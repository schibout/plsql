@echo off
rem Copier en config.bat (non versionne) et renseigner.
rem ORA_CONN : utilisateur/motdepasse@//hote:port/service
set ORA_CONN=utilisateur/motdepasse@//prdscanc1pdb03.dalkia.net:1521/ebs_PDBFINP1
rem CSV_DIR : dossier synchronise avec le dossier Drive lu par le dashboard (Google Drive pour ordinateur).
set CSV_DIR=G:\Mon Drive\Dashboard_CSV
rem Client : sqlplus (12.2+) dans le PATH, sinon chemin complet.
set SQLPLUS=sqlplus
