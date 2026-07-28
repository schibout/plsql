# =====================================================================
# oracle_mapping.ps1 — Phase 4 : Corrélation CTM ↔ Oracle EBS
# =====================================================================
# Compare les jobs CTM FIN-FINANCE avec les programmes concurrents
# Oracle EBS exécutés sur la même fenêtre temporelle.
#
# Stratégie de mapping en 3 niveaux :
#   1. Correspondance directe par nom (NOM_COURT dans le nom du job)
#   2. Matching temporel (job CTM Ended OK + FCR lancé dans la fenêtre)
#   3. Export du mapping pour enrichissement manuel
#
# Usage : .\oracle_mapping.ps1 [-DaysBack 7]
# Sortie : ctm_oracle_mapping.csv + rapport Excel
#
# PREREQUIS : Données Oracle dans Programmes_Oracle_Concurrent_20260417.csv
#             ou connexion oracleProd disponible (MCP SQLcl)
# =====================================================================
param([int]$DaysBack = 7)

$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot

# --- Config ---
$cfg              = Get-Content (Join-Path $scriptDir 'config.json') -Raw | ConvertFrom-Json
$consolidatedFile = Join-Path $scriptDir $cfg.consolidatedFile
$mappingFile      = Join-Path $scriptDir 'ctm_oracle_mapping.csv'
$today            = Get-Date -Format 'yyyyMMdd'
$xlsxFile         = Join-Path $scriptDir "Mapping_CTM_Oracle_${today}.xlsx"

$endDate   = (Get-Date).ToString('yyyy-MM-dd')
$startDate = (Get-Date).AddDays(-$DaysBack).ToString('yyyy-MM-dd')

Write-Host "=== Mapping CTM ↔ Oracle EBS ===" -ForegroundColor Cyan
Write-Host "Période : $startDate → $endDate ($DaysBack jours)"
Write-Host ""

if (-not (Test-Path $consolidatedFile)) {
    Write-Host "ERREUR : $consolidatedFile introuvable." -ForegroundColor Red
    Write-Host "Lancez d'abord : .\consolidate_finance.ps1"; exit 1
}

# =====================================================================
# Chargement CTM + Oracle
# =====================================================================
Write-Host "[1/4] Chargement des données CTM..." -ForegroundColor Yellow
$allCtm    = Import-Csv -Path $consolidatedFile -Delimiter ',' -Encoding UTF8
$periodCtm = $allCtm | Where-Object { $_.odate_date -ge $startDate -and $_.odate_date -le $endDate }
Write-Host "  Jobs CTM FIN-FINANCE dans la période : $($periodCtm.Count)"

# Charger le CSV Oracle le plus récent disponible
Write-Host "[2/4] Chargement des données Oracle..." -ForegroundColor Yellow
$oracleCsv = Get-ChildItem -Path $scriptDir -Filter 'Programmes_Oracle_Concurrent_*.csv' |
             Sort-Object Name -Descending | Select-Object -First 1

if (-not $oracleCsv) {
    Write-Host "  AVERTISSEMENT : Aucun fichier Programmes_Oracle_Concurrent_*.csv trouvé." -ForegroundColor Yellow
    Write-Host "  Lancez d'abord l'extraction Oracle (MCP SQLcl) pour enrichir le mapping."
    $oracleData = @()
} else {
    Write-Host "  Fichier Oracle : $($oracleCsv.Name)"
    $oracleData = Import-Csv -Path $oracleCsv.FullName -Delimiter ',' -Encoding UTF8
    Write-Host "  Programmes Oracle : $($oracleData.Count) lignes"
}

# Index Oracle par NOM_COURT (clé technique)
$oracleIndex = @{}
foreach ($r in $oracleData) {
    $key = $r.NOM_COURT.ToUpper().Trim()
    if (-not $oracleIndex.ContainsKey($key)) { $oracleIndex[$key] = $r }
}

# =====================================================================
# Matching niveau 1 : nom du job CTM contient un NOM_COURT Oracle
# =====================================================================
Write-Host "[3/4] Matching CTM ↔ Oracle..." -ForegroundColor Yellow

# Référentiel : jobs CTM distincts avec statut Ended OK
$ctmJobs = $periodCtm | Where-Object { $_.Status -eq 'Ended OK' } |
           Select-Object 'Job Name', 'Group Name', 'Member Name', 'Run as User', 'Hostname' -Unique |
           Sort-Object 'Group Name', 'Job Name'

