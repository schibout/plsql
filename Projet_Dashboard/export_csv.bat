@echo off
rem Execute chaque requete de sql\ et depose un CSV par requete dans CSV_DIR.
rem Une requete en erreur garde son CSV precedent (le dashboard le signale comme perime).
rem Planification horaire : voir README.md. Code retour : nombre de requetes en echec.
setlocal EnableDelayedExpansion
cd /d "%~dp0"
if not exist config.bat (
  echo config.bat absent : copier config.exemple.bat en config.bat et le renseigner.
  exit /b 99
)
call config.bat
if not exist "%CSV_DIR%" mkdir "%CSV_DIR%"
set NLS_LANG=FRENCH_FRANCE.AL32UTF8
set KO=0
for %%F in (sql\[0-9]*.sql) do (
  set TMP_CSV=%TEMP%\dashboard_%%~nF.csv
  "%SQLPLUS%" -S -L "%ORA_CONN%" @sql\_export.sql "%%F" "!TMP_CSV!" > "%TEMP%\dashboard_%%~nF.log" 2>&1
  if errorlevel 1 (
    echo [KO] %%~nF - voir %TEMP%\dashboard_%%~nF.log
    set /a KO+=1
    del "!TMP_CSV!" 2>nul
  ) else (
    move /y "!TMP_CSV!" "%CSV_DIR%\%%~nF.csv" >nul
    echo [OK] %%~nF
  )
)
echo %date% %time% : %KO% requete^(s^) en echec.
exit /b %KO%
