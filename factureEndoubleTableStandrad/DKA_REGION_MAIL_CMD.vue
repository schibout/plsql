create or replace PACKAGE BODY DKA_SPOCMDMAIL_CITY_PKG IS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_SPOCMDMAIL_CITY_PKG.pkb
    -- DESCRIPTION      : DKA_SPOCMDMAIL_CITY_PKG Package Body
    --
    -- AUTEUR           : Anas RAOUF (Capgemini)
    -- DATE DE CREATION : 03/05/2021
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
     loaded_header_rows               NUMBER      -- Nb des en-entétes chargées en table specifique
    ,loaded_transaction_rows          NUMBER      -- Nb des transactions chargés en table specifique
    ,rec_final_rows                   NUMBER      -- Nb des en-entétes chargées en table specifique
    ,rejected_header_rows             NUMBER      -- Nb de Lignes en-entétes rejectées
    ,rejected_io_rows                 NUMBER      -- Nb de Lignes transaction rejectés
    ,complete_header_rows             NUMBER      -- SELO
    ,inserted_header_rows             NUMBER      -- Nb de Lignes en-entétes insérées
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
    g_org_id           PLS_INTEGER  := FND_GLOBAL.org_id;
	g_resp_appl_id     PLS_INTEGER  := fnd_global.resp_appl_id;
    g_login_id                     fnd_logins.login_id%TYPE;
	cv_directory CONSTANT VARCHAR2(50) := 'DKA_OUT_DIR';

	gv_expediteur      VARCHAR2(150);
    gv_conn            VARCHAR2(30);
    g_step             VARCHAR2(500);
    gv_plat_appro_mail VARCHAR2(4000);
    gv_nom_mail VARCHAR2(4000);
    gv_base            v$database.name%TYPE;
    gn_amt             BINARY_INTEGER := 672 * 3;
    BOUNDARY            CONSTANT VARCHAR2(256) := '=_NextPart_DC7E1BB5_1105_4DB3_BAE3_2A6208EB099D';
    FIRST_BOUNDARY      CONSTANT VARCHAR2(256) := '--' || BOUNDARY ||
                                                  utl_tcp.CRLF;
    LAST_BOUNDARY       CONSTANT VARCHAR2(256) := '--' || BOUNDARY || '--' ||
                                                  utl_tcp.CRLF;
    MULTIPART_MIME_TYPE CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary=' ||
                                                  BOUNDARY;
    MAX_LINE_WIDTH PLS_INTEGER := 54;

    -- Variable d'exception :
    e_envoi_mail EXCEPTION;
    e_mail EXCEPTION;

    -- Variable contenant l'entéte et le corps du mail.
    gv_objet VARCHAR2(4000);
    gv_corps VARCHAR2(4000);

	  TYPE liste_destinataires IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;


