CREATE OR REPLACE PACKAGE DKA_SAPRPT_MVTS_SANS_IMAGE IS
  -- $Id$
  --
  -- CAPGEMINI
  -- PROJET      : VEOLIA Puissance 4
  -- NOM         : DKA_SAPRPT_MVTS_SANS_IMAGE_PKG.pks
  -- DESCRIPTION : DKA_SAPRPT_MVTS_SANS_IMAGE package spec :
  ---              package spécifique utilisé dans le workflow remplacant le workflow approbation AP
  --- AUTEUR       : Maheswara Thunga (CAPGEMINI)
  --- DATE DE CREATION : 20/05/2010
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- --------------------------------------------------------------------------------------------
  --- 2016/07/05 JJA Portage Helios R12
  ---------------------------------------------------------------------------------------------------------------
PROCEDURE clear_tmp_table(pv_csp IN VARCHAR2,
                          pv_division IN VARCHAR2,
                          pv_status IN OUT VARCHAR2);
PROCEDURE Load_data(pv_csp IN VARCHAR2,
                    pv_division IN VARCHAR2,
                    pv_status IN OUT VARCHAR2);
PROCEDURE Launch_report ( pv_csp        IN VARCHAR2,
                          pv_division   IN VARCHAR2,
                          pv_status IN OUT VARCHAR2); 
PROCEDURE Main (pv_errbuf     OUT VARCHAR2,
                pn_retcode    IN OUT NUMBER,
                pv_csp        IN VARCHAR2,
                pv_division   IN VARCHAR2);                           

END DKA_SAPRPT_MVTS_SANS_IMAGE;
/

show errors package DKA_SAPRPT_MVTS_SANS_IMAGE;
EXIT


