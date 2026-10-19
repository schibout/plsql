  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : dka_task_ic.VUE
  -- Nom              : dka_task_ic.VUE
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
create or replace view dka_task_ic as
select pt.Task_number, pt.Task_name,  pt.task_id, pda.po_header_id, pha.segment1, hou.name,PDA.PO_DISTRIBUTION_ID
from PA_TASKS pt, PO_DISTRIBUTIONS_ALL PDA, pa_projects_all pp, po_headers_all pha, hr_organization_units hou
where pt.task_name not like '%REFAC%'
and nvl(pt.completion_date,sysdate+1) > sysdate
and pt.creation_date <=sysdate
and pt.TASK_ID = PDA.TASK_ID
--and PDA.PO_DISTRIBUTION_ID=:$FLEX$.DKA_PO_LIGNE_IC
and pp.project_id=pt.project_id
and pp.template_flag <>'Y'
and pha.po_header_id =pda.po_header_id
--and pda.po_header_id=998033
--and pda.org_id=90
and pda.org_id=organization_id
and pha.org_id=organization_id;	

/													
SHOW ERRORS VIEW dka_task_ic
EXIT
