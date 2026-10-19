create or replace PACKAGE BODY DKA_SARPREL_ATTACH_PKG AS
  ------------------------------------------------------------------------------------------
  -- $$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SARPREL_ATTACH_PKG.pkb
  -- DESCRIPTION       : DKA_SARPREL_ATTACH_PKG package body :
  --
  -- AUTEUR           : Benjamin Coudrier (CAPGEMINI)
  -- DATE DE CREATION : 17/12/2013
  -- DOC. ASSOCIEE    :
  -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
  ------------------------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Qui Description
  -- 23/02/2021 ARA EDB282 - Enrichissement de l'avis de prélèvement (Migration vers XML publisher) et envoi par mail
  -- 06/01/2022 ARA INC0617936 : Automatisation des prélèvements clients - Date prélèvements
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  gn_user_id       fnd_user.user_id%TYPE;
  gn_login_id      fnd_logins.login_id%TYPE;
  gn_org_id        hr_all_organization_units.organization_id%TYPE;
  gv_description   VARCHAR2(250);
  gn_category_id   NUMBER;
  gv_datatype_name VARCHAR2(30) := 'FILE';
  gn_datatype_id   NUMBER;
  gv_entity_name   VARCHAR2(30) := 'AR_CASH_RECEIPTS';

  g_step VARCHAR2(500);
  TYPE liste_destinataires IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
  e_dest_error EXCEPTION;
  e_etat_error EXCEPTION;

  vn_adresses      VARCHAR2(30000);
  v_region VARCHAR2(20);

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

  ----------------------------------------------------------------------------
  --  Nom           : init
  --  Description   : Procédure d'initialisation
  --
  --  PARAMETRES :
  --    pv_errbuf   Entrée/Sortie          message d'erreur
  --    VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE init(pv_errbuf  IN OUT VARCHAR2,
                 pn_retcode    OUT NUMBER)
  IS
    rec_param   dka_parameters%ROWTYPE;
    vv_category fnd_document_categories.name%TYPE;

  BEGIN
    g_step := 'INIT 000 - DEBUT';
    log_msg(g_step);
    pv_errbuf  := NULL;
    pn_retcode := 0;

    -- En-tête du fichier de sortie
    dka_tools_pkg.put_out_header;

    -- Variables globale "WHO"
    gn_user_id  := fnd_global.user_id;
    gn_login_id := fnd_global.login_id;
    --gn_org_id   := fnd_profile.value('ORG_ID');

    -- Variables liées à la création du document joint
    Dka_Tools_Pkg.get_parameter('DKA_SARPREL_ATTACH',
                                'DESCRIPTION',
                                rec_param,
                                pv_errbuf,
                                pn_retcode);
    gv_description := rec_param.varchar2_value;

    IF pn_retcode != 0 THEN
      pv_errbuf := 'Paramètre DESCRIPTION : ' || pv_errbuf;
      RETURN;
    ELSIF gv_description IS NULL THEN
      pv_errbuf  := 'Paramètre DESCRIPTION : Aucune donnée trouvée';
      pn_retcode := 2;
      RETURN;
    END IF;

    g_step := 'INIT 001 - DESCRIPTION : ' || gv_description;
    log_msg(g_step);

    Dka_Tools_Pkg.get_parameter('DKA_SARPREL_ATTACH',
                                'CATEGORY',
                                rec_param,
                                pv_errbuf,
                                pn_retcode);
    vv_category := rec_param.varchar2_value;

    IF pn_retcode != 0 THEN
      pv_errbuf := 'Paramètre CATEGORY : ' || pv_errbuf;
      RETURN;
    ELSIF vv_category IS NULL THEN
      pv_errbuf  := 'Paramètre CATEGORY : Aucune donnée trouvée';
      pn_retcode := 2;
      RETURN;
    END IF;

    -- Récupération de l'id correspondant à la categorie de document
    SELECT category_id
    INTO gn_category_id
    FROM fnd_document_categories
    WHERE name = vv_category;

    g_step := 'INIT 001 - IDENTIFIANT DE LA CATEGORY : ' || gn_category_id;
    log_msg(g_step);

    -- Récupération de l'id correspondant au type de document
    SELECT distinct datatype_id
    INTO gn_datatype_id
    FROM fnd_document_datatypes
    WHERE name = gv_datatype_name;

    g_step := 'INIT 002 - IDENTIFIANT DU TYPE DE DONNEES : ' || gn_datatype_id;
    log_msg(g_step);
    g_step := 'INIT 999 - FIN';
    log_msg(g_step);
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'INIT 999 : ' || SQLERRM;
  END init;

  ----------------------------------------------------------------------------
  --  Nom           : get_doc_avr
  --  Description   : Procédure permettant de récupérer les info d'un document
  --                  attaché de type Avis de prélèvement s'il existe
  --
  --  PARAMETRES :
  --    pv_errbuf   Entrée/Sortie          message d'erreur
  --    VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------

  PROCEDURE get_doc_avr(pv_cash_receipt_id IN NUMBER,
                        pv_media_id        OUT NUMBER,
                        pv_document_id     OUT NUMBER,
                        pv_errbuf          IN OUT VARCHAR2,
                        pn_retcode         OUT NUMBER)
  IS

    -- Curseur de lecture des documents attachés à l'avis de virement
    CURSOR cur_documents_joints IS
    SELECT fad.document_id
    FROM fnd_attached_documents fad
    WHERE fad.entity_name = gv_entity_name
      AND fad.pk1_value = pv_cash_receipt_id
    ORDER BY fad.seq_num;

    rec_documents_joints cur_documents_joints%ROWTYPE;
    vb_avr_found         BOOLEAN := FALSE;

  BEGIN
    g_step := 'GET_DOC_AVR 000 - DEBUT';
    log_msg(g_step);

    vb_avr_found   := FALSE;
    pv_document_id := NULL;
    pv_media_id    := NULL;

    -- Boucle de lecture des documents attachés au règlement
    -- On sort de la boucle si on trouve un document de type "AVIS PRELEVEMENT"
    OPEN cur_documents_joints;
    LOOP
      FETCH cur_documents_joints INTO rec_documents_joints;
      EXIT WHEN cur_documents_joints%NOTFOUND OR vb_avr_found;

      -- Pour le document joint trouvé, on regarde si il est de type "AVIS PRELEVEMENT"
      BEGIN
        SELECT fdt.document_id, fdt.media_id
        INTO pv_document_id, pv_media_id
        FROM fnd_documents_tl fdt
        JOIN fnd_documents    fd on(fd.document_id = fdt.document_id)
        WHERE fdt.document_id = rec_documents_joints.document_id
          AND fd.category_id = gn_category_id
          AND fd.datatype_id = gn_datatype_id
          AND fdt.description = gv_description
          AND fdt.language = userenv('LANG');

        -- Le document joint est de type "AVIS PRELEVEMENT"
        -- On positionne l'indicateur vb_avr_found pour sortir de la boucle
        vb_avr_found := TRUE;
        g_step := 'GET_DOC_AVR 001 - Un document de type "AVIS PRELEVEMENT" est déjà rattaché à ce règlement (document_id : ' ||pv_document_id || ', media_id : ' || pv_media_id || ').';
        log_msg(g_step);

      EXCEPTION
        WHEN OTHERS THEN
          -- Le document joint n'est pas de type "AVIS PRELEVEMENT" donc on passe au document joint suivant
          NULL;
      END;

    END LOOP;
    CLOSE cur_documents_joints;

    -- Il n'existe aucun document de type "AVIS PRELEVEMENT"
    IF NOT vb_avr_found THEN
      g_step := 'GET_DOC_AVR 001 - ERROR - Aucun document de type "AVIS PRELEVEMENT" n''est rattaché à ce règlement.';
      log_msg(g_step);
    END IF;

    g_step := 'GET_DOC_AVR 999 - FIN';
    log_msg(g_step);

  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'GET_DOC_AVR : ' || SQLERRM;
  END get_doc_avr;

  ---------------------------------------------------------------------------
  --  Nom           : chargement_image
  --  Description   : procédure qui charge une image d'avis de prélèvement en table
  --
  --  PARAMETRES :
  --    pv_errbuf   Entrée/Sortie          message d'erreur
  --    VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE chargement_image(pv_nom_fichier IN VARCHAR2,
                             pb_existe      OUT BOOLEAN,
                             pn_file_id     OUT NUMBER,
                             pv_errbuf      OUT VARCHAR2,
                             pn_retcode     IN OUT NUMBER) IS
    l_length     NUMBER;
    l_blocksize  NUMBER;
    l_src_fich   BFILE;
    l_dst_fich   BLOB;
    l_src_offset NUMBER := 1;
    l_dst_offset NUMBER := 1;

  BEGIN
    g_step := 'CHARGEMENT_IMAGE 000 - DEBUT';
    log_msg(g_step);
    pn_retcode := 0;
    dbms_lob.createtemporary(l_dst_fich, true, dbms_lob.session);

    l_src_fich := bfilename('DKA_LOADAVR', pv_nom_fichier);
    pb_existe  := DBMS_LOB.FILEEXISTS(l_src_fich) = 1;

    IF pb_existe THEN
      dbms_lob.fileopen(l_src_fich, dbms_lob.file_readonly);
      dbms_lob.loadfromfile(l_dst_fich,
                            l_src_fich,
                            dbms_lob.lobmaxsize,
                            l_src_offset,
                            l_dst_offset);

      SELECT fnd_lobs_s.NEXTVAL INTO pn_file_id FROM dual;

      insert into fnd_lobs
        (file_id,
         file_name,
         file_content_type,
         file_data,
         file_format,
         upload_date,
         program_name)
      values
        (pn_file_id,
         'AVIS_PRELEVEMENT.pdf', --pv_nom_fichier,
         'application/pdf',
         l_dst_fich,
         'binary',
         sysdate,
         'FNDATTCH');

      DBMS_LOB.FILECLOSE(l_src_fich);
    ELSE
      pv_errbuf := 'CHARGEMENT_IMAGE - ERREUR : Pas de fichier à charger';
      log_msg(pv_errbuf);
      pn_retcode := 2;
    END IF;

    g_step := 'CHARGEMENT_IMAGE 999 - FIN';
    log_msg(g_step);
  EXCEPTION
    WHEN OTHERS THEN
      g_step := 'CHARGEMENT_IMAGE 999 - ' || substr(SQLERRM, 1, 400);
      log_msg(g_step);
      g_step := 'CHARGEMENT_IMAGE 999 - ' || SQLERRM;
      log_msg(g_step);
      pv_errbuf  := 'chargement_image - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END chargement_image;

  ---------------------------------------------------------------------------
  --  Nom           : delete_image
  --  Description   : procédure qui charge une image de bon de commande en table
  --
  --  PARAMETRES :
  --    pv_errbuf   Entrée/Sortie          message d'erreur
  --    VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE delete_image(pn_file_id IN NUMBER,
                         pv_errbuf  OUT VARCHAR2,
                         pn_retcode IN OUT NUMBER) IS

  BEGIN
    g_step := 'DELETE_IMAGE 000 : DEBUT.';
    log_msg(g_step);
    pn_retcode := 0;

    DELETE fnd_lobs WHERE file_id = pn_file_id;
    g_step := 'DELETE_IMAGE 001 : SUPPRESSION DE L''ANCIEN AVIS DE PRELEVEMENT : ' ||pn_file_id;
    log_msg(g_step);
    g_step := 'DELETE_IMAGE 099 : FIN.';
    log_msg(g_step);
  EXCEPTION
    WHEN OTHERS THEN
      g_step := 'DELETE_IMAGE 099 : ' || substr(SQLERRM, 1, 400);
      log_msg(g_step);
      g_step := 'DELETE_IMAGE 099 : ' || SQLERRM;
      log_msg(g_step);
      pv_errbuf  := 'delete_image - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END delete_image;

  ----------------------------------------------------------------------------
  --  Nom           : create_attached_document_avr
  --  Description   : procédure qui crée le document attaché
  --
  --
  --  PARAMETRES :
  --    pv_errbuf   Entrée/Sortie          message d'erreur
  --    VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE create_attached_document_avr(pv_filename        IN VARCHAR2,
                                         pv_cash_receipt_id IN NUMBER,
                                         pn_file_id         IN NUMBER,
                                         pv_org_id          IN NUMBER,
                                         pv_errbuf          OUT VARCHAR2,
                                         pn_retcode         IN OUT NUMBER) IS

    l_document_id          NUMBER;
    l_attached_document_id NUMBER;
    l_num_seq              NUMBER;
  BEGIN
    g_step := 'CREATE_ATTACHED_DOCUMENT_AVR 000 : DEBUT.';
    log_msg(g_step);
    pn_retcode := 0;

    -- Recupération du dernier numéro de séquence
    BEGIN
      SELECT NVL(MAX(seq_num), 0) + 10
        INTO l_num_seq
        FROM fnd_attached_documents
       WHERE entity_name = gv_entity_name
         AND pk1_value = pv_cash_receipt_id;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_num_seq := 10;
    END;

    SELECT fnd_documents_s.nextval INTO l_document_id FROM DUAL;

    INSERT INTO fnd_documents_tl
      (document_id,
       file_name,
       media_id,
       description,
       creation_date,
       created_by,
       last_update_date,
       last_updated_by,
       language,
       source_lang)
    VALUES
      (l_document_id,
       'AVIS_PRELEVEMENT.pdf', --pv_filename,
       pn_file_id,
       gv_description,
       sysdate,
       -1,
       sysdate,
       -1,
       userenv('LANG'),
       userenv('LANG'));

    INSERT INTO fnd_documents
      (document_id,
       category_id,
       datatype_id,
       creation_date,
       created_by,
       last_update_date,
       last_updated_by,
       security_type,
       security_id,
       publish_flag,
       usage_type,
       media_id,
       file_name)
    VALUES
      (l_document_id,
       gn_category_id,
       gn_datatype_id,
       sysdate,
       -1,
       sysdate,
       -1,
       1,
       pv_org_id,
       'Y',
       'O',
       pn_file_id,
       'AVIS_PRELEVEMENT.pdf');

    SELECT fnd_attached_documents_s.nextval
      INTO l_attached_document_id
      FROM DUAL;

    INSERT INTO fnd_attached_documents
      (attached_document_id,
       document_id,
       seq_num,
       entity_name,
       pk1_value,
       creation_date,
       created_by,
       last_update_date,
       last_updated_by,
       AUTOMATICALLY_ADDED_FLAG,
       category_id)
    VALUES
      (l_attached_document_id,
       l_document_id,
       l_num_seq,
       gv_entity_name,
       pv_cash_receipt_id,
       sysdate,
       -1,
       sysdate,
       -1,
       'N',
       gn_category_id);

    dka_Tools_Pkg.put_outdebug_message('==>  Création du document_id : ' ||
                                       l_document_id);
    g_step := 'CREATE_ATTACHED_DOCUMENT_AVR 001 : CREATION DU DOCUMENT_ID : ' ||
              l_document_id;
    log_msg(g_step);
    g_step := 'CREATE_ATTACHED_DOCUMENT_AVR 099 : FIN.';
    log_msg(g_step);
  EXCEPTION
    WHEN OTHERS THEN
      g_step := 'CREATE_ATTACHED_DOCUMENT_AVR 099 - ERREUR : ' || SQLCODE || '=' ||
                substr(SQLERRM, 1, 400);
      log_msg(g_step);
      g_step := 'CREATE_ATTACHED_DOCUMENT_AVR 099 - ERREUR : ' || SQLERRM;
      log_msg(g_step);
      pv_errbuf  := 'create_attached_document_avr - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END create_attached_document_avr;

  ----------------------------------------------------------------------------
  --  Nom           : update_attached_document_avr
  --  Description   : procédure qui crée le document attaché
  --
  --
  --  PARAMETRES :
  --    pv_errbuf   Entrée/Sortie          message d'erreur
  --    VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE update_attached_document_avr(pv_filename    IN VARCHAR2,
                                         pn_file_id     IN NUMBER,
                                         pn_document_id IN NUMBER,
                                         pv_errbuf      OUT VARCHAR2,
                                         pn_retcode     IN OUT NUMBER) IS

  BEGIN
    g_step := 'UPDATE_ATTACHED_DOCUMENT_AVR 000 : DEBUT.';
    log_msg(g_step);

    pn_retcode := 0;

    UPDATE fnd_documents_tl
    SET file_name = 'AVIS_PRELEVEMENT.pdf',
        media_id = pn_file_id,
        last_update_date = sysdate,
        last_updated_by  = -1
    WHERE document_id = pn_document_id;

    update fnd_documents
    set file_name = 'AVIS_PRELEVEMENT.pdf',
        media_id = pn_file_id,
        last_update_date = sysdate,
        last_updated_by  = -1
    where document_id = pn_document_id;

    g_step := 'UPDATE_ATTACHED_DOCUMENT_AVR 001 : MISE A JOUR DU DOCUMENT_ID : ' || pn_document_id;
    log_msg(g_step);

    g_step := 'UPDATE_ATTACHED_DOCUMENT_AVR 999 : FIN';
    log_msg(g_step);
  EXCEPTION
    WHEN OTHERS THEN
      g_step := 'UPDATE_ATTACHED_DOCUMENT_AVR 999 - ERREUR : ' || SQLCODE || '=' || substr(SQLERRM, 1, 400);
      log_msg(g_step);
      g_step := 'UPDATE_ATTACHED_DOCUMENT_AVR 999 - ERREUR : ' || SQLERRM;
      log_msg(g_step);
      pv_errbuf  := 'UPDATE_ATTACHED_DOCUMENT_AVR - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END update_attached_document_avr;

