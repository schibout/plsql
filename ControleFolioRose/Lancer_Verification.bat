@echo off
:: Lanceur - Vérification des factures Oracle EBS avec paramètre dynamique
:: Aller dans le dossier où se trouve le script .bat
cd /d "%~dp0"

:: Vérifier si l'utilisateur a bien fourni un nom de fichier (en paramètre ou via glisser-déposer)
if "%~1" == "" (
    echo [ERREUR] Veuillez preciser le nom du fichier CSV ou glisser-deposer le fichier sur ce .bat.
    echo.
    echo Exemple d'utilisation :
    echo Lancer_Verification.bat ExportCSV-01-06-2026.csv
    echo Lancer_Verification.bat ExportCSV-01-06-2026.csv /SANSORACLE
    echo.
    pause
    exit /b
)

:: Récupération du nom ou du chemin du fichier passé en premier paramètre (%1)
set "FICHIER_ENTREE=%~1"

:: Second parametre optionnel : /SANSORACLE sur un poste sans acces a la base.
:: Le rapport est produit a partir du seul fichier d'entree, sans reconciliation.
set "OPT_PS="
if /I "%~2" == "/SANSORACLE" set "OPT_PS=-SansOracle"

:: Étape de vérification : on regarde si le fichier est dans le même répertoire ou si c'est un chemin complet
if exist "%FICHIER_ENTREE%" (
    set "CHEMIN_COMPLET=%FICHIER_ENTREE%"
) else if exist "%~dp0%FICHIER_ENTREE%" (
    set "CHEMIN_COMPLET=%~dp0%FICHIER_ENTREE%"
) else (
    echo [ERREUR] Le fichier "%FICHIER_ENTREE%" est introuvable dans le repertoire.
    echo.
    pause
    exit /b
)

echo =======================================================================
echo Lancement du controle avec le fichier : %FICHIER_ENTREE%
echo =======================================================================
echo.

:: Appel du script PowerShell avec le bon chemin de fichier
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Verifier_Factures.ps1" -CheminFichierCsv "%CHEMIN_COMPLET%" %OPT_PS%

:: Codes retour : 0 = tout concorde, 1 = erreur technique, 2 = ecarts constates
set RC=%ERRORLEVEL%
echo.
if %RC% EQU 1 (
    echo [ERREUR TECHNIQUE] Le controle n'a pas pu aboutir - aucun rapport fiable produit.
) else if %RC% EQU 2 (
    echo [ECARTS] Des lignes sont en ecart ou indeterminees - voir le rapport CSV.
) else if defined OPT_PS (
    echo [INFO] Mode SANS ORACLE - rapport produit sans reconciliation.
) else (
    echo [OK] Toutes les lignes concordent.
)

echo.
echo Controle termine.
pause
exit /b %RC%