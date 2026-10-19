CREATE OR REPLACE PACKAGE BODY APPS.DKA_SAPAUTOVIR_PKG AS
    ------------------------------------------------------------------------------------------
    -- $$
    -- CAPGEMINI
    -- PROJET            : DALKIA Oracle Applications
    -- NOM               : DKA_SAPAUTOVIR_PKG.pkb
    -- DESCRIPTION       : DKA_SAPAUTOVIR_PKG package body :
    --
    -- AUTEUR           : CAPGEMINI
    -- DATE DE CREATION : 13/08/2013
    -- DOC. ASSOCIEE    :
    -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
    ------------------------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- ---------- --- ------------------------------------------------------------------------
    -- 22/11/2013 CDE Correction adresse mail du fournisseur
    -- 20/12/2013 BCO Optimisation du traitement.
    --             Exécution d'un seul traitement d'envoi d'avis de virement par mail et d'un
    --                seul traitement de rattachement d'avis de virement par mail.
    -- 10/10/2016 RBE Migration R12
	-- 25/12/2023 ARA EDB295 Lot3 - Ajout d¿une nouvelle campagne de règlement / Remboursements client
    -- 11/07/2025 Oracle , on enleve le test sur le vendor_id de ap_checks_all
    -- 03/09/2025 Oracle , modif précédente insuffisante , on revoie entierement les requetes en question
    -- ---------- --- ------------------------------------------------------------------------

    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PRIVEES
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    gv_base v$database.name%TYPE;

    -- Message d'information.
    g_step VARCHAR2(500);

    -- Variable contenant les noms abrégés des traitements :
    gv_rapvir_pdf    CONSTANT VARCHAR2(25) := 'DKA_RAPVIR_PDF';
    gv_sapvir_mail   CONSTANT VARCHAR2(25) := 'DKA_SAPVIR_MAIL';
    gv_sapvir_attach CONSTANT VARCHAR2(25) := 'DKA_SAPVIR_ATTACH';

    -- Variable contenant les informations de mise à jour :
    cn_user_id CONSTANT NUMBER := fnd_profile.value('USER_ID');

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

    -------------------------------------------------------------------------------------
    --  Nom           : lance_trait_pdf
    --  Description   : procedure d'exécution de traitement de création du fichier avis de virement
    --
    --  PARAMETRES    :
    --  Pn_Check      IN      Identifiant du règlement
    -- Pv_prog_name    IN      Nom du programme
    --  Pv_Errbuf           IN OUT      Message d'avertissement
    --  Pn_Retcode          IN OUT      Code erreur
    --  VALEUR RETOURNEE :  pn_retcode
    --  Valeurs possibles : true=traitement sans erreur, false=traitement en erreur
    ------------------------------------------------------------------------------------
    PROCEDURE lance_trait_pdf(Pn_Check     IN NUMBER,
                              Pv_prog_name IN VARCHAR2,
                              Pv_Errbuf    IN OUT VARCHAR2,
                              Pn_Retcode   IN OUT NUMBER) IS

        vv_prog_application_short_name VARCHAR(30);
        vn_request_id                  NUMBER(15);
        e_error EXCEPTION;
    BEGIN
        g_step := 'LANCE_TRAIT_PDF 000 : DEBUT';
        log_msg(g_step);

        -- Recherche de l'application propriétaire du traitement. --
        g_step := 'LANCE_TRAIT_PDF 001 : RECHERCHE DES INFORMATIONS LIEES AU PROGRAMME D''ENVOI PAR MAIL.';
        BEGIN
            SELECT fa.application_short_name
              INTO vv_prog_application_short_name
              FROM fnd_concurrent_programs fcp, fnd_application fa
             WHERE fcp.concurrent_program_name = Pv_prog_name
               AND fa.application_id = fcp.application_id;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE e_error;
                g_step := 'LANCE_TRAIT_PDF 001 - ERREUR : Impossible de trouver l''application propriétaire.';
                log_msg(g_step);
        END;

        vn_request_id := fnd_request.submit_request(vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                    Pv_prog_name, --SHORT_NAME du TRAITEMENT
                                                    NULL, --PROGRAM_NAME
                                                    NULL, --START
                                                    FALSE, --SUB_REQUEST
                                                    NULL, --ARGUMENT1
                                                    NULL, --ARGUMENT2
                                                    NULL, --ARGUMENT3
                                                    Pn_Check --ARGUMENT1
                                                    );
        g_step        := 'LANCE_TRAIT_PDF 002 :Validation pour que les GTS puissent prendre la demande.';
        log_msg(g_step);
        COMMIT;

        IF vn_request_id = 0 THEN
            DBMS_OUTPUT.put_line('Impossible de lancer le Traitement ');
            RAISE e_error;
        END IF;

        DBMS_OUTPUT.put_line('Traitement numero : ' ||
                             TO_CHAR(vn_request_id));

        g_step := 'LANCE_TRAIT_PDF 999 : FIN';
        log_msg(g_step);
        INSERT INTO DKA_SAPVIR_ATTACH_TMP
            (REQUEST_ID,
             CHECK_ID,
             CREATED_BY,
             CREATION_DATE,
             LAST_UPDATED_BY,
             LAST_UPDATE_DATE)
        VALUES
            (vn_request_id,
             Pn_Check,
             cn_user_id,
             SYSDATE,
             cn_user_id,
             SYSDATE);
    EXCEPTION
        WHEN e_error THEN
            g_step     := '';
            Pv_Errbuf  := g_step;
            Pn_Retcode := 2;
        WHEN OTHERS THEN
            g_step := 'LANCE_TRAIT_PDF 999 - ERREUR : ' || Pv_prog_name ||
                      ' ==> ERREUR : ' || SQLERRM;
            log_msg(g_step);
            Pv_Errbuf  := g_step;
            Pn_Retcode := 2;

    END lance_trait_pdf;

    -------------------------------------------------------------------------------------
    --  Nom           : lance_trait_attach
    --  Description   : procedure d'exécution du traitement "DKA : Rattachement avis de virement"
    --
    --  PARAMETRES    :
    -- Pv_prog_name    IN      Nom du programme
    --  Pv_Errbuf           IN OUT      Message d'avertissement
    --  Pn_Retcode          IN OUT      Code erreur
    --  VALEUR RETOURNEE :  pn_retcode
    --  Valeurs possibles : true=traitement sans erreur, false=traitement en erreur
    ------------------------------------------------------------------------------------
    PROCEDURE lance_trait_attach(Pv_prog_name IN VARCHAR2,
                                 Pv_Errbuf    IN OUT VARCHAR2,
                                 Pn_Retcode   IN OUT NUMBER) IS

        vv_prog_application_short_name VARCHAR(30);
        vn_request_id                  NUMBER(15);
        e_error EXCEPTION;
    BEGIN
        g_step := 'LANCE_TRAIT_ATTACH 000 : DEBUT';
        log_msg(g_step);

        -- Recherche de l'application propriétaire du traitement. --
        g_step := 'LANCE_TRAIT_ATTACH 001 : RECHERCHE DES INFORMATIONS LIEES AU PROGRAMME D''ENVOI PAR MAIL.';
        BEGIN
            SELECT fa.application_short_name
              INTO vv_prog_application_short_name
              FROM fnd_concurrent_programs fcp, fnd_application fa
             WHERE fcp.concurrent_program_name = Pv_prog_name
               AND fa.application_id = fcp.application_id;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE e_error;
                g_step := 'LANCE_TRAIT_ATTACH 001 - ERREUR : Impossible de trouver l''application propriétaire.';
                log_msg(g_step);
        END;

        vn_request_id := fnd_request.submit_request(vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                    Pv_prog_name, --SHORT_NAME du TRAITEMENT
                                                    NULL, --PROGRAM_NAME
                                                    NULL, --START
                                                    FALSE --SUB_REQUEST
                                                    );
        g_step        := 'LANCE_TRAIT_ATTACH 002 :Validation pour que les GTS puissent prendre la demande.';
        log_msg(g_step);
        COMMIT;

        IF vn_request_id = 0 THEN
            DBMS_OUTPUT.put_line('Impossible de lancer le Traitement ');
            RAISE e_error;
        END IF;

        DBMS_OUTPUT.put_line('Traitement numero : ' ||
                             TO_CHAR(vn_request_id));

        g_step := 'LANCE_TRAIT_ATTACH 999 : FIN';
        log_msg(g_step);
    EXCEPTION
        WHEN e_error THEN
            g_step     := '';
            Pv_Errbuf  := g_step;
            Pn_Retcode := 2;
        WHEN OTHERS THEN
            g_step := 'LANCE_TRAIT_ATTACH 999 - ERREUR : ' || Pv_prog_name ||
                      ' ==> ERREUR : ' || SQLERRM;
            log_msg(g_step);
            Pv_Errbuf  := g_step;
            Pn_Retcode := 2;
    END lance_trait_attach;

    -------------------------------------------------------------------------------------
    --  Nom           : lance_trait_mail
    --  Description   : procedure d'exécution du traitement "DKA : Envoi avis de virement par mail"
    --
    --  PARAMETRES    :
    --  Pv_prog_name      IN      Nom du programme
    --  Pv_Errbuf           IN OUT      Message d'avertissement
    --  Pn_Retcode          IN OUT      Code erreur
    --  VALEUR RETOURNEE :  pn_retcode
    --  Valeurs possibles : true=traitement sans erreur, false=traitement en erreur
    ------------------------------------------------------------------------------------
    PROCEDURE lance_trait_mail(Pv_prog_name IN VARCHAR2,
                               Pv_Errbuf    IN OUT VARCHAR2,
                               Pn_Retcode   IN OUT NUMBER) IS

        vv_prog_application_short_name VARCHAR(30);
        vn_request_id                  NUMBER(15);
        e_error EXCEPTION;
        vn_prog_application_id           NUMBER (15);
        vn_program_id                    NUMBER (15);
    BEGIN
        g_step := 'LANCE_TRAIT_MAIL 000 : DEBUT';
        log_msg(g_step);

        -- Recherche de l'application propriétaire du traitement. --
        g_step := 'LANCE_TRAIT_MAIL 001 : RECHERCHE DES INFORMATIONS LIEES AU PROGRAMME D''ENVOI PAR MAIL.';
        BEGIN
            SELECT fa.application_short_name,
                fcp.application_id,--YWA
                fcp.concurrent_program_id --YWA
              INTO vv_prog_application_short_name,
                    vn_prog_application_id,
                    vn_program_id
              FROM fnd_concurrent_programs fcp, fnd_application fa
             WHERE fcp.concurrent_program_name = Pv_prog_name
               AND fa.application_id = fcp.application_id;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE e_error;
                g_step := 'LANCE_TRAIT_MAIL 001 - ERREUR : Impossible de trouver l''application propriétaire.';
                log_msg(g_step);
        END;

        --YWA
         DBMS_OUTPUT.put_line ('Recuperation des parametres');
        dka_tools_pkg.get_request_set_params (
            pv_errbuf                      => Pv_Errbuf,
            pn_retcode                     => Pn_Retcode,
            pn_application_id              => NULL,
            pn_request_set_id              => NULL,
            pn_request_set_program_id      => NULL,
            pn_prog_application_id         => vn_prog_application_id,
            pn_program_id                  => vn_program_id
        );

        IF Pn_Retcode != 0
        THEN
            DBMS_OUTPUT.put_line ('Impossible de récupérer les paramètres :');
            DBMS_OUTPUT.put_line (Pv_Errbuf);
            RETURN;
        END IF;--YWA

        vn_request_id := fnd_request.submit_request(vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                    Pv_prog_name, --SHORT_NAME du TRAITEMENT
                                                    NULL, --PROGRAM_NAME
                                                    NULL, --START
                                                    FALSE,
                                                    dka_tools_pkg.tab_request_params(1) --ARGUMENT1 YWA
                                                    ); --SUB_REQUEST
        g_step        := 'LANCE_TRAIT_MAIL 002 :Validation pour que les GTS puissent prendre la demande.';
        log_msg(g_step);
        COMMIT;

        IF vn_request_id = 0 THEN
            DBMS_OUTPUT.put_line('Impossible de lancer le Traitement ');
            RAISE e_error;
        END IF;

        DBMS_OUTPUT.put_line('Traitement numero : ' ||
                             TO_CHAR(vn_request_id));

        g_step := 'LANCE_TRAIT_MAIL 999 : FIN';
        log_msg(g_step);
    EXCEPTION
        WHEN e_error THEN
            g_step     := '';
            Pv_Errbuf  := g_step;
            Pn_Retcode := 2;
        WHEN OTHERS THEN
            g_step := 'LANCE_TRAIT_MAIL 999 - ERREUR : ' || Pv_prog_name ||
                      ' ==> ERREUR : ' || SQLERRM;
            log_msg(g_step);
            Pv_Errbuf  := g_step;
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
    -----------------------------------------------------------------
    PROCEDURE edition_output(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

        l_appl      fnd_application.application_short_name%TYPE;
        l_prgm_name fnd_conc_req_summary_v.PROGRAM%TYPE;

        l_out   VARCHAR2(4000);
        l_ligne VARCHAR2(100) := '---------------------------------------------------------------';

        CURSOR cur_avis_virement IS
            SELECT distinct ACA.CHECK_ID,
                            ACA.CHECK_NUMBER,
                            DIAH.SOCIETE,
                            DIAH.REGION,
                            DIAL.VENDOR_ID,
                            DIAL.VENDOR_SITE_ID
              FROM DKA_IEOAPSAT01_APIMP_LINE DIAL
                 , DKA_IEOAPSAT01_APIMP_HDR  DIAH
                 , AP_CHECKS_ALL             ACA
                 , iby_payments_all          IPA -- ajout 03/09/25
             WHERE DIAH.HEADER_ID = DIAL.HEADER_ID
               AND DIAH.STATUS = 'PRINT'
               AND DIAL.PAYMENTMETHOD = 'EFT'
               AND ACA.PAYMENT_METHOD_CODE = DIAL.PAYMENTMETHOD -- Type de document. 11/07/2025 : PAYMENT_METHOD_CODE et pas LOOKUP
               AND ACA.CHECK_DATE = DIAL.TRANSACTIONDATE -- Date de règlement.
--               AND ACA.Vendor_Id = DIAL.Vendor_Id -- 11/07/2025 : on met en commentaire
--               AND ACA.VENDOR_SITE_ID = DIAL.Vendor_Site_Id  -- 11/07/2025 : on met en commentaire 
               AND ACA.CHECKRUN_NAME = DIAL.CHECKRUN_NAME
--               AND ACA.IBAN_NUMBER = DIAL.CPTYSECONDARYACCOUNTNUMBER
               AND IPA.PAYMENT_ID = ACA.PAYMENT_ID -- 03/09/25 : jointure avec IBY
               AND IPA.ext_bank_account_iban_number = DIAL.CPTYSECONDARYACCOUNTNUMBER -- 03/09/25 : on prend l'iban de IBY
               AND ACA.VENDOR_NAME = DIAL.COUNTERPARTYNAME -- 03/09/25 : on joint par le nom , faute de mieux dans la table spé
                  -- RG5 - Pas de génération de fichier pour les notes de frais.
               AND DIAL.CHECKRUN_NAME not like '%EMPVIR'
               AND ACA.STATUS_LOOKUP_CODE = 'NEGOTIABLE'
             ORDER BY DIAH.SOCIETE,
                      DIAH.REGION,
                      DIAL.VENDOR_ID,
                      DIAL.VENDOR_SITE_ID;

        rec_avis_virement cur_avis_virement%ROWTYPE;

    --ARA EDB295
    CURSOR cur_avis_vir_rbt IS
    SELECT distinct ACA.CHECK_ID,
                ACA.CHECK_NUMBER,
                DIAH.SOCIETE,
                DIAH.REGION,
                hca.cust_account_id,
                ACA.PARTY_SITE_ID
      FROM DKA_IEOAPSAT01_APIMP_LINE DIAL
        , DKA_IEOAPSAT01_APIMP_HDR  DIAH
        , AP_CHECKS_ALL             ACA
        , IBY_EXT_BANK_ACCOUNTS     IEBC
        , hz_party_sites         hps
        , hz_cust_acct_sites_all hcas
        , hz_cust_accounts       hca
        , iby_payments_all          IPA -- ajout 03/09/25
     WHERE DIAH.HEADER_ID = DIAL.HEADER_ID
       AND DIAH.STATUS = 'PRINT'
       AND DIAL.PAYMENTMETHOD = 'EFT'
       AND ACA.PAYMENT_METHOD_CODE = DIAL.PAYMENTMETHOD -- Type de document.
       AND ACA.CHECK_DATE = DIAL.TRANSACTIONDATE -- Date de règlement.
--       AND NVL(ACA.Vendor_Id, '-1') = NVL(DIAL.Vendor_Id, '-1') --EDB295 -- 11/07/25 : on enleve ce test
--       AND NVL(ACA.VENDOR_SITE_ID, '-1') = NVL(DIAL.Vendor_Site_Id, '-1') --EDB295 -- 11/07/25 : on enleve ce test
       AND ACA.CHECKRUN_NAME = DIAL.CHECKRUN_NAME
       AND ACA.external_bank_account_id = IEBC.ext_bank_account_id
--       AND IEBC.IBAN = DIAL.CPTYSECONDARYACCOUNTNUMBER
        AND IPA.PAYMENT_ID = ACA.PAYMENT_ID -- 03/09/25 : jointure avec IBY
       AND IPA.ext_bank_account_iban_number = DIAL.CPTYSECONDARYACCOUNTNUMBER -- 03/09/25 : on prend l'iban de IBY
       AND ACA.VENDOR_NAME = DIAL.COUNTERPARTYNAME -- 03/09/25 : on joint par le nom , faute de mieux dans la table spé
       AND DIAL.CHECKRUN_NAME not like '%EMPVIR'
       AND ACA.STATUS_LOOKUP_CODE = 'NEGOTIABLE'
       and hps.party_site_id = hcas.party_site_id
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
               and c.check_id = ACA.CHECK_ID
			   and rownum = 1))

       and aca.party_site_id = hps.party_site_id
       and aca.party_id = hps.party_id
       AND hcas.org_id = aca.org_id

     ORDER BY DIAH.SOCIETE, DIAH.REGION, hca.cust_account_id, ACA.PARTY_SITE_ID;

    rec_avis_vir_rbt cur_avis_vir_rbt%ROWTYPE;

    --END EDB295

        CURSOR cur_prog_error IS
            SELECT FCP.CONCURRENT_PROGRAM_NAME,
                   FCR.PRIORITY_REQUEST_ID,
                   FCR.ARGUMENT4 CHECK_ID,
                   ACA.CHECK_NUMBER,
                   TO_CHAR(ACA.CHECK_DATE, 'DD/MM/YYYY') CHECK_DATE
              FROM FND_CONCURRENT_PROGRAMS FCP,
                   FND_CONCURRENT_REQUESTS FCR,
                   AP_CHECKS_ALL           ACA
             WHERE FCP.APPLICATION_ID = FCR.PROGRAM_APPLICATION_ID
               AND FCP.CONCURRENT_PROGRAM_ID = FCR.CONCURRENT_PROGRAM_ID
               AND FCP.CONCURRENT_PROGRAM_NAME = 'DKA_RAPVIR_PDF'
               AND FCR.STATUS_CODE = 'E'
               AND FCR.REQUEST_ID > fnd_global.CONC_REQUEST_ID
               AND FCR.ARGUMENT4 = ACA.CHECK_ID;

        rec_prog_error cur_prog_error%ROWTYPE;
        vn_sleep       NUMBER;
    BEGIN

        g_step := 'EDITION_OUTPUT 000 : DEBUT';
        log_msg(g_step);

        --Recuperation des informations
        BEGIN
            --Récupération du nom de la base de données.
            SELECT name INTO gv_base FROM v$database;

            --Recuperation du nom de l'application.
            SELECT fa.application_short_name
              INTO l_appl
              FROM fnd_application fa
             WHERE fa.application_id = fnd_profile.VALUE('RESP_APPL_ID');

            --Recuperation du nom du programme.
            SELECT v.PROGRAM
              INTO l_prgm_name
              FROM fnd_conc_req_summary_v v
             WHERE v.REQUEST_ID = fnd_global.CONC_REQUEST_ID;

        EXCEPTION
            WHEN OTHERS THEN
                l_appl := '';
        END;

        --ENTETE
        l_out := 'Environnement   : ' || gv_base || chr(10) ||
                 'Application     : ' || l_appl || chr(10) ||
                 'Programme       : ' || l_prgm_name || chr(10) ||
                 'Utilisateur     : ' || fnd_profile.VALUE('USERNAME') ||
                 chr(10) || 'Date            : ' ||
                 to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || chr(10);
        out_msg(l_out);

        out_msg(l_ligne);

        --CORPS
        l_out := 'Liste des règlements :';
        out_msg(l_out);
        out_msg(l_ligne);
        l_out := '| ' || RPAD('Id règlement', 15) || ' | ' ||
                 RPAD('Num règlement', 15) || ' | ' || RPAD('Société', 9) ||
                 ' | ' || RPAD('Région', 8) || ' | ' ||
                 RPAD('Identifiant du fournisseur', 28) || ' | ' ||
                 RPAD('Identifiant du site fournisseur', 33) || ' |';
        out_msg(l_out);
        OPEN cur_avis_virement;
        LOOP
            FETCH cur_avis_virement
                INTO rec_avis_virement;
            EXIT WHEN cur_avis_virement%NOTFOUND;
            l_out := '| ' || RPAD(rec_avis_virement.CHECK_ID, 15) || ' | ' ||
                     RPAD(rec_avis_virement.CHECK_NUMBER, 15) || ' | ' ||
                     RPAD(rec_avis_virement.SOCIETE, 9) || ' | ' ||
                     RPAD(rec_avis_virement.REGION, 8) || ' | ' ||
                     RPAD(rec_avis_virement.VENDOR_ID, 28) || ' | ' ||
                     RPAD(rec_avis_virement.VENDOR_SITE_ID, 33) || ' |';
            out_msg(l_out);
        END LOOP;
        CLOSE cur_avis_virement;

    --EDB295
    --CORPS
	    out_msg(l_ligne);
        l_out := 'Liste des règlements de type Remboursement Clients :';
        out_msg(l_out);
        out_msg(l_ligne);
        l_out := '| ' || RPAD('Id règlement', 15) || ' | ' ||
                 RPAD('Num règlement', 15) || ' | ' || RPAD('Société', 9) ||
                 ' | ' || RPAD('Région', 8) || ' | ' ||
                 RPAD('Identifiant du client', 28) || ' | ' ||
                 RPAD('Identifiant du site client', 33) || ' |';
        out_msg(l_out);
        OPEN cur_avis_vir_rbt;
        LOOP
            FETCH cur_avis_vir_rbt
                INTO rec_avis_vir_rbt;
            EXIT WHEN cur_avis_vir_rbt%NOTFOUND;
            l_out := '| ' || RPAD(rec_avis_vir_rbt.CHECK_ID, 15) || ' | ' ||
                     RPAD(rec_avis_vir_rbt.CHECK_NUMBER, 15) || ' | ' ||
                     RPAD(rec_avis_vir_rbt.SOCIETE, 9) || ' | ' ||
                     RPAD(rec_avis_vir_rbt.REGION, 8) || ' | ' ||
                     RPAD(rec_avis_vir_rbt.cust_account_id, 28) || ' | ' ||
                     RPAD(rec_avis_vir_rbt.PARTY_SITE_ID, 33) || ' |';
            out_msg(l_out);
        END LOOP;
        CLOSE cur_avis_vir_rbt;

    --END EDB295



        out_msg(l_ligne);
        l_out := 'Liste des traitements "DKA : Création du fichier avis de virement" en erreur :';
        out_msg(l_out);
        out_msg(l_ligne);

        l_out := '| ' || RPAD('Id règlement', 15) || ' | ' ||
                 RPAD('Num règlement', 15) || ' | ' ||
                 RPAD('Date de règlement', 10) || ' | ' ||
                 RPAD('Nom du programme', 15) || ' | ' ||
                 RPAD('Id programme', 15) || ' |';
        out_msg(l_out);
        OPEN cur_prog_error;
        LOOP
            FETCH cur_prog_error
                INTO rec_prog_error;
            EXIT WHEN cur_prog_error%NOTFOUND;
            l_out := '| ' || RPAD(rec_prog_error.CHECK_ID, 15) || ' | ' ||
                     RPAD(rec_prog_error.CHECK_NUMBER, 15) || ' | ' ||
                     RPAD(rec_prog_error.CHECK_DATE, 10) || ' | ' ||
                     RPAD(rec_prog_error.CONCURRENT_PROGRAM_NAME, 15) ||
                     ' | ' || RPAD(rec_prog_error.PRIORITY_REQUEST_ID, 15) || ' |';
            out_msg(l_out);
            p_retcode := 1;
            p_errbuf  := 'Erreur lors de l''execution du traitement d''identifiant : ' ||
                         rec_prog_error.PRIORITY_REQUEST_ID;
            log_msg(p_errbuf);
        END LOOP;
        CLOSE cur_prog_error;

        vn_sleep := 0;

        select count(1)
          into vn_sleep
          from FND_CONC_REQ_SUMMARY_V FC
         where FC.PROGRAM_SHORT_NAME = 'DKA_SAPVIR_ATTACH'
           AND FC.STATUS_CODE = 'E'
           AND FC.REQUEST_ID > fnd_global.CONC_REQUEST_ID;

        IF vn_sleep > 0 THEN
            p_retcode := 1;
            p_errbuf  := 'Erreur lors de l''execution du traitement de rattachement des avis de virement.';
            log_msg(p_errbuf);
            out_msg(p_errbuf);
        END IF;

        vn_sleep := 0;

        select count(1)
          into vn_sleep
          from FND_CONC_REQ_SUMMARY_V FC
         where FC.PROGRAM_SHORT_NAME = 'DKA_SAPVIR_MAIL'
           AND FC.STATUS_CODE = 'E'
           AND FC.REQUEST_ID > fnd_global.CONC_REQUEST_ID;

        IF vn_sleep > 0 THEN
            p_retcode := 1;
            p_errbuf  := 'Erreur lors de l''execution du traitement d''envoi par mail des avis de virement.';
            log_msg(p_errbuf);
            out_msg(p_errbuf);
        END IF;

        g_step := 'EDITION_OUTPUT 999 : FIN';
        log_msg(g_step);
    EXCEPTION
        WHEN OTHERS THEN
            p_retcode := 2;
            p_errbuf  := 'Erreur procedure EDITION_OUTPUT :' || g_step ||
                         chr(10) || SQLERRM;
            log_msg(p_errbuf);
    END edition_output;

    ----------------------------------------------------------------------------
    --  Nom           : main
    --  Description   : procédure principale
    --
    --
    --  PARAMETRES :
    --    p_errbuf     Entrée/Sortie   Message d'erreur
    --    p_retcode  Sortie      Code d'erreur
    --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
    ----------------------------------------------------------------------------

    PROCEDURE main(p_errbuf IN OUT VARCHAR2, p_retcode OUT NUMBER) IS
        CURSOR cur_avis_virement(pv_status VARCHAR2) IS
            SELECT distinct ACA.CHECK_ID,
                            ACA.CHECK_NUMBER,
                            DIAH.SOCIETE,
                            DIAH.REGION,
                            DIAL.VENDOR_ID,
                            DIAL.VENDOR_SITE_ID
              FROM DKA_IEOAPSAT01_APIMP_LINE DIAL
                 , DKA_IEOAPSAT01_APIMP_HDR  DIAH
                 , AP_CHECKS_ALL             ACA
                 , IBY_EXT_BANK_ACCOUNTS     IEBC --RBE MigR12
                 , iby_payments_all          IPA -- ajout 03/09/25 pour l'iban
             WHERE DIAH.HEADER_ID = DIAL.HEADER_ID
               AND DIAH.STATUS = pv_status
               AND ACA.CHECK_DATE = DIAL.TRANSACTIONDATE -- Date de règlement.
               --AND ACA.Vendor_Id = DIAL.Vendor_Id --EDB295
               --AND ACA.VENDOR_SITE_ID = DIAL.Vendor_Site_Id --EDB295
