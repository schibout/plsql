# =====================================================================
# Rapport FIN-FINANCE — Analyse des chaînes Control-M + Oracle EBS
# =====================================================================
# Lit tous les CSV Report_ctm_*.csv, filtre Application = FIN-FINANCE,
# enrichit avec les données Oracle, et génère un classeur Excel local.
#
# Usage : .\report_finance.ps1
# Sortie : AnalyseTraitements\Rapport_FIN-FINANCE_<date>.xlsx
# =====================================================================

$ErrorActionPreference = 'Stop'

# --- Configuration ---
$csvFolder   = Join-Path $PSScriptRoot "Extraits"
$outputDir   = $PSScriptRoot
$today       = Get-Date -Format "yyyyMMdd"
$xlsxFile    = Join-Path $outputDir "Rapport_FIN-FINANCE_$today.xlsx"
$delimiter   = ';'
$appFilter   = 'FIN-FINANCE'

Write-Host "=== Rapport FIN-FINANCE ===" -ForegroundColor Cyan
Write-Host "Dossier CSV : $csvFolder"
Write-Host ""

# =====================================================================
# ÉTAPE 1 : Charger tous les CSV
# =====================================================================
Write-Host "[1/4] Chargement des fichiers CSV..." -ForegroundColor Yellow

$csvFiles = Get-ChildItem -Path $csvFolder -Filter "*.csv" | Sort-Object Name
Write-Host "  Fichiers trouvés : $($csvFiles.Count)"

$allRows = [System.Collections.ArrayList]::new()

foreach ($file in $csvFiles) {
    $data = Import-Csv -Path $file.FullName -Delimiter $delimiter -Encoding UTF8
    $finRows = $data | Where-Object { $_.Application -eq $appFilter }
    foreach ($r in $finRows) {
        [void]$allRows.Add($r)
    }
}

Write-Host "  Lignes FIN-FINANCE : $($allRows.Count)"

# =====================================================================
# ÉTAPE 2 : Agrégation — Synthèse par chaîne
# =====================================================================
Write-Host "[2/4] Calcul des statistiques par chaîne..." -ForegroundColor Yellow

$chainStats = @{}

foreach ($row in $allRows) {
    $key = $row.'Group Name'
    if (-not $chainStats.ContainsKey($key)) {
        $chainStats[$key] = [PSCustomObject]@{
            Chaine          = $key
            Description     = ''
            NbJobsTotal     = 0
            EndedOK         = 0
            EndedNotOK      = 0
            Executing       = 0
            WaitEvent       = 0
            AutreStatut     = 0
            TotalRunTime    = 0
            RunTimeCount    = 0
            DatesDistinctes = @{}
        }
    }
    $c = $chainStats[$key]
    $c.NbJobsTotal++

    switch ($row.Status) {
        'Ended OK'       { $c.EndedOK++ }
        'Ended Not OK'   { $c.EndedNotOK++ }
        'Executing'      { $c.Executing++ }
        'Wait for Event' { $c.WaitEvent++ }
        default          { $c.AutreStatut++ }
    }

    if ($row.'Run Time' -and $row.'Run Time' -match '^\d+') {
        $c.TotalRunTime += [double]$row.'Run Time'
        $c.RunTimeCount++
    }

    $odate = $row.Odate -replace '"', ''
    if ($odate) { $c.DatesDistinctes[$odate] = $true }

    if (-not $c.Description -and $row.Description) {
        $c.Description = $row.Description
    }
}

$syntheseData = $chainStats.Values | Sort-Object Chaine | ForEach-Object {
    $tauxSucces = if ($_.NbJobsTotal -gt 0) { [math]::Round(($_.EndedOK / $_.NbJobsTotal) * 100, 1) } else { 0 }
    $dureeMoy   = if ($_.RunTimeCount -gt 0) { [math]::Round($_.TotalRunTime / $_.RunTimeCount, 0) } else { '' }

    [PSCustomObject]@{
        'Chaîne (Group Name)' = $_.Chaine
        'Description'         = $_.Description
        'Nb Jobs Total'       = $_.NbJobsTotal
        'Ended OK'            = $_.EndedOK
        'Erreurs'             = $_.EndedNotOK
        'En cours'            = $_.Executing
        'Wait Event'          = $_.WaitEvent
        'Autre'               = $_.AutreStatut
        'Taux Succès (%)'     = $tauxSucces
        'Durée Moy (sec)'     = $dureeMoy
        'Nb Jours Exécutés'   = $_.DatesDistinctes.Count
    }
}

Write-Host "  Chaînes distinctes : $($syntheseData.Count)"

