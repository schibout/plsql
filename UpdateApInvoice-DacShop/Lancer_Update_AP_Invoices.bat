@ECHO OFF
REM =====================================================================
REM Lancer_Update_AP_Invoices.bat
REM =====================================================================
REM Lanceur pour Update_AP_Invoices_From_CSV.ps1
REM Usage : double-cliquer ou appeler depuis une invite de commandes
REM =====================================================================

CD /D "%~dp0"

ECHO.
ECHO =====================================================================
ECHO   UPDATE AP_INVOICES_ALL depuis CSV
ECHO =====================================================================
ECHO.
ECHO Options disponibles :
ECHO   [1] Execution normale (COMMIT si tout OK, ROLLBACK sinon)
ECHO   [2] Dry-Run          (genere le SQL sans l'executer)
ECHO   [3] Execution + conserver le SQL temporaire
ECHO.
SET /P CHOIX=Votre choix [1/2/3] (defaut=1) : 

IF "%CHOIX%"=="2" GOTO DRYRUN
IF "%CHOIX%"=="3" GOTO GARDER
GOTO NORMAL

:NORMAL
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update_AP_Invoices_From_CSV.ps1"
GOTO FIN

:DRYRUN
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update_AP_Invoices_From_CSV.ps1" -DryRun
GOTO FIN

:GARDER
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update_AP_Invoices_From_CSV.ps1" -GarderTempSQL
GOTO FIN

:FIN
ECHO.
PAUSE
