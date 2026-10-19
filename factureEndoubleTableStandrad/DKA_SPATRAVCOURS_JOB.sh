CREATE OR REPLACE PACKAGE DKA_MAIL_PKG IS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_MAIL_PKG.pkb
    -- DESCRIPTION      : DKA_MAIL_PKG Package Body
    --
    -- AUTEUR           : Nicolas BOUSSEKEYT (Capgemini)
    -- DATE DE CREATION : 04/03/2020
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
    --  Description   : Procédure principale du traitement "Envoi par mail des fichiers de contrôle de pré-clôture".
    --
    --  PARAMETRES    :
    --  Pv_Errbuf      IN OUT       Message d'avertissement
    --  Pn_Retcode  IN OUT     Code erreur
    --  P_Req_Id    IN       Numéro de requête
    --------------------------------------------------------------------------------------
    PROCEDURE envoi_mail(Pv_Errbuf  IN OUT VARCHAR2,
                         Pn_Retcode IN OUT NUMBER,
                         P_Req_Id   IN NUMBER);

END DKA_MAIL_PKG;
/
SHOW ERRORS;
EXIT
