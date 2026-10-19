create or replace package DKA_SPOCHARGCATLG_PKG
AS

--------------------------------------------------------------------------------------------
-- $Id: DKA_SPOCHARGCATLG_PKG.pks 271 2018-01-17 10:13:20 $
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications (Helios R12)
-- NOM               : DKA_SPOCHARGCATLG_PKG.pks
-- DESCRIPTION       : DKA_SPOCHARGCATLG_PKG package body :
---
--- AUTEUR           : R. BELAYACHI (CAPGEMINI)
--- DATE DE CREATION : 17/01/2018
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------
--  Nom           : duplicate_orders
--  Description   : Procédure pour le traitement de duplication des commandes ouvertes globales
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--  pn_retcode                      Sortie                  status du traitement en sortie
--  pn_po_header_id                 Entrée                  id de la commande ouverte
--  pv_action                       Entrée                  action à effectuer par le traitement
--  pv_perimetre                    Entrée                  perimetre de l'action
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE duplicate_orders (
        pv_errbuf       IN OUT   VARCHAR2,
        pn_retcode      OUT      NUMBER,
        pn_po_header_id IN       NUMBER,
        pv_action       IN       VARCHAR2,
        pv_perimetre    IN       VARCHAR2
    );

-------------------------------------------------------------------------------------------------------------------
--  Nom           : duplicate_sites
--  Description   : Procédure pour le traitement DKA : Mise à jour des rattachements 
--                                               de sites fournisseurs sur 
--                                               commande ouverte globale
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--  pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE duplicate_sites (
        pv_errbuf       IN OUT   VARCHAR2,
        pn_retcode      OUT      NUMBER
    );
    
END DKA_SPOCHARGCATLG_PKG; -- Package spec
/
SHOW ERRORS;
EXIT;
