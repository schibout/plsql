@echo off
rem =========================================================================
rem controleGL.bat - Controle du flux d'ecritures GL
rem Usage : controleGL.bat [dossier_export ^| fichier_SRC] [fichier_CTL]
rem   - dossier en parametre : descend jusqu'a SOURCE et prend le SRC le plus recent
rem   - fichier en parametre : accepte tout prefixe, mais le fichier doit etre dans SOURCE
rem   - sans argument        : cherche recursivement sous le dossier du lanceur
rem Codes retour : 0 = controle OK, 1 = erreur technique, 2 = anomalie/ecart
rem =========================================================================
setlocal
for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI\"
set "FICHIER_ENTREE=%~f1"
set "FICHIER_CTL=%~f2"

if "%FICHIER_ENTREE%"=="" set "FICHIER_ENTREE=%SCRIPT_DIR%"
set "SOURCE_SELECTIONNEE="
for /f "usebackq delims=" %%F in (`python "%SCRIPT_DIR%selectionner_source.py" GL "%FICHIER_ENTREE%"`) do set "SOURCE_SELECTIONNEE=%%F"
if not defined SOURCE_SELECTIONNEE (
    echo [ERREUR] Aucun fichier SRC GL valide n'a ete selectionne.
    exit /b 1
)

python "%SCRIPT_DIR%controle_talend.py" "%SOURCE_SELECTIONNEE%"
set "RC_TALEND=%ERRORLEVEL%"
if not "%RC_TALEND%"=="0" if not "%RC_TALEND%"=="1" exit /b 1

if "%FICHIER_CTL%"=="" (
    python "%SCRIPT_DIR%ctl_ecritures_gl.py" "%SOURCE_SELECTIONNEE%"
) else (
    python "%SCRIPT_DIR%ctl_ecritures_gl.py" "%SOURCE_SELECTIONNEE%" "%FICHIER_CTL%"
)
set "RC_LOCAL=%ERRORLEVEL%"

if "%RC_LOCAL%"=="1" exit /b 1

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Verifier_Oracle_Ecritures_GL.ps1" -CheminFichierSrc "%SOURCE_SELECTIONNEE%"
set "RC_ORACLE=%ERRORLEVEL%"

if "%RC_ORACLE%"=="1" exit /b 1
if "%RC_TALEND%"=="1" exit /b 2
if "%RC_LOCAL%"=="2" exit /b 2
if "%RC_ORACLE%"=="2" exit /b 2
exit /b 0
