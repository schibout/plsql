CREATE OR REPLACE PACKAGE BODY DKA_FUSPOMAJPFTF_PKG AS
  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_FUSPOMAJPFTF_PKG
  -- Description      : Body du package DKA_FUSPOMAJPFTF_PKG
  -- Auteur           : Samir EL OUAHABI
  -- Date de création : 01/09/2019
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- V2.0    22/01/2020     SELO  Modification, SFD : SPE098_ACHATS_SFD20190011_Automatisation de la Fusion PO V1.3 
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ------------------------------------------------------------------------------------
  -- Nom              : Main
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
  

 
  PROCEDURE main(p_errbuf       IN OUT  VARCHAR2,
                 p_retcode      OUT     NUMBER,
				 p_org_id       IN      Number
                 )
  IS

   CURSOR cur_DA
   IS
    select prh.org_id, 
	       prh.requisition_header_id, 
		   prd.task_id, 
	       prd.project_id, 
		   ppa.org_id project_org, 
	       ppa.segment1, 
		   prl.line_num,
		   pt.task_number, 
		   prd.distribution_id,
	       prh.segment1 DA,
		   prl.line_type_id,
		   prd.expenditure_type, 
		   prl.destination_organization_id, 
		   prl.destination_type_code,
		   prd.set_of_books_id
	  from po_requisition_headers_all prh,
		   po_requisition_lines_all prl,
		   po_req_distributions_all prd,
		   pa_projects_all ppa,
           pa_tasks pt		   
	 where prh.requisition_header_id=prl.requisition_header_id
	   and prl.requisition_line_id=prd.requisition_line_id
	   and prh.authorization_status not in ('REJECTED' , 'CANCELLED') -- SELO 
	   and nvl(prh.cancel_flag, 'N') = 'N'                            -- SELO
	   and nvl(prl.cancel_flag, 'N') = 'N'                            -- SELO
	   and ppa.project_id=prd.project_id
	   and pt.task_id=prd.task_id
	   and prl.line_location_id is null
	   and prh.org_id not in ( SELECT HOU.organization_id
							     FROM HR_ORGANIZATION_UNITS HOU,
								      DKA_STRANSCO_LINES DSTL,
								      DKA_STRANSCO_HEADERS DSTH
							    WHERE DSTL.SET_ID = DSTH.SET_ID
								  AND HOU.NAME = DSTL.PARAM1_VALUE
								  AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
								  AND DSTL.ENABLE = 'Y'
								  AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
							   -- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
								 )
       and prh.org_id  = p_org_id								 
       and ppa.org_id in ( SELECT HOU.organization_id
					         FROM HR_ORGANIZATION_UNITS HOU,
								  DKA_STRANSCO_LINES DSTL,
								  DKA_STRANSCO_HEADERS DSTH
					        WHERE DSTL.SET_ID = DSTH.SET_ID
						      AND HOU.NAME = DSTL.PARAM1_VALUE
						      AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
						      AND DSTL.ENABLE = 'Y'
						      AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
						   -- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
							  )  
					;
 
 
 CURSOR cur_commande
   IS
   select poha.po_header_id, 
          poda.po_distribution_id,
          poha.vendor_id,
          poha.agent_id,
          pola.category_id,
          pola.line_type_id,
          poda.project_id, 
          poda.destination_type_code, 
          poda.destination_organization_id,
          poda.expenditure_type,
          poda.expenditure_organization_id,
          poda.expenditure_item_date,
          poda.deliver_to_location_id,
          papa.segment1,
          papa.org_id project_org,
          pt.task_number,
		  poha.org_id,
		  poha.segment1 cmd_num,
		  pola.line_num,
		  poda.set_of_books_id
     FROM PO_HEADERS_ALL poha,
          PO_LINES_ALL pola,
          PO_DISTRIBUTIONS_ALL poda,
          PA_PROJECTS_ALL papa,
	      PA_TASKS PT	--SELO
     --  ,hr_all_organization_units hraou
    WHERE poda.po_header_id = poha.po_header_id
	  AND poda.po_line_id = pola.po_line_id
	  AND poha.type_lookup_code        = 'STANDARD'
	  AND NVL(poha.closed_code,'OPEN') = 'OPEN'
	  AND NVL(poha.cancel_flag,'N')    = 'N'
	  AND poda.PROJECT_ID = papa.project_id (+)
	  AND PT.TASK_ID = poda.TASK_ID
	  AND poha.org_id not in ( SELECT HOU.organization_id
							     FROM HR_ORGANIZATION_UNITS HOU,
									  DKA_STRANSCO_LINES DSTL,
									  DKA_STRANSCO_HEADERS DSTH
							    WHERE DSTL.SET_ID = DSTH.SET_ID
								  AND HOU.NAME = DSTL.PARAM1_VALUE
								  AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
								  AND DSTL.ENABLE = 'Y'
								  AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
							   -- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
							   )
	  AND poha.org_id  = p_org_id
      AND papa.org_id in ( SELECT HOU.organization_id
					         FROM HR_ORGANIZATION_UNITS HOU,
						          DKA_STRANSCO_LINES DSTL,
						          DKA_STRANSCO_HEADERS DSTH
					        WHERE DSTL.SET_ID = DSTH.SET_ID
						      AND HOU.NAME = DSTL.PARAM1_VALUE
						      AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
						      AND DSTL.ENABLE = 'Y'
						      AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
						   -- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
						  ) ;

 
 
    result BOOLEAN;

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
	l_org_absorbante              VARCHAR2(240);  
	l_org_ID_absorbante           NUMBER;
	v_RG_EXP01                    NUMBER;
    g_user_id                      fnd_user.user_id%TYPE;	
	ROW_COUNT					  NUMBER;
	UO_NAME						  VARCHAR2(100);
  
