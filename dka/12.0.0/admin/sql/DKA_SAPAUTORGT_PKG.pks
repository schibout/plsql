CREATE OR REPLACE PACKAGE DKA_SAPAUTORGT_PKG AS
--------------------------------------------------------------------------------------------------------------- 
-- CAP GEMINI ERNST AND YOUNG
-- $Id: DKA_SAPAUTORGT_PKG.pks 34 2008-08-05 12:53:03Z tbonduae $
-- PROJET            : DALKIA Oracle Applications
-- NOM		     	 : DKA_SAPAUTORGT.pks
-- DESCRIPTION	     : DKA_SAPAUTORGT_PKG package spec : 
---
--- AUTEUR	     : M.E (CGEY)
--- DATE DE CREATION : 11/06/2002
--- DOC. ASSOCIEE    : DOCF281
--  COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------------------------- 
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 29/10/2007 ADR ETANCHEITE DALKIA 2007
--------------------------------------------------------------------------------------------------------------- 
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/* ETANCHEITE DALKIA 2007 */
gn_per_business_group_id NUMBER := TO_NUMBER(FND_PROFILE.VALUE('PER_BUSINESS_GROUP_ID'));
gn_org_id                NUMBER := TO_NUMBER(FND_PROFILE.VALUE('ORG_ID'));
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++               
---------------------------------------------------------------------------------------------------------------  
--  Nom           : Validate
--  Description   : 
--                  
--  PARAMETRES    : 
--                  
--
--  VALEUR RETOURNEE :
--     Description       : Procédure standard du package AP_PBATCH_SET_LINES_PKG adaptée pour retourner le 
--                         nom du lot déjà utilisé en cas de conflit sur le titre de paiement
--                         c'est à dire quand p_doc_in_use vaut 'Y'
--     Valeurs possibles : ************************
--------------------------------------------------------------------------------------------------------------- 
--RBE
/*
PROCEDURE Validate (p_batch_set_id             IN  NUMBER,
                   p_batch_run_name            IN  VARCHAR2,
                   p_payment_date              IN  DATE,
                   p_exchange_date             IN  DATE,
                   p_doc_in_use                OUT VARCHAR2,
                   p_in_use_by                 OUT VARCHAR2,
                   p_calling_sequence          IN  VARCHAR2);

---------------------------------------------------------------------------------------------------------------  
--  Nom           : Insert_Submit_Records
--  Description   : 
--                  
--  PARAMETRES    : pv_errbuf              Entrée/Sortie    message d'erreur   
--                  pn_retcode             Sortie           code de retour: 'O=normal', '1=warning', '2=erreur' 
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
--------------------------------------------------------------------------------------------------------------- 
 PROCEDURE Insert_Submit_Records
            (p_batch_set_id           IN      NUMBER,
             p_batch_run_name         IN      VARCHAR2,
             p_pay_thru_date          IN      DATE,
             p_payment_date           IN      DATE,
             p_exchange_date          IN      DATE,
             p_exchange_rate_type     IN      VARCHAR2,
             p_select_invoices        IN      VARCHAR2,
             p_build_payments         IN      VARCHAR2,
             p_print_preg             IN      VARCHAR2,
             p_preg_printer           IN      VARCHAR2,
             p_format_payments        IN      VARCHAR2,
             p_print_now              IN      VARCHAR2,
             p_confirm_payments       IN      VARCHAR2,
             p_print_freg             IN      VARCHAR2,
             p_freg_printer           IN      VARCHAR2,
             p_print_sra              IN      VARCHAR2,
             p_debug_switch           IN      VARCHAR2,
             p_trace_switch           IN      VARCHAR2,
             p_calling_sequence       IN      VARCHAR2);

*/ --fin RBE


------------------------------------------------------------------------------------------------------------  
--  Nom           : main
--  Description   : procédure principale du traitement qui enchaînera l'ensemble
--                  des autres procèdures.
--
--  PARAMETRES    : pv_errbuf              Entrée/Sortie    message d'erreur   
--                  pn_retcode             Sortie           code de retour: 'O=normal', '1=warning', '2=erreur' 
--		    		
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
--------------------------------------------------------------------------------------------------------------- 
PROCEDURE main(pv_errbuf        	IN  	OUT VARCHAR2,
               pn_retcode           	        OUT NUMBER,
               pv_vendor_pay_group      IN	    VARCHAR2);

---------------------------------------------------------------------------------------------------------------  

---------------------------------------------------------------------------------------------------------------
--  Nom           : recalculate
--  Description   : procédure principale du traitement qui enchaînera la compagne de reglement
--
--  PARAMETRES    : pv_errbuf              Entrée/Sortie    message d'erreur
--                  pn_retcode             Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--                  pv_vendor_pay_group    Type de fournisseur
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE recalculate(pv_errbuf           IN  OUT     VARCHAR2,
                      pn_retcode          OUT         NUMBER,
                      pv_vendor_pay_group IN	       VARCHAR2);

---------------------------------------------------------------------------------------------------------------


END DKA_SAPAUTORGT_PKG;                   
/
SHOW ERROR
EXIT;
