CREATE OR REPLACE PACKAGE DKA_SAPCREATE_BLOCAGES_PKG AS
---------------------------------------------------------------------------------------------------------------
  -- $Id: DKA_SAPCREATE_BLOCAGES_PKG.pks 2011-03-29 12:19:28Z CORP\mthunga $
  --
  -- CAPGEMINI
  -- PROJET      : HELIOS
  -- NOM         : DKA_SAPCREATE_BLOCAGES_PKG.pks
  -- DESCRIPTION       : DKA_SAPCREATE_BLOCAGES_PKG package spec :
  ---
  --- AUTEUR       : Maheswara THUNGA (CAPGEMINI)
  --- DATE DE CREATION : 29/03/2011
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  ---------------------------------------------------------------------------------------------------------------
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- NBO 24/11/16 - SPE001 - defect 388 Prise en compte des données AP du jour en erreur
  gn_org_id                NUMBER := TO_NUMBER(MO_GLOBAL.get_current_org_id);--TO_NUMBER(FND_PROFILE.VALUE('ORG_ID'));
  ------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure de l'executable rattache au traitement DKA_SAPCREATE_BLOCAGES_PKG
  --               
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE Main ( pv_errbuf     OUT VARCHAR2,
                   pn_retcode    IN OUT NUMBER);
  ------------------------------------------------------------------------------------
  --  Nom           : Blocage_date_facture
  --  Description   : 
  --               
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------

  PROCEDURE Blocage_date_facture(
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    ) ;
  ------------------------------------------------------------------------------------
  --  Nom           : Blocage_fres_affact
  --  Description   : 
  --               
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE Blocage_fres_affact(
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    ) ;
           
  PROCEDURE cree_blocage(pn_invoice_id     IN ap_invoices_all.invoice_id%type,
                         pv_blocage        IN ap_holds_all.hold_lookup_code%type,
                         pv_blocage_reason IN ap_holds_all.hold_reason%type,
                         pn_user_id        IN fnd_user.user_id%type,
                         pv_errbuf        OUT NOCOPY VARCHAR2,
                         pn_retcode       OUT NOCOPY NUMBER);
                                                                 
  END DKA_SAPCREATE_BLOCAGES_PKG; -- Spécification du package
/
SHOW ERROR PACKAGE DKA_SAPCREATE_BLOCAGES_PKG;
EXIT
