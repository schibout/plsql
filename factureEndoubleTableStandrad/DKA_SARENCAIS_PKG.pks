CREATE OR REPLACE PACKAGE BODY dka_spobon_mail_pkg AS
------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOBON_MAIL_PKG.pkb
-- DESCRIPTION       : DKA_SPOBON_MAIL_PKG package body :
--
-- AUTEUR           : CAPGEMINI
-- DATE DE CREATION : 30/07/2009
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------------------------
-- 03/04/2012 BCO Modification de la date d'envoi du mail pour la mettre au format Americain.
------------------------------------------------------------------------------------------
-- 24/05/2016 MEG Migration R12
------------------------------------------------------------------------------------------
-- 21/02/2017 MEG Correction artf2098623
------------------------------------------------------------------------------------------
-- 24/05/2017 YWA artf2157040
------------------------------------------------------------------------------------------
-- 20/02/2018 JWY artf2389456 - Correctif lié au duplicata pour les commandes sans DA
------------------------------------------------------------------------------------------
-- 10/04/2018 RBE artf2516306 : SPE061 - Ne plus envoyer les bons de commande des contrats SSTR par mail aux demandeurs 
-- 19/11/2019 SEL - INC0361763
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    gn_user_id                      fnd_user.user_id%TYPE;
    gn_login_id                     fnd_logins.login_id%TYPE;
    gn_org_id                       hr_all_organization_units.organization_id%TYPE;
    gn_request_id                   fnd_concurrent_requests.request_id%TYPE;

    gv_base                         VARCHAR2(50);
    gv_entite                       VARCHAR2(50);
    --gv_envoi_entite                 VARCHAR2(5);
    gv_dir_source                   VARCHAR2(200);
    Vn_Request_Id                   Fnd_Concurrent_Requests.Request_Id%TYPE;
    gv_conn                         VARCHAR2(30);
    gv_expediteur                   VARCHAR2(50);
    gv_mail_test                    VARCHAR2(240) := NULL; -- Adresse de test a qui seront envoyés les mails.
    gv_subject                      VARCHAR2(4000);
    gv_body                         VARCHAR2(4000);
    gv_type_attachment              VARCHAR2(50);
    gv_base_prod                    VARCHAR2(20);
    gn_amt                          BINARY_INTEGER := 672 * 3;  /* ensures proper format;  2016 */

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
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode      OUT   NUMBER,
        pv_mail_test IN       VARCHAR2
    )

    IS
        rec_param   dka_parameters%ROWTYPE;
        vv_category fnd_document_categories.name%TYPE;
        e_err_param EXCEPTION;

    BEGIN
        dka_tools_pkg.put_debug_message ('(+) Init');
        pv_errbuf     := NULL;
        pn_retcode    := 0;

        -- En-tête du fichier de sortie
        dka_tools_pkg.put_out_header;

        -- Variables globale "WHO"
        gn_user_id                      := fnd_global.user_id;
        gn_login_id                     := fnd_global.login_id;
        gn_request_id                   := fnd_global.conc_request_id;
        gn_org_id                       := fnd_global.org_id; --fnd_profile.value ('ORG_ID');

        --Récupération du nom de la base de données concernée
        BEGIN
          SELECT name
          INTO gv_base
          FROM v$database;
          EXCEPTION
            WHEN OTHERS THEN
                pv_errbuf := 'ERREUR lors de la recherche du nom de la base de données';
                pn_retcode := 2;
                RAISE;
        END;

        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'gv_base : ' || gv_base);

