create or replace PACKAGE BODY DKA_IPOEXTSOLDHERC_PKG
AS
------------------------------------------------------------------------------------
-- $Id: DKA_IPOEXTSOLDGHERC_PKG.pkb 
-- Capgemini
-- PROJET            : Helios
-- NOM               : DKA_IPOEXTSOLDHERC_PKG.pks
-- DESCRIPTION       : DKA_IPOEXTSOLDHERC_PKG package créé pour l'interface DKA : Extraction des soldes des tâches travaux vers Hercule 
---
--- AUTEUR           : F.Siham (Capgemini)
--- DATE DE CREATION : 21/05/2019
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
--- 10/09/2019 CDE Suppression du controle sur les soldes à 0
--- 16/09/2019 CDE INC0347573 Extraction coût direct au lieu du coût complet + Modif règle tâches fermés 
--- 29/04/2020 AAM INC0422568 Récupération de la GL_DATE pour extraction soldes travaux HERCULE 
------------------------------------------------------------------------------------


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--EXCEPTIONS
  E_FATAL_ERROR EXCEPTION;
  PRAGMA EXCEPTION_INIT(E_FATAL_ERROR, -20012);
  K_FATAL_ERROR_NUM CONSTANT NUMBER := -20012;

  --CONSTANTE
  vg_package_name CONSTANT VARCHAR2(30) := 'DKA_IPOEXTSOLDHERC_PKG';
  G_separateur   CONSTANT VARCHAR2(1)   := ';';
  vg_DIRECTORY     CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';
  vg_nbl_extr_cmd   number:=0;
  vg_nbl_extr_fact  number:=0;
  vg_nbl_extr_maind number:=0;
  vg_directory_path varchar2(100);
  vg_request_id_cf  number;
  vg_period_n_1    VARCHAR2(10):= 'XX';



--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

------------------------------------------------------------------------------------
  --  Nom           : p_put_debug_message
  --  Description   : Ecrit dans le journal du traitement
  --
  --  PARAMETRES    : Message à afficher dans le journal
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_put_debug_message(p_message IN VARCHAR2) IS

  BEGIN

    dka_tools_pkg.put_log_message(p_message);

  END p_put_debug_message;

  ------------------------------------------------------------------------------------
  --  Nom           : p_validate
  --  Description   :
  --
  --  PARAMETRES    : p_condition: Si FALSE => Affiche un message dans le journal et
  --                                           genere une erreur fatale
  --                               Si TRUE  => Fait aucune action
  --                  p_message:   Message a afficher dans le journal
  ------------------------------------------------------------------------------------
  PROCEDURE p_validate(p_condition IN BOOLEAN,
                       p_message   IN VARCHAR2 DEFAULT NULL) IS
  BEGIN

    IF NOT p_condition THEN
      IF p_message IS NOT NULL THEN
        p_put_debug_message(p_message);
      END IF;

      RAISE_APPLICATION_ERROR(K_FATAL_ERROR_NUM,
                              nvl(p_message, 'Erreur fatale : '));

    END IF;

  END p_validate;

  ------------------------------------------------------------------------------------
  --  Nom           : p_check_directory
  --  Description   : Verifie que le directory existe
  --
  --  PARAMETRES    :
  --  p_directory_name          nom du directory
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_check_directory(p_directory_name in ALL_DIRECTORIES.directory_name%type) IS

    CURSOR cur_directory(p_directory_name IN ALL_DIRECTORIES.directory_name%type) IS
      SELECT owner, directory_name, directory_path
        FROM all_directories
       WHERE directory_name = p_directory_name;
    l_dir cur_directory%ROWTYPE;

  BEGIN


    OPEN cur_directory(p_directory_name);
    FETCH cur_directory
      INTO l_dir;

       p_put_debug_message('vérification du répertoire:  ' || p_directory_name ||
                        ' -> ' || l_dir.directory_path);

         vg_directory_path:=l_dir.directory_path;                 
    IF cur_directory%NOTFOUND THEN
      CLOSE cur_directory;
      p_validate(FALSE,
                 'Le directory ' || p_directory_name || ' n''existe pas.');
    END IF;


    CLOSE cur_directory;



  END p_check_directory;

   ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data
  --  Description   : Extrait des données correspondantes aux taches P3 et P6
  --
  --  PARAMETRES    :

  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data (P_PERIOD_NAME VARCHAR2)  IS

	v_start_date    gl_periods.start_date%TYPE;
	v_start_date_a  gl_periods.start_date%TYPE;
	v_start_date_p  gl_periods.start_date%TYPE;
	v_end_date_p    gl_periods.start_date%TYPE;
	v_end_date      gl_periods.start_date%TYPE;
	v_period_year   gl_periods.period_year%TYPE;
	v_task_type     VARCHAR2(2);



    CURSOR CUR_TACHE (p_date_debut DATE) IS
        SELECT  ppa.segment1 preject_name,
		            ppa.project_id,
                pt.task_number,
                pt.task_id,
				        pt.attribute1 mode_gestion,
			        	TO_CHAR(TO_DATE(pt.ATTRIBUTE2,'yyyy/mm/dd HH24:MI:SS'),'dd/mm/yyyy') DATE_CLOTURE,
                TO_CHAR(TO_DATE(pt.ATTRIBUTE5,'yyyy/mm/dd HH24:MI:SS'),'dd/mm/yyyy') DATE_PREV_FIN,
		         		ppa.PROJFUNC_CURRENCY_CODE devise
        FROM    pa_projects_all ppa
        ,       pa_tasks pt
        WHERE   ppa.project_id = pt.project_id 
        AND    (pt.TASK_NUMBER LIKE 'GT%' OR pt.TASK_NUMBER LIKE 'GX%')
        AND   ( pt.COMPLETION_DATE IS NULL
				  OR TRUNC(pt.COMPLETION_DATE + 180) >= p_date_debut    --TRUNC(SYSDATE)
	           ) 
	      AND     ppa.ORG_ID IN (
                 SELECT
                     ORGANIZATION_ID
                 FROM
                     PER_SECURITY_ORGANIZATIONS
                 WHERE
                     SECURITY_PROFILE_ID = (
                         SELECT
                             SECURITY_PROFILE_ID
                         FROM
                             PER_SECURITY_PROFILES
                         WHERE
                             SECURITY_PROFILE_NAME = 'DKA_TOUT'
                                           )
                                )				  ;

  BEGIN

	SELECT start_date,end_date,period_year ,year_start_date 
    INTO  v_start_date,v_end_date,v_period_year ,v_start_date_a
    FROM  gl_periods gp
    WHERE period_name = P_PERIOD_NAME
    AND   period_set_name='GROUPE';

   /* SELECT ADD_MONTHS (TRUNC (v_start_date,'YEAR'), -12) 
   	,      TRUNC (v_start_date , 'YEAR') 
	  INTO  v_start_date_p
  	,     v_start_date_a
	  FROM  DUAL;

    SELECT ADD_MONTHS (TRUNC (v_start_date, 'YEAR'), -1 ) +30 
	  INTO  v_end_date_p
	  FROM  DUAL;*/
    
   /* SELECT  period_name  
    INTO  vg_period_n_1
    from  gl_periods  
    WHERE end_date = v_end_date_p 
    AND   period_set_name='GROUPE';*/
    SELECT period_name 
    INTO  vg_period_n_1
    from (select period_name
          from  gl_periods 
          where period_year = v_period_year-1  
          and period_set_name='GROUPE'
          order by start_date desc) 
    where  ROWNUM=1;
   
    SELECT gl.year_start_date,gl.end_date
	INTO   v_start_date_p , v_end_date_p
    FROM gl_periods gl
    WHERE gl.period_name = vg_period_n_1
    AND  gl.period_set_name='GROUPE';
   
	FOR L_TACHE IN CUR_TACHE(v_start_date) LOOP
