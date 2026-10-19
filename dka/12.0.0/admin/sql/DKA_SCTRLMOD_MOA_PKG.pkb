SET VERIFY OFF;
CREATE OR REPLACE PACKAGE BODY DKA_SCTRLMOD_MOA_PKG IS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_SCTRLMOD_MOA_PKG.pkb
    -- DESCRIPTION      : DKA_SCTRLMOD_MOA_PKG Package Body
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

    -- Variable contenant l'entête et le corps du mail.
    gv_objet VARCHAR2(4000);
    gv_corps VARCHAR2(4000);
	
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
    --  Nom           : envoi_sans_fichier
    --  Description   : Envoi du message sans aucun fichier.
    --
    --  PARAMETRES    :
    --  Pv_Errbuf      IN OUT       Message d'avertissement
    --  Pn_Retcode  IN OUT     Code erreur
    --  Pv_Entite    IN       Entité
    --  Pv_Module    IN       Module
    --  Pd_Date  IN       Date 
    --------------------------------------------------------------------------------------
    PROCEDURE envoi_sans_fichier(Pv_Errbuf   IN OUT VARCHAR2,
                                 Pn_Retcode  IN OUT NUMBER,
                                 Pv_Entite   IN VARCHAR2,
                                 Pv_Module   IN VARCHAR2,
                                 Pd_Date IN VARCHAR2) IS
        l_mesg   VARCHAR2(4000);
        l_conn   UTL_SMTP.CONNECTION;
        vr_reply UTL_SMTP.REPLY;
		vv_adresses    VARCHAR2(32000);
        vv_adresses_cc    VARCHAR2(32000);
		vb_adress_valide NUMBER;		
		e_pas_destinataire EXCEPTION;   
		
		
          CURSOR c_liste_destinataire IS
               SELECT ffv.description adresse
                 from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
                where ffvs.flex_value_set_id = ffv.flex_value_set_id
                and ffvs.flex_value_set_name = 'DKA_SCTRLMOD_MOA_MAIL'
                  AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                  AND ffv.enabled_flag = 'Y'
                  AND ffv.ATTRIBUTE1 = 'OUI';	
        
        CURSOR c_liste_destinataire_CC IS
               SELECT ffv.description adresse
                 from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
                where ffvs.flex_value_set_id = ffv.flex_value_set_id
                and ffvs.flex_value_set_name = 'DKA_SCTRLMOD_MOA_MAIL'
                  AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                  AND ffv.enabled_flag = 'Y'
                  AND ffv.ATTRIBUTE2 = 'OUI';			  
					  
		
    BEGIN
		vb_adress_valide := 0;
        g_step := 'ENVOI_SANS_FICHIER 000 : DEBUT';
        log_msg(g_step);
        g_step   := 'ENVOI_SANS_FICHIER 001 : RECHERCHE DE L''OBJET DU MAIL.';
        gv_objet := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_SCTRLMOD_MOA_NOOBJECT',
                                              'MODULE',
                                              Pv_Module,
                                              'DATE_SITUATION',
                                              Pd_Date);
        g_step   := 'ENVOI_SANS_FICHIER 002 : RECHERCHE DU CORPS DU MAIL.';
        gv_corps := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_SCTRLMOD_MOA_NOCORPS',
                                              'MODULE',
                                              Pv_Module);
    
        g_step := 'ENVOI_SANS_FICHIER 003 : CONNEXION.';
        l_conn := utl_smtp.open_connection(gv_conn, 25);
    
        g_step := 'ENVOI_SANS_FICHIER 004 : DEBUT CONSTRUCTION MAIL.';
        utl_smtp.helo(l_conn, gv_conn);
	
        vr_reply := utl_smtp.mail(l_conn, gv_expediteur);
        g_step   := 'REPLY MAIL : ' || vr_reply.code || ' - ' ||
                    vr_reply.text;
					
        --< OBE artf2283043
        /*vr_reply := utl_smtp.rcpt(l_conn, gv_plat_appro_mail);
        g_step   := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                    vr_reply.text;*/
					
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
			   RAISE e_pas_destinataire;
		  END IF;		
		--> OBE artf2283043					
		
        -- Liste des mails en CC
		
		g_step := 'SEND_MAIL 003 : LISTE DESTINATAIRE EN COPIE';
		  log_msg(g_step);
		  FOR ligne_cc IN c_liste_destinataire_CC LOOP

			   vr_reply := utl_smtp.rcpt(l_conn, '<' || ligne_cc.adresse || '>');

			   g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
						  vr_reply.text;
			   log_msg(g_step);

			   IF vr_reply.code != '250' THEN
					g_step := 'SEND_MAIL E03 : ERREUR SUR DESTINATAIRE : ' ||
							   ligne_cc.adresse;
					log_msg(g_step);
					IF vb_adress_valide = 0 THEN
						 vr_reply := utl_smtp.rcpt(l_conn, '<' ||
													gv_expediteur || '>');

						 g_step := 'REPLY RCPT : ' || vr_reply.code ||
									' - ' || vr_reply.text;
						 log_msg(g_step);
						 vv_adresses_cc      := vv_adresses_cc || ';' ||
											 gv_expediteur;
						 vb_adress_valide := 1;
					END IF;
			   ELSE
					vv_adresses_cc := vv_adresses_cc || ';' || ligne_cc.adresse;
			   END IF;

		  END LOOP;

		  --On retire le 1er ;
		  IF LENGTH(vv_adresses_cc) > 1 THEN
			   vv_adresses_cc := SUBSTR(vv_adresses_cc, 2);
			   log_msg(substr('Adresse(s) destinataire(s) en copie  : ' ||
							  vv_adresses_cc, 1, 255));
		  
			 --  RAISE e_pas_destinataire;
		  END IF;		
		--> OBE artf2283043
        
        utl_smtp.open_data(l_conn);
        l_mesg := 'Date: ' ||
                  to_char(systimestamp,
                          'dd Mon yyyy hh24:mi:ss tzhtzm',
                          'NLS_DATE_LANGUAGE=American') || utl_tcp.CRLF ||
                  'From: ' || gv_expediteur || utl_tcp.CRLF || 'To: ' ||
                  vv_adresses/*gv_plat_appro_mail*/ || utl_tcp.CRLF || 'CC: ' || vv_adresses_cc/*gv_plat_appro_mail*/ || utl_tcp.CRLF || 'Subject:' ||
                  REPLACE(utl_encode.MIMEHEADER_ENCODE(gv_objet,'utf8'),CHR(13)||CHR(10),'') || utl_tcp.CRLF || 
				  'Content-Type: text/html; charset=windows-1252' || utl_tcp.CRLF || utl_tcp.CRLF || gv_corps;
        utl_smtp.write_data(l_conn, l_mesg);
        
        utl_smtp.close_data(l_conn);
        utl_smtp.quit(l_conn);
        g_step := 'ENVOI_SANS_FICHIER 005 ==> Mail BdC envoye a adresse : ' ||
                  vv_adresses;
        log_msg(g_step);
        g_step := 'ENVOI_SANS_FICHIER 099 : FIN';
        log_msg(g_step);
    EXCEPTION
       WHEN e_pas_destinataire THEN
               --Fermeture de la connexion
               IF l_conn.host IS NOT NULL THEN
                    vr_reply := utl_smtp.quit(l_conn);
               END IF;

               Pv_Errbuf  := 'Pas de destinataire';
               Pn_Retcode := 2;
               Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
               RAISE;	
        WHEN OTHERS THEN
            Pv_Errbuf  := 'MESSAGE_SANS_FICHIER 099 - ERREUR : ' ||
                          SQLERRM;
            log_msg(Pv_Errbuf); --JJA 2014/02/10
            Pn_Retcode := 2;
            RAISE; --JJA 2014/02/10 --Propagation de l'erreur
    END envoi_sans_fichier;

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
    PROCEDURE envoi_avec_fichier(Pv_Errbuf   IN OUT VARCHAR2,
                                 Pn_Retcode  IN OUT NUMBER,
                                 Pv_Entite   IN VARCHAR2,
                                 Pv_Module   IN VARCHAR2,
                                 Pd_Date IN VARCHAR2,
                                 P_Req_Id    IN NUMBER) IS
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
		vv_adresses    VARCHAR2(32000);	-- OBE artf2283043
		vv_adresses_cc    VARCHAR2(32000);	-- OBE artf2283043		
		vb_adress_valide NUMBER;        -- OBE artf2283043
		e_pas_destinataire EXCEPTION;   -- OBE artf2283043
        
        CURSOR cur_file_name(pv_entity VARCHAR2, pv_module VARCHAR2) IS
            select distinct ENTITE,
                            MODULE,
                            REQUEST_ID,
                            FILE_NAME,
                            CREATED_BY,
                            CREATION_DATE
              from DKA_SCTRLMOD_MOA_FILE
             where ENTITE = pv_entity
               and MODULE = pv_module
               and request_id = P_Req_Id; --JJA 2014/02/10
    
        rec_file_name cur_file_name%ROWTYPE;
		
		
          CURSOR c_liste_destinataire IS
               SELECT ffv.description adresse
                 from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
                where ffvs.flex_value_set_id = ffv.flex_value_set_id
                and ffvs.flex_value_set_name = 'DKA_SCTRLMOD_MOA_MAIL'
                  AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                  AND ffv.enabled_flag = 'Y'
                  AND ffv.ATTRIBUTE1 = 'OUI';
				  
		  CURSOR c_liste_destinataire_CC IS
               SELECT ffv.description adresse
                 from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
                where ffvs.flex_value_set_id = ffv.flex_value_set_id
                and ffvs.flex_value_set_name = 'DKA_SCTRLMOD_MOA_MAIL'
                  AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                  AND ffv.enabled_flag = 'Y'
                  AND ffv.ATTRIBUTE2 = 'OUI';
         					  
    
    BEGIN
		vb_adress_valide := 0;
        g_step := 'ENVOI_AVEC_FICHIER 000 : DEBUT';
        log_msg(g_step);
        g_step := 'ENVOI_AVEC_FICHIER 001 : RECHERCHE DE L''OBJET DU MAIL.';
        log_msg(g_step);
        gv_objet := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_SCTRLMOD_MOA_OBJECT',
                                              'MODULE',
                                              Pv_Module,
                                              'DATE_SITUATION',
                                              Pd_Date);
        g_step   := 'ENVOI_AVEC_FICHIER 002 : RECHERCHE DU CORPS DU MAIL.';
        log_msg(g_step);
        gv_corps := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_SCTRLMOD_MOA_CORPS',
                                              'MODULE',
                                              Pv_Module);
    
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
			   RAISE e_pas_destinataire;
		  END IF;		
		--> OBE artf2283043

		  -- Liste des mails en CC
		
		g_step := 'SEND_MAIL 003 : LISTE DESTINATAIRE EN COPIE';
		  log_msg(g_step);
		  FOR ligne_cc IN c_liste_destinataire_CC LOOP

			   vr_reply := utl_smtp.rcpt(l_conn, '<' || ligne_cc.adresse || '>');

			   g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
						  vr_reply.text;
			   log_msg(g_step);

			   IF vr_reply.code != '250' THEN
					g_step := 'SEND_MAIL E03 : ERREUR SUR DESTINATAIRE : ' ||
							   ligne_cc.adresse;
					log_msg(g_step);
					IF vb_adress_valide = 0 THEN
						 vr_reply := utl_smtp.rcpt(l_conn, '<' ||
													gv_expediteur || '>');

						 g_step := 'REPLY RCPT : ' || vr_reply.code ||
									' - ' || vr_reply.text;
						 log_msg(g_step);
						 vv_adresses_cc      := vv_adresses_cc || ';' ||
											 gv_expediteur;
						 vb_adress_valide := 1;
					END IF;
			   ELSE
					vv_adresses_cc := vv_adresses_cc || ';' || ligne_cc.adresse;
			   END IF;

		  END LOOP;

		  --On retire le 1er ;
		  IF LENGTH(vv_adresses_cc) > 1 THEN
			   vv_adresses_cc := SUBSTR(vv_adresses_cc, 2);
			   log_msg(substr('Adresse(s) destinataire(s) en copie  : ' ||
							  vv_adresses_cc, 1, 255));
		  
			 --  RAISE e_pas_destinataire;
		  END IF;		
		--> OBE artf2283043
		
	
        utl_smtp.open_data(l_conn);
        l_mesg := 'Date: ' || to_char(systimestamp, 'dd Mon yyyy hh24:mi:ss tzhtzm', 'NLS_DATE_LANGUAGE=American') || utl_tcp.CRLF ||
                  'From: ' || gv_expediteur || utl_tcp.CRLF || 
				  'To: ' || vv_adresses/*gv_plat_appro_mail*/ || utl_tcp.CRLF ||
				   --decode( vv_adresses_cc, null, '',);
				  'CC: ' || vv_adresses_cc/*gv_plat_appro_mail*/ || utl_tcp.CRLF ||
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
    
        OPEN cur_file_name(Pv_Entite, Pv_Module);
        LOOP
            FETCH cur_file_name
                INTO rec_file_name;
            EXIT WHEN cur_file_name%NOTFOUND;

            gn_amt     	:= 672 * 3;
			l_filepos	:= 1;
			
            begin_attachment(conn         => l_conn,
                             mime_type    => 'text/csv',
                             inline       => TRUE,
                             filename     => rec_file_name.FILE_NAME,
                             transfer_enc => 'base64');
							 
			l_file     := BFILENAME('DKA_OUT_DIR', rec_file_name.FILE_NAME);
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
        END LOOP;
        CLOSE cur_file_name;
    
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

               Pv_Errbuf  := 'Pas de destinataire';
               Pn_Retcode := 2;
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
               and ffvs.flex_value_set_name = 'DKA_SCTRLMOD_MOA_MAIL'
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
            g_step     := 'RECHERCHE_MAIL 099 - ERROR : AUCUNE ADRESSE MAIL N''EST VALIDE DANS LE JEU DE VALEUR DKA_SCTRLMOD_MOA_MAIL';
            Pv_Errbuf  := g_step || ' - ERREUR : ' || SQLERRM;
            Pn_Retcode := 2;
            raise e_mail;
        WHEN OTHERS THEN
            g_step     := 'RECHERCHE_MAIL 099 - ERROR : PROCEDURE RECHERCHE_MAIL EN ERREUR';
            Pv_Errbuf  := g_step || ' - ERREUR : ' || SQLERRM;
            Pn_Retcode := 2;
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
  --  P_REQ_ID				request_id du traitement père
  -----------------------------------------------------------------
  PROCEDURE edition_output_mail(p_errbuf        OUT VARCHAR2,
                                p_retcode       OUT NUMBER,
						        p_req_id   	   IN NUMBER) IS

   l_appl       fnd_application.application_short_name%TYPE;
   l_prgm_name  fnd_conc_req_summary_v.PROGRAM%TYPE;
   
   l_out        VARCHAR2(4000);
   l_ligne      VARCHAR2(100) := '---------------------------------------------------------------';
   
   -- Curseur de recherche de l'ensemble des adresses mail de destination :
   CURSOR cur_mail IS
		select ffv.flex_value, ffv.FLEX_VALUE_MEANING, ffv.DESCRIPTION
          from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
         where ffvs.flex_value_set_id = ffv.flex_value_set_id
           and ffvs.flex_value_set_name = 'DKA_SCTRLMOD_MOA_MAIL'
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


    --ENTETE
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
  l_out := 'Numéro du traitement à traiter : '||p_req_id;out_msg(l_out);
  out_msg(l_ligne);
  l_out := 'E-mail de destination : ';out_msg(l_out);
  l_out := '------------------------';out_msg(l_out);
  OPEN cur_mail;
         LOOP
             FETCH cur_mail
                 INTO rec_mail;
			 EXIT WHEN cur_mail%NOTFOUND;
			  l_out := rec_mail.DESCRIPTION;out_msg(l_out);
	     END LOOP;
  CLOSE cur_mail;
  out_msg(l_ligne);
  l_out := 'MAIL :';out_msg(l_out);
  l_out := '------';out_msg(l_out);
  l_out := 'OBJET : ' || gv_objet;out_msg(l_out);
  out_msg(gv_corps);
    
    g_step  := 'EDITION_OUTPUT_MAIL 999 : FIN';
    log_msg(g_step);

  EXCEPTION
   WHEN OTHERS THEN
    p_retcode := 2;
    p_errbuf  := 'Erreur procedure EDITION_OUTPUT_MAIL :'|| g_step ||chr(10)||SQLERRM;
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
                         P_Req_Id   IN NUMBER) IS
    
        vv_entite     FND_CONCURRENT_REQUESTS.argument1%TYPE;
        vv_module     FND_CONCURRENT_REQUESTS.argument2%TYPE;
        vn_n_requete  FND_CONCURRENT_REQUESTS.argument3%TYPE;
        vv_envoi_mail FND_CONCURRENT_REQUESTS.argument4%TYPE;
    
        vn_file NUMBER;
    
		e_edition_output_mail EXCEPTION;
    BEGIN
        g_step := 'ENVOI_MAIL 000 : DEBUT';
        log_msg(g_step);
        -- Recherche des arguments lors de l'exécution du traitement "VE : Edition des fichiers de contrôle de pré-clôture".
        g_step := 'ENVOI_MAIL 001 : RECHERCHE DES ARGUMENTS DU TRAITEMENT.';
        log_msg(g_step);
        BEGIN
            select fcr.argument1,
                   fcr.argument2,
                   fcr.argument3,
                   fcr.argument4
              into vv_entite, vv_module, vn_n_requete, vv_envoi_mail
              from FND_CONCURRENT_REQUESTS fcr
             where fcr.REQUEST_ID = P_Req_Id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                g_step := 'ENVOI_MAIL 001 : IMPOSSIBLE DE DETERMINER LES ARGUMENTS DU TRAITEMENT ' ||
                          P_Req_Id || '.';
                raise e_envoi_mail;
        END;
    
	    
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
    
        IF vn_n_requete IS NOT NULL THEN
            select count(1)
              into vn_file
              from DKA_SCTRLMOD_MOA_FILE
             where REQUEST_ID = P_Req_Id
               and ENTITE = vv_entite
               and MODULE = vv_module
               and request_id = P_Req_Id; 
               
            IF vn_file = 0 THEN
                -- Initialisation du message contenant aucun fichier.
                g_step := 'ENVOI_MAIL 005.a : ENVOI DU MESSAGE SANS FICHIER.';
                log_msg(g_step);
                envoi_sans_fichier(Pv_Errbuf,
                                   Pn_Retcode,
                                   vv_entite,
                                   vv_module,
                                   to_char(SYSDATE, 'DD/MM/YYYY'));
            ELSE
                -- Initialisation du message contenant un fichier.
                g_step := 'ENVOI_MAIL 005.a : ENVOI DU MESSAGE AVEC FICHIER.';
                log_msg(g_step);
                envoi_avec_fichier(Pv_Errbuf,
                                   Pn_Retcode,
                                   vv_entite,
                                   vv_module,
                                   to_char(SYSDATE, 'DD/MM/YYYY'),
                                   P_Req_Id);
            END IF;
        ELSE
            select count(1)
              into vn_file
              from DKA_SCTRLMOD_MOA_FILE
             where ENTITE = vv_entite
               and MODULE = vv_module
               and request_id = P_Req_Id; 
               
            IF vn_file = 0 THEN
                -- Initialisation du message contenant aucun fichier.
                g_step := 'ENVOI_MAIL 005.a : ENVOI DU MESSAGE SANS FICHIER.';
                log_msg(g_step);
                envoi_sans_fichier(Pv_Errbuf,
                                   Pn_Retcode,
                                   vv_entite,
                                   vv_module,
                                   to_char(SYSDATE, 'DD/MM/YYYY'));
            ELSE
                -- Initialisation du message contenant un fichier.
                g_step := 'ENVOI_MAIL 005.a : ENVOI DU MESSAGE AVEC FICHIER.';
                log_msg(g_step);
                envoi_avec_fichier(Pv_Errbuf,
                                   Pn_Retcode,
                                   vv_entite,
                                   vv_module,
                                   to_char(SYSDATE, 'DD/MM/YYYY'),
                                   P_Req_Id);
            END IF;
        END IF;
		
		--------------------------------------------------------------------------------
		--Suppression des enregistrements dans la table contenant les noms des fichiers.
		--------------------------------------------------------------------------------
		BEGIN
			DELETE FROM DKA_SCTRLMOD_MOA_FILE WHERE REQUEST_ID = P_Req_Id;
		END;
		COMMIT;
		
		----------------------------------------------------------------
		--Edition fichier de sortie
		----------------------------------------------------------------
		g_step := 'ENVOI_MAIL 006 : EDITION FICHIER DE SORTIE.';
		log_msg(g_step);
		edition_output_mail(Pv_Errbuf,Pn_Retcode,P_Req_Id);
		IF Pn_Retcode != 0 THEN
			RAISE e_edition_output_mail;
		END IF;
        g_step := 'ENVOI_MAIL 999 : FIN';
        log_msg(g_step);
    EXCEPTION
		WHEN e_edition_output_mail THEN
			Pv_Errbuf  := 'Erreur procedure EDITION_OUTPUT_MAIL';
			Pn_Retcode := 2;
			log_msg(Pv_Errbuf);
        WHEN e_mail THEN
            log_msg(Pv_Errbuf);
            Pn_Retcode := 2;
        WHEN e_envoi_mail THEN
            log_msg('ERREUR - ' || g_step);
            Pv_Errbuf := 'ERREUR : ' || SQLERRM;
            log_msg(Pv_Errbuf);
            Pn_Retcode := 2;
        WHEN OTHERS THEN
            log_msg('ERREUR - ' || g_step);
            Pv_Errbuf := 'ERREUR : ' || SQLERRM;
            log_msg(Pv_Errbuf);
            Pn_Retcode := 2;
    END send_mail;

  
    -------------------------------------------------------------------------------------
    --  Nom           : lance_trait_mail
    --  Description   : procedure d'exécution du traitement d'envoi par mail
    --
    --  PARAMETRES    :
    --  Pv_Errbuf      IN OUT       Message d'avertissement
    --  Pn_Retcode    IN OUT     Code erreur
    --  Pv_Req_Id    IN       Nom de l'entité
    --  Pv_prog_name  IN          Short Name du traitement
    --  VALEUR RETOURNEE :  pn_retcode
    --  Valeurs possibles : true=traitement sans erreur, false=traitement en erreur
    ------------------------------------------------------------------------------------
    PROCEDURE lance_trait_mail(Pv_Errbuf    IN OUT VARCHAR2,
                               Pn_Retcode   IN OUT NUMBER,
                               Pv_Req_Id    IN VARCHAR2,
                               Pv_prog_name IN VARCHAR2) IS
        vv_prog_application_short_name VARCHAR(30);
        vn_request_id                  NUMBER(15);
        cn_tempo CONSTANT NUMBER := 20;
        vv_rphase     VARCHAR2(80);
        vv_rstatus    VARCHAR2(80);
        vv_dphase     VARCHAR2(30);
        vv_dstatus    VARCHAR2(30);
        vv_message    VARCHAR2(240);
        vb_validation BOOLEAN;
    BEGIN
        g_step := 'LANCE_TRAIT_MAIL 000 : DEBUT';
        log_msg(g_step);
    
        -- Recherche de l'application propriétaire du traitement. --
        g_step := 'LANCE_TRAIT_MAIL 001 : RECHERCHE DES INFORMATIONS LIEES AU PROGRAMME D''ENVOI PAR MAIL.';
        BEGIN
            SELECT fa.application_short_name
              INTO vv_prog_application_short_name
              FROM fnd_concurrent_programs fcp, fnd_application fa
             WHERE fcp.concurrent_program_name = Pv_prog_name
               AND fa.application_id = fcp.application_id;
        EXCEPTION
            WHEN OTHERS THEN
                vb_validation := FALSE;
                g_step        := 'LANCE_TRAIT_MAIL 001 :ERROR - Impossible de trouver l''application propriétaire.';
                log_msg(g_step);
        END;
    
        vn_request_id := fnd_request.submit_request(vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                    Pv_prog_name, --SHORT_NAME du TRAITEMENT
                                                    NULL, --PROGRAM_NAME
                                                    NULL, --START
                                                    FALSE, --SUB_REQUEST
                                                    Pv_Req_Id --ARGUMENT1
                                                    );
        g_step        := 'LANCE_TRAIT_MAIL 002 :Validation pour que les GTS puissent prendre la demande.';
        log_msg(g_step);
        COMMIT;
    
        IF vn_request_id = 0 THEN
            DBMS_OUTPUT.put_line('Impossible de lancer le Traitement ');
            vb_validation := FALSE;
        END IF;
    
        DBMS_OUTPUT.put_line('Traitement numero : ' ||
                             TO_CHAR(vn_request_id));
    
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
        g_step := 'LANCE_TRAIT_MAIL 999 : FIN';
        log_msg(g_step);
		
		IF (vb_validation = FALSE) THEN
		  Pn_Retcode := 2;
		END IF;
        
		vb_validation := TRUE;
		
    EXCEPTION
        WHEN OTHERS THEN
            g_step := 'LANCE_TRAIT_MAIL 999 : ' || Pv_prog_name ||
                      ' ==> ERREUR : ' || SQLERRM;
            log_msg(g_step);
            vb_validation := FALSE;
			Pn_Retcode := 2;
    END lance_trait_mail;

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
               p_entite        IN VARCHAR2,
               p_module        IN VARCHAR2,
               p_n_requete     IN NUMBER,
               p_envoi_mail    IN VARCHAR2) IS

   l_appl       fnd_application.application_short_name%TYPE;
   l_prgm_name  fnd_conc_req_summary_v.PROGRAM%TYPE;
   
   l_out        VARCHAR2(4000);
   l_ligne      VARCHAR2(100) := '---------------------------------------------------------------';
   
   -- Curseur de recherche des fichiers de contrôle:
   CURSOR cur_file_ctrl IS
   SELECT   DISTINCT FILE_NAME, NB_LINE
    FROM  DKA_SCTRLMOD_MOA_FILE
    WHERE request_id = gv_request_id --JJA 2014/02/10
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


    --ENTETE
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
    out_msg(l_out);
    
    --FICHIERS GENERES
   OPEN cur_file_ctrl;
            LOOP
                FETCH cur_file_ctrl
                    INTO rec_file_ctrl;
        EXIT WHEN cur_file_ctrl%NOTFOUND;
    l_out := 'Fichier : '||rec_file_ctrl.FILE_NAME||'; Nombre de ligne :'||rec_file_ctrl.NB_LINE;out_msg(l_out);
              END LOOP;
            CLOSE cur_file_ctrl;
    l_out := chr(10)||chr(10)||l_ligne;
    out_msg(l_out);
    
    g_step  := 'EDITION_OUTPUT 999 : FIN';
    log_msg(g_step);

  EXCEPTION
   WHEN OTHERS THEN
    p_retcode := 2;
    p_errbuf  := 'Erreur procedure EDITION_OUTPUT :'|| g_step ||chr(10)||SQLERRM;
    log_msg(p_errbuf);
  END edition_output;
  
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
                   Pn_Retcode   IN OUT NUMBER,
                   P_Entite     IN VARCHAR2,
                   P_Module     IN VARCHAR2,
                   P_N_Requete  IN NUMBER,
                   P_Envoi_Mail IN VARCHAR2) IS
    
        -- Curseur de parcours de la liste des requêtes :
        CURSOR cur_requete_mod(pv_entity VARCHAR2, pv_module VARCHAR2) IS
            select ffv.flex_value, ffv.FLEX_VALUE_MEANING, ffv.DESCRIPTION,ffv.ATTRIBUTE2 as lundi , ffv.ATTRIBUTE3 as mardi ,
        ffv.ATTRIBUTE4 as mercredi,ffv.ATTRIBUTE5 as jeudi,ffv.ATTRIBUTE6 as vendredi,ffv.ATTRIBUTE7 as samedi ,
        ffv.ATTRIBUTE8 as dimanche
              from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
             where ffvs.flex_value_set_id = ffv.flex_value_set_id
               and ffvs.flex_value_set_name =
                   'DKA_SCTRLMOD_MOA_REQUETE_MOD'
               and ffv.ENABLED_FLAG = 'Y'
               and nvl(ffv.START_DATE_ACTIVE, trunc(SYSDATE)) <= trunc(SYSDATE)
               and nvl(ffv.END_DATE_ACTIVE, trunc(SYSDATE)) >= trunc(SYSDATE)
               and ffv.SUMMARY_FLAG = 'N'
               and ffv.attribute1 = pv_entity -- Liste des entités
               and ffv.PARENT_FLEX_VALUE_LOW = pv_module; -- Liste des modules à contrôler
    
        Rec_requete_mod Cur_requete_mod%ROWTYPE;
    
        -- Curseur de parcours des adresses mails :
    
        -- Variable d'écriture dans un fichier log.
        fileHandler UTL_FILE.FILE_TYPE;
        filename    varchar2(50);
        cv_directory CONSTANT VARCHAR2(50) := 'DKA_OUT_DIR';
    
        -- Variable validation des données :
        vn_entite    NUMBER;
        vn_module    NUMBER;
        vn_mail      NUMBER;
        vn_n_requete NUMBER;
        
        -- Variables du jours
        vv_lundi varchar2(10);
        vv_mardi varchar2(10);
        vv_mercredi varchar2(10);
        vv_jeudi varchar2(10);
        vv_vendredi varchar2(10);
        vv_samedi varchar2(10);
        vv_dimanche varchar2(10);
    
        -- Variable d'exception :
        e_main EXCEPTION;
        e_edition_output EXCEPTION;
		e_erreur_jour EXCEPTION;
		
        -- Variable de sortie du traitement d'envoi par mail.
        Pv2_Errbuf		VARCHAR2(1000);
        Pn2_Retcode		NUMBER;
		
		
        -- Variable contenant les informations sur la requête :
        VV_NOM_COURT 	DKA_SCTRLMOD_MOA_REQUETE.NOM_COURT%TYPE;
        VV_DESCRIPT  	DKA_SCTRLMOD_MOA_REQUETE.DESCRIPTION%TYPE;
        VV_COLONNE   	DKA_SCTRLMOD_MOA_REQUETE.COLONNE%TYPE;
        VV_REQUETE   	DKA_SCTRLMOD_MOA_REQUETE.REQUETE%TYPE;
        VV_COMMENTAIRE	DKA_SCTRLMOD_MOA_REQUETE.COMMENTAIRE%TYPE;
		
        TYPE t_result_req is TABLE of VARCHAR2(3200);
        vv_result_req t_result_req;
    
        -- Variable compteur du nombre de lignes dans un fichier de clôture:
        vn_nb_ligne  NUMBER;
		
		--Variable contenant le nom du jour
        vn_nb_jour VARCHAR(20);
		
		vn_err_flag NUMBER := 0; -- OBE artf2286611
    
    BEGIN
        g_step := 'MAIN 000 : DEBUT';
        log_msg(g_step);
        g_step := 'MAIN 001 : PURGE DE LA TABLE DE TRAVAIL DKA_SCTRLMOD_MOA_FILE.';
        
        -- Etape 1 : Validation des paramètres.
        -- Recherche de l'existence de l'entité dans le jeu de valeur DKA_SCTRLMOD_MOA_ENTITE (l'entité doit êtr active).
        g_step := 'MAIN 001 : VERIFICATION DE L''EXISTENCE DE L''ENTITE DANS LE JEU DE VALEUR DKA_SCTRLMOD_MOA_ENTITE';
        log_msg(g_step);
        select count(1)
          into vn_entite
          from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
         where ffvs.flex_value_set_id = ffv.flex_value_set_id
           and ffvs.flex_value_set_name = 'DKA_SCTRLMOD_MOA_ENTITE'
           and ffv.ENABLED_FLAG = 'Y'
           and nvl(ffv.START_DATE_ACTIVE, trunc(SYSDATE)) <=
               trunc(SYSDATE)
           and nvl(ffv.END_DATE_ACTIVE, trunc(SYSDATE)) >= trunc(SYSDATE)
           and ffv.SUMMARY_FLAG = 'N'
           and ffv.flex_value = P_Entite;
    
        if vn_entite = 0 THEN
            g_step := 'MAIN 001 : ERROR - L''ENTITE ' || P_Entite ||
                      ' N''EXISTE PAS DANS LE JEU DE VALEUR DKA_SCTRLMOD_MOA_ENTITE';
            raise e_main;
        end if;
    
        -- Recherche de l'existence du nom de module dans le jeu de valeur DKA_SCTRLMOD_MOA_MODULE.
        g_step := 'MAIN 002 : VERIFICATION DE L''EXISTENCE DU MODULE DANS LE JEU DE VALEUR DKA_SCTRLMOD_MOA_MODULE';
        log_msg(g_step);
        select count(1)
          into vn_module
          from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
         where ffvs.flex_value_set_id = ffv.flex_value_set_id
           and ffvs.flex_value_set_name = 'DKA_SCTRLMOD_MOA_MODULE'
           and ffv.ENABLED_FLAG = 'Y'
           and nvl(ffv.START_DATE_ACTIVE, trunc(SYSDATE)) <=
               trunc(SYSDATE)
           and nvl(ffv.END_DATE_ACTIVE, trunc(SYSDATE)) >= trunc(SYSDATE)
           and ffv.SUMMARY_FLAG = 'N'
           and ffv.flex_value = P_Module;
    
        if vn_module = 0 THEN
            g_step := 'MAIN 002 : ERROR - LE MODULE ' || P_Module ||
                      ' N''EXISTE PAS DANS LE JEU DE VALEUR DKA_SCTRLMOD_MOA_ENTITE';
            raise e_main;
        end if;
    
        IF P_Envoi_Mail IS NOT NULL and P_Envoi_Mail = 'OUI' THEN
            g_step := 'MAIN 003 : VERIFICATION DE L''EXISTENCE DE MAIL DANS LE JEU DE VALEUR DKA_SCTRLMOD_MOA_MAIL';
            log_msg(g_step);
            select count(1)
              into vn_mail
              from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
             where ffvs.flex_value_set_id = ffv.flex_value_set_id
               and ffvs.flex_value_set_name = 'DKA_SCTRLMOD_MOA_MAIL'
               and ffv.ENABLED_FLAG = 'Y'
               and nvl(ffv.START_DATE_ACTIVE, trunc(SYSDATE)) <=
                   trunc(SYSDATE)
               and nvl(ffv.END_DATE_ACTIVE, trunc(SYSDATE)) >=
                   trunc(SYSDATE)
               and ffv.SUMMARY_FLAG = 'N';
            if vn_mail = 0 then
                g_step := 'MAIN 003 : ERROR - AUCUNE ADRESSE MAIL N''EST PRESENTE DANS LE JEU DE VALEUR DKA_SCTRLMOD_MOA_MAIL';
                raise e_main;
            end if;
        END IF;
    
	
		-- Defining today in the variable
            SELECT to_char(sysdate - 0.8,'DAY') INTO vn_nb_jour FROM dual;
        -------
	
        g_step := 'MAIN 005 : CONTRÔLE DU PARAMETRE NUMERO DE REQUÊTE';
        log_msg(g_step);
        -- Recherche de l'existence du numéro de requête dans le jeu de valeur DKA_SCTRLMOD_MOA_REQUETE_MOD.
        IF P_N_Requete IS NOT NULL THEN
            g_step := 'MAIN 006 : VERIFICATION DE L''EXISTENCE DU NUMERO DE REQUETE DANS LE JEU DE VALEUR DKA_SCTRLMOD_MOA_REQUETE_MOD';
            log_msg(g_step);
        
            select count(1) --,ffv.ATTRIBUTE2 , ffv.ATTRIBUTE3 , ffv.ATTRIBUTE4 ,ffv.ATTRIBUTE5 ,ffv.ATTRIBUTE6 ,ffv.ATTRIBUTE7  , ffv.ATTRIBUTE8 
              into vn_n_requete --,vv_lundi,vv_mardi,vv_mercredi,vv_jeudi,vv_vendredi,vv_samedi,vv_dimanche
              from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
             where ffvs.flex_value_set_id = ffv.flex_value_set_id
               and ffvs.flex_value_set_name =
                   'DKA_SCTRLMOD_MOA_REQUETE_MOD'
               --and ffv.ENABLED_FLAG = 'Y'
               and nvl(ffv.START_DATE_ACTIVE, trunc(SYSDATE)) <=
                   trunc(SYSDATE)
               and nvl(ffv.END_DATE_ACTIVE, trunc(SYSDATE)) >=
                   trunc(SYSDATE)
               and ffv.SUMMARY_FLAG = 'N'
               and ffv.attribute1 = P_Entite -- Liste des entités
               and ffv.PARENT_FLEX_VALUE_LOW = P_Module -- Liste des modules à contrôler
               and ffv.flex_value = TO_CHAR(P_N_Requete);
               /*GROUP BY ffv.ATTRIBUTE2, ffv.ATTRIBUTE3 ,
                ffv.ATTRIBUTE4 ,ffv.ATTRIBUTE5 ,ffv.ATTRIBUTE6 ,ffv.ATTRIBUTE7  ,
                ffv.ATTRIBUTE8;*/
        
            if vn_n_requete = 0 then
                g_step := 'MAIN 006 : ERROR - LE NUMERO DE REQUÊTE ' ||
                          P_N_Requete || ' NE CORRESPOND PAS AU MODULE ' ||
                          P_Module || ' ET A L''ENTITE ' || P_Entite ||
                          ' DANS LE JEU DE VALEUR DKA_SCTRLMODULE_REQUETE_MOD.';
                raise e_main;
            end if;
			
			
			
            g_step := 'MAIN 007 : RECHERCHE DES INFORMATION LIEES A LA REQUETE SELECTIONNEE.';
            log_msg(g_step);
            BEGIN
                SELECT XSR.NOM_COURT,
                       XSR.DESCRIPTION,
                       XSR.COMMENTAIRE,
                       XSR.COLONNE,
                       XSR.REQUETE
                  INTO VV_NOM_COURT, VV_DESCRIPT, VV_COMMENTAIRE, VV_COLONNE, VV_REQUETE
                  FROM DKA_SCTRLMOD_MOA_REQUETE XSR
                 WHERE XSR.ENTITE = P_Entite
                   AND XSR.MODULE = P_Module
                   AND XSR.NUMERO = P_N_Requete;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    g_step     := 'MAIN 007 : ERROR - IMPOSSIBLE DE DETERMINER LES INFORMATIONS LIEES A LA REQUETE NUMERO ' ||
                                  P_N_Requete || ' POUR L''ENTITE ' ||
                                  P_Entite || ' ET POUR LE MODULE ' ||
                                  P_Module;
                    Pv_Errbuf  := g_step;
                    --Pn_Retcode := 2;
					vn_err_flag := 1;
					
					-- Affectation de la valeur NULL aux variables.
					VV_NOM_COURT 	:= NULL;
					VV_DESCRIPT 	:= NULL;
					VV_COMMENTAIRE 	:= NULL;
					VV_COLONNE 		:= NULL;
					VV_REQUETE 		:= NULL;
            END;
			
            --IF ((vn_nb_jour LIKE '%LUNDI%' OR vn_nb_jour LIKE '%MONDAY%') AND vv_lundi = 'OUI') THEN -- new if
				IF VV_REQUETE IS NOT NULL THEN
					g_step := 'MAIN 008 : DEFINITION DU NOM DE FICHIER.';
					log_msg(g_step);
					filename := gv_request_id || '_' || VV_NOM_COURT || '.csv';
				
					g_step := 'MAIN 009 : EXECUTION DE LA REQUETE STOCKEE POUR LE CONTRÔLE : ' || VV_NOM_COURT || '('|| P_N_Requete || ')';
					log_msg(g_step);
					
					EXECUTE IMMEDIATE VV_REQUETE BULK COLLECT
					  INTO vv_result_req;
								
					
					-- Si le fichier ne sera pas vide alors nous créons le fichier.
					IF vv_result_req.COUNT != 0 THEN
						g_step := 'MAIN 010.a : CREATION DU FICHIER ET DE SON ENTÊTE : ' || filename;
						log_msg(g_step);
						fileHandler := utl_file.fopen(cv_directory, filename, 'w');
						utl_file.put_line(fileHandler, VV_DESCRIPT);
						utl_file.put_line(fileHandler, VV_COMMENTAIRE);
						utl_file.put_line(fileHandler, '');
						utl_file.put_line(fileHandler, VV_COLONNE);
					
						g_step := 'MAIN 010.b : INSERTION DE CHAQUE LIGNE DE LA REQUÊTE DANS LE FICHIER DE SORTIE.';
						log_msg(g_step);
						vn_nb_ligne := 0;
						FOR i IN vv_result_req.first .. vv_result_req.last LOOP
							utl_file.put_line(fileHandler, replace(vv_result_req(i),chr(10),' '));
						vn_nb_ligne := vn_nb_ligne + 1;
						END LOOP;
						g_step := 'MAIN 010.c : INSERTION DU NOM DU FICHIER DANS LA TABLE DE TRAVAIL DKA_SCTRLMOD_MOA_FILE.';
						log_msg(g_step);
						BEGIN
							INSERT INTO DKA_SCTRLMOD_MOA_FILE
								(ENTITE,
								 MODULE,
								 REQUEST_ID,
								 FILE_NAME,
								 NB_LINE,
								 CREATED_BY,
								 CREATION_DATE)
							VALUES
								(P_Entite,
								 P_Module,
								 gv_request_id,
								 filename,
								 vn_nb_ligne,
								 gv_created_by,
								 SYSDATE);
							COMMIT;
						END;
						utl_file.fclose(fileHandler);
					END IF;
				END IF;
            
 
			--END IF;
			
        ELSE
            g_step := 'MAIN 006 : PARCOURS DE L''ENSEMBLE DES ENREGISTREMENTS PRESENTS DANS LA JEU DE VALEUR DKA_SCTRLMODULE_REQUETE_MOD POUR L''ENTITE ' ||
                      P_Entite || ' ET LE MODULE ' || P_Module || '.';
            log_msg(g_step);
			
			
			
            OPEN Cur_requete_mod(P_Entite, P_Module);
            LOOP
                FETCH Cur_requete_mod
                    INTO Rec_requete_mod;
                EXIT WHEN Cur_requete_mod%NOTFOUND;
                g_step := 'MAIN 007 : RECHERCHE DES INFORMATION LIEES A LA REQUETE SELECTIONNEE.';
                log_msg(g_step);
                BEGIN
                    SELECT  XSR.NOM_COURT,
                            XSR.DESCRIPTION,
                            XSR.COMMENTAIRE,
                            XSR.COLONNE,
                            XSR.REQUETE
                      INTO VV_NOM_COURT,
                           VV_DESCRIPT,
                           VV_COMMENTAIRE,
                           VV_COLONNE,
                           VV_REQUETE
                      FROM DKA_SCTRLMOD_MOA_REQUETE XSR
                     WHERE XSR.ENTITE = P_Entite
                       AND XSR.MODULE = P_Module
                       AND XSR.NUMERO = Rec_requete_mod.flex_value;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        g_step     := 'MAIN 007 : ERROR - IMPOSSIBLE DE DETERMINER LES INFORMATIONS LIEES A LA REQUETE NUMERO ' ||
                                      Rec_requete_mod.flex_value ||
                                      ' POUR L''ENTITE ' || P_Entite ||
                                      ' ET POUR LE MODULE ' || P_Module;
                        Pv_Errbuf  := g_step;
						log_msg(Pv_Errbuf);
                        -- Pn_Retcode := 2;
						vn_err_flag := 1;
						
						-- Affectation de la valeur NULL aux variables.
						VV_NOM_COURT 	:= NULL;
						VV_DESCRIPT 	:= NULL;
						VV_COMMENTAIRE 	:= NULL;
						VV_COLONNE 		:= NULL;
						VV_REQUETE 		:= NULL;
                END;
				IF ((vn_nb_jour LIKE '%LUNDI%' OR vn_nb_jour LIKE '%MONDAY%') AND Rec_requete_mod.lundi = 'OUI') THEN
					IF VV_REQUETE IS NOT NULL THEN
						g_step := 'MAIN 008 : DEFINITION DU NOM DE FICHIER.';
						log_msg(g_step);
						filename := gv_request_id || '_' || VV_NOM_COURT || '.csv';
					
						g_step := 'MAIN 009 : EXECUTION DE LA REQUETE STOCKEE POUR LE CONTRÔLE : ' || VV_NOM_COURT || '('|| Rec_requete_mod.flex_value || ')';
						log_msg(g_step);
						
						--< OBE artf2286611
						BEGIN					
							  EXECUTE IMMEDIATE VV_REQUETE BULK COLLECT
							   INTO vv_result_req;
						EXCEPTION
						WHEN OTHERS THEN
						  g_step := 'ERREUR < '||TO_CHAR(SQLERRM)||' > LORS DE L''EXECUTION DE LA REQUETE : ' || VV_NOM_COURT || '('|| Rec_requete_mod.flex_value || ')';
						  log_msg(g_step);
						  vn_err_flag := 1;
						END;	
						--> OBE artf2286611	
				
						-- Si le fichier ne sera pas vide alors nous créons le fichier.
						IF vv_result_req.COUNT != 0 THEN
							g_step := 'MAIN 010.a : CREATION DU FICHIER ET DE SON ENTÊTE : ' || filename;
							log_msg(g_step);
							fileHandler := utl_file.fopen(cv_directory,
														  filename,
														  'w');
							utl_file.put_line(fileHandler, VV_DESCRIPT);
							utl_file.put_line(fileHandler, VV_COMMENTAIRE);
							utl_file.put_line(fileHandler, '');
							utl_file.put_line(fileHandler, VV_COLONNE);
						
							g_step := 'MAIN 010.b : INSERTION DE CHAQUE LIGNE DE LA REQUÊTE DANS LE FICHIER DE SORTIE.';
							log_msg(g_step);
							vn_nb_ligne := 0;
							FOR i IN vv_result_req.first .. vv_result_req.last LOOP
								utl_file.put_line(fileHandler, replace(vv_result_req(i),chr(10),' '));
								vn_nb_ligne := vn_nb_ligne + 1;
							END LOOP;
							g_step := 'MAIN 010.c : INSERTION DU NOM DU FICHIER DANS LA TABLE DE TRAVAIL DKA_SCTRLMOD_MOA_FILE.';
							log_msg(g_step);
							BEGIN
								INSERT INTO DKA_SCTRLMOD_MOA_FILE
									(ENTITE,
									 MODULE,
									 REQUEST_ID,
									 FILE_NAME,
									 NB_LINE,
									 CREATED_BY,
									 CREATION_DATE)
								VALUES
									(P_Entite,
									 P_Module,
									 gv_request_id,
									 filename,
									 vn_nb_ligne,
									 gv_created_by,
									 SYSDATE);
								COMMIT;
							END;
							utl_file.fclose(fileHandler);
						END IF;
					END IF;
                
				ELSIF ((vn_nb_jour LIKE '%MARDI%' OR vn_nb_jour LIKE '%TUESDAY%') AND Rec_requete_mod.mardi = 'OUI') THEN-- new if
					IF VV_REQUETE IS NOT NULL THEN
						g_step := 'MAIN 008 : DEFINITION DU NOM DE FICHIER.';
						log_msg(g_step);
						filename := gv_request_id || '_' || VV_NOM_COURT || '.csv';
					
						g_step := 'MAIN 009 : EXECUTION DE LA REQUETE STOCKEE POUR LE CONTRÔLE : ' || VV_NOM_COURT || '('|| Rec_requete_mod.flex_value || ')';
						log_msg(g_step);
						
						--< OBE artf2286611
						BEGIN					
							  EXECUTE IMMEDIATE VV_REQUETE BULK COLLECT
							   INTO vv_result_req;
						EXCEPTION
						WHEN OTHERS THEN
						  g_step := 'ERREUR < '||TO_CHAR(SQLERRM)||' > LORS DE L''EXECUTION DE LA REQUETE : ' || VV_NOM_COURT || '('|| Rec_requete_mod.flex_value || ')';
						  log_msg(g_step);
						  vn_err_flag := 1;
						END;	
						--> OBE artf2286611	
				
						-- Si le fichier ne sera pas vide alors nous créons le fichier.
						IF vv_result_req.COUNT != 0 THEN
							g_step := 'MAIN 010.a : CREATION DU FICHIER ET DE SON ENTÊTE : ' || filename;
							log_msg(g_step);
							fileHandler := utl_file.fopen(cv_directory,
														  filename,
														  'w');
							utl_file.put_line(fileHandler, VV_DESCRIPT);
							utl_file.put_line(fileHandler, VV_COMMENTAIRE);
							utl_file.put_line(fileHandler, '');
							utl_file.put_line(fileHandler, VV_COLONNE);
						
							g_step := 'MAIN 010.b : INSERTION DE CHAQUE LIGNE DE LA REQUÊTE DANS LE FICHIER DE SORTIE.';
							log_msg(g_step);
							vn_nb_ligne := 0;
							FOR i IN vv_result_req.first .. vv_result_req.last LOOP
								utl_file.put_line(fileHandler, replace(vv_result_req(i),chr(10),' '));
								vn_nb_ligne := vn_nb_ligne + 1;
							END LOOP;
							g_step := 'MAIN 010.c : INSERTION DU NOM DU FICHIER DANS LA TABLE DE TRAVAIL DKA_SCTRLMOD_MOA_FILE.';
							log_msg(g_step);
							BEGIN
								INSERT INTO DKA_SCTRLMOD_MOA_FILE
									(ENTITE,
									 MODULE,
									 REQUEST_ID,
									 FILE_NAME,
									 NB_LINE,
									 CREATED_BY,
									 CREATION_DATE)
								VALUES
									(P_Entite,
									 P_Module,
									 gv_request_id,
									 filename,
									 vn_nb_ligne,
									 gv_created_by,
									 SYSDATE);
								COMMIT;
							END;
							utl_file.fclose(fileHandler);
						END IF;
					END IF;
				
				ELSIF ((vn_nb_jour LIKE '%MERCREDI%' OR vn_nb_jour LIKE '%WEDNESDAY%') AND Rec_requete_mod.mercredi = 'OUI') THEN-- new if
					IF VV_REQUETE IS NOT NULL THEN
						g_step := 'MAIN 008 : DEFINITION DU NOM DE FICHIER.';
						log_msg(g_step);
						filename := gv_request_id || '_' || VV_NOM_COURT || '.csv';
					
						g_step := 'MAIN 009 : EXECUTION DE LA REQUETE STOCKEE POUR LE CONTRÔLE : ' || VV_NOM_COURT || '('|| Rec_requete_mod.flex_value || ')';
						log_msg(g_step);
						
						--< OBE artf2286611
						BEGIN					
							  EXECUTE IMMEDIATE VV_REQUETE BULK COLLECT
							   INTO vv_result_req;
						EXCEPTION
						WHEN OTHERS THEN
						  g_step := 'ERREUR < '||TO_CHAR(SQLERRM)||' > LORS DE L''EXECUTION DE LA REQUETE : ' || VV_NOM_COURT || '('|| Rec_requete_mod.flex_value || ')';
						  log_msg(g_step);
						  vn_err_flag := 1;
						END;	
						--> OBE artf2286611	
				
						-- Si le fichier ne sera pas vide alors nous créons le fichier.
						IF vv_result_req.COUNT != 0 THEN
							g_step := 'MAIN 010.a : CREATION DU FICHIER ET DE SON ENTÊTE : ' || filename;
							log_msg(g_step);
							fileHandler := utl_file.fopen(cv_directory,
														  filename,
														  'w');
							utl_file.put_line(fileHandler, VV_DESCRIPT);
							utl_file.put_line(fileHandler, VV_COMMENTAIRE);
							utl_file.put_line(fileHandler, '');
							utl_file.put_line(fileHandler, VV_COLONNE);
						
							g_step := 'MAIN 010.b : INSERTION DE CHAQUE LIGNE DE LA REQUÊTE DANS LE FICHIER DE SORTIE.';
							log_msg(g_step);
							vn_nb_ligne := 0;
							FOR i IN vv_result_req.first .. vv_result_req.last LOOP
								utl_file.put_line(fileHandler, replace(vv_result_req(i),chr(10),' '));
								vn_nb_ligne := vn_nb_ligne + 1;
							END LOOP;
							g_step := 'MAIN 010.c : INSERTION DU NOM DU FICHIER DANS LA TABLE DE TRAVAIL DKA_SCTRLMOD_MOA_FILE.';
							log_msg(g_step);
							BEGIN
								INSERT INTO DKA_SCTRLMOD_MOA_FILE
									(ENTITE,
									 MODULE,
									 REQUEST_ID,
									 FILE_NAME,
									 NB_LINE,
									 CREATED_BY,
									 CREATION_DATE)
								VALUES
									(P_Entite,
									 P_Module,
									 gv_request_id,
									 filename,
									 vn_nb_ligne,
									 gv_created_by,
									 SYSDATE);
								COMMIT;
							END;
							utl_file.fclose(fileHandler);
						END IF;
					END IF;
				
				ELSIF ( (vn_nb_jour LIKE '%JEUDI%' OR vn_nb_jour LIKE '%THURSDAY%') AND Rec_requete_mod.jeudi LIKE '%OUI%') THEN -- new if
					IF VV_REQUETE IS NOT NULL THEN
						g_step := 'MAIN 008 : DEFINITION DU NOM DE FICHIER.';
						log_msg(g_step);
						filename := gv_request_id || '_' || VV_NOM_COURT || '.csv';
					
						g_step := 'MAIN 009 : EXECUTION DE LA REQUETE STOCKEE POUR LE CONTRÔLE : ' || VV_NOM_COURT || '('|| Rec_requete_mod.flex_value || ')';
						log_msg(g_step);
						
						--< OBE artf2286611
						BEGIN					
							  EXECUTE IMMEDIATE VV_REQUETE BULK COLLECT
							   INTO vv_result_req;
						EXCEPTION
						WHEN OTHERS THEN
						  g_step := 'ERREUR < '||TO_CHAR(SQLERRM)||' > LORS DE L''EXECUTION DE LA REQUETE : ' || VV_NOM_COURT || '('|| Rec_requete_mod.flex_value || ')';
						  log_msg(g_step);
						  vn_err_flag := 1;
						END;	
						--> OBE artf2286611	
				
						-- Si le fichier ne sera pas vide alors nous créons le fichier.
						IF vv_result_req.COUNT != 0 THEN
							g_step := 'MAIN 010.a : CREATION DU FICHIER ET DE SON ENTÊTE : ' || filename;
							log_msg(g_step);
							fileHandler := utl_file.fopen(cv_directory,
														  filename,
														  'w');
							utl_file.put_line(fileHandler, VV_DESCRIPT);
							utl_file.put_line(fileHandler, VV_COMMENTAIRE);
							utl_file.put_line(fileHandler, '');
							utl_file.put_line(fileHandler, VV_COLONNE);
						
							g_step := 'MAIN 010.b : INSERTION DE CHAQUE LIGNE DE LA REQUÊTE DANS LE FICHIER DE SORTIE.';
							log_msg(g_step);
							vn_nb_ligne := 0;
							FOR i IN vv_result_req.first .. vv_result_req.last LOOP
								utl_file.put_line(fileHandler, replace(vv_result_req(i),chr(10),' '));
								vn_nb_ligne := vn_nb_ligne + 1;
							END LOOP;
							g_step := 'MAIN 010.c : INSERTION DU NOM DU FICHIER DANS LA TABLE DE TRAVAIL DKA_SCTRLMOD_MOA_FILE.';
							log_msg(g_step);
							BEGIN
								INSERT INTO DKA_SCTRLMOD_MOA_FILE
									(ENTITE,
									 MODULE,
									 REQUEST_ID,
									 FILE_NAME,
									 NB_LINE,
									 CREATED_BY,
									 CREATION_DATE)
								VALUES
									(P_Entite,
									 P_Module,
									 gv_request_id,
									 filename,
									 vn_nb_ligne,
									 gv_created_by,
									 SYSDATE);
								COMMIT;
							END;
							utl_file.fclose(fileHandler);
						END IF;
					END IF;
				
				ELSIF ((vn_nb_jour LIKE '%VENDREDI%' OR vn_nb_jour LIKE '%FRIDAY%') AND Rec_requete_mod.vendredi = 'OUI') THEN-- new if
					IF VV_REQUETE IS NOT NULL THEN
						g_step := 'MAIN 008 : DEFINITION DU NOM DE FICHIER.';
						log_msg(g_step);
						filename := gv_request_id || '_' || VV_NOM_COURT || '.csv';
					
						g_step := 'MAIN 009 : EXECUTION DE LA REQUETE STOCKEE POUR LE CONTRÔLE : ' || VV_NOM_COURT || '('|| Rec_requete_mod.flex_value || ')';
						log_msg(g_step);
						
						--< OBE artf2286611
						BEGIN					
							  EXECUTE IMMEDIATE VV_REQUETE BULK COLLECT
							   INTO vv_result_req;
						EXCEPTION
						WHEN OTHERS THEN
						  g_step := 'ERREUR < '||TO_CHAR(SQLERRM)||' > LORS DE L''EXECUTION DE LA REQUETE : ' || VV_NOM_COURT || '('|| Rec_requete_mod.flex_value || ')';
						  log_msg(g_step);
						  vn_err_flag := 1;
						END;	
						--> OBE artf2286611	
				
						-- Si le fichier ne sera pas vide alors nous créons le fichier.
						IF vv_result_req.COUNT != 0 THEN
							g_step := 'MAIN 010.a : CREATION DU FICHIER ET DE SON ENTÊTE : ' || filename;
							log_msg(g_step);
							fileHandler := utl_file.fopen(cv_directory,
														  filename,
														  'w');
							utl_file.put_line(fileHandler, VV_DESCRIPT);
							utl_file.put_line(fileHandler, VV_COMMENTAIRE);
							utl_file.put_line(fileHandler, '');
							utl_file.put_line(fileHandler, VV_COLONNE);
						
							g_step := 'MAIN 010.b : INSERTION DE CHAQUE LIGNE DE LA REQUÊTE DANS LE FICHIER DE SORTIE.';
							log_msg(g_step);
							vn_nb_ligne := 0;
							FOR i IN vv_result_req.first .. vv_result_req.last LOOP
								utl_file.put_line(fileHandler, replace(vv_result_req(i),chr(10),' '));
								vn_nb_ligne := vn_nb_ligne + 1;
							END LOOP;
							g_step := 'MAIN 010.c : INSERTION DU NOM DU FICHIER DANS LA TABLE DE TRAVAIL DKA_SCTRLMOD_MOA_FILE.';
							log_msg(g_step);
							BEGIN
								INSERT INTO DKA_SCTRLMOD_MOA_FILE
									(ENTITE,
									 MODULE,
									 REQUEST_ID,
									 FILE_NAME,
									 NB_LINE,
									 CREATED_BY,
									 CREATION_DATE)
								VALUES
									(P_Entite,
									 P_Module,
									 gv_request_id,
									 filename,
									 vn_nb_ligne,
									 gv_created_by,
									 SYSDATE);
								COMMIT;
							END;
							utl_file.fclose(fileHandler);
						END IF;
					END IF;
			
				ELSIF ((vn_nb_jour LIKE '%SAMEDI%' OR vn_nb_jour LIKE '%SATURDAY%') AND Rec_requete_mod.samedi = 'OUI') THEN-- new if
					IF VV_REQUETE IS NOT NULL THEN
						g_step := 'MAIN 008 : DEFINITION DU NOM DE FICHIER.';
						log_msg(g_step);
						filename := gv_request_id || '_' || VV_NOM_COURT || '.csv';
					
						g_step := 'MAIN 009 : EXECUTION DE LA REQUETE STOCKEE POUR LE CONTRÔLE : ' || VV_NOM_COURT || '('|| Rec_requete_mod.flex_value || ')';
						log_msg(g_step);
						
						--< OBE artf2286611
						BEGIN					
							  EXECUTE IMMEDIATE VV_REQUETE BULK COLLECT
							   INTO vv_result_req;
						EXCEPTION
						WHEN OTHERS THEN
						  g_step := 'ERREUR < '||TO_CHAR(SQLERRM)||' > LORS DE L''EXECUTION DE LA REQUETE : ' || VV_NOM_COURT || '('|| Rec_requete_mod.flex_value || ')';
						  log_msg(g_step);
						  vn_err_flag := 1;
						END;	
						--> OBE artf2286611	
				
						-- Si le fichier ne sera pas vide alors nous créons le fichier.
						IF vv_result_req.COUNT != 0 THEN
							g_step := 'MAIN 010.a : CREATION DU FICHIER ET DE SON ENTÊTE : ' || filename;
							log_msg(g_step);
							fileHandler := utl_file.fopen(cv_directory,
														  filename,
														  'w');
							utl_file.put_line(fileHandler, VV_DESCRIPT);
							utl_file.put_line(fileHandler, VV_COMMENTAIRE);
							utl_file.put_line(fileHandler, '');
							utl_file.put_line(fileHandler, VV_COLONNE);
						
							g_step := 'MAIN 010.b : INSERTION DE CHAQUE LIGNE DE LA REQUÊTE DANS LE FICHIER DE SORTIE.';
							log_msg(g_step);
							vn_nb_ligne := 0;
							FOR i IN vv_result_req.first .. vv_result_req.last LOOP
								utl_file.put_line(fileHandler, replace(vv_result_req(i),chr(10),' '));
								vn_nb_ligne := vn_nb_ligne + 1;
							END LOOP;
							g_step := 'MAIN 010.c : INSERTION DU NOM DU FICHIER DANS LA TABLE DE TRAVAIL DKA_SCTRLMOD_MOA_FILE.';
							log_msg(g_step);
							BEGIN
								INSERT INTO DKA_SCTRLMOD_MOA_FILE
									(ENTITE,
									 MODULE,
									 REQUEST_ID,
									 FILE_NAME,
									 NB_LINE,
									 CREATED_BY,
									 CREATION_DATE)
								VALUES
									(P_Entite,
									 P_Module,
									 gv_request_id,
									 filename,
									 vn_nb_ligne,
									 gv_created_by,
									 SYSDATE);
								COMMIT;
							END;
							utl_file.fclose(fileHandler);
						END IF;
					END IF;
			
				ELSIF ((vn_nb_jour LIKE '%DIMANCHE%' OR vn_nb_jour LIKE '%SUNDAY%') AND Rec_requete_mod.dimanche = 'OUI') THEN-- new if
					IF VV_REQUETE IS NOT NULL THEN
						g_step := 'MAIN 008 : DEFINITION DU NOM DE FICHIER.';
						log_msg(g_step);
						filename := gv_request_id || '_' || VV_NOM_COURT || '.csv';
					
						g_step := 'MAIN 009 : EXECUTION DE LA REQUETE STOCKEE POUR LE CONTRÔLE : ' || VV_NOM_COURT || '('|| Rec_requete_mod.flex_value || ')';
						log_msg(g_step);
						
						
						BEGIN					
							  EXECUTE IMMEDIATE VV_REQUETE BULK COLLECT
							   INTO vv_result_req;
						EXCEPTION
						WHEN OTHERS THEN
						  g_step := 'ERREUR < '||TO_CHAR(SQLERRM)||' > LORS DE L''EXECUTION DE LA REQUETE : ' || VV_NOM_COURT || '('|| Rec_requete_mod.flex_value || ')';
						  log_msg(g_step);
						  vn_err_flag := 1;
						END;	
						
				
						-- Si le fichier ne sera pas vide alors nous créons le fichier.
						IF vv_result_req.COUNT != 0 THEN
							g_step := 'MAIN 010.a : CREATION DU FICHIER ET DE SON ENTÊTE : ' || filename;
							log_msg(g_step);
							fileHandler := utl_file.fopen(cv_directory,
														  filename,
														  'w');
							utl_file.put_line(fileHandler, VV_DESCRIPT);
							utl_file.put_line(fileHandler, VV_COMMENTAIRE);
							utl_file.put_line(fileHandler, '');
							utl_file.put_line(fileHandler, VV_COLONNE);
						
							g_step := 'MAIN 010.b : INSERTION DE CHAQUE LIGNE DE LA REQUÊTE DANS LE FICHIER DE SORTIE.';
							log_msg(g_step);
							vn_nb_ligne := 0;
							FOR i IN vv_result_req.first .. vv_result_req.last LOOP
								utl_file.put_line(fileHandler, replace(vv_result_req(i),chr(10),' '));
								vn_nb_ligne := vn_nb_ligne + 1;
							END LOOP;
							g_step := 'MAIN 010.c : INSERTION DU NOM DU FICHIER DANS LA TABLE DE TRAVAIL DKA_SCTRLMOD_MOA_FILE.';
							log_msg(g_step);
							BEGIN
								INSERT INTO DKA_SCTRLMOD_MOA_FILE
									(ENTITE,
									 MODULE,
									 REQUEST_ID,
									 FILE_NAME,
									 NB_LINE,
									 CREATED_BY,
									 CREATION_DATE)
								VALUES
									(P_Entite,
									 P_Module,
									 gv_request_id,
									 filename,
									 vn_nb_ligne,
									 gv_created_by,
									 SYSDATE);
								COMMIT;
							END;
							utl_file.fclose(fileHandler);
						END IF;
					END IF;
					
				ELSE-- add else big fail
                    
					g_step := 'LA REQUETE N° ' || Rec_requete_mod.flex_value ||
                      ' N''EST PAS CONFIGUREE POUR CE JOUR';
                    log_msg(g_step);
					--raise e_erreur_jour;
				END IF; -- big if 
            END LOOP;
            CLOSE Cur_requete_mod;
        END IF;
        COMMIT;
		
		----------------------------------------------------------------
    -- Etape 4 : Lancement du traitement DKA_SCTRLMOD_MOA_MAIL.
		----------------------------------------------------------------
        g_step := 'MAIN 011 : LANCEMENT DU TRAITEMENT DKA_SCTRLMOD_MOA_MAIL D''ENVOI PAR MAIL.';
		log_msg(g_step);
    IF P_Envoi_Mail = 'OUI' THEN
        lance_trait_mail(Pv_Errbuf,
                         Pn_Retcode,
                         gv_request_id,
                         'DKA_SCTRLMOD_MOA_MAIL');
    END IF;
    IF Pn_Retcode != 0 AND P_Envoi_Mail = 'OUI' THEN
        g_step := 'MAIN 011 : ERROR - LANCEMENT DU TRAITEMENT D''ENVOI PAR MAIL.';
        raise e_main;
    END IF;
		
		----------------------------------------------------------------
		--Edition fichier de sortie
		----------------------------------------------------------------
		g_step := 'MAIN 012 : EDITION FICHIER DE SORTIE.';
		log_msg(g_step);
		--procedure d'edition de la sortie
		edition_output(Pv2_Errbuf,Pn2_Retcode,P_Entite,P_Module,P_N_Requete,P_Envoi_Mail);
		IF Pn2_Retcode != 0 THEN
			RAISE e_edition_output;
		END IF;
		
		IF Pn2_Retcode > Pn_Retcode THEN
			Pn_Retcode := Pn2_Retcode;
		END IF;
		
    g_step := 'MAIN 999 : FIN';
    log_msg(g_step);
	
	--< OBE artf2286611
	IF vn_err_flag != 0 THEN
		Pn_Retcode := 1;
	END IF;
	--> OBE artf2286611
		
    EXCEPTION
  		WHEN e_edition_output THEN
  			Pv_Errbuf  := 'Erreur procedure EDITION_OUTPUT';
  			Pn_Retcode := 2;
  			log_msg(Pv_Errbuf);
      WHEN e_main THEN
        log_msg('ERREUR - ' || g_step);
        Pv_Errbuf := 'ERREUR : ' || SQLERRM;
        log_msg(Pv_Errbuf);
        Pn_Retcode := 2;
	  WHEN e_erreur_jour THEN
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

END DKA_SCTRLMOD_MOA_PKG;
/

SHOW ERRORS;
EXIT