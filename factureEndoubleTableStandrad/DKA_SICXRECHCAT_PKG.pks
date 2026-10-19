CREATE OR REPLACE PACKAGE dka_sapxcrrcr_pkg
AS

---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SAPXCRRCR_PKG.pks
-- DESCRIPTION       : DKA_SAPXCRRCR_PKG package spec :
---
--- AUTEUR           : X. Descamps
--- DATE DE CREATION : 20/05/2003
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 03/04/2007 TB  Ajout d'un paramètre pour le type de fournisseurs (TIERS, GROUPE, EMPLOYE)
--- 31/03/2008 QV  Changement du type des variables pd_pay_through_date et pd_payment_date
---------------------------------------------------------------------------------------------------------------
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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
    PROCEDURE main (
        pv_errbuf                   IN OUT   VARCHAR2,
        pn_retcode                  OUT      NUMBER,
        pv_pay_only_when_due_flag   IN       VARCHAR2,
        pd_pay_through_date         IN       VARCHAR2,--DATE, CSP Portabilite 2008
        pd_payment_date             IN       VARCHAR2,--DATE, CSP Portabilite 2008
        pv_include_unapp_inv_flag   IN       VARCHAR2,
        pv_type_tiers               IN       VARCHAR2 DEFAULT NULL,-- Ajout TB 03/04/07
        pv_include_unval_inv_flag   IN       VARCHAR2,  --Facture non validées
        pv_include_select_inv_flag  IN       VARCHAR2  --Facture sélectionnées 
    );
---------------------------------------------------------------------------------------------------------------

END dka_sapxcrrcr_pkg;
/
SHOW ERROR
EXIT;
