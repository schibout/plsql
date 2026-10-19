--------------------------------------------------------------------------------
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_REDACTEUR_V.vue
-- Description      : Création de la vue DKA_REDACTEUR_V
-- Auteur           : S.NIKMAOUI (Capgemini)
-- Date de création : 07/12/2018
-- Doc. associée    :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
--
--------------------------------------------------------------------------------
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_REDACTEUR_V
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA_REDACTEUR_V AS
select distinct PAPF.FULL_NAME FULL_NAME, PRLA.created_by person_id
											from PER_ALL_PEOPLE_F PAPF, PO_REQUISITION_LINES_ALL PRLA
											where PAPF.person_id = PRLA.created_by order by 1;													
/													
SHOW ERRORS VIEW DKA_REDACTEUR_V
EXIT