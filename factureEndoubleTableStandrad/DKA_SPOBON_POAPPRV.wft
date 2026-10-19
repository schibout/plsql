CREATE OR REPLACE PACKAGE BODY DKA_SPOMAJIC_PKG AS
  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_SPOMAJIC_PKG 
  -- Nom              : DKA_SPOMAJIC_PKG 
  -- Description      : Body du package DKA_SPOMAJIC_PKG ( IMPORT DES RECEPTIONS PO )
  -- Auteur           : SELO
  -- Date de création : 17/07/2020
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 
  --------------------------------------------------------------------------------  
  
/*
 *************************************************************************
 * PROCEDURE NAME : Output_Header
 *
 * DESCRIPTION
 *  Procédure pour insérer une en-tête dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE output_header
  IS
        cv_line                     VARCHAR2 (100);
        v_conc_program_name         fnd_concurrent_programs.concurrent_program_name%TYPE;
        v_user_conc_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN

        cv_line    := '----------------------------------------------------------------------------------';

        ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
        BEGIN
            SELECT fcp.concurrent_program_name,
                   fcpt.user_concurrent_program_name
            INTO   v_conc_program_name,
                   v_user_conc_program_name
            FROM   fnd_concurrent_programs fcp,
                   fnd_concurrent_programs_tl fcpt
            WHERE  fcp.application_id = Fnd_Global.prog_appl_id
            AND    fcp.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.application_id = Fnd_Global.prog_appl_id
            AND    fcpt.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.LANGUAGE = Fnd_Global.current_language;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_user_conc_program_name    := '???????????????????????';
                v_conc_program_name         := '???????';
        END;


        Fnd_File.put_line (Fnd_File.output, cv_line );
		Fnd_File.put_line (Fnd_File.output, 'COMPTE-RENDU DU TRAITEMENT « DKA : Mise à jour commande - Imputations comptables »');
        Fnd_File.put_line (Fnd_File.output, 'Traitement n° '||fnd_global.conc_request_id);
        Fnd_File.put_line (Fnd_File.output, 'Le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') );
		Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        --Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10) || CHR(10));
  END output_header;
   
 /*
 *************************************************************************
 * PROCEDURE NAME : main
 * 
 * DESCRIPTION
 *  Procédure principale
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 ************************************************************************
 */

PROCEDURE main(
                p_Errbuf            IN OUT  VARCHAR2,
                p_retcode           OUT     NUMBER,
                p_commande          IN      NUMBER,
                p_Num_Ligne         IN      NUMBER,
				p_TF                IN      NUMBER,
                p_depense           IN      NUMBER
              )

