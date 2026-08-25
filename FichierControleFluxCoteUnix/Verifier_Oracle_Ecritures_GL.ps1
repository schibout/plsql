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

# Les interrogations Oracle sont ajoutees au classeur de synthese produit par
# ctl_ecritures_gl.py : un seul rapport par flux, ecrit par rapport_excel.py
# (openpyxl), donc sans dependance a une installation d'Excel.
. (Join-Path $ScriptDir 'rapport_oracle.ps1')

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

    $colonnesSynthese = @(
        'Origine', 'Nb Pieces SRC', 'Debit SRC', 'Credit SRC',
        'Nb Journaux Oracle', 'Debit Oracle', 'Credit Oracle',
        'Debit Interface', 'Credit Interface', 'Ecart Debit', 'Ecart Credit', 'Statut')
    $colonnesDetail = @('Origine', 'Numero Piece', 'Debit SRC', 'Credit SRC', 'Ecart', 'Statut')
    $horodatage = Get-Date -Format 'dd/MM/yyyy HH:mm:ss'

    $classeur = Export-OngletsOracle -Src $chemin.Path -Prefixe 'GL_SYNTHESE' `
        -DossierTravail $ScriptDir -Onglets @(
        [ordered]@{
            nom            = 'Synthese Oracle'
            titre          = 'CONTROLE ECRITURES GL - SYNTHESE ORACLE PAR ORIGINE'
            sous_titre     = "Fichier : $nomFichier  |  Execution : $horodatage"
            colonnes       = $colonnesSynthese
            colonne_statut = 'Statut'
            valeurs_ok     = @('INTEGREE')
            lignes         = (ConvertTo-LignesOnglet $synthese $colonnesSynthese)
        },
        [ordered]@{
            nom            = 'Detail Pieces SRC'
            titre          = 'CONTROLE ECRITURES GL - DETAIL PIECE PAR PIECE'
            sous_titre     = 'Equilibre debit / credit par numero de piece dans le fichier source'
            colonnes       = $colonnesDetail
            colonne_statut = 'Statut'
            valeurs_ok     = @('EQUILIBREE')
            lignes         = (ConvertTo-LignesOnglet $detail $colonnesDetail)
        })
    if ($classeur) { Write-Host "   Rapport Excel : $classeur" -ForegroundColor Green }
    if (-not $GarderTempSQL) { Remove-Item -LiteralPath $sqlTemp -ErrorAction SilentlyContinue }
    exit $(if ($anomalie) { $EXIT_ANOMALIE } else { $EXIT_OK })
} catch {
    Write-Host "[ERREUR] $($_.Exception.Message)" -ForegroundColor Red
    if ($sqlTemp -and -not $GarderTempSQL) { Remove-Item -LiteralPath $sqlTemp -ErrorAction SilentlyContinue }
    exit $EXIT_TECH
}
