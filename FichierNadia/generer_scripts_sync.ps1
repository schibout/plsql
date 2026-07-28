# =====================================================================
# Génération des scripts SQL de synchronisation
# =====================================================================
# Ce script génère les ordres SQL pour :
#   1. Sauvegarder les last_update_date actuelles
#   2. Mettre à jour last_update_date pour forcer sync BO
#   3. Restaurer les valeurs originales
# =====================================================================

param(
    [Parameter(Mandatory=$false)]
    [int]$Annee = (Get-Date).Year,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("PREPARE", "GENERATE_ONLY")]
    [string]$Action = "PREPARE"
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Créer les dossiers nécessaires
$DossierSQL = Join-Path $ScriptDir "sql_sync"
$DossierBackup = Join-Path $ScriptDir "backup"
$DossierLogs = Join-Path $ScriptDir "logs"

foreach ($dossier in @($DossierSQL, $DossierBackup, $DossierLogs)) {
    if (-not (Test-Path $dossier)) {
        New-Item -ItemType Directory -Path $dossier -Force | Out-Null
    }
}

Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  GENERATION SCRIPTS SQL - Synchronisation Factures BO" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "Annee cible  : $Annee"
Write-Host "Timestamp    : $Timestamp"
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""

# =====================================================================
# 1. CHARGER LES FACTURES IMPAYÉES BO
# =====================================================================
Write-Host "[1/4] Chargement des factures impayees BO..." -ForegroundColor Yellow

$FichierBO = Join-Path $ScriptDir "factureImpayees\Factures impayees BO $Annee.csv"
if (-not (Test-Path $FichierBO)) {
    Write-Host "ERREUR: Fichier BO introuvable : $FichierBO" -ForegroundColor Red
    exit 1
}

# Charger le CSV (détecter le délimiteur)
$ContenuBrut = Get-Content $FichierBO -First 2 -Encoding UTF8
$Delimiteur = if ($ContenuBrut[0] -match ';') { ';' } else { ',' }

$FacturesBO = Import-Csv -Path $FichierBO -Delimiter $Delimiteur -Encoding UTF8 | 
    Where-Object { $_.ID_FACTURE -and $_.ID_FACTURE -match '^\d+$' }

$IDsFactures = $FacturesBO | ForEach-Object { $_.ID_FACTURE } | Sort-Object -Unique
$NbFactures = $IDsFactures.Count

Write-Host "   Factures chargees : $NbFactures" -ForegroundColor Green
Write-Host ""

if ($NbFactures -eq 0) {
    Write-Host "ERREUR: Aucune facture valide trouvee dans le fichier BO" -ForegroundColor Red
    exit 1
}

# =====================================================================
# 2. GÉNÉRER SCRIPT DE SAUVEGARDE
# =====================================================================
Write-Host "[2/4] Generation du script de sauvegarde..." -ForegroundColor Yellow

