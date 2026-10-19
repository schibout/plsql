----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_IARPAFAC_TASKS_V.vue
-- DESCRIPTION	    : Création de la vue DKA_IARPAFAC_TASKS_V
--
-- AUTEUR           : Xavier Descamps (CGEY)
-- DATE DE CREATION : 20/01/2004
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_IARPAFAC_TASKS_V
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA_IARPAFAC_TASKS_V
(task_code,
 description
)
AS
SELECT pt.task_number,
         pt.description
FROM  pa_projects_all ppa, 
      pa_tasks pt,
      (SELECT MIN (gps.end_date) gl_date,hou.organization_id
        FROM gl_period_statuses gps,
             hr_operating_units hou,
             PER_SECURITY_PROFILES_V PSP, 
             PER_SECURITY_ORGANIZATIONS_V PSO
        WHERE 1=1
        AND gps.set_of_books_id = hou.set_of_books_id 
        and hou.organization_id = PSO.organization_id
        AND PSO.SECURITY_PROFILE_ID = PSP.SECURITY_PROFILE_ID
        AND sysdate BETWEEN NVL(hou.date_from, sysdate) AND NVL(hou.date_to, sysdate)
        AND PSP.SECURITY_PROFILE_ID = FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL')
        AND gps.application_id = 222
        AND gps.closing_status = 'O'
        GROUP BY hou.organization_id) periods
WHERE ppa.project_id = pt.project_id
AND ppa.template_flag = 'N'
AND ppa.project_type != 'REFAC'
AND ppa.org_id = periods.organization_id
AND periods.gl_date BETWEEN ppa.start_date AND Nvl(fnd_date.canonical_to_date (ppa.attribute7), periods.gl_date);

SHOW ERROR

EXIT
