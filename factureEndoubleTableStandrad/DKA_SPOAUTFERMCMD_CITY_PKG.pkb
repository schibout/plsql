SET VERIFY OFF;
CREATE OR REPLACE PACKAGE BODY dka_mail_pkg IS

  -- -----------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- PROJET           : DALKIA Oracle Applications
  -- NOM              : DKA_MAIL_PKG.pkb
  -- DESCRIPTION      : DKA_MAIL_PKG Package Body
  --
  -- AUTEUR           : Coudrier Benjamin (Capgemini)
  -- DATE DE CREATION : 06/06/2013
  -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
  -- -----------------------------------------------------------------------------
  --
  -- -----------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Qui Description
  -- 09/10/2020 - MTIA - Possibilité de saisir jusqu'a 5 adresses mails dans le jdv
  -- 15/09/2021 NBO artf07480820 - TASK0152735 Correctif sur l'envoi par mail de l'état DKA : Etat des prélèvements automatiques fournisseur
  -- ---------- --- --------------------------------------------------------------

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  gv_conn            VARCHAR2(30);
  g_step             VARCHAR2(500);
  gv_directory_path  VARCHAR2(4000);
  gn_amt             BINARY_INTEGER := 672 * 3;
  boundary            CONSTANT VARCHAR2(256) := '=_NextPart_DC7E1BB5_1105_4DB3_BAE3_2A6208EB099D';
  first_boundary      CONSTANT VARCHAR2(256) := '--' || boundary ||
                                                utl_tcp.crlf;
  last_boundary       CONSTANT VARCHAR2(256) := '--' || boundary || '--' ||
                                                utl_tcp.crlf;
  multipart_mime_type CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary=' ||
                                                boundary;
  max_line_width PLS_INTEGER := 54;

  -- Variable d'exception :
  e_envoi_mail EXCEPTION;
  e_mail       EXCEPTION;

  -----------------------------------------------------------------
  --  Nom           : OUT_MSG
  --  Description   : procedure d'affichage des messages
  --
  --  PARAMETRES :
  --   p_message          texte a imprimer dans la sortie
  --
  -----------------------------------------------------------------
  PROCEDURE out_msg(p_message IN VARCHAR2) IS
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
  PROCEDURE log_msg(p_message IN VARCHAR2) IS
    l_message VARCHAR2(1000);
  BEGIN

    l_message := substr(p_message, 1, 1000);

    IF (l_message IS NULL) THEN
      l_message := to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
    END IF;

    fnd_file.put_line(fnd_file.log, l_message);
  END log_msg;

  -----------------------------------------------------------------
  --  Nom           : INIT
  --  Description   : procedure d'initialisation
  --
  --  PARAMETRES :
  --
  --
  -----------------------------------------------------------------
  PROCEDURE init(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

    rec_param dka_parameters%ROWTYPE;
    e_expediteur_vide EXCEPTION;

  BEGIN
    --Init des variables de sortie
    p_retcode := 0;
    p_errbuf  := '';

    SELECT ad.directory_path
      INTO gv_directory_path
      FROM all_directories ad
     WHERE ad.directory_name = 'DKA_OUT_DIR';

    dka_tools_pkg.get_parameter('DKA_MAIL',
                                'SMTP_CONNECTION',
                                rec_param,
                                p_errbuf,
                                p_retcode);
    gv_conn := rec_param.varchar2_value;

    --Reinit des variables de sortie
    p_retcode := 0;
    p_errbuf  := '';

  EXCEPTION
    WHEN OTHERS THEN
      p_errbuf := 'Erreur procedure INIT :' || g_step || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(p_errbuf);
      p_retcode := 2;
  END init;

  ----------------------------------------------------------------------------
  --  Nom           : write_boundary
  --  Description   : Procédure
  --
  --  PARAMETRES :
  ----------------------------------------------------------------------------
  PROCEDURE write_boundary(conn IN OUT NOCOPY utl_smtp.connection,
                           LAST IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
    IF (LAST) THEN
      utl_smtp.write_data(conn, last_boundary);
    ELSE
      utl_smtp.write_data(conn, first_boundary);
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
                                                mime_type || utl_tcp.crlf));
    IF (filename IS NOT NULL) THEN
      IF (inline) THEN
        utl_smtp.write_raw_data(conn,
                                utl_raw.cast_to_raw('Content-Disposition: ' ||
                                                    'inline; filename="' ||
                                                    filename || '"' ||
                                                    utl_tcp.crlf));
      ELSE
        utl_smtp.write_raw_data(conn,
                                utl_raw.cast_to_raw('Content-Disposition: ' ||
                                                    'attachment; filename="' ||
                                                    filename || '"' ||
                                                    utl_tcp.crlf));
      END IF;
    END IF;
    IF (transfer_enc IS NOT NULL) THEN
      utl_smtp.write_raw_data(conn,
                              utl_raw.cast_to_raw('Content-Transfer-Encoding: ' ||
                                                  transfer_enc ||
                                                  utl_tcp.crlf));
    END IF;
    utl_smtp.write_data(conn, utl_tcp.crlf);
  END begin_attachment;

  ----------------------------------------------------------------------------
  --  Nom           : end_attachment
  --  Description   : Procédure
  --
  --  PARAMETRES :
  ----------------------------------------------------------------------------
  PROCEDURE end_attachment(conn IN OUT NOCOPY utl_smtp.connection,
                           LAST IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
    utl_smtp.write_data(conn, utl_tcp.crlf || utl_tcp.crlf);
    IF (LAST) THEN
      write_boundary(conn, LAST);
    END IF;
  END end_attachment;

  -------------------------------------------------------------------------------------
  --  Nom           : envoi_avec_fichier
  --  Description   : Envoi du message avec fichier.
  --
  --  PARAMETRES    :
  --  Pv_Errbuf      IN OUT       Message d'avertissement
  --  Pn_Retcode  IN OUT     Code erreur
  --  Pv_Entite    IN       Entité
  --  Pv_Module    IN       Module
  --  Pd_Controle  IN       Date de Controle
  --------------------------------------------------------------------------------------
  PROCEDURE envoi_avec_fichier(pv_errbuf  IN OUT VARCHAR2,
                               pn_retcode IN OUT NUMBER,
                               p_req_id   IN NUMBER) IS
    l_mesg           VARCHAR2(4000);
    l_conn           utl_smtp.connection;
    l_file           BFILE;
    l_file_len       PLS_INTEGER;
    l_modulo         PLS_INTEGER;
    l_pieces         PLS_INTEGER;
    l_filepos        PLS_INTEGER := 1; /* pointeur pour le fichier */
    l_buf            RAW(2100);
    l_data           RAW(2100);
    l_chunks         PLS_INTEGER;
    vr_reply         utl_smtp.reply;
    vv_adresses      VARCHAR2(32000); -- OBE artf2283043
    vb_adress_valide NUMBER; -- OBE artf2283043
    e_pas_destinataire EXCEPTION; -- OBE artf228304

    CURSOR cur_file_name(p_req_id NUMBER) IS
      SELECT substr(file_name, 1, instr(file_name, '/', -1) - 1) path,
             substr(file_name, instr(file_name, '/', -1) + 1) file_name, fmt.MIME_TYPE
        FROM fnd_conc_req_outputs fcro, fnd_mime_types fmt
       WHERE concurrent_request_id = p_req_id
       AND fmt.file_ext = lower(decode(fcro.file_type,'EXCEL', 'xls', fcro.file_type));

    CURSOR cur_reqid(p_req_id NUMBER) IS
      SELECT expediteur,
         destinataire,
         substr(destinataire, 1, instr(destinataire, ';') - 1) dest1,
         substr(destinataire,
                instr(destinataire, ';', 1, 1) + 1,
                instr(destinataire, ';', 1, 2) -
                instr(destinataire, ';', 1, 1) - 1) dest2,
         substr(destinataire,
                instr(destinataire, ';', 1, 2) + 1,
                instr(destinataire, ';', 1, 3) -
                instr(destinataire, ';', 1, 2) - 1) dest3,
         substr(destinataire,
                instr(destinataire, ';', 1, 3) + 1,
                instr(destinataire, ';', 1, 4) -
                instr(destinataire, ';', 1, 3) - 1) dest4,
                   substr(destinataire,
                instr(destinataire, ';', 1, 4) + 1,
                instr(destinataire, ';', 1, 5) -
                instr(destinataire, ';', 1, 4) - 1) dest5,
		 -- 15/09/2021 NBO artf07480820 - TASK0152735 Correctif sur l'envoi par mail de l'état DKA : Etat des prélèvements automatiques fournisseur
         substr(destinataire,
                instr(destinataire, ';', 1, 5) + 1,
                instr(destinataire, ';', 1, 6) -
                instr(destinataire, ';', 1, 5) - 1) dest6,
         substr(destinataire,
                instr(destinataire, ';', 1, 6) + 1,
                instr(destinataire, ';', 1, 7) -
                instr(destinataire, ';', 1, 6) - 1) dest7,
         substr(destinataire,
                instr(destinataire, ';', 1, 7) + 1,
                instr(destinataire, ';', 1, 8) -
                instr(destinataire, ';', 1, 7) - 1) dest8,
         substr(destinataire,
                instr(destinataire, ';', 1, 8) + 1,
                instr(destinataire, ';', 1, 9) -
                instr(destinataire, ';', 1, 8) - 1) dest9,
         substr(destinataire,
                instr(destinataire, ';', 1, 9) + 1,
                instr(destinataire, ';', 1, 10) -
                instr(destinataire, ';', 1, 9) - 1) dest10,
         objet,
         corps,
         attachement,
         filename,
         cc_mail
        FROM dka.dka_mail_param
       WHERE req_id = p_req_id;

    rec_file_name cur_file_name%ROWTYPE;
    rec_reqid     cur_reqid%ROWTYPE;

    vv_expediteur   VARCHAR2(1000);
    vv_destinataire VARCHAR2(1000);
    vv_destinataire2 VARCHAR2(1000);
    vv_destinataire3 VARCHAR2(1000);
    vv_destinataire4 VARCHAR2(1000);
    vv_destinataire5 VARCHAR2(1000);
    -- 15/09/2021 NBO artf07480820 - TASK0152735 Correctif sur l'envoi par mail de l'état DKA : Etat des prélèvements automatiques fournisseur
    vv_destinataire6 VARCHAR2(1000);
    vv_destinataire7 VARCHAR2(1000);
    vv_destinataire8 VARCHAR2(1000);
    vv_destinataire9 VARCHAR2(1000);
    vv_destinataire10 VARCHAR2(1000);
    vv_objet        VARCHAR2(4000);
    vv_corps        VARCHAR2(4000);
    vv_attachement  VARCHAR2(1);
    vv_filename     VARCHAR2(4000);
    vv_cc           VARCHAR2(4000);
  BEGIN
    vb_adress_valide := 0;
    g_step           := 'ENVOI_AVEC_FICHIER 000 : DEBUT';
    log_msg(g_step);
    g_step := 'ENVOI_AVEC_FICHIER 001 : RECHERCHE DE L''OBJET DU MAIL.';
    log_msg(g_step);

    FOR rec_reqid IN cur_reqid(p_req_id) LOOP
      vv_expediteur   := rec_reqid.expediteur;
      vv_destinataire := rec_reqid.dest1;
      vv_destinataire2 := rec_reqid.dest2;
      vv_destinataire3 := rec_reqid.dest3;
      vv_destinataire4 := rec_reqid.dest4;
      vv_destinataire5 := rec_reqid.dest5;
  	  -- 15/09/2021 NBO artf07480820 - TASK0152735 Correctif sur l'envoi par mail de l'état DKA : Etat des prélèvements automatiques fournisseur
      vv_destinataire6 := rec_reqid.dest6;
      vv_destinataire7 := rec_reqid.dest7;
      vv_destinataire8 := rec_reqid.dest8;
      vv_destinataire9 := rec_reqid.dest9;
      vv_destinataire10 := rec_reqid.dest10;
      vv_objet        := rec_reqid.objet;
      vv_corps        := rec_reqid.corps;
      vv_attachement  := rec_reqid.attachement;
      vv_filename     := rec_reqid.filename;
      vv_cc           := rec_reqid.cc_mail;
    END LOOP;

    IF vv_destinataire IS NULL THEN
      RAISE e_pas_destinataire;
    END IF;

    g_step := 'ENVOI_AVEC_FICHIER 003 : CONNEXION.';
    log_msg(g_step);
    l_conn := utl_smtp.open_connection(gv_conn, 25);

    g_step := 'ENVOI_AVEC_FICHIER 004 : DEBUT CONSTRUCTION MAIL.';
    log_msg(g_step);
    utl_smtp.helo(l_conn, gv_conn);

    vr_reply := utl_smtp.mail(l_conn, vv_expediteur);
    g_step   := 'REPLY MAIL : ' || vr_reply.code || ' - ' || vr_reply.text;
    log_msg(g_step);

    --< OBE artf2283043
    /*vr_reply := utl_smtp.rcpt(l_conn, gv_plat_appro_mail);
    g_step   := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                vr_reply.text;
    log_msg(g_step);*/

    g_step := 'SEND_MAIL 003 : LISTE DESTINATAIRE';
    log_msg(g_step);

    vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire || '>');

    g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' || vr_reply.text;
    log_msg(g_step);

    log_msg('vv_destinataire2:'||vv_destinataire2);

    IF vr_reply.code != '250' THEN
      g_step := 'SEND_MAIL E03 : ERREUR SUR DESTINATAIRE : ' ||
                vv_destinataire;
      log_msg(g_step);
      IF vb_adress_valide = 0 THEN
        vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_expediteur || '>');

        g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
        log_msg(g_step);
        vv_adresses      := vv_adresses || ';' || vv_expediteur;
        vb_adress_valide := 1;

       END IF;
    ELSE
      IF vv_destinataire2 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire2 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         vv_adresses      := vv_adresses || ';' || vv_destinataire2;
         vb_adress_valide := 1;
      END IF;
       IF vv_destinataire3 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire3 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         vv_adresses      := vv_adresses || ';' || vv_destinataire3;
         vb_adress_valide := 1;
      END IF;
       IF vv_destinataire4 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire4 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         vv_adresses      := vv_adresses || ';' || vv_destinataire4;
         vb_adress_valide := 1;
      END IF;
       IF vv_destinataire5 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire5 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         vv_adresses      := vv_adresses || ';' || vv_destinataire5;
         vb_adress_valide := 1;
      END IF;
	  -- 15/09/2021 NBO artf07480820 - TASK0152735 Correctif sur l'envoi par mail de l'état DKA : Etat des prélèvements automatiques fournisseur
      IF vv_destinataire6 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire6 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         vv_adresses      := vv_adresses || ';' || vv_destinataire6;
         vb_adress_valide := 1;
      END IF;
      IF vv_destinataire7 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire7 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         vv_adresses      := vv_adresses || ';' || vv_destinataire7;
         vb_adress_valide := 1;
      END IF;
      IF vv_destinataire8 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire8 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         vv_adresses      := vv_adresses || ';' || vv_destinataire8;
         vb_adress_valide := 1;
      END IF;
      IF vv_destinataire9 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire9 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         vv_adresses      := vv_adresses || ';' || vv_destinataire9;
         vb_adress_valide := 1;
      END IF;
      IF vv_destinataire10 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire10 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         vv_adresses      := vv_adresses || ';' || vv_destinataire10;
         vb_adress_valide := 1;
      END IF;
      
      vv_adresses := vv_adresses || ';' || vv_destinataire;
    END IF;

    IF length(vv_adresses) > 1 THEN
      vv_adresses := substr(vv_adresses, 2);
      log_msg(substr('Adresse(s) destinataire(s)  : ' || vv_adresses,
                     1,
                     255));
    ELSE
      RAISE e_pas_destinataire;
    END IF;

    g_step := 'ENVOI_AVEC_FICHIER 004 : DEBUT CONSTRUCTION MAIL.';
    log_msg(g_step);

    utl_smtp.open_data(l_conn);
    l_mesg := 'Date: ' || to_char(systimestamp,
                                  'dd Mon yyyy hh24:mi:ss tzhtzm',
                                  'NLS_DATE_LANGUAGE=American') ||
              utl_tcp.crlf || 'From: ' || vv_expediteur || utl_tcp.crlf ||
              'To: ' || vv_adresses /*gv_plat_appro_mail*/ || utl_tcp.crlf;
              
    IF TRIM(vv_cc) IS NOT NULL THEN
      -- 15/09/2021 NBO artf07480820 - TASK0152735 Correctif sur l'envoi par mail de l'état DKA : Etat des prélèvements automatiques fournisseur
      l_mesg := l_mesg || 'Cc: ' || REPLACE(vv_cc, ',', ';') || UTL_TCP.crlf;
      log_msg('ENVOI_AVEC_FICHIER : CC :' || vv_cc);
    END IF;
    
    l_mesg := l_mesg || 'Subject:' || vv_objet || utl_tcp.crlf ||
              'Reply-To: ' || vv_expediteur || utl_tcp.crlf ||
              'Return-Path: ' || vv_expediteur || utl_tcp.crlf ||
              'MIME-Version: 1.0' || utl_tcp.crlf || 'Content-Type: ' ||
              multipart_mime_type || utl_tcp.crlf || utl_tcp.crlf;
    utl_smtp.write_data(l_conn, l_mesg);
    -- Insertion du corps du message
    BEGIN
      begin_attachment(conn => l_conn, mime_type => 'text/html');
      utl_smtp.write_data(l_conn, vv_corps);
      end_attachment(conn => l_conn);
    END;

    g_step := 'ENVOI_AVEC_FICHIER 005 : Corps = ' || vv_corps ;
    log_msg(g_step);

    IF vv_attachement = 'O' THEN

      OPEN cur_file_name(p_req_id);
      LOOP
        FETCH cur_file_name
          INTO rec_file_name;
        EXIT WHEN cur_file_name%NOTFOUND;

        g_step := 'ENVOI_AVEC_FICHIER 006 ==> Attachement : ' ||
                  rec_file_name.file_name;
        log_msg(g_step);

        gn_amt    := 672 * 3;
        l_filepos := 1;

        begin_attachment(conn         => l_conn,
                         mime_type    => rec_file_name.mime_type,
                         inline       => TRUE,
                         filename     => nvl(vv_filename,rec_file_name.file_name),
                         transfer_enc => 'base64');

        l_file     := bfilename('DKA_SARG00C8_MAIL', rec_file_name.file_name);
        l_file_len := dbms_lob.getlength(l_file);
        l_modulo   := MOD(l_file_len, gn_amt);
        l_pieces   := trunc(l_file_len / gn_amt);
        l_buf      := NULL;

        IF (l_modulo <> 0) THEN
          l_pieces := l_pieces + 1;
        END IF;

        dbms_lob.fileopen(l_file, dbms_lob.file_readonly);
        dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
        l_data := NULL;
        FOR i IN 1 .. l_pieces LOOP
          l_filepos  := i * gn_amt + 1;
          l_file_len := l_file_len - gn_amt;
          l_data     := utl_raw.concat(l_data, l_buf);
          l_chunks   := trunc(utl_raw.length(l_data) / max_line_width);

          IF (i <> l_pieces) THEN
            l_chunks := l_chunks - 1;
          END IF;
          utl_smtp.write_raw_data(l_conn, utl_encode.base64_encode(l_data));
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
      END LOOP;
      CLOSE cur_file_name;

    END IF;

    utl_smtp.close_data(l_conn);
    utl_smtp.quit(l_conn);
    g_step := 'ENVOI_AVEC_FICHIER 005 ==> Mail BdC envoye a adresse : ' ||
              vv_adresses;
    log_msg(g_step);

    g_step := 'ENVOI_AVEC_FICHIER 099 : FIN';
    log_msg(g_step);
  EXCEPTION
    WHEN e_pas_destinataire THEN
      --Fermeture de la connexion
      IF l_conn.host IS NOT NULL THEN
        vr_reply := utl_smtp.quit(l_conn);
      END IF;

      pv_errbuf  := 'Pas de destinataire';
      pn_retcode := 2;
      dka_tools_pkg.put_debug_message(pv_errbuf);
      RAISE;
    WHEN OTHERS THEN
      pv_errbuf := 'ENVOI_AVEC_FICHIER 099 - ERREUR : ' || SQLERRM;
      log_msg(pv_errbuf); --JJA 2014/02/10
      pn_retcode := 2;
      RAISE; --JJA 2014/02/10 --Propagation de l'erreur
  END envoi_avec_fichier;

  -------------------------------------------------------------------------------------
  --  Nom           : envoi_mail
  --  Description   : Procédure principale du traitement "VE : Envoi par mail des fichiers de contrôle de pré-clôture".
  --
  --  PARAMETRES    :
  --  Pv_Errbuf      IN OUT       Message d'avertissement
  --  Pn_Retcode  IN OUT     Code erreur
  --  pv_expediteur IN  Expediteur
  --  pv_destinataire IN Destinataire
  --  pv_objet    IN  Objet
  --  pv_corps    IN  Corps
  --  P_Req_Id    IN       Numéro de requête
  --------------------------------------------------------------------------------------
  PROCEDURE envoi_mail(pv_errbuf  IN OUT VARCHAR2,
                       pn_retcode IN OUT NUMBER,
                       p_req_id   IN NUMBER) IS

    cn_tempo CONSTANT NUMBER := 20;
    vv_rphase     VARCHAR2(80);
    vv_rstatus    VARCHAR2(80);
    vv_dphase     VARCHAR2(30);
    vv_dstatus    VARCHAR2(30);
    vv_message    VARCHAR2(240);
    vb_validation BOOLEAN;

    e_edition_output_mail EXCEPTION;
  BEGIN
    g_step := 'ENVOI_MAIL 000 : DEBUT';
    log_msg(g_step);
    -- Recherche des arguments lors de l'exécution du traitement "VE : Edition des fichiers de contrôle de pré-clôture".
    g_step := 'ENVOI_MAIL 001 : RECHERCHE DES ARGUMENTS DU TRAITEMENT.';
    log_msg(g_step);

    -- Initialisation des variables d'envoi de mail :
    g_step := 'ENVOI_MAIL 003 : INITIALISATION DES VARIABLES D''ENVOI DE MAIL.';
    log_msg(g_step);
    init(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      g_step := 'ENVOI_MAIL 003 : ERROR - INITIALISATION DES VARIABLES D''ENVOI DE MAIL.';
      RAISE e_envoi_mail;
    END IF;

    IF NOT fnd_concurrent.wait_for_request(p_req_id,
                                           cn_tempo,
                                           0,
                                           vv_rphase,
                                           vv_rstatus,
                                           vv_dphase,
                                           vv_dstatus,
                                           vv_message) THEN
      vb_validation := TRUE;
    ELSE
      IF vv_dstatus = 'WARNING' THEN
        log_msg(chr(10) || '>>> Traitement termine en Warning ');
        vb_validation := FALSE;
      ELSIF vv_dstatus != 'NORMAL' THEN
        log_msg(chr(10) || '>>> Traitement termine en Erreur ');
        vb_validation := FALSE;
      ELSE
        vb_validation := TRUE;
      END IF;
    END IF;

    IF vb_validation THEN

      g_step := 'ENVOI_MAIL 004 : PARCOUR DE L''ENSEMBLE DES FICHIERS POUR L''ENVOI PAR MAIL.';
      log_msg(g_step);

      -- Initialisation du message contenant un fichier.
      g_step := 'ENVOI_MAIL 005.a : ENVOI DU MESSAGE AVEC FICHIER.';
      log_msg(g_step);
      envoi_avec_fichier(pv_errbuf,
                         pn_retcode,
                         p_req_id);

    END IF;

    g_step := 'ENVOI_MAIL 999 : FIN';
    log_msg(g_step);
  EXCEPTION
    WHEN e_edition_output_mail THEN
      pv_errbuf  := 'Erreur procedure EDITION_OUTPUT_MAIL';
      pn_retcode := 2;
      log_msg(pv_errbuf);
    WHEN e_mail THEN
      log_msg(pv_errbuf);
      pn_retcode := 2;
    WHEN e_envoi_mail THEN
      log_msg('ERREUR - ' || g_step);
      pv_errbuf := 'ERREUR : ' || SQLERRM;
      log_msg(pv_errbuf);
      pn_retcode := 2;
    WHEN OTHERS THEN
      log_msg('ERREUR - ' || g_step);
      pv_errbuf := 'ERREUR : ' || SQLERRM;
      log_msg(pv_errbuf);
      pn_retcode := 2;
  END envoi_mail;

END dka_mail_pkg;
/
SHOW ERRORS;
EXIT
