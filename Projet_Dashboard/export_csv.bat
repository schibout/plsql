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
rem "Error 6 initializing SQL*Plus / SP2-0667" = ORACLE_HOME absent ou faux. S'il n'a pas de
rem sqlplus\mesg, on le deduit de l'emplacement du client (client complet : ...\bin\sqlplus.exe).
rem Instant Client (pas de mesg) : ORACLE_HOME ne sert pas et un mauvais le casse, on le vide.
rem ORACLE_HOME peut aussi etre fixe dans config.bat.
set CLIENT_EXE=
if exist "%SQLPLUS%" (set "CLIENT_EXE=%SQLPLUS%") else for /f "delims=" %%P in ('where "%SQLPLUS%" 2^>nul') do if not defined CLIENT_EXE set "CLIENT_EXE=%%P"
if defined CLIENT_EXE if not exist "%ORACLE_HOME%\sqlplus\mesg" (
  for %%D in ("!CLIENT_EXE!\..") do set "CLIENT_DIR=%%~fD"
  for %%D in ("!CLIENT_DIR!") do if /i "%%~nxD"=="bin" (for %%H in ("!CLIENT_DIR!\..") do set "GUESS_HOME=%%~fH") else set "GUESS_HOME=!CLIENT_DIR!"
  if exist "!GUESS_HOME!\sqlplus\mesg" (set "ORACLE_HOME=!GUESS_HOME!") else set ORACLE_HOME=
)
echo Client : %CLIENT_EXE% - ORACLE_HOME=%ORACLE_HOME%
echo Connexion : %ORA_USER%@%ORA_HOST%:%ORA_PORT%/%ORA_SERVICE%
if not exist "%CSV_DIR%" mkdir "%CSV_DIR%"
rem AMERICAN : fichiers de messages anglais, toujours installes (le francais sp1f.msb manque souvent),
rem et point decimal dans les CSV. Les jours en francais sont forces dans les requetes (NLS_DATE_LANGUAGE).
set NLS_LANG=AMERICAN_AMERICA.AL32UTF8
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
