create or replace PACKAGE BODY DKA_SPODAMAIL_PKG AS
  ---------------------------------------------------------------------------------------------------------------
  -- CAP GEMINI ERNST AND YOUNG
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SPODAMAIL_PKG.pkb
  -- DESCRIPTION       : Identification des DA saisies dans Oracle sur un périmètre fermé
  --
  --- AUTEUR           : SALOUA HAHIOUI
  --- DATE DE CREATION : 11/09/2020
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  ---------------------------------------------------------------------------------------------------------------
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  g_nom_traitement varchar2(100) := 'DKA : Identification des DA saisies dans Oracle sur un périmètre fermé';
  cv_package_name   CONSTANT VARCHAR2(30) := 'DKA_SPODAMAIL_PKG';
  K_SEPARATOR       CONSTANT VARCHAR2(2) := ';';
  K_DIRECTORY       CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';
  K_FATAL_ERROR_NUM CONSTANT NUMBER := -20012;
  g_request_id                  NUMBER        := fnd_global.conc_request_id;
  TYPE liste_destinataires IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
  e_dest_error EXCEPTION;
  e_etat_error EXCEPTION;

  PROCEDURE output_header is
  BEGIN
  
    Dka_Tools_Pkg.Put_Outdebug_Message('+---------------------------------------------------------------------------------------------------------------------+');
    Dka_Tools_Pkg.Put_Outdebug_Message('    Traitement « ' ||g_nom_traitement || '»');
	Dka_Tools_Pkg.Put_Outdebug_Message('    Traitement n°       :' ||g_request_id );
    Dka_Tools_Pkg.Put_Outdebug_Message('    Programme lancé le  : ' ||
                                       to_char(SYSDATE,
                                               'DD-MON-YYYY HH24:MI:SS'));
    Dka_Tools_Pkg.Put_Outdebug_Message('+---------------------------------------------------------------------------------------------------------------------+');
    fnd_file.put_line(fnd_file.OUTPUT, ' ');
  
  END;
    ------------------------------------------------------------------------------------
  --  Nom           : p_put_debug_message
  --  Description   : Ecrit dans le journal du traitement
  --
  --  PARAMETRES    : Message à afficher dans le journal
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_put_debug_message(p_message IN VARCHAR2) IS
  
  BEGIN
  
    dbms_output.put_line(p_message);
  
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

  PROCEDURE output_end IS
    cv_line VARCHAR2(100);
  BEGIN
    cv_line := '+-------------------------------------------------------------------------+';
     Fnd_File.put_line(Fnd_File.output, cv_line);
    Fnd_File.put_line(Fnd_File.output,
                      'Programme terminé le : ' ||
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') );
    Fnd_File.put_line(Fnd_File.output, cv_line);
  END output_end;
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
  
    IF cur_directory%NOTFOUND THEN
      CLOSE cur_directory;
      p_validate(FALSE,
                 'Le directory ' || p_directory_name || ' n''existe pas.');
    END IF;
  
    CLOSE cur_directory;
  
   
  
  END p_check_directory;


  ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data
  --  Description   : Extrait des DA saisies dans Oracle sur un périmètre fermé 
  --
  --  PARAMETRES    :
  --  p_directory_name        Nom du directory
  --  p_file_name             Nom du fichier
  --  p_nb_lignes             Nombre de lignes inserees
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data(p_directory_name    IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name         IN VARCHAR2,
                           p_nb_lignes_da     IN OUT NUMBER) IS
  
    l_file UTL_FILE.file_type;
    vn_nb_lignes_da  number := 0;
    vv_ligne         VARCHAR2(4000);
  CURSOR cur_DA
   IS
    select distinct hou.name  UO, 
		   prh.segment1 NUM_MVT,
	       pv.segment1 NUM_FOURNISSEUR,
		   prl.suggested_vendor_name  NOM_FOURNISSEUR, 
           prl.line_num ||'.'|| prd.DISTRIBUTION_NUM as NUM_LIGNE,
           REPLACE(REPLACE(REPLACE(prl.item_description,';' , '-'), CHR(13), ' '), CHR(10), ' ')   DESCRIPTION_ARTICLE,
           prh.authorization_status STATUT,
           REPLACE((prl.unit_price * prl.quantity), '.',',')MONTANT,
           prl.suggested_vendor_location SITE_FOURNISSEUR,
           gcc.segment6 CENTRE_FINANCE,
		   DSTL.RETURN_VALUE CENTRE_OPERATIONNEL,
		   DSTL.START_DATE DATE_DEPLOIEMENT_CO,
		   ppx.full_name DEMANDEUR,
		   fu.user_name UTILISATEUR_ORACLE,
		   fu.email_address EMAIL_UTILISATEUR,
		   prd.creation_date DATE_CREATION
		   
	  from po_requisition_headers_all prh,
		   po_requisition_lines_all   prl,
		   po_req_distributions_all   prd,
		   gl_code_combinations_kfv   gcc,
           hr_operating_units         hou,
		   DKA_STRANSCO_LINES DSTL,
		   DKA_STRANSCO_HEADERS DSTH,
		   per_all_people_f     ppx,
		   fnd_user             fu,
		   po_vendors pv
	 where prh.requisition_header_id=prl.requisition_header_id
	    and prl.requisition_line_id=prd.requisition_line_id
	    and gcc.code_combination_id = prd.code_combination_id
        and hou.organization_id     = prh.org_id
		AND ppx.person_id(+)= prh.preparer_id
		and pv.vendor_id(+)= prl.vendor_id 
		and fu.user_id= prd.created_by
	    and prh.authorization_status !='CANCELLED'
	    and nvl(prl.cancel_flag, 'N') = 'N'                        
	    and prl.line_location_id is null
	    and gcc.segment6 = DSTL.param1_value
	    AND DSTL.SET_ID = DSTH.SET_ID
	    AND DSTH.SET_NAME LIKE 'DKA_CO_MIGR_IVALUA'
	    AND DSTL.ENABLE = 'Y'
	    AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
	    AND prd.creation_date >= DSTL.START_DATE
		ORDER BY gcc.segment6,  
               hou.name, 
               NUM_MVT, 
               NUM_LIGNE asc
      
	    
		;
 
  
    
  
  BEGIN
  
    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '    > Extract data : ' || 'Début');
  
    -- Verification de l'existence du directory
    p_check_directory(p_directory_name);
  
    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, p_file_name, 'W');
  
    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                        '    > Extract data : ' || 'le fichier ' ||
                        p_directory_name || '/' || p_file_name ||
                        ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
    END IF;
    vv_ligne := 'UO'                  || K_SEPARATOR || 
	            'NUM_MVT'             || K_SEPARATOR || 
				'NUM_FOURNISSEUR'     || K_SEPARATOR || 
				'NOM_FOURNISSEUR'     || K_SEPARATOR || 
				'SITE_FOURNISSEUR'    || K_SEPARATOR ||
                'STATUT'              || K_SEPARATOR ||
				'NUM_LIGNE'           || K_SEPARATOR || 
				'DESCRIPTION_ARTICLE' || K_SEPARATOR ||
				'MONTANT'             || K_SEPARATOR ||
                'CENTRE_FINANCE'      || K_SEPARATOR ||
                'CENTRE_OPERATIONNEL' || K_SEPARATOR ||
                'DATE_DEPLOIEMENT_CO' || K_SEPARATOR ||
                'DEMANDEUR'           || K_SEPARATOR ||
				'UTILISATEUR_ORACLE'  || K_SEPARATOR ||
                'EMAIL_UTILISATEUR'   || K_SEPARATOR ||
                'DATE_CREATION'       || K_SEPARATOR 
				;
    
      -- Ecrit dans le fichier
      utl_file.put_line(l_file, vv_ligne);
    -- Extraction des donnees
    FOR r_DA in cur_DA LOOP
    
      vv_ligne := r_DA.UO                || K_SEPARATOR || 
	            r_DA.NUM_MVT             || K_SEPARATOR || 
				r_DA.NUM_FOURNISSEUR     || K_SEPARATOR || 
				r_DA.NOM_FOURNISSEUR     || K_SEPARATOR || 
				r_DA.SITE_FOURNISSEUR    || K_SEPARATOR ||
                r_DA.STATUT              || K_SEPARATOR ||
				r_DA.NUM_LIGNE           || K_SEPARATOR || 
				r_DA.DESCRIPTION_ARTICLE || K_SEPARATOR ||
				r_DA.MONTANT             || K_SEPARATOR ||
                r_DA.CENTRE_FINANCE      || K_SEPARATOR ||
                r_DA.CENTRE_OPERATIONNEL || K_SEPARATOR ||
                r_DA.DATE_DEPLOIEMENT_CO || K_SEPARATOR ||
                r_DA.DEMANDEUR           || K_SEPARATOR ||
				r_DA.UTILISATEUR_ORACLE  || K_SEPARATOR ||
                r_DA.EMAIL_UTILISATEUR   || K_SEPARATOR ||
                r_DA.DATE_CREATION       || K_SEPARATOR 
				;
    
      -- Ecrit dans le fichier
      utl_file.put_line(l_file, vv_ligne);
    
      -- Maj des compteurs
      vn_nb_lignes_da := vn_nb_lignes_da + 1;
    
    END LOOP;
  
    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '    > Extract data : ' ||
                      'Export des DA saisies dans Oracle sur un périmètre fermé');
  
   
    
  
  
    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '    > Extract data : ' || 'Fermeture du fichier');
  
    -- Fermeture du fichier
    UTL_FILE.FCLOSE(l_file);
  
    p_nb_lignes_da  := vn_nb_lignes_da;
  
  EXCEPTION
    WHEN OTHERS THEN
      p_validate(FALSE,
                 'Probleme dans la procedure p_extract_data (' || SQLERRM || ')');
    
  END p_extract_data;
  
  
  -----------------------------------------------------------------
  --  Nom           : SEND_MSG
  --  Description   : procédure d'envoi de mail avec pièce jointe
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  --   vb_boucle        IN         BOOLEAN
  -----------------------------------------------------------------

  PROCEDURE SEND_MSG(p_tab_to      liste_destinataires,
                     p_tab_cc      liste_destinataires,
                     p_from        IN VARCHAR2,
                     p_subject     IN VARCHAR2,
                     p_text_msg    IN VARCHAR2 DEFAULT NULL,
                     p_attach_name IN VARCHAR2 DEFAULT NULL,
                     p_attach_mime IN VARCHAR2 DEFAULT NULL,
                     p_smtp_host   IN VARCHAR2,
                     p_smtp_port   IN NUMBER DEFAULT 25) AS
    l_mail_conn UTL_SMTP.connection;
    l_boundary  VARCHAR2(50) := '----=*#abc1234321cba#*=';

    fil             BFILE; 
    v_length        integer := 0; 
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
                        'Subject: ' || p_subject || UTL_TCP.crlf);
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
    
      UTL_SMTP.write_data(l_mail_conn, p_text_msg);
      UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
    END IF;
  
    fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '     > Mail : Alimentation de la pièce jointe');
  
    IF p_attach_name IS NOT NULL THEN
      UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Type: ' || p_attach_mime || '; name="' ||
                          'DKA_DA_SUR_CO_IVALUA.CSV ' || '"' ||
                          UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Transfer-Encoding: base64' ||
                          UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Disposition: attachment; filename="' ||
                          'DKA_DA_SUR_CO_IVALUA.CSV ' || '"' ||
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

  --------------------------------------------------------------------------------------------------------------
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : procédure principale du traitement qui enchaînera l'ensemble
  --                  des autres procèdures.
  --
  --  PARAMETRES    : pv_errbuf              Entrée/Sortie    message d'erreur
  --                  pn_retcode             Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --        pv_p_payment_patch     Entrée
  --        pv_type_enregistrement Entrée   type_enregistrement  'C= lettre chèque',
  --              type_enregistrement  'B= LCR',
  --              type_enregistrement  'W =Virement',
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER)
  
   IS
    l_procedure VARCHAR2(100) := 'DKA : Identification des DA saisies dans Oracle sur un périmètre fermé';
    l_request_id       NUMBER;
    l_application_code VARCHAR2(50) := 'DKA';
    l_conc_program     VARCHAR2(50) := 'DKA_SSATIPOIDS_RDF';
    l_execute_code     BOOLEAN;
    l_req_interval     NUMBER := 30;
    l_req_max_wait     NUMBER := 999999;
    l_req_phase      VARCHAR2(255);
    l_req_status     VARCHAR2(255);
    l_req_dev_phase  VARCHAR2(255);
    l_req_dev_status VARCHAR2(255);
    l_req_message    VARCHAR2(255);
    vv_conn VARCHAR2(50);
    vt_adr_to     liste_destinataires;
    vt_adr_cc     liste_destinataires;
    vn_cpt        NUMBER;
	i             NUMBER;
    gv_expediteur VARCHAR2(50);
    rec_param     dka_parameters%ROWTYPE;
    l_layout        BOOLEAN;
    V_TYPE_CAMPAGNE VARCHAR2(50);
    lv_nom_fichier VARCHAR2(200);
	p_nb_lignes_da  NUMBER := 0;
   
    
    -- Récupération des destinataires directs
    CURSOR EXTR_ADR_TO IS
      SELECT ffv.flex_value AS ADR_DESTINATION
        FROM fnd_flex_values_tl  ffvt,
             fnd_flex_value_sets ffvs,
             fnd_flex_values     ffv
       WHERE ffv.flex_value_set_id = ffvs.flex_value_set_id
         AND ffvs.flex_value_set_name = 'DKA_MAIL_CTRL_MIGR_IVALUA'
         AND ffv.flex_value_id = ffvt.flex_value_id
         AND ffvt.LANGUAGE = USERENV('LANG')
         AND ffv.ENABLED_FLAG = 'Y'
         --AND ffv.ATTRIBUTE1 = 'Y'
         AND SYSDATE BETWEEN NVL(START_DATE_ACTIVE, SYSDATE) AND
             NVL(END_DATE_ACTIVE, SYSDATE);
  
    
  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''FRENCH''';
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS =''.,''';
   
    
    output_header;
     -- Construction du nom du fichier
    lv_nom_fichier := 'DKA_DA_SUR_CO_IVALUA.csv';
    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Nom fichier : ' || lv_nom_fichier);
      
    p_extract_data(K_DIRECTORY,
                   lv_nom_fichier,
                   p_nb_lignes_da );
				   
    fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'Récupération des informations SMTP');
  
    Dka_Tools_Pkg.get_parameter('SCTRLMODULE',
                                'SMTP_CONNECTION',
                                rec_param,
                                Pv_Errbuf,
                                Pn_Retcode);
    vv_conn := rec_param.varchar2_value;
  
    --   Dka_Tools_Pkg.get_parameter ('DKA_MAIL', 'EXPEDITEUR_MAIL', rec_param, pv_errbuf, pn_retcode);
    --   gv_expediteur := rec_param.varchar2_value;
  
    
  
    vn_cpt := 0;
	i :=0;
    vt_adr_to(1) := 'INIT';
  
    fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Récupération des destinataires directs');
    -- Alimentation du tableau des destinataires directs
    FOR CUR_ADR_TO IN EXTR_ADR_TO LOOP
      vn_cpt := vn_cpt + 1;
      
    END LOOP;
  
    -- Si pas de destinataire direct, on renvoie vers l'exception
    IF (vn_cpt = 0) THEN
      raise e_dest_error;
	ELSE 
	fnd_file.put_line(fnd_file.OUTPUT,
                      'SUCCES : Le mail a été envoyé avec succès aux adresses suivantes :');
	FOR CUR_ADR_TO IN EXTR_ADR_TO LOOP
       i := i+1;
	   vt_adr_to(i) := CUR_ADR_to.ADR_DESTINATION;
       fnd_file.put_line(fnd_file.OUTPUT, '- ' || vt_adr_to(i));
    END LOOP;			  
    END IF;
    vn_cpt := 0;
    vt_adr_cc(1) := 'INIT';
  
    fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Récupération des destinataires en copie');
    
    
      fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Procédure d''envoi du mail');
      SEND_MSG(p_tab_to      => vt_adr_to,
               p_tab_cc      => vt_adr_cc,
               p_from        => 'no-reply@dalkia.fr',
               p_subject     => ' HELIOS : DA saisies dans Oracle sur un périmètre fermé',
               p_text_msg    => 'Bonjour,' || CHR(13) || '' || CHR(13) ||
                                'Veuillez trouver ci-joint la liste des DA saisies dans Oracle sur un périmètre fermé.'||
                                CHR(13) || '' || CHR(13) || 'Cordialement,',
               p_attach_name =>  'DKA_DA_SUR_CO_IVALUA.csv',
               p_attach_mime => K_DIRECTORY,
               p_smtp_host   => vv_conn);
    
      fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Mail envoyé');
    
  
    IF pn_retcode = 2 THEN
      pv_errbuf := 'ATTENTION : Erreur bloquante : ' || pv_errbuf;
      
    ELSE
      pv_errbuf  := 'Fin normale du traitement - Aucun rejet.';
      pn_retcode := 0;
    END IF;
    Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || pv_errbuf || CHR(10));
    output_end;
  
  EXCEPTION
    WHEN e_dest_error THEN
     
      pn_retcode := 1;
      pv_errbuf  := 'ECHEC : Le mail n''a pas pu être envoyé.';
	  
      Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || pv_errbuf || CHR(10));
	  pv_errbuf  := 'Voir le journal du traitement pour avoir plus de détail sur l''anomalie rencontrée.';
	  Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || pv_errbuf || CHR(10));
      output_end;
    WHEN e_etat_error THEN
      pn_retcode := 2;
      Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || pv_errbuf || CHR(10));
      output_end;
  END MAIN;

END DKA_SPODAMAIL_PKG;
/
SHOW ERRORS;
EXIT 