/*        BEGIN
          SELECT gsob.name
          INTO   gv_entite
          FROM   gl_sets_of_books gsob
          WHERE  gsob.set_of_books_id = TO_NUMBER(gl_access_set_security_pkg.get_default_ledger_id(FND_PROFILE.value('GL_ACCESS_SET_ID'), 'R')) --Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID')
          ;

          EXCEPTION
            WHEN OTHERS THEN
                pv_errbuf := 'ERREUR lors de la recherche du nom de l''entité comptable';
                pn_retcode := 2;
                RAISE;
        END;

        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'gv_entite : ' || gv_entite);  */

        --gv_envoi_entite := nvl(dka_stransco_pkg.etl_get_value_f('DKA_SPOBON_EMAIL',trunc(SYSDATE),gv_entite), 'NON');

        --Dka_Tools_Pkg.put_debug_message (CHR (10) || 'gv_envoi_entite : ' || gv_envoi_entite);

        --Recherche du répertoire source des fichiers de BdC
        BEGIN
        SELECT  DIRECTORY_PATH
        INTO gv_dir_source
        from DBA_DIRECTORIES
        WHERE directory_name = 'DALKIA_LOADBDC';

        EXCEPTION
            WHEN OTHERS THEN
                pv_errbuf := 'ERREUR lors de la recherche du répertoire source des fichiers de BdC';
                pn_retcode := 2;
                RAISE;
        END;

       --Recuperation des parametres de connexion
       Dka_Tools_Pkg.get_parameter ('SPOBON_MAIL', 'SMTP_CONNECTION', rec_param, pv_errbuf, pn_retcode);
       gv_conn := rec_param.varchar2_value;

       Dka_Tools_Pkg.put_debug_message('Connexion SMTP : '||gv_conn);

       IF pn_retcode != 0 THEN
          RAISE e_err_param;
       END IF;

       --Recuperation du nombre de reconduction max
       Dka_Tools_Pkg.get_parameter ('SPOBON_MAIL', 'EXPEDITEUR_MAIL', rec_param, pv_errbuf, pn_retcode);
       gv_expediteur := rec_param.varchar2_value;

       Dka_Tools_Pkg.put_debug_message('Expediteur mail : '||gv_expediteur);

       IF pn_retcode != 0 THEN
          RAISE e_err_param;
       END IF;

       --Recuperation du nombre de reconduction max
       Dka_Tools_Pkg.get_parameter ('SPOBON_MAIL', 'TYPE_PIECE_JOINTE', rec_param, pv_errbuf, pn_retcode);
       gv_type_attachment := rec_param.varchar2_value;

       Dka_Tools_Pkg.put_debug_message('Type Piece jointe : '||gv_type_attachment);

       IF pn_retcode != 0 THEN
          RAISE e_err_param;
       END IF;

       --Recuperation du nom de la base de production
       Dka_Tools_Pkg.get_parameter ('TOOLS', 'BASE_PRODUCTION', rec_param, pv_errbuf, pn_retcode);
       gv_base_prod := rec_param.varchar2_value;

       Dka_Tools_Pkg.put_debug_message('Nom de la base de production : '||gv_base_prod);

       IF pn_retcode != 0 THEN
          RAISE e_err_param;
       END IF;

       dka_tools_pkg.put_debug_message ('(-) Init');

    EXCEPTION
        WHEN OTHERS
        THEN
            dka_tools_pkg.put_debug_message ('WHEN OTHERS (Init): ' || pv_errbuf);
            pn_retcode   := 2;
            pv_errbuf    := 'INIT : ' ||SQLERRM;
    END init;


----------------------------------------------------------------------------
--  Nom           : get_po_header_id
--  Description   : Fonction qui renvoie en retour l'Id de la commande
--
--  PARAMETRES :
--
--    VALEUR RETOURNEE :  pv_numero_cde
--
----------------------------------------------------------------------------
    FUNCTION get_po_header_id (
        pv_numero_cde   IN   VARCHAR2
    )
    RETURN NUMBER
    IS
        vn_po_header_id   po_headers_all.po_header_id%TYPE;
    BEGIN
        SELECT DISTINCT po_header_id
        INTO   vn_po_header_id
        FROM   po_headers_all
        WHERE  segment1 = pv_numero_cde
        AND    org_id = gn_org_id;

        RETURN vn_po_header_id;

    END get_po_header_id;

----------------------------------------------------------------------------
--  Nom           : get_po_org_name
--  Description   : Fonction qui renvoie en retour le nom de l'org de la cmd
--
--  PARAMETRES    : Identifiant de la commande
--
--  VALEUR RETOURNEE :  VARCHAR2
--
----------------------------------------------------------------------------
    FUNCTION get_po_org_name (
        pv_id_cde IN VARCHAR2
    )
    RETURN VARCHAR2
    IS
      vv_org_name hr_all_organization_units.name%TYPE;

    BEGIN
      SELECT haou.name
        INTO vv_org_name
        FROM po_headers_all pha, hr_all_organization_units haou
       WHERE pha.org_id = haou.organization_id
         AND po_header_id = pv_id_cde;

      RETURN vv_org_name;

    END get_po_org_name;

