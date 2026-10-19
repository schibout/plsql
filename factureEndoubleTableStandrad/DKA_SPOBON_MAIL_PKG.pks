create or replace PACKAGE BODY DKA_FUSPOIMPCTRSSTR_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_FUSPOIMPCTRSSTR_PKG.pkb  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    Création du package de l'interface specifique d'import des contrats SSTR
--
-- USAGE
--    A exécuter sous SqlPlus avec user APPS sans paramètre
--
-- NOTES
--
-- PARAMETERS
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Date           Qui Description
-- -------------- --- ---------------------------------------------------------------
-- 28/03/2016     RBE Creation
-- 18/08/2017     RBE Correctif artf2212570 : Ajout LATEST_EXTERNAL_FLAG
---------------------------------------------------------------------------------------------

 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    TYPE summary_typ IS RECORD 
    (
     loaded_header_rows               NUMBER      -- Nb des en-entêtes à traiter  en table specifique
    ,loaded_detail_rows               NUMBER      -- Nb des détails à traiter  en table specifique
    ,loaded_imput_rows                NUMBER      -- Nb des imputations à traiter  en table specifique
    ,rejected_header_rows             NUMBER      -- Nb de Lignes en-entêtes rejectées
    ,rejected_detail_rows             NUMBER      -- Nb de Lignes détail rejectés
    ,rejected_imput_rows              NUMBER      -- Nb de Lignes imputation rejectées
    ,inserted_header_rows             NUMBER      -- Nb de Lignes en-entêtes insérées
    ,inserted_detail_rows             NUMBER      -- Nb de Lignes detail insérés
    ,inserted_imput_rows              NUMBER      -- Nb de Lignes d'imputations insérées
    ,loaded_header_hist_rows          NUMBER      -- Nb des en-entêtes chargées en table specifique
    ,loaded_detail_hist_rows          NUMBER      -- Nb des détails chargés en table specifique
    ,loaded_imput_hist_rows           NUMBER      -- Nb des imputations chargées en table specifique
    ,rejected_header_hist_rows        NUMBER      -- Nb de Lignes en-entêtes rejectées
    ,rejected_detail_hist_rows        NUMBER      -- Nb de Lignes détail rejectés
    ,rejected_imput_hist_rows         NUMBER      -- Nb de Lignes imputation rejectées
    ,inserted_header_hist_rows        NUMBER      -- Nb de Lignes en-entêtes insérées
    ,inserted_detail_hist_rows        NUMBER      -- Nb de Lignes detail insérés
    ,inserted_imput_hist_rows         NUMBER      -- Nb de Lignes d'imputations insérées
    ,purged_header_rows               NUMBER      -- Nb de Lignes purgées en table spécifique   
    ,purged_detail_rows               NUMBER      -- Nb de Lignes purgées en table spécifique 
    ,purged_imput_rows                NUMBER      -- Nb de Lignes purgées en table spécifique 
    ,message_flag                     NUMBER      -- Flag d'entete etat des erreurs
    ,reprise_flag                     VARCHAR2(1) -- Flag reprise
    )
    ;

    g_summary                      summary_typ;
    g_user_id                      fnd_user.user_id%TYPE;
    g_login_id                     fnd_logins.login_id%TYPE;
    g_org_id                       hr_all_organization_units.organization_id%TYPE;
    g_request_id                   fnd_concurrent_requests.request_id%TYPE;
    g_loader_request_id            fnd_concurrent_requests.request_id%TYPE;
    gv_printer                     fnd_concurrent_requests.printer%TYPE;
    g_number_of_copies             fnd_concurrent_requests.number_of_copies%TYPE;
    g_tempo                        NUMBER;


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

        v_current_program_unit    VARCHAR2(30);
        v_step_program_error      VARCHAR2(1000);
        program_error             EXCEPTION;

BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début init');

        ----------------------------------
        -- Initialisation des variables --
        ----------------------------------
        p_errbuf  := NULL;
        p_retcode := 0;
        v_current_program_unit := 'INIT';

        ------------------------
        -- Variables globales --
        ------------------------ 

        g_user_id                      := fnd_global.user_id;
        g_login_id                     := fnd_global.login_id;
        g_request_id                   := fnd_global.conc_request_id;
        g_org_id                       := fnd_profile.value ('ORG_ID');
        g_tempo                        := 20;

        -- Variables globales de comptage

        g_summary.loaded_header_rows             := 0;
        g_summary.loaded_detail_rows             := 0;
        g_summary.loaded_imput_rows              := 0;
        g_summary.rejected_header_rows           := 0;
        g_summary.rejected_detail_rows           := 0;
        g_summary.rejected_imput_rows            := 0;
        g_summary.inserted_header_rows           := 0;
        g_summary.inserted_detail_rows           := 0;
        g_summary.inserted_imput_rows            := 0;
        g_summary.loaded_header_hist_rows        := 0;
        g_summary.loaded_detail_hist_rows        := 0;
        g_summary.loaded_imput_hist_rows         := 0;
        g_summary.rejected_header_hist_rows      := 0;
        g_summary.rejected_detail_hist_rows      := 0;
        g_summary.rejected_imput_hist_rows       := 0;
        g_summary.inserted_header_hist_rows      := 0;
        g_summary.inserted_detail_hist_rows      := 0;
        g_summary.inserted_imput_hist_rows       := 0;
        g_summary.purged_header_rows             := 0;
        g_summary.purged_detail_rows             := 0;
        g_summary.purged_imput_rows              := 0;
        g_summary.message_flag                   := 0;
        g_summary.reprise_flag                   := 'Y';

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin init');

    BEGIN
           SELECT printer
                 ,number_of_copies
           INTO   gv_printer
                 ,g_number_of_copies
           FROM   fnd_concurrent_requests fcr
           WHERE  fcr.request_id = g_request_id;
           EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
           Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Erreur de récupération de l''imprimante');
           gv_printer := NULL;
           g_number_of_copies := 0;
    END;

    EXCEPTION
            WHEN program_error THEN
             fnd_file.put_line(fnd_file.log, 'ERREUR : ' || v_step_program_error);
             RAISE; 
            WHEN OTHERS
            THEN
            p_retcode   := 2;
            p_errbuf    := 'INIT : ' ||SQLERRM;
