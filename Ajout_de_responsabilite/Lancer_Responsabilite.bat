@echo off
:: =====================================================================
:: Lanceur - Requetes Utilisateurs / Responsabilites Oracle EBS
:: =====================================================================
:: Date    : 01/04/2026
:: Scripts : Utilisateurs ayant une certaine responsabilite.sql
:: =====================================================================

cd /d "%~dp0"

echo.
echo =====================================================================
echo  EXECUTION - Utilisateurs ayant une certaine responsabilite
echo =====================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Lancer_SQL.ps1" -SqlFile "%~dp0Utilisateurs ayant une certaine responsabilite.sql"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] Le script a echoue avec le code : %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [OK] Execution terminee.
pause
