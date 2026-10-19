SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
create or replace PACKAGE BODY DKA_REPARCLIIMP_PKG IS
  --------------------------------------------------------------------------------------------
  -- FILENAME
  --    DKA_REPARCLIIMP_PKG.pkb  V1.12
  --
  -- AUTEUR
  --    Capgemini
  --
  -- DESCRIPTION
  --    Création du package de l'interface specifique des clients
  --
  -- USAGE
  --    A exécuter sous SqlPlus avec user APPS
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
  -- V1.0    06/05/2016     OBN Creation
  ---------------------------------------------------------------------------------------------
  -- V1.1    15/07/2016     OBN Modification : - Prise en compte du nouveau champ country_bank
  --                                           au niveau du fichier de contrôle
  --                                           - Modification de la procédure validate_data
  ---------------------------------------------------------------------------------------------
  -- V1.2    15/07/2016     OBN Modification : - Ajout de l'API pour vérification/création des banques/agences
  ---------------------------------------------------------------------------------------------
  -- V1.3    19/07/2016     MEG Modification : - Ajout d'un controle sur les banques / agences a la place des API
  ---------------------------------------------------------------------------------------------
  -- V1.4    02/08/2016     OBN Modification : - Modification de la sortie du traitement -artf1981234-
  ---------------------------------------------------------------------------------------------
  -- V1.5    08/08/2016     OBN Modification : - Ajout d'un contrôle afin de rejeter les banques et agences qui n'existent pas
  ---------------------------------------------------------------------------------------------
  -- V1.6    27/09/2016     OBN Modification : - Modifications -artf2012517- artf2014757 / Ajout API pour création des comptes bancaires
  ---------------------------------------------------------------------------------------------
  -- V1.7    05/10/2016     OBN Modification : - Correction -artf2023709-
  ---------------------------------------------------------------------------------------------
  -- V1.8    07/10/2016     OBN Modification : Optimisation du traitement -artf2016223-
  ---------------------------------------------------------------------------------------------
  -- V1.9    10/10/2016     JLY Modification : Optimisation du traitement
  ---------------------------------------------------------------------------------------------
  -- V1.10   24/10/2016     MEG Modification : Correction suite a l'artf2032823
  ---------------------------------------------------------------------------------------------
  -- V1.11   15/11/2016     OBE Modification : Correction suite a l'artf2044674
  ---------------------------------------------------------------------------------------------
  -- V1.12   22/11/2016     OBE Modification : Correction suite a l'artf2049012
  ---------------------------------------------------------------------------------------------
  -- V1.13  16/12/2016      NBO artf2062780 - REP002 - Export / Import - Gestion des relations
  ---------------------------------------------------------------------------------------------
  -- V1.14  11/01/2017      JLY artf2081484 - Les contrôles sur l'absence des banques ne doivent pas empècher la création du client
  --                            artf2081483 - Controle de la catégorie et de la classe
  --                            artf2084473 - Gestion des UO désactivées
  --                            artf2084531 - Perf. Execution des statistiques
  ---------------------------------------------------------------------------------------------
  -- V1.14  26/01/2017      JLY artf2089049 - Date affecatation RIB
  ---------------------------------------------------------------------------------------------
  -- V1.15 28/07/2017      NBO artf2204067 - REP002 - Il y a des rejets dans l'open-interface des modes de paiement
  ---------------------------------------------------------------------------------------------
  -- V1.16 09/11/2017      NBO artf2274489 - REP002 - Il y a des rejets dans l'open-interface des modes de paiement

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  TYPE summary_typ IS RECORD(
    loaded_rows_cli       NUMBER, -- Nb de Lignes chargées en table spécifique des clients
    loaded_rows_rec       NUMBER, -- Nb de Lignes chargées en table spécifique des chargés de recouvrement
    loaded_rows_OI_cust   NUMBER, -- Nb de Lignes chargées en table OI des clients
    loaded_rows_OI_prof   NUMBER, -- Nb de Lignes chargées en table OI des profils
    loaded_rows_OI_meth   NUMBER, -- Nb de Lignes chargées en table OI des méthodes de paiements
    loaded_rows_OI_bank   NUMBER, -- Nb de Lignes chargées en table OI des banques
    loaded_rows_OI_cont   NUMBER, -- Nb de Lignes chargées en table OI des contacts
    rejected_rows_cli     NUMBER, -- Nb de lignes rejetées dans la table spécifique des clients
    rejected_rows_rec     NUMBER, -- Nb de lignes rejetées dans la table spécifique des chargés de recouvrement
    rejected_rows_OI_cust NUMBER, -- Nb de lignes rejetées dans la table OI des clients
    rejected_rows_OI_prof NUMBER, -- Nb de lignes rejetées dans la table OI des profils
    rejected_rows_OI_meth NUMBER, -- Nb de lignes rejetées dans la table OI des méthodes de paiements
    rejected_rows_OI_bank NUMBER, -- Nb de lignes rejetées dans la table OI des banques
    rejected_rows_OI_cont NUMBER, -- Nb de lignes rejetées dans la table OI des contacts
    rejected_rows         NUMBER, -- Nb de lignes rejetées dans les tables d'open interface
    warning_rows          NUMBER -- Nb de lignes en avertissement
    );

  TYPE IdTabTyp IS TABLE OF NUMBER(15) INDEX BY BINARY_INTEGER;

  g_summary summary_typ;

  g_buf VARCHAR2(2000); --buffer d erreur
  g_ret NUMBER; --code retour erreur
  erreur EXCEPTION; --Erreur fatale du programme

  g_user_id              fnd_user.user_id%TYPE;
  g_login_id             fnd_logins.login_id%TYPE;
  g_org_id               hr_all_organization_units.organization_id%TYPE;
  g_request_id           fnd_concurrent_requests.request_id%TYPE;
  g_loader_request_id    fnd_concurrent_requests.request_id%TYPE;
  g_int_request_id       fnd_concurrent_requests.request_id%TYPE;
  g_request_OI_vendor_id fnd_concurrent_requests.request_id%TYPE;
  g_request_OI_site_id   fnd_concurrent_requests.request_id%TYPE;
  gv_printer             fnd_concurrent_requests.printer%TYPE;
  g_number_of_copies     fnd_concurrent_requests.number_of_copies%TYPE;
  g_tempo                NUMBER;
  g_nom_traitement       VARCHAR2(100);
  g_org_id_profil        NUMBER;

  g_segment4_client_partner  VARCHAR2(40); --Compte groupe client avec code partenaire -- PHENIX 2004:  gv_segment2... -> gv_segment4....
  g_segment4_client          VARCHAR2(40); --Compte groupe client sans code partenaire -- PHENIX 2004:  gv_segment2... -> gv_segment4....
  g_segment4_produit_partner VARCHAR2(40); --Compte groupe produit avec code partenaire -- PHENIX 2004:  gv_segment2... -> gv_segment4....
  g_segment4_produit         VARCHAR2(40); --Compte groupe produit sans code partenaire -- PHENIX 2004:  gv_segment2... -> gv_segment4....

  g_segment3_client_partner  VARCHAR2(40); --Compte local client avec code partenaire
  g_segment3_client          VARCHAR2(40); --Compte local client sans code partenaire
  g_segment3_produit_partner VARCHAR2(40); --Compte local produit avec code partenaire
  g_segment3_produit         VARCHAR2(40); --Compte local produit sans code partenaire

  -- 16/12/2016 NBO artf2062780 - REP002 - Export / Import - Gestion des relations
  gv_statut_ok    VARCHAR2(20) := 'OK';
  gv_statut_new   VARCHAR2(20) := 'NEW';
  gv_statut_valid VARCHAR2(20) := 'VALID';
  gv_statut_ko    VARCHAR2(20) := 'INVALID';
  gv_statut_rejected VARCHAR2(20) := 'REJECTED';

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

  PROCEDURE init(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

    v_current_program_unit VARCHAR2(30);
    v_step_program_error   VARCHAR2(1000);
    program_error EXCEPTION;
    rec_param dka_parameters%ROWTYPE;

  BEGIN

    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début init');

    ----------------------------------
    -- Initialisation des variables --
    ----------------------------------
    p_errbuf               := NULL;
    p_retcode              := 0;
    v_current_program_unit := 'INIT';

    ------------------------
    -- Variables globales --
    ------------------------

    g_user_id    := fnd_global.user_id;
    g_login_id   := fnd_global.login_id;
    g_request_id := fnd_global.conc_request_id;
    g_org_id     := fnd_profile.value('ORG_ID');
    g_tempo      := 20;

    -- Nom du programme

    SELECT fcp.CONCURRENT_PROGRAM_NAME
      INTO g_nom_traitement
      FROM FND_CONCURRENT_REQUESTS fcr, FND_CONCURRENT_PROGRAMS_VL fcp
     WHERE 1 = 1
       AND fcr.CONCURRENT_PROGRAM_ID = fcp.CONCURRENT_PROGRAM_ID
       AND fcr.PROGRAM_APPLICATION_ID = fcp.APPLICATION_ID
       AND fcr.REQUEST_ID = g_request_id;

    -- Variables globales de comptage
    g_summary.loaded_rows_cli       := 0;
    g_summary.loaded_rows_rec       := 0;
    g_summary.loaded_rows_OI_cust   := 0;
    g_summary.loaded_rows_OI_prof   := 0;
    g_summary.loaded_rows_OI_meth   := 0;
    g_summary.loaded_rows_OI_bank   := 0;
    g_summary.loaded_rows_OI_cont   := 0;
    g_summary.rejected_rows_cli     := 0;
    g_summary.rejected_rows_rec     := 0;
    g_summary.rejected_rows         := 0;
    g_summary.rejected_rows_OI_cust := 0;
    g_summary.rejected_rows_OI_prof := 0;
    g_summary.rejected_rows_OI_meth := 0;
    g_summary.rejected_rows_OI_bank := 0;
    g_summary.rejected_rows_OI_cont := 0;
    g_summary.warning_rows          := 0;

    -- Récupération des variables de la table des paramètres
    Dka_Tools_Pkg.get_parameter('DKA_REPARCLIIMP',
                                'SEG4_CUST_PARTNER',
                                rec_param,
                                p_retcode,
                                p_errbuf); -- PHENIX 2004: SEG2_CUST_PARTNER -> SEG4_CUST_PARTNER.
    g_segment4_client_partner := rec_param.varchar2_value; -- PHENIX 2004: gv_segment2_client_partner -> g_segment4_client_partner.
    IF p_retcode != 0 THEN
      p_errbuf := 'init : SEG4_CUST_PARTNER - ' || p_errbuf; -- PHENIX 2004: SEG2_CUST_PARTNER -> SEG4_CUST_PARTNER.
      RETURN;
    END IF;

    Dka_Tools_Pkg.get_parameter('DKA_REPARCLIIMP',
                                'SEG4_CUST',
                                rec_param,
                                p_retcode,
                                p_errbuf); -- PHENIX 2004: SEG2_CUST -> SEG4_CUST.
    g_segment4_client := rec_param.varchar2_value; -- PHENIX 2004: gv_segment2_client -> g_segment4_client.
    IF p_retcode != 0 THEN
      p_errbuf := 'init : SEG4_CUST - ' || p_errbuf; -- PHENIX 2004: SEG2_CUST -> SEG4_CUST.
      RETURN;
    END IF;

    Dka_Tools_Pkg.get_parameter('DKA_REPARCLIIMP',
                                'SEG4_REV_PARTNER',
                                rec_param,
                                p_retcode,
                                p_errbuf); -- PHENIX 2004: SEG2_REV_PARTNER -> SEG4_REV_PARTNER.
    g_segment4_produit_partner := rec_param.varchar2_value; -- PHENIX 2004: gv_segment2_produit_partner -> g_segment4_produit_partner.
    IF p_retcode != 0 THEN
      p_errbuf := 'init : SEG4_REV_PARTNER - ' || p_errbuf; -- PHENIX 2004: SEG2_REV_PARTNER -> SEG4_REV_PARTNER.
      RETURN;
    END IF;

    Dka_Tools_Pkg.get_parameter('DKA_REPARCLIIMP',
                                'SEG4_REV',
                                rec_param,
                                p_retcode,
                                p_errbuf); -- PHENIX 2004: SEG2_REV -> SEG4_REV.
    g_segment4_produit := rec_param.varchar2_value; -- PHENIX 2004: gv_segment2_produit -> g_segment4_produit.
    IF p_retcode != 0 THEN
      p_errbuf := 'init : SEG4_REV - ' || p_errbuf; -- PHENIX 2004: SEG2_REV -> SEG4_REV.
      RETURN;
    END IF;

    Dka_Tools_Pkg.get_parameter('DKA_REPARCLIIMP',
                                'SEG3_CUST_PARTNER',
                                rec_param,
                                p_retcode,
                                p_errbuf);
    g_segment3_client_partner := rec_param.varchar2_value;
    IF p_retcode != 0 THEN
      p_errbuf := 'init : SEG3_CUST_PARTNER - ' || p_errbuf;
      RETURN;
    END IF;

    Dka_Tools_Pkg.get_parameter('DKA_REPARCLIIMP',
                                'SEG3_CUST',
                                rec_param,
                                p_retcode,
                                p_errbuf);
    g_segment3_client := rec_param.varchar2_value;
    IF p_retcode != 0 THEN
      p_errbuf := 'init : SEG3_CUST - ' || p_errbuf;
      RETURN;
    END IF;

    Dka_Tools_Pkg.get_parameter('DKA_REPARCLIIMP',
                                'SEG3_REV_PARTNER',
                                rec_param,
                                p_retcode,
                                p_errbuf);
    g_segment3_produit_partner := rec_param.varchar2_value;
    IF p_retcode != 0 THEN
      p_errbuf := 'init : SEG3_REV_PARTNER - ' || p_errbuf;
      RETURN;
    END IF;

    Dka_Tools_Pkg.get_parameter('DKA_REPARCLIIMP',
                                'SEG3_REV',
                                rec_param,
                                p_retcode,
                                p_errbuf);
    g_segment3_produit := rec_param.varchar2_value;
    IF p_retcode != 0 THEN
      p_errbuf := 'init : SEG3_REV - ' || p_errbuf;
      RETURN;
    END IF;

    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin init');

    BEGIN
      SELECT printer, number_of_copies
        INTO gv_printer, g_number_of_copies
        FROM fnd_concurrent_requests fcr
       WHERE fcr.request_id = g_request_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Fnd_File.put_line(Fnd_File.LOG,
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                          ' - ' ||
                          'Erreur de récupération de l''imprimante');
        gv_printer         := NULL;
        g_number_of_copies := 0;
    END;

  EXCEPTION
    WHEN program_error THEN
      fnd_file.put_line(fnd_file.log, 'ERREUR : ' || v_step_program_error);
      RAISE;
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'INIT : ' || SQLERRM;
  END init;

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

  PROCEDURE output_header IS
    cv_line                  VARCHAR2(100);
    v_conc_program_name      fnd_concurrent_programs.concurrent_program_name%TYPE;
    v_user_conc_program_name fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN

    cv_line := '+-------------------------------------------------------------------------+';

    ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
    BEGIN
      SELECT fcp.concurrent_program_name, fcpt.user_concurrent_program_name
        INTO v_conc_program_name, v_user_conc_program_name
        FROM fnd_concurrent_programs fcp, fnd_concurrent_programs_tl fcpt
       WHERE fcp.application_id = Fnd_Global.prog_appl_id
         AND fcp.concurrent_program_id = Fnd_Global.conc_program_id
         AND fcpt.application_id = Fnd_Global.prog_appl_id
         AND fcpt.concurrent_program_id = Fnd_Global.conc_program_id
         AND fcpt.LANGUAGE = Fnd_Global.current_language;
    EXCEPTION
      WHEN OTHERS THEN
        v_user_conc_program_name := '???????????????????????';
        v_conc_program_name      := '???????';
    END;

    Fnd_File.put_line(Fnd_File.output, cv_line || CHR(10));
    Fnd_File.put_line(Fnd_File.output,
                      'Nom du traitement  : ' || v_user_conc_program_name);
    Fnd_File.put_line(Fnd_File.output,
                      'Code du traitement : ' || v_conc_program_name);
    Fnd_File.put_line(Fnd_File.output,
                      'Programme lancé le : ' ||
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
    Fnd_File.put_line(Fnd_File.output, cv_line || CHR(10) || CHR(10));
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

  PROCEDURE Request_parameters IS

    CURSOR cur_parameters IS
      SELECT form_left_prompt
        FROM fnd_concurrent_requests     fcr,
             fnd_concurrent_programs     fcp,
             fnd_descr_flex_col_usage_vl fdfcu
       WHERE fdfcu.descriptive_flexfield_name =
             '$SRS$.' || fcp.concurrent_program_name
         AND fcp.concurrent_program_id = fcr.concurrent_program_id
         AND fcr.request_id = Fnd_Global.conc_request_id
       ORDER BY fdfcu.column_seq_num;
    rec_parameters cur_parameters%ROWTYPE;

    sql_req           VARCHAR2(500);
    v_argument_number VARCHAR2(12);
    v_argument_num    NUMBER;
    v_argument_value  VARCHAR2(240);
  BEGIN

    Fnd_File.put_line(Fnd_File.output, 'PARAMETRES : ');
    Fnd_File.put_line(Fnd_File.output, '--------------');
    Fnd_File.put_line(Fnd_File.log, 'PARAMETRES : ');
    Fnd_File.put_line(Fnd_File.log, '--------------');

    v_argument_num := 1;

    OPEN cur_parameters;
    FETCH cur_parameters
      INTO rec_parameters;

    IF (cur_parameters%FOUND) THEN
      v_argument_number := 'ARGUMENT' || v_argument_num;

      sql_req := 'SELECT ' || v_argument_number ||
                 ' FROM fnd_concurrent_requests ' ||
                 'WHERE request_id = Fnd_Global.conc_request_id';

      EXECUTE IMMEDIATE sql_req
        INTO v_argument_value;

      Fnd_File.put_line(Fnd_File.output,
                        rec_parameters.form_left_prompt || ' : ' ||
                        v_argument_value);
      Fnd_File.put_line(Fnd_File.log,
                        rec_parameters.form_left_prompt || ' : ' ||
                        v_argument_value);

      LOOP
        FETCH cur_parameters
          INTO rec_parameters;
        EXIT WHEN cur_parameters%NOTFOUND;

        v_argument_num    := v_argument_num + 1;
        v_argument_number := 'ARGUMENT' || v_argument_num;

        sql_req := 'SELECT ' || v_argument_number ||
                   ' FROM fnd_concurrent_requests ' ||
                   'WHERE request_id = Fnd_Global.conc_request_id';

        EXECUTE IMMEDIATE sql_req
          INTO v_argument_value;

        Fnd_File.put_line(Fnd_File.output,
                          rec_parameters.form_left_prompt || ' : ' ||
                          v_argument_value);
        Fnd_File.put_line(Fnd_File.log,
                          rec_parameters.form_left_prompt || ' : ' ||
                          v_argument_value);
      END LOOP;

      Fnd_File.put_line(Fnd_File.output, CHR(10));

    ELSE
      Fnd_File.put_line(Fnd_File.output, 'Aucun argument');
      Fnd_File.put_line(Fnd_File.log, 'Aucun argument');
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

  PROCEDURE output_end IS
    cv_line VARCHAR2(100);
  BEGIN

    cv_line := '+-------------------------------------------------------------------------+';

    Fnd_File.put_line(Fnd_File.output, cv_line || CHR(10));
    Fnd_File.put_line(Fnd_File.output,
                      'Programme terminé le : ' ||
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
    Fnd_File.put_line(Fnd_File.output, cv_line);
  END output_end;

  /*
   *************************************************************************
   * PROCEDURE NAME : print_errors
   *
   * DESCRIPTION
   *  Procédure pour écrire les anomalies du programme
   *
   * PARAMETERS
   * ==========
   * NAME               DESCRIPTION
  .* -----------------  ------------------------------------------------------
   *
   ************************************************************************
   */

  PROCEDURE print_errors IS

    CURSOR cur_prog_mess IS
      SELECT DISTINCT dct.customer_number, dpm.table_id, dpm.column_name||' '||dpm.column_value||' => '||dpm.message_text message_text
        FROM DKA_CLIENTS_TMP dct,
             DKA_PROGRAM_MESSAGES dpm
       WHERE dct.LOGICAL_LINE_NUM = dpm.TABLE_ID
         AND dpm.TABLE_NAME = 'DKA_CLIENTS_TMP'
         AND dpm.REQUEST_ID = g_request_id
         AND dpm.MESSAGE_TYPE = 'E' -- V1.6
      UNION ALL
      SELECT DISTINCT dct.customer_number, dpm.table_id, dpm.column_name||' '||dpm.column_value||' => '||dpm.message_text message_text
        FROM DKA_RECOUVREMENTS_TMP dct,
             DKA_PROGRAM_MESSAGES dpm
       WHERE dct.LOGICAL_LINE_NUM = dpm.TABLE_ID
         AND dpm.TABLE_NAME = 'DKA_RECOUVREMENTS_TMP'
         AND dpm.REQUEST_ID = g_request_id
         AND dpm.MESSAGE_TYPE = 'E' -- V1.6
         ;

    --< V1.6
    CURSOR cur_prog_avert IS
      SELECT DISTINCT dct.customer_number, dpm.table_id, dpm.column_name||' '||dpm.column_value||' => '||dpm.message_text message_text
        FROM DKA_CLIENTS_TMP dct,
             DKA_PROGRAM_MESSAGES dpm
       WHERE dct.LOGICAL_LINE_NUM = dpm.TABLE_ID
         AND dpm.TABLE_NAME = 'DKA_CLIENTS_TMP'
         AND dpm.REQUEST_ID = g_request_id
         AND dpm.MESSAGE_TYPE = 'W'
      UNION ALL
      SELECT DISTINCT dct.customer_number, dpm.table_id, dpm.column_name||' '||dpm.column_value||' => '||dpm.message_text message_text
        FROM DKA_RECOUVREMENTS_TMP dct,
             DKA_PROGRAM_MESSAGES dpm
       WHERE dct.LOGICAL_LINE_NUM = dpm.TABLE_ID
         AND dpm.TABLE_NAME = 'DKA_RECOUVREMENTS_TMP'
         AND dpm.REQUEST_ID = g_request_id
         AND dpm.MESSAGE_TYPE = 'W'
      ;
    --> V1.6

  BEGIN
    --< v1.4
    /*fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT, 'LISTE DES ANOMALIES :');
    fnd_file.put_line(fnd_file.OUTPUT, '----------------------');

    FOR msg IN cur_prog_mess LOOP
        Fnd_File.put_line (Fnd_File.output, '. '||msg.message_text);
    END LOOP;*/

    --< V1.6
    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT, 'LISTE DES AVERTISSEMENTS :');
    fnd_file.put_line(fnd_file.OUTPUT, '---------------------');
    fnd_file.put_line(fnd_file.OUTPUT, 'N°Client        Ligne    Message');
    fnd_file.put_line(fnd_file.OUTPUT, '------------    -----    -------');

    FOR avert IN cur_prog_avert LOOP
      Fnd_File.put_line(Fnd_File.output,
                        RPAD(avert.customer_number, 12, ' ') || '    ' ||
                        RPAD(NVL(avert.table_id, ' '), 5, ' ') || '    ' ||
                        avert.message_text);
    END LOOP;
    --> V1.6

    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT, 'LISTE DES ANOMALIES :');
    fnd_file.put_line(fnd_file.OUTPUT, '---------------------');
    fnd_file.put_line(fnd_file.OUTPUT, 'N°Client        Ligne    Message');
    fnd_file.put_line(fnd_file.OUTPUT, '------------    -----    -------');

    FOR msg IN cur_prog_mess LOOP
      Fnd_File.put_line(Fnd_File.output,
                        RPAD(msg.customer_number, 12, ' ') || '    ' ||
                        RPAD(NVL(msg.table_id, ' '), 5, ' ') || '    ' ||
                        msg.message_text);
    END LOOP;
    --> v1.4
  END print_errors;

  -------------------------------------------------------------------------------------
  --  Nom           : GET_GL_ID
  --  Description   : Calcule et retourne les cles comptables client et produit
  --      qu il faudra par la suite inserer dans la fonction
  --      economique de facturation
  --
  --  PARAMETRES    : Code Centre de Gestion
  --        Code Societe
  --        Code Partenaire
  --  OUT      ID de la cle client
  --  OUT      ID de la cle produit
  --
  ------------------------------------------------------------------------------------
  -- PHENIX 2004: Procedure modifiee.
  PROCEDURE get_gl_id(p_cdg          IN VARCHAR2,
                      p_soc          IN VARCHAR2,
                      p_partner_code IN VARCHAR2 DEFAULT NULL,
                      gl_id_rec      OUT NUMBER,
                      gl_id_rev      OUT NUMBER) IS

  BEGIN

    IF p_partner_code IS NOT NULL THEN
      -- code partenaire renseigne
      --Dka_Tools_Pkg.put_outdebug_message('p_partner_code IS NOT NULL');
      -- Fnd_File.put_line (Fnd_File.LOG,'p_partner_code IS NOT NULL');
      BEGIN
        /*Fnd_File.put_line (Fnd_File.LOG,'p_soc : '||p_soc);
        Fnd_File.put_line (Fnd_File.LOG,'p_cdg : '||p_cdg);
        Fnd_File.put_line (Fnd_File.LOG,'g_segment3_client_partner : '||g_segment3_client_partner);
        Fnd_File.put_line (Fnd_File.LOG,'g_segment4_client_partner : '||g_segment4_client_partner);
        Fnd_File.put_line (Fnd_File.LOG,'p_partner_code : '||p_partner_code);*/
        SELECT gcc.code_combination_id
          INTO gl_id_rec
          FROM gl_code_combinations gcc, gl_ledgers gl
         WHERE 1 = 1
           AND gl.ledger_category_code = 'PRIMARY'
           AND gl.short_name = p_soc
           AND gl.chart_of_accounts_id = gcc.chart_of_accounts_id
           AND gcc.segment1 = p_soc
           AND gcc.segment2 = p_cdg
           AND gcc.segment3 = g_segment3_client_partner
           AND gcc.segment4 = g_segment4_client_partner
           AND gcc.segment5 = p_partner_code
           AND gcc.segment6 = '0'
           AND gcc.segment7 = '0'
           AND gcc.segment8 = '0'
           AND gcc.segment9 = '0'
           AND gcc.segment10 = '0'
              --< V1.9
           AND gcc.segment11 = '0'
           AND gcc.segment12 = '0'
        --> V1.9
        ;
      EXCEPTION
        WHEN OTHERS THEN
          Dka_Tools_Pkg.get_code_combination_id(p_soc,
                                                p_cdg,
                                                g_segment3_client_partner,
                                                g_segment4_client_partner,
                                                p_partner_code,
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                gl_id_rec,
                                                g_buf,
                                                g_ret);
          IF g_ret != 0 THEN
            Fnd_File.put_line(Fnd_File.LOG, g_buf);
            RAISE erreur;
          END IF;
      END;

      BEGIN
        SELECT gcc.code_combination_id
          INTO gl_id_rev
          FROM gl_code_combinations gcc, gl_ledgers gl
         WHERE 1 = 1
           AND gl.ledger_category_code = 'PRIMARY'
           AND gl.short_name = p_soc
           AND gl.chart_of_accounts_id = gcc.chart_of_accounts_id
           AND gcc.segment1 = p_soc
           AND gcc.segment2 = p_cdg
           AND gcc.segment3 = g_segment3_produit_partner
           AND gcc.segment4 = g_segment4_produit_partner
           AND gcc.segment5 = p_partner_code
           AND gcc.segment6 = '0'
           AND gcc.segment7 = '0'
           AND gcc.segment8 = '0'
           AND gcc.segment9 = '0'
           AND gcc.segment10 = '0'
              --< V1.9
           AND gcc.segment11 = '0'
           AND gcc.segment12 = '0'
        --> V1.9
        ;
      EXCEPTION
        WHEN OTHERS THEN
          Dka_Tools_Pkg.get_code_combination_id(p_soc,
                                                p_cdg,
                                                g_segment3_produit_partner,
                                                g_segment4_produit_partner,
                                                p_partner_code,
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                gl_id_rev,
                                                g_buf,
                                                g_ret);
          IF g_ret != 0 THEN
            Fnd_File.put_line(Fnd_File.LOG, g_buf);

            RAISE erreur;
          END IF;
      END;

    ELSE
      -- code partenaire non renseigne
      --Fnd_File.put_line (Fnd_File.LOG,'p_partner_code IS NULL');
      BEGIN
        /*Fnd_File.put_line (Fnd_File.LOG,'p_soc : '||p_soc);
        Fnd_File.put_line (Fnd_File.LOG,'p_cdg : '||p_cdg);
        Fnd_File.put_line (Fnd_File.LOG,'g_segment3_client : '||g_segment3_client);
        Fnd_File.put_line (Fnd_File.LOG,'g_segment4_client : '||g_segment4_client);*/
        SELECT gcc.code_combination_id
          INTO gl_id_rec
          FROM gl_code_combinations gcc, gl_ledgers gl
         WHERE 1 = 1
           AND gl.ledger_category_code = 'PRIMARY'
           AND gl.short_name = p_soc
           AND gl.chart_of_accounts_id = gcc.chart_of_accounts_id
           AND gcc.segment1 = p_soc
           AND gcc.segment2 = p_cdg
           AND gcc.segment3 = g_segment3_client
           AND gcc.segment4 = g_segment4_client
           AND gcc.segment5 = '0'
           AND gcc.segment6 = '0'
           AND gcc.segment7 = '0'
           AND gcc.segment8 = '0'
           AND gcc.segment9 = '0'
           AND gcc.segment10 = '0'
              --< V1.9
           AND gcc.segment11 = '0'
           AND gcc.segment12 = '0'
        --> V1.9
        ;
      EXCEPTION

        WHEN OTHERS THEN
          Dka_Tools_Pkg.get_code_combination_id(p_soc,
                                                p_cdg,
                                                g_segment3_client,
                                                g_segment4_client,
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                gl_id_rec,
                                                g_buf,
                                                g_ret);
          IF g_ret != 0 THEN
            Fnd_File.put_line(Fnd_File.LOG, g_buf);
            RAISE erreur;
          END IF;
      END;

      BEGIN
        SELECT gcc.code_combination_id
          INTO gl_id_rev
          FROM gl_code_combinations gcc, gl_ledgers gl
         WHERE 1 = 1
           AND gl.ledger_category_code = 'PRIMARY'
           AND gl.short_name = p_soc
           AND gl.chart_of_accounts_id = gcc.chart_of_accounts_id
           AND gcc.segment1 = p_soc
           AND gcc.segment2 = p_cdg
           AND gcc.segment3 = g_segment3_produit
           AND gcc.segment4 = g_segment4_produit
           AND gcc.segment5 = '0'
           AND gcc.segment6 = '0'
           AND gcc.segment7 = '0'
           AND gcc.segment8 = '0'
           AND gcc.segment9 = '0'
           AND gcc.segment10 = '0'
              --< V1.9
           AND gcc.segment11 = '0'
           AND gcc.segment12 = '0'
        --> V1.9
        ;
      EXCEPTION
        WHEN OTHERS THEN
          Dka_Tools_Pkg.get_code_combination_id(p_soc,
                                                p_cdg,
                                                g_segment3_produit,
                                                g_segment4_produit,
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                gl_id_rev,
                                                g_buf,
                                                g_ret);
          IF g_ret != 0 THEN
            Fnd_File.put_line(Fnd_File.LOG, g_buf);
            RAISE erreur;
          END IF;
      END;

    END IF; --IF partner_code NULL

  END get_gl_id;

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
   * p_file_name       Nom du fichier à charger
   * p_errbuf          Retour de message éventuel
   * p_retcode         Statut du traitement en sortie
   *
   ************************************************************************
   */
  PROCEDURE Launch_Loader(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
    v_phase      VARCHAR2(100);
    v_status     VARCHAR2(100);
    v_dev_phase  VARCHAR2(100);
    v_dev_status VARCHAR2(100);
    v_message    VARCHAR2(100);
    b_result     BOOLEAN;

  BEGIN
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début Launch_Loader');
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Lancement de chargement du fichier dans la table d''interface spécifique : ');

    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT, 'CHARGEMENT DU FICHIER :');
    fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
    ------------------------------------------------------
    -- Lancement du traitement de chargement du fichier --
    ------------------------------------------------------
    -- Positionnement des options d'impression
    b_result := fnd_request.set_print_options(printer => gv_printer,
                                              copies  => g_number_of_copies);
    -- Lancement du traitement
    g_loader_request_id := Fnd_Request.submit_request('DKA' -- APPL
                                                     ,
                                                      'DKA_LOADER_REPARCLIIMP' -- PROG
                                                     ,
                                                      NULL -- PROGRAM_NAME
                                                     ,
                                                      NULL -- START
                                                     ,
                                                      FALSE -- SUB_REQUEST
                                                      );

    IF g_loader_request_id = 0 THEN
      p_retcode := 2;
      fnd_file.put_line(fnd_file.LOG,
                        'ERREUR : Le traitement de chargement du fichier a échoué' ||
                        CHR(10) || 'PROGRAMME  : DKA_LOADER_REPARCLIIMP' ||
                        CHR(10));
      Fnd_File.put_line(Fnd_File.OUTPUT,
                        '====> ERREUR : Le traitement de chargement du fichier a échoué');
    ELSE
      COMMIT;
      Fnd_File.put_line(Fnd_File.LOG,
                        '=> LOAD REQUEST ID= ' || g_loader_request_id);
      Fnd_File.put_line(Fnd_File.OUTPUT,
                        '. Numéro du traitement de chargement du fichier : ' ||
                        g_loader_request_id);

      -- Attente de la fin du traitement
      IF NOT (Fnd_Concurrent.wait_for_request(g_loader_request_id,
                                              g_tempo,
                                              0,
                                              v_phase,
                                              v_status,
                                              v_dev_phase,
                                              v_dev_status,
                                              v_message)) THEN
        p_errbuf := v_Message;
        Fnd_file.put_line(Fnd_file.log,
                          'ERREUR : Attente de la fin du programme de chargement du fichier dépassée : Fin du traitement' ||
                          CHR(10) || 'MESSAGE : ' || v_Message || CHR(10));
      END IF;

      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
        Fnd_File.put_line(Fnd_File.LOG,
                          'COMPLETION= ' || v_dev_phase || '/' ||
                          v_dev_status);
        Fnd_File.put_line(Fnd_File.OUTPUT,
                          '. Statut de fin : ' || v_phase || '/' ||
                          v_status);

        UPDATE DKA_CLIENTS_TMP
           SET load_request_id = g_loader_request_id
         WHERE load_request_id IS NULL;

        SELECT COUNT(*)
          INTO g_summary.loaded_rows_cli
          FROM DKA_CLIENTS_TMP
         WHERE load_request_id = g_loader_request_id;
        Fnd_File.put_line(Fnd_File.LOG,
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                          ' Nbre enregistrements charges clients => ' ||
                          g_summary.loaded_rows_cli);

        UPDATE DKA_RECOUVREMENTS_TMP
           SET load_request_id = g_loader_request_id
         WHERE load_request_id IS NULL;

        SELECT COUNT(*)
          INTO g_summary.loaded_rows_rec
          FROM DKA_RECOUVREMENTS_TMP
         WHERE load_request_id = g_loader_request_id;
        Fnd_File.put_line(Fnd_File.LOG,
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                          ' Nbre enregistrements charges chargés de recouvrements => ' ||
                          g_summary.loaded_rows_rec);

      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
        Fnd_File.put_line(Fnd_File.LOG,
                          'Fin du traitement de chargement en warning ' ||
                          g_loader_request_id);
        p_retcode := 1;

      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
        p_retcode := 2;
        p_errbuf  := 'ERREUR : Fin anormale du traitement de chargement : ' ||
                     v_Message;

        fnd_file.put_line(fnd_file.LOG,
                          'ERREUR : Fin anormale du traitement de chargement ' ||
                          g_loader_request_id || CHR(10) ||
                          'Phase/Statut : ' || v_dev_phase || '/' ||
                          v_dev_status || CHR(10) || 'MESSAGE : ' ||
                          v_message || CHR(10));
        Fnd_File.put_line(Fnd_File.OUTPUT,
                          '===> ERREUR : Fin anormale du traitement de chargement ' ||
                          g_loader_request_id);
      END IF;

    END IF;

    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin Launch_Loader');

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'LAUNCH_LOADER : ' || SQLERRM;
      Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure Launch_Loader : EXCEPTION OTHERS ');
  END Launch_Loader;

  /*
   *************************************************************************
   * PROCEDURE NAME : validate_data
   *
   * DESCRIPTION
   *  Procédure de transcodification et de validation des données
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE validate_data(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

    CURSOR cur_clients IS
      SELECT *
        FROM DKA_CLIENTS_TMP
       WHERE LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
         AND STATUT IS NULL
         FOR UPDATE OF STATUT, PARTNER_CODE, CUSTOMER_CATEGORY, RECEIPT_METHOD_NAME, COLLECTOR, SOC;

    CURSOR cur_rec IS
      SELECT *
        FROM DKA_RECOUVREMENTS_TMP
       WHERE LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
         AND STATUT IS NULL
         FOR UPDATE OF STATUT, CDG;

    CURSOR cur_rec_tmp IS
      SELECT *
        FROM DKA_RECOUVREMENTS_TMP
       WHERE LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
         AND STATUT IS NULL
            --< V1.9
         AND CDG = 'GFK'
      --> V1.9
         FOR UPDATE OF collector;

    CURSOR cur_clients_err IS
      SELECT DISTINCT customer_number
        FROM DKA_CLIENTS_TMP
       WHERE LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
         AND STATUT = 'E';

    CURSOR cur_rec_err IS
      SELECT DISTINCT customer_number
        FROM DKA_RECOUVREMENTS_TMP
       WHERE LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
         AND STATUT = 'E';

    v_flag_erreur       BOOLEAN := FALSE;
    v_flag_erreur_rec   BOOLEAN := FALSE;
    v_rec               VARCHAR2(10);
    v_exists            VARCHAR2(10);
    v_collector         VARCHAR2(10);
    v_collector_tmp     VARCHAR2(10);
    v_region            VARCHAR2(10);
    v_test              VARCHAR2(10);
    v_soc               VARCHAR2(4);
    v_partner_code      VARCHAR2(10);
    v_receipt_method    VARCHAR2(30);
    v_customer_category VARCHAR2(30);
    v_user_id           NUMBER;

    v_bank_name   VARCHAR2(150);
    v_branch_name VARCHAR2(150);

  BEGIN

    v_user_id := FND_PROFILE.VALUE('USER_ID');

    -----------------------------------------------------------------------------
    --
    -- Parcours du curseur temporaire des recouvrements
    --

    FOR rec in cur_rec_tmp LOOP

      -- Modification temporaire du collector des régions GFK

      IF rec.cdg = 'GFK' THEN

        BEGIN
          SELECT collector
            INTO v_collector_tmp
            FROM DKA_RECOUVREMENTS_TMP
           WHERE customer_number = rec.customer_number
             AND cdg = 'DOS'
                --< V1.9
             AND load_request_id = g_loader_request_id
          --> V1.9
          ;

          UPDATE DKA_RECOUVREMENTS_TMP
             SET collector = v_collector_tmp
           WHERE CURRENT OF cur_rec_tmp
          --WHERE   customer_number = client.customer_number
          --AND     cdg = 'GFK'
          ;

        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;

      END IF;

    END LOOP;

    -----------------------------------------------------------------------------
    --
    --Parcours du curseur des clients et validation des données
    --

    FOR client IN cur_clients LOOP
      v_flag_erreur := FALSE;
      -- Mise à jour du partner_code

      -- V1.16 09/11/2017      NBO artf2274489 - REP002 - Il y a des rejets dans l'open-interface des modes de paiement
      v_partner_code := client.partner_code;

      IF client.partner_code IS NOT NULL
        --< V1.9
         AND client.partner_code NOT LIKE 'XXX%'
      --> V1.9
       THEN
        v_partner_code := 'XXX' || client.partner_code;
      END IF;

      --< V1.11
      -- Contrôle de l'existence du partner_code
      IF client.partner_code IS NOT NULL THEN
        BEGIN
              SELECT 'EXISTS'
                INTO v_exists
                FROM fnd_flex_values ffv, fnd_flex_value_sets ffvs
               WHERE ffv.flex_value_set_id = ffvs.flex_value_set_id
                 AND ffvs.flex_value_set_name = 'DAOPCCF_INTERCO'
                 AND ffv.flex_value = v_partner_code
                 AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            v_flag_erreur := TRUE;
            dka_tools_pkg.ins_prog_message(g_request_id,
                                           g_nom_traitement,
                                           'ETL',
                                           'DKA_CLIENTS_TMP',
                                           client.logical_line_num,
                                           'PARTNER_CODE',
                                           v_partner_code,
                                           'E',
                                           'La code partner n''existe pas dans le référentiel Dalkia.'
                                           );
        END;
       END IF;
       --> V1.11

      -- Transcodification de la catégorie
      DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '007_CATEGORIES_CLIENT',
                                      pv_column_01    => client.customer_category,
                                      pv_out_01       => v_customer_category);

      --<artf2081483
      IF v_customer_category IS NULL THEN
        v_flag_erreur := TRUE;

        dka_tools_pkg.ins_prog_message(g_request_id,
                                       g_nom_traitement,
                                       'ETL',
                                       'DKA_CLIENTS_TMP',
                                       client.logical_line_num,
                                       'CUSTOMER_CATEGORY',
                                       v_customer_category,
                                       'E',
                                       'La catégorie client est obligatoire pour le SPE171'
                                       );

      END IF;

      IF client.customer_class IS NULL THEN
        v_flag_erreur := TRUE;

        dka_tools_pkg.ins_prog_message(g_request_id,
                                       g_nom_traitement,
                                       'ETL',
                                       'DKA_CLIENTS_TMP',
                                       client.logical_line_num,
                                       'CUSTOMER_CLASS',
                                       client.customer_class,
                                       'E',
                                       'La classe client est obligatoire pour le SPE171'
                                       );

      END IF;
      -->artf2081483

      -- Transcodification de la région
      DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '008_REGIONS',
                                      pv_column_01    => client.CDG,
                                      pv_out_01       => v_region);

      BEGIN

        SELECT 'EXISTS'
          INTO v_exists
          FROM hr_operating_units
         WHERE substr(name, 1, 3) = v_region
           AND sysdate between nvl(date_from, sysdate) and nvl(date_to, sysdate) --artf2084473
           AND ROWNUM = 1;

      EXCEPTION
        WHEN OTHERS THEN
          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         g_nom_traitement,
                                         'ETL',
                                         'DKA_CLIENTS_TMP',
                                         client.logical_line_num,
                                         'CDG',
                                         v_region,
                                         'E',
                                         'La région n''existe pas dans le référentiel Dalkia.' -- Numéro client : '||client.customer_number
                                         );

      END;

      IF client.receipt_method_name IS NOT NULL THEN

        -- Transcodification de la méthode de paiement
        DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '017_RECEIPT_METHOD',
                                        pv_column_01    => client.receipt_method_name,
                                        pv_out_01       => v_receipt_method);

        BEGIN

          SELECT 'EXISTS'
            INTO v_exists
            FROM AR_RECEIPT_METHODS
           WHERE name = v_receipt_method
             AND ROWNUM = 1;

        EXCEPTION
          WHEN OTHERS THEN
            v_flag_erreur := TRUE;

            dka_tools_pkg.ins_prog_message(g_request_id,
                                           g_nom_traitement,
                                           'ETL',
                                           'DKA_CLIENTS_TMP',
                                           client.logical_line_num,
                                           'RECEIPT_METHOD_NAME',
                                           client.receipt_method_name,
                                           'E',
                                           'Le mode de règlement n''est pas défini dans AR_RECEIPT_METHODS.' -- Numéro client : '||client.customer_number
                                           );

        END;

      END IF;

      IF client.customer_dka_bank_name IS NOT NULL THEN

        -- Récupération de la société
        v_soc := NVL(client.SOC, SUBSTR(client.customer_dka_bank_name, 1, 4));

      END IF;

      --< V1.9
      IF client.profil_class IS NOT NULL THEN

        BEGIN

          SELECT 'EXISTS'
            INTO v_exists
            FROM AR_CUSTOMER_PROFILE_CLASSES_V
           WHERE profile_class_name = client.profil_class
             AND ROWNUM = 1;

        EXCEPTION
          WHEN OTHERS THEN
            v_flag_erreur := TRUE;

            dka_tools_pkg.ins_prog_message(g_request_id,
                                           g_nom_traitement,
                                           'ETL',
                                           'DKA_CLIENTS_TMP',
                                           client.logical_line_num,
                                           'PROFILE_CLASS_NAME',
                                           client.receipt_method_name,
                                           'E',
                                           'La classe de profil n''est pas défini dans AR_CUSTOMER_PROFILE_CLASSES.');

        END;

      END IF;
      --> V1.9

      -- Mise à jour de la table des clients
      IF NOT v_flag_erreur THEN

        UPDATE DKA_CLIENTS_TMP
           SET STATUT              = 'S',
               PARTNER_CODE        = v_partner_code,
               CUSTOMER_CATEGORY   = v_customer_category,
               RECEIPT_METHOD_NAME = v_receipt_method,
               CDG                 = v_region,
               SOC                 = v_soc,
               LAST_UPDATED_BY     = v_user_id,
               LAST_UPDATE_DATE    = sysdate
         WHERE CURRENT OF cur_clients;
      ELSE
        -- en cas d'erreur

        g_summary.rejected_rows_cli := g_summary.rejected_rows_cli + 1;

        UPDATE DKA_CLIENTS_TMP
           SET STATUT           = 'E',
               LAST_UPDATED_BY  = v_user_id,
               LAST_UPDATE_DATE = sysdate
         WHERE CURRENT OF cur_clients;

        UPDATE DKA_RECOUVREMENTS_TMP
           SET STATUT           = 'E',
               LAST_UPDATED_BY  = v_user_id,
               LAST_UPDATE_DATE = sysdate
         WHERE customer_number = client.customer_number
           AND CDG = client.CDG;

      END IF;

      v_partner_code      := NULL;
      v_customer_category := NULL;
      v_receipt_method    := NULL;
      v_region            := NULL;
      v_soc               := NULL;

    END LOOP; -- Fin curseur clients

    --< v 1.1
    -----------------------------------------------------------------------------
    --
    -- Parcours du curseur du chargé de recouvrement
    --

    FOR rec IN cur_rec LOOP

      v_flag_erreur_rec := FALSE;

      BEGIN
        SELECT name
          INTO v_collector
          FROM ar_collectors
         WHERE name = rec.collector
           AND ROWNUM = 1;

      EXCEPTION
        WHEN OTHERS THEN
          v_flag_erreur_rec := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         g_nom_traitement,
                                         'ETL',
                                         'DKA_RECOUVREMENTS_TMP',
                                         rec.logical_line_num,
                                         'COLLECTOR',
                                         rec.collector,
                                         'E',
                                         'Le collector n''existe pas dans la table AR_COLLECTORS');

      END;

      -- Transcodification de la région
      DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '008_REGIONS',
                                      pv_column_01    => rec.CDG,
                                      pv_out_01       => v_region);

      BEGIN

        SELECT 'EXISTS'
          INTO v_exists
          FROM hr_operating_units
         WHERE substr(name, 1, 3) = v_region
           AND sysdate between nvl(date_from, sysdate) and nvl(date_to, sysdate) --artf2084473
           AND ROWNUM = 1;

      EXCEPTION
        WHEN OTHERS THEN
          v_flag_erreur_rec := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         g_nom_traitement,
                                         'ETL',
                                         'DKA_RECOUVREMENTS_TMP',
                                         rec.logical_line_num,
                                         'CDG',
                                         v_region,
                                         'E',
                                         'La région n''existe pas dans le référentiel Dalkia.' -- Numéro client : '||rec.customer_number
                                         );

      END;

      -- Mise à jour de la table des chargés de recouvrement
      IF NOT v_flag_erreur_rec THEN

        UPDATE DKA_RECOUVREMENTS_TMP
           SET STATUT           = 'S',
               CDG              = v_region,
               LAST_UPDATED_BY  = v_user_id,
               LAST_UPDATE_DATE = sysdate
         WHERE CURRENT OF cur_rec;

        UPDATE DKA_CLIENTS_TMP
           SET COLLECTOR        = v_collector,
               LAST_UPDATED_BY  = v_user_id,
               LAST_UPDATE_DATE = sysdate
         WHERE customer_number = rec.customer_number
           AND CDG = rec.CDG
              --< V1.9
           AND LOAD_REQUEST_ID = g_loader_request_id
        --> V1.9
        ;
      ELSE
        -- en cas d'erreur
        g_summary.rejected_rows_rec := g_summary.rejected_rows_rec + 1;

        UPDATE DKA_RECOUVREMENTS_TMP
           SET STATUT           = 'E',
               LAST_UPDATED_BY  = v_user_id,
               LAST_UPDATE_DATE = sysdate
         WHERE CURRENT OF cur_rec;

        UPDATE DKA_CLIENTS_TMP
           SET STATUT           = 'E',
               LAST_UPDATED_BY  = v_user_id,
               LAST_UPDATE_DATE = sysdate
         WHERE customer_number = rec.customer_number
           AND CDG = rec.CDG
              --< V1.9
           AND LOAD_REQUEST_ID = g_loader_request_id
        --> V1.9
        ;

        g_summary.rejected_rows_cli := g_summary.rejected_rows_cli +
                                       SQL%ROWCOUNT;

      END IF;

    END LOOP; -- Fin curseur recouvrement
    --> v 1.1

    -- Parcours des enregistrements en erreur afin de mettre en erreur l'ensemble des lignes du client de l'enregistrement
    --< v 1.1
    FOR client IN cur_clients_err LOOP

      UPDATE DKA_CLIENTS_TMP
         SET STATUT           = 'E',
             LAST_UPDATED_BY  = v_user_id,
             LAST_UPDATE_DATE = sysdate
       WHERE customer_number = client.customer_number
            --< V1.9
         AND LOAD_REQUEST_ID = g_loader_request_id
      --> V1.9
      ;
      UPDATE DKA_RECOUVREMENTS_TMP
         SET STATUT           = 'E',
             LAST_UPDATED_BY  = v_user_id,
             LAST_UPDATE_DATE = sysdate
       WHERE customer_number = client.customer_number;

    END LOOP;

    FOR rec IN cur_rec_err LOOP

      UPDATE DKA_RECOUVREMENTS_TMP
         SET STATUT           = 'E',
             LAST_UPDATED_BY  = v_user_id,
             LAST_UPDATE_DATE = sysdate
       WHERE customer_number = rec.customer_number;
      UPDATE DKA_CLIENTS_TMP
         SET STATUT           = 'E',
             LAST_UPDATED_BY  = v_user_id,
             LAST_UPDATE_DATE = sysdate
       WHERE customer_number = rec.customer_number
            --< V1.9
         AND LOAD_REQUEST_ID = g_loader_request_id
      --> V1.9
      ;
    END LOOP;
    --> v 1.1

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

  /*
   *************************************************************************
   * PROCEDURE NAME : import_data
   *
   * DESCRIPTION
   *  Procédure d'importation des données
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE import_data(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

    CURSOR cur_clients IS
      SELECT DISTINCT CUSTOMER_NAME,
                      CUSTOMER_NUMBER,
                      INTRACOM_NUMBER,
                      CUSTOMER_STATUS,
                      CUSTOMER_CATEGORY,
                      CUSTOMER_CLASS,
                      NOM1,
                      NOM2,
                      ADDRESS1,
                      ADDRESS2,
                      CUSTOMER_TYPE,
                      CITY,
                      POSTAL_CODE,
                      COUNTRY,
                      ADDRESS_STATUS,
                      PROFIL_CLASS,
                      PARTNER_CODE,
                      LOCATION,
                      CODE_CLIENT_DESTINATAIRE,
                      ADRESSE_CLIENT_DESTINATAIRE,
                      RECIPIENT_ONLY_FLAG,
                      ANAEL_REF,
                      SOCIETY,
                      INSERT_UPDATE_FLAG,
                      ETL_STATUS,
                      PAYMENT_TERMS,
                      COLLECTOR,
                      CDG,
                      SIRET,
                      ORG_ID
        FROM DKA_CLIENTS_TMP
       WHERE LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
         AND STATUT = 'S';

    CURSOR cur_uo(v_cdg VARCHAR2) IS
      SELECT organization_id, name
        FROM hr_operating_units
       WHERE name LIKE v_cdg || '%'
         AND sysdate between nvl(date_from, sysdate) and nvl(date_to, sysdate) --artf2084473
         ;

    CURSOR cur_contact(v_customer_number VARCHAR2, v_cdg VARCHAR2, v_location VARCHAR2) IS
      SELECT DISTINCT CUSTOMER_NUMBER,
                      LAST_NAME,
                      FIRST_NAME,
                      CONTACT_NUMBER,
                      ORIG_SYSTEM_REFERENCE_CTC,
                      PHONE_NUMBER,
                      PHONE_TYPE,
                      CONTACT_POINT_TYPE,
                      ORIG_SYSTEM_REFERENCE_PH,
                      CDG,
                      LOCATION
        FROM DKA_CLIENTS_TMP
       WHERE LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
         AND customer_number = v_customer_number
         AND contact_number IS NOT NULL
         AND cdg = v_cdg
         AND location = v_location
         AND STATUT = 'S';

    --< V1.2
    --CURSOR cur_bank(v_customer_number VARCHAR2, v_cdg VARCHAR2, v_location VARCHAR2) IS
    --  SELECT distinct customer_name,
    --                  customer_number,
    --                  bank_name,
    --                  bank_num,
    --                  bank_branch_name,
    --                  bank_number,
    --                  country_bank,
    --                  bank_account_name,
    --                  bank_account_num,
    --                  currency_code,
    --                  iban_number,
    --                  check_digits,
    --                  bank_start_date,
    --                  bank_primary_flag,
    --                  location,
    --                  CDG,
    --                  SOC
    --    FROM DKA_CLIENTS_TMP
    --   WHERE LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
    --     AND customer_number = v_customer_number
    --     AND bank_account_num IS NOT NULL
    --     AND cdg = v_cdg
    --     AND location = v_location
    --     AND STATUT = 'S';
    --> V1.2

    CURSOR cur_method(v_customer_number VARCHAR2, v_cdg VARCHAR2, v_location VARCHAR2) IS
      /*SELECT DISTINCT CUSTOMER_NAME,
                      CUSTOMER_NUMBER,
                      RECEIPT_METHOD_NAME,
                      MIN(RECEIPT_START_DATE) RECEIPT_START_DATE,
                      MAX(RECEIPT_PRIMARY_FLAG) RECEIPT_PRIMARY_FLAG,
                      CDG,
                      SOC
        FROM DKA_CLIENTS_TMP
       WHERE LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
         AND customer_number = v_customer_number
         AND receipt_method_name IS NOT NULL
         AND CDG = v_cdg
         AND location = v_location
         AND STATUT = 'S'
       GROUP BY CUSTOMER_NAME,
                CUSTOMER_NUMBER,
                RECEIPT_METHOD_NAME,
                CDG,
                SOC;*/
  -- V1.15 28/07/2017      NBO artf2204067 - REP002 - Il y a des rejets dans l'open-interface des modes de paiement
        SELECT DISTINCT v.*
        FROM (SELECT customer_name,
                     customer_number,
                     receipt_method_name,
                     MIN(receipt_start_date) over(PARTITION BY customer_number ORDER BY cdg, soc) min_receipt_start_date,
                     receipt_start_date,
                     MAX(receipt_primary_flag) over(PARTITION BY customer_number ORDER BY cdg, soc) receipt_primary_flag,
                     COUNT(1) over(ORDER BY cdg) nb_ligne,
                     row_number() over(ORDER BY cdg, start_date) num_ligne,
                     cdg,
                     soc
                FROM dka_clients_tmp
               WHERE LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
                 AND customer_number = v_customer_number
                 AND receipt_method_name IS NOT NULL
                 AND CDG = v_cdg
                  AND location = v_location
                  AND STATUT = 'S'
              ) v
         ORDER BY v.receipt_start_date DESC;


    CURSOR cur_profil IS
    --< V1.9
    --         SELECT a.customer_number
    --          ,MIN(a.insert_update_flag) insert_update_flag
    --          ,MIN(a.profil_class) profil_class
    --          ,MIN(c.organization_id) org_id
    --          FROM DKA_CLIENTS_TMP a
    --          ,hr_operating_units c
    --          WHERE c.name LIKE a.cdg||'%'
    --          AND sysdate between nvl(c.date_from, sysdate) and nvl(c.date_to, sysdate) --artf2084473
    --          AND a.LOAD_REQUEST_ID = g_loader_request_id--DECODE( g_loader_request_id, -1, a.load_request_id, g_loader_request_id)
    --          AND a.STATUT = 'S'
    --          GROUP BY  a.customer_number
    WITH DKA_CUSTOMER_PROFILE AS(
      SELECT a.customer_number,
             a.insert_update_flag,
             a.profil_class,
             c.organization_id org_id,
             a.cdg,
             row_number() over(partition by a.customer_number, a.insert_update_flag, a.profil_class order by a.customer_number, a.cdg, c.organization_id) rn
        FROM DKA_CLIENTS_TMP a,
             HR_OPERATING_UNITS c
       WHERE c.name LIKE a.cdg || '%'
         AND sysdate between nvl(c.date_from, sysdate) and nvl(c.date_to, sysdate) --artf2084473
         AND a.LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, a.load_request_id, g_loader_request_id)
         AND a.STATUT = 'S')
        SELECT customer_number,
         insert_update_flag,
         profil_class,
         org_id
          FROM DKA_CUSTOMER_PROFILE
         WHERE rn = 1
         ORDER BY customer_number
        --> V1.9
        ;


    v_org_id         NUMBER;
    v_receipt_method VARCHAR2(30);
    v_partner_code   VARCHAR2(30);
    v_region         VARCHAR2(3);
    v_resp_id        NUMBER;
    v_resp_appl_id   NUMBER;
    v_user_id        NUMBER;

    v_errbuf     VARCHAR2(2500);
    v_retcode    NUMBER;
    v_phase      VARCHAR2(100);
    v_status     VARCHAR2(100);
    v_dev_phase  VARCHAR2(100);
    v_dev_status VARCHAR2(100);
    v_message    VARCHAR2(100);

    b_result     BOOLEAN;
    b            NUMBER;

    v_count_customer NUMBER;
    v_count_profil   NUMBER;
    v_count_bank     NUMBER;
    v_count_method   NUMBER;
    v_count_phone    NUMBER;

    v_id_rec NUMBER;
    v_id_rev NUMBER;
    
    v_receipt_start_date DATE;
    v_receipt_end_date DATE;
    
    TYPE num_traitement IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    num_trait_list num_traitement;

    v_cpt INTEGER := 0;

  BEGIN

    v_user_id      := FND_PROFILE.VALUE('USER_ID');
    v_resp_id      := FND_PROFILE.VALUE('RESP_ID');
    v_resp_appl_id := FND_PROFILE.VALUE('RESP_APPL_ID');

    Fnd_File.put_line(Fnd_File.LOG,
                      to_char(sysdate, 'YYYYMMDD HH24:MI:SS') ||
                      'Parcours du curseur des clients. Insertion des données dans les tables d''interfaces.');
    FOR client IN cur_clients LOOP

      BEGIN
        --Fnd_File.put_line(Fnd_File.LOG, '>>>>-------------------------------------------------------------------------------------------<<<<<<<');
        --Fnd_File.put_line(Fnd_File.LOG, '>>>>-------------------------------------------------------------------------------------------<<<<<<<');

        --Fnd_File.put_line(Fnd_File.LOG,CHR(10) || '---------------------------------------------------------------------------');
        --Fnd_File.put_line(Fnd_File.LOG,to_char(sysdate, 'YYYYMMDD HH24:MI:SS') || ' - Traitement du client numéro : ' || client.customer_number || '. CDG-LOCATION : ' || client.cdg || '-' || client.location || CHR(10));

        --Fnd_File.put_line(Fnd_File.LOG, '>>>>-------------------------------------------------------------------------------------------<<<<<<<');
        --Fnd_File.put_line(Fnd_File.LOG, '>>>>-------------------------------------------------------------------------------------------<<<<<<<'||CHR(10));

        FOR uo IN cur_uo(client.CDG) LOOP

          BEGIN

            get_gl_id(client.cdg,
                      SUBSTR(uo.name, 4),
                      client.partner_code,
                      v_id_rec,
                      v_id_rev);

          EXCEPTION
            WHEN OTHERS THEN
              --Fnd_File.put_line(Fnd_File.LOG, 'Compte client ou produit introuvable');
              v_id_rec := NULL;
              v_id_rev := NULL;

              dka_tools_pkg.ins_prog_message(g_request_id,
                                             g_nom_traitement,
                                             'OI',
                                             'DKA_CLIENTS_TMP',
                                             -1,
                                             'GET_GL_ID',
                                             client.partner_code,
                                             'W',
                                             SQLERRM);
          END;
          /*
          Fnd_File.put_line(Fnd_File.LOG, 'GL_ID_REC : '||TO_CHAR(v_id_rec));
          Fnd_File.put_line(Fnd_File.LOG, 'GL_ID_REV : '||TO_CHAR(v_id_rev));*/
          Fnd_File.put_line(Fnd_File.LOG, 'Insertion dans les clients : ' || client.customer_number);
          
          --Fnd_File.put_line(Fnd_File.LOG, 'Insertion dans la table RA_CUSTOMERS_INTERFACE_ALL.');
          INSERT INTO RA_CUSTOMERS_INTERFACE_ALL
            (ORIG_SYSTEM_CUSTOMER_REF,
             ORIG_SYSTEM_ADDRESS_REF,
             INSERT_UPDATE_FLAG,
             CUSTOMER_NAME,
             CUSTOMER_CATEGORY_CODE,
             CUSTOMER_CLASS_CODE,
             CUSTOMER_NUMBER,
             CUSTOMER_STATUS,
             CUSTOMER_TYPE,
             GL_ID_REC,
             GL_ID_REV,
             CUST_TAX_REFERENCE,
             CITY,
             COUNTRY,
             POSTAL_CODE
             --< V1.9
            ,
             STATE,
             COUNTY
             --> V1.9
            ,
             LAST_UPDATED_BY,
             LAST_UPDATE_DATE,
             CREATED_BY,
             CREATION_DATE,
             VALIDATED_FLAG,
             PRIMARY_SITE_USE_FLAG,
             LOCATION,
             SITE_USE_CODE,
             ADDRESS1,
             ADDRESS2,
             ADDRESS3,
             ADDRESS4,
             ADDRESS_ATTRIBUTE1,
             ADDRESS_ATTRIBUTE2,
             ADDRESS_ATTRIBUTE3,
             ADDRESS_ATTRIBUTE8,
             ADDRESS_ATTRIBUTE11
             --,SITE_USE_ATTRIBUTE11
            ,
             SITE_USE_ATTRIBUTE16,
             ORG_ID)
          VALUES
            (client.customer_number,
             client.cdg || '-' || client.location,
             client.INSERT_UPDATE_FLAG,
             client.CUSTOMER_NAME,
             client.CUSTOMER_CATEGORY,
             client.CUSTOMER_CLASS,
             client.CUSTOMER_NUMBER,
             client.CUSTOMER_STATUS,
             client.CUSTOMER_TYPE,
             v_id_rec,
             v_id_rev,  -- V1.12
             --NULL,    -- V1.12
             client.intracom_number,
             client.CITY,
             client.COUNTRY,
             client.postal_code
             --< V1.9
            ,
             case when client.COUNTRY = 'US' then 'NY' else NULL end,
             case when client.COUNTRY = 'US' then '.' else NULL end
             --> V1.9
            ,
             v_user_id,
             sysdate,
             v_user_id,
             sysdate,
             'Y',
             'N',
             client.location,
             'BILL_TO',
             client.nom1,
             client.nom2,
             client.address1,
             client.address2,
             client.code_client_destinataire,
             client.adresse_client_destinataire,
             client.anael_ref,
             client.partner_code,
             client.SIRET,
             client.recipient_only_flag,
             uo.organization_id);

          g_summary.loaded_rows_OI_cust := g_summary.loaded_rows_OI_cust + 1;

          --Fnd_File.put_line(Fnd_File.LOG, 'Insertion dans la table RA_CUSTOMER_PROFILES_INT_ALL.');
          INSERT INTO RA_CUSTOMER_PROFILES_INT_ALL
            (ORIG_SYSTEM_CUSTOMER_REF,
             ORIG_SYSTEM_ADDRESS_REF,
             COLLECTOR_NAME,
             VALIDATED_FLAG,
             INSERT_UPDATE_FLAG,
             CUSTOMER_PROFILE_CLASS_NAME,
             CREDIT_HOLD,
             LAST_UPDATED_BY,
             LAST_UPDATE_DATE,
             CREATED_BY,
             CREATION_DATE,
             ORG_ID)
          VALUES
            (client.customer_number,
             client.cdg || '-' || client.location
             --,ou.collector
            ,
             client.collector,
             'Y',
             client.INSERT_UPDATE_FLAG,
             client.PROFIL_CLASS,
             'N',
             v_user_id,
             sysdate,
             v_user_id,
             sysdate,
             uo.organization_id);

          g_summary.loaded_rows_OI_prof := g_summary.loaded_rows_OI_prof + 1;

          --Fnd_File.put_line(Fnd_File.LOG, '-------------------------------------');
          --Fnd_File.put_line(Fnd_File.LOG, to_char(sysdate, 'YYYYMMDD HH24:MI:SS')||' - Traitement des contacts : ');
          -- Insertion des contacts
          FOR contact IN cur_contact(client.customer_number,
                                     client.CDG,
                                     client.location) LOOP
            --IF contact.CDG = client.CDG AND contact.location = client.location THEN
            --Fnd_File.put_line(Fnd_File.LOG, 'Insertion dans la table RA_CONTACT_PHONES_INT_ALL.');

            INSERT INTO RA_CONTACT_PHONES_INT_ALL
              (ORIG_SYSTEM_CONTACT_REF,
               ORIG_SYSTEM_TELEPHONE_REF,
               ORIG_SYSTEM_CUSTOMER_REF,
               ORIG_SYSTEM_ADDRESS_REF,
               INSERT_UPDATE_FLAG,
               LAST_UPDATED_BY,
               LAST_UPDATE_DATE,
               CREATED_BY,
               CREATION_DATE,
               CONTACT_FIRST_NAME,
               CONTACT_LAST_NAME,
               TELEPHONE,
               CONTACT_POINT_TYPE,
               TELEPHONE_TYPE,
               ORG_ID)
            VALUES
              (uo.name || '-' || contact.ORIG_SYSTEM_REFERENCE_CTC,
               decode(contact.ORIG_SYSTEM_REFERENCE_PH,
                      null,
                      null,
                      uo.name || '-' || contact.ORIG_SYSTEM_REFERENCE_PH),
               contact.customer_number,
               client.cdg || '-' || client.location,
               'I',
               v_user_id,
               sysdate,
               v_user_id,
               sysdate,
               contact.FIRST_NAME,
               contact.LAST_NAME,
               contact.PHONE_NUMBER,
               contact.CONTACT_POINT_TYPE,
               contact.PHONE_TYPE,
               uo.organization_id);

            g_summary.loaded_rows_OI_cont := g_summary.loaded_rows_OI_cont + 1;

          --END IF;
          END LOOP;

          --Fnd_File.put_line(Fnd_File.LOG, 'Fin de traitement des contacts.');
          --Fnd_File.put_line(Fnd_File.LOG, '-------------------------------------');

          --Fnd_File.put_line(Fnd_File.LOG, '-------------------------------------');
          --Fnd_File.put_line(Fnd_File.LOG, 'Traitement des banques : ');
          --FOR bank IN cur_bank (client.customer_number,client.CDG,client.location) LOOP -- V1.6

            --< V1.6
            /*
            Fnd_File.put_line(Fnd_File.LOG, 'Insertion dans la table RA_CUSTOMER_BANKS_INT_ALL.');

            INSERT INTO RA_CUSTOMER_BANKS_INT_ALL
            (
            ORIG_SYSTEM_CUSTOMER_REF
            ,ORIG_SYSTEM_ADDRESS_REF
            ,PRIMARY_FLAG
            ,START_DATE
            ,LAST_UPDATED_BY
            ,LAST_UPDATE_DATE
            ,CREATED_BY
            ,CREATION_DATE
            ,BANK_ACCOUNT_NAME
            ,BANK_ACCOUNT_CURRENCY_CODE
            ,BANK_ACCOUNT_NUM
            ,BANK_NAME
            ,BANK_BRANCH_NAME
            ,BANK_NUM
            ,BANK_NUMBER
            ,BANK_ACCOUNT_CHECK_DIGITS
            ,ORG_ID
            ,bank_home_country
            )
            VALUES
            (
            bank.customer_number
            ,bank.cdg||'-'||client.location
            ,bank.bank_primary_flag
            ,bank.bank_start_date
            ,v_user_id
            ,sysdate
            ,v_user_id
            ,sysdate
            ,bank.BANK_ACCOUNT_NAME
            ,bank.currency_code
            ,bank.BANK_ACCOUNT_NUM
            ,bank.BANK_NAME
            ,bank.bank_branch_name
            ,bank.bank_num
            ,bank.bank_number
            ,bank.check_digits
            ,uo.organization_id
            ,bank.country_bank
            );
            g_summary.loaded_rows_OI_bank := g_summary.loaded_rows_OI_bank + 1;
            */
            --> V1.6

          --END LOOP; -- Fin boucle curseur des banques -- V1.6
          --Fnd_File.put_line(Fnd_File.LOG, 'Fin de traitement des banques.');
          --Fnd_File.put_line(Fnd_File.LOG, '-------------------------------------');

          --Fnd_File.put_line(Fnd_File.LOG, '-------------------------------------');
          --Fnd_File.put_line(Fnd_File.LOG, to_char(sysdate, 'YYYYMMDD HH24:MI:SS')||' - Traitement des méthodes de paiement : ');
          FOR method IN cur_method(client.customer_number,
                                   client.CDG,
                                   client.location) LOOP

            -- IF method.CDG = client.CDG THEN
            IF method.CDG || method.SOC = uo.name OR method.SOC IS NULL THEN
              dka_tools_pkg.put_debug_message('Insertion Methode : ' || client.customer_number ||','||
                                   client.CDG ||','||
                                   client.location);
              -- >> V1.15 28/07/2017      NBO artf2204067 - REP002 - Il y a des rejets dans l'open-interface des modes de paiement
              IF method.nb_ligne > 1 AND method.num_ligne = 2 THEN
                 IF method.receipt_start_date = method.min_receipt_start_date THEN
                   v_receipt_start_date := method.receipt_start_date - 1;
                   v_receipt_end_date := method.receipt_start_date - 1;
                 ELSE
                   v_receipt_start_date := method.receipt_start_date;
                   v_receipt_end_date := method.receipt_start_date;
                 END IF;
              ELSE
                 v_receipt_start_date := method.receipt_start_date;
                 v_receipt_end_date :=  method.receipt_start_date;
              END IF;

              --Fnd_File.put_line(Fnd_File.LOG, 'Insertion dans la table RA_CUST_PAY_METHOD_INT_ALL.');
              INSERT INTO RA_CUST_PAY_METHOD_INT_ALL
                (ORIG_SYSTEM_CUSTOMER_REF,
                 ORIG_SYSTEM_ADDRESS_REF,
                 PAYMENT_METHOD_NAME,
                 PRIMARY_FLAG,
                 START_DATE,
                 END_DATE,
                 LAST_UPDATED_BY,
                 LAST_UPDATE_DATE,
                 CREATED_BY,
                 CREATION_DATE,
                 ORG_ID)
              VALUES
                (client.customer_number,
                 method.cdg || '-' || client.location,
                 method.receipt_method_name,
                 method.receipt_primary_flag,
                 v_receipt_start_date,
                 v_receipt_end_date,
                 v_user_id,
                 sysdate,
                 v_user_id,
                 sysdate,
                 uo.organization_id);
              -- << V1.15 28/07/2017      NBO artf2204067 - REP002 - Il y a des rejets dans l'open-interface des modes de paiement

              g_summary.loaded_rows_OI_meth := g_summary.loaded_rows_OI_meth + 1;

            END IF;
          END LOOP;
          --Fnd_File.put_line(Fnd_File.LOG, 'Fin de traitement des méthodes.');
          --Fnd_File.put_line(Fnd_File.LOG, '-------------------------------------');

        END LOOP; -- Fin curseur des unités opérationnelles

      EXCEPTION
        WHEN OTHERS THEN
          dka_tools_pkg.put_debug_message('--> Code erreur ' || SQLCODE ||
                                          ' - ' || SQLERRM);
          p_retcode := 1;
      END;

    END LOOP; -- Fin curseur des clients

    --Fnd_File.put_line(Fnd_File.LOG, '----------------------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.LOG,
                      to_char(sysdate, 'YYYYMMDD HH24:MI:SS') ||
                      ' - Insertion entete du profil dans la table RA_CUSTOMER_PROFILES_INT_ALL.');

    FOR profil IN cur_profil LOOP

      g_org_id_profil := profil.org_id; -- V1.8

      INSERT INTO RA_CUSTOMER_PROFILES_INT_ALL
        (ORIG_SYSTEM_CUSTOMER_REF,
         ORIG_SYSTEM_ADDRESS_REF,
         VALIDATED_FLAG,
         INSERT_UPDATE_FLAG,
         CUSTOMER_PROFILE_CLASS_NAME,
         CREDIT_HOLD,
         LAST_UPDATED_BY,
         LAST_UPDATE_DATE,
         CREATED_BY,
         CREATION_DATE,
         ORG_ID)
      VALUES
        (profil.customer_number,
         NULL,
         'Y',
         profil.insert_update_flag,
         profil.profil_class,
         'N',
         v_user_id,
         sysdate,
         v_user_id,
         sysdate,
         profil.org_id);

      g_summary.loaded_rows_OI_prof := g_summary.loaded_rows_OI_prof + 1;

      UPDATE DKA_CLIENTS_TMP
         SET STATUT           = 'T',
             LAST_UPDATED_BY  = v_user_id,
             LAST_UPDATE_DATE = sysdate
       WHERE customer_number = profil.customer_number
         AND LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
         AND STATUT != 'E';

      UPDATE DKA_RECOUVREMENTS_TMP
         SET STATUT           = 'T',
             LAST_UPDATED_BY  = v_user_id,
             LAST_UPDATE_DATE = sysdate
       WHERE customer_number = profil.customer_number
         AND LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
         AND STATUT != 'E';

    END LOOP;

    COMMIT;

    --< artf2084531
    Fnd_File.put_line(Fnd_File.LOG,
                      chr(10) ||
                      '----------------------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.LOG,
                      to_char(sysdate, 'YYYYMMDD HH24:MI:SS') ||
                      ' - Collecte des statisitiques des tables d''interface');

    FOR rec IN (  select  'AR' table_owner,'RA_CUSTOMERS_INTERFACE_ALL' table_name from RA_CUSTOMERS_INTERFACE_ALL where rownum = 1 union
                  select  'AR' table_owner,'RA_CUSTOMER_PROFILES_INT_ALL' table_name from RA_CUSTOMER_PROFILES_INT_ALL where rownum = 1 union
                  select  'AR' table_owner,'RA_CONTACT_PHONES_INT_ALL' table_name from RA_CONTACT_PHONES_INT_ALL where rownum = 1 union
                  select  'AR' table_owner,'RA_CUST_PAY_METHOD_INT_ALL' table_name from RA_CUST_PAY_METHOD_INT_ALL where rownum = 1
                ) LOOP

      g_int_request_id := Fnd_Request.submit_request('FND', -- APPL
                                                     'FNDGTST', -- PROG
                                                     NULL, -- DESCRIPTION
                                                     NULL, -- START
                                                     FALSE, -- SUB_REQUEST
                                                     rec.table_owner,   --Table Owner
                                                     rec.table_name,    --Table Name
                                                     30,                --Estimate Percent
                                                     NULL,              --Degree of parallelism
                                                     NULL,              --Partition Name
                                                     'NOBACKUP',        --Backup Flag
                                                     'DEFAULT',         --Granularity
                                                     'LASTRUN',         --History Mode
                                                     'Y'                --Invalidate Dependent Cursors
                                                     );

      IF g_int_request_id = 0 THEN
        p_retcode := 2;
        fnd_file.put_line(fnd_file.LOG,
                          'ERREUR : Le traitement de de collecte des statistiques a échoué' ||
                          CHR(10) || 'PROGRAMME  : FNDGTST' || CHR(10));
        Fnd_File.put_line(Fnd_File.OUTPUT,
                          '====> ERREUR : Le traitement de de collecte des statistiques a échoué');
      ELSE
        COMMIT;
        v_cpt := v_cpt + 1;
        num_trait_list(v_cpt) := g_int_request_id;

        Fnd_File.put_line(Fnd_File.LOG,
                          to_char(sysdate, 'YYYYMMDD HH24:MI:SS') ||
                          ' - Numéro du traitement de collecte des statistiques de la table ' ||
                          rec.table_name || ' : ' || g_int_request_id);
      END IF;
    END LOOP;

    -- Attente de la fin des traitements
    FOR var IN 1 .. v_cpt LOOP

      IF NOT (Fnd_Concurrent.wait_for_request(num_trait_list(var),
                                              g_tempo,
                                              0,
                                              v_phase,
                                              v_status,
                                              v_dev_phase,
                                              v_dev_status,
                                              v_message)) THEN
        p_errbuf := v_Message;
      END IF;
    END LOOP;
    --> artf2084531

    --< V1.9
    --  --< V1.8
    --  Fnd_File.put_line(Fnd_File.LOG, 'Lancement du traitement standard avec org_id');
    --
    --  APPS.FND_GLOBAL.APPS_INITIALIZE(USER_ID      => v_user_id,
    --                                  RESP_ID      => v_resp_id,
    --                                  RESP_APPL_ID => v_resp_appl_id
    --                           );
    --  mo_global.set_org_context(g_org_id_profil,NULL,'AR');
    --  MO_GLOBAL.INIT('AR');
    --
    --  g_int_request_id          := Fnd_Request.submit_request (
    --                                 'AR'                             -- APPL
    --                                ,'RACUST'                         -- PROG
    --                                ,NULL                             -- PROGRAM_NAME
    --                                ,NULL                             -- START
    --                                ,FALSE                            -- SUB_REQUEST
    --                                ,'N'
    --                                ,g_org_id_profil
    --                                );
    --
    --
    --  IF g_int_request_id = 0
    --  THEN
    --      p_retcode    := 2;
    --      fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de l''interface client a échoué' || CHR(10) ||
    --                                      'PROGRAMME  : RACUST' || CHR(10)
    --                                      );
    --      Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de l''interface client a échoué');
    --  ELSE
    --      COMMIT;
    --      Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || g_int_request_id);
    --      Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement de l''interface client : ' || g_int_request_id);
    --
    --      -- Attente de la fin du traitement
    --      IF NOT (Fnd_Concurrent.wait_for_request (g_int_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
    --      THEN
    --          p_errbuf  := v_Message;
    --          Fnd_file.put_line(Fnd_file.log, 'ERREUR : Attente de la fin du programme de l''interface client : Fin du traitement' || CHR(10) ||
    --                                          'MESSAGE : ' || v_Message || CHR(10) );
    --      END IF;
    --
    --      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL')
    --      THEN
    --          Fnd_File.put_line(Fnd_File.LOG, 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
    --          Fnd_File.put_line(Fnd_File.OUTPUT, '. Statut de fin : ' || v_phase || '/' || v_status);
    --
    --      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
    --      THEN
    --          Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement de l''interface client en warning '|| g_int_request_id);
    --          p_retcode    := 1;
    --
    --      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')
    --      THEN
    --          p_retcode := 2;
    --          p_errbuf  := 'ERREUR : Fin anormale du traitement de l''interface client : '||v_Message;
    --
    --          fnd_file.put_line(fnd_file.LOG, 'ERREUR : Fin anormale du traitement de l''interface client '|| g_int_request_id  || CHR(10) ||
    --                                          'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
    --                                          'MESSAGE : ' || v_message || CHR(10) );
    --          Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement de l''interface client '||g_int_request_id);
    --      END IF;
    --
    --  END IF;
    --  --> V1.8
    --> V1.9

    Fnd_File.put_line(Fnd_File.LOG,
                      chr(10) ||
                      '----------------------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.LOG,
                      to_char(sysdate, 'YYYYMMDD HH24:MI:SS') ||
                      ' - Lancement des traitements standard');
    --< V1.8
    --      FOR rec IN (SELECT distinct org_id
    --                  FROM RA_CUSTOMERS_INTERFACE_ALL ORDER BY org_id)
    FOR rec IN (SELECT DISTINCT a.responsibility_id,
                                a.application_id,
                                --< V1.9
                                substr(b.name, 1, 3) cdg
                --> V1.9
                  FROM fnd_responsibility a,
                       --< V1.9
                       --dka_clients_tmp b,
                       hr_operating_units         b,
                       ( select org_id from ra_customers_interface_all union
                         select org_id from ra_customer_profiles_int_all union
                         select org_id from ra_contact_phones_int_all union
                         select org_id from ra_cust_pay_method_int_all
                      ) c
                --> V1.9
                 WHERE 1 = 1
                      --< V1.9
                      --AND     a.responsibility_key LIKE b.CDG||'_AR_ADMINISTRATEUR'
                      --AND     b.statut = 'T'
                   AND c.org_id = b.organization_id
                   AND a.responsibility_key LIKE
                       substr(b.name, 1, 3) || '_AR_ADMINISTRATEUR'
                 ORDER BY substr(b.name, 1, 3)
                --> V1.9
                ) LOOP
      --> V1.8

      APPS.FND_GLOBAL.APPS_INITIALIZE(USER_ID      => v_user_id,
                                      RESP_ID      => rec.responsibility_id, --v_resp_id, -- V1.8
                                      RESP_APPL_ID => rec.application_id --v_resp_appl_id -- V1.8
                                      );
      --mo_global.set_org_context(rec.org_id,NULL,'AR'); -- V1.8
      MO_GLOBAL.INIT('AR');

      g_int_request_id := Fnd_Request.submit_request('AR' -- APPL
                                                    ,
                                                     'RACUSTMA' -- PROG
                                                     --< V1.9
                                                    ,
                                                     'Interface clients - ' ||
                                                     rec.cdg -- DESCRIPTION
                                                     --,NULL                             -- PROGRAM_NAME
                                                     --> V1.9
                                                    ,
                                                     NULL -- START
                                                    ,
                                                     FALSE -- SUB_REQUEST
                                                    ,
                                                     'N',
                                                     NULL
                                                     --,rec.org_id                     -- V1.8
                                                     );

      IF g_int_request_id = 0 THEN
        p_retcode := 2;
        fnd_file.put_line(fnd_file.LOG,
                          'ERREUR : Le traitement de l''interface client a échoué' ||
                          CHR(10) || 'PROGRAMME  : RACUSTMA' || CHR(10));
        Fnd_File.put_line(Fnd_File.OUTPUT,
                          '====> ERREUR : Le traitement de l''interface client a échoué');
      ELSE
        COMMIT;
        v_cpt := v_cpt + 1;
        num_trait_list(v_cpt) := g_int_request_id;

        --< V1.6
        --Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || g_int_request_id);
        Fnd_File.put_line(Fnd_File.LOG,
                          to_char(sysdate, 'YYYYMMDD HH24:MI:SS') ||
                          ' - Numéro du traitement de l''interface client ' ||
                          rec.cdg || ' : ' || g_int_request_id);

        -- Attente de la fin du traitement
        IF NOT (Fnd_Concurrent.wait_for_request (g_int_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
        THEN
            p_errbuf  := v_Message;
            Fnd_file.put_line(Fnd_file.log, 'ERREUR : Attente de la fin du programme de l''interface client : Fin du traitement' || CHR(10) ||
                                            'MESSAGE : ' || v_Message || CHR(10) );
        END IF;

        IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
          Fnd_File.put_line(Fnd_File.LOG,
                            'COMPLETION= ' || v_dev_phase || '/' ||
                            v_dev_status);
          Fnd_File.put_line(Fnd_File.OUTPUT,
                            '. Statut de fin : ' || v_phase || '/' ||
                            v_status);

        ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
          Fnd_File.put_line(Fnd_File.LOG,
                            'Fin du traitement de l''interface client en warning ' ||
                            g_int_request_id);
          p_retcode := 1;

        ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
          p_retcode := 2;
          p_errbuf  := 'ERREUR : Fin anormale du traitement de l''interface client : ' ||
                       v_Message;

          fnd_file.put_line(fnd_file.LOG,
                            'ERREUR : Fin anormale du traitement de l''interface client ' ||
                            g_int_request_id || CHR(10) || 'Phase/Statut : ' ||
                            v_dev_phase || '/' || v_dev_status || CHR(10) ||
                            'MESSAGE : ' || v_message || CHR(10));
          Fnd_File.put_line(Fnd_File.OUTPUT,
                            '===> ERREUR : Fin anormale du traitement de l''interface client ' ||
                            g_int_request_id);
        END IF;
        --> V1.6

        --< artf2084531
        g_int_request_id := Fnd_Request.submit_request('FND', -- APPL
                                                       'FNDGSCST', -- PROG
                                                       NULL, -- DESCRIPTION
                                                       NULL, -- START
                                                       FALSE, -- SUB_REQUEST
                                                       'AR',              --Schema Name
                                                       30,                --Estimate Percent
                                                       NULL,              --Degree of parallelism
                                                       'NOBACKUP',        --Backup Flag
                                                       NULL,              --Restart Request ID
                                                       'LASTRUN',         --History Mode
                                                       'GATHER',          --Gather Options
                                                       NULL,              --Modifications Threshold
                                                       'Y'                --Invalidate Dependent Cursors
                                                       );

        IF g_int_request_id = 0 THEN
          p_retcode := 2;
          fnd_file.put_line(fnd_file.LOG,
                            'ERREUR : Le traitement de de collecte des statistiques a échoué' ||
                            CHR(10) || 'PROGRAMME  : FNDGTST' || CHR(10));
          Fnd_File.put_line(Fnd_File.OUTPUT,
                            '====> ERREUR : Le traitement de de collecte des statistiques a échoué');
        ELSE
          COMMIT;
          v_cpt := v_cpt + 1;
          num_trait_list(v_cpt) := g_int_request_id;

          Fnd_File.put_line(Fnd_File.LOG,
                            to_char(sysdate, 'YYYYMMDD HH24:MI:SS') ||
                            ' - Numéro du traitement de collecte des statistiques du schema AR : ' || g_int_request_id);

          -- Attente de la fin du traitement
          IF NOT (Fnd_Concurrent.wait_for_request (g_int_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
          THEN
              p_errbuf  := v_Message;
              Fnd_file.put_line(Fnd_file.log, 'ERREUR : Attente de la fin du programme e collecte des statistiques du schema AR  : Fin du traitement' || CHR(10) ||
                                              'MESSAGE : ' || v_Message || CHR(10) );
          END IF;
        END IF;
        --> artf2084531
      END IF;
    END LOOP;

    --< artf2084531
    --< V1.6
    -- Attente de la fin des traitements
    --FOR var IN 1 .. v_cpt LOOP
    --
    --  --Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || num_trait_list(var));
    --  Fnd_File.put_line(Fnd_File.OUTPUT,
    --                    '. Numéro du traitement de l''interface client : ' ||
    --                    num_trait_list(var));
    --
    --  IF NOT (Fnd_Concurrent.wait_for_request(num_trait_list(var),
    --                                          g_tempo,
    --                                          0,
    --                                          v_phase,
    --                                          v_status,
    --                                          v_dev_phase,
    --                                          v_dev_status,
    --                                          v_message)) THEN
    --    p_errbuf := v_Message;
    --    Fnd_file.put_line(Fnd_file.log,
    --                      'ERREUR : Attente de la fin du programme de l''interface client : Fin du traitement' ||
    --                      CHR(10) || 'MESSAGE : ' || v_Message || CHR(10));
    --  END IF;
    --
    --  IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
    --    Fnd_File.put_line(Fnd_File.LOG,
    --                      'COMPLETION= ' || v_dev_phase || '/' ||
    --                      v_dev_status);
    --    Fnd_File.put_line(Fnd_File.OUTPUT,
    --                      '. Statut de fin : ' || v_phase || '/' ||
    --                      v_status);
    --
    --  ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
    --    Fnd_File.put_line(Fnd_File.LOG,
    --                      'Fin du traitement de l''interface client en warning ' ||
    --                      g_int_request_id);
    --    p_retcode := 1;
    --
    --  ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
    --    p_retcode := 2;
    --    p_errbuf  := 'ERREUR : Fin anormale du traitement de l''interface client : ' ||
    --                 v_Message;
    --
    --    fnd_file.put_line(fnd_file.LOG,
    --                      'ERREUR : Fin anormale du traitement de l''interface client ' ||
    --                      g_int_request_id || CHR(10) || 'Phase/Statut : ' ||
    --                      v_dev_phase || '/' || v_dev_status || CHR(10) ||
    --                      'MESSAGE : ' || v_message || CHR(10));
    --    Fnd_File.put_line(Fnd_File.OUTPUT,
    --                      '===> ERREUR : Fin anormale du traitement de l''interface client ' ||
    --                      g_int_request_id);
    --  END IF;
    --END LOOP;
    --> V1.6
    --> artf2084531

   -- >> V1.15 28/07/2017      NBO artf2204067 - REP002 - Il y a des rejets dans l'open-interface des modes de paiement
   UPDATE ra_cust_receipt_methods rcrm
      -- V1.16 09/11/2017      NBO artf2274489 - REP002 - Il y a des rejets dans l'open-interface des modes de paiement
      SET start_date = (SELECT MIN(tmp.start_date) OVER (PARTITION BY ac.customer_number)
                          FROM ar_customers ac,
                               (SELECT DISTINCT cdg,
                                                soc,
                                                location,
                                                customer_number,
                                                start_date
                                  FROM dka_clients_tmp) tmp,
                               hz_cust_site_uses_all hcsu,
                               hz_cust_acct_sites_all hcas,
                               hr_operating_units hou
                         WHERE ac.customer_id = rcrm.customer_id
                           AND ac.customer_number = tmp.customer_number
                           AND ac.customer_id = hcas.cust_account_id
                           AND hcsu.org_id = hou.organization_id
                           AND hcas.cust_acct_site_id =
                               hcsu.cust_acct_site_id
                           AND hou.NAME = tmp.cdg || tmp.soc
                           AND hcsu.site_use_id = rcrm.site_use_id
                           AND rownum = 1),
          end_date   = NULL
    WHERE rcrm.end_date IS NOT NULL;
    -- << V1.15 28/07/2017      NBO artf2204067 - REP002 - Il y a des rejets dans l'open-interface des modes de paiement

    COMMIT;

    APPS.FND_GLOBAL.APPS_INITIALIZE(USER_ID      => v_user_id,
                                    RESP_ID      => v_resp_id,
                                    RESP_APPL_ID => v_resp_appl_id);

    BEGIN
      --< v1.4
      /*SELECT count(racia.interface_status)
      INTO v_count_customer
      FROM RA_CUSTOMERS_INTERFACE_ALL racia
          ,DKA_CLIENTS_TMP dct
      WHERE racia.orig_system_customer_ref = dct.customer_number
      AND dct.LOAD_REQUEST_ID              = DECODE( g_loader_request_id, -1, dct.load_request_id, g_loader_request_id)
      AND dct.STATUT = 'T'
      ;*/

      SELECT COUNT(interface_status)
        INTO g_summary.rejected_rows_OI_cust
        FROM RA_CUSTOMERS_INTERFACE_ALL
       WHERE orig_system_customer_ref IN
             (SELECT DISTINCT customer_number
                FROM DKA_CLIENTS_TMP
               WHERE STATUT = 'T'
                 AND LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
              );

      /*
      SELECT count(interface_status)
      --INTO v_count_profil
      INTO g_summary.rejected_rows_OI_prof
      FROM RA_CUSTOMER_PROFILES_INT_ALL racpia
          ,DKA_CLIENTS_TMP dct
      WHERE racpia.orig_system_customer_ref = dct.customer_number
      AND dct.LOAD_REQUEST_ID               = DECODE( g_loader_request_id, -1, dct.load_request_id, g_loader_request_id)
      AND dct.STATUT = 'T'
      ;*/

      SELECT COUNT(interface_status)
        INTO g_summary.rejected_rows_OI_prof
        FROM RA_CUSTOMER_PROFILES_INT_ALL
       WHERE orig_system_customer_ref IN
             (SELECT DISTINCT customer_number
                FROM DKA_CLIENTS_TMP
               WHERE STATUT = 'T'
                 AND LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
              );
      /*
      SELECT count(interface_status)
      --INTO v_count_bank
      INTO g_summary.rejected_rows_OI_bank
      FROM RA_CUSTOMER_BANKS_INT_ALL racbia
          ,DKA_CLIENTS_TMP dct
      WHERE racbia.orig_system_customer_ref = dct.customer_number
      AND dct.LOAD_REQUEST_ID               = DECODE( g_loader_request_id, -1, dct.load_request_id, g_loader_request_id)
      AND dct.STATUT = 'T'
      ;*/

      SELECT COUNT(interface_status)
        INTO g_summary.rejected_rows_OI_bank
        FROM RA_CUSTOMER_BANKS_INT_ALL
       WHERE orig_system_customer_ref IN
             (SELECT DISTINCT customer_number
                FROM DKA_CLIENTS_TMP
               WHERE STATUT = 'T'
                 AND LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
              );

      /*
      SELECT count(interface_status)
      --INTO v_count_method
      INTO g_summary.rejected_rows_OI_meth
      FROM RA_CUST_PAY_METHOD_INT_ALL racpmia
          ,DKA_CLIENTS_TMP dct
      WHERE racpmia.orig_system_customer_ref = dct.customer_number
      AND dct.LOAD_REQUEST_ID                = DECODE( g_loader_request_id, -1, dct.load_request_id, g_loader_request_id)
      AND dct.STATUT = 'T'
      ;*/

      SELECT COUNT(interface_status)
        INTO g_summary.rejected_rows_OI_meth
        FROM RA_CUST_PAY_METHOD_INT_ALL
       WHERE orig_system_customer_ref IN
             (SELECT DISTINCT customer_number
                FROM DKA_CLIENTS_TMP
               WHERE STATUT = 'T'
                 AND LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
              );
      /*
      SELECT count(interface_status)
      --INTO v_count_phone
      INTO g_summary.rejected_rows_OI_cont
      FROM ra_contact_phones_int_all racpmia
          ,DKA_CLIENTS_TMP dct
      WHERE racpmia.orig_system_customer_ref = dct.customer_number
      AND dct.LOAD_REQUEST_ID                = DECODE( g_loader_request_id, -1, dct.load_request_id, g_loader_request_id)
      AND dct.STATUT = 'T'
      ;    */

      SELECT COUNT(interface_status)
        INTO g_summary.rejected_rows_OI_cont
        FROM ra_contact_phones_int_all
       WHERE orig_system_customer_ref IN
             (SELECT DISTINCT customer_number
                FROM DKA_CLIENTS_TMP
               WHERE STATUT = 'T'
                 AND LOAD_REQUEST_ID = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
              );
      --> v1.4

      IF g_summary.rejected_rows_OI_cust > 0 OR
         g_summary.rejected_rows_OI_prof > 0 OR
         g_summary.rejected_rows_OI_bank > 0 OR
         g_summary.rejected_rows_OI_meth > 0 OR
         g_summary.rejected_rows_OI_cont > 0 THEN

        dka_tools_pkg.ins_prog_message(g_request_id,
                                       g_nom_traitement,
                                       'OI',
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       'W',
                                       'Il y a des erreurs dans les tables d''interfaces. Pour plus de détails, consultez la sortie du traitement stantard.');

        g_summary.rejected_rows := g_summary.rejected_rows + 1;

      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'import_data : ' || SQLERRM;
      Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure import_data : EXCEPTION OTHERS ');
  END import_data;

  /*
   *************************************************************************
   * PROCEDURE NAME : import_data_bank
   *
   * DESCRIPTION
   *  Procédure d'importation des données bancaires
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE import_data_bank(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

    CURSOR cur_bank_acc IS
      SELECT DISTINCT dct.rowid row_id,
                      dct.logical_line_num,
                      dct.customer_number,
                      dct.cdg || '-' || dct.location orig_system_reference,
                      dct.bank_number,
                      dct.bank_name,
                      dct.bank_num branch_number,
                      dct.bank_branch_name branch_name,
                      dct.bank_account_num,
                      dct.check_digits,
                      dct.bank_account_name,
                      dct.currency_code,
                      dct.iban_number,
                      dct.country_bank,
                      dct.bank_start_date,
                      dct.cdg
        FROM dka_clients_tmp        dct
       WHERE dct.bank_account_num is not null
         --V1.10: AND dct.LOAD_REQUEST_ID = g_loader_request_id
         AND NVL(dct.STATUT_BANQUE,'Z') <> 'T' --V1.10: ajout
         AND NVL(dct.STATUT,'Z') = 'T'
         --AND hou.name = dct.cdg || dct.soc
       ORDER BY dct.customer_number, dct.cdg || '-' || dct.location
      ;

    CURSOR cur_ou (p_cdg IN VARCHAR2) IS
      SELECT  hou.organization_id,
              hou.name organization_name
      FROM    hr_operating_units     hou
      WHERE   1 = 1
        AND   sysdate between nvl(hou.date_from, sysdate) and nvl(hou.date_to, sysdate) --artf2084473
        AND   hou.name like p_cdg || '%'
      ORDER BY hou.name
      ;

    CURSOR cur_mandats IS
      SELECT DISTINCT dct.rowid row_id,
                      dct.logical_line_num,
                      dct.customer_number,
                      dct.cdg || '-' || dct.location orig_system_reference,
                      dct.bank_number,
                      dct.bank_num branch_number,
                      dct.bank_account_num,
                      dct.check_digits,
                      dct.currency_code,
                      dct.country_bank,
                      dct.start_date,
                      dct.rum,
                      hou.organization_id,
                      hou.name organization_name,
                      xep.legal_entity_id,
                      xep.name legal_entity_name
        FROM dka_clients_tmp         dct,
             hr_operating_units      hou,
             xle_entity_profiles     xep
       WHERE dct.RUM IS NOT NULL
         --V1.10: AND dct.load_request_id = g_loader_request_id --DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
         AND NVL(dct.STATUT_RUM,'Z') <> 'T' --V1.10: ajout
         AND NVL(dct.STATUT_BANQUE,'Z') = 'T' --V1.10: ajout
         AND NVL(dct.STATUT,'Z') = 'T'
         AND hou.default_legal_context_id = xep.legal_entity_id
         AND sysdate between nvl(hou.date_from, sysdate) and nvl(hou.date_to, sysdate) --artf2084473
         AND hou.name = dct.cdg || dct.soc
       ORDER BY dct.customer_number, dct.cdg || '-' || dct.location, hou.name
      ;

    v_cust_account_id     NUMBER;
    v_party_id            NUMBER;
    v_cust_acct_site_id   NUMBER;
    v_party_site_id       NUMBER;
    v_site_use_id         NUMBER;

    v_return_status       VARCHAR2(10);
    v_msg_count           NUMBER;
    v_msg_data            VARCHAR2(500);

    v_bankacct            iby_ext_bankacct_pub.ExtBankAcct_rec_type;
    v_response_rec        iby_fndcpt_common_pub.Result_rec_type;
    v_ext_bank_rec        iby_ext_bankacct_pub.ExtBank_rec_type;
    v_ext_bank_branch_rec iby_ext_bankacct_pub.ExtBankBranch_rec_type;

    v_bank_id             NUMBER;
    v_branch_id           NUMBER;

    v_ext_bankacc_rec     iby_ext_bankacct_pub.ExtBankAcct_rec_type;
    v_payer_rec           iby_fndcpt_common_pub.PayerContext_rec_type;
    v_assign_rec          iby_fndcpt_setup_pub.PmtInstrAssignment_rec_type;
    v_instrument_rec      iby_fndcpt_setup_pub.PmtInstrument_rec_type;

    v_acct_id             NUMBER;
    v_assign_id           NUMBER;
    v_joint_acct_owner_id NUMBER;
    v_debit_auth_id       NUMBER;

    v_create_acc_flag     VARCHAR2(1);

    v_exists              VARCHAR2(10);
    v_result              NUMBER;

    v_user_id             NUMBER;
    v_start_date          DATE;
    v_end_date            DATE;

    v_flag_erreur         BOOLEAN := FALSE;
  BEGIN
      --< V1.6
    Fnd_File.put_line(Fnd_File.LOG,
                      chr(10) ||
                      '----------------------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.LOG,
                      to_char(sysdate, 'YYYYMMDD HH24:MI:SS') ||
                      ' - Traitement des comptes bancaires');

    FOR bank_acc IN cur_bank_acc LOOP

      v_flag_erreur := FALSE;

      --< artf2081484
      -- Check customer exists
      BEGIN
        select  hca.cust_account_id,
                hca.party_id
        into    v_cust_account_id,
                v_party_id
        from    hz_cust_accounts hca
        where   hca.account_number = bank_acc.customer_number;
      EXCEPTION
        WHEN OTHERS THEN
          v_cust_account_id := NULL;
          v_party_id := NULL;

          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         g_nom_traitement,
                                         'BANK',
                                         'DKA_CLIENTS_TMP',
                                         bank_acc.logical_line_num,
                                         'CUSTOMER_NUMBER',
                                         bank_acc.customer_number,
                                         'E',
                                         'Le client n''eiste pas dans le référentiel Dalkia');
      END;

      -- Check bank exists
      iby_ext_bankacct_pub.check_bank_exist (p_api_version     => 1.0,
                                             p_init_msg_list   => FND_API.G_FALSE,
                                             p_country_code    => bank_acc.country_bank,
                                             p_bank_name       => NULL,--bank_acc.bank_name,
                                             p_bank_number     => bank_acc.bank_number,
                                             x_return_status   => v_return_status,
                                             x_msg_count       => v_msg_count,
                                             x_msg_data        => v_msg_data,
                                             x_bank_id         => v_bank_id,
                                             x_end_date        => v_end_date,
                                             x_response        => v_response_rec);

      IF nvl(v_return_status, 'NULL') <> 'S' THEN

        --Fnd_File.put_line(Fnd_File.LOG, 'Error in iby_ext_bankacct_pub.check_bank_exist for line '||bank_acc.logical_line_num);

        v_flag_erreur := TRUE;

        dka_tools_pkg.ins_prog_message(g_request_id,
                                       g_nom_traitement,
                                       'BANK',
                                       'DKA_CLIENTS_TMP',
                                       bank_acc.logical_line_num,
                                       'BANK_NUMBER',
                                       TO_CHAR(bank_acc.bank_number),
                                       'E',
                                       nvl(v_msg_data, 'Unknown error in iby_ext_bankacct_pub.check_bank_exist'));

      ELSE

        IF v_bank_id IS NULL AND bank_acc.country_bank <> 'FR' THEN
          iby_ext_bankacct_pub.check_bank_exist (p_api_version     => 1.0,
                                                 p_init_msg_list   => FND_API.G_FALSE,
                                                 p_country_code    => bank_acc.country_bank,
                                                 p_bank_name       => bank_acc.bank_name,
                                                 p_bank_number     => NULL,--bank_acc.bank_number,
                                                 x_return_status   => v_return_status,
                                                 x_msg_count       => v_msg_count,
                                                 x_msg_data        => v_msg_data,
                                                 x_bank_id         => v_bank_id,
                                                 x_end_date        => v_end_date,
                                                 x_response        => v_response_rec);

          IF nvl(v_return_status, 'NULL') <> 'S' THEN

            --Fnd_File.put_line(Fnd_File.LOG, 'Error in iby_ext_bankacct_pub.check_bank_exist for line '||bank_acc.logical_line_num);

            v_flag_erreur := TRUE;

            dka_tools_pkg.ins_prog_message(g_request_id,
                                           g_nom_traitement,
                                           'BANK',
                                           'DKA_CLIENTS_TMP',
                                           bank_acc.logical_line_num,
                                           'BANK_NAME',
                                           TO_CHAR(bank_acc.bank_name),
                                           'E',
                                           nvl(v_msg_data, 'Unknown error in iby_ext_bankacct_pub.check_bank_exist'));

          ELSE

            IF v_bank_id IS NULL THEN

              v_flag_erreur := TRUE;

              dka_tools_pkg.ins_prog_message(g_request_id,
                                             g_nom_traitement,
                                             'BANK',
                                             'DKA_CLIENTS_TMP',
                                             bank_acc.logical_line_num,
                                             'BANK_NUMBER / BANK_NAME',
                                             TO_CHAR(bank_acc.bank_number)||' / '||TO_CHAR(bank_acc.bank_name),
                                             'E',
                                             'La banque est introuvable dans le référentiel Dalkia.');
            END IF;
          END IF;
        END IF;
      END IF;

      -- Check bank branch exists
      IF v_bank_id IS NOT NULL THEN

        iby_ext_bankacct_pub.check_ext_bank_branch_exist(p_api_version      => 1.0,
                                                         p_init_msg_list    => NULL,
                                                         p_bank_id          => v_bank_id,
                                                         p_branch_name      => NULL,--bank_acc.branch_name,
                                                         p_branch_number    => bank_acc.branch_number,
                                                         x_return_status    => v_return_status,
                                                         x_msg_count        => v_msg_count,
                                                         x_msg_data         => v_msg_data,
                                                         x_branch_id        => v_branch_id,
                                                         x_end_date         => v_end_date,
                                                         x_response         => v_response_rec);

        IF nvl(v_return_status, 'NULL') <> 'S' THEN

          --Fnd_File.put_line(Fnd_File.LOG, 'Error in iby_ext_bankacct_pub.check_ext_bank_branch_exist for line '||bank_acc.logical_line_num);

          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         g_nom_traitement,
                                         'BANK',
                                         'DKA_CLIENTS_TMP',
                                         bank_acc.logical_line_num,
                                         'BRANCH_NUMBER',
                                         TO_CHAR(bank_acc.branch_number),
                                         'E',
                                         nvl(v_msg_data, 'Unknown error in iby_ext_bankacct_pub.check_ext_bank_branch_exist'));

        ELSE

          IF v_branch_id IS NULL AND bank_acc.country_bank <> 'FR' THEN
            iby_ext_bankacct_pub.check_ext_bank_branch_exist(p_api_version      => 1.0,
                                                             p_init_msg_list    => NULL,
                                                             p_bank_id          => v_bank_id,
                                                             p_branch_name      => bank_acc.branch_name,
                                                             p_branch_number    => NULL,--bank_acc.branch_number,
                                                             x_return_status    => v_return_status,
                                                             x_msg_count        => v_msg_count,
                                                             x_msg_data         => v_msg_data,
                                                             x_branch_id        => v_branch_id,
                                                             x_end_date         => v_end_date,
                                                             x_response         => v_response_rec);

            IF nvl(v_return_status, 'NULL') <> 'S' THEN

              --Fnd_File.put_line(Fnd_File.LOG, 'Error in iby_ext_bankacct_pub.check_ext_bank_branch_exist for line '||bank_acc.logical_line_num);

              v_flag_erreur := TRUE;

              dka_tools_pkg.ins_prog_message(g_request_id,
                                             g_nom_traitement,
                                             'BANK',
                                             'DKA_CLIENTS_TMP',
                                             bank_acc.logical_line_num,
                                             'BRANCH_NAME',
                                             TO_CHAR(bank_acc.branch_name),
                                             'E',
                                             nvl(v_msg_data, 'Unknown error in iby_ext_bankacct_pub.check_ext_bank_branch_exist'));

            ELSE

              IF v_branch_id IS NULL THEN

                v_flag_erreur := TRUE;

                dka_tools_pkg.ins_prog_message(g_request_id,
                                               g_nom_traitement,
                                               'BANK',
                                               'DKA_CLIENTS_TMP',
                                               bank_acc.logical_line_num,
                                               'BRANCH_NUMBER / BRANCH_NAME',
                                               TO_CHAR(bank_acc.branch_number)||' / '||TO_CHAR(bank_acc.branch_name),
                                               'E',
                                               'L''agence est introuvable dans le référentiel Dalkia.');
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
      --> artf2081484

      -- Check bank account exists
      IF v_cust_account_id IS NOT NULL
        AND v_bank_id IS NOT NULL
        AND v_branch_id IS NOT NULL
      THEN
        --Fnd_File.put_line(Fnd_File.LOG, 'Vérification de l''existance du compte bancaire.');

        fnd_msg_pub.initialize;

        v_ext_bankacc_rec.bank_id             := v_bank_id;
        v_ext_bankacc_rec.branch_id           := v_branch_id;
        v_ext_bankacc_rec.bank_account_name   := bank_acc.bank_account_name;
        v_ext_bankacc_rec.bank_account_num    := bank_acc.bank_account_num;
        v_ext_bankacc_rec.currency            := bank_acc.currency_code;
        v_ext_bankacc_rec.iban                := bank_acc.iban_number;
        v_ext_bankacc_rec.check_digits        := bank_acc.check_digits;
        v_ext_bankacc_rec.acct_owner_party_id := v_party_id;
        v_ext_bankacc_rec.country_code        := bank_acc.country_bank;
        --<artf2089049
        --v_ext_bankacc_rec.start_date          := bank_acc.bank_start_date;
        v_ext_bankacc_rec.start_date          := nvl(bank_acc.bank_start_date, to_date('01/01/2000', 'DD/MM/YYYY'));
        -->artf2089049

        iby_ext_bankacct_pub.check_ext_acct_exist(p_api_version       => 1.0,
                                                  p_init_msg_list     => FND_API.G_FALSE,
                                                  p_ext_bank_acct_rec => v_ext_bankacc_rec,
                                                  x_acct_id           => v_acct_id,
                                                  x_start_date        => v_start_date,
                                                  x_end_date          => v_end_date,
                                                  x_return_status     => v_return_status,
                                                  x_msg_count         => v_msg_count,
                                                  x_msg_data          => v_msg_data,
                                                  x_response          => v_response_rec);

        IF nvl(v_return_status, 'NULL') <> 'S' THEN

          g_summary.rejected_rows := g_summary.rejected_rows + 1;

          --Fnd_File.put_line(Fnd_File.LOG, 'Error in iby_ext_bankacct_pub.check_ext_acct_exist for line '||bank_acc.logical_line_num);

          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         g_nom_traitement,
                                         'BANK',
                                         'DKA_CLIENTS_TMP',
                                         bank_acc.logical_line_num,
                                         'BANK_ACCOUNT_NUM',
                                         TO_CHAR(bank_acc.bank_account_num),
                                         'E',
                                         nvl(v_msg_data, 'Unknown error in iby_ext_bankacct_pub.check_ext_acct_exist'));

        ELSE

          IF v_acct_id IS NOT NULL THEN

            -- Check owner exists
            SELECT  count(1)
            INTO    v_exists
            FROM    IBY_ACCOUNT_OWNERS
            WHERE   account_owner_party_id = v_party_id
            AND     ext_bank_account_id = v_acct_id;

            --Add account owner
            IF v_exists = 0 THEN
              --Fnd_File.put_line(Fnd_File.LOG, 'Ajout d''un proprietaire au compte');

              fnd_msg_pub.initialize;

              iby_ext_bankacct_pub.add_joint_account_owner(p_api_version         => 1.0,
                                                           p_init_msg_list       => FND_API.G_FALSE,
                                                           p_bank_account_id     => v_acct_id,
                                                           p_acct_owner_party_id => v_party_id,
                                                           x_joint_acct_owner_id => v_joint_acct_owner_id,
                                                           x_return_status       => v_return_status,
                                                           x_msg_count           => v_msg_count,
                                                           x_msg_data            => v_msg_data,
                                                           x_response            => v_response_rec);

              IF nvl(v_return_status, 'NULL') <> 'S' THEN

                g_summary.rejected_rows := g_summary.rejected_rows + 1;

                --Fnd_File.put_line(Fnd_File.LOG, 'Error in iby_ext_bankacct_pub.add_joint_account_owner for line '||bank_acc.logical_line_num);

                v_flag_erreur := TRUE;

                dka_tools_pkg.ins_prog_message(g_request_id,
                                               g_nom_traitement,
                                               'BANK',
                                               'DKA_CLIENTS_TMP',
                                               bank_acc.logical_line_num,
                                               'BANK_ACCOUNT_NUM',
                                               TO_CHAR(bank_acc.bank_account_num),
                                               'E',
                                               nvl(v_msg_data, 'Unknown error in iby_ext_bankacct_pub.add_joint_account_owner'));

              END IF;
            END IF;

          -- Création compte bancaire
          ELSIF v_acct_id IS NULL THEN

            --Fnd_File.put_line(Fnd_File.LOG, 'Création du compte bancaire. Compte N° : ' || bank_acc.bank_account_num);

            fnd_msg_pub.initialize;

            iby_ext_bankacct_pub.create_ext_bank_acct(p_api_version       => 1.0,
                                                      p_init_msg_list     => FND_API.G_FALSE,
                                                      p_ext_bank_acct_rec => v_ext_bankacc_rec,
                                                      x_acct_id           => v_acct_id,
                                                      x_return_status     => v_return_status,
                                                      x_msg_count         => v_msg_count,
                                                      x_msg_data          => v_msg_data,
                                                      x_response          => v_response_rec);

            IF nvl(v_return_status, 'NULL') <> 'S' THEN

              g_summary.rejected_rows := g_summary.rejected_rows + 1;

              --Fnd_File.put_line(Fnd_File.LOG, 'Error in iby_ext_bankacct_pub.create_ext_bank_acct for line '||bank_acc.logical_line_num);

              v_flag_erreur := TRUE;

              dka_tools_pkg.ins_prog_message(g_request_id,
                                             g_nom_traitement,
                                             'BANK',
                                             'DKA_CLIENTS_TMP',
                                             bank_acc.logical_line_num,
                                             'BANK_ACCOUNT_NUM',
                                             TO_CHAR(bank_acc.bank_account_num),
                                             'E',
                                             nvl(v_msg_data, 'Unknown error in iby_ext_bankacct_pub.create_ext_bank_acct'));

            END IF;
          END IF;
        END IF;
      END IF;

      IF v_flag_erreur = TRUE THEN

        UPDATE DKA_CLIENTS_TMP a
           SET a.STATUT_BANQUE    = 'E',
               a.LAST_UPDATED_BY  = v_user_id,
               a.LAST_UPDATE_DATE = sysdate
         WHERE a.rowid = bank_acc.row_id;

         CONTINUE;
      END IF;

      --
      -- Loop on all organizations
      --
      FOR rec_ou in cur_ou (bank_acc.cdg) LOOP

        BEGIN
          select  hcas.cust_acct_site_id,
                  hcas.party_site_id,
                  hcsu.site_use_id
          into    v_cust_acct_site_id,
                  v_party_site_id,
                  v_site_use_id
          from    hz_cust_acct_sites_all hcas,
                  hz_cust_site_uses_all hcsu
          where   hcas.cust_acct_site_id = hcsu.cust_acct_site_id
          and     hcsu.site_use_code = 'BILL_TO'
          and     hcas.cust_account_id = v_cust_account_id
          and     hcas.orig_system_reference = bank_acc.orig_system_reference
          and     hcas.org_id = rec_ou.organization_id;
        EXCEPTION
          WHEN OTHERS THEN
            v_cust_acct_site_id := NULL;
            v_party_site_id := NULL;
            v_site_use_id := NULL;

            v_flag_erreur := TRUE;

            dka_tools_pkg.ins_prog_message(g_request_id,
                                           g_nom_traitement,
                                           'BANK',
                                           'DKA_CLIENTS_TMP',
                                           bank_acc.logical_line_num,
                                           'LOCATION',
                                           bank_acc.orig_system_reference,
                                           'E',
                                           'Le site client n''existe pas dans le référentiel Dalkia');
        END;

        IF v_cust_acct_site_id IS NOT NULL THEN
          -- Cas 2.2 : Rattachement
          --Fnd_File.put_line(Fnd_File.LOG, 'Rattachement du compte au site client');

          SELECT  count(1)
          INTO    v_exists
          FROM    iby_external_payers_all iep,
                  iby_pmt_instr_uses_all ipiu
          WHERE   iep.ext_payer_id = ipiu.ext_pmt_party_id
          AND     iep.payment_function = 'CUSTOMER_PAYMENT'
          AND     iep.party_id = v_party_id
          AND     iep.org_type = 'OPERATING_UNIT'
          AND     iep.org_id = rec_ou.organization_id
          AND     iep.cust_account_id = v_cust_account_id
          AND     iep.acct_site_use_id = v_site_use_id
          AND     ipiu.instrument_type = 'BANKACCOUNT'
          AND     ipiu.instrument_id = v_acct_id;

          IF v_exists = 0 THEN

            fnd_msg_pub.initialize;

            v_payer_rec.payment_function := 'CUSTOMER_PAYMENT';
            v_payer_rec.party_id         := v_party_id;
            v_payer_rec.org_type         := 'OPERATING_UNIT';
            v_payer_rec.org_id           := rec_ou.organization_id;
            v_payer_rec.cust_account_id  := v_cust_account_id;
            v_payer_rec.account_site_id  := v_site_use_id;

            v_instrument_rec.instrument_type := 'BANKACCOUNT';
            v_instrument_rec.instrument_id   := v_acct_id;

            v_assign_rec.Instrument := v_instrument_rec;
            v_assign_rec.Priority   := 1;
            --<artf2089049
            --v_assign_rec.Start_Date := sysdate;
            v_assign_rec.Start_Date := nvl(bank_acc.bank_start_date, to_date('01/01/2000', 'DD/MM/YYYY'));
            -->artf2089049

            iby_fndcpt_setup_pub.set_payer_instr_assignment(p_api_version        => 1.0,
                                                            p_init_msg_list      => FND_API.G_FALSE,
                                                            p_commit             => FND_API.G_TRUE,
                                                            x_return_status      => v_return_status,
                                                            x_msg_count          => v_msg_count,
                                                            x_msg_data           => v_msg_data,
                                                            p_payer              => v_payer_rec,
                                                            p_assignment_attribs => v_assign_rec,
                                                            x_assign_id          => v_assign_id,
                                                            x_response           => v_response_rec);

            IF nvl(v_return_status, 'NULL') <> 'S' THEN

              g_summary.rejected_rows := g_summary.rejected_rows + 1;

              --Fnd_File.put_line(Fnd_File.LOG, 'Error in iby_fndcpt_setup_pub.set_payer_instr_assignment for line '||bank_acc.logical_line_num);

              v_flag_erreur := TRUE;

              dka_tools_pkg.ins_prog_message(g_request_id,
                                             g_nom_traitement,
                                             'BANK',
                                             'DKA_CLIENTS_TMP',
                                             bank_acc.logical_line_num,
                                             'BANK_ACCOUNT_NUM',
                                             TO_CHAR(bank_acc.bank_account_num),
                                             'E',
                                             nvl(v_msg_data, 'Unknown error in iby_fndcpt_setup_pub.set_payer_instr_assignment'));
            END IF;
          END IF;
        END IF;

        --< V1.10
        SELECT  count(1)
        INTO    v_exists
        FROM    hz_cust_accounts hca,
                hz_cust_acct_sites_all hcas,
                hz_cust_site_uses_all hcsu,
                iby_external_payers_all iep,
                iby_pmt_instr_uses_all ipiu,
                iby_ext_bank_accounts ieba,
                hr_operating_units hou,
                ce_bank_branches_v cbb
        WHERE   1 = 1
        AND     hca.cust_account_id = hcas.cust_account_id
        AND     hcas.cust_acct_site_id = hcsu.cust_acct_site_id
        AND     hcsu.site_use_id = iep.acct_site_use_id
        AND     iep.ext_payer_id = ipiu.ext_pmt_party_id
        AND     ipiu.instrument_id = ieba.ext_bank_account_id
        AND     ipiu.instrument_type = 'BANKACCOUNT'
        AND     ipiu.payment_function = 'CUSTOMER_PAYMENT'
        AND     ieba.bank_id = cbb.bank_party_id
        AND     ieba.branch_id = cbb.branch_party_id
        AND     hcsu.org_id = hou.organization_id
        AND     hcsu.org_id = rec_ou.organization_id
        AND     hca.account_number = bank_acc.customer_number
        AND     cbb.bank_number = bank_acc.bank_number
        AND     cbb.branch_number = bank_acc.branch_number
        AND     ieba.bank_account_num = bank_acc.bank_account_num
        AND     ieba.check_digits = bank_acc.check_digits
        AND     hcas.orig_system_reference = bank_acc.orig_system_reference;

        IF v_exists = 0 THEN

          SELECT  count(1)
          INTO    v_exists
          FROM    dka_program_messages dpm
          WHERE   dpm.table_id = bank_acc.logical_line_num
          AND     dpm.table_name = 'DKA_CLIENTS_TMP_BK'
          AND     dpm.request_id = g_request_id;

          IF v_exists = 0 THEN

            g_summary.rejected_rows := g_summary.rejected_rows + 1;

            v_flag_erreur := TRUE;

            dka_tools_pkg.ins_prog_message(g_request_id,
                                           g_nom_traitement,
                                           'BANK',
                                           'DKA_CLIENTS_TMP',
                                           bank_acc.logical_line_num,
                                           'BANK_ACCOUNT_NUM',
                                           TO_CHAR(bank_acc.bank_account_num),
                                           'E',
                                           'Erreur inconnue');
         END IF;
        END IF;
      END LOOP;

      IF v_flag_erreur = TRUE THEN

        UPDATE DKA_CLIENTS_TMP a
           SET a.STATUT_BANQUE    = 'E',
               a.LAST_UPDATED_BY  = v_user_id,
               a.LAST_UPDATE_DATE = sysdate
         WHERE a.rowid = bank_acc.row_id;

      ELSE

        UPDATE DKA_CLIENTS_TMP a
           SET a.STATUT_BANQUE    = 'T',
               a.LAST_UPDATED_BY  = v_user_id,
               a.LAST_UPDATE_DATE = sysdate
         WHERE a.rowid = bank_acc.row_id;

      END IF;
    END LOOP;


    -- Insertion des mandats de prélevements
    Fnd_File.put_line(Fnd_File.LOG,
                      chr(10) ||
                      '----------------------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.LOG,
                      to_char(sysdate, 'YYYYMMDD HH24:MI:SS') ||
                      ' - Traitement des mandats de prélèvement');

    FOR mandat IN cur_mandats LOOP

      v_flag_erreur := FALSE;

      BEGIN
        SELECT  hca.cust_account_id,
                hca.party_id,
                hcas.cust_acct_site_id,
                hcas.party_site_id,
                hcsu.site_use_id,
                ieba.ext_bank_account_id,
                ipiu.instrument_payment_use_id
        INTO    v_cust_account_id,
                v_party_id,
                v_cust_acct_site_id,
                v_party_site_id,
                v_site_use_id,
                v_acct_id,
                v_assign_id
        FROM    hz_cust_accounts hca,
                hz_cust_acct_sites_all hcas,
                hz_cust_site_uses_all hcsu,
                iby_external_payers_all iep,
                iby_pmt_instr_uses_all ipiu,
                iby_ext_bank_accounts ieba,
                hr_operating_units hou,
                ce_bank_branches_v cbb
        WHERE   1 = 1
        AND     hca.cust_account_id = hcas.cust_account_id
        AND     hcas.cust_acct_site_id = hcsu.cust_acct_site_id
        AND     hcsu.site_use_id = iep.acct_site_use_id
        AND     iep.ext_payer_id = ipiu.ext_pmt_party_id
        AND     ipiu.instrument_id = ieba.ext_bank_account_id
        AND     ipiu.instrument_type = 'BANKACCOUNT'
        AND     ipiu.payment_function = 'CUSTOMER_PAYMENT'
        AND     ieba.bank_id = cbb.bank_party_id
        AND     ieba.branch_id = cbb.branch_party_id
        AND     hcsu.org_id = hou.organization_id
        AND     hcsu.org_id = mandat.organization_id
        AND     hca.account_number = mandat.customer_number
        AND     cbb.bank_number = mandat.bank_number
        AND     cbb.branch_number = mandat.branch_number
        AND     ieba.bank_account_num = mandat.bank_account_num
        AND     ieba.check_digits = mandat.check_digits
        AND     hcas.orig_system_reference = mandat.orig_system_reference;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_cust_account_id := NULL;
          v_party_id := NULL;
          v_cust_acct_site_id := NULL;
          v_party_site_id := NULL;
          v_site_use_id := NULL;
          v_acct_id := NULL;
          v_assign_id := NULL;

          --< V1.10
          g_summary.rejected_rows := g_summary.rejected_rows + 1;

          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         g_nom_traitement,
                                         'RUM',
                                         'DKA_CLIENTS_TMP',
                                         mandat.logical_line_num,
                                         'BANK_ACCOUNT_NUM',
                                         TO_CHAR(mandat.bank_account_num),
                                         'E',
                                         'Le compte bancaire n''existe pas dans le référentiel Dalkia');

        WHEN OTHERS THEN
          v_cust_account_id := NULL;
          v_party_id := NULL;
          v_cust_acct_site_id := NULL;
          v_party_site_id := NULL;
          v_site_use_id := NULL;
          v_acct_id := NULL;
          v_assign_id := NULL;

          --< V1.10
          g_summary.rejected_rows := g_summary.rejected_rows + 1;

          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         g_nom_traitement,
                                         'RUM',
                                         'DKA_CLIENTS_TMP',
                                         mandat.logical_line_num,
                                         'BANK_ACCOUNT_NUM',
                                         TO_CHAR(mandat.bank_account_num),
                                         'E',
                                         'Unknown error in check_bank_account : '||sqlerrm);


      END;

      IF v_acct_id IS NOT NULL THEN
        --Fnd_File.put_line(Fnd_File.LOG, 'Insertion des mandats de prélevements. Account ID : ' || TO_CHAR(mandat.ext_bank_account_id));

        SELECT  count(1)
        INTO    v_exists
        FROM    iby_debit_authorizations ida
        WHERE   ida.creditor_legal_entity_id = mandat.legal_entity_id
        AND     ida.external_bank_account_id = v_acct_id
        AND     ida.debtor_party_id = v_party_id
        AND     ida.authorization_reference_number = mandat.RUM;

        IF v_exists = 0 THEN
          v_debit_auth_id := iby_debit_authorizations_s.nextval;

          BEGIN
            iby_debit_auth_pkg.Create_Debit_Authorization(p_debit_auth_id           => v_debit_auth_id,
                                                          p_bank_use_id             => NULL, --v_assign_id
                                                          p_auth_ref_number         => mandat.RUM,
                                                          p_initial_debit_auth_id   => v_debit_auth_id,
                                                          p_auth_rev_number         => 1,
                                                          p_payment_code            => 'REC',
                                                          p_amend_readon_code       => NULL,
                                                          p_auth_sign_date          => mandat.start_date,
                                                          p_auth_cancel_date        => NULL,
                                                          p_debit_auth_method       => NULL,
                                                          p_pre_notif_flag          => 'N',
                                                          p_creditor_id             => mandat.legal_entity_id,
                                                          p_creditor_name           => mandat.legal_entity_name,
                                                          p_debit_auth_begin        => mandat.start_date,
                                                          p_cust_addr_id            => NULL, --v_site_use_id,
                                                          p_debit_auth_flag         => 'Y',
                                                          p_debit_auth_ref          => NULL,
                                                          p_cust_id_code            => NULL,
                                                          p_creditor_identifer      => NULL,
                                                          p_debit_auth_end          => NULL,
                                                          p_mandate_file            => NULL,
                                                          p_cust_name               => NULL,
                                                          p_ext_bank_acct_id        => v_acct_id,
                                                          p_debit_party_id          => v_party_id,
                                                          p_direct_debit_count      => 0,
                                                          p_priority                => NULL,
                                                          p_debit_auth_fnl_col_date => NULL,
                                                          p_frequency               => NULL, --'ADHO'
                                                          x_result                  => v_result);

          EXCEPTION
            WHEN OTHERS THEN
              --Fnd_File.put_line(Fnd_File.LOG, 'Erreur suite à l''insertion du mandat de prélevement : '||SQLERRM);

              v_result := 0;

              v_flag_erreur := TRUE;

              dka_tools_pkg.ins_prog_message(g_request_id,
                                             g_nom_traitement,
                                             'RUM',
                                             'DKA_CLIENTS_TMP',
                                             mandat.logical_line_num,
                                             'RUM',
                                             mandat.RUM,
                                             'E',
                                             SQLERRM);
          END;
        END IF;
      END IF;

      IF v_flag_erreur = TRUE THEN

        UPDATE DKA_CLIENTS_TMP a
           SET a.STATUT_RUM       = 'E',
               a.LAST_UPDATED_BY  = v_user_id,
               a.LAST_UPDATE_DATE = sysdate
         WHERE a.rowid = mandat.row_id;

      ELSE

        UPDATE DKA_CLIENTS_TMP a
           SET a.STATUT_RUM       = 'T',
               a.LAST_UPDATED_BY  = v_user_id,
               a.LAST_UPDATE_DATE = sysdate
         WHERE a.rowid = mandat.row_id;

      END IF;
    END LOOP;

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'import_data_bank : ' || SQLERRM;
      Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure import_data_bank : EXCEPTION OTHERS ');
  END import_data_bank;
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
  PROCEDURE Report_Bilan(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

  BEGIN

    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début Report_Bilan');

    --------------------
    -- Initialisation --
    --------------------

    p_errbuf  := NULL;
    p_retcode := 0;

    --< v1.4
    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT, 'BILAN :');
    fnd_file.put_line(fnd_file.OUTPUT, '-------');
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements chargés dans la table spécifique des clients                                  : ' ||
                      TO_CHAR(g_summary.loaded_rows_cli));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements chargés dans la table spécifique des chargés de recouvrements                 : ' ||
                      TO_CHAR(g_summary.loaded_rows_rec) || CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements rejetés dans la table spécifique des clients après validation                 : ' ||
                      TO_CHAR(g_summary.rejected_rows_cli));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements rejetés dans la table spécifique des chargés de recouvrement après validation : ' ||
                      TO_CHAR(g_summary.rejected_rows_rec) || CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements chargés dans la table d''interface des clients                                 : ' ||
                      TO_CHAR(g_summary.loaded_rows_OI_cust));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements chargés dans la table d''interface des profils                                 : ' ||
                      TO_CHAR(g_summary.loaded_rows_OI_prof));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements chargés dans la table d''interface des méthodes de paiement                    : ' ||
                      TO_CHAR(g_summary.loaded_rows_OI_meth));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements chargés dans la table d''interface des banques                                 : ' ||
                      TO_CHAR(g_summary.loaded_rows_OI_bank));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements chargés dans la table d''interface des contacts                                : ' ||
                      TO_CHAR(g_summary.loaded_rows_OI_cont) || CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements rejetés dans la table d''interface des clients                                 : ' ||
                      TO_CHAR(g_summary.rejected_rows_OI_cust));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements rejetés dans la table d''interface des profils                                 : ' ||
                      TO_CHAR(g_summary.rejected_rows_OI_prof));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements rejetés dans la table d''interface des méthodes de paiement                    : ' ||
                      TO_CHAR(g_summary.rejected_rows_OI_meth));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements rejetés dans la table d''interface des banques                                 : ' ||
                      TO_CHAR(g_summary.rejected_rows_OI_bank));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements rejetés dans la table d''interface des contacts                                : ' ||
                      TO_CHAR(g_summary.rejected_rows_OI_cont) || CHR(10));
    --> v1.4

    fnd_file.put_line(fnd_file.OUTPUT,
                      'Voir les sorties des traitements d''Open interface pour avoir plus de détails sur les enregistrements rejetés.');

    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin Report_Bilan');

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'REPORT_BILAN : ' || SQLERRM;
      Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
  END Report_Bilan;

  /*
  *************************************************************************
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
   ************************************************************************
   */

  PROCEDURE set_recovery_mode(p_Errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

  BEGIN

    g_loader_request_id := g_request_id; ---1;

    UPDATE DKA_CLIENTS_TMP
       SET STATUT = NULL, LOAD_REQUEST_ID = g_request_id
     WHERE NVL(STATUT, 'E') = 'E';

    UPDATE DKA_RECOUVREMENTS_TMP
       SET STATUT = NULL, LOAD_REQUEST_ID = g_request_id
     WHERE NVL(STATUT, 'E') = 'E';

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'SET_RECOVERY_MODE : ' || SQLERRM;
      Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure SET_RECOVERY_MODE : EXCEPTION OTHERS ');
  END set_recovery_mode;


   -- 16/12/2016 NBO artf2062780 - REP002 - Export / Import - Gestion des relations
    /*
   *************************************************************************
   * PROCEDURE NAME : Launch_Loader_relation
   *
   * DESCRIPTION
   *  Procédure de lancement du programme de chargement dans la table spécifique
   *
   * PARAMETERS
   * ==========
   * NAME               DESCRIPTION
  .* -----------------  ------------------------------------------------------
   * p_file_name       Nom du fichier à charger
   * p_errbuf          Retour de message éventuel
   * p_retcode         Statut du traitement en sortie
   *
   ************************************************************************
   */
  PROCEDURE Launch_Loader_relation(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
    v_phase      VARCHAR2(100);
    v_status     VARCHAR2(100);
    v_dev_phase  VARCHAR2(100);
    v_dev_status VARCHAR2(100);
    v_message    VARCHAR2(100);
    b_result     BOOLEAN;

  BEGIN
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début Launch_Loader_relation');
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Lancement de chargement du fichier dans la table d''interface spécifique : ');

    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT, 'CHARGEMENT DU FICHIER :');
    fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
    ------------------------------------------------------
    -- Lancement du traitement de chargement du fichier --
    ------------------------------------------------------
    -- Positionnement des options d'impression
    b_result := fnd_request.set_print_options(printer => gv_printer,
                                              copies  => g_number_of_copies);
    -- Lancement du traitement
    g_loader_request_id := Fnd_Request.submit_request('DKA' -- APPL
                                                     ,
                                                      'DKA_LOADER_REPARRELCLIIMP' -- PROG
                                                     ,
                                                      NULL -- PROGRAM_NAME
                                                     ,
                                                      NULL -- START
                                                     ,
                                                      FALSE -- SUB_REQUEST
                                                      );

    IF g_loader_request_id = 0 THEN
      p_retcode := 2;
      fnd_file.put_line(fnd_file.LOG,
                        'ERREUR : Le traitement de chargement du fichier a échoué' ||
                        CHR(10) || 'PROGRAMME  : DKA_LOADER_REPARRELCLIIMP' ||
                        CHR(10));
      Fnd_File.put_line(Fnd_File.OUTPUT,
                        '====> ERREUR : Le traitement de chargement du fichier a échoué');
    ELSE
      COMMIT;
      Fnd_File.put_line(Fnd_File.LOG,
                        '=> LOAD REQUEST ID= ' || g_loader_request_id);
      Fnd_File.put_line(Fnd_File.OUTPUT,
                        '. Numéro du traitement de chargement du fichier : ' ||
                        g_loader_request_id);

      -- Attente de la fin du traitement
      IF NOT (Fnd_Concurrent.wait_for_request(g_loader_request_id,
                                              g_tempo,
                                              0,
                                              v_phase,
                                              v_status,
                                              v_dev_phase,
                                              v_dev_status,
                                              v_message)) THEN
        p_errbuf := v_Message;
        Fnd_file.put_line(Fnd_file.log,
                          'ERREUR : Attente de la fin du programme de chargement du fichier dépassée : Fin du traitement' ||
                          CHR(10) || 'MESSAGE : ' || v_Message || CHR(10));
      END IF;

      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
        Fnd_File.put_line(Fnd_File.LOG,
                          'COMPLETION= ' || v_dev_phase || '/' ||
                          v_dev_status);
        Fnd_File.put_line(Fnd_File.OUTPUT,
                          '. Statut de fin : ' || v_phase || '/' ||
                          v_status);

        UPDATE DKA_CLIENTS_REL_TMP
           SET load_request_id = g_loader_request_id
         WHERE load_request_id IS NULL;

        SELECT COUNT(*)
          INTO g_summary.loaded_rows_cli
          FROM DKA_CLIENTS_REL_TMP
         WHERE load_request_id = g_loader_request_id;
        Fnd_File.put_line(Fnd_File.LOG,
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                          ' Nbre enregistrements charges clients => ' ||
                          g_summary.loaded_rows_cli);


      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
        Fnd_File.put_line(Fnd_File.LOG,
                          'Fin du traitement de chargement en warning ' ||
                          g_loader_request_id);
        p_retcode := 1;

      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
        p_retcode := 2;
        p_errbuf  := 'ERREUR : Fin anormale du traitement de chargement : ' ||
                     v_Message;

        fnd_file.put_line(fnd_file.LOG,
                          'ERREUR : Fin anormale du traitement de chargement ' ||
                          g_loader_request_id || CHR(10) ||
                          'Phase/Statut : ' || v_dev_phase || '/' ||
                          v_dev_status || CHR(10) || 'MESSAGE : ' ||
                          v_message || CHR(10));
        Fnd_File.put_line(Fnd_File.OUTPUT,
                          '===> ERREUR : Fin anormale du traitement de chargement ' ||
                          g_loader_request_id);
      END IF;

    END IF;

    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin Launch_Loader');

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'LAUNCH_LOADER_RELATION : ' || SQLERRM;
      Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure Launch_Loader_relation : EXCEPTION OTHERS ');
  END Launch_Loader_relation;

  /*
     *************************************************************************
     * PROCEDURE NAME : validate_data
     *
     * DESCRIPTION
     *  Procédure de transcodification et de validation des données
     *
     * PARAMETERS
     * ==========
     * NAME                 DESCRIPTION
    .* -------------------- ---------------------------------------------------
     * p_errbuf            Retour de message éventuel
     * p_retcode           Statut du traitement en sortie
     ************************************************************************
     */

  PROCEDURE validate_data_relation(p_errbuf  OUT VARCHAR2,
                                   p_retcode OUT NUMBER) IS

    CURSOR cur_rec_tmp IS
        select tmp.*, tmp.rowid rid from  DKA_CLIENTS_REL_TMP tmp
        where statut NOT IN (gv_statut_ok);

    v_flag_erreur       BOOLEAN := FALSE;
    v_flag_erreur_rec   BOOLEAN := FALSE;
    v_rec               VARCHAR2(10);
    v_exists            VARCHAR2(10);
    v_collector         VARCHAR2(10);
    v_collector_tmp     VARCHAR2(10);
    v_region            VARCHAR2(10);
    v_test              VARCHAR2(10);
    v_partner_code      VARCHAR2(10);
    v_receipt_method    VARCHAR2(30);
    v_customer_category VARCHAR2(30);
    v_user_id           NUMBER;

    v_bank_name   VARCHAR2(150);
    v_branch_name VARCHAR2(150);
    ln_count      NUMBER;

  BEGIN

    v_user_id := fnd_profile.VALUE('USER_ID');

    -----------------------------------------------------------------------------
    --
    -- Parcours du curseur temporaire des recouvrements
    --

    FOR rec IN cur_rec_tmp LOOP

      IF rec.customer_number = rec.related_customer_number THEN
        v_flag_erreur := TRUE;

        UPDATE dka_clients_rel_tmp
           SET statut        = gv_statut_ko,
               error_message = 'Le client et la relation sont identiques'
         WHERE ROWID = rec.rid;
        COMMIT;
        continue;
      END IF;

      select count(1) into ln_count
      from dka_clients_rel_tmp where customer_number = rec.customer_number
      and related_customer_number = rec.related_customer_number;

      IF ln_count > 1 THEN
        v_flag_erreur := TRUE;

        UPDATE dka_clients_rel_tmp
           SET statut        = gv_statut_ko,
               error_message = 'La relation est en doublon'
         WHERE ROWID = rec.rid;
        COMMIT;
        continue;
      END IF;

      SELECT COUNT(1) INTO ln_count
      FROM hz_cust_accounts      hca
       WHERE hca.account_number = rec.customer_number;

      IF ln_count = 0 THEN
        v_flag_erreur := TRUE;

        UPDATE dka_clients_rel_tmp
           SET statut        = gv_statut_ko,
               error_message = 'Le client n''existe pas'
         WHERE ROWID = rec.rid;
        COMMIT;
        continue;
      END IF;

      SELECT COUNT(1) INTO ln_count
      FROM hz_cust_accounts      hca
       WHERE hca.account_number = rec.related_customer_number;

      IF ln_count = 0 THEN
        v_flag_erreur := TRUE;

        UPDATE dka_clients_rel_tmp
           SET statut        = gv_statut_ko,
               error_message = 'Le client lié n''existe pas'
         WHERE ROWID = rec.rid;
        COMMIT;
        continue;
      END IF;


      SELECT COUNT(1)
        INTO ln_count
        FROM hz_cust_accounts       hca,
             hz_cust_acct_sites_all hcas,
             hz_cust_site_uses_all  hcsu,
             hr_operating_units     hou
       WHERE hca.account_number = rec.customer_number
         AND hca.cust_account_id = hcas.cust_account_id
         AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
         AND hcsu.org_id = hou.organization_id
         AND sysdate between nvl(hou.date_from, sysdate) and nvl(hou.date_to, sysdate) --artf2084473
         --and hcsu.primary_flag = 'Y'
         and hcsu.status = 'A'
         AND EXISTS
       (SELECT 'x'
                FROM hz_cust_accounts       hca2,
                     hz_cust_acct_sites_all hcas2,
                     hz_cust_site_uses_all  hcsu2
               WHERE hca2.account_number = rec.related_customer_number
                 AND hca2.cust_account_id = hcas2.cust_account_id
                 AND hcas2.cust_acct_site_id = hcsu2.cust_acct_site_id
                 AND hcsu2.org_id = hcsu.org_id
                 --and hcsu2.primary_flag = 'Y'
                 and hcsu2.status = 'A');

      IF ln_count = 0 THEN
        v_flag_erreur := TRUE;

        UPDATE dka_clients_rel_tmp
           SET statut        = gv_statut_ko,
               error_message = 'Les 2 clients ne possèdent pas d''organisation en commun'
         WHERE ROWID = rec.rid;
        COMMIT;
        continue;
      END IF;

      UPDATE dka_clients_rel_tmp
         SET statut = gv_statut_valid, error_message = NULL
       WHERE ROWID = rec.rid;
      COMMIT;
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'validate_data_relation : ' || SQLERRM;
      Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure validate_data_relation : EXCEPTION OTHERS ');
  END validate_data_relation;

  /*
   *************************************************************************
   * PROCEDURE NAME : import_data_relation
   *
   * DESCRIPTION
   *  Procédure d'importation des données
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE import_data_relation(p_errbuf  OUT VARCHAR2,
                                 p_retcode OUT NUMBER) IS

    p_init_msg_list        VARCHAR2(200);
    p_cust_acct_relate_rec apps.hz_cust_account_v2pub.cust_acct_relate_rec_type;
    x_return_status        VARCHAR2(200);
    x_msg_count            NUMBER;
    x_msg_data             VARCHAR2(4000);

    v_flag_erreur          BOOLEAN := FALSE;
    v_erreur_message       VARCHAR2(4000);

    CURSOR cur_rec IS
      SELECT DISTINCT
             tmp.ROWID rid,
             hca.cust_account_id cust_account_id,
             hca2.cust_account_id related_cust_account_id,
             tmp.customer_reciprocal_flag,
             tmp.bill_to_flag,
             tmp.ship_to_flag
        FROM dka_clients_rel_tmp    tmp,
             hz_cust_accounts       hca,
             hz_cust_accounts       hca2
       WHERE hca.account_number = tmp.related_customer_number
         AND hca2.account_number = tmp.customer_number
         AND tmp.statut IN (gv_statut_valid, gv_statut_rejected);

    CURSOR cur_ou (p_customer_id in number, p_related_customer_id in number) IS
      SELECT DISTINCT hou.organization_id
        FROM hz_cust_acct_sites_all hcas,
             hz_cust_site_uses_all  hcsu,
             hr_operating_units     hou
       WHERE hcas.cust_account_id = p_customer_id
         AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
         AND hcsu.org_id = hou.organization_id
         AND sysdate between nvl(hou.date_from, sysdate) and nvl(hou.date_to, sysdate) --artf2084473
         --and hcsu.primary_flag = 'Y'
         and hcsu.status = 'A'
         AND EXISTS
       (SELECT 'x'
                FROM hz_cust_acct_sites_all hcas2,
                     hz_cust_site_uses_all  hcsu2
               WHERE hcas2.cust_account_id = p_related_customer_id
                 AND hcas2.cust_acct_site_id = hcsu2.cust_acct_site_id
                 AND hcsu2.org_id = hcsu.org_id
                 --and hcsu2.primary_flag = 'Y'
                 and hcsu2.status = 'A');

  BEGIN

    FOR rec IN cur_rec LOOP
      -- Initializing the Mandatory API parameters
      x_msg_data := NULL;

      p_cust_acct_relate_rec.cust_account_id         := rec.cust_account_id;
      p_cust_acct_relate_rec.related_cust_account_id := rec.related_cust_account_id;

      v_flag_erreur := FALSE;
      v_erreur_message := NULL;

      FOR rec_ou IN cur_ou (rec.cust_account_id, rec.related_cust_account_id) LOOP

        p_cust_acct_relate_rec.relationship_type        := 'ALL';
        p_cust_acct_relate_rec.created_by_module        := 'BO_API';
        p_cust_acct_relate_rec.org_id                   := rec_ou.organization_id;
        p_cust_acct_relate_rec.customer_reciprocal_flag := nvl(rec.customer_reciprocal_flag, 'N');
        p_cust_acct_relate_rec.bill_to_flag             := nvl(rec.bill_to_flag, 'N');
        p_cust_acct_relate_rec.ship_to_flag             := nvl(rec.ship_to_flag, 'N');

        hz_cust_account_v2pub.create_cust_acct_relate(p_init_msg_list        => fnd_api.g_true,
                                                      p_cust_acct_relate_rec => p_cust_acct_relate_rec,
                                                      x_return_status        => x_return_status,
                                                      x_msg_count            => x_msg_count,
                                                      x_msg_data             => x_msg_data);

        IF x_return_status <> fnd_api.g_ret_sts_success THEN
          v_flag_erreur := TRUE;

          FOR i IN 1 .. x_msg_count LOOP
            v_erreur_message := substr(v_erreur_message || ',' ||
                          fnd_msg_pub.get(p_msg_index => i, p_encoded => 'F'), 1, 1000);
          END LOOP;
        END IF;
      END LOOP;

      IF v_flag_erreur = TRUE THEN

        ROLLBACK;

        UPDATE dka_clients_rel_tmp
           SET statut = gv_statut_rejected, error_message = v_erreur_message
         WHERE ROWID = rec.rid;

      ELSE

         UPDATE dka_clients_rel_tmp
             SET statut = gv_statut_ok, error_message = null
           WHERE ROWID = rec.rid;

      END IF;

      COMMIT;

    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'import_data_relation : ' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure import_data_relation : EXCEPTION OTHERS ');

  END import_data_relation;

 PROCEDURE generate_output_relation(p_err_buf OUT VARCHAR2, p_ret_code OUT NUMBER) IS
   -- =============================================================================
   -- Name         : generate_output
   -- Type         : Procedure
   -- Description  : Liste les erreurs
   -- Author       : Nicolas Boussekeyt
   -- Updated by   :
   -- Date Created : 01-12-2016
   -- Updated      :
   -- Parameters   : p_err_buf  OUT VARCHAR2 - error messages
   --                           p_ret_code OUT NUMBER   - error code
   --
   -- =============================================================================
   CURSOR cur_erreur IS
     SELECT statut, error_message, COUNT(1) cpt
       FROM dka_clients_rel_tmp
      GROUP BY statut, error_message;

   l_count NUMBER;

 BEGIN
   fnd_file.put_line(fnd_file.output, '----------------');
   fnd_file.put_line(fnd_file.output,
                     ' | status  | message d''erreur                                                  | compteur |');
   FOR rec_erreur IN cur_erreur LOOP
     fnd_file.put_line(fnd_file.output,
                       ' | ' || rpad(rec_erreur.statut,9,' ') || ' | ' ||
                       rpad(rec_erreur.error_message,68,' ') || ' | ' || rpad(rec_erreur.cpt,10,' ')|| '|');
   END LOOP;
   fnd_file.put_line(fnd_file.output, '----------------');

   SELECT COUNT(1) INTO l_count FROM dka_clients_rel_tmp;

   fnd_file.put_line(fnd_file.output,
                     'Nombre de lignes dans le fichier : ' || l_count);

   SELECT COUNT(1)
     INTO l_count
     FROM dka_clients_rel_tmp
    WHERE statut = gv_statut_ko;

   fnd_file.put_line(fnd_file.output,
                     'Nombre de lignes invalides lors des controles : ' ||
                     l_count);

   SELECT COUNT(1)
     INTO l_count
     FROM dka_clients_rel_tmp
    WHERE statut = gv_statut_rejected;

   fnd_file.put_line(fnd_file.output,
                     'Nombre de lignes rejetées dans l''interface : ' ||
                     l_count);

   SELECT COUNT(1)
     INTO l_count
     FROM dka_clients_rel_tmp
      WHERE statut = gv_statut_ok;

   fnd_file.put_line(fnd_file.output,
                     'Nombre de lignes inseres par l''interface : ' ||
                     l_count);

 EXCEPTION
   WHEN OTHERS THEN
     p_err_buf  := 'generate_output_relation : ' || ':' || SQLERRM;
     p_ret_code := 2;
 END;

  /*
   *************************************************************************
   * PROCEDURE NAME : main
   *
   * DESCRIPTION
   *  Procédure principale de l'interface de création des fournisseurs
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * p_directory      Repertoire
   * p_file_name      Nom du fichier à charger
   ************************************************************************
   */

  PROCEDURE main(p_errbuf  IN OUT VARCHAR2,
                 p_retcode OUT NUMBER,
                 p_reprise IN VARCHAR2) IS

    v_current_program_unit VARCHAR2(30);
    v_errbuf               VARCHAR2(2500);
    v_retcode              NUMBER;
    Erreur_Programme EXCEPTION;

  BEGIN

    ----------------------------
    -- PHASE D'INITIALISATION --
    ----------------------------

    v_current_program_unit := 'main';
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'DEBUT DE L''INTERFACE');

    Output_Header;
    Request_parameters;

    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE D''INITIALISATION');

    v_errbuf  := NULL;
    v_retcode := 0;

    Init(v_errbuf, v_retcode);

    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;

    IF p_reprise = 'N' THEN

      ------------------------------------
      -- PHASE DE CHARGEMENT DU FICHIER --
      ------------------------------------
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'PHASE DE CHARGEMENT DU FICHIER');

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
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE DE VALIDATION DES DONNEES');

    validate_data(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;

    --------------------------------
    -- PHASE D'IMPORT DES DONNEES --
    --------------------------------
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE D''IMPORT DES DONNEES');

    import_data(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;

    --------------------------------
    -- PHASE D'IMPORT DES BANK    --
    --------------------------------
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE D''IMPORT DES DONNEES');

    import_data_bank(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;

    ----------------------------------
    -- PHASE DE BILAN DU TRAITEMENT --
    ----------------------------------

    Report_Bilan(v_errbuf, v_retcode);

    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      --RAISE Erreur_Programme;
    END IF;

    ------------------------------------
    -- PHASE DE CHARGEMENT DU FICHIER --
    ------------------------------------
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE DES ANOMALIES');

    print_errors;

    ---------------------------------------
    -- PHASE DE FIN DU TRAITEMENT MAITRE --
    ---------------------------------------
    IF p_retcode = 2 THEN
      p_errbuf := 'ATTENTION : Erreur bloquante : ' || p_errbuf;
    ELSIF (g_summary.rejected_rows > 0 OR g_summary.rejected_rows_cli > 0 OR
          g_summary.rejected_rows_rec > 0 OR g_summary.warning_rows > 0) THEN
      p_errbuf  := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
      p_retcode := 1;
--    ELSIF (g_summary.loaded_rows_cli = 0) AND
--          (g_summary.loaded_rows_rec = 0) THEN
--      p_errbuf  := 'ATTENTION : Aucun enregistrement chargé.';
--      p_retcode := 1;
    ELSE
      p_errbuf  := 'Fin normale du traitement - Aucun rejet.';
      p_retcode := 0;
    END IF;

    Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
    Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || p_errbuf || CHR(10));
    output_end;
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'FIN DE L''INTERFACE');

  EXCEPTION
    WHEN Erreur_Programme THEN
      p_retcode := 2;
      p_errbuf  := v_errbuf;
      Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || p_errbuf);
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure ' || v_current_program_unit ||
                        ' : EXCEPTION Erreur_Traitement ');
      Fnd_File.put_line(Fnd_File.OUTPUT,
                        '==> Fin de la procédure ' ||
                        v_current_program_unit ||
                        ' : EXCEPTION Erreur_Traitement ');
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Fnd_File.put_line(Fnd_File.Log,
                        'Erreur technique sur le composant   : ' ||
                        'DKA_REPARCLIIMP_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
  END main;

  -- 16/12/2016 NBO artf2062780 - REP002 - Export / Import - Gestion des relations
  /*
   *************************************************************************
   * PROCEDURE NAME : main_relation
   *
   * DESCRIPTION
   *  Procédure principale de l'interface de création des fournisseurs
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * p_directory      Repertoire
   * p_file_name      Nom du fichier à charger
   ************************************************************************
   */

  PROCEDURE main_relation(p_errbuf  IN OUT VARCHAR2,
                 p_retcode OUT NUMBER,
                 p_reprise IN VARCHAR2) IS

    v_current_program_unit VARCHAR2(30);
    v_errbuf               VARCHAR2(2500);
    v_retcode              NUMBER;
    Erreur_Programme EXCEPTION;

  BEGIN

   IF p_reprise = 'N' THEN

      ------------------------------------
      -- PHASE DE CHARGEMENT DU FICHIER --
      ------------------------------------
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'PHASE DE CHARGEMENT DU FICHIER');

      -- Lancement du programme de chargement
      Launch_Loader_relation(v_errbuf, v_retcode);
      IF v_retcode = 2 THEN
        RAISE Erreur_Programme;
      END IF;

    END IF;

    -------------------------------------
    -- PHASE DE VALIDATION DES DONNEES --
    -------------------------------------
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE DE VALIDATION DES DONNEES');

    validate_data_relation(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;

    --------------------------------
    -- PHASE D'IMPORT DES DONNEES --
    --------------------------------
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE D''IMPORT DES DONNEES');

    import_data_relation(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;

    ----------------------------------
    -- PHASE DE BILAN DU TRAITEMENT --
    ----------------------------------

    generate_output_relation(v_errbuf, v_retcode);

    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Fnd_File.put_line(Fnd_File.Log,
                        'Erreur technique sur le composant   : ' ||
                        'DKA_REPARCLIIMP_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
  END main_relation;

END DKA_REPARCLIIMP_PKG;
/
SHOW ERRORS
EXIT
