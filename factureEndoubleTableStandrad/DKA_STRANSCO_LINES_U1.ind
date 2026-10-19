CREATE OR REPLACE PACKAGE BODY dka_iaparglctrlfiscal_pkg AS
  ----------------------------------------------------------------------------------------------
  -- $Id$
  -- CAPGEMINI
  -- PROJET                        : DALKIA Oracle Applications
  -- NOM                             : DKA_IAPARGLCTRLFISCAL_PKG.pkb
  -- DESCRIPTION             : DKA_IAPARGLCTRLFISCAL_PKG package body :
  ---
  --- AUTEUR                     : Julien Jardez
  --- DATE DE CREATION : 20/08/2013
  --- DOC. ASSOCIEE        :
  -- COMMENTAIRE             : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- ---------- --- ---------------------------------------------------------------------------
  --- 18/11/2013 JJA DPE20130086 : Modification des RG
  --- 06/12/2013 CDE Modification de la RG sur le journal d'ouverture
  --- 06/06/2016 YWA Migration R12
  --- 22/06/2017 YWA artf2180347
  --- 24/08/2017 RBE artf2213960 : INT075 - Revoir extraction autres GL - defect beB # 915
  --- 12/09/2017 JJA artf2220598 : INT075 - Ecarts sur compte - defect beB # 915
  --- 06/10/2017 OBE artf2238161 : INT075 - Gestion des factures AP issues de AR - defect beB # 915
  --- 13/02/2019 JWYC INC0289351 (artf07155923) : Optimisation requête GL + Correction AR + Correction libelle entete
  --- 23/11/2020 ARA EDB283 - Modification fichier des FEC (PIECEREF et PIECEDATE)
  --- 18/12/2020 SHA INC0492493 - FEC Correctif sur le fichier des descriptions
  --- 12/04/2021 JWYC TASK0133265 : Problème de performance requête GL, retour version INC0289351
  --- 26/04/2021 NBO  artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1
  --- 11/05/2021 SHA artf07457202 :INT075 - dates du FEC sont erronées en juin 
  --- 13/07/2021 SHA EDB299 Ajout du traitement DKA - Automate Extraction contrôle fiscal 
  --- 01/02/2022 SHA Retour recette EDB299 - 
  --- 02/03/2022 SELO EDB334
  --- 11/04/2022 AFE - TASK0172627 correctif FEC LIVRES PRIMAIRES et périodes de début <> JAN
  
  ----------------------------------------------------------------------------------------------
  --TYPE
  TYPE r_donnee_fichier IS RECORD(
    annee        NUMBER,
    date_debut   DATE,
    date_fin     DATE,
    date_fichier DATE,
    suffixe      VARCHAR2(50));

  TYPE r_param_data IS RECORD(
    data_name  VARCHAR2(500),
    data_value VARCHAR2(4000));

  TYPE t_table_fichier IS TABLE OF r_donnee_fichier INDEX BY BINARY_INTEGER;
  TYPE t_table_param IS TABLE OF r_param_data INDEX BY BINARY_INTEGER;
  TYPE t_lettrage_tiers IS TABLE OF VARCHAR2(1) INDEX BY VARCHAR2(6);

  TYPE myrecord IS RECORD(
    request_id NUMBER);

  TYPE mytable IS TABLE OF myrecord INDEX BY BINARY_INTEGER;

  --CONSTANTE
  cv_package_name CONSTANT VARCHAR2(30) := 'DKA_IAPARGLCTRLFISCAL_PKG';
  cv_fsep         CONSTANT VARCHAR2(1) := chr(9);
  g_request_id NUMBER := fnd_global.conc_request_id;
  --CONSTANTE JEU DE VALEUR, TRANSCO ....
  cv_program_name   CONSTANT VARCHAR2(30) := 'IAPARGLCTRLFISCAL';
  cv_param_nb_annee CONSTANT VARCHAR2(30) := 'NB_ANNEE';
  cv_directory      CONSTANT VARCHAR2(30) := 'DKA_OUT_DIR';
  cv_jdv_cpt_local  CONSTANT VARCHAR2(30) := 'DAOPCCF_LOCAL';
  cv_jdv_ste        CONSTANT VARCHAR2(30) := 'DAOPCCF_STE';
  cv_jdv_caract_spe CONSTANT VARCHAR2(30) := 'DKA_CARACTERE_EXTRACT_FISCALE';

  cn_annee_prec    CONSTANT PLS_INTEGER := 1;
  cv_devise        CONSTANT VARCHAR2(10) := 'EUR';
  cv_nom_fichier   CONSTANT VARCHAR2(10) := 'FEC';
  cv_extension     CONSTANT VARCHAR2(10) := '.txt';
  cn_nb_annee      CONSTANT PLS_INTEGER := 1; --JJA 18/11/2013
  cv_type_fichier  CONSTANT VARCHAR2(50) := 'Fichier ASCII';
  cv_separateur    CONSTANT VARCHAR2(50) := 'Tabulation';
  cv_fichier_param CONSTANT VARCHAR2(50) := '_descrip_extraction_fisc';
  cv_line          CONSTANT VARCHAR2(75) := '+-------------------------------------------------------------------------+';
  cv_compte_loc_cr CONSTANT VARCHAR2(10) := '120000';
  cv_compte_loc_dr CONSTANT VARCHAR2(10) := '119000';

  --VARIABLE GLOBALES
  gn_sob_id          gl_sets_of_books.set_of_books_id%TYPE;
  gn_conc_request_id fnd_concurrent_requests.request_id%TYPE;
  gn_nb_annee        dka_parameters.number_value%TYPE;
  gv_siren           xle_registrations.registration_number%TYPE; --YWA
  gv_ligne_entete    VARCHAR2(500);
  gv_out_message     VARCHAR2(4000);
  gn_insert          PLS_INTEGER;
  gn_cpt             PLS_INTEGER;
  gv_step            VARCHAR2(500);

  gd_date_debut DATE;
  gd_date_fin   DATE;
  gv_period     VARCHAR2(10);

  gv_transco_de VARCHAR2(4000);
  gv_transco_a  VARCHAR2(4000);

  gt_table_fichier  t_table_fichier;
  gt_table_param    t_table_param;
  gt_lettrage_tiers t_lettrage_tiers;

  gv_desc_cpte_loc_cr VARCHAR2(240);
  gv_desc_cpte_loc_dr VARCHAR2(240);

  --PARAMETRES
  gv_societe   VARCHAR2(10);
  gn_annee_ref NUMBER;
  gn_periode   NUMBER;

  -----------------------------------------------------------------------
  -- GET_TIME
  ----------------------------------------------------------------------
  --    fonction qui retourne la date et l'heure actuelle
  --
  --    Parametres : N/A
  --
  -----------------------------------------------------------------
  FUNCTION get_time RETURN VARCHAR2 IS
  BEGIN
    RETURN to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
  END get_time;

  -----------------------------------------------------------------------
  -- TRANSLATE_TEXTE
  ----------------------------------------------------------------------
  --    fonction traduit le texte en fonction des caractères spéciaux
  --
  --    Parametres : N/A
  --
  -----------------------------------------------------------------
  FUNCTION translate_texte(p_texte_to_translate IN VARCHAR2) RETURN VARCHAR2 IS
  
    lv_current_program_unit VARCHAR2(30) := 'translate_texte';
    pv_errbuf               VARCHAR2(500);
  
    l_texte_transcode VARCHAR2(4004);
  
  BEGIN
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit || ' 001 : INIT';
    --dka_tools_pkg.put_debug_message(gv_step);
    l_texte_transcode := p_texte_to_translate;
  
    --On ne traduit que si les paramètres de transco sont alimentés
    IF gv_transco_de IS NOT NULL AND gv_transco_a IS NOT NULL THEN
    
      gv_step := lv_current_program_unit ||
                 ' 002 : Suppression des blancs en début et fin de texte';
      --dka_tools_pkg.put_debug_message(gv_step);
      l_texte_transcode := TRIM(' ' FROM l_texte_transcode);
    
      gv_step := lv_current_program_unit ||
                 ' 003 : Traduction du texte avec paramètre';
      --dka_tools_pkg.put_debug_message(gv_step);
      l_texte_transcode := translate(l_texte_transcode,
                                     ' ' || gv_transco_de,
                                     ' ' || gv_transco_a);
    
      gv_step := lv_current_program_unit || ' 004 : l_texte_transcode : ' ||
                 l_texte_transcode;
      --dka_tools_pkg.put_debug_message(gv_step);
    
    END IF;
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    RETURN l_texte_transcode;
  
  EXCEPTION
    WHEN OTHERS THEN
      gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
  END translate_texte;

  -----------------------------------------------------------------
  --    Nom                     : INSERT_TABLE_PARAM
  --    Description     : procedure d'insertion dans la table de parametre
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE insert_table_param(pn_n_ordre    IN NUMBER,
                               pv_groupe     IN VARCHAR2,
                               pv_data_name  IN VARCHAR2,
                               pv_data_value IN VARCHAR2,
                               pv_data_type  IN VARCHAR2,
                               pn_data_lg    IN NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'insert_table_param';
    ln_n_ordre              NUMBER;
  
    pv_errbuf VARCHAR2(500);
  
  BEGIN
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit ||
               ' 001 : DETERMINATION DU N° ORDRE';
    --dka_tools_pkg.put_debug_message(gv_step);
    IF pn_n_ordre IS NULL THEN
      SELECT MAX(n_ordre)
        INTO ln_n_ordre
        FROM dka_param_extract_fiscal
      --- 26/04/2021 NBO   artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
      --WHERE  request_id = fnd_global.conc_request_id;
       WHERE request_id = gn_conc_request_id;
    
      ln_n_ordre := nvl(ln_n_ordre, 0);
    END IF;
  
    gv_step := lv_current_program_unit || ' 002 : INSERTION EN TABLE';
    --dka_tools_pkg.put_debug_message(gv_step);
    INSERT INTO dka_param_extract_fiscal
      (request_id,
       n_ordre,
       groupe,
       data_name,
       data_value,
       data_type,
       data_lg)
    VALUES
    --- 26/04/2021 NBO  artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
      ( --fnd_global.conc_request_id,
       gn_conc_request_id,
       nvl(pn_n_ordre, ln_n_ordre + 1),
       pv_groupe,
       pv_data_name,
       pv_data_value,
       pv_data_type,
       pn_data_lg);
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
  END insert_table_param;

  -----------------------------------------------------------------
  --    Nom                     : get_parameters
  --    Description     : procedure d'initialisation
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBERdescrip_extraction_fisc
  -----------------------------------------------------------------
  PROCEDURE get_parameters(pv_errbuf    OUT NOCOPY VARCHAR2,
                           pn_retcode   OUT NOCOPY NUMBER,
                           pv_societe   IN VARCHAR2,
                           pn_annee_ref IN NUMBER,
                           pn_periode   IN NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'get_parameters';
  
  BEGIN
  
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit ||
               ' 001 : Affectations aux variables globales';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_societe   := pv_societe;
    gn_annee_ref := pn_annee_ref;
    gn_periode   := pn_periode; --1, 3, 6 ou 12
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      gv_step := lv_current_program_unit || ' EE2 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END get_parameters;

  -----------------------------------------------------------------
  --    Nom                     : INIT
  --    Description     : procedure d'initialisation
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE init(pv_errbuf  OUT NOCOPY VARCHAR2,
                 pn_retcode OUT NOCOPY NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'init';
    rec_param               dka_parameters%ROWTYPE;
  
    lr_donnee_fichier r_donnee_fichier;
    lv_nom_societe    fnd_flex_values_vl.description%TYPE;
    ln_annee_tmp      PLS_INTEGER;
    ld_date_debut     DATE;
    ld_date_fin_tmp   DATE;
    lv_ligne          VARCHAR2(500);
    ln_annee_debut    PLS_INTEGER;
    ln_annee_fin      PLS_INTEGER;
    lv_lettre         VARCHAR2(10);
    lv_secondaire     varchar2(1);
    ln_cpt_period     PLS_INTEGER;
    ln_num_ordre      PLS_INTEGER;
  
    CURSOR c_period(cd_date_debut DATE, cd_date_fin DATE) IS
      SELECT gps.period_set_name,
             gpt.period_type,
             gpt.number_per_fiscal_year,
             gp.period_name,
             gp.period_year,
             gp.period_num,
             gp.start_date,
             gp.end_date
        FROM gl_period_sets  gps,
             gl_periods      gp,
             gl_period_types gpt,
             gl_ledgers      gl
       WHERE gl.ledger_id = gn_sob_id -- gsob.set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID') YWA
         AND gps.period_set_name = gl.period_set_name
         AND gps.zd_edition_name = gp.zd_edition_name --YWA
         AND gp.period_set_name = gps.period_set_name
         AND gp.period_type = gpt.period_type
         AND gp.start_date BETWEEN cd_date_debut AND cd_date_fin
       ORDER BY gp.period_year ASC, gp.period_num ASC;
  
    CURSOR c_lettrage_tiers IS
      SELECT ffvv.flex_value
        FROM fnd_flex_value_sets ffvs, fnd_flex_values_vl ffvv
       WHERE ffvs.flex_value_set_id = ffvv.flex_value_set_id
         AND ffvs.flex_value_set_name = 'DKA_LETTRAGE_TIERS'
         AND ffvv.enabled_flag = 'Y'
         AND SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
             nvl(ffvv.end_date_active, SYSDATE);
  
    CURSOR c_transco IS
      SELECT ffvv.flex_value, ffvv.description, ffvv.enabled_flag
        FROM fnd_flex_values_vl ffvv, fnd_flex_value_sets ffvs
       WHERE ffvs.flex_value_set_name = cv_jdv_caract_spe
         AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
         AND SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
             nvl(ffvv.end_date_active, SYSDATE)
       ORDER BY description ASC,
                ffvv.enabled_flag DESC,
                to_number(ffvv.flex_value) ASC;
  
  BEGIN
  
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit || ' 001 : Init variables';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    pn_retcode := 0;
    pv_errbuf  := NULL;
    --gn_sob_id                    --:= fnd_profile.value('GL_SET_OF_BKS_ID');
    gn_conc_request_id := fnd_global.conc_request_id;
    gn_insert          := 0;
    gn_cpt             := 0;
  
    gv_step := 'INIT 002 : Recherche du nombre d''année à extraire';
    --dka_tools_pkg.put_debug_message(gv_step);
    dka_tools_pkg.get_parameter(cv_program_name,
                                cv_param_nb_annee,
                                rec_param,
                                pv_errbuf,
                                pn_retcode);
    gn_nb_annee := nvl(rec_param.number_value, cn_nb_annee);
    gv_step     := 'INIT 002 : ' || gn_nb_annee;
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := 'INIT 003 : Recherche du numéro siren';
    --dka_tools_pkg.put_debug_message(gv_step);
    /*
    SELECT SIREN
    INTO gv_siren
    FROM dka_bdste_donnees_sociales
    WHERE company_code = gv_societe;*/ --YWA
  
    SELECT xr.registration_number, gl.ledger_id
      INTO gv_siren, gn_sob_id
      FROM xle_registrations xr, gl_ledgers gl, xle_entity_profiles xep
     WHERE xr.source_id = xep.legal_entity_id
       AND xr.source_table = 'XLE_ENTITY_PROFILES'
      -- AND gl.name = xep.name
	   AND gl.short_name = xep.LEGAL_ENTITY_IDENTIFIER --SHA Retour recette EDB299
       AND gl.ledger_category_code = 'PRIMARY'
       AND xep.legal_entity_id IN
           (SELECT DISTINCT default_legal_context_id
              FROM hr_operating_units
             WHERE NAME LIKE '%' || gv_societe);
  
    gv_step := lv_current_program_unit || '003 : ' || gv_siren;
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit ||
               ' 004 : Recherche du nom de la societe';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    SELECT ffvv.description
      INTO lv_nom_societe
      FROM fnd_flex_value_sets ffvs, fnd_flex_values_vl ffvv
     WHERE ffvs.flex_value_set_id = ffvv.flex_value_set_id
       AND ffvs.flex_value_set_name = cv_jdv_ste
       AND flex_value = gv_societe;
  
    gv_step := lv_current_program_unit || ' 004 : ' || lv_nom_societe;
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit ||
               ' 005 : Détermination des date début et fin extraction en fonction de la societe';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    ln_annee_debut := gn_annee_ref /*PARAM*/
                      -gn_nb_annee /*DKA*/ /*- cn_annee_prec JJA --18/11/2013*/
     ;
    ln_annee_fin   := gn_annee_ref /*PARAM*/ /*- cn_annee_prec --JJA 18/11/2013*/
     ;
  
    /*SELECT add_months(to_date('01/' || to_char(add_months(to_date(first_ledger_period_name,
                                                                  'MM-YY'),
                                                          -1),
                                               'MM') || '/' ||
                              ln_annee_debut,
                              'dd/mm/yyyy'),
                      1) date_debut,
           last_day(to_date('01/' || to_char(add_months(to_date(first_ledger_period_name,
                                                                'MM-YY'),
                                                        -1),
                                             'MM') || '/' || ln_annee_fin,
                            'dd/mm/yyyy')) date_fin,
           substr(first_ledger_period_name, 1, 3) periode_debut
    INTO   gd_date_debut,
           gd_date_fin,
           gv_period
    FROM   gl_ledgers          gl,
           xle_entity_profiles xep
    WHERE  gl.name = xep.name
    AND    xep.legal_entity_id IN
           (SELECT DISTINCT default_legal_context_id
             FROM   hr_operating_units
             WHERE  NAME LIKE '%' || gv_societe);--a revoir YWA*/
  
    --- BEGIN SHA artf07457202 
    BEGIN
    
      select 'Y'
        into lv_secondaire
        from GL_LEDGER_RELATIONSHIPS glr, gl_ledgers gl1, gl_ledgers gl2
       where glr.primary_ledger_id = gl1.ledger_id
         and glr.TARGET_LEDGER_ID = gl2.ledger_id
         and glr.target_ledger_category_code = 'SECONDARY'
         and glr.relationship_type_code = 'JOURNAL'
         and glr.disable_conversion_date is null
         and gl1.SHORT_NAME = gv_societe;
    EXCEPTION
      when no_data_found THEN
        lv_secondaire := 'N';
    END;
  
    if lv_secondaire = 'N' then
      SELECT gp_start.start_date,
             gp_end.end_date,
             SUBSTR(gp_start.PERIOD_NAME, 1, 3) periode_debut
             --SUBSTR(first_ledger_period_name, 1, 3) periode_debut
        INTO gd_date_debut, gd_date_fin, gv_period
        FROM gl_ledgers gl, gl_periods gp_start, gl_periods gp_end
       WHERE gl.SHORT_NAME = gv_societe
         AND gl.period_set_name = gp_start.period_set_name
         AND gp_start.period_name = (SELECT PERIOD_NAME
                                     FROM gl_periods glp1
                                     WHERE glp1.PERIOD_SET_NAME=gp_start.period_set_name
                                     AND START_DATE = (SELECT MIN(START_DATE)
                                                       FROM  gl_periods glp2
                                                       WHERE PERIOD_YEAR = DECODE(gp_start.period_set_name,'GROUPE',ln_annee_debut + 1,ln_annee_debut)
                                                       AND glp2.PERIOD_SET_NAME=glp1.PERIOD_SET_NAME))
         AND gl.period_set_name = gp_end.period_set_name
         AND gp_end.period_name =(SELECT PERIOD_NAME
                                     FROM gl_periods glp1
                                     WHERE glp1.PERIOD_SET_NAME=gp_start.period_set_name
                                     AND START_DATE = (SELECT MAX(START_DATE)
                                                       FROM  gl_periods glp2
                                                       WHERE PERIOD_YEAR = ln_annee_fin
                                                       AND glp2.PERIOD_SET_NAME=glp1.PERIOD_SET_NAME)); 
    ELSE
      SELECT min(gp.start_date) start_date,
             max(gp.end_date) end_date,
             to_char(min(start_date), 'MON') periode_debut
        INTO gd_date_debut, gd_date_fin, gv_period
        FROM gl_periods gp
       WHERE gp.period_set_name = 'Juillet à Juin'
         and gp.period_year = ln_annee_fin;
    
    END IF;
    --- END SHA -artf07457202 
    /*SELECT
    add_months(to_date('01/'||dbc.close_month||'/'||ln_annee_debut,'dd/mm/yyyy'),1) date_debut,
    add_months(to_date('01/'||dbc.close_month||'/'||ln_annee_fin||' 23:59:59','dd/mm/yyyy hh24:mi:ss'),1) -1 date_fin,
    decode(dbc.close_month,'12','JAN','06','JUL') periode_debut
    INTO
    gd_date_debut,
    gd_date_fin,
    gv_period
    FROM     dka_ibdsoc_i00dgic             dii,
    dka_ibdsoc_general_info    digi,
    dka_bdste_comptable            dbc
    WHERE    dii.company_code        = digi.company_code
    AND        dii.company_code        = dbc.company_code
    AND        dii.company_code        = gv_societe
    AND        dbc.effective_date    = ( SELECT MAX(db2.effective_date) FROM dka_bdste_comptable db2 WHERE dbc.company_code = db2.company_code);*/ --YWA
  
    gv_step := lv_current_program_unit || ' 005 : Date début : ' ||
               to_char(gd_date_debut, 'dd/mm/yyyy hh24:mi:ss');
    dka_tools_pkg.put_debug_message(gv_step);
    gv_step := lv_current_program_unit || ' 005 : Date fin     : ' ||
               to_char(gd_date_fin, 'dd/mm/yyyy hh24:mi:ss');
    dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit ||
               ' 006 : Détermination des fichiers à extraire';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    SELECT decode(gn_periode, 1, 'M', 3, 'T', 6, 'S', 12, 'A')
      INTO lv_lettre
      FROM dual;
  
    ln_cpt_period := 0;
    ln_num_ordre  := 0;
  
    FOR l IN c_period(gd_date_debut, gd_date_fin) LOOP
      ln_cpt_period := ln_cpt_period + 1;
    
      --INIT
      IF ln_cpt_period = 1 THEN
        ld_date_debut := l.start_date;
        ln_annee_tmp  := l.period_year;
      ELSIF MOD(ln_cpt_period - 1, gn_periode) = 0 THEN
        ld_date_debut := l.start_date;
      END IF;
    
      --On a atteint à périodicité
      IF MOD(ln_cpt_period, gn_periode) = 0 THEN
        ln_num_ordre := ln_num_ordre + 1;
      
        lr_donnee_fichier.date_debut := ld_date_debut;
        lr_donnee_fichier.date_fin   := l.end_date;
        lr_donnee_fichier.annee      := ln_annee_tmp;
        lr_donnee_fichier.suffixe    := ln_num_ordre || lv_lettre;
      
        --Ajout dans la table
        gt_table_fichier(gt_table_fichier.count + 1) := lr_donnee_fichier;
      
      END IF;
    
      --On arrive à 1 année complete
      IF ln_cpt_period = l.number_per_fiscal_year THEN
        ln_cpt_period := 0;
        ln_num_ordre  := 0;
      
        --Détermination de la date de fin de période annuel
        IF gt_table_fichier.count > 0 THEN
          FOR i IN gt_table_fichier.first .. gt_table_fichier.last LOOP
            IF gt_table_fichier(i).annee = ln_annee_tmp THEN
              gt_table_fichier(i).date_fichier := l.end_date;
            END IF;
          
          END LOOP;
        END IF;
      
      END IF;
    
    END LOOP;
  
    gv_step := lv_current_program_unit ||
               ' 007 : Edition des fichiers à éditer';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    --Edition des fichiers à éditer
    gv_step := 'Edition des fichiers à éditer';
    dka_tools_pkg.put_debug_message(gv_step);
  
    IF gt_table_fichier.count > 0 THEN
      FOR i IN gt_table_fichier.first .. gt_table_fichier.last LOOP
        lv_ligne := gt_table_fichier(i)
                    .annee || ' : ' ||
                     to_char(gt_table_fichier(i).date_debut, 'dd/mm/yyyy') ||
                     ' - ' ||
                     to_char(gt_table_fichier(i).date_fin, 'dd/mm/yyyy') ||
                     ' - ' ||
                     to_char(gt_table_fichier(i).date_fichier, 'dd/mm/yyyy') ||
                     ' - ' || gt_table_fichier(i).suffixe;
        dka_tools_pkg.put_debug_message(lv_ligne);
      END LOOP;
    END IF;
  
    gv_step := lv_current_program_unit ||
               ' 008 : Création du tableau des comptes lettrage tiers';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := 'Tableau des comptes lettrage tiers';
    dka_tools_pkg.put_debug_message(gv_step);
    lv_ligne := NULL;
    FOR l IN c_lettrage_tiers LOOP
    
      IF NOT gt_lettrage_tiers.exists(l.flex_value) THEN
        gt_lettrage_tiers(l.flex_value) := 'O';
        lv_ligne := lv_ligne || chr(10) || l.flex_value;
      END IF;
    
    END LOOP;
  
    dka_tools_pkg.put_debug_message(lv_ligne);
  
    gv_step := lv_current_program_unit ||
               ' 009 : Récupération des paramètres de traduction';
    --dka_tools_pkg.put_debug_message(gv_step);
    FOR c_transco_rec IN c_transco LOOP
      gv_transco_de := gv_transco_de || chr(c_transco_rec.flex_value);
      IF c_transco_rec.enabled_flag = 'Y' OR
         c_transco_rec.description IS NOT NULL THEN
        IF c_transco_rec.description = 'SP' THEN
          gv_transco_a := gv_transco_a || ' ';
        ELSE
          gv_transco_a := gv_transco_a ||
                          nvl(c_transco_rec.description,
                              chr(c_transco_rec.flex_value));
        END IF;
      END IF;
    END LOOP;
    gv_step := lv_current_program_unit || ' 009 : transco_de : ' ||
               gv_transco_de;
    --dka_tools_pkg.put_debug_message(gv_step);
    gv_step := lv_current_program_unit || ' 009 : transco_a    : ' ||
               gv_transco_a;
    --dka_tools_pkg.put_debug_message(gv_step);
  
    --Ajout dans la table de paramétrage
    gv_step := lv_current_program_unit ||
               ' 010 : Ajout dans la table de paramétrage';
    --dka_tools_pkg.put_debug_message(gv_step);
    insert_table_param(1,
                       '01_DONNEES_GENERALES',
                       'SOCIETE',
                       gv_societe,
                       NULL,
                       NULL);
    insert_table_param(2,
                       '01_DONNEES_GENERALES',
                       'NOM SOCIETE',
                       lv_nom_societe,
                       NULL,
                       NULL);
    insert_table_param(3,
                       '01_DONNEES_GENERALES',
                       'SIREN SOCIETE',
                       gv_siren,
                       NULL,
                       NULL);
    insert_table_param(4,
                       '01_DONNEES_GENERALES',
                       'TYPE FICHIER',
                       cv_type_fichier,
                       NULL,
                       NULL);
    insert_table_param(5,
                       '01_DONNEES_GENERALES',
                       'SEPARATEUR CHAMP',
                       cv_separateur,
                       NULL,
                       NULL);
  
    -- Récupération des descriptions des comptes locaux 119000 et 120000
    BEGIN
      SELECT ffvv_loc.description
        INTO gv_desc_cpte_loc_cr
        FROM fnd_flex_value_sets ffvs_loc, fnd_flex_values_vl ffvv_loc
       WHERE ffvv_loc.flex_value_set_id = ffvs_loc.flex_value_set_id
         AND ffvs_loc.flex_value_set_name = cv_jdv_cpt_local
         AND ffvv_loc.flex_value = cv_compte_loc_cr;
    EXCEPTION
      WHEN OTHERS THEN
        gv_desc_cpte_loc_cr := NULL;
    END;
  
    BEGIN
      SELECT ffvv_loc.description
        INTO gv_desc_cpte_loc_dr
        FROM fnd_flex_value_sets ffvs_loc, fnd_flex_values_vl ffvv_loc
       WHERE ffvv_loc.flex_value_set_id = ffvs_loc.flex_value_set_id
         AND ffvs_loc.flex_value_set_name = cv_jdv_cpt_local
         AND ffvv_loc.flex_value = cv_compte_loc_dr;
    EXCEPTION
      WHEN OTHERS THEN
        gv_desc_cpte_loc_cr := NULL;
    END;
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      gv_step := lv_current_program_unit || ' EE2 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END init;

  -----------------------------------------------------------------
  --    Nom                     : PURGE_TABLE_TMP
  --    Description     : procedure de purge des tables de travail
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE purge_table_tmp(pv_errbuf  OUT NOCOPY VARCHAR2,
                            pn_retcode OUT NOCOPY NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'purge_table_tmp';
  
  BEGIN
  
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit ||
               ' 001 : DELETE    < 10 jours - dka_param_extract_fiscal';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    DELETE FROM dka.dka_param_extract_fiscal
     WHERE request_id IN
           (SELECT DISTINCT request_id
              FROM dka_extract_fiscal
             WHERE date_extraction <= SYSDATE - 10);
  
    gv_step := lv_current_program_unit ||
               ' 002 : DELETE < 10 jours - DKA_EXTRACT_FISCAL';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    DELETE FROM dka.dka_extract_fiscal
     WHERE date_extraction <= SYSDATE - 10;
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END purge_table_tmp;

  -----------------------------------------------------------------
  --    Nom                     : INSERT_TABLE_FACT_AP_TMP
  --    Description     : procedure d'insertion dans la table de travail
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE insert_table_fact_ap_tmp(pv_errbuf  OUT NOCOPY VARCHAR2,
                                     pn_retcode OUT NOCOPY NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'insert_table_fact_ap_tmp';
  
  BEGIN
  
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------ FACTURE AP ------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    gv_step := lv_current_program_unit || ' 001 : ANNEE DE DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit ||
               ' 001 : INSERT INTO DKA_EXTRACT_FISCAL -- FACTURE AP';
    dka_tools_pkg.put_log_message(gv_step);
    INSERT INTO dka_extract_fiscal
    --- 26/04/2021 NBO  artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
      SELECT --fnd_global.conc_request_id request_id,
       gn_conc_request_id request_id,
       gv_societe societe,
       gp.period_year annee_comptable, -- RG02
       gjl.period_name periode_comptable, -- RG03                                    ,
       gjh.je_category journal_code, --    RG04
       gjct.user_je_category_name journal_lib, --     RG05
       gjl.subledger_doc_sequence_value ecriture_num, --    RG06 --,gjh.JE_SOURCE    ,gjh.DOC_SEQUENCE_VALUE
       gjh.posted_date ecriture_date, --    RG07
       gcc.segment3 compte_num, --                 RG08
       ffvv_loc.description compte_lib, --            RG09
       decode(substr(ffvv_loc.compiled_value_attributes, 7, 1),
              'Y',
              NVL(pv.segment1, hz.party_number), -- OBE artf2238161
              NULL) compte_aux_num,
       decode(substr(ffvv_loc.compiled_value_attributes, 7, 1),
              'Y',
              NVL(pv.vendor_name, hz.party_name), -- OBE artf2238161
              NULL) compte_aux_lib,
       aia.invoice_num, -- RG12
       aia.invoice_date, -- RG13
       
       nvl(gjl.description, gjh.name) ecriture_lib, --            RG14
       xal.accounted_dr debit, --DEBIT                            RG15
       xal.accounted_cr credit, --CREDIT                            RG16
       nvl2(aia.cancelled_date,
            aia.invoice_id,
            decode(nvl(aia.amount_paid, 0),
                   0,
                   NULL,
                   nvl((SELECT MAX(s_ac.check_id)
                         FROM ap_checks_all           s_ac,
                              ap_invoice_payments_all s_aip
                        WHERE s_aip.invoice_id = aia.invoice_id
                          AND s_ac.check_id = s_aip.check_id
                          AND void_date IS NULL
                          AND s_ac.check_date =
                              (SELECT MAX(check_date)
                                 FROM ap_checks_all           s_ac2,
                                      ap_invoice_payments_all s_aip2
                                WHERE s_aip2.invoice_id = aia.invoice_id
                                  AND s_ac2.check_id = s_aip2.check_id
                                  AND s_ac2.void_date IS NULL)),
                       aia.invoice_id)
                   
                   )) ecriture_let, --RG17
       nvl2(aia.cancelled_date,
            aia.cancelled_date,
            nvl(aia.cancelled_date,
                decode(nvl(aia.amount_paid, 0),
                       0,
                       NULL,
                       nvl((SELECT MAX(s_ac.check_date)
                             FROM ap_checks_all           s_ac,
                                  ap_invoice_payments_all s_aip
                            WHERE s_aip.invoice_id = aia.invoice_id
                              AND s_ac.check_id = s_aip.check_id
                              AND void_date IS NULL),
                           (SELECT MAX(accounting_date)
                              FROM ap_invoice_distributions_all s_aid
                             WHERE s_aid.invoice_id = aia.invoice_id
                               AND s_aid.line_type_lookup_code = 'PREPAY'
                               AND s_aid.reversal_flag IS NULL))))
            
            ) date_let, --RG18
       gjl.effective_date valid_date, -- RG19
       xal.accounted_dr - xal.accounted_cr montant_devise, --    RG20
       gjh.currency_code devise, --                            RG21
       SYSDATE date_extraction,
       xte.entity_code type_donnee,
       aia.invoice_id id_elt,
       gjh.je_header_id je_header_id,
       gjl.je_line_num je_line_num
        FROM gl_je_lines                  gjl,
             gl_je_headers                gjh,
             gl_je_batches                gjb,
             gl_je_sources_tl             gjst,
             gl_je_categories_tl          gjct,
             gl_code_combinations         gcc,
             gl_ledgers                   gl,
             gl_periods                   gp, -- periode comptable
             gl_period_sets               gps, --calandrier comptable
             gl_import_references         gir, --lien avec xla
             gl_lookups                   glk,
             xla_ae_lines                 xal,
             xla_ae_headers               xah,
             xla.xla_transaction_entities xte,
             ap_invoices_all              aia,
             po_vendors                   pv,
             hz_parties                   hz, -- OBE artf2238161
             --CPTE LOCAL
             fnd_flex_value_sets ffvs_loc,
             fnd_flex_values_vl  ffvv_loc
       WHERE gjl.je_header_id = gir.je_header_id
         AND gjl.je_line_num = gir.je_line_num
         AND gjh.je_header_id = gir.je_header_id
         AND gjb.je_batch_id = gir.je_batch_id
         AND gjh.je_from_sla_flag IN ('U', 'Y') -- bug 7163158
         AND glk.lookup_type = 'BATCH_STATUS'
         AND glk.lookup_code = gjb.status
         AND gjh.status = 'P'
         AND gjct.je_category_name = gjh.je_category
         AND gjct.language = 'F'
         AND gjst.je_source_name = gjh.je_source --bug12408239
         AND gjst.language = 'F' --bug12408239
         AND gcc.code_combination_id = gjl.code_combination_id
         AND gjh.ledger_id = gl.ledger_id
         AND gps.period_set_name = gp.period_set_name
         AND gps.zd_edition_name = gp.zd_edition_name
         AND gl.period_set_name = gps.period_set_name
         AND gjh.period_name = gp.period_name
            -----lien fournisseur et facture
         AND gir.gl_sl_link_id = xal.gl_sl_link_id
         AND gir.gl_sl_link_table = xal.gl_sl_link_table
         AND xal.ae_header_id = xah.ae_header_id
         AND xte.application_id = xah.application_id
         AND xal.application_id = xah.application_id
         AND xte.entity_id = xah.entity_id
         AND aia.invoice_id = xte.source_id_int_1
         AND aia.vendor_id = pv.vendor_id(+) -- OBE artf2238161
         AND aia.party_id = hz.party_id -- OBE artf2238161
            --CPTE LOCAL
         AND ffvv_loc.flex_value_set_id = ffvs_loc.flex_value_set_id
         AND ffvs_loc.flex_value_set_name = 'DAOPCCF_LOCAL'
         AND ffvv_loc.flex_value = gcc.segment3
         AND substr(gcc.segment3, 1, 1) IN
             ('1', '2', '3', '4', '5', '6', '7') --JJA 18/11/2013
            --TYPE
         AND gjh.je_source = 'Payables'
         AND xte.entity_code = 'AP_INVOICES'
            --param
         AND gcc.segment1 = gv_societe
         AND gjh.default_effective_date BETWEEN gd_date_debut AND
             gd_date_fin
         AND gl.ledger_id = gn_sob_id;
    --AND    gjh.currency_code = cv_devise;--YWA Revoir
  
    gn_insert := SQL%ROWCOUNT;
    gv_step   := 'Nb de ligne insérée : ' || gn_insert;
    dka_tools_pkg.put_log_message(gv_step);
  
    -- Validation des insertions
    gv_step := lv_current_program_unit ||
               ' 001 : VALIDATION DES INSERTIONS';
    --dka_tools_pkg.put_debug_message(gv_step);
    COMMIT;
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END insert_table_fact_ap_tmp;

  -----------------------------------------------------------------
  --    Nom                     : INSERT_TABLE_RGLT_AP_TMP
  --    Description     : procedure d'insertion dans la table de travail
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE insert_table_rglt_ap_tmp(pv_errbuf  OUT NOCOPY VARCHAR2,
                                     pn_retcode OUT NOCOPY NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'insert_table_rglt_ap_tmp';
  
  BEGIN
  
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------- REGLT AP -------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    gv_step := lv_current_program_unit || ' 002 : REINIT ANNEE DE DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit ||
               ' 002 : INSERT INTO DKA_EXTRACT_FISCAL -- REGLT AP';
    dka_tools_pkg.put_log_message(gv_step);
    INSERT INTO dka_extract_fiscal
    --- 26/04/2021 NBO  artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
      SELECT --fnd_global.conc_request_id request_id,
       gn_conc_request_id request_id,
       gv_societe societe,
       gp.period_year annee_comptable, -- RG02
       gjl.period_name periode_comptable, -- RG03
       gjh.je_category journal_code, --    RG04
       gjct.user_je_category_name journal_lib, --     RG05
       gjl.subledger_doc_sequence_value ecriture_num, --    RG06 --,gjh.JE_SOURCE    ,gjh.DOC_SEQUENCE_VALUE
       gjh.posted_date ecriture_date, --    RG07
       gcc.segment3 compte_num, --                 RG08
       ffvv_loc.description compte_lib, --            RG09
       decode(substr(ffvv_loc.compiled_value_attributes, 7, 1),
              'Y',
              asup.segment1,
              NULL) compte_aux_num, --RG010
       decode(substr(ffvv_loc.compiled_value_attributes, 7, 1),
              'Y',
              asup.vendor_name,
              NULL) compte_aux_lib, --RG11
       aca.check_number piece_ref, --RG12
       aca.check_date piece_date, -- RG13
       nvl(gjl.description, gjh.name) ecriture_lib, --            RG14
       xal.accounted_dr debit, --DEBIT                            RG15
       xal.accounted_cr credit, --CREDIT                            RG16
       aca.check_id ecriture_let, --RG17
       decode(aca.status_lookup_code,
              'VOIDED',
              aca.void_date,
              aca.check_date) date_let, --RG18
       gjl.effective_date valid_date, -- RG19
       xal.accounted_dr - xal.accounted_cr montant_devise, --    RG20
       gjh.currency_code devise, --                            RG21
       SYSDATE date_extraction,
       xte.entity_code type_donnee,
       aca.check_id id_elt,
       gjh.je_header_id je_header_id,
       gjl.je_line_num je_line_num
        FROM gl_je_lines          gjl,
             gl_je_headers        gjh,
             gl_je_batches        gjb,
             gl_je_sources_tl     gjst,
             gl_je_categories_tl  gjct,
             gl_code_combinations gcc,
             gl_ledgers           gl,
             gl_periods           gp, -- periode comptable
             gl_period_sets       gps, --calandrier comptable
             gl_import_references gir, --lien avec xla
             gl_lookups           glk,
             --
             xla_ae_lines             xal,
             xla_ae_headers           xah,
             xla_transaction_entities xte,
             ap_suppliers             asup,
             ap_checks_all            aca,
             --CPTE LOCAL
             fnd_flex_value_sets ffvs_loc,
             fnd_flex_values_vl  ffvv_loc
       WHERE gjl.je_header_id = gir.je_header_id
         AND gjl.je_line_num = gir.je_line_num
         AND gjh.je_header_id = gir.je_header_id
         AND gjb.je_batch_id = gir.je_batch_id
         AND gjh.je_from_sla_flag IN ('U', 'Y') -- bug 7163158
         AND glk.lookup_type = 'BATCH_STATUS'
         AND glk.lookup_code = gjb.status
         AND gjh.status = 'P'
         AND gjct.je_category_name = gjh.je_category
         AND gjct.language = 'F'
         AND gjst.je_source_name = gjh.je_source --bug12408239
         AND gjst.language = 'F' --bug12408239
         AND gcc.code_combination_id = gjl.code_combination_id
         AND gjh.ledger_id = gl.ledger_id
         AND gps.period_set_name = gp.period_set_name
         AND gps.zd_edition_name = gp.zd_edition_name
         AND gl.period_set_name = gps.period_set_name
         AND gjh.period_name = gp.period_name
            -----lien fournisseur et reglement
         AND gir.gl_sl_link_id = xal.gl_sl_link_id
         AND gir.gl_sl_link_table = xal.gl_sl_link_table
         AND xal.ae_header_id = xah.ae_header_id
         AND xte.application_id = xah.application_id
         AND xal.application_id = xah.application_id
         AND xte.entity_id = xah.entity_id
         AND aca.check_id = xte.source_id_int_1
         AND aca.vendor_id = asup.vendor_id
            --CPTE LOCAL
         AND ffvv_loc.flex_value_set_id = ffvs_loc.flex_value_set_id
         AND ffvs_loc.flex_value_set_name = 'DAOPCCF_LOCAL'
         AND ffvv_loc.flex_value = gcc.segment3
         AND substr(gcc.segment3, 1, 1) IN
             ('1', '2', '3', '4', '5', '6', '7') --JJA 18/11/2013
            --TYPE
         AND gjh.je_source = 'Payables'
         AND xte.entity_code = 'AP_PAYMENTS' --xte.entity_code != 'AP_INVOICES' -- a revoir --ywa
            --param
         AND gcc.segment1 = gv_societe
         AND gjh.default_effective_date BETWEEN gd_date_debut AND
             gd_date_fin
         AND gl.ledger_id = gn_sob_id;
    --AND    gjh.currency_code = cv_devise;
  
    gn_insert := SQL%ROWCOUNT;
    gv_step   := 'Nb de ligne insérée : ' || gn_insert;
    dka_tools_pkg.put_log_message(gv_step);
  
    -- Validation des insertions
    gv_step := lv_current_program_unit ||
               ' 002 : VALIDATION DES INSERTIONS';
    --dka_tools_pkg.put_debug_message(gv_step);
    COMMIT;
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END insert_table_rglt_ap_tmp;

  -----------------------------------------------------------------
  --    Nom                     : INSERT_TABLE_FACT_AR_TMP
  --    Description     : procedure d'insertion dans la table de travail
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE insert_table_fact_ar_tmp(pv_errbuf  OUT NOCOPY VARCHAR2,
                                     pn_retcode OUT NOCOPY NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'insert_table_fact_ar_tmp';
  
  BEGIN
  
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------ FACTURE AR ------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    gv_step := lv_current_program_unit || ' 003 : ANNEE DE DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit ||
               ' 003 : INSERT INTO DKA_EXTRACT_FISCAL -- FACTURE AR';
    dka_tools_pkg.put_log_message(gv_step);
    INSERT INTO dka_extract_fiscal
    --- 26/04/2021 NBO  artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
      SELECT --fnd_global.conc_request_id request_id,
       gn_conc_request_id request_id,
       gv_societe societe,
       gp.period_year annee_comptable, -- RG02
       gjl.period_name periode_comptable, -- RG03
       gjh.je_category journal_code, --    RG04
       gjct.user_je_category_name journal_lib, --     RG05
       gjl.subledger_doc_sequence_value ecriture_num, --    RG06 --,gjh.JE_SOURCE    ,gjh.DOC_SEQUENCE_VALUE
       gjh.posted_date ecriture_date, --    RG07
       gcc.segment3 compte_num, --                 RG08
       ffvv_loc.description compte_lib, --            RG09
       decode(substr(ffvv_loc.compiled_value_attributes, 7, 1),
              'Y',
              ac.customer_number,
              NULL) compte_aux_num, --RG010
       decode(substr(ffvv_loc.compiled_value_attributes, 7, 1),
              'Y',
              ac.customer_name,
              NULL) compte_aux_lib, --RG11
       rcta.trx_number piece_ref,
       rcta.trx_date piece_date,
       nvl(gjl.description, gjh.name) ecriture_lib, --            RG14
       xal.accounted_dr debit, --DEBIT                            RG15
       xal.accounted_cr credit, --CREDIT                            RG16
       decode(apsa.status,
              'OP',
              NULL,
              'CL',
              (SELECT araa.cash_receipt_id
                 FROM ar_receivable_applications_all araa
                WHERE receivable_application_id =
                      (SELECT MAX(receivable_application_id)
                         FROM ar_receivable_applications_all araa
                        WHERE araa.applied_customer_trx_id =
                              rcta.customer_trx_id
                          AND display = 'Y'
                          AND status = 'APP'
                          AND amount_applied != 0))) ecriture_let,
       decode(apsa.status,
              'OP',
              NULL,
              'CL',
              (SELECT araa.apply_date
                 FROM ar_receivable_applications_all araa
                WHERE receivable_application_id =
                      (SELECT MAX(receivable_application_id)
                         FROM ar_receivable_applications_all araa
                        WHERE araa.applied_customer_trx_id =
                              rcta.customer_trx_id
                          AND display = 'Y'
                          AND status = 'APP'
                          AND amount_applied != 0))) date_let,
       gjl.effective_date valid_date, -- RG19
       xal.accounted_dr - xal.accounted_cr montant_devise, --    RG20
       gjh.currency_code devise, --                            RG21
       SYSDATE date_extraction,
       xte.entity_code type_donnee,
       rcta.customer_trx_id id_elt,
       gjh.je_header_id je_header_id,
       gjl.je_line_num je_line_num
        FROM gl_je_lines          gjl,
             gl_je_headers        gjh,
             gl_je_batches        gjb,
             gl_je_sources_tl     gjst,
             gl_je_categories_tl  gjct,
             gl_code_combinations gcc,
             gl_ledgers           gl,
             gl_periods           gp, -- periode comptable
             gl_period_sets       gps, --calandrier comptable
             gl_import_references gir, --lien avec xla
             gl_lookups           glk,
             --
             xla_ae_lines             xal,
             xla_ae_headers           xah,
             xla_transaction_entities xte,
             ra_customer_trx_all      rcta,
             ar_payment_schedules_all apsa,
             ar_customers             ac,
             --CPTE LOCAL
             fnd_flex_value_sets ffvs_loc,
             fnd_flex_values_vl  ffvv_loc
       WHERE gjl.je_header_id = gir.je_header_id
         AND gjl.je_line_num = gir.je_line_num
         AND gjh.je_header_id = gir.je_header_id
         AND gjb.je_batch_id = gir.je_batch_id
         AND gjh.je_from_sla_flag IN ('U', 'Y') -- bug 7163158
         AND glk.lookup_type = 'BATCH_STATUS'
         AND glk.lookup_code = gjb.status
         AND gjh.status = 'P'
         AND gjct.je_category_name = gjh.je_category
         AND gjct.language = 'F'
         AND gjst.je_source_name = gjh.je_source --bug12408239
         AND gjst.language = 'F' --bug12408239
         AND gcc.code_combination_id = gjl.code_combination_id
         AND gjh.ledger_id = gl.ledger_id
         AND gps.period_set_name = gp.period_set_name
         AND gps.zd_edition_name = gp.zd_edition_name
         AND gl.period_set_name = gps.period_set_name
         AND gjh.period_name = gp.period_name
            -----lien client et factures
         AND gir.gl_sl_link_id = xal.gl_sl_link_id
         AND gir.gl_sl_link_table = xal.gl_sl_link_table
         AND xal.ae_header_id = xah.ae_header_id
         AND xte.application_id = xah.application_id
         AND xal.application_id = xah.application_id
         AND xte.entity_id = xah.entity_id
         AND rcta.customer_trx_id(+) = xte.source_id_int_1
            --APSA
         AND apsa.customer_id = rcta.bill_to_customer_id
         AND apsa.customer_trx_id = rcta.customer_trx_id
         AND apsa.org_id = rcta.org_id
         AND apsa.due_date =
             (SELECT MAX(due_date)
                FROM ar_payment_schedules_all apsa1
               WHERE apsa1.customer_trx_id = rcta.customer_trx_id)
            --RC
         AND ac.customer_id = rcta.bill_to_customer_id
            
            --CPTE LOCAL
         AND ffvv_loc.flex_value_set_id = ffvs_loc.flex_value_set_id
         AND ffvs_loc.flex_value_set_name = 'DAOPCCF_LOCAL'
         AND ffvv_loc.flex_value = gcc.segment3
         AND substr(gcc.segment3, 1, 1) IN
             ('1', '2', '3', '4', '5', '6', '7') --JJA 18/11/2013
            --TYPE
         AND gjh.je_source = 'Receivables'
         AND xte.entity_code = 'TRANSACTIONS' -- JWYC INC0289351 'RECEIPTS'
            --param
         AND gcc.segment1 = gv_societe
         AND gjh.default_effective_date BETWEEN gd_date_debut AND
             gd_date_fin
         AND gl.ledger_id = gn_sob_id;
    --AND    gjh.currency_code = cv_devise;
  
    gn_insert := SQL%ROWCOUNT;
    gv_step   := 'Nb de ligne insérée : ' || gn_insert;
    dka_tools_pkg.put_log_message(gv_step);
  
    -- Validation des insertions
    gv_step := lv_current_program_unit ||
               ' 003 : VALIDATION DES INSERTIONS';
    --dka_tools_pkg.put_debug_message(gv_step);
    COMMIT;
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END insert_table_fact_ar_tmp;

  -----------------------------------------------------------------
  --    Nom                     : INSERT_TABLE_RGLT_AR_TMP
  --    Description     : procedure d'insertion dans la table de travail
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE insert_table_rglt_ar_tmp(pv_errbuf  OUT NOCOPY VARCHAR2,
                                     pn_retcode OUT NOCOPY NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'insert_table_rglt_ar_tmp';
  
  BEGIN
  
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------ REGLMT    AR ------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    gv_step := lv_current_program_unit || ' 004 : ANNEE DE DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit ||
               ' 004 : INSERT INTO DKA_EXTRACT_FISCAL -- REGLT AR';
    dka_tools_pkg.put_log_message(gv_step);
    INSERT INTO dka_extract_fiscal
    --- 26/04/2021 NBO  artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
      SELECT --fnd_global.conc_request_id request_id,
       gn_conc_request_id request_id,
       gv_societe societe,
       gp.period_year annee_comptable, -- RG02
       gjl.period_name periode_comptable, -- RG03
       gjh.je_category journal_code, --    RG04
       gjct.user_je_category_name journal_lib, --     RG05
       gjl.subledger_doc_sequence_value ecriture_num, --    RG06 --,gjh.JE_SOURCE    ,gjh.DOC_SEQUENCE_VALUE
       gjh.posted_date ecriture_date, --    RG07
       gcc.segment3 compte_num, --                 RG08
       ffvv_loc.description compte_lib, --            RG09
       decode(substr(ffvv_loc.compiled_value_attributes, 7, 1),
              'Y',
              (SELECT ac.customer_number
                 FROM ar_customers ac
                WHERE acra.pay_from_customer = ac.customer_id),
              NULL) compte_aux_num, --RG010
       decode(substr(ffvv_loc.compiled_value_attributes, 7, 1),
              'Y',
              (SELECT ac.customer_name
                 FROM ar_customers ac
                WHERE acra.pay_from_customer = ac.customer_id),
              NULL) compte_aux_lib, --RG11
       acra.receipt_number piece_ref,
       acra.receipt_date piece_date,
       nvl(gjl.description, gjh.name) ecriture_lib, --            RG14
       xal.accounted_dr debit, --DEBIT                            RG15
       xal.accounted_cr credit, --CREDIT                            RG16
       decode(acra.status,
              'NSF',
              acra.cash_receipt_id,
              'REV',
              acra.cash_receipt_id,
              'STOP',
              acra.cash_receipt_id,
              'APP',
              acra.cash_receipt_id,
              'UNID',
              NULL,
              'UNAPP',
              NULL,
              NULL) ecriture_let,
       decode(acra.status,
              'NSF',
              acra.reversal_date,
              'REV',
              acra.reversal_date,
              'STOP',
              acra.reversal_date,
              'APP', /*acra.receipt_date*/
              (SELECT MAX(araa.apply_date)
                 FROM ar_receivable_applications_all araa
                WHERE araa.cash_receipt_id = acra.cash_receipt_id
                  AND display = 'Y'
                  AND status = 'APP'
                  AND amount_applied != 0),
              'UNID',
              NULL,
              'UNAPP',
              NULL,
              NULL) date_let,
       gjl.effective_date valid_date, -- RG19
       xal.accounted_dr - xal.accounted_cr montant_devise, --    RG20
       gjh.currency_code devise, --                            RG21
       SYSDATE date_extraction,
       xte.entity_code type_donnee,
       acra.cash_receipt_id id_elt,
       gjh.je_header_id je_header_id,
       gjl.je_line_num je_line_num
        FROM gl_je_lines          gjl,
             gl_je_headers        gjh,
             gl_je_batches        gjb,
             gl_je_sources_tl     gjst,
             gl_je_categories_tl  gjct,
             gl_code_combinations gcc,
             gl_ledgers           gl,
             gl_periods           gp, -- periode comptable
             gl_period_sets       gps, --calandrier comptable
             gl_import_references gir, --lien avec xla
             gl_lookups           glk,
             --
             xla_ae_lines             xal,
             xla_ae_headers           xah,
             xla_transaction_entities xte,
             --ra_customer_trx_all            rcta,
             ar_cash_receipts_all acra,
             --CPTE LOCAL
             fnd_flex_value_sets ffvs_loc,
             fnd_flex_values_vl  ffvv_loc
       WHERE gjl.je_header_id = gir.je_header_id
         AND gjl.je_line_num = gir.je_line_num
         AND gjh.je_header_id = gir.je_header_id
         AND gjb.je_batch_id = gir.je_batch_id
         AND gjh.je_from_sla_flag IN ('U', 'Y') -- bug 7163158
         AND glk.lookup_type = 'BATCH_STATUS'
         AND glk.lookup_code = gjb.status
         AND gjh.status = 'P'
         AND gjct.je_category_name = gjh.je_category
         AND gjct.language = 'F'
         AND gjst.je_source_name = gjh.je_source --bug12408239
         AND gjst.language = 'F' --bug12408239
         AND gcc.code_combination_id = gjl.code_combination_id
         AND gjh.ledger_id = gl.ledger_id
         AND gps.period_set_name = gp.period_set_name
         AND gps.zd_edition_name = gp.zd_edition_name
         AND gl.period_set_name = gps.period_set_name
         AND gjh.period_name = gp.period_name
            -----lien reglement
         AND gir.gl_sl_link_id = xal.gl_sl_link_id
         AND gir.gl_sl_link_table = xal.gl_sl_link_table
         AND xal.ae_header_id = xah.ae_header_id
         AND xte.application_id = xah.application_id
         AND xal.application_id = xah.application_id
         AND xte.entity_id = xah.entity_id
         AND acra.cash_receipt_id(+) = xte.source_id_int_1
            
            --CPTE LOCAL
         AND ffvv_loc.flex_value_set_id = ffvs_loc.flex_value_set_id
         AND ffvs_loc.flex_value_set_name = 'DAOPCCF_LOCAL'
         AND ffvv_loc.flex_value = gcc.segment3
         AND substr(gcc.segment3, 1, 1) IN
             ('1', '2', '3', '4', '5', '6', '7') --JJA 18/11/2013
            --TYPE
         AND gjh.je_source = 'Receivables'
         AND xte.entity_code = 'RECEIPTS' -- JWYC INC0289351 'TRANSACTIONS'
            --param
         AND gcc.segment1 = gv_societe
         AND gjh.default_effective_date BETWEEN gd_date_debut AND
             gd_date_fin
         AND gl.ledger_id = gn_sob_id;
    --AND    gjh.currency_code = cv_devise;
  
    gn_insert := SQL%ROWCOUNT;
    gv_step   := 'Nb de ligne insérée : ' || gn_insert;
    dka_tools_pkg.put_log_message(gv_step);
  
    -- Validation des insertions
    gv_step := lv_current_program_unit ||
               ' 004 : VALIDATION DES INSERTIONS';
    --dka_tools_pkg.put_debug_message(gv_step);
    COMMIT;
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END insert_table_rglt_ar_tmp;

  /* -----------------------------------------------------------------
  --    Nom                     : INSERT_TABLE_MISC_AR_TMP
  --    Description     : procedure d'insertion dans la table de travail
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE insert_table_misc_ar_tmp(pv_errbuf                OUT NOCOPY VARCHAR2,
                           pn_retcode             OUT NOCOPY NUMBER) IS
  
  lv_current_program_unit    VARCHAR2(30) := 'insert_table_misc_ar_tmp';
  
  BEGIN
  
  gv_step    := lv_current_program_unit||' 000 : DEBUT';
  --dka_tools_pkg.put_debug_message(gv_step);
  
  ------------------------------------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------------------------------------
  ------------------------------------------------------ DIVERS    AR ------------------------------------------------------
  ------------------------------------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------------------------------------
  gv_step    := lv_current_program_unit||' 004 : ANNEE DE DEBUT';
  --dka_tools_pkg.put_debug_message(gv_step);
  
  gv_step    := lv_current_program_unit||' 004 : INSERT INTO DKA_EXTRACT_FISCAL -- DIVERS AR';
  dka_tools_pkg.put_log_message(gv_step);
  INSERT INTO DKA_EXTRACT_FISCAL
  SELECT
  FND_GLOBAL.CONC_REQUEST_ID                        REQUEST_ID,
  gv_societe                                                        SOCIETE,
  gp.period_year                                                ANNEE_COMPTABLE,
  gp.period_name                                                PERIODE_COMPTABLE,
  SYSDATE                                                             DATE_EXTRACTION,
  gjc.je_category_name                                    JOURNAL_CODE,
  gjc.user_je_category_name                         JOURNAL_LIB,
  gjl.subledger_doc_sequence_value            ECRITURE_NUM,
  gjh.posted_date                                             ECRITURE_DATE,
  gcc.segment3                                                    COMPTE_NUM,
  ffvv_loc.DESCRIPTION                                    COMPTE_LIB,
  decode(substr(ffvv_loc.COMPILED_VALUE_ATTRIBUTES,-1),'Y',( SELECT rc.customer_number
                                                                                      FROM ra_customers rc
                                                                                      WHERE acra.pay_from_customer = rc.customer_id),NULL)     COMPTE_AUX_NUM,
  decode(substr(ffvv_loc.COMPILED_VALUE_ATTRIBUTES,-1),'Y',( SELECT rc.customer_name
                                                                                      FROM ra_customers rc
                                                                                      WHERE acra.pay_from_customer= rc.customer_id),NULL)     COMPTE_AUX_LIB,
  acra.receipt_number                                     PIECE_REF,
  acra.receipt_date                                         PIECE_DATE,
  nvl(gjl.description,gjh.name)                 ECRITURE_LIB,
  gjl.accounted_dr                                            DEBIT,
  gjl.accounted_cr                                            CREDIT,
  decode(acra.status,
  'NSF',gjl.reference_2,
  'REV',gjl.reference_2,
  'STOP',gjl.reference_2,
  'APP',gjl.reference_2,
  'UNID',NULL,
  'UNAPP',NULL,
  NULL)                                                    ECRITURE_LET,
  decode(acra.status,
  'NSF',acra.reversal_date,
  'REV',acra.reversal_date,
  'STOP',acra.reversal_date,
  'APP',/*acra.receipt_date*/
  /*                                 (SELECT MAX(araa.apply_date)
  FROM
  ar_receivable_applications_all araa
  WHERE
  araa.CASH_RECEIPT_ID = acra.CASH_RECEIPT_ID
  AND display = 'Y'
  AND status = 'APP'
  AND amount_applied != 0),
  'UNID',NULL,
  'UNAPP',NULL,
  NULL)                                                    DATE_LET,
  gjl.effective_date                                        VALID_DATE,
  NULL                                                                    MONTANT_DEVISE,
  NULL                                                                    DEVISE,
  'AR MISC CASH RECEIPT'                                         TYPE_DONNEE,
  acra.cash_receipt_id                                    ID_ELT,
  gjh.je_header_id                                            JE_HEADER_ID,
  gjl.je_line_num                                             JE_LINE_NUM
  FROM
  gl_je_headers gjh,
  gl_je_lines     gjl,
  gl_je_categories_vl gjc,
  gl_code_combinations gcc,
  gl_je_sources_vl gjs,
  --AR_REGL
  ar_cash_receipts_all acra,
  ar_receipt_methods arm,
  ar_receipt_classes arc,
  --PERIOD
  gl_sets_of_books gsob,
  gl_periods gp,
  --CPTE LOCAL
  fnd_flex_value_sets ffvs_loc,
  fnd_flex_values_vl ffvv_loc
  WHERE
  --GJL
  gjh.je_header_id = gjl.je_header_id
  --GJC
  AND gjh.je_category = gjc.je_category_name
  --GJS
  AND gjh.je_source = gjs.je_source_name
  --GCC
  AND gcc.code_combination_id = gjl.code_combination_id
  --ACRA
  AND acra.cash_receipt_id = decode(length(translate(gjl.reference_2,'a1234567890','a')),NULL,gjl.reference_2,NULL)
  --ARM
  AND acra.receipt_method_id = arm.receipt_method_id
  --ARC
  AND arm.receipt_class_id = arc.receipt_class_id
  --PERIOD
  AND gsob.set_of_books_id = gjh.set_of_books_id
  AND gsob.period_set_name = gp.period_set_name
  AND gjh.period_name = gp.period_name
  --CPTE LOCAL
  AND ffvv_loc.FLEX_VALUE_SET_ID = ffvs_loc.flex_value_set_id
  AND ffvs_loc.flex_value_set_name = cv_jdv_cpt_local
  AND ffvv_loc.FLEX_VALUE = gcc.segment3
  AND SUBSTR(gcc.segment3,1,1) in ('1','2','3','4','5','6','7') --JJA 18/11/2013
  --TYPE
  AND gjh.je_source = 'AR Translator'
  AND gjl.reference_8 = 'MISC'
  --
  AND gcc.segment1 = gv_societe
  AND gjl.effective_date BETWEEN gd_date_debut AND gd_date_fin
  AND gjl.status = 'P'
  AND gjh.set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID')
  AND gjh.currency_code = cv_devise
  ;
  
  gn_insert := SQL%ROWCOUNT;
  gv_step    := 'Nb de ligne insérée : '||gn_insert;
  dka_tools_pkg.put_log_message(gv_step);
  
  -- Validation des insertions
  gv_step    := lv_current_program_unit||' 004 : VALIDATION DES INSERTIONS';
  --dka_tools_pkg.put_debug_message(gv_step);
  COMMIT;
  
  gv_step    := lv_current_program_unit||' 999 : FIN';
  --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
  WHEN OTHERS THEN
  ROLLBACK;
  gv_step    := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
  dka_tools_pkg.put_log_message(gv_step);
  pv_errbuf    := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
  dka_tools_pkg.put_log_message(pv_errbuf);
  pn_retcode := 2;
  END insert_table_misc_ar_tmp;*/

  -----------------------------------------------------------------
  --    Nom                     : INSERT_TABLE_ADJU_AR_TMP
  --    Description     : procedure d'insertion dans la table de travail
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE insert_table_adju_ar_tmp(pv_errbuf  OUT NOCOPY VARCHAR2,
                                     pn_retcode OUT NOCOPY NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'insert_table_adju_ar_tmp';
  
  BEGIN
  
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------ ADJUST    AR ------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    gv_step := lv_current_program_unit || ' 005 : ANNEE DE DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit ||
               ' 005 : INSERT INTO DKA_EXTRACT_FISCAL -- ADJUST AR';
    dka_tools_pkg.put_log_message(gv_step);
    INSERT INTO dka_extract_fiscal
    --- 26/04/2021 NBO  artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
      SELECT --fnd_global.conc_request_id request_id,
       gn_conc_request_id request_id,
       gv_societe societe,
       gp.period_year annee_comptable, -- RG02
       gjl.period_name periode_comptable, -- RG03
       gjh.je_category journal_code, --    RG04
       gjct.user_je_category_name journal_lib, --     RG05
       gjl.subledger_doc_sequence_value ecriture_num, --    RG06 --,gjh.JE_SOURCE    ,gjh.DOC_SEQUENCE_VALUE
       gjh.posted_date ecriture_date, --    RG07
       gcc.segment3 compte_num, --                 RG08
       ffvv_loc.description compte_lib, --            RG09
       decode(substr(ffvv_loc.compiled_value_attributes, 7, 1),
              'Y',
              ac.customer_number,
              NULL) compte_aux_num, --RG010
       decode(substr(ffvv_loc.compiled_value_attributes, 7, 1),
              'Y',
              ac.customer_name,
              NULL) compte_aux_lib, --RG11
       aaa.adjustment_number piece_ref,
       aaa.apply_date piece_date,
       nvl(gjl.description, gjh.name) ecriture_lib, --            RG14
       xal.accounted_dr debit, --DEBIT                            RG15
       xal.accounted_cr credit, --CREDIT                            RG16
       aaa.associated_cash_receipt_id ecriture_let,
       aaa.apply_date date_let,
       gjl.effective_date valid_date, -- RG19
       xal.accounted_dr - xal.accounted_cr montant_devise, --    RG20
       gjh.currency_code devise, --                            RG21
       SYSDATE date_extraction,
       xte.entity_code type_donnee,
       aaa.adjustment_id id_elt,
       gjh.je_header_id je_header_id,
       gjl.je_line_num je_line_num
        FROM gl_je_lines          gjl,
             gl_je_headers        gjh,
             gl_je_batches        gjb,
             gl_je_sources_tl     gjst,
             gl_je_categories_tl  gjct,
             gl_code_combinations gcc,
             gl_ledgers           gl,
             gl_periods           gp, -- periode comptable
             gl_period_sets       gps, --calandrier comptable
             gl_import_references gir, --lien avec xla
             gl_lookups           glk,
             --
             xla_ae_lines             xal,
             xla_ae_headers           xah,
             xla_transaction_entities xte,
             ar_adjustments_all       aaa,
             ra_customer_trx_all      rcta,
             ar_customers             ac,
             --CPTE LOCAL
             fnd_flex_value_sets ffvs_loc,
             fnd_flex_values_vl  ffvv_loc
       WHERE gjl.je_header_id = gir.je_header_id
         AND gjl.je_line_num = gir.je_line_num
         AND gjh.je_header_id = gir.je_header_id
         AND gjb.je_batch_id = gir.je_batch_id
         AND gjh.je_from_sla_flag IN ('U', 'Y') -- bug 7163158
         AND glk.lookup_type = 'BATCH_STATUS'
         AND glk.lookup_code = gjb.status
         AND gjh.status = 'P'
         AND gjct.je_category_name = gjh.je_category
         AND gjct.language = 'F'
         AND gjst.je_source_name = gjh.je_source --bug12408239
         AND gjst.language = 'F' --bug12408239
         AND gcc.code_combination_id = gjl.code_combination_id
         AND gjh.ledger_id = gl.ledger_id
         AND gps.period_set_name = gp.period_set_name
         AND gps.zd_edition_name = gp.zd_edition_name
         AND gl.period_set_name = gps.period_set_name
         AND gjh.period_name = gp.period_name
            -----lien adjustment
         AND gir.gl_sl_link_id = xal.gl_sl_link_id
         AND gir.gl_sl_link_table = xal.gl_sl_link_table
         AND xal.ae_header_id = xah.ae_header_id
         AND xte.application_id = xah.application_id
         AND xal.application_id = xah.application_id
         AND xte.entity_id = xah.entity_id
         AND aaa.adjustment_id(+) = xte.source_id_int_1
         AND aaa.customer_trx_id = rcta.customer_trx_id
         AND aaa.org_id = rcta.org_id
            --AC
         AND ac.customer_id = rcta.bill_to_customer_id
            
            --CPTE LOCAL
         AND ffvv_loc.flex_value_set_id = ffvs_loc.flex_value_set_id
         AND ffvs_loc.flex_value_set_name = 'DAOPCCF_LOCAL'
         AND ffvv_loc.flex_value = gcc.segment3
         AND substr(gcc.segment3, 1, 1) IN
             ('1', '2', '3', '4', '5', '6', '7') --JJA 18/11/2013
            
            --TYPE
         AND gjh.je_source = 'Receivables'
         AND xte.entity_code = 'ADJUSTMENTS'
            --param
         AND gcc.segment1 = gv_societe
         AND gjh.default_effective_date BETWEEN gd_date_debut AND
             gd_date_fin
         AND gl.ledger_id = gn_sob_id;
    --AND    gjh.currency_code = cv_devise; tous les devis
  
    gn_insert := SQL%ROWCOUNT;
    gv_step   := 'Nb de ligne insérée : ' || gn_insert;
    dka_tools_pkg.put_log_message(gv_step);
  
    -- Validation des insertions
    gv_step := lv_current_program_unit ||
               ' 005 : VALIDATION DES INSERTIONS';
    --dka_tools_pkg.put_debug_message(gv_step);
    COMMIT;
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END insert_table_adju_ar_tmp;

  -----------------------------------------------------------------
  --    Nom                     : INSERT_TABLE_AUTR_GL_TMP
  --    Description     : procedure d'insertion dans la table de travail
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE insert_table_autr_gl_tmp(pv_errbuf  OUT NOCOPY VARCHAR2,
                                     pn_retcode OUT NOCOPY NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'insert_table_autr_gl_tmp';
  
  BEGIN
  
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------ AUTRES    GL ------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    gv_step := lv_current_program_unit || ' 006 : ANNEE DE DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit ||
               ' 006 : INSERT INTO DKA_EXTRACT_FISCAL -- AUTRES GL';
    dka_tools_pkg.put_log_message(gv_step);
    INSERT INTO dka_extract_fiscal
    --- 26/04/2021 NBO  artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
      SELECT --fnd_global.conc_request_id request_id,
       gn_conc_request_id request_id,
       gv_societe societe,
       gp.period_year annee_comptable, -- RG02
       gjl.period_name periode_comptable, -- RG03
       gjh.je_category journal_code, --    RG04
       gjct.user_je_category_name journal_lib, --     RG05
       gjh.doc_sequence_value ecriture_num, --RG6
       gjh.posted_date ecriture_date, --    RG07
       gcc.segment3 compte_num, --                 RG08
       ffvv_loc.description compte_lib, --            RG09
       NULL compte_aux_num,
       NULL compte_aux_lib,
       gjl.JE_HEADER_ID piece_ref, ------- RG12 -- ARA EDB283 - Modification fichier des FEC
       gjh.DEFAULT_EFFECTIVE_DATE piece_date, ------- RG13 ARA EDB283 - Modification fichier des FEC
       nvl(gjl.description, gjh.name) ecriture_lib, --            RG14
       gjl.accounted_dr debit, --DEBIT                            RG15   -- RBE artf2213960
       gjl.accounted_cr credit, --CREDIT                            RG16 -- RBE artf2213960
       gjlr.jgzz_recon_id ecriture_let,
       gjlr.jgzz_recon_date date_let,
       gjl.effective_date valid_date, -- RG19
       NVL(gjl.accounted_dr, 0) - NVL(gjl.accounted_cr, 0) montant_devise, --    RG20   --RBE artf2213960
       gjh.currency_code devise, --                            RG21
       SYSDATE date_extraction,
       --xte.entity_code type_donnee,  --RBE artf2213960
       'GL AUTRES' type_donnee, --RBE artf2213960
       gjlr.jgzz_recon_id id_elt,
       gjh.je_header_id je_header_id,
       gjl.je_line_num je_line_num
        FROM gl_je_lines          gjl,
             gl_je_headers        gjh,
             gl_je_batches        gjb,
             gl_je_sources_tl     gjst,
             gl_je_categories_tl  gjct,
             gl_je_lines_recon    gjlr,
             gl_code_combinations gcc,
             gl_ledgers           gl,
             gl_periods           gp, -- periode comptable
             gl_period_sets       gps, --calandrier comptable
             --gl_import_references gir, --lien avec xla   --RBE artf2213960
             gl_lookups glk,
             --
             --xla_ae_lines             xal, --RBE artf2213960
             --xla_ae_headers           xah, --RBE artf2213960
             --xla_transaction_entities xte, --RBE artf2213960
             --CPTE LOCAL
             fnd_flex_value_sets ffvs_loc,
             fnd_flex_values_vl  ffvv_loc
       WHERE 1 = 1 --gjl.je_header_id = gir.je_header_id -- RBE artf2213960
            --AND    gjl.je_line_num = gir.je_line_num       -- RBE artf2213960
            --AND    gjh.je_header_id = gir.je_header_id     -- RBE artf2213960
            --AND    gjb.je_batch_id = gir.je_batch_id       -- RBE artf2213960
         AND gjh.je_header_id = gjl.je_header_id -- RBE artf2213960
         AND gjb.je_batch_id = gjh.je_batch_id -- RBE artf2213960
            --AND    gjh.je_from_sla_flag IN ('U', 'Y') -- bug 7163158 --JJA artf2220598
         AND glk.lookup_type = 'BATCH_STATUS'
         AND glk.lookup_code = gjb.status
         AND gjh.status = 'P'
         AND gjlr.je_header_id(+) = gjl.je_header_id -- Added for French audit file ER
         AND gjlr.je_line_num(+) = gjl.je_line_num
         AND gjct.je_category_name = gjh.je_category
         AND gjct.language = 'F'
         AND gjst.je_source_name = gjh.je_source --bug12408239
         AND gjst.language = 'F' --bug12408239
         AND gcc.code_combination_id = gjl.code_combination_id
         AND gjh.ledger_id = gl.ledger_id
         AND gps.period_set_name = gp.period_set_name
         AND gps.zd_edition_name = gp.zd_edition_name
         AND gl.period_set_name = gps.period_set_name
         AND gjh.period_name = gp.period_name
            -----
            --RBE artf2213960
            --AND    gir.gl_sl_link_id = xal.gl_sl_link_id
            --AND    gir.gl_sl_link_table = xal.gl_sl_link_table
            --AND    xal.ae_header_id = xah.ae_header_id
            --AND    xte.application_id = xah.application_id
            --AND    xal.application_id =xah.application_id
            --AND    xte.entity_id = xah.entity_id
            
            --CPTE LOCAL
         AND ffvv_loc.flex_value_set_id = ffvs_loc.flex_value_set_id
         AND ffvs_loc.flex_value_set_name = cv_jdv_cpt_local --'DAOPCCF_LOCAL' --RBE artf2213960
         AND ffvv_loc.flex_value = gcc.segment3
            -- JWYC INC0289351 / TASK0133265 retour version initiale
         AND substr(gcc.segment3, 1, 1) IN
             ('1', '2', '3', '4', '5', '6', '7')
            --TYPE
         AND gjh.je_source NOT IN ('Receivables', 'Payables')
            --param
         AND gcc.segment1 = gv_societe -- JWYC INC0289351 / TASK0133265 retour version initiale
         AND gjh.default_effective_date BETWEEN gd_date_debut AND
             gd_date_fin
         AND gl.ledger_id = gn_sob_id
      -- JWYC INC0289351 / TASK0133265 retour version initiale
      /*and exists (select 1 from gl.gl_code_combinations gcc1 
      where gcc1.segment1 = gv_societe and substr(gcc1.segment3 , 1,1) in ('1', '2', '3', '4', '5', '6', '7')
      and   gcc1.code_combination_id = gjl.code_combination_id ) */
      ;
    --AND    gjh.currency_code = cv_devise;
  
    gn_insert := SQL%ROWCOUNT;
    gv_step   := 'Nb de ligne insérée : ' || gn_insert;
    dka_tools_pkg.put_log_message(gv_step);
  
    -- Validation des insertions
    gv_step := lv_current_program_unit ||
               ' 006 : VALIDATION DES INSERTIONS';
    --dka_tools_pkg.put_debug_message(gv_step);
    COMMIT;
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END insert_table_autr_gl_tmp;

  -----------------------------------------------------------------
  --    Nom                     : INSERT_TABLE_REPORT_TMP
  --    Description     : procedure d'insertion dans la table de travail
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE insert_table_report_tmp(pv_errbuf  OUT NOCOPY VARCHAR2,
                                    pn_retcode OUT NOCOPY NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'insert_table_report_tmp';
    ln_annee_debut          PLS_INTEGER;
  
  BEGIN
  
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------ REPORT    GL ------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    gv_step := lv_current_program_unit || ' 007 : ANNEE DE DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
    ln_annee_debut := gn_annee_ref /*PARAM*/
                      -gn_nb_annee /*DKA*/
     ;
  
    WHILE ln_annee_debut < gn_annee_ref LOOP
    
      gv_step := lv_current_program_unit ||
                 ' 007 : INSERT INTO DKA_EXTRACT_FISCAL -- REPORT A NOUVEAU : année :' ||
                 ln_annee_debut;
      dka_tools_pkg.put_log_message(gv_step);
    
      -- Si Société dont exercice comptable va du 01/01 au 31/12, extraction des soldes au 01/01
      IF gv_period = 'JAN' THEN
        INSERT INTO dka_extract_fiscal
        --- 26/04/2021 NBO  artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
          SELECT --fnd_global.conc_request_id request_id,
           gn_conc_request_id request_id,
           gv_societe societe,
           v.period_year annee_comptable,
           v.period_name periode_comptable,
           '0' journal_code,
           'Journal ouverture' journal_lib,
           substr(to_char(v.period_year), -2) || '0000001' ecriture_num,
           to_date('01/' || lpad(v.period_num, 2, '0') || '/' ||
                   v.period_year,
                   'dd/mm/yyyy') ecriture_date,
           v.segment3 compte_num,
           ffvv_loc.description compte_lib,
           NULL compte_aux_num,
           NULL compte_aux_lib,
           'Report à nouveau' piece_ref,
           to_date('01/' || lpad(v.period_num, 2, '0') || '/' ||
                   v.period_year,
                   'dd/mm/yyyy') piece_date,
           'Report à nouveau compte ' || v.segment3 ecriture_lib,
           CASE
             WHEN v.somme_period_net_dr > v.somme_period_net_cr THEN
              (v.somme_period_net_dr - v.somme_period_net_cr)
             ELSE
              0
           END debit,
           CASE
             WHEN v.somme_period_net_cr > v.somme_period_net_dr THEN
              (v.somme_period_net_cr - v.somme_period_net_dr)
             ELSE
              0
           END credit,
           NULL ecriture_let,
           NULL date_let,
           to_date('01/' || lpad(v.period_num, 2, '0') || '/' ||
                   v.period_year,
                   'dd/mm/yyyy') valid_date,
           NULL montant_devise,
           NULL devise,
           SYSDATE date_extraction,
           'REPORT GL' type_donnee,
           NULL id_elt,
           NULL je_header_id,
           NULL je_line_num
            FROM (SELECT gcc.segment3,
                          gb.period_name,
                          gb.period_num,
                          gb.period_year,
                          SUM(begin_balance_dr) somme_period_net_dr,
                          SUM(begin_balance_cr) somme_period_net_cr
                     FROM gl_balances          gb,
                          gl_code_combinations gcc,
                          fnd_flex_value_sets  ffvs,
                          fnd_flex_values_vl   ffv
                    WHERE
                   --GB
                   --gb.currency_code = cv_devise YWA
                    gb.ledger_id = gn_sob_id --ywa
                 AND gb.actual_flag = 'A'
                   --GCC
                 AND gb.code_combination_id = gcc.code_combination_id
                 AND gcc.detail_posting_allowed_flag = 'Y'
                   --FFV
                 AND gcc.segment3 = ffv.flex_value
                 AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                 AND ffvs.flex_value_set_name = cv_jdv_cpt_local
                 AND substr(gcc.segment3, 1, 1) IN
                    ('1', '2', '3', '4', '5', '6', '7') --JJA 18/11/2013
                   --
                 AND gb.period_name = gv_period || '-' ||
                    substr(to_char(ln_annee_debut) + 1, -2)
                 AND gcc.segment1 = gv_societe
                    GROUP BY gcc.segment3,
                             gb.period_name,
                             gb.period_num,
                             gb.period_year) v,
                 --CPTE LOCAL
                 fnd_flex_value_sets ffvs_loc,
                 fnd_flex_values_vl  ffvv_loc
           WHERE v.somme_period_net_dr != v.somme_period_net_cr
                --CPTE LOCAL
             AND ffvv_loc.flex_value_set_id = ffvs_loc.flex_value_set_id
             AND ffvs_loc.flex_value_set_name = cv_jdv_cpt_local
             AND ffvv_loc.flex_value = v.segment3;
      
        gn_insert := SQL%ROWCOUNT;
      
      ELSIF gv_period = 'JUL' THEN
      
        -- Récupération des soldes des comptes 1 à 5 au 01/07
        INSERT INTO dka_extract_fiscal
        --- 26/04/2021 NBO  artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
          SELECT --fnd_global.conc_request_id request_id,
           gn_conc_request_id request_id,
           gv_societe societe,
           v.period_year annee_comptable,
           v.period_name periode_comptable,
           '0' journal_code,
           'Journal ouverture' journal_lib,
           substr(to_char(v.period_year), -2) || '0000001' ecriture_num,
           to_date('01/' || lpad(v.period_num, 2, '0') || '/' ||
                   v.period_year,
                   'dd/mm/yyyy') ecriture_date,
           v.segment3 compte_num,
           ffvv_loc.description compte_lib,
           NULL compte_aux_num,
           NULL compte_aux_lib,
           'Report à nouveau' piece_ref,
           to_date('01/' || lpad(v.period_num, 2, '0') || '/' ||
                   v.period_year,
                   'dd/mm/yyyy') piece_date,
           'Report à nouveau compte ' || v.segment3 ecriture_lib,
           CASE
             WHEN v.somme_period_net_dr > v.somme_period_net_cr THEN
              (v.somme_period_net_dr - v.somme_period_net_cr)
             ELSE
              0
           END debit,
           CASE
             WHEN v.somme_period_net_cr > v.somme_period_net_dr THEN
              (v.somme_period_net_cr - v.somme_period_net_dr)
             ELSE
              0
           END credit,
           NULL ecriture_let,
           NULL date_let,
           to_date('01/' || lpad(v.period_num, 2, '0') || '/' ||
                   v.period_year,
                   'dd/mm/yyyy') valid_date,
           NULL montant_devise,
           NULL devise,
           SYSDATE date_extraction,
           'REPORT GL' type_donnee,
           NULL id_elt,
           NULL je_header_id,
           NULL je_line_num
            FROM (SELECT gcc.segment3,
                          gb.period_name,
                          gb.period_num,
                          gb.period_year,
                          SUM(begin_balance_dr) somme_period_net_dr,
                          SUM(begin_balance_cr) somme_period_net_cr
                     FROM gl_balances          gb,
                          gl_code_combinations gcc,
                          fnd_flex_value_sets  ffvs,
                          fnd_flex_values_vl   ffv
                    WHERE
                   --GB
                   --gb.currency_code = cv_devise --YWA
                    gb.ledger_id = gn_sob_id --YWA
                 AND gb.actual_flag = 'A'
                   --GCC
                 AND gb.code_combination_id = gcc.code_combination_id
                 AND gcc.detail_posting_allowed_flag = 'Y'
                   --FFV
                 AND gcc.segment3 = ffv.flex_value
                 AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                 AND ffvs.flex_value_set_name = cv_jdv_cpt_local
                 AND substr(gcc.segment3, 1, 1) IN ('1', '2', '3', '4', '5')
                   --
                 AND gb.period_name =
                    gv_period || '-' || substr(to_char(ln_annee_debut), -2)
                 AND gcc.segment1 = gv_societe
                    GROUP BY gcc.segment3,
                             gb.period_name,
                             gb.period_num,
                             gb.period_year) v,
                 --CPTE LOCAL
                 fnd_flex_value_sets ffvs_loc,
                 fnd_flex_values_vl  ffvv_loc
           WHERE v.somme_period_net_dr != v.somme_period_net_cr
                --CPTE LOCAL
             AND ffvv_loc.flex_value_set_id = ffvs_loc.flex_value_set_id
             AND ffvs_loc.flex_value_set_name = cv_jdv_cpt_local
             AND ffvv_loc.flex_value = v.segment3;
        gn_insert := SQL%ROWCOUNT;
      
        -- Faire la somme des soldes des comptes 7 - 6
        -- Si le solde est positif, il faut insérer une ligne de 120000 dans le journal d¿ouverture
        -- Si le solde est négatif, il faut insérer une ligne de 119000 dans le journal d¿ouverture
        INSERT INTO dka_extract_fiscal
        --- 26/04/2021 NBO  artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
          SELECT --fnd_global.conc_request_id request_id,
           gn_conc_request_id request_id,
           gv_societe societe,
           v.period_year annee_comptable,
           v.period_name periode_comptable,
           '0' journal_code,
           'Journal ouverture' journal_lib,
           substr(to_char(v.period_year), -2) || '0000001' ecriture_num,
           to_date('01/' || lpad(v.period_num, 2, '0') || '/' ||
                   v.period_year,
                   'dd/mm/yyyy') ecriture_date,
           CASE
             WHEN v.somme_period_net_dr > v.somme_period_net_cr THEN
              cv_compte_loc_dr
             ELSE
              cv_compte_loc_cr
           END compte_num,
           CASE
             WHEN v.somme_period_net_dr > v.somme_period_net_cr THEN
              gv_desc_cpte_loc_dr
             ELSE
              gv_desc_cpte_loc_cr
           END compte_lib,
           NULL compte_aux_num,
           NULL compte_aux_lib,
           'Report à nouveau' piece_ref,
           to_date('01/' || lpad(v.period_num, 2, '0') || '/' ||
                   v.period_year,
                   'dd/mm/yyyy') piece_date,
           CASE
             WHEN v.somme_period_net_dr > v.somme_period_net_cr THEN
              'Report à nouveau compte ' || cv_compte_loc_dr
             ELSE
              'Report à nouveau compte ' || cv_compte_loc_cr
           END ecriture_lib,
           CASE
             WHEN v.somme_period_net_dr > v.somme_period_net_cr THEN
              (v.somme_period_net_dr - v.somme_period_net_cr)
             ELSE
              0
           END debit,
           CASE
             WHEN v.somme_period_net_cr > v.somme_period_net_dr THEN
              (v.somme_period_net_cr - v.somme_period_net_dr)
             ELSE
              0
           END credit,
           NULL ecriture_let,
           NULL date_let,
           to_date('01/' || lpad(v.period_num, 2, '0') || '/' ||
                   v.period_year,
                   'dd/mm/yyyy') valid_date,
           NULL montant_devise,
           NULL devise,
           SYSDATE date_extraction,
           'REPORT GL' type_donnee,
           NULL id_elt,
           NULL je_header_id,
           NULL je_line_num
            FROM (SELECT gb.period_name,
                          gb.period_num,
                          gb.period_year,
                          SUM(begin_balance_dr) somme_period_net_dr,
                          SUM(begin_balance_cr) somme_period_net_cr
                     FROM gl_balances          gb,
                          gl_code_combinations gcc,
                          fnd_flex_value_sets  ffvs,
                          fnd_flex_values_vl   ffv
                    WHERE
                   --GB
                   --gb.currency_code = cv_devise--YWA
                    gb.ledger_id = gn_sob_id --YWA
                 AND gb.actual_flag = 'A'
                   --GCC
                 AND gb.code_combination_id = gcc.code_combination_id
                 AND gcc.detail_posting_allowed_flag = 'Y'
                   --FFV
                 AND gcc.segment3 = ffv.flex_value
                 AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                 AND ffvs.flex_value_set_name = cv_jdv_cpt_local
                 AND substr(gcc.segment3, 1, 1) IN ('6', '7')
                   --
                 AND gb.period_name =
                    gv_period || '-' || substr(to_char(ln_annee_debut), -2)
                 AND gcc.segment1 = gv_societe
                    GROUP BY gb.period_name, gb.period_num, gb.period_year) v
           WHERE v.somme_period_net_dr != v.somme_period_net_cr;
      
        gn_insert := gn_insert + SQL%ROWCOUNT;
      END IF;
    
      gv_step := 'Nb de ligne insérée : ' || gn_insert;
      dka_tools_pkg.put_log_message(gv_step);
    
      -- Validation des insertions
      gv_step := lv_current_program_unit ||
                 ' 007 : VALIDATION DES INSERTIONS';
      --dka_tools_pkg.put_debug_message(gv_step);
      COMMIT;
    
      --ANNEE SUIVANTE
      ln_annee_debut := ln_annee_debut + 1;
    
    END LOOP;
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END insert_table_report_tmp;

  -----------------------------------------------------------------
  --    Nom                     : INSERT_TABLE_PARAM
  --    Description     : procedure d'insertion dans la table de parametre
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE insert_table_param(pv_errbuf  OUT NOCOPY VARCHAR2,
                               pn_retcode OUT NOCOPY NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'insert_table_param';
    ln_annee_debut          PLS_INTEGER;
    vv_lib_colonne          VARCHAR2(50) := NULL; -- JWYC INC0289351
    ln_n_ordre              NUMBER := 0;
  
    CURSOR c_param_col IS
      SELECT '02_STRUCTURE' "GROUPE",
             column_name "NAME",
             CASE column_name
               WHEN 'JOURNAL_CODE' THEN
                '01_Code journal'
               WHEN 'JOURNAL_LIB' THEN
                '02_Libellé journal'
               WHEN 'ECRITURE_NUM' THEN
                '03_N° d''écriture'
               WHEN 'ECRITURE_DATE' THEN
                '04_Date écriture'
               WHEN 'COMPTE_NUM' THEN
                '05_N° du compte général'
               WHEN 'COMPTE_LIB' THEN
                '06_Libellé du compte général'
               WHEN 'COMPTE_AUX_NUM' THEN
                '07_Compte auxiliaire'
               WHEN 'COMPTE_AUX_LIB' THEN
                '08_Libellé du compte auxiliaire'
               WHEN 'PIECE_REF' THEN
                '09_Référence de la pièce'
               WHEN 'PIECE_DATE' THEN
                '10_Date de la pièce'
               WHEN 'ECRITURE_LIB' THEN
                '11_Libellé de l''écriture'
               WHEN 'DEBIT' THEN
                '12_Débit'
               WHEN 'CREDIT' THEN
                '13_Crédit'
               WHEN 'ECRITURE_LET' THEN
                '14_Référence de lettrage'
               WHEN 'DATE_LET' THEN
                '15_Date de lettrage'
               WHEN 'VALID_DATE' THEN
                '16_Date effective de l''écriture'
               WHEN 'MONTANT_DEVISE' THEN
                '17_Montant en devise'
               WHEN 'DEVISE' THEN
                '18_Devise'
             END "LIBELLE",
             decode(data_type,
                    'VARCHAR2',
                    'ALPHANUMERIQUE',
                    'NUMBER',
                    'NOMBRE',
                    'DATE',
                    'DATE') "TYPE",
             decode(data_type, 'DATE', '8', data_length) "LG"
        FROM all_tab_columns
       WHERE table_name = 'DKA_EXTRACT_FISCAL'
         AND column_name IN ('JOURNAL_CODE',
                             'JOURNAL_LIB',
                             'ECRITURE_NUM',
                             'ECRITURE_DATE',
                             'COMPTE_NUM',
                             'COMPTE_LIB',
                             'COMPTE_AUX_NUM',
                             'COMPTE_AUX_LIB',
                             'PIECE_REF',
                             'PIECE_DATE',
                             'ECRITURE_LIB',
                             'DEBIT',
                             'CREDIT',
                             'ECRITURE_LET',
                             'DATE_LET',
                             'VALID_DATE',
                             'MONTANT_DEVISE',
                             'DEVISE')
       ORDER BY libelle;
  
    CURSOR c_param IS
      SELECT DISTINCT '03_JOURNAUX' "GROUPE",
                      dict.journal_code "NAME",
                      dict.journal_lib "LIBELLE",
                      NULL "TYPE",
                      NULL "LG"
        FROM dka_extract_fiscal dict
      --- 26/04/2021 NBO   artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
       WHERE request_id = gn_conc_request_id --fnd_global.conc_request_id
      UNION
      SELECT DISTINCT '04_COMPTES' "GROUPE",
                      dict.compte_num "NAME",
                      dict.compte_lib "LIBELLE",
                      NULL "TYPE",
                      NULL "LG"
        FROM dka_extract_fiscal dict
      --- 26/04/2021 NBO   artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
       WHERE request_id = gn_conc_request_id --fnd_global.conc_request_id
      UNION
      SELECT DISTINCT '05_FOURNISSEURS' "GROUPE",
                      dict.compte_aux_num "NAME",
                      dict.compte_aux_lib "LIBELLE",
                      NULL "TYPE",
                      NULL "LG"
        FROM dka_extract_fiscal dict
       WHERE dict.type_donnee LIKE 'AP%'
            --- 26/04/2021 NBO   artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
         AND request_id = gn_conc_request_id -- fnd_global.conc_request_id
      UNION
      SELECT DISTINCT '06_CLIENTS' "GROUPE",
                      dict.compte_aux_num "NAME",
                      dict.compte_aux_lib "LIBELLE",
                      NULL "TYPE",
                      NULL "LG"
        FROM dka_extract_fiscal dict
       WHERE dict.type_donnee in
             ('TRANSACTIONS', 'RECEIPTS', 'ADJUSTMENTS')
            --- 26/04/2021 NBO   artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
         AND request_id = gn_conc_request_id; --fnd_global.conc_request_id;
  
  BEGIN
  
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit ||
               ' 001 : INSERTION DE LA STRUCTURE DU FICHIER';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    --- 26/04/2021 NBO  artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
    SELECT MAX(n_ordre)
      INTO ln_n_ordre
      FROM dka_param_extract_fiscal
    --WHERE  request_id = fnd_global.conc_request_id;
     WHERE request_id = gn_conc_request_id;
  
    ln_n_ordre := nvl(ln_n_ordre, 0);
  
    FOR l IN c_param_col LOOP
      --- 26/04/2021 NBO  artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
      ln_n_ordre := ln_n_ordre + 1;
    
      insert_table_param(ln_n_ordre,
                         l.groupe,
                         l.name,
                         l.libelle,
                         l.type,
                         l.lg);
    
      --< JWYC INC0289351     
      SELECT DECODE(l.name,
                    'DEVISE',
                    'IDEVISE',
                    'COMPTE_AUX_NUM',
                    'COMPAUXNUM',
                    'COMPTE_AUX_LIB',
                    'COMPAUXLIB',
                    replace(l.name, '_', ''))
        INTO vv_lib_colonne
        FROM DUAL;
      --/>
    
      IF gv_ligne_entete IS NULL THEN
        --gv_ligne_entete := l.name;
        gv_ligne_entete := vv_lib_colonne; -- JWYC INC0289351
      ELSE
        --gv_ligne_entete := gv_ligne_entete || cv_fsep || l.name;
        gv_ligne_entete := gv_ligne_entete || cv_fsep || vv_lib_colonne; -- JWYC INC0289351 
      END IF;
    END LOOP;
  
    gv_ligne_entete := gv_ligne_entete || cv_fsep;
  
    gv_step := lv_current_program_unit || ' 001 : LIGNE ENTETE : ' ||
               gv_ligne_entete;
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit || ' 002 : INSERTION DES PARAMETRES';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    FOR l IN c_param LOOP
      --- 26/04/2021 NBO  artf07454292 - TASK0141429 - Pouvez-vous nous envoyer le rapport AWR entre 18H et 9H ce matin (du 21 au 22/04) sur ETI1 
      ln_n_ordre := ln_n_ordre + 1;
    
      insert_table_param(ln_n_ordre,
                         l.groupe,
                         l.name,
                         l.libelle,
                         l.type,
                         l.lg);
    END LOOP;
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END insert_table_param;

  -----------------------------------------------------------------
  --    Nom                     : WRITE_OUTPUT_FILE
  --    Description     : procedure d'écriture dans les fichiers de sortie
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE write_output_file(pv_errbuf  OUT NOCOPY VARCHAR2,
                              pn_retcode OUT NOCOPY NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'write_output_file';
  
    -- Récupération des valeurs à éditer
    CURSOR c_select(cd_date_debut DATE, cd_date_fin DATE) IS
      SELECT *
        FROM dka_extract_fiscal
       WHERE request_id = fnd_global.conc_request_id
         AND valid_date BETWEEN cd_date_debut AND cd_date_fin
       ORDER BY valid_date, journal_code, ecriture_num;
  
    l_file_id      utl_file.file_type;
    lv_nom_fichier VARCHAR2(250);
    lv_message     VARCHAR2(100);
    lv_buffer      VARCHAR2(10000);
    ln_cpt         PLS_INTEGER;
  
  BEGIN
  
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    IF gt_table_fichier.count > 0 THEN
      gv_step := lv_current_program_unit ||
                 ' 001 : BOUCLE SUR LES FICHIERS A GENERER';
      --dka_tools_pkg.put_debug_message(gv_step);
    
      FOR i IN gt_table_fichier.first .. gt_table_fichier.last LOOP
      
        lv_nom_fichier := gv_societe || '-' || gv_siren || cv_nom_fichier ||
                          to_char(gt_table_fichier(i).date_fichier,
                                  'yyyymmdd');
      
        IF gn_periode != 12 THEN
          lv_nom_fichier := lv_nom_fichier || '_' || gt_table_fichier(i).suffixe ||
                            cv_extension;
        ELSE
          lv_nom_fichier := lv_nom_fichier || cv_extension;
        END IF;
      
        gv_step := lv_current_program_unit || ' 002 : NOM DU FICHIER : ' ||
                   lv_nom_fichier;
        --dka_tools_pkg.put_debug_message(gv_step);
      
        ln_cpt := 0;
      
        l_file_id := utl_file.fopen(cv_directory,
                                    lv_nom_fichier,
                                    'W',
                                    32764);
      
        gv_step := lv_current_program_unit ||
                   ' 003 : AJOUT DE LA LIGNE D''ENTETE';
        --dka_tools_pkg.put_debug_message(gv_step);
        utl_file.put_line(l_file_id, gv_ligne_entete);
      
        FOR ligne IN c_select(gt_table_fichier(i).date_debut,
                              gt_table_fichier(i).date_fin) LOOP
          lv_buffer := ligne.journal_code || cv_fsep ||
                       translate_texte(ligne.journal_lib) || cv_fsep ||
                       ligne.ecriture_num || cv_fsep ||
                       to_char(ligne.ecriture_date, 'yyyymmdd') || cv_fsep ||
                       ligne.compte_num || cv_fsep ||
                       translate_texte(ligne.compte_lib) || cv_fsep ||
                       ligne.compte_aux_num || cv_fsep ||
                       translate_texte(ligne.compte_aux_lib) || cv_fsep ||
                       translate_texte(ligne.piece_ref) || cv_fsep ||
                       to_char(ligne.piece_date, 'yyyymmdd') || cv_fsep ||
                       translate_texte(ligne.ecriture_lib) || cv_fsep ||
                       to_char(ligne.debit, 'FM999999999999990D00') ||
                       cv_fsep ||
                       to_char(ligne.credit, 'FM999999999999990D00') ||
                       cv_fsep;
        
          IF gt_lettrage_tiers.exists(ligne.compte_num) THEN
            --LETTRAGE
            lv_buffer := lv_buffer || ligne.ecriture_let || cv_fsep ||
                         to_char(ligne.date_let, 'yyyymmdd') || cv_fsep;
          
          ELSE
            --PAS DE LETTRAGE
            lv_buffer := lv_buffer || '' || cv_fsep || '' || cv_fsep;
          END IF;
        
          lv_buffer := lv_buffer || to_char(ligne.valid_date, 'yyyymmdd') ||
                       cv_fsep || ligne.montant_devise || cv_fsep ||
                       ligne.devise || cv_fsep;
        
          utl_file.put_line(l_file_id, lv_buffer);
          ln_cpt := ln_cpt + 1;
        
        END LOOP;
      
        --Compteur globale
        gn_cpt := gn_cpt + ln_cpt;
      
        lv_message     := 'Fichier ' || lv_nom_fichier || ' créé avec ' ||
                          ln_cpt || ' lignes';
        gv_out_message := gv_out_message || chr(10) || lv_message;
        dka_tools_pkg.put_log_message(lv_message);
      
        utl_file.fclose(l_file_id);
      
        --Ajout dans la table de paramétrage
        gv_step := lv_current_program_unit ||
                   ' 004 : Ajout dans la table de paramétrage';
        --dka_tools_pkg.put_debug_message(gv_step);
        insert_table_param(NULL,
                           '01_DONNEES_GENERALES',
                           'NBRE LIGNE FICHIER ' || lv_nom_fichier,
                           ln_cpt,
                           NULL,
                           NULL);
      
      END LOOP;
    
    END IF;
  
    --Ajout dans la table de paramétrage
    gv_step := lv_current_program_unit ||
               ' 005 : Ajout dans la table de paramétrage';
    --dka_tools_pkg.put_debug_message(gv_step);
    insert_table_param(NULL,
                       '01_DONNEES_GENERALES',
                       'NOMBRE LIGNE TOTAL',
                       gn_cpt,
                       NULL,
                       NULL);
    insert_table_param(NULL,
                       '01_DONNEES_GENERALES',
                       'NOMBRE FICHIER',
                       gt_table_fichier.count,
                       NULL,
                       NULL);
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END write_output_file;

  -----------------------------------------------------------------
  --    Nom                     : WRITE_PARAM_FILE
  --    Description     : procedure d'écriture dans les fichiers de sortie
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE write_param_file(pv_errbuf  OUT NOCOPY VARCHAR2,
                             pn_retcode OUT NOCOPY NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'write_param_file';
  
    -- Récupération des valeurs à éditer
    CURSOR c_select IS
      SELECT *
        FROM dka_param_extract_fiscal
       WHERE request_id = fnd_global.conc_request_id
       ORDER BY groupe, n_ordre, data_value;
  
    l_file_id      utl_file.file_type;
    lv_nom_fichier VARCHAR2(250);
    lv_group       dka_param_extract_fiscal.groupe%TYPE;
    lv_message     VARCHAR2(100);
    lv_value       dka_param_extract_fiscal.data_value%TYPE;
    lv_buffer      VARCHAR2(10000);
    vv_lib_colonne VARCHAR2(50) := NULL;
  
  BEGIN
  
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    lv_nom_fichier := gv_societe || '-' || gv_siren || cv_fichier_param ||
                      cv_extension;
    gv_step        := lv_current_program_unit || ' 002 : NOM DU FICHIER : ' ||
                      lv_nom_fichier;
    --dka_tools_pkg.put_debug_message(gv_step);
  
    l_file_id := utl_file.fopen(cv_directory, lv_nom_fichier, 'W', 32764);
  
    FOR ligne IN c_select LOOP
    
      lv_buffer := NULL;
    
      IF nvl(lv_group, '#') != ligne.groupe THEN
        lv_group := ligne.groupe;
      
        CASE lv_group
          WHEN '01_DONNEES_GENERALES' THEN
            lv_buffer := 'DONNEES GENERALES' || chr(10) || 'NOM PARAMETRE' ||
                         chr(9) || 'VALEUR' || chr(9);
          WHEN '02_STRUCTURE' THEN
            lv_buffer := chr(10) || 'DESCRIPTIF EN TETE FICHIER' || chr(10) ||
                         'CODE' || chr(9) || 'DESCRIPTION' || chr(9) ||
                         'TYPE CHAMP' || chr(9) || 'LONGUEUR' || chr(9);
          WHEN '03_JOURNAUX' THEN
            lv_buffer := chr(10) || 'CODES JOURNAUX' || chr(10) || 'CODE' ||
                         chr(9) || 'LIBELLE' || chr(9);
          WHEN '04_COMPTES' THEN
            lv_buffer := chr(10) || 'COMPTES GENERAUX' || chr(10) || 'CODE' ||
                         chr(9) || 'LIBELLE' || chr(9);
          WHEN '05_FOURNISSEURS' THEN
            lv_buffer := chr(10) || 'CODES FOURNISSEURS' || chr(10) ||
                         'CODE FOURNISSEUR' || chr(9) ||
                         'LIBELLE FOURNISSEUR' || chr(9);
          WHEN '06_CLIENTS' THEN
            lv_buffer := chr(10) || 'CODES CLIENTS' || chr(10) ||
                         'CODE CLIENT' || chr(9) || 'LIBELLE CLIENT' ||
                         chr(9);
          ELSE
            lv_buffer := 'GROUPE INCONNU';
        END CASE;
      
        utl_file.put_line(l_file_id, lv_buffer);
      
      END IF;
    
      IF lv_group = '02_STRUCTURE' THEN
        lv_value := substr(ligne.data_value, 4);
      ELSE
        lv_value := ligne.data_value;
      END IF;
    
      --<JWYC INC0289351 
      IF lv_group = '02_STRUCTURE' THEN
      
        SELECT DECODE(ligne.data_name,
                      'DEVISE',
                      'IDEVISE',
                      'COMPTE_AUX_NUM',
                      'COMPAUXNUM',
                      'COMPTE_AUX_LIB',
                      'COMPAUXLIB',
                      replace(ligne.data_name, '_', ''))
          INTO vv_lib_colonne
          FROM DUAL;
      
        lv_buffer := translate_texte(vv_lib_colonne) || cv_fsep ||
                     translate_texte(lv_value) || cv_fsep ||
                     ligne.data_type || cv_fsep || ligne.data_lg || cv_fsep;
      
      ELSE
        --/>
      
        lv_buffer := translate_texte(ligne.data_name) || cv_fsep ||
                     translate_texte(lv_value) || cv_fsep ||
                     ligne.data_type || cv_fsep || ligne.data_lg || cv_fsep;
      
      END IF;
    
      --Suppression des sauts de lignes
      lv_buffer := REPLACE(lv_buffer, chr(10), '');
    
      utl_file.put_line(l_file_id, lv_buffer);
    
    END LOOP;
  
    lv_message     := 'Fichier ' || lv_nom_fichier || ' créé';
    gv_out_message := gv_out_message || chr(10) || lv_message;
    dka_tools_pkg.put_log_message(lv_message);
  
    utl_file.fclose(l_file_id);
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END write_param_file;

  -----------------------------------------------------------------
  --    Nom                     : AFFICHAGE_FICHIER_SORTIE
  --    Description     : procedure d'écriture dans le fichier de sortie
  --                                    du traitement
  --
  --    PARAMETRES :
  --     pv_errbuf                OUT NOCOPY VARCHAR2,
  --     pn_retcode             OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE affichage_fichier_sortie(pv_errbuf  OUT NOCOPY VARCHAR2,
                                     pn_retcode OUT NOCOPY NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'affichage_fichier_sortie';
  
  BEGIN
  
    gv_step := lv_current_program_unit || ' 000 : DEBUT';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    gv_step := lv_current_program_unit || ' 001 : INSERTION ENTETE';
    --dka_tools_pkg.put_debug_message(gv_step);
    dka_tools_pkg.put_out_header;
  
    gv_step := lv_current_program_unit || ' 002 : AFFICHAGE DES PARAMETRES';
    --dka_tools_pkg.put_debug_message(gv_step);
  
    dka_tools_pkg.put_outdebug_message('SOCIETE                  :' ||
                                       gv_societe);
    dka_tools_pkg.put_outdebug_message('ANNEE DU CONTROLE FISCAL :' ||
                                       gn_annee_ref);
    dka_tools_pkg.put_outdebug_message('PERIODICITE (MOIS)       :' ||
                                       gn_periode);
    dka_tools_pkg.put_outdebug_message(cv_line);
  
    gv_step := lv_current_program_unit ||
               ' 003 : AFFICHAGE DES FICHIERS GENEREES';
    --dka_tools_pkg.put_debug_message(gv_step);
    fnd_file.put_line(fnd_file.output, gv_out_message);
  
    gv_step := lv_current_program_unit || ' 999 : FIN';
    --dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END affichage_fichier_sortie;

  ------------------------------------------------------------------------------------
  --    Nom                     : main
  --    Description     : point d'entrée du traitement
  --
  --    PARAMETRES        :
  -- Parametres
  --    pv_errbuf                         message d'erreur si pn_retcode != 0
  --    pn_retcode                        code de sortie (0 : normal, 1 : warning,2 : erreur)
  --    pv_societe                        Societe
  --    pn_annee_ref                    Année de référence
  --    pn_periode                        Périodicité (1 mois, 2 mois .... 12 mois)
  --
  ------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf    OUT NOCOPY VARCHAR2,
                 pn_retcode   OUT NOCOPY NUMBER,
                 pv_societe   IN VARCHAR2,
                 pn_annee_ref IN NUMBER,
                 pn_periode   IN NUMBER) IS
  
    lv_current_program_unit VARCHAR2(30) := 'main';
  
    --EXCEPTION
    e_init             EXCEPTION;
    e_param            EXCEPTION;
    e_purge            EXCEPTION;
    e_insert           EXCEPTION;
    e_output           EXCEPTION;
    e_insert_param     EXCEPTION;
    e_affichage_sortie EXCEPTION;
    e_write_param      EXCEPTION;
  
  BEGIN
  
    ----------------------------------------------------------------
    --RECUPERATION DES PARAMETRES
    ----------------------------------------------------------------
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Recuperation des parametres');
    dka_tools_pkg.put_log_message(cv_line);
  
    dka_tools_pkg.put_log_message('Debut : ' || get_time);
  
    --procedure de recuperation des parametres
    get_parameters(pv_errbuf,
                   pn_retcode,
                   pv_societe,
                   pn_annee_ref,
                   pn_periode);
    IF pn_retcode != 0 THEN
      RAISE e_param;
    END IF;
  
    dka_tools_pkg.put_log_message('Recuperation des parametres OK...');
    dka_tools_pkg.put_log_message('Fin     : ' || get_time);
  
    ----------------------------------------------------------------
    --PURGE DE LA TABLE DE TRAVAIL
    ----------------------------------------------------------------
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Purge des tables de travail');
    dka_tools_pkg.put_log_message(cv_line);
  
    dka_tools_pkg.put_log_message('Debut : ' || get_time);
  
    --procedure de purge de la table de travail
    purge_table_tmp(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_purge;
    END IF;
  
    dka_tools_pkg.put_log_message('Purge des tables de travail OK...');
    dka_tools_pkg.put_log_message('Fin     : ' || get_time);
  
    ----------------------------------------------------------------
    --INITIALISATION DU TRAITEMENT
    ----------------------------------------------------------------
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Initialisation');
    dka_tools_pkg.put_log_message(cv_line);
  
    dka_tools_pkg.put_log_message('Debut : ' || get_time);
  
    --procedure de initialisation
    init(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_init;
    END IF;
  
    dka_tools_pkg.put_log_message('Initialisation OK...');
    dka_tools_pkg.put_log_message('Fin     : ' || get_time);
  
    ----------------------------------------------------------------
    --INSERTIONS DANS LA TABLE DE TRAVAIL
    ----------------------------------------------------------------
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Insertions dans la table de travail');
    dka_tools_pkg.put_log_message(cv_line);
  
    dka_tools_pkg.put_log_message(chr(9) ||
                                  'Insertion Facture AP - debut : ' ||
                                  get_time);
    --procedure d'insertion dans la table de travail
    insert_table_fact_ap_tmp(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_insert;
    END IF;
    dka_tools_pkg.put_log_message(chr(9) ||
                                  'Insertion Facture AP - fin : ' ||
                                  get_time || chr(10));
  
    dka_tools_pkg.put_log_message('Insertion Règlement AP - debut : ' ||
                                  get_time);
    --procedure d'insertion dans la table de travail
    insert_table_rglt_ap_tmp(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_insert;
    END IF;
    dka_tools_pkg.put_log_message(chr(9) ||
                                  'Insertion Règlement AP - fin : ' ||
                                  get_time || chr(10));
  
    dka_tools_pkg.put_log_message(chr(9) ||
                                  'Insertion Facture AR - debut : ' ||
                                  get_time);
    --procedure d'insertion dans la table de travail
    insert_table_fact_ar_tmp(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_insert;
    END IF;
    dka_tools_pkg.put_log_message(chr(9) ||
                                  'Insertion Facture AR - fin : ' ||
                                  get_time || chr(10));
  
    dka_tools_pkg.put_log_message(chr(9) ||
                                  'Insertion Règlement et    Divers AR - debut : ' ||
                                  get_time);
    --procedure d'insertion dans la table de travail
    insert_table_rglt_ar_tmp(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_insert;
    END IF;
    dka_tools_pkg.put_log_message(chr(9) ||
                                  'Insertion Règlement    et    Divers AR- fin : ' ||
                                  get_time || chr(10));
  
    /*dka_tools_pkg.put_log_message(chr(9)||'Insertion Divers AR - debut : '||get_time);
    --procedure d'insertion dans la table de travail
    insert_table_misc_ar_tmp(pv_errbuf,pn_retcode);
    IF pn_retcode != 0 THEN
    RAISE e_insert;
    END IF;
    dka_tools_pkg.put_log_message(chr(9)||'Insertion Divers AR - fin : '||get_time||chr(10));
    */
    dka_tools_pkg.put_log_message(chr(9) ||
                                  'Insertion Ajustement AR - debut : ' ||
                                  get_time);
    --procedure d'insertion dans la table de travail
    insert_table_adju_ar_tmp(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_insert;
    END IF;
    dka_tools_pkg.put_log_message(chr(9) ||
                                  'Insertion Ajustement AR - fin : ' ||
                                  get_time || chr(10));
  
    dka_tools_pkg.put_log_message(chr(9) ||
                                  'Insertion Autres GL - debut : ' ||
                                  get_time);
    --procedure d'insertion dans la table de travail
    insert_table_autr_gl_tmp(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_insert;
    END IF;
    dka_tools_pkg.put_log_message(chr(9) || 'Insertion Autres GL - fin : ' ||
                                  get_time || chr(10));
  
    dka_tools_pkg.put_log_message(chr(9) ||
                                  'Insertion Report GL - debut : ' ||
                                  get_time);
    --procedure d'insertion dans la table de travail
    insert_table_report_tmp(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_insert;
    END IF;
    dka_tools_pkg.put_log_message(chr(9) || 'Insertion Report GL - fin : ' ||
                                  get_time || chr(10));
  
    dka_tools_pkg.put_log_message('Insertions dans la table de travail OK...');
    dka_tools_pkg.put_log_message('Fin     : ' || get_time);
  
    ----------------------------------------------------------------
    --INSERTIONS DANS LA TABLE DE PARAMETRE
    ----------------------------------------------------------------
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Insertion dans la table de paramètre');
    dka_tools_pkg.put_log_message(cv_line);
  
    dka_tools_pkg.put_log_message('Debut : ' || get_time);
  
    --procedure de insertion dans la table de paramètre
    insert_table_param(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_insert_param;
    END IF;
  
    dka_tools_pkg.put_log_message('Insertion dans la table de paramètre OK...');
    dka_tools_pkg.put_log_message('Fin     : ' || get_time);
  
    ----------------------------------------------------------------
    --ECRITURE DANS LES FICHIERS
    ----------------------------------------------------------------
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Ecriture des fichiers de sortie');
    dka_tools_pkg.put_log_message(cv_line);
  
    dka_tools_pkg.put_log_message('Debut : ' || get_time);
  
    --procedure d'ecriture dans les fichiers de sortie
    write_output_file(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_output;
    END IF;
  
    dka_tools_pkg.put_log_message('Ecriture des fichiers de sortie OK...');
    dka_tools_pkg.put_log_message('Fin     : ' || get_time);
  
    ----------------------------------------------------------------
    --EDITION DU FICHIER DE PARAMETRES
    ----------------------------------------------------------------
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Edition du fichier de parametres');
    dka_tools_pkg.put_log_message(cv_line);
  
    dka_tools_pkg.put_log_message('Debut : ' || get_time);
  
    --procedure d'ecriture du fichier de paramètre
    write_param_file(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_write_param;
    END IF;
  
    dka_tools_pkg.put_log_message('Edition du fichier de parametres OK...');
    dka_tools_pkg.put_log_message('Fin     : ' || get_time);
  
    ----------------------------------------------------------------
    --AFFICHAGE DANS LE FICHIER DE SORTIE
    ----------------------------------------------------------------
    dka_tools_pkg.put_log_message(cv_line);
    dka_tools_pkg.put_log_message('Affichage dans le fichier de sortie');
    dka_tools_pkg.put_log_message(cv_line);
  
    dka_tools_pkg.put_log_message('Debut : ' || get_time);
  
    --procedure d'affichage dans le fichier de sortie
    affichage_fichier_sortie(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_affichage_sortie;
    END IF;
  
    dka_tools_pkg.put_log_message('Affichage dans le fichier de sortie OK...');
    dka_tools_pkg.put_log_message('Fin     : ' || get_time);
  
  EXCEPTION
    WHEN e_init THEN
      gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
    WHEN e_param THEN
      gv_step := lv_current_program_unit || ' EE2 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
    WHEN e_purge THEN
      gv_step := lv_current_program_unit || ' EE3 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
    WHEN e_insert THEN
      gv_step := lv_current_program_unit || ' EE4 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
    WHEN e_output THEN
      gv_step := lv_current_program_unit || ' EE5 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
    WHEN e_insert_param THEN
      gv_step := lv_current_program_unit || ' EE6 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
    WHEN e_affichage_sortie THEN
      gv_step := lv_current_program_unit || ' EE7 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
    WHEN e_write_param THEN
      gv_step := lv_current_program_unit || ' EE8 : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
    WHEN OTHERS THEN
      gv_step := lv_current_program_unit || ' EEE : ERREUR lors de :' ||
                 gv_step;
      dka_tools_pkg.put_log_message(gv_step);
      pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
                   lv_current_program_unit || chr(10) || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END main;
  /*============================================================================*/
  -- Procedure         : writeout
  -- Description       : Ecriture dans fichier *.OUT
  -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
  -- Parametres sortie : AUCUN
  -- Auteur            : Saloua HA 
  -- Date              : 14/07/2021
  -- Remarques         :
  /*============================================================================*/
  PROCEDURE writeout(P_message IN VARCHAR2) IS
    L_procedure VARCHAR2(30) := 'writeout';
    v_etape     VARCHAR2(100);
  
  BEGIN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, P_message);
  END writeout;

  ------------------------------------------------------------------------------------
  --    Nom                     : main
  --    Description             : point d'entrée du traitement
  --
  --    PARAMETRES              :
  -- Parametres
  --    pv_errbuf                         message d'erreur si pn_retcode != 0
  --    pn_retcode                        code de sortie (0 : normal, 1 : warning,2 : erreur)
  --    pv_type_exercice                  type d'exercice

  ------------------------------------------------------------------------------------
  PROCEDURE main_auto(pv_errbuf        OUT NOCOPY VARCHAR2,
                      pn_retcode       OUT NOCOPY NUMBER,
                      pv_type_exercice IN VARCHAR2,
					  pv_annee_extraction in number -- 1100 EDB334
					  ) IS
  
    lv_current_program_unit VARCHAR2(30) := 'main_auto';
    l_application_code      VARCHAR2(50) := 'DKA';
    l_conc_program          VARCHAR2(50) := 'DKA_IAPARGLCTRLFISCAL';
    l_message               VARCHAR2(2000);
    l_execute_code          BOOLEAN;
    pn_annee_ref            NUMBER;
    l_request_id            NUMBER;
    l_req_interval          NUMBER := 30;
    l_req_max_wait          NUMBER := 999999;
    --l_req_ret_code          NUMBER;
    l_req_phase      VARCHAR2(255);
    l_req_status     VARCHAR2(255);
    l_req_dev_phase  VARCHAR2(255);
    l_req_dev_status VARCHAR2(255);
    l_req_message    VARCHAR2(255);
    p_type_exercice  varchar(10);
    v_warning        boolean;
  
    vt_traitement  mytable;
    vn_traitement  NUMBER := 0;
    vn_trt_normal  NUMBER := 0;
    vn_trt_warning NUMBER := 0;
    vn_trt_erreur  NUMBER := 0;
  
    CURSOR cur_exercice_decale IS
      select gl1.short_name societe
        from GL_LEDGER_RELATIONSHIPS glr, gl_ledgers gl1, gl_ledgers gl2
       where glr.primary_ledger_id = gl1.ledger_id
         and glr.TARGET_LEDGER_ID = gl2.ledger_id
         and glr.target_ledger_category_code = 'SECONDARY'
         and glr.relationship_type_code = 'JOURNAL'
         and glr.disable_conversion_date is null
         and gl1.short_name not in
             (select ffv.flex_value
                from fnd_flex_value_sets ffvs, fnd_flex_values ffv
               where ffv.flex_value_set_id = ffvs.flex_value_set_id
                 AND flex_value_set_name = 'DKA_STES_EXCLUES_CTRL_FISCAL'
                 and ffv.enabled_flag = 'Y'
                 and nvl(ffv.start_date_active, SYSDATE) <= SYSDATE
                 and nvl(ffv.end_date_active, SYSDATE) >= SYSDATE)
         and gl1.short_name in
             (select ffv.flex_value
                from fnd_flex_value_sets ffvs, fnd_flex_values ffv
               where ffv.flex_value_set_id = ffvs.flex_value_set_id
                 AND flex_value_set_name = 'DAOPCCF_STE'
                 and ffv.enabled_flag = 'Y'
                 and nvl(ffv.start_date_active, SYSDATE) <= SYSDATE
                 and nvl(ffv.end_date_active, SYSDATE) >= SYSDATE)
       order by 1;
  
    CURSOR cur_annee_civile IS
    
      select gl.short_name societe
        from gl_ledgers gl
       where gl.short_name not in
             (select ffv.flex_value
                from fnd_flex_value_sets ffvs, fnd_flex_values ffv
               where ffv.flex_value_set_id = ffvs.flex_value_set_id
                 AND flex_value_set_name = 'DKA_STES_EXCLUES_CTRL_FISCAL'
                 and ffv.enabled_flag = 'Y'
                 and nvl(ffv.start_date_active, SYSDATE) <= SYSDATE
                 and nvl(ffv.end_date_active, SYSDATE) >= SYSDATE)
         and gl.short_name in
             (select ffv.flex_value
                from fnd_flex_value_sets ffvs, fnd_flex_values ffv
               where ffv.flex_value_set_id = ffvs.flex_value_set_id
                 AND flex_value_set_name = 'DAOPCCF_STE'
                 and ffv.enabled_flag = 'Y'
                 and nvl(ffv.start_date_active, SYSDATE) <= SYSDATE
                 and nvl(ffv.end_date_active, SYSDATE) >= SYSDATE)
         and gl.short_name not in
             (select gl1.short_name
                from GL_LEDGER_RELATIONSHIPS glr,
                     gl_ledgers              gl1,
                     gl_ledgers              gl2
               where glr.primary_ledger_id = gl1.ledger_id
                 and glr.TARGET_LEDGER_ID = gl2.ledger_id
                 and glr.target_ledger_category_code = 'SECONDARY'
                 and glr.relationship_type_code = 'JOURNAL'
                 and glr.disable_conversion_date is null)
       order by 1;
  BEGIN
  
    v_warning := FALSE;
    writeout('--------------------------------------------------------------------------------------------');
    writeout(' COMPTE-RENDU DU TRAITEMENT « DKA - Automate Extraction contrôle fiscal » ');
    writeout(' Traitement n° ' || TO_CHAR(g_request_id));
    writeout(' Le  : ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    writeout('--------------------------------------------------------------------------------------------');
    writeout('                                                                ');
    writeout(' Paramètre type d''exercice : ' || pv_type_exercice);
    p_type_exercice := pv_type_exercice;
    IF p_type_exercice = '01-12' THEN
      FOR rec_annee_civile IN cur_annee_civile LOOP
        
	    If pv_annee_extraction is not null then   -- 1100 EDB334
			pn_annee_ref := pv_annee_extraction;  -- 1100 EDB334
		else                                      -- 1100 EDB334
			BEGIN
			  select distinct period_year
				INTO pn_annee_ref
				from gl_periods
			   where period_set_name = 'GROUPE'
				 and add_months(sysdate, -12) between start_date and end_date;
			EXCEPTION
			  WHEN OTHERS THEN
				pn_annee_ref := null;
			  
			END;
		end if;                                   -- 1100 EDB334
		
        l_request_id := FND_REQUEST.submit_request(l_application_code,
                                                   l_conc_program,
                                                   null,
                                                   SYSDATE,
                                                   FALSE,
                                                   rec_annee_civile.societe,
                                                   pn_annee_ref,
                                                   '12');
        COMMIT;
      
        vn_traitement := vn_traitement + 1;
        vt_traitement(vn_traitement).request_id := l_request_id;
      
        /*
        IF l_request_id != 0 THEN
          DKA_TOOLS_PKG.put_log_message(l_message);
          l_execute_code := FND_CONCURRENT.WAIT_FOR_REQUEST(REQUEST_ID => l_request_id,
                                                            INTERVAL   => l_req_interval,
                                                            MAX_WAIT   => l_req_max_wait,
                                                            PHASE      => l_req_phase,
                                                            STATUS     => l_req_status,
                                                            DEV_PHASE  => l_req_dev_phase,
                                                            DEV_STATUS => l_req_dev_status,
                                                            MESSAGE    => l_req_message);
        
          IF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'WARNING' THEN
            l_message := lv_current_program_unit ||
                         ' - 04a - Traitement terminé en avertissement';
            DKA_TOOLS_PKG.put_log_message(l_message);
            v_warning := true;
          ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'ERROR' THEN
            l_message := lv_current_program_unit ||
                         ' - 04b - Traitement terminé en erreur';
            DKA_TOOLS_PKG.put_log_message(l_message);
            v_warning := true;
          ELSIF l_req_dev_phase = 'COMPLETE' AND
                l_req_dev_status = 'NORMAL' THEN
            l_message := lv_current_program_unit ||
                         ' - 04b - Traitement terminé normal';
            DKA_TOOLS_PKG.put_log_message(l_message);
            Fnd_File.put_line(Fnd_File.LOG, l_message);
            pn_retcode := 0;
          
          END IF; 
        ELSE */
        IF l_request_id = 0 THEN
        
          l_message := lv_current_program_unit ||
                       ' - 03 - Erreur lors du lancement du traitement';
          DKA_TOOLS_PKG.put_log_message(l_message);
          DBMS_OUTPUT.PUT_LINE(l_message);
          pn_retcode := 2;
        
        END IF;
        writeout(' Société ' || rec_annee_civile.societe ||
                 ' : lancement du traitement ' || l_request_id);
      END LOOP;
    
    ELSE
    
      FOR rec_exercice_decale IN cur_exercice_decale LOOP
      
	    If pv_annee_extraction is not null then   -- 1100 EDB334
			pn_annee_ref := pv_annee_extraction;  -- 1100 EDB334
		else 	                                  -- 1100 EDB334    
			BEGIN
			  select distinct period_year
				INTO pn_annee_ref
				from gl_periods
			   where period_set_name like 'Juillet%'
				 and add_months(sysdate, -12) between start_date and end_date;
			EXCEPTION
			  WHEN OTHERS THEN
				pn_annee_ref := null;
			  
			END;
		end if;                                   -- 1100 EDB334
        l_request_id := FND_REQUEST.submit_request(l_application_code,
                                                   l_conc_program,
                                                   null,
                                                   SYSDATE,
                                                   FALSE,
                                                   rec_exercice_decale.societe,
                                                   pn_annee_ref,
                                                   '12');
      
        vn_traitement := vn_traitement + 1;
        vt_traitement(vn_traitement).request_id := l_request_id;
      
        COMMIT;
      
        /*
        
        IF l_request_id != 0 THEN
          DKA_TOOLS_PKG.put_log_message(l_message);
          l_execute_code := FND_CONCURRENT.WAIT_FOR_REQUEST(REQUEST_ID => l_request_id,
                                                            INTERVAL   => l_req_interval,
                                                            MAX_WAIT   => l_req_max_wait,
                                                            PHASE      => l_req_phase,
                                                            STATUS     => l_req_status,
                                                            DEV_PHASE  => l_req_dev_phase,
                                                            DEV_STATUS => l_req_dev_status,
                                                            MESSAGE    => l_req_message);
        
          IF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'WARNING' THEN
            l_message := lv_current_program_unit ||
                         ' - 04a - Traitement terminé en avertissement';
            DKA_TOOLS_PKG.put_log_message(l_message);
            v_warning := true;
          ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'ERROR' THEN
            l_message := lv_current_program_unit ||
                         ' - 04b - Traitement terminé en erreur';
            DKA_TOOLS_PKG.put_log_message(l_message);
            v_warning := true;
          ELSIF l_req_dev_phase = 'COMPLETE' AND
                l_req_dev_status = 'NORMAL' THEN
            l_message := lv_current_program_unit ||
                         ' - 04b - Traitement terminé normal';
            DKA_TOOLS_PKG.put_log_message(l_message);
            Fnd_File.put_line(Fnd_File.LOG, l_message);
            pn_retcode := 0;
          
          END IF;
        ELSE */
      
        IF l_request_id = 0 THEN
          l_message := lv_current_program_unit ||
                       ' - 03 - Erreur lors du lancement du traitement';
          DKA_TOOLS_PKG.put_log_message(l_message);
          DBMS_OUTPUT.PUT_LINE(l_message);
          pn_retcode := 2;
        
        END IF;
        writeout(' Société :=  ' || rec_exercice_decale.societe ||
                 ': lancement du traitement ' || l_request_id);
      END LOOP;
    END IF;
  
    writeout('');
  
    FOR vn_indice IN 1 .. vn_traitement LOOP
      IF NOT Fnd_Concurrent.wait_for_request(REQUEST_ID => vt_traitement(vn_indice).request_id,
                                             INTERVAL   => l_req_interval,
                                             MAX_WAIT   => l_req_max_wait,
                                             PHASE      => l_req_phase,
                                             STATUS     => l_req_status,
                                             DEV_PHASE  => l_req_dev_phase,
                                             DEV_STATUS => l_req_dev_status,
                                             MESSAGE    => l_req_message) THEN
        writeout(CHR(10) || '>>> Traitement ' || vt_traitement(vn_indice).request_id ||
                 ' termine en Warning');
      ELSE
      
        IF l_req_dev_status = 'NORMAL' THEN
          --    writeout ('>>> Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
          vn_trt_normal := vn_trt_normal + 1;
        ELSIF l_req_dev_status = 'WARNING' THEN
          writeout('>>> Traitement ' || vt_traitement(vn_indice).request_id ||
                   ' termine en Avertissement.');
          vn_trt_warning := vn_trt_warning + 1;
        ELSIF l_req_dev_status != 'NORMAL' THEN
          writeout('>>> Traitement ' || vt_traitement(vn_indice).request_id ||
                   ' termine en Erreur (' || l_req_message || ').');
          vn_trt_erreur := vn_trt_erreur + 1;
        END IF;
      END IF;
    
    END LOOP;
  
    if (vn_trt_warning > 0 OR vn_trt_erreur > 0) then
      pn_retcode := 1;
    end if;
  
    writeout('');
    writeout('--------------------------------------------------------------------------------------------');
    writeout('');
    writeout('Traitements lancés : ' || vn_traitement);
    writeout('Traitements terminés OK : ' || vn_trt_normal);
    writeout('Traitements en avertissement : ' || vn_trt_warning);
    writeout('Traitements en erreur : ' || vn_trt_erreur);
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc dka_iaparglctrlfiscal_pkg.main_auto : ' ||
                    SQLERRM;
  END main_auto;
END dka_iaparglctrlfiscal_pkg;
/
SHOW ERRORS;
EXIT