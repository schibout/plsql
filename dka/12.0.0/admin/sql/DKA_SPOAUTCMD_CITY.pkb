create or replace PACKAGE BODY DKA_SPOAUTCMD_CITY_PKG IS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_SPOAUTCMD_CITY_PKG.pkb
    -- DESCRIPTION      : DKA_SPOAUTCMD_CITY_PKG Package Body
    --
    -- AUTEUR           : Anas RAOUF (Capgemini)
    -- DATE DE CREATION : 28/04/2021
    -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
    -- -----------------------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- -----------------------------------------------------------------------------
	-- 18/10/2021 ARA EDB288B - DPE20210027 – COMMANDE EN PAIEMENT DIRECTE
    
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    TYPE summary_typ IS RECORD 
    (
     loaded_header_rows               NUMBER      -- Nb des en-entêtes chargées en table specifique
    ,loaded_transaction_rows          NUMBER      -- Nb des transactions chargés en table specifique
    ,rec_final_rows                   NUMBER      -- Nb des en-entêtes chargées en table specifique
    ,rejected_header_rows             NUMBER      -- Nb de Lignes en-entêtes rejectées
    ,rejected_io_rows                 NUMBER      -- Nb de Lignes transaction rejectés
    ,complete_header_rows             NUMBER      -- SELO
    ,inserted_header_rows             NUMBER      -- Nb de Lignes en-entêtes insérées
    ,inserted_transaction_rows        NUMBER      -- Nb de Lignes transaction insérés
    ,purged_header_rows               NUMBER      -- Nb de Lignes purgées en table spécifique   
    ,purged_interface_rows            NUMBER      -- Nb de Lignes purgées en table spécifique 
    , purged_errors_rows              NUMBER
    , purged_transaction_rows         NUMBER
    ,message_flag                     NUMBER      -- Flag d'entete etat des erreurs
    ,reprise_flag                     VARCHAR2(1) -- Flag reprise
    ,warning_flag                     VARCHAR2(1) -- Flag warning
    );

    g_summary                      summary_typ;
    g_request_id      VARCHAR2(30) := fnd_global.CONC_REQUEST_ID;
    gv_created_by      VARCHAR2(60) := fnd_profile.value('USER_NAME');
    
	g_user_id          PLS_INTEGER  := fnd_profile.value('USER_ID');
	g_resp_id          PLS_INTEGER  := fnd_profile.value('RESP_ID');
	g_resp_appl_id     PLS_INTEGER  := fnd_global.resp_appl_id;
    g_step             VARCHAR2(500);
    g_login_id                     fnd_logins.login_id%TYPE;
	g_rejected			BOOLEAN:= FALSE;
    
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
        cv_line                     VARCHAR2 (1000);
        v_conc_program_name         fnd_concurrent_programs.concurrent_program_name%TYPE;
        v_user_conc_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN

        cv_line    := '+-----------------------------------------------------------------------------------------------------------------+';

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
		Fnd_File.put_line (Fnd_File.output, 'COMPTE-RENDU DU TRAITEMENT « DKA : Fermeture automatique des commandes intragroupe CITY »');
        Fnd_File.put_line (Fnd_File.output, 'Traitement n° '||fnd_global.conc_request_id);
        Fnd_File.put_line (Fnd_File.output, 'Le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') );
		Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
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
        v_argument_number    VARCHAR2(12);
        v_argument_num       NUMBER;
        v_argument_value     VARCHAR2(240);
  BEGIN

        Fnd_File.put_line (Fnd_File.output, 'PARAMETRES : ');
        Fnd_File.put_line (Fnd_File.output, '--------------');

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

                   --Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
                   Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);


                   LOOP
                      FETCH cur_parameters INTO rec_parameters;
                      EXIT WHEN cur_parameters%NOTFOUND;

                          v_argument_num := v_argument_num + 1;
                          v_argument_number := 'ARGUMENT'||v_argument_num;

                          sql_req := 'SELECT '||v_argument_number||
                                     ' FROM fnd_concurrent_requests '||
                                     'WHERE request_id = Fnd_Global.conc_request_id';

                          EXECUTE IMMEDIATE sql_req INTO v_argument_value;

                         -- Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
                          Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
                   END LOOP;

                   --Fnd_File.put_line (Fnd_File.output,CHR(10));

            ELSE
                   --Fnd_File.put_line (Fnd_File.output,'Aucun argument');
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

        cv_line    := '---------------------------------------------------------------------------';

        Fnd_File.put_line (Fnd_File.output, cv_line);
        Fnd_File.put_line (Fnd_File.output, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
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

  PROCEDURE Add_Message  (p_fact_uo      IN  VARCHAR2,
                          p_fact_num        IN  VARCHAR2,
                          p_line_number      IN  VARCHAR2,
                          p_message_text         IN  VARCHAR2
                          ) 
  IS
        cv_line                     VARCHAR2 (500);
  BEGIN

    /*IF  g_summary.message_flag = 0 THEN
    --  cv_line := 'Liste des rejets de validation :';
    --  Fnd_File.put_line (Fnd_File.output, CHR(10)||cv_line);
    --  cv_line := '-----------------';
    --  Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := 'UO Facture  Numéro Facture   Num. ligne   Message';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := '----------  --------------   ----------   ---------------------------------';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      g_summary.message_flag := 1;
    
	ELSIF  g_summary.message_flag = 1 THEN
    --  cv_line := 'Liste des rejets de validation :';
    --  Fnd_File.put_line (Fnd_File.output, CHR(10)||cv_line);
    --  cv_line := '-----------------';
    --  Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := 'UO Facture  Numéro Facture   Num. ligne   Numéro de commande fermée';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := '----------  --------------   ----------   ---------------------------------';
      Fnd_File.put_line (Fnd_File.output, cv_line);
    END IF;*/
	
	
    cv_line := RPAD(nvl(p_fact_uo,' '),10,' ') ||'  '||RPAD(NVL(p_fact_num,' '),15,' ') ||'  '|| RPAD(nvl(TO_CHAR(p_line_number),' '),10,' ') ||'   ' || p_message_text ;

    Fnd_File.put_line (Fnd_File.output, cv_line);
    
  END Add_Message;
  
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
                  p_retcode   OUT      NUMBER,
				  p_period IN VARCHAR2
                  )
  IS

    v_current_program_unit    VARCHAR2(30);
    v_step_program_error      VARCHAR2(1000);
    program_error             EXCEPTION;
    rec_param dka_parameters%ROWTYPE;
	v_num_fourn_cmd 		  VARCHAR2(30);
	v_record_id               NUMBER;
	v_fourn_cmd				  VARCHAR2(240);
    v_name                    VARCHAR2(30);
	v_org_id_cmd 			  NUMBER;
        
	CURSOR cur_city IS
	SELECT  	   hou1.name        UO_FACTURE,
				   aial.LINE_NUMBER LIGNE_FACTURE,
				   aida.DISTRIBUTION_LINE_NUMBER LINE_NUMBER,
				   aia.INVOICE_NUM,
				   aia.ORG_ID       ORG_ID_FACT,
				   ass1.VENDOR_NAME FOURN_FACT,
				   ass1.SEGMENT1 NUM_FOURN_FACT,
				   DECODE(regexp_count(aida.Description, ' '),0,aida.Description,
						  Substr(aida.Description, 1, instr(aida.Description, ' ') - 1)) NUM_CMD
				   
				   --hou2.name UO_CMD,
				   --pha.ORG_ID ORG_CMD
				   
			from   ap_invoices_all aia,
				   ap_invoice_lines_all aial,
				   hr_operating_units   hou1,
				   ap_invoice_distributions_All aida,
				   ap_suppliers         ass1

			 where aia.invoice_id = aial.invoice_id
			   AND aia.org_id = hou1.ORGANIZATION_ID
			   AND aida.invoice_id = aial.invoice_id
               AND aida.INVOICE_LINE_NUMBER = aial.LINE_NUMBER
			   
			   
			   AND ass1.vendor_id = aia.vendor_id
			   AND aia.ATTRIBUTE9 = 'CYF'
			   AND aida.PERIOD_NAME = p_period -- 'FEV-18'
			   AND aida.LINE_TYPE_LOOKUP_CODE = 'ITEM'
			   AND aida.ACCRUAL_POSTED_FLAG = 'Y'
               order by 4,2,3;

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

        -- Variables globales de comptage


        g_summary.rejected_header_rows           := 0;
        g_summary.complete_header_rows           := 0;
      
        
		FOR rec_city in cur_city LOOP
        BEGIN
           
           BEGIN
           SELECT pha.org_id , hou.name 
           INTO v_org_id_cmd ,v_name
           FROM hr_operating_units hou , PO_HEADERS_ALL pha
           WHERE hou.organization_id = pha.org_id
           AND pha.segment1 = rec_city.NUM_CMD
		   AND hou.name = rec_city.UO_FACTURE;
           EXCEPTION
           WHEN NO_DATA_FOUND THEN
           v_name := NULL;
           v_org_id_cmd:=0;
           END;
		   
		   SELECT DKA_SAPCDE_CITY_TMP_S.nextval 
			INTO v_record_id
           FROM DUAL;
		   
		   INSERT INTO DKA_SAPCDE_CITY_TMP
			(
				RECORD_ID,
				LINE_NUMBER,
				UO_FACTURE,  
				INVOICE_NUM,  
				ORG_ID_FACT,  
				FOURN_FACT,  
				NUM_FOURN_FACT,  
				NUM_CMD,
				UO_CMD,
				FOURN_CMD,
				NUM_FOURN_CMD,
				ORG_ID_CMD,
				STATUT, 
				REQUEST_ID,
				CREATION_DATE,        
				CREATED_BY,   
				LAST_UPDATE_DATE,  
				LAST_UPDATED_BY
			)
			VALUES
			(
				v_record_id,
				rec_city.LIGNE_FACTURE || '-' || rec_city.LINE_NUMBER,
				rec_city.UO_FACTURE,
				rec_city.INVOICE_NUM,
				rec_city.ORG_ID_FACT,
				rec_city.FOURN_FACT,
				rec_city.NUM_FOURN_FACT,
				rec_city.NUM_CMD,
				NULL, --v_name,
				NULL,
				NULL,
				NULL, --v_org_id_cmd,
				'NEW',
				g_request_id,
				SYSDATE,
				g_user_id,
				SYSDATE,
				g_user_id
			);
        END;
		END LOOP;
        COMMIT;
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
/* *************************************************************************
 * PROCEDURE NAME : purge_data
 *
 * DESCRIPTION
 *  Procédure de purge des données
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
 * -----------------  ------------------------------------------------------
 *
 *************************************************************************/
  PROCEDURE purge_data(p_Errbuf            OUT VARCHAR2,
                       p_retcode           OUT NUMBER
                              ) 
  IS

  BEGIN

     Fnd_File.Put_Line(Fnd_File.LOG, '-> DKA_SAPCDE_CITY_TMP' );     
     
     EXECUTE IMMEDIATE 'TRUNCATE TABLE DKA.DKA_SAPCDE_CITY_TMP';
	   
     g_summary.purged_transaction_rows := SQL%ROWCOUNT;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows dans la table DKA_SAPCDE_CITY_TMP :'||TO_CHAR(g_summary.purged_transaction_rows));     
	   
	   
    DELETE FROM dka_program_messages dpm
    where prog_name ='DKA_SPOAUTCMD_CITY';
     
	COMMIT;
  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'PURGE_DATA : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure PURGE_DATA : EXCEPTION OTHERS ');
  END purge_data;

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
--------------------------------------------------------------------------------------
PROCEDURE validate_data(p_Errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
	
	
	v_message                     VARCHAR2(500);
    v_flag_erreur                 BOOLEAN := FALSE;
	v_CMD_ID                      Number;
	v_paiement_direct			  VARCHAR2(10); 
	v_result_ID					  Number;
    v_num_fourn_cmd               VARCHAR2(30); 
    v_fourn_cmd                   VARCHAR2(240);
	v_name                    VARCHAR2(30);
	v_org_id_cmd 			  NUMBER;
	
	CURSOR cur_cmd_new IS
		SELECT *
		  FROM DKA_SAPCDE_CITY_TMP
		 WHERE 1 = 1
		   AND STATUT = 'NEW'
		 ORDER BY record_id
         FOR UPDATE OF record_id;
    
    CURSOR cur2 IS
    select AA.NUM_CMD , AA.LINE_NUMBER , AA.RECORD_ID
    from DKA_SAPCDE_CITY_TMP AA , 
    (
        select NUM_CMD , COUNT(NUM_CMD) , MIN(RECORD_ID) RECORD_ID
        from DKA_SAPCDE_CITY_TMP 
        where 1 = 1 --invoice_num = 'EDB288_F101'
        AND STATUT = 'VALIDATED'
        GROUP BY NUM_CMD
        HAVING COUNT(NUM_CMD) > 2
    ) BB
    where  1 = 1 --AA.invoice_num = 'EDB288_F101' 
    AND AA.NUM_CMD = BB.NUM_CMD
    AND AA.RECORD_ID != BB.RECORD_ID
    AND AA.STATUT = 'VALIDATED';


BEGIN

	Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_data');
	Fnd_File.put_line(Fnd_File.LOG,
                    TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                    'Validation des données dans les tables spécifiques : ');




	FOR rec_cursor_city IN cur_cmd_new LOOP
		BEGIN
			v_flag_erreur := FALSE;
			v_org_id_cmd := null;
	        v_name := null;
			-- RG31-07-1
			IF rec_cursor_city.NUM_CMD IS NULL THEN
				v_CMD_ID := 0;
			    v_message :=dka_tools_pkg.get_message('DKA','DKA_SPOCITY_E01');
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_SPOAUTCMD_CITY', --prog_name
                                                'FERMETURE',               --source
                                                'DKA_SAPCDE_CITY_TMP' ,   --table_name
                                                rec_cursor_city.RECORD_ID,  --table_id
                                                'NUM_CMD',  --column_name
                                                rec_cursor_city.NUM_CMD, --column_value
                                                'E',                       --message_type
                                                v_message                   --message_text
                                                );
                    v_flag_erreur := TRUE;
					g_rejected := TRUE;
                
                UPDATE DKA_SAPCDE_CITY_TMP
                 SET STATUT = 'REJECTED'
                   , request_id = g_request_id
               WHERE CURRENT OF cur_cmd_new;
			END IF;
			
			--RG31-07-2
			IF rec_cursor_city.NUM_CMD IS NOT NULL THEN
				--v_CMD_ID:=0;
				BEGIN
					select PHA.PO_header_id into v_CMD_ID
					  from PO_HEADERS_ALL PHA
					 where PHA.segment1 = rec_cursor_city.NUM_CMD;
					 --  AND PHA.org_id   = rec_cursor_city.ORG_ID_CMD
				EXCEPTION
					WHEN no_data_found THEN
						v_message :=dka_tools_pkg.get_message('DKA','DKA_SPOCITY_E02','NUMERO_COMMANDE',rec_cursor_city.NUM_CMD);
						DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
														'DKA_SPOAUTCMD_CITY', --prog_name
														'FERMETURE',               --source
														'DKA_SAPCDE_CITY_TMP' ,   --table_name
														rec_cursor_city.RECORD_ID,  --table_id
														'NUM_CMD',  --column_name
														rec_cursor_city.NUM_CMD, --column_value
														'E',                       --message_type
													    v_message                   --message_text
													  );
						v_flag_erreur := TRUE;
						g_rejected := TRUE;
						fnd_file.put_line(fnd_file.log,
                              'DKA_SPOCITY_E02 ||' || rec_cursor_city.NUM_CMD || '| erreur: ' || sqlerrm);
						UPDATE DKA_SAPCDE_CITY_TMP
						 SET STATUT = 'REJECTED'
						   , request_id = g_request_id
					   WHERE CURRENT OF cur_cmd_new;
						v_CMD_ID := 0;
					WHEN too_many_rows THEN
						v_CMD_ID:=1;
						
				END;
			END IF;
			
            /*fnd_file.put_line(fnd_file.log,
                              'DKA_SPOCITY_E03 DEBUT  ||' || rec_cursor_city.NUM_CMD);*/
			-- Commande Trouvée
			IF v_CMD_ID <> 0 THEN
				  
			   BEGIN
				   SELECT pha.org_id , hou.name 
				   INTO v_org_id_cmd ,v_name
				   FROM hr_operating_units hou , PO_HEADERS_ALL pha
				   WHERE hou.organization_id = pha.org_id
				   AND pha.segment1 = rec_cursor_city.NUM_CMD
				   AND hou.name = rec_cursor_city.UO_FACTURE;
				   
				 UPDATE DKA_SAPCDE_CITY_TMP
                 SET UO_CMD = v_name
                   , ORG_ID_CMD = v_org_id_cmd
               WHERE CURRENT OF cur_cmd_new;
				   
			   EXCEPTION
			   WHEN others THEN
			   
			       SELECT hou.name 
				     INTO v_name
				     FROM hr_operating_units hou , PO_HEADERS_ALL pha
				    WHERE hou.organization_id = pha.org_id
				      AND pha.segment1 = rec_cursor_city.NUM_CMD
				    --  AND hou.name = rec_city.UO_FACTURE
					  AND ROWNUM<2;
			    
			   
			   
				   v_message :=dka_tools_pkg.get_message('DKA','DKA_SPOCITY_E03','NUMERO_COMMANDE',rec_cursor_city.NUM_CMD
														  ,'NOM_UO_COMMANDE',v_name
														  ,'NOM_UO_FACTURE',rec_cursor_city.UO_FACTURE);
						DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
														'DKA_SPOAUTCMD_CITY', --prog_name
														'FERMETURE',               --source
														'DKA_SAPCDE_CITY_TMP' ,   --table_name
														rec_cursor_city.RECORD_ID,  --table_id
														'UO_CMD',  --column_name
														rec_cursor_city.UO_CMD, --column_value
														'E',                       --message_type
													    v_message                   --message_text
													  );
						v_flag_erreur := TRUE;
						g_rejected := TRUE;
						fnd_file.put_line(fnd_file.log,
                              'DKA_SPOCITY_E03 ||' || rec_cursor_city.NUM_CMD || '| erreur: ' || sqlerrm);
						UPDATE DKA_SAPCDE_CITY_TMP
						 SET STATUT = 'REJECTED'
						   , request_id = g_request_id
					   WHERE CURRENT OF cur_cmd_new;
			   END;
				
				
				
				IF ( rec_cursor_city.FOURN_FACT IS NOT NULL ) and ( v_org_id_cmd is not null ) THEN
                 /*fnd_file.put_line(fnd_file.log,
                              'DKA_SPOCITY_E04.0 DEBUT  ||' || rec_cursor_city.NUM_CMD);*/
                    BEGIN
                    
					/*fnd_file.put_line(fnd_file.log,
                              'DKA_SPOCITY_E04.6 ' || rec_cursor_city.NUM_CMD || '  ICI  ' || rec_cursor_city.ORG_ID_CMD || '  ICI   ' || v_org_id_cmd);*/
							  
					SELECT pv.SEGMENT1 ,pv.VENDOR_NAME
                    INTO v_num_fourn_cmd , v_fourn_cmd
                    FROM PO_HEADERS_ALL pha ,PO_VENDORS pv
                    WHERE pv.vendor_id = pha.vendor_id
                    AND pha.SEGMENT1 = rec_cursor_city.NUM_CMD
                    AND pha.org_id = v_org_id_cmd;
					
					/*fnd_file.put_line(fnd_file.log,
                              'DKA_SPOCITY_E04.7 ' || rec_cursor_city.NUM_CMD || 'ICI  ');*/
					
					UPDATE DKA_SAPCDE_CITY_TMP
					 SET FOURN_CMD = v_fourn_cmd 
					   , NUM_FOURN_CMD = v_num_fourn_cmd
				    WHERE CURRENT OF cur_cmd_new;
					
                    EXCEPTION
                    WHEN OTHERS THEN
                        fnd_file.put_line(fnd_file.log,
                              'DKA_SPOCITY_E04.0 FIN    ||' || rec_cursor_city.NUM_CMD || '| erreur: ' || sqlerrm);
                    END;
					
					
					
                    IF NVL(rec_cursor_city.FOURN_FACT,'A') != NVL(v_fourn_cmd,'B') THEN
					v_message :=dka_tools_pkg.get_message('DKA','DKA_SPOCITY_E04','NUMERO_COMMANDE',rec_cursor_city.NUM_CMD
														  ,'NUMERO_FOURNISSEUR_CDE',v_num_fourn_cmd
														  ,'NUMERO_FOURNISSEUR_FACT',rec_cursor_city.NUM_FOURN_FACT);
						DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
														'DKA_SPOAUTCMD_CITY', --prog_name
														'FERMETURE',               --source
														'DKA_SAPCDE_CITY_TMP' ,   --table_name
														rec_cursor_city.RECORD_ID,  --table_id
														'NUM_FOURN_CMD',  --column_name
														rec_cursor_city.NUM_FOURN_CMD, --column_value
														'E',                       --message_type
													    v_message                   --message_text
													  );
						v_flag_erreur := TRUE;
						g_rejected := TRUE;
                        fnd_file.put_line(fnd_file.log,
                              'DKA_SPOCITY_E04 ||' || rec_cursor_city.NUM_CMD || '| erreur: ' || sqlerrm);
						UPDATE DKA_SAPCDE_CITY_TMP
						 SET STATUT = 'REJECTED'
						   , request_id = g_request_id
					   WHERE CURRENT OF cur_cmd_new;
				    /*ELSE
					fnd_file.put_line(fnd_file.log,
						  'DKA_SPOCITY_E04.1 DEBUT  ||' || v_fourn_cmd );*/
					END IF;
                    
				--ELSE
					/*fnd_file.put_line(fnd_file.log,
                              'DKA_SPOCITY_E05 DEBUT  ||' || rec_cursor_city.NUM_CMD);*/
					v_result_ID:=0;
					if (v_org_id_cmd is not null) then 
						BEGIN
							select PHA.PO_header_id into v_result_ID
							  from PO_HEADERS_ALL PHA
							 where PHA.segment1 = rec_cursor_city.NUM_CMD
							 AND PHA.AUTHORIZATION_STATUS = 'APPROVED'
							 AND NVL(PHA.CANCEL_FLAG,'N') <> 'Y'
							 AND NVL(PHA.CLOSED_CODE,'OPEN') NOT IN ('CLOSED' ,'FINALLY CLOSED')
							 AND PHA.ORG_ID = v_org_id_cmd;
						EXCEPTION
							WHEN no_data_found THEN
								v_message := dka_tools_pkg.get_message('DKA','DKA_SPOCITY_E05','NUMERO_COMMANDE',rec_cursor_city.NUM_CMD);
								DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
																'DKA_SPOAUTCMD_CITY', --prog_name
																'FERMETURE',               --source
																'DKA_SAPCDE_CITY_TMP' ,   --table_name
																rec_cursor_city.RECORD_ID,  --table_id
																'NUM_CMD',  --column_name
																rec_cursor_city.NUM_CMD, --column_value
																'E',                       --message_type
																v_message                   --message_text
															  );
								v_flag_erreur := TRUE;
								g_rejected := TRUE;
								fnd_file.put_line(fnd_file.log,
								  'DKA_SPOCITY_E05 ||' || rec_cursor_city.NUM_CMD || '| erreur: ' || sqlerrm);
								
								UPDATE DKA_SAPCDE_CITY_TMP
								 SET STATUT = 'REJECTED'
								   , request_id = g_request_id
							   WHERE CURRENT OF cur_cmd_new;
								v_result_ID := 0;
							WHEN too_many_rows THEN
								v_result_ID:=1;
								
								
								
							
						END;
				    END IF;
					
					BEGIN -- EDB288B
						SELECT PHA.ATTRIBUTE13 INTO v_paiement_direct 
						from PO_HEADERS_ALL PHA
						where PHA.SEGMENT1 = rec_cursor_city.NUM_CMD
                        AND PHA.org_id = rec_cursor_city.ORG_ID_FACT;
					END;
					
					IF v_paiement_direct = 'OUI' THEN
						v_message := dka_tools_pkg.get_message('DKA','DKA_SPOCITY_E07','NUMERO_COMMANDE',rec_cursor_city.NUM_CMD);
								DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
																'DKA_SPOAUTCMD_CITY', --prog_name
																'FERMETURE',               --source
																'DKA_SAPCDE_CITY_TMP' ,   --table_name
																rec_cursor_city.RECORD_ID,  --table_id
																'NUM_CMD',  --column_name
																rec_cursor_city.NUM_CMD, --column_value
																'E',                       --message_type
																v_message                   --message_text
															  );
								v_flag_erreur := TRUE;
								g_rejected := TRUE;
								fnd_file.put_line(fnd_file.log,
								  'DKA_SPOCITY_E07 ||' || rec_cursor_city.NUM_CMD || '| erreur: ' || sqlerrm);
								
								UPDATE DKA_SAPCDE_CITY_TMP
								 SET STATUT = 'REJECTED'
								   , request_id = g_request_id
							   WHERE CURRENT OF cur_cmd_new;
					END IF;
					
				END IF;

			END IF;
			
			IF NOT v_flag_erreur THEN
				UPDATE DKA_SAPCDE_CITY_TMP
				   SET STATUT = 'VALIDATED'
					 , request_id = g_request_id
				 WHERE CURRENT OF cur_cmd_new;    
			END IF ;
			
			
		EXCEPTION
        WHEN others THEN
            fnd_file.put_line(fnd_file.log,
                              'VALIDATION COMMANDE IMPOSSIBLE||' || rec_cursor_city.NUM_CMD || '| erreur: ' || sqlerrm);
      
            ROLLBACK;
      
			UPDATE DKA_SAPCDE_CITY_TMP
			SET STATUT = 'REJECTED'
			, request_id = g_request_id
			WHERE CURRENT OF cur_cmd_new;
			
			
			
			
		END;
	END LOOP;

    FOR rec in cur2 LOOP
        UPDATE DKA_SAPCDE_CITY_TMP
			SET STATUT = 'REJECTED'
			, request_id = g_request_id
			WHERE RECORD_ID =  rec.record_id;
            
        v_message := dka_tools_pkg.get_message('DKA','DKA_SPOCITY_E05','NUMERO_COMMANDE',rec.NUM_CMD);
							DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
															'DKA_SPOAUTCMD_CITY', --prog_name
															'FERMETURE',               --source
															'DKA_SAPCDE_CITY_TMP' ,   --table_name
															rec.RECORD_ID,  --table_id
															'NUM_CMD',  --column_name
															rec.NUM_CMD, --column_value
															'E',                       --message_type
															v_message                   --message_text
														  );
    END LOOP;

    
      Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_data');

    COMMIT; 

