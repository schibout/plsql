# =====================================================================
# daily_dashboard.ps1 — Phase 2 : Tableau de bord quotidien FIN-FINANCE
# =====================================================================
# Lit ctm_finance_consolidated.csv et génère un Excel 5 onglets :
#   1. KPI            — indicateurs clés du jour cible
#   2. Erreurs J-1    — tous les Ended Not OK
#   3. Jobs longs     — durées anormales (moy + N×écart-type)
#   4. Jobs manquants — jobs attendus absents du jour cible
#   5. Chaînes risque — chaînes ayant au moins 1 erreur
#
# Usage : .\daily_dashboard.ps1 [-TargetDate yyyy-MM-dd]
# Défaut : date d'hier
# =====================================================================
param([string]$TargetDate = '')

$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot

# --- Config ---
$cfg              = Get-Content (Join-Path $scriptDir 'config.json') -Raw | ConvertFrom-Json
$consolidatedFile = Join-Path $scriptDir $cfg.consolidatedFile
$longJobMult      = [double]$cfg.thresholds.longJobMultiplier
$missingLookback  = [int]$cfg.thresholds.missingJobLookbackDays
$trendWindow      = [int]$cfg.thresholds.trendWindowDays

if (-not $TargetDate) { $TargetDate = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd') }
$xlsxFile = Join-Path $scriptDir "Dashboard_FIN_$($TargetDate -replace '-','').xlsx"

Write-Host "=== Dashboard FIN-FINANCE ===" -ForegroundColor Cyan
Write-Host "Date cible : $TargetDate"
Write-Host ""

if (-not (Test-Path $consolidatedFile)) {
    Write-Host "ERREUR : $consolidatedFile introuvable." -ForegroundColor Red
    Write-Host "Lancez d'abord : .\consolidate_finance.ps1"
    exit 1
}

# =====================================================================
# Chargement
# =====================================================================
Write-Host "[1/6] Chargement des données..." -ForegroundColor Yellow
$allData   = Import-Csv -Path $consolidatedFile -Delimiter ',' -Encoding UTF8
$todayData = $allData | Where-Object { $_.odate_date -eq $TargetDate }
Write-Host "  Total lignes consolidées : $($allData.Count)"
Write-Host "  Lignes pour $TargetDate  : $($todayData.Count)"

if ($todayData.Count -eq 0) {
    Write-Host "Aucune donnée FIN-FINANCE pour $TargetDate." -ForegroundColor Yellow
    exit 0
}

# =====================================================================
# Stats historiques (fenêtre trendWindow jours avant TargetDate)
# =====================================================================
Write-Host "[2/6] Calcul statistiques historiques ($trendWindow jours)..." -ForegroundColor Yellow
$windowStart = (Get-Date $TargetDate).AddDays(-$trendWindow).ToString('yyyy-MM-dd')
$histData    = $allData | Where-Object {
    $_.odate_date -ge $windowStart -and
    $_.odate_date -lt  $TargetDate -and
    $_.duration_min -ne '' -and
    $_.duration_min -match '^[\d\.\-]+'
}

# Statistiques par job (avg, écart-type) pour détecter les durées anormales
$jobStats = @{}
$histData | Group-Object 'Job Name' | ForEach-Object {
    $durs = $_.Group | ForEach-Object { [double]$_.duration_min } | Where-Object { $_ -ge 0 }
    if ($durs.Count -gt 2) {
        $avg    = ($durs | Measure-Object -Average).Average
        $var    = ($durs | ForEach-Object { [math]::Pow($_ - $avg, 2) } | Measure-Object -Average).Average
        $stddev = [math]::Sqrt($var)
        $jobStats[$_.Name] = @{
            Avg    = [math]::Round($avg, 3)
            Stddev = [math]::Round($stddev, 3)
            Count  = $durs.Count
            Max    = ($durs | Measure-Object -Maximum).Maximum
        }
    }
}
Write-Host "  Jobs avec historique : $($jobStats.Count)"

# =====================================================================
# 1 — KPI
# =====================================================================
Write-Host "[3/6] Calcul KPI..." -ForegroundColor Yellow

$kpiOK    = ($todayData | Where-Object { $_.Status -eq 'Ended OK' }).Count
$kpiKO    = ($todayData | Where-Object { $_.Status -eq 'Ended Not OK' }).Count
$kpiExec  = ($todayData | Where-Object { $_.Status -eq 'Executing' }).Count
$kpiWait  = ($todayData | Where-Object { $_.Status -eq 'Wait for Event' }).Count
$kpiOther = ($todayData | Where-Object { $_.Status -notin @('Ended OK','Ended Not OK','Executing','Wait for Event') }).Count
$kpiTotal = $todayData.Count
$kpiTaux  = if ($kpiTotal -gt 0) { [math]::Round($kpiOK / $kpiTotal * 100, 1) } else { 0 }
$kpiChns  = ($todayData | Select-Object 'Group Name' -Unique).Count
$dursMin  = $todayData | Where-Object { $_.duration_min -ne '' -and $_.duration_min -match '^[\d\.]+$' } |
            ForEach-Object { [double]$_.duration_min }
$durTot   = if ($dursMin) { [math]::Round(($dursMin | Measure-Object -Sum).Sum, 1) } else { 0 }
$durMoy   = if ($dursMin) { [math]::Round(($dursMin | Measure-Object -Average).Average, 3) } else { 0 }

function Get-KpiComment ([string]$ind, $val) {
    switch ($ind) {
        'Ended Not OK'          { if ($val -gt 0) { 'ALERTE' } else { 'OK' } }
        'En cours (Executing)'  { if ($val -gt 0) { 'Vérifier' } else { 'OK' } }
        'Taux de succès (%)'    { if ($val -ge 95) { 'Bon' } elseif ($val -ge 80) { 'Acceptable' } else { 'ALERTE' } }
        default                 { '' }
    }
}

$kpiData = @(
    [PSCustomObject]@{ Indicateur = 'Date analysée';       Valeur = $TargetDate; Commentaire = '' }
    [PSCustomObject]@{ Indicateur = 'Total jobs';          Valeur = $kpiTotal;   Commentaire = '' }
    [PSCustomObject]@{ Indicateur = 'Ended OK';            Valeur = $kpiOK;      Commentaire = '' }
    [PSCustomObject]@{ Indicateur = 'Ended Not OK';        Valeur = $kpiKO;      Commentaire = (Get-KpiComment 'Ended Not OK' $kpiKO) }
    [PSCustomObject]@{ Indicateur = 'En cours (Executing)';Valeur = $kpiExec;    Commentaire = (Get-KpiComment 'En cours (Executing)' $kpiExec) }
    [PSCustomObject]@{ Indicateur = 'Wait for Event';      Valeur = $kpiWait;    Commentaire = '' }
    [PSCustomObject]@{ Indicateur = 'Autre statut';        Valeur = $kpiOther;   Commentaire = '' }
    [PSCustomObject]@{ Indicateur = 'Taux de succès (%)';  Valeur = $kpiTaux;    Commentaire = (Get-KpiComment 'Taux de succès (%)' $kpiTaux) }
    [PSCustomObject]@{ Indicateur = 'Chaînes distinctes';  Valeur = $kpiChns;    Commentaire = '' }
    [PSCustomObject]@{ Indicateur = 'Durée totale (min)';  Valeur = $durTot;     Commentaire = '' }
    [PSCustomObject]@{ Indicateur = 'Durée moyenne (min)'; Valeur = $durMoy;     Commentaire = '' }
)

# =====================================================================
# 2 — Erreurs J-1
# =====================================================================
$errorsData = $todayData | Where-Object { $_.Status -eq 'Ended Not OK' } |
    Sort-Object 'Group Name', 'Job Name' | ForEach-Object {
        [PSCustomObject]@{
            'Chaîne'      = $_.'Group Name'
            'Job Name'    = $_.'Job Name'
            'Description' = $_.Description
            'Heure Début' = $_.'Start Time'
            'Heure Fin'   = $_.'End Time'
            'Durée (min)' = $_.duration_min
            'Statut'      = $_.Status
            'Hostname'    = $_.Hostname
            'Rerun'       = $_.'Rerun Counter'
            'Order id'    = $_.'Order id'
        }
    }

# =====================================================================
# 3 — Jobs longs (durée > moy + N×σ)
# =====================================================================
Write-Host "[4/6] Détection jobs longs..." -ForegroundColor Yellow
$longJobsData = $todayData |
    Where-Object { $_.duration_min -ne '' -and $_.duration_min -match '^[\d\.]+$' } |
    ForEach-Object {
        $jn    = $_.'Job Name'
        $dur   = [double]$_.duration_min
        $seuil = ''; $ratio = ''; $alerte = 'Non'
        if ($jobStats.ContainsKey($jn)) {
            $s     = $jobStats[$jn]
            $thresh = $s.Avg + $longJobMult * $s.Stddev
            $seuil  = [math]::Round($thresh, 2)
            if ($dur -gt $thresh -and $thresh -gt 0) {
                $ratio  = if ($s.Avg -gt 0) { [math]::Round($dur / $s.Avg, 1) } else { '' }
                $alerte = 'OUI'
            }
        }
        [PSCustomObject]@{
            'Chaîne'               = $_.'Group Name'
            'Job Name'             = $jn
            'Durée J-1 (min)'      = $dur
            'Seuil alerte (min)'   = $seuil
            'Ratio vs moyenne'     = $ratio
            'ALERTE'               = $alerte
            'Statut'               = $_.Status
            'Nb obs historique'    = if ($jobStats.ContainsKey($jn)) { $jobStats[$jn].Count } else { '' }
            'Durée max historique' = if ($jobStats.ContainsKey($jn)) { $jobStats[$jn].Max } else { '' }
        }
    } | Where-Object { $_.ALERTE -eq 'OUI' } | Sort-Object {
        if ($_.'Ratio vs moyenne' -ne '') { [double]$_.'Ratio vs moyenne' } else { 0 }
    } -Descending

# =====================================================================
# 4 — Jobs manquants
# =====================================================================
Write-Host "[5/6] Détection jobs manquants ($missingLookback j)..." -ForegroundColor Yellow
$winStart14  = (Get-Date $TargetDate).AddDays(-$missingLookback).ToString('yyyy-MM-dd')
$recentData  = $allData | Where-Object { $_.odate_date -ge $winStart14 -and $_.odate_date -lt $TargetDate }
$recentJobs  = $recentData | Select-Object 'Job Name', 'Group Name' -Unique
$todayJobSet = @{}; $todayData | ForEach-Object { $todayJobSet[$_.'Job Name'] = $true }

$missingData = $recentJobs | Where-Object { -not $todayJobSet.ContainsKey($_.'Job Name') } |
    Sort-Object 'Group Name', 'Job Name' | ForEach-Object {
        $jn  = $_.'Job Name'; $gn = $_.'Group Name'
        $obs = $recentData | Where-Object { $_.'Job Name' -eq $jn }
        $nbDays = ($obs | Select-Object odate_date -Unique).Count
        $last   = ($obs | Sort-Object odate_date -Descending | Select-Object -First 1).odate_date
        [PSCustomObject]@{
            'Chaîne'                         = $gn
            'Job Name'                       = $jn
            "Jours vus (${missingLookback}j)" = $nbDays
            'Dernière exécution'             = $last
            'Fréquence (%)'                  = [math]::Round($nbDays / $missingLookback * 100, 0)
        }
    }

# =====================================================================
# 5 — Chaînes à risque
# =====================================================================
Write-Host "[6/6] Calcul chaînes à risque..." -ForegroundColor Yellow
$chainesRisque = $todayData | Group-Object 'Group Name' | ForEach-Object {
    $g     = $_.Group
    $total = $g.Count
    $ok    = ($g | Where-Object { $_.Status -eq 'Ended OK' }).Count
    $ko    = ($g | Where-Object { $_.Status -eq 'Ended Not OK' }).Count
    $taux  = if ($total -gt 0) { [math]::Round($ok / $total * 100, 1) } else { 0 }
    [PSCustomObject]@{
        'Chaîne'        = $_.Name
        'Nb Jobs'       = $total
        'Ended OK'      = $ok
        'Erreurs'       = $ko
        'Taux (%)'      = $taux
        'Niveau risque' = if ($ko -ge 3) { 'CRITIQUE' } elseif ($ko -ge 1) { 'ALERTE' } elseif ($taux -lt 80) { 'FAIBLE' } else { 'OK' }
    }
} | Where-Object { $_.Erreurs -gt 0 } | Sort-Object Erreurs -Descending

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

    # Onglet 1 — KPI
    $sh1 = $wb.Worksheets.Item(1)
    Write-SheetData -Sheet $sh1 -Name "KPI $TargetDate" -Data $kpiData -HeaderColor '#375623'
    # Colorier la colonne Commentaire selon valeur
    $colorMap = @{ 'ALERTE' = '#FF0000'; 'Vérifier' = '#FFC000'; 'OK' = '#70AD47'; 'Bon' = '#70AD47'; 'Acceptable' = '#FFC000' }
    for ($i = 2; $i -le $kpiData.Count + 1; $i++) {
        $comm = $sh1.Cells.Item($i, 3).Text
        if ($colorMap.ContainsKey($comm)) {
            $sh1.Cells.Item($i, 3).Interior.Color = ConvertTo-OleColor $colorMap[$comm]
            if ($comm -eq 'ALERTE') { $sh1.Cells.Item($i, 3).Font.Bold = $true }
        }
    }

    # Onglet 2 — Erreurs
    $sh2 = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    Write-SheetData -Sheet $sh2 -Name 'Erreurs J-1' -Data $errorsData -HeaderColor '#C00000'

    # Onglet 3 — Jobs longs
    $sh3 = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    Write-SheetData -Sheet $sh3 -Name 'Jobs longs' -Data $longJobsData -HeaderColor '#ED7D31'

    # Onglet 4 — Jobs manquants
    $sh4 = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    Write-SheetData -Sheet $sh4 -Name 'Jobs manquants' -Data $missingData -HeaderColor '#7030A0'

    # Onglet 5 — Chaînes à risque
    $sh5 = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    Write-SheetData -Sheet $sh5 -Name 'Chaines a risque' -Data $chainesRisque -HeaderColor '#C00000'

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
Write-Host "=== Dashboard terminé ===" -ForegroundColor Cyan
Write-Host "  KPI              : $($kpiData.Count) indicateurs"
Write-Host "  Erreurs J-1      : $($errorsData.Count) jobs"
Write-Host "  Jobs longs       : $($longJobsData.Count) alertes"
Write-Host "  Jobs manquants   : $($missingData.Count) jobs"
Write-Host "  Chaînes à risque : $($chainesRisque.Count) chaînes"
