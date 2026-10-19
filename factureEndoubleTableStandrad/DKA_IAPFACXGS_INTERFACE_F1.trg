create or replace PACKAGE DKA_SICXRECHCAT_PKG
AS
--------------------------------------------------------------------------------
-- $Id: DKA_SICXRECHCAT_PKG.pks  $
-- Capgemini
-- Projet           : 
-- Nom              : DKA_SICXRECHCAT_PKG.pks
-- Description      : Spécification du package DKA_SICXRECHCAT_PKG
-- Auteur           : Asma AMENKOUR
-- Date de création : 06/03/2019
-- Commentaires     : 
--------------------------------------------------------------------------------

  -------------------------------------------------------------------------------------
  --  Nom           : insert_DKA_SICXRECHCAT_HIST
  --  Description   : Fonction pour inserer les critères de recherche dans la table
  --                  DKA_SICXRECHCAT_HIST .
  --
  --  PARAMETRES :  p_user_id
  --                p_uo
  --                p_domaine        
  --                p_marche         
  --		        p_code           
  --		        p_reference      
  --		        p_fournisseur    
  --		        p_fabricant      
  --                p_mot_cle     
  --                p_codeResultat  
  --
  --  VALEUR RETOURNEE : ID_RECHERCHE qui est la valeur de la sequence DKA_SICXRECHCAT_HIST_S
  -------------------------------------------------------------------------------------
FUNCTION insert_DKA_SICXRECHCAT_HIST ( p_user_id        IN NUMBER
                                     , p_uo             IN VARCHAR2 
                                     , p_domaine        IN VARCHAR2
                                     , p_marche         IN VARCHAR2
						             , p_code           IN VARCHAR2
						             , p_reference      IN VARCHAR2
						             , p_fournisseur    IN VARCHAR2
						             , p_fabricant      IN VARCHAR2
									 , p_mot_cle        IN VARCHAR2
                                     , p_codeResultat   IN VARCHAR2
                                       )
RETURN NUMBER;

END DKA_SICXRECHCAT_PKG;

/
show error;
exit;