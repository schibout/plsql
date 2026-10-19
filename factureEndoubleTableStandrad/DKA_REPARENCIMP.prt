CREATE OR REPLACE PACKAGE Dka_Sapletmvtzero_Pkg AS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_SAPLETMVTZERO_PKG.pks
    -- DESCRIPTION      : DKA_SAPLETMVTZERO_PKG Package Specifications
    --
    -- AUTEUR           : E.MATUSZEWSKI (Capgemini)
    -- DATE DE CREATION : 28/09/2006
    -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
    -- -----------------------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- ---------- --- --------------------------------------------------------------
    -- 31/10/2007 ADR ETANCHEITE DALKIA 2007
    -- 22/06/2016 YWA Migration R12
    -- -----------------------------------------------------------------------------

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PUBLIQUES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    /* ETANCHEITE DALKIA 2007 */
    gn_per_business_group_id NUMBER := TO_NUMBER(FND_PROFILE.VALUE('PER_BUSINESS_GROUP_ID'));
    gn_org_id                NUMBER := TO_NUMBER(FND_PROFILE.VALUE('ORG_ID'));

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    -- -----------------------------------------------------------------------------
    -- Nom              : main
    -- Description      : Procédure principale du traitement qui enchaîne l'ensemble
    --                    des autres procédures.
    --
    -- PARAMETRES       : Pv_Errbuf       Sortie Message d'erreur
    --                    Pn_Retcode      Sortie Code Retour de la procédure
    --                                           '0' : Normal
    --                                           '1' : Avertissement
    --                                           '2' : Erreur
    --                    Pv_Debug_Switch Entrée Flag activation diagnostic
    --                                           'Y' : Oui 
    --                                           'N' : Non
    --                    Pv_Trace_Switch Entrée Flag activation analyse
    --                                           'Y' : Oui 
    --                                           'N' : Non
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Main(Pv_Errbuf            OUT  VARCHAR2,
                   Pn_Retcode           OUT  NUMBER);

END Dka_Sapletmvtzero_Pkg;
/
SHOW ERRORS
EXIT
