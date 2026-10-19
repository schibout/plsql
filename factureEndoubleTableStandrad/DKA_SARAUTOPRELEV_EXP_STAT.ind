CREATE OR REPLACE PACKAGE BODY APPS.DKA_SARETAT_AVOIR_REG_PKG AS
--------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_SARETAT_AVOIR_REG_PKG
  -- Auteur           : ANAS RAOUF
  -- Date de création : 10/10/2024
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------

  --------------------------------------------------------------------------------

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    gn_user_id            fnd_user.user_id%TYPE;
    gn_login_id           fnd_logins.login_id%TYPE;
    gn_org_id             hr_all_organization_units.organization_id%TYPE;
    gn_request_id         fnd_concurrent_requests.request_id%TYPE;
    gv_base               VARCHAR2(50);
    gv_conn               VARCHAR2(30);
    gv_base_prod          VARCHAR2(30);
    gv_expediteur         VARCHAR2(50);
    gv_subject            VARCHAR2(4000);
    gv_body               VARCHAR2(4000);
    gv_type_attachment    VARCHAR2(50);
    gn_amt                BINARY_INTEGER := 672 * 3; /* ensures proper format;  2016 */
    gv_plat_appro_mail    VARCHAR2(240);
    gv_plat_appro_name    VARCHAR2(240);
    pv_adresse_mail       VARCHAR2(240);
    gv_directory_path     VARCHAR2(240);
    gv_mail_test          VARCHAR2(240) := NULL;--YWA artf2120398
    l_line_count          NUMBER;
    -- Message d'information.
    g_step                VARCHAR2(500);

    -- Variable contenant l'entête et le corps du mail.
    gv_objet              VARCHAR2(4000);
    gv_corps              VARCHAR2(4000);
    boundary              CONSTANT VARCHAR2(256) := '=_NextPart_DC7E1BB5_1105_4DB3_BAE3_2A6208EB099D';
    first_boundary        CONSTANT VARCHAR2(256) := '--'
                                             || boundary
                                             || utl_tcp.crlf;
    last_boundary         CONSTANT VARCHAR2(256) := '--'
                                            || boundary
                                            || '--'
                                            || utl_tcp.crlf;
    multipart_mime_type   CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary=' || boundary;
    max_line_width        PLS_INTEGER := 54;
    g_request_id          NUMBER := fnd_global.conc_request_id;
    g_cdir                VARCHAR2(30) := 'DKA_OUT_DIR';

               K_DIRECTORY       CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';

    g_filename            VARCHAR2(100) := 'mail.htm';
    g_date                DATE := sysdate;
    g_date_exec           VARCHAR2(50);
    g_avoir_file          VARCHAR2(240);
    g_retproc             NUMBER := 0;
    g_sqlerrm             VARCHAR2(500) := NULL;
    g_package             VARCHAR2(30) := 'DKA_SARSELECAVOIR';
    g_header_file         VARCHAR2(240);
    g_line_file           VARCHAR2(240);
    g_hold_file           VARCHAR2(240);
    g_payment_file        VARCHAR2(240);
    l_fichier_avoir       utl_file.file_type;
    g_separateur          VARCHAR2(1) := ';';
    g_pic_file            VARCHAR2(240);
    v_path                VARCHAR2(1000);
    l_str                 VARCHAR2(4000);
    TYPE liste_destinataires IS
        TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
     -----------------------------------------------------------------

    PROCEDURE out_msg (
        p_message IN VARCHAR2
    ) IS
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

    PROCEDURE log_msg (
        p_message IN VARCHAR2
    ) IS
        l_message VARCHAR2(1000);
    BEGIN
        l_message := substr(p_message, 1, 1000);
        IF ( l_message IS NULL ) THEN
            l_message := to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS');
        END IF;

        fnd_file.put_line(fnd_file.log, l_message);
    END log_msg;

    ----------------------------------------------------------------------------
    --  Nom           : init
    --  Description   : Procédure d'initialisation
    --
    --  PARAMETRES :
    --    pv_errbuf   Entrée/Sortie          message d'erreur
    --    VALEUR RETOURNEE :  pn_retcode
    --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
    ----------------------------------------------------------------------------

    PROCEDURE init (
        p_errbuf    OUT   VARCHAR2,
        p_retcode   OUT   NUMBER
    ) IS
        rec_param dka_parameters%rowtype;
        e_expediteur_vide EXCEPTION;
    BEGIN
        --Init des variables de sortie
        p_retcode := 0;
        p_errbuf := '';
        SELECT
            ad.directory_path
        INTO gv_directory_path
        FROM
            all_directories ad
        WHERE
            ad.directory_name = 'DKA_OUT_DIR';

        dka_tools_pkg.get_parameter('SPOCDE_CITY', 'EXPEDITEUR_MAIL', rec_param, p_errbuf, p_retcode);
        gv_expediteur := rec_param.varchar2_value;
        IF gv_expediteur IS NULL THEN
            RAISE e_expediteur_vide;
        END IF;
        SELECT
            name
        INTO gv_base
        FROM
            v$database;

        dka_tools_pkg.get_parameter('SPOCDE_CITY', 'SMTP_CONNECTION', rec_param, p_errbuf, p_retcode);
        gv_conn := rec_param.varchar2_value;

        --Reinit des variables de sortie
        p_retcode := 0;
        p_errbuf := '';
    EXCEPTION
        WHEN e_expediteur_vide THEN
            p_errbuf := 'Aucun expéditeur trouvé';
            dka_tools_pkg.put_log_message(p_errbuf);
            p_retcode := 2;
        WHEN OTHERS THEN
            p_errbuf := 'Erreur procedure INIT :'
                        || g_step
                        || chr(10)
                        || sqlerrm;
            dka_tools_pkg.put_log_message(p_errbuf);
            p_retcode := 2;
    END init;