END validate_data;
 /*
 *************************************************************************
 * PROCEDURE NAME : Fermeture des commandes 
 * 
 * DESCRIPTION
 *  Procédure de Fermeture des commandes validés
 *
 * PARAMETERS
 * ==========
 * NAME                 DESCRIPTION
.* -------------------- ---------------------------------------------------
 * p_errbuf            Retour de message éventuel
 * p_retcode           Statut du traitement en sortie
 ************************************************************************
 */

  PROCEDURE Fermer_commandes(Pv_Errbuf    OUT VARCHAR2,
							 Pn_Retcode   OUT NUMBER) 
  IS
  
  v_resp_id                NUMBER;
  v_resp_appl_id           NUMBER;
  v_message				   VARCHAR2(500);
  x_action constant varchar2(20) := 'FINALLY CLOSE'; -- Change this parameter as per requirement

  x_calling_mode constant varchar2(2) := 'PO';

  x_conc_flag constant varchar2(1) := 'N';

  x_return_code_h varchar2(100);

  x_auto_close constant varchar2(1) := 'N';

  x_origin_doc_id number;

  x_returned boolean;
  
  
  CURSOR cur_cmd_valides is
    select record_id , NUM_CMD , ORG_ID_CMD
      from DKA_SAPCDE_CITY_TMP
     where STATUT = 'VALIDATED'
	 ORDER BY record_id
     FOR UPDATE OF record_id;	
  
  CURSOR c_po_details (p_segment VARCHAR2,p_org_id NUMBER) IS

	SELECT 

	pha.po_header_id,

	pha.org_id,

	pha.segment1,

	pha.agent_id,

	pdt.document_subtype,

	pdt.document_type_code,

	pha.closed_code,

	pha.closed_date

	FROM apps.po_headers_all pha, apps.po_document_types_all pdt

	WHERE pha.type_lookup_code = pdt.document_subtype

	AND pha.org_id = pdt.org_id

	AND pdt.document_type_code = 'PO'

	AND authorization_status = 'APPROVED'
	
	AND pha.SEGMENT1 = p_segment

	AND pha.org_id = p_org_id;
	
	--AND pha.po_header_id = 949049; -- Enter the PO Number if one PO needs to be finally closed/Closed
  
  BEGIN
	
	/*SELECT responsibility_id, application_id
        INTO v_resp_id, v_resp_appl_id
        FROM fnd_responsibility fr, hr_operating_units hou
        WHERE hou.organization_id = rec.org_id
        AND fr.responsibility_key = hou.name || '_PO_ADMINISTRATEUR';*/
	
	APPS.FND_GLOBAL.APPS_INITIALIZE(USER_ID      => g_user_id,
                                        RESP_ID      => g_resp_id,
                                        RESP_APPL_ID => g_resp_appl_id
                                    );
	
	FOR rec_city_valid IN cur_cmd_valides LOOP
		
		for po_head in c_po_details(rec_city_valid.NUM_CMD , rec_city_valid.ORG_ID_CMD) LOOP

			mo_global.init (po_head.document_type_code);

			mo_global.set_policy_context ('S', po_head.org_id);

			--DBMS_OUTPUT.PUT_LINE ('Calling PO_Actions.close_po for Closing/Finally Closing PO =>'|| po_head.segment1);
			
			Fnd_File.put_line (Fnd_File.log, 'Calling PO_Actions.close_po for Closing/Finally Closing PO =>'|| po_head.segment1);  

			x_returned :=

			po_actions.close_po(
			
			p_docid => po_head.po_header_id,

			p_doctyp => po_head.document_type_code,

			p_docsubtyp => po_head.document_subtype,

			p_lineid => NULL,

			p_shipid => NULL,

			p_action => x_action,

			p_reason => 'Fermeture Auto Commande IntraGroupe City',

			p_calling_mode => x_calling_mode,

			p_conc_flag => x_conc_flag,

			p_return_code => x_return_code_h,

			p_auto_close => x_auto_close,

			p_action_date => SYSDATE,

			p_origin_doc_id => NULL);

			IF x_returned = TRUE THEN

			--DBMS_OUTPUT.PUT_LINE ('Purchase Order which just got Closed/Finally Closed is ' || po_head.segment1);
			Fnd_File.put_line (Fnd_File.log, 'La commande : ' || rec_city_valid.NUM_CMD || ' a été bien fermée.');  
			
			UPDATE DKA_SAPCDE_CITY_TMP
				   SET STATUT = 'COMPLETE'
					 , request_id = g_request_id
				 WHERE CURRENT OF cur_cmd_valides; 
			
			

			ELSE

			--DBMS_OUTPUT.PUT_LINE ('API Failed to Close/Finally Close the Purchase Order');
			Fnd_File.put_line (Fnd_File.log, 'La commande : ' || rec_city_valid.NUM_CMD || ' n''a pas été bien fermée.');  
			
			v_message := dka_tools_pkg.get_message('DKA','DKA_SPOCITY_E06','NUMERO_COMMANDE',rec_city_valid.NUM_CMD
												  ,'ERROR',SQLERRM);
							DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
															'DKA_SPOAUTCMD_CITY', --prog_name
															'FERMETURE API',               --source
															'DKA_SAPCDE_CITY_TMP' ,   --table_name
															rec_city_valid.RECORD_ID,  --table_id
															'NUM_CMD',  --column_name
															rec_city_valid.NUM_CMD, --column_value
															'E',                       --message_type
															v_message                   --message_text
														  );
			
			
			END IF;

			END LOOP;
	
	END LOOP;
	
	COMMIT;
  
  END Fermer_commandes;




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
  PROCEDURE Report_Bilan(p_statut IN NUMBER) 
  IS
    
	CURSOR cur_err_validate is
    select distinct dii.UO_FACTURE, dii.INVOICE_NUM , dii.LINE_NUMBER , TABLE_ID , message_text
      from dka_program_messages dpm,
	       DKA_SAPCDE_CITY_TMP dii
     where prog_name ='DKA_SPOAUTCMD_CITY'
       and table_id = dii.record_id	 
       and dii.request_id = g_request_id
	   and dpm.request_id = g_request_id
	   order by dpm.TABLE_ID;	
	
	
	CURSOR cur_success IS
	   SELECT UO_FACTURE , INVOICE_NUM , LINE_NUMBER , NUM_CMD
       FROM DKA_SAPCDE_CITY_TMP
       WHERE STATUT = 'COMPLETE'
       AND request_id=g_request_id;

     cv_line    VARCHAR2(100);
     V_STATUT   VARCHAR2(15);
  BEGIN

        cv_line    := '----------------------------------------------------------------------------------';

  
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Report_Bilan');

        --------------------    
        -- Initialisation --
        --------------------          
  
        BEGIN                          
            SELECT count(1)
              INTO g_summary.rejected_header_rows
              FROM DKA_SAPCDE_CITY_TMP
             WHERE STATUT = 'REJECTED'
            ;

            SELECT count(1)
              INTO g_summary.complete_header_rows
              FROM DKA_SAPCDE_CITY_TMP
             WHERE STATUT = 'COMPLETE'
            ;

            select decode(p_statut, 0, 'Normal', 1, 'Avertissement', 2, 'Erreur') into v_statut
		      from dual;
		EXCEPTION
		  when others then
		    null;
		END;		  

    --    Fnd_File.put_line (Fnd_File.output, 'Numéro de traitement : '||g_REQUEST_ID ||' Statut : ' ||v_statut);
        Fnd_File.put_line (Fnd_File.output,  CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'BILAN : ');  
		Fnd_File.put_line (Fnd_File.output, '-------' || CHR(10));
        
       -- fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des transactions chargées dans la table spécifique                   : ' ||TO_CHAR(g_summary.loaded_transaction_rows)); 


       
        

     --   fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements inserés dans la table RCV_HEADERS_INTERFACE        : ' || TO_CHAR(g_summary.inserted_header_rows));
     --   fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements inserés dans la table RCV_TRANSACTIONS_INTERFACE   : ' || TO_CHAR(g_summary.inserted_transaction_rows)); 
        
		
		fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements traités avec succès :                              : '||TO_CHAR(g_summary.complete_header_rows));		
		fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements rejetés                                            : ' || TO_CHAR(g_summary.rejected_header_rows) || CHR(10));
        
		--Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'LISTE DES REJETS : ');      
		Fnd_File.put_line (Fnd_File.output, '---------------------' || CHR(10));
		
		cv_line := 'UO Facture  Numéro Facture   Num. ligne   Message';
		Fnd_File.put_line (Fnd_File.output, cv_line);
		cv_line := '----------  --------------   ----------   ---------------------------------';
		Fnd_File.put_line (Fnd_File.output, cv_line);
	
		FOR rec_cur_err_validate IN cur_err_validate LOOP		   
            Add_Message(rec_cur_err_validate.UO_FACTURE, rec_cur_err_validate.INVOICE_NUM, rec_cur_err_validate.LINE_NUMBER, rec_cur_err_validate.message_text);
        END LOOP;			
		
		--g_summary.message_flag := 0;
		
		Fnd_File.put_line (Fnd_File.output, CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'LISTE DES COMMANDES FERMEES AVEC SUCCES  : '); 
		Fnd_File.put_line (Fnd_File.output, '-----------------------------------------' || CHR(10));
		
		cv_line := 'UO Facture  Numéro Facture   Num. ligne   Numéro de commande fermée';
		Fnd_File.put_line (Fnd_File.output, cv_line);
		cv_line := '----------  --------------   ----------   ---------------------------------';
		Fnd_File.put_line (Fnd_File.output, cv_line);
		FOR rec_cur_success IN cur_success LOOP
            Add_Message(rec_cur_success.UO_FACTURE, rec_cur_success.INVOICE_NUM, rec_cur_success.LINE_NUMBER, rec_cur_success.NUM_CMD);
        END LOOP;
		
		g_summary.message_flag := 0;
        fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Report_Bilan');  
		
 
  END Report_Bilan;

 /*
 *************************************************************************
 * PROCEDURE NAME : main
 * 
 * DESCRIPTION
 *  Procédure générale du traitement
 *
 * PARAMETERS
 * ==========
 * NAME                 DESCRIPTION
.* -------------------- ---------------------------------------------------
 * p_errbuf            Retour de message éventuel
 * p_retcode           Statut du traitement en sortie
 ************************************************************************
 */
