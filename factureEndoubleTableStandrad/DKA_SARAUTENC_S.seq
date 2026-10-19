CREATE OR REPLACE PACKAGE BODY dka_sfa_fusion_societe_pkg AS
  ---------------------------------------------------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_FUSION_FA_PKG.pkb
  -- DESCRIPTION       : DKA_FUSION_FA_PKG package body :
  ---
  --- AUTEUR           : N. BOUSSEKEYT
  --- DATE DE CREATION : 06/08/2019
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
  -----------------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  -- Private type declarations
  -- 03/10/2019 NBO Modification sur le contrôle avant importation pour éviter de mettre à jour les status à tort.

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  gv_printer          fnd_concurrent_requests.printer%TYPE;
  g_number_of_copies  fnd_concurrent_requests.number_of_copies%TYPE;
  g_user_id           fnd_user.user_id%TYPE;
  g_login_id          fnd_logins.login_id%TYPE;
  g_request_id        fnd_concurrent_requests.request_id%TYPE := fnd_global.conc_request_id;
  g_loader_request_id fnd_concurrent_requests.request_id%TYPE;
  TYPE tab_request IS TABLE OF fnd_concurrent_requests.request_id%TYPE INDEX BY BINARY_INTEGER;
  g_tab_requests tab_request;

  TYPE summary_typ IS RECORD(
    loaded_rows_social NUMBER -- Nb de Lignes chargées en table spécifique
    ,
    rejected_rows      NUMBER -- Nb de lignes rejetées en table spécifique
    ,
    valid_rows_social  NUMBER -- Nb de lignes presentes pour les livres sociaux
    ,
    import_rows_social NUMBER -- Nb de lignes presentes pour les livres sociaux
    ,
    import_rows_ifrs   NUMBER -- Nb de lignes presentes pour les livres fiscaux
    );

  g_summary summary_typ;

  ------------
  -- Constantes
  ------------
  gv_statut_new        VARCHAR2(20) := 'NEW';
  gv_statut_valid      VARCHAR2(20) := 'VALID';
  gv_statut_ko         VARCHAR2(20) := 'INVALID';
  gv_statut_ok         VARCHAR2(20) := 'IMPORTED';
  gv_statut_postimport VARCHAR2(20) := 'POST_IMPORT';

  ------------
  -- Exceptions
  ------------
  -- Erreur SQL
  erreur_gen_e EXCEPTION;

  -- Erreur lors d'un controle
  erreur_cont_e EXCEPTION;

  CURSOR cur_proj_tache_ferme IS
    SELECT hou.name org_name,
           pps.project_status_name,
           ppa.segment1 project_code,
           ppa.completion_date ppa_completion_date,
           ppa.closed_date,
           pt.task_name,
           pt.task_number,
           fc.segment1 || '.' || fc.segment2 || '.' || fc.segment3 || '.' ||
           fc.segment4 categorie_name,
           pt2.task_number tache_parent,
           pt.description pt_libelle,
           pt.start_date pt_start_date,
           pt.completion_date pt_completion_date,
           hou2.name org_name2,
           ppa.description libelle,
           ppa.project_type,
           ppc.class_code affaire,
           ppc2.class_code destination,
           ppc3.class_code filiere,
           nvl(ppc4.class_code, 'XXXX') activite,
           ppa.start_date,
           (SELECT DISTINCT dsl.return_value
              FROM dka_stransco_lines dsl, dka_stransco_headers dsh
             WHERE dsh.set_name = g_transco
               AND dsl.set_id = dsh.set_id
               AND nvl(dsl.enable, 'N') = 'Y'
               AND dsl.param1_value = hou2.name) org_absorbante,
           substr(ppa2.name, instr(ppa2.name, '.') + 1) modele
      FROM fa_asset_invoices         fai,
           pa_projects_all           ppa,
           pa_projects_all           ppa2,
           pa_project_statuses       pps,
           pa_tasks                  pt,
           hr_all_organization_units hou,
           hr_all_organization_units hou2,
           pa_project_classes_v      ppc,
           pa_project_classes_v      ppc2,
           pa_project_classes_v      ppc3,
           pa_project_classes_v      ppc4,
           fa_categories_vl          fc,
           pa_tasks                  pt2
     WHERE 1 = 1
       AND ppa.project_status_code = pps.project_status_code
       AND ppa.segment1 LIKE 'FC%'
       AND pps.status_type = 'PROJECT'
       AND pt.task_id = fai.task_id
       AND pt.task_number LIKE 'GY%'
       AND ppa.project_id = fai.project_id
       AND pps.project_status_name = 'Fermé'
       AND ppa.completion_date IS NOT NULL
          -- AND pt.completion_date IS NOT NULL
       AND ppa.created_from_project_id = ppa2.project_id
       AND ppa.org_id IN (SELECT DISTINCT hou.organization_id
                            FROM dka_stransco_lines   dsl,
                                 dka_stransco_headers dsh,
                                 hr_operating_units   hou
                           WHERE dsh.set_name = g_transco
                             AND dsl.set_id = dsh.set_id
                             AND nvl(dsl.enable, 'N') = 'Y'
                             AND dsl.param1_value = hou.name)
       AND hou.organization_id = ppa.carrying_out_organization_id
       AND ppa.org_id = hou2.organization_id
       AND ppc.project_id(+) = ppa.project_id
       AND ppc.class_category(+) = 'AFFAIRE'
       AND ppc2.project_id(+) = ppa.project_id
       AND ppc2.class_category(+) = 'DESTINATION'
       AND ppc3.project_id(+) = ppa.project_id
       AND ppc3.class_category(+) = 'FILIERE'
       AND ppc4.project_id(+) = ppa.project_id
       AND ppc4.class_category(+) = 'ACTIVITE'
       AND fc.category_id(+) = pt.attribute6
       AND pt2.task_id(+) = pt.attribute7;

  CURSOR cur_proj_tache_ferme_parent IS
    SELECT hou.name org_name,
           pps.project_status_name,
           ppa.segment1 project_code,
           ppa.completion_date ppa_completion_date,
           ppa.closed_date,
           pt.task_name,
           pt.task_number,
           fc.segment1 || '.' || fc.segment2 || '.' || fc.segment3 || '.' ||
           fc.segment4 categorie_name,
           pt2.task_number tache_parent,
           pt.description pt_libelle,
           pt.start_date pt_start_date,
           pt.completion_date pt_completion_date,
           hou2.name org_name2,
           ppa.description libelle,
           ppa.project_type,
           ppc.class_code affaire,
           ppc2.class_code destination,
           ppc3.class_code filiere,
           nvl(ppc4.class_code, 'XXXX') activite,
           ppa.start_date,
           (SELECT DISTINCT dsl.return_value
              FROM dka_stransco_lines dsl, dka_stransco_headers dsh
             WHERE dsh.set_name = g_transco
               AND dsl.set_id = dsh.set_id
               AND nvl(dsl.enable, 'N') = 'Y'
               AND dsl.param1_value = hou2.name) org_absorbante,
           substr(ppa2.name, instr(ppa2.name, '.') + 1) modele
      FROM pa_projects_all           ppa,
           pa_projects_all           ppa2,
           pa_project_statuses       pps,
           pa_tasks                  pt,
           hr_all_organization_units hou,
           hr_all_organization_units hou2,
           pa_project_classes_v      ppc,
           pa_project_classes_v      ppc2,
           pa_project_classes_v      ppc3,
           pa_project_classes_v      ppc4,
           fa_categories_vl          fc,
           pa_tasks                  pt2
     WHERE 1 = 1
       AND ppa.project_status_code = pps.project_status_code
       AND pps.status_type = 'PROJECT'
       AND pt.project_id = ppa.project_id
       AND substr(pt.task_number, 1, 10) IN
           (SELECT DISTINCT tache_parent FROM dka.dka_fa_projet_ferme)
       AND ppa.created_from_project_id = ppa2.project_id
       AND ppa.org_id IN (SELECT DISTINCT hou.organization_id
                            FROM dka_stransco_lines   dsl,
                                 dka_stransco_headers dsh,
                                 hr_operating_units   hou
                           WHERE dsh.set_name = g_transco
                             AND dsl.set_id = dsh.set_id
                             AND nvl(dsl.enable, 'N') = 'Y'
                             AND dsl.param1_value = hou.name)
       AND hou.organization_id = ppa.carrying_out_organization_id
       AND ppa.org_id = hou2.organization_id
       AND ppc.project_id(+) = ppa.project_id
       AND ppc.class_category(+) = 'AFFAIRE'
       AND ppc2.project_id(+) = ppa.project_id
       AND ppc2.class_category(+) = 'DESTINATION'
       AND ppc3.project_id(+) = ppa.project_id
       AND ppc3.class_category(+) = 'FILIERE'
       AND ppc4.project_id(+) = ppa.project_id
       AND ppc4.class_category(+) = 'ACTIVITE'
       AND fc.category_id(+) = pt.attribute6
       AND pt2.task_id(+) = pt.attribute7;

  CURSOR cur_proj_tache_cout(p_org_id_absorbee   NUMBER,
                             p_org_id_absorbante NUMBER) IS
    SELECT peia.expenditure_item_id trans_id,
           substr(ppa.segment1, 1, 10) project,
           substr(pt.task_number, 1, 10) task,
           peia.transaction_source tx_src,
           peia.expenditure_item_date exp_date,
           peia.creation_date,
           peia.raw_cost,
           peia.quantity,
           peia.burden_cost,
           peia.expenditure_type,
           peia.org_id,
           p_org_id_absorbante org_id_absorbante,
           pcdla.dr_code_combination_id,
           hou.name org_depense
      FROM pa.pa_expenditure_items_all       peia,
           pa.pa_cost_distribution_lines_all pcdla,
           pa.pa_expenditures_all            pea,
           pa.pa_projects_all                ppa,
           pa.pa_tasks                       pt,
           hr_all_organization_units         hou
     WHERE peia.expenditure_item_id = pcdla.expenditure_item_id
       AND peia.expenditure_id = pea.expenditure_id
       AND peia.project_id = ppa.project_id
       AND peia.task_id = pt.task_id
       AND NOT EXISTS
     (SELECT 'x'
              FROM pa.pa_project_asset_line_details ppald
             WHERE peia.expenditure_item_id = ppald.expenditure_item_id)
       AND ppa.project_id = pt.project_id
       AND peia.transaction_source NOT IN ('MIGRATION_R12')
       AND ppa.segment1 LIKE 'FC%'
       AND pt.task_number LIKE 'GY%'
       AND peia.org_id = p_org_id_absorbee
       AND ppa.carrying_out_organization_id = hou.organization_id(+);

  CURSOR cur_soc_fusion_org IS
    SELECT dsl.return_value soc_to,
           substr(dsl.return_value, 4) cod_soc_to,
           hou2.organization_id org_id_to,
           dsl.param1_value soc_from,
           substr(dsl.param1_value, 4) cod_soc_from,
           hou.organization_id org_id_from,
           trunc(dsl.start_date, 'MONTH') - 1 date_fusion
      FROM dka_stransco_lines        dsl,
           dka_stransco_headers      dsh,
           hr_all_organization_units hou,
           hr_all_organization_units hou2
     WHERE dsh.set_name = g_transco
       AND dsl.set_id = dsh.set_id
       AND nvl(dsl.enable, 'N') = 'Y'
       AND hou.name = dsl.param1_value
       AND hou2.name = dsl.return_value;

  ---------------------------------------------------------------------
  --  Nom           : CTR_Exist_Livre_Cpt
  --  Description   : Controle de l'existence des livres comptables
  --                  destination et d'origine
  -- PARAMETRES :
  -- VALEUR RETOURNEE : Boolean
  ---------------------------------------------------------------------
  FUNCTION ctr_exist_livre_cpt(pv_livre VARCHAR2, pv_type VARCHAR2)
    RETURN BOOLEAN
  
   IS
    l_count NUMBER;
  BEGIN
  
    SELECT COUNT(1)
      INTO l_count
      FROM fa_book_controls fbc
     WHERE fbc.book_type_code LIKE pv_livre || '%' || pv_type
       AND fbc.date_ineffective IS NULL;
  
    IF l_count > 0 THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  
  END ctr_exist_livre_cpt;

  ---------------------------------------------------------------------
  --  Nom           : CTR_Period_soc
  --  Description   : Controle qu'il y a la meme période ouverte sur les livres sociaux fiscaux sur les différentes sociétés
  --                  destination et d'origine
  -- PARAMETRES :
  -- VALEUR RETOURNEE : Boolean
  ---------------------------------------------------------------------
  FUNCTION ctr_period_soc(pv_livre_absorbee   VARCHAR2,
                          pv_livre_absorbante VARCHAR2) RETURN VARCHAR2
  
   IS
    l_period_name VARCHAR2(50);
  BEGIN
  
    SELECT fdp1.period_name
      INTO l_period_name
      FROM fa_deprn_periods fdp1,
           fa_deprn_periods fdp2,
           fa_deprn_periods fdp3,
           fa_deprn_periods fdp4
     WHERE fdp1.book_type_code LIKE pv_livre_absorbee || '%IFRS'
       AND fdp1.period_close_date IS NULL
       AND fdp2.book_type_code LIKE pv_livre_absorbante || '%SOCIAL'
       AND fdp2.period_close_date IS NULL
       AND fdp1.period_name = fdp2.period_name
       AND fdp3.period_name = fdp2.period_name
       AND fdp3.book_type_code LIKE pv_livre_absorbee || '%IFRS'
       AND fdp3.period_close_date IS NULL
       AND fdp4.book_type_code LIKE pv_livre_absorbante || '%SOCIAL'
       AND fdp4.period_close_date IS NULL
       AND fdp3.period_name = fdp4.period_name;
  
    RETURN l_period_name;
  EXCEPTION
    WHEN no_data_found THEN
      RETURN NULL;
    WHEN OTHERS THEN
      RETURN NULL;
  END ctr_period_soc;

  ---------------------------------------------------------------------
  --  Nom           : CTR_ECRITURE_FA_IMPUTE
  --  Description   : Controle de validation des écritures comptables dans GL imputés
  -- PARAMETRES :
  -- VALEUR RETOURNEE : Boolean
  ---------------------------------------------------------------------
  FUNCTION ctr_ecriture_fa_impute(pv_sob VARCHAR2) RETURN BOOLEAN
  
   IS
    l_count NUMBER;
  BEGIN
  
    SELECT COUNT(1)
      INTO l_count
      FROM xla_ae_headers          xah,
           xla_ae_lines            xal,
           gl.gl_import_references gir,
           gl_je_headers           gjh,
           gl_je_lines             gjl,
           gl_sets_of_books        gsob
     WHERE 1 = 1
       AND xah.application_id = 140
          --  AND xah.ledger_id =  gsob.set_of_books_id
       AND xal.ae_header_id = xah.ae_header_id
       AND xal.application_id = 140
          --------------------------------------------
       AND gir.gl_sl_link_id = xal.gl_sl_link_id
       AND gir.gl_sl_link_table = xal.gl_sl_link_table
       AND gir.gl_sl_link_table = 'XLAJEL'
       AND gir.je_header_id = gjh.je_header_id
       AND gjh.actual_flag = 'A'
       AND gjl.gl_sl_link_id = gir.gl_sl_link_id
       AND gjl.gl_sl_link_table = 'XLAJEL'
       AND gjl.status != 'P'
       AND gjl.ledger_id = gsob.set_of_books_id
       AND gsob.short_name = pv_sob;
  
    IF l_count > 1 THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
  END ctr_ecriture_fa_impute;

  ---------------------------------------------------------------------
  --  Nom           : CTR_EVT_SLA_NON_COMPTA
  --  Description   : Controle qu'il n'y a plus d'événements FA/SLA non comptabilisés
  -- PARAMETRES :
  -- VALEUR RETOURNEE : Boolean
  ---------------------------------------------------------------------
  FUNCTION ctr_evt_sla_non_compta(pv_sob VARCHAR2) RETURN BOOLEAN
  
   IS
    l_count NUMBER;
  BEGIN
  
    SELECT COUNT(1)
      INTO l_count
      FROM xla_entity_events_v xe, gl_sets_of_books gsob
     WHERE xe.application_id = 140
       AND xe.process_status_code NOT IN ('P', 'Z')
       AND xe.ledger_id = gsob.set_of_books_id
       AND gsob.short_name = pv_sob;
  
    IF l_count > 1 THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
  END ctr_evt_sla_non_compta;

  ---------------------------------------------------------------------
  --  Nom           : ctr_mass_addition
  --  Description   : Controle qu'il n'y a plus de lignes dans la mass addition
  -- PARAMETRES :
  -- VALEUR RETOURNEE : Boolean
  ---------------------------------------------------------------------
  FUNCTION ctr_mass_addition RETURN BOOLEAN
  
   IS
    l_count NUMBER;
  BEGIN
  
    SELECT COUNT(1)
      INTO l_count
      FROM fa_mass_additions
     WHERE posting_status NOT IN ('POSTED');
  
    IF l_count > 1 THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
  END ctr_mass_addition;

  ---------------------------------------------------------------------
  --  Nom           : CTR_LIST_PROJET_TACHE_ACTIF
  --  Description   : Controle qu'il n'y a plus de projet et de tache actif
  -- PARAMETRES :
  -- VALEUR RETOURNEE : 
  ---------------------------------------------------------------------
  PROCEDURE ctr_list_projet_tache_actif IS
    CURSOR cur_proj_tache IS
      SELECT hou.name                org_name,
             pps.project_status_name,
             ppa.segment1,
             ppa.completion_date     ppa_completion_date,
             ppa.closed_date,
             pt.task_number,
             pt.completion_date      pt_completion_date
        FROM fa_asset_invoices         fai,
             pa_projects_all           ppa,
             pa_project_statuses       pps,
             pa_tasks                  pt,
             hr_all_organization_units hou
       WHERE 1 = 1
         AND ppa.project_status_code = pps.project_status_code
         AND ppa.segment1 LIKE 'FC%'
         AND pps.status_type = 'PROJECT'
         AND pt.task_id = fai.task_id
         AND pt.task_number LIKE 'GY%'
         AND ppa.project_id = fai.project_id
         AND ((pps.project_status_name = 'Actif' AND
             ppa.completion_date IS NULL AND ppa.closed_date IS NULL) OR
             pt.completion_date IS NULL)
            --AND ppa.carrying_out_organization_id IN
         AND ppa.org_id IN
             (SELECT DISTINCT hou.organization_id
                FROM dka_stransco_lines   dsl,
                     dka_stransco_headers dsh,
                     hr_operating_units   hou
               WHERE dsh.set_name = g_transco
                 AND dsl.set_id = dsh.set_id
                 AND nvl(dsl.enable, 'N') = 'Y'
                 AND dsl.param1_value = hou.name)
         AND hou.organization_id = ppa.carrying_out_organization_id;
  BEGIN
  
    dka_tools_pkg.put_outdebug_message(' ');
    dka_tools_pkg.put_outdebug_message('Liste les projects FC et les taches qui sont actifs :');
    dka_tools_pkg.put_outdebug_message('Nom Org | Project status Name | Project Name | Completion Date | Date de fermeture | Numero de Tache | Tache date de fin');
  
    FOR rec_proj_tache IN cur_proj_tache LOOP
      dka_tools_pkg.put_outdebug_message(rec_proj_tache.org_name || '|' ||
                                         rec_proj_tache.project_status_name || '|' ||
                                         rec_proj_tache.segment1 || '|' ||
                                         rec_proj_tache.ppa_completion_date || '|' ||
                                         rec_proj_tache.closed_date || '|' ||
                                         rec_proj_tache.task_number || '|' ||
                                         rec_proj_tache.pt_completion_date);
    END LOOP;
  
  END ctr_list_projet_tache_actif;

  ---------------------------------------------------------------------
  --  Nom           : CTR_LIST_PROJET_TACHE_FERME
  --  Description   : Controle qu'il n'y a plus de projet et de tache fermé
  -- PARAMETRES :
  -- VALEUR RETOURNEE : 
  ---------------------------------------------------------------------
  PROCEDURE ctr_list_projet_tache_ferme IS
  
  BEGIN
  
    dka_tools_pkg.put_outdebug_message(' ');
    dka_tools_pkg.put_outdebug_message('Liste les projects FC et les taches qui sont fermées :');
    dka_tools_pkg.put_outdebug_message('Nom Org | Project status Name | Project Name | Completion Date | Date de fermeture | Numero de Tache | Tache date de fin');
  
    FOR rec_proj_tache IN cur_proj_tache_ferme LOOP
      dka_tools_pkg.put_outdebug_message(rec_proj_tache.org_name || '|' ||
                                         rec_proj_tache.project_status_name || '|' ||
                                         rec_proj_tache.project_code || '|' ||
                                         rec_proj_tache.ppa_completion_date || '|' ||
                                         rec_proj_tache.closed_date || '|' ||
                                         rec_proj_tache.task_number || '|' ||
                                         rec_proj_tache.pt_completion_date);
    END LOOP;
  
  END ctr_list_projet_tache_ferme;

  ---------------------------------------------------------------------
  --  Nom           : ctr_list_projet_cout
  --  Description   : Controle qui liste l'ensemble des couts par projet
  -- PARAMETRES :
  -- VALEUR RETOURNEE : 
  ---------------------------------------------------------------------
  PROCEDURE ctr_list_projet_cout IS
  
  BEGIN
  
    dka_tools_pkg.put_outdebug_message(' ');
    dka_tools_pkg.put_outdebug_message('Liste les lignes de couts affectés aux projects FC :');
    dka_tools_pkg.put_outdebug_message('Trans Id | Project Name | Tache | Src Trans | Date Exp | Numero de Tache | Creation Date | Cout');
  
    FOR rec_soc IN cur_soc_fusion_org LOOP
    
      FOR rec_proj_tache IN cur_proj_tache_cout(rec_soc.org_id_from,
                                                rec_soc.org_id_to) LOOP
        dka_tools_pkg.put_outdebug_message(rec_proj_tache.trans_id || '/' ||
                                           rec_proj_tache.project || '/' ||
                                           rec_proj_tache.task || '/' ||
                                           rec_proj_tache.tx_src || '/' ||
                                           rec_proj_tache.exp_date || '/' ||
                                           rec_proj_tache.creation_date || '/' ||
                                           rec_proj_tache.raw_cost);
      END LOOP;
    END LOOP;
  
  END ctr_list_projet_cout;

  ---------------------------------------------------------------------
  --  Nom           : main_Ctr
  --  Description   : Procédure principale du controle des immo avant fusion
  --PARAMETRES :
  --  pv_errbuf   Entrée/Sortie          message d'erreur
  --  VALEUR RETOURNEE :  pn_retcode
  --Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ---------------------------------------------------------------------
  PROCEDURE main_ctr(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    vv_err_msg    VARCHAR2(1000);
    l_period_name VARCHAR2(100);
    l_erreur      BOOLEAN;
  
  BEGIN
    ----- Initialisation des variables -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
  
    dka_tools_pkg.put_log_message('Début');
  
    dka_tools_pkg.put_outdebug_message('Liste des erreurs de contrôle :');
    dka_tools_pkg.put_outdebug_message('-----------------------------------------');
  
    l_erreur := FALSE;
  
    FOR rec_soc_fusion IN cur_soc_fusion LOOP
    
      -- Vérifie que livre SOCIAL et IFRS existent pour la société absorbé et absorbante
      IF (NOT ctr_exist_livre_cpt(rec_soc_fusion.cod_soc_from, 'SOCIAL')) THEN
        dka_tools_pkg.put_outdebug_message('Le livre n''existe pas pour la société : ' ||
                                           rec_soc_fusion.cod_soc_from ||
                                           ' avec le type de livre SOCIAL');
        l_erreur := TRUE;
      ELSE
        dka_tools_pkg.put_outdebug_message('Le livre existe pour la société : ' ||
                                           rec_soc_fusion.cod_soc_from ||
                                           ' avec le type de livre SOCIAL');
      END IF;
    
      IF (NOT ctr_exist_livre_cpt(rec_soc_fusion.cod_soc_to, 'SOCIAL')) THEN
        dka_tools_pkg.put_outdebug_message('Le livre n''existe pas pour la société : ' ||
                                           rec_soc_fusion.cod_soc_to ||
                                           ' avec le type de livre SOCIAL');
        l_erreur := TRUE;
      ELSE
        dka_tools_pkg.put_outdebug_message('Le livre existe pour la société : ' ||
                                           rec_soc_fusion.cod_soc_to ||
                                           ' avec le type de livre SOCIAL');
      END IF;
    
      IF (NOT ctr_exist_livre_cpt(rec_soc_fusion.cod_soc_from, 'IFRS')) THEN
        dka_tools_pkg.put_outdebug_message('Le livre n''existe pas pour la société : ' ||
                                           rec_soc_fusion.cod_soc_from ||
                                           ' avec le type de livre IFRS');
        l_erreur := TRUE;
      ELSE
        dka_tools_pkg.put_outdebug_message('Le livre existe pour la société : ' ||
                                           rec_soc_fusion.cod_soc_from ||
                                           ' avec le type de livre IFRS');
      END IF;
    
      IF (NOT ctr_exist_livre_cpt(rec_soc_fusion.cod_soc_to, 'IFRS')) THEN
        dka_tools_pkg.put_outdebug_message('Le livre n''existe pas pour la société : ' ||
                                           rec_soc_fusion.cod_soc_to ||
                                           ' avec le type de livre IFRS');
        l_erreur := TRUE;
      ELSE
        dka_tools_pkg.put_outdebug_message('Le livre existe pour la société : ' ||
                                           rec_soc_fusion.cod_soc_to ||
                                           ' avec le type de livre IFRS');
      END IF;
    
      -- Vérifie qu'il existe sur la meme période
      l_period_name := ctr_period_soc(rec_soc_fusion.cod_soc_from,
                                      rec_soc_fusion.cod_soc_to);
    
      IF l_period_name IS NULL THEN
        dka_tools_pkg.put_outdebug_message('La periode n''est pas la meme entre les livres et les sociétés ' ||
                                           rec_soc_fusion.cod_soc_from ||
                                           ' / ' ||
                                           rec_soc_fusion.cod_soc_to);
        l_erreur := TRUE;
      END IF;
    
      -- Vérifie que la totalité des pièces ont été traduites de SLA dans FA
      IF (NOT ctr_evt_sla_non_compta(rec_soc_fusion.cod_soc_from)) THEN
        dka_tools_pkg.put_outdebug_message('Il y a des événements non traduits dans SLA : ' ||
                                           rec_soc_fusion.cod_soc_from);
        l_erreur := TRUE;
      END IF;
    
      IF (NOT ctr_evt_sla_non_compta(rec_soc_fusion.cod_soc_to)) THEN
        dka_tools_pkg.put_outdebug_message('Il y a des événements non traduits dans SLA : ' ||
                                           rec_soc_fusion.cod_soc_to);
        l_erreur := TRUE;
      END IF;
    
      -- Vérifie que la totalité des pièces ont été imputés
      IF (NOT ctr_ecriture_fa_impute(rec_soc_fusion.cod_soc_from)) THEN
        dka_tools_pkg.put_outdebug_message('Les pièces FA n''ont pas été imputés dans GL : ' ||
                                           rec_soc_fusion.cod_soc_from);
        l_erreur := TRUE;
      END IF;
    
      IF (NOT ctr_ecriture_fa_impute(rec_soc_fusion.cod_soc_from)) THEN
        dka_tools_pkg.put_outdebug_message('Les pièces FA n''ont pas été imputés dans GL : ' ||
                                           rec_soc_fusion.cod_soc_to);
        l_erreur := TRUE;
      END IF;
    
      IF (NOT ctr_mass_addition) THEN
        dka_tools_pkg.put_outdebug_message('Il y a des lignes non intégrés dans la table de haut volume');
        l_erreur := TRUE;
      END IF;
    
    END LOOP;
  
    IF l_erreur THEN
      pn_retcode := 1;
    END IF;
  
    ctr_list_projet_tache_actif;
  
    ctr_list_projet_tache_ferme;
  
    ctr_list_projet_cout;
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      -- Affichage du code et du message de l erreur
      vv_err_msg := substr(SQLERRM, 1, 512);
      pv_errbuf  := 'Erreur Oracle ' || vv_err_msg || ' dans main_Ctr ()';
      ROLLBACK;
      pn_retcode := 2;
  END main_ctr;

  FUNCTION xxfa_accytddeprn_get_fnc(p_asset_id NUMBER,
                                    p_book     VARCHAR2,
                                    p_type     VARCHAR2) RETURN NUMBER IS
    /*********************************************************************************
    * FUNCTION *  XXFA_ACCDEPRN_GET_FNC
    * DESCRIPTION *  The following function is required to derive the Consolidated and Monthly
    *  Unplanned depreciation details for Fixed Assets.
    * PARAMETERS * ==========
    * NAME                TYPE     DESCRIPTION
    * —————–      ———- ———————————————
    * p_asset_id            IN      Asset ID
    * p_btc                 IN        Book Type Code
    *********************************************************************************/
    l_deprn_reserve       NUMBER;
    l_ytd_deprn           NUMBER; -- YEAR - TO - DATE depreciation 
    l_bonus_deprn_reserve NUMBER;
    l_bonus_ytd_deprn     NUMBER;
    l_reval_reserve       NUMBER;
    l_cost                NUMBER;
    dummy_num             NUMBER;
    dummy_char            VARCHAR2(100);
    dummy_bool            BOOLEAN;
    l_book_type_code      VARCHAR2(20) := p_book;
    l_run_mode            VARCHAR2(20) := 'STANDARD';
    l_asset_id            NUMBER := p_asset_id;
  BEGIN
    -- standard api TO derive THE CURRENT accumulated depreciation FOR THE asset 
    apps.fa_query_balances_pkg.query_balances(x_asset_id              => l_asset_id,
                                              x_book                  => l_book_type_code,
                                              x_period_ctr            => 0,
                                              x_dist_id               => 0,
                                              x_run_mode              => l_run_mode,
                                              x_cost                  => l_cost,
                                              x_deprn_rsv             => l_deprn_reserve,
                                              x_reval_rsv             => l_reval_reserve,
                                              x_ytd_deprn             => l_ytd_deprn,
                                              x_ytd_reval_exp         => dummy_num,
                                              x_reval_deprn_exp       => dummy_num,
                                              x_deprn_exp             => dummy_num,
                                              x_reval_amo             => dummy_num,
                                              x_prod                  => dummy_num,
                                              x_ytd_prod              => dummy_num,
                                              x_ltd_prod              => dummy_num,
                                              x_adj_cost              => dummy_num,
                                              x_reval_amo_basis       => dummy_num,
                                              x_bonus_rate            => dummy_num,
                                              x_deprn_source_code     => dummy_char,
                                              x_adjusted_flag         => dummy_bool,
                                              x_transaction_header_id => -1,
                                              x_bonus_deprn_rsv       => l_bonus_deprn_reserve,
                                              x_bonus_ytd_deprn       => l_bonus_ytd_deprn,
                                              x_bonus_deprn_amount    => dummy_num,
                                              x_impairment_rsv        => dummy_num,
                                              x_ytd_impairment        => dummy_num,
                                              x_impairment_amount     => dummy_num,
                                              x_capital_adjustment    => dummy_num,
                                              x_general_fund          => dummy_num,
                                              x_mrc_sob_type_code     => 'P',
                                              x_set_of_books_id       => NULL,
                                              p_log_level_rec         => NULL);
    IF p_type = 'COST' THEN
      RETURN l_cost;
    ELSIF p_type = 'DEPRN' THEN
      RETURN l_deprn_reserve;
    ELSE
      RETURN l_ytd_deprn;
    END IF;
    -- accumulated depreciation, USE l_ytd_deprn AS RETURN VARIABLE TO calculate ytd depreciation 
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  ----------------------------------------------------------------------------------------
  --  Nom           : GET_CODE_COMBINATION_ID
  --  Description   : Procédure permettant de déterminer le code_combination_id
  --                  correspondant a la combinaison passée en parametre
  --                  Si la combinaison n'existe pas, elle est créée
  --                  Si la combinaison n'existe pas, elle est créée
  --  PARAMETRES :
  --    pv_segment1       Entrée
  --    pv_segment2       Entrée
  --    pv_segment3       Entrée
  --    pv_segment4       Entrée
  --    pv_segment5       Entrée
  --    pv_segment6       Entrée
  --    pv_segment7       Entrée
  --    pv_segment8       Entrée
  --    pv_segment9       Entrée
  --    pv_segment10      Entrée
  --    pv_segment11      Entrée
  --    pv_segment12      Entrée
  --
  --    pn_ccid           Sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal
  --                         2: erreur
  ----------------------------------------------------------------------------------------
  PROCEDURE get_code_combination_id(pv_segment1            IN VARCHAR2,
                                    pv_segment2            IN VARCHAR2,
                                    pv_segment3            IN VARCHAR2,
                                    pv_segment4            IN VARCHAR2,
                                    pv_segment5            IN VARCHAR2,
                                    pv_segment6            IN VARCHAR2,
                                    pv_segment7            IN VARCHAR2,
                                    pv_segment8            IN VARCHAR2,
                                    pv_segment9            IN VARCHAR2,
                                    pv_segment10           IN VARCHAR2,
                                    pv_segment11           IN VARCHAR2,
                                    pv_segment12           IN VARCHAR2,
                                    pn_code_combination_id OUT NUMBER,
                                    pv_errbuf              OUT VARCHAR2,
                                    pn_retcode             OUT NUMBER,
                                    pv_validation_flag     IN VARCHAR2 DEFAULT 'Y') IS
    vb_dummy                  BOOLEAN;
    va_segments_array         fnd_flex_ext.segmentarray;
    vn_nb_segments            NUMBER;
    vv_application_short_name fnd_application.application_short_name%TYPE;
    vv_key_flex_code          fnd_id_flex_segments.id_flex_code%TYPE;
    vn_structure_number       fnd_id_flex_segments.id_flex_num%TYPE;
    vd_validation_date        DATE;
    vn_code_combination_id    gl_code_combinations.code_combination_id%TYPE;
  BEGIN
  
    -- Initialisation des variables de sortie
    pv_errbuf  := NULL;
    pn_retcode := 0;
    -- Initialisation des variables
    vd_validation_date        := SYSDATE;
    vv_key_flex_code          := 'GL#';
    vv_application_short_name := 'SQLGL';
  
    SELECT fifs.id_flex_num, COUNT(1)
      INTO vn_structure_number, vn_nb_segments
      FROM (SELECT *
              FROM gl_access_set_assignments
             WHERE access_set_id = 1040
               AND rownum = 1) gasa,
           gl_ledgers gl,
           fnd_id_flex_segments fifs
     WHERE gl.ledger_id = gasa.ledger_id
       AND gl.ledger_category_code = 'PRIMARY'
       AND gl.chart_of_accounts_id = fifs.id_flex_num
       AND fifs.application_id = 101
       AND fifs.id_flex_code = 'GL#'
       AND fifs.enabled_flag = 'Y'
     GROUP BY fifs.id_flex_num;
  
    -- Si la vérification des regles n'est pas nécessaire, on regarde si la combinaison existe
    -- Dans ce cas, on retourne ce ccid directement
    IF pv_validation_flag = 'N' THEN
      BEGIN
        SELECT gcc.code_combination_id
          INTO pn_code_combination_id
          FROM gl_code_combinations gcc
         WHERE gcc.chart_of_accounts_id = vn_structure_number
           AND gcc.segment1 = pv_segment1
           AND gcc.segment2 = pv_segment2
           AND gcc.segment3 = pv_segment3
           AND gcc.segment4 = pv_segment4
           AND gcc.segment5 = pv_segment5
           AND gcc.segment6 = pv_segment6
           AND gcc.segment7 = pv_segment7
           AND gcc.segment8 = pv_segment8
           AND gcc.segment9 = pv_segment9
           AND gcc.segment10 = pv_segment10
           AND gcc.segment11 = pv_segment11
           AND gcc.segment12 = pv_segment12;
      
        -- On a trouvé la combinaison, donc on sort
        RETURN;
      EXCEPTION
        WHEN no_data_found THEN
          NULL;
      END;
    END IF;
  
    -- Remplissage de la variable Array
    va_segments_array(1) := pv_segment1;
    va_segments_array(2) := pv_segment2;
    va_segments_array(3) := pv_segment3;
    va_segments_array(4) := pv_segment4;
    va_segments_array(5) := pv_segment5;
    va_segments_array(6) := pv_segment6;
    va_segments_array(7) := pv_segment7;
    va_segments_array(8) := pv_segment8;
    va_segments_array(9) := pv_segment9;
    va_segments_array(10) := pv_segment10;
    va_segments_array(11) := pv_segment11;
    va_segments_array(12) := pv_segment12;
  
    -- Lancement de la fonction standard de détermination / génération du ccid
    vb_dummy := fnd_flex_ext.get_combination_id(vv_application_short_name,
                                                vv_key_flex_code,
                                                vn_structure_number,
                                                vd_validation_date,
                                                vn_nb_segments,
                                                va_segments_array,
                                                vn_code_combination_id);
  
    -- En cas d'erreur, récupération du message
    IF NOT vb_dummy THEN
      pv_errbuf              := pv_segment1 || '.' || pv_segment2 || '.' ||
                                pv_segment3 || '.' || pv_segment4 || '.' ||
                                pv_segment5 || '.' || pv_segment6 || '.' ||
                                pv_segment7 || '.' || pv_segment8 || '.' ||
                                pv_segment9 || '.' || pv_segment10 || '.' ||
                                pv_segment11 || '.' || pv_segment12 || '.' ||
                                fnd_flex_ext.get_message;
      pn_retcode             := 2;
      pn_code_combination_id := NULL;
    ELSE
      pn_code_combination_id := vn_code_combination_id;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'GET_CODE_COMBINATION_ID - ' || SQLERRM;
      pn_retcode := SQLCODE;
  END get_code_combination_id;

  /*
   *************************************************************************
   * PROCEDURE NAME : submit_project
   *
   * DESCRIPTION
   *  Soumission du traitement d'import des projets
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE submit_project(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
    v_request_id fnd_concurrent_requests.request_id%TYPE;
    l_resp_id    NUMBER;
    l_app_id     NUMBER;
  BEGIN
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début submit_project ');
  
    SELECT DISTINCT fr.responsibility_id, fr.application_id
      INTO l_resp_id, l_app_id
      FROM fnd_responsibility     fr,
           dka.dka_fa_projet_cout drci,
           pa_projects_all        pp,
           hr_operating_units     hou
     WHERE fr.responsibility_key LIKE 'TOUT_PA_ADMINISTRATEUR';
  
    fnd_global.apps_initialize(user_id      => g_user_id,
                               resp_id      => l_resp_id,
                               resp_appl_id => l_app_id);
  
    v_request_id := fnd_request.submit_request('DKA' -- APPL
                                              ,
                                               'DKA_IPROJECT' -- PROG
                                              ,
                                               NULL -- PROGRAM_NAME
                                              ,
                                               NULL -- START
                                              ,
                                               FALSE -- SUB_REQUEST
                                               );
  
    IF v_request_id = 0 THEN
      p_retcode := 2;
      fnd_file.put_line(fnd_file.log,
                        'ERREUR : Le traitement submit_project a échoué' ||
                        chr(10));
      fnd_file.put_line(fnd_file.output,
                        '====> ERREUR :Le traitement submit_project a échoué');
    ELSE
      COMMIT;
      g_tab_requests(v_request_id) := v_request_id;
    
      fnd_file.put_line(fnd_file.output,
                        '. Numéro du traitement submit_project  : ' ||
                        v_request_id);
    END IF;
  
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin submit_project ');
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'submit_project :' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure submit_project  EXCEPTION OTHERS ');
  END submit_project;

  /*=========================================================================*/
  /* PROCEDURE NAME :   program_import_couts
  /*
  /* DESCRIPTION  Traitement standard d'import des fournisseurs
  /*
  /*
  /* PARAMETERS
  /* ==========
  /* NAME               DESCRIPTION
  /* -----------------  ------------------------------------------------------
  /*
  /*
  /*=========================================================================*/
  PROCEDURE program_import_couts(pv_errbuf  IN OUT VARCHAR2,
                                 pn_retcode IN OUT NUMBER) IS
  
    v_phase      VARCHAR2(100);
    v_status     VARCHAR2(100);
    v_dev_phase  VARCHAR2(100);
    v_dev_status VARCHAR2(100);
    v_message    VARCHAR2(100);
  
    -- NBO 28/10/16 - Utilise la responsabilité TOUT_PA_ADMINISTRATEUR
    --récupération des différentes responsabilités pour lesquelles il faut lancer le traitement
    CURSOR cur_resp IS
      SELECT DISTINCT fr.responsibility_key,
                      fr.responsibility_id,
                      fr.application_id,
                      hou.organization_id   org_id,
                      hou.name              org_name
        FROM fnd_responsibility     fr,
             dka.dka_fa_projet_cout drci,
             pa_projects_all        pp,
             hr_operating_units     hou
       WHERE fr.responsibility_key LIKE 'TOUT_PA_ADMINISTRATEUR'
         AND drci.project = pp.segment1
         AND pp.org_id = hou.organization_id
         AND drci.org_id_absorbante = pp.org_id
         AND drci.statut IN (gv_statut_ok);
  
    -- NBO 28/10/16 - Sélectionne les lignes rejetés à flagger
    CURSOR cur_dka IS
      SELECT dka.rowid rid, ptia.transaction_rejection_code
        FROM pa_transaction_interface_all ptia,
             dka.dka_fa_projet_cout       dka,
             hr_operating_units           hou
       WHERE transaction_status_code = 'R'
         AND ptia.transaction_source = 'FUSION_FA'
         AND dka.project = ptia.project_number
         AND dka.task = ptia.task_number
         AND hou.organization_id = ptia.org_id
         AND dka.statut IN (gv_statut_ok);
  
  BEGIN
    dka_tools_pkg.put_log_message(to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' ||
                                  'Début de la procédure program_import_couts');
  
    FOR v_tmp IN cur_resp LOOP
    
      dka_tools_pkg.put_log_message(to_char(SYSDATE,
                                            'DD/MM/YYYY HH24:MI:SS') ||
                                    ' - ' || 'positionnement de la resp :' ||
                                    v_tmp.responsibility_id || ' org_id:' ||
                                    v_tmp.org_id);
    
      fnd_global.apps_initialize(user_id      => g_user_id,
                                 resp_id      => v_tmp.responsibility_id,
                                 resp_appl_id => v_tmp.application_id);
    
      --MO_GLOBAL.INIT (p_appl_short_name => v_tmp.application_short_name);
    
      -- NBO 28/10/16 - Positionne l'org de la responsabilité
      fnd_request.set_org_id(v_tmp.org_id);
    
      g_request_id := fnd_request.submit_request('PA', --APPL
                                                 'PAXTRTRX', --PROG
                                                 NULL, --PROGRAM_NAME
                                                 NULL, --START
                                                 FALSE, --SUB_REQUEST
                                                 'FUSION_FA' --Source           --ARGUMENT1
                                                 );
    
      IF g_request_id = 0 THEN
        pn_retcode := 2;
        pv_errbuf  := 'ERREUR : Le traitement standard d''import des coûts s''est terminé en erreur.';
        dka_tools_pkg.put_log_message('ERREUR : Le traitement standard d''import des coûts s''est terminé en erreur.' ||
                                      chr(10) ||
                                      'PROGRAMME  : Importation des coûts ');
      ELSE
        COMMIT;
        dka_tools_pkg.put_outdebug_message('Numéro du traitement standard d''import des coûts pour la responsabilité ' ||
                                           v_tmp.responsibility_key ||
                                           ' : ' || g_request_id || ':' ||
                                           v_tmp.org_name);
      
        --********************************************
        -- Wait for the concurrent program to complete
        --********************************************
        IF NOT (fnd_concurrent.wait_for_request(g_request_id,
                                                20,
                                                0,
                                                v_phase,
                                                v_status,
                                                v_dev_phase,
                                                v_dev_status,
                                                v_message)) THEN
        
          pv_errbuf := v_message;
          dka_tools_pkg.put_log_message('ERREUR : Attente de la fin du programme dépassée : Fin du traitement' ||
                                        chr(10) || 'MESSAGE : ' ||
                                        v_message || chr(10));
        END IF;
      
        IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
        
          dka_tools_pkg.put_log_message('Request id :' || g_request_id ||
                                        'COMPLETION= ' || v_dev_phase || '/' ||
                                        v_dev_status);
          dka_tools_pkg.put_outdebug_message('Statut de fin : ' || v_phase || '/' ||
                                             v_status);
        
        ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
          dka_tools_pkg.put_log_message('Request id :' || g_request_id ||
                                        'COMPLETION= ' || v_dev_phase || '/' ||
                                        v_dev_status);
          dka_tools_pkg.put_outdebug_message('Fin du traitement standard d''import des coûts en WARNING. ' ||
                                             g_request_id);
          v_message  := 'ERREUR : Fin du traitement en WARNING : ' ||
                        v_message;
          pn_retcode := 1;
        ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
        
          pn_retcode := 2;
          pv_errbuf  := 'ERREUR : Fin anormale du traitement standard d''import des coûts';
          dka_tools_pkg.put_outdebug_message('ERREUR : Fin anormale du traitement ');
          dka_tools_pkg.put_log_message(g_request_id || chr(10) ||
                                        'Phase/Statut : ' || v_dev_phase || '/' ||
                                        v_dev_status || chr(10) ||
                                        'MESSAGE : ' || v_message ||
                                        chr(10));
        END IF;
      END IF;
    END LOOP;
  
    FOR rec_dka IN cur_dka LOOP
      UPDATE dka.dka_fa_projet_cout dka
         SET statut        = gv_statut_ko,
             error_message = rec_dka.transaction_rejection_code
       WHERE ROWID = rec_dka.rid;
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Exception déclenchée lors du lancement du traitement standard PAXTRTRX: ' ||
                    SQLERRM;
      dka_tools_pkg.put_log_message(to_char(SYSDATE,
                                            'DD/MM/YYYY HH24:MI:SS') ||
                                    ' - ' ||
                                    'Fin de la procédure program_import_couts : EXCEPTION OTHERS ');
  END program_import_couts;

  /*
   *************************************************************************
   * PROCEDURE NAME : Wait_request
   *
   * DESCRIPTION
   *  Attente de la fin du traitement
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE wait_request(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
    v_phase      VARCHAR2(100);
    v_status     VARCHAR2(100);
    v_dev_phase  VARCHAR2(100);
    v_dev_status VARCHAR2(100);
    v_message    VARCHAR2(500);
    --v_nb_ok      NUMBER;
    --v_nb_rejet         NUMBER;
  
    i BINARY_INTEGER;
  
  BEGIN
    fnd_file.put_line(fnd_file.log, 'DEBUT wait_request');
    i := g_tab_requests.first;
    WHILE i IS NOT NULL LOOP
    
      IF NOT fnd_concurrent.wait_for_request(g_tab_requests(i),
                                             2,
                                             0,
                                             v_phase,
                                             v_status,
                                             v_dev_phase,
                                             v_dev_status,
                                             v_message) THEN
        p_errbuf := v_message;
        fnd_file.put_line(fnd_file.output,
                          'ERREUR : Attente de la fin du programme dépassée : Fin du traitement' ||
                          chr(10) || 'MESSAGE : ' || v_message || chr(10));
      END IF;
    
      IF v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL' THEN
      
        fnd_file.put_line(fnd_file.output,
                          'COMPLETION= ' || v_dev_phase || '/' ||
                          v_dev_status);
      
      ELSIF v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING' THEN
      
        fnd_file.put_line(fnd_file.output,
                          'Fin du traitement en warning ' ||
                          g_tab_requests(i));
        v_message := 'ERREUR : Fin du traitement en warning: ' || v_message;
        p_retcode := 1;
      
      ELSIF v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL' THEN
      
        p_retcode := 2;
        v_message := 'ERREUR : Fin anormale du traitement : ' || v_message;
      
        fnd_file.put_line(fnd_file.output,
                          'ERREUR : Fin anormale du traitement ' ||
                          g_tab_requests(i) || chr(10) || 'Phase/Statut : ' ||
                          v_dev_phase || '/' || v_dev_status || chr(10) ||
                          'MESSAGE : ' || v_message || chr(10));
        --Fnd_File.put_line (Fnd_File.LOG, '===> ERREUR : Fin anormale du traitement '||g_import_request_id);
      END IF;
    
      p_errbuf := v_message;
      i        := g_tab_requests.next(i);
    END LOOP;
  
  END wait_request;

  ------------------------------------------------------------------------------------
  -- Nom              : Main_export
  -- Description      : Procédure principale du traitement
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
  PROCEDURE main_export(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
    CURSOR cur_soc IS
      SELECT dsl.param1_value soc_from,
             substr(dsl.param1_value, 4) cod_soc_from,
             dsl.return_value soc_to,
             substr(dsl.return_value, 4) cod_soc_to,
             trunc(dsl.start_date, 'MONTH') - 1 date_fusion
        FROM dka_stransco_lines dsl, dka_stransco_headers dsh
       WHERE dsh.set_name = g_transco
         AND dsl.set_id = dsh.set_id
         AND nvl(dsl.enable, 'N') = 'Y';
  
    CURSOR cur_livre_data(pv_soc_absorbee   VARCHAR2,
                          pv_soc_absorbante VARCHAR2) IS
      SELECT fad.asset_number numero_immobilisation,
             fad.description libelle_immo,
             fbc.book_type_code,
             fac.segment1 rub_principale,
             fac.segment2 rub_detail,
             fac.segment3 methode_amt,
             fac.segment4 plafond_amt,
             fad.current_units unites,
             substr(pv_soc_absorbante, 4) societe,
             fl.segment2 lieu_physique,
             gcc_dotation.segment1 d_societe_seg,
             gcc_dotation.segment2 d_uo_seg,
             substr(pv_soc_absorbante, 4) d_societe,
             substr(pv_soc_absorbante, 1, 3) d_uo,
             gcc_dotation.segment3 d_compte_local,
             gcc_dotation.segment4 d_compte_analytique,
             gcc_dotation.segment5 d_interco,
             gcc_dotation.segment6 d_centre_fi,
             gcc_dotation.segment7 d_affaire,
             gcc_dotation.segment8 d_projet_fi,
             gcc_dotation.segment9 d_flux,
             gcc_dotation.segment10 d_reserve2,
             gcc_lettrage.segment1 l_societe_seg,
             gcc_lettrage.segment2 l_uo_seg,
             substr(pv_soc_absorbante, 4) l_societe,
             substr(pv_soc_absorbante, 1, 3) l_uo,
             gcc_lettrage.segment3 l_compte_local,
             gcc_lettrage.segment4 l_compte_analytique,
             gcc_lettrage.segment5 l_interco,
             gcc_lettrage.segment6 l_centre_fi,
             gcc_lettrage.segment7 l_affaire,
             gcc_lettrage.segment8 l_projet_fi,
             gcc_lettrage.segment9 l_flux,
             gcc_lettrage.segment10 l_reserve2,
             fb.date_placed_in_service date_de_mise_en_service,
             fad.asset_number numero_immo,
             decode(fad.in_use_flag, 'YES', 'Oui', 'Non') utilise,
             decode(fad.owned_leased,
                    'OWNED',
                    'En propriété',
                    'En crédit-bail') propriete,
             decode(fad.new_used, 'NEW', 'Neuf', 'D''occasion') achete,
             fakk.segment1 taxe_prof,
             fakk.segment2 impot_foncier,
             apps.dka_sfa_fusion_societe_pkg.xxfa_accytddeprn_get_fnc(fb.asset_id,
                                                                      fbc.book_type_code,
                                                                      'DEPRN') amortissement_cumule,
             apps.dka_sfa_fusion_societe_pkg.xxfa_accytddeprn_get_fnc(fb.asset_id,
                                                                      fbc.book_type_code,
                                                                      'YTD') amortissement_exercice,
             fb.deprn_start_date date_deb_amort,
             fb.deprn_method_code type_amortissement,
             fb.life_in_months duree_amortissement,
             fb.asset_id asset_id,
             SUM(fadd.cost) cost,
             --fai.project,
             --fai.task_number,
             fb.depreciate_flag amortir,
             substr(pv_soc_absorbante, 4) || ' ' ||
             decode(fbc.book_class, 'CORPORATE', 'SOCIAL', 'IFRS') livre_fa,
             pv_soc_absorbee societe_absorbee,
             (SELECT DISTINCT ppa.segment1 project
                FROM fa_asset_invoices fai, pa_projects_all ppa, pa_tasks pt
               WHERE fai.project_id = ppa.project_id
                 AND fai.task_id = pt.task_id
                 AND fai.asset_id = fb.asset_id) project,
             (SELECT DISTINCT pt.task_number
                FROM fa_asset_invoices fai, pa_projects_all ppa, pa_tasks pt
               WHERE fai.project_id = ppa.project_id
                 AND fai.task_id = pt.task_id
                 AND fai.asset_id = fb.asset_id) task_number
        FROM fa_book_controls         fbc,
             fa_books                 fb,
             fa_distribution_history  fdh,
             fa_asset_history         fah,
             fa_additions             fad,
             fa_categories            fac,
             fa_locations             fl,
             fa_distribution_accounts fda,
             gl_code_combinations     gcc_dotation,
             gl_code_combinations     gcc_lettrage,
             fa_deprn_detail          fadd,
             fa_asset_keywords_kfv    fakk
       WHERE 1 = 1
         AND fbc.book_class IN ('CORPORATE', 'TAX')
         AND trunc(nvl(fbc.date_ineffective, SYSDATE)) >= trunc(SYSDATE)
            --
         AND fb.book_type_code = fbc.book_type_code
         AND fb.date_effective =
             (SELECT MAX(fb2.date_effective) -- Enregistrement actif au dernier calcul d'amortissement du livre
                FROM fa_books fb2
               WHERE fb2.asset_id = fb.asset_id
                 AND fb2.book_type_code = fb.book_type_code
                 AND fb2.date_effective <=
                     (SELECT MAX(fdp.period_close_date)
                        FROM fa_deprn_periods fdp
                       WHERE fdp.book_type_code = fb.book_type_code
                         AND fdp.period_close_date IS NOT NULL))
         AND fb.transaction_header_id_in =
             (SELECT MAX(fb2.transaction_header_id_in)
                FROM fa_books fb2
               WHERE fb2.asset_id = fb.asset_id
                 AND fb2.book_type_code = fb.book_type_code
                 AND fb2.date_effective = fb.date_effective)
         AND fb.period_counter_fully_retired IS NULL -- Immo non completement cedee
            --
         AND fdh.asset_id = fb.asset_id -- Ligne active au dernier calcul d'amortissement du livre
         AND fdh.date_effective <=
             (SELECT MAX(fdp.period_close_date)
                FROM fa_deprn_periods fdp
               WHERE fdp.book_type_code = fdh.book_type_code
                 AND fdp.period_close_date IS NOT NULL)
            --
         AND fah.asset_id = fb.asset_id
         AND fah.date_effective =
             (SELECT MAX(fah2.date_effective) -- Enregistrement actif au dernier calcul d'amortissement du livre
                FROM fa_asset_history fah2
               WHERE fah2.asset_id = fb.asset_id
                 AND fah2.date_effective <=
                     (SELECT MAX(fdp.period_close_date)
                        FROM fa_deprn_periods fdp
                       WHERE fdp.book_type_code = fb.book_type_code
                         AND fdp.period_close_date IS NOT NULL))
            --
         AND fad.asset_id = fb.asset_id
         AND fad.asset_type = 'CAPITALIZED'
            --AND fai.project_id = ppa.project_id
            --AND fai.task_id = pt.task_id
            --
         AND fac.category_id = fah.category_id
            --
         AND fl.location_id = fdh.location_id
            --
         AND fda.distribution_id = fdh.distribution_id
         AND fda.book_type_code = fdh.book_type_code
            --
         AND gcc_dotation.code_combination_id =
             fda.deprn_expense_account_ccid
         AND gcc_dotation.segment2 || gcc_dotation.segment1 =
             pv_soc_absorbee
            --
         AND gcc_lettrage.code_combination_id = fda.asset_cost_account_ccid --Fda.Asset_Clearing_Account_Ccid ??? compte de lettragge ???
         AND gcc_lettrage.segment2 || gcc_lettrage.segment1 =
             pv_soc_absorbee
            --
         AND fadd.book_type_code = fb.book_type_code
         AND fadd.distribution_id = fdh.distribution_id
         AND fadd.period_counter =
             (SELECT MAX(fadd2.period_counter)
                FROM fa_deprn_detail fadd2
               WHERE fadd2.book_type_code = fb.book_type_code
                 AND fadd2.distribution_id = fdh.distribution_id)
            --
         AND fakk.code_combination_id = fad.asset_key_ccid
            --
            --
         AND (fbc.book_class != 'CORPORATE' OR
             (fbc.book_class = 'CORPORATE' AND
             fda.book_type_code NOT LIKE '%FISCAL%'))
         AND fdh.date_ineffective IS NULL
         AND fb.asset_id NOT IN
             (SELECT fr.asset_id
                FROM fa.fa_retirements fr
               WHERE fr.asset_id = fb.asset_id
                 AND (fr.status = 'PROCESSED' AND
                     fr.retirement_type_code != 'PARTIELLE'))
      --   AND fai.asset_id = fad.asset_id
       GROUP BY fad.description,
                fbc.book_type_code,
                fac.segment1,
                fac.segment2,
                fac.segment3,
                fac.segment4,
                fad.current_units,
                fl.segment1,
                fl.segment2,
                gcc_dotation.segment1,
                gcc_dotation.segment2,
                gcc_dotation.segment3,
                gcc_dotation.segment4,
                gcc_dotation.segment5,
                gcc_dotation.segment6,
                gcc_dotation.segment7,
                gcc_dotation.segment8,
                gcc_dotation.segment9,
                gcc_dotation.segment10,
                gcc_lettrage.segment1,
                gcc_lettrage.segment2,
                gcc_lettrage.segment3,
                gcc_lettrage.segment4,
                gcc_lettrage.segment5,
                gcc_lettrage.segment6,
                gcc_lettrage.segment7,
                gcc_lettrage.segment8,
                gcc_lettrage.segment9,
                gcc_lettrage.segment10,
                fb.date_placed_in_service,
                fad.asset_number,
                decode(fad.in_use_flag, 'YES', 'Oui', 'Non'),
                decode(fad.owned_leased,
                       'OWNED',
                       'En propriété',
                       'En crédit-bail'),
                decode(fad.new_used, 'NEW', 'Neuf', 'D''occasion'),
                fakk.segment1,
                fakk.segment2,
                fb.deprn_start_date,
                fb.deprn_method_code,
                fb.life_in_months,
                fb.asset_id,
                --fai.project,
                --fai.task_number,
                fb.depreciate_flag,
                decode(fbc.book_class, 'CORPORATE', 'SOCIAL', 'IFRS')
       ORDER BY fad.asset_number;
  
    v_compteur_export_liv_soc NUMBER;
    l_count                   NUMBER;
  
    -- fichiers de sortie
  
    p_fic_out_ptr  utl_file.file_type;
    p_dir_out      VARCHAR2(120);
    p_fic_out_name VARCHAR2(80);
  
    TYPE assets IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    assets_list assets;
  
    v_cpt   INTEGER := 0;
    v_sep   VARCHAR2(1) := '|';
    v_cat_1 VARCHAR2(50);
    v_cat_2 VARCHAR2(50);
    v_cat_3 VARCHAR2(50);
    v_cat_4 VARCHAR2(50);
  
    v_cpt_dot1  VARCHAR2(10);
    v_cpt_dot2  VARCHAR2(10);
    v_cpt_dot3  VARCHAR2(10);
    v_cpt_dot4  VARCHAR2(10);
    v_cpt_dot5  VARCHAR2(10);
    v_cpt_dot6  VARCHAR2(10);
    v_cpt_dot7  VARCHAR2(10);
    v_cpt_dot8  VARCHAR2(10);
    v_cpt_dot9  VARCHAR2(10);
    v_cpt_dot10 VARCHAR2(10);
    v_cpt_dot11 VARCHAR2(10);
    v_cpt_dot12 VARCHAR2(10);
  
    v_cpt_let1  VARCHAR2(10);
    v_cpt_let2  VARCHAR2(10);
    v_cpt_let3  VARCHAR2(10);
    v_cpt_let4  VARCHAR2(10);
    v_cpt_let5  VARCHAR2(10);
    v_cpt_let6  VARCHAR2(10);
    v_cpt_let7  VARCHAR2(10);
    v_cpt_let8  VARCHAR2(10);
    v_cpt_let9  VARCHAR2(10);
    v_cpt_let10 VARCHAR2(10);
    v_cpt_let11 VARCHAR2(10);
    v_cpt_let12 VARCHAR2(10);
  
    v_compteur_proj NUMBER;
    v_compteur_cout NUMBER;
  
    v_amortir VARCHAR2(10);
    l_step    VARCHAR2(50);
  
    v_date_jour VARCHAR2(20) := to_char(SYSDATE, 'RRMMDDHH24MI');
  
  BEGIN
  
    p_errbuf  := NULL;
    p_retcode := 0;
  
    l_step := 'DEBUT';
  
    -- Initialisation des compteurs
    v_compteur_export_liv_soc := 0;
  
    -- Ouverture fichier de sortie
    p_fic_out_name := 'IMMO_FUSION_PAS' || '.csv';
    p_dir_out      := 'DKA_OUT_DIR';
  
    dka_tools_pkg.put_outdebug_message('----------------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('    Log des traitements DKA                                          : Extraction pour reprise des immobilisations');
    dka_tools_pkg.put_outdebug_message('    Fichier de sortie de l''extraction du livre social et fiscal     : ' ||
                                       p_fic_out_name);
    dka_tools_pkg.put_outdebug_message('    Date et Heure                                                    : ' ||
                                       to_char(SYSDATE,
                                               'DD-MON-YYYY HH24:MI:SS'));
    dka_tools_pkg.put_outdebug_message('-----------------:------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('');
  
    l_step := 'OUVERTURE';
  
    -- 1. Livre social   
    --p_fic_out_ptr := utl_file.fopen(p_dir_out, p_fic_out_name, 'W', 32764);
    -- Ecriture des noms de colonnes dans le fichier du livre social
  
    dka_tools_pkg.put_outdebug_message(
                                       --utl_file.put_line(p_fic_out_ptr,
                                       'Libelle_Immo' || v_sep ||
                                       'RUB PRINCIPALE' || v_sep ||
                                       'RUB DETAIL' || v_sep ||
                                       'METHODE AMT' || v_sep ||
                                       'PLAFOND AMT' || v_sep || 'Unites' ||
                                       v_sep || 'Cost' || v_sep ||
                                       'Societe' || v_sep ||
                                       'Lieu physique' || v_sep ||
                                       'D_Societe' || v_sep || 'D_UO' ||
                                       v_sep || 'D_COMPTE_LOCAL' || v_sep ||
                                       'D_COMPTE_ANALYTIQUE' || v_sep ||
                                       'D_INTERCO' || v_sep ||
                                       'D_CENTRE_FI' || v_sep ||
                                       'D_AFFAIRE' || v_sep ||
                                       'D_PROJET_FI' || v_sep || 'D_FLUX' ||
                                       v_sep || 'D_RESERVE1' || v_sep ||
                                       'D_RESERVE2' || v_sep ||
                                       'D_RESERVE3' || v_sep || 'L_Societe' ||
                                       v_sep || 'L_UO' || v_sep ||
                                       'L_COMPTE_LOCAL' || v_sep ||
                                       'L_COMPTE_ANALYTIQUE' || v_sep ||
                                       'L_INTERCO' || v_sep ||
                                       'L_CENTRE_FI' || v_sep ||
                                       'L_AFFAIRE' || v_sep ||
                                       'L_PROJET_FI' || v_sep || 'L_FLUX' ||
                                       v_sep || 'L_RESERVE1' || v_sep ||
                                       'L_RESERVE2' || v_sep ||
                                       'L_RESERVE3' || v_sep ||
                                       'Date de mise en service' || v_sep ||
                                       'Numero immobilisation' || v_sep ||
                                       'Utilise' || v_sep || 'Propriete' ||
                                       v_sep || 'Achete' || v_sep ||
                                       'TAXE PROF' || v_sep ||
                                       'IMPOT FONCIER' || v_sep ||
                                       'Amortir' || v_sep ||
                                       'Amortissement cumule' || v_sep ||
                                       'Amortissement exercice' || v_sep ||
                                       'Date de début de l''amortissement' ||
                                       v_sep || 'Méthode d''amortissement' ||
                                       v_sep || 'Durée de vie en mois' ||
                                       v_sep || 'Projet' || v_sep ||
                                       'Tache' || v_sep || 'Soc_Absorbee' ||
                                       v_sep || 'Livre_FA');
  
    -- Ecriture des enregistrements dans le fichier du livre social
    fnd_file.put_line(fnd_file.log,
                      'Ecriture des enregistrements dans le fichier du livre social et fiscal');
  
    l_step := 'BOUCLE';
  
    SELECT COUNT(1) INTO l_count FROM dka.dka_fa_fusion_immo;
  
    IF l_count > 0 THEN
      EXECUTE IMMEDIATE 'create table dka.dka_fa_fusion_immo_' ||
                        v_date_jour || ' as
              select * from dka.dka_fa_fusion_immo';
      DELETE FROM dka.dka_fa_fusion_immo;
    END IF;
  
    FOR rec_soc IN cur_soc LOOP
      FOR lig_livsoc IN cur_livre_data(rec_soc.soc_from, rec_soc.soc_to) LOOP
        BEGIN
          v_cpt := v_cpt + 1;
          assets_list(v_cpt) := lig_livsoc.asset_id;
        
          v_cat_1 := lig_livsoc.rub_principale;
          v_cat_2 := lig_livsoc.rub_detail;
          v_cat_3 := lig_livsoc.methode_amt;
          v_cat_4 := lig_livsoc.plafond_amt;
        
          -- 04/04/17 - NBO - artf2129974 - REP009 - Export - Champ amortir à oui alors que non coché en 11i
          -- Calcul du champ amortir
          IF lig_livsoc.amortir = 'NO' OR
             lig_livsoc.duree_amortissement = 0 OR v_cat_3 = 'NA' THEN
            v_amortir := 'Non';
          ELSE
            v_amortir := 'Oui';
          END IF;
        
          v_cpt_dot1  := lig_livsoc.d_societe;
          v_cpt_dot2  := lig_livsoc.d_uo;
          v_cpt_dot3  := lig_livsoc.d_compte_local;
          v_cpt_dot4  := lig_livsoc.d_compte_analytique;
          v_cpt_dot5  := lig_livsoc.d_interco;
          v_cpt_dot6  := lig_livsoc.d_centre_fi;
          v_cpt_dot7  := lig_livsoc.d_affaire;
          v_cpt_dot8  := '0';
          v_cpt_dot9  := lig_livsoc.d_flux;
          v_cpt_dot10 := '0';
          v_cpt_dot11 := '0';
          v_cpt_dot12 := '0';
        
          v_cpt_let1  := lig_livsoc.l_societe;
          v_cpt_let2  := lig_livsoc.l_uo;
          v_cpt_let3  := lig_livsoc.l_compte_local;
          v_cpt_let4  := lig_livsoc.l_compte_analytique;
          v_cpt_let5  := lig_livsoc.l_interco;
          v_cpt_let6  := lig_livsoc.l_centre_fi;
          v_cpt_let7  := lig_livsoc.l_affaire;
          v_cpt_let8  := '0';
          v_cpt_let9  := lig_livsoc.l_flux;
          v_cpt_let10 := '0';
          v_cpt_let11 := '0';
          v_cpt_let12 := '0';
        
          l_step := 'ECRITURE';
        
          -- Ecriture dans le fichier
          dka_tools_pkg.put_outdebug_message(
                                             --utl_file.put_line(p_fic_out_ptr,
                                             lig_livsoc.numero_immobilisation ||
                                             v_sep ||
                                             lig_livsoc.libelle_immo ||
                                             v_sep || v_cat_1 || v_sep ||
                                             v_cat_2 || v_sep || v_cat_3 ||
                                             v_sep || v_cat_4 || v_sep ||
                                             lig_livsoc.unites || v_sep ||
                                             TRIM(to_char(lig_livsoc.cost,
                                                          '999999999999999999999D00') ||
                                                  v_sep ||
                                                  lig_livsoc.societe ||
                                                  v_sep ||
                                                  lig_livsoc.lieu_physique ||
                                                  v_sep || v_cpt_dot1 ||
                                                  v_sep || v_cpt_dot2 ||
                                                  v_sep || v_cpt_dot3 ||
                                                  v_sep || v_cpt_dot4 ||
                                                  v_sep || v_cpt_dot5 ||
                                                  v_sep || v_cpt_dot6 ||
                                                  v_sep || v_cpt_dot7 ||
                                                  v_sep || v_cpt_dot8 ||
                                                  v_sep || v_cpt_dot9 ||
                                                  v_sep || v_cpt_dot10 ||
                                                  v_sep || v_cpt_dot11 ||
                                                  v_sep || v_cpt_dot12 ||
                                                  v_sep || v_cpt_let1 ||
                                                  v_sep || v_cpt_let2 ||
                                                  v_sep || v_cpt_let3 ||
                                                  v_sep || v_cpt_let4 ||
                                                  v_sep || v_cpt_let5 ||
                                                  v_sep || v_cpt_let6 ||
                                                  v_sep || v_cpt_let7 ||
                                                  v_sep || v_cpt_let8 ||
                                                  v_sep || v_cpt_let9 ||
                                                  v_sep || v_cpt_let10 ||
                                                  v_sep || v_cpt_let11 ||
                                                  v_sep || v_cpt_let12 ||
                                                  v_sep ||
                                                  to_char(lig_livsoc.date_de_mise_en_service,
                                                          'YYYY/MM/DD') ||
                                                  v_sep ||
                                                  lig_livsoc.numero_immo ||
                                                  v_sep ||
                                                  lig_livsoc.utilise ||
                                                  v_sep ||
                                                  lig_livsoc.propriete ||
                                                  v_sep ||
                                                  lig_livsoc.achete ||
                                                  v_sep ||
                                                  lig_livsoc.taxe_prof ||
                                                  v_sep ||
                                                  lig_livsoc.impot_foncier ||
                                                  v_sep || v_amortir ||
                                                  v_sep ||
                                                  TRIM(to_char(lig_livsoc.amortissement_cumule,
                                                               '999999999999999999999D00')) ||
                                                  v_sep ||
                                                  TRIM(to_char(lig_livsoc.amortissement_exercice,
                                                               '999999999999999999999D00')) ||
                                                  v_sep ||
                                                  to_char(lig_livsoc.date_deb_amort,
                                                          'YYYY/MM/DD') ||
                                                  v_sep ||
                                                  lig_livsoc.type_amortissement ||
                                                  v_sep ||
                                                  lig_livsoc.duree_amortissement ||
                                                  v_sep ||
                                                  lig_livsoc.project ||
                                                  v_sep ||
                                                  lig_livsoc.task_number ||
                                                  v_sep || rec_soc.soc_from ||
                                                  v_sep ||
                                                  lig_livsoc.livre_fa));
        
          INSERT INTO dka.dka_fa_fusion_immo
            (numero_immobilisation,
             libelle_immo,
             book_type_code,
             rub_principale,
             rub_detail,
             methode_amt,
             plafond_amt,
             unites,
             societe,
             lieu_physique,
             d_societe_seg,
             d_uo_seg,
             d_compte_local,
             d_compte_analytique,
             d_interco,
             d_centre_fi,
             d_affaire,
             d_projet_fi,
             d_flux,
             d_reserve2,
             l_societe_seg,
             l_uo_seg,
             l_compte_local,
             l_compte_analytique,
             l_interco,
             l_centre_fi,
             l_affaire,
             l_projet_fi,
             l_flux,
             l_reserve2,
             date_de_mise_en_service,
             numero_immo,
             utilise,
             propriete,
             achete,
             taxe_prof,
             impot_foncier,
             amortissement_cumule,
             amortissement_exercice,
             date_deb_amort,
             type_amortissement,
             duree_amortissement,
             asset_id,
             cost,
             project,
             task_number,
             amortir,
             livre_fa,
             statut,
             societe_absorbee)
          VALUES
            (lig_livsoc.numero_immobilisation,
             lig_livsoc.libelle_immo,
             lig_livsoc.book_type_code,
             lig_livsoc.rub_principale,
             lig_livsoc.rub_detail,
             lig_livsoc.methode_amt,
             lig_livsoc.plafond_amt,
             lig_livsoc.unites,
             lig_livsoc.societe,
             lig_livsoc.lieu_physique,
             lig_livsoc.d_societe,
             lig_livsoc.d_uo,
             lig_livsoc.d_compte_local,
             lig_livsoc.d_compte_analytique,
             lig_livsoc.d_interco,
             lig_livsoc.d_centre_fi,
             lig_livsoc.d_affaire,
             lig_livsoc.d_projet_fi,
             lig_livsoc.d_flux,
             lig_livsoc.d_reserve2,
             lig_livsoc.l_societe,
             lig_livsoc.l_uo,
             lig_livsoc.l_compte_local,
             lig_livsoc.l_compte_analytique,
             lig_livsoc.l_interco,
             lig_livsoc.l_centre_fi,
             lig_livsoc.l_affaire,
             lig_livsoc.l_projet_fi,
             lig_livsoc.l_flux,
             lig_livsoc.l_reserve2,
             lig_livsoc.date_de_mise_en_service,
             lig_livsoc.numero_immo,
             lig_livsoc.utilise,
             lig_livsoc.propriete,
             lig_livsoc.achete,
             lig_livsoc.taxe_prof,
             lig_livsoc.impot_foncier,
             lig_livsoc.amortissement_cumule,
             lig_livsoc.amortissement_exercice,
             lig_livsoc.date_deb_amort,
             lig_livsoc.type_amortissement,
             lig_livsoc.duree_amortissement,
             lig_livsoc.asset_id,
             lig_livsoc.cost,
             lig_livsoc.project,
             lig_livsoc.task_number,
             lig_livsoc.amortir,
             lig_livsoc.livre_fa,
             gv_statut_new,
             lig_livsoc.societe_absorbee);
        
          -- Mise à jour du compteur
          v_compteur_export_liv_soc := v_compteur_export_liv_soc + 1;
        
        EXCEPTION
          WHEN OTHERS THEN
            dka_tools_pkg.put_debug_message('--> Code erreur ' || SQLCODE ||
                                            ' - ' || SQLERRM);
            p_retcode := 1;
        END;
      
      END LOOP; /* lig_livsoc IN cur_livre_Data */
    
    END LOOP;
  
    l_step := 'FIN';
  
    --utl_file.fclose(file => p_fic_out_ptr);
  
    -- Log du nombre d'enregistrements
    dka_tools_pkg.put_outdebug_message('Nombre de lignes d''immos du livre social et fiscal                          : ' ||
                                       v_compteur_export_liv_soc);
  
    SELECT COUNT(1) INTO l_count FROM dka.dka_fa_projet_ferme;
  
    IF l_count > 0 THEN
      EXECUTE IMMEDIATE 'create table dka.dka_fa_projet_ferme_' ||
                        v_date_jour || ' as
              select * from dka.dka_fa_projet_ferme';
      DELETE FROM dka.dka_fa_projet_ferme;
    END IF;
  
    v_compteur_proj := 0;
    FOR rec_proj_tache IN cur_proj_tache_ferme LOOP
      INSERT INTO dka.dka_fa_projet_ferme
        (org_name,
         project_status_name,
         project_code,
         ppa_completion_date,
         closed_date,
         task_name,
         task_number,
         categorie_name,
         tache_parent,
         pt_libelle,
         pt_start_date,
         pt_completion_date,
         org_name2,
         libelle,
         project_type,
         affaire,
         destination,
         filiere,
         activite,
         start_date,
         org_absorbante,
         statut,
         modele)
      VALUES
        (rec_proj_tache.org_name,
         rec_proj_tache.project_status_name,
         rec_proj_tache.project_code,
         rec_proj_tache.ppa_completion_date,
         rec_proj_tache.closed_date,
         rec_proj_tache.task_name,
         rec_proj_tache.task_number,
         rec_proj_tache.categorie_name,
         rec_proj_tache.tache_parent,
         rec_proj_tache.pt_libelle,
         rec_proj_tache.pt_start_date,
         rec_proj_tache.pt_completion_date,
         rec_proj_tache.org_name2,
         rec_proj_tache.libelle,
         rec_proj_tache.project_type,
         rec_proj_tache.affaire,
         rec_proj_tache.destination,
         rec_proj_tache.filiere,
         rec_proj_tache.activite,
         rec_proj_tache.start_date,
         rec_proj_tache.org_absorbante,
         'NEW',
         rec_proj_tache.modele);
    
      v_compteur_proj := v_compteur_proj + 1;
    END LOOP;
  
    -- Insere les projets parents des projets d'immo
    FOR rec_proj_tache IN cur_proj_tache_ferme_parent LOOP
      INSERT INTO dka.dka_fa_projet_ferme
        (org_name,
         project_status_name,
         project_code,
         ppa_completion_date,
         closed_date,
         task_name,
         task_number,
         categorie_name,
         tache_parent,
         pt_libelle,
         pt_start_date,
         pt_completion_date,
         org_name2,
         libelle,
         project_type,
         affaire,
         destination,
         filiere,
         activite,
         start_date,
         org_absorbante,
         statut,
         modele)
      VALUES
        (rec_proj_tache.org_name,
         rec_proj_tache.project_status_name,
         rec_proj_tache.project_code,
         rec_proj_tache.ppa_completion_date,
         rec_proj_tache.closed_date,
         rec_proj_tache.task_name,
         rec_proj_tache.task_number,
         rec_proj_tache.categorie_name,
         rec_proj_tache.tache_parent,
         rec_proj_tache.pt_libelle,
         rec_proj_tache.pt_start_date,
         rec_proj_tache.pt_completion_date,
         rec_proj_tache.org_name2,
         rec_proj_tache.libelle,
         rec_proj_tache.project_type,
         rec_proj_tache.affaire,
         rec_proj_tache.destination,
         rec_proj_tache.filiere,
         rec_proj_tache.activite,
         rec_proj_tache.start_date,
         rec_proj_tache.org_absorbante,
         'NEW',
         rec_proj_tache.modele);
    
      v_compteur_proj := v_compteur_proj + 1;
    END LOOP;
  
    dka_tools_pkg.put_outdebug_message('');
    dka_tools_pkg.put_outdebug_message('Nombre de lignes projet a créer : ' ||
                                       v_compteur_proj);
  
    SELECT COUNT(1) INTO l_count FROM dka.dka_fa_projet_cout;
  
    IF l_count > 0 THEN
      EXECUTE IMMEDIATE 'create table dka.dka_fa_projet_cout_' ||
                        v_date_jour || ' as
              select * from dka.dka_fa_projet_cout';
      DELETE FROM dka.dka_fa_projet_cout;
    END IF;
  
    v_compteur_cout := 0;
  
    FOR rec_soc IN cur_soc_fusion_org LOOP
    
      FOR rec_proj_tache IN cur_proj_tache_cout(rec_soc.org_id_from,
                                                rec_soc.org_id_to) LOOP
        INSERT INTO dka.dka_fa_projet_cout
          (trans_id,
           project,
           task,
           tx_src,
           exp_date,
           creation_date,
           raw_cost,
           quantity,
           burden_cost,
           expenditure_type,
           org_id,
           org_id_absorbante,
           dr_code_combination_id,
           org_depense,
           statut)
        VALUES
          (rec_proj_tache.trans_id,
           rec_proj_tache.project,
           rec_proj_tache.task,
           rec_proj_tache.tx_src,
           rec_proj_tache.exp_date,
           rec_proj_tache.creation_date,
           rec_proj_tache.raw_cost,
           rec_proj_tache.quantity,
           rec_proj_tache.burden_cost,
           rec_proj_tache.expenditure_type,
           rec_proj_tache.org_id,
           rec_proj_tache.org_id_absorbante,
           rec_proj_tache.dr_code_combination_id,
           rec_proj_tache.org_depense,
           'NEW');
        v_compteur_cout := v_compteur_cout + 1;
      END LOOP;
    END LOOP;
  
    dka_tools_pkg.put_outdebug_message('Nombre de lignes de cout a créer : ' ||
                                       v_compteur_cout);
  
    dka_tools_pkg.put_outdebug_message('');
    dka_tools_pkg.put_outdebug_message('-----------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('Fin des logs de traitements DKA : Extraction pour reprise des immobilisations');
    dka_tools_pkg.put_outdebug_message('-----------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('');
  
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      p_errbuf  := 'Erreur dans la procécure Main : ' || l_step || ' : ' ||
                   SQLCODE || '-' || substr(SQLERRM, 1, 1000);
      p_retcode := 2;
    
      dka_tools_pkg.put_outdebug_message(' ');
      dka_tools_pkg.put_outdebug_message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      dka_tools_pkg.put_outdebug_message('=> TRAITEMENT TERMINE EN ERREUR');
      dka_tools_pkg.put_outdebug_message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      dka_tools_pkg.put_outdebug_message(p_errbuf);
  END main_export;

  ------------------------------------------------------------------------------------
  -- Nom              : Main_import
  -- Description      : Procédure principale du traitement
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
  PROCEDURE main_import(p_errbuf          OUT VARCHAR2,
                        p_retcode         OUT NUMBER,
                        p_mode_simulation IN VARCHAR2) IS
    l_step               VARCHAR2(50);
    ld_end_period        DATE;
    ln_sequence          NUMBER;
    v_original_trans_ref VARCHAR2(150);
    vn_org_id            NUMBER;
    vv_ou                VARCHAR2(30);
    vv_ou_absorbe        VARCHAR2(30);
    l_seg1               VARCHAR2(100);
    l_seg2               VARCHAR2(100);
    l_seg3               VARCHAR2(100);
    l_seg4               VARCHAR2(100);
    l_seg5               VARCHAR2(100);
    l_seg6               VARCHAR2(100);
    l_seg7               VARCHAR2(100);
    l_seg8               VARCHAR2(100);
    l_seg9               VARCHAR2(100);
    l_seg10              VARCHAR2(100);
    l_errbuf             VARCHAR2(100);
    l_retcode            NUMBER;
    l_count              NUMBER;
    vn_ccid              NUMBER;
    vn_ccid2             NUMBER;
    vv_errbuf_ccid       VARCHAR2(200);
    vn_retcode_ccid      NUMBER;
    vv_enabled_flag      VARCHAR2(100);
    vd_start_date_active DATE;
    vd_end_date_active   DATE;
  BEGIN
    l_step := 'DEBUT';
  
    dka_tools_pkg.put_outdebug_message('----------------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('    Log des traitements DKA                                          : Import pour fusion des immobilisations');
    dka_tools_pkg.put_outdebug_message('-----------------:------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('');
  
    dka_tools_pkg.put_outdebug_message('Liste les projets et tache à créer :');
    dka_tools_pkg.put_outdebug_message('Nom Org | Project status Name | Project Name | Completion Date | Date de fermeture | Numero de Tache | Tache date de fin');
  
    l_step := 'BOUCLE';
  
    -- Insertion des projets parents
    FOR rec_proj_tache IN (SELECT DISTINCT projet.org_absorbante,
                                           projet.project_code,
                                           projet.libelle,
                                           projet.modele,
                                           projet.start_date,
                                           projet.closed_date,
                                           projet.ppa_completion_date,
                                           projet.project_type,
                                           projet.org_name,
                                           projet.affaire,
                                           projet.activite,
                                           projet.filiere,
                                           projet.destination
                             FROM dka.dka_fa_projet_ferme projet
                            WHERE statut = gv_statut_new
                              AND project_type != 'Investissement'
                              AND NOT EXISTS
                            (SELECT 'x'
                                     FROM pa_projects_all           ppa,
                                          hr_all_organization_units hou
                                    WHERE hou.name = projet.org_absorbante
                                      AND ppa.segment1 = projet.project_code)) LOOP
    
      IF (nvl(p_mode_simulation, 'N') = 'N') THEN
        INSERT INTO dka.dka_eai_projet
          (operating_unit,
           project_code,
           libelle,
           project_template,
           project_start_date,
           project_closing_date,
           project_completion_date,
           project_type,
           organization_name,
           organization_start_date,
           code_affaire,
           code_activite,
           code_filiere,
           code_destination,
           oa_status,
           oa_action_type,
           creation_date)
        VALUES
          (rec_proj_tache.org_absorbante,
           substr(rec_proj_tache.project_code, 1, 10),
           rec_proj_tache.libelle,
           rec_proj_tache.org_absorbante || '.' || rec_proj_tache.modele,
           rec_proj_tache.start_date,
           rec_proj_tache.closed_date,
           rec_proj_tache.ppa_completion_date,
           rec_proj_tache.project_type,
           rec_proj_tache.org_name,
           rec_proj_tache.start_date,
           rec_proj_tache.affaire,
           rec_proj_tache.activite,
           rec_proj_tache.filiere,
           rec_proj_tache.destination,
           'NEW',
           'Création',
           SYSDATE);
      END IF;
    
      FOR rec_tache IN (SELECT projet.org_absorbante,
                               projet.project_code,
                               projet.libelle,
                               projet.modele,
                               projet.start_date,
                               projet.closed_date,
                               projet.ppa_completion_date,
                               projet.project_type,
                               projet.org_name,
                               projet.affaire,
                               projet.activite,
                               projet.filiere,
                               projet.destination,
                               projet.task_number,
                               projet.task_name,
                               projet.pt_libelle,
                               projet.pt_start_date,
                               projet.categorie_name,
                               projet.tache_parent,
                               projet.project_status_name,
                               projet.pt_completion_date,
                               projet.rowid rid
                          FROM dka.dka_fa_projet_ferme projet
                         WHERE projet.project_code =
                               rec_proj_tache.project_code) LOOP
      
        dka_tools_pkg.put_outdebug_message(rec_tache.org_name || '|' ||
                                           rec_tache.project_status_name || '|' ||
                                           rec_tache.project_code || '|' ||
                                           rec_tache.ppa_completion_date || '|' ||
                                           rec_tache.closed_date || '|' ||
                                           rec_tache.task_number || '|' ||
                                           rec_tache.pt_completion_date);
      
        IF (nvl(p_mode_simulation, 'N') = 'N') THEN
          INSERT INTO dka.dka_eai_tache
            (project_code,
             task_code,
             task_name,
             description,
             task_start_date,
             asset_category,
             subproject_relationship,
             oa_status)
          VALUES
            (substr(rec_tache.project_code, 1, 10),
             substr(rec_tache.task_number, 1, 10),
             rec_tache.task_name,
             rec_tache.pt_libelle,
             rec_tache.pt_start_date,
             rec_tache.categorie_name,
             substr(rec_tache.tache_parent, 1, 10),
             'NEW');
        
          UPDATE dka.dka_fa_projet_ferme
             SET statut = gv_statut_ok
           WHERE ROWID = rec_tache.rid;
        
        END IF;
      END LOOP;
    
    END LOOP;
  
    IF (nvl(p_mode_simulation, 'N') = 'N') THEN
      g_tab_requests.delete;
    
      submit_project(l_errbuf, l_retcode);
    
      wait_request(l_errbuf, l_retcode);
    END IF;
  
    IF l_retcode <> 0 THEN
      p_errbuf  := l_errbuf;
      p_retcode := l_retcode;
    END IF;
  
    -- Insertion des projets d'investissement
    FOR rec_proj_tache IN (SELECT DISTINCT projet.org_absorbante,
                                           projet.project_code,
                                           projet.libelle,
                                           projet.modele,
                                           projet.start_date,
                                           projet.closed_date,
                                           projet.ppa_completion_date,
                                           projet.project_type,
                                           projet.org_name,
                                           projet.affaire,
                                           projet.activite,
                                           projet.filiere,
                                           projet.destination
                             FROM dka.dka_fa_projet_ferme projet
                            WHERE statut = gv_statut_new
                              AND project_type = 'Investissement') LOOP
    
      IF (nvl(p_mode_simulation, 'N') = 'N') THEN
        INSERT INTO dka.dka_eai_projet
          (operating_unit,
           project_code,
           libelle,
           project_template,
           project_start_date,
           project_closing_date,
           project_completion_date,
           project_type,
           organization_name,
           organization_start_date,
           code_affaire,
           code_activite,
           code_filiere,
           code_destination,
           oa_status,
           oa_action_type,
           creation_date)
        VALUES
          (rec_proj_tache.org_absorbante,
           substr(rec_proj_tache.project_code, 1, 10),
           rec_proj_tache.libelle,
           rec_proj_tache.org_absorbante || '.' || rec_proj_tache.modele,
           rec_proj_tache.start_date,
           rec_proj_tache.closed_date,
           rec_proj_tache.ppa_completion_date,
           rec_proj_tache.project_type,
           rec_proj_tache.org_name,
           rec_proj_tache.start_date,
           rec_proj_tache.affaire,
           rec_proj_tache.activite,
           rec_proj_tache.filiere,
           rec_proj_tache.destination,
           'NEW',
           'Création',
           SYSDATE);
      END IF;
    
      FOR rec_tache IN (SELECT projet.org_absorbante,
                               projet.project_code,
                               projet.libelle,
                               projet.modele,
                               projet.start_date,
                               projet.closed_date,
                               projet.ppa_completion_date,
                               projet.project_type,
                               projet.org_name,
                               projet.affaire,
                               projet.activite,
                               projet.filiere,
                               projet.destination,
                               projet.task_number,
                               projet.task_name,
                               projet.pt_libelle,
                               projet.pt_start_date,
                               projet.categorie_name,
                               projet.tache_parent,
                               projet.project_status_name,
                               projet.pt_completion_date,
                               projet.rowid rid
                          FROM dka.dka_fa_projet_ferme projet
                         WHERE projet.project_code =
                               rec_proj_tache.project_code) LOOP
      
        dka_tools_pkg.put_outdebug_message(rec_tache.org_name || '|' ||
                                           rec_tache.project_status_name || '|' ||
                                           rec_tache.project_code || '|' ||
                                           rec_tache.ppa_completion_date || '|' ||
                                           rec_tache.closed_date || '|' ||
                                           rec_tache.task_number || '|' ||
                                           rec_tache.pt_completion_date);
      
        IF (nvl(p_mode_simulation, 'N') = 'N') THEN
          INSERT INTO dka.dka_eai_tache
            (project_code,
             task_code,
             task_name,
             description,
             task_start_date,
             asset_category,
             subproject_relationship,
             oa_status)
          VALUES
            (substr(rec_tache.project_code, 1, 10),
             substr(rec_tache.task_number, 1, 10),
             rec_tache.task_name,
             rec_tache.pt_libelle,
             rec_tache.pt_start_date,
             rec_tache.categorie_name,
             substr(rec_tache.tache_parent, 1, 10),
             'NEW');
        
          UPDATE dka.dka_fa_projet_ferme
             SET statut = gv_statut_ok
           WHERE ROWID = rec_tache.rid;
        
        END IF;
      END LOOP;
    
    END LOOP;
  
    IF (nvl(p_mode_simulation, 'N') = 'N') THEN
      g_tab_requests.delete;
    
      submit_project(l_errbuf, l_retcode);
    
      wait_request(l_errbuf, l_retcode);
    END IF;
  
    IF l_retcode <> 0 THEN
      p_errbuf  := l_errbuf;
      p_retcode := l_retcode;
    END IF;
  
    l_step := 'COUT';
  
    dka_tools_pkg.put_outdebug_message(' ');
    dka_tools_pkg.put_outdebug_message('Liste les lignes de couts affectés aux projects FC :');
  
    dka_tools_pkg.put_outdebug_message('Trans Id | Project Name | Tache | Src Trans | Date Exp | Numero de Tache | Creation Date | Cout');
    FOR rec_proj_tache IN (SELECT cout.*, cout.rowid rid
                             FROM dka.dka_fa_projet_cout cout
                            WHERE statut = gv_statut_new
                              AND EXISTS
                            (SELECT 'x'
                                     FROM pa_projects_all ppa
                                    WHERE ppa.org_id = cout.org_id_absorbante
                                      AND ppa.segment1 = cout.project)) LOOP
      dka_tools_pkg.put_outdebug_message(rec_proj_tache.trans_id || '/' ||
                                         rec_proj_tache.project || '/' ||
                                         rec_proj_tache.task || '/' ||
                                         rec_proj_tache.tx_src || '/' ||
                                         rec_proj_tache.exp_date || '/' ||
                                         rec_proj_tache.creation_date || '/' ||
                                         rec_proj_tache.raw_cost);
    
      IF (nvl(p_mode_simulation, 'N') = 'N') THEN
        l_step := 'SIMU';
        SELECT trunc(dsl.start_date, 'MONTH') - 1
          INTO ld_end_period
          FROM dka_stransco_lines        dsl,
               dka_stransco_headers      dsh,
               hr_all_organization_units hou,
               hr_all_organization_units hou2
         WHERE dsh.set_name = g_transco
           AND dsl.set_id = dsh.set_id
           AND nvl(dsl.enable, 'N') = 'Y'
           AND hou.name = dsl.param1_value
           AND hou2.name = dsl.return_value
           AND hou.organization_id = rec_proj_tache.org_id
           AND hou2.organization_id = rec_proj_tache.org_id_absorbante;
      
        dka_tools_pkg.put_outdebug_message(ld_end_period);
      
        l_step := 'ORG_ID';
        SELECT hou.name
          INTO vv_ou
          FROM hr_operating_units hou
         WHERE hou.organization_id = rec_proj_tache.org_id_absorbante;
      
        SELECT hou.name
          INTO vv_ou_absorbe
          FROM hr_operating_units hou
         WHERE hou.organization_id = rec_proj_tache.org_id;
      
        l_step := 'GCC';
        BEGIN
          SELECT segment1,
                 segment2,
                 segment3,
                 segment4,
                 segment5,
                 segment6,
                 segment7,
                 segment8,
                 segment9,
                 segment10
            INTO l_seg1,
                 l_seg2,
                 l_seg3,
                 l_seg4,
                 l_seg5,
                 l_seg6,
                 l_seg7,
                 l_seg8,
                 l_seg9,
                 l_seg10
            FROM gl_code_combinations gcc
           WHERE code_combination_id =
                 rec_proj_tache.dr_code_combination_id;
        
          SELECT COUNT(1)
            INTO l_count
            FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
           WHERE ffvs.flex_value_set_name = 'DAOPCCF_PROJETFI'
             AND ffv.flex_value_set_id = ffvs.flex_value_set_id
             AND ffv.flex_value = l_seg8
             AND (enabled_flag = 'N' OR
                 trunc(SYSDATE) NOT BETWEEN start_date_active AND
                 nvl(end_date_active, trunc(SYSDATE)));
        
          IF l_count > 0 THEN
            SELECT ffv.enabled_flag,
                   ffv.start_date_active,
                   ffv.end_date_active
              INTO vv_enabled_flag,
                   vd_start_date_active,
                   vd_end_date_active
              FROM fnd_flex_values ffv
             WHERE ffv.flex_value_set_id IN
                   (SELECT ffvs.flex_value_set_id
                      FROM fnd_flex_value_sets ffvs
                     WHERE ffvs.flex_value_set_name = 'DAOPCCF_PROJETFI')
               AND ffv.flex_value = l_seg8;
          
            UPDATE fnd_flex_values ffv
               SET enabled_flag = 'Y', ffv.end_date_active = NULL
             WHERE ffv.flex_value_set_id IN
                   (SELECT ffvs.flex_value_set_id
                      FROM fnd_flex_value_sets ffvs
                     WHERE ffvs.flex_value_set_name = 'DAOPCCF_PROJETFI')
               AND ffv.flex_value = l_seg8;
            
            fnd_file.put_line(fnd_file.log, 'Mise à jour du projet ' || l_seg8 || ' dans DAOPCCF_PROJETFI');
          END IF;
        
          get_code_combination_id(pv_segment1            => substr(vv_ou, 4),
                                  pv_segment2            => substr(vv_ou,
                                                                   1,
                                                                   3),
                                  pv_segment3            => l_seg3,
                                  pv_segment4            => l_seg4,
                                  pv_segment5            => l_seg5,
                                  pv_segment6            => l_seg6,
                                  pv_segment7            => l_seg7,
                                  pv_segment8            => l_seg8,
                                  pv_segment9            => l_seg9,
                                  pv_segment10           => l_seg10,
                                  pv_segment11           => '0',
                                  pv_segment12           => '0',
                                  pn_code_combination_id => vn_ccid,
                                  pv_errbuf              => vv_errbuf_ccid,
                                  pn_retcode             => vn_retcode_ccid,
                                  pv_validation_flag     => 'Y');
        
          IF vn_retcode_ccid != 0 THEN
            vn_ccid := NULL;
          
            fnd_file.put_line(fnd_file.log,
                              'La clé ' || substr(vv_ou, 4) || '.' ||
                              substr(vv_ou, 1, 3) || '.' || l_seg3 || '.' ||
                              l_seg4 || '.' || l_seg5 || '.' || l_seg6 || '.' ||
                              l_seg7 || '.' || l_seg8 || '.' || l_seg9 || '.' ||
                              l_seg10 || ' n''est pas valide');
            fnd_file.put_line(fnd_file.log, vv_errbuf_ccid);
          END IF;
          
          IF l_count > 0 THEN
          
            UPDATE fnd_flex_values ffv
               SET enabled_flag          = vv_enabled_flag,
                   ffv.end_date_active   = vd_end_date_active,
                   last_update_date      = SYSDATE,
                   ffv.last_updated_by   = fnd_global.user_id,
                   ffv.last_update_login = fnd_global.login_id
             WHERE ffv.flex_value_set_id IN
                   (SELECT ffvs.flex_value_set_id
                      FROM fnd_flex_value_sets ffvs
                     WHERE ffvs.flex_value_set_name = 'DAOPCCF_PROJETFI')
               AND ffv.flex_value = l_seg8;
          END IF;
        
          get_code_combination_id(pv_segment1            => substr(vv_ou, 4),
                                  pv_segment2            => substr(vv_ou,
                                                                   1,
                                                                   3),
                                  pv_segment3            => '0',
                                  pv_segment4            => '0',
                                  pv_segment5            => '0',
                                  pv_segment6            => '0',
                                  pv_segment7            => '0',
                                  pv_segment8            => 0,
                                  pv_segment9            => 0,
                                  pv_segment10           => 0,
                                  pv_segment11           => '0',
                                  pv_segment12           => '0',
                                  pn_code_combination_id => vn_ccid2,
                                  pv_errbuf              => vv_errbuf_ccid,
                                  pn_retcode             => vn_retcode_ccid,
                                  pv_validation_flag     => 'Y');
        END;
      
        l_step := 'SEQUENCE';
      
        SELECT dka.dka_fusion_couts_s.nextval INTO ln_sequence FROM dual;
      
        l_step := 'INSERT';
      
        v_original_trans_ref := 'FUSION_' || vv_ou || '_' || ln_sequence;
      
        mo_global.set_policy_context('S', rec_proj_tache.org_id_absorbante);
      
        INSERT INTO pa_transaction_interface_all
          (transaction_source,
           batch_name,
           expenditure_ending_date,
           employee_number,
           organization_name,
           expenditure_item_date,
           project_number,
           task_number,
           expenditure_type,
           non_labor_resource,
           non_labor_resource_org_name,
           quantity,
           raw_cost,
           expenditure_comment,
           transaction_status_code,
           transaction_rejection_code,
           expenditure_id,
           orig_transaction_reference,
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
           raw_cost_rate,
           interface_id,
           unmatched_negative_txn_flag,
           expenditure_item_id,
           org_id,
           dr_code_combination_id,
           cr_code_combination_id,
           cdl_system_reference1,
           cdl_system_reference2,
           cdl_system_reference3,
           gl_date,
           burdened_cost,
           burdened_cost_rate,
           system_linkage,
           txn_interface_id,
           user_transaction_source,
           created_by,
           creation_date,
           last_updated_by,
           last_update_date,
           receipt_currency_amount,
           receipt_currency_code,
           receipt_exchange_rate,
           denom_currency_code,
           denom_raw_cost,
           denom_burdened_cost,
           acct_rate_date,
           acct_rate_type,
           acct_exchange_rate,
           acct_raw_cost,
           acct_burdened_cost,
           acct_exchange_rounding_limit,
           project_currency_code,
           project_rate_date,
           project_rate_type,
           project_exchange_rate,
           orig_exp_txn_reference1,
           orig_exp_txn_reference2,
           orig_exp_txn_reference3,
           orig_user_exp_txn_reference,
           vendor_number,
           override_to_organization_name,
           reversed_orig_txn_reference,
           billable_flag,
           person_business_group_name)
        VALUES
          ('FUSION_FA', --TRANSACTION_SOURCE,
           'FUSION_FA_' || to_char(SYSDATE, 'DDMMRRHH24MI'), --BATCH_NAME,
           pa_utils.getweekending(ld_end_period), --EXPENDITURE_ENDING_DATE,
           NULL, --EMPLOYEE_NUMBER,
           rec_proj_tache.org_depense, --ORGANIZATION_NAME,
           ld_end_period, --EXPENDITURE_ITEM_DATE, 
           rec_proj_tache.project, --PROJECT_NUMBER,
           rec_proj_tache.task, --TASK_NUMBER,
           rec_proj_tache.expenditure_type, --EXPENDITURE_TYPE,
           NULL, --NON_LABOR_RESOURCE,
           NULL, --NON_LABOR_RESOURCE_ORG_NAME,
           rec_proj_tache.quantity, --QUANTITY,
           rec_proj_tache.raw_cost, --RAW_COST,
           'Fusion ' || vv_ou_absorbe, -- expenditure_comment
           'P', --TRANSACTION_STATUS_CODE,
           NULL, --TRANSACTION_REJECTION_CODE,
           NULL, --EXPENDITURE_ID,
           v_original_trans_ref, --ORIG_TRANSACTION_REFERENCE,
           'Global Data Elements', --ATTRIBUTE_CATEGORY,
           NULL, --ATTRIBUTE1,
           NULL, --ATTRIBUTE2,
           NULL, --ATTRIBUTE3,
           NULL, --ATTRIBUTE4,
           to_char(ld_end_period, 'RRRRMMDD'), --ATTRIBUTE5,
           NULL, --ATTRIBUTE6,
           NULL, --ATTRIBUTE7,
           NULL, --ATTRIBUTE8,
           NULL, --ATTRIBUTE9,
           NULL, --ATTRIBUTE10,
           NULL, --RAW_COST_RATE,
           NULL, --INTERFACE_ID,
           'Y', --UNMATCHED_NEGATIVE_TXN_FLAG,
           NULL, --EXPENDITURE_ITEM_ID,
           rec_proj_tache.org_id_absorbante, -- ORG_ID
           vn_ccid, -- vn_ccid, --DR_CODE_COMBINATION_ID,
           vn_ccid2, --CR_CODE_COMBINATION_ID,
           NULL, --CDL_SYSTEM_REFERENCE1,
           NULL, --CDL_SYSTEM_REFERENCE2,
           NULL, --CDL_SYSTEM_REFERENCE3,
           ld_end_period, --GL_DATE,
           rec_proj_tache.burden_cost, --BURDENED_COST,
           NULL, --BURDENED_COST_RATE,
           'PJ', --SYSTEM_LINKAGE,
           NULL, --TXN_INTERFACE_ID,
           NULL, --USER_TRANSACTION_SOURCE,
           fnd_global.user_id, --CREATED_BY,
           SYSDATE, --CREATION_DATE,
           fnd_global.user_id, --LAST_UPDATED_BY,
           SYSDATE, --LAST_UPDATE_DATE,
           NULL, --RECEIPT_CURRENCY_AMOUNT,
           NULL, --RECEIPT_CURRENCY_CODE,
           NULL, --RECEIPT_EXCHANGE_RATE,
           NULL, --DENOM_CURRENCY_CODE,
           rec_proj_tache.raw_cost, --DENOM_RAW_COST,
           rec_proj_tache.burden_cost, --DENOM_BURDENED_COST,
           NULL, --ACCT_RATE_DATE,
           NULL, --ACCT_RATE_TYPE,
           NULL, --ACCT_EXCHANGE_RATE,
           rec_proj_tache.raw_cost, --ACCT_RAW_COST,
           rec_proj_tache.burden_cost, --ACCT_BURDENED_COST,
           NULL, --ACCT_EXCHANGE_ROUNDING_LIMIT,
           NULL, --PROJECT_CURRENCY_CODE,
           NULL, --PROJECT_RATE_DATE,
           NULL, --PROJECT_RATE_TYPE,
           NULL, --PROJECT_EXCHANGE_RATE,
           NULL, --ORIG_EXP_TXN_REFERENCE1,
           NULL, --ORIG_EXP_TXN_REFERENCE2,
           NULL, --ORIG_EXP_TXN_REFERENCE3,
           NULL, --ORIG_USER_EXP_TXN_REFERENCE,
           NULL, --VENDOR_NUMBER,
           NULL, --OVERRIDE_TO_ORGANIZATION_NAME,
           NULL, --REVERSED_ORIG_TXN_REFERENCE,
           NULL, --BILLABLE_FLAG,
           NULL --PERSON_BUSINESS_GROUP_NAME
           );
        l_step := 'FIN INSERT';
      
        UPDATE dka.dka_fa_projet_cout
           SET statut = gv_statut_ok
         WHERE ROWID = rec_proj_tache.rid;
      END IF;
    END LOOP;
  
    IF (nvl(p_mode_simulation, 'N') = 'N') THEN
      program_import_couts(l_errbuf, l_retcode);
    END IF;
  
    IF l_retcode <> 0 THEN
      p_errbuf  := l_errbuf;
      p_retcode := l_retcode;
    END IF;
  
    dka_tools_pkg.put_outdebug_message(' ');
    dka_tools_pkg.put_outdebug_message('Liste les lignes de couts affectés aux projects FC non insérés :');
  
    dka_tools_pkg.put_outdebug_message('Trans Id | Project Name | Tache | Src Trans | Date Exp | Numero de Tache | Creation Date | Cout');
    FOR rec_proj_tache IN (SELECT cout.*, cout.rowid rid
                             FROM dka.dka_fa_projet_cout cout
                            WHERE statut = gv_statut_new) LOOP
      dka_tools_pkg.put_outdebug_message(rec_proj_tache.trans_id || '/' ||
                                         rec_proj_tache.project || '/' ||
                                         rec_proj_tache.task || '/' ||
                                         rec_proj_tache.tx_src || '/' ||
                                         rec_proj_tache.exp_date || '/' ||
                                         rec_proj_tache.creation_date || '/' ||
                                         rec_proj_tache.raw_cost);
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      p_errbuf  := 'Erreur dans la procécure Main_import : ' || l_step ||
                   ' : ' || SQLCODE || '-' || substr(SQLERRM, 1, 1000);
      p_retcode := 2;
    
      dka_tools_pkg.put_outdebug_message(' ');
      dka_tools_pkg.put_outdebug_message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      dka_tools_pkg.put_outdebug_message('=> TRAITEMENT TERMINE EN ERREUR');
      dka_tools_pkg.put_outdebug_message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      dka_tools_pkg.put_outdebug_message(p_errbuf);
    
  END main_import;

  /*
   *************************************************************************
   * PROCEDURE NAME : print_errors
   *
   * DESCRIPTION
   *  Procédure pour écrire les anomalies du programme
   *
   * PARAMETERS
   * ==========
   * NAME               DESCRIPTION
  .* -----------------  ------------------------------------------------------
   *
   ************************************************************************
   */

  PROCEDURE print_errors IS
  
    CURSOR cur_prog_mess IS
      SELECT DISTINCT msg.column_name, msg.column_value, msg.message_text
        FROM dka_program_messages msg
       WHERE request_id = g_request_id;
  
  BEGIN
  
    fnd_file.put_line(fnd_file.output, chr(10) || chr(10));
    fnd_file.put_line(fnd_file.output, 'LISTE DES ANOMALIES :');
    fnd_file.put_line(fnd_file.output,
                      '---------------------------------------------------------------------------------------------');
  
    FOR msg IN cur_prog_mess LOOP
      fnd_file.put_line(fnd_file.output,
                        '. ' || rpad(msg.column_name, 30) || '|' ||
                        rpad(msg.column_value, 30) || '|' ||
                        msg.message_text);
    END LOOP;
  
  END print_errors;

  ------------------------------------------------------------------------------------
  -- Nom              : main_control_insert
  -- Description      : Procédure principale d'insertion des immos
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
  PROCEDURE main_control_insert(p_errbuf  OUT VARCHAR2,
                                p_retcode OUT NUMBER) IS
    l_step        VARCHAR2(50);
    v_flag_erreur BOOLEAN;
  
    CURSOR cur_social_data IS
      SELECT *
        FROM dka.dka_fa_fusion_immo dk
       WHERE nvl(statut, gv_statut_new) IN (gv_statut_new, gv_statut_ko)
         FOR UPDATE;
  
    CURSOR cur_proj_tache_actif(p_org_id_absorbee   NUMBER,
                                p_org_id_absorbante NUMBER) IS
      SELECT hou.name                org_name,
             pps.project_status_name,
             ppa.segment1,
             ppa.completion_date     ppa_completion_date,
             ppa.closed_date,
             pt.task_number,
             pt.completion_date      pt_completion_date
        FROM fa_asset_invoices         fai,
             pa_projects_all           ppa,
             pa_project_statuses       pps,
             pa_tasks                  pt,
             hr_all_organization_units hou
       WHERE 1 = 1
         AND ppa.project_status_code = pps.project_status_code
         AND ppa.segment1 LIKE 'FC%'
         AND pps.status_type = 'PROJECT'
         AND pt.task_id = fai.task_id
         AND pt.task_number LIKE 'GY%'
         AND ppa.project_id = fai.project_id
         AND ((pps.project_status_name = 'Actif' AND
             ppa.completion_date IS NULL AND ppa.closed_date IS NULL) OR
             pt.completion_date IS NULL)
         AND NOT EXISTS
       (SELECT 'x'
                FROM pa_projects_all ppa2, pa_tasks pt2
               WHERE ppa2.project_id = pt2.project_id
                 AND substr(ppa2.segment1, 1, 10) =
                     substr(ppa.segment1, 1, 10)
                 AND substr(pt2.task_number, 1, 10) =
                     substr(pt.task_number, 1, 10)
                 AND ppa2.org_id = p_org_id_absorbante)
         AND ppa.org_id = p_org_id_absorbee
         AND hou.organization_id = ppa.carrying_out_organization_id;
  
    CURSOR cur_proj_tache_ferme(p_org_id_absorbee   NUMBER,
                                p_org_id_absorbante NUMBER) IS
      SELECT hou.name org_name,
             pps.project_status_name,
             ppa.segment1 project_code,
             ppa.completion_date ppa_completion_date,
             ppa.closed_date,
             pt.task_name,
             pt.task_number,
             fc.segment1 || '.' || fc.segment2 || '.' || fc.segment3 || '.' ||
             fc.segment4 categorie_name,
             pt2.task_number tache_parent,
             pt.description pt_libelle,
             pt.start_date pt_start_date,
             pt.completion_date pt_completion_date,
             hou2.name org_name2,
             ppa.description libelle,
             ppa.project_type,
             ppc.class_code affaire,
             ppc2.class_code destination,
             ppc3.class_code filiere,
             ppc4.class_code activite,
             ppa.start_date,
             (SELECT DISTINCT dsl.return_value
                FROM dka_stransco_lines dsl, dka_stransco_headers dsh
               WHERE dsh.set_name = g_transco
                 AND dsl.set_id = dsh.set_id
                 AND nvl(dsl.enable, 'N') = 'Y'
                 AND dsl.param1_value = hou2.name) org_absorbante
        FROM fa_asset_invoices         fai,
             pa_projects_all           ppa,
             pa_project_statuses       pps,
             pa_tasks                  pt,
             hr_all_organization_units hou,
             hr_all_organization_units hou2,
             pa_project_classes_v      ppc,
             pa_project_classes_v      ppc2,
             pa_project_classes_v      ppc3,
             pa_project_classes_v      ppc4,
             fa_categories_vl          fc,
             pa_tasks                  pt2
       WHERE 1 = 1
         AND ppa.project_status_code = pps.project_status_code
         AND ppa.segment1 LIKE 'FC%'
         AND pps.status_type = 'PROJECT'
         AND pt.task_id = fai.task_id
         AND pt.task_number LIKE 'GY%'
         AND ppa.project_id = fai.project_id
         AND pps.project_status_name = 'Fermé'
         AND ppa.completion_date IS NOT NULL
         AND pt.completion_date IS NOT NULL
         AND ppa.org_id = p_org_id_absorbee
         AND hou.organization_id = ppa.carrying_out_organization_id
         AND ppa.org_id = hou2.organization_id
         AND ppc.project_id(+) = ppa.project_id
         AND ppc.class_category(+) = 'AFFAIRE'
         AND ppc2.project_id(+) = ppa.project_id
         AND ppc2.class_category(+) = 'DESTINATION'
         AND ppc3.project_id(+) = ppa.project_id
         AND ppc3.class_category(+) = 'FILIERE'
         AND ppc4.project_id(+) = ppa.project_id
         AND ppc4.class_category(+) = 'ACTIVITE'
         AND fc.category_id(+) = pt.attribute6
         AND pt2.task_id(+) = pt.attribute7
         AND NOT EXISTS
       (SELECT 'x'
                FROM pa_projects_all ppa2, pa_tasks pt2
               WHERE ppa2.project_id = pt2.project_id
                 AND substr(ppa2.segment1, 1, 10) =
                     substr(ppa.segment1, 1, 10)
                 AND substr(pt2.task_number, 1, 10) =
                     substr(pt.task_number, 1, 10)
                 AND ppa2.org_id = p_org_id_absorbante);
  
    CURSOR cur_control_cout IS
      SELECT *
        FROM dka.dka_fa_projet_cout cout
       WHERE (cout.org_id_absorbante, quantity, task, expenditure_type,
              raw_cost, project) NOT IN
             (SELECT peia.org_id,
                     quantity,
                     pt.task_number,
                     expenditure_type,
                     raw_cost,
                     pp.segment1
                FROM pa_expenditure_items_all peia,
                     pa_projects_all          pp,
                     pa_tasks                 pt
               WHERE peia.transaction_source = 'FUSION_FA'
                 AND peia.project_id = pp.project_id
                 AND peia.task_id = pt.task_id);
  
    ln_project_id     NUMBER;
    ln_task_id        NUMBER;
    ln_category_id    NUMBER;
    ln_asset_key_ccid NUMBER;
    ln_loc_ccid       NUMBER;
    vn_dotation_ccid  NUMBER;
    vn_lettrage_ccid  NUMBER;
    vv_errbuf_ccid    VARCHAR2(2000);
    vn_retcode_ccid   NUMBER;
  
    application_short_name VARCHAR2(200);
    key_flex_code          VARCHAR2(200);
    structure_number       NUMBER;
    validation_date        DATE;
    n_segments             NUMBER;
    segments               apps.fnd_flex_ext.segmentarray;
    data_set               NUMBER;
    v_return               BOOLEAN;
  BEGIN
  
    dka_tools_pkg.put_outdebug_message('----------------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('    Log des traitements DKA                                          : Contrôles avant insertion');
    dka_tools_pkg.put_outdebug_message('-----------------:------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('');
  
    v_flag_erreur := FALSE;
  
    FOR rec_soc IN cur_soc_fusion_org LOOP
      FOR rec_proj IN cur_proj_tache_actif(rec_soc.org_id_from,
                                           rec_soc.org_id_to) LOOP
        dka_tools_pkg.ins_prog_message(g_request_id,
                                       'DKA_SFAFUSIONSOCCTR',
                                       'ETL',
                                       'DKA_FA_FUSION_IMMO',
                                       rec_proj.segment1,
                                       'PROJECT_TASK_OPËN',
                                       rec_proj.segment1 || '/' ||
                                       rec_proj.task_number,
                                       'E',
                                       'Le projet et la tâche actif n''existe pas dans l''organisation ' ||
                                       rec_soc.soc_to);
      END LOOP;
    
      FOR rec_proj IN cur_proj_tache_ferme(rec_soc.org_id_from,
                                           rec_soc.org_id_to) LOOP
        dka_tools_pkg.ins_prog_message(g_request_id,
                                       'DKA_SFAFUSIONSOCCTR',
                                       'ETL',
                                       'DKA_FA_FUSION_IMMO',
                                       rec_proj.project_code,
                                       'PROJECT_TASK_CLOSE',
                                       rec_proj.project_code || '/' ||
                                       rec_proj.task_number,
                                       'E',
                                       'Le projet et la tâche fermée n''existe pas dans l''organisation ' ||
                                       rec_soc.soc_to);
      END LOOP;
    
    END LOOP;
  
    FOR rec_cout IN cur_control_cout LOOP
      dka_tools_pkg.ins_prog_message(g_request_id,
                                     'DKA_SFAFUSIONSOCCTR',
                                     'ETL',
                                     'DKA_FA_PROJET_COUT',
                                     rec_cout.project,
                                     'COST',
                                     rec_cout.project || '/' ||
                                     rec_cout.task,
                                     'E',
                                     'La ligne de cout n''existe pas dans PA : ' ||
                                     rec_cout.raw_cost || '/' ||
                                     rec_cout.expenditure_type);
    
    END LOOP;
  
    FOR rec_social IN cur_social_data LOOP
      -- 03/10/2019 NBO Modification sur le contrôle avant importation pour éviter de mettre à jour les status à tort.
      v_flag_erreur := FALSE;
    
      -- Contrôle de l'existence du projet cible
      BEGIN
        SELECT pp.project_id, pt.task_id
          INTO ln_project_id, ln_task_id
          FROM pa_tasks pt, pa_projects_all pp, hr_operating_units hou
         WHERE pt.task_number = substr(rec_social.task_number, 1, 10)
           AND pt.project_id = pp.project_id
           AND pp.segment1 = substr(rec_social.project, 1, 10)
           AND pp.org_id = hou.organization_id
           AND hou.name = rec_social.d_uo_seg || rec_social.d_societe_seg;
      
      EXCEPTION
        WHEN no_data_found THEN
          v_flag_erreur := TRUE;
          ln_project_id := NULL;
          ln_task_id    := NULL;
        
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_SFAFUSIONSOCCTR',
                                         'ETL',
                                         'DKA_FA_FUSION_IMMO',
                                         rec_social.numero_immobilisation,
                                         'PROJECT_NUMBER',
                                         rec_social.project || '/' ||
                                         rec_social.task_number,
                                         'E',
                                         'Le projet n''existe pas');
      END;
    
      BEGIN
        l_step := 'CATEGORY';
      
        SELECT category_id
          INTO ln_category_id
          FROM fa_categories_vl
         WHERE segment1 = rec_social.rub_principale
           AND segment2 = rec_social.rub_detail
           AND segment3 = rec_social.methode_amt
           AND segment4 = rec_social.plafond_amt;
      EXCEPTION
        WHEN no_data_found THEN
          v_flag_erreur  := TRUE;
          ln_category_id := NULL;
        
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_SFAFUSIONSOCCTR',
                                         'ETL',
                                         'DKA_FA_FUSION_IMMO',
                                         rec_social.numero_immobilisation,
                                         'CATEGORY',
                                         substr(rec_social.rub_principale || '.' ||
                                                rec_social.rub_detail || '.' ||
                                                rec_social.methode_amt || '.' ||
                                                rec_social.plafond_amt,
                                                1,
                                                30),
                                         'E',
                                         'La catégorie d''immobilisation n''existe pas');
      END;
    
      -- Contrôle de la clé TAXE
      BEGIN
        l_step := 'TAXE_IMPOT';
      
        application_short_name := 'OFA';
        key_flex_code := 'KEY#';
        structure_number := 101;
        validation_date := SYSDATE;
        n_segments := 2;
        segments(1) := rec_social.taxe_prof;
        segments(2) := rec_social.impot_foncier;
        data_set := NULL;
      
        v_return := fnd_flex_ext.get_combination_id(application_short_name => application_short_name,
                                                    key_flex_code          => key_flex_code,
                                                    structure_number       => structure_number,
                                                    validation_date        => validation_date,
                                                    n_segments             => n_segments,
                                                    segments               => segments,
                                                    combination_id         => ln_asset_key_ccid);
      
        IF NOT v_return THEN
          v_flag_erreur     := TRUE;
          ln_asset_key_ccid := NULL;
        
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_SFAFUSIONSOCCTR',
                                         'ETL',
                                         'DKA_FA_FUSION_IMMO',
                                         rec_social.numero_immobilisation,
                                         'CLE_TAXE',
                                         substr(rec_social.taxe_prof || '.' ||
                                                rec_social.impot_foncier,
                                                1,
                                                30),
                                         'E',
                                         'La clé TAXE IMPOT n''est pas valide');
        END IF;
      END;
    
      -- Contrôle de la clé LIEU
      BEGIN
        l_step := 'LIEU';
      
        application_short_name := 'OFA';
        key_flex_code := 'LOC#';
        structure_number := 101;
        validation_date := SYSDATE;
        n_segments := 2;
        segments(1) := rec_social.societe;
        segments(2) := rec_social.lieu_physique;
        data_set := NULL;
      
        v_return := fnd_flex_ext.get_combination_id(application_short_name => application_short_name,
                                                    key_flex_code          => key_flex_code,
                                                    structure_number       => structure_number,
                                                    validation_date        => validation_date,
                                                    n_segments             => n_segments,
                                                    segments               => segments,
                                                    combination_id         => ln_loc_ccid);
      
        IF NOT v_return THEN
          v_flag_erreur := TRUE;
          ln_loc_ccid   := NULL;
        
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_SFAFUSIONSOCCTR',
                                         'ETL',
                                         'DKA_FA_FUSION_IMMO',
                                         rec_social.numero_immobilisation,
                                         'CLE_LIEU',
                                         substr(rec_social.societe || '.' ||
                                                rec_social.lieu_physique,
                                                1,
                                                30),
                                         'E',
                                         'La clé LIEU n''est pas valide');
        END IF;
      END;
    
      BEGIN
        l_step := 'COMPTE_DOTATION';
      
        get_code_combination_id(pv_segment1            => rec_social.d_societe_seg,
                                pv_segment2            => rec_social.d_uo_seg,
                                pv_segment3            => rec_social.d_compte_local,
                                pv_segment4            => rec_social.d_compte_analytique,
                                pv_segment5            => rec_social.d_interco,
                                pv_segment6            => rec_social.d_centre_fi,
                                pv_segment7            => rec_social.d_affaire,
                                pv_segment8            => rec_social.d_projet_fi,
                                pv_segment9            => rec_social.d_flux,
                                pv_segment10           => rec_social.d_reserve2,
                                pv_segment11           => '0',
                                pv_segment12           => '0',
                                pn_code_combination_id => vn_dotation_ccid,
                                pv_errbuf              => vv_errbuf_ccid,
                                pn_retcode             => vn_retcode_ccid,
                                pv_validation_flag     => 'N');
      
        l_step := 'COMPTE_DOTATION CCID';
      
        IF vn_retcode_ccid != 0 THEN
          v_flag_erreur    := TRUE;
          vn_dotation_ccid := NULL;
        
          --fnd_file.put_line(fnd_file.log, vv_errbuf_ccid);
        
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_SFAFUSIONSOCCTR',
                                         'ETL',
                                         'DKA_FA_FUSION_IMMO',
                                         rec_social.numero_immobilisation,
                                         'EXPENSE_ACCOUNT',
                                         substr(rec_social.d_societe_seg || '.' ||
                                                rec_social.d_uo_seg || '.' ||
                                                rec_social.d_compte_local || '.' ||
                                                rec_social.d_compte_analytique || '.' ||
                                                rec_social.d_interco || '.' ||
                                                rec_social.d_centre_fi || '.' ||
                                                rec_social.d_affaire || '.' ||
                                                rec_social.d_projet_fi || '.' ||
                                                rec_social.d_flux || '.' ||
                                                rec_social.d_reserve2,
                                                1,
                                                30),
                                         'E',
                                         'La clé de dotation n''est pas valide');
        END IF;
      END;
    
      -- Contrôle de la clé de lettrage
      BEGIN
        l_step := 'COMPTE_LETTRAGE';
      
        get_code_combination_id(pv_segment1            => rec_social.l_societe_seg,
                                pv_segment2            => rec_social.l_uo_seg,
                                pv_segment3            => rec_social.l_compte_local,
                                pv_segment4            => rec_social.l_compte_analytique,
                                pv_segment5            => rec_social.l_interco,
                                pv_segment6            => rec_social.l_centre_fi,
                                pv_segment7            => rec_social.l_affaire,
                                pv_segment8            => rec_social.l_projet_fi,
                                pv_segment9            => rec_social.l_flux,
                                pv_segment10           => rec_social.l_reserve2,
                                pv_segment11           => '0',
                                pv_segment12           => '0',
                                pn_code_combination_id => vn_lettrage_ccid,
                                pv_errbuf              => vv_errbuf_ccid,
                                pn_retcode             => vn_retcode_ccid,
                                pv_validation_flag     => 'N');
      
        IF vn_retcode_ccid != 0 THEN
          v_flag_erreur    := TRUE;
          vn_lettrage_ccid := NULL;
        
          --fnd_file.put_line(fnd_file.log, vv_errbuf_ccid);
        
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_SFAFUSIONSOCCTR',
                                         'ETL',
                                         'DKA_FA_FUSION_IMMO',
                                         rec_social.numero_immobilisation,
                                         'CLEARING_ACCOUNT',
                                         substr(rec_social.l_societe_seg || '.' ||
                                                rec_social.l_uo_seg || '.' ||
                                                rec_social.l_compte_local || '.' ||
                                                rec_social.l_compte_analytique || '.' ||
                                                rec_social.l_interco || '.' ||
                                                rec_social.l_centre_fi || '.' ||
                                                rec_social.l_affaire || '.' ||
                                                rec_social.l_projet_fi || '.' ||
                                                rec_social.l_flux || '.' ||
                                                rec_social.l_reserve2,
                                                1,
                                                30),
                                         'E',
                                         'La clé de lettrage n''est pas valide');
        END IF;
      END;
    
      IF NOT v_flag_erreur THEN
      
        UPDATE dka.dka_fa_fusion_immo
           SET statut                       = gv_statut_valid,
               asset_category_id            = ln_category_id,
               asset_key_ccid               = ln_asset_key_ccid,
               location_id                  = ln_loc_ccid,
               cle_dotation                 = rec_social.d_societe_seg || '.' ||
                                              rec_social.d_uo_seg || '.' ||
                                              rec_social.d_compte_local || '.' ||
                                              rec_social.d_compte_analytique || '.' ||
                                              rec_social.d_interco || '.' ||
                                              rec_social.d_centre_fi || '.' ||
                                              rec_social.d_affaire || '.' ||
                                              rec_social.d_projet_fi || '.' ||
                                              rec_social.d_flux || '.' ||
                                              rec_social.d_reserve2,
               deprn_expense_ccid           = vn_dotation_ccid,
               cle_lettrage                 = rec_social.l_societe_seg || '.' ||
                                              rec_social.l_uo_seg || '.' ||
                                              rec_social.l_compte_local || '.' ||
                                              rec_social.l_compte_analytique || '.' ||
                                              rec_social.l_interco || '.' ||
                                              rec_social.l_centre_fi || '.' ||
                                              rec_social.l_affaire || '.' ||
                                              rec_social.l_projet_fi || '.' ||
                                              rec_social.l_flux || '.' ||
                                              rec_social.l_reserve2,
               payables_code_combination_id = vn_lettrage_ccid,
               project_id                   = ln_project_id,
               task_id                      = ln_task_id
         WHERE CURRENT OF cur_social_data;
      
        g_summary.valid_rows_social := g_summary.valid_rows_social + 1;
      
      ELSE
        -- en cas d'erreur
      
        UPDATE dka.dka_fa_fusion_immo
           SET statut = gv_statut_ko
         WHERE CURRENT OF cur_social_data;
      
        g_summary.rejected_rows := g_summary.rejected_rows + 1;
      
      END IF;
    END LOOP;
  
    print_errors;
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      p_errbuf  := 'Erreur dans la procécure main_control_insert : ' ||
                   l_step || ' : ' || SQLCODE || '-' ||
                   substr(SQLERRM, 1, 1000);
      p_retcode := 2;
    
      dka_tools_pkg.put_outdebug_message(' ');
      dka_tools_pkg.put_outdebug_message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      dka_tools_pkg.put_outdebug_message('=> TRAITEMENT TERMINE EN ERREUR');
      dka_tools_pkg.put_outdebug_message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      dka_tools_pkg.put_outdebug_message(p_errbuf);
  END main_control_insert;

  /*
   *************************************************************************
   * PROCEDURE NAME : insert_data_social
   *
   * DESCRIPTION
   *  Insertion des données des livrees sociaux dans la table d'interface
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE insert_data_social(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
    CURSOR cur_social_data IS
      SELECT *
        FROM dka.dka_fa_fusion_immo dk
       WHERE nvl(statut, gv_statut_new) IN (gv_statut_valid)
         AND dk.book_type_code LIKE '%SOCIAL'
         AND NOT EXISTS
       (SELECT '1'
                FROM fa_additions fa
               WHERE asset_number = dk.numero_immobilisation || '-' ||
                     substr(dk.societe_absorbee, 4)
              UNION ALL
              SELECT '1'
                FROM fa_mass_additions fa
               WHERE asset_number = dk.numero_immobilisation || '-' ||
                     substr(dk.societe_absorbee, 4))
         FOR UPDATE;
  
    l_seq   NUMBER;
    l_livre VARCHAR2(100);
    l_step  VARCHAR2(50);
  
  BEGIN
    p_retcode := 0;
  
    fnd_file.put_line(fnd_file.log,
                      'insert_data_social : start : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));
  
    FOR rec_social_data IN cur_social_data LOOP
    
      SELECT fa_mass_additions_s.nextval INTO l_seq FROM dual;
    
      l_step := 'INSERT';
    
      BEGIN
        -- Donnee a inserer dans la table d'interface
        INSERT INTO fa_mass_additions
          (mass_addition_id,
           asset_number,
           description,
           asset_category_id, --
           book_type_code,
           date_placed_in_service,
           fixed_assets_cost,
           payables_units,
           fixed_assets_units,
           payables_code_combination_id, --
           feeder_system_name,
           create_batch_date,
           create_batch_id, --
           posting_status,
           queue_name,
           payables_cost, --
           depreciate_flag,
           asset_key_ccid, --
           asset_type,
           deprn_reserve,
           ytd_deprn,
           amortize_nbv_flag,
           amortization_start_date,
           in_use_flag,
           owned_leased,
           new_used,
           deprn_method_code,
           life_in_months,
           project_id, --
           task_id --
           )
        VALUES
          (l_seq,
           rec_social_data.numero_immobilisation || '-' ||
           substr(rec_social_data.societe_absorbee, 4),
           substr(rec_social_data.libelle_immo, 1, 80),
           rec_social_data.asset_category_id,
           rec_social_data.livre_fa,
           rec_social_data.date_de_mise_en_service,
           rec_social_data.cost,
           rec_social_data.unites,
           rec_social_data.unites,
           rec_social_data.payables_code_combination_id,
           'FUSION_FA',
           SYSDATE,
           fnd_global.conc_request_id,
           'POST',
           'POST',
           rec_social_data.cost,
           -- AMORTIR doit également être faite pour pouvoir gérer les éventuels formats différents du fichier Calisto (OUI, Oui, oui, NON, Non ,non)
           rec_social_data.amortir,
           rec_social_data.asset_key_ccid,
           'CAPITALIZED',
           rec_social_data.amortissement_cumule,
           rec_social_data.amortissement_exercice,
           'N', -- Amortir la valeur nette
           rec_social_data.date_deb_amort,
           -- Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
           decode(lower(rec_social_data.utilise), 'oui', 'YES', 'NO'),
           decode(rec_social_data.propriete,
                  'En propriété',
                  'OWNED',
                  'LEASED'),
           decode(rec_social_data.achete, 'Neuf', 'NEW', 'USED'),
           rec_social_data.type_amortissement,
           rec_social_data.duree_amortissement,
           rec_social_data.project_id,
           rec_social_data.task_id);
      
        l_step := 'UPDATE';
      
        UPDATE fa_massadd_distributions
           SET units              = rec_social_data.unites,
               deprn_expense_ccid = rec_social_data.deprn_expense_ccid,
               location_id        = rec_social_data.location_id
         WHERE mass_addition_id = l_seq;
      
        UPDATE dka.dka_fa_fusion_immo
           SET statut = gv_statut_ok
         WHERE CURRENT OF cur_social_data;
      
        g_summary.import_rows_social := g_summary.import_rows_social + 1;
      
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log, substr(SQLERRM, 1, 1000));
          g_summary.rejected_rows := g_summary.rejected_rows + 1;
        
      END;
    END LOOP; /* rec_social_data IN Cur_Fiscal_Data */
  
    COMMIT;
  
    fnd_file.put_line(fnd_file.log,
                      'insert_data_social : end : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'insert_data_social : ' || SQLERRM || ':' || l_step;
    
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure insert_data_social : EXCEPTION OTHERS ');
  END insert_data_social;

  /*
   *************************************************************************
   * PROCEDURE NAME : insert_data_IFRS
   *
   * DESCRIPTION
   *  Insertion des données des livrees sociaux dans la table d'interface
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE insert_data_ifrs(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
    -- V1.8    11/04/2017     NBO artf2136811 - REP009 - Import - Charger l'interface de livre de gestion en erreur
    CURSOR cur_ifrs_data IS
      SELECT *
        FROM dka.dka_fa_fusion_immo dk
       WHERE nvl(statut, gv_statut_new) IN (gv_statut_valid)
         AND dk.book_type_code LIKE '%IFRS'
         AND EXISTS
       (SELECT '1'
                FROM fa_additions fa
               WHERE asset_number = dk.numero_immobilisation || '-' ||
                     substr(dk.societe_absorbee, 4)
              UNION ALL
              SELECT '1'
                FROM fa_mass_additions fa
               WHERE asset_number = dk.numero_immobilisation || '-' ||
                     substr(dk.societe_absorbee, 4))
         FOR UPDATE;
  
    --l_seq   NUMBER;
    l_livre VARCHAR2(100);
    l_step  VARCHAR2(50);
    -- V1.8    11/04/2017     NBO artf2136811 - REP009 - Import - Charger l'interface de livre de gestion en erreur
    lv_depreciate_flag VARCHAR2(10);
    ln_cost            NUMBER;
    lv_amortir         VARCHAR2(3);
  
  BEGIN
    p_retcode := 0;
  
    fnd_file.put_line(fnd_file.log,
                      'insert_data_IFRS : start : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));
  
    FOR rec_ifrs_data IN cur_ifrs_data LOOP
    
      SELECT book_type_code
        INTO l_livre
        FROM fa_book_controls
       WHERE book_type_code LIKE rec_ifrs_data.societe || '%'
         AND book_class = 'TAX';
    
      -- V1.8    11/04/2017     NBO artf2136811 - REP009 - Import - Charger l'interface de livre de gestion en erreur
      fnd_file.put_line(fnd_file.log, rec_ifrs_data.numero_immobilisation);
    
      l_step := 'INSERT';
    
      BEGIN
        -- Donnee a inserer dans la table d'interface
        INSERT INTO fa_tax_interface
          (asset_number,
           book_type_code,
           cost,
           created_by,
           creation_date,
           date_placed_in_service,
           depreciate_flag,
           deprn_method_code,
           deprn_reserve,
           last_update_date,
           last_updated_by,
           life_in_months,
           posting_status,
           --prorate_convention_code,
           ytd_deprn)
        VALUES
          (rec_ifrs_data.numero_immobilisation || '-' ||
           substr(rec_ifrs_data.societe_absorbee, 4),
           l_livre,
           rec_ifrs_data.cost,
           fnd_global.user_id,
           SYSDATE,
           rec_ifrs_data.date_de_mise_en_service,
           -- Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
           'YES',
           rec_ifrs_data.type_amortissement,
           rec_ifrs_data.amortissement_cumule,
           SYSDATE,
           fnd_global.user_id,
           rec_ifrs_data.duree_amortissement,
           'POST',
           --'CM_L_01',
           rec_ifrs_data.amortissement_exercice);
      
        UPDATE dka.dka_fa_fusion_immo
           SET statut = gv_statut_ok
         WHERE CURRENT OF cur_ifrs_data;
      
        g_summary.import_rows_ifrs := g_summary.import_rows_ifrs + 1;
      
      EXCEPTION
        WHEN OTHERS THEN
          g_summary.rejected_rows := g_summary.rejected_rows + 1;
        
      END;
    END LOOP; /* rec_IFRS_data IN Cur_IFRS_Data */
  
    COMMIT;
  
    fnd_file.put_line(fnd_file.log,
                      'insert_data_IFRS : end : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'insert_data_IFRS : ' || SQLERRM || ':' || l_step;
    
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure insert_data_IFRS : EXCEPTION OTHERS ');
  END insert_data_ifrs;

  /*
   *************************************************************************
   * PROCEDURE NAME : submit_FNDRSSUB46
   *
   * DESCRIPTION
   *  Soumission du traitement de copie initiale haut volume
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE submit_fndrssub46(p_errbuf         OUT VARCHAR2,
                              p_retcode        OUT NUMBER,
                              p_book_type_code IN fa_book_controls.book_type_code%TYPE) IS
  
    --v_phase      VARCHAR2(100);
    --v_status     VARCHAR2(100);
    --v_dev_phase  VARCHAR2(100);
    --v_dev_status VARCHAR2(100);
    --v_message    VARCHAR2(100);
    b_result       BOOLEAN;
    l_wait_for_req BOOLEAN;
  
    --l_request_set_exist BOOLEAN := FALSE;
    --l_set_mode          BOOLEAN := FALSE;
    --l_conc_prog_submit  BOOLEAN := FALSE;
  
    l_phase      VARCHAR2(100);
    l_status     VARCHAR2(100);
    l_dev_phase  VARCHAR2(100);
    l_dev_status VARCHAR2(100);
    l_message    VARCHAR2(4000);
  
    srs_failed        EXCEPTION;
    submitprog_failed EXCEPTION;
    setmode_failed    EXCEPTION;
    submitset_failed  EXCEPTION;
  
    v_request_id fnd_concurrent_requests.request_id%TYPE;
  
  BEGIN
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début submit_FNDRSSUB46 (' || p_book_type_code || ')');
  
    b_result := fnd_submit.set_request_set(application => 'OFA', -- Application short name
                                           request_set => 'FNDRSSUB46' -- Request set shot name
                                           );
  
    IF (NOT b_result) THEN
      RAISE srs_failed;
    END IF;
  
    b_result := fnd_submit.submit_program('OFA', -- Application short name
                                          'FAMAPT', -- Concurrent program shot name
                                          'STAGE10', -- Stage
                                          p_book_type_code, --parameter for concurrent program
                                          'NORMAL' -- --parameter for concurrent program
                                          );
  
    IF (NOT b_result) THEN
      RAISE submitprog_failed;
    END IF;
  
    b_result := fnd_submit.submit_program('OFA', -- Application short name
                                          'FAS824', -- Concurrent program shot name
                                          'STAGE20', -- Stage
                                          p_book_type_code --parameter for concurrent program,
                                          --,'NORMAL' --v1.7 --parameter for concurrent program
                                          );
    IF (NOT b_result) THEN
      RAISE submitprog_failed;
    END IF;
  
    v_request_id := fnd_submit.submit_set(NULL, FALSE);
  
    IF v_request_id = 0 THEN
      p_retcode := 2;
      fnd_file.put_line(fnd_file.log,
                        'ERREUR : Le traitement d''imputation du livre a échoué' ||
                        chr(10) || 'LIVRE : ' || p_book_type_code ||
                        chr(10));
      fnd_file.put_line(fnd_file.output,
                        '====> ERREUR : Le traitement d''imputation du livre ' ||
                        p_book_type_code || ' a échoué');
    ELSE
      COMMIT;
    
      fnd_file.put_line(fnd_file.output,
                        '. Numéro du traitement la copie initiale haut volume du livre ' ||
                        p_book_type_code || ': ' || v_request_id);
    
      l_wait_for_req := fnd_concurrent.wait_for_request(request_id => v_request_id,
                                                        INTERVAL   => 2,
                                                        max_wait   => 0,
                                                        phase      => l_phase,
                                                        status     => l_status,
                                                        dev_phase  => l_dev_phase,
                                                        dev_status => l_dev_status,
                                                        
                                                        message => l_message);
    END IF;
  
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin submit_FNDRSSUB46 (' || p_book_type_code || ')');
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'submit_FNDRSSUB46 (' || p_book_type_code || '):' ||
                   SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure submit_FNDRSSUB46 (' ||
                        p_book_type_code || ') : EXCEPTION OTHERS ');
  END submit_fndrssub46;

  /*
   *************************************************************************
   * PROCEDURE NAME : submit_faimcp
   *
   * DESCRIPTION
   *  Soumission du traitement de copie initiale haut volume
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE submit_faimcp(p_errbuf         OUT VARCHAR2,
                          p_retcode        OUT NUMBER,
                          p_book_type_code IN fa_book_controls.book_type_code%TYPE) IS
  
    --v_phase      VARCHAR2(100);
    --v_status     VARCHAR2(100);
    --v_dev_phase  VARCHAR2(100);
    --v_dev_status VARCHAR2(100);
    --v_message    VARCHAR2(100);
    --b_result     BOOLEAN;
  
    v_request_id fnd_concurrent_requests.request_id%TYPE;
  
  BEGIN
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début submit_FAIMCP (' || p_book_type_code || ')');
  
    v_request_id := fnd_request.submit_request('OFA' -- APPL
                                              ,
                                               'FAIMCP' -- PROG
                                              ,
                                               NULL -- PROGRAM_NAME
                                              ,
                                               NULL -- START
                                              ,
                                               FALSE -- SUB_REQUEST
                                              ,
                                               p_book_type_code -- Livre fiscal
                                              ,
                                               '"INITIAL"',
                                               1);
  
    IF v_request_id = 0 THEN
      p_retcode := 2;
      fnd_file.put_line(fnd_file.log,
                        'ERREUR : Le traitement de de la copie initiale haut volume du livre a échoué' ||
                        chr(10) || 'LIVRE : ' || p_book_type_code ||
                        chr(10));
      fnd_file.put_line(fnd_file.output,
                        '====> ERREUR :Le traitement de de la copie initiale haut volume du livre ' ||
                        p_book_type_code || ' a échoué');
    ELSE
      COMMIT;
      g_tab_requests(v_request_id) := v_request_id;
    
      fnd_file.put_line(fnd_file.output,
                        '. Numéro du traitement la copie initiale haut volume du livre ' ||
                        p_book_type_code || ': ' || v_request_id);
    END IF;
  
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin submit_FAIMCP (' || p_book_type_code || ')');
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'submit_FAIMCP (' || p_book_type_code || '):' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure submit_FAIMCP (' ||
                        p_book_type_code || ') : EXCEPTION OTHERS ');
  END submit_faimcp;

  /*
   *************************************************************************
   * PROCEDURE NAME : submit_FATAXUP
   *
   * DESCRIPTION
   *  Soumission du traitement d'import des livres fiscaux
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE submit_fataxup(p_errbuf         OUT VARCHAR2,
                           p_retcode        OUT NUMBER,
                           p_book_type_code IN fa_book_controls.book_type_code%TYPE) IS
  
    --v_phase      VARCHAR2(100);
    --v_status     VARCHAR2(100);
    --v_dev_phase  VARCHAR2(100);
    --v_dev_status VARCHAR2(100);
    --v_message    VARCHAR2(100);
    --b_result     BOOLEAN;
  
    v_request_id fnd_concurrent_requests.request_id%TYPE;
  
  BEGIN
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début submit_FATAXUP (' || p_book_type_code || ')');
  
    v_request_id := fnd_request.submit_request('OFA' -- APPL
                                              ,
                                               'FATAXUP' -- PROG
                                              ,
                                               NULL -- PROGRAM_NAME
                                              ,
                                               NULL -- START
                                              ,
                                               FALSE -- SUB_REQUEST
                                              ,
                                               p_book_type_code -- Livre fiscal
                                               );
  
    IF v_request_id = 0 THEN
      p_retcode := 2;
      fnd_file.put_line(fnd_file.log,
                        'ERREUR : Le traitement de chargement du livre fiscal a échoué' ||
                        chr(10) || 'LIVRE : ' || p_book_type_code ||
                        chr(10));
    
      fnd_file.put_line(fnd_file.output,
                        '====> ERREUR :Le traitement de chargement du livre fiscal ' ||
                        p_book_type_code || ' a échoué');
    ELSE
      COMMIT;
    
      g_tab_requests(v_request_id) := v_request_id;
    
      fnd_file.put_line(fnd_file.log,
                        '=> LOAD REQUEST ID= ' || v_request_id);
      fnd_file.put_line(fnd_file.output,
                        '. Numéro du traitement de chargement livre fiscal ' ||
                        p_book_type_code || ': ' || v_request_id);
    END IF;
  
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin submit_FATAXUP (' || p_book_type_code || ')');
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'submit_FATAXUP (' || p_book_type_code || '):' ||
                   SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure submit_FATAXUP (' ||
                        p_book_type_code || ') : EXCEPTION OTHERS ');
  END submit_fataxup;

  ------------------------------------------------------------------------------------
  -- Nom              : Main_import_fa
  -- Description      : Procédure principale d'insertion des immos
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
  PROCEDURE main_import_fa(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
    l_step    VARCHAR2(50);
    v_errbuf  VARCHAR2(2500);
    v_retcode NUMBER;
    erreur_programme EXCEPTION;
  BEGIN
    l_step := 'DEBUT';
  
    dka_tools_pkg.put_outdebug_message('----------------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('    Log des traitements DKA                                          : Import des immos pour fusion des immobilisations');
    dka_tools_pkg.put_outdebug_message('-----------------:------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('');
  
    insert_data_social(p_errbuf, p_retcode);
  
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'SOUMISSION DE L IMPUTATION DES IMMOBILISATIONS');
  
    FOR r_book IN (SELECT DISTINCT book_type_code
                     FROM fa_mass_additions
                    WHERE posting_status = 'POST'
                    ORDER BY 1) LOOP
    
      submit_fndrssub46(v_errbuf, v_retcode, r_book.book_type_code);
    
      IF v_retcode = 2 THEN
        p_errbuf  := v_errbuf;
        p_retcode := v_retcode;
        RAISE erreur_programme;
      END IF;
    END LOOP;
  
    -------------------------------------
    --  SOUMISSION DE LA COPIE INITIALE HAUT VOLUME
    -------------------------------------
    g_tab_requests.delete;
  
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'SOUMISSION DE LA COPIE INITIALE HAUT VOLUME');
  
    FOR r_book IN (SELECT DISTINCT substr(fma.book_type_code, 1, 4) ||
                                   ' IFRS' book_type_code
                     FROM fa_mass_additions fma, dka.dka_fa_fusion_immo dk
                    WHERE fma.posting_status = 'POSTED'
                      AND dk.livre_fa = fma.book_type_code
                         -- Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
                         -- Cette restriction du spécifique doit par conséquent être commentée pour autoriser la création des immos IFRS.
                         -- AND     fma.depreciate_flag = 'YES'
                      AND fma.asset_category_id IN
                          (SELECT DISTINCT fcb.category_id
                             FROM fa_category_books fcb
                             JOIN fa_book_controls fbc
                               ON fcb.book_type_code = fbc.book_type_code
                              AND fbc.book_class = 'TAX')
                      AND NOT EXISTS
                    (SELECT 1
                             FROM fa_additions fa
                             JOIN fa_books fb
                               ON fa.asset_id = fb.asset_id
                             JOIN fa_book_controls fbc
                               ON fb.book_type_code = fbc.book_type_code
                              AND fbc.book_class = 'TAX'
                            WHERE fa.asset_number = fma.asset_number)
                    ORDER BY 1) LOOP
      fnd_file.put_line(fnd_file.log, 'livre=' || r_book.book_type_code);
      submit_faimcp(v_errbuf, v_retcode, r_book.book_type_code);
    
      IF v_retcode = 2 THEN
        p_errbuf  := v_errbuf;
        p_retcode := v_retcode;
        RAISE erreur_programme;
      END IF;
    
    END LOOP;
  
    wait_request(p_errbuf, p_retcode);
  
    insert_data_ifrs(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE erreur_programme;
    END IF;
  
    -- Mise à jour des taxes
    FOR r_book IN (SELECT DISTINCT book_type_code
                     FROM fa_tax_interface
                    WHERE posting_status = 'POST'
                    ORDER BY 1) LOOP
    
      submit_fataxup(v_errbuf, v_retcode, r_book.book_type_code);
    
      IF v_retcode = 2 THEN
        p_errbuf  := v_errbuf;
        p_retcode := v_retcode;
        RAISE erreur_programme;
      END IF;
    
    END LOOP;
  
    wait_request(p_errbuf, p_retcode);
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      p_errbuf  := 'Erreur dans la procécure Main_import_fa : ' || l_step ||
                   ' : ' || SQLCODE || '-' || substr(SQLERRM, 1, 1000);
      p_retcode := 2;
    
      dka_tools_pkg.put_outdebug_message(' ');
      dka_tools_pkg.put_outdebug_message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      dka_tools_pkg.put_outdebug_message('=> TRAITEMENT TERMINE EN ERREUR');
      dka_tools_pkg.put_outdebug_message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      dka_tools_pkg.put_outdebug_message(p_errbuf);
    
  END main_import_fa;

END dka_sfa_fusion_societe_pkg;
/
SHOW ERRORS;
EXIT
