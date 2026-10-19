CREATE OR REPLACE PACKAGE dka_sglreflettrage_pkg IS

     -- -----------------------------------------------------------------------------
     -- $$
     -- Capgemini
     -- PROJET           : DALKIA Oracle Applications
     -- NOM              : DKA_SGLREFLETTRAGE.pkb
     -- DESCRIPTION      : DKA_SGLREFLETTRAGE Package Specifications
     --
     -- AUTEUR           : C.DEFAUX  (Capgemini)
     -- DATE DE CREATION : 23/02/2012
     -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
     -- -----------------------------------------------------------------------------
     --
     -- -----------------------------------------------------------------------------
     -- HISTORIQUE DES MODIFICATIONS
     -- Date       Qui Description
     -- ---------- --- --------------------------------------------------------------
     --
     -- -----------------------------------------------------------------------------

     -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     -- FONCTIONS ET PROCEDURES PRIVEES
     -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

     PROCEDURE main(pv_errbuf  OUT VARCHAR2,
                    pn_retcode OUT NUMBER,
                    pv_societe IN VARCHAR2,
                    pv_uo  IN VARCHAR2,
                    pv_periode IN VARCHAR2,
                    pv_folio   IN VARCHAR2);

END dka_sglreflettrage_pkg;
/

SHOW ERRORS;

EXIT