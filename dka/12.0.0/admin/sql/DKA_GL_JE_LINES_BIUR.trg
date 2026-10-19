/* Formatted on 03/11/2002 16:18 (Formatter Plus v4.5.2) */
----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_GL_JE_LINES_BIUR.trg
-- DESCRIPTION       : Trigger sur la table GL_JE_LINES
---
--- AUTEUR           : Xavier Descamps (CGEY)
--- DATE DE CREATION : 21/05/2003
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
---
--------------------------------------------------------------------------------------------


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU TRIGGER DKA_GL_JE_LINES_BIUR
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE TRIGGER dka_gl_je_lines_biur
    BEFORE INSERT OR UPDATE
    ON gl.gl_je_lines
    FOR EACH ROW
    WHEN (    NEW.attribute14 IS NOT NULL
          AND NEW.attribute14 LIKE '%,%'
         )
DECLARE
    e_error   EXCEPTION;
BEGIN
    -- Trigger pour remplacer les , par des . afin de ne pas avoir de problème lors du transfert vers PA
    -- Composant : SPACUTOFF
    :NEW.attribute14    := REPLACE (:NEW.attribute14, ',', '.');

EXCEPTION
    WHEN e_error
    THEN
        app_exception.raise_exception;
    WHEN OTHERS
    THEN
        app_exception.raise_exception;
END;
/

SHOW ERROR
EXIT;
