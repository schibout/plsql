CREATE OR REPLACE PACKAGE BODY DKA_ICODEPROJET_PKG IS

    ----------------------------------------------------------------------
    -- PROGRAM : DKA_ICODEPROJET_PKG.sql                                 -
    -- Version : 1.0                                                     -
    -- AUTEUR  : Y.Warid / SOCIETE : CAPGEMINI                           -
    -- DATE    : 16/08/16                                                -
    ----------------------------------------------------------------------
    -- APPELE PAR : Import des projets dans PA                       -
    -- FONCTION   : INT018                                               -
    --                                                                   -
    --                                                                   -
    ----------------------------------------------------------------------
    -- VER  Quand       QUI Commentaires
    -- 1.1  14/12/2016  PBR artf2064984 (alimentation du long_name du projet en update et en création)
    --                  PBR artf2064994 (Modification des conditions de mises à jour du centre de finance pour un projet)
    --                  PBR artf2062718 (Modification de la méthode init pour changer la récupération de la période en cours)
    -- 1.2  28/12/2016  RBE artf2069459 (Implémentation du traitement de mise mensuelle des projets (main2))
    -- 1.3  09/01/2016  YWA artf2072190 (contrôle de la date de fin de la tache erroné)
    --                  YWA artf2076305 (la recherche de la période en cours doit être restreinte aux UO définies pour la responsabilité)
    --                  YWA artf2076309 (mise à jour mensuelle ne doit traiter que les UO liées à la responsabilité SFD 2.9)
    --                  YWA artf2076741 (mise à jour mensuelle, message à modifier)
    --                  YWA artf2076737 (Nom long et description ne doivent pas être préfixés avec le code projet SFD 2.9)
    --                  YWA artf2077757 (modification des règles de dates de mise à jour mensuelle SFD 2.9)
    --                  YWA artf2076863 (centre finance: contrôle de dates incorrect SFD 2.9)
    --1.4  16/01/2017   YWA artf2080425 : INT018 : Si le projet est en statut Cloturé, aucune modification ne peut être faite via interface
    --                  YWA artf2079940 : INT018 : date début centre finance
    --                  YWA artf2076305 : INT018 : la recherche de la période en cours doit être restreinte aux UO définies pour la responsabilité
    --1.5  24/01/2017   RBE artf2089025 : INT018 - Modification alimentation du Nom long et de la Description du projet
    --1.6  25/01/2017   MEG artf2089456 : INT018 - Format de date incorrect dans les CUFs
    --1.7  20/03/2017   YWA artf2121068 : INT018 - Pb dans la gestion des lignes et dans la màj des statuts des lignes traitées
    --2.0  06/04/2017   YWA artf2131851,artf2131656,artf2131655,artf2131647,artf2131956
    --2.1  13/04/2017   YWA artf2140013
    --2.2  22/05/2017   JJA artf2152566
    --2.3  31/05/2017   JJA artf2163124 - artf2163320 - artf2164140
    --2.4  30/01/2018   OBE artf2342766 : INT018 - Mise à jour des centres finances
    --2.5  13/03/2018   OBE artf2432038 : INT018 - Import des projets - Contrôle dates de clôture/fin des projets/taches plus permissif
    --2.6  25/05/2018   OBE artf2676417 : INC0219512 : INT018 Correctifs sur l'interface des Projets
    --2.7  03/10/2019   JWY artf07314292 : INC0353775 Correctif sur la fermeture des projets sans tâche associée (INT018)
    --2.8  24/10/2019   OCL artf07318822 : INC0361018 Correctif sur le message d'erreur sur la période PA
    --2.9  10/09/2025   RTM Migration 12.2.14 - Ajout p_msg_index à l'API pa_interface_utils_pub.get_messages, et v_project_in.start_date
    ----------------------------------------------------------------------

     --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PRIVEES
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


    cv_std_date_mask                CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS'; --'YYYY-MON-DD';
    g_user_id                       fnd_user.user_id%TYPE;
    g_login_id                      fnd_logins.login_id%TYPE;
    g_org_id                        hr_all_organization_units.organization_id%TYPE;
    g_request_id                    fnd_concurrent_requests.request_id%TYPE;
    g_tempo                         NUMBER;
    g_message_erreur_cf             VARCHAR2(500)    :=null;
    g_message_erreur_prj            VARCHAR2(500)    :=null;
    g_validate_cf_err               NUMBER  :=0;
    g_validate_proj_err             NUMBER  :=0;
    g_validate_cf                   NUMBER  :=0;
    g_validate_proj                 NUMBER  :=0;
    g_task_validate                NUMBER  :=0;
    g_task_reject                NUMBER  :=0;
    g_subproject_war                NUMBER  :=0;
    g_date_controle                 VARCHAR2(30)    :=null;
    g_period_name                    VARCHAR2(30) ;
    g_start_date_en_cours           DATE;
    g_end_date_en_cours             DATE;
    g_effective_period_num                    NUMBER ;
    g_user_name                     VARCHAR2(30) ;

    --RBE
    gv_project_status_name_closed   pa_project_statuses.project_status_name%TYPE;
    gv_project_status_name_actif    pa_project_statuses.project_status_name%TYPE;
    gv_project_status_code_actif    pa_project_statuses.project_status_code%TYPE;
    gv_project_status_code_closed   pa_project_statuses.project_status_code%TYPE;
    gv_project_status_name_cloture  pa_project_statuses.project_status_name%TYPE;
    gv_project_status_code_cloture  pa_project_statuses.project_status_code%TYPE;


    /*
    *************************************************************************
    * PROCEDURE NAME : init
    *
    * DESCRIPTION
    *  Procédure d'initialisation des variables globales
    *
    * PARAMETERS
    * ==========
    * NAME              DESCRIPTION
    .* ----------------- ------------------------------------------------------
    * p_errbuf         Retour de message éventuel
    * p_retcode        Statut du traitement en sortie
    ************************************************************************
    */

    PROCEDURE init (
        p_errbuf    OUT      VARCHAR2,
        p_retcode   OUT      NUMBER
        )
    IS

        v_procedure         VARCHAR2(30);
        program_error       EXCEPTION;
        rec_param           dka_parameters%ROWTYPE;

    BEGIN

        --Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut init');


        ----------------------------------
        -- Initialisation des variables --
        ----------------------------------
        p_errbuf  := NULL;
        p_retcode := 0;
        v_procedure := 'INIT';


        ------------------------
        -- Variables globales --
        ------------------------

        g_login_id                      := fnd_global.login_id;
        g_request_id                    := fnd_global.conc_request_id;
        --g_org_id                       := fnd_profile.value ('ORG_ID');
        --g_tempo                        := 20;
        g_user_id                       :=   fnd_global.user_id;
        g_user_name                     := fnd_global.user_name ;

        dka_tools_pkg.get_parameter('ICODEPROJET',
                                    'PROJECT_STATUS_NAME_CLOSED',
                                    rec_param,
                                    p_errbuf,
                                    p_retcode);
        gv_project_status_name_closed := rec_param.varchar2_value;

        --dka_tools_pkg.put_debug_message ( gv_project_status_name_closed );
        IF p_retcode != 0 THEN
          p_errbuf := 'PROJECT_STATUS_NAME_CLOSED - ' || p_errbuf;
          RETURN;
        END IF;

        dka_tools_pkg.get_parameter('ICODEPROJET',
                                    'PROJECT_STATUS_NAME_ACTIF',
                                    rec_param,
                                    p_errbuf,
                                    p_retcode);
        gv_project_status_name_actif := rec_param.varchar2_value;

        --dka_tools_pkg.put_debug_message (gv_project_status_name_actif );
        IF p_retcode != 0 THEN
          p_errbuf := 'PROJECT_STATUS_NAME_ACTIF - ' || p_errbuf;
          RETURN;
        END IF;

        dka_tools_pkg.get_parameter('ICODEPROJET',
                                    'PROJECT_STATUS_NAME_ENCLOSED',
                                    rec_param,
                                    p_errbuf,
                                    p_retcode);
        gv_project_status_name_cloture := rec_param.varchar2_value;

        --dka_tools_pkg.put_debug_message (gv_project_status_name_cloture );
        IF p_retcode != 0 THEN
          p_errbuf := 'PROJECT_STATUS_NAME_CLOTURE - ' || p_errbuf;
          RETURN;
        END IF;

        Fnd_File.put_line (Fnd_File.LOG,'Récupération du code du status actif');
        SELECT pps.project_status_code
          INTO gv_project_status_code_actif
          FROM pa_project_statuses pps
         WHERE pps.project_status_name = gv_project_status_name_actif
           AND pps.status_type = 'PROJECT';

        Fnd_File.put_line (Fnd_File.LOG,'Récupération du code du status fermé');
        SELECT pps.project_status_code
          INTO gv_project_status_code_closed
          FROM pa_project_statuses pps
         WHERE pps.project_status_name = gv_project_status_name_closed
           AND pps.status_type = 'PROJECT';

        Fnd_File.put_line (Fnd_File.LOG,'Récupération du code du status cloturé');
        SELECT pps.project_status_code
          INTO gv_project_status_code_cloture
          FROM pa_project_statuses pps
         WHERE pps.project_status_name = gv_project_status_name_cloture
           AND pps.status_type = 'PROJECT';

        --Récupération de la période PA en cours.
        BEGIN
            /*SELECT DISTINCT period_name,start_date,end_date,effective_period_num
            INTO  g_period_name,g_start_date_en_cours,g_end_date_en_cours,g_effective_period_num
            FROM gl_period_statuses
            WHERE application_id=275
            AND period_year=EXTRACT(YEAR FROM SYSDATE)
            AND ledger_id in( SELECT ledger_id FROM   gl_access_set_ledgers  WHERE access_set_id = fnd_profile.value('GL_ACCESS_SET_ID'))
            AND SYSDATE  BETWEEN  start_date AND end_date
            AND closing_status = 'O';*/
            --artf2062718
            SELECT ppa.period_name, ppa.start_date, ppa.end_date--, gps.effective_period_num
            INTO  g_period_name,g_start_date_en_cours,g_end_date_en_cours--,g_effective_period_num
            FROM pa_periods_all ppa
            --JOIN gl_period_statuses gps ON  (ppa.period_name = gps.period_name)
            WHERE ppa.start_date = (SELECT min(start_date)
                                FROM  pa_periods_all,
                                      per_security_profiles_v psp,
                                      per_security_organizations_v pso
                                WHERE status = 'O'
                              AND pso.security_profile_id = psp.security_profile_id
                              AND psp.security_profile_id = FND_PROFILE.VALUE ('XLA_MO_SECURITY_PROFILE_LEVEL')
                              AND pso.organization_id        = org_id --YWA artf2076305
                               )--YWA artf2076305
            AND ROWNUM <2 ;--artf2072122

        EXCEPTION
            WHEN OTHERS THEN
                p_errbuf  := 'Erreur lors de la récupération de la période PA en cours (qui correspond à la période PA ouverte): ';
                p_retcode := 2;
                Fnd_File.put_line (Fnd_File.LOG,p_errbuf||sqlerrm);
                RETURN;
        END;



    EXCEPTION
        WHEN program_error THEN
             Fnd_File.put_line (Fnd_File.LOG, 'ERREUR : ' || p_errbuf);
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := v_procedure ||': '||SQLERRM;
    END init;

     /*
    *************************************************************************
    * PROCEDURE NAME : init_environement
    *
    * DESCRIPTION
    *  Procédure d'initialisation de l'environnement
    *
    * PARAMETERS
    * ==========
    * NAME              DESCRIPTION
    .* ----------------- ------------------------------------------------------
    * p_errbuf         Retour de message éventuel
    * p_retcode        Statut du traitement en sortie
    ************************************************************************
    */

    PROCEDURE init_environement (
        p_errbuf    OUT      VARCHAR2,
        p_retcode   OUT      NUMBER
        )
    IS
        v_resp_id                               NUMBER;
        v_resp_appl_id                          NUMBER;
    BEGIN

        --Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut init_environement');

        p_retcode   := 0;


        SELECT responsibility_id
              ,application_id
        INTO   v_resp_id
              ,v_resp_appl_id
        FROM  fnd_responsibility fr,
              hr_operating_units hou
        WHERE hou.organization_id = g_org_id
        AND   fr.responsibility_key = hou.name||'_PA_ADMINISTRATEUR';


        fnd_global.apps_initialize(g_user_id, v_resp_id, v_resp_appl_id);

        -- Initialiser org_id
        mo_global.set_org_context(g_org_id,NULL,'PA');
        --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin init_environement');
    EXCEPTION
        WHEN program_error THEN
             Fnd_File.put_line (Fnd_File.LOG, 'ERREUR : ' || p_errbuf);
        WHEN NO_DATA_FOUND THEN
            p_retcode   := 1;
            p_errbuf    := 'init_environement responsabilité introuvable: '||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, 'ERREUR : ' || p_errbuf ||' pour L''UO ' ||g_org_id);
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'init_environement: '||SQLERRM;

    END init_environement;

    /*=========================================================================*/
    /* PROCEDURE NAME : validate_centre_finance
    /*
    /* DESCRIPTION
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/
    PROCEDURE validate_centre_finance(  p_centre_finance         VARCHAR2
                                        ,p_erreur             BOOLEAN
                                        ,p_organization_id         hr_all_organization_units.organization_id%TYPE
                                        ,p_errbuf            OUT VARCHAR2
                                        ,p_retcode           OUT NUMBER)
    IS

    BEGIN
        --Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_centre_finance');
        IF p_erreur THEN

            g_validate_cf_err := g_validate_cf_err+1;
            BEGIN
                UPDATE dka_eai_organisation
                SET    oa_status ='REJECT',
                       oa_rejection_reason = substr(g_message_erreur_cf,1,240),
                       oa_request_id = g_request_id,
                       last_updated_by = 	g_user_id,
                       last_update_date = sysdate
                WHERE  centre_finance = p_centre_finance
                AND id IS NULL;
            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
            END;

        ELSE
            g_validate_cf := g_validate_cf+1;
            BEGIN
                UPDATE dka_eai_organisation
                SET    oa_status ='PROCESSED',
                       oa_rejection_reason = NULL,
                       oa_request_id =g_request_id,
                       id = p_organization_id,
                       last_updated_by = 	g_user_id,
                       last_update_date = sysdate
                WHERE   centre_finance = p_centre_finance
                AND id IS NULL;
            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
            END;

        END IF;
        COMMIT;
        --Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_centre_finance');
    END validate_centre_finance;


    /*=====================================================================================*/
    /* PROCEDURE NAME : create_update_flex_value
    /*
    /* DESCRIPTION
    /*  Procédure pour ajout de du centre de finance dans le jeu de valeur
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/
    PROCEDURE create_update_flex_value (p_value_set_name VARCHAR2,
        p_flex_value  VARCHAR2,
        p_code_activite VARCHAR2,
        p_description  VARCHAR2,
        p_start_date    date,
        p_end_date      date,
        p_errbuf  OUT VARCHAR2,
        p_retcode OUT NUMBER
       )
    IS

       v_enabled_flag             VARCHAR2 (2);
       v_summary_flag             VARCHAR2 (2);
       v_who_type                 FND_FLEX_LOADER_APIS.WHO_TYPE;
      -- v_value_set_name           FND_FLEX_VALUE_SETS.FLEX_VALUE_SET_NAME%TYPE;
       c_compiled_value_attributes VARCHAR2 (3) :=  'Y'||CHR(10)||'Y';
       v_start_date              VARCHAR2 (30);
       v_end_date_active         VARCHAR2 (30);
       l_hier_cpt                PLS_INTEGER;

       e_erreur_hierar EXCEPTION;

    BEGIN
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début create_update_flex_value : AUTONOMOUS_TRANSACTION');
        --v_value_set_name             :='DAOPCCF_CENTREFI';
        v_enabled_flag               := 'Y';
        v_summary_flag               := 'N';
        v_who_type.created_by        := g_user_id;
        v_who_type.creation_date     := SYSDATE;
        v_who_type.last_updated_by   := g_user_id;
        v_who_type.last_update_date  := SYSDATE;
        v_who_type.last_update_login := g_login_id;

        p_retcode := 0;

        IF p_start_date IS NOT NULL THEN
           v_start_date :=  TO_CHAR(p_start_date, 'YYYY/MM/DD HH24:MI:SS');
        ELSE
          v_start_date := p_start_date;
        END IF;

        IF p_end_date IS NOT NULL THEN
           v_end_date_active := TO_CHAR(p_end_date, 'YYYY/MM/DD HH24:MI:SS');
        ELSE
          v_end_date_active := p_end_date;
        END IF;


        fnd_flex_loader_apis.up_value_set_value
                  (p_upload_phase               => 'BEGIN',
                   p_upload_mode                => NULL,
                   p_custom_mode                => 'FORCE',
                   p_flex_value_set_name        => p_value_set_name,--v_value_set_name,
                   p_parent_flex_value_low      => NULL,
                   p_flex_value                 => p_flex_value,
                   p_owner                      => g_user_name,
                   p_last_update_date           => TO_CHAR(SYSDATE, 'YYYY/MM/DD HH24:MI:SS'),
                   p_enabled_flag               => v_enabled_flag,
                   p_summary_flag               => v_summary_flag,
                   p_start_date_active          => v_start_date,
                   p_end_date_active            => v_end_date_active,
                   p_parent_flex_value_high     => NULL,
                   p_rollup_flex_value_set_name => NULL,
                   p_rollup_hierarchy_code      => NULL,
                   p_hierarchy_level            => NULL,
                   p_compiled_value_attributes  => c_compiled_value_attributes,
                   p_value_category             => NULL,--'VALUE_SET_NAME',
                   p_attribute1                 => NULL,
                   p_attribute2                 => NULL,
                   p_attribute3                 => NULL,
                   p_attribute4                 => NULL,
                   p_attribute5                 => NULL,
                   p_attribute6                 => NULL,
                   p_attribute7                 => NULL,
                   p_attribute8                 => NULL,
                   p_attribute9                 => NULL,
                   p_attribute10                => NULL,
                   p_attribute11                => NULL,
                   p_attribute12                => NULL,
                   p_attribute13                => NULL,
                   p_attribute14                => NULL,
                   p_attribute15                => NULL,
                   p_attribute16                => NULL,
                   p_attribute17                => NULL,
                   p_attribute18                => NULL,
                   p_attribute19                => NULL,
                   p_attribute20                => NULL,
                   p_attribute21                => NULL,
                   p_attribute22                => NULL,
                   p_attribute23                => NULL,
                   p_attribute24                => NULL,
                   p_attribute25                => NULL,
                   p_attribute26                => NULL,
                   p_attribute27                => NULL,
                   p_attribute28                => NULL,
                   p_attribute29                => NULL,
                   p_attribute30                => NULL,
                   p_attribute31                => NULL,
                   p_attribute32                => NULL,
                   p_attribute33                => NULL,
                   p_attribute34                => NULL,
                   p_attribute35                => NULL,
                   p_attribute36                => NULL,
                   p_attribute37                => NULL,
                   p_attribute38                => NULL,
                   p_attribute39                => NULL,
                   p_attribute40                => NULL,
                   p_attribute41                => NULL,
                   p_attribute42                => NULL,
                   p_attribute43                => NULL,
                   p_attribute44                => NULL,
                   p_attribute45                => NULL,
                   p_attribute46                => NULL,
                   p_attribute47                => NULL,
                   p_attribute48                => NULL,
                   p_attribute49                => NULL,
                   p_attribute50                => NULL,
                   p_flex_value_meaning         => p_flex_value,
                   p_description                => p_description
                   );

        IF p_value_set_name = 'DAOPCCF_AFFAIRE' THEN

            fnd_flex_loader_apis.up_val_norm_hierarchy (p_upload_phase            => 'BEGIN',
                                                        p_upload_mode             => NULL,
                                                        p_custom_mode             => 'FORCE',
                                                        p_flex_value_set_name     => p_value_set_name,
                                                        p_parent_flex_value       => p_code_activite,--parent
                                                        p_range_attribute         => 'C',
                                                        p_child_flex_value_low    => p_flex_value,
                                                        p_child_flex_value_high   => p_flex_value,
                                                        p_owner                   => g_user_name,
                                                        p_last_update_date        => TO_CHAR (SYSDATE,'YYYY/MM/DD HH24:MI:SS'),
                                                        p_start_date_active       => v_start_date,
                                                        p_end_date_active         => v_end_date_active);
           -->artf2163124
           l_hier_cpt := SQL%ROWCOUNT;

           IF l_hier_cpt = 0 THEN
             RAISE e_erreur_hierar;
           END IF;
           --<artf2163124
        END IF;

        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin create_update_flex_value');
    EXCEPTION
      WHEN e_erreur_hierar
          THEN
            p_retcode := 1;
            p_errbuf := 'Erreur pour l''ajout dans la hierarchie de '||p_value_set_name|| ' Activité : '||p_code_activite;
            Fnd_File.put_line (Fnd_File.LOG, 'Error : ' || p_errbuf);
      WHEN OTHERS
          THEN
            ROLLBACK;
            p_errbuf := 'Error pour l''ajout dans le jeu de valeur '||p_value_set_name ||' : ' || SUBSTR (SQLERRM, 1, 1000);
            p_retcode := 1;
             --g_message_erreur_cf := 'Error pour l''ajout dans le jeu de valeur: ' || SUBSTR (SQLERRM, 1, 1000)
             Fnd_File.put_line (Fnd_File.LOG, 'Error : ' || SUBSTR (SQLERRM, 1, 1000));
    END create_update_flex_value;

    /*=====================================================================================*/
    /* PROCEDURE NAME : add_hierarchy_element
    /*
    /* DESCRIPTION
    /*  Procédure pour ajout de hierarchy
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/
    PROCEDURE add_hierarchy_element (   p_organization_id         hr_all_organization_units.organization_id%TYPE,
                                        p_child_effective_date      DATE,
                                        p_org_parent            VARCHAR2,
                                        p_org_structure_element_id     OUT per_org_structure_elements.org_structure_element_id%TYPE,
                                        p_object_version_number  OUT per_org_structure_elements.object_version_number%TYPE
                                    )
    IS

        v_validate_mode          boolean ;--:= true;
        --l_child_effective_date   date    := sysdate;--(sysdate +1)
        v_parent_org_id          hr_all_organization_units.organization_id%type;
        v_org_structure_ver_id   per_org_structure_versions.org_structure_version_id%type;
        v_business_group_id      NUMBER := 0;
        v_inactive_org_warning   BOOLEAN;
        --v_object_version_number  per_org_structure_elements.object_version_number%TYPE;
        v_org_hierarchy          per_organization_structures.name%TYPE :='HIERARCHIE_PROJET';
        --v_org_structure_element_id  per_org_structure_elements.org_structure_element_id%TYPE;

    BEGIN

        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début add_hierarchy_element');
        /*SELECT organization_structure_id
        INTO v_org_structure_ver_id
        FROM   per_organization_structures
        WHERE name = 'HIERARCHIE_PROJET'
        AND business_group_id=0;*/
        BEGIN

            SELECT organization_id
            INTO v_parent_org_id
            FROM  hr_all_organization_units
            WHERE name =p_org_parent--'CONSO'
            AND business_group_id=v_business_group_id;

            SELECT  posv.org_structure_version_id
            INTO    v_org_structure_ver_id
            FROM    per_org_structure_versions  posv,
                    per_organization_structures pos
            WHERE   pos.name = v_org_hierarchy
            AND   posv.organization_structure_id = pos.organization_structure_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                g_message_erreur_cf :='les informations du centre finance parent sont introuvable';
                Fnd_File.put_line (Fnd_File.LOG,'les informations du centre finance parent sont introuvable');
        END;

        v_inactive_org_warning     := false;


        BEGIN
          hr_hierarchy_element_api.create_hierarchy_element
                (
                p_validate                  => v_validate_mode
               ,p_effective_date            => p_child_effective_date+1
               ,p_organization_id_parent    => v_parent_org_id
               ,p_org_structure_version_id  => v_org_structure_ver_id
               ,p_organization_id_child     => p_organization_id
               ,p_business_group_id         => v_business_group_id
               ,p_pos_control_enabled_flag  => 'N'
               ,p_inactive_org_warning      => v_inactive_org_warning
               ,p_org_structure_element_id  => p_org_structure_element_id
               ,p_object_version_number     => p_object_version_number
                );

            Fnd_File.put_line (Fnd_File.LOG, 'structure_element_id'||p_org_structure_element_id);

            IF p_object_version_number is null or p_org_structure_element_id is null then
               Fnd_File.put_line (Fnd_File.LOG, 'create_hierarchy_element API Error: '||sqlerrm);

            ELSIF v_inactive_org_warning then
               Fnd_File.put_line (Fnd_File.LOG, 'Warning: Inactive Organization');
            ELSE
               Fnd_File.put_line (Fnd_File.LOG, 'hierarchy created Successfully ');
            END IF;
        EXCEPTION
         WHEN OTHERS THEN
            Fnd_File.put_line (Fnd_File.LOG, 'create_hierarchy_element API failed with error :'||sqlerrm);
            ROLLBACK;
        END;
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin add_hierarchy_element');

    EXCEPTION
      WHEN OTHERS THEN
          Fnd_File.put_line (Fnd_File.LOG, 'hr_hierarchy_element_api API failed with error :'||sqlerrm);
    END add_hierarchy_element;



    /*=====================================================================================*/
    /* PROCEDURE NAME : add_classification
    /*
    /* DESCRIPTION
    /*  Procédure pour ajout de classification
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/
    PROCEDURE add_classification ( p_organization_id         hr_all_organization_units.organization_id%TYPE,
                                    p_child_effective_date      DATE,
                                    p_org_parent                VARCHAR2,
                                --p_org_information_id     OUT NUMBER,
                                --p_object_version_number  OUT NUMBER,
                                p_errbuf  OUT VARCHAR2,
                                p_retcode OUT NUMBER
                                )
    IS
        v_org_classif_code  VARCHAR2(20);
        v_org_structure_element_id      per_org_structure_elements.org_structure_element_id%TYPE ;
        v_object_version_number   per_org_structure_elements.object_version_number%TYPE;
        v_org_information_id      NUMBER;
        v_org_information_id1      NUMBER;
        v_org_info_type_code VARCHAR2(50) := 'Project Type Class Information';
    BEGIN
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début add_classification');
        FOR i IN 1..3 LOOP
            v_org_information_id := null;
            v_org_information_id1 := null;
            IF i = 1 THEN
                v_org_classif_code := 'PA_EXPENDITURE_ORG';
            /*ELSIF i = 2 THEN
                v_org_classif_code := 'INV';*/
            ELSIF i = 2 THEN
                v_org_classif_code := 'HR_ORG';
            ELSE
                v_org_classif_code := 'PA_PROJECT_ORG';
            END IF;

            hr_organization_api.create_org_classification(  p_validate                   => NULL,
                                                                p_effective_date             => p_child_effective_date+1,--sysdate,
                                                                p_organization_id            => p_organization_id,
                                                                p_org_classif_code           => v_org_classif_code,--'INV'--'HR_ORG',--'PA_EXPENDITURE_ORG',--'PA_PROJECT_ORG',
                                                                p_org_information_id         => v_org_information_id,
                                                                p_object_version_number      => v_object_version_number
                                                                );


            IF v_org_information_id IS NULL THEN
                p_errbuf  := 'ERREUR pour la creation de la calssification '||v_org_classif_code;
                p_retcode := 1;
                EXIT;
            END IF;

            IF  v_org_classif_code = 'HR_ORG' THEN
                add_hierarchy_element(p_organization_id,p_child_effective_date,p_org_parent,v_org_structure_element_id,v_object_version_number );
                IF v_org_structure_element_id IS NULL THEN
                    p_errbuf  := 'ERREUR pour la création de la hiérarchie de la classification '||v_org_classif_code;
                    p_retcode := 1;
                    EXIT;
                END IF;


            END IF;

            IF  v_org_classif_code = 'PA_PROJECT_ORG' THEN
                hr_organization_api.create_org_information( p_validate                        => NULL
                                                            ,p_effective_date                 => p_child_effective_date+1--sysdate
                                                            ,p_organization_id                => p_organization_id
                                                            ,p_org_info_type_code             => v_org_info_type_code
                                                            ,p_org_information1               => 'Y'
                                                            ,p_org_information12              => 'Y'
                                                            ,p_org_information13              => 'Y'
                                                            ,p_org_information_id             => v_org_information_id1
                                                            ,p_object_version_number          => v_object_version_number
                                                            );
                IF v_org_information_id1 IS NULL THEN
                    p_errbuf  := 'ERREUR pour la création des cuf pour la classification '||v_org_classif_code;
                    p_retcode := 1;
                    EXIT;
                END IF;
            END IF;

            Fnd_File.put_line (Fnd_File.LOG,'information_id :'||v_org_information_id );
        END LOOP;
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin add_classification');
    EXCEPTION
        WHEN OTHERS THEN
            p_retcode := 2;
            Fnd_File.put_line (Fnd_File.LOG,'hr_organization_api.create_organization API en error :'||sqlerrm);
    END add_classification;

    /*=====================================================================================*/
    /* PROCEDURE NAME : create_centre_finance
    /*
    /* DESCRIPTION
    /*  Procédure principale de l'interface de création des centres de finances
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/
    PROCEDURE create_centre_finance (p_centre_finance  dka_eai_organisation%rowtype,
                    p_organization_id        OUT hr_all_organization_units.organization_id%TYPE,
                    p_object_version_number  OUT hr_all_organization_units.object_version_number%TYPE,
                    p_errbuf OUT VARCHAR2,
                    p_retcode OUT NUMBER
                    )
    IS


        v_validate_mode             BOOLEAN ;
        v_business_group_id         NUMBER  := 0;
        v_intl_extl                 fnd_lookup_values.meaning%TYPE :='INT';
        v_duplicate_org_warning     BOOLEAN;
        v_org_information_id        NUMBER;
        v_object_version_number     NUMBER;
        c_org_type                  VARCHAR2(1) := 1;
        v_value_set_name            VARCHAR2(30) :='DAOPCCF_CENTREFI';
        v_errbuf                    VARCHAR2(2500);
        v_retcode                   NUMBER;
        v_controle_date                   BOOLEAN := FALSE;
        v_start_date                DATE;
        v_end_date                 DATE;
        v_start_date_en_cours                 DATE;
        v_end_date_en_cours              DATE;
        v_period_start_date         DATE;
        v_period_end_date           DATE;

    BEGIN

        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début create_centre_finance');

        IF g_date_controle IS NULL THEN

            BEGIN
                SELECT start_date
                INTO v_period_start_date
                FROM pa_periods_all
                where   1=1
                AND ( start_date = p_centre_finance.start_date OR TO_CHAR(p_centre_finance.start_date,'dd') = '01' )
                AND ROWNUM <2
                ORDER BY start_date DESC;
            EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    Fnd_File.put_line (Fnd_File.LOG, 'La date de début du centre finance ne peut être qu''un premier jour de mois calendaire ou de période');
                    p_retcode := 1;
                    p_errbuf := 'La date de début du centre finance ne peut être qu''un premier jour de mois calendaire ou de période';
                    RETURN;
            END;--YWA artf2076863


            --IF  TO_CHAR(p_centre_finance.start_date,'dd') = '01' THEN--OR p_centre_finance.start_date = last_day(p_centre_finance.start_date) THEN
            BEGIN
                /*SELECT DISTINCT start_date
                INTO v_start_date
                FROM gl_period_statuses
                WHERE application_id=275
                --AND period_year=EXTRACT(YEAR FROM p_centre_finance.start_date)
                AND ledger_id in( SELECT ledger_id FROM   gl_access_set_ledgers  WHERE access_set_id = fnd_profile.value('GL_ACCESS_SET_ID'))
                AND p_centre_finance.start_date  BETWEEN  start_date AND end_date
                AND effective_period_num > g_effective_period_num;*/
                SELECT start_date
                INTO v_start_date
                FROM pa_periods_all ppa,
                    per_security_profiles_v psp,
                    per_security_organizations_v pso
                WHERE p_centre_finance.start_date  BETWEEN  start_date AND end_date
                AND  start_date > g_end_date_en_cours
                AND pso.security_profile_id = psp.security_profile_id
                AND psp.security_profile_id = FND_PROFILE.VALUE ('XLA_MO_SECURITY_PROFILE_LEVEL')
                AND pso.organization_id        = ppa.org_id --YWA artf2076305
                AND ROWNUM <2 ;--artf2072122

            EXCEPTION
                WHEN OTHERS THEN
				-- artf07318822 OCL
                    p_errbuf  := 'La période PA correspondant à la date de début du centre finance, est strictement postérieure à la période PA en cours ';
				-- artf07318822 /
                    p_retcode := 1;
                    Fnd_File.put_line (Fnd_File.LOG,p_errbuf||sqlerrm);
                    RETURN;
            END;

            IF p_centre_finance.end_date IS NOT NULL THEN
                BEGIN
                    SELECT end_date
                    INTO v_period_end_date
                    FROM pa_periods_all
                    where   1=1
                    AND ( end_date = p_centre_finance.end_date OR p_centre_finance.end_date =LAST_DAY(p_centre_finance.end_date) )
                    AND  p_centre_finance.start_date < p_centre_finance.end_date
                    AND ROWNUM <2
                    ORDER BY end_date DESC;
                EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'La date de fin du centre finance ne peut être qu''un dernier jour de mois calendaire ou de période et doit être supérieure à la date de début du centre finance');
                        p_retcode := 1;
                        p_errbuf := 'La date de fin du centre finance ne peut être qu''un dernier jour de mois calendaire ou de période et doit être supérieure à la date de début du centre finance';
                        RETURN;
                END;--YWA artf2076863

                --IF p_centre_finance.end_date = LAST_DAY(p_centre_finance.end_date) AND p_centre_finance.start_date < p_centre_finance.end_date THEN --YWA artf2076863

                BEGIN
                    /*SELECT DISTINCT end_date
                    INTO v_end_date
                    FROM gl_period_statuses
                    WHERE application_id=275
                    --AND period_year=EXTRACT(YEAR FROM p_centre_finance.end_date)
                    AND ledger_id in( SELECT ledger_id FROM   gl_access_set_ledgers  WHERE access_set_id = fnd_profile.value('GL_ACCESS_SET_ID'))
                    AND p_centre_finance.end_date  BETWEEN  start_date AND end_date
                    AND effective_period_num > g_effective_period_num;*/

                    SELECT end_date
                    INTO v_end_date
                    FROM pa_periods_all ppa,
                        per_security_profiles_v psp,
                        per_security_organizations_v pso
                    WHERE p_centre_finance.end_date  BETWEEN  start_date AND end_date
                    AND  start_date > g_end_date_en_cours
                    AND pso.security_profile_id = psp.security_profile_id
                    AND psp.security_profile_id = FND_PROFILE.VALUE ('XLA_MO_SECURITY_PROFILE_LEVEL')
                    AND pso.organization_id        = ppa.org_id --YWA artf2076305
                    AND ROWNUM <2 ;--artf2072122


                EXCEPTION
                    WHEN OTHERS THEN
                        p_errbuf  := 'La période PA correspondant à la date de fin du centre finance fournie est antérieure ou correspond à la période PA en cours ';
                        p_retcode := 1;
                        Fnd_File.put_line (Fnd_File.LOG,p_errbuf||sqlerrm);
                        RETURN;
                END;

                /*ELSE
                    Fnd_File.put_line (Fnd_File.LOG,'Les dates de fin ne peut être qu''un dernier jour de mois calendaire');
                    p_errbuf  := 'Les dates de fin ne peut être qu''un dernier jour de mois calendaire';
                    p_retcode := 1;
                    RETURN;
                END IF;*/--YWA artf2076863

            ELSE
                v_end_date  := p_centre_finance.end_date;
            END IF ;
            v_controle_date := TRUE;

            /*ELSE
                Fnd_File.put_line (Fnd_File.LOG,'Les dates de début ne peut qu''un premier jour de mois calendaire');
                p_errbuf  := 'Les dates de début ne peut qu''un premier jour de mois calendaire';
                p_retcode := 1;
                RETURN;
            END IF;*/
        ELSE
            v_start_date := p_centre_finance.start_date;
            v_end_date  := p_centre_finance.end_date;
        END IF;

        IF g_date_controle IS NOT NULL OR ( g_date_controle IS NULL AND v_controle_date) THEN
            hr_organization_api.create_organization( p_validate                     => v_validate_mode
                                                    ,p_effective_date               => v_start_date --Reference date for validating lookup values
                                                    ,p_language_code                => hr_api.userenv_lang
                                                    ,p_business_group_id            => v_business_group_id
                                                    ,p_date_from                    => v_start_date --Date the organization takes effect
                                                    ,p_name                         => p_centre_finance.centre_finance
                                                    ,p_location_id                  => null
                                                    ,p_date_to                      => v_end_date
                                                    ,p_internal_external_flag       => v_intl_extl--'INT' --Internal/External org flag
                                                    ,p_internal_address_line        => null
                                                    ,p_type                         => c_org_type  --Org type -- Lookup Type ORG_TYPE
                                                    ,p_comments                     => null
                                                    ,p_attribute_category           => null
                                                    ,p_attribute1                   => null
                                                    ,p_attribute2                   => null
                                                    ,p_attribute3                   => null
                                                    ,p_attribute4                   => null
                                                    ,p_attribute5                   => null
                                                    --Out Variables
                                                    ,p_organization_id              => p_organization_id
                                                    ,p_object_version_number        => p_object_version_number
                                                    ,p_duplicate_org_warning        => v_duplicate_org_warning
                                                    );

            IF p_organization_id IS NULL OR p_object_version_number IS NULL THEN
                Fnd_File.put_line (Fnd_File.LOG,'hr_organization_api.create_organization  API Error: '||sqlerrm);
                p_errbuf  := 'hr_organization_api.create_organization  API Error: '||sqlerrm;
                p_retcode := 1;
            ELSIF v_duplicate_org_warning then
                Fnd_File.put_line (Fnd_File.LOG,'centre de finance en double');
                p_errbuf  := 'centre de finance en double';
                p_retcode := 1;
            ELSE
                p_errbuf  := null;
                p_retcode := 0;
                Fnd_File.put_line (Fnd_File.LOG,'centre de finance créé correctement avec l''id :'||p_organization_id);
                add_classification( p_organization_id,p_centre_finance.start_date,p_centre_finance.org_parent ,v_errbuf,v_retcode) ;

                IF v_retcode = 1 THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    ROLLBACK;
                    RETURN;
                END IF;

                --Fnd_File.put_line (Fnd_File.LOG,v_value_set_name||' , '||p_centre_finance.centre_finance||' , '||null||' , '||p_centre_finance.description||' , '||p_centre_finance.start_date||' , '||p_centre_finance.end_date||' , '||v_errbuf||' , '||v_retcode);
                create_update_flex_value(v_value_set_name,p_centre_finance.centre_finance,null,p_centre_finance.description,v_start_date,v_end_date,v_errbuf,v_retcode);

                IF v_retcode != 0 THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    ROLLBACK;
                    RETURN;
                END IF;
                p_retcode := 0;
                COMMIT;
            END IF;

        END IF;
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin create_centre_finance');
    EXCEPTION
        WHEN OTHERS THEN
            p_errbuf  := 'hr_organization_api.create_organization API en error :'||sqlerrm;
            p_retcode := 2;
            Fnd_File.put_line (Fnd_File.LOG,'hr_organization_api.create_organization API en error :'||sqlerrm);
    END create_centre_finance;


    /*=====================================================================================*/
    /* PROCEDURE NAME : update_centre_finance
    /*
    /* DESCRIPTION
    /*  Procédure principale de l'interface de modification des centres de finances
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/
    PROCEDURE update_centre_finance (p_centre_finance  dka_eai_organisation%rowtype,
                                       p_organization_id    OUT NUMBER,
                                        p_errbuf    OUT VARCHAR2,
                                        p_retcode   OUT NUMBER
                                        )
    IS
        v_validate_mode             BOOLEAN ;
        v_duplicate_org_warning     BOOLEAN;
        v_object_version_number     NUMBER;
        v_organization_id           NUMBER;
        v_value_set_name            VARCHAR2(30) :='DAOPCCF_CENTREFI';
        v_errbuf                     VARCHAR2(2500);
        v_retcode                    NUMBER;
        v_start_date DATE ;
        v_end_date DATE ;
        v_period_end_date DATE ;

		v_period_start_date_cf    VARCHAR2(20); -- OBE artf2342766
		v_period_start_date_org   VARCHAR2(20); -- OBE artf2342766

    BEGIN
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début update_centre_finance');

        SELECT organization_id,object_version_number ,date_from
        INTO v_organization_id,v_object_version_number,v_start_date
        FROM hr_all_organization_units
        WHERE name = p_centre_finance.centre_finance
        AND business_group_id = 0;

		--< OBE artf2342766
		BEGIN
          SELECT period_name
          INTO v_period_start_date_cf
          FROM PA_PERIODS_ALL
          WHERE p_centre_finance.start_date BETWEEN start_date AND end_date
          AND ROWNUM = 1
          ;
		EXCEPTION
		  WHEN NO_DATA_FOUND THEN
			v_period_start_date_cf := 'NULL';
		END;

		BEGIN
          SELECT period_name
          INTO v_period_start_date_org
          FROM PA_PERIODS_ALL
          WHERE v_start_date BETWEEN start_date AND end_date
          AND ROWNUM = 1
          ;
		EXCEPTION
		  WHEN NO_DATA_FOUND THEN
			v_period_start_date_org := 'NULL';
		END;


		IF p_centre_finance.start_date != v_start_date AND v_period_start_date_cf != v_period_start_date_org THEN
			Fnd_File.put_line (Fnd_File.LOG, 'La mise à jour de la date de début du Centre Finance n''est pas autorisée');
            p_retcode := 1;
            p_errbuf := 'La mise à jour de la date de début du Centre Finance n''est pas autorisée';
			RETURN;
		END IF;
		--> OBE artf2342766

        p_organization_id := v_organization_id;
        IF  p_centre_finance.end_date IS NOT NULL THEN -- YWA artf2076863

            --IF  p_centre_finance.end_date = last_day(p_centre_finance.end_date) AND p_centre_finance.end_date > v_start_date THEN --YWA artf2076863
            BEGIN
                SELECT end_date
                INTO v_period_end_date
                FROM pa_periods_all
                where   1=1
                AND ( end_date = p_centre_finance.end_date OR p_centre_finance.end_date =LAST_DAY(p_centre_finance.end_date) )
                AND  v_start_date < p_centre_finance.end_date
                AND ROWNUM <2
                ORDER BY end_date DESC;
            EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    Fnd_File.put_line (Fnd_File.LOG, 'La date de fin du centre finance ne peut être qu''un dernier jour de mois calendaire ou de période et doit être supérieure à la date de début du centre finance');
                    p_retcode := 1;
                    p_errbuf := 'La date de fin du centre finance ne peut être qu''un dernier jour de mois calendaire ou de période et doit être supérieure à la date de début du centre finance';
                    RETURN;
            END;--YWA artf2076863


            BEGIN
                /*SELECT DISTINCT end_date
                INTO v_end_date
                FROM gl_period_statuses
                WHERE application_id=275
                --AND period_year=EXTRACT(YEAR FROM p_centre_finance.end_date)
                AND ledger_id in( SELECT ledger_id FROM   gl_access_set_ledgers  WHERE access_set_id = fnd_profile.value('GL_ACCESS_SET_ID'))
                AND p_centre_finance.end_date  BETWEEN  start_date AND end_date
                AND effective_period_num > g_effective_period_num;*/
                SELECT end_date
                INTO v_end_date
                FROM pa_periods_all ppa,
                    per_security_profiles_v psp,
                    per_security_organizations_v pso
                WHERE p_centre_finance.end_date  BETWEEN  start_date AND end_date
                AND  start_date > g_end_date_en_cours
                AND pso.security_profile_id = psp.security_profile_id
                AND psp.security_profile_id = FND_PROFILE.VALUE ('XLA_MO_SECURITY_PROFILE_LEVEL')
                AND pso.organization_id     = ppa.org_id --YWA artf2076305
                AND ROWNUM <2 ;--artf2072122

            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := 'La période PA correspondant à la date de fin du centre finance fournie est antérieure ou correspond à la période PA en cours ';
                    p_retcode := 1;
                    Fnd_File.put_line (Fnd_File.LOG,p_errbuf||sqlerrm);
                    RETURN;
            END;


            hr_organization_api.update_organization (p_validate                 => v_validate_mode
                                                   ,p_effective_date            => v_start_date
                                                   ,p_date_to                   => v_end_date
                                                   ,p_organization_id           => v_organization_id
                                                   ,p_name                      => p_centre_finance.centre_finance
                                                   ,p_object_version_number     => v_object_version_number
                                                   ,p_duplicate_org_warning     => v_duplicate_org_warning
                                                  );

            IF  v_object_version_number IS NULL THEN
			    Fnd_File.put_line (Fnd_File.LOG, 'Problème lors de la mise à jour du centre finance.'); -- OBE artf2342766
                Fnd_File.put_line (Fnd_File.LOG,'hr_organization_api.update_organization  API Error: '||sqlerrm);
                p_errbuf  := 'hr_organization_api.update_organization  API Error: '||sqlerrm;
                p_retcode := 1;
            ELSIF v_duplicate_org_warning then
                Fnd_File.put_line (Fnd_File.LOG,'centre de finance en double');
                p_errbuf  := 'centre de finance en double';
                p_retcode := 1;
            ELSE
                p_errbuf  := null;
                p_retcode := 0;
                Fnd_File.put_line (Fnd_File.LOG,'Date de fin du centre de finance modifié correctement  :'||v_organization_id);
                --artf2079940
                create_update_flex_value(v_value_set_name,p_centre_finance.centre_finance,null,p_centre_finance.description,v_start_date,v_end_date,v_errbuf,v_retcode);
                IF v_retcode != 0 THEN
				    Fnd_File.put_line (Fnd_File.LOG, 'Problème lors de la mise à jour du centre finance.'); -- OBE artf2342766
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    ROLLBACK;
                    RETURN;

                END IF;
                COMMIT;
            END IF;
        /*ELSE
            Fnd_File.put_line (Fnd_File.LOG,'Les dates de fin ne peut être qu''un dernier jour de mois calendaire');
            p_errbuf  := 'Les dates de fin ne peut être qu''un dernier jour de mois calendaire';
            p_retcode := 1;
        END IF; */--YWA artf2076863

        ELSE
		    --< OBE artf2342766
            /*Fnd_File.put_line (Fnd_File.LOG,'Aucune modification autre que la date de fin n''est possible. Renseignez une date de fin');-- YWA artf2076863
            p_errbuf  := 'Aucune modification autre que la date de fin n''est possible. Renseignez une date de fin';-- YWA artf2076863
            p_retcode := 1;    */
            hr_organization_api.update_organization (p_validate                 => v_validate_mode
                                                   ,p_effective_date            => v_start_date
                                                   ,p_date_to                   => p_centre_finance.end_date
                                                   ,p_organization_id           => v_organization_id
                                                   ,p_name                      => p_centre_finance.centre_finance
                                                   ,p_object_version_number     => v_object_version_number
                                                   ,p_duplicate_org_warning     => v_duplicate_org_warning
                                                  );

            IF  v_object_version_number IS NULL THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Problème lors de la mise à jour du centre finance.'); -- OBE artf2342766
				Fnd_File.put_line (Fnd_File.LOG,'hr_organization_api.update_organization  API Error: '||sqlerrm);
                p_errbuf  := 'hr_organization_api.update_organization  API Error: '||sqlerrm;
                p_retcode := 1;
            ELSIF v_duplicate_org_warning then
                Fnd_File.put_line (Fnd_File.LOG,'centre de finance en double');
                p_errbuf  := 'centre de finance en double';
                p_retcode := 1;
            ELSE
                p_errbuf  := null;
                p_retcode := 0;
                Fnd_File.put_line (Fnd_File.LOG,'Date de fin du centre de finance modifié correctement  :'||v_organization_id);
                create_update_flex_value(v_value_set_name,p_centre_finance.centre_finance,null,p_centre_finance.description,v_start_date,p_centre_finance.end_date,v_errbuf,v_retcode);
                IF v_retcode != 0 THEN
                    Fnd_File.put_line (Fnd_File.LOG, 'Problème lors de la mise à jour du centre finance.'); -- OBE artf2342766
					p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    ROLLBACK;
                    RETURN;

                END IF;
                COMMIT;
            END IF;
			--> OBE artf2342766
        END IF;

        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin update_centre_finance');
    EXCEPTION
        WHEN OTHERS THEN
		    Fnd_File.put_line (Fnd_File.LOG, 'Problème lors de la mise à jour du centre finance.'); -- OBE artf2342766
            p_errbuf  := 'hr_organization_api.update_organization API en error :'||sqlerrm;
            p_retcode := 2;
            Fnd_File.put_line (Fnd_File.LOG,'hr_organization_api.update_organization API en error :'||sqlerrm);

    END update_centre_finance;
    /*
    *************************************************************************
    * PROCEDURE NAME : bilan_cf
    *
    * DESCRIPTION
    *  Procédure de génération du bilan_cf du traitement des centres de finance
    *
    * PARAMETERS
    * ==========
    * NAME                 DESCRIPTION
    .* -------------------- -------------------------------------------------
    * p_errbuf            Retour de message éventuel
    * p_retcode           Statut du traitement en sortie
    ************************************************************************
    */
    PROCEDURE bilan_cf(p_Errbuf            OUT VARCHAR2,
                         p_retcode           OUT NUMBER
                         )
    IS

    BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut bilan_cf');

        --------------------
        -- Initialisation --
        --------------------

        p_Errbuf  := NULL;
        p_retcode := 0;


        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'-----------------------------------------------------BILAN-------------------------------------------------------------------------');
        Fnd_File.put_line (Fnd_File.output,'-----------------------------------------------------------------------------------------------------------------------------------');
        Fnd_File.put_line (Fnd_File.output,'   . Nombre de centres de finance créés correctement        : ' || TO_CHAR(g_validate_cf)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'   . Nombre de centre de finance avec des erreurs           : ' || TO_CHAR(g_validate_cf_err)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'-----------------------------------------------------------------------------------------------------------------------------------');


        Fnd_File.put_line (Fnd_File.LOG,CHR(10));
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin bilan_cf');


    EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'bilan_cf : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure bilan_cf : EXCEPTION OTHERS ');
    END bilan_cf;

    /*=====================================================================================*/
    /* PROCEDURE NAME : centre_finance
    /*
    /* DESCRIPTION
    /*  Procédure principale de l'interface de création et modification des centres de finances
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/
    PROCEDURE centre_finance(p_errbuf         IN OUT VARCHAR2,
                    p_retcode         IN  OUT NUMBER,
                    p_date_controle VARCHAR2
                    )
    IS
      -- ========== VARIABLES ==========
        v_package                    VARCHAR2(30)  := 'DKA_ICODEPROJET_PKG';
        v_nom_traitement             VARCHAR2(200) := 'Import des centres de finances';
        v_sqlerrm                    VARCHAR2(250) := NULL;
        v_nb_erreurs                 NUMBER :=0;

        v_procedure                  VARCHAR2(30)    := 'Centre_finance';
        v_message                    VARCHAR2(500);

        v_errbuf                     VARCHAR2(2500);
        v_retcode                    NUMBER;
        v_exeption                   EXCEPTION;
        v_exist_erreur              BOOLEAN;
        v_type_action               VARCHAR2(30);

        --v_centre_finance  dka_eai_organisation%rowtype;
        v_organization_id         hr_all_organization_units.organization_id%TYPE;
        v_object_version_number   hr_all_organization_units.object_version_number%TYPE;
        v_organization_id_cnt     NUMBER ;

        CURSOR centre_finance
        IS SELECT *
        FROM dka_eai_organisation
        WHERE oa_status !='PROCESSED'
        AND id IS NULL;

    BEGIN

        -- Début du Programme --
        -- ========Initialisation des variables d'anomalies========
        p_retcode   := 0;
        p_errbuf   := NULL;
        v_message   := 'Début procédure centre_finance';

        /*============================================================================================*/
        /*Initialisation des variables*/
        /*============================================================================================*/
        v_message   := 'Init';
        Fnd_File.put_line (Fnd_File.log, 'p_date_controle: '||p_date_controle);
        g_date_controle := p_date_controle;
        Fnd_File.put_line (Fnd_File.output, 'Initiation des variables');
        Init(v_errbuf, v_retcode);
        IF v_retcode = 2 THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RAISE v_exeption;
        END IF;

         -- Initialization des journaux --
        Fnd_File.put_line (Fnd_File.LOG,'=======================================================================');
        Fnd_File.put_line (Fnd_File.LOG,'Import des centres de finances DKA_ICODEPROJET_PKG');
        Fnd_File.put_line (Fnd_File.LOG,'=======================================================================');
        Fnd_File.put_line (Fnd_File.LOG,'Date de lancement    : ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.LOG,'Numéro de traitement : ' || TO_CHAR(g_request_id));
         -- Initialization de la sortie --
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');
        Fnd_File.put_line (Fnd_File.output,'Import des centres de finances DKA_ICODEPROJET_PKG');
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');
        Fnd_File.put_line (Fnd_File.output,'Date de lancement    : ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.output,'Numéro de traitement : ' || TO_CHAR(g_request_id));
        Fnd_File.put_line (Fnd_File.output,'Libelle du login OA '||FND_GLOBAL.USER_NAME);

        -- param user
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');
        Fnd_File.put_line (Fnd_File.output,'Paramètres utilisateur :');
        Fnd_File.put_line (Fnd_File.output,'Aucun');
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');


        -- Entete fichier log
        Fnd_File.put_line (Fnd_File.LOG,'==========================================================================');
        Fnd_File.put_line (Fnd_File.LOG,'Numéro de traitement '||TO_CHAR(g_request_id));
        Fnd_File.put_line (Fnd_File.LOG,'Libelle du login OA '||FND_GLOBAL.USER_NAME);
        Fnd_File.put_line (Fnd_File.LOG,'==========================================================================');

        Fnd_File.put_line (Fnd_File.output,'==========================================================================');
        Fnd_File.put_line (Fnd_File.output,v_nom_traitement);
        Fnd_File.put_line (Fnd_File.output,'==========================================================================');

        --
        UPDATE dka_eai_organisation cf1 SET id = -1
        WHERE OA_STATUS ='REJECT'
        AND EXISTS (SELECT 1
                    FROM dka_eai_organisation cf2
                    WHERE cf2.CENTRE_FINANCE = cf1.CENTRE_FINANCE
                    AND cf2.Oa_Status = 'NEW');

        v_exist_erreur := FALSE;
        /*============================================================================================*/
        /*Creation centres de finance*/
        /*============================================================================================*/
        FOR cf IN centre_finance LOOP
            v_retcode := 0;
            v_errbuf := null;

            SELECT count(organization_id)
            INTO v_organization_id_cnt
            FROM hr_all_organization_units
            WHERE name = cf.centre_finance
            AND business_group_id = 0;


            IF v_organization_id_cnt =0 THEN
                v_type_action:= 'création';
                create_centre_finance(cf,v_organization_id,v_object_version_number,v_errbuf ,v_retcode);
            ELSE
                v_type_action := 'modification';
                update_centre_finance (cf,v_organization_id,v_errbuf ,v_retcode);
            END IF;

            IF v_retcode = 1 THEN
                g_message_erreur_cf := v_errbuf;
                v_exist_erreur := TRUE;
                validate_centre_finance(cf.centre_finance,TRUE,v_organization_id,v_errbuf,v_retcode);
                IF v_retcode = 2 THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    v_message := 'Erreur lors de le validation centre de finance en erreur '||cf.centre_finance;
                    RAISE v_exeption;
                END IF;
                --ROLLBACK;

            ELSIF v_retcode =0 THEN
                validate_centre_finance(cf.centre_finance,FALSE,v_organization_id,v_errbuf,v_retcode);
                IF v_retcode = 2 THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    v_message := 'Erreur lors de le validation centre de finance '||cf.centre_finance;
                    RAISE v_exeption;
                END IF;
            ELSE

                Fnd_File.put_line (Fnd_File.LOG,'Erreur lors de '||v_type_action||' du centre de finance '||cf.centre_finance);
                p_errbuf  := v_errbuf;
                p_retcode := 2;
                v_message := 'Erreur bloquante lors de la '||v_type_action||' du centre de finance'|| v_errbuf;
                RAISE v_exeption;
            END IF;

        END LOOP;
        IF v_exist_erreur THEN
            p_errbuf  := 'Des centres finances ont été rejetés lors de la création, merci de consulter les rejets sur DKA : Etat des rejets OA du referentiel projet';
            p_retcode := 1;
        END IF;

        ----------------------------------
        -- PHASE DE BILAN DU TRAITEMENT --
        ----------------------------------

        bilan_cf(v_errbuf,v_retcode);

        IF v_retcode = 2
        THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RAISE v_exeption;
        END IF;

        COMMIT;
        Fnd_File.put_line (Fnd_File.output, p_errbuf);
        Fnd_File.put_line (Fnd_File.LOG, CHR(10)||p_errbuf||CHR(10));
        Fnd_File.put_line (Fnd_File.LOG,'==========================================================================');
        Fnd_File.put_line (Fnd_File.LOG, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.LOG,'==========================================================================');
        --Fnd_File.put_line (Fnd_File.output, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'FIN DE L''INTERFACE');

    EXCEPTION
        WHEN v_exeption THEN
            --p_retcode := 2;
            --p_errbuf  := 'Erreur EXCEPTION v_exception dans pkg.proc/fonc '||v_package||'.'||v_procedure;
            Fnd_File.put_line (Fnd_File.output,'-------------------- ERREUR --------------------');
            Fnd_File.put_line (Fnd_File.output,'Package   : '||v_package);
            Fnd_File.put_line (Fnd_File.output,'Procédure : '||v_procedure);
            Fnd_File.put_line (Fnd_File.output,'Exception : OTHERS');
            Fnd_File.put_line (Fnd_File.output,'Message   : '||v_message);
            Fnd_File.put_line (Fnd_File.LOG,'Cause     : '||p_errbuf);
            Fnd_File.put_line (Fnd_File.output,'------------------------------------------------');
            Fnd_File.put_line (Fnd_File.output, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_procedure||' : EXCEPTION v_exeption ');
            Fnd_File.put_line (Fnd_File.LOG, '==> Fin de la procédure '||v_procedure||' : EXCEPTION v_exeption ');
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            Fnd_File.put_line (Fnd_File.LOG,'Traitement '||v_nom_traitement||' terminé en erreur         ');
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            ROLLBACK;

       WHEN OTHERS THEN
            v_sqlerrm := SUBSTR(SQLERRM,1,200);
            p_retcode := 2;
            p_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc '||v_package||'.'||v_procedure;
            Fnd_File.put_line (Fnd_File.output,'-------------------- ERREUR --------------------');
            Fnd_File.put_line (Fnd_File.output,'Package   : '||v_package);
            Fnd_File.put_line (Fnd_File.output,'Procédure : '||v_procedure);
            Fnd_File.put_line (Fnd_File.output,'Exception : OTHERS');
            Fnd_File.put_line (Fnd_File.output,'Message   : '||v_message);
            Fnd_File.put_line (Fnd_File.LOG, CHR(10)||p_errbuf);
            Fnd_File.put_line (Fnd_File.output,'Cause     : '||v_sqlerrm);
            Fnd_File.put_line (Fnd_File.output,'------------------------------------------------');
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            Fnd_File.put_line (Fnd_File.LOG,'Traitement '||v_nom_traitement||' terminé en erreur         ');
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            ROLLBACK;



    END centre_finance;

    /*=========================================================================*/
    /* PROCEDURE NAME : validate_project
    /*
    /* DESCRIPTION
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/
    PROCEDURE validate_project( p_project_code         VARCHAR2
                                ,p_erreur             BOOLEAN
                                ,p_project_id         dka_eai_projet.id%TYPE
                                ,p_type_action        VARCHAR2
                                ,p_creation_date      dka_eai_projet.creation_date%TYPE
                                ,p_errbuf            OUT VARCHAR2
                                ,p_retcode           OUT NUMBER)
    IS

    BEGIN
        --Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_project');
        IF p_erreur THEN

            g_validate_proj_err := g_validate_proj_err+1;
            BEGIN
                UPDATE dka_eai_projet
                SET    oa_status ='REJECT',
                       oa_rejection_reason = SUBSTR(g_message_erreur_prj,0,240),
                       oa_request_id = g_request_id,
                       last_updated_by = 	g_user_id,
                       last_update_date = sysdate,
                       oa_action_type = p_type_action
                WHERE  project_code = p_project_code
                AND    oa_status  != 'PROCESSED'
                AND     id IS NULL
                AND    creation_date = p_creation_date;--YWA artf2131956

                UPDATE dka_eai_tache
                SET    oa_status ='REJECT',
                       --oa_rejection_reason = SUBSTR(g_message_erreur_prj,0,240),
                       oa_request_id = g_request_id,
                       last_updated_by = 	g_user_id,
                       last_update_date = sysdate
                WHERE  project_code = p_project_code
                AND    oa_status  != 'PROCESSED'
                AND     id IS NULL ;--YWA artf2131956,artf2131656
            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
            END;

        ELSE
            g_validate_proj := g_validate_proj+1;
            BEGIN
                UPDATE dka_eai_projet
                SET    oa_status ='PROCESSED',
                       oa_rejection_reason = NULL,
                       oa_request_id =g_request_id,
                       id = p_project_id,
                       last_updated_by = 	g_user_id,
                       last_update_date = sysdate,
                       oa_action_type = p_type_action
                WHERE  project_code = p_project_code
                AND    id IS  NULL
                AND    creation_date = p_creation_date;--YWA artf2131956
                /*UPDATE dka_eai_tache
                SET    oa_status ='PROCESSED',
                       oa_rejection_reason = NULL,
                       oa_request_id =g_request_id,
                       id = (SELECT task_id FROM pa_tasks WHERE task_number= task_code AND project_id=p_project_id),
                       last_updated_by = 	g_user_id,
                       last_update_date = sysdate
                WHERE  project_code = p_project_code
                AND    id IS  NULL ;*/--YWA artf2131956

            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
            END;

        END IF;
        --Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_project');
    END validate_project;

        ----------------------------------------------------------------------------------------
    --  Nom           : INSERT_PA_CLASS_CODES
    --  Description   : Procédure vérifiant si la valeur de classification existe déjà
    --                  sinon elle alimente la TABLE PA_CLASS_CODES
    --  PARAMETRES :
    --    p_code_affaire       Entrée
    --    p_project_start_date           Entrée
    --      p_description        Entrée
    --    pv_errbuf               Sortie
    --    pn_retcode               Sortie

    --  VALEUR RETOURNEE :
    --     Description       : code retour de validité
    --     Valeurs possibles : 0: normal
    --                         2: erreur
    ----------------------------------------------------------------------------------------
    PROCEDURE insert_pa_class_codes(p_code_affaire      VARCHAR2,
                                    p_code_activite      VARCHAR2,
                                      --p_project_start_date   DATE ,
                                      p_errbuf             OUT VARCHAR2,
                                      p_retcode            OUT NUMBER)
    IS

        v_name_org hr_operating_units.name%type;
        v_value_set_name           VARCHAR2(30)  :='DAOPCCF_AFFAIRE';
        v_errbuf                     VARCHAR2(2500);
        v_retcode                    NUMBER;
    BEGIN
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début INSERT_PA_CLASS_CODES');
        p_errbuf  := NULL;
        p_retcode := 0;

        SELECT name
        INTO v_name_org
        FROM hr_operating_units
        WHERE organization_id = g_org_id;

        SAVEPOINT insert_pa_class_code;

        INSERT INTO pa_class_codes pcc
                (class_category,
                class_code,
                last_update_date,
                last_updated_by,
                creation_date,
                created_by,
                last_update_login,
                start_date_active,
                end_date_active,
                description,
                attribute_category,
                attribute1,
                attribute2,
                attribute3,
                attribute4,
                attribute5,
                attribute6,
                attribute7,
                attribute8,
                attribute9,
                attribute10,
                attribute11,
                attribute12,
                attribute13,
                attribute14,
                attribute15,
                adw_notify_flag,
                class_code_id
                )
        VALUES
                ('AFFAIRE',
                p_code_affaire ,
                SYSDATE,
                g_user_id,
                SYSDATE,
                g_user_id,
                g_login_id,
                SYSDATE,--p_project_start_date,
                NULL,
                p_code_affaire,--RTRIM(LTRIM(SUBSTR(p_code_affaire || '-' || v_name_org,1,240))),
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                'Y',
                pa_class_codes_s.NEXTVAL
                );

        create_update_flex_value(v_value_set_name,p_code_affaire,p_code_activite,p_code_affaire,NULL,NULL,v_errbuf,v_retcode);
        IF v_retcode != 0 THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;

            ROLLBACK TO SAVEPOINT insert_pa_class_code;
            RETURN;

        END IF;

        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'FIN INSERT_PA_CLASS_CODES');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT insert_pa_class_code;
            p_retcode := 1;
            p_errbuf  := 'ERREUR DKA_ICODEPROJET_PKG.insert_pa_class_codes : ' || SQLERRM;
    END insert_pa_class_codes;


    ----------------------------------------------------------------------------------------
    --  Nom           : UPDATE_PA_PROJECT_CLASSES
    --  Description   : Procédure de mise à jour de la classification d'un projet
    --
    --  PARAMETRES :
    --    p_project_id            Entrée
    --    p_class_category       Entrée
    --    p_class_code            Entrée
    --  VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    ----------------------------------------------------------------------------------------
    PROCEDURE update_pa_project_classes(p_project_id     IN NUMBER,
                                      p_class_category IN VARCHAR2,
                                      p_class_code     IN VARCHAR2,
                                      p_code_affaire     IN VARCHAR2,
                                      --p_project_start_date IN DATE Default Null,
                                      p_errbuf         OUT VARCHAR2,
                                      p_retcode        OUT NUMBER)

    IS
        v_record_version_number  NUMBER;
        v_rowid ROWID;
        v_class_code pa_class_codes.class_code%type;
        v_api_version_number   NUMBER                                 := 1.0;
        v_return_status  VARCHAR2 (1);
        v_msg_count   NUMBER;
        v_msg_data  VARCHAR2 (2000);
        v_msg_index_out        NUMBER;
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        p_errbuf  := NULL;
        p_retcode := 0;

        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début update_pa_project_classes');
        BEGIN
            SELECT record_version_number,rowid
            INTO v_record_version_number,v_rowid
            FROM   pa_project_classes
            WHERE   project_id = p_project_id
            AND     class_category = p_class_category;
           -- AND   class_code = p_class_code;
        EXCEPTION
          WHEN OTHERS THEN
            Fnd_File.put_line (Fnd_File.LOG, 'Impossible de trouver l''ancienne valeur pour le code affaire de ce projet');
            p_errbuf := 'Impossible de trouver l''ancienne valeur pour le code affaire de ce projet' ;
            p_retcode := 1;
            RETURN;
        END;

        BEGIN
            SELECT class_code
            INTO v_class_code
            FROM pa_class_codes
            WHERE  class_category = p_class_category
            AND class_code = p_class_code;

        EXCEPTION
          WHEN OTHERS THEN
            IF p_class_category = 'AFFAIRE' THEN
                insert_pa_class_codes(p_class_code,p_code_affaire,p_errbuf,p_retcode);
                IF p_retcode != 0 THEN
                    RETURN;
                END IF;

            ELSE
                Fnd_File.put_line (Fnd_File.LOG, 'Le code class '||p_class_category||' est erroné');
                p_retcode := 1;
                p_errbuf := 'Le code class '||p_class_category||' est erroné';
                RETURN;
            END IF;
        END;

        pa_projects_maint_pub.update_classifications(p_api_version                  => v_api_version_number,
                                                    p_init_msg_list                 => fnd_api.g_true,
                                                    p_commit                        => fnd_api.g_false,
                                                    p_validate_only                 => fnd_api.g_false,
                                                    p_max_msg_count                 => fnd_api.g_miss_num,
                                                    p_object_id                     => p_project_id,
                                                    p_object_type                   => 'PA_PROJECTS',
                                                    p_class_category                => p_class_category,
                                                    p_class_code                    => p_class_code,
                                                    p_rowid                         => v_rowid,
                                                    p_record_version_number         => v_record_version_number,
                                                    x_return_status                 => v_return_status,
                                                    x_msg_count                     => v_msg_count,
                                                    x_msg_data                      => v_msg_data);



        IF v_return_status !='S' THEN
            FOR i IN 1..v_msg_count LOOP

                fnd_msg_pub.get (p_msg_index     => i
                                        ,p_encoded       => 'F'
                                        ,p_data          => v_msg_data
                                        ,p_msg_index_out => v_msg_index_out
                                        );

                p_errbuf := p_errbuf || CHR(10) || v_msg_data;


            END LOOP;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            p_retcode := 1;
            RETURN;
        END IF;

        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'fin update_pa_project_classes');
    EXCEPTION
        WHEN OTHERS THEN
            p_retcode := 2;
            p_errbuf  := 'ERREUR DKA_ICODEPROJET_PKG.UPDATE_PA_PROJECT_CLASSES : ' || SQLERRM;
    END update_pa_project_classes;

     /*=====================================================================================*/
    /* PROCEDURE NAME : copie_task_template
    /*
    /* DESCRIPTION
    /*  Procédure de copie du modele de tache
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_project_template_id
    /* p_task_code
    /* p_cost_ind_rate_sch_id
    /* p_tasks_in_rec
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/
    PROCEDURE copie_task_template (  p_project_template_id    NUMBER,
                            p_task_code                 VARCHAR2,
                            p_cost_ind_rate_sch_id      NUMBER,
                            p_tasks_in_rec              OUT pa_project_pub.task_in_rec_type,
                            p_errbuf                    OUT VARCHAR2,
                            p_retcode                   OUT NUMBER
                           )
    IS
        v_tasks_in_rec         pa_project_pub.task_in_rec_type;

    BEGIN
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début copie_task_template');
        p_errbuf  := null;
        p_retcode := 0;
        BEGIN
            SELECT  service_type_code
                    ,task_manager_person_id
                    ,chargeable_flag
                    ,billable_flag
                    ,limit_to_txn_controls_flag
                    ,labor_bill_rate_org_id
                    ,labor_std_bill_rate_schdl
                    ,labor_schedule_fixed_date
                    ,labor_schedule_discount
                    ,non_labor_bill_rate_org_id
                    ,non_labor_std_bill_rate_schdl
                    ,non_labor_schedule_fixed_date
                    ,non_labor_schedule_discount
                    ,labor_cost_multiplier_name
                    ,cost_ind_rate_sch_id
                    ,rev_ind_rate_sch_id
                    ,inv_ind_rate_sch_id
                    ,cost_ind_sch_fixed_date
                    ,rev_ind_sch_fixed_date
                    ,inv_ind_sch_fixed_date
                    ,labor_sch_type
                    ,non_labor_sch_type
                    ,allow_cross_charge_flag
                    ,project_rate_date
                    ,project_rate_type
                    ,cc_process_labor_flag
                    ,labor_tp_schedule_id
                    ,labor_tp_fixed_date
                    ,cc_process_nl_flag
                    ,nl_tp_schedule_id
                    ,nl_tp_fixed_date
                    ,receive_project_invoice_flag
                    ,work_type_id
                    ,job_bill_rate_schedule_id
                    ,emp_bill_rate_schedule_id
                    ,taskfunc_cost_rate_type
                    ,taskfunc_cost_rate_date
                    ,non_lab_std_bill_rt_sch_id
                    ,labor_disc_reason_code
                    ,non_labor_disc_reason_code
                    ,retirement_cost_flag
                    ,cint_eligible_flag
                    ,cint_stop_date
                    ,invoice_method
                    ,gen_etc_source_code
                    ,adj_on_std_inv
                    ,cost_plus_fixed_fee_flag
                    ,progress_payment_flag
                    ,retention_percentage
                    ,rate_percentage
                    ,liquidation_rate_percentage
                    ,alt_liquidation_rate_per
                    ,withhold_amount
            INTO v_tasks_in_rec.service_type_code
                ,v_tasks_in_rec.task_manager_person_id
                ,v_tasks_in_rec.chargeable_flag
                ,v_tasks_in_rec.billable_flag
                ,v_tasks_in_rec.limit_to_txn_controls_flag
                ,v_tasks_in_rec.labor_bill_rate_org_id
                ,v_tasks_in_rec.labor_std_bill_rate_schdl
                ,v_tasks_in_rec.labor_schedule_fixed_date
                ,v_tasks_in_rec.labor_schedule_discount
                ,v_tasks_in_rec.non_labor_bill_rate_org_id
                ,v_tasks_in_rec.non_labor_std_bill_rate_schdl
                ,v_tasks_in_rec.non_labor_schedule_fixed_date
                ,v_tasks_in_rec.non_labor_schedule_discount
                ,v_tasks_in_rec.labor_cost_multiplier_name
                ,v_tasks_in_rec.cost_ind_rate_sch_id
                ,v_tasks_in_rec.rev_ind_rate_sch_id
                ,v_tasks_in_rec.inv_ind_rate_sch_id
                ,v_tasks_in_rec.cost_ind_sch_fixed_date
                ,v_tasks_in_rec.rev_ind_sch_fixed_date
                ,v_tasks_in_rec.inv_ind_sch_fixed_date
                ,v_tasks_in_rec.labor_sch_type
                ,v_tasks_in_rec.non_labor_sch_type
                ,v_tasks_in_rec.allow_cross_charge_flag
                ,v_tasks_in_rec.project_rate_date
                ,v_tasks_in_rec.project_rate_type
                ,v_tasks_in_rec.cc_process_labor_flag
                ,v_tasks_in_rec.labor_tp_schedule_id
                ,v_tasks_in_rec.labor_tp_fixed_date
                ,v_tasks_in_rec.cc_process_nl_flag
                ,v_tasks_in_rec.nl_tp_schedule_id
                ,v_tasks_in_rec.nl_tp_fixed_date
                ,v_tasks_in_rec.receive_project_invoice_flag
                ,v_tasks_in_rec.work_type_id
                ,v_tasks_in_rec.job_bill_rate_schedule_id
                ,v_tasks_in_rec.emp_bill_rate_schedule_id
                ,v_tasks_in_rec.taskfunc_cost_rate_type
                ,v_tasks_in_rec.taskfunc_cost_rate_date
                ,v_tasks_in_rec.non_lab_std_bill_rt_sch_id
                ,v_tasks_in_rec.labor_disc_reason_code
                ,v_tasks_in_rec.non_labor_disc_reason_code
                ,v_tasks_in_rec.retirement_cost_flag
                ,v_tasks_in_rec.cint_eligible_flag
                ,v_tasks_in_rec.cint_stop_date
                ,v_tasks_in_rec.invoice_method
                ,v_tasks_in_rec.gen_etc_source_code
                ,v_tasks_in_rec.adj_on_std_inv
                ,v_tasks_in_rec.cost_plus_fixed_fee_flag
                ,v_tasks_in_rec.progress_payment_flag
                ,v_tasks_in_rec.retention_percentage
                ,v_tasks_in_rec.rate_percentage
                ,v_tasks_in_rec.liquidation_rate_percentage
                ,v_tasks_in_rec.alt_liquidation_rate_per
                ,v_tasks_in_rec.withhold_amount
            FROM pa_tasks
            WHERE project_id=p_project_template_id
            AND SUBSTR(task_number,1,2)= SUBSTR(p_task_code,1,2);

        EXCEPTION
          WHEN OTHERS THEN

                IF p_project_template_id != -1 THEN
                    p_errbuf := SUBSTR('Erreur lors de la récupération des informations du modèle de tache pour la tache ' ||p_task_code,0,240);--||'  : '|| SQLERRM,0,240) ;
                    Fnd_File.put_line (Fnd_File.LOG,'p_errbuf copie : ' || p_errbuf);
                    Fnd_File.put_line (Fnd_File.LOG,'Error message 1: ' || SQLERRM);
                    p_retcode := 1;
                    return;

                END IF;

                v_tasks_in_rec.cost_ind_rate_sch_id             :=  p_cost_ind_rate_sch_id;
        END;

        p_tasks_in_rec := v_tasks_in_rec;
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin copie_task_template');
    EXCEPTION
          WHEN OTHERS THEN
            p_errbuf := SUBSTR('Error: '|| SQLERRM,0,240) ;
            Fnd_File.put_line (Fnd_File.LOG,'Error message : ' || SQLERRM);
            p_retcode := 1;

    END copie_task_template;

        /*=====================================================================================*/
    /* PROCEDURE NAME : controle_mouvements
    /*
    /* DESCRIPTION
    /*  Procédure pour ajout des controle de mouvements
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/
    PROCEDURE controle_mouvements  (  p_project_template_id   NUMBER,
                                    p_project_id            NUMBER,
                                    --p_start_date DATE,
                                    p_task_id        NUMBER,
                                    p_errbuf                OUT VARCHAR2,
                                    p_retcode               OUT NUMBER
                                   )
    IS

    BEGIN
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut controle_mouvements');
        p_errbuf := null;
        p_retcode := 0;
        FOR t IN (SELECT * FROM pa_tasks WHERE project_id = p_project_id AND task_id =  NVL(p_task_id,task_id) ) LOOP

            INSERT INTO pa_transaction_controls (project_id
                                                ,task_id
                                                ,start_date_active
                                                ,chargeable_flag
                                                ,billable_indicator
                                                ,creation_date
                                                ,created_by
                                                ,last_update_date
                                                ,last_updated_by
                                                ,last_update_login
                                                ,person_id
                                                ,expenditure_category
                                                ,expenditure_type
                                                ,non_labor_resource
                                                ,scheduled_exp_only
                                                ,end_date_active
                                                ,workplan_res_only_flag
                                                ,employees_only_flag
                                                )
            SELECT          p_project_id
                            ,t.task_id
                            ,t.start_date
                            ,tc.chargeable_flag
                            ,tc.billable_indicator
                            ,SYSDATE
                            ,g_user_id
                            ,SYSDATE
                            ,g_user_id
                            ,g_login_id
                            ,tc.person_id
                            ,tc.expenditure_category
                            ,tc.expenditure_type
                            ,tc.non_labor_resource
                            ,tc.scheduled_exp_only
                            ,tc.end_date_active
                            ,tc.workplan_res_only_flag
                            ,tc.employees_only_flag
            FROM pa_transaction_controls tc ,
                 pa_tasks pt
            WHERE pt.project_id =p_project_template_id
            AND tc.project_id = pt.project_id
            AND tc.task_id = pt.task_id
            AND SUBSTR(pt.task_number,1,2)  = SUBSTR(t.task_number,1,2);

        END LOOP;
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin controle_mouvements');
    EXCEPTION
        WHEN OTHERS THEN
            Fnd_File.put_line (Fnd_File.LOG,'ERREUR DKA_ICODEPROJET_PKG.controle_mouvements : ' || SQLERRM);
            p_retcode := 1;
            p_errbuf  := 'ERREUR DKA_ICODEPROJET_PKG.controle_mouvements : ' || SQLERRM;

    END controle_mouvements;

          /*=====================================================================================*/
    /* PROCEDURE NAME : add_budget
    /*
    /* DESCRIPTION
    /*  Procédure pour ajout des budget pour les projet facturable
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/
    PROCEDURE add_budget (  p_project_template_id   NUMBER,
                            p_project_id            NUMBER,
                            p_pm_project_reference  VARCHAR2,
                            p_pm_product_code       VARCHAR2,
                            p_errbuf                OUT VARCHAR2,
                            p_retcode               OUT NUMBER
                           )
    IS




        v_api_version_number NUMBER := 1.0;
        v_commit VARCHAR2(1) := 'F';
        v_init_msg_list VARCHAR2(1) := 'T';
        v_msg_count NUMBER;
        v_msg_data VARCHAR2(2000);
        v_return_status VARCHAR2(1);
        v_data VARCHAR2(2000);

        v_msg_index_out NUMBER;

        v_budget_type_code VARCHAR2(30);
        v_change_reason_code VARCHAR2(30);
        v_description VARCHAR2(255);
        v_entry_method_code VARCHAR2(30);
        v_resource_list_name VARCHAR2(60);
        v_resource_list_id NUMBER;
        v_resource_list_member_id   NUMBER;
        v_revenue NUMBER;
        v_task_id       NUMBER;
        v_resource_assignment_id    NUMBER;
        v_budget_lines_in PA_BUDGET_PUB.BUDGET_LINE_IN_TBL_TYPE;
        v_budget_lines_in_rec PA_BUDGET_PUB.BUDGET_LINE_IN_REC_TYPE;
        v_budget_lines_out PA_BUDGET_PUB.BUDGET_LINE_OUT_TBL_TYPE;
        v_budget_version_name VARCHAR2(20) ;
        api_error EXCEPTION;
        v_workflow_started               VARCHAR2 (1)                       := 'Y';

    BEGIN
        p_retcode := 0;
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut add_budget');
        BEGIN
            SELECT  v.budget_entry_method_code,
                    v.budget_type_code,
                    v.resource_list_id,
                    v.revenue,
                    v.version_name,
                    v.description,
                    v.change_reason_code,
                    a.resource_list_member_id,
                    a.task_id,
                    a.resource_assignment_id
            INTO    v_entry_method_code,
                    v_budget_type_code,
                    v_resource_list_id,
                    v_revenue,
                    v_budget_version_name,
                    v_description,
                    v_change_reason_code,
                    v_resource_list_member_id,
                    v_task_id,
                    v_resource_assignment_id
            FROM    pa_resource_assignments a,
                    pa_budget_versions v
            WHERE  v.project_id = p_project_template_id
            AND    (v.budget_type_code = 'AR' OR v.approved_rev_plan_type_flag ='Y')
            AND    v.budget_status_code = 'W'
            AND    DECODE(v.budget_type_code,NULL,v.current_working_flag,'Y')='Y'
            AND    a.budget_version_id = v.budget_version_id
            AND    a.project_id = v.project_id
            AND    a.task_id IS NOT NULL;
        EXCEPTION
            WHEN OTHERS THEN
                Fnd_File.put_line (Fnd_File.LOG,'Pas de budget trouvé pour le template du projet');
                p_errbuf := 'Pas de budget trouvé pour le template du projet';
                p_retcode := 1;
                RETURN;
        END;

        pa_budget_pub.init_budget;

        -- CREATE_DRAFT_BUDGET
        pa_budget_pub.create_draft_budget ( p_api_version_number        => v_api_version_number, -- required
                                            p_commit                    => v_commit,
                                            p_init_msg_list             => v_init_msg_list,
                                            p_msg_count                 => v_msg_count,
                                            p_msg_data                  => v_msg_data,
                                            p_return_status             => v_return_status,
                                            p_pm_product_code           => p_pm_product_code, -- required
                                            p_pm_project_reference      => p_pm_project_reference,
                                            p_budget_version_name       => v_budget_version_name,
                                            p_pa_project_id             => p_project_id,
                                            p_budget_type_code          => v_budget_type_code, -- required
                                            p_change_reason_code        => v_change_reason_code,
                                            p_description               => v_description,
                                            p_entry_method_code         => v_entry_method_code, -- required
                                            p_resource_list_name        => v_resource_list_name,
                                            p_resource_list_id          => v_resource_list_id,
                                            p_budget_lines_in           => v_budget_lines_in,
                                            p_budget_lines_out          => v_budget_lines_out
                                            );




        IF v_return_status != 'S' THEN
            RAISE api_error;
        END IF;


        FOR line IN (SELECT start_date,end_date,period_name,quantity,revenue,description,project_revenue ,burdened_cost,raw_cost , txn_currency_code
                    FROM pa_budget_lines WHERE resource_assignment_id = v_resource_assignment_id ) LOOP

            pa_Budget_Pub.add_budget_line(  p_api_version_number        => v_api_version_number,
                                            p_commit                    => v_commit,
                                            p_init_msg_list             => v_init_msg_list,
                                            p_msg_count                 => v_msg_count,
                                            p_msg_data                  => v_msg_data,
                                            p_return_status             => v_return_status,
                                            p_pm_product_code           => p_pm_product_code,
                                            p_pa_project_id             => p_project_id,
                                            p_pm_project_reference      => p_pm_project_reference,
                                            p_resource_list_member_id   => v_resource_list_member_id,
                                            p_budget_type_code          => v_budget_type_code,
                                            p_pa_task_id                => v_task_id,
                                            p_period_name               => line.period_name,
                                            p_budget_start_date	        => line.start_date,
                                            p_budget_end_date	        => line.end_date,
                                            p_description               => line.description,
                                            p_burdened_cost             => line.burdened_cost,
                                            p_revenue                   => line.revenue,
                                            p_quantity                  => line.quantity,
                                            p_raw_cost                  => line.raw_cost
                                            );

            --Fnd_File.put_line (Fnd_File.log,'v_return_status add line: '||v_return_status);

            IF v_return_status != 'S' THEN

               RAISE API_ERROR;
            END IF;
        END LOOP;

        pa_budget_pub.baseline_budget( p_api_version_number        => v_api_version_number,
                                      p_commit                    => v_commit,
                                      p_init_msg_list             => v_init_msg_list,
                                      p_msg_count                 => v_msg_count,
                                      p_msg_data                  => v_msg_data,
                                      p_return_status             => v_return_status,
                                      p_workflow_started          => v_workflow_started,
                                      p_pm_product_code           => p_pm_product_code,
                                      p_pa_project_id             => p_project_id,
                                      p_pm_project_reference      => p_pm_project_reference,
                                      p_budget_type_code          => v_budget_type_code,
                                      p_fin_plan_type_id          => NULL,
                                      p_fin_plan_type_name        => null,
                                      p_version_type              => null
                                     );

        IF v_return_status != 'S' THEN
            RAISE api_error;
        END IF;

        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin add_budget');
    EXCEPTION
        WHEN API_ERROR THEN
            FOR i IN 1..v_msg_count LOOP
                pa_interface_utils_pub.get_messages(
                p_msg_data     => v_msg_data,
                p_data          => v_data,
                p_msg_count     => v_msg_count,
                p_msg_index     => i,--10/09/2025 RTM Migration 12.2.14 
                p_msg_index_out => v_msg_index_out);
                p_errbuf := SUBSTR(p_errbuf || v_data||' -- '|| SQLERRM,0,240);
            END LOOP;
            Fnd_File.put_line (Fnd_File.LOG,'error message API_ERROR add_budget: ' || p_errbuf);
            p_retcode := 1;
        WHEN OTHERS THEN
                Fnd_File.put_line (Fnd_File.LOG,'error message OTHERS add_budget: '||sqlerrm);
                p_errbuf := SUBSTR('error message OTHERS add_budget: '||sqlerrm,0,240);
                p_retcode := 1;
                RETURN;

    END add_budget;

    /*=====================================================================================*/
    /* PROCEDURE NAME : add_immo_gy
    /*
    /* DESCRIPTION
    /*  Procédure pour ajout desimmobilisation sur le projet et affectée à la tâche GY
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/
    PROCEDURE add_immo_gy ( p_project_id            NUMBER,
                            p_pm_project_reference  VARCHAR2,
                            p_task_id               NUMBER,
                            p_pm_product_code       VARCHAR2,
                            p_errbuf                OUT VARCHAR2,
                            p_retcode               OUT NUMBER
                           )
    IS




        v_api_version_number NUMBER := 1.0;
        v_commit VARCHAR2(1) := 'F';
        v_init_msg_list VARCHAR2(1) := 'T';
        v_msg_count NUMBER;
        v_msg_data VARCHAR2(2000);
        v_return_status VARCHAR2(1);
        v_data VARCHAR2(2000);

        v_msg_index_out NUMBER;
        v_pa_project_id_out NUMBER;
       v_pa_project_number_out     VARCHAR2(1000);
       v_pa_project_asset_id_out   NUMBER;
       v_pm_asset_reference_out     VARCHAR2(1000);
       v_pa_task_id_out            NUMBER;

        api_error EXCEPTION;

    BEGIN
        p_retcode := 0;
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut add_immo_gy');
        FOR t IN (SELECT * FROM pa_tasks WHERE project_id = p_project_id AND SUBSTR(task_number,1,2) = 'GY'  AND task_id = nvl(p_task_id,task_id) ) LOOP

            pa_project_assets_pub.add_project_asset(p_api_version_number        => v_api_version_number
                                                    ,p_commit                   => v_commit
                                                    ,p_init_msg_list            => v_init_msg_list
                                                    ,p_msg_count                => v_msg_count
                                                    ,p_msg_data                 => v_msg_data
                                                    ,p_return_status            => v_return_status
                                                    ,p_pa_project_id_out        => v_pa_project_id_out
                                                    ,p_pa_project_number_out    => v_pa_project_number_out
                                                    ,p_pa_project_asset_id_out  => v_pa_project_asset_id_out
                                                    ,p_pm_asset_reference_out   => v_pm_asset_reference_out
                                                    ,p_pm_project_reference     => p_pm_project_reference
                                                    ,p_pm_product_code          => p_pm_product_code--null
                                                    ,p_pm_asset_reference       => t.task_number
                                                    ,p_asset_description        => t.task_name
                                                    ,p_pa_project_id            => p_project_id
                                                    ,p_asset_category_id        => TO_NUMBER(t.attribute6)
                                                    ,p_depreciate_flag          => 'Y'
                                                    ,p_project_asset_type       => 'AS-BUILT'
                                                    ,p_asset_units              => 1
                                                    ,p_date_placed_in_service   => TO_DATE('31-DEC-2050','DD-MON-YYYY')
                                                    );

            IF v_return_status != 'S' THEN
                RAISE api_error;
            ELSE
                PA_PROJECT_ASSETS_PUB.add_asset_assignment ( p_api_version_number   => v_api_version_number
                                                            ,p_commit               => v_commit
                                                            ,p_init_msg_list        => v_init_msg_list
                                                            ,p_msg_count            => v_msg_count
                                                            ,p_msg_data             => v_msg_data
                                                            ,p_return_status        => v_return_status
                                                            ,p_pm_product_code      => p_pm_product_code
                                                            ,p_pm_project_reference => p_pm_project_reference
                                                            ,p_pa_project_id        => p_project_id
                                                            ,p_pm_task_reference    => t.task_number
                                                            ,p_pa_task_id           => t.task_id
                                                            ,p_pm_asset_reference   => v_pm_asset_reference_out
                                                            ,p_pa_project_asset_id  => v_pa_project_asset_id_out
                                                            ,p_pa_task_id_out       => v_pa_task_id_out
                                                            ,p_pa_project_asset_id_out => v_pa_project_asset_id_out) ;



                IF v_return_status != 'S' THEN
                    RAISE api_error;
                END IF;

            END IF;

        END LOOP;
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin add_immo_gy');
    EXCEPTION
        WHEN API_ERROR THEN
            FOR i IN 1..v_msg_count LOOP
                pa_interface_utils_pub.get_messages(
                p_msg_data     => v_msg_data,
                p_data          => v_data,
                p_msg_count     => v_msg_count,
                p_msg_index     => i, --10/09/2025 RTM Migration 12.2.14 
                p_msg_index_out => v_msg_index_out);
                p_errbuf := SUBSTR(p_errbuf || v_data||' -- '|| SQLERRM,0,240);
            END LOOP;
            Fnd_File.put_line (Fnd_File.LOG,'error message add_immo_gy: ' || p_errbuf);
            p_retcode := 1;
        WHEN OTHERS THEN
            p_retcode := 1;
            p_errbuf  := 'ERREUR DKA_ICODEPROJET_PKG.add_immo_gy : ' || SQLERRM;

    END add_immo_gy;


    /*=====================================================================================*/
    /* PROCEDURE NAME : tache_action
    /*
    /* DESCRIPTION
    /*  Procédure de mis a jour ou d'ajout de tache d'un projet
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_project        le projet de la tache
    /* p_tache          la tache
    /* p_type_action    type de l'action sur la tache
    /* p_tasks_in_rec   record de la tache
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/

    PROCEDURE tache_action(p_project pa_projects_all%rowtype,
                    p_tache           dka_eai_tache%rowtype,
                    p_type_action   OUT VARCHAR2,
                    --p_task_id    OUT NUMBER,
                    p_tasks_in_rec OUT pa_project_pub.task_in_rec_type,
                    p_errbuf         IN OUT VARCHAR2,
                    p_retcode         IN  OUT NUMBER
                    )
    IS
        v_task                pa_tasks%rowtype;
        v_tasks_in_rec         pa_project_pub.task_in_rec_type;
        v_errbuf                     VARCHAR2(2500);
        v_retcode                    NUMBER :=0;
        -- Variables needed for API standard parameters
        v_api_version_number    NUMBER                                 := 1.0;
        v_commit                VARCHAR2 (1)                           := 'F';
        v_return_status         VARCHAR2 (1);
        v_init_msg_list         VARCHAR2 (1)                           := 'T';
        v_msg_count             NUMBER;
        v_msg_index_out         NUMBER;
        v_msg_data              VARCHAR2 (30000);
        v_data                  VARCHAR2 (30000);
        v_project_status_clos   VARCHAR2 (30):= 1001;
        v_business_group_id     NUMBER := 0;
        v_project_parent pa_projects_all.segment1%TYPE;
        api_error               EXCEPTION;
        v_type_action           VARCHAR2(15);
        v_out_pa_task_id        NUMBER;
        v_out_pm_task_reference pa_tasks.pm_task_reference%type;
        v_pa_project_id_out     NUMBER;
        v_pa_project_number_out pa_projects_all.segment1%type;
        v_tache_parent          pa_tasks.attribute7%type;
    BEGIN
        BEGIN

            SELECT *
            INTO v_task
            FROM PA_TASKS
            WHERE project_id =p_project.project_id
            AND task_number=p_tache.task_code;

            v_type_action := 'M à J';
            Fnd_File.put_line (Fnd_File.LOG, 'not new tache '||p_tache.task_code);
            --pour évité le cas de boucle apres nouvelle tache rennitialise v_tasks_in_rec
            copie_task_template ( -1,p_tache.task_code,v_task.cost_ind_rate_sch_id,v_tasks_in_rec,v_errbuf,v_retcode);
            IF v_retcode !=0 THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Les informations de la tache '||p_tache.task_code||' n''ont pas pu être copiées de la tache pour modification ');
                p_retcode := 1;
                p_errbuf := v_errbuf;
                RETURN;
            END IF;


            v_tasks_in_rec.pa_task_id := v_task.task_id;
            v_tasks_in_rec.pm_task_reference := v_task.pm_task_reference;
            v_tasks_in_rec.task_name := v_task.task_name;
            --v_tasks_in_rec.cost_ind_rate_sch_id := v_task.cost_ind_rate_sch_id;
            v_tasks_in_rec.task_start_date              := v_task.start_date;

            IF p_project.project_status_code != v_project_status_clos THEN -- ywa artf2080425
                v_tasks_in_rec.task_description := p_tache.description;
                v_tasks_in_rec.task_name        := p_tache.task_name;
            END IF;

            --v_tasks_in_rec.carrying_out_organization_id := v_project_in.carrying_out_organization_id; a revoir


            v_tasks_in_rec.attribute2 := v_task.attribute2;
            --maj date cloture
            IF p_tache.task_closing_date IS NOT NULL  AND (v_task.attribute2 IS NULL OR to_char(p_tache.task_closing_date,cv_std_date_mask) !=v_task.attribute2) THEN

                IF  p_tache.task_closing_date >= v_task.start_date THEN  -- OBE artf2432038
                    v_tasks_in_rec.attribute2 := to_char(p_tache.task_closing_date,cv_std_date_mask);
                ELSE
                    p_retcode := 1;
                    p_errbuf := 'La date de clôture de la tâche doit être supérieure ou égale à la date de début de la tâche';
                    RETURN;
                END IF;
            END IF;

            --maj date fin
            v_tasks_in_rec.task_completion_date := v_task.completion_date;
            IF p_tache.task_completion_date IS NOT NULL  AND  (v_task.completion_date IS NULL OR p_tache.task_completion_date !=v_task.completion_date) THEN

              IF  p_tache.task_completion_date >= v_task.start_date AND p_tache.task_completion_date >= to_date(v_tasks_in_rec.attribute2,cv_std_date_mask) THEN --artf2072190 -- OBE artf2432038
                    v_tasks_in_rec.task_completion_date := p_tache.task_completion_date;
                ELSE
                    p_retcode := 1;
                    p_errbuf := 'La date de fin/fermeture de la tâche doit être supérieure ou égale à la date de début de la tâche et à la date de clôture de la tâche';
                    RETURN;
                END IF;
            END IF;


            v_tasks_in_rec.tasks_dff := 'Y';
            v_tasks_in_rec.attribute_category := v_task.attribute_category;
            --v_tasks_in_rec.attribute3 := v_task.attribute3;

            v_tasks_in_rec.attribute4 := v_task.attribute4;
            v_tasks_in_rec.attribute1 := v_task.attribute1;
            v_tasks_in_rec.attribute6 := v_task.attribute6;
            v_tasks_in_rec.attribute7 := v_task.attribute7;--21/12

            IF v_tasks_in_rec.attribute_category = 'GY' THEN
                BEGIN
                    SELECT project_id
                    INTO v_project_parent
                    FROM pa_tasks
                    WHERE task_id= v_task.attribute7;
                EXCEPTION
                    WHEN OTHERS THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'Probleme lors de la récupération de la tâche du projet parent introuvable ou en double');
                        p_retcode := 1;
                        p_errbuf := 'Erreur lors de la récupération de la tache parent. Elle est soit introuvable ou correspond à deux possibilités.';
                        RETURN;
                END;
            END IF;

            ----p_tache.task_estimated_end_date;
            IF v_task.attribute_category IN ('GX','GT') AND v_task.attribute5 != to_char(p_tache.task_estimated_end_date,cv_std_date_mask)  AND  p_tache.task_estimated_end_date IS NOT NULL THEN
                v_tasks_in_rec.attribute5 := to_char(p_tache.task_estimated_end_date,cv_std_date_mask);
            ELSE
                v_tasks_in_rec.attribute5 := v_task.attribute5;
            END IF;

            IF  v_task.attribute4 != p_tache.work_estimated_amount THEN

                IF v_task.attribute_category = 'GX'  THEN

                    v_tasks_in_rec.attribute4 := p_tache.work_estimated_amount;

                    IF p_tache.task_attribute LIKE 'S%' THEN

                        BEGIN
                            SELECT pirsa.ind_rate_sch_id
                            INTO v_tasks_in_rec.cost_ind_rate_sch_id
                            FROM pa_segment_value_lookup_sets psvls,pa_segment_value_lookups psvl, pa_ind_rate_schedules_all_bg pirsa
                            WHERE psvls.segment_value_lookup_set_name = 'BAREME_TACHE_TEXT'
                            AND pirsa.ind_rate_sch_name = psvl.segment_value
                            AND pirsa.business_group_id= v_business_group_id
                            AND psvl.segment_value_lookup_set_id=psvls.segment_value_lookup_set_id
                            AND (p_tache.work_estimated_amount >= to_number(substr(psvl.segment_value_lookup,1,INSTR(psvl.segment_value_lookup,'-')-1))
                                    AND p_tache.work_estimated_amount <= to_number(substr(psvl.segment_value_lookup,INSTR(psvl.segment_value_lookup,'-')+1))
                                );

                        EXCEPTION
                            WHEN OTHERS THEN
                                Fnd_File.put_line (Fnd_File.LOG, 'ERREUR lors de la récupération du bareme pour la tache Spécifique GX');
                                p_retcode := 1;
                                p_errbuf := 'ERREUR lors de la récupération du bareme pour la tache Spécifique';
                                RETURN;
                        END;

                    END IF;

                ELSIF v_task.attribute_category = 'GT'  THEN
                    v_tasks_in_rec.attribute4 := p_tache.work_estimated_amount;
                END IF;

                --Fnd_File.put_line (Fnd_File.LOG, 'copie_task_template7');

            END IF ;



        EXCEPTION
            WHEN OTHERS THEN

            Fnd_File.put_line (Fnd_File.LOG, 'new tache '||p_tache.task_code ||' error' ||sqlerrm);
            --v_new := v_new+1;
            v_type_action := 'Création';
            copie_task_template ( p_project.created_from_project_id,p_tache.task_code,p_project.cost_ind_rate_sch_id,v_tasks_in_rec,v_errbuf,v_retcode);
            IF v_retcode !=0 THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Les informations de la tache '||p_tache.task_code||' n''ont pas pu être copiées du modèle de la tache');
                p_retcode := 1;
                p_errbuf := v_errbuf;
                RETURN;
            END IF;

            v_tasks_in_rec.pm_task_reference            := p_tache.task_code;
            v_tasks_in_rec.task_name                    := p_tache.task_name ;
            v_tasks_in_rec.task_description             := p_tache.description;
            --v_tasks_in_rec.pm_parent_task_reference     := '';

            IF p_project.start_date > p_tache.task_start_date THEN
                Fnd_File.put_line (Fnd_File.LOG, 'La date de début de la tache '||p_tache.task_code||' ne peut pas être inférieure à la date de début du projet');
                p_retcode := 1;
                p_errbuf := 'La date de début de la tache '||p_tache.task_code||' ne peut pas être inférieure à la date de début du projet';
                RETURN;
            END IF;
            v_tasks_in_rec.task_start_date              := p_tache.task_start_date;
            --v_tasks_in_rec.carrying_out_organization_id := v_project_in.carrying_out_organization_id;YWA 22/12
            v_tasks_in_rec.task_completion_date         := p_tache.task_completion_date;
            --l_tasks_in_rec.actual_start_date          := p_tache.task_actual_start_date;
            --l_tasks_in_rec.actual_finish_date         := p_tache.task_actual_finish_date;

            /*BEGIN
                SELECT cost_ind_rate_sch_id , limit_to_txn_controls_flag
                INTO v_tasks_in_rec.cost_ind_rate_sch_id,v_tasks_in_rec.limit_to_txn_controls_flag
                FROM pa_tasks
                WHERE project_id=p_project.created_from_project_id
                AND SUBSTR(task_number,1,2)= SUBSTR(p_tache.task_code,1,2);
            EXCEPTION
              WHEN OTHERS THEN
                v_tasks_in_rec.cost_ind_rate_sch_id := p_project.cost_ind_rate_sch_id;
                v_tasks_in_rec.limit_to_txn_controls_flag := NULL;
            END;*/--remplacer par copie_task_template

            --PROJECT_PARENT

            v_tasks_in_rec.tasks_dff := 'Y';
            v_tasks_in_rec.attribute_category := NULL;--'Global Data Elements';
            v_tasks_in_rec.attribute2 := TO_CHAR(p_tache.task_closing_date,cv_std_date_mask);
            --
            --v_tasks_in_rec.attribute3 := null;
            v_tasks_in_rec.attribute5 := null;
            v_tasks_in_rec.attribute1 := null;
            v_tasks_in_rec.attribute4 := null;
            v_tasks_in_rec.attribute6 := null;-- a revoir

            --GX (Travaux externes), GT (Travaux interne) et GY (Immo) l'attribute1
            IF SUBSTR(p_tache.task_code ,1,2) = 'GX'  THEN
                v_tasks_in_rec.attribute_category := 'GX';

                BEGIN
                    SELECT ffvv.flex_value
                    INTO v_tasks_in_rec.attribute1
                    FROM fnd_flex_value_sets ffvs,
                         fnd_flex_values_vl ffvv
                    WHERE 1=1
                    AND ffvs.flex_value_set_id        = ffvv.flex_value_set_id
                    AND ffvs.flex_value_set_name      = 'DKA_GX_TASK_ATTRIBUTE'
                    AND ffvv.enabled_flag = 'Y'
                    AND SYSDATE BETWEEN NVL(ffvv.start_date_active, SYSDATE)
                    AND NVL(ffvv.end_date_active, SYSDATE)
                    AND ffvv.flex_value = p_tache.task_attribute;
                EXCEPTION
                    WHEN OTHERS THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'L''Attribut de la tache GX est introuvable');
                        p_retcode := 1;
                        p_errbuf := 'L''Attribut de la tache GX est introuvable';
                        RETURN;
                END;

                IF p_tache.work_estimated_amount IS NOT NULL THEN
                    v_tasks_in_rec.attribute4 := p_tache.work_estimated_amount;
                ELSE
                    Fnd_File.put_line (Fnd_File.LOG, 'Le montant estimé des travaux de la tache est nul');
                    p_retcode := 1;
                    p_errbuf := 'Le montant estimé des travaux de la tache est nul';
                    RETURN;
                END IF;

                IF p_tache.task_estimated_end_date IS NOT NULL THEN
                    v_tasks_in_rec.attribute5 := to_char(p_tache.task_estimated_end_date,cv_std_date_mask);
                ELSE
                    Fnd_File.put_line (Fnd_File.LOG, 'La date de fin prévisionnelle de la tache est nulle');
                    p_retcode := 1;
                    p_errbuf := 'La date de fin prévisionnelle de la tache est nulle';
                    RETURN;
                END IF;

                --v_tasks_in_rec.attribute3 := p_tache.billed_task||p_tache.billed_task;

                IF p_tache.task_attribute like 'S%' THEN

                    BEGIN
                        SELECT pirsa.ind_rate_sch_id
                        INTO v_tasks_in_rec.cost_ind_rate_sch_id
                        FROM pa_segment_value_lookup_sets psvls,pa_segment_value_lookups psvl, pa_ind_rate_schedules_all_bg pirsa
                        WHERE psvls.segment_value_lookup_set_name = 'BAREME_TACHE_TEXT'
                        AND pirsa.ind_rate_sch_name = psvl.segment_value
                        AND pirsa.business_group_id= v_business_group_id
                        AND psvl.segment_value_lookup_set_id=psvls.segment_value_lookup_set_id
                        AND (p_tache.work_estimated_amount >= to_number(substr(psvl.segment_value_lookup,1,INSTR(psvl.segment_value_lookup,'-')-1))
                                AND p_tache.work_estimated_amount <= to_number(substr(psvl.segment_value_lookup,INSTR(psvl.segment_value_lookup,'-')+1))
                            );
                    EXCEPTION
                        WHEN OTHERS THEN
                            Fnd_File.put_line (Fnd_File.LOG, 'ERREUR lors de la récupération du bareme pour la tache Spécifique GX');
                            p_retcode := 1;
                            p_errbuf := 'ERREUR lors de la récupération du bareme pour la tache Spécifique';
                            RETURN;
                    END;
                ELSE
                    BEGIN
                        SELECT ind_rate_sch_id
                        INTO v_tasks_in_rec.cost_ind_rate_sch_id
                        FROM pa_ind_rate_schedules_all_bg
                        WHERE  ind_rate_sch_name = 'BAREME_TACHE_TEXT_15%';
                    EXCEPTION
                        WHEN OTHERS THEN
                            Fnd_File.put_line (Fnd_File.LOG, 'ERREUR lors de la récupération du bareme pour la tache Générique GX');
                            p_retcode := 1;
                            p_errbuf := 'ERREUR lors de la récupération du bareme pour la tache Générique';
                            RETURN;
                    END;
                END IF;

            END IF;

            IF SUBSTR(p_tache.task_code ,1,2) = 'GT'  THEN
                v_tasks_in_rec.attribute_category := 'GT';

                BEGIN
                    SELECT ffvv.flex_value
                    INTO v_tasks_in_rec.attribute1
                    FROM fnd_flex_value_sets ffvs,
                         fnd_flex_values_vl ffvv
                    WHERE 1=1
                    AND ffvs.flex_value_set_id        = ffvv.flex_value_set_id
                    AND ffvs.flex_value_set_name      = 'DKA_GT_TASK_ATTRIBUTE'
                    AND ffvv.ENABLED_FLAG = 'Y'
                    AND SYSDATE BETWEEN NVL(ffvv.start_date_active, SYSDATE)
                    AND NVL(ffvv.end_date_active, SYSDATE)
                    AND ffvv.flex_value = p_tache.task_attribute;
                EXCEPTION
                    WHEN OTHERS THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'L''Attribut de la tache GT est introuvable');
                        p_retcode := 1;
                        p_errbuf := 'L''Attribut de la tache GT est introuvable';
                        RETURN;
                END;

                IF p_tache.work_estimated_amount IS NOT NULL THEN
                     v_tasks_in_rec.attribute4 := p_tache.work_estimated_amount;
                ELSE
                    Fnd_File.put_line (Fnd_File.LOG, 'Le montant estimé des travaux de la tache est nul');
                    p_retcode := 1;
                    p_errbuf := 'Le montant estimé des travaux de la tache est nul';
                    RETURN;
                END IF;

                IF p_tache.task_estimated_end_date IS NOT NULL THEN
                    v_tasks_in_rec.attribute5 := to_char(p_tache.task_estimated_end_date,cv_std_date_mask);
                ELSE
                    Fnd_File.put_line (Fnd_File.LOG, 'La date de fin prévisionnelle de la tache est nulle');
                    p_retcode := 1;
                    p_errbuf := 'La date de fin prévisionnelle de la tache est nulle';
                    RETURN;

                END IF;
                BEGIN
                    SELECT pirsa.ind_rate_sch_id
                    INTO v_tasks_in_rec.cost_ind_rate_sch_id
                    FROM pa_segment_value_lookup_sets psvls,pa_segment_value_lookups psvl, pa_ind_rate_schedules_all_bg pirsa
                    WHERE psvls.segment_value_lookup_set_name = 'BAREME_TACHE_TINT'
                    AND pirsa.ind_rate_sch_name = psvl.segment_value
                    AND pirsa.business_group_id= v_business_group_id
                    AND psvl.segment_value_lookup_set_id=psvls.segment_value_lookup_set_id
                    AND psvl.segment_value_lookup = p_tache.task_attribute;
                EXCEPTION
                    WHEN OTHERS THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'ERREUR lors de la recuperation du bareme pour la tache GT BAREME_TACHE_TINT');
                        p_retcode := 1;
                        p_errbuf := 'ERREUR lors de la recuperation du bareme pour la tache';
                        RETURN;
                END;


            END IF;

            IF SUBSTR(p_tache.task_code ,1,2) = 'GY'  THEN
                v_tasks_in_rec.attribute_category := 'GY';

                BEGIN
                    SELECT category_id
                    INTO   v_tasks_in_rec.attribute6
                    FROM  fa_categories_b_kfv
                    WHERE concatenated_segments=p_tache.asset_category;
                EXCEPTION
                    WHEN OTHERS THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'La category immo est introuvable');
                        p_retcode := 1;
                        p_errbuf := 'La category immo est introuvable';
                        RETURN;
                END;

                BEGIN
                    SELECT task_id ,project_id
                    INTO  v_tasks_in_rec.attribute7 ,v_project_parent
                    FROM pa_tasks
                    WHERE task_number =p_tache.subproject_relationship;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'Erreur lors de la récupération de la tache parent. La tache parent '||p_tache.subproject_relationship||' n''existe pas');
                        p_retcode := 1;
                        p_errbuf := 'Erreur lors de la récupération de la tache parent. La tache parent '||p_tache.subproject_relationship||' n''existe pas';
                        RETURN;
                    WHEN TOO_MANY_ROWS THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'Erreur lors de la récupération de la tache parent. La tache parent '||p_tache.subproject_relationship||' est en doublon');
                        p_retcode := 1;
                        p_errbuf := 'Erreur lors de la récupération de la tache parent. La tache parent '||p_tache.subproject_relationship||' est en doublon';
                        RETURN;
                    WHEN OTHERS THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'problème lors de la récupération de la tache du projet parent : '||SQLERRM);
                        p_retcode := 1;
                        p_errbuf := 'Erreur lors de la récupération de la tache parent : '||SQLERRM;
                        RETURN;
                END;

                BEGIN
                    SELECT distinct pt.attribute7
                    INTO  v_tache_parent
                    FROM
                     pa_tasks pt,
                     pa_projects_all ppa
                    WHERE ppa.project_id = pt.project_id
                     and ppa.segment1 = p_tache.project_code
                    ;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        --Pas de tache sur le projet,on poursuit
                        NULL;
                    WHEN TOO_MANY_ROWS THEN
                        --Problème sur les projets parent
                        Fnd_File.put_line (Fnd_File.LOG, 'Erreur lors de la récupération de la tache parent sur les taches existantes. Projet : '||p_tache.project_code );
                        p_retcode := 1;
                        p_errbuf := 'Erreur lors de la récupération de la tache parent sur les taches existantes. Projet : '||p_tache.project_code;
                        RETURN;
                    WHEN OTHERS THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'Erreur lors de la récupération de la tache parent sur les taches existantes. Projet : '||p_tache.project_code||' : '||SQLERRM);
                        p_retcode := 1;
                        p_errbuf := 'Erreur lors de la récupération de la tache parent sur les taches existantes. Projet : '||p_tache.project_code||' : '||SQLERRM;
                        RETURN;
                END;

                IF v_tache_parent != v_tasks_in_rec.attribute7 THEN
                  Fnd_File.put_line (Fnd_File.LOG, 'La tache parent calculée (ID : '||v_tache_parent||') sur les taches existantes est différente de celle reçue ID:'||v_tasks_in_rec.attribute7 );
                  p_retcode := 1;
                  p_errbuf := 'La tache parent calculée (ID : '||v_tache_parent||') sur les taches existantes est différente de celle reçue ID:'||v_tasks_in_rec.attribute7 ;
                  RETURN;
                END IF;

                IF p_tache.task_attribute IN ('AMELIOR.P1(>15KE)','AMELIOR.P2(>15KE)','DEP.DE DEVELOPPT','PRODUCTION IMMO') THEN
                    BEGIN
                        SELECT ind_rate_sch_id
                        INTO v_tasks_in_rec.cost_ind_rate_sch_id
                        FROM pa_ind_rate_schedules_all_bg
                        WHERE  ind_rate_sch_name ='BAREME_TACHE_TINT.K3'
                        AND business_group_id = v_business_group_id;
                    EXCEPTION
                        WHEN OTHERS THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'ERREUR lors de la recuperation du bareme pour la tache GY BAREME_TACHE_TINT.K3');
                        p_retcode := 1;
                        p_errbuf := 'ERREUR lors de la recuperation du bareme pour la tache';
                        RETURN;
                    END;
                END IF;

            END IF;
            Fnd_File.put_line (Fnd_File.LOG, 'NEW TASK '||p_tache.task_code );
           -- v_new_task(v_new)  := p_tache.task_code;
        END;

        p_type_action := v_type_action;
        Fnd_File.put_line (Fnd_File.LOG, 'tache type_action '||p_type_action);
        IF v_type_action = 'M à J' THEN

            Fnd_File.put_line (Fnd_File.LOG, 'debut update_task');
            pa_project_pub.update_task (p_api_version_number    => v_api_version_number,
                                            p_commit                => v_commit,
                                            p_init_msg_list         => v_init_msg_list,
                                            p_msg_count             => v_msg_count,
                                            p_msg_data              => v_msg_data,
                                            p_return_status         => v_return_status,
                                            p_pm_product_code       => p_project.pm_product_code,
                                            --p_pm_project_reference  => p_project.segment1,
                                            p_pa_project_id         => p_project.project_id,
                                            p_pa_task_id            => v_tasks_in_rec.pa_task_id,
                                            p_task_name             => v_tasks_in_rec.task_name, --artf2163320
                                            p_task_description      => v_tasks_in_rec.task_description,
                                            p_tasks_dff             => v_tasks_in_rec.tasks_dff,
                                            p_task_completion_date  => v_tasks_in_rec.task_completion_date,
                                            p_attribute_category    => v_tasks_in_rec.attribute_category,
                                            p_cost_ind_rate_sch_id  => v_tasks_in_rec.cost_ind_rate_sch_id,
                                            p_attribute1            => v_tasks_in_rec.attribute1,
                                            p_attribute2            => v_tasks_in_rec.attribute2,
                                            p_attribute3            => v_tasks_in_rec.attribute3,
                                            p_attribute4            => v_tasks_in_rec.attribute4,
                                            p_attribute5            => v_tasks_in_rec.attribute5,
                                            p_attribute6            => v_tasks_in_rec.attribute6,
                                            p_attribute7            => v_tasks_in_rec.attribute7,
                                            p_out_pa_task_id        => v_out_pa_task_id,
                                            p_out_pm_task_reference => v_out_pm_task_reference
                                            );

            Fnd_File.put_line (Fnd_File.LOG, 'end update_task');
            -- Check for errors
            IF v_return_status != 'S' THEN
                Fnd_File.put_line (Fnd_File.LOG, 'v_return_status !=s update_task');
                p_retcode := 1;
                RAISE api_error;
            END IF;

        ELSE

            Fnd_File.put_line (Fnd_File.LOG, 'debut add_task');
            SAVEPOINT befor_add_task;
            pa_project_pub.add_task (   p_api_version_number    => v_api_version_number,
                                        p_commit                => v_commit,
                                        p_init_msg_list         => v_init_msg_list,
                                        p_msg_count             => v_msg_count,
                                        p_msg_data              => v_msg_data,
                                        p_return_status         => v_return_status,
                                        p_pm_product_code       => p_project.pm_product_code,
                                        p_pm_project_reference  => p_project.segment1,
                                        p_pa_project_id         => p_project.project_id,
                                        p_pm_task_reference     => v_tasks_in_rec.pm_task_reference,
                                        p_pa_task_number        => v_tasks_in_rec.pm_task_reference,
                                        p_task_name             => v_tasks_in_rec.task_name,
                                        --p_long_task_name        => v_tasks_in_rec.,
                                        p_task_description      => v_tasks_in_rec.task_description,
                                        p_task_start_date       => v_tasks_in_rec.task_start_date,
                                        p_task_completion_date  => v_tasks_in_rec.task_completion_date,
                                        p_tasks_dff             => v_tasks_in_rec.tasks_dff,
                                        p_attribute_category    => v_tasks_in_rec.attribute_category,
                                        p_cost_ind_rate_sch_id  => v_tasks_in_rec.cost_ind_rate_sch_id,
                                        p_attribute1            => v_tasks_in_rec.attribute1,
                                        p_attribute2            => v_tasks_in_rec.attribute2,
                                        p_attribute3            => v_tasks_in_rec.attribute3,
                                        p_attribute4            => v_tasks_in_rec.attribute4,
                                        p_attribute5            => v_tasks_in_rec.attribute5,
                                        p_attribute6            => v_tasks_in_rec.attribute6,
                                        p_attribute7            => v_tasks_in_rec.attribute7,
                                        p_limit_to_txn_controls_flag => v_tasks_in_rec.limit_to_txn_controls_flag,
                                        p_pa_project_id_out     => v_pa_project_id_out,
                                        p_pa_project_number_out => v_pa_project_number_out,
                                        p_task_id               => v_out_pa_task_id,
                                        p_structure_updates_flag => 'N' --artf2152566
                                        );

            v_tasks_in_rec.pa_task_id := v_out_pa_task_id;
            Fnd_File.put_line (Fnd_File.LOG, 'end add_task');
            -- Check for errors
            IF v_return_status != 'S' THEN
                Fnd_File.put_line (Fnd_File.LOG, 'v_return_status !=s add_task');
                p_retcode := 1;
                RAISE api_error;

            END IF;

            /*SELECT task_id
            INTO v_new_task_id
            FROM pa_tasks WHERE task_number= v_pa_project_number_out AND project_id=p_project.project_id ;*/

            --mouvements de controles
            --Fnd_File.put_line (Fnd_File.LOG,'mouvements de controles');
            controle_mouvements  (p_project.created_from_project_id,p_project.project_id,v_out_pa_task_id,v_errbuf,v_retcode);
            IF v_retcode != 0 THEN
                p_errbuf  := v_errbuf;
                p_retcode := v_retcode;
                ROLLBACK TO SAVEPOINT befor_add_task;
                RETURN;
            END IF;

            add_immo_gy  (p_project.project_id,p_project.segment1,v_out_pa_task_id,p_project.pm_product_code,v_errbuf,v_retcode);
            IF v_retcode != 0 THEN
                p_errbuf  := v_errbuf;
                p_retcode := v_retcode;
                ROLLBACK TO SAVEPOINT befor_add_task;
                RETURN;
            END IF;


        END IF;
        --p_task_id := v_out_pa_task_id;
        p_tasks_in_rec := v_tasks_in_rec;

    EXCEPTION
        WHEN api_error THEN

        IF v_msg_count >= 1 THEN
            /*FOR i IN 1 .. v_msg_count LOOP
                pa_interface_utils_pub.get_messages
                                              (p_msg_data           => v_msg_data,
                                               p_encoded            => 'F',
                                               p_data               => v_data,
                                               p_msg_count          => v_msg_count,
                                               --p_msg_index          => v_msg_count,
                                               p_msg_index_out      => v_msg_index_out
                                              );
                Fnd_File.put_line (Fnd_File.LOG,'error message: ' || v_data);
                p_errbuf := SUBSTR(p_errbuf || v_data,0,240);
            END LOOP;*/
            FOR i IN 1 .. v_msg_count
            LOOP
              fnd_msg_pub.get (i, fnd_api.g_false, v_msg_data, v_data);
              p_errbuf := SUBSTR(p_errbuf || v_msg_data,0,240);
              --DBMS_OUTPUT.put_line ( 'Error: API Error while add the Task: ' || p_errbuf );
              Fnd_File.put_line (Fnd_File.LOG, 'Error: API Error while add the Task: ' || p_errbuf );

            END LOOP;
        END IF;

        WHEN OTHERS THEN
            p_errbuf  := 'ERREUR tache_action '||sqlerrm;
            p_retcode := 2;
            Fnd_File.put_line (Fnd_File.LOG,'ERREUR tache_action '||sqlerrm);

    END tache_action;    -- YWA artf2131956



    /*=====================================================================================*/
    /* PROCEDURE NAME : update_project
    /*
    /* DESCRIPTION
    /*  Procédure principale de l'interface de modification d'un projet et tache
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/
    PROCEDURE update_project (p_project  dka_eai_projet%rowtype,
                                p_errbuf OUT VARCHAR2,
                                p_retcode OUT NUMBER
                    )
    IS

          -- Variables needed to create task hierachy

        v_i                      NUMBER;

        v_errbuf                     VARCHAR2(2500);
        v_retcode                    NUMBER;
        v_business_group_id      NUMBER := 0;
        v_project_status_clos VARCHAR2 (30) := 1001;
        -- Variables needed for API standard parameters
        v_api_version_number   NUMBER                                 := 1.0;
        v_commit               VARCHAR2 (1)                           := 'F';
        v_return_status        VARCHAR2 (1);
        v_init_msg_list        VARCHAR2 (1)                           := 'T';
        v_msg_count            NUMBER;
        v_msg_index_out        NUMBER;
        v_msg_data             VARCHAR2 (30000);
        v_data                 VARCHAR2 (30000);
        v_workflow_started     VARCHAR2 (1)                           := 'Y';
        v_pm_product_code      VARCHAR2 (10);
        -- Predefined Composit data types
        v_project_in           pa_project_pub.project_in_rec_type;
        v_project_out          pa_project_pub.project_out_rec_type;
        v_key_members          pa_project_pub.project_role_tbl_type;
        v_class_categories     pa_project_pub.class_category_tbl_type;
        v_tasks_in_rec         pa_project_pub.task_in_rec_type;
        v_tasks_in             pa_project_pub.task_in_tbl_type;
        v_tasks_out            pa_project_pub.task_out_tbl_type;


        api_error              EXCEPTION;
        v_new_class_code          VARCHAR2 (30);

        v_code_affaire         pa_class_codes.class_code%type;
        v_code_activite        pa_class_codes.class_code%type;
        v_code_filiere         pa_class_codes.class_code%type;
        v_code_destination     pa_class_codes.class_code%type;

        v_project              pa_projects_all%rowtype;


        v_date_from_cf          DATE;
        v_old_organization_id  hr_all_organization_units.organization_id%type;
        v_new_organization_id  hr_all_organization_units.organization_id%type;
        v_task                pa_tasks%rowtype;
        v_new_name_cf         hr_all_organization_units.name%type;
        v_old_name_cf         hr_all_organization_units.name%type;
        v_rowid rowid;
        v_cost_dist_override_id   pa_cost_dist_overrides.cost_distribution_override_id%type;
        v_start_date_active   pa_cost_dist_overrides.start_date_active%type;
        v_start_date DATE;

        v_non_cloture_task BOOLEAN;
        v_max_fin_task_date  DATE;
        v_max_cloture_task VARCHAR2(30);
        v_non_fin_task BOOLEAN;
        v_project_parent          pa_projects_all.segment1%TYPE;
        v_created_from_project_id NUMBER;
        TYPE new_task_type IS TABLE OF  VARCHAR2(30)  INDEX BY BINARY_INTEGER;

        v_new_task  new_task_type;
        v_new NUMBER;
        v_new_task_id NUMBER;

        v_period_start_date DATE; --artf2064994
        v_in_futur_period   NUMBER; --artf2064994
        v_type_action   VARCHAR2(10);

        vn_nb_task NUMBER; -- JWY artf07314292



        ---- Curosr to get Project Task Details ------------------------
        CURSOR taches (p_project_code VARCHAR2)
        IS
            SELECT *
            FROM DKA_EAI_TACHE
            WHERE OA_STATUS != 'PROCESSED' AND project_code = p_project_code
            AND     id IS NULL
            ORDER BY task_code,creation_date for update; --YWA artf2131655 --task_name;

        ---- Curosr to get Project Task oracle ------------------------
        CURSOR taches_oa (p_project_id NUMBER)
        IS
            SELECT *
            FROM pa_tasks
            WHERE project_id = p_project_id; --YWA

    BEGIN
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début update_project');
        p_errbuf  := null;
        p_retcode := 0;

        SELECT *
        INTO v_project
        FROM pa_projects_all
        WHERE segment1 = p_project.project_code;


        --IF v_project.project_status_code != v_project_status_code THEN --ywa artf2080425

            g_org_id := v_project.org_id;


            init_environement(v_errbuf, v_retcode);

            IF v_retcode != 0 THEN
                p_errbuf  := v_errbuf;
                p_retcode := v_retcode;
                RETURN;
            END IF;
            v_errbuf := null;

            v_project_in.pa_project_id              := v_project.project_id;
            v_project_in.pm_project_reference       := p_project.project_code;--'Project Reference'

            IF v_project.project_status_code != v_project_status_clos THEN -- YWA artf2080425
                v_project_in.project_name               := SUBSTR(p_project.project_code||'-'||p_project.libelle,1,30);--Project Name ;
                v_project_in.description                := SUBSTR(p_project.libelle,1,250); --ywa artf2076737 -- RBE artf2089025
                v_project_in.long_name                  := SUBSTR(p_project.project_code||'-'||p_project.libelle,1,240); --v_project_in.description; --artf2064984 -- RBE artf2089025

            END IF;

            v_pm_product_code                       := v_project.pm_product_code;


            BEGIN

                --new centre de finance
                SELECT organization_id,name
                INTO  v_new_organization_id,
                     v_new_name_cf
                FROM hr_all_organization_units
                WHERE name = p_project.organization_name
                AND business_group_id=v_business_group_id;
            EXCEPTION
             WHEN OTHERS
             THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Centre de finance introuvable');
                p_retcode := 1;
                p_errbuf := 'Centre de finance introuvable';
                RETURN;
            END;


            v_i:=0;
            v_max_fin_task_date := NULL;
            v_max_cloture_task := NULL;
            v_non_cloture_task := FALSE;
            v_non_fin_task := FALSE;
            v_new := 0;
            --TASKS DATA
            FOR t IN taches (p_project.project_code) LOOP

                tache_action(v_project,t,v_type_action,v_tasks_in_rec,v_errbuf,v_retcode);

                IF v_retcode !=0 THEN
                    UPDATE dka_eai_tache
                    SET    oa_status ='REJECT',
                           oa_rejection_reason = v_errbuf,
                           oa_request_id =g_request_id,
                           --oa_action_type = v_type_action,
                           last_updated_by = 	g_user_id,
                           last_update_date = sysdate
                    WHERE  CURRENT OF taches;
                    g_task_reject :=g_task_reject+1;
                    Fnd_File.put_line (Fnd_File.LOG, 'ERREUR sur la tache '||t.task_code ||' '|| SQLERRM);
                    p_retcode := 1;
                    p_errbuf := 'ERREUR sur la tache '||t.task_code;
                    RETURN;

                ELSE
                    UPDATE dka_eai_tache
                    SET    oa_status ='PROCESSED',
                           oa_rejection_reason = NULL,
                           oa_request_id =g_request_id,
                           --oa_action_type = v_type_action,
                           id = v_tasks_in_rec.pa_task_id,
                           last_updated_by = 	g_user_id,
                           last_update_date = sysdate
                    WHERE  CURRENT OF taches;
                    g_task_validate:=g_task_validate+1;-- ywa artf2140013
                    --Fnd_File.put_line (Fnd_File.LOG, 'la tache update_project '||g_task_validate);
                END IF;

            END LOOP;

            --< JWY artf07314292
            -- Vérification de l'existance de taches associees au projet
            SELECT count(*)
            INTO vn_nb_task
            FROM pa_tasks pt
            WHERE pt.project_id = v_project.project_id;

            -- S'il existe des tâches, on vérifie les dates de fin
            IF (vn_nb_task > 0) THEN

            --> JWY artf07314292

              FOR t IN taches_oa(v_project.project_id) LOOP
                  IF nvl(v_max_fin_task_date, t.completion_date-1) < t.completion_date THEN
                      v_max_fin_task_date := t.completion_date;
                  END IF;

                  IF to_date(nvl(v_max_cloture_task, t.attribute2),cv_std_date_mask) <= to_date(t.attribute2,cv_std_date_mask) THEN
                      v_max_cloture_task := t.attribute2;
                  END IF;

                  -- SI PAS Toutes les tâches du projet sont clôturées
                  IF  t.attribute2 IS NULL THEN  --artf2164140
                      v_non_cloture_task := true;
                  END IF;
                  -- SI PAS Toutes les tâches du projet sont fermées
                  IF t.completion_date IS NULL THEN  --artf2164140
                      v_non_fin_task := true;
                  END IF;


              END LOOP;--YWA artf2131956

            --< JWY artf07314292
            -- S'il n'existe pas de tâche, on initiale la date de fin de tâche à la valeur de la date de fin du projet afin de ne pas bloqeur les contrôles suivants
            ELSE

              v_max_fin_task_date := p_project.project_completion_date;
              v_max_cloture_task := p_project.project_completion_date;

            END IF;

            --> JWY artf07314292

            v_project_in.attribute8        := v_project.attribute8 ;

            --Mise à jour de la date de clôture d'un projet (CUF ATTRIBUTE8)
            IF p_project.project_closing_date IS NOT NULL  AND (v_project.attribute8 IS NULL OR to_char(p_project.project_closing_date,cv_std_date_mask) != v_project.attribute8)   THEN

                --Fnd_File.put_line (Fnd_File.LOG, 'v_max_cloture_task '||v_max_cloture_task);
                IF  p_project.project_closing_date  >= v_project.start_date AND p_project.project_closing_date >= to_date(v_max_cloture_task,cv_std_date_mask) THEN--artf2072174 -- OBE artf2432038

                    IF not(v_non_cloture_task)   THEN
                        v_project_in.attribute8        := to_char(p_project.project_closing_date,cv_std_date_mask);
                    ELSE
                        p_retcode := 1;
                        p_errbuf := 'erreur lors de la MAJ de la date de cloture du projet : toutes les tâches du projet doivent avoir une date de clôture';
                        RETURN;
                    END IF;
                    --STATUT DE CLOTURE A REVOIR
                    /*IF p_project.project_closing_date  <= SYSDATE THEN
                        v_project_in.project_status_code    := v_project_status_code;
                        v_project_in.description            := SUBSTR(v_project_in.description||' Clôturé le '||p_project.project_completion_date,1,228);--mofid
                        --CUF
                        v_project_in.attribute_category := 'Global Data Elements';
                        v_project_in.attribute7         := SYSDATE;
                    END IF;*/

                ELSE
                    p_retcode := 1;
                    p_errbuf := 'La date de clôture de projet doit être supérieure ou égale à la date de début de projet et supérieure ou égale à toutes les dates de clôture des tâches';
                    RETURN;
                END IF;
            END IF;


            IF p_project.project_completion_date IS NOT NULL AND ( v_project.completion_date IS NULL OR p_project.project_completion_date !=v_project.completion_date)  THEN

                IF  p_project.project_completion_date >= v_project.start_date AND p_project.project_completion_date >= to_date(v_project_in.attribute8,cv_std_date_mask)  THEN -- OBE artf2432038

                   IF p_project.project_completion_date >= v_max_fin_task_date THEN -- OBE artf2432038

                        IF not(v_non_fin_task)   THEN
                            v_project_in.completion_date        := p_project.project_completion_date;

                        ELSE
                            p_retcode := 1;
                            p_errbuf := 'Toutes les tâches du projet doivent etre fermées';
                            RETURN;
                        END IF;


                    ELSE

                        p_retcode := 1;
                        p_errbuf := 'La date de fin de projet doit être supérieure ou égale à la plus grande des dates de fermeture des tâches';
                        RETURN;

                    END IF;

                ELSE
                    p_retcode := 1;
                    p_errbuf := 'La date de fin de projet doit être supérieure ou égale à la date de début de projet et à la date de clôture du projet ';
                    RETURN;
                END IF;
            END IF;

            v_project_in.start_date             := p_project.project_start_date;--10/09/2025 RTM Migration 12.2.14 
            v_project_in.process_mode           := 'ONLINE';

            SAVEPOINT befor_update_projet;
            --INIT_update_project
            pa_project_pub.init_project;
            --update_project
            Fnd_File.put_line (Fnd_File.LOG, 'start update_project');
            pa_project_pub.update_project (v_api_version_number,
                                            p_commit                => v_commit,
                                            p_init_msg_list         => v_init_msg_list,
                                            p_msg_count             => v_msg_count,
                                            p_msg_data              => v_msg_data,
                                            p_return_status         => v_return_status,
                                            p_workflow_started      => v_workflow_started,
                                            p_pm_product_code       => v_pm_product_code,
                                            p_project_in            => v_project_in,
                                            p_project_out           => v_project_out,
                                            p_key_members           => v_key_members,
                                            p_class_categories      => v_class_categories,
                                            p_tasks_in              => v_tasks_in,
                                            p_tasks_out             => v_tasks_out
                                            );
            Fnd_File.put_line (Fnd_File.LOG, 'end update_project');
            -- Check for errors
            IF v_return_status != 'S' THEN
                Fnd_File.put_line (Fnd_File.LOG, 'v_return_status !=s update_project');
                p_retcode := 1;
                RAISE api_error;
            END IF;

            IF v_return_status ='S' THEN
                Fnd_File.put_line (Fnd_File.LOG,'Project Id: ' || v_project.project_id);
                Fnd_File.put_line (Fnd_File.LOG,'Project Number: ' || v_project.segment1);
                --VALIDATE
                p_retcode := 0;
                p_errbuf := v_project.project_id;

                create_update_flex_value('DAOPCCF_PROJETFI',v_project_in.pm_project_reference ,NULL,p_project.libelle ,p_project.project_start_date,p_project.project_completion_date,v_errbuf,v_retcode);
                IF v_retcode != 0 THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    ROLLBACK TO SAVEPOINT befor_update_projet;
                    RETURN;

                END IF;



                --IF TO_CHAR(p_project.organization_start_date,'dd') = '01' THEN --AND p_project.organization_start_date >= v_date_from_cf THEN
                --v_project_in.carrying_out_organization_id := v_new_organization_id;
                Fnd_File.put_line (Fnd_File.LOG,'Modification du bloc nouvelle organisation');
                -- Mise à jour de la date de fin de l'ancienne organisation  --
                BEGIN

                    SELECT rowid,cost_distribution_override_id,start_date_active,override_to_organization_id
                    INTO v_rowid,v_cost_dist_override_id,v_start_date_active ,v_old_organization_id
                    FROM pa_cost_dist_overrides
                    WHERE project_id = v_project.project_id
                    AND end_date_active IS NULL;

                    --IF v_old_name_cf != v_new_name_cf THEN
                    IF v_old_organization_id != v_new_organization_id THEN  --YWA
                        -- Vérification la date de début de l'organisation doit etre 01 ou un début de période PA
                        BEGIN
                              SELECT start_date
                              INTO v_period_start_date
                              FROM pa_periods_all
                              where   1=1
                              --STATUS = 'O'
                              AND ( start_date = p_project.organization_start_date or TO_CHAR(p_project.organization_start_date,'dd') = '01' )
                              AND org_id = g_org_id
                              AND ROWNUM <2
                              ORDER BY start_date DESC;
                        EXCEPTION
                              WHEN NO_DATA_FOUND THEN
                                 Fnd_File.put_line (Fnd_File.LOG, 'La date du nouveau centre de finance est invalide. la date dedébut de validité doit être un premier jour du mois ou un premier jour de période');
                                p_retcode := 1;
                                p_errbuf := 'La date du nouveau centre de finance est invalide. la date de début de validité doit être un premier jour du mois ou un premier jour de période';
                                ROLLBACK TO SAVEPOINT befor_update_projet;
                                RETURN;
                        END;


                        IF v_start_date_active < p_project.organization_start_date THEN

                            BEGIN
                                /*SELECT DISTINCT start_date
                                INTO v_start_date
                                FROM gl_period_statuses
                                WHERE application_id=275
                                --AND period_year=EXTRACT(YEAR FROM p_project.organization_start_date) --artf2072122
                                AND ledger_id in( SELECT ledger_id FROM   gl_access_set_ledgers  WHERE access_set_id = fnd_profile.value('GL_ACCESS_SET_ID'))
                                AND p_project.organization_start_date  BETWEEN  start_date AND end_date
                                AND effective_period_num > g_effective_period_num;*/

                                SELECT start_date
                                INTO v_start_date
                                FROM pa_periods_all ppa,
                                    per_security_profiles_v psp,
                                    per_security_organizations_v pso
                                WHERE p_project.organization_start_date  BETWEEN  start_date AND end_date
                                AND  start_date > g_end_date_en_cours
                                AND pso.security_profile_id = psp.security_profile_id
                                AND psp.security_profile_id = FND_PROFILE.VALUE ('XLA_MO_SECURITY_PROFILE_LEVEL')
                                AND pso.organization_id        = ppa.org_id --YWA artf2076305
                                AND ROWNUM <2 ;--artf2072122

                            EXCEPTION
                                WHEN OTHERS THEN
                                    /*p_errbuf  := 'La période PA correspondant à la date de début du centre finance, est strictement postérieure à la période PA en cours ';
                                    p_retcode := 1;
                                    Fnd_File.put_line (Fnd_File.LOG,p_errbuf||sqlerrm);*/
                                    Fnd_File.put_line (Fnd_File.LOG, 'La période PA correspondant à la date de début du centre finance, est strictement postérieure à la période PA en cours ');
                                    p_retcode := 1;
									-- artf07318822 OCL
                                    p_errbuf := 'La période PA correspondant à la date de début du centre finance, est strictement postérieure à la période PA en cours';
									-- artf07318822 /
                                    ROLLBACK TO SAVEPOINT befor_update_projet;
                                    RETURN;
                            END;

                            BEGIN
                                pa_cost_dist_overrides_pkg.Update_Row(   x_rowid                      =>     v_rowid,
                                                                        x_cost_dist_override_id      =>     v_cost_dist_override_id,
                                                                        x_project_id                 =>     v_project.project_id,
                                                                        x_override_to_org_id         =>     v_old_organization_id,
                                                                        x_start_date_active          =>     v_start_date_active,
                                                                        x_last_update_date           =>     SYSDATE,
                                                                        x_last_updated_by            =>     g_user_id,
                                                                        x_last_update_login          =>     g_login_id,
                                                                        x_person_id                  =>     NULL,
                                                                        x_expenditure_category       =>     NULL,
                                                                        x_override_from_org_id       =>     v_old_organization_id,
                                                                        x_end_date_active            =>     v_start_date-1

                                                                    );
                            EXCEPTION
                                WHEN OTHERS THEN
                                    Fnd_File.put_line (Fnd_File.LOG, 'error lors de la modififcation de l''ancien centre de finance '|| SQLERRM);
                                    p_retcode := 1;
                                    p_errbuf  := 'error lors de la modififcation de l''ancien centre de finance: ' || SQLERRM;
                                    ROLLBACK TO SAVEPOINT befor_update_projet;
                                    RETURN;
                            END;
                            v_rowid := null;
                            v_cost_dist_override_id := null;
                            -- Insertion de la nouvelle organisation du projet --
                            BEGIN
                                pa_cost_dist_overrides_pkg.Insert_Row( x_rowid                  =>     v_rowid,
                                                                   x_cost_dist_override_id      =>     v_cost_dist_override_id,
                                                                   x_project_id                 =>     v_project.project_id,
                                                                   x_override_to_org_id         =>     v_new_organization_id,
                                                                   x_start_date_active          =>     v_start_date,
                                                                   x_last_update_date           =>     SYSDATE,
                                                                   x_last_updated_by            =>     g_user_id,
                                                                   x_creation_date              =>     SYSDATE,
                                                                   x_created_by                 =>     g_user_id,
                                                                   x_last_update_login          =>     g_login_id,
                                                                   x_person_id                  =>     NULL,
                                                                   x_expenditure_category       =>     NULL,
                                                                   x_override_from_org_id       =>     v_new_organization_id, --v_old_organization_id,
                                                                   x_end_date_active            =>     NULL
                                                                );
                            EXCEPTION
                                WHEN OTHERS THEN
                                    Fnd_File.put_line (Fnd_File.LOG, 'ERREUR lors de la modification de la nouvelle organisation qui permettra de gérer les mouvements sur projet à date d''effet ');
                                    p_retcode := 1;
                                    p_errbuf := 'ERREUR lors de la modification de la nouvelle organisation qui permettra de gérer les mouvements sur projet à date d''effet  '|| SQLERRM;
                                    ROLLBACK TO SAVEPOINT befor_update_projet;
                                    RETURN;
                            END;
                        ELSE
                            Fnd_File.put_line (Fnd_File.LOG, 'La date de début du nouveau centre finance fournie est antérieure à la date de debut de l''ancien centre de finance. Elle doit être dans le futur');
                            p_retcode := 1;
                            p_errbuf := 'La date de début du nouveau centre finance fournie est antérieure ou correspond à la date de debut de l''ancien centre de finance. Elle doit être dans le futur';
                            ROLLBACK TO SAVEPOINT befor_update_projet;
                            RETURN;
                        END IF;
                    END IF;--YWA 22/11
                EXCEPTION
                    WHEN OTHERS THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'ancienne organisation introuvable');
                        p_retcode := 1;
                        p_errbuf := 'ancienne organisation introuvable';
                        ROLLBACK TO SAVEPOINT befor_update_projet;
                        RETURN;
                END;

                /*ELSE
                    Fnd_File.put_line (Fnd_File.LOG, 'La date du nouveau centre de finance est invalide la date de début de validité doit être un premier jour du mois et être supérieure ou égale à la date de début de validité de l''ancien centre finance');
                    p_retcode := 1;
                    p_errbuf := 'La date du nouveau centre de finance est invalide la date de début de validité doit  être un premier jour du mois et être supérieure ou égale à la date de début de validité de l''ancien centre finance';
                    RETURN;
                END IF;*/



                Fnd_File.put_line (Fnd_File.LOG,' phase des update_pa_project_classes');
                --mofid

                IF p_project.code_affaire IS NOT NULL THEN

                    IF p_project.code_activite IS NULL THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'Il n''a pas de code activité parent');
                        p_retcode := 1;
                        p_errbuf := 'Il n''a pas de code activité parent';
                        ROLLBACK TO SAVEPOINT befor_update_projet;
                        RETURN;
                    /*ELSE

                        BEGIN
                            SELECT class_code
                            INTO v_code_activite
                            FROM pa_class_codes
                            WHERE  class_category = 'ACTIVITE'
                            AND class_code = p_project.code_activite;
                        EXCEPTION
                          WHEN OTHERS THEN
                            Fnd_File.put_line (Fnd_File.LOG, 'Le code class ACTIVITE est erroné');
                            p_retcode := 1;
                            p_errbuf := 'Le code class ACTIVITE est erroné';
                            ROLLBACK TO SAVEPOINT befor_update_projet;
                            RETURN;
                        END;*/

                    END IF ;

                    update_pa_project_classes(v_project.project_id,'AFFAIRE',p_project.code_affaire,p_project.code_activite,v_errbuf,v_retcode);
                    IF v_retcode != 0 THEN
                        p_errbuf  := v_errbuf;
                        p_retcode := v_retcode;
                        ROLLBACK TO SAVEPOINT befor_update_projet;
                        RETURN;
                    END IF;
                ELSIF p_project.project_template  = p_project.operating_unit||'.ORGANIQUE' THEN
                    BEGIN
                        SELECT class_code
                        INTO v_new_class_code
                        FROM pa_project_classes
                        WHERE project_id=v_project.created_from_project_id
                        AND class_category= 'AFFAIRE'
                        AND object_type = 'PA_PROJECTS'
                        AND object_id = v_project.created_from_project_id;

                       update_pa_project_classes(v_project.project_id,'AFFAIRE',v_new_class_code,null,v_errbuf,v_retcode);
                        IF v_retcode != 0 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            ROLLBACK TO SAVEPOINT befor_update_projet;
                            RETURN;
                        END IF;

                    EXCEPTION
                          WHEN OTHERS THEN
                            Fnd_File.put_line (Fnd_File.LOG, 'Erreur lors de la récupération du code affaire pour le projet ORGANIQUE à partir du template');
                            p_retcode := 1;
                            p_errbuf := 'Erreur lors de la récupération du code affaire pour le projet ORGANIQUE à partir du template';
                            ROLLBACK TO SAVEPOINT befor_update_projet;
                            RETURN;
                    END;



                ELSIF  UPPER(p_project.project_type) = 'INVESTISSEMENT'  THEN  --SFD 2.6V

                    BEGIN
                       SELECT DISTINCT ppa.created_from_project_id,ppa.segment1
                       INTO v_created_from_project_id,v_project_parent
                       FROM
                        pa_projects_all ppa_e,
                        pa_tasks pt_e,
                        pa_tasks pt,
                        pa_projects_all ppa
                       WHERE ppa_e.segment1= p_project.project_code
                        and pt_e.project_id = ppa_e.project_id
                        AND pt.TASK_ID = pt_e.attribute7
                        AND pt.project_id = ppa.project_id;
                    EXCEPTION
                      WHEN OTHERS THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'Erreur lors de la récupération projet parent');
                        p_retcode := 1;
                        p_errbuf := 'Erreur lors de la récupération projet parent';
                        RETURN;
                    END;

                    BEGIN
                        SELECT ppc.class_code
                        INTO v_new_class_code
                        FROM pa_project_classes ppc,pa_projects_all ppa
                        WHERE ppc.project_id= ppa.project_id
                        AND ppa.project_id = v_created_from_project_id
                        AND ppa.segment1 LIKE '%ORGANIQUE%'
                        AND ppc.class_category= 'AFFAIRE'
                        AND ppc.object_type = 'PA_PROJECTS'
                        AND ppc.object_id = ppa.project_id;

                        update_pa_project_classes(v_project.project_id,'AFFAIRE',v_new_class_code,null,v_errbuf,v_retcode);
                        IF v_retcode != 0 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            ROLLBACK TO SAVEPOINT befor_update_projet;
                            RETURN;
                        END IF;

                    EXCEPTION
                      WHEN OTHERS THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'Erreur lors de la récupération du code affaire à partir du projet parent (uniquement pour les parents organiques) ');
                        p_retcode := 1;
                        p_errbuf := 'Erreur lors de la récupération du code affaire à partir du projet parent (uniquement pour les parents organiques)';
                        RETURN;
                    END;

                ELSE
                    Fnd_File.put_line (Fnd_File.LOG, 'Le code class AFFAIRE est nul');
                    p_retcode := 1;
                    p_errbuf := 'Le code class AFFAIRE est nul';
                    ROLLBACK TO SAVEPOINT befor_update_projet;
                    RETURN;

                END IF ;

                IF p_project.code_filiere IS NOT NULL THEN
                    BEGIN
                        SELECT class_code
                        INTO v_code_filiere
                        FROM pa_class_codes
                        WHERE  class_category = 'FILIERE'
                        AND class_code = p_project.code_filiere;
                    EXCEPTION
                      WHEN OTHERS THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'Le code class FILIERE est erroné');
                        p_retcode := 1;
                        p_errbuf := 'Le code class FILIERE est erroné';
                        ROLLBACK TO SAVEPOINT befor_update_projet;
                        RETURN;
                    END;
                    update_pa_project_classes(v_project.project_id,'FILIERE',p_project.code_filiere,null,v_errbuf,v_retcode);
                    IF v_retcode != 0 THEN
                        p_errbuf  := v_errbuf;
                        p_retcode := v_retcode;
                        ROLLBACK TO SAVEPOINT befor_update_projet;
                        RETURN;
                    END IF;
                END IF ;
                IF p_project.code_destination IS NOT NULL THEN
                    BEGIN
                        SELECT class_code
                        INTO v_code_destination
                        FROM pa_class_codes
                        WHERE  class_category = 'DESTINATION'
                        AND class_code = p_project.code_destination;
                    EXCEPTION
                      WHEN OTHERS THEN
                        Fnd_File.put_line (Fnd_File.LOG, 'Le code class DESTINATION est erroné');
                        p_retcode := 1;
                        p_errbuf := 'Le code class DESTINATION est erroné';
                        ROLLBACK TO SAVEPOINT befor_update_projet;
                        RETURN;
                    END;
                    update_pa_project_classes(v_project.project_id,'DESTINATION',p_project.code_destination,null,v_errbuf,v_retcode);
                    IF v_retcode != 0 THEN
                        p_errbuf  := v_errbuf;
                        p_retcode := v_retcode;
                        RETURN;
                    END IF;
                END IF ;

                --Fnd_File.put_line (Fnd_File.LOG,'v_new_task.count'|| v_new_task.count);
                --Fnd_File.put_line (Fnd_File.LOG,'v_project_out.pa_project_id'|| v_project_out.pa_project_id);

                /*FOR i IN 1..v_new_task.count LOOP
                    --Fnd_File.put_line (Fnd_File.LOG,'AVAN MODIF mouvements de controles'|| v_new_task(i));
                    SELECT task_id
                    INTO v_new_task_id
                    FROM pa_tasks WHERE task_number= v_new_task(i) AND project_id=v_project.project_id ;

                    --mouvements de controles
                    --Fnd_File.put_line (Fnd_File.LOG,'mouvements de controles');
                    controle_mouvements  (v_project.created_from_project_id,v_project.project_id,v_new_task_id,v_errbuf,v_retcode);
                    IF v_retcode != 0 THEN
                        p_errbuf  := v_errbuf;
                        p_retcode := v_retcode;
                        ROLLBACK TO SAVEPOINT befor_update_projet;
                        RETURN;
                    END IF;

                    add_immo_gy  (v_project.project_id,v_project.segment1,v_new_task_id,v_pm_product_code,v_errbuf,v_retcode);
                    IF v_retcode != 0 THEN
                        p_errbuf  := v_errbuf;
                        p_retcode := v_retcode;
                        ROLLBACK TO SAVEPOINT befor_update_projet;
                        RETURN;
                    END IF;
                END LOOP;*/--YWA artf2131956
            END IF;
        /*ELSE


            Fnd_File.put_line (Fnd_File.log, 'mise à jour non autorisée le projet est déjà clôturé');
            p_retcode := 0;
            p_errbuf := v_project.project_id;

        END IF;*/-- YWA artf2080425

        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'fin update_project');
    EXCEPTION
        WHEN api_error THEN

        IF v_msg_count >= 1 THEN
            FOR i IN 1 .. v_msg_count LOOP
                pa_interface_utils_pub.get_messages
                                              (p_msg_data           => v_msg_data,
                                               p_encoded            => 'F',
                                               p_data               => v_data,
                                               p_msg_count          => v_msg_count,
                                               p_msg_index          => i,--10/09/2025 RTM Migration 12.2.14 --p_msg_index          => v_msg_count,
                                               p_msg_index_out      => v_msg_index_out
                                              );
                Fnd_File.put_line (Fnd_File.LOG,'error message: ' || v_data);
                p_errbuf := SUBSTR(p_errbuf || v_data,0,240);
            END LOOP;
        END IF;
        WHEN OTHERS THEN
            IF v_msg_count >= 1 THEN

                FOR i IN 1 .. v_msg_count LOOP
                    pa_interface_utils_pub.get_messages
                                                  (p_msg_count          => v_msg_count,
                                                   p_encoded            => 'F',
                                                   p_msg_data           => v_msg_data,
                                                   p_data               => v_data,
                                                   p_msg_index          => i,--10/09/2025 RTM Migration 12.2.14 -- p_msg_index          => v_msg_count,
                                                   p_msg_index_out      => v_msg_index_out
                                                  );
                    Fnd_File.put_line (Fnd_File.LOG,'error message: ' || v_data);
                    p_errbuf := SUBSTR(p_errbuf || v_data,0,240);
                END LOOP;
            ELSE
                p_errbuf := sqlerrm;
                p_retcode := 2;
            END IF;



    END update_project;

    /*=====================================================================================*/
    /* PROCEDURE NAME : create_project
    /*
    /* DESCRIPTION
    /*  Procédure principale de l'interface de création dun projet et tache
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/
    PROCEDURE create_project (p_project  dka_eai_projet%rowtype,
                                p_errbuf OUT VARCHAR2,
                                p_retcode OUT NUMBER
                    )
    IS

          -- Variables needed to create task hierachy

        v_i                      NUMBER;

        v_errbuf                     VARCHAR2(2500);
        v_retcode                    NUMBER;
        v_business_group_id      NUMBER := 0;
        v_project_status_actif VARCHAR2 (30):= 1000; --ACTIF
        -- Variables needed for API standard parameters
        v_api_version_number   NUMBER                                 := 1.0;
        v_commit               VARCHAR2 (1)                           := 'F';
        v_return_status        VARCHAR2 (1);
        v_init_msg_list        VARCHAR2 (1)                           := 'T';
        v_msg_count            NUMBER;
        v_msg_index_out        NUMBER;
        v_msg_data             VARCHAR2 (30000);
        v_data                 VARCHAR2 (30000);
        v_workflow_started     VARCHAR2 (1)                           := 'Y';
        v_pm_product_code      VARCHAR2 (10);
        -- Predefined Composit data types
        v_project_in           pa_project_pub.project_in_rec_type;
        v_project_out          pa_project_pub.project_out_rec_type;
        v_key_members          pa_project_pub.project_role_tbl_type;
        v_class_categories     pa_project_pub.class_category_tbl_type;
        v_tasks_in_rec         pa_project_pub.task_in_rec_type;
        v_tasks_in             pa_project_pub.task_in_tbl_type;
        v_tasks_out_rec        pa_project_pub.task_out_rec_type;
        v_tasks_out            pa_project_pub.task_out_tbl_type;
        v_cust_rec             pa_project_pub.customer_in_rec_type;
        v_cust_tbl             pa_project_pub.customer_tbl_type;
        v_person_id            NUMBER;
        v_project_role_type    VARCHAR2 (20);

        v_ind                  NUMBER;
        v_custid               NUMBER;
        v_personid             NUMBER;

        api_error              EXCEPTION;
        v_project_template_id            NUMBER;
        v_cost_ind_rate_sch_id  NUMBER;
        v_code_affaire        pa_class_codes.class_code%type;
        v_code_activite        pa_class_codes.class_code%type;
        v_code_filiere         pa_class_codes.class_code%type;
        v_code_destination     pa_class_codes.class_code%type;
        v_rowid                 ROWID;
        v_cost_dist_override_id NUMBER;
        v_project_parent          pa_projects_all.segment1%TYPE;
        v_created_from_project_id NUMBER;
        v_project pa_projects_all%rowtype;
        v_type_action   VARCHAR2 (15);
        v_task_validate NUMBER ;

        ---- Curosr to get Project Task Details ------------------------
        CURSOR taches (p_project_code VARCHAR2)
        IS
            SELECT *
            FROM DKA_EAI_TACHE
            WHERE OA_STATUS != 'PROCESSED' AND project_code = p_project_code
            AND     id IS NULL
            ORDER BY task_code,creation_date for update; --YWA artf2131655 --task_name;

        /*CURSOR taches_childs (p_project_code VARCHAR2)
        IS
            SELECT *
            FROM DKA_EAI_TACHE
            WHERE OA_STATUS != 'PROCESSED' AND project_code = p_project_code
            AND PROJECT_PARENT IS NOT NULL
            ORDER BY task_name;*/

    BEGIN
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début create_project');
        -- PRODUCT RELATED DATA
        BEGIN
            SELECT flv.LOOKUP_CODE
            INTO   v_pm_product_code
            FROM   fnd_lookup_values_vl flv
            WHERE  TRUNC(SYSDATE) BETWEEN TRUNC(NVL(flv.start_date_active, SYSDATE))
                 AND     TRUNC(NVL(flv.end_date_active, SYSDATE))
            AND    flv.enabled_flag = 'Y'
            AND    flv.lookup_type = 'PM_PRODUCT_CODE'
            AND    flv.meaning = 'Internal Controls Manager'
            AND    flv.view_application_id = 275;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                    Fnd_File.put_line (Fnd_File.LOG,'code produit <Internal Controls Manager> introuvanle ');
                    p_retcode := 1;
                    p_errbuf := 'Erreur lors de la recuperation du code produit <Internal Controls Manager>';
                    RETURN;
            WHEN OTHERS
                THEN
                    Fnd_File.put_line (Fnd_File.LOG,'Erreur lors de la récupération du code produit <Internal Controls Manager>');
                    p_retcode := 1;
                    p_errbuf := 'Erreur lors de la récupération du code produit <Internal Controls Manager>';
                    RETURN;
        END;

          -------------- Query To Get Organization Id ---------------------
        BEGIN
            SELECT organization_id
            INTO g_org_id
            FROM hr_operating_units
            WHERE UPPER (NAME) = UPPER (TRIM (p_project.operating_unit));
        EXCEPTION
            WHEN OTHERS
                THEN
                    Fnd_File.put_line (Fnd_File.LOG, 'Invalid Operating Unit');
                    p_retcode := 1;
                    p_errbuf := 'Invalid Operating Unit';
                    RETURN;
        END;

          --mo_global.set_policy_context ('S', g_org_id);

        init_environement(v_errbuf, v_retcode);

        IF v_retcode != 0 THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RETURN;
        END IF;


          -------------- Query To Get Project Template ID -----------------
        BEGIN
            SELECT project_id,cost_ind_rate_sch_id
            INTO v_project_template_id, v_cost_ind_rate_sch_id
            FROM pa_projects_all
            WHERE org_id = g_org_id
            AND UPPER (segment1) = UPPER (TRIM (p_project.project_template))--UPPER (TRIM (p_project.operating_unit||'.'||p_project.project_template))
            AND template_flag='Y';
        EXCEPTION
         WHEN OTHERS
         THEN
            Fnd_File.put_line (Fnd_File.LOG, ' Invalid Project Template');
            p_retcode := 1;
            p_errbuf := 'Invalid Project Template';
            RETURN;
        END;


        -- PRODUCT DATA (PROJECT_IN_REC_TYPE)
        v_project_in.created_from_project_id    := v_project_template_id;-- Project id from template
        v_project_in.project_name               := SUBSTR(p_project.project_code||'-'||p_project.libelle,1,30);--Project Name ;
        v_project_in.pm_project_reference       := p_project.project_code;--'Project Reference';
        v_project_in.description                := SUBSTR(p_project.libelle,1,250);--ywa artf2076737 -- RBE artf2089025
        --v_project_in.cost_ind_rate_sch_id     := v_cost_ind_rate_sch_id;
        v_project_in.project_status_code        := v_project_status_actif;--ACTIF
         v_project_in.long_name                  := SUBSTR(p_project.project_code||'-'||p_project.libelle,1,240); --v_project_in.description; --artf2064984 -- RBE artf2089025

        --CUF
        --v_project_in.attribute_category := 'Global Data Elements';
        --v_project_in.attribute1        := p_project.work_estimated_amount;
        --v_project_in.attribute2        := p_project.work_estimated_end_date;
        --l_project_in.org_id := g_org_id;--  from template

        BEGIN

            SELECT organization_id
            INTO  v_project_in.carrying_out_organization_id
            FROM hr_all_organization_units
            WHERE name = p_project.organization_name
            AND business_group_id=v_business_group_id;
        EXCEPTION
         WHEN OTHERS
         THEN
            Fnd_File.put_line (Fnd_File.LOG, 'Centre de finance introuvable');
            p_retcode := 1;
            p_errbuf := 'Centre de finance introuvable';
            RETURN;
        END;



        IF p_project.project_start_date IS NULL THEN
            p_retcode := 1;
            p_errbuf := 'La date de début du projet est obligatoire ';
            RETURN;
        END IF;

        IF p_project.organization_start_date IS NULL THEN
            p_retcode := 1;
            p_errbuf := 'La date de début de validité de l''organisation n''est pas fournie';
            RETURN;
        ELSIF p_project.project_start_date != p_project.organization_start_date THEN
            p_retcode := 1;
            p_errbuf := 'La date de début de validité de l''organisation est différente de la date de début de projet';
            RETURN;
        END IF; --YWA artf2131656  --!rg8.2.6

        v_project_in.start_date             := p_project.project_start_date;-- can override default from template
        v_project_in.completion_date        := p_project.project_completion_date;-- can override default from template
        --l_project_in.actual_start_date    := p_project.actual_start_date;
        --l_project_in.actual_finish_date   := p_project.actual_finish_date;
       -- v_project_in.projet_type          := p_project.projet_type;
        v_project_in.process_mode           := 'ONLINE';

        --CUF
        v_project_in.attribute_category := 'Global Data Elements';
        v_project_in.attribute8        := TO_CHAR(p_project.project_closing_date,cv_std_date_mask);

        SAVEPOINT befor_create_projet;

        IF p_project.code_affaire IS NOT NULL THEN

            IF p_project.code_activite IS NULL THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Il n''a pas de code activité parent');
                p_retcode := 1;
                p_errbuf := 'Il n''a pas de code activité parent';
                RETURN;
            /*ELSE

                BEGIN
                    SELECT class_code
                    INTO v_code_activite
                    FROM pa_class_codes
                    WHERE  class_category = 'ACTIVITE'
                    AND class_code = p_project.code_activite;
                EXCEPTION
                  WHEN OTHERS THEN
                    Fnd_File.put_line (Fnd_File.LOG, 'Le code class ACTIVITE est erroné');
                    p_retcode := 1;
                    p_errbuf := 'Le code class ACTIVITE est erroné';
                    RETURN;
                END;*/

            END IF ;

            BEGIN
                SELECT class_code
                INTO v_code_affaire
                FROM pa_class_codes
                WHERE  class_category = 'AFFAIRE'
                AND class_code = p_project.code_affaire;
            EXCEPTION
              WHEN OTHERS THEN
                /*pa_project_pub.load_class_category( p_api_version_number    => v_api_version_number
                                                ,p_return_status        => v_return_status
                                                ,p_class_category       => 'AFFAIRE'
                                                ,p_class_code           => p_project.code_affaire );

                IF v_return_status != 'S' THEN
                    Fnd_File.put_line (Fnd_File.LOG, 'Le code class AFFAIRE n''a pas pu etre crée');
                    p_retcode := 1;
                    p_errbuf := 'Le code class AFFAIRE n''a pas pu etre crée';
                    RETURN;
                END IF;*/
                    insert_pa_class_codes(p_project.code_affaire,p_project.code_activite,p_errbuf,p_retcode);
                    IF p_retcode != 0 THEN
                        RETURN;
                    END IF ;
            END;

            v_class_categories(1).class_category := 'AFFAIRE'; --value from template
            v_class_categories(1).class_code := p_project.code_affaire;
        ELSIF p_project.project_template  = p_project.operating_unit||'.ORGANIQUE' THEN
            BEGIN
                SELECT class_code,class_category
                INTO v_class_categories(1).class_code,
                    v_class_categories(1).class_category
                FROM pa_project_classes
                WHERE project_id=v_project_template_id
                AND class_category= 'AFFAIRE'
                AND object_type = 'PA_PROJECTS'
                AND object_id = v_project_template_id;
            EXCEPTION
                  WHEN OTHERS THEN
                    Fnd_File.put_line (Fnd_File.LOG, 'Erreur lors de la récupération du code affaire pour le projet ORGANIQUE à partir du template');
                    p_retcode := 1;
                    p_errbuf := 'Erreur lors de la récupération du code affaire pour le projet ORGANIQUE à partir du template';
                    RETURN;
            END;

        ELSIF  upper(p_project.project_type) = 'INVESTISSEMENT'  THEN  --SFD 2.6V

            BEGIN
               SELECT DISTINCT ppa.created_from_project_id,ppa.segment1
               INTO v_created_from_project_id,v_project_parent
               FROM
                dka_eai_tache det,
                pa_tasks pt,
                pa_projects_all ppa
               WHERE project_code= p_project.project_code
                AND pt.TASK_NUMBER = det.subproject_relationship
                AND pt.project_id = ppa.project_id;
            EXCEPTION
              WHEN OTHERS THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Erreur lors de la récupération projet parent');
                p_retcode := 1;
                p_errbuf := 'Erreur lors de la récupération projet parent : '||SQLERRM;
                RETURN;
            END;

            BEGIN
                SELECT ppc.class_code,ppc.class_category
                INTO v_class_categories(1).class_code,
                    v_class_categories(1).class_category
                FROM pa_project_classes ppc,pa_projects_all ppa
                WHERE ppc.project_id= ppa.project_id
                AND ppa.project_id = v_created_from_project_id
                AND ppa.segment1 LIKE '%ORGANIQUE%'
                AND ppc.class_category= 'AFFAIRE'
                AND ppc.object_type = 'PA_PROJECTS'
                AND ppc.object_id = ppa.project_id;
            EXCEPTION
              WHEN OTHERS THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Erreur lors de la récupération du code affaire à partir du projet parent (uniquement pour les parents organiques) : '||SQLERRM);
                p_retcode := 1;
                p_errbuf := 'Erreur lors de la récupération du code affaire à partir du projet parent (uniquement pour les parents organiques) : '||SQLERRM;
                RETURN;
            END;

        ELSE
            Fnd_File.put_line (Fnd_File.LOG, 'Le code class AFFAIRE est nul');
            p_retcode := 1;
            p_errbuf := 'Le code class AFFAIRE est nul';
            RETURN;

        END IF ;

        IF p_project.code_filiere IS NOT NULL THEN
            BEGIN
                SELECT class_code
                INTO v_code_filiere
                FROM pa_class_codes
                WHERE  class_category = 'FILIERE'
                AND class_code = p_project.code_filiere;
            EXCEPTION
              WHEN OTHERS THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Le code class FILIERE est erroné');
                p_retcode := 1;
                p_errbuf := 'Le code class FILIERE est erroné';
                RETURN;
            END;
            v_class_categories(2).class_category := 'FILIERE';
            v_class_categories(2).class_code := p_project.code_filiere;
        END IF ;
        IF p_project.code_destination IS NOT NULL THEN
            BEGIN
                SELECT class_code
                INTO v_code_destination
                FROM pa_class_codes
                WHERE  class_category = 'DESTINATION'
                AND class_code = p_project.code_destination;
            EXCEPTION
              WHEN OTHERS THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Le code class DESTINATION est erroné');
                p_retcode := 1;
                p_errbuf := 'Le code class DESTINATION est erroné';
                RETURN;
            END;
            v_class_categories(3).class_category := 'DESTINATION';
            v_class_categories(3).class_code := p_project.code_destination;
        END IF ;

        --Fnd_Msg_Pub.initialize;
        --INIT_CREATE_PROJECT
        pa_project_pub.init_project;
        --CREATE_PROJECT
        pa_project_pub.create_project (v_api_version_number,
                                        p_commit                => v_commit,
                                        p_init_msg_list         => 'T',
                                        p_msg_count             => v_msg_count,
                                        p_msg_data              => v_msg_data,
                                        p_return_status         => v_return_status,
                                        p_workflow_started      => v_workflow_started,
                                        p_pm_product_code       => v_pm_product_code,
                                        p_project_in            => v_project_in,
                                        p_project_out           => v_project_out,
                                        p_key_members           => v_key_members,
                                        p_class_categories      => v_class_categories,
                                        p_tasks_in              => v_tasks_in,
                                        p_tasks_out             => v_tasks_out,
                                        p_customers_in          => v_cust_tbl
                                        );

        -- Check for errors
        IF v_return_status != 'S' THEN
            p_retcode := 1;
            RAISE api_error;
        END IF;

        IF v_return_status ='S' THEN
            Fnd_File.put_line (Fnd_File.LOG,'Project Id: ' || v_project_out.pa_project_id);
            Fnd_File.put_line (Fnd_File.LOG,'Project Number: ' || v_project_out.pa_project_number);
            v_task_validate := 0;
            FOR t IN taches (p_project.project_code) LOOP

                SELECT *
                INTO v_project
                FROM pa_projects_all
                WHERE project_id=v_project_out.pa_project_id;

                tache_action(v_project,t,v_type_action,v_tasks_in_rec,v_errbuf,v_retcode);

                IF v_retcode !=0 THEN
                    ROLLBACK TO SAVEPOINT befor_create_projet;
                    UPDATE dka_eai_tache
                    SET    oa_status ='REJECT',
                           oa_rejection_reason = v_errbuf,
                           oa_request_id =g_request_id,
                           --oa_action_type = v_type_action,
                           last_updated_by = 	g_user_id,
                           last_update_date = sysdate
                    WHERE  CURRENT OF taches;
                    g_task_reject :=g_task_reject+1;-- ywa artf2140013
                    Fnd_File.put_line (Fnd_File.LOG, 'ERREUR sur la tache '||t.task_code);
                    p_retcode := 1;
                    p_errbuf := 'ERREUR sur la tache '||t.task_code ;
                    RETURN;

                ELSE

                    UPDATE dka_eai_tache
                    SET    oa_status ='PROCESSED',
                           oa_rejection_reason = NULL,
                           oa_request_id =g_request_id,
                           --oa_action_type = v_type_action,
                           id = v_tasks_in_rec.pa_task_id,
                           last_updated_by = 	g_user_id,
                           last_update_date = sysdate
                    WHERE  CURRENT OF taches;

                    v_task_validate := v_task_validate+1;-- ywa artf2140013
                    --Fnd_File.put_line (Fnd_File.LOG, 'la tache create_project '||g_task_validate);
                END IF;

            END LOOP;
            g_task_validate:=v_task_validate;-- ywa artf2140013

            BEGIN
                pa_cost_dist_overrides_pkg.Insert_Row( x_rowid                  =>     v_rowid,
                                                   x_cost_dist_override_id      =>     v_cost_dist_override_id,
                                                   x_project_id                 =>     v_project_out.pa_project_id,
                                                   x_override_to_org_id         =>     v_project_in.carrying_out_organization_id,
                                                   x_start_date_active          =>     p_project.project_start_date,--p_project.organization_start_date,--TRUNC(nvl(p_project.organization_start_date,SYSDATE),'mm'),
                                                   x_last_update_date           =>     SYSDATE,
                                                   x_last_updated_by            =>     g_user_id,
                                                   x_creation_date              =>     SYSDATE,
                                                   x_created_by                 =>     g_user_id,
                                                   x_last_update_login          =>     g_login_id,
                                                   x_person_id                  =>     NULL,
                                                   x_expenditure_category       =>     NULL,
                                                   x_override_from_org_id       =>     v_project_in.carrying_out_organization_id,
                                                   x_end_date_active            =>     NULL
                                                );
            EXCEPTION
                WHEN OTHERS THEN
                    Fnd_File.put_line (Fnd_File.LOG, 'ERREUR lors de l''insertion de la nouvelle oragnisation qui permettra de gérer les mouvements sur projet à date d''effet');
                    p_retcode := 1;
                    p_errbuf := 'ERREUR lors de l''insertion de la nouvelle oragnisation qui permettra de gérer les mouvements sur projet à date d''effet '|| SQLERRM;
                    ROLLBACK TO SAVEPOINT befor_create_projet;
                    RETURN;
            END;

            IF upper(p_project.project_type) = 'FACTURABLE' THEN
                --ADD BUDGET
                Fnd_File.put_line (Fnd_File.LOG,'ADD BUDGET');
                add_budget (v_project_template_id,v_project_out.pa_project_id,v_project_out.pa_project_number,v_pm_product_code,v_errbuf ,v_retcode);
                IF v_retcode != 0 THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    ROLLBACK TO SAVEPOINT befor_create_projet;
                    RETURN;
                END IF;
            END IF;
            /*--mouvements de controles
            Fnd_File.put_line (Fnd_File.LOG,'mouvements de controles');
            controle_mouvements  (v_project_template_id,v_project_out.pa_project_id,null,v_errbuf,v_retcode);
            IF v_retcode != 0 THEN
                p_errbuf  := v_errbuf;
                p_retcode := v_retcode;
                ROLLBACK TO SAVEPOINT befor_create_projet;
                RETURN;
            END IF;

            add_immo_gy  (v_project_out.pa_project_id,v_project_out.pa_project_number,null,v_pm_product_code,v_errbuf,v_retcode);
            IF v_retcode != 0 THEN
                p_errbuf  := v_errbuf;
                p_retcode := v_retcode;
                ROLLBACK TO SAVEPOINT befor_create_projet;
                RETURN;
            END IF;*/--YWA
            -- ajout dans le jeu de valeurs de la CCF DAOPCCF_PROJETFI
            Fnd_File.put_line (Fnd_File.LOG,'ajout dans le jeu de valeurs de la CCF DAOPCCF_PROJETFI');
            create_update_flex_value('DAOPCCF_PROJETFI',v_project_in.pm_project_reference ,NULL,p_project.libelle ,p_project.project_start_date,p_project.project_completion_date,v_errbuf,v_retcode);
            IF v_retcode != 0 THEN
                p_errbuf  := v_errbuf;
                p_retcode := v_retcode;
                ROLLBACK TO SAVEPOINT befor_create_projet;
                RETURN;

            END IF;

            --VALIDATE
            p_retcode := 0;
            p_errbuf := v_project_out.pa_project_id;

        END IF;


    EXCEPTION
       WHEN api_error
       THEN


          IF v_msg_count >= 1
          THEN

             FOR i IN 1 .. v_msg_count

             LOOP

                pa_interface_utils_pub.get_messages
                                              (--p_msg_data           => v_msg_data,
                                               p_encoded            => 'F',
                                               p_data               => v_data,
                                               --p_msg_count          => v_msg_count,
                                               p_msg_index          => i,
                                               p_msg_index_out      => v_msg_index_out
                                              );
                Fnd_File.put_line (Fnd_File.LOG,'error message api_error: ' || v_data);
                p_errbuf := SUBSTR(p_errbuf || v_data,0,240);
             END LOOP;
          END IF;
       WHEN OTHERS
       THEN
          IF v_msg_count >= 1 THEN
             FOR i IN 1 .. v_msg_count
             LOOP
                pa_interface_utils_pub.get_messages
                                              (--p_msg_count          => v_msg_count,
                                               p_encoded            => 'F',
                                               --p_msg_data           => v_msg_data,
                                               p_data               => v_data,
                                               p_msg_index          => i,
                                               p_msg_index_out      => v_msg_index_out
                                              );
                Fnd_File.put_line (Fnd_File.LOG,'error message OTHERS: ' || v_data);
                p_errbuf := SUBSTR(p_errbuf || v_data,0,240);

             END LOOP;
          ELSE
            p_errbuf := sqlerrm;
            p_retcode := 2;

          END IF;

        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin create_project');

    END create_project;

    /*=====================================================================================*/
    /* PROCEDURE NAME : archive
    /*
    /* DESCRIPTION
    /*  Procédure lignes de projets traitées depuis plus de 2 mois seront archivées
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/

    PROCEDURE archive( p_errbuf         IN OUT VARCHAR2,
                    p_retcode         IN  OUT NUMBER
                    )
    IS

    BEGIN
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début archive');
        INSERT INTO dka_eai_organisation_hist(id
                                        ,centre_finance
                                        ,description
                                        ,start_date
                                        ,end_date
                                        ,org_parent
                                        ,oa_status
                                        ,oa_rejection_reason
                                        ,oa_request_id
                                        ,last_updated_by
                                        ,last_update_date
                                        ,creation_date
                                        ,histo_date
                                       )
        SELECT   id
                ,centre_finance
                ,description
                ,start_date
                ,end_date
                ,org_parent
                ,oa_status
                ,oa_rejection_reason
                ,oa_request_id
                ,last_updated_by
                ,last_update_date
                ,creation_date
                ,SYSDATE
        FROM dka_eai_organisation
        WHERE  ADD_MONTHS(last_update_date,2) <= sysdate;

        DELETE dka_eai_organisation WHERE ADD_MONTHS(last_update_date,2) <= sysdate;

        INSERT INTO dka_eai_tache_hist(id
                                ,project_code
                                ,task_code
                                ,task_name
                                ,description
                                ,task_start_date
                                ,task_estimated_end_date
                                ,task_closing_date
                                ,task_completion_date
                                ,task_attribute
                                ,billed_task
                                ,asset_category
                                ,work_estimated_amount
                                ,subproject_relationship
                                ,oa_status
                                ,oa_rejection_reason
                                ,oa_request_id
                                ,last_updated_by
                                ,last_update_date
                                ,creation_date
                                ,histo_date
                                )
        SELECT id
                ,project_code
                ,task_code
                ,task_name
                ,description
                ,task_start_date
                ,task_estimated_end_date
                ,task_closing_date
                ,task_completion_date
                ,task_attribute
                ,billed_task
                ,asset_category
                ,work_estimated_amount
                ,subproject_relationship
                ,oa_status
                ,oa_rejection_reason
                ,oa_request_id
                ,last_updated_by
                ,last_update_date
                ,creation_date
                ,SYSDATE
        FROM dka_eai_tache
        WHERE project_code IN (SELECT project_code FROM dka_eai_projet
        WHERE  ADD_MONTHS(last_update_date,2) <= sysdate);

        DELETE dka_eai_tache WHERE project_code IN (SELECT project_code FROM dka_eai_projet
        WHERE  ADD_MONTHS(last_update_date,2) <= sysdate);

        INSERT INTO dka_eai_projet_hist
        (id
        ,operating_unit
        ,project_code
        ,libelle
        ,project_template
        ,project_start_date
        ,project_completion_date
        ,project_type
        ,organization_name
        ,organization_start_date
        ,code_affaire
        ,code_activite
        ,code_filiere
        ,code_destination
        ,oa_status
        ,oa_action_type
        ,oa_request_id
        ,last_updated_by
        ,last_update_date
        ,creation_date
        ,histo_date
        )
        SELECT  id
                ,operating_unit
                ,project_code
                ,libelle
                ,project_template
                ,project_start_date
                ,project_completion_date
                ,project_type
                ,organization_name
                ,organization_start_date
                ,code_affaire
                ,code_activite
                ,code_filiere
                ,code_destination
                ,oa_status
                ,oa_action_type
                ,oa_request_id
                ,last_updated_by
                ,last_update_date
                ,creation_date
                ,SYSDATE
        FROM dka_eai_projet
        WHERE  ADD_MONTHS(last_update_date,2) <= sysdate;

        DELETE dka_eai_projet WHERE ADD_MONTHS(last_update_date,2) <= sysdate;


        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin archive');
    EXCEPTION
        WHEN OTHERS THEN
            p_errbuf  := 'EXCEPTION au momment de l''archivage '||sqlerrm;
            p_retcode := 2;
            Fnd_File.put_line (Fnd_File.LOG,'EXCEPTION au momment de l''archivage '||sqlerrm);

    END archive;

     /*
    *************************************************************************
    * PROCEDURE NAME : bilan_projet
    *
    * DESCRIPTION
    *  Procédure de génération du bilan_projet du traitement des projets
    *
    * PARAMETERS
    * ==========
    * NAME                 DESCRIPTION
    .* -------------------- -------------------------------------------------
    * p_errbuf            Retour de message éventuel
    * p_retcode           Statut du traitement en sortie
    ************************************************************************
    */
    PROCEDURE bilan_projet(p_Errbuf            OUT VARCHAR2,
                         p_retcode           OUT NUMBER
                         )
    IS

    BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut bilan_projet');

        --------------------
        -- Initialisation --
        --------------------

        p_Errbuf  := NULL;
        p_retcode := 0;


        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'-----------------------------------------------------BILAN-------------------------------------------------------------------------');
        Fnd_File.put_line (Fnd_File.output,'-----------------------------------------------------------------------------------------------------------------------------------');
        Fnd_File.put_line (Fnd_File.output,'   . Nombre de projets créés et modifiés correctement    : ' || TO_CHAR(g_validate_proj)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'   . Nombre de projets avec des erreurs                  : ' || TO_CHAR(g_validate_proj_err)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'   . Nombre de taches créées et modifiées correctement   : ' || TO_CHAR(g_task_validate)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'   . Nombre de taches en rejet                           : ' || TO_CHAR(g_task_reject)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'-----------------------------------------------------------------------------------------------------------------------------------');


        Fnd_File.put_line (Fnd_File.LOG,CHR(10));
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin bilan_projet');


    EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'bilan_projet : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure bilan_projet : EXCEPTION OTHERS ');
    END bilan_projet;

    /*
    *************************************************************************
    * PROCEDURE NAME : Create_Subproject_Association
    *
    * DESCRIPTION
    *  Gestion des projets parents sur tâche
    *
    * PARAMETERS
    * ==========
    * NAME                 DESCRIPTION
    .* -------------------- ---------------------------------------------------
    * p_tache             TACHE
    * p_errbuf            Retour de message éventuel
    * p_retcode           Statut du traitement en sortie
    ************************************************************************
    */
    /*PROCEDURE create_subproject_association(p_tache  dka_eai_tache%rowtype,p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS


        v_task_id NUMBER;
        v_dest_project_id  NUMBER;
        v_src_project_id  NUMBER;

        v varchar(30);
        ----API standard parameters---
        v_return_status VARCHAR2(1);
        v_msg_count     NUMBER;
        v_msg_data      VARCHAR2(250);
        v_msg_index_out NUMBER;




    BEGIN
        Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Create_Subproject_Association');



        Fnd_File.put_line(Fnd_File.LOG, '**Task : ' || p_tache.TASK_NAME);

        -- Récupération du task_id
        --->>
        --->>
        BEGIN
        SELECT task_id
              INTO v_task_id
              FROM pa_tasks
         WHERE task_id = p_tache.id;

        EXCEPTION
            WHEN OTHERS THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Erreur de récuperation du task_id');
                p_retcode := 1;
                p_errbuf := 'Erreur de récuperation du task_id';
                RETURN;
        END;


        -- Récupération du project_dest_id

        BEGIN
            SELECT project_id
            INTO v_dest_project_id
            FROM pa_projects_all
            WHERE segment1 = p_tache.subproject_relationship;
        EXCEPTION
          WHEN OTHERS THEN
            Fnd_File.put_line (Fnd_File.LOG, 'Erreur de récuperation du dest_project_id');
            p_retcode := 1;
            p_errbuf := 'Erreur de récuperation du dest_project_id';
            RETURN;
        END;

        -- Récupération du project_src_id
        BEGIN
            SELECT project_id
            INTO v_src_project_id
            FROM pa_projects_all
            WHERE segment1 = p_tache.project_code;

        EXCEPTION
          WHEN OTHERS THEN
            Fnd_File.put_line (Fnd_File.LOG, 'Erreur de récuperation du v_src_project_id');
            p_retcode := 1;
            p_errbuf := 'Erreur de récuperation du v_src_project_id';
            RETURN;
        END;


        fnd_file.put_line(fnd_file.LOG, ' v_task_id ->'         || v_task_id ||
                                        ' v_dest_project_id ->' || v_dest_project_id ||
                                        ' v_src_project_id ->'  || v_src_project_id);


        IF PA_PROJECT_STRUCTURE_UTILS.check_program_flag_enable(v_src_project_id) = 'N' THEN


            PA_PROJECT_STRUCTURE_PUB1.ENABLE_PROGRAM_FLAG(p_project_id         => v_src_project_id
                                                          , x_return_status    => v_return_status
                                                          , x_msg_count        => v_msg_count
                                                          , x_msg_data         => v_msg_data);

            IF v_return_status !='S' THEN
                FOR i IN 1..v_msg_count LOOP

                    fnd_msg_pub.get (p_msg_index     => i
                                            ,p_encoded       => 'F'
                                            ,p_data          => v_msg_data
                                            ,p_msg_index_out => v_msg_index_out
                                            );

                    p_errbuf := p_errbuf || CHR(10) || v_msg_data;


                END LOOP;
                Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
                p_retcode := 1;
                RETURN;
            END IF;
        END IF;

        /*v := PA_RELATIONSHIP_UTILS.CREATE_SUB_PROJ_ASSO_OK (v_task_id,v_dest_project_id);
        Fnd_File.put_line (Fnd_File.LOG, 'PA_RELATIONSHIP_UTILS.CREATE_SUB_PROJ_ASSO_OK '|| v);*/


       /* pa_proj_structure_pub.create_relationship(p_api_version       => 1.0
                                                ,p_init_msg_list     => 'T'
                                                ,p_commit            => 'F'
                                                ,p_validate_only     => 'F'
                                                ,p_debug_mode        => 'N'
                                                ,p_project_id        => v_dest_project_id
                                                ,p_task_id           => v_task_id
                                                ,x_return_status     => v_return_status
                                                ,x_msg_count         => v_msg_count
                                                ,x_msg_data          => v_msg_data);

        IF v_return_status ='S' THEN
            p_errbuf := NULL;
            p_retcode :=0;
        ELSE
            FOR i IN 1..v_msg_count LOOP

                fnd_msg_pub.get (p_msg_index     => i
                                        ,p_encoded       => 'F'
                                        ,p_data          => v_msg_data
                                        ,p_msg_index_out => v_msg_index_out
                                        );

                p_errbuf := p_errbuf || CHR(10) || v_msg_data;


            END LOOP;

            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            p_retcode := 1;
            RETURN;
        END IF;


        Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'fin Create_Subproject_Association');



    EXCEPTION
        WHEN OTHERS THEN
        p_retcode :=2;
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Create_Subproject_Association : EXCEPTION OTHERS -> '|| SQLERRM);

    END Create_Subproject_Association;*/

    ---------------------------------------------------------------------------------------------------------------
