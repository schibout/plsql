create or replace package DKA_SPOFRAIS_PORT_PKG is
---PROD------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            	: DALKIA Oracle Applications
-- NOM           	    : DKA_SPOFRAIS_PORT_PKG.pks
-- DESCRIPTION       	: DKA_SPOFRAIS_PORT_PKG package spec :
---
--- AUTEUR       	    : Eric BLONDEEL
--- DATE DE CREATION 	: 06/03/2006
--- DOC. ASSOCIEE    	:
-- COMMENTAIRE       	: A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 06/03/2006 EB  Création du package
--- 16/11/2007 ADR ETANCHEITE DALKIA 2007
--- 04/04/2017 MEG artf2131632 : Dysfonctionnement de la gestion des frais de port
---------------------------------------------------------------------------------------------------------------
/* ETANCHEITE DALKIA 2007 */
--gn_org_id NUMBER := TO_NUMBER(FND_PROFILE.VALUE('ORG_ID'));

  TYPE g_header_id_tab_type IS TABLE OF po_headers_all.po_header_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE g_vendor_id_tab_type IS TABLE OF po_headers_all.vendor_id%TYPE INDEX BY BINARY_INTEGER;
  
  g_header_id_tab g_header_id_tab_type;
  g_vendor_id_tab g_vendor_id_tab_type;
  g_index_tab NUMBER := 0;
  
  PROCEDURE Calculer_montant (
          pn_header_id                IN  NUMBER,
          pn_montant_calculé          OUT NUMBER,
          pv_errbuf                   OUT VARCHAR2,
          pn_retcode                  OUT NUMBER);
  
  
  PROCEDURE Inserer_ligne (
          pn_header_id                IN  NUMBER, 
          pn_vendor_id                IN  NUMBER,    
          pv_errbuf                   OUT VARCHAR2,
          pn_retcode                  OUT NUMBER);
    
          
  PROCEDURE Annuler_ligne (
          pn_header_id                IN  NUMBER,  
          pn_line_id                  IN  NUMBER,
          pv_errbuf                   OUT VARCHAR2,
          pn_retcode                  OUT NUMBER); 
       
          
  PROCEDURE Supprimer_ligne (
          pn_header_id                IN  NUMBER,  
          pn_line_id                  IN  NUMBER,
          pv_errbuf                   OUT VARCHAR2,
          pn_retcode                  OUT NUMBER);                             

END DKA_SPOFRAIS_PORT_PKG;
/
SHOW ERRORS;
EXIT
