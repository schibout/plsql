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
    echo.
    pause
    exit /b
)

:: Récupération du nom ou du chemin du fichier passé en premier paramètre (%1)
set "FICHIER_ENTREE=%~1"

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
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Verifier_Factures.ps1" -CheminFichierCsv "%CHEMIN_COMPLET%"

:: Garder la fenêtre ouverte pour voir le résultat OK/KO
echo.
echo Controle termine.
pause