IS
    v_errbuf                      VARCHAR2(2500);
    v_retcode                     NUMBER;
    Erreur_Programme              EXCEPTION;
    error                         EXCEPTION;
    v_current_program_unit        VARCHAR2(30);
    v_ATTRIBUTE13                 VARCHAR2(10); 
    v_segment1                    VARCHAR2(15);
    g_user_id                     fnd_user.user_id%TYPE;
                                    
                                    
                                    
    v_line_num			          NUMBER;
    v_SHIPMENT_NUM                PO_LINE_LOCATIONS_ALL.SHIPMENT_NUM%TYPE;
    v_DISTRIBUTION_NUM            NUMBER;
    v_PO_LINE_ID                  NUMBER;
    v_LINE_LOCATION_ID            NUMBER;
    v_PO_DISTRIBUTION_ID          NUMBER;
    v_task_number                 PA_TASKS.task_number%TYPE;
    v_expenditure_type            PA_EXPENDITURE_TYPES.expenditure_type%TYPE;
    v_task_id                     NUMBER;
    v_expenditure_type_id         NUMBER;
    v_cmd                         varchar2(50);
    v_project_name                varchar2(50);
    V_ET                          PA_EXPENDITURE_TYPES.expenditure_type%TYPE;
    v_line_type_id                NUMBER;
    v_project_id                  NUMBER;
    v_destination_type_code       PO_DISTRIBUTIONS_ALL.destination_type_code%TYPE;
    v_destination_organization_id NUMBER;
    v_org_id                      NUMBER;
    v_set_of_books_id             NUMBER;
    result                        BOOLEAN;

    l_charge_success              BOOLEAN;
    l_budget_success              BOOLEAN;
    l_accrual_success             BOOLEAN;
    l_variance_success            BOOLEAN;
    l_code_combination_id         gl_code_combinations_kfv.code_combination_id%TYPE;
    l_budget_account_id           gl_code_combinations_kfv.code_combination_id%TYPE;
    l_accrual_account_id          gl_code_combinations_kfv.code_combination_id%TYPE;
    l_variance_account_id         gl_code_combinations_kfv.code_combination_id%TYPE;
    l_charge_account_flex_new_id  gl_code_combinations_kfv.code_combination_id%TYPE;
    l_charge_account_flex         gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_budget_account_flex         gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_accrual_account_flex        gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_variance_account_flex       gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_charge_account_desc         VARCHAR2(2000);
    l_budget_account_desc         VARCHAR2(2000);
    l_accrual_account_desc        VARCHAR2(2000);
    l_variance_account_desc       VARCHAR2(2000);
    l_coa_id                      NUMBER;
    l_bom_resource_id             NUMBER;
    l_bom_cost_element_id         NUMBER;
    l_category_id                 NUMBER;
    l_destination_type_code       VARCHAR2(100);
    l_deliver_to_location_id      NUMBER;
    l_destination_organization_id NUMBER;
    l_destination_subinventory    VARCHAR2(100);
    l_expenditure_type            VARCHAR2(100);
    l_expenditure_organization_id NUMBER;
    l_expenditure_item_date       DATE;
    l_item_id                     NUMBER;
    l_line_type_id                NUMBER;
    l_result_billable_flag        VARCHAR2(100);
    l_agent_id                    NUMBER;
    l_project_id                  NUMBER;
    l_from_type_lookup_code       VARCHAR2(100);
    l_from_header_id              NUMBER;
    l_from_line_id                NUMBER;
    l_task_id                     NUMBER;
    l_deliver_to_person_id        NUMBER;
    l_type_lookup_code            VARCHAR2(100);
    l_vendor_id                   NUMBER;
    l_wip_entity_id               NUMBER;
    l_wip_entity_type             VARCHAR2(100);
    l_wip_line_id                 NUMBER;
    l_wip_repetitive_schedule_id  NUMBER;
    l_wip_operation_seq_num       NUMBER;
    l_wip_resource_seq_num        NUMBER;
    l_po_encumberance_flag        VARCHAR2(100);
    l_gl_encumbered_date          DATE;
    l_wf_itemkey                  VARCHAR2(100);
    l_new_combination             BOOLEAN;
    l_header_att1                 VARCHAR2(240);
    l_header_att2                 VARCHAR2(240);
    l_header_att3                 VARCHAR2(240);
    l_header_att4                 VARCHAR2(240);
    l_header_att5                 VARCHAR2(240);
    l_header_att6                 VARCHAR2(240);
    l_header_att7                 VARCHAR2(240);
    l_header_att8                 VARCHAR2(240);
    l_header_att9                 VARCHAR2(240);
    l_header_att10                VARCHAR2(240);
    l_header_att11                VARCHAR2(240);
    l_header_att12                VARCHAR2(240);
    l_header_att13                VARCHAR2(240);
    l_header_att14                VARCHAR2(240);
    l_header_att15                VARCHAR2(240);
    l_line_att1                   VARCHAR2(240);
    l_line_att2                   VARCHAR2(240);
    l_line_att3                   VARCHAR2(240);
    l_line_att4                   VARCHAR2(240);
    l_line_att5                   VARCHAR2(240);
    l_line_att6                   VARCHAR2(240);
    l_line_att7                   VARCHAR2(240);
    l_line_att8                   VARCHAR2(240);
    l_line_att9                   VARCHAR2(240);
    l_line_att10                  VARCHAR2(240);
    l_line_att11                  VARCHAR2(240);
    l_line_att12                  VARCHAR2(240);
    l_line_att13                  VARCHAR2(240);
    l_line_att14                  VARCHAR2(240);
    l_line_att15                  VARCHAR2(240);
    l_shipment_att1               VARCHAR2(240);
    l_shipment_att2               VARCHAR2(240);
    l_shipment_att3               VARCHAR2(240);
    l_shipment_att4               VARCHAR2(240);
    l_shipment_att5               VARCHAR2(240);
    l_shipment_att6               VARCHAR2(240);
    l_shipment_att7               VARCHAR2(240);
    l_shipment_att8               VARCHAR2(240);
    l_shipment_att9               VARCHAR2(240);
    l_shipment_att10              VARCHAR2(240);
    l_shipment_att11              VARCHAR2(240);
    l_shipment_att12              VARCHAR2(240);
    l_shipment_att13              VARCHAR2(240);
    l_shipment_att14              VARCHAR2(240);
    l_shipment_att15              VARCHAR2(240);
    l_distribution_att1           VARCHAR2(240);
    l_distribution_att2           VARCHAR2(240);
    l_distribution_att3           VARCHAR2(240);
    l_distribution_att4           VARCHAR2(240);
    l_distribution_att5           VARCHAR2(240);
    l_distribution_att6           VARCHAR2(240);
    l_distribution_att7           VARCHAR2(240);
    l_distribution_att8           VARCHAR2(240);
    l_distribution_att9           VARCHAR2(240);
    l_distribution_att10          VARCHAR2(240);
    l_distribution_att11          VARCHAR2(240);
    l_distribution_att12          VARCHAR2(240);
    l_distribution_att13          VARCHAR2(240);
    l_distribution_att14          VARCHAR2(240);
    l_distribution_att15          VARCHAR2(240);
    l_fb_error_msg                VARCHAR2(1000);
    
    l_responsibility_id           NUMBER;
    l_message_erreur              VARCHAR2(2000);
    l_user_id                     NUMBER;
    l_application_id              NUMBER;
    l_nbre_lu                     NUMBER;
    l_nbre_ok                     NUMBER;  
    l_nbre_ko                     NUMBER;  
    l_nbre_maj                    NUMBER; 
	
	l_nbre_lu_cmd                 NUMBER;
    l_nbre_ok_cmd                 NUMBER;  
    l_nbre_ko_cmd                 NUMBER;  
    l_nbre_maj_cmd                NUMBER; 
    
    l_accrual_segment1            gl_code_combinations.segment1%TYPE;    
    l_accrual_segment2            gl_code_combinations.segment2%TYPE;
    l_accrual_segment3            gl_code_combinations.segment3%TYPE;
    l_accrual_segment4            gl_code_combinations.segment4%TYPE;
    l_accrual_segment7            gl_code_combinations.segment7%TYPE;   
    l_flux                        gl_code_combinations.segment9%TYPE; 
    l_retcode                     NUMBER;
    l_errbuf                      VARCHAR2(2000);
	l_org_name                    VARCHAR2(240);  
	l_org_ID_absorbante           NUMBER;
	v_RG_EXP01                    NUMBER;
    ROW_COUNT					  NUMBER;
	UO_NAME						  VARCHAR2(100);
    v_tache                       PA_TASKS.task_number%TYPE;	
    v_prj_name                    varchar2(50);
    v_code_combination            VARCHAR2(100);	
    v_accrual_account             VARCHAR2(100);	
	v_num_ligne                   VARCHAR2(20);
	CF                            NUMBER;
	vv_segment1                   VARCHAR2(100);
	v_segment2                    VARCHAR2(100);
	v_segment3                    VARCHAR2(100);
	v_segment4                    VARCHAR2(100);
	v_segment5                    VARCHAR2(100);
	v_segment6                    VARCHAR2(100);
	v_segment7                    VARCHAR2(100);
	v_segment8                    VARCHAR2(100);
	v_segment9                    VARCHAR2(100);
	v_segment10                   VARCHAR2(100);
	v_segment11                   VARCHAR2(100);
	v_segment12                   VARCHAR2(100);
	v_vendor_site_id              NUMBER;
	v_message_wf                  VARCHAR2(2000);
    l_transaction_flow_header_id  NUMBER;
    l_dest_charge_success         BOOLEAN;
    l_dest_variance_success       BOOLEAN;
    l_dest_charge_account_id      NUMBER;
    l_dest_variance_account_id    NUMBER;
    l_dest_charge_account_desc    VARCHAR2(2000);
    l_dest_variance_account_desc  VARCHAR2(2000);
    l_dest_charge_account_flex    VARCHAR2(2000);
    l_dest_variance_account_flex  VARCHAR2(2000);
	

	
  
