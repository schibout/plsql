CREATE OR REPLACE PACKAGE DKA_FUSPOCTRSUP_PKG AS 
   --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_FUSPOCTRSUP_PKG
  -- Description      : Body du package DKA_FUSPOCTRSUP_PKG
  -- Auteur           : Saloua HAHIOUI
  -- Date de création : 24/09/2019
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  
  ------------------------------------------------------------------------------------
  -- Nom              : Main
  -- Description      : Procédure principale du traitement
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --					p_mois 			 Nombre de mois
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
  PROCEDURE Main(p_errbuf OUT VARCHAR2, 
                 p_retcode OUT NUMBER ,
                 P_UO_ABSORBEE    number,
			     P_UO_ABSORBANTE  number);

END DKA_FUSPOCTRSUP_PKG;
/
SHOW ERRORS PACKAGE DKA_FUSPOCTRSUP_PKG;
EXIT
