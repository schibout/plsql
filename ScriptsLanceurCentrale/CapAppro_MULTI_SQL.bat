@echo off
REM Lanceur Central - execution de plusieurs fichiers SQL listes dans un CSV
REM Usage : CapAppro_MULTI_SQL.bat liste.csv [--configBDD section | --env-oracle env_oracle.sh] [--arret-sur-erreur] [--dry-run]
REM Format du CSV : une ligne par extraction  fichier.sql;sortie.csv (ou .xlsx)
REM Python : comme CapAppro_UN_SQL.bat (.venv local, puis C:\tmp\odatenv, sinon py).
setlocal
if "%~1"=="" (
    echo Usage : %~nx0 liste.csv [--configBDD section ^| --env-oracle env_oracle.sh] [--arret-sur-erreur] [--dry-run]
    exit /b 2
)
set PY=
if exist "%~dp0.venv\Scripts\python.exe" set PY=%~dp0.venv\Scripts\python.exe
if "%PY%"=="" if exist "C:\tmp\odatenv\Scripts\python.exe" set PY=C:\tmp\odatenv\Scripts\python.exe
if "%PY%"=="" set PY=py

"%PY%" "%~dp0CapAppro_MULTI_SQL.py" --csv "%~1" %2 %3 %4 %5 %6
exit /b %ERRORLEVEL%
