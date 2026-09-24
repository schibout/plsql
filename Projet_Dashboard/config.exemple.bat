@echo off
rem Copier en config.bat (non versionne) et renseigner. Memes variables que ControleMatinGenerique\config.ps1.
set ORA_USER=utilisateur
set ORA_PWD=motdepasse
set ORA_HOST=prdscanc1pdb03.dalkia.net
set ORA_PORT=1521
set ORA_SERVICE=ebs_PDBFINP1
rem Dossier synchronise avec le dossier Drive lu par le dashboard (Google Drive pour ordinateur).
set CSV_DIR=G:\Mon Drive\Dashboard_CSV
rem Optionnel : forcer le client (sinon sqlcl, sql puis sqlplus, le premier trouve).
rem set SQLPLUS=sqlplus
@REM  