CREATE OR REPLACE PACKAGE BODY APPS.DKA_SEND_MAIL_PKG AS

     ----------------------------------------------------------------------------------------------
     -- $ $
     --
     -- NOM               : DKA_SEND_MAIL_PKG.pks
     -- DESCRIPTION       : DKA_SEND_MAIL_PKG package body : fonctions d'envoi de mail
     ---
     --- AUTEUR           : J. JARDEZ
     --- DATE DE CREATION : 25/03/2014
     --- DOC. ASSOCIEE    :
     ---
     ----------------------------------------------------------------------------------------------
     --- NOM DU PROGRAMME :
     --- PARAMETRES       :
     ---
     --- HISTORIQUE DES MODIFICATIONS
     --- Date       Qui Description
     --- ---------- --- -------------------------------------------------------------------------
     --- 12/01/2014 BCO DPE20140058 : Dakota - Relevés Bancaires pour CSP. Modification du package d?envoi de mail.
     --- 07/03/2019 MTIA artf07217600 : Modification convert_type format csv
     --------------------------------------------------------------------------------------------

     BOUNDARY       CONSTANT VARCHAR2(256) := '=_NextPart_DC7E1BB5_1105_4DB3_BAE3_2A6208EB099D';
     FIRST_BOUNDARY CONSTANT VARCHAR2(256) := '--' || BOUNDARY ||
                                              utl_tcp.CRLF;
     LAST_BOUNDARY  CONSTANT VARCHAR2(256) := '--' || BOUNDARY || '--' ||
                                              utl_tcp.CRLF;

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
          --dbms_output.put_line('LOG : '||substr(l_message,1,253));
     END log_msg;

     -----------------------------------------------------------------
     --  Nom           : CONVERT_TYPE_MIME
     --  Description   : fonction qui retourne le type mime
     --
     --  PARAMETRES :
     --
     -----------------------------------------------------------------
     FUNCTION convert_type_mime(pv_extension VARCHAR2) return VARCHAR2 IS

          vv_type_mime VARCHAR2(50);
          vv_extension VARCHAR2(50);

     BEGIN

          vv_extension := pv_extension;

          CASE
               WHEN vv_extension = 'dwg' THEN
                    vv_type_mime := 'application/acad';
               WHEN vv_extension = 'ccad' THEN
                    vv_type_mime := 'application/clariscad';
               WHEN vv_extension = 'drw' THEN
                    vv_type_mime := 'application/drafting';
               WHEN vv_extension = 'dxf' THEN
                    vv_type_mime := 'application/dxf';
               WHEN vv_extension = 'unv' THEN
                    vv_type_mime := 'application/i-deas';
               WHEN vv_extension in ('igs', 'iges') THEN
                    vv_type_mime := 'application/iges';
               WHEN vv_extension = 'bin' THEN
                    vv_type_mime := 'application/octet-stream';
               WHEN vv_extension = 'oda' THEN
                    vv_type_mime := 'application/oda';
               WHEN vv_extension = 'pdf' THEN
                    vv_type_mime := 'application/pdf';
               WHEN vv_extension in ('ai', 'eps', 'ps') THEN
                    vv_type_mime := 'application/postscript';
               WHEN vv_extension = 'prt' THEN
                    vv_type_mime := 'application/pro_eng';
               WHEN vv_extension = 'rtf' THEN
                    vv_type_mime := 'application/rtf';
               WHEN vv_extension = 'set' THEN
                    vv_type_mime := 'application/set';
               WHEN vv_extension = 'stl' THEN
                    vv_type_mime := 'application/sla';
               WHEN vv_extension = 'dwg' THEN
                    vv_type_mime := 'application/solids';
               WHEN vv_extension = 'step' THEN
                    vv_type_mime := 'application/step';
               WHEN vv_extension = 'vda' THEN
                    vv_type_mime := 'application/vda';
               WHEN vv_extension = 'mif' THEN
                    vv_type_mime := 'application/x-mif';
               WHEN vv_extension = 'dwg' THEN
                    vv_type_mime := 'application/x-csh';
               WHEN vv_extension = 'dvi' THEN
                    vv_type_mime := 'application/x-dvi';
               WHEN vv_extension = 'hdf' THEN
                    vv_type_mime := 'application/hdf';
               WHEN vv_extension = 'latex' THEN
                    vv_type_mime := 'application/x-latex';
               WHEN vv_extension in ('nc', 'cdf') THEN
                    vv_type_mime := 'application/x-netcdf';
               WHEN vv_extension = 'dwg' THEN
                    vv_type_mime := 'application/x-sh';
               WHEN vv_extension = 'tcl' THEN
                    vv_type_mime := 'application/x-tcl';
               WHEN vv_extension = 'tex' THEN
                    vv_type_mime := 'application/x-tex';
               WHEN vv_extension in ('texinfo', 'texi') THEN
                    vv_type_mime := 'application/x-texinfo';
               WHEN vv_extension in ('t', 'tr', 'troff') THEN
                    vv_type_mime := 'application/x-troff';
               WHEN vv_extension = 'man' THEN
                    vv_type_mime := 'application/x-troff-man';
               WHEN vv_extension = 'me' THEN
                    vv_type_mime := 'application/x-troff-me';
               WHEN vv_extension = 'ms' THEN
                    vv_type_mime := 'application/x-troff-ms';
               WHEN vv_extension = 'src' THEN
                    vv_type_mime := 'application/x-wais-source';
               WHEN vv_extension = 'bcpio' THEN
                    vv_type_mime := 'application/x-bcpio';
               WHEN vv_extension = 'cpio' THEN
                    vv_type_mime := 'application/x-cpio';
               WHEN vv_extension = 'gtar' THEN
                    vv_type_mime := 'application/x-gtar';
               WHEN vv_extension = 'shar' THEN
                    vv_type_mime := 'application/x-shar';
               WHEN vv_extension = 'sv4cpio' THEN
                    vv_type_mime := 'application/x-sv4cpio';
               WHEN vv_extension = 'sc4crc' THEN
                    vv_type_mime := 'application/x-sv4crc';
               WHEN vv_extension = 'tar' THEN
                    vv_type_mime := 'application/x-tar';
               WHEN vv_extension = 'man' THEN
                    vv_type_mime := 'application/x-ustar';
               WHEN vv_extension = 'man' THEN
                    vv_type_mime := 'application/zip';
               WHEN vv_extension = 'au,snd' THEN
                    vv_type_mime := 'audio/basic';
               WHEN vv_extension in ('aif', 'aiff', 'aifc') THEN
                    vv_type_mime := 'audio/x-aiff';
               WHEN vv_extension = 'wav' THEN
                    vv_type_mime := 'audio/x-wav';
               WHEN vv_extension = 'man' THEN
                    vv_type_mime := 'image/gif';
               WHEN vv_extension = 'ief' THEN
                    vv_type_mime := 'image/ief';
               WHEN vv_extension in ('jpg', 'jpeg', 'jpe') THEN
                    vv_type_mime := 'image/jpeg';
               WHEN vv_extension in ('tiff', 'tif') THEN
                    vv_type_mime := 'image/tiff';
               WHEN vv_extension = 'cmu' THEN
                    vv_type_mime := 'image/x-cmu-raster';
               WHEN vv_extension = 'pnm' THEN
                    vv_type_mime := 'image/x-portable-anymap';
               WHEN vv_extension = 'pbm' THEN
                    vv_type_mime := 'image/x-portable-bitmap';
               WHEN vv_extension = 'pgm' THEN
                    vv_type_mime := 'image/x-portable-graymap';
               WHEN vv_extension = 'ppm' THEN
                    vv_type_mime := 'image/x-portable-pixmap';
               WHEN vv_extension = 'rgb' THEN
                    vv_type_mime := 'image/x-rgb';
               WHEN vv_extension = 'xbm' THEN
                    vv_type_mime := 'image/x-xbitmap';
               WHEN vv_extension = 'xpm' THEN
                    vv_type_mime := 'image/x-xpixmap';
               WHEN vv_extension = 'man' THEN
                    vv_type_mime := 'image/x-xwindowdump';
               WHEN vv_extension = 'zip' THEN
                    vv_type_mime := 'multipart/x-zip';
               WHEN vv_extension in ('gz', 'gzip') THEN
                    vv_type_mime := 'multipart/x-gzip';
               WHEN vv_extension in ('htm', 'html') THEN
                    vv_type_mime := 'text/html';
               WHEN vv_extension in
                    ('txt', 'g', 'h', 'c', 'cc', 'hh', 'm', 'f90') THEN
                    vv_type_mime := 'text/plain';
               WHEN vv_extension = 'rtx' THEN
                    vv_type_mime := 'text/richtext';
               WHEN vv_extension = 'tsv' THEN
                    vv_type_mime := 'text/tab-separated-value';
                WHEN vv_extension = 'csv' THEN
                    vv_type_mime := 'text/csv';      
               WHEN vv_extension = 'etx' THEN
                    vv_type_mime := 'text/x-setext';
               WHEN vv_extension in ('mpeg', 'mpg', 'mpe') THEN
                    vv_type_mime := 'video/mpeg';
               WHEN vv_extension in ('qt', 'mov') THEN
                    vv_type_mime := 'video/quicktime';
               WHEN vv_extension = 'avi' THEN
                    vv_type_mime := 'video/msvideo';
               WHEN vv_extension = 'movie' THEN
                    vv_type_mime := 'video/x-sgi-movie';
               ELSE
                    vv_type_mime := 'text/plain';
          END CASE;

          return vv_type_mime;

     END convert_type_mime;

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
          utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Type: ' ||
                                                       mime_type ||
                                                       utl_tcp.CRLF));
          IF (filename IS NOT NULL) THEN
               IF (inline) THEN
                    utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Disposition: ' ||
                                                                 'inline; filename="' ||
                                                                 filename || '"' ||
                                                                 utl_tcp.CRLF));
               ELSE
                    utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Disposition: ' ||
                                                                 'attachment; filename="' ||
                                                                 filename || '"' ||
                                                                 utl_tcp.CRLF));
               END IF;
          END IF;
          IF (transfer_enc IS NOT NULL) THEN
               utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Transfer-Encoding: ' ||
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

     -- -----------------------------------------------------------------------------
     -- Nom              : send_mail
     -- Description      : Procédure d'envoi de mail
     --
     -- PARAMETRES       : Pn_Request_Id      Sortie Numéro de traitement lancé
     --                    Pv_Errbuf          Sortie Message d'erreur
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
     PROCEDURE Send_Mail(Pv_Errbuf             OUT VARCHAR2,
                         Pn_Retcode            OUT NUMBER,
                         Pv_connexion          IN VARCHAR2, --Connexion
                         Pv_expediteur         IN VARCHAR2, --Expéditeur
                         Pv_retour_mail        IN VARCHAR2, --Mail de retour
                         Pv_liste_destinataire IN VARCHAR2, --JDV des destinataires
                         Pv_message_subject    IN VARCHAR2, --Texte a mettre en objet
                         Pv_message_corps      IN VARCHAR2, --Texte a mettre dans le corps
                         Pv_directory          IN VARCHAR2, --Nom de a directory a utiliser pour ajouter les fichiers joints
                         Pv_liste_fichier      IN VARCHAR2, --Listes des fichiers séparés par des '/'
                         Pv_JDV_Attribute1     IN VARCHAR2 DEFAULT NULL --Cuf Attribute1 JDV des destinataires
                         ) IS

          vv_step VARCHAR2(500);

          vc_conn UTL_SMTP.CONNECTION;

          vr_reply   UTL_SMTP.REPLY;
          vr_replies UTL_SMTP.REPLIES;

          vv_directory_path VARCHAR2(4000);
          vv_liste_fichier  VARCHAR2(4000);
          vv_fichier        VARCHAR2(255);
          vv_extension      VARCHAR2(10);
          vv_separateur CONSTANT VARCHAR2(1) := '/';

          l_file     BFILE;
          l_file_len PLS_INTEGER;
          l_modulo   PLS_INTEGER;
          l_pieces   PLS_INTEGER;
          l_filepos  PLS_INTEGER := 1; /* pointeur pour le fichier */
          l_buf      RAW(2100);
          l_data     RAW(2100);
          l_chunks   PLS_INTEGER;
          gn_amt     BINARY_INTEGER := 672 * 3;
          MULTIPART_MIME_TYPE CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary=' ||
                                                        BOUNDARY;
          MAX_LINE_WIDTH PLS_INTEGER := 54;

          vv_retour_mail VARCHAR2(500);
          vv_adresses    VARCHAR2(32000);
          vv_mesg        VARCHAR2(32000);

          vb_adress_valide NUMBER;

          e_pas_connexion EXCEPTION;
          e_pas_expediteur EXCEPTION;
          e_pas_objet EXCEPTION;
          e_pas_destinataire EXCEPTION;
          e_pas_corps EXCEPTION;

          CURSOR c_liste_destinataire IS
               SELECT ffvv.description adresse
                 FROM fnd_flex_value_sets ffvs, fnd_flex_values_vl ffvv
                WHERE ffvs.flex_value_set_name = Pv_liste_destinataire
                  AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                  AND ffvv.enabled_flag = 'Y'
                  AND SYSDATE BETWEEN NVL(ffvv.start_date_active, SYSDATE) AND
                      NVL(ffvv.end_date_active, SYSDATE)
                  AND (ffvv.ATTRIBUTE1 IS NULL OR
                      ffvv.ATTRIBUTE1 =
                      nvl(Pv_JDV_Attribute1, ffvv.ATTRIBUTE1));

          ----------------------------------------------------------------------------
          ----------------------------------------------------------------------------

     BEGIN
          vb_adress_valide := 0;
          vv_step          := 'SEND_MAIL 000 : INIT';
          log_msg(vv_step);
          Pv_Errbuf  := '';
          Pn_Retcode := 0;

          --Vérification des paramétres obligatoires
          IF Pv_connexion IS NULL THEN
               RAISE e_pas_connexion;
          END IF;
          IF Pv_expediteur IS NULL THEN
               RAISE e_pas_expediteur;
          END IF;
          IF Pv_liste_destinataire IS NULL THEN
               RAISE e_pas_destinataire;
          END IF;
          IF Pv_message_subject IS NULL THEN
               RAISE e_pas_objet;
          END IF;
          IF Pv_message_corps IS NULL THEN
               RAISE e_pas_corps;
          END IF;

          IF Pv_retour_mail IS NOT NULL THEN
               vv_retour_mail := Pv_retour_mail;
          ELSE
               vv_retour_mail := Pv_expediteur;
          END IF;

          vv_step := 'SEND_MAIL 001 : Connexion';
          log_msg(vv_step);
          vr_reply := utl_smtp.open_connection(Pv_connexion, 25, vc_conn);
          vv_step  := 'REPLY OPEN_CONNECTION : ' || vr_reply.code || ' - ' ||
                      vr_reply.text; --log_msg(vv_step);

          vv_step := 'SEND_MAIL 002 : EHLO';
          log_msg(vv_step);
          vr_replies := utl_smtp.ehlo(vc_conn, Pv_connexion);
          IF vr_replies.COUNT > 0 THEN
               FOR i IN vr_replies.FIRST .. vr_replies.LAST LOOP
                    vv_step := 'REPLY EHLO ' || i || ' : ' || vr_replies(i)
                              .code || ' - ' || vr_replies(i).text; --log_msg(vv_step);
               END LOOP;
          END IF;

          vv_step := 'SEND_MAIL 002 : MAIL';
          log_msg(vv_step);
          vr_reply := utl_smtp.mail(vc_conn, '<' || Pv_expediteur || '>');
          vv_step  := 'REPLY MAIL : ' || vr_reply.code || ' - ' ||
                      vr_reply.text; --log_msg(vv_step);

          vv_step := 'SEND_MAIL 003 : LISTE DESTINATAIRE';
          log_msg(vv_step);
          FOR ligne IN c_liste_destinataire LOOP

               vr_reply := utl_smtp.rcpt(vc_conn, '<' || ligne.adresse || '>');

               vv_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                          vr_reply.text;
               log_msg(vv_step);

               IF vr_reply.code != '250' THEN
                    vv_step := 'SEND_MAIL E03 : ERREUR SUR DESTINATAIRE : ' ||
                               ligne.adresse;
                    log_msg(vv_step);
                    IF vb_adress_valide = 0 THEN
                         vr_reply := utl_smtp.rcpt(vc_conn, '<' ||
                                                    vv_retour_mail || '>');

                         vv_step := 'REPLY RCPT : ' || vr_reply.code ||
                                    ' - ' || vr_reply.text;
                         log_msg(vv_step);
                         vv_adresses      := vv_adresses || ';' ||
                                             vv_retour_mail;
                         vb_adress_valide := 1;
                    END IF;
               ELSE
                    vv_adresses := vv_adresses || ';' || ligne.adresse;
               END IF;

          END LOOP;

          --On retire le 1er ;
          IF LENGTH(vv_adresses) > 1 THEN
               vv_adresses := SUBSTR(vv_adresses, 2);
               log_msg(substr('Adresse(s) destinataire(s)  : ' ||
                              vv_adresses, 1, 255));
          ELSE
               RAISE e_pas_destinataire;
          END IF;

          vv_step := 'SEND_MAIL 004 : OPEN_DATA';
          log_msg(vv_step);
          vr_reply := utl_smtp.open_data(vc_conn);
          vv_step  := 'REPLY OPEN_DATA : ' || vr_reply.code || ' - ' ||
                      vr_reply.text; --log_msg(vv_step);

          vv_mesg := 'Date: ' ||
                     to_char(systimestamp, 'dd Mon yyyy hh24:mi:ss tzhtzm', 'NLS_DATE_LANGUAGE=American') ||
                     utl_tcp.CRLF || 'From: ' || Pv_expediteur ||
                     utl_tcp.CRLF || 'To: ' || vv_adresses || utl_tcp.CRLF ||
                     'Subject: ' || Pv_message_subject || utl_tcp.CRLF ||
                     'Reply-To: ' || vv_retour_mail || utl_tcp.CRLF ||
                     'Return-Path: ' || vv_retour_mail || utl_tcp.CRLF ||
                     'MIME-Version: 1.0' || utl_tcp.CRLF ||
                     'Content-Type: ' || MULTIPART_MIME_TYPE ||
                     utl_tcp.CRLF || utl_tcp.CRLF;

          utl_smtp.write_data(vc_conn, vv_mesg);

          -- Insertion du corps du message
          vv_step := 'SEND_MAIL 005 : Insertion du corps du message';
          log_msg(vv_step);
          BEGIN
               begin_attachment(conn => vc_conn, mime_type => 'text/html');
               utl_smtp.write_data(vc_conn, Pv_message_corps);
               end_attachment(conn => vc_conn);
          END;

          -- Insertion des fichiers
          vv_step := 'SEND_MAIL 006 : Insertion des fichiers';
          log_msg(vv_step);
          IF Pv_directory is not null AND Pv_liste_fichier IS NOT NULL THEN
               vv_liste_fichier := Pv_liste_fichier || vv_separateur;

               vv_step := 'SEND_MAIL 007 : Recherche du chemin de la directory';
               log_msg(vv_step);
               SELECT ad.directory_path
                 INTO vv_directory_path
                 FROM all_directories ad
                WHERE ad.directory_name = Pv_directory;

               vv_step := 'SEND_MAIL 008 : Parcours des fichiers';
               log_msg(vv_step);
               WHILE vv_liste_fichier IS NOT NULL LOOP

                    vv_fichier := substr(vv_liste_fichier, 1, instr(vv_liste_fichier, vv_separateur) - 1);
                    vv_step    := 'SEND_MAIL 009 : fichier : ' ||
                                  vv_fichier;
                    log_msg(vv_step);

                    vv_liste_fichier := substr(vv_liste_fichier, instr(vv_liste_fichier, vv_separateur) + 1);

                    vv_step := 'SEND_MAIL 010 : Piece jointe';
                    log_msg(vv_step);
                    vv_extension := substr(vv_fichier, instr(vv_fichier, '.', -1) + 1);
                    l_filepos    := 1;
                    gn_amt       := 672 * 3;

                    BEGIN
                         begin_attachment(conn => vc_conn, mime_type => convert_type_mime(vv_extension), inline => TRUE, filename => vv_fichier, transfer_enc => 'base64');

                         BEGIN
                              l_file     := BFILENAME(Pv_directory, vv_fichier);
                              l_file_len := dbms_lob.getlength(l_file);
                              l_modulo   := mod(l_file_len, gn_amt);
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
                                   l_chunks   := trunc(utl_raw.length(l_data) /
                                                       MAX_LINE_WIDTH);

                                   IF (i <> l_pieces) THEN
                                        l_chunks := l_chunks - 1;
                                   END IF;

                                   utl_smtp.write_raw_data(vc_conn, utl_encode.base64_encode(l_data));
                                   l_data := NULL;

                                   IF (l_file_len < gn_amt AND
                                      l_file_len > 0) THEN
                                        gn_amt := l_file_len;
                                   END IF;

                                   IF l_pieces > 1 THEN
                                        dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
                                   END IF;

                              END LOOP;

                         END;
                         dbms_lob.fileclose(l_file);

                         end_attachment(conn => vc_conn);
                    END; -- Fin de l'insertion de la piece jointe

               END LOOP;

          END IF;

          vv_step := 'ENVOI_MAIL 010 : Fermeture des attachements';
          log_msg(vv_step);
          end_attachment(conn => vc_conn, last => TRUE);

          --Envoi du mail
          vv_step := 'SEND_MAIL 011 : Envoi du mail';
          log_msg(vv_step);
          vr_reply := utl_smtp.close_data(vc_conn);
          vv_step  := 'REPLY CLOSE_DATA : ' || vr_reply.code || ' - ' ||
                      vr_reply.text; -- log_msg(vv_step);

          vr_reply := utl_smtp.quit(vc_conn);
          vv_step  := 'REPLY QUIT : ' || vr_reply.code || ' - ' ||
                      vr_reply.text; -- log_msg(vv_step);

     EXCEPTION
          WHEN e_pas_connexion THEN
               Pv_Errbuf  := 'Pas de connexion';
               Pn_Retcode := 2;
               Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
               RAISE;
          WHEN e_pas_expediteur THEN
               Pv_Errbuf  := 'Pas d''expéditeur';
               Pn_Retcode := 2;
               Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
               RAISE;
          WHEN e_pas_objet THEN
               Pv_Errbuf  := 'Pas d''objet';
               Pn_Retcode := 2;
               Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
               RAISE;
          WHEN e_pas_destinataire THEN
               --Fermeture de la connexion
               IF vc_conn.host IS NOT NULL THEN
                    vr_reply := utl_smtp.quit(vc_conn);
               END IF;

               Pv_Errbuf  := 'Pas de destinataire';
               Pn_Retcode := 2;
               Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
               RAISE;
          WHEN e_pas_corps THEN
               Pv_Errbuf  := 'Pas de corps';
               Pn_Retcode := 2;
               Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
               RAISE;
          WHEN OTHERS THEN
               --Fermeture de la connexion
               IF vc_conn.host IS NOT NULL THEN
                    vr_reply := utl_smtp.quit(vc_conn);
               END IF;

               Pn_Retcode := 2;
               Pv_Errbuf  := 'Erreur dans la procécure Send_Mail : ' ||
                             vv_step || chr(10) || Substr(SQLERRM, 1, 80);
               Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
               RAISE;
     END Send_Mail;


