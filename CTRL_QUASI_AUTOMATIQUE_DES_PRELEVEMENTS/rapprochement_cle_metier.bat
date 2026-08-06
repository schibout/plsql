@echo off
REM ============================================================
REM Rapprochement des prelevements Oracle / EDF par cle metier.
REM Rapproche sur (IBAN creancier x echeance) et qualifie chaque
REM ecart a l'aide des rejets internes apparies sur le RUM.
REM
REM Usage : rapprochement_cle_metier.bat
REM         rapprochement_cle_metier.bat --date 2026-08-06
REM         rapprochement_cle_metier.bat --jours 15
REM         rapprochement_cle_metier.bat --sortie "C:\mes rapports"
REM         rapprochement_cle_metier.bat --no-pause   (execution planifiee)
REM         rapprochement_cle_metier.bat --help
REM
REM Les arguments autres que --no-pause sont transmis au script Python.
REM
REM Code retour : 0 = rien a traiter, 1 = anomalies, 2 = erreur,
REM               3 = execution degradee (resultat partiel).
REM ============================================================
setlocal enabledelayedexpansion

REM Se placer dans le repertoire du script
cd /d "%~dp0"

REM --- Analyse des arguments -------------------------------------------------
REM Chaque argument est re-encadre de guillemets : les chemins contenant des
REM espaces sont transmis intacts. --no-pause est consomme ici.
set "PAUSE_FIN=1"
set "ARGS="
:analyse_args
if "%~1"=="" goto args_ok
if /i "%~1"=="--no-pause" (
    set "PAUSE_FIN=0"
) else (
    set ARGS=!ARGS! "%~1"
)
shift
goto analyse_args
:args_ok

REM --- Choix de l'interpreteur Python ---------------------------------------
where py >nul 2>&1
if %errorlevel%==0 (set "PYEXE=py") else (set "PYEXE=python")

%PYEXE% --version >nul 2>&1
if not %errorlevel%==0 (
    echo ERREUR : Python est introuvable. Installez-le depuis https://www.python.org/
    set "RC=2"
    goto fin
)

REM --- Dependance openpyxl (generation du .xlsx) -----------------------------
%PYEXE% -c "import openpyxl" >nul 2>&1
if %errorlevel%==0 goto traitement

echo Installation de la dependance manquante ^(openpyxl^)...
%PYEXE% -m pip install -q -r requirements.txt
%PYEXE% -c "import openpyxl" >nul 2>&1
if not %errorlevel%==0 (
    echo ERREUR : openpyxl reste indisponible.
    echo Installez-la manuellement : %PYEXE% -m pip install openpyxl
    set "RC=2"
    goto fin
)

REM --- Traitement ------------------------------------------------------------
:traitement
echo Lancement du rapprochement par cle metier...
%PYEXE% rapprochement_cle_metier.py%ARGS%
set "RC=%errorlevel%"

echo.
if "%RC%"=="0" (
    echo Resultat : OK - tout est rapproche ou explique.
) else if "%RC%"=="1" (
    echo Resultat : ANOMALIES - consultez l'onglet Rapprochement, colonne Statut.
) else if "%RC%"=="3" (
    echo Resultat : EXECUTION DEGRADEE - resultat partiel, lisez les avertissements.
) else (
    echo Resultat : ERREUR DE TRAITEMENT ^(code %RC%^)
)

:fin
REM Laisser la fenetre ouverte pour un lancement en double-clic
if "%PAUSE_FIN%"=="1" pause
endlocal & exit /b %RC%
