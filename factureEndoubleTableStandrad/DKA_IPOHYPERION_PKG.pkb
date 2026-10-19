CREATE OR REPLACE PACKAGE BODY APPS.DKA_SARAUTOPRELEV_PKG IS
  ----------------------------------------------------------------------------------------------
  -- $Id: DKA_SARAUTOPRELEV_PKG.pkb 178 2008-11-26 19:03:25Z viknab $
  --
  -- NOM               : DKA_SARAUTOPRELEV_PKG.pks
  -- DESCRIPTION       :
  ---
  --- AUTEUR           : C. Trochu (Capgemini)
  --- DATE DE CREATION : 10/07/2008
  --- DOC. ASSOCIEE    : Spécifications fonctionnelles (0SPF20080090_NEXT - Remise en banque des prélèvements clients.doc)
  ---                    Spécifications techniques (PDO-MD070-003-V1.00-FR-DNX-Remise en banque des prélèvements clients.doc)
  ---
  ----------------------------------------------------------------------------------------------
  --- NOM DU PROGRAMME :
  --- PARAMETRES       :
  ---
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --- 2008/10/09 tbo [artf408153] ajout d'un curseur pour l'execution du second
  ---                traitement, et de la boucle associee.
  --- 2008/11/10 vkn [artf430728]  : Modifications des Prélèvements clients suite recette
  ---                   les identifications sont identifiés par M3.
  ---                  + oubli de M1 (pour la date a la place du C_REMIT_REFERENCE
  ---                         dans les entetes de type 03)
  --- 18/03/2009 GV  main: correction de la rupture sur la création de fichier => il faut prendre
  ---                      le code banque au lieu du code guichet
  --- 24/03/2008 GV  insert_prelev: changement de la remit_date  => on prend la date d'échéance passé en paramètre
  ---                main: il ne faut imprimer que les traitements de bordereaux
  --- 01/04/2009 GV  main: ajout trunc dans les SYSDATE pour une comparaison sans la partie heure
  --- 10/04/2009 GV  main: appel de la fonction dka_dnx_tools_pkg.trt_car_spec pour traiter les
  ---                      caractères spéciaux
  --- 23/07/2009 GV  main: appel de la procédure dka_dnx_tools_pkg.get_next_working_day pour que la date
  ---                      de remise soit automatiquement un jour ouvré
  -- 21/12/2009 JVI EIS20090085 : Gestion des prélèvements partiels :
  --                              Suppression de la création auto de règlement et
  --                              Ajout des paramètres de date d'exigibilité dans l'appel à la remise en banque auto
  -- 03/02/2010 SLA create_seq_prlv_ar : les séquences sont créées avec une mauvaise valeur initiale
  --                La valeur initiale actuelle est 8000001 alors qu'elle doit être fonction de l'année
  --                (car séquence annuelle)
  -- 24/06/2010 FMI EIS20100069 : Les etats concernés par la campagne de reglement express sont mis a disposition sur l'imprimante
  --                de la tresorerie.
  -- 05/11/2012 JJA Correction de get_code_agora
  -- 06/12/2012 JJA Correction de get_code_agora (BD SOCIETE)
  -- 15/11/2012 JJA DGE20120044 :création de nouvelles Uos
  -- 12/07/2013 JJA DGE20130023 :Evolution F56 Bis Avennat au format DD IMPORT
  -- 17/12/2013 BCO Ajout du CashReceiptId dans la table de travail DKA_SARAUTOPRELEV_TMP.
  --        2.3.1.12 - Ajout de la date de prélèvement dans le CUF Attribute4
  -- 31/12/2013 BCO Modification de la valeur du champ COUNTERPARTYMESSAGE.
  -- 28/01/2014 JJA INC000000505105 : Correction sur la sélection de la classe de règlement et du champ description.
  -- 19/03/2014 BCO INC000000520672 - Pb génération fichier SEPA prélèvement client.
  -- 22/09/2016 MEG Migration R12
  -- 26/01/2017 OBE Modification - artf2090858
  -- 13/06/2017 JJA Modification- sécurisation - artf2173211
  -- 14/03/2018 OBE artf2432851 : INC0193097 : Prélèvements clients - Ligne en double dans l'état DKA : France - Bordereau des prélèvements clients
  -- 02/05/2018 JJA Correction APPS.AR_MO_GLOBAL_CACHE - INC0206499 : Campagne de Prélèvements (D8)
  -- 15/05/2020 JWY INC0422554 Suppression de la MaJ du parametrage du nb de jours sur la classe de reglement.
  --                Il n'est plus nécessaire et génère des conflits avec le SPE219
  -- 01/07/2024 ARA EDB379 - MISE EN PLACE DES PRELEVEMENTS EXPRESS
  -- 24/06/2025 BBM EDB418 - Module AR - Prélèvements clients - Nommage table sauvegarde en début de traitement
  --------------------------------------------------------------------------------------------

  -- Constantes
  --------------
  k_user_name    fnd_user.user_name%TYPE := fnd_global.user_name;

  cv_program_code          constant dka_parameters.program_code%type := 'SARAUTOEFFRGT'; --JVI 21/12/2009
  cv_param_name_due_date_l constant dka_parameters.parameter_name%type := 'EFFET_DUE_DATE_L'; --JVI 21/12/2009
  cv_caractere_autorise    CONSTANT VARCHAR2(100) := ' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-?:().,+''';
  cn_default_delai         CONSTANT NUMBER := 3;

  -- Variables globales
  ----------------------
  g_organisation_user   hr_all_organization_units.organization_id%type;
  gd_effet_due_date_l   dka_parameters.date_value%type; --jvi 21/12/2009

  gn_request_id fnd_concurrent_requests.request_id%TYPE;

  -- Procédures privées
  ------------------------

  -------------------------------------------------------
  -- Procédure de suppression des tables de sauvegarde --
  -------------------------------------------------------
  PROCEDURE delete_save_tables(pv_table_name VARCHAR2) IS

    CURSOR cur_tables(pv_table_name VARCHAR2) IS
      SELECT owner, table_name
        FROM all_tables
       WHERE table_name LIKE pv_table_name || '%';

    rec_tables          cur_tables%ROWTYPE;
    vn_longueur_prefixe NUMBER;
    vn_longueur_table   NUMBER;
    vv_date_table       VARCHAR2(30);
    vd_date_table       DATE;
    vv_sqlstmt          VARCHAR2(250);

    --------------------------------------------------------------
    -- Fonction qui vérifie qu'une chaine de caractère est bien --
    -- une date au format YYYYMMDDHHMISS                        --
    --------------------------------------------------------------
    FUNCTION is_date(pv_date VARCHAR2) RETURN BOOLEAN IS

      vd_date    DATE;
      vb_is_date BOOLEAN;

    BEGIN

      BEGIN
        vb_is_date := TRUE;

        SELECT TO_DATE(pv_date, 'YYYYMMDDHH24MISS') INTO vd_date FROM dual;

      EXCEPTION
        WHEN OTHERS THEN
          vb_is_date := FALSE;
      END;

      RETURN vb_is_date;

    END is_date;

  BEGIN

    OPEN cur_tables(pv_table_name);
    LOOP
      FETCH cur_tables
        INTO rec_tables;
      EXIT WHEN cur_tables%NOTFOUND;

      vn_longueur_prefixe := LENGTH(pv_table_name);
      vn_longueur_table   := LENGTH(rec_tables.table_name);

      -------------------------------------------------------------------------------
      -- Le nom de la table doit respester le format 'pv_table_nameYYYYMMDDHHMISS' --
      -- La longueur du nom de la table doit donc être égale à la longueur du      --
      -- préfixe + 14                                                              --
      -------------------------------------------------------------------------------
      IF vn_longueur_table = vn_longueur_prefixe + 14 THEN
        vv_date_table := SUBSTR(rec_tables.table_name,
                                vn_longueur_prefixe + 1,
                                14);

        -------------------------------------------------------------
        -- On vérifie que les 14 derniers caractères sont une date --
        -------------------------------------------------------------
        IF is_date(vv_date_table) THEN
          vd_date_table := TO_DATE(vv_date_table, 'YYYYMMDDHH24MISS');

          -----------------------------------------------
          -- On supprime les table de plus de 30 jours --
          -----------------------------------------------
          IF TRUNC(SYSDATE) - TRUNC(vd_date_table) > 30 THEN
            vv_sqlstmt := 'DROP TABLE ' || rec_tables.owner || '.' ||
                          rec_tables.table_name;
            EXECUTE IMMEDIATE vv_sqlstmt;
            Dka_Tools_Pkg.put_log_message('table ' || rec_tables.owner || '.' ||
                                          rec_tables.table_name ||
                                          ' supprimée');
          END IF;
        END IF;
      END IF;

    END LOOP;
    CLOSE cur_tables;

  END delete_save_tables;

  --------------------------------------------------------------------------
  -- Initialise les variables globales avec les valeurs venant de la table
  -- dka_parameters.
  -- JVI 21/12/2009 : Ajout Procédure
  --------------------------------------------------------------------------

  PROCEDURE init_params IS
    rec_params dka_parameters%rowtype;
    vn_retcode number;
    vv_errbuf  varchar2(255);
  BEGIN
    dka_tools_pkg.get_parameter(cv_program_code,
                                cv_param_name_due_date_l,
                                rec_params,
                                vn_retcode,
                                vv_errbuf);
    gd_effet_due_date_l := rec_params.date_value;
  END init_params;

  ----------------------------------------------------------------
  --  Nom           : GET_CODE_AGORA - fonction récopiée du SPE069 - DKA_IEOAPSAT01_APIMP_PKG
  --  Description   : fonction qui va retourner le code AGORA
  --
  --  PARAMETRES :
  --     pv_type               Entrée
  --     pv_division           Entrée
  --     pv_region             Entrée
  --     pv_societe            Entrée
  --     pv_default            Entrée
  -- VALEUR RETOURNEE :
  --     Description       : VARCHAR2
  --     Valeurs possibles : text
  ----------------------------------------------------------------
  /*FUNCTION get_code_agora(pv_type     VARCHAR2,
                          pv_division VARCHAR2,
                          pv_region   VARCHAR2,
                          pv_societe  VARCHAR2,
                          pv_default  VARCHAR2) RETURN VARCHAR2 IS

    vv_step VARCHAR2(500);

    CURSOR c_select_agora(cv_code_conso VARCHAR2) IS
      SELECT dsl.param1_value
        FROM dka_stransco_lines dsl, dka_stransco_headers dsh
       WHERE dsh.set_id = dsl.set_id
         AND trunc(SYSDATE) <= trunc(nvl(dsh.inactive_date, SYSDATE))
         AND (trunc(SYSDATE) between trunc(dsl.start_date) AND
             trunc(nvl(dsl.end_date, SYSDATE)))
         AND dsh.set_name = 'DKA_STE_AGORA_CONSO'
         AND dsl.return_value = cv_code_conso
         AND dsl.enable = 'Y';

    CURSOR c_select_conso(cv_region VARCHAR2, cv_societe VARCHAR2) IS
      SELECT code_conso, segmented_company
        FROM (SELECT ffvv.flex_value societe,
                     'DCW' region,
                     ffvv.attribute3 code_conso,
                     dbc.segmented_company
                FROM fnd_flex_value_sets ffvs,
                     fnd_flex_values_vl  ffvv,
                     dka_bdste_comptable dbc
               WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
                 AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                 AND ffvv.enabled_flag = 'Y'
                 AND SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
                     nvl(ffvv.end_date_active, SYSDATE)
                 AND ffvv.attribute3 IS NOT NULL
                 AND dbc.company_code = ffvv.flex_value
                 AND dbc.effective_date =
                     (SELECT MAX(dbc_d.effective_date)
                        FROM dka_bdste_comptable dbc_d
                       WHERE dbc_d.company_code = ffvv.flex_value)
              UNION
              SELECT ffvv.flex_value societe,
                     'DLS' region,
                     ffvv.attribute4 code_conso,
                     dbc.segmented_company
                FROM fnd_flex_value_sets ffvs,
                     fnd_flex_values_vl  ffvv,
                     dka_bdste_comptable dbc
               WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
                 AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                 AND ffvv.enabled_flag = 'Y'
                 AND SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
                     nvl(ffvv.end_date_active, SYSDATE)
                 AND ffvv.attribute4 IS NOT NULL
                 AND dbc.company_code = ffvv.flex_value
                 AND dbc.effective_date =
                     (SELECT MAX(dbc_d.effective_date)
                        FROM dka_bdste_comptable dbc_d
                       WHERE dbc_d.company_code = ffvv.flex_value)
              UNION
              SELECT ffvv.flex_value societe,
                     'DMS' region,
                     ffvv.attribute5 code_conso,
                     dbc.segmented_company
                FROM fnd_flex_value_sets ffvs,
                     fnd_flex_values_vl  ffvv,
                     dka_bdste_comptable dbc
               WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
                 AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                 AND ffvv.enabled_flag = 'Y'
                 AND SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
                     nvl(ffvv.end_date_active, SYSDATE)
                 AND ffvv.attribute5 IS NOT NULL
                 AND dbc.company_code = ffvv.flex_value
                 AND dbc.effective_date =
                     (SELECT MAX(dbc_d.effective_date)
                        FROM dka_bdste_comptable dbc_d
                       WHERE dbc_d.company_code = ffvv.flex_value)
              UNION
              SELECT ffvv.flex_value societe,
                     'DRW' region,
                     ffvv.attribute6 code_conso,
                     dbc.segmented_company
                FROM fnd_flex_value_sets ffvs,
                     fnd_flex_values_vl  ffvv,
                     dka_bdste_comptable dbc
               WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
                 AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                 AND ffvv.enabled_flag = 'Y'
                 AND SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
                     nvl(ffvv.end_date_active, SYSDATE)
                 AND ffvv.attribute6 IS NOT NULL
                 AND dbc.company_code = ffvv.flex_value
                 AND dbc.effective_date =
                     (SELECT MAX(dbc_d.effective_date)
                        FROM dka_bdste_comptable dbc_d
                       WHERE dbc_d.company_code = ffvv.flex_value)
              UNION
              SELECT ffvv.flex_value societe,
                     'DSW' region,
                     ffvv.attribute7 code_conso,
                     dbc.segmented_company
                FROM fnd_flex_value_sets ffvs,
                     fnd_flex_values_vl  ffvv,
                     dka_bdste_comptable dbc
               WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
                 AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                 AND ffvv.enabled_flag = 'Y'
                 AND SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
                     nvl(ffvv.end_date_active, SYSDATE)
                 AND ffvv.attribute7 IS NOT NULL
                 AND dbc.company_code = ffvv.flex_value
                 AND dbc.effective_date =
                     (SELECT MAX(dbc_d.effective_date)
                        FROM dka_bdste_comptable dbc_d
                       WHERE dbc_d.company_code = ffvv.flex_value)
              UNION
              SELECT ffvv.flex_value societe,
                     'GFK' region,
                     ffvv.attribute8 code_conso,
                     dbc.segmented_company
                FROM fnd_flex_value_sets ffvs,
                     fnd_flex_values_vl  ffvv,
                     dka_bdste_comptable dbc
               WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
                 AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                 AND ffvv.enabled_flag = 'Y'
                 AND SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
                     nvl(ffvv.end_date_active, SYSDATE)
                 AND ffvv.attribute8 IS NOT NULL
                 AND dbc.company_code = ffvv.flex_value
                 AND dbc.effective_date =
                     (SELECT MAX(dbc_d.effective_date)
                        FROM dka_bdste_comptable dbc_d
                       WHERE dbc_d.company_code = ffvv.flex_value)
              --> JJA 15/11/2012
              UNION
              SELECT ffvv.flex_value societe,
                     'DEW' region,
                     ffvv.attribute11 code_conso,
                     dbc.segmented_company
                FROM fnd_flex_value_sets ffvs,
                     fnd_flex_values_vl  ffvv,
                     dka_bdste_comptable dbc
               WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
                 AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                 AND ffvv.enabled_flag = 'Y'
                 AND SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
                     nvl(ffvv.end_date_active, SYSDATE)
                 AND ffvv.attribute11 IS NOT NULL
                 AND dbc.company_code = ffvv.flex_value
                 AND dbc.effective_date =
                     (SELECT MAX(dbc_d.effective_date)
                        FROM dka_bdste_comptable dbc_d
                       WHERE dbc_d.company_code = ffvv.flex_value)
              UNION
              SELECT ffvv.flex_value societe,
                     'DNA' region,
                     ffvv.attribute12 code_conso,
                     dbc.segmented_company
                FROM fnd_flex_value_sets ffvs,
                     fnd_flex_values_vl  ffvv,
                     dka_bdste_comptable dbc
               WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
                 AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                 AND ffvv.enabled_flag = 'Y'
                 AND SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
                     nvl(ffvv.end_date_active, SYSDATE)
                 AND ffvv.attribute12 IS NOT NULL
                 AND dbc.company_code = ffvv.flex_value
                 AND dbc.effective_date =
                     (SELECT MAX(dbc_d.effective_date)
                        FROM dka_bdste_comptable dbc_d
                       WHERE dbc_d.company_code = ffvv.flex_value)
              UNION
              SELECT ffvv.flex_value societe,
                     'DOS' region,
                     ffvv.attribute13 code_conso,
                     dbc.segmented_company
                FROM fnd_flex_value_sets ffvs,
                     fnd_flex_values_vl  ffvv,
                     dka_bdste_comptable dbc
               WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
                 AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                 AND ffvv.enabled_flag = 'Y'
                 AND SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
                     nvl(ffvv.end_date_active, SYSDATE)
                 AND ffvv.attribute13 IS NOT NULL
                 AND dbc.company_code = ffvv.flex_value
                 AND dbc.effective_date =
                     (SELECT MAX(dbc_d.effective_date)
                        FROM dka_bdste_comptable dbc_d
                       WHERE dbc_d.company_code = ffvv.flex_value)
              --< JJA 15/11/2012
              ) v
       WHERE v.societe = cv_societe
         and v.region = cv_region;

    CURSOR c_db_select_conso(cv_societe VARCHAR2) IS
      SELECT dbdg.consumption_code, dbdg.company_type
        FROM dka_bdste_donnees_gen dbdg
       WHERE dbdg.company_code = cv_societe
         AND dbdg.effective_date =
             (SELECT MAX(d.effective_date)
                FROM dka_bdste_donnees_gen d
               WHERE d.company_code = dbdg.company_code);

    CURSOR c_select_carat(cv_societe VARCHAR2, cv_set_name VARCHAR2) IS
      SELECT ffvv.attribute1 code_conso
        FROM fnd_flex_value_sets ffvs, fnd_flex_values_vl ffvv
       WHERE ffvs.flex_value_set_name = cv_set_name
         AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
         AND ffvv.enabled_flag = 'Y'
         AND SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
             nvl(ffvv.end_date_active, SYSDATE)
         AND ffvv.flex_value = cv_societe;

    --
    lv_code_conso       fnd_flex_values_vl.attribute1%TYPE;
    lv_code_conso_bd    fnd_flex_values_vl.attribute1%TYPE;
    lv_code_conso_cible fnd_flex_values_vl.attribute1%TYPE;
    l_code_agora        VARCHAR2(50);
    lv_segmente         dka_bdste_comptable.segmented_company%TYPE;
    lv_gere             dka_bdste_donnees_gen.company_type%TYPE;

  BEGIN
    vv_step := '001 : GET_CODE_AGORA début';
    dka_tools_pkg.put_debug_message(vv_step);

    vv_step := '002 : paramètres : ' || pv_type || '/' || pv_division || '/' ||
               pv_region || '/' || pv_societe;
    dka_tools_pkg.put_debug_message(vv_step);

    vv_step := '003 : récupération des valeurs';
    dka_tools_pkg.put_debug_message(vv_step);

    --CODE CONSO
    OPEN c_select_conso(pv_region, pv_societe);
    FETCH c_select_conso
      INTO lv_code_conso, lv_segmente;
    CLOSE c_select_conso;

    vv_step := '004 : code conso JDV / SEGMENTEE : ' || lv_code_conso || '/' ||
               lv_segmente;
    dka_tools_pkg.put_debug_message(vv_step);

    --CODE CONSO DB
    OPEN c_db_select_conso(pv_societe);
    FETCH c_db_select_conso
      INTO lv_code_conso_bd, lv_gere;
    CLOSE c_db_select_conso;

    vv_step := '005 : code conso BD / GEREE : ' || lv_code_conso_bd || '/' ||
               lv_gere;
    dka_tools_pkg.put_debug_message(vv_step);

    vv_step := '006 : Début condition';
    dka_tools_pkg.put_debug_message(vv_step);
    IF pv_division = 'DK' THEN

      IF pv_type IS NULL THEN

        IF lv_segmente = 'N' THEN
          lv_code_conso_cible := lv_code_conso_bd;
        ELSE
          lv_code_conso_cible := lv_code_conso;
        END IF;

      ELSIF pv_type = 'GROUPE' THEN
        --RG GROUPE
        --1)
        IF nvl(lv_segmente, '#') = 'O' THEN
          lv_code_conso_cible := lv_code_conso;
          --2)
        ELSIF nvl(lv_segmente, '#') = 'N' AND nvl(lv_gere, -1) IN (0, 1) --05/11/2012 JJA
         THEN
          lv_code_conso_cible := lv_code_conso_bd;
          --3)
          IF lv_code_conso_cible IS NULL THEN
            OPEN c_select_carat(pv_societe, 'DAOPCCF_COMPLEMENT');
            FETCH c_select_carat
              INTO lv_code_conso_cible;
            CLOSE c_select_carat;
          END IF; --fin 3)
        ELSE
          OPEN c_select_carat(pv_societe, 'DAOPCCF_COMPLEMENT');
          FETCH c_select_carat
            INTO lv_code_conso_cible;
          CLOSE c_select_carat;
        END IF; --fin 1) et 2)

      END IF;*/

