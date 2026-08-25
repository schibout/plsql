@echo off
rem =========================================================================
rem controle.bat - Point d'entree unique des controles de flux
rem
rem Detecte tous les fichiers SRC presents sous le dossier passe en parametre
rem (CLIENTS, FOURNISSEURS, ECRITURES GL) et lance un controle par fichier.
rem Un dossier parent contenant plusieurs exports est donc controle en entier.
rem Il n'y a plus a savoir quel lanceur appeler : ce script s'en charge.
rem
rem Usage : controle.bat [dossier_export ^| fichier_SRC] [fichier_CTL]
rem   - dossier en parametre : detecte les fichiers SRC et les controle tous
rem   - fichier en parametre : controle le flux de ce fichier (dans SOURCE)
rem   - sans argument        : cherche recursivement sous le dossier du lanceur
rem   - fichier_CTL          : accepte uniquement si un seul SRC est detecte
rem
rem Codes retour : 0 = controles OK, 1 = erreur technique, 2 = anomalie/ecart
rem =========================================================================
setlocal enabledelayedexpansion
for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI\"
set "FICHIER_ENTREE=%~f1"
set "FICHIER_CTL=%~f2"
cd /d "%SCRIPT_DIR%"

if "%FICHIER_ENTREE%"=="" set "FICHIER_ENTREE=%SCRIPT_DIR%"

rem Une ligne "TYPE;chemin" par fichier SRC detecte.
set "NB_FLUX=0"
for /f "usebackq tokens=1,* delims=;" %%A in (`python "%SCRIPT_DIR%selectionner_source.py" --detecter "%FICHIER_ENTREE%"`) do (
    set /a NB_FLUX+=1
    set "TYPE_!NB_FLUX!=%%A"
    set "SRC_!NB_FLUX!=%%B"
)

if "%NB_FLUX%"=="0" (
    echo [ERREUR] Aucun flux CLIENT, FOURNISSEUR ou GL trouve sous :
    echo          %FICHIER_ENTREE%
    exit /b 1
)
if not "%FICHIER_CTL%"=="" if not "%NB_FLUX%"=="1" (
    echo [ERREUR] %NB_FLUX% fichiers SRC detectes : un fichier CTL ne peut pas
    echo          etre impose. Relancez en ciblant un seul export.
    exit /b 1
)
set "FICHIER_CTL_ARG="
if not "%FICHIER_CTL%"=="" set "FICHIER_CTL_ARG="%FICHIER_CTL%""

echo =======================================================================
echo Controle des flux
echo Dossier : %FICHIER_ENTREE%
echo Fichiers SRC detectes : %NB_FLUX%
echo =======================================================================

set "RC_FINAL=0"
for /l %%N in (1,1,%NB_FLUX%) do (
    echo.
    echo #######################################################################
    echo # FLUX !TYPE_%%N! ^(%%N/%NB_FLUX%^)
    echo # SRC : !SRC_%%N!
    echo #######################################################################
    call :controler "!TYPE_%%N!" "!SRC_%%N!"
    rem Une erreur technique est prioritaire sur une anomalie fonctionnelle.
    if "!ERRORLEVEL!"=="1" set "RC_FINAL=1"
    if "!ERRORLEVEL!"=="2" if not "!RC_FINAL!"=="1" set "RC_FINAL=2"
)

echo.
echo =======================================================================
echo SYNTHESE GENERALE
echo   Fichiers SRC controles : %NB_FLUX%
echo -----------------------------------------------------------------------
if "%RC_FINAL%"=="0" (
    echo [OK] Tous les flux controles sont conformes.
) else if "%RC_FINAL%"=="1" (
    echo [ERREUR TECHNIQUE] Au moins un controle n'a pas pu aboutir.
) else (
    echo [ANOMALIES] Au moins un flux presente un ecart ou une anomalie.
)
echo =======================================================================
exit /b %RC_FINAL%

rem -------------------------------------------------------------------------
rem :controler <TYPE> <chemin SRC> - delegue au lanceur du flux
rem -------------------------------------------------------------------------
:controler
set "TYPE_FLUX=%~1"
set "SRC=%~2"
set "LANCEUR="
if /i "%TYPE_FLUX%"=="CLIENT"      set "LANCEUR=controleClient.bat"
if /i "%TYPE_FLUX%"=="FOURNISSEUR" set "LANCEUR=controleFournisseur.bat"
if /i "%TYPE_FLUX%"=="GL"          set "LANCEUR=controleGL.bat"
if not defined LANCEUR (
    echo [ERREUR] Type de flux inconnu : %TYPE_FLUX%
    exit /b 1
)
call "%SCRIPT_DIR%%LANCEUR%" "%SRC%" %FICHIER_CTL_ARG%
exit /b %ERRORLEVEL%