END init;


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

        cv_line    := '+-------------------------------------------------------------------------+';

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
        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Nom du traitement  : ' || v_user_conc_program_name);
        Fnd_File.put_line (Fnd_File.output, 'Code du traitement : ' || v_conc_program_name);
        Fnd_File.put_line (Fnd_File.output, 'Programme lancé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10) || CHR(10));
 END output_header;


 /*
 *************************************************************************
 * PROCEDURE NAME : Request_parameters
 *
 * DESCRIPTION
 *  Procédure pour afficher les valeurs de paramètres du traitement
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 ************************************************************************
 */

 PROCEDURE Request_parameters
  IS

        CURSOR cur_parameters
            IS
            SELECT form_left_prompt
            FROM   fnd_concurrent_requests fcr,
                   fnd_concurrent_programs fcp,
                   fnd_descr_flex_col_usage_vl fdfcu
            WHERE  fdfcu.descriptive_flexfield_name = '$SRS$.'||fcp.concurrent_program_name
            AND    fcp.concurrent_program_id = fcr.concurrent_program_id
            AND    fcr.request_id = Fnd_Global.conc_request_id
            ORDER BY fdfcu.column_seq_num
            ;
        rec_parameters        cur_parameters%ROWTYPE;
        sql_req               VARCHAR2(500);
        v_argument_number     VARCHAR2(12);
        v_argument_num        NUMBER;
        v_argument_value      VARCHAR2(240);
BEGIN

        Fnd_File.put_line (Fnd_File.output, 'PARAMETRES : ');
        Fnd_File.put_line (Fnd_File.output, '--------------');
        Fnd_File.put_line (Fnd_File.log, 'PARAMETRES : ');
        Fnd_File.put_line (Fnd_File.log, '--------------');

        v_argument_num := 1;

        OPEN cur_parameters;
        FETCH cur_parameters INTO rec_parameters;

            IF (cur_parameters%FOUND)
            THEN
                    v_argument_number := 'ARGUMENT'||v_argument_num;

                    sql_req := 'SELECT '||v_argument_number||
                              ' FROM fnd_concurrent_requests '||
                              'WHERE request_id = Fnd_Global.conc_request_id';

                    EXECUTE IMMEDIATE sql_req INTO v_argument_value;

                    Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
                    Fnd_File.put_line (Fnd_File.log, rec_parameters.form_left_prompt||' : '||v_argument_value);


            LOOP
                    FETCH cur_parameters INTO rec_parameters;
                    EXIT WHEN cur_parameters%NOTFOUND;

                    v_argument_num := v_argument_num + 1;
                    v_argument_number := 'ARGUMENT'||v_argument_num;

                    sql_req := 'SELECT '||v_argument_number||
                               ' FROM fnd_concurrent_requests '||
                               'WHERE request_id = Fnd_Global.conc_request_id';

                    EXECUTE IMMEDIATE sql_req INTO v_argument_value;

                    Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
                    Fnd_File.put_line (Fnd_File.log, rec_parameters.form_left_prompt||' : '||v_argument_value);
            END LOOP;

                   Fnd_File.put_line (Fnd_File.output,CHR(10));

            ELSE
                   Fnd_File.put_line (Fnd_File.output,'Aucun argument');
                   Fnd_File.put_line (Fnd_File.log,'Aucun argument');
            END IF;

        CLOSE cur_parameters;

 END Request_parameters;

 /*
 *************************************************************************
 * PROCEDURE NAME : Output_End
 *
 * DESCRIPTION
 *  Procédure pour insérer une fin dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

 PROCEDURE output_end
  IS
        cv_line                     VARCHAR2 (100);
  BEGIN
        cv_line    := '+-------------------------------------------------------------------------+';
        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
        Fnd_File.put_line (Fnd_File.output, cv_line);
  END output_end; 

 /*
 *************************************************************************
 * PROCEDURE NAME : Add_Message
 *
 * DESCRIPTION
 *  Procédure pour insérer un message dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

 PROCEDURE Add_Message  (p_document_num      IN  VARCHAR2,
                          p_type              IN  VARCHAR2,
                          p_line_num          IN  VARCHAR2,
                          p_message_text      IN  VARCHAR2
                          ) 
  IS
        cv_line                     VARCHAR2 (500);
BEGIN

    IF  g_summary.message_flag = 0 THEN
      cv_line := 'Etat des erreurs :';
      Fnd_File.put_line (Fnd_File.output, CHR(10)||cv_line);
      cv_line := '-----------------';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := 'Numéro de document  Type   Id de la ligne de contrat  Message d''erreur';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := '------------------  ------ -------------------------  ---------------';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      g_summary.message_flag := 1;
    END IF;
    cv_line := RPAD(p_document_num,18,' ') ||'  '|| RPAD(NVL(p_type,' '),6,' ') || ' ' ||RPAD(NVL(p_line_num,' '),25,' ') ||'  ' || p_message_text ;
    Fnd_File.put_line (Fnd_File.output, cv_line);

END Add_Message; 

/*
*************************************************************************
 * FUNCTION NAME : get_organization_id
 *
 * DESCRIPTION
 *  Fonction pour récupérer le party_id du fournisseur
 *
 * PARAMETERS
 * ==========
 * NAME                    DESCRIPTION
 * ----------------------- -------------------------------------------------
 * p_vendor_name           Nom du fournisseur
 *
 * RETURN
 * ======
 * party_id   
 *
 ************************************************************************
 */

 FUNCTION get_organization_id (
                                 p_org_id        IN NUMBER

                              )          
  RETURN NUMBER
  IS
    v_organization_id NUMBER;

BEGIN  
 -- Recherche  de l'org_id          
    BEGIN
		SELECT
                HOU.ORGANIZATION_ID
				into v_organization_id
        FROM
                HR_ORGANIZATION_UNITS HOU,
                DKA_STRANSCO_LINES DSTL,
                DKA_STRANSCO_HEADERS DSTH
        WHERE
                 DSTL.SET_ID = DSTH.SET_ID
                AND HOU.NAME = DSTL.RETURN_VALUE
                AND DSTL.param1_value=(select name from HR_ORGANIZATION_UNITS hr where hr.organization_id=p_org_id)
                AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                AND DSTL.ENABLE = 'Y'
                AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
				and rownum<2
        ;


            EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
        v_organization_id := -1;
    END;

     ----- return value -----
     RETURN (v_organization_id);  

 END get_organization_id;  

 /*
 *************************************************************************
 * PROCEDURE NAME : validate_data
 * 
 * DESCRIPTION
 *  Procédure d'insertion dans les tables finales
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 * 
 ************************************************************************
 */
  PROCEDURE validate_data(  p_Errbuf            OUT VARCHAR2,
                            p_retcode           OUT NUMBER
                          ) 
  IS
    v_message                 VARCHAR2 (500);
    v_AGENT_ID                NUMBER;
    V_VENDOR_ID               NUMBER;
    V_VENDOR_SITE_ID          NUMBER;
    v_ship_TO_LOCATION_ID     NUMBER;
    v_BILL_TO_LOCATION_ID     NUMBER;
    v_TERM_ID                 NUMBER;
    v_STYLE_ID                NUMBER;
    v_CONTRAT_IMPUTATION_ID   NUMBER;
    v_CODE_COMBINATION_ID     NUMBER;
    l_charge_account_flex_new_id  gl_code_combinations_kfv.code_combination_id%TYPE; 
    v_org_id                  NUMBER;
    V_COUNT_PO_HEADERS        NUMBER := 0;
    v_commande_id             NUMBER;
    v_cadre_po_header_id      NUMBER;
    v_person_id               NUMBER;
    v_project_id              NUMBER;
    v_task_id                 NUMBER;
    v_location_id             NUMBER;
    v_segment1                VARCHAR2(150);
	v_segment2                VARCHAR2(150);
    v_project_code            VARCHAR2(150);
    v_task                    VARCHAR2(150);
    v_ccf                     VARCHAR2(500);
    l_errbuf                  VARCHAR2(2000);
	l_retcode                 number;
    v_ATTRIBUTE5              VARCHAR2(240);
    v_attribute5_1            VARCHAR2(150);
    v_attribute5_2            VARCHAR2(150);
    v_attribute5_3            VARCHAR2(150);
    v_attribute5_4            VARCHAR2(150);
    v_flag_erreur             BOOLEAN := FALSE;
    v_flag_erreur_detail      BOOLEAN := FALSE;
    v_flag_erreur_imput       BOOLEAN := FALSE;
    v_flag_erreur_histo       BOOLEAN := FALSE;
    v_flag_warning            BOOLEAN := FALSE;
    v_agent_name              VARCHAR2(150);

    CURSOR cur_header IS
      SELECT *
      FROM DKA_SPOFUSION_SSTR_HEADERS_TMP
      WHERE DATA_TYPE = 'ACTUEL'
        AND org_abs in (
			SELECT
                 HOU.organization_id
             FROM
                 HR_ORGANIZATION_UNITS HOU,
                 DKA_STRANSCO_LINES DSTL,
                 DKA_STRANSCO_HEADERS DSTH
             WHERE
                 DSTL.SET_ID = DSTH.SET_ID
                 AND HOU.NAME = DSTL.PARAM1_VALUE
                 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                 AND DSTL.ENABLE = 'Y'
                 AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
                -- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
				              )
		AND  STATUT is null	  
    ; 

    CURSOR cur_header_histo(p_doc_num VARCHAR2, p_ORG_ABS number) IS
      SELECT *
      FROM DKA_SPOFUSION_SSTR_HEADERS_TMP
      WHERE document_num = p_doc_num
      AND DATA_TYPE = 'HISTO'
	  and ORG_ABS=p_ORG_ABS
	  
	  FOR UPDATE OF
           org_id              
          ,AGENT_ID            
          ,VENDOR_SITE_ID      
          ,VENDOR_ID           
          ,SHIP_TO_LOCATION_ID 
          ,BILL_TO_LOCATION_ID 
          ,TERM_ID             
          ,STYLE_ID            
          ,ATTRIBUTE5_TRANSCO  
          ,STATUT              
    ;

    CURSOR cur_detail (p_doc_num VARCHAR2,
					   p_org_abs number)IS
      SELECT *
      FROM DKA_SPOFUSION_SSTR_DETAIL_TMP
      WHERE document_num = p_doc_num
      AND org_abs=p_org_abs
      FOR UPDATE OF
               CADRE_PO_HEADER_ID
              ,COMMANDE_ID       
              ,PERSON_ID         
              ,STATUT   

    ;
    CURSOR cur_imput (p_doc_num VARCHAR2,p_org_abs number) IS
      SELECT *
      FROM 	DKA_SPOFUSION_SSTR_IMPUT_TMP
      WHERE document_num 	= p_doc_num
	  and 	ORG_ABS			= p_ORG_ABS
      FOR UPDATE OF
               project_id 
              ,task_id
              ,LOCATION_ID 
              ,STATUT 
              ,CCID_SEGMENT1 		  
              ,CCID_SEGMENT2 
    ;

BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_data');    
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 
                                         'Validation des données dans les tables spécifiques : ');

        -- Récuperer style
        --->>
        --->>
    BEGIN
            SELECT STYLE_ID 
			INTO v_STYLE_ID
			FROM PO_DOC_STYLE_HEADERS
			WHERE STYLE_TYPE = 'STANDARD'
			;
        EXCEPTION
        WHEN OTHERS THEN
          v_STYLE_ID := NULL;
          v_message := 'Erreur de récupération du STYLE ID';
          Add_Message('TOUT',NULL,NULL,v_message);
          p_retcode   := 2;
        RETURN;
    END;
        ---<<
        ---<<
        FOR rec_cur_header IN cur_header LOOP
            v_flag_erreur := FALSE;

         -- Récuperer l'agent
         --->>
         --->>
    BEGIN
               SELECT ppf.person_id
               INTO v_agent_id
               FROM per_people_f ppf
				,per_all_assignments_f paaf
                WHERE ppf.full_name = rec_cur_header.AGENT_NAME
				and paaf.person_id = ppf.person_id
               AND sysdate BETWEEN NVL(ppf.effective_start_date,sysdate) AND NVL(ppf.effective_end_date,sysdate)
				and sysdate BETWEEN NVL(paaf.effective_start_date,sysdate) AND NVL(paaf.effective_end_date,sysdate)
               AND CURRENT_EMPLOYEE_FLAG = 'Y';
               v_agent_name := rec_cur_header.AGENT_NAME;

              EXCEPTION
                WHEN OTHERS THEN 
                  v_agent_id := NULL;
                 v_agent_name := null;--'REPRISE, REPRISE';
                  v_message := 'Avertissement : L''employé '||rec_cur_header.AGENT_NAME||' n''existe pas';
                  Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_header.DATA_TYPE,NULL,v_message);
                  v_flag_warning := TRUE;
              END;

              BEGIN
                SELECT AGENT_ID 
                INTO v_AGENT_ID
				FROM PO_AGENTS_V
                WHERE AGENT_NAME = v_agent_name
                AND sysdate BETWEEN NVL(start_date_active,sysdate) AND NVL(end_date_active,sysdate)
                ;
              EXCEPTION
              WHEN OTHERS THEN
                v_agent_id := NULL;
                v_message :=  'L''employé '||v_agent_name||' n''est pas défini comme acheteur';
                Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_header.DATA_TYPE,NULL,v_message);
                v_flag_erreur := TRUE;
              END;
           
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'cur_header: agent'||v_agent_id); 
		
            v_org_id := get_organization_id(rec_cur_header.org_abs);

                IF v_org_id = -1 THEN
                  v_org_id := NULL;
                  v_message := 'Erreur de récuperation de ORG_ID:'||rec_cur_header.org_abs;
                  Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_header.DATA_TYPE,NULL,v_message);
                  v_flag_erreur := TRUE;
                END IF;

            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'cur_header: v_org_id'||v_org_id);
			
            -- Récupération du fournisseur et site
            --->>
            --->>
                BEGIN
					SELECT  
						pvs_abs.vendor_id, pvs_abs.vendor_site_id
						INTO V_VENDOR_ID, V_VENDOR_SITE_ID                                                                            
					FROM -- ABOSRBE
						DKA_SPOFUSION_SSTR_HEADERS_TMP heaPO,     
						ap_suppliers pv,
						ap_supplier_sites_all pvs,
						ap_supplier_sites_all pvs_abs -- ABSorbante
					WHERE pv.vendor_id = pvs.vendor_id
					AND pvs.org_id = rec_cur_header.org_abs  -- org_abs= organization id absorbee
					and heaPO.vendor_site_code=  pvs.vendor_site_code
					and heaPO.vendor_name=pv.vendor_name
					and heapo.document_num=rec_cur_header.document_num
					and heaPO.org_abs=pvs.org_id
					and pv.vendor_id = pvs_abs.vendor_id
					and pvs_abs.org_id = v_org_id
					and pvs_abs.location_id=pvs.location_id
					and pvs_abs.purchasing_site_flag = 'Y'
					and heaPO.DATA_TYPE = 'ACTUEL'
			        AND ROWNUM = 1;
				
                EXCEPTION
                WHEN OTHERS THEN
                  V_VENDOR_ID := NULL;
                  V_VENDOR_SITE_ID := NULL;
                  v_message := 'Erreur de récuperation de la commande et de organization ' ||rec_cur_header.document_num||'/'||rec_cur_header.ORG_ID||', '||SQLERRM;
                  Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_header.DATA_TYPE,NULL,v_message);
                  v_flag_erreur := TRUE;
                END;
            
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'cur_header: V_VENDOR_ID, V_VENDOR_SITE_ID'||V_VENDOR_ID ||'__'|| V_VENDOR_SITE_ID);
            -- Lieu de livraison
            --->>
            --->>
                BEGIN
                  SELECT LOCATION_ID 
                  INTO v_SHIP_TO_LOCATION_ID
                  FROM HR_LOCATIONS
                  WHERE location_code = rec_cur_header.SHIP_TO_LOCATION
                  ;
                EXCEPTION
                WHEN OTHERS THEN
                  v_SHIP_TO_LOCATION_ID := NULL;
                  v_message := 'Erreur de récuperation du lieu de livraison : '||rec_cur_header.SHIP_TO_LOCATION;
                  Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_header.DATA_TYPE,NULL,v_message);
                  v_flag_erreur := TRUE;
                END;
            
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'cur_header: v_SHIP_TO_LOCATION_ID'||v_SHIP_TO_LOCATION_ID);

            -- Lieu de facturation
            --->>
            --->>
                BEGIN
					select bill_to_location_id--, loc.location_code
					into V_bill_to_location_ID --, v_bill_to_location
					from FINANCIALS_SYSTEM_PARAMS_ALL par,
						 HR_LOCATIONS_ALL 			  loc
					where 1=1
					and par.inventory_organization_id= v_org_id
					and par.bill_to_location_id=loc.LOCATION_ID;  
					EXCEPTION
					WHEN OTHERS THEN
					v_BILL_TO_LOCATION_ID := NULL;
					v_message := 'Erreur de récuperation du lieu de facturation '||rec_cur_header.BILL_TO_LOCATION;
					Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_header.DATA_TYPE,NULL,v_message);
					v_flag_erreur := TRUE;
                END;

			 Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'cur_header: v_BILL_TO_LOCATION_ID'||v_BILL_TO_LOCATION_ID);
            -- Terms
            --->>
            --->>
            IF rec_cur_header.PAYMENT_TERMS IS NOT NULL THEN
                BEGIN
                  SELECT TERM_ID 
                  INTO v_TERM_ID
                  FROM AP_TERMS
                  WHERE NAME = rec_cur_header.PAYMENT_TERMS
                  ;
                EXCEPTION
                WHEN OTHERS THEN
                  v_TERM_ID := NULL;
                  v_message := 'Erreur de récuperation du Terms Id pour NAME = '|| rec_cur_header.PAYMENT_TERMS;
                  Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_header.DATA_TYPE,NULL,v_message);
                  v_flag_erreur := TRUE;
                END;
            ELSE
              v_TERM_ID := NULL;
            END IF;

            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'cur_header: v_TERM_ID'||v_TERM_ID);


			v_attribute5 := rec_cur_header.ATTRIBUTE5;
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'cur_header: debut update 1'|| v_org_id|| '_'||v_agent_id);

            IF not v_flag_erreur THEN
                -- Table des entetes
                UPDATE DKA_SPOFUSION_SSTR_HEADERS_TMP
                SET 
                      org_id               = v_org_id,
                      AGENT_ID             = v_agent_id
                      ,VENDOR_SITE_ID       = V_VENDOR_SITE_ID
                      ,VENDOR_ID            = V_VENDOR_ID
                      ,SHIP_TO_LOCATION_ID  = v_SHIP_TO_LOCATION_ID
                      ,BILL_TO_LOCATION_ID  = v_BILL_TO_LOCATION_ID
                      ,TERM_ID              = V_TERM_ID
                      ,STYLE_ID             = v_STYLE_ID
                      ,ATTRIBUTE5_TRANSCO   = v_attribute5
                      ,STATUT               = 'S'
					  ,last_update_date = sysdate
                      ,last_updated_by = g_user_id

                WHERE document_num = rec_cur_header.document_num
				AND   org_abs= rec_cur_header.org_abs
                AND   DATA_TYPE    = 'ACTUEL'
                ;
              ELSE
                -- Table des entetes
                UPDATE DKA_SPOFUSION_SSTR_HEADERS_TMP
                SET 
                       org_id               = v_org_id,
                      AGENT_ID             = v_agent_id
                      ,VENDOR_SITE_ID       = V_VENDOR_SITE_ID
                      ,VENDOR_ID            = V_VENDOR_ID
                      ,SHIP_TO_LOCATION_ID  = v_SHIP_TO_LOCATION_ID
                      ,BILL_TO_LOCATION_ID  = v_BILL_TO_LOCATION_ID
                      ,TERM_ID              = V_TERM_ID
                      ,STYLE_ID             = v_STYLE_ID
                      ,ATTRIBUTE5_TRANSCO   = v_attribute5
                      ,STATUT               = 'E'
					  ,last_update_date = sysdate
					  ,last_updated_by = g_user_id

                WHERE document_num = rec_cur_header.document_num
                AND   DATA_TYPE    = 'ACTUEL'
				AND   org_abs= rec_cur_header.org_abs
                ;
              END IF;

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'cur_header :fin update 1' || v_org_id|| '_'||v_agent_id);

            -----------------------
            -- Valider histo entete --
            -----------------------
            --->>
            --->>
            FOR rec_cur_header_histo IN cur_header_histo(rec_cur_header.DOCUMENT_NUM, rec_cur_header.org_abs ) LOOP
              v_flag_erreur_histo := FALSE;

              -- Récuperer l'agent
              --->>
              --->>
		    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'histo avant selection v_agent_id');   -- a supprimer

                BEGIN
                  SELECT ppf.person_id
                  INTO v_agent_id
                  FROM per_people_f ppf
				  ,per_all_assignments_f paaf
                  WHERE ppf.full_name = rec_cur_header_histo.AGENT_NAME
				  and paaf.person_id = ppf.person_id
                  AND sysdate BETWEEN NVL(ppf.effective_start_date,sysdate) AND NVL(ppf.effective_end_date,sysdate)
				  and sysdate BETWEEN NVL(paaf.effective_start_date,sysdate) AND NVL(paaf.effective_end_date,sysdate)
                  AND CURRENT_EMPLOYEE_FLAG = 'Y';

                  v_agent_name := rec_cur_header_histo.AGENT_NAME;

                EXCEPTION
                  WHEN OTHERS THEN 
                    v_agent_id := NULL;
                    v_agent_name := null;
                    v_message := 'Avertissement : L''employé '||rec_cur_header_histo.AGENT_NAME||' n''existe pas';--, remplacement par REPRISE';
                    Add_Message(rec_cur_header_histo.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                    v_flag_warning := TRUE;
                END;

			Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'rec_cur_header_histo: histo apres selection v_agent_id'||v_agent_id);   -- a supprimer
			Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'rec_cur_header_histo :histo avant selection v_AGENT_ID');   -- a supprimer

                BEGIN
                  SELECT AGENT_ID 
                  INTO v_AGENT_ID
                  FROM PO_AGENTS_V
                  WHERE AGENT_NAME = v_agent_name
                 -- AND sysdate BETWEEN NVL(start_date_active,sysdate) AND NVL(end_date_active,sysdate)
                  ;
                EXCEPTION
                WHEN OTHERS THEN
                  v_agent_id := NULL;
                  v_message :=  'L''employé '||v_agent_name||' n''est pas défini comme acheteur';
                  Add_Message(rec_cur_header_histo.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                  v_flag_erreur_histo := TRUE;
                END;
              ---<<
              ---<<

              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'histo apres selection v_AGENT_ID'||v_AGENT_ID);   -- a supprimer
              -- Récupération du fournisseur et site
              --->>
              --->>
                  BEGIN
                    SELECT ASA.VENDOR_ID
                    INTO V_VENDOR_ID
                    FROM Po_Vendors ASA
                    WHERE ASA.VENDOR_NAME  = rec_cur_header_histo.VENDOR_NAME
                    ;

                    IF V_VENDOR_ID IS NOT NULL THEN
                        BEGIN

						SELECT  
						pvs_abs.vendor_id, pvs_abs.vendor_site_id
						INTO V_VENDOR_ID, V_VENDOR_SITE_ID                                                                            
					FROM -- ABOSRBE
						ap_suppliers pv,
						ap_supplier_sites_all pvs,
						ap_supplier_sites_all pvs_abs -- ABSorbante
					WHERE pv.vendor_id = pvs.vendor_id
					AND pvs.org_id = rec_cur_header_histo.org_abs--ORG_ID--abs
					and rec_cur_header_histo.vendor_site_code=  pvs.vendor_site_code
					and rec_cur_header_histo.vendor_name=pv.vendor_name
					and rec_cur_header_histo.org_abs=pvs.org_id
					and pv.vendor_id = pvs_abs.vendor_id
					and pvs_abs.org_id = v_org_id
					and pvs_abs.location_id=pvs.location_id
					and pvs_abs.purchasing_site_flag = 'Y'
					 AND ROWNUM = 1;

                        EXCEPTION
                        WHEN OTHERS THEN
                          V_VENDOR_SITE_ID := NULL;
                          v_message := 'Avertissement : le site fournisseur ' ||SUBSTR(rec_cur_header_histo.VENDOR_SITE_CODE,5)||' n''existe pas';
                          Add_Message(rec_cur_header_histo.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                          v_flag_warning := TRUE;
                        END;
                    END IF;

                EXCEPTION
                WHEN OTHERS THEN
                    V_VENDOR_ID := NULL;
                    V_VENDOR_SITE_ID := NULL;
                    v_message := 'Avertissement : le fournisseur ' ||rec_cur_header_histo.VENDOR_NAME|| ' n''existe pas ' ;
                    Add_Message(rec_cur_header_histo.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                    v_flag_warning := TRUE;
                END;
              -- Lieu de livraison
              --->>
              --->>
                  BEGIN
                    SELECT LOCATION_ID 
                    INTO v_SHIP_TO_LOCATION_ID
                    FROM HR_LOCATIONS
                    WHERE location_code = rec_cur_header_histo.SHIP_TO_LOCATION
                    ;
                  EXCEPTION
                  WHEN OTHERS THEN
                    v_SHIP_TO_LOCATION_ID := NULL;
                    v_message := 'Erreur de récuperation du lieu de livraison : '||rec_cur_header_histo.SHIP_TO_LOCATION;
                    Add_Message(rec_cur_header_histo.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                    v_flag_erreur_histo := TRUE;
                  END;
             
              -- Lieu de facturation
              --->>
              --->>
               
			  BEGIN
			  
				select bill_to_location_id--, loc.location_code
				  into V_bill_to_location_ID --, v_bill_to_location
				  from FINANCIALS_SYSTEM_PARAMS_ALL par,
				       HR_LOCATIONS_ALL loc
				where 1=1
				   and par.inventory_organization_id= v_org_id
				   and par.bill_to_location_id=loc.LOCATION_ID;  


			  EXCEPTION
				WHEN OTHERS THEN  

				 v_message := 'Avertissement : L''identifiant du lieu de facturation de la commande ' ||rec_cur_header_histo.DOCUMENT_NUM|| ' n''existe pas ' ;
                    Add_Message(rec_cur_header_histo.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                    v_flag_warning := TRUE;

			  END;   

              -- Terms
              --->>
              --->>

              IF rec_cur_header_histo.PAYMENT_TERMS IS NOT NULL THEN
                    BEGIN
                    SELECT TERM_ID 
                    INTO v_TERM_ID
                    FROM AP_TERMS
                    WHERE NAME = rec_cur_header_histo.PAYMENT_TERMS
                    ;
                  EXCEPTION
                  WHEN OTHERS THEN
                    v_TERM_ID := NULL;
                    v_message := 'Erreur de récuperation du Terms Id pour NAME = '|| rec_cur_header_histo.PAYMENT_TERMS;
                    Add_Message(rec_cur_header_histo.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                    v_flag_erreur_histo := TRUE;
                  END;
              ELSE
                v_TERM_ID := NULL;
              END IF;

				v_attribute5 := rec_cur_header_histo.ATTRIBUTE5;
                Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'debut update rec_cur_header_histo'||v_org_id);   -- a supprimer

                IF v_flag_erreur_histo THEN

                  v_flag_erreur := TRUE;

                  -- Table des enetetes
                  UPDATE DKA_SPOFUSION_SSTR_HEADERS_TMP
                  SET 
                         org_id               = v_org_id
                        ,AGENT_ID             = v_AGENT_ID
                        ,VENDOR_SITE_ID       = V_VENDOR_SITE_ID
                        ,VENDOR_ID            = V_VENDOR_ID
                        ,SHIP_TO_LOCATION_ID  = v_SHIP_TO_LOCATION_ID
                        ,BILL_TO_LOCATION_ID  = v_BILL_TO_LOCATION_ID
                        ,TERM_ID              = V_TERM_ID
                        ,STYLE_ID             = v_STYLE_ID
                        ,ATTRIBUTE5_TRANSCO   = v_attribute5
                        ,STATUT               = 'E'
						,last_update_date = sysdate
					    ,last_updated_by = g_user_id

                  WHERE  CURRENT OF cur_header_histo
				;
                ELSE
                    -- Table des enetetes
                    UPDATE DKA_SPOFUSION_SSTR_HEADERS_TMP
                    SET 

                           org_id               = v_org_id
                          ,AGENT_ID             = v_AGENT_ID
                          ,VENDOR_SITE_ID       = V_VENDOR_SITE_ID
                          ,VENDOR_ID            = V_VENDOR_ID
                          ,SHIP_TO_LOCATION_ID  = v_SHIP_TO_LOCATION_ID
                          ,BILL_TO_LOCATION_ID  = v_BILL_TO_LOCATION_ID
                          ,TERM_ID              = V_TERM_ID
                          ,STYLE_ID             = v_STYLE_ID
                          ,ATTRIBUTE5_TRANSCO   = v_attribute5
                          ,STATUT               = 'S'
						  ,last_update_date = sysdate
					      ,last_updated_by = g_user_id


                    WHERE  CURRENT OF cur_header_histo

                    ;
                END IF;
             
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'fin update rec_cur_header_histo'||v_org_id);
            END LOOP;
            -----------------------
            -- Valider le detail --
            -----------------------
            --->>
            --->>
            FOR rec_cur_detail IN cur_detail(rec_cur_header.DOCUMENT_NUM, rec_cur_header.org_abs) LOOP

			   v_flag_erreur_detail := FALSE;
              -- Recuperer le signataire
              --->>
              --->>
            /*  IF rec_cur_detail.DOCUMENT_NUM_CADRE IS NOT NULL THEN
                  BEGIN
                    SELECT PO_HEADER_ID
                    INTO v_cadre_po_header_id
                    FROM PO_HEADERS_ALL
                    WHERE segment1= rec_cur_detail.DOCUMENT_NUM_CADRE
                    ;
                  EXCEPTION
                  WHEN OTHERS THEN
                    IF rec_cur_detail.DATA_TYPE = 'ACTUEL' THEN
                      v_cadre_po_header_id := NULL;
                      v_message := 'Erreur de récupération du contrat cadre '|| rec_cur_detail.DOCUMENT_NUM_CADRE;
                      Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_detail.data_type,NULL,v_message);
                      v_flag_erreur_detail := TRUE;
                    ELSE
                      v_cadre_po_header_id := NULL;
                      v_message := 'Avertissement : problème de récupération du contrat cadre '|| rec_cur_detail.DOCUMENT_NUM_CADRE;
                      Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_detail.data_type,NULL,v_message);
                      v_flag_warning := TRUE;
                    END IF;
                  END;
              ELSE*/
                v_cadre_po_header_id := NULL;
            --  END IF;

              -- Recuperer la commande
              --->>
              --->>
        IF rec_cur_detail.COMMANDE_NUM IS NOT NULL THEN
                  BEGIN
                    SELECT PO_HEADER_ID
                    INTO v_commande_id
                    FROM PO_HEADERS_ALL
                    WHERE segment1 = rec_cur_detail.COMMANDE_NUM
                    AND type_lookup_code = 'STANDARD' 
					and org_id = v_org_id 
                    ;
                  EXCEPTION
                  WHEN OTHERS THEN
                    IF rec_cur_detail.DATA_TYPE = 'ACTUEL' THEN
                        v_commande_id := NULL;
                        v_message := 'La commande PO ' ||rec_cur_detail.COMMANDE_NUM ||' n''existe pas dans la société absorbante';
                        Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_detail.data_type,NULL,v_message);
                        v_flag_erreur_detail := TRUE;

                    ELSE
                      v_commande_id := NULL;
                      v_message := 'Avertissement : la commande PO ' ||rec_cur_detail.COMMANDE_NUM ||' n''est pas trouvée';
                      Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_detail.data_type,NULL,v_message);
                      v_flag_warning := TRUE;
                    END IF;
                  END;
              ELSE
                v_commande_id := NULL;
              END IF;
           
              -- Recuperer le signataire
              --->>
              --->>
					  
                   BEGIN
                    SELECT ppf.PERSON_ID
                    INTO v_person_id
                    FROM PER_ALL_PEOPLE_F ppf
				        ,per_all_assignments_f paaf
                    WHERE ppf.FULL_NAME= rec_cur_detail.SIGNATAIRE_CONTRAT
                    AND sysdate BETWEEN NVL(ppf.effective_start_date,sysdate) AND NVL(ppf.effective_end_date,sysdate)
					and sysdate BETWEEN NVL(paaf.effective_start_date,sysdate) AND NVL(paaf.effective_end_date,sysdate)
					and paaf.person_id = ppf.person_id
                    AND ppf.CURRENT_EMPLOYEE_FLAG = 'Y'
					and rownum<2;
                
				   EXCEPTION
					WHEN OTHERS THEN
					v_person_id := NULL;
					v_message :=  'L''employé '||rec_cur_detail.SIGNATAIRE_CONTRAT||' n''est pas trouvé';
					Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_detail.data_type,NULL,v_message);
					v_flag_erreur := TRUE;

				  end ;

              --Mise à jour de la table detail
              --->
              --->
                  -- Si erreur
                  IF v_flag_erreur_detail THEN

                    UPDATE DKA_SPOFUSION_SSTR_DETAIL_TMP
                    SET 
                           CADRE_PO_HEADER_ID = V_CADRE_PO_HEADER_ID
                          ,COMMANDE_ID        = V_COMMANDE_ID
                          ,PERSON_ID          = V_PERSON_ID
                          ,STATUT      = 'E'
						  ,org_id               = v_org_id
						  ,last_update_date = sysdate
						  ,last_updated_by = g_user_id
                    WHERE  CURRENT OF cur_detail;

                  ELSE -- en cas d'erreur

                    UPDATE DKA_SPOFUSION_SSTR_DETAIL_TMP
                    SET 
                           CADRE_PO_HEADER_ID = V_CADRE_PO_HEADER_ID
                          ,COMMANDE_ID        = V_COMMANDE_ID
                          ,PERSON_ID          = V_PERSON_ID        
                          ,STATUT      = 'S'
						  ,org_id               = v_org_id
						  ,last_update_date = sysdate
					      ,last_updated_by = g_user_id
                    WHERE  CURRENT OF cur_detail
                    ;

                 END IF;
              ---<<
              ---<<
              -- Si erreur
                 IF v_flag_erreur_detail THEN
                v_flag_erreur := TRUE;
                END IF;
        END LOOP; --<<< Fin cur_detail

            -- Valider les imputations
            --->>
            --->>
        FOR rec_cur_imput IN cur_imput(rec_cur_header.DOCUMENT_NUM,rec_cur_header.org_abs) LOOP

