  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_PO_LIGNE_IVALUA.VUE
  -- Nom              : DKA_PO_LIGNE_IVALUA.VUE
  -- Description      : Création des vues
  -- Auteur           : SELO
  -- Date de création : 17/07/2020
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 
create or replace view DKA_PO_LIGNE_IVALUA as
select PLA.line_num||'.'||PLLA.SHIPMENT_NUM||'.'||PDA.DISTRIBUTION_NUM num_ligne,
PO_DISTRIBUTION_ID num_id,
task.task_number||'_'||PDA.expenditure_type tache_depense,
pha.po_header_id
from PO.PO_DISTRIBUTIONS_ALL PDA, PA_TASKS TASK, PO.PO_LINE_LOCATIONS_ALL PLLA, PO.PO_LINES_ALL PLA, PO.PO_HEADERS_ALL PHA
where TASK.TASK_ID = PDA.TASK_ID
	and PLLA.LINE_LOCATION_ID = PDA.LINE_LOCATION_ID
	and PLA.PO_LINE_ID = PDA.PO_LINE_ID
	and PHA.PO_HEADER_ID = PDA.PO_HEADER_ID   
 -- and PHA.PO_HEADER_ID= :$FLEX$.DKA_PO_NUM_VALIDE
 -- and PHA.PO_HEADER_ID= 989032  -- segment1 = 4755242
    and nvl(pla.CLOSED_CODE,'A') not in ('CLOSED','FINALLY CLOSED')
    and PLA.CANCEL_FLAG <> 'Y';

/													
SHOW ERRORS VIEW DKA_PO_LIGNE_IVALUA
EXIT