BEGIN
     ----------------------------
      -- PHASE D'INITIALISATION --
      ----------------------------
      
      v_current_program_unit := 'main';
      g_user_id                      := fnd_global.user_id;	  
      
      Output_Header;
      p_retcode := 0;
	BEGIN
         select PLA.line_num,
		        PLLA.SHIPMENT_NUM,
				PDA.DISTRIBUTION_NUM,
                PLA.PO_LINE_ID, 
				PLLA.LINE_LOCATION_ID, 
				pda.PO_DISTRIBUTION_ID,
                task.task_number,
				PDA.expenditure_type,
                task.task_id, 
				pet.expenditure_type_id, 
				PHA.segment1, 
				pp.segment1, 
				PLA.line_type_id,
				pda.destination_type_code,
				pda.destination_organization_id,
				pha.org_id,
				pda.set_of_books_id,
				pha.vendor_site_id
		   into
				v_line_num, 
				v_SHIPMENT_NUM, 
				v_DISTRIBUTION_NUM,
                v_PO_LINE_ID, 
				v_LINE_LOCATION_ID, 
				v_PO_DISTRIBUTION_ID,
                v_task_number,
				v_expenditure_type,
                v_task_id, 
				v_expenditure_type_id, 
				v_cmd, 
				v_project_name, 
				v_line_type_id,
				v_destination_type_code,
                v_destination_organization_id,
				v_org_id,
				v_set_of_books_id,
				v_vendor_site_id
           from PO.PO_DISTRIBUTIONS_ALL PDA, 
                PA_TASKS TASK, 
                PO.PO_LINE_LOCATIONS_ALL PLLA, 
                PO.PO_LINES_ALL PLA, 
                PO.PO_HEADERS_ALL PHA, 
                PA_EXPENDITURE_TYPES pet,
                pa_projects_all pp
          where TASK.TASK_ID = PDA.TASK_ID
         	and PLLA.LINE_LOCATION_ID = PDA.LINE_LOCATION_ID
         	and PLA.PO_LINE_ID = PDA.PO_LINE_ID
         	and PHA.PO_HEADER_ID = PDA.PO_HEADER_ID   
            and PDA.expenditure_type= pet.expenditure_type
            and PDA.PO_DISTRIBUTION_ID= p_Num_Ligne
            and PDA.PO_HEADER_ID = p_commande
            and pda.PROJECT_ID = pp.project_id
            and TASK.TASK_ID = pda.TASK_ID
    ;
	
    exception
        when others then
            fnd_file.put_line(fnd_file.OUTPUT,'Problème pour récupérer les informations sur cette commande');	
            p_retcode := 1;	
            p_Errbuf := 'Problème pour récupérer les informations sur cette commande';			
    END;
    IF (v_task_id = p_TF) and (v_expenditure_type_id= p_depense) then
        l_message_erreur:='Les valeurs '||v_task_number||' et '||v_expenditure_type||' indiquées en paramètre sont déjà celles présentes sur la ligne d''imputation.' ;
		Fnd_File.put_line (Fnd_File.OUTPUT, '« '||v_cmd||' / '||v_line_num||'.'||v_SHIPMENT_NUM||'.'||v_DISTRIBUTION_NUM || ': La ligne d''imputation n''a pas été mise à jour: ' || l_message_erreur || ' »');			   
               
		--fnd_file.put_line(fnd_file.OUTPUT,'Les valeurs '||v_task_number||' et '||v_expenditure_type||' indiquées en paramètre sont déjà celles présentes sur la ligne d''imputation.');
		p_retcode := 1;	
        p_Errbuf := 'Les valeurs '||v_task_number||' et '||v_expenditure_type||' indiquées en paramètre sont déjà celles présentes sur la ligne d''imputation.';	
        --Fnd_File.Put_Line(Fnd_File.LOG,  '==> '||v_segment1 ||' : La valeur ' ||v_ATTRIBUTE13||' indiquée en paramètre est déjà celle présente sur la commande.');		
    ELSE
        l_bom_cost_element_id         := NULL;
        l_from_type_lookup_code       := NULL;
        l_from_header_id              := NULL;
        l_from_line_id                := NULL;
        l_wip_entity_type             := NULL;
        l_message_erreur              := NULL;
        l_fb_error_msg                := NULL;
        l_accrual_segment1            := NULL; 
        l_accrual_segment2            := NULL;
        l_accrual_segment3            := NULL;
        l_accrual_segment4            := NULL;
        l_accrual_segment7            := NULL;  
        l_flux                        := NULL;
        l_charge_account_flex         := NULL;
        l_accrual_account_flex        := NULL;
        l_code_combination_id         := NULL;
        l_budget_account_id           := NULL;
        l_accrual_account_id          := NULL;
        l_variance_account_id         := NULL;
        l_responsibility_id           := NULL;
        l_application_id              := NULL;
        l_task_id                     := NULL;
        l_project_id                  := NULL;
        l_expenditure_organization_id := NULL;   
	    l_org_name	                  := null;
        l_org_ID_absorbante           := null;	  

        l_transaction_flow_header_id  := NULL;
        l_dest_charge_success         := NULL;
        l_dest_variance_success       := NULL;
        l_dest_charge_account_id      := NULL;
        l_dest_variance_account_id    := NULL;
        l_dest_charge_account_desc    := NULL;
        l_dest_variance_account_desc  := NULL;
        l_dest_charge_account_flex    := NULL;
        l_dest_variance_account_flex  := NULL;
		
		
        select name into l_org_name
		  from hr_organization_units
		 where organization_id = v_org_id;
	    select PLA.line_num||'.'||PLLA.SHIPMENT_NUM||'.'||PDA.DISTRIBUTION_NUM into v_num_ligne
          from PO.PO_DISTRIBUTIONS_ALL PDA, PO.PO_LINE_LOCATIONS_ALL PLLA, PO.PO_LINES_ALL PLA
         where PLLA.LINE_LOCATION_ID = PDA.LINE_LOCATION_ID
           and PLA.PO_LINE_ID = PDA.PO_LINE_ID
           and PO_DISTRIBUTION_ID = p_Num_Ligne;
		
       BEGIN
          SELECT responsibility_id,
                 application_id
            INTO l_responsibility_id,
                 l_application_id 
            FROM fnd_responsibility
           WHERE responsibility_key = l_org_name ||'_PO_ADMINISTRATEUR';
       EXCEPTION
       WHEN OTHERS THEN
            l_message_erreur := 'Impossible de déterminer la responsabilité PO ADMINISTRATEUR de cette commande';

			p_retcode := 1;	
		    Fnd_File.put_line (Fnd_File.OUTPUT, '« '||v_cmd|| '  / '||v_num_ligne || ': La ligne d''imputation n''a pas été mise à jour: ' || l_message_erreur || ' »');
		    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Impossible de déterminer la responsabilité PO ADMINISTRATEUR de cette commande'); 
       END;
       
       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'resp_id : ' ||l_responsibility_id);
       
	      SELECT pt.task_number
            INTO v_tache
            FROM pa_tasks pt
           WHERE task_id=p_TF
			 ;
	   
       BEGIN
          SELECT pt.task_id,
                 ppa.project_id,
                 ppa.carrying_out_organization_id,
				 pt.task_number,
				 ppa.segment1
            INTO l_task_id,
                 v_project_id,
                 l_expenditure_organization_id,
				 v_tache,
				 v_prj_name
            FROM pa_tasks pt,
                 pa_projects_all ppa
           WHERE pt.project_id = ppa.project_id 
             AND task_id=p_TF
			 and nvl(pt.completion_date,sysdate+1) > sysdate
			 ;
	
	    EXCEPTION
           WHEN OTHERS THEN
	           l_message_erreur:='Echec lors de la récupération du projet à partir de la TF '|| v_tache ||'. ' ;
			   Fnd_File.put_line (Fnd_File.OUTPUT, '« '||v_cmd|| '  / '||v_num_ligne || ': La ligne d''imputation n''a pas été mise à jour: ' || l_message_erreur || ' »');			   
               Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - Impossible de récupérer la nouvelle tâche'); 
			   l_nbre_ko_cmd:=l_nbre_ko_cmd+1;
			   p_retcode := 1;	
        END;
        IF ( l_expenditure_organization_id is null ) and ( v_project_id is not null ) then
            l_message_erreur:='Echec lors de la récupération du CF du projet à partir de la TF '|| v_tache ||'. ' ;
			Fnd_File.put_line (Fnd_File.OUTPUT, '« '||v_cmd|| '  / '||v_num_ligne || ': La ligne d''imputation n''a pas été mise à jour: ' || l_message_erreur || ' »');			   
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - Impossible de récupérer la nouvelle tâche'); 
			l_nbre_ko_cmd:=l_nbre_ko_cmd+1;
			p_retcode := 1;	
        END IF;	
        IF ( l_expenditure_organization_id is not null ) then
		    BEGIN
    			select 1 into CF
		          from hr_organization_units
		         where organization_id = l_expenditure_organization_id;
	        EXCEPTION
                WHEN OTHERS THEN		     
                    l_message_erreur:='Echec lors de la récupération du CF du projet à partir de la TF '|| v_tache ||'. ' ;
			        Fnd_File.put_line (Fnd_File.OUTPUT, '« '||v_cmd|| '  / '||v_num_ligne || ': La ligne d''imputation n''a pas été mise à jour: ' || l_message_erreur || ' »');			   
                    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - Impossible de récupérer la nouvelle tâche'); 
			        l_nbre_ko_cmd:=l_nbre_ko_cmd+1;
			        p_retcode := 1;	
			END;
        END IF;	
		

		select expenditure_type
          into V_ET		
		  from PA_EXPENDITURE_TYPES 
		 where expenditure_type_id = p_depense;
	
       IF l_message_erreur IS NULL
       THEN 
           fnd_global.APPS_INITIALIZE (user_id => g_user_id,resp_id => l_responsibility_id,resp_appl_id => l_application_id);
           MO_GLOBAL.INIT (p_appl_short_name => 'PO');

           BEGIN
		      Fnd_File.put_line (Fnd_File.LOG, 'set_of_books_id = ' ||v_set_of_books_id);
              SELECT chart_of_accounts_id
                INTO l_coa_id
                FROM gl_sets_of_books
               WHERE set_of_books_id = v_set_of_books_id;
           EXCEPTION
             WHEN OTHERS THEN
		       l_message_erreur:='Impossible de récupérer le set_of_books'  ;
			   Fnd_File.put_line (Fnd_File.OUTPUT, l_message_erreur);
			   Fnd_File.put_line (Fnd_File.OUTPUT, '« '||v_cmd|| '  / '||v_num_ligne || ': La ligne d''imputation n''a pas été mise à jour: ' || l_message_erreur || ' »');			   
               Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || 'Impossible de récupérer le set_of_books'); 
			   p_retcode := 1;	
           END;
           

           IF l_message_erreur IS NULL
           THEN 		  
               result := po_wf_build_account_init.start_workflow(  x_purchasing_ou_id           => FND_GLOBAL.org_id,
                                                                   x_transaction_flow_header_id => l_transaction_flow_header_id,
                                                                   x_dest_charge_success        => l_dest_charge_success,
                                                                   x_dest_variance_success      => l_dest_variance_success,
                                                                   x_dest_charge_account_id     => l_dest_charge_account_id,
                                                                   x_dest_variance_account_id   => l_dest_variance_account_id,
                                                                   x_dest_charge_account_desc   => l_dest_charge_account_desc,
                                                                   x_dest_variance_account_desc => l_dest_variance_account_desc,
                                                                   x_dest_charge_account_flex   => l_dest_charge_account_flex,
                                                                   x_dest_variance_account_flex => l_dest_variance_account_flex,
                                                                   x_charge_success              => l_charge_success,
                                                                   x_budget_success              => l_budget_success,
                                                                   x_accrual_success             => l_accrual_success,
                                                                   x_variance_success            => l_variance_success,
                                                                   x_code_combination_id         => l_code_combination_id,
                                                                   x_budget_account_id           => l_budget_account_id,
                                                                   x_accrual_account_id          => l_accrual_account_id,
                                                                   x_variance_account_id         => l_variance_account_id,
                                                                   x_charge_account_flex         => l_charge_account_flex,
                                                                   x_budget_account_flex         => l_budget_account_flex,
                                                                   x_accrual_account_flex        => l_accrual_account_flex,
                                                                   x_variance_account_flex       => l_variance_account_flex,
                                                                   x_charge_account_desc         => l_charge_account_desc,
                                                                   x_budget_account_desc         => l_budget_account_desc,
                                                                   x_accrual_account_desc        => l_accrual_account_desc,
                                                                   x_variance_account_desc       => l_variance_account_desc,
                                                                   x_coa_id                      => l_coa_id,
                                                                   x_bom_resource_id             => l_bom_resource_id,
                                                                   x_bom_cost_element_id         => l_bom_cost_element_id,
                                                                   x_category_id                 => l_category_id,
                                                                   x_destination_type_code       => v_destination_type_code,     --
                                                                   x_deliver_to_location_id      => l_deliver_to_location_id,
                                                                   x_destination_organization_id => v_destination_organization_id,   --
                                                                   x_destination_subinventory    => l_destination_subinventory,
                                                                   x_expenditure_type            => V_ET,                 --
                                                                   x_expenditure_organization_id => l_expenditure_organization_id,     --
                                                                   x_expenditure_item_DATE       => SYSDATE,
                                                                   x_item_id                     => l_item_id,
                                                                   x_line_type_id                => v_line_type_id , 
                                                                   x_result_billable_flag        => 'N',
                                                                   x_agent_id                    => l_agent_id,
                                                                   x_project_id                  => v_project_id,          --
                                                                   x_from_type_lookup_code       => l_from_type_lookup_code,
                                                                   x_from_header_id              => l_from_header_id,
                                                                   x_from_line_id                => l_from_line_id,
                                                                   x_task_id                     => l_task_id,          --
                                                                   x_deliver_to_person_id        => l_deliver_to_person_id,
                                                                   x_type_lookup_code            => 'STANDARD',
                                                                   x_vendor_id                   => l_vendor_id,       --
																   x_vendor_site_id              => v_vendor_site_id,
                                                                   x_wip_entity_id               => l_wip_entity_id,
                                                                   x_wip_entity_type             => l_wip_entity_type,
                                                                   x_wip_line_id                 => l_wip_line_id,
                                                                   x_wip_repetitive_schedule_id  => l_wip_repetitive_schedule_id,
                                                                   x_wip_operation_seq_num       => l_wip_operation_seq_num,
                                                                   x_wip_resource_seq_num        => l_wip_resource_seq_num,
                                                                   x_po_encumberance_flag        => 'N',
                                                                   x_gl_encumbered_DATE          => l_gl_encumbered_DATE,
                                                                   wf_itemkey                    => l_wf_itemkey,
                                                                   x_new_combination             => l_new_combination,
                                                                   header_att1                   => l_header_att1,
                                                                   header_att2                   => l_header_att2,
                                                                   header_att3                   => l_header_att3,
                                                                   header_att4                   => l_header_att4,
                                                                   header_att5                   => l_header_att5,
                                                                   header_att6                   => l_header_att6,
                                                                   header_att7                   => l_header_att7,
                                                                   header_att8                   => l_header_att8,
                                                                   header_att9                   => l_header_att9,
                                                                   header_att10                  => l_header_att10,
                                                                   header_att11                  => l_header_att11,
                                                                   header_att12                  => l_header_att12,
                                                                   header_att13                  => l_header_att13,
                                                                   header_att14                  => l_header_att14,
                                                                   header_att15                  => l_header_att15,
                                                                   line_att1                     => l_line_att1,
                                                                   line_att2                     => l_line_att2,
                                                                   line_att3                     => l_line_att3,
                                                                   line_att4                     => l_line_att4,
                                                                   line_att5                     => l_line_att5,
                                                                   line_att6                     => l_line_att6,
                                                                   line_att7                     => l_line_att7,
                                                                   line_att8                     => l_line_att8,
                                                                   line_att9                     => l_line_att9,
                                                                   line_att10                    => l_line_att10,
                                                                   line_att11                    => l_line_att11,
                                                                   line_att12                    => l_line_att12,
                                                                   line_att13                    => l_line_att13,
                                                                   line_att14                    => l_line_att14,
                                                                   line_att15                    => l_line_att15,
                                                                   shipment_att1                 => l_shipment_att1,
                                                                   shipment_att2                 => l_shipment_att2,
                                                                   shipment_att3                 => l_shipment_att3,
                                                                   shipment_att4                 => l_shipment_att4,
                                                                   shipment_att5                 => l_shipment_att5,
                                                                   shipment_att6                 => l_shipment_att6,
                                                                   shipment_att7                 => l_shipment_att7,
                                                                   shipment_att8                 => l_shipment_att8,
                                                                   shipment_att9                 => l_shipment_att9,
                                                                   shipment_att10                => l_shipment_att10,
                                                                   shipment_att11                => l_shipment_att11,
                                                                   shipment_att12                => l_shipment_att12,
                                                                   shipment_att13                => l_shipment_att13,
                                                                   shipment_att14                => l_shipment_att14,
                                                                   shipment_att15                => l_shipment_att15,
                                                                   distribution_att1             => l_distribution_att1,
                                                                   distribution_att2             => l_distribution_att2,
                                                                   distribution_att3             => l_distribution_att3,
                                                                   distribution_att4             => l_distribution_att4,
                                                                   distribution_att5             => l_distribution_att5,
                                                                   distribution_att6             => l_distribution_att6,
                                                                   distribution_att7             => l_distribution_att7,
                                                                   distribution_att8             => l_distribution_att8,
                                                                   distribution_att9             => l_distribution_att9,
                                                                   distribution_att10            => l_distribution_att10,
                                                                   distribution_att11            => l_distribution_att11,
                                                                   distribution_att12            => l_distribution_att12,
                                                                   distribution_att13            => l_distribution_att13,
                                                                   distribution_att14            => l_distribution_att14,
                                                                   distribution_att15            => l_distribution_att15,
                                                                   fb_error_msg                  => l_fb_error_msg);
	
           IF NOT l_charge_success
			   THEN
			      				   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'Probleme Workflow ' );
			       if ((l_fb_error_msg like '%FND%') or (l_fb_error_msg like '%DKA_SPOWFAG%')) then
					  begin
					      SELECT MESSAGE_TEXT into v_message_wf  FROM FND_NEW_MESSAGES WHERE MESSAGE_NAME  like '%'||substr(l_fb_error_msg ,instr(l_fb_error_msg , chr(0))+1,length(substr(l_fb_error_msg,instr(l_fb_error_msg , chr(0))+1,length(l_fb_error_msg)))-1)||'%'
                             and rownum<2;
					  exception
					     when others then
					        -- v_message_wf:=l_fb_error_msg;
							 v_message_wf:=replace(substr(l_fb_error_msg ,instr(l_fb_error_msg , chr(0))+1,length(substr(l_fb_error_msg,instr(l_fb_error_msg , chr(0))+1,length(l_fb_error_msg)))-1), chr(0), ' ');
					  end;
					   else
					   -- v_message_wf:=l_fb_error_msg;
					   v_message_wf:=replace(substr(l_fb_error_msg ,instr(l_fb_error_msg , chr(0))+1,length(substr(l_fb_error_msg,instr(l_fb_error_msg , chr(0))+1,length(l_fb_error_msg)))-1), chr(0), ' ');
				   end if;
			       
			       l_message_erreur := 'Echec lors de la génération du compte d''imputation : '|| v_message_wf;
				   Fnd_File.put_line (Fnd_File.OUTPUT, '« '||v_cmd|| '  / '||v_num_ligne || ': La ligne d''imputation n''a pas été mise à jour: ' || l_message_erreur || ' »');
				   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'Probleme Workflow ' );
				   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'l_charge_account_flex = ' || l_charge_account_flex);
				   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'l_accrual_account_flex = ' || l_accrual_account_flex);
				   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'l_code_combination_id = ' || l_code_combination_id);
				   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'ERREUR Workflow : '||l_fb_error_msg); 
				   p_retcode := 1;	
			   ELSE
				   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'l_code_combination_id = ' || l_code_combination_id);
				   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'l_charge_account_flex = ' || l_charge_account_flex);
				   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'l_accrual_account_flex = ' || l_accrual_account_flex);
				   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'v_vendor_site_id = ' || v_vendor_site_id);
			END IF;	
	
	        IF l_message_erreur IS NULL
               THEN
			   
			    /*
                    -- Calcul du segment5
		            v_segment5 := dka_spaautoaccounting_pkg.get_interco_fourn_f(v_vendor_site_id);
					
				   select segment1, segment2, segment3, segment4,  segment6, segment7, segment8, segment9, segment10, segment11, segment12
                    into vv_segment1, v_segment2, v_segment3, v_segment4, v_segment6, v_segment7, v_segment8, v_segment9, v_segment10, v_segment11, v_segment12                   
					from gl_code_combinations
					where code_combination_id =l_code_combination_id;
					
                    dka_tools_pkg.get_code_combination_id (
                                                pv_segment1 =>  vv_segment1,
                                                pv_segment2 =>  v_segment2,
                                                pv_segment3 =>  v_segment3,
                                                pv_segment4 =>  v_segment4,
                                                pv_segment5 =>  v_segment5,
                                                pv_segment6 =>  v_segment6 ,
                                                pv_segment7 =>  v_segment7 ,
                                                pv_segment8 =>  v_segment8 ,
                                                pv_segment9 =>  v_segment9 ,
                                                pv_segment10 => v_segment10,
                                                pv_segment11 => v_segment11,
                                                pv_segment12 => v_segment12,
                                                pn_code_combination_id =>  l_code_combination_id,
                                                pv_errbuf => l_errbuf,
                                                pn_retcode => l_retcode);
			   
			        IF l_retcode != 0 THEN
                        l_message_erreur := 'Echec lors de la génération du compte d''imputation : '|| l_errbuf;
						Fnd_File.put_line (Fnd_File.OUTPUT, '« '||v_cmd|| '  / '||v_num_ligne || ': La ligne d''imputation n''a pas été mise à jour: ' || l_message_erreur || ' »');
				        p_retcode := 1;
					END IF;   
			        
					
					select segment1, segment2, segment3, segment4,  segment6, segment7, segment8, segment9, segment10, segment11, segment12
                    into vv_segment1, v_segment2, v_segment3, v_segment4, v_segment6, v_segment7, v_segment8, v_segment9, v_segment10, v_segment11, v_segment12                   
					from gl_code_combinations
					where code_combination_id =l_accrual_account_id;
					
                    dka_tools_pkg.get_code_combination_id (
                                                pv_segment1 =>  vv_segment1,
                                                pv_segment2 =>  v_segment2,
                                                pv_segment3 =>  v_segment3,
                                                pv_segment4 =>  v_segment4,
                                                pv_segment5 =>  v_segment5,
                                                pv_segment6 =>  v_segment6 ,
                                                pv_segment7 =>  v_segment7 ,
                                                pv_segment8 =>  v_segment8 ,
                                                pv_segment9 =>  v_segment9 ,
                                                pv_segment10 => v_segment10,
                                                pv_segment11 => v_segment11,
                                                pv_segment12 => v_segment12,
                                                pn_code_combination_id =>  l_accrual_account_id,
                                                pv_errbuf => l_errbuf,
                                                pn_retcode => l_retcode);
			   
			        IF l_retcode != 0 THEN
                        l_message_erreur := 'Echec lors de la génération du compte de provisions.: '|| l_errbuf; 
					    Fnd_File.put_line (Fnd_File.OUTPUT, '« '||v_cmd|| '  / '||v_num_ligne || ': La ligne d''imputation n''a pas été mise à jour: ' || l_message_erreur || ' »');
						p_retcode := 1;						
				    END IF; 
			      */
			   
				  UPDATE PO_DISTRIBUTIONS_ALL 
					 SET project_id = v_project_id,
						 task_id = l_task_id,
						 expenditure_organization_id = l_expenditure_organization_id,
						 code_combination_id = l_code_combination_id,
						 Accrual_account_id =  l_accrual_account_id, 
						 variance_account_id  = l_code_combination_id,
						 expenditure_type= V_ET,
						 last_updated_by = g_user_id,
						 last_update_DATE = sysdate
				   WHERE po_distribution_id = p_Num_Ligne;   

		           
		           
				   select segment1||'.'||segment2||'.'||segment3||'.'||segment4||'.'||segment5||'.'||segment6||'.'||segment7||'.'||segment8||'.'||segment9||'.'||segment10||'.'||segment11||'.'||segment12
                    into v_code_combination                   
					from gl_code_combinations
					where code_combination_id =l_code_combination_id;

				   select segment1||'.'||segment2||'.'||segment3||'.'||segment4||'.'||segment5||'.'||segment6||'.'||segment7||'.'||segment8||'.'||segment9||'.'||segment10||'.'||segment11||'.'||segment12
                    into v_accrual_account                
					from gl_code_combinations
					where code_combination_id =l_accrual_account_id;					
				

				
				   fnd_file.put_line(fnd_file.OUTPUT,''||v_cmd||' / '||v_line_num||'.'||v_SHIPMENT_NUM||'.'||v_DISTRIBUTION_NUM||' : La ligne d''imputation a été mise à jour avec succès.');
                   fnd_file.put_line(fnd_file.OUTPUT,'Projet : ' ||v_prj_name);
                   fnd_file.put_line(fnd_file.OUTPUT,'Tâche : '||v_tache);
                   fnd_file.put_line(fnd_file.OUTPUT,'Type de dépense : '||V_ET);
                   fnd_file.put_line(fnd_file.OUTPUT,'Compte d''imputation : '||v_code_combination);
                   fnd_file.put_line(fnd_file.OUTPUT,'Compte de provision : '||v_accrual_account);
				   
				   
				   
				   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || 'MAJ effectuee');
              
            ELSE
			     
			      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' erreur calcul CCID  = ' || l_message_erreur);
                  l_nbre_ko_cmd := l_nbre_ko_cmd + 1;  
              
			END IF;  
	
            ELSE
		   
		       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' erreur positionnement UO = ' || l_message_erreur);
           
                l_nbre_ko_cmd := l_nbre_ko_cmd + 1; 
           END IF;
           
       ELSE 
	       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' erreur diverse = ' || l_message_erreur);
        
           --l_nbre_ko_cmd := l_nbre_ko_cmd + SQL%ROWCOUNT; 
       
       END IF;  
		-- p_retcode := 0;
		 
		 

    END IF;	  

  EXCEPTION
        WHEN Erreur_Programme THEN
            p_retcode   := 2;
            p_errbuf    := v_errbuf;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');        
            Fnd_File.put_line (Fnd_File.OUTPUT, '==> Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');        
			
       WHEN OTHERS 
       THEN
           fnd_concurrent.af_rollback;
           p_retcode := 2;
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_SPOMAJIC_PKG.' || v_current_program_unit||CHR(10)||'A retourné     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           p_errbuf := SQLERRM;
  END main; 

------------------------------------------------------
END DKA_SPOMAJIC_PKG;




/
SHOW ERRORS;

EXIT
