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

:: Codes retour : 0 = conforme, 1 = erreur technique,
::                2 = alerte fonctionnelle, 3 = avertissements
if %ERRORLEVEL% EQU 1 (
    echo.
    echo [ERREUR TECHNIQUE] Erreurs Oracle / SQL*Plus - le controle n'est pas fiable.
    pause
) else if %ERRORLEVEL% EQU 2 (
    echo.
    echo [ALERTE] Des anomalies fonctionnelles demandent une action ce matin.
    pause
) else if %ERRORLEVEL% EQU 3 (
    echo.
    echo [AVERTISSEMENT] Points a surveiller, sans action immediate.
    pause
) else if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] Le script a echoue avec le code : %ERRORLEVEL%
    pause
)
