CREATE OR REPLACE PACKAGE DKA_SCTRLMODULE_PKG IS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_SCTRLMODULE_PKG.pkb
    -- DESCRIPTION      : DKA_SCTRLMODULE_PKG Package Body
    --
    -- AUTEUR           : Coudrier Benjamin (Capgemini)
    -- DATE DE CREATION : 06/06/2013
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
    -------------------------------------------------------------------------------------
    --  Nom           : recherche_mail
    --  Description   : Procédure principale du traitement "VE : Envoi par mail des fichiers de contrôle de pré-clôture".
    --
    --  PARAMETRES    :
    --  Pv_Errbuf      IN OUT       Message d'avertissement
    --  Pn_Retcode  IN OUT     Code erreur
    --  P_Req_Id    IN       Numéro de requête
    --------------------------------------------------------------------------------------
    PROCEDURE envoi_mail(Pv_Errbuf  IN OUT VARCHAR2,
                         Pn_Retcode IN OUT NUMBER,
                         P_Req_Id   IN NUMBER);

    -------------------------------------------------------------------------------------
    --  Nom           : main
    --  Description   :
    --
    --  PARAMETRES    :
    --  Pv_Errbuf     IN OUT       Message d'avertissement
    --  Pn_Retcode  IN OUT     Code erreur
    --  VALEUR RETOURNEE :
    --     Description       : code retour de validite
    --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
    --------------------------------------------------------------------------------------
    PROCEDURE main(Pv_Errbuf    IN OUT VARCHAR2,
                   Pn_Retcode   IN OUT NUMBER,
                   P_Entite     IN VARCHAR2,
                   P_Module     IN VARCHAR2,
                   P_N_Requete  IN NUMBER,
                   P_Envoi_Mail IN VARCHAR2);

END DKA_SCTRLMODULE_PKG;
/

SHOW ERRORS;
EXIT