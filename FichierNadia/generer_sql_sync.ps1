# =====================================================================
# Synchronisation Factures via MCP SQLcl
# =====================================================================
# Ce script génère et affiche les commandes SQL à exécuter
# manuellement via SQL Developer ou via le MCP SQLcl
# =====================================================================

param(
    [Parameter(Mandatory=$false)]
    [int]$Annee = (Get-Date).Year,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("GENERATE", "COUNT", "SAMPLE")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [int]$Limit = 100
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Dossiers
$DossierSQL = Join-Path $ScriptDir "sql_sync"
$DossierBackup = Join-Path $ScriptDir "backup"

foreach ($dossier in @($DossierSQL, $DossierBackup)) {
    if (-not (Test-Path $dossier)) {
        New-Item -ItemType Directory -Path $dossier -Force | Out-Null
    }
}

Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  SYNCHRONISATION FACTURES - Generateur SQL" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "Annee   : $Annee"
Write-Host "Action  : $Action"
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""

# =====================================================================
# CHARGER LES FACTURES BO
# =====================================================================
$FichierBO = Join-Path $ScriptDir "factureImpayees\Factures impayees BO $Annee.csv"
if (-not (Test-Path $FichierBO)) {
    Write-Host "ERREUR: Fichier BO introuvable : $FichierBO" -ForegroundColor Red
    exit 1
}

# Détecter le délimiteur
$ContenuBrut = Get-Content $FichierBO -First 2 -Encoding UTF8
$Delimiteur = if ($ContenuBrut[0] -match ';') { ';' } else { ',' }

$FacturesBO = Import-Csv -Path $FichierBO -Delimiter $Delimiteur -Encoding UTF8 | 
    Where-Object { $_.ID_FACTURE -and $_.ID_FACTURE -match '^\d+$' }

$IDsFactures = $FacturesBO | ForEach-Object { $_.ID_FACTURE } | Sort-Object -Unique
$NbFactures = $IDsFactures.Count

Write-Host "Factures BO chargees : $NbFactures" -ForegroundColor Green
Write-Host ""

# =====================================================================
# ACTION: COUNT - Juste compter
# =====================================================================
if ($Action -eq "COUNT") {
    Write-Host "Total factures impayees BO pour $Annee : $NbFactures" -ForegroundColor Yellow
    exit 0
}

# =====================================================================
# ACTION: SAMPLE - Extraire un échantillon d'IDs
# =====================================================================
if ($Action -eq "SAMPLE") {
    Write-Host "Echantillon de $Limit IDs :" -ForegroundColor Yellow
    $Sample = $IDsFactures | Select-Object -First $Limit
    Write-Host ($Sample -join ", ")
    Write-Host ""
    Write-Host "Requete pour tester dans SQL Developer :" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "SELECT invoice_id, invoice_num, payment_status_flag, last_update_date"
    Write-Host "FROM ap_invoices_all"
    Write-Host "WHERE invoice_id IN ($($Sample -join ', '))"
    Write-Host "ORDER BY last_update_date DESC;"
    exit 0
}

# =====================================================================
# ACTION: GENERATE - Générer tous les scripts
# =====================================================================
if ($Action -eq "GENERATE") {
    
    # Diviser en lots de 1000 (limite Oracle IN)
    $Lots = @()
    for ($i = 0; $i -lt $NbFactures; $i += 1000) {
        $Fin = [Math]::Min($i + 999, $NbFactures - 1)
        $Lots += ,@($IDsFactures[$i..$Fin])
    }
    $NbLots = $Lots.Count
    
    Write-Host "Generation des scripts pour $NbFactures factures en $NbLots lots..." -ForegroundColor Yellow
    Write-Host ""
    
    # =========================================================
    # SCRIPT 1 : SAUVEGARDE
    # =========================================================
    $FichierSauvegarde = Join-Path $DossierSQL "01_sauvegarde_${Annee}.sql"
    
    $ScriptSauv = @"
-- =====================================================================
-- SAUVEGARDE DES DONNEES AVANT MODIFICATION
-- =====================================================================
-- Genere le : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
-- Annee : $Annee
-- Factures : $NbFactures
-- =====================================================================
-- INSTRUCTIONS :
-- 1. Executer ce script dans SQL Developer
-- 2. Exporter le resultat en CSV (clic droit > Export)
-- 3. Sauvegarder dans : backup/sauvegarde_factures_${Annee}_${Timestamp}.csv
-- =====================================================================

"@

    foreach ($lotIndex in 0..($NbLots-1)) {
        $IdsLot = $Lots[$lotIndex] -join ", "
        $ScriptSauv += @"

-- LOT $($lotIndex + 1) / $NbLots
SELECT 
    invoice_id,
    invoice_num,
    TO_CHAR(last_update_date, 'YYYY-MM-DD HH24:MI:SS') AS last_update_date_original,
    last_updated_by AS last_updated_by_original,
    payment_status_flag,
    invoice_amount,
    NVL(amount_paid, 0) AS amount_paid,
    NVL(TO_CHAR(cancelled_date, 'YYYY-MM-DD'), 'N/A') AS cancelled_date
FROM ap_invoices_all
WHERE invoice_id IN ($IdsLot)
$(if ($lotIndex -lt $NbLots - 1) { "UNION ALL" } else { "ORDER BY 1;" })

"@
    }
    
    $ScriptSauv | Out-File -FilePath $FichierSauvegarde -Encoding UTF8
    Write-Host "  [OK] $FichierSauvegarde" -ForegroundColor Green
    
    # =========================================================
    # SCRIPT 2 : UPDATE
    # =========================================================
    $FichierUpdate = Join-Path $DossierSQL "02_update_sync_${Annee}.sql"
    
    $ScriptUpd = @"
-- =====================================================================
-- MISE A JOUR last_update_date POUR FORCER SYNC BO
-- =====================================================================
-- Genere le : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
-- Annee : $Annee
-- Factures : $NbFactures
-- =====================================================================
-- ATTENTION : EXECUTER SEULEMENT APRES AVOIR SAUVEGARDE LES DONNEES !
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    v_total NUMBER := 0;
    v_lot NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== DEBUT MISE A JOUR SYNC BO ===');
    DBMS_OUTPUT.PUT_LINE('Date : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');

"@

    foreach ($lotIndex in 0..($NbLots-1)) {
        $IdsLot = $Lots[$lotIndex] -join ", "
        $ScriptUpd += @"

    -- LOT $($lotIndex + 1) / $NbLots
    UPDATE ap_invoices_all
    SET last_update_date = TRUNC(SYSDATE) - 1 + (12/24),
        last_updated_by = -1
    WHERE invoice_id IN ($IdsLot);
    
    v_lot := SQL%ROWCOUNT;
    v_total := v_total + v_lot;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Lot $($lotIndex + 1) : ' || v_lot || ' factures (Total: ' || v_total || ')');

"@
    }

    $ScriptUpd += @"

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== MISE A JOUR TERMINEE ===');
    DBMS_OUTPUT.PUT_LINE('Total factures mises a jour : ' || v_total);
END;
/

-- Verification
SELECT 
    'MODIFIE_HIER' AS STATUT,
    COUNT(*) AS NB_FACTURES
FROM ap_invoices_all
WHERE invoice_id IN ($(($IDsFactures | Select-Object -First 1000) -join ", "))
AND TRUNC(last_update_date) = TRUNC(SYSDATE) - 1;
"@

    $ScriptUpd | Out-File -FilePath $FichierUpdate -Encoding UTF8
    Write-Host "  [OK] $FichierUpdate" -ForegroundColor Green
    
    # =========================================================
    # SCRIPT 3 : TEMPLATE RESTORE
    # =========================================================
    $FichierRestore = Join-Path $DossierSQL "03_restore_template_${Annee}.sql"
    
    $ScriptRestore = @"
-- =====================================================================
-- TEMPLATE DE RESTAURATION
-- =====================================================================
-- Genere le : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
-- Annee : $Annee
-- =====================================================================
-- INSTRUCTIONS :
-- 1. Ouvrir le fichier CSV de sauvegarde dans Excel
-- 2. Utiliser ce template pour generer les UPDATE
-- 3. Remplacer les valeurs XXX par les valeurs du CSV
-- =====================================================================

-- Template pour chaque ligne du CSV :
/*
UPDATE ap_invoices_all
SET last_update_date = TO_DATE('YYYY-MM-DD HH24:MI:SS', 'YYYY-MM-DD HH24:MI:SS'),
    last_updated_by = XXX
WHERE invoice_id = XXX;
*/

-- OU utiliser le script PowerShell generer_restore.ps1 avec le fichier CSV

-- Exemple :
-- UPDATE ap_invoices_all SET last_update_date = TO_DATE('2025-11-15 14:30:22', 'YYYY-MM-DD HH24:MI:SS'), last_updated_by = 1234 WHERE invoice_id = 47135;

COMMIT;
"@

    $ScriptRestore | Out-File -FilePath $FichierRestore -Encoding UTF8
    Write-Host "  [OK] $FichierRestore" -ForegroundColor Green
    
    # =========================================================
    # RÉSUMÉ
    # =========================================================
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  SCRIPTS GENERES" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Dossier : $DossierSQL" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. 01_sauvegarde_${Annee}.sql"
    Write-Host "   -> Executer dans SQL Developer, exporter le resultat en CSV"
    Write-Host ""
    Write-Host "2. 02_update_sync_${Annee}.sql"
    Write-Host "   -> Executer APRES avoir sauvegarde"
    Write-Host "   -> Forcer la sync BO du soir"
    Write-Host ""
    Write-Host "3. 03_restore_template_${Annee}.sql"
    Write-Host "   -> Template pour regenerer les UPDATE de restauration"
    Write-Host ""
    Write-Host "Factures concernees : $NbFactures" -ForegroundColor Green
    Write-Host "Nombre de lots SQL  : $NbLots" -ForegroundColor Green
    Write-Host ""
}
