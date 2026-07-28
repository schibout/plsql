@echo off
REM =====================================================================
REM Script batch pour lancer l'analyse des factures impayees BO
REM =====================================================================
REM Usage: analyse_factures_impayees.bat [ANNEE] [MODE]
REM   ANNEE : Annee a analyser (par defaut : annee courante)
REM   MODE  : simple (defaut) ou batch (traitement par lots)
REM Exemples:
REM   analyse_factures_impayees.bat 2025
REM   analyse_factures_impayees.bat 2025 batch
REM   analyse_factures_impayees.bat 2026 simple
REM =====================================================================

setlocal

REM Recuperer l'annee (parametre ou annee courante)
if "%1"=="" (
    for /f "tokens=1" %%i in ('powershell -Command "Get-Date -Format yyyy"') do set ANNEE=%%i
) else (
    set ANNEE=%1
)

REM Recuperer le mode (simple ou batch)
if "%2"=="" (
    set MODE=simple
) else (
    set MODE=%2
)

set SCRIPT_DIR=%~dp0

echo =======================================================================
echo   ANALYSE DES FACTURES IMPAYEES BO
echo =======================================================================
echo Annee      : %ANNEE%
echo Mode       : %MODE%
echo Repertoire : %SCRIPT_DIR%
echo =======================================================================
echo.

REM Verifier que le fichier BO existe
set FICHIER_BO=%SCRIPT_DIR%factureImpayees\Factures impayees BO %ANNEE%.csv

if not exist "%FICHIER_BO%" (
    echo [ERREUR] Fichier BO introuvable : %FICHIER_BO%
    echo.
    echo Fichiers disponibles :
    dir /b "%SCRIPT_DIR%factureImpayees\*.csv"
    echo.
    pause
    exit /b 1
)

echo [OK] Fichier BO trouve : %FICHIER_BO%
echo.

REM Lancer le script PowerShell approprie
if /i "%MODE%"=="batch" goto :mode_batch
if /i "%MODE%"=="simple" goto :mode_simple
goto :mode_simple

:mode_batch
echo Lancement du mode BATCH - traitement par lots de 1000...
echo.
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%analyse_factures_impayees_batch.ps1" -Annee %ANNEE% -TailleLot 1000
goto :fin_execution

:mode_simple
echo Lancement du mode SIMPLE - limitation a 5000 factures...
echo.
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%analyse_factures_impayees_simple.ps1" -Annee %ANNEE% -MaxFactures 5000
goto :fin_execution

:fin_execution

if %errorlevel% neq 0 (
    echo.
    echo [ERREUR] Le script PowerShell a rencontre une erreur
    pause
    exit /b %errorlevel%
)

echo.
echo =======================================================================
echo   ANALYSE TERMINEE
echo =======================================================================
echo.
echo Fichiers generes dans : %SCRIPT_DIR%
dir /b /od "%SCRIPT_DIR%factures_detaillees_%ANNEE%*.csv" 2>nul

echo.
pause
endlocal
