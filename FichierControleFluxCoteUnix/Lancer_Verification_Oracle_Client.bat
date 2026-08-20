@echo off
:: Lanceur - Verification des factures FAC02 CLIENTS dans Oracle EBS
:: Usage : Lancer_Verification_Oracle_Client.bat [dossier_source ^| fichier_SRC]
::   - dossier en parametre : traite le fichier SRC le plus recent du dossier
::   - fichier en parametre : traite ce fichier (glisser-deposer possible)
::   - sans argument        : cherche le dossier SOURCE aux emplacements connus
cd /d "%~dp0"

set "FICHIER_ENTREE=%~1"

if not "%FICHIER_ENTREE%" == "" if not exist "%FICHIER_ENTREE%\" goto :fichier_connu

if not "%FICHIER_ENTREE%" == "" (
    rem Le parametre est un dossier
    set "DOSSIER_SOURCE=%FICHIER_ENTREE%"
    set "FICHIER_ENTREE="
) else (
    set "DOSSIER_SOURCE=SOURCE"
)
if not exist "%DOSSIER_SOURCE%" set "DOSSIER_SOURCE=FAC02factureClient\SOURCE"
if not exist "%DOSSIER_SOURCE%" set "DOSSIER_SOURCE=FichierControleFluxCoteUnix\FAC02factureClient\SOURCE"

for /f "delims=" %%F in ('dir /b /o-d "%DOSSIER_SOURCE%\FAC02_SRC_*.csv" 2^>nul') do (
    set "FICHIER_ENTREE=%DOSSIER_SOURCE%\%%F"
    goto :fichier_connu
)
echo [ERREUR] Aucun fichier FAC02_SRC_*.csv dans %DOSSIER_SOURCE%\
pause
exit /b 1

:fichier_connu

if not exist "%FICHIER_ENTREE%" (
    echo [ERREUR] Le fichier "%FICHIER_ENTREE%" est introuvable.
    pause
    exit /b 1
)

echo =======================================================================
echo Verification Oracle avec le fichier : %FICHIER_ENTREE%
echo =======================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Verifier_Oracle_FAC02_Client.ps1" -CheminFichierSrc "%FICHIER_ENTREE%"

:: Codes retour : 0 = tout integre, 1 = erreur technique, 2 = anomalies
set RC=%ERRORLEVEL%
echo.
if %RC% EQU 1 (
    echo [ERREUR TECHNIQUE] Le controle n'a pas pu aboutir.
) else if %RC% EQU 2 (
    echo [ANOMALIES] Des factures sont en interface, absentes ou en ecart - voir le rapport CSV.
) else (
    echo [OK] Toutes les factures sont integrees dans Oracle.
)

echo.
echo Controle termine.
pause
exit /b %RC%
