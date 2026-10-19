CREATE OR REPLACE PACKAGE BODY APPS.DKA_SAPVIR_MAIL_PKG AS
    ------------------------------------------------------------------------------------------
    -- $$
    -- CAPGEMINI
    -- PROJET            : DALKIA Oracle Applications
    -- NOM               : DKA_SAPVIR_MAIL_PKG.pkb
    -- DESCRIPTION       : DKA_SAPVIR_MAIL_PKG package body :
    --
    -- AUTEUR           : CAPGEMINI
    -- DATE DE CREATION : 12/08/2013
    -- DOC. ASSOCIEE    :
    -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
    ------------------------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- ---------- --- ------------------------------------------------------------------------
    -- 20/11/2013 CDE Modification recherche adresse mail pour bases différentes de DPROAP
    -- 22/11/2013 CDE Correction adresse mail du fournisseur
    -- 20/12/2013 BCO Optimisation du traitement (exécution d'un traitement unique pour l'ensemble des virements).
    -- 17/03/2014 BCO INC000000521658 - Modification de la procédure envoi_mail lorsque l'adresse mail est incorrecte.
    -- 11/10/2016 RBE Migration R12
    -- 01/02/2017 RBE artf2090995
    -- 14/02/2017 RBE artf2101497
    -- 14/03/2017 YWA artf2120398
    -- 26/07/2017 MEG artf2202802 : INT004 : Modification dans le code source du nom de l'instance de la base de production
  -- 25/12/2023 ARA EDB295 Lot3 - Ajout d¿une nouvelle campagne de règlement / Remboursements client
    -- ---------- --- ------------------------------------------------------------------------

    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PRIVEES
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    gn_user_id    fnd_user.user_id%TYPE;
    gn_login_id   fnd_logins.login_id%TYPE;
    gn_org_id     hr_all_organization_units.organization_id%TYPE;
    gn_request_id fnd_concurrent_requests.request_id%TYPE;

    gv_base            VARCHAR2(50);
    gv_conn            VARCHAR2(30);
    gv_base_prod       VARCHAR2(30);
    gv_expediteur      VARCHAR2(50);
    gv_subject         VARCHAR2(4000);
    gv_body            VARCHAR2(4000);
    gv_type_attachment VARCHAR2(50);
    gn_amt             BINARY_INTEGER := 672 * 3; /* ensures proper format;  2016 */
    gv_plat_appro_mail VARCHAR2(240);
    gv_plat_appro_name VARCHAR2(240);




  --EDB295
  gv_plat_appro_mail_cl VARCHAR2(240);
    gv_plat_appro_name_cl VARCHAR2(240);


    gv_mail_test                  VARCHAR2(240) := NULL;--YWA artf2120398

    -- Message d'information.
    g_step VARCHAR2(500);

    -- Variable contenant l'entête et le corps du mail.
    gv_objet VARCHAR2(4000);
    gv_corps VARCHAR2(4000);

    BOUNDARY            CONSTANT VARCHAR2(256) := '=_NextPart_DC7E1BB5_1105_4DB3_BAE3_2A6208EB099D';
    FIRST_BOUNDARY      CONSTANT VARCHAR2(256) := '--' || BOUNDARY ||
                                                  utl_tcp.CRLF;
    LAST_BOUNDARY       CONSTANT VARCHAR2(256) := '--' || BOUNDARY || '--' ||
                                                  utl_tcp.CRLF;
    MULTIPART_MIME_TYPE CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary=' ||
                                                  BOUNDARY;
    MAX_LINE_WIDTH PLS_INTEGER := 54;
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
    PROCEDURE init(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
        rec_param dka_parameters%ROWTYPE;
        e_err_param EXCEPTION;

    BEGIN
        g_step := 'INIT 000 - DEBUT.';
        log_msg(g_step);
        pv_errbuf  := NULL;
        pn_retcode := 0;

        -- En-tête du fichier de sortie
        dka_tools_pkg.put_out_header;

        -- Variables globale "WHO"
        gn_user_id    := fnd_global.user_id;
        gn_login_id   := fnd_global.login_id;
        gn_request_id := fnd_global.conc_request_id;
        gn_org_id     := fnd_profile.value('ORG_ID');

        g_step := 'INIT 001 - RECUPERATION NOM DATABASE.';
        log_msg(g_step);
        --Récupération du nom de la base de données concernée
        BEGIN
            SELECT name INTO gv_base FROM v$database;
        EXCEPTION
            WHEN OTHERS THEN
                pv_errbuf  := 'ERREUR lors de la recherche du nom de la base de données';
                pn_retcode := 2;
                RAISE e_err_param;
        END;

        g_step := 'INIT 001 - Nom base de données : ' || gv_base || '.';
        log_msg(g_step);

        g_step := 'INIT 002 - RECUPERATION SERVEUR SMTP.';
        log_msg(g_step);

        --Recuperation des parametres de connexion
        Dka_Tools_Pkg.get_parameter('SAPVIR_MAIL',
                                    'SMTP_CONNECTION',
                                    rec_param,
                                    pv_errbuf,
                                    pn_retcode);
        gv_conn := rec_param.varchar2_value;

        g_step := 'INIT 002 - Connexion SMTP : ' || gv_conn || '.';
        log_msg(g_step);

        IF pn_retcode != 0 THEN
            RAISE e_err_param;
        END IF;

        g_step := 'INIT 003 - RECUPERATION NOM SERVEUR DE PRODUCTION.';
        log_msg(g_step);

        --Recuperation des parametres de connexion
        Dka_Tools_Pkg.get_parameter('TOOLS',
                                    'BASE_PRODUCTION',
                                    rec_param,
                                    pv_errbuf,
                                    pn_retcode);
        gv_base_prod := rec_param.varchar2_value;

        g_step := 'INIT 003 - Base de production : ' || gv_base_prod || '.';
        log_msg(g_step);

        IF pn_retcode != 0 THEN
            RAISE e_err_param;
        END IF;

        g_step := 'INIT 004 - RECUPERATION ADRESSE MAIL EXPEDITEUR.';
        log_msg(g_step);

        IF gv_base != gv_base_prod THEN
            Dka_Tools_Pkg.get_parameter('SAPVIR_MAIL',
                                        'TEST_EXP_MAIL',
                                        rec_param,
                                        pv_errbuf,
                                        pn_retcode);
            gv_expediteur := rec_param.varchar2_value;
        ELSE
            Dka_Tools_Pkg.get_parameter('SAPVIR_MAIL',
                                        'EXPEDITEUR_MAIL',
                                        rec_param,
                                        pv_errbuf,
                                        pn_retcode);
            gv_expediteur := rec_param.varchar2_value;
        END IF;
        g_step := 'INIT 004 - Expediteur mail : ' || gv_expediteur || '.';
        log_msg(g_step);

        IF pn_retcode != 0 THEN
            RAISE e_err_param;
        END IF;

        g_step := 'INIT 005 - RECUPERATION TYPE PIECE JOINTE.';
        log_msg(g_step);
        Dka_Tools_Pkg.get_parameter('SAPVIR_MAIL',
                                    'TYPE_PIECE_JOINTE',
                                    rec_param,
                                    pv_errbuf,
                                    pn_retcode);
        gv_type_attachment := rec_param.varchar2_value;

        g_step := 'INIT 005 - Type Piece jointe : ' || gv_type_attachment || '.';
        log_msg(g_step);

        IF pn_retcode != 0 THEN
            RAISE e_err_param;
        END IF;

        g_step := 'INIT 006 - RECUPERATION NOM ET ADRESSE CELLULES DALKIA.';
        log_msg(g_step);

        IF gv_base != gv_base_prod THEN
            Dka_Tools_Pkg.get_parameter('SAPVIR_MAIL',
                                        'TEST_DEST_MAIL',
                                        rec_param,
                                        pv_errbuf,
                                        pn_retcode);
            gv_plat_appro_mail := rec_param.varchar2_value;
            gv_plat_appro_name := 'TEST INTERNE';

        ELSE
            BEGIN
                SELECT ffvv.FLEX_VALUE_MEANING, ffvv.DESCRIPTION
                  INTO gv_plat_appro_name, gv_plat_appro_mail
                  FROM fnd_flex_value_sets ffvs, fnd_flex_values_vl ffvv
                 WHERE ffvs.flex_value_set_name =
                       'DKA_SAPVIR_MAIL_CEL_FOURNI'
                   AND ffvs.flex_value_set_id = ffvv.FLEX_VALUE_SET_ID
           AND ffvv.enabled_flag = 'Y'  --EDB295
                   AND decode(ffvv.START_DATE_ACTIVE,
                              NULL,
                              SYSDATE,
                              ffvv.START_DATE_ACTIVE) <= SYSDATE
                   AND decode(ffvv.END_DATE_ACTIVE,
                              NULL,
                              SYSDATE,
                              ffvv.END_DATE_ACTIVE) >= SYSDATE;

                g_step := 'INIT 006 - Nom cellule fournisseur : ' ||
                          gv_plat_appro_name ||
                          ', Mail cellule fournisseur : ' ||
                          gv_plat_appro_mail || '.';
                log_msg(g_step);

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    gv_plat_appro_name := NULL;
                    gv_plat_appro_mail := NULL;
                    RAISE e_err_param;
                WHEN OTHERS THEN
                    gv_plat_appro_name := NULL;
                    gv_plat_appro_mail := NULL;
                    RAISE e_err_param;
            END;

      --ARA EDB295
      BEGIN
                SELECT ffvv.FLEX_VALUE_MEANING, ffvv.DESCRIPTION
                  INTO gv_plat_appro_name_cl, gv_plat_appro_mail_cl
                  FROM fnd_flex_value_sets ffvs, fnd_flex_values_vl ffvv
                 WHERE ffvs.flex_value_set_name =
                       'DKA_SAPVIR_MAIL_CEL_CLI'
                   AND ffvs.flex_value_set_id = ffvv.FLEX_VALUE_SET_ID
           AND ffvv.enabled_flag = 'Y'  --EDB295
                   AND decode(ffvv.START_DATE_ACTIVE,
                              NULL,
                              SYSDATE,
                              ffvv.START_DATE_ACTIVE) <= SYSDATE
                   AND decode(ffvv.END_DATE_ACTIVE,
                              NULL,
                              SYSDATE,
                              ffvv.END_DATE_ACTIVE) >= SYSDATE;

                g_step := 'INIT 006 - Nom cellule client : ' ||
                          gv_plat_appro_name_cl ||
                          ', Mail cellule client : ' ||
                          gv_plat_appro_mail_cl || '.';
                log_msg(g_step);

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    gv_plat_appro_name_cl := NULL;
                    gv_plat_appro_mail_cl := NULL;
                    RAISE e_err_param;
                WHEN OTHERS THEN
                    gv_plat_appro_name_cl := NULL;
                    gv_plat_appro_mail_cl := NULL;
                    RAISE e_err_param;
            END;


    END IF;

        g_step := 'INIT 099 - FIN.';
        log_msg(g_step);
    EXCEPTION
        WHEN OTHERS THEN
            pn_retcode := 2;
            pv_errbuf  := 'INIT : ' || SQLERRM;
    END init;


--ARA EDB295

-------------------------------------------------------------------------------------
    --  Nom           : envoi_mail_adress_client_abs
    --  Description   : Envoi du mail d'avertissement:
    --         Adresse du site client inexistante.
    --
    --  PARAMETRES    :
    --  Pn_Check      IN      Numéro du règlement
    --  Pv_Four       IN      Nom client
    --  Pv_SiteFour   IN      Nom du site client
    --  Pv_Errbuf     IN OUT      Message d'avertissement
    --  Pn_Retcode    IN OUT      Code erreur
    --------------------------------------------------------------------------------------
    PROCEDURE envoi_mail_adress_client_abs(pv_check_number IN ap_checks_all.CHECK_NUMBER%TYPE,
                                         pv_montant      IN VARCHAR2,
                                         Pv_client       IN AR_CUSTOMERS.CUSTOMER_NAME%TYPE,
                                         Pv_SiteClient   IN hz_party_sites.party_site_number%TYPE,
                     Pv_region       IN hr_all_organization_units.name%TYPE,
                                         Pv_Errbuf       IN OUT VARCHAR2,
                                         Pn_Retcode      IN OUT NUMBER) IS
        l_mesg   VARCHAR2(4000);
        l_conn   UTL_SMTP.CONNECTION;
        vr_reply UTL_SMTP.REPLY;

    p_to            VARCHAR2(30000);
    p_cc            VARCHAR2(30000);

    vv_destinataire1 VARCHAR2(1000);
    vv_destinataire2 VARCHAR2(1000);
    vv_destinataire3 VARCHAR2(1000);
    vv_destinataire4 VARCHAR2(1000);
    vv_destinataire5 VARCHAR2(1000);
    vv_destinataire6 VARCHAR2(1000);
    vv_destinataire7 VARCHAR2(1000);
    vv_destinataire8 VARCHAR2(1000);
    vv_destinataire9 VARCHAR2(1000);
    vv_destinataire10 VARCHAR2(1000);

  vv_destinataire1cc VARCHAR2(1000);
    vv_destinataire2cc VARCHAR2(1000);
    vv_destinataire3cc VARCHAR2(1000);
    vv_destinataire4cc VARCHAR2(1000);
    vv_destinataire5cc VARCHAR2(1000);
    vv_destinataire6cc VARCHAR2(1000);
    vv_destinataire7cc VARCHAR2(1000);
    vv_destinataire8cc VARCHAR2(1000);
    vv_destinataire9cc VARCHAR2(1000);
    vv_destinataire10cc VARCHAR2(1000);

  CURSOR cur_mail --()
  IS
      select substr(ffv.attribute1, 1, instr(ffv.attribute1, ';') - 1) dest1,
         substr(ffv.attribute1,
                instr(ffv.attribute1, ';', 1, 1) + 1,
                instr(ffv.attribute1, ';', 1, 2) -
                instr(ffv.attribute1, ';', 1, 1) - 1) dest2,
         substr(ffv.attribute1,
                instr(ffv.attribute1, ';', 1, 2) + 1,
                instr(ffv.attribute1, ';', 1, 3) -
                instr(ffv.attribute1, ';', 1, 2) - 1) dest3,
         substr(ffv.attribute1,
                instr(ffv.attribute1, ';', 1, 3) + 1,
                instr(ffv.attribute1, ';', 1, 4) -
                instr(ffv.attribute1, ';', 1, 3) - 1) dest4,
                   substr(ffv.attribute1,
                instr(ffv.attribute1, ';', 1, 4) + 1,
                instr(ffv.attribute1, ';', 1, 5) -
                instr(ffv.attribute1, ';', 1, 4) - 1) dest5,
         substr(ffv.attribute1,
                instr(ffv.attribute1, ';', 1, 5) + 1,
                instr(ffv.attribute1, ';', 1, 6) -
                instr(ffv.attribute1, ';', 1, 5) - 1) dest6,
         substr(ffv.attribute1,
                instr(ffv.attribute1, ';', 1, 6) + 1,
                instr(ffv.attribute1, ';', 1, 7) -
                instr(ffv.attribute1, ';', 1, 6) - 1) dest7,
         substr(ffv.attribute1,
                instr(ffv.attribute1, ';', 1, 7) + 1,
                instr(ffv.attribute1, ';', 1, 8) -
                instr(ffv.attribute1, ';', 1, 7) - 1) dest8,
         substr(ffv.attribute1,
                instr(ffv.attribute1, ';', 1, 8) + 1,
                instr(ffv.attribute1, ';', 1, 9) -
                instr(ffv.attribute1, ';', 1, 8) - 1) dest9,
         substr(ffv.attribute1,
                instr(ffv.attribute1, ';', 1, 9) + 1,
                instr(ffv.attribute1, ';', 1, 10) -
                instr(ffv.attribute1, ';', 1, 9) - 1) dest10,

         substr(ffv.attribute2, 1, instr(ffv.attribute2, ';') - 1) dest1cc,
         substr(ffv.attribute2,
                instr(ffv.attribute2, ';', 1, 1) + 1,
                instr(ffv.attribute2, ';', 1, 2) -
                instr(ffv.attribute2, ';', 1, 1) - 1) dest2cc,
         substr(ffv.attribute2,
                instr(ffv.attribute2, ';', 1, 2) + 1,
                instr(ffv.attribute2, ';', 1, 3) -
                instr(ffv.attribute2, ';', 1, 2) - 1) dest3cc,
         substr(ffv.attribute2,
                instr(ffv.attribute2, ';', 1, 3) + 1,
                instr(ffv.attribute2, ';', 1, 4) -
                instr(ffv.attribute2, ';', 1, 3) - 1) dest4cc,
                   substr(ffv.attribute2,
                instr(ffv.attribute2, ';', 1, 4) + 1,
                instr(ffv.attribute2, ';', 1, 5) -
                instr(ffv.attribute2, ';', 1, 4) - 1) dest5cc,
         substr(ffv.attribute2,
                instr(ffv.attribute2, ';', 1, 5) + 1,
                instr(ffv.attribute2, ';', 1, 6) -
                instr(ffv.attribute2, ';', 1, 5) - 1) dest6cc,
         substr(ffv.attribute2,
                instr(ffv.attribute2, ';', 1, 6) + 1,
                instr(ffv.attribute2, ';', 1, 7) -
                instr(ffv.attribute2, ';', 1, 6) - 1) dest7cc,
         substr(ffv.attribute2,
                instr(ffv.attribute2, ';', 1, 7) + 1,
                instr(ffv.attribute2, ';', 1, 8) -
                instr(ffv.attribute2, ';', 1, 7) - 1) dest8cc,
         substr(ffv.attribute2,
                instr(ffv.attribute2, ';', 1, 8) + 1,
                instr(ffv.attribute2, ';', 1, 9) -
                instr(ffv.attribute2, ';', 1, 8) - 1) dest9cc,
         substr(ffv.attribute2,
                instr(ffv.attribute2, ';', 1, 9) + 1,
                instr(ffv.attribute2, ';', 1, 10) -
                instr(ffv.attribute2, ';', 1, 9) - 1) dest10cc

      FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
       WHERE ffvs.flex_value_set_name = 'DKA_RESP_RECOUV_RBT'
       AND ffv.flex_value_set_id = ffvs.flex_value_set_id
       AND ffv.flex_value = Pv_region
       AND ffv.enabled_flag = 'Y'
       AND SYSDATE BETWEEN nvl(ffv.start_date_active, SYSDATE) AND
         nvl(ffv.end_date_active, SYSDATE);

    BEGIN

        g_step := 'ENVOI_MAIL_ADRESS_CLIENT_ABS 000 : DEBUT';
        log_msg(g_step);
        g_step := 'ENVOI_MAIL_ADRESS_CLIENT_ABS 001 : RECHERCHE DE L''OBJET DU MAIL.';
        log_msg(g_step);
        gv_objet := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_SAPAUTOVIR_CLIABSOBJ',
                                              'NOM_CLI',
                                              Pv_client);

        g_step := 'ENVOI_MAIL_ADRESS_CLIENT_ABS 002 : RECHERCHE DU CORPS DU MAIL.';
        log_msg(g_step);
        gv_corps := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_SAPAUTOVIR_CLIABSCOR',
                                              'NOM_CLI',
                                              Pv_client,
                                              'NOM_SITECLI',
                                              Pv_SiteClient);

    FOR rec_reqid IN cur_mail LOOP
      vv_destinataire1 := rec_reqid.dest1;
      vv_destinataire2 := rec_reqid.dest2;
      vv_destinataire3 := rec_reqid.dest3;
      vv_destinataire4 := rec_reqid.dest4;
      vv_destinataire5 := rec_reqid.dest5;
      vv_destinataire6 := rec_reqid.dest6;
      vv_destinataire7 := rec_reqid.dest7;
      vv_destinataire8 := rec_reqid.dest8;
      vv_destinataire9 := rec_reqid.dest9;
      vv_destinataire10 := rec_reqid.dest10;

      vv_destinataire1cc := rec_reqid.dest1cc;
      vv_destinataire2cc := rec_reqid.dest2cc;
      vv_destinataire3cc := rec_reqid.dest3cc;
      vv_destinataire4cc := rec_reqid.dest4cc;
      vv_destinataire5cc := rec_reqid.dest5cc;
      vv_destinataire6cc := rec_reqid.dest6cc;
      vv_destinataire7cc := rec_reqid.dest7cc;
      vv_destinataire8cc := rec_reqid.dest8cc;
      vv_destinataire9cc := rec_reqid.dest9cc;
      vv_destinataire10cc := rec_reqid.dest10cc;

    END LOOP;


        g_step := 'ENVOI_MAIL_ADRESS_CLIENT_ABS 003 : CONNEXION.';
        log_msg(g_step);
        l_conn := utl_smtp.open_connection(gv_conn, 25);

        g_step := 'ENVOI_MAIL_ADRESS_CLIENT_ABS 004 : DEBUT CONSTRUCTION MAIL.';
        log_msg(g_step);
        utl_smtp.helo(l_conn, gv_conn);

        vr_reply := utl_smtp.mail(l_conn, '<' || gv_expediteur || '>');
        g_step   := 'REPLY MAIL : ' || vr_reply.code || ' - ' ||
                    vr_reply.text;


     -----Ajouté else dyalha = error destinataire
    IF vv_destinataire1 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire1 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_to      := p_to || ';' || vv_destinataire1;
    END IF;


    --p_to := p_to || ';' || vv_destinataire1;


    IF vv_destinataire2 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire2 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_to      := p_to || ';' || vv_destinataire2;
     log_msg('p_to : ' || p_to);

    END IF;
       IF vv_destinataire3 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire3 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_to      := p_to || ';' || vv_destinataire3;
     log_msg('p_to : ' || p_to);
    END IF;
       IF vv_destinataire4 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire4 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_to      := p_to || ';' || vv_destinataire4;
     log_msg('p_to : ' || p_to);
    END IF;
       IF vv_destinataire5 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire5 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_to      := p_to || ';' || vv_destinataire5;
     log_msg('p_to : ' || p_to);
        END IF;
      IF vv_destinataire6 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire6 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_to      := p_to || ';' || vv_destinataire6;


      END IF;
      IF vv_destinataire7 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire7 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_to      := p_to || ';' || vv_destinataire7;
     log_msg('p_to : ' || p_to);
      END IF;
      IF vv_destinataire8 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire8 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_to      := p_to || ';' || vv_destinataire8;
     log_msg('p_to : ' || p_to);
      END IF;
      IF vv_destinataire9 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire9 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_to      := p_to || ';' || vv_destinataire9;
     log_msg('p_to : ' || p_to);
      END IF;
      IF vv_destinataire10 IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire10 || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_to      := p_to || ';' || vv_destinataire10;
     log_msg('p_to : ' || p_to);
      END IF;

    --p_to := p_to || ';' || vv_destinataire1;


    --TRIM the ';'
    SELECT  LTRIM(p_to,';') INTO p_to from dual;

    g_step := 'adresses destinataires : ' || p_to ;
      log_msg(g_step);


    --Partie CC
    IF vv_destinataire1cc IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire1cc || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_cc      := p_cc || ';' || vv_destinataire1cc;
    END IF;
    IF vv_destinataire2cc IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire2cc || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_cc      := p_cc || ';' || vv_destinataire2cc;
    END IF;
       IF vv_destinataire3cc IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire3cc || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_cc      := p_cc || ';' || vv_destinataire3cc;
    END IF;
       IF vv_destinataire4cc IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire4cc || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_cc      := p_cc || ';' || vv_destinataire4cc;
    END IF;
       IF vv_destinataire5cc IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire5cc || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_cc      := p_cc || ';' || vv_destinataire5cc;
        END IF;
      IF vv_destinataire6cc IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire6cc || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_cc      := p_cc || ';' || vv_destinataire6cc;
      END IF;
      IF vv_destinataire7cc IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire7cc || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_cc      := p_cc || ';' || vv_destinataire7cc;
      END IF;
      IF vv_destinataire8cc IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire8cc || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_cc      := p_cc || ';' || vv_destinataire8cc;
      END IF;
      IF vv_destinataire9cc IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire9cc || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_cc      := p_cc || ';' || vv_destinataire9cc;
      END IF;
      IF vv_destinataire10cc IS NOT NULL THEN
         vr_reply := utl_smtp.rcpt(l_conn, '<' || vv_destinataire10cc || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                  vr_reply.text;
         log_msg(g_step);
         p_cc      := p_cc || ';' || vv_destinataire10cc;
      END IF;




    utl_smtp.open_data(l_conn);

    IF p_cc IS NOT NULL THEN

    l_mesg := 'Date: ' ||
                  to_char(systimestamp,
                          'dd Mon yyyy hh24:mi:ss tzhtzm',
                          'NLS_DATE_LANGUAGE=American') || utl_tcp.CRLF ||
                  'From: <' || gv_expediteur || '>' || utl_tcp.CRLF ||
                  'To: <' || p_to || '>' || utl_tcp.CRLF ||
          'CC: ' || p_cc || utl_tcp.CRLF ||
                  'Subject:' || gv_objet || utl_tcp.CRLF ||
                  'Content-Type: text/html; charset=windows-1252' ||
                  utl_tcp.CRLF || utl_tcp.CRLF || gv_corps;
    ELSE

        l_mesg := 'Date: ' ||
                  to_char(systimestamp,
                          'dd Mon yyyy hh24:mi:ss tzhtzm',
                          'NLS_DATE_LANGUAGE=American') || utl_tcp.CRLF ||
                  'From: <' || gv_expediteur || '>' || utl_tcp.CRLF ||
                  'To: <' || gv_plat_appro_mail || '>' || utl_tcp.CRLF ||
                  'Subject:' || gv_objet || utl_tcp.CRLF ||
                  'Content-Type: text/html; charset=windows-1252' ||
                  utl_tcp.CRLF || utl_tcp.CRLF || gv_corps;
    END IF;



        utl_smtp.write_data(l_conn, l_mesg);

        utl_smtp.close_data(l_conn);
        utl_smtp.quit(l_conn);
        g_step := 'ENVOI_MAIL_ADRESS_CLIENT_ABS 005 ==> Mail Avis de Virement envoye a adresse : <Cellules clients DKA/VE>; CHECK_NUMBER : ' ||
                  pv_check_number || '; MONTANT : ' || pv_montant ||
                  '; CLIENT : ' || Pv_client || '; SITE CLIENT : ' ||
                  Pv_SiteClient;
        log_msg(g_step);
        out_msg('==> Mail Avis de Virement (adresse client absente) envoye a : <Cellules clients DKA/VE>; CHECK_NUMBER : ' ||
                pv_check_number || '; MONTANT : ' || pv_montant ||
                '; CLIENT : ' || Pv_client || '; SITE CLIENT : ' ||
                Pv_SiteClient);
        g_step := 'ENVOI_MAIL_ADRESS_CLIENT_ABS 999 : FIN';
        log_msg(g_step);
    EXCEPTION
        WHEN OTHERS THEN
            Pn_Retcode := 1;
            Pv_Errbuf  := 'Erreur procedure ENVOI_MAIL_ADRESS_CLIENT_ABS :' ||
                          g_step || chr(10) || SQLERRM;
            log_msg(Pv_Errbuf);
            out_msg('==> Erreur lors de l''envoi par mail  (adresse CLIENT absente) du règlement numéro : ' ||
                    pv_check_number);
            log_msg('==> Erreur lors de l''envoi par mail du règlement numéro : ' ||
                    pv_check_number);
            utl_smtp.close_data(l_conn);
            utl_smtp.quit(l_conn);
    END ENVOI_MAIL_ADRESS_CLIENT_ABS;


    -------------------------------------------------------------------------------------
    --  Nom           : envoi_mail_adress_four_abs
    --  Description   : Envoi du mail d'avertissement:
    --         Adresse du site fournisseur inexistante.
    --
    --  PARAMETRES    :
    --  Pn_Check      IN      Numéro du règlement
    --  Pv_Four       IN      Nom Fournisseur
    --  Pv_SiteFour   IN      Nom du site fournisseur
    --  Pv_Errbuf     IN OUT      Message d'avertissement
    --  Pn_Retcode    IN OUT      Code erreur
    --------------------------------------------------------------------------------------
    PROCEDURE envoi_mail_adress_four_abs(pv_check_number IN ap_checks_all.CHECK_NUMBER%TYPE,
                                         pv_montant      IN VARCHAR2,
                                         Pv_Four         IN PO_VENDORS.VENDOR_NAME%TYPE,
                                         Pv_SiteFour     IN PO_VENDOR_SITES_ALL.VENDOR_SITE_CODE%TYPE,
                                         Pv_Errbuf       IN OUT VARCHAR2,
                                         Pn_Retcode      IN OUT NUMBER) IS
        l_mesg   VARCHAR2(4000);
        l_conn   UTL_SMTP.CONNECTION;
        vr_reply UTL_SMTP.REPLY;
    BEGIN
        g_step := 'ENVOI_MAIL_ADRESS_FOUR_ABS 000 : DEBUT';
        log_msg(g_step);
        g_step := 'ENVOI_MAIL_ADRESS_FOUR_ABS 001 : RECHERCHE DE L''OBJET DU MAIL.';
        log_msg(g_step);
        gv_objet := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_SAPAUTOVIR_FOURABSOBJ',
                                              'NOM_FOUR',
                                              Pv_Four);

        g_step := 'ENVOI_MAIL_ADRESS_FOUR_ABS 002 : RECHERCHE DU CORPS DU MAIL.';
        log_msg(g_step);
        gv_corps := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_SAPAUTOVIR_FOURABSCOR',
                                              'NOM_FOUR',
                                              Pv_four,
                                              'NOM_SITEFOUR',
                                              Pv_SiteFour);

        g_step := 'ENVOI_MAIL_ADRESS_FOUR_ABS 003 : CONNEXION.';
        log_msg(g_step);
        l_conn := utl_smtp.open_connection(gv_conn, 25);

        g_step := 'ENVOI_MAIL_ADRESS_FOUR_ABS 004 : DEBUT CONSTRUCTION MAIL.';
        log_msg(g_step);
        utl_smtp.helo(l_conn, gv_conn);

        vr_reply := utl_smtp.mail(l_conn, '<' || gv_expediteur || '>');
        g_step   := 'REPLY MAIL : ' || vr_reply.code || ' - ' ||
                    vr_reply.text;

        vr_reply := utl_smtp.rcpt(l_conn, '<' || nvl(gv_mail_test,gv_plat_appro_mail) || '>');--YWA artf2120398

        g_step   := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                    vr_reply.text;
        utl_smtp.open_data(l_conn);
        l_mesg := 'Date: ' ||
                  to_char(systimestamp,
                          'dd Mon yyyy hh24:mi:ss tzhtzm',
                          'NLS_DATE_LANGUAGE=American') || utl_tcp.CRLF ||
                  'From: <' || gv_expediteur || '>' || utl_tcp.CRLF ||
                  'To: <' || gv_plat_appro_mail || '>' || utl_tcp.CRLF ||
                  'Subject:' || gv_objet || utl_tcp.CRLF ||
                  'Content-Type: text/html; charset=windows-1252' ||
                  utl_tcp.CRLF || utl_tcp.CRLF || gv_corps;
        utl_smtp.write_data(l_conn, l_mesg);

        utl_smtp.close_data(l_conn);
        utl_smtp.quit(l_conn);
        g_step := 'ENVOI_MAIL_ADRESS_FOUR_ABS 005 ==> Mail Avis de Virement envoye a adresse : <' ||
                  gv_plat_appro_mail || '>; CHECK_NUMBER : ' ||
                  pv_check_number || '; MONTANT : ' || pv_montant ||
                  '; FOURNISSEUR : ' || Pv_Four || '; SITE FOURNISSEUR : ' ||
                  Pv_SiteFour;
        log_msg(g_step);
        out_msg('==> Mail Avis de Virement (adresse fournisseur absente) envoye a : <' ||
                gv_plat_appro_name || '>; CHECK_NUMBER : ' ||
                pv_check_number || '; MONTANT : ' || pv_montant ||
                '; FOURNISSEUR : ' || Pv_Four || '; SITE FOURNISSEUR : ' ||
                Pv_SiteFour);
        g_step := 'ENVOI_MAIL_ADRESS_FOUR_ABS 999 : FIN';
        log_msg(g_step);
    EXCEPTION
        WHEN OTHERS THEN
            Pn_Retcode := 1;
            Pv_Errbuf  := 'Erreur procedure Envoi_mail_adress_four_abs :' ||
                          g_step || chr(10) || SQLERRM;
            log_msg(Pv_Errbuf);
            out_msg('==> Erreur lors de l''envoi par mail  (adresse fournisseur absente) du règlement numéro : ' ||
                    pv_check_number);
            log_msg('==> Erreur lors de l''envoi par mail du règlement numéro : ' ||
                    pv_check_number);
            utl_smtp.close_data(l_conn);
            utl_smtp.quit(l_conn);
    END envoi_mail_adress_four_abs;

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

    -----------------------------------------------------------------
    --  Nom           : SEND_MAIL_REF
    --  Description   : procedure d'envoi de mail à la plateforme
    --                  d'appro pour information
    --
    --  PARAMETRES :
    --
    --
    -----------------------------------------------------------------
    /*PROCEDURE send_mail_ref(pv_check_number     IN ap_checks_all.CHECK_NUMBER%TYPE,
              pv_montant          IN VARCHAR2,
                            pv_vendor_name      IN PO_VENDORS.VENDOR_NAME%TYPE,
                            pv_vendor_site_code IN PO_VENDOR_SITES_ALL.VENDOR_SITE_CODE%TYPE,
                            pv_errbuf           OUT VARCHAR2,
                            pn_retcode          OUT NUMBER) IS

        l_conn UTL_SMTP.CONNECTION;
        l_mesg VARCHAR2(4000);

        vr_reply UTL_SMTP.REPLY;

        vv_subject VARCHAR2(500);
        vv_body    VARCHAR2(500);

    BEGIN
        g_step := 'SEND_MAIL_REF 000 : DEBUT';
        log_msg(g_step);

        --CONSTRUCTION DES MESSAGES
        --SUJET
        g_step := 'SEND_MAIL_REF 001 : Définition du sujet';

        vv_subject := Dka_Tools_Pkg.get_message('DKA',
                                                'DKA_SAPAUTOVIR_FOURINOBJ',
                                                'NOM_FOUR',
                                                pv_vendor_name);

        g_step  := 'SEND_MAIL_REF 002 : Définition du sujet';
        vv_body := Dka_Tools_Pkg.get_message('DKA',
                                             'DKA_SAPAUTOVIR_FOURINCOR',
                                             'NOM_FOUR',
                                             pv_vendor_name,
                                             'NOM_SITEFOUR',
                                             pv_vendor_site_code);

        g_step := 'SEND_MAIL_REF 003 : Connexion';
        log_msg(g_step);
        vr_reply := utl_smtp.open_connection(gv_conn, 25, l_conn);
        utl_smtp.ehlo(l_conn, gv_conn);
        vr_reply := utl_smtp.mail(l_conn, '<' || gv_expediteur || '>');
        vr_reply := utl_smtp.rcpt(l_conn, '<' || gv_plat_appro_mail || '>');

        g_step := 'SEND_MAIL_REF 004 : Ouverture/Ecriture des datas';
        log_msg(g_step);
        utl_smtp.open_data(l_conn);
        l_mesg := 'Date: ' ||
                  to_char(systimestamp,
                          'dd Mon yyyy hh24:mi:ss tzhtzm',
                          'NLS_DATE_LANGUAGE=American') || utl_tcp.CRLF ||
                  'From: <' || gv_expediteur || '>' || utl_tcp.CRLF ||
                  'To: <' || gv_plat_appro_mail || '>' || utl_tcp.CRLF ||
                  'Subject: ' || vv_subject || utl_tcp.CRLF ||
                  'MIME-Version: 1.0' || utl_tcp.CRLF || 'Content-Type: ' ||
                  MULTIPART_MIME_TYPE || utl_tcp.CRLF || utl_tcp.CRLF;

        utl_smtp.write_data(l_conn, l_mesg);

        -- Insertion du corps du message
        g_step := 'SEND_MAIL_REF 005 : Insertion du corps du message';
        log_msg(g_step);
        BEGIN
            begin_attachment(conn => l_conn, mime_type => 'text/html');
            utl_smtp.write_data(l_conn, vv_body);
            end_attachment(conn => l_conn);
        END;

        g_step := 'SEND_MAIL_REF 006 : Fermeture des attachements';
        log_msg(g_step);
        end_attachment(conn => l_conn, last => TRUE);

        --Envoi du mail
        g_step := 'SEND_MAIL_REF 007 : Envoi du mail';
        log_msg(g_step);
        vr_reply := utl_smtp.close_data(l_conn);
        vr_reply := utl_smtp.quit(l_conn);
        out_msg('==> Mail Avis de Virement envoye a : <' ||
                gv_plat_appro_name || '>; CHECK_NUMBER : ' ||
          pv_check_number || '; MONTANT : ' ||
          pv_montant || '; FOURNISSEUR : ' ||
          pv_vendor_name || '; SITE FOURNISSEUR : ' ||
          pv_vendor_site_code);
        g_step := 'SEND_MAIL_REF 999 : FIN';
        log_msg(g_step);

    EXCEPTION
        WHEN OTHERS THEN
            g_step := 'REPLY : ' || vr_reply.code || ' - ' ||
                      vr_reply.text;
            log_msg(g_step);
            out_msg('==> Erreur lors de l''envoi par mail (anvoi plateforme d''approbation) du règlement numéro : ' ||
                    pv_check_number);
            log_msg('==> Erreur lors de l''envoi par mail du règlement numéro : ' ||
                    pv_check_number);
            vr_reply := utl_smtp.close_data(l_conn);
            vr_reply := utl_smtp.quit(l_conn);
            g_step   := 'Erreur procedure SEND_MAIL_REF :' || g_step ||
                        chr(10) || SQLERRM;
            log_msg(g_step);
            pv_errbuf  := g_step;
            pn_retcode := 1;
    END send_mail_ref;*/