--- segment1, segment2 	
				       begin 
				       select substr(name,1,3),substr(name,4,length(name))
                       into 	v_segment1, v_segment2			
				       from HR_ORGANIZATION_UNITS 
				       where organization_id = (SELECT
														HOU.ORGANIZATION_ID
													
												FROM
														HR_ORGANIZATION_UNITS HOU,
														DKA_STRANSCO_LINES DSTL,
														DKA_STRANSCO_HEADERS DSTH
												WHERE
														 DSTL.SET_ID = DSTH.SET_ID
														AND HOU.NAME = DSTL.RETURN_VALUE
														AND DSTL.param1_value=(select name from HR_ORGANIZATION_UNITS hr where hr.organization_id=rec_cur_header.org_abs )
														AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
														AND DSTL.ENABLE = 'Y'
														AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE));
					    

					   EXCEPTION
                       WHEN OTHERS THEN
                          v_segment1 := NULL;
						  v_segment2 := NULL;
                          v_message := 'Problème lors de récupération du segment1 , segment2 '||v_segment1||' _'|| v_segment2;
 Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_imput.data_type, rec_cur_imput.contrat_imputation_id,v_message);
				       end ; 	                   

                    v_flag_erreur_imput := FALSE;

						
						 dka_tools_pkg.get_code_combination_id (
                                                    pv_segment1 =>  v_segment2,
                                                    pv_segment2 =>  v_segment1,
                                                    pv_segment3 =>  rec_cur_imput.CCID_segment3,
                                                    pv_segment4 =>  rec_cur_imput.CCID_segment4,
                                                    pv_segment5 =>  rec_cur_imput.CCID_segment5, --'0',
                                                    pv_segment6 =>  rec_cur_imput.CCID_segment6, --'0',
                                                    pv_segment7 =>  rec_cur_imput.CCID_segment7,
                                                    pv_segment8 =>  rec_cur_imput.CCID_segment8, --'0',
                                                    pv_segment9 =>  rec_cur_imput.CCID_segment9, --'0',--l_flux,
                                                    pv_segment10 => rec_cur_imput.CCID_segment10, --'0',
                                                    pv_segment11 => rec_cur_imput.CCID_segment11,
                                                    pv_segment12 => rec_cur_imput.CCID_segment12,
                                                    pn_code_combination_id => l_charge_account_flex_new_id,
                                                    pv_errbuf => l_errbuf,
                                                    pn_retcode => l_retcode
													);

                        if l_retcode = 2 then
							v_code_combination_id := NULL; 
							v_message := 'probleme de recuperation de code combination '||v_code_combination_id || '- Message d''erreur : '||l_errbuf;
							Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_imput.data_type, rec_cur_imput.contrat_imputation_id,v_message);
							v_flag_erreur_imput := TRUE;
						END IF;
					---- projet -----
                          BEGIN
                          v_project_code:=substr(rec_cur_imput.PROJECT_CODE,1,10);
						  
						  SELECT project_id
                          INTO v_project_id
                          FROM PA_PROJECTS_ALL 
                          WHERE segment1 = v_project_code
						    and org_id= v_org_id
						  ;
						  
                         EXCEPTION
                         WHEN OTHERS THEN
                          v_project_id := NULL;
                          v_message := 'Problème lors de récupération du projet '||v_project_code;
                          IF rec_cur_imput.DATA_TYPE = 'HISTO' THEN
                              v_message := 'Avertissement - '||v_message;
                              v_flag_warning := TRUE;
                          ELSE
                              v_flag_erreur_imput := TRUE;
                          END IF;
                          Add_Message(rec_cur_header.DOCUMENT_NUM, rec_cur_imput.data_type,rec_cur_imput.contrat_imputation_id,v_message);

                        END;

                      ----- tache 

            BEGIN
                        /*  SELECT task_id, substr(task_number,1,LENGTH(task_number)-1)
                          INTO v_task_id, v_task
                          FROM PA_TASKS 
                          WHERE 1=1
						 -- and task_number = v_task
                          AND   project_id  = v_project_id
						AND   task_id  = rec_cur_imput.task_id
						
						
						  SELECT substr(task_number,1,LENGTH(task_number)-1)
                            INTO v_task
                            FROM PA_TASKS 
                           WHERE 1=1
						     AND project_id  = rec_cur_imput.PROJECT_CODE
						     AND task_id  = rec_cur_imput.task_id
						   ;*/
						   SELECT task_id, substr(rec_cur_imput.task_num_absorbe,1,10)
                             INTO v_task_id, v_task
                             FROM PA_TASKS 
                            WHERE 1=1
						      and task_number = substr(rec_cur_imput.task_num_absorbe,1,10)
                              AND project_id  = v_project_id
						   ;
						   
                        EXCEPTION
                        WHEN OTHERS THEN
                          v_task_id := NULL;
                          v_message := 'Problème lors de récupération de la tâche '||v_task;
                          IF rec_cur_imput.DATA_TYPE = 'HISTO' THEN
                              v_message := 'Avertissement - '||v_message;
                              v_flag_warning := TRUE;
                          ELSE
                              v_flag_erreur_imput := TRUE;
                          END IF;
                          Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_imput.data_type, rec_cur_imput.contrat_imputation_id,v_message);
            END;

			BEGIN
            /*    select loc.location_id
                into v_location_id --, v_bill_to_location
                from FINANCIALS_SYSTEM_PARAMS_ALL par,
                    HR_LOCATIONS_ALL loc
			    where 1=1
			    and par.inventory_organization_id= v_org_id
                and par.bill_to_location_id=loc.LOCATION_ID; */
				
				SELECT LOCATION_ID 
				  INTO v_location_id
				  FROM HR_LOCATIONS
				 WHERE location_code = rec_cur_imput.location_code;

            EXCEPTION
            WHEN OTHERS THEN  
                v_location_id := NULL;
                          v_message := 'Erreur de récupération location id pour LOCATION_CODE = '||rec_cur_imput.LOCATION_CODE;
                          Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_imput.data_type, rec_cur_imput.contrat_imputation_id,v_message);
                          v_flag_erreur_imput := TRUE;
                 --g_summary.rejected_headers_rows :=  g_summary.rejected_headers_rows + 1;                   
            END;   
                    -- Mise à jour de la table
                    --->
                    --->
                        -- Si erreur
                        IF v_flag_erreur_imput THEN

                          UPDATE DKA_SPOFUSION_SSTR_IMPUT_TMP
                          SET 
                                 project_id  = v_project_id
                                ,task_id     = v_task_id
                               -- ,location_id = v_location_id
                                ,code_combination_id = l_charge_account_flex_new_id
                                ,STATUT      = 'E'
								,org_id   = v_org_id
								,last_update_date = sysdate
					            ,last_updated_by = g_user_id			

                          WHERE  CURRENT OF cur_imput
                          ;
                        ELSE -- en cas d'erreur

                          UPDATE DKA_SPOFUSION_SSTR_IMPUT_TMP
                          SET 
                                 project_id  = v_project_id
                                ,task_id     = v_task_id
                                ,location_id = v_location_id
							    ,code_combination_id = l_charge_account_flex_new_id
                                ,STATUT      = 'S'
							    ,org_id=v_org_id
								,last_update_date = sysdate
							    ,last_updated_by = g_user_id
                          WHERE  CURRENT OF cur_imput
                          ;

                      END IF;
                
                    -- Si erreur
                    IF v_flag_erreur_imput THEN
                      v_flag_erreur := TRUE;
                    END IF;

        END LOOP; --<<<Fin cur_imput

            -- Mise à jour de la table
            --->
            --->
                -- Si erreur
                IF v_flag_erreur THEN

                  -- Table des entetes
                  UPDATE DKA_SPOFUSION_SSTR_HEADERS_TMP
                  SET STATUT = 'E'
				  ,last_update_date = sysdate
				  ,last_updated_by = g_user_id
                  WHERE document_num = rec_cur_header.document_num
                  ;

                  -- Table des details
                  UPDATE DKA_SPOFUSION_SSTR_DETAIL_TMP
                  SET STATUT = 'E'
				  ,last_update_date = sysdate
				  ,last_updated_by = g_user_id
                  WHERE document_num = rec_cur_header.document_num
                  ;

                  -- Table des imputations
                  UPDATE DKA_SPOFUSION_SSTR_IMPUT_TMP
                  SET STATUT = 'E'
				  ,last_update_date = sysdate
				  ,last_updated_by = g_user_id
                  WHERE document_num = rec_cur_header.document_num
                  ;
                END IF;
              ---<<
              ---<<

        END LOOP;          

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_data');    

        IF v_flag_warning AND p_retcode != 2 THEN
          p_retcode   := 1;
        END IF;

    EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'validate_data : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure validate_data : EXCEPTION OTHERS ');
		
  END validate_data;  


 /*
 *************************************************************************
 * PROCEDURE NAME : import_data
 * 
 * DESCRIPTION
 *  Procédure d'insertion dans les tables finales
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 * 
 ************************************************************************
 */
  PROCEDURE import_data(  p_Errbuf            OUT VARCHAR2,
                          p_retcode           OUT NUMBER
                          ) 
   IS
    v_contrat_imputation_id   number;
    v_po_header_id            NUMBER;
    v_AGENT              number;
    CURSOR cur_header IS
      SELECT *
      FROM DKA_SPOFUSION_SSTR_HEADERS_TMP
      WHERE DATA_TYPE = 'ACTUEL'
	  and  org_id in (
                                          SELECT
                 HOU.organization_id
             FROM
                 HR_ORGANIZATION_UNITS HOU,
                 DKA_STRANSCO_LINES DSTL,
                 DKA_STRANSCO_HEADERS DSTH
             WHERE
                 DSTL.SET_ID = DSTH.SET_ID
                 AND HOU.NAME = DSTL.return_value
                 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                 AND DSTL.ENABLE = 'Y'
                 AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
                -- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
				 )
		AND  STATUT = 'S'
	;
   
      CURSOR cur_header_histo(p_doc_num VARCHAR2) IS
      SELECT distinct *
      FROM DKA_SPOFUSION_SSTR_HEADERS_TMP
      WHERE document_num = p_doc_num
      AND DATA_TYPE = 'HISTO'
	  and  org_id in (
                                          SELECT
                 HOU.organization_id
             FROM
                 HR_ORGANIZATION_UNITS HOU,
                 DKA_STRANSCO_LINES DSTL,
                 DKA_STRANSCO_HEADERS DSTH
             WHERE
                 DSTL.SET_ID = DSTH.SET_ID
                 AND HOU.NAME = DSTL.return_value
                 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                 AND DSTL.ENABLE = 'Y'
                 AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
                                              --           AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
														 )
	  		AND  STATUT = 'S'
    ;

      CURSOR cur_detail (p_doc_num VARCHAR2)IS
      SELECT distinct *  --SHA
      FROM DKA_SPOFUSION_SSTR_DETAIL_TMP
      WHERE document_num = p_doc_num
	  and  org_id  in (
                                          SELECT
                 HOU.organization_id
             FROM
                 HR_ORGANIZATION_UNITS HOU,
                 DKA_STRANSCO_LINES DSTL,
                 DKA_STRANSCO_HEADERS DSTH
             WHERE
                 DSTL.SET_ID = DSTH.SET_ID
                 AND HOU.NAME = DSTL.return_value
                 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                 AND DSTL.ENABLE = 'Y'
                 AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
                                                --         AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
														 )
		AND  STATUT = 'S'
	--  and rownum<2 -- SHA
      ORDER BY DATA_TYPE
    ;
      CURSOR cur_imput (p_doc_num VARCHAR2) IS
      SELECT *
      FROM DKA_SPOFUSION_SSTR_IMPUT_TMP
      WHERE document_num = p_doc_num
	  and  org_id in (
                                          SELECT
                 HOU.organization_id
             FROM
                 HR_ORGANIZATION_UNITS HOU,
                 DKA_STRANSCO_LINES DSTL,
                 DKA_STRANSCO_HEADERS DSTH
             WHERE
                 DSTL.SET_ID = DSTH.SET_ID
                 AND HOU.NAME = DSTL.return_value
                 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                 AND DSTL.ENABLE = 'Y'
                 AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
                  --                                       AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
														 )
       AND  STATUT = 'S'														 
	--  and rownum<2 -- SHA
      ORDER BY DATA_TYPE
    ;

        BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début import_data');    
        FOR rec_cur_header IN cur_header LOOP  
              -- Generer po_header_id
              SELECT po_headers_s.nextval
              INTO v_po_header_id
              FROM DUAL;
		Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'valeur du compteur po_header_id'||v_po_header_id);  

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'avant insetion po_header_all l''agent_id = '||rec_cur_header.AGENT_ID);  
            -- PO_HEADERS_ALL
            INSERT INTO  PO_HEADERS_ALL 
                                (  PO_HEADER_ID
                                  ,AGENT_ID
                                  ,TYPE_LOOKUP_CODE
                                  ,LAST_UPDATE_DATE
                                  ,LAST_UPDATED_BY
                                  ,SEGMENT1
                                  ,SUMMARY_FLAG
                                  ,ENABLED_FLAG
                                  ,CREATION_DATE
                                  ,CREATED_BY
                                  ,VENDOR_ID
                                  ,VENDOR_SITE_ID
                                  ,SHIP_TO_LOCATION_ID
                                  ,BILL_TO_LOCATION_ID
                                  ,TERMS_ID
                                  ,CURRENCY_CODE
                                  ,RATE_DATE
                                  ,START_DATE
                                  ,END_DATE
                                  ,BLANKET_TOTAL_AMOUNT
                                  ,AUTHORIZATION_STATUS
                                  ,REVISION_NUM
                                  ,REVISED_DATE
                                  ,APPROVED_FLAG
                                  ,APPROVED_DATE
                                  ,COMMENTS
                                  ,ATTRIBUTE4
                                  ,ATTRIBUTE5
                                  ,ATTRIBUTE13
                                  ,ATTRIBUTE14
                                  ,ATTRIBUTE15
                                  ,ORG_ID 
                                  ,STYLE_ID
                                  )
            VALUES
                                  (
                                   v_po_header_id                      --PO_HEADER_ID
                                  ,rec_cur_header.AGENT_ID                --AGENT_ID
                                  ,rec_cur_header.TYPE_LOOKUP_CODE        --TYPE_LOOKUP_CODE
                                  ,SYSDATE                                --LAST_UPDATE_DATE
                                  ,g_user_id                              --LAST_UPDATED_BY
                                  ,rec_cur_header.DOCUMENT_NUM            --SEGMENT1
                                  ,'N'                                    --SUMMARY_FLAG
                                  ,'Y'                                    --ENABLED_FLAG
                                  ,SYSDATE                                --CREATION_DATE
                                  ,g_user_id                              --CREATED_BY
                                  ,rec_cur_header.VENDOR_ID               --VENDOR_ID
                                  ,rec_cur_header.VENDOR_SITE_ID          --VENDOR_SITE_ID
                                  ,rec_cur_header.SHIP_TO_LOCATION_ID     --SHIP_TO_LOCATION_ID 
                                  ,rec_cur_header.BILL_TO_LOCATION_ID     --BILL_TO_LOCATION_ID 
                                  ,rec_cur_header.TERM_ID                 --TERMS_ID  
                                  ,rec_cur_header.CURRENCY_CODE           --CURRENCY_CODE
                                  ,rec_cur_header.RATE_DATE               --RATE_DATE
                                  ,rec_cur_header.START_DATE              --START_DATE           
                                  ,rec_cur_header.END_DATE                --END_DATE             
                                  ,rec_cur_header.BLANKET_TOTAL_AMOUNT    --BLANKET_TOTAL_AMOUNT 
                                  ,rec_cur_header.APPROVAL_STATUS         --AUTHORIZATION_STATUS 
                                  ,rec_cur_header.REVISION_NUM            --REVISION_NUM         
                                  ,rec_cur_header.REVISION_DATE           --REVISED_DATE         
                                  ,rec_cur_header.APPROVED_FLAG           --APPROVED_FLAG        
                                  ,rec_cur_header.APPROVED_DATE           --APPROVED_DATE   
                                  ,rec_cur_header.COMMENTS                --COMMENTS
                                  ,rec_cur_header.ATTRIBUTE4              --ATTRIBUTE4 
                                  ,rec_cur_header.ATTRIBUTE5_transco      --ATTRIBUTE5 
                                  ,rec_cur_header.ATTRIBUTE13             --ATTRIBUTE13
                                  ,rec_cur_header.ATTRIBUTE14             --ATTRIBUTE14
                                  ,rec_cur_header.ATTRIBUTE15             --ATTRIBUTE15
                                  ,rec_cur_header.ORG_ID                  --ORG_ID     
                                  ,rec_cur_header.STYLE_ID                --STYLE_ID
                                  );

            g_summary.inserted_header_rows := g_summary.inserted_header_rows + 1;
		FOR rec_cur_header_histo IN cur_header_histo(rec_cur_header.DOCUMENT_NUM) LOOP
                SELECT AGENT_ID 
                INTO v_AGENT
                FROM PO_AGENTS_V
                WHERE AGENT_NAME = rec_cur_header_histo.AGENT_NAME
				AND sysdate BETWEEN NVL(start_date_active,sysdate) AND NVL(end_date_active,sysdate);
            -- PO_HEADERS_ARCHIVE_U1
			Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'avant insetion PO_HEADERS_ARCHIVE_all l''agent_id = '||rec_cur_header.AGENT_ID);  

			if rec_cur_header_histo.AGENT_ID  is null then
			  Fnd_File.put_line (Fnd_File.LOG, ' TEST - AGEN ID NULL : ' || rec_cur_header_histo.DOCUMENT_NUM );  
			end if;


            INSERT INTO PO_HEADERS_ARCHIVE_ALL 
                                (  PO_HEADER_ID
                                  ,AGENT_ID
                                  ,TYPE_LOOKUP_CODE
                                  ,LAST_UPDATE_DATE
                                  ,LAST_UPDATED_BY
                                  ,SEGMENT1
                                  ,SUMMARY_FLAG
                                  ,ENABLED_FLAG
                                  ,CREATION_DATE
                                  ,CREATED_BY
                                  ,VENDOR_ID
                                  ,VENDOR_SITE_ID
                                  ,SHIP_TO_LOCATION_ID
                                  ,BILL_TO_LOCATION_ID
                                  ,TERMS_ID
                                  ,CURRENCY_CODE
                                  ,RATE_DATE
                                  ,START_DATE
                                  ,END_DATE
                                  ,BLANKET_TOTAL_AMOUNT
                                  ,AUTHORIZATION_STATUS
                                  ,REVISION_NUM
                                  ,REVISED_DATE
                                  ,APPROVED_FLAG
                                  ,APPROVED_DATE
                                  ,COMMENTS
                                  ,ATTRIBUTE4
                                  ,ATTRIBUTE5
                                  ,ATTRIBUTE13
                                  ,ATTRIBUTE14
                                  ,ATTRIBUTE15
                                  ,ORG_ID
                                  ,STYLE_ID
                                  ,LATEST_EXTERNAL_FLAG --RBE artf2212570
                                  )
            VALUES
                                  (
                                   v_po_header_id                               --PO_HEADER_ID
                                  ,rec_cur_header_histo.AGENT_ID                --AGENT_ID
                                  ,rec_cur_header_histo.TYPE_LOOKUP_CODE        --TYPE_LOOKUP_CODE
                                  ,SYSDATE                                      --LAST_UPDATE_DATE
                                  ,g_user_id                                    --LAST_UPDATED_BY
                                  ,rec_cur_header_histo.DOCUMENT_NUM            --SEGMENT1
                                  ,'N'                                          --SUMMARY_FLAG
                                  ,'Y'                                          --ENABLED_FLAG
                                  ,SYSDATE                                      --CREATION_DATE
                                  ,g_user_id                                    --CREATED_BY
                                  ,rec_cur_header_histo.VENDOR_ID               --VENDOR_ID
                                  ,rec_cur_header_histo.VENDOR_SITE_ID          --VENDOR_SITE_ID
                                  ,rec_cur_header_histo.SHIP_TO_LOCATION_ID     --SHIP_TO_LOCATION_ID 
                                  ,rec_cur_header_histo.BILL_TO_LOCATION_ID     --BILL_TO_LOCATION_ID 
                                  ,rec_cur_header_histo.TERM_ID                 --TERMS_ID  
                                  ,rec_cur_header_histo.CURRENCY_CODE           --CURRENCY_CODE
                                  ,rec_cur_header_histo.RATE_DATE               --RATE_DATE
                                  ,rec_cur_header_histo.START_DATE              --START_DATE           
                                  ,rec_cur_header_histo.END_DATE                --END_DATE             
                                  ,rec_cur_header_histo.BLANKET_TOTAL_AMOUNT    --BLANKET_TOTAL_AMOUNT 
                                  ,rec_cur_header_histo.APPROVAL_STATUS         --AUTHORIZATION_STATUS 
                                  ,rec_cur_header_histo.REVISION_NUM            --REVISION_NUM         
                                  ,rec_cur_header_histo.REVISION_DATE           --REVISED_DATE         
                                  ,rec_cur_header_histo.APPROVED_FLAG           --APPROVED_FLAG        
                                  ,rec_cur_header_histo.APPROVED_DATE           --APPROVED_DATE   
                                  ,rec_cur_header_histo.COMMENTS                --COMMENTS
                                  ,rec_cur_header_histo.ATTRIBUTE4              --ATTRIBUTE4 
                                  ,rec_cur_header_histo.ATTRIBUTE5_TRANSCO      --ATTRIBUTE5 
                                  ,rec_cur_header_histo.ATTRIBUTE13             --ATTRIBUTE13
                                  ,rec_cur_header_histo.ATTRIBUTE14             --ATTRIBUTE14
                                  ,rec_cur_header_histo.ATTRIBUTE15             --ATTRIBUTE15
                                  ,rec_cur_header_histo.org_id                  --ORG_ID    
                                  ,rec_cur_header.STYLE_ID                      --STYLE_ID
                                  ,rec_cur_header_histo.LATEST_EXTERNAL_FLAG    --LATEST_EXTERNAL_FLAG --RBE artf2212570
                                  );
                g_summary.inserted_header_hist_rows := g_summary.inserted_header_hist_rows + 1;