/*    ELSIF pv_division IN ('VT', 'VP') THEN

      IF pv_type is null then

        lv_code_conso_cible := lv_code_conso_bd;

      ELSIF pv_type = 'GROUPE' THEN

        IF lv_gere in ('0', '1') THEN
          lv_code_conso_cible := lv_code_conso_bd;
        ELSE

          IF pv_division = 'VP' THEN
            OPEN c_select_carat(pv_societe, 'VPOPCCF_COMPLEMENT');
            FETCH c_select_carat
              INTO lv_code_conso_cible;
            CLOSE c_select_carat;
          ELSIF pv_division = 'VT' THEN
            OPEN c_select_carat(pv_societe, 'VTOPCCF_COMPLEMENT');
            FETCH c_select_carat
              INTO lv_code_conso_cible;
            CLOSE c_select_carat;
          END IF;

        END IF; --lv_gere
      END IF; --pv_type*/

    /*END IF; --pv_division

    vv_step := '007 : code conso cible : ' || lv_code_conso_cible;
    dka_tools_pkg.put_debug_message(vv_step);

    OPEN c_select_agora(lv_code_conso_cible);
    FETCH c_select_agora
      INTO l_code_agora;

    vv_step := '008 : Controle de valeur multiple';
    dka_tools_pkg.put_debug_message(vv_step);
    IF l_code_agora IS NOT NULL THEN
      FETCH c_select_agora
        INTO l_code_agora;
      IF c_select_agora%FOUND THEN
        vv_step := '009 : valeur multiple';
        dka_tools_pkg.put_debug_message(vv_step);
        l_code_agora := pv_default;
      END IF;
    END IF;

    CLOSE c_select_agora;

    vv_step := '010 : code agora cible : ' || l_code_agora;
    dka_tools_pkg.put_debug_message(vv_step);

    vv_step := '999 : GET_CODE_AGORA fin';
    dka_tools_pkg.put_debug_message(vv_step);

    RETURN nvl(l_code_agora, pv_default);

  EXCEPTION
    WHEN OTHERS THEN
      dka_tools_pkg.put_debug_message(vv_step || ' : ' || SQLERRM);
      RAISE;
  END get_code_agora;*/

  -----------------------------------------------------------------
  --  Nom           : get_printer_name
  --  Description   : Procédure permettant de determiner l'imprimante
  --
  --  PARAMETRES :
  --     pv_user_name       Sortie  --> Varchar2
  --
  --  VALEUR RETOURNEE :
  --
  -----------------------------------------------------------------
  FUNCTION get_printer_name(pv_user_name  varchar2,
                            pv_region     varchar2) RETURN varchar2 IS
    vn_user_id   number;
    vv_printer   fnd_profile_option_values.profile_option_value%type;
  BEGIN

    vv_printer := Dka_Stransco_Pkg.etl_get_value_f('AR_IMPRIMANTE_TRESO',
                                                   SYSDATE,
                                                   pv_region,
                                                   'PRELEVEMENT_CLIENT',
                                                   NULL);
    IF vv_printer IS NULL THEN
      BEGIN
        SELECT user_id
        INTO vn_user_id
        FROM fnd_user
        WHERE user_name = pv_user_name;

      EXCEPTION
        WHEN OTHERS THEN
          vn_user_id := -1;
      END;

      vv_printer := Fnd_Profile.value_specific('PRINTER',
                                               vn_user_id,
                                               NULL,
                                               NULL);
    END IF;

    RETURN vv_printer;

  END get_printer_name;

  -----------------------------------------------------------------
  --  Nom           : create_seq_prlv_ar
  --  Description   : Creation des sequences de prelevements AR
  --
  --  PARAMETRES :
  --     pv_user_name       Sortie  --> Varchar2
  --
  --  VALEUR RETOURNEE :
  --
  -----------------------------------------------------------------
/*
  PROCEDURE create_seq_prlv_ar(pn_retcode IN OUT NOCOPY NUMBER,
                               pv_errbuf  IN OUT NOCOPY VARCHAR2) IS

    vv_application_name fnd_application_tl.application_name%TYPE := 'Oracle Receivables';
    vn_application_id   fnd_application_tl.application_id%TYPE;
    vn_flag_insert      NUMBER := 0;
    vv_year             VARCHAR2(4);
    vv_seqname          fnd_document_sequences.name%TYPE;
    vv_seqtype          fnd_document_sequences.type%TYPE := 'A';
    --      vv_initval              fnd_document_sequences.initial_value%TYPE := '8000001'; -- SL 03/02/2010
    vv_initval    fnd_document_sequences.initial_value%TYPE;
    vv_msg_error  VARCHAR2(1000);
    vv_sob_name   gl_sets_of_books.short_name%TYPE := 'DALKIA_OPE';
    vn_sob_id     gl_sets_of_books.set_of_books_id%TYPE;
    vv_meth_code  fnd_doc_sequence_assignments.method_code%TYPE := null;
    vn_docSeqId   fnd_document_sequences.doc_sequence_id%TYPE;
    vn_exist      NUMBER := 0;
    vv_start_date VARCHAR2(10);
    vv_end_date   VARCHAR2(10);
    vv_decennie   VARCHAR2(2);

    CURSOR cur_societe IS
      SELECT ffv1.flex_value      societe,
             hou.organization_id  org_id,
             gsob.set_of_books_id sob_id,
             gsob.short_name      sob_sname
        FROM gl_sets_of_books          gsob,
             fnd_id_flex_segments      fifs1,
             fnd_flex_values           ffv1,
             hr_all_organization_units hou
       WHERE gsob.set_of_books_id = vn_sob_id
         AND fifs1.application_id = 101
         AND fifs1.id_flex_code = 'GL#'
         AND fifs1.id_flex_num = gsob.chart_of_accounts_id
         AND fifs1.application_column_name = 'SEGMENT1'
         AND ffv1.flex_value_set_id = fifs1.flex_value_set_id
         AND trunc(SYSDATE) BETWEEN
             nvl(ffv1.start_date_active, trunc(SYSDATE)) AND
             nvl(ffv1.end_date_active, trunc(SYSDATE))
         AND ffv1.enabled_flag = 'Y'
         AND ffv1.summary_flag = 'N'
         AND hou.name = ffv1.flex_value
            ---------- !!!! POUR TEST !!!!! ----------
            --AND    ffv1.flex_value = '0040'
            ---------- !!!! POUR TEST !!!!! ----------
         AND ffv1.flex_value IN
             (SELECT DISTINCT dit.company_code
                FROM dka_ibdsoc_i00dgic          dii,
                     dka_ibdsoc_territorialities dit,
                     dka_ibdsoc_general_info     digi
               WHERE dii.company_code = dit.company_code
                 AND dii.company_type = 0
                 AND digi.company_code = dii.company_code
                 AND digi.segmented_company_flag = 'Y'
              UNION
              SELECT digi.company_code
                FROM dka_ibdsoc_general_info digi, dka_ibdsoc_i00dgic dii
               WHERE digi.segmented_company_flag = 'N'
                 AND dii.company_code = digi.company_code
                 AND dii.company_type = 0)
       ORDER BY ffv1.flex_value;

    CURSOR cur_categ IS
      SELECT code, name, application_id
        FROM fnd_doc_sequence_categories
       WHERE name LIKE '%PRELEV%';

    e_application EXCEPTION;
    e_error_fatal EXCEPTION;
    e_sequence EXCEPTION;

  BEGIN
    -- Recuperation de l'annee en cours
    SELECT to_char(SYSDATE, 'RRRR') INTO vv_year FROM dual;
    DKA_TOOLS_PKG.put_log_message('Année=' || vv_year);
    vv_start_date := '01/01/' || vv_year;
    vv_end_date   := '31/12/' || vv_year;

    -- Calcul de la valeur initiale de la séquence XX000001 (où XX correspond à la décénnie)
    select to_char(SYSDATE, 'RR') --Récupération des 2 derniers chiffres de l'année en cours
      into vv_decennie
      from dual;

    vv_initval := vv_decennie || '000001';

    -- Recuperation de l'application id
    BEGIN
      SELECT application_id
        INTO vn_application_id
        FROM fnd_application_tl
       WHERE application_name = vv_application_name
         AND LANGUAGE = 'F';
    EXCEPTION
      WHEN others THEN
        vv_msg_error := SUBSTR(SQLERRM, 1, 1000);
        RAISE e_application;
    END;

    -- Récuperation du sob id
    SELECT set_of_books_id
      INTO vn_sob_id
      FROM gl_sets_of_books
     WHERE short_name = vv_sob_name;

    DKA_TOOLS_PKG.put_log_message('Création/Vérification des séquences');
    FOR rec_societe IN cur_societe LOOP
      BEGIN
        vv_msg_error := null;
        vv_seqname   := rec_societe.societe || '_PRELEVEMENT_AR_' ||
                        vv_year;

        -- Appel de l'api de creation des sequences
        vn_flag_insert := fnd_seqnum.define_doc_seq(app_id      => vn_application_id,
                                                    docseq_name => vv_seqname,
                                                    docseq_type => vv_seqtype,
                                                    msg_flag    => 'N',
                                                    init_value  => vv_initval,
                                                    p_startDate => to_date(vv_start_date,
                                                                           'DD/MM/RRRR'),
                                                    p_endDate   => to_date(vv_end_date,
                                                                           'DD/MM/RRRR'));
        -- Vérification du code retour de l'API
        IF vn_flag_insert = fnd_seqnum.SEQSUCC THEN
          DKA_TOOLS_PKG.put_log_message('Séquence ' || vv_seqname ||
                                        ' créée.');
        ELSIF vn_flag_insert = fnd_seqnum.DUPNAME THEN
          -- si la sequence a deja été creee, ne pas afficher de message de
          -- log (artf420553)
          NULL;
        ELSIF vn_flag_insert = fnd_seqnum.BADAPPID THEN
          vv_msg_error := 'L''application_id ' || vn_application_id ||
                          ' n''est pas valide.';
          RAISE e_error_fatal;
        ELSIF vn_flag_insert = fnd_seqnum.BADTYPE THEN
          vv_msg_error := 'Le type de sequence ' || vv_seqtype ||
                          ' n''est pas valide.';
          RAISE e_error_fatal;
        ELSIF vn_flag_insert = fnd_seqnum.BADFLAG THEN
          vv_msg_error := 'Le flag message ' || '"non"' ||
                          ' n''est pas valide.';
          RAISE e_error_fatal;
        ELSIF vn_flag_insert = fnd_seqnum.BADDATE THEN
          vv_msg_error := 'Les dates de debut et fin ne sont pas valides.';
          RAISE e_error_fatal;
        ELSIF vn_flag_insert = fnd_seqnum.ORAFAIL THEN
          vv_msg_error := SUBSTR(fnd_message.get, 1, 1000);
          RAISE e_error_fatal;
        ELSE
          vv_msg_error := 'Code retour de FND_SEQNUM.DEFINE_DOC_SEQ ' ||
                          vn_flag_insert || ' inconnu.';
          RAISE e_error_fatal;
        END IF;

      EXCEPTION
        WHEN e_error_fatal THEN
          DKA_TOOLS_PKG.put_log_message(substr(vv_msg_error, 1, 255));
          pv_errbuf := vv_msg_error;
        WHEN OTHERS THEN
          DKA_TOOLS_PKG.put_log_message(SUBSTR('L''erreur suivante s''est produite lors de la création de la séquence => ' ||
                                               SQLERRM,
                                               1,
                                               255));
          pv_errbuf := 'L''erreur suivante s''est produite lors de la création de la séquence => ' ||
                       SQLERRM;
      END;
    END LOOP;

    COMMIT;
    fnd_seqnum.create_gapless_sequences;

    --DKA_TOOLS_PKG.put_log_message('Les séquences ont été créées avec succès.'||chr(10));

    DKA_TOOLS_PKG.put_log_message(chr(10) || 'Affectation des séquences');

    FOR rec_categ IN cur_categ LOOP
      BEGIN
        vn_exist     := 0;
        vv_msg_error := null;

        DKA_TOOLS_PKG.put_log_message('Catégorie : ' || rec_categ.name);
        -- Recuperation du nom de la séquence
        BEGIN
          SELECT fds.name
            INTO vv_seqname
            FROM FND_DOCUMENT_SEQUENCES FDS
           WHERE fds.application_id = vn_application_id
             AND fds.name = substr(rec_categ.code, 1, 4) ||
                 '_PRELEVEMENT_AR_' || vv_year;
          DKA_TOOLS_PKG.put_log_message('Séquence : ' || vv_seqname);
        EXCEPTION
          WHEN no_data_found THEN
            vv_msg_error := 'Pas de séquence à associer à la categorie ' ||
                            rec_categ.name;
            RAISE e_sequence;
          WHEN OTHERS THEN
            vv_msg_error := SUBSTR(SQLERRM, 1, 1000);
            RAISE e_sequence;
        END;

        -- Affectation
        vn_flag_insert := FND_SEQNUM.assign_doc_seq(app_id      => vn_application_id,
                                                    docseq_name => vv_seqname,
                                                    cat_code    => rec_categ.code,
                                                    sob_id      => vn_sob_id,
                                                    met_code    => vv_meth_code,
                                                    p_startDate => to_date(vv_start_date,
                                                                           'DD/MM/RRRR'),
                                                    p_endDate   => to_date(vv_end_date,
                                                                           'DD/MM/RRRR'));

        -- Controle du code retour de l'API
        IF vn_flag_insert = fnd_seqnum.SEQSUCC THEN
          DKA_TOOLS_PKG.put_log_message('Catégorie ' || rec_categ.name ||
                                        ' associée avec la séquence ' ||
                                        vv_seqname);
        ELSIF vn_flag_insert = fnd_seqnum.DUPNAME THEN
          DKA_TOOLS_PKG.put_log_message('Catégorie ' || rec_categ.name ||
                                        ' associée avec la séquence ' ||
                                        vv_seqname);
        ELSIF vn_flag_insert = fnd_seqnum.BADAPPID THEN
          vv_msg_error := 'L''application_id ' || vn_application_id ||
                          ' n''est pas valide.';
          RAISE e_error_fatal;
        ELSIF vn_flag_insert = fnd_seqnum.BADNAME THEN
          vv_msg_error := 'La sequence name ' || vv_seqname ||
                          ' n''est pas valide.';
          RAISE e_error_fatal;
        ELSIF vn_flag_insert = fnd_seqnum.BADCODE THEN
          vv_msg_error := 'Le code categorie ' || rec_categ.code ||
                          ' n''est pas valide.';
          RAISE e_error_fatal;
        ELSIF vn_flag_insert = fnd_seqnum.BADSOB THEN
          vv_msg_error := 'L''entité comptable ' || vv_sob_name ||
                          ' n''est pas valide.';
          RAISE e_error_fatal;
        ELSIF vn_flag_insert = fnd_seqnum.BADMTHD THEN
          vv_msg_error := 'La méthode ' || vv_meth_code ||
                          ' n''est pas valide.';
          RAISE e_error_fatal;
        ELSIF vn_flag_insert = fnd_seqnum.BADDATE THEN
          --vv_msg_error := 'Les dates de debut : '||Rs_CSSA.date_de_debut||' et fin : '||Rs_CSSA.date_de_fin||' ne sont pas valides.';
          -- ** Calcul des variables
          SELECT doc_sequence_id
            INTO vn_docSeqId
            FROM fnd_document_sequences
           WHERE NAME = vv_seqname;
          -- ** Calcul des variables
          SELECT COUNT(1)
            INTO vn_exist
            FROM FND_DOC_SEQUENCE_ASSIGNMENTS fdsa
           WHERE fdsa.application_id = vn_application_id
             AND fdsa.doc_sequence_id = vn_docSeqId
             AND fdsa.category_code = rec_categ.code
             AND fdsa.set_of_books_id = vn_sob_id
             AND nvl(fdsa.method_code, 'X') = nvl(vv_meth_code, 'X')
          --AND nvl(fdsa.start_date,'01/01/2005')= nvl(Rs_CSSA.date_de_debut, '01/01/2005')
          --                     AND nvl(fdsa.end_date,'01/01/2005') = nvl(Rs_CSSA.date_de_fin,'01/01/2005')
          ;

          IF vn_exist = 0 THEN
            vv_msg_error := SUBSTR(fnd_message.get, 1, 1000);
            vv_msg_error := SUBSTR(vv_msg_error,
                                   1,
                                   INSTR(vv_msg_error, CHR(10)) - 1);
            RAISE e_error_fatal;
          ELSE
            DKA_TOOLS_PKG.put_log_message('Catégorie ' || rec_categ.name ||
                                          ' associée avec la séquence ' ||
                                          vv_seqname);
          END IF;
        ELSIF vn_flag_insert = fnd_seqnum.ORAFAIL THEN
          vv_msg_error := SUBSTR(fnd_message.get, 1, 1000);
          RAISE e_error_fatal;
        ELSE
          vv_msg_error := 'Code retour de FND_SEQNUM.DEFINE_DOC_SEQ ' ||
                          vn_flag_insert || ' inconnu.';
          RAISE e_error_fatal;
        END IF;

      EXCEPTION
        WHEN e_sequence THEN
          DKA_TOOLS_PKG.put_log_message(substr(vv_msg_error, 1, 255));
        WHEN e_error_fatal THEN
          DKA_TOOLS_PKG.put_log_message(substr(vv_msg_error, 1, 255));
        WHEN OTHERS THEN
          DKA_TOOLS_PKG.put_log_message(SUBSTR('L''erreur suivante s''est produite lors de l''affectation de la séquence => ' ||
                                               SQLERRM,
                                               1,
                                               255));
      END;
    END LOOP;

    DKA_TOOLS_PKG.put_log_message('Les séquences ont été associées aux catégories avec succès.');

  EXCEPTION
    WHEN e_application THEN
      DKA_TOOLS_PKG.put_log_message('Erreur lors de la recherche de l''identifiant de l''application : ' ||
                                    vv_application_name);
      DKA_TOOLS_PKG.put_log_message(vv_msg_error);
      pv_errbuf  := 'L''erreur suivante s''est produite lors de la création de la séquence => ' ||
                    vv_msg_error;
      pn_retcode := 1;
    WHEN OTHERS THEN
      DKA_TOOLS_PKG.put_log_message(SQLERRM);
      pv_errbuf  := 'L''erreur suivante s''est produite lors de la création de la séquence => ' ||
                    SQLERRM;
      pn_retcode := 1;
  END create_seq_prlv_ar;
*/

  ------------------------------------------------------------------------------
  --  Description : Execute le traitement OA de création des remises
  --                automatiques (ARZCAR_REMIT_SRS)
  --
  --  Parametres  : pv_prog_application_short_name  nom court de l'application
  --                pv_last_day_month               date gl du lot
  --                pn_receipt_class_id             classe de reglements
  --                pn_receipt_method_id            mode de reglement
  --                pn_bank_branch_id               agence bancaire de remise
  --                pn_bank_account_id              numero de compte de remise
  --                pn_retcode                      statut de sortie (0 si ok,
  --                                                > 0 sinon)
  --                pv_errbuf                       message d'erreur si statut
  --                                                de sortie > 0)
  ------------------------------------------------------------------------------
  PROCEDURE create_remit(pv_prog_application_short_name IN fnd_application.application_short_name%TYPE,
                         pv_last_day_month              IN VARCHAR2,
                         pn_receipt_class_id            IN ar_receipt_classes.receipt_class_id%TYPE,
                         pn_receipt_method_id           IN ar_receipt_methods.receipt_method_id%TYPE,
                         pn_bank_branch_id              IN ap_bank_branches.bank_branch_id%TYPE,
                         pn_bank_account_id             IN ap_bank_accounts_all.bank_account_id%TYPE,
                         pv_date_echeance               IN VARCHAR2, --JVI 21/12/2009
                         pn_org_id                      IN NUMBER, -- Correction org_id
                         pn_request_id                  OUT NUMBER, --> GV20090324 : ajout de ce paramètre pour récup request_id
                         pn_retcode                     IN OUT NOCOPY NUMBER,
                         pv_errbuf                      IN OUT NOCOPY VARCHAR2) IS

    l_request_id NUMBER(15);
    cn_tempo CONSTANT NUMBER := 20;
    l_rphase  VARCHAR2(80);
    l_rstatus VARCHAR2(80);
    l_dphase  VARCHAR2(30);
    l_dstatus VARCHAR2(30);
    l_message VARCHAR2(240);
  BEGIN

    --Positionnement de l'organisation

    po_moac_utils_pvt.set_org_context(pn_org_id);
    MO_GLOBAL.INIT('AR');

    fnd_request.set_org_id(pn_org_id);


    l_request_id := fnd_request.submit_request( application => pv_prog_application_short_name,
                                                program     => 'AUTOREMAPI',--'ARZCAR_REMIT_SRS',
                                                description => NULL,
                                                start_time  => NULL,
                                                sub_request => FALSE,
                                                argument1   => 'REMIT',
                                                argument2   => fnd_date.date_to_canonical(SYSDATE),
                                                argument3   => pv_last_day_month,
                                                argument4   => 'Y',
                                                argument5   => 'Y',
                                                argument6   => 'Y',
                                                argument7   => NULL,
                                                argument8   => NULL,
                                                argument9   => 'EUR',
                                                argument10  => NULL,
                                                argument11  => NULL,
                                                argument12  => NULL,
                                                argument13  => 'STANDARD',
                                                argument14  => pn_receipt_class_id,
                                                argument15  => pn_receipt_method_id,
                                                argument16  => NULL,
                                                argument17  => pn_bank_branch_id,
                                                argument18  => pn_bank_account_id,
                                                argument19  => NULL,
                                                argument20  => 'Règlement automatique : ' ||pn_receipt_class_id || ' - ' ||pn_receipt_method_id,
                                                argument21  => NULL,
                                                argument22  => NULL,
                                                argument23  => fnd_date.date_to_canonical(gd_effet_due_date_l),
                                                argument24  => fnd_date.date_to_canonical(to_date(pv_date_echeance,'YYYYMMDD')),
                                                argument25  => NULL, --low
                                                argument26  => NULL, --high
                                                argument27  => NULL,
                                                argument28  => NULL,
                                                argument29  => NULL,
                                                argument30  => NULL,
                                                argument31  => NULL,
                                                argument32  => NULL,
                                                argument33  => NULL,
                                                argument34  => NULL,
                                                argument35  => NULL,
                                                argument36  => NULL,
                                                argument37  => NULL,
                                                argument38  => NULL,
                                                argument39  => NULL,
                                                argument40  => NULL,
                                                argument41  => NULL,
                                                argument42  => NULL);

    DKA_TOOLS_PKG.put_log_message('Validation pour que les GTS puissent prendre la demande');
    COMMIT;

    IF (l_request_id = 0) THEN
      pn_retcode := 2;
      pv_errbuf  := 'Impossible de lancer le Traitement ';
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
    END IF;

    DKA_TOOLS_PKG.put_log_message('Traitement numero : ' ||
                                  TO_CHAR(l_request_id));

    -- Ajout GV20090324 : on récupére le request_id pour la procédure de réimpression
    pn_request_id := l_request_id;

    IF NOT fnd_concurrent.wait_for_request(l_request_id,
                                           cn_tempo,
                                           0,
                                           l_rphase,
                                           l_rstatus,
                                           l_dphase,
                                           l_dstatus,
                                           l_message) THEN
      pn_retcode := 2;
      pv_errbuf  := 'Erreur wait_for_request.';
    ELSE
      IF l_dstatus = 'WARNING' THEN
        DKA_TOOLS_PKG.put_log_message(CHR(10) ||
                                      '>>> Traitement termine en Warning ');
        pn_retcode := 1;
      ELSIF l_dstatus != 'NORMAL' THEN
        DKA_TOOLS_PKG.put_log_message(CHR(10) ||
                                      '>>> Traitement termine en Erreur ');
        pn_retcode := 2;
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Erreur inattendue lors de la création des remises automatiques ' ||
                    SQLERRM;
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
  END create_remit;


  --ARA EDB379
   ------------------------------------------------------------------------------
  --  Description : Execute le traitement OA de création des remises
  --                automatiques (ARZCAR_REMIT_SRS)
  --
  --  Parametres  : pv_prog_application_short_name  nom court de l'application
  --                pv_last_day_month               date gl du lot
  --                pn_receipt_class_id             classe de reglements
  --                pn_receipt_method_id            mode de reglement
  --                pn_bank_branch_id               agence bancaire de remise
  --                pn_bank_account_id              numero de compte de remise
  --                pn_retcode                      statut de sortie (0 si ok,
  --                                                > 0 sinon)
  --                pv_errbuf                       message d'erreur si statut
  --                                                de sortie > 0)
  ------------------------------------------------------------------------------
  PROCEDURE create_remit_express(pv_prog_application_short_name IN fnd_application.application_short_name%TYPE,
                         pv_last_day_month              IN VARCHAR2,
                         pn_receipt_class_id            IN ar_receipt_classes.receipt_class_id%TYPE,
                         pn_receipt_method_id           IN ar_receipt_methods.receipt_method_id%TYPE,
                         pn_bank_branch_id              IN ap_bank_branches.bank_branch_id%TYPE,
                         pn_bank_account_id             IN ap_bank_accounts_all.bank_account_id%TYPE,
                         pv_date_echeance               IN VARCHAR2, --JVI 21/12/2009
             pv_receipt_number              IN VARCHAR2,
                         pn_org_id                      IN NUMBER, -- Correction org_id
                         pn_request_id                  OUT NUMBER, --> GV20090324 : ajout de ce paramètre pour récup request_id
                         pn_retcode                     IN OUT NOCOPY NUMBER,
                         pv_errbuf                      IN OUT NOCOPY VARCHAR2) IS

    l_request_id NUMBER(15);
    cn_tempo CONSTANT NUMBER := 20;
    l_rphase  VARCHAR2(80);
    l_rstatus VARCHAR2(80);
    l_dphase  VARCHAR2(30);
    l_dstatus VARCHAR2(30);
    l_message VARCHAR2(240);
  BEGIN

    --Positionnement de l'organisation

    po_moac_utils_pvt.set_org_context(pn_org_id);
    MO_GLOBAL.INIT('AR');

    fnd_request.set_org_id(pn_org_id);


    l_request_id := fnd_request.submit_request( application => pv_prog_application_short_name,
                                                program     => 'AUTOREMAPI',--'ARZCAR_REMIT_SRS',
                                                description => NULL,
                                                start_time  => NULL,
                                                sub_request => FALSE,
                                                argument1   => 'REMIT',
                                                argument2   => fnd_date.date_to_canonical(SYSDATE),
                                                argument3   => pv_last_day_month,
                                                argument4   => 'Y',
                                                argument5   => 'Y',
                                                argument6   => 'Y',
                                                argument7   => NULL,
                                                argument8   => NULL,
                                                argument9   => 'EUR',
                                                argument10  => NULL,
                                                argument11  => NULL,
                                                argument12  => NULL,
                                                argument13  => 'STANDARD',
                                                argument14  => pn_receipt_class_id,
                                                argument15  => pn_receipt_method_id,
                                                argument16  => NULL,
                                                argument17  => pn_bank_branch_id,
                                                argument18  => pn_bank_account_id,
                                                argument19  => NULL,
                                                argument20  => 'Règlement automatique : ' ||pn_receipt_class_id || ' - ' ||pn_receipt_method_id,
                                                argument21  => NULL,
                                                argument22  => NULL,
                                                argument23  => fnd_date.date_to_canonical(gd_effet_due_date_l),
                                                argument24  => fnd_date.date_to_canonical(to_date(pv_date_echeance,'YYYYMMDD')),
                                                argument25  => pv_receipt_number, --low
                                                argument26  => pv_receipt_number, --high
                                                argument27  => NULL,
                                                argument28  => NULL,
                                                argument29  => NULL,
                                                argument30  => NULL,
                                                argument31  => NULL,
                                                argument32  => NULL,
                                                argument33  => NULL,
                                                argument34  => NULL,
                                                argument35  => NULL,
                                                argument36  => NULL,
                                                argument37  => NULL,
                                                argument38  => NULL,
                                                argument39  => NULL,
                                                argument40  => NULL,
                                                argument41  => NULL,
                                                argument42  => NULL);

    DKA_TOOLS_PKG.put_log_message('Validation pour que les GTS puissent prendre la demande');
    COMMIT;

    IF (l_request_id = 0) THEN
      pn_retcode := 2;
      pv_errbuf  := 'Impossible de lancer le Traitement ';
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
    END IF;

    DKA_TOOLS_PKG.put_log_message('Traitement numero : ' ||
                                  TO_CHAR(l_request_id));

    -- Ajout GV20090324 : on récupére le request_id pour la procédure de réimpression
    pn_request_id := l_request_id;

    IF NOT fnd_concurrent.wait_for_request(l_request_id,
                                           cn_tempo,
                                           0,
                                           l_rphase,
                                           l_rstatus,
                                           l_dphase,
                                           l_dstatus,
                                           l_message) THEN
      pn_retcode := 2;
      pv_errbuf  := 'Erreur wait_for_request.';
    ELSE
      IF l_dstatus = 'WARNING' THEN
        DKA_TOOLS_PKG.put_log_message(CHR(10) ||
                                      '>>> Traitement termine en Warning ');
        pn_retcode := 1;
      ELSIF l_dstatus != 'NORMAL' THEN
        DKA_TOOLS_PKG.put_log_message(CHR(10) ||
                                      '>>> Traitement termine en Erreur ');
        pn_retcode := 2;
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Erreur inattendue lors de la création des remises automatiques ' ||
                    SQLERRM;
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
  END create_remit_express;

  ------------------------------------------------------------------------------
  --  Description : Execute le traitement OA de création des reglements
  --                automatiques (ARZCAR_RECEIPT_SRS)
  --
  --  Parametres  : pv_prog_application_short_name  nom court de l'application
  --                pv_last_day_month               date gl du lot
  --                pn_receipt_class_id             classe de reglements
  --                pn_receipt_method_id            mode de reglement
  --                pn_retcode                      statut de sortie (0 si ok,
  --                                                > 0 sinon)
  --                pv_errbuf                       message d'erreur si statut
  --                                                de sortie > 0)
  ------------------------------------------------------------------------------