/*
 *************************************************************************
 * PROCEDURE NAME : Output_Header
 *
 * DESCRIPTION
 *  Procédure pour insérer une en-téte dans le fichier de sortie
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
		Fnd_File.put_line (Fnd_File.output, 'COMPTE-RENDU DU TRAITEMENT : DKA : Edition et envoi par mail de l''état de la facturation et des commandes CITY ');
        Fnd_File.put_line (Fnd_File.output, 'Traitement n ° : '||fnd_global.conc_request_id);
        Fnd_File.put_line (Fnd_File.output, 'Le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') );
		Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
  END output_header;


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
        cv_line                     VARCHAR2 (1000);
  BEGIN

        cv_line    := '+---------------------------------------------------------------------+';

        Fnd_File.put_line (Fnd_File.output, cv_line);
        Fnd_File.put_line (Fnd_File.output, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.output, cv_line);
  END output_end;

  -----------------------------------------------------------------
	--  Nom           : OUT_MSG
	--  Description   : procedure d'affichage des messages
	--
	--  PARAMETRES :
	--   p_message          texte a imprimer dans la sortie
	--
	-----------------------------------------------------------------
	PROCEDURE out_msg(p_message in varchar2) IS
	BEGIN
	  -- Ecriture dans le fichier de sortie
	  fnd_file.put_line(fnd_file.output, p_message);
	END out_msg;


    -----------------------------------------------------------------
    --  Nom           : LOG_MSG
    --  Description   : procedure d'affichage des messages
    --
    --  PARAMETRES :
    --   p_message      texte a imprimer dans le log
    --
    -----------------------------------------------------------------
    PROCEDURE log_msg(p_message in varchar2) IS
        l_message VARCHAR2(1000);
    BEGIN

        l_message := SUBSTR(p_message, 1, 1000);

        IF (l_message IS NULL) THEN
            l_message := TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
        END IF;

        fnd_file.put_line(fnd_file.LOG, l_message);
    END log_msg;
	
-- -----------------------------------------------------------------------------
     -- Nom              : check_value_set
     -- Description      : Vérifie de l'existence d'un jeu de valeurs et provoque une exception s'il n'existe pas
     -- -----------------------------------------------------------------------------
     procedure check_value_set(p_value_set_name in fnd_flex_value_sets.flex_value_set_name%type
								,p_errbuf    OUT      VARCHAR2,
								p_retcode   OUT      NUMBER) is
	 
        cursor cur_value_set(p_value_set_name in varchar2) is
        select ffvs.FLEX_VALUE_SET_ID,
               sum(case when ffv.ENABLED_FLAG='Y' and sysdate between trunc(nvl(ffv.START_DATE_ACTIVE, sysdate)) and trunc(nvl(ffv.END_DATE_ACTIVE, SYSDATE+1)) then 1 else 0 end) as active_lines,
               count(ffv.flex_value_id) as lines
        from fnd_flex_value_sets        ffvs
        left outer join fnd_flex_values ffv  on (ffvs.flex_value_set_id =  ffv.flex_value_set_id)
        where ffvs.flex_value_set_name = p_value_set_name
        group by ffvs.FLEX_VALUE_SET_ID;
        l_value_set cur_value_set%rowtype;
        l_ok boolean := false;
      begin
        open cur_value_set(p_value_set_name);
        fetch cur_value_set into l_value_set;
        if cur_value_set%notfound then
          log_msg('Le jeu de valeurs ' || p_value_set_name || ' n''existe pas.');
		  p_retcode := 2;
        elsif l_value_set.lines = 0 then
          log_msg('Aucune ligne n''est configurée dans le jeu de valeurs ' || p_value_set_name || '.');
		  p_retcode := 2;
        elsif l_value_set.active_lines = 0 then
          log_msg('Aucune valeur n''est active dans le jeu de valeurs ' || p_value_set_name || '.');
		  p_retcode := 2;
        else
          log_msg('Jeu de valeurs OK : ' || p_value_set_name);
          l_ok := true;
        end if;
        close cur_value_set;
        if not l_ok then
          p_retcode := 2;
        end if;
      end check_value_set;

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
				  P_period IN VARCHAR2,
				  P_region IN VARCHAR2,
				  Pv_file_name OUT VARCHAR2
                  )
  IS

    v_current_program_unit    VARCHAR2(30);
    v_step_program_error      VARCHAR2(1000);
    program_error             EXCEPTION;
    rec_param dka_parameters%ROWTYPE;
	v_num_fourn_cmd 		  VARCHAR2(30);
	v_record_id               NUMBER;
    v_HEADER_ID               NUMBER;
	v_UO_CMD 				  VARCHAR2(10);
	v_closed_date 			  VARCHAR2(10);
	v_auth_status 			  VARCHAR2(80);
	v_paiement_direct		  VARCHAR2(10); --EDB288B
	v_montant 		          VARCHAR2(30);
	v_type_four 			  VARCHAR2(100);
	v_note 				      VARCHAR2(240);
    v_existence               VARCHAR2(10);
	v_TF					  VARCHAR2(30);
	v_PF					  VARCHAR2(30);
	v_description			  VARCHAR2(300);
    v_count                   NUMBER;
    vn_nb_line                NUMBER;
    v_org_id_cmd              NUMBER;
	lv_csv_line varchar2(32000);
    is_found_rec boolean := false;

	fileHandler UTL_FILE.FILE_TYPE;
    filename    varchar2(70);

	CURSOR cur_city_2 IS
	SELECT         aia.ATTRIBUTE9 FOLIO, -- 1
                   SUBSTR(hou1.name,1,3) REGION, --3,
                   hou1.name UO_FACTURE,
                   SUBSTR(hou1.name,4,7) CODE_SOCIETE, --4,
                   (SELECT ffv.DESCRIPTION
                    FROM fnd_flex_value_sets ffvs ,
                         fnd_flex_values_vl     ffv  
                    where 
                    ffv.flex_value_set_id = ffvs.flex_value_set_id
                    AND flex_value_set_name = 'DAOPCCF_STE'
                    and ffv.flex_value = SUBSTR(hou1.name,4,7)) SOCIETE, --5
                    aia.INVOICE_ID INVOICE_ID ,--6
                    aia.INVOICE_NUM, --7
                    ass1.SEGMENT1 NUM_FOURN_FACT, --8
                    ass1.VENDOR_NAME FOURN_FACT, --9
                    apss.VENDOR_SITE_CODE Site_Frs, --10
                    aial.LINE_NUMBER Ligne_Facture, --11
                    aida.DISTRIBUTION_LINE_NUMBER Ligne_Ventilation, --12
                    replace (replace (to_number (aida.AMOUNT),'.',','),'-,','-0,') Montant, --13
                    aida.DESCRIPTION DESCRIPTION_LIGNE, --14

                    /*DECODE(PROJECT_TYPE , 'REFAC' , aida.ATTRIBUTE1
                                        , PAP.SEGMENT1) PF ,  --15       */        
					
					aida.PROJECT_ID PROJECT_ID,
					
					PAP.SEGMENT1 PROJECT_NUMBER,
					
                    PAT.TASK_NUMBER TASK_NUMBER,
					
					aida.ATTRIBUTE1 PF1,
					
					PROJECT_TYPE PROJECT_TYPE,
					
                    PAP.DESCRIPTION Project_description, --16

					aida.TASK_ID TASK_ID,
					
					aida.ATTRIBUTE7 TF1,
                    /*DECODE(PROJECT_TYPE , 'REFAC' , aida.ATTRIBUTE7
                                        , PAT.TASK_NUMBER) TF , --17*/

                    DECODE(regexp_count(aida.Description, ' '),0,aida.Description,
						  Substr(aida.Description, 1, instr(aida.Description, ' ') - 1)) NUM_CMD, --18

                   aia.ORG_ID ORG_CMD

			from   ap_invoices_all aia,
                   ap_invoice_distributions_All aida,
				   ap_invoice_lines_all aial,
				   hr_operating_units   hou1,
                   PA_PROJECTS_ALL          PAP,
                   PA_TASKS PAT,
				   ap_suppliers         ass1,
                   ap_supplier_sites_all apss

			 where aia.invoice_id = aial.invoice_id
               AND aida.invoice_id = aial.invoice_id
               AND aida.INVOICE_LINE_NUMBER = aial.LINE_NUMBER
			   AND aia.org_id = hou1.ORGANIZATION_ID
			   AND ass1.vendor_id = aia.vendor_id
               AND ass1.vendor_id = apss.vendor_id
               --
               AND aia.VENDOR_SITE_ID = apss.VENDOR_SITE_ID
               --
               AND aida.PROJECT_ID = PAP.PROJECT_ID 
               AND aida.TASK_ID = PAT.TASK_ID 
               AND PAT.PROJECT_ID = aida.PROJECT_ID
			   AND aia.ATTRIBUTE9 = 'CYF'
			   AND aida.PERIOD_NAME = P_period --'FEV-18'
			   AND aida.LINE_TYPE_LOOKUP_CODE = 'ITEM'
               --new
               AND SUBSTR(hou1.name,1,3) = P_region --'DRW'
               AND aida.ACCRUAL_POSTED_FLAG = 'Y'

			   ORDER BY aia.INVOICE_ID,aial.LINE_NUMBER,aida.DISTRIBUTION_LINE_NUMBER;



  BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début init');

        ----------------------------------
        -- Initialisation des variables --
        ----------------------------------
        p_errbuf  := NULL;
        p_retcode := 0;
        v_current_program_unit := 'INIT';


		-- directories
        dka_tools_pkg.check_directory(cv_directory); 

		-- Jeux de valeur
	   check_value_set('DAOPCCF_STE',p_errbuf,p_retcode);
	   IF p_retcode = 2
       THEN
          p_errbuf  := p_errbuf;
          p_retcode := p_retcode;
		  Fnd_File.put_line (Fnd_File.log, CHR(10)|| p_errbuf);
       END IF;

        ------------------------
        -- Variables globales --
        ------------------------ 

        g_user_id                      := fnd_global.user_id;
        g_login_id                     := fnd_global.login_id;
        g_request_id                   := fnd_global.conc_request_id;

		  log_msg(' 000 : Initialisation du nom du fichier / nombre enregistrements.');
          filename     := 'DKA_FACTURATION_COMMANDES_CITY_' || P_period || '_' || P_region || '_' ||
                          g_request_id || '.csv';
          Pv_file_name := filename;
		  vn_nb_line   := 0;


		log_msg(' 001 : Ouverture du fichier ' || filename || ' en mode écriture.');
        fileHandler := utl_file.fopen(cv_directory, filename, 'w');


        log_msg(' 003 : Création de l''entéte du fichier.');
        utl_file.put_line(fileHandler, 'FOLIO;Période;REGION;CODE_SOCIETE;SOCIETE;ID Facture;N° Facture;N° Fournisseur;Nom Fournisseur;Site Frs;N° Ligne Facture;N° Ligne Ventilation;Montant HT Ligne Facture;Description Ligne Facture;PF;DESCRIPTION PF;TF;Commande sur Ligne Fact;Commande Existe dans OA;UO Commande;Type de fournisseur de la Cde;Montant total de la Cde;Statut Commande;Commande en paiement directe;Date fermeture cde;Motif fermeture déf. cde;');


		FOR rec_city in cur_city_2 LOOP


			v_UO_CMD := NULL;
			v_closed_date := NULL;
			v_auth_status := NULL;
			v_paiement_direct := NULL;
			v_montant := NULL;
			v_type_four := NULL;
			v_note 	:= NULL;
			
			v_PF := NULL;
			v_TF := NULL;
			v_description := NULL;
			
			log_msg('BEFORE REFAC');
			log_msg('TYPE : ' || rec_city.PROJECT_TYPE);
			
			
			IF rec_city.PROJECT_TYPE = 'REFAC' THEN
			
			log_msg('TYPE REFAC');
			
			BEGIN
				
				SELECT SEGMENT1 , DESCRIPTION
				INTO v_PF , v_description
				from PA_PROJECTS_ALL 
				where project_id = rec_city.PF1;
				
				EXCEPTION
				WHEN OTHERS THEN
				log_msg('PROJECT REFAC not found');
				END;
				
				BEGIN
				
				SELECT TASK_NUMBER 
				INTO v_TF
				from PA_TASKS 
				where TASK_ID = rec_city.TF1;
				
				EXCEPTION
				WHEN OTHERS THEN
				log_msg('TASK REFAC not found');
				END;
			
			ELSE
			
				v_PF := rec_city.PROJECT_NUMBER;
				v_TF := rec_city.TASK_NUMBER;
				v_description := rec_city.Project_description;
				/*log_msg('TYPE NOT REFAC');
				v_PF := nvl(rec_city.PF1,'pf1');
				v_TF := nvl(rec_city.TF1,'tf1');*/
			
			END IF;
			
			/*log_msg('v_PF : ' || v_PF);
			log_msg('v_TF : ' || v_TF);
			
			log_msg('rec_city.ATTRIBUTE1 : ' || rec_city.PF1);
			log_msg('rec_city.ATTRIBUTE7 : ' || rec_city.TF1);*/
			
			BEGIN
				SELECT PO_HEADER_ID PHA
				INTO v_HEADER_ID 
                FROM PO_HEADERS_ALL PHA , hr_operating_units hou
				WHERE PHA.SEGMENT1 = rec_city.NUM_CMD
                AND hou.organization_id = PHA.ORG_ID
                AND hou.name = rec_city.UO_FACTURE;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                log_msg('001 : ' || SQLERRM);
                v_HEADER_ID := 0;

			END;

			IF v_HEADER_ID <> 0 THEN
				v_existence := 'OUI';
			ELSE	
				v_existence := 'NON';
			END IF;

            log_msg('v_existence : ' || v_existence);

			IF v_existence = 'OUI' THEN
			BEGIN
				SELECT hou.name , to_char(PHA.CLOSED_DATE,'DD/MM/YYYY') , replace(replace (to_number (SUM(NVL((pla.unit_price * pla.quantity),0))),'.',','),'-,','-0,')
				INTO v_UO_CMD , v_closed_date  , v_montant
				FROM PO_HEADERS_ALL PHA , PO_LINES_ALL pla , HR_OPERATING_UNITS hou
				where hou.organization_id = PHA.ORG_ID
                AND pla.po_header_id = pha.po_header_id
				AND PHA.PO_HEADER_ID = v_HEADER_ID
                GROUP BY hou.name , PHA.CLOSED_DATE;
                EXCEPTION
                WHEN OTHERS THEN
                log_msg('002');
			END;

			BEGIN
				SELECT flv.meaning 
				INTO v_type_four
                FROM PO_HEADERS_ALL PHA  , po_vendors pv , fnd_lookup_values_vl flv
                WHERE PHA.VENDOR_ID = PV.VENDOR_ID
                AND PV.VENDOR_TYPE_LOOKUP_CODE = flv.lookup_code
                AND flv.lookup_type = 'VENDOR TYPE'
                AND flv.enabled_flag = 'Y'
                AND PHA.PO_HEADER_ID = v_HEADER_ID;
                EXCEPTION
                WHEN OTHERS THEN
                log_msg('003');
			END;

            ----------
            /*BEGIN
				SELECT flv.meaning 
				INTO v_auth_status
                FROM PO_HEADERS_ALL PHA , fnd_lookup_values_vl flv
                WHERE PHA.AUTHORIZATION_STATUS = flv.lookup_code
                AND flv.lookup_type = 'DOCUMENT STATE'
                AND flv.enabled_flag = 'Y'
                AND PHA.PO_HEADER_ID = v_HEADER_ID;
                EXCEPTION
                WHEN OTHERS THEN
                log_msg('003 - meaning');
                v_auth_status := NULL;
			END;*/
			
			BEGIN
				SELECT DECODE(PHA.AUTHORIZATION_STATUS,'APPROVED', 
						                               DECODE(PHA.CANCEL_FLAG ,'Y','Annulé', flv.meaning ),
													   'Non approuvé'),
						PHA.ATTRIBUTE13
							  
				INTO v_auth_status, v_paiement_direct --EDB288B
                FROM PO_HEADERS_ALL PHA , fnd_lookup_values_vl flv
                WHERE NVL(PHA.closed_code,'OPEN')= flv.lookup_code
                AND flv.lookup_type = 'DOCUMENT STATE'
                AND flv.enabled_flag = 'Y'
                AND PHA.PO_HEADER_ID = v_HEADER_ID;
				
                EXCEPTION
                WHEN OTHERS THEN
                log_msg('003 - meaning');
                v_auth_status := NULL;
				v_paiement_direct := NULL;
			END;

			BEGIN
				select poah.note
				INTO v_note
                from po_action_history poah,  po_headers_all pohead 
                where poah.object_id = pohead.po_header_id 
                AND poah.ACTION_CODE = 'FINALLY CLOSE'
                AND poah.object_sub_type_code = 'STANDARD'
                and pohead.PO_HEADER_ID = v_HEADER_ID
                order by poah.last_update_date desc
                FETCH FIRST 1 ROWS ONLY;
                --and substr(poah.object_type_code,1,3) = 'PO' 
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                log_msg('004 ' || 'Pas de note');
				v_note := NULL;
			END;
            ELSIF v_existence = 'NON' THEN

            v_UO_CMD := NULL;
			v_closed_date := NULL;
			v_auth_status := NULL;
			v_paiement_direct := NULL;
			v_montant := NULL;
			v_type_four := NULL;
			v_note 	:= NULL;

			END IF;

			IF v_auth_status NOT IN ('Fermé','Fermé définitivement') THEN
				v_closed_date := NULL;
			END IF;
			
			IF v_auth_status NOT IN ('Fermé définitivement') THEN
				v_note := NULL;
			END IF;
			
			lv_csv_line := rec_city.FOLIO || ';' || --FOLIO
                       P_period || ';' || --PERIODE
                       rec_city.REGION || ';' || --REGION
                       rec_city.CODE_SOCIETE || ';' || --CODE_SOCIETE
                       rec_city.SOCIETE || ';' || --SOCIETE
                       rec_city.INVOICE_ID || ';' || --INVOICE_ID
                       rec_city.INVOICE_NUM || ';' || --INVOICE_NUM
                       rec_city.NUM_FOURN_FACT || ';' || --NUM_FOURN_FACT
                       rec_city.FOURN_FACT || ';' || --FOURN_FACT.
                       rec_city.Site_Frs || ';' || --Site_Frs
                       rec_city.Ligne_Facture || ';' || --Ligne_Facture
                       rec_city.Ligne_Ventilation || ';' || --Ligne_Ventilation
                       rec_city.Montant || ';' || --Montant
                       rec_city.DESCRIPTION_LIGNE || ';' || --DESCRIPTION_LIGNE
                       v_PF || ';' || --PF
                       v_description || ';' || --Project_description
                       v_TF || ';' || --TF
					   rec_city.NUM_CMD || ';' || --NUM_CMD
                       v_existence || ';' || --EXISTENCE DANS OA
					   v_UO_CMD || ';' || --UO_CMD
					   v_type_four || ';' || --TYPE_FOURNISSEUR_CMD
					   v_montant || ';' || --MONTANT_CMD
					   v_auth_status || ';' || --STATUT_CMD
					   v_paiement_direct || ';' || --Paiement direct --EDB288B ARA
					   v_closed_date || ';' || --DATE_FERMETURE
                       v_note || ';'; --NOTE_FERMETURE

		   utl_file.put_line(fileHandler, lv_csv_line);

           vn_nb_line   := vn_nb_line + 1;

		END LOOP;
		log_msg(' 005 : nb lignes extraites : ' || vn_nb_line);
        IF vn_nb_line = 0 THEN
            utl_file.fclose(fileHandler); 
        END IF;
        log_msg(' 005 : Fermeture du fichier.');
        IF utl_file.is_open(fileHandler) THEN
			utl_file.fclose(fileHandler); 
		END IF;
        log_msg(' 999 : Fin Normale.');
    EXCEPTION
        WHEN program_error THEN
             fnd_file.put_line(fnd_file.log, 'ERREUR : ' || v_step_program_error);
             RAISE; 
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'INIT : ' ||SQLERRM;
  END init;

  ----------------------------------------------------------------------------
    --  Nom           : write_boundary
    --  Description   : Procédure
    --
    --  PARAMETRES :
    ----------------------------------------------------------------------------
    PROCEDURE write_boundary(conn IN OUT NOCOPY utl_smtp.connection,
                             last IN BOOLEAN DEFAULT FALSE) IS
    BEGIN
        IF (last) THEN
            utl_smtp.write_data(conn, LAST_BOUNDARY);
        ELSE
            utl_smtp.write_data(conn, FIRST_BOUNDARY);
        END IF;
    END write_boundary;

    ----------------------------------------------------------------------------
    --  Nom           : begin_attachment
    --  Description   : Procédure
    --
    --  PARAMETRES :
    ----------------------------------------------------------------------------
    PROCEDURE begin_attachment(conn         IN OUT NOCOPY utl_smtp.connection,
                               mime_type    IN VARCHAR2 DEFAULT 'text/plain',
                               inline       IN BOOLEAN DEFAULT TRUE,
                               filename     IN VARCHAR2 DEFAULT NULL,
                               transfer_enc IN VARCHAR2 DEFAULT NULL) IS
    BEGIN
        write_boundary(conn);
        utl_smtp.write_raw_data(conn,
                                utl_raw.cast_to_raw('Content-Type: ' ||
                                                    mime_type ||
                                                    utl_tcp.CRLF));
        IF (filename IS NOT NULL) THEN
            IF (inline) THEN
                utl_smtp.write_raw_data(conn,
                                        utl_raw.cast_to_raw('Content-Disposition: ' ||
                                                            'inline; filename="' ||
                                                            filename || '"' ||
                                                            utl_tcp.CRLF));
            ELSE
                utl_smtp.write_raw_data(conn,
                                        utl_raw.cast_to_raw('Content-Disposition: ' ||
                                                            'attachment; filename="' ||
                                                            filename || '"' ||
                                                            utl_tcp.CRLF));
            END IF;
        END IF;
        IF (transfer_enc IS NOT NULL) THEN
            utl_smtp.write_raw_data(conn,
                                    utl_raw.cast_to_raw('Content-Transfer-Encoding: ' ||
                                                        transfer_enc ||
                                                        utl_tcp.CRLF));
        END IF;
        utl_smtp.write_data(conn, utl_tcp.CRLF);
    END begin_attachment;

	 ----------------------------------------------------------------------------
    --  Nom           : end_attachment
    --  Description   : Procédure
    --
    --  PARAMETRES :
    ----------------------------------------------------------------------------
    PROCEDURE end_attachment(conn IN OUT NOCOPY utl_smtp.connection,
                             last IN BOOLEAN DEFAULT FALSE) IS
    BEGIN
        utl_smtp.write_data(conn, utl_tcp.CRLF || utl_tcp.CRLF);
        IF (last) THEN
            write_boundary(conn, last);
        END IF;
    END end_attachment;




	  -----------------------------------------------------------------
  --  Nom           : SEND_MSG
  --  Description   : procédure d'envoi de mail avec piéce jointe
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
   -----------------------------------------------------------------

  PROCEDURE SEND_MSG(p_tab_to      liste_destinataires,
                     p_tab_cc      liste_destinataires,
                     p_from        IN VARCHAR2,
                     p_subject     IN VARCHAR2,
					 P_period	   IN VARCHAR2,
					 P_region	   IN VARCHAR2,
                     p_text_msg    IN VARCHAR2 DEFAULT NULL,
                     p_attach_name IN VARCHAR2 DEFAULT NULL,
                     p_attach_mime IN VARCHAR2 DEFAULT NULL,
                     p_smtp_host   IN VARCHAR2,
                     p_smtp_port   IN NUMBER DEFAULT 25 ) AS
    l_mail_conn UTL_SMTP.connection;
    l_boundary  VARCHAR2(50) := '----=*#abc1234321cba#*=';

    fil             BFILE; -- SELOO
    v_length        integer := 0; -- SELOO
    k               integer := 1;
    v_raw           raw(57);
    v_buffer_size   integer := 57;
    V_TYPE_CAMPAGNE varchar(50);
    p_to            VARCHAR2(30000);
    p_cc            VARCHAR2(30000);
  BEGIN


    l_mail_conn := UTL_SMTP.open_connection(p_smtp_host, p_smtp_port);
    UTL_SMTP.helo(l_mail_conn, p_smtp_host);
    UTL_SMTP.mail(l_mail_conn, p_from);

    fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '     > Mail : Chargement des destinataires directs');

    -- Ajout des destinataires directs
    FOR i in p_tab_to.FIRST .. p_tab_to.LAST LOOP
      UTL_SMTP.rcpt(l_mail_conn, p_tab_to(i));
      IF (i = 1) THEN
        p_to := p_tab_to(i);
      ELSE
        p_to := p_to || ';' || p_tab_to(i);
      END IF;

    END LOOP;

    fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '     > Mail : Chargement des destinataires en copie');

    IF (p_tab_cc(1) != 'INIT') THEN
      -- Ajout des destinataires en copie
      FOR i in p_tab_cc.FIRST .. p_tab_cc.LAST LOOP
        UTL_SMTP.rcpt(l_mail_conn, p_tab_cc(i));
        IF (i = 1) THEN
          p_cc := p_tab_cc(i);
        ELSE
          p_cc := p_cc || ';' || p_tab_cc(i);
        END IF;
      END LOOP;
    ELSE
      fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '     > Mail : Pas de destinataires en copie');
    END IF;

    fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '     > Mail : Alimentation du mail');

    UTL_SMTP.open_data(l_mail_conn);

    UTL_SMTP.write_data(l_mail_conn,
                        'Date: ' ||
                        TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') ||
                        UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to || UTL_TCP.crlf);

    IF (p_cc IS NOT NULL) THEN
      UTL_SMTP.write_data(l_mail_conn, 'CC: ' || p_cc || UTL_TCP.crlf);
    END IF;
    UTL_SMTP.write_data(l_mail_conn, 'From: ' || p_from || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 
                        'Subject: ' || REPLACE(utl_encode.MIMEHEADER_ENCODE(p_subject,'utf8'),CHR(13)||CHR(10),'') || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn,
                        'Reply-To: ' || p_from || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'MIME-Version: 1.0' || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn,
                        'Content-Type: multipart/mixed; boundary="' ||
                        l_boundary || '"' || UTL_TCP.crlf || UTL_TCP.crlf);

    IF p_text_msg IS NOT NULL THEN
      UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Type: text/plain; charset="iso-8859-1"' ||
                          UTL_TCP.crlf || UTL_TCP.crlf);

      utl_smtp.write_raw_data(l_mail_conn,utl_raw.cast_to_raw(p_text_msg));
      UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
    END IF;

    fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '     > Mail : Alimentation de la piéce jointe');

    IF p_attach_name IS NOT NULL THEN
    --IF p_attach_name = 1 THEN -- test
      UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Type: ' || p_attach_mime || '; name="' ||
                          'DKA_FACTURATION_COMMANDES_CITY_' || P_period || '_' || P_region || '_' ||
                          g_request_id || '.csv' || '"' ||
                          UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Transfer-Encoding: base64' ||
                          UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Disposition: attachment; filename="' ||
                          'DKA_FACTURATION_COMMANDES_CITY_' || P_period || '_' || P_region || '_' ||
                          g_request_id || '.csv' || '"' ||
                          UTL_TCP.crlf || UTL_TCP.crlf);

      BEGIN
        fil := bfilename(p_attach_mime, p_attach_name);
        dbms_lob.fileopen(fil, dbms_lob.file_readonly);
      EXCEPTION
        WHEN OTHERS THEN
          null;
      END;
      v_length := dbms_lob.getlength(fil);

      while k < v_length loop
        dbms_lob.read(fil, v_buffer_size, k, v_raw);
        UTL_SMTP.write_data(l_mail_conn,
                            UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(v_raw)));
        utl_smtp.write_data(l_mail_conn, utl_tcp.crlf);
        k := k + v_buffer_size;
      end loop;

      dbms_lob.fileclose(fil);

    END IF;

    UTL_SMTP.write_data(l_mail_conn,
                        '--' || l_boundary || '--' || UTL_TCP.crlf);
    UTL_SMTP.close_data(l_mail_conn);

    UTL_SMTP.quit(l_mail_conn);
  END SEND_MSG;


	  -----------------------------------------------------------------
  --  Nom           : Main
  --  Description   : procédure principale du traitement
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER

  -----------------------------------------------------------------
