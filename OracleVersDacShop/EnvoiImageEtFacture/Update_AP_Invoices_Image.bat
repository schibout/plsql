@ECHO OFF
TITLE Update AP_INVOICES_ALL - invoice.csv
CD /D "%~dp0"

ECHO.
ECHO =====================================================================
ECHO   UPDATE AP.AP_INVOICES_ALL - invoiceImage.csv
ECHO   Date : %DATE% %TIME%
ECHO =====================================================================
ECHO.

PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update_AP_Invoices_Image.ps1" %*
EXIT /B %ERRORLEVEL%