----------------------------------------------------------------------------
    --  Nom           : write_boundary
    --  Description   : Procédure
    --
    --  PARAMETRES :
    ----------------------------------------------------------------------------

    PROCEDURE write_boundary (
        conn IN OUT NOCOPY utl_smtp.connection,
        last IN BOOLEAN DEFAULT false
    ) IS
    BEGIN
        IF ( last ) THEN
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

    PROCEDURE begin_attachment (
        conn IN OUT NOCOPY utl_smtp.connection,
        mime_type      IN   VARCHAR2 DEFAULT 'text/plain',
        inline         IN   BOOLEAN DEFAULT true,
        filename       IN   VARCHAR2 DEFAULT NULL,
        transfer_enc   IN   VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        write_boundary(conn);
        utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Type: '
                                                          || mime_type
                                                          || utl_tcp.crlf));

        IF ( filename IS NOT NULL ) THEN
            IF ( inline ) THEN
                utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Disposition: '
                                                                  || 'inline; filename="'
                                                                  || filename
                                                                  || '"'
                                                                  || utl_tcp.crlf));

            ELSE
                utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Disposition: '
                                                                  || 'attachment; filename="'
                                                                  || filename
                                                                  || '"'
                                                                  || utl_tcp.crlf));
            END IF;
        END IF;

        IF ( transfer_enc IS NOT NULL ) THEN
            utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Transfer-Encoding: '
                                                              || transfer_enc
                                                              || utl_tcp.crlf));
        END IF;

        utl_smtp.write_data(conn, utl_tcp.crlf);
    END begin_attachment;


    ----------------------------------------------------------------------------
    --  Nom           : end_attachment
    --  Description   : Procédure
    --
    --  PARAMETRES :
    ----------------------------------------------------------------------------

    PROCEDURE end_attachment (
        conn IN OUT NOCOPY utl_smtp.connection,
        last IN BOOLEAN DEFAULT false
    ) IS
    BEGIN
        utl_smtp.write_data(conn, utl_tcp.crlf || utl_tcp.crlf);
        IF ( last ) THEN
            write_boundary(conn, last);
        END IF;
    END end_attachment;


-- -----------------------------------------------------------------------------
     -- Nom              : check_value_set
     -- Description      : Vérifie de l'existence d'un jeu de valeurs et provoque une exception s'il n'existe pas
     -- -----------------------------------------------------------------------------

    PROCEDURE check_value_set (
        p_value_set_name   IN    fnd_flex_value_sets.flex_value_set_name%TYPE,
        p_errbuf           OUT   VARCHAR2,
        p_retcode          OUT   NUMBER
    ) IS

        CURSOR cur_value_set (
            p_value_set_name IN VARCHAR2
        ) IS
        SELECT
            ffvs.flex_value_set_id,
            SUM(
                CASE
                    WHEN ffv.enabled_flag = 'Y'
                         AND sysdate BETWEEN trunc(nvl(ffv.start_date_active, sysdate)) AND trunc(nvl(ffv.end_date_active, sysdate
                         + 1)) THEN
                        1
                    ELSE
                        0
                END
            ) AS active_lines,
            COUNT(ffv.flex_value_id) AS lines
        FROM
            fnd_flex_value_sets   ffvs
            LEFT OUTER JOIN fnd_flex_values       ffv ON ( ffvs.flex_value_set_id = ffv.flex_value_set_id )
        WHERE
            ffvs.flex_value_set_name = p_value_set_name
        GROUP BY
            ffvs.flex_value_set_id;

        l_value_set   cur_value_set%rowtype;
        l_ok          BOOLEAN := false;
    BEGIN
        OPEN cur_value_set(p_value_set_name);
        FETCH cur_value_set INTO l_value_set;
        IF cur_value_set%notfound THEN
            log_msg('Le jeu de valeurs '
                    || p_value_set_name
                    || ' n''existe pas.');
            p_retcode := 2;
        ELSIF l_value_set.lines = 0 THEN
            log_msg('Aucune ligne n''est configurée dans le jeu de valeurs '
                    || p_value_set_name
                    || '.');
            p_retcode := 2;
        ELSIF l_value_set.active_lines = 0 THEN
            log_msg('Aucune valeur n''est active dans le jeu de valeurs '
                    || p_value_set_name
                    || '.');
            p_retcode := 2;
        ELSE
            log_msg('Jeu de valeurs OK : ' || p_value_set_name);
            l_ok := true;
        END IF;

        CLOSE cur_value_set;
        IF NOT l_ok THEN
            p_retcode := 2;
        END IF;
    END check_value_set;