-------------------------------------------------------------------------------------
--  Nom           : GET_MESSAGE
--  Description   : procedure de recuperation des messages
--
--  PARAMETRES    :
--  pn_header_id IN       identifiant du contrat
--  pv_errbuf    IN OUT   message de sortie
--  pn_retcode   OUT      code retour
--  VALEUR RETOURNEE :  pn_retcode
--Valeurs possibles : 0=normal, 1=warning, 2=erreur
------------------------------------------------------------------------------------
   PROCEDURE get_message (
        pn_header_id    IN       PO_HEADERS_ALL.po_header_id%TYPE,
        pv_errbuf       OUT      VARCHAR2,
        pn_retcode      OUT      NUMBER
   ) IS

    l_fournisseur        po_vendors.Vendor_Name%TYPE;
    l_date_creation         VARCHAR2(10);
    l_ref_da_commande    VARCHAR2(100);
    l_prem_phrase        VARCHAR2(200);
    l_ref_document       VARCHAR2(100);
    l_demandeur          VARCHAR2(50);
    l_num_commande       VARCHAR2(30);
    l_site_fournisseur   VARCHAR2(15);
    l_entite_entete      VARCHAR2(30);
  --  l_cpt                NUMBER := 0;    JWY artf2389456
  --  e_warn_da            EXCEPTION;      JWY artf2389456

    CURSOR cur_DA_num (pn_header_id VARCHAR2)
    IS
       SELECT distinct prh.segment1 Num_DA
       FROM   po_headers_all ph,
              po_distributions_all pd,
              po_req_distributions_all prd,
              po_requisition_lines_all prl,
              po_requisition_headers_all prh
       WHERE ph.po_header_id  = pn_header_id
       AND ph.po_header_id = pd.po_header_id
       AND pd.req_distribution_id = prd.distribution_id
       AND prl.requisition_line_id = prd.requisition_line_id
       AND prh.requisition_header_id = prl.requisition_header_id;

    rec_DA_num   cur_DA_num%ROWTYPE;

   BEGIN

     l_ref_da_commande := NULL;

     SELECT distinct
      papf.attribute1||ph.segment1||DECODE(ph.revision_num, '0', NULL,'-V'||TO_CHAR (ph.revision_num)),
      papf.full_name,
      pv.vendor_name,
      pvs.vendor_site_code,
      to_char(trunc(ph.creation_date),'DD-MON-RR')
     INTO
      l_num_commande,
      l_demandeur,
      l_fournisseur,
      l_site_fournisseur,
      l_date_creation
     FROM
      po_headers_all ph,
      po_vendors pv,
      po_vendor_sites_all pvs,
      per_all_people_f papf
     WHERE
      ph.po_header_id  = pn_header_id
      AND ph.vendor_id = pv.vendor_id
      AND ph.vendor_site_id = pvs.vendor_site_id
      AND ph.agent_id = papf.person_id(+)
      AND trunc(sysdate) between papf.effective_start_date and papf .effective_end_date
     ;


      --l_entite_entete := rtrim(rtrim(gv_entite,'OPERATIONNELLE'),'_');
      l_entite_entete := gv_entite;

      -- Récupération du ou des numéros de DA
      FOR rec_DA_num IN cur_DA_num (pn_header_id)
      LOOP
          BEGIN
              l_ref_da_commande := l_ref_da_commande||'DA '|| rec_DA_num.Num_DA||' ';

              IF l_ref_document IS NULL THEN
                    l_ref_document := rec_DA_num.Num_DA;
                    l_prem_phrase := 'La demande d''achat '||l_ref_document||' émise par '||l_demandeur||' a été transformée en commande.';
              ELSE
                    l_ref_document := l_ref_document||', '||rec_DA_num.Num_DA;
                    l_prem_phrase := 'Les demandes d''achat '||l_ref_document||' émises par '||l_demandeur||' ont été transformées en commande.';
              END IF;
          END;
  --        l_cpt := l_cpt + 1;   -- JWY artf2389456
      END LOOP;

      -- JWY artf2389456
      /*IF l_cpt = 0 THEN
        RAISE e_warn_da;
      END IF;*/

      l_ref_da_commande := l_ref_da_commande||' Commande '||l_num_commande;

      IF l_prem_phrase IS NULL THEN
          l_prem_phrase := 'La commande '||l_num_commande||' émise par '||l_demandeur||' a été créée';
      END IF;

     --GET MESSAGE
     gv_subject := Dka_Tools_Pkg.get_message('DKA','DKA_SPOBON_DUPLI_MAIL_SUJET',
                                             'ENTITE',l_entite_entete,
                                             'REF_DA_COMMANDE',l_ref_da_commande,
                                             'NOM_FOURNISSEUR',l_fournisseur);

     gv_body := Dka_Tools_Pkg.get_message('DKA','DKA_SPOBON_DUPLI_MAIL_CORPS',
                                          'REF_DOCUMENT',l_prem_phrase,
                                          'NUM_COMMANDE',l_num_commande,
                                          'NOM_FOURNISSEUR',l_fournisseur,
                                          'SITE_FOURNISSEUR',l_site_fournisseur,
                                          'DATE_CREATION',l_date_creation);


   EXCEPTION
   -- JWY artf2389456
  /*  WHEN e_warn_da THEN
     pv_errbuf  := 'Commande sans DA, pas d''envoi au demandeur';
     pn_retcode := 1;*/
    WHEN OTHERS THEN
     pv_errbuf  := 'Erreur procedure GET_MESSAGE '|| SQLERRM;
     pn_retcode := 2;
     Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
   END get_message;


