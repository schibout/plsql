SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

create or replace PACKAGE BODY dka_repfaimoimp_pkg IS
  --------------------------------------------------------------------------------------------
  -- FILENAME
  --    DKA_REPFAIMOIMP_PKG.pkb  V1.0
  --
  -- AUTEUR
  --    Capgemini
  --
  -- DESCRIPTION
  --    Création du package de l'interface specifique des immobilisations
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
  -- V1.0    12/04/2016     OBN Creation
  -- V1.1    24/11/2016     EFL artf2050223: Le numero de tache doit commencer par GY.
  -- V1.2	   19/12/2016		  NBO - artf2067886 - Controle depreciation method / life in months
  -- V1.3	   09/01/2017		  NBO - artf2067886 - Controle depreciation method / life in months
  -- V1.4    22/03/2017     NBO Correction suite à la reprise du RUN3
  -- V1.5    28/03/2017     NBO artf2134133 - REP009 - Import - Valorisation de la VNC incorrecte
  -- V1.6    05/04/2017     NBO artf2134134 - REP009 - Import - Mise a jour des projets PA
  -- V1.7    06/04/2017     JLY artfxxxxxxx - REP009 - Import - Etat Imputation des acquisitions en haut volume en erreur
  -- V1.8    11/04/2017     NBO artf2136811 - REP009 - Import - Charger l'interface de livre de gestion en erreur
  -- V1.9    20/04/2017     NBO artf2134134 - REP009 - Import - Mise a jour des projets PA
  -- V1.10   28/08/2017     NBO artf2211081 - REP009 - Import - Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
  -- V1.11   22/09/2017     NBO artf2211081 - REP009 - Import - Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
  -- V1.12   23/02/2021    SELO EDB291
  ---------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  TYPE summary_typ IS RECORD(
      loaded_rows_social    NUMBER -- Nb de Lignes chargées en table spécifique
    , loaded_rows_IFRS      NUMBER -- Nb de Lignes chargées en table spécifique
    , rejected_rows         NUMBER -- Nb de lignes rejetées en table spécifique
    , valid_rows_social     NUMBER -- Nb de lignes presentes pour les livres fiscaux
    , valid_rows_IFRS       NUMBER -- Nb de lignes presentes pour les livres fiscaux
    , import_rows_social    NUMBER -- Nb de lignes presentes pour les livres fiscaux
    , import_rows_IFRS      NUMBER -- Nb de lignes presentes pour les livres fiscaux
    );

  g_summary summary_typ;

  g_user_id           fnd_user.user_id%TYPE;
  g_login_id          fnd_logins.login_id%TYPE;
  g_request_id        fnd_concurrent_requests.request_id%TYPE;
  g_loader_request_id fnd_concurrent_requests.request_id%TYPE;
  gv_printer          fnd_concurrent_requests.printer%TYPE;
  g_number_of_copies  fnd_concurrent_requests.number_of_copies%TYPE;
  g_tempo             NUMBER;

  TYPE tab_request IS TABLE OF fnd_concurrent_requests.request_id%TYPE INDEX BY BINARY_INTEGER;
  g_tab_requests   tab_request;

  gv_statut_new   VARCHAR2(20) := 'NEW';
  gv_statut_valid VARCHAR2(20) := 'VALID';
  gv_statut_ko    VARCHAR2(20) := 'INVALID';
  gv_statut_ok    VARCHAR2(20) := 'IMPORTED';
  --gv_statut_rejected VARCHAR2(20) := 'REJECTED';
  gv_statut_postimport VARCHAR2(20) := 'POST_IMPORT';

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

    v_step_program_error VARCHAR2(1000);
    program_error EXCEPTION;

  BEGIN

    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début init');

    ----------------------------------
    -- Initialisation des variables --
    ----------------------------------
    p_errbuf  := NULL;
    p_retcode := 0;

    ------------------------
    -- Variables globales --
    ------------------------

    g_user_id    := fnd_global.user_id;
    g_login_id   := fnd_global.login_id;
    g_request_id := fnd_global.conc_request_id;
    g_tempo      := 60;

    -- Variables globales de comptage

    g_summary.loaded_rows_social    := 0;
    g_summary.loaded_rows_IFRS      := 0;
    g_summary.rejected_rows         := 0;
    g_summary.valid_rows_social     := 0;
    g_summary.valid_rows_IFRS       := 0;
    g_summary.import_rows_social    := 0;
    g_summary.import_rows_IFRS      := 0;

    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin init');

    BEGIN
      SELECT printer, number_of_copies
        INTO gv_printer, g_number_of_copies
        FROM fnd_concurrent_requests fcr
       WHERE fcr.request_id = g_request_id;
    EXCEPTION
      WHEN no_data_found THEN
        fnd_file.put_line(fnd_file.log,
                          to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
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
       WHERE fcp.application_id = fnd_global.prog_appl_id
         AND fcp.concurrent_program_id = fnd_global.conc_program_id
         AND fcpt.application_id = fnd_global.prog_appl_id
         AND fcpt.concurrent_program_id = fnd_global.conc_program_id
         AND fcpt.LANGUAGE = fnd_global.current_language;
    EXCEPTION
      WHEN OTHERS THEN
        v_user_conc_program_name := '???????????????????????';
        v_conc_program_name      := '???????';
    END;

    fnd_file.put_line(fnd_file.output, cv_line || chr(10));
    fnd_file.put_line(fnd_file.output,
                      'Nom du traitement  : ' || v_user_conc_program_name);
    fnd_file.put_line(fnd_file.output,
                      'Code du traitement : ' || v_conc_program_name);
    fnd_file.put_line(fnd_file.output,
                      'Programme lancé le : ' ||
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || chr(10));
    fnd_file.put_line(fnd_file.output, cv_line || chr(10) || chr(10));
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

  PROCEDURE request_parameters IS

    CURSOR cur_parameters IS
      SELECT form_left_prompt
        FROM fnd_concurrent_requests     fcr,
             fnd_concurrent_programs     fcp,
             fnd_descr_flex_col_usage_vl fdfcu
       WHERE fdfcu.descriptive_flexfield_name =
             '$SRS$.' || fcp.concurrent_program_name
         AND fcp.concurrent_program_id = fcr.concurrent_program_id
         AND fcr.request_id = fnd_global.conc_request_id
       ORDER BY fdfcu.column_seq_num;
    rec_parameters cur_parameters%ROWTYPE;

    sql_req           VARCHAR2(500);
    v_argument_number VARCHAR2(12);
    v_argument_num    NUMBER;
    v_argument_value  VARCHAR2(240);
  BEGIN

    fnd_file.put_line(fnd_file.output, 'PARAMETRES : ');
    fnd_file.put_line(fnd_file.output, '--------------');
    fnd_file.put_line(fnd_file.log, 'PARAMETRES : ');
    fnd_file.put_line(fnd_file.log, '--------------');

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

      fnd_file.put_line(fnd_file.output,
                        rec_parameters.form_left_prompt || ' : ' ||
                        v_argument_value);
      fnd_file.put_line(fnd_file.log,
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

        fnd_file.put_line(fnd_file.output,
                          rec_parameters.form_left_prompt || ' : ' ||
                          v_argument_value);
        fnd_file.put_line(fnd_file.log,
                          rec_parameters.form_left_prompt || ' : ' ||
                          v_argument_value);
      END LOOP;

      fnd_file.put_line(fnd_file.output, chr(10));

    ELSE
      fnd_file.put_line(fnd_file.output, 'Aucun argument');
      fnd_file.put_line(fnd_file.log, 'Aucun argument');
    END IF;

    CLOSE cur_parameters;

  END request_parameters;

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

    fnd_file.put_line(fnd_file.output, cv_line || chr(10));
    fnd_file.put_line(fnd_file.output,
                      'Programme terminé le : ' ||
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || chr(10));
    fnd_file.put_line(fnd_file.output, cv_line);
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
      SELECT * FROM dka_program_messages WHERE request_id = g_request_id;

  BEGIN

    fnd_file.put_line(fnd_file.output, chr(10)||chr(10));
    fnd_file.put_line(fnd_file.output, 'LISTE DES ANOMALIES :');
    fnd_file.put_line(fnd_file.output, '---------------------------------------------------------------------------------------------');

    FOR msg IN cur_prog_mess LOOP
      fnd_file.put_line(fnd_file.output, '. ' || RPAD(msg.column_name, 30) || '|' || RPAD(msg.column_value, 30) || '|' || msg.message_text);
    END LOOP;

  END print_errors;

----------------------------------------------------------------------------------------
--  Nom           : GET_CODE_COMBINATION_ID
--  Description   : Procédure permettant de déterminer le code_combination_id
--                  correspondant a la combinaison passée en parametre
--                  Si la combinaison n'existe pas, elle est créée
--                  Si la combinaison n'existe pas, elle est créée
--  PARAMETRES :
--    pv_segment1       Entrée
--    pv_segment2       Entrée
--    pv_segment3       Entrée
--    pv_segment4       Entrée
--    pv_segment5       Entrée
--    pv_segment6       Entrée
--    pv_segment7       Entrée
--    pv_segment8       Entrée
--    pv_segment9       Entrée
--    pv_segment10      Entrée
--    pv_segment11      Entrée
--    pv_segment12      Entrée
--
--    pn_ccid           Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
----------------------------------------------------------------------------------------
    PROCEDURE get_code_combination_id (
        pv_segment1              IN       VARCHAR2,
        pv_segment2              IN       VARCHAR2,
        pv_segment3              IN       VARCHAR2,
        pv_segment4              IN       VARCHAR2,
        pv_segment5              IN       VARCHAR2,
        pv_segment6              IN       VARCHAR2,
        pv_segment7              IN       VARCHAR2,
        pv_segment8              IN       VARCHAR2,
        pv_segment9              IN       VARCHAR2,
        pv_segment10             IN       VARCHAR2,
        pv_segment11             IN       VARCHAR2,
        pv_segment12             IN       VARCHAR2,
        pn_code_combination_id   OUT      NUMBER,
        pv_errbuf                OUT      VARCHAR2,
        pn_retcode               OUT      NUMBER,
        pv_validation_flag       IN       VARCHAR2 DEFAULT 'Y'
    )
    IS
        vb_dummy                    BOOLEAN;
        va_segments_array           Fnd_Flex_Ext.segmentarray;
        vn_nb_segments              NUMBER;
        vv_application_short_name   fnd_application.application_short_name%TYPE;
        vv_key_flex_code            fnd_id_flex_segments.id_flex_code%TYPE;
        vn_structure_number         fnd_id_flex_segments.id_flex_num%TYPE;
        vd_validation_date          DATE;
        vn_code_combination_id      gl_code_combinations.code_combination_id%TYPE;
    BEGIN
        -- Initialisation des variables de sortie
        pv_errbuf                    := NULL;
        pn_retcode                   := 0;
        -- Initialisation des variables
        vd_validation_date           := SYSDATE;
        vv_key_flex_code             := 'GL#';
        vv_application_short_name    := 'SQLGL';

        select  fifs.id_flex_num,count(1)
        INTO     vn_structure_number,
                 vn_nb_segments
        from
         (select *
          from gl_access_set_assignments
          where access_set_id =  1040
          and rownum = 1) gasa,
         gl_ledgers gl,
         FND_ID_FLEX_SEGMENTS fifs
        where
             gl.ledger_id = gasa.ledger_id
         and gl.ledger_category_code = 'PRIMARY'
         and gl.chart_of_accounts_id = fifs.id_flex_num
         AND fifs.application_id = 101
         AND fifs.id_flex_code =  'GL#'
         and fifs.enabled_flag = 'Y'
         GROUP BY fifs.id_flex_num;

        -- Si la vérification des regles n'est pas nécessaire, on regarde si la combinaison existe
        -- Dans ce cas, on retourne ce ccid directement
        IF pv_validation_flag = 'N'
        THEN
            BEGIN
                SELECT gcc.code_combination_id
                INTO   pn_code_combination_id
                FROM   gl_code_combinations gcc
                WHERE      gcc.chart_of_accounts_id = vn_structure_number
                       AND gcc.segment1 = pv_segment1
                       AND gcc.segment2 = pv_segment2
                       AND gcc.segment3 = pv_segment3
                       AND gcc.segment4 = pv_segment4
                       AND gcc.segment5 = pv_segment5
                       AND gcc.segment6 = pv_segment6
                       AND gcc.segment7 = pv_segment7
                       AND gcc.segment8 = pv_segment8
                       AND gcc.segment9 = pv_segment9
                       AND gcc.segment10 = pv_segment10
                       AND gcc.segment11 = pv_segment11
                       AND gcc.segment12 = pv_segment12;

                -- On a trouvé la combinaison, donc on sort
                RETURN;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    NULL;
            END;
        END IF;

        -- Remplissage de la variable Array
        va_segments_array (1)        := pv_segment1;
        va_segments_array (2)        := pv_segment2;
        va_segments_array (3)        := pv_segment3;
        va_segments_array (4)        := pv_segment4;
        va_segments_array (5)        := pv_segment5;
        va_segments_array (6)        := pv_segment6;
        va_segments_array (7)        := pv_segment7;
        va_segments_array (8)        := pv_segment8;
        va_segments_array (9)        := pv_segment9;
        va_segments_array (10)       := pv_segment10;
        va_segments_array (11)       := pv_segment11;
        va_segments_array (12)       := pv_segment12;

        -- Lancement de la fonction standard de détermination / génération du ccid
        vb_dummy                     := Fnd_Flex_Ext.get_combination_id (
                                            vv_application_short_name,
                                            vv_key_flex_code,
                                            vn_structure_number,
                                            vd_validation_date,
                                            vn_nb_segments,
                                            va_segments_array,
                                            vn_code_combination_id
                                        );

        -- En cas d'erreur, récupération du message
        IF NOT vb_dummy
        THEN
            pv_errbuf                 :=    pv_segment1
                                         || '.'
                                         || pv_segment2
                                         || '.'
                                         || pv_segment3
                                         || '.'
                                         || pv_segment4
                                         || '.'
                                         || pv_segment5
                                         || '.'
                                         || pv_segment6
                                         || '.'
                                         || pv_segment7
                                         || '.'
                                         || pv_segment8
                                         || '.'
                                         || pv_segment9
                                         || '.'
                                         || pv_segment10
                                         || '.'
                                         || pv_segment11
                                         || '.'
                                         || pv_segment12
                                         || ' : '
                                         || Fnd_Flex_Ext.get_message;
            pn_retcode                := 2;
            pn_code_combination_id    := NULL;
        ELSE
            pn_code_combination_id    := vn_code_combination_id;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := 'GET_CODE_COMBINATION_ID - ' || SQLERRM;
            pn_retcode    := SQLCODE;
    END get_code_combination_id;

  /*
   *************************************************************************
   * PROCEDURE NAME : duplicate_calisto_social
   *
   * DESCRIPTION
   *  Procédure de duplication des immoblisation calisto devant être créés en social également
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE duplicate_calisto_social(p_errbuf  OUT VARCHAR2,
                                 p_retcode OUT NUMBER) IS

    CURSOR cur_duplicate_data IS
      SELECT  *
      FROM    DKA_REP009_CALISTO_INTERFACE dk
      WHERE   nvl(DUPLICATE_STATUS, gv_statut_new) IN (gv_statut_new, gv_statut_ko)
      AND     (    RUB_DETAIL LIKE 'SUB%'
                OR RUB_DETAIL LIKE 'CEE%'
                OR RUB_DETAIL LIKE 'DRC%'
                OR RUB_DETAIL LIKE 'COGEOH%'
              )
      FOR UPDATE;

    l_step                 VARCHAR2(50);
    v_flag_erreur          BOOLEAN;

    ld_current_period     DATE;
    ln_cost               NUMBER;
    ln_amortissement_cumule NUMBER;

  BEGIN
    fnd_file.put_line(fnd_file.log,
                      'duplicate_calisto_social : start : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));

    p_retcode := 0;

    SELECT  max(calendar_period_close_date)
    INTO    ld_current_period
    FROM    fa_deprn_periods;

    FOR rec_duplicate_data IN cur_duplicate_data LOOP
      BEGIN
         -- V1.10   28/08/2017     NBO artf2211081 - REP009 - Import - Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
         -- V1.11   22/09/2017     NBO artf2211081 - REP009 - Import - Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
         /*IF rec_duplicate_data.RUB_DETAIL LIKE 'SUB%'
                OR rec_duplicate_data.RUB_DETAIL LIKE 'CEE%'
                OR rec_duplicate_data.RUB_DETAIL LIKE 'DRC%' THEN
          ln_cost := 0.01;
          ln_amortissement_cumule := 0.01;
        ELSE*/
          ln_cost := rec_duplicate_data.COST;
          ln_amortissement_cumule := rec_duplicate_data.AMORTISSEMENT_CUMULE;
        --END IF;
        
        INSERT INTO DKA_REP009_INTERFACE (
          LIBELLE_IMMO,
          RUB_PRINCIPALE,
          RUB_DETAIL,
          METHODE_AMT,
          PLAFOND_AMT,
          UNITES,
          COST,
          SOCIETE,
          LIEU_PHYSIQUE,
          D_SOCIETE,
          D_UO,
          D_COMPTE_LOCAL,
          D_COMPTE_ANALYTIQUE,
          D_INTERCO,
          D_CENTRE_FI,
          D_AFFAIRE,
          D_PROJET_FI,
          D_FLUX,
          D_RESERVE1,
          D_RESERVE2,
          D_RESERVE3,
          L_SOCIETE,
          L_UO,
          L_COMPTE_LOCAL,
          L_COMPTE_ANALYTIQUE,
          L_INTERCO,
          L_CENTRE_FI,
          L_AFFAIRE,
          L_PROJET_FI,
          L_FLUX,
          L_RESERVE1,
          L_RESERVE2,
          L_RESERVE3,
          DATE_DE_MISE_EN_SERVICE,
          NUMERO_IMMOBILISATION,
          UTILISE,
          PROPRIETE,
          ACHETE,
          TAXE_PROF,
          IMPOT_FONCIER,
          AMORTIR,
          AMORTISSEMENT_CUMULE,
          AMORTISSEMENT_EXERCICE,
          DATE_DE_DEBUT_DE_AMORTISSEMENT,
          METHODE_D_AMORTISSEMENT,
          DUREE_DE_VIE_EN_MOIS,
          PROJET)
        VALUES (
          rec_duplicate_data.LIBELLE_IMMO,
          rec_duplicate_data.RUB_PRINCIPALE,
          rec_duplicate_data.RUB_DETAIL,
          rec_duplicate_data.METHODE_AMT,
          rec_duplicate_data.PLAFOND_AMT,
          rec_duplicate_data.UNITES,
         -- V1.10   28/08/2017     NBO artf2211081 - REP009 - Import - Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
          --rec_duplicate_data.COST,
          ln_cost,
          rec_duplicate_data.SOCIETE,
          rec_duplicate_data.LIEU_PHYSIQUE,
          rec_duplicate_data.D_SOCIETE,
          rec_duplicate_data.D_UO,
          rec_duplicate_data.D_COMPTE_LOCAL,
          rec_duplicate_data.D_COMPTE_ANALYTIQUE,
          rec_duplicate_data.D_INTERCO,
          rec_duplicate_data.D_CENTRE_FI,
          rec_duplicate_data.D_AFFAIRE,
          rec_duplicate_data.D_PROJET_FI,
          rec_duplicate_data.D_FLUX,
          rec_duplicate_data.D_RESERVE1,
          rec_duplicate_data.D_RESERVE2,
          rec_duplicate_data.D_RESERVE3,
          rec_duplicate_data.L_SOCIETE,
          rec_duplicate_data.L_UO,
          rec_duplicate_data.L_COMPTE_LOCAL,
          rec_duplicate_data.L_COMPTE_ANALYTIQUE,
          rec_duplicate_data.L_INTERCO,
          rec_duplicate_data.L_CENTRE_FI,
          rec_duplicate_data.L_AFFAIRE,
          rec_duplicate_data.L_PROJET_FI,
          rec_duplicate_data.L_FLUX,
          rec_duplicate_data.L_RESERVE1,
          rec_duplicate_data.L_RESERVE2,
          rec_duplicate_data.L_RESERVE3,
          rec_duplicate_data.DATE_DE_MISE_EN_SERVICE,
          rec_duplicate_data.NUMERO_IMMOBILISATION,
          rec_duplicate_data.UTILISE,
          rec_duplicate_data.PROPRIETE,
          rec_duplicate_data.ACHETE,
          rec_duplicate_data.TAXE_PROF,
          rec_duplicate_data.IMPOT_FONCIER,
          -- V1.10   11/08/2017     NBO artf2211081 - REP009 - Import - Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
          -- les immos présentes uniquement dans le fichier Calisto (et non existantes en 11i), doivent être créées en Social pour un montant de 0,01 € avec le champ AMORTIR à NON.
          rec_duplicate_data.AMORTIR,
          --'Non',
          CASE WHEN rec_duplicate_data.RUB_DETAIL like 'COGEOH%'
                    AND rec_duplicate_data.AMORTISSEMENT_CUMULE <> 0
               THEN rec_duplicate_data.COST
               --ELSE rec_duplicate_data.AMORTISSEMENT_CUMULE
               ELSE ln_amortissement_cumule
          END, --AMORTISSEMENT_CUMULE
          CASE WHEN rec_duplicate_data.RUB_DETAIL like 'COGEOH%'
                    AND trunc(rec_duplicate_data.DATE_DE_DEBUT_DE_AMORTISSEMENT, 'YYYY') = trunc(ld_current_period, 'YYYY')
               THEN rec_duplicate_data.COST
               ELSE rec_duplicate_data.AMORTISSEMENT_EXERCICE
          END, --AMORTISSEMENT_EXERCICE
          rec_duplicate_data.DATE_DE_DEBUT_DE_AMORTISSEMENT,
          CASE WHEN rec_duplicate_data.RUB_DETAIL like 'COGEOH%'
               THEN 'L0.01'
               ELSE rec_duplicate_data.METHODE_D_AMORTISSEMENT
          END, -- METHODE_D_AMORTISSEMENT
          CASE WHEN rec_duplicate_data.RUB_DETAIL like 'COGEOH%'
               THEN 1
               ELSE rec_duplicate_data.DUREE_DE_VIE_EN_MOIS
          END, -- DUREE_DE_VIE_EN_MOIS
          NULL --PROJET
        );

      EXCEPTION
        WHEN OTHERS THEN
          --v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'DUP',
                                         'DKA_REP009_CALISTO_INTERFACE',
                                         rec_duplicate_data.numero_immobilisation,
                                         'Erreur inconnue',
                                         NULL,
                                         'E',
                                         SQLERRM);
      END;

      v_flag_erreur := FALSE;

      IF NOT v_flag_erreur THEN

        UPDATE  DKA_REP009_CALISTO_INTERFACE
        SET     DUPLICATE_STATUS   = gv_statut_valid
        WHERE   CURRENT OF cur_duplicate_data;

        g_summary.loaded_rows_social := g_summary.loaded_rows_social + 1;

      ELSE
        -- en cas d'erreur

        UPDATE  DKA_REP009_CALISTO_INTERFACE
        SET     DUPLICATE_STATUS             = gv_statut_ko
        WHERE  CURRENT OF cur_duplicate_data;

        g_summary.rejected_rows := g_summary.rejected_rows + 1;

      END IF;

    END LOOP; /* Rec_Social_Data IN Cur_Fiscal_Data */

    fnd_file.put_line(fnd_file.log,
                      'duplicate_calisto_social : end : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'duplicate_calisto_social : ' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        l_step || '-' ||
                        'Fin de la procédure duplicate_calisto_social: EXCEPTION OTHERS ');
  END duplicate_calisto_social;

  /*
   *************************************************************************
   * PROCEDURE NAME : validate_data_social
   *
   * DESCRIPTION
   *  Procédure de validation des données des livrees sociaux
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE validate_data_social(p_errbuf  OUT VARCHAR2,
                                 p_retcode OUT NUMBER) IS

    -- On selectionne toutes les donnees
    -- But: Memoriser tous les livres presents dans la table Fa_Tax_Tmp
    -- Permet dans le cas de reprise sur erreur, de soumettre les traitements standards FATAXUP et FAIMCP
    -- pour tous les livres et pas seulement pour les livres des donnees inserees.

    CURSOR cur_social_data IS
      SELECT  *
      FROM    DKA_REP009_INTERFACE dk
      WHERE   nvl(STATUS, gv_statut_new) IN (gv_statut_new, gv_statut_ko)
      FOR UPDATE;

    v_flag_erreur          BOOLEAN;
    l_count                NUMBER;
    l_step                 VARCHAR2(50);


    application_short_name VARCHAR2(200);
    key_flex_code          VARCHAR2(200);
    structure_number       NUMBER;
    validation_date        DATE;
    n_segments             NUMBER;
    segments               apps.fnd_flex_ext.segmentarray;
    data_set               NUMBER;
    v_return               BOOLEAN;

    ln_category_id         NUMBER;
    ln_asset_key_ccid      NUMBER;
    vn_dotation_ccid       NUMBER;
    vn_lettrage_ccid       NUMBER;
    vv_errbuf_ccid         VARCHAR2(1000);
    vn_retcode_ccid        NUMBER;
    ln_loc_ccid            NUMBER;
    vv_projet              VARCHAR2(50);
    vv_tache               VARCHAR2(50);
    ln_project_id          NUMBER;
    ln_task_id             NUMBER;
    lv_region              VARCHAR2(50);
    --ln_life_in_months      NUMBER;
    ld_current_period      DATE; --< JLY

    v_cat                  VARCHAR2(200);
    v_methode              VARCHAR2(200);
    v_cpt_dot1             VARCHAR2(10);
    v_cpt_dot2             VARCHAR2(10);
    v_cpt_dot3             VARCHAR2(10);
    v_cpt_dot4             VARCHAR2(10);
    v_cpt_dot5             VARCHAR2(10);
    v_cpt_dot6             VARCHAR2(10);
    v_cpt_dot7             VARCHAR2(10);
    v_cpt_dot8             VARCHAR2(10);
    v_cpt_dot9             VARCHAR2(10);
    v_cpt_dot10            VARCHAR2(10);
    v_cpt_dot11            VARCHAR2(10);
    v_cpt_dot12            VARCHAR2(10);

    v_cpt_let1             VARCHAR2(10);
    v_cpt_let2             VARCHAR2(10);
    v_cpt_let3             VARCHAR2(10);
    v_cpt_let4             VARCHAR2(10);
    v_cpt_let5             VARCHAR2(10);
    v_cpt_let6             VARCHAR2(10);
    v_cpt_let7             VARCHAR2(10);
    v_cpt_let8             VARCHAR2(10);
    v_cpt_let9             VARCHAR2(10);
    v_cpt_let10            VARCHAR2(10);
    v_cpt_let11            VARCHAR2(10);
    v_cpt_let12            VARCHAR2(10);

  BEGIN
    fnd_file.put_line(fnd_file.log,
                      'validate_data_social : start : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));

    p_retcode := 0;

    --< JLY
    SELECT  max(calendar_period_close_date)
    INTO    ld_current_period
    FROM    fa_deprn_periods;
    --> JLY

    FOR rec_social_data IN cur_social_data LOOP
      -- Donnee a verifier
      --
      -- Récupération de l'identifiant de l'immobilisation
      v_flag_erreur := FALSE;

      -- Contrôle que l'immobilisation n'existe pas déj)
      BEGIN
        l_step := 'IMMOBILISATION';

        SELECT  SUM(nb)
        INTO    l_count
        FROM (
                SELECT  COUNT(1) nb
                FROM    fa_additions
                WHERE   asset_number = rec_social_data.numero_immobilisation
                UNION
                SELECT  COUNT(1) nb
                FROM    fa_mass_additions
                WHERE   asset_number = rec_social_data.numero_immobilisation
                AND     posting_status <> 'POSTED'
              );

        IF l_count > 0 THEN
          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_INTERFACE',
                                         rec_social_data.numero_immobilisation,
                                         'ASSET_NUMBER',
                                         rec_social_data.numero_immobilisation,
                                         'E',
                                         'L''immobilisation existe déjà');
        END IF;
      END;

      -- Contrôle de la catégorie d'immobilisation
      BEGIN
        l_step := 'BOOK';

        SELECT  1
        INTO    l_count
        FROM    fa_book_controls
        WHERE   book_type_code LIKE rec_social_data.societe || '%'
        AND     book_class = 'CORPORATE';
      EXCEPTION
        WHEN no_data_found THEN
          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_INTERFACE',
                                         rec_social_data.numero_immobilisation,
                                         'BOOK',
                                         substr(rec_social_data.societe, 1, 30),
                                         'E',
                                         'Le livre n''existe pas');
      END;

      -- Contrôle de la catégorie d'immobilisation
      -- 12/12/2016 NBO artf2063248 : REP009 : Déplacement des fonctions de transco de 11.5.10 vers R12
      BEGIN
        l_step := 'CATEGORY';

        dka_rep_transco_pkg.get_transco(pv_transco_name => '018_ASSET_CATEGORY',
                                        pv_column_01    => rec_social_data.rub_principale || '.' ||
                                                           rec_social_data.rub_detail || '.' ||
                                                           rec_social_data.methode_amt || '.' ||
                                                           rec_social_data.plafond_amt,
                                        pv_out_01       => v_cat);

        v_cat := replace(v_cat, '..', 'µ.');

        SELECT  category_id
        INTO    ln_category_id
        FROM    fa_categories_vl
        WHERE   segment1 = replace(substr(v_cat, 1, instr(v_cat, '.', 1) - 1), 'µ', '.')
        AND     segment2 = replace(substr(v_cat,
                                          instr(v_cat, '.', 1) + 1,
                                          ((instr(v_cat, '.', 1, 2))) - (instr(v_cat, '.', 1) + 1)
                                          ), 'µ', '.')
        AND     segment3 = replace(substr(v_cat,
                                          instr(v_cat, '.', 1, 2) + 1,
                                          ((instr(v_cat, '.', 1, 3))) - (instr(v_cat, '.', 1, 2) + 1)
                                          ), 'µ', '.')
        AND     segment4 = replace(substr(v_cat, instr(v_cat, '.', 1, 3) + 1), 'µ', '.');
      EXCEPTION
        WHEN no_data_found THEN
          v_flag_erreur := TRUE;
          ln_category_id := NULL;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_INTERFACE',
                                         rec_social_data.numero_immobilisation,
                                         'CATEGORY',
                                         substr(rec_social_data.rub_principale || '.' || rec_social_data.rub_detail || '.' || rec_social_data.methode_amt || '.' || rec_social_data.plafond_amt, 1, 30),
                                         'E',
                                         'La catégorie d''immobilisation n''existe pas');
      END;

      -- Contrôle de l'affectation de la catégorie au livre
      IF ln_category_id IS NOT NULL THEN
        BEGIN
          l_step := 'CATEGORY_BOOK';

          SELECT  1
          INTO    l_count
          FROM    fa_category_books fcb
          WHERE   fcb.category_id = ln_category_id
          AND     fcb.book_type_code LIKE rec_social_data.societe || '%SOCIAL';

        EXCEPTION
          WHEN no_data_found THEN
            v_flag_erreur := TRUE;

            dka_tools_pkg.ins_prog_message(g_request_id,
                                           'DKA_REPFAIMOIMP',
                                           'ETL',
                                           'DKA_REP009_INTERFACE',
                                           rec_social_data.numero_immobilisation,
                                           'CATEGORY_BOOK',
                                           substr(rec_social_data.rub_principale || '.' || rec_social_data.rub_detail || '.' || rec_social_data.methode_amt || '.' || rec_social_data.plafond_amt, 1, 30),
                                           'E',
                                           'La catégorie d''immobilisation n''est pas disponible pour ce livre');
        END;
      END IF;

      -- V1.2	 19/12/2016		NBO - artf2067886 - Controle depreciation method / life in months
      BEGIN
        l_step := 'METHODE_AMORTISSEMENT';

        dka_rep_transco_pkg.get_transco(pv_transco_name => '024_ASSET_METHOD',
                                        pv_column_01    => rec_social_data.methode_d_amortissement,
                                        pv_out_01       => v_methode);

        SELECT  1
        INTO    l_count
        FROM    fa_methods
        WHERE   method_code = v_methode
        AND     life_in_months = to_number(rec_social_data.duree_de_vie_en_mois);

      EXCEPTION
        WHEN no_data_found THEN
          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_INTERFACE',
                                         rec_social_data.numero_immobilisation,
                                         'METHODE_D_AMORTISSEMENT',
                                         substr(v_methode || '/' || rec_social_data.duree_de_vie_en_mois, 1, 30),
                                         'E',
                                         'La méthode d''amortissement et durée n''existe pas');
      END;

      -- Contrôle de la clé TAXE
      BEGIN
        l_step := 'TAXE_IMPOT';

        application_short_name := 'OFA';
        key_flex_code := 'KEY#';
        structure_number := 101;
        validation_date := SYSDATE;
        n_segments := 2;
        segments(1) := rec_social_data.taxe_prof;
        segments(2) := rec_social_data.impot_foncier;
        data_set := NULL;

        v_return := fnd_flex_ext.get_combination_id(application_short_name => application_short_name,
                                                    key_flex_code          => key_flex_code,
                                                    structure_number       => structure_number,
                                                    validation_date        => validation_date,
                                                    n_segments             => n_segments,
                                                    segments               => segments,
                                                    combination_id         => ln_asset_key_ccid);

        IF NOT v_return THEN
          v_flag_erreur := TRUE;
          ln_asset_key_ccid := NULL;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_INTERFACE',
                                         rec_social_data.numero_immobilisation,
                                         'CLE_TAXE',
                                         substr(rec_social_data.taxe_prof || '.' || rec_social_data.impot_foncier, 1, 30),
                                         'E',
                                         'La clé TAXE IMPOT n''est pas valide');
        END IF;
      END;

      -- Contrôle de la clé LIEU
      BEGIN
        l_step := 'LIEU';

        application_short_name := 'OFA';
        key_flex_code := 'LOC#';
        structure_number := 101;
        validation_date := SYSDATE;
        n_segments := 2;
        segments(1) := rec_social_data.societe;
        segments(2) := rec_social_data.lieu_physique;
        data_set := NULL;

        v_return := fnd_flex_ext.get_combination_id(application_short_name => application_short_name,
                                                    key_flex_code          => key_flex_code,
                                                    structure_number       => structure_number,
                                                    validation_date        => validation_date,
                                                    n_segments             => n_segments,
                                                    segments               => segments,
                                                    combination_id         => ln_loc_ccid);

        IF NOT v_return THEN
          v_flag_erreur := TRUE;
          ln_loc_ccid := NULL;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_INTERFACE',
                                         rec_social_data.numero_immobilisation,
                                         'CLE_LIEU',
                                         substr(rec_social_data.societe || '.' || rec_social_data.lieu_physique, 1, 30),
                                         'E',
                                         'La clé LIEU n''est pas valide');
        END IF;
      END;

      BEGIN
        l_step := 'COMPTE_DOTATION';

        -- 12/12/2016 NBO artf2063248 : REP009 : Déplacement des fonctions de transco de 11.5.10 vers R12
        dka_rep_transco_pkg.get_cle_transco(pv_segment_01     => rec_social_data.d_societe,
                                            pv_segment_02     => rec_social_data.d_uo,
                                            pv_segment_03     => rec_social_data.d_compte_local,
                                            pv_segment_04     => rec_social_data.d_compte_analytique,
                                            pv_segment_05     => rec_social_data.d_interco,
                                            pv_code_projet    => rec_social_data.d_centre_fi,
                                            pv_segment_08     => rec_social_data.d_affaire,
                                            pv_segment_09     => rec_social_data.d_flux,
                                            pv_segment_10     => '0',
                                            pv_segment_out_01 => v_cpt_dot1,
                                            pv_segment_out_02 => v_cpt_dot2,
                                            pv_segment_out_03 => v_cpt_dot3,
                                            pv_segment_out_04 => v_cpt_dot4,
                                            pv_segment_out_05 => v_cpt_dot5,
                                            pv_segment_out_06 => v_cpt_dot6,
                                            pv_segment_out_07 => v_cpt_dot7,
                                            pv_segment_out_08 => v_cpt_dot8,
                                            pv_segment_out_09 => v_cpt_dot9,
                                            pv_segment_out_10 => v_cpt_dot10,
                                            pv_segment_out_11 => v_cpt_dot11,
                                            pv_segment_out_12 => v_cpt_dot12);

        dka_rep_transco_pkg.get_transco(pv_transco_name => '008_REGIONS',
                                        pv_column_01    => v_cpt_dot2,
                                        pv_out_01       => lv_region);

        get_code_combination_id(pv_segment1            => v_cpt_dot1,
                                pv_segment2            => lv_region,
                                pv_segment3            => v_cpt_dot3,
                                pv_segment4            => v_cpt_dot4,
                                pv_segment5            => v_cpt_dot5,
                                pv_segment6            => v_cpt_dot6,
                                pv_segment7            => v_cpt_dot7,
                                pv_segment8            => v_cpt_dot8,
                                pv_segment9            => v_cpt_dot9,
                                pv_segment10           => v_cpt_dot10,
                                pv_segment11           => v_cpt_dot11,
                                pv_segment12           => v_cpt_dot12,
                                pn_code_combination_id => vn_dotation_ccid,
                                pv_errbuf              => vv_errbuf_ccid,
                                pn_retcode             => vn_retcode_ccid,
                                pv_validation_flag     => 'N');

        IF vn_retcode_ccid != 0 THEN
          v_flag_erreur := TRUE;
          vn_dotation_ccid := NULL;

          --fnd_file.put_line(fnd_file.log, vv_errbuf_ccid);

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_INTERFACE',
                                         rec_social_data.numero_immobilisation,
                                         'EXPENSE_ACCOUNT',
                                         substr(v_cpt_dot1 || '.' || lv_region || '.' ||
                                                v_cpt_dot3 || '.' || v_cpt_dot4 || '.' ||
                                                v_cpt_dot5 || '.' || v_cpt_dot6 || '.' ||
                                                v_cpt_dot7 || '.' || v_cpt_dot8 || '.' ||
                                                v_cpt_dot9 || '.' || v_cpt_dot10 || '.' ||
                                                v_cpt_dot11 || '.' || v_cpt_dot12,
                                                1, 30),
                                         'E',
                                         'La clé de dotation n''est pas valide');
        ELSE
          SELECT  count(1)
          INTO    l_count
          FROM    gl_code_combinations
          WHERE   code_combination_id = vn_dotation_ccid
          AND     account_type = 'E';

          IF l_count = 0 THEN
            v_flag_erreur := TRUE;
            vn_dotation_ccid := NULL;

            dka_tools_pkg.ins_prog_message(g_request_id,
                                           'DKA_REPFAIMOIMP',
                                           'ETL',
                                           'DKA_REP009_INTERFACE',
                                           rec_social_data.numero_immobilisation,
                                           'EXPENSE_ACCOUNT',
                                           substr(v_cpt_dot1 || '.' || lv_region || '.' ||
                                                  v_cpt_dot3 || '.' || v_cpt_dot4 || '.' ||
                                                  v_cpt_dot5 || '.' || v_cpt_dot6 || '.' ||
                                                  v_cpt_dot7 || '.' || v_cpt_dot8 || '.' ||
                                                  v_cpt_dot9 || '.' || v_cpt_dot10 || '.' ||
                                                  v_cpt_dot11 || '.' || v_cpt_dot12,
                                                  1, 30),
                                           'E',
                                           'La clé de dotation doit être de type Charge');
          END IF;
        END IF;
      END;

      -- Contrôle de la clé de lettrage
      BEGIN
        l_step := 'COMPTE_LETTRAGE';

        -- 12/12/2016 NBO artf2063248 : REP009 : Déplacement des fonctions de transco de 11.5.10 vers R12
        dka_rep_transco_pkg.get_cle_transco(pv_segment_01     => rec_social_data.l_societe,
                                            pv_segment_02     => rec_social_data.l_uo,
                                            pv_segment_03     => rec_social_data.l_compte_local,
                                            pv_segment_04     => rec_social_data.l_compte_analytique,
                                            pv_segment_05     => rec_social_data.l_interco,
                                            pv_code_projet    => rec_social_data.l_centre_fi,
                                            pv_segment_08     => rec_social_data.l_affaire,
                                            pv_segment_09     => rec_social_data.l_flux,
                                            pv_segment_10     => '0',
                                            pv_segment_out_01 => v_cpt_let1,
                                            pv_segment_out_02 => v_cpt_let2,
                                            pv_segment_out_03 => v_cpt_let3,
                                            pv_segment_out_04 => v_cpt_let4,
                                            pv_segment_out_05 => v_cpt_let5,
                                            pv_segment_out_06 => v_cpt_let6,
                                            pv_segment_out_07 => v_cpt_let7,
                                            pv_segment_out_08 => v_cpt_let8,
                                            pv_segment_out_09 => v_cpt_let9,
                                            pv_segment_out_10 => v_cpt_let10,
                                            pv_segment_out_11 => v_cpt_let11,
                                            pv_segment_out_12 => v_cpt_let12);

        dka_rep_transco_pkg.get_transco(pv_transco_name => '008_REGIONS',
                                        pv_column_01    => v_cpt_let2,
                                        pv_out_01       => lv_region);

        get_code_combination_id(pv_segment1            => v_cpt_let1,
                                pv_segment2            => lv_region,
                                pv_segment3            => v_cpt_let3,
                                pv_segment4            => v_cpt_let4,
                                pv_segment5            => v_cpt_let5,
                                pv_segment6            => v_cpt_let6,
                                pv_segment7            => v_cpt_let7,
                                pv_segment8            => v_cpt_let8,
                                pv_segment9            => v_cpt_let9,
                                pv_segment10           => v_cpt_let10,
                                pv_segment11           => v_cpt_let11,
                                pv_segment12           => v_cpt_let12,
                                pn_code_combination_id => vn_lettrage_ccid,
                                pv_errbuf              => vv_errbuf_ccid,
                                pn_retcode             => vn_retcode_ccid,
                                pv_validation_flag     => 'N');

        IF vn_retcode_ccid != 0 THEN
          v_flag_erreur := TRUE;
          vn_lettrage_ccid := NULL;

          --fnd_file.put_line(fnd_file.log, vv_errbuf_ccid);

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_INTERFACE',
                                         rec_social_data.numero_immobilisation,
                                         'CLEARING_ACCOUNT',
                                         substr(v_cpt_let1 || '.' || lv_region || '.' ||
                                                v_cpt_let3 || '.' || v_cpt_let4 || '.' ||
                                                v_cpt_let5 || '.' || v_cpt_let6 || '.' ||
                                                v_cpt_let7 || '.' || v_cpt_let8 || '.' ||
                                                v_cpt_let9 || '.' || v_cpt_let10 || '.' ||
                                                v_cpt_let11 || '.' || v_cpt_let12,
                                                1, 30),
                                         'E',
                                         'La clé de lettrage n''est pas valide');
        END IF;
      END;

      -- Contrôle de la transco Immo / Projet
      BEGIN
        l_step := 'TRANSCO_IMMO';

        dka_rep_transco_pkg.get_transco(pv_transco_name => '023_IMMO_PROJET',
                                        pv_column_01    => rec_social_data.numero_immobilisation,
                                        pv_out_01       => vv_projet,
                                        pv_out_02       => vv_tache);

        IF rec_social_data.numero_immobilisation = vv_projet THEN
          v_flag_erreur := TRUE;
          vv_projet := NULL;
          vv_tache := NULL;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_INTERFACE',
                                         rec_social_data.numero_immobilisation,
                                         'PROJECT_NUMBER',
                                         rec_social_data.numero_immobilisation,
                                         'E',
                                         'La transco immo projet n''existe pas');
        ELSE

          -- Contrôle de l'existence du projet cible
          BEGIN
            SELECT  pp.project_id, pt.task_id
            INTO    ln_project_id, ln_task_id
            FROM    pa_tasks pt, pa_projects_all pp
            WHERE   pt.task_number = vv_tache
            AND     pt.project_id = pp.project_id
            AND     pp.segment1 = vv_projet;
          EXCEPTION
            WHEN no_data_found THEN
              v_flag_erreur := TRUE;
              ln_project_id := NULL;
              ln_task_id    := NULL;

              dka_tools_pkg.ins_prog_message(g_request_id,
                                             'DKA_REPFAIMOIMP',
                                             'ETL',
                                             'DKA_REP009_INTERFACE',
                                             rec_social_data.numero_immobilisation,
                                             'PROJECT_NUMBER',
                                             vv_projet || '/' || vv_tache,
                                             'E',
                                             'Le projet de la transco immo projet n''existe pas');
          END;
        END IF;
      END;

      -- V1.5    28/03/2017     NBO Correction suite à la reprise du RUN3
      -- Contrôle de l'affectation du lieu, clé de dotation, clé de lettrage
      BEGIN
        l_step := 'SOCIETE';

        IF rec_social_data.societe != rec_social_data.d_societe OR rec_social_data.societe != rec_social_data.l_societe THEN
          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_INTERFACE',
                                         rec_social_data.numero_immobilisation,
                                         'SOCIETE',
                                         substr(rec_social_data.societe || '/' || rec_social_data.d_societe || '/' || rec_social_data.l_societe,1,30),
                                         'E',
                                         'La société du lieu et des clés sont différentes');

        END IF;
      END;

      -- V1.5    28/03/2017     NBO Correction suite à la reprise du RUN3
      -- Contrôle de l'amortissement cumulé vs cout
      BEGIN
        l_step := 'AMORTISSEMENT_CUMUL';

        IF nvl(abs(rec_social_data.amortissement_cumule), 0) > nvl(abs(rec_social_data.cost), 0) THEN
          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_INTERFACE',
                                         rec_social_data.numero_immobilisation,
                                         'AMORTISSEMENT_CUMUL',
                                         substr(rec_social_data.amortissement_exercice || '/' || rec_social_data.cost,1,30),
                                         'E',
                                         'L''amortissement cumulé ne peut pas être supérieur à la base amortissable');

        END IF;
      END;

      -- Contrôle de l'amortissement cumulé vs exercice
      BEGIN
        l_step := 'AMORTISSEMENT_EXERCICE';

        IF nvl(abs(rec_social_data.amortissement_cumule), 0) < nvl(abs(rec_social_data.amortissement_exercice), 0) THEN
          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_INTERFACE',
                                         rec_social_data.numero_immobilisation,
                                         'AMORTISSEMENT_EXERCICE',
                                         substr(rec_social_data.amortissement_exercice || '/' || rec_social_data.amortissement_cumule,1,30),
                                         'E',
                                         'L''amortissement cumulé de l''exercice ne peut pas dépasser l''amortissement cumulé à ce jour');

        END IF;
      END;

      -- V1.5    28/03/2017     NBO Correction suite à la reprise du RUN3
      -- Contrôle de l'amortissement cumulé vs exercice pour les aquisitions de l'année

      BEGIN
        l_step := 'ACQUISITION EXERCICE';

        --< JLY
        --IF rec_social_data.amortissement_exercice !=0 and rec_social_data.amortissement_cumule = 0 THEN
        IF nvl(rec_social_data.amortissement_exercice, 0) != nvl(rec_social_data.amortissement_cumule, 0)
           and trunc(rec_social_data.date_de_debut_de_amortissement, 'YYYY') = trunc(ld_current_period, 'YYYY') THEN
        --> JLY
          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_INTERFACE',
                                         rec_social_data.numero_immobilisation,
                                         'AMORTISSEMENT_EXERCICE',
                                         substr(rec_social_data.amortissement_exercice || '/' || rec_social_data.amortissement_cumule,1,30),
                                         'E',
                                         'L''amortissement cumulé de l''exercice doit être équal à l''amortissement cumulé à ce jour pour une acquisition de l''année');

        END IF;
      END;

      -- Contrôle des unités
      BEGIN
        l_step := 'UNITE';

        IF nvl(rec_social_data.unites, 0) <> nvl(round(rec_social_data.unites, 0), 0) THEN
          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_INTERFACE',
                                         rec_social_data.numero_immobilisation,
                                         'UNITES',
                                         substr(rec_social_data.unites,1,30),
                                         'E',
                                         'Vous ne pouvez pas créer d''immobilisations avec des unités fractionnées');

        END IF;
      END;

      IF NOT v_flag_erreur THEN

        UPDATE  DKA_REP009_INTERFACE
        SET     STATUS             = gv_statut_valid,
                CATEGORIE_TRANSCO  = v_cat,
                METHODE_TRANSCO    = v_methode,
                ASSET_CATEGORY_ID  = ln_category_id,
                ASSET_KEY_CCID     = ln_asset_key_ccid,
                LOCATION_ID        = ln_loc_ccid,
                CLE_DOTATION       = v_cpt_dot1 || '.' || lv_region || '.' ||
                                     v_cpt_dot3 || '.' || v_cpt_dot4 || '.' ||
                                     v_cpt_dot5 || '.' || v_cpt_dot6 || '.' ||
                                     v_cpt_dot7 || '.' || v_cpt_dot8 || '.' ||
                                     v_cpt_dot9 || '.' || v_cpt_dot10 || '.' ||
                                     v_cpt_dot11 || '.' || v_cpt_dot12,
                DEPRN_EXPENSE_CCID = vn_dotation_ccid           ,
                CLE_LETTRAGE       = v_cpt_let1 || '.' || lv_region || '.' ||
                                     v_cpt_let3 || '.' || v_cpt_let4 || '.' ||
                                     v_cpt_let5 || '.' || v_cpt_let6 || '.' ||
                                     v_cpt_let7 || '.' || v_cpt_let8 || '.' ||
                                     v_cpt_let9 || '.' || v_cpt_let10 || '.' ||
                                     v_cpt_let11 || '.' || v_cpt_let12,
                PAYABLES_CODE_COMBINATION_ID = vn_lettrage_ccid,
                PROJECT_ID         = ln_project_id,
                TASK_ID            = ln_task_id
        WHERE   CURRENT OF cur_social_data;

        g_summary.valid_rows_social := g_summary.valid_rows_social + 1;

      ELSE
        -- en cas d'erreur

        UPDATE  DKA_REP009_INTERFACE
        SET     STATUS             = gv_statut_ko
        WHERE  CURRENT OF cur_social_data;

        g_summary.rejected_rows := g_summary.rejected_rows + 1;

      END IF;

    END LOOP; /* Rec_Social_Data IN Cur_Fiscal_Data */

    fnd_file.put_line(fnd_file.log,
                      'validate_data_social : end : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'validate_data_social : ' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        l_step || '-' ||
                        'Fin de la procédure validate_data_social: EXCEPTION OTHERS ');
  END validate_data_social;

  /*
   *************************************************************************
   * PROCEDURE NAME : validate_data_IFRS
   *
   * DESCRIPTION
   *  Procédure de validation des données des livres IFRS
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE validate_data_IFRS  (p_errbuf  OUT VARCHAR2,
                                 p_retcode OUT NUMBER) IS

    -- On selectionne toutes les donnees
    -- But: Memoriser tous les livres presents dans la table Fa_Tax_Tmp
    -- Permet dans le cas de reprise sur erreur, de soumettre les traitements standards FATAXUP et FAIMCP
    -- pour tous les livres et pas seulement pour les livres des donnees inserees.

    CURSOR cur_IFRS_data IS
      SELECT  *
      FROM    DKA_REP009_CALISTO_INTERFACE dk
      WHERE   nvl(STATUS, gv_statut_new) IN (gv_statut_new, gv_statut_ko)
      FOR UPDATE;

    v_flag_erreur          BOOLEAN;
    l_count                NUMBER;
    l_step                 VARCHAR2(50);

    --application_short_name VARCHAR2(200);
    --key_flex_code          VARCHAR2(200);
    --structure_number       NUMBER;
    --validation_date        DATE;
    --n_segments             NUMBER;
    --segments               apps.fnd_flex_ext.segmentarray;
    --data_set               NUMBER;
    --v_return               BOOLEAN;

    v_methode              VARCHAR2(200);
    --ln_category_id         NUMBER;
    --ln_asset_key_ccid      NUMBER;
    --vn_dotation_ccid       NUMBER;
    --vn_lettrage_ccid       NUMBER;
    --vv_errbuf_ccid         VARCHAR2(1000);
    --vn_retcode_ccid        NUMBER;
    --ln_loc_ccid            NUMBER;
    --vv_projet              VARCHAR2(50);
    --vv_tache               VARCHAR2(50);
    --ln_project_id          NUMBER;
    --ln_task_id             NUMBER;
    --lv_region              VARCHAR2(50);
    --ln_life_in_months      NUMBER;

    --v_cat                  VARCHAR2(200);
    --v_cpt_dot1             VARCHAR2(10);
    --v_cpt_dot2             VARCHAR2(10);
/*    v_cpt_dot3             VARCHAR2(10);
    v_cpt_dot4             VARCHAR2(10);
    v_cpt_dot5             VARCHAR2(10);
    v_cpt_dot6             VARCHAR2(10);
    v_cpt_dot7             VARCHAR2(10);
    v_cpt_dot8             VARCHAR2(10);
    v_cpt_dot9             VARCHAR2(10);
    v_cpt_dot10            VARCHAR2(10);
    v_cpt_dot11            VARCHAR2(10);
    v_cpt_dot12            VARCHAR2(10);*/

    /*v_cpt_let1             VARCHAR2(10);
    v_cpt_let2             VARCHAR2(10);
    v_cpt_let3             VARCHAR2(10);
    v_cpt_let4             VARCHAR2(10);
    v_cpt_let5             VARCHAR2(10);
    v_cpt_let6             VARCHAR2(10);
    v_cpt_let7             VARCHAR2(10);
    v_cpt_let8             VARCHAR2(10);
    v_cpt_let9             VARCHAR2(10);
    v_cpt_let10            VARCHAR2(10);
    v_cpt_let11            VARCHAR2(10);
    v_cpt_let12            VARCHAR2(10);*/

  BEGIN
    fnd_file.put_line(fnd_file.log,
                      'validate_data_IFRS : start : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));

    p_retcode := 0;

    FOR rec_IFRS_data IN cur_IFRS_data LOOP
      -- Donnee a verifier
      --
      -- Récupération de l'identifiant de l'immobilisation
      v_flag_erreur := FALSE;

      -- Contrôle que l'immobilisation existe dans le livre SOCIAL
      BEGIN
        l_step := 'IMMOBILISATION';

        SELECT  COUNT(1)
        INTO    l_count
        FROM    DKA_REP009_INTERFACE
        WHERE   numero_immobilisation = rec_IFRS_data.numero_immobilisation;

        IF l_count = 0 THEN
          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_CALISTO_INTERFACE',
                                         rec_IFRS_data.numero_immobilisation,
                                         'ASSET_NUMBER',
                                         rec_IFRS_data.numero_immobilisation,
                                         'E',
                                         'L''immobilisation n''existe pas dans le livre SOCIAL');
        ELSE
          SELECT  COUNT(1)
          INTO    l_count
          FROM    DKA_REP009_INTERFACE
          WHERE   numero_immobilisation = rec_IFRS_data.numero_immobilisation
          AND     status in (gv_statut_valid, gv_statut_ok, gv_statut_postimport);

          IF l_count = 0 THEN
            v_flag_erreur := TRUE;

            dka_tools_pkg.ins_prog_message(g_request_id,
                                           'DKA_REPFAIMOIMP',
                                           'ETL',
                                           'DKA_REP009_CALISTO_INTERFACE',
                                           rec_IFRS_data.numero_immobilisation,
                                           'ASSET_NUMBER',
                                           rec_IFRS_data.numero_immobilisation,
                                           'E',
                                           'L''immobilisation est en rejet dans le livre SOCIAL');
          END IF;
        END IF;
      END;

      -- Contrôle de la catégorie d'immobilisation
      BEGIN
        l_step := 'BOOK';

        SELECT  1
        INTO    l_count
        FROM    fa_book_controls
        WHERE   book_type_code LIKE rec_IFRS_data.societe || '%'
        AND     book_class = 'TAX';
      EXCEPTION
        WHEN no_data_found THEN
          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_CALISTO_INTERFACE',
                                         rec_IFRS_data.numero_immobilisation,
                                         'BOOK',
                                         substr(rec_IFRS_data.societe, 1, 30),
                                         'E',
                                         'Le livre n''existe pas');
      END;

      -- V1.2	 19/12/2016		NBO - artf2067886 - Controle depreciation method / life in months
      BEGIN
        l_step := 'METHODE_AMORTISSEMENT';

        dka_rep_transco_pkg.get_transco(pv_transco_name => '024_ASSET_METHOD',
                                        pv_column_01    => rec_IFRS_data.methode_d_amortissement,
                                        pv_out_01       => v_methode);

        SELECT  1
        INTO    l_count
        FROM    fa_methods
        WHERE   method_code = v_methode
        AND     life_in_months = to_number(rec_IFRS_data.duree_de_vie_en_mois);

      EXCEPTION
        WHEN no_data_found THEN
          v_flag_erreur := TRUE;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'ETL',
                                         'DKA_REP009_CALISTO_INTERFACE',
                                         rec_IFRS_data.numero_immobilisation,
                                         'METHODE_D_AMORTISSEMENT',
                                         substr(v_methode || '/' || rec_IFRS_data.duree_de_vie_en_mois, 1, 30),
                                         'E',
                                         'La méthode d''amortissement et durée n''existe pas');
      END;

      IF NOT v_flag_erreur THEN

        UPDATE  DKA_REP009_CALISTO_INTERFACE
        SET     STATUS             = gv_statut_valid,
                METHODE_TRANSCO    = v_methode
        WHERE   CURRENT OF cur_IFRS_data;

        g_summary.valid_rows_social := g_summary.valid_rows_social + 1;

      ELSE
        -- en cas d'erreur

        UPDATE  DKA_REP009_CALISTO_INTERFACE
        SET     STATUS             = gv_statut_ko
        WHERE  CURRENT OF cur_IFRS_data;

        g_summary.rejected_rows := g_summary.rejected_rows + 1;

      END IF;

    END LOOP; /* Rec_Social_Data IN Cur_Fiscal_Data */

    fnd_file.put_line(fnd_file.log,
                      'validate_data_IFRS : end : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'validate_data_IFRS : ' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        l_step || '-' ||
                        'Fin de la procédure validate_data_social: EXCEPTION OTHERS ');
  END validate_data_IFRS;

  /*
   *************************************************************************
   * PROCEDURE NAME : insert_data_social
   *
   * DESCRIPTION
   *  Insertion des données des livrees sociaux dans la table d'interface
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE insert_data_social(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

    CURSOR cur_social_data IS
      SELECT  *
      FROM    DKA_REP009_INTERFACE dk
      WHERE   nvl(status, gv_statut_new) IN (gv_statut_valid)
      AND     NOT EXISTS (
                SELECT '1'
                FROM fa_additions fa
                WHERE asset_number = dk.numero_immobilisation
                UNION ALL
                SELECT '1'
                FROM fa_mass_additions fa
                WHERE asset_number = dk.numero_immobilisation
               )
      FOR UPDATE;

    l_seq   NUMBER;
    l_livre VARCHAR2(100);
    l_step  VARCHAR2(50);

  BEGIN
    p_retcode := 0;

    fnd_file.put_line(fnd_file.log,
                      'insert_data_social : start : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));

    FOR rec_social_data IN cur_social_data LOOP

      SELECT fa_mass_additions_s.NEXTVAL INTO l_seq FROM dual;

      l_step := 'BOOK';

      SELECT  book_type_code
      INTO    l_livre
      FROM    fa_book_controls
      WHERE   book_type_code LIKE rec_social_data.societe || '%'
      AND     book_class = 'CORPORATE';

      l_step := 'INSERT';

      BEGIN
        -- Donnee a inserer dans la table d'interface
        INSERT INTO fa_mass_additions
          (mass_addition_id,
           asset_number,
           description,
           asset_category_id, --
           book_type_code,
           date_placed_in_service,
           fixed_assets_cost,
           payables_units,
           fixed_assets_units,
           payables_code_combination_id, --
           feeder_system_name,
           create_batch_date,
           create_batch_id, --
           posting_status,
           queue_name,
           payables_cost, --
           depreciate_flag,
           asset_key_ccid, --
           asset_type,
           deprn_reserve,
           ytd_deprn,
           amortize_nbv_flag,
           amortization_start_date,
           in_use_flag,
           owned_leased,
           new_used,
           deprn_method_code,
           life_in_months,
           project_id, --
           task_id --
           )
        VALUES
          (l_seq,
           rec_social_data.numero_immobilisation,
           -- V1.4    22/03/2017     NBO Correction suuite à la reprise du RUN3
           substr(rec_social_data.libelle_immo,1,80),
           rec_social_data.asset_category_id,
           l_livre,
           rec_social_data.date_de_mise_en_service,
           rec_social_data.cost,
           rec_social_data.unites,
           rec_social_data.unites,
           rec_social_data.payables_code_combination_id,
           'REPRISE_R12',
           SYSDATE,
           fnd_global.conc_request_id,
           'POST',
           'POST',
           rec_social_data.cost,
           -- V1.10   11/08/2017     NBO artf2211081 - REP009 - Import - Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
           -- AMORTIR doit également être faite pour pouvoir gérer les éventuels formats différents du fichier Calisto (OUI, Oui, oui, NON, Non ,non)
           decode(lower(rec_social_data.amortir), 'oui', 'YES', 'NO'),
           rec_social_data.asset_key_ccid,
           'CAPITALIZED',
           rec_social_data.amortissement_cumule,
           rec_social_data.amortissement_exercice,
           'N', -- Amortir la valeur nette
           rec_social_data.date_de_debut_de_amortissement,
           -- V1.10   28/08/2017     NBO artf2211081 - REP009 - Import - Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
           decode(lower(rec_social_data.utilise), 'oui', 'YES', 'NO'),
           decode(rec_social_data.propriete,
                  'En propriété',
                  'OWNED',
                  'LEASED'),
           decode(rec_social_data.achete, 'Neuf', 'NEW', 'USED'),
           -- V1.5    28/03/2017     NBO Correction suite à la reprise du RUN3
           --rec_social_data.methode_d_amortissement,
           rec_social_data.methode_transco,
           rec_social_data.duree_de_vie_en_mois,
           rec_social_data.project_id,
           rec_social_data.task_id);

        l_step := 'UPDATE';

        UPDATE  fa_massadd_distributions
        SET     units              = rec_social_data.unites,
                deprn_expense_ccid = rec_social_data.deprn_expense_ccid,
                location_id        = rec_social_data.location_id
        WHERE   mass_addition_id = l_seq;

        UPDATE  DKA_REP009_INTERFACE
        SET     STATUS             = gv_statut_ok
        WHERE  CURRENT OF cur_social_data;

        g_summary.import_rows_social := g_summary.import_rows_social + 1;

      EXCEPTION
        WHEN OTHERS THEN
          g_summary.rejected_rows := g_summary.rejected_rows + 1;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'OI',
                                         'DKA_REP009_INTERFACE',
                                         rec_social_data.numero_immobilisation,
                                         'FA_MASS_ADDITIONS',
                                         NULL,
                                         'E',
                                         SUBSTR(l_step || ':' || SQLERRM, 1, 500));
      END;
    END LOOP; /* rec_social_data IN Cur_Fiscal_Data */

    COMMIT;

    fnd_file.put_line(fnd_file.log,
                      'insert_data_social : end : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'insert_data_social : ' || SQLERRM || ':' || l_step;

      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure insert_data_social : EXCEPTION OTHERS ');
  END insert_data_social;

  /*
   *************************************************************************
   * PROCEDURE NAME : insert_data_IFRS
   *
   * DESCRIPTION
   *  Insertion des données des livrees sociaux dans la table d'interface
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE insert_data_IFRS(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

    -- V1.8    11/04/2017     NBO artf2136811 - REP009 - Import - Charger l'interface de livre de gestion en erreur
    CURSOR cur_IFRS_data IS
      SELECT  dk.*
      FROM    DKA_REP009_CALISTO_INTERFACE dk
      WHERE   nvl(status, gv_statut_new) IN (gv_statut_valid)
      -- V1.4    22/03/2017     NBO Correction suuite à la reprise du RUN3
      AND     EXISTS (
                SELECT '1'
                FROM fa_additions fa
                WHERE asset_number = dk.numero_immobilisation
                UNION ALL
                SELECT '1'
                FROM fa_mass_additions fa
                WHERE asset_number = dk.numero_immobilisation
               )
      FOR UPDATE;

    --l_seq   NUMBER;
    l_livre VARCHAR2(100);
    l_step  VARCHAR2(50);
    -- V1.8    11/04/2017     NBO artf2136811 - REP009 - Import - Charger l'interface de livre de gestion en erreur
    lv_depreciate_flag VARCHAR2(10);
    ln_cost NUMBER;
    lv_amortir VARCHAR2(3);

  BEGIN
    p_retcode := 0;

    fnd_file.put_line(fnd_file.log,
                      'insert_data_IFRS : start : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));

    FOR rec_IFRS_data IN cur_IFRS_data LOOP

      SELECT  book_type_code
      INTO    l_livre
      FROM    fa_book_controls
      WHERE   book_type_code LIKE rec_IFRS_data.societe || '%'
      AND     book_class = 'TAX';

    -- V1.8    11/04/2017     NBO artf2136811 - REP009 - Import - Charger l'interface de livre de gestion en erreur
      fnd_file.put_line(fnd_file.log,
                      rec_ifrs_data.numero_immobilisation);

     -- V1.10   28/08/2017     NBO artf2211081 - REP009 - Import - Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
    /*  SELECT  v.depreciate_flag
      INTO    l_depreciate_flag
      FROM (SELECT fa.asset_number, fb.depreciate_flag
                FROM fa_additions fa, fa_books fb
               WHERE fa.asset_id = fb.asset_id
              UNION ALL
              SELECT fa.asset_number, fa.depreciate_flag
                FROM fa_mass_additions fa
                WHERE posting_status = 'POST') v
       WHERE rec_ifrs_data.numero_immobilisation = v.asset_number;*/
      
      l_step := 'INSERT';

      BEGIN
        -- Donnee a inserer dans la table d'interface
        INSERT INTO fa_tax_interface
          (asset_number,
           book_type_code,
           cost,
           created_by,
           creation_date,
           date_placed_in_service,
           depreciate_flag,
           deprn_method_code,
           deprn_reserve,
           last_update_date,
           last_updated_by,
           life_in_months,
           posting_status,
           --prorate_convention_code,
           ytd_deprn)
        VALUES
          (rec_IFRS_data.numero_immobilisation,
           l_livre,
           rec_IFRS_data.cost,
           fnd_global.user_id,
           SYSDATE,
           rec_IFRS_data.date_de_mise_en_service,
           -- V1.8    11/04/2017     NBO artf2136811 - REP009 - Import - Charger l'interface de livre de gestion en erreur
           /*decode(upper(rec_IFRS_data.amortir),
                  'NON',
                  'NO',
                  'OUI',
                  'YES',
                  rec_IFRS_data.amortir),*/
         -- V1.10   28/08/2017     NBO artf2211081 - REP009 - Import - Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
           'YES',
           --'STL',
           -- V1.5    28/03/2017     NBO Correction suite à la reprise du RUN3
           --rec_IFRS_data.methode_d_amortissement,
           rec_IFRS_data.methode_transco,
           rec_IFRS_data.amortissement_cumule,
           SYSDATE,
           fnd_global.user_id,
           rec_IFRS_data.duree_de_vie_en_mois,
           'POST',
           --'CM_L_01',
           rec_IFRS_data.amortissement_exercice);

        UPDATE  DKA_REP009_CALISTO_INTERFACE
        SET     STATUS             = gv_statut_ok
        WHERE  CURRENT OF cur_IFRS_data;

        g_summary.import_rows_IFRS := g_summary.import_rows_IFRS + 1;
        

      EXCEPTION
        WHEN OTHERS THEN
          g_summary.rejected_rows := g_summary.rejected_rows + 1;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'OI',
                                         'DKA_REP009_CALISTO_INTERFACE',
                                         rec_IFRS_data.numero_immobilisation,
                                         'FA_TAX_INTERFACE',
                                         NULL,
                                         'E',
                                         SUBSTR(SQLERRM, 1, 500));
      END;
    END LOOP; /* rec_IFRS_data IN Cur_IFRS_Data */

    COMMIT;

    fnd_file.put_line(fnd_file.log,
                      'insert_data_IFRS : end : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'insert_data_IFRS : ' || SQLERRM || ':' || l_step;

      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure insert_data_IFRS : EXCEPTION OTHERS ');
  END insert_data_IFRS;

  -- V1.10   28/08/2017     NBO artf2211081 - REP009 - Import - Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
  /*
   *************************************************************************
   * PROCEDURE NAME : update_data_IFRS
   *
   * DESCRIPTION
   *  MAJ du flag amortir des données des livrees sociaux dans la table d'interface
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE update_data_IFRS(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

    -- V1.8    11/04/2017     NBO artf2136811 - REP009 - Import - Charger l'interface de livre de gestion en erreur
    CURSOR cur_IFRS_data IS
      SELECT  dk.*
      FROM    DKA_REP009_CALISTO_INTERFACE dk
      WHERE   nvl(status, gv_statut_new) IN (gv_statut_ok)
      -- V1.4    22/03/2017     NBO Correction suuite à la reprise du RUN3
      AND     EXISTS (
                SELECT '1'
                FROM fa_additions fa, fa_books fb
                WHERE asset_number = dk.numero_immobilisation
                AND fa.asset_id = fb.asset_id
                AND fb.book_type_code like '%IFRS'
               )
      AND     EXISTS (
                SELECT '1'
                FROM fa_tax_interface fa
                WHERE asset_number = dk.numero_immobilisation)
      AND EXISTS
       (SELECT 'x'
                FROM dka_rep009_interface tmp
               WHERE tmp.numero_immobilisation = dk.numero_immobilisation
                 AND decode(upper(tmp.amortir),
                            'NON',
                            'NO',
                            'OUI',
                            'YES',
                            tmp.amortir) =
                     decode(upper(dk.amortir),
                            'NON',
                            'NO',
                            'OUI',
                            'YES',
                            dk.amortir))
      FOR UPDATE;

    l_livre VARCHAR2(100);
    l_step  VARCHAR2(50);
    -- V1.8    11/04/2017     NBO artf2136811 - REP009 - Import - Charger l'interface de livre de gestion en erreur
    lv_depreciate_flag VARCHAR2(10);
    ln_cost NUMBER;
    lv_amortir VARCHAR2(3);

  BEGIN
    p_retcode := 0;

    fnd_file.put_line(fnd_file.log,
                      'update_data_IFRS : start : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));

    FOR rec_IFRS_data IN cur_IFRS_data LOOP

      SELECT  book_type_code
      INTO    l_livre
      FROM    fa_book_controls
      WHERE   book_type_code LIKE rec_IFRS_data.societe || '%'
      AND     book_class = 'TAX';

    -- V1.8    11/04/2017     NBO artf2136811 - REP009 - Import - Charger l'interface de livre de gestion en erreur
      fnd_file.put_line(fnd_file.log,
                      rec_ifrs_data.numero_immobilisation);

      BEGIN
        SELECT cost, decode(upper(amortir),
                    'NON',
                    'NO',
                    'OUI',
                    'YES',
                    amortir)
          INTO ln_cost, lv_depreciate_flag
          FROM DKA_REP009_INTERFACE 
         WHERE numero_immobilisation = rec_ifrs_data.numero_immobilisation;
      EXCEPTION
        WHEN OTHERS THEN
          ln_cost            := NULL;
          lv_depreciate_flag := NULL;
          fnd_file.put_line(fnd_file.log,
                            'Impossible de trouver l''immo : ' ||
                            rec_ifrs_data.numero_immobilisation ||
                            ' et la société : ' || rec_ifrs_data.societe);
      END;
      
      SELECT decode(upper(rec_ifrs_data.amortir),
                    'NON',
                    'NO',
                    'OUI',
                    'YES',
                    rec_ifrs_data.amortir)
        INTO lv_amortir
        FROM dual;
      
      l_step := 'INSERT';

      BEGIN
      
        -- Donnee a inserer dans la table d'interface
        UPDATE fa_tax_interface
        SET depreciate_flag = decode(upper(rec_IFRS_data.amortir),
                  'NON',
                  'NO',
                  'OUI',
                  'YES',
                  rec_IFRS_data.amortir),
           cost = null,
           date_placed_in_service = null,
           deprn_method_code = null,
           deprn_reserve = null,
           life_in_months = null,
           ytd_deprn = null,
           created_by = fnd_global.user_id,
           creation_date = sysdate,
           last_update_date = sysdate,
           last_updated_by = fnd_global.user_id,
           posting_status = 'POST'
        WHERE asset_number = rec_IFRS_data.numero_immobilisation;
        
        UPDATE  DKA_REP009_CALISTO_INTERFACE
        SET     STATUS             = gv_statut_ok
        WHERE  CURRENT OF cur_IFRS_data;

        g_summary.import_rows_IFRS := g_summary.import_rows_IFRS + 1;
        

      EXCEPTION
        WHEN OTHERS THEN
          g_summary.rejected_rows := g_summary.rejected_rows + 1;

          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFAIMOIMP',
                                         'OI',
                                         'DKA_REP009_CALISTO_INTERFACE',
                                         rec_IFRS_data.numero_immobilisation,
                                         'FA_TAX_INTERFACE',
                                         NULL,
                                         'E',
                                         SUBSTR(SQLERRM, 1, 500));
      END;
    END LOOP; /* rec_IFRS_data IN Cur_IFRS_Data */

    COMMIT;

    fnd_file.put_line(fnd_file.log,
                      'update_data_IFRS : end : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'insert_data_IFRS : ' || SQLERRM || ':' || l_step;

      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure insert_data_IFRS : EXCEPTION OTHERS ');
  END update_data_IFRS;

  /*
   *************************************************************************
   * PROCEDURE NAME : Wait_request
   *
   * DESCRIPTION
   *  Attente de la fin du traitement
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE wait_request(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
    v_phase      VARCHAR2(100);
    v_status     VARCHAR2(100);
    v_dev_phase  VARCHAR2(100);
    v_dev_status VARCHAR2(100);
    v_message    VARCHAR2(100);
    --v_nb_ok      NUMBER;
    --v_nb_rejet         NUMBER;

    i BINARY_INTEGER;

  BEGIN
    fnd_file.put_line(fnd_file.log, 'DEBUT wait_request');
    i := g_tab_requests.first;
    WHILE i IS NOT NULL LOOP

      IF NOT Fnd_Concurrent.wait_for_request(g_tab_requests(i),
                                             2,
                                             0,
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
                          'Fin du traitement en warning ' ||
                          g_tab_requests(i));
        v_message := 'ERREUR : Fin du traitement en warning: ' || v_message;
        p_retcode := 1;

      ELSIF v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL' THEN

        p_retcode := 2;
        v_message := 'ERREUR : Fin anormale du traitement : ' ||
                     v_message;

        Fnd_File.put_line(Fnd_File.output,
                          'ERREUR : Fin anormale du traitement ' ||
                           g_tab_requests(i) || CHR(10) || 'Phase/Statut : ' ||
                           v_dev_phase || '/' || v_dev_status || CHR(10) ||
                           'MESSAGE : ' || v_message || CHR(10));
        --Fnd_File.put_line (Fnd_File.LOG, '===> ERREUR : Fin anormale du traitement '||g_import_request_id);
      END IF;

      p_errbuf := v_message;
      i        := g_tab_requests.next(i);
    END LOOP;

  END wait_request;

  /*
   *************************************************************************
   * PROCEDURE NAME : submit_FNDRSSUB46
   *
   * DESCRIPTION
   *  Soumission du traitement de copie initiale haut volume
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE submit_fndrssub46(p_errbuf         OUT VARCHAR2,
                              p_retcode        OUT NUMBER,
                              p_book_type_code IN fa_book_controls.book_type_code%TYPE) IS

    --v_phase      VARCHAR2(100);
    --v_status     VARCHAR2(100);
    --v_dev_phase  VARCHAR2(100);
    --v_dev_status VARCHAR2(100);
    --v_message    VARCHAR2(100);
    b_result     BOOLEAN;
    l_wait_for_req BOOLEAN;

    --l_request_set_exist BOOLEAN := FALSE;
    --l_set_mode          BOOLEAN := FALSE;
    --l_conc_prog_submit  BOOLEAN := FALSE;

    l_phase        VARCHAR2(100);
    l_status       VARCHAR2(100);
    l_dev_phase    VARCHAR2(100);
    l_dev_status   VARCHAR2(100);
    l_message      VARCHAR2(4000);

    srs_failed EXCEPTION;
    submitprog_failed EXCEPTION;
    setmode_failed EXCEPTION;
    submitset_failed EXCEPTION;

    v_request_id fnd_concurrent_requests.request_id%TYPE;

  BEGIN
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début submit_FNDRSSUB46 (' || p_book_type_code || ')');

    b_result := fnd_submit.set_request_set(application => 'OFA', -- Application short name
                                           request_set => 'FNDRSSUB46' -- Request set shot name
                                          );

    IF (NOT b_result) THEN
      RAISE srs_failed;
    END IF;

    b_result := fnd_submit.submit_program('OFA', -- Application short name
                                          'FAMAPT', -- Concurrent program shot name
                                          'STAGE10', -- Stage
                                          p_book_type_code, --parameter for concurrent program
                                          'NORMAL' -- --parameter for concurrent program
                                         );

    IF (NOT b_result) THEN
      RAISE submitprog_failed;
    END IF;

    b_result := fnd_submit.submit_program('OFA', -- Application short name
                                          'FAS824', -- Concurrent program shot name
                                          'STAGE20', -- Stage
                                          p_book_type_code --parameter for concurrent program,
                                          --,'NORMAL' --v1.7 --parameter for concurrent program
                                          );
    IF (NOT b_result) THEN
      RAISE submitprog_failed;
    END IF;

    v_request_id := fnd_submit.submit_set(NULL, FALSE);

    IF v_request_id = 0 THEN
      p_retcode := 2;
      fnd_file.put_line(fnd_file.log,
                        'ERREUR : Le traitement d''imputation du livre a échoué' ||
                        chr(10) || 'LIVRE : ' || p_book_type_code ||
                        chr(10)
                        );
      fnd_file.put_line(fnd_file.output,
                        '====> ERREUR : Le traitement d''imputation du livre ' ||
                        p_book_type_code || ' a échoué');
    ELSE
      COMMIT;

      fnd_file.put_line(fnd_file.output,
                        '. Numéro du traitement la copie initiale haut volume du livre ' ||
                        p_book_type_code || ': ' || v_request_id);

            l_wait_for_req := fnd_concurrent.wait_for_request(request_id => v_request_id,
                                                        INTERVAL   => 2,
                                                        max_wait   => 0,
                                                        phase      => l_phase,
                                                        status     => l_status,
                                                        dev_phase  => l_dev_phase,
                                                        dev_status => l_dev_status,

                                                        message => l_message);
    END IF;

    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin submit_FNDRSSUB46 (' || p_book_type_code || ')');

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'submit_FNDRSSUB46 (' || p_book_type_code || '):' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure submit_FNDRSSUB46 (' ||
                        p_book_type_code || ') : EXCEPTION OTHERS ');
  END submit_fndrssub46;

  /*
   *************************************************************************
   * PROCEDURE NAME : submit_faimcp
   *
   * DESCRIPTION
   *  Soumission du traitement de copie initiale haut volume
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE submit_faimcp(p_errbuf         OUT VARCHAR2,
                          p_retcode        OUT NUMBER,
                          p_book_type_code IN fa_book_controls.book_type_code%TYPE) IS

    --v_phase      VARCHAR2(100);
    --v_status     VARCHAR2(100);
    --v_dev_phase  VARCHAR2(100);
    --v_dev_status VARCHAR2(100);
    --v_message    VARCHAR2(100);
    --b_result     BOOLEAN;

    v_request_id fnd_concurrent_requests.request_id%TYPE;

  BEGIN
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début submit_FAIMCP (' || p_book_type_code || ')');

    v_request_id := fnd_request.submit_request('OFA' -- APPL
                                              ,
                                               'FAIMCP' -- PROG
                                              ,
                                               NULL -- PROGRAM_NAME
                                              ,
                                               NULL -- START
                                              ,
                                               FALSE -- SUB_REQUEST
                                              ,
                                               p_book_type_code -- Livre fiscal
                                              ,
                                               '"INITIAL"',
                                               1);

    IF v_request_id = 0 THEN
      p_retcode := 2;
      fnd_file.put_line(fnd_file.log,
                        'ERREUR : Le traitement de de la copie initiale haut volume du livre a échoué' ||
                        chr(10) || 'LIVRE : ' || p_book_type_code ||
                        chr(10)
                        );
      fnd_file.put_line(fnd_file.output,
                        '====> ERREUR :Le traitement de de la copie initiale haut volume du livre ' ||
                        p_book_type_code || ' a échoué');
    ELSE
      COMMIT;
      g_tab_requests(v_request_id) := v_request_id;

      fnd_file.put_line(fnd_file.output,
                        '. Numéro du traitement la copie initiale haut volume du livre ' ||
                        p_book_type_code || ': ' || v_request_id);
    END IF;

    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin submit_FAIMCP (' || p_book_type_code || ')');

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'submit_FAIMCP (' || p_book_type_code || '):' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure submit_FAIMCP (' ||
                        p_book_type_code || ') : EXCEPTION OTHERS ');
  END submit_faimcp;

  /*
   *************************************************************************
   * PROCEDURE NAME : submit_FATAXUP
   *
   * DESCRIPTION
   *  Soumission du traitement d'import des livres fiscaux
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE submit_fataxup(p_errbuf         OUT VARCHAR2,
                           p_retcode        OUT NUMBER,
                           p_book_type_code IN fa_book_controls.book_type_code%TYPE) IS

    --v_phase      VARCHAR2(100);
    --v_status     VARCHAR2(100);
    --v_dev_phase  VARCHAR2(100);
    --v_dev_status VARCHAR2(100);
    --v_message    VARCHAR2(100);
    --b_result     BOOLEAN;

    v_request_id fnd_concurrent_requests.request_id%TYPE;

  BEGIN
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début submit_FATAXUP (' || p_book_type_code || ')');

    v_request_id := fnd_request.submit_request('OFA' -- APPL
                                              ,
                                               'FATAXUP' -- PROG
                                              ,
                                               NULL -- PROGRAM_NAME
                                              ,
                                               NULL -- START
                                              ,
                                               FALSE -- SUB_REQUEST
                                              ,
                                               p_book_type_code -- Livre fiscal
                                               );

    IF v_request_id = 0 THEN
      p_retcode := 2;
      fnd_file.put_line(fnd_file.log,
                        'ERREUR : Le traitement de chargement du livre fiscal a échoué' ||
                        chr(10) || 'LIVRE : ' || p_book_type_code ||
                        chr(10)
                        );

      fnd_file.put_line(fnd_file.output,
                        '====> ERREUR :Le traitement de chargement du livre fiscal ' ||
                        p_book_type_code || ' a échoué');
    ELSE
      COMMIT;

      g_tab_requests(v_request_id) := v_request_id;

      fnd_file.put_line(fnd_file.log,
                        '=> LOAD REQUEST ID= ' || v_request_id);
      fnd_file.put_line(fnd_file.output,
                        '. Numéro du traitement de chargement livre fiscal ' ||
                        p_book_type_code || ': ' || v_request_id);
    END IF;

    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin submit_FATAXUP (' || p_book_type_code || ')');

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'submit_FATAXUP (' || p_book_type_code || '):' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure submit_FATAXUP (' ||
                        p_book_type_code || ') : EXCEPTION OTHERS ');
  END submit_fataxup;

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
  PROCEDURE report_bilan(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

  BEGIN

    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début Report_Bilan');

    --------------------
    -- Initialisation --
    --------------------

    p_errbuf  := NULL;
    p_retcode := 0;

    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output, 'BILAN :');
    fnd_file.put_line(fnd_file.output, '-------');

    fnd_file.put_line(fnd_file.output,
                      '   . Nombre d''enregistrements SOCIAL chargés dans les tables spécifiqu            : ' ||
                      to_char(g_summary.loaded_rows_social));
    fnd_file.put_line(fnd_file.output,
                      '   . Nombre d''enregistrements IFRS chargés dans les tables spécifiques            : ' ||
                      to_char(g_summary.loaded_rows_IFRS));
    fnd_file.put_line(fnd_file.output,
                      '   . Nombre d''enregistrements SOCIAL validés                                      : ' ||
                      to_char(g_summary.valid_rows_social));
    fnd_file.put_line(fnd_file.output,
                      '   . Nombre d''enregistrements IFRS validés                                        : ' ||
                      to_char(g_summary.valid_rows_IFRS));
    fnd_file.put_line(fnd_file.output,
                      '   . Nombre d''enregistrements SOCIAL importé dans les Open Interface              : ' ||
                      to_char(g_summary.import_rows_social));
    fnd_file.put_line(fnd_file.output,
                      '   . Nombre d''enregistrements IFRS importé dans les Open Interface              : ' ||
                      to_char(g_summary.import_rows_IFRS));

    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output,
                      'Voir les sorties des traitements d''Open interface pour avoir plus de détails sur les enregistrements rejetés.');

    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin Report_Bilan');

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'REPORT_BILAN : ' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
  END report_bilan;

   /*
   *************************************************************************
   * PROCEDURE NAME : Launch_Loader_immo
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
  PROCEDURE launch_loader_immo(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER, p_interface IN VARCHAR2, p_filename IN VARCHAR2) IS
    v_phase      VARCHAR2(100);
    v_status     VARCHAR2(100);
    v_dev_phase  VARCHAR2(100);
    v_dev_status VARCHAR2(100);
    v_message    VARCHAR2(100);
    b_result     BOOLEAN;

  BEGIN
    p_retcode := 0;

    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début Launch_Loader');
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Lancement de chargement du fichier dans la table d''interface spécifique : ');

    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output, 'CHARGEMENT DU FICHIER :');
    fnd_file.put_line(fnd_file.output, '----------------------');
    ------------------------------------------------------
    -- Lancement du traitement de chargement du fichier --
    ------------------------------------------------------
    -- Positionnement des options d'impression
    b_result := fnd_request.set_print_options(printer => gv_printer,
                                              copies  => g_number_of_copies);
    -- Lancement du traitement
    g_loader_request_id := fnd_request.submit_request('DKA' -- APPL
                                                     ,
                                                      p_interface -- PROG
                                                     ,
                                                      NULL -- PROGRAM_NAME
                                                     ,
                                                      NULL -- START
                                                     ,
                                                      FALSE -- SUB_REQUEST
                                                      ,
                                                      p_filename
                                                      );

    IF g_loader_request_id = 0 THEN
      p_retcode := 2;
      fnd_file.put_line(fnd_file.log,
                        'ERREUR : Le traitement de chargement du fichier a échoué' ||
                        chr(10) || 'PROGRAMME  : ' || p_interface
                        --'FICHIER : ' || p_file_name || CHR(10)
                        );
      fnd_file.put_line(fnd_file.output,
                        '====> ERREUR : Le traitement de chargement du fichier a échoué');
    ELSE
      COMMIT;
      fnd_file.put_line(fnd_file.log,
                        '=> LOAD REQUEST ID= ' || g_loader_request_id);
      fnd_file.put_line(fnd_file.output,
                        '. Numéro du traitement de chargement du fichier : ' ||
                        g_loader_request_id);

      -- Attente de la fin du traitement
      IF NOT (fnd_concurrent.wait_for_request(g_loader_request_id,
                                              5,
                                              0,
                                              v_phase,
                                              v_status,
                                              v_dev_phase,
                                              v_dev_status,
                                              v_message)) THEN
        p_errbuf := v_message;
        fnd_file.put_line(fnd_file.log,
                          'ERREUR : Attente de la fin du programme de chargement du fichier dépassée : Fin du traitement' ||
                          chr(10) || 'MESSAGE : ' || v_message || chr(10));
      END IF;

      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
        fnd_file.put_line(fnd_file.log,
                          'COMPLETION= ' || v_dev_phase || '/' ||
                          v_dev_status);
        fnd_file.put_line(fnd_file.output,
                          '. Statut de fin : ' || v_phase || '/' ||
                          v_status);

      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
        fnd_file.put_line(fnd_file.log,
                          'Fin du traitement de chargement en warning ' ||
                          g_loader_request_id);
        p_retcode := 1;

      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
        p_retcode := 2;
        p_errbuf  := 'ERREUR : Fin anormale du traitement de chargement : ' ||
                     v_message;

        fnd_file.put_line(fnd_file.log,
                          'ERREUR : Fin anormale du traitement de chargement ' ||
                          g_loader_request_id || chr(10) ||
                          'Phase/Statut : ' || v_dev_phase || '/' ||
                          v_dev_status || chr(10) || 'MESSAGE : ' ||
                          v_message || chr(10));
        fnd_file.put_line(fnd_file.output,
                          '===> ERREUR : Fin anormale du traitement de chargement ' ||
                          g_loader_request_id);
      END IF;

    END IF;

    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin Launch_Loader Immo');

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'LAUNCH_LOADER IMMO : ' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure Launch_Loader Immo : EXCEPTION OTHERS ');
  END launch_loader_immo;

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

  PROCEDURE main(p_errbuf       IN OUT VARCHAR2,
                 p_retcode      OUT NUMBER,
                 p_file_social  IN VARCHAR2,
                 p_file_calisto IN VARCHAR2,
                 p_load_file    IN VARCHAR2,
                 p_load_OI      IN VARCHAR2,
                 p_launch_OI    IN VARCHAR2) IS

    v_current_program_unit VARCHAR2(30);
    v_errbuf               VARCHAR2(2500);
    v_retcode              NUMBER;
    erreur_programme EXCEPTION;

    /*CURSOR cur_ifrs IS
      SELECT fbc.book_type_code
        FROM fa_book_controls fbc
       WHERE fbc.book_type_code LIKE '%IFRS'
         AND fbc.book_class = 'TAX';*/


     -- V1.6    05/04/2017     NBO artf2134134 - REP009 - Import - Mise a jour des projets PA
     CURSOR cur_immo IS
       SELECT ppa.project_id,
         ppa.rowid rid,
         x.asset_id,
         ppa.asset_number,
         x.asset_number fa_asset_number,
         x.task_number,
         ppa.asset_description,
         x.description,
         ppa.date_placed_in_service,
         x.date_placed_in_service fa_date_placed_in_service,
         ppa.attribute1,
         ppa.capital_hold_flag,
         ppa.location_id,
         x.location_id fa_location_id,
         ppa.asset_key_ccid,
         x.asset_key_ccid fa_asset_key_ccid,
  -- V1.9    20/04/2017     NBO artf2134134 - REP009 - Import - Mise a jour des projets PA
         COUNT(1) over(PARTITION BY ppa.project_id, asset_name ORDER BY ppa.project_id, asset_name) cpt
    FROM pa_project_assets_all ppa,
	     DKA_REP009_INTERFACE DRI,      -- SELO EDB291
         (SELECT DISTINCT fa.asset_id,
                          fa.asset_number,
                          fa.asset_key_ccid,
                          fa.description,
                          fdh.location_id,
                          fb.book_type_code,
                          fb.date_placed_in_service,
                          pp.project_id,
                          pt.task_id,
                          pt.task_number
            FROM fa_additions fa
            JOIN fa_books fb ON fa.asset_id = fb.asset_id
            JOIN fa_distribution_history fdh ON fa.asset_id = fdh.asset_id
            JOIN fa_asset_invoices fai ON fa.asset_id = fai.asset_id
            JOIN pa_projects_all pp ON fai.project_id = pp.project_id
            JOIN pa_tasks pt ON fai.task_id = pt.task_id) x
   WHERE (ppa.project_id = x.project_id AND ppa.asset_name = x.task_number AND
         ppa.book_type_code = x.book_type_code)
     AND ppa.Asset_name = DRI.Projet   -- SELO EDB291
     AND ppa.fa_asset_id IS NULL;

  BEGIN

    ----------------------------
    -- PHASE D'INITIALISATION --
    ----------------------------

    v_current_program_unit := 'main';
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'DEBUT DE L''INTERFACE');

    output_header;
    request_parameters;

    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE D''INITIALISATION');

    v_errbuf  := NULL;
    v_retcode := 0;

    init(v_errbuf, v_retcode);

    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE erreur_programme;
    END IF;

    IF p_load_file = 'Y' THEN
      ------------------------------------
      -- PHASE DE CHARGEMENT DU FICHIER --
      ------------------------------------
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'PHASE DE CHARGEMENT DU FICHIER');

      -- Lancement du programme de chargement des immos sociales
      launch_loader_immo(v_errbuf, v_retcode, 'DKA_LOADER_REPFAIMOIMP', p_file_social);
      IF v_retcode = 2 THEN
        p_errbuf  := v_errbuf;
        p_retcode := v_retcode;
        RAISE erreur_programme;
      END IF;

      -- Lancement du programme de chargement des immos IFRS
      launch_loader_immo(v_errbuf, v_retcode, 'DKA_LOADER_REPFAIMOCALIMP', p_file_calisto);
      IF v_retcode = 2 THEN
        p_errbuf  := v_errbuf;
        p_retcode := v_retcode;
        RAISE erreur_programme;
      END IF;

      ------------------------------------
      -- PHASE DE COPIE DES IMMOS CALISTO SOCIALES
      ------------------------------------
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'PHASE DE COPIE DES IMMOS CALISTO SOCIALES');

      duplicate_calisto_social(v_errbuf, v_retcode);
      IF v_retcode = 2 THEN
        p_errbuf  := v_errbuf;
        p_retcode := v_retcode;
        RAISE erreur_programme;
      END IF;

    END IF;

    -------------------------------------
    --  CTRL DES DONNEES DES LIVRES SOCIAL
    -------------------------------------
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'CTRL DES DONNEES DES LIVRES SOCIAL');

    validate_data_social(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE erreur_programme;
    END IF;

    IF p_load_OI = 'Y' THEN
      -------------------------------------
      --  CHARGEMENT DES DONNEES DES LIVRES SOCIAL
      -------------------------------------
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'CHARGEMENT DES DONNEES DES LIVRES SOCIAL');

      insert_data_social(v_errbuf, v_retcode);
      IF v_retcode = 2 THEN
        p_errbuf  := v_errbuf;
        p_retcode := v_retcode;
        RAISE erreur_programme;
      END IF;
    END IF;

    IF p_launch_OI = 'Y' THEN
      -------------------------------------
      --  SOUMISSION DE L IMPUTATION DES IMMOBILISATIONS
      -------------------------------------
      --g_tab_requests.delete;

      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'SOUMISSION DE L IMPUTATION DES IMMOBILISATIONS');

      FOR r_book IN ( select  distinct book_type_code
                      from    fa_mass_additions
                      where   posting_status = 'POST'
                      order by 1
                    ) LOOP

        submit_fndrssub46(v_errbuf, v_retcode, r_book.book_type_code);

        IF v_retcode = 2 THEN
          p_errbuf  := v_errbuf;
          p_retcode := v_retcode;
          RAISE erreur_programme;
        END IF;

      END LOOP;

      --wait_request(p_errbuf, p_retcode);

      -------------------------------------
      --  SOUMISSION DE LA COPIE INITIALE HAUT VOLUME
      -------------------------------------
      g_tab_requests.delete;

      fnd_file.put_line(fnd_file.log,
                  to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                  'SOUMISSION DE LA COPIE INITIALE HAUT VOLUME');

      -- V1.8    11/04/2017     NBO artf2136811 - REP009 - Import - Charger l'interface de livre de gestion en erreur
      FOR r_book IN ( SELECT  DISTINCT substr(fma.book_type_code,1,4) || ' IFRS' book_type_code
                      FROM    fa_mass_additions fma
					      ,   DKA_REP009_INTERFACE DRI -- SELO EDB291
                      WHERE   fma.posting_status = 'POSTED'
                     -- V1.10   11/08/2017     NBO artf2211081 - REP009 - Import - Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
                     -- Cette restriction du spécifique doit par conséquent être commentée pour autoriser la création des immos IFRS.
                     -- AND     fma.depreciate_flag = 'YES'
					  AND     DRI.numero_immobilisation = fma.asset_number -- SELO EDB291
                      AND     fma.asset_category_id in (
                                SELECT  distinct fcb.category_id
                                FROM    fa_category_books fcb
                                        join fa_book_controls fbc
                                          on fcb.book_type_code = fbc.book_type_code
                                            and fbc.book_class = 'TAX' )
                      AND     NOT EXISTS (
                                SELECT  1
                                FROM    fa_additions fa
                                        join fa_books fb
                                          on fa.asset_id = fb.asset_id
                                        join fa_book_controls fbc
                                          on fb.book_type_code = fbc.book_type_code
                                            and fbc.book_class = 'TAX'
                                WHERE   fa.asset_number = fma.asset_number
                              )
                      ORDER BY 1
                    ) LOOP
        fnd_file.put_line(fnd_file.log, 'livre='||r_book.book_type_code);
        submit_faimcp(v_errbuf, v_retcode, r_book.book_type_code);

        IF v_retcode = 2 THEN
          p_errbuf  := v_errbuf;
          p_retcode := v_retcode;
          RAISE erreur_programme;
        END IF;

      END LOOP;

      wait_request(p_errbuf, p_retcode);
    END IF;

    -------------------------------------
    --  CTRL DES DONNEES DES LIVRES IFRS
    -------------------------------------
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'CTRL DES DONNEES DES LIVRES IFRS');

    validate_data_IFRS(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE erreur_programme;
    END IF;

    IF p_load_OI = 'Y' THEN
      -------------------------------------
      --  CHARGEMENT DES DONNEES DES LIVRES IFRS
      -------------------------------------
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'CHARGEMENT DES DONNEES DES LIVRES IFRS');

      insert_data_IFRS(v_errbuf, v_retcode);
      IF v_retcode = 2 THEN
        p_errbuf  := v_errbuf;
        p_retcode := v_retcode;
        RAISE erreur_programme;
      END IF;
    END IF;

    IF p_launch_OI = 'Y' THEN
      -------------------------------------
      --  SOUMISSION DE LA MISE A JOUR DES DONNEE IFRS
      -------------------------------------
      g_tab_requests.delete;

      fnd_file.put_line(fnd_file.log,
          to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
          'SOUMISSION DE LA MISE A JOUR DES DONNEE IFRS');

      -- V1.10   28/08/2017     NBO artf2211081 - REP009 - Import - Des immos IFRS ne sont créées car le champ Amortir est à NON dans l'immo SOCIAL
      FOR i IN 1..2 LOOP
        FOR r_book IN ( select  distinct book_type_code
                        from    fa_tax_interface
                        where   posting_status = 'POST'
                        order by 1
                      ) LOOP

          submit_fataxup(v_errbuf, v_retcode, r_book.book_type_code);

          IF v_retcode = 2 THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RAISE erreur_programme;
          END IF;
          


        END LOOP;

        wait_request(p_errbuf, p_retcode);
        
        update_data_IFRS(v_errbuf, v_retcode);
        IF v_retcode = 2 THEN
          p_errbuf  := v_errbuf;
          p_retcode := v_retcode;
          RAISE erreur_programme;
        END IF;
        
      END LOOP;
      
    END IF;

    -------------------------------------
    --  MISE A JOUR DES PROJETS AVEC LES INFOS IMMOS
    -------------------------------------

    fnd_file.put_line(fnd_file.log,
        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
        'MISE A JOUR DES PROJETS AVEC LES INFOS IMMOS');

    -- V1.6    05/04/2017     NBO artf2134134 - REP009 - Import - Mise a jour des projets PA
    FOR rec_immo IN cur_immo LOOP
      IF rec_immo.cpt > 1 THEN
        dka_tools_pkg.ins_prog_message(g_request_id,
                               'DKA_REPFAIMOIMP',
                               'ETL',
                               'DKA_REP009_INTERFACE',
  -- V1.9    20/04/2017     NBO artf2134134 - REP009 - Import - Mise a jour des projets PA
                               rec_immo.fa_asset_number,
                               'PROJECT_ID',
                               rec_immo.project_id || '/' || rec_immo.task_number,
                               'E',
                               'La tâche a été affecté sur plusieurs immos');

        UPDATE  DKA_REP009_INTERFACE
        SET     STATUS = gv_statut_postimport
  -- V1.9    20/04/2017     NBO artf2134134 - REP009 - Import - Mise a jour des projets PA
        WHERE  numero_immobilisation =  rec_immo.fa_asset_number;
      ELSE
        UPDATE pa_project_assets_all ppa
        SET ppa.fa_asset_id = rec_immo.asset_id,
  -- V1.9    20/04/2017     NBO artf2134134 - REP009 - Import - Mise a jour des projets PA
                 ppa.asset_number = rec_immo.fa_asset_number,
                 ppa.asset_description = rec_immo.description,
                 ppa.date_placed_in_service = rec_immo.date_placed_in_service,
                 ppa.attribute1 = 'Y',
                 ppa.capital_hold_flag = 'Y',
                 ppa.location_id = rec_immo.location_id,
                 ppa.asset_key_ccid = rec_immo.asset_key_ccid
        WHERE rowid = rec_immo.rid;
      END IF;

    END LOOP;

    ------------------------------------
    -- IMPRESSION DES ANOMALIES --
    ------------------------------------
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE DES ANOMALIES');
    print_errors;

    ------------------------------------
    -- IMPRESSION DU BILAN --
    ------------------------------------
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE BILAN');
    report_bilan(p_errbuf, p_retcode);

    ---------------------------------------
    -- PHASE DE FIN DU TRAITEMENT MAITRE --
    ---------------------------------------
    IF p_retcode = 2 THEN
      p_errbuf := 'ATTENTION : Erreur bloquante : ' || p_errbuf;
    ELSIF (g_summary.rejected_rows > 0) THEN
      p_errbuf  := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
      p_retcode := 1;
    ELSIF (g_summary.loaded_rows_social = 0 OR g_summary.loaded_rows_IFRS = 0) THEN
      p_errbuf  := 'ATTENTION : Aucun enregistrement chargé.';
      p_retcode := 1;
    ELSE
      p_errbuf  := 'Fin normale du traitement - Aucun rejet.';
      p_retcode := 0;
    END IF;

    fnd_file.put_line(fnd_file.log, p_errbuf);
    fnd_file.put_line(fnd_file.output, chr(10) || p_errbuf || chr(10));
    output_end;
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'FIN DE L''INTERFACE');

  EXCEPTION
    WHEN erreur_programme THEN
      p_retcode := 2;
      p_errbuf  := v_errbuf;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.output, chr(10) || p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure ' || v_current_program_unit ||
                        ' : EXCEPTION Erreur_Traitement ');
      fnd_file.put_line(fnd_file.output,
                        '==> Fin de la procédure ' ||
                        v_current_program_unit ||
                        ' : EXCEPTION Erreur_Traitement ');
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      fnd_file.put_line(fnd_file.log,
                        'Erreur technique sur le composant   : ' ||
                        'DKA_REPFAIMOIMP_PKG.' || v_current_program_unit ||
                        chr(10) || 'A retourné     : ' || SQLERRM);
      fnd_file.put_line(fnd_file.output,
                        chr(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        chr(10));
      p_errbuf := SQLERRM;
  END main;

END dka_repfaimoimp_pkg;
/
SHOW ERRORS
EXIT
