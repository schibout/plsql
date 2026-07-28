@echo off
:: Lanceur generique - Execution de scripts SQL Oracle EBS
:: Usage : Lancer_SQL.bat <chemin_du_fichier.sql>
:: Exemple : Lancer_SQL.bat monScript.sql
:: Exemple : Lancer_SQL.bat C:\plsql\dossier\monScript.sql

cd /d "%~dp0"

if "%~1"=="" (
    echo.
    echo Usage : Lancer_SQL.bat ^<fichier.sql^>
    echo.
    echo Exemples :
    echo    Lancer_SQL.bat monScript.sql
    echo    Lancer_SQL.bat C:\plsql\dossier\monScript.sql
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Lancer_SQL.ps1" -SqlFile "%~1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] Le script a echoue avec le code : %ERRORLEVEL%
    pause
)
