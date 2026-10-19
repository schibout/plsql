create or replace PACKAGE DKA_SPOCMDMAIL_CITY_PKG IS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_SPOCMDMAIL_CITY_PKG.pkb
    -- DESCRIPTION      : DKA_SPOCMDMAIL_CITY_PKG Package Body
    --
    -- AUTEUR           : Anas RAOUF (Capgemini)
    -- DATE DE CREATION : 03/05/2021
    -- COMMENTAIRES     : A exÃ©cuter sous SQLPLUS avec le user apps
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
    --  Nom           : main
    --  Description   : Procédure principale du traitement "DKA : Edition et envoi par mail de l¿état de la facturation et des commandes CITY".
    --
    --  PARAMETRES    :
    --  Pv_Errbuf     IN OUT       Message d'avertissement
    --  Pn_Retcode  IN OUT         Code erreur
    --  Pn_CASH_RECEIPT_ID IN      Identifiant du Prélèvement
    --  VALEUR RETOURNEE :
    --     Description       : code retour de validite
    --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
    --------------------------------------------------------------------------------------
    PROCEDURE main(Pv_Errbuf    IN OUT VARCHAR2,
                   Pn_Retcode   IN OUT NUMBER,
                    P_period IN VARCHAR2,
                    P_region IN VARCHAR2
                   );

END DKA_SPOCMDMAIL_CITY_PKG;

/
SHOW ERRORS;
EXIT