PROCEDURE main(Pv_Errbuf    IN OUT VARCHAR2,
                   Pn_Retcode   IN OUT NUMBER,
                   P_period IN VARCHAR2,
                   P_region IN VARCHAR2
                   )
IS
  v_errbuf                    VARCHAR2(2500);
  v_retcode                   NUMBER;
  Erreur_Programme            EXCEPTION;
  Erreur_mail                 EXCEPTION;
  cv_line                     VARCHAR2 (100);
  v_current_program_unit      VARCHAR2(30);
  vn_nb_line                  NUMBER;
  vv_file_name                VARCHAR2(70);
  vv_adresses    			  VARCHAR2(32000);
  vv_adresses_cc  			  VARCHAR2(32000);
  vt_adr_to     liste_destinataires;
    vt_adr_cc     liste_destinataires;
    vn_cpt        NUMBER;
    vn_cptt        NUMBER;
    rec_param dka_parameters%ROWTYPE;

  CURSOR c_liste_destinataire IS
               SELECT ffv.flex_value adresse
                 from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
                where ffvs.flex_value_set_id = ffv.flex_value_set_id
                and ffvs.flex_value_set_name = 'DKA_MAIL_SPOCITY'
                  AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                  AND ffv.enabled_flag = 'Y'
                  AND ffv.description = 'DESTINATAIRE';

		  CURSOR c_liste_destinataire_CC IS
               SELECT ffv.flex_value adresse
                 from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
                where ffvs.flex_value_set_id = ffv.flex_value_set_id
                and ffvs.flex_value_set_name = 'DKA_MAIL_SPOCITY'
                  AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                  AND ffv.enabled_flag = 'Y'
                  AND ffv.description = 'COPIE';