--         AND NVL(ACA.Vendor_Id,'-1') = NVL(DIAL.Vendor_Id,'-1') --EDB295 -- 11/07/2025 : on enleve totalement le test
--               AND NVL(ACA.VENDOR_SITE_ID,'-1') = NVL(DIAL.Vendor_Site_Id,'-1') --EDB295 -- 11/07/2025 : on enleve totalement le test
               AND ACA.CHECKRUN_NAME = DIAL.CHECKRUN_NAME
--               AND IEBC.IBAN = DIAL.CPTYSECONDARYACCOUNTNUMBER --RBE MigR12
               AND IPA.ext_bank_account_iban_number = DIAL.CPTYSECONDARYACCOUNTNUMBER -- 03/09/25 : on prend l'iban de IBY
               AND ACA.VENDOR_NAME = DIAL.COUNTERPARTYNAME -- 03/09/25 :on joint le fournisseur par son nom , faute de mieux
                  -- RG5 - Pas de génération de fichier pour les notes de frais.
               AND IPA.PAYMENT_ID = ACA.PAYMENT_ID -- 03/09/25 : ajout table
               AND DIAL.CHECKRUN_NAME not like '%EMPVIR'
               AND ACA.STATUS_LOOKUP_CODE = 'NEGOTIABLE'
               AND ACA.external_bank_account_id  = IEBC.ext_bank_account_id--RBE MigR12
             ORDER BY DIAH.SOCIETE,
                      DIAH.REGION,
                      DIAL.VENDOR_ID,
                      DIAL.VENDOR_SITE_ID;



        rec_avis_virement cur_avis_virement%ROWTYPE;

        vn_org_id_tra NUMBER;
        vn_org_id     NUMBER := fnd_profile.value('ORG_ID');
        vv_status     DKA_IEOAPSAT01_APIMP_HDR.STATUS%TYPE;
        pv_errbuf     VARCHAR2(200);
        pn_retcode    NUMBER;
        vn_sleep      NUMBER;

        e_main EXCEPTION;
        e_boucle EXCEPTION;

    BEGIN
        g_step := 'MAIN 000 : DEBUT';
        log_msg(g_step);
        -- Initialisation des variables d'envoi de mail :
        g_step := 'MAIN 001 : INITIALISATION DES VARIABLES D''ENVOI DE MAIL.';
        log_msg(g_step);
        vn_sleep := 1;
        EXECUTE IMMEDIATE 'DELETE FROM DKA_SAPVIR_ATTACH_TMP';

        --RBE MigR12
        --- 17/10/2013 BCO DGE20130021 - Recherche de l'ensemble des organisations.
        /*BEGIN
            select hou.organization_id
              into vn_org_id_tra
              from hr_all_organization_units_tl hou
             where name = 'TRANSPORT_OPE'
               and language = 'F';
        EXCEPTION
            WHEN OTHERS then
                dka_tools_pkg.put_outdebug_message('Erreur lors de la recherche de l''organization_id de VEOLIA TRANSPORT ');
                dka_tools_pkg.put_outdebug_message(SQLERRM);
        END;*/

        --IF vn_org_id_tra = vn_org_id THEN
        --    vv_status := 'NEW';
        --ELSE
            vv_status := 'PRINT';
        --END IF;

        OPEN cur_avis_virement(vv_status);
        LOOP
            FETCH cur_avis_virement
                INTO rec_avis_virement;
            EXIT WHEN cur_avis_virement%NOTFOUND;
            BEGIN
                pn_retcode := 0;

                g_step := 'MAIN 002 : LANCEMENT DU TRAITEMENT DKA : Création du fichier avis de virement.';
                log_msg(g_step);
                lance_trait_pdf(rec_avis_virement.CHECK_ID,
                                gv_rapvir_pdf,
                                pv_errbuf,
                                pn_retcode);
                IF pn_retcode != 0 THEN
                    g_step := 'MAIN 002 : ERREUR - ERREUR LORS DE L''EXECUTION DU TRAITEMENT DKA : Création du fichier avis de virement.';
                    RAISE e_boucle;
                END IF;
            EXCEPTION
                WHEN e_boucle THEN
                    p_errbuf  := g_step;
                    p_retcode := 1;
            END;
        END LOOP;
        CLOSE cur_avis_virement;

        WHILE vn_sleep != 0 LOOP
            DBMS_LOCK.sleep(5);
            select COUNT(1)
              into vn_sleep
              from FND_CONC_REQ_SUMMARY_V FC
             where FC.PROGRAM_SHORT_NAME = 'DKA_RAPVIR_PDF'
               and FC.PHASE_CODE != 'C';
        END LOOP;

        vn_sleep := 1;
        g_step   := 'MAIN 003 : LANCEMENT DU TRAITEMENT DKA : Rattachement de l''avis de virement au règlement AP.';
        log_msg(g_step);
        lance_trait_attach(gv_sapvir_attach, pv_errbuf, pn_retcode);

        g_step := 'MAIN 004 : LANCEMENT DU TRAITEMENT DKA : Envoi avis de virement par mail.';
        log_msg(g_step);
        lance_trait_mail(gv_sapvir_mail, pv_errbuf, pn_retcode);

        WHILE vn_sleep != 0 LOOP
            DBMS_LOCK.sleep(5);
            select count(1)
              into vn_sleep
              from FND_CONC_REQ_SUMMARY_V FC
             where (FC.PROGRAM_SHORT_NAME = 'DKA_SAPVIR_ATTACH' or
                   FC.PROGRAM_SHORT_NAME = 'DKA_SAPVIR_MAIL')
               and FC.PHASE_CODE != 'C';
        END LOOP;

        g_step := 'MAIN 005 : EDITION FICHIER DE SORTIE.';
        log_msg(g_step);
        --procedure d'edition de la sortie
        edition_output(pv_errbuf, pn_retcode);
