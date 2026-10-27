@echo off
REM Lanceur Central - execution de fichiers SQL, ecriture en flux par lots
REM Usage :
REM   CapAppro_UN_SQL_FLUX.bat liste.csv [--lot N] [--configBDD section | --env-oracle env_oracle.sh] [--arret-sur-erreur] [--dry-run]
REM   CapAppro_UN_SQL_FLUX.bat fichier.sql sortie.csv [--lot N] [--configBDD section | --env-oracle env_oracle.sh]
REM Format de liste.csv : une ligne par extraction  requete.sql;resultat.csv (ou .xlsx)
REM Python : comme ODAT Watch (run.bat), on cherche un venv contenant oracledb :
REM   .venv\ a cote de ce fichier, puis C:\tmp\odatenv, sinon py du PATH.
setlocal
if "%~1"=="" (
    echo Usage : %~nx0 liste.csv [--lot N] [--configBDD section ^| --env-oracle env_oracle.sh] [--arret-sur-erreur] [--dry-run]
    echo    ou : %~nx0 fichier.sql sortie.csv^|sortie.xlsx [--lot N] [--configBDD section ^| --env-oracle env_oracle.sh]
    exit /b 2
)
set PY=
if exist "%~dp0.venv\Scripts\python.exe" set PY=%~dp0.venv\Scripts\python.exe
if "%PY%"=="" if exist "C:\tmp\odatenv\Scripts\python.exe" set PY=C:\tmp\odatenv\Scripts\python.exe
if "%PY%"=="" set PY=py

if /i "%~x1"==".csv" (
    "%PY%" "%~dp0CapAppro_UN_SQL_FLUX.py" --csv "%~1" %2 %3 %4 %5 %6 %7 %8 %9
) else (
    "%PY%" "%~dp0CapAppro_UN_SQL_FLUX.py" --sql "%~1" --sortie "%~2" %3 %4 %5 %6 %7 %8 %9
)
exit /b %ERRORLEVEL%
