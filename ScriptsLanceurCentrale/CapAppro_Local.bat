@echo off
setlocal EnableDelayedExpansion

REM ============================================================================
REM   Extracteur CapAppro local - lanceur CMD
REM
REM   Appelle CapAppro_Local.ps1 (extracteur natif PowerShell, sans Python)
REM   en lui transmettant les arguments tels quels.
REM
REM   Utilisation :
REM       CapAppro_Local.bat -List
REM       CapAppro_Local.bat 39 -DryRun
REM       CapAppro_Local.bat 39
REM       CapAppro_Local.bat 39,40
REM
REM   Codes retour : 0 succes | 1 echec d'execution | 2 argument invalide
REM                  3 PowerShell introuvable | 4 script introuvable
REM ============================================================================

REM --- Accents lisibles dans la console ---------------------------------------
chcp 65001 >nul 2>&1

REM --- Detection d'un lancement par double-clic, pour garder la fenetre -------
set "INTERACTIF="
echo %cmdcmdline% | find /i "%~f0" >nul 2>&1 && set "INTERACTIF=1"

pushd "%~dp0"

set "SCRIPT_PS1=%~dp0CapAppro_Local.ps1"
if not exist "%SCRIPT_PS1%" (
    echo [ERREUR] Script introuvable : "%SCRIPT_PS1%"
    set "CODE=4"
    goto :fin
)

REM --- Localiser PowerShell : pwsh 7 d'abord, Windows PowerShell en repli -----
set "PSEXE="
where pwsh >nul 2>&1 && set "PSEXE=pwsh"
if not defined PSEXE (
    where powershell >nul 2>&1 && set "PSEXE=powershell"
)
if not defined PSEXE (
    echo [ERREUR] PowerShell introuvable dans le PATH.
    set "CODE=3"
    goto :fin
)

REM --- Sans argument : afficher les lignes disponibles ------------------------
if "%~1"=="" (
    echo Aucun IdExec fourni : affichage des lignes disponibles.
    echo Exemple : %~nx0 39 -DryRun
    echo.
    %PSEXE% -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PS1%" -List
    set "CODE=!ERRORLEVEL!"
    goto :fin
)

REM -ExecutionPolicy Bypass evite d'avoir a modifier la strategie de la machine.
%PSEXE% -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PS1%" %*
set "CODE=!ERRORLEVEL!"

:fin
popd
if defined INTERACTIF (
    echo.
    echo Code retour : !CODE!
    pause
)
endlocal & exit /b %CODE%
