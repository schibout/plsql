CREATE OR REPLACE PACKAGE DKA_SAPVIR_MAIL_PKG AS
    ------------------------------------------------------------------------------------------
    -- $$
    -- CAPGEMINI
    -- PROJET            : DALKIA Oracle Applications
    -- NOM               : DKA_SAPVIR_MAIL_PKG.pkb
    -- DESCRIPTION       : Spec du package DKA_SAPVIR_MAIL_PKG :
    --
    -- AUTEUR           : CAPGEMINI
    -- DATE DE CREATION : 12/08/2013
    -- DOC. ASSOCIEE    :
    -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
    ------------------------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- ---------- --- ------------------------------------------------------------------------
    -- 14/03/2017 YWA artf2120398
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PRIVEES
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    ----------------------------------------------------------------------------
    --  Nom           : main
    --  Description   : procédure principale du stockage des bons de commande
    --
    --
    --  PARAMETRES :
    --    pn_request_id  Entrée      Numéro du traitement "VE : Création du fichier avis de virement"
    --    pv_errbuf     Entrée/Sortie   Message d'erreur
    --    pn_retcode  Sortie      Code d'erreur
    --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
    ----------------------------------------------------------------------------

    PROCEDURE main(pv_errbuf              IN OUT VARCHAR2,
                   pn_retcode             OUT NUMBER,
                   pv_mail_test IN       VARCHAR2);

END DKA_SAPVIR_MAIL_PKG;

/
SHOW ERRORS

EXIT