/*  PROCEDURE create_receipt(pv_prog_application_short_name IN fnd_application.application_short_name%TYPE,
                           pv_last_day_month              IN VARCHAR2,
                           pn_receipt_class_id            IN ar_receipt_classes.receipt_class_id%TYPE,
                           pn_receipt_method_id           IN ar_receipt_methods.receipt_method_id%TYPE,
                           pn_retcode                     IN OUT NOCOPY NUMBER,
                           pv_errbuf                      IN OUT NOCOPY VARCHAR2) IS

    l_request_id NUMBER(15);
    cn_tempo CONSTANT NUMBER := 20;
    l_rphase  VARCHAR2(80);
    l_rstatus VARCHAR2(80);
    l_dphase  VARCHAR2(30);
    l_dstatus VARCHAR2(30);
    l_message VARCHAR2(240);
  BEGIN

    l_request_id := fnd_request.submit_request(pv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                               'ARZCAR_RECEIPT_SRS', --SHORT_NAME du TRAITEMENT
                                               NULL, --PROGRAM_NAME
                                               NULL, --START
                                               FALSE, --SUB_REQUEST
                                               'RECEIPT', --ARGUMENT1
                                               fnd_date.date_to_canonical(SYSDATE), --ARGUMENT2
                                               pv_last_day_month, --ARGUMENT3
                                               'Y', --ARGUMENT4
                                               'Y', --ARGUMENT5
                                               'N', --ARGUMENT6
                                               NULL, --ARGUMENT7
                                               NULL, --ARGUMENT8
                                               'EUR', --ARGUMENT9
                                               NULL, --ARGUMENT10
                                               NULL, --ARGUMENT11
                                               NULL, --ARGUMENT12
                                               NULL, --ARGUMENT13
                                               pn_receipt_class_id, --ARGUMENT14
                                               pn_receipt_method_id, --ARGUMENT15
                                               NULL, --ARGUMENT16
                                               NULL, --ARGUMENT17
                                               NULL, --ARGUMENT18
                                               NULL, --ARGUMENT19
                                               NULL, --ARGUMENT20
                                               NULL, --ARGUMENT21
                                               NULL, --ARGUMENT22
                                               NULL, --ARGUMENT23
                                               NULL, --ARGUMENT24
                                               NULL, --ARGUMENT25
                                               NULL, --ARGUMENT26
                                               NULL, --ARGUMENT27
                                               NULL, --ARGUMENT28
                                               NULL, --ARGUMENT29
                                               NULL, --ARGUMENT30
                                               NULL, --ARGUMENT31
                                               NULL, --ARGUMENT32
                                               NULL, --ARGUMENT33
                                               NULL, --ARGUMENT34
                                               NULL, --ARGUMENT35
                                               NULL, --ARGUMENT36
                                               NULL, --ARGUMENT37
                                               NULL, --ARGUMENT38
                                               NULL, --ARGUMENT39
                                               NULL, --ARGUMENT40
                                               NULL, --ARGUMENT41
                                               NULL --ARGUMENT42
                                               );

    DKA_TOOLS_PKG.put_log_message('Validation pour que les GTS puissent prendre la demande');
    COMMIT;

    IF (l_request_id = 0) THEN
      pn_retcode := 2;
      pv_errbuf  := 'Impossible de lancer le Traitement ';
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
    END IF;

    DKA_TOOLS_PKG.put_log_message('Traitement numero : ' ||
                                  TO_CHAR(l_request_id));

    IF NOT fnd_concurrent.wait_for_request(l_request_id,
                                           cn_tempo,
                                           0,
                                           l_rphase,
                                           l_rstatus,
                                           l_dphase,
                                           l_dstatus,
                                           l_message) THEN
      pn_retcode := 2;
      pv_errbuf  := 'Erreur wait_for_request.';
    ELSE
      IF l_dstatus = 'WARNING' THEN
        DKA_TOOLS_PKG.put_log_message(CHR(10) ||
                                      '>>> Traitement termine en Warning ');
        pn_retcode := 1;
      ELSIF l_dstatus != 'NORMAL' THEN
        DKA_TOOLS_PKG.put_log_message(CHR(10) ||
                                      '>>> Traitement termine en Erreur ');
        pn_retcode := 2;
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Erreur inattendue lors de la création des règlements automatiques (SRS)' ||
                    SQLERRM;
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
  END create_receipt;*/

  ------------------------
  -- Procédures publiques
  ------------------------
  -----------------------------------------------------------------
  --  Nom           : INSERT_PRELEV
  --  Description   : Procédure permettant de créer les fichiers envoyés
  --          à la banque pour effectuer les virements ou prélèvements.
  --          Cette procédure remplace le report standard : ARXADTRM
  --
  --  PARAMETRES :
  --     pv_errbuf       Sortie  --> Varchar2
  --     pn_retcode      Sortie  --> Number
  --     pn_batch_id     Entrée  --> Varchar2
  --
  --  VALEUR RETOURNEE :
  --
  -----------------------------------------------------------------
  PROCEDURE INSERT_PRELEV(pv_errbuf   IN OUT NOCOPY VARCHAR2,
                          pn_retcode  IN OUT NOCOPY NUMBER,
                          pv_batch_id IN VARCHAR2)
  IS
    cv_counterpartyid CONSTANT VARCHAR2(10) := 'NO';
    cv_prefix         CONSTANT VARCHAR2(10) := 'DLK_';

    lv_batch_id                 VARCHAR2(100);
    lv_code_agora               VARCHAR2(8);
    vn_sarautoprelev_request_id NUMBER;

    CURSOR c_select IS
    SELECT * FROM dka_sarautoprelev_tmp FOR UPDATE;

  BEGIN
    DKA_TOOLS_PKG.put_log_message('Debut de la procedure');
    pn_retcode := 0;
    pv_errbuf  := '';

    -- 31/12/2013 BCO Recherche du request_id du dernier traitement "DKA : Règlements automatiques des prélèvements clients".
    BEGIN
      select max(request_id)
      into vn_sarautoprelev_request_id
      from fnd_conc_req_summary_v v
      where v.program_short_name = 'DKA_SARAUTOPRELEV'
        and v.request_date >= SYSDATE - 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vn_sarautoprelev_request_id := fnd_global.conc_request_id;
    END;

    lv_batch_id := substr(pv_batch_id, instr(pv_batch_id, '=', 1) + 1);


    -- Insertion des donnees dans la table temporaire
    INSERT INTO dka_sarautoprelev_tmp
      (SUPPLIER_NUMBER,
       REMIT_DATE,
       SUPPLIER_NAME,
       REMIT_BANK_ADDRESS,
       REMIT_BANK_NUMBER,
       REMIT_BANK_ACCT_NUM,
       REMIT_BANK_NUM,
       REMIT_REFERENCE,
       REMIT_BANK_ACCT_ID,
       DUE_DATE,
       CURRENCY,
       RECEIPT_REFERENCE,
       CUSTOMER_NAME,
       CUSTOMER_BANK_NAME,
       CUST_BANK_ACCT_NUM,
       CUSTOMER_BANK_NUM,
       CUST_BANK_NUMBER,
       REMIT_AMOUNT,
       EFT_CODE,
       PAYMENT_METHOD,
       Created_By,
       Creation_Date,
       Last_Updated_By,
       Last_Update_Date,
       Last_Update_Login,
       request_id,
       sob_id,
       --DD IMPORT ==> ENTETE
       SOCIETE,
       REGION,
       TYPE_CAMPAGNE,
       TYPE_PRLVT,
       CAMP_REQUEST_ID,
       --DD IMPORT ==> CORPS
       DESCRIPTION_REFERENCE,
       CUSTOMERREFERENCENUMBER,
       ENTITYBANKACCOUNTNUMBER,
       COUNTERPARTYNAME,
       COUNTERPARTYADDRESS1,
       COUNTERPARTYADDRESS2,
       COUNTERPARTYADDRESS3,
       COUNTERPARTYADDRESS4,
       COUNTERPARTYZIP,
       COUNTERPARTYCITY,
       COUNTERPARTYCOUNTRYCODE,
       COUNTERPARTYBANKACCOUNTNUMBER,
       CPTYSECONDARYACCOUNTNUMBER,
       COUNTERPARTYBANKNAME,
       COUNTERPARTYBANKCODE,
       COUNTERPARTYBANKADDRESS,
       COUNTERPARTYBANKADDRESS2,
       COUNTERPARTYBANKCITY,
       COUNTERPARTYBANKZIP,
       COUNTERPARTYMESSAGE,
       BANKPREAUTHORIZATIONID,
       CREATIONDATE,
       SEPAMANDATEID,
       SEPAMANDATEDATE,
       SEPACREDITORSCHEMEID,
       SEPADDTYPE,
       SEPAORIGINALMANDATEID,
       SEPAORIGINALCREDITORSCHEMEID,
       SEPAORIGINALCREDITORAGENT,
       SEPAORIGINALDEBTORAGENT,
       SEPAORIGINALDEBTORACCOUNT,
       CASHRECEIPTID,
       STATUS,
       ORG_ID)
      SELECT sp.tax_registration_number,
             to_char(rrf.remit_batch_date, 'DDMMY'),
             substr(ffvt.description, 1, 25),
             rrf.remit_bank_name||cbb.address_line1||cbb.address_line2||cbb.address_line3||cbb.city||cbb.state||cbb.zip,
             cbb.bank_number,
             rrf.remit_bank_account_number,
             cbb.branch_number,
             rrf.remit_batch_name,
             rrf.remit_bank_account_id,
             to_char(rrf.maturity_date, 'DDMMRR'),
             rrf.receipt_currency,
             rrf.receipt_number,
             rrf.customer_name,
             rrf.customer_bank_name,
             rrf.customer_bank_account_number,
             cbb2.branch_number,
             cbb2.bank_number,
             rrf.receipt_amount * 100,
             ffs.attribute10,
             rrf.payment_method,
             fnd_global.user_id,
             SYSDATE,
             fnd_global.user_id,
             SYSDATE,
             fnd_global.login_id,
             fnd_global.conc_request_id,
             sp.set_of_books_id,
             --DD IMPORT ==> ENTETE
             gcc.segment1, --SOCIETE
             gcc.segment2, --REGION
             ffvv_camp.attribute1, --TYPE_CAMPAGNE
             decode(ida.payment_type_code,'REC','RCUR',ida.payment_type_code),--TYPE_PRLVT
             fnd_global.conc_request_id, --CAMP_REQUEST_ID
             --DD IMPORT ==> CORPS
             substr(dka_tools_pkg.get_message('DKA', 'DKA_SARAUTOPRELEV_DESCR_REF',
                                              'DOC', cr.DOC_SEQUENCE_VALUE,
                                              'DATE', to_char(rrf.receipt_date,'yymmdd'),
                                              'NCLIENT', rrf.customer_number,
                                              'STEREG', gcc.segment1 || gcc.segment2), 1, 35), --DESCRIPTION_REFERENCE -JJA 28/01/2014
             substr(dka_tools_pkg.get_message('DKA', 'DKA_SARAUTOPRELEV_CUST_REF_NUM',
                                              'REG', substr(gcc.segment2, -2),
                                              'DATE', to_char(rrf.receipt_date,'ddmmyy'),
                                              'NLOT', rrf.remit_batch_name), 1,50), --CUSTOMERREFERENCENUMBER
             substr(translate(cba.iban_number,translate(' '||REPLACE(cba.iban_number,' '),cv_caractere_autorise,' '),' '), 1, 60), --ENTITYBANKACCOUNTNUMBER
             substr(translate(rrf.customer_name,translate(' '||REPLACE(rrf.customer_name, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYNAME
             substr(translate(aav.address1,translate(' ' || REPLACE(aav.address1, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYADDRESS1
             substr(translate(aav.address2,translate(' ' || REPLACE(aav.address2, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYADDRESS2
             substr(translate(aav.address3,translate(' ' || REPLACE(aav.address3, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYADDRESS3
             substr(translate(aav.address4,translate(' ' || REPLACE(aav.address4, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYADDRESS4
             substr(translate(aav.postal_code,translate(' ' || REPLACE(aav.postal_code, ' '),cv_caractere_autorise,' '),' '),1,10), --COUNTERPARTYZIP
             substr(translate(aav.city,translate(' ' || REPLACE(aav.city, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYCITY
             substr(translate(aav.country,translate(' ' || REPLACE(aav.country, ' '),cv_caractere_autorise,' '),' '),1,2), --COUNTERPARTYCOUNTRYCODE
             substr(translate(cbb2.bank_number || cbb2.branch_number ||rrf.customer_bank_account_number,
                    translate(' ' || REPLACE(cbb2.bank_number ||cbb2.branch_number ||rrf.customer_bank_account_number,' '),cv_caractere_autorise,' '),' '),1,30), --COUNTERPARTYBANKACCOUNTNUMBER
             substr(translate(ieba.IBAN,translate(' ' || REPLACE(ieba.IBAN, ' '),cv_caractere_autorise,' '),' '),1,34), --CPTYSECONDARYACCOUNTNUMBER
             substr(translate(cbb2.bank_name,translate(' ' || REPLACE(cbb2.bank_name, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYBANKNAME
             substr(translate(cbb2.eft_swift_code,translate(' ' ||REPLACE(cbb2.eft_swift_code, ' '),cv_caractere_autorise,' '),' '),1,20), --COUNTERPARTYBANKCODE
             substr(translate(cbb2.address_line1,translate(' ' ||REPLACE(cbb2.address_line1, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYBANKADDRESS
             substr(translate(cbb2.address_line2,translate(' ' ||REPLACE(cbb2.address_line2, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYBANKADDRESS2
             substr(translate(cbb2.city,translate(' ' || REPLACE(cbb2.city, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYBANKCITY
             substr(translate(cbb2.zip,translate(' ' || REPLACE(cbb2.zip, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYBANKZIP
             substr(translate(cv_prefix || gcc.segment1 || gcc.segment2 ||to_char(SYSDATE, 'DDMMYYYY') ||vn_sarautoprelev_request_id,
                    translate(' ' ||REPLACE(cv_prefix || gcc.segment1 ||gcc.segment2 ||to_char(SYSDATE, 'DDMMYYYY') ||vn_sarautoprelev_request_id,' '),cv_caractere_autorise,' '),' '),1,100), --COUNTERPARTYMESSAGE
             NULL, --BANKPREAUTHORIZATIONID
             NULL, --CREATIONDATE
             substr(translate(ida.authorization_reference_number,translate(' ' || REPLACE(ida.authorization_reference_number,' '),cv_caractere_autorise,' '),' '),1,35), --SEPAMANDATEID
             ida.auth_sign_date, --SEPAMANDATEDATE
             substr(translate(ffs.attribute15,translate(' ' || REPLACE(ffs.attribute15, ' '),cv_caractere_autorise,' '),' '),1,35), --SEPACREDITORSCHEMEID
             substr(translate(decode(ida.payment_type_code,'REC','RCUR',ida.payment_type_code),translate(' ' || REPLACE(decode(ida.payment_type_code,'REC','RCUR',ida.payment_type_code), ' '),cv_caractere_autorise,' '),' '),1,4), --SEPADDTYPE
             NULL, --SEPAORIGINALMANDATEID
             NULL, --SEPAORIGINALCREDITORSCHEMEID
             NULL, --SEPAORIGINALCREDITORAGENT
             NULL, --SEPAORIGINALDEBTORAGENT
             NULL, --SEPAORIGINALDEBTORACCOUNT
             cr.cash_receipt_id, --CASHRECEIPTID
             'NEW', --STATUS
             haou.organization_id
      FROM ar_remitted_receipts_format_v  rrf,
           ce_bank_accounts               cba,  --ap_bank_accounts    ba,
           ce_bank_branches_v             cbb,  --ap_bank_branches    bb,
           ce_bank_acct_uses_all          cbau,
           iby_fndcpt_tx_extensions       ifte,
           iby_debit_authorizations       ida,
           iby_pmt_instr_uses_all         ipiu,
           iby_ext_bank_accounts          ieba, --ap_bank_accounts    ba2,
           ce_bank_branches_v             cbb2, --ap_bank_branches    bb2,
           ar_cash_receipts               cr,
           ar_receipt_methods             arm,
           ar_receipt_method_accounts     armaa,
           gl_code_combinations           gcc,
           hz_cust_accounts               hca, --ra_customers         rc,
           ar_addresses_v                 aav,
           ar_system_parameters           sp,
           gl_ledgers                     gl,
           hr_all_organization_units      haou,
           fnd_flex_value_sets            fvs,
           fnd_flex_values                ffs,
           fnd_flex_values_tl             ffvt,
           fnd_flex_value_sets            ffvs_camp,
           fnd_flex_values_vl             ffvv_camp
      WHERE 1=1
        --AND cba.bank_account_id = rrf.remit_bank_account_id -- OBE
        AND cbau.bank_acct_use_id = rrf.remit_bank_account_id -- OBE
        AND cbb.branch_party_id = cba.bank_branch_id
        AND cbau.bank_account_id = cba.bank_account_id
        AND cbau.org_id = haou.organization_id
        AND ifte.trxn_extension_id = rrf.payment_trxn_extension_id
        AND ida.debit_authorization_id = ifte.debit_authorization_id
        AND ipiu.instrument_payment_use_id = ifte.instr_assignment_id
        AND ieba.ext_bank_account_id = ipiu.instrument_id
        AND cbb2.branch_party_id = ieba.branch_id
        AND rrf.cash_receipt_id = cr.cash_receipt_id
        AND arm.name = rrf.payment_method
        AND armaa.receipt_method_id = arm.receipt_method_id
        AND armaa.remit_bank_acct_use_id = cbau.bank_acct_use_id
        AND armaa.org_id = haou.organization_id
        AND gcc.code_combination_id = armaa.cash_ccid
        AND hca.cust_account_id = rrf.customer_id
        AND aav.customer_id(+) = rrf.customer_id
        AND aav.orig_system_reference(+) like '%'||rrf.customer_site_location
        AND aav.org_id(+) = cr.org_id
        AND sp.org_id = cr.org_id
        AND gl.ledger_id = sp.set_of_books_id
        AND haou.organization_id = cr.org_id
        AND fvs.flex_value_set_name = 'DAOPCCF_STE'
        AND ffs.flex_value_set_id = fvs.flex_value_set_id
        AND ffs.enabled_flag = 'Y'
        AND trunc(sysdate) between nvl(ffs.start_date_active, trunc(sysdate)) and nvl(ffs.end_date_active, trunc(sysdate))
        AND ffs.flex_value = substr(haou.name,-4)
        AND ffvt.flex_value_id = ffs.flex_value_id
        AND ffvt.LANGUAGE = 'F'
        AND rrf.remit_batch_id = lv_batch_id
        AND ffvs_camp.flex_value_set_name = 'DKA_CUSTOMER_PAY_GROUP'
        AND ffvs_camp.flex_value_set_id = ffvv_camp.flex_value_set_id
        AND ffvv_camp.flex_value = 'PRELEVEMENT';


    --Alimentation des champs supplémentaires
    FOR l in c_select LOOP
      --ENTETE
      --AGORA_CODE / FORMAT1ENTITYID
      /*lv_code_agora := get_code_agora(NULL,
                                      'DK',
                                      l.region,
                                      l.societe,
                                      cv_counterpartyid);*/

      UPDATE dka_sarautoprelev_tmp
      SET AGORA_CODE              = SOCIETE,--lv_code_agora,
          FORMAT1ENTITYID         = SOCIETE,--lv_code_agora,
          DESCRIPTION_REFERENCE   = translate(DESCRIPTION_REFERENCE,translate(' ' ||REPLACE(DESCRIPTION_REFERENCE,' '),cv_caractere_autorise,' '),' '),
          CUSTOMERREFERENCENUMBER = translate(CUSTOMERREFERENCENUMBER,translate(' ' ||REPLACE(CUSTOMERREFERENCENUMBER,' '),cv_caractere_autorise,' '),' ')
      WHERE current of c_select;

    END LOOP;

    DKA_TOOLS_PKG.put_log_message('Nombre de lignes inserées dans la table = ' ||SQL%ROWCOUNT);
    DKA_TOOLS_PKG.put_log_message('Procédure terminée avec succès');
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := SQLERRM;
      DKA_TOOLS_PKG.put_log_message('Erreur lors de l''insertion des données => ' || pv_errbuf);
  END INSERT_PRELEV;


  --ARA EDB379
   -----------------------------------------------------------------
  --  Nom           : INSERT_PRELEV_EXP
  --  Description   : Procédure permettant de créer les fichiers envoyés
  --          à la banque pour effectuer les virements ou prélèvements.
  --          Cette procédure remplace le report standard : ARXADTRM
  --
  --  PARAMETRES :
  --     pv_errbuf       Sortie  --> Varchar2
  --     pn_retcode      Sortie  --> Number
  --     pn_batch_id     Entrée  --> Varchar2
  --
  --  VALEUR RETOURNEE :
  --
  -----------------------------------------------------------------
  PROCEDURE INSERT_PRELEV_EXP(pv_errbuf   IN OUT NOCOPY VARCHAR2,
                          pn_retcode  IN OUT NOCOPY NUMBER,
                          pv_batch_id IN VARCHAR2)
  IS
    cv_counterpartyid CONSTANT VARCHAR2(10) := 'NO';
    cv_prefix         CONSTANT VARCHAR2(10) := 'DLK_';

    lv_batch_id                 VARCHAR2(100);
    lv_code_agora               VARCHAR2(8);
    vn_sarautoprelev_request_id NUMBER;

    CURSOR c_select IS
    SELECT * FROM dka_sarautoprelev_tmp FOR UPDATE;

  BEGIN
    DKA_TOOLS_PKG.put_log_message('Debut de la procedure');
    pn_retcode := 0;
    pv_errbuf  := '';

    -- 31/12/2013 BCO Recherche du request_id du dernier traitement "DKA : Règlements automatiques des prélèvements clients".
    BEGIN
      select max(request_id)
      into vn_sarautoprelev_request_id
      from fnd_conc_req_summary_v v
      where v.program_short_name = 'DKA_SARAUTOPRELEV'
        and v.request_date >= SYSDATE - 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vn_sarautoprelev_request_id := fnd_global.conc_request_id;
    END;

    lv_batch_id := substr(pv_batch_id, instr(pv_batch_id, '=', 1) + 1);


  -- Insertion des donnees dans la table temporaire
    INSERT INTO dka_sarautoprelev_tmp
      (SUPPLIER_NUMBER,
       REMIT_DATE,
       SUPPLIER_NAME,
       REMIT_BANK_ADDRESS,
       REMIT_BANK_NUMBER,
       REMIT_BANK_ACCT_NUM,
       REMIT_BANK_NUM,
       REMIT_REFERENCE,
       REMIT_BANK_ACCT_ID,
       DUE_DATE,
       CURRENCY,
       RECEIPT_REFERENCE,
       CUSTOMER_NAME,
       CUSTOMER_BANK_NAME,
       CUST_BANK_ACCT_NUM,
       CUSTOMER_BANK_NUM,
       CUST_BANK_NUMBER,
       REMIT_AMOUNT,
       EFT_CODE,
       PAYMENT_METHOD,
       Created_By,
       Creation_Date,
       Last_Updated_By,
       Last_Update_Date,
       Last_Update_Login,
       request_id,
       sob_id,
       --DD IMPORT ==> ENTETE
       SOCIETE,
       REGION,
       TYPE_CAMPAGNE,
       TYPE_PRLVT,
       CAMP_REQUEST_ID,
       --DD IMPORT ==> CORPS
       DESCRIPTION_REFERENCE,
       CUSTOMERREFERENCENUMBER,
       ENTITYBANKACCOUNTNUMBER,
       COUNTERPARTYNAME,
       COUNTERPARTYADDRESS1,
       COUNTERPARTYADDRESS2,
       COUNTERPARTYADDRESS3,
       COUNTERPARTYADDRESS4,
       COUNTERPARTYZIP,
       COUNTERPARTYCITY,
       COUNTERPARTYCOUNTRYCODE,
       COUNTERPARTYBANKACCOUNTNUMBER,
       CPTYSECONDARYACCOUNTNUMBER,
       COUNTERPARTYBANKNAME,
       COUNTERPARTYBANKCODE,
       COUNTERPARTYBANKADDRESS,
       COUNTERPARTYBANKADDRESS2,
       COUNTERPARTYBANKCITY,
       COUNTERPARTYBANKZIP,
       COUNTERPARTYMESSAGE,
       BANKPREAUTHORIZATIONID,
       CREATIONDATE,
       SEPAMANDATEID,
       SEPAMANDATEDATE,
       SEPACREDITORSCHEMEID,
       SEPADDTYPE,
       SEPAORIGINALMANDATEID,
       SEPAORIGINALCREDITORSCHEMEID,
       SEPAORIGINALCREDITORAGENT,
       SEPAORIGINALDEBTORAGENT,
       SEPAORIGINALDEBTORACCOUNT,
       CASHRECEIPTID,
       STATUS,
       ORG_ID)
      SELECT sp.tax_registration_number,
             to_char(rrf.remit_batch_date, 'DDMMY'),
             substr(ffvt.description, 1, 25),
             rrf.remit_bank_name||cbb.address_line1||cbb.address_line2||cbb.address_line3||cbb.city||cbb.state||cbb.zip,
             cbb.bank_number,
             rrf.remit_bank_account_number,
             cbb.branch_number,
             rrf.remit_batch_name,
             rrf.remit_bank_account_id,
             to_char(rrf.maturity_date, 'DDMMRR'),
             rrf.receipt_currency,
             rrf.receipt_number,
             rrf.customer_name,
             rrf.customer_bank_name,
             rrf.customer_bank_account_number,
             cbb2.branch_number,
             cbb2.bank_number,
             rrf.receipt_amount * 100,
             ffs.attribute10,
             rrf.payment_method,
             fnd_global.user_id,
             SYSDATE,
             fnd_global.user_id,
             SYSDATE,
             fnd_global.login_id,
             fnd_global.conc_request_id,
             sp.set_of_books_id,
             --DD IMPORT ==> ENTETE
             gcc.segment1, --SOCIETE
             gcc.segment2, --REGION
             ffvv_camp.attribute1, --TYPE_CAMPAGNE
             decode(ida.payment_type_code,'REC','RCUR',ida.payment_type_code),--TYPE_PRLVT
             fnd_global.conc_request_id, --CAMP_REQUEST_ID
             --DD IMPORT ==> CORPS
             substr(dka_tools_pkg.get_message('DKA', 'DKA_SARAUTOPRELEV_DESCR_REF',
                                              'DOC', cr.DOC_SEQUENCE_VALUE,
                                              'DATE', to_char(rrf.receipt_date,'yymmdd'),
                                              'NCLIENT', rrf.customer_number,
                                              'STEREG', gcc.segment1 || gcc.segment2), 1, 35), --DESCRIPTION_REFERENCE -JJA 28/01/2014
             substr(dka_tools_pkg.get_message('DKA', 'DKA_SARAUTOPRELEV_CUST_REF_NUM',
                                              'REG', substr(gcc.segment2, -2),
                                              'DATE', to_char(rrf.receipt_date,'ddmmyy'),
                                              'NLOT', rrf.remit_batch_name), 1,50), --CUSTOMERREFERENCENUMBER
             substr(translate(cba.iban_number,translate(' '||REPLACE(cba.iban_number,' '),cv_caractere_autorise,' '),' '), 1, 60), --ENTITYBANKACCOUNTNUMBER
             substr(translate(rrf.customer_name,translate(' '||REPLACE(rrf.customer_name, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYNAME
             substr(translate(aav.address1,translate(' ' || REPLACE(aav.address1, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYADDRESS1
             substr(translate(aav.address2,translate(' ' || REPLACE(aav.address2, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYADDRESS2
             substr(translate(aav.address3,translate(' ' || REPLACE(aav.address3, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYADDRESS3
             substr(translate(aav.address4,translate(' ' || REPLACE(aav.address4, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYADDRESS4
             substr(translate(aav.postal_code,translate(' ' || REPLACE(aav.postal_code, ' '),cv_caractere_autorise,' '),' '),1,10), --COUNTERPARTYZIP
             substr(translate(aav.city,translate(' ' || REPLACE(aav.city, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYCITY
             substr(translate(aav.country,translate(' ' || REPLACE(aav.country, ' '),cv_caractere_autorise,' '),' '),1,2), --COUNTERPARTYCOUNTRYCODE
             substr(translate(cbb2.bank_number || cbb2.branch_number ||rrf.customer_bank_account_number,
                    translate(' ' || REPLACE(cbb2.bank_number ||cbb2.branch_number ||rrf.customer_bank_account_number,' '),cv_caractere_autorise,' '),' '),1,30), --COUNTERPARTYBANKACCOUNTNUMBER
             substr(translate(ieba.IBAN,translate(' ' || REPLACE(ieba.IBAN, ' '),cv_caractere_autorise,' '),' '),1,34), --CPTYSECONDARYACCOUNTNUMBER
             substr(translate(cbb2.bank_name,translate(' ' || REPLACE(cbb2.bank_name, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYBANKNAME
             substr(translate(cbb2.eft_swift_code,translate(' ' ||REPLACE(cbb2.eft_swift_code, ' '),cv_caractere_autorise,' '),' '),1,20), --COUNTERPARTYBANKCODE
             substr(translate(cbb2.address_line1,translate(' ' ||REPLACE(cbb2.address_line1, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYBANKADDRESS
             substr(translate(cbb2.address_line2,translate(' ' ||REPLACE(cbb2.address_line2, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYBANKADDRESS2
             substr(translate(cbb2.city,translate(' ' || REPLACE(cbb2.city, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYBANKCITY
             substr(translate(cbb2.zip,translate(' ' || REPLACE(cbb2.zip, ' '),cv_caractere_autorise,' '),' '),1,35), --COUNTERPARTYBANKZIP
             substr(translate(cv_prefix || gcc.segment1 || gcc.segment2 ||to_char(SYSDATE, 'DDMMYYYY') ||vn_sarautoprelev_request_id,
                    translate(' ' ||REPLACE(cv_prefix || gcc.segment1 ||gcc.segment2 ||to_char(SYSDATE, 'DDMMYYYY') ||vn_sarautoprelev_request_id,' '),cv_caractere_autorise,' '),' '),1,100), --COUNTERPARTYMESSAGE
             NULL, --BANKPREAUTHORIZATIONID
             NULL, --CREATIONDATE
             substr(translate(ida.authorization_reference_number,translate(' ' || REPLACE(ida.authorization_reference_number,' '),cv_caractere_autorise,' '),' '),1,35), --SEPAMANDATEID
             ida.auth_sign_date, --SEPAMANDATEDATE
             substr(translate(ffs.attribute15,translate(' ' || REPLACE(ffs.attribute15, ' '),cv_caractere_autorise,' '),' '),1,35), --SEPACREDITORSCHEMEID
             substr(translate(decode(ida.payment_type_code,'REC','RCUR',ida.payment_type_code),translate(' ' || REPLACE(decode(ida.payment_type_code,'REC','RCUR',ida.payment_type_code), ' '),cv_caractere_autorise,' '),' '),1,4), --SEPADDTYPE
             NULL, --SEPAORIGINALMANDATEID
             NULL, --SEPAORIGINALCREDITORSCHEMEID
             NULL, --SEPAORIGINALCREDITORAGENT
             NULL, --SEPAORIGINALDEBTORAGENT
             NULL, --SEPAORIGINALDEBTORACCOUNT
             cr.cash_receipt_id, --CASHRECEIPTID
             'NEW', --STATUS
             haou.organization_id
      FROM ar_remitted_receipts_format_v  rrf,
           ce_bank_accounts               cba,  --ap_bank_accounts    ba,
           ce_bank_branches_v             cbb,  --ap_bank_branches    bb,
           ce_bank_acct_uses_all          cbau,
           iby_fndcpt_tx_extensions       ifte,
           iby_debit_authorizations       ida,
           iby_pmt_instr_uses_all         ipiu,
           iby_ext_bank_accounts          ieba, --ap_bank_accounts    ba2,
           ce_bank_branches_v             cbb2, --ap_bank_branches    bb2,
           ar_cash_receipts               cr,
           ar_receipt_methods             arm,
           ar_receipt_method_accounts     armaa,
           gl_code_combinations           gcc,
           hz_cust_accounts               hca, --ra_customers         rc,
           ar_addresses_v                 aav,
           ar_system_parameters           sp,
           gl_ledgers                     gl,
           hr_all_organization_units      haou,
           fnd_flex_value_sets            fvs,
           fnd_flex_values                ffs,
           fnd_flex_values_tl             ffvt,
           fnd_flex_value_sets            ffvs_camp,
           fnd_flex_values_vl             ffvv_camp
      WHERE 1=1
        --AND cba.bank_account_id = rrf.remit_bank_account_id -- OBE
        AND cbau.bank_acct_use_id = rrf.remit_bank_account_id -- OBE
        AND cbb.branch_party_id = cba.bank_branch_id
        AND cbau.bank_account_id = cba.bank_account_id
        AND cbau.org_id = haou.organization_id
        AND ifte.trxn_extension_id = rrf.payment_trxn_extension_id
        AND ida.debit_authorization_id = ifte.debit_authorization_id
        AND ipiu.instrument_payment_use_id = ifte.instr_assignment_id
        AND ieba.ext_bank_account_id = ipiu.instrument_id
        AND cbb2.branch_party_id = ieba.branch_id
        AND rrf.cash_receipt_id = cr.cash_receipt_id
        AND arm.name = rrf.payment_method
        AND armaa.receipt_method_id = arm.receipt_method_id
        AND armaa.remit_bank_acct_use_id = cbau.bank_acct_use_id
        AND armaa.org_id = haou.organization_id
        AND gcc.code_combination_id = armaa.cash_ccid
        AND hca.cust_account_id = rrf.customer_id
        AND aav.customer_id(+) = rrf.customer_id
        AND aav.orig_system_reference(+) like '%'||rrf.customer_site_location
        AND aav.org_id(+) = cr.org_id
        AND sp.org_id = cr.org_id
        AND gl.ledger_id = sp.set_of_books_id
        AND haou.organization_id = cr.org_id
        AND fvs.flex_value_set_name = 'DAOPCCF_STE'
        AND ffs.flex_value_set_id = fvs.flex_value_set_id
        AND ffs.enabled_flag = 'Y'
        AND trunc(sysdate) between nvl(ffs.start_date_active, trunc(sysdate)) and nvl(ffs.end_date_active, trunc(sysdate))
        AND ffs.flex_value = substr(haou.name,-4)
        AND ffvt.flex_value_id = ffs.flex_value_id
        AND ffvt.LANGUAGE = 'F'
        AND rrf.remit_batch_id = lv_batch_id
        AND ffvs_camp.flex_value_set_name = 'DKA_CUSTOMER_PAY_GROUP'
        AND ffvs_camp.flex_value_set_id = ffvv_camp.flex_value_set_id
        AND ffvv_camp.flex_value = 'PRELEVEMENT EXPRESS'
    AND cr.ATTRIBUTE8 = 'Y'
        AND cr.created_by != '1205'  ;



    FOR l in c_select LOOP

      UPDATE dka_sarautoprelev_tmp
      SET AGORA_CODE              = SOCIETE,--lv_code_agora,
          FORMAT1ENTITYID         = SOCIETE,--lv_code_agora,
          DESCRIPTION_REFERENCE   = translate(DESCRIPTION_REFERENCE,translate(' ' ||REPLACE(DESCRIPTION_REFERENCE,' '),cv_caractere_autorise,' '),' '),
          CUSTOMERREFERENCENUMBER = translate(CUSTOMERREFERENCENUMBER,translate(' ' ||REPLACE(CUSTOMERREFERENCENUMBER,' '),cv_caractere_autorise,' '),' ')
      WHERE current of c_select;

    END LOOP;

    DKA_TOOLS_PKG.put_log_message('Nombre de lignes inserées dans la table = ' ||SQL%ROWCOUNT);
    DKA_TOOLS_PKG.put_log_message('Procédure terminée avec succès');
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := SQLERRM;
      DKA_TOOLS_PKG.put_log_message('Erreur lors de l''insertion des données => ' || pv_errbuf);
  END INSERT_PRELEV_EXP;


  -----------------------------------------------------------------
  --  Nom           : CREATE_DDIMPORT
  --  Description   : Procédure permettant de créer les fichiers au
  --                  format DDIMPORT envoyés à la banque pour
  --                  effectuer les virements ou prélèvements
  --
  --  PARAMETRES :
  --     pv_errbuf       Sortie  --> Varchar2
  --     pn_retcode      Sortie  --> Number
  --     pv_date         Entrée  --> Varchar2
  --
  --  VALEUR RETOURNEE :
  --
  -----------------------------------------------------------------
  PROCEDURE CREATE_DDIMPORT(pv_errbuf  IN OUT NOCOPY VARCHAR2,
                            pn_retcode IN OUT NOCOPY NUMBER,
                            pv_date    IN VARCHAR2)
  IS

    CURSOR cur_remit IS
    SELECT dst.supplier_number,
           dst.remit_date,
           dst.supplier_name,
           dst.remit_bank_address,
           dst.remit_bank_number,
           dst.remit_bank_acct_num,
           dst.remit_bank_num,
           dst.remit_reference,
           dst.remit_bank_acct_id,
           dst.due_date,
           dst.currency,
           dst.receipt_reference,
           dst.customer_name,
           dst.customer_bank_name,
           dst.cust_bank_acct_num,
           dst.customer_bank_num,
           dst.cust_bank_number,
           dst.remit_amount,
           dst.eft_code,
           dst.payment_method,
           to_char(dst.creation_date, 'DDMMRR') creation_date,
           'DK'     abr_short_name,
           dst.AGORA_CODE,
           dst.SOCIETE,
           dst.REGION,
           dst.TYPE_CAMPAGNE,
           dst.TYPE_PRLVT,
           dst.CAMP_REQUEST_ID,
           dst.FORMAT1ENTITYID,
           dst.VALUEDATE,
           dst.TRANSACTIONDATE,
           dst.DESCRIPTION_REFERENCE,
           dst.CUSTOMERREFERENCENUMBER,
           dst.ENTITYBANKACCOUNTNUMBER,
           dst.COUNTERPARTYNAME,
           dst.COUNTERPARTYADDRESS1,
           dst.COUNTERPARTYADDRESS2,
           dst.COUNTERPARTYADDRESS3,
           dst.COUNTERPARTYADDRESS4,
           dst.COUNTERPARTYZIP,
           dst.COUNTERPARTYCITY,
           dst.COUNTERPARTYCOUNTRYCODE,
           dst.COUNTERPARTYBANKACCOUNTNUMBER,
           dst.CPTYSECONDARYACCOUNTNUMBER,
           dst.COUNTERPARTYBANKNAME,
           dst.COUNTERPARTYBANKCODE,
           dst.COUNTERPARTYBANKADDRESS,
           dst.COUNTERPARTYBANKADDRESS2,
           dst.COUNTERPARTYBANKCITY,
           dst.COUNTERPARTYBANKZIP,
           dst.COUNTERPARTYMESSAGE,
           dst.BANKPREAUTHORIZATIONID,
           dst.CREATIONDATE,
           dst.SEPAMANDATEID,
           dst.SEPAMANDATEDATE,
           dst.SEPACREDITORSCHEMEID,
           dst.SEPADDTYPE,
           dst.SEPAORIGINALMANDATEID,
           dst.SEPAORIGINALCREDITORSCHEMEID,
           dst.SEPAORIGINALCREDITORAGENT,
           dst.SEPAORIGINALDEBTORAGENT,
           dst.SEPAORIGINALDEBTORACCOUNT,
           dst.CASHRECEIPTID
    FROM dka_sarautoprelev_tmp dst
    WHERE dst.STATUS = 'NEW'
    ORDER BY dst.remit_bank_number,
             dst.SOCIETE,
             dst.REGION,
             dst.type_prlvt,
             dst.remit_bank_num,
             dst.remit_reference;

    cv_separateur   CONSTANT VARCHAR2(1) := ',';
    cv_ext          CONSTANT VARCHAR2(10) := '.txt';

    File_Handle                    utl_file.file_type;
    vv_file_name                   VARCHAR2(100);
    vv_buffer                      VARCHAR2(4000);
    vv_step                        VARCHAR2(500);
    vn_nb_lignes                   PLS_INTEGER;
    vn_nb_lignes_tot               PLS_INTEGER;
    vn_nb_fichier                  PLS_INTEGER;
    vv_CASHFLOWTYPE                fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_CODE_DIVISION               fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_COUNTERPARTYBANKACCOUNTCOUN fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_COUNTERPARTYBANKACCOUNTCURC fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_COUNTERPARTYBANKCODETYPE    fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_COUNTERPARTYID              fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_CPTYPRIMARYACCOUNTNUMBERTYP fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_CPTYSECONDARYACCOUNTNUMBERT fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_CURRENCYCODE                fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_ENTITYBANKACCOUNTCURRENCYCO fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_FILE_INFORMATION_INDICATOR  fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_PAYMENTMETHOD               fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_SUPPLYCPTYDETAILS           fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_SUPPLYPAYINGACCOUNT         fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_TRANSACTIONTYPECODE         fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_TYPE_INDICATOR              fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_SEPAPAYMENTFORMAT           fnd_lookup_values_vl.DESCRIPTION%TYPE;
    vv_FILE_LAYOUT                 VARCHAR2(2000);
    vd_value_date                  DATE;
    vd_transaction_date            DATE;
    l_delai                        NUMBER;

    --FILE
    vv_bank_number dka_sarautoprelev_tmp.remit_bank_number%TYPE;
    vv_societe     dka_sarautoprelev_tmp.SOCIETE%TYPE;
    vv_region      dka_sarautoprelev_tmp.REGION%TYPE;
    vv_prlvt       dka_sarautoprelev_tmp.TYPE_PRLVT%TYPE;

  --ARA EDB379
  vv_type_echeance varchar2(40);
  v_due_date_exp varchar2(20);
  v_due_date_dd DATE;
  v_value_date_exp DATE;

    CURSOR c_param IS
    SELECT lookup_code, DESCRIPTION
    FROM fnd_lookup_values_vl flvv
    WHERE flvv.lookup_type = 'DKA_DD_IMPORT'
    ORDER BY lookup_code DESC;

  BEGIN
    pv_errbuf  := NULL;
    pn_retcode := 0;

    ----------------------------------------------------------------------------------------------------------------------
    -->DD IMPORT
    ----------------------------------------------------------------------------------------------------------------------
    -----  Récupération des constantes -----
    vv_step := '001 : Récupération des constantes';
    dka_tools_pkg.put_debug_message(vv_step);

    vv_step := '002 : Parametres inconnus : ';
    FOR l IN c_param LOOP

      CASE
        WHEN l.lookup_code = 'CASHFLOWTYPE' THEN
          vv_CASHFLOWTYPE := l.DESCRIPTION;
        WHEN l.lookup_code = 'CODE_DIVISION' THEN
          vv_CODE_DIVISION := l.DESCRIPTION;
        WHEN l.lookup_code = 'COUNTERPARTYBANKACCOUNTCOUNTRY' THEN
          vv_COUNTERPARTYBANKACCOUNTCOUN := l.DESCRIPTION;
        WHEN l.lookup_code = 'COUNTERPARTYBANKACCOUNTCURCODE' THEN
          vv_COUNTERPARTYBANKACCOUNTCURC := l.DESCRIPTION;
        WHEN l.lookup_code = 'COUNTERPARTYBANKCODETYPE' THEN
          vv_COUNTERPARTYBANKCODETYPE := l.DESCRIPTION;
        WHEN l.lookup_code = 'COUNTERPARTYID' THEN
          vv_COUNTERPARTYID := l.DESCRIPTION;
        WHEN l.lookup_code = 'CPTYPRIMARYACCOUNTNUMBERTYPE' THEN
          vv_CPTYPRIMARYACCOUNTNUMBERTYP := l.DESCRIPTION;
        WHEN l.lookup_code = 'CPTYSECONDARYACCOUNTNUMBERTYPE' THEN
          vv_CPTYSECONDARYACCOUNTNUMBERT := l.DESCRIPTION;
        WHEN l.lookup_code = 'CURRENCYCODE' THEN
          vv_CURRENCYCODE := l.DESCRIPTION;
        WHEN l.lookup_code = 'ENTITYBANKACCOUNTCURRENCYCODE' THEN
          vv_ENTITYBANKACCOUNTCURRENCYCO := l.DESCRIPTION;
        WHEN l.lookup_code = 'FILE_INFORMATION_INDICATOR' THEN
          vv_FILE_INFORMATION_INDICATOR := l.DESCRIPTION;
        WHEN l.lookup_code = 'PAYMENTMETHOD' THEN
          vv_PAYMENTMETHOD := l.DESCRIPTION;
        WHEN l.lookup_code = 'SUPPLYCPTYDETAILS' THEN
          vv_SUPPLYCPTYDETAILS := l.DESCRIPTION;
        WHEN l.lookup_code = 'SUPPLYPAYINGACCOUNT' THEN
          vv_SUPPLYPAYINGACCOUNT := l.DESCRIPTION;
        WHEN l.lookup_code = 'TRANSACTIONTYPECODE' THEN
          vv_TRANSACTIONTYPECODE := l.DESCRIPTION;
        WHEN l.lookup_code = 'TYPE_INDICATOR' THEN
          vv_TYPE_INDICATOR := l.DESCRIPTION;
        WHEN l.lookup_code = 'SEPAPAYMENTFORMAT' THEN
          vv_SEPAPAYMENTFORMAT := l.DESCRIPTION;
        WHEN l.lookup_code LIKE 'FILE_LAYOUT%' THEN
          vv_FILE_LAYOUT := l.DESCRIPTION || cv_separateur || vv_FILE_LAYOUT;
        ELSE
          vv_step := vv_step || ' ' || l.lookup_code || '/' || l.DESCRIPTION;
      END CASE;

    END LOOP;
    dka_tools_pkg.put_debug_message(vv_step);

    --Calcul de la date de valeur
    vv_step := '003 : Calcul de la date de valeur';
    dka_tools_pkg.put_debug_message(vv_step);

  --ARA EDB379
  BEGIN
   SELECT STATUS_TRAITEMENT
   INTO vv_type_echeance
   FROM DKA_SARAUTOPRELEV_STAT;

  END;

  IF vv_type_echeance = 'EXPRESS' THEN

  SELECT TO_NUMBER(NVL(attribute2, cn_default_delai))
    INTO l_delai
    FROM fnd_flex_value_sets ffvs,
         fnd_flex_values_vl  ffvv
    WHERE ffvs.flex_value_set_id = ffvv.flex_value_set_id
      AND ffvs.flex_value_set_name = 'DKA_CUSTOMER_PAY_GROUP'
      AND ffvv.flex_value = 'PRELEVEMENT EXPRESS'
      AND enabled_flag = 'Y'
      AND SYSDATE BETWEEN NVL(ffvv.start_date_active, SYSDATE) AND NVL(ffvv.end_date_active, SYSDATE);

  ELSE

  SELECT TO_NUMBER(NVL(attribute2, cn_default_delai))
    INTO l_delai
    FROM fnd_flex_value_sets ffvs,
         fnd_flex_values_vl  ffvv
    WHERE ffvs.flex_value_set_id = ffvv.flex_value_set_id
      AND ffvs.flex_value_set_name = 'DKA_CUSTOMER_PAY_GROUP'
      AND ffvv.flex_value = 'PRELEVEMENT'
      AND enabled_flag = 'Y'
      AND SYSDATE BETWEEN NVL(ffvv.start_date_active, SYSDATE) AND NVL(ffvv.end_date_active, SYSDATE);

  END IF;


    vd_transaction_date := fnd_date.canonical_to_date(pv_date);

    vv_step := '004 : Delai / Date de référence :' || l_delai || '/' || to_char(vd_transaction_date, 'dd/mm/yyyy');
    dka_tools_pkg.put_debug_message(vv_step);

    FOR i in 1 .. l_delai LOOP

      vd_transaction_date := vd_transaction_date + 1;
      Dka_Tools_Pkg.Get_Next_Working_Day(vd_transaction_date);

    END LOOP;

    vd_value_date := vd_transaction_date + 1;
    Dka_Tools_Pkg.Get_Next_Working_Day(vd_value_date);

    vv_step := '005 : Date de valeur :' || to_char(vd_value_date, 'dd/mm/yyyy');
    dka_tools_pkg.put_debug_message(vv_step);
    vv_step := '005 : Date de transaction :' ||to_char(vd_transaction_date, 'dd/mm/yyyy');
    dka_tools_pkg.put_debug_message(vv_step);

    --Variable de boucle
    vv_societe     := NULL;
    vv_region      := NULL;
    vv_bank_number := NULL;
    vv_prlvt       := NULL;

    vn_nb_lignes     := 0;
    vn_nb_lignes_tot := 0;
    vn_nb_fichier    := 0;

    --Pour tous les prélèvements
    vv_step := '006 : Pour tous les prélèvements...';
    dka_tools_pkg.put_debug_message(vv_step);
    FOR rec_remit IN cur_remit LOOP

      --Si on est sur un nouveau couple banque/societe/region > nouveau fichier
      IF rec_remit.remit_bank_number != nvl(vv_bank_number, '#') OR
         rec_remit.societe != nvl(vv_societe, '#') OR
         rec_remit.region != nvl(vv_region, '#') OR
         rec_remit.type_prlvt != nvl(vv_prlvt, '#') THEN

        vv_step := '007 : Nouveau Fichier' || chr(10) ||
                         'banque  :' ||rec_remit.remit_bank_number || chr(10) ||
                         'societe :' ||rec_remit.societe || chr(10) ||
                         'région  :' ||rec_remit.region || chr(10) ||
                         'prlvt   :' ||rec_remit.type_prlvt;
        dka_tools_pkg.put_debug_message(vv_step);

        vv_societe     := rec_remit.societe;
        vv_region      := rec_remit.region;
        vv_bank_number := rec_remit.remit_bank_number;
        vv_prlvt       := rec_remit.type_prlvt;

        --Fermeture du fichier précédent
        IF File_Handle.id IS NOT NULL THEN
          vv_step := '008 : Nombre de lignes dans le fichier : ' || vn_nb_lignes;
          dka_tools_pkg.put_debug_message(vv_step);

          vv_step := '009 : Fermeture du fichier';
          dka_tools_pkg.put_debug_message(vv_step);
          UTL_FILE.fclose(File_Handle);

          vn_nb_fichier    := vn_nb_fichier + 1;
          vn_nb_lignes_tot := vn_nb_lignes_tot + vn_nb_lignes;
        END IF;

        --Création du nouveau fichier
        vv_file_name := vv_CODE_DIVISION || '_' || vv_bank_number || '-' ||
                        vv_societe || vv_region || rec_remit.TYPE_CAMPAGNE ||
                        rec_remit.type_prlvt || '-' ||
                        to_char(SYSDATE, 'YYYYMMDD') || '-' ||
                        fnd_global.CONC_REQUEST_ID || '_' ||
                        to_char(SYSDATE, 'YYYYMMDD-HH24MISS') || cv_ext;

        vv_step := '010 : Nom du fichier n°' || vn_nb_fichier || ' : ' || vv_file_name;
        dka_tools_pkg.put_debug_message(vv_step);

        File_Handle := UTL_FILE.FOPEN('DKA_DDIMPORT_DIR', vv_file_name, 'w', 2000);

        --LIGNE D'ENTETE
        vv_buffer := vv_FILE_INFORMATION_INDICATOR || cv_separateur ||
                     vv_CODE_DIVISION || '_' || rec_remit.AGORA_CODE || '_' ||
                     vv_bank_number || '-' || vv_societe || vv_region ||
                     rec_remit.TYPE_CAMPAGNE || rec_remit.type_prlvt || '-' ||
                     to_char(SYSDATE, 'YYYYMMDD') || '-' ||
                     fnd_global.CONC_REQUEST_ID || cv_separateur ||
                     vv_TYPE_INDICATOR || cv_separateur || CHR(13);

        vv_step := '011 : Ligne d''entete';
        dka_tools_pkg.put_debug_message(vv_step);
        UTL_FILE.PUT_LINE(File_Handle, vv_buffer);

        --LIGNE DE COLONNE
        vv_step := '012 : Ligne de colonne';
        dka_tools_pkg.put_debug_message(vv_step);
        UTL_FILE.PUT_LINE(File_Handle, vv_FILE_LAYOUT || CHR(13));
        vn_nb_lignes := 0;

      END IF;

    --ARA EDB379 : Cas EXPRESS : prendre la date d'échéance de chaque règlement
    IF rec_remit.TYPE_CAMPAGNE = 'PCX'
    THEN
      SELECT to_char(DUE_DATE, 'MM/DD/YYYY') , DUE_DATE
      INTO v_due_date_exp , v_due_date_dd
      FROM ar_payment_schedules_all aps
      where aps.cash_receipt_id = rec_remit.CASHRECEIPTID;

    v_value_date_exp := v_due_date_dd + 1;
    Dka_Tools_Pkg.Get_Next_Working_Day(v_value_date_exp);

    vv_step := '005a : Date de valeur :' || to_char(v_value_date_exp, 'dd/mm/yyyy');
    dka_tools_pkg.put_debug_message(vv_step);
    vv_step := '005b : Date de transaction :' ||to_char(v_due_date_dd, 'dd/mm/yyyy');
    dka_tools_pkg.put_debug_message(vv_step);

    --LIGNE DE CORPS
      vv_buffer := REPLACE(rec_remit.FORMAT1ENTITYID, cv_separateur) ||
                   cv_separateur || --01
                   REPLACE(vv_COUNTERPARTYID, cv_separateur) ||
                   cv_separateur || --02
                   REPLACE(to_char(v_value_date_exp, 'MM/DD/YYYY'),
                           cv_separateur) || cv_separateur || --03
                   REPLACE(v_due_date_exp,
                           cv_separateur) || cv_separateur || --04
                   REPLACE(vv_CURRENCYCODE, cv_separateur) || cv_separateur || --05
                   REPLACE(trim(' ' FROM to_char(rec_remit.REMIT_AMOUNT / 100,
                                        '99999999999999.99')),
                           cv_separateur) || cv_separateur || --06
                   REPLACE(vv_CASHFLOWTYPE, cv_separateur) || cv_separateur || --07
                   REPLACE(vv_PAYMENTMETHOD, cv_separateur) ||
                   cv_separateur || --08
                   REPLACE(rec_remit.DESCRIPTION_REFERENCE, cv_separateur) ||
                   cv_separateur || --09
                   REPLACE(rec_remit.CUSTOMERREFERENCENUMBER, cv_separateur) ||
                   cv_separateur || --10
                   '' || cv_separateur || --11
                   REPLACE(rec_remit.ENTITYBANKACCOUNTNUMBER, cv_separateur) ||
                   cv_separateur || --12
                   REPLACE(vv_ENTITYBANKACCOUNTCURRENCYCO, cv_separateur) ||
                   cv_separateur || --13
                   REPLACE(vv_SUPPLYCPTYDETAILS, cv_separateur) ||
                   cv_separateur || --14
                   REPLACE(rec_remit.COUNTERPARTYNAME, cv_separateur) ||
                   cv_separateur || --15
                   REPLACE(rec_remit.COUNTERPARTYADDRESS1, cv_separateur) ||
                   cv_separateur || --16
                   REPLACE(rec_remit.COUNTERPARTYADDRESS2, cv_separateur) ||
                   cv_separateur || --17
                   REPLACE(rec_remit.COUNTERPARTYADDRESS3, cv_separateur) ||
                   cv_separateur || --18
                   REPLACE(rec_remit.COUNTERPARTYADDRESS4, cv_separateur) ||
                   cv_separateur || --19
                   REPLACE(rec_remit.COUNTERPARTYZIP, cv_separateur) ||
                   cv_separateur || --20
                   REPLACE(rec_remit.COUNTERPARTYCITY, cv_separateur) ||
                   cv_separateur || --21
                   REPLACE(vv_CPTYPRIMARYACCOUNTNUMBERTYP, cv_separateur) ||
                   cv_separateur || --22
                   REPLACE(vv_CPTYSECONDARYACCOUNTNUMBERT, cv_separateur) ||
                   cv_separateur || --23
                   REPLACE(rec_remit.COUNTERPARTYCOUNTRYCODE, cv_separateur) ||
                   cv_separateur || --24
                   REPLACE(rec_remit.COUNTERPARTYBANKACCOUNTNUMBER,
                           cv_separateur) || cv_separateur || --25
                   REPLACE(rec_remit.CPTYSECONDARYACCOUNTNUMBER,
                           cv_separateur) || cv_separateur || --26
                   REPLACE(rec_remit.COUNTERPARTYBANKNAME, cv_separateur) ||
                   cv_separateur || --27
                   REPLACE(vv_COUNTERPARTYBANKACCOUNTCOUN, cv_separateur) ||
                   cv_separateur || --28
                   REPLACE(vv_COUNTERPARTYBANKACCOUNTCURC, cv_separateur) ||
                   cv_separateur || --29
                   REPLACE(rec_remit.COUNTERPARTYBANKCODE, cv_separateur) ||
                   cv_separateur || --30
                   REPLACE(vv_COUNTERPARTYBANKCODETYPE, cv_separateur) ||
                   cv_separateur || --31
                   REPLACE(rec_remit.COUNTERPARTYBANKADDRESS, cv_separateur) ||
                   cv_separateur || --32
                   REPLACE(rec_remit.COUNTERPARTYBANKADDRESS2,
                           cv_separateur) || cv_separateur || --33
                   REPLACE(rec_remit.COUNTERPARTYBANKCITY, cv_separateur) ||
                   cv_separateur || --34
                   REPLACE(rec_remit.COUNTERPARTYBANKZIP, cv_separateur) ||
                   cv_separateur || --35
                   REPLACE(rec_remit.COUNTERPARTYMESSAGE, cv_separateur) ||
                   cv_separateur || --36
                   REPLACE(rec_remit.BANKPREAUTHORIZATIONID, cv_separateur) ||
                   cv_separateur || --37
                   REPLACE(rec_remit.CREATIONDATE, cv_separateur) ||
                   cv_separateur || --38
                   '' || cv_separateur || --39
                   REPLACE(vv_SUPPLYPAYINGACCOUNT, cv_separateur) ||
                   cv_separateur || --40
                   REPLACE(vv_TRANSACTIONTYPECODE, cv_separateur) ||
                   cv_separateur || --41
                   '' || cv_separateur || --42
                   '' || cv_separateur || --43
                   '' || cv_separateur || --44
                   REPLACE(rec_remit.SEPAMANDATEID, cv_separateur) ||
                   cv_separateur || --45
                   REPLACE(to_char(rec_remit.SEPAMANDATEDATE, 'MM/DD/YYYY'),
                           cv_separateur) || cv_separateur || --46
                   REPLACE(rec_remit.SEPACREDITORSCHEMEID, cv_separateur) ||
                   cv_separateur || --47
                   REPLACE(vv_SEPAPAYMENTFORMAT, cv_separateur) ||
                   cv_separateur || --48
                   REPLACE(rec_remit.SEPADDTYPE, cv_separateur) ||
                   cv_separateur || --49
                   REPLACE(rec_remit.SEPAORIGINALMANDATEID, cv_separateur) ||
                   cv_separateur || --50
                   REPLACE(rec_remit.SEPAORIGINALCREDITORSCHEMEID,
                           cv_separateur) || cv_separateur || --51
                   REPLACE(rec_remit.SEPAORIGINALCREDITORAGENT,
                           cv_separateur) || cv_separateur || --52
                   REPLACE(rec_remit.SEPAORIGINALDEBTORAGENT, cv_separateur) ||
                   cv_separateur || --53
                   REPLACE(rec_remit.SEPAORIGINALDEBTORACCOUNT,
                           cv_separateur) || cv_separateur || --54
                   CHR(13);

    BEGIN

    UPDATE ar_cash_receipts
    SET attribute4 = v_value_date_exp
    WHERE cash_receipt_id = rec_remit.CASHRECEIPTID;

    UPDATE DKA_SARAUTOPRELEV_TMP
    SET STATUS = 'PRINT',
        VALUEDATE = v_value_date_exp,
        TRANSACTIONDATE = v_due_date_dd
    WHERE STATUS = 'NEW'
    AND TYPE_CAMPAGNE = 'PCX'
    AND CASHRECEIPTID = rec_remit.CASHRECEIPTID;

    COMMIT;

    END;


    ELSE

    --LIGNE DE CORPS
      vv_buffer := REPLACE(rec_remit.FORMAT1ENTITYID, cv_separateur) ||
                   cv_separateur || --01
                   REPLACE(vv_COUNTERPARTYID, cv_separateur) ||
                   cv_separateur || --02
                   REPLACE(to_char(vd_value_date, 'MM/DD/YYYY'),
                           cv_separateur) || cv_separateur || --03
                   REPLACE(to_char(vd_transaction_date, 'MM/DD/YYYY'),
                           cv_separateur) || cv_separateur || --04
                   REPLACE(vv_CURRENCYCODE, cv_separateur) || cv_separateur || --05
                   REPLACE(trim(' ' FROM to_char(rec_remit.REMIT_AMOUNT / 100,
                                        '99999999999999.99')),
                           cv_separateur) || cv_separateur || --06
                   REPLACE(vv_CASHFLOWTYPE, cv_separateur) || cv_separateur || --07
                   REPLACE(vv_PAYMENTMETHOD, cv_separateur) ||
                   cv_separateur || --08
                   REPLACE(rec_remit.DESCRIPTION_REFERENCE, cv_separateur) ||
                   cv_separateur || --09
                   REPLACE(rec_remit.CUSTOMERREFERENCENUMBER, cv_separateur) ||
                   cv_separateur || --10
                   '' || cv_separateur || --11
                   REPLACE(rec_remit.ENTITYBANKACCOUNTNUMBER, cv_separateur) ||
                   cv_separateur || --12
                   REPLACE(vv_ENTITYBANKACCOUNTCURRENCYCO, cv_separateur) ||
                   cv_separateur || --13
                   REPLACE(vv_SUPPLYCPTYDETAILS, cv_separateur) ||
                   cv_separateur || --14
                   REPLACE(rec_remit.COUNTERPARTYNAME, cv_separateur) ||
                   cv_separateur || --15
                   REPLACE(rec_remit.COUNTERPARTYADDRESS1, cv_separateur) ||
                   cv_separateur || --16
                   REPLACE(rec_remit.COUNTERPARTYADDRESS2, cv_separateur) ||
                   cv_separateur || --17
                   REPLACE(rec_remit.COUNTERPARTYADDRESS3, cv_separateur) ||
                   cv_separateur || --18
                   REPLACE(rec_remit.COUNTERPARTYADDRESS4, cv_separateur) ||
                   cv_separateur || --19
                   REPLACE(rec_remit.COUNTERPARTYZIP, cv_separateur) ||
                   cv_separateur || --20
                   REPLACE(rec_remit.COUNTERPARTYCITY, cv_separateur) ||
                   cv_separateur || --21
                   REPLACE(vv_CPTYPRIMARYACCOUNTNUMBERTYP, cv_separateur) ||
                   cv_separateur || --22
                   REPLACE(vv_CPTYSECONDARYACCOUNTNUMBERT, cv_separateur) ||
                   cv_separateur || --23
                   REPLACE(rec_remit.COUNTERPARTYCOUNTRYCODE, cv_separateur) ||
                   cv_separateur || --24
                   REPLACE(rec_remit.COUNTERPARTYBANKACCOUNTNUMBER,
                           cv_separateur) || cv_separateur || --25
                   REPLACE(rec_remit.CPTYSECONDARYACCOUNTNUMBER,
                           cv_separateur) || cv_separateur || --26
                   REPLACE(rec_remit.COUNTERPARTYBANKNAME, cv_separateur) ||
                   cv_separateur || --27
                   REPLACE(vv_COUNTERPARTYBANKACCOUNTCOUN, cv_separateur) ||
                   cv_separateur || --28
                   REPLACE(vv_COUNTERPARTYBANKACCOUNTCURC, cv_separateur) ||
                   cv_separateur || --29
                   REPLACE(rec_remit.COUNTERPARTYBANKCODE, cv_separateur) ||
                   cv_separateur || --30
                   REPLACE(vv_COUNTERPARTYBANKCODETYPE, cv_separateur) ||
                   cv_separateur || --31
                   REPLACE(rec_remit.COUNTERPARTYBANKADDRESS, cv_separateur) ||
                   cv_separateur || --32
                   REPLACE(rec_remit.COUNTERPARTYBANKADDRESS2,
                           cv_separateur) || cv_separateur || --33
                   REPLACE(rec_remit.COUNTERPARTYBANKCITY, cv_separateur) ||
                   cv_separateur || --34
                   REPLACE(rec_remit.COUNTERPARTYBANKZIP, cv_separateur) ||
                   cv_separateur || --35
                   REPLACE(rec_remit.COUNTERPARTYMESSAGE, cv_separateur) ||
                   cv_separateur || --36
                   REPLACE(rec_remit.BANKPREAUTHORIZATIONID, cv_separateur) ||
                   cv_separateur || --37
                   REPLACE(rec_remit.CREATIONDATE, cv_separateur) ||
                   cv_separateur || --38
                   '' || cv_separateur || --39
                   REPLACE(vv_SUPPLYPAYINGACCOUNT, cv_separateur) ||
                   cv_separateur || --40
                   REPLACE(vv_TRANSACTIONTYPECODE, cv_separateur) ||
                   cv_separateur || --41
                   '' || cv_separateur || --42
                   '' || cv_separateur || --43
                   '' || cv_separateur || --44
                   REPLACE(rec_remit.SEPAMANDATEID, cv_separateur) ||
                   cv_separateur || --45
                   REPLACE(to_char(rec_remit.SEPAMANDATEDATE, 'MM/DD/YYYY'),
                           cv_separateur) || cv_separateur || --46
                   REPLACE(rec_remit.SEPACREDITORSCHEMEID, cv_separateur) ||
                   cv_separateur || --47
                   REPLACE(vv_SEPAPAYMENTFORMAT, cv_separateur) ||
                   cv_separateur || --48
                   REPLACE(rec_remit.SEPADDTYPE, cv_separateur) ||
                   cv_separateur || --49
                   REPLACE(rec_remit.SEPAORIGINALMANDATEID, cv_separateur) ||
                   cv_separateur || --50
                   REPLACE(rec_remit.SEPAORIGINALCREDITORSCHEMEID,
                           cv_separateur) || cv_separateur || --51
                   REPLACE(rec_remit.SEPAORIGINALCREDITORAGENT,
                           cv_separateur) || cv_separateur || --52
                   REPLACE(rec_remit.SEPAORIGINALDEBTORAGENT, cv_separateur) ||
                   cv_separateur || --53
                   REPLACE(rec_remit.SEPAORIGINALDEBTORACCOUNT,
                           cv_separateur) || cv_separateur || --54
                   CHR(13);

      -- 2.3.1.12 - Ajout de la date de prélèvement dans le CUF Attribute4
      UPDATE ar_cash_receipts
      SET attribute4 = vd_value_date
      WHERE cash_receipt_id = rec_remit.CASHRECEIPTID;

    END IF;


      --LIGNE DE DONNEES
      vv_step := '013 : Ligne de corps';
      dka_tools_pkg.put_debug_message(vv_step);
      UTL_FILE.PUT_LINE(File_Handle, vv_buffer);

      vn_nb_lignes := vn_nb_lignes + 1;

    END LOOP;

    IF File_Handle.id IS NOT NULL THEN
      vv_step := '014 : Nombre de lignes dans le fichier : ' || vn_nb_lignes;
      dka_tools_pkg.put_debug_message(vv_step);

      vv_step := '015 : Fermeture du dernier fichier';
      dka_tools_pkg.put_debug_message(vv_step);
      UTL_FILE.fclose(File_Handle);

      vn_nb_fichier    := vn_nb_fichier + 1;
      vn_nb_lignes_tot := vn_nb_lignes_tot + vn_nb_lignes;
    END IF;

    vv_step := '016 : Nombre de lignes parcourues : ' || vn_nb_lignes_tot;
    dka_tools_pkg.put_debug_message(vv_step);

    vv_step := '017 : Nombre de ligne mis à PRINT';
    dka_tools_pkg.put_debug_message(vv_step);

    UPDATE DKA_SARAUTOPRELEV_TMP
    SET STATUS          = 'PRINT',
        VALUEDATE       = vd_value_date,
        TRANSACTIONDATE = vd_transaction_date
    WHERE STATUS = 'NEW'
  AND TYPE_CAMPAGNE != 'PCX'; --ARA EDB379
    vv_step := '017 : ' || SQL%ROWCOUNT;
    dka_tools_pkg.put_debug_message(vv_step);

    ----------------------------------------------------------------------------------------------------------------------
    --<DD IMPORT
    ----------------------------------------------------------------------------------------------------------------------

    vv_step := '999 : FIN';
    dka_tools_pkg.put_debug_message(vv_step);

  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := vv_step || ' : ' || SQLERRM;
      DKA_TOOLS_PKG.put_log_message('Erreur lors de : ' || pv_errbuf);
  END CREATE_DDIMPORT;

  -----------------------------------------------------------------
  --  Nom           : MAIN
  --  Description   : Procédure appelee par le traitement
  --                  DKA : Règlements automatiques effet de commerce des factures clients
  --
  --  PARAMETRES :
  --     pv_errbuf       Sortie  --> Varchar2
  --     pn_retcode      Sortie  --> Number
  --
  --  VALEUR RETOURNEE :
  --
  -----------------------------------------------------------------
  PROCEDURE MAIN(pv_errbuf        IN OUT NOCOPY VARCHAR2,
                 pn_retcode       IN OUT NOCOPY NUMBER,
                 pv_date_echeance IN VARCHAR2) IS

    CURSOR cur_org_num_emetteur IS
    SELECT DISTINCT hou.organization_id org_id,
                    hou.name            org_name,
                    gl.ledger_id
    FROM fnd_flex_value_sets       ffvs
    JOIN fnd_flex_values           ffv  on(ffv.flex_value_set_id = ffvs.flex_value_set_id)
    JOIN hr_operating_units        hou  on(substr(hou.name, -4) = ffv.flex_value)
    JOIN gl_ledgers                gl   on (gl.SHORT_NAME = ffv.flex_value)
    JOIN gl_access_set_assignments gasa on (gl.ledger_id = gasa.ledger_id)
    WHERE 1 = 1
      AND ffvs.flex_value_set_name = 'DAOPCCF_STE'
      AND ffv.value_category = 'DAOPCCF_STE'
      AND ffv.attribute15 /*ffv.attribute10*/ IS NOT NULL
      AND gl.ledger_category_code = 'PRIMARY'
      AND gasa.access_set_id = Fnd_Profile.VALUE('GL_ACCESS_SET_ID'); -- OBE

  /*CURSOR cur_methods IS
      SELECT arm.receipt_method_id,
             arc.receipt_class_id,
             arm.name,
             abb.bank_branch_id,
             abaa.bank_account_id
        FROM ar_receipt_methods             arm,
             ar_receipt_classes             arc,
             ar_receipt_method_accounts_all armaa,
             ap_bank_branches               abb,
             ap_bank_accounts_all           abaa
       WHERE arc.receipt_class_id = arm.receipt_class_id
         AND armaa.receipt_method_id = arm.receipt_method_id
         AND abb.bank_branch_id = abaa.bank_branch_id
         AND armaa.bank_account_id = abaa.bank_account_id
         AND arm.start_date <= trunc(SYSDATE)
         AND nvl(arm.end_date, trunc(SYSDATE)) >= trunc(SYSDATE)
         AND armaa.start_date <= trunc(SYSDATE)
         AND nvl(armaa.end_date, trunc(SYSDATE)) >= trunc(SYSDATE)
         AND nvl(abb.end_date, trunc(SYSDATE)) >= trunc(SYSDATE)
         AND nvl(abaa.inactive_date, trunc(SYSDATE)) >= trunc(SYSDATE)
         AND arc.name = 'PRELEVEMENT'
         AND armaa.org_id = g_organisation_user
         and exists
       (select 1
                from RA_CUSTOMER_TRX_ALL rct, AR_PAYMENT_SCHEDULES_ALL apsa
               where rct.RECEIPT_METHOD_ID = arm.RECEIPT_METHOD_ID
                 and APSA.CUSTOMER_TRX_ID = RCT.CUSTOMER_TRX_ID
                 and APSA.STATUS = 'OP'
                 and APSA.GL_DATE_CLOSED =
                     to_date('4712/12/31', 'YYYY/MM/DD')
                 and APSA.SELECTED_FOR_RECEIPT_BATCH_ID is null
                 and APSA.DUE_DATE <= trunc(SYSDATE) + ARM.LEAD_DAYS -- M3
                 and APSA.RESERVED_TYPE IS NULL
                 and APSA.RESERVED_VALUE IS NULL
                 and RCT.TERM_DUE_DATE <= trunc(SYSDATE) + ARM.LEAD_DAYS -- M3
              )
      \*AND abaa.bank_account_id IN (33380)*\;*/

    -- selection des lots de remise en banque (p24-26 de la spec)
    CURSOR cur_lots_remise(pn_ledger_id gl_ledgers.ledger_id%TYPE) IS
    SELECT arm.receipt_method_id,
           arc.receipt_class_id,
           arm.name,
           cbbv.branch_party_id  bank_branch_id,
           cbu.bank_acct_use_id  bank_account_id -- OBE
           --cba.bank_account_id                 -- OBE
    FROM ar_cash_receipts               cr
    JOIN ar_payment_schedules           ps   on(ps.cash_receipt_id = cr.cash_receipt_id)
    JOIN ar_cash_receipt_history        crh  on(crh.cash_receipt_id = cr.cash_receipt_id)
    JOIN ar_receipt_methods             arm  on(arm.receipt_method_id = cr.receipt_method_id)
    JOIN ar_receipt_classes             arc  on(arc.receipt_class_id = arm.receipt_class_id)
    JOIN ar_receipt_method_accounts_all arma on(arma.receipt_method_id = arm.receipt_method_id and arma.remit_bank_acct_use_id = cr.remit_bank_acct_use_id)
    JOIN ce_bank_acct_uses              cbu  on(cbu.bank_acct_use_id = arma.remit_bank_acct_use_id)
    JOIN ce_bank_accounts               cba  on(cba.bank_account_id = cbu.bank_account_id)  --ap_bank_accounts_all  abaa,
    JOIN ce_bank_branches_v             cbbv on(cbbv.branch_party_id = cba.bank_branch_id)    --ap_bank_branches               abb,
    WHERE 1 = 1
      AND cr.selected_remittance_batch_id IS NULL
      AND (cr.amount >= 0 or (cr.amount < 0 AND cr.type = 'MISC'))
      AND cr.set_of_books_id = pn_ledger_id
      AND crh.status = 'CONFIRMED'
      AND crh.current_record_flag = 'Y'
      AND arc.name = 'PRELEVEMENT'
      AND arma.org_id = g_organisation_user
      AND trunc(SYSDATE) between arm.start_date and nvl(arm.end_date, trunc(SYSDATE))
      AND trunc(SYSDATE) between arma.start_date and nvl(arma.end_date, trunc(SYSDATE))
      AND trunc(SYSDATE) <= nvl(cbu.end_date, trunc(SYSDATE))
      AND trunc(SYSDATE) <= nvl(cba.end_date, trunc(SYSDATE))
      AND trunc(SYSDATE) <= nvl(cbbv.end_date, trunc(SYSDATE))
      AND not exists (select 1
                      from ar_lookups l
                      where nvl(cr.reversal_category, '~') = l.lookup_code
                        and l.lookup_type = 'REVERSAL_CATEGORY_TYPE')

      --EDB379
      AND NVL(cr.ATTRIBUTE8, 'N') != 'Y'

      GROUP BY arm.receipt_method_id,
               arc.receipt_class_id,
               arm.name,
               cbbv.branch_party_id,
               cbu.bank_acct_use_id   -- OBE
               --cba.bank_account_id  -- OBE
               ;

  CURSOR cur_lots_express(pn_ledger_id gl_ledgers.ledger_id%TYPE) IS
    SELECT arm.receipt_method_id,
           arc.receipt_class_id,
           arm.name,
           cbbv.branch_party_id  bank_branch_id,
           cbu.bank_acct_use_id  bank_account_id,
       cr.cash_receipt_id,
       ps.due_date ,
       to_char(ps.due_date, 'YYYYMMDD') due_date1,
       cr.receipt_number,
     cr.org_id
    FROM ar_cash_receipts               cr
    JOIN ar_payment_schedules           ps   on(ps.cash_receipt_id = cr.cash_receipt_id)
    JOIN ar_cash_receipt_history        crh  on(crh.cash_receipt_id = cr.cash_receipt_id)
    JOIN ar_receipt_methods             arm  on(arm.receipt_method_id = cr.receipt_method_id)
    JOIN ar_receipt_classes             arc  on(arc.receipt_class_id = arm.receipt_class_id)
    JOIN ar_receipt_method_accounts_all arma on(arma.receipt_method_id = arm.receipt_method_id and arma.remit_bank_acct_use_id = cr.remit_bank_acct_use_id)
    JOIN ce_bank_acct_uses              cbu  on(cbu.bank_acct_use_id = arma.remit_bank_acct_use_id)
    JOIN ce_bank_accounts               cba  on(cba.bank_account_id = cbu.bank_account_id)  --ap_bank_accounts_all  abaa,
    JOIN ce_bank_branches_v             cbbv on(cbbv.branch_party_id = cba.bank_branch_id)    --ap_bank_branches               abb,
    WHERE 1 = 1
      AND cr.selected_remittance_batch_id IS NULL
      AND (cr.amount >= 0 or (cr.amount < 0 AND cr.type = 'MISC'))
      AND cr.set_of_books_id = pn_ledger_id
      AND crh.status = 'CONFIRMED'
      AND crh.current_record_flag = 'Y'
      AND arc.name = 'PRELEVEMENT'
      AND arma.org_id = g_organisation_user
      AND trunc(SYSDATE) between arm.start_date and nvl(arm.end_date, trunc(SYSDATE))
      AND trunc(SYSDATE) between arma.start_date and nvl(arma.end_date, trunc(SYSDATE))
      AND trunc(SYSDATE) <= nvl(cbu.end_date, trunc(SYSDATE))
      AND trunc(SYSDATE) <= nvl(cba.end_date, trunc(SYSDATE))
      AND trunc(SYSDATE) <= nvl(cbbv.end_date, trunc(SYSDATE))
      AND not exists (select 1
                      from ar_lookups l
                      where nvl(cr.reversal_category, '~') = l.lookup_code
                        and l.lookup_type = 'REVERSAL_CATEGORY_TYPE')

    --EXPRESS
      AND cr.ATTRIBUTE8 = 'Y'
      AND cr.created_by != '1205'

      GROUP BY arm.receipt_method_id,
               arc.receipt_class_id,
               arm.name,
               cbbv.branch_party_id,
               cbu.bank_acct_use_id,   -- OBE
         cr.cash_receipt_id,
           ps.due_date,
         cr.receipt_number,
     cr.org_id
               --cba.bank_account_id  -- OBE
               ;



    lv_today        VARCHAR2(30);
    ln_cpt          PLS_INTEGER;
    ln_ledger_id    NUMBER;
    lv_printer_name VARCHAR2(100);
    lv_step         VARCHAR2(1000);
    lf_file         utl_file.file_type;
    lv_filename     VARCHAR2(1000);
    -- Modif GV20090318 : il faut prendre le bank_number (code banque) au lieu du bank_num (code guichet)
    --lv_bank_num_prec               dka_sarautoprelev_tmp.remit_bank_num%TYPE;
    lv_bank_number_prec dka_sarautoprelev_tmp.remit_bank_number%TYPE;
    --
    lv_remit_ref_prec dka_sarautoprelev_tmp.remit_reference%TYPE;
    lv_ligne          VARCHAR2(1000);
    ln_tot_amount     NUMBER;
    lv_eft_code       dka_sarautoprelev_tmp.eft_code%TYPE;
    --vn_nb_jours       ar_receipt_methods.lead_days%TYPE; --JWY INC0422554

    l_prog_application_id          NUMBER(15);
    l_prog_application_short_name  VARCHAR2(50);
    l_program_id                   NUMBER(15);
    l_prog_application_id2         NUMBER(15);
    l_prog_application_short_name2 VARCHAR2(50);
    l_program_id2                  NUMBER(15);
    l_message                      VARCHAR2(240);
    l_printing                     BOOLEAN;
    l_batch_param                  fnd_concurrent_requests.argument2%type;

    e_last_day         EXCEPTION;
    e_org_id           EXCEPTION;
    e_create_receipt   EXCEPTION;
    e_create_seq       EXCEPTION;
    e_create_corr      EXCEPTION;
    e_create_remit     EXCEPTION;
    tv_tab_trt         dka_tab_trt; --> Ajout GV20090324
    i                  NUMBER := 0; --> Ajout GV20090324
    vn_request_id      NUMBER; --> Ajout GV20090324
    vn_result          NUMBER; --> Ajout GV20090324
    vv_printer_treso   fnd_profile_option_values.profile_option_value%TYPE; --> ajout fmi eis20100069

    vv_sqlstmt             VARCHAR2(250);
    vv_PHASE               VARCHAR2(30);
    vv_STATUS              VARCHAR2(30);
    vv_DEV_PHASE           VARCHAR2(30);
    vv_DEV_STATUS          VARCHAR2(30);
    vv_MESSAGE             VARCHAR2(30);
    vn_CREATE_DD_IMPORT_ID NUMBER;
    v_settle_batches_id    NUMBER;

    gn_retcode             NUMBER;

  vv_date_echeance VARCHAR2(30);
  vv_date_eche_old DATE;

  --ARA EDB379
  vv_type_echeance  varchar2(40);
  vv_date_prov DATE;
  vv_date_orig DATE;

  BEGIN

    -- Modif GV20090324: on alimente la variable globale gd_remit_date, car on en a besoin
    -- pour la création du fichier
    gd_remit_date := to_date(pv_date_echeance, 'YYYYMMDD');

    gn_request_id := fnd_global.conc_request_id;

    /* <JWY INC0422554

    -- Calcul du nombre de jours par rapport à la date d'échéance
    SELECT gd_remit_date - trunc(SYSDATE) INTO vn_nb_jours FROM DUAL;

    -- Mise à jour du champ LEAD_DAYS de AR_RECEIPT_METHOD
    UPDATE ar_receipt_methods arm
       SET lead_days = vn_nb_jours
     WHERE EXISTS (select null
              from ar_receipt_classes arc
             where arc.receipt_class_id = arm.receipt_class_id
               and arc.name = 'PRELEVEMENT');

      JWY INC0422554/>     */


    --JVI 21/12/2009
    -- recuperation des parametres de dka_parameters
    init_params();

    -->JJA 11/07/2013
    -- Suppression des tables de sauvegarde de plus de 30 jours --
    --------------------------------------------------------------
    Dka_Tools_Pkg.put_log_message('Suppression des tables de sauvegarde de la table DKA_SAPAUTORGT1_TMP');
    delete_save_tables('DKA_SARAUTOPRLV');

    -- Sauvegarde de la table de travail précédente             --
    --------------------------------------------------------------
    Dka_Tools_Pkg.put_log_message('Création de la table DKA_SARAUTOPRELEV_TMP' ||
                                  TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS'));
    vv_sqlstmt := 'CREATE TABLE DKA.DKA_SARAUTOPRLV_' ||
                  TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') ||
                  ' AS SELECT * FROM DKA.DKA_SARAUTOPRELEV_TMP';
    EXECUTE IMMEDIATE vv_sqlstmt;

    -- Vider la table temporaire
    --DELETE FROM DKA_SARAUTOPRELEV_TMP;
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DKA.DKA_SARAUTOPRELEV_TMP'; /*<AUTO_COMMIT>*/

  --ARA EDB379
  --Sauvegarde de la table de travail DKA_SARAUTOPRELEV_EXP_STAT
  Dka_Tools_Pkg.put_log_message('Création de la table DKA_SARPRLV_EXP_' ||  --BBM
                                  TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS'));
    vv_sqlstmt := 'CREATE TABLE DKA.DKA_SARPRLV_EXP_' ||   --BBM
                  TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') ||
                  ' AS SELECT * FROM DKA.DKA_SARAUTOPRELEV_EXP_STAT';
    EXECUTE IMMEDIATE vv_sqlstmt;

    -- Vider la table temporaire
    --DELETE FROM DKA_SARAUTOPRELEV_TMP;
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DKA.DKA_SARAUTOPRELEV_EXP_STAT'; /*<AUTO_COMMIT>*/

    --<JJA 11/07/2013

    -- Création des sequences pour les prelevements AR
    --create_seq_prlv_ar(pn_retcode, pv_errbuf);

    --IF pn_retcode <> 0 THEN
    --  RAISE e_create_seq;
    --END IF;

    DKA_TOOLS_PKG.put_log_message('Creation du parametrage des codes operation.');
    -- Creation du parametrage des codes operation
    DKA_AR_TOOLS_PKG.alim_corresp_operations('PRELEVEMENTS',
                                              pn_retcode,
                                              pv_errbuf);
    DKA_TOOLS_PKG.put_log_message('Creation du parametrage des codes operation fin.');
    IF pn_retcode <> 0 THEN
      RAISE e_create_corr;
    END IF;

    -- verifier que le jour actuel appartient a une periode ouverte
    lv_step := 'verifier que le jour actuel appartient a une periode ouverte';

    lv_today := fnd_date.date_to_canonical(SYSDATE);

    FOR rec_org_num_emetteur IN cur_org_num_emetteur LOOP
      BEGIN
        pn_retcode := 0;

        DKA_TOOLS_PKG.put_log_message('organisation à traiter :'||rec_org_num_emetteur.org_name);

        po_moac_utils_pvt.set_org_context(rec_org_num_emetteur.org_id);
        MO_GLOBAL.INIT('AR');

        g_organisation_user := rec_org_num_emetteur.org_id;

        fnd_request.set_org_id(g_organisation_user);


        SELECT COUNT(1)
        INTO ln_cpt
        FROM gl_period_statuses gps
        WHERE gps.set_of_books_id = rec_org_num_emetteur.ledger_id
          AND gps.application_id = 222
          AND gps.closing_status = 'O'
          AND sysdate BETWEEN gps.start_date AND gps.end_date;

        IF ln_cpt = 0 THEN
          RAISE e_last_day;
        END IF;

        -- Pour chaque ligne du curseur lancer le traitement "Programme de création de remises automatiques (API)"
        -- Récupération des identifiants programme
        lv_step := 'Récupération des identifiants programme';
        SELECT fcp.application_id,
               fa.application_short_name,
               fcp.concurrent_program_id
          INTO l_prog_application_id,
               l_prog_application_short_name,
               l_program_id
          FROM fnd_concurrent_programs fcp,
               fnd_application         fa
         WHERE fcp.concurrent_program_name = 'AUTOREMAPI'
           AND fa.application_id = fcp.application_id;

    --ARA EDB379
    BEGIN
     SELECT STATUS_TRAITEMENT
     INTO vv_type_echeance
     FROM DKA_SARAUTOPRELEV_STAT;

    END;

    --ARA EDB379
    IF vv_type_echeance = 'EXPRESS' THEN

    FOR rec_lots_express IN cur_lots_express(rec_org_num_emetteur.ledger_id) LOOP
          -- si erreur, on continue de parcourir le curseur
          BEGIN

            lv_step := 'Recherche de l''imprimante';
            lv_printer_name := get_printer_name(k_user_name, substr(rec_org_num_emetteur.org_name,1,3));

            l_printing := fnd_request.set_print_options(printer => lv_printer_name,
                                                        copies  => 0);
            i := i + 1;
            dka_tools_pkg.put_log_message('Région/ imprimante : '||substr(rec_org_num_emetteur.org_name,1,3)||'/ '||lv_printer_name); -- OBE artf2432851

      dka_tools_pkg.put_debug_message('rec_lots_express.due_date : '||rec_lots_express.due_date);
      dka_tools_pkg.put_debug_message('rec_lots_express.due_date_1 : '||rec_lots_express.due_date1);
      dka_tools_pkg.put_debug_message('trunc(SYSDATE) : '||trunc(SYSDATE));

      vv_date_eche_old := rec_lots_express.due_date;

      dka_tools_pkg.put_debug_message('vv_date_eche_old : '||vv_date_eche_old);

      IF rec_lots_express.due_date < trunc(SYSDATE)
      THEN

      BEGIN

      UPDATE ar_payment_schedules_all
      SET due_date = trunc(sysdate)
      WHERE cash_receipt_id = rec_lots_express.cash_receipt_id;

      COMMIT;

      BEGIN

      SELECT to_char(due_date, 'YYYYMMDD')
      INTO vv_date_echeance
      FROM ar_payment_schedules_all
      WHERE cash_receipt_id = rec_lots_express.cash_receipt_id;

      END;

      rec_lots_express.due_date1 := vv_date_echeance;

      EXCEPTION
      WHEN OTHERS THEN
      dka_tools_pkg.put_log_message(SQLERRM);
      END;

      END IF;

      lv_step := 'Lancement du traitement de création des remises';
      create_remit_express(l_prog_application_short_name,
           lv_today,
           rec_lots_express.receipt_class_id,
           rec_lots_express.receipt_method_id,
           rec_lots_express.bank_branch_id,
           rec_lots_express.bank_account_id,
           rec_lots_express.due_date1,--pv_date_echeance,
           rec_lots_express.receipt_number,
           g_organisation_user,
           vn_request_id,
           pn_retcode,
           pv_errbuf);


            IF pn_retcode != 0 THEN
              dka_tools_pkg.put_log_message('Erreur lors de la création des remises pour la méthode '||rec_lots_express.name||'(id='||rec_lots_express.receipt_method_id||')');
              dka_tools_pkg.put_log_message(pv_errbuf);

              --Remise de la date exigibilité avant erreur
              BEGIN

              UPDATE ar_payment_schedules_all
              SET due_date = vv_date_eche_old
              WHERE cash_receipt_id = rec_lots_express.cash_receipt_id;

              COMMIT;

              END;


            ELSE


              -- Alimentation de la table temporaire dka_sarautoprelev_tmp pour la création des fichiers à envoyer à la banque
              lv_step := 'Récupération de l''ID du lot de remise en banque';
              select fcr.argument2
              into l_batch_param
              from fnd_concurrent_requests fcr
              join fnd_concurrent_programs fcp on(fcp.application_id = fcr.program_application_id  and fcp.concurrent_program_id = fcr.concurrent_program_id)
              where 1 = 1
                and parent_request_id = vn_request_id
                and fcp.concurrent_program_name = 'ARZCARPO';

              lv_step := 'Alimentation de la table dka_sarautoprelev_tmp';
              INSERT_PRELEV_EXP(pv_errbuf   => pv_errbuf,
                            pn_retcode  => pn_retcode,
                            pv_batch_id => l_batch_param
              );

            END IF;

            -- On stocke le request_id et l'imprimante associée
            tv_tab_trt(i).request_id := vn_request_id;
            tv_tab_trt(i).printer_name := lv_printer_name;
          EXCEPTION
            WHEN OTHERS THEN
              dka_tools_pkg.put_log_message('Erreur à l''étape ' || lv_step);
              dka_tools_pkg.put_log_message(pv_errbuf || '--' || SQLERRM);
          END;
        END LOOP;

    ELSE

    --ARA EDB379 Cas ECHE10,ECHE20 ou ECHEFDM, on m-a-j la date exigibilité des reglements express où date > date ECHE10,ECHE20 ou ECHEFDM
    SELECT CASE WHEN vv_type_echeance = 'ECHE10'  THEN trunc(add_months(SYSDATE, 1), 'MM') + 10 --Le 10 du mois suivant +1
              WHEN vv_type_echeance = 'ECHE20'  THEN trunc(SYSDATE, 'MM') + 20           --Le 20 du mois en cours +1
              WHEN vv_type_echeance = 'ECHEFDM' THEN trunc(last_day(SYSDATE)) +1                  --Le dernier jour du mois en cours +1
                ELSE NULL END
     INTO vv_date_prov
     FROM DUAL;

    FOR rec_lots_express IN cur_lots_express(rec_org_num_emetteur.ledger_id) LOOP

    INSERT INTO DKA_SARAUTOPRELEV_EXP_STAT
    (TYPE_ECHEANCE,
    CASH_RECEIPT_ID,
    RECEIPT_NUMBER,
    DATE_ORIGINALE,
    date_provisoire,
    org_id,
    request_id,
    LAST_UPDATE_DATE)
    VALUES
    (
     vv_type_echeance,
     rec_lots_express.cash_receipt_id,
     rec_lots_express.receipt_number,
     rec_lots_express.due_date, --date_originale
     vv_date_prov, --date_provisoire
     rec_lots_express.org_id,
     gn_request_id,
     SYSDATE
    );

    UPDATE ar_payment_schedules_all
    SET due_date = vv_date_prov
    WHERE cash_receipt_id = rec_lots_express.cash_receipt_id;

    END LOOP;

  COMMIT;


        lv_step := 'Avant de rentrer dans la boucle lots_remise';

        FOR rec_lots_remise IN cur_lots_remise(rec_org_num_emetteur.ledger_id) LOOP
          -- si erreur, on continue de parcourir le curseur



          BEGIN
            lv_step := 'Recherche de l''imprimante';
            lv_printer_name := get_printer_name(k_user_name, substr(rec_org_num_emetteur.org_name,1,3)); -- OBE artf2432851
            -- Modif GV20090324 : il ne faut imprimer que les bordereaux: on lance un traitement d'impression à la fin
            l_printing := fnd_request.set_print_options(printer => lv_printer_name,
                                                        copies  => 0);
            i := i + 1;
            dka_tools_pkg.put_log_message('Région/ imprimante : '||substr(rec_org_num_emetteur.org_name,1,3)||'/ '||lv_printer_name); -- OBE artf2432851

            lv_step := 'Lancement du traitement de création des remises';
            create_remit(l_prog_application_short_name,
                         lv_today,
                         rec_lots_remise.receipt_class_id,
                         rec_lots_remise.receipt_method_id,
                         rec_lots_remise.bank_branch_id,
                         rec_lots_remise.bank_account_id,
                         pv_date_echeance, --JVI 21/12/2009
                         g_organisation_user, --Correction ORG_ID
                         vn_request_id, --> GV20090324 : Ajout de ce paramètre pour récupérer le request_id
                         pn_retcode,
                         pv_errbuf);

            IF pn_retcode != 0 THEN
              dka_tools_pkg.put_log_message('Erreur lors de la création des remises pour la méthode '||rec_lots_remise.name||'(id='||rec_lots_remise.receipt_method_id||')');
              dka_tools_pkg.put_log_message(pv_errbuf);
            ELSE

              -- Alimentation de la table temporaire dka_sarautoprelev_tmp pour la création des fichiers à envoyer à la banque
              lv_step := 'Récupération de l''ID du lot de remise en banque';
              select fcr.argument2
              into l_batch_param
              from fnd_concurrent_requests fcr
              join fnd_concurrent_programs fcp on(fcp.application_id = fcr.program_application_id  and fcp.concurrent_program_id = fcr.concurrent_program_id)
              where 1 = 1
                and parent_request_id = vn_request_id
                and fcp.concurrent_program_name = 'ARZCARPO';

              lv_step := 'Alimentation de la table dka_sarautoprelev_tmp';
              INSERT_PRELEV(pv_errbuf   => pv_errbuf,
                            pn_retcode  => pn_retcode,
                            pv_batch_id => l_batch_param);

            END IF;

            -- On stocke le request_id et l'imprimante associée
            tv_tab_trt(i).request_id := vn_request_id;
            tv_tab_trt(i).printer_name := lv_printer_name;
          EXCEPTION
            WHEN OTHERS THEN
              dka_tools_pkg.put_log_message('Erreur à l''étape ' || lv_step);
              dka_tools_pkg.put_log_message(pv_errbuf || '--' || SQLERRM);
          END;
        END LOOP;


  FOR rec_lots_express IN cur_lots_express(rec_org_num_emetteur.ledger_id) LOOP

  BEGIN

  UPDATE ar_payment_schedules_all
    SET due_date = (
    SELECT DATE_ORIGINALE
    FROM DKA_SARAUTOPRELEV_EXP_STAT
    WHERE CASH_RECEIPT_ID = rec_lots_express.cash_receipt_id
  )
    WHERE cash_receipt_id = rec_lots_express.cash_receipt_id;

  COMMIT;

  EXCEPTION
  WHEN OTHERS THEN
  dka_tools_pkg.put_log_message('Erreur de mise à jour de la date originale : ' || SQLERRM);

  END;
  END LOOP;


    END IF; --ARA EDB379

      EXCEPTION
        WHEN e_last_day THEN
          gn_retcode := 1;
          pv_errbuf  := 'La date comptable du lot de remise en banque (' ||lv_today || ') n''est pas dans une période ouverte pour l''organisation :'||rec_org_num_emetteur.org_name;
          DKA_TOOLS_PKG.put_log_message(pv_errbuf);
      END;

      gn_retcode := greatest(gn_retcode,pn_retcode);

    END LOOP;

    pn_retcode := gn_retcode;

    -- Exécution du traitement standard "Créer des lots de règlements"
    dka_tools_pkg.put_log_message('Lancement du traitement : IBY_FC_CREATE_SETTLE_BATCHES');
    v_settle_batches_id := fnd_request.submit_request(application => 'IBY',
                                                      program     => 'IBY_FC_CREATE_SETTLE_BATCHES',
                                                      description => NULL,
                                                      start_time  => NULL,
                                                      sub_request => FALSE,
                                                      argument1   => 'IBY_FC_CREATE_SETTLE_BATCHES',
                                                      argument2   => 'N',
                                                      argument3   => NULL,
                                                      argument4   => NULL,
                                                      argument5   => NULL,
                                                      argument6   => NULL,
                                                      argument7   => NULL,
                                                      argument8   => NULL,
                                                      argument9   => NULL,
                                                      argument10  => NULL,
                                                      argument11  => NULL,
                                                      argument12  => NULL,
                                                      argument13  => NULL,
                                                      argument14  => NULL,
                                                      argument15  => NULL,
                                                      argument16  => NULL,
                                                      argument17  => NULL,
                                                      argument18  => NULL);

    if v_settle_batches_id = 0 then
      dka_tools_pkg.put_log_message('Erreur lors du lancement du traitement : IBY_FC_CREATE_SETTLE_BATCHES');
    end if;

    commit; --Lancement du traitement
    dka_tools_pkg.put_log_message('Traitement :  / No request :' || v_settle_batches_id);
    if not fnd_concurrent.wait_for_request( request_id => v_settle_batches_id,
                                            interval   => 10,
                                            max_wait   => 0,
                                            phase      => vv_phase,
                                            status     => vv_status,
                                            dev_phase  => vv_dev_phase,
                                            dev_status => vv_dev_status,
                                            message    => vv_message) then

      dka_tools_pkg.put_log_message('Erreur lors du lancement du traitement : IBY_FC_CREATE_SETTLE_BATCHES : ' || vv_message);
    end if;

    dka_tools_pkg.put_log_message('Traitement terminé : ' || vv_phase || ' / ' || vv_status);

    -- Parcourir la table temporaire pour creer les fichiers
    --------------------------------------------------------
    --> Ajout GV20090723 : modification de la remit_date pour prendre le prochain jour ouvré
    Dka_Tools_Pkg.GET_NEXT_WORKING_DAY(gd_remit_date);

    --Execution du traitement CREATE_DD_IMPORT
    dka_tools_pkg.put_log_message('Lancement du traitement : DKA_CREATE_DDIMPORT_FILE');
    vn_CREATE_DD_IMPORT_ID := FND_REQUEST.SUBMIT_REQUEST(application => 'DKA',
                                                         program     => 'DKA_CREATE_DDIMPORT_FILE',
                                                         description => NULL,
                                                         start_time  => NULL,
                                                         sub_request => FALSE,
                                                         argument1   => fnd_date.date_to_canonical(gd_remit_date));

    IF vn_CREATE_DD_IMPORT_ID = 0 THEN
      dka_tools_pkg.put_log_message('Erreur lors du lancement du traitement : DKA_CREATE_DDIMPORT_FILE');
    END IF;

    COMMIT; --Lancement du traitement
    dka_tools_pkg.put_log_message('Traitement : DKA_CREATE_DDIMPORT_FILE / No request :' || vn_CREATE_DD_IMPORT_ID);

    IF NOT FND_CONCURRENT.WAIT_FOR_REQUEST(vn_CREATE_DD_IMPORT_ID, -- Premier traitement lance
                                           10, -- Interval
                                           0, -- Max wait
                                           vv_PHASE,
                                           vv_STATUS,
                                           vv_DEV_PHASE,
                                           vv_DEV_STATUS,
                                           vv_MESSAGE) THEN
      dka_tools_pkg.put_log_message('Erreur lors du lancement du traitement : DKA_CREATE_DDIMPORT_FILE : ' || vv_MESSAGE);
    END IF;

    dka_tools_pkg.put_log_message('Traitement terminé : ' || vv_PHASE || ' / ' || vv_STATUS);


    -- fmi ears20100069 : on recupere le nom de l'imprimante de la tresorerie
    vv_printer_treso := Dka_Stransco_Pkg.etl_get_value_f('IMPRIMANTE_TRESORERIE',
                                                         SYSDATE,
                                                         'PARIS',
                                                         NULL,
                                                         NULL);

    -- Impression des bordereaux
    IF tv_tab_trt.FIRST IS NOT NULL THEN
      FOR i IN tv_tab_trt.FIRST .. tv_tab_trt.LAST LOOP
        BEGIN
          -- Soumission du traitement : on recherche le traitement ayant un parent_request_id dans le tableau
          BEGIN
            select fcr.request_id
            into vn_request_id
            from fnd_concurrent_requests  fcr
            join fnd_concurrent_programs  fcp on(fcp.concurrent_program_id = fcr.concurrent_program_id)
            where 1=1
              and fcr.parent_request_id = tv_tab_trt(i).request_id
              and fcp.concurrent_program_name = 'DKAPR02';
          EXCEPTION
            WHEN OTHERS THEN
              vn_request_id := 0;
          END;

          IF vn_request_id <> 0 THEN
            vn_result := fnd_request.submit_request(application => 'FND',
                                                    program     => 'FNDREPRINT',
                                                    argument1   => vn_request_id,
                                                    argument2   => tv_tab_trt(i).printer_name,
                                                    argument3   => '1',
                                                    argument4   => 'LANDSCAPE',
                                                    argument5   => 'Y');

            -- fmi eis20100069 : impression si tiers express
            IF vv_printer_treso IS NOT NULL THEN
              dka_tools_pkg.put_log_message('Impression sur IMPRIMANTE_TRESORERIE : ' || vv_printer_treso);
              vn_result := fnd_request.submit_request(application => 'FND',
                                                      program     => 'FNDREPRINT',
                                                      argument1   => vn_request_id,
                                                      argument2   => vv_printer_treso,
                                                      argument3   => '1',
                                                      argument4   => 'LANDSCAPE',
                                                      argument5   => 'Y');
            END IF;
          END IF;
        END;
      END LOOP;

    ELSE
      pn_retcode := 1;
      pv_errbuf  := 'Aucun lot à traiter';
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
    END IF;

  EXCEPTION
    WHEN e_org_id THEN
      pn_retcode := 2;
      pv_errbuf  := 'Erreur lors de la recuperation de l''org id => ' ||chr(10) || l_message;
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := SQLERRM;
      DKA_TOOLS_PKG.put_log_message('Etape => ' || lv_step || chr(10) || pv_errbuf);
  END MAIN;

END DKA_SARAUTOPRELEV_PKG;

/
SHOW ERROR

EXIT
