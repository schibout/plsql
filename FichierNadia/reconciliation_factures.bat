@echo off
REM =====================================================================
REM Script de réconciliation factures payées Oracle vs BO
REM =====================================================================
REM Usage: reconciliation_factures.bat [ANNEE] [FICHIER_BO]
REM Exemple: reconciliation_factures.bat 2026
REM          reconciliation_factures.bat 2026 "C:\data\factures_bo_2026.csv"
REM =====================================================================

setlocal enabledelayedexpansion

REM =====================================================================
REM Configuration Oracle
REM =====================================================================
set ORACLE_USER=aroux
set ORACLE_PASSWORD=GAERFTXF
set ORACLE_HOST=prdscanc1pdb03.dalkia.net
set ORACLE_PORT=1521
set ORACLE_SERVICE=ebs_PDBFINP1
set ORACLE_DSN=%ORACLE_HOST%:%ORACLE_PORT%/%ORACLE_SERVICE%
set CONNECT_STRING=%ORACLE_USER%/%ORACLE_PASSWORD%@%ORACLE_DSN%

REM =====================================================================
REM Paramètres
REM =====================================================================
set SCRIPT_DIR=%~dp0

REM Récupérer l'année (paramètre ou année courante)
if "%1"=="" (
    for /f "tokens=1" %%i in ('powershell -Command "Get-Date -Format yyyy"') do set ANNEE=%%i
) else (
    set ANNEE=%1
)

REM Fichier BO (paramètre ou fichier par défaut)
if "%2"=="" (
    set FICHIER_BO=%SCRIPT_DIR%factureImpayees\Factures impayees BO %ANNEE%.csv
) else (
    set FICHIER_BO=%~2
)

REM Timestamp
for /f "tokens=1-6 delims=/: " %%a in ("%date% %time%") do (
    set TIMESTAMP=%%c%%b%%a_%%d%%e%%f
)
set TIMESTAMP=%TIMESTAMP: =0%

REM Fichiers temporaires
set TEMP_ORACLE_CSV=%SCRIPT_DIR%temp_oracle_%ANNEE%.csv
set TEMP_SQL=%SCRIPT_DIR%temp_extraction_reconciliation.sql

echo =======================================================================
echo   RECONCILIATION FACTURES PAYEES ORACLE vs BO
echo =======================================================================
echo Annee              : %ANNEE%
echo Fichier BO         : %FICHIER_BO%
echo Date execution     : %date% %time%
echo =======================================================================
echo.

REM =====================================================================
REM Détection du client SQL
REM =====================================================================
set SQL_CMD=

where sqlcl >nul 2>&1
if %errorlevel%==0 (
    set SQL_CMD=sqlcl
    goto :sql_found_recup
)

where sql >nul 2>&1
if %errorlevel%==0 (
    set SQL_CMD=sql
    goto :sql_found_recup
)

where sqlplus >nul 2>&1
if %errorlevel%==0 (
    set SQL_CMD=sqlplus
    goto :sql_found_recup
)

echo [ERREUR] Aucun client Oracle trouve (sqlcl, sql, ou sqlplus^)
exit /b 1

:sql_found_recup
echo [OK] Client SQL      : %SQL_CMD%

echo.
echo Etape 1 : Extraction des factures payees Oracle R12...
echo ----------------------------------------------------------------------

REM Vérifier si un fichier d'extraction récent existe
set FICHIER_ORACLE_EXISTANT=%SCRIPT_DIR%factures_payees_%ANNEE%*.csv
for /f "delims=" %%i in ('dir /b /od "%FICHIER_ORACLE_EXISTANT%" 2^>nul') do set DERNIER_FICHIER=%%i

if defined DERNIER_FICHIER (
    echo [INFO] Fichier d'extraction existant trouve : %DERNIER_FICHIER%
    echo        Voulez-vous le reutiliser ^(O^) ou extraire a nouveau ^(N^) ? [O/N]
    set /p REPONSE="Votre choix (O par defaut): "
    if /i "!REPONSE!"=="" set REPONSE=O
    if /i "!REPONSE!"=="O" (
        set TEMP_ORACLE_CSV=%SCRIPT_DIR%!DERNIER_FICHIER!
        echo [OK] Reutilisation du fichier : !DERNIER_FICHIER!
        goto :skip_extraction
    )
)