-------------------------------------------------------------------------------------
    --  Nom           : SEND_MSG
    --  Description   : Envoi du message avec fichier.
    --
    --  PARAMETRES    :
    --  Pv_Errbuf      IN OUT       Message d'avertissement
    --  Pn_Retcode  IN OUT     Code erreur
              --  P_REGION     IN Region
    --------------------------------------------------------------------------------------
   PROCEDURE SEND_MSG(p_tab_to      liste_destinataires,
                     p_tab_cc      liste_destinataires,
                     p_from        IN VARCHAR2,
                     p_subject     IN VARCHAR2,
           -- P_period           IN VARCHAR2,
           P_region              IN VARCHAR2,
                     p_text_msg    IN VARCHAR2 DEFAULT NULL,
                     p_attach_name IN VARCHAR2 DEFAULT NULL,
                     p_attach_mime IN VARCHAR2 DEFAULT NULL,
                     p_smtp_host   IN VARCHAR2,
                     p_smtp_port   IN NUMBER DEFAULT 25 ) AS
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
                          'Content-Type: ' || p_attach_mime || '; name="' ||P_REGION||' - Liste avoirs - '||
                      TO_CHAR(g_date, 'DDMMYYYY')||'.csv' || '"' ||
                          UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Transfer-Encoding: base64' ||
                          UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                         'Content-Disposition: attachment; filename="' ||P_REGION||' - Liste avoirs - '||
                      TO_CHAR(g_date, 'DDMMYYYY')||'.csv' || '"' ||
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

  /*============================================================================*/
  -- Procedure         : writeout
  -- Description       : Ecriture dans fichier *.OUT
  -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
  -- Parametres sortie : AUCUN
  -- Auteur            :
  /*============================================================================*/

    PROCEDURE writeout (
        p_message IN VARCHAR2
    ) IS
        l_procedure   VARCHAR2(30) := 'writeout';
        v_etape       VARCHAR2(100);
    BEGIN
        fnd_file.put_line(fnd_file.output, p_message);
    EXCEPTION
        WHEN OTHERS THEN
            g_retproc := 1;
            g_sqlerrm := substr(sqlerrm, 1, 200);
            fnd_file.put_line(fnd_file.log, '-------------------- ERREUR --------------------');
            fnd_file.put_line(fnd_file.log, 'Package   : ' || g_package);
            fnd_file.put_line(fnd_file.log, 'Procedure : ' || l_procedure);
            fnd_file.put_line(fnd_file.log, 'Exception : OTHERS');
            fnd_file.put_line(fnd_file.log, 'Message   : ' || v_etape);
            fnd_file.put_line(fnd_file.log, 'Cause     : ' || g_sqlerrm);
    END writeout;

  /*============================================================================*/
  -- Procedure         : extraction_avoir_reglee
  -- Description       : Ecriture dans fichier *.OUT
  -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
  -- Parametres sortie : AUCUN
  -- Auteur            :
  /*============================================================================*/
PROCEDURE extraction_avoir_reglee (
        pv_errbuf     IN OUT  VARCHAR2,
        pn_retcode    IN OUT  NUMBER,
    p_region      IN      VARCHAR2,
        vv_filename   OUT     VARCHAR2
    ) IS

    CURSOR cur_avoir_reg(p_region IN VARCHAR2)
    IS
      SELECT * FROM dka_ar_remb_avoir_list where REMB = 'Y' and substr(UO,1,3) = p_region;
    
  CURSOR cur_before_camp(p_region IN VARCHAR2)
  IS
  SELECT dar.* 
  FROM dka_ar_remboursement_avoirs dar , DKA_ARREMB_REPORTING dr
  WHERE dar.REMB = 'Y' 
  AND dar.num_avoir = dr.num_avoir
    AND dar.uo = dr.uo
  AND ACTIVITY_FLAG = 'Y'
  AND substr(dar.UO,1,3) = p_region;
  
    vn_request_id      fnd_concurrent_requests.request_id%TYPE;
        l_avoirs_lignes    VARCHAR2(2000);
        vv_step            VARCHAR2(500);
        count_rows         NUMBER;
        my_exeception EXCEPTION;
        l_message_entete   VARCHAR2(2000);  
    rec_param dka_parameters%rowtype;
    v_flag_campagne    VARCHAR2(10);
