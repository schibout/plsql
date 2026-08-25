@echo off
rem =========================================================================
rem controleClient.bat - Controle complet du flux CLIENTS
rem
rem 1. Controle du statut Talend (marqueur LS_IN.OK/KO + erreurs de formatage)
rem 2. Rapprochement du fichier SRC avec le fichier CTL (Python)
rem 3. Verification de l'integration des factures dans Oracle (PowerShell)
rem
rem Usage : controleClient.bat [dossier_export ^| fichier_SRC] [fichier_CTL]
rem   - dossier en parametre : descend jusqu'a SOURCE et prend le SRC le plus recent
rem   - fichier en parametre : accepte tout prefixe, mais le fichier doit etre dans SOURCE
rem   - sans argument        : cherche recursivement sous le dossier du lanceur
rem
rem Codes retour : 0 = controles OK, 1 = erreur technique, 2 = anomalie/ecart
rem =========================================================================
setlocal
for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI\"
set "FICHIER_ENTREE=%~f1"
set "FICHIER_CTL=%~f2"
cd /d "%SCRIPT_DIR%"

if "%FICHIER_ENTREE%"=="" set "FICHIER_ENTREE=%SCRIPT_DIR%"
set "SOURCE_SELECTIONNEE="
for /f "usebackq delims=" %%F in (`python "%SCRIPT_DIR%selectionner_source.py" CLIENT "%FICHIER_ENTREE%"`) do set "SOURCE_SELECTIONNEE=%%F"
if not defined SOURCE_SELECTIONNEE (
    echo [ERREUR] Aucun fichier SRC CLIENT valide n'a ete selectionne.
    exit /b 1
)
set "FICHIER_ENTREE=%SOURCE_SELECTIONNEE%"

echo =======================================================================
echo Controle complet CLIENTS
echo Fichier SRC : %FICHIER_ENTREE%
if not "%FICHIER_CTL%"=="" echo Fichier CTL : %FICHIER_CTL%
echo =======================================================================
echo.

echo [1/3] Controle du statut Talend
echo -----------------------------------------------------------------------
python "%SCRIPT_DIR%controle_talend.py" "%FICHIER_ENTREE%"
set "RC_TALEND=%ERRORLEVEL%"

echo.
echo [2/3] Rapprochement SRC / CTL
echo -----------------------------------------------------------------------
if "%FICHIER_CTL%"=="" (
    python "%SCRIPT_DIR%ctl_fac02.py" "%FICHIER_ENTREE%"
) else (
    python "%SCRIPT_DIR%ctl_fac02.py" "%FICHIER_ENTREE%" "%FICHIER_CTL%"
)
set "RC_CTL=%ERRORLEVEL%"

echo.
echo [3/3] Verification dans Oracle EBS
echo -----------------------------------------------------------------------
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Verifier_Oracle_FAC02_Client.ps1" -CheminFichierSrc "%FICHIER_ENTREE%"
set "RC_ORACLE=%ERRORLEVEL%"

rem Une erreur technique est prioritaire sur une anomalie fonctionnelle.
set "RC_FINAL=0"
if "%RC_TALEND%"=="1" set "RC_FINAL=2"
if not "%RC_TALEND%"=="0" if not "%RC_TALEND%"=="1" set "RC_FINAL=1"
if "%RC_CTL%"=="1" if not "%RC_FINAL%"=="1" set "RC_FINAL=2"
if not "%RC_CTL%"=="0" if not "%RC_CTL%"=="1" set "RC_FINAL=1"
if "%RC_ORACLE%"=="2" if not "%RC_FINAL%"=="1" set "RC_FINAL=2"
if not "%RC_ORACLE%"=="0" if not "%RC_ORACLE%"=="2" set "RC_FINAL=1"

echo.
echo =======================================================================
echo SYNTHESE DES CONTROLES
echo   Statut Talend          : code %RC_TALEND%
echo   Rapprochement SRC / CTL : code %RC_CTL%
echo   Verification Oracle    : code %RC_ORACLE%
echo -----------------------------------------------------------------------
if "%RC_FINAL%"=="0" (
    echo [OK] Talend OK, rapprochement conforme et toutes les factures sont integrees.
) else if "%RC_FINAL%"=="1" (
    echo [ERREUR TECHNIQUE] Au moins un controle n'a pas pu aboutir.
) else (
    echo [ANOMALIES] Erreur de formatage Talend, ecart SRC/CTL ou factures
    echo             en interface, absentes ou en ecart.
)
echo =======================================================================
exit /b %RC_FINAL%
