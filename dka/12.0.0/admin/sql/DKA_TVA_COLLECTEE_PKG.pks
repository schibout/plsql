CREATE OR REPLACE PACKAGE DKA_TVA_COLLECTEE_PKG AS
----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM           : DKA_TVA_COLLECTEE_PKG.pks
-- DESCRIPTION       : DKA_TVA_COLLECTEE_PKG package spec :
---
--- AUTEUR           : anthony Deltour(CGEY)
--- DATE DE CREATION : 06/02/2003
--- DOC. ASSOCIEE    : 
-- COMMENTAIRE      : A executer sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-----------------------------------------------------------------------------------------------
--  Nom           : Insert_data
--  Description   : Insertion dans la table DKA_TVA_COLLECTEE des données nécessaires à l'édition
--                  de l'état sur la TVA Collectee pour les lignes de facture:_ exonérées de TVA
--                                                                            _ TVA sur débit
--                                                                            _ TVA sur encaissement                                                                    
--
--  PARAMETRES :
--     pn_ledger_id        Entrée               
--     pv_code_societe           Entrée           Code Societe 
--     pd_periode                Entrée           Période Comptable
--     pv_user_id                Entrée           User_id de l'utilisateur
--     pn_conc_request_id        Entrée           Request_id du traitement
--     pv_debug_mode             Entrée           Mode Debug ('Y' ou 'N')
--     pv_errbuff                Entree/Sortie   message d'erreur
--     pn_retcode                Sortie   code retour (0=Normal, 1=Attention, Autres=Erreur)
-----------------------------------------------------------------------------------------------

    PROCEDURE insert_data (
        pn_ledger_id   IN         NUMBER,      
        pv_code_societe      IN         VARCHAR2,
        pd_periode           IN         VARCHAR2,
        pn_user_id           IN         NUMBER,
        pn_conc_request_id   IN         NUMBER,
        pv_debug_mode        IN         VARCHAR2,
        pv_errbuff           IN   OUT   VARCHAR2,
        pn_retcode                OUT   NUMBER
    );
    
-----------------------------------------------------------------------------------------------
--  Nom           : Update_totaux_fact_regl
--  Description   : Mise a jour du montant total de la facture et du montant total réglé 
--
--  PARAMETRES :
--     pd_gl_date_debut          Entree
--     pd_gl_date_fin            Entree
--     pv_errbuff                Entrie/Sortie   message d'erreur
--     pn_retcode                Sortie   code retour (0=Normal, 1=Attention, Autres=Erreur)
-----------------------------------------------------------------------------------------------
--  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements 
    PROCEDURE update_totaux_fact_regl (
        pd_gl_date_debut     IN         DATE,
        pd_gl_date_fin       IN         DATE,
        pn_conc_request_id   IN       NUMBER,
        pv_errbuff           IN   OUT   VARCHAR2,
        pn_retcode                OUT   NUMBER
    );    
  
-----------------------------------------------------------------------------------------------
--  Nom           : Update_amount_ht_tva
--  Description   : Mise a jour du montant ht_a_declarer et tva_a_declarer pour les 3
--                  types de TVA. 
--
--  PARAMETRES :
--     pv_errbuff                Sortie   message d'erreur
--     pn_retcode                Sortie   code retour (0=Normal, 1=Attention, Autres=Erreur)
-----------------------------------------------------------------------------------------------
--  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements 
    PROCEDURE update_amount_ht_tva (
        pn_conc_request_id   IN       NUMBER,
        pv_errbuff                OUT   VARCHAR2,
        pn_retcode                OUT   NUMBER
    );
    
-----------------------------------------------------------------------------------------------
--  Nom           : update_montant_regle
--  Description   :  Mise à jour du montant_regle dans le cas ou il y plusieurs lignes 
--                   de TVA sur encaissement.  
--
--  PARAMETRES :
--     pv_errbuff                Sortie   message d'erreur
--     pn_retcode                Sortie   code retour (0=Normal, 1=Attention, Autres=Erreur)
----------------------------------------------------------------------------------------------- 
--  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
    PROCEDURE update_montant_regle (
        pn_conc_request_id   IN       NUMBER,
        pv_errbuff                OUT   VARCHAR2,
        pn_retcode                OUT   NUMBER
    );
                
-----------------------------------------------------------------------------------------------
--  Nom           : Delete_data
--  Description   : Supprime les données dans la table DKA_TVA_COLLECTEE en fonction
--                  du Request_id                                                                   
--
--  PARAMETRES :
--     pn_ledger_id        Entree
--     pn_conc_request_id        Entree
--     pv_debug_mode             Entree
--     pv_errbuff                Entrie/Sortie   message d'erreur
--     pn_retcode                Sortie   code retour (0=Normal, 1=Attention, Autres=Erreur)
-----------------------------------------------------------------------------------------------
    
    PROCEDURE delete_data (
        pn_ledger_id   IN         NUMBER,      
        pn_conc_request_id   IN         NUMBER,
        pv_debug_mode        IN         VARCHAR2,
        pv_errbuff           IN   OUT   VARCHAR2,
        pn_retcode                OUT   NUMBER
    );
    
END dka_tva_collectee_pkg; --spécifications du package
/
SHOW ERRORS;
EXIT
