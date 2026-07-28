@echo off
REM ============================================================
REM Lancement du controle des virements pour une date donnee.
REM Usage : controle_virements.bat 26062026
REM Sans argument : la date du jour au format DDMMYYYY est utilisee.
REM ============================================================
setlocal

set "DATE_ARG=%~1"
if "%DATE_ARG%"=="" (
    for /f "tokens=1-3 delims=/-. " %%a in ("%date%") do set "DATE_ARG=%%a%%b%%c"
)

REM Se placer dans le repertoire du script
cd /d "%~dp0"

REM Interpreteur Python : 'py' si disponible, sinon 'python'
where py >nul 2>&1
if %errorlevel%==0 (
    set "PYEXE=py"
) else (
    set "PYEXE=python"
)

REM S'assurer que la dependance xlrd (lecture du .xls Quartz) est presente
%PYEXE% -c "import xlrd" >nul 2>&1
if not %errorlevel%==0 (
    echo Installation des dependances manquantes ^(xlrd^)...
    %PYEXE% -m pip install -q -r requirements.txt
)

echo Lancement du controle des virements pour la date %DATE_ARG%...
%PYEXE% controle_virements.py %DATE_ARG%
set "RC=%errorlevel%"

echo.
if "%RC%"=="0" (
    echo Resultat : OK ^(aucun ecart^)
) else (
    echo Resultat : ECARTS DETECTES ^(code %RC%^) - consultez rapport_%DATE_ARG%\synthese.md
)

endlocal & exit /b %RC%
