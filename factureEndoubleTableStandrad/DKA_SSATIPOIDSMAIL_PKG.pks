CREATE OR REPLACE PACKAGE DKA_SAPVIR_ATTACH_PKG AS
    ------------------------------------------------------------------------------------------
    -- $$
    -- CAPGEMINI
    -- PROJET            : DALKIA Oracle Applications
    -- NOM               : DKA_SAPVIR_ATTACH_PKG.pkb
    -- DESCRIPTION       : DKA_SAPVIR_ATTACH_PKG package body :
    --
    -- AUTEUR           : CAPGEMINI
    -- DATE DE CREATION : 19/08/2013
    -- DOC. ASSOCIEE    :
    -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
    ------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------
    --  Nom           : main
    --  Description   : procédure principale du stockage des avis de virement
    --
    --
    --  PARAMETRES :
    --    pv_errbuf       Entrée/Sortie           message d'erreur
    --    VALEUR RETOURNEE :  pn_retcode
    --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
    ----------------------------------------------------------------------------

    PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER);

END DKA_SAPVIR_ATTACH_PKG;
/

SHOW ERROR

EXIT