-- ARA EDB295

-------------------------------------------------------------------------------------
    --  Nom           : ENVOI_MAIL_CLIENT
    --  Description   : Procédure d'envoi par Mail.
    --
    --  PARAMETRES    :
    --  pv_check_number IN   Numéro du règlement.
    --  pd_date_vir     IN      Date de virement.
    --  pv_iban_number    IN    Numéro IBAN
    --  pv_montant      IN    Montant du virement.
    --  pv_societe      IN    Société
    --  pv_motif      IN    Motif du virement
    --  pv_nom_fichier    IN    Nom du fichier de virement
    --  pv_client_name    IN    Nom du fournisseur
    --  pv_vendor_site_code  IN    Nom du site fournisseur
    --  pv_adresse_mail    IN    Email du destinataire
    --  pv_errbuf         IN OUT  Message de sortie
    --  pn_retcode        OUT     Code retour
    --  VALEUR RETOURNEE :  pn_retcode
    --Valeurs possibles : 0=normal, 1=warning, 2=erreur
    ------------------------------------------------------------------------------------
    PROCEDURE envoi_mail_client(pv_check_number     IN ap_checks_all.CHECK_NUMBER%TYPE,
                         pd_date_vir         IN AP_CHECKS_ALL.CHECK_DATE%TYPE,
                         pv_iban_number      IN AP_CHECKS_ALL.IBAN_NUMBER%TYPE,
                         pv_montant          IN VARCHAR2,
                         pv_societe          IN HR_LOCATIONS_ALL.DESCRIPTION%TYPE,
                         pv_motif            IN VARCHAR2,
                         pv_nom_fichier      IN VARCHAR2,
                         pv_client_name      IN AR_CUSTOMERS.CUSTOMER_NAME%TYPE,
                         pv_client_site_code IN hz_party_sites.party_site_number%TYPE,
                         pv_adresse_mail     IN VARCHAR2,
                         pv_errbuf           OUT VARCHAR2,
                         pn_retcode          OUT NUMBER) IS

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
        vr_replies UTL_SMTP.REPLIES;

        e_adresse_fournisseur EXCEPTION;
        e_piece_jointe EXCEPTION;
    BEGIN
        -- Init des variables de sortie.
        pn_retcode := 0;
        pv_errbuf  := '';

        g_step := 'ENVOI_MAIL_CLIENT 000 - DEBUT.';
        log_msg(g_step);

        g_step := 'ENVOI_MAIL_CLIENT 001 - RECUPERATION DES MESSAGES.';
        log_msg(g_step);

        -- Recherche de l'entête du message :
        gv_subject := Dka_Tools_Pkg.get_message('DKA',
                                                'DKA_SAPAUTOVIR_PDFOBJ');

        -- Recherche du corp du message :
        gv_body := Dka_Tools_Pkg.get_message('DKA',
                                             'DKA_SAPAUTOVIR_PDFCOR',
                                             'DATE_VIR',
                                             pd_date_vir,
                                             'SOCIETE',
                                             pv_societe,
                                             'IBAN',
                                             pv_iban_number,
                                             'MONTANT',
                                             pv_montant,
                                             'MOTIF',
                                             pv_motif);
        IF gv_subject IS NOT NULL AND gv_body IS NOT NULL THEN
            g_step := 'ENVOI_MAIL_CLIENT 002 - CONNEXION.';
            log_msg(g_step);
            vr_reply := utl_smtp.open_connection(gv_conn, 25, l_conn);
            g_step   := 'REPLY OPEN_CONNECTION : ' || vr_reply.code ||
                        ' - ' || vr_reply.text;

            g_step := 'ENVOI_MAIL_CLIENT 003 : Début construction mail';
            log_msg(g_step);
            vr_replies := utl_smtp.ehlo(l_conn, gv_conn);
            IF vr_replies.COUNT > 0 THEN
                FOR i IN vr_replies.FIRST .. vr_replies.LAST LOOP
                    g_step := 'REPLY EHLO ' || i || ' : ' || vr_replies(i)
                             .code || ' - ' || vr_replies(i).text; --log_msg(g_step);
                END LOOP;
            END IF;
            vr_reply := utl_smtp.mail(l_conn,
                                      '<' || gv_expediteur || '>' /*gv_expediteur*/);
            g_step   := 'REPLY MAIL : ' || vr_reply.code || ' - ' ||
                        vr_reply.text; --log_msg(g_step);

            vr_reply := utl_smtp.rcpt(l_conn,
                                      '<' || pv_adresse_mail || '>');-- YWA artf2120398

            g_step   := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                        vr_reply.text;
            log_msg(g_step);

            IF vr_reply.code != '250' THEN
                raise e_adresse_fournisseur;
            END IF;

            vr_reply := utl_smtp.open_data(l_conn);
            g_step   := 'REPLY OPEN_DATA : ' || vr_reply.code || ' - ' ||
                        vr_reply.text; --log_msg(g_step);

            l_mesg := 'Date: ' ||
                      to_char(systimestamp,
                              'dd Mon yyyy hh24:mi:ss tzhtzm',
                              'NLS_DATE_LANGUAGE=American') ||
                      utl_tcp.CRLF || 'From: <' || gv_expediteur || '>' ||  utl_tcp.CRLF
            || 'To: <' || pv_adresse_mail || '>' || utl_tcp.CRLF
            || 'MIME-Version: 1.0' || utl_tcp.CRLF
            || 'Subject:' ||
                      gv_subject || utl_tcp.CRLF || 'Content-Type: ' ||
                      MULTIPART_MIME_TYPE || utl_tcp.CRLF || utl_tcp.CRLF;


            utl_smtp.write_data(l_conn, l_mesg);

            g_step := 'ENVOI_MAIL_CLIENT 004 - INSERTION DU CORPS DU MESSAGE.';
            log_msg(g_step);
            log_msg(g_step);
            -- Insertion du corps du message
            BEGIN
                begin_attachment(conn => l_conn, mime_type => 'text/html');
                utl_smtp.write_data(l_conn, gv_body || utl_tcp.CRLF);
                end_attachment(conn => l_conn);

            END;

            IF pv_nom_fichier IS NOT NULL THEN
                gn_amt := 672 * 3;
                g_step := 'ENVOI_MAIL_CLIENT 005 - ATTACHEMENT DE LA PIECE JOINTE.';
                log_msg(g_step);
                -- Insertion pièce jointe
                BEGIN
                    begin_attachment(conn         => l_conn,
                                     mime_type    => gv_type_attachment,
                                     inline       => TRUE,
                                     filename     => pv_nom_fichier,
                                     transfer_enc => 'base64');

                    BEGIN
                        l_file     := BFILENAME('DKA_TMPAVR',
                                                pv_nom_fichier);
                        l_file_len := dbms_lob.getlength(l_file);
                        l_modulo   := mod(l_file_len, gn_amt);
                        l_pieces   := trunc(l_file_len / gn_amt);

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

                            dbms_lob.read(l_file,
                                          gn_amt,
                                          l_filepos,
                                          l_buf);
                        END LOOP;
                    END;
                    dbms_lob.fileclose(l_file);

                    end_attachment(conn => l_conn);
                EXCEPTION
                    WHEN OTHERS THEN
                        RAISE e_piece_jointe;
                END; -- Fin de l'insertion de la pièce jointe
            END IF;

            utl_smtp.close_data(l_conn);
            utl_smtp.quit(l_conn);

            out_msg('==> Mail Avis de Virement envoye a : <' ||
                    pv_adresse_mail || '>; CHECK_NUMBER : ' ||
                    pv_check_number || '; MONTANT : ' || pv_montant ||
                    '; CLIENT : ' || pv_client_name ||
                    '; SITE CLIENT : ' || pv_client_site_code);
        END IF;
        g_step := 'ENVOI_MAIL_CLIENT 999 - FIN.';
        log_msg(g_step);
    EXCEPTION
        WHEN e_piece_jointe THEN
            g_step := 'ENVOI_MAIL_CLIENT EE2 : Erreur rattachement pièce jointe' ||
                      SQLERRM;
            log_msg(pv_errbuf);
            out_msg('==> Erreur lors de l''envoi par mail du règlement numéro CHECK_NUMBER : ' ||
                    pv_check_number || '; MONTANT : ' || pv_montant ||
                    '; CLIENT : ' || pv_client_name ||
                    '; SITE CLIENT : ' || pv_client_site_code);
            log_msg('==> Erreur lors de l''envoi par mail du règlement numéro CHECK_NUMBER : ' ||
                    pv_check_number || '; MONTANT : ' || pv_montant ||
                    '; CLIENT : ' || pv_client_name ||
                    '; SITE CLIENT : ' || pv_client_site_code);
            utl_smtp.close_data(l_conn);
            utl_smtp.quit(l_conn);
            pn_retcode := 1;
        WHEN e_adresse_fournisseur THEN
            g_step := 'ENVOI_MAIL_CLIENT EE1 : Erreur adresse client';
            log_msg(g_step);

       /*     BEGIN
                g_step := 'SEND_MAIL_REF 000 : DEBUT';
                log_msg(g_step);

                --CONSTRUCTION DES MESSAGES
                --SUJET
                g_step := 'SEND_MAIL_REF 001 : Définition du sujet';

                gv_subject := Dka_Tools_Pkg.get_message('DKA',
                                                        'DKA_SAPAUTOVIR_CLIINOBJ',
                                                        'NOM_CLI',
                                                        pv_client_name);

                g_step  := 'SEND_MAIL_REF 002 : Définition du sujet';
                gv_body := Dka_Tools_Pkg.get_message('DKA',
                                                     'DKA_SAPAUTOVIR_CLIINCOR',
                                                     'NOM_CLI',
                                                     pv_client_name,
                                                     'NOM_SITECLI',
                                                     pv_client_site_code);

                g_step := 'SEND_MAIL_REF 003 : Connexion';
                log_msg(g_step);
                vr_reply := utl_smtp.rcpt(l_conn,
                                          '<' || nvl(gv_mail_test,gv_plat_appro_mail) || '>');--YWA artf2120398

                g_step := 'SEND_MAIL_REF 004 : Ouverture/Ecriture des datas';
                log_msg(g_step);
                utl_smtp.open_data(l_conn);
                l_mesg := 'Date: ' ||
                          to_char(systimestamp,
                                  'dd Mon yyyy hh24:mi:ss tzhtzm',
                                  'NLS_DATE_LANGUAGE=American') ||
                          utl_tcp.CRLF || 'From: <' || gv_expediteur || '>' ||
                          utl_tcp.CRLF || 'To: <' || gv_plat_appro_mail || '>' ||
                          utl_tcp.CRLF || 'Subject: ' || gv_subject ||
                          utl_tcp.CRLF || 'MIME-Version: 1.0' ||
                          utl_tcp.CRLF || 'Content-Type: ' ||
                          MULTIPART_MIME_TYPE || utl_tcp.CRLF ||
                          utl_tcp.CRLF;

                utl_smtp.write_data(l_conn, l_mesg);

                -- Insertion du corps du message
                g_step := 'SEND_MAIL_REF 005 : Insertion du corps du message';
                log_msg(g_step);
                BEGIN
                    begin_attachment(conn      => l_conn,
                                     mime_type => 'text/html');
                    utl_smtp.write_data(l_conn, gv_body);
                    end_attachment(conn => l_conn);
                END;

                g_step := 'SEND_MAIL_REF 006 : Fermeture des attachements';
                log_msg(g_step);
                end_attachment(conn => l_conn, last => TRUE);

                --Envoi du mail
                g_step := 'SEND_MAIL_REF 007 : Envoi du mail';
                log_msg(g_step);
                vr_reply := utl_smtp.close_data(l_conn);
                vr_reply := utl_smtp.quit(l_conn);
                out_msg('==> Mail Avis de Virement envoye a : <' ||
                        gv_plat_appro_name || '>; CHECK_NUMBER : ' ||
                        pv_check_number || '; MONTANT : ' || pv_montant ||
                        '; CLIENT : ' || pv_client_name ||
                        '; SITE CLIENT : ' || pv_client_site_code);
                g_step := 'SEND_MAIL_REF 999 : FIN';
                log_msg(g_step);

            EXCEPTION
                WHEN OTHERS THEN
                    g_step := 'REPLY : ' || vr_reply.code || ' - ' ||
                              vr_reply.text;
                    log_msg(g_step);
                    out_msg('==> Erreur lors de l''envoi par mail (Envoi plateforme d''approbation) du règlement numéro : ' ||
                            pv_check_number);
                    log_msg('==> Erreur lors de l''envoi par mail du règlement numéro : ' ||
                            pv_check_number);
                    vr_reply := utl_smtp.close_data(l_conn);
                    vr_reply := utl_smtp.quit(l_conn);
                    g_step   := 'Erreur procedure SEND_MAIL_REF :' ||
                                g_step || chr(10) || SQLERRM;
                    log_msg(g_step);
                    pv_errbuf  := g_step;
                    pn_retcode := 1;
            END;*/
            pn_retcode := 1;
        WHEN OTHERS THEN
            pv_errbuf := 'Erreur procedure ENVOI_MAIL_CLIENT ' || SQLERRM;
            log_msg(pv_errbuf);
            out_msg('==> Erreur lors de l''envoi par mail du règlement numéro CHECK_NUMBER : ' ||
                    pv_check_number || '; MONTANT : ' || pv_montant ||
                    '; CLIENT : ' || pv_client_name ||
                    '; SITE CLIENT : ' || pv_client_site_code);
            log_msg('==> Erreur lors de l''envoi par mail du règlement numéro CHECK_NUMBER : ' ||
                    pv_check_number || '; MONTANT : ' || pv_montant ||
                    '; CLIENT : ' || pv_client_name ||
                    '; SITE CLIENT : ' || pv_client_site_code);
            utl_smtp.close_data(l_conn);
            utl_smtp.quit(l_conn);
            pn_retcode := 1;
    END ENVOI_MAIL_CLIENT;






    -------------------------------------------------------------------------------------
    --  Nom           : ENVOI_MAIL
    --  Description   : Procédure d'envoi par Mail.
    --
    --  PARAMETRES    :
    --  pv_check_number IN   Numéro du règlement.
    --  pd_date_vir     IN      Date de virement.
    --  pv_iban_number    IN    Numéro IBAN
    --  pv_montant      IN    Montant du virement.
    --  pv_societe      IN    Société
    --  pv_motif      IN    Motif du virement
    --  pv_nom_fichier    IN    Nom du fichier de virement
    --  pv_vendor_name    IN    Nom du fournisseur
    --  pv_vendor_site_code  IN    Nom du site fournisseur
    --  pv_adresse_mail    IN    Email du destinataire
    --  pv_errbuf         IN OUT  Message de sortie
    --  pn_retcode        OUT     Code retour
    --  VALEUR RETOURNEE :  pn_retcode
    --Valeurs possibles : 0=normal, 1=warning, 2=erreur
    ------------------------------------------------------------------------------------
    PROCEDURE envoi_mail(pv_check_number     IN ap_checks_all.CHECK_NUMBER%TYPE,
                         pd_date_vir         IN AP_CHECKS_ALL.CHECK_DATE%TYPE,
                         pv_iban_number      IN AP_CHECKS_ALL.IBAN_NUMBER%TYPE,
                         pv_montant          IN VARCHAR2,
                         pv_societe          IN HR_LOCATIONS_ALL.DESCRIPTION%TYPE,
                         pv_motif            IN VARCHAR2,
                         pv_nom_fichier      IN VARCHAR2,
                         pv_vendor_name      IN PO_VENDORS.VENDOR_NAME%TYPE,
                         pv_vendor_site_code IN PO_VENDOR_SITES_ALL.VENDOR_SITE_CODE%TYPE,
                         pv_adresse_mail     IN PO_VENDOR_SITES_ALL.EMAIL_ADDRESS%TYPE,
                         pv_errbuf           OUT VARCHAR2,
                         pn_retcode          OUT NUMBER) IS

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
        vr_replies UTL_SMTP.REPLIES;

        e_adresse_fournisseur EXCEPTION;
        e_piece_jointe EXCEPTION;
    BEGIN
        -- Init des variables de sortie.
        pn_retcode := 0;
        pv_errbuf  := '';

        g_step := 'ENVOI_MAIL 000 - DEBUT.';
        log_msg(g_step);

        g_step := 'ENVOI_MAIL 001 - RECUPERATION DES MESSAGES.';
        log_msg(g_step);

        -- Recherche de l'entête du message :
        gv_subject := Dka_Tools_Pkg.get_message('DKA',
                                                'DKA_SAPAUTOVIR_PDFOBJ');

        -- Recherche du corp du message :
        gv_body := Dka_Tools_Pkg.get_message('DKA',
                                             'DKA_SAPAUTOVIR_PDFCOR',
                                             'DATE_VIR',
                                             pd_date_vir,
                                             'SOCIETE',
                                             pv_societe,
                                             'IBAN',
                                             pv_iban_number,
                                             'MONTANT',
                                             pv_montant,
                                             'MOTIF',
                                             pv_motif);
        IF gv_subject IS NOT NULL AND gv_body IS NOT NULL THEN
            g_step := 'ENVOI_MAIL 002 - CONNEXION.';
            log_msg(g_step);
            vr_reply := utl_smtp.open_connection(gv_conn, 25, l_conn);
            g_step   := 'REPLY OPEN_CONNECTION : ' || vr_reply.code ||
                        ' - ' || vr_reply.text;

            g_step := 'ENVOI_MAIL 003 : Début construction mail';
            log_msg(g_step);
            vr_replies := utl_smtp.ehlo(l_conn, gv_conn);
            IF vr_replies.COUNT > 0 THEN
                FOR i IN vr_replies.FIRST .. vr_replies.LAST LOOP
                    g_step := 'REPLY EHLO ' || i || ' : ' || vr_replies(i)
                             .code || ' - ' || vr_replies(i).text; --log_msg(g_step);
                END LOOP;
            END IF;
            vr_reply := utl_smtp.mail(l_conn,
                                      '<' || gv_expediteur || '>' /*gv_expediteur*/);
            g_step   := 'REPLY MAIL : ' || vr_reply.code || ' - ' ||
                        vr_reply.text; --log_msg(g_step);

            vr_reply := utl_smtp.rcpt(l_conn,
                                      '<' || nvl(gv_mail_test,pv_adresse_mail) || '>');-- YWA artf2120398

            g_step   := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                        vr_reply.text;
            log_msg(g_step);

            IF vr_reply.code != '250' THEN
                raise e_adresse_fournisseur;
            END IF;

            vr_reply := utl_smtp.open_data(l_conn);
            g_step   := 'REPLY OPEN_DATA : ' || vr_reply.code || ' - ' ||
                        vr_reply.text; --log_msg(g_step);

            l_mesg := 'Date: ' ||
                      to_char(systimestamp,
                              'dd Mon yyyy hh24:mi:ss tzhtzm',
                              'NLS_DATE_LANGUAGE=American') ||
                      utl_tcp.CRLF || 'From: <' || gv_expediteur || '>' ||
                      utl_tcp.CRLF || 'To: <' || pv_adresse_mail || '>' ||
                      utl_tcp.CRLF || 'Reply-To: <' || gv_plat_appro_mail || '>' ||
                      utl_tcp.CRLF || 'Return-Path: ' ||
                      gv_plat_appro_mail || utl_tcp.CRLF ||
                      'MIME-Version: 1.0' || utl_tcp.CRLF || 'Subject:' ||
                      gv_subject || utl_tcp.CRLF || 'Content-Type: ' ||
                      MULTIPART_MIME_TYPE || utl_tcp.CRLF || utl_tcp.CRLF;

            utl_smtp.write_data(l_conn, l_mesg);

            g_step := 'ENVOI_MAIL 004 - INSERTION DU CORPS DU MESSAGE.';
            log_msg(g_step);
            log_msg(g_step);
            -- Insertion du corps du message
            BEGIN
                begin_attachment(conn => l_conn, mime_type => 'text/html');
                utl_smtp.write_data(l_conn, gv_body || utl_tcp.CRLF);
                end_attachment(conn => l_conn);

            END;

            IF pv_nom_fichier IS NOT NULL THEN
                gn_amt := 672 * 3;
                g_step := 'ENVOI_MAIL 005 - ATTACHEMENT DE LA PIECE JOINTE.';
                log_msg(g_step);
                -- Insertion pièce jointe
                BEGIN
                    begin_attachment(conn         => l_conn,
                                     mime_type    => gv_type_attachment,
                                     inline       => TRUE,
                                     filename     => pv_nom_fichier,
                                     transfer_enc => 'base64');

                    BEGIN
                        l_file     := BFILENAME('DKA_TMPAVR',
                                                pv_nom_fichier);
                        l_file_len := dbms_lob.getlength(l_file);
                        l_modulo   := mod(l_file_len, gn_amt);
                        l_pieces   := trunc(l_file_len / gn_amt);

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

                            dbms_lob.read(l_file,
                                          gn_amt,
                                          l_filepos,
                                          l_buf);
                        END LOOP;
                    END;
                    dbms_lob.fileclose(l_file);

                    end_attachment(conn => l_conn);
                EXCEPTION
                    WHEN OTHERS THEN
                        RAISE e_piece_jointe;
                END; -- Fin de l'insertion de la pièce jointe
            END IF;

            utl_smtp.close_data(l_conn);
            utl_smtp.quit(l_conn);

            out_msg('==> Mail Avis de Virement envoye a : <' ||
                    pv_adresse_mail || '>; CHECK_NUMBER : ' ||
                    pv_check_number || '; MONTANT : ' || pv_montant ||
                    '; FOURNISSEUR : ' || pv_vendor_name ||
                    '; SITE FOURNISSEUR : ' || pv_vendor_site_code);
        END IF;
        g_step := 'ENVOI_MAIL 999 - FIN.';
        log_msg(g_step);
    EXCEPTION
        WHEN e_piece_jointe THEN
            g_step := 'ENVOI_MAIL EE2 : Erreur rattachement pièce jointe' ||
                      SQLERRM;
            log_msg(pv_errbuf);
            out_msg('==> Erreur lors de l''envoi par mail du règlement numéro CHECK_NUMBER : ' ||
                    pv_check_number || '; MONTANT : ' || pv_montant ||
                    '; FOURNISSEUR : ' || pv_vendor_name ||
                    '; SITE FOURNISSEUR : ' || pv_vendor_site_code);
            log_msg('==> Erreur lors de l''envoi par mail du règlement numéro CHECK_NUMBER : ' ||
                    pv_check_number || '; MONTANT : ' || pv_montant ||
                    '; FOURNISSEUR : ' || pv_vendor_name ||
                    '; SITE FOURNISSEUR : ' || pv_vendor_site_code);
            utl_smtp.close_data(l_conn);
            utl_smtp.quit(l_conn);
            pn_retcode := 1;
        WHEN e_adresse_fournisseur THEN
            g_step := 'ENVOI_MAIL EE1 : Erreur adresse fournisseur';
            log_msg(g_step);
            -- INC000000521658 - Envoi d'un mail dans le cas ou l'adresse mail est incorrecte.
            --send_mail_ref(pv_check_number,
            --        pv_montant,
            --              pv_vendor_name,
            --              pv_vendor_site_code,
            --              pv_errbuf,
            --              pn_retcode);

            BEGIN
                g_step := 'SEND_MAIL_REF 000 : DEBUT';
                log_msg(g_step);

                --CONSTRUCTION DES MESSAGES
                --SUJET
                g_step := 'SEND_MAIL_REF 001 : Définition du sujet';

                gv_subject := Dka_Tools_Pkg.get_message('DKA',
                                                        'DKA_SAPAUTOVIR_FOURINOBJ',
                                                        'NOM_FOUR',
                                                        pv_vendor_name);

                g_step  := 'SEND_MAIL_REF 002 : Définition du sujet';
                gv_body := Dka_Tools_Pkg.get_message('DKA',
                                                     'DKA_SAPAUTOVIR_FOURINCOR',
                                                     'NOM_FOUR',
                                                     pv_vendor_name,
                                                     'NOM_SITEFOUR',
                                                     pv_vendor_site_code);

                g_step := 'SEND_MAIL_REF 003 : Connexion';
                log_msg(g_step);
                vr_reply := utl_smtp.rcpt(l_conn,
                                          '<' || nvl(gv_mail_test,gv_plat_appro_mail) || '>');--YWA artf2120398

                g_step := 'SEND_MAIL_REF 004 : Ouverture/Ecriture des datas';
                log_msg(g_step);
                utl_smtp.open_data(l_conn);
                l_mesg := 'Date: ' ||
                          to_char(systimestamp,
                                  'dd Mon yyyy hh24:mi:ss tzhtzm',
                                  'NLS_DATE_LANGUAGE=American') ||
                          utl_tcp.CRLF || 'From: <' || gv_expediteur || '>' ||
                          utl_tcp.CRLF || 'To: <' || gv_plat_appro_mail || '>' ||
                          utl_tcp.CRLF || 'Subject: ' || gv_subject ||
                          utl_tcp.CRLF || 'MIME-Version: 1.0' ||
                          utl_tcp.CRLF || 'Content-Type: ' ||
                          MULTIPART_MIME_TYPE || utl_tcp.CRLF ||
                          utl_tcp.CRLF;

                utl_smtp.write_data(l_conn, l_mesg);

                -- Insertion du corps du message
                g_step := 'SEND_MAIL_REF 005 : Insertion du corps du message';
                log_msg(g_step);
                BEGIN
                    begin_attachment(conn      => l_conn,
                                     mime_type => 'text/html');
                    utl_smtp.write_data(l_conn, gv_body);
                    end_attachment(conn => l_conn);
                END;

                g_step := 'SEND_MAIL_REF 006 : Fermeture des attachements';
                log_msg(g_step);
                end_attachment(conn => l_conn, last => TRUE);

                --Envoi du mail
                g_step := 'SEND_MAIL_REF 007 : Envoi du mail';
                log_msg(g_step);
                vr_reply := utl_smtp.close_data(l_conn);
                vr_reply := utl_smtp.quit(l_conn);
                out_msg('==> Mail Avis de Virement envoye a : <' ||
                        gv_plat_appro_name || '>; CHECK_NUMBER : ' ||
                        pv_check_number || '; MONTANT : ' || pv_montant ||
                        '; FOURNISSEUR : ' || pv_vendor_name ||
                        '; SITE FOURNISSEUR : ' || pv_vendor_site_code);
                g_step := 'SEND_MAIL_REF 999 : FIN';
                log_msg(g_step);

            EXCEPTION
                WHEN OTHERS THEN
                    g_step := 'REPLY : ' || vr_reply.code || ' - ' ||
                              vr_reply.text;
                    log_msg(g_step);
                    out_msg('==> Erreur lors de l''envoi par mail (anvoi plateforme d''approbation) du règlement numéro : ' ||
                            pv_check_number);
                    log_msg('==> Erreur lors de l''envoi par mail du règlement numéro : ' ||
                            pv_check_number);
                    vr_reply := utl_smtp.close_data(l_conn);
                    vr_reply := utl_smtp.quit(l_conn);
                    g_step   := 'Erreur procedure SEND_MAIL_REF :' ||
                                g_step || chr(10) || SQLERRM;
                    log_msg(g_step);
                    pv_errbuf  := g_step;
                    pn_retcode := 1;
            END;
            pn_retcode := 1;
        WHEN OTHERS THEN
            pv_errbuf := 'Erreur procedure ENVOI_MAIL ' || SQLERRM;
            log_msg(pv_errbuf);
            out_msg('==> Erreur lors de l''envoi par mail du règlement numéro CHECK_NUMBER : ' ||
                    pv_check_number || '; MONTANT : ' || pv_montant ||
                    '; FOURNISSEUR : ' || pv_vendor_name ||
                    '; SITE FOURNISSEUR : ' || pv_vendor_site_code);
            log_msg('==> Erreur lors de l''envoi par mail du règlement numéro CHECK_NUMBER : ' ||
                    pv_check_number || '; MONTANT : ' || pv_montant ||
                    '; FOURNISSEUR : ' || pv_vendor_name ||
                    '; SITE FOURNISSEUR : ' || pv_vendor_site_code);
            utl_smtp.close_data(l_conn);
            utl_smtp.quit(l_conn);
            pn_retcode := 1;
    END envoi_mail;

    ----------------------------------------------------------------------------
    --  Nom           : main
    --  Description   : procédure principale du stockage des bons de commande
    --
    --
    --  PARAMETRES :
    --    pv_errbuf     Entrée/Sortie   Message d'erreur
    --    pn_retcode  Sortie      Code d'erreur
    --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
    --    pv_mail_test                Entree          Adresse mail destinataire pour test
    ----------------------------------------------------------------------------

    PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER,pv_mail_test IN VARCHAR2)

     IS
        vn_check_num AP_CHECKS_ALL.CHECK_NUMBER%TYPE;

        vv_nom_fichier      VARCHAR2(100);
        vd_date_vir         AP_CHECKS_ALL.CHECK_DATE%TYPE;
        vv_iban_number      AP_CHECKS_ALL.IBAN_NUMBER%TYPE;
        vv_montant          VARCHAR2(25);
        vv_societe          HR_LOCATIONS_ALL.DESCRIPTION%TYPE;
        vv_motif            VARCHAR2(250);
        vv_vendor_name      PO_VENDORS.VENDOR_NAME%TYPE;
        vv_vendor_site_code PO_VENDOR_SITES_ALL.VENDOR_SITE_CODE%TYPE;
        --vv_adresse_mail     PO_VENDOR_SITES_ALL.REMITTANCE_EMAIL%TYPE; --EDB295
    vv_adresse_mail     VARCHAR2(100);--EDB295


        vv_check_id    AP_CHECKS_ALL.CHECK_ID%TYPE;
        vv_output_file fnd_concurrent_requests.outfile_name%TYPE;
        rec_param      dka_parameters%ROWTYPE;

    --EDB295
    vv_checkname    AP_CHECKS_ALL.checkrun_name%TYPE;
    vv_client_name    ar_customers.CUSTOMER_NAME%TYPE;
    vv_client_site_number  hz_party_sites.party_site_number%TYPE;
    vv_region  hr_all_organization_units.name%TYPE;
  vv_cli_reference hz_cust_acct_sites_all.attribute3%TYPE;






        e_no_mail EXCEPTION;

        vv_status_code VARCHAR2(50);
        CURSOR cur_avis_reglement IS
            SELECT distinct DST.REQUEST_ID,
                            DST.CHECK_ID,
                            DST.CREATED_BY,
                            DST.CREATION_DATE,
                            DST.LAST_UPDATED_BY,
                            DST.LAST_UPDATE_DATE
              FROM DKA_SAPVIR_ATTACH_TMP DST
             ORDER BY DST.REQUEST_ID;

        rec_avis_reglement cur_avis_reglement%ROWTYPE;
        e_boucle EXCEPTION;

    BEGIN

        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf  := NULL;
        pn_retcode := 0;

        --YWA artf2120398
        ------------------------------------
        --INITIALISATION ADRESSE MAIL TEST--
        ------------------------------------
        DKA_SEND_MAIL_PKG.mail_test(pv_mail_test,gv_mail_test);
        log_msg('Mail de test :'||gv_mail_test);

        g_step := 'MAIN 001 - INITIALISATION DES VARIABLES D''ENVOI DE MAIL.';
        log_msg(g_step);
        ----- Appel de la procédure INIT -----
        init(pv_errbuf, pn_retcode);
        IF pn_retcode = 2 THEN
            Raise e_no_mail;
        END IF;

        OPEN cur_avis_reglement;
        LOOP
            FETCH cur_avis_reglement
                INTO rec_avis_reglement;
            EXIT WHEN cur_avis_reglement%NOTFOUND;
            BEGIN
                g_step := 'MAIN 002 - RECHERCHE DE L''IDENTIFIANT DU REGLEMENT.';
                log_msg(g_step);
                BEGIN
                    select ARGUMENT4,
                           SUBSTR(fcr.outfile_name,
                                  INSTR(fcr.outfile_name, '/', -1, 1) + 1),
                           STATUS_CODE
                      into vv_check_id, vv_output_file, vv_status_code
                      from fnd_concurrent_requests fcr
                     where fcr.request_id = rec_avis_reglement.REQUEST_ID;
                EXCEPTION
                    WHEN OTHERS THEN
                        dka_tools_pkg.put_outdebug_message(SQLCODE || '=' ||
                                                           substr(SQLERRM,
                                                                  1,
                                                                  400));
                        dka_tools_pkg.put_outdebug_message(SQLERRM);

                END;
                IF vv_status_code = 'C' THEN
                    g_step := 'MAIN 003 - RECHERCHE DES DONNEES A ENVOYEES PAR MAIL.';
                    log_msg(g_step);

                        --RBE MigR12
                        /*
                        select ACA.CHECK_NUMBER,
                               ACA.CHECK_DATE,
                               ACA.IBAN_NUMBER,
                               TO_CHAR(ACA.AMOUNT, 'FM999G999G999G999D90') || ' ' ||
                               ACA.CURRENCY_CODE,
                               HLA.DESCRIPTION,
                               'VIR DE ' || HLA.DESCRIPTION,
                               PV.SEGMENT1 || '_' || PVSA.VENDOR_SITE_CODE || '_' ||
                               ACA.CHECK_NUMBER || '.pdf',
                               PV.VENDOR_NAME,
                               PVSA.VENDOR_SITE_CODE,
                               PVSA.REMITTANCE_EMAIL
                          INTO vn_check_num,
                               vd_date_vir,
                               vv_iban_number,
                               vv_montant,
                               vv_societe,
                               vv_motif,
                               vv_nom_fichier,
                               vv_vendor_name,
                               vv_vendor_site_code,
                               vv_adresse_mail
                          from hr_locations_all          hla,
                               ap_checks_all             aca,
                               po_vendor_sites_all       pvsa,
                               po_vendors                pv,
                               hr_all_organization_units haou,
                               ap_bank_accounts_all      aba,
                               gl_code_combinations      gcc
                         where aca.vendor_id = pv.vendor_id(+)
                           and aca.vendor_site_id = pvsa.vendor_site_id(+)
                           and haou.location_id = hla.location_id
                           and aca.bank_account_id = aba.bank_account_id
                           and gcc.code_combination_id =
                               aba.asset_code_combination_id
                           and haou.name = gcc.segment1
                           and aca.check_id = vv_check_id;
                           */

            --ARA EDB295

            BEGIN
              SELECT Substr(checkrun_name,Instr(checkrun_name, 'RBT'), INSTR(checkrun_name, 'NT') - INSTR(checkrun_name, 'RBT') +2 )
              INTO vv_checkname
              from AP_CHECKS_ALL
              where check_id = vv_check_id;
            END;


            IF vv_checkname = 'RBTCLIENT' THEN
              BEGIN
              SELECT distinct ACA.CHECK_NUMBER,
                ACA.CHECK_DATE,
                ABA.IBAN IBAN_NUMBER,
                TO_CHAR(ACA.AMOUNT, 'FM999G999G999G999D90') || ' ' ||
                ACA.CURRENCY_CODE,
                NVL(HLA.DESCRIPTION, HLA.LOCATION_CODE),
                'VIR DE ' || NVL(HLA.DESCRIPTION, HLA.LOCATION_CODE),
                hca.ORIG_SYSTEM_REFERENCE || '_' || hcas.attribute3 || '_' ||
                ACA.CHECK_NUMBER || '.pdf',
                (select CUSTOMER_NAME
                   from ar_customers
                  where orig_system_reference = hca.ORIG_SYSTEM_REFERENCE),
          hcas.attribute3,
               -- hps.party_site_number,
                /*(select distinct hcp.email_address
                   from hz_contact_points hcp
                  where hps.PARTY_SITE_ID = hcp.owner_table_id
                    and hcp.primary_flag = 'Y'
                    AND hcp.status = 'A'
          and hcp.email_address is not null) email_address*/
        --iepa.debit_advice_email email_address,
        hca.ORIG_SYSTEM_REFERENCE,
        (
         select substr (name , 1, 3)
         from hr_all_organization_units
         where organization_id = ACA.ORG_ID
        ) region

              INTO vn_check_num,
                             vd_date_vir,
                             vv_iban_number,
                             vv_montant,
                             vv_societe,
                             vv_motif,
                             vv_nom_fichier,
                             vv_client_name,
                             vv_client_site_number,
               vv_cli_reference,
                             --vv_adresse_mail,
               vv_region
               FROM AP_CHECKS_ALL ACA,
                IBY_EXT_BANK_ACCOUNTS     ABA,
                HR_ALL_ORGANIZATION_UNITS HAOU,
                hr_locations_all          hla,
                hz_party_sites         hps,
                hz_cust_acct_sites_all hcas,
                hz_cust_accounts       hca
        --,iby_external_payers_all iepa


                WHERE hps.party_site_id = hcas.party_site_id
           AND haou.organization_id = hcas.org_id
           AND hca.cust_account_id = hcas.cust_account_id
           AND hcas.cust_account_id =
             (SELECT BILL_TO_CUSTOMER_ID
              FROM ra_customer_trx_all
             where customer_trx_id =
                 (SELECT substr(ai.description,
                        -instr(reverse(ai.description), '_') + 1)
                  from AP_INVOICES_ALL         ai,
                     AP_INVOICE_PAYMENTS_ALL p,
                     ap_checks_all           c
                 where p.invoice_id = ai.invoice_id
                   and c.check_id = p.check_id
                   and c.check_id = ACA.check_id
           and rownum = 1))

           and ACA.party_site_id = hps.party_site_id
           and ACA.party_id = hps.party_id

       --AND iepa.cust_account_id = hca.cust_account_id
           --AND debit_advice_delivery_method = 'EMAIL'

           AND ACA.EXTERNAL_BANK_ACCOUNT_ID = ABA.EXT_BANK_ACCOUNT_ID
           AND ACA.ORG_ID = HAOU.ORGANIZATION_ID
           and haou.location_id = hla.location_id
                   AND   ACA.CHECK_ID = vv_check_id
                 ;

       --SELECT Mail address
       BEGIN
       select distinct iepa.debit_advice_email
       INTO vv_adresse_mail
           from hz_cust_accounts hca, hz_cust_acct_sites_all hcas ,iby_external_payers_all iepa
           where iepa.cust_account_id = hca.cust_account_id
           AND hca.cust_account_id = hcas.cust_account_id
           AND debit_advice_delivery_method = 'EMAIL'
           AND hcas.attribute3 = vv_client_site_number
           AND hca.ORIG_SYSTEM_REFERENCE = vv_cli_reference;
       EXCEPTION
       WHEN OTHERS THEN
       g_step := 'MAIN 003-A ERROR RBT - IMPOSSIBLE DE DETERMINER L''ADRESSE MAIL :  ' || SQLERRM;
           log_msg(g_step);
       vv_adresse_mail     := NULL;
       END;



               EXCEPTION
              WHEN NO_DATA_FOUND THEN
                g_step := 'MAIN 003ERROR RBT - IMPOSSIBLE DE DETERMINER LES DONNEES A ENVOYER :  ' || SQLERRM;
                log_msg(g_step);
                vd_date_vir         := NULL;
                vv_iban_number      := NULL;
                vv_montant          := NULL;
                vv_societe          := NULL;
                vv_motif            := NULL;
                vv_nom_fichier      := NULL;
                vv_client_name      := NULL;
                vv_client_site_number := NULL;
        vv_cli_reference := NULL;
                --vv_adresse_mail     := NULL;
              WHEN OTHERS THEN
                g_step := 'MAIN 003ERROR RBT - IMPOSSIBLE DE DETERMINER LES DONNEES A ENVOYER :  ' || SQLERRM;
                log_msg(g_step);
                vd_date_vir         := NULL;
                vv_iban_number      := NULL;
                vv_montant          := NULL;
                vv_societe          := NULL;
                vv_motif            := NULL;
                vv_nom_fichier      := NULL;
                vv_client_name      := NULL;
                vv_client_site_number := NULL;
        vv_cli_reference := NULL;
                --vv_adresse_mail     := NULL;

               END;

            ELSE

              BEGIN

              SELECT ACA.CHECK_NUMBER,
                 ACA.CHECK_DATE,
                 --ACA.IBAN_NUMBER,      --RBE artf2101497
                 ABA.IBAN IBAN_NUMBER,   --RBE artf2101497
                 TO_CHAR(ACA.AMOUNT, 'FM999G999G999G999D90') || ' ' ||
                 ACA.CURRENCY_CODE,
                 NVL(HLA.DESCRIPTION,HLA.LOCATION_CODE),              --RBE artf2101497
                 'VIR DE ' || NVL(HLA.DESCRIPTION,HLA.LOCATION_CODE), --RBE artf2101497
                 PV.SEGMENT1 || '_' || PVSA.VENDOR_SITE_CODE || '_' ||
                 ACA.CHECK_NUMBER || '.pdf',
                 PV.VENDOR_NAME,
                 PVSA.VENDOR_SITE_CODE,
                 --PVSA.REMITTANCE_EMAIL
                 iepa.REMIT_ADVICE_EMAIL --RBE artf2090995
              INTO vn_check_num,
                 vd_date_vir,
                 vv_iban_number,
                 vv_montant,
                 vv_societe,
                 vv_motif,
                 vv_nom_fichier,
                 vv_vendor_name,
                 vv_vendor_site_code,
                 vv_adresse_mail
               FROM AP_CHECKS_ALL ACA,
                PO_VENDOR_SITES_ALL       PVSA,
                PO_VENDORS                PV,
                IBY_EXT_BANK_ACCOUNTS     ABA,
                ---gl_code_combinations      gcc
                HR_ALL_ORGANIZATION_UNITS HAOU,
                hr_locations_all          hla,
                IBY_EXTERNAL_PAYEES_ALL   iepa -- RBE artf2090995
               WHERE ACA.VENDOR_ID = PV.VENDOR_ID(+)
               AND   ACA.VENDOR_SITE_ID = PVSA.VENDOR_SITE_ID(+)
               AND   ACA.VENDOR_SITE_ID = iepa.SUPPLIER_SITE_ID(+) -- RBE artf2090995
               AND   ACA.EXTERNAL_BANK_ACCOUNT_ID = ABA.EXT_BANK_ACCOUNT_ID
               AND   ACA.ORG_ID = HAOU.ORGANIZATION_ID
               and   haou.location_id = hla.location_id
               --and   gcc.code_combination_id = aba.asset_code_combination_id
               AND   ACA.CHECK_ID = vv_check_id
               ;

            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                g_step := 'MAIN 003ERROR - IMPOSSIBLE DE DETERMINER LES DONNEES A ENVOYER.';
                log_msg(g_step);
                vd_date_vir         := NULL;
                vv_iban_number      := NULL;
                vv_montant          := NULL;
                vv_societe          := NULL;
                vv_motif            := NULL;
                vv_nom_fichier      := NULL;
                vv_vendor_name      := NULL;
                vv_vendor_site_code := NULL;
                vv_adresse_mail     := NULL;
              WHEN OTHERS THEN
                g_step := 'MAIN 003ERROR - IMPOSSIBLE DE DETERMINER LES DONNEES A ENVOYER.';
                log_msg(g_step);
                vd_date_vir         := NULL;
                vv_iban_number      := NULL;
                vv_montant          := NULL;
                vv_societe          := NULL;
                vv_motif            := NULL;
                vv_nom_fichier      := NULL;
                vv_vendor_name      := NULL;
                vv_vendor_site_code := NULL;
                vv_adresse_mail     := NULL;
            END;

          END IF;

                    IF vv_adresse_mail IS NULL THEN

            --EDB295
            IF vv_checkname = 'RBTCLIENT' THEN
              g_step := 'MAIN 004 - ERREUR : IMPOSSIBLE DE DETERMINER L''EMAIL DU SITE CLIENT : CLIENT ''' ||
                        vv_client_name ||
                        ''' SITE CLIENT ''' ||
                        vv_client_site_number || '''';
                  log_msg(g_step);
                  ENVOI_MAIL_ADRESS_CLIENT_ABS(vn_check_num,
                                 vv_montant,
                                 vv_client_name,
                                 vv_client_site_number,
                                 vv_region,
                                 pv_errbuf,
                                 pn_retcode);
                  RAISE e_boucle;

            ELSE


                  g_step := 'MAIN 004 - ERREUR : IMPOSSIBLE DE DETERMINER L''EMAIL DU SITE FOURNISSEUR : FOURNISSEUR ''' ||
                        vv_vendor_name ||
                        ''' SITE FOURNISSEUR ''' ||
                        vv_vendor_site_code || '''';
                  log_msg(g_step);
                  envoi_mail_adress_four_abs(vn_check_num,
                                 vv_montant,
                                 vv_vendor_name,
                                 vv_vendor_site_code,
                                 pv_errbuf,
                                 pn_retcode);
                  RAISE e_boucle;

            END IF; --END EDB295

                    END IF;

                    IF gv_base != gv_base_prod and vv_adresse_mail IS NOT NULL THEN
                        Dka_Tools_Pkg.get_parameter('SAPVIR_MAIL',
                                                    'TEST_DEST_MAIL',
                                                    rec_param,
                                                    pv_errbuf,
                                                    pn_retcode);
                        vv_adresse_mail := rec_param.varchar2_value;
                    END IF;

                    g_step := 'MAIN 004 - COPIE ET RENOMMAGE DU FICHIER PDF.';
                    log_msg(g_step);
                    BEGIN
                        UTL_FILE.FCOPY('DKA_LOADAVR',
                                       vv_output_file,
                                       'DKA_TMPAVR',
                                       vv_nom_fichier,
                                       1,
                                       NULL);
                    EXCEPTION
                        WHEN OTHERS THEN
                            g_step := 'MAIN 004 - ERREUR LORS DE LA COPIE DU FICHIER PDF.';
                            log_msg(g_step);
                    END;

                    g_step := 'MAIN 005 - CONSTITUTION ET ENVOI DU MAIL.';
                    log_msg(g_step);

      --<EDB295

          IF vv_checkname = 'RBTCLIENT' THEN

                    ENVOI_MAIL_CLIENT(vn_check_num,
                               vd_date_vir,
                               vv_iban_number,
                               vv_montant,
                               vv_societe,
                               vv_motif,
                               vv_nom_fichier,
                               vv_client_name,
                               vv_client_site_number,
                               vv_adresse_mail,
                               pv_errbuf,
                               pn_retcode);

                    g_step := 'MAIN 006 - SUPPRESSION DU FICHIER TEMPORAIRE.';
                    log_msg(g_step);
                    BEGIN
                        UTL_FILE.FREMOVE('DKA_TMPAVR', vv_nom_fichier);
                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE e_boucle;
                    END;

          ELSE

          envoi_mail(vn_check_num,
                               vd_date_vir,
                               vv_iban_number,
                               vv_montant,
                               vv_societe,
                               vv_motif,
                               vv_nom_fichier,
                               vv_vendor_name,
                               vv_vendor_site_code,
                               vv_adresse_mail,
                               pv_errbuf,
                               pn_retcode);

                    g_step := 'MAIN 006 - SUPPRESSION DU FICHIER TEMPORAIRE.';
                    log_msg(g_step);
                    BEGIN
                        UTL_FILE.FREMOVE('DKA_TMPAVR', vv_nom_fichier);
                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE e_boucle;
                    END;

          END IF;

      -->EDB295

                ELSE
                    g_step := 'MAIN 003 - FICHIER DE SORTIE VIDE OU INEXISTANT.';
                    log_msg(g_step);
                    RAISE e_boucle;
                END IF;
            EXCEPTION
                WHEN e_boucle THEN
                    pn_retcode := 1;
            END;
        END LOOP;
        CLOSE cur_avis_reglement;
        g_step := 'MAIN 999 - FIN.';
        log_msg(g_step);
    EXCEPTION
        WHEN e_no_mail THEN
            pv_errbuf := g_step || SQLERRM;
            log_msg(pv_errbuf);
            out_msg(pv_errbuf);
            pn_retcode := 2;
        WHEN OTHERS THEN
            pv_errbuf := 'MAIN 999 - ERROR PROCEDURE MAIN ' || SQLERRM;
            log_msg(pv_errbuf);
            out_msg(pv_errbuf);
            pn_retcode := 2;
    END main;

END DKA_SAPVIR_MAIL_PKG;

/
show errors
exit