$FichierSauvegarde = Join-Path $DossierSQL "01_sauvegarde_$Annee.sql"
$FichierSauvegardePath = $FichierSauvegarde.Replace('\', '/')
$FichierBackupCSV = Join-Path $DossierBackup "sauvegarde_factures_${Annee}_${Timestamp}.csv"
$FichierBackupCSVPath = $FichierBackupCSV.Replace('\', '/')

# Créer la liste des IDs par lots de 1000 (limite Oracle IN clause)
$Lots = @()
for ($i = 0; $i -lt $NbFactures; $i += 1000) {
    $Fin = [Math]::Min($i + 999, $NbFactures - 1)
    $Lots += ($IDsFactures[$i..$Fin] -join ", ")
}

$ClauseIN = if ($Lots.Count -eq 1) {
    "invoice_id IN ($($Lots[0]))"
} else {
    $Clauses = $Lots | ForEach-Object { "invoice_id IN ($_)" }
    "(" + ($Clauses -join " OR ") + ")"
}

$ScriptSauvegarde = @"
-- =====================================================================
-- SCRIPT DE SAUVEGARDE - Factures $Annee
-- =====================================================================
-- Genere le : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
-- Nombre de factures : $NbFactures
-- IMPORTANT : Conserver ce fichier pour la restauration !
-- =====================================================================

SET PAGESIZE 0
SET LINESIZE 32767
SET TRIMSPOOL ON
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING ON
SET COLSEP ';'

ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

SPOOL $FichierBackupCSVPath

SELECT 
    'INVOICE_ID;INVOICE_NUM;LAST_UPDATE_DATE_ORIGINAL;LAST_UPDATED_BY_ORIGINAL;PAYMENT_STATUS_FLAG' AS HEADER
FROM DUAL
UNION ALL
SELECT 
    invoice_id || ';' ||
    invoice_num || ';' ||
    TO_CHAR(last_update_date, 'YYYY-MM-DD HH24:MI:SS') || ';' ||
    last_updated_by || ';' ||
    payment_status_flag
FROM ap_invoices_all
WHERE $ClauseIN
ORDER BY 1;

SPOOL OFF

SELECT 'Sauvegarde terminee : ' || COUNT(*) || ' factures' AS RESULTAT
FROM ap_invoices_all
WHERE $ClauseIN;

EXIT;
"@

$ScriptSauvegarde | Out-File -FilePath $FichierSauvegarde -Encoding UTF8
Write-Host "   Script genere : $FichierSauvegarde" -ForegroundColor Green
Write-Host ""

# =====================================================================
# 3. GÉNÉRER SCRIPT DE MISE À JOUR
# =====================================================================
Write-Host "[3/4] Generation du script de mise a jour..." -ForegroundColor Yellow

$FichierUpdate = Join-Path $DossierSQL "02_update_sync_$Annee.sql"

$ScriptUpdate = @"
-- =====================================================================
-- SCRIPT DE MISE A JOUR - Forcer synchronisation BO
-- =====================================================================
-- Genere le : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
-- Nombre de factures : $NbFactures
-- Action : Met a jour last_update_date = SYSDATE-1 pour forcer le dump BO
-- =====================================================================
-- ATTENTION : Executer UNIQUEMENT apres la sauvegarde !
-- =====================================================================

SET SERVEROUTPUT ON
SET FEEDBACK ON

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

DECLARE
    v_count NUMBER := 0;
    v_batch_size CONSTANT NUMBER := 500;
    v_total NUMBER := 0;
    
    -- Curseur des factures a mettre a jour
    CURSOR c_factures IS
        SELECT invoice_id
        FROM ap_invoices_all
        WHERE $ClauseIN;
        
    TYPE t_invoice_ids IS TABLE OF ap_invoices_all.invoice_id%TYPE;
    l_invoice_ids t_invoice_ids;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== DEBUT MISE A JOUR SYNCHRONISATION BO ===');
    DBMS_OUTPUT.PUT_LINE('Date execution : ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');
    
    OPEN c_factures;
    LOOP
        FETCH c_factures BULK COLLECT INTO l_invoice_ids LIMIT v_batch_size;
        EXIT WHEN l_invoice_ids.COUNT = 0;
        
        FORALL i IN 1..l_invoice_ids.COUNT
            UPDATE ap_invoices_all
            SET last_update_date = TRUNC(SYSDATE) - 1 + (12/24),  -- Hier a midi
                last_updated_by = -1,  -- System
                request_id = NULL
            WHERE invoice_id = l_invoice_ids(i);
        
        v_total := v_total + l_invoice_ids.COUNT;
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Lot traite : ' || l_invoice_ids.COUNT || ' factures (Total: ' || v_total || ')');
    END LOOP;
    CLOSE c_factures;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== MISE A JOUR TERMINEE ===');
    DBMS_OUTPUT.PUT_LINE('Total factures mises a jour : ' || v_total);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('PROCHAINE ETAPE : Executer le dump BO puis demain lancer RESTORE');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERREUR : ' || SQLERRM);
        ROLLBACK;
        RAISE;
END;
/

-- Verification post-update
SELECT 'Verification : ' || COUNT(*) || ' factures avec last_update_date = hier' AS RESULTAT
FROM ap_invoices_all
WHERE $ClauseIN
AND TRUNC(last_update_date) = TRUNC(SYSDATE) - 1;

EXIT;
"@

$ScriptUpdate | Out-File -FilePath $FichierUpdate -Encoding UTF8
Write-Host "   Script genere : $FichierUpdate" -ForegroundColor Green
Write-Host ""

# =====================================================================
# 4. GÉNÉRER SCRIPT DE RESTAURATION
# =====================================================================
Write-Host "[4/4] Generation du script de restauration..." -ForegroundColor Yellow

$FichierRestore = Join-Path $DossierSQL "03_restore_$Annee.sql"

# Note: Ce script sera régénéré dynamiquement lors de l'exécution avec les vraies données de backup
$ScriptRestore = @"
-- =====================================================================
-- SCRIPT DE RESTAURATION - Remettre les donnees originales
-- =====================================================================
-- Genere le : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
-- Ce script est un template. Le script final sera genere dynamiquement
-- a partir du fichier de sauvegarde lors de l'execution de RESTORE.
-- =====================================================================

SET SERVEROUTPUT ON
SET FEEDBACK ON

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

-- Le script de restauration sera genere dynamiquement par executer_sql_sync.ps1
-- Il lira le fichier CSV de sauvegarde et generera les UPDATE correspondants

DECLARE
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== SCRIPT TEMPLATE ===');
    DBMS_OUTPUT.PUT_LINE('Ce script doit etre regenere avec les donnees de sauvegarde.');
    DBMS_OUTPUT.PUT_LINE('Utilisez : sync_factures_bo.bat RESTORE $Annee');
END;
/

EXIT;
"@

$ScriptRestore | Out-File -FilePath $FichierRestore -Encoding UTF8
Write-Host "   Script genere : $FichierRestore" -ForegroundColor Green
Write-Host ""

# =====================================================================
# RÉSUMÉ
# =====================================================================
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  GENERATION TERMINEE" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Scripts generes dans : $DossierSQL" -ForegroundColor Green
Write-Host ""
Write-Host "  1. 01_sauvegarde_$Annee.sql  - Sauvegarde des donnees actuelles"
Write-Host "  2. 02_update_sync_$Annee.sql - Mise a jour last_update_date"
Write-Host "  3. 03_restore_$Annee.sql     - Template restauration"
Write-Host ""
Write-Host "Factures concernees : $NbFactures" -ForegroundColor Yellow
Write-Host ""

if ($Action -eq "GENERATE_ONLY") {
    Write-Host "Mode GENERATE_ONLY : Scripts generes sans execution." -ForegroundColor Yellow
    Write-Host "Pour executer : sync_factures_bo.bat PREPARE $Annee" -ForegroundColor Yellow
}

exit 0
