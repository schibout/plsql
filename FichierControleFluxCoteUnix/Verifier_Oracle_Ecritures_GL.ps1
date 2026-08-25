# =====================================================================
# Controle des ecritures GL dans Oracle EBS
# Requetes reprises du flux GL de ControleFolioRose\Verifier_Factures.ps1.
# =====================================================================
param(
    [Parameter(Mandatory = $true)]
    [string] $CheminFichierSrc,
    [switch] $Diagnostic,
    [switch] $GarderTempSQL
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EXIT_OK = 0; $EXIT_TECH = 1; $EXIT_ANOMALIE = 2
$TOLERANCE = [decimal]0.005

# Palette du rapport CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS (valeurs BGR Excel).
$XL_CENTER       = -4108
$XL_LEFT         = -4131
$XL_CONTINUOUS   = 1
$COULEUR_ENTETE = 0x7D491F
$COULEUR_ECART  = 0xD6E4FC
$COULEUR_OK     = 0xDAEFED
$COULEUR_BANDE  = 0xF7F2EA
$COULEUR_BORDURE = 0xD9D9D9

function Format-Montant { param($Valeur) return ('{0:N2}' -f [double]$Valeur) }

function Convertir-Montant {
    param([string] $Texte, [int] $NumeroLigne)
    $normalise = $Texte.Trim().Replace(' ', '').Replace(',', '.')
    if ($normalise -eq '') { return [decimal]0 }
    [decimal] $montant = 0
    $ok = [decimal]::TryParse(
        $normalise,
        [System.Globalization.NumberStyles]::Number,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [ref] $montant)
    if (-not $ok) { throw "Montant illisible ligne $NumeroLigne : '$Texte'." }
    return $montant
}

function Ecart-Acceptable {
    param([decimal] $Valeur1, [decimal] $Valeur2)
    return [math]::Abs($Valeur1 - $Valeur2) -le $TOLERANCE
}

function Export-RapportCsvSecours {
    param([string] $BaseSortie, [object[]] $Synthese, [object[]] $Detail)
    $csvSynthese = "${BaseSortie}.csv"
    $csvDetail = "${BaseSortie}_Detail.csv"
    $Synthese | Export-Csv -LiteralPath $csvSynthese -Delimiter ';' -NoTypeInformation -Encoding UTF8
    $Detail | Export-Csv -LiteralPath $csvDetail -Delimiter ';' -NoTypeInformation -Encoding UTF8
    Write-Host "   Rapports CSV : $csvSynthese" -ForegroundColor Yellow
    Write-Host "                  $csvDetail" -ForegroundColor Yellow
}

function Mettre-EnFormeOnglet {
    param(
        $Feuille,
        [string] $Titre,
        [string] $SousTitre,
        [object[]] $Donnees,
        [string[]] $Colonnes,
        [string] $ColonneStatut,
        [string[]] $ValeursOk
    )
    $nbColonnes = $Colonnes.Count
    $Feuille.Name = $Titre
    $Feuille.Application.ActiveWindow.DisplayGridlines = $false

    $bandeTitre = $Feuille.Range($Feuille.Cells.Item(1, 1), $Feuille.Cells.Item(1, $nbColonnes))
    # PowerShell 5.1 peut corrompre les affectations Value2 suivantes quand
    # une chaine scalaire est ecrite directement : utiliser une matrice 1x1.
    $titreMatrice = New-Object 'object[,]' 1, 1
    $titreMatrice[0, 0] = 'CONTROLE ORACLE - ECRITURES GL'
    $Feuille.Range($Feuille.Cells.Item(1, 1), $Feuille.Cells.Item(1, 1)).Value2 = $titreMatrice
    $bandeTitre.Interior.Color = $COULEUR_ENTETE
    $bandeTitre.Font.Color = 0xFFFFFF
    $bandeTitre.Font.Bold = $true
    $Feuille.Cells.Item(1, 1).Font.Size = 16
    $Feuille.Cells.Item(1, 1).HorizontalAlignment = $XL_LEFT
    $Feuille.Rows.Item(1).RowHeight = 28

    $sousTitreMatrice = New-Object 'object[,]' 1, 1
    $sousTitreMatrice[0, 0] = $SousTitre
    $Feuille.Range($Feuille.Cells.Item(2, 1), $Feuille.Cells.Item(2, 1)).Value2 = $sousTitreMatrice
    $Feuille.Cells.Item(2, 1).Font.Color = 0x666666
    $Feuille.Cells.Item(2, 1).Font.Italic = $true

    $entetes = New-Object 'object[,]' 1, $nbColonnes
    for ($c = 0; $c -lt $nbColonnes; $c++) { $entetes[0, $c] = $Colonnes[$c] }
    $plageEntete = $Feuille.Range($Feuille.Cells.Item(4, 1), $Feuille.Cells.Item(4, $nbColonnes))
    $plageEntete.Value2 = $entetes
    $plageEntete.Interior.Color = $COULEUR_ENTETE
    $plageEntete.Font.Color = 0xFFFFFF
    $plageEntete.Font.Bold = $true
    $plageEntete.HorizontalAlignment = $XL_CENTER
    $plageEntete.WrapText = $true
    $Feuille.Rows.Item(4).RowHeight = 34

    # Poser les formats avant l'ecriture, notamment le format texte qui
    # preserve les zeros de tete des numeros de piece.
    for ($c = 0; $c -lt $nbColonnes; $c++) {
        $nom = $Colonnes[$c]
        if ($nom -like 'Debit*' -or $nom -like 'Credit*' -or $nom -like 'Ecart*') {
            $Feuille.Columns.Item($c + 1).NumberFormatLocal = '# ##0,00;[Rouge]-# ##0,00'
        } elseif ($nom -like 'Nb *') {
            $Feuille.Columns.Item($c + 1).NumberFormatLocal = '# ##0'
        } elseif ($nom -like 'Numero*' -or $nom -eq 'Fichier') {
            $Feuille.Columns.Item($c + 1).NumberFormatLocal = '@'
        }
    }

    if ($Donnees.Count -gt 0) {
        # Certaines versions d'Excel 32 bits refusent une matrice heterogene
        # et renvoient E_OUTOFMEMORY. L'ecriture cellule par cellule est plus
        # lente, mais fiable et acceptable ici (une ligne par origine/piece).
        for ($r = 0; $r -lt $Donnees.Count; $r++) {
            for ($c = 0; $c -lt $Colonnes.Count; $c++) {
                $Feuille.Cells.Item(5 + $r, 1 + $c).Value2 = $Donnees[$r].($Colonnes[$c])
            }
        }
        $derniereLigne = 4 + $Donnees.Count
        $plage = $Feuille.Range($Feuille.Cells.Item(5, 1), $Feuille.Cells.Item($derniereLigne, $nbColonnes))
        $plage.Borders.LineStyle = $XL_CONTINUOUS
        $plage.Borders.Color = $COULEUR_BORDURE

        for ($r = 0; $r -lt $Donnees.Count; $r++) {
            $ligneExcel = 5 + $r
            if (($r % 2) -eq 1) {
                $Feuille.Range($Feuille.Cells.Item($ligneExcel, 1), $Feuille.Cells.Item($ligneExcel, $nbColonnes)).Interior.Color = $COULEUR_BANDE
            }
        }

        $indexStatut = [array]::IndexOf($Colonnes, $ColonneStatut)
        if ($indexStatut -ge 0) {
            for ($r = 0; $r -lt $Donnees.Count; $r++) {
                $cellule = $Feuille.Cells.Item(5 + $r, $indexStatut + 1)
                $estOk = $ValeursOk -contains [string]$Donnees[$r].($ColonneStatut)
                $cellule.Interior.Color = if ($estOk) { $COULEUR_OK } else { $COULEUR_ECART }
                $cellule.Font.Bold = $true
                $cellule.HorizontalAlignment = $XL_CENTER
            }
        }
        $plageEntete.AutoFilter() | Out-Null
    }

    $Feuille.UsedRange.Columns.AutoFit() | Out-Null
    for ($c = 1; $c -le $nbColonnes; $c++) {
        if ($Feuille.Columns.Item($c).ColumnWidth -gt 24) { $Feuille.Columns.Item($c).ColumnWidth = 24 }
        $largeurMini = [math]::Min(24, [math]::Max(11, $Colonnes[$c - 1].Length + 3))
        if ($Feuille.Columns.Item($c).ColumnWidth -lt $largeurMini) { $Feuille.Columns.Item($c).ColumnWidth = $largeurMini }
    }
    $Feuille.Activate() | Out-Null
    $Feuille.Application.ActiveWindow.SplitRow = 4
    $Feuille.Application.ActiveWindow.FreezePanes = $true
}

function Export-RapportExcel {
    param([string] $Chemin, [string] $NomFichier, [object[]] $Synthese, [object[]] $Detail)
    if (-not (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\excel.exe')) {
        return $false
    }
    $excel = $null; $classeur = $null; $feuilles = @()
    try {
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $excel.DisplayAlerts = $false
        $excel.ScreenUpdating = $false
        $classeur = $excel.Workbooks.Add()

        $colonnesSynthese = @(
            'Origine', 'Nb Pieces SRC', 'Debit SRC', 'Credit SRC',
            'Nb Journaux Oracle', 'Debit Oracle', 'Credit Oracle',
            'Debit Interface', 'Credit Interface', 'Ecart Debit', 'Ecart Credit', 'Statut'
        )
        $colonnesDetail = @('Origine', 'Numero Piece', 'Debit SRC', 'Credit SRC', 'Ecart', 'Statut')

        $wsSynthese = $classeur.Sheets.Item(1); $feuilles += $wsSynthese
        Mettre-EnFormeOnglet $wsSynthese 'Synthese Oracle' "Fichier : $NomFichier  |  Execution : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" $Synthese $colonnesSynthese 'Statut' @('INTEGREE')

        $wsDetail = $classeur.Sheets.Add([System.Reflection.Missing]::Value, $wsSynthese); $feuilles += $wsDetail
        Mettre-EnFormeOnglet $wsDetail 'Detail Pieces SRC' 'Equilibre debit / credit par numero de piece dans le fichier source' $Detail $colonnesDetail 'Statut' @('EQUILIBREE')

        $wsSynthese.Activate() | Out-Null
        $classeur.SaveAs($Chemin)
        $classeur.Close($false); $classeur = $null
        return $true
    } catch {
        Write-Host "   [ATTENTION] Echec generation Excel : $($_.Exception.Message)" -ForegroundColor Yellow
        if ($Diagnostic) { Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray }
        return $false
    } finally {
        foreach ($feuille in $feuilles) {
            try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($feuille) | Out-Null } catch { }
        }
        if ($classeur) {
            try { $classeur.Close($false) } catch { }
            try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($classeur) | Out-Null } catch { }
        }
        if ($excel) {
            try { $excel.Quit() } catch { }
            try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null } catch { }
        }
        [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); [System.GC]::Collect()
    }
}

