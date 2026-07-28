@echo off
REM =====================================================================
REM Script d'extraction des factures payées Oracle R12 (Windows Batch)
REM =====================================================================
REM Usage: extraction_factures_payees.bat [ANNEE]
REM Exemple: extraction_factures_payees.bat 2026
REM          extraction_factures_payees.bat 2025
REM          extraction_factures_payees.bat (année courante par défaut)
REM =====================================================================

setlocal enabledelayedexpansion

REM =====================================================================
REM Configuration Oracle EBS Production
REM =====================================================================
set ORACLE_USER=aroux
set ORACLE_PASSWORD=GAERFTXF
set ORACLE_HOST=prdscanc1pdb03.dalkia.net
set ORACLE_PORT=1521
set ORACLE_SERVICE=ebs_PDBFINP1
set ORACLE_DSN=%ORACLE_HOST%:%ORACLE_PORT%/%ORACLE_SERVICE%

REM =====================================================================
REM Paramètres d'extraction
REM =====================================================================
REM Récupérer l'année (paramètre ou année courante)
if "%1"=="" (
    for /f "tokens=1" %%i in ('powershell -Command "Get-Date -Format yyyy"') do set ANNEE=%%i
) else (
    set ANNEE=%1
)

REM Calculer l'année suivante
set /a ANNEE_SUIVANTE=%ANNEE%+1

REM Dates
set DATE_DEBUT=%ANNEE%-01-01
set DATE_FIN=%ANNEE_SUIVANTE%-01-01

REM Timestamp
for /f "tokens=1-6 delims=/: " %%a in ("%date% %time%") do (
    set TIMESTAMP=%%c%%b%%a_%%d%%e%%f
)
set TIMESTAMP=%TIMESTAMP: =0%

REM Fichiers
set SCRIPT_DIR=%~dp0
set OUTPUT_FILE=%SCRIPT_DIR%factures_payees_%ANNEE%_%TIMESTAMP%.csv
set SQL_FILE=%SCRIPT_DIR%temp_extraction_%ANNEE%.sql
set CONNECT_STRING=%ORACLE_USER%/%ORACLE_PASSWORD%@%ORACLE_DSN%

echo =======================================================================
echo   EXTRACTION FACTURES PAYEES ORACLE R12
echo =======================================================================
echo Annee              : %ANNEE%
echo Periode            : du %DATE_DEBUT% au %DATE_FIN%
echo Base de donnees    : %ORACLE_USER%@%ORACLE_DSN%
echo Fichier de sortie  : %OUTPUT_FILE%
echo =======================================================================

REM Vérification des variables
if "%ORACLE_USER%"=="" (
    echo ERREUR: ORACLE_USER non defini
    exit /b 1
)
if "%ORACLE_PASSWORD%"=="" (
    echo ERREUR: ORACLE_PASSWORD non defini
    exit /b 1
)

REM =====================================================================
REM Génération du fichier SQL
REM =====================================================================
echo.
echo Generation du fichier SQL...

