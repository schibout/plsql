--------------------------------------------------------------------------------
-- $
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_SARG00C8_PKG
-- Description      : Spec du package DKA_SARG00C8_PKG
-- Auteur           : B.Coudrier
-- Date de création : 25/04/2014
-- Doc. associée    :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS 
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE DKA_SARG00C8_PKG AS

    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    ------------------------------------------------------------------------------------
    --  Nom           : SARG00C8_ETAT
    --  Description   : Procédure principale du traitement DKA : Comparaison mensuelle - Etat de comparaison
    --
    --  PARAMETRES    :
    --      Pv_Errbuf         Message d'erreur
    --      Pn_Retcode        Code de retour
    --      P_Set_Of_Books_Id   Identifiant du Set_Of_Books
    --    P_Periode      Nom de la période.
    --  VALEUR RETOURNEE :
    --     Valeurs possibles : 0: deroulement correct
    --                         1: avertissement
    --                         2: deroulement avec erreur
    ------------------------------------------------------------------------------------
    PROCEDURE SARG00C8_ETAT(Pv_Errbuf         OUT VARCHAR2,
                            Pn_Retcode        OUT NUMBER,
							--P_Set_Of_Books_Id IN NUMBER,
                            P_Periode         IN VARCHAR2);
							
    ------------------------------------------------------------------------------------
    --  Nom           : SARG00C8_RATT
    --  Description   : Procédure principale du traitement DKA : Comparaison mensuelle - Etat de comparaison
    --
    --  PARAMETRES    :
    --      Pv_Errbuf         Message d'erreur
    --      Pn_Retcode        Code de retour
    --      P_Set_Of_Books_Id   Identifiant du Set_Of_Books
    --    P_Periode_Debut    Nom de la période de début.
    --    P_Periode_Fin    Nom de la période de fin.
    --  VALEUR RETOURNEE :
    --     Valeurs possibles : 0: deroulement correct
    --                         1: avertissement
    --                         2: deroulement avec erreur
    ------------------------------------------------------------------------------------
    PROCEDURE SARG00C8_RATT(Pv_Errbuf         OUT VARCHAR2,
                            Pn_Retcode        OUT NUMBER,
							--P_Set_Of_Books_Id IN NUMBER,
                            P_Periode_Debut   IN VARCHAR2,
                            P_Periode_Fin     IN VARCHAR2);
							
END DKA_SARG00C8_PKG;
/

SHOW ERRORS PACKAGE DKA_SARG00C8_PKG;

EXIT