---------------------------------------------------- RG-IMP02 numéros contrats ------------------------------------------------------------------------------
                          UPDATE PO_HEADERS_ARCHIVE_ALL
                           SET segment1 = rec_cur_header_histo.DOCUMENT_NUM||'_OLD'
						      ,last_update_date = sysdate
					          ,last_updated_by = g_user_id
                           WHERE segment1 = rec_cur_header_histo.DOCUMENT_NUM
						    and org_id=rec_cur_header_histo.org_abs;
--------------------------------------------------------------------------------------------------------------------------------------------------------------			
	END LOOP;

            -- Inserer le detail
        FOR rec_cur_detail IN cur_detail(rec_cur_header.DOCUMENT_NUM) LOOP

        IF rec_cur_detail.DATA_TYPE = 'ACTUEL' THEN

                -- DKA_CONTRAT_SSTR
            INSERT INTO DKA_CONTRAT_SSTR
                (
                   PO_HEADER_ID                  
                  ,CADRE_PO_HEADER_ID               
                  ,FLAG_TACITE_RECONDUCTION         
                  ,NB_RECONDUCTION                 
                  ,PREAVIS_RESILIATION             
                  ,FLAG_REVISION                   
                  ,DATE_REVISION                   
                  ,NB_INTERVENTION                 
                  ,PERIODICITE_INTERVENTION         
                  ,NB_INTERVENTION_REALISE         
                  ,FLAG_FACTURATION                 
                  ,COMMENTAIRE_FACTURATION         
                  ,PERIODICITE_FACTURATION         
                  ,SIGNATAIRE_CONTRAT               
                  ,CREATED_BY                       
                  ,CREATION_DATE                   
                  ,LAST_UPDATED_BY                 
                  ,LAST_UPDATE_DATE                 
                  ,ORG_ID                           
                  ,REF_CONTRAT_FOURNISSEUR         
                  ,DESCRIPTION_SPECIFIQUE_CONTRAT
                  ,FLAG_MAIL_AVERTISSEMENT         
                  ,DATE_EFFET                    
                  ,RECONDUCTION_NUM                 
                  ,REVISION_NUM                  
                  ,COMMANDE_ID                     
                  ,COMMANDE_VERSION                 
                  ,DATE_RESILIATION                 
                  ,ANNULATION
                  )
                VALUES
                  (
                   v_po_header_id                                                         --PO_HEADER_ID                  
                  ,rec_cur_detail.CADRE_PO_HEADER_ID                                      --CADRE_PO_HEADER_ID               
                  ,rec_cur_detail.FLAG_TACITE_RECONDUCTION                                --FLAG_TACITE_RECONDUCTION         
                  ,rec_cur_detail.NB_RECONDUCTION                                         --NB_RECONDUCTION                  
                  ,rec_cur_detail.PREAVIS_RESILIATION                                     --PREAVIS_RESILIATION              
                  ,rec_cur_detail.FLAG_REVISION                                           --FLAG_REVISION                    
                  ,rec_cur_detail.DATE_REVISION                                              --DATE_REVISION                    
                  ,rec_cur_detail.NB_INTERVENTION                                         --NB_INTERVENTION                  
                  ,rec_cur_detail.PERIODICITE_INTERVENTION                                --PERIODICITE_INTERVENTION         
                  ,rec_cur_detail.NB_INTERVENTION_REALISE                                 --NB_INTERVENTION_REALISE          
                  ,rec_cur_detail.FLAG_FACTURATION                                        --FLAG_FACTURATION                 
                  ,rec_cur_detail.COMMENTAIRE_FACTURATION                                 --COMMENTAIRE_FACTURATION          
                  ,rec_cur_detail.PERIODICITE_FACTURATION                                 --PERIODICITE_FACTURATION          
                  ,rec_cur_detail.PERSON_ID                                               --SIGNATAIRE_CONTRAT               
                  ,g_user_id                                                              --CREATED_BY                       
                  ,SYSDATE                                                                --CREATION_DATE                    
                  ,g_user_id                                                              --LAST_UPDATED_BY                  
                  ,SYSDATE                                                                --LAST_UPDATE_DATE                 
                  ,rec_cur_header.org_id                                                               --ORG_ID                           
                  ,rec_cur_detail.REF_CONTRAT_FOURNISSEUR                                 --REF_CONTRAT_FOURNISSEUR          
                  ,rec_cur_detail.DESCRIPTION_SPECIFIQUE_CONTRAT                          --DESCRIPTION_SPECIFIQUE_CONTRAT
                  ,rec_cur_detail.FLAG_MAIL_AVERTISSEMENT                                 --FLAG_MAIL_AVERTISSEMENT          
                  ,rec_cur_detail.DATE_EFFET                                              --DATE_EFFET                    
                  ,rec_cur_detail.RECONDUCTION_NUM                                        --RECONDUCTION_NUM                 
                  ,rec_cur_detail.REVISION_NUM                                            --REVISION_NUM                  
                  ,rec_cur_detail.commande_id                                             --COMMANDE_ID
                  ,rec_cur_detail.COMMANDE_VERSION                                        --COMMANDE_VERSION                 
                  ,rec_cur_detail.DATE_RESILIATION                                        --DATE_RESILIATION                 
                  ,rec_cur_detail.ANNULATION                                              --ANNULATION                    
                  );

               g_summary.inserted_detail_rows := g_summary.inserted_detail_rows + 1;

              ELSIF(rec_cur_detail.DATA_TYPE = 'HISTO') THEN
			  Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'rec_cur_detail: REVISION_NUM '||rec_cur_detail.REVISION_NUM ||',HEADER_ID : PO_HEADER_ID'||v_po_header_id  );  

                -- DKA_CONTRAT_SSTR_ARCHI
                INSERT INTO DKA_CONTRAT_SSTR_ARCHI
                (
                   PO_HEADER_ID                  
                  ,CADRE_PO_HEADER_ID               
                  ,FLAG_TACITE_RECONDUCTION         
                  ,NB_RECONDUCTION                 
                  ,PREAVIS_RESILIATION             
                  ,FLAG_REVISION                   
                  ,DATE_REVISION                   
                  ,NB_INTERVENTION                 
                  ,PERIODICITE_INTERVENTION         
                  ,NB_INTERVENTION_REALISE         
                  ,FLAG_FACTURATION                 
                  ,COMMENTAIRE_FACTURATION         
                  ,PERIODICITE_FACTURATION         
                  ,SIGNATAIRE_CONTRAT               
                  ,CREATED_BY                       
                  ,CREATION_DATE                   
                  ,LAST_UPDATED_BY                 
                  ,LAST_UPDATE_DATE                 
                  ,ORG_ID                           
                  ,REF_CONTRAT_FOURNISSEUR         
                  ,DESCRIPTION_SPECIFIQUE_CONTRAT
                  ,FLAG_MAIL_AVERTISSEMENT         
                  ,DATE_EFFET                    
                  ,RECONDUCTION_NUM                 
                  ,REVISION_NUM                  
                  ,COMMANDE_ID                     
                  ,COMMANDE_VERSION                 
                  ,DATE_RESILIATION                 
                  ,ANNULATION                    
                  )
                VALUES
                  (
                   v_po_header_id                                                         --PO_HEADER_ID                  
                  ,rec_cur_detail.CADRE_PO_HEADER_ID                                      --CADRE_PO_HEADER_ID               
                  ,rec_cur_detail.FLAG_TACITE_RECONDUCTION                                --FLAG_TACITE_RECONDUCTION         
                  ,rec_cur_detail.NB_RECONDUCTION                                         --NB_RECONDUCTION                  
                  ,rec_cur_detail.PREAVIS_RESILIATION                                     --PREAVIS_RESILIATION              
                  ,rec_cur_detail.FLAG_REVISION                                           --FLAG_REVISION                    
                  ,rec_cur_detail.DATE_REVISION                                              --DATE_REVISION                    
                  ,rec_cur_detail.NB_INTERVENTION                                         --NB_INTERVENTION                  
                  ,rec_cur_detail.PERIODICITE_INTERVENTION                                --PERIODICITE_INTERVENTION         
                  ,rec_cur_detail.NB_INTERVENTION_REALISE                                 --NB_INTERVENTION_REALISE          
                  ,rec_cur_detail.FLAG_FACTURATION                                        --FLAG_FACTURATION                 
                  ,rec_cur_detail.COMMENTAIRE_FACTURATION                                 --COMMENTAIRE_FACTURATION          
                  ,rec_cur_detail.PERIODICITE_FACTURATION                                 --PERIODICITE_FACTURATION          
                  ,rec_cur_detail.PERSON_ID                                                            --SIGNATAIRE_CONTRAT               
                  ,g_user_id                                                              --CREATED_BY                       
                  ,SYSDATE                                                                --CREATION_DATE                    
                  ,g_user_id                                                              --LAST_UPDATED_BY                  
                  ,SYSDATE                                                                --LAST_UPDATE_DATE                 
                  ,rec_cur_header.org_id                                                  --ORG_ID                           
                  ,rec_cur_detail.REF_CONTRAT_FOURNISSEUR                                 --REF_CONTRAT_FOURNISSEUR          
                  ,rec_cur_detail.DESCRIPTION_SPECIFIQUE_CONTRAT                          --DESCRIPTION_SPECIFIQUE_CONTRAT
                  ,rec_cur_detail.FLAG_MAIL_AVERTISSEMENT                                 --FLAG_MAIL_AVERTISSEMENT          
                  ,rec_cur_detail.DATE_EFFET                                              --DATE_EFFET                    
                  ,rec_cur_detail.RECONDUCTION_NUM                                        --RECONDUCTION_NUM                 
                  ,rec_cur_detail.REVISION_NUM                                            --REVISION_NUM                  
                  ,rec_cur_detail.commande_id                                                          --COMMANDE_ID
                  ,rec_cur_detail.COMMANDE_VERSION                                        --COMMANDE_VERSION                 
                  ,rec_cur_detail.DATE_RESILIATION                                        --DATE_RESILIATION                 
                  ,rec_cur_detail.ANNULATION                                              --ANNULATION   
                  );

                 g_summary.inserted_detail_hist_rows := g_summary.inserted_detail_hist_rows + 1;
              END IF;        

        END LOOP; -- Fin cur_detail

            -- Inserer les imputations

		FOR rec_cur_imput IN cur_imput(rec_cur_header.DOCUMENT_NUM) LOOP


              IF rec_cur_imput.DATA_TYPE = 'ACTUEL' THEN

	    SELECT max(contrat_imputation_id)
		     INTO  v_contrat_imputation_id
		 FROM	DKA_CONTRAT_SSTR_IMPUTATION;

	    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'cur_imput : 1 v_contrat_imputation_id '||v_contrat_imputation_id  );  
        v_contrat_imputation_id:= v_contrat_imputation_id +1 ;
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'cur_imput : 2 v_contrat_imputation_id '||v_contrat_imputation_id  );  
         -- DKA_CONTRAT_SSTR_IMPUTATION

		    INSERT INTO DKA_CONTRAT_SSTR_IMPUTATION
                (
                   CONTRAT_IMPUTATION_ID
                  ,PO_HEADER_ID
                  ,PROJECT_ID
                  ,TASK_ID
                  ,UNITE_OEUVRE
                  ,CREATED_BY
                  ,CREATION_DATE
                  ,LAST_UPDATED_BY
                  ,LAST_UPDATE_DATE
                  ,ORG_ID
                  ,LOCATION_ID
                  ,REVISION_NUM
                  ,EXPENDITURE_TYPE
                  ,CODE_COMBINATION_ID                 
                  )
            VALUES
                  (
                    v_contrat_imputation_id --rec_cur_imput.contrat_imputation_id         --CONTRAT_IMPUTATION_ID   
                   ,v_po_header_id                              --PO_HEADER_ID            
                   ,rec_cur_imput.project_id                    --PROJECT_ID 
                   ,rec_cur_imput.task_id                       --TASK_ID             
                   ,rec_cur_imput.UNITE_OEUVRE                  --UNITE_OEUVRE            
                   ,g_user_id                                   --CREATED_BY              
                   ,SYSDATE                                     --CREATION_DATE           
                   ,g_user_id                                   --LAST_UPDATED_BY         
                   ,SYSDATE                                     --LAST_UPDATE_DATE        
                   ,rec_cur_header.org_id                       --ORG_ID                  
                   ,rec_cur_imput.location_id                   --LOCATION_ID             
                   ,rec_cur_imput.REVISION_NUM                  --REVISION_NUM            
                   ,rec_cur_imput.EXPENDITURE_TYPE              --EXPENDITURE_TYPE        
                   ,rec_cur_imput.CODE_COMBINATION_ID           --CODE_COMBINATION_ID                  
                  );



                 g_summary.inserted_imput_rows := g_summary.inserted_imput_rows + 1;

            ELSIF (rec_cur_imput.DATA_TYPE = 'HISTO') THEN


	Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'cur_imput : 1 v_contrat_imputation_id '||v_contrat_imputation_id  );  
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'cur_imput : 2 v_contrat_imputation_id '||v_contrat_imputation_id  );  

                -- DKA_CONTAT_SSTR_IMPUT_ARCHI
                INSERT INTO DKA_CONTRAT_SSTR_IMPUT_ARCHI
                (
                   CONTRAT_IMPUTATION_ID
                  ,PO_HEADER_ID
                  ,PROJECT_ID
                  ,TASK_ID
                  ,UNITE_OEUVRE
                  ,CREATED_BY
                  ,CREATION_DATE
                  ,LAST_UPDATED_BY
                  ,LAST_UPDATE_DATE
                  ,ORG_ID
                  ,LOCATION_ID
                  ,REVISION_NUM
                  ,EXPENDITURE_TYPE
                  ,CODE_COMBINATION_ID
                  )
                VALUES
                  (
                    v_contrat_imputation_id--rec_cur_imput.contrat_imputation_id        --CONTRAT_IMPUTATION_ID    
                   ,v_po_header_id                              --PO_HEADER_ID            
                   ,rec_cur_imput.project_id                    --PROJECT_ID  
                   ,rec_cur_imput.task_id                       --TASK_ID            
                   ,rec_cur_imput.UNITE_OEUVRE                  --UNITE_OEUVRE            
                   ,g_user_id                                   --CREATED_BY              
                   ,SYSDATE                                     --CREATION_DATE           
                   ,g_user_id                                   --LAST_UPDATED_BY         
                   ,SYSDATE                                     --LAST_UPDATE_DATE        
                   ,rec_cur_header.org_id                       --ORG_ID                  
                   ,rec_cur_imput.location_id                   --LOCATION_ID             
                   ,rec_cur_imput.REVISION_NUM                  --REVISION_NUM            
                   ,rec_cur_imput.EXPENDITURE_TYPE              --EXPENDITURE_TYPE        
                   ,rec_cur_imput.CODE_COMBINATION_ID           --CODE_COMBINATION_ID  
                  );
                 g_summary.inserted_imput_hist_rows := g_summary.inserted_imput_hist_rows + 1;
              END IF;    

            -- RG 7

            UPDATE PO_DISTRIBUTIONS_ALL pda
      SET pda.attribute3 = v_contrat_imputation_id
         ,pda.last_update_date = sysdate
         ,pda.last_updated_by = g_user_id
      WHERE EXISTS (SELECT 1
                    FROM DKA_CONTRAT_SSTR_IMPUTATION dcsi,
                         dka_contrat_sstr dcs, 
                         po_headers_all po1
                    WHERE dcsi.project_id   = pda.project_id
                    AND dcsi.task_id   = pda.task_id
                    AND dcsi.po_header_id=v_po_header_id
                    AND dcsi.expenditure_type   = pda.expenditure_type
                    AND po1.po_header_id= dcsi.po_header_id
                    AND dcs.po_header_id = dcsi.po_header_id
                    AND pda.org_id=dcsi.org_id
                    AND po1.type_lookup_code        = 'CONTRACT'
                    AND dcs.commande_id = pda.po_header_id
                   )
      AND pda.org_id IN  (
            SELECT
                 HOU.organization_id
            FROM
                 HR_ORGANIZATION_UNITS HOU,
                 DKA_STRANSCO_LINES DSTL,
                 DKA_STRANSCO_HEADERS DSTH
            WHERE
                 DSTL.SET_ID = DSTH.SET_ID
                 AND HOU.NAME = DSTL.return_value
                 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                 AND DSTL.ENABLE = 'Y'
                 AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
                 -- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
                             );      




            END LOOP; --Fin cur_imput

            UPDATE DKA_SPOFUSION_SSTR_HEADERS_TMP
            SET  STATUT               = 'T'
			,last_update_date = sysdate
			,last_updated_by = g_user_id
            WHERE document_num = rec_cur_header.document_num
            ;

            UPDATE DKA_SPOFUSION_SSTR_DETAIL_TMP
            SET  STATUT               = 'T'
			,last_update_date = sysdate
			,last_updated_by = g_user_id
            WHERE document_num = rec_cur_header.document_num
            ;

            UPDATE DKA_SPOFUSION_SSTR_IMPUT_TMP
            SET  STATUT               = 'T'
			,last_update_date = sysdate
			,last_updated_by = g_user_id
            WHERE document_num = rec_cur_header.document_num
            ;
                    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'avant update po_headers_all');    

