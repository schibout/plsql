CREATE OR REPLACE PACKAGE DKA_SFACLOTURE_PKG AS
---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SFACLOTURE_PKG
-- DESCRIPTION       : Traitement de la cloture des périodes FA
---
--- AUTEUR           : Guillaume Chabrier
--- DATE DE CREATION : 30/05/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--09/07/02 Mohame Si-Fodil  Fusion des packages DKA_SFACLOTURE_PKG et DKA_SFACLOFISC_PKG
--        Ajout d'un nouveau paramètre en entrée "vv_book_type_code".
-- 03/05/2013 BCO DPE20120028 - Sécurisation de la clôture FA - Ajout du paramètre "Période à fermer"
--                    pour ne sélectionner que les livres dont la période en cour correspond
--                 à la période FA en paramètre du traitement.
-- 05/10/2016 RGH Migration R12
---------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Procédure qui enchaine le reste des procedures
--
--  PARAMETRES    :vv_book_class
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE main (pv_errbuf      IN OUT VARCHAR2,
                pn_retcode     OUT NUMBER,
                pv_book_class  IN VARCHAR2,
                pv_period_name IN VARCHAR2,
                pn_sob         IN NUMBER);

---------------------------------------------------------------------------------------------------------------
END DKA_SFACLOTURE_PKG; -- Spécification du package
/
SHOW ERRORS;
EXIT;
