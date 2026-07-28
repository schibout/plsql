@echo off
:: Lanceur generique - Execution de scripts SQL Oracle EBS
:: Usage : Lancer_SQL.bat <chemin_du_fichier.sql> [nom_personne]
:: Exemple : Lancer_SQL.bat verification_user.sql "Dupont"
:: Exemple : Lancer_SQL.bat verification_user.sql "Marie%"  (% = joker SQL)

cd /d "%~dp0"

if "%~1"=="" (
    echo.
    echo Usage : Lancer_SQL.bat ^<fichier.sql^> [nom_personne]
    echo.
    echo Exemples :
    echo    Lancer_SQL.bat verification_user.sql "Dupont"
    echo    Lancer_SQL.bat verification_user.sql "Marie%%"   (double %% = joker SQL)
    echo.
    pause
    exit /b 1
)

if "%~2"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Lancer_SQL.ps1" -SqlFile "%~1" -HTML
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Lancer_SQL.ps1" -SqlFile "%~1" -BindVars "NOM_PERSONNE=%%%~2%%" -HTML
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] Le script a echoue avec le code : %ERRORLEVEL%
    pause
)
