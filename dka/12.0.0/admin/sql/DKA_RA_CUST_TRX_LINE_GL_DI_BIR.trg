/* Formatted on 03/11/2002 16:18 (Formatter Plus v4.5.2) */
----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_RA_CUST_TRX_LINE_GL_DI_BIR.trg
-- DESCRIPTION       : Trigger sur la table RA_CUST_TRX_LINE_GL_DIST_ALL
---
--- AUTEUR           : Xavier Descamps (CGEY)
--- DATE DE CREATION : 15/03/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
---
--------------------------------------------------------------------------------------------


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU TRIGGER DKA_RA_CUST_TRX_LINE_GL_DI_BIR
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE TRIGGER dka_ra_cust_trx_line_gl_di_bir
    BEFORE INSERT
    ON ar.ra_cust_trx_line_gl_dist_all
    FOR EACH ROW
    WHEN (    NEW.attribute1 IS NOT NULL
          AND NEW.attribute5 IS NOT NULL
         )
DECLARE
    e_error   EXCEPTION;
    Mutating_table      EXCEPTION;
    PRAGMA EXCEPTION_INIT (Mutating_table, -4091);
BEGIN
    -- Pour le cas de contrepassation ou split de dépense
    :NEW.attribute5    := NULL;
EXCEPTION
    WHEN e_error
    THEN
        app_exception.raise_exception;
    WHEN Mutating_table THEN
        NULL;
END;
/

SHOW ERROR
EXIT;
