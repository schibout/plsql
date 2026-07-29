@ECHO OFF
SETLOCAL
TITLE Doublons Open Interface AR - rapport et suppression
CD /D "%~dp0"

:: =====================================================================
::  Usage :
::     Suppression_Doublons.bat            -> rapport + SIMULATION
::     Suppression_Doublons.bat RAPPORT    -> rapport seul, aucune purge
::     Suppression_Doublons.bat EXEC       -> rapport + suppression reelle
::     Suppression_Doublons.bat 348        -> limite a l'ORG_ID 348
::     Suppression_Doublons.bat 348 EXEC   -> ORG_ID 348, suppression reelle
::
::  Dans tous les cas, le rapport complet est produit AVANT toute
::  suppression : un HTML et un CSV listant chaque enregistrement qui
::  partirait, dans les quatre tables concernees. Le HTML s'ouvre
::  automatiquement.
::
::  Sans le mot-cle EXEC, les DELETE sont joues puis annules : on voit
::  exactement ce qui partirait, sans rien conserver.
::
::  Le message d'erreur EBS est traduit selon la langue de la session.
::  En session anglaise, lancer le PowerShell directement :
::     PowerShell -File Suppression_Doublons.ps1 -Motif "%%duplicate invoice%%"
:: =====================================================================

SET "ORGID=0"
SET "MODE="
SET "LIBELLE=SIMULATION"

:PARAM
IF "%~1"=="" GOTO FINPARAM
IF /I "%~1"=="EXEC" (
    SET "MODE=-Executer"
    SET "LIBELLE=EXECUTION REELLE"
) ELSE IF /I "%~1"=="RAPPORT" (
    SET "MODE=-RapportSeul"
    SET "LIBELLE=RAPPORT SEUL"
) ELSE (
    SET "ORGID=%~1"
)
SHIFT
GOTO PARAM
:FINPARAM

:: Tout parametre qui n'est ni EXEC ni RAPPORT est pris pour un ORG_ID.
:: Une faute de frappe deviendrait donc un perimetre, mieux vaut la
:: refuser ici que de la laisser filer jusqu'a Oracle.
ECHO %ORGID%| FINDSTR /R /C:"^[0-9][0-9]*$" >NUL
IF ERRORLEVEL 1 (
    ECHO.
    ECHO [ERREUR] Parametre non reconnu : "%ORGID%"
    ECHO          Attendu : un ORG_ID numerique, EXEC ou RAPPORT.
    ECHO.
    PAUSE
    EXIT /B 1
)

ECHO.
ECHO =====================================================================
ECHO   DOUBLONS OPEN INTERFACE AR
ECHO   Organisation : %ORGID%   (0 = toutes)
ECHO   Mode         : %LIBELLE%
ECHO   Date         : %DATE% %TIME%
ECHO =====================================================================

IF /I "%LIBELLE%"=="EXECUTION REELLE" (
    ECHO   *** SUPPRESSION DEFINITIVE - confirmation demandee apres le rapport ***
) ELSE IF /I "%LIBELLE%"=="RAPPORT SEUL" (
    ECHO   Aucune suppression ne sera tentee.
) ELSE (
    ECHO   Mode SIMULATION - pour supprimer : ajouter EXEC en parametre
)
ECHO.

PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Suppression_Doublons.ps1" -OrgId %ORGID% %MODE%

SET RC=%ERRORLEVEL%
IF %RC% EQU 1 (
    ECHO.
    ECHO [ERREUR] Erreur technique - aucune suppression conservee.
) ELSE IF %RC% EQU 2 (
    ECHO.
    ECHO [ECART] Perimetre hors plafond ou orphelins detectes - voir le rapport.
) ELSE IF %RC% EQU 3 (
    ECHO.
    ECHO [ANNULE] Operation annulee par l'utilisateur.
)

ECHO.
PAUSE
EXIT /B %RC%