BEGIN

    begin 
	  select name into uo_name
	    from hr_organization_units
	   where organization_id=p_org_id;
	exception
	  when others then
		Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Impossible de reccuperer le nom de l''organisation ');								  
	  end; 
 
	BEGIN
		SELECT
					 distinct 1 into v_RG_EXP01
				 FROM
					 HR_ORGANIZATION_UNITS HOU,
					 DKA_STRANSCO_LINES DSTL,
					 DKA_STRANSCO_HEADERS DSTH
				 WHERE
					 DSTL.SET_ID = DSTH.SET_ID
					 AND HOU.NAME = DSTL.PARAM1_VALUE
					 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
					 AND DSTL.ENABLE = 'Y'
					 AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
					-- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE) )  <= TRUNC(SYSDATE)
					 group by DSTL.PARAM1_VALUE,
							  DSTL.RetuRN_VALUE
					 having count(PARAM1_VALUE)>1;
	exception
		  when others then
		        v_RG_EXP01:=0;								  
		  end;


	if  v_RG_EXP01 = 1 then
	
	    --Fnd_File.put_line (Fnd_File.OUTPUT, 'RG_MAJ1: Plusieurs couples actifs dans la table de transco ');
		Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'RG_MAJ1: Plusieurs couples actifs dans la table de transco ');
	end if;


    g_user_id                      := fnd_global.user_id; 
    l_nbre_lu := 0;
    l_nbre_ok := 0;
    l_nbre_ko := 0;
    l_nbre_maj:= 0;
 
    l_nbre_lu_cmd := 0;
    l_nbre_ok_cmd := 0;
    l_nbre_ko_cmd := 0;
    l_nbre_maj_cmd:= 0;
 