--Determiner le type de la tache
		IF L_TACHE.TASK_NUMBER like 'GT%' THEN v_task_type := 'P3';
		ELSE v_task_type := 'P6';
		END IF;
--- Calcul revenu N-1
		FOR REC_REV_N_1 IN  (SELECT pcera.project_id
                            ,      pcera.task_id
                            ,      SUM(pcera.amount) REVENU_N_1
                            ,      glc.segment4

                            FROM pa_cust_event_rdl_all pcera 
                                ,gl_code_combinations glc
                                ,pa_projects_all ppa
                                ,pa_events pae
								--DEBUT AAM INC0422568
								,pa_draft_revenues_all padra 
								,PA_DRAFT_REVENUE_ITEMS PDRI
								--FIN AAM INC0422568
                            WHERE pcera.project_id = L_TACHE.project_id
                                AND pcera.task_id  = L_TACHE.task_id
                                AND glc.code_combination_id = pcera.code_combination_id
                                AND pae.project_id = ppa.project_id
                                AND pae.event_num  = pcera.event_num
                                AND pae.project_id = pcera.project_id
                                AND pae.task_id    = pcera.task_id								
								--DEBUT AAM INC0422568
								and pcera.PROJECT_ID =PDRI.PROJECT_ID 
                                and pcera.DRAFT_REVENUE_NUM = PDRI.DRAFT_REVENUE_NUM
                                and pcera.DRAFT_REVENUE_ITEM_LINE_NUM = PDRI.LINE_NUM
                                and padra.PROJECT_ID =PDRI.PROJECT_ID
                                and pcera.DRAFT_REVENUE_NUM = padra.DRAFT_REVENUE_NUM
								--FIN AAM INC0422568
                                AND glc.SEGMENT4 IN (
                                						SELECT
                                							FLEX_VALUE
                                						FROM
                                							FND_FLEX_VALUES_VL
                                						WHERE
                                							ATTRIBUTE8 = 'OUI'
                                							AND ATTRIBUTE9 IN  ('P3','P6')
                                							AND FLEX_VALUE_SET_ID IN (
                                								SELECT
                                									FLEX_VALUE_SET_ID
                                								FROM
                                									FND_FLEX_VALUE_SETS
                                								WHERE
                                									FLEX_VALUE_SET_NAME = 'DAOPCCF_ANALYTIQUE'
                                							)
                                					)			                		
                                --DEBUT AAM INC0422568  						
            			    	--AND pae.completion_date  between v_start_date_p AND  v_end_date_p
                                AND padra.gl_date between v_start_date_p AND  v_end_date_p  
                                --FIN AAM INC0422568  								
                            GROUP BY 
                                pcera.project_id,
                                pcera.task_id,
                                glc.segment4
							) LOOP	
							    INSERT INTO DKA_IPOEXTSOLDHERC values 
						               (REC_REV_N_1.project_id        ,
								            REC_REV_N_1.task_id           ,
								            L_TACHE.task_number          ,
								            L_TACHE.mode_gestion        ,
								            REC_REV_N_1.segment4          ,
								            REC_REV_N_1.REVENU_N_1        ,
								            0                             ,
								            0                             ,
								            0                             ,
								            v_task_type                   ,
								            L_TACHE.DATE_CLOTURE        ,
								            L_TACHE.DATE_PREV_FIN       ,
								            L_TACHE.devise              ,
								            SYSDATE                       ,
                            FND_PROFILE.VALUE('USER_ID')  ,
                            SYSDATE                       ,
                            FND_PROFILE.VALUE('USER_ID')  
								);
		                    END LOOP;                            

