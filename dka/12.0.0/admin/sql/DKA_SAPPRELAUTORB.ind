------------------------------------------------------------------------------------
-- $Id: DKA_SPOFUSION_DISTRIBS_TMP.ind $
-- Capgemini
-- PROJET            : DALKIA
-- NOM               : DKA_SAPPRELAUTORB.ind
-- DESCRIPTION       : Création des index pour l'EDB338
---
--- AUTEUR           : Anas RAOUF (Capgemini)
--- DOC. ASSOCIEE    : 
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user schema
--                     en lui passant en paramètre :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur DKA en 
--                    passant en paramètres
--                    1- Password APPS
--                    2- Tablespace des index pour le schéma APPLSYSX
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
---
------------------------------------------------------------------------------------

CONNECT APPS/&1

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DE INDEX AP.DKA_AP_INVOICES_ALL_N22
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX AP.DKA_AP_INVOICES_ALL_N22;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DE INDEX AP.DKA_AP_INVOICES_ALL_N23
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX AP.DKA_AP_INVOICES_ALL_N23;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DE INDEX AP.DKA_AP_INVOICES_ALL_N24
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX AP.DKA_AP_INVOICES_ALL_N24;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DE INDEX AP.DKA_AP_INVOICES_ALL_N25
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX AP.DKA_AP_INVOICES_ALL_N25;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++




PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX AP.DKA_AP_INVOICES_ALL_N22 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX AP.DKA_AP_INVOICES_ALL_N22 ON AP.AP_INVOICES_ALL (SOURCE) TABLESPACE &2 ;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_IPOCDE_REPORT_HEADERS_N1  
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX AP.DKA_AP_INVOICES_ALL_N23 ON AP.AP_INVOICES_ALL (DESCRIPTION) TABLESPACE &2 ;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_IPOCDE_REPORT_HEADERS_N1  
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX AP.DKA_AP_INVOICES_ALL_N24 ON AP.AP_INVOICES_ALL (ATTRIBUTE9) TABLESPACE &2 ;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_IPOCDE_REPORT_HEADERS_N1  
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX AP.DKA_AP_INVOICES_ALL_N25 ON AP.AP_INVOICES_ALL (INVOICE_TYPE_LOOKUP_CODE) TABLESPACE &2 ;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

EXIT
