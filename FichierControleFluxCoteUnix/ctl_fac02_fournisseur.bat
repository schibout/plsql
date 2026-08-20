@echo off
rem =========================================================================
rem ctl_fac02_fournisseur.bat - Lance le controle Python du flux FAC02
rem                             factures FOURNISSEURS
rem Usage : ctl_fac02_fournisseur.bat [dossier_source ^| fichier_SRC] [fichier_CTL]
rem   - dossier en parametre : traite le fichier SRC le plus recent du dossier
rem   - fichier en parametre : traite ce fichier (CTL optionnel en 2e arg)
rem   - sans argument        : cherche le dossier SOURCE aux emplacements connus
rem =========================================================================
setlocal
set SCRIPT_DIR=%~dp0

rem --- Determiner le dossier source ---
if not "%~1"=="" (
    if exist "%~1\" (
        rem Le 1er parametre est un dossier
        set "DOSSIER_SOURCE=%~1"
        goto :chercher
    )
    rem Le 1er parametre est un fichier : appel direct
    python "%SCRIPT_DIR%ctl_fac02_fournisseur.py" %*
    exit /b
)

rem --- Sans argument : emplacements connus ---
set "DOSSIER_SOURCE=%SCRIPT_DIR%SOURCE"
if not exist "%DOSSIER_SOURCE%" set "DOSSIER_SOURCE=%SCRIPT_DIR%FAC02FACTURESFOURNISSEURS\SOURCE"
if not exist "%DOSSIER_SOURCE%" set "DOSSIER_SOURCE=%SCRIPT_DIR%FichierControleFluxCoteUnix\FAC02FACTURESFOURNISSEURS\SOURCE"
if not exist "%DOSSIER_SOURCE%" (
    echo ERREUR : aucun dossier SOURCE trouve. Passer le dossier en parametre :
    echo   ctl_fac02_fournisseur.bat chemin\vers\dossier
    exit /b 2
)

:chercher
rem --- Fichier SRC le plus recent du dossier ---
for /f "delims=" %%F in ('dir /b /o-d "%DOSSIER_SOURCE%\FAC02_SRC_FACTURESFOURNISSEURS*.csv" 2^>nul') do (
    python "%SCRIPT_DIR%ctl_fac02_fournisseur.py" "%DOSSIER_SOURCE%\%%F"
    exit /b
)
echo ERREUR : aucun fichier FAC02_SRC_FACTURESFOURNISSEURS*.csv dans %DOSSIER_SOURCE%\
exit /b 2
