create or replace package DKA_IFA_FLUXCM_PKG AS
--------------------------------------------------------------------------------
-- $
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_IFA_FLUXCM_PKG
-- Description      : Spécifications du package DKA_IFA_FLUXCM_PKG
-- Auteur           : C.DEFAUX
-- Date de création : 28/10/2011
-- Doc. associée    :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS 
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 24/10/2016 HDE Migration R12 Helios
--------------------------------------------------------------------------------

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    ------------------------------------------------------------------------------------
    -- Nom              : Main
    -- Description      : Procédure principale du traitement 
    --
    -- PARAMETRES       : Pv_Errbuf             Sortie Message d'erreur
    --                    Pn_Retcode            Sortie Code Retour de la procédure
    --                                                 '0' : Normal
    --                                                 '1' : Avertissement
    --                                                 '2' : Erreur
    --                    Pv_Societe     Entrée        Société
    --                    Pv_Projet      Entrée        Projet
    --                    Pv_Period_From Entrée        Période début
    --                    Pv_Period_To   Entrée        Période fin
    --                    Pv_Compte_From Entrée        Compte début
    --                    Pv_Compte_To   Entrée        Compte fin
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    ------------------------------------------------------------------------------------
    PROCEDURE Main(Pv_Errbuf         OUT VARCHAR2,
                   Pn_Retcode        OUT NUMBER,
                   Pv_Period_From IN     VARCHAR2,
                   Pv_Period_To   IN     VARCHAR2);

end DKA_IFA_FLUXCM_PKG;
/

SHOW ERRORS;

EXIT   
