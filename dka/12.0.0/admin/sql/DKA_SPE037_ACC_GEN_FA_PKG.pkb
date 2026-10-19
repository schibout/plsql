create or replace package body apps.DKA_SPE037_ACC_GEN_FA_PKG is
  ----------------------------------------------------------------------------------------------
  -- NOM               : DKA_SPE037_ACC_GEN_FA_PKG.pkb
  -- DESCRIPTION       : DKA_SPE037_ACC_GEN_FA_PKG package body : composant wf account generator FA
  ---
  --- AUTEUR           : NBOUSSEKEYT
  --- DATE DE CREATION : 05/10/2016
  --- DOC. ASSOCIEE    :
  ---
  ----------------------------------------------------------------------------------------------
  --- NOM DU PROGRAMME :
  --- PARAMETRES       :
  ---
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --  05/10/2016 NBO Création
  --  11/07/2017 NBO artf2194571 - SPE037 - Correction de l'account generator FA
  --  31/10/2017 NBO artf2251137 - SPE037 Générateur de comptes dans FA - Alimentation du compte groupe suivant la destination du projet
  --  31/10/2017 NBO artf2268989 - SPE037 et SPE205 - La transco MIGR_GROUP_ACCOUNT_CLASS_BILAN ne doit effectivement contenir que des comptes de bilan
  --  19/04/2018 NBO artf2544795 : INC0202347 clés comptables générées par FA
  --  11/04/2025 ARA EDB425 - Evolution WF Générateur de compte FA - Ajout d une nouvelle destination SOP
  --------------------------------------------------------------------------------------------
  -----------------------------------------------------------------
  --  Variables globales
  -----------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  -------------------------------------------------------------------------------------
  --  Nom           : INIT
  --  Description   : Procedure d'initialisation des item_attributes
  --
  --  PARAMETRES    :
  --     itemtype                 Entree          Identifiant du workflow
  --     itemkey                  Entree          Identifiant du process en cours d'execution
  --     actid                    Entree          Id de l'activite du process ayant appele cette procedure
  --     funcmode                 Entree          Mode de fonctionnement du workflow : doit être à 'RUN'
  --     result                   Sortie          Valeur retournee à l'activite du process : 'SUCCESS' ou 'FAILURE'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ------------------------------------------------------------------------------------
  PROCEDURE init(itemtype IN VARCHAR2,
                 itemkey  IN VARCHAR2,
                 actid    IN NUMBER,
                 funcmode IN VARCHAR2,
                 RESULT   OUT VARCHAR2) IS
    e_error EXCEPTION;
    x_progress VARCHAR2(100);
  
    vn_distribution_id    fa_distribution_history.distribution_id%TYPE;
    vn_asset_id           NUMBER;
    vn_project_id         pa_projects_all.project_id%TYPE;
    --  11/07/2017 NBO artf2194571 - SPE037 - Correction de l'account generator FA
    vn_project_id_parent  pa_projects_all.project_id%TYPE;
    vd_fa_date            DATE;
    vv_book_type_code     fa_books.book_type_code%TYPE;
    vv_account_type       VARCHAR2(50);
    vv_errbuf             VARCHAR2(150);
    vv_code_affaire       VARCHAR2(150);
    vv_code_projet_parent VARCHAR2(150);
    --  11/07/2017 NBO artf2194571 - SPE037 - Correction de l'account generator FA
    vv_region             VARCHAR2(10);
  
    vn_retcode           NUMBER;
    vn_task_id           NUMBER;
    vv_project_soc       VARCHAR2(50);
    vv_project_type      VARCHAR2(50);
    vn_distribution_ccid NUMBER;
    vn_default_ccid      NUMBER;
    --  11/07/2017 NBO artf2194571 - SPE037 - Correction de l'account generator FA  
    vn_account_ccid      NUMBER;
    vn_deprn_expense_account_ccid NUMBER;
    vv_local_account     VARCHAR2(50);
    vv_group_account     VARCHAR2(50);
    vv_destination       VARCHAR2(50);
    vv_categ_group_account VARCHAR2(50);
    vv_class               VARCHAR2(50);
    vv_tax                 VARCHAR2(1);
    vv_bc_attr1          VARCHAR2(50);
    vv_bc_attr2          VARCHAR2(50);
    vv_bc_attr3          VARCHAR2(50);
    vv_property_type_code VARCHAR2(50);
    vv_flex_account_type VARCHAR2(50);
  
  BEGIN
    x_progress := 'DKA_SPE037_ACC_GEN_FA_PKG.INIT : Debut';
    dbms_output.put_line('>>> Debug >>> DEBUT INIT');
  
    ----- Do nothing in cancel or timeout mode -----
    IF (funcmode != wf_engine.eng_run) THEN
      RESULT := wf_engine.eng_null;
      RETURN;
    END IF;
  
    --
    -- Recuperation des Item_Attribute
    --
    x_progress := 'DKA_SPE037_ACC_GEN_FA_PKG.INIT : Get_Item_Attributes';
    -- Recuperation du Distribution_Id
    vn_distribution_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                      itemkey  => itemkey,
                                                      aname    => 'DISTRIBUTION_ID');
    dbms_output.put_line('>>> Debug >>> vn_distribution_id: ' ||
                         to_char(vn_distribution_id));
  
    -- Recuperation du Book_Type_Code
    vv_book_type_code := wf_engine.getitemattrtext(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'BOOK_TYPE_CODE');
    dbms_output.put_line('>>> Debug >>> vv_book_type_code: ' ||
                         vv_book_type_code);
  
    vn_distribution_ccid := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                        itemkey  => itemkey,
                                                        aname    => 'DISTRIBUTION_CCID');
    dbms_output.put_line('>>> Debug >>> DISTRIBUTION_CCID: ' || vn_distribution_ccid);
  
    
    vn_default_ccid := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                        itemkey  => itemkey,
                                                        aname    => 'DEFAULT_CCID');
    dbms_output.put_line('>>> Debug >>> DEFAULT_CCID: ' || vn_default_ccid);                                                   
                                                                
    --  11/07/2017 NBO artf2194571 - SPE037 - Correction de l'account generator FA                                                        
    vn_account_ccid := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                        itemkey  => itemkey,
                                                        aname    => 'ACCOUNT_CCID');
    dbms_output.put_line('>>> Debug >>> ACCOUNT_CCID: ' || vn_account_ccid);     
    --  11/07/2017 NBO artf2194571 - SPE037 - Correction de l'account generator FA
    vv_local_account := wf_engine.getitemattrtext(itemtype => itemtype,
                                                        itemkey  => itemkey,
                                                        aname    => 'ACCT_SEG_VAL');
    dbms_output.put_line('>>> Debug >>> ACCT_SEG_VAL: ' || vv_local_account);   
    
                                                          
                                                          
                                       
    --
    -- Calcul des donnees
    --
    x_progress := 'DKA_SPE037_ACC_GEN_FA_PKG.INIT : Calcul donnees';
    -- Recupère l'identifiant de l'immo
    SELECT asset_id
      INTO vn_asset_id
      FROM fa_distribution_history
     WHERE distribution_id = vn_distribution_id;
    dbms_output.put_line('>>> Debug >>> vn_asset_id: ' ||
                         to_char(vn_asset_id));
  
    -- Recuperation du projet
    BEGIN
      SELECT DISTINCT project_id, task_id
        INTO vn_project_id, vn_task_id
        FROM fa_asset_invoices
       WHERE asset_id = vn_asset_id;
    EXCEPTION
      WHEN too_many_rows THEN
        x_progress := 'No project found';
        RAISE e_error;
      WHEN OTHERS THEN
        vn_project_id := NULL;
        vn_task_id    := NULL;
    END;
    dbms_output.put_line('>>> Debug >>> vn_project_id: ' ||
                         to_char(vn_project_id));
    dbms_output.put_line('>>> Debug >>> vn_task_id: ' ||
                         to_char(vn_task_id));
  
    IF vn_project_id IS NOT NULL THEN
    
      /*dka_pa_tools_pkg.get_project_info(pv_errbuf           => vv_errbuf,
      pn_retcode          => vn_retcode,
      pn_project_id       => vn_project_id,
      pv_project_segment1 => NULL,
      pv_project_soc      => vv_project_soc,
      pv_project_type     => vv_project_type);*/
      
      --  11/07/2017 NBO artf2194571 - SPE037 - Correction de l'account generator FA
      SELECT fcb.deprn_expense_account_ccid
      INTO vn_deprn_expense_account_ccid
      FROM fa_additions_b fab, fa_category_books fcb
      WHERE asset_id = vn_asset_id
       AND fab.asset_category_id = fcb.category_id
       AND fcb.book_type_code = vv_book_type_code;
       
       dbms_output.put_line('>>> Debug >>> vn_deprn_expense_account_ccid: ' ||
                         to_char(vn_deprn_expense_account_ccid));
        
       wf_engine.setitemattrnumber(itemtype,
                                itemkey,
                                'DKA_DEPRN_EXPENSE_ACC_CCID',
                                vn_deprn_expense_account_ccid);
      
      vv_region := DKA_SPAAUTOACCOUNTING_PKG.uo_projet(vn_project_id);
      
      wf_engine.setitemattrtext(itemtype,
                                itemkey,
                                'DKA_REGION',
                                vv_region);
    
      wf_engine.setitemattrnumber(itemtype => itemtype,
                                  itemkey  => itemkey,
                                  aname    => 'DKA_PROJECT_ID',
                                  avalue   => vn_project_id);
    
      wf_engine.setitemattrnumber(itemtype => itemtype,
                                  itemkey  => itemkey,
                                  aname    => 'DKA_TASK_ID',
                                  avalue   => vn_task_id);
      --  11/07/2017 NBO artf2194571 - SPE037 - Correction de l'account generator FA                            
      select pp.project_id, pp.segment1
      into vn_project_id_parent, vv_code_projet_parent
      from pa_tasks pt, pa_projects_all pp
      where pt.task_id IN
         (select attribute7 from pa.pa_tasks where task_id = vn_task_id)
      and pt.PROJECT_ID = pp.project_id;
      
      
      dbms_output.put_line('>>> Debug >>> vv_code_projet_parent: ' ||
                         to_char(vv_code_projet_parent));
      
      wf_engine.setitemattrtext(itemtype,
                                itemkey,
                                'DKA_PROJET_FINANCE',
                                vv_code_projet_parent);
      
      dbms_output.put_line('>>> Debug >>> vn_project_id_parent: ' ||
                         to_char(vn_project_id_parent));
    
      vv_code_affaire := dka_pa_tools_pkg.get_class_project(fn_project_id     => vn_project_id_parent,
                                                            fv_class_category => 'AFFAIRE');
                                                            
      dbms_output.put_line('>>> Debug >>> vv_code_affaire: ' ||
                   to_char(vv_code_affaire));
                   
      wf_engine.setitemattrtext(itemtype,
                          itemkey,
                          'DKA_CODE_AFFAIRE',
                          vv_code_affaire);
                   
      -- Récupération du centre financier (organisation du projet PA)
      vv_project_soc := dka_pa_tools_pkg.get_centre_finance(vn_project_id_parent, SYSDATE);
      
      wf_engine.setitemattrtext(itemtype,
                          itemkey,
                          'DKA_CENTRE_FINANCE',
                          vv_project_soc);
      
      --  31/10/2017 NBO artf2251137 - SPE037 Générateur de comptes dans FA - Alimentation du compte groupe suivant la destination du projet
      vv_destination := dka_pa_tools_pkg.get_class_project(fn_project_id     => vn_project_id_parent,
                                                            fv_class_category => 'DESTINATION');
                                                            
      dbms_output.put_line('>>> Debug >>> vv_destination: ' ||
                   to_char(vv_destination));
                   
      wf_engine.setitemattrtext(itemtype,
                          itemkey,
                          'DKA_DESTINATION',
                          vv_destination);     
     
      SELECT CASE vv_destination
               WHEN 'CDV' THEN
                fc.attribute1
               WHEN 'COM' THEN
                fc.attribute2
               WHEN 'SGA' THEN
                fc.attribute3
               WHEN 'SOP' THEN --ARA EDB425
                fc.attribute8
             END
        INTO vv_categ_group_account
        FROM fa_additions_b fab, fa_categories fc
       WHERE asset_id = vn_asset_id
         AND fab.asset_category_id = fc.category_id;
      
       dbms_output.put_line('>>> Debug >>> vv_categ_group_account: ' ||
                   to_char(vv_categ_group_account));
              
      wf_engine.setitemattrtext(itemtype,
                          itemkey,
                          'DKA_CATEG_CPT_GROUPE',
                          vv_categ_group_account); 
                          
      
      select book_class, attribute1, attribute2, attribute3 into vv_class, vv_bc_attr1, vv_bc_attr2, vv_bc_attr3
      from FA_BOOK_CONTROLS where book_type_code = vv_book_type_code;
      
      vv_flex_account_type := wf_engine.getItemAttrText(itemtype => itemtype,
                                itemkey  => itemkey,
                                aname    =>'ACCOUNT_TYPE');
      
      IF vv_class != 'TAX' THEN                 
      
        SELECT fc.property_type_code
          INTO vv_property_type_code
          FROM fa_additions_b fab, fa_categories fc
         WHERE asset_id = vn_asset_id
           AND fab.asset_category_id = fc.category_id; 
      
        IF vv_property_type_code  = 'INCORPOREL' THEN
          
          dbms_output.put_line('>>> Debug >>> vv_property_type_code: ' || vv_property_type_code); 
          dbms_output.put_line('>>> Debug >>> vv_flex_account_type: ' || vv_flex_account_type); 
          
          IF vv_flex_account_type =  'POS_GAIN'  -- Plus-value de produit de cession
            OR vv_flex_account_type = 'POS_LOSS'  -- Moins-value de produit de cession
          THEN
            vv_local_account := vv_bc_attr1;
          ELSIF vv_flex_account_type = 'COR_GAIN' -- Plus-value de coût de cession
            OR vv_flex_account_type = 'COR_LOSS' -- Moins-value de coût de cession
          THEN
            vv_local_account := vv_bc_attr2;
          ELSIF vv_flex_account_type = 'NBV_GAIN' -- Plus-value de valeur comptable nette cédée
            OR vv_flex_account_type = 'NBV_LOSS' -- Moins-value de valeur comptable nette cédée
          THEN
            vv_local_account := vv_bc_attr3;
          END IF;
            
          wf_engine.setitemattrtext(itemtype, itemkey, 'ACCT_SEG_VAL', vv_local_account);
          dbms_output.put_line('>>> Debug >>> INCORPOREL ACCT_SEG_VAL: ' || vv_local_account); 
        END IF;
      END IF;
      
  END IF;
  
    --IF vn_distribution_ccid IS NOT NULL THEN
  --  11/07/2017 NBO artf2194571 - SPE037 - Correction de l'account generator FA
    IF vv_local_account IS NOT NULL THEN
      /*SELECT segment3
        INTO vv_local_account
        FROM gl_code_combinations gg
       WHERE code_combination_id = vn_default_ccid;*/
    
      --  31/10/2017 NBO artf2268989 - SPE037 et SPE205 - La transco MIGR_GROUP_ACCOUNT_CLASS_BILAN ne doit effectivement contenir que des comptes de bilan
      --vv_group_account := dka_stransco_pkg.get_value_f(pv_set_name => 'MIGR_GROUP_ACCOUNT_CLASS_BILAN',
      vv_group_account := dka_stransco_pkg.get_value_f(pv_set_name => 'DKA_TRANSCO_LOCAL_GROUPE',
                                                       pd_date     => SYSDATE,
                                                       pv_errbuf   => vv_errbuf,
                                                       pv_param1   => vv_local_account);
      dbms_output.put_line('vv_group_account : ' || vv_group_account);
      
      wf_engine.setitemattrtext(itemtype,
                                itemkey,
                                'DKA_COMPTE_GROUPE',
                                vv_group_account);
    END IF;

    --
    -- Affectation des valeurs aux Item_Attribute
    --
    x_progress := 'DKA_SPE037_ACC_GEN_FA_PKG.INIT : Put_Item_Attributes';
    wf_engine.setitemattrnumber(itemtype => itemtype,
                                itemkey  => itemkey,
                                aname    => 'DKA_ASSET_ID',
                                avalue   => vn_asset_id);
   
    --  19/04/2018 NBO  artf2544795 : INC0202347 clés comptables générées par FA
    x_progress := 'DKA_SPE037_ACC_GEN_FA_PKG.INIT : est ce un livre IFRS ?'; 
    
    select book_class into vv_class
    from FA_BOOK_CONTROLS where book_type_code = vv_book_type_code;
    
    IF vv_class = 'TAX' THEN
      vv_tax := 'Y';
    ELSE
      vv_tax  := 'N';
    END IF;
    
    wf_engine.setitemattrtext(itemtype => itemtype,
                            itemkey  => itemkey,
                            aname    => 'DKA_IS_TAX_BOOK',
                            avalue   => vv_tax);   
  
    RESULT := 'COMPLETE:';
    dbms_output.put_line('>>> Debug >>> FIN INIT');
    RETURN;
  EXCEPTION
    WHEN e_error THEN
      wf_engine.setitemattrtext(itemtype => itemtype,
                                itemkey  => itemkey,
                                aname    => 'ERROR_MESSAGE',
                                avalue   => fnd_message.get_encoded);
      RESULT := 'COMPLETE:FAILURE';
      wf_core.CONTEXT('DKA_SPE037_ACC_GEN_FA_PKG', 'INIT', x_progress);
      dbms_output.put_line('>>> Debug >>> ' || x_progress ||
                           ' >>> ERREUR: ' || SQLERRM);
      RAISE;
    
    WHEN OTHERS THEN
      wf_core.CONTEXT('DKA_SPE037_ACC_GEN_FA_PKG', 'INIT', x_progress);
      dbms_output.put_line('>>> Debug >>> ' || x_progress ||
                           ' >>> ERREUR: ' || SQLERRM);
      RAISE;
  END init;
end DKA_SPE037_ACC_GEN_FA_PKG;

/
SHOW ERRORS
EXIT;
