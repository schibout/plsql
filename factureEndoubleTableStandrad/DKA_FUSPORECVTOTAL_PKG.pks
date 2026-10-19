-------------------------------------------------------------------------------
-- CAP GEMINI
-- Projet : DALKIA Oracle Applications
-- Auteur : 
-- Date Création : 
-- Version livrables : 
--------------------------------------------------------------------------------
-- NOM : DKA_FRAIS_PORT.vue
-- DESCRIPTION : 
-- COMMENTAIRE      : 
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 16/11/2007 ADR ETANCHEITE DALKIA 2007
-- 02/02/2017 MEG artf2092860 : DEFECT 500 - GESTION DES FRAIS DE PORT
--------------------------------------------------------------------------------------------
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_SPOPARAM_FRAIS_PORT_V
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CONNECT APPS/&2;

create or replace view DKA_SPOPARAM_FRAIS_PORT_V as
  select 
         pv.Vendor_name,
         dsfp.type,
         dsfp.seuil,
         dsfp.montant,
         dsfp.vendor_id      
    from po_vendors pv,
         dka_spoparam_frais_port dsfp
    where pv.vendor_id   = dsfp.vendor_id 
    --and   dsfp.org_id    = to_number(decode(substrb(userenv('CLIENT_INFO'),1,1),' ',null,substrb(userenv('CLIENT_INFO'),1,10)))
    ;

SHOW ERRORS

EXIT

    
    
  