$mappingResults = foreach ($job in $ctmJobs) {
    $jn          = $job.'Job Name'.ToUpper()
    $memberName  = $job.'Member Name'.ToUpper()
    $matchLevel  = 'Aucun'
    $oracleMatch = $null
    $confidence  = 0

    # Niveau 1a : NOM_COURT exact dans le nom du job CTM
    foreach ($key in $oracleIndex.Keys) {
        if ($jn -like "*$key*" -or $memberName -like "*$key*") {
            $oracleMatch = $oracleIndex[$key]
            $matchLevel  = 'Direct (nom)'
            $confidence  = 90
            break
        }
    }

    # Niveau 1b : fragments communs significatifs (>= 6 chars)
    if (-not $oracleMatch) {
        $bestLen = 5
        foreach ($key in $oracleIndex.Keys) {
            if ($key.Length -gt $bestLen -and ($jn -like "*$key*" -or $jn -like "*$($key.Substring(0,[math]::Min(6,$key.Length)))*")) {
                $oracleMatch = $oracleIndex[$key]
                $matchLevel  = 'Partiel (fragment)'
                $confidence  = 60
                $bestLen     = $key.Length
            }
        }
    }

    # Stats CTM sur la période pour ce job
    $jobStats = $periodCtm | Where-Object { $_.'Job Name' -eq $job.'Job Name' }
    $nbExec   = $jobStats.Count
    $nbOK     = ($jobStats | Where-Object { $_.Status -eq 'Ended OK' }).Count
    $nbKO     = ($jobStats | Where-Object { $_.Status -eq 'Ended Not OK' }).Count

    [PSCustomObject]@{
        'Chaîne CTM'             = $job.'Group Name'
        'Job CTM'                = $job.'Job Name'
        'Member Name'            = $job.'Member Name'
        'Run as User'            = $job.'Run as User'
        'NOM_COURT Oracle'       = if ($oracleMatch) { $oracleMatch.NOM_COURT }    else { '' }
        'Programme Oracle'       = if ($oracleMatch) { $oracleMatch.PROGRAMME }    else { '' }
        'Application Oracle'     = if ($oracleMatch) { $oracleMatch.APPLICATION }  else { '' }
        'Niveau matching'        = $matchLevel
        'Confiance (%)'          = $confidence
        'Nb exéc CTM'            = $nbExec
        'Nb OK'                  = $nbOK
        'Nb KO'                  = $nbKO
        'Mapping manuel'         = ''   # colonne à remplir manuellement
        'Notes'                  = ''   # colonne à remplir manuellement
    }
}

# =====================================================================
# Fusionner avec mapping manuel existant
# =====================================================================
if (Test-Path $mappingFile) {
    Write-Host "  Fusion avec mapping manuel existant..."
    $existingMapping = Import-Csv -Path $mappingFile -Delimiter ',' -Encoding UTF8
    $manualIndex = @{}
    foreach ($r in $existingMapping) {
        if ($r.'Mapping manuel' -ne '') { $manualIndex[$r.'Job CTM'] = $r }
    }
    foreach ($r in $mappingResults) {
        if ($manualIndex.ContainsKey($r.'Job CTM')) {
            $manual = $manualIndex[$r.'Job CTM']
            if ($r.'Mapping manuel' -eq '' -and $manual.'Mapping manuel' -ne '') {
                $r.'Mapping manuel' = $manual.'Mapping manuel'
                $r.'Notes'          = $manual.'Notes'
            }
        }
    }
}

# =====================================================================
# Statistiques de matching
# =====================================================================
$nbTotal   = $mappingResults.Count
$nbDirect  = ($mappingResults | Where-Object { $_.'Niveau matching' -eq 'Direct (nom)' }).Count
$nbPartial = ($mappingResults | Where-Object { $_.'Niveau matching' -eq 'Partiel (fragment)' }).Count
$nbNone    = ($mappingResults | Where-Object { $_.'Niveau matching' -eq 'Aucun' }).Count
$pctMatch  = if ($nbTotal -gt 0) { [math]::Round(($nbDirect + $nbPartial) / $nbTotal * 100, 1) } else { 0 }

Write-Host "  Jobs CTM distincts (Ended OK) : $nbTotal"
Write-Host "  Matchés direct               : $nbDirect"
Write-Host "  Matchés partiel              : $nbPartial"
Write-Host "  Sans correspondance          : $nbNone"
Write-Host "  Taux de matching             : $pctMatch%"

# Sauvegarder le CSV de mapping
Write-Host ""
Write-Host "[4/4] Sauvegarde : $mappingFile"
$mappingResults | Export-Csv -Path $mappingFile -Delimiter ',' -Encoding UTF8 -NoTypeInformation

# =====================================================================
# Génération Excel
# =====================================================================
Write-Host "Génération Excel : $xlsxFile" -ForegroundColor Yellow

function ConvertTo-OleColor ([string]$hex) {
    $hex = $hex.TrimStart('#')
    $r   = [Convert]::ToInt32($hex.Substring(0,2), 16)
    $g   = [Convert]::ToInt32($hex.Substring(2,2), 16)
    $b   = [Convert]::ToInt32($hex.Substring(4,2), 16)
    return $r + ($g * 256) + ($b * 65536)
}

