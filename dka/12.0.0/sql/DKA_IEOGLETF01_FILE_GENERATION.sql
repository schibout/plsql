
----------------------------------------------------------------------------
------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM		         : DKA_IEOGLETF01_FILE_GENERATION.sql
-- DESCRIPTION	     : Etat spécifique de génération du fichier ETAFI
---
--- AUTEUR	         : Noujoud  AZIZ(CGEY)
--- DATE DE CREATION : 07/06/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
-- PARAMETRES       : 1 : entity traitée

------------------------------------------------------------------------------
------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------

----------------------------------------------------------------------------
----------------
SET VERIFY OFF
SET HEAD OFF
SET PAGESIZE 100
SET LINESIZE 135
-- SET NEWPAGE 0
SET FEEDBACK OFF


SET FEEDBACK ON
COLUMN LINE_TEXT FORMAT A123

--DEFINE cv_filler1 = '  ';
--DEFINE cv_filler2 = '    ';
--DEFINE cv_montant_vide = '000';

SELECT
DKA_IEOGLETF01_INT.local_account||nvl(DKA_IEOGLETF01_INT.partner_code,'0000')||'  '||
  rpad(DKA_IEOGLETF01_INT.description,25)||'    '||
  lpad('000',15)||'    '||
  lpad(sum(DKA_IEOGLETF01_INT.amount),15)||'    '||
  lpad('000',15)||'    '||
  lpad('000',15) LINE_TEXT
FROM
  DKA_IEOGLETF01_INT
  WHERE DKA_IEOGLETF01_INT.company_code='&&1'
GROUP BY
  DKA_IEOGLETF01_INT.local_account,
  DKA_IEOGLETF01_INT.description,
  DKA_IEOGLETF01_INT.partner_code
order BY DKA_IEOGLETF01_INT.local_account,DKA_IEOGLETF01_INT.partner_code;

EXIT;
