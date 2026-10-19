--------------------------------------------------------------------------------
-- $Id: DROP_OBJET.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : DROP_OBJET.sql
-- Description      : Suppression de l'ensemble des objets créés par le spécifique
-- Auteur           : Benjamin COUDRIER
-- Date de création : 15/09/2014
-- Doc. associée    :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur DKA en 
--                    passant en paramètres
--                    1- Login XXEAI
--                    2- Password XXEAI
--
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 02/12/2014 BCO DPE20140088 - Ajout des outils d'interface pour AP
--------------------------------------------------------------------------------


PROMPT ======================================
PROMPT Suppression des TYPES existants
PROMPT ======================================
PROMPT
PROMPT !!!*** NE PAS TENIR COMPTE DES MESSAGES INDIQUANT : ***!!!
PROMPT !!!***   ORA-04043: object XXXXXX does not exist    ***!!!
PROMPT

-- SUPPRESSION DES OBJETS GL. --
DROP TYPE XXEAI_CLE_COMPTABLE_CUF_LST
/
DROP TYPE XXEAI_CLE_COMPTABLE_CUF_TAB
/
DROP TYPE XXEAI_CLE_COMPTABLE_CUF_OBJ
/
DROP TYPE XXEAI_IN_TYP_EVT_DEP_TAB
/
DROP TYPE XXEAI_IN_TYP_EVT_DEP_TYP
/
DROP TYPE XXEAI_CST_FLUX_GL_OBJ
/
DROP TYPE XXEAI_INFO_CLE_TAB
/
DROP TYPE XXEAI_INFO_CLE_TYP
/
DROP TYPE XXEAI_PROJET_TAB
/
DROP TYPE XXEAI_SOCIETE_LST
/
DROP TYPE XXEAI_SOCIETE_TAB
/
DROP TYPE XXEAI_SOCIETE_OBJ
/
DROP TYPE XXEAI_TYP_EVT_DEP_LST
/
DROP TYPE XXEAI_TYP_EVT_DEP_TAB
/
DROP TYPE XXEAI_TYP_EVT_DEP_OBJ
/

-- SUPPRESSION DES OBJETS AP. --
DROP TYPE XXEAI_CST_FLUX_AP_OBJ
/
DROP TYPE XXEAI_IN_INVOICE_HEADER_TAB
/
DROP TYPE XXEAI_IN_INVOICE_HEADER_TYP
/
DROP TYPE XXEAI_IN_INVOICE_LINE_TAB
/
DROP TYPE XXEAI_IN_INVOICE_LINE_TYP
/
DROP TYPE XXEAI_INFO_INVOICE_HEADER_LST
/
DROP TYPE XXEAI_INFO_INVOICE_HEADER_TAB
/
DROP TYPE XXEAI_INFO_INVOICE_HEADER_OBJ
/
DROP TYPE XXEAI_INFO_INVOICE_LINE_LST
/
DROP TYPE XXEAI_INFO_INVOICE_LINE_TAB
/
DROP TYPE XXEAI_INFO_INVOICE_LINE_OBJ
/
DROP TYPE XXEAI_INVOICE_ID_LST
/
DROP TYPE XXEAI_INVOICE_ID_TAB
/
DROP TYPE XXEAI_INVOICE_ID
/
DROP TYPE XXEAI_TYPE_ENTETE_LIGNE_TAB
/
DROP TYPE XXEAI_IN_LIGNE_MVT_AR_TYP
/
DROP TYPE XXEAI_TYPE_AR_OBJ
/
DROP TYPE XXEAI_TYPE_INFO_REGION_OBJ
/

EXIT;