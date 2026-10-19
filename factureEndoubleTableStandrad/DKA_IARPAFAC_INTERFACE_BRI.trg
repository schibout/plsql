------------------------------------------------------------------------------------
-- $Id: DKA_SEND_NOTIF_S.seq 262 2007-09-18 07:42:09Z NORDEST\jjardez $
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SEND_NOTIF_S.seq
-- DESCRIPTION       : Création de la séquence nom_sequence
--
-- AUTEUR            : J. JARDEZ (Capgemini)
-- NOM               : DKA_SEND_NOTIF_S.seq
-- DOC. ASSOCIEE     : 
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user DKA
--                     en lui passant en paramètre :
--                            1) Password APPS
------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------------------
-- 
------------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA SEQUENCE DKA_SEND_NOTIF_S
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE SEQUENCE DKA_SEND_NOTIF_S
INCREMENT BY 1
START WITH 1 ;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON DKA_SEND_NOTIF_S TO APPS WITH GRANT OPTION;


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&1

DROP SYNONYM DKA_SEND_NOTIF_S;
CREATE SYNONYM DKA_SEND_NOTIF_S FOR dka.DKA_SEND_NOTIF_S;


EXIT;
