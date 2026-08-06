<#
.SYNOPSIS
    Rapprochement des ordres de prelevement emis par ORACLE avec les etats de
    reception EDF, avec restitution Excel en 3 onglets.

.DESCRIPTION
    Etape 1 : synthese journaliere brute (volumes et montants Oracle vs EDF).
    Etape 2 : etat comparatif et ecarts, avec projection de la date Oracle vers
              la date de prise en charge EDF attendue.
    Etape 3 : contenu brut des fichiers de rejets internes.

.NOTES
    Encodage : UTF-8 avec BOM (obligatoire pour que les accents soient corrects
    a la fois sous Windows PowerShell 5.1 et PowerShell 7+).
#>

[CmdletBinding()]
param(
    # Racine de traitement. Par defaut le dossier du script.
    [string] $RacinePath,

    # Sous-dossier contenant l'arborescence Oracle (un sous-dossier par date yyyyMMdd).
    [string] $DossierOracle = 'ORACLE',

    # Sous-dossier contenant les etats de reception EDF.
    [string] $DossierEdf = 'EDF',

    # Motifs de nom identifiant les fichiers Oracle a prendre en compte.
    [string[]] $MotifsFichiersOracle = @('*PCX*', '*PCL*'),

    # Motif de nom des etats de reception EDF.
    [string] $MotifFichiersEdf = 'IMPORT_AVP_DK.*.*.csv',

    # Motif de nom des fichiers de rejets internes.
    [string] $MotifFichiersRejets = 'REJETS_INTERNES_DK.*',

    # Valeur de la colonne "NOM DU SI" identifiant les lignes a rapprocher.
    [string] $NomSi = 'ORACLE',

    # Dossier de sortie du classeur. Par defaut, la racine de traitement.
    [string] $SortiePath,

    # Ne pas attendre d'appui touche en fin de traitement (execution planifiee).
    [switch] $NoPause
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

# Encodage des fichiers sources (ISO-8859-1 : disponible sur toutes les versions
# de .NET, et identique a CP1252 sur la plage des accents francais utilises ici).
$script:EncodageSource = [System.Text.Encoding]::GetEncoding(28591)

# Constantes Excel (evite la dependance a la PIA Microsoft.Office.Interop).
$XL_CENTER      = -4108
$COULEUR_ENTETE = 0x7D491F   # BGR
$COULEUR_ECART  = 0xD6E4FC
$COULEUR_OK     = 0xDAEFED
$COULEUR_BRUT   = 0x4F81BD

# Compteurs de diagnostic : un rapport partiel doit se voir.
$diag = [ordered]@{
    FichiersOracle       = 0
    LignesOracle         = 0
    LignesOracleIgnorees = 0
    FichiersEdf          = 0
    LignesEdf            = 0
    FichiersRejets       = 0
    LignesRejets         = 0
    Avertissements       = [System.Collections.Generic.List[string]]::new()
}

function Add-Avertissement {
    param([string] $Message)
    $diag.Avertissements.Add($Message)
    Write-Warning $Message
}

function Read-LignesFichier {
    <# Lecture rapide et deterministe (evite Get-Content, 10x plus lent). #>
    param([string] $Path)
    return [System.IO.File]::ReadAllLines($Path, $script:EncodageSource)
}

function ConvertTo-Decimal {
    <# Conversion invariante : le separateur decimal est toujours le point. #>
    param([string] $Valeur)
    return [decimal]::Parse(
        ($Valeur.Trim() -replace ',', '.'),
        [System.Globalization.NumberStyles]::Any,
        [System.Globalization.CultureInfo]::InvariantCulture)
}

function Get-DateYyyyMMdd {
    <# Renvoie $null au lieu de lever, pour pouvoir signaler l'anomalie. #>
    param([string] $Valeur)
    [datetime] $parsed = [datetime]::MinValue
    $ok = [datetime]::TryParseExact(
        $Valeur, 'yyyyMMdd', [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::None, [ref] $parsed)
    if ($ok) { return $parsed }
    return $null
}

function Get-IndexColonneMontant {
    <#
        Resout la position de la colonne AMOUNT depuis la ligne de description
        FORMAT1ENTITYID plutot que de la coder en dur : le format Oracle peut
        evoluer sans que le script ne s'en apercoive.
    #>
    param([string[]] $Lignes)
    foreach ($ligne in $Lignes) {
        if ($ligne -match '^FORMAT1ENTITYID') {
            $colonnes = $ligne.Split(',')
            for ($i = 0; $i -lt $colonnes.Count; $i++) {
                if ($colonnes[$i].Trim() -eq 'AMOUNT') { return $i }
            }
        }
    }
    return -1
}

function Write-BlocExcel {
    <#
        Ecrit un tableau 2D en un seul aller-retour COM. L'ecriture cellule par
        cellule couterait un appel inter-processus par valeur : sur quelques
        milliers de lignes, la difference est de plusieurs minutes.
    #>
    param(
        $Feuille,
        [int] $LigneDepart,
        [int] $ColonneDepart,
        [object[][]] $Donnees
    )
    if ($null -eq $Donnees -or $Donnees.Count -eq 0) { return }

    $nbLignes = $Donnees.Count
    $nbCols   = $Donnees[0].Count
    $matrice  = New-Object 'object[,]' $nbLignes, $nbCols
    for ($r = 0; $r -lt $nbLignes; $r++) {
        for ($c = 0; $c -lt $nbCols; $c++) { $matrice[$r, $c] = $Donnees[$r][$c] }
    }

    $plage = $Feuille.Range(
        $Feuille.Cells.Item($LigneDepart, $ColonneDepart),
        $Feuille.Cells.Item($LigneDepart + $nbLignes - 1, $ColonneDepart + $nbCols - 1))
    $plage.Value2 = $matrice
}

function Set-EnteteExcel {
    param($Feuille, [int] $Ligne, [int] $ColonneDepart, [string[]] $Libelles, [int] $Couleur)
    $plage = $Feuille.Range(
        $Feuille.Cells.Item($Ligne, $ColonneDepart),
        $Feuille.Cells.Item($Ligne, $ColonneDepart + $Libelles.Count - 1))
    $matrice = New-Object 'object[,]' 1, $Libelles.Count
    for ($i = 0; $i -lt $Libelles.Count; $i++) { $matrice[0, $i] = $Libelles[$i] }
    $plage.Value2              = $matrice
    $plage.Interior.Color      = $Couleur
    $plage.Font.Color          = 0xFFFFFF
    $plage.Font.Bold           = $true
    $plage.HorizontalAlignment = $XL_CENTER
}

# Permet d'identifier le PID de NOTRE instance Excel (via son handle de fenetre)
# pour garantir sa fermeture, sans jamais toucher aux Excel ouverts par l'utilisateur.
if (-not ('Win32Fenetre' -as [type])) {
    Add-Type -Namespace '' -Name 'Win32Fenetre' -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true)]
public static extern uint GetWindowThreadProcessId(System.IntPtr hWnd, out uint lpdwProcessId);
'@
}

