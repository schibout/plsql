CREATE OR REPLACE PACKAGE DKA_PA_TOOLS_PKG AS
----------------------------------------------------------------------------------------------
-- $Id$
--
-- NOM               : DKA_PA_TOOLS_PKG.pks
-- DESCRIPTION       : DKA_PA_TOOLS_PKG package spec : fonctions communes
---
--- AUTEUR           : J.JARDEZ
--- DATE DE CREATION : 16/03/2016
--- DOC. ASSOCIEE    :
---
----------------------------------------------------------------------------------------------
--- NOM DU PROGRAMME :
--- PARAMETRES       :
---
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  16/03/2016 JJA Portage Helios 2016
--  06/10/2016 JPE Ajout de la fonction pa_insert_event_2
--  06/10/2016 NBO Ajout de la fonction get_class_project et get_parent_project
--  19/10/2016 OBE Ajout du parametre pv_event_attribute7 dans la procédure pa_insert_event2
--  20/10/2016 OBE pa_insert_event2 renommé en pa_insert_event
--------------------------------------------------------------------------------------------
-----------------------------------------------------------------
--  Variables globales
-----------------------------------------------------------------
    gv_debug_mode        VARCHAR2 (1);

-------------------------------------------------------------------------------------------------------------------
--  Nom           : PA_CHECK_TRANSACTION_DATA
--  Description   : Vérification de cohérence des données saisies sur projet
--
--  PARAMETRES    :
--    pv_errbuf           varchar2
--    pn_retcode          number
--    pn_project_id       number
--    pv_segment1         varchar2
--    pv_expenditure_type varchar2
--    pv_event_type       varchar2
--    pd_date             date
--
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE pa_check_transaction_data (
        pv_errbuf             OUT      VARCHAR2,
        pn_retcode            OUT      NUMBER,
        pn_project_id         IN       NUMBER DEFAULT NULL,
        pn_tache_id           IN       NUMBER DEFAULT NULL,
        pv_expenditure_type   IN       VARCHAR2 DEFAULT NULL,
        pb_no_test_type_evt   IN       BOOLEAN  DEFAULT FALSE,
        pv_event_type         IN       VARCHAR2 DEFAULT NULL,
        pd_date               IN       DATE
    );

----------------------------------------------------------------------------------------
--  Nom           : PA_AA_RUN_FUNCTION_TRANSACTION
--  Description   : Procédure permettant d'executer
--                  une fonction d'autoaccounting
--  PARAMETRES :
--    pn_org_id         Entrée
--    pv_segment1       Sortie
--    pn_project_id     Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
----------------------------------------------------------------------------------------
    PROCEDURE pa_aa_run_function_transaction (
        pv_function_code               IN       VARCHAR2,
        pv_function_transaction_code   IN       VARCHAR2,
        pv_segment1                    OUT      VARCHAR2,
        pv_segment2                    OUT      VARCHAR2,
        pv_segment3                    OUT      VARCHAR2,
        pv_segment4                    OUT      VARCHAR2,
        pv_segment5                    OUT      VARCHAR2,
        pv_segment6                    OUT      VARCHAR2,
        pv_segment7                    OUT      VARCHAR2,
        pv_segment8                    OUT      VARCHAR2,
        pv_segment9                    OUT      VARCHAR2,  -- PHENIX 2004: Ajout.
        pv_segment10                   OUT      VARCHAR2,  -- PHENIX 2004: Ajout.
        pv_segment11                   OUT      VARCHAR2,  -- PHENIX 2004: Ajout.
        pv_segment12                   OUT      VARCHAR2,  -- PHENIX 2004: Ajout.
        pv_expenditure_type            IN       VARCHAR2 DEFAULT NULL, -- Par 03
        pv_organization_name           IN       VARCHAR2 DEFAULT NULL, -- Par 06
        pv_revenue_category            IN       VARCHAR2 DEFAULT NULL, -- Par 07
        pv_event_type                  IN       VARCHAR2 DEFAULT NULL, -- Par 19
        pn_project_id                  IN       NUMBER DEFAULT NULL, -- Par 24
        pn_event_num                   IN       NUMBER DEFAULT NULL, -- Par 33
        pn_task_id                     IN       NUMBER DEFAULT NULL, -- Par 26        
        pv_errbuf                      OUT      VARCHAR2,
        pn_retcode                     OUT      NUMBER
    ) ;


 -------------------------------------------------------------------------------------
 --  Nom           : pa_insert_event2
 --  Description   :insérer un évenement dans la table standard PA_EVENTS sans etre dans un contexte particulier.
 --
 --  PARAMETRES    : pv_event_type      Entrée
 --                  pn_amont           Entrée
 --                  pn_project_id      Entrée
 --                  pd_completion_date Entrée
 --
 --  VALEUR RETOURNEE :
 --     Description       : pv_errbuf,pn_result
 --     Valeurs possibles :
 ------------------------------------------------------------------------------------
    PROCEDURE pa_insert_event (
        pn_task_id                 IN       NUMBER DEFAULT NULL, 
        pv_event_type              IN       VARCHAR2,
        pn_amount                  IN       NUMBER,
        pn_project_id              IN       NUMBER,
        pd_completion_date         IN       DATE,
        pn_group_id                IN       NUMBER DEFAULT NULL,
        pv_insert_revenue_flag     IN       VARCHAR2 DEFAULT 'N',
        pv_insert_into_gl          IN       VARCHAR2 DEFAULT 'Y',
        pn_unbilled_ccid           IN       NUMBER DEFAULT NULL,
        pv_batch_name              IN       VARCHAR2 DEFAULT 'XXX',
        pv_description             IN       VARCHAR2 DEFAULT NULL,
        pn_ccid                    IN       NUMBER DEFAULT NULL,
        pv_event_attr_context      IN       VARCHAR2 DEFAULT NULL,
        pv_event_attribute1        IN       VARCHAR2 DEFAULT NULL,
        pv_event_attribute2        IN       VARCHAR2 DEFAULT NULL, 
        pv_event_attribute3        IN       VARCHAR2 DEFAULT NULL,
        pv_event_attribute4        IN       VARCHAR2 DEFAULT NULL,
        pv_event_attribute5        IN       VARCHAR2 DEFAULT NULL,
        pv_event_attribute7        IN       VARCHAR2 DEFAULT NULL,    -- OBE
		pv_event_attribute8        IN       VARCHAR2 DEFAULT NULL,
        pn_event_organization_id   IN       NUMBER DEFAULT NULL,
        pn_org_id                  IN       NUMBER DEFAULT NULL,
        pv_errbuf                  OUT      VARCHAR2,
        pn_result                  OUT      NUMBER
    );

