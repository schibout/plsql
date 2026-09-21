@echo off
rem Lanceur historique conserve pour les habitudes : il appelle desormais le rapprochement par cle metier
rem (plus de PowerShell ni d'Excel COM). Options : voir rapprochement_cle_metier.bat.
call "%~dp0rapprochement_cle_metier.bat" %*