--- Calcul revenu N           	    
        FOR REC_REV_N IN  (SELECT pcera.project_id
                            ,      pcera.task_id
                            ,      SUM(pcera.amount) REVENU_N
                            ,      glc.segment4

                            FROM pa_cust_event_rdl_all pcera 
                                ,gl_code_combinations glc
                                ,pa_projects_all ppa
                                ,pa_events pae
								--DEBUT AAM INC0422568
								,pa_draft_revenues_all padra 
								,PA_DRAFT_REVENUE_ITEMS PDRI
								--FIN AAM INC0422568
                            WHERE pcera.project_id          = L_TACHE.project_id
                                AND pcera.task_id           = L_TACHE.task_id
                                AND glc.code_combination_id = pcera.code_combination_id
                                AND pae.project_id          = ppa.project_id
                                AND pae.event_num           = pcera.event_num
                                AND pae.project_id          = pcera.project_id
                                AND pae.task_id             = pcera.task_id
								--DEBUT AAM INC0422568
								and pcera.PROJECT_ID =PDRI.PROJECT_ID 
                                and pcera.DRAFT_REVENUE_NUM = PDRI.DRAFT_REVENUE_NUM
                                and pcera.DRAFT_REVENUE_ITEM_LINE_NUM = PDRI.LINE_NUM
                                and padra.PROJECT_ID =PDRI.PROJECT_ID
                                and pcera.DRAFT_REVENUE_NUM = padra.DRAFT_REVENUE_NUM
								--FIN AAM INC0422568
                                AND glc.SEGMENT4 IN (
                                						SELECT
                                							FLEX_VALUE
                                						FROM
                                							FND_FLEX_VALUES_VL
                                						WHERE
                                							ATTRIBUTE8 = 'OUI'
                                							AND ATTRIBUTE9 IN  ('P3','P6')
                                							AND FLEX_VALUE_SET_ID IN (
                                								SELECT
                                									FLEX_VALUE_SET_ID
                                								FROM
                                									FND_FLEX_VALUE_SETS
                                								WHERE
                                									FLEX_VALUE_SET_NAME = 'DAOPCCF_ANALYTIQUE'
                                							)
                                					)
							    --DEBUT AAM INC0422568  						
            			    	--AND pae.completion_date between v_start_date_a AND  v_end_date	
                                AND padra.gl_date between v_start_date_a AND  v_end_date  
                                --FIN AAM INC0422568  								
                            GROUP BY 
                                pcera.project_id,
                                pcera.task_id,
                                glc.segment4
                            )LOOP            		                                            				
							    INSERT INTO DKA_IPOEXTSOLDHERC values 
								           (REC_REV_N.project_id         ,
								            REC_REV_N.task_id            ,
								            L_TACHE.task_number        ,
								            L_TACHE.mode_gestion       ,
								            REC_REV_N.segment4           ,
								            0                            ,
								            REC_REV_N.REVENU_N           ,
								            0                            ,
								            0                            ,
								            v_task_type                  ,
								            L_TACHE.DATE_CLOTURE       ,
								            L_TACHE.DATE_PREV_FIN      ,
								            L_TACHE.devise             ,
								            SYSDATE                      ,
                            FND_PROFILE.VALUE('USER_ID') ,
                            SYSDATE                      ,
                            FND_PROFILE.VALUE('USER_ID')
								);
                            END LOOP;

