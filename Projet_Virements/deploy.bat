@echo off
rem Deploie Projet_Virements vers le projet Apps Script lie par .clasp.json (clasp push).
rem Les tests Node doivent passer avant l'envoi. Premiere fois : npm install -g @google/clasp && clasp login
setlocal
cd /d "%~dp0"
echo === Tests locaux ===
node tests\run_local_tests.js || goto :ko
node tests\run_service_tests.js || goto :ko
echo === Envoi vers Apps Script ===
call clasp push --force || goto :ko
echo.
echo Deploiement OK. Dans l'editeur : diagnoseMailImports() puis processMailImports().
if not "%~1"=="--no-pause" pause
exit /b 0
:ko
echo.
echo ECHEC : rien n'a ete envoye si les tests ont echoue ; sinon voir le message clasp ci-dessus.
if not "%~1"=="--no-pause" pause
exit /b 1
