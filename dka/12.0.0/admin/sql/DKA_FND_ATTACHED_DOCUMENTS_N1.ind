--------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_FND_ATTACHED_DOCUMENTS_N1.ind
-- DESCRIPTION	     : Création index sur table std FND_ATTACHED_DOCUMENTS 
--                     pour optimisation
--
-- AUTEUR            : CDE
-- DATE DE CREATION  : 28/06/2007
-- DOC. ASSOCIEE     :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DE INDEX DKA_FND_ATTACHED_DOCUMENTS_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX APPLSYS.DKA_FND_ATTACHED_DOCUMENTS_N1;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_FND_ATTACHED_DOCUMENTS_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX APPLSYS.DKA_FND_ATTACHED_DOCUMENTS_N1 
ON APPLSYS.FND_ATTACHED_DOCUMENTS 
(ENTITY_NAME
,PK1_VALUE)
  tablespace APPLSYSX
  pctfree 10
  initrans 11
  maxtrans 255
  storage
  (
    initial 16K
    next 1M
    minextents 1
    maxextents unlimited
    pctincrease 0
  );

EXIT;
