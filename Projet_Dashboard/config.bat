rem $ORA_USER    = "aroux"
rem $ORA_PWD     = "GAERFTXF"
rem $ORA_HOST    = "prdscanc1pdb03.dalkia.net"
rem $ORA_PORT    = "1521"
rem $ORA_SERVICE = "ebs_PDBFINP1"
@echo off
rem Copier en config.bat (non versionne) et renseigner. Memes variables que ControleMatinGenerique\config.ps1.
set ORA_USER=aroux
set ORA_PWD=GAERFTXF
set ORA_HOST=prdscanc1pdb03.dalkia.net
set ORA_PORT=1521
set ORA_SERVICE=ebs_PDBFINP1
rem Dossier synchronise avec le dossier Drive lu par le dashboard (Google Drive pour ordinateur).
set CSV_DIR=C:\Dashboard_CSV
rem Optionnel : forcer le client (sinon sqlcl, sql puis sqlplus, le premier trouve).
set SQLPLUS=sqlplus
set ORACLE_HOME=C:\app\oracle\product\11.2.0\client_1
set PATH=%ORACLE_HOME%\bin;%PATH%
@REM  