----------------------------------------------------------------------------
--  Nom           : get_po_header_id
--  Description   : Fonction qui renvoie en retour l'Id de la commande
--
--  PARAMETRES :
--
--    VALEUR RETOURNEE :  pv_numero_cde
--
----------------------------------------------------------------------------
    PROCEDURE get_address_mail (
        pv_employee_id     IN   VARCHAR2,
        pv_mail_test       IN   VARCHAR2,
        pv_address_envoi   OUT  VARCHAR2,
        pv_employee_envoi  OUT  VARCHAR2,
        pv_matricule_envoi OUT  VARCHAR2,
        pv_errbuf          OUT  VARCHAR2,
        pn_retcode         OUT  NUMBER
    )
    IS
        vn_po_header_id   po_headers_all.po_header_id%TYPE;
        vv_address_mail   per_people_f.email_address%TYPE;
        vv_employee_id    per_people_f.person_id%TYPE;
    BEGIN

        SELECT trim(nvl(ppf.EMAIL_ADDRESS,fu.email_address)),
               ppf.full_name,
               ppf.employee_number
        INTO  pv_address_envoi,
              pv_employee_envoi,
              pv_matricule_envoi
        FROM  fnd_user fu,
              per_people_f ppf
        WHERE ppf.person_id = pv_employee_id
        AND   fu.employee_id(+) = ppf.person_id
       -- AND   rownum = 1  -- SEL - INC0361763
		AND   trunc(sysdate) BETWEEN ppf.effective_start_date AND ppf.effective_end_date ; -- SEL - INC0361763

        vv_employee_id := pv_employee_id;

            WHILE pv_address_envoi IS NULL
            LOOP
               ----- Récupérer l'adresse mail du superviseur -----
               BEGIN
               SELECT ppf_sup.person_id,
                      trim(nvl(ppf_sup.email_address,fu_sup.email_address)),
                      ppf_sup.full_name,
                      ppf_sup.employee_number
               INTO vv_employee_id,
                    pv_address_envoi,
                    pv_employee_envoi,
                    pv_matricule_envoi
               FROM per_people_f ppf,
                    per_people_f ppf_sup,
                    per_all_assignments_f paf,
                    fnd_user fu_sup
               WHERE paf.supervisor_id = ppf_sup.person_id(+)
               AND   paf.person_id = ppf.person_id
               AND   fu_sup.employee_id(+) = ppf_sup.person_id
               AND   trunc(sysdate) BETWEEN paf.effective_start_date AND paf.effective_end_date
               AND   ppf.person_id = vv_employee_id
               AND   rownum = 1;

               EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  pn_retcode := 1;
                  RAISE;
               WHEN OTHERS THEN
                  pv_errbuf := 'ERREUR lors de la recherche de l''adesse mail';
                  pn_retcode := 2;
                  RAISE;
               END;

            END LOOP;

      ------------------------------------
      --INITIALISATION ADRESSE MAIL TEST--
      ------------------------------------
      DKA_SEND_MAIL_PKG.mail_test(pv_mail_test,gv_mail_test);
      Dka_Tools_Pkg.put_outdebug_message('Mail de test :'||gv_mail_test);

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
          pn_retcode := 1;
    WHEN OTHERS THEN
          pv_errbuf  := 'Erreur procedure GET_ADDRESS_MAIL '|| SQLERRM;
          pn_retcode := 2;
          Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
    END get_address_mail;


