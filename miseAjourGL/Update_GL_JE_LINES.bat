@ECHO OFF
SETLOCAL
TITLE Correction ATTRIBUTE13 GL_JE_LINES
CD /D "%~dp0"

:: =====================================================================
::  Usage :
::     Update_GL_JE_LINES.bat                    -> SIMULATION
::     Update_GL_JE_LINES.bat EXEC               -> application reelle
::     Update_GL_JE_LINES.bat autre_lot.csv      -> SIMULATION sur ce CSV
::     Update_GL_JE_LINES.bat autre_lot.csv EXEC -> application sur ce CSV
::
::  Sans le mot-cle EXEC, l'UPDATE est joue puis annule : on voit
::  l'ancienne et la nouvelle valeur de chaque ligne, sans rien conserver.
::
::  Le perimetre vient du CSV (par defaut lignes_a_corriger.csv), au
::  format JE_HEADER_ID;JE_LINE_NUM, une ligne par correction.
:: =====================================================================

SET "FICHIER=lignes_a_corriger.csv"
SET "MODE="

IF /I "%~1"=="EXEC" (
    SET "MODE=-Executer"
) ELSE IF NOT "%~1"=="" (
    SET "FICHIER=%~1"
    IF /I "%~2"=="EXEC" SET "MODE=-Executer"
)

ECHO.
ECHO =====================================================================
ECHO   CORRECTION ATTRIBUTE13 - GL_JE_LINES
ECHO   Fichier : %FICHIER%
ECHO   Date    : %DATE% %TIME%
ECHO =====================================================================

IF DEFINED MODE (
    ECHO   *** MODE EXECUTION REELLE ***
) ELSE (
    ECHO   Mode SIMULATION - pour appliquer : ajouter EXEC en parametre
)
ECHO.

PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update_GL_JE_LINES.ps1" -Csv "%FICHIER%" %MODE%

SET RC=%ERRORLEVEL%
IF %RC% EQU 1 (
    ECHO.
    ECHO [ERREUR] Erreur technique - aucune modification conservee.
) ELSE IF %RC% EQU 2 (
    ECHO.
    ECHO [ECART] Des couples du CSV sont introuvables - rien n'a ete conserve.
) ELSE IF %RC% EQU 3 (
    ECHO.
    ECHO [ANNULE] Operation annulee par l'utilisateur.
)

ECHO.
PAUSE
EXIT /B %RC%