---------------------------------------------------- RG-IMP02 numéros contrats ------------------------------------------------------------------------------
                          UPDATE PO_HEADERS_ALL
                           SET segment1 = rec_cur_header.DOCUMENT_NUM||'_OLD'
						      ,last_update_date = sysdate
					          ,last_updated_by = g_user_id
                           WHERE segment1 = rec_cur_header.DOCUMENT_NUM
						     and org_id=rec_cur_header.org_abs;
--------------------------------------------------------------------------------------------------------------------------------------------------------------			
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'apres update po_headers_all');    



	END LOOP;          

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin import_data');    

  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'import_data : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure import_data : EXCEPTION OTHERS ');
  END import_data;  

 /*
 *************************************************************************
 * PROCEDURE NAME : Bilan
 * 
 * DESCRIPTION
 *  Procédure de génération du bilan du traitement d'interface
 *
 * PARAMETERS
 * ==========
 * NAME                 DESCRIPTION
.* -------------------- ---------------------------------------------------
 * p_errbuf            Retour de message éventuel
 * p_retcode           Statut du traitement en sortie
 ************************************************************************
 */
	PROCEDURE Report_Bilan(	p_Errbuf            OUT VARCHAR2,
							p_retcode           OUT NUMBER
                         ) 
	IS

BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Report_Bilan');

        --------------------    
        -- Initialisation --
        --------------------          

        p_Errbuf  := NULL;
        p_retcode := 0;


        SELECT count(1)
        INTO g_summary.rejected_header_rows
        FROM DKA_SPOFUSION_SSTR_HEADERS_TMP
        WHERE statut = 'E' 
        AND DATA_TYPE = 'ACTUEL' 
        ;

        SELECT count(1)
        INTO g_summary.rejected_detail_rows
        FROM DKA_SPOFUSION_SSTR_DETAIL_TMP 
        WHERE statut = 'E' 
        AND DATA_TYPE = 'ACTUEL' 
        ;

        SELECT count(1)
        INTO g_summary.rejected_imput_rows
        FROM DKA_SPOFUSION_SSTR_IMPUT_TMP 
        WHERE statut = 'E' 
        AND DATA_TYPE = 'ACTUEL' 
        ;

        SELECT count(1)
        INTO g_summary.rejected_header_hist_rows
        FROM DKA_SPOFUSION_SSTR_HEADERS_TMP
        WHERE statut = 'E' 
        AND DATA_TYPE = 'HISTO' 
        ;

        SELECT count(1)
        INTO g_summary.rejected_detail_hist_rows
        FROM DKA_SPOFUSION_SSTR_DETAIL_TMP 
        WHERE statut = 'E' 
        AND DATA_TYPE = 'HISTO' 
        ;

        SELECT count(1)
        INTO g_summary.rejected_imput_hist_rows
        FROM DKA_SPOFUSION_SSTR_IMPUT_TMP 
        WHERE statut = 'E' 
        AND DATA_TYPE = 'HISTO' 
        ;
	

        fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT,'BILAN :');
        fnd_file.put_line(fnd_file.OUTPUT,'-------');

        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des en-têtes à traiter  dans la table spécifique                      : ' ||TO_CHAR(g_summary.loaded_header_rows+g_summary.loaded_header_hist_rows)||' (Actuel : '||TO_CHAR(g_summary.loaded_header_rows)||', Historique : '||TO_CHAR(g_summary.loaded_header_hist_rows)||')');
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des détails à traiter  dans la table spécifique                       : ' ||TO_CHAR(g_summary.loaded_detail_rows+g_summary.loaded_detail_hist_rows)||' (Actuel : '||TO_CHAR(g_summary.loaded_detail_rows)||', Historique : '||TO_CHAR(g_summary.loaded_detail_hist_rows)||')'); 
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des imputations à traiter  dans la table spécifique                   : ' || TO_CHAR(g_summary.loaded_imput_rows+g_summary.loaded_imput_hist_rows)||' (Actuel : '||TO_CHAR(g_summary.loaded_imput_rows)||', Historique : '||TO_CHAR(g_summary.loaded_imput_hist_rows)||')'||CHR(10));
																											                 
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des en-têtes en rejet dans la table spécifique                         : ' || TO_CHAR(g_summary.rejected_header_rows+g_summary.rejected_header_hist_rows)||' (Actuel : '||TO_CHAR(g_summary.rejected_header_rows)||', Historique : '||TO_CHAR(g_summary.rejected_header_hist_rows)||')');
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des détails en rejet  dans la table spécifique                         : ' || TO_CHAR(g_summary.rejected_detail_rows+g_summary.rejected_detail_hist_rows)||' (Actuel : '||TO_CHAR(g_summary.rejected_detail_rows)||', Historique : '||TO_CHAR(g_summary.rejected_detail_hist_rows)||')');
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des imputations en rejet dans la table spécifique                      : ' || TO_CHAR(g_summary.rejected_imput_rows+g_summary.rejected_imput_hist_rows)||' (Actuel : '||TO_CHAR(g_summary.rejected_imput_rows)||', Historique : '||TO_CHAR(g_summary.rejected_imput_hist_rows)||')'||CHR(10));

        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table PO_HEADERS_ALL                : ' || TO_CHAR(g_summary.inserted_header_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table PO_HEADERS_ARCHIVE_ALL        : ' || TO_CHAR(g_summary.inserted_header_hist_rows)); 
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table DKA_CONTRAT_SSTR              : ' || TO_CHAR(g_summary.inserted_detail_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table DKA_CONTRAT_SSTR_ARCHI        : ' || TO_CHAR(g_summary.inserted_detail_hist_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table DKA_CONTRAT_SSTR_IMPUTATION   : ' || TO_CHAR(g_summary.inserted_imput_rows)); 
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table DKA_CONTRAT_SSTR_IMPUT_ARCHI  : ' || TO_CHAR(g_summary.inserted_imput_hist_rows)||CHR(10));

        fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Report_Bilan');  


    EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'REPORT_BILAN : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
    END Report_Bilan; 
 /**************************************************************************
 * PROCEDURE NAME : set_recovery_mode
 *
 * DESCRIPTION
 *  Procédure d'initialisation du mode reprise (Pas de fichier en entrée)
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
 * -----------------  ------------------------------------------------------
 *
 *************************************************************************/
 PROCEDURE set_recovery_mode( p_Errbuf            OUT VARCHAR2,
                              p_retcode           OUT NUMBER
                              ) 
  IS

  BEGIN

     --RESET g_loader_request_id
     g_loader_request_id := -1;

    UPDATE DKA_SPOFUSION_SSTR_HEADERS_TMP
    SET  STATUT               = NULL
        ,AGENT_ID             = NULL
        ,ORG_ID               = NULL
        ,VENDOR_ID            = NULL
        ,VENDOR_SITE_ID       = NULL
        ,SHIP_TO_LOCATION_ID  = NULL
        ,BILL_TO_LOCATION_ID  = NULL
        ,TERM_ID              = NULL
        ,STYLE_ID             = NULL
        ,ATTRIBUTE5_TRANSCO   = NULL
		,last_update_date = sysdate
		,last_updated_by = g_user_id
    WHERE STATUT in ('E','S');

    UPDATE DKA_SPOFUSION_SSTR_DETAIL_TMP
    SET STATUT 				= NULL
        ,CADRE_PO_HEADER_ID = NULL
        ,COMMANDE_ID        = NULL
        ,PERSON_ID          = NULL
		,ORG_ID             = NULL
		,last_update_date = sysdate
		,last_updated_by = g_user_id
    WHERE STATUT in ('E','S');

    UPDATE DKA_SPOFUSION_SSTR_IMPUT_TMP
    SET  STATUT             = NULL
        ,project_id         = NULL
        ,task_id            = NULL
        ,LOCATION_ID        = NULL
		,ORG_ID             = NULL
		,CODE_COMBINATION_ID= NULL
		,last_update_date = sysdate
		,last_updated_by = g_user_id
    WHERE STATUT in ('E','S');
 ---- Compteur des lignes a traiter :
	 	
		SELECT count(1)
        INTO g_summary.loaded_header_rows
        FROM DKA_SPOFUSION_SSTR_HEADERS_TMP 
        WHERE statut is null 
        AND DATA_TYPE = 'ACTUEL' 
		and org_abs in (SELECT
                         HROU.ORGANIZATION_ID
                        FROM
                        HR_ORGANIZATION_UNITS HROU,
                        DKA_STRANSCO_LINES DSTL,
                        DKA_STRANSCO_HEADERS DSTH
                        WHERE
                        DSTL.SET_ID = DSTH.SET_ID
                        AND HROU.NAME = DSTL.PARAM1_VALUE
                        AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                        AND DSTL.ENABLE = 'Y'
                        AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
						
						)
        ;
		
		SELECT count(1)
        INTO g_summary.loaded_detail_rows
        FROM DKA_SPOFUSION_SSTR_DETAIL_TMP 
        WHERE statut is null 
        AND DATA_TYPE = 'ACTUEL'
		and org_abs in (SELECT
                         HROU.ORGANIZATION_ID
                        FROM
                        HR_ORGANIZATION_UNITS HROU,
                        DKA_STRANSCO_LINES DSTL,
                        DKA_STRANSCO_HEADERS DSTH
                        WHERE
                        DSTL.SET_ID = DSTH.SET_ID
                        AND HROU.NAME = DSTL.PARAM1_VALUE
                        AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                        AND DSTL.ENABLE = 'Y'
                        AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
						
						)		
        ;
		
		SELECT count(1)
        INTO g_summary.loaded_imput_rows
        FROM DKA_SPOFUSION_SSTR_IMPUT_TMP 
        WHERE statut is null 
        AND DATA_TYPE = 'ACTUEL' 
		and org_abs in (SELECT
                         HROU.ORGANIZATION_ID
                        FROM
                        HR_ORGANIZATION_UNITS HROU,
                        DKA_STRANSCO_LINES DSTL,
                        DKA_STRANSCO_HEADERS DSTH
                        WHERE
                        DSTL.SET_ID = DSTH.SET_ID
                        AND HROU.NAME = DSTL.PARAM1_VALUE
                        AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                        AND DSTL.ENABLE = 'Y'
                        AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
						
						)
        ;
		
		SELECT count(1)
        INTO g_summary.loaded_header_hist_rows
        FROM DKA_SPOFUSION_SSTR_HEADERS_TMP 
        WHERE statut is null 
        AND DATA_TYPE = 'HISTO' 
		and org_abs in (SELECT
                         HROU.ORGANIZATION_ID
                        FROM
                        HR_ORGANIZATION_UNITS HROU,
                        DKA_STRANSCO_LINES DSTL,
                        DKA_STRANSCO_HEADERS DSTH
                        WHERE
                        DSTL.SET_ID = DSTH.SET_ID
                        AND HROU.NAME = DSTL.PARAM1_VALUE
                        AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                        AND DSTL.ENABLE = 'Y'
                        AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
						
						)
        ;
		
		SELECT count(1)
        INTO g_summary.loaded_detail_hist_rows
        FROM DKA_SPOFUSION_SSTR_DETAIL_TMP 
        WHERE statut is null 
        AND DATA_TYPE = 'HISTO' 
		and org_abs in (SELECT
                         HROU.ORGANIZATION_ID
                        FROM
                        HR_ORGANIZATION_UNITS HROU,
                        DKA_STRANSCO_LINES DSTL,
                        DKA_STRANSCO_HEADERS DSTH
                        WHERE
                        DSTL.SET_ID = DSTH.SET_ID
                        AND HROU.NAME = DSTL.PARAM1_VALUE
                        AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                        AND DSTL.ENABLE = 'Y'
                        AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
						
						)
        ;
		
		SELECT count(1)
        INTO g_summary.loaded_imput_hist_rows
        FROM DKA_SPOFUSION_SSTR_IMPUT_TMP 
        WHERE statut is null 
        AND DATA_TYPE = 'HISTO' 
		and org_abs in (SELECT
                         HROU.ORGANIZATION_ID
                        FROM
                        HR_ORGANIZATION_UNITS HROU,
                        DKA_STRANSCO_LINES DSTL,
                        DKA_STRANSCO_HEADERS DSTH
                        WHERE
                        DSTL.SET_ID = DSTH.SET_ID
                        AND HROU.NAME = DSTL.PARAM1_VALUE
                        AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                        AND DSTL.ENABLE = 'Y'
                        AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
						
						)
        ;



  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'SET_RECOVERY_MODE : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure SET_RECOVERY_MODE : EXCEPTION OTHERS ');
  END set_recovery_mode;


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

    PROCEDURE main(p_errbuf     IN    OUT VARCHAR2,
                 p_retcode          OUT NUMBER--,
                -- p_reprise    IN        VARCHAR2
                 )
    IS

    v_current_program_unit     VARCHAR2(30);
    v_errbuf                   VARCHAR2(2500);
    v_retcode                  NUMBER;
    Erreur_Programme           EXCEPTION;
    v_warning                  BOOLEAN := FALSE;
    v_RG_EXP01                 number;
