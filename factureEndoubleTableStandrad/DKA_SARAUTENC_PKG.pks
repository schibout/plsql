------------------------------------------------------------------------------------
-- $Id: DKA_PO_REQUISITION_LINES_N1.ind 149 2008-03-12 16:52:16Z NORDEST\tbonduae $
-- Capgemini
-- PROJET            : VEOLIA Oracle Applications
-- NOM               : DKA_PO_REQUISITION_LINES_N1.ind
-- DESCRIPTION       : Création de l'index DKA_PO_REQUISITION_LINES_N1
---
--- AUTEUR           : Jonathan Dequidt (Capgemini)
--- DATE DE CREATION : 27/02/2008
--- DOC. ASSOCIEE    : 
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user schema
--                     en lui passant en paramètre :
--                            1) Tablespace de stockage de l’index
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
---
------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE L'INDEX DKA_PO_REQUISITION_LINES_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX DKA_PO_REQUISITION_LINES_N1;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L'INDEX DKA_PO_REQUISITION_LINES_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX DKA_PO_REQUISITION_LINES_N1
ON PO.PO_REQUISITION_LINES_ALL (VENDOR_SITE_ID)
TABLESPACE &1
PCTFREE    10
INITRANS   11
MAXTRANS   255
STORAGE
  (INITIAL     8M
   NEXT        8M
   MINEXTENTS  1
   MAXEXTENTS  UNLIMITED
   PCTINCREASE 0);

EXIT