Fnd_File.put_line (Fnd_File.OUTPUT,'*******************************************************');	
Fnd_File.put_line (Fnd_File.OUTPUT,chr(10));	
Fnd_File.put_line (Fnd_File.OUTPUT,'***********   Liste des DA MAJ OK/KO    **************');
Fnd_File.put_line (Fnd_File.OUTPUT,chr(10));	
Fnd_File.put_line (Fnd_File.OUTPUT,'*******************************************************');
 
    FOR rec_DA IN cur_DA LOOP
            
       l_bom_cost_element_id   := NULL;
       l_from_type_lookup_code := NULL;
       l_from_header_id        := NULL;
       l_from_line_id          := NULL;
       l_wip_entity_type       := NULL;
       l_message_erreur        := NULL;
       l_fb_error_msg          := NULL;
       l_nbre_lu               := l_nbre_lu + 1; 
       l_accrual_segment1      := NULL; 
       l_accrual_segment2      := NULL;
       l_accrual_segment3      := NULL;
       l_accrual_segment4      := NULL;
       l_accrual_segment7      := NULL;  
       l_flux                  := NULL;
       l_charge_account_flex   := NULL;
       l_accrual_account_flex  := NULL;
       l_code_combination_id   := NULL;
       l_budget_account_id     := NULL;
       l_accrual_account_id    := NULL;
       l_variance_account_id   := NULL;
       l_responsibility_id     := NULL;
       l_application_id        := NULL;
       l_task_id               := NULL;
       l_project_id            := NULL;
       l_expenditure_organization_id := NULL;   
	   l_org_absorbante	:= null;
       l_org_ID_absorbante := null;
             
       
    --   Fnd_File.put_line (Fnd_File.OUTPUT, 'Demande d''achat : ' || rec_DA.DA );
	   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Demande d''achat : ' || rec_DA.DA); 

       /*
	   
	   SELECT HOU.organization_id, DSTL.return_VALUE
    	 INTO l_org_ID_absorbante, l_org_absorbante
		 FROM HR_ORGANIZATION_UNITS HOU,
			  DKA_STRANSCO_LINES DSTL,
			  DKA_STRANSCO_HEADERS DSTH
		WHERE DSTL.SET_ID = DSTH.SET_ID
		  AND HOU.NAME = DSTL.return_VALUE
		  AND DSTL.PARAM1_VALUE = (select name
									 from hr_organization_units
									where organization_id = rec_DA.project_org)
		  AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
		  AND DSTL.ENABLE = 'Y'
		  AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
		--AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
			 ;
	    */
	    select name into l_org_absorbante
		  from hr_organization_units
		 where organization_id = rec_DA.org_id;
		 
       BEGIN
          SELECT responsibility_id,
                 application_id
            INTO l_responsibility_id,
                 l_application_id 
            FROM fnd_responsibility
           WHERE responsibility_key = l_org_absorbante ||'_PO_ADMINISTRATEUR';
       EXCEPTION
       WHEN OTHERS THEN
           l_message_erreur := 'Impossible de déterminer la responsabilité de connexion';
		   Fnd_File.put_line (Fnd_File.OUTPUT,'MAJ: KO - Organisation : ' ||uo_name||' - DA : '||rec_DA.DA|| ' - Num ligne: ' || rec_DA.line_num|| ' - erreur diverse = ' || l_message_erreur);
	       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Impossible de déterminer la responsabilité de connexion'); 
       END;
       
       --Fnd_File.put_line (Fnd_File.OUTPUT, 'resp_id : ' ||l_responsibility_id);
	    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'resp_id : ' ||l_responsibility_id); 

        BEGIN
          SELECT pt.task_id,
                 ppa.project_id,
                 ppa.carrying_out_organization_id
            INTO l_task_id,
                 l_project_id,
                 l_expenditure_organization_id
            FROM pa_tasks pt,
                 pa_projects_all ppa
           WHERE pt.project_id = ppa.project_id 
             AND pt.task_number = substr(rec_DA.task_number,1,10) 
             AND ppa.segment1   = substr(rec_DA.segment1,1,10) ;

		EXCEPTION
            WHEN OTHERS THEN
	          l_message_erreur:='Impossible de récupérer la nouvelle tâche' ;
			  Fnd_File.put_line (Fnd_File.OUTPUT,'MAJ: KO - Organisation : ' ||uo_name||' - DA : '||rec_DA.DA|| ' - Num ligne: ' || rec_DA.line_num|| ' - erreur diverse = ' || l_message_erreur);
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - Impossible de récupérer la nouvelle tâche'); 
			  l_nbre_ko := l_nbre_ko + 1; 
        END;
       
       IF l_message_erreur IS NULL
       THEN 
           fnd_global.APPS_INITIALIZE (user_id => g_user_id,resp_id => l_responsibility_id,resp_appl_id => l_application_id);
           MO_GLOBAL.INIT (p_appl_short_name => 'PO');

           BEGIN
		      Fnd_File.put_line (Fnd_File.LOG, 'set_of_books_id = ' ||rec_DA.set_of_books_id);
              SELECT chart_of_accounts_id
                INTO l_coa_id
                FROM gl_sets_of_books
               WHERE set_of_books_id = rec_DA.set_of_books_id ;--fnd_profile.VALUE('GL_SET_OF_BKS_ID');
           EXCEPTION
             WHEN OTHERS THEN
		    --   l_message_erreur:='Impossible de récupérer le set_of_books'  ;
			   Fnd_File.put_line (Fnd_File.OUTPUT, l_message_erreur);
			   Fnd_File.put_line (Fnd_File.OUTPUT,'MAJ: KO - Organisation : ' ||uo_name||' - DA : '||rec_DA.DA|| ' - Num ligne: ' || rec_DA.line_num|| ' - erreur diverse = ' || l_message_erreur);
               Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || 'Impossible de récupérer le set_of_books'); 
           END;
           

           IF l_message_erreur IS NULL
           THEN 

               -- Call the function
               result := po_wf_build_account_init.start_workflow( x_charge_success              => l_charge_success,
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
																  x_destination_type_code       => rec_da.destination_type_code,     --
																  x_deliver_to_location_id      => l_deliver_to_location_id,
																  x_destination_organization_id => rec_da.destination_organization_id,   --
																  x_destination_subinventory    => l_destination_subinventory,
																  x_expenditure_type            => rec_da.expenditure_type,                --
																  x_expenditure_organization_id => l_expenditure_organization_id,     --
																  x_expenditure_item_date       => SYSDATE,
																  x_item_id                     => l_item_id,
																  x_line_type_id                => rec_da.line_type_id,          --
																  x_result_billable_flag        => 'N',
																  x_agent_id                    => l_agent_id,
																  x_project_id                  => l_project_id,          --
																  x_from_type_lookup_code       => l_from_type_lookup_code,
																  x_from_header_id              => l_from_header_id,
																  x_from_line_id                => l_from_line_id,
																  x_task_id                     => l_task_id,          --
																  x_deliver_to_person_id        => l_deliver_to_person_id,
																  x_type_lookup_code            => 'STANDARD',
																  x_vendor_id                   => l_vendor_id,       --
																  x_wip_entity_id               => l_wip_entity_id,
																  x_wip_entity_type             => l_wip_entity_type,
																  x_wip_line_id                 => l_wip_line_id,
																  x_wip_repetitive_schedule_id  => l_wip_repetitive_schedule_id,
																  x_wip_operation_seq_num       => l_wip_operation_seq_num,
																  x_wip_resource_seq_num        => l_wip_resource_seq_num,
																  x_po_encumberance_flag        => 'N',
																  x_gl_encumbered_date          => l_gl_encumbered_date,
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
				       l_message_erreur := 'ERREUR Workflow : '||l_fb_error_msg;
					   Fnd_File.put_line (Fnd_File.OUTPUT,'MAJ: KO - Organisation : ' ||uo_name||' - DA : '||rec_DA.DA|| ' - Num ligne: ' || rec_DA.line_num|| ' - erreur diverse = '||l_message_erreur||' - l_charge_account_flex = ' || l_charge_account_flex|| ' - l_accrual_account_flex = ' || l_accrual_account_flex|| ' - l_code_combination_id = ' || l_code_combination_id);
					   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || 'Probleme Workflow ' );
                       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || 'l_charge_account_flex = ' || l_charge_account_flex);
					   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || 'l_accrual_account_flex = ' || l_accrual_account_flex);
                       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || 'l_code_combination_id = ' || l_code_combination_id);
					   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || 'ERREUR Workflow : '||l_fb_error_msg); 
                        
                   ELSE
                       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || 'l_code_combination_id = ' || l_code_combination_id);
                       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || 'l_charge_account_flex = ' || l_charge_account_flex);
                       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || 'l_accrual_account_flex = ' || l_accrual_account_flex);
                   END IF;
                   
    
                   IF l_message_erreur IS NULL
                   THEN
                          UPDATE po_req_distributions_all 
                             SET project_id = l_project_id,
                                 task_id = l_task_id,
                                 expenditure_organization_id = l_expenditure_organization_id,
                                 code_combination_id = l_code_combination_id,
                                 Accrual_account_id =  l_accrual_account_id, -- l_charge_account_flex_new_id,
                                 variance_account_id  = l_code_combination_id,
                                 last_updated_by = g_user_id,
                                 last_update_date = sysdate
                           WHERE distribution_id = rec_DA.distribution_id;  
                       
						  Fnd_File.put_line (Fnd_File.OUTPUT, 'MAJ: OK - Organisation : ' ||uo_name||' - DA : '||rec_DA.DA|| ' - Num ligne: ' || rec_DA.line_num);
                          l_nbre_maj := l_nbre_maj + SQL%ROWCOUNT; 
            
                          Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE,'DD/MM/YYYY HH24:MI:SS') ||'MAJ effectuee');
                  
                   ELSE
					    l_nbre_ko := l_nbre_ko + 1;  
                  
				  END IF;    
                
           ELSE
		   
		       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' erreur positionnement UO = ' || l_message_erreur);
           
               l_nbre_ko := l_nbre_ko + 1; 
           END IF;
           
       ELSE 
	      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' erreur diverse = ' || l_message_erreur);
        
          -- l_nbre_ko := l_nbre_ko + 1; 
       
       END IF;    
       
    END LOOP;       
    
    -- Bilan
    Fnd_File.put_line (Fnd_File.OUTPUT,CHR(10)||'******************************************************');
	Fnd_File.put_line (Fnd_File.OUTPUT,'*******************************************************');	
    Fnd_File.put_line (Fnd_File.OUTPUT,'                                                       ');	
    Fnd_File.put_line (Fnd_File.OUTPUT,'***********   BILAN DEMANDE D''ACHAT     **************');
    Fnd_File.put_line (Fnd_File.OUTPUT,'                                                       ');	
    Fnd_File.put_line (Fnd_File.OUTPUT,'*******************************************************');
    Fnd_File.put_line (Fnd_File.OUTPUT,'Nombre de lignes lues : ' || l_nbre_lu);
    Fnd_File.put_line (Fnd_File.OUTPUT,'Nombre de lignes maj : ' || l_nbre_maj);
    Fnd_File.put_line (Fnd_File.OUTPUT,'Nombre de lignes ko : ' || l_nbre_ko);
    Fnd_File.put_line (Fnd_File.OUTPUT,'                                                       ');	
    Fnd_File.put_line (Fnd_File.OUTPUT,'*******************************************************');
     
