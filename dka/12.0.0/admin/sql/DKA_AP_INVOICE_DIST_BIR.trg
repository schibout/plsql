CREATE OR REPLACE TRIGGER dka_ap_invoice_dist_bir
----------------------------------------------------------------------------------------------
  -- $$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_AP_INVOICE_DIST_BIR.trg
  -- DESCRIPTION       : Trigger sur la table AP_INVOICE_DISTRIBUTIONS_ALL
  ---
  --- AUTEUR           : Xavier Descamps (CG)
  --- DATE DE CREATION : 03/12/2001
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- ---------------------------------------------------------------------------
  --- 24/10/2016 JJA Portage Helios R12
  --- 20/12/2016 MEG artf2065132 : Defect 426 Erreur saisie facture avec rapprochement commande
  --- 31/01/2017 RBE artf2087147 et artf2089590
  --- 13/02/2017 RBE artf2095146
  --- 06/07/2017 MEG artf2191189 : EDB078 LOT1 - Alimentation code Flux pour investissement
  --- 25/05/2018 NBO artf2606902 : SPE022 - trigger refacturation
  --  27/08/2020 MTIA INC0453597 - Rapprochement manuel depuis panneau AP - Test validité de la tache
  --  09/02/2021 NBO TASK0132016 - Etude d'impact mise en place correctif refacturation
  --  11/03/2021 JWY TASK0132016 - Problème d'annulation de lignes sur projet de refac
  ----------------------------------------------------------------------------------------------

  BEFORE INSERT OR UPDATE ON ap.ap_invoice_distributions_all
  FOR EACH ROW

  when (NEW.project_id IS NOT NULL and NEW.task_id IS NOT NULL)
DECLARE
  vv_project_company_code pa_project_classes.class_code%TYPE;
  vv_project_type         pa_project_types_all.project_type%TYPE;
  vv_errbuf               VARCHAR2(500);
  vn_retcode              NUMBER(15);
  vv_step                 VARCHAR2(50);
  vv_invoice_company_code VARCHAR2(20);
  e_error            EXCEPTION;
  project_error      EXCEPTION;
  ctrl_project       EXCEPTION;
  ctrl_project_error EXCEPTION;
  G_LEVEL_STATEMENT       CONSTANT NUMBER := FND_LOG.LEVEL_STATEMENT;
  G_CURRENT_RUNTIME_LEVEL CONSTANT NUMBER := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
  G_MODULE_NAME           CONSTANT VARCHAR2(100) := 'APPS.PLSQL.dka_ap_invoice_dist_bir.';
  l_debug_info VARCHAR2(240);
  l_api_name CONSTANT VARCHAR2(100) := 'Trigger';
  vn_project_id  pa_projects_all.project_id%TYPE;
  vn_task_id     pa_tasks.task_id%TYPE;
  vv_task_number pa_tasks.task_number%TYPE;
  vv_segment1    pa_projects_all.segment1%TYPE;
  pd_date        DATE;

