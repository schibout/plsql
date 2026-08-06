@echo off
setlocal

:: ============================================================================
:: Lanceur pour le script de rapprochement des prélèvements Oracle vs EDF.
::
:: DESCRIPTION:
:: Ce batch exécute le script PowerShell 'Prelevements_Rapprochement_Oracle_EDF.ps1'.
:: Il génère un rapport Excel comparant les prélèvements émis par Oracle
:: et ceux reçus par EDF.
::
:: USAGE:
::   1. Double-cliquer sur ce fichier pour analyser le dossier courant.
::   2. Lancer depuis une console :
::      Lancer_Rapprochement.bat [chemin_vers_le_dossier_a_analyser]
::
:: EXEMPLE:
::   Lancer_Rapprochement.bat "D:\TOTO\Prelevements_20260625"
:: ============================================================================

title Rapprochement des Prelevements Oracle-EDF

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_PATH=%SCRIPT_DIR%Prelevements_Rapprochement_Oracle_EDF.ps1"

:: Le chemin racine est le premier argument, sinon le dossier du script.
set "RACINE_PATH=%~1"
if not defined RACINE_PATH (
    :: %SCRIPT_DIR% (%~dp0) se termine par un backslash.
    :: On l'enleve pour eviter un bug de parsing de PowerShell lorsque l'argument
    :: est passe entre guillemets.
    set "RACINE_PATH=%SCRIPT_DIR:~0,-1%"
)

echo Lancement du script de rapprochement pour le dossier : "%RACINE_PATH%"
echo.

:: Appel de PowerShell en contournant la politique d'exécution locale.
:: Le paramètre -NoPause est ajouté pour une exécution non-interactive.
powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -RacinePath "%RACINE_PATH%" -NoPause

endlocal