BEGIN

      ----------------------------
      -- PHASE D'INITIALISATION --
      ----------------------------
	  ------------------------------------------------------------------------------------
      --  v_RG_EXP01 --couple Société absorbé-absorbante unique 
      ------------------------------------------------------------------------------------

BEGIN
	SELECT distinct 1 into v_RG_EXP01
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
					 --  AND NVL(DSTL.START_DATE,TRUNC(SYSDATE) )  <= TRUNC(SYSDATE)
					   group by DSTL.PARAM1_VALUE,
								DSTL.RetuRN_VALUE
					   having count(PARAM1_VALUE)>1;
	exception
	when others then
	v_RG_EXP01:=0  ;                                                                                                                                      
	end;
    if  v_RG_EXP01 = 1 then

		Dka_Tools_Pkg.put_log_message('RG_EXPST01: Plusieurs couples actifs dans la table de transco ');
        Dka_Tools_Pkg.Put_Outdebug_Message('RG_EXP01: Plusieurs couples actifs dans la table de transco ');
    end if;

      v_current_program_unit := 'main';
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'DEBUT DE L''INTERFACE'); 


      Output_Header;
      Request_parameters;

      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE D''INITIALISATION'); 

      v_errbuf  := NULL;
      v_retcode := 0;
     
      Init(v_errbuf, v_retcode);
	  set_recovery_mode(v_errbuf,
                          v_retcode
                       );

    IF v_retcode = 2 
      THEN
          p_Errbuf  := v_errbuf;
          p_retcode := v_retcode;
          RAISE Erreur_Programme;
    END IF;       

    -- Lancement de validation des données
    validate_data(v_errbuf,
                   v_retcode
                   );
    IF v_retcode = 2 
		THEN
        RAISE Erreur_Programme;
	ELSIF v_retcode = 1 THEN
        v_warning := TRUE;
		END IF;

     -- Lancement de l'insertion des données
    import_data(v_errbuf,
                   v_retcode
                   );
    IF v_retcode = 2 
		THEN
          RAISE Erreur_Programme;
		END IF;

      -- bilan
      Report_Bilan(p_Errbuf,
                   p_retcode
                 ); 

      ---------------------------------------
      -- PHASE DE FIN DU TRAITEMENT MAITRE --
      ---------------------------------------
	IF p_retcode = 2
		THEN
         p_errbuf := 'ATTENTION : Erreur bloquante : '||p_errbuf;
	ELSIF (g_summary.rejected_header_rows > 0 OR g_summary.rejected_detail_rows > 0 OR g_summary.rejected_imput_rows > 0 OR v_warning)
		THEN
         p_errbuf := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
         p_retcode := 1;
	ELSE 
         p_errbuf := 'Fin normale du traitement - Aucun rejet.';
         p_retcode := 0;
	END IF;

		COMMIT;


      Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf||CHR(10));
      output_end;
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'FIN DE L''INTERFACE');       


    EXCEPTION
        WHEN Erreur_Programme
        THEN
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
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_FUSPOIMPCTRSSTR_PKG.' || v_current_program_unit||CHR(10)||'A retourné     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           p_errbuf := SQLERRM;




END main; 


END DKA_FUSPOIMPCTRSSTR_PKG;


/
SHOW ERRORS
EXIT