# =====================================================================
# trend_analysis.ps1 — Phase 3 : Analyse des tendances FIN-FINANCE
# =====================================================================
# Lit ctm_finance_consolidated.csv et génère un Excel 5 onglets :
#   1. Synthèse mensuelle  — nb exécutions, taux succès par mois
#   2. Durées par chaîne   — moyenne, médiane, p95 par mois
#   3. Erreurs récurrentes — top jobs en erreur sur la période
#   4. Volumétrie          — nb jobs/jour (pics et creux)
#   5. Jobs fantômes       — jobs exécutés rarement sur la période
#
# Usage : .\trend_analysis.ps1 [-DaysBack 30] [-OutputLabel '30j']
# =====================================================================
param(
    [int]   $DaysBack    = 30,
    [string]$OutputLabel = ''
)

$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot

# --- Config ---
$cfg              = Get-Content (Join-Path $scriptDir 'config.json') -Raw | ConvertFrom-Json
$consolidatedFile = Join-Path $scriptDir $cfg.consolidatedFile

if (-not $OutputLabel) { $OutputLabel = "${DaysBack}j" }
$today    = Get-Date -Format 'yyyyMMdd'
$xlsxFile = Join-Path $scriptDir "Tendances_FIN_${OutputLabel}_${today}.xlsx"

$endDate   = (Get-Date).ToString('yyyy-MM-dd')
$startDate = (Get-Date).AddDays(-$DaysBack).ToString('yyyy-MM-dd')

Write-Host "=== Analyse des tendances FIN-FINANCE ===" -ForegroundColor Cyan
Write-Host "Période : $startDate → $endDate ($DaysBack jours)"
Write-Host ""

if (-not (Test-Path $consolidatedFile)) {
    Write-Host "ERREUR : $consolidatedFile introuvable." -ForegroundColor Red
    Write-Host "Lancez d'abord : .\consolidate_finance.ps1"
    exit 1
}

# =====================================================================
# Chargement + filtrage période
# =====================================================================
Write-Host "[1/5] Chargement et filtrage..." -ForegroundColor Yellow
$allData    = Import-Csv -Path $consolidatedFile -Delimiter ',' -Encoding UTF8
$periodData = $allData | Where-Object { $_.odate_date -ge $startDate -and $_.odate_date -le $endDate }
Write-Host "  Total consolidé     : $($allData.Count) lignes"
Write-Host "  Dans la période     : $($periodData.Count) lignes"

if ($periodData.Count -eq 0) {
    Write-Host "Aucune donnée dans la période." -ForegroundColor Yellow; exit 0
}

# =====================================================================
# 1 — Synthèse mensuelle
# =====================================================================
Write-Host "[2/5] Synthèse mensuelle..." -ForegroundColor Yellow
$monthlyData = $periodData | Group-Object { $_.odate_date.Substring(0,7) } |
    Sort-Object Name | ForEach-Object {
        $g     = $_.Group
        $total = $g.Count
        $ok    = ($g | Where-Object { $_.Status -eq 'Ended OK' }).Count
        $ko    = ($g | Where-Object { $_.Status -eq 'Ended Not OK' }).Count
        $exec  = ($g | Where-Object { $_.Status -eq 'Ended Not OK' }).Count
        $wait  = ($g | Where-Object { $_.Status -eq 'Wait for Event' }).Count
        $taux  = if ($total -gt 0) { [math]::Round($ok / $total * 100, 1) } else { 0 }
        $nbChains = ($g | Select-Object 'Group Name' -Unique).Count
        $nbJobs   = ($g | Select-Object 'Job Name' -Unique).Count
        $nbDays   = ($g | Select-Object odate_date -Unique).Count
        $durs = $g | Where-Object { $_.duration_min -ne '' -and $_.duration_min -match '^[\d\.]+$' } |
                    ForEach-Object { [double]$_.duration_min }
        $durMoy = if ($durs) { [math]::Round(($durs | Measure-Object -Average).Average, 3) } else { '' }
        [PSCustomObject]@{
            'Mois'             = $_.Name
            'Total exécutions' = $total
            'Ended OK'         = $ok
            'Ended Not OK'     = $ko
            'Taux succès (%)'  = $taux
            'Chaînes actives'  = $nbChains
            'Jobs distincts'   = $nbJobs
            'Jours actifs'     = $nbDays
            'Durée moy (min)'  = $durMoy
        }
    }

# =====================================================================
# 2 — Durées par chaîne (moy, médiane, p95)
# =====================================================================
Write-Host "[3/5] Durées par chaîne..." -ForegroundColor Yellow
$chainDurData = $periodData | Group-Object 'Group Name' | Sort-Object Name | ForEach-Object {
    $g    = $_.Group
    $durs = $g | Where-Object { $_.duration_min -ne '' -and $_.duration_min -match '^[\d\.]+$' } |
                 ForEach-Object { [double]$_.duration_min } | Sort-Object
    if ($durs.Count -eq 0) { return }
    $avg = [math]::Round(($durs | Measure-Object -Average).Average, 3)
    $med = if ($durs.Count % 2 -eq 1) {
               $durs[[math]::Floor($durs.Count / 2)]
           } else {
               [math]::Round(($durs[$durs.Count / 2 - 1] + $durs[$durs.Count / 2]) / 2, 3)
           }
    $p95idx = [math]::Floor($durs.Count * 0.95)
    $p95    = $durs[[math]::Min($p95idx, $durs.Count - 1)]
    $ok     = ($g | Where-Object { $_.Status -eq 'Ended OK' }).Count
    $ko     = ($g | Where-Object { $_.Status -eq 'Ended Not OK' }).Count
    [PSCustomObject]@{
        'Chaîne'          = $_.Name
        'Nb exécutions'   = $g.Count
        'Ended OK'        = $ok
        'Ended Not OK'    = $ko
        'Taux succès (%)' = if ($g.Count -gt 0) { [math]::Round($ok / $g.Count * 100, 1) } else { 0 }
        'Durée moy (min)' = $avg
        'Durée méd (min)' = $med
        'Durée p95 (min)' = [math]::Round($p95, 3)
        'Durée max (min)' = [math]::Round(($durs | Measure-Object -Maximum).Maximum, 3)
        'Nb jours actifs' = ($g | Select-Object odate_date -Unique).Count
    }
}