PROCEDURE main(Pv_Errbuf    IN OUT VARCHAR2,
                   Pn_Retcode   IN OUT NUMBER,
                   P_period IN VARCHAR2
                   )
IS
  v_errbuf                    VARCHAR2(2500);
  v_retcode                   NUMBER;
  Erreur_Programme            EXCEPTION;
  cv_line                     VARCHAR2 (100);
  v_current_program_unit      VARCHAR2(30);
  
BEGIN

      Output_Header;
    
      Request_parameters; 
	  
	  purge_data(v_errbuf,
                    v_retcode
                   );
	  IF v_retcode = 2 
      THEN
          Pv_Errbuf  := v_errbuf;
          Pn_Retcode := v_retcode;
          RAISE Erreur_Programme;
      END IF;
	  
	  Init(v_errbuf, v_retcode,P_period);  -- Add period as param later
      
      IF v_retcode = 2 
      THEN
          Pv_Errbuf  := v_errbuf;
          Pn_Retcode := v_retcode;
          RAISE Erreur_Programme;
      END IF;  
	  
	  validate_data(v_errbuf,
                    v_retcode
                   );
      IF v_retcode = 2 
      THEN
          Pv_Errbuf  := v_errbuf;
          Pn_Retcode := v_retcode;
          RAISE Erreur_Programme;
      END IF;
      
      Fermer_commandes(v_errbuf,
                    v_retcode
                   );
      IF v_retcode = 2 
      THEN
          Pv_Errbuf  := v_errbuf;
          Pn_Retcode := v_retcode;
          RAISE Erreur_Programme;
      END IF;
      
	  Report_Bilan(v_retcode);
	  
	  IF (g_rejected) THEN
		Pn_Retcode :=1;
		Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'ATTENTION : Il y a des cas de rejet.');
	  ELSE
		Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Fin normale du traitement - Aucun rejet.');
	  END IF;
	  
      output_end;
	EXCEPTION
        WHEN Erreur_Programme THEN
            Pn_Retcode   := 2;
            Pv_Errbuf    := v_errbuf;
            Fnd_File.put_line (Fnd_File.LOG, Pv_Errbuf);
            Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||Pv_Errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');        
            Fnd_File.put_line (Fnd_File.OUTPUT, '==> Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');        
       WHEN OTHERS 
       THEN
           fnd_concurrent.af_rollback;
           Pn_Retcode := 2;
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_SPOAUTCMD_CITY_PKG.' || v_current_program_unit||CHR(10)||'A retourné     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           Pv_Errbuf := SQLERRM;
END main;
    
END DKA_SPOAUTCMD_CITY_PKG;

/
SHOW ERRORS;
EXIT