-------------------------------------------------------------------------------------------------------------------
--  Nom           : PA_GET_INFO_TASK
--  Description   : Récupération des informations relative a la tache en parametre
--
--  PARAMETRES    :
--    pv_errbuf           varchar2
--    pn_retcode          number
--    pv_task_number      varchar2
--    pv_task_id          number
--    pv_segment1         varchar2
--    pn_project_id       varchar2
--    pv_project_name     varchar2
--    pv_project_type     varchar2
--    pd_start_date       date
--    pd_completion_date  date
--    pd_closed_date      date
--    pv_org_projet       varchar2
--    pv_org_projet_id       number
--    pv_societe          varchar2
--    pv_region           varchar2
--    pv_org_fin          varchar2
--    pv_org_fin_id       number
--
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE pa_get_info_task (
        pv_errbuf             OUT      VARCHAR2,
        pn_retcode            OUT      NUMBER,
        pv_task_number        IN       VARCHAR2,
        pv_task_id            OUT      NUMBER,
        pn_project_id         OUT      VARCHAR2,  
        pv_project_name       OUT      VARCHAR2,  
        pv_project_type       OUT      VARCHAR2,  
        pd_start_date         OUT      DATE,      
        pd_completion_date    OUT      DATE,      
        pd_closed_date        OUT      DATE,      
        pv_org_projet         OUT      VARCHAR2,
        pv_org_projet_id      OUT      NUMBER,  
        pv_societe            OUT      VARCHAR2,  
        pv_region             OUT      VARCHAR2,  
        pv_org_fin            OUT      VARCHAR2,  
        pv_org_fin_id         OUT      NUMBER
        );
		
	----------------------------------------------------------------------------------------
--  Nom           : PA_GET_CODE_Z_REFAC
--  Description   : Procédure permettant de déterminer le code projet de Refac
--                  correspondant au couple société/centre de gestion
----------------------------------------------------------------------------------------
    PROCEDURE pa_get_code_z_refac (
        pn_org_id           IN       NUMBER DEFAULT NULL,
        pv_societe          IN       VARCHAR2 DEFAULT NULL,
        pv_centre_gestion   IN       VARCHAR2,
        pv_segment1         OUT      VARCHAR2,
        pn_project_id       OUT      NUMBER,
        pv_project_name     OUT      VARCHAR2,
        pv_errbuf           OUT      VARCHAR2,
        pn_retcode          OUT      NUMBER
    );

-------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_PROJECT_INFO
--  Description   : Récupération d'informations du projet
--
--  PARAMETRES    :
--      pv_errbuf               VARCHAR2
--      pn_retcode              NUMBER
--      pn_project_id           NUMBER
--      pv_project_segment1     VARCHAR2
--  VALEUR RETOURNEE :
--     Description       : Unité opérationnelle du projet
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_project_info (
        pv_errbuf             OUT      VARCHAR2,
        pn_retcode            OUT      NUMBER,
        pn_project_id         IN       NUMBER DEFAULT NULL,
        pv_project_segment1   IN       VARCHAR2 DEFAULT NULL,
        pv_project_soc        OUT      VARCHAR2, 
        pv_project_type       OUT      VARCHAR2
    );

----------------------------------------------------------------------------------------
--  Nom           : PA_RUN_ACCOUNTING_RULE
--  Description   : Procédure permettant d'executer
--                  une regle d'autoaccounting
--  PARAMETRES :
--    pn_org_id         Entrée
--    pv_segment1       Sortie
--    pn_project_id     Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
----------------------------------------------------------------------------------------
    PROCEDURE pa_run_accounting_rule (
        pn_rule_id             IN       NUMBER DEFAULT NULL,
        pv_rule_name           IN       VARCHAR2 DEFAULT NULL,
        pv_expenditure_type    IN       VARCHAR2 DEFAULT NULL, -- Par 03
        pv_organization_name   IN       VARCHAR2 DEFAULT NULL, -- Par 06
        pv_revenue_category    IN       VARCHAR2 DEFAULT NULL, -- Par 07
        pv_event_type          IN       VARCHAR2 DEFAULT NULL, -- Par 19
        pn_project_id          IN       NUMBER DEFAULT NULL, -- Par 24
        pn_event_num           IN       NUMBER DEFAULT NULL, -- Par 33
        pv_segment_value       OUT      VARCHAR2,
        pv_errbuf              OUT      VARCHAR2,
        pn_retcode             OUT      NUMBER
    );

    PRAGMA RESTRICT_REFERENCES (pa_run_accounting_rule, WNDS);
    
---------------------------------------------------------------------------------------------------------------------
--  Nom           : get_centre_finance
--  Description   : F(vonction utilisée pour retourner l'appartenance du projet sur une période
--
--  PARAMETRES :
--      pn_project_id                   Entrée
--  pd_date             Entrée
--  VALEUR RETOURNEE :
--     Description       : Societé
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_centre_finance (
        fn_project_id   IN   NUMBER,
        fd_date         IN   DATE
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (get_centre_finance, WNDS);
      
---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_APPART
--  Description   : Fonction utilisée pour retourner l'appartenance du projet sur une période
--
--  PARAMETRES :
--      pn_project_id                   Entrée
--  pd_date             Entrée
--  VALEUR RETOURNEE :
--     Description       : Societé
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_appart (
        fn_project_id   IN   NUMBER,
        fd_date         IN   DATE
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (get_appart, WNDS);
    
---------------------------------------------------------------------------------------------------------------------
--  Nom           : get_class_project
--  Description   : Fonction utilisée pour retourner la valeur de la classe du project du projet sur une p,riode
--
--  PARAMETRES :
--  fn_project_id                 Entrée
--  fv_class_category             Entrée
--  VALEUR RETOURNEE :
--     Description       : Class Code
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
FUNCTION get_class_project(fn_project_id     IN NUMBER,
                           fv_class_category IN VARCHAR2) RETURN VARCHAR2;

PRAGMA RESTRICT_REFERENCES (get_class_project, WNDS);

---------------------------------------------------------------------------------------------------------------------
--  Nom           : get_parent_project
--  Description   : Fonction utilisée pour retourner le parent du projet avec sa tâche
--
--  PARAMETRES :
--  fn_task_id                 Entrée
--  VALEUR RETOURNEE :
--     Description       : Code projet
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
FUNCTION get_parent_project(fn_task_id IN NUMBER) RETURN VARCHAR2;

PRAGMA RESTRICT_REFERENCES (get_class_project, WNDS);  

-------------------------------------------------------------------------------------------------------------------
--  Nom           : PA_GET_PROJECT_TASK
--  Description   : Récupération des informations sur la tâche d'un projet
--
--  PARAMETRES    :
--    pv_errbuf       varchar2
--    pn_retcode      number
--    pn_project_id   number
--    pv_segment1     varchar2
--    pn_task_id      number
--    pv_task_number  varchar2
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE pa_get_project_task (
        pv_errbuf        OUT      VARCHAR2,
        pn_retcode       OUT      NUMBER,
        pn_project_id    IN       NUMBER DEFAULT NULL,
        pv_segment1      IN       VARCHAR2 DEFAULT NULL,
        pn_task_id       OUT      NUMBER,
        pv_task_number   OUT      VARCHAR2
    );
    
-------------------------------------------------------------------------------------------------------------------
--  Nom           : PA_GET_PERIOD
--  Description   : Récupération des informations sur la période PA d'un événement
--
--  PARAMETRES    :
--    pv_errbuf       varchar2
--    pn_retcode      number
--    pn_project_id   number
--    pv_segment1     varchar2
--    pn_task_id      number
--    pv_task_number  varchar2
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
  PROCEDURE pa_get_period(pv_errbuf      OUT VARCHAR2,
                          pn_retcode     OUT NUMBER,
                          pd_event_date  IN DATE DEFAULT NULL,
                          pd_gl_date     IN DATE DEFAULT NULL,
                          pn_org_id      IN NUMBER DEFAULT NULL,
                          pd_start_date  OUT DATE,
                          pd_end_date    OUT DATE,
                          pd_pa_date     OUT DATE,
                          pv_period_name OUT VARCHAR2);
    
END DKA_PA_TOOLS_PKG; -- Spécification du package
/
SHOW ERRORS
EXIT;