REM Générer le script SQL d'extraction
(
echo SET PAGESIZE 0
echo SET LINESIZE 32767
echo SET TRIMSPOOL ON
echo SET TRIMOUT ON
echo SET FEEDBACK OFF
echo SET VERIFY OFF
echo SET HEADING OFF
echo SET COLSEP ';'
echo SET NUMFORMAT 999999999999.99
echo.
echo ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
echo ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';
echo.
echo SPOOL "%TEMP_ORACLE_CSV%"
echo.
echo PROMPT ID_FACTURE;NUM_FACTURE;STATUT_PAIEMENT;MONTANT_FACTURE;MONTANT_PAYE;PAIEMENT_ID;NUMERO_PAIEMENT;DATE_PAIEMENT;MONTANT_PAIEMENT;DEVISE;DATE_MAJ_FACTURE
echo.
echo SELECT    
echo     aia.invoice_id ^|^| ';' ^|^|
echo     aia.invoice_num ^|^| ';' ^|^|
echo     aia.payment_status_flag ^|^| ';' ^|^|
echo     aia.invoice_amount ^|^| ';' ^|^|
echo     aia.amount_paid ^|^| ';' ^|^|
echo     ac.check_id ^|^| ';' ^|^|
echo     ac.check_number ^|^| ';' ^|^|
echo     ac.check_date ^|^| ';' ^|^|
echo     ac.amount ^|^| ';' ^|^|
echo     ac.currency_code ^|^| ';' ^|^|
echo     aia.last_update_date AS LIGNE
echo FROM ap_invoices_all aia
echo JOIN AP_INVOICE_PAYMENTS_all AIP 
echo     ON aia.INVOICE_ID = AIP.INVOICE_ID
echo JOIN AP_CHECKS_ALL AC 
echo     ON AIP.CHECK_ID = AC.CHECK_ID
echo WHERE aia.PAYMENT_STATUS_FLAG = 'Y'
echo   AND NVL^(aia.AMOUNT_PAID, 0^) ^^!= 0
echo   AND aia.invoice_amount ^^!= 0
echo   AND ac.status_lookup_code ^^!= 'VOIDED'
echo   AND EXTRACT^(YEAR FROM ac.check_date^) = %ANNEE%
echo ORDER BY ac.check_date DESC;
echo.
echo SPOOL OFF
echo EXIT;
) > "%TEMP_SQL%"

echo Connexion a Oracle : %ORACLE_USER%@%ORACLE_DSN%
%SQL_CMD% -S %CONNECT_STRING% @"%TEMP_SQL%"

if %errorlevel% neq 0 (
    echo [ERREUR] Impossible d'extraire les factures depuis Oracle
    del "%TEMP_SQL%" 2>nul
    exit /b 1
)

if not exist "%TEMP_ORACLE_CSV%" (
    echo [ERREUR] Fichier d'extraction Oracle non genere
    del "%TEMP_SQL%" 2>nul
    exit /b 1
)

echo [OK] Factures Oracle extraites : %TEMP_ORACLE_CSV%
del "%TEMP_SQL%" 2>nul

:skip_extraction

REM =====================================================================
REM Vérification du fichier BO
REM =====================================================================
echo.
echo Etape 2 : Verification du fichier BO...
echo ----------------------------------------------------------------------

if not exist "%FICHIER_BO%" (
    echo [ERREUR] Fichier BO introuvable : %FICHIER_BO%
    echo.
    echo Placez le fichier d'extraction BO dans :
    echo   %SCRIPT_DIR%factureImpayees\
    echo.
    echo Ou specifiez le chemin complet :
    echo   %~nx0 %ANNEE% "C:\chemin\vers\fichier_bo.csv"
    exit /b 1
)

echo [OK] Fichier BO    : %FICHIER_BO%
echo.

REM =====================================================================
REM Réconciliation avec PowerShell
REM =====================================================================
echo.
echo Etape 3 : Reconciliation et generation des rapports...
echo ----------------------------------------------------------------------

REM Si fichier temporaire, le renommer pour conservation
if "%TEMP_ORACLE_CSV%"=="%SCRIPT_DIR%temp_oracle_%ANNEE%.csv" (
    set FICHIER_FINAL=%SCRIPT_DIR%factures_payees_%ANNEE%_%TIMESTAMP%.csv
    copy /Y "%TEMP_ORACLE_CSV%" "!FICHIER_FINAL!" >nul
    echo [INFO] Fichier sauvegarde : factures_payees_%ANNEE%_%TIMESTAMP%.csv
) else (
    set FICHIER_FINAL=%TEMP_ORACLE_CSV%
    echo [INFO] Utilisation du fichier existant
)

REM Lancer le script PowerShell de réconciliation
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%\reconciliation_factures.ps1" -Annee %ANNEE%

if %errorlevel% neq 0 (
    echo.
    del "%TEMP_ORACLE_CSV%" 2>nul
    exit /b %errorlevel%
)

REM Nettoyage des fichiers temporaires
del "%TEMP_ORACLE_CSV%" 2>nul

echo.
echo [OK] Reconciliation terminee avec succes
echo =======================================================================
endlocal
