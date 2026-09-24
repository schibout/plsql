@echo off
rem Export horaire des requetes de sql\ en CSV (voir export_csv.py).
rem Connexion Oracle : odat_watch\config.ini, comme odat_watch.
rem config.bat (optionnel, non versionne) peut redefinir CSV_DIR et PYTHON.
setlocal
cd /d "%~dp0"
set CSV_DIR=G:\Mon Drive\Dashboard_CSV
set PYTHON=python
if exist "%~dp0config.bat" call "%~dp0config.bat"
"%PYTHON%" "%~dp0export_csv.py" "%CSV_DIR%"
exit /b %ERRORLEVEL%
