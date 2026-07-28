@echo off
:: =====================================================================
:: Script pour lancer la fusion des fichiers CSV de prélèvements.
::
:: Ce script exécute le script Python 'fusionner_prelevements.py'
:: qui se trouve dans le même dossier.
::
:: Prérequis:
::   - Python 3 doit être installé et accessible via la commande 'python'.
:: =====================================================================

echo Lancement du script de fusion Python...
echo.

:: Se place dans le dossier où se trouve le .bat
cd /d "%~dp0"

:: Exécute le script Python
python fusionner_prelevements.py

:: Garde la fenêtre ouverte pour voir les messages
echo.
echo Appuyez sur une touche pour fermer cette fenetre.
pause > nul