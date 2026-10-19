CREATE OR REPLACE PACKAGE DKA_IEOAPSAT01_APIMP_PKG AS
--------------------------------------------------------------------------------------------------------------- 
-- CAP GEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_IEOAPSAT01_APIMP_PKG.pks 
-- DESCRIPTION       : DKA_IEOAPSAT01_APIMP_PKG package spec : 
---
--- AUTEUR           : J.JARDEZ (CG)
--- DATE DE CREATION : 17/07/2012
--- DOC. ASSOCIEE    : 
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------------------------- 
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- --------------------------------------------------------------------------------------------
--- 17/07/2012 JJA Création
--------------------------------------------------------------------------------------------------------------- 


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

gn_per_business_group_id NUMBER := TO_NUMBER(fnd_profile.VALUE('PER_BUSINESS_GROUP_ID'));

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++   

----------------------------------------------------------------
--  Nom           : CREATE_AP_IMPORT_FILE
--  Description   : Procédure qui génère le fichier AP_IMPORT 
--
--  PARAMETRES :
--     pv_errbuf          Sortie
--     pn_retcode         Sortie
--     pn_reprise         Entrée
-- VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
----------------------------------------------------------------
    PROCEDURE CREATE_AP_IMPORT_FILE (
        pv_errbuf          IN  OUT VARCHAR2,
        pn_retcode             OUT NUMBER,
        pn_reprise         IN      VARCHAR2,
        pv_entite          IN      VARCHAR2
    );


---------------------------------------------------------------------------------------------------------------  
--  Nom           : main
--  Description   : procédure principale du traitement qui enchaînera l'ensemble
--                  des autres procèdures.
--
--  PARAMETRES    : pv_errbuf              Entrée/Sortie    message d'erreur   
--                  pn_retcode             Sortie           code de retour: 'O=normal', '1=warning', '2=erreur' 
--                  pv_p_paymnt_patch      Entrée
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
--------------------------------------------------------------------------------------------------------------- 
PROCEDURE MAIN(pv_errbuf           IN OUT VARCHAR2,
               pn_retcode             OUT NUMBER--,
               --pv_p_payment_patch  IN     VARCHAR2
               );
---------------------------------------------------------------------------------------------------------------  


END DKA_IEOAPSAT01_APIMP_PKG;                   
/
SHOW ERROR
EXIT;         
  
