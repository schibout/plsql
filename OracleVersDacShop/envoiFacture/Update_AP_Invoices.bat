@ECHO OFF
SETLOCAL
TITLE Renvoi factures vers DacShop - invoice.csv
CD /D "%~dp0"

:: =====================================================================
::  Usage :
::     Update_AP_Invoices.bat          -> SIMULATION (aucune modification)
::     Update_AP_Invoices.bat EXEC     -> application reelle
::
::  Sans le mot-cle EXEC, les UPDATE sont joues puis annules : on voit
::  exactement ce qui serait modifie, sans rien conserver.
:: =====================================================================

ECHO.
ECHO =====================================================================
ECHO   RENVOI FACTURES VERS DACSHOP - invoice.csv
ECHO   Date : %DATE% %TIME%
ECHO =====================================================================

IF /I "%~1"=="EXEC" (
    ECHO   *** MODE EXECUTION REELLE ***
    ECHO.
    PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update_AP_Invoices.ps1" -Executer
) ELSE (
    ECHO   Mode SIMULATION - pour appliquer : Update_AP_Invoices.bat EXEC
    ECHO.
    PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update_AP_Invoices.ps1"
)

SET RC=%ERRORLEVEL%
IF %RC% EQU 1 (
    ECHO.
    ECHO [ERREUR] Erreur Oracle - aucune modification conservee.
) ELSE IF %RC% EQU 2 (
    ECHO.
    ECHO [ECART] Des identifiants sont sans correspondance dans AP_INVOICES_ALL.
) ELSE IF %RC% EQU 3 (
    ECHO.
    ECHO [ANNULE] Operation annulee par l'utilisateur.
)

PAUSE
EXIT /B %RC%
