@echo off
:: =====================================================================
:: Lancer_Update_AP.bat
:: Mise à jour AP_INVOICES_ALL - Date du Jour
:: =====================================================================
:: Usage : Double-cliquer ou appeler depuis cmd
:: Pre-requis : sqlcl (ou sql / sqlplus) accessible dans le PATH
::              config.ps1 present dans ce meme dossier
:: =====================================================================

:: Aller dans le dossier du .bat
cd /d "%~dp0"

echo.
echo =====================================================================
echo   MISE A JOUR AP_INVOICES_ALL - DATE DU JOUR
echo =====================================================================
echo.

:: Appel du lanceur générique via PowerShell
powershell.exe -NoProfile -ExecutionPolicy Bypass ^
    -File "%~dp0..\Lancer_SQL.ps1" ^
    -SqlFile "%~dp0Update_AP_Invoices_Date_Jour.sql" ^
    -OuvrirLog

:: Conserver la fenetre ouverte en cas d'erreur
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] Le script a echoue avec le code : %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)