function Stop-ExcelResiduel {
    <#
        Quit() ne suffit pas : tant qu'un RCW subsiste quelque part, le processus
        reste en memoire, sans fenetre et invisible pour l'utilisateur. On force
        la fermeture du seul PID que l'on a demarre.
    #>
    param([int] $ProcessId)
    if ($ProcessId -le 0) { return }
    for ($i = 0; $i -lt 20; $i++) {
        $p = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
        if (-not $p) { return }
        Start-Sleep -Milliseconds 250
    }
    try {
        Stop-Process -Id $ProcessId -Force -ErrorAction Stop
        Write-Verbose "Instance Excel $ProcessId fermee de force."
    } catch { }
}

# Declarees hors du try pour rester accessibles au bloc finally.
$excel    = $null
$workbook = $null
$ws1      = $null
$ws2      = $null
$ws3      = $null
$excelPid = 0

try {
    # --- VERIFICATION PREALABLE : Presence d'Excel ---
    # Le script utilise l'automatisation COM qui necessite une installation locale d'Excel.
    # Cette verification permet de produire une erreur claire si Excel est absent.
    $excelRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\excel.exe"
    if (-not (Test-Path $excelRegPath)) {
        throw "Microsoft Excel ne semble pas etre installe sur ce poste. L'installation d'Excel est requise pour generer le rapport .xlsx."
    }

    # -----------------------------------------------------------------
    # 1. Configuration des chemins
    # -----------------------------------------------------------------
    if ([string]::IsNullOrWhiteSpace($RacinePath)) {
        if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
            throw "Impossible de determiner le dossier du script. Utilisez -RacinePath."
        }
        $RacinePath = $PSScriptRoot
    }
    if (-not (Test-Path -LiteralPath $RacinePath)) {
        throw "Racine de traitement introuvable : $RacinePath"
    }
    if ([string]::IsNullOrWhiteSpace($SortiePath)) { $SortiePath = $RacinePath }

    $oraclePath = Join-Path $RacinePath $DossierOracle
    $edfPath    = Join-Path $RacinePath $DossierEdf

    # Detection du dossier rejets sans distinction de casse.
    $rejetsPath = Join-Path $edfPath 'REJETS'
    if (Test-Path -LiteralPath $edfPath) {
        $dossierRejets = Get-ChildItem -LiteralPath $edfPath -Directory |
            Where-Object { $_.Name -eq 'REJETS' } | Select-Object -First 1
        if ($dossierRejets) { $rejetsPath = $dossierRejets.FullName }
    }

    $timestamp  = Get-Date -Format 'yyyyMMdd_HHmmss'
    $outputPath = Join-Path $SortiePath "Rapprochement_Oracle_EDF_$timestamp.xlsx"

    Write-Host "Analyse du dossier en cours : $(Split-Path $RacinePath -Leaf)" -ForegroundColor Yellow

    # -----------------------------------------------------------------
    # 2. Analyse ORACLE
    # -----------------------------------------------------------------
    if (-not (Test-Path -LiteralPath $oraclePath)) {
        throw "Dossier Oracle introuvable : $oraclePath"
    }

    $oracleFiles = @(
        Get-ChildItem -LiteralPath $oraclePath -Recurse -File |
            Where-Object {
                $nom = $_.Name
                @($MotifsFichiersOracle | Where-Object { $nom -like $_ }).Count -gt 0
            })

    $oracleRaw = [System.Collections.Generic.List[object]]::new()
    foreach ($file in $oracleFiles) {
        $dateFolder = $file.Directory.Name
        if (-not (Get-DateYyyyMMdd $dateFolder)) {
            Add-Avertissement "Dossier non date ignore : $($file.Directory.FullName)"
            continue
        }

        $lignes = Read-LignesFichier $file.FullName
        $idxMontant = Get-IndexColonneMontant $lignes
        if ($idxMontant -lt 0) {
            Add-Avertissement "Colonne AMOUNT introuvable, index 5 par defaut : $($file.Name)"
            $idxMontant = 5
        }

        $diag.FichiersOracle++
        foreach ($ligne in $lignes) {
            if ($ligne -match '^HEADER' -or $ligne -match '^FORMAT1ENTITYID' -or
                [string]::IsNullOrWhiteSpace($ligne)) { continue }

            $champs = $ligne.Split(',')
            if ($champs.Count -le $idxMontant) { $diag.LignesOracleIgnorees++; continue }

            try {
                $montant = ConvertTo-Decimal $champs[$idxMontant]
            } catch {
                $diag.LignesOracleIgnorees++
                continue
            }
            $oracleRaw.Add([PSCustomObject]@{ Date = $dateFolder; Montant = $montant })
            $diag.LignesOracle++
        }
    }

    if ($diag.LignesOracleIgnorees -gt 0) {
        Add-Avertissement "$($diag.LignesOracleIgnorees) ligne(s) Oracle illisible(s) ecartee(s) du calcul."
    }
    if ($oracleRaw.Count -eq 0) {
        throw "Aucune ligne Oracle exploitable trouvee sous $oraclePath."
    }

    $oracleSummary = @(
        $oracleRaw | Group-Object Date | ForEach-Object {
            [PSCustomObject]@{
                Date    = $_.Name
                NbLines = $_.Count
                Total   = ($_.Group | Measure-Object Montant -Sum).Sum
            }
        } | Sort-Object Date)

    Write-Host "Oracle : $($diag.FichiersOracle) fichier(s), $($diag.LignesOracle) ligne(s), $($oracleSummary.Count) date(s)." -ForegroundColor Cyan

    # -----------------------------------------------------------------
    # 3. Analyse EDF
    # -----------------------------------------------------------------
    $edfSummary = @()
    if (Test-Path -LiteralPath $edfPath) {
        $edfFiles = @(Get-ChildItem -LiteralPath $edfPath -File -Filter $MotifFichiersEdf)
        $edfRaw = [System.Collections.Generic.List[object]]::new()

        foreach ($file in $edfFiles) {
            $segments = $file.Name.Split('.')
            if ($segments.Count -lt 2 -or -not (Get-DateYyyyMMdd $segments[1])) {
                Add-Avertissement "Date illisible dans le nom du fichier EDF, ignore : $($file.Name)"
                continue
            }
            $dateEdf = $segments[1]
            $diag.FichiersEdf++

            foreach ($ligne in (Read-LignesFichier $file.FullName)) {
                $champs = $ligne.Split(';')
                if ($champs.Count -lt 5 -or $champs[0].Trim() -ne $NomSi) { continue }
                try {
                    $edfRaw.Add([PSCustomObject]@{
                        DateEdf  = $dateEdf
                        NbEdf    = [int]::Parse($champs[3].Trim(), [System.Globalization.CultureInfo]::InvariantCulture)
                        TotalEdf = ConvertTo-Decimal $champs[4]
                    })
                    $diag.LignesEdf++
                } catch {
                    Add-Avertissement "Ligne EDF illisible ignoree dans $($file.Name) : $ligne"
                }
            }
        }

        $edfSummary = @(
            $edfRaw | Group-Object DateEdf | ForEach-Object {
                [PSCustomObject]@{
                    DateEdf  = $_.Name
                    NbEdf    = ($_.Group | Measure-Object NbEdf -Sum).Sum
                    TotalEdf = ($_.Group | Measure-Object TotalEdf -Sum).Sum
                }
            } | Sort-Object DateEdf)

        Write-Host "EDF : $($diag.FichiersEdf) fichier(s), $($diag.LignesEdf) ligne(s) '$NomSi', $($edfSummary.Count) date(s)." -ForegroundColor Cyan

        # Un rapport ou tout l'EDF est a zero ressemble a un ecart total : il
        # faut distinguer "rien recu" de "mauvais filtre / format change".
        if ($diag.FichiersEdf -gt 0 -and $diag.LignesEdf -eq 0) {
            Add-Avertissement "Aucune ligne '$NomSi' trouvee dans les $($diag.FichiersEdf) fichier(s) EDF lus. Verifiez le parametre -NomSi ou le format des fichiers : les ecarts affiches seront trompeurs."
        }
    } else {
        Add-Avertissement "Dossier EDF introuvable : $edfPath. Les volumes recus seront a zero."
    }

    # -----------------------------------------------------------------
    # 4. Lecture brute des fichiers de REJETS
    # -----------------------------------------------------------------
    $lignesBrutesRejets = [System.Collections.Generic.List[object]]::new()
    if (Test-Path -LiteralPath $rejetsPath) {
        $rejetFiles = @(Get-ChildItem -LiteralPath $rejetsPath -File |
            Where-Object { $_.Name -like $MotifFichiersRejets })
        $diag.FichiersRejets = $rejetFiles.Count

        foreach ($file in $rejetFiles) {
            foreach ($ligne in (Read-LignesFichier $file.FullName)) {
                if ([string]::IsNullOrWhiteSpace($ligne)) { continue }
                $lignesBrutesRejets.Add([PSCustomObject]@{ Fichier = $file.Name; TexteBrut = $ligne })
                $diag.LignesRejets++
            }
        }
        Write-Host "Rejets : $($diag.FichiersRejets) fichier(s), $($diag.LignesRejets) ligne(s)." -ForegroundColor Cyan
    } else {
        Add-Avertissement "Dossier de rejets introuvable : $rejetsPath."
    }

    # -----------------------------------------------------------------
    # 5. Preparation du rapprochement comparatif
    # -----------------------------------------------------------------
    # Regle de projection Oracle -> EDF (J+2 ouvre approxime en jours calendaires).
    # A revoir avec le metier : ne tient pas compte des jours feries.
    $oraclePlanifie = foreach ($ora in $oracleSummary) {
        $dateOra = Get-DateYyyyMMdd $ora.Date
        $dateCible = switch ($dateOra.DayOfWeek) {
            'Thursday' { $dateOra.AddDays(4) }
            'Friday'   { $dateOra.AddDays(4) }
            'Saturday' { $dateOra.AddDays(2) }
            default    { $dateOra.AddDays(2) }
        }
        [PSCustomObject]@{
            DateOrigine = $ora.Date
            DateCible   = $dateCible.ToString('yyyyMMdd')
            NbLines     = $ora.NbLines
            Total       = $ora.Total
        }
    }

    $tableauRapprochement = [System.Collections.Generic.List[object]]::new()
    foreach ($groupe in ($oraclePlanifie | Group-Object DateCible | Sort-Object Name)) {
        $dateEdfCible = $groupe.Name
        $datesOrigine = @($groupe.Group.DateOrigine | Sort-Object)

        $formattedOracleDates = ($datesOrigine |
            ForEach-Object { (Get-DateYyyyMMdd $_).ToString('dd/MM/yyyy') }) -join ' + '
        $dateEdfParsed = Get-DateYyyyMMdd $dateEdfCible

        $oraNbAttendu    = ($groupe.Group | Measure-Object NbLines -Sum).Sum
        $oraTotalAttendu = ($groupe.Group | Measure-Object Total -Sum).Sum

        $edfMatch  = $edfSummary | Where-Object { $_.DateEdf -eq $dateEdfCible } | Select-Object -First 1
        $edfVolume = if ($edfMatch) { $edfMatch.NbEdf }    else { 0 }
        $edfTotal  = if ($edfMatch) { $edfMatch.TotalEdf } else { [decimal]0 }

        $ecartNb      = $edfVolume - $oraNbAttendu
        $ecartMontant = $edfTotal - $oraTotalAttendu

        # Delai mesure depuis la premiere date d'origine du groupe.
        $delaiConstate = ($dateEdfParsed - (Get-DateYyyyMMdd $datesOrigine[0])).Days

        $tableauRapprochement.Add([PSCustomObject]@{
            Date_Oracle   = $formattedOracleDates
            Date_EDF      = $dateEdfParsed.ToString('dd/MM/yyyy')
            Nb_Oracle     = $oraNbAttendu
            Nb_EDF        = $edfVolume
            Ecart_Nb      = $ecartNb
            Total_Oracle  = [math]::Round($oraTotalAttendu, 2)
            Total_EDF     = [math]::Round($edfTotal, 2)
            Ecart_Montant = [math]::Round($ecartMontant, 2)
            Statut        = if ($ecartNb -eq 0) { "OK (J+$delaiConstate)" } else { "Écart (J+$delaiConstate)" }
        })
    }

    # -----------------------------------------------------------------
    # 6. Restitution Excel
    #    (automatisation COM : necessite Microsoft Excel installe localement)
    # -----------------------------------------------------------------
    Write-Host "Génération du classeur Excel..." -ForegroundColor Yellow

    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $excel.ScreenUpdating = $false

    # Memorise le PID de cette instance precise, avant toute autre operation.
    [uint32] $pidTrouve = 0
    [void][Win32Fenetre]::GetWindowThreadProcessId([System.IntPtr]$excel.Hwnd, [ref] $pidTrouve)
    $excelPid = [int] $pidTrouve

    $workbook = $excel.Workbooks.Add()

    $formatMontant = '# ##0,00'
    $formatNombre  = '# ##0'
    $formatTexte   = '@'

    # --- ONGLET 1 : Synthese journaliere brute ---
    $ws1 = $workbook.Sheets.Item(1)
    $ws1.Name = 'Synthèse Journalière Brute'
    $ws1.Cells.Item(1, 1).Value2 = 'ÉTAPE 1 : SYNTHÈSE JOURNALIÈRE BRUTE'
    $ws1.Cells.Item(1, 1).Font.Bold = $true
    $ws1.Cells.Item(1, 1).Font.Size = 14
    $ws1.Cells.Item(3, 1).Value2 = 'Données Émises par ORACLE'
    $ws1.Cells.Item(3, 1).Font.Bold = $true
    $ws1.Cells.Item(3, 5).Value2 = 'Données Reçues par EDF'
    $ws1.Cells.Item(3, 5).Font.Bold = $true

    Set-EnteteExcel $ws1 4 1 @('Date Gén. Oracle', 'Nb Total Lignes', 'Montant Total (€)') $COULEUR_ENTETE
    Set-EnteteExcel $ws1 4 5 @('Date Prise Chg EDF', 'Nb Prél. Pris en Chg', 'Montant Pris en Chg (€)') $COULEUR_ENTETE

    # Formats poses sur la colonne entiere avant ecriture : les dates sont
    # stockees en texte pour figer l'affichage jj/mm/aaaa.
    $ws1.Columns.Item(1).NumberFormatLocal = $formatTexte
    $ws1.Columns.Item(5).NumberFormatLocal = $formatTexte

    if ($oracleSummary.Count -gt 0) {
        $bloc = @($oracleSummary | ForEach-Object {
            , @((Get-DateYyyyMMdd $_.Date).ToString('dd/MM/yyyy'), $_.NbLines, $_.Total)
        })
        Write-BlocExcel $ws1 5 1 $bloc
        $derniere = 4 + $bloc.Count
        $ws1.Range($ws1.Cells.Item(5, 1), $ws1.Cells.Item($derniere, 1)).HorizontalAlignment = $XL_CENTER
        $ws1.Range($ws1.Cells.Item(5, 2), $ws1.Cells.Item($derniere, 2)).NumberFormatLocal = $formatNombre
        $ws1.Range($ws1.Cells.Item(5, 3), $ws1.Cells.Item($derniere, 3)).NumberFormatLocal = $formatMontant
    }

    if ($edfSummary.Count -gt 0) {
        $bloc = @($edfSummary | ForEach-Object {
            , @((Get-DateYyyyMMdd $_.DateEdf).ToString('dd/MM/yyyy'), $_.NbEdf, $_.TotalEdf)
        })
        Write-BlocExcel $ws1 5 5 $bloc
        $derniere = 4 + $bloc.Count
        $ws1.Range($ws1.Cells.Item(5, 5), $ws1.Cells.Item($derniere, 5)).HorizontalAlignment = $XL_CENTER
        $ws1.Range($ws1.Cells.Item(5, 6), $ws1.Cells.Item($derniere, 6)).NumberFormatLocal = $formatNombre
        $ws1.Range($ws1.Cells.Item(5, 7), $ws1.Cells.Item($derniere, 7)).NumberFormatLocal = $formatMontant
    }

    $ws1.UsedRange.Columns.AutoFit() | Out-Null
    $ws1.Columns.Item(1).ColumnWidth = 26

    # --- ONGLET 2 : Etat comparatif et ecarts ---
    $ws2 = $workbook.Sheets.Add([System.Reflection.Missing]::Value, $ws1)
    $ws2.Name = 'État Comparatif & Écarts'
    $ws2.Cells.Item(1, 1).Value2 = 'ÉTAPE 2 : ÉTAT COMPARATIF ET RAPPROCHEMENT DES ÉCARTS'
    $ws2.Cells.Item(1, 1).Font.Bold = $true
    $ws2.Cells.Item(1, 1).Font.Size = 14

    Set-EnteteExcel $ws2 3 1 @(
        'Date(s) Gén. Oracle', 'Date Reç. EDF (Cible)', 'Nb Attendu (Ora)', 'Nb Reçu (EDF)',
        'Écart Nombre', 'Total Attendu (Ora)', 'Total Reçu (EDF)', 'Écart Montant (€)',
        'Statut / Délai') $COULEUR_ENTETE

    $ws2.Columns.Item(1).NumberFormatLocal = $formatTexte
    $ws2.Columns.Item(2).NumberFormatLocal = $formatTexte

    if ($tableauRapprochement.Count -gt 0) {
        $bloc = @($tableauRapprochement | ForEach-Object {
            , @($_.Date_Oracle, $_.Date_EDF, $_.Nb_Oracle, $_.Nb_EDF, $_.Ecart_Nb,
                $_.Total_Oracle, $_.Total_EDF, $_.Ecart_Montant, $_.Statut)
        })
        Write-BlocExcel $ws2 4 1 $bloc
        $derniere = 3 + $bloc.Count

        $ws2.Range($ws2.Cells.Item(4, 1), $ws2.Cells.Item($derniere, 2)).HorizontalAlignment = $XL_CENTER
        $ws2.Range($ws2.Cells.Item(4, 3), $ws2.Cells.Item($derniere, 5)).NumberFormatLocal = $formatNombre
        $ws2.Range($ws2.Cells.Item(4, 6), $ws2.Cells.Item($derniere, 8)).NumberFormatLocal = $formatMontant

        # Surlignage : uniquement sur les lignes en ecart, donc peu d'appels COM.
        $rowIdx = 4
        foreach ($row in $tableauRapprochement) {
            if ($row.Ecart_Nb -ne 0) {
                $ws2.Range($ws2.Cells.Item($rowIdx, 5), $ws2.Cells.Item($rowIdx, 5)).Interior.Color = $COULEUR_ECART
                $ws2.Range($ws2.Cells.Item($rowIdx, 8), $ws2.Cells.Item($rowIdx, 9)).Interior.Color = $COULEUR_ECART
                $ws2.Cells.Item($rowIdx, 9).Font.Bold = $true
            } else {
                $ws2.Cells.Item($rowIdx, 9).Interior.Color = $COULEUR_OK
            }
            $rowIdx++
        }
    }

    $ws2.UsedRange.Columns.AutoFit() | Out-Null
    $ws2.Columns.Item(1).ColumnWidth = 22

    # --- ONGLET 3 : Fichiers de rejets bruts ---
    $ws3 = $workbook.Sheets.Add([System.Reflection.Missing]::Value, $ws2)
    $ws3.Name = 'Fichiers de Rejets Bruts'
    $ws3.Cells.Item(1, 1).Value2 = 'DONNÉES BRUTES EXTRAITES DES FICHIERS DE REJETS'
    $ws3.Cells.Item(1, 1).Font.Bold = $true
    $ws3.Cells.Item(1, 1).Font.Size = 14

    Set-EnteteExcel $ws3 3 1 @(
        'Nom du Fichier Source',
        'Ligne Brute (Contenu Intégral du Fichier CSV)') $COULEUR_BRUT

    # Colonne en mode texte strict : preserve les IBAN et les zeros de tete.
    $ws3.Columns.Item(2).NumberFormatLocal = $formatTexte

    if ($lignesBrutesRejets.Count -gt 0) {
        $bloc = @($lignesBrutesRejets | ForEach-Object { , @($_.Fichier, $_.TexteBrut) })
        Write-BlocExcel $ws3 4 1 $bloc
    }

    $ws3.Columns.Item(1).ColumnWidth = 35
    $ws3.Columns.Item(2).ColumnWidth = 120

    # --- Sauvegarde ---
    $workbook.SaveAs($outputPath)
    $workbook.Close($false)
    $workbook = $null

    Write-Host "`n=======================================================" -ForegroundColor Green
    Write-Host " Rapprochement complété avec succès !" -ForegroundColor Green
    Write-Host " Fichier : $outputPath" -ForegroundColor Yellow
    Write-Host " Oracle : $($diag.LignesOracle) ligne(s) / EDF : $($diag.LignesEdf) ligne(s) / Rejets : $($diag.LignesRejets) ligne(s)" -ForegroundColor Gray
    if ($diag.Avertissements.Count -gt 0) {
        Write-Host " $($diag.Avertissements.Count) avertissement(s) - rapport potentiellement incomplet." -ForegroundColor Yellow
    }
    Write-Host "=======================================================" -ForegroundColor Green
}
catch {
    Write-Host "Erreur critique : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    $global:LASTEXITCODE = 1
}
finally {
    # Liberation systematique : sans cela, un echec laisse un EXCEL.EXE orphelin
    # invisible qui s'accumule a chaque execution. Les references de feuilles
    # doivent partir avant le classeur, sinon Quit() reste bloque.
    foreach ($feuilleVar in 'ws3', 'ws2', 'ws1') {
        $feuille = Get-Variable -Name $feuilleVar -Scope Script -ValueOnly -ErrorAction SilentlyContinue
        if ($feuille) {
            try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($feuille) | Out-Null } catch { }
            Set-Variable -Name $feuilleVar -Scope Script -Value $null
        }
    }
    if ($workbook) {
        try { $workbook.Close($false) } catch { }
        try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($workbook) | Out-Null } catch { }
        $workbook = $null
    }
    if ($excel) {
        try { $excel.Quit() } catch { }
        try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null } catch { }
        $excel = $null
    }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()

    # Filet de securite : ne cible que le PID demarre par ce script.
    Stop-ExcelResiduel -ProcessId $excelPid
}

if (-not $NoPause) {
    Write-Host "`nAppuyez sur une touche pour fermer." -ForegroundColor Gray
    try { $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') } catch { }
}
