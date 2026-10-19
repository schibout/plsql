------------------------------------------------------------------------------------
-- $Id: DKA_AP_INV_APRVL_HIST_S.seq 488 2008-04-16 15:55:24Z CORP\jjardez $
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_AP_INV_APRVL_HIST_S.seq
-- DESCRIPTION       : Création de la séquence DKA_AP_INV_APRVL_HIST_S
--
-- AUTEUR            : Julien JARDEZ (Capgemini)
-- DATE DE CREATION  : 16/04/2008
-- DOC. ASSOCIEE     : 
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user DKA
--                     en lui passant en parametre :
--                            1) Password APPS
------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------------------
-- 2016/07/05 JJA Portage Helios R12
------------------------------------------------------------------------------------

CONNECT &&1/&&2

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LA SEQUENCE DKA_AP_INV_APRVL_HIST_S
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP SEQUENCE DKA_AP_INV_APRVL_HIST_S;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA SEQUENCE DKA_AP_INV_APRVL_HIST_S
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE SEQUENCE DKA_AP_INV_APRVL_HIST_S
INCREMENT BY 1
START WITH 1 ;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON DKA_AP_INV_APRVL_HIST_S TO &&3 WITH GRANT OPTION;


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT &&3/&&4

DROP SYNONYM DKA_AP_INV_APRVL_HIST_S;
CREATE SYNONYM DKA_AP_INV_APRVL_HIST_S FOR &&1..DKA_AP_INV_APRVL_HIST_S;


EXIT;
