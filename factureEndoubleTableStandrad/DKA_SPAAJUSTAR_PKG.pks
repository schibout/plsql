CREATE OR REPLACE PACKAGE BODY DKA_SICXRECHCAT_PKG IS
--------------------------------------------------------------------------------
-- $Id: DKA_SICXRECHCAT_PKG.pkb  $
-- Capgemini
-- Projet           : 
-- Nom              : DKA_SICXRECHCAT_PKG.pks
-- Description      : Corps du package DKA_SICXRECHCAT_PKG
-- Auteur           : Asma AMENKOUR
-- Date de création : 06/03/2019
-- Commentaires     : 
--------------------------------------------------------------------------------

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
    RETURN NUMBER IS 
	v_recherche_id NUMBER;
    v_nom_domaine ICX_CAT_SHOP_STORES_VL.name%type;
	BEGIN
	  select DKA_SICXRECHCAT_HIST_S.nextval 
      into   v_recherche_id
      from   DUAL;
      
      select  name
      into v_nom_domaine
      from ICX_CAT_SHOP_STORES_VL
      where store_id = p_domaine
      and   local_content_first_flag = 'Y';

	  INSERT INTO DKA_SICXRECHCAT_HIST
	  (
	  ID_RECHERCHE                  ,
      UO                            ,
      USER_ID                       ,
      RECH_DOMAINE                  , 
      RECH_MARCHE                   ,
      RECH_CODE_ARTICLE_INTERNE     ,
      RECH_REF_FRS_FAB              ,
      RECH_FOURNISSEUR              ,
      RECH_FABRICANT                ,
      RECH_MOTS_CLES                ,
      RESULT_CODE_ARTICLE_INTERNE   ,
      CREATION_DATE                 ,
      CREATED_BY                    ,
      LAST_UPDATE_DATE              ,
      LAST_UPDATED_BY               ,
      STATUT

	  )
      values
	  (
	  v_recherche_id                ,
	  p_uo                          ,
	  p_user_id                     ,
	  v_nom_domaine                 ,
	  p_marche                      ,
	  p_code                        ,
	  p_reference                   ,
	  p_fournisseur                 ,
	  p_fabricant                   ,
	  p_mot_cle                     ,
      p_codeResultat                ,
      SYSDATE                       ,
      FND_PROFILE.VALUE('USER_ID')  ,
      SYSDATE                       ,
      FND_PROFILE.VALUE('USER_ID')  ,
      'NEW'
	  );
	  COMMIT;
      RETURN v_recherche_id;
    END insert_DKA_SICXRECHCAT_HIST;
    
END DKA_SICXRECHCAT_PKG;

/
show error;
exit;