BEGIN
  -- Paliatif de bug Oracle
  IF :NEW.amount IS NULL THEN
    vv_errbuf := 'Erreur de rapprochement.' || CHR(10) ||
                 'Vous avez spécifié une ou plusieurs ligne(s) a rapprocher sans préciser la quantité facturée et/ou le montant a rapprocher.' ||
                 CHR(10) ||
                 'Recommencez votre rapprochement en renseignant toutes les informations obligatoires.';
    RAISE e_error;
  END IF;

  DKA_PA_TOOLS_PKG.get_project_info(pv_errbuf       => vv_errbuf,
                                    pn_retcode      => vn_retcode,
                                    pn_project_id   => :NEW.project_id,
                                    pv_project_soc  => vv_project_company_code,
                                    pv_project_type => vv_project_type);

  SELECT substr(haou.name, 4)
    INTO vv_invoice_company_code
    FROM ap_invoices_all aia, hr_all_organization_units haou
   WHERE aia.invoice_id = :NEW.invoice_id
     AND aia.org_id = haou.organization_id;

  IF vn_retcode != 0 THEN
    RAISE project_error;
  END IF;

  -- Cas des lignes de commande PO
  IF :NEW.po_distribution_id IS NOT NULL
    --- 25/05/2018 NBO artf2606902 : SPE022 - trigger refacturation
     AND INSERTING AND :new.line_type_lookup_code = 'ITEM' THEN
    DECLARE
      po_error EXCEPTION;
      vn_project_id              pa_projects_all.project_id%TYPE;
      vv_project_segment1        pa_projects_all.segment1%TYPE;
      vv_project_name            pa_projects_all.NAME%TYPE;
      vn_task_id                 pa_tasks.task_id%TYPE;
      vv_centre_gestion          VARCHAR2(50);
      vn_vendor_id               po_vendors.vendor_id%TYPE;
      --vn_expenditure_item_id     pa_cost_distribution_lines_all.expenditure_item_id%TYPE;
      vv_vendor_type_lookup_code po_vendors.vendor_type_lookup_code%TYPE;
      vn_ar_seg_rule_id          pa_segment_rule_pairings.rule_id%TYPE;
      vn_vendor_site_id          ap_invoices_all.vendor_site_id%TYPE;
      vv_segment1                gl_code_combinations.segment1%TYPE;
      vv_segment2                gl_code_combinations.segment2%TYPE;
      vv_segment3                gl_code_combinations.segment3%TYPE;
      vv_segment4                gl_code_combinations.segment4%TYPE;
      vv_segment5                gl_code_combinations.segment5%TYPE;
      vv_segment6                gl_code_combinations.segment6%TYPE;
      vv_segment7                gl_code_combinations.segment7%TYPE;
      vv_segment8                gl_code_combinations.segment8%TYPE;
      vv_segment9                gl_code_combinations.segment9%TYPE;
      vv_segment10               gl_code_combinations.segment10%TYPE;
      vv_segment11               gl_code_combinations.segment11%TYPE;
      vv_segment12               gl_code_combinations.segment12%TYPE;
      vn_ccid                    NUMBER(15);
      vd_start_date              date := null; -- MTIA - 27/08/2020 - INC0453597 - Rapprochement manuel depuis panneau AP - Test validité du projet
      vd_end_date                date := null; -- MTIA - 27/08/2020 - INC0453597 - Rapprochement manuel depuis panneau AP - Test validité du projet
    BEGIN
      -- Date de dépense = Date GL
      :NEW.expenditure_item_date := :NEW.accounting_date;
      pd_date                    := :NEW.accounting_date;
    
      --- 25/05/2018 NBO artf2606902 : SPE022 - trigger refacturation
      l_debug_info := 'Controle de coherence des donnees sur le projet';
      -- Récupération de l'identifiant du projet
      BEGIN
        SELECT pt.project_id,
               pt.task_id,
               pp.project_type,
               pp.segment1,
               pt.task_number
          INTO vn_project_id,
               vn_task_id,
               vv_project_type,
               vv_segment1,
               vv_task_number
          FROM pa_tasks pt, pa_projects_all pp
         WHERE pt.project_id = :NEW.project_id
           AND pt.task_id = :NEW.task_id
           AND pt.project_id = pp.project_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vv_errbuf := 'Le couple projet ' || :NEW.project_id ||
                       ' / tâche ' || :NEW.task_id || ' n''existe pas';
          RAISE e_error;
      END;
      -- Vérification de la validité du projet a la date reçue
      BEGIN
        SELECT gps.start_date, gps.end_date
          INTO vd_start_date, vd_end_date
          FROM gl_period_statuses gps
         WHERE gps.application_id = 200
           AND gps.set_of_books_id = :NEW.Set_Of_Books_Id
           AND pd_date BETWEEN trunc(gps.start_date) AND
               trunc(gps.end_date);
      EXCEPTION
        WHEN OTHERS THEN
          vv_errbuf := 'Erreur sur la récupération de la date comptable pour contrôle de la validité du couple projet tache';
          RAISE ctrl_project;
      END;
      -- MTIA - 27/08/2020 - INC0453597 - Rapprochement manuel depuis panneau AP - Test validité du projet
    
      DECLARE
        vn_count NUMBER(15);
      BEGIN
        SELECT COUNT(1)
          INTO vn_count
          FROM pa_projects_all pp
         WHERE pp.project_id = vn_project_id
           and (nvl(pp.completion_date, pd_date) >= pd_date or
               pp.completion_date between vd_start_date and vd_end_date);
      
        IF vn_count = 0 THEN
          vv_errbuf := 'Le projet ' || vv_segment1 ||
                       ' n''est pas valide au ' ||
                       TO_CHAR(pd_date, 'DD/MM/YYYY');
          RAISE ctrl_project;
        END IF;
      END;
    
      -- Vérification de la validité de la tache a la date reçue
      -- MTIA - 27/08/2020 - INC0453597 - Rapprochement manuel depuis panneau AP - Test validité de la tache
      DECLARE
        vn_count NUMBER(15);
      BEGIN
        SELECT COUNT(1)
          INTO vn_count
          FROM pa_tasks pT
         WHERE pt.task_id = vn_task_id
           and (nvl(pt.completion_date, pd_date) >= pd_date or
               pt.completion_date between vd_start_date and vd_end_date);
      
        IF vn_count = 0 THEN
          vv_errbuf := 'La tache ' || vv_task_number ||
                       ' n''est pas valide au ' ||
                       TO_CHAR(pd_date, 'DD/MM/YYYY');
          RAISE ctrl_project;
        END IF;
      END;
    
      -- Controle de coherence des donnees sur le projet
      Dka_pa_Tools_Pkg.pa_check_transaction_data(pv_errbuf           => vv_errbuf,
                                                 pn_retcode          => vn_retcode,
                                                 pn_project_id       => :NEW.project_id,
                                                 pv_expenditure_type => :NEW.expenditure_type,
                                                 pv_event_type       => NULL,
                                                 pd_date             => :NEW.accounting_date,
                                                 pn_tache_id         => :NEW.task_id
                                                 --pv_refac                  => 'N'
                                                 );
      --MTIA le 23/09/2020 - NE pas remonter dans l'erreur si c'est pour projet non valide (controle réalisé au dessus)
      IF vn_retcode != 0 and
         vv_errbuf not like '%' || :NEW.project_id || '%valide%' THEN
        RAISE po_error;
      END IF;
    
      --- 25/05/2018 NBO artf2606902 : SPE022 - trigger refacturation
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      
        FND_LOG.STRING(G_LEVEL_STATEMENT,
                       G_MODULE_NAME || l_api_name,
                       l_debug_info || ' vv_project_company_code : ' ||
                       vv_project_company_code ||
                       ' vv_invoice_company_code : ' ||
                       vv_invoice_company_code);
      END IF;
    
      IF vv_project_company_code != vv_invoice_company_code -- cas de refacturation test sur les company_code
      -- Cas de refacturation sur commande PO
       THEN
        -- Récupération du couple Societe / Centre de gestion
        SELECT gcc.segment2
          INTO vv_centre_gestion
          FROM gl_code_combinations gcc
         WHERE gcc.code_combination_id = :NEW.dist_code_combination_id;
      
        l_debug_info := 'Récupération projet et tache de Refac';
      
        -- Récupération projet et tache de Refac
        Dka_pa_Tools_Pkg.pa_get_code_z_refac(pv_societe        => vv_invoice_company_code,
                                             pv_centre_gestion => vv_centre_gestion,
                                             pv_segment1       => vv_project_segment1,
                                             pn_project_id     => vn_project_id,
                                             pv_project_name   => vv_project_name,
                                             pv_errbuf         => vv_errbuf,
                                             pn_retcode        => vn_retcode);
      
        IF vn_retcode != 0 THEN
          RAISE po_error;
        END IF;
      
        l_debug_info := 'recuperer la tache 1 du projet de refac';
      
        --vn_task_id := :NEW.task_id; --RBE artf2087147
        --RBE artf2087147 : recuperer la tache 1 du projet de refac
        BEGIN
          SELECT task_id
            INTO vn_task_id
            FROM PA_TASKS
           WHERE project_id = vn_project_id
             AND task_number = '1';
        EXCEPTION
          WHEN OTHERS THEN
            vn_task_id := NULL;
        END;
      
        l_debug_info := 'Controle de coherence des donnees sur le projet 2';
      
        -- Controle de coherence des donnees sur le projet
        Dka_pa_Tools_Pkg.pa_check_transaction_data(pv_errbuf           => vv_errbuf,
                                                   pn_retcode          => vn_retcode,
                                                   pn_project_id       => :NEW.project_id,
                                                   pv_expenditure_type => :NEW.expenditure_type,
                                                   pv_event_type       => NULL,
                                                   pd_date             => :NEW.accounting_date,
                                                   pn_tache_id         => :NEW.task_id
                                                   --pv_refac                  => 'Y'
                                                   );
      
        IF vn_retcode != 0 THEN
          RAISE po_error;
        END IF;
      
        -- Stockage des informations
        :NEW.attribute1         := :NEW.project_id;
        :NEW.attribute7         := :NEW.task_id; -- RBE artf2087147
        :NEW.attribute_category := :NEW.set_of_books_id;
        :NEW.project_id         := vn_project_id;
        :NEW.task_id            := vn_task_id;
      
        --  11/03/2021 JWY TASK0132016 - Problème d'annulation de lignes sur projet de refac  
        UPDATE ap_invoice_lines_all aila
           SET aila.attribute1 = :NEW.attribute1,
               aila.attribute7 = :NEW.attribute7
         WHERE aila.invoice_id = :NEW.invoice_id
           AND aila.line_number = :NEW.invoice_line_number
           AND aila.attribute1 IS NULL
           AND aila.attribute7 IS NULL;
      
      END IF;
    
      l_debug_info := 'Calcul de l''organisation de dépense';
    
      -- Calcul de l'organisation de dépense
      SELECT carrying_out_organization_id
        INTO :NEW.expenditure_organization_id
        FROM pa_projects_all ppa
       WHERE ppa.project_id = :NEW.project_id;
    
      -- ********* CALCUL DES SEGMENTS DE LA CLE COMPTABLE **************--
    
      l_debug_info := 'Segment1';
    
      -- Segment1
      vv_step := 'DKA_AP_INVOICE_DIST_BIR.generate_ccid - 01';
      BEGIN
        SELECT substr(haou.name, 4), substr(haou.name, 1, 3)
          INTO vv_segment1, vv_segment2
          FROM pa_projects_all ppa, hr_all_organization_units haou
         WHERE ppa.project_id = :NEW.project_id
           and haou.organization_id = ppa.org_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vv_segment1 := NULL;
          vv_segment2 := NULL;
      END;
    
      IF vv_segment1 IS NULL THEN
        vv_errbuf := 'ERREUR récupération segment1; project_id=' ||
                     TO_CHAR(:NEW.project_id) || '; date=' ||
                     TO_CHAR(:NEW.accounting_date, 'DD/MM/YYYY');
        RAISE po_error;
      END IF;
    
      -- Segment3
      vv_step := 'DKA_AP_INVOICE_DIST_BIR.generate_ccid - 03';
      --RBE artf2089590
      /*
      Dka_pa_Tools_Pkg.pa_run_accounting_rule (
          pv_rule_name              => 'CPT_LOCAL_COUTS',
          pv_expenditure_type       => :NEW.expenditure_type,
          pv_segment_value          => vv_segment3,
          pv_errbuf                 => vv_errbuf,
          pn_retcode                => vn_retcode
      );
      
      IF vn_retcode != 0
      THEN
          vv_errbuf    := 'ERREUR récupération segment3; expn_type=' || :NEW.expenditure_type;
          RAISE po_error;
      END IF;
      */
      l_debug_info := 'Segment3';
    
      vv_segment3 := DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts(:NEW.project_id,
                                                               :NEW.expenditure_type,
                                                               :NEW.task_id);
    
      -- Segment4
      l_debug_info := 'Segment4';
      vv_step      := 'DKA_AP_INVOICE_DIST_BIR.generate_ccid - 04';
      --- 25/05/2018 NBO artf2606902 : SPE022 - trigger refacturation
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      
        FND_LOG.STRING(G_LEVEL_STATEMENT,
                       G_MODULE_NAME || l_api_name,
                       l_debug_info || ' vv_project_type : ' ||
                       vv_project_type || ' vn_project_id : ' ||
                       vn_project_id || ' vv_invoice_company_code : ' ||
                       vv_invoice_company_code);
      END IF;
    
      IF (vv_project_type = 'REFAC' AND vn_project_id IS NOT NULL) THEN
        --AND NVL(:NEW.attribute1,:OLD.attribute1) IS NOT NULL) THEN
      
        -- 11/03/2021 JWY TASK0132016 - Problème d'annulation de lignes sur projet de refac      
        vv_segment4 := Dka_Spaautoaccounting_Pkg.Run_Cpt_Groupe_Couts_f(pn_project_id       => vn_project_id, -- project_id refac
                                                                        pv_expenditure_type => :NEW.expenditure_type,
                                                                        --  09/02/2021 NBO TASK0132016 - Etude d'impact mise en place correctif refacturation
                                                                        pn_expenditure_item_id => NULL,
                                                                        pn_task_id             => vn_task_id, -- task_id refac
                                                                        --  11/03/2021 JWY TASK0132016 - Etude d'impact mise en place correctif refacturation
                                                                        pn_refac_project_id => :NEW.attribute1 -- projet à refacturer
                                                                        );
      
      ELSE
        vv_segment4 := Dka_Spaautoaccounting_Pkg.run_cpt_groupe_couts_f(pn_project_id       => :NEW.project_id,
                                                                        pv_expenditure_type => :NEW.expenditure_type,
                                                                        pn_task_id          => :NEW.task_id,
                                                                        pn_refac_project_id => :NEW.attribute1);
      END IF;
    
      IF vv_segment4 IS NULL THEN
        vv_errbuf := 'ERREUR récupération segment4; project_id=' ||
                     TO_CHAR(:NEW.project_id) || '; expn_type=' ||
                     :NEW.expenditure_type || '; refac_proj_id=' ||
                     :NEW.attribute1 || '; date=' ||
                     TO_CHAR(:NEW.accounting_date, 'DD/MM/YYYY');
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        
          FND_LOG.STRING(G_LEVEL_STATEMENT,
                         G_MODULE_NAME || l_api_name,
                         l_debug_info || ' vv_errbuf : ' || vv_errbuf);
        END IF;
        RAISE po_error;
      END IF;
    
      -- Segment5 -- PHENIX 2004
      vv_step := 'DKA_AP_INVOICE_DIST_BIR.generate_ccid - 05';
    
      -- Détermination du Type de fournisseur
      l_debug_info := 'Détermination du Type de fournisseur';
      SELECT vendor_site_id
        INTO vn_vendor_site_id
        FROM ap_invoices_all aia
       WHERE aia.invoice_id = :NEW.invoice_id;
    
      l_debug_info := 'Segment5';
    
      vv_segment5 := Dka_Spaautoaccounting_Pkg.code_interco(pn_project_id    => :NEW.project_id,
                                                            pn_id_site_fourn => vn_vendor_site_id);
    
      IF vv_segment5 IS NULL -- PHENIX 2004
       THEN
        vv_errbuf := 'ERREUR récupération segment5; vendor_id=' ||
                     TO_CHAR(vn_vendor_id) || '; vendor_type=' ||
                     vv_vendor_type_lookup_code;
        RAISE po_error;
      END IF;
    
      -- Segment6 -- PHENIX 2004
      l_debug_info := 'Segment6';
      vv_step      := 'DKA_APXIIMPT_DEBUG.generate_ccid - 06';
      SELECT DISTINCT psrp.rule_id
        INTO vn_ar_seg_rule_id
        FROM pa_segment_rule_pairings psrp
       WHERE psrp.application_id = 275
         AND psrp.function_code = 'GER'
         AND psrp.function_transaction_code = 'WRITE-ON'
         AND psrp.segment_num = 6 - 1 -- Numerotation a partir de 0
         AND psrp.org_id = :NEW.org_id;
    
      DKA_PA_TOOLS_PKG.pa_run_accounting_rule(pn_rule_id       => vn_ar_seg_rule_id,
                                              pv_event_type    => NULL,
                                              pn_project_id    => :NEW.project_id,
                                              pv_segment_value => vv_segment6,
                                              pv_errbuf        => vv_errbuf,
                                              pn_retcode       => vn_retcode);
    
      IF vv_segment6 IS NULL THEN
        vv_errbuf := 'ERREUR récupération segment6; project_id=' -- PHENIX 2004
                     || TO_CHAR(:NEW.project_id) || '; date=' ||
                     TO_CHAR(:NEW.accounting_date, 'DD/MM/YYYY');
        RAISE po_error;
      END IF;
    
      -- Segment7 -- PHENIX 2004
      l_debug_info := 'Segment7';
      vv_step      := 'DKA_APXIIMPT_DEBUG.generate_ccid - 07';
      DKA_PA_TOOLS_PKG.pa_run_accounting_rule(pv_rule_name     => 'AFFAIRE', --'CODE_D',
                                              pn_project_id    => :NEW.project_id,
                                              pv_segment_value => vv_segment7,
                                              pv_errbuf        => vv_errbuf,
                                              pn_retcode       => vn_retcode);
    
      IF vn_retcode != 0 THEN
        Dka_Tools_Pkg.put_debug_message('>>>>>> ' || vv_errbuf);
        vv_errbuf := 'ERREUR récupération segment7; expn_type=' ||
                     vv_segment7; -- PHENIX 2004
        RAISE po_error;
      END IF;
    
      -- Segment8  PHENIX 2004
      l_debug_info := 'Segment8';
      vv_step      := 'DKA_APXIIMPT_DEBUG.generate_ccid - 08';
      SELECT DISTINCT psrp.rule_id
        INTO vn_ar_seg_rule_id
        FROM pa_segment_rule_pairings psrp
       WHERE psrp.application_id = 275
         AND psrp.function_code = 'GER'
         AND psrp.function_transaction_code = 'WRITE-ON'
         AND psrp.segment_num = 8 - 1 -- Numerotation a partir de 0
         AND psrp.org_id = :NEW.org_id;
    
      DKA_PA_TOOLS_PKG.pa_run_accounting_rule(pn_rule_id       => vn_ar_seg_rule_id,
                                              pv_event_type    => NULL,
                                              pn_project_id    => :NEW.project_id,
                                              pv_segment_value => vv_segment8,
                                              pv_errbuf        => vv_errbuf,
                                              pn_retcode       => vn_retcode);
    
      IF vv_segment8 IS NULL THEN
        vv_errbuf := 'ERREUR récupération segment8; project_id=' -- PHENIX2004
                     || TO_CHAR(:NEW.project_id);
        RAISE po_error;
      END IF;
    
      -- Segment9
      l_debug_info := 'Segment9';
      vv_step      := 'DKA_APXIIMPT_DEBUG.generate_ccid - 09';
      Dka_pa_Tools_Pkg.pa_run_accounting_rule(pv_rule_name     => 'FLUX',
                                              pn_project_id    => :NEW.project_id,
                                              pv_segment_value => vv_segment9,
                                              pv_errbuf        => vv_errbuf,
                                              pn_retcode       => vn_retcode);
    
      IF vn_retcode != 0 THEN
        Dka_Tools_Pkg.put_debug_message('>>>>>> ' || vv_errbuf);
        vv_errbuf := 'ERREUR récupération segment9;';
        RAISE po_error;
      END IF;
    
      -- Segment10
      l_debug_info := 'Segment10';
      vv_step      := 'DKA_APXIIMPT_DEBUG.generate_ccid - 10';
      Dka_Pa_Tools_Pkg.pa_run_accounting_rule(pv_rule_name     => 'NON_SIGNIFICATIF',
                                              pv_segment_value => vv_segment10,
                                              pv_errbuf        => vv_errbuf,
                                              pn_retcode       => vn_retcode);
    
      -- Segment11
      l_debug_info := 'Segment11';
      vv_step      := 'DKA_APXIIMPT_DEBUG.generate_ccid - 10';
      Dka_Pa_Tools_Pkg.pa_run_accounting_rule(pv_rule_name     => 'NON_SIGNIFICATIF',
                                              pv_segment_value => vv_segment11,
                                              pv_errbuf        => vv_errbuf,
                                              pn_retcode       => vn_retcode);
    
      -- Segment12
      l_debug_info := 'Segment12';
      vv_step      := 'DKA_APXIIMPT_DEBUG.generate_ccid - 10';
      Dka_Pa_Tools_Pkg.pa_run_accounting_rule(pv_rule_name     => 'NON_SIGNIFICATIF',
                                              pv_segment_value => vv_segment12,
                                              pv_errbuf        => vv_errbuf,
                                              pn_retcode       => vn_retcode);
    
      IF vn_retcode != 0 THEN
        Dka_Tools_Pkg.put_debug_message('>>>>>> ' || vv_errbuf);
        vv_errbuf := 'ERREUR récupération segment10;';
        RAISE po_error;
      END IF;
      -- FIN PHENIX 2004
    
      -- Génération du ccid
      l_debug_info := 'Génération du ccid';
      Dka_Tools_Pkg.get_code_combination_id(pv_segment1            => vv_segment1,
                                            pv_segment2            => vv_segment2,
                                            pv_segment3            => vv_segment3,
                                            pv_segment4            => vv_segment4,
                                            pv_segment5            => vv_segment5,
                                            pv_segment6            => vv_segment6,
                                            pv_segment7            => vv_segment7,
                                            pv_segment8            => vv_segment8,
                                            pv_segment9            => vv_segment9,
                                            pv_segment10           => vv_segment10,
                                            pv_segment11           => vv_segment11,
                                            pv_segment12           => vv_segment12,
                                            pn_code_combination_id => vn_ccid,
                                            pv_errbuf              => vv_errbuf,
                                            pn_retcode             => vn_retcode);
    
      IF vn_retcode != 0 THEN
        vv_errbuf := 'ERREUR récupération ccid;' || CHR(10) || vv_errbuf;
        RAISE po_error;
      END IF;
    
      -- Affectation du nouveau ccid
      :NEW.dist_code_combination_id := vn_ccid;
    
    EXCEPTION
      WHEN po_error THEN
        RAISE project_error;
        --  27/08/2020 MTIA INC0453597 - Rapprochement manuel depuis panneau AP - Test validité de la tache
      WHEN ctrl_project THEN
        RAISE ctrl_project_error;
    END;
  END IF;

  -- RBE artf2095146 : cette partie ne sert plus
  /*
    -- Gestion du projet a refacturer dans le champ Award_Id
    -- IF    vn_project_org_id != :NEW.org_id  PHENIX 2004
  IF vv_project_company_code != vv_invoice_company_code  -- PHENIX 2004
       OR vv_project_type = 'REFAC'
    THEN
        IF     :NEW.attribute1 IS NOT NULL
           AND :NEW.award_id IS NULL
        THEN
            :NEW.award_id    := TO_NUMBER (:NEW.attribute1);
        ELSIF     :NEW.attribute1 IS NULL
              AND :NEW.award_id IS NOT NULL
        THEN
            :NEW.attribute1             := TO_CHAR (:NEW.award_id);
            :NEW.attribute_category     := :NEW.set_of_books_id; -- CDE 290808
        END IF;
    END IF;
  */ -- Fin RBE