----------------------------------------------------------------------------
--  Nom           : mail_test
--  Description   : Procedure mail_test
--
--PARAMETRES :
--  pv_mail_test   Entree   Mail de test
--  pv_mail_cible  Sortie   Mail cible
----------------------------------------------------------------------------
    PROCEDURE mail_test (pv_mail_test    IN    VARCHAR2,
                         pv_mail_cible   OUT   VARCHAR2) IS
      vv_base_prod     VARCHAR2(100);
      vv_base          VARCHAR2(100);

      vv_errbuf   VARCHAR2(500);
      vn_retcode  NUMBER := 0;

      rec_param   dka_parameters%ROWTYPE;
      e_err_param EXCEPTION;
    BEGIN

      --Recuperation du type de la base
      Dka_Tools_Pkg.get_parameter ('TOOLS', 'BASE_PRODUCTION', rec_param, vn_retcode, vv_errbuf);
      vv_base_prod := rec_param.varchar2_value;

      IF vn_retcode != 0 THEN
        Raise_Application_Error (-20999, 'Erreur lors de la récupération du nom de la base de production : TOOLS / BASE_PRODUCTION');
      END IF;

      BEGIN
        SELECT name
        INTO vv_base
        FROM v$database;
      EXCEPTION
       WHEN OTHERS THEN
        Raise_Application_Error (-20998, 'Erreur lors de la récupération du nom de la base actuelle');
      END;

      IF vv_base != vv_base_prod THEN
        pv_mail_cible := nvl(pv_mail_test,'MAIL_TEST@BASE.TEST');
      ELSE
        pv_mail_cible := pv_mail_test;
      END IF;

    END mail_test;

-----------------------------------------------------------------
-- Debut du corps de package                                   --
-----------------------------------------------------------------
BEGIN
     gv_debug_mode := Fnd_Profile.VALUE('DKA_DEBUG_MODE');
END DKA_SEND_MAIL_PKG; -- package body
/

SHOW ERRORS PACKAGE BODY DKA_SEND_MAIL_PKG; 
EXIT