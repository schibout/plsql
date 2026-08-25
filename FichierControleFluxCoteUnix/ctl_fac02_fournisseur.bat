@echo off
rem =========================================================================
rem ctl_fac02_fournisseur.bat - Controle complet du flux FAC02 FOURNISSEURS
rem
rem 1. Rapprochement du fichier SRC avec le fichier CTL (Python)
rem 2. Verification de l'integration des factures dans Oracle (PowerShell)
rem
rem Usage : ctl_fac02_fournisseur.bat [dossier_source ^| fichier_SRC] [fichier_CTL]
rem   - dossier en parametre : traite le fichier SRC le plus recent du dossier
rem   - fichier en parametre : traite ce fichier (CTL optionnel en 2e arg)
rem   - sans argument        : cherche le dossier SOURCE aux emplacements connus
rem
rem Codes retour : 0 = controles OK, 1 = erreur technique, 2 = anomalie/ecart
rem =========================================================================
setlocal
for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI\"
set "FICHIER_ENTREE=%~f1"
set "FICHIER_CTL=%~f2"
cd /d "%SCRIPT_DIR%"

rem --- Determiner le fichier SRC a controler ---
if not "%FICHIER_ENTREE%"=="" (
    if exist "%FICHIER_ENTREE%\" (
        set "DOSSIER_SOURCE=%FICHIER_ENTREE%"
        set "FICHIER_ENTREE="
        goto :chercher
    )
    goto :fichier_connu
)

rem --- Sans argument : emplacements connus ---
set "DOSSIER_SOURCE=%SCRIPT_DIR%SOURCE"
if not exist "%DOSSIER_SOURCE%\" set "DOSSIER_SOURCE=%SCRIPT_DIR%FAC02FACTURESFOURNISSEURS\SOURCE"
if not exist "%DOSSIER_SOURCE%\" set "DOSSIER_SOURCE=%SCRIPT_DIR%FichierControleFluxCoteUnix\FAC02FACTURESFOURNISSEURS\SOURCE"

:chercher
if not exist "%DOSSIER_SOURCE%\" (
    echo [ERREUR] Le dossier SOURCE "%DOSSIER_SOURCE%" est introuvable.
    echo          Passer un dossier ou un fichier SRC en parametre.
    exit /b 1
)

for /f "delims=" %%F in ('dir /b /a-d /o-d "%DOSSIER_SOURCE%\FAC02_SRC_FACTURESFOURNISSEURS*.csv" 2^>nul') do (
    set "FICHIER_ENTREE=%DOSSIER_SOURCE%\%%F"
    goto :fichier_connu
)
echo [ERREUR] Aucun fichier FAC02_SRC_FACTURESFOURNISSEURS*.csv dans "%DOSSIER_SOURCE%\".
exit /b 1

:fichier_connu
if not exist "%FICHIER_ENTREE%" (
    echo [ERREUR] Le fichier "%FICHIER_ENTREE%" est introuvable.
    exit /b 1
)

echo =======================================================================
echo Controle complet FAC02 FOURNISSEURS
echo Fichier SRC : %FICHIER_ENTREE%
if not "%FICHIER_CTL%"=="" echo Fichier CTL : %FICHIER_CTL%
echo =======================================================================
echo.

echo [1/2] Rapprochement SRC / CTL
echo -----------------------------------------------------------------------
if "%FICHIER_CTL%"=="" (
    python "%SCRIPT_DIR%ctl_fac02_fournisseur.py" "%FICHIER_ENTREE%"
) else (
    python "%SCRIPT_DIR%ctl_fac02_fournisseur.py" "%FICHIER_ENTREE%" "%FICHIER_CTL%"
)
set "RC_CTL=%ERRORLEVEL%"

echo.
echo [2/2] Verification dans Oracle EBS
echo -----------------------------------------------------------------------
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Verifier_Oracle_FAC02_Fournisseur.ps1" -CheminFichierSrc "%FICHIER_ENTREE%"
set "RC_ORACLE=%ERRORLEVEL%"

rem Une erreur technique est prioritaire sur une anomalie fonctionnelle.
set "RC_FINAL=0"
if "%RC_CTL%"=="1" set "RC_FINAL=2"
if not "%RC_CTL%"=="0" if not "%RC_CTL%"=="1" set "RC_FINAL=1"
if "%RC_ORACLE%"=="2" if not "%RC_FINAL%"=="1" set "RC_FINAL=2"
if not "%RC_ORACLE%"=="0" if not "%RC_ORACLE%"=="2" set "RC_FINAL=1"

echo.
echo =======================================================================
echo SYNTHESE DES CONTROLES
echo   Rapprochement SRC / CTL : code %RC_CTL%
echo   Verification Oracle    : code %RC_ORACLE%
echo -----------------------------------------------------------------------
if "%RC_FINAL%"=="0" (
    echo [OK] Rapprochement conforme et toutes les factures sont integrees.
) else if "%RC_FINAL%"=="1" (
    echo [ERREUR TECHNIQUE] Au moins un controle n'a pas pu aboutir.
) else (
    echo [ANOMALIES] Ecart SRC/CTL ou factures en interface, absentes ou en ecart.
)
echo =======================================================================
exit /b %RC_FINAL%
