CREATE OR REPLACE PACKAGE DKA_SAPACTUALIMG_WF_PKG AS
---------------------------------------------------------------------------------------------------------------
  -- $Id$
  --
  -- CAPGEMINI
  -- PROJET      : VEOLIA Puissance 4
  -- NOM         : DKA_SAPWFCSP_PKG.pks
  -- DESCRIPTION : DKA_SAPWFCSP_PKG package spec :
  ---
  --- AUTEUR       : Vincent Knab (CAPGEMINI)
  --- DATE DE CREATION : 16/01/2008
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --- 2016/07/05 JJA Portage Helios R12
  ---------------------------------------------------------------------------------------------------------------

 PROCEDURE actualise_url_notif(pn_retcode  IN OUT NUMBER , 
                               pv_errbuf out varchar2) ;

END DKA_SAPACTUALIMG_WF_PKG; -- Spécification du package
/
SHOW ERROR PACKAGE DKA_SAPACTUALIMG_WF_PKG;
EXIT
