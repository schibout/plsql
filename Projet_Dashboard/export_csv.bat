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
call "%~dp0config.bat"
rem Memes variables que ControleMatinGenerique\config.ps1 ; ORA_CONN reste accepte tel quel.
if not defined ORA_CONN set ORA_CONN=%ORA_USER%/%ORA_PWD%@%ORA_HOST%:%ORA_PORT%/%ORA_SERVICE%
rem Client : SQLPLUS de config.bat, sinon le premier trouve (meme ordre que Lancer_Controle_Quotidien.ps1).
if not defined SQLPLUS for %%C in (sqlcl sql sqlplus) do if not defined SQLPLUS (
  where %%C >nul 2>&1 && set SQLPLUS=%%C
)
if not defined SQLPLUS (
  echo Aucun client Oracle trouve ^(sqlcl, sql ou sqlplus^).
  exit /b 97
)
echo Client : %SQLPLUS% - connexion %ORA_USER%@%ORA_HOST%:%ORA_PORT%/%ORA_SERVICE%
if not exist "%CSV_DIR%" mkdir "%CSV_DIR%"
set NLS_LANG=FRENCH_FRANCE.AL32UTF8
set KO=0
set NB=0
rem cmd ne connait pas [0-9] dans un motif : toutes les .sql de sql\ sont des requetes.
for %%F in (sql\*.sql) do (
  set /a NB+=1
  set TMP_CSV=%TEMP%\dashboard_%%~nF.csv
  rem < nul : un mot de passe refuse ne doit pas bloquer la tache planifiee sur une invite.
  call "%SQLPLUS%" -S -L "%ORA_CONN%" @export.sql "%%F" "!TMP_CSV!" < nul > "%TEMP%\dashboard_%%~nF.log" 2>&1
  if errorlevel 1 (
    echo [KO] %%~nF - voir %TEMP%\dashboard_%%~nF.log
    set /a KO+=1
    del "!TMP_CSV!" 2>nul
  ) else (
    move /y "!TMP_CSV!" "%CSV_DIR%\%%~nF.csv" >nul
    echo [OK] %%~nF
  )
)
if %NB%==0 (
  echo Aucune requete trouvee dans %CD%\sql
  exit /b 98
)
echo %date% %time% : %NB% requete^(s^), %KO% en echec.
exit /b %KO%