--- Calcul depense N-1

		FOR REC_DEP_N_1 IN  (SELECT  ppa.project_id 
                            ,       pt.task_id
                            ,       glc.segment4
                            ,       SUM(pei.raw_cost) DEPENSE_N_1   --,       SUM(pei.burden_cost) DEPENSE_N_1

                            FROM pa_cost_distribution_lines_all pcd 
                            ,    pa_projects_all ppa
                            ,    pa_expenditure_items_all pei
                            ,    pa_tasks pt
                            ,    gl_code_combinations glc
                            WHERE  1=1
                            AND pcd.project_id          = L_TACHE.project_id
                            AND ppa.project_id          = pcd.project_id
                            AND ppa.project_id          = pei.project_id
                            AND ppa.project_id          = pt.project_id 
                            AND pcd.expenditure_item_id = pei.expenditure_item_id
                            AND glc.code_combination_id = pcd.dr_code_combination_id
                            AND pt.task_id              =  L_TACHE.task_id
                            AND pcd.TASK_ID = PT.TASK_ID
                            AND glc.SEGMENT4 IN (
                            						SELECT
                            							FLEX_VALUE
                            						FROM
                            							FND_FLEX_VALUES_VL
                            						WHERE
                            							ATTRIBUTE8 = 'OUI'
                            							AND ATTRIBUTE9 IN('P3','P6')
                            							AND FLEX_VALUE_SET_ID IN (
                            								SELECT
                            									FLEX_VALUE_SET_ID
                            								FROM
                            									FND_FLEX_VALUE_SETS
                            								WHERE
                            									FLEX_VALUE_SET_NAME = 'DAOPCCF_ANALYTIQUE'
                            							)
                            					)
							--DEBUT AAM INC0422568 
							--AND pei.expenditure_item_date between v_start_date_p AND  v_end_date_p
			                AND pcd.GL_DATE between v_start_date_p AND  v_end_date_p	
                            --FIN AAM INC0422568 							
                            group by 
                             ppa.project_id ,
                             pt.task_id,
                             glc.segment4
                            ) LOOP
							    INSERT INTO DKA_IPOEXTSOLDHERC values 
								         (REC_DEP_N_1.project_id        ,
								          REC_DEP_N_1.task_id           ,
								          L_TACHE.task_number          ,
								          L_TACHE.mode_gestion        ,
								          REC_DEP_N_1.segment4          ,
								          0                             ,
								          0                             ,
								          REC_DEP_N_1.DEPENSE_N_1       ,
								          0                             ,
								          v_task_type                   ,
								          L_TACHE.DATE_CLOTURE        ,
								          L_TACHE.DATE_PREV_FIN       ,
								          L_TACHE.devise              ,
								          SYSDATE                       ,
                          FND_PROFILE.VALUE('USER_ID')  ,
                          SYSDATE                       ,
                          FND_PROFILE.VALUE('USER_ID')  
								 );

							END LOOP;

