@echo off
:: Lanceur - Controle Quotidien Complet Oracle EBS
:: Double-cliquer ou appeler depuis cmd pour executer le script PowerShell

:: Aller dans le dossier du .bat
cd /d "%~dp0"

:: Parametres par defaut (modifier ici si besoin)
set NB_JOURS=3
set HEURE_FERMETURE=19
set HEURE_OUVERTURE=7

:: Options : ajouter -GarderTempSQL a la fin de la ligne powershell pour debug
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Lancer_Controle_Quotidien.ps1" -NbJoursHisto %NB_JOURS% -HeureFermeture %HEURE_FERMETURE% -HeureOuverture %HEURE_OUVERTURE%

:: Garder la fenetre ouverte si erreur
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] Le script a echoue avec le code : %ERRORLEVEL%
    pause
)
