@echo off
REM Lanceur Central - execution d'un seul fichier SQL
REM Usage : CapAppro_UN_SQL.bat fichier.sql sortie.csv [--configBDD section | --env-oracle env_oracle.sh]
if "%~2"=="" (
    echo Usage : %~nx0 fichier.sql sortie.csv^|sortie.xlsx [--configBDD section ^| --env-oracle env_oracle.sh]
    exit /b 2
)
py "%~dp0CapAppro_UN_SQL.py" --sql "%~1" --sortie "%~2" %3 %4 %5 %6
exit /b %ERRORLEVEL%