BEGIN


      Output_Header;


	  init (v_errbuf,v_retcode,P_period,P_region,vv_file_name);
	  IF v_retcode = 2 
      THEN
          Pv_Errbuf  := v_errbuf;
          Pn_Retcode := v_retcode;
		  Fnd_File.put_line (Fnd_File.OUTPUT, 'ECHEC : Le fichier n''a pas pu être généré.'); 
		  Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10) || 'Voir le journal du traitement pour avoir plus de détail sur l''anomalie rencontrée.');
		  RAISE Erreur_Programme;
      END IF;

      log_msg('Nom Fichier : ' || vv_file_name);

	  check_value_set('DKA_MAIL_SPOCITY',v_errbuf,v_retcode);
	  IF v_retcode = 2
      THEN
          Pv_Errbuf  := v_errbuf;
          Pn_Retcode := v_retcode;
		  Fnd_File.put_line (Fnd_File.log, CHR(10)|| Pv_Errbuf);
          RAISE Erreur_mail;
      END IF;
	  
	  Dka_Tools_Pkg.get_parameter('SPOCDE_CITY',
                                    'SMTP_CONNECTION',
                                    rec_param, 
                                    Pv_Errbuf,
                                    Pn_Retcode);
        gv_conn := rec_param.varchar2_value;
		IF gv_conn IS NULL THEN
            Fnd_File.put_line (Fnd_File.log, CHR(10)|| 'ECHEC : erreur concernant la connexion SMTP.');
            RAISE Erreur_mail;
        END IF;


        g_step := 'ENVOI_AVEC_FICHIER 000 : DEBUT';
        log_msg(g_step);
        g_step := 'ENVOI_AVEC_FICHIER 001 : RECHERCHE DE L''OBJET DU MAIL.';
        log_msg(g_step);
        gv_objet := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_SPOCMD_CITY_OBJECT',
											   'PERIODE' , P_period ,
											   'REGION' , P_region
                                              );
        IF gv_objet IS NULL THEN
          Fnd_File.put_line (Fnd_File.log, CHR(10)|| 'ECHEC : Pas d''objet du mail.');
          RAISE Erreur_mail;
        END IF;
        g_step   := 'ENVOI_AVEC_FICHIER 002 : RECHERCHE DU CORPS DU MAIL.';
        log_msg(g_step);
        gv_corps := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_SPOCMD_CITY_CORPS',
                                              'PERIODE' , P_period ,
											  'REGION' , P_region);

	    IF gv_corps IS NULL THEN
            Fnd_File.put_line (Fnd_File.log, CHR(10)|| 'ECHEC : Pas de corps du mail.');
          RAISE Erreur_mail;
        END IF;

	  vn_cpt := 0;
    vt_adr_to(1) := 'INIT';

    vv_adresses := NULL;
	vv_adresses_cc := NULL;

    fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Récupération des destinataires directs');
    -- Alimentation du tableau des destinataires directs
    FOR CUR_ADR_TO IN c_liste_destinataire LOOP
      vn_cpt := vn_cpt + 1;
      vt_adr_to(vn_cpt) := CUR_ADR_to.adresse;
	  vv_adresses := vv_adresses || CUR_ADR_to.adresse || ',';  
      --fnd_file.put_line(fnd_file.LOG, '- Adresses principaux : ' || vv_adresses);
    END LOOP;

    IF vv_adresses IS NULL THEN
        
          Fnd_File.put_line (Fnd_File.log, CHR(10)|| 'Aucune valeur n''est active dans le jeu de valeurs DKA_MAIL_SPOCITY');
          RAISE Erreur_mail;
    ELSE

    vn_cptt := 0;
    vt_adr_cc(1) := 'INIT';

    FOR CUR_ADR_TOO IN c_liste_destinataire_CC LOOP
      vn_cptt := vn_cptt + 1;
      vt_adr_cc(vn_cptt) := CUR_ADR_TOO.adresse;
	  vv_adresses_cc := vv_adresses_cc || CUR_ADR_TOO.adresse || ',';
	  
    END LOOP;
	
	
	SEND_MSG(p_tab_to      => vt_adr_to,
               p_tab_cc      => vt_adr_cc,
               p_from        => 'no-reply@dalkia.fr',
               p_subject     => gv_objet,
			   P_period      => P_period,
			   P_region      => P_region,
               p_text_msg    => gv_corps,
               p_attach_name => vv_file_name,
               p_attach_mime => 'DKA_OUT_DIR',
               p_smtp_host   => gv_conn);

    Fnd_File.put (Fnd_File.OUTPUT, CHR(10)|| 'SUCCES : Le mail a été envoyé avec succès aux adresses suivantes : ');
          /*FOR p IN 1..vn_cpt LOOP
		  Fnd_File.put (Fnd_File.OUTPUT, vt_adr_to(p) || ', ');
          END LOOP;*/
		  --log_msg('adresses : ' || vv_adresses || vv_adresses_cc);
		  log_msg('adresses : ' || vv_adresses || vv_adresses_cc);
		  Fnd_File.put (Fnd_File.OUTPUT, SUBSTR(vv_adresses || vv_adresses_cc, 0, LENGTH(vv_adresses || vv_adresses_cc) - 1));
          Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10) || CHR(10));
		  
		  Fnd_File.put_line (Fnd_File.OUTPUT, 'Fin normale du traitement.' || CHR(10));
		  
    END IF;


      output_end;
	  EXCEPTION
        WHEN Erreur_mail THEN
            Pn_Retcode   := 1;
            Fnd_File.put_line (Fnd_File.OUTPUT, 'ECHEC : Le mail n''a pas pu être envoyé.');
			Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10) || 'Voir le journal du traitement pour avoir plus de détail sur l''anomalie rencontrée.');
            --Fnd_File.put_line (Fnd_File.log, CHR(10)|| 'ECHEC : Pas de destinataires.');
            output_end;
        WHEN Erreur_Programme THEN
            Pn_Retcode   := 2;
            Pv_Errbuf    := v_errbuf;
            Fnd_File.put_line (Fnd_File.LOG, Pv_Errbuf);
            Fnd_File.put_line (Fnd_File.LOG, CHR(10)||Pv_Errbuf);
            output_end;
END main;

END DKA_SPOCMDMAIL_CITY_PKG;

/
SHOW ERRORS;
EXIT