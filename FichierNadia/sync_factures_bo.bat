@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: =====================================================================
:: ORCHESTRATEUR - Synchronisation Factures Oracle vers BO
:: =====================================================================
:: Ce script gère le cycle complet :
::   1. Génération des scripts SQL
::   2. (Optionnel) Exécution via SQL*Plus/SQLcl si disponible
::   3. Instructions pour exécution manuelle via SQL Developer
:: =====================================================================
:: Usage:
::   sync_factures_bo.bat GENERATE [année]   - Génère les scripts SQL
::   sync_factures_bo.bat COUNT [année]      - Compte les factures
::   sync_factures_bo.bat SAMPLE [année]     - Affiche un échantillon
::   sync_factures_bo.bat PREPARE [année]    - Génère + tente exécution auto
::   sync_factures_bo.bat RESTORE [année]    - Restaure les données
::   sync_factures_bo.bat STATUS [année]     - Vérifie l'état
:: =====================================================================

set "SCRIPT_DIR=%~dp0"
set "ACTION=%~1"
set "ANNEE=%~2"

:: Valeurs par défaut
if "%ANNEE%"=="" set "ANNEE=%date:~6,4%"
if "%ACTION%"=="" set "ACTION=HELP"

:: Timestamp pour les fichiers
for /f "tokens=1-3 delims=/" %%a in ("%date%") do set "DATESTAMP=%%c%%b%%a"
for /f "tokens=1-2 delims=:" %%a in ("%time: =0%") do set "TIMESTAMP=%%a%%b"
set "TIMESTAMP=%DATESTAMP%_%TIMESTAMP%"

echo.
echo =====================================================================
echo   SYNCHRONISATION FACTURES ORACLE vers BO
echo =====================================================================
echo   Action  : %ACTION%
echo   Annee   : %ANNEE%
echo   Date    : %date% %time%
echo =====================================================================
echo.

:: Dispatcher selon l'action
if /i "%ACTION%"=="GENERATE" goto :GENERATE
if /i "%ACTION%"=="COUNT" goto :COUNT
if /i "%ACTION%"=="SAMPLE" goto :SAMPLE
if /i "%ACTION%"=="PREPARE" goto :PREPARE
if /i "%ACTION%"=="RESTORE" goto :RESTORE
if /i "%ACTION%"=="STATUS" goto :STATUS
if /i "%ACTION%"=="HELP" goto :HELP
goto :HELP

:: =====================================================================
:: ACTION: GENERATE - Génère les scripts SQL
:: =====================================================================
:GENERATE
echo Generation des scripts SQL pour l'annee %ANNEE%...
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%generer_sql_sync.ps1" -Annee %ANNEE% -Action GENERATE
echo.
echo =====================================================================
echo   PROCHAINES ETAPES
echo =====================================================================
echo   1. Ouvrir SQL Developer et se connecter a Oracle PROD
echo   2. Executer sql_sync\01_sauvegarde_%ANNEE%.sql
echo   3. Exporter le resultat en CSV dans backup\
echo   4. Executer sql_sync\02_update_sync_%ANNEE%.sql
echo   5. Attendre le batch BO de nuit
echo   6. Demain : generer et executer le script de restauration
echo =====================================================================
goto :EOF

:: =====================================================================
:: ACTION: COUNT - Compte les factures
:: =====================================================================
:COUNT
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%generer_sql_sync.ps1" -Annee %ANNEE% -Action COUNT
goto :EOF

:: =====================================================================
:: ACTION: SAMPLE - Affiche un échantillon
:: =====================================================================
:SAMPLE
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%generer_sql_sync.ps1" -Annee %ANNEE% -Action SAMPLE -Limit 20
goto :EOF

:: =====================================================================
:: ACTION: PREPARE - Génère + tente exécution automatique
:: =====================================================================
:PREPARE
echo [ETAPE 1/3] Generation des scripts SQL...
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%generer_sql_sync.ps1" -Annee %ANNEE% -Action GENERATE
if errorlevel 1 (
    echo ERREUR: Echec generation scripts
    exit /b 1
)

echo.
echo [ETAPE 2/3] Tentative d'execution automatique...
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%executer_sql_sync.ps1" -Annee %ANNEE% -Action BACKUP
if errorlevel 1 (
    echo.
    echo =====================================================================
    echo   EXECUTION AUTOMATIQUE NON DISPONIBLE
    echo =====================================================================
    echo   SQL*Plus/SQLcl local non configure ou erreur de connexion.
    echo   Veuillez executer manuellement dans SQL Developer :
    echo.
    echo   1. sql_sync\01_sauvegarde_%ANNEE%.sql (exporter en CSV)
    echo   2. sql_sync\02_update_sync_%ANNEE%.sql
    echo =====================================================================
    goto :EOF
)

echo.
echo [ETAPE 3/3] Mise a jour last_update_date...
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%executer_sql_sync.ps1" -Annee %ANNEE% -Action UPDATE
if errorlevel 1 (
    echo ERREUR: Echec mise a jour
    exit /b 1
)

echo.
echo =====================================================================
echo   PREPARATION TERMINEE AVEC SUCCES
echo =====================================================================
echo   Demain : sync_factures_bo.bat RESTORE %ANNEE%
echo =====================================================================
goto :EOF

:: =====================================================================
:: ACTION: RESTORE
:: =====================================================================
:RESTORE
echo Restauration des donnees pour l'annee %ANNEE%...
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%executer_sql_sync.ps1" -Annee %ANNEE% -Action RESTORE
if errorlevel 1 (
    echo.
    echo =====================================================================
    echo   RESTAURATION MANUELLE REQUISE
    echo =====================================================================
    echo   Utilisez le fichier CSV de sauvegarde et le template :
    echo   sql_sync\03_restore_template_%ANNEE%.sql
    echo =====================================================================
)
goto :EOF

:: =====================================================================
:: ACTION: STATUS
:: =====================================================================
:STATUS
echo Verification de l'etat des factures...
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%executer_sql_sync.ps1" -Annee %ANNEE% -Action STATUS
goto :EOF

:: =====================================================================
:: HELP
:: =====================================================================
:HELP
echo.
echo USAGE: sync_factures_bo.bat [ACTION] [ANNEE]
echo.
echo ACTIONS PRINCIPALES:
echo   GENERATE [annee]  - Genere les scripts SQL (recommande)
echo   COUNT [annee]     - Compte les factures impayees BO
echo   SAMPLE [annee]    - Affiche un echantillon d'IDs
echo.
echo ACTIONS AVANCEES (necessite SQL*Plus/SQLcl configure):
echo   PREPARE [annee]   - Generation + execution automatique
echo   RESTORE [annee]   - Restauration automatique
echo   STATUS [annee]    - Verification de l'etat
echo.
echo WORKFLOW RECOMMANDE:
echo   1. sync_factures_bo.bat GENERATE 2025
echo   2. Executer les scripts dans SQL Developer
echo   3. Le lendemain : executer le script de restauration
echo.
goto :EOF
