create or replace PACKAGE DKA_IAPFAC_IVALUA_PKG
AS
--------------------------------------------------------------------------------
-- $Id: DKA_IAPFAC_IVALUA_PKG.pks  $
-- Capgemini
-- Projet           : 
-- Nom              : DKA_IAPFAC_IVALUA_PKG.pks
-- Description      : Spécification du package DKA_IAPFAC_IVALUA_PKG
-- Auteur           : Asma AMENKOUR
-- Date de création : 15/09/2020
-- Commentaires     : 
--------------------------------------------------------------------------------
  PROCEDURE EXPORT_IMG( p_file in VARCHAR2
                      , req_id in number
					  , p_user_id in number
                      , Sn_retcode  IN OUT  NUMBER
					  , g_date_export in varchar2
  )   ;  

  PROCEDURE MAIN(pv_errbuf  IN OUT VARCHAR2,
                 pn_retcode OUT NUMBER) ;

END DKA_IAPFAC_IVALUA_PKG;
/
SHOW ERRORS
EXIT