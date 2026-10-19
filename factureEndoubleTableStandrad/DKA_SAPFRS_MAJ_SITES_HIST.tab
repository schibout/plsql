CREATE OR REPLACE PACKAGE DKA_SARREFAC_PKG
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SARREFAC_PKG.pks
-- DESCRIPTION       : DKA_SARREFAC_PKG package spec :
---
--- AUTEUR           : Xavier Descamps (CGEY)
--- DATE DE CREATION : 03/12/2001
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 2016/09/26 JJA Portage Helios R12
--- 2018/04/30 JJA artf2572923 : INC0213453 - Edition de refacturation incomplète (Détails manquants) 
---                on lance le traitement run_all_invoice_printing de façon autonome 
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-------------------------------------------------------------------------------------------------------------------
--  Nom           : IS_TRANSACTION_TYPE_REFAC
--  Description   : Fonction qui vérifie si le type de mouvement est soumis a la Refac
--
--  PARAMETRES    :
--      pv_transaction_type     VARCHAR2
--  VALEUR RETOURNEE :
--     Description       : soumis a la Refac
--     Valeurs possibles : TRUE : soumis a la Refac
--                         FALSE: non soumis a la Refac
-------------------------------------------------------------------------------------------------------------------
    FUNCTION is_transaction_type_refac (
        pv_transaction_type   IN   VARCHAR2
    )
        RETURN BOOLEAN;

    PRAGMA RESTRICT_REFERENCES (is_transaction_type_refac, WNDS, WNPS);

-------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_SELECT_RECORD_GROUP
--  Description   : Récupération de requete pour lov dans forms
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--      pv_item                 IN      VARCHAR2
--      pv_select               OUT     VARCHAR2
--  VALEUR RETOURNEE :
--     Description       : Ordre Select
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_select_record_group (
        pv_errbuf    OUT      VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pv_item      IN       VARCHAR2,
        pv_select    OUT      VARCHAR2
    );

-------------------------------------------------------------------------------------------------------------------
--  Nom           : CHECK_AP_INVOICE
--  Description   : Vérification des lignes d'une facture suite au rapprochement avec une commande
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--      pn_invoice_id           IN      NUMBER
--      pv_message              OUT     VARCHAR2
--  VALEUR RETOURNEE :
--     Description       : Message
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE check_ap_invoice (
        pv_errbuf       OUT      VARCHAR2,
        pn_retcode      OUT      NUMBER,
        pn_invoice_id   IN       VARCHAR2,
        Pv_Message      OUT      VARCHAR2
    );

-------------------------------------------------------------------------------------------------------------------
--  Nom           : PA_CHECK_TRANSACTION_DATA
--  Description   : Vérification de cohérence des données saisies sur projet
--
--  PARAMETRES    :
--    pv_errbuf       varchar2
--    pn_retcode      number
--    pn_project_id   number
--    pv_segment1     varchar2
--    pn_task_id      number
--    pv_task_number  varchar2
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE pa_check_transaction_data (
        pv_errbuf             OUT      VARCHAR2,
        pn_retcode            OUT      NUMBER,
        pn_project_id         IN       NUMBER DEFAULT NULL,
        pn_tache_id           IN       NUMBER DEFAULT NULL,
        pv_expenditure_type   IN       VARCHAR2 DEFAULT NULL,
        pb_no_test_type_evt   IN       BOOLEAN  DEFAULT FALSE,
        pv_event_type         IN       VARCHAR2 DEFAULT NULL,
        pd_date               IN       DATE,
        pv_refac              IN       VARCHAR2 DEFAULT 'N'
    );

    PRAGMA RESTRICT_REFERENCES (pa_check_transaction_data, WNDS);

------------------------------------------------------------------------------------------------------------------------
--  Nom           : MAIN
--  Description   : Procédure principale enchaînant l'ensemble des autres procédures
--
--  PARAMETRES :
--    pv_errbuf                       Entrée/Sortie           retour de message eventuel
--    pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-----------------------------------------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );
    
------------------------------------------------------------------------------------------------------------------------
--  Nom           : RUN_ALL_INVOICE_PRINTING
--  Description   : Procédure principale enchaînant les impressions des factures de refac
--
--  PARAMETRES :
--    pv_errbuf                       Entrée/Sortie           retour de message eventuel
--    pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-----------------------------------------------------------------------------------------------------------------------
    PROCEDURE run_all_invoice_printing (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );   
    
------------------------------------------------------------------------------------------------------------------------
--  Nom           : SEND_MAIL
--  Description   : Procédure d'envoi d'email
--
--  PARAMETRES :
--    pn_request_id NUMBER
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-----------------------------------------------------------------------------------------------------------------------
    PROCEDURE send_mail (
        pn_request_id   IN      NUMBER,
        Pv_CDG_FROM IN VARCHAR2,
        Pv_CDG_TO IN VARCHAR2,
        pv_edition IN VARCHAR2
    );    
     
    
END DKA_SARREFAC_PKG; -- Spécification du package
/
SHOW ERRORS;
EXIT