BEGIN

        vv_step := '001';
        dka_tools_pkg.get_parameter('DKA_SAPAUTORGT', 'FLAG_CAMPAGNE', rec_param, pv_errbuf, pn_retcode);
        v_flag_campagne := rec_param.varchar2_value;
  
        IF utl_file.is_open(l_fichier_avoir) THEN
            utl_file.fclose(l_fichier_avoir);
        END IF;
        vv_step := '002';
        l_line_count := 0;
        g_avoir_file := p_region
                        || ' - Liste avoirs - '
                        || to_char(g_date, 'DDMMYYYY')
                        || '.csv';

        vv_filename := g_avoir_file;
        vv_step := '003 : Ouverture du fichier : ' || vv_filename;
        dka_tools_pkg.put_log_message(vv_step);
        l_fichier_avoir := utl_file.fopen(g_cdir, vv_filename, 'w',32767);
        l_avoirs_lignes := 'UO'
                           || g_separateur
                           || 'CODE_CHARGE_RECOUVR'
                           || g_separateur
                           || 'NOM_CLIENT'
                           || g_separateur
                           || 'CODE_CLIENT_ORACLE'
                           || g_separateur
                           || 'CODE_ANAEL'
                           || g_separateur
                           || 'NUM_AVOIR'
                           || g_separateur
                           || 'DATE_AVOIR'
                           || g_separateur
                           || 'MONTANT_AVOIR'
                           || g_separateur
                           || 'MONTANT_NON_SOLDE'
                           || g_separateur
                           || 'COMMENTAIRE'
                           || g_separateur
                           || 'IBAN'
                           || g_separateur
                           || 'REGLEE';

        utl_file.put_line(l_fichier_avoir, l_avoirs_lignes);
        vv_step := 'Insertion en table temporaire';
        dka_tools_pkg.put_log_message(vv_step);
    
    IF v_flag_campagne = 'N' THEN
    
    FOR cur_avoir IN cur_before_camp(p_region) LOOP
            l_message_entete := cur_avoir.uo
                                || g_separateur
                                || cur_avoir.code_charge
                                || g_separateur
                                || cur_avoir.NOM_CLIENT
                                || g_separateur
                                || chr(28)
                                || to_char(cur_avoir.code_oracle, 'fm00000000')
                                || g_separateur
                                || cur_avoir.code_anael
                                || g_separateur
                                || cur_avoir.num_avoir
                                || g_separateur
                                || to_char(cur_avoir.date_avoir, 'DD/MM/YYYY')
                                || g_separateur
                                || replace(to_char(cur_avoir.AMT_AVOIR), '.', ',')
                                || g_separateur
                                || replace(to_char(cur_avoir.AMT_NON_SLD), '.', ',')
                                || g_separateur
                                || cur_avoir.commentaire
                                || g_separateur
                                || cur_avoir.iban
                                || g_separateur
                                || cur_avoir.reglee;                               

            l_line_count := l_line_count + 1;
            utl_file.put_line(l_fichier_avoir, l_message_entete);
            
            END LOOP;
    
    ELSE
    
    FOR cur_avoir IN cur_avoir_reg(p_region) LOOP
            l_message_entete := cur_avoir.uo
                                || g_separateur
                                || cur_avoir.code_charge
                                || g_separateur
                                || cur_avoir.NOM_CLIENT
                                || g_separateur
                                || chr(28)
                                || to_char(cur_avoir.code_oracle, 'fm00000000')
                                || g_separateur
                                || cur_avoir.code_anael
                                || g_separateur
                                || cur_avoir.num_avoir
                                || g_separateur
                                || to_char(cur_avoir.date_avoir, 'DD/MM/YYYY')
                                || g_separateur
                                || replace(to_char(cur_avoir.AMT_AVOIR), '.', ',')
                                || g_separateur
                                || replace(to_char(cur_avoir.AMT_NON_SLD), '.', ',')
                                || g_separateur
                                || cur_avoir.commentaire
                                || g_separateur
                                || cur_avoir.iban
                                || g_separateur
                                || cur_avoir.reglee;                               

            l_line_count := l_line_count + 1;
            utl_file.put_line(l_fichier_avoir, l_message_entete);
            
        END LOOP;
    
    END IF;
    
    --Fermeture du fichier
      UTL_FILE.FCLOSE(l_fichier_avoir);
    
