create or replace package DKA_SPORECEP_FRAISPORT_PKG is
---PROD------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            	: DALKIA Oracle Applications
-- NOM           	    : DKA_SPORECEP_FRAISPORT_PKG.pks
-- DESCRIPTION       	: DKA_SPORECEP_FRAISPORT_PKG package spec :
---
--- AUTEUR       	    : Thierry Bougault
--- DATE DE CREATION 	: 05/02/2007
--- DOC. ASSOCIEE    	:
-- COMMENTAIRE       	: A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
---------------------------------------------------------------------------------------------------------------

  PROCEDURE put_line_log (
        pv_buffer   IN   VARCHAR2);

  PROCEDURE put_line_out (
        pv_buffer   IN   VARCHAR2);
    
  PROCEDURE init (
        pv_prog     IN      VARCHAR2 DEFAULT NULL,
        pv_errbuf   OUT  VARCHAR2,
        pn_retcode  OUT  NUMBER);
    
  PROCEDURE insert_rcv_headers(
        pn_user_id                  IN  NUMBER,
        pn_vendor_id                IN  NUMBER,
        pn_vendor_site_id           IN  NUMBER,
        pn_location_id              IN  NUMBER,
        pn_org_id                   IN  NUMBER,
        pv_errbuf                   OUT VARCHAR2,
        pn_retcode                  OUT NUMBER);
        
  PROCEDURE insert_rcv_transactions(
        pn_user_id                  IN  NUMBER,
        pn_quantity                 IN  NUMBER,
        pv_uom                      IN  VARCHAR2,
        pv_description              IN  VARCHAR2,
        pn_org_id                   IN  NUMBER,
        pn_vendor_id                IN  NUMBER,
        pn_vendor_site_id           IN  NUMBER,        
        pn_header_id                IN  NUMBER,
        pn_line_id                  IN  NUMBER,
        pn_line_location_id         IN  NUMBER,        
        pv_errbuf                   OUT VARCHAR2,
        pn_retcode                  OUT NUMBER);


  PROCEDURE main (
        pv_errbuf                   OUT VARCHAR2,
        pn_retcode                  OUT NUMBER,
        vd_date_deb                 IN  VARCHAR2,
        vd_date_fin                 IN  VARCHAR2);        

END DKA_SPORECEP_FRAISPORT_PKG;
/
SHOW ERRORS;
EXIT  
