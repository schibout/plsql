CREATE OR REPLACE PACKAGE Dka_Sapdas2_Pkg AS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_SAPDAS2_PKG
    -- DESCRIPTION      : DKA_SAPDAS2_PKG Package Specifications
    --
    -- AUTEUR           : E.MATUSZEWSKI (Capgemini)
    -- DATE DE CREATION : 29/11/2006
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
    -- CONSTANTES ET VARIABLES PUBLIQUES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    -- -----------------------------------------------------------------------------
    -- Nom              : Control_Data
    -- Description      : Controle des données pour l'édition de la DAS2;
    --
    -- PARAMETRES       : Pv_Errbuf              Sortie Message d'erreur
    --                    Pn_Retcode             Sortie Code Retour de la procédure
    --                                                  '0' : Normal
    --                                                  '1' : Avertissement
    --                                                  '2' : Erreur
    --                    Pv_Annee       Entrée         Année de déclaration
    --                    Pv_Societe     Entrée         Société de déclaration
    --
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Control_Data(Pv_Errbuf              OUT  VARCHAR2,
                           Pn_Retcode             OUT  NUMBER,
                           Pv_Annee           IN       VARCHAR2,
                           Pv_Societe         IN       VARCHAR2,
                           Pv_Controle        IN       VARCHAR2,
                           Pv_Debug_Mode      IN       VARCHAR2,
                           Pn_Set_Of_Books_Id IN       NUMBER);


END Dka_Sapdas2_Pkg;
/
SHOW ERRORS
EXIT
