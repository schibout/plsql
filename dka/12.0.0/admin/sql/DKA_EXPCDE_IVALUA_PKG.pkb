create or replace PACKAGE BODY DKA_EXPCDE_IVALUA_PKG IS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_EXPCDE_IVALUA_PKG.pkb
    -- DESCRIPTION      : DKA_EXPCDE_IVALUA_PKG Package Body
    --
    -- AUTEUR           : Anas RAOUF (Capgemini)
    -- DATE DE CREATION : 26/11/2020
    -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
    -- -----------------------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- -----------------------------------------------------------------------------	

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    gv_request_id      VARCHAR2(30) := fnd_global.CONC_REQUEST_ID;
    gv_created_by      VARCHAR2(60) := fnd_profile.value('USER_NAME');
	g_user_id          PLS_INTEGER  := fnd_profile.value('USER_ID');
    gv_expediteur      VARCHAR2(150);
    gv_conn            VARCHAR2(30);
    g_step             VARCHAR2(500);
    gv_directory_path  VARCHAR2(4000);
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

    E_FATAL_ERROR EXCEPTION;
     PRAGMA EXCEPTION_INIT(E_FATAL_ERROR, -20012);
     K_FATAL_ERROR_NUM CONSTANT NUMBER := -20012;
    -- Variable contenant l'entête et le corps du mail.
    gv_objet VARCHAR2(4000);
    gv_corps VARCHAR2(4000);

	vg_SEPARATOR     CONSTANT VARCHAR2(2) := '|';
	vg_nbl_extr_cmd  number:=0;
	vg_DIRECTORY     CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';
	vg_directory_path  varchar2(100);
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

        Dka_Tools_Pkg.get_parameter('SCTRLMODULE',
                                    'EXPEDITEUR_MAIL',
                                    rec_param,
                                    p_errbuf,
                                    p_retcode);
        gv_expediteur := rec_param.varchar2_value;

        IF gv_expediteur IS NULL THEN
            RAISE e_expediteur_vide;
        END IF;

        SELECT name INTO gv_base FROM v$database;

        Dka_Tools_Pkg.get_parameter('SCTRLMODULE',
                                    'SMTP_CONNECTION',
                                    rec_param,
                                    p_errbuf,
                                    p_retcode);
        gv_conn := rec_param.varchar2_value;
        
       /* Dka_Tools_Pkg.get_parameter('SCTRLMODULE',
                                'SMTP_CONNECTION',
                                rec_param,
                                Pv_Errbuf,
                                Pn_Retcode);
        vv_conn := rec_param.varchar2_value; */

        --Reinit des variables de sortie
        p_retcode := 0;
        p_errbuf  := '';

    EXCEPTION
        WHEN e_expediteur_vide THEN
            p_errbuf := 'Aucun expéditeur trouvé';
            DKA_TOOLS_PKG.put_log_message(p_errbuf);
            p_retcode := 2;
        WHEN OTHERS THEN
            p_errbuf := 'Erreur procedure INIT :' || g_step || chr(10) ||
                        SQLERRM;
            DKA_TOOLS_PKG.put_log_message(p_errbuf);
            p_retcode := 2;
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


    -------------------------------------------------------------------------------------
    --  Nom           : envoi_avec_fichier
    --  Description   : Envoi du message avec fichier.
    --
    --  PARAMETRES    :
    --  Pv_Errbuf      IN OUT       Message d'avertissement
    --  Pn_Retcode  IN OUT     Code erreur
    --  P_filename    IN       Nom Fichier
    --  P_nbre_lignes    IN    Nombre des lignes
    --------------------------------------------------------------------------------------
    PROCEDURE envoi_avec_fichier(Pv_Errbuf   IN OUT VARCHAR2,
                                 Pn_Retcode  IN OUT NUMBER,
                                 P_filename   IN VARCHAR2
                                 ) IS

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
        vr_reply   UTL_SMTP.REPLY;
		v_filename VARCHAR2(40);
		v_obj	   VARCHAR2(400);
		v_nbline  NUMBER; 
		vv_adresses    VARCHAR2(32000);	-- OBE artf2283043
		vv_adresses_cc    VARCHAR2(32000);	-- OBE artf2283043		
		vb_adress_valide NUMBER;        -- OBE artf2283043
		e_pas_destinataire EXCEPTION;   -- OBE artf2283043
		
        CURSOR c_liste_destinataire IS
               SELECT ffv.description adresse
                 from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
                where ffvs.flex_value_set_id = ffv.flex_value_set_id
                and ffvs.flex_value_set_name = 'DKA_MAIL_EXPCDE_TRANSFRS_IVALUA'
                  AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                  AND ffv.enabled_flag = 'Y'
                  ;



    BEGIN
        select distinct FILE_NAME, NB_LINE
				INTO v_filename, v_nbline
              from DKA_EXPCDE_IVALUA_FILE
             where FILE_NAME = P_filename;
			 

		vb_adress_valide := 0;
        g_step := 'ENVOI_AVEC_FICHIER 000 : DEBUT';
        log_msg(g_step);
        g_step := 'ENVOI_AVEC_FICHIER 001 : RECHERCHE DE L''OBJET DU MAIL.';
        log_msg(g_step);
        gv_objet := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_EXPCDE_IVALUA_OBJECT'
                                              );
        g_step   := 'ENVOI_AVEC_FICHIER 002 : RECHERCHE DU CORPS DU MAIL.';
        log_msg(g_step);
        gv_corps := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_EXPCDE_IVALUA_CORPS',
                                              'NOMBRE',
                                              v_nbline);

        g_step := 'ENVOI_AVEC_FICHIER 003 : CONNEXION.';
    log_msg(g_step);
        l_conn := utl_smtp.open_connection(gv_conn, 25);

        g_step := 'ENVOI_AVEC_FICHIER 004 : DEBUT CONSTRUCTION MAIL.';
    log_msg(g_step);
        utl_smtp.helo(l_conn, gv_conn);

        vr_reply := utl_smtp.mail(l_conn, gv_expediteur);
        g_step   := 'REPLY MAIL : ' || vr_reply.code || ' - ' ||
                    vr_reply.text;
    log_msg(g_step);



		  -- Liste des destinataires		
		  g_step := 'SEND_MAIL 003 : LISTE DESTINATAIRE';
		  log_msg(g_step);
		  FOR ligne IN c_liste_destinataire LOOP

			   vr_reply := utl_smtp.rcpt(l_conn, '<' || ligne.adresse || '>');

			   g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
						  vr_reply.text;
			   log_msg(g_step);

			   IF vr_reply.code != '250' THEN
					g_step := 'SEND_MAIL E03 : ERREUR SUR DESTINATAIRE : ' ||
							   ligne.adresse;
					log_msg(g_step);
					IF vb_adress_valide = 0 THEN
						 vr_reply := utl_smtp.rcpt(l_conn, '<' ||
													gv_expediteur || '>');

						 g_step := 'REPLY RCPT : ' || vr_reply.code ||
									' - ' || vr_reply.text;
						 log_msg(g_step);
						 vv_adresses      := vv_adresses || ';' ||
											 gv_expediteur;
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
			   -- exception
			   IF l_conn.host IS NOT NULL THEN
                    vr_reply := utl_smtp.quit(l_conn);
               END IF;

               Pv_Errbuf  := 'Pas de destinataire';
               Pn_Retcode := 1;
               Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
		  END IF;		
		

		IF Pn_Retcode <> 1 THEN
        utl_smtp.open_data(l_conn);
        l_mesg := 'Date: ' || to_char(systimestamp, 'dd Mon yyyy hh24:mi:ss tzhtzm', 'NLS_DATE_LANGUAGE=American') || utl_tcp.CRLF ||
                  'From: ' || gv_expediteur || utl_tcp.CRLF || 
				  'To: ' || vv_adresses/*gv_plat_appro_mail*/ || utl_tcp.CRLF ||
				   --decode( vv_adresses_cc, null, '',);
				 -- 'CC: ' || vv_adresses_cc/*gv_plat_appro_mail*/ || utl_tcp.CRLF ||
				 -- 'Subject:' || v_obj || utl_tcp.CRLF || 
                  'Subject:' || REPLACE(utl_encode.MIMEHEADER_ENCODE(gv_objet,'utf8'),CHR(13)||CHR(10),'') || utl_tcp.CRLF || 
				  'Reply-To: ' || gv_expediteur || utl_tcp.CRLF ||
				  'Return-Path: ' || gv_expediteur || utl_tcp.CRLF ||
                  'MIME-Version: 1.0' || utl_tcp.CRLF ||
				  'Content-Type: ' || MULTIPART_MIME_TYPE || utl_tcp.CRLF || utl_tcp.CRLF;
				  
        utl_smtp.write_data(l_conn, l_mesg);
        -- Insertion du corps du message
        BEGIN
            begin_attachment(conn => l_conn, mime_type => 'text/html');
            --utl_smtp.write_data(l_conn, gv_corps);
			utl_smtp.write_raw_data(l_conn,utl_raw.cast_to_raw(gv_corps));
            end_attachment(conn => l_conn);
        END;



            gn_amt     	:= 672 * 3;
			l_filepos	:= 1;

            begin_attachment(conn         => l_conn,
                             mime_type    => 'text/csv',
                             inline       => TRUE,
                             filename     => v_filename,
                             transfer_enc => 'base64');

			l_file     := BFILENAME('DKA_OUT_DIR', v_filename);
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
        g_step := 'ENVOI_AVEC_FICHIER 005 ==> Mail envoyé a (aux) adresse(s) : ' ||
                  vv_adresses;
        log_msg(g_step);
		
		END IF; -- p retcode

        g_step := 'ENVOI_AVEC_FICHIER 099 : FIN';
        log_msg(g_step);
		EXCEPTION
		WHEN e_pas_destinataire THEN
               --Fermeture de la connexion
               IF l_conn.host IS NOT NULL THEN
                    vr_reply := utl_smtp.quit(l_conn);
               END IF;

               Pv_Errbuf  := 'Pas de destinataire';
               Pn_Retcode := 1;
               Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
               RAISE;

        WHEN OTHERS THEN
            Pv_Errbuf  := 'ENVOI_AVEC_FICHIER 099 - ERREUR : ' || SQLERRM;
            log_msg(Pv_Errbuf); --JJA 2014/02/10
            Pn_Retcode := 2;
            RAISE; --JJA 2014/02/10 --Propagation de l'erreur
    END envoi_avec_fichier;

    -------------------------------------------------------------------------------------
    --  Nom           : recherche_mail
    --  Description   : Procédure de recherche de la liste des adresses mails de destination.
    --
    --  PARAMETRES    :
    --  Pv_Errbuf      IN OUT       Message d'avertissement
    --  Pn_Retcode    IN OUT     Code erreur
    --------------------------------------------------------------------------------------
    PROCEDURE recherche_mail(Pv_Errbuf  IN OUT VARCHAR2,
                             Pn_Retcode IN OUT NUMBER) IS
        -- Curseur de parcours des adresses mails :
        CURSOR Cur_email IS
            select ffv.flex_value, ffv.FLEX_VALUE_MEANING, ffv.DESCRIPTION
              from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
             where ffvs.flex_value_set_id = ffv.flex_value_set_id
               and ffvs.flex_value_set_name = 'DKA_MAIL_EXPCDE_TRANSFRS_IVALUA'
               and ffv.ENABLED_FLAG = 'Y'
               and nvl(ffv.START_DATE_ACTIVE, trunc(SYSDATE)) <=
                   trunc(SYSDATE)
               and nvl(ffv.END_DATE_ACTIVE, trunc(SYSDATE)) >=
                   trunc(SYSDATE)
               and ffv.SUMMARY_FLAG = 'N';

        Rec_email       Cur_email%ROWTYPE;
        vv_adresse_mail VARCHAR2(1000);
        vv_nom_mail     VARCHAR2(2000);
    BEGIN
        g_step := 'RECHERCHE_MAIL 000 : DEBUT';
        log_msg(g_step);
        -- Initialisation de la variable contenant la liste des adresses emails.
        vv_adresse_mail := NULL;
        OPEN Cur_email;
        LOOP
            FETCH Cur_email
                INTO Rec_email;
            EXIT WHEN Cur_email%NOTFOUND;
            vv_adresse_mail := vv_adresse_mail || ';<' ||
                               Rec_email.DESCRIPTION || '>';
            vv_nom_mail := vv_nom_mail || Rec_email.Flex_Value || '<' || Rec_email.DESCRIPTION || '>;';
        END LOOP;
        CLOSE Cur_email;
        gv_plat_appro_mail := substr(vv_adresse_mail,2);
        gv_nom_mail := vv_nom_mail;
        g_step             := 'RECHERCHE_MAIL 099 : FIN';
        log_msg(g_step);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            g_step     := 'RECHERCHE_MAIL 099 - ERROR : AUCUNE ADRESSE MAIL N''EST VALIDE DANS LE JEU DE VALEUR DKA_MAIL_EXPCDE_TRANSFRS_IVALUA';
            Pv_Errbuf  := g_step || ' - ERREUR : ' || SQLERRM;
            Pn_Retcode := 1;
            raise e_mail;
        WHEN OTHERS THEN
            g_step     := 'RECHERCHE_MAIL 099 - ERROR : PROCEDURE RECHERCHE_MAIL EN ERREUR';
            Pv_Errbuf  := g_step || ' - ERREUR : ' || SQLERRM;
            Pn_Retcode := 1;
            raise e_mail;
    END recherche_mail;

  -----------------------------------------------------------------
  --  NOM           : EDITION_OUTPUT_MAIL
  --  DESCRIPTION   : procedure d'edition du fichier de sortie pour l'envoi par mail
  --
  --  PARAMETRES :
  --
  --  P_RETCODE             code retour out
  --  P_ERRBUF              description de l'erreur out
  -----------------------------------------------------------------
  PROCEDURE edition_output_mail(p_errbuf        IN VARCHAR2,
                                p_retcode       IN NUMBER) IS

   l_appl       fnd_application.application_short_name%TYPE;
   l_prgm_name  fnd_conc_req_summary_v.PROGRAM%TYPE;

   l_out        VARCHAR2(4000);
   --l_ligne      VARCHAR2(100) := '+--------------------------------------------------------------';
   l_ligne      VARCHAR2(1000) := '+------------------------------------------------------------------------------------------+';

   -- Curseur de recherche de l'ensemble des adresses mail de destination :
   CURSOR cur_mail IS
		select ffv.flex_value, ffv.FLEX_VALUE_MEANING, ffv.DESCRIPTION
          from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
         where ffvs.flex_value_set_id = ffv.flex_value_set_id
           and ffvs.flex_value_set_name = 'DKA_MAIL_EXPCDE_TRANSFRS_IVALUA'
           and ffv.ENABLED_FLAG = 'Y'
           and nvl(ffv.START_DATE_ACTIVE, trunc(SYSDATE)) <=
               trunc(SYSDATE)
           and nvl(ffv.END_DATE_ACTIVE, trunc(SYSDATE)) >=
               trunc(SYSDATE)
           and ffv.SUMMARY_FLAG = 'N';

   rec_mail cur_mail%ROWTYPE;
  BEGIN

    g_step  := 'EDITION_OUTPUT_MAIL 000 : DEBUT';
    log_msg(g_step);

     --Recuperation des informations
     BEGIN
    --Récupération du nom de la base de données.
    SELECT name 
    INTO gv_base 
    FROM v$database;

      --Recuperation du nom de l'application.
      SELECT fa.application_short_name
      INTO l_appl
      FROM fnd_application fa
      WHERE fa.application_id = fnd_profile.VALUE('RESP_APPL_ID');

      --Recuperation du nom du programme.
      SELECT v.PROGRAM
      INTO l_prgm_name
      FROM fnd_conc_req_summary_v v
      WHERE v.REQUEST_ID =  fnd_global.CONC_REQUEST_ID;

    EXCEPTION
     WHEN OTHERS THEN
      l_appl := '';
    END;

    out_msg(l_ligne);
    --ENTETE
    l_out := 'TRAITEMENT      : '||l_prgm_name||chr(10)||
             'Traitement n°     : '||gv_request_id||chr(10)||
             'Programme lancé le : '||to_char(SYSDATE,'DD/MM/YYYY HH24:MI:SS');
    out_msg(l_out);
    out_msg(l_ligne);

	/* l_out := p_retcode;
	 out_msg(l_out);*/
	
	IF p_retcode = 0 THEN


  l_out := 'SUCCES : Le mail a été envoyé aux adresses suivantes ';out_msg(l_out);
 -- l_out := '------------------------';out_msg(l_out);
  OPEN cur_mail;
         LOOP
             FETCH cur_mail
                 INTO rec_mail;
			 EXIT WHEN cur_mail%NOTFOUND;
			  l_out := rec_mail.DESCRIPTION;out_msg(l_out);
	     END LOOP;
  CLOSE cur_mail;
  
  l_out := chr(10);out_msg(l_out);
  /*l_out := '------';out_msg(l_out);
  l_out := 'OBJET : ' || gv_objet;out_msg(l_out);
  out_msg(gv_corps);*/
    l_out := 'Fin normale du traitement. ';out_msg(l_out);
    l_out := chr(10);out_msg(l_out);
    g_step  := 'EDITION_OUTPUT_MAIL 999 : FIN';
    log_msg(g_step);
	
	ELSIF p_retcode = 2 THEN
	
	g_step  := 'EDITION_OUTPUT_MAIL  : FICHIER NON GENERE';
		log_msg(g_step);
	l_out := 'ECHEC : Le fichier d''export n''a pas pu être généré ';out_msg(l_out);
 
  
  l_out := chr(10);out_msg(l_out);
  /*l_out := '------';out_msg(l_out);
  l_out := 'OBJET : ' || gv_objet;out_msg(l_out);
  out_msg(gv_corps);*/
    l_out := 'Voir le journal du traitement pour avoir plus de détail sur l''anomalie rencontrée. ';out_msg(l_out);
    l_out := chr(10);out_msg(l_out);
    g_step  := 'EDITION_OUTPUT_MAIL 999 : FIN';
    log_msg(g_step);
	
	
	ELSIF p_retcode = 1 THEN
		
		g_step  := 'EDITION_OUTPUT_MAIL  : MAIL NON ENVOYE';
		log_msg(g_step);
		l_out := 'ECHEC : Le mail n''a pas pu être envoyé. ';out_msg(l_out);
  
		  l_out := chr(10);out_msg(l_out);
		  
			l_out := 'Voir le journal du traitement pour avoir plus de détail sur l''anomalie rencontrée. ';out_msg(l_out);
			l_out := chr(10);out_msg(l_out);
			g_step  := 'EDITION_OUTPUT_MAIL 999 : FIN';
			log_msg(g_step);
	
	END IF;
	
	------
	
    out_msg(l_ligne);
	l_out := 'Programme terminé le : '||to_char(SYSDATE,'DD/MM/YYYY HH24:MI:SS');out_msg(l_out);
	out_msg(l_ligne);
	

  EXCEPTION
   WHEN OTHERS THEN
   /* p_retcode := 2;
    p_errbuf  := 'Erreur procedure EDITION_OUTPUT_MAIL :'|| g_step ||chr(10)||SQLERRM;*/
    log_msg(p_errbuf);
  END edition_output_mail;

    -------------------------------------------------------------------------------------
    --  Nom           : send_mail
    --  Description   : Procédure principale du traitement "DKA : Envoi par mail des fichiers de situation Oracle du matin ".
    --
    --  PARAMETRES    :
    --  Pv_Errbuf      IN OUT       Message d'avertissement
    --  Pn_Retcode  IN OUT     Code erreur
    --  P_Req_Id    IN       Numéro de requête
    --------------------------------------------------------------------------------------
    PROCEDURE send_mail(Pv_Errbuf  IN OUT VARCHAR2,
                         Pn_Retcode IN OUT NUMBER,
                         P_filename   IN VARCHAR2) IS


        vn_file NUMBER;

		e_edition_output_mail EXCEPTION;
		e_edition_fichier_mail EXCEPTION;
    BEGIN
        g_step := 'ENVOI_MAIL 000 : DEBUT';
        log_msg(g_step);


        -- Initialisation des variables d'envoi de mail :
        g_step := 'ENVOI_MAIL 003 : INITIALISATION DES VARIABLES D''ENVOI DE MAIL.';
        log_msg(g_step);
        init(Pv_Errbuf, Pn_Retcode);
        IF Pn_Retcode != 0 THEN
            g_step := 'ENVOI_MAIL 003 : ERROR - INITIALISATION DES VARIABLES D''ENVOI DE MAIL.';
            raise e_envoi_mail;
        END IF;

        g_step := 'ENVOI_MAIL 004 : PARCOUR DE L''ENSEMBLE DES FICHIERS POUR L''ENVOI PAR MAIL.';
        log_msg(g_step);


		select count(1)
		  into vn_file
		  from DKA_EXPCDE_IVALUA_FILE
		 where FILE_NAME = P_filename; 

		IF vn_file = 0 THEN
			-- error le fichier n'a pas pu etre genere.
			RAISE e_edition_fichier_mail;
		ELSE

			envoi_avec_fichier(Pv_Errbuf,
							   Pn_Retcode,
							   P_filename);
		END IF;


		--------------------------------------------------------------------------------
		--Suppression des enregistrements dans la table contenant les noms des fichiers.
		--------------------------------------------------------------------------------
		BEGIN
			DELETE FROM DKA_EXPCDE_IVALUA_FILE WHERE FILE_NAME = P_filename;
		END;
		COMMIT;

		----------------------------------------------------------------
		--Edition fichier de sortie
		----------------------------------------------------------------
		g_step := 'ENVOI_MAIL 006 : EDITION FICHIER DE SORTIE.';
		log_msg(g_step);
		/*edition_output_mail(Pv_Errbuf,Pn_Retcode);
		IF Pn_Retcode != 0 THEN
			RAISE e_edition_output_mail;
		END IF;*/
        g_step := 'ENVOI_MAIL 999 : FIN';
        log_msg(g_step);
    EXCEPTION
		WHEN e_edition_output_mail THEN
			Pv_Errbuf  := 'Erreur procedure EDITION_OUTPUT_MAIL';
			Pn_Retcode := 2;
			log_msg(Pv_Errbuf);
        WHEN e_mail THEN
            log_msg(Pv_Errbuf);
            Pn_Retcode := 1;
        WHEN e_envoi_mail THEN
            log_msg('ERREUR - ' || g_step);
            Pv_Errbuf := 'ERREUR : ' || SQLERRM;
            log_msg(Pv_Errbuf);
            Pn_Retcode := 2;
		WHEN e_edition_fichier_mail THEN
			log_msg('ERREUR - ' || 'Le fichier n''a pas pu être généré ');
            Pv_Errbuf := 'ERREUR : ' || SQLERRM;
            log_msg(Pv_Errbuf);
            Pn_Retcode := 2;
        WHEN OTHERS THEN
            log_msg('ERREUR - ' || g_step);
            Pv_Errbuf := 'ERREUR : ' || SQLERRM;
            log_msg(Pv_Errbuf);
            Pn_Retcode := 2;
    END send_mail;

  -----------------------------------------------------------------
  --  NOM           : EDITION_OUTPUT
  --  DESCRIPTION   : procedure d'edition du fichier de sortie
  --
  --  PARAMETRES :
  --
  --  P_RETCODE             code retour out
  --  P_ERRBUF              description de l'erreur out
  --  P_ENTITE        nom de l'entité
  --  P_MODULE        nom du module
  --  P_N_REQUETE      numéro de la requête exécuté
  --  P_ENVOI_MAIL      flag d'envoi par mail des fichiers
  -----------------------------------------------------------------
  PROCEDURE edition_output(p_errbuf        OUT VARCHAR2,
                           p_retcode       OUT NUMBER,
						   p_filename     IN VARCHAR2) IS

   l_appl       fnd_application.application_short_name%TYPE;
   l_prgm_name  fnd_conc_req_summary_v.PROGRAM%TYPE;

   l_out        VARCHAR2(4000);
   l_ligne      VARCHAR2(100) := '---------------------------------------------------------------';

   -- Curseur de recherche des fichiers de contrôle:
   CURSOR cur_file_ctrl IS
   SELECT   DISTINCT FILE_NAME, NB_LINE
    FROM  DKA_EXPCDE_IVALUA_FILE
    WHERE FILE_NAME = p_filename 
    ;

   rec_file_ctrl cur_file_ctrl%ROWTYPE;
  BEGIN

    g_step  := 'EDITION_OUTPUT 000 : DEBUT';
    log_msg(g_step);

     --Recuperation des informations
     BEGIN
    --Récupération du nom de la base de données.
    SELECT name 
    INTO gv_base 
    FROM v$database;

      --Recuperation du nom de l'application.
      SELECT fa.application_short_name
      INTO l_appl
      FROM fnd_application fa
      WHERE fa.application_id = fnd_profile.VALUE('RESP_APPL_ID');

      --Recuperation du nom du programme.
      SELECT v.PROGRAM
      INTO l_prgm_name
      FROM fnd_conc_req_summary_v v
      WHERE v.REQUEST_ID =  fnd_global.CONC_REQUEST_ID;

    EXCEPTION
     WHEN OTHERS THEN
      l_appl := '';
    END;


  /*  --ENTETE
    l_out := 'Environnement   : '||gv_base||chr(10)||
             'Application     : '||l_appl||chr(10)||
             'Programme       : '||l_prgm_name||chr(10)||
             'Utilisateur     : '||fnd_profile.VALUE('USERNAME')||chr(10)||
             'Date            : '||to_char(SYSDATE,'DD/MM/YYYY HH24:MI:SS')||chr(10);
    out_msg(l_out);

    out_msg(l_ligne);

    --CORPS
  l_out := 'Paramètre :';out_msg(l_out);
  l_out := '-----------';out_msg(l_out);
    l_out := 'Entité        : '||p_entite;out_msg(l_out);
    l_out := 'Module        : '||p_module;out_msg(l_out);
    l_out := 'Requête       : '||p_n_requete;out_msg(l_out);
    l_out := 'Envoi de mail : '||p_envoi_mail;out_msg(l_out);
    l_out := chr(10)||chr(10)||l_ligne;
    out_msg(l_out);*/

    --FICHIERS GENERES
   OPEN cur_file_ctrl;
            LOOP
                FETCH cur_file_ctrl
                    INTO rec_file_ctrl;
        EXIT WHEN cur_file_ctrl%NOTFOUND;
    l_out := 'Fichier : '||rec_file_ctrl.FILE_NAME||'; Nombre de ligne :'||rec_file_ctrl.NB_LINE;out_msg(l_out);
              END LOOP;
            CLOSE cur_file_ctrl;
    /*l_out := chr(10)||chr(10)||l_ligne;
    out_msg(l_out);*/

    g_step  := 'EDITION_OUTPUT 999 : FIN';
    log_msg(g_step);

  EXCEPTION
   WHEN OTHERS THEN
    p_retcode := 2;
    p_errbuf  := 'Erreur procedure EDITION_OUTPUT :'|| g_step ||chr(10)||SQLERRM;
    log_msg(p_errbuf);
  END edition_output;

    ------------------------------------------------------------------------------------
  --  Nom           : p_check_directory
  --  Description   : Verifie que le directory existe
  --
  --  PARAMETRES    :
  --  p_directory_name          nom du directory
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_check_directory(p_directory_name in ALL_DIRECTORIES.directory_name%type,
								p_errbuf OUT VARCHAR2, 
								p_retcode OUT NUMBER) IS

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
	  g_step := 'LE CHEMIN '|| p_directory_name || ' n''existe pas.';
			log_msg(g_step);
			--Pn_Retcode := 2;
			--edition_output_mail(Pv_Errbuf,Pn_Retcode);
			--raise e_file;	
			p_retcode := 2;
		   p_errbuf  := 'Le directory ' || p_directory_name || ' n''existe pas.';
     -- p_validate(FALSE, 'Le directory ' || p_directory_name || ' n''existe pas.');
    END IF;


    CLOSE cur_directory;



  END p_check_directory;
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
PROCEDURE validate_data(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS


 CURSOR cur_extractions IS
    SELECT STH.* , PHA.ATTRIBUTE7 ATTRIBUTE7
      FROM dka.DKA_SPOCDE_TRANSFRS_HIST STH , PO_HEADERS_ALL PHA
     WHERE 1 = 1
      AND STATUT = 'NEW' 
	  AND STH.PO_HEADER_ID = PHA.PO_HEADER_ID
     ORDER BY STH.record_id 
       --FOR UPDATE OF STH.STATUT, STH.EXTRACTED_DATE,STH.LAST_UPDATE_DATE,STH.LAST_UPDATED_BY     
       ;



BEGIN

 -- RG6-3-6-9 
  FOR rec_cur_recept IN cur_extractions LOOP
		
		/*out_msg(rec_cur_recept.STATUT);
		out_msg(NVL(rec_cur_recept.ATTRIBUTE7 ,'NOTIVA'));*/

        IF rec_cur_recept.STATUT = 'NEW' AND NVL(rec_cur_recept.ATTRIBUTE7 ,'NOTIVA') = 'NOTIVA' THEN
	
            UPDATE DKA_SPOCDE_TRANSFRS_HIST
               SET STATUT = 'IGNORED'
				 , LAST_UPDATE_DATE = SYSDATE
                 , LAST_UPDATED_BY = TO_NUMBER(g_user_id)
             --WHERE CURRENT OF cur_extractions;  
				WHERE RECORD_ID = rec_cur_recept.RECORD_ID;
        END IF;
		

  END LOOP;

  Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_data');

  COMMIT; 


EXCEPTION
  WHEN OTHERS THEN
    p_retcode := 2;
    p_errbuf  := 'validate_data : ' || SQLERRM;
    Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin de la procédure validate_data : EXCEPTION OTHERS ');
END validate_data;


  ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data_excel
  --  Description   : Extrait des lignes dans le fichier Excel
  --
  --  PARAMETRES    :
  --  p_directory_name        Nom du directory
  --  p_file_name             Nom du fichier
  --  p_nb_lignes             Nombre de lignes inserees
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data_excel(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name      IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2,
						   p_errbuf IN OUT VARCHAR2, 
						   p_retcode IN OUT NUMBER) IS

    vv_ligne      VARCHAR2(4000);
    vn_nb_lignes  NUMBER := 0;
    l_file        UTL_FILE.file_type;
	vn_err_flag NUMBER := 0;
	p_retcodee NUMBER;

	CURSOR cur_new IS
		SELECT STH.* 
		FROM DKA_SPOCDE_TRANSFRS_HIST STH
		WHERE STH.STATUT = 'NEW'
		ORDER BY STH.record_id 
        FOR UPDATE OF STH.STATUT, STH.EXTRACTED_DATE,STH.LAST_UPDATE_DATE,STH.LAST_UPDATED_BY;



	 /*//-- cursor pour extraction des lignes//*/

    CURSOR cur_data IS


		SELECT
			
            PO_NUMBER
			||vg_SEPARATOR
			|| SUPPLIER_NUMBER
			||vg_SEPARATOR
			|| SITE_SUPPLIER_NAME
			||vg_SEPARATOR
			|| NVL(SITE_SUPPLIER_ID,'')
			||vg_SEPARATOR
			|| OLD_SUPPLIER_NUM
			||vg_SEPARATOR
			|| OLD_SITE_SUP_NAME
			||vg_SEPARATOR
			|| NVL(OLD_SITE_SUP_ID,'')
			 AS LIGNE
		FROM
			  (
				SELECT PHA.SEGMENT1           PO_NUMBER,
					   POV1.SEGMENT1          SUPPLIER_NUMBER,
					   apss1.VENDOR_SITE_CODE SITE_SUPPLIER_NAME,
					   apss1.ATTRIBUTE4       SITE_SUPPLIER_ID,
					   POV2.SEGMENT1          OLD_SUPPLIER_NUM,
					   apss2.VENDOR_SITE_CODE OLD_SITE_SUP_NAME,
					   apss2.ATTRIBUTE4       OLD_SITE_SUP_ID
				  FROM DKA_SPOCDE_TRANSFRS_HIST STH,
					   PO_VENDORS               POV1,
					   PO_VENDORS               POV2,
					   ap_supplier_sites_all    apss1,
					   ap_supplier_sites_all    apss2,
					   po_headers_all           PHA
				 WHERE STH.STATUT = 'NEW'
				   and STH.PO_HEADER_ID = PHA.PO_HEADER_ID
				   and STH.new_vendor_id = POV1.vendor_id
				   and STH.new_vendor_site_id = apss1.vendor_site_id
				   and STH.old_vendor_id = POV2.vendor_id
				   and STH.old_vendor_site_id = apss2.vendor_site_id
			  );

    TYPE t_cur_data IS TABLE OF cur_data%ROWTYPE index by binary_integer;
    lt_cur_data t_cur_data;

    --ln_step PLS_INTEGER := 10000;

  BEGIN

    -- Verification de l'existence du directory
    p_check_directory(p_directory_name,p_errbuf,p_retcode);
	/*IF p_retcode = 2 THEN
	
	edition_output_mail(p_errbuf,p_retcode);
	
	END IF;*/
	

    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, p_file_name, 'W',32767);

    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      p_put_debug_message('Le fichier ' || p_directory_name || '/' ||p_file_name || ' est ouvert en écriture');
    ELSE
		g_step := 'Le fichier ne peut pas être ouvert en écriture';
		log_msg(g_step);
		
		p_retcode := 2;
		p_errbuf  := 'Le fichier ne peut pas être ouvert en écriture . Erreur : ' || SQLERRM;
		
      --p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
    END IF;

    --création de l'entête
     utl_file.put_line(l_file,'PO_NUMBER|SUPPLIER_NUMBER|SITE_SUPPLIER_NAME|SITE_SUPPLIER_ID|OLD_SUPPLIER_NUM|OLD_SITE_SUP_NAME|OLD_SITE_SUP_ID');
  -- Extraction des donnees
    OPEN cur_data;
    LOOP
      FETCH cur_data BULK COLLECT INTO lt_cur_data;

      IF lt_cur_data.COUNT > 0 THEN
        FOR i in lt_cur_data.FIRST .. lt_cur_data.LAST LOOP

            BEGIN
              vv_ligne :=lt_cur_data(i).LIGNE;  

              -- Ecrit dans le fichier
              utl_file.put_line(l_file, vv_ligne);

              -- Maj des compteurs
              vn_nb_lignes := vn_nb_lignes + 1;

            EXCEPTION
              WHEN OTHERS THEN
                p_put_debug_message('ERREUR ' ||lt_cur_data(i).LIGNE||' - '  || SQLERRM);
            END;

        END LOOP;


      END IF;

      EXIT WHEN cur_data%NOTFOUND;

    END LOOP;
    CLOSE cur_data;
	
	
	
	BEGIN
		INSERT INTO DKA_EXPCDE_IVALUA_FILE
			(FILE_NAME,
			 NB_LINE,
			 CREATED_BY,
			 CREATION_DATE)
		VALUES
			(p_file_name,
			 vn_nb_lignes,
			 gv_created_by,
			 SYSDATE);
		COMMIT;
	END;


	FOR rec_cur_recept IN cur_new LOOP

        UPDATE DKA_SPOCDE_TRANSFRS_HIST
		   SET STATUT = 'EXTRACTED'
			 , EXTRACTED_DATE = SYSDATE
			 , LAST_UPDATE_DATE = SYSDATE
			 , LAST_UPDATED_BY = TO_NUMBER(g_user_id)
		 WHERE CURRENT OF cur_new;

    END LOOP;
    COMMIT; 
	

    -- Fermeture du fichier
      UTL_FILE.FCLOSE(l_file);
		
		p_retcode := 0;
      -- Remet les valeurs des compteurs dans les parametres de la procedure
	   vg_nbl_extr_cmd      := vn_nb_lignes;
	   p_put_debug_message('L''écriture dans le fichier ' || p_directory_name || '/' ||p_file_name || ' est terminée');
	   p_put_debug_message('Le nombre de lignes dans le fichier ' || p_directory_name || '/' ||p_file_name || ' est :'|| vg_nbl_extr_cmd);
  EXCEPTION
    WHEN OTHERS THEN
		p_retcode := 2;
		p_errbuf  := 'Probleme dans la procedure p_extract_data_excel' || (' || SQLERRM || ');
		

  END p_extract_data_excel;

    -------------------------------------------------------------------------------------
    --  Nom           : main
    --  Description   : Procédure principale d'exécution du traitement "DKA : Situation Oracle du matin"
    --
    --  PARAMETRES    :
    --  Pv_Errbuf      IN OUT       Message d'avertissement
    --  Pn_Retcode  IN OUT     Code erreur
    --  P_Entite    IN       Nom de l'entité
    --  P_Module    IN       Nom du module
    --  P_N_Requete  IN       Numéro de requête
    --  P_Envoi_Mail  IN       Envoi de mail
    --  VALEUR RETOURNEE :
    --     Description       : code retour de validite
    --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
    --------------------------------------------------------------------------------------
    PROCEDURE main(Pv_Errbuf    IN OUT VARCHAR2,
                   Pn_Retcode   IN OUT NUMBER
                   ) IS

		-- Variable de sortie du traitement d'envoi par mail.
        Pv2_Errbuf		VARCHAR2(1000);
        Pn2_Retcode		NUMBER;
		lv_nom_fichier  VARCHAR2(200) := 'DSP01_PO_MAJFRS_' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS')  ||'.csv';
		ln_nb_lignes    NUMBER:=0;
        vn_mail      NUMBER;
		vn_file		 NUMBER;




        -- Variable d'exception :
        e_main EXCEPTION;
		e_mainn EXCEPTION;
        e_edition_output EXCEPTION;
		e_file EXCEPTION;

    BEGIN
		
		validate_data(Pv_Errbuf,Pn_Retcode);
		IF Pn_Retcode = 2 THEN
			g_step := 'MAIN 011 : ERROR - PROCEDURE VALIDATE_DATA';
			log_msg(g_step);
			edition_output_mail(Pv_Errbuf,Pn_Retcode);
			raise e_main;
		END IF;
		
        p_extract_data_excel(vg_DIRECTORY, lv_nom_fichier,ln_nb_lignes,Pv_Errbuf,Pn_Retcode);
		IF Pn_Retcode = 2 THEN
			g_step := 'MAIN 011 : ERROR - PROCEDURE EXTRACTION DES DONNEES';
			log_msg(g_step);
			edition_output_mail(Pv_Errbuf,Pn_Retcode);
			raise e_main;
		
		END IF;
		
		
		g_step := 'MAIN 001 : VERIFICATION DE L''EXISTENCE DU FICHIER EXCEL';
		log_msg(g_step);
		select count(1)
		  into vn_file
		  from DKA_EXPCDE_IVALUA_FILE
		 where FILE_NAME = lv_nom_fichier;
		 
		if vn_file = 0 then
			g_step := 'MAIN 002 : ERROR - LE FICHIER EXCEL N''A PAS PU ETRE GENERE';
			log_msg(g_step);
			Pn_Retcode := 2;
			edition_output_mail(Pv_Errbuf,Pn_Retcode);
			raise e_file;	
		end if;
		
		g_step := 'MAIN 003 : VERIFICATION DE L''EXISTENCE DE MAIL DANS LE JEU DE VALEUR DKA_MAIL_EXPCDE_TRANSFRS_IVALUA';
		log_msg(g_step);
		select count(1)
		  into vn_mail
		  from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
		 where ffvs.flex_value_set_id = ffv.flex_value_set_id
		   and ffvs.flex_value_set_name = 'DKA_MAIL_EXPCDE_TRANSFRS_IVALUA'
		   and ffv.ENABLED_FLAG = 'Y'
		   and nvl(ffv.START_DATE_ACTIVE, trunc(SYSDATE)) <=
			   trunc(SYSDATE)
		   and nvl(ffv.END_DATE_ACTIVE, trunc(SYSDATE)) >=
			   trunc(SYSDATE)
		   and ffv.SUMMARY_FLAG = 'N';
		if vn_mail = 0 then
			g_step := 'MAIN 003 : ERROR - AUCUNE ADRESSE MAIL N''EST PRESENTE DANS LE JEU DE VALEUR DKA_MAIL_EXPCDE_TRANSFRS_IVALUA';
			log_msg(g_step);
			Pn_Retcode := 1;
			edition_output_mail(Pv_Errbuf,Pn_Retcode);
			raise e_main;
			
		end if;



		----------------------------------------------------------------
    -- Etape 4 : Lancement du traitement DKA_MAIL_EXPCDE_TRANSFRS_IVALUA.
		----------------------------------------------------------------
       -- IF Pn_Retcode != 2 THEN
		g_step := 'MAIN 011 : LANCEMENT DU TRAITEMENT DKA_MAIL_EXPCDE_TRANSFRS_IVALUA D''ENVOI PAR MAIL.';
		log_msg(g_step);
		
        send_mail(Pv_Errbuf,Pn_Retcode,lv_nom_fichier);
		
		--END IF;
		
		IF Pn_Retcode = 2 THEN
			g_step := 'MAIN 011 : ERROR - PROCEDURE dans la send_mail';
			log_msg(g_step);
			Pn_Retcode := 1;
			edition_output_mail(Pv_Errbuf,Pn_Retcode);
			raise e_main;
		END IF;
		
		

		----------------------------------------------------------------
		--Edition fichier de sortie
		----------------------------------------------------------------
		/*IF Pn_Retcode = 1 THEN
		g_step := 'MAIN 011 : PROCEDURE SEND_MAIL NON EXECUTEE.';
		log_msg(g_step);
		edition_output_mail(Pv_Errbuf,Pn_Retcode);
		raise e_main;
		END IF;*/
		
		IF Pn_Retcode != 2 THEN
		g_step := 'MAIN 012 : EDITION FICHIER DE SORTIE.';
		log_msg(g_step);
		g_step := 'Pn_Retcode : ' || nvl(Pn_Retcode,5);
		log_msg(g_step);
		--procedure d'edition de la sortie
		edition_output_mail(Pv_Errbuf,Pn_Retcode);
		edition_output(Pv_Errbuf,Pn_Retcode,lv_nom_fichier);
		END IF;
		/*IF Pn_Retcode = 1 THEN
		g_step := 'MAIN 011 : PAS DE DESTINATAIRE DANS LE JEU DE VALEURS DKA_MAIL_EXPCDE_TRANSFRS_IVALUA';
		log_msg(g_step);
		raise e_main;
		END IF;*/
		
		/*IF Pn2_Retcode != 0 THEN
			RAISE e_edition_output;
		END IF;
		
		IF Pn2_Retcode > Pn_Retcode THEN
			Pn_Retcode := Pn2_Retcode;
		END IF;*/

    g_step := 'MAIN 999 : FIN';
    log_msg(g_step);


    EXCEPTION
  		WHEN e_edition_output THEN
  			Pv_Errbuf  := 'Erreur procedure EDITION_OUTPUT';
  			Pn_Retcode := 2;
  			log_msg(Pv_Errbuf);
		WHEN e_file THEN
  			Pv_Errbuf  := 'Erreur pas de fichier EXCEL';
  			Pn_Retcode := 2;
  			log_msg(Pv_Errbuf);
      WHEN e_main THEN
        log_msg('ERREUR - ' || g_step);
        Pv_Errbuf := 'ERREUR : ' || SQLERRM;
        log_msg(Pv_Errbuf);
        Pn_Retcode := 1;
	  WHEN e_mainn THEN
        log_msg('ERREUR - ' || g_step);
        Pv_Errbuf := 'ERREUR : ' || SQLERRM;
        log_msg(Pv_Errbuf);
        Pn_Retcode := 2;

      WHEN OTHERS THEN
        log_msg('ERREUR - ' || g_step);
        Pv_Errbuf := 'ERREUR : ' || SQLERRM;
        log_msg(Pv_Errbuf);
        Pn_Retcode := 2;
    END main;

END DKA_EXPCDE_IVALUA_PKG;
/
show error;
exit;
