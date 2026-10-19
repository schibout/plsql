--------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_MTL_SYSTEM_ITEMS_INTERF_N1
-- DESCRIPTION	     : Création index sur table std MTL_SYSTEM_ITEMS_INTERFACE 
--                     pour optimisation
--
-- AUTEUR            : CDE
-- DATE DE CREATION  : 21/02/2019
-- DOC. ASSOCIEE     :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DE INDEX DKA_MTL_SYSTEM_ITEMS_INTERF_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX INV.DKA_MTL_SYSTEM_ITEMS_INTERF_N1;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_MTL_SYSTEM_ITEMS_INTERF_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX INV.DKA_MTL_SYSTEM_ITEMS_INTERF_N1 
ON INV.MTL_SYSTEM_ITEMS_INTERFACE (ORGANIZATION_ID, SEGMENT1, SEGMENT2)
  tablespace APPS_TS_TX_DATA
  pctfree 10
  initrans 11
  maxtrans 255
  storage
  (
    initial 128K
    next 128K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );
  
  
EXIT;
