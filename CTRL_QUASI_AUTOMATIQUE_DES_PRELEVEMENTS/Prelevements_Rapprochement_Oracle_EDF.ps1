try {
    # -----------------------------------------------------------------
    # 1. Configuration dynamique du chemin (Répertoire Courant)
    # -----------------------------------------------------------------
    $rootPath   = $PSScriptRoot
    $edfPath    = Join-Path $rootPath "EDF"
    
    # Détection dynamique du dossier rejets (sans distinction de casse)
    $targetRejetsFolder = Get-ChildItem -Path $edfPath -Directory | Where-Object { $_.Name -like "rejets" }
    if ($targetRejetsFolder) {
        $rejetsPath = $targetRejetsFolder.FullName
    } else {
        $rejetsPath = Join-Path $edfPath "REJETS"
    }
    
    $timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputName = "Rapprochement_Oracle_EDF_$timestamp.xlsx"
    $outputPath = Join-Path $rootPath $outputName

    Write-Host "Analyse du dossier en cours : $(Split-Path $rootPath -Leaf)" -ForegroundColor Yellow

    # -----------------------------------------------------------------
    # 2. Analyse ORACLE
    # -----------------------------------------------------------------
    $oracleFiles = Get-ChildItem -Path $rootPath -Recurse -File | Where-Object { $_.Name -like "*PCX*" -or $_.Name -like "*PCL*" }
    $oracleRaw = foreach ($file in $oracleFiles) {
        $dateFolder = $file.Directory.Name
        Get-Content $file.FullName | Where-Object {
            $_ -notmatch "^HEADER" -and $_ -notmatch "^FORMAT1ENTITYID" -and $_.Trim() -ne ""
        } | ForEach-Object {
            $fields = $_.Split(',')
            if ($fields.Count -ge 6) {
                [PSCustomObject]@{ Date = $dateFolder; Montant = [decimal]($fields[5].Trim().Replace(',', '.')) }
            }
        }
    }
    if (-not $oracleRaw) { Write-Warning "Aucun fichier Oracle trouvé."; return }
    $oracleSummary = $oracleRaw | Group-Object Date | ForEach-Object {
        [PSCustomObject]@{ Date = $_.Name; NbLines = $_.Count; Total = ($_.Group | Measure-Object Montant -Sum).Sum }
    } | Sort-Object Date

    # -----------------------------------------------------------------
    # 3. Analyse EDF
    # -----------------------------------------------------------------
    $edfSummary = @()
    if (Test-Path $edfPath) {
        $edfFiles = Get-ChildItem -Path $edfPath -Filter "IMPORT_AVP_DK.*.*.csv"
        $edfRaw = foreach ($file in $edfFiles) {
            $dateEdf = $file.Name.Split('.')[1]
            Import-Csv -Path $file.FullName -Header "ColA", "ColB", "ColC", "ColD", "ColE" -Delimiter ";" | 
                Where-Object { $_.ColA -eq "ORACLE" } | ForEach-Object {
                    [PSCustomObject]@{ DateEdf = $dateEdf; NbEdf = [int]$_.ColD; TotalEdf = [decimal]($_.ColE -replace ',', '.') }
                }
        }
        $edfSummary = $edfRaw | Group-Object DateEdf | ForEach-Object {
            [PSCustomObject]@{ DateEdf = $_.Name; NbEdf = ($_.Group | Measure-Object NbEdf -Sum).Sum; TotalEdf = ($_.Group | Measure-Object TotalEdf -Sum).Sum }
        } | Sort-Object DateEdf
    }

    # -----------------------------------------------------------------
    # 4. Lecture brute et directe des fichiers de REJETS (Version Validée)
    # -----------------------------------------------------------------
    $listeLignesBrutesRejets = @()

    if (Test-Path $rejetsPath) {
        $rejetFiles = Get-ChildItem -Path $rejetsPath -File | Where-Object { $_.Name -like "REJETS_INTERNES_DK.*" }
        
        Write-Host "Nombre de fichiers de rejets détectés : $($rejetFiles.Count)" -ForegroundColor Cyan
        
        foreach ($file in $rejetFiles) {
            # Lecture pure ligne à ligne
            $lines = Get-Content $file.FullName
            foreach ($line in $lines) {
                if (-not [string]::IsNullOrWhiteSpace($line)) {
                    $listeLignesBrutesRejets += [PSCustomObject]@{
                        "Fichier"     = $file.Name
                        "TexteBrut"   = $line
                    }
                }
            }
        }
    }

    # -----------------------------------------------------------------
    # 5. Étape 2 : Préparation du Rapprochement Comparatif
    # -----------------------------------------------------------------
    $tableauRapprochement = @()
    $oraclePlanifie = foreach ($ora in $oracleSummary) {
        $dateOraParsed = [datetime]::ParseExact($ora.Date, "yyyyMMdd", $null)
        $dateCibleParsed = switch ($dateOraParsed.DayOfWeek) {
            "Thursday" { $dateOraParsed.AddDays(4) } 
            "Friday"   { $dateOraParsed.AddDays(4) } 
            "Saturday" { $dateOraParsed.AddDays(2) } 
            default    { $dateOraParsed.AddDays(2) } 
        }
        [PSCustomObject]@{ DateOrigine = $ora.Date; DateCible = $dateCibleParsed.ToString("yyyyMMdd"); NbLines = $ora.NbLines; Total = $ora.Total }
    }

    foreach ($groupe in ($oraclePlanifie | Group-Object DateCible | Sort-Object Name)) {
        $dateEdfCible = $groupe.Name
        $formattedOracleDates = ($groupe.Group.DateOrigine | ForEach-Object { [datetime]::ParseExact($_, "yyyyMMdd", $null).ToString("dd/MM/yyyy") }) -join " + "
        $dateEdfFR = [datetime]::ParseExact($dateEdfCible, "yyyyMMdd", $null).ToString("dd/MM/yyyy")

        $oraNbAttendu = ($groupe.Group | Measure-Object NbLines -Sum).Sum
        $oraTotalAttendu = ($groupe.Group | Measure-Object Total -Sum).Sum
        $edfMatch = $edfSummary | Where-Object { $_.DateEdf -eq $dateEdfCible }

        $edfVolume = if ($edfMatch) { $edfMatch.NbEdf } else { 0 }
        $edfTotal  = if ($edfMatch) { $edfMatch.TotalEdf } else { 0.0 }
        
        $ecartNb      = $edfVolume - $oraNbAttendu
        $ecartMontant = $edfTotal - $oraTotalAttendu

        $dateOraInitiale = [datetime]::ParseExact($groupe.Group[0].DateOrigine, "yyyyMMdd", $null)
        $dateEdfParsed = [datetime]::ParseExact($dateEdfCible, "yyyyMMdd", $null)
        $delaiConstate = ($dateEdfParsed - $dateOraInitiale).Days

        $tableauRapprochement += [PSCustomObject]@{
            "Date_Oracle"   = $formattedOracleDates
            "Date_EDF"      = $dateEdfFR
            "Nb_Oracle"     = $oraNbAttendu
            "Nb_EDF"        = $edfVolume
            "Ecart_Nb"      = $ecartNb
            "Total_Oracle"  = [math]::Round($oraTotalAttendu, 2)
            "Total_EDF"     = [math]::Round($edfTotal, 2)
            "Ecart_Montant" = [math]::Round($ecartMontant, 2)
            "Statut"        = if ($ecartNb -eq 0) { "OK (J+$delaiConstate)" } else { "Écart (J+$delaiConstate)" }
        }
    }

    # -----------------------------------------------------------------
    # 6. Pilotage d'Excel (Remplissage)
    # -----------------------------------------------------------------
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false; $excel.DisplayAlerts = $false
    $workbook = $excel.Workbooks.Add()
    $formatMontant = "# ##0,00"; $formatNombre = "# ##0"; $formatDate = "@"

    # --- ONGLET 1 : Synthèse Journalière Brute ---
    $ws1 = $workbook.Sheets.Item(1); $ws1.Name = "Synthèse Journalière Brute"
    $ws1.Cells.Item(1, 1) = "ÉTAPE 1 : SYNTHÈSE JOURNALIÈRE BRUTE"
    $ws1.Cells.Item(1, 1).Font.Bold = $true; $ws1.Cells.Item(1, 1).Font.Size = 14
    $ws1.Cells.Item(3, 1) = "Données Émises par ORACLE"; $ws1.Cells.Item(3, 1).Font.Bold = $true
    $ws1.Cells.Item(3, 5) = "Données Reçues par EDF"; $ws1.Cells.Item(3, 5).Font.Bold = $true

    $headersOra = @("Date Gén. Oracle", "Nb Total Lignes", "Montant Total (€)")
    for ($i = 0; $i -lt $headersOra.Count; $i++) {
        $cell = $ws1.Cells.Item(4, $i + 1); $cell.Value = $headersOra[$i]; $cell.Interior.Color = 0x7D491F; $cell.Font.Color = 0xFFFFFF; $cell.Font.Bold = $true; $cell.HorizontalAlignment = -4108
    }
    $rowIdx = 5
    foreach ($row in $oracleSummary) {
        $ws1.Cells.Item($rowIdx, 1).NumberFormatLocal = $formatDate; $ws1.Cells.Item($rowIdx, 1) = [datetime]::ParseExact($row.Date, "yyyyMMdd", $null).ToString("dd/MM/yyyy"); $ws1.Cells.Item($rowIdx, 1).HorizontalAlignment = -4108
        $ws1.Cells.Item($rowIdx, 2) = $row.NbLines; $ws1.Cells.Item($rowIdx, 2).NumberFormatLocal = $formatNombre
        $ws1.Cells.Item($rowIdx, 3) = $row.Total; $ws1.Cells.Item($rowIdx, 3).NumberFormatLocal = $formatMontant
        $rowIdx++
    }
    $headersEdf = @("Date Prise Chg EDF", "Nb Prél. Pris en Chg", "Montant Pris en Chg (€)")
    for ($i = 0; $i -lt $headersEdf.Count; $i++) {
        $cell = $ws1.Cells.Item(4, $i + 5); $cell.Value = $headersEdf[$i]; $cell.Interior.Color = 0x7D491F; $cell.Font.Color = 0xFFFFFF; $cell.Font.Bold = $true; $cell.HorizontalAlignment = -4108
    }
    $rowIdx = 5
    foreach ($row in $edfSummary) {
        $ws1.Cells.Item($rowIdx, 5).NumberFormatLocal = $formatDate; $ws1.Cells.Item($rowIdx, 5) = [datetime]::ParseExact($row.DateEdf, "yyyyMMdd", $null).ToString("dd/MM/yyyy"); $ws1.Cells.Item($rowIdx, 5).HorizontalAlignment = -4108
        $ws1.Cells.Item($rowIdx, 6) = $row.NbEdf; $ws1.Cells.Item($rowIdx, 6).NumberFormatLocal = $formatNombre
        $ws1.Cells.Item($rowIdx, 7) = $row.TotalEdf; $ws1.Cells.Item($rowIdx, 7).NumberFormatLocal = $formatMontant
        $rowIdx++
    }
    $ws1.UsedRange.Columns.AutoFit() | Out-Null; $ws1.Columns.Item(1).ColumnWidth = 26

    # --- ONGLET 2 : État Comparatif & Écarts ---
    $ws2 = $workbook.Sheets.Add([System.Reflection.Missing]::Value, $ws1); $ws2.Name = "État Comparatif & Écarts"
    $ws2.Cells.Item(1, 1) = "ÉTAPE 2 : ÉTAT COMPARATIF ET RAPPROCHEMENT DES ÉCARTS"
    $ws2.Cells.Item(1, 1).Font.Bold = $true; $ws2.Cells.Item(1, 1).Font.Size = 14

    $headersComp = @("Date(s) Gén. Oracle", "Date Reç. EDF (Cible)", "Nb Attendu (Ora)", "Nb Reçu (EDF)", "Écart Nombre", "Total Attendu (Ora)", "Total Reçu (EDF)", "Écart Montant (€)", "Statut / Délai")
    for ($i = 0; $i -lt $headersComp.Count; $i++) {
        $cell = $ws2.Cells.Item(3, $i + 1); $cell.Value = $headersComp[$i]; $cell.Interior.Color = 0x7D491F; $cell.Font.Color = 0xFFFFFF; $cell.Font.Bold = $true; $cell.HorizontalAlignment = -4108
    }
    $rowIdx = 4
    foreach ($row in $tableauRapprochement) {
        $ws2.Cells.Item($rowIdx, 1).NumberFormatLocal = $formatDate; $ws2.Cells.Item($rowIdx, 1) = $row.Date_Oracle; $ws2.Cells.Item($rowIdx, 1).HorizontalAlignment = -4108
        $ws2.Cells.Item($rowIdx, 2).NumberFormatLocal = $formatDate; $ws2.Cells.Item($rowIdx, 2) = $row.Date_EDF; $ws2.Cells.Item($rowIdx, 2).HorizontalAlignment = -4108
        $ws2.Cells.Item($rowIdx, 3) = $row.Nb_Oracle; $ws2.Cells.Item($rowIdx, 3).NumberFormatLocal = $formatNombre
        $ws2.Cells.Item($rowIdx, 4) = $row.Nb_EDF; $ws2.Cells.Item($rowIdx, 4).NumberFormatLocal = $formatNombre
        $ws2.Cells.Item($rowIdx, 5) = $row.Ecart_Nb; $ws2.Cells.Item($rowIdx, 5).NumberFormatLocal = $formatNombre
        $ws2.Cells.Item($rowIdx, 6) = $row.Total_Oracle; $ws2.Cells.Item($rowIdx, 6).NumberFormatLocal = $formatMontant
        $ws2.Cells.Item($rowIdx, 7) = $row.Total_EDF; $ws2.Cells.Item($rowIdx, 7).NumberFormatLocal = $formatMontant
        $ws2.Cells.Item($rowIdx, 8) = $row.Ecart_Montant; $ws2.Cells.Item($rowIdx, 8).NumberFormatLocal = $formatMontant
        $ws2.Cells.Item($rowIdx, 9) = $row.Statut

        if ($row.Ecart_Nb -ne 0) {
            $ws2.Cells.Item($rowIdx, 5).Interior.Color = 0xD6E4FC
            $ws2.Cells.Item($rowIdx, 8).Interior.Color = 0xD6E4FC
            $ws2.Cells.Item($rowIdx, 9).Interior.Color = 0xD6E4FC
            $ws2.Cells.Item($rowIdx, 9).Font.Bold = $true
        } else {
            $ws2.Cells.Item($rowIdx, 9).Interior.Color = 0xDAEFED
        }
        $rowIdx++
    }
    $ws2.UsedRange.Columns.AutoFit() | Out-Null; $ws2.Columns.Item(1).ColumnWidth = 22

    # --- ONGLET 3 : Fichiers de Rejets Bruts (SÉCURISÉ) ---
    $ws3 = $workbook.Sheets.Add([System.Reflection.Missing]::Value, $ws2)
    $ws3.Name = "Fichiers de Rejets Bruts"
    $ws3.Cells.Item(1, 1) = "DONNÉES BRUTES EXTRAITES DES FICHIERS DE REJETS"
    $ws3.Cells.Item(1, 1).Font.Bold = $true; $ws3.Cells.Item(1, 1).Font.Size = 14

    $ws3.Cells.Item(3, 1) = "Nom du Fichier Source"
    $ws3.Cells.Item(3, 1).Interior.Color = 0x4F81BD; $ws3.Cells.Item(3, 1).Font.Color = 0xFFFFFF; $ws3.Cells.Item(3, 1).Font.Bold = $true
    $ws3.Cells.Item(3, 2) = "Ligne Brute (Contenu Intégral du Fichier CSV)"
    $ws3.Cells.Item(3, 2).Interior.Color = 0x4F81BD; $ws3.Cells.Item(3, 2).Font.Color = 0xFFFFFF; $ws3.Cells.Item(3, 2).Font.Bold = $true

    $rowIdx = 4
    foreach ($ligne in $listeLignesBrutesRejets) {
        $ws3.Cells.Item($rowIdx, 1) = $ligne.Fichier
        $ws3.Cells.Item($rowIdx, 2).NumberFormatLocal = "@" # Mode texte strict
        $ws3.Cells.Item($rowIdx, 2) = $ligne.TexteBrut
        $rowIdx++
    }
    
    $ws3.Columns.Item(1).ColumnWidth = 35
    $ws3.Columns.Item(2).ColumnWidth = 120

    # Sauvegarde finale
    if (Test-Path $outputPath) { Remove-Item $outputPath }
    $workbook.SaveAs($outputPath); $workbook.Close(); $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    
    Write-Host "`n=======================================================" -ForegroundColor Green
    Write-Host " Rapprochement complété avec succès !" -ForegroundColor Green
    Write-Host " Fichier généré avec l'onglet brut alimenté." -ForegroundColor Yellow
    Write-Host "=======================================================" -ForegroundColor Green
}
catch {
    Write-Host "Erreur critique : $($_.Exception.Message)" -ForegroundColor Red
    if ($excel) { $excel.Quit() }
}
Write-Host "`nAppuyez sur une touche pour fermer." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")