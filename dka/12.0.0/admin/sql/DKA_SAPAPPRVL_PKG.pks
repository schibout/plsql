CREATE OR REPLACE PACKAGE DKA_SAPAPPRVL_PKG AS
--------------------------------------------------------------------------------------------------------------- 
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM		     : DKA_SAPAPPRVL_PKG.pks
-- DESCRIPTION	     : DKA_SAPAPPRVL_PKG package spec : 
---
--- AUTEUR	     : Guillaume CHABRIER (CGEY)
--- DATE DE CREATION : 15/01/2002
--- DOC. ASSOCIEE    : 
--  COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------------------------- 
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 30/10/2007 ADR ETANCHEITE DALKIA 2007
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
--  Nom           : main
--  Description   : procédure principale du traitement qui enchaînera l'ensemble
--                  des autres procèdures.
--
--  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur   
--                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur' 
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
--------------------------------------------------------------------------------------------------------------- 
PROCEDURE main(pv_errbuf        IN  OUT VARCHAR2,
               pn_retcode           OUT NUMBER);
---------------------------------------------------------------------------------------------------------------  

END DKA_SAPAPPRVL_PKG;                   
/
SHOW ERROR
EXIT;
