@echo off
setlocal
:: =====================================================================
::  Desactivation d'utilisateurs Oracle EBS a une date donnee
:: =====================================================================
::  Usage :
::     Desactiver_Users.bat                    -> demande la date, simulation
::     Desactiver_Users.bat 31/12/2026         -> simulation
::     Desactiver_Users.bat 31/12/2026 EXEC    -> application reelle
::
::  Sans le mot-cle EXEC, RIEN n'est modifie en base.
:: =====================================================================

cd /d "%~dp0"

set "DATEFIN=%~1"
if "%DATEFIN%"=="" (
    echo.
    echo  Desactivation d'utilisateurs Oracle EBS
    echo  ---------------------------------------
    set /p DATEFIN=" Date de fin a appliquer (JJ/MM/AAAA) : "
)

if "%DATEFIN%"=="" (
    echo.
    echo  [ERREUR] Aucune date saisie. Abandon.
    echo.
    pause
    exit /b 1
)

if /i "%~2"=="EXEC" (
    echo.
    echo  *** MODE EXECUTION REELLE : les comptes seront modifies en base ***
    echo.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Desactiver_Users.ps1" -DateFin "%DATEFIN%" -Executer
) else (
    echo.
    echo  Mode SIMULATION : aucune modification ne sera effectuee.
    echo  Pour appliquer reellement : Desactiver_Users.bat %DATEFIN% EXEC
    echo.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Desactiver_Users.ps1" -DateFin "%DATEFIN%"
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  [ERREUR] Le script s'est termine avec le code : %ERRORLEVEL%
)

echo.
pause
