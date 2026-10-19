create or replace PACKAGE BODY DKA_SSATIPOIDSMAIL_PKG AS
  ---------------------------------------------------------------------------------------------------------------
  -- CAP GEMINI ERNST AND YOUNG
  -- PROJET            : DALKIA Oracle Applications
  -- NOM           : DKA_SATI_WEIGHT_PKG.pkb
  -- DESCRIPTION       : CALCUL DU POIDS SATI et ENVOI DE MAIL
  --
  --- AUTEUR           : SALOUA HAHIOUI
  --- DATE DE CREATION : 10/03/2020
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
  ------------------------------------------------------------------------------------
  -- Nom              : Output_header
  -- Description      : Procédure de duplication en masse des sites fournisseurs
  --
  -- PARAMETRES       : pv_errbuf      Sortie Message d'erreur
  --                    pn_retgcc     Sortie gcc Retour de la procédure
  --                                   '0' : Normal
  --                                   '1' : Avertissement
  --                                   '2' : Erreur
  --
  ------------------------------------------------------------------------------------
  g_nom_traitement varchar2(50) := 'DKA : Calcul du poids SATI et envoi de mail';

  TYPE liste_destinataires IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
  e_dest_error EXCEPTION;
  e_etat_error EXCEPTION;

  PROCEDURE output_header is
  BEGIN
  
    Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('    Traitement                                                : ' ||
                                       g_nom_traitement);
    Dka_Tools_Pkg.Put_Outdebug_Message('    Date et Heure                                             : ' ||
                                       to_char(SYSDATE,
                                               'DD-MON-YYYY HH24:MI:SS'));
    Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------------------------------------');
    fnd_file.put_line(fnd_file.OUTPUT, ' ');
  
  END;
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
    Fnd_File.put_line(Fnd_File.output, cv_line || CHR(10));
    Fnd_File.put_line(Fnd_File.output,
                      'Programme terminé le : ' ||
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
    Fnd_File.put_line(Fnd_File.output, cv_line);
  END output_end;

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

    fil             BFILE; -- SELOO
    v_length        integer := 0; -- SELOO
    k               integer := 1;
    v_raw           raw(57);
    v_buffer_size   integer := 57;
    V_TYPE_CAMPAGNE varchar(50);
    p_to            VARCHAR2(30000);
    p_cc            VARCHAR2(30000);
  BEGIN
  
    BEGIN
      SELECT ffv.flex_value AS ADR_DESTINATION
        into V_TYPE_CAMPAGNE
        FROM fnd_flex_values_tl           ffvt,
             fnd_flex_value_sets          ffvs,
             fnd_flex_values              ffv,
             dka.DKA_IEOAPSAT01_APIMP_HDR
       WHERE ffv.flex_value_set_id = ffvs.flex_value_set_id
         AND ffvs.flex_value_set_name = 'DKA_VENDOR_PAY_GROUP'
         AND ffv.flex_value_id = ffvt.flex_value_id
         AND ffvt.LANGUAGE = USERENV('LANG')
         AND ffv.ENABLED_FLAG = 'Y'
         AND ATTRIBUTE1 = type_campagne
         AND SYSDATE BETWEEN NVL(START_DATE_ACTIVE, SYSDATE) AND
             NVL(END_DATE_ACTIVE, SYSDATE)
         AND rownum < 2;
    EXCEPTION
    
      WHEN OTHERS THEN
        select argument1
          into V_TYPE_CAMPAGNE
          from (SELECT fcr.argument1
                  FROM fnd_concurrent_requests fcr,
                       fnd_concurrent_programs fcp
                 where fcr.concurrent_program_id = fcp.concurrent_program_id
                   and Fcp.Concurrent_Program_Name = 'DKA_SAPAUTORGT'
                 order by actual_start_date desc)
         where rownum = 1;
      
    END;
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
                          'DKA_CALCUL_POIDS' || '_' || V_TYPE_CAMPAGNE || '_' ||
                          to_CHAR(sysdate, 'DDMMYYYY_HH24MMSS') || '.xls' || '"' ||
                          UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Transfer-Encoding: base64' ||
                          UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Disposition: attachment; filename="' ||
                          'DKA_CALCUL_POIDS' || '_' || V_TYPE_CAMPAGNE || '_' ||
                          to_CHAR(sysdate, 'DDMMYYYY_HH24MMSS') || '.xls' || '"' ||
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
    l_procedure VARCHAR2(30) := 'DKA : Etat calcul du poids';
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
    gv_expediteur VARCHAR2(50);
    rec_param     dka_parameters%ROWTYPE;
    l_layout        BOOLEAN;
    V_TYPE_CAMPAGNE VARCHAR2(50);
  
    CURSOR cur_file_name(P_Req_Id NUMBER) IS
    
      SELECT SUBSTR(OUTFILE_NAME, INSTR(OUTFILE_NAME, '/', -1) + 1, 200) FILE_NAME,
             outfile_name,
             fcp.concurrent_program_name || '_' || fcr.request_id ||
             '_1.xls' excel_file
        FROM fnd_concurrent_requests fcr, FND_CONCURRENT_PROGRAMS fcp
       WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
         and fcr.request_id = P_Req_Id;
  
    rec_file_name cur_file_name%ROWTYPE;
  
    -- Récupération des destinataires directs
    CURSOR EXTR_ADR_TO IS
      SELECT ffv.flex_value AS ADR_DESTINATION
        FROM fnd_flex_values_tl  ffvt,
             fnd_flex_value_sets ffvs,
             fnd_flex_values     ffv
       WHERE ffv.flex_value_set_id = ffvs.flex_value_set_id
         AND ffvs.flex_value_set_name = 'DKA_MAIL_CALCUL_POIDS'
         AND ffv.flex_value_id = ffvt.flex_value_id
         AND ffvt.LANGUAGE = USERENV('LANG')
         AND ffv.ENABLED_FLAG = 'Y'
         AND ffv.ATTRIBUTE1 = 'Y'
         AND SYSDATE BETWEEN NVL(START_DATE_ACTIVE, SYSDATE) AND
             NVL(END_DATE_ACTIVE, SYSDATE);
  
    -- Récupération des destinataires en copie
    CURSOR EXTR_ADR_CC IS
      SELECT ffv.flex_value AS ADR_DESTINATION
        FROM fnd_flex_values_tl  ffvt,
             fnd_flex_value_sets ffvs,
             fnd_flex_values     ffv
       WHERE ffv.flex_value_set_id = ffvs.flex_value_set_id
         AND ffvs.flex_value_set_name = 'DKA_MAIL_CALCUL_POIDS'
         AND ffv.flex_value_id = ffvt.flex_value_id
         AND ffvt.LANGUAGE = USERENV('LANG')
         AND ffv.ENABLED_FLAG = 'Y'
         AND ffv.ATTRIBUTE2 = 'Y'
         AND SYSDATE BETWEEN NVL(START_DATE_ACTIVE, SYSDATE) AND
             NVL(END_DATE_ACTIVE, SYSDATE);
  
  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''FRENCH''';
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS =''.,''';
    BEGIN
      SELECT ffv.flex_value AS ADR_DESTINATION
        into V_TYPE_CAMPAGNE
        FROM fnd_flex_values_tl           ffvt,
             fnd_flex_value_sets          ffvs,
             fnd_flex_values              ffv,
             dka.DKA_IEOAPSAT01_APIMP_HDR
       WHERE ffv.flex_value_set_id = ffvs.flex_value_set_id
         AND ffvs.flex_value_set_name = 'DKA_VENDOR_PAY_GROUP'
         AND ffv.flex_value_id = ffvt.flex_value_id
         AND ffvt.LANGUAGE = USERENV('LANG')
         AND ffv.ENABLED_FLAG = 'Y'
         AND ATTRIBUTE1 = type_campagne
         AND SYSDATE BETWEEN NVL(START_DATE_ACTIVE, SYSDATE) AND
             NVL(END_DATE_ACTIVE, SYSDATE)
         AND rownum < 2;
    EXCEPTION
      WHEN OTHERS THEN
        select argument1
          into V_TYPE_CAMPAGNE
          from (SELECT fcr.argument1
                  FROM fnd_concurrent_requests fcr,
                       fnd_concurrent_programs fcp
                 where fcr.concurrent_program_id = fcp.concurrent_program_id
                   and Fcp.Concurrent_Program_Name = 'DKA_SAPAUTORGT'
                 order by actual_start_date desc)
         where rownum = 1;
    END;
  
    BEGIN
      output_header;
    
      fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'Lancement de l''état');
    
      l_layout := fnd_request.add_layout(template_appl_name => 'DKA',
                                         template_code      => 'DKA_SSATIPOIDS_RDF',
                                         template_language  => 'fr', --Use language from template definition
                                         template_territory => 'F', --Use territory from template definition
                                         output_format      => 'EXCEL' --Use output format from template definition
                                         );
    
      l_request_id := fnd_request.submit_request(l_application_code, -- APPL
                                                 l_conc_program, -- PROG
                                                 '', -- PROGRAM_NAME
                                                 sysdate, -- START
                                                 FALSE -- SUB_REQUEST                                                 
                                                 );
    
      commit;
      IF l_request_id != 0 THEN
      
        l_execute_code := FND_CONCURRENT.WAIT_FOR_REQUEST(REQUEST_ID => l_request_id,
                                                          INTERVAL   => l_req_interval,
                                                          MAX_WAIT   => l_req_max_wait,
                                                          PHASE      => l_req_phase,
                                                          STATUS     => l_req_status,
                                                          DEV_PHASE  => l_req_dev_phase,
                                                          DEV_STATUS => l_req_dev_status,
                                                          MESSAGE    => l_req_message);
      
        IF (upper(l_req_status) != 'NORMAL') THEN
          pn_retcode := 2;
          pv_errbuf  := '====> ERREUR :Le traitement ' || l_procedure ||
                        ' s''est terminé en erreur.';
          raise e_etat_error;
        END IF;
      
      ELSE
      
        pn_retcode := 2;
        pv_errbuf  := '====> ERREUR :Le traitement ' || l_procedure ||
                      ' a échoué';
        raise e_etat_error;
      
      END IF;
    
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin ' || l_procedure);
    
    END;
  
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
  
    fnd_file.put_line(fnd_file.OUTPUT,
                      'L''envoi du calcul du poids SATI a été envoyé par mail aux adresses suivantes:');
  
    vn_cpt := 0;
    vt_adr_to(1) := 'INIT';
  
    fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Récupération des destinataires directs');
    -- Alimentation du tableau des destinataires directs
    FOR CUR_ADR_TO IN EXTR_ADR_TO LOOP
      vn_cpt := vn_cpt + 1;
      vt_adr_to(vn_cpt) := CUR_ADR_to.ADR_DESTINATION;
      fnd_file.put_line(fnd_file.OUTPUT, '- ' || vt_adr_to(vn_cpt));
    END LOOP;
  
    -- Si pas de destinataire direct, on renvoie vers l'exception
    IF (vn_cpt = 0) THEN
      raise e_dest_error;
    END IF;
  
    vn_cpt := 0;
    vt_adr_cc(1) := 'INIT';
  
    fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Récupération des destinataires en copie');
    -- Alimentation du tableau des destinataires en copie
    FOR CUR_ADR_CC IN EXTR_ADR_CC LOOP
      vn_cpt := vn_cpt + 1;
      vt_adr_cc(vn_cpt) := CUR_ADR_cc.ADR_DESTINATION;
      fnd_file.put_line(fnd_file.OUTPUT, '- ' || vt_adr_cc(vn_cpt));
    END LOOP;
  
    FOR rec_file_name IN cur_file_name(l_request_id) LOOP
    
      fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Procédure d''envoi du mail');
      SEND_MSG(p_tab_to      => vt_adr_to,
               p_tab_cc      => vt_adr_cc,
               p_from        => 'no-reply@dalkia.fr',
               p_subject     => 'Calcul du poids pour la campagne de virements ' ||
                                V_TYPE_CAMPAGNE || ' du ' ||
                                to_CHAR(sysdate, 'DD/MM/YYYY'),
               p_text_msg    => 'Bonjour,' || CHR(13) || '' || CHR(13) ||
                                'Veuillez trouver ci-joint l''état du calcul du poids pour la campagne de virements ' ||
                                V_TYPE_CAMPAGNE || ' du ' ||
                                to_CHAR(sysdate, 'DD/MM/YYYY') || '.' ||
                                CHR(13) || '' || CHR(13) || 'Cordialement,',
               p_attach_name => rec_file_name.excel_file,
               p_attach_mime => 'DKA_SARENCAIS_FILE_OUT_DIR',
               p_smtp_host   => vv_conn);
    
      fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Mail envoyé');
    END LOOP;
  
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
      pv_errbuf  := 'L''envoi de mail n''a pas pu être effectué car aucun destinataire n''est actif.';
      Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || pv_errbuf || CHR(10));
      output_end;
    WHEN e_etat_error THEN
      pn_retcode := 2;
      Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || pv_errbuf || CHR(10));
      output_end;
  END MAIN;

END DKA_SSATIPOIDSMAIL_PKG;
/
SHOW ERRORS;
EXIT 