# =====================================================================
# ÉTAPE 3 : Détails et erreurs
# =====================================================================
Write-Host "[3/4] Préparation du détail et des erreurs..." -ForegroundColor Yellow

$detailData = $allRows | Sort-Object { ($_.Odate -replace '"','') }, 'Group Name', 'Job Name' | ForEach-Object {
    [PSCustomObject]@{
        'Date (Odate)'  = $_.Odate -replace '"', ''
        'Chaîne'        = $_.'Group Name'
        'Job Name'      = $_.'Job Name'
        'Description'   = $_.Description
        'Heure Début'   = $_.'Start Time' -replace '"', ''
        'Heure Fin'     = $_.'End Time' -replace '"', ''
        'Durée (sec)'   = $_.'Run Time'
        'Statut'        = $_.Status
        'Member Name'   = $_.'Member Name'
        'Hostname'      = $_.Hostname
        'Run As User'   = $_.'Run as User'
        'Cyclic'        = $_.Cyclic
        'Rerun'         = $_.'Rerun Counter'
    }
}

$errorData = $allRows | Where-Object { $_.Status -eq 'Ended Not OK' } | Sort-Object { ($_.Odate -replace '"','') } | ForEach-Object {
    [PSCustomObject]@{
        'Date (Odate)'  = $_.Odate -replace '"', ''
        'Chaîne'        = $_.'Group Name'
        'Job Name'      = $_.'Job Name'
        'Description'   = $_.Description
        'Heure Début'   = $_.'Start Time' -replace '"', ''
        'Heure Fin'     = $_.'End Time' -replace '"', ''
        'Statut'        = $_.Status
        'Hostname'      = $_.Hostname
        'Rerun'         = $_.'Rerun Counter'
    }
}

Write-Host "  Lignes détail : $($detailData.Count)"
Write-Host "  Lignes erreurs : $($errorData.Count)"

# =====================================================================
# ÉTAPE 4 : Génération Excel via COM
# =====================================================================
Write-Host "[4/4] Génération du fichier Excel..." -ForegroundColor Yellow

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