-- ARA
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
                     p_from        IN VARCHAR2,
                     p_subject     IN VARCHAR2,
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


    fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '     > Mail : Alimentation du mail');

    UTL_SMTP.open_data(l_mail_conn);

    UTL_SMTP.write_data(l_mail_conn,
                        'Date: ' ||
                        TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') ||
                        UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to || UTL_TCP.crlf);


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
      --UTL_SMTP.write_data(l_mail_conn, p_text_msg);
      UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
    END IF;

    fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '     > Mail : Alimentation de la pièce jointe');

    IF p_attach_name IS NOT NULL THEN
    --IF p_attach_name = 1 THEN -- test
      UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Type: ' || p_attach_mime || '; name="' ||
                          'Etat_des_prélèvements_remis_en_banque_' || '_' ||
                          TO_CHAR(to_date(sysdate,'yyyy/mm/dd hh24:mi:SS'), 'DD-MM-YYYY')|| '.pdf' || '"' ||
                          UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Transfer-Encoding: base64' ||
                          UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Disposition: attachment; filename="' ||
                          'AVIS_PRELEVEMENT' || '.pdf' || '"' ||
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

  --ARA
    ----------------------------------------------------------------------------
  --  Nom           : envoi_mail_avec_client
  --  Description   : Procédure 
  --
  --
  --  PARAMETRES :
  --    p_num           Entrée          Numéro du traitement "VE : Création du fichier avis de prélèvement"
  --    pv_errbuf       Entrée/Sortie   message d'erreur
  --    VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE envoi_mail_avec_client(pv_errbuf  IN OUT VARCHAR2,
								   pn_retcode    OUT NUMBER,
								   p_attach_name    IN VARCHAR2,
								   p_destinataire  liste_destinataires,
                                   p_req_id IN NUMBER
								   )
	IS

	v_mail VARCHAR2(255);
	v_delivery VARCHAR2(30);
	v_societe VARCHAR2(60);
	v_montant VARCHAR2(30);
	v_devise VARCHAR2(10);
	v_date VARCHAR2(10);
	vv_conn VARCHAR2(50);
    rec_param     dka_parameters%ROWTYPE;


	BEGIN
	   
	SELECT DISTINCT gl.name NOM_SOCIETE,
					case 
					when arca.amount < 0 then TO_CHAR (arca.amount,'fm999G999G999G990D00','NLS_NUMERIC_CHARACTERS='', ''')
					when arca.amount BETWEEN 0 AND 1 then '0' || TO_CHAR(arca.amount,'fm999G999G999D00','NLS_NUMERIC_CHARACTERS = '', ''')
					else
					TO_CHAR(arca.amount,'fm999G999G999D00','NLS_NUMERIC_CHARACTERS = '', ''')
                    end montant_total_preleve ,
					DECODE(arca.currency_code,
						   'EUR',
						   'euros',
						   arca.currency_code) devise,
					to_char(dst.TRANSACTIONDATE, 'DD/MM/YYYY') DATE_PRELEVEMNT
	  INTO v_societe, v_montant, v_devise, v_date
	  FROM ar_cash_receipts_all arca,      
		   gl_ledgers gl,     
		   hr_operating_units hou,    
		   dka_sarautoprelev_tmp dst
	 WHERE 1 = 1
		  -- Reglement
	   AND arca.org_id = hou.organization_id
	   AND hou.set_of_books_id = gl.ledger_id
	   and dst.cashreceiptid = arca.cash_receipt_id
	   AND arca.cash_receipt_id = p_req_id; -- variable; 

	Dka_Tools_Pkg.get_parameter('SARRGLTPRLV',
                                'SMTP_CONNECTION',
                                rec_param,
                                Pv_Errbuf,
                                Pn_Retcode);
    vv_conn := rec_param.varchar2_value;
    
  --  fnd_file.put_line(fnd_file.OUTPUT, ' -> ' || p_destinataire);
  --fnd_file.put_line(fnd_file.OUTPUT, ' -> ' || p_destinataire);
	

	SEND_MSG(p_tab_to      => p_destinataire,
             p_from        => 'no-reply@dalkia.fr',
             p_subject     => 'Avis de prélèvement', 
             p_text_msg    => 'Bonjour,' || CHR(13) || '' || CHR(13) ||
                                'Nous vous informons que nous avons instruit en notre faveur, un ordre de prélèvement initié par ' ||
                                v_societe || ' pour un montant de : ' || v_montant || ' ' || v_devise || '.' ||
                                CHR(13) ||  CHR(13)|| CHR(13)|| 'Le prélèvement sera réalisé en date du : ' || v_date || '.' || CHR(13)|| CHR(13) || CHR(13) || 'Cordialement',
               p_attach_name => p_attach_name,
               --p_attach_name => 'DKA_RARPREL_PDF_16093613_1.PDF',
               p_attach_mime => 'DKA_LOADAVR',
               p_smtp_host   => vv_conn);

	EXCEPTION
    WHEN OTHERS THEN
      g_step := 'envoi_mail_avec_client 999 - ERREUR : ' || SQLCODE || '=' || substr(SQLERRM, 1, 400);
      log_msg(g_step);
      g_step := 'envoi_mail_avec_client 999 - ERREUR : ' || SQLERRM;
      log_msg(g_step);
      pv_errbuf  := 'envoi_mail_avec_client - ' || SQLERRM;
      pn_retcode := 2;
	END envoi_mail_avec_client;

  --ARA
      ----------------------------------------------------------------------------
  --  Nom           : envoi_mail_sans_client
  --  Description   : Procédure 
  --
  --
  --  PARAMETRES :
  --    p_num           Entrée          Numéro du traitement "VE : Création du fichier avis de prélèvement"
  --    pv_errbuf       Entrée/Sortie   message d'erreur
  --    VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE envoi_mail_sans_client(pv_errbuf  IN OUT VARCHAR2,
								   pn_retcode    OUT NUMBER,
								   p_attach_name    IN VARCHAR2,
                                   p_req_id IN NUMBER
								   )
	IS

	v_num_client VARCHAR2(20);
	v_nom_client VARCHAR2(100); --
	v_adresse VARCHAR2(100);
	v_uo VARCHAR2(20);
    

	vt_adr_to     liste_destinataires;
    vt_adr_cc     liste_destinataires;
	vn_cpt        NUMBER;
	vv_conn VARCHAR2(50);
    rec_param     dka_parameters%ROWTYPE;



	-- Récupération des destinataires directs
    CURSOR EXTR_ADR_TO (p_region VARCHAR2) IS
      SELECT ffvv.description adresse, ffvv.flex_value
                 FROM fnd_flex_value_sets ffvs, fnd_flex_values_vl ffvv
                WHERE ffvs.flex_value_set_name = 'DKA_ENVOI_MAIL_REGION' --DKA_SCTRLMOD_MOA_MAIL
                  AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                  AND ffvv.enabled_flag = 'Y'
                  AND SYSDATE BETWEEN NVL(ffvv.start_date_active, SYSDATE) AND
                      NVL(ffvv.end_date_active, SYSDATE)
                  AND ffvv.flex_value = p_region;

	BEGIN
	-- Infos  -----------
	select hca.account_number num_client,
       tmp.CUSTOMER_NAME nom_client,
       hcasa.Attribute3 adresse,
       hou.name           uo,
       tmp.region
    INTO v_num_client , v_nom_client , v_adresse , v_uo , v_region
  FROM dka_sarautoprelev_tmp tmp,
       ar_cash_receipts_all  arca,
       hz_cust_accounts      hca,
       hz_cust_acct_sites_all hcasa,
       hz_cust_site_uses_all hcsua,
       hr_operating_units    hou
 WHERE tmp.cashreceiptid = arca.cash_receipt_id
   AND arca.pay_from_customer = hca.cust_account_id
   AND arca.customer_site_use_id = hcsua.Site_use_id
   AND hcsua.cust_acct_site_id =   hcasa.cust_acct_site_id
   AND tmp.org_id = hou.organization_id
   AND tmp.cashreceiptid = p_req_id;
		  ---------

	Dka_Tools_Pkg.get_parameter('SARRGLTPRLV',
                                'SMTP_CONNECTION',
                                rec_param,
                                Pv_Errbuf,
                                Pn_Retcode);
    vv_conn := rec_param.varchar2_value;

	vn_cpt := 0;
    vt_adr_to(1) := 'INIT';


    fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Récupération des destinataires directs');
    -- Alimentation du tableau des destinataires directs
    FOR CUR_ADR_TO IN EXTR_ADR_TO (v_region) LOOP
        IF CUR_ADR_to.adresse IS NOT NULL THEN
      vn_cpt := vn_cpt + 1;
      vt_adr_to(vn_cpt) := CUR_ADR_to.adresse;
     -- vn_adresses := vn_adresses || ';' || CUR_ADR_to.adresse;
      fnd_file.put_line(fnd_file.OUTPUT, ' - ' || 'Mail : ' || vt_adr_to(vn_cpt));
        ELSE
            vt_adr_to(1) := 'anas.raouf@capgemini.com';
            fnd_file.put_line(fnd_file.OUTPUT, 'Pas de mail client' || ' -> ' || vt_adr_to(1));
       END IF;
    END LOOP;

	--vn_adresses := vt_adr_to;

      g_step := 'vn_cpt =' || vn_cpt;
      log_msg(g_step);
      g_step := 'l''adresse mail =' || vt_adr_to(vn_cpt);
      log_msg(g_step);
    -- Si pas de destinataire direct, on renvoie vers l'exception
    IF (vn_cpt = 0) THEN
      g_step := 'Pas de destinatire ou l''adresse correspondante à la région est nulle';
      log_msg(g_step);
      --pn_retcode := 1;
      raise e_dest_error;

    ELSE
	SEND_MSG(p_tab_to      => vt_adr_to,
             p_from        => 'no-reply@dalkia.fr',
             p_subject     => 'Avis de prélèvement client - Adresse manquante ou erronée sur le site',
             p_text_msg    => 'Bonjour,' || CHR(13) || '' || CHR(13) ||
                                'Sur le client N° ' || v_num_client || ' ' || chr(45) || ' Nom : ' || v_nom_client || ' ' || chr(45) ||' UO : ' || v_uo || ' ' || chr(45) || ' Adresse : ' || v_adresse ||
                                ', l''adresse mail est manquante ou erronée. ' || CHR(13) || CHR(13) || 'Par conséquent l''avis de prélèvement n''a pu être envoyé au client. '|| CHR(13) || CHR(13) || 'Cordialement',
             p_attach_name => p_attach_name,
               --p_attach_name => 'DKA_RARPREL_PDF_16093613_1.PDF',
             p_attach_mime => 'DKA_LOADAVR',
             p_smtp_host   => vv_conn);
    END IF;
	EXCEPTION
    WHEN OTHERS THEN
      g_step := 'envoi_mail_sans_client 999 - ERREUR : ' || SQLCODE || '=' || substr(SQLERRM, 1, 400);
      log_msg(g_step);
      g_step := 'envoi_mail_sans_client 999 - ERREUR : ' || SQLERRM;
      log_msg(g_step);
      pv_errbuf  := 'envoi_mail_sans_client - ' || SQLERRM;
      pn_retcode := 2;
	END envoi_mail_sans_client;

  ----------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure principale du stockage des avis de prélèvement
  --
  --
  --  PARAMETRES :
  --    p_num           Entrée          Numéro du traitement "VE : Création du fichier avis de prélèvement"
  --    pv_errbuf       Entrée/Sortie   message d'erreur
  --    VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------

  PROCEDURE main(pv_errbuf  IN OUT VARCHAR2,
                 pn_retcode    OUT NUMBER)
  IS
   l_request_id       NUMBER;
    vv_nom_fichier    VARCHAR2(100);
    v_cash_receipt_id NUMBER;
    v_output_file     VARCHAR2(200);
    v_existe          BOOLEAN;
    b_ismailvalid   BOOLEAN;
    b_error         BOOLEAN := FALSE;
    v_file_id         NUMBER;
    v_po_header_id    po_headers_all.po_header_id%TYPE;
    v_media_id        fnd_documents_tl.media_id%TYPE;
    v_document_id     fnd_documents_tl.document_id%TYPE;
    v_mail VARCHAR2(60);
    v_delivery VARCHAR2(30);
    vt_adr_to     liste_destinataires;
    vn_cpt NUMBER;


    e_main EXCEPTION;

    CURSOR cur_avis_prelevement IS
    SELECT distinct DST.REQUEST_ID,
                    DST.CASH_RECEPT_ID,
                    DST.CREATED_BY,
                    DST.CREATION_DATE,
                    DST.LAST_UPDATED_BY,
                    DST.LAST_UPDATE_DATE,
                    DST.ORG_ID
    FROM DKA_SARPREL_ATTACH_TMP DST
    ORDER BY DST.REQUEST_ID;

    rec_avis_prelevement cur_avis_prelevement%ROWTYPE;

    CURSOR cur_file_name(P_Req_Id NUMBER) IS

      SELECT SUBSTR(OUTFILE_NAME, INSTR(OUTFILE_NAME, '/', -1) + 1, 200) FILE_NAME,
             outfile_name,
             fcp.concurrent_program_name || '_' || fcr.request_id ||
             '_1.PDF' pdf_file
        FROM fnd_concurrent_requests fcr, FND_CONCURRENT_PROGRAMS fcp
       WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
         and fcr.request_id = P_Req_Id;

    rec_file_name cur_file_name%ROWTYPE;



  BEGIN
    g_step := 'MAIN 000 : DEBUT.';
    log_msg(g_step);

    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;

    g_step := 'MAIN 001 : INITIALISATION DES VARIABLES.';
    log_msg(g_step);
    ----- Appel de la procédure INIT -----
    init(pv_errbuf, pn_retcode);

    IF pn_retcode != 0 THEN
      pv_errbuf := 'INIT - ' || pv_errbuf;
      g_step    := pv_errbuf;
      log_msg(g_step);
      RAISE e_main;
    END IF;
    OPEN cur_avis_prelevement;
    LOOP
      FETCH cur_avis_prelevement INTO rec_avis_prelevement;
      EXIT WHEN cur_avis_prelevement%NOTFOUND;

      g_step := 'MAIN 002 : ***** RECUPERATION DES PARAMETRES *****';
      log_msg(g_step);
      select to_number(fcr1.argument1),
             fcp.concurrent_program_name || '_' || fcr1.request_id || '_1.PDF' pdf_file
      into v_cash_receipt_id,
           v_output_file
      from fnd_concurrent_requests fcr1, FND_CONCURRENT_PROGRAMS fcp
      where fcr1.concurrent_program_id = fcp.concurrent_program_id
      and fcr1.request_id = rec_avis_prelevement.request_id;
        --and fcr1.output_file_type = 'PDF'


      log_msg('cash_receipt_id : ' || TO_CHAR(v_cash_receipt_id));
      log_msg('fichier avis de prélèvement : ' || v_output_file);

      log_msg('');
      g_step := 'MAIN 003 : ***** STOCKAGE DE L''AVIS DE PRELEVEMENT *****';
      log_msg(g_step);
      log_msg('');

      -- Chargement de l'image en table
      chargement_image(pv_nom_fichier => v_output_file,
                       pb_existe      => v_existe,
                       pn_file_id     => v_file_id,
                       pv_errbuf      => pv_errbuf,
                       pn_retcode     => pn_retcode);

      IF pn_retcode != 0 THEN
        pv_errbuf := 'CHARGEMENT IMAGE - ' || pv_errbuf;
        log_msg(CHR(10) || pv_errbuf);
        RAISE e_main;
      END IF;

      -- Recherche si un document attaché AVR existe déjà sur le règlement.
      get_doc_avr(pv_cash_receipt_id => v_cash_receipt_id,
                  pv_media_id        => v_media_id,
                  pv_document_id     => v_document_id,
                  pv_errbuf          => pv_errbuf,
                  pn_retcode         => pn_retcode);

      IF v_document_id IS NOT NULL THEN

        -- Mise à jour du document existant avec le nouveau fichier
        g_step := 'MAIN 005 : Un document de type "AVIS PRELEVEMENT" est déjà rattaché à ce règlement.';
        log_msg(g_step);
        update_attached_document_avr(pv_filename    => v_output_file,
                                     pn_file_id     => v_file_id,
                                     pn_document_id => v_document_id,
                                     pv_errbuf      => pv_errbuf,
                                     pn_retcode     => pn_retcode);

        IF pn_retcode != 0 THEN
          pv_errbuf := 'UPDATE ATTACHED DOCUMENT AVR - ' || pv_errbuf;
          log_msg(CHR(10) || pv_errbuf);
          RAISE e_main;
        END IF;

        -- Suppression de l'ancien fichier
        delete_image(pn_file_id => v_media_id,
                     pv_errbuf  => pv_errbuf,
                     pn_retcode => pn_retcode);

        IF pn_retcode != 0 THEN
          pv_errbuf := 'DELETE IMAGE - ' || pv_errbuf;
          log_msg(CHR(10) || pv_errbuf);
          RAISE e_main;
        END IF;

      ELSE

        -- Création d'un nouveau document joint
        create_attached_document_avr(v_output_file,
                                     v_cash_receipt_id,
                                     v_file_id,
                                     rec_avis_prelevement.org_id,
                                     pv_errbuf,
                                     pn_retcode);

        IF pn_retcode != 0 THEN
          pv_errbuf := 'CREATE ATTACHED DOCUMENT AVR - ' || pv_errbuf;
          log_msg(CHR(10) || pv_errbuf);
          RAISE e_main;
        END IF;
      END IF;
	  
	  COMMIT;
	  
      ---- ARA
      fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'Récupération des informations SMTP');

    
    
    BEGIN
       select tmp.region
       INTO v_region
      FROM dka_sarautoprelev_tmp tmp,
           ar_cash_receipts_all  arca,
           hz_cust_accounts      hca,
           hz_cust_acct_sites_all hcasa,
           hz_cust_site_uses_all hcsua,
           hr_operating_units    hou
     WHERE tmp.cashreceiptid = arca.cash_receipt_id
       AND arca.pay_from_customer = hca.cust_account_id
       AND arca.customer_site_use_id = hcsua.Site_use_id
       AND hcsua.cust_acct_site_id =   hcasa.cust_acct_site_id
       AND tmp.org_id = hou.organization_id
       AND tmp.cashreceiptid = rec_avis_prelevement.CASH_RECEPT_ID;
    END;
    
    

    BEGIN
    select iepa.debit_advice_email,
       debit_advice_delivery_method
       into v_mail , v_delivery
   from iby_external_payers_all iepa, ar_cash_receipts_all arca
   where iepa.acct_site_use_id(+) = arca.customer_site_use_id
   AND debit_advice_delivery_method = 'EMAIL'
   AND iepa.debit_advice_email IS NOT NULL
   and arca.cash_receipt_id = rec_avis_prelevement.CASH_RECEPT_ID;
    EXCEPTION
    WHEN OTHERS THEN
        v_mail := 'NOMAIL';
	END;

    BEGIN
        b_ismailvalid := REGEXP_LIKE (v_mail,'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$');
    END;


      g_step := 'v_mail = ' || v_mail ;
      log_msg(g_step);


    FOR rec_file_name IN cur_file_name(rec_avis_prelevement.request_id) LOOP


		IF b_ismailvalid = FALSE OR v_mail = 'NOMAIL' THEN
        g_step     := 'envoi_mail_sans_client ' ;
        log_msg(g_step);

        fnd_file.put(fnd_file.OUTPUT, 'Règlement id = ' || rec_avis_prelevement.CASH_RECEPT_ID);
    
		--fnd_file.put_line(fnd_file.OUTPUT, 'Règlement id = ' || rec_avis_prelevement.CASH_RECEPT_ID || ' - ' || 'Mail : ' || vn_adresses(vn_cpt));
        envoi_mail_sans_client(pv_errbuf,pn_retcode,rec_file_name.pdf_file,rec_avis_prelevement.CASH_RECEPT_ID);

        ELSIF b_ismailvalid = TRUE AND v_delivery = 'EMAIL' THEN
        g_step     := 'envoi_mail_avec_client ' ;
        log_msg(g_step);
        vn_cpt := 0;
        vt_adr_to(1) := 'INIT';

        vn_cpt := vn_cpt + 1;
        vt_adr_to(vn_cpt) := v_mail;
        fnd_file.put_line(fnd_file.OUTPUT, 'Règlement id = ' || rec_avis_prelevement.CASH_RECEPT_ID || ' - ' || 'Mail : ' || vt_adr_to(vn_cpt));
        envoi_mail_avec_client(pv_errbuf,pn_retcode,rec_file_name.pdf_file,vt_adr_to,rec_avis_prelevement.CASH_RECEPT_ID);

        END IF;

    END LOOP;

    IF pn_retcode = 2 THEN
      pv_errbuf := 'ATTENTION : Erreur bloquante : ' || pv_errbuf;
	  b_error := TRUE;
    ELSE
      pv_errbuf  := 'Envoi mail OK';
      fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Mail envoyé');
      pn_retcode := 0;
    END IF;
    Fnd_File.put_line(Fnd_File.OUTPUT, pv_errbuf || CHR(10));


      -- End mail ARA
    END LOOP;
    CLOSE cur_avis_prelevement;

    IF b_error = TRUE THEN
        pn_retcode := 2;
    END IF;

    g_step := 'MAIN 999 - FIN.';
    log_msg(g_step);



  EXCEPTION
    WHEN e_main THEN
      pn_retcode := 2;
    WHEN e_dest_error THEN
      pn_retcode := 1;
      pv_errbuf  := 'L''envoi de mail n''a pas pu être effectué car aucun destinataire n''est actif.';
      Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || pv_errbuf || CHR(10));
    WHEN e_etat_error THEN
      pn_retcode := 2;
      Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || pv_errbuf || CHR(10));
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Procédure main en erreur ' || SQLERRM;
      g_step     := 'MAIN 999 - ERREUR : ' || pv_errbuf;
      log_msg(g_step);
  END main;

END DKA_SARPREL_ATTACH_PKG;
/
show error;
exit;