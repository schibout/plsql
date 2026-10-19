--------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_WF_NOTIFICATIONS_N9.ind
-- DESCRIPTION	     : Création index sur table WF_NOTIFICATIONS 
--                     pour optimisation
--
-- AUTEUR            : IBA
-- DATE DE CREATION  : 10/11/2022
-- DOC. ASSOCIEE     :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DE INDEX APPLSYS.DKA_WF_NOTIFICATIONS_N9
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX APPLSYS.DKA_WF_NOTIFICATIONS_N9;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX APPLSYS.DKA_WF_NOTIFICATIONS_N9
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
create index APPLSYS.DKA_WF_NOTIFICATIONS_N9 on APPLSYS.WF_NOTIFICATIONS (MESSAGE_NAME,MESSAGE_TYPE);
  
  
EXIT;