try {
    $workbook = $excel.Workbooks.Add()

    # --- Helper : écrire des données dans une feuille ---
    # Convertir couleur HTML en OLE (RGB inversé pour Excel COM)
    function ConvertTo-OleColor([string]$hex) {
        $hex = $hex.TrimStart('#')
        $r = [Convert]::ToInt32($hex.Substring(0, 2), 16)
        $g = [Convert]::ToInt32($hex.Substring(2, 2), 16)
        $b = [Convert]::ToInt32($hex.Substring(4, 2), 16)
        return $r + ($g * 256) + ($b * 65536)
    }

    function Write-SheetData {
        param(
            [object]$Sheet,
            [string]$Name,
            [array]$Data,
            [string]$HeaderColor = '#4472C4'
        )

        $Sheet.Name = $Name

        if ($Data.Count -eq 0) {
            $Sheet.Cells.Item(1, 1) = "Aucune donnée"
            return
        }

        # En-têtes
        $props = $Data[0].PSObject.Properties.Name
        $nbCols = $props.Count
        $oleColor = ConvertTo-OleColor $HeaderColor

        # Construire un tableau 2D pour écriture en bloc (BEAUCOUP plus rapide)
        $nbRows = $Data.Count + 1  # +1 pour l'en-tête
        $array = [System.Array]::CreateInstance([object], $nbRows, $nbCols)

        # Remplir l'en-tête
        for ($col = 0; $col -lt $nbCols; $col++) {
            $array.SetValue($props[$col], 0, $col)
        }

        # Remplir les données
        for ($row = 0; $row -lt $Data.Count; $row++) {
            $item = $Data[$row]
            $r = $row + 1
            for ($col = 0; $col -lt $nbCols; $col++) {
                $val = $item.($props[$col])
                if ($null -eq $val) { $val = '' }
                $array.SetValue([string]$val, $r, $col)
            }
            if ($row % 5000 -eq 0 -and $row -gt 0) {
                Write-Host "    ... $row / $($Data.Count) lignes préparées" -ForegroundColor DarkGray
            }
        }

        # Écriture en bloc dans Excel (une seule opération)
        Write-Host "    Écriture $($Data.Count) lignes dans '$Name'..." -ForegroundColor DarkGray
        $range = $Sheet.Range($Sheet.Cells.Item(1, 1), $Sheet.Cells.Item($nbRows, $nbCols))
        $range.Value2 = $array

        # Mise en forme de l'en-tête
        $headerRange = $Sheet.Range($Sheet.Cells.Item(1, 1), $Sheet.Cells.Item(1, $nbCols))
        $headerRange.Font.Bold = $true
        $headerRange.Font.Color = 16777215  # blanc
        $headerRange.Interior.Color = $oleColor

        # Auto-ajuster colonnes
        $Sheet.UsedRange.EntireColumn.AutoFit() | Out-Null

        # Figer la première ligne
        $Sheet.Rows.Item(2).Select() | Out-Null
        $excel.ActiveWindow.FreezePanes = $true
    }

    # Feuille 1 : Synthèse
    $sheet1 = $workbook.Worksheets.Item(1)
    Write-SheetData -Sheet $sheet1 -Name "Synthèse par chaîne" -Data $syntheseData

    # Feuille 2 : Détail quotidien
    $sheet2 = $workbook.Worksheets.Add([System.Reflection.Missing]::Value, $workbook.Worksheets.Item($workbook.Worksheets.Count))
    Write-SheetData -Sheet $sheet2 -Name "Détail quotidien" -Data $detailData

    # Feuille 3 : Erreurs
    $sheet3 = $workbook.Worksheets.Add([System.Reflection.Missing]::Value, $workbook.Worksheets.Item($workbook.Worksheets.Count))
    Write-SheetData -Sheet $sheet3 -Name "Erreurs" -Data $errorData -HeaderColor '#C00000'

    # Feuille 4 : Programmes Oracle (top 150)
    $oracleData = @(
        [PSCustomObject]@{ 'Programme Oracle' = 'DKA_RAPVIR_PDF'; 'Nom complet' = 'DKA : Création du fichier avis de virement'; 'Module' = 'DKA'; 'Exécutions 7j' = 28256; 'Durée moy (min)' = 0.28; 'Durée max (min)' = 11.0 }
        [PSCustomObject]@{ 'Programme Oracle' = 'FAACCPB'; 'Nom complet' = 'Créer une comptabilisation - Immobilisations'; 'Module' = 'OFA'; 'Exécutions 7j' = 26320; 'Durée moy (min)' = 0.1; 'Durée max (min)' = 0.65 }
        [PSCustomObject]@{ 'Programme Oracle' = 'XLAACCPB'; 'Nom complet' = 'Créer une comptabilisation'; 'Module' = 'XLA'; 'Exécutions 7j' = 24944; 'Durée moy (min)' = 0.8; 'Durée max (min)' = 34.57 }
        [PSCustomObject]@{ 'Programme Oracle' = 'DKA_SAPCREATE_BLOCAGES'; 'Nom complet' = 'DKA : Création blocages comptabilisation factures AP'; 'Module' = 'DKA'; 'Exécutions 7j' = 20776; 'Durée moy (min)' = 0.02; 'Durée max (min)' = 0.37 }
        [PSCustomObject]@{ 'Programme Oracle' = 'GLLEZL'; 'Nom complet' = 'EasyLink'; 'Module' = 'SQLGL'; 'Exécutions 7j' = 17160; 'Durée moy (min)' = 0.03; 'Durée max (min)' = 0.4 }
        [PSCustomObject]@{ 'Programme Oracle' = 'APXPBASL'; 'Nom complet' = 'Programme de demande de traitement des règlements'; 'Module' = 'SQLAP'; 'Exécutions 7j' = 16640; 'Durée moy (min)' = 0.02; 'Durée max (min)' = 0.12 }
        [PSCustomObject]@{ 'Programme Oracle' = 'APXIIMPT'; 'Nom complet' = "Programme d'importation de l'interface coopérative d'Oracle Payables"; 'Module' = 'SQLAP'; 'Exécutions 7j' = 15472; 'Durée moy (min)' = 0.1; 'Durée max (min)' = 3.8 }
        [PSCustomObject]@{ 'Programme Oracle' = 'WORKERAPPRVL'; 'Nom complet' = 'Traitement du processeur enfant de validation de factures'; 'Module' = 'SQLAP'; 'Exécutions 7j' = 14304; 'Durée moy (min)' = 3.54; 'Durée max (min)' = 27.25 }
        [PSCustomObject]@{ 'Programme Oracle' = 'FARET'; 'Nom complet' = 'Calculer les plus- et moins-values'; 'Module' = 'OFA'; 'Exécutions 7j' = 13280; 'Durée moy (min)' = 0.01; 'Durée max (min)' = 0.08 }
        [PSCustomObject]@{ 'Programme Oracle' = 'FAGDA'; 'Nom complet' = 'Générer des comptes'; 'Module' = 'OFA'; 'Exécutions 7j' = 13280; 'Durée moy (min)' = 0.02; 'Durée max (min)' = 0.18 }
        [PSCustomObject]@{ 'Programme Oracle' = 'DKA_SFAACCPB'; 'Nom complet' = 'DKA : Créer une comptabilisation - Immobilisations'; 'Module' = 'DKA'; 'Exécutions 7j' = 13200; 'Durée moy (min)' = 0.51; 'Durée max (min)' = 1.52 }
        [PSCustomObject]@{ 'Programme Oracle' = 'FAMCP'; 'Nom complet' = 'Copie en haut volume périodique'; 'Module' = 'OFA'; 'Exécutions 7j' = 12328; 'Durée moy (min)' = 0.05; 'Durée max (min)' = 0.12 }
        [PSCustomObject]@{ 'Programme Oracle' = 'XLAACCUP'; 'Nom complet' = 'Programme de comptabilisation'; 'Module' = 'XLA'; 'Exécutions 7j' = 12144; 'Durée moy (min)' = 0.98; 'Durée max (min)' = 34.37 }
        [PSCustomObject]@{ 'Programme Oracle' = 'XLABAPUB'; 'Nom complet' = 'Mettre à jour les soldes de comptabilité auxiliaire'; 'Module' = 'XLA'; 'Exécutions 7j' = 11600; 'Durée moy (min)' = 0.01; 'Durée max (min)' = 0.15 }
        [PSCustomObject]@{ 'Programme Oracle' = 'APPRVL'; 'Nom complet' = 'Validation de factures'; 'Module' = 'SQLAP'; 'Exécutions 7j' = 10920; 'Durée moy (min)' = 3.74; 'Durée max (min)' = 29.83 }
        [PSCustomObject]@{ 'Programme Oracle' = 'DKA_SLAUNCHER'; 'Nom complet' = 'DKA : Lanceur (SHELL)'; 'Module' = 'DKA'; 'Exécutions 7j' = 7976; 'Durée moy (min)' = 11.44; 'Durée max (min)' = 1773.13 }
        [PSCustomObject]@{ 'Programme Oracle' = 'FNDRSSTG'; 'Nom complet' = 'Phase du jeu de traitements'; 'Module' = 'FND'; 'Exécutions 7j' = 7832; 'Durée moy (min)' = 2.28; 'Durée max (min)' = 269.58 }
        [PSCustomObject]@{ 'Programme Oracle' = 'FNDOAMCOL'; 'Nom complet' = 'Collection de tableaux de bord pour les applications OAM'; 'Module' = 'FND'; 'Exécutions 7j' = 7816; 'Durée moy (min)' = 0.27; 'Durée max (min)' = 2.07 }
        [PSCustomObject]@{ 'Programme Oracle' = 'PAAPIMPR'; 'Nom complet' = 'AUD : Audit de transfert des coûts fournisseur'; 'Module' = 'PA'; 'Exécutions 7j' = 7496; 'Durée moy (min)' = 0.28; 'Durée max (min)' = 0.55 }
        [PSCustomObject]@{ 'Programme Oracle' = 'DKA_APXCRRCR'; 'Nom complet' = 'DKA : Echeancier Fournisseur Provisoire'; 'Module' = 'DKA'; 'Exécutions 7j' = 5792; 'Durée moy (min)' = 2.18; 'Durée max (min)' = 3.93 }
        [PSCustomObject]@{ 'Programme Oracle' = 'IBYBUILD'; 'Nom complet' = 'Créer des règlements'; 'Module' = 'IBY'; 'Exécutions 7j' = 5096; 'Durée moy (min)' = 0.08; 'Durée max (min)' = 0.3 }
        [PSCustomObject]@{ 'Programme Oracle' = 'APINVSEL'; 'Nom complet' = "Etat relatif à la sélection de l'échéancier de paiement"; 'Module' = 'SQLAP'; 'Exécutions 7j' = 5096; 'Durée moy (min)' = 0.06; 'Durée max (min)' = 0.28 }
        [PSCustomObject]@{ 'Programme Oracle' = 'POXPOPDOI'; 'Nom complet' = 'Importer des commandes standard'; 'Module' = 'PO'; 'Exécutions 7j' = 3688; 'Durée moy (min)' = 0.31; 'Durée max (min)' = 2.73 }
        [PSCustomObject]@{ 'Programme Oracle' = 'DKA_OPEN_INTERFACE_AP_EAI'; 'Nom complet' = "DKA : Import des données depuis l'open Interface AP"; 'Module' = 'DKA'; 'Exécutions 7j' = 3352; 'Durée moy (min)' = 10.85; 'Durée max (min)' = 33.9 }
        [PSCustomObject]@{ 'Programme Oracle' = 'GLPARV'; 'Nom complet' = 'Programme - Contrepassation automatique'; 'Module' = 'SQLGL'; 'Exécutions 7j' = 2640; 'Durée moy (min)' = 4.8; 'Durée max (min)' = 703.33 }
        [PSCustomObject]@{ 'Programme Oracle' = 'GLXRCAUT'; 'Nom complet' = 'Rapprochement - Rapprochement automatique'; 'Module' = 'SQLGL'; 'Exécutions 7j' = 2640; 'Durée moy (min)' = 0.12; 'Durée max (min)' = 12.07 }
        [PSCustomObject]@{ 'Programme Oracle' = 'DKA_IPOFRS_IVALUA'; 'Nom complet' = "DKA : Import des données Fournisseurs depuis iValua"; 'Module' = 'DKA'; 'Exécutions 7j' = 120; 'Durée moy (min)' = 4.98; 'Durée max (min)' = 10.17 }
        [PSCustomObject]@{ 'Programme Oracle' = 'DKA_IPOCDE_IVALUA'; 'Nom complet' = "DKA : Import des commandes depuis iValua"; 'Module' = 'DKA'; 'Exécutions 7j' = 128; 'Durée moy (min)' = 6.45; 'Durée max (min)' = 20.95 }
        [PSCustomObject]@{ 'Programme Oracle' = 'DKA_SAPFRSDUPLI_MAJ'; 'Nom complet' = 'DKA : Mise à jour quotidienne des sites fournisseurs dupliqués'; 'Module' = 'DKA'; 'Exécutions 7j' = 1544; 'Durée moy (min)' = 0.45; 'Durée max (min)' = 28.32 }
        [PSCustomObject]@{ 'Programme Oracle' = 'DKA_SAPAUTORGT'; 'Nom complet' = 'DKA : Règlements automatiques toutes sociétés'; 'Module' = 'DKA'; 'Exécutions 7j' = 96; 'Durée moy (min)' = 66.55; 'Durée max (min)' = 91.93 }
        [PSCustomObject]@{ 'Programme Oracle' = 'DKA_SCTRLMOD_MOA_EDT'; 'Nom complet' = 'DKA : Situation Oracle du matin'; 'Module' = 'DKA'; 'Exécutions 7j' = 280; 'Durée moy (min)' = 32.1; 'Durée max (min)' = 155.33 }
        [PSCustomObject]@{ 'Programme Oracle' = 'DKA_SAPWFCSP'; 'Nom complet' = 'DKA : Traitement de validation des factures CSP'; 'Module' = 'DKA'; 'Exécutions 7j' = 280; 'Durée moy (min)' = 7.72; 'Durée max (min)' = 23.62 }
        [PSCustomObject]@{ 'Programme Oracle' = 'DKA_SRBRELBANC_CSP'; 'Nom complet' = "DKA : Edition des relevés bancaires pour les CSP"; 'Module' = 'DKA'; 'Exécutions 7j' = 472; 'Durée moy (min)' = 0.57; 'Durée max (min)' = 0.95 }
        [PSCustomObject]@{ 'Programme Oracle' = 'DKA_SRBRAPAUTO'; 'Nom complet' = 'DKA : Rapprochement automatique RB sur toutes sociétés'; 'Module' = 'DKA'; 'Exécutions 7j' = 120; 'Durée moy (min)' = 2.74; 'Durée max (min)' = 3.02 }
    )

    $sheet4 = $workbook.Worksheets.Add([System.Reflection.Missing]::Value, $workbook.Worksheets.Item($workbook.Worksheets.Count))
    Write-SheetData -Sheet $sheet4 -Name "Programmes Oracle (7j)" -Data $oracleData -HeaderColor '#2E75B6'

    # Activer la première feuille
    $workbook.Worksheets.Item(1).Activate()

    # Sauvegarder
    if (Test-Path $xlsxFile) { Remove-Item $xlsxFile -Force }
    $workbook.SaveAs($xlsxFile, 51)  # 51 = xlOpenXMLWorkbook (.xlsx)
    Write-Host ""
    Write-Host "Fichier généré : $xlsxFile" -ForegroundColor Green
}
finally {
    $workbook.Close($false)
    $excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
    [GC]::Collect()
}

Write-Host ""
Write-Host "=== Rapport terminé ===" -ForegroundColor Cyan
Write-Host "  - Synthèse par chaîne : $($syntheseData.Count) chaînes"
Write-Host "  - Détail quotidien    : $($detailData.Count) lignes"
Write-Host "  - Erreurs             : $($errorData.Count) lignes"
Write-Host "  - Programmes Oracle   : $($oracleData.Count) programmes"
