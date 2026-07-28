@ECHO OFF
TITLE Update AP_INVOICES_ALL - invoice.csv
CD /D "%~dp0"

ECHO.
ECHO =====================================================================
ECHO   UPDATE AP.AP_INVOICES_ALL - invoice.csv
ECHO   Date : %DATE% %TIME%
ECHO =====================================================================
ECHO.

PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update_AP_Invoices.ps1" %*
EXIT /B %ERRORLEVEL%

