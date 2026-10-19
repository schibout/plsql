----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_IARPAFAC_ORIGIN_TAX_V.vue
-- DESCRIPTION	    : Création de la vue DKA_IARPAFAC_ORIGIN_TAX_V
--
-- AUTEUR           : Xavier Descamps (CGEY)
-- DATE DE CREATION : 20/01/2004
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_IARPAFAC_ORIGIN_TAX_V
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA_IARPAFAC_ORIGIN_TAX_V
(origin_tax_code,
 tax_rate,
 sob_id
)
AS
SELECT dsl.param1_value,
       dsl.return_value,
       periods.set_of_books_id
FROM dka_stransco_headers dsh,
     dka_stransco_lines dsl,
     (SELECT MIN (gps.end_date) gl_date, gps.set_of_books_id
      FROM gl_period_statuses gps
      WHERE 1=1
        AND gps.application_id = 222
        AND gps.closing_status = 'O'
        group by gps.set_of_books_id) periods
WHERE 1=1
  AND dsh.set_name = 'AP_TAX_RATE'
  AND dsl.set_id = dsh.set_id
  AND dsl.enable = 'Y'
  AND periods.gl_date BETWEEN NVL (dsl.start_date, periods.gl_date) AND NVL (dsl.end_date, periods.gl_date);

SHOW ERROR

EXIT
