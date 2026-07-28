# =====================================================================
# consolidate_finance.ps1 — Phase 1 : Consolidation incrémentale
# =====================================================================
# Lit les nouveaux CSV depuis Extraits/, filtre FIN-FINANCE,
# enrichit (odate_date, duration_min) et maintient un CSV consolidé.
# Déduplication par 'Order id' (identifiant unique de job CTM).
# Incrémental : seuls les fichiers non encore traités sont relus.
#
# Usage : .\consolidate_finance.ps1
# Sortie : ctm_finance_consolidated.csv
# =====================================================================
$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot

# --- Config ---
$cfg              = Get-Content (Join-Path $scriptDir 'config.json') -Raw | ConvertFrom-Json
$csvFolder        = Join-Path $scriptDir $cfg.csvFolder
$consolidatedFile = Join-Path $scriptDir $cfg.consolidatedFile
$processedFile    = Join-Path $scriptDir $cfg.processedFile
$appFilter        = $cfg.appFilter
$delimiter        = ';'
$cultureEN        = [System.Globalization.CultureInfo]::new('en-US')

Write-Host "=== Consolidation FIN-FINANCE ===" -ForegroundColor Cyan
Write-Host "Dossier CSV       : $csvFolder"
Write-Host "Fichier consolide : $consolidatedFile"
Write-Host ""

# --- Fichiers déjà traités ---
$processed = @{}
if (Test-Path $processedFile) {
    Get-Content $processedFile | Where-Object { $_.Trim() -ne '' } | ForEach-Object {
        $processed[$_] = $true
    }
}
Write-Host "Fichiers déjà traités : $($processed.Count)"

# --- Nouveaux fichiers ---
$allFiles = Get-ChildItem -Path $csvFolder -Filter '*.csv' | Sort-Object Name
$newFiles  = $allFiles | Where-Object { -not $processed.ContainsKey($_.Name) }

Write-Host "Fichiers disponibles  : $($allFiles.Count)"
Write-Host "Nouveaux à traiter    : $($newFiles.Count)"
Write-Host ""

if ($newFiles.Count -eq 0) {
    Write-Host "Aucun nouveau fichier. Consolidé à jour." -ForegroundColor Yellow
    if (Test-Path $consolidatedFile) {
        $existing = Import-Csv -Path $consolidatedFile -Delimiter ',' -Encoding UTF8
        Write-Host "Lignes consolidées : $($existing.Count)"
    }
    exit 0
}

# --- Charger consolidé existant (index par Order id) ---
$existingRows = [System.Collections.Generic.Dictionary[string,object]]::new()
if (Test-Path $consolidatedFile) {
    Write-Host "Chargement du consolidé existant..."
    $existing = Import-Csv -Path $consolidatedFile -Delimiter ',' -Encoding UTF8
    foreach ($r in $existing) {
        $key = $r.'Order id'
        if ($key) { $existingRows[$key] = $r }
    }
    Write-Host "  Lignes existantes : $($existingRows.Count)"
}

# --- Traiter les nouveaux fichiers ---
$newCount   = 0
$errorFiles = 0

Write-Host "Traitement des nouveaux fichiers..."
foreach ($file in $newFiles) {
    Write-Host "  $($file.Name)" -ForegroundColor DarkGray
    try {
        $rows    = Import-Csv -Path $file.FullName -Delimiter $delimiter -Encoding UTF8
        $finRows = $rows | Where-Object { $_.Application -eq $appFilter }

        foreach ($row in $finRows) {
            $orderId = ($row.'Order id' -replace '"', '').Trim()
            if (-not $orderId) { continue }

            # Parse odate_date (format : "November 9, 2025")
            $odateRaw  = ($row.Odate -replace '"', '').Trim()
            $odateDate = ''
            if ($odateRaw) {
                try { $odateDate = [datetime]::Parse($odateRaw, $cultureEN).ToString('yyyy-MM-dd') } catch { }
            }

            # Calcul duration_min depuis Start/End Time
            $durationMin = ''
            $startRaw    = ($row.'Start Time' -replace '"', '').Trim()
            $endRaw      = ($row.'End Time'   -replace '"', '').Trim()
            if ($startRaw -and $endRaw) {
                try {
                    $dtS         = [datetime]::Parse($startRaw, $cultureEN)
                    $dtE         = [datetime]::Parse($endRaw,   $cultureEN)
                    $durationMin = [math]::Round(($dtE - $dtS).TotalMinutes, 3)
                } catch { }
            }

            $isNew = -not $existingRows.ContainsKey($orderId)

            $enriched = [PSCustomObject][ordered]@{
                'Application'    = $row.Application
                'Group Name'     = $row.'Group Name'
                'Job Name'       = $row.'Job Name'
                'Odate'          = $odateRaw
                'odate_date'     = $odateDate
                'Start Time'     = $startRaw
                'End Time'       = $endRaw
                'Run Time'       = ($row.'Run Time' -replace '"', '').Trim()
                'duration_min'   = $durationMin
                'Status'         = $row.Status
                'Description'    = $row.Description
                'Member Name'    = $row.'Member Name'
                'Task Type'      = $row.'Task Type'
                'Deleted'        = $row.Deleted
                'Rerun Counter'  = $row.'Rerun Counter'
                'Cyclic'         = $row.Cyclic
                'CONTROL-M Name' = $row.'CONTROL-M Name'
                'Run as User'    = $row.'Run as User'
                'Hostname'       = $row.Hostname
                'Nodegroup'      = $row.Nodegroup
                'Order id'       = $orderId
                'source_file'    = $file.Name
            }

            if ($isNew) { $newCount++ }
            $existingRows[$orderId] = $enriched
        }

        $processed[$file.Name] = $true

    } catch {
        Write-Host "  ERREUR $($file.Name) : $($_.Exception.Message)" -ForegroundColor Red
        $errorFiles++
    }
}

Write-Host ""
Write-Host "  Nouvelles lignes ajoutées : $newCount"
Write-Host "  Total consolidé           : $($existingRows.Count)"
Write-Host "  Fichiers en erreur        : $errorFiles"

# --- Sauvegarder le CSV consolidé ---
Write-Host ""
Write-Host "Sauvegarde : $consolidatedFile..."
$existingRows.Values |
    Sort-Object odate_date, 'Group Name', 'Job Name' |
    Export-Csv -Path $consolidatedFile -Delimiter ',' -Encoding UTF8 -NoTypeInformation

# --- Mettre à jour la liste des fichiers traités ---
$processed.Keys | Sort-Object | Set-Content $processedFile -Encoding UTF8

Write-Host ""
Write-Host "=== Consolidation terminée ===" -ForegroundColor Cyan
Write-Host "  FIN-FINANCE total : $($existingRows.Count) jobs"
Write-Host "  Fichiers traités  : $($processed.Count) / $($allFiles.Count)"

# --- Résumé par date ---
Write-Host ""
Write-Host "--- Distribution par date (10 dernières) ---"
$existingRows.Values |
    Group-Object odate_date |
    Sort-Object Name -Descending |
    Select-Object -First 10 |
    ForEach-Object {
        $ok  = ($_.Group | Where-Object { $_.Status -eq 'Ended OK'     }).Count
        $ko  = ($_.Group | Where-Object { $_.Status -eq 'Ended Not OK' }).Count
        Write-Host ("  {0}  : {1,5} jobs  |  OK={2}  KO={3}" -f $_.Name, $_.Count, $ok, $ko)
    }