----------------------------------------------------------------------------
--  Nom           : write_boundary
--  Description   : Procédure
--
--  PARAMETRES :
--    VALEUR RETOURNEE :
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
    PROCEDURE write_boundary(conn IN OUT NOCOPY utl_smtp.connection,
                             last IN BOOLEAN DEFAULT FALSE)
    AS
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
                               transfer_enc IN VARCHAR2 DEFAULT NULL)
    IS
    BEGIN
        write_boundary(conn);
        utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Type: ' || mime_type || utl_tcp.CRLF));
        IF (filename IS NOT NULL) THEN
            IF (inline) THEN
               utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Disposition: ' || 'inline; filename="'||filename||'"' || utl_tcp.CRLF));
            ELSE
               utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Disposition: ' || 'attachment; filename="'||filename||'"' || utl_tcp.CRLF));
            END IF;
        END IF;
        IF (transfer_enc IS NOT NULL) THEN
            utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Transfer-Encoding: ' || transfer_enc || utl_tcp.CRLF));
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
                              last IN BOOLEAN DEFAULT FALSE)
    IS
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
--  pv_signataire IN       signataire du contrat (destinataire du mail)
--  pv_subject    IN       Sujet du courriel
--  pv_body       IN       Corps du courriel
--  pv_errbuf     IN OUT   message de sortie
--  pn_retcode    OUT      code retour
--  VALEUR RETOURNEE :  pn_retcode
--Valeurs possibles : 0=normal, 1=warning, 2=erreur
------------------------------------------------------------------------------------

    PROCEDURE envoi_mail (
        pv_destinataire IN       PER_PEOPLE_F.PERSON_ID%TYPE,
        pv_header_id    IN       PO_HEADERS_ALL.PO_HEADER_ID%TYPE,
        pv_file_name    IN       VARCHAR2,
        pv_mail_test    IN       VARCHAR2,
        pv_errbuf       OUT      VARCHAR2,
        pn_retcode      OUT      NUMBER
    ) IS

      l_email            fnd_user.email_address%TYPE;
      pv_employee_envoi  VARCHAR2(300);
      pv_matricule_envoi VARCHAR2(50);

      l_mesg VARCHAR2( 4000 );
      l_conn UTL_SMTP.CONNECTION;
      l_file BFILE;
      l_file_len PLS_INTEGER;
      l_modulo PLS_INTEGER;
      l_pieces PLS_INTEGER;
      l_filepos PLS_INTEGER := 1; /* pointeur pour le fichier */
      l_buf RAW(2100);
      l_data RAW(2100);
      l_chunks PLS_INTEGER;

    BEGIN

      ----- Appel de la procédure de récupération des messages -----
      get_message (pv_header_id, pv_errbuf, pn_retcode);

      IF pn_retcode != 0
      THEN
            pv_errbuf    := 'GET_MESSAGE - ' || pv_errbuf;
            Dka_Tools_Pkg.put_outdebug_message( CHR(10)||pv_errbuf);
            RETURN;
      END IF;

      ----- Appel de la procédure de calcul de l'adresse mail -----
      get_address_mail(pv_destinataire, pv_mail_test, l_email, pv_employee_envoi, pv_matricule_envoi, pv_errbuf, pn_retcode);

      IF pn_retcode = 2
      THEN
            pv_errbuf    := 'GET_ADDRESS_MAIL - ' || pv_errbuf;
            Dka_Tools_Pkg.put_outdebug_message( CHR(10)||pv_errbuf);
            RETURN;
      END IF;

      -- Gestion du cas où aucune adresse n'a été trouvée
      IF l_email IS NOT NULL OR gv_mail_test IS NOT NULL THEN

         -- Création et envoi du mail au créateur
         l_conn:= utl_smtp.open_connection( gv_conn, 25 );

         utl_smtp.helo( l_conn , gv_conn );
         utl_smtp.mail( l_conn , gv_expediteur );
         utl_smtp.rcpt( l_conn , '<'||NVL(gv_mail_test,l_email)||'>' );
         utl_smtp.open_data(l_conn);
         -- l_mesg:= 'Date: ' || TO_CHAR( SYSDATE, 'dd Mon yy hh24:mi:ss' ) || utl_tcp.CRLF ||
		 -- l_mesg:= 'Date: ' || to_char(systimestamp, 'dd Mon yy hh24:mi:ss tzhtzm') || utl_tcp.CRLF ||
		 l_mesg:= 'Date: ' || to_char(systimestamp, 'dd Mon yyyy hh24:mi:ss tzhtzm','NLS_DATE_LANGUAGE=American') || utl_tcp.CRLF ||
                  'From: ' || gv_expediteur || utl_tcp.CRLF ||
                  'To: ' || pv_employee_envoi || ' <' || NVL(gv_mail_test,l_email) || '>' || utl_tcp.CRLF ||
                  'Subject:' || gv_subject || utl_tcp.CRLF ||
                  'Content-Type: '|| MULTIPART_MIME_TYPE || utl_tcp.CRLF||
                          utl_tcp.CRLF;-- YWA artf2157040
        utl_smtp.write_data(l_conn, l_mesg);

        -- Insertion du corps du message
        BEGIN
             begin_attachment(conn => l_conn,
                              mime_type => 'text/html'
                              );
             utl_smtp.write_data(l_conn, gv_body || utl_tcp.CRLF);
             end_attachment(conn => l_conn );

        END;

        -- Insertion pièce jointe
        BEGIN
             begin_attachment(conn => l_conn,
                              mime_type => gv_type_attachment,
                              inline => TRUE,
                              filename => pv_file_name,
                              transfer_enc => 'base64');

             BEGIN
                 l_file := BFILENAME('DALKIA_TMPBDC', pv_file_name);
                 l_file_len := dbms_lob.getlength(l_file);
                 l_modulo := mod(l_file_len, gn_amt);
                 l_pieces := trunc(l_file_len / gn_amt);

                 IF (l_modulo <> 0 and l_modulo != l_file_len  ) THEN -- YWA artf2157040
                    l_pieces := l_pieces + 1;
                 END IF;

                 dbms_lob.fileopen(l_file, dbms_lob.file_readonly);
                 dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);

                 -- YWA artf2157040
                 IF  (l_pieces < 1) THEN
                    utl_smtp.write_raw_data( l_conn, utl_encode.base64_encode(l_buf ) );
                 END IF;-- YWA artf2157040
                 l_data := NULL;

                 FOR i IN 1..l_pieces LOOP
                     l_filepos := i * gn_amt + 1;
                     l_file_len := l_file_len - gn_amt;
                     l_data := utl_raw.concat(l_data, l_buf);
                     l_chunks := trunc(utl_raw.length(l_data) / MAX_LINE_WIDTH);

                     IF (i <> l_pieces) THEN
                         l_chunks := l_chunks - 1;
                     END IF;

                     utl_smtp.write_raw_data( l_conn, utl_encode.base64_encode(l_data ) );
                     l_data := NULL;

                     IF (l_file_len < gn_amt AND l_file_len > 0) THEN
                         gn_amt := l_file_len;
                     END IF;

                     dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
                 END LOOP;
            END;
            dbms_lob.fileclose(l_file);

            end_attachment(conn => l_conn, last => TRUE );
        END; -- Fin de l'insertion de la pièce jointe


        utl_smtp.close_data(l_conn);
        utl_smtp.quit( l_conn );

        Dka_Tools_Pkg.put_outdebug_message('==> Mail BdC envoye a : '|| pv_employee_envoi ||' ('|| pv_matricule_envoi ||')'|| ' - adresse : <' || l_email || '>');

      ELSE

        Dka_Tools_Pkg.put_outdebug_message(CHR(10)||'==> AVERTISSEMENT : Pas d''envoi effectué : Aucune adresse mail disponible' );

      END IF;


    EXCEPTION
      WHEN OTHERS THEN
         pv_errbuf  := 'Erreur procedure ENVOI_MAIL '|| SQLERRM;
         pn_retcode := 1;
         Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
    END envoi_mail;


