--------------------------------------------------------------------------------
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_DEMANDEUR_V.vue
-- Description      : Création de la vue DKA_DEMANDEUR_V
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
PROMPT CREATION DE LA VUE DKA_DEMANDEUR_V
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA_DEMANDEUR_V AS
select distinct PAPF.FULL_NAME FULL_NAME, PRLA.to_person_id person_id
											from PER_ALL_PEOPLE_F PAPF, PO_REQUISITION_LINES_ALL PRLA
											where PAPF.person_id = PRLA.to_person_id order by 1;													
/													
SHOW ERRORS VIEW DKA_DEMANDEUR_V
EXIT