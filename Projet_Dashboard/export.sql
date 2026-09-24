-- Enveloppe d'export CSV, appelee par export_csv.bat :
--   sqlplus -S -L <connexion> @sql\_export.sql <requete.sql> <sortie.csv>
-- Necessite SQL*Plus 12.2+ (SET MARKUP CSV).
WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR EXIT FAILURE
SET MARKUP CSV ON QUOTE ON
SET FEEDBACK OFF VERIFY OFF ECHO OFF TERMOUT OFF PAGESIZE 50000 TRIMSPOOL ON
DEFINE nb_jours_histo  = 3
DEFINE heure_fermeture = 19
DEFINE heure_ouverture = 7
SPOOL "&2"
@"&1"
SPOOL OFF
EXIT SUCCESS
