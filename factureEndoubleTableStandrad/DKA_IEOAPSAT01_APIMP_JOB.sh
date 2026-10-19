CREATE OR REPLACE PACKAGE DKA_SAPCAMPPREL_PKG AS
-- -----------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SAPCAMPPREL_PKG.pks
-- DESCRIPTION      : DKA_SAPCAMPPREL_PKG Package Specifications
--
-- AUTEUR           : A.DELTOUR (Capgemini)
-- DATE DE CREATION : 06/06/2007
-- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
-- -----------------------------------------------------------------------------
--
-- -----------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 02/10/2017 JJA Correction : artf2228879 
-- 28/03/2018 RBE Correction : artf2470765: INC0191103 : SPE118 - Correctif sur lancement campagne Prelevement AP
-- -----------------------------------------------------------------------------

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  TYPE gr_ap_prelevement_tmp IS RECORD
  ( PHASE                      VARCHAR2(50),
    DATE_EXTRACTION            DATE,
    INVOICE_ID                 AP_INVOICES_ALL.INVOICE_ID%TYPE,
    INVOICE_NUM                AP_INVOICES_ALL.INVOICE_NUM%TYPE,
    INVOICE_DATE               AP_INVOICES_ALL.INVOICE_DATE%TYPE,
    INVOICE_AMOUNT             AP_INVOICES_ALL.INVOICE_AMOUNT%TYPE,
    CANCELLED_DATE             AP_INVOICES_ALL.CANCELLED_DATE%TYPE,
    PAY_GROUP_LOOKUP_CODE      AP_INVOICES_ALL.PAY_GROUP_LOOKUP_CODE%TYPE,
    PAYMENT_METHOD_LOOKUP_CODE AP_PAYMENT_SCHEDULES_ALL.PAYMENT_METHOD_LOOKUP_CODE%TYPE,
    EXCLUSIVE_PAYMENT_FLAG     AP_INVOICES_ALL.EXCLUSIVE_PAYMENT_FLAG%TYPE,
    PAYMENT_NUM                AP_PAYMENT_SCHEDULES_ALL.PAYMENT_NUM%TYPE,
    DUE_DATE                   AP_PAYMENT_SCHEDULES_ALL.DUE_DATE%TYPE,
    PAYMENT_PRIORITY           AP_PAYMENT_SCHEDULES_ALL.PAYMENT_PRIORITY%TYPE,
    VENDOR_NAME                PO_VENDORS.VENDOR_NAME%TYPE,
    VENDOR_SITE_CODE           PO_VENDOR_SITES_ALL.VENDOR_SITE_CODE%TYPE);
    
  TYPE gt_ap_prel_tmp_tab IS TABLE OF gr_ap_prelevement_tmp INDEX BY BINARY_INTEGER;
  
  gt_ap_prel_tmp               gt_ap_prel_tmp_tab;  
  gn_userid                    FND_USER.USER_ID%TYPE := Fnd_Global.USER_ID;
  gn_login_id                  FND_LOGINS.LOGIN_ID%TYPE := Fnd_Global.LOGIN_ID;
  gn_request_id                FND_CONCURRENT_REQUESTS.REQUEST_ID%TYPE := fnd_global.CONC_REQUEST_ID;
  gn_org_id                    HR_ALL_ORGANIZATION_UNITS.ORGANIZATION_ID%TYPE := NULL; --RBE artf2470765 fnd_profile.VALUE('ORG_ID');
  gv_society                   VARCHAR2(4) := NULL;
  gn_bank_account_id           AP_BANK_ACCOUNTS_ALL.BANK_ACCOUNT_ID%TYPE := NULL;
  gn_vendor_id                 PO_VENDORS.VENDOR_ID%TYPE := NULL;
  gn_vendor_site_id            PO_VENDOR_SITES_ALL.VENDOR_SITE_ID%TYPE := NULL;
  gn_nb_factures               NUMBER := 0;
  gv_pay_group                 PO_LOOKUP_CODES_PAY_GROUP_AP_V.PAYGROUP%TYPE := NULL;
  gd_date_from                 DATE;
  gd_date_to                   DATE;
   
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- -----------------------------------------------------------------------------
-- Nom              : main
-- Description      : Procédure principale du traitement qui enchaîne l'ensemble
--                    des autres procédures.
--
-- PARAMETRES       : Pv_Errbuf         Sortie Message d'erreur
--                    Pn_Retcode        Sortie Code Retour de la procédure
--                                           '0' : Normal
--                                           '1' : Avertissement
--                                           '2' : Erreur
--                    Pn_vendor_id      Identifiant du fournisseur
--                    Pn_vendor_site_id Identifiant du site fournisseur
--                    Pv_date_from      Date de debut de selection
--                    Pv_date_to        Date de debut de selection
--                    Pv_society        Societe        
--                    Pv_region         Region
--                    Pv_bank_account_id identifiant du compte bancaire               
--                    Pv_Debug_Switch   Entrée Flag activation diagnostic
--                                           'Y' : Oui 
--                                           'N' : Non
--                    Pv_Trace_Switch   Entrée Flag activation analyse
--                                           'Y' : Oui 
--                                           'N' : Non
--
-- VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
-- -----------------------------------------------------------------------------
  PROCEDURE Main(Pv_Errbuf            OUT NOCOPY VARCHAR2,
                 Pn_Retcode           OUT NOCOPY NUMBER,
                 Pn_org_id          IN           NUMBER, --RBE artf2470765
                 Pn_vendor_id       IN           NUMBER,
                 Pn_vendor_site_id  IN           NUMBER,
                 Pv_date_from       IN           VARCHAR2,
                 Pv_date_to         IN           VARCHAR2,
                -- Pv_society         IN           VARCHAR2,
                -- Pv_region          IN           VARCHAR2 DEFAULT NULL,
                -- Pv_pay_group       IN           VARCHAR2,
                 Pn_bank_account_id IN           NUMBER,
                 Pv_Debug_Switch    IN           VARCHAR2,
                 Pv_Trace_Switch    IN           VARCHAR2);

END DKA_SAPCAMPPREL_PKG;
/
SHOW ERRORS
EXIT