(
echo SET PAGESIZE 0
echo SET LINESIZE 32767
echo SET TRIMSPOOL ON
echo SET TRIMOUT ON
echo SET FEEDBACK OFF
echo SET VERIFY OFF
echo SET HEADING ON
echo SET COLSEP ';'
echo SET NUMFORMAT 999999999999.99
echo.
echo -- Configuration format CSV
echo ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
echo ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';
echo.
echo SPOOL %OUTPUT_FILE%
echo.
echo -- =====================================================================
echo -- Requete Oracle R12 - Extraction des Factures Payees (VERSION OPTIMISEE^)
echo -- =====================================================================
echo -- Date de creation : 18/02/2026
echo -- Auteur : GitHub Copilot
echo -- Base de donnees : Oracle EBS 12.2.13
echo -- Periode extraction : %DATE_DEBUT% au %DATE_FIN%
echo --
echo -- AMELIORATION PAR RAPPORT A LA VERSION ORIGINALE :
echo -- 1. Utilisation de JOIN au lieu de EXISTS pour meilleures performances
echo -- 2. Filtre sur check_date au lieu de last_update_date
echo -- 3. Colonnes supplementaires (PAIEMENT_ID, MONTANT_PAIEMENT, DEVISE^)
echo -- 4. Parametrage par annee au lieu de J-1
echo -- =====================================================================
echo.
echo -- En-tete CSV
echo PROMPT ID_FACTURE;NUM_FACTURE;STATUT_PAIEMENT;MONTANT_FACTURE;MONTANT_PAYE;PAIEMENT_ID;NUMERO_PAIEMENT;DATE_PAIEMENT;MONTANT_PAIEMENT;DEVISE;FACTURE_LAST_UPDATE;FOURNISSEUR_ID;SITE_FOURNISSEUR_ID
echo.
echo SELECT    
echo     aia.invoice_id AS ID_FACTURE,
echo     aia.invoice_num AS NUM_FACTURE,
echo     aia.payment_status_flag AS STATUT_PAIEMENT,
echo     aia.invoice_amount AS MONTANT_FACTURE,
echo     aia.amount_paid AS MONTANT_PAYE,
echo     ac.check_id AS PAIEMENT_ID,
echo     ac.check_number AS NUMERO_PAIEMENT,
echo     ac.check_date AS DATE_PAIEMENT,
echo     ac.amount AS MONTANT_PAIEMENT,
echo     ac.currency_code AS DEVISE,
echo     aia.last_update_date AS FACTURE_LAST_UPDATE,
echo     aia.vendor_id AS FOURNISSEUR_ID,
echo     aia.vendor_site_id AS SITE_FOURNISSEUR_ID
echo FROM ap_invoices_all aia
echo JOIN AP_INVOICE_PAYMENTS_all AIP 
echo     ON aia.INVOICE_ID = AIP.INVOICE_ID
echo JOIN AP_CHECKS_ALL AC 
echo     ON AIP.CHECK_ID = AC.CHECK_ID
echo WHERE aia.PAYMENT_STATUS_FLAG = 'Y'
echo   AND NVL(aia.AMOUNT_PAID, 0^) ^^!= 0
echo   AND aia.invoice_amount ^^!= 0
echo   AND ac.status_lookup_code ^^!= 'VOIDED'
echo   AND EXTRACT(YEAR FROM ac.check_date^) = %ANNEE%
echo ORDER BY ac.check_date DESC, aia.invoice_id;
echo.
echo SPOOL OFF
echo EXIT;
) > "%SQL_FILE%"

REM =====================================================================
REM Détection du client SQL
REM =====================================================================
set SQL_CMD=

where sqlcl >nul 2>&1
if %errorlevel%==0 (
    set SQL_CMD=sqlcl
    goto :sql_found
)

where sql >nul 2>&1
if %errorlevel%==0 (
    set SQL_CMD=sql
    goto :sql_found
)

where sqlplus >nul 2>&1
if %errorlevel%==0 (
    set SQL_CMD=sqlplus
    goto :sql_found
)

echo ERREUR: Aucun client Oracle trouve (sqlcl, sql, ou sqlplus^)
echo Installez SQLcl ou SQL*Plus
del "%SQL_FILE%" 2>nul
exit /b 1

:sql_found
echo Utilisation de: %SQL_CMD%

REM =====================================================================
REM Exécution de la requête SQL
REM =====================================================================
echo.
echo Execution de la requete SQL...
echo ----------------------------------------------------------------------

%SQL_CMD% -S %CONNECT_STRING% @"%SQL_FILE%"

if %errorlevel%==0 (
    echo ----------------------------------------------------------------------
    echo [OK] EXTRACTION TERMINEE AVEC SUCCES
    echo.
    
    REM Statistiques
    if exist "%OUTPUT_FILE%" (
        for /f %%A in ('find /c /v "" ^< "%OUTPUT_FILE%"') do set NB_LIGNES=%%A
        set /a NB_FACTURES=!NB_LIGNES!-1
        for %%A in ("%OUTPUT_FILE%") do set TAILLE_FICHIER=%%~zA
        set /a TAILLE_KB=!TAILLE_FICHIER!/1024
        
        echo Nombre de factures : !NB_FACTURES!
        echo Taille du fichier  : !TAILLE_KB! KB
        echo Fichier genere     : %OUTPUT_FILE%
        
        REM Afficher les 5 premières lignes
        echo.
        echo Apercu (5 premieres factures^) :
        echo ----------------------------------------------------------------------
        powershell -Command "Get-Content '%OUTPUT_FILE%' -Head 6"
    ) else (
        echo ATTENTION: Fichier de sortie non genere
    )
) else (
    echo ----------------------------------------------------------------------
    echo [ERREUR] ERREUR LORS DE L'EXTRACTION
    echo Code retour: %errorlevel%
)

REM =====================================================================
REM Nettoyage
REM =====================================================================
del "%SQL_FILE%" 2>nul

echo =======================================================================
endlocal