EXCEPTION
WHEN no_data_found THEN
  pv_errbuf := 'aucune données trouvées';
  dka_tools_pkg.put_log_message(pv_errbuf);
  pn_retcode := 1;
END;
  
  ------------------------------------------------------------------------------------
  -- Nom              : Main
  -- Description      : Procédure principale du traitement
  --
  -- PARAMETRES       : pp_errbuf         Sortie Message d'erreur
  --                    pp_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --                    p_nbre_jours     Nombre de jours
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------

    PROCEDURE main (
        p_errbuf       IN OUT  VARCHAR2,
        p_retcode      OUT     NUMBER,
        p_region       IN      VARCHAR2
    ) IS

        vv_ligne                 VARCHAR2(4000);
        vn_nb_lignes             NUMBER := -1;
        l_file                   utl_file.file_type;
        va_file_id               utl_file.file_type;
        vv_phase                 VARCHAR2(100);
        vv_status                VARCHAR2(100);
        vv_dev_phase             VARCHAR2(100);
        vv_filename              VARCHAR2(80);
        vv_dev_status            VARCHAR2(100);
        vv_message               VARCHAR2(100);
        pv_errbuf                VARCHAR2(2500);
        nom_program              VARCHAR2(2500);
        vvn_retcode              NUMBER;
        pn_retcode               NUMBER;
        vv_directory_name        dba_directories.directory_path%TYPE;
        v_errbuf                 VARCHAR2(2500);
        v_retcode                NUMBER;
        erreur_programme EXCEPTION;
        erreur_mail EXCEPTION;
        cv_line                  VARCHAR2(100);
        v_current_program_unit   VARCHAR2(30);
        vn_nb_line               NUMBER;
        vv_file_name             VARCHAR2(70);
        vv_adresses              VARCHAR2(32000);
        vv_adresses_cc           VARCHAR2(32000);
        vt_adr_to                liste_destinataires;
        vt_adr_cc                liste_destinataires;
        vn_cpt                   NUMBER;
        vn_cptt                  NUMBER;
        rec_param                dka_parameters%rowtype;
    vn_parent_request_id     NUMBER;
        CURSOR c_liste_destinataire (
            p_region IN VARCHAR2
        ) IS
       WITH CTE AS (SELECT
            ffv.attribute1 adresse
        FROM
            fnd_flex_value_sets   ffvs,
            fnd_flex_values       ffv
        WHERE
            ffvs.flex_value_set_name = 'DKA_MAIL_REMB_AVOIRS'
            AND ffv.flex_value_set_id = ffvs.flex_value_set_id
            AND ffv.flex_value = nvl(p_region, ffv.flex_value)
            AND ffv.enabled_flag = 'Y'
            AND sysdate BETWEEN nvl(ffv.start_date_active, sysdate) AND nvl(ffv.end_date_active, sysdate)

      )
SELECT TRIM(REGEXP_SUBSTR( adresse, '[^;]+', 1, LEVEL)) adresse FROM CTE
CONNECT BY LEVEL < LENGTH(REGEXP_REPLACE(adresse, '[^;]+')) + 1;



        CURSOR c_liste_destinataire_cc (
            p_region IN VARCHAR2
        ) IS
       WITH CTE AS (SELECT
            ffv.attribute2 adresse
        FROM
            fnd_flex_value_sets   ffvs,
            fnd_flex_values       ffv
        WHERE
            ffvs.flex_value_set_name = 'DKA_MAIL_REMB_AVOIRS'
            AND ffv.flex_value_set_id = ffvs.flex_value_set_id
            AND ffv.flex_value = nvl(p_region, ffv.flex_value)
            AND ffv.enabled_flag = 'Y'
            AND sysdate BETWEEN nvl(ffv.start_date_active, sysdate) AND nvl(ffv.end_date_active, sysdate)

      )
