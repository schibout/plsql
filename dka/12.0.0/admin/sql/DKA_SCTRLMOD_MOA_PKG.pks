CREATE OR REPLACE PACKAGE DKA_SCTRLMOD_MOA_PKG IS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_SCTRLMOD_MOA_PKG.pkb
    -- DESCRIPTION      : DKA_SCTRLMOD_MOA_PKG Package Body
    --
    -- AUTEUR           : Anas RAOUF (Capgemini)
    -- DATE DE CREATION : 26/11/2020
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
    --  Nom           : send_mail
    --  Description   : Procédure principale du traitement "DKA : Envoi par mail des fichiers de situation Oracle du matin".
    --
    --  PARAMETRES    :
    --  Pv_Errbuf      IN OUT       Message d'avertissement
    --  Pn_Retcode  IN OUT     Code erreur
    --  P_Req_Id    IN       Numéro de requête
    --------------------------------------------------------------------------------------
    PROCEDURE send_mail(Pv_Errbuf  IN OUT VARCHAR2,
                         Pn_Retcode IN OUT NUMBER,
                         P_Req_Id   IN NUMBER);

    -------------------------------------------------------------------------------------
    --  Nom           : main
    --  Description   : Procédure principale du traitement "DKA : Situation Oracle du matin".
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

END DKA_SCTRLMOD_MOA_PKG;
/

SHOW ERRORS;
EXIT