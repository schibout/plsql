@echo off
REM Lance ODAT Watch : import des nouveaux fichiers ODAT puis interface web.
REM Python attendu dans .venv\ (a cote de ce fichier) ou C:\tmp\odatenv, sinon python du PATH.
setlocal
cd /d "%~dp0"
set PY=
if exist ".venv\Scripts\python.exe" set PY=.venv\Scripts\python.exe
if "%PY%"=="" if exist "C:\tmp\odatenv\Scripts\python.exe" set PY=C:\tmp\odatenv\Scripts\python.exe
if "%PY%"=="" set PY=python

"%PY%" ingest.py
"%PY%" -m streamlit run app.py --server.headless true --browser.gatherUsageStats false
endlocal
