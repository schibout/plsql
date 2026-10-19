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
CREATE OR REPLACE PACKAGE DKA_SARG00C8_MAIL_PKG AS
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    ------------------------------------------------------------------------------------
    --  Nom           : main
    --  Description   : Procédure principale du traitement DKA : Comparaison mensuelle - Etat de comparaison
    --
    --  PARAMETRES    :
    --      Pv_Errbuf         Message d'erreur
    --      Pn_Retcode        Code de retour
    --      P_Set_Of_Books_Id   Identifiant du Set_Of_Books
    --  VALEUR RETOURNEE :
    --     Valeurs possibles : 0: deroulement correct
    --                         1: avertissement
    --                         2: deroulement avec erreur
    ------------------------------------------------------------------------------------
    PROCEDURE main(Pv_Errbuf         OUT VARCHAR2,
                   Pn_Retcode        OUT NUMBER);--,
				   --P_Set_Of_Books_Id IN	 VARCHAR2);
				   
END DKA_SARG00C8_MAIL_PKG;
/

SHOW ERROR PACKAGE DKA_SARG00C8_MAIL_PKG;
EXIT