--  Nom           : run_PAPMPRPB
--  Description   : lancement procédure standard du traitement standard PAPMPRPB
--
--  PARAMETRES    :pv_errbuf       Entrée/Sortie    message d'erreur
--                 pn_retcode      Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    PROCEDURE run_PAPMPRPB (
        pv_errbuf              IN OUT   VARCHAR2,
        pn_retcode             OUT      NUMBER
    )
    IS
        vn_request_id  NUMBER;
        vv_phase       VARCHAR2 (10);
        vv_status		 	 VARCHAR2 (10);
        vv_dev_phase   VARCHAR2 (10);
        vv_dev_status  VARCHAR2 (10);

    BEGIN
        Dka_Tools_Pkg.put_debug_message ('>run_PAPMPRPB ');
        pv_errbuf               := NULL;
        pn_retcode              := 0;

        vn_request_id           :=
                Fnd_Request.submit_request (
                    application  => 'PA', --APPL
                    program      => 'PAPMPRPB', --PROG
                    description  => NULL, --PROGRAM_NAME
                    start_time   => NULL, --START
                    sub_request  => FALSE, --SUB_REQUEST
                    argument1    => NULL,
                    argument2    => NULL,
                    argument3    => NULL
                );

        IF vn_request_id IS NULL
        THEN
            pn_retcode    := 1;
            Dka_Tools_Pkg.put_outdebug_message (
                '=> le traitement PRC : Traiter les mises à jour de structure de projet n''a pas pu être lancé'
            );
        ELSE
            pn_retcode    := 0;
            Dka_Tools_Pkg.put_outdebug_message ('=> traitement PRC : Traiter les mises à jour de structure de projet : '|| TO_CHAR (vn_request_id));
            COMMIT;
        END IF;

        IF NOT (Fnd_Concurrent.wait_for_request(vn_request_id,
	                                              15,
	                                              0,
	                                              vv_phase,
	                                              vv_status,
	                                              vv_dev_phase,
	                                              vv_dev_status,
	                                              pv_errbuf))
	      THEN
	        Dka_Tools_Pkg.put_outdebug_message('Traitement numéro ' || TO_CHAR(vn_request_id) || ' trop long ou tombé en erreur');

	      ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL')
	      THEN
	        Dka_Tools_Pkg.put_debug_message('Traitement numéro ' || TO_CHAR(vn_request_id) || ' correctement exécuté');
	      ELSE
	        Dka_Tools_Pkg.put_outdebug_message('Traitement numéro ' || TO_CHAR(vn_request_id) || ' trop long ou tombé en erreur');
	      END IF;  ----- >fin IF NOT -----

        Dka_Tools_Pkg.put_debug_message ('<run_PAPMPRPB ');

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode   := 2;
            pv_errbuf    := 'run_PAPMPRPB : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, pv_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure run_PAPMPRPB : EXCEPTION OTHERS ');
    END run_PAPMPRPB;


    /*=====================================================================================*/
    /* PROCEDURE NAME : projets
    /*
    /* DESCRIPTION
    /*  Procédure principale de l'interface de création
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/

    PROCEDURE projets(p_errbuf         IN OUT VARCHAR2,
                    p_retcode         IN  OUT NUMBER
                    )
    IS

        -- ========== VARIABLES ==========
        v_package                    VARCHAR2(30)  := 'DKA_ICODEPROJET_PKG';
        v_nom_traitement             VARCHAR2(200) := 'Import des projets et taches et affaires ';
        v_sqlerrm                    VARCHAR2(250) := NULL;
        v_nb_erreurs                 NUMBER :=0;

        v_procedure                  VARCHAR2(30)    := 'projets';
        v_message                    VARCHAR2(500);

        v_errbuf                     VARCHAR2(2500);
        v_retcode                    NUMBER;
        v_exeption                   EXCEPTION;
        v_exist_erreur              BOOLEAN;
        v_exist_warning             BOOLEAN;
        v_project_nb                   NUMBER;
        v_project              pa_projects_all%rowtype;
        v_type_action                VARCHAR2(10);
        v_task_id               NUMBER;
        v_tasks_in_rec          pa_project_pub.task_in_rec_type;

		v_project_org_name      VARCHAR2(10); -- OBE artf2676417
        ---- Cursoe To get Project Header Details ----------------------
        CURSOR project
        IS
          SELECT *
           FROM DKA_EAI_PROJET
           WHERE OA_STATUS != 'PROCESSED'
           AND     id IS NULL
           ORDER BY PROJECT_TYPE,CREATION_DATE,ORGANIZATION_START_DATE ;--YWA artf2121068 ,artf2131851 (ORGANISATION_START_DATE)

        CURSOR cur_taches IS
            SELECT *
                FROM DKA_EAI_TACHE
                WHERE OA_STATUS != 'PROCESSED' AND project_code not in (select project_code from  DKA_EAI_PROJET where id is null)
                AND     id IS NULL
                ORDER BY task_code,creation_date for update;



    BEGIN

        -- Début du Programme --
        -- ========Initialisation des variables d'anomalies========
        p_retcode   := 0;
        p_errbuf   := NULL;
        v_message   := 'Début procédure projets';
        --g_date_controle := p_date_controle;
        /*============================================================================================*/
        /*Initialisation des variables*/
        /*============================================================================================*/
        v_message   := 'Init';
        Fnd_File.put_line (Fnd_File.output, 'Initiation des variables');
        Init(v_errbuf, v_retcode);
        IF v_retcode = 2 THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RAISE v_exeption;
        END IF;

         -- Initialization des journaux --
        Fnd_File.put_line (Fnd_File.LOG,'=======================================================================');
        Fnd_File.put_line (Fnd_File.LOG,'Import projets et taches et affaires DKA_ICODEPROJET_PKG');
        Fnd_File.put_line (Fnd_File.LOG,'=======================================================================');
        Fnd_File.put_line (Fnd_File.LOG,'Date de lancement    : ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.LOG,'Numéro de traitement : ' || TO_CHAR(g_request_id));
         -- Initialization de la sortie --
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');
        Fnd_File.put_line (Fnd_File.output,'Import projets et taches et affaires DKA_ICODEPROJET_PKG');
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');
        Fnd_File.put_line (Fnd_File.output,'Date de lancement    : ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.output,'Numéro de traitement : ' || TO_CHAR(g_request_id));
        Fnd_File.put_line (Fnd_File.output,'Libelle du login OA '||FND_GLOBAL.USER_NAME);

        -- param user
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');
        Fnd_File.put_line (Fnd_File.output,'Paramètres utilisateur :');
        Fnd_File.put_line (Fnd_File.output,'Aucun');
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');


        -- Entete fichier log
        Fnd_File.put_line (Fnd_File.LOG,'==========================================================================');
        Fnd_File.put_line (Fnd_File.LOG,'Numéro de traitement '||TO_CHAR(g_request_id));
        Fnd_File.put_line (Fnd_File.LOG,'Libelle du login OA '||FND_GLOBAL.USER_NAME);
        Fnd_File.put_line (Fnd_File.LOG,'==========================================================================');

        Fnd_File.put_line (Fnd_File.output,'==========================================================================');
        Fnd_File.put_line (Fnd_File.output,v_nom_traitement);
        Fnd_File.put_line (Fnd_File.output,'==========================================================================');
         v_message   := 'marquer les ancienes ligne en rejet en double';
        --marquer les ancienes ligne en rejet en double
        UPDATE dka_eai_projet p1 set id = -1
        WHERE oa_status ='REJECT'
        AND   p1.id IS NULL
        AND EXISTS (SELECT 1
                    FROM dka_eai_projet p2
                    WHERE p2.project_code = p1.project_code
                    AND p2.oa_status = 'NEW');

        UPDATE dka_eai_tache t1 set id = -1
        WHERE t1.oa_status = 'REJECT'
        AND     t1.id IS NULL
        AND EXISTS (SELECT 1
                    FROM dka_eai_tache t2
                    WHERE t2.Project_Code = t1.Project_Code
                    AND t2.Task_Code = t1.Task_Code --YWA artf2121068
                    AND t2.Oa_Status = 'NEW');

        /*============================================================================================*/
        /*creation des projets et taches et affaire*/
        /*============================================================================================*/
        v_message   := 'creation des projets et taches et affaire';
        v_exist_erreur := FALSE;
        FOR p IN project LOOP

            v_errbuf := null;
            v_retcode := 0;
            v_project_nb :=0;

            SELECT COUNT(*)
            INTO v_project_nb
            FROM pa_projects_all
            WHERE segment1=p.project_code;

			--< OBE artf2676417
			BEGIN
			  SELECT b.name
              INTO v_project_org_name
              FROM pa_projects_all a, hr_operating_units b
              WHERE a.org_id = b.organization_id
			  AND a.segment1 = p.project_code
			  ;
			EXCEPTION
              WHEN OTHERS THEN
			     v_project_org_name := NULL;
            END;
			--> OBE artf2676417

            --création de projet ou en mise à jour de projet
            v_message   := 'création de projet ou en mise à jour de projet';
            IF v_project_nb!=0 THEN
                v_type_action:= 'M à J';
                Fnd_File.put_line (Fnd_File.LOG,'M à J');
			 	IF NVL(v_project_org_name,'XXXYYYY') != p.operating_unit THEN                              -- OBE artf2676417
				  v_retcode := 1;                                                                          -- OBE artf2676417
				  v_errbuf  := 'UO du projet dans l''interface est différente de l''UO du Projet dans OA'; -- OBE artf2676417
				ELSE                                                                                       -- OBE artf2676417
                  update_project (p,v_errbuf, v_retcode);
				END IF;                                                                                    -- OBE artf2676417
            ELSE
                v_type_action:= 'Création';
                Fnd_File.put_line (Fnd_File.LOG,'Création');
                create_project (p,v_errbuf, v_retcode);
            END IF;

            IF v_retcode = 1 THEN
                v_exist_erreur := TRUE;
                g_message_erreur_prj := v_errbuf;
                Fnd_File.put_line (Fnd_File.LOG,'Rejet du projet : '||p.project_code);
                validate_project(p.project_code,v_exist_erreur,NULL,v_type_action,p.creation_date,v_errbuf,v_retcode);
                IF v_retcode = 2 THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    v_message := 'Errerur lors du rejet du projet '||p.project_code;
                    RAISE v_exeption;
                END IF;

            ELSIF v_retcode =0 THEN

                Fnd_File.put_line (Fnd_File.LOG,v_type_action||' du projet '||p.project_code);
                validate_project(p.project_code,FALSE,to_number(v_errbuf),v_type_action,p.creation_date,v_errbuf,v_retcode);
                IF v_retcode = 2 THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    v_message := 'erreur lors de la validation de la '||v_type_action||' du projet '||p.project_code;
                    RAISE v_exeption;
                END IF;

            ELSE
                Fnd_File.put_line (Fnd_File.LOG,'Erreur lors de la '||v_type_action||' du projet '||v_errbuf);
                p_errbuf  := v_errbuf;
                p_retcode := 2;
                v_message := 'Erreur lors de la '||v_type_action||' du project';
                RAISE v_exeption;
            END IF;

        END LOOP;
         v_message   := 'FIN création de projet ou en mise à jour de projet';
        IF v_exist_erreur THEN
            p_errbuf  := 'Des projets ont été rejetés lors de la création';
            p_retcode := 1;
        END IF;
        ---YWA artf2131647 ---------------------
        FOR t IN cur_taches LOOP
            v_errbuf := null;
            v_retcode := 0;
            BEGIN
                SELECT *
                INTO v_project
                FROM pa_projects_all
                WHERE segment1=t.project_code;

                g_org_id := v_project.org_id;


                init_environement(v_errbuf, v_retcode);

                IF v_retcode != 0 THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    RETURN;
                END IF;

                v_errbuf := null;

                tache_action(v_project,t,v_type_action,v_tasks_in_rec,v_errbuf,v_retcode);
                IF v_retcode !=0 THEN
                    UPDATE dka_eai_tache
                    SET    oa_status ='REJECT',
                           oa_rejection_reason = v_errbuf,
                           oa_request_id =g_request_id,
                           --oa_action_type = v_type_action,
                           last_updated_by = 	g_user_id,
                           last_update_date = sysdate
                    WHERE  CURRENT OF cur_taches;
                    g_task_reject :=g_task_reject+1;
                ELSE
                    UPDATE dka_eai_tache
                    SET    oa_status ='PROCESSED',
                           oa_rejection_reason = NULL,
                           oa_request_id =g_request_id,
                           --oa_action_type = v_type_action,
                           id = v_tasks_in_rec.pa_task_id,
                           last_updated_by = 	g_user_id,
                           last_update_date = sysdate
                    WHERE  CURRENT OF cur_taches;
                    g_task_validate:=g_task_validate+1;
                END IF;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_retcode   := 1;
                    v_errbuf    := 'Le projet de la tache est introuvable: '||SQLERRM;
                    Fnd_File.put_line (Fnd_File.LOG, 'ERREUR : ' || p_errbuf);
            END;

        END LOOP;


        /*============================================================================================*/
        /*archive*/
        /*============================================================================================*/
        archive(v_errbuf,v_retcode);
         v_message   := 'archive';
        IF v_retcode = 2 THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RAISE v_exeption;
        END IF;

        ----------------------------------
        -- PHASE DE BILAN DU TRAITEMENT --
        ----------------------------------
         v_message   := 'bilan_projet';
        bilan_projet(v_errbuf,v_retcode);

        IF v_retcode = 2 THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RAISE v_exeption;
        END IF;

        --Commit du traitement
        COMMIT;


        ----------------------------------------------
        -- LANCEMENT DE LA MISE A JOUR DE STRUCTURE --
        ----------------------------------------------
        v_message   := 'run_PAPMPRPB';
        run_PAPMPRPB(v_errbuf,v_retcode);

        IF v_retcode = 2 THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RAISE v_exeption;
        END IF;

        Fnd_File.put_line (Fnd_File.output, p_errbuf);
        Fnd_File.put_line (Fnd_File.LOG, CHR(10)||p_errbuf||CHR(10));
        Fnd_File.put_line (Fnd_File.LOG,'==========================================================================');
        Fnd_File.put_line (Fnd_File.LOG, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.LOG,'==========================================================================');
        --Fnd_File.put_line (Fnd_File.output, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'FIN DE L''INTERFACE');

    EXCEPTION
        WHEN v_exeption THEN
            --p_retcode := 2;
            --p_errbuf  := 'Erreur EXCEPTION v_exception dans pkg.proc/fonc '||v_package||'.'||v_procedure;
            Fnd_File.put_line (Fnd_File.output,'-------------------- ERREUR --------------------');
            Fnd_File.put_line (Fnd_File.output,'Package   : '||v_package);
            Fnd_File.put_line (Fnd_File.output,'Procédure : '||v_procedure);
            Fnd_File.put_line (Fnd_File.output,'Exception : v_exeption');
            Fnd_File.put_line (Fnd_File.output,'Message   : '||v_message);
            Fnd_File.put_line (Fnd_File.LOG,'Cause     : '||p_errbuf);
            Fnd_File.put_line (Fnd_File.output,'------------------------------------------------');
            Fnd_File.put_line (Fnd_File.output, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_procedure||' : EXCEPTION v_exeption ');
            Fnd_File.put_line (Fnd_File.LOG, '==> Fin de la procédure '||v_procedure||' : EXCEPTION v_exeption ');
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            Fnd_File.put_line (Fnd_File.LOG,'Traitement '||v_nom_traitement||' terminé en erreur         ');
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            ROLLBACK;

       WHEN OTHERS THEN
            v_sqlerrm := SUBSTR(SQLERRM,1,200);
            p_retcode := 2;
            p_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc '||v_package||'.'||v_procedure;
            Fnd_File.put_line (Fnd_File.output,'-------------------- ERREUR --------------------');
            Fnd_File.put_line (Fnd_File.output,'Package   : '||v_package);
            Fnd_File.put_line (Fnd_File.output,'Procédure : '||v_procedure);
            Fnd_File.put_line (Fnd_File.output,'Exception : OTHERS');
            Fnd_File.put_line (Fnd_File.output,'Message   : '||v_message);
            Fnd_File.put_line (Fnd_File.LOG, CHR(10)||p_errbuf);
            Fnd_File.put_line (Fnd_File.output,'Cause     : '||v_sqlerrm);
            Fnd_File.put_line (Fnd_File.output,'------------------------------------------------');
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            Fnd_File.put_line (Fnd_File.LOG,'Traitement '||v_nom_traitement||' terminé en erreur         ');
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            ROLLBACK;

    END projets;

  -- RBE
  ----------------------------------------------------------------------------------------
  --  Nom           : Update_Project_Closed
  --  Description   : Procédure mettant à jour le status "fermé" du projet
  --
  --  PARAMETRES :
  --    pn_rec                  Entrée
  --    pv_errbuf               Sortie
  --    pn_retcode               Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal
  --                         2: erreur
  --                         ou le code erreur ORA
  ----------------------------------------------------------------------------------------
  PROCEDURE update_project_closed(pn_project_id IN NUMBER, pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER)
  IS
  BEGIN
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;


    ----- Mise à jour du status à "fermé"  -----
    UPDATE pa_projects_all ppa
       SET ppa.project_status_code = gv_project_status_code_closed,
           ppa.last_update_date    = SYSDATE,
           ppa.last_updated_by     = g_user_id,
           ppa.last_update_login   = g_login_id
     WHERE ppa.project_id = pn_project_id;

  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := ' Erreur UPDATE_PROJECT_CLOSED :' || SQLERRM;
  END update_project_closed;

  ----------------------------------------------------------------------------------------
  --  Nom           : Update_Project_EnClosed
  --  Description   : Procédure mettant à jour le status "Cloturé" du projet
  --
  --  PARAMETRES :
  --    pn_rec                  Entrée
  --    pv_errbuf               Sortie
  --    pn_retcode               Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal
  --                         2: erreur
  --                         ou le code erreur ORA
  ----------------------------------------------------------------------------------------
  PROCEDURE Update_Project_EnClosed(pn_project_id IN NUMBER, pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER)
  IS
  BEGIN
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;


    ----- Mise à jour du status à "Cloturé"  -----
    UPDATE pa_projects_all ppa
       SET ppa.project_status_code = gv_project_status_code_cloture,
           ppa.description         = substr(rtrim(ltrim(ppa.description)),1, 250 - length(' Clôturé le '|| to_char(to_date(ppa.attribute8,cv_std_date_mask),'DD/MM/YYYY'))) || ' Clôturé le '|| to_char(to_date(ppa.attribute8,cv_std_date_mask),'DD/MM/YYYY'),--YWA artf2076741
           ppa.last_update_date    = SYSDATE,
           ppa.last_updated_by     = g_user_id,
           ppa.last_update_login   = g_login_id
     WHERE ppa.project_id = pn_project_id;

  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := ' Erreur Update_Project_EnClosed :' || SQLERRM;
  END Update_Project_EnClosed;

  --------------------------------------------------------------------------------------
  --  Nom           : UPDATE_PROJECT_MONTH_STATUS
  --  Description   : Procédure de mise à jour mensuelle des projets
  --
  --  PARAMETRES :
  --    pv_errbuf                       Entrée/Sortie           retour de message eventuel
  --    pn_retcode                      Sortie                  status du traitement en sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
  --
  ----------------------------------------------------------------------------------------
  PROCEDURE update_project_month_status(pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER)
  IS

    -- A Cloturer
    CURSOR cur_projects_Enclosed IS
      SELECT ppa.project_id,
             ppa.segment1,
             ppa.project_type,
             ppa.attribute8
        FROM pa_projects_all ppa,
            per_security_profiles_v psp,
            per_security_organizations_v pso
       WHERE TO_DATE (ppa.attribute8, cv_std_date_mask) <= SYSDATE
     --AND   TO_DATE (ppa.attribute8, cv_std_date_mask) BETWEEN g_start_date_en_cours AND g_end_date_en_cours --YWA artf2077757
     --AND   ppa.project_status_code <> gv_project_status_code_cloture
       AND   TO_DATE (ppa.attribute8, cv_std_date_mask) <= (g_start_date_en_cours - 1)
       AND   ppa.project_status_code = gv_project_status_code_actif
       AND   pso.security_profile_id = psp.security_profile_id
       AND   psp.security_profile_id = FND_PROFILE.VALUE ('XLA_MO_SECURITY_PROFILE_LEVEL')
       AND   pso.organization_id        = ppa.org_id ;--YWA  --artf2076309 ;

    -- A Fermer
    CURSOR cur_projects_closed IS
      SELECT ppa.project_id,
             ppa.segment1,
             ppa.project_type,
             ppa.completion_date
        FROM pa_projects_all ppa,
             per_security_profiles_v psp,
             per_security_organizations_v pso
       WHERE ppa.completion_date <= SYSDATE
     --AND   ppa.completion_date BETWEEN g_start_date_en_cours AND g_end_date_en_cours --YWA artf2077757
     --AND   ppa.project_status_code <> gv_project_status_code_closed
       AND   ppa.completion_date <= (g_start_date_en_cours - 1)
       AND   ppa.project_status_code = gv_project_status_code_cloture
       AND   pso.security_profile_id = psp.security_profile_id
       AND   psp.security_profile_id = FND_PROFILE.VALUE ('XLA_MO_SECURITY_PROFILE_LEVEL')
       AND   pso.organization_id        = ppa.org_id ;--YWA  --artf2076309 ;

    pr_projects_enclosed cur_projects_Enclosed%ROWTYPE;
    pr_projects_closed cur_projects_closed%ROWTYPE;
    e_error_curseur_closed EXCEPTION;
    pn_count NUMBER(15);
  BEGIN
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
    pn_count   := 0;
    Fnd_File.put_line (Fnd_File.LOG,'*************   DÉBUT DE LA PROCÉDURE UPDATE_PROJECT_MONTH_STATUS  *********************');

    ----- Ouverture du curseur ------
    OPEN cur_projects_Enclosed;

    --dka_tools_pkg.put_debug_message ('Ouverture du curseur ');

    ----- Ouverture du curseur projets à Cloturer -----
    LOOP
      FETCH cur_projects_Enclosed
        INTO pr_projects_enclosed;
      EXIT WHEN cur_projects_Enclosed%NOTFOUND;

      --dka_tools_pkg.put_debug_message ('chargement du curseur  ');

      BEGIN
        -- lecture du curseur cur_projects_Enclosed
        SAVEPOINT dka_projects_closed;
        pv_errbuf  := NULL;
        pn_retcode := 0;
        Fnd_File.put_line (Fnd_File.LOG,'Appel de  update_project_Enclosed');
        dka_icodeprojet_pkg.update_project_Enclosed(pr_projects_enclosed.project_id,
                                                  pv_errbuf,
                                                  pn_retcode);

        IF pn_retcode != 0 THEN
          RAISE e_error_curseur_closed;
        END IF;

        -- Ecriture dans le fichier de sortie --
        dka_tools_pkg.put_outdebug_message('Le projet ' || pr_projects_enclosed.segment1 || ' a été clos le ' || to_char(to_date(pr_projects_enclosed.attribute8,cv_std_date_mask),'DD/MM/YYYY'));--YWA artf2076741
        --  dka_tools_pkg.put_debug_message ('le projet '|| pr_projects_enclosed.project_id || ' a été clôturé');
      EXCEPTION
        -- lecture du curseur cur_tbl_dit_reject
        WHEN e_error_curseur_closed THEN
          pn_count := pn_count + 1;
          dka_tools_pkg.put_outdebug_message('ERREUR : Le projet ' || pr_projects_enclosed.segment1 || 'n''a pas été clôturé le' ||
                                             to_char(to_date(pr_projects_enclosed.attribute8,cv_std_date_mask),'DD/MM/YYYY'));
          ROLLBACK TO SAVEPOINT dka_projects_closed;
        WHEN OTHERS THEN
          ROLLBACK TO SAVEPOINT dka_projects_closed;
          pn_count  := pn_count + 1;
          pv_errbuf := SQLERRM;
          dka_tools_pkg.put_outdebug_message('Autre erreur  : le projet ' || pr_projects_enclosed.segment1 || ' n''a pas été clôturé');
      END; -- lecture du curseur cur_projects_Enclosed

    END LOOP;

    ----- Validation -----
    COMMIT;
    Fnd_File.put_line (Fnd_File.LOG,'--------------------------------------------------------------------------------');
    Fnd_File.put_line (Fnd_File.LOG,'UPDATE_PROJECT_MONTH_STATUS - Nombre de projets à clôturer traitées : ' || to_char(cur_projects_Enclosed%ROWCOUNT));
    Fnd_File.put_line (Fnd_File.LOG,'--------------------------------------------------------------------------------');
    ----- Fermeture du curseur -----
    CLOSE cur_projects_Enclosed;

    --dka_tools_pkg.put_debug_message (' fermeture du curseur ');

    ----- Ouverture du curseur projets à Fermer------
    OPEN cur_projects_closed;

    --dka_tools_pkg.put_debug_message ('Ouverture du curseur ');

    ----- Chargement du curseur -----
    LOOP
      FETCH cur_projects_closed
        INTO pr_projects_closed;
      EXIT WHEN cur_projects_closed%NOTFOUND;

      --dka_tools_pkg.put_debug_message ('chargement du curseur  ');

      BEGIN
        -- lecture du curseur cur_projects_closed
        SAVEPOINT dka_projects_closed;
        pv_errbuf  := NULL;
        pn_retcode := 0;
        Fnd_File.put_line (Fnd_File.LOG,'Appel de  update_project_closed');
        dka_icodeprojet_pkg.update_project_closed(pr_projects_closed.project_id,
                                                  pv_errbuf,
                                                  pn_retcode);

        IF pn_retcode != 0 THEN
          RAISE e_error_curseur_closed;
        END IF;

        -- Ecriture dans le fichier de sortie --
        dka_tools_pkg.put_outdebug_message('Le projet ' || pr_projects_closed.segment1 || ' a été fermé le ' ||
                                           to_char(pr_projects_closed.completion_date,
                                                   cv_std_date_mask));
        --  dka_tools_pkg.put_debug_message ('le projet '|| pr_projects_closed.project_id || ' a été fermé');
      EXCEPTION
        -- lecture du curseur cur_tbl_dit_reject
        WHEN e_error_curseur_closed THEN
          pn_count := pn_count + 1;
          dka_tools_pkg.put_outdebug_message('ERREUR : Le projet ' || pr_projects_closed.segment1 || 'n''a pas été fermé le' ||
                                             to_char(pr_projects_closed.completion_date,
                                                   cv_std_date_mask));
          ROLLBACK TO SAVEPOINT dka_projects_closed;
        WHEN OTHERS THEN
          ROLLBACK TO SAVEPOINT dka_projects_closed;
          pn_count  := pn_count + 1;
          pv_errbuf := SQLERRM;
          dka_tools_pkg.put_outdebug_message('Autre erreur  : le projet ' || pr_projects_closed.segment1 || ' n''a pas été fermé');
      END; -- lecture du curseur cur_projects_closed

    END LOOP;

    ----- Validation -----
    COMMIT;
    Fnd_File.put_line (Fnd_File.LOG,'--------------------------------------------------------------------------------');
    Fnd_File.put_line (Fnd_File.LOG,'UPDATE_PROJECT_MONTH_STATUS - Nombre de projets à Fermer traitées : ' || to_char(cur_projects_closed%ROWCOUNT));
    Fnd_File.put_line (Fnd_File.LOG,'--------------------------------------------------------------------------------');
    ----- Fermeture du curseur -----
    CLOSE cur_projects_closed;

    IF pn_count != 0 THEN
      pn_retcode := 1;
    END IF;

    Fnd_File.put_line (Fnd_File.LOG,'fin du UPDATE_PROJECT_MONTH_STATUS');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := SQLERRM;
      pn_retcode := 2;
      Fnd_File.put_line (Fnd_File.LOG,'EXCEPTION UPDATE_PROJECT_MONTH_STATUS : ' || pv_errbuf);
  END update_project_month_status;


  --------------------------------------------------------------------------------------
  --  Nom           : UPDATE_MONTH_PROJECT
  --  Description   : Procédure de mise à jour mensuelle des projets
  --
  --  PARAMETRES :
  --    pv_errbuf                       Entrée/Sortie           retour de message eventuel
  --    pn_retcode                      Sortie                  status du traitement en sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
  --
  ----------------------------------------------------------------------------------------
  PROCEDURE update_month_project(pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    CURSOR cur_tbl_ppa_projects IS
    /* SELECT ppa.project_id,
                                            ppa.segment1,
                                            ppa.start_date,
                                            ppa.carrying_out_organization_id,
                                            pcdo.override_to_organization_id,
                                            ppa.project_type,
                                            ppa.org_id
                                     FROM   pa_projects_all ppa,
                                            pa_cost_dist_overrides pcdo
                                     WHERE  ppa.carrying_out_organization_id != pcdo.override_to_organization_id
                                            -- Sur la premiere période PA ouverte --
                                        AND pcdo.start_date_active < dka_tools_pkg.
                                    AND NVL(pcdo.end_date_active,pd_date_ref) >= pd_date_ref
                                        AND ppa.project_id = pcdo.project_id
                                            -- le project a un status actif
                                        AND ppa.project_status_code = gv_project_status_code_actif;
                                   */

--      SELECT /*+ordered*/
--       ppa.project_id,
--       ppa.segment1,
--       ppa.start_date,
--       ppa.carrying_out_organization_id,
--       haou.organization_id,
--       ppa.project_type,
--       ppa.org_id
--        FROM pa_projects /*_all*/ /* ETANCHEITE DALKIA 2007*/               ppa,
--             hr_all_organization_units haou
--       WHERE haou.NAME = dka_tools_pkg.get_appart(ppa.project_id,
--                                                  dka_tools_pkg.get_pa_period_date_f(NULL,
--                                                                                     ppa.org_id))
--            -- Sur la premiere période PA ouverte --
--         AND haou.organization_id != ppa.carrying_out_organization_id
--            -- le project a un status actif
--         AND ppa.project_status_code = gv_project_status_code_actif;
--         */
      SELECT
       ppa.project_id,
       ppa.segment1,
       ppa.start_date,
       ppa.carrying_out_organization_id,
       pcdo.override_to_organization_id organization_id,
       ppa.project_type,
       ppa.org_id,
       hao.name
      FROM pa_cost_dist_overrides pcdo ,
            pa_projects_all ppa,
            hr_all_organization_units hao,
            per_security_profiles_v psp,
            per_security_organizations_v pso
      WHERE pcdo.project_id = ppa.project_id
      AND   pso.security_profile_id = psp.security_profile_id
      AND   psp.security_profile_id = FND_PROFILE.VALUE ('XLA_MO_SECURITY_PROFILE_LEVEL')
      AND   pso.organization_id        = ppa.org_id --YWA  --artf2076309
      --AND   pcdo.end_date_active IS NULL
      AND   pcdo.override_to_organization_id <> ppa.carrying_out_organization_id
      AND   pcdo.override_to_organization_id = hao.organization_id
      AND   pcdo.start_date_active BETWEEN   g_start_date_en_cours AND g_end_date_en_cours
      AND   ppa.project_status_code = gv_project_status_code_actif;

    pr_ppa_projects cur_tbl_ppa_projects%ROWTYPE;
    e_error_curseur_ppa EXCEPTION;
    pn_count           NUMBER(15);
    vd_period_end_date DATE;
  BEGIN
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
    pn_count   := 0;
    Fnd_File.put_line (Fnd_File.LOG,'*************   DÉBUT DE LA PROCÉDURE UPDATE_MONTH_PROJECT     *********************');

    ----- Ouverture du curseur ------
    OPEN cur_tbl_ppa_projects;

    --dka_tools_pkg.put_debug_message (' Ouverture du curseur ');

    ----- Chargement du curseur -----
    LOOP
      FETCH cur_tbl_ppa_projects
        INTO pr_ppa_projects;
      EXIT WHEN cur_tbl_ppa_projects%NOTFOUND;

      BEGIN
        -- lecture du curseur cur_tbl_ppa_projects
        SAVEPOINT dka_ppa_projects;
        pv_errbuf  := NULL;
        pn_retcode := 0;
        -- Récupération de la date de fin de la première periode comptable ouverte PA --
        --vd_period_end_date    := dka_tools_pkg.get_pa_period_date_f (SYSDATE, pr_ppa_projects.org_id);
        /*vd_period_end_date := dka_tools_pkg.get_pa_period_date_f(NULL,
                                                                 pr_ppa_projects.org_id);*/
        -- mise à jour de la nouvelle organisation du projet sur la fiche projet --
        --dka_tools_pkg.put_debug_message ('mise à jour de la nouvelle organisation UPDATE_MONTH_ORG_PROJECT :');
        dka_icodeprojet_pkg.update_month_org_project(pr_ppa_projects.project_id,
                                                     pr_ppa_projects.organization_id,
                                                     vd_period_end_date,
                                                     pv_errbuf,
                                                     pn_retcode);

        IF pn_retcode != 0 THEN
          RAISE e_error_curseur_ppa;
        END IF;

        -- mise à jour de la nouvelle organisation sur les différentes tâches du projet  --
        --dka_tools_pkg.put_debug_message ('mise à jour de la nouvelle organisation UPDATE_MONTH_ORG_TASK :');
        dka_icodeprojet_pkg.update_month_org_task(pr_ppa_projects.project_id,
                                                  pr_ppa_projects.organization_id,
                                                  vd_period_end_date,
                                                  pv_errbuf,
                                                  pn_retcode);

        IF pn_retcode != 0 THEN
          RAISE e_error_curseur_ppa;
        END IF;

/*
        -- Mise à jour du nouveau barèmes de frais généraux pour les projets de type exploitation --
        IF pr_ppa_projects.project_type = gv_project_type_exploitation THEN
          dka_icodeprojet_pkg.update_baremes(pr_ppa_projects.project_id,
                                             pr_ppa_projects.carrying_out_organization_id,
                                             pr_ppa_projects.organization_id,
                                             pr_ppa_projects.start_date,
                                             pr_ppa_projects.org_id,
                                             pv_errbuf,
                                             pn_retcode);

          IF pn_retcode != 0 THEN
            RAISE e_error_curseur_ppa;
          END IF;
        END IF;
*/
        -- Ecriture dans le fichier de sortie --
         dka_tools_pkg.put_outdebug_message('L''organisation du projet ' || pr_ppa_projects.segment1 ||
                                           ' a été modifiée : la nouvelle organisation est ' || pr_ppa_projects.name);
      EXCEPTION
        -- lecture du curseur cur_tbl_dit_reject
        WHEN e_error_curseur_ppa THEN
          pn_count  := pn_count + 1;
          pv_errbuf := 'L''organisation du projet ' || pr_ppa_projects.segment1 || ' n''a pas été modifié';
          ROLLBACK TO SAVEPOINT dka_ppa_projects;
          -- Ecriture dans le fichier de sortie --
          dka_tools_pkg.put_outdebug_message(pv_errbuf);
        WHEN OTHERS THEN
          ROLLBACK TO SAVEPOINT dka_ppa_projects;
          pn_count  := pn_count + 1;
          pv_errbuf := SQLERRM;
          -- Ecriture dans le fichier de sortie --
          dka_tools_pkg.put_outdebug_message('L''organisation du projet ' || pr_ppa_projects.segment1 || ' n''a pas été modifié ' || pv_errbuf);
      END; -- lecture du curseur cur_tbl_ppa_projects

    END LOOP;

    ----- Validation -----
    COMMIT;
    Fnd_File.put_line (Fnd_File.LOG,'--------------------------------------------------------------------------------');
    Fnd_File.put_line (Fnd_File.LOG,'Nombre de lignes UPDATE_MONTH_PROJECT traitées : ' || to_char(cur_tbl_ppa_projects%ROWCOUNT));
    Fnd_File.put_line (Fnd_File.LOG,'--------------------------------------------------------------------------------');
    ----- Fermeture du curseur -----
    CLOSE cur_tbl_ppa_projects;

    --dka_tools_pkg.put_debug_message (' fermeture du curseur ');

    IF pn_count != 0 THEN
      pn_retcode := 1;
    END IF;

    Fnd_File.put_line (Fnd_File.LOG,'fin du UPDATE_MONTH_PROJECT');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := SQLERRM;
      pn_retcode := 2;
      Fnd_File.put_line (Fnd_File.LOG,'EXCEPTION UPDATE_MONTH_PROJECT : ' || pv_errbuf);
  END update_month_project;

  ----------------------------------------------------------------------------------------
  --  Nom           : UPDATE_MONTH_ORG_PROJECT
  --  Description   : Procédure mettant à jour l'organisation mensuelle du projet
  --
  --  PARAMETRES :
  --    pn_rec                  Entrée
  --    pv_errbuf               Sortie
  --    pn_retcode               Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal
  --                         2: erreur
  --                         ou le code erreur ORA
  ----------------------------------------------------------------------------------------
  PROCEDURE update_month_org_project(pn_project_id      IN NUMBER,
                                     pn_organization_id IN NUMBER,
                                     pd_date_ref        IN DATE,
                                     pv_errbuf          OUT VARCHAR2,
                                     pn_retcode         OUT NUMBER) IS
  BEGIN
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;

    ----- Mise à jour de l'organisation sur la fiche projet sur la période PA ouverte -----
    UPDATE pa_projects /*_all*/ /* ETANCHEITE DALKIA 2007*/ ppa
       SET ppa.carrying_out_organization_id = pn_organization_id,
           ppa.last_update_date             = SYSDATE,
           ppa.last_updated_by              = g_user_id,
           ppa.last_update_login            = g_login_id
     WHERE ppa.project_id = pn_project_id;
    --       AND pd_date_ref > (SELECT start_date_active
    --                          FROM   pa_cost_dist_overrides pcdo
    --                          WHERE      pcdo.project_id = pn_project_id
    --                                 AND pcdo.end_date_active IS NULL);
    --   AND ppa.project_status_code  = gv_project_status_code_actif;   projet actif

    -- dka_tools_pkg.put_debug_message ('ligne mise à jour sur le l''orga  : '|| SQL%ROWCOUNT);
    -- dka_tools_pkg.put_debug_message ('fin UPDATE_MONTH_ORG_PROJECT');
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := ' Erreur UPDATE_MONTH_ORG_PROJECT :' || SQLERRM;
  END update_month_org_project;

  ----------------------------------------------------------------------------------------
  --  Nom           : UPDATE_MONTH_ORG_TASK
  --  Description   : Procédure mettant à jour l'organisation mensuelle du projet
  --
  --  PARAMETRES :
  --    pn_rec                  Entrée
  --    pv_errbuf               Sortie
  --    pn_retcode               Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal
  --                         2: erreur
  --                         ou le code erreur ORA
  ----------------------------------------------------------------------------------------
  PROCEDURE update_month_org_task(pn_project_id      IN NUMBER,
                                  pn_organization_id IN NUMBER,
                                  pd_date_ref        IN DATE,
                                  pv_errbuf          OUT VARCHAR2,
                                  pn_retcode         OUT NUMBER) IS
  BEGIN
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;

    ----- Mise à jour de l'organisation sur la fiche projet  -----
    UPDATE pa_tasks pt
       SET pt.carrying_out_organization_id = pn_organization_id,
           pt.last_update_date             = SYSDATE,
           pt.last_updated_by              = g_user_id,
           pt.last_update_login            = g_login_id
     WHERE pt.project_id = pn_project_id;
    --       AND pd_date_ref > (SELECT start_date_active
    --                          FROM   pa_cost_dist_overrides pcdo
    --                        WHERE      pcdo.project_id = pn_project_id
    --                                 AND pcdo.end_date_active IS NULL);

    -- dka_tools_pkg.put_debug_message ('ligne mise à jour sur le l''orga sur tache  : '|| SQL%ROWCOUNT);
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := ' Erreur UPDATE_MONTH_ORG_TASK :' || SQLERRM;
  END update_month_org_task;

  --------------------------------------------------------------------------------------
  --  Nom           : MAIN2
  --  Description   : Procédure de mise à jour mensuelle des projets
  --
  --  PARAMETRES :
  --    pv_errbuf                       Entrée/Sortie           retour de message eventuel
  --    pn_retcode                      Sortie                  status du traitement en sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
  --
  ----------------------------------------------------------------------------------------
  PROCEDURE main2(pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    vn_retcode  NUMBER(1);
    vn_retcode2 NUMBER(1);
  BEGIN
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
    Fnd_File.put_line (Fnd_File.LOG,'**********************    DÉBUT DE LA PROCÉDURE MAIN2   ********************************');
    ----- Initialisation des variables globales du PACKAGE -----
    --Fnd_File.put_line (Fnd_File.LOG,'        Initialisation des variables globales du PACKAGE  ');

    dka_icodeprojet_pkg.init(pv_errbuf,
                             pn_retcode);

    IF pn_retcode != 0 THEN
      pv_errbuf  := 'ERREUR PROCEDURE dka_icodeprojet_pkg.init : ' || pv_errbuf;
      pn_retcode := 2;
      Fnd_File.put_line (Fnd_File.LOG,pv_errbuf);
      RETURN;
    END IF;

    -- Ecriture de l'entête du fichier de sortie --
    dka_tools_pkg.put_out_header;

    Fnd_File.put_line (Fnd_File.OUTPUT,'Période PA en cours : '||g_period_name);

    Fnd_File.put_line (Fnd_File.OUTPUT,'');
    Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------------------------+');
    Fnd_File.put_line (Fnd_File.OUTPUT,'');

    -- mise à jour de la nouvelle organisation du projet sur la fiche projet --
    --dka_tools_pkg.put_debug_message ('   nouvelle organisation du projet sur la fiche projet UPDATE_MONTH_PROJECT  ');
    dka_icodeprojet_pkg.update_month_project(pv_errbuf,
                                             vn_retcode);

    IF vn_retcode = 2 THEN
      Fnd_File.put_line (Fnd_File.LOG,'ERREUR  UPDATE_MONTH_PROJECT  : ' || pv_errbuf);
      pn_retcode := 2;
      RETURN;
    ELSIF vn_retcode = 1 THEN
      pn_retcode := 1;
    END IF;

    -- Mise à jour du status du projet à "fermé" ou ""clôturé" --
    dka_tools_pkg.put_debug_message ('  Mise à jour du status des projets UPDATE_PROJECT_MONTH_STATUS  ');
    dka_icodeprojet_pkg.update_project_month_status(pv_errbuf,
                                                    vn_retcode2);

    IF vn_retcode2 = 2 THEN
      Fnd_File.put_line (Fnd_File.LOG,'ERREUR  UPDATE_PROJECT_STATUS_CLOSED  : ' || pv_errbuf);
      pn_retcode := 2;
      RETURN;
    ELSIF vn_retcode2 = 1 THEN
      pn_retcode := 1;
    END IF;

    Fnd_File.put_line (Fnd_File.LOG,'fin du main 2');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := SQLERRM;
      pn_retcode := 2;
      Fnd_File.put_line (Fnd_File.LOG,'EXCEPTION MAIN2 : ' || pv_errbuf);
  END main2;


END DKA_ICODEPROJET_PKG;

/

SHOW ERRORS;
EXIT