# =====================================================================
# 3 — Erreurs récurrentes
# =====================================================================
Write-Host "[4/5] Top erreurs récurrentes..." -ForegroundColor Yellow
$errorsAll    = $periodData | Where-Object { $_.Status -eq 'Ended Not OK' }
$errorsRecData = $errorsAll | Group-Object 'Job Name' | Sort-Object Count -Descending | ForEach-Object {
    $g       = $_.Group
    $gn      = ($g | Select-Object -First 1).'Group Name'
    $nbDays  = ($g | Select-Object odate_date -Unique).Count
    $premier = ($g | Sort-Object odate_date | Select-Object -First 1).odate_date
    $dernier = ($g | Sort-Object odate_date -Descending | Select-Object -First 1).odate_date
    [PSCustomObject]@{
        'Chaîne'                   = $gn
        'Job Name'                 = $_.Name
        "Nb erreurs (${DaysBack}j)"= $_.Count
        'Nb jours en erreur'       = $nbDays
        'Première erreur'          = $premier
        'Dernière erreur'          = $dernier
        'Description'              = ($g | Select-Object -First 1).Description
    }
}

# =====================================================================
# 4 — Volumétrie quotidienne
# =====================================================================
Write-Host "[5/5] Volumétrie quotidienne..." -ForegroundColor Yellow
$allDates     = $periodData | Select-Object odate_date -Unique | Sort-Object odate_date
$avgPerDay    = if ($allDates.Count -gt 0) { [math]::Round($periodData.Count / $allDates.Count, 0) } else { 0 }

$volumeData = $allDates | ForEach-Object {
    $d  = $_.odate_date
    $dg = $periodData | Where-Object { $_.odate_date -eq $d }
    $ok = ($dg | Where-Object { $_.Status -eq 'Ended OK' }).Count
    $ko = ($dg | Where-Object { $_.Status -eq 'Ended Not OK' }).Count
    $alert = ''
    if ($dg.Count -gt $avgPerDay * 1.3) { $alert = 'PIC' }
    if ($dg.Count -lt $avgPerDay * 0.7) { $alert = 'CREUX' }
    [PSCustomObject]@{
        'Date'             = $d
        'Nb exécutions'    = $dg.Count
        'Ended OK'         = $ok
        'Ended Not OK'     = $ko
        'Taux succès (%)'  = if ($dg.Count -gt 0) { [math]::Round($ok / $dg.Count * 100, 1) } else { 0 }
        'Nb chaînes'       = ($dg | Select-Object 'Group Name' -Unique).Count
        'vs Moy (±30%)'    = $alert
    }
} | Sort-Object Date

# =====================================================================
# 5 — Jobs fantômes (exécutés rarement)
# =====================================================================
$totalDays   = $allDates.Count
$ghostThresh = [math]::Max([math]::Floor($totalDays * 0.15), 2)  # < 15% des jours

$ghostData = $periodData | Group-Object 'Job Name' | ForEach-Object {
    $nbDaysJob = ($_.Group | Select-Object odate_date -Unique).Count
    if ($nbDaysJob -le $ghostThresh) {
        $g  = $_.Group
        $gn = ($g | Select-Object -First 1).'Group Name'
        [PSCustomObject]@{
            'Chaîne'                     = $gn
            'Job Name'                   = $_.Name
            'Nb jours exécuté'           = $nbDaysJob
            "Total jours période"        = $totalDays
            'Fréquence (%)'              = [math]::Round($nbDaysJob / $totalDays * 100, 1)
            'Dernière exécution'         = ($g | Sort-Object odate_date -Descending | Select-Object -First 1).odate_date
            'Statut dernière exécution'  = ($g | Sort-Object odate_date -Descending | Select-Object -First 1).Status
        }
    }
} | Sort-Object 'Nb jours exécuté'

# =====================================================================
# Génération Excel
# =====================================================================
Write-Host ""
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

    $sh1 = $wb.Worksheets.Item(1)
    Write-SheetData -Sheet $sh1 -Name 'Synthese mensuelle' -Data $monthlyData -HeaderColor '#2E75B6'

    $sh2 = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    Write-SheetData -Sheet $sh2 -Name 'Durees par chaine' -Data $chainDurData -HeaderColor '#375623'

    $sh3 = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    Write-SheetData -Sheet $sh3 -Name 'Erreurs recurrentes' -Data $errorsRecData -HeaderColor '#C00000'

    $sh4 = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    Write-SheetData -Sheet $sh4 -Name 'Volumetrie quotidienne' -Data $volumeData -HeaderColor '#4472C4'

    $sh5 = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    Write-SheetData -Sheet $sh5 -Name 'Jobs fantomes' -Data $ghostData -HeaderColor '#7030A0'

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
Write-Host "=== Analyse terminée ===" -ForegroundColor Cyan
Write-Host "  Synthèse mensuelle : $($monthlyData.Count) mois"
Write-Host "  Durées par chaîne  : $($chainDurData.Count) chaînes"
Write-Host "  Erreurs récurr.    : $($errorsRecData.Count) jobs"
Write-Host "  Jours volumétrie   : $($volumeData.Count) jours"
Write-Host "  Jobs fantômes      : $($ghostData.Count) jobs"