---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
Fnd_File.put_line (Fnd_File.OUTPUT,'*******************************************************');	
Fnd_File.put_line (Fnd_File.OUTPUT,chr(10));	
Fnd_File.put_line (Fnd_File.OUTPUT,'***********   Liste des commandes MAJ OK/KO     **************');
Fnd_File.put_line (Fnd_File.OUTPUT,chr(10));	
Fnd_File.put_line (Fnd_File.OUTPUT,'*******************************************************');

  FOR rec_commande IN cur_commande LOOP
            
       l_bom_cost_element_id   := NULL;
       l_from_type_lookup_code := NULL;
       l_from_header_id        := NULL;
       l_from_line_id          := NULL;
       l_wip_entity_type       := NULL;
       l_message_erreur        := NULL;
       l_fb_error_msg          := NULL;
       l_nbre_lu_cmd               := l_nbre_lu_cmd + 1; 
       l_accrual_segment1      := NULL; 
       l_accrual_segment2      := NULL;
       l_accrual_segment3      := NULL;
       l_accrual_segment4      := NULL;
       l_accrual_segment7      := NULL;  
       l_flux                  := NULL;
       l_charge_account_flex   := NULL;
       l_accrual_account_flex  := NULL;
       l_code_combination_id   := NULL;
       l_budget_account_id     := NULL;
       l_accrual_account_id    := NULL;
       l_variance_account_id   := NULL;
       l_responsibility_id     := NULL;
       l_application_id        := NULL;
       l_task_id               := NULL;
       l_project_id            := NULL;
       l_expenditure_organization_id := NULL;   
	   l_org_absorbante	:= null;
       l_org_ID_absorbante := null;
             
    --   Fnd_File.put_line (Fnd_File.OUTPUT, 'Commande : ' || rec_commande.cmd_num );
       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'Commande : ' || rec_commande.cmd_num );

       
	   /*
		SELECT HOU.organization_id, 
		       DSTL.return_VALUE
		  INTO l_org_ID_absorbante, 
		       l_org_absorbante
		  FROM HR_ORGANIZATION_UNITS HOU,
			   DKA_STRANSCO_LINES DSTL,
			   DKA_STRANSCO_HEADERS DSTH
		 WHERE DSTL.SET_ID = DSTH.SET_ID
		   AND HOU.NAME = DSTL.return_VALUE
		   AND DSTL.PARAM1_VALUE = (select name
									  from hr_organization_units
									 where organization_id =rec_commande.project_org)
		   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
		   AND DSTL.ENABLE = 'Y'
		   AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
			-- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
			 ;*/
        select name into l_org_absorbante
		  from hr_organization_units
		 where organization_id = rec_commande.org_id;
	   
       BEGIN
          SELECT responsibility_id,
                 application_id
            INTO l_responsibility_id,
                 l_application_id 
            FROM fnd_responsibility
           WHERE responsibility_key = l_org_absorbante ||'_PO_ADMINISTRATEUR';
       EXCEPTION
       WHEN OTHERS THEN
            l_message_erreur := 'Impossible de déterminer la responsabilité de connexion';
		    Fnd_File.put_line (Fnd_File.OUTPUT, 'MAJ: KO - Organisation : ' ||uo_name||' - Commande : '||rec_commande.cmd_num|| ' - Num ligne: ' || rec_commande.line_num ||'- erreur diverse : '||l_message_erreur);
		    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Impossible de déterminer la responsabilité de connexion'); 
       END;
       
       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'resp_id : ' ||l_responsibility_id);

       BEGIN
          SELECT pt.task_id,
                 ppa.project_id,
                 ppa.carrying_out_organization_id
            INTO l_task_id,
                 l_project_id,
                 l_expenditure_organization_id
          FROM pa_tasks pt,
               pa_projects_all ppa
          WHERE pt.project_id = ppa.project_id 
          AND   pt.task_number = substr(rec_commande.task_number,1,10) 
           AND  ppa.segment1   = substr(rec_commande.segment1,1,10) ;
		  
		
       EXCEPTION
       WHEN OTHERS THEN
	           l_message_erreur:='Impossible de récupérer la nouvelle tâche' ;
			   Fnd_File.put_line (Fnd_File.OUTPUT, 'MAJ: KO - Organisation : ' ||uo_name||' - Commande : '||rec_commande.cmd_num|| ' - Num ligne: ' || rec_commande.line_num ||'- erreur diverse : '||l_message_erreur);
               Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - Impossible de récupérer la nouvelle tâche'); 
			   l_nbre_ko_cmd:=l_nbre_ko_cmd+1;
       END;
       
       IF l_message_erreur IS NULL
       THEN 
                  
           fnd_global.APPS_INITIALIZE (user_id => g_user_id,resp_id => l_responsibility_id,resp_appl_id => l_application_id);
           MO_GLOBAL.INIT (p_appl_short_name => 'PO');

           BEGIN
		      Fnd_File.put_line (Fnd_File.LOG, 'set_of_books_id = ' ||rec_commande.set_of_books_id);
              SELECT chart_of_accounts_id
              INTO l_coa_id
              FROM gl_sets_of_books
              WHERE set_of_books_id = rec_commande.set_of_books_id ; --fnd_profile.VALUE('GL_SET_OF_BKS_ID');
           EXCEPTION
           WHEN OTHERS THEN
		       l_message_erreur:='Impossible de récupérer le set_of_books'  ;
			   Fnd_File.put_line (Fnd_File.OUTPUT, 'MAJ: KO - Organisation : ' ||uo_name||' - Commande : '||rec_commande.cmd_num|| ' - Num ligne: ' || rec_commande.line_num ||'- erreur diverse : '||l_message_erreur);
			   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || 'Impossible de récupérer le set_of_books'); 
           END;
           

           IF l_message_erreur IS NULL
           THEN 

               -- Call the function
               result := po_wf_build_account_init.start_workflow(  x_charge_success              => l_charge_success,
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
                                                                   x_destination_type_code       => rec_commande.destination_type_code,     --
                                                                   x_deliver_to_location_id      => l_deliver_to_location_id,
                                                                   x_destination_organization_id => rec_commande.destination_organization_id,   --
                                                                   x_destination_subinventory    => l_destination_subinventory,
                                                                   x_expenditure_type            => rec_commande.expenditure_type,                --
                                                                   x_expenditure_organization_id => l_expenditure_organization_id,     --
                                                                   x_expenditure_item_DATE       => SYSDATE,
                                                                   x_item_id                     => l_item_id,
                                                                   x_line_type_id                => null , -- rec_commande.line_type_id,          --
                                                                   x_result_billable_flag        => 'N',
                                                                   x_agent_id                    => l_agent_id,
                                                                   x_project_id                  => l_project_id,          --
                                                                   x_from_type_lookup_code       => l_from_type_lookup_code,
                                                                   x_from_header_id              => l_from_header_id,
                                                                   x_from_line_id                => l_from_line_id,
                                                                   x_task_id                     => l_task_id,          --
                                                                   x_deliver_to_person_id        => l_deliver_to_person_id,
                                                                   x_type_lookup_code            => 'STANDARD',
                                                                   x_vendor_id                   => l_vendor_id,       --
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
				   
				       l_message_erreur := 'ERREUR Workflow : '||l_fb_error_msg;
					   Fnd_File.put_line (Fnd_File.OUTPUT,'MAJ: KO - Organisation : ' ||uo_name||' - Commande : '||rec_commande.cmd_num|| ' - Num ligne: ' || rec_commande.line_num|| ' - erreur diverse = '||l_message_erreur||' - l_charge_account_flex = ' || l_charge_account_flex|| ' - l_accrual_account_flex = ' || l_accrual_account_flex|| ' - l_code_combination_id = ' || l_code_combination_id);
					   			   
                       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'Probleme Workflow ' );
                       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'l_charge_account_flex = ' || l_charge_account_flex);
                       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'l_accrual_account_flex = ' || l_accrual_account_flex);
                       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'l_code_combination_id = ' || l_code_combination_id);
					   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'ERREUR Workflow : '||l_fb_error_msg); 
                   ELSE
                       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'l_code_combination_id = ' || l_code_combination_id);
                       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'l_charge_account_flex = ' || l_charge_account_flex);
                       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||  'l_accrual_account_flex = ' || l_accrual_account_flex);
                   --    dbms_output.put_line('l_accrual_account_id = ' || l_accrual_account_id);  */
                   END IF;
                   
    
                   IF l_message_erreur IS NULL
                   THEN
                    
                       
                          UPDATE PO_DISTRIBUTIONS_ALL 
                             SET project_id = l_project_id,
                                 task_id = l_task_id,
                                 expenditure_organization_id = l_expenditure_organization_id,
                                 code_combination_id = l_code_combination_id,
                                 Accrual_account_id =  l_accrual_account_id, --l_charge_account_flex_new_id,
                                 variance_account_id  = l_code_combination_id,
                                 last_updated_by = g_user_id,
                                 last_update_DATE = sysdate
                           WHERE po_distribution_id = rec_commande.po_distribution_id;   
             
                          l_nbre_maj_cmd := l_nbre_maj_cmd + SQL%ROWCOUNT; 
                          
                          l_nbre_ok_cmd := l_nbre_ok_cmd + SQL%ROWCOUNT; 
						  Fnd_File.put_line (Fnd_File.OUTPUT, 'MAJ: OK - Organisation : ' ||uo_name||' - Commande : '||rec_commande.cmd_num|| ' - Num ligne: ' || rec_commande.line_num);
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
       
    END LOOP;       
    
    -- Bilan
    Fnd_File.put_line (Fnd_File.OUTPUT,'******************************************************');
	Fnd_File.put_line (Fnd_File.OUTPUT,CHR(10)||'******************************************************');
    Fnd_File.put_line (Fnd_File.OUTPUT,'**************   BILAN  COMMANDES    *****************');
    Fnd_File.put_line (Fnd_File.OUTPUT,'******************************************************');
	Fnd_File.put_line (Fnd_File.OUTPUT,'                                                      ');
    Fnd_File.put_line (Fnd_File.OUTPUT,'Nombre de lignes lues : ' || l_nbre_lu_cmd);
    Fnd_File.put_line (Fnd_File.OUTPUT,'Nombre de lignes maj : ' || l_nbre_maj_cmd);
    Fnd_File.put_line (Fnd_File.OUTPUT,'Nombre de lignes ko : ' || l_nbre_ko_cmd);   


    Fnd_File.put_line (Fnd_File.OUTPUT,'                                                      ');
	Fnd_File.put_line (Fnd_File.OUTPUT,'******************************************************');	
            
	EXCEPTION
		WHEN OTHERS THEN
		  Fnd_File.put_line (Fnd_File.OUTPUT,'MAJ DA / Commande =>' || SQLERRM);
		  Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' MAJ DA / Commande =>' || SQLERRM);
    END Main; 
END DKA_FUSPOMAJPFTF_PKG;




/
SHOW ERRORS;
EXIT