function Write-SheetData {
    param([object]$Sheet, [string]$Name, [array]$Data, [string]$HeaderColor = '#4472C4')
    $Sheet.Name = $Name
    if (-not $Data -or $Data.Count -eq 0) { $Sheet.Cells.Item(1,1) = 'Aucune donnée'; return }
    $props    = $Data[0].PSObject.Properties.Name
    $nbCols   = $props.Count
    $nbRows   = $Data.Count + 1
    $oleColor = ConvertTo-OleColor $HeaderColor
    $array    = [System.Array]::CreateInstance([object], $nbRows, $nbCols)
    for ($col = 0; $col -lt $nbCols; $col++) { $array.SetValue($props[$col], 0, $col) }
    for ($row = 0; $row -lt $Data.Count; $row++) {
        $item = $Data[$row]
        for ($col = 0; $col -lt $nbCols; $col++) {
            $val = $item.($props[$col]); if ($null -eq $val) { $val = '' }
            $array.SetValue([string]$val, $row + 1, $col)
        }
    }
    $rng = $Sheet.Range($Sheet.Cells.Item(1,1), $Sheet.Cells.Item($nbRows, $nbCols))
    $rng.Value2 = $array
    $hdr = $Sheet.Range($Sheet.Cells.Item(1,1), $Sheet.Cells.Item(1, $nbCols))
    $hdr.Font.Bold = $true; $hdr.Font.Color = 16777215; $hdr.Interior.Color = $oleColor
    $Sheet.UsedRange.EntireColumn.AutoFit() | Out-Null
    $Sheet.Rows.Item(2).Select() | Out-Null
    $excel.ActiveWindow.FreezePanes = $true
}

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

try {
    $wb = $excel.Workbooks.Add()

    # Onglet 1 : mapping complet
    $sh1 = $wb.Worksheets.Item(1)
    Write-SheetData -Sheet $sh1 -Name 'Mapping CTM Oracle' -Data $mappingResults -HeaderColor '#2E75B6'

    # Colorier selon niveau matching
    $colorMatch = @{
        'Direct (nom)'       = ConvertTo-OleColor '#E2EFDA'
        'Partiel (fragment)' = ConvertTo-OleColor '#FFEB9C'
        'Aucun'              = ConvertTo-OleColor '#FFC7CE'
    }
    $colLevel = 8  # colonne 'Niveau matching' (1-based)
    for ($i = 2; $i -le $mappingResults.Count + 1; $i++) {
        $lvl = $sh1.Cells.Item($i, $colLevel).Text
        if ($colorMatch.ContainsKey($lvl)) {
            $sh1.Cells.Item($i, $colLevel).Interior.Color = $colorMatch[$lvl]
        }
    }

    # Onglet 2 : non matchés (à compléter manuellement)
    $nonMatchedData = $mappingResults | Where-Object { $_.'Niveau matching' -eq 'Aucun' } |
                      Sort-Object 'Chaîne CTM', 'Job CTM'
    $sh2 = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    Write-SheetData -Sheet $sh2 -Name 'A mapper manuellement' -Data $nonMatchedData -HeaderColor '#C00000'

    # Onglet 3 : top jobs Oracle dans la période
    $oracleTopData = $oracleData | Sort-Object { [int]$_.NB_EXECUTIONS } -Descending | Select-Object -First 50 |
        ForEach-Object {
            [PSCustomObject]@{
                'NOM_COURT'       = $_.NOM_COURT
                'Programme'       = $_.PROGRAMME
                'Application'     = $_.APPLICATION
                'Mois'            = $_.MOIS
                'Nb exécutions'   = $_.NB_EXECUTIONS
                'Durée moy (min)' = $_.DUREE_MOY_MIN
                'Durée max (min)' = $_.DUREE_MAX_MIN
                'Statut'          = $_.STATUT
            }
        }
    $sh3 = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    Write-SheetData -Sheet $sh3 -Name 'Top Oracle' -Data $oracleTopData -HeaderColor '#375623'

    $wb.Worksheets.Item(1).Activate()
    if (Test-Path $xlsxFile) { Remove-Item $xlsxFile -Force }
    $wb.SaveAs($xlsxFile, 51)
    Write-Host "Fichier généré : $xlsxFile" -ForegroundColor Green

} finally {
    $wb.Close($false)
    $excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
    [GC]::Collect()
}

Write-Host ""
Write-Host "=== Mapping terminé ===" -ForegroundColor Cyan
Write-Host "  Jobs CTM distincts    : $nbTotal"
Write-Host "  Matchés direct        : $nbDirect  ($([math]::Round($nbDirect/$nbTotal*100,1))%)"
Write-Host "  Matchés partiel       : $nbPartial ($([math]::Round($nbPartial/$nbTotal*100,1))%)"
Write-Host "  Sans correspondance   : $nbNone    ($([math]::Round($nbNone/$nbTotal*100,1))%)"
Write-Host ""
Write-Host "  → Complétez la colonne 'Mapping manuel' dans :"
Write-Host "    $mappingFile"
Write-Host "    ou l'onglet 'A mapper manuellement' du fichier Excel"
