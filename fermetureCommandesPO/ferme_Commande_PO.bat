@ECHO OFF
TITLE Fermeture Commandes PO - po_list.csv
CD /D "%~dp0"

ECHO.
ECHO =====================================================================
ECHO   FERMETURE DEFINITIVE COMMANDES PO - po_list.csv
ECHO   Date : %DATE% %TIME%
ECHO =====================================================================
ECHO.

PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ferme_Commande_PO.ps1" %*
EXIT /B %ERRORLEVEL%

