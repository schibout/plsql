# =====================================================================
# Update_AP_Invoices_From_CSV.ps1
# =====================================================================
# Date de creation : 12/05/2026
# Base de donnees  : Oracle EBS 12.2.13 (Database 19.25.0.0.0)
#
# DESCRIPTION :
# Lit le fichier CSV payment052026.csv et met a jour AP_INVOICES_ALL
# pour chaque numero de facture : PAYMENT_STATUS_FLAG, LAST_UPDATE_DATE,
# LAST_UPDATED_BY, LAST_UPDATE_LOGIN.
#
# USAGE :
#   .\Update_AP_Invoices_From_CSV.ps1 [-CsvPath <chemin>] [-GarderTempSQL] [-DryRun]
#
# PARAMETRES :
#   -CsvPath       : Chemin vers le CSV (defaut : ..\payment052026.csv)
#   -GarderTempSQL : Conserve le fichier SQL temporaire apres execution
#   -DryRun        : Genere le SQL sans l'executer (pour validation)
# =====================================================================

param(
    [string]$CsvPath      = (Join-Path (Split-Path -Parent $PSScriptRoot) "payment052026.csv"),
    [switch]$GarderTempSQL,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp  = Get-Date -Format "ddMMyyyy_HHmmss"

Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  UPDATE AP_INVOICES_ALL depuis CSV - Oracle EBS" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "Date execution : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
if ($DryRun) {
    Write-Host "MODE           : DRY-RUN (aucune modification en base)" -ForegroundColor Yellow
}
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""

# --- 1. PREREQUIS ---
Write-Host "Etape 1 : Verification des prerequis..." -ForegroundColor Yellow

if (-not (Test-Path $CsvPath)) {
    Write-Host "[ERREUR] Fichier CSV introuvable : $CsvPath" -ForegroundColor Red
    exit 1
}
Write-Host "   Fichier CSV    : $CsvPath" -ForegroundColor Green

$LogDir = Join-Path $ScriptDir "Logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}
$FichierLog    = Join-Path $LogDir "Update_AP_${Timestamp}.log"
$FichierSQLTmp = Join-Path $LogDir "Update_AP_${Timestamp}_temp.sql"

$SQL_CMD = $null
foreach ($cmd in @('sqlcl', 'sql', 'sqlplus')) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) { $SQL_CMD = $cmd; break }
}
if ($null -eq $SQL_CMD) {
    Write-Host "[ERREUR] Aucun client Oracle trouve (sqlcl, sql ou sqlplus)" -ForegroundColor Red
    exit 1
}
Write-Host "   Client Oracle  : $SQL_CMD" -ForegroundColor Green
Write-Host "   Fichier log    : $FichierLog" -ForegroundColor Green
Write-Host ""

# --- 2. CONNEXION ORACLE ---
Write-Host "Etape 2 : Configuration connexion Oracle..." -ForegroundColor Yellow

$ConfigFile = Join-Path $ScriptDir "..\OracleVersDacShop\config.ps1"
if (-not (Test-Path $ConfigFile)) {
    # Fallback : chercher config.ps1 dans le repertoire courant ou parent
    $ConfigFile = Join-Path $ScriptDir "config.ps1"
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "[ERREUR] Fichier config.ps1 introuvable." -ForegroundColor Red
        Write-Host "         Creez un config.ps1 avec ORA_USER, ORA_PWD, ORA_HOST, ORA_PORT, ORA_SERVICE" -ForegroundColor Yellow
        exit 1
    }
}
. (Resolve-Path $ConfigFile)

$ORA_DSN     = "${ORA_HOST}:${ORA_PORT}/${ORA_SERVICE}"
$CONNECT_STR = "${ORA_USER}/${ORA_PWD}@${ORA_DSN}"

Write-Host "   Connexion      : ${ORA_USER}@${ORA_DSN}" -ForegroundColor Green
Write-Host ""

# --- 3. LECTURE DU CSV ---
Write-Host "Etape 3 : Lecture du CSV..." -ForegroundColor Yellow

$lignes = Import-Csv -Path $CsvPath -Encoding UTF8

# Normaliser les noms de colonnes (enlever guillemets residuels)
$colonnes = $lignes[0].PSObject.Properties.Name
Write-Host "   Colonnes detectees : $($colonnes -join ', ')" -ForegroundColor Gray

$nbTotal = $lignes.Count
Write-Host "   Factures a traiter : $nbTotal" -ForegroundColor Green
Write-Host ""

# --- 4. GENERATION DU SCRIPT SQL ---
Write-Host "Etape 4 : Generation du script SQL..." -ForegroundColor Yellow

$sqlContent = @"
-- =====================================================================
-- Script de mise a jour AP_INVOICES_ALL - Genere le $((Get-Date).ToString('dd/MM/yyyy HH:mm:ss'))
-- Source CSV : $CsvPath
-- Nombre de factures : $nbTotal
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF

