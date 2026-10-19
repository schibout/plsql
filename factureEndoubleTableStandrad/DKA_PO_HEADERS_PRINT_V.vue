------------------------------------------------------------------------------------
-- $Id: DKA_AP_INV_APRVL_HIST_N1.ind 488 2008-04-16 15:55:24Z CORP\jjardez $
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_AP_INV_APRVL_HIST_N1.ind
-- DESCRIPTION       : Création de l'index DKA_AP_INV_APRVL_HIST_N1
---
--- AUTEUR           : Julien JARDEZ (Capgemini)
--- DATE DE CREATION : 16/04/2008
--- DOC. ASSOCIEE    : 
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user schema
--                     en lui passant en parametre :
--                            1) Tablespace de stockage de l'index
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
--- 2016/07/05 JJA Portage Helios R12
------------------------------------------------------------------------------------

CONNECT &&1/&&2

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DE INDEX DKA_AP_INV_APRVL_HIST_N1
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX DKA_AP_INV_APRVL_HIST_N1;


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_AP_INV_APRVL_HIST_N1
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
create index DKA_AP_INV_APRVL_HIST_N1 on DKA.DKA_AP_INV_APRVL_HIST_ALL (INVOICE_ID)
TABLESPACE &&3;


EXIT;