SELECT TRIM(REGEXP_SUBSTR( adresse, '[^;]+', 1, LEVEL)) adresse FROM CTE
CONNECT BY LEVEL < LENGTH(REGEXP_REPLACE(adresse, '[^;]+')) + 1;

        CURSOR REC_REGION IS
        SELECT distinct substr(name,1,3) user_name
            FROM   hr_operating_units
            where substr(name,1,3) <> 'REF';


    BEGIN
        gn_request_id := fnd_global.conc_request_id;
        pv_errbuf := NULL;
        pn_retcode := 0;
    
      --------------------------------------------------------------

     dka_tools_pkg.get_parameter('SPOCDE_CITY', 'SMTP_CONNECTION', rec_param, pv_errbuf, pn_retcode);
      gv_conn := rec_param.varchar2_value;
      IF gv_conn IS NULL THEN
            fnd_file.put_line(fnd_file.log, chr(10) || 'ECHEC : erreur concernant la connexion SMTP.');
            RAISE erreur_mail;
      END IF;

      IF p_region IS NULL THEN
        FOR cur_region IN REC_REGION LOOP
                pn_retcode := 0;

              -- Extraction des donnees
                extraction_avoir_reglee(pv_errbuf, pn_retcode, cur_region.user_name, vv_filename);
                dka_tools_pkg.put_log_message('Région : ' || cur_region.user_name);
                dka_tools_pkg.put_log_message('Pn_Retcode : ' || pn_retcode);
                fnd_file.put_line(fnd_file.output, '---------------------------------------------------------');
                fnd_file.put_line(fnd_file.output, 'COMPTE-RENDU DU TRAITEMENT "DKA : Etat des avoirs à rembourser"'
                );
                fnd_file.put_line(fnd_file.output, 'Region :' || cur_region.user_name);
                fnd_file.put_line(fnd_file.output, 'Traitement n° ' || gn_request_id);
                fnd_file.put_line(fnd_file.output, '                                                                           ')
                ;
                fnd_file.put_line(fnd_file.output, 'Nombre d avoirs selectionnes par le traitement : ' || l_line_count);
                fnd_file.put_line(fnd_file.output, '                                                                           ')
                ;

                BEGIN
                        dka_tools_pkg.put_log_message('le mail a ete envoye');

                        log_msg('Nom Fichier : ' || vv_filename);

                        g_step := 'ENVOI_AVEC_FICHIER 000 : DEBUT';
                        log_msg(g_step);
                        g_step := 'ENVOI_AVEC_FICHIER 001 : RECHERCHE DE L''OBJET DU MAIL.';
                        log_msg(g_step);
                        gv_objet := cur_region.user_name 
                                    || ' - Liste des remboursements d''avoirs validés - '
                                    || to_char(g_date, 'DD'
                                                       || '/'
                                                       || 'MM'
                                                       || '/'
                                                       || 'YYYY');

                        IF gv_objet IS NULL THEN
                            fnd_file.put_line(fnd_file.log, chr(10) || 'ECHEC : Pas d''objet du mail.');
                            RAISE erreur_mail;
                        END IF;

                        g_step := 'ENVOI_AVEC_FICHIER 002 : RECHERCHE DU CORPS DU MAIL.';
                        log_msg(g_step);
                        gv_corps := 'Bonjour,'
                                    || chr(13)
                                    || chr(10)
                                    || chr(10)
                                    || 'Vous trouverez en PJ la liste des remboursements d''avoirs validés pour paiement.'
                                    || chr(13)
                                    || chr(10)
                                    || chr(10)
                  || 'Si le statut « Réglée » est à NON, la demande de règlement a été créé dans le module AP (Fournisseur), mais non réglée.'
                                    || chr(13)
                                    || chr(10)
                                    || chr(10)
                  || 'Si le statut « Réglée » est à OUI, alors le virement a été exécuté.'
                                    || chr(13)
                                    || chr(10)
                                    || chr(10)
                                    || 'Cordialement,'
                                    || chr(13)
                                    || chr(10);

                        IF gv_corps IS NULL THEN
                            fnd_file.put_line(fnd_file.log, chr(10)
                                                            || 'ECHEC : Pas de corps du mail.');
                            RAISE erreur_mail;
                        END IF;

                        vn_cpt := 0;
            vt_adr_to.delete;
                        vt_adr_to(1) := 'INIT';
                        vv_adresses := NULL;
                        vv_adresses_cc := NULL;
                        fnd_file.put_line(fnd_file.log, to_char(sysdate, 'DD/MM/YYYY')
                                                        || ' - '
                                                        || 'Récupération des destinataires directs');
    -- Alimentation du tableau des destinataires directs

                        FOR cur_adr_to IN c_liste_destinataire(cur_region.user_name) LOOP
                            vn_cpt := vn_cpt + 1;
                            vt_adr_to(vn_cpt) := cur_adr_to.adresse;

                            vv_adresses := vv_adresses
                                           || cur_adr_to.adresse
                                           || ';';
            dka_tools_pkg.put_log_message('vv_adresses : '||vv_adresses);

                        END LOOP;

                        IF vv_adresses IS NULL THEN
                            fnd_file.put_line(fnd_file.log, chr(10)
                                                            || 'Aucune valeur n''est active dans le jeu de valeurs DKA_MAIL_REMB_AVOIRS'
                                                            );
                            RAISE erreur_mail;
                        ELSE
                            vn_cptt := 0;
              vt_adr_cc.delete;
                            vt_adr_cc(1) := 'INIT';
                            FOR cur_adr_too IN c_liste_destinataire_cc(cur_region.user_name) LOOP
                                vn_cptt := vn_cptt + 1;
                                vt_adr_cc(vn_cptt) := cur_adr_too.adresse;
                                vv_adresses_cc := vv_adresses_cc
                                                  || cur_adr_too.adresse
                                                  || ',';
                            END LOOP;


              SEND_MSG(p_tab_to => vt_adr_to,
              p_tab_cc      => vt_adr_cc,
              p_from        => 'no-reply@dalkia.fr',
              p_subject     => gv_objet,
              P_region      => cur_region.user_name,
              p_text_msg    => gv_corps,
              p_attach_name => vv_filename,
              p_attach_mime => K_DIRECTORY,
              p_smtp_host   => gv_conn);


                            log_msg('adresses : '
                                    || vv_adresses
                                    || vv_adresses_cc);

                        END IF;

                    EXCEPTION
                        WHEN erreur_mail THEN
                            pn_retcode := 1;
                            fnd_file.put_line(fnd_file.output, 'ECHEC : Le mail n''a pas pu être envoyé.');
                            fnd_file.put_line(fnd_file.output, chr(10)
                                                               || 'Voir le journal du traitement pour avoir plus de détail sur l''anomalie rencontrée.'
                                                               );

                        WHEN erreur_programme THEN
                            pn_retcode := 2;
                            pv_errbuf := v_errbuf;
                            fnd_file.put_line(fnd_file.log, pv_errbuf);
                            fnd_file.put_line(fnd_file.log, chr(10)
                                                            || pv_errbuf);
                END;
                
  -----------------------------------------------

                dka_tools_pkg.put_log_message('Nombre du fichier LIGNES genere : ' || l_line_count);
                IF pn_retcode = 0 THEN
                    dka_tools_pkg.put_log_message('execution traitement OK');
                    p_retcode := 0;
                ELSIF pn_retcode = 1 THEN
                    ROLLBACK;
                    p_errbuf := 'aucune donnees trouvrees';
                    p_retcode := 1;
                END IF;

                dka_tools_pkg.put_log_message(p_errbuf);
                dka_tools_pkg.put_log_message(p_retcode);
                pn_retcode := 0;
            END LOOP;
        ELSE
              -- Extraction des donnees
            extraction_avoir_reglee(pv_errbuf, pn_retcode, p_region, vv_filename);
            dka_tools_pkg.put_log_message('Région : ' || p_region);
            fnd_file.put_line(fnd_file.output, '---------------------------------------------------------');
            fnd_file.put_line(fnd_file.output, 'COMPTE-RENDU DU TRAITEMENT "DKA : Etat des avoirs à rembourser"')
            ;
            fnd_file.put_line(fnd_file.output, 'Region :' || p_region);
            fnd_file.put_line(fnd_file.output, 'Traitement n° ' || gn_request_id);
            fnd_file.put_line(fnd_file.output, '                                                                           ');
            fnd_file.put_line(fnd_file.output, 'Nombre d avoirs selectionnes par le traitement : ' || l_line_count);
            fnd_file.put_line(fnd_file.output, '                                                                           ');
      
      
            BEGIN
                    dka_tools_pkg.put_log_message('le mail a ete envoye');

                    log_msg('Nom Fichier : ' || vv_filename);

                    dka_tools_pkg.get_parameter('SPOCDE_CITY', 'SMTP_CONNECTION', rec_param, pv_errbuf, pn_retcode);
                    gv_conn := rec_param.varchar2_value;
                    IF gv_conn IS NULL THEN
                        fnd_file.put_line(fnd_file.log, chr(10)
                                                        || 'ECHEC : erreur concernant la connexion SMTP.');
                        RAISE erreur_mail;
                    END IF;

                    g_step := 'ENVOI_AVEC_FICHIER 000 : DEBUT';
                    log_msg(g_step);
                    g_step := 'ENVOI_AVEC_FICHIER 001 : RECHERCHE DE L''OBJET DU MAIL.';
                    log_msg(g_step);
                    gv_objet := p_region
                                || ' - Liste des remboursements d''avoirs validés - '
                                || to_char(g_date, 'DD'
                                                   || '/'
                                                   || 'MM'
                                                   || '/'
                                                   || 'YYYY');

                    IF gv_objet IS NULL THEN
                        fnd_file.put_line(fnd_file.log, chr(10)
                                                        || 'ECHEC : Pas d''objet du mail.');
                        RAISE erreur_mail;
                    END IF;

                    g_step := 'ENVOI_AVEC_FICHIER 002 : RECHERCHE DU CORPS DU MAIL.';
                    log_msg(g_step);
                    gv_corps := 'Bonjour,'
                                    || chr(13)
                                    || chr(10)
                                    || chr(10)
                                    || 'Vous trouverez en PJ la liste des remboursements d''avoirs validés pour paiement.'
                                    || chr(13)
                                    || chr(10)
                                    || chr(10)
                  || 'Si le statut « Réglée » est à NON, la demande de règlement a été créé dans le module AP (Fournisseur), mais non réglée.'
                                    || chr(13)
                                    || chr(10)
                                    || chr(10)
                  || 'Si le statut « Réglée » est à OUI, alors le virement a été exécuté.'
                                    || chr(13)
                                    || chr(10)
                                    || chr(10)
                                    || 'Cordialement,'
                                    || chr(13)
                                    || chr(10);

                    IF gv_corps IS NULL THEN
                        fnd_file.put_line(fnd_file.log, chr(10)
                                                        || 'ECHEC : Pas de corps du mail.');
                        RAISE erreur_mail;
                    END IF;

                    vn_cpt := 0;
          vt_adr_to.delete;
                    vt_adr_to(1) := 'INIT';
                    vv_adresses := NULL;
                    vv_adresses_cc := NULL;
                    fnd_file.put_line(fnd_file.log, to_char(sysdate, 'DD/MM/YYYY')
                                                    || ' - '
                                                    || 'Récupération des destinataires directs');
    -- Alimentation du tableau des destinataires directs

                    FOR cur_adr_to IN c_liste_destinataire(p_region) LOOP
                        vn_cpt := vn_cpt + 1;
                        vt_adr_to(vn_cpt) := cur_adr_to.adresse;
                        vv_adresses := vv_adresses
                                       || cur_adr_to.adresse
                                       || ';';

                    END LOOP;

                    IF vv_adresses IS NULL THEN
                        fnd_file.put_line(fnd_file.log, chr(10)
                                                        || 'Aucune valeur n''est active dans le jeu de valeurs DKA_MAIL_REMB_AVOIRS')
                                                        ;
                        RAISE erreur_mail;
                    ELSE
                        vn_cptt := 0;
            vt_adr_cc.delete;
                       vt_adr_cc(1) := 'INIT';
                        FOR cur_adr_too IN c_liste_destinataire_cc(p_region) LOOP
                            vn_cptt := vn_cptt + 1;
                            vt_adr_cc(vn_cptt) := cur_adr_too.adresse;
                            vv_adresses_cc := vv_adresses_cc
                                              || cur_adr_too.adresse
                                              || ',';
                        END LOOP;


             SEND_MSG(p_tab_to      => vt_adr_to,
             p_tab_cc      => vt_adr_cc,
             p_from        => 'no-reply@dalkia.fr',
             p_subject     => gv_objet,
             P_region      => P_region,
             p_text_msg    => gv_corps,
             p_attach_name => vv_filename,
             p_attach_mime => K_DIRECTORY,
             p_smtp_host   => gv_conn);


                        log_msg('adresses : '
                                || vv_adresses
                                || vv_adresses_cc);

                    END IF;

                EXCEPTION
                    WHEN erreur_mail THEN
                        pn_retcode := 1;
                        fnd_file.put_line(fnd_file.output, 'ECHEC : Le mail n''a pas pu être envoyé.');
                        fnd_file.put_line(fnd_file.output, chr(10)
                                                           || 'Voir le journal du traitement pour avoir plus de détail sur l''anomalie rencontrée.'
                                                           );

                    WHEN erreur_programme THEN
                        pn_retcode := 2;
                        pv_errbuf := v_errbuf;
                        fnd_file.put_line(fnd_file.log, pv_errbuf);
                        fnd_file.put_line(fnd_file.log, chr(10)
                                                        || pv_errbuf);
                END;
  

            dka_tools_pkg.put_log_message('Nombre du fichier LIGNES genere : ' || l_line_count);
            IF pn_retcode = 0 THEN
                dka_tools_pkg.put_log_message('execution traitement OK');
                p_retcode := 0;
            ELSIF pn_retcode = 1 THEN
                ROLLBACK;
                p_errbuf := 'aucune donnees trouvrees';
                p_retcode := 1;
            END IF;

            dka_tools_pkg.put_log_message(p_errbuf);
            dka_tools_pkg.put_log_message(p_retcode);
        END IF;

    END main;
  
END DKA_SARETAT_AVOIR_REG_PKG;

/
SHOW ERRORS
EXIT
