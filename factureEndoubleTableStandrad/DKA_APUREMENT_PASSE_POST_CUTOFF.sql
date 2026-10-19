CREATE OR REPLACE PACKAGE BODY DKA_SARENCAIS_MAIL_PKG AS

  ----------------------------------------------------------------------------------------------
  -- $$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SARENCAIS_MAIL_PKG.pks
  -- DESCRIPTION       : DKA_SARENCAIS_MAIL_PKG package body :
  ---
  --- AUTEUR           : Benjamin COUDRIER
  --- DATE DE CREATION : 20/08/2012
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- 10/04/2013 BCO INC000000395045 - Création d'une procédure d'attente de fin d'exécution de
  ---           traitement + Lancement de la procédure en début de traitement.
  --- 04/08/2016 MEG Migration R12
  --- ---------- --- ---------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  gn_user_id    fnd_user.user_id%TYPE;
  gn_login_id   fnd_logins.login_id%TYPE;
  --gn_org_id     hr_all_organization_units.organization_id%TYPE;
  gn_request_id fnd_concurrent_requests.request_id%TYPE;

  gv_base            VARCHAR2(50);
  gv_conn            VARCHAR2(30);
  gv_expediteur      VARCHAR2(50);
  gv_subject         VARCHAR2(4000);
  gv_body            VARCHAR2(4000);
  gv_type_attachment VARCHAR2(50);
  gn_amt             BINARY_INTEGER := 672 * 3; /* ensures proper format;  2016 */

  -- -----------------------------------------------------------------------------
  -- Nom              : Attente_Fin_Trait_Sarencais
  -- Description      : Procédure d'attente de la fin de tous les traitements.
  --
  -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
  --                    Pn_Retcode         Sortie Code Retour de la procédure
  --                                              '0' : Normal
  --                                              '1' : Avertissement
  --                                              '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Attente_Fin_Trait_Sarencais(Pv_Errbuf  OUT VARCHAR2,
                                        Pn_Retcode OUT NUMBER) IS
  
    Vn_Indice     NUMBER;
    Vn_Interval   NUMBER := 10;
    Vn_Max_Wait   NUMBER := 0;
    Vv_Phase      VARCHAR2(80);
    Vv_Status     VARCHAR2(80);
    Vv_Dev_Phase  VARCHAR2(30);
    Vv_Dev_Status VARCHAR2(30);
    Vv_Message    VARCHAR2(240);
    Vb_Trait_Ok   BOOLEAN;
    vn_parent_id  fnd_concurrent_requests.parent_request_id%TYPE;
  
  BEGIN
  
    Dka_Tools_Pkg.Put_Debug_Message('Attente_Fin_Trait_Sarencais (+)');
  
    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;
  
    Vb_Trait_Ok := TRUE;
  
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Recherche de l''identifiant du traitement parent :');
  
    BEGIN
      SELECT fcr.parent_request_id
        INTO vn_parent_id
        FROM fnd_concurrent_requests fcr
       WHERE fcr.request_id = fnd_global.CONC_REQUEST_ID;
    EXCEPTION
      WHEN OTHERS THEN
        Pn_Retcode := 2;
        Pv_Errbuf  := 'Impossible de recherche l''identifiant parent pour le traitement d''identifiant ' ||
                      fnd_global.CONC_REQUEST_ID || ' .';
    END;
  
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Numéro de traitement parent : ' ||
                                       vn_parent_id ||
                                       ' / Numéro du traitement fils : ' ||
                                       fnd_global.CONC_REQUEST_ID);
    Dka_Tools_Pkg.Put_Outdebug_Message('=> Attente de la fin du traitement : ''DKA : Paiement intra groupe AP/AR''');
    
    IF NOT Fnd_Concurrent.Wait_For_Request(vn_parent_id,
                                           Vn_Interval,
                                           Vn_Max_Wait,
                                           Vv_Phase,
                                           Vv_Status,
                                           Vv_Dev_Phase,
                                           Vv_Dev_Status,
                                           Vv_Message) THEN
      Pv_Errbuf  := Vv_Message;
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Vv_Message);
    ELSE
      IF Vv_Dev_Status = 'NORMAL' THEN
        Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement ' ||
                                           vn_parent_id ||
                                           ' s''est terminé normalement');
      ELSIF Vv_Dev_Status = 'WARNING' THEN
        Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement ' ||
                                           vn_parent_id ||
                                           ' s''est terminé en warning');
        Vb_Trait_Ok := FALSE;
      ELSIF Vv_Dev_Status != 'NORMAL' THEN
        Dka_Tools_Pkg.Put_Outdebug_Message('==> Le traitement ' ||
                                           vn_parent_id ||
                                           ' s''est terminé en erreur');
        Vb_Trait_Ok := FALSE;
      END IF;
    END IF;
  
    IF NOT Vb_Trait_Ok THEN
      Pv_Errbuf  := '==> Un ou plusieurs traitements se sont terminés en Warning ou en Erreur';
      Pn_Retcode := 1;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
    END IF;
  
    Dka_Tools_Pkg.Put_Debug_Message('Attente_Fin_Trait_Sarencais (-)');
  
  EXCEPTION
    WHEN OTHERS THEN
      Pv_Errbuf  := 'Erreur dans la procécure Attente_Fin_Trait_Sarencais : ' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
      Dka_Tools_Pkg.Put_Debug_Message('Attente_Fin_Trait_Sarencais (-)');
    
  END Attente_Fin_Trait_Sarencais;

  ----------------------------------------------------------------------------
  --  Nom           : init
  --  Description   : Procédure d'initialisation
  --
  --  PARAMETRES :
  --    pv_errbuf   Entrée/Sortie          message d'erreur
  --    VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE init(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    rec_param dka_parameters%ROWTYPE;
    e_err_param EXCEPTION;
  
  BEGIN
    dka_tools_pkg.put_debug_message('(+) Init');
    pv_errbuf  := NULL;
    pn_retcode := 0;
  
    -- En-tête du fichier de sortie
    dka_tools_pkg.put_out_header;
  
    -- Variables globale "WHO"
    gn_user_id    := fnd_global.user_id;
    gn_login_id   := fnd_global.login_id;
    gn_request_id := fnd_global.conc_request_id;
    --gn_org_id     := fnd_profile.value('ORG_ID');
  
    --Récupération du nom de la base de données concernée
    BEGIN
      SELECT name INTO gv_base FROM v$database;
    EXCEPTION
      WHEN OTHERS THEN
        pv_errbuf  := 'ERREUR lors de la recherche du nom de la base de données';
        pn_retcode := 2;
        RAISE;
    END;
  
    Dka_Tools_Pkg.put_debug_message(CHR(10) || 'gv_base : ' || gv_base);
  
    --Recuperation des parametres de connexion
  --IF gv_base = 'DT1OAP' THEN
    IF gv_base = 'HELDEV' THEN
    --gv_conn := 'kriek.nord-est.capgemini.fr';
      gv_conn := 'ismtp.corp.capgemini.com';
    ELSE
      Dka_Tools_Pkg.get_parameter('SPOBON_MAIL',
                                  'SMTP_CONNECTION',
                                  rec_param,
                                  pv_errbuf,
                                  pn_retcode);
      gv_conn := rec_param.varchar2_value;
    END IF;
  
    Dka_Tools_Pkg.put_debug_message('Connexion SMTP : ' || gv_conn);
  
    IF pn_retcode != 0 THEN
      RAISE e_err_param;
    END IF;
  
    --Recuperation du nombre de reconduction max
    Dka_Tools_Pkg.get_parameter('SPOBON_MAIL',
                                'EXPEDITEUR_MAIL',
                                rec_param,
                                pv_errbuf,
                                pn_retcode);
    gv_expediteur := rec_param.varchar2_value;
  
    Dka_Tools_Pkg.put_debug_message('Expediteur mail : ' || gv_expediteur);
  
    IF pn_retcode != 0 THEN
      RAISE e_err_param;
    END IF;
  
    --Recuperation du nombre de reconduction max
    Dka_Tools_Pkg.get_parameter('SPOBON_MAIL',
                                'TYPE_PIECE_JOINTE',
                                rec_param,
                                pv_errbuf,
                                pn_retcode);
    gv_type_attachment := rec_param.varchar2_value;
  
    Dka_Tools_Pkg.put_debug_message('Type Piece jointe : ' ||
                                    gv_type_attachment);
  
    IF pn_retcode != 0 THEN
      RAISE e_err_param;
    END IF;
  
    dka_tools_pkg.put_debug_message('(-) Init');
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'INIT : ' || SQLERRM;
  END init;

  ----------------------------------------------------------------------------
  --  Nom           : write_boundary
  --  Description   : Procédure
  --
  --  PARAMETRES :
  --    VALEUR RETOURNEE :
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE write_boundary(conn IN OUT NOCOPY utl_smtp.connection,
                           last IN BOOLEAN DEFAULT FALSE) AS
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
  --    VALEUR RETOURNEE :
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
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
                                                mime_type || utl_tcp.CRLF));
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
  --    VALEUR RETOURNEE :
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE end_attachment(conn IN OUT NOCOPY utl_smtp.connection,
                           last IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
    utl_smtp.write_data(conn, utl_tcp.CRLF);
    IF (last) THEN
      write_boundary(conn, last);
    END IF;
  END end_attachment;

  -------------------------------------------------------------------------------------
  --  Nom           : ENVOI_MAIL
  --  Description   : procedure d'envoi de mail
  --
  --  PARAMETRES    :
  --  pv_date_gen   IN       Date génération du fichier
  --  pv_region      IN       Région
  --  pv_societe      IN       Société
  --  pv_file_name    IN       Nom du fichier en pièce jointe.
  --  pv_errbuf       OUT      Message de sortie.
  --  pn_retcode      OUT      Code retour.
  --  VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ------------------------------------------------------------------------------------
  PROCEDURE envoi_mail(pv_program_name IN VARCHAR2,
                       pv_request_date IN VARCHAR2,
                       pv_file_name    IN VARCHAR2,
                       pv_mail         IN VARCHAR2,
                       pv_errbuf       OUT VARCHAR2,
                       pn_retcode      OUT NUMBER) IS
  
    l_mesg     VARCHAR2(4000);
    l_conn     UTL_SMTP.CONNECTION;
    l_file     BFILE;
    l_file_len PLS_INTEGER;
    l_modulo   PLS_INTEGER;
    l_pieces   PLS_INTEGER;
    l_filepos  PLS_INTEGER := 1; /* pointeur pour le fichier */
    l_buf      RAW(2100);
    l_data     RAW(2100);
    l_chunks   PLS_INTEGER;
  
  BEGIN
    -- Initialisation de l'objet du mail.
    gv_subject := Dka_Tools_Pkg.get_message('DKA', 'DKA_SARENCAIS_MAIL_SUB');
    -- Initialisation du corps du mail.
    gv_body := Dka_Tools_Pkg.get_message('DKA',
                                         'DKA_SARENCAIS_MAIL_CONT',
                                         'PROGRAM_NAME',
                                         pv_program_name,
                                         'REQUEST_DATE',
                                         pv_request_date);
  
    -- Gestion du cas où aucune adresse n'a été trouvée
    BEGIN
      -- Fichier.
      -- l_file := BFILENAME('DKA_SARENCAIS_FILE_OUT_DIR', pv_file_name);
      l_file := BFILENAME('DKA_OUT_DIR', pv_file_name);
      gn_amt := 672 * 3;
      BEGIN
        l_file_len := dbms_lob.getlength(l_file);
      EXCEPTION
        WHEN OTHERS THEN
          dka_tools_pkg.put_log_message('Le fichier : ' || pv_file_name ||
                                        ' est vide et aucun mail ne sera envoyé aux destinataires.');
      END;
      l_modulo := mod(l_file_len, 0);
      l_pieces := trunc(l_file_len / gn_amt);
      IF (l_modulo <> 0) THEN
        l_pieces := l_pieces + 1;
        IF pv_mail IS NOT NULL THEN
          -- Création et envoi du mail au créateur
          l_conn := utl_smtp.open_connection(gv_conn, 25);
          utl_smtp.helo(l_conn, gv_conn);
          utl_smtp.mail(l_conn, gv_expediteur);
          utl_smtp.rcpt(l_conn, '<' || pv_mail || '>');
          utl_smtp.open_data(l_conn);
          --l_mesg:= 'Date: ' || to_char(systimestamp, 'dd Mon yy hh24:mi:ss tzhtzm') || utl_tcp.CRLF ||
          l_mesg := 'Date: ' ||
                    to_char(systimestamp,
                            'dd Mon yyyy hh24:mi:ss tzhtzm',
                            'NLS_DATE_LANGUAGE=American') || utl_tcp.CRLF ||
                    'From: ' || gv_expediteur || utl_tcp.CRLF || 'To: <' ||
                    pv_mail || '>' || utl_tcp.CRLF || 'Subject:' ||
                    gv_subject || utl_tcp.CRLF || 'Content-Type: ' ||
                    MULTIPART_MIME_TYPE || utl_tcp.CRLF || utl_tcp.CRLF;
          utl_smtp.write_data(l_conn, l_mesg);
          -- Insertion du corps du message
          BEGIN
            begin_attachment(conn => l_conn, mime_type => 'text/plain');
            utl_smtp.write_data(l_conn, gv_body || utl_tcp.CRLF);
            end_attachment(conn => l_conn);
          END;
          begin_attachment(conn         => l_conn,
                           mime_type    => 'text/plain',
                           inline       => TRUE,
                           filename     => pv_file_name,
                           transfer_enc => 'base64');
          dbms_lob.fileopen(l_file, dbms_lob.file_readonly);
          dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
          l_data := NULL;
          FOR i IN 1 .. l_pieces LOOP
            l_filepos  := i * gn_amt + 1;
            l_file_len := l_file_len - gn_amt;
            l_data     := utl_raw.concat(l_data, l_buf);
            l_chunks   := trunc(utl_raw.length(l_data) / MAX_LINE_WIDTH);
          
            IF (i <> l_pieces) THEN
              l_chunks := l_chunks - 1;
            END IF;
            utl_smtp.write_raw_data(l_conn,
                                    utl_encode.base64_encode(l_data));
            l_data := NULL;
            IF (l_file_len < gn_amt AND l_file_len > 0) THEN
              gn_amt := l_file_len;
            END IF;
          
            IF l_pieces > 1 THEN
              dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
            END IF;
          END LOOP;
          dbms_lob.fileclose(l_file);
          end_attachment(conn => l_conn);
          utl_smtp.close_data(l_conn);
          utl_smtp.quit(l_conn);
          Dka_Tools_Pkg.put_outdebug_message('==> Mail BdC envoye a adresse : <' ||
                                             pv_mail || '>');
        ELSE
          Dka_Tools_Pkg.put_outdebug_message(CHR(10) ||
                                             '==> AVERTISSEMENT : Pas d''envoi effectué : Aucune adresse mail disponible');
        END IF;
      END IF;
    END; -- Fin de l'insertion de la pièce jointe
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure ENVOI_MAIL ' || SQLERRM;
      pn_retcode := 2;
      Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
  END envoi_mail;

  -------------------------------------------------------------------------------------
  --  Nom           : file_zip_affact
  --  Description   : procedure d'exécution de la compression du fichier à envoyer
  --
  --  PARAMETRES    :
  --  cv_prog_name                 IN       Short Name du traitement
  --  vv_nom_entre               IN       Nom fichier en entré
  --  vv_chemin_entre              IN       Chemin du fichier en entré
  --  vv_chemin_sortie               IN       Chemin du fichier zip de sortie
  --  vv_nom_sortie                IN       Nom fichier zip de sortie
  --  vb_validation                OUT      Code retour.
  --  VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : true=traitement sans erreur, false=traitement en erreur
  ------------------------------------------------------------------------------------
  PROCEDURE file_zip_affact(cv_prog_name     IN VARCHAR2,
                            vv_nom_entre     IN VARCHAR2,
                            vv_chemin_entre  IN VARCHAR2,
                            vv_chemin_sortie IN VARCHAR2,
                            vv_nom_sortie    IN VARCHAR2,
                            vb_validation    OUT BOOLEAN) IS
    vv_prog_application_short_name VARCHAR(30);
    vn_request_id                  NUMBER(15);
    cn_tempo CONSTANT NUMBER := 20;
    vv_rphase  VARCHAR2(80);
    vv_rstatus VARCHAR2(80);
    vv_dphase  VARCHAR2(30);
    vv_dstatus VARCHAR2(30);
    vv_message VARCHAR2(240);
  BEGIN
    -- Recherche de l'application propriétaire du traitement. --
    BEGIN
      SELECT fa.application_short_name
        INTO vv_prog_application_short_name
        FROM fnd_concurrent_programs fcp, fnd_application fa
       WHERE fcp.concurrent_program_name = cv_prog_name
         AND fa.application_id = fcp.application_id;
    EXCEPTION
      WHEN OTHERS THEN
        vb_validation := FALSE;
        DBMS_OUTPUT.put_line('Impossible de trouver l''application propriétaire pour le lancement du traitement de compression du fichier : ' ||
                             vv_nom_entre);
    END;
  
    vn_request_id := fnd_request.submit_request(vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                cv_prog_name, --SHORT_NAME du TRAITEMENT
                                                NULL, --PROGRAM_NAME
                                                NULL, --START
                                                FALSE, --SUB_REQUEST
                                                vv_nom_entre, --ARGUMENT1
                                                vv_chemin_entre, --ARGUMENT2
                                                vv_chemin_sortie, --ARGUMENT3
                                                vv_nom_sortie --ARGUMENT4
                                                );
    DBMS_OUTPUT.put_line('Validation pour que les GTS puissent prendre la demande');
    COMMIT;
  
    IF vn_request_id = 0 THEN
      DBMS_OUTPUT.put_line('Impossible de lancer le Traitement ');
      vb_validation := FALSE;
    END IF;
  
    DBMS_OUTPUT.put_line('Traitement numero : ' || TO_CHAR(vn_request_id));
  
    IF NOT fnd_concurrent.wait_for_request(vn_request_id,
                                           cn_tempo,
                                           0,
                                           vv_rphase,
                                           vv_rstatus,
                                           vv_dphase,
                                           vv_dstatus,
                                           vv_message) THEN
      vb_validation := FALSE;
    ELSE
      IF vv_dstatus = 'WARNING' THEN
        DBMS_OUTPUT.put_line(CHR(10) ||
                             '>>> Traitement termine en Warning ');
        vb_validation := FALSE;
      ELSIF vv_dstatus != 'NORMAL' THEN
        DBMS_OUTPUT.put_line(CHR(10) ||
                             '>>> Traitement termine en Erreur ');
        vb_validation := FALSE;
      END IF;
    END IF;
  
    DBMS_OUTPUT.put_line(CHR(10) || '>>> Fin normale');
    vb_validation := TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.put_line(cv_prog_name || ' ==> ERREUR : ' || SQLERRM);
      vb_validation := FALSE;
  END;

  -----------------------------------------------------------------
  -- NOM         : main
  -- DESCRIPTION : Procédure principale d'envoi par mail des
  --        rejets de la surtaxe communale.
  --        traitments DKA : Controle des rejets de la surtaxe communale.
  -- PARAMETRE   : pv_errbuf     OUT   Message de sortie
  --        pn_retcode   OUT   Code retour
  -----------------------------------------------------------------
  PROCEDURE main(pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER) IS
  
    -- Recherche de l'ensemble des adresses mails liées aux traitements sélectionnés. --
    CURSOR cur_mail_sarencais(Pv_Prog_Name_Are IN VARCHAR2) IS
      SELECT ffvv_p.FLEX_VALUE NOM_ABRE, ffvv_e.FLEX_VALUE MAIL
        FROM fnd_flex_value_sets ffvs_p,
             fnd_flex_values_vl  ffvv_p,
             fnd_flex_value_sets ffvs_e,
             fnd_flex_values_vl  ffvv_e
       WHERE ffvs_p.flex_value_set_name = 'DKA_TRAIT_NAME_AUDIT'
         AND ffvs_p.flex_value_set_id = ffvv_p.FLEX_VALUE_SET_ID
         AND ffvs_e.flex_value_set_name = 'DKA_MAIL_LISTE_AUDIT'
         AND ffvs_e.flex_value_set_id = ffvv_e.FLEX_VALUE_SET_ID
         AND ffvv_p.FLEX_VALUE = ffvv_e.PARENT_FLEX_VALUE_LOW
         AND ffvv_e.ENABLED_FLAG = 'Y'
         AND decode(ffvv_e.START_DATE_ACTIVE,
                    NULL,
                    SYSDATE,
                    ffvv_e.START_DATE_ACTIVE) <= SYSDATE
         AND decode(ffvv_e.END_DATE_ACTIVE,
                    NULL,
                    SYSDATE,
                    ffvv_e.END_DATE_ACTIVE) >= SYSDATE
         AND ffvv_p.FLEX_VALUE = Pv_Prog_Name_Are;
  
    -- Variable contenant l'ensemble des informations sur le fichier de sortie. --
    vv_file_out     FND_CONCURRENT_REQUESTS.OUTFILE_NAME%TYPE;
    vv_program_name FND_CONCURRENT_PROGRAMS_TL.USER_CONCURRENT_PROGRAM_NAME%TYPE;
    vv_request_id   FND_CONCURRENT_REQUESTS.REQUEST_ID%TYPE;
    vv_request_date FND_CONCURRENT_REQUESTS.REQUEST_DATE%TYPE;
  
    -- Variable contenant le nom du fichier de sortie. --
    vv_name_file        VARCHAR2(200);
    vv_name_file_sortie VARCHAR2(200);
  
    -- Chemin d'accès à la directory DKA_OUT_DIR'. --
    vv_directory_path all_directories.directory_path%TYPE;
    vv_chemin_file    all_directories.directory_path%TYPE;
  
    -- Valeur de retour de la procédure de compression de fichier. --
    vb_validation boolean;
  
    NOM_SARENCAIS         FND_CONCURRENT_PROGRAMS_TL.USER_CONCURRENT_PROGRAM_NAME%TYPE;
    NOM_ABRE_SARENCAIS    FND_CONCURRENT_PROGRAMS_VL.CONCURRENT_PROGRAM_NAME%TYPE;
    DESCRIPTION_SARENCAIS FND_CONCURRENT_PROGRAMS_TL.DESCRIPTION%TYPE;
  
    -- Variable permettant la vérification de la taille du fichier d'entré : --
    l_file_enter     BFILE;
    l_file_enter_len PLS_INTEGER;
  
  BEGIN
    -- INC000000395045 - Lancement du traitement d'attente :
    Attente_Fin_Trait_Sarencais(pv_errbuf, pn_retcode);
  
    -- Recherche du chemin de la directory DKA_OUT_DIR. --
    BEGIN
      SELECT ad.directory_path
        INTO vv_directory_path
        FROM all_directories ad
       WHERE ad.directory_name = 'DKA_OUT_DIR';
    EXCEPTION
      WHEN OTHERS THEN
        pv_errbuf  := '==> ERREUR DANS LA PROCEDURE main : ' || SQLERRM;
        pn_retcode := 2;
        DKA_TOOLS_PKG.PUT_LOG_MESSAGE(pv_errbuf);
        DKA_TOOLS_PKG.PUT_LOG_MESSAGE('Impossible de trouver le chemin de la directory ''DKA_OUT_DIR''. ');
    END;
  
    -- Initialisation des variables de connection au serveur d'envoi du mail.
    init(pv_errbuf, pn_retcode);
  
    -- Recherche des informations du traitement DKA_SARSURTAXE_6 du jeu de traitement DKA_SARSURTAXE_SET. --
    SELECT FCP.USER_CONCURRENT_PROGRAM_NAME,
           FCPV.CONCURRENT_PROGRAM_NAME,
           FCP.DESCRIPTION
      INTO NOM_SARENCAIS, NOM_ABRE_SARENCAIS, DESCRIPTION_SARENCAIS
      FROM FND_CONCURRENT_PROGRAMS_TL FCP, FND_CONCURRENT_PROGRAMS_VL FCPV
     WHERE FCP.CONCURRENT_PROGRAM_ID = FCPV.CONCURRENT_PROGRAM_ID
       AND LANGUAGE = 'F'
       AND FCPV.CONCURRENT_PROGRAM_NAME = 'DKA_SARENCAIS'
     ORDER BY USER_CONCURRENT_PROGRAM_NAME;
  
    -- Requête permettant de rechercher les informations pour récupérer les fichiers de sortie. --
    BEGIN
      SELECT R.OUTFILE_NAME,
             TAB.PROGRAM_NAME,
             TAB.REQUEST_ID,
             R.REQUEST_DATE
        INTO vv_file_out, vv_program_name, vv_request_id, vv_request_date
        FROM (SELECT MAX(R.REQUEST_ID) REQUEST_ID,
                     PT.USER_CONCURRENT_PROGRAM_NAME PROGRAM_NAME
                FROM FND_CONCURRENT_PROGRAMS_TL PT,
                     FND_CONCURRENT_PROGRAMS    PB,
                     FND_CONCURRENT_REQUESTS    R
               WHERE PB.APPLICATION_ID = R.PROGRAM_APPLICATION_ID
                 AND PB.CONCURRENT_PROGRAM_ID = R.CONCURRENT_PROGRAM_ID
                 AND PB.APPLICATION_ID = PT.APPLICATION_ID
                 AND PB.CONCURRENT_PROGRAM_ID = PT.CONCURRENT_PROGRAM_ID
                 AND PT.LANGUAGE = USERENV('LANG')
                 AND PB.CONCURRENT_PROGRAM_NAME = NOM_ABRE_SARENCAIS
               GROUP BY PT.USER_CONCURRENT_PROGRAM_NAME) TAB,
             FND_CONCURRENT_REQUESTS R
       WHERE R.REQUEST_ID = TAB.REQUEST_ID;
    EXCEPTION
      WHEN OTHERS THEN
        -- Message d'avertissement concernant l'absence de fichier de sortie. --
        pv_errbuf := 'Aucun Fichier de sortie n''a été trouvé pour l''état ' ||
                     NOM_SARENCAIS;
        dka_tools_pkg.put_log_message(pv_errbuf);
    END;
  
    IF vv_file_out IS NOT NULL THEN
      -- Récupération uniquement du nom de fichier. --
      vv_name_file        := SUBSTR(vv_file_out,
                                    INSTR(vv_file_out, '/', -1) + 1);
      vv_chemin_file      := SUBSTR(vv_file_out,
                                    1,
                                    INSTR(vv_file_out, '/', -1) - 1);
      vv_name_file_sortie := SUBSTR(vv_file_out,
                                    INSTR(vv_file_out, '/', -1) + 1,
                                    INSTR(SUBSTR(vv_file_out,
                                                 INSTR(vv_file_out, '/', -1) + 1),
                                          '.out',
                                          1) - 1) || '.zip';
    
      -- Vérification que le fichier de sortie du traitement 'DKA : Paiement intra groupe AP/AR' n'est pas vide. --
      l_file_enter := BFILENAME('DKA_SARENCAIS_FILE_OUT_DIR', vv_name_file);
      BEGIN
        l_file_enter_len := dbms_lob.getlength(l_file_enter);
      EXCEPTION
        WHEN OTHERS THEN
          dka_tools_pkg.put_log_message('Le fichier : ' || vv_name_file ||
                                        ' est vide et aucun mail ne sera envoyé aux destinataires.');
      END;
    
      IF l_file_enter_len != 0 AND l_file_enter_len IS NOT NULL THEN
        -- Compression du fichier grâce au traitement DKA_COMPRESS_FILE_ZIP
        file_zip_affact('DKA_COMPRESS_FILE_ZIP',
                        vv_name_file,
                        vv_chemin_file,
                        vv_directory_path,
                        vv_name_file_sortie,
                        vb_validation);
        IF vb_validation = TRUE THEN
          FOR rec_mail_sarencais IN cur_mail_sarencais(NOM_ABRE_SARENCAIS) LOOP
            Dka_Tools_Pkg.put_outdebug_message('-------------------------------------------------------------------------');
            Dka_Tools_Pkg.put_outdebug_message('==> Nom du programme : <' ||
                                               NOM_SARENCAIS || '>');
            Dka_Tools_Pkg.put_outdebug_message('==> Nom du fichier de destination : <' ||
                                               vv_name_file || '>');
            Dka_Tools_Pkg.put_outdebug_message('==> Adresse mail de destination : <' ||
                                               rec_mail_sarencais.MAIL || '>');
          
            -- Envoi du fichier par mail à l'adresse email du destinataire des fichiers pour HSBC
            envoi_mail(vv_program_name,
                       vv_request_date,
                       vv_name_file_sortie,
                       rec_mail_sarencais.MAIL,
                       pv_errbuf,
                       pn_retcode);
            Dka_Tools_Pkg.put_outdebug_message('-------------------------------------------------------------------------');
            Dka_Tools_Pkg.put_outdebug_message('--');
          END LOOP;
        ELSE
          DKA_TOOLS_PKG.PUT_LOG_MESSAGE('Erreur lors de la compression du fichier. Le fichier ' ||
                                        vv_name_file ||
                                        ' n''a pas envoyé par mail.');
          pn_retcode := 2;
        END IF;
      ELSE
        dka_tools_pkg.put_log_message('Le fichier : ' || vv_name_file ||
                                      ' est vide et aucun mail ne sera envoyé aux destinataires.');
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := '';
      pn_retcode := 1;
  END;

END DKA_SARENCAIS_MAIL_PKG;
/
SHOW ERRORS

EXIT;
