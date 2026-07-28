# =====================================================================
# weekly_report.ps1 — Phase 5 : Rapport hebdomadaire FIN-FINANCE
# =====================================================================
# Lance la consolidation incrémentale puis trend_analysis (30 jours)
# et oracle_mapping (7 jours). À planifier le vendredi soir.
#
# Usage : .\weekly_report.ps1
# =====================================================================
$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot
$logFile   = Join-Path $scriptDir "weekly_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Log { param([string]$msg, [string]$color = 'White')
    $ts = Get-Date -Format 'HH:mm:ss'
    $line = "[$ts] $msg"
    Write-Host $line -ForegroundColor $color
    Add-Content $logFile -Value $line -Encoding UTF8
}

Log "=== Rapport hebdomadaire FIN-FINANCE ===" Cyan
Log "Dossier : $scriptDir"
Log ""

try {
    Log "--- Étape 1/3 : Consolidation incrémentale ---" Yellow
    & (Join-Path $scriptDir 'consolidate_finance.ps1')
    Log "  Consolidation OK" Green

    Log ""
    Log "--- Étape 2/3 : Analyse des tendances (30j) ---" Yellow
    & (Join-Path $scriptDir 'trend_analysis.ps1') -DaysBack 30 -OutputLabel '30j'
    Log "  Tendances OK" Green

    Log ""
    Log "--- Étape 3/3 : Mapping CTM ↔ Oracle (7j) ---" Yellow
    & (Join-Path $scriptDir 'oracle_mapping.ps1') -DaysBack 7
    Log "  Mapping OK" Green

} catch {
    Log "ERREUR : $($_.Exception.Message)" Red
    exit 1
}

Log ""
Log "=== Rapport hebdomadaire terminé ===" Cyan
Log "Log : $logFile"
