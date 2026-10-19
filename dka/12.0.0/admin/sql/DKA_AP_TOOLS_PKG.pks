CREATE OR REPLACE PACKAGE DKA_AP_TOOLS_PKG AS
----------------------------------------------------------------------------------------------
-- $Id$
--
-- NOM               : DKA_AP_TOOLS_PKG.pks
-- DESCRIPTION       : DKA_AP_TOOLS_PKG package spec : fonctions communes
---
--- AUTEUR           : J.JARDEZ
--- DATE DE CREATION : 16/03/2016
--- DOC. ASSOCIEE    :
---
----------------------------------------------------------------------------------------------
--- NOM DU PROGRAMME :
--- PARAMETRES       :
---
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  16/03/2016 JJA Portage Helios 2016
--  19/05/2016 RBE Ajout de la fonction get_Attribute12DSP_Facture
--  03/05/2018 RBE EDB 106 : Ajout fonction get_is_vendor_analyse
--------------------------------------------------------------------------------------------
-----------------------------------------------------------------
--  Variables globales
-----------------------------------------------------------------
    gv_debug_mode        VARCHAR2 (1);

----------------------------------------------------------------------------
--  Nom           : get_Attribute12DSP_Facture
--  Description   : Fonction pour affichée le libelle (pour le moment user_name)
--                  correspondant a l'ID du CUF attribute12 de la facture  (pour le moment user_id )
--                  mais comme le jeu de valeurs peut etre modifie a tout moemnt...
-- PARAMETRES     :
--  pv_attribute12    la valeur présente dans le CUF
--
-- VALEUR RETOURNEE :
--  vv_attribute12dsp    le libellé correspondant (utilisé pour le workflow, dans le forms de passerelle de factures)
----------------------------------------------------------------------------
    FUNCTION get_Attribute12DSP_Facture (
                                     pv_attribute12  ap_invoices_all.attribute12%type
                                     ) 
        RETURN VARCHAR2;
        
-----------------------------------------------------------------
--  Nom           : APPLY_FONCTION
--  Description   : Procedure utilisée pour ajouter les lignes de TVA AUTOLIQUIDEE 
--                  ou rapprocher les acomptes selon l'interface
--
--  PARAMETRES :
--     pv_interface_origine   Entrée   Interface origine
--     pv_source              Entrée   Source
--     pv_folio               Entrée   Code folio
--     pv_group_id            Entrée   Group ID
--     pn_org_id              Entrée   Org_id
--
--  VALEUR RETOURNEE :
--     pv_errbuf       :  Message de sortie
--     pn_retcode      :  '0'=OK, '2'=Erreur
-----------------------------------------------------------------                                   
  PROCEDURE apply_fonction(pv_errbuf            OUT VARCHAR2,
                           pn_retcode           OUT NUMBER,
                           pv_interface_origine IN VARCHAR2,
                           pv_source            IN VARCHAR2,
                           pv_folio             IN VARCHAR2,
                           pv_group_id          IN VARCHAR2,
                           pn_org_id            IN NUMBER);

---------------------------------------------------------------------------------------
--  Nom           : get_vendor_partner
--  Description   : Procédure permettant d'obtenir les identifiants du fournisseur, du site fournisseur
--                  correspondant a la société passée en parametre et définis dans le centre de gestion
--                  et l'organisation passés en entrée
--
--  PARAMETRES :
--          pv_code_societe     Entrée
--          pn_org_id           Entrée
--          pn_vendor_id                Sortie
--          pn_vendor_site_id           Sortie
--          pv_errbuf           Entrée  Sortie
--          pn_retcode                  Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
PROCEDURE get_vendor_partner (
    pv_code_societe     IN       VARCHAR2,
    pn_org_id           IN       NUMBER,
    pn_vendor_id        OUT      NUMBER,
    pn_vendor_site_id   OUT      NUMBER,
    pv_errbuf           IN OUT   VARCHAR2,
    pn_retcode          OUT      NUMBER
);

-----------------------------------------------------------------
--  Nom           : APPLY_FONCTION
--  Description   : Fonction utilisée pour verifier si le fournisseur est de type prestataire Analyse 
--
--  PARAMETRES :
--     pn_vendor_id   Entrée   Id du fournisseur
--
--  VALEUR RETOURNEE :
--     Quand le fournisseur est de type analyse : 'TRUE'
--     Sinon                                    : 'FALSE'
-----------------------------------------------------------------     
FUNCTION get_is_vendor_analyse ( 
    pn_vendor_id IN NUMBER
    ) 
    RETURN VARCHAR2;
                           
END DKA_AP_TOOLS_PKG; -- Spécification du package
/

SHOW ERRORS
EXIT;

