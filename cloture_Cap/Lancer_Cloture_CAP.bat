@echo off
:: =====================================================================
:: Lanceur - Export Cloture CAP Oracle EBS
:: =====================================================================
:: Date    : 01/04/2026
::
:: Fichiers generes dans cloture_Cap\Exports\ :
::   - Lignes de commande rejetees_2604.xlsx
::   - DTR Provisions PO avec Cde_2604.csv
::   - Od Cut Off SSTR avec factures_2604.xlsx
::   - Provisions PO avec Cde_2604.xlsx
::
:: Periode par defaut : DEC-25
:: Pour changer la periode : Lancer_Cloture_CAP.bat MAR-26
:: =====================================================================

cd /d "%~dp0"

:: Periode passee en argument (defaut DEC-25)
set PERIODE=%~1
if "%PERIODE%"=="" set PERIODE=DEC-25

echo.
echo =====================================================================
echo  EXPORT CLOTURE CAP  -  Periode : %PERIODE%
echo =====================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass ^
    -File "%~dp0Export_Cloture_CAP.ps1" ^
    -Periode "%PERIODE%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] Le script a echoue avec le code : %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

echo.
pause
