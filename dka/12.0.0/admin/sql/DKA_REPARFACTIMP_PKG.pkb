SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

create or replace PACKAGE BODY DKA_REPARFACTIMP_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME
--    DKA_REPARFACTIMP_PKG.pkb  V2.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION
--    Création du package de l'interface specifique d'import des factures clients
--
-- USAGE
--    A exécuter sous SqlPlus avec user APPS sans paramètre
--
-- NOTES
--
-- PARAMETERS
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    19/04/2016     RAZ Creation
-- v1.1    28/09/2016     PBR Modification du calcul des montants pour les lignes et les ventilations. --artf2014189
-- v1.2    14/10/2016     PBR Modification de l'alimentation du segment3 et de l'attribute8.
-- v1.3    19/10/2016     MEG artf2031282 : Reprise en cours Facture - Optimisation
-- v1.4    02/11/2016     JLY artf2031282 : Reprise en cours Facture - Optimisation
--                            artf2014189 : Reprise des factures clients - Problème d'import des factures partiellement réglées
-- v1.5    07/11/2016     JLY artf2031282 : Reprise en cours Facture - Optimisation
--                            artf2040185 : REP004 - Import - Rattachement des lignes de distribution 
--                            artf2040317 : REP004 - Import - Controle du solde
-- v1.6    26/01/2017     JLY artf2090895 : REP002 - Import - Gestion de la date GL d'import
-- v1.7    10/02/2017     JLY artf2104888 : REP002 - Import - Lancement MOAC
--                        JLY artf2104891 : REP002 - Import - Signe des types de transaction
-- v1.8    27/02/2017     JLY artf2108451 : REP004 - Import - Defect 581 - Gestion des CUF
-- v1.9    01/03/2017     JLY artf2110172 : REP004 - Import - Defect 583 - Gestion des Reliquats (CB)
-- v2.0    28/04/2017     OBE artf2143238 / artf2143230
-- v2.1    29/05/2017     NBO artf2142366 - REP004 - Reprise des factures clients - Optimisation
-- v2.2    11/08/2017     RBE artf2211077, artf2205802, artf2205811 et artf2205817
---------------------------------------------------------------------------------------------

 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    TYPE summary_typ IS RECORD
    (
     loaded_header_fact_rows          NUMBER      -- Nb des en-entêtes chargées en table specifique
    ,loaded_distrib_rows              NUMBER      -- Nb des détails chargés en table specifique
    ,rejected_header_fact_rows        NUMBER      -- Nb de Lignes en-entêtes rejectées
    ,rejected_distrib_rows            NUMBER      -- Nb de Lignes détail rejectés
    ,inserted_header_fact_rows        NUMBER      -- Nb de Lignes en-entêtes insérées
    ,inserted_distrib_rows            NUMBER      -- Nb de Lignes detail insérés
    ,message_flag                     NUMBER      -- Flag d'entete etat des erreurs
    ,reprise_flag                     VARCHAR2(1) -- Flag reprise
    )
    ;

    TYPE rec_request IS RECORD
    (
     request_id number,
     interval   number,
     max_wait   number,
     phase      varchar2(80),
     status     varchar2(80),
     dev_phase  varchar2(15),
     dev_status varchar2(15),
     message    varchar2(255)
     )
     ;

    type tab_request is table of rec_request index by binary_integer;
    g_tab_requests   tab_request;

    g_summary                      summary_typ;

    g_user_id                      fnd_user.user_id%TYPE;
    g_login_id                     fnd_logins.login_id%TYPE;
    g_org_id                       hr_all_organization_units.organization_id%TYPE;
    g_request_id                   fnd_concurrent_requests.request_id%TYPE;

    g_loader_request_id            Fnd_Concurrent_Requests.Request_Id%Type;
    g_int_request_id               Fnd_Concurrent_Requests.Request_Id%Type;

    gv_printer                     fnd_concurrent_requests.printer%TYPE;
    g_number_of_copies             fnd_concurrent_requests.number_of_copies%TYPE;
    g_tempo                        NUMBER;

    g_source_name                  VARCHAR2(240) := 'REPRISE';
    
    --< V1.6
    g_gl_date                      DATE;
    g_gl_date_max                  DATE;
    --> V1.6
    
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
        p_retcode   OUT      NUMBER,
        p_reprise   IN       VARCHAR2
        )
  IS

    v_current_program_unit    VARCHAR2(30);
    v_step_program_error      VARCHAR2(1000);
    program_error             EXCEPTION;

  BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début init');

        ----------------------------------
        -- Initialisation des variables --
        ----------------------------------
        p_errbuf  := NULL;
        p_retcode := 0;
        v_current_program_unit := 'INIT';

        ------------------------
        -- Variables globales --
        ------------------------

        g_user_id                      := fnd_global.user_id;
        g_login_id                     := fnd_global.login_id;
        g_request_id                   := fnd_global.conc_request_id;
        g_org_id                       := fnd_profile.value ('ORG_ID');
        g_tempo                        := 20;
        
        

        -- Variables globales de comptage

        g_summary.loaded_header_fact_rows             := 0;
        g_summary.loaded_distrib_rows                 := 0;
        g_summary.rejected_header_fact_rows           := 0;
        g_summary.rejected_distrib_rows               := 0;
        g_summary.inserted_header_fact_rows           := 0;
        g_summary.inserted_distrib_rows               := 0;

        g_summary.message_flag                        := 0;
        g_summary.reprise_flag                        := NVL(p_reprise,'N');

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin init');

        BEGIN
           SELECT printer
                 ,number_of_copies
           INTO   gv_printer
                 ,g_number_of_copies
           FROM   fnd_concurrent_requests fcr
           WHERE  fcr.request_id = g_request_id;
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
           Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Erreur de récupération de l''imprimante');
           gv_printer := NULL;
           g_number_of_copies := 0;
        END;



  EXCEPTION
        WHEN program_error THEN
             fnd_file.put_line(fnd_file.log, 'ERREUR : ' || v_step_program_error);
             RAISE;
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'INIT : ' ||SQLERRM;
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
                              p_resp_key IN VARCHAR2) IS
    v_resp_id      NUMBER;
    v_resp_appl_id NUMBER;
  BEGIN

    p_retcode := 0;

    SELECT responsibility_id, application_id
      INTO v_resp_id, v_resp_appl_id
      FROM fnd_responsibility fr
     WHERE fr.responsibility_key = p_resp_key;

    fnd_global.apps_initialize(g_user_id, v_resp_id, v_resp_appl_id);
    Fnd_File.put_line(Fnd_File.LOG,
                      'Environnement initialisé avec la responsabilité ' ||
                      p_resp_key);

  EXCEPTION
    WHEN program_error THEN
      Fnd_File.put_line(Fnd_File.LOG, 'ERREUR : ' || p_errbuf);
    WHEN NO_DATA_FOUND THEN
      p_retcode := 1;
      p_errbuf  := 'init_environement: ' || SQLERRM;
      Fnd_File.put_line(Fnd_File.LOG, 'ERREUR : ' || p_errbuf);
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'init_environement: ' || SQLERRM;

  END init_environement;


  /*
   *=========================================================================
   * PROCEDURE NAME : wait_import
   * DESCRIPTION      :  Attendre la fin des Traitements standard d'import des sites fournisseurs
   *=========================================================================
  */
  PROCEDURE wait_import(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
    v_phase      VARCHAR2(100);
    v_status     VARCHAR2(100);
    v_dev_phase  VARCHAR2(100);
    v_dev_status VARCHAR2(100);
    v_message    VARCHAR2(100);
    v_nb_ok      NUMBER;
    --v_nb_rejet         NUMBER;

    i BINARY_INTEGER;

  BEGIN

    i := g_tab_requests.first;
    WHILE i IS NOT NULL LOOP

      IF NOT Fnd_Concurrent.wait_for_request(g_tab_requests(i).request_id,
                                             g_tab_requests(i).interval,
                                             g_tab_requests(i).max_wait,
                                             v_phase,
                                             v_status,
                                             v_dev_phase,
                                             v_dev_status,
                                             v_message) THEN
        p_errbuf := v_message;
        Fnd_File.put_line(Fnd_File.output,
                          'ERREUR : Attente de la fin du programme dépassée : Fin du traitement' ||
                          CHR(10) || 'MESSAGE : ' || v_message || CHR(10));
      END IF;

      IF v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL' THEN

        Fnd_File.put_line(Fnd_File.output,
                          'COMPLETION= ' || v_dev_phase || '/' ||
                          v_dev_status);


      ELSIF v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING' THEN

        Fnd_File.put_line(Fnd_File.output,
                          'Fin du traitement standard d''import des sites fournisseurs en warning ' ||
                          g_tab_requests(i).request_id);
        v_message := 'ERREUR : Fin du traitement en warning: ' || v_message;
        p_retcode := 1;

      ELSIF v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL' THEN

        p_retcode := 2;
        v_message := 'ERREUR : Fin anormale du traitement standard d''import des sites fournisseurs : ' ||
                     v_message;

        Fnd_File.put_line(Fnd_File.output,
                          'ERREUR : Fin anormale du traitement ' ||
                           g_tab_requests(i)
                          .request_id || CHR(10) || 'Phase/Statut : ' ||
                           v_dev_phase || '/' || v_dev_status || CHR(10) ||
                           'MESSAGE : ' || v_message || CHR(10));
        --Fnd_File.put_line (Fnd_File.LOG, '===> ERREUR : Fin anormale du traitement '||g_import_request_id);
      END IF;

      p_errbuf := v_message;
      i        := g_tab_requests.next(i);
    END LOOP;

  END wait_import;


 /*
 *************************************************************************
 * PROCEDURE NAME : Output_Header
 *
 * DESCRIPTION
 *  Procédure pour insérer une en-tête dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE output_header
  IS
        cv_line                     VARCHAR2 (100);
        v_conc_program_name         fnd_concurrent_programs.concurrent_program_name%TYPE;
        v_user_conc_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN

        cv_line    := '+-------------------------------------------------------------------------+';

        ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
        BEGIN
            SELECT fcp.concurrent_program_name,
                   fcpt.user_concurrent_program_name
            INTO   v_conc_program_name,
                   v_user_conc_program_name
            FROM   fnd_concurrent_programs fcp,
                   fnd_concurrent_programs_tl fcpt
            WHERE  fcp.application_id = Fnd_Global.prog_appl_id
            AND    fcp.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.application_id = Fnd_Global.prog_appl_id
            AND    fcpt.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.LANGUAGE = Fnd_Global.current_language;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_user_conc_program_name    := '???????????????????????';
                v_conc_program_name         := '???????';
        END;


        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Nom du traitement  : ' || v_user_conc_program_name);
        Fnd_File.put_line (Fnd_File.output, 'Code du traitement : ' || v_conc_program_name);
        Fnd_File.put_line (Fnd_File.output, 'Programme lancé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10) || CHR(10));
  END output_header;


 /*
 *************************************************************************
 * PROCEDURE NAME : Request_parameters
 *
 * DESCRIPTION
 *  Procédure pour afficher les valeurs de paramètres du traitement
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 ************************************************************************
 */

  PROCEDURE Request_parameters
  IS

      CURSOR cur_parameters
            IS
            SELECT form_left_prompt
            FROM   fnd_concurrent_requests fcr,
                   fnd_concurrent_programs fcp,
                   fnd_descr_flex_col_usage_vl fdfcu
            WHERE  fdfcu.descriptive_flexfield_name = '$SRS$.'||fcp.concurrent_program_name
            AND    fcp.concurrent_program_id = fcr.concurrent_program_id
            AND    fcr.request_id = Fnd_Global.conc_request_id
            ORDER BY fdfcu.column_seq_num
            ;
        rec_parameters        cur_parameters%ROWTYPE;

        sql_req               VARCHAR2(500);
        v_argument_number    VARCHAR2(12);
        v_argument_num       NUMBER;
        v_argument_value     VARCHAR2(240);
  BEGIN

        Fnd_File.put_line (Fnd_File.output, 'PARAMETRES : ');
        Fnd_File.put_line (Fnd_File.output, '--------------');
        Fnd_File.put_line (Fnd_File.log, 'PARAMETRES : ');
        Fnd_File.put_line (Fnd_File.log, '--------------');

        v_argument_num := 1;

        OPEN cur_parameters;
        FETCH cur_parameters INTO rec_parameters;

             IF (cur_parameters%FOUND)
             THEN
                   v_argument_number := 'ARGUMENT'||v_argument_num;

                   sql_req := 'SELECT '||v_argument_number||
                              ' FROM fnd_concurrent_requests '||
                              'WHERE request_id = Fnd_Global.conc_request_id';

                   EXECUTE IMMEDIATE sql_req INTO v_argument_value;

                   Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
                   Fnd_File.put_line (Fnd_File.log, rec_parameters.form_left_prompt||' : '||v_argument_value);


                   LOOP
                      FETCH cur_parameters INTO rec_parameters;
                      EXIT WHEN cur_parameters%NOTFOUND;

                          v_argument_num := v_argument_num + 1;
                          v_argument_number := 'ARGUMENT'||v_argument_num;

                          sql_req := 'SELECT '||v_argument_number||
                                     ' FROM fnd_concurrent_requests '||
                                     'WHERE request_id = Fnd_Global.conc_request_id';

                          EXECUTE IMMEDIATE sql_req INTO v_argument_value;

                          Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
                          Fnd_File.put_line (Fnd_File.log, rec_parameters.form_left_prompt||' : '||v_argument_value);
                   END LOOP;

                   Fnd_File.put_line (Fnd_File.output,CHR(10));

            ELSE
                   Fnd_File.put_line (Fnd_File.output,'Aucun argument');
                   Fnd_File.put_line (Fnd_File.log,'Aucun argument');
            END IF;

        CLOSE cur_parameters;

  END Request_parameters;

 /*
 *************************************************************************
 * PROCEDURE NAME : Output_End
 *
 * DESCRIPTION
 *  Procédure pour insérer une fin dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE output_end
  IS
        cv_line                     VARCHAR2 (100);
  BEGIN

        cv_line    := '+-------------------------------------------------------------------------+';



        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
        Fnd_File.put_line (Fnd_File.output, cv_line);
  END output_end;

 /*
 *************************************************************************
 * PROCEDURE NAME : Add_Message
 *
 * DESCRIPTION
 *  Procédure pour insérer un message dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE Add_Message  (p_document_num      IN  VARCHAR2,
                          p_societe           IN  VARCHAR2,
                          P_centre            IN  VARCHAR2,
                          p_line_num          IN  VARCHAR2,
                          p_message_text      IN  VARCHAR2
                          )
  IS
        cv_line                     VARCHAR2 (500);
  BEGIN

    IF  g_summary.message_flag = 0 THEN
      cv_line := 'Etat des erreurs :';
      Fnd_File.put_line (Fnd_File.output, CHR(10)||cv_line);
      cv_line := '-----------------';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := 'Numéro de la facture  Société  Région  Num Ligne  Message d''erreur';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := '--------------------  -------  ------  ---------  -----------------';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      g_summary.message_flag := 1;
    END IF;

    cv_line := RPAD(p_document_num,20,' ') ||'  '||RPAD(NVL(p_societe,' '),7,' ')||'  '||RPAD(NVL(P_centre,' '),6,' ')||'  '||RPAD(NVL(p_line_num,' '),9,' ') ||'  ' || p_message_text ;

    Fnd_File.put_line (Fnd_File.output, cv_line);

  END Add_Message;

/*
*************************************************************************
 * FUNCTION NAME : get_organization_id
 *
 * DESCRIPTION
 *  Fonction pour récupérer l'organisation ID
 *
 * PARAMETERS
 * ==========
 * NAME                    DESCRIPTION
 * ----------------------- -------------------------------------------------
 * p_societe           Nom de la societé
 * p_region            Nom de la région
 * RETURN
 * ======
 * v_organization_id
 *
 ************************************************************************
 */

  FUNCTION get_organization_id ( p_societe  IN VARCHAR2,
                                 p_region   IN VARCHAR2) RETURN NUMBER
  IS
    v_organization_id  NUMBER;

  BEGIN

    -- Recherche  de l'org_id
    SELECT  hr.ORGANIZATION_ID
    INTO    v_organization_id
    FROM    hr_operating_units hr
    WHERE   hr.NAME = p_region||p_societe;

    RETURN  v_organization_id;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_organization_id;

  ----------------------------------------------------------------------------
  -- FUNCTION NAME : get_cust_acct_id
  -- DESCRIPTION : Fonction qui retourne l'identifiant du client
  -- NSI 11/10/2016
  ----------------------------------------------------------------------------
  FUNCTION get_cust_acct_id (p_orig_syst_ref IN hz_cust_accounts.orig_system_reference%type) RETURN hz_cust_accounts.cust_account_id%type
  IS
    v_cust_acct_id   hz_cust_accounts.cust_account_id%type;

  BEGIN

    SELECT  CUST_ACCOUNT_ID
    INTO    v_cust_acct_id
    FROM    HZ_CUST_ACCOUNTS
    WHERE   ORIG_SYSTEM_REFERENCE = p_orig_syst_ref;

    RETURN v_cust_acct_id;

  EXCEPTION
    WHEN OTHERS THEN
      Fnd_File.put_line(Fnd_File.LOG, 'Erreur lors de la récupération de l''id du client référencé : '||p_orig_syst_ref);
      RETURN -1;
  END get_cust_acct_id;

  ----------------------------------------------------------------------------
  -- FUNCTION NAME : get_cust_site_use_id
  -- DESCRIPTION : Fonction qui retourne l'identifiant de la fonction du site client
  -- NSI 11/10/2016
  ----------------------------------------------------------------------------
  FUNCTION get_cust_site_use_id (p_orig_syst_addr_ref IN hz_cust_site_uses_all.orig_system_reference%type,
                                 p_org_id             IN hr_all_organization_units.organization_id%type) RETURN hz_cust_site_uses_all.site_use_id%type
  IS
    v_site_use_id   hz_cust_site_uses_all.site_use_id%type;

  BEGIN

    SELECT  SITE_USE_ID
    INTO    v_site_use_id
    FROM    HZ_CUST_SITE_USES_ALL
    WHERE   ORIG_SYSTEM_REFERENCE = p_orig_syst_addr_ref
    AND     ORG_ID = p_org_id;

    RETURN v_site_use_id;

  EXCEPTION
    WHEN OTHERS THEN
      Fnd_File.put_line(Fnd_File.LOG, 'Erreur lors de la récupération de l''id de la fonction du site client référencé : '||p_orig_syst_addr_ref);
      return -1;
  END get_cust_site_use_id;

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
 * p_file_name       Nom du fichier à charger
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
        b_result                  BOOLEAN;

  BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Launch_Loader');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                                         'Lancement de chargement du fichier dans la table d''interface spécifique : ');

        fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT, 'CHARGEMENT DU FICHIER :');
        fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
        ------------------------------------------------------
        -- Lancement du traitement de chargement du fichier --
        ------------------------------------------------------
        -- Positionnement des options d'impression
        b_result := fnd_request.set_print_options(printer => gv_printer,
                                                  copies => g_number_of_copies);
        -- Lancement du traitement
        g_loader_request_id         := Fnd_Request.submit_request (
                                                                   'DKA'                            -- APPL
                                                                  ,'DKA_LOADER_DKA_REPARFACTIMP'    -- PROG
                                                                  ,NULL                             -- PROGRAM_NAME
                                                                  ,NULL                             -- START
                                                                  ,FALSE                            -- SUB_REQUEST
                                                                  );

        IF g_loader_request_id = 0
        THEN
            p_retcode    := 2;
            fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de chargement du fichier a échoué' || CHR(10) ||
                                            'PROGRAMME  : DKA_LOADER_DKA_REPARFACTIMP'
                                            );
            Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de chargement du fichier a échoué');
        ELSE
            COMMIT;
            Fnd_File.put_line(Fnd_File.LOG, '=> LOAD REQUEST ID= ' || g_loader_request_id);
            Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement de chargement du fichier : ' || g_loader_request_id);

            -- Attente de la fin du traitement
            IF NOT (Fnd_Concurrent.wait_for_request (g_loader_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
            THEN
                p_Errbuf  := v_Message;
                Fnd_file.put_line(Fnd_file.log, 'ERREUR : Attente de la fin du programme de chargement du fichier dépassée : Fin du traitement' || CHR(10) ||
                                                'MESSAGE : ' || v_Message || CHR(10) );
            END IF;

            IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL')
            THEN
                Fnd_File.put_line(Fnd_File.LOG, 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
                Fnd_File.put_line(Fnd_File.OUTPUT, '. Statut de fin : ' || v_phase || '/' || v_status);
                
                UPDATE  DKA_ENTETE_LIGNES_FACTURE_TMP
                SET     LOAD_REQUEST_ID = g_loader_request_id
                WHERE   LOAD_REQUEST_ID IS NULL;

                SELECT  count(1)
                INTO    g_summary.loaded_header_fact_rows
                FROM    DKA_ENTETE_LIGNES_FACTURE_TMP
                WHERE   LOAD_REQUEST_ID = g_loader_request_id
                ;

                UPDATE  DKA_DISTRIBUTIONS_FACTURE_TMP
                SET     LOAD_REQUEST_ID = g_loader_request_id
                WHERE   LOAD_REQUEST_ID IS NULL;         

                SELECT  count(1)
                INTO    g_summary.loaded_distrib_rows
                FROM    DKA_DISTRIBUTIONS_FACTURE_TMP
                WHERE   LOAD_REQUEST_ID = g_loader_request_id
                ;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
            THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement de chargement en warning '|| g_loader_request_id);
                p_retcode    := 1;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')
            THEN
                p_retcode := 2;
                p_Errbuf  := 'ERREUR : Fin anormale du traitement de chargement : '||v_Message;

                fnd_file.put_line(fnd_file.LOG, 'ERREUR : Fin anormale du traitement de chargement '|| g_loader_request_id  || CHR(10) ||
                                                'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                                'MESSAGE : ' || v_message || CHR(10) );
                Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement de chargement '||g_loader_request_id);
            END IF;

        END IF;


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
  PROCEDURE validate_data(  p_Errbuf            OUT VARCHAR2,
                            p_retcode           OUT NUMBER
                          )
  IS
    v_flag_erreur_entete_facture      BOOLEAN := FALSE;
    v_flag_erreur_lignes_facture      BOOLEAN := FALSE;
    v_flag_erreur_distrib_facture     BOOLEAN := FALSE;

    v_message                         VARCHAR2 (500);

    v_exist                           NUMBER;

    -- Variable en tete transaction
    v_region                          VARCHAR2(30);
    v_org_id                          VARCHAR2(240);
    v_type_mvt                        VARCHAR2(100);
    v_type_mvt_class                  VARCHAR2(100);
    v_type_mvt_sign                   VARCHAR2(100);
    v_term_name                       VARCHAR2(100);
    v_bill_to_address                 VARCHAR2(100);
    v_total_amount                    NUMBER;
    v_total_dist_amount               NUMBER;
    v_task_code                       VARCHAR2(100);
    v_project_code                    VARCHAR2(100);
    v_task_id                         NUMBER;
    v_project_id                      NUMBER;

    -- Variable lignes transaction
    v_code_tva                        VARCHAR2(100);
    v_tax_rate                        VARCHAR2(100);
    v_tax_regime_code                 VARCHAR2(100);
    v_tax                             VARCHAR2(100);
    v_tax_status_code                 VARCHAR2(100);
    v_taxe_jurisdiction_code          VARCHAR2(100);
    v_tax_rate_code                   VARCHAR2(100);
    v_tax_code                        VARCHAR2(100);
    v_extended_amount                 NUMBER;

    -- Variable distrib transaction
    v_segment1_new                    VARCHAR2(100);
    v_segment2_new                    VARCHAR2(100);
    v_segment3_new                    VARCHAR2(100);
    v_segment4_new                    VARCHAR2(100);
    v_segment5_new                    VARCHAR2(100);
    v_segment6_new                    VARCHAR2(100);
    v_segment7_new                    VARCHAR2(100);
    v_segment8_new                    VARCHAR2(100);
    v_segment9_new                    VARCHAR2(100);
    v_segment10_new                   VARCHAR2(100);
    v_segment11_new                   VARCHAR2(100);
    v_segment12_new                   VARCHAR2(100);
    v_dist_amount                     NUMBER;

    CURSOR cur_headers IS
      SELECT  DISTINCT
              TRX_ID, --< v1.5 - artf204018
              TRX_NUMBER,
              SOCIETE,
              CENTRE_DE_GESTION,
              TYPE,
              TRX_TYPE,
              TERM_NAME,
              BILL_TO_ADDRESS,
              ACCTD_AMOUNT_DUE_REMAINING TRX_AMOUNT,
              TRX_AMOUNT ORIGINAL_AMOUNT--< 1.5 - artf2040317
              ,HEADER_ATTRIBUTE10 --<artf2108451
      FROM    DKA_ENTETE_LIGNES_FACTURE_TMP
      WHERE   LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
      AND     FLAG = 'N'
      --< v1.5 - artf204018
      --ORDER BY TRX_NUMBER
      ORDER BY TRX_ID
      --> v1.5 - artf204018
      ;

    --< v1.5 - artf204018
    --CURSOR cur_lignes_fact (P_TRX_NUMBER          VARCHAR2,
    --                        P_SOCIETE             VARCHAR2,
    --                        P_CENTRE_DE_GESTION   VARCHAR2
    --                        ) IS
    CURSOR cur_lignes_fact (P_TRX_ID                NUMBER
                            ) IS
    --> v1.5 - artf204018
      SELECT  *
      FROM    DKA_ENTETE_LIGNES_FACTURE_TMP
      WHERE   LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
      AND     FLAG = 'N'
      --< v1.5 - artf204018
      --AND     TRX_NUMBER          = P_TRX_NUMBER
      --AND     SOCIETE             = P_SOCIETE
      --AND     CENTRE_DE_GESTION   = P_CENTRE_DE_GESTION
      AND     TRX_ID              = P_TRX_ID
      --ORDER BY TRX_NUMBER, LINE_NUMBER
      ORDER BY TRX_ID, LINE_NUMBER
      --> v1.5 - artf204018
      FOR UPDATE OF  FLAG
                    ,ORG_ID
                    ,NEW_TAX_REGIME_CODE
                    ,NEW_TAX
                    ,NEW_TAX_STATUS_CODE
                    ,NEW_TAXE_JURISDICTION_CODE
                    ,NEW_TAX_RATE_CODE
                    ,NEW_TRX_TYPE
                    ,NEW_TERMS
      ;

    --< v1.5 - artf204018
    --CURSOR cur_distrib_fact (P_TRX_NUMBER          VARCHAR2,
    --                         P_SOCIETE             VARCHAR2,
    --                         P_CENTRE_DE_GESTION   VARCHAR2,
    --                         P_LINE_NUMBER         NUMBER
    --                         ) IS
    CURSOR cur_distrib_fact (P_TRX_ID               NUMBER,
                             P_LINE_NUMBER         NUMBER
                             ) IS
    --> v1.5 - artf204018
    SELECT  *
      FROM    DKA_DISTRIBUTIONS_FACTURE_TMP
      WHERE   LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
      AND     FLAG                = 'N'
      --< v1.5 - artf204018
      --AND     TRX_NUMBER          = P_TRX_NUMBER
      --AND     DIST_ACCT1          = P_SOCIETE
      --AND     DIST_ACCT2          = P_CENTRE_DE_GESTION
      AND     TRX_ID              = P_TRX_ID
      AND     NVL(LINE_NUMBER, 1) = P_LINE_NUMBER
      --ORDER BY TRX_NUMBER, NVL(LINE_NUMBER, 0)
      ORDER BY TRX_ID, NVL(LINE_NUMBER, 0)
      --> v1.5 - artf204018
      FOR UPDATE OF  FLAG
                    ,ORG_ID
                    ,SEGMENT1_NEW
                    ,SEGMENT2_NEW
                    ,SEGMENT3_NEW
                    ,SEGMENT4_NEW
                    ,SEGMENT5_NEW
                    ,SEGMENT6_NEW
                    ,SEGMENT7_NEW
                    ,SEGMENT8_NEW
                    ,SEGMENT9_NEW
                    ,SEGMENT10_NEW
                    ,SEGMENT11_NEW
                    ,SEGMENT12_NEW
      ;

  BEGIN
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_data');
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Validation des données dans les tables spécifiques : ');

    -----------------------
    -- Valider le detail des en tete de facture
    -----------------------
    FOR rec_cur_headers IN cur_headers LOOP
      -- Initialiser les variables
      v_flag_erreur_entete_facture  := FALSE;
      v_region                      := NULL;
      v_bill_to_address             := NULL;
      v_org_id                      := NULL;
      v_type_mvt                    := NULL;
      v_term_name                   := NULL;
      v_total_amount                := rec_cur_headers.TRX_AMOUNT;
      v_total_dist_amount           := rec_cur_headers.TRX_AMOUNT;

      -- Transcodification du site client
      --RBE artf2205811
      /*dka_rep_transco_pkg.get_transco(  pv_transco_name => '008_REGIONS',
                                        pv_column_01    => substr(rec_cur_headers.BILL_TO_ADDRESS, 1, 3),
                                        pv_out_01       => v_bill_to_address);

      v_bill_to_address := v_bill_to_address || substr(rec_cur_headers.BILL_TO_ADDRESS, 4);*/

      --< 1.5 - artf2040317
      -- Controle des surlettrage
      IF sign(rec_cur_headers.TRX_AMOUNT) <> sign(rec_cur_headers.ORIGINAL_AMOUNT)
         or abs(rec_cur_headers.TRX_AMOUNT) > abs(rec_cur_headers.ORIGINAL_AMOUNT) THEN
        v_flag_erreur_entete_facture:= TRUE;
        v_message := 'Solde incohérent : Montant initial = '||rec_cur_headers.ORIGINAL_AMOUNT||' / Montan restant = '||rec_cur_headers.TRX_AMOUNT;

        Add_Message(rec_cur_headers.TRX_NUMBER, rec_cur_headers.SOCIETE, rec_cur_headers.CENTRE_DE_GESTION, 1, v_message);      
        
        dka_tools_pkg.ins_prog_message(g_request_id,
                               'DKA_REPARFACTIMP',
                               'ETL',
                               'DKA_ENTETE_FACTURE_TMP',
                               rec_cur_headers.TRX_ID,
                               'TRX_AMOUNT',
                               rec_cur_headers.TRX_NUMBER,
                               'E',
                               v_message);
      END IF;
      --> 1.5 - artf2040317
      
      -- Transcodification de la région
      dka_rep_transco_pkg.get_transco(  pv_transco_name => '008_REGIONS',
                                        pv_column_01    => rec_cur_headers.CENTRE_DE_GESTION,
                                        pv_out_01       => v_region);

      --RBE artf2205811
      v_bill_to_address := v_region || substr(rec_cur_headers.BILL_TO_ADDRESS, 4);
      
      -- Récupération de l'org id
      v_org_id := get_organization_id(rec_cur_headers.SOCIETE, v_region);

      IF v_org_id IS NULL THEN
        v_flag_erreur_entete_facture:= TRUE;
        v_message := 'Erreur de récuperation de ORG_ID';

        Add_Message(rec_cur_headers.TRX_NUMBER, rec_cur_headers.SOCIETE, rec_cur_headers.CENTRE_DE_GESTION, 1, v_message||' '||v_region);
        
        dka_tools_pkg.ins_prog_message(g_request_id,
                               'DKA_REPARFACTIMP',
                               'ETL',
                               'DKA_ENTETE_FACTURE_TMP',
                               rec_cur_headers.TRX_ID,
                               'OPERATING_UNIT',
                               v_region||rec_cur_headers.SOCIETE,
                               'E',
                               v_message);
      ELSE
        -- Controle du paramétrage de la Source
        BEGIN
          SELECT  1
          INTO    v_exist
          FROM    RA_BATCH_SOURCES_ALL
          WHERE   1 = 1
          AND     NAME   = g_source_name
          AND     ORG_ID = v_org_id;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_flag_erreur_entete_facture:= TRUE;
            v_message := 'Erreur de récuperation de la source';

            Add_Message(rec_cur_headers.TRX_NUMBER, rec_cur_headers.SOCIETE, rec_cur_headers.CENTRE_DE_GESTION, 1, v_message||' '||g_source_name);
            
            dka_tools_pkg.ins_prog_message(g_request_id,
                                   'DKA_REPARFACTIMP',
                                   'ETL',
                                   'DKA_ENTETE_FACTURE_TMP',
                                   rec_cur_headers.TRX_ID,
                                   'BATCH_SOURCE',
                                   g_source_name,
                                   'E',
                                   v_message);            
        END;

        -- Controle du paramétrage du Type de mouvement
        BEGIN
          dka_rep_transco_pkg.get_transco(  pv_transco_name => '001_AR_TYPE_MOUVEMENT',
                                            pv_column_01    => rec_cur_headers.TRX_TYPE,
                                            pv_out_01       => v_type_mvt);

          SELECT  TYPE, 
                  CREATION_SIGN
          INTO    v_type_mvt_class,
                  v_type_mvt_sign
          FROM    RA_CUST_TRX_TYPES_ALL
          WHERE   1 = 1
          AND     NAME   = v_type_mvt
          AND     ORG_ID = v_org_id;
          
          --< artf2104891
          IF v_type_mvt_sign = 'P' AND sign(rec_cur_headers.TRX_AMOUNT) = -1 THEN
            v_type_mvt := REPLACE(v_type_mvt, 'FACTURE', 'AVOIR');
          
            SELECT  TYPE, 
                    CREATION_SIGN
            INTO    v_type_mvt_class,
                    v_type_mvt_sign
            FROM    RA_CUST_TRX_TYPES_ALL
            WHERE   1 = 1
            AND     NAME   = v_type_mvt
            AND     ORG_ID = v_org_id;             
            
          ELSIF v_type_mvt_sign = 'N' AND sign(rec_cur_headers.TRX_AMOUNT) = 1 THEN
            v_type_mvt := REPLACE(v_type_mvt, 'AVOIR', 'FACTURE');
            
            SELECT  TYPE, 
                    CREATION_SIGN
            INTO    v_type_mvt_class,
                    v_type_mvt_sign
            FROM    RA_CUST_TRX_TYPES_ALL
            WHERE   1 = 1
            AND     NAME   = v_type_mvt
            AND     ORG_ID = v_org_id;        
          END IF;          
          --> artf2104891
        EXCEPTION
          WHEN OTHERS THEN
            v_type_mvt_class := NULL;
            v_type_mvt_sign := NULL;
          
            v_flag_erreur_entete_facture:= TRUE;
            v_message := 'Erreur de recupération du type de mouvement';

            Add_Message(rec_cur_headers.TRX_NUMBER, rec_cur_headers.SOCIETE, rec_cur_headers.CENTRE_DE_GESTION, 1, v_message||' '||v_type_mvt);
            
            dka_tools_pkg.ins_prog_message(g_request_id,
                                   'DKA_REPARFACTIMP',
                                   'ETL',
                                   'DKA_ENTETE_FACTURE_TMP',
                                   rec_cur_headers.TRX_ID,
                                   'TRX_TYPE',
                                   rec_cur_headers.TRX_TYPE,
                                   'E',
                                   v_message);                 
        END;
      END IF;

      -- Controle du paramétrage des Conditions de reglements
      IF v_type_mvt_class = 'INV' AND rec_cur_headers.TERM_NAME IS NULL THEN
        rec_cur_headers.TERM_NAME := 'A_ECHEANCE';
      END IF;
      
      --IF rec_cur_headers.TYPE <> 'CM' THEN
      IF v_type_mvt_class <> 'CM' THEN
        BEGIN
          dka_rep_transco_pkg.get_transco(  pv_transco_name => '020_CONDITIONS_RGLT',
                                            pv_column_01    => rec_cur_headers.TERM_NAME,
                                            pv_out_01       => v_term_name);

          SELECT  1
          INTO    v_exist
          FROM    RA_TERMS_VL
          WHERE   1 = 1
          AND     NAME   = v_term_name;
        EXCEPTION
          WHEN OTHERS THEN
            v_flag_erreur_entete_facture:= TRUE;
            v_message := 'Erreur de recupération de condition de règlement';

            Add_Message(rec_cur_headers.TRX_NUMBER, rec_cur_headers.SOCIETE, rec_cur_headers.CENTRE_DE_GESTION, 1, v_message||' '||v_term_name);

            dka_tools_pkg.ins_prog_message(g_request_id,
                                   'DKA_REPARFACTIMP',
                                   'ETL',
                                   'DKA_ENTETE_FACTURE_TMP',
                                   rec_cur_headers.TRX_ID,
                                   'TERM_NAME',
                                   rec_cur_headers.TERM_NAME,
                                   'E',
                                   v_message);              
        END;
      END IF;

      --< artf2108451
      IF rec_cur_headers.HEADER_ATTRIBUTE10 IS NOT NULL THEN     
        BEGIN
          dka_rep_transco_pkg.get_transco(  pv_transco_name => '014_PROJETS',
                                            pv_column_01    => rec_cur_headers.HEADER_ATTRIBUTE10,
                                            pv_out_01       => v_project_code,
                                            pv_out_02       => v_task_code);

          SELECT  pp.PROJECT_ID,
                  pt.TASK_ID
          INTO    v_project_id,
                  v_task_id
          FROM    PA_PROJECTS_ALL pp,
                  PA_TASKS pt
          WHERE   1 = 1
          AND     pp.PROJECT_ID = pt.PROJECT_ID
          AND     pp.SEGMENT1 = v_project_code
          AND     pt.TASK_NUMBER = v_task_code;
        EXCEPTION
          WHEN OTHERS THEN
            v_flag_erreur_entete_facture:= TRUE;
            v_message := 'Erreur dans le mapping du projet majoritaire';

            Add_Message(rec_cur_headers.TRX_NUMBER, rec_cur_headers.SOCIETE, rec_cur_headers.CENTRE_DE_GESTION, 1, v_message||' '||rec_cur_headers.HEADER_ATTRIBUTE10);

            dka_tools_pkg.ins_prog_message(g_request_id,
                                   'DKA_REPARFACTIMP',
                                   'ETL',
                                   'DKA_ENTETE_FACTURE_TMP',
                                   rec_cur_headers.TRX_ID,
                                   'HEADER_ATTRIBUTE10',
                                   rec_cur_headers.HEADER_ATTRIBUTE10,
                                   'E',
                                   v_message);              
        END;
      END IF;     
      --> artf2108451
      
      -----------------------
      -- Valider le detail des lignes de facture
      -----------------------
      --< v1.5 - artf204018
      --FOR rec_cur_lignes_fact IN cur_lignes_fact(rec_cur_headers.TRX_NUMBER,
      --                                           rec_cur_headers.SOCIETE,
      --                                           rec_cur_headers.CENTRE_DE_GESTION)
      FOR rec_cur_lignes_fact IN cur_lignes_fact(rec_cur_headers.TRX_ID)
      --> v1.5 - artf204018
      LOOP
        -- Initialiser les variables
        v_flag_erreur_lignes_facture  := FALSE;
        v_code_tva                    := NULL;
        v_tax_rate                    := NULL;
        v_tax_regime_code             := NULL;
        v_tax                         := NULL;
        v_tax_status_code             := NULL;
        v_taxe_jurisdiction_code      := NULL;
        v_tax_rate_code               := NULL;
        v_tax_code                    := NULL;
        v_extended_amount             := 0;

        -- Code TVA
        IF rec_cur_lignes_fact.CODE_TVA IS NOT NULL THEN
          BEGIN
            dka_rep_transco_pkg.get_transco( pv_transco_name  => '004_CODE_TVA',
                                             pv_column_01     => rec_cur_lignes_fact.CODE_TVA,
                                             pv_out_01        => v_code_tva);

            SELECT  PERCENTAGE_RATE,
                    TAX_REGIME_CODE,
                    TAX,
                    TAX_STATUS_CODE,
                    TAX_JURISDICTION_CODE,
                    TAX_RATE_CODE,
                    TAX_RATE_CODE
            INTO    v_tax_rate,
                    v_tax_regime_code,
                    v_tax,
                    v_tax_status_code,
                    v_taxe_jurisdiction_code,
                    v_tax_rate_code,
                    v_tax_code
            FROM    ZX_RATES_VL
            WHERE   TAX_RATE_CODE = v_code_tva;

            IF rec_cur_lignes_fact.LINE_TYPE <> 'TAX' THEN
              v_tax_rate                    := NULL;
              v_tax_regime_code             := NULL;
              v_tax                         := NULL;
              v_tax_status_code             := NULL;
              v_taxe_jurisdiction_code      := NULL;
              v_tax_rate_code               := NULL;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
              v_flag_erreur_lignes_facture:= TRUE;
              v_message := 'Erreur de recupération du code TVA';

              Add_Message(rec_cur_lignes_fact.TRX_NUMBER, rec_cur_lignes_fact.SOCIETE, rec_cur_lignes_fact.CENTRE_DE_GESTION, rec_cur_lignes_fact.LINE_NUMBER, v_message||' '||v_code_tva);
              
              dka_tools_pkg.ins_prog_message(g_request_id,
                                     'DKA_REPARFACTIMP',
                                     'ETL',
                                     'DKA_LIGNES_FACTURE_TMP',
                                     rec_cur_headers.TRX_ID||'-'||rec_cur_lignes_fact.LINE_NUMBER,
                                     'CODE_TVA',
                                     rec_cur_lignes_fact.CODE_TVA,
                                     'E',
                                     v_message);                     
          END;
        END IF;

        -- Calcul du montant de la ligne
        v_extended_amount := round(rec_cur_lignes_fact.EXTENDED_AMOUNT * (rec_cur_lignes_fact.ACCTD_AMOUNT_DUE_REMAINING / rec_cur_lignes_fact.TRX_AMOUNT), 2);
        v_total_amount := v_total_amount - v_extended_amount;

        -----------------------
        -- Valider le detail des distributions de facture
        -----------------------
        --< v1.5 - artf204018
        --FOR rec_cur_distrib_fact IN cur_distrib_fact (rec_cur_lignes_fact.TRX_NUMBER,
        --                                              rec_cur_lignes_fact.SOCIETE,
        --                                              rec_cur_lignes_fact.CENTRE_DE_GESTION,
        --                                              rec_cur_lignes_fact.LINE_NUMBER)
        FOR rec_cur_distrib_fact IN cur_distrib_fact (rec_cur_lignes_fact.TRX_ID,
                                                      rec_cur_lignes_fact.LINE_NUMBER)
        --> v1.5 - artf204018
        LOOP
          -- Initialiser les variables
          v_flag_erreur_distrib_facture := FALSE;
          v_segment1_new                := NULL;
          v_segment2_new                := NULL;
          v_segment3_new                := NULL;
          v_segment4_new                := NULL;
          v_segment5_new                := NULL;
          v_segment6_new                := NULL;
          v_segment7_new                := NULL;
          v_segment8_new                := NULL;
          v_segment9_new                := NULL;
          v_segment10_new               := NULL;
          v_segment11_new               := NULL;
          v_segment12_new               := NULL;
          v_dist_amount                 := 0;

          -- transo des segments
          BEGIN
            DKA_REP_TRANSCO_PKG.get_cle_transco( rec_cur_distrib_fact.DIST_ACCT1
                                                ,rec_cur_distrib_fact.DIST_ACCT2
                                                ,rec_cur_distrib_fact.DIST_ACCT3
                                                ,rec_cur_distrib_fact.DIST_ACCT4
                                                ,rec_cur_distrib_fact.DIST_ACCT5
                                                ,rec_cur_distrib_fact.DIST_ACCT6
                                                ,rec_cur_distrib_fact.DIST_ACCT7
                                                ,rec_cur_distrib_fact.DIST_ACCT8
                                                ,rec_cur_distrib_fact.DIST_ACCT9
                                                --,rec_cur_distrib_fact.DIST_ACCT10
                                                ,v_segment1_new
                                                ,v_segment2_new
                                                ,v_segment3_new
                                                ,v_segment4_new
                                                ,v_segment5_new
                                                ,v_segment6_new
                                                ,v_segment7_new
                                                ,v_segment8_new
                                                ,v_segment9_new
                                                ,v_segment10_new
                                                ,v_segment11_new
                                                ,v_segment12_new
                                                );
          EXCEPTION
            WHEN OTHERS THEN
              v_flag_erreur_distrib_facture := TRUE;
              v_message := 'Erreur de recupération de transco des segments ';

              Add_Message(rec_cur_lignes_fact.TRX_NUMBER,rec_cur_lignes_fact.SOCIETE,rec_cur_lignes_fact.CENTRE_DE_GESTION,rec_cur_lignes_fact.LINE_NUMBER,v_message);
              
              dka_tools_pkg.ins_prog_message(g_request_id,
                                     'DKA_REPARFACTIMP',
                                     'ETL',
                                     'DKA_DISTRIBUTIONS_FACTURE_TMP',
                                     rec_cur_headers.TRX_ID||'-'||rec_cur_lignes_fact.LINE_NUMBER||'-'||rec_cur_distrib_fact.ACCOUNT_CLASS,
                                     'DIST_ACCT',
                                     substr(rec_cur_distrib_fact.DIST_ACCT3||'.'||rec_cur_distrib_fact.DIST_ACCT4||'.'||rec_cur_distrib_fact.DIST_ACCT5||'.'||rec_cur_distrib_fact.DIST_ACCT6||'.'||rec_cur_distrib_fact.DIST_ACCT7||'.'||rec_cur_distrib_fact.DIST_ACCT8||'.'||rec_cur_distrib_fact.DIST_ACCT9, 1, 30),
                                     'E',
                                     v_message);                  
          END;

          IF rec_cur_distrib_fact.ACCOUNT_CLASS IN ('REV', 'CM')  THEN
            v_SEGMENT3_NEW := 'REPRIS';
            v_SEGMENT4_NEW := '0';
            v_SEGMENT5_NEW := '0';
            v_SEGMENT6_NEW := '0';
            v_SEGMENT7_NEW := '0';
            v_SEGMENT8_NEW := '0';
            v_SEGMENT9_NEW := '0';
          END IF;

          -- Calcul du montant de la distibution
          IF rec_cur_distrib_fact.ACCOUNT_CLASS = 'REC' THEN
            v_dist_amount := rec_cur_lignes_fact.ACCTD_AMOUNT_DUE_REMAINING;
          ELSE
            v_dist_amount := round(rec_cur_distrib_fact.DIST_AMOUNT * (rec_cur_lignes_fact.ACCTD_AMOUNT_DUE_REMAINING / rec_cur_lignes_fact.TRX_AMOUNT), 2);
            v_total_dist_amount := v_total_dist_amount - v_dist_amount;
          END IF;

          UPDATE DKA_DISTRIBUTIONS_FACTURE_TMP
          SET   FLAG            = 'S'
               ,ORG_ID          = v_org_id
               ,DIST_AMOUNT_NEW = v_dist_amount
               ,SEGMENT1_NEW    = v_segment1_new
               ,SEGMENT2_NEW    = v_segment2_new
               ,SEGMENT3_NEW    = v_segment3_new
               ,SEGMENT4_NEW    = v_segment4_new
               ,SEGMENT5_NEW    = v_segment5_new
               ,SEGMENT6_NEW    = v_segment6_new
               ,SEGMENT7_NEW    = v_segment7_new
               ,SEGMENT8_NEW    = v_segment8_new
               ,SEGMENT9_NEW    = v_segment9_new
               ,SEGMENT10_NEW   = v_segment10_new
               ,SEGMENT11_NEW   = v_segment11_new
               ,SEGMENT12_NEW   = v_segment12_new
          WHERE  CURRENT OF cur_distrib_fact;

          IF v_flag_erreur_distrib_facture or v_flag_erreur_lignes_facture OR v_flag_erreur_entete_facture THEN
            UPDATE DKA_DISTRIBUTIONS_FACTURE_TMP
            SET   FLAG          = 'E'
            WHERE  CURRENT OF cur_distrib_fact;
          END IF;
        END LOOP; --<<< Fin cur_distrib_fact

        UPDATE DKA_ENTETE_LIGNES_FACTURE_TMP
        SET    FLAG                       = 'S'
              ,LINK_TO_LINE               = REPLACE(LINK_TO_LINE, CHR(13), '')
              ,ORG_ID                     = v_org_id
              ,NEW_TRX_TYPE               = v_type_mvt
              ,NEW_TERMS                  = v_term_name
              ,NEW_BILL_TO_ADDRESS        = v_bill_to_address
              ,NEW_TAX_REGIME_CODE        = v_tax_regime_code
              ,NEW_TAX                    = v_tax
              ,NEW_TAX_STATUS_CODE        = v_tax_status_code
              ,NEW_TAXE_JURISDICTION_CODE = v_taxe_jurisdiction_code
              ,NEW_TAX_RATE_CODE          = v_tax_rate_code
              ,NEW_TAX_CODE               = v_tax_code
              ,NEW_EXTENDED_AMOUNT        = v_extended_amount
              ,NEW_TASK_ID                = v_task_id
              ,NEW_PROJECT_ID             = v_project_id
        WHERE  CURRENT OF cur_lignes_fact ;

        IF v_flag_erreur_lignes_facture OR v_flag_erreur_entete_facture THEN
          UPDATE DKA_ENTETE_LIGNES_FACTURE_TMP
          SET    FLAG                   = 'E'
          WHERE  CURRENT OF cur_lignes_fact ;
        END IF;
      END LOOP; --<<< Fin cur_lignes_fact

      -- Gestion des arrondis de Prorata
      IF v_total_amount <> 0 THEN
        UPDATE  DKA_ENTETE_LIGNES_FACTURE_TMP
        SET     NEW_EXTENDED_AMOUNT   = NEW_EXTENDED_AMOUNT + v_total_amount
        WHERE   LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
        --< v1.5 - artf204018
        --AND     TRX_NUMBER            = rec_cur_headers.TRX_NUMBER
        --AND     SOCIETE               = rec_cur_headers.SOCIETE
        --AND     CENTRE_DE_GESTION     = rec_cur_headers.CENTRE_DE_GESTION
        AND     TRX_ID                = rec_cur_headers.TRX_ID
        --> v1.5 - artf204018
        AND     LINE_NUMBER           = 1;
      END IF;

      IF v_total_dist_amount <> 0 THEN
        UPDATE  DKA_DISTRIBUTIONS_FACTURE_TMP
        SET     DIST_AMOUNT_NEW       = DIST_AMOUNT_NEW + v_total_dist_amount
        WHERE   LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
        --< v1.5 - artf204018
        --AND     TRX_NUMBER            = rec_cur_headers.TRX_NUMBER
        --AND     DIST_ACCT1            = rec_cur_headers.SOCIETE
        --AND     DIST_ACCT2            = rec_cur_headers.CENTRE_DE_GESTION
        AND     TRX_ID                = rec_cur_headers.TRX_ID
        --> v1.5 - artf204018
        AND     LINE_NUMBER           = 1;
      END IF;
    END LOOP; --<<< Fin cur_entete_fact

    -- En cas erreur dans une ligne de facture - flaguer les autres lignes de la meme factures en erreur
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Exclusion facture avec au moin sune erreur');

    UPDATE DKA_ENTETE_LIGNES_FACTURE_TMP LF
    SET    LF.FLAG  = 'E'
    WHERE  LF.LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
    AND  ( EXISTS ( SELECT  1 
                    FROM    DKA_ENTETE_LIGNES_FACTURE_TMP LF_TEMP
                    WHERE   LF_TEMP.LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
                    --< v1.5 - artf204018
                    --AND     LF_TEMP.TRX_NUMBER        = LF.TRX_NUMBER
                    --AND     LF_TEMP.SOCIETE           = LF.SOCIETE
                    --AND     LF_TEMP.CENTRE_DE_GESTION = LF.CENTRE_DE_GESTION
                    AND     LF_TEMP.TRX_ID            = LF.TRX_ID
                    --> v1.5 - artf204018
                    AND     LF_TEMP.FLAG              = 'E'
                  )
           OR
           EXISTS ( SELECT  1 
                    FROM    DKA_DISTRIBUTIONS_FACTURE_TMP LF_TEMP
                    WHERE   LF_TEMP.LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
                    --< v1.5 - artf204018
                    --AND     LF_TEMP.TRX_NUMBER        = LF.TRX_NUMBER
                    --AND     LF_TEMP.SOCIETE           = LF.DIST_ACCT1
                    --AND     LF_TEMP.CENTRE_DE_GESTION = LF.DIST_ACCT2
                    AND     LF_TEMP.TRX_ID            = LF.TRX_ID
                    --> v1.5 - artf204018
                    AND     LF_TEMP.FLAG              = 'E'
                  )
         );

    --
    UPDATE  DKA_DISTRIBUTIONS_FACTURE_TMP LD
    SET     LD.FLAG  = 'E'
    WHERE   LD.LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
    AND     EXISTS( SELECT  1 
                    FROM    DKA_ENTETE_LIGNES_FACTURE_TMP LF_TEMP
                    WHERE   LF_TEMP.LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
                    --< v1.5 - artf204018
                    --AND LF_TEMP.TRX_NUMBER          = LD.TRX_NUMBER
                    --AND LF_TEMP.DIST_ACCT1          = LD.SOCIETE
                    --AND LF_TEMP.DIST_ACCT2          = LD.CENTRE_DE_GESTION
                    AND LF_TEMP.TRX_ID              = LD.TRX_ID
                    --> v1.5 - artf204018
                    AND LF_TEMP.FLAG    = 'E'
                  );

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_data');

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode   := 2;
      p_errbuf    := 'validate_data : ' ||SQLERRM;
      Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure validate_data : EXCEPTION OTHERS ');
  END validate_data;


 /*
 *************************************************************************
 * PROCEDURE NAME : import_data
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
  PROCEDURE import_data(  p_Errbuf            OUT VARCHAR2,
                          p_retcode           OUT NUMBER
                          )
  IS

    v_interface_line_context          VARCHAR2(100);
    v_interface_line_attribute1       VARCHAR2(100);
    v_interface_line_attribute2       VARCHAR2(100);
    v_interface_line_attribute3       VARCHAR2(100);
    v_interface_line_attribute4       DATE;
    v_interface_line_attribute5       NUMBER;

    v_attribute_category              VARCHAR2(100); --RBE artf2211077
    v_attribute1                      VARCHAR2(100);
    v_attribute2                      VARCHAR2(100);
    v_attribute3                      VARCHAR2(100);
    v_attribute4                      VARCHAR2(100);
    v_attribute5                      VARCHAR2(100);
    v_attribute6                      VARCHAR2(100);
    v_attribute7                      VARCHAR2(100);
    v_attribute8                      VARCHAR2(100);
    v_attribute9                      VARCHAR2(100);
    v_attribute10                     VARCHAR2(100);
    v_attribute11                     VARCHAR2(100);
    v_attribute12                     VARCHAR2(100);
    v_attribute13                     VARCHAR2(100);
    v_attribute14                     VARCHAR2(100);
    v_attribute15                     VARCHAR2(100);
    
    vn_customer_id                    NUMBER;      -- OBE
    vv_exist                          VARCHAR2(1); -- OBE

    -- Pour lignes de factures
    CURSOR cur_lignes_fact IS
      SELECT  *
      FROM    DKA_ENTETE_LIGNES_FACTURE_TMP
      WHERE   LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
      AND     FLAG = 'S'
      --< v1.5 - artf204018
      --ORDER BY ORG_ID, TRX_NUMBER, LINE_NUMBER
      ORDER BY TRX_ID, LINE_NUMBER
      --> v1.5 - artf204018
      FOR UPDATE OF FLAG
    ;

    -- Pour les distributions
    --< v1.5 - artf2040185
    --CURSOR cur_distrib_fact(p_trx_number VARCHAR2, p_org_id NUMBER, p_line_number NUMBER) IS
    CURSOR cur_distrib_fact(p_trx_id NUMBER, p_line_number NUMBER) IS
    --> v1.5 - artf2040185                       
      SELECT  *
      FROM    DKA_DISTRIBUTIONS_FACTURE_TMP
      WHERE   LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
      AND     FLAG = 'S'
      --< v1.5 - artf204018
      --AND     ORG_ID              = p_org_id
      --AND     TRX_NUMBER          = p_trx_number
      AND     TRX_ID              = p_trx_id
      --> v1.5 - artf204018
      AND     NVL(LINE_NUMBER, 1) = p_line_number
      --< v1.5 - artf204018
      --ORDER BY ORG_ID, TRX_NUMBER, 
      ORDER BY TRX_ID, NVL(LINE_NUMBER, 0)
      --> v1.5 - artf204018
      FOR UPDATE OF FLAG;

  BEGIN
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Import_Data');
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Insertion dans les tables Open Interface : ');

    FOR rec_cur_lignes_fact IN cur_lignes_fact LOOP
      -- Initialisation des variables
      v_interface_line_context    := g_source_name;
      v_interface_line_attribute1 := rec_cur_lignes_fact.TRX_TYPE;
      v_interface_line_attribute2 := rec_cur_lignes_fact.SOCIETE;
      v_interface_line_attribute3 := rec_cur_lignes_fact.TRX_NUMBER;
      v_interface_line_attribute4 := rec_cur_lignes_fact.TRX_DATE;
      v_interface_line_attribute5 := rec_cur_lignes_fact.LINE_NUMBER;
      
      /* --RBE  artf2205802
      --< OBE
      BEGIN
        
        SELECT 'Y'
        INTO vv_exist
        FROM ra_customer_trx_all
        WHERE trx_number = rec_cur_lignes_fact.TRX_NUMBER
        AND ROWNUM = 1
        ;
        
        UPDATE  ra_batch_sources_all rbs
        SET     rbs.allow_duplicate_trx_num_flag = 'Y'
        WHERE   rbs.name = g_source_name
        AND     rbs.org_id = rec_cur_lignes_fact.org_id
        ;                
      
      EXCEPTION
        WHEN OTHERS THEN
            NULL;
      END;
      */

      
      BEGIN
      
        SELECT customer_id
        INTO vn_customer_id
        FROM ar_customers
        WHERE customer_number = rec_cur_lignes_fact.BILL_TO_CUSTOMER
        AND ROWNUM = 1
        ;
        
        UPDATE  ra_cust_receipt_methods rcrm
        SET     primary_flag = 'N'
        where   primary_flag = 'Y'
        and     customer_id = vn_customer_id
        ;              
      
      EXCEPTION
        WHEN OTHERS THEN
            NULL;
      END;
      

      --> OBE

      -- Récupération des identifiants du client et de la fonction du site client
      --V_CUST_ACCOUNT_ID := get_cust_acct_id(rec_cur_lignes_fact.BILL_TO_CUSTOMER); -- NSI 11/10/2016
      --V_SITE_USE_ID     := get_cust_site_use_id(rec_cur_lignes_fact.BILL_TO_ADDRESS,rec_cur_lignes_fact.org_id); -- NSI 11/10/2016

      -- Insertion dans la table RA_INTERFACE_LINES_ALL
      INSERT INTO RA_INTERFACE_LINES_ALL
      (  INTERFACE_LINE_CONTEXT
        ,INTERFACE_LINE_ATTRIBUTE1
        ,INTERFACE_LINE_ATTRIBUTE2
        ,INTERFACE_LINE_ATTRIBUTE3
        ,INTERFACE_LINE_ATTRIBUTE4
        ,INTERFACE_LINE_ATTRIBUTE5
        ,LINE_NUMBER
        ,BATCH_SOURCE_NAME
        ,LINE_TYPE
        ,DESCRIPTION
        ,CURRENCY_CODE
        ,AMOUNT
        ,CUST_TRX_TYPE_NAME
        ,TERM_NAME
        ,ORIG_SYSTEM_BILL_CUSTOMER_REF
        ,ORIG_SYSTEM_BILL_ADDRESS_REF
        ,ORIG_SYSTEM_SOLD_CUSTOMER_REF
        ,LINK_TO_LINE_CONTEXT
        ,LINK_TO_LINE_ATTRIBUTE1
        ,LINK_TO_LINE_ATTRIBUTE2
        ,LINK_TO_LINE_ATTRIBUTE3
        ,LINK_TO_LINE_ATTRIBUTE4
        ,LINK_TO_LINE_ATTRIBUTE5
        ,CONVERSION_TYPE
        ,CONVERSION_RATE
        ,TRX_DATE
        ,GL_DATE
        ,TRX_NUMBER
        ,QUANTITY
        ,UNIT_SELLING_PRICE
        ,PRINTING_OPTION
        ,SHIP_DATE_ACTUAL
        ,ATTRIBUTE9
        ,ATTRIBUTE10
        ,HEADER_ATTRIBUTE_CATEGORY
        ,HEADER_ATTRIBUTE1
        ,HEADER_ATTRIBUTE2
        ,HEADER_ATTRIBUTE3
        ,HEADER_ATTRIBUTE4
        ,HEADER_ATTRIBUTE5
        ,HEADER_ATTRIBUTE6
        ,HEADER_ATTRIBUTE7
        ,HEADER_ATTRIBUTE8
        ,HEADER_ATTRIBUTE9
        ,HEADER_ATTRIBUTE10
        ,HEADER_ATTRIBUTE11
        ,HEADER_ATTRIBUTE12
        ,HEADER_ATTRIBUTE13
        ,HEADER_ATTRIBUTE14
        ,HEADER_ATTRIBUTE15
        ,COMMENTS
        ,INTERNAL_NOTES
        ,TAX_EXEMPT_FLAG
        ,TAX_EXEMPT_REASON_CODE --artf2039967
        ,AMOUNT_INCLUDES_TAX_FLAG
        ,TAXABLE_FLAG
        ,CREATED_BY
        ,CREATION_DATE
        ,LAST_UPDATED_BY
        ,LAST_UPDATE_DATE
        ,ORG_ID
        ,TAX_REGIME_CODE
        ,TAX
        ,TAX_STATUS_CODE
        ,TAX_RATE_CODE
        ,TAX_JURISDICTION_CODE
        ,TAX_RATE
        ,TAX_CODE
        --,PAYING_CUSTOMER_ID -- NSI 11/10/2016
        --,PAYING_SITE_USE_ID -- NSI 11/10/2016
      )
      VALUES
      (  v_interface_line_context                                               --INTERFACE_LINE_CONTEXT
         ,v_interface_line_attribute1                                           --INTERFACE_LINE_ATTRIBUTE1
         ,v_interface_line_attribute2                                           --INTERFACE_LINE_ATTRIBUTE2
         ,v_interface_line_attribute3                                           --INTERFACE_LINE_ATTRIBUTE3
         ,v_interface_line_attribute4                                           --INTERFACE_LINE_ATTRIBUTE4
         ,v_interface_line_attribute5                                           --INTERFACE_LINE_ATTRIBUTE5
         ,rec_cur_lignes_fact.LINE_NUMBER                                       --LINE_NUMBER
         ,g_source_name                                                         --BATCH_SOURCE_NAME
         ,CASE WHEN rec_cur_lignes_fact.LINE_TYPE = 'CB'
               THEN 'LINE'
               ELSE rec_cur_lignes_fact.LINE_TYPE
          END                                                                   --LINE_TYPE
         ,CASE WHEN rec_cur_lignes_fact.LINE_TYPE = 'TAX'
               THEN 'Ligne de taxe'
               ELSE rec_cur_lignes_fact.DESCRIPTION
          END                                                                   --DESCRIPTION
         ,rec_cur_lignes_fact.INVOICE_CURRENCY_CODE                             --INVOICE_CURRENCY_CODE
         ,rec_cur_lignes_fact.NEW_EXTENDED_AMOUNT                               --AMOUNT
         ,rec_cur_lignes_fact.NEW_TRX_TYPE                                      --CUST_TRX_TYPE_NAME
         ,rec_cur_lignes_fact.NEW_TERMS                                         --TERM_NAME
         ,rec_cur_lignes_fact.BILL_TO_CUSTOMER                                  --ORIG_SYSTEM_BILL_CUSTOMER_REF
         ,rec_cur_lignes_fact.NEW_BILL_TO_ADDRESS                               --ORIG_SYSTEM_BILL_ADDRESS_REF
         ,rec_cur_lignes_fact.SOLD_TO_CUSTOMER                                  --ORIG_SYSTEM_SOLD_CUSTOMER_REF
         ,CASE WHEN rec_cur_lignes_fact.LINE_TYPE = 'TAX'
               THEN v_interface_line_context
               ELSE NULL
          END                                                                   --LINK_TO_LINE_CONTEXT
         ,CASE WHEN rec_cur_lignes_fact.LINE_TYPE = 'TAX'
               THEN v_interface_line_attribute1
               ELSE NULL
          END                                                                   --LINK_TO_LINE_ATTRIBUTE1
         ,CASE WHEN rec_cur_lignes_fact.LINE_TYPE = 'TAX'
               THEN v_interface_line_attribute2
               ELSE NULL
          END                                                                   --LINK_TO_LINE_ATTRIBUTE2
         ,CASE WHEN rec_cur_lignes_fact.LINE_TYPE = 'TAX'
               THEN v_interface_line_attribute3
               ELSE NULL
          END                                                                   --LINK_TO_LINE_ATTRIBUTE3
         ,CASE WHEN rec_cur_lignes_fact.LINE_TYPE = 'TAX'
               THEN v_interface_line_attribute4
               ELSE NULL
          END                                                                   --LINK_TO_LINE_ATTRIBUTE4
         ,CASE WHEN rec_cur_lignes_fact.LINE_TYPE = 'TAX'
               THEN rec_cur_lignes_fact.LINK_TO_LINE
               ELSE NULL
          END                                                                   --LINK_TO_LINE_ATTRIBUTE5
         ,'User'                                                                --CONVERSION_TYPE
         ,1                                                                     --CONVERSION_RATE
         ,rec_cur_lignes_fact.TRX_DATE                                          --TRX_DATE
         --< V1.6
         --,GREATEST(rec_cur_lignes_fact.GL_DATE, g_gl_date)                      --GL_DATE
         ,CASE WHEN rec_cur_lignes_fact.GL_DATE <= g_gl_date_max
              THEN g_gl_date
              ELSE rec_cur_lignes_fact.GL_DATE
         END                                                                   --GL_DATE
         --> V1.6
         ,rec_cur_lignes_fact.TRX_NUMBER                                        --TRX_NUMBER
         ,CASE WHEN rec_cur_lignes_fact.LINE_TYPE = 'TAX'
               THEN NULL
               ELSE 1
          END                                                                   --QUANTITY
         ,CASE WHEN rec_cur_lignes_fact.LINE_TYPE = 'TAX'
               THEN NULL
               ELSE rec_cur_lignes_fact.NEW_EXTENDED_AMOUNT
          END                                                                   --UNIT_SELLING_PRICE
         ,rec_cur_lignes_fact.PRINTING_OPTION                                   --PRINTING_OPTION
         ,rec_cur_lignes_fact.TERM_DUE_DATE                                     --SHIP_DATE_ACTUAL
         ,rec_cur_lignes_fact.LINE_ATTRIBUTE9                                   --ATTRIBUTE9
         ,rec_cur_lignes_fact.LINE_ATTRIBUTE10                                  --ATTRIBUTE10
         ,rec_cur_lignes_fact.HEADER_ATTRIBUTE_CATEGORY                         --HEADER_ATTRIBUTE_CATEGORY
         ,rec_cur_lignes_fact.HEADER_ATTRIBUTE1                                 --HEADER_ATTRIBUTE1
         ,rec_cur_lignes_fact.HEADER_ATTRIBUTE2                                 --HEADER_ATTRIBUTE2
         ,rec_cur_lignes_fact.HEADER_ATTRIBUTE3                                 --HEADER_ATTRIBUTE3
         ,rec_cur_lignes_fact.HEADER_ATTRIBUTE4                                 --HEADER_ATTRIBUTE4
         --< artf2108451
         --,rec_cur_lignes_fact.HEADER_ATTRIBUTE5                                 --HEADER_ATTRIBUTE5
         --,rec_cur_lignes_fact.HEADER_ATTRIBUTE6                                 --HEADER_ATTRIBUTE6
         --,rec_cur_lignes_fact.HEADER_ATTRIBUTE7                                 --HEADER_ATTRIBUTE7
         ,NULL                                                                  --HEADER_ATTRIBUTE5
         ,NULL                                                                  --HEADER_ATTRIBUTE6
         ,NULL                                                                  --HEADER_ATTRIBUTE7
         --> artf2108451
         ,rec_cur_lignes_fact.TRX_AMOUNT                                        --HEADER_ATTRIBUTE8
         --< artf2108451
         --,rec_cur_lignes_fact.HEADER_ATTRIBUTE9                                 --HEADER_ATTRIBUTE9
         --,rec_cur_lignes_fact.HEADER_ATTRIBUTE10                                --HEADER_ATTRIBUTE10
         --,rec_cur_lignes_fact.HEADER_ATTRIBUTE11                                --HEADER_ATTRIBUTE11
         --,rec_cur_lignes_fact.HEADER_ATTRIBUTE12                                --HEADER_ATTRIBUTE12
         --,rec_cur_lignes_fact.HEADER_ATTRIBUTE13                                --HEADER_ATTRIBUTE13
         --,rec_cur_lignes_fact.HEADER_ATTRIBUTE14                                --HEADER_ATTRIBUTE14
         --,rec_cur_lignes_fact.HEADER_ATTRIBUTE15                                --HEADER_ATTRIBUTE15
         ,NULL                                                                  --HEADER_ATTRIBUTE9
         ,rec_cur_lignes_fact.NEW_TASK_ID                                       --HEADER_ATTRIBUTE10
         ,rec_cur_lignes_fact.NEW_PROJECT_ID                                    --HEADER_ATTRIBUTE11
         ,NULL                                                                  --HEADER_ATTRIBUTE12
         ,NULL                                                                  --HEADER_ATTRIBUTE13
         ,NULL                                                                  --HEADER_ATTRIBUTE14
         ,NULL                                                                  --HEADER_ATTRIBUTE15
         --> artf2108451
         ,rec_cur_lignes_fact.COMMENTS                                          --COMMENTS
         ,rec_cur_lignes_fact.INTERNAL_NOTES                                    --INTERNAL_NOTES
         ,rec_cur_lignes_fact.TAX_EXEMPT_FLAG                                   --TAX_EXEMPT_FLAG
         ,CASE WHEN rec_cur_lignes_fact.TAX_EXEMPT_FLAG = 'E'
               THEN 'REPRISE'
               ELSE NULL
          END                                                                   --TAX_EXEMPT_REASON_CODE
         ,CASE WHEN rec_cur_lignes_fact.LINE_TYPE = 'TAX'
               THEN NULL
               ELSE rec_cur_lignes_fact.AMOUNT_INCLUDES_TAX_FLAG
          END                                                                   --AMOUNT_INCLUDES_TAX_FLAG
         ,CASE WHEN rec_cur_lignes_fact.LINE_TYPE = 'TAX'
               THEN NULL
               ELSE 'N'
          END                                                                   --TAXABLE_FLAG
         ,g_user_id                                                             --CREATED_BY
         ,SYSDATE                                                               --CREATION_DATE
         ,g_user_id                                                             --LAST_UPDATED_BY
         ,SYSDATE                                                               --LAST_UPDATE_DATE
         ,rec_cur_lignes_fact.ORG_ID                                            --ORG_ID
         ,rec_cur_lignes_fact.NEW_TAX_REGIME_CODE                               --TAX_REGIME_CODE
         ,rec_cur_lignes_fact.NEW_TAX                                           --TAX
         ,rec_cur_lignes_fact.NEW_TAX_STATUS_CODE                               --TAX_STATUS_CODE
         ,rec_cur_lignes_fact.NEW_TAX_RATE_CODE                                 --TAX_RATE_CODE
         ,rec_cur_lignes_fact.NEW_TAXE_JURISDICTION_CODE                        --TAX_JURISDICTION_CODE
         ,DECODE(rec_cur_lignes_fact.NEW_TAX_CODE,NULL,rec_cur_lignes_fact.TAX_RATE,NULL)                                          --TAX_RATE --RBE artf2205817 
         ,rec_cur_lignes_fact.NEW_TAX_CODE                                      --TAX_CODE
         --,V_CUST_ACCOUNT_ID -- NSI 11/10/2016
         --,V_SITE_USE_ID     -- NSI 11/10/2016
        );

      g_summary.inserted_header_fact_rows := g_summary.inserted_header_fact_rows + 1;

      --< v1.5 - artf2040185
      --FOR rec_cur_distrib_fact IN cur_distrib_fact(rec_cur_lignes_fact.TRX_NUMBER, 
      --                                             rec_cur_lignes_fact.ORG_ID, 
      --                                             rec_cur_lignes_fact.LINE_NUMBER ) 
      FOR rec_cur_distrib_fact IN cur_distrib_fact(rec_cur_lignes_fact.TRX_ID, 
                                                   rec_cur_lignes_fact.LINE_NUMBER)
      LOOP
      --> v1.5 - artf2040185
        -- Initialisation des variables
        v_attribute_category := NULL; --RBE artf2211077
        v_attribute1  := NULL;
        v_attribute2  := NULL;
        v_attribute3  := NULL;
        v_attribute4  := NULL;
        v_attribute5  := NULL;
        v_attribute6  := NULL;
        v_attribute7  := NULL;
        v_attribute8  := NULL;
        v_attribute9  := NULL;
        v_attribute10 := NULL;
        v_attribute11 := NULL;
        v_attribute12 := NULL;
        v_attribute13 := NULL;
        v_attribute14 := NULL;
        v_attribute15 := NULL;

        IF rec_cur_distrib_fact.ACCOUNT_CLASS LIKE 'REV'  THEN
          --v_attribute1  := rec_cur_distrib_fact.DIST_ATTRIBUTE1;
          --v_attribute2  := rec_cur_distrib_fact.DIST_ATTRIBUTE2;
          --v_attribute3  := rec_cur_distrib_fact.DIST_ATTRIBUTE3;
          --v_attribute4  := rec_cur_distrib_fact.DIST_ATTRIBUTE4;
          --RBE artf2211077 
          IF rec_cur_distrib_fact.DIST_ATTRIBUTE5 IS NOT NULL THEN
            v_attribute5  := 'REPRISE'; --rec_cur_distrib_fact.DIST_ATTRIBUTE5; --RBE artf2211077 
          END IF;
          --v_attribute6  := rec_cur_distrib_fact.DIST_ATTRIBUTE6;
          --v_attribute7  := rec_cur_distrib_fact.DIST_ATTRIBUTE7;
          --< artf2006694
          --v_attribute8  := rec_cur_distrib_fact.DIST_ATTRIBUTE8;
          --IF rec_cur_distrib_fact.dist_acct3 IN ('467300', '467296') THEN --RBE artf2211077
          IF DKA_AR_TOOLS_PKG.issurtaxeaccount(rec_cur_distrib_fact.dist_acct3 ) = 'TRUE' THEN --RBE artf2211077
            v_attribute8  := rec_cur_distrib_fact.DIST_ACCT5;
            v_attribute_category := 'S'; --RBE artf2211077
          END IF;
          --> artf2006694
          --v_attribute9 := rec_cur_distrib_fact.DIST_ATTRIBUTE9;
          --v_attribute10 := rec_cur_distrib_fact.DIST_ATTRIBUTE10;
          --v_attribute11 := rec_cur_distrib_fact.DIST_ATTRIBUTE11;
          --v_attribute12 := rec_cur_distrib_fact.DIST_ATTRIBUTE14;
          --v_attribute13 := rec_cur_distrib_fact.DIST_ATTRIBUTE13;
          --v_attribute14 := rec_cur_distrib_fact.DIST_ATTRIBUTE14;
          --v_attribute15 := rec_cur_distrib_fact.DIST_ATTRIBUTE15;
        END IF;

        INSERT INTO RA_INTERFACE_DISTRIBUTIONS_ALL
        ( INTERFACE_LINE_CONTEXT
          ,INTERFACE_LINE_ATTRIBUTE1
          ,INTERFACE_LINE_ATTRIBUTE2
          ,INTERFACE_LINE_ATTRIBUTE3
          ,INTERFACE_LINE_ATTRIBUTE4
          ,INTERFACE_LINE_ATTRIBUTE5
          ,ACCOUNT_CLASS
          ,AMOUNT
          ,PERCENT
          ,SEGMENT1
          ,SEGMENT2
          ,SEGMENT3
          ,SEGMENT4
          ,SEGMENT5
          ,SEGMENT6
          ,SEGMENT7
          ,SEGMENT8
          ,SEGMENT9
          ,SEGMENT10
          ,SEGMENT11
          ,SEGMENT12
          ,ATTRIBUTE_CATEGORY
          ,ATTRIBUTE1
          ,ATTRIBUTE2
          ,ATTRIBUTE3
          ,ATTRIBUTE4
          ,ATTRIBUTE5
          ,ATTRIBUTE6
          ,ATTRIBUTE7
          ,ATTRIBUTE8
          ,ATTRIBUTE13
          ,ATTRIBUTE14
          ,ATTRIBUTE15
          ,CREATED_BY
          ,CREATION_DATE
          ,LAST_UPDATED_BY
          ,LAST_UPDATE_DATE
          ,ORG_ID
        )
        VALUES
        (  v_interface_line_context                                             --INTERFACE_LINE_CONTEXT
          ,v_interface_line_attribute1                                          --INTERFACE_LINE_ATTRIBUTE1
          ,v_interface_line_attribute2                                          --INTERFACE_LINE_ATTRIBUTE2
          ,v_interface_line_attribute3                                          --INTERFACE_LINE_ATTRIBUTE3
          ,v_interface_line_attribute4                                          --INTERFACE_LINE_ATTRIBUTE4
          ,v_interface_line_attribute5                                          --INTERFACE_LINE_ATTRIBUTE5
          ,rec_cur_distrib_fact.ACCOUNT_CLASS                                   --ACCOUNT_CLASS
          ,rec_cur_distrib_fact.DIST_AMOUNT_NEW                                 --AMOUNT
          ,rec_cur_distrib_fact.PERCENT                                         --PERCENT
          ,rec_cur_distrib_fact.SEGMENT1_NEW                                    --SEGMENT1
          ,rec_cur_distrib_fact.SEGMENT2_NEW                                    --SEGMENT2
          --< artf2006649
          --,rec_cur_distrib_fact.SEGMENT3_NEW                                    --SEGMENT3
          ,CASE WHEN rec_cur_distrib_fact.DIST_ACCT3 IN ('467300', '467296')
                THEN rec_cur_distrib_fact.DIST_ACCT3
                ELSE rec_cur_distrib_fact.SEGMENT3_NEW
           END                                                                  --SEGMENT3
          --> artf2006649
          ,rec_cur_distrib_fact.SEGMENT4_NEW                                    --SEGMENT4
          ,rec_cur_distrib_fact.SEGMENT5_NEW                                    --SEGMENT5
          ,rec_cur_distrib_fact.SEGMENT6_NEW                                    --SEGMENT6
          ,rec_cur_distrib_fact.SEGMENT7_NEW                                    --SEGMENT7
          ,rec_cur_distrib_fact.SEGMENT8_NEW                                    --SEGMENT8
          ,rec_cur_distrib_fact.SEGMENT9_NEW                                    --SEGMENT9
          ,rec_cur_distrib_fact.SEGMENT10_NEW                                   --SEGMENT10
          ,rec_cur_distrib_fact.SEGMENT11_NEW                                   --SEGMENT11
          ,rec_cur_distrib_fact.SEGMENT12_NEW                                   --SEGMENT12
          ,v_attribute_category                                                 --ATTRIBUTE_CATEGORY
          ,v_attribute1
          ,v_attribute2
          ,v_attribute3
          ,v_attribute4
          ,v_attribute5
          ,v_attribute6
          ,v_attribute7
          ,v_attribute8
          ,v_attribute13
          ,v_attribute14
          ,v_attribute15
          ,g_user_id
          ,SYSDATE
          ,g_user_id
          ,SYSDATE
          ,rec_cur_lignes_fact.ORG_ID
        );

        g_summary.inserted_distrib_rows := g_summary.inserted_distrib_rows + 1;

        -- Mettre à jour le statut de la ligne de distributions
        UPDATE  DKA_DISTRIBUTIONS_FACTURE_TMP
        SET     FLAG         = 'T'
        WHERE  CURRENT OF cur_distrib_fact;
      END LOOP;

      -- Mettre à jour le statut de la ligne de facture
      UPDATE  DKA_ENTETE_LIGNES_FACTURE_TMP
      SET     FLAG        = 'T'
      WHERE  CURRENT OF cur_lignes_fact;
    END LOOP;

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin import_data');

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode   := 2;
      p_errbuf    := 'import_data : ' ||SQLERRM;
      Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure import_data : EXCEPTION OTHERS ');
  END import_data;

/*
 *************************************************************************
 * PROCEDURE NAME : Launch_OI
 *
 * DESCRIPTION
 *  Procédure de lancement du Programme maître de l'interface factures
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_ou              Unité opérationnelle
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 *
 ************************************************************************
 */

  PROCEDURE Launch_OI(p_errbuf            OUT VARCHAR2,
                      p_retcode           OUT NUMBER,
                      p_region            IN  VARCHAR2,
                      p_org_id            IN  NUMBER DEFAULT -99 --< v1.5 - artf2031282
                     )
  IS
        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
        v_message                VARCHAR2 (100);
        b_result                 BOOLEAN;

        v_batch_source_id        NUMBER;

  BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Launch_OI');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                                         'Lancement de l''interface des factures : ');

        fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT, 'LANCEMENT DE L''INTERFACE DES FACTURES :');
        fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
        ---------------------------------------------------
        -- Lancement du traitement de l'interface des factures --
        ---------------------------------------------------
        -- Positionnement des options d'impression
        b_result := fnd_request.set_print_options(printer => gv_printer,
                                                  copies => g_number_of_copies);

        -- Source
        BEGIN
          SELECT  BATCH_SOURCE_ID
          INTO    v_batch_source_id
          FROM    AR_AI_BATCH_SOURCE_V
          WHERE   1=1
          AND     NAME = g_source_name
          --< v1.5 - artf2031282
          --AND     GET_ALL = 'Y'
          AND     GET_ALL = CASE WHEN p_org_id = -99
                                 THEN 'Y'
                                 ELSE 'N'
                            END
          AND     ORG_ID =  CASE WHEN p_org_id = -99
                                 THEN ORG_ID
                                 ELSE p_org_id
                            END
          --> v1.5 - artf2031282
          ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            p_retcode    := 2;
            fnd_file.put_line(fnd_file.LOG, 'ERREUR : La source '||g_source_name||' n''est pas trouvée ');
            Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : La source '||g_source_name||' n''est pas trouvée ');
            RETURN;
        END;
        -- Lancement du traitement Programme maître de l'interface factures
        g_int_request_id := fnd_request.submit_request
                                    (application    =>  'AR',
                                     program        =>  'RAXMTR',
                                     --description    =>  NULL, --< 1.6
                                     description    =>  p_region, --< 1.6
                                     -- v2.1    29/05/2017     NBO artf2142366 - REP004 - Reprise des factures clients - Optimisation
                                     --argument1      =>  '1',                        --Number of Instances
                                     argument1      =>  fnd_profile.value('DKA_REP004_PARALLEL'),                        --Number of Instances
                                     --< v1.5 - artf2031282
                                     --argument2      =>  -99,                        --Organization
                                     argument2      =>  p_org_id,                   --Organization
                                     --> v1.5 - artf2031282
                                     argument3      =>  v_batch_source_id,          --Batch Source Id
                                     argument4      =>  g_source_name,              --Batch Source Name
                                     argument5      =>  TO_CHAR(TRUNC(SYSDATE),
                                                        'YYYY/MM/DD HH24:MI:SS'),   --Default Date
                                     argument6      =>  NULL,                       --Transaction Flexfield
                                     argument7      =>  NULL,                       --Transaction Type
                                     argument8      =>  NULL,                       --(Low) Bill To Customer Number
                                     argument9      =>  NULL,                       --(High) Bill To Customer Number
                                     argument10     =>  NULL,                       --(Low) Bill To Customer Name
                                     argument11     =>  NULL,                       --(High) Bill To Customer Name
                                     argument12     =>  NULL,                       --(Low) GL Date
                                     argument13     =>  NULL,                       --(High) GL Date
                                     argument14     =>  NULL,                       --(Low) Ship Date
                                     argument15     =>  NULL,                       --(High) Ship Date
                                     argument16     =>  NULL,                       --(Low) Transaction Number
                                     argument17     =>  NULL,                       --(High) Transaction  Number
                                     argument18     =>  NULL,                       --(Low) Sales Order Number
                                     argument19     =>  NULL,                       --(High) Sales Order Number
                                     argument20     =>  NULL,                       --(Low) Invoice Date
                                     argument21     =>  NULL,                       --(High) Invoice Date
                                     argument22     =>  NULL,                       --(Low) Ship To Customer Number
                                     argument23     =>  NULL,                       --(High) Ship To Customer Number
                                     argument24     =>  NULL,                       --(Low) Ship To Customer Name
                                     argument25     =>  NULL,                       --(High) Ship To Customer Name
                                     argument26     =>  'N',                        --Base Due Date on Trx Date
                                     argument27     =>  NULL                        --Due Date Adjustment Days
                                    );

        IF g_int_request_id = 0
        THEN
            p_retcode    := 2;
            fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de l''interface des factures a échoué' || CHR(10) ||
                                            'PROGRAMME  : RAXMTR' --|| CHR(10) ||
                                            --'UNITE OPERATIONNELLE : ' || p_ou || CHR(10)
                                            );
            Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de l''interface des factures a échoué');
        ELSE
            COMMIT;
            g_tab_requests(g_int_request_id).request_id := g_int_request_id;
            g_tab_requests(g_int_request_id).interval := g_tempo;
            g_tab_requests(g_int_request_id).max_wait := 0;

            Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || g_int_request_id);
            Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement de l''interface des factures : ' || g_int_request_id);

            --< 1.4
            -- Attente de la fin du traitement
            --IF NOT (Fnd_Concurrent.wait_for_request (g_int_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
            --THEN
            --    p_errbuf  := v_Message;
            --    Fnd_file.put_line(Fnd_file.log, 'ERREUR : Attente de la fin du programme de l''interface des factures : Fin du traitement' || CHR(10) ||
            --                                    'MESSAGE : ' || v_Message || CHR(10) );
            --END IF;
            --
            --IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL')
            --THEN
            --    Fnd_File.put_line(Fnd_File.LOG, 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
            --    Fnd_File.put_line(Fnd_File.OUTPUT, '. Statut de fin : ' || v_phase || '/' || v_status);
            --
            --ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
            --THEN
            --    Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement de l''interface des factures en warning '|| g_int_request_id);
            --    p_retcode    := 1;
            --
            --ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')
            --THEN
            --    p_retcode := 2;
            --    p_errbuf  := 'ERREUR : Fin anormale du traitement de l''interface des factures : '||v_Message;
            --
            --    fnd_file.put_line(fnd_file.LOG, 'ERREUR : Fin anormale du traitement de l''interface des factures '|| g_int_request_id  || CHR(10) ||
            --                                    'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
            --                                    'MESSAGE : ' || v_message || CHR(10) );
            --    Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement de l''interface des factures '||g_int_request_id);
            --END IF;
            --> 1.4

        END IF;


        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Launch_OI');

  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'Launch_OI : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Launch_OI : EXCEPTION OTHERS ');
  END Launch_OI;

 /*
 *************************************************************************
 * PROCEDURE NAME : Bilan
 *
 * DESCRIPTION
 *  Procédure de génération du bilan du traitement d'interface
 *
 * PARAMETERS
 * ==========
 * NAME                 DESCRIPTION
.* -------------------- ---------------------------------------------------
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

        SELECT  count(1)
        INTO    g_summary.rejected_header_fact_rows
        FROM    DKA_ENTETE_LIGNES_FACTURE_TMP
        WHERE   FLAG = 'E'
        ;

        SELECT  count(1)
        INTO    g_summary.rejected_distrib_rows
        FROM    DKA_DISTRIBUTIONS_FACTURE_TMP
        WHERE   FLAG = 'E'
        ;

        fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT,'BILAN :');
        fnd_file.put_line(fnd_file.OUTPUT,'-------');

        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des en-têtes de factures et lignes de factures chargées dans la table spécifique           : '||TO_CHAR(g_summary.loaded_header_fact_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des lignes de distribution chargés dans la table spécifique                                : ' ||TO_CHAR(g_summary.loaded_distrib_rows));

        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des en-têtes de factures et lignes de factures en rejet dans la table spécifique           : ' || TO_CHAR(g_summary.rejected_header_fact_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des lignes de distribution en rejet dans la table spécifique                               : ' || TO_CHAR(g_summary.rejected_distrib_rows));

        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table RA_INTERFACE_LINES_ALL                             : ' || TO_CHAR(g_summary.inserted_header_fact_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table RA_INTERFACE_DISTRIBUTIONS_ALL                     : ' || TO_CHAR(g_summary.inserted_distrib_rows));


        fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Report_Bilan');


  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'REPORT_BILAN : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
  END Report_Bilan;

/**************************************************************************
 * PROCEDURE NAME : set_recovery_mode
 *
 * DESCRIPTION
 *  Procédure d'initialisation du mode reprise (Pas de fichier en entrée)
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
 * -----------------  ------------------------------------------------------
 *
 *************************************************************************/
  PROCEDURE set_recovery_mode(p_Errbuf            OUT VARCHAR2,
                              p_retcode           OUT NUMBER
                              )
  IS

  BEGIN

     --RESET g_loader_request_id
    g_loader_request_id := g_request_id; ---1;

    UPDATE  DKA_ENTETE_LIGNES_FACTURE_TMP
    SET     FLAG = 'N', LOAD_REQUEST_ID = g_request_id
    WHERE   FLAG = 'E';


    UPDATE  DKA_DISTRIBUTIONS_FACTURE_TMP
    SET     FLAG = 'N', LOAD_REQUEST_ID = g_request_id
    WHERE   FLAG = 'E';

  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'SET_RECOVERY_MODE : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure SET_RECOVERY_MODE : EXCEPTION OTHERS ');
  END set_recovery_mode;

 /*
 *************************************************************************
 * PROCEDURE NAME : main
 *
 * DESCRIPTION
 *  Procédure principale
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 ************************************************************************
 */

  PROCEDURE main(p_errbuf       IN    OUT VARCHAR2,
                 p_retcode            OUT NUMBER,
                 p_gl_date      IN        VARCHAR2,
                 p_reprise      IN        VARCHAR2
                 )
  IS

    v_current_program_unit     VARCHAR2(30);
    v_errbuf                   VARCHAR2(2500);
    v_retcode                  NUMBER;
    Erreur_Programme           EXCEPTION;

    CURSOR cur_regions IS
      --< 1.4
      select  distinct substr(hou.name, 1, 3) region,
              --< v1.5 - artf2031282
              hou.name org,
              ral.org_id
              --> v1.5 - artf2031282
      from    ra_interface_lines_all ral
              join hr_operating_units hou
                on ral.org_id = hou.organization_id
      where   ral.interface_line_context = 'REPRISE'
      order by hou.name
      --SELECT ffv.flex_value region
      --  FROM fnd_flex_value_sets ffvs
      --  JOIN fnd_flex_values ffv ON (ffv.flex_value_set_id = ffvs.flex_value_set_id)
      -- WHERE flex_value_set_name = 'DAOPCCF_UO'
      --   AND ffv.enabled_flag = 'Y'
      --   AND ffv.summary_flag = 'N'
      --> 1.4
      ;
      
   --< OBE
    CURSOR cur_org_id IS
        select distinct org_id 
        from DKA_ENTETE_LIGNES_FACTURE_TMP
        where flag = 'T'
        and load_request_id = g_loader_request_id
    ;       
   --> OBE   

  BEGIN

    ----------------------------
    -- PHASE D'INITIALISATION --
    ----------------------------

    v_current_program_unit := 'main';
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'DEBUT DE L''INTERFACE');


    Output_Header;
    Request_parameters;

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE D''INITIALISATION');

    v_errbuf  := NULL;
    v_retcode := 0;

    Init(v_errbuf, v_retcode, p_reprise);

    g_gl_date := fnd_date.canonical_to_date(p_gl_date);
    
    --< V1.6
    SELECT  trunc(add_months(g_gl_date, 1), 'MM') - 1
    INTO    g_gl_date_max
    FROM    dual;
    --> V1.6

    IF v_retcode = 2
    THEN
        p_Errbuf  := v_errbuf;
        p_retcode := v_retcode;
        RAISE Erreur_Programme;
    END IF;

    IF g_summary.reprise_flag = 'N' THEN

      ------------------------------------
      -- PHASE DE CHARGEMENT DU FICHIER --
      ------------------------------------
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE DE CHARGEMENT DU FICHIER');

      -- Lancement du programme de chargement
      Launch_Loader(v_errbuf, v_retcode);
      IF v_retcode = 2 THEN
        RAISE Erreur_Programme;
      END IF;

    ELSE
      set_recovery_mode(v_errbuf, v_retcode);
    END IF;

    -------------------------------------
    -- PHASE DE VALIDATION DES DONNEES --
    ------------------------------------- 
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE DE VALIDATION DES DONNEES');

    validate_data(v_errbuf, v_retcode);
    
    IF v_retcode = 2 THEN
      RAISE Erreur_Programme;
    END IF;

    --------------------------------
    -- PHASE D'IMPORT DES DONNEES --
    -------------------------------- 
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE D''IMPORT DES DONNEES');

    import_data(v_errbuf, v_retcode);
    
    IF v_retcode = 2 THEN
      RAISE Erreur_Programme;
    END IF;

    --< RBE artf2205802
    --< OBE
    FOR rec in cur_org_id LOOP
    
        UPDATE  ra_batch_sources_all rbs
        SET     rbs.allow_duplicate_trx_num_flag = 'Y'
               ,last_update_date = sysdate
               ,last_updated_by = g_user_id
        WHERE   rbs.name = g_source_name
        AND     rbs.org_id = rec.org_id
        --AND     allow_duplicate_trx_num_flag = 'N'
        ;  
        
    END LOOP;
    --> OBE
    
    -----------------------------------------------
    -- PHASE DE LANCEMENT DU TRAITEMENT STANDARD --
    -----------------------------------------------
    FOR l_regions in cur_regions LOOP

      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE DE LANCEMENT DU TRAITEMENT STANDARD');

      --< artf2104888
      ---- Initialisation de l'environnement
      --init_environement(v_errbuf, v_retcode,l_regions.region||'_AR_ADMINISTRATEUR');
      --IF v_retcode != 0 THEN
      --  p_errbuf  := v_errbuf;
      --  p_retcode := v_retcode;
      --  RAISE Erreur_Programme;
      --END IF;
      --> artf2104888

      -- Lancement de l'import des mouvements AR
      Fnd_File.put_line (Fnd_File.LOG, 'début lancement traitement standard d''import des mouvements AR pour l''organisation '||l_regions.org);
      v_errbuf := null;
      --< v1.5 - artf2031282
      --Launch_OI(v_errbuf, v_retcode, l_regions.region);
      Launch_OI(v_errbuf, v_retcode, l_regions.org, l_regions.org_id);
      --> v1.5 - artf2031282
      IF v_retcode = 2 THEN
        p_errbuf  := v_errbuf;
        p_retcode := v_retcode;
        RAISE Erreur_Programme;
      END IF;

    END LOOP;

    Fnd_File.put_line (Fnd_File.LOG, 'fin lancement traitement standard d''import des mouvements AR');

    --< artf2104888
    ---- Initialisation de l'environnement
    --Fnd_File.put_line (Fnd_File.LOG, 'Initialisation de l''environnement avec la responsabilité TOUT_AR_ADMINISTRATEUR');
    --v_errbuf := null;
    --init_environement(v_errbuf, v_retcode,'TOUT_AR_ADMINISTRATEUR');
    --IF v_retcode != 0 THEN
    --   p_errbuf  := v_errbuf;
    --   p_retcode := v_retcode;
    --   RAISE Erreur_Programme;
    --END IF;
    --> artf2104888
    
    -- Attente de la fin des traitements d'import des sites fournisseurs
    wait_import(v_errbuf,v_retcode);
    IF v_retcode = 2 THEN
       p_errbuf  := v_errbuf;
       p_retcode := v_retcode;
       RAISE Erreur_Programme;
    END IF;
    
    --<artf2110172
    declare
      cursor c_datafix is
        select  rct.customer_trx_id,
                rct.cust_trx_type_id,
                rctt.cust_trx_type_id new_cust_trx_type_id,
                rctt.type new_class,
                rct.interface_header_attribute1,
                rctt.name
        from    dka_entete_lignes_facture_tmp delf
                join  ra_customer_trx_all rct
                  on rct.interface_header_context = 'REPRISE'
                  and rct.interface_header_attribute1 = delf.trx_type
                  and rct.interface_header_attribute2 = delf.societe
                  and rct.interface_header_attribute3 = delf.trx_number
                  and rct.interface_header_attribute4 = delf.trx_date
                join ar_payment_schedules_all aps
                  on rct.customer_trx_id = aps.customer_trx_id
                left outer join ra_cust_trx_types_all rctt
                  on  case when substr(rct.interface_header_attribute1, 10, 100) = 'DOUTEUX_GPE'
                           then 'DOUTEUX GROUPE'
                           when substr(rct.interface_header_attribute1, 10, 100) = 'DOUTEUX'
                           then 'DOUTEUX'
                           else delf.new_trx_type
                      end = rctt.name
                  and  rct.org_id = rctt.org_id
        where   1= 1
        and     delf.type = 'CB'
        and     aps.class <> 'CB'
        ;
    begin
      for r_row in c_datafix loop
        update  ra_customer_trx_all rct
        set     rct.cust_trx_type_id = r_row.new_cust_trx_type_id
        where   rct.customer_trx_id = r_row.customer_trx_id;
        
        update  ar_payment_schedules_all aps
        set     aps.cust_trx_type_id = r_row.new_cust_trx_type_id,
                aps.class = r_row.new_class
        where   aps.customer_trx_id = r_row.customer_trx_id;
        
      end loop;
      
      commit;
    end;    
    -->artf2110172
    
    --< OBE
    FOR rec in cur_org_id LOOP
    
        UPDATE  ra_batch_sources_all rbs
        SET     rbs.allow_duplicate_trx_num_flag = 'N'
               ,last_update_date = sysdate
               ,last_updated_by = g_user_id
        WHERE   rbs.name = g_source_name
        AND     rbs.org_id = rec.org_id
        AND     allow_duplicate_trx_num_flag = 'Y'
        ;  
        
    END LOOP;
    --> OBE
    
    
    -- bilan
    Report_Bilan(p_Errbuf,p_retcode);

    ---------------------------------------
    -- PHASE DE FIN DU TRAITEMENT MAITRE --
    ---------------------------------------
    IF p_retcode = 2
    THEN
       p_errbuf := 'ATTENTION : Erreur bloquante : '||p_errbuf;
    ELSIF (g_summary.rejected_header_fact_rows > 0 OR g_summary.rejected_distrib_rows > 0)
    THEN
       p_errbuf := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
       p_retcode := 1;
    ELSIF (g_summary.loaded_header_fact_rows = 0 AND g_summary.loaded_distrib_rows = 0 AND  g_summary.reprise_flag = 'N')
    THEN
       p_errbuf := 'ATTENTION : Aucun enregistrement chargé.';
       p_retcode := 1;
    ELSE
       p_errbuf := 'Fin normale du traitement - Aucun rejet.';
       p_retcode := 0;
    END IF;

    COMMIT;

    Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
    Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf||CHR(10));
    output_end;
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'FIN DE L''INTERFACE');


  EXCEPTION
        WHEN Erreur_Programme
        THEN
            p_retcode   := 2;
            p_errbuf    := v_errbuf;
            --Fnd_File.put_line (Fnd_Filxe.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');
            Fnd_File.put_line (Fnd_File.OUTPUT, '==> Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');
       WHEN OTHERS
       THEN
           fnd_concurrent.af_rollback;
           p_retcode := 2;
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_REPARFACTIMP_PKG.' || v_current_program_unit||CHR(10)||'A retourné     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           p_errbuf := SQLERRM;
  END main;


END DKA_REPARFACTIMP_PKG;
/
SHOW ERRORS
EXIT
