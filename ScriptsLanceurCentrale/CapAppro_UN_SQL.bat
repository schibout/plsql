@echo off
REM Lanceur Central - execution d'un seul fichier SQL
REM Usage : CapAppro_UN_SQL.bat fichier.sql sortie.csv [--configBDD section | --env-oracle env_oracle.sh]
REM Python : comme ODAT Watch (run.bat), on cherche un venv contenant oracledb :
REM   .venv\ a cote de ce fichier, puis C:\tmp\odatenv, sinon py du PATH.
setlocal
if "%~2"=="" (
    echo Usage : %~nx0 fichier.sql sortie.csv^|sortie.xlsx [--configBDD section ^| --env-oracle env_oracle.sh]
    exit /b 2
)
set PY=
if exist "%~dp0.venv\Scripts\python.exe" set PY=%~dp0.venv\Scripts\python.exe
if "%PY%"=="" if exist "C:\tmp\odatenv\Scripts\python.exe" set PY=C:\tmp\odatenv\Scripts\python.exe
if "%PY%"=="" set PY=py

"%PY%" "%~dp0CapAppro_UN_SQL.py" --sql "%~1" --sortie "%~2" %3 %4 %5 %6
exit /b %ERRORLEVEL%