----------------------------------------------------------------------------
--  Nom           : main
--  Description   : procédure principale du stockage des bons de commande
--
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------

  PROCEDURE main
           (pv_errbuf    IN OUT VARCHAR2,
            pn_retcode      OUT NUMBER,
            pv_mail_test IN     VARCHAR2)

  IS

    v_request_set_id       NUMBER;
    v_bdc_request_id       NUMBER;
    v_po_num               fnd_concurrent_requests.argument3%TYPE;
    v_output_file          VARCHAR2(100);
    v_existe               BOOLEAN;
    v_file_id              NUMBER;
    v_po_header_id         po_headers_all.po_header_id%TYPE;
    vv_nom_fichier         VARCHAR2(100);
    vv_matricule_demandeur VARCHAR2(30);
    vv_matricule_createur  VARCHAR2(30);
    vv_nom_demandeur       VARCHAR2(240);
    vv_nom_createur        VARCHAR2(240);
    vn_id_demandeur        NUMBER;
	
	--Exception
    e_ivalua            EXCEPTION;

    l_count             NUMBER;


  BEGIN

        dka_tools_pkg.put_debug_message ('(+) main');

        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'début de la procédure principale' || CHR (10));

        ----- Appel de la procédure INIT -----
        init (pv_errbuf, pn_retcode, pv_mail_test);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'INIT - ' || pv_errbuf;
            Dka_Tools_Pkg.put_outdebug_message( CHR(10)||pv_errbuf);
            RETURN;
        END IF;

        Dka_Tools_Pkg.put_outdebug_message('***** RECUPERATION DES PARAMETRES *****');
        Dka_Tools_Pkg.put_outdebug_message( CHR(10));


        BEGIN
        SELECT fcr1.request_id,
               fcr3.parent_request_id,
               fcr1.argument3,
               SUBSTR (fcr1.outfile_name, INSTR (fcr1.outfile_name, '/', -1, 1) + 1)
        INTO   v_bdc_request_id,
               v_request_set_id,
               v_po_num,
               v_output_file
        FROM   fnd_concurrent_requests fcr1, -- prog edition bdc
               fnd_concurrent_requests fcr2, -- etape edition bdc
               fnd_concurrent_requests fcr3, -- etape envoi bdc par mail
               fnd_concurrent_requests fcr4  -- prog envoi bdc par mail
        WHERE      fcr4.request_id = gn_request_id
               AND fcr3.request_id = fcr4.parent_request_id + 0
               AND fcr2.parent_request_id = fcr3.parent_request_id + 0
               AND fcr1.parent_request_id = fcr2.request_id + 0
               AND fcr1.output_file_type = 'PDF';

         EXCEPTION
         WHEN OTHERS THEN
         dka_tools_pkg.put_outdebug_message(SQLCODE || '=' ||substr(SQLERRM, 1, 400));
         dka_tools_pkg.put_outdebug_message(SQLERRM);

        END;

        Dka_Tools_Pkg.put_outdebug_message ('request_id : '|| TO_CHAR (gn_request_id));
        Dka_Tools_Pkg.put_outdebug_message ('request_id edition bdc  : '|| TO_CHAR (v_bdc_request_id));
        Dka_Tools_Pkg.put_outdebug_message ('request_id du jeu : '|| TO_CHAR (v_request_set_id));
        Dka_Tools_Pkg.put_outdebug_message ('num commande : '|| v_po_num);
        Dka_Tools_Pkg.put_outdebug_message ('fichier bdc : '|| v_output_file);
		
		SELECT
			COUNT(1)
		  INTO
			l_count
		  FROM
		   po_headers ph
		  WHERE
		   ph.segment1 = v_po_num
		   AND ph.org_id = gn_org_id
		   AND NVL(ATTRIBUTE7, 'ORACLE') IN ('IVALUA', 'REPRISE')
		  ;
		
		IF l_count > 0 THEN
          RAISE e_ivalua;
        END IF;


        -- Récupération de l'Id de la commande
        v_po_header_id := get_po_header_id(v_po_num);
        Dka_Tools_Pkg.put_outdebug_message ('Id commande : '|| v_po_header_id);

        gv_entite := get_po_org_name(v_po_header_id);
        Dka_Tools_Pkg.put_outdebug_message ('Nom de l''organisation : '|| gv_entite);

        Dka_Tools_Pkg.put_outdebug_message( CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('***** ENVOI DU BON DE COMMANDE AU DEMANDEUR *****');
        Dka_Tools_Pkg.put_outdebug_message( CHR(10));

        -- Récupération des informations de la commande
        BEGIN

           SELECT haou.name || '_' || php.segment1 || '.pdf',
                  papf.person_id id_demandeur,
                  papf.employee_number matricule_demandeur,
                  papf.full_name nom_demandeur,
                  papf2.employee_number matricule_createur,
                  papf2.full_name nom_createur
           INTO   vv_nom_fichier,
                  vn_id_demandeur,
                  vv_matricule_demandeur,
                  vv_nom_demandeur,
                  vv_matricule_createur,
                  vv_nom_createur
           FROM   po_headers php,
                  per_all_people_f papf,
                  fnd_user fu,
                  per_all_people_f papf2,
                  hr_all_organization_units haou
           WHERE  php.agent_id = papf.person_id(+)
             AND  php.org_id = haou.organization_id
             AND  trunc(sysdate) between papf.effective_start_date and papf .effective_end_date
             AND  php.created_by = fu.user_id
             AND  fu.employee_id = papf2.person_id
             AND  trunc(sysdate) between papf2.effective_start_date and papf2.effective_end_date
             AND  php.type_lookup_code <> 'CONTRACT' -- RBE artf2516306 
             AND (php.type_lookup_code <> 'BLANKET' AND NVL(php.GLOBAL_AGREEMENT_FLAG,'N') <> 'Y')
             AND  php.po_header_id = v_po_header_id;

        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            vv_matricule_demandeur := 0;
            vv_matricule_createur := 0;
        WHEN OTHERS
        THEN
             app_exception.raise_exception;
        END;

        Dka_Tools_Pkg.put_outdebug_message ('Demandeur : '|| vv_nom_demandeur ||' ('||vv_matricule_demandeur||')');
        Dka_Tools_Pkg.put_outdebug_message ('Créateur : '|| vv_nom_createur ||' ('||vv_matricule_createur||')');
        Dka_Tools_Pkg.put_outdebug_message ('Fichier BdC : '|| vv_nom_fichier);

        --IF gv_envoi_entite = 'OUI'
        --THEN

           --IF vv_matricule_demandeur != vv_matricule_createur
           IF (vv_matricule_demandeur != vv_matricule_createur AND gv_base = gv_base_prod) -- Pour éviter envoi par mail automatique sur base de test
           THEN


               Dka_Tools_Pkg.put_outdebug_message ('Copie et renommage du fichier PDF');
		   			    UTL_FILE.FCOPY ('DALKIA_LOADBDC', v_output_file, 'DALKIA_TMPBDC', vv_nom_fichier,1,NULL);

               Dka_Tools_Pkg.put_outdebug_message ('Constitution et envoi du mail');

               ----- Appel de la procédure INIT -----
               envoi_mail (vn_id_demandeur, v_po_header_id,vv_nom_fichier, pv_mail_test, pv_errbuf, pn_retcode);

               IF pn_retcode = 1
               THEN
                   pv_errbuf    := 'ENVOI_MAIL - ' || pv_errbuf;
                   Dka_Tools_Pkg.put_outdebug_message( CHR(10)||pv_errbuf);
                   RETURN;
               END IF;

               IF pn_retcode = 2
               THEN
                   pv_errbuf    := 'ENVOI_MAIL - ' || pv_errbuf;
                   Dka_Tools_Pkg.put_outdebug_message( CHR(10)||pv_errbuf);
                   RETURN;
               END IF;

               Dka_Tools_Pkg.put_outdebug_message ('Suppression du fichier temporaire');
				    	    UTL_FILE.FREMOVE ('DALKIA_TMPBDC', vv_nom_fichier);

           ELSE

               IF vv_matricule_demandeur = vv_matricule_createur THEN
                  Dka_Tools_Pkg.put_outdebug_message( CHR(10)||'===> PAS D''ENVOI DE MAIL (DEMANDEUR = CREATEUR)');
               ELSIF gv_base != gv_base_prod THEN
                  Dka_Tools_Pkg.put_outdebug_message( CHR(10)||'===> PAS D''ENVOI DE MAIL - BASE DE TEST');
               END IF;

           END IF;

         --ELSE
         --     Dka_Tools_Pkg.put_outdebug_message( CHR(10)||'===> PAS D''ENVOI DE MAIL - ENTITE NON CONCERNEE PAR CETTE FONCTIONNALITE');
         --END IF;


        Dka_Tools_Pkg.put_outdebug_message(CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('***** FIN DU TRAITEMENT *****');

        dka_tools_pkg.put_debug_message ('(-) main');
		
	EXCEPTION
	WHEN e_ivalua THEN
	 pv_errbuf  := 'Commande IVALUA ou REPRISE, pas d''envoi de mail';
	 pn_retcode := 1;
	 Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
  END main;



END dka_spobon_mail_pkg;
/
SHOW ERRORS PACKAGE BODY dka_spobon_mail_pkg
EXIT
