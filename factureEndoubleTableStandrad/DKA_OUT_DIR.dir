create or replace PACKAGE BODY DKA_REPAPFCTIMP_PKG IS
    ----------------------------------------------------------------------
    -- PROGRAM : DKA_REPAPFCTIMP_PKG.sql                                 -
    -- Version : 1.0                                                     -
    -- AUTEUR  : Y.Warid / SOCIETE : CAPGEMINI                           -
    -- DATE    : 18/04/16                                                -
    ----------------------------------------------------------------------
    -- APPELE PAR : Reprise AP factures fournisseurs Import               -
    -- FONCTION   : SFD003                                               -
    --                                                                   -
    --                                                                   -
    ----------------------------------------------------------------------
    -- VERSION              :        1.1                                 -
    -- PROGRAMME MODIFIE LE :        20/10/2016                          -
    -- PAR                  :        Maxime EGOT                         -
    -- NUM_ANOMALIE         :        artf2032401                         -
    -- OBJET                :        Correction                          -
    ----------------------------------------------------------------------
    -- VERSION              :        1.2                                 -
    -- PROGRAMME MODIFIE LE :        20/10/2016                          -
    -- PAR                  :        Maxime EGOT                         -
    -- NUM_ANOMALIE         :        artf2032604                         -
    -- OBJET                :        Correction                          -
    ----------------------------------------------------------------------
    -- VERSION              :        1.3                                 -
    -- PROGRAMME MODIFIE LE :        26/10/2016                          -
    -- PAR                  :        Maxime EGOT                         -
    -- NUM_ANOMALIE         :        artf2034435                         -
    -- OBJET                :        Correction                          -
    ----------------------------------------------------------------------
    -- VERSION              :        1.4                                 -
    -- PROGRAMME MODIFIE LE :        10/11/2016                          -
    -- PAR                  :        Josselin LAUNAY                     -
    -- NUM_ANOMALIE         :        artf2043352                         -
    -- OBJET                :        Correction                          -
    ----------------------------------------------------------------------
    -- VERSION              :        1.5                                 -
    -- PROGRAMME MODIFIE LE :        14/11/2016                          -
    -- PAR                  :        Nordine SSABRI                      -
    -- NUM_ANOMALIE         :        artf2043247 artf2043246 artf2043245 -
    -- OBJET                :        Correction                          -
    ----------------------------------------------------------------------
    -- VERSION              :        1.6                                 -
    -- PROGRAMME MODIFIE LE :        23/11/2016                          -
    -- PAR                  :        Nordine SSABRI                      -
    -- NUM_ANOMALIE         :        artf2043247 artf2050056             -
    -- OBJET                :        Modification                        -
    ----------------------------------------------------------------------
    -- VERSION              :        1.7                                 -
    -- PROGRAMME MODIFIE LE :        25/11/2016                          -
    -- PAR                  :        Nordine SSABRI                      -
    -- NUM_ANOMALIE         :        artf2050658                         -
    -- OBJET                :        Ajout d'un contrôle sur le site frs -
    ----------------------------------------------------------------------
    -- VERSION              :        1.8                                 -
    -- PROGRAMME MODIFIE LE :        25/11/2016                          -
    -- PAR                  :        Nordine SSABRI                      -
    -- NUM_ANOMALIE         :        artf2050658                         -
    -- OBJET                :        Ajout d'un contrôle sur le site frs -
    ----------------------------------------------------------------------
    -- VERSION              :        1.9                                 -
    -- PROGRAMME MODIFIE LE :        01/12/2016                          -
    -- PAR                  :        Maxime EGOT                         -
    -- NUM_ANOMALIE         :        artf2052442 et artf2052447          -
    -- OBJET                :                                            -
    ----------------------------------------------------------------------
    -- VERSION              :        1.10                                -
    -- PROGRAMME MODIFIE LE :        22/12/2016                          -
    -- PAR                  :        Redouane BELAYACHI                  -
    -- NUM_ANOMALIE         :        artf2069783                         -
    -- OBJET                :                                            -
    ----------------------------------------------------------------------
    -- VERSION              :        1.11                                -
    -- PROGRAMME MODIFIE LE :        06/01/2017                          -
    -- PAR                  :        Maxime EGOT                         -
    -- NUM_ANOMALIE         :        artf2052451                         -
    -- OBJET                :        Gestion des EXPENSE REPORT          -
    ----------------------------------------------------------------------
    -- VERSION              :        1.12                                -
    -- PROGRAMME MODIFIE LE :        10/04/2017                          -
    -- PAR                  :        Younes WARID                        -
    -- NUM_ANOMALIE         :        artf2135344                         -
    -- OBJET                :        Segment 5 InterCo pour les Fournisseurs Groupe   -
    ----------------------------------------------------------------------
    --- HISTORIQUE DES MODIFICATIONS
    --- Date       Qui Description
    --- ---------- --- -------------------------------------------------------------------------
    --  24/04/2017 YWA artf2145111 
    --  05/05/2017 YWA artf2147106 EDB059 - Enrichissement des motifs de blocages REPRISE
    --  30/05/2017 YWA artf2161564 : Reprise en cours Fournisseur : Vendor_site_code = OFFICE table de reprise factures (en tête)
    --  10/07/2017 OBE artf2191277 : Reprise en cours Fournisseur : EDB077 - Reprise des factures bloquées au paiement
    --  19/07/2017 OBE artf2191277 : Correction
    --  28/07/2017 MEG artf2135344 : Purge des données ap_interface_rejections avant les données de open interface AP 
    --  28/09/2017 YWA artf2228134 : Reprise en cours Fournisseur : EDB080 - Reprise en cours fournisseurs - MAJ RG pour déterminer Classe Reglements 
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
    g_source                       VARCHAR2(30) ;

    g_nb_facture_cree_oi           NUMBER     :=0;
    g_nb_four_factor_cree_oi       NUMBER    :=0;
    g_nb_lignes_fact_cree_oi       NUMBER    :=0;
    g_nb_site_four_factor_cree_oi  NUMBER    :=0;
    g_nb_blocage_cree_oi           NUMBER    :=0;
    g_nb_conatct_factor_cree_oi    NUMBER    :=0;

    g_nb_blocages_charger          NUMBER    :=0;
    g_nb_entete_fact_charger       NUMBER    :=0;
    g_nb_ligne_fact_charger        NUMBER    :=0;
    g_nb_bank_charger              NUMBER    :=0;

    g_nb_facture_cree              NUMBER     :=0;
    g_nb_four_factor_cree          NUMBER    :=0;
    g_nb_ligne_fact_cree           NUMBER    :=0;
    g_nb_site_four_factor_cree     NUMBER    :=0;
    g_nb_blocage_cree              NUMBER    :=0;
    g_nb_conatct_factor_cree       NUMBER    :=0;

    g_nb_bank_cree                 NUMBER    :=0;
    g_nb_agence_cree               NUMBER    :=0;
    g_nb_compte_cree               NUMBER    :=0;

    g_nb_rejet                     NUMBER    :=0;
    g_nb_rejet_dka_entete          NUMBER    :=0;
    g_nb_rejet_dka_ligne           NUMBER    :=0;
    g_nb_rejet_dka_blocage         NUMBER    :=0;

    g_message_erreur_chargement    VARCHAR2(500)    :=null;


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

        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début init');


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
        g_source                         := 'REPRISE';
        g_user_id                      :=  fnd_profile.value ('USER_ID');

        /*
        BEGIN
            SELECT user_id
            INTO   g_user_id
            FROM  fnd_user
            WHERE user_name ='CAPTECH' ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                p_errbuf:= 'Erreur user CAPTECH introuvable ';
                Fnd_File.put_line (Fnd_File.LOG,p_errbuf);
                p_retcode := 2;
                RAISE program_error;
            WHEN OTHERS THEN
                p_errbuf:= SQLERRM;
                Fnd_File.put_line (Fnd_File.LOG,p_errbuf);
                p_retcode := 2;
                RAISE program_error;
        END;*/

        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin init');




    EXCEPTION
        WHEN program_error THEN
             Fnd_File.put_line (Fnd_File.output, 'ERREUR : ' || p_errbuf);
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

    PROCEDURE init_environement (
        p_errbuf    OUT      VARCHAR2,
        p_retcode   OUT      NUMBER
        )
    IS
        v_resp_id                               NUMBER;
        v_resp_appl_id                          NUMBER;
    BEGIN
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut init_environement');
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
        WHERE ROWNUM = 1;*/ --Car on ne veut qu'une seule responsabilité

         SELECT responsibility_id
              ,application_id
        INTO   v_resp_id
              ,v_resp_appl_id
        FROM  fnd_responsibility fr,
              hr_operating_units hou
        WHERE hou.organization_id = g_org_id
        AND   fr.responsibility_key = hou.name||'_AP_ADMINISTRATEUR';

        fnd_global.apps_initialize(g_user_id, v_resp_id, v_resp_appl_id);

        -- Initialiser org_id
        mo_global.set_org_context(g_org_id,NULL,'SQLAP');

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin init_environement');

    EXCEPTION
        WHEN program_error THEN
            Fnd_File.put_line (Fnd_File.output, 'ERREUR : ' || p_errbuf);
        WHEN NO_DATA_FOUND THEN
            p_retcode   := 1;
            p_errbuf    := 'init_environement: '||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, 'ERREUR : ' || p_errbuf ||' pour l'''||g_org_id);
        WHEN OTHERS
        THEN
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
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Launch_Loader');

        Fnd_File.put_line (Fnd_File.LOG, CHR(10));
        Fnd_File.put_line (Fnd_File.LOG, 'CHARGEMENT DU FICHIER :');
        Fnd_File.put_line (Fnd_File.LOG, '----------------------');
        ------------------------------------------------------
        -- Lancement du traitement de chargement du fichier --
        ------------------------------------------------------

        -- Lancement du traitement
        g_loader_request_id          := Fnd_Request.submit_request (
                                             'DKA'                            -- APPL
                                            ,'DKA_REPAPFCTIMP_LOADER'                -- PROG
                                            ,NULL                             -- PROGRAM_NAME
                                            ,NULL                             -- START
                                            ,FALSE                            -- SUB_REQUEST
                                            );
        Fnd_File.put_line (Fnd_File.output, 'Le N°du traitement de chargement des données dans les tables spécifiques :' || g_loader_request_id);
        IF g_loader_request_id = 0
        THEN
            p_retcode    := 2;
            Fnd_File.put_line (Fnd_File.LOG, 'ERREUR : Le traitement de chargement du fichier a échoué' || CHR(10) ||
                                            'PROGRAMME  : DKA_REPAPFCTIMP_LOADER');
        ELSE
            COMMIT;
            Fnd_File.put_line (Fnd_File.LOG, '=> LOAD REQUEST ID= ' || g_loader_request_id);
            Fnd_File.put_line (Fnd_File.LOG, 'Numéro du traitement de chargement du fichier : ' || g_loader_request_id);
            -- Attente de la fin du traitement
            IF NOT (Fnd_Concurrent.wait_for_request (g_loader_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
            THEN
                p_Errbuf  := v_message;
                Fnd_File.put_line (Fnd_File.LOG, 'ERREUR : Attente de la fin du programme de chargement du fichier dépassée : Fin du traitement' || CHR(10) ||
                                                'MESSAGE : ' || v_message || CHR(10) );
            END IF;

            IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL')
            THEN
                Fnd_File.put_line (Fnd_File.LOG, 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);

                null;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
            THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement de chargement en warning '|| g_loader_request_id);
                p_retcode    := 1;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')
            THEN
                p_retcode := 2;
                p_Errbuf  := 'ERREUR : Fin anormale du traitement de chargement : '||v_message;

                Fnd_File.put_line (Fnd_File.LOG, 'ERREUR : Fin anormale du traitement de chargement '|| g_loader_request_id  || CHR(10) ||
                                                'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                                'MESSAGE : ' || v_message || CHR(10) );
            END IF;

        END IF;

        SELECT count(*) INTO g_nb_entete_fact_charger FROM dka_ap_rep_entete_facture_tmp where load_request_id=g_loader_request_id;

        SELECT count(*) INTO g_nb_ligne_fact_charger FROM dka_ap_rep_lignes_facture_tmp WHERE load_request_id=g_loader_request_id;

        SELECT count(*) INTO g_nb_blocages_charger FROM dka_ap_rep_blocages_tmp WHERE  load_request_id=g_loader_request_id;

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Launch_Loader');

    EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'LAUNCH_LOADER : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Launch_Loader : EXCEPTION OTHERS ');
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

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Report_Bilan');

        --------------------
        -- Initialisation --
        --------------------

        p_Errbuf  := NULL;
        p_retcode := 0;

        Fnd_File.put_line (Fnd_File.output,'-------------------------------------------------------------------------------------------------------------------------------------------------------');
        Fnd_File.put_line (Fnd_File.output,'---------------------------------------------------------------BILAN-----------------------------------------------------------------------------------');
        Fnd_File.put_line (Fnd_File.output,'-------------------------------------------------------------------------------------------------------------------------------------------------------');
        Fnd_File.put_line (Fnd_File.output,'   . Nombre d''enregistrements chargés dans la table spécifique des factures fournisseurs           : ' || TO_CHAR(g_nb_entete_fact_charger)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'   . Nombre d''enregistrements chargés dans la table spécifique des lignes de ventilation facture   : ' || TO_CHAR(g_nb_ligne_fact_charger)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'   . Nombre d''enregistrements chargés dans la table spécifique des blocages factures               : ' || TO_CHAR(g_nb_blocages_charger)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'-------------------------------------------------------------------------------------------------------------------------------------------------------');
        Fnd_File.put_line (Fnd_File.output,'   . Nombre d''enregistrements chargés dans l''Open Interface des factures fournisseurs             : ' || TO_CHAR(g_nb_facture_cree_oi)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'   . Nombre d''enregistrements chargés dans l''Open Interface des lignes de ventilation facture     : ' || TO_CHAR(g_nb_lignes_fact_cree_oi)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'-------------------------------------------------------------------------------------------------------------------------------------------------------');
        Fnd_File.put_line (Fnd_File.output,'   . Nombre d''enregistrements chargés dans la table standard des factures                          : ' || TO_CHAR(g_nb_facture_cree)||CHR(10));
        --Fnd_File.put_line (Fnd_File.output,'   . Nombre d''enregistrements chargés dans la table standard des lignes de ventilation             : ' || TO_CHAR(g_nb_ligne_fact_cree)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'   . Nombre d''enregistrements chargés dans la table standard des blocages factures                 : ' || TO_CHAR(g_nb_blocage_cree)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'-------------------------------------------------------------------------------------------------------------------------------------------------------');
        Fnd_File.put_line (Fnd_File.output,'   . Nombre d''enregistrements en rejet dans la table spécifique des factures fournisseurs          : ' || TO_CHAR(g_nb_rejet_dka_entete)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'   . Nombre d''enregistrements en rejet dans la table spécifique des lignes de ventilation facture  : ' || TO_CHAR(g_nb_rejet_dka_ligne)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'   . Nombre d''enregistrements en rejet dans la table spécifique des blocages factures              : ' || TO_CHAR(g_nb_rejet_dka_blocage)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'   . Nombre d''enregistrements en rejet dans l''Open Interface                                      : ' || TO_CHAR(g_nb_rejet)||CHR(10));
        Fnd_File.put_line (Fnd_File.output,'-------------------------------------------------------------------------------------------------------------------------------------------------------');

        Fnd_File.put_line (Fnd_File.output,CHR(10));

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Report_Bilan');

    EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'REPORT_BILAN : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
    END Report_Bilan;


    /*=========================================================================*/
    /* PROCEDURE NAME :   program_import_factures
    /*
    /* DESCRIPTION  Traitement standard d import des factures fournisseurs
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/

    PROCEDURE program_import_factures(  p_errbuf            OUT VARCHAR2,
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
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut program_import_factures');
        g_import_request_id:= fnd_request.submit_request
                               ( application                  => 'SQLAP'
                                ,program                      => 'APXIIMPT'
                                ,description                  => NULL
                                ,start_time                   => NULL
                                ,sub_request                  => FALSE
                                ,argument1                    => g_org_id
                                ,argument2                    => g_source
                                ,argument3                    => NULL
                                ,argument4                    => NULL
                                ,argument5                    => NULL
                                ,argument6                    => NULL
                                ,argument7                    => NULL
                                ,argument8                    => 'N'
                                 );

        Fnd_File.put_line (Fnd_File.output,'Le N°du traitement du traitement standard d''import des factures fournisseurs : ' || g_import_request_id);
        IF g_import_request_id = 0 THEN
            p_retcode    := 2;
            Fnd_File.put_line (Fnd_File.LOG, 'ERREUR : Le traitement standard d''import des factures fournisseurs' || CHR(10) ||
                                            'PROGRAMME  : Programme d''importation de l''interface coopérative d''Oracle Payables ');
        ELSE
            COMMIT;
            Fnd_File.put_line (Fnd_File.LOG, 'Numéro du traitement standard d''import des factures fournisseurs: ' || g_import_request_id);

            --********************************************
            -- Wait for the concurrent program to complete
            --********************************************
            IF NOT (Fnd_Concurrent.wait_for_request (g_import_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message)) THEN

                p_errbuf  := v_message;
                Fnd_File.put_line (Fnd_File.LOG, 'ERREUR : Attente de la fin du programme  dépassée : Fin du traitement' || CHR(10) ||
                                                'MESSAGE : ' || v_message || CHR(10) );
            END IF;

            IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN

                Fnd_File.put_line (Fnd_File.LOG, 'Statut de fin : ' || v_phase || '/' || v_status);

                SELECT count(invoice_id)
                  INTO v_nb_ok
                  FROM ap_invoices_interface
                 WHERE status = 'PROCESSED'
                   AND request_id = g_import_request_id
                   AND org_id = g_org_id
                   AND source = g_source;

                SELECT count(invoice_id)
                  INTO v_nb_rejet
                  FROM ap_invoices_interface
                 WHERE status = 'REJECTED'
                   AND org_id = g_org_id
                   AND source = g_source;

                g_nb_rejet := g_nb_rejet + v_nb_rejet;

                Fnd_File.put_line (Fnd_File.LOG,'Nombre de factures fournisseurs correctement créé: '||v_nb_ok );
                Fnd_File.put_line (Fnd_File.LOG,'Nombre de factures fournisseurs en rejet         : '||v_nb_rejet );

                g_nb_facture_cree:= g_nb_facture_cree + v_nb_ok;

                IF v_nb_rejet !=0 THEN
                    Fnd_File.put_line (Fnd_File.output,'-------------------------------------------------------------------------------------------------------------------------------------------------------');
                    Fnd_File.put_line (Fnd_File.output,'-------------------------------------------REJETS du traitement standard pour l''UO '||g_org_id||'-------------------------------------------------------');
                    Fnd_File.put_line (Fnd_File.output,'-------------------------------------------------------------------------------------------------------------------------------------------------------');
                    Fnd_File.put_line (Fnd_File.output,RPAD('ID FACTURE',15,' ')||RPAD('NUMERO FACTURE',30,' ')||RPAD('ID LINE FACTURE',20,' ')||RPAD('NUMERO LINE' ,20,' ')||'MOTIF');
                    Fnd_File.put_line (Fnd_File.output,'-------------------------------------------------------------------------------------------------------------------------------------------------------');
                    Fnd_File.put_line (Fnd_File.output,chr(10));
                    --Fnd_File.put_line (Fnd_File.LOG,'------------------Liste des factures en rejet -----------------------');
                    FOR rejections IN (SELECT   air.parent_id,
                                                aii.invoice_id,
                                                aii.invoice_num,
                                                null line_id,
                                                null line_num,
                                                --fvl.meaning,
                                                fvl.description
                                        FROM    ap_interface_rejections air,
                                                ap_invoices_interface aii,
                                                fnd_lookup_values fvl
                                        WHERE aii.status ='REJECTED'
                                        AND fvl.lookup_code =air.reject_lookup_code
                                        AND fvl.language = 'F'
                                        AND fvl.lookup_type= 'REJECT CODE'
                                        AND air.parent_table='AP_INVOICES_INTERFACE'
                                        AND aii.invoice_id=air.parent_id
                                        AND  aii.org_id = g_org_id
                                        AND  aii.source = g_source

                                        UNION

                                        SELECT   air.parent_id,
                                                aii.invoice_id,
                                                aii.invoice_num,
                                                aili.invoice_line_id line_id,
                                                aili.line_number line_num,
                                                --fvl.meaning,
                                                fvl.description
                                        FROM    ap_interface_rejections air,
                                                ap_invoices_interface aii,
                                                ap_invoice_lines_interface aili,
                                                fnd_lookup_values fvl
                                        WHERE aii.status ='REJECTED'
                                        AND fvl.lookup_code =air.reject_lookup_code
                                        AND fvl.language = 'F'
                                        AND fvl.lookup_type= 'REJECT CODE'
                                        AND   air.parent_table='AP_INVOICE_LINES_INTERFACE'
                                        AND aili.invoice_line_id =air.parent_id
                                        AND aili.invoice_id = aii.invoice_id
                                        AND  aii.org_id = g_org_id
                                        AND  aii.source = g_source
                                        order by invoice_id ,line_id

                                        )
                    LOOP
                        --Fnd_File.put_line (Fnd_File.LOG,'ID de la facture INVOICE_ID: '||rejections.invoice_id);
                        --Fnd_File.put_line (Fnd_File.LOG,'numéro de la facture INVOICE_NUM: '||rejections.invoice_num);
                        --IF rejections.line_number IS NOT NULL THEN
                            Fnd_File.put_line (Fnd_File.output,RPAD(nvl(to_char(rejections.invoice_id),' '),15,' ')||RPAD(rejections.invoice_num,30,' ')||RPAD(nvl(to_char(rejections.line_id),' '),20,' ')||RPAD(nvl(to_char(rejections.line_num),' ') ,20,' ')||rejections.description);
                            --Fnd_File.put_line (Fnd_File.LOG,'ID de la ligne de facture INVOICE_LINE_ID: '||rejections.invoice_line_id);
                            --Fnd_File.put_line (Fnd_File.LOG,'Numéro de la ligne de ventilation : '||rejections.line_number);
                        --END IF;
                        --Fnd_File.put_line (Fnd_File.LOG,'Message d''erreur : '||rejections.description);

                    END LOOP;

                p_retcode    := 1;
                END IF;


            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN

                Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement standard d''import des factures fournisseurs en warning '|| g_import_request_id);
                v_message  := 'ERREUR : Fin du traitement en warning: '||v_message;
                p_retcode    := 1;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN

                p_retcode := 2;
                v_message  := 'ERREUR : Fin anormale du traitement standard d''import des factures fournisseurs : '||v_message;

                Fnd_File.put_line (Fnd_File.LOG, 'ERREUR : Fin anormale du traitement '|| g_import_request_id  || CHR(10) ||
                                                'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                                'MESSAGE : ' || v_message || CHR(10) );
            END IF;
            p_errbuf :=v_message;

        END IF;
        Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin program_import_factures');
    END program_import_factures;



    /*=========================================================================*/
    /* PROCEDURE NAME : purge_data
    /*
    /* DESCRIPTION
    /*  Purge des données des opens interfaces
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
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - début ' || v_current_program_unit);

        -- Reprise des rejets
        UPDATE dka_ap_rep_entete_facture_tmp dar
           SET dar.processed_request_id = -1
         WHERE EXISTS (SELECT aii.*
                  FROM ap_invoices_interface aii, po_vendors pv
                 WHERE aii.invoice_num = dar.invoice_num
                   AND pv.segment1 = dar.vendor_num
                   --AND substr(dar.vendor_site_code,
                              --INSTR(dar.vendor_site_code, '-') + 1) like
                       --aii.vendor_site_code || '%'
                   AND pv.vendor_id = aii.vendor_id
                   AND aii.status = 'REJECTED');

       -- Reprise des rejets au niveau ligne
       UPDATE dka_ap_rep_lignes_facture_tmp dar
          SET dar.processed_request_id = -1
        WHERE EXISTS (SELECT aii.*
                 FROM ap_invoices_interface aii, po_vendors pv
                WHERE aii.invoice_num = dar.invoice_num
                  AND pv.segment1 = dar.vendor_num
                  AND pv.vendor_id = aii.vendor_id
                  AND aii.status = 'REJECTED');

        DELETE
        FROM   ap_interface_rejections
        WHERE  parent_id IN (SELECT invoice_id FROM ap_invoices_interface WHERE status = 'REJECTED');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||'-> AP_INTERFACE_REJECTIONS : '||SQL%ROWCOUNT);

        DELETE
        FROM   ap_invoice_lines_interface
        WHERE  invoice_id in (SELECT invoice_id FROM ap_invoices_interface WHERE status = 'REJECTED');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||'-> AP_INVOICE_LINES_INTERFACE : '||SQL%ROWCOUNT);

        DELETE
        FROM   ap_invoices_interface
        WHERE  status = 'REJECTED';
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||'-> AP_INVOICES_INTERFACE : '||SQL%ROWCOUNT);
        
        --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||'-> ap_sup_site_contact_int : '||SQL%ROWCOUNT);

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - fin ' || v_current_program_unit);
        
    END purge_data;



    /*=========================================================================*/
    /* PROCEDURE NAME : insert_ap_invoices_interface
    /*
    /* DESCRIPTION  :   Procédure d'insertion dans l'open interface ap_invoices_interface
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
     /*=========================================================================*/

    FUNCTION insert_ap_invoices_interface(p_ap_invoices_interface_rec ap_invoices_interface%ROWTYPE
                                    )
    RETURN     NUMBER
    IS

    BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut insert_ap_invoices_interface');
        INSERT
        INTO   ap_invoices_interface
        VALUES p_ap_invoices_interface_rec;
        --Fnd_File.put_line (Fnd_File.LOG,'la facture '||p_ap_invoices_interface_rec.invoice_num||' a bien été insérée dans l''open interface');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin insert_ap_invoices_interface');
        return 0;
    EXCEPTION
        WHEN OTHERS THEN
            Fnd_File.put_line (Fnd_File.LOG,'erreur lors de l''insertion de la facture '||p_ap_invoices_interface_rec.invoice_num||' dans l''open interface');
            Fnd_File.put_line (Fnd_File.LOG,'Cause:'||SQLERRM);
            g_message_erreur_chargement := substr(SQLERRM,0,500) ;
            return 1;

    END insert_ap_invoices_interface;

    /*=========================================================================*/
    /* PROCEDURE NAME : insert_ap_invoice_lines_intrf
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

    FUNCTION insert_ap_invoice_lines_intrf(p_ap_inv_lines_interface_rec ap_invoice_lines_interface%ROWTYPE)
    RETURN     NUMBER
    IS

    BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut insert_ap_invoice_lines_intrf');
        INSERT
        INTO   ap_invoice_lines_interface
        VALUES p_ap_inv_lines_interface_rec;

        --Fnd_File.put_line (Fnd_File.LOG,'la ligne de ventilation '||p_ap_inv_lines_interface_rec.line_number||' a bien été insérée dans l''open interface pour la facture ID: '||p_ap_inv_lines_interface_rec.invoice_id);
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin insert_ap_invoice_lines_intrf');
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            --Fnd_File.put_line (Fnd_File.LOG,'erreur lors de l''insertion de la ligne de facture '||p_ap_inv_lines_interface_rec.line_number||' dans l''open interface pour la facture ID: '||p_ap_inv_lines_interface_rec.invoice_id );
            --Fnd_File.put_line (Fnd_File.LOG,'Cause:'||SQLERRM);
            g_message_erreur_chargement:=substr(SQLERRM,0,500) ;
            RETURN 1;

    END insert_ap_invoice_lines_intrf;


    /*=========================================================================*/
    /* PROCEDURE NAME : insert_ap_holds_all
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

    FUNCTION insert_ap_holds_all(p_ap_holds_all_rec ap_holds_all%ROWTYPE)
    RETURN     NUMBER
    IS

    BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut insert_ap_holds_all');
        INSERT
        INTO   ap_holds_all
        VALUES p_ap_holds_all_rec;

        Fnd_File.put_line (Fnd_File.LOG,'le blocage '||p_ap_holds_all_rec.hold_id||' a bien été inséré pour la facture ID: ' ||p_ap_holds_all_rec.invoice_id);
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin insert_ap_holds_all');
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            Fnd_File.put_line (Fnd_File.LOG,'erreur lors de l''insertion du blocage '||p_ap_holds_all_rec.hold_id||' pour la facture ID: ' ||p_ap_holds_all_rec.invoice_id);
            Fnd_File.put_line (Fnd_File.LOG,'Cause:'||SQLERRM);
            g_message_erreur_chargement := substr(SQLERRM,0,500) ;
            RETURN 1;

    END insert_ap_holds_all;

    /*=========================================================================*/
    /* PROCEDURE NAME : validate_factures
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


    PROCEDURE validate_factures( p_uo                 NUMBER
                                ,p_invoice_num        VARCHAR2
                                ,p_vendor_num         VARCHAR2
                                ,p_vendor_site_code   VARCHAR2
                                ,p_erreur             BOOLEAN
                                ,p_errbuf             OUT VARCHAR2
                                ,p_retcode            OUT NUMBER)
    IS

    BEGIN
        --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut validate_factures');
        IF p_erreur THEN

            Fnd_File.put_line (Fnd_File.output,RPAD(nvl(to_char(p_uo),' '),10,' ')||RPAD(p_invoice_num,40,' ')||RPAD(' ',30,' ')||RPAD(p_vendor_num ,30,' ')||g_message_erreur_chargement);
            --Fnd_File.put_line (Fnd_File.output,chr(10));

            BEGIN
                UPDATE dka_ap_rep_entete_facture_tmp
                SET    message_erreur = g_message_erreur_chargement
                WHERE  invoice_num = p_invoice_num
                AND    vendor_num =  p_vendor_num
                AND    vendor_site_code = p_vendor_site_code;
            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
                    --v_message :='ERREUR lors de la mise à jour du message d'erreur de la table temporaire des entêtes facture lors de l'insertion';
            END;

        ELSE

            BEGIN
                UPDATE dka_ap_rep_entete_facture_tmp
                SET    processed_request_id = g_request_id,
                        message_erreur = NULL
                WHERE  invoice_num = p_invoice_num
                AND    vendor_num = p_vendor_num
                AND    vendor_site_code = p_vendor_site_code;
            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
                    --v_message :='ERREUR lors de la mise à jour du PROCESSED_REQUEST_ID de la table temporaire des entêtes facture lors de l'insertion';
            END;

        END IF;
        --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_factures');
    END validate_factures;


        /*=========================================================================*/
    /* PROCEDURE NAME : validate_lignes_factures
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


    PROCEDURE validate_lignes_factures(  p_uo                NUMBER
                                        ,p_invoice_num       VARCHAR2
                                        ,p_vendor_num        VARCHAR2
                                        ,p_line_number       NUMBER
                                        ,p_erreur            BOOLEAN
                                        ,p_errbuf            OUT VARCHAR2
                                        ,p_retcode           OUT NUMBER)
    IS

    BEGIN
        --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut validate_lignes_factures');
        IF p_erreur THEN

            Fnd_File.put_line (Fnd_File.output,RPAD(nvl(to_char(p_uo),' '),10,' ')||RPAD(p_invoice_num,40,' ')||RPAD(p_line_number,30,' ')||RPAD(p_vendor_num ,30,' ')||g_message_erreur_chargement);
            --Fnd_File.put_line (Fnd_File.output,chr(10));

            BEGIN
                UPDATE dka_ap_rep_lignes_facture_tmp
                SET    message_erreur = g_message_erreur_chargement
                WHERE  invoice_num = p_invoice_num
                AND    vendor_num = p_vendor_num
                AND    line_number = p_line_number;
            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
                    --v_message :='ERREUR lors de la mise à jour du message d'erreur de la table temporaire des lignes facture lors de l'insertion';
            END;

        ELSE

            BEGIN
                UPDATE dka_ap_rep_lignes_facture_tmp
                SET    processed_request_id = g_request_id,
                        message_erreur = NULL
                WHERE  invoice_num = p_invoice_num
                AND    vendor_num = p_vendor_num
                AND    line_number = p_line_number;
            EXCEPTION
                WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
                    --v_message :='ERREUR lors de la mise à jour du PROCESSED_REQUEST_ID de la table temporaire des lignes facture lors de l'insertion';

            END;

        END IF;
        --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_lignes_factures');
    END validate_lignes_factures;

  --=========================================================================
  -- PROCEDURE NAME : check_holds
  -- DESCRIPTION  :  Fonction qui vérifie l'existence d'un code blocage donné sur une facture AP

  --=========================================================================
  FUNCTION check_holds(p_invoice_id          IN ap_holds_all.invoice_id%type,
                       p_hold_lookup_code    IN ap_holds_all.hold_lookup_code%type,
                       p_release_lookup_code IN ap_holds_all.release_lookup_code%type,
                       p_hold_date           IN ap_holds_all.hold_date%type) RETURN boolean
  IS
    l_exist   number := 0;
    
  BEGIN
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut check_holds');
    
    select 1
    into l_exist
    from ap_holds_all
    where invoice_id = p_invoice_id
      and hold_lookup_code = p_hold_lookup_code
      and release_lookup_code = p_release_lookup_code
      and hold_date = p_hold_date;
        
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin check_holds');
    return true;
  EXCEPTION
    WHEN OTHERS THEN
      return false;
  END check_holds;

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
                    p_chargement_blocage    VARCHAR2,
                    p_chargement_echeances  VARCHAR2, -- OBE artf2191277
                    p_date                  VARCHAR2
                    )
    IS

        -- ========== VARIABLES ==========
        v_package                    VARCHAR2(30)  := 'DKA_REPAPFCTIMP_PKG';
        v_nom_traitement             VARCHAR2(200) := 'Import des factures fournisseurs';
        v_sqlerrm                    VARCHAR2(250) := NULL;
        v_nb_erreurs                 NUMBER :=0;

        v_procedure                  VARCHAR2(30)    := 'MAIN';
        v_message                    VARCHAR2(500);

        v_errbuf                     VARCHAR2(2500);
        v_retcode                    NUMBER;
        v_exeption                   EXCEPTION;

        v_ccf 						VARCHAR2(500);
        v_ap_invoices_interface_rec      ap_invoices_interface%ROWTYPE;
        v_ap_inv_lines_interface_rec     ap_invoice_lines_interface%ROWTYPE;
        v_ap_holds_all_rec               ap_holds_all%ROWTYPE;

        v_user_id                NUMBER;
        v_invoice_id            NUMBER;
        v_vendor_id    NUMBER;
        v_accts_pay_code_combination_1    VARCHAR2(25);
        v_accts_pay_code_combination_2    VARCHAR2(25);
        v_accts_pay_code_combination_3    VARCHAR2(25);
        v_accts_pay_code_combination_4    VARCHAR2(25);
        v_accts_pay_code_combination_5    VARCHAR2(25);
        v_accts_pay_code_combination_6    VARCHAR2(25);
        v_accts_pay_code_combination_7    VARCHAR2(25);
        v_accts_pay_code_combination_8    VARCHAR2(25);
        v_accts_pay_code_combination_9    VARCHAR2(25);
        v_accts_pay_code_comb_10   VARCHAR2(25);
        v_dist_code_combination_1           VARCHAR2(25);
        v_dist_code_combination_2           VARCHAR2(25);
        v_dist_code_combination_3           VARCHAR2(25);
        v_dist_code_combination_4           VARCHAR2(25);
        v_dist_code_combination_5           VARCHAR2(25);
        v_dist_code_combination_6           VARCHAR2(25);
        v_dist_code_combination_7           VARCHAR2(25);
        v_dist_code_combination_8           VARCHAR2(25);
        v_dist_code_combination_9           VARCHAR2(25);
        v_dist_code_combination_10          VARCHAR2(25);
		v_dist_code_combination_11  VARCHAR2 (25);
		v_dist_code_combination_12 VARCHAR2 (25);
        v_nb_erreur_blocage NUMBER;
        v_code_tva  VARCHAR2 (100);

        v_ext_bank_rec_type                     IBY_EXT_BANKACCT_PUB.EXTBANK_REC_TYPE;
        v_response_rec                          IBY_FNDCPT_COMMON_PUB.RESULT_REC_TYPE;
        v_ext_bank_branch_rec                   IBY_EXT_BANKACCT_PUB.EXTBANKBRANCH_REC_TYPE;
        v_ext_bank_acc_rec                      iby_ext_bankacct_pub.extbankacct_rec_type;
        v_api_version                           NUMBER := 1.0;
        v_x_bank_id                             NUMBER;
        v_x_branch_id                           NUMBER;
        v_x_acct_id                             NUMBER;

        v_x_return_status                       VARCHAR2 (2000);
        v_x_msg_data                            VARCHAR2 (2000);
        v_x_msg_count                           NUMBER;
        v_msg_index_out                         NUMBER;
        v_warining_interface                    BOOLEAN :=false;
        v_warining_interface_globale            BOOLEAN :=false;
        
        v_operating_unit_exist                  BOOLEAN;
        v_exist_bank                            BOOLEAN;


        v_x_end_date                    DATE;
        v_x_joint_acct_owner_id         NUMBER;
        v_x_start_date                  DATE;
        v_x_assign_id                   NUMBER;

        vn_period_param                         NUMBER; --artf2034435
        vd_end_date_period_param                DATE;    --artf2034435
        v_type_frs                              VARCHAR2 (20); --YWA artf2228134 
        v_vendor_type_lookup_code      ap_suppliers.vendor_type_lookup_code%type;

        CURSOR cur_factures
        IS SELECT * FROM dka_ap_rep_entete_facture_tmp where processed_request_id=-1;

        CURSOR cur_lignes_factures (p_vendor_num VARCHAR2,p_invoice_num VARCHAR2)
        IS SELECT * FROM dka_ap_rep_lignes_facture_tmp WHERE vendor_num=p_vendor_num AND invoice_num=p_invoice_num AND processed_request_id=-1;

        CURSOR cur_blocage
        IS SELECT * FROM dka_ap_rep_blocages_tmp
        WHERE INVOICE_ID IS NOT NULL
        AND ORG_ID  IS NOT NULL
        AND processed_request_id=-1 ;
        
        --< OBE artf2191277
        CURSOR cur_hold_flag IS 
          SELECT a.invoice_id,
            d.hold_flag
          FROM dka_ap_rep_entete_facture_tmp d,
            ap_invoices_all a ,
            ap_suppliers p
          WHERE d.processed_request_id= g_request_id
          AND d.HOLD_FLAG             = 'Y'
          AND d.invoice_num           = a.invoice_num
          AND p.segment1              = d.vendor_num
          AND p.vendor_id             = a.vendor_id 
          ;
        --> OBE artf2191277


    BEGIN

        -- Début du Programme --
        -- ========Initialisation des variables d'anomalies========
        v_message   := 'Début procédure MAIN';
        p_retcode   := 0;
        p_errbuf    := NULL;

        /*============================================================================================*/
        /*Initialisation des variables*/
        /*============================================================================================*/
        v_message   := 'Init';
        Fnd_File.put_line (Fnd_File.log, 'Initiation des variables');
        Init(v_errbuf, v_retcode);
        IF v_retcode = 2 THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RAISE v_exeption;
        END IF;

         -- Initialization des journaux --
        Fnd_File.put_line (Fnd_File.LOG,'=======================================================================');
        Fnd_File.put_line (Fnd_File.LOG,'Import fournisseur DKA_REPAPFCTIMP_PKG');
        Fnd_File.put_line (Fnd_File.LOG,'=======================================================================');
        Fnd_File.put_line (Fnd_File.LOG,'Date de lancement    : ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.LOG,'Numéro de traitement : ' || TO_CHAR(g_request_id));
        Fnd_File.put_line (Fnd_File.LOG,'Libelle du login OA '||FND_GLOBAL.USER_NAME);

         -- Initialization de la sortie --
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');
        Fnd_File.put_line (Fnd_File.output,'Import fournisseur DKA_REPAPFCTIMP_PKG');
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');
        Fnd_File.put_line (Fnd_File.output,'Date de lancement    : ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.output,'Numéro de traitement : ' || TO_CHAR(g_request_id));
        Fnd_File.put_line (Fnd_File.output,'Libelle du login OA '||FND_GLOBAL.USER_NAME);

        -- param user
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');
        Fnd_File.put_line (Fnd_File.output,'Paramètres utilisateur :');
        Fnd_File.put_line (Fnd_File.output,'Chargement des fichiers                        : ' || TO_CHAR(p_chargement_f));
        Fnd_File.put_line (Fnd_File.output,'Changement dans les Opens interfaces           : ' || TO_CHAR(p_chargement_oi));
        Fnd_File.put_line (Fnd_File.output,'Lancement des traitements standard d''import    : ' || TO_CHAR(p_lancement_prog_stand));
        Fnd_File.put_line (Fnd_File.output,'Chargement des blocages                        : ' || TO_CHAR(p_chargement_blocage));
        Fnd_File.put_line (Fnd_File.output,'Chargement des Echéances Bloquées Paiement     : ' || TO_CHAR(p_chargement_echeances));    -- OBE artf2191277    
        Fnd_File.put_line (Fnd_File.output,'Date GL                                        : ' || TO_CHAR(p_date));
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');

        /*============================================================================================*/
        /*Chargement des fichiers*/
        /*============================================================================================*/
        IF p_chargement_f ='Y' THEN
            Fnd_File.put_line (Fnd_File.log,'/*============================================================================================*/');
            Fnd_File.put_line (Fnd_File.log,'/*Chargement des fichiers*/');
            Fnd_File.put_line (Fnd_File.log,'/*============================================================================================*/');
            Fnd_File.put_line (Fnd_File.LOG,'PHASE DE CHARGEMENT DU FICHIER');
            v_message   := 'PHASE DE CHARGEMENT DU FICHIER';
            -- Lancement du programme de chargement des fichiers

            Launch_Loader(v_errbuf,v_retcode);


            IF v_retcode = 2 THEN
                p_errbuf  := v_errbuf;
                p_retcode := v_retcode;
                Fnd_File.put_line (Fnd_File.log,'Chargement des fichiers en erreur');
                RAISE v_exeption;
            END IF;
            Fnd_File.put_line (Fnd_File.log,'Fin chargement des fichiers avec succès');
        END IF;

        
        /*============================================================================================*/
        -- Insertion dans les opren interfaces --
        /*============================================================================================*/
        IF p_chargement_oi ='Y' THEN
            /*============================================================================================*/
            -- PHASE DE PURGE DES ANCIENNES DONNEES d'open interface --
            /*============================================================================================*/
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PURGE DES DONNEES d''open interface');
            purge_data;

            Fnd_File.put_line (Fnd_File.LOG,chr(10));
            Fnd_File.put_line (Fnd_File.LOG,'/*============================================================================================*/');
            Fnd_File.put_line (Fnd_File.LOG,'/*Insertion dans les opens interfaces*/');
            Fnd_File.put_line (Fnd_File.LOG,'/*============================================================================================*/');
            v_message   := 'Insertion dans les opens interfaces';

            /*============================================================================================*/
            /*Boucle principale d'insertion dans l'open interface AP_INVOICES_INTERFACE */
            /*============================================================================================*/
            Fnd_File.put_line (Fnd_File.LOG,'Boucle principale d''insertion dans l''open interface AP_INVOICES_INTERFACE');
            v_message   := 'Boucle principale d''insertion dans l''open interface AP_INVOICES_INTERFACE';

            Fnd_File.put_line (Fnd_File.LOG,chr(10));

            Fnd_File.put_line (Fnd_File.output,'-------------------------------------------------------------------------------------------------------------------------------------------------------');
            Fnd_File.put_line (Fnd_File.output,'---------------------------------------------------------------REJETS de validation--------------------------------------------------------------------');
            Fnd_File.put_line (Fnd_File.output,'-------------------------------------------------------------------------------------------------------------------------------------------------------');
            Fnd_File.put_line (Fnd_File.output,RPAD('UO',10,' ')||RPAD('NUMERO FACTURE',40,' ')||RPAD('NUMERO LIGNE',30,' ')||RPAD('NUMERO FOURNISSEUR' ,30,' ')||'MOTIF');
            Fnd_File.put_line (Fnd_File.output,'-------------------------------------------------------------------------------------------------------------------------------------------------------');
            Fnd_File.put_line (Fnd_File.output,chr(10));

            --artf2034435
            SELECT MIN(gp.period_year || trim(to_char(gp.period_num,'09')))
              INTO vn_period_param
              FROM gl_period_statuses gp
             WHERE fnd_date.canonical_to_date(p_date) BETWEEN nvl(start_date,sysdate) AND nvl(end_date,sysdate)
               AND application_id = 200 --SQLAP
            ;

            -- YWA artf2161564 : Reprise en cours Fournisseur : Vendor_site_code = OFFICE table de reprise factures (en tête)
            update  DKA_AP_REP_ENTETE_FACTURE_TMP set vendor_site_code = 'OFFICE' where vendor_site_code like '%BUREAU';

            FOR c_f IN cur_factures LOOP
                v_warining_interface := FALSE;
                
                dka_rep_transco_pkg.get_transco ( pv_transco_name  => '008_REGIONS',
                                               pv_column_01 => c_f.accts_pay_code_combination_2,
                                               pv_out_01 =>  c_f.accts_pay_code_combination_2
                                            );

                --Fnd_File.put_line (Fnd_File.LOG,'----------------------------------Facture NUMERO :' ||c_f.INVOICE_NUM||'-----------------------------------------------' );
                --Fnd_File.put_line (Fnd_File.LOG,'récupération de l''unité opérationnelle: '||c_f.accts_pay_code_combination_2||c_f.accts_pay_code_combination_1);

                v_message   := 'récupération de l''unité opérationnelle : '||c_f.accts_pay_code_combination_2||c_f.accts_pay_code_combination_1;

                BEGIN
                    SELECT organization_id
                    INTO v_ap_invoices_interface_rec.org_id
                    FROM hr_operating_units
                    WHERE name = c_f.accts_pay_code_combination_2||c_f.accts_pay_code_combination_1;

                    g_org_id                                                        := v_ap_invoices_interface_rec.org_id  ;
                    --V1.1
                    /*
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
                    END IF;
                    */
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        g_message_erreur_chargement := 'ORGANIZATION_ID introuvable pour '||c_f.accts_pay_code_combination_2||c_f.accts_pay_code_combination_1;
                        v_warining_interface := TRUE;
                        v_warining_interface_globale := v_warining_interface;
                        validate_factures(g_org_id,c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,TRUE,v_errbuf,v_retcode);
                        IF v_retcode = 2 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            v_message := 'Erreur lors de la récupération de l''ORGANIZATION_ID';
                            RAISE v_exeption;
                        END IF;

                        CONTINUE;
                    WHEN OTHERS THEN
                        g_message_erreur_chargement := 'Erreur lors de la récupération de l''ORGANIZATION_ID '||c_f.accts_pay_code_combination_2||c_f.accts_pay_code_combination_1;
                        v_warining_interface := TRUE;
                        v_warining_interface_globale := v_warining_interface;
                        validate_factures(g_org_id,c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,TRUE,v_errbuf,v_retcode);
                        IF v_retcode = 2 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            v_message := 'Erreur lors de la récupération de l''ORGANIZATION_ID';
                            RAISE v_exeption;
                        END IF;

                        CONTINUE;
                END;




                --Fnd_File.put_line (Fnd_File.LOG,'récupération du fournisseur numéro: '||c_f.vendor_num);
                v_message   := 'récupération du fournisseur numéro: '||c_f.vendor_num;
                BEGIN
                    SELECT vendor_id,segment1,vendor_type_lookup_code
                    INTO v_vendor_id,
                         v_ap_invoices_interface_rec.vendor_num,
                         v_vendor_type_lookup_code
                    FROM ap_suppliers
                    WHERE segment1 = c_f.vendor_num;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        g_message_erreur_chargement := 'FOURNISSEUR introuvable';
                        validate_factures(g_org_id,c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,TRUE,v_errbuf,v_retcode);
                        IF v_retcode = 2 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            v_message := g_message_erreur_chargement;
                            RAISE v_exeption;
                        END IF;
                        v_warining_interface := TRUE;
                        v_warining_interface_globale := v_warining_interface;
                        CONTINUE;
                    WHEN OTHERS THEN
                        g_message_erreur_chargement := 'Erreur lors de la récupération des lid du fournisseur';
                        validate_factures(g_org_id,c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,TRUE,v_errbuf,v_retcode);
                        IF v_retcode = 2 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            v_message := g_message_erreur_chargement;
                            RAISE v_exeption;
                        END IF;
                        v_warining_interface := TRUE;
                        v_warining_interface_globale := v_warining_interface;
                        CONTINUE;
                END;

                --Fnd_File.put_line (Fnd_File.LOG,'récupération du site fournisseur numéro: '||c_f.vendor_site_code);
                v_message   := 'récupération du site fournisseur numéro: '||c_f.vendor_site_code;
                ---v_ap_invoices_interface_rec.vendor_site_code                    := c_f.vendor_site_code;--récupération RG03
                BEGIN

            --V1.2: SELECT vendor_site_code
                    SELECT MAX(vendor_site_code)
                    INTO v_ap_invoices_interface_rec.vendor_site_code
                    FROM ap_supplier_sites_all
                    WHERE vendor_id = v_vendor_id
                    AND org_id= g_org_id
                    AND vendor_site_code like SUBSTR(c_f.vendor_site_code,INSTR(c_f.vendor_site_code,'-')+1)||'%';
                    
                    if v_ap_invoices_interface_rec.vendor_site_code is null then  --artf2050658
                      raise NO_DATA_FOUND;
                    end if;

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        g_message_erreur_chargement := 'SITE FOURNISSEUR introuvable';
                        validate_factures(g_org_id,c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,TRUE,v_errbuf,v_retcode);
                        IF v_retcode = 2 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            v_message := g_message_erreur_chargement;
                            RAISE v_exeption;
                        END IF;
                        v_warining_interface := TRUE;
                        v_warining_interface_globale := v_warining_interface;
                        CONTINUE;
                    WHEN OTHERS THEN
                        g_message_erreur_chargement := 'Erreur lors de la récupération du code site fournisseur';
                        validate_factures(g_org_id,c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,TRUE,v_errbuf,v_retcode);
                        IF v_retcode = 2 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            v_message := g_message_erreur_chargement;
                            RAISE v_exeption;
                        END IF;
                        v_warining_interface := TRUE;
                        v_warining_interface_globale := v_warining_interface;
                        CONTINUE;
                END;




                v_ap_invoices_interface_rec.invoice_id                          := ap_invoices_interface_s.NEXTVAL;
                v_ap_invoices_interface_rec.invoice_num                         := c_f.invoice_num;

/*                IF c_f.invoice_type_lookup_code ='EXPENSE REPORT' THEN
                    v_ap_invoices_interface_rec.invoice_type_lookup_code         := NULL;
                ELSE*/
                    v_ap_invoices_interface_rec.invoice_type_lookup_code        := c_f.invoice_type_lookup_code;--EXPENSE REPORT à revoir
/*                END IF;*/

                v_ap_invoices_interface_rec.invoice_date                        := c_f.invoice_date;


                v_ap_invoices_interface_rec.invoice_amount                      := c_f.invoice_amount;
                v_ap_invoices_interface_rec.invoice_currency_code               := c_f.invoice_currency_code;

                 --v_ap_invoices_interface_rec.terms_name                          := c_f.terms_name;-- +TRANSCO 020_CONDITIONS_RGLT
                dka_rep_transco_pkg.get_transco ( pv_transco_name  => '020_CONDITIONS_RGLT',
                                               pv_column_01 => c_f.terms_name,
                                               pv_out_01 => v_ap_invoices_interface_rec.terms_name
                                            );



                v_ap_invoices_interface_rec.description                         := c_f.description;
                v_ap_invoices_interface_rec.creation_date                       := SYSDATE;
                v_ap_invoices_interface_rec.created_by                          := g_user_id;
                --v_ap_invoices_interface_rec.attribute_category                  := c_f.attribute_category; --RBE artf2069783 
                v_ap_invoices_interface_rec.attribute_category                  := 'REPRISE'; --RBE artf2069783 
                v_ap_invoices_interface_rec.attribute1                          := c_f.attribute1;
                v_ap_invoices_interface_rec.attribute2                          := c_f.attribute2;
                v_ap_invoices_interface_rec.attribute3                          := c_f.attribute3;
                v_ap_invoices_interface_rec.attribute4                          := c_f.attribute4;
                v_ap_invoices_interface_rec.attribute5                          := c_f.attribute5;
                --v_ap_invoices_interface_rec.attribute6                          := c_f.attribute6; --RBE artf2069783 
                v_ap_invoices_interface_rec.attribute6                          := TO_CHAR(c_f.MONTANT_INITAL);  --RBE artf2069783 
                v_ap_invoices_interface_rec.attribute7                          := c_f.attribute7;
                v_ap_invoices_interface_rec.attribute8                          := c_f.attribute8;
                v_ap_invoices_interface_rec.attribute9                          := c_f.attribute9;
                v_ap_invoices_interface_rec.attribute10                         := c_f.attribute10;
                v_ap_invoices_interface_rec.attribute11                         := c_f.attribute11;
                v_ap_invoices_interface_rec.attribute12                         := c_f.attribute12;
                v_ap_invoices_interface_rec.attribute13                         := c_f.attribute13;
                v_ap_invoices_interface_rec.attribute14                         := c_f.attribute14;
                v_ap_invoices_interface_rec.attribute15                         := c_f.attribute15;
                v_ap_invoices_interface_rec.source                              := 'REPRISE';
                v_ap_invoices_interface_rec.payment_currency_code               := c_f.payment_currency_code;
                v_ap_invoices_interface_rec.terms_date                          := c_f.terms_date;
                v_ap_invoices_interface_rec.calc_tax_during_import_flag         := 'N';
                v_ap_invoices_interface_rec.payment_method_lookup_code          := c_f.payment_method_loookup_code;
                v_ap_invoices_interface_rec.payment_priority                    := c_f.payment_priority;
								v_ap_invoices_interface_rec.external_bank_account_id            := null;

                --v_ap_invoices_interface_rec.doc_category_code                   := ;--l'Open interface déduira la valeur automatiquement à partir du type lorsque l'option de profil « sequencial numbering » est positionnée à Always.

                --v_ap_invoices_interface_rec.pay_group_lookup_code               := c_f.pay_group_lookup_code;--transco à jouter table 021_CLASSE_REGL
                --YWA artf2228134 EDB80
                IF c_f.pay_group_lookup_code NOT LIKE '%GROUPE' THEN 
                
                    dka_rep_transco_pkg.get_transco ( pv_transco_name  => '021_CLASSE_REGL',
                                               pv_column_01 => c_f.pay_group_lookup_code,--ajouter prefix de sociterregion
                                               pv_out_01 => v_ap_invoices_interface_rec.pay_group_lookup_code
                                            );
                ELSE
                    
                    dka_rep_transco_pkg.get_transco ( pv_transco_name  => '024_TYPE_FRS',
                                               pv_column_01 => c_f.accts_pay_code_combination_5,
                                               pv_out_01 => v_type_frs
                                            );
                    
                    IF v_type_frs = 'G EXT' THEN
                        v_ap_invoices_interface_rec.pay_group_lookup_code := 'GROUPEHORSDKA';
                    ELSE 
                       v_ap_invoices_interface_rec.pay_group_lookup_code :=  'GROUPEDKA';
                    END IF;
                    
                END IF;    
                
                
                /* --artf2034435
                IF c_f.gl_date < fnd_date.canonical_to_date(p_date) THEN

                    v_ap_invoices_interface_rec.gl_date                             := fnd_date.canonical_to_date(p_date);--c_f.gl_date;
                ELSE
                    v_ap_invoices_interface_rec.gl_date                            := c_f.gl_date;
                END IF;
                */

                IF c_f.period_gl <= vn_period_param THEN

                  SELECT MIN(gp.end_date)
                    INTO vd_end_date_period_param
                    FROM gl_period_statuses gp
                   WHERE fnd_date.canonical_to_date(p_date) BETWEEN nvl(start_date, sysdate) AND nvl(end_date, sysdate)
                     AND application_id = 200 --SQLAP
                     AND gp.period_year || trim(to_char(gp.period_num, '09')) = to_char(vn_period_param)
                  ;

                  v_ap_invoices_interface_rec.gl_date := vd_end_date_period_param;

                ELSE

                  v_ap_invoices_interface_rec.gl_date := c_f.gl_date;

                END IF;

                --Fnd_File.put_line (Fnd_File.LOG,'Récupération de l''ID de la transco CCF');
                v_message   := 'Récupération de l''ID de la transco CCF';
                BEGIN
                  /*IF c_f.accts_pay_code_combination_5 !='0' THEN
                      c_f.accts_pay_code_combination_5 := 'XXX'||c_f.accts_pay_code_combination_5;
                  END IF;*/--YWA artf2135344 
                  v_ccf := dka_rep_transco_pkg.get_cle_transco_f( c_f.accts_pay_code_combination_1,
                                                                  c_f.accts_pay_code_combination_2,
                                                                  c_f.accts_pay_code_combination_3,
                                                                  c_f.accts_pay_code_combination_4,
                                                                  c_f.accts_pay_code_combination_5,
                                                                  --c_f.accts_pay_code_combination_6,
                                                                  c_f.accts_pay_code_combination_7,
                                                                  c_f.accts_pay_code_combination_8,
                                                                  c_f.accts_pay_code_combination_9,
                                                                  c_f.accts_pay_code_combination_10);
                  v_ap_invoices_interface_rec.accts_pay_code_combination_id := to_number(v_ccf);

                EXCEPTION
                    WHEN OTHERS THEN
                        --v_ap_invoices_interface_rec.accts_pay_code_combination_id :=NULL;
                        g_message_erreur_chargement := v_ccf;
                        validate_factures(g_org_id,c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,TRUE,v_errbuf,v_retcode);
                        IF v_retcode = 2 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            v_message := 'Erreur lors de la récupération du CODE_COMBINATION_ID';
                            RAISE v_exeption;
                        END IF;
                        v_warining_interface := TRUE;
                        v_warining_interface_globale := v_warining_interface;
                        CONTINUE;
                END;

                
                IF c_f.bank_account_num IS NOT NULL THEN
--< JLY - artf2043352               
--                  --Fnd_File.put_line (Fnd_File.LOG,'vérification de l''existence de la banque :'||c_f.bank_name);
--                  v_message   := 'vérification de l''existence de la banque :'||c_f.bank_name;
--                  v_ext_bank_rec_type.object_version_number   := v_api_version;
--                  v_ext_bank_rec_type.bank_name               := c_f.bank_name;
--                  v_ext_bank_rec_type.bank_number             := c_f.bank_number; --V1.3
--                  v_ext_bank_rec_type.institution_type        := NULL;
--                  v_ext_bank_rec_type.country_code            := 'FR';
--  
--                  --<<V1.3
--                  iby_ext_bankacct_pub.check_bank_exist(  p_api_version   => v_api_version,
--                                                          p_init_msg_list => fnd_api.g_true,
--                                                          p_country_code  => v_ext_bank_rec_type.country_code,
--                                                          p_bank_name     => NULL,
--                                                          p_bank_number   => v_ext_bank_rec_type.bank_number,
--                                                          x_response      => v_response_rec,
--                                                          x_bank_id       => v_x_bank_id,
--                                                          x_end_date      => v_x_end_date,
--                                                          x_return_status => v_x_return_status,
--                                                          x_msg_count     => v_x_msg_count,
--                                                          x_msg_data      => v_x_msg_data
--                                                          );
--  
--                  IF v_x_bank_id IS NULL THEN
--  
--                      iby_ext_bankacct_pub.check_bank_exist(  p_api_version   => v_api_version,
--                                                              p_init_msg_list => fnd_api.g_true,
--                                                              p_country_code  => v_ext_bank_rec_type.country_code,
--                                                              p_bank_name     => v_ext_bank_rec_type.bank_name,
--                                                              p_bank_number   => NULL,
--                                                              x_response      => v_response_rec,
--                                                              x_bank_id       => v_x_bank_id,
--                                                              x_end_date      => v_x_end_date,
--                                                              x_return_status => v_x_return_status,
--                                                              x_msg_count     => v_x_msg_count,
--                                                              x_msg_data      => v_x_msg_data
--                                                              );
--  
--                      IF v_x_bank_id IS NULL THEN
--  
--                        g_message_erreur_chargement := 'Banque introuvable';
--                        validate_factures (g_org_id,c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,TRUE,v_errbuf,v_retcode);
--                        IF v_retcode = 2 THEN
--                            p_errbuf  := v_errbuf;
--                            p_retcode := v_retcode;
--                            v_message := 'Erreur lors de la récupération de la Banque'||c_f.bank_name;
--                            RAISE v_exeption;
--                        END IF;
--                        v_warining_interface := TRUE;
--                        v_warining_interface_globale := v_warining_interface;
--                        CONTINUE;
--  
--                      END IF;
--  
--                  END IF;
--                  -->>V1.3
--                
--                --Fnd_File.put_line (Fnd_File.LOG,'vérification de l''existence de l''agence:'||c_f.bank_branch_name);
--                v_message   := 'vérification de l''existence de l''agence :'||c_f.bank_branch_name;
--
--                v_ext_bank_branch_rec.bch_object_version_number := v_api_version;
--                v_ext_bank_branch_rec.bank_party_id             := v_x_bank_id;
--                v_ext_bank_branch_rec.branch_name               := c_f.bank_branch_name;
--                v_ext_bank_branch_rec.branch_number             := c_f.bank_num; --V1.3
--
--                --<<V1.3
--
--                iby_ext_bankacct_pub.check_ext_bank_branch_exist(   p_api_version   => v_api_version,
--                                                                    p_init_msg_list => fnd_api.g_true,
--                                                                    p_bank_id       => v_ext_bank_branch_rec.bank_party_id,
--                                                                    p_branch_name   => NULL,
--                                                                    p_branch_number => v_ext_bank_branch_rec.branch_number,
--                                                                    x_response      => v_response_rec,
--                                                                    x_branch_id     => v_x_branch_id,
--                                                                    x_end_date      => v_x_end_date,
--                                                                    x_return_status => v_x_return_status,
--                                                                    x_msg_count     => v_x_msg_count,
--                                                                    x_msg_data      => v_x_msg_data
--                                                                    );
--
--                IF v_x_branch_id IS NULL THEN
--
--                    iby_ext_bankacct_pub.check_ext_bank_branch_exist(   p_api_version   => v_api_version,
--                                                                        p_init_msg_list => fnd_api.g_true,
--                                                                        p_bank_id       => v_ext_bank_branch_rec.bank_party_id,
--                                                                        p_branch_name   => v_ext_bank_branch_rec.branch_name,
--                                                                        p_branch_number => NULL,
--                                                                        x_response      => v_response_rec,
--                                                                        x_branch_id     => v_x_branch_id,
--                                                                        x_end_date      => v_x_end_date,
--                                                                        x_return_status => v_x_return_status,
--                                                                        x_msg_count     => v_x_msg_count,
--                                                                        x_msg_data      => v_x_msg_data
--                                                                        );
--
--                    IF v_x_branch_id IS NULL THEN
--
--                      g_message_erreur_chargement := 'Agence bancaire introuvable';
--                      validate_factures (g_org_id,c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,true,v_errbuf,v_retcode);
--                      IF v_retcode = 2 THEN
--                          p_errbuf  := v_errbuf;
--                          p_retcode := v_retcode;
--                          v_message := 'Erreur lors de la récupération de l''agence bancaire'||c_f.bank_branch_name;
--                          RAISE v_exeption;
--                      END IF;
--                      v_warining_interface := TRUE;
--                      v_warining_interface_globale := v_warining_interface;
--                      CONTINUE;
--
--                    END IF;
--
--                END IF;
--                -->>V1.3
--> JLY - artf2043352 
                
                
                  --Fnd_File.put_line (Fnd_File.LOG,'vérification de l''existence de l''agence:'||c_f.bank_branch_name);
                  v_message   := 'vérification de l''existence de la Banque '||c_f.bank_name||'('||c_f.bank_number||') / Agence '||c_f.bank_branch_name||'('||c_f.bank_num||')';
  
                  --< JLY - artf2043352
                  v_x_bank_id := null;
                  v_x_branch_id := null;

                  begin
                    begin 
                      select  bank_party_id, branch_party_id
                      into    v_x_bank_id, v_x_branch_id
                      from    ce_bank_branches_v
                      where   bank_number = c_f.bank_number
                      and     branch_number = c_f.bank_num;
                    exception
                      when too_many_rows then 
                        select  bank_party_id, branch_party_id
                        into    v_x_bank_id, v_x_branch_id
                        from    ce_bank_branches_v
                        where   bank_number = c_f.bank_number
                        and     branch_number = c_f.bank_num
                        and     bank_home_country = 'FR';      
                    end;
                  exception
                    when no_data_found then
                      begin
                        select  bank_party_id, branch_party_id
                        into    v_x_bank_id, v_x_branch_id
                        from    ce_bank_branches_v
                        where   bank_name = c_f.bank_name
                        and     bank_branch_name = c_f.bank_branch_name;  
                      exception
                        when no_data_found then
                          begin
                            select  bank_party_id, branch_party_id
                            into    v_x_bank_id, v_x_branch_id
                            from    ce_bank_branches_v
                            where   bank_number = c_f.bank_number
                            and     bank_branch_name = c_f.bank_branch_name;
                          exception
                            when no_data_found then
                              begin
                                select  bank_party_id, branch_party_id
                                into    v_x_bank_id, v_x_branch_id
                                from    ce_bank_branches_v
                                where   bank_name = c_f.bank_name
                                and     branch_number = c_f.bank_num;                        
                              exception
                                when others then
                                  null;
                              end;
                            when others then
                              null;
                          end;
                        when others then
                          null;
                      end;
                    when others then
                      null;
                  end;
                  --> JLY - artf2043352
                
                  IF v_x_bank_id IS NULL OR v_x_branch_id IS NULL THEN
                    g_message_erreur_chargement := 'Banque / Agence introuvable : '||c_f.bank_name||'('||c_f.bank_number||') / Agence '||c_f.bank_branch_name||'('||c_f.bank_num||')';
                    validate_factures (g_org_id,c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,TRUE,v_errbuf,v_retcode);
                    
                    
                    v_ap_invoices_interface_rec.payment_method_lookup_code := 'CHECK';
                    v_ap_invoices_interface_rec.external_bank_account_id  := NULL;                  
                  ELSE
--< JLY - artf2043352
--                    v_ext_bank_acc_rec.object_version_number    := v_api_version;
--    
--                    --v_ext_bank_acc_rec.bank_account_name        := c_f.bank_account_name;
--                    v_ext_bank_acc_rec.bank_account_num         := c_f.bank_account_num;
--                    v_ext_bank_acc_rec.bank_id                  := v_x_bank_id;
--                    v_ext_bank_acc_rec.branch_id                := v_x_branch_id;
--                    v_ext_bank_acc_rec.country_code             := 'FR';
--                    v_ext_bank_acc_rec.currency                 := 'EUR';
--  
--    
--                    -- Initialiser org_id
--                    /*v_message   := 'init_environnement';
--                    --Fnd_File.put_line (Fnd_File.output, 'Initialisation de l''environnement pour vérification de l''existence du compte '||c_f.bank_account_name);
--                    init_environement(v_errbuf, v_retcode);
--                    IF v_retcode = 1 THEN
--                        p_errbuf  := v_errbuf;
--                        p_retcode := v_retcode;
--                        CONTINUE;
--                    END IF;
--                    IF v_retcode = 2 THEN
--                        p_errbuf  := v_errbuf;
--                        p_retcode := v_retcode;
--                        RAISE v_exeption;
--                    END IF;*/
--                    --Fnd_File.put_line (Fnd_File.LOG,'vérification de l''existence du compte '||c_f.bank_account_name);
--                    v_message   := 'vérification de l''existence du compte '||c_f.bank_account_num;
--                    iby_ext_bankacct_pub.check_ext_acct_exist(  p_api_version       => v_api_version,
--                                                                p_init_msg_list     => fnd_api.g_true,
--                                                                p_ext_bank_acct_rec => v_ext_bank_acc_rec,
--                                                                x_acct_id           => v_x_acct_id,
--                                                                x_start_date        => v_x_start_date,
--                                                                x_end_date          => v_x_end_date,
--                                                                x_return_status     => v_x_return_status,
--                                                                x_msg_count         => v_x_msg_count,
--                                                                x_msg_data          => v_x_msg_data,
--                                                                x_response          => v_response_rec
--                                                                );
--                    IF v_x_acct_id IS NULL THEN
--                        g_message_erreur_chargement := 'Compte bancaire introuvable';
--                        validate_factures (g_org_id,c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,true,v_errbuf,v_retcode);
--  
--                        v_ap_invoices_interface_rec.payment_method_lookup_code := 'CHECK';
--                        v_ap_invoices_interface_rec.external_bank_account_id  := NULL;
--                        
--                        IF v_retcode = 2 THEN
--                            p_errbuf  := v_errbuf;
--                            p_retcode := v_retcode;
--                            v_message := 'Erreur lors de la récuperation du Compte bancaire'||c_f.bank_account_num;
--                            RAISE v_exeption;
--                        END IF;
--                        
--                        v_warining_interface := TRUE;
--                        v_warining_interface_globale := v_warining_interface;
--                        CONTINUE;
--                    END IF;
--> JLY - artf2043352

                    v_message   :=  'Vérification de l''existence du compte '||c_f.bank_account_name||' ('||c_f.bank_account_num||')';
                    
                    --< JLY - artf2043352
                    v_x_acct_id := NULL;
                    
                    begin
                      select  ext_bank_account_id
                      into    v_x_acct_id
                      from    iby_ext_bank_accounts
                      where   (bank_account_num_hash1= iby_security_pkg.get_hash(c_f.bank_account_num,'F'))
                      and     (bank_account_num_hash2= iby_security_pkg.get_hash(c_f.bank_account_num,'T'))
                      and     (bank_id = v_x_bank_id)
                      and     (branch_id = v_x_branch_id);
                    exception
                      when others then
                        g_message_erreur_chargement := 'Compte bancaire introuvable '||c_f.bank_account_name||' ('||c_f.bank_account_num||')';
                        validate_factures (g_org_id,c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,true,v_errbuf,v_retcode);
                        
                        v_x_acct_id := NULL;
  
                        v_ap_invoices_interface_rec.payment_method_lookup_code := 'CHECK';
                        v_ap_invoices_interface_rec.external_bank_account_id  := NULL;
                    end;
                    --> JLY - artf2043352
                
                    v_ap_invoices_interface_rec.external_bank_account_id            := v_x_acct_id;
                  END IF;
                END IF;
                
                v_ap_invoices_interface_rec.remit_to_supplier_name              := c_f.remit_to_supplier_name;
                v_ap_invoices_interface_rec.remit_to_supplier_site              := c_f.remit_to_supplier_site;
                v_ap_invoices_interface_rec.status                              := NULL;

                    FOR c_lf IN cur_lignes_factures (c_f.vendor_num,c_f.invoice_num) LOOP
                        --Fnd_File.put_line (Fnd_File.LOG,'*********************************Ligne facture NUMERO :' ||c_lf.LINE_NUMBER||'****************************************' );


                        /*IF c_lf.accounting_date != c_f.gl_date THEN -- Doit être identique gl_date de invoice_interface
                            g_message_erreur_chargement := 'ACCOUNTING_DATE invalide doit être identique à GL_DATE de la facture';
                            validate_lignes_factures(g_org_id,c_lf.invoice_num,c_lf.vendor_num,c_lf.line_number,true,v_errbuf,v_retcode);
                            IF v_retcode = 2 THEN
                                p_errbuf  := v_errbuf;
                                p_retcode := v_retcode;
                                v_message := 'ACCOUNTING_DATE invalide doit être identique a GL_DATE de la facture';
                                RAISE v_exeption;
                            END IF;
                            v_warining_interface := TRUE;
                            CONTINUE;
                        END IF;*/
                        --parti des informtions de projet a rensigner en cas de besoin
                        /*
                        BEGIN
                            --v_ap_inv_lines_interface_rec.project_id                 := ;--
                            SELECT ppa.project_id
                            INTO  v_ap_inv_lines_interface_rec.project_id
                            FROM  pa_projects_all ppa,
                                  hr_operating_units hor
                            WHERE ppa.segment1= hor.name||'_'||'000000'
                            AND hor.organization_id = g_org_id;
                        EXCEPTION
                            WHEN OTHERS THEN
                                g_message_erreur_chargement := 'Erreur lors de la récupération du projet 0 pour lorg_id: '||g_org_id;
                                validate_factures(c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,TRUE,v_errbuf,v_retcode);
                                IF v_retcode = 2 THEN
                                    p_errbuf  := v_errbuf;
                                    p_retcode := v_retcode;
                                    v_message := g_message_erreur_chargement;
                                    RAISE v_exeption;
                                END IF;
                                v_warining_interface := TRUE;
                                CONTINUE;
                        END;

                        BEGIN
                            --v_ap_inv_lines_interface_rec.task_id                    := ;--
                            SELECT task_id
                            INTO   v_ap_inv_lines_interface_rec.task_id
                            FROM pa_tasks
                            WHERE project_id=v_ap_inv_lines_interface_rec.project_id
                            AND task_number=000000;
                         EXCEPTION
                            WHEN OTHERS THEN
                                g_message_erreur_chargement := 'Erreur lors de la récupération de la tache 0 du projet id:'||v_ap_inv_lines_interface_rec.project_id ||' pour lorg_id: '||g_org_id;
                                validate_factures(c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,TRUE,v_errbuf,v_retcode);
                                IF v_retcode = 2 THEN
                                    p_errbuf  := v_errbuf;
                                    p_retcode := v_retcode;
                                    v_message := g_message_erreur_chargement;
                                    RAISE v_exeption;
                                END IF;
                                v_warining_interface := TRUE;
                                CONTINUE;

                        END;
                        */
                        /*
                        --v_ap_inv_lines_interface_rec.expenditure_type           := c_lf.expenditure_type;-- transco(012_EXPENDITURE_TYPES)
                        dka_rep_transco_pkg.get_transco ( pv_transco_name  => '012_EXPENDITURE_TYPES',
                                               pv_column_01 => c_lf.expenditure_type,
                                               pv_out_01 => v_ap_inv_lines_interface_rec.expenditure_type
                                            );*/




                        IF c_lf.code_tva IS NOT NULL THEN

                            --Fnd_File.put_line (Fnd_File.LOG,'Validation du code tva'||c_lf.code_tva);
                            v_message   := 'Validation du code tva'||c_lf.code_tva;

                            BEGIN
                                --v_ap_inv_lines_interface_rec.tax_rate_code              := c_lf.code_tva;--transco 004_CODE_TVA
                                dka_rep_transco_pkg.get_transco ( pv_transco_name  => '004_CODE_TVA',
                                               pv_column_01 => c_lf.code_tva,
                                               pv_out_01 => v_code_tva
                                            );
                                
                                SELECT  tax_rate_code,
                                        tax_regime_code,
                                        tax,
                                        tax_jurisdiction_code,
                                        tax_status_code
                                INTO    v_ap_inv_lines_interface_rec.tax_rate_code,
                                        v_ap_inv_lines_interface_rec.tax_regime_code,
                                        v_ap_inv_lines_interface_rec.tax,
                                        v_ap_inv_lines_interface_rec.tax_jurisdiction_code,
                                        v_ap_inv_lines_interface_rec.tax_status_code
                                FROM    zx_rates_b
                                WHERE tax_rate_code = v_code_tva
                                  AND sysdate between nvl(effective_from,sysdate) and nvl(effective_to,sysdate);

                            EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                    g_message_erreur_chargement := 'TAX_RATE_CODE INTROUVABLE';
                                    validate_lignes_factures(g_org_id,c_lf.invoice_num,c_lf.vendor_num,c_lf.line_number,true,v_errbuf,v_retcode);
                                    IF v_retcode = 2 THEN
                                        p_errbuf  := v_errbuf;
                                        p_retcode := v_retcode;
                                        v_message := 'Erreur lors de la récupération des informations de la taxe'||c_lf.code_tva;
                                        RAISE v_exeption;
                                    END IF;
                                    v_warining_interface := TRUE;
                                    CONTINUE;
                                WHEN OTHERS THEN
                                    g_message_erreur_chargement := 'TAX_RATE_CODE INTROUVABLE';
                                    validate_lignes_factures(g_org_id,c_lf.invoice_num,c_lf.vendor_num,c_lf.line_number,true,v_errbuf,v_retcode);
                                    IF v_retcode = 2 THEN
                                        p_errbuf  := v_errbuf;
                                        p_retcode := v_retcode;
                                        v_message := 'Erreur lors de la récupération des informations de la taxe'||c_lf.code_tva;
                                        RAISE v_exeption;
                                    END IF;
                                    v_warining_interface := TRUE;
                                    CONTINUE;

                            END;

                        END IF;


                        IF c_lf.line_type_lookup_code != 'TAX' THEN

                          --Fnd_File.put_line (Fnd_File.LOG,'Validation de la transco CCF');
                          v_message   := 'Validation de la transco CCF de la ligne';
                          --v_ap_inv_lines_interface_rec.dist_code_combination_id    --:= ; transco ccf RG20
                          --Fnd_File.put_line (Fnd_File.LOG,'Récupération de l''ID de la transco CCF');
                          v_message   := 'Récupération de l''ID de la transco CCF de la ligne';
                          BEGIN
                            dka_rep_transco_pkg.get_transco( pv_transco_name => '008_REGIONS',
                                                             pv_column_01    => c_lf.dist_code_combination_2,
                                                             pv_out_01       => c_lf.dist_code_combination_2);
                            /*                                 
                            IF c_lf.dist_code_combination_5 !='0' THEN
                              c_lf.dist_code_combination_5 := 'XXX'||c_lf.dist_code_combination_5;
                            END IF;

                            v_ccf := dka_rep_transco_pkg.get_cle_transco_f( c_lf.dist_code_combination_1,
                                                                            c_lf.dist_code_combination_2,
                                                                            c_lf.dist_code_combination_3,
                                                                            c_lf.dist_code_combination_4,
                                                                            c_lf.dist_code_combination_5,
                                                                            --c_lf.dist_code_combination_6,
                                                                            c_lf.dist_code_combination_7,
                                                                            c_lf.dist_code_combination_8,
                                                                            c_lf.dist_code_combination_9,
                                                                            c_lf.dist_code_combination_10);
								            v_ap_inv_lines_interface_rec.dist_code_combination_id := to_number(v_ccf);
                            */
                            
                            Dka_Tools_Pkg.get_code_combination_id (
                                pv_segment1              => c_lf.dist_code_combination_1,
                                pv_segment2              => c_lf.dist_code_combination_2,
                                pv_segment3              => 'REPRIS', --'REPRISE',
                                pv_segment4              => 'REP',
                                pv_segment5              => '0',
                                pv_segment6              => '0',
                                pv_segment7              => '0',
                                pv_segment8              => '0',
                                pv_segment9              => '0',
                                pv_segment10             => '0',
                                pv_segment11             => '0',
                                pv_segment12             => '0',
                                pn_code_combination_id   => v_ap_inv_lines_interface_rec.dist_code_combination_id,
                                pv_errbuf                => v_errbuf,
                                pn_retcode               => v_retcode);
                                
                          EXCEPTION
                            WHEN OTHERS THEN
                              --v_ap_inv_lines_interface_rec.dist_code_combination_id := NULL;
                              g_message_erreur_chargement := to_char(v_ap_inv_lines_interface_rec.dist_code_combination_id);
                              validate_lignes_factures(g_org_id,c_lf.invoice_num,c_lf.vendor_num,c_lf.line_number,true,v_errbuf,v_retcode);
                              IF v_retcode = 2 THEN
                                p_errbuf  := v_errbuf;
                                p_retcode := v_retcode;
                                v_message := 'Erreur lors de la récupération des informations de la ccf de la ligne';
                                RAISE v_exeption;
                              END IF;
                              v_warining_interface := TRUE;
                              CONTINUE;
                          END;

                        END IF;

                    END LOOP;   

                --<< Ajout artf2052447
                -- Permet de renseigner un msg au niveau entete s'il existe au moins 1 ligne en erreur
                IF v_warining_interface THEN
           
                  DECLARE
                    vv_dump dka_ap_rep_entete_facture_tmp.message_erreur%TYPE;
                  
                  BEGIN
                  
                    SELECT dar.message_erreur
                      INTO vv_dump
                      FROM dka_ap_rep_entete_facture_tmp dar
                     WHERE dar.invoice_num = c_f.invoice_num
                       AND dar.vendor_num = c_f.vendor_num
                       AND dar.vendor_site_code = c_f.vendor_site_code;
                  
                    IF vv_dump IS NULL OR vv_dump = 'Rejet au niveau ligne' THEN
                      Fnd_File.put_line(Fnd_File.output,
                                        RPAD(nvl(to_char(g_org_id), ' '), 10, ' ') || RPAD(c_f.invoice_num, 40, ' ') ||
                                        RPAD(' ', 30, ' ') || RPAD(c_f.vendor_num, 30, ' ') || 'Rejet au niveau ligne');
                    END IF;
                  
                  EXCEPTION
                    WHEN OTHERS THEN
                      NULL;
                  END;
                
                UPDATE dka_ap_rep_entete_facture_tmp dar
                   SET dar.message_erreur = 'Rejet au niveau ligne'
                 WHERE dar.message_erreur IS NULL
                   AND dar.invoice_num = c_f.invoice_num
                   AND dar.vendor_num = c_f.vendor_num
                   AND dar.vendor_site_code = c_f.vendor_site_code
                   AND EXISTS (SELECT 1
                                 FROM dka_ap_rep_lignes_facture_tmp darl
                                WHERE darl.invoice_num = dar.invoice_num
                                  AND darl.vendor_num = dar.vendor_num
                                  AND darl.message_erreur IS NOT NULL);
                
                END IF;
                -->>
                
                IF NOT v_warining_interface  THEN


                    v_message   := 'insertion de la facture ';

                    IF insert_ap_invoices_interface(v_ap_invoices_interface_rec) = 1 THEN
                        --Fnd_File.put_line (Fnd_File.output,'Problème lors de l''insertion de la facture numéro : '||v_ap_invoices_interface_rec.invoice_num);
                        v_message   := 'problème lors de l''insertion dans l''open interface ap_invoices_interface ';
                        validate_factures (g_org_id,c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,true,v_errbuf,v_retcode);
                        IF v_retcode = 2 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            RAISE v_exeption;
                        END IF;
                        p_errbuf  := g_message_erreur_chargement;
                        p_retcode := 2;
                        RAISE v_exeption;
                    ELSE
                        --Fnd_File.put_line (Fnd_File.LOG,'L''insertion de la facture numéro : '||v_ap_invoices_interface_rec.invoice_num||' avec succès');
                        v_message   := 'Insertion dans l''open interface ap_invoices_interface avec succès';
                        validate_factures (g_org_id,c_f.invoice_num,c_f.vendor_num,c_f.vendor_site_code,false,v_errbuf,v_retcode);
                        IF v_retcode = 2 THEN
                            p_errbuf  := v_errbuf;
                            p_retcode := v_retcode;
                            RAISE v_exeption;
                        END IF;
                        g_nb_facture_cree_oi :=g_nb_facture_cree_oi+1;

                        v_message :='mise à jour table blocages temporaire pour la facture '||c_f.invoice_num;
                        BEGIN
                            UPDATE dka_ap_rep_blocages_tmp
                            SET    invoice_id = v_ap_invoices_interface_rec.invoice_id,
                                   org_id  = g_org_id
                            WHERE  invoice_num = c_f.invoice_num
                            AND    vendor_num = c_f.vendor_num;
                        EXCEPTION
                            WHEN OTHERS THEN
                                p_errbuf  := SQLERRM;
                                p_retcode := 2;
                                RAISE v_exeption;
                        END;

                        FOR c_lf IN cur_lignes_factures (c_f.vendor_num,c_f.invoice_num) LOOP

                            v_ap_inv_lines_interface_rec.invoice_id                 := v_ap_invoices_interface_rec.invoice_id ;
                            v_ap_inv_lines_interface_rec.invoice_line_id            := ap_invoice_lines_interface_s.NEXTVAL;
                            v_ap_inv_lines_interface_rec.line_number                := c_lf.line_number;
                            v_ap_inv_lines_interface_rec.line_type_lookup_code      := c_lf.line_type_lookup_code;



                            v_ap_inv_lines_interface_rec.amount                     := c_lf.amount;

                            /* --artf2034435
                            IF c_lf.accounting_date < fnd_date.canonical_to_date(p_date) THEN
                                v_ap_inv_lines_interface_rec.accounting_date            := fnd_date.canonical_to_date(p_date);
                            ELSE
                                v_ap_inv_lines_interface_rec.accounting_date            := c_lf.accounting_date;
                            END IF;
                            */

                            v_ap_inv_lines_interface_rec.accounting_date := v_ap_invoices_interface_rec.gl_date; --artf2034435

                            --v_ap_inv_lines_interface_rec.accounting_date            := sysdate;--c_lf.accounting_date;-- doit être identique à gl_date de invoice_interface

                            v_ap_inv_lines_interface_rec.description                := c_lf.description;


                            v_ap_inv_lines_interface_rec.created_by                 := g_user_id;
                            v_ap_inv_lines_interface_rec.creation_date              := SYSDATE;

                            v_ap_inv_lines_interface_rec.attribute_category         := c_lf.attribute_category;
                            /*
                           --v_ap_inv_lines_interface_rec.project_id                 := ;--

                            SELECT ppa.project_id
                            INTO  v_ap_inv_lines_interface_rec.project_id
                            FROM  pa_projects_all ppa,
                                  hr_operating_units hor
                            WHERE ppa.segment1= hor.name||'_'||'000000'
                            AND hor.organization_id = g_org_id;

                            --v_ap_inv_lines_interface_rec.task_id                    := ;--
                            SELECT task_id
                            INTO   v_ap_inv_lines_interface_rec.task_id
                            FROM pa_tasks
                            WHERE project_id=v_ap_inv_lines_interface_rec.project_id
                            AND task_number=000000;


                            IF c_lf.expenditure_type IS NULL THEN
                                 c_lf.expenditure_type := 'CHARGES DIVERSES GESTION';
                            END IF;

                            --v_ap_inv_lines_interface_rec.expenditure_type           := c_lf.expenditure_type;-- transco(012_EXPENDITURE_TYPES)
                            dka_rep_transco_pkg.get_transco ( pv_transco_name  => '012_EXPENDITURE_TYPES',
                                               pv_column_01 => c_lf.expenditure_type,
                                               pv_out_01 => v_ap_inv_lines_interface_rec.expenditure_type
                                            );*/
                            /*
                            SELECT organization_id
                            INTO v_ap_inv_lines_interface_rec.expenditure_organization_id
                            FROM per_organization_units
                            WHERE name= fnd_profile.value('PA_DEFAULT_EXP_ORG');

                            IF fnd_profile.value('PA_AP_EI_DATE_DEFAULT') = 'POTRNSDT' THEN
                               v_ap_inv_lines_interface_rec.expenditure_item_date := c_f.invoice_date;
                            ELSE
                               v_ap_inv_lines_interface_rec.expenditure_item_date := SYSDATE;
                            END IF;

                            v_ap_inv_lines_interface_rec.pa_addition_flag := 'N';*/



                            v_ap_inv_lines_interface_rec.type_1099                  := c_lf.code_das2;
                            v_ap_inv_lines_interface_rec.assets_tracking_flag       := c_lf.assets_tracking_flag;
                            v_ap_inv_lines_interface_rec.org_id                     := v_ap_invoices_interface_rec.org_id;


                            --v_ap_inv_lines_interface_rec.tax_rate_code              := c_lf.code_tva;--transco 004_CODE_TVA
                            dka_rep_transco_pkg.get_transco ( pv_transco_name  => '004_CODE_TVA',
                                           pv_column_01 => c_lf.code_tva,
                                           pv_out_01 => v_code_tva
                                        );

                            IF c_lf.line_type_lookup_code = 'TAX'  THEN
                                v_ap_inv_lines_interface_rec.line_group_number          := c_lf.line_group_number;


                                v_ap_inv_lines_interface_rec.prorate_across_flag        := 'Y';

                                v_ap_inv_lines_interface_rec.dist_code_concatenated  := null;
                                v_ap_inv_lines_interface_rec.dist_code_combination_id := null;

                                SELECT  tax_rate_code,
                                        tax_regime_code,
                                        tax,
                                        tax_jurisdiction_code,
                                        tax_status_code
                                INTO    v_ap_inv_lines_interface_rec.tax_rate_code,
                                        v_ap_inv_lines_interface_rec.tax_regime_code,
                                        v_ap_inv_lines_interface_rec.tax,
                                        v_ap_inv_lines_interface_rec.tax_jurisdiction_code,
                                        v_ap_inv_lines_interface_rec.tax_status_code
                                FROM    zx_rates_b
                                WHERE tax_rate_code = v_code_tva
                                  AND sysdate between nvl(effective_from,sysdate) and nvl(effective_to,sysdate);


                                v_ap_inv_lines_interface_rec.tax_classification_code := NULL;

                            ELSE

                              IF c_lf.code_tva IS NOT NULL THEN
                                  BEGIN
                                      SELECT line_group_number
                                      INTO  v_ap_inv_lines_interface_rec.line_group_number
                                      FROM  dka_ap_rep_lignes_facture_tmp
                                      WHERE  invoice_num  = c_lf.invoice_num
                                      AND vendor_num = c_lf.vendor_num
                                      AND code_tva = c_lf.code_tva
                                      AND line_type_lookup_code = 'TAX';
                                  EXCEPTION
                                      WHEN OTHERS THEN
                                          v_ap_inv_lines_interface_rec.line_group_number := NULL;
                                  END;
                              ELSE
                                  v_ap_inv_lines_interface_rec.line_group_number := NULL;
                              END IF;

                              v_ap_inv_lines_interface_rec.prorate_across_flag            := NULL;
                              v_ap_inv_lines_interface_rec.tax_classification_code        := v_code_tva;--transco 004_CODE_TVA
                              v_ap_inv_lines_interface_rec.tax_regime_code                := NULL;
                              v_ap_inv_lines_interface_rec.tax                            := NULL;
                              v_ap_inv_lines_interface_rec.tax_jurisdiction_code          := NULL;
                              v_ap_inv_lines_interface_rec.tax_status_code                := NULL;
                              v_ap_inv_lines_interface_rec.tax_rate_code                  := NULL;

                              dka_rep_transco_pkg.get_transco ( pv_transco_name => '008_REGIONS',
                                                                pv_column_01    => c_lf.dist_code_combination_2,
                                                                pv_out_01       => c_lf.dist_code_combination_2);
                                /*
                                IF c_lf.dist_code_combination_5 !='0' THEN
                                  c_lf.dist_code_combination_5 := 'XXX'||c_lf.dist_code_combination_5;
                                END IF;
                                dka_rep_transco_pkg.get_cle_transco ( c_lf.dist_code_combination_1,
                                                                      c_lf.dist_code_combination_2,
                                                                      c_lf.dist_code_combination_3,
                                                                      c_lf.dist_code_combination_4,
                                                                      c_lf.dist_code_combination_5,
                                                                      --c_lf.dist_code_combination_6,
                                                                      c_lf.dist_code_combination_7,
                                                                      c_lf.dist_code_combination_8,
                                                                      c_lf.dist_code_combination_9,
                                                                      c_lf.dist_code_combination_10,
                                                                      v_dist_code_combination_1,
                                                                      v_dist_code_combination_2,
                                                                      v_dist_code_combination_3,
                                                                      v_dist_code_combination_4,
                                                                      v_dist_code_combination_5,
                                                                      v_dist_code_combination_6,
                                                                      v_dist_code_combination_7,
                                                                      v_dist_code_combination_8,
                                                                      v_dist_code_combination_9,
                                                                      v_dist_code_combination_10,
																		                                  v_dist_code_combination_11,
																		                                  v_dist_code_combination_12);

                                --v_ap_inv_lines_interface_rec.dist_code_combination_id    --:= ; transco ccf RG20
                                v_ap_inv_lines_interface_rec.dist_code_concatenated     :=  v_dist_code_combination_1    ||'.'||
                                                                                            v_dist_code_combination_2    ||'.'||
                                                                                            v_dist_code_combination_3    ||'.'||
                                                                                            v_dist_code_combination_4    ||'.'||
                                                                                            v_dist_code_combination_5    ||'.'||
                                                                                            v_dist_code_combination_6    ||'.'||
                                                                                            v_dist_code_combination_7    ||'.'||
                                                                                            v_dist_code_combination_8    ||'.'||
                                                                                            v_dist_code_combination_9    ||'.'||
                                                                                            v_dist_code_combination_10   ||'.'||
                                                                                            v_dist_code_combination_11   ||'.'||
                                                                                            v_dist_code_combination_12;

                                v_ccf := dka_rep_transco_pkg.get_cle_transco_f( c_lf.dist_code_combination_1,
                                                                                c_lf.dist_code_combination_2,
                                                                                c_lf.dist_code_combination_3,
                                                                                c_lf.dist_code_combination_4,
                                                                                c_lf.dist_code_combination_5,
                                                                                --c_lf.dist_code_combination_6,
                                                                                c_lf.dist_code_combination_7,
                                                                                c_lf.dist_code_combination_8,
                                                                                c_lf.dist_code_combination_9,
                                                                                c_lf.dist_code_combination_10);
                                v_ap_inv_lines_interface_rec.dist_code_combination_id := to_number(v_ccf);
                                --v_ap_inv_lines_interface_rec.dist_code_combination_id := null;
                                */
                              Dka_Tools_Pkg.get_code_combination_id (
                                  pv_segment1              => c_lf.dist_code_combination_1,
                                  pv_segment2              => c_lf.dist_code_combination_2,
                                  pv_segment3              => 'REPRIS', --'REPRISE',
                                  pv_segment4              => 'REP',
                                  pv_segment5              => '0',
                                  pv_segment6              => '0',
                                  pv_segment7              => '0',
                                  pv_segment8              => '0',
                                  pv_segment9              => '0',
                                  pv_segment10             => '0',
                                  pv_segment11             => '0',
                                  pv_segment12             => '0',
                                  pn_code_combination_id   => v_ap_inv_lines_interface_rec.dist_code_combination_id,
                                  pv_errbuf                => v_errbuf,
                                  pn_retcode               => v_retcode);

                            END IF;

                            IF insert_ap_invoice_lines_intrf(v_ap_inv_lines_interface_rec) = 1 THEN
                                --Fnd_File.put_line (Fnd_File.output,'Problème lors de l''insertion la ligne de facture numéro : '||v_ap_inv_lines_interface_rec.line_number);
                                v_message   := 'problème lors de l''insertion dans l''open interface ap_invoices_interface ';
                                validate_lignes_factures(g_org_id,c_lf.invoice_num,c_lf.vendor_num,c_lf.line_number,true,v_errbuf,v_retcode);
                                IF v_retcode = 2 THEN
                                    p_errbuf  := v_errbuf;
                                    p_retcode := v_retcode;
                                    RAISE v_exeption;
                                END IF;
                                p_errbuf  := g_message_erreur_chargement;
                                p_retcode := 2;
                                RAISE v_exeption;

                            ELSE
                                --Fnd_File.put_line (Fnd_File.LOG,'L''insertion de la ligne de facture numéro : '||v_ap_inv_lines_interface_rec.line_number||' avec succès');
                                v_message   := 'Insertion dans l''open interface ap_invoice_lines_interface avec succès';
                                validate_lignes_factures(g_org_id,c_lf.invoice_num,c_lf.vendor_num,c_lf.line_number,false,v_errbuf,v_retcode);
                                IF v_retcode = 2 THEN
                                    p_errbuf  := v_errbuf;
                                    p_retcode := v_retcode;
                                    RAISE v_exeption;
                                END IF;
                                g_nb_lignes_fact_cree_oi :=g_nb_lignes_fact_cree_oi+1;
                            END IF;

                        END LOOP;

                    END IF;

                ELSE
                    v_warining_interface_globale := TRUE;
                END IF;
            END LOOP;
 
            IF v_warining_interface_globale  THEN
                p_retcode := 1;
                Fnd_File.put_line (Fnd_File.log,'Insertion dans les opens interfaces terminée avec des lignes non inserées');
            ELSE
                Fnd_File.put_line (Fnd_File.log,'Insertion dans les opens interfaces terminée correctement');
            END IF ;

        END IF;


        /*============================================================================================*/
        /*appel des traitements standards d'import des factures*/
        /*============================================================================================*/
        IF p_lancement_prog_stand ='Y' THEN
            Fnd_File.put_line (Fnd_File.output,chr(10));
            Fnd_File.put_line (Fnd_File.LOG,chr(10));
            Fnd_File.put_line (Fnd_File.LOG,'/*============================================================================================*/');
            Fnd_File.put_line (Fnd_File.LOG,'/*appel des traitements standards d''import des factures*/');
            Fnd_File.put_line (Fnd_File.LOG,'/*============================================================================================*/');

            --V1.1:
            /*
            FOR ord_id_facture IN (SELECT distinct org_id FROM ap_invoices_interface WHERE nvl(status,'NEW') != 'PROCESSED' )
            */
            FOR ord_id_facture IN (SELECT distinct aii.org_id
                                     FROM ap_invoices_interface aii
                                    WHERE nvl(aii.status, 'NEW') != 'PROCESSED'
                                      AND EXISTS (SELECT 1
                                                    FROM PER_SECURITY_ORGANIZATIONS_V ov
                                                   WHERE ov.security_profile_id = fnd_profile.value('XLA_MO_SECURITY_PROFILE_LEVEL')
                                                     AND ov.organization_id = aii.org_id))
            LOOP

                g_org_id:=ord_id_facture.org_id;

                -- Initialiser org_id
                v_message   := 'init_environement';
                Fnd_File.put_line (Fnd_File.log, 'Initialisation de l''environnement');
                --V1.1
                /*
                init_environement(v_errbuf, v_retcode);
                IF v_retcode = 1 THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    CONTINUE;
                END IF;
                IF v_retcode = 2 THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    v_message :='init_environnement pour le traitement standard d''import des factures de lorg_id:'||g_org_id;
                    RAISE v_exeption;
                END IF;
                */
                Fnd_File.put_line (Fnd_File.LOG,'appel des traitements standards d''imports des factures pour les org_id :'||g_org_id);
                v_message   := 'appel des traitements standards d''import des factures';
                Fnd_File.put_line (Fnd_File.LOG,'========================================================================================');
                program_import_factures(v_errbuf,v_retcode);

                IF v_retcode = 2
                THEN
                    p_errbuf  := v_errbuf;
                    p_retcode := v_retcode;
                    v_message :='Erreur traitement standard d''import des facture de lorg_id:'||g_org_id;
                    RAISE v_exeption;
                END IF;

                IF v_retcode=1 THEN
                    p_retcode := v_retcode;
                    Fnd_File.put_line (Fnd_File.log,'/*Des lignes de factures de l''org_id:'||g_org_id ||' ont été rejetées voir  détail dans le journal */');
                ELSE
                    Fnd_File.put_line (Fnd_File.log,'/*Traitement d''import des factures terminé correctement de l''org_id:'||g_org_id||'*/');
                END IF ;

            END LOOP;



        END IF;

        /*============================================================================================*/
        /*insertion dans la table des blocages*/
        /*============================================================================================*/
        IF p_chargement_blocage ='Y' THEN

            Fnd_File.put_line (Fnd_File.LOG,chr(10));
            Fnd_File.put_line (Fnd_File.LOG,'/*============================================================================================*/');
            Fnd_File.put_line (Fnd_File.LOG,'/*insertion dans la table des blocages*/');
            Fnd_File.put_line (Fnd_File.LOG,'/*============================================================================================*/');

          FOR c_b IN cur_blocage LOOP
            
            v_message :='récupération de la facture invoice_id '||c_b.invoice_id;
            BEGIN
              SELECT aia.invoice_id
              INTO v_invoice_id
              FROM ap_invoices_all aia
              JOIN ap_suppliers    aps on(aps.vendor_id = aia.vendor_id)
              WHERE aia.invoice_num = c_b.invoice_num --invoice_id = c_b.invoice_id
                AND aps.segment1 = c_b.vendor_num
                AND aia.org_id = c_b.org_id;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                BEGIN
                  g_message_erreur_chargement := 'la facture invoice_id '||c_b.invoice_id||' est introuvable';
                  --Fnd_File.put_line (Fnd_File.LOG,'la facture invoice_id'||c_b.invoice_id||' est introuvable');
                  v_message := g_message_erreur_chargement;
                  UPDATE dka_ap_rep_blocages_tmp
                  SET    message_erreur = g_message_erreur_chargement
                  WHERE  invoice_num     = c_b.invoice_num
                  AND    vendor_num     = c_b.vendor_num
                  AND    invoice_id     = c_b.invoice_id
                  AND    org_id         = c_b.org_id;
                EXCEPTION
                  WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
                    v_message := 'ERREUR1 lors de la mise à jour du message d''erreur de la table temporaire des blocages facture lors de l''insertion';
                    RAISE v_exeption;
                END;
                CONTINUE;
              WHEN OTHERS THEN
                g_message_erreur_chargement := 'erreur lors de la récupération de la facture invoice_id '||c_b.invoice_id;
                --Fnd_File.put_line (Fnd_File.LOG,'erreur lors de la récupération de la facture invoice_id'||c_b.invoice_id);
                v_message := g_message_erreur_chargement;
                BEGIN
                  UPDATE dka_ap_rep_blocages_tmp
                  SET    message_erreur = g_message_erreur_chargement
                  WHERE  invoice_num    = c_b.invoice_num
                  AND    vendor_num     = c_b.vendor_num
                  AND    invoice_id     = c_b.invoice_id
                  AND    org_id         = c_b.org_id;
                EXCEPTION
                  WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
                    v_message := 'erreur lors de la mise à jour du message d''erreur de la table temporaire des blocages facture lors de l''insertion';
                    RAISE v_exeption;
                END;
                CONTINUE;
            END;
            
            -- Vérification de l'existence du code blocage sur la facture
            v_message := 'Vérification existence blocage';
            IF check_holds(p_invoice_id          => v_invoice_id,
                           p_hold_lookup_code    => c_b.hold_lookup_code,
                           p_release_lookup_code => c_b.release_lookup_code,
                           p_hold_date           => c_b.hold_date) THEN
              
              Fnd_File.put_line(Fnd_File.LOG, 'Le code blocage '||c_b.hold_lookup_code||' existe déjà sur la facture.');
              
              -- MàJ de la table de travail pour le code blocage déjà existant sur la facture
              BEGIN
                UPDATE dka_ap_rep_blocages_tmp
                SET processed_request_id = g_request_id,
                    message_erreur = NULL
                WHERE invoice_num = c_b.invoice_num
                  AND vendor_num = c_b.vendor_num
                  AND invoice_id = c_b.invoice_id
                  AND org_id = c_b.org_id;
              EXCEPTION
                WHEN OTHERS THEN
                  p_errbuf  := SQLERRM;
                  p_retcode := 2;
                  v_message :='Erreur lors de la mise à jour du PROCESSED_REQUEST_ID de la table temporaire des blocages facture lors de la vérification.';
                  raise v_exeption;
              END;
              
            ELSE
            
              v_message := 'Récuperation user_id';
              BEGIN
                SELECT user_id
                INTO v_user_id
                FROM  fnd_user
                WHERE user_name = c_b.held_by;
              EXCEPTION
                WHEN OTHERS THEN
                  v_user_id := -1;
              END;

              v_ap_holds_all_rec.invoice_id             := v_invoice_id;
              --v_ap_holds_all_rec.line_location_id       := c_b.line_location_id;
              v_ap_holds_all_rec.hold_lookup_code       := c_b.hold_lookup_code;
              v_ap_holds_all_rec.hold_reason            := c_b.hold_reason;
              
              IF c_b.hold_lookup_code IN  ('FINAL MATCHING','MAX SHIP AMOUNT','PRICE','QTY ORD','QTY REC') THEN
                v_ap_holds_all_rec.hold_lookup_code       := 'REPRISE';
                v_ap_holds_all_rec.hold_reason            := c_b.hold_reason_reprise;--artf2147106
              END IF;-- YWA artf2145111 
               
              v_ap_holds_all_rec.last_update_date       := SYSDATE ;
              v_ap_holds_all_rec.last_updated_by        := g_user_id;
              v_ap_holds_all_rec.held_by                := v_user_id;
              v_ap_holds_all_rec.hold_date              := c_b.hold_date;
              
              v_ap_holds_all_rec.release_lookup_code    := c_b.release_lookup_code;
              v_ap_holds_all_rec.release_reason         := c_b.release_reason;
              v_ap_holds_all_rec.status_flag            := c_b.status_flag;
              v_ap_holds_all_rec.creation_date          := c_b.creation_date;
              v_ap_holds_all_rec.created_by             := v_ap_holds_all_rec.held_by;
              v_ap_holds_all_rec.org_id                 := c_b.org_id;
              v_ap_holds_all_rec.hold_id                := ap_holds_s.NEXTVAL;

              Fnd_File.put_line (Fnd_File.LOG,'');
              v_message := '';
              IF insert_ap_holds_all(v_ap_holds_all_rec) = 1 THEN
                
                v_message := 'ERREUR lors de l''insertion du blocage: '||v_ap_holds_all_rec.hold_reason||' pour la facture id :' ||v_invoice_id;
                BEGIN
                  UPDATE dka_ap_rep_blocages_tmp
                  SET    message_erreur = g_message_erreur_chargement
                  WHERE  invoice_num     = c_b.invoice_num
                  AND    vendor_num     = c_b.vendor_num
                  AND    invoice_id     = c_b.invoice_id
                  AND    org_id         = c_b.org_id;
                EXCEPTION
                  WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
                    v_message :='ERREUR3 lors de la mise à jour du message d''erreur de la table temporaire des blocages facture lors de l''insertion';
                    RAISE v_exeption;
                END;
                CONTINUE;

              ELSE
                    
                v_message := 'L''insertion du blocage: '||v_ap_holds_all_rec.hold_reason||' pour la facture id :' ||v_invoice_id||' a bien été effectuée';
                g_nb_blocage_cree := g_nb_blocage_cree+1;
                BEGIN
                  UPDATE dka_ap_rep_blocages_tmp
                  SET    processed_request_id = g_request_id,
                          message_erreur = NULL
                  WHERE  invoice_num     = c_b.invoice_num
                  AND    vendor_num     = c_b.vendor_num
                  AND    invoice_id    = c_b.invoice_id
                  AND    org_id         = c_b.org_id;
                EXCEPTION
                  WHEN OTHERS THEN
                    p_errbuf  := SQLERRM;
                    p_retcode := 2;
                    v_message :='ERREUR4 lors de la mise à jour du PROCESSED_REQUEST_ID de la table temporaire des blocages facture lors de l''insertion';
                    RAISE v_exeption;
                END;

              END IF;
            END IF;
          END LOOP;

          BEGIN
            SELECT count(invoice_num)
            INTO v_nb_erreur_blocage
            FROM  dka_ap_rep_blocages_tmp
            WHERE  processed_request_id = -1;

            Fnd_File.put_line (Fnd_File.output,'-------------------------------------------------------------------------------------------------------------------------------------------------------');
            Fnd_File.put_line (Fnd_File.output,'---------------------------------------------------------------REJETS des blocages---------------------------------------------------------------------');
            Fnd_File.put_line (Fnd_File.output,'-------------------------------------------------------------------------------------------------------------------------------------------------------');
            Fnd_File.put_line (Fnd_File.output,RPAD('UO',10,' ')||RPAD('NUMERO FOURNISSEUR',30,' ')||RPAD('NUMERO FACTURE',30,' ')||RPAD('BLOQUAGE' ,30,' ')||'MOTIF');
            Fnd_File.put_line (Fnd_File.output,'-------------------------------------------------------------------------------------------------------------------------------------------------------');
            Fnd_File.put_line (Fnd_File.output,chr(10));
            FOR rej_b IN(SELECT org_id,
                                vendor_num,
                                invoice_num,
                                hold_lookup_code,
                                message_erreur
                         FROM dka_ap_rep_blocages_tmp
                         WHERE processed_request_id = -1
                           AND message_erreur IS NOT NULL) LOOP
                           
              Fnd_File.put_line (Fnd_File.output,RPAD(nvl(to_char(rej_b.org_id),' '),10,' ')||RPAD(rej_b.vendor_num,30,' ')||RPAD(rej_b.invoice_num,30,' ')||RPAD(rej_b.hold_lookup_code,30,' ')||rej_b.message_erreur);
            END LOOP;
            
          EXCEPTION
            WHEN OTHERS THEN
              p_errbuf  := SQLERRM;
              p_retcode := 2;
              v_message :='Vérification nombre de blocages non traitée';
              RAISE v_exeption;
          END;


          IF v_nb_erreur_blocage != 0 THEN
            Fnd_File.put_line (Fnd_File.log,'/*Des lignes de blocage non pas été insérées*/');
          ELSE
            Fnd_File.put_line (Fnd_File.log,'/*toutes les lignes de blocage ont bien été insérées*/');
          END IF;

        END IF;
        
        --< OBE artf2191277
        IF p_chargement_echeances = 'Y' THEN
        
          Fnd_File.put_line (Fnd_File.LOG,chr(10));
          Fnd_File.put_line (Fnd_File.LOG,'/*============================================================================================*/');
          Fnd_File.put_line (Fnd_File.LOG,'/*Mise à jour des champs HOLD_FLAG des échéances de paiement*/');
          Fnd_File.put_line (Fnd_File.LOG,'/*============================================================================================*/');
        
          UPDATE dka_ap_rep_entete_facture_tmp dar
          SET dar.processed_request_id = g_request_id
             ,dar.last_update_date = sysdate
          WHERE dar.HOLD_FLAG = 'Y'
          AND EXISTS (SELECT aii.*
                          FROM ap_invoices_interface aii, po_vendors pv
                          WHERE aii.invoice_num = dar.invoice_num
                           AND pv.segment1 = dar.vendor_num
                           AND pv.vendor_id = aii.vendor_id
                           AND aii.status = 'PROCESSED')
          ;

          FOR rec IN cur_hold_flag LOOP
          
            BEGIN
              UPDATE ap_payment_schedules_all
              SET HOLD_FLAG        = rec.hold_flag
                 ,iby_hold_reason  = 'Reprise '||TO_CHAR('-')||' Bloquée paiement'
                 ,last_update_date = SYSDATE
                 ,last_updated_by  = g_user_id
              WHERE invoice_id     = rec.invoice_id
              ;
              
              Fnd_File.put_line (Fnd_File.log,'La mise à jour du champs blocage au niveau des échéances de paiement a été effectuée. Invoice ID : '||TO_CHAR(rec.invoice_id));
              
            EXCEPTION
              WHEN OTHERS THEN
                p_errbuf  := SQLERRM;
                p_retcode := 2;
                v_message :='Erreur lors de la mise à jour du champs blocage au niveau des échéances de paiement. Invoice ID : '||TO_CHAR(rec.invoice_id);
                RAISE v_exeption;            
            END;
              
          END LOOP;
        END IF;
        --> OBE artf2191277

        /*============================================================================================*/
        -- PHASE DE FIN DU TRAITEMENT MAITRE --
        /*============================================================================================*/

        SELECT COUNT(1)
          INTO g_nb_rejet_dka_entete
          FROM dka_ap_rep_entete_facture_tmp
         WHERE processed_request_id = -1;
           --AND message_erreur IS NOT NULL;

        SELECT COUNT(1)
          INTO g_nb_rejet_dka_ligne
          FROM dka_ap_rep_lignes_facture_tmp
         WHERE processed_request_id = -1;
           --AND message_erreur IS NOT NULL;

        SELECT COUNT(1)
          INTO g_nb_rejet_dka_blocage
          FROM dka_ap_rep_blocages_tmp
         WHERE processed_request_id = -1;
           --AND message_erreur IS NOT NULL;

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

        COMMIT;
        Fnd_File.put_line (Fnd_File.output, p_errbuf);
        Fnd_File.put_line (Fnd_File.LOG, CHR(10)||p_errbuf||CHR(10));
        Fnd_File.put_line (Fnd_File.LOG,'==========================================================================');
        Fnd_File.put_line (Fnd_File.LOG, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.LOG,'==========================================================================');
        --Fnd_File.put_line (Fnd_File.output, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'FIN DE L''INTERFACE');

    EXCEPTION
        WHEN v_exeption THEN
            --p_retcode := 2;
            --p_errbuf  := 'Erreur EXCEPTION v_exception dans pkg.proc/fonc '||v_package||'.'||v_procedure;
            Fnd_File.put_line (Fnd_File.LOG,'-------------------- ERREUR --------------------');
            Fnd_File.put_line (Fnd_File.LOG,'Package   : '||v_package);
            Fnd_File.put_line (Fnd_File.LOG,'Procédure : '||v_procedure);
            Fnd_File.put_line (Fnd_File.LOG,'Exception : OTHERS');
            Fnd_File.put_line (Fnd_File.LOG,'Message   : '||v_message);
            Fnd_File.put_line (Fnd_File.LOG,'Cause     : '||p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG,'------------------------------------------------');
            Fnd_File.put_line (Fnd_File.LOG,'==> Fin de la procédure '||v_procedure||' : EXCEPTION v_exeption ');
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            Fnd_File.put_line (Fnd_File.LOG,'Traitement '||v_nom_traitement||' terminé en erreur         ');
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            ROLLBACK;

       WHEN OTHERS THEN
            v_sqlerrm := SUBSTR(SQLERRM,1,200);
            p_retcode := 2;
            p_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc '||v_package||'.'||v_procedure;
            Fnd_File.put_line (Fnd_File.LOG,'-------------------- ERREUR --------------------');
            Fnd_File.put_line (Fnd_File.LOG,'Package   : '||v_package);
            Fnd_File.put_line (Fnd_File.LOG,'Procédure : '||v_procedure);
            Fnd_File.put_line (Fnd_File.LOG,'Exception : OTHERS');
            Fnd_File.put_line (Fnd_File.LOG,'Message   : '||v_message);
            Fnd_File.put_line (Fnd_File.LOG, CHR(10)||p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG,'Cause     : '||v_sqlerrm);
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            Fnd_File.put_line (Fnd_File.LOG,'Traitement '||v_nom_traitement||' terminé en erreur         ');
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            ROLLBACK;

    END main;


END DKA_REPAPFCTIMP_PKG;
/
SHOW ERRORS PACKAGE DKA_REPAPFCTIMP_PKG;
EXIT
