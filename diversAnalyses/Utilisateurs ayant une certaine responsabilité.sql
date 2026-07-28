SELECT
  fu.user_name Matricule,
  fu.description Utilisateur,
  --fu.end_date,
  resp.responsibility_name Responsabilite,
  afct.start_date Debut_affect,
  afct.end_date Fin_affect
from FND_USER_RESP_GROUPS_DIRECT afct,
     FND_RESPONSIBILITY_TL resp,
     FND_USER fu
where 1=1
and afct.user_id = fu.user_id
--and fu.user_name = 'ABDELMOUMENEK'
and Afct.Responsibility_Id = Resp.Responsibility_Id
and (fu.end_date is null or fu.end_date > sysdate)
--and upper(resp.responsibility_name) like '%CONTRAT_SOUS-TRAITANCE%'
and resp.APPLICATION_ID = 201
and (Afct.End_Date is null or Afct.End_Date > sysdate)
--and trunc(Afct.End_Date) < '18/07/2017'
order by fu.user_name
;

select *
from FND_RESPONSIBILITY_TL
where upper(responsibility_name) like '%TOUT%PO%'
;