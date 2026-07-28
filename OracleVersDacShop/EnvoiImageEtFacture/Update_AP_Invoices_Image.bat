@ECHO OFF
SETLOCAL
TITLE Renvoi factures et images vers DacShop - invoiceImage.csv
CD /D "%~dp0"

:: =====================================================================
::  Usage :
::     Update_AP_Invoices_Image.bat          -> SIMULATION
::     Update_AP_Invoices_Image.bat EXEC     -> application reelle
::
::  Sans le mot-cle EXEC, les UPDATE sont joues puis annules : on voit
::  exactement ce qui serait modifie, sans rien conserver.
::  ATTENTION : ce traitement remet FND_ATTACHED_DOCUMENTS.ATTRIBUTE1
::  a NULL pour les factures listees. Cette valeur n'est pas sauvegardee.
:: =====================================================================

ECHO.
ECHO =====================================================================
ECHO   RENVOI FACTURES ET IMAGES VERS DACSHOP - invoiceImage.csv
ECHO   Date : %DATE% %TIME%
ECHO =====================================================================

IF /I "%~1"=="EXEC" (
    ECHO   *** MODE EXECUTION REELLE - ATTRIBUTE1 sera remis a NULL ***
    ECHO.
    PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update_AP_Invoices_Image.ps1" -Executer
) ELSE (
    ECHO   Mode SIMULATION - pour appliquer : Update_AP_Invoices_Image.bat EXEC
    ECHO.
    PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update_AP_Invoices_Image.ps1"
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