DECLARE
    v_count_ok   NUMBER := 0;
    v_count_nok  NUMBER := 0;
    v_invoice_id NUMBER;
BEGIN

"@

foreach ($ligne in $lignes) {
    # Recuperer les champs (noms sans guillemets)
    $invoiceId  = ($ligne.'ID_FACTURE'         -replace '"','').Trim()
    $invoiceNum = ($ligne.'INVOICE_NUM'        -replace '"','').Trim()
    $flagPmt    = ($ligne.'PAYMENT_STATUS_FLAG'-replace '"','').Trim()

    # Echapper les apostrophes dans le numero de facture (securite SQL injection)
    $invoiceNumSafe = $invoiceNum -replace "'", "''"

    $sqlContent += @"

    -- Facture ID=$invoiceId NUM='$invoiceNumSafe'
    BEGIN
        UPDATE AP.AP_INVOICES_ALL
        SET    PAYMENT_STATUS_FLAG = '$flagPmt',
               LAST_UPDATE_DATE   = SYSDATE,
               LAST_UPDATED_BY    = FND_GLOBAL.USER_ID,
               LAST_UPDATE_LOGIN  = FND_GLOBAL.LOGIN_ID
        WHERE  INVOICE_ID  = $invoiceId
          AND  INVOICE_NUM = '$invoiceNumSafe';

        IF SQL%ROWCOUNT = 1 THEN
            v_count_ok := v_count_ok + 1;
        ELSE
            DBMS_OUTPUT.PUT_LINE('ATTENTION - Facture non trouvee : ID=$invoiceId NUM=$invoiceNumSafe');
            v_count_nok := v_count_nok + 1;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERREUR facture ID=$invoiceId NUM=$invoiceNumSafe : ' || SQLERRM);
            v_count_nok := v_count_nok + 1;
    END;

"@
}

$sqlContent += @"

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=============================================');
    DBMS_OUTPUT.PUT_LINE('RESULTATS MISE A JOUR AP_INVOICES_ALL');
    DBMS_OUTPUT.PUT_LINE('=============================================');
    DBMS_OUTPUT.PUT_LINE('  Factures mises a jour : ' || v_count_ok);
    DBMS_OUTPUT.PUT_LINE('  Factures non trouvees : ' || v_count_nok);
    DBMS_OUTPUT.PUT_LINE('  Total traite          : ' || (v_count_ok + v_count_nok));
    DBMS_OUTPUT.PUT_LINE('=============================================');

    IF v_count_nok = 0 THEN
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('COMMIT effectue - ' || v_count_ok || ' facture(s) mise(s) a jour.');
    ELSE
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK effectue - ' || v_count_nok || ' erreur(s) detectee(s).');
        DBMS_OUTPUT.PUT_LINE('Corriger les ecarts et relancer.');
    END IF;

END;
/

EXIT;
"@

$sqlContent | Out-File -FilePath $FichierSQLTmp -Encoding UTF8
Write-Host "   Script SQL genere : $FichierSQLTmp" -ForegroundColor Green
Write-Host "   Nombre de blocs UPDATE : $nbTotal" -ForegroundColor Green
Write-Host ""

# --- 5. EXECUTION ---
if ($DryRun) {
    Write-Host "Etape 5 : [DRY-RUN] Script SQL genere mais NON execute." -ForegroundColor Yellow
    Write-Host "   Pour inspecter : $FichierSQLTmp" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[DRY-RUN] Fin du script - aucune modification effectuee." -ForegroundColor Yellow
    exit 0
}

Write-Host "Etape 5 : Execution sur Oracle EBS..." -ForegroundColor Yellow
Write-Host "   Mise a jour de $nbTotal factures en cours..." -ForegroundColor Gray

$sqlFileForOracle = $FichierSQLTmp -replace '\\', '/'

$sortieOracle = & $SQL_CMD -S "$CONNECT_STR" "@$FichierSQLTmp" 2>&1
$exitCode = $LASTEXITCODE

# Afficher la sortie Oracle
$sortieOracle | Tee-Object -FilePath $FichierLog

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "Execution Oracle terminee avec succes." -ForegroundColor Green
} else {
    Write-Host "[ATTENTION] SQLcl a retourne le code : $exitCode" -ForegroundColor Yellow
}
Write-Host "   Log complet : $FichierLog" -ForegroundColor Cyan
Write-Host ""

# --- 6. NETTOYAGE ---
if (-not $GarderTempSQL) {
    Remove-Item $FichierSQLTmp -ErrorAction SilentlyContinue
    Write-Host "   Fichier SQL temporaire supprime." -ForegroundColor Gray
} else {
    Write-Host "   Fichier SQL temporaire conserve : $FichierSQLTmp" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  FIN - Update AP_INVOICES_ALL" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
