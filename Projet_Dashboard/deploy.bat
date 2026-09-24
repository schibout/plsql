@echo off
rem Deploie Projet_Dashboard vers le projet Apps Script lie par .clasp.json (clasp push).
rem Premiere fois : npm install -g @google/clasp && clasp login, puis voir README.md.
rem Si .deployment_id existe, le deploiement web existant est mis a jour (URL /exec inchangee).
setlocal
cd /d "%~dp0"
if not exist .clasp.json (
  echo .clasp.json absent : voir README.md, section Premiere installation.
  goto :ko
)
echo === Tests locaux ===
node tests\run_local_tests.js || goto :ko
echo === Envoi vers Apps Script ===
call clasp push --force || goto :ko
if not exist .deployment_id goto :ok
set /p DEPLOYMENT_ID=<.deployment_id
echo === Mise a jour du deploiement %DEPLOYMENT_ID% ===
call clasp deploy -i %DEPLOYMENT_ID% -d "deploy.bat %date% %time%" || goto :ko
:ok
echo.
echo Deploiement OK.
if not "%~1"=="--no-pause" pause
exit /b 0
:ko
echo.
echo ECHEC : voir le message ci-dessus.
if not "%~1"=="--no-pause" pause
exit /b 1
