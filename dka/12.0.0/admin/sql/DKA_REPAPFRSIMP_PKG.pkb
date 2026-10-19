create or replace PACKAGE BODY DKA_REPAPFRSIMP_PKG IS
    ----------------------------------------------------------------------
    -- PROGRAM : DKA_REPAPFRSIMP_PKG.sql                                 -
    -- Version : 1.0                                                     -
    -- AUTEUR  : Y.Warid / SOCIETE : CAPGEMINI                           -
    -- DATE    : 15/03/16                                                -
    ----------------------------------------------------------------------
    -- APPELE PAR : Reprise AP fournisseurs Import                       -
    -- FONCTION   : SFD001                                               -
    --                                                                   -
    --                                                                   -
    ----------------------------------------------------------------------
    -- VERSION              :        1.1                                 -
    -- PROGRAMME MODIFIE LE :        18/01/2017                          -
    -- PAR                  :        Maxime EGOT                         -
    -- NUM_ANOMALIE         :        artf2081167                         -
    --                               artf2084658                         -
    --                               artf2085558                         -
    -- OBJET                :                                            -
    ----------------------------------------------------------------------
    -- VERSION              :        1.2                                 -
    -- PROGRAMME MODIFIE LE :        24/01/2017                          -
    -- PAR                  :        Maxime EGOT                         -
    -- NUM_ANOMALIE         :        artf2089052                         -
    --                               artf2089030                         -
    --                               artf2088797                         -
    -- OBJET                :                                            -
    ----------------------------------------------------------------------
    ----------------------------------------------------------------------
    -- VERSION              :        1.3                                 -
    -- PROGRAMME MODIFIE LE :        13/02/2017                          -
    -- PAR                  :        Younes WARID                        -
    -- NUM_ANOMALIE         :        artf2099969                         -
    -- OBJET                :                                            -
    ----------------------------------------------------------------------
    ----------------------------------------------------------------------
    -- VERSION              :        1.4                                 -
    -- PROGRAMME MODIFIE LE :        08/03/2017                          -
    -- PAR                  :        Maxime EGOT                         -
    -- NUM_ANOMALIE         :        artf2089196                         -
    -- OBJET                :                                            -
    ----------------------------------------------------------------------
    ----------------------------------------------------------------------
    -- VERSION              :        1.5                                 -
    -- PROGRAMME MODIFIE LE :        17/03/2017                          -
    -- PAR                  :        YWA                         -
    -- NUM_ANOMALIE         :        artf2123523                         -
    -- OBJET                :                                            -
    ----------------------------------------------------------------------
    ----------------------------------------------------------------------
    -- VERSION              :        1.6                                 -
    -- PROGRAMME MODIFIE LE :        22/03/2017                          -
    -- PAR                  :        Maxime EGOT                         -
    -- NUM_ANOMALIE         :        artf2124119                         -
    -- OBJET                :        Alimentation auto_taxt_calc_flag    -
    ----------------------------------------------------------------------
    -- VERSION              :        1.7                                 -
    -- PROGRAMME MODIFIE LE :        04/08/2017                          -
    -- PAR                  :        Younes WARID                        -
    -- NUM_ANOMALIE         :        artf2207564                          -
    -- OBJET                :        Alimenter le champ "email_address" dans l'open interface    -
    ----------------------------------------------------------------------
    -- VERSION              :        1.8                                 -
    -- PROGRAMME MODIFIE LE :        04/09/2017                          -
    -- PAR                  :        Redouane BELAYACHI                  -
    -- NUM_ANOMALIE         :        artf2217916,artf2213926             -
    -- OBJET                :        EDB080 - Fournisseurs groupe externe -
    --                      :        EDB071 - reprise "société mère" sur entête fournisseur -
    ------------------------------------------------------------------------
    -- VERSION              :        1.9                                 -
    -- PROGRAMME MODIFIE LE :        26/09/2017                          -
    -- PAR                  :        Younes WARID                   -
    -- NUM_ANOMALIE         :        artf2227406                                           -
    -- OBJET                :        Fonctionnement de la procédure "liste_des_anomalies"         -
    ------------------------------------------------------------------------
     --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PRIVEES
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    g_user_id                      fnd_user.user_id%TYPE;
    g_login_id                     fnd_logins.login_id%TYPE;
    g_org_id                       hr_all_organization_units.organization_id%TYPE;
    g_request_id                   fnd_concurrent_requests.request_id%TYPE;
    g_loader_request_id            fnd_concurrent_requests.request_id%TYPE;
    g_import_request_id            fnd_concurrent_requests.request_id%TYPE;
    g_tempo                        NUMBER;

    g_nb_fournisseur_cree_oi            NUMBER     :=0;
    g_nb_four_factor_cree_oi            NUMBER    :=0;
    g_nb_site_fournisseur_cree_oi       NUMBER    :=0;
    g_nb_site_four_factor_cree_oi       NUMBER    :=0;
    g_nb_conatct_cree_oi                NUMBER    :=0;
    g_nb_conatct_factor_cree_oi         NUMBER    :=0;

    g_nb_conatct_charger                NUMBER    :=0;
    g_nb_fournisseur_charger            NUMBER    :=0;
    g_nb_site_four_charger              NUMBER    :=0;
    g_nb_bank_charger                   NUMBER    :=0;

    g_nb_fournisseur_cree              NUMBER     :=0;
    g_nb_four_factor_cree              NUMBER    :=0;
    g_nb_site_fournisseur_cree         NUMBER    :=0;
    g_nb_site_four_factor_cree         NUMBER    :=0;
    g_nb_conatct_cree                  NUMBER    :=0;
    g_nb_conatct_factor_cree           NUMBER    :=0;

    g_nb_bank_cree                    NUMBER    :=0;
    g_nb_agence_cree                  NUMBER    :=0;
    g_nb_compte_cree                  NUMBER    :=0;
    
    g_validate_banque_err           NUMBER    :=0;
    g_validate_fournisseur_err      NUMBER    :=0;
    g_validate_site_four_err        NUMBER    :=0;
    g_validate_contact_site_f_err   NUMBER    :=0;
    
    g_nb_rejet_f        NUMBER    :=0;
    g_nb_rejet_sf       NUMBER    :=0;
    g_nb_rejet_csf      NUMBER    :=0;
    g_dup_logical_line_num NUMBER    :=0;

    g_message_erreur_chargement                 VARCHAR2(1000)    :=null;
    
    type rec_request is record( request_id number,
		                            interval   number,
                                max_wait   number,
                                phase      varchar2(80),
                                status     varchar2(80),
                                dev_phase  varchar2(15),
                                dev_status varchar2(15),
                                message    varchar2(255));
                                
    type tab_request is table of rec_request index by binary_integer;
    g_tab_site_requests   tab_request;

    /*
    *************************************************************************
    * PROCEDURE NAME : init
    *
    * DESCRIPTION
    *  Procédure d'initialisation des variables globales
    *
    * PARAMETERS
    * ==========
    * NAME              DESCRIPTION
    .* ----------------- ------------------------------------------------------
    * p_errbuf         Retour de message éventuel
    * p_retcode        Statut du traitement en sortie
    ************************************************************************
    */

    PROCEDURE init (
        p_errbuf    OUT      VARCHAR2,
        p_retcode   OUT      NUMBER
        )
    IS

        v_procedure   VARCHAR2(30);
        program_error             EXCEPTION;

    BEGIN

        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut init');


        ----------------------------------
        -- Initialisation des variables --
        ----------------------------------
        p_errbuf  := NULL;
        p_retcode := 0;
        v_procedure := 'INIT';


        ------------------------
        -- Variables globales --
        ------------------------

        g_login_id                     := fnd_global.login_id;
        g_request_id                   := fnd_global.conc_request_id;
        --g_org_id                       := fnd_profile.value ('ORG_ID');
        g_tempo                        := 20;
        g_user_id                    :=   fnd_global.user_id;

        /*BEGIN
            SELECT user_id
            INTO   g_user_id
            FROM  fnd_user
            WHERE user_name ='CAPTECH' ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                p_errbuf:= 'Erreur user CAPTECH introuvable ';
                Dka_Tools_Pkg.put_log_message(p_errbuf);
                p_retcode := 2;
                RAISE program_error;
            WHEN OTHERS THEN
                p_errbuf:= SQLERRM;
                Dka_Tools_Pkg.put_log_message(p_errbuf);
                p_retcode := 2;
                RAISE program_error;
        END;*/

      --Reinit des messages d'erreur
      UPDATE dka_ap_rep_supp_tmp
      SET message_erreur = NULL
      where processed_request_id = -1;
      
      UPDATE dka_ap_rep_supp_sites_tmp
      SET message_erreur = NULL
      where processed_request_id = -1;
      
      UPDATE dka_ap_rep_supp_sites_ctct_tmp
      SET message_erreur = NULL
      where processed_request_id = -1;
      
      UPDATE DKA_AP_REP_SUPP_BANK_TMP
      SET message_erreur = NULL
      where processed_request_id = -1;
      
      commit;
      
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin init');




    EXCEPTION
        WHEN program_error THEN
             Dka_Tools_Pkg.put_log_message( 'ERREUR : ' || p_errbuf);
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := v_procedure ||': '||SQLERRM;
    END init;

     /*
    *************************************************************************
    * PROCEDURE NAME : init_environement
    *
    * DESCRIPTION
    *  Procédure d'initialisation de l'environnement
    *
    * PARAMETERS
    * ==========
    * NAME              DESCRIPTION
    .* ----------------- ------------------------------------------------------
    * p_errbuf         Retour de message éventuel
    * p_retcode        Statut du traitement en sortie
    ************************************************************************
    */

    PROCEDURE init_environement(p_errbuf   OUT VARCHAR2,
                                p_retcode  OUT NUMBER,
                                p_resp_key IN  VARCHAR2)
    IS
        v_resp_id                               NUMBER;
        v_resp_appl_id                          NUMBER;
    BEGIN
        
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut init_environement');
        
        p_retcode   := 0;

        /*SELECT responsibility_id
              ,responsibility_application_id
        INTO   v_resp_id
               ,v_resp_appl_id
        FROM
        (
                    SELECT  furg.responsibility_id,
                            furg.responsibility_application_id
                    FROM    FND_PROFILE_OPTIONS       fpo,
                            FND_PROFILE_OPTION_VALUES fpov,
                            FND_USER_RESP_GROUPS      furg
                    WHERE  1 = 1
                    AND    fpov.APPLICATION_ID       = fpo.APPLICATION_ID
                    AND    fpov.PROFILE_OPTION_ID    = fpo.PROFILE_OPTION_ID
                    AND    fpov.PROFILE_OPTION_VALUE = TO_CHAR(g_org_id)
                    AND    fpo.PROFILE_OPTION_NAME   = 'ORG_ID'
                    AND    fpov.LEVEL_ID             = 10003
                    AND    furg.responsibility_application_id = fpov.LEVEL_VALUE_APPLICATION_ID
                    AND    furg.responsibility_id       = fpov.LEVEL_VALUE
                    AND    furg.USER_ID                 = g_user_id
                    AND    furg.START_DATE              <= SYSDATE
                    AND    nvl(furg.END_DATE,SYSDATE+1) >= SYSDATE
                    AND    furg.responsibility_application_id = 200 -- AP
                    ORDER BY furg.responsibility_id ASC

            )
        WHERE ROWNUM = 1; --Car on ne veut qu'une seule responsabilité
        */
        /*SELECT responsibility_id
              ,application_id
        INTO   v_resp_id
              ,v_resp_appl_id
        FROM  fnd_responsibility fr,
              hr_operating_units hou
        WHERE hou.organization_id = g_org_id
        AND   fr.responsibility_key = hou.name||'_AP_ADMINISTRATEUR'; */--YWA TRS   
        SELECT responsibility_id,
               application_id
        INTO v_resp_id,
             v_resp_appl_id
        FROM fnd_responsibility fr
        WHERE fr.responsibility_key = p_resp_key;--'TOUT_AP_ADMINISTRATEUR';

        fnd_global.apps_initialize(g_user_id, v_resp_id, v_resp_appl_id);--YWA TRS
        MO_GLOBAL.INIT ('SQLAP');
        Dka_Tools_Pkg.put_log_message('Environnement initialisé avec la responsabilité '||p_resp_key);

        -- Initialiser org_id
        --mo_global.set_org_context(g_org_id,NULL,'SQLAP');--YWA TRS 
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin init_environement');
    EXCEPTION
      WHEN program_error THEN
        Dka_Tools_Pkg.put_log_message( 'ERREUR : ' || p_errbuf);
      WHEN NO_DATA_FOUND THEN
        p_retcode   := 1;
        p_errbuf    := 'init_environement: '||SQLERRM;
        Dka_Tools_Pkg.put_log_message( 'ERREUR : ' || p_errbuf );-- pour L''UO ' ||g_org_id);--YWA TRS
      WHEN OTHERS THEN
        p_retcode   := 2;
        p_errbuf    := 'init_environement: '||SQLERRM;

    END init_environement;
    /*
    *************************************************************************
    * PROCEDURE NAME : Launch_Loader
    *
    * DESCRIPTION
    *  Procédure de lancement du programme de chargement dans la table spécifique
    *
    * PARAMETERS
    * ==========
    * NAME               DESCRIPTION
    .* -----------------  ------------------------------------------------------
    * p_directory       Répertoire du fichier
    * p_file_name       Nom du fichier a charger
    * p_errbuf          Retour de message éventuel
    * p_retcode         Statut du traitement en sortie
    *
    ************************************************************************
    */
    PROCEDURE Launch_Loader(p_Errbuf            OUT VARCHAR2,
                          p_retcode           OUT NUMBER
                          )
    IS
        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
        v_message                VARCHAR2 (100);

    BEGIN
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut Launch_Loader');
        --Dka_Tools_Pkg.put_outdebug_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));

        Dka_Tools_Pkg.put_log_message( CHR(10));
        Dka_Tools_Pkg.put_log_message( 'CHARGEMENT DU FICHIER :');
        Dka_Tools_Pkg.put_log_message( '----------------------');
        ------------------------------------------------------
        -- Lancement du traitement de chargement du fichier --
        ------------------------------------------------------

        -- Lancement du traitement
        g_loader_request_id          := Fnd_Request.submit_request (
                                             'DKA'                            -- APPL
                                            ,'DKA_REPAPFRSIMP_LOADER'                -- PROG
                                            ,NULL                             -- PROGRAM_NAME
                                            ,NULL                             -- START
                                            ,FALSE                            -- SUB_REQUEST
                                            );
        
        Dka_Tools_Pkg.put_outdebug_message( 'Le N°du traitement de chargement des données dans les tables spécifiques :' || g_loader_request_id);
        
        IF g_loader_request_id = 0
        THEN
            p_retcode    := 2;
            Dka_Tools_Pkg.put_outdebug_message( 'ERREUR : Le traitement de chargement du fichier a échoué' || CHR(10) ||
                                            'PROGRAMME  : DKA_REPAPFRSIMP_LOADER');
            Dka_Tools_Pkg.put_log_message( '====> ERREUR : Le traitement de chargement du fichier a échoué');
        ELSE
            COMMIT;
            --Dka_Tools_Pkg.put_outdebug_message( '=> LOAD REQUEST ID= ' || g_loader_request_id);
            --Dka_Tools_Pkg.put_log_message( 'Numéro du traitement de chargement du fichier : ' || g_loader_request_id);
            -- Attente de la fin du traitement
            IF NOT (Fnd_Concurrent.wait_for_request (g_loader_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
            THEN
                p_Errbuf  := v_message;
                Dka_Tools_Pkg.put_outdebug_message( 'ERREUR : Attente de la fin du programme de chargement du fichier dépassée : Fin du traitement' || CHR(10) ||
                                                'MESSAGE : ' || v_message || CHR(10) );
            END IF;

            IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL')
            THEN
                Dka_Tools_Pkg.put_outdebug_message( 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
                Dka_Tools_Pkg.put_log_message( 'Statut de fin : ' || v_phase || '/' || v_status);

                null;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
            THEN
                Dka_Tools_Pkg.put_outdebug_message( 'Fin du traitement de chargement en warning '|| g_loader_request_id);
                p_retcode    := 1;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')
            THEN
                p_retcode := 2;
                p_Errbuf  := 'ERREUR : Fin anormale du traitement de chargement : '||v_message;

                Dka_Tools_Pkg.put_outdebug_message( 'ERREUR : Fin anormale du traitement de chargement '|| g_loader_request_id  || CHR(10) ||
                                                'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                                'MESSAGE : ' || v_message || CHR(10) );
                Dka_Tools_Pkg.put_log_message( '===> ERREUR : Fin anormale du traitement de chargement '||g_loader_request_id);
            END IF;

        END IF;

        SELECT count(*) INTO g_nb_fournisseur_charger FROM dka_ap_rep_supp_tmp where load_request_id=g_loader_request_id;

        SELECT count(*) INTO g_nb_site_four_charger FROM dka_ap_rep_supp_sites_tmp WHERE load_request_id=g_loader_request_id;

        SELECT count(*) INTO g_nb_conatct_charger FROM dka_ap_rep_supp_sites_ctct_tmp WHERE  load_request_id=g_loader_request_id;

        SELECT count(*) INTO g_nb_bank_charger FROM dka_ap_rep_supp_bank_tmp where load_request_id=g_loader_request_id;



        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Launch_Loader');

    EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'LAUNCH_LOADER : ' ||SQLERRM;
            Dka_Tools_Pkg.put_log_message( p_errbuf);
            Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Launch_Loader : EXCEPTION OTHERS ');
    END Launch_Loader;


    /*
    *************************************************************************
    * PROCEDURE NAME : Bilan
    *
    * DESCRIPTION
    *  Procédure de génération du bilan du traitement
    *
    * PARAMETERS
    * ==========
    * NAME                 DESCRIPTION
    .* -------------------- -------------------------------------------------
    * p_errbuf            Retour de message éventuel
    * p_retcode           Statut du traitement en sortie
    ************************************************************************
    */
    PROCEDURE Report_Bilan(p_Errbuf            OUT VARCHAR2,
                         p_retcode           OUT NUMBER
                         )
    IS

    BEGIN

        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut Report_Bilan');

        --------------------
        -- Initialisation --
        --------------------

        p_Errbuf  := NULL;
        p_retcode := 0;


        Dka_Tools_Pkg.put_outdebug_message(CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('-----------------------------------------------------BILAN-------------------------------------------------------------------------');
        Dka_Tools_Pkg.put_outdebug_message('-----------------------------------------------------------------------------------------------------------------------------------');
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans la table spécifique des fournisseurs            : ' || TO_CHAR(g_nb_fournisseur_charger)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans la table spécifique des sites fournisseurs      : ' || TO_CHAR(g_nb_site_four_charger)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans la table spécifique des contacts fournisseurs   : ' || TO_CHAR(g_nb_conatct_charger)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans la table spécifique des comptes bancaires       : ' || TO_CHAR(g_nb_bank_charger)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('-----------------------------------------------------------------------------------------------------------------------------------');
        
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements non chargés dans l''OI des fournisseurs             : ' || TO_CHAR(g_validate_fournisseur_err)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements non chargés dans l''OI des sites fournisseurs       : ' || TO_CHAR(g_validate_site_four_err)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements non chargés dans l''OI des contacts fournisseurs    : ' || TO_CHAR(g_validate_contact_site_f_err)||CHR(10));
        
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans l''OI des fournisseurs             : ' || TO_CHAR(g_nb_fournisseur_cree_oi)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans l''OI des sites fournisseurs       : ' || TO_CHAR(g_nb_site_fournisseur_cree_oi)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans l''OI des contacts fournisseurs    : ' || TO_CHAR(g_nb_conatct_cree_oi)||CHR(10)); 
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans l''OI des fournisseurs FACTOR          : ' || TO_CHAR(g_nb_four_factor_cree_oi)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans l''OI des sites fournisseurs FACTOR    : ' || TO_CHAR(g_nb_site_four_factor_cree_oi)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans l''OI des contacts fournisseurs FACTOR : ' || TO_CHAR(g_nb_conatct_factor_cree_oi)||CHR(10));
        
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements rejetés par le traitement standard des fournisseurs             : ' || TO_CHAR(g_nb_rejet_f)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements rejetés par le traitement standard des sites fournisseurs       : ' || TO_CHAR(g_nb_rejet_sf)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements rejetés par le traitement standard des contacts fournisseurs    : ' || TO_CHAR(g_nb_rejet_csf)||CHR(10));
        
        Dka_Tools_Pkg.put_outdebug_message(' *Voir les sorties des traitements d''Open interface pour avoir plus de détails sur les enregistrements rejetés.');
        Dka_Tools_Pkg.put_outdebug_message(CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('-----------------------------------------------------------------------------------------------------------------------------------');
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans la table des fournisseurs           : ' || TO_CHAR(g_nb_fournisseur_cree)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans la table des sites fournisseurs     : ' || TO_CHAR(g_nb_site_fournisseur_cree)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans la table des contacts fournisseurs  : ' || TO_CHAR(g_nb_conatct_cree)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre de comptes bancaires créés                                          : ' || TO_CHAR(g_nb_compte_cree)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('   . Nombre de comptes bancaires avec des erreurs                               : ' || TO_CHAR(g_validate_banque_err));





        Dka_Tools_Pkg.put_log_message(CHR(10));
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Report_Bilan');


    EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'REPORT_BILAN : ' ||SQLERRM;
            Dka_Tools_Pkg.put_log_message( p_errbuf);
            Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
    END Report_Bilan;

    /*
    *************************************************************************
    * PROCEDURE NAME : liste_des_anomalies
    *
    * DESCRIPTION
    *  Procédure de génération de la liste des anomalies
    *
    * PARAMETERS
    * ==========
    * NAME                 DESCRIPTION
    .* -------------------- -------------------------------------------------
    * p_errbuf            Retour de message éventuel
    * p_retcode           Statut du traitement en sortie
    ************************************************************************
    */
    PROCEDURE liste_des_anomalies(p_Errbuf            OUT VARCHAR2,
                         p_retcode           OUT NUMBER
                         )
    IS
        cv_line                     VARCHAR2 (5000);
        
        CURSOR cur_err_fournisseur
        IS
            SELECT segment1,
                    LOGICAL_LINE_NUM num_id,
                    'VAL' niveau,
                    message_erreur
            FROM dka_ap_rep_supp_tmp
            WHERE message_erreur    IS NOT NULL
            AND processed_request_id = -1
            UNION
            SELECT PARENT_CODE segment1,
                    PARENT_ID num_id,
                    'OI' niveau,
                    message_text message_erreur
            FROM DKA_AP_REP_SUPP_REJECTION
            WHERE parent_table = 'AP_SUPPLIERS_INT'
            ORDER BY   niveau desc ,num_id asc;

        CURSOR cur_err_sf
        IS
            SELECT SEGMENT1,VENDOR_SITE_CODE,
                    LOGICAL_LINE_NUM num_id,
                    'VAL' niveau,
                    NULL  org,
                    message_erreur
            FROM DKA_AP_REP_SUPP_SITES_TMP
            WHERE message_erreur    IS NOT NULL
            AND processed_request_id = -1
            UNION
            SELECT  asi.segment1,
                    PARENT_CODE VENDOR_SITE_CODE,
                    PARENT_ID num_id,
                    'OI' niveau,
                    assi.org_id,
                    message_text message_erreur
            FROM 
             DKA_AP_REP_SUPP_REJECTION,
             ap_supplier_sites_int assi,
             ap_suppliers_int asi 
            WHERE parent_table = 'AP_SUPPLIER_SITES_INT'
            and assi.vendor_site_interface_id = PARENT_ID
            AND asi.vendor_interface_id = assi.vendor_interface_id
            AND asi.vendor_type_lookup_code IN ('VENDOR','PARTENAIRE', 'EXTERNAL  PARTNER') --YWA artf2227406 
            ORDER BY  niveau desc ,num_id asc;

        CURSOR cur_err_csf
        IS
            SELECT  SEGMENT1,
                    VENDOR_SITE_CODE, 
                    LAST_NAME,
                    LOGICAL_LINE_NUM num_id,
                    'VAL' niveau,
                    NULL  org,
                    message_erreur
            FROM DKA_AP_REP_SUPP_SITES_CTCT_TMP
            WHERE message_erreur    IS NOT NULL
            AND processed_request_id = -1
            UNION
            SELECT  asi.segment1,
                    vendor_site_code,
                    PARENT_CODE,
                    PARENT_ID num_id,
                    'OI' niveau,
                    operating_unit_name  org,
                    message_text message_erreur
            FROM DKA_AP_REP_SUPP_REJECTION,
                 AP_SUP_SITE_CONTACT_INT assci,
                 ap_suppliers_int asi 
            WHERE parent_table = 'AP_SUP_SITE_CONTACT_INT'
            and assci.vendor_contact_interface_id = PARENT_ID
            and assci.vendor_interface_id = asi.vendor_interface_id
           AND asi.vendor_type_lookup_code IN ('VENDOR','PARTENAIRE', 'EXTERNAL  PARTNER') --YWA artf2227406
            ORDER BY  niveau desc ,num_id asc;

        CURSOR cur_err_b
        IS
            SELECT segment1,
                  vendor_site_code,
                    bank_account_num,
                    logical_line_num ,
                    message_erreur
            FROM dka_ap_rep_supp_bank_tmp
            WHERE message_erreur    IS NOT NULL
            AND processed_request_id = -1
            ORDER BY logical_line_num;
        
    BEGIN

        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut liste_des_anomalies');

        --------------------
        -- Initialisation --
        --------------------

        p_Errbuf  := NULL;
        p_retcode := 0;


        Dka_Tools_Pkg.put_outdebug_message(CHR(10));

        cv_line := 'Etat des erreurs des fournisseurs:';
        Dka_Tools_Pkg.put_outdebug_message( CHR(10)||cv_line);
        cv_line := '-----------------';
        Dka_Tools_Pkg.put_outdebug_message( cv_line);
        cv_line := 'Num Fournisseur  Ligne/interface_id     Niveau    Message d''erreur';
        Dka_Tools_Pkg.put_outdebug_message( cv_line);
        cv_line := '---------------  ---------------------  -------  ------------------------------';
        Dka_Tools_Pkg.put_outdebug_message( cv_line);
        
        FOR c_err_f IN cur_err_fournisseur LOOP
            cv_line := RPAD(c_err_f.segment1,15,' ') ||'  '||RPAD(NVL(to_char(c_err_f.num_id),' '),21,' ') ||'  '||RPAD(NVL(c_err_f.niveau,' '),7,' ') ||'  ' || replace(c_err_f.message_erreur,CHR(10),' ');
            Dka_Tools_Pkg.put_outdebug_message( cv_line);
        END LOOP;    
        -----------------------------------------------------------------------------------------------------------------------------------------------------
        Dka_Tools_Pkg.put_outdebug_message( '--------------------------------------------------------------------------------------------------------------------');
        cv_line := 'Etat des erreurs des sites fournisseurs:';
        Dka_Tools_Pkg.put_outdebug_message( CHR(10)||cv_line);
        cv_line := '-----------------';
        Dka_Tools_Pkg.put_outdebug_message( cv_line);
        cv_line := 'Num Fournisseur  Vendor site code    Org_id   Ligne/interface_id     Niveau   Message d''erreur';
        Dka_Tools_Pkg.put_outdebug_message( cv_line);
        cv_line := '---------------  ------------------  ------   ---------------------  -------  ------------------------------';
        Dka_Tools_Pkg.put_outdebug_message( cv_line);
        FOR c_err_sf IN cur_err_sf LOOP
            cv_line := RPAD(c_err_sf.SEGMENT1,15,' ') ||'  '||
                       RPAD(c_err_sf.vendor_site_code,18,' ') ||'  '||
                       RPAD(c_err_sf.org,7,' ') ||'  '||
                       RPAD(NVL(to_char(c_err_sf.num_id),' '),21,' ') ||'  '||
                       RPAD(NVL(c_err_sf.niveau,' '),7,' ') ||'  ' || replace(c_err_sf.message_erreur,CHR(10),' ');
            Dka_Tools_Pkg.put_outdebug_message( cv_line);
        END LOOP;    
         
        -----------------------------------------------------------------------------------------------------------------------------------------------------
        Dka_Tools_Pkg.put_outdebug_message( '--------------------------------------------------------------------------------------------------------------------');
        cv_line := 'Etat des erreurs des contacts fournisseurs:';
        Dka_Tools_Pkg.put_outdebug_message( CHR(10)||cv_line);
        cv_line := '-----------------';
        Dka_Tools_Pkg.put_outdebug_message( cv_line);
        cv_line := 'Num Fournisseur  Vendor site code   Org_id   last_name             Ligne/interface_id     Niveau   Message d''erreur';
        Dka_Tools_Pkg.put_outdebug_message( cv_line);
        cv_line := '---------------  -----------------  ------   --------------------  ---------------------  -------  ------------------------------';
        Dka_Tools_Pkg.put_outdebug_message( cv_line);
        FOR c_err_csf IN cur_err_csf LOOP
            cv_line := RPAD(c_err_csf.SEGMENT1,15,' ') ||'  '||
                       RPAD(c_err_csf.vendor_site_code,18,' ') ||'  '||
                       RPAD(c_err_csf.org,7,' ') ||'  '||
                       RPAD(c_err_csf.last_name,20,' ') ||'  '||
                       RPAD(NVL(to_char(c_err_csf.num_id),' '),21,' ') ||'  '||
                       RPAD(NVL(c_err_csf.niveau,' '),7,' ') ||'  ' || 
                       replace(c_err_csf.message_erreur,CHR(10),' ');
            Dka_Tools_Pkg.put_outdebug_message( cv_line);
        END LOOP;
        -----------------------------------------------------------------------------------------------------------------------------------------------------
        Dka_Tools_Pkg.put_outdebug_message( '--------------------------------------------------------------------------------------------------------------------');
        cv_line := 'Etat des erreurs des comptes bancaire:';
        Dka_Tools_Pkg.put_outdebug_message( CHR(10)||cv_line);
        cv_line := '-----------------';
        Dka_Tools_Pkg.put_outdebug_message( cv_line);
        cv_line := 'Num Fournisseur  Vendor site code   Num compte       Ligne       Message d''erreur';
        Dka_Tools_Pkg.put_outdebug_message( cv_line);
        cv_line := '---------------  -----------------  ---------------  ----------  ------------------------------';
        Dka_Tools_Pkg.put_outdebug_message( cv_line);
        FOR c_err_b IN cur_err_b LOOP
            cv_line := RPAD(c_err_b.segment1,15,' ') ||'  '||
                       RPAD(c_err_b.vendor_site_code,18,' ') ||'  '||
                       RPAD(c_err_b.bank_account_num,15,' ') ||'  '||
                       RPAD(NVL(to_char(c_err_b.logical_line_num),' '),10,' ') ||'  ' || 
                       replace(c_err_b.message_erreur,CHR(10),' ') ;
            Dka_Tools_Pkg.put_outdebug_message( cv_line);
        END LOOP;
        -----------------------------------------------------------------------------------------------------------------------------------------------------
        
        
        
        Dka_Tools_Pkg.put_log_message(CHR(10));
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin liste_des_anomalies');


    EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'liste_des_anomalies : ' ||SQLERRM;
            Dka_Tools_Pkg.put_log_message( p_errbuf);
            Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure liste_des_anomalies : EXCEPTION OTHERS ');
    END liste_des_anomalies;

    /*=========================================================================*/
    /* PROCEDURE NAME :   program_import_fournisseur
    /*
    /* DESCRIPTION  Traitement standard d'import des fournisseurs
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/

    PROCEDURE program_import_fournisseur(    p_errbuf            OUT VARCHAR2,
                                            p_retcode           OUT NUMBER)
    IS

        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
        v_message                VARCHAR2 (100);
        v_nb_rejet               NUMBER :=0;
        v_nb_ok                     NUMBER :=0;


    BEGIN
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut program_import_fournisseur');
    
        g_import_request_id:= FND_REQUEST.SUBMIT_REQUEST
                               (Application => 'SQLAP'
                               ,Program     => 'APXSUIMP'
                               ,Description => NULL
                               ,Start_time  => SYSDATE
                               ,Sub_Request => FALSE
                               ,Argument1   => 'ALL'
                               ,Argument2   => 1000
                               ,Argument3   => 'N'
                               ,Argument4   => 'N'
                               ,Argument5   => 'N'
                               );

        Dka_Tools_Pkg.put_outdebug_message('Le N°du traitement du traitement standard d''import de fournisseurs : ' || g_import_request_id);
        IF g_import_request_id = 0 THEN

            p_retcode    := 2;
            Dka_Tools_Pkg.put_outdebug_message( 'ERREUR : Le traitement standard d''import des fournisseurs' || CHR(10) ||
                                            'PROGRAMME  : Importation de l''interface coopérative fournisseur');
            Dka_Tools_Pkg.put_log_message( '====> ERREUR : Le traitement standard d''import des fournisseurs ');
            v_message :=' ERREUR : Le traitement standard d''import des fournisseurs ';
        ELSE
            COMMIT;
            --Dka_Tools_Pkg.put_outdebug_message( '=> LOAD REQUEST ID= ' || g_import_request_id);
            --Dka_Tools_Pkg.put_log_message( 'Numéro du traitement standard d''import des fournisseurs: ' || g_import_request_id);


            --********************************************
            -- Wait for the concurrent program to complete
            --********************************************
            IF NOT (Fnd_Concurrent.wait_for_request (g_import_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message)) THEN

                p_errbuf  := v_message;
                Dka_Tools_Pkg.put_outdebug_message( 'ERREUR : Attente de la fin du programme  dépassée : Fin du traitement' || CHR(10) ||
                                                'MESSAGE : ' || v_message || CHR(10) );
            END IF;

            IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN

                Dka_Tools_Pkg.put_outdebug_message( 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
                Dka_Tools_Pkg.put_log_message( 'Statut de fin : ' || v_phase || '/' || v_status);


                SELECT     count(vendor_interface_id)
                INTO     v_nb_ok
                FROM     ap_suppliers_int
                WHERE      status ='PROCESSED'
                AND     import_request_id = g_import_request_id;

                SELECT     count(vendor_interface_id)
                INTO     v_nb_rejet
                FROM     ap_suppliers_int
                WHERE  status ='REJECTED';
                --AND import_request_id = g_import_request_id;

                --Dka_Tools_Pkg.put_log_message('Nombre de fournisseurs correctement créé: '||v_nb_ok );
                --Dka_Tools_Pkg.put_log_message('Nombre de fournisseurs en rejet: '||v_nb_rejet );
                g_nb_rejet_f := v_nb_rejet;
                g_nb_fournisseur_cree:= v_nb_ok;
                IF v_nb_rejet !=0 THEN
                    /*Dka_Tools_Pkg.put_log_message('------------------Liste des fournisseurs en rejet -----------------------');
                    FOR rejections IN (SELECT     asi.vendor_interface_id,
                                                asi.segment1,
                                                fnm.message_name,
                                                fnm.message_text
                                        FROM     ap_supplier_int_rejections asir,
                                                ap_suppliers_int asi,
                                                fnd_new_messages fnm
                                        WHERE asi.status ='REJECTED'
                                        AND asi.vendor_interface_id= asir.parent_id
                                        AND fnm.message_name=asir.reject_lookup_code
                                        AND language_code = 'F'
                                        --AND import_request_id = g_import_request_id
                                        AND asir.parent_table='AP_SUPPLIERS_INT')
                    LOOP

                        Dka_Tools_Pkg.put_log_message('vendor_interface_id: '||rejections.vendor_interface_id);
                        Dka_Tools_Pkg.put_log_message('Numéro du fournisseur : '||rejections.segment1);
                        Dka_Tools_Pkg.put_log_message('Message d''erreur : '||rejections.message_text);

                    END LOOP;*/
                    p_retcode    := 1;
                    --Sauvegarde des rejets:
                    INSERT INTO DKA_AP_REP_SUPP_REJECTION
                    SELECT   asi.vendor_interface_id,
                          asi.segment1,
                          asir.parent_table,
                          fnm.message_name,
                          fnm.message_text,
                          g_request_id
                    FROM    ap_supplier_int_rejections asir,
                          ap_suppliers_int asi,
                          fnd_new_messages fnm
                    WHERE asi.status ='REJECTED'
                    AND asi.vendor_interface_id= asir.parent_id
                    AND fnm.message_name=asir.reject_lookup_code
                    AND language_code = 'F'
                    AND asir.parent_table='AP_SUPPLIERS_INT';
                END IF;
                

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN

                Dka_Tools_Pkg.put_outdebug_message( 'Fin du traitement standard d''import des fournisseurs en warning '|| g_import_request_id);
                v_message  := 'ERREUR : Fin du traitement en warning: '||v_message;
                p_retcode    := 1;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN

                p_retcode := 2;
                v_message  := 'ERREUR : Fin anormale du traitement standard d''import des fournisseurs : '||v_message;

                Dka_Tools_Pkg.put_outdebug_message( 'ERREUR : Fin anormale du traitement '|| g_import_request_id  || CHR(10) ||
                                                'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                                'MESSAGE : ' || v_message || CHR(10) );
                --Dka_Tools_Pkg.put_log_message( '===> ERREUR : Fin anormale du traitement '||g_import_request_id);
            END IF;
            p_errbuf :=v_message;

        END IF;
        
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin program_import_fournisseur');

    END program_import_fournisseur;

    /*=========================================================================*/
    /* PROCEDURE NAME :   program_import_site_four
    /*
    /* DESCRIPTION      :  Traitement standard d'import des sites fournisseurs
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/

    PROCEDURE program_import_site_four( p_errbuf   OUT VARCHAR2,
                                        p_retcode  OUT NUMBER)
    IS

      v_message                VARCHAR2 (100);

    BEGIN
    
      Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut program_import_site_four ');--pour l''UO : '||g_org_id);--YWA TRS
      g_import_request_id := Fnd_Request.submit_request (
                                             'SQLAP'                          -- APPL
                                            ,'APXSSIMP'                       -- PROG
                                            ,NULL                             -- PROGRAM_NAME
                                            ,NULL                             -- START
                                            ,FALSE                            -- SUB_REQUEST
                                            ,NULL--g_org_id                   -- Unité opérationnelle
                                            ,'ALL'                            -- Options d'importation
                                            ,1000                             -- Taille de lot
                                            ,'N'                              -- Imprimer les exceptions uniquement
                                            ,'N'                              -- Activer diagnostic
                                            ,'N'                              -- Activer analyse
                                            );
        
      Dka_Tools_Pkg.put_outdebug_message('Le N°du traitement du traitement standard d''import des sites fournisseurs '|| g_import_request_id);
        
      IF g_import_request_id = 0 THEN

          p_retcode    := 2;
          Dka_Tools_Pkg.put_outdebug_message( 'ERREUR : Le traitement standard d''import des sites fournisseurs' || CHR(10) ||
                                          'PROGRAMME  : Importation de l''interface coopérative des sites fournisseurs');
          Dka_Tools_Pkg.put_log_message( '====> ERREUR : Le traitement standard d''import des  sites fournisseurs ');
          v_message :=' ERREUR : Le traitement standard d''import des sites fournisseurs ';
      ELSE
          COMMIT;
          g_tab_site_requests(g_import_request_id).request_id := g_import_request_id;
          g_tab_site_requests(g_import_request_id).interval := g_tempo;
          g_tab_site_requests(g_import_request_id).max_wait := 0;
          --Dka_Tools_Pkg.put_outdebug_message( '=> LOAD REQUEST ID= ' || g_import_request_id);
          --Dka_Tools_Pkg.put_log_message( 'Numéro du traitement standard d''import des sites fournisseurs: ' || g_import_request_id);
      END IF;
      p_errbuf :=v_message;
      
    END program_import_site_four;
          
    /*=========================================================================
      PROCEDURE NAME : wait_sites_import
      DESCRIPTION      :  Attendre la fin des Traitements standard d'import des sites fournisseurs
    =========================================================================*/
    PROCEDURE wait_sites_import( p_errbuf  OUT VARCHAR2,
                                 p_retcode OUT NUMBER)
    IS
      v_phase            VARCHAR2 (100);
      v_status           VARCHAR2 (100);
      v_dev_phase        VARCHAR2 (100);
      v_dev_status       VARCHAR2 (100);
      v_message          VARCHAR2 (100);
      v_nb_ok            NUMBER;
      --v_nb_rejet         NUMBER;
      
      i                  BINARY_INTEGER; 
    
    BEGIN    
    
      i := g_tab_site_requests.first;
      WHILE i IS NOT NULL LOOP
        
        IF NOT Fnd_Concurrent.wait_for_request (g_tab_site_requests(i).request_id, 
                                                g_tab_site_requests(i).interval,
                                                g_tab_site_requests(i).max_wait, 
                                                v_phase, 
                                                v_status, 
                                                v_dev_phase, 
                                                v_dev_status, 
                                                v_message) THEN
          p_errbuf  := v_message;
          Dka_Tools_Pkg.put_outdebug_message( 'ERREUR : Attente de la fin du programme dépassée : Fin du traitement' || CHR(10) ||
                                             'MESSAGE : ' || v_message || CHR(10) );
        END IF;

        IF v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL' THEN

          Dka_Tools_Pkg.put_outdebug_message( 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);

          SELECT count(vendor_site_interface_id)
          INTO v_nb_ok
          FROM ap_supplier_sites_int
          WHERE status ='PROCESSED'
          --AND org_id = g_org_id
            AND import_request_id = g_tab_site_requests(i).request_id;

          g_nb_site_fournisseur_cree := g_nb_site_fournisseur_cree + v_nb_ok;

        ELSIF v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING' THEN

          Dka_Tools_Pkg.put_outdebug_message( 'Fin du traitement standard d''import des sites fournisseurs en warning '|| g_tab_site_requests(i).request_id);
          v_message  := 'ERREUR : Fin du traitement en warning: '||v_message;
          p_retcode    := 1;

        ELSIF v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL' THEN

          p_retcode := 2;
          v_message  := 'ERREUR : Fin anormale du traitement standard d''import des sites fournisseurs : '||v_message;

          Dka_Tools_Pkg.put_outdebug_message( 'ERREUR : Fin anormale du traitement '|| g_tab_site_requests(i).request_id  || CHR(10) ||
                                              'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                              'MESSAGE : ' || v_message || CHR(10) );
          --Dka_Tools_Pkg.put_log_message( '===> ERREUR : Fin anormale du traitement '||g_import_request_id);
        END IF;
            
        p_errbuf :=v_message;
        i := g_tab_site_requests.next(i);
      END LOOP;
      
      -- Récupération du nombre sites en rejet
      SELECT count(vendor_site_interface_id)
      INTO g_nb_rejet_sf
      FROM ap_supplier_sites_int
      WHERE status ='REJECTED';
        
      IF g_nb_rejet_sf !=0 THEN
      
        --Sauvegarde des rejets:
        INSERT INTO DKA_AP_REP_SUPP_REJECTION
        SELECT assi.vendor_site_interface_id,
               assi.vendor_site_code,
               asir.parent_table,
               fnm.message_name,
               fnm.message_text,
               g_request_id
          FROM ap_supplier_int_rejections asir,
               ap_supplier_sites_int      assi,
               fnd_new_messages           fnm
          WHERE assi.status ='REJECTED'
            AND assi.vendor_site_interface_id= asir.parent_id
            AND fnm.message_name=asir.reject_lookup_code
            AND language_code = 'F'
            AND asir.parent_table='AP_SUPPLIER_SITES_INT';
            
        p_retcode    := 1;
      END IF;

    END wait_sites_import;

    /*=========================================================================*/
    /* PROCEDURE NAME :   program_import_contact_four
    /*
    /* DESCRIPTION  :   Traitement standard d'import des contacts sites fournisseurs
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/

    PROCEDURE program_import_contact_four(    p_errbuf            OUT VARCHAR2,
                                     p_retcode           OUT NUMBER)
    IS

        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
        v_message                VARCHAR2 (100);
    v_nb_ok                 NUMBER;
    v_nb_rejet            number;


    BEGIN
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut program_import_contact_four' );--pour l''UO : '||g_org_id);
        g_import_request_id := Fnd_Request.submit_request (
                                             'SQLAP'                          -- APPL
                                            ,'APXSCIMP'                       -- PROG
                                            ,NULL                             -- PROGRAM_NAME
                                            ,NULL                             -- START
                                            ,FALSE                            -- SUB_REQUEST
                                            --,g_org_id                        -- Unité opérationnelle
                                            ,'ALL'                            -- Options d'importation
                                            ,1000                             -- Taille de lot
                                            ,'N'                              -- Imprimer les exceptions uniquement
                                            ,'N'                              -- Activer diagnostic
                                            ,'N'                              -- Activer analyse
                                            );
        
        Dka_Tools_Pkg.put_outdebug_message('Le N°du traitement du traitement standard d''import des contacts sites fournisseurs '|| g_import_request_id); --dans UO '||g_org_id ||' : '|| g_import_request_id);
        
        IF g_import_request_id = 0 THEN

            p_retcode    := 2;
            Dka_Tools_Pkg.put_outdebug_message( 'ERREUR : Le traitement standard d''import des contacts site fournisseur' || CHR(10) ||
                                            'PROGRAMME  : Importation de l''interface coopérative des contacts fournisseurs');
            --Dka_Tools_Pkg.put_log_message( '====> ERREUR : Le traitement standard d''import des contacts site fournisseur ');
            v_message :=' ERREUR : Le traitement standard d''import des fournisseurs ';
        ELSE
            COMMIT;
            --Dka_Tools_Pkg.put_outdebug_message( '=> LOAD REQUEST ID= ' || g_import_request_id);
            --Dka_Tools_Pkg.put_log_message( 'Numéro du traitement standard d''import des contacts site fournisseur: ' || g_import_request_id);


            --********************************************
            -- Wait for the concurrent program to complete
            --********************************************
            IF NOT (Fnd_Concurrent.wait_for_request (g_import_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message)) THEN

                p_errbuf  := v_message;
                Dka_Tools_Pkg.put_outdebug_message( 'ERREUR : Attente de la fin du programme  dépassée : Fin du traitement' || CHR(10) ||
                                                'MESSAGE : ' || v_message || CHR(10) );
            END IF;

            IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN

                Dka_Tools_Pkg.put_outdebug_message( 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
                --Dka_Tools_Pkg.put_log_message( 'Statut de fin : ' || v_phase || '/' || v_status);
                SELECT     count(vendor_contact_interface_id)
                INTO     v_nb_ok
                FROM     ap_sup_site_contact_int
                WHERE      status ='PROCESSED'
                --AND     org_id = g_org_id
                AND     import_request_id = g_import_request_id;

                SELECT     count(vendor_contact_interface_id)
                INTO     v_nb_rejet
                FROM     ap_sup_site_contact_int
                WHERE   status ='REJECTED';
                --AND     org_id = g_org_id ;
                --AND     import_request_id = g_import_request_id;

                --Dka_Tools_Pkg.put_log_message('Nombre de contacts de site fournisseur correctement créé: '||v_nb_ok );
                --Dka_Tools_Pkg.put_log_message('Nombre de contacts de site fournisseur en rejet: '||v_nb_rejet );
                g_nb_conatct_cree := g_nb_conatct_cree+v_nb_ok;
                g_nb_rejet_csf := g_nb_rejet_csf+v_nb_rejet;
                IF v_nb_rejet !=0 THEN
                    /*Dka_Tools_Pkg.put_log_message('------------------Liste des contacts de site fournisseur en rejet -----------------------');
                    FOR rejections IN (SELECT     assci.vendor_contact_interface_id,
                                                assci.last_name,
                                                fnm.message_name,
                                                fnm.message_text
                                        FROM     ap_supplier_int_rejections asir,
                                                ap_sup_site_contact_int assci,
                                                fnd_new_messages fnm
                                        WHERE assci.status ='REJECTED'
                                        AND assci.vendor_contact_interface_id= asir.parent_id
                                        AND fnm.message_name=asir.reject_lookup_code
                                        AND language_code = 'F'
                                        AND assci.org_id = g_org_id
                                        AND asir.parent_table='AP_SUP_SITE_CONTACT_INT')
                    LOOP

                        Dka_Tools_Pkg.put_log_message('vendor_contact_interface_id: '||rejections.vendor_contact_interface_id);
                        Dka_Tools_Pkg.put_log_message('Nom du contact du site fournisseur : '||rejections.last_name);
                        Dka_Tools_Pkg.put_log_message('Message d''erreur : '||rejections.message_text);

                    END LOOP;*/
                    
                    --Sauvegarde des rejets:
                    INSERT INTO DKA_AP_REP_SUPP_REJECTION
                     SELECT   assci.vendor_contact_interface_id,
                              assci.last_name,
                              asir.parent_table,
                              fnm.message_name,
                              fnm.message_text,
                              g_request_id
                      FROM    ap_supplier_int_rejections asir,
                              ap_sup_site_contact_int assci,
                              fnd_new_messages fnm
                      WHERE assci.status ='REJECTED'
                      AND assci.vendor_contact_interface_id= asir.parent_id
                      AND fnm.message_name=asir.reject_lookup_code
                      AND language_code = 'F'
                      --AND assci.org_id = g_org_id
                      AND asir.parent_table='AP_SUP_SITE_CONTACT_INT';
                    
                    p_retcode    := 1;
                END IF;
            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN

                Dka_Tools_Pkg.put_outdebug_message( 'Fin du traitement standard d''import des contacts site fournisseur en warning '|| g_import_request_id);
                v_message  := 'ERREUR : Fin du traitement en warning: '||v_message;
                p_retcode    := 1;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN

                p_retcode := 2;
                v_message  := 'ERREUR : Fin anormale du traitement standard d''import des contacts site fournisseur : '||v_message;

                Dka_Tools_Pkg.put_outdebug_message( 'ERREUR : Fin anormale du traitement '|| g_import_request_id  || CHR(10) ||
                                                'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                                'MESSAGE : ' || v_message || CHR(10) );
                --Dka_Tools_Pkg.put_log_message( '===> ERREUR : Fin anormale du traitement '||g_import_request_id);
            END IF;
            p_errbuf :=v_message;

        END IF;
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin program_import_contact_four' );

    END program_import_contact_four;
    /*=========================================================================*/
    /* PROCEDURE NAME : purge_data
    /*
    /* DESCRIPTION
    /*  Purge des donner des opens interfaces
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/
    PROCEDURE purge_data
    IS
    v_current_program_unit   VARCHAR2(30);

    BEGIN
        v_current_program_unit := 'purge_data';
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - début ' || v_current_program_unit);

        /*DELETE
        FROM   AP_SUPPLIERS_INT
        WHERE  status = 'REJECTED';
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||'-> AP_SUPPLIERS_INT : '||SQL%ROWCOUNT);

        DELETE
        FROM   AP_SUPPLIER_SITES_INT
        WHERE  status = 'REJECTED';
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||'-> AP_SUPPLIER_SITES_INT : '||SQL%ROWCOUNT);

        DELETE
        FROM   AP_SUP_SITE_CONTACT_INT
        WHERE  status = 'REJECTED' OR status IS NULL;
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||'-> ap_sup_site_contact_int : '||SQL%ROWCOUNT);*/
        
         -- Réinitialisation des champs de suivi pour recharger les contacts frs en erreur dans l'OI

        UPDATE DKA_AP_REP_SUPP_SITES_CTCT_TMP dar
        SET    processed_request_id = -1
              ,message_erreur = NULL
        WHERE EXISTS ( SELECT 'x'
                       FROM AP_SUP_SITE_CONTACT_INT assc,
                            AP_SUPPLIER_SITES_ALL assi,
                            AP_SUPPLIERS asup
                       WHERE asup.vendor_id = assi.vendor_id
                       AND   assc.vendor_site_id = assi.vendor_site_id
                       AND   asup.segment1 = dar.segment1
                       AND   substr(assc.operating_unit_name,1,3)||'-'||assi.vendor_site_code like dar.vendor_site_code||'%'
                       AND   assc.first_name = dar.first_name
                       AND   assc.last_name = dar.last_name
                       AND   assc.status = 'REJECTED');

        -- Suppression des contacts en erreur dans OI
        DELETE
        FROM   AP_SUP_SITE_CONTACT_INT
        WHERE  status = 'REJECTED' OR status IS NULL;
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||'-> ap_sup_site_contact_int : '||SQL%ROWCOUNT);

        -- Réinitialisation des champs de suivi pour recharger les frs en erreur dans l'OI
        -- Elle est effectuée des qu'au moins 1 site dupliqué n'est pas passé
        UPDATE DKA_AP_REP_SUPP_SITES_TMP darsst
        SET    processed_request_id = -1
              ,vendor_site_interface_id = NULL
              ,message_erreur = NULL
        WHERE EXISTS (SELECT 'x'
                      FROM   AP_SUPPLIER_SITES_INT assi
                            ,AP_SUPPLIERS_INT asi
                      WHERE  asi.vendor_interface_id = assi.vendor_interface_id
                      AND    asi.segment1 = darsst.segment1
                      AND    substr(assi.operating_unit_name,1,3)||'-'||assi.vendor_site_code like darsst.vendor_site_code||'%'
                      AND    assi.status = 'REJECTED' );

        -- Suppression des sites frs en erreur dans OI
        DELETE
        FROM   AP_SUPPLIER_SITES_INT
        WHERE  status = 'REJECTED';
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||'-> AP_SUPPLIER_SITES_INT : '||SQL%ROWCOUNT);



        -- Réinitialisation des champs de suivi pour recharger les données en erreur dans l'OI
        UPDATE DKA_AP_REP_SUPP_TMP
        SET    processed_request_id = -1
              ,vendor_interface_id = NULL
              ,message_erreur = NULL
        WHERE vendor_interface_id IN (SELECT vendor_interface_id
                                      FROM   AP_SUPPLIERS_INT
                                      WHERE  status = 'REJECTED');
        
        -- Suppression des en-tetes frs en erreur dans OI
        DELETE
        FROM   AP_SUPPLIERS_INT
        WHERE  status = 'REJECTED';
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||'-> AP_SUPPLIERS_INT : '||SQL%ROWCOUNT);
        
        
        DELETE
        FROM   AP_SUPPLIER_INT_REJECTIONS;

        DELETE
        FROM DKA_AP_REP_SUPP_REJECTION;

        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||'-> ap_sup_site_contact_int : '||SQL%ROWCOUNT);

        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - fin ' || v_current_program_unit);
    END purge_data;
    /*=========================================================================*/
    /* PROCEDURE NAME : to_az
    /*
    /* DESCRIPTION
    /*  Procédure de génération de lettre alphabet
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /* p_num               numéro de la lettre
    /*
     /*=========================================================================*/

    FUNCTION     to_az(p_num     NUMBER)
    RETURN     VARCHAR2
    DETERMINISTIC
    IS
        num          PLS_INTEGER  := TRUNC (p_num) - 1;
        return_txt     VARCHAR2 (1) := CHR (65 + MOD (num, 26));
    BEGIN
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début to_az');
        IF  num <= 25 THEN
          RETURN     return_txt;
        ELSE
          RETURN     to_az (FLOOR (num / 26))|| return_txt;
        END IF;
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin to_az');
    END to_az;

    /*=========================================================================*/
    /* PROCEDURE NAME : validate_fournisseur
    /*
    /* DESCRIPTION
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/
    PROCEDURE validate_fournisseur( p_vendor_num         VARCHAR2
                                ,p_logical_line_num         NUMBER
                                ,p_vendor_interface_id         NUMBER
                                ,p_erreur             BOOLEAN
                                ,p_errbuf            OUT VARCHAR2
                                ,p_retcode           OUT NUMBER)
    IS

    BEGIN
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_fournisseur');
        IF p_erreur THEN

            --Dka_Tools_Pkg.put_log_message('ERREUR lors de la validation du fournisseur numero: '||p_vendor_num);
            --Dka_Tools_Pkg.put_log_message('Cause:'||g_message_erreur_chargement);
            g_validate_fournisseur_err := g_validate_fournisseur_err+1;
            BEGIN
                UPDATE dka_ap_rep_supp_tmp
                SET    message_erreur = substr(nvl2(message_erreur,message_erreur||chr(10),NULL)||g_message_erreur_chargement,1,500),
                       vendor_interface_id = NULL,
                       processed_request_id = -1,
                       last_update_date = SYSDATE
                WHERE  segment1 = p_vendor_num
                AND    logical_line_num = p_logical_line_num ;
            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
            END;

        ELSE

            BEGIN
                UPDATE dka_ap_rep_supp_tmp
                SET    processed_request_id = g_request_id,
                       vendor_interface_id = p_vendor_interface_id,
                       message_erreur = NULL,
                       last_update_date = SYSDATE
                WHERE  segment1 = p_vendor_num
                AND    logical_line_num = p_logical_line_num ;
            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
            END;

        END IF;
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_fournisseur');
    END validate_fournisseur;

    /*=========================================================================*/
    /* PROCEDURE NAME : validate_site_fournisseur
    /*
    /* DESCRIPTION
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/
    PROCEDURE validate_site_fournisseur( p_vendor_num         VARCHAR2
                                ,p_vendor_site_code         VARCHAR2
                                ,p_logical_line_num      NUMBER
                                ,p_vendor_site_interface_id NUMBER
                                ,p_erreur             BOOLEAN
                                ,p_errbuf            OUT VARCHAR2
                                ,p_retcode           OUT NUMBER)
    IS

    BEGIN
    
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_site_fournisseur');
        IF p_erreur THEN

            --Dka_Tools_Pkg.put_log_message('ERREUR lors de la validation du site fournisseur numero: '||p_vendor_site_code);
            --Dka_Tools_Pkg.put_log_message('Cause:'||g_message_erreur_chargement);
            g_validate_site_four_err := g_validate_site_four_err+1;
            BEGIN
                UPDATE dka_ap_rep_supp_sites_tmp
                SET    message_erreur = substr(nvl2(message_erreur,message_erreur||chr(10),NULL)||g_message_erreur_chargement,1,500),
                        vendor_site_interface_id=p_vendor_site_interface_id,
                        processed_request_id = -1,
                        last_update_date = SYSDATE
                WHERE  segment1 = p_vendor_num
                AND    vendor_site_code = p_vendor_site_code
                AND    logical_line_num = p_logical_line_num;
                
                UPDATE dka_dup_site_fournisseur
                SET     processed_request_id = -1,
                        last_update_date = SYSDATE
                WHERE  segment1 = p_vendor_num
                AND    vendor_site_code = p_vendor_site_code
                AND    logical_line_num = g_dup_logical_line_num;
                
                
            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
            END;

        ELSE

            BEGIN
                UPDATE dka_ap_rep_supp_sites_tmp
                SET    processed_request_id = g_request_id,
                        message_erreur = NULL,
                        last_update_date = SYSDATE,
                        vendor_site_interface_id=p_vendor_site_interface_id
                WHERE  segment1 = p_vendor_num
                AND    vendor_site_code = p_vendor_site_code
                AND    logical_line_num = p_logical_line_num;
                
                UPDATE dka_dup_site_fournisseur
                SET     processed_request_id = g_request_id,
                        last_update_date = SYSDATE
                WHERE  segment1 = p_vendor_num
                AND    vendor_site_code = p_vendor_site_code
                AND    logical_line_num = g_dup_logical_line_num;
                
                
            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
            END;

        END IF;
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_site_fournisseur');
    END validate_site_fournisseur;


    /*=========================================================================*/
    /* PROCEDURE NAME : validate_contact_site_f
    /*
    /* DESCRIPTION
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/
    PROCEDURE validate_contact_site_f( p_vendor_num         VARCHAR2
                                ,p_vendor_site_code         VARCHAR2
                                ,p_logical_line_num      NUMBER
                                ,p_last_name        VARCHAR2
                                ,p_erreur             BOOLEAN
                                ,p_errbuf            OUT VARCHAR2
                                ,p_retcode           OUT NUMBER)
    IS

    BEGIN
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_contact_site_f');
        IF p_erreur THEN

            --Dka_Tools_Pkg.put_log_message('ERREUR lors de la validation du contact'||p_last_name||' du site fournisseur numero: '||p_vendor_site_code);
            --Dka_Tools_Pkg.put_log_message('Cause:'||g_message_erreur_chargement);
            g_validate_contact_site_f_err := g_validate_contact_site_f_err+1;
            BEGIN
                UPDATE dka_ap_rep_supp_sites_ctct_tmp
                SET    message_erreur = substr(nvl2(message_erreur,message_erreur||chr(10),NULL)||g_message_erreur_chargement,1,500),
                      processed_request_id = -1,
                      last_update_date = SYSDATE
                WHERE  segment1 = p_vendor_num
                AND    vendor_site_code = p_vendor_site_code
                AND    logical_line_num = p_logical_line_num;
                --and     last_name=p_last_name;
            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
            END;

        ELSE

            BEGIN
                UPDATE dka_ap_rep_supp_sites_ctct_tmp
                SET    processed_request_id = g_request_id,
                        message_erreur = NULL,
                        last_update_date = SYSDATE
                WHERE  segment1 = p_vendor_num
                AND    vendor_site_code = p_vendor_site_code
                AND    logical_line_num = p_logical_line_num;
            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
            END;

        END IF;
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_contact_site_f');
    END validate_contact_site_f;

    /*=========================================================================*/
    /* PROCEDURE NAME : validate_banque
    /*
    /* DESCRIPTION
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/
    PROCEDURE validate_banque(     p_vendor_num         VARCHAR2
                                ,p_vendor_site_code         VARCHAR2
                                --,p_bank_account_name    VARCHAR2
                                ,p_logical_line_num      NUMBER
                                ,p_erreur             BOOLEAN
                                ,p_errbuf            OUT VARCHAR2
                                ,p_retcode           OUT NUMBER)
    IS

    BEGIN
    
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_banque');
        IF p_erreur THEN

            --Dka_Tools_Pkg.put_log_message('ERREUR lors de la validation du compte bancaire'||p_bank_account_name);
            --Dka_Tools_Pkg.put_log_message('Cause:'||g_message_erreur_chargement);
            BEGIN
                UPDATE dka_ap_rep_supp_bank_tmp
                SET    message_erreur = substr(nvl2(message_erreur,message_erreur||chr(10),NULL)||g_message_erreur_chargement,1,500),
                       processed_request_id=-1,
                       last_update_date = SYSDATE
                WHERE  segment1 = p_vendor_num
                AND    vendor_site_code = p_vendor_site_code
                AND    logical_line_num = p_logical_line_num;
            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
            END;

        ELSE

            BEGIN
                UPDATE dka_ap_rep_supp_bank_tmp
                SET    processed_request_id = g_request_id,
                        message_erreur = NULL,
                        last_update_date = SYSDATE
                WHERE  segment1 = p_vendor_num
                AND    vendor_site_code = p_vendor_site_code
                AND    logical_line_num = p_logical_line_num;
            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
            END;

        END IF;
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_banque');
    END validate_banque;
    /*=========================================================================*/
    /* PROCEDURE NAME : insert_ap_suppliers_int
    /*
    /* DESCRIPTION  :   Procédure d'insertion dans l'open interface ap_suppliers_int
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/

    FUNCTION insert_ap_suppliers_int(p_ap_supp_int_rec ap_suppliers_int%ROWTYPE
                                    )
    RETURN     NUMBER
    IS

    BEGIN
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début insert_ap_suppliers_int');
        INSERT
        INTO   ap_suppliers_int
        VALUES p_ap_supp_int_rec;
        --Dka_Tools_Pkg.put_log_message('le fournisseur '||p_ap_supp_int_rec.vendor_name||' a bien été inséré dans l''open interface');
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin insert_ap_suppliers_int');
        return 0;
    EXCEPTION
        WHEN OTHERS THEN
            Dka_Tools_Pkg.put_log_message('erreur lors de l''insertion du fournisseur '||p_ap_supp_int_rec.vendor_name||' dans l''open interface');
            Dka_Tools_Pkg.put_log_message('Cause:'||SQLERRM);
            g_message_erreur_chargement := substr(SQLERRM,0,500) ;
            return 1;

    END insert_ap_suppliers_int;

    /*=========================================================================*/
    /* PROCEDURE NAME : insert_ap_supplier_sites_int
    /*
    /* DESCRIPTION
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/

    FUNCTION insert_ap_supplier_sites_int(p_ap_supp_site_int_rec ap_supplier_sites_int%ROWTYPE)
    RETURN     NUMBER
    IS

    BEGIN
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début insert_ap_supplier_sites_int');
        INSERT
        INTO   ap_supplier_sites_int
        VALUES p_ap_supp_site_int_rec;

        --Dka_Tools_Pkg.put_log_message('le site fournisseur '||p_ap_supp_site_int_rec.vendor_site_code||' a bien été inséré dans l''open interface');
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin insert_ap_supplier_sites_int');
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            Dka_Tools_Pkg.put_log_message('erreur lors de l''insertion du site fournisseur '||p_ap_supp_site_int_rec.vendor_site_code||' dans l''open interface pour l''organisation: '||p_ap_supp_site_int_rec.operating_unit_name );
            Dka_Tools_Pkg.put_log_message('Cause:'||SQLERRM);
            g_message_erreur_chargement:=substr(SQLERRM,0,500) ;
            RETURN 1;

    END insert_ap_supplier_sites_int;


    /*=========================================================================*/
    /* PROCEDURE NAME : insert_ap_sup_site_contact_int
    /*
    /* DESCRIPTION
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/

    FUNCTION insert_ap_sup_site_contact_int(p_ap_supp_site_ctct_rec ap_sup_site_contact_int%ROWTYPE)
    RETURN     NUMBER
    IS

    BEGIN
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début insert_ap_sup_site_contact_int');
        INSERT
        INTO   ap_sup_site_contact_int
        VALUES p_ap_supp_site_ctct_rec;

        --Dka_Tools_Pkg.put_log_message('le contact '||p_ap_supp_site_ctct_rec.last_name||' a bien été inséré dans l''open interface');
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin insert_ap_sup_site_contact_int');
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            Dka_Tools_Pkg.put_log_message('erreur lors de l''insertion du contact '||p_ap_supp_site_ctct_rec.last_name||' dans l''open interface pour les sites fournisseurs '||p_ap_supp_site_ctct_rec.vendor_site_code);
            Dka_Tools_Pkg.put_log_message('Cause:'||SQLERRM);
            g_message_erreur_chargement := substr(SQLERRM,0,500) ;
            RETURN 1;

    END insert_ap_sup_site_contact_int;

      /*=========================================================================*/
    /* PROCEDURE NAME : insert_ap_suppliers_fact_int
    /*
    /* DESCRIPTION
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/

    PROCEDURE insert_factor_int( p_ap_supp_int_rec                    ap_suppliers_int%ROWTYPE
                                ,p_ap_supp_site_int_rec               ap_supplier_sites_int%ROWTYPE
                                ,p_vendor_interface_id         OUT    ap_suppliers_int.vendor_interface_id%type
                                ,p_new_vendor_site_code_factor IN OUT VARCHAR2,
                                 p_retcode                     OUT    NUMBER)
    IS
        v_vendor_interface_id ap_suppliers_int.vendor_interface_id%type := null;
        v_ap_supp_int_rec             ap_suppliers_int%ROWTYPE;
        v_ap_supp_site_int_rec     ap_supplier_sites_int%ROWTYPE;
        v_retcode     NUMBER;
        v_segment1    ap_suppliers_int.segment1%type := null;
        v_vendor_id ap_suppliers.vendor_id%type := null;
        v_nb_vendor_site_code           NUMBER :=0;
        v_nb_vendor_site_code_tab       NUMBER :=0;
        v_lettre                        NUMBER;
        v_validate_code_site            NUMBER := 0;
        v_new_vendor_site_code_temp      VARCHAR2 (30);

    BEGIN
        --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début insert_factor_int');
        v_ap_supp_int_rec := p_ap_supp_int_rec;
        v_ap_supp_site_int_rec :=p_ap_supp_site_int_rec;
        v_retcode := 0;
        v_ap_supp_site_int_rec.vendor_site_code := NVL(SUBSTR(v_ap_supp_site_int_rec.vendor_site_code,0,INSTR(v_ap_supp_site_int_rec.vendor_site_code,'-',-1)-1),v_ap_supp_site_int_rec.vendor_site_code);
        BEGIN
            SELECT  vendor_id,segment1
            INTO    v_vendor_id,v_segment1
            FROM    ap_suppliers
            WHERE    vendor_name = upper(v_ap_supp_site_int_rec.address_line1)
            AND    vendor_type_lookup_code = 'FACTOR';--problem
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN    
            NULL;
        END;
        
        BEGIN
            SELECT vendor_interface_id
            INTO    v_vendor_interface_id
            FROM    ap_suppliers_int
            WHERE  vendor_name = upper(v_ap_supp_site_int_rec.address_line1)
            AND    vendor_type_lookup_code = 'FACTOR';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_vendor_interface_id            := ap_suppliers_int_s.NEXTVAL;
                v_ap_supp_int_rec.vendor_interface_id           := v_vendor_interface_id;
                v_ap_supp_int_rec.last_update_date              := SYSDATE;
                v_ap_supp_int_rec.vendor_name := upper(v_ap_supp_site_int_rec.address_line1);
                v_ap_supp_int_rec.vat_registration_num := null;
                v_ap_supp_int_rec.num_1099 := null;--YWA artf2099969 
                --test sur null pour le nom
                v_ap_supp_int_rec.vendor_type_lookup_code := 'FACTOR';
                
                
                IF v_vendor_id IS NULL THEN
                    v_ap_supp_int_rec.status                                 := 'NEW';
                    v_ap_supp_int_rec.segment1 := dka_repapfrsimp_four_factor_s.NEXTVAL;--v_ap_supp_int_rec.segment1||'-F'
                    
                ELSE
                    v_ap_supp_int_rec.status                                 := 'PROCESSED';
                    v_ap_supp_int_rec.segment1 :=  v_segment1 ;
                END IF;    
                
                --Dka_Tools_Pkg.put_log_message('Insertion founisseur factor '||v_ap_supp_int_rec.vendor_name);                            
                v_retcode := insert_ap_suppliers_int(v_ap_supp_int_rec);
                
                IF v_retcode =0 THEN
                    g_nb_four_factor_cree_oi:=g_nb_four_factor_cree_oi+1;
                END IF;
            WHEN OTHERS THEN
                Dka_Tools_Pkg.put_log_message('probleme lors de la recherche du founisseur factor '||v_ap_supp_int_rec.vendor_name);
        END;
        

        
        IF v_vendor_interface_id IS NOT NULL THEN
            IF p_new_vendor_site_code_factor IS NULL THEN 
                SELECT COUNT(*) 
                INTO v_nb_vendor_site_code 
                FROM (SELECT COUNT (vendor_site_code)
                        FROM ap_supplier_sites_int
                        WHERE vendor_interface_id = v_vendor_interface_id
                        AND   vendor_site_code like v_ap_supp_site_int_rec.vendor_site_code||'%'
                        GROUP BY vendor_site_code
                      );
                
                --On détermine le nombre de site ayant le meme code postal dans la Table finale
                IF v_vendor_id IS NOT NULL THEN
                    SELECT COUNT(*)
                    INTO v_nb_vendor_site_code_tab
                    FROM (SELECT COUNT(vendor_site_code)
                            FROM ap_supplier_sites_all
                            WHERE vendor_id = v_vendor_id
                            AND vendor_site_code like v_ap_supp_site_int_rec.vendor_site_code||'%'
                            AND vendor_site_code NOT IN (SELECT  vendor_site_code
                            FROM ap_supplier_sites_int
                            WHERE vendor_interface_id = v_vendor_interface_id)
                            GROUP BY vendor_site_code);
                END IF;
                
                /*IF v_nb_vendor_site_code + v_nb_vendor_site_code_tab !=0 THEN
                    v_ap_supp_site_int_rec.vendor_site_code  := v_ap_supp_site_int_rec.vendor_site_code||'-'||to_az(v_nb_vendor_site_code+v_nb_vendor_site_code_tab); --ajouter lettre
                END IF;*/
                
                IF v_nb_vendor_site_code + v_nb_vendor_site_code_tab !=0 THEN
                    v_lettre := v_nb_vendor_site_code+v_nb_vendor_site_code_tab;
                    v_validate_code_site := 0;
                    v_new_vendor_site_code_temp :=  v_ap_supp_site_int_rec.vendor_site_code;
                    
                    LOOP
                        v_ap_supp_site_int_rec.vendor_site_code  := v_new_vendor_site_code_temp||'-'||to_az(v_lettre); --ajouter lettre
                           BEGIN
                                SELECT 0 
                                INTO v_validate_code_site
                                FROM (                 
                                        SELECT  vendor_site_code
                                        FROM ap_supplier_sites_int
                                        WHERE vendor_interface_id = v_vendor_interface_id
                                        AND   vendor_site_code like v_ap_supp_site_int_rec.vendor_site_code
                                        UNION       
                                        SELECT  vendor_site_code
                                        FROM ap_supplier_sites_all
                                        WHERE vendor_id = v_vendor_id
                                        AND vendor_site_code like  v_ap_supp_site_int_rec.vendor_site_code
                                    ) WHERE ROWNUM=1;
                            EXCEPTION
                                WHEN OTHERS THEN   
                                   v_validate_code_site  := 1;
                            END;
                            
                            IF  v_validate_code_site =0 THEN
                                v_lettre := v_lettre+1;
                            END IF;
                            
                       EXIT WHEN v_validate_code_site =1;
                    
                    END LOOP;
                    
                
                END IF;
                
                
                p_new_vendor_site_code_factor := v_ap_supp_site_int_rec.vendor_site_code;
            ELSE
                v_ap_supp_site_int_rec.vendor_site_code := p_new_vendor_site_code_factor;
            END IF;
            
            -- artf2170885 : DEFECT 59 - Adresses fournisseur affichées plusieurs fois          
            v_ap_supp_site_int_rec.fax   := v_ap_supp_site_int_rec.fax;
            v_ap_supp_site_int_rec.phone := v_ap_supp_site_int_rec.phone;

            v_ap_supp_site_int_rec.party_site_name := v_ap_supp_site_int_rec.vendor_site_code;
            v_ap_supp_site_int_rec.vendor_interface_id := v_vendor_interface_id;
            v_ap_supp_site_int_rec.vendor_id := v_vendor_id;
            v_ap_supp_site_int_rec.address_line1   := v_ap_supp_site_int_rec.address_line2;
            v_ap_supp_site_int_rec.address_line2   := v_ap_supp_site_int_rec.address_line3;
            v_ap_supp_site_int_rec.address_line3   := NULL;--ou null mettre adress1 pour relation par la suite
            v_ap_supp_site_int_rec.vat_registration_num := NULL;-- ywa artf2099969 
            --Dka_Tools_Pkg.put_log_message('Insertion du site founisseur factor '||v_ap_supp_site_int_rec.vendor_site_code||' du fournisseur factor de l''open interface id :'||v_vendor_interface_id);
            v_retcode := insert_ap_supplier_sites_int(v_ap_supp_site_int_rec);
            p_vendor_interface_id := v_vendor_interface_id;

        END IF;

        p_retcode := v_retcode;
       -- Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin insert_factor_int');

    END insert_factor_int;
    
    /*=========================================================================*/
    /* PROCEDURE NAME : create_contact_point
    /*
    /* DESCRIPTION
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/

    PROCEDURE create_contact_point( p_contact_point_rec hz_contact_point_v2pub.contact_point_rec_type
                                    ,p_email_rec         hz_contact_point_v2pub.email_rec_type
                                    ,p_phone_rec         hz_contact_point_v2pub.phone_rec_type
                                    ,p_errbuf   OUT VARCHAR2
                                    ,p_retcode OUT NUMBER)
    IS
       
        v_edi_rec           hz_contact_point_v2pub.edi_rec_type;
        v_telex_rec         hz_contact_point_v2pub.telex_rec_type;
        v_web_rec           hz_contact_point_v2pub.web_rec_type;
        v_return_status     VARCHAR2(2000);
        v_msg_count         NUMBER;
        v_msg_data          VARCHAR2(2000);
        v_contact_point_id  NUMBER;
        v_msg_index_out NUMBER;
        
    BEGIN
    
        p_errbuf  := NULL;
        p_retcode := 0;
    
        hz_contact_point_v2pub.create_contact_point (p_init_msg_list     =>  'T',
                                                       p_contact_point_rec =>  p_contact_point_rec,
                                                       p_edi_rec           =>  v_edi_rec          ,
                                                       p_email_rec         =>  p_email_rec        , 
                                                       p_phone_rec         =>  p_phone_rec        ,
                                                       p_telex_rec         =>  v_telex_rec        ,
                                                       p_web_rec           =>  v_web_rec          ,
                                                       x_contact_point_id  =>  v_contact_point_id ,
                                                       x_return_status     =>  v_return_status    ,
                                                       x_msg_count         =>  v_msg_count        ,
                                                       x_msg_data          =>  v_msg_data
                                                   );
                                                   
            IF v_return_status ='S' THEN     
                Dka_Tools_Pkg.put_log_message('contact point cree id: '||v_contact_point_id);
            ELSE
                IF v_msg_count > 1  THEN
                    FOR I IN 1..v_msg_count  LOOP
                        fnd_msg_pub.get (p_msg_index     => i
                                        ,p_encoded       => 'F'
                                        ,p_data          => v_msg_data
                                        ,p_msg_index_out => v_msg_index_out
                                        );
                                        
                        if nvl(instr(p_errbuf,v_msg_data),0) = 0 then
                          p_errbuf := p_errbuf || CHR(10) || v_msg_data;
                        end if;

                    END LOOP;
                    Dka_Tools_Pkg.put_log_message('Erreur api create_contact_point '||p_errbuf);
                    p_retcode := 1; 
                END IF;  
            END IF;
            

    EXCEPTION
        WHEN OTHERS THEN
            Dka_Tools_Pkg.put_log_message('Erreur create_contact_point Cause:'||SQLERRM);
            p_errbuf := substr(SQLERRM,0,500) ;
            p_retcode := 1;        
    END create_contact_point;
    
    /*=========================================================================*/
    /* PROCEDURE NAME : create_phone_fax_email
    /*
    /* DESCRIPTION
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/

    PROCEDURE create_phone_fax_email( p_party_site_id             ap_supplier_sites_all.party_site_id%type
                                    ,p_contact     dka_ap_rep_supp_sites_tmp%ROWTYPE
                                    ,p_errbuf   OUT VARCHAR2
                                    ,p_retcode  OUT NUMBER)
    IS

        v_contact_point_rec hz_contact_point_v2pub.contact_point_rec_type;
        v_email_rec         hz_contact_point_v2pub.email_rec_type;
        v_phone_rec         hz_contact_point_v2pub.phone_rec_type;

        
    BEGIN
        
        v_contact_point_rec.owner_table_name       := 'HZ_PARTY_SITES';
        v_contact_point_rec.created_by_module      := 'TCA_MIGRATION';--TCA_V2_API
        v_contact_point_rec.owner_table_id         := p_party_site_id;
       
        IF p_contact.phone IS NOT NULL THEN 
            v_contact_point_rec.contact_point_type     := 'PHONE';
            v_contact_point_rec.primary_flag           := 'Y';
            v_phone_rec.phone_area_code                := p_contact.area_code;
            v_phone_rec.phone_number                   := p_contact.phone;
            v_phone_rec.phone_line_type                := 'GEN';
            create_contact_point(v_contact_point_rec,v_email_rec,v_phone_rec,p_errbuf,p_retcode);
            IF p_retcode!=0 THEN
                p_errbuf := 'PHONE '||p_errbuf;
                RETURN;
            END IF;
        END IF;
        /*
        IF p_contact.fax IS NOT NULL THEN 
            v_contact_point_rec.contact_point_type     := 'PHONE';
            v_contact_point_rec.primary_flag           := 'N';
            v_phone_rec.phone_area_code                := p_contact.fax_area_code;
            v_phone_rec.phone_number                   := p_contact.fax;
            v_phone_rec.phone_line_type                := 'FAX';
            create_contact_point(v_contact_point_rec,v_email_rec,v_phone_rec,p_errbuf,p_retcode);
            IF p_retcode!=0 THEN
                p_errbuf := 'FAX '||p_errbuf ;
                RETURN;
            END IF;
        END IF;
        */
        IF p_contact.email_address IS NOT NULL THEN 
            v_contact_point_rec.contact_point_type     := 'EMAIL';
            v_contact_point_rec.primary_flag           := 'Y';
            v_email_rec.email_format                   := 'MAILTEXT';    
            v_email_rec.email_address                  := p_contact.email_address;
            create_contact_point(v_contact_point_rec,v_email_rec,v_phone_rec,p_errbuf,p_retcode);
            IF p_retcode!=0 THEN
                /*UPDATE dka_ap_rep_supp_sites_tmp SET hz_party_site_contact='EMAIL '||p_errbuf  WHERE logical_line_num =p_contact.logical_line_num 
                AND segment1 = p_contact.segment1 AND vendor_site_code = p_contact.vendor_site_code;*/
                p_errbuf := 'EMAIL '||p_errbuf ;
                RETURN;
            END IF;
        END IF;
            
    EXCEPTION
        WHEN OTHERS THEN
            Dka_Tools_Pkg.put_log_message('Erreur create_phone_fax_email Cause:'||SQLERRM);
            p_errbuf := substr(SQLERRM,0,500) ;
            p_retcode := 1;               
    END create_phone_fax_email;
    
    /*=========================================================================*/
    /* FUNCTION NAME : get_terms_id
    /*
    /* DESCRIPTION  : Fonction qui retourne l'identifiant de la condition de reglement en entrée
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* p_terms_name       Nom de la condition de reglement
    /* -----------------  ------------------------------------------------------
    /*
    /*
    /*=========================================================================*/
    FUNCTION get_terms_id(p_terms_name  ap_terms.name%type) RETURN ap_terms.term_id%type
    IS
      v_term_id    ap_terms.term_id%type;
    BEGIN
    
      select term_id
      into v_term_id
      from ap_terms
      where name = p_terms_name;
      
      return v_term_id;
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Dka_Tools_Pkg.put_log_message('La condition de reglement '||p_terms_name||' n''existe pas dans Oracle.');
        return null;
      WHEN OTHERS THEN
        Dka_Tools_Pkg.put_log_message('erreur lors de la recherche de l''identifiant de la condition de reglement '||p_terms_name);
        Dka_Tools_Pkg.put_log_message('Cause:'||SQLERRM);
        g_message_erreur_chargement := substr(SQLERRM,0,500);
        return null;
    END get_terms_id;
    
    /*=====================================================================================*/
    /* PROCEDURE NAME : main
    /*
    /* DESCRIPTION
    /*  Procédure principale de l'interface de création des fournisseurs
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* p_errbuf         Retour de message éventuel
    /* p_retcode        Statut du traitement en sortie
    /*=====================================================================================*/

    PROCEDURE MAIN( p_errbuf         IN OUT VARCHAR2,
                    p_retcode         IN  OUT NUMBER,
                    p_chargement_f          VARCHAR2,
                    p_chargement_oi         VARCHAR2,
                    p_lancement_prog_stand  VARCHAR2,
                    p_creation_banque       VARCHAR2,
                    p_creation_lien_factor  VARCHAR2
                    )
    IS

        -- ========== VARIABLES ==========
        v_package                    VARCHAR2(30)  := 'DKA_REPAPFRSIMP_PKG';
        v_nom_traitement             VARCHAR2(200) := 'Import des fournisseurs';
        v_sqlerrm                    VARCHAR2(250) := NULL;
        v_nb_erreurs                 NUMBER :=0;

        v_procedure                  VARCHAR2(30)    := 'MAIN';
        v_message                    VARCHAR2(500);

        v_errbuf                     VARCHAR2(2500);
        v_retcode                    NUMBER;
        v_exeption                   EXCEPTION;
        
        v_nb_vendor_site_code        NUMBER :=0;
        v_ap_supp_int_rec           AP_SUPPLIERS_INT%ROWTYPE;
        v_ap_supp_sites_int_rec     AP_SUPPLIER_SITES_INT%ROWTYPE;
        v_ap_supp_site_ctct_rec     AP_SUP_SITE_CONTACT_INT%ROWTYPE;
        
        v_ccf                         VARCHAR2(500);
        v_vendor_id      NUMBER;
        v_vendor_site_id  NUMBER;
        v_factor_vendor_interface_id            ap_suppliers_int.vendor_interface_id%type;
        v_ext_bank_rec_type                     iby_ext_bankacct_pub.extbank_rec_type;
        v_response_rec                          iby_fndcpt_common_pub.result_rec_type;
        v_ext_bank_branch_rec                   iby_ext_bankacct_pub.extbankbranch_rec_type;
        v_ext_bank_acc_rec                      iby_ext_bankacct_pub.extbankacct_rec_type;
        v_api_version                           NUMBER := 1.0;
        v_x_bank_id                             NUMBER;
        v_x_branch_id                           NUMBER;
        v_x_acct_id                             NUMBER;
        v_supplier_site_id                      NUMBER;
        v_party_site_id                         NUMBER;
        v_x_return_status                       VARCHAR2 (2000);
        v_x_msg_data                            VARCHAR2 (2000);
        v_x_msg_count                           NUMBER;
        v_msg_index_out                         NUMBER;
        v_warining_interface                    BOOLEAN :=false;
        v_warining_bank                         BOOLEAN :=false;
        v_operating_unit_exist                  BOOLEAN;
        v_exist_bank                            BOOLEAN;

        v_lien_f_and_ffactor_exist              BOOLEAN;

        v_p_payee                            IBY_DISBURSEMENT_SETUP_PUB.PAYEECONTEXT_REC_TYPE;
        v_p_assignment_attribs                IBY_FNDCPT_SETUP_PUB.PMTINSTRASSIGNMENT_REC_TYPE;

        p_instrument                   IBY_FNDCPT_SETUP_PUB.PMTINSTRUMENT_REC_TYPE;
        v_x_end_date                    DATE;
        v_x_joint_acct_owner_id         NUMBER;
        v_x_start_date                  DATE;
        v_x_assign_id                   NUMBER;
        
        v_region                        VARCHAR2 (5);
        v_if_factor                     VARCHAR2 (5);
        v_vendor_name_factor            VARCHAR2 (300);
        v_nb_boucle                     NUMBER;
        
        v_nb_vendor_site_code_tab       NUMBER;
         
        v_new_vendor_site_code          VARCHAR2 (30);
        v_new_vendor_site_code_factor   VARCHAR2 (30);
        v_vendor_interface_id           ap_suppliers_int.vendor_interface_id%type := NULL;
        v_terms_name                    ap_terms.name%type;
        v_lettre                        NUMBER;
        v_validate_code_site            NUMBER;
        v_new_vendor_site_code_temp     VARCHAR2 (30);
        
        v_vendor_type_lookup_code       VARCHAR2 (80); --RBE EDB080
        v_grp_fournisseur               VARCHAR2 (80); --RBE EDB080
        
        e_pas_de_site                   EXCEPTION;
        
        CURSOR cur_fournisseur
        IS SELECT rst.*
        FROM dka_ap_rep_supp_tmp rst
        WHERE rst.processed_request_id=-1
        OR rst.segment1 in (SELECT rsst.segment1 
                            FROM dka_ap_rep_supp_sites_tmp rsst 
                            WHERE rsst.segment1=rst.segment1 
                              AND rsst.processed_request_id=-1
        OR rst.segment1 in (SELECT rssct.segment1 
                            FROM dka_ap_rep_supp_sites_ctct_tmp rssct 
                            WHERE rssct.segment1=rsst.segment1 
                              and rssct.vendor_site_code=rsst.vendor_site_code 
                              AND rssct.processed_request_id=-1));

        CURSOR cur_site_fournisseur (p_segment1 VARCHAR2)
        IS SELECT rsst.* 
           FROM dka_ap_rep_supp_sites_tmp rsst 
           WHERE (rsst.segment1=p_segment1 
                 AND rsst.processed_request_id=-1)
                  OR (rsst.segment1=p_segment1 AND
                      EXISTS (SELECT * 
                              FROM dka_ap_rep_supp_sites_ctct_tmp rssct 
                              WHERE rssct.segment1=p_segment1 
                              and rssct.vendor_site_code=rsst.vendor_site_code 
                              AND rssct.processed_request_id=-1)) FOR UPDATE;

        CURSOR cur_contact_site_fournisseur (p_segment1 VARCHAR2,p_vendor_site_code VARCHAR2)
        IS SELECT * 
           FROM dka_ap_rep_supp_sites_ctct_tmp 
           WHERE segment1=p_segment1 and vendor_site_code=p_vendor_site_code AND processed_request_id=-1;
        
        /*TYPE site_ctc_tab_typ IS TABLE OF dka_ap_rep_supp_sites_ctct_tmp%ROWTYPE INDEX BY BINARY_INTEGER;
        c_csf site_ctc_tab_typ;
        v_i NUMBER;*/
        
        CURSOR cur_contact_site_hz 
        IS SELECT * FROM dka_ap_rep_supp_sites_tmp WHERE processed_request_id = g_request_id or hz_party_site_contact IS NOT NULL ORDER BY segment1 ;
        
        /*CURSOR cur_contact_site_hz 
        IS SELECT cst.*,st.new_vendor_site_code FROM dka_ap_rep_supp_sites_ctct_tmp cst, dka_ap_rep_supp_sites_tmp st
        WHERE  cst.segment1 = st.segment1 and cst.vendor_site_code=st.vendor_site_code
        AND (cst.processed_request_id = g_request_id or cst.hz_party_site_contact IS NOT NULL)
        ORDER BY cst.segment1 ;*/

        CURSOR cur_bank_fournisseur --(p_segment1 VARCHAR2)
        IS SELECT * FROM dka_ap_rep_supp_bank_tmp where processed_request_id=-1; --WHERE  segment1=p_segment1;
        
        
        
       cursor cur_regions is
       select ffv.flex_value   region
       from fnd_flex_value_sets ffvs
       join fnd_flex_values     ffv  on(ffv.flex_value_set_id = ffvs.flex_value_set_id)
       where flex_value_set_name = 'DAOPCCF_UO'
         and ffv.enabled_flag = 'Y'
         and ffv.summary_flag = 'N';
    
    BEGIN

        -- Début du Programme --
        -- ========Initialisation des variables d'anomalies========
        p_retcode   := 0;
        p_errbuf   := NULL;
        v_message   := 'Début procédure MAIN';

         -- Initialization des journaux --
        Dka_Tools_Pkg.put_log_message('=======================================================================');
        Dka_Tools_Pkg.put_log_message('Import fournisseur DKA_REPAPFRSIMP_PKG');
        Dka_Tools_Pkg.put_log_message('=======================================================================');
        Dka_Tools_Pkg.put_log_message('Date de lancement    : ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        Dka_Tools_Pkg.put_log_message('Numéro de traitement : ' || TO_CHAR(g_request_id));
         -- Initialization de la sortie --
        Dka_Tools_Pkg.put_outdebug_message('=======================================================================');
        Dka_Tools_Pkg.put_outdebug_message('Import fournisseur DKA_REPAPFRSIMP_PKG');
        Dka_Tools_Pkg.put_outdebug_message('=======================================================================');
        Dka_Tools_Pkg.put_outdebug_message('Date de lancement    : ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        Dka_Tools_Pkg.put_outdebug_message('Numéro de traitement : ' || TO_CHAR(g_request_id));
        Dka_Tools_Pkg.put_outdebug_message('Libelle du login OA '||FND_GLOBAL.USER_NAME);

        -- param user
        Dka_Tools_Pkg.put_outdebug_message('=======================================================================');
        Dka_Tools_Pkg.put_outdebug_message('Parametres utilisateur :');
        Dka_Tools_Pkg.put_outdebug_message('Chargement des fichiers                        : ' || TO_CHAR(p_chargement_f));
        Dka_Tools_Pkg.put_outdebug_message('Changement dans les Opens interfaces           : ' || TO_CHAR(p_chargement_oi));
        Dka_Tools_Pkg.put_outdebug_message('Lancement des traitements standard d''import   : ' || TO_CHAR(p_lancement_prog_stand));
        Dka_Tools_Pkg.put_outdebug_message('Creation des banques                           : ' || TO_CHAR(p_creation_banque));
        Dka_Tools_Pkg.put_outdebug_message('Creation lien sites FACTOR                     : ' || TO_CHAR(p_creation_lien_factor));
        Dka_Tools_Pkg.put_outdebug_message('=======================================================================');


        -- Entete fichier log
        Dka_Tools_Pkg.put_log_message('==========================================================================');
        Dka_Tools_Pkg.put_log_message('Numéro de traitement '||TO_CHAR(g_request_id));
        Dka_Tools_Pkg.put_log_message('Libelle du login OA '||FND_GLOBAL.USER_NAME);
        Dka_Tools_Pkg.put_log_message('==========================================================================');

        Dka_Tools_Pkg.put_outdebug_message('==========================================================================');
        Dka_Tools_Pkg.put_outdebug_message(v_nom_traitement);
        Dka_Tools_Pkg.put_outdebug_message('==========================================================================');

        /*============================================================================================*/
        /*Initialisation des variables*/
        /*============================================================================================*/
        v_message   := 'Init';
        Dka_Tools_Pkg.put_outdebug_message( 'Initiation des variables');
        Init(v_errbuf, v_retcode);
        IF v_retcode = 2 THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RAISE v_exeption;
        END IF;


        /*============================================================================================*/
        /*Chargement des fichiers*/
        /*============================================================================================*/
        IF p_chargement_f ='Y' THEN
            Dka_Tools_Pkg.put_outdebug_message('/*============================================================================================*/');
            Dka_Tools_Pkg.put_outdebug_message('/*Chargement des fichiers*/');
            Dka_Tools_Pkg.put_outdebug_message('/*============================================================================================*/');
            Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');
            Dka_Tools_Pkg.put_log_message('/*Chargement des fichiers*/');
            Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');
            Dka_Tools_Pkg.put_log_message('PHASE DE CHARGEMENT DU FICHIER');
            v_message   := 'PHASE DE CHARGEMENT DU FICHIER';
            -- Lancement du programme de chargement des fichiers
            Launch_Loader(v_errbuf,v_retcode);


            IF v_retcode = 2
            THEN
                p_errbuf  := v_errbuf;
                p_retcode := v_retcode;
                Dka_Tools_Pkg.put_outdebug_message('Chargement des fichiers en erreur');
                RAISE v_exeption;
            END IF;
            Dka_Tools_Pkg.put_outdebug_message('Fin chargement des fichiers avec succes');
        END IF;



        /*============================================================================================*/
        -- Insertion dans les opren interface --
        /*============================================================================================*/
        IF p_chargement_oi ='Y' THEN
            /*============================================================================================*/
            -- PHASE DE PURGE DES ANCIENNES DONNEES d'open interface --
            /*============================================================================================*/
            --Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PURGE DES DONNEES d''open interface');
            purge_data;

            Dka_Tools_Pkg.put_log_message(chr(10));
            Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');
            Dka_Tools_Pkg.put_log_message('/*Insertion dans les opens interfaces*/');
            Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');
            Dka_Tools_Pkg.put_outdebug_message('/*============================================================================================*/');
            Dka_Tools_Pkg.put_outdebug_message('/*Insertion dans les opens interfaces*/');
            Dka_Tools_Pkg.put_outdebug_message('/*============================================================================================*/');
            Dka_Tools_Pkg.put_log_message('Insertion dans les opens interfaces');
            v_message   := 'Insertion dans les opens interfaces';
            /*============================================================================================*/
            /*Boucle principale d'insertion dans l'open interface AP_SUPPLIERS_INT */
            /*============================================================================================*/
            Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut Boucle principale d''insertion dans les open interface ');
            --Dka_Tools_Pkg.put_log_message('Boucle principale d''insertion dans l''open interface AP_SUPPLIERS_INT');
           
            v_message   := 'Boucle principale d''insertion dans l''open interface AP_SUPPLIERS_INT';

            FOR c_f IN cur_fournisseur LOOP
                --Dka_Tools_Pkg.put_log_message('===============================================================================================================');
                --Dka_Tools_Pkg.put_log_message('    ----------------------------Numéro fournisseur : '||c_f.segment1||'------------------------');

                IF c_f.processed_request_id = -1 THEN
                    
                    v_vendor_id := NULL;
                    v_vendor_interface_id := NULL;
                    
                    BEGIN
                        SELECT  vendor_id
                        INTO    v_vendor_id
                        FROM    ap_suppliers
                        WHERE   segment1= c_f.segment1;
                    EXCEPTION
                        WHEN OTHERS THEN
                            v_vendor_id := NULL;
                    END;    
                    
                    BEGIN
                        SELECT  vendor_interface_id
                        INTO    v_vendor_interface_id
                        FROM    ap_suppliers_int
                        WHERE   segment1= c_f.segment1;
                    EXCEPTION
                        WHEN OTHERS THEN
                            v_vendor_interface_id := NULL;
                    END; 
                    
                    IF v_vendor_id IS NOT NULL OR v_vendor_interface_id IS NOT NULL THEN
                        v_warining_interface := TRUE;
                        g_message_erreur_chargement := 'Erreur vous demandé l''insertion d''un fournisseur qui existe deja ';
                        validate_fournisseur(c_f.segment1,c_f.logical_line_num,NULL,TRUE,v_errbuf,v_retcode);
                        IF v_retcode = 2 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            v_message := 'Erreur lors de la validation de la non insertion du founisseur existant '||c_f.segment1;
                            RAISE v_exeption;
                        END IF;
                        CONTINUE;
                    END IF;
                    
                    --RBE EDB080 type fournisseur
                    IF c_f.vendor_type_lookup_code = 'PARTENAIRE' THEN
                    
                        dka_rep_transco_pkg.get_transco ( pv_transco_name  => '024_TYPE_FRS',
                                                   pv_column_01 => c_f.attribute2,
                                                   pv_out_01 => v_grp_fournisseur
                                                );
                        IF v_grp_fournisseur = 'G EXT' THEN
                            v_vendor_type_lookup_code := 'EXTERNAL  PARTNER';
                        ELSE
                            v_vendor_type_lookup_code := 'PARTENAIRE';
                        END IF;
                    ELSE
                        v_vendor_type_lookup_code := c_f.vendor_type_lookup_code;
                    END IF;
                    
                    v_ap_supp_int_rec := NULL;
                    v_ap_supp_int_rec.vendor_interface_id               := ap_suppliers_int_s.NEXTVAL;
                    v_ap_supp_int_rec.last_update_date                  := SYSDATE;
                    v_ap_supp_int_rec.creation_date                     := SYSDATE;
                    v_ap_supp_int_rec.last_updated_by                     := g_user_id;

                    v_ap_supp_int_rec.vendor_name                       := c_f.vendor_name;   --factor aussi
                    v_ap_supp_int_rec.vendor_name_alt                   := c_f.vendor_name_alt;
                    v_ap_supp_int_rec.segment1                          := c_f.segment1;
                    --v_ap_supp_int_rec.summary_flag                  --  n default
                    --v_ap_supp_int_rec.enabled_flag                  --  y default
                    v_ap_supp_int_rec.created_by                           := v_ap_supp_int_rec.last_updated_by;
                    v_ap_supp_int_rec.vendor_type_lookup_code           := v_vendor_type_lookup_code;--c_f.vendor_type_lookup_code;--factor aussi
                    
                    --v_ap_supp_int_rec.ship_to_location_code             := c_f.ship_to_location_code;--ajouter transco;
                    dka_rep_transco_pkg.get_transco ( pv_transco_name  => '016_LIEUX_LIV_FACT',
                                               pv_column_01 => c_f.ship_to_location_code,
                                               pv_out_01 => v_ap_supp_int_rec.ship_to_location_code
                                            );
                    --v_ap_supp_int_rec.bill_to_location_code             := c_f.bill_to_location_code;--ajouter transco;
                    dka_rep_transco_pkg.get_transco ( pv_transco_name  => '016_LIEUX_LIV_FACT',
                                               pv_column_01 => c_f.bill_to_location_code,
                                               pv_out_01 => v_ap_supp_int_rec.bill_to_location_code
                                            );
                    
                    v_ap_supp_int_rec.one_time_flag                      := c_f.one_time_flag;-- a reprendre de l'extraction 11i
                    --v_ap_supp_int_rec.terms_name                         := c_f.terms_name; --transco 020_CONDITIONS_RGLT
                    dka_rep_transco_pkg.get_transco (pv_transco_name => '020_CONDITIONS_RGLT',
                                                     pv_column_01    => c_f.terms_name,
                                                     pv_out_01       => v_terms_name);--v_ap_supp_int_rec.terms_name);
                    v_ap_supp_int_rec.terms_id := get_terms_id(v_terms_name);                               
                    v_ap_supp_int_rec.pay_date_basis_lookup_code         := c_f.pay_date_basis_lookup_code;
                    --v_ap_supp_int_rec.pay_group_lookup_code              := c_f.pay_group_lookup_code;transco en plus
                    dka_rep_transco_pkg.get_transco ( pv_transco_name  => '021_CLASSE_REGL',
                                               pv_column_01 => c_f.pay_group_lookup_code,
                                               pv_out_01 => v_ap_supp_int_rec.pay_group_lookup_code 
                                            );
                    --RBE EDB080
                    IF v_vendor_type_lookup_code = 'EXTERNAL  PARTNER' THEN
                        v_ap_supp_int_rec.pay_group_lookup_code := 'GROUPEHORSDKA';
                    END IF;
                    
                    v_ap_supp_int_rec.payment_priority                   := c_f.payment_priority;
                    v_ap_supp_int_rec.invoice_currency_code              := c_f.invoice_currency_code;
                    v_ap_supp_int_rec.payment_currency_code              := c_f.payment_currency_code;
                    v_ap_supp_int_rec.hold_all_payments_flag             := c_f.hold_all_payments_flag;
                    v_ap_supp_int_rec.hold_future_payments_flag          := c_f.hold_future_payments_flag;
                    v_ap_supp_int_rec.hold_reason                        := c_f.hold_reason;
                    v_ap_supp_int_rec.num_1099                           := c_f.num_1099;
                    v_ap_supp_int_rec.type_1099                          := c_f.type_1099;
                    v_ap_supp_int_rec.organization_type_lookup_code      := c_f.organization_type_lookup_code ;
                    v_ap_supp_int_rec.minority_group_lookup_code         := c_f.minority_group_lookup_code;
                    v_ap_supp_int_rec.payment_method_lookup_code         := c_f.payment_method_lookup_code;-- a reprendre de l'extraction 11i
                    v_ap_supp_int_rec.women_owned_flag                   := c_f.women_owned_flag;
                    v_ap_supp_int_rec.small_business_flag                := c_f.small_business_flag ;
                    v_ap_supp_int_rec.standard_industry_class            := c_f.standard_industry_class;
                    v_ap_supp_int_rec.hold_flag                          := c_f.hold_flag;
                    v_ap_supp_int_rec.terms_date_basis                   := c_f.terms_date_basis;
                    --v_ap_supp_int_rec.inspection_required_flag       -- VALEUR PAR DEFAUT
                    v_ap_supp_int_rec.receipt_required_flag              := c_f.receipt_required_flag;
                    v_ap_supp_int_rec.qty_rcv_tolerance                  := c_f.qty_rcv_tolerance;-- a reprendre de l'extraction 11i
                    v_ap_supp_int_rec.qty_rcv_exception_code             := c_f.qty_rcv_exception_code;-- a reprendre de l'extraction 11i
                    v_ap_supp_int_rec.enforce_ship_to_location_code      := c_f.enforce_ship_to_location_code;
                    v_ap_supp_int_rec.days_early_receipt_allowed         := c_f.days_early_receipt_allowed;
                    
                    IF c_f.enforce_ship_to_location_code IS NULL AND c_f.days_early_receipt_allowed IS NULL THEN
                      v_ap_supp_int_rec.days_late_receipt_allowed        := NULL;
                    ELSE
                      v_ap_supp_int_rec.days_late_receipt_allowed        := c_f.days_late_receipt_allowed;
                    END IF;--YWA TRS
                    
                    IF v_ap_supp_int_rec.days_early_receipt_allowed is null AND v_ap_supp_int_rec.days_late_receipt_allowed is null THEN--NSI artf2010813
                      v_ap_supp_int_rec.receipt_days_exception_code      := null;--NSI artf2010813
                    ELSE
                      v_ap_supp_int_rec.receipt_days_exception_code      := c_f.receipt_days_exception_code;
                    END IF;
     
                    -- artf2089052                                      
                    DECLARE
                      vv_supp_exist_fact VARCHAR2(1) := 'N';
                    BEGIN
                      SELECT DECODE(COUNT(1), 0, 'N', 'Y')
                        INTO vv_supp_exist_fact
                        FROM dka_ap_rep_supp_tmp a
                       WHERE EXISTS (SELECT 1
                                FROM dka_ap_rep_supp_sites_tmp b
                               WHERE /*a.segment1 = b.segment1
                                 AND */
                                     NVL(b.attribute5, 'N') = 'Y'
                                 AND upper(b.address_line1) = upper(a.vendor_name))
                         AND a.segment1 = c_f.segment1;
                      
                      IF vv_supp_exist_fact = 'Y' THEN
                        -- afficher message d'avertissement
                        Dka_Tools_Pkg.put_outdebug_message('');
                        Dka_Tools_Pkg.put_outdebug_message('Le fournisseur ' || c_f.vendor_name || ' existe aussi en tant que factor : risque de doublon');
                        Dka_Tools_Pkg.put_outdebug_message('');
                        
                        -- changer le type du fournisseur courant
                        v_ap_supp_int_rec.vendor_type_lookup_code := 'FACTOR';
                      END IF;
                      
                    END;
                    
                    --v_ap_supp_int_rec.receiving_routing_id           -- pas besoin meme valeur
                    v_ap_supp_int_rec.allow_substitute_receipts_flag      := c_f.allow_substitute_receipts_flag;
                    v_ap_supp_int_rec.allow_unordered_receipts_flag       := c_f.allow_unordered_receipts_flag ;
                    v_ap_supp_int_rec.hold_unmatched_invoices_flag        := c_f.hold_unmatched_invoices_flag;
                    v_ap_supp_int_rec.exclusive_payment_flag              := c_f.exclusive_payment_flag ;
                    --v_ap_supp_int_rec.ap_tax_rounding_rule            -- default value N
                    v_ap_supp_int_rec.auto_tax_calc_flag                 := v_ap_supp_int_rec.auto_tax_calc_flag;
                    v_ap_supp_int_rec.auto_tax_calc_override              := v_ap_supp_int_rec.auto_tax_calc_override ;
                    --v_ap_supp_int_rec.amount_includes_tax_flag        -- pas besoin default value
                    v_ap_supp_int_rec.state_reportable_flag              := c_f.state_reportable_flag;
                    v_ap_supp_int_rec.federal_reportable_flag              := c_f.federal_reportable_flag  ;
                    v_ap_supp_int_rec.attribute_category                := c_f.attribute_category;
                    v_ap_supp_int_rec.attribute1                           := c_f.attribute1;
                    v_ap_supp_int_rec.attribute2                           := c_f.attribute2;
                    v_ap_supp_int_rec.attribute3                           := c_f.attribute3;
                    v_ap_supp_int_rec.attribute4                           := c_f.attribute4;
                    v_ap_supp_int_rec.attribute5                           := c_f.attribute5;
                    v_ap_supp_int_rec.attribute6                           := c_f.attribute6;
                    v_ap_supp_int_rec.attribute7                           := c_f.attribute7;
                    
                    BEGIN--YWA TRS
                        SELECT out_01||'.'||out_02||'.'||out_03||'.'||out_04 --artf2070349 
                        INTO   v_ap_supp_int_rec.attribute8               
                        FROM dka_rep_transco_lines 
                        WHERE transco_name ='013_CATEGORIES_ACHATS' 
                        AND column_02= c_f.attribute8 
                        AND  ROWNUM=1;
                    EXCEPTION
                        WHEN OTHERS THEN
                            v_ap_supp_int_rec.attribute8 := NULL;
                    END;   
                    v_ap_supp_int_rec.attribute9                           := c_f.attribute9;
                    v_ap_supp_int_rec.attribute10                          := c_f.attribute10;
                    v_ap_supp_int_rec.attribute11                          := c_f.attribute11;
                    v_ap_supp_int_rec.attribute12                          := c_f.attribute12;
                    v_ap_supp_int_rec.attribute13                          := c_f.attribute13;
                    v_ap_supp_int_rec.attribute14                          := c_f.attribute14;
                    v_ap_supp_int_rec.attribute15                          := c_f.attribute15;
                    v_ap_supp_int_rec.vat_registration_num                 := c_f.vat_registration_num;
                    v_ap_supp_int_rec.auto_calculate_interest_flag       := c_f.auto_calculate_interest_flag;
                    v_ap_supp_int_rec.exclude_freight_from_discount      := c_f.exclude_freight_from_discount;
                    v_ap_supp_int_rec.tax_reporting_name                 := c_f.tax_reporting_name;
                    v_ap_supp_int_rec.allow_awt_flag                     := c_f.allow_awt_flag;
                    --v_ap_supp_int_rec.bank_charge_bearer              -- pas besoin une seule valeur mais a revoir 'I'
                    v_ap_supp_int_rec.match_option                       := c_f.match_option;
                    --v_ap_supp_int_rec.create_debit_memo_flag          --pas besoin meme valeur N par défaut
                    v_ap_supp_int_rec.offset_tax_flag                   := c_f.offset_tax_flag;
                    v_ap_supp_int_rec.payment_method_code                := c_f.payment_method_lookup_code;
                    v_ap_supp_int_rec.status                                     := 'NEW';
                    
                     
                    v_message   := 'insertion du fournisseur';
                    IF insert_ap_suppliers_int(v_ap_supp_int_rec) =1 THEN
                        v_warining_interface := TRUE;
                        validate_fournisseur(c_f.segment1,c_f.logical_line_num,null,TRUE,v_errbuf,v_retcode);
                        IF v_retcode = 2 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            v_message := 'Erreur lors de le validation le la non insertion du founisseur1 '||c_f.segment1;
                            RAISE v_exeption;
                        END IF;
                        CONTINUE;

                    END IF;

                    validate_fournisseur(c_f.segment1,c_f.logical_line_num,v_ap_supp_int_rec.vendor_interface_id,FALSE,v_errbuf,v_retcode);
                    IF v_retcode = 2 THEN
                        p_errbuf  := v_errbuf;
                        p_retcode := v_retcode;
                        v_message := 'Erreur lors de le validation le l''insertion du founisseur2 '||c_f.segment1;
                        RAISE v_exeption;
                    END IF;

                ELSE
                    BEGIN
                        v_ap_supp_int_rec := NULL;
                        v_vendor_id := NULL;
                        
                        SELECT  *
                        INTO    v_ap_supp_int_rec
                        FROM    ap_suppliers_int
                        WHERE   vendor_interface_id = c_f.vendor_interface_id;
                        
                        SELECT  vendor_id
                        INTO    v_vendor_id
                        FROM    ap_suppliers
                        WHERE   segment1= c_f.segment1;
                        
                    EXCEPTION
                        WHEN OTHERS THEN
                            --Dka_Tools_Pkg.put_log_message('Erreur lors de racuperatution du founisseur'||c_f.segment1||' de lopen interface');
                            v_warining_interface := TRUE;
                            g_message_erreur_chargement := 'Erreur lors de recuperation du fournisseur de l''open interface_id:'||c_f.vendor_interface_id;
                            validate_fournisseur(c_f.segment1,c_f.logical_line_num,NULL,TRUE,v_errbuf,v_retcode);
                            IF v_retcode = 2 THEN
                                p_errbuf  := v_errbuf;
                                p_retcode := v_retcode;
                                v_message := 'Erreur lors de la validation de la non insertion du founisseur3 '||c_f.segment1;
                                RAISE v_exeption;
                            END IF;
                            CONTINUE;
                    END;

                END IF;

                g_nb_fournisseur_cree_oi :=g_nb_fournisseur_cree_oi+1;
                v_nb_vendor_site_code :=0;
                v_nb_vendor_site_code_tab :=0;

                FOR c_sf IN cur_site_fournisseur(c_f.segment1) LOOP

                    /*============================================================================================*/
                    /*Boucle d'insertion dans l'open interface AP_SUPPLIER_SITES_INT*/
                    /*============================================================================================*/
                    --Dka_Tools_Pkg.put_log_message('Boucle  d''insertion dans l''open interface AP_SUPPLIER_SITES_INT');
                    v_message   := 'Boucle  d''insertion dans l''open interface AP_SUPPLIER_SITES_INT';
                    v_nb_vendor_site_code     := 0;
                    v_nb_vendor_site_code_tab := 0;
                    v_ap_supp_sites_int_rec   := NULL;
                    
                    BEGIN
                      SELECT  vendor_id
                      INTO    v_vendor_id
                      FROM    ap_suppliers
                      WHERE   segment1= c_f.segment1;
                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        v_vendor_id := NULL;
                    END;  
                    
                    v_ap_supp_sites_int_rec.last_updated_by                     := v_ap_supp_int_rec.last_updated_by;
                    v_ap_supp_sites_int_rec.creation_date                       := SYSDATE;
                    v_ap_supp_sites_int_rec.vendor_interface_id                 := v_ap_supp_int_rec.vendor_interface_id ;
                    v_ap_supp_sites_int_rec.vendor_id                           := v_vendor_id;
                    v_ap_supp_sites_int_rec.vendor_site_code                    := SUBSTR(c_sf.vendor_site_code,INSTR(c_sf.vendor_site_code,'-')+1);


                    v_message   := 'Création du nouveau vendor_site_code ' || v_ap_supp_sites_int_rec.vendor_site_code  ;
                    
                    
                    
                    
                    SELECT COUNT(*) 
                    INTO v_nb_vendor_site_code 
                    FROM (SELECT COUNT (vendor_site_code)
                            FROM ap_supplier_sites_int
                            WHERE vendor_interface_id = v_ap_supp_int_rec.vendor_interface_id
                            AND   vendor_site_code like v_ap_supp_sites_int_rec.vendor_site_code||'%'
                            GROUP BY vendor_site_code
                          );
                    
                    --On détermine le nombre de site ayant le meme code postal dans la Table finale
                    IF v_vendor_id IS NOT NULL THEN
                        SELECT COUNT(*) 
                        INTO v_nb_vendor_site_code_tab
                        FROM (SELECT COUNT(vendor_site_code)
                                FROM ap_supplier_sites_all
                                WHERE vendor_id = v_vendor_id
                                AND vendor_site_code like v_ap_supp_sites_int_rec.vendor_site_code||'%'
                                AND vendor_site_code NOT IN (SELECT  vendor_site_code
                                                            FROM ap_supplier_sites_int
                                                            WHERE vendor_interface_id = v_ap_supp_int_rec.vendor_interface_id)
                                                             GROUP BY vendor_site_code);
                    END IF;
                    
                    IF v_nb_vendor_site_code + v_nb_vendor_site_code_tab !=0 THEN
                        v_lettre := v_nb_vendor_site_code+v_nb_vendor_site_code_tab;
                        v_validate_code_site := 0;
                        v_new_vendor_site_code_temp :=  v_ap_supp_sites_int_rec.vendor_site_code;
                        
                        LOOP
                            v_ap_supp_sites_int_rec.vendor_site_code  := v_new_vendor_site_code_temp||'-'||to_az(v_lettre); --ajouter lettre
                               BEGIN
                                    SELECT 0 
                                    INTO v_validate_code_site
                                    FROM (                 
                                            SELECT  vendor_site_code
                                            FROM ap_supplier_sites_int
                                            WHERE vendor_interface_id = v_ap_supp_int_rec.vendor_interface_id
                                            AND   vendor_site_code like v_ap_supp_sites_int_rec.vendor_site_code
                                            UNION       
                                            SELECT  vendor_site_code
                                            FROM ap_supplier_sites_all
                                            WHERE vendor_id = v_vendor_id
                                            AND vendor_site_code like  v_ap_supp_sites_int_rec.vendor_site_code
                                        ) WHERE ROWNUM=1;
                                EXCEPTION
                                    WHEN OTHERS THEN   
                                       v_validate_code_site  := 1;
                                END;
                                
                                IF  v_validate_code_site =0 THEN
                                    v_lettre := v_lettre+1;
                                END IF;
                                
                           EXIT WHEN v_validate_code_site =1;
                        
                        END LOOP;
                        
                    
                    END IF;
                    
                    -- artf2148043
                    IF c_sf.purchasing_site_flag = 'N' AND c_sf.pay_site_flag = 'N' THEN
                       v_ap_supp_sites_int_rec.purchasing_site_flag             := 'Y';
                       v_ap_supp_sites_int_rec.pay_site_flag                    := 'Y';
                       v_ap_supp_sites_int_rec.attribute4                       := 'UPDATE_FLAG_RDD';
                    ELSE
                       v_ap_supp_sites_int_rec.purchasing_site_flag             := c_sf.purchasing_site_flag;
                       v_ap_supp_sites_int_rec.pay_site_flag                    := c_sf.pay_site_flag;
                       v_ap_supp_sites_int_rec.attribute4                       := NULL;
                    END IF;

                    v_ap_supp_sites_int_rec.party_site_name                     := v_ap_supp_sites_int_rec.vendor_site_code;
                    
                    v_ap_supp_sites_int_rec.vendor_site_code_alt                := c_sf.vendor_site_code_alt;
                    v_ap_supp_sites_int_rec.rfq_only_site_flag                  := c_sf.rfq_only_site_flag;
                    v_ap_supp_sites_int_rec.attention_ar_flag                   := c_sf.attention_ar_flag ;
                    v_ap_supp_sites_int_rec.address_line1                       := c_sf.address_line1;-- +factor
                    v_ap_supp_sites_int_rec.address_lines_alt                   := c_sf.address_lines_alt;
                    v_ap_supp_sites_int_rec.address_line2                       := c_sf.address_line2;-- +factor
                    v_ap_supp_sites_int_rec.address_line3                       := c_sf.address_line3;-- +factor
                    v_ap_supp_sites_int_rec.city                                := c_sf.city;
                    v_ap_supp_sites_int_rec.state                               := c_sf.state;
                    v_ap_supp_sites_int_rec.zip                                 := c_sf.zip;
                    v_ap_supp_sites_int_rec.county                              := c_sf.county;
                    v_ap_supp_sites_int_rec.country                             := c_sf.country;
                    --v_ap_supp_sites_int_rec.area_code                           := c_sf.area_code;
                    --v_ap_supp_sites_int_rec.phone                               := c_sf.phone;
                    
                    --v_ap_supp_sites_int_rec.ship_to_location_code               := c_sf.ship_to_location_code; --ajouter jointure transco
                    dka_rep_transco_pkg.get_transco ( pv_transco_name  => '016_LIEUX_LIV_FACT',
                                               pv_column_01 => c_sf.ship_to_location_code,
                                               pv_out_01 => v_ap_supp_sites_int_rec.ship_to_location_code 
                                            );
                    --v_ap_supp_sites_int_rec.bill_to_location_code               := c_sf.bill_to_location_code; --ajouter jointure transco
                    dka_rep_transco_pkg.get_transco ( pv_transco_name  => '016_LIEUX_LIV_FACT',
                                               pv_column_01 => c_sf.bill_to_location_code,
                                               pv_out_01 => v_ap_supp_sites_int_rec.bill_to_location_code 
                                            );
                    
                    --v_ap_supp_sites_int_rec.fax                                 := c_sf.fax;
                    --v_ap_supp_sites_int_rec.fax_area_code                       := c_sf.fax_area_code;
                    v_ap_supp_sites_int_rec.payment_method_lookup_code          := c_sf.payment_method_lookup_code;--non défini a extraire 11i
                    v_ap_supp_sites_int_rec.terms_date_basis                    := c_sf.terms_date_basis;
                    v_ap_supp_sites_int_rec.vat_code                            := c_sf.vat_code;--select VAT_CODE from  FINANCIALS_SYSTEM_PARAMS_ALL where VAT_CODE=c_sf.vat_code     ;
                    v_ap_supp_sites_int_rec.distribution_set_name               := c_sf.distribution_set_name;
                    
                    --v_ap_supp_sites_int_rec.pay_group_lookup_code               := c_sf.pay_group_lookup_code; transco en plus
                    dka_rep_transco_pkg.get_transco ( pv_transco_name  => '021_CLASSE_REGL',
                                               pv_column_01 => c_sf.pay_group_lookup_code,
                                               pv_out_01 => v_ap_supp_sites_int_rec.pay_group_lookup_code 
                                            );
                    --RBE EDB080
                    IF v_vendor_type_lookup_code = 'EXTERNAL  PARTNER' THEN
                        v_ap_supp_sites_int_rec.pay_group_lookup_code := 'GROUPEHORSDKA';
                    END IF;
                    
                    v_ap_supp_sites_int_rec.payment_priority                    := c_sf.payment_priority;
                    --v_ap_supp_sites_int_rec.terms_name                          := c_sf.terms_name;--transco 020_CONDITIONS_RGLT
                    dka_rep_transco_pkg.get_transco( pv_transco_name => '020_CONDITIONS_RGLT',
                                                     pv_column_01    => c_sf.terms_name,
                                                     pv_out_01       => v_terms_name);--v_ap_supp_sites_int_rec.terms_name);
                                                     
                    SELECT DECODE(c_sf.auto_tax_calc_flag, 'T', 'Y', 'L', 'Y', c_sf.auto_tax_calc_flag)
                      INTO v_ap_supp_sites_int_rec.auto_tax_calc_flag
                      FROM DUAL;
                                                     
                    v_ap_supp_sites_int_rec.terms_id := get_terms_id(v_terms_name);                               
                    v_ap_supp_sites_int_rec.invoice_amount_limit                := c_sf.invoice_amount_limit;
                    v_ap_supp_sites_int_rec.pay_date_basis_lookup_code          := c_sf.pay_date_basis_lookup_code;
                    v_ap_supp_sites_int_rec.always_take_disc_flag                  := c_sf.always_take_disc_flag;
                    v_ap_supp_sites_int_rec.invoice_currency_code                  := c_sf.invoice_currency_code;
                    v_ap_supp_sites_int_rec.payment_currency_code                  := c_sf.payment_currency_code;
                    v_ap_supp_sites_int_rec.hold_all_payments_flag                 := c_sf.hold_all_payments_flag;
                    v_ap_supp_sites_int_rec.hold_future_payments_flag              := c_sf.hold_future_payments_flag;
                    v_ap_supp_sites_int_rec.hold_reason                            := c_sf.hold_reason;
                    v_ap_supp_sites_int_rec.hold_unmatched_invoices_flag           := c_sf.hold_unmatched_invoices_flag;
                    v_ap_supp_sites_int_rec.ap_tax_rounding_rule                   := c_sf.ap_tax_rounding_rule;
                  --v_ap_supp_sites_int_rec.auto_tax_calc_flag                     := c_sf.auto_tax_calc_flag;
                    v_ap_supp_sites_int_rec.auto_tax_calc_override                 := c_sf.auto_tax_calc_override;
                    v_ap_supp_sites_int_rec.amount_includes_tax_flag               := c_sf.exclusive_payment_flag;
                    v_ap_supp_sites_int_rec.exclusive_payment_flag                 := c_sf.attention_ar_flag;
                    v_ap_supp_sites_int_rec.tax_reporting_site_flag                := c_sf.tax_reporting_site_flag;
                    v_ap_supp_sites_int_rec.attribute1                             := c_sf.attribute1;
                    v_ap_supp_sites_int_rec.attribute2                             := c_sf.attribute2; --c_sf.attribute2 ; ---c_sf.address_lines_alt
                    v_ap_supp_sites_int_rec.attribute3                             := c_sf.attribute3 ;
                  --v_ap_supp_sites_int_rec.attribute4                             := c_sf.attribute4; --artf2148043
                    v_ap_supp_sites_int_rec.attribute5                             := c_sf.attribute5;
                    v_ap_supp_sites_int_rec.attribute6                             := c_sf.attribute6;
                    v_ap_supp_sites_int_rec.attribute7                             := c_sf.attribute7;
                    v_ap_supp_sites_int_rec.attribute8                             := c_sf.attribute8;
                    v_ap_supp_sites_int_rec.attribute9                             := c_sf.attribute9;
                    v_ap_supp_sites_int_rec.attribute10                            := c_sf.attribute10;
                    v_ap_supp_sites_int_rec.attribute11                            := c_sf.attribute11;
                    v_ap_supp_sites_int_rec.attribute12                            := c_sf.attribute12;
                    v_ap_supp_sites_int_rec.attribute13                            := c_sf.vendor_site_code; --c_sf.attribute13;YWA
                    v_ap_supp_sites_int_rec.attribute14                            := c_sf.attribute14;
                    v_ap_supp_sites_int_rec.attribute15                            := c_sf.attribute15;
                    v_ap_supp_sites_int_rec.exclude_freight_from_discount       := c_sf.exclude_freight_from_discount;
                    v_ap_supp_sites_int_rec.vat_registration_num                := c_sf.vat_registration_num;
                    v_ap_supp_sites_int_rec.address_line4                         := c_sf.address_line4;
                    v_ap_supp_sites_int_rec.address_style                         := c_sf.address_style;
                    v_ap_supp_sites_int_rec.language                            := c_sf.language;
                    --v_ap_supp_sites_int_rec.awt_group_id                        := null;-- pas besoin
                    --v_ap_supp_sites_int_rec.awt_group_name                      := null;-- pas besoin
                    v_ap_supp_sites_int_rec.global_attribute1                   := c_sf.global_attribute1;
                    v_ap_supp_sites_int_rec.global_attribute2                   := c_sf.global_attribute2;
                    v_ap_supp_sites_int_rec.global_attribute3                   := c_sf.global_attribute3;
                    v_ap_supp_sites_int_rec.global_attribute4                   := c_sf.global_attribute4;
                    v_ap_supp_sites_int_rec.global_attribute5                   := c_sf.global_attribute5;
                    v_ap_supp_sites_int_rec.global_attribute6                   := c_sf.global_attribute6;
                    v_ap_supp_sites_int_rec.global_attribute7                   := c_sf.global_attribute7;
                    v_ap_supp_sites_int_rec.global_attribute8                   := c_sf.global_attribute8;
                    v_ap_supp_sites_int_rec.global_attribute9                   := c_sf.global_attribute9;
                    v_ap_supp_sites_int_rec.global_attribute10                  := c_sf.global_attribute10;
                    v_ap_supp_sites_int_rec.global_attribute_category              := c_sf.global_attribute_category;
                    v_ap_supp_sites_int_rec.edi_id_number                       := c_sf.edi_id_number;
                    v_ap_supp_sites_int_rec.bank_charge_bearer                  := c_sf.bank_charge_bearer;
                    v_ap_supp_sites_int_rec.pcard_site_flag                      := c_sf.pcard_site_flag;--default value -- a reprendre de la 11i
                    v_ap_supp_sites_int_rec.match_option                        := c_sf.match_option;
                    v_ap_supp_sites_int_rec.country_of_origin_code                := c_sf.country_of_origin_code;-- a reprendre a extraire  11i
                    --v_ap_supp_sites_int_rec.create_debit_memo_flag            -- pas besoin
                    v_ap_supp_sites_int_rec.offset_tax_flag                       := c_sf.offset_tax_flag;
                    v_ap_supp_sites_int_rec.supplier_notif_method                 := c_sf.supplier_notif_method;
                    v_ap_supp_sites_int_rec.email_address                         := c_sf.email_address;--YWA artf2207564 
                    v_ap_supp_sites_int_rec.remittance_email                      := c_sf.remittance_email;
                    v_ap_supp_sites_int_rec.primary_pay_site_flag                := c_sf.primary_pay_site_flag ;
                    v_ap_supp_sites_int_rec.payment_method_code                   := c_sf.payment_method_lookup_code;--payment_method_code ;
                    v_ap_supp_sites_int_rec.status                                 := 'NEW';
                    v_ap_supp_sites_int_rec.fax                                  := c_sf.fax;
                    v_ap_supp_sites_int_rec.phone                                := c_sf.phone;
                    
                    /*v_i := 0;
                    c_csf.DELETE;
                    FOR cc IN  cur_contact_site_fournisseur(c_f.segment1,c_sf.vendor_site_code)  LOOP
                        v_i := v_i +1;
                        c_csf(v_i):= cc;
                    END LOOP;*/
                    
                    v_message   := 'Boucle  d''insertion dans l''open interface AP_SUPPLIER_SITES_INT selon l''organisation';

                    v_operating_unit_exist := FALSE;
                    
                    dka_rep_transco_pkg.get_transco ( pv_transco_name  => '008_REGIONS',
                                               pv_column_01 => SUBSTR(c_sf.vendor_site_code,1,INSTR(c_sf.vendor_site_code,'-')-1),
                                               pv_out_01 =>  v_region
                                            );
                    v_new_vendor_site_code_factor := null;
                    
                    SAVEPOINT insert_all_site;
                    
                    FOR uint_op IN (    SELECT name,organization_id,logical_line_num
                                        FROM  hr_operating_units ,
                                            dka_dup_site_fournisseur 
                                        WHERE segment1 = c_f.segment1
                                        AND processed_request_id=-1
                                        AND vendor_site_code   = c_sf.vendor_site_code
                                        AND name  = v_region||societe)
                                        
                    /*FOR uint_op IN (  SELECT name,organization_id
                                      FROM  hr_operating_units
                                      WHERE name LIKE v_region||'%'  )*/--YWA
                    LOOP
                        
                        g_dup_logical_line_num := uint_op.logical_line_num;
                        v_operating_unit_exist:= TRUE;
                        IF c_sf.processed_request_id = -1 THEN

                            
                            v_ap_supp_sites_int_rec.vendor_site_interface_id               := AP_SUPPLIER_SITES_INT_S.NEXTVAL;
                            v_ap_supp_sites_int_rec.last_update_date                      := SYSDATE;
                            v_ap_supp_sites_int_rec.operating_unit_name := uint_op.name;
                            v_ap_supp_sites_int_rec.org_id := uint_op.organization_id;
                            --insert_ap_supplier_sites_int(v_ap_supp_sites_int_rec);
                            v_vendor_site_id := null;
                            
                            --RG009 Le segment Interco de la CCF pour les fournisseurs Groupe 
                            IF v_ap_supp_int_rec.vendor_type_lookup_code = 'PARTENAIRE' OR v_ap_supp_int_rec.vendor_type_lookup_code='EXTERNAL  PARTNER' THEN  --RBE EDB080
                                
                                c_sf.segment5_liability        := /*v_region*/ v_ap_supp_int_rec.attribute2;
                                c_sf.segment5_prepayment       := /*v_region*/ v_ap_supp_int_rec.attribute2;
                                c_sf.segment5_future_dated_pay := /*v_region*/ v_ap_supp_int_rec.attribute2;
                                
                                --IF dka_rep_transco_pkg.get_complement_compte ( /*v_region*/ 'XXX'||v_ap_supp_int_rec.attribute2 ) = '0' AND dka_rep_transco_pkg.get_complement_compte ( v_ap_supp_int_rec.attribute2 ) != '0' THEN
                                --    c_sf.segment5_liability := v_ap_supp_int_rec.attribute2;
                                --    c_sf.segment5_prepayment := v_ap_supp_int_rec.attribute2;
                                --    c_sf.segment5_future_dated_pay := v_ap_supp_int_rec.attribute2;
                                --ELSIF dka_rep_transco_pkg.get_complement_compte (  /*v_region*/ 'XXX'||v_ap_supp_int_rec.attribute2 ) = '0' AND dka_rep_transco_pkg.get_complement_compte ( v_ap_supp_int_rec.attribute2 ) = '0' THEN
                                --    --Dka_Tools_Pkg.put_log_message('le segment interco de la CCF est 0 pour le fournisseur '||v_ap_supp_int_rec.segment1);
                                --    v_warining_interface := TRUE;
                                --END IF;
                                
                            END IF;
                            
                            --Dka_Tools_Pkg.put_log_message('Recuperation de l''ID de la transco accts_pay_code_combination_id');
                            v_message   := 'Recuperation de l''ID de la transco accts_pay_code_combination_id de la ligne';
                            --v_ap_supp_sites_int_rec.accts_pay_code_combination_id;     --RG DE CCF COMAUN ccf
                                
                            BEGIN
                                
                                dka_rep_transco_pkg.get_transco ( pv_transco_name  => '008_REGIONS',
                                                       pv_column_01 => c_sf.segment2_liability,
                                                       pv_out_01 =>  c_sf.segment2_liability
                                                    );
                                v_ccf := dka_rep_transco_pkg.get_cle_transco_f ( SUBSTR(uint_op.name,4),
                                                                                c_sf.segment2_liability,
                                                                                c_sf.segment3_liability,
                                                                                c_sf.segment4_liability,
                                                                                c_sf.segment5_liability,
                                                                                --c_sf.segment6_liability,
                                                                                c_sf.segment7_liability,
                                                                                c_sf.segment8_liability,
                                                                                c_sf.segment9_liability,
                                                                                c_sf.segment10_liability);
                                v_ap_supp_sites_int_rec.accts_pay_code_combination_id := to_number(v_ccf);
                                
                                DECLARE
                                  vv_segment5 VARCHAR2(200);
                                  e_segment5 EXCEPTION;
                                  
                                BEGIN
                                  SELECT gcc.segment5
                                    INTO vv_segment5
                                    FROM gl_code_combinations gcc
                                   WHERE gcc.code_combination_id =
                                         v_ap_supp_sites_int_rec.accts_pay_code_combination_id;
                                
                                  IF vv_segment5 = '0' AND (v_ap_supp_int_rec.vendor_type_lookup_code = 'PARTENAIRE' OR v_ap_supp_int_rec.vendor_type_lookup_code = 'EXTERNAL  PARTNER') THEN -- YWA artf2123523  --RBE EDB080
                                    RAISE e_segment5;
                                  END IF;
                                
                                EXCEPTION
                                  WHEN e_segment5 THEN
                                    RAISE;
                                  WHEN OTHERS THEN
                                    RAISE;
                                END;
                                
                            EXCEPTION
                                WHEN OTHERS THEN
                                    ROLLBACK TO SAVEPOINT insert_all_site;
                                  --g_message_erreur_chargement := v_ccf;
                                    g_message_erreur_chargement := 'Erreur lors de la recuperation des information de la ccf accts_pay_code_combination_id de la ligne';
                                    validate_site_fournisseur(c_sf.segment1,c_sf.vendor_site_code,c_sf.logical_line_num,NULL,TRUE,v_errbuf,v_retcode);
                                    IF v_retcode = 2 THEN
                                        p_errbuf  := v_errbuf;
                                        p_retcode := v_retcode;
                                        v_message := 'Erreur lors de la recuperation des information de la ccf accts_pay_code_combination_id de la ligne';
                                        RAISE v_exeption;
                                    END IF;
                                    v_warining_interface := TRUE;
                                    EXIT;--CONTINUE;
                            END;


                            --Dka_Tools_Pkg.put_log_message('Recuperation de l''ID de la transco prepay_code_combination_id');
                            v_message   := 'Recuperation de l''ID de la transco prepay_code_combination_id de la ligne';
                            --v_ap_supp_sites_int_rec.prepay_code_combination_id;        --RG DE CCF COMAUN
                            BEGIN
                                dka_rep_transco_pkg.get_transco ( pv_transco_name  => '008_REGIONS',
                                                       pv_column_01 => c_sf.segment2_prepayment,
                                                       pv_out_01 =>  c_sf.segment2_prepayment
                                                    );
                                v_ccf := dka_rep_transco_pkg.get_cle_transco_f ( SUBSTR(uint_op.name,4),
                                                                                c_sf.segment2_prepayment,
                                                                                c_sf.segment3_prepayment,
                                                                                c_sf.segment4_prepayment,
                                                                                c_sf.segment5_prepayment,
                                                                                --c_sf.segment6_prepayment,
                                                                                c_sf.segment7_prepayment,
                                                                                c_sf.segment8_prepayment,
                                                                                c_sf.segment9_prepayment,
                                                                                c_sf.segment10_prepayment);
                                v_ap_supp_sites_int_rec.prepay_code_combination_id := to_number(v_ccf);
                            EXCEPTION
                                WHEN OTHERS THEN
                                    ROLLBACK TO SAVEPOINT insert_all_site;
                                  --g_message_erreur_chargement := v_ccf;
                                    g_message_erreur_chargement := 'Erreur lors de la recuperation des information de la ccf prepay_code_combination_id de la ligne';
                                    validate_site_fournisseur(c_sf.segment1,c_sf.vendor_site_code,c_sf.logical_line_num,NULL,TRUE,v_errbuf,v_retcode);
                                    IF v_retcode = 2 THEN
                                        p_errbuf  := v_errbuf;
                                        p_retcode := v_retcode;
                                        v_message := 'Erreur lors de la recuperation des information de la ccf prepay_code_combination_id de la ligne';
                                        RAISE v_exeption;
                                    END IF;
                                    v_warining_interface := TRUE;
                                    EXIT;--CONTINUE;
                            END;


                            --Dka_Tools_Pkg.put_log_message('Recuperation de l''ID de la transco future_dated_payment_ccid');
                            v_message   := 'Recuperation de l''ID de la transco future_dated_payment_ccid de la ligne';
                            --v_ap_supp_sites_int_rec.future_dated_payment_ccid;         --RG DE CCF COMAUN ccf
                            BEGIN
                                dka_rep_transco_pkg.get_transco ( pv_transco_name  => '008_REGIONS',
                                                       pv_column_01 => c_sf.segment2_future_dated_pay,
                                                       pv_out_01 =>  c_sf.segment2_future_dated_pay
                                                    );
                                v_ccf := dka_rep_transco_pkg.get_cle_transco_f (SUBSTR(uint_op.name,4),
                                                                                c_sf.segment2_future_dated_pay,
                                                                                c_sf.segment3_future_dated_pay,
                                                                                c_sf.segment4_future_dated_pay,
                                                                                c_sf.segment5_future_dated_pay,
                                                                                --c_sf.segment6_future_dated_pay,
                                                                                c_sf.segment7_future_dated_pay,
                                                                                c_sf.segment8_future_dated_pay,
                                                                                c_sf.segment9_future_dated_pay,
                                                                                c_sf.segment10_future_dated_pay);
                                v_ap_supp_sites_int_rec.future_dated_payment_ccid := to_number(v_ccf);
                            EXCEPTION
                                WHEN OTHERS THEN
                                    ROLLBACK TO SAVEPOINT insert_all_site;
                                  --g_message_erreur_chargement := v_ap_supp_sites_int_rec.future_dated_payment_ccid;
                                    g_message_erreur_chargement := 'Erreur lors de la recuperation des information de la ccf future_dated_payment_ccid de la ligne';
                                    validate_site_fournisseur(c_sf.segment1,c_sf.vendor_site_code,c_sf.logical_line_num,NULL,TRUE,v_errbuf,v_retcode);
                                    IF v_retcode = 2 THEN
                                        p_errbuf  := v_errbuf;
                                        p_retcode := v_retcode;
                                        v_message := 'Erreur lors de la recuperation des information de la ccf future_dated_payment_ccid de la ligne';
                                        RAISE v_exeption;
                                    END IF;
                                    v_warining_interface := TRUE;
                                    EXIT;--CONTINUE;
                            END;
                            
                            --Dka_Tools_Pkg.put_log_message('    ----------------------------code site fournisseur : '||v_ap_supp_sites_int_rec.vendor_site_code||'------------------------');
                            
                            IF c_sf.attribute5 ='Y' THEN
                                --Dka_Tools_Pkg.put_log_message('    *****************code site fournisseur factor: '||v_ap_supp_sites_int_rec.vendor_site_code||'*******************');
                                v_message   := 'insertion site fournisseur factor';
                                IF  v_ap_supp_sites_int_rec.address_line1 IS NOT NULL THEN
                                    --Dka_Tools_Pkg.put_log_message('Début Insertion du site founisseur factor');
                                    insert_factor_int(v_ap_supp_int_rec,v_ap_supp_sites_int_rec,v_factor_vendor_interface_id,v_new_vendor_site_code_factor,p_retcode);
                                    IF p_retcode =0 THEN
                                        --Sauvegarde de la nouvelle valeur de vendor_site_code pour site factor
                                        UPDATE dka_ap_rep_supp_sites_tmp
                                        SET
                                         new_vendor_site_code_factor = v_new_vendor_site_code_factor
                                        WHERE
                                        CURRENT OF cur_site_fournisseur;
                                        g_nb_site_four_factor_cree_oi:= g_nb_site_four_factor_cree_oi+1;
                                        v_ap_supp_sites_int_rec.vendor_site_interface_id := AP_SUPPLIER_SITES_INT_S.NEXTVAL;
                                    ELSE
                                        ROLLBACK TO SAVEPOINT insert_all_site;
                                        g_message_erreur_chargement := 'Erreur lors de l''insertion du site factor';
                                        validate_site_fournisseur(c_sf.segment1,c_sf.vendor_site_code,c_sf.logical_line_num,NULL,TRUE,v_errbuf,v_retcode);
                                        IF v_retcode = 2 THEN
                                            p_errbuf  := v_errbuf;
                                            p_retcode := v_retcode;
                                            v_message := 'Erreur lors de l''insertion du site factor';
                                            RAISE v_exeption;
                                        END IF;
                                        v_warining_interface := TRUE;
                                        EXIT;--CONTINUE;
                                    END IF;
                                ELSE
                                    ROLLBACK TO SAVEPOINT insert_all_site;
                                    --Dka_Tools_Pkg.put_log_message('l''adresse line 1 du site founisseur ne doit pas etre nulle afin de pouvoir créer le founisseur factor');
                                    g_message_erreur_chargement := 'l''adresse line 1 du site founisseur ne doit pas etre nulle afin de pouvoir créer le founisseur factor';
                                    validate_site_fournisseur(c_sf.segment1,c_sf.vendor_site_code,c_sf.logical_line_num,NULL,TRUE,v_errbuf,v_retcode);
                                    IF v_retcode = 2 THEN
                                        p_errbuf  := v_errbuf;
                                        p_retcode := v_retcode;
                                        v_message := 'l''adresse line 1 du site founisseur ne doit pas etre nulle afin de pouvoir créer le founisseur factor';
                                        RAISE v_exeption;
                                    END IF;
                                    v_warining_interface := TRUE;
                                    EXIT;--CONTINUE;
                                END IF;
                            END IF;
                            v_message   := 'insertion du site fournisseur';
                            IF insert_ap_supplier_sites_int(v_ap_supp_sites_int_rec) =1 THEN
                                ROLLBACK TO SAVEPOINT insert_all_site;
                                v_warining_interface := TRUE;
                                validate_site_fournisseur(c_sf.segment1,c_sf.vendor_site_code,c_sf.logical_line_num,NULL,TRUE,v_errbuf,v_retcode);
                                    IF v_retcode = 2 THEN
                                        p_errbuf  := v_errbuf;
                                        p_retcode := v_retcode;
                                        v_message := 'Erreur lors de la validation de la non insertion du site founisseur1 '||c_sf.vendor_site_code;
                                        RAISE v_exeption;
                                    END IF;
                                EXIT;--CONTINUE;

                            END IF;

                            validate_site_fournisseur(c_sf.segment1,c_sf.vendor_site_code,c_sf.logical_line_num,v_ap_supp_sites_int_rec.vendor_site_interface_id,FALSE,v_errbuf,v_retcode);
                            IF v_retcode = 2 THEN
                                p_errbuf  := v_errbuf;
                                p_retcode := v_retcode;
                                v_message := 'Erreur lors de la validation de  L''insertion du site founisseur1 '||c_sf.vendor_site_code;
                                RAISE v_exeption;
                            END IF;
                            g_nb_site_fournisseur_cree_oi := g_nb_site_fournisseur_cree_oi+1;
                            --Sauvegarde de la nouvelle valeur de vendor_site_code
                            UPDATE dka_ap_rep_supp_sites_tmp
                            SET new_vendor_site_code = v_ap_supp_sites_int_rec.vendor_site_code
                            WHERE
                            CURRENT OF cur_site_fournisseur;
                            

                        ELSE
                            BEGIN
                            v_ap_supp_sites_int_rec := NULL;
                            v_vendor_site_id := NULL;
                            
                            SELECT  *
                            INTO     v_ap_supp_sites_int_rec
                            FROM    ap_supplier_sites_int
                            WHERE     vendor_site_interface_id = c_sf.vendor_site_interface_id;
                            
                            SELECT vendor_site_id 
                            INTO     v_vendor_site_id
                            FROM ap_supplier_sites_all 
                            WHERE vendor_id =  v_vendor_id
                            AND vendor_site_code= c_sf.new_vendor_site_code--v_ap_supp_sites_int_rec.vendor_site_code
                            AND org_id= uint_op.organization_id;
                            
                            EXCEPTION
                                WHEN OTHERS THEN
                                    --Dka_Tools_Pkg.put_log_message('Erreur lors de racuperatution du site founisseur'||c_sf.vendor_site_code||' de lopen interface');
                                    v_warining_interface := TRUE;
                                    g_message_erreur_chargement := 'Erreur lors de racuperatution du site founisseur de lopen interface id:'||c_sf.vendor_site_interface_id;
                                    validate_site_fournisseur(c_sf.segment1,c_sf.vendor_site_code,c_sf.logical_line_num,NULL,TRUE,v_errbuf,v_retcode);
                                    IF v_retcode = 2 THEN
                                        p_errbuf  := v_errbuf;
                                        p_retcode := v_retcode;
                                        v_message := 'Erreur lors de la validation de la non insertion du site founisseur3 '||c_sf.vendor_site_code;
                                        RAISE v_exeption;
                                    END IF;
                                    CONTINUE;
                            END;

                        END IF;

                        /*============================================================================================*/
                        /*Boucle d'insertion dans l'open interface ap_sup_site_contact_int */
                        /*============================================================================================*/
                        --Dka_Tools_Pkg.put_log_message('Boucle  d''insertion dans l''open interface ap_sup_site_contact_int');
                        v_message   := 'Boucle  d''insertion dans l''open interface ap_sup_site_contact_int';
                        --FOR y IN 1..c_csf.COUNT LOOP --cur_contact_site_fournisseur(c_f.segment1,c_sf.vendor_site_code) LOOP
                        FOR c_csf IN cur_contact_site_fournisseur(c_f.segment1,c_sf.vendor_site_code) LOOP
                                
                                v_ap_supp_site_ctct_rec := NULL;
                                
                                v_ap_supp_site_ctct_rec.last_updated_by                 := v_ap_supp_sites_int_rec.last_updated_by;
                                v_ap_supp_site_ctct_rec.creation_date                 := SYSDATE;
                                v_ap_supp_site_ctct_rec.operating_unit_name           := v_ap_supp_sites_int_rec.operating_unit_name;
                                --v_ap_supp_site_ctct_rec.org_id                        := v_ap_supp_sites_int_rec.org_id;
                                
                                v_ap_supp_site_ctct_rec.first_name                    := c_csf.first_name;
                                v_ap_supp_site_ctct_rec.middle_name                   := c_csf.middle_name;
                                v_ap_supp_site_ctct_rec.last_name                     := c_csf.last_name;
                                v_ap_supp_site_ctct_rec.prefix                        := c_csf.prefix;
                                v_ap_supp_site_ctct_rec.title                         := c_csf.title;
                                v_ap_supp_site_ctct_rec.area_code                     := c_csf.area_code;
                                v_ap_supp_site_ctct_rec.phone                         := c_csf.phone;
                                v_ap_supp_site_ctct_rec.contact_name_alt              := c_csf.contact_name_alt;
                                v_ap_supp_site_ctct_rec.first_name_alt                := c_csf.first_name_alt;
                                v_ap_supp_site_ctct_rec.last_name_alt                 := c_csf.last_name_alt;
                                v_ap_supp_site_ctct_rec.department                    := c_csf.department;
                                v_ap_supp_site_ctct_rec.email_address                 := c_csf.email_address;
                                v_ap_supp_site_ctct_rec.url                           := c_csf.url;
                                v_ap_supp_site_ctct_rec.alt_area_code                 := c_csf.alt_area_code;
                                v_ap_supp_site_ctct_rec.alt_phone                     := c_csf.alt_phone;
                                v_ap_supp_site_ctct_rec.fax_area_code                 := c_csf.fax_area_code;
                                v_ap_supp_site_ctct_rec.fax                           := c_csf.fax;
                                v_ap_supp_site_ctct_rec.status                         := 'NEW';
                                
                                
                                IF c_sf.attribute5 ='Y' and p_retcode = 0 AND v_ap_supp_sites_int_rec.address_line1 IS NOT NULL  THEN
                                    --Dka_Tools_Pkg.put_log_message('    *****************Contact site fournisseur Factor: '||v_ap_supp_site_ctct_rec.last_name ||'*******************');
                                    v_message   := 'insertion site fournisseur factor';
                                    v_ap_supp_site_ctct_rec.vendor_contact_interface_id   := ap_sup_site_contact_int_s.NextVal;
                                    v_ap_supp_site_ctct_rec.last_update_date              := SYSDATE;
                                    v_ap_supp_site_ctct_rec.vendor_interface_id          := v_factor_vendor_interface_id;
                                    v_ap_supp_site_ctct_rec.vendor_site_code            := v_new_vendor_site_code_factor;
                                    --Dka_Tools_Pkg.put_log_message('v_new_vendor_site_code_factor conatct factor '||v_new_vendor_site_code_factor);
                                    BEGIN
                                        --Dka_Tools_Pkg.put_log_message('BEGIN conatct factor ');
                                        SELECT vendor_id 
                                        INTO    v_ap_supp_site_ctct_rec.vendor_id
                                        FROM ap_suppliers 
                                        WHERE segment1 = (select segment1 from ap_suppliers_int where vendor_interface_id =v_ap_supp_site_ctct_rec.vendor_interface_id);

                                        --Dka_Tools_Pkg.put_log_message('contact factor vendor_id'||v_ap_supp_site_ctct_rec.vendor_id);
                                       
                                       /*SELECT vendor_site_id 
                                        INTO   v_ap_supp_site_ctct_rec.vendor_site_id 
                                        FROM ap_supplier_sites_all 
                                        WHERE vendor_id =  v_ap_supp_site_ctct_rec.vendor_id
                                        AND vendor_site_code= v_ap_supp_site_ctct_rec.vendor_site_code
                                        AND org_id= uint_op.organization_id;*/
                                      --Dka_Tools_Pkg.put_log_message('contact factor vendor_site_id'||v_ap_supp_site_ctct_rec.vendor_site_id);
                                    EXCEPTION
                                        WHEN OTHERS THEN
                                            v_ap_supp_site_ctct_rec.vendor_id                      := null;
                                            --v_ap_supp_site_ctct_rec.vendor_site_id                 := null;

                                    END;
                                    
                                    p_retcode:= insert_ap_sup_site_contact_int(v_ap_supp_site_ctct_rec);
                                    IF p_retcode =0 THEN
                                        g_nb_conatct_factor_cree_oi:= g_nb_conatct_factor_cree_oi+1;
                                    ELSE
                                        v_warining_interface := TRUE;
                                    END IF;

                                END IF;
                                v_ap_supp_site_ctct_rec.vendor_id                      := v_vendor_id;
                                v_ap_supp_site_ctct_rec.vendor_site_id                 := v_vendor_site_id;
                                v_ap_supp_site_ctct_rec.vendor_contact_interface_id   := ap_sup_site_contact_int_s.NextVal;
                                v_ap_supp_site_ctct_rec.last_update_date              := SYSDATE;
                                v_ap_supp_site_ctct_rec.vendor_interface_id           := v_ap_supp_int_rec.vendor_interface_id;
                                v_ap_supp_site_ctct_rec.vendor_site_code              := v_ap_supp_sites_int_rec.vendor_site_code;
                                
                                --Dka_Tools_Pkg.put_log_message('    ----------------------------Contact site fournisseur : '||v_ap_supp_site_ctct_rec.last_name ||'------------------------');
                                v_message   := 'Contact site fournisseur';

                                IF insert_ap_sup_site_contact_int(v_ap_supp_site_ctct_rec) =0 THEN
                                    validate_contact_site_f(c_csf.segment1,c_csf.vendor_site_code,c_csf.logical_line_num,v_ap_supp_site_ctct_rec.last_name,FALSE,v_errbuf,v_retcode);
                                    IF v_retcode = 2 THEN
                                        p_errbuf  := v_errbuf;
                                        p_retcode := v_retcode;
                                        v_message := 'Erreur lors de la validation de l''insertion du conatct site founisseur '||v_ap_supp_site_ctct_rec.last_name;
                                        RAISE v_exeption;
                                    END IF;
                                    g_nb_conatct_cree_oi := g_nb_conatct_cree_oi+1;
                                ELSE
                                    v_warining_interface := TRUE;
                                    validate_contact_site_f(c_csf.segment1,c_csf.vendor_site_code,c_csf.logical_line_num,v_ap_supp_site_ctct_rec.last_name,TRUE,v_errbuf,v_retcode);
                                        IF v_retcode = 2 THEN
                                            p_errbuf  := v_errbuf;
                                            p_retcode := v_retcode;
                                            v_message := 'Erreur lors de la validation de la non insertion du contact du site founisseur '||v_ap_supp_site_ctct_rec.last_name;
                                            RAISE v_exeption;
                                        END IF;
                                END IF;


                        END LOOP;

                    END LOOP;

                    IF  NOT v_operating_unit_exist THEN
                        v_warining_interface := TRUE;
                        g_message_erreur_chargement := 'ERREUR UNITE OPERATIONNELLE N''EXISTE PAS';
                        validate_site_fournisseur(c_sf.segment1,c_sf.vendor_site_code,c_sf.logical_line_num,NULL,TRUE,v_errbuf,v_retcode);
                            IF v_retcode = 2 THEN
                                p_errbuf  := v_errbuf;
                                p_retcode := v_retcode;
                                v_message := 'Erreur lors de la validation de la non insertion du site founisseur4 '||c_sf.vendor_site_code;
                                RAISE v_exeption;
                            END IF;
                        Dka_Tools_Pkg.put_log_message('ERREUR UNITE OPERATIONNELLE N''EXISTE PAS :' ||SUBSTR(c_sf.vendor_site_code,1,INSTR(c_sf.vendor_site_code,'-')-1));
                        v_message := '==> ERREUR : L''unité opérationnelle présente dans le fichier '||' n''existe pas dans Oracle';
                    END IF;


                END LOOP;

            END LOOP;
            IF v_warining_interface THEN
                p_retcode := 1;
                Dka_Tools_Pkg.put_outdebug_message('/*Insertion dans les opens interfaces terminée avec des lignes non inserées*/');
                Dka_Tools_Pkg.put_log_message('/*Insertion dans les opens interfaces terminée avec des lignes non inserées*/');
            ELSE
                Dka_Tools_Pkg.put_outdebug_message('/*Insertion dans les opens interfaces terminée correctement*/');
                Dka_Tools_Pkg.put_log_message('/*Insertion dans les opens interfaces terminée correctement*/');
            END IF ;
            Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Boucle principale d''insertion dans les opens interface ');
        END IF;
        

        /*============================================================================================*/
        /*appel des traitements standards d'import des founisseurs*/
        /*============================================================================================*/
        
        IF p_lancement_prog_stand ='Y' THEN
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut appel des traitements standards d''impot ');
            Dka_Tools_Pkg.put_outdebug_message(chr(10));
            Dka_Tools_Pkg.put_log_message(chr(10));
            Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');
            Dka_Tools_Pkg.put_log_message('/*appel des traitements standards d''import des founisseurs*/');
            Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');
            Dka_Tools_Pkg.put_outdebug_message('/*============================================================================================*/');
            Dka_Tools_Pkg.put_outdebug_message('/*appel des traitements standards d''import des founisseurs*/');
            Dka_Tools_Pkg.put_outdebug_message('/*============================================================================================*/');
            v_message   := 'appel des traitements standards d''import des founisseurs';
            --Dka_Tools_Pkg.put_log_message('========================================================================================');
            DELETE
            FROM DKA_AP_REP_SUPP_REJECTION;
            
            v_errbuf := null;
            v_message   := 'Initialisation de l''environnement avec la responsabilité TOUT_AP_ADMINISTRATEUR';
            init_environement(v_errbuf, v_retcode,'TOUT_AP_ADMINISTRATEUR');
            /*IF v_retcode = 1 THEN
                p_errbuf  := v_errbuf;
                p_retcode := v_retcode;
                CONTINUE;
            END IF;*/
            IF v_retcode != 0 THEN
                p_errbuf  := v_errbuf;
                p_retcode := v_retcode;
                RAISE v_exeption;
            END IF;--YWA TRS 
            
            program_import_fournisseur(v_errbuf,v_retcode);

            IF v_retcode = 2
            THEN
                p_errbuf  := v_errbuf;
                p_retcode := v_retcode;
                RAISE v_exeption;
            END IF;

            IF v_retcode=1 THEN

                Dka_Tools_Pkg.put_outdebug_message('/*des lignes de founisseurs ont été rejetées voir  détail dans le journal */');
            ELSE
                Dka_Tools_Pkg.put_outdebug_message('/*traitement des fournisseurs terminé correctement*/');
            END IF ;

            --Dka_Tools_Pkg.put_log_message('=========================================================================================');
            --Dka_Tools_Pkg.put_log_message('appel des traitements standard d''import des sites fournisseurs par organization_id');
            v_message   := 'appel des traitements standards d''import des sites fournisseurs';

            /*FOR ord_id_site IN (SELECT distinct org_id FROM ap_supplier_sites_int WHERE status != 'PROCESSED' )--YWA TRS 
            LOOP
                g_org_id:=ord_id_site.org_id;
                v_errbuf := null;
                -- Initialiser org_id
                v_message   := 'Initialisation de l''environnement pour UO '||g_org_id;
                --Dka_Tools_Pkg.put_log_message( 'Initialisation de l''environnement pour UO '||g_org_id);
                init_environement(v_errbuf, v_retcode);
                IF v_retcode = 1 THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    CONTINUE;
                END IF;
                IF v_retcode = 2 THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    RAISE v_exeption;
                END IF;*/--YWA TRS 

                --Dka_Tools_Pkg.put_log_message('--------------------------------------------------------------------------------------------------');
                --Dka_Tools_Pkg.put_log_message('début lancement traitement standard d''import des sites fournisseurs avec l''org_id: '||g_org_id);
            FOR l_regions in cur_regions LOOP
              
              -- Initialisation de l'environnement
              v_message   := 'Initialisation de l''environnement avec la responsabilité '||l_regions.region||'_AP_ADMINISTRATEUR';
              init_environement(v_errbuf, v_retcode,l_regions.region||'_AP_ADMINISTRATEUR');
              IF v_retcode != 0 THEN
                p_errbuf  := v_errbuf;
                p_retcode := v_retcode;
                RAISE v_exeption;
              END IF;
 
              -- Lancement de l'import des sites fournisseurs
              v_message   := 'début lancement traitement standard d''import des sites fournisseurs avec '||l_regions.region||'_AP_ADMINISTRATEUR';
              v_errbuf := null;
              program_import_site_four(v_errbuf,v_retcode);
              IF v_retcode = 2 THEN
                p_errbuf  := v_errbuf;
                p_retcode := v_retcode;
                RAISE v_exeption;
              END IF;
              
            END LOOP;
            
            -- Initialisation de l'environnement
            v_message   := 'Initialisation de l''environnement avec la responsabilité TOUT_AP_ADMINISTRATEUR';
            v_errbuf := null;
            init_environement(v_errbuf, v_retcode,'TOUT_AP_ADMINISTRATEUR');
            IF v_retcode != 0 THEN
              p_errbuf  := v_errbuf;
              p_retcode := v_retcode;
              RAISE v_exeption;
            END IF;
            
            -- Attente de la fin des traitements d'import des sites fournisseurs
            wait_sites_import(v_errbuf,v_retcode);
            IF v_retcode =1 THEN
              v_warining_interface := TRUE;
            END IF;
            IF v_retcode = 2 THEN
              p_errbuf  := v_errbuf;
              p_retcode := v_retcode;
              RAISE v_exeption;
            END IF;
            
            IF v_warining_interface THEN
              p_retcode := 1;
              Dka_Tools_Pkg.put_outdebug_message('/*des lignes de sites founisseurs on été rejetées voir  détail dans le journal */');
            ELSE
              Dka_Tools_Pkg.put_outdebug_message('/*traitement des sites terminé correctement*/');
            END IF ;

            --Dka_Tools_Pkg.put_log_message('=====================================================================================================');
            --Dka_Tools_Pkg.put_log_message('appel des traitements standards d''import des contacts fournisseurs par organization_id');
            v_message   := 'appel des traitements standard d''import des contacts fournisseurs';

            /* program_import_contact_four(v_errbuf,v_retcode);
            IF v_retcode = 2
            THEN
                p_errbuf  := v_errbuf;
                p_retcode := v_retcode;
                RAISE v_exeption;
            END IF;*/

            --FOR ord_id_contact IN (SELECT distinct org_id FROM ap_sup_site_contact_int WHERE status != 'PROCESSED' )
            --LOOP

               -- g_org_id:=ord_id_contact.org_id;
                -- Initialiser org_id
                --v_message   := 'init_environement  pour UO '||g_org_id;--YWA TRS 
                --Dka_Tools_Pkg.put_outdebug_message( 'Initiation de l''environnement');
                /*init_environement(v_errbuf, v_retcode);
                IF v_retcode = 1 THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    CONTINUE;
                END IF;
                IF v_retcode = 2 THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    RAISE v_exeption;
                END IF;*/--att

                --Dka_Tools_Pkg.put_log_message('---------------------------------------------------------------------------------------------------');
                --Dka_Tools_Pkg.put_log_message('début lancement traitement standard d''import des contacts fournisseurs avec l''org_id: '||g_org_id);
                v_message   := 'début lancement traitement standard d''import des contacts fournisseur'; --YWA TRS --avec l''org_id: '||g_org_id;
                v_errbuf := null;
                program_import_contact_four(v_errbuf,v_retcode);
                IF v_retcode =1 THEN
                    v_warining_interface := TRUE;
                END IF;
                IF v_retcode = 2
                THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    RAISE v_exeption;
                END IF;
            --END LOOP;att


            IF v_warining_interface THEN
                p_retcode := 1;
                Dka_Tools_Pkg.put_outdebug_message('/*des lignes ont été rejetées voir détails dans le journal */');
            ELSE
                Dka_Tools_Pkg.put_outdebug_message('/*traitement des contacts terminé correctement*/');
            END IF ;
            Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'FIN appel des traitements standards d''impot ');
        END IF ;

        
        /*==================== ========================================================================*/
        /*boucle de création des des information contact niveau HZ_PARTY_SITES*/
        /*============================================================================================*/
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut création des des information contact niveau HZ_PARTY_SITES ');
        FOR ccfh IN cur_contact_site_hz LOOP
            v_errbuf := null;
            v_retcode := 0;
            v_party_site_id := NULL;
            v_if_factor    := NULL;
            v_vendor_name_factor := NULL;
            
            BEGIN
                                
                SELECT assl.party_site_id,assl.attribute5,assl.address_line1 
                INTO v_party_site_id,v_if_factor,v_vendor_name_factor
                FROM ap_suppliers ap,
                    ap_supplier_sites_all assl 
                WHERE ap.vendor_id=assl.vendor_id  
                AND  assl.vendor_site_code=ccfh.new_vendor_site_code 
                AND ap.segment1=ccfh.segment1
                AND ap.vendor_type_lookup_code!='FACTOR'
                AND ROWNUM = 1;
            EXCEPTION
                WHEN OTHERS THEN
                    --Dka_Tools_Pkg.put_log_message('Erreur lors de la recuperation du party_site_id du site fournisseur '||ccfh.new_vendor_site_code);
                    v_warining_interface := TRUE;
                    v_message := 'Erreur lors de la recuperation du party_site_id du site fournisseur '||ccfh.new_vendor_site_code;
                    UPDATE dka_ap_rep_supp_sites_tmp SET hz_party_site_contact=v_message  WHERE logical_line_num =ccfh.logical_line_num 
                    AND segment1 = ccfh.segment1 AND vendor_site_code = ccfh.vendor_site_code;
                    CONTINUE;
            END;    
            
            create_phone_fax_email(v_party_site_id,ccfh,v_errbuf,v_retcode );
            IF v_retcode!=0 THEN
                UPDATE dka_ap_rep_supp_sites_tmp SET hz_party_site_contact=v_errbuf  WHERE logical_line_num =ccfh.logical_line_num 
                AND segment1 = ccfh.segment1 AND vendor_site_code = ccfh.vendor_site_code;
                v_warining_interface := TRUE;
                p_errbuf  := v_errbuf;
                p_retcode := v_retcode;
                CONTINUE;
            ELSE
                UPDATE dka_ap_rep_supp_sites_tmp SET hz_party_site_contact=NULL  WHERE logical_line_num =ccfh.logical_line_num 
                AND segment1 = ccfh.segment1 AND vendor_site_code = ccfh.vendor_site_code;
            END IF;
            
            
            
            IF v_if_factor ='Y' THEN
            
                BEGIN
                    v_party_site_id := NULL;
                    
                    SELECT assl.party_site_id
                    INTO   v_party_site_id
                    FROM ap_suppliers ap,ap_supplier_sites_all assl
                    WHERE ap.vendor_id=assl.vendor_id 
                    AND   assl.vendor_site_code= ccfh.new_vendor_site_code_factor
                    AND  ap.vendor_type_lookup_code='FACTOR' 
                    AND ap.vendor_name = v_vendor_name_factor
                    AND ROWNUM = 1;
                EXCEPTION
                    WHEN OTHERS THEN
                        --Dka_Tools_Pkg.put_log_message('Erreur lors de la recuperation du party_site_id du site fournisseur factor '||ccfh.new_vendor_site_code_factor);
                        v_warining_interface := TRUE;
                        v_message := 'Erreur lors de la recuperation du party_site_id du site fournisseur factor '||ccfh.new_vendor_site_code_factor;
                        UPDATE dka_ap_rep_supp_sites_tmp SET hz_party_site_contact=v_message  WHERE logical_line_num =ccfh.logical_line_num 
                        AND segment1 = ccfh.segment1 AND vendor_site_code = ccfh.vendor_site_code;
                        CONTINUE;
                END;    
            
                create_phone_fax_email(v_party_site_id,ccfh,v_errbuf,v_retcode );
                IF v_retcode!=0 THEN
                    UPDATE dka_ap_rep_supp_sites_tmp SET hz_party_site_contact=v_errbuf  WHERE logical_line_num =ccfh.logical_line_num 
                    AND segment1 = ccfh.segment1 AND vendor_site_code = ccfh.vendor_site_code;
                    v_warining_interface := TRUE;
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    CONTINUE;
                ELSE
                    UPDATE dka_ap_rep_supp_sites_tmp SET hz_party_site_contact=NULL  WHERE logical_line_num =ccfh.logical_line_num 
                    AND segment1 = ccfh.segment1 AND vendor_site_code = ccfh.vendor_site_code;    
                END IF;
                
            END IF;
            
        END LOOP;
        IF v_warining_interface THEN
            p_retcode := 1;
            Dka_Tools_Pkg.put_outdebug_message('/*des problemes ont été rencontrés lors de la création des détails et fonctions des contacts*/ ');
        ELSE
            Dka_Tools_Pkg.put_outdebug_message('/*les détails et fonctions des contacts ont bien été créés */');
        END IF ;
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin création des des information contact niveau HZ_PARTY_SITES ');
        
        /*==================== ========================================================================*/
        /*boucle de création des banques et agences et comptes*/
        /*============================================================================================*/
        
        IF p_creation_banque ='Y' THEN
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut de création des banques et agences et comptes');
    
            Dka_Tools_Pkg.put_log_message(chr(10));
            Dka_Tools_Pkg.put_log_message('========================================================================================');
            Dka_Tools_Pkg.put_log_message('Boucle de création des banques et agences et comptes');
            v_message   := 'Boucle de création des banques et agences et comptes';
            Dka_Tools_Pkg.put_log_message('========================================================================================');
            Dka_Tools_Pkg.put_outdebug_message('========================================================================================');
            Dka_Tools_Pkg.put_outdebug_message('Boucle de création des banques et agences et comptes');
            Dka_Tools_Pkg.put_outdebug_message('========================================================================================');
            v_party_site_id := NULL;
            v_if_factor    := NULL;
            v_vendor_name_factor := NULL;
            
            FOR c_bf IN cur_bank_fournisseur LOOP
                --Dka_Tools_Pkg.put_log_message(chr(10));
                --Dka_Tools_Pkg.put_log_message('--------------------------------------------------------------------------------------');
                p_errbuf := null;
                v_errbuf := null;
              
              BEGIN --boucle globale on saute si on ne trouve pas de site ( pas de site pas de compte a rattacher)  
                
                BEGIN
                    
                    v_if_factor := NULL;
                    v_vendor_name_factor  := NULL;
                    v_new_vendor_site_code  := NULL;
                    v_new_vendor_site_code_factor  := NULL;
                    
                    SELECT  attribute5, 
                            address_line1 ,
                            new_vendor_site_code,
                            new_vendor_site_code_factor
                    INTO    v_if_factor,
                            v_vendor_name_factor,
                            v_new_vendor_site_code,
                            v_new_vendor_site_code_factor
                    FROM    dka_ap_rep_supp_sites_tmp 
                    WHERE   segment1 = c_bf.segment1
                    AND     vendor_site_code = c_bf.vendor_site_code
                    AND     processed_request_id != -1;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        --Dka_Tools_Pkg.put_log_message('Le site fournisseur ' ||c_bf.vendor_site_code|| ' du fournisseur '||c_bf.segment1||' il n''a pas été charger correctement');
                        v_warining_bank := TRUE;
                        v_message   := 'Le site fournisseur ' ||c_bf.vendor_site_code|| ' du fournisseur '||c_bf.segment1||' il n''a pas été charger correctement';
                        g_message_erreur_chargement := v_message;
                        validate_banque(c_bf.segment1,c_bf.vendor_site_code,c_bf.logical_line_num,TRUE,v_errbuf,v_retcode);
                        IF v_retcode = 2 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            RAISE v_exeption;
                        END IF;
                        RAISE e_pas_de_site;
                END;
                
                
                v_x_bank_id :=NULL;
                --Dka_Tools_Pkg.put_log_message('vérification de l''existance de la banque :'||c_bf.bank_name);
                v_message   := 'vérification de l''existence de la banque :'||c_bf.bank_name;
                v_ext_bank_rec_type.object_version_number   := v_api_version;
                v_ext_bank_rec_type.bank_name               := c_bf.bank_name;
                v_ext_bank_rec_type.bank_number             := c_bf.bank_number;
                v_ext_bank_rec_type.institution_type        := null;
                v_ext_bank_rec_type.country_code            := c_bf.country;
                v_ext_bank_rec_type.bank_alt_name           := c_bf.bank_name_alt; --new

                --< artf2080905
                IF c_bf.country <> 'FR' THEN
                  iby_ext_bankacct_pub.check_bank_exist(  p_api_version   => v_api_version,
                                                          p_init_msg_list => fnd_api.g_true,
                                                          p_country_code  => v_ext_bank_rec_type.country_code,
                                                          p_bank_name     => v_ext_bank_rec_type.bank_name,
                                                          p_bank_number   => NULL,--v_ext_bank_rec_type.bank_number ,
                                                          x_response      => v_response_rec,
                                                          x_bank_id       => v_x_bank_id,
                                                          x_end_date      => v_x_end_date,
                                                          x_return_status => v_x_return_status,
                                                          x_msg_count     => v_x_msg_count,
                                                          x_msg_data      => v_x_msg_data
                                                          );                
                END IF;
                --> artf2080905
                
                --artf2089196 
                IF v_x_bank_id IS NULL THEN
                  iby_ext_bankacct_pub.check_bank_exist(  p_api_version   => v_api_version,
                                                          p_init_msg_list => fnd_api.g_true,
                                                          p_country_code  => v_ext_bank_rec_type.country_code,
                                                          p_bank_name     => NULL,--v_ext_bank_rec_type.bank_name,
                                                          p_bank_number   => v_ext_bank_rec_type.bank_number ,
                                                          x_response      => v_response_rec,
                                                          x_bank_id       => v_x_bank_id,
                                                          x_end_date      => v_x_end_date,
                                                          x_return_status => v_x_return_status,
                                                          x_msg_count     => v_x_msg_count,
                                                          x_msg_data      => v_x_msg_data
                                                          );
                END IF;

                IF v_x_bank_id IS NULL THEN
                   /* --Dka_Tools_Pkg.put_log_message('banque a créer :'||c_bf.bank_name);
                    v_message   := 'banque a créer :'||c_bf.bank_name;
                    v_exist_bank := FALSE;

                    --Dka_Tools_Pkg.put_log_message('creation de la banque :'||c_bf.bank_name);
                    v_message   := 'creation de la banque :'||c_bf.bank_name;
                    iby_ext_bankacct_pub.create_ext_bank ( p_api_version          => v_api_version
                                                          ,p_init_msg_list        => fnd_api.g_true
                                                          ,p_ext_bank_rec         => v_ext_bank_rec_type
                                                          ,x_bank_id              => v_x_bank_id
                                                          ,x_return_status        => v_x_return_status
                                                          ,x_msg_count            => v_x_msg_count
                                                          ,x_msg_data             => v_x_msg_data
                                                          ,x_response             => v_response_rec
                                                         );

                    IF  v_x_return_status = fnd_api.g_ret_sts_success THEN
                        g_nb_bank_cree:=g_nb_bank_cree+1;
                        --Dka_Tools_Pkg.put_log_message('La banque:'||c_bf.bank_name||' a bien été créé');
                        v_message   := 'La banque:'||c_bf.bank_name||' a bien été créée';
                        COMMIT;
                    ELSE

                        v_warining_bank := TRUE;
                        --Dka_Tools_Pkg.put_log_message('la banque '||c_bf.bank_name||' n''a pas pu etre créée');
                        v_message   := 'la banque '||c_bf.bank_name||' n''a pas pu etre créée';
                        FOR i IN 1..v_x_msg_count
                        LOOP
                            fnd_msg_pub.get (p_msg_index     => i
                                            ,p_encoded       => 'F'
                                            ,p_data          => v_x_msg_data
                                            ,p_msg_index_out => v_msg_index_out
                                            );

                            p_errbuf := p_errbuf || CHR(10) || v_x_msg_data;
                        END LOOP;
                        --Dka_Tools_Pkg.put_log_message('cause : '||p_errbuf);
                        g_message_erreur_chargement := p_errbuf;
                        validate_banque(c_bf.segment1,c_bf.vendor_site_code,c_bf.logical_line_num,TRUE,v_errbuf,v_retcode);
                        IF v_retcode = 2 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            v_message := 'Erreur lors de la validation de la non insertion de la banque '||c_bf.bank_name;
                            RAISE v_exeption;
                        END IF;

                        CONTINUE;
                    END IF;*/--YWA
                    g_message_erreur_chargement := 'La banque n''existe pas';
                    validate_banque(c_bf.segment1,c_bf.vendor_site_code,c_bf.logical_line_num,TRUE,v_errbuf,v_retcode);
                    g_message_erreur_chargement := null;
                    IF v_retcode = 2 THEN
                        p_errbuf  := v_errbuf;
                        p_retcode := v_retcode;
                        v_message := 'Erreur lors de la validation de la vérification de l''existance de la banque '||c_bf.bank_name;
                        RAISE v_exeption;
                    END IF;

                    CONTINUE;
                    
                ELSE
                    v_exist_bank := TRUE;
                    --Dka_Tools_Pkg.put_log_message('La banque:'||c_bf.bank_name||' existe déja avec l''id :' || v_x_bank_id);
                    v_message   := 'La banque:'||c_bf.bank_name||' existe déja avec l''id :' || v_x_bank_id;
                END IF;


                v_x_branch_id := NULL;
                v_exist_bank := TRUE;
                --Dka_Tools_Pkg.put_log_message('vérification de l''existance de l''agence:'||c_bf.bank_branch_name);
                v_message   := 'vérification de l''existence de l''agence :'||c_bf.bank_branch_name;

                v_ext_bank_branch_rec.bch_object_version_number := v_api_version;
                v_ext_bank_branch_rec.bank_party_id             := v_x_bank_id;
                v_ext_bank_branch_rec.branch_name               := c_bf.bank_branch_name;
                v_ext_bank_branch_rec.branch_number             := c_bf.bank_num;

                iby_ext_bankacct_pub.check_ext_bank_branch_exist(   p_api_version   => v_api_version,
                                                                    p_init_msg_list => fnd_api.g_true,
                                                                    p_bank_id       => v_ext_bank_branch_rec.bank_party_id,
                                                                    p_branch_name   => NULL,--v_ext_bank_branch_rec.branch_name,
                                                                    p_branch_number => v_ext_bank_branch_rec.branch_number,
                                                                    x_response      => v_response_rec,
                                                                    x_branch_id     => v_x_branch_id,
                                                                    x_end_date      => v_x_end_date,
                                                                    x_return_status => v_x_return_status,
                                                                    x_msg_count     => v_x_msg_count,
                                                                    x_msg_data      => v_x_msg_data
                                                                    );

                --< artf2080905
                IF v_x_branch_id IS NULL AND c_bf.country <> 'FR' THEN
                  iby_ext_bankacct_pub.check_ext_bank_branch_exist(   p_api_version   => v_api_version,
                                                                      p_init_msg_list => fnd_api.g_true,
                                                                      p_bank_id       => v_ext_bank_branch_rec.bank_party_id,
                                                                      p_branch_name   => v_ext_bank_branch_rec.branch_name,
                                                                      p_branch_number => NULL,--v_ext_bank_branch_rec.branch_number,
                                                                      x_response      => v_response_rec,
                                                                      x_branch_id     => v_x_branch_id,
                                                                      x_end_date      => v_x_end_date,
                                                                      x_return_status => v_x_return_status,
                                                                      x_msg_count     => v_x_msg_count,
                                                                      x_msg_data      => v_x_msg_data
                                                                      );              
                END IF;
                --> artf2080905
                
                IF v_x_branch_id IS NULL THEN

                    /*v_ext_bank_branch_rec.branch_type               := c_bf.bank_branch_type;

                    IF v_ext_bank_branch_rec.branch_type IS NULL OR c_bf.bank_branch_type = 'AUTRE' THEN
                        v_ext_bank_branch_rec.branch_type           := 'OTHER';
                    END IF;

                    v_ext_bank_branch_rec.alternate_branch_name     :=c_bf.bank_branch_name_alt; --new
                    v_ext_bank_branch_rec.description               :=c_bf.description_branch;
                    v_ext_bank_branch_rec.eft_number                :=c_bf.eft_swift_code;
                    v_ext_bank_branch_rec.rfc_identifier            :=c_bf.rfc_identifier;--new
                    --v_ext_bank_branch_rec.attribute_category        :=c_bf.attribute_category;--a reprendre dans l'extraction
                    v_ext_bank_branch_rec.attribute1            :=  c_bf.attribute1;
                    v_ext_bank_branch_rec.attribute2            :=  c_bf.attribute2_b;
                    v_ext_bank_branch_rec.attribute3            :=  c_bf.attribute3; --a reprendre dans l'extraction
                    --v_ext_bank_branch_rec.attribute4        :=  c_bf.attribute4; --a reprendre dans l'extraction
                    --v_ext_bank_branch_rec.attribute5        :=  c_bf.attribute5; --a reprendre dans l'extraction
                    --v_ext_bank_branch_rec.attribute6        :=  c_bf.attribute6; --a reprendre dans l'extraction
                    --v_ext_bank_branch_rec.attribute7        :=  c_bf.attribute7; --a reprendre dans l'extraction
                    --v_ext_bank_branch_rec.attribute8        :=  c_bf.attribute8; --a reprendre dans l'extraction
                    --v_ext_bank_branch_rec.attribute9        :=  c_bf.attribute9; --a reprendre dans l'extraction
                    --v_ext_bank_branch_rec.attribute10       :=  c_bf.attribute10;--a reprendre dans l'extraction
                    --v_ext_bank_branch_rec.attribute11       :=  c_bf.attribute11;--a reprendre dans l'extraction
                    --v_ext_bank_branch_rec.attribute12       :=  c_bf.attribute12;--a reprendre dans l'extraction
                    --v_ext_bank_branch_rec.attribute13       :=  c_bf.attribute13;--a reprendre dans l'extraction
                    --v_ext_bank_branch_rec.attribute14       :=  c_bf.attribute14;--a reprendre dans l'extraction
                    --v_ext_bank_branch_rec.attribute15       :=  c_bf.attribute15;--a reprendre dans l'extraction

                    iby_ext_bankacct_pub.create_ext_bank_branch(  p_api_version                  => v_api_version
                                                                 ,p_init_msg_list                => fnd_api.g_true
                                                                 ,p_ext_bank_branch_rec          => v_ext_bank_branch_rec
                                                                 ,x_branch_id                    => v_x_branch_id
                                                                 ,x_return_status                => v_x_return_status
                                                                 ,x_msg_count                    => v_x_msg_count
                                                                 ,x_msg_data                     => v_x_msg_data
                                                                 ,x_response                     => v_response_rec
                                                                );
                    IF  v_x_return_status = fnd_api.g_ret_sts_success THEN
                        --Dka_Tools_Pkg.put_log_message('L''agence :'||c_bf.bank_branch_name||' a bien été créée');
                        v_message   := 'Lagence:'||c_bf.bank_branch_name||' a bien été créée';
                        g_nb_agence_cree:=g_nb_agence_cree+1;
                        COMMIT;
                    ELSE
                        v_warining_bank := TRUE;
                        --Dka_Tools_Pkg.put_log_message('l''agence '||c_bf.bank_branch_name||' n''a pas pu etre créée');
                        v_message   := 'l''agence '||c_bf.bank_branch_name||' n''a pas pu etre créée';
                            FOR i IN 1..v_x_msg_count
                            LOOP
                                fnd_msg_pub.get (p_msg_index     => i
                                        ,p_encoded       => 'F'
                                        ,p_data          => v_x_msg_data
                                        ,p_msg_index_out => v_msg_index_out
                                        );

                                p_errbuf := p_errbuf || CHR(10) || v_x_msg_data;
                        END LOOP;
                        --Dka_Tools_Pkg.put_log_message('cause : '||p_errbuf);
                        g_message_erreur_chargement := p_errbuf;
                        validate_banque(c_bf.segment1,c_bf.vendor_site_code,c_bf.logical_line_num,TRUE,v_errbuf,v_retcode);
                        IF v_retcode = 2 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            v_message := 'Erreur lors de la validation de la non insertion de l''agence banque '||c_bf.bank_branch_name;
                            RAISE v_exeption;
                        END IF;
                        CONTINUE;
                    END IF;*/--YWA
                    
                    g_message_erreur_chargement := 'L''agence n''existe pas';
                    validate_banque(c_bf.segment1,c_bf.vendor_site_code,c_bf.logical_line_num,TRUE,v_errbuf,v_retcode);
                    g_message_erreur_chargement := null;
                    IF v_retcode = 2 THEN
                        p_errbuf  := v_errbuf;
                        p_retcode := v_retcode;
                        v_message := 'Erreur lors de la validation de la vérification de l''existance l''agence banque '||c_bf.bank_branch_name;
                        RAISE v_exeption;
                    END IF;
                    CONTINUE;
                    
                ELSE
                    v_exist_bank := TRUE;
                    --Dka_Tools_Pkg.put_log_message('L''agence:'||c_bf.bank_branch_name||' existe déja avec l''id :' || v_x_branch_id);
                    v_message   := 'L''agence:'||c_bf.bank_branch_name||' existe déja avec l''id :' || v_x_branch_id;
                END IF;

                v_ext_bank_acc_rec.object_version_number    := v_api_version;

                v_ext_bank_acc_rec.bank_account_name        := c_bf.bank_account_name;
                v_ext_bank_acc_rec.bank_account_num         := c_bf.bank_account_num;
                v_ext_bank_acc_rec.bank_id                  := v_x_bank_id;
                v_ext_bank_acc_rec.branch_id                := v_x_branch_id;
                --v_ext_bank_acc_rec.start_date               := SYSDATE;
                v_ext_bank_acc_rec.start_date                     := c_bf.start_date;--new

                v_ext_bank_acc_rec.country_code             := c_bf.country;

                v_ext_bank_acc_rec.currency                 := c_bf.currency_code;
                v_ext_bank_acc_rec.foreign_payment_use_flag := null;
                v_ext_bank_acc_rec.iban                     := c_bf.iban_number;
                v_ext_bank_acc_rec.check_digits             := c_bf.check_digits;

                v_ext_bank_acc_rec.multi_currency_allowed_flag  :=    'N';
                v_ext_bank_acc_rec.alternate_acct_name          := c_bf.bank_account_name_alt;--new

                v_ext_bank_acc_rec.acct_type                    := c_bf.account_type;
                v_ext_bank_acc_rec.description                  := c_bf.description_accounts;
                v_ext_bank_acc_rec.agency_location_code         := c_bf.agency_location_code;
                v_ext_bank_acc_rec.end_date                     := c_bf.end_date;--new
                
                --DEBUG
                --Dka_Tools_Pkg.put_log_message('bank          : '||c_bf.bank_number);
                --Dka_Tools_Pkg.put_log_message('branch        : '||c_bf.bank_num);
                --Dka_Tools_Pkg.put_log_message('v_x_bank_id   : '||v_x_bank_id);
                --Dka_Tools_Pkg.put_log_message('v_x_branch_id : '||v_x_branch_id);
                --Dka_Tools_Pkg.put_log_message('iban_number   : '||c_bf.iban_number);
                --Dka_Tools_Pkg.put_log_message('check_digits  : '||c_bf.check_digits);
                

                --hedging_contract_reference
                --attribute_category
                --attribute1
                v_ext_bank_acc_rec.attribute2  :=  c_bf.attribute2_acc;
                v_ext_bank_acc_rec.attribute3  :=  c_bf.attribute3;
                --attribute4
                --attribute5
                --attribute6
                --attribute7
                --attribute8
                --attribute9
                v_ext_bank_acc_rec.attribute10 := c_bf.attribute10;
                --attribute11
                --attribute12
                --attribute13
                --attribute14
                --attribute15

                dka_rep_transco_pkg.get_transco ( pv_transco_name  => '008_REGIONS',
                                               pv_column_01 => SUBSTR(c_bf.vendor_site_code,1,INSTR(c_bf.vendor_site_code,'-')-1),
                                               pv_out_01 =>  v_region
                                            );
                
                
                FOR org_id IN ( SELECT organization_id
                                        FROM  hr_operating_units ,
                                            dka_dup_site_fournisseur 
                                        WHERE segment1 = c_bf.segment1
                                        AND processed_request_id != -1
                                        AND vendor_site_code   = c_bf.vendor_site_code
                                        AND name  = v_region||societe)
                                       
                /*FOR org_id IN (
                SELECT organization_id
                FROM  hr_operating_units
                WHERE name LIKE v_region||'%'
                )*/
                LOOP

                    g_org_id:=org_id.organization_id;

                    -- Initialiser org_id
                    --v_message   := 'Initialisation de l''environnement pour UO '||g_org_id;
                    --Dka_Tools_Pkg.put_log_message( 'Initialisation de l''environnement pour UO '||g_org_id);
                    /*init_environement(v_errbuf, v_retcode);
                    IF v_retcode = 1 THEN
                        p_errbuf  := v_errbuf;
                        p_retcode := v_retcode;
                        CONTINUE;
                    END IF;
                    IF v_retcode = 2 THEN
                        p_errbuf  := v_errbuf;
                        p_retcode := v_retcode;
                        RAISE v_exeption;
                    END IF;*/-- YWA TRS
                    
                    v_nb_boucle := 1;
                    
                    IF v_if_factor = 'Y' THEN
                        v_nb_boucle := 2;
                    END IF;
                        
                    FOR i IN 1..v_nb_boucle LOOP   
                        
                        BEGIN
                        
                            IF i = 2 THEN
                                 --Dka_Tools_Pkg.put_log_message('creation pour site factor');
                                 
                                 v_ext_bank_acc_rec.acct_owner_party_id := NULL;
                                 v_supplier_site_id  := NULL;
                                 v_party_site_id  := NULL;
                                 
                                SELECT  asup.party_id,
                                        vendor_site_id,
                                        party_site_id
                                INTO    v_ext_bank_acc_rec.acct_owner_party_id,
                                        v_supplier_site_id,
                                        v_party_site_id        
                                FROM    ap_suppliers asup,
                                        ap_supplier_sites_all ass
                                WHERE   ass.vendor_site_code  = v_new_vendor_site_code_factor--like  SUBSTR(c_bf.vendor_site_code,INSTR(c_bf.vendor_site_code,'-')+1)||'%'
                                And     asup.vendor_id = ass.vendor_id
                                AND     asup.vendor_type_lookup_code='FACTOR'
                                And     ass.org_id = org_id.organization_id
                                AND     asup.vendor_name = v_vendor_name_factor;
                            
                            ELSE
                                v_ext_bank_acc_rec.acct_owner_party_id := NULL;
                                v_supplier_site_id  := NULL;
                                v_party_site_id  := NULL;
                            
                                 --Dka_Tools_Pkg.put_log_message('creation pour site non factor');
                                SELECT  asup.party_id,
                                        vendor_site_id,
                                        party_site_id
                                INTO    v_ext_bank_acc_rec.acct_owner_party_id,
                                        v_supplier_site_id,
                                        v_party_site_id
                                FROM    ap_suppliers asup ,
                                        ap_supplier_sites_all ass
                                WHERE   asup.segment1         = c_bf.segment1
                                AND     ass.vendor_site_code = v_new_vendor_site_code--like SUBSTR(c_bf.vendor_site_code,INSTR(c_bf.vendor_site_code,'-')+1)||'%'
                                And     asup.vendor_id = ass.vendor_id
                                And     ass.org_id = org_id.organization_id;
                            END IF;    
                        EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                                v_warining_bank := TRUE;
                                --Dka_Tools_Pkg.put_log_message('Le founisseur '||c_bf.segment1||' ou  le site fournisseur ' ||c_bf.vendor_site_code||' n''existe pas');
                                v_message   := 'Le fournisseur '||c_bf.segment1||' ou  le site founisseur ' ||c_bf.vendor_site_code||' n''existe pas';
                                g_message_erreur_chargement := v_message;
                                validate_banque(c_bf.segment1,c_bf.vendor_site_code,c_bf.logical_line_num,TRUE,v_errbuf,v_retcode);
                                g_message_erreur_chargement := null;
                                IF v_retcode = 2 THEN
                                    p_errbuf  := v_errbuf;
                                    p_retcode := v_retcode;
                                    RAISE v_exeption;
                                END IF;
                                RAISE e_pas_de_site;
                            WHEN OTHERS THEN
                                --Dka_Tools_Pkg.put_log_message('Erreur lors de la récupération des informations fournisseur et site founisseur pour le compte '||c_bf.bank_account_name);
                                v_message   := 'Erreur lors de la récuperation des informations fournisseur et site founisseur pour le compte '||c_bf.bank_account_name;
                                v_warining_bank := TRUE;
                                g_message_erreur_chargement := v_message;
                                validate_banque(c_bf.segment1,c_bf.vendor_site_code,c_bf.logical_line_num,TRUE,v_errbuf,v_retcode);
                                g_message_erreur_chargement := null;
                                IF v_retcode = 2 THEN
                                    p_errbuf  := v_errbuf;
                                    p_retcode := v_retcode;
                                    RAISE v_exeption;
                                END IF;
                                RAISE e_pas_de_site;
                        END;

                        
                        iby_ext_bankacct_pub.check_ext_acct_exist(  p_api_version       => v_api_version,
                                        p_init_msg_list     => fnd_api.g_true,
                                        p_ext_bank_acct_rec => v_ext_bank_acc_rec,
                                        x_acct_id           => v_x_acct_id,
                                        x_start_date        => v_x_start_date,
                                        x_end_date          => v_x_end_date,
                                        x_return_status     => v_x_return_status,
                                        x_msg_count         => v_x_msg_count,
                                        x_msg_data          => v_x_msg_data,
                                        x_response          => v_response_rec
                                        );
                        IF v_x_acct_id IS NULL THEN
                            

                            iby_ext_bankacct_pub.create_ext_bank_acct
                                                    (  p_api_version                      => v_api_version
                                                      ,p_init_msg_list                    => fnd_api.g_true
                                                      ,p_ext_bank_acct_rec                => v_ext_bank_acc_rec
                                                      ,x_acct_id                          => v_x_acct_id
                                                      ,p_association_level                => 'SS'
                                                      ,p_supplier_site_id                 => v_supplier_site_id
                                                      ,p_party_site_id                    => v_party_site_id
                                                      ,p_org_id                           => org_id.organization_id
                                                      ,p_org_type                         => 'OPERATING_UNIT'
                                                      ,x_return_status                    => v_x_return_status
                                                      ,x_msg_count                        => v_x_msg_count
                                                      ,x_msg_data                         => v_x_msg_data
                                                      ,x_response                         => v_response_rec
                                                    );
                            IF  (v_x_return_status = fnd_api.g_ret_sts_success) THEN
                                COMMIT;
                                g_nb_compte_cree:=g_nb_compte_cree+1;
                                --Dka_Tools_Pkg.put_log_message('le compte '||c_bf.bank_account_name||' a bien été créé numéro :' ||c_bf.bank_account_num ||' pour l''organisation: '||org_id.ORGANIZATION_ID);
                                v_message   := 'le compte '||c_bf.bank_account_name||' a bien été créé numéro :' ||c_bf.bank_account_num;
                             
                               /*
                               validate_banque(c_bf.segment1,c_bf.vendor_site_code,c_bf.line_number,FALSE,v_errbuf,v_retcode);
                                IF v_retcode = 2 THEN
                                    p_errbuf  := v_errbuf;
                                    p_retcode := v_retcode;
                                    v_message := 'Erreur lors de la validation de l''insertion du compte bancaire '||c_bf.bank_account_name;
                                    RAISE v_exeption;
                                END IF;    */


                            ELSE
                                v_warining_bank := TRUE;
                                --Dka_Tools_Pkg.put_log_message('le compte '||c_bf.bank_account_name||' n''a pas pu etre créé numéro :' ||c_bf.bank_account_num);
                                v_message   := 'le compte '||c_bf.bank_account_name||' n''a pas pu etre créé numéro :' ||c_bf.bank_account_num;

                                IF v_x_msg_count is null then
                                   v_x_msg_count:=1;
                                END IF;

                                FOR i IN 1..v_x_msg_count
                                LOOP
                                    --Dka_Tools_Pkg.put_log_message(i);
                                    fnd_msg_pub.get (p_msg_index     => i
                                                    ,p_encoded       => 'F'
                                                    ,p_data          => v_x_msg_data
                                                    ,p_msg_index_out => v_msg_index_out
                                                    );
                                                    
                                    if nvl(instr(p_errbuf,v_x_msg_data),0) = 0 then
                                      p_errbuf := p_errbuf || CHR(10) || v_x_msg_data;
                                    end if;

                                END LOOP;

                                --Dka_Tools_Pkg.put_log_message('cause : '||p_errbuf);
                                g_message_erreur_chargement := v_message|| ' ' ||p_errbuf;
                                v_warining_bank := TRUE;
                                validate_banque(c_bf.segment1,c_bf.vendor_site_code,c_bf.logical_line_num,TRUE,v_errbuf,v_retcode);
                                g_message_erreur_chargement := null;
                                IF v_retcode = 2 THEN
                                    p_errbuf  := v_errbuf;
                                    p_retcode := v_retcode;
                                    v_message := 'Erreur lors de la validation de la non insertion du compte bancaire '||c_bf.bank_account_name;
                                    RAISE v_exeption;
                                END IF;

                                CONTINUE;

                            END IF;

                        ELSE
                            g_nb_compte_cree:=g_nb_compte_cree+1;
                            v_exist_bank := TRUE;
                            --Dka_Tools_Pkg.put_log_message('le compte '||c_bf.bank_account_name||' existe déja avec le numéro :' ||c_bf.bank_account_num);
                            v_message   := 'le compte '||c_bf.bank_account_name||' existe déja avec le numéro :' ||c_bf.bank_account_num;
                            
                            iby_ext_bankacct_pub.check_bank_acct_owner(p_api_version            => v_api_version,
                                                                    p_init_msg_list         => fnd_api.g_true,
                                                                    p_bank_acct_id          => v_x_acct_id,
                                                                    p_acct_owner_party_id   => v_ext_bank_acc_rec.acct_owner_party_id,
                                                                    x_return_status         => v_x_return_status,
                                                                    x_msg_count             => v_x_msg_count,
                                                                    x_msg_data              => v_x_msg_data,
                                                                    x_response              => v_response_rec
                                                                    );
                            
                            IF (v_x_return_status <> fnd_api.g_ret_sts_success) THEN

                            -- créer le co-propriétaire de compte pour le compte bancaire
                                iby_ext_bankacct_pub.add_joint_account_owner(p_api_version         => v_api_version
                                                                            ,p_init_msg_list       => fnd_api.g_true
                                                                            ,p_bank_account_id     => v_x_acct_id
                                                                            ,p_acct_owner_party_id => v_ext_bank_acc_rec.acct_owner_party_id
                                                                            ,x_joint_acct_owner_id => v_x_joint_acct_owner_id --OUT
                                                                            ,x_return_status       => v_x_return_status --OUT
                                                                            ,x_msg_count           => v_x_msg_count --OUT
                                                                            ,x_msg_data            => v_x_msg_data --OUT
                                                                            ,x_response            => v_response_rec --OUT
                                                                            );


                                IF  (v_x_return_status = fnd_api.g_ret_sts_success) THEN
                                    COMMIT;
                                    --g_nb_compte_cree:=g_nb_compte_cree+1;
                                    --Dka_Tools_Pkg.put_log_message('le lien avec le propriétaire pour le compte bancaire'||c_bf.bank_account_name||' a bien eté etablie (parti id):'||v_ext_bank_acc_rec.acct_owner_party_id);
                                    v_message   := 'le lien avec le propriétaire pour le compte bancaire'||c_bf.bank_account_name||' a bien été établie (partie id):'||v_ext_bank_acc_rec.acct_owner_party_id;

                                ELSE
                                    v_warining_bank := TRUE;
                                    --Dka_Tools_Pkg.put_log_message('le lien avec le propriétaire pour le compte bancaire'||c_bf.bank_account_name||' n''a pas été établi (partie id):'||v_ext_bank_acc_rec.acct_owner_party_id);
                                    v_message   := 'le lien avec le propriétaire pour le compte bancaire'||c_bf.bank_account_name||' n''a pas été établi (partie id):'||v_ext_bank_acc_rec.acct_owner_party_id;


                                    FOR i IN 1..v_x_msg_count LOOP
                                    
                                      --Dka_Tools_Pkg.put_log_message(i);
                                      fnd_msg_pub.get (p_msg_index     => i
                                                      ,p_encoded       => 'F'
                                                      ,p_data          => v_x_msg_data
                                                      ,p_msg_index_out => v_msg_index_out);
                                                        
                                      if nvl(instr(p_errbuf,v_x_msg_data),0) = 0 then
                                        p_errbuf := p_errbuf || CHR(10) || v_x_msg_data;
                                      end if;
                                      
                                    END LOOP;

                                    --Dka_Tools_Pkg.put_log_message('cause : '||p_errbuf);
                                    g_message_erreur_chargement := v_message|| ' ' ||p_errbuf;
                                    v_warining_bank := TRUE;
                                    validate_banque(c_bf.segment1,c_bf.vendor_site_code,c_bf.logical_line_num,TRUE,v_errbuf,v_retcode);
                                    g_message_erreur_chargement := null;
                                    IF v_retcode = 2 THEN
                                        p_errbuf  := v_errbuf;
                                        p_retcode := v_retcode;
                                        v_message := 'Erreur lors de la non validation de la non insertion le lien avec le propriétaire pour le compte bancaire ';
                                        RAISE v_exeption;
                                    END IF;
                                    CONTINUE;

                                END IF;


                            ELSE
                                v_exist_bank := TRUE;
                                --Dka_Tools_Pkg.put_log_message('le lien avec le propriétaire pour le compte bancaire'||c_bf.bank_account_name||' existe déja (partie id):'||v_ext_bank_acc_rec.acct_owner_party_id);
                                v_message   := 'le lien avec le propriétaire pour le compte bancaire'||c_bf.bank_account_name||' existe déja (partie id):'||v_ext_bank_acc_rec.acct_owner_party_id;

                            END IF;
                            
                        END IF;
                        
                        v_message :='set_payee_instr_assignment';
                        p_instrument.instrument_type        := 'BANKACCOUNT';
                        p_instrument.instrument_id          := v_x_acct_id; --<bank account id>  IBY_EXT_BANKACCT_PUB.CREATE_EXT_BANK_ACCT API account id
                        v_p_assignment_attribs.start_date   := NVL(v_ext_bank_acc_rec.start_date, to_date('01/01/2000', 'DD/MM/YYYY'));--SYSDATE; ywa artf1986271
                        v_p_assignment_attribs.instrument   := p_instrument;
                        v_p_payee.party_id                   := v_ext_bank_acc_rec.acct_owner_party_id;--PARTY_ID -- which is party_id of the supplier
                        v_p_payee.payment_function           := 'PAYABLES_DISB';
                        v_p_payee.Party_Site_id              := v_party_site_id;
                        v_p_payee.Supplier_Site_id           := v_supplier_site_id;
                        v_p_payee.Org_Id                     := g_org_id;
                        v_p_payee.Org_Type                   := 'OPERATING_UNIT';

                        --Affectation Banque fournisseur Compte de paiement pour le site
                        iby_disbursement_setup_pub.set_payee_instr_assignment(  p_api_version                  => v_api_version
                                                                                ,p_init_msg_list                => fnd_api.g_false
                                                                                ,p_commit                       => fnd_api.g_true
                                                                                ,p_payee                        => v_p_payee
                                                                                ,p_assignment_attribs           => v_p_assignment_attribs
                                                                                ,x_return_status                => v_x_return_status
                                                                                ,x_msg_count                    => v_x_msg_count
                                                                                ,x_msg_data                     => v_x_msg_data
                                                                                ,x_assign_id                    => v_x_assign_id
                                                                                ,x_response                     => v_response_rec
                                                                                );

                        IF v_x_return_status = fnd_api.g_ret_sts_success THEN
                            --Dka_Tools_Pkg.put_log_message('L''affectation Banque fournisseur et Compte de paiement pour le site id:'||v_supplier_site_id||' a bien été établie (partie id):'||v_party_site_id);
                            v_message   := 'L''affectation Banque fournisseur et Compte de paiement pour le site id:'||v_supplier_site_id||' a bien été établie (partie id):'||v_party_site_id;
                            validate_banque(c_bf.segment1,c_bf.vendor_site_code,c_bf.logical_line_num,false,v_errbuf,v_retcode);
                            IF v_retcode = 2 THEN
                                p_errbuf  := v_errbuf;
                                p_retcode := v_retcode;
                                v_message := 'Erreur lors de L''affectation Banque fournisseur et Compte de paiement pour le site ';
                                RAISE v_exeption;
                            END IF;

                        ELSE

                            v_warining_bank := TRUE;
                            --Dka_Tools_Pkg.put_log_message('L''affectation Banque fournisseur et Compte de paiement pour le site id:'||v_supplier_site_id||' n''a pas été établie (partie id):'||v_party_site_id);
                            v_message   := 'L''affectation Banque fournisseur et Compte de paiement pour le site id:'||v_supplier_site_id||' n''a pas été établie (partie id):'||v_party_site_id;


                            FOR i IN 1..v_x_msg_count
                            LOOP
                                --Dka_Tools_Pkg.put_log_message(i);
                                fnd_msg_pub.get (p_msg_index     => i
                                                ,p_encoded       => 'F'
                                                ,p_data          => v_x_msg_data
                                                ,p_msg_index_out => v_msg_index_out
                                                );
                                                
                                if nvl(instr(p_errbuf,v_x_msg_data),0) = 0 then
                                  p_errbuf := p_errbuf || CHR(10) || v_x_msg_data;
                                end if;

                            END LOOP;

                            --Dka_Tools_Pkg.put_log_message('cause : '||p_errbuf);
                            g_message_erreur_chargement := v_message|| ' ' ||p_errbuf;
                            validate_banque(c_bf.segment1,c_bf.vendor_site_code,c_bf.logical_line_num,TRUE,v_errbuf,v_retcode);
                            g_message_erreur_chargement := null;
                            IF v_retcode = 2 THEN
                                p_errbuf  := v_errbuf;
                                p_retcode := v_retcode;
                                v_message := 'Erreur lors de la non affectation Banque fournisseur et Compte de paiement pour le site ';
                                RAISE v_exeption;
                            END IF;

                        END IF;
                    END LOOP;
                END LOOP;
              
              
              EXCEPTION
                WHEN e_pas_de_site THEN
                  Dka_Tools_Pkg.put_log_message('Pas de site, on passe a la suite');
                  CONTINUE;
              END;   --boucle globale on saute si on ne trouve pas de site ( pas de site pas de compte a rattacher)   
            END LOOP;
            
            IF v_warining_bank THEN
                p_retcode := 1;
                Dka_Tools_Pkg.put_outdebug_message('/*des banques ou agences ou comptes n''ont pas pu etre créés correctement */');
            ELSE
                Dka_Tools_Pkg.put_outdebug_message('/*tous les comptes et banques et agences ont été correctement créés*/');
            END IF ;
        
            SELECT count(1)
            INTO g_validate_banque_err
            FROM dka_ap_rep_supp_bank_tmp
            WHERE message_erreur    IS NOT NULL
            AND processed_request_id = -1;
            Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de création des banques et agences et comptes');
        END IF;
        

        /*============================================================================================*/
        /*boucle de création des relations fournisseur et factor*/
        /*============================================================================================*/
        IF p_creation_lien_factor ='Y' THEN
            Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut de création des relations fournisseur et factor');
            Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');
            Dka_Tools_Pkg.put_log_message('/*boucle de création des relations fournisseur et factor*/');
            Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');
            Dka_Tools_Pkg.put_outdebug_message('/*============================================================================================*/');
            Dka_Tools_Pkg.put_outdebug_message('/*boucle de création des relations fournisseur et factor*/');
            Dka_Tools_Pkg.put_outdebug_message('/*============================================================================================*/');
            Dka_Tools_Pkg.put_log_message('boucle de création des relations fournisseur et factor');
            v_message   := 'boucle de création des relations fournisseur et factor';
            FOR fournisseur_factor IN (SELECT vendor_id,
                                        party_id,
                                        vendor_name
                                        FROM ap_suppliers
                                        WHERE vendor_type_lookup_code='FACTOR'
                                        AND  upper(vendor_name) IN (SELECT upper(address_line1) FROM dka_ap_rep_supp_sites_tmp WHERE processed_request_id != -1 )
                                    )
            LOOP
                --Dka_Tools_Pkg.put_log_message(chr(10));
                --Dka_Tools_Pkg.put_log_message('-------------------------------------');
                --Dka_Tools_Pkg.put_log_message('fournisseur factor : '||fournisseur_factor.vendor_id);
                v_message   := 'fournisseur factor : '||fournisseur_factor.vendor_id;

                FOR fournisseur_site_factor IN (SELECT vendor_site_id,
                                        vendor_site_code,
                                        org_id,
                                        attribute13
                                        FROM ap_supplier_sites_all
                                        WHERE vendor_id = fournisseur_factor.vendor_id
                                    )
                LOOP

                    --Dka_Tools_Pkg.put_log_message('site fournisseur factor : '||fournisseur_site_factor.vendor_site_code ||' pour lorg_id ' || fournisseur_site_factor.org_id);
                    v_message   := 'site fournisseur factor : '||fournisseur_site_factor.vendor_site_code ||' pour lorg_id' || fournisseur_site_factor.org_id;
                    v_lien_f_and_ffactor_exist := FALSE;
                    FOR fournisseur_site IN ( SELECT  ass.vendor_site_id,
                                                      asup.party_id
                                                FROM  ap_suppliers  asup,
                                                      ap_supplier_sites_all ass,
                                                      DKA_AP_REP_SUPP_SITES_TMP ts
                                                WHERE asup.vendor_id                 = ass.vendor_id
                                                  AND ts.vendor_site_code            = ass.attribute13  
                                                  AND upper(ts.address_line1)        = upper(fournisseur_factor.vendor_name)  
                                                  AND ts.new_vendor_site_code_factor = fournisseur_site_factor.vendor_site_code  
                                                  AND ts.segment1                    = asup.segment1
                                                --AND ass.vendor_site_code           = fournisseur_site_factor.vendor_site_code
                                                  AND ass.attribute13                = fournisseur_site_factor.attribute13 
                                                  AND ass.org_id                     = fournisseur_site_factor.org_id
                                                  AND ass.vendor_id                 != fournisseur_factor.vendor_id
                                                  AND ass.attribute5                 = 'Y'
                                                  AND asup.vendor_type_lookup_code  != 'FACTOR'
                                                  AND upper(ass.address_line1)       = upper(fournisseur_factor.vendor_name)
                                                  AND NOT EXISTS (SELECT NULL 
                                                                    FROM iby_ext_payee_relationships iepr
                                                                  WHERE  iepr.party_id               = asup.party_id
                                                                     AND iepr.supplier_site_id       = ass.vendor_site_id
                                                                     AND iepr.remit_party_id         = fournisseur_factor.party_id
                                                                     AND iepr.remit_supplier_site_id = fournisseur_site_factor.vendor_site_id)
                                            )
                    LOOP

                        BEGIN
                            v_lien_f_and_ffactor_exist := TRUE;
                            --Dka_Tools_Pkg.put_log_message('founisseur party_id: ' ||fournisseur_site.party_id||' site fournisseur '||fournisseur_site.vendor_site_id);
                            v_message   := 'founisseur party_id: ' ||fournisseur_site.party_id||' site fournisseur '||fournisseur_site.vendor_site_id;
                            INSERT
                            INTO iby_ext_payee_relationships(relationship_id,
                                                              party_id,
                                                              supplier_site_id,
                                                              remit_party_id,
                                                              remit_supplier_site_id,
                                                              from_date,
                                                              primary_flag,
                                                              active,
                                                              created_by,
                                                              creation_date,
                                                              last_updated_by,
                                                              last_update_date,
                                                              last_update_login,
                                                              object_version_number
                                                            )
                            VALUES(iby_ext_payee_relship_seq.NEXTVAL,
                                  fournisseur_site.party_id,
                                  fournisseur_site.vendor_site_id,
                                  fournisseur_factor.party_id,
                                  fournisseur_site_factor.vendor_site_id,
                                  TRUNC(SYSDATE),
                                  'Y',
                                  'Y',
                                  fnd_global.user_id,
                                  SYSDATE,
                                  fnd_global.user_id,
                                  SYSDATE,
                                  fnd_global.user_id,
                                  1
                                );

                            COMMIT;
                        EXCEPTION
                            WHEN OTHERS THEN
                                --Dka_Tools_Pkg.put_log_message('le lien entre le site fournisseur id'||fournisseur_site.vendor_site_id||' et le site founisseur factor: '||fournisseur_site_factor.vendor_site_id||'n''a pas pu etre inséré' );
                                v_message   := 'le lien entre le site fournisseur id'||fournisseur_site.vendor_site_id||' et le site founisseur factor: '||fournisseur_site_factor.vendor_site_id||'n''a pas pu etre inséré';
                                p_retcode:=1;
                                CONTINUE;
                        END;

                    END LOOP;

                    IF NOT v_lien_f_and_ffactor_exist THEN
                        Dka_Tools_Pkg.put_log_message('fournisseur parent n''a pas pu etre trouvé pour site fournisseur factor : '||fournisseur_site_factor.vendor_site_code ||' pour l''UO: ' || fournisseur_site_factor.org_id);
                        p_retcode:=1;
                    END IF;

                END LOOP;
            END LOOP;
        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de création des relations fournisseur et factor');
        END IF;

        /*============================================================================================*/
        -- PHASE DE FIN DU TRAITEMENT MAITRE --
        /*============================================================================================*/
        ----------------------------------
        -- PHASE DE BILAN DU TRAITEMENT --
        ----------------------------------

        Report_Bilan(v_errbuf,v_retcode);

        IF v_retcode = 2
        THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RAISE v_exeption;
        END IF;
        
        /*============================================================================================*/
        -- Liste des anomalies l'ensemble des erreurs spécifiques et les erreurs de l'OI --
        /*============================================================================================*/
        
        liste_des_anomalies(v_errbuf,v_retcode);

        IF v_retcode = 2
        THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RAISE v_exeption;
        END IF;

        COMMIT;
        Dka_Tools_Pkg.put_outdebug_message( p_errbuf);
        Dka_Tools_Pkg.put_log_message( CHR(10)||p_errbuf||CHR(10));
        Dka_Tools_Pkg.put_log_message('==========================================================================');
        Dka_Tools_Pkg.put_log_message( 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
        Dka_Tools_Pkg.put_log_message('==========================================================================');
        --Dka_Tools_Pkg.put_outdebug_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'FIN DE L''INTERFACE');

    EXCEPTION
        WHEN v_exeption THEN
            --p_retcode := 2;
            --p_errbuf  := 'Erreur EXCEPTION v_exception dans pkg.proc/fonc '||v_package||'.'||v_procedure;
            Dka_Tools_Pkg.put_outdebug_message('-------------------- ERREUR --------------------');
            Dka_Tools_Pkg.put_outdebug_message('Package   : '||v_package);
            Dka_Tools_Pkg.put_outdebug_message('Procédure : '||v_procedure);
            Dka_Tools_Pkg.put_outdebug_message('Exception : OTHERS');
            Dka_Tools_Pkg.put_outdebug_message('Message   : '||v_message);
            Dka_Tools_Pkg.put_log_message('Cause     : '||p_errbuf);
            Dka_Tools_Pkg.put_outdebug_message('------------------------------------------------');
            Dka_Tools_Pkg.put_outdebug_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_procedure||' : EXCEPTION v_exeption ');
            Dka_Tools_Pkg.put_log_message( '==> Fin de la procédure '||v_procedure||' : EXCEPTION v_exeption ');
            Dka_Tools_Pkg.put_log_message('=========================================================================');
            Dka_Tools_Pkg.put_log_message('Traitement '||v_nom_traitement||' terminé en erreur         ');
            Dka_Tools_Pkg.put_log_message('=========================================================================');
            ROLLBACK;

       WHEN OTHERS THEN
            v_sqlerrm := SUBSTR(SQLERRM,1,200);
            p_retcode := 2;
            p_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc '||v_package||'.'||v_procedure;
            Dka_Tools_Pkg.put_outdebug_message('-------------------- ERREUR --------------------');
            Dka_Tools_Pkg.put_outdebug_message('Package   : '||v_package);
            Dka_Tools_Pkg.put_outdebug_message('Procédure : '||v_procedure);
            Dka_Tools_Pkg.put_outdebug_message('Exception : OTHERS');
            Dka_Tools_Pkg.put_outdebug_message('Message   : '||v_message);
            Dka_Tools_Pkg.put_log_message( CHR(10)||p_errbuf);
            Dka_Tools_Pkg.put_outdebug_message('Cause     : '||v_sqlerrm);
            Dka_Tools_Pkg.put_outdebug_message('------------------------------------------------');
            Dka_Tools_Pkg.put_log_message('=========================================================================');
            Dka_Tools_Pkg.put_log_message('Traitement '||v_nom_traitement||' terminé en erreur         ');
            Dka_Tools_Pkg.put_log_message('=========================================================================');
            ROLLBACK;

    END main;
    
    --RBE EDB071
    /*
    *************************************************************************
    * PROCEDURE NAME : update_parent_vendor
    *
    * DESCRIPTION
    *  Procédure de Mise à jour de la société mère sur fournisseurs
    *
    * PARAMETERS
    * ==========
    * NAME              DESCRIPTION
    .* ----------------- ------------------------------------------------------
    * p_errbuf         Retour de message éventuel
    * p_retcode        Statut du traitement en sortie
    ************************************************************************
    */
    PROCEDURE update_parent_vendor (
        p_errbuf    OUT      VARCHAR2,
        p_retcode   OUT      NUMBER
        )
    IS
        CURSOR cur_fournisseur
        IS SELECT rst.*
        FROM dka_ap_rep_supp_tmp rst
        WHERE 1=1
        AND  societe_mere IS NOT NULL;
        
        v_count_frs         NUMBER:= 0;
        v_count_frs_maj     NUMBER:= 0;
        v_vendor_id         NUMBER;
        v_parent_vendor_id  NUMBER;
        v_message           VARCHAR2(500);
        v_vendor_name       VARCHAR2(200);
        v_vendor_num        VARCHAR2(200);
        v_statut            VARCHAR2(10);
        i                   NUMBER:=0;
        
        TYPE rec_vendor IS RECORD( vendor_num      VARCHAR2(200),
                                   vendor_name     VARCHAR2(200),
                                   societe_mere    VARCHAR2(200),
                                   statut          VARCHAR2(2)
                                    );
                                    
        TYPE tab_vendors IS TABLE OF rec_vendor INDEX BY BINARY_INTEGER;
        v_tab_vendors   tab_vendors;
        
    BEGIN
        -- Début du Programme --
        p_retcode   := 0;
        p_errbuf    := NULL;

        Dka_Tools_Pkg.put_out_header;
        
        FOR rec_fournisseur IN cur_fournisseur
        LOOP
            v_statut := 'KO';
            v_vendor_id         := NULL;
            v_parent_vendor_id  := NULL;
            v_count_frs := v_count_frs + 1;
            BEGIN
                SELECT vendor_id
                INTO v_vendor_id
                FROM AP_SUPPLIERS
                WHERE segment1 = rec_fournisseur.segment1;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                    v_vendor_id := NULL;
                    v_message := 'Le fournisseur '|| rec_fournisseur.segment1 ||' n''est pas trouvé';
                    Dka_Tools_Pkg.put_log_message( v_message);
                    p_retcode := 1;
               WHEN OTHERS THEN
                    v_vendor_id := NULL;
                    v_message := SUBSTR(SQLERRM,1,200);
                    p_retcode := 2;
                    Dka_Tools_Pkg.put_log_message('Erreur     : '||v_message);
            END;

            BEGIN
                SELECT vendor_id
                INTO v_parent_vendor_id
                FROM PO_VENDORS
                WHERE segment1 = rec_fournisseur.societe_mere;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                    v_parent_vendor_id := NULL;
                    v_message := 'La société mère '|| rec_fournisseur.societe_mere ||' n''est pas trouvée';
                    Dka_Tools_Pkg.put_log_message( v_message);
                    p_retcode := 1;
               WHEN OTHERS THEN
                    v_parent_vendor_id := NULL;
                    v_message := SUBSTR(SQLERRM,1,200);
                    p_retcode := 2;
                    Dka_Tools_Pkg.put_log_message('Erreur     : '||v_message);
            END;
            
            IF v_vendor_id IS NOT NULL AND v_parent_vendor_id IS NOT NULL 
            THEN
                UPDATE AP_SUPPLIERS
                SET parent_vendor_id = v_parent_vendor_id
                WHERE vendor_id = v_vendor_id
                ;
                
                v_count_frs_maj := v_count_frs_maj + 1;
                
                v_statut := 'OK';
                
            END IF;
            
            v_tab_vendors(i).vendor_num := rec_fournisseur.segment1;
            v_tab_vendors(i).vendor_name := rec_fournisseur.vendor_name;
            v_tab_vendors(i).societe_mere := rec_fournisseur.societe_mere;
            v_tab_vendors(i).statut := v_statut;
            i := i + 1;
        END LOOP;
        
        IF v_count_frs = 0 THEN
            p_retcode := 1;
            v_message := 'Aucune donnée traitée ';
            Dka_Tools_Pkg.put_log_message( v_message);
            Fnd_File.put_line (Fnd_File.output, v_message);
            Fnd_File.put_line (Fnd_File.output, ' ');
        ELSE
        
            --Sortie
            Fnd_File.put_line (Fnd_File.output, ' ');
            Fnd_File.put_line (Fnd_File.output, 'Nombre de fournisseurs sélectionnés : '||TO_CHAR(v_count_frs));
            Fnd_File.put_line (Fnd_File.output, 'Nombre de fournisseurs mis à jour   : '||TO_CHAR(v_count_frs_maj));
            Fnd_File.put_line (Fnd_File.output, ' ');
            
            Fnd_File.put_line (Fnd_File.output, 'Liste des fournisseurs traités :');
            Fnd_File.put_line (Fnd_File.output, ' ');
            
            Fnd_File.put_line (Fnd_File.output, 'N° fournisseur |Nom fournisseur             |N° société mère |Statut mise à jour');
            Fnd_File.put_line (Fnd_File.output, '---------------|----------------------------|----------------|------------------');
            FOR j IN v_tab_vendors.first..v_tab_vendors.last
            LOOP
            Fnd_File.put_line (Fnd_File.output, RPAD(v_tab_vendors(j).vendor_num,15,' ')||'|'||RPAD(v_tab_vendors(j).vendor_name,28,' ')||'|'||RPAD(v_tab_vendors(j).societe_mere,16,' ')||'|'||v_tab_vendors(j).statut);
            END LOOP;
        
        END IF;
        
        Fnd_File.put_line (Fnd_File.OUTPUT, '+-------------------------------------------------------------------------+');
        
    EXCEPTION
       WHEN OTHERS THEN
            v_message := SUBSTR(SQLERRM,1,200);
            p_retcode := 2;
            Dka_Tools_Pkg.put_log_message('Erreur     : '||v_message);
    END update_parent_vendor;
    
END DKA_REPAPFRSIMP_PKG;
/
SHOW ERRORS;
EXIT