--- Calcul depense N
        FOR REC_DEP_N IN    (SELECT  ppa.project_id 
                            ,       pt.task_id
                            ,       glc.segment4
                            ,       SUM(pei.raw_cost) DEPENSE_N   --,       SUM(pei.burden_cost) DEPENSE_N

                            FROM pa_cost_distribution_lines_all pcd 
                            ,    pa_projects_all ppa
                            ,    pa_expenditure_items_all pei
                            ,    pa_tasks pt
                            ,    gl_code_combinations glc
                            WHERE  1=1
                            AND pcd.project_id          = L_TACHE.project_id
                            AND ppa.project_id          = pcd.project_id
                            AND ppa.project_id          = pei.project_id
                            AND ppa.project_id          = pt.project_id 
                            AND pcd.expenditure_item_id = pei.expenditure_item_id
                            AND glc.code_combination_id = pcd.dr_code_combination_id
                            AND pt.task_id              =  L_TACHE.task_id
                            AND pcd.TASK_ID             = PT.TASK_ID
                            AND glc.SEGMENT4 IN (
                                						SELECT
                                							FLEX_VALUE
                                						FROM
                                							FND_FLEX_VALUES_VL
                                						WHERE
                                							ATTRIBUTE8 = 'OUI'
                                							AND ATTRIBUTE9 IN  ('P3','P6')
                                							AND FLEX_VALUE_SET_ID IN (
                                								SELECT
                                									FLEX_VALUE_SET_ID
                                								FROM
                                									FND_FLEX_VALUE_SETS
                                								WHERE
                                									FLEX_VALUE_SET_NAME = 'DAOPCCF_ANALYTIQUE'
                                							)
                                					)
							--DEBUT AAM INC0422568 
							--AND pei.expenditure_item_date between v_start_date_a AND  v_end_date						
                            AND pcd.GL_DATE between v_start_date_a AND  v_end_date		
                            --FIN AAM INC0422568 							
                            group by 
                             ppa.project_id ,
                             pt.task_id,
                             glc.segment4
                            )LOOP
							    INSERT INTO DKA_IPOEXTSOLDHERC values 
								          (REC_DEP_N.project_id          ,
								           REC_DEP_N.task_id             ,
								           L_TACHE.task_number          ,
								           L_TACHE.mode_gestion        ,
								           REC_DEP_N.segment4            ,
								           0                             ,
								           0                             ,
								           0                             ,
								           REC_DEP_N.DEPENSE_N           ,
								           v_task_type                   ,
								           L_TACHE.DATE_CLOTURE        ,
								           L_TACHE.DATE_PREV_FIN       ,
								           L_TACHE.devise              ,
								           SYSDATE                       ,
                           FND_PROFILE.VALUE('USER_ID')  ,
                           SYSDATE                       ,
                           FND_PROFILE.VALUE('USER_ID') 
								);
                            END LOOP;									
	END LOOP;	

  EXCEPTION
    WHEN OTHERS THEN
     p_validate(FALSE, 'Probleme dans la procedure p_extract_data(' || SQLERRM || ')');

  END p_extract_data;
   ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data_type_p3
  --  Description   : Extrait des lignes des travaux de type P3 
  --
  --  PARAMETRES    :
  --  p_directory_name        Nom du directory
  --  p_file_name             Nom du fichier
  --  p_nb_lignes             Nombre de lignes inserees
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data_type_p3(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name      IN VARCHAR2,
                           P_PERIOD_NAME    IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2) IS

    vv_ligne      VARCHAR2(4000);
    vn_nb_lignes  NUMBER := 0;
	L_line_count  NUMBER := 0;
    l_file        UTL_FILE.file_type;

	 /*//-- cursor pour extraction des lignes des travaux de type P6//*/

	CURSOR CUR_DATA_P3 IS 
	   SELECT   ID_PROJET               
              , ID_TACHE 
			        , NUM_TACHE
              , MODE_GESTION			  
              , COMPTE                  
              , SUM(REVENU_N_1)  REVENU_N_1            
              , SUM(REVENU_N)    REVENU_N            
              , SUM(DEPENSE_N_1) DEPENSE_N_1            
              , SUM(DEPENSE_N)   DEPENSE_N            
              , TYPE_TACHE              
              , DATE_CLOTURE            
              , DATE_PREV_FIN           
              , DEVISE                  
	   FROM DKA_IPOEXTSOLDHERC
	   WHERE TYPE_TACHE ='P3'
	   GROUP BY ID_PROJET               
              , ID_TACHE 
              , NUM_TACHE
              , MODE_GESTION
              , COMPTE
              , TYPE_TACHE              
              , DATE_CLOTURE            
              , DATE_PREV_FIN           
              , DEVISE;


    l_message_c           VARCHAR2(2000);
    l_entête              VARCHAR2(2000);

	v_PERIODE_N_1     VARCHAR2(50);
	v_SOLDE_N_1       NUMBER;
    v_SOLDE_N         NUMBER;

  BEGIN
    L_line_count := 0;
    -- Verification de l'existence du directory
    p_check_directory(p_directory_name);

    -- Ouverture du fichier
    l_file      := UTL_FILE.fopen(p_directory_name, p_file_name, 'W',32767);
	-- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      p_put_debug_message('Le fichier ' || p_directory_name || '/' ||p_file_name || ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
    END IF;
    l_entête:=
                            'NUM_TACHE'
                            ||G_separateur||'MODE_GESTION'
                            ||G_separateur||'DATE_CLOTURE'
                            ||G_separateur||'DATE_PREV_FIN'
                            ||G_separateur||'DEVISE'
                            ||G_separateur||'NUM_COMPTE'
                            ||G_separateur||'PERIODE N-1'
                            ||G_separateur||'SOLDE N-1'
                            ||G_separateur||'PERIODE N'
                            ||G_separateur||'SOLDE N'

                            ;
    UTL_FILE.PUT_LINE(l_file, l_entête);
    -- Extraction des donnees
    FOR l_tache IN CUR_DATA_P3 LOOP
	    v_PERIODE_N_1 := vg_period_n_1;
        v_SOLDE_N_1   := l_tache.REVENU_N_1 - l_tache.DEPENSE_N_1  ;
        v_SOLDE_N     := l_tache.REVENU_N   - l_tache.DEPENSE_N    ;
        -- IF v_SOLDE_N_1 != 0 OR v_SOLDE_N != 0 THEN
          l_message_c :=
                   l_tache.NUM_TACHE
                   ||G_separateur||l_tache.MODE_GESTION
                   ||G_separateur||l_tache.DATE_CLOTURE
                   ||G_separateur||l_tache.DATE_PREV_FIN
                   ||G_separateur||l_tache.DEVISE
                   ||G_separateur||l_tache.COMPTE
                   ||G_separateur||v_PERIODE_N_1
                   ||G_separateur||v_SOLDE_N_1
                   ||G_separateur||P_PERIOD_NAME
                   ||G_separateur||v_SOLDE_N;
          
          L_line_count := L_line_count + 1;		
	      UTL_FILE.PUT_LINE(l_file, l_message_c);
		--END IF;
    END LOOP;	
    IF UTL_FILE.IS_OPEN(l_file) THEN
        UTL_FILE.FCLOSE(l_file);	
	END IF;	

	   -- Remet les valeurs des compteurs dans les parametres de la procedure
	   vg_nbl_extr_fact:=L_line_count;
	   p_put_debug_message('L''écriture dans le fichier ' || p_directory_name || '/' ||p_file_name || ' est terminée');
	   p_put_debug_message('Le nombre de lignes dans le fichier ' || p_directory_name || '/' ||p_file_name || ' est :'|| vg_nbl_extr_fact);
  EXCEPTION
    WHEN OTHERS THEN
     p_validate(FALSE, 'Probleme dans la procedure p_extract_data_type_p6 (' || SQLERRM || ')');

  END p_extract_data_type_p3;
     ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data_type_p6
  --  Description   : Extrait des lignes des travaux de type P6
  --
  --  PARAMETRES    :
  --  p_directory_name        Nom du directory
  --  p_file_name             Nom du fichier
  --  p_nb_lignes             Nombre de lignes inserees
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data_type_p6(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name      IN VARCHAR2,
                           P_PERIOD_NAME    IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2) IS

    vv_ligne      VARCHAR2(4000);
    vn_nb_lignes  NUMBER := 0;
	L_line_count  NUMBER := 0;
    l_file        UTL_FILE.file_type;

	 /*//-- cursor pour extraction des lignes des travaux de type P6//*/

	CURSOR CUR_DATA_P6 IS 
	   SELECT   ID_PROJET               
              , ID_TACHE 
			        , NUM_TACHE
              , MODE_GESTION			  
              , COMPTE                  
              , SUM(REVENU_N_1)  REVENU_N_1            
              , SUM(REVENU_N)    REVENU_N            
              , SUM(DEPENSE_N_1) DEPENSE_N_1            
              , SUM(DEPENSE_N)   DEPENSE_N            
              , TYPE_TACHE              
              , DATE_CLOTURE            
              , DATE_PREV_FIN           
              , DEVISE                  
	   FROM DKA_IPOEXTSOLDHERC
	   WHERE TYPE_TACHE ='P6'
	   GROUP BY ID_PROJET               
              , ID_TACHE     
              , NUM_TACHE
              , MODE_GESTION
              , COMPTE
              , TYPE_TACHE              
              , DATE_CLOTURE            
              , DATE_PREV_FIN           
              , DEVISE;


    l_message_c           VARCHAR2(2000);
    l_entête              VARCHAR2(2000);

	v_PERIODE_N_1     VARCHAR2(50);
	v_SOLDE_N_1       NUMBER;
    v_SOLDE_N         NUMBER;

  BEGIN
    L_line_count := 0;
    -- Verification de l'existence du directory
    p_check_directory(p_directory_name);

    -- Ouverture du fichier
    l_file      := UTL_FILE.fopen(p_directory_name, p_file_name, 'W',32767);
	-- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      p_put_debug_message('Le fichier ' || p_directory_name || '/' ||p_file_name || ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
    END IF;
    l_entête:=
                            'NUM_TACHE'
                            ||G_separateur||'MODE_GESTION'
                            ||G_separateur||'DATE_CLOTURE'
                            ||G_separateur||'DATE_PREV_FIN'
                            ||G_separateur||'DEVISE'
                            ||G_separateur||'NUM_COMPTE'
                            ||G_separateur||'PERIODE N-1'
                            ||G_separateur||'SOLDE N-1'
                            ||G_separateur||'PERIODE N'
                            ||G_separateur||'SOLDE N'

                            ;
    UTL_FILE.PUT_LINE(l_file, l_entête);
    -- Extraction des donnees
    FOR l_tache IN CUR_DATA_P6 LOOP

	    v_PERIODE_N_1 := vg_period_n_1;
        v_SOLDE_N_1   := l_tache.REVENU_N_1 - l_tache.DEPENSE_N_1  ;
        v_SOLDE_N     := l_tache.REVENU_N   - l_tache.DEPENSE_N    ;
        --IF v_SOLDE_N_1 != 0 OR v_SOLDE_N != 0 THEN
          l_message_c :=
                   l_tache.NUM_TACHE
                   ||G_separateur||l_tache.MODE_GESTION
                   ||G_separateur||l_tache.DATE_CLOTURE
                   ||G_separateur||l_tache.DATE_PREV_FIN
                   ||G_separateur||l_tache.DEVISE
                   ||G_separateur||l_tache.COMPTE
                   ||G_separateur||v_PERIODE_N_1
                   ||G_separateur||v_SOLDE_N_1
                   ||G_separateur||P_PERIOD_NAME
                   ||G_separateur||v_SOLDE_N;
          
          L_line_count := L_line_count + 1;		
	      UTL_FILE.PUT_LINE(l_file, l_message_c);
		--END IF;
    END LOOP;	
    IF UTL_FILE.IS_OPEN(l_file) THEN
        UTL_FILE.FCLOSE(l_file);	
	END IF;	

	   -- Remet les valeurs des compteurs dans les parametres de la procedure
	   vg_nbl_extr_fact:=L_line_count;
	   p_put_debug_message('L''écriture dans le fichier ' || p_directory_name || '/' ||p_file_name || ' est terminée');
	   p_put_debug_message('Le nombre de lignes dans le fichier ' || p_directory_name || '/' ||p_file_name || ' est :'|| vg_nbl_extr_fact);
  EXCEPTION
    WHEN OTHERS THEN
     p_validate(FALSE, 'Probleme dans la procedure p_extract_data_type_p6 (' || SQLERRM || ')');

  END p_extract_data_type_p6;
  ------------------------------------------------------------------------------------
  --  Nom           : Output_Header
  --  Description   : Procédure pour insérer une en-tête dans le fichier de sortie
  --
  --  PARAMETRES    :
  --              
  --
  ------------------------------------------------------------------------------------  

  PROCEDURE output_header IS
    cv_line                  VARCHAR2(100);
    v_conc_program_name      fnd_concurrent_programs.concurrent_program_name%TYPE;
    v_user_conc_program_name fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN

    cv_line := '+-------------------------------------------------------------------------+';

    ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
    BEGIN
      SELECT fcp.concurrent_program_name, fcpt.user_concurrent_program_name
        INTO v_conc_program_name, v_user_conc_program_name
        FROM fnd_concurrent_programs fcp, fnd_concurrent_programs_tl fcpt
       WHERE fcp.application_id = Fnd_Global.prog_appl_id
         AND fcp.concurrent_program_id = Fnd_Global.conc_program_id
         AND fcpt.application_id = Fnd_Global.prog_appl_id
         AND fcpt.concurrent_program_id = Fnd_Global.conc_program_id
         AND fcpt.LANGUAGE = Fnd_Global.current_language;
    EXCEPTION
      WHEN OTHERS THEN
        v_user_conc_program_name := '???????????????????????';
        v_conc_program_name      := '???????';
    END;

    Fnd_File.put_line(Fnd_File.output, cv_line || CHR(10));
    Fnd_File.put_line(Fnd_File.output,
                      'Nom du traitement  : ' || v_user_conc_program_name);
    Fnd_File.put_line(Fnd_File.output,
                      'Code du traitement : ' || v_conc_program_name);
    Fnd_File.put_line(Fnd_File.output,
                      'Programme lancé le : ' ||
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
    Fnd_File.put_line(Fnd_File.output, cv_line || CHR(10) || CHR(10));
  END output_header;
  ------------------------------------------------------------------------------------
  --  Nom           : Output_Header
  --  Description   : Procédure pour insérer une en-tête dans le fichier de sortie
  --
  --  PARAMETRES    :
  --              
  --
  ------------------------------------------------------------------------------------  
  PROCEDURE PURGE_TABLE IS
  BEGIN
     DELETE FROM DKA_IPOEXTSOLDHERC;
     COMMIT;
  END PURGE_TABLE;
  ------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : point d'entrée du traitement
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------
  PROCEDURE main(
  pv_errbuf OUT NOCOPY VARCHAR2, pn_retcode OUT NOCOPY NUMBER, P_PERIOD_NAME IN VARCHAR2) IS

    lv_current_program_unit VARCHAR2(30) := 'main';
    lv_nom_fichier1          VARCHAR2(200);
	lv_nom_fichier2          VARCHAR2(200);
    ln_nb_lignes            NUMBER:=0;


	lv_EXTRACT_MAN VARCHAR2(3);
     cn_tempo                CONSTANT NUMBER       := 20;
     vn_user_id                       NUMBER (15);
    vn_request_id                    NUMBER (15);
    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);

  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS=''' || ',.' || '''';
	  ---Purge de la table de travail DKA_IPOEXTSOLDHERC
	  PURGE_TABLE;
	  ---Alimentation de la table de travail DKA_IPOEXTSOLDHERC
  	p_extract_data (P_PERIOD_NAME);
    COMMIT;
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'DEBUT DE L''INTERFACE');
    Output_Header;

    -- Construction du premier nom du fichier
    lv_nom_fichier1 := 'ComptesgroupesP3_ORACLE_' || TO_CHAR(SYSDATE, 'YYYYMMDD')  ||'.csv'; 	
	  -- Construction du deuxième nom du fichier
    lv_nom_fichier2 := 'ComptesgroupesP6_ORACLE_' || TO_CHAR(SYSDATE, 'YYYYMMDD')  ||'.csv'; 				  				  

    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE D''EXTRACTION DES DONNEES');

    -- Extrait les lignes d'écritures dans le premier fichier 

     p_extract_data_type_p3(vg_DIRECTORY, lv_nom_fichier1, p_period_name,ln_nb_lignes);
	   -- Extrait les lignes d'écritures dans le deuxième fichier 
	   p_extract_data_type_p6(vg_DIRECTORY, lv_nom_fichier2, p_period_name, ln_nb_lignes);
     Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'AFFICHAGE DU BILAN');
     ---- compression des fichiers de sortie en zip
     Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Lancement de traitement de compression des fichiers ');
     compression_fichier_sortie;

     -- Edite un rapport de traitment
            bilan(p_period_name ,
                    lv_nom_fichier1 ,
                    lv_nom_fichier2);



  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure ' || vg_package_name || '.' || lv_current_program_unit || chr(10) || SQLERRM;
      pn_retcode := 2;
  END main;

    ------------------------------------------------------------------------------------
  --  Nom           : bilan
  --  Description   : Affichage des stats

  ------------------------------------------------------------------------------------
  PROCEDURE bilan( p_period_name varchar2,
                    p_file_name1 varchar2,
                    p_file_name2 varchar2) IS

  BEGIN



    Fnd_File.put_line(Fnd_File.log,
                      '---------------------Bilan du traitement------------------------------------');
    Fnd_File.put_line(Fnd_File.log,
                      'TRAITEMENT, lancé le ' ||
                      to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS'));
    Fnd_File.put_line(Fnd_File.log,
                      'Paramètre du traitement :---------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.log, '1) Période  : ' || p_period_name);


    Fnd_File.put_line(Fnd_File.log, chr(10));

    Fnd_File.put_line(Fnd_File.log,
                      '---------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.log,
                      '-- BILAN                                                 ');
    Fnd_File.put_line(Fnd_File.log,
                      '---------------------------------------------------------');


    IF vg_nbl_extr_cmd > 0 THEN
      Fnd_File.put_line(Fnd_File.log,
                        'le nombre de lignes générées dans le fichier '||p_file_name1||' est : ' || vg_nbl_extr_cmd ||
                        ' lignes.');
    ELSE
      Fnd_File.put_line(Fnd_File.log, 'Aucune ligne trouvée pour le fichier '||p_file_name1);
    END IF;

     IF vg_nbl_extr_fact > 0 THEN
      Fnd_File.put_line(Fnd_File.log,
                        'le nombre de lignes générées dans le fichier '||p_file_name2||' est : ' || vg_nbl_extr_fact||
                        ' lignes.');
    ELSE
     Fnd_File.put_line(Fnd_File.log, 'Aucune ligne trouvée pour le fichier '||p_file_name2);
    END IF;


  END bilan;

  procedure compression_fichier_sortie 
  as


    cn_tempo                        CONSTANT NUMBER       := 20;
    vn_user_id                      NUMBER (15);
    vn_request_id                    NUMBER (15);
    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
  begin


                vn_request_id := FND_REQUEST.SUBMIT_REQUEST(
                  'DKA',
                  'DKA_COMPRESS_FICH_HERC',
                  '',
                  '', 
                  FALSE,
                  'DKA',
                  vg_directory_path,
                  '',
                  '',
                  '',
                  '',
                  '',
                  '',
                  '',
                  '',
                   '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '');
                    COMMIT;
                  vg_request_id_cf:=vn_request_id;

      Fnd_File.put_line(Fnd_File.output,
                      'TRAITEMENT, lancé le ' ||
                      to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS'));

     Fnd_File.put_line(Fnd_File.log, 'Validation pour que les GTS puissent prendre la demande');

    IF vn_request_id = 0
    THEN
         Fnd_File.put_line(Fnd_File.log, 'Impossible de lancer le Traitement de compression dse fichiers de sorties ');
        RETURN;
    END IF;
 Fnd_File.put_line(Fnd_File.log, 'Traitement de Compression de fichier numéro : ' || TO_CHAR (vn_request_id));

    IF NOT fnd_concurrent.wait_for_request (vn_request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message)
    THEN

        RETURN;
    ELSE
        IF vv_dstatus = 'WARNING'
        THEN
           Fnd_File.put_line(Fnd_File.log,CHR (10) || '>>> Traitement termine en Warning ');

            RETURN;
        ELSIF vv_dstatus != 'NORMAL'
        THEN
              Fnd_File.put_line(Fnd_File.log,CHR (10) || '>>> Traitement termine en Erreur ');
            RETURN;
        END IF;
    END IF;
    IF vv_dstatus != 'NORMAL'then 
       Fnd_File.put_line(Fnd_File.log,CHR (10) || '>>> Traitement termine en Erreur ');
    END IF;
   Fnd_File.put_line(Fnd_File.log,'>>> Fin normale');

     IF vv_dstatus = 'NORMAL'then 
       Fnd_File.put_line(Fnd_File.log,CHR (10) || '>>> Le traitement à généré le dossier: -	ComptesgroupesP3_ORACLE_'||to_char (sysdate,'yyyymmdd')||' dans le chemin  '||vg_directory_path);
	   Fnd_File.put_line(Fnd_File.log,CHR (10) || '>>> Le traitement à généré le dossier: - ComptesgroupesP6_ORACLE_'||to_char (sysdate,'yyyymmdd')||' dans le chemin  '||vg_directory_path);
    END IF;

EXCEPTION
    WHEN OTHERS
    THEN
          Fnd_File.put_line(Fnd_File.log,(' ==> ERREUR : ' || SQLERRM));
  end compression_fichier_sortie;

END DKA_IPOEXTSOLDHERC_PKG;







/
SHOW ERRORS;

EXIT