--        IF pn_retcode != 0 THEN
--            RAISE e_main;
--        END IF;

        g_step := 'MAIN 006 : RECHERCHE DU STATUS DU TRAITEMENT.';
        log_msg(g_step);
    vn_sleep := 0;
    BEGIN
    select COUNT(1)
      into vn_sleep
          from FND_CONC_REQ_SUMMARY_V FC
         where FC.PROGRAM_SHORT_NAME = 'DKA_SAPVIR_MAIL'
       and FC.PARENT_REQUEST_ID = FND_GLOBAL.CONC_REQUEST_ID
       and FC.STATUS_CODE = 'E';
    EXCEPTION
        WHEN OTHERS THEN
         vn_sleep := 0;
    END;
    IF vn_sleep = 0 THEN
    BEGIN
      select COUNT(1)
        into vn_sleep
        from FND_CONC_REQ_SUMMARY_V FC
       where FC.PARENT_REQUEST_ID = FND_GLOBAL.CONC_REQUEST_ID
         and FC.STATUS_CODE IN ('G', 'E');
    EXCEPTION
        WHEN OTHERS THEN
         vn_sleep := 0;
    END;
      IF vn_sleep > 0 THEN
        p_retcode := 1;
      END IF;
    ELSE
      p_retcode := 2;
    END IF;

        g_step := 'MAIN 999 - FIN.';
        log_msg(g_step);
    EXCEPTION
        WHEN e_main THEN
            p_errbuf := g_step || SQLERRM;
            log_msg(pv_errbuf);
            p_retcode := 2;
        WHEN OTHERS THEN
            p_errbuf := 'MAIN 999 - ERREUR : PROCEDURE MAIN ' || SQLERRM;
            log_msg(pv_errbuf);
            p_retcode := 2;
    END main;

END DKA_SAPAUTOVIR_PKG;

/
SHOW ERRORS
EXIT