EXCEPTION
  WHEN project_error THEN
    /*BEGIN
        -- Calcul du ccid
        SELECT gcc.code_combination_id
        INTO   :NEW.dist_code_combination_id
        FROM   gl_code_combinations gcc
        WHERE      gcc.segment1 = 'XXXX'
               AND gcc.segment2 = 'XXX'
               AND gcc.segment3 = 'ERREUR'
               AND gcc.segment4 = '0'
               AND gcc.segment5 = '0'
               AND gcc.segment6 = '0'
               AND gcc.segment7 = '0'
               AND gcc.segment8 = '0'
               AND gcc.segment9 = '0'  --  PHENIX 2004
               AND gcc.segment10 = '0'; --  PHENIX 2004
    
    EXCEPTION
        WHEN OTHERS
        THEN
            vv_errbuf   := 'Impossible de déterminer la clé d''erreur.' || CHR (10) || CHR (10);
            App_Exception.raise_exception (exception_text => vv_errbuf);
    END;*/
    --- 25/05/2018 NBO artf2606902 : SPE022 - trigger refacturation
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    
      FND_LOG.STRING(G_LEVEL_STATEMENT,
                     G_MODULE_NAME || l_api_name,
                     l_debug_info || ' project_id:' || :new.project_id ||
                     ' Task_id:' || :new.task_id || ' Expenditure_type:' ||
                     :new.expenditure_type || ' vv_invoice_company_code : ' ||
                     vv_invoice_company_code || ' line_type_lookup_code:' ||
                     :new.line_type_lookup_code);
    END IF;
  
    :NEW.dist_code_combination_id := NULL;
    --  27/08/2020 MTIA INC0453597 - Rapprochement manuel depuis panneau AP - Test validité de la tache
  WHEN ctrl_project_error THEN
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    
      FND_LOG.STRING(G_LEVEL_STATEMENT,
                     G_MODULE_NAME || l_api_name,
                     l_debug_info || ' project_id:' || :new.project_id ||
                     ' Task_id:' || :new.task_id || ' Expenditure_type:' ||
                     :new.expenditure_type || ' vv_invoice_company_code : ' ||
                     vv_invoice_company_code || ' line_type_lookup_code:' ||
                     :new.line_type_lookup_code);
    END IF;
  
    :NEW.dist_code_combination_id := NULL;
  
    vv_errbuf := CHR(10) || CHR(10) || vv_errbuf || CHR(10) || CHR(10) ||
                 CHR(10) || CHR(10) || CHR(10);
    /*App_Exception.raise_exception (exception_code => -20500,
    exception_text => vv_errbuf);*/
  
    raise_application_error(-20000, NVL(vv_errbuf, vv_step));
  
  WHEN e_error THEN
    vv_errbuf := CHR(10) || CHR(10) || vv_errbuf || CHR(10) || CHR(10) ||
                 CHR(10) || CHR(10) || CHR(10);
    App_Exception.raise_exception(exception_text => vv_errbuf);
  WHEN OTHERS THEN
    --raise_application_error (-20500, NVL (vv_errbuf, vv_step));
    App_Exception.raise_exception(exception_text => NVL(vv_errbuf, vv_step));
END;
/
SHOW ERRORS
EXIT;