try {
    Write-Host ''
    Write-Host '=======================================================================' -ForegroundColor Cyan
    Write-Host '  CONTROLE ORACLE - ECRITURES GL' -ForegroundColor Cyan
    Write-Host '=======================================================================' -ForegroundColor Cyan

    $chemin = Resolve-Path -LiteralPath $CheminFichierSrc -ErrorAction Stop
    $nomFichier = [System.IO.Path]::GetFileNameWithoutExtension($chemin.Path)
    $fichierBase = $nomFichier
    $positionST = $nomFichier.IndexOf('_ST_')
    if ($positionST -gt 0) { $fichierBase = $nomFichier.Substring(0, $positionST) }

    $src = [ordered]@{}
    $pieces = [ordered]@{}
    $numeroLigne = 0
    foreach ($ligne in [System.IO.File]::ReadLines($chemin.Path, [System.Text.Encoding]::GetEncoding(1252))) {
        $numeroLigne++
        if ([string]::IsNullOrWhiteSpace($ligne)) { continue }
        $champs = $ligne.Split(';')
        if ($champs.Count -lt 12) { throw "Ligne $numeroLigne : moins de 12 colonnes." }
        $piece = $champs[0].Trim(); $origine = $champs[11].Trim()
        if ($piece -eq '' -or $origine -eq '') { throw "Ligne $numeroLigne : numero de piece ou origine vide." }
        $debit = Convertir-Montant $champs[8] $numeroLigne
        $credit = Convertir-Montant $champs[9] $numeroLigne
        if (-not $src.Contains($origine)) {
            $src[$origine] = @{ Pieces = [System.Collections.Generic.HashSet[string]]::new(); Debit = [decimal]0; Credit = [decimal]0 }
        }
        [void]$src[$origine].Pieces.Add($piece)
        $src[$origine].Debit += $debit; $src[$origine].Credit += $credit
        $clePiece = "$origine|$piece"
        if (-not $pieces.Contains($clePiece)) { $pieces[$clePiece] = @{ Origine = $origine; Piece = $piece; Debit = [decimal]0; Credit = [decimal]0 } }
        $pieces[$clePiece].Debit += $debit; $pieces[$clePiece].Credit += $credit
    }
    if ($src.Count -eq 0) { throw 'Aucune ecriture GL exploitable dans le SRC.' }

    $config = Join-Path $ScriptDir 'config.ps1'
    if (-not (Test-Path -LiteralPath $config)) { throw "Configuration Oracle introuvable : $config" }
    . $config
    $sqlCmd = $null
    foreach ($commande in @('sqlplus', 'sqlcl', 'sql')) {
        if (Get-Command $commande -ErrorAction SilentlyContinue) { $sqlCmd = $commande; break }
    }
    if ($null -eq $sqlCmd) { throw 'Aucun client Oracle trouve (sqlplus, sqlcl ou sql).' }

    $logDir = if ($env:CONTROLE_FLUX_LOG_DIR) { $env:CONTROLE_FLUX_LOG_DIR } else { Join-Path $ScriptDir 'Logs' }
    if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
    $timestamp = Get-Date -Format 'ddMMyyyy_HHmmss'
    $sqlTemp = Join-Path $logDir "requetes_gl_${timestamp}.sql"
    $baseSortie = Join-Path $logDir "Rapport_Oracle_GL_${timestamp}"
    $xlsx = "${baseSortie}.xlsx"
    $b = $fichierBase.Replace("'", "''")

    $sb = New-Object System.Text.StringBuilder
    foreach ($instruction in @('SET PAGESIZE 0', 'SET FEEDBACK OFF', 'SET HEADING OFF', 'SET LINESIZE 1000', 'SET TRIMSPOOL ON', 'SET DEFINE OFF', 'WHENEVER SQLERROR CONTINUE', '')) {
        [void]$sb.AppendLine($instruction)
    }
    $cles = @{}; $index = 0
    foreach ($origine in @($src.Keys | Sort-Object)) {
        $cles[$index] = $origine
        $f = $origine.Replace("'", "''")
        [void]$sb.AppendLine(@"
SELECT '##RES##$index|' || NVL(q_def.nb_trx, 0) || '|' || NVL(q_def.sum_dr, 0) || '|' || NVL(q_def.sum_cr, 0) || '|' || NVL(q_int.sum_dr, 0) || '|' || NVL(q_int.sum_cr, 0)
FROM
  (SELECT COUNT(DISTINCT gjh.je_header_id) AS nb_trx,
          SUM(NVL(gjl.entered_dr, 0)) AS sum_dr,
          SUM(NVL(gjl.entered_cr, 0)) AS sum_cr
   FROM   APPS.GL_JE_HEADERS gjh
   JOIN   APPS.GL_JE_LINES gjl ON gjh.je_header_id = gjl.je_header_id
   WHERE  gjl.attribute10 LIKE TRIM('$b') || '%'
     AND  gjl.attribute9 = TRIM('$f')) q_def
CROSS JOIN
  (SELECT SUM(NVL(entered_dr, 0)) AS sum_dr,
          SUM(NVL(entered_cr, 0)) AS sum_cr
   FROM   APPS.GL_INTERFACE
   WHERE  attribute10 LIKE TRIM('$b') || '%'
     AND  attribute9 = TRIM('$f')) q_int;
"@)
        [void]$sb.AppendLine('')
        $index++
    }
    [void]$sb.AppendLine('EXIT;')
    [System.IO.File]::WriteAllText($sqlTemp, $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))

    if ($Diagnostic) { Get-Content -LiteralPath $sqlTemp | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray } }
    $connexion = "${ORA_USER}/${ORA_PWD}@${ORA_HOST}:${ORA_PORT}/${ORA_SERVICE}"
    $sortie = & $sqlCmd -S $connexion "@$sqlTemp" 2>&1
    if ($Diagnostic) { $sortie | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray } }
    $erreurs = @($sortie | Where-Object { "$_" -match '^(ORA|SP2|TNS)-\d+' } | Select-Object -Unique)
    if ($erreurs.Count -gt 0) { throw "Oracle a retourne une erreur : $($erreurs[0])" }

    $oracle = @{}
    foreach ($ligne in $sortie) {
        if ("$ligne" -match '##RES##(\d+)\|([^|]*)\|([^|]*)\|([^|]*)\|([^|]*)\|(.*)$') {
            $oracle[[int]$Matches[1]] = @(
                [int]$Matches[2].Trim(),
                [decimal]($Matches[3].Trim() -replace ',', '.'),
                [decimal]($Matches[4].Trim() -replace ',', '.'),
                [decimal]($Matches[5].Trim() -replace ',', '.'),
                [decimal]($Matches[6].Trim() -replace ',', '.'))
        }
    }
    if ($oracle.Count -ne $src.Count) { throw "Reponses Oracle incompletes : $($oracle.Count)/$($src.Count)." }

    $synthese = @(); $anomalie = $false
    foreach ($i in @($cles.Keys | Sort-Object)) {
        $origine = $cles[$i]; $s = $src[$origine]; $o = $oracle[$i]
        $nbDef = [int]$o[0]; $drDef = [decimal]$o[1]; $crDef = [decimal]$o[2]
        $drInt = [decimal]$o[3]; $crInt = [decimal]$o[4]
        $nbSrc = $s.Pieces.Count; $drSrc = [decimal]$s.Debit; $crSrc = [decimal]$s.Credit
        $defVide = $nbDef -eq 0 -and $drDef -eq 0 -and $crDef -eq 0
        $intVide = $drInt -eq 0 -and $crInt -eq 0
        if ($nbDef -eq $nbSrc -and (Ecart-Acceptable $drDef $drSrc) -and (Ecart-Acceptable $crDef $crSrc)) { $statut = 'INTEGREE' }
        elseif ($defVide -and (Ecart-Acceptable $drInt $drSrc) -and (Ecart-Acceptable $crInt $crSrc)) { $statut = 'EN INTERFACE' }
        elseif (-not $defVide -and -not $intVide -and (Ecart-Acceptable ($drDef + $drInt) $drSrc) -and (Ecart-Acceptable ($crDef + $crInt) $crSrc)) { $statut = 'PARTIELLE' }
        elseif ($defVide -and $intVide) { $statut = 'ABSENTE' }
        else { $statut = 'ECART' }
        if ($statut -ne 'INTEGREE') { $anomalie = $true }
        $synthese += [PSCustomObject][ordered]@{
            'Origine' = $origine; 'Nb Pieces SRC' = $nbSrc; 'Debit SRC' = [double]$drSrc; 'Credit SRC' = [double]$crSrc
            'Nb Journaux Oracle' = $nbDef; 'Debit Oracle' = [double]$drDef; 'Credit Oracle' = [double]$crDef
            'Debit Interface' = [double]$drInt; 'Credit Interface' = [double]$crInt
            'Ecart Debit' = [double](($drDef + $drInt) - $drSrc); 'Ecart Credit' = [double](($crDef + $crInt) - $crSrc); 'Statut' = $statut
        }
    }

    $detail = @()
    foreach ($cle in $pieces.Keys) {
        $p = $pieces[$cle]; $ecart = [decimal]$p.Debit - [decimal]$p.Credit
        $detail += [PSCustomObject][ordered]@{
            'Origine' = $p.Origine; 'Numero Piece' = $p.Piece; 'Debit SRC' = [double]$p.Debit
            'Credit SRC' = [double]$p.Credit; 'Ecart' = [double]$ecart
            'Statut' = if ([math]::Abs($ecart) -le $TOLERANCE) { 'EQUILIBREE' } else { 'DESEQUILIBREE' }
        }
    }

    Write-Host ''
    $synthese | Format-Table Origine, 'Nb Pieces SRC', 'Debit SRC', 'Debit Oracle', 'Debit Interface', Statut -AutoSize
    if (Export-RapportExcel $xlsx $nomFichier $synthese $detail) {
        Write-Host "   Rapport Excel : $xlsx" -ForegroundColor Green
    } else {
        Export-RapportCsvSecours $baseSortie $synthese $detail
    }
    if (-not $GarderTempSQL) { Remove-Item -LiteralPath $sqlTemp -ErrorAction SilentlyContinue }
    exit $(if ($anomalie) { $EXIT_ANOMALIE } else { $EXIT_OK })
} catch {
    Write-Host "[ERREUR] $($_.Exception.Message)" -ForegroundColor Red
    if ($sqlTemp -and -not $GarderTempSQL) { Remove-Item -LiteralPath $sqlTemp -ErrorAction SilentlyContinue }
    exit $EXIT_TECH
}
