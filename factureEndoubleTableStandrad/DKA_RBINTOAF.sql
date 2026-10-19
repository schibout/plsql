----------------------------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_PERIOD_GL_OPEN_ACCES_ID_v.vue
-- DESCRIPTION	    : Création de la vue DKA_PERIOD_GL_OPEN_ACCES_ID_V
--
-- AUTEUR           : B.Coudrier
-- DATE DE CREATION : 13/01/2014
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
 

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_PERIOD_GL_OPEN_ACCES_ID_V
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA_PERIOD_GL_OPEN_ACCES_ID_V
AS
SELECT DISTINCT v.* FROM (
SELECT gps.start_date,
       access_set_id,
       first_value(gps.period_name) over(PARTITION BY gps.period_name ORDER BY gps.start_date, gps.set_of_books_id) period_name,
       first_value(gps.set_of_books_id) over(PARTITION BY gps.period_name ORDER BY gps.start_date, gps.set_of_books_id) set_of_books_id
  FROM gl.gl_period_statuses           gps,
       gl.gl_access_set_assignments gasa,
       gl.gl_ledgers                gl
 WHERE gps.closing_status IN ('O')
   AND gps.ledger_id = gasa.ledger_id
   AND gps.application_id = 101
   AND gl.ledger_id = gasa.ledger_id
   AND gl.ledger_category_code = 'PRIMARY') v
   ORDER BY access_set_id, start_date;

SHOW ERROR

EXIT
