CREATE OR REPLACE PACKAGE BODY DKA_IGLHYPERIONDR_PKG AS
  ----------------------------------------------------------------------------------------------
  -- $Id$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_IGLHYPERIONDR_PKG.pkb
  -- DESCRIPTION       : DKA_IGLHYPERIONDR_PKG package body :
  ---
  --- AUTEUR           : Maxime EGOT
  --- DATE DE CREATION : 04/11/2016
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       :
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- ---------------------------------------------------------------------------
  --- 04/01/2017 MEG artf2076298 : modification du nom du fichier
  --- 02/05/2017 MEG artf2147095 : INT081_ Interface Hyperion données Reelles 1.5 : EDB056
  --- 27/06/2017 JJA artf2182062 : Correction sur l'alimentation de l'unité d'oeuvre - DefectBout_en_bout_Helios_Ref #820
  --- 26/01/2018 MEG artf2331333 : INT081 - RG non respectée
  --- 31/01/2018 OBE artf2343300 : INT081 - Fichier Hypérion Caractère guillemet à supprimer
  --- 09/04/2018 OBE artf2511543 : INT081 - Problèmes avec les écritures contrepassées dans l'export Hyperion
  --- 04/10/2018 JWY Refonte totale du composant
  --- 27/01/2020 SELO DGE20190021 Gestion des comptes en quantité
  --- 03/03/2020 SELO DGE20190021 SFD version 4 Gestion des unités de mesures
  --- 20/03/2020 JWY INC0410652 - INT081 - Optimisation du temps de performance Hyperion - Données réelles
  --- 27/08/2020 JWY TASK0115987 - Ajout de la devise CHF à l'export quotidien Hyperion
  --- 02/10/2020 JWY INC0446031 - Inversion du signe pour les comptes en HEURES
  --- 28/03/2022 SELO EDB333
  ----------------------------------------------------------------------------------------------

  --EXCEPTIONS
  E_FATAL_ERROR  EXCEPTION;
  E_PERIOD_ERROR EXCEPTION;
  PRAGMA EXCEPTION_INIT(E_FATAL_ERROR, -20012);
  K_FATAL_ERROR_NUM CONSTANT NUMBER := -20012;

  --CONSTANTE
  cv_package_name CONSTANT VARCHAR2(30) := 'DKA_IGLHYPERIONDR_PKG';
  K_SEPARATOR     CONSTANT VARCHAR2(2) := ';';
  K_DIRECTORY     CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';

  ------------------------------------------------------------------------------------
  --  Nom           : p_put_debug_message
  --  Description   : Ecrit dans le journal du traitement
  --
  --  PARAMETRES    : Message à afficher dans le journal
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_put_debug_message(p_message IN VARCHAR2) IS
  
  BEGIN
  
    dka_tools_pkg.put_log_message(p_message);
  
  END p_put_debug_message;

  ------------------------------------------------------------------------------------
  --  Nom           : p_validate
  --  Description   :
  --
  --  PARAMETRES    : p_condition: Si FALSE => Affiche un message dans le journal et
  --                                           genere une erreur fatale
  --                               Si TRUE  => Fait aucune action
  --                  p_message:   Message a afficher dans le journal
  ------------------------------------------------------------------------------------
  PROCEDURE p_validate(p_condition IN BOOLEAN,
                       p_message   IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
  
    IF NOT p_condition THEN
      IF p_message IS NOT NULL THEN
        p_put_debug_message(p_message);
      END IF;
    
      RAISE_APPLICATION_ERROR(K_FATAL_ERROR_NUM,
                              nvl(p_message, 'Erreur fatale : '));
    
    END IF;
  
  END p_validate;

  ------------------------------------------------------------------------------------
  --  Nom           : p_check_directory
  --  Description   : Verifie que le directory existe
  --
  --  PARAMETRES    :
  --  p_directory_name          nom du directory
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_check_directory(p_directory_name in ALL_DIRECTORIES.directory_name%type) IS
  
    CURSOR cur_directory(p_directory_name IN ALL_DIRECTORIES.directory_name%type) IS
      SELECT owner, directory_name, directory_path
        FROM all_directories
       WHERE directory_name = p_directory_name;
    l_dir cur_directory%ROWTYPE;
  
  BEGIN
  
    OPEN cur_directory(p_directory_name);
    FETCH cur_directory
      INTO l_dir;
  
    IF cur_directory%NOTFOUND THEN
      CLOSE cur_directory;
      p_validate(FALSE,
                 'Le directory ' || p_directory_name || ' n''existe pas.');
    END IF;
  
    CLOSE cur_directory;
  
    p_put_debug_message('p_check_directory :  ' || p_directory_name ||
                        ' -> ' || l_dir.directory_path);
  
  END p_check_directory;

  ------------------------------------------------------------------------------------
  --  Nom           : f_get_DKCODE_region
  --  Description   : retourne le DKCODE de la région passée en paramètre
  --
  --  PARAMETRES    :
  --  region          nom de la région
  --
  ------------------------------------------------------------------------------------
  FUNCTION f_get_DKCODE_region(region VARCHAR2) RETURN VARCHAR2 IS
    pv_dkcode VARCHAR2(10);
  BEGIN
  
    SELECT dsl.param1_value
      INTO pv_dkcode
      FROM dka_stransco_headers dsh, dka_stransco_lines dsl
     WHERE dsh.set_id = dsl.set_id
       AND dsh.set_name = 'DKA_DKCODE_UO'
       AND dsl.return_value = region;
  
    return pv_dkcode;
  END f_get_DKCODE_region;

  -----------------------------------------------------------------------------------
  --  Nom           : f_get_UNITS_OF_MEASURE
  --  Description   : retourne le UNITS_OF_MEASURE
  --
  --  PARAMETRES    :
  --  Unite          Unite
  --
  ------------------------------------------------------------------------------------
  FUNCTION f_get_UNITS_OF_MEASURE(unite VARCHAR2) RETURN VARCHAR2 IS
    pv_UNITS_OF_MEASURE VARCHAR2(10);
  BEGIN
    BEGIN
      SELECT dsl.return_value
        INTO pv_UNITS_OF_MEASURE
        FROM dka_stransco_headers dsh, dka_stransco_lines dsl
       WHERE dsh.set_id = dsl.set_id
         AND dsh.set_name = 'DKA_HYPERION_UNITS_OF_MEASURE'
         AND dsl.param1_value = unite
         AND NVL(dsl.Start_DATE, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND NVL(dsl.END_DATE, TRUNC(SYSDATE)) >= TRUNC(SYSDATE);
    EXCEPTION
      when no_data_found then
        pv_UNITS_OF_MEASURE := unite;
    end;
  
    return pv_UNITS_OF_MEASURE;
  END f_get_UNITS_OF_MEASURE;

  ------------------------------------------------------------------------------------
  --  Nom           : f_get_us_periode_name
  --  Description   : retourne la période au format demandé (FEV-18 -> Feb-18)
  --
  --  PARAMETRES    :
  --  pv_period_name          nom de la période
  --
  ------------------------------------------------------------------------------------
  -- retourne la période au format demandé
  FUNCTION f_get_us_periode_name(pv_period_name IN VARCHAR2) RETURN varchar2 IS
  
    vv_out_period VARCHAR2(10);
  
  BEGIN
  
    SELECT initcap(substr(to_char(gp.end_date,
                                  'MONTH',
                                  'NLS_DATE_LANGUAGE = English'),
                          1,
                          3)) || substr(gp.period_name, -3)
      INTO vv_out_period
      FROM gl_periods gp
     WHERE gp.period_name = pv_period_name
       AND gp.period_set_name = 'GROUPE';
  
    return vv_out_period;
  
  END f_get_us_periode_name;

  ------------------------------------------------------------------------------------
  --  Nom           : f_get_period_to_extract
  --  Description   : retourne la période à extraire en se basant sur la première periode
  --                  ouverte et sur la période utilisée lors du précédent lancement
  --
  ------------------------------------------------------------------------------------

  FUNCTION f_get_period_to_extract(pv_errbuf  OUT NOCOPY VARCHAR2,
                                   pn_retcode OUT NOCOPY NUMBER,
                                   p_main     in VARCHAR2) RETURN VARCHAR2 IS
    vv_current_opened_period VARCHAR2(10);
    vv_last_opened_period    VARCHAR2(10);
    rec_param                dka_parameters%ROWTYPE;
    vd_current_period        DATE;
    vd_last_period           DATE;
  
  BEGIN
  
    -- Récupération de la première période GL ouverte
    SELECT period_name
      into vv_current_opened_period
      FROM gl_periods
     WHERE start_date =
           (SELECT min(start_date)
              FROM PER_SECURITY_PROFILES_V      pspv,
                   PER_SECURITY_ORGANIZATIONS_V psov,
                   hr_operating_units           hou,
                   gl_ledgers                   gl,
                   gl_period_statuses           gls
             WHERE pspv.security_profile_id =
                   fnd_profile.value('XLA_MO_SECURITY_PROFILE_LEVEL')
               AND pspv.security_profile_id = psov.security_profile_id
               AND hou.organization_id = psov.organization_id
               AND hou.set_of_books_id = gl.ledger_id
               AND gls.application_id = 101
               AND gls.closing_status = 'O'
               AND gls.set_of_books_id = gl.ledger_id)
       AND period_set_name = 'GROUPE';
  
    -- Récupération de la période ouverte lors du précédent lancement
    IF p_main = 'main' THEN
      Dka_Tools_Pkg.get_parameter('DKA_SGLHYPERION',
                                  'LAST_OPENED_PERIOD',
                                  rec_param,
                                  pn_retcode,
                                  pv_errbuf);
      vv_last_opened_period := rec_param.varchar2_value;
    
      -- Mise à jour du paramètre pour le prochain lancement
      UPDATE DKA_PARAMETERS
         SET VARCHAR2_VALUE = vv_current_opened_period
       WHERE PROGRAM_CODE = 'DKA_SGLHYPERION'
         AND PARAMETER_NAME = 'LAST_OPENED_PERIOD';
    ELSIF p_main = 'main_qte' THEN
      Dka_Tools_Pkg.get_parameter('DKA_SGLHYPERION_QTE',
                                  'LAST_OPENED_PERIOD',
                                  rec_param,
                                  pn_retcode,
                                  pv_errbuf);
      vv_last_opened_period := rec_param.varchar2_value;
    
      -- Mise à jour du paramètre pour le prochain lancement
      UPDATE DKA_PARAMETERS
         SET VARCHAR2_VALUE = vv_current_opened_period
       WHERE PROGRAM_CODE = 'DKA_SGLHYPERION_QTE'
         AND PARAMETER_NAME = 'LAST_OPENED_PERIOD';
    END IF;
  
    p_put_debug_message('Période ouverte : ' || vv_current_opened_period);
    p_put_debug_message('Période du précédent lancement : ' ||
                        vv_last_opened_period);
    p_put_debug_message('-------------------------');
  
    -- Verification que le paramètre précédent soit bien initialisé
    IF (vv_last_opened_period is NULL) THEN
      p_put_debug_message('Période précédente non initialisée => ' ||
                          vv_current_opened_period);
      RETURN vv_current_opened_period;
    
    END IF;
  
    -- Si les 2 périodes sont les mêmes, pas de soucis
    IF (vv_current_opened_period = vv_last_opened_period) THEN
      p_put_debug_message('Périodes égales => ' ||
                          vv_current_opened_period);
      RETURN vv_current_opened_period;
    
      -- Sinon, on vérifie quelle est la période la plus ancienne afin qu'elle soit sélectionnée
    ELSE
    
      SELECT start_date
        into vd_current_period
        FROM gl_periods
       WHERE period_name = vv_current_opened_period
         AND period_set_name = 'GROUPE';
    
      SELECT start_date
        into vd_last_period
        FROM gl_periods
       WHERE period_name = vv_last_opened_period
         AND period_set_name = 'GROUPE';
    
      IF (vd_current_period < vd_last_period) THEN
      
        p_put_debug_message('Periode courante < Derniere periode => ' ||
                            vv_current_opened_period);
        RETURN vv_current_opened_period;
      
      ELSE
      
        p_put_debug_message('Periode courante > Derniere periode => ' ||
                            vv_last_opened_period);
        RETURN vv_last_opened_period;
      
      END IF;
    
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procédure f_get_period_to_extract : ' ||
                    SQLERRM;
      pn_retcode := 2;
    
  END f_get_period_to_extract;

  ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data
  --  Description   : Extrait les ecritures comptables vers Hyperion
  --
  --  PARAMETRES    :
  --  p_directory_name        Nom du directory
  --  p_file_name             Nom du fichier
  --  p_nb_lignes             Nombre de lignes inserees
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name      IN VARCHAR2,
                           p_livre          IN VARCHAR2,
                           p_period_name    IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2) IS
  
    vv_ligne      VARCHAR2(4000);
    vn_nb_lignes  NUMBER := 0;
    l_file        UTL_FILE.file_type;
    vv_region     VARCHAR2(10);
    vv_societe    VARCHAR2(10);
    vv_dkcode     VARCHAR2(10);
    vv_periode_us VARCHAR2(10);
  
    CURSOR cur_ecrit_cmpt IS
      SELECT gcc.segment8,
             gcc.segment6,
             gjh.period_name,
             gcc.segment4,
			 gjct.USER_JE_CATEGORY_NAME Categorie, -- SELO EDB333
             sum(nvl(accounted_cr, 0) - nvl(accounted_dr, 0)) / 1000 solde
        FROM gl_je_headers gjh,
             gl_je_lines gjl,
             gl_code_combinations gcc,
             gl_je_batches gjb,
             gl_access_set_norm_assign_v gasn,
             gl_ledger_sets_v gls,
             gl_ledger_set_norm_assign_v glsna,
             gl_ledgers gl,
             (SELECT ffvv.flex_value
                FROM fnd_flex_values ffvv, fnd_flex_value_sets ffvs
               WHERE ffvs.flex_value_set_id = ffvv.flex_value_set_id
                 AND ffvs.flex_value_set_name = 'DAOPCCF_ANALYTIQUE'
                 AND (ffvv.attribute1 like 'PL%' OR
                     ffvv.attribute1 like '40PL%')) ffv,
			GL_JE_CATEGORIES_TL gjct -- SELO EDB333
       WHERE 1 = 1
         AND gjh.je_header_id = gjl.je_header_id
         AND gjl.code_combination_id = gcc.code_combination_id
         AND gjh.je_batch_id = gjb.je_batch_id
         AND NVL(gjh.status, 'ZZZ') = 'P' --Lignes d'écritures comptabilisées
         AND nvl(gjl.status, 'ZZZ') = 'P'
         AND gjh.period_name = p_period_name
         AND gjl.period_name = gjh.period_name -- 20/03/2020 JWY INC0410652
            --AND gjh.currency_code = 'EUR'
         AND gjh.currency_code = gl.currency_code -- 27/08/2020 JWY TASK0115987
         AND gcc.segment1 = gl.short_name -- 20/03/2020 JWY INC0410652
         AND gcc.segment4 = ffv.flex_value
         AND gjl.ledger_id = gl.ledger_id
         AND gasn.ledger_name = p_livre
         AND gasn.ledger_id = gls.ledger_id(+)
         AND gls.ledger_id = glsna.ledger_set_id(+)
         AND gl.ledger_id =
             decode(glsna.ledger_id, NULL, gasn.ledger_id, glsna.ledger_id)
         and gasn.access_set_id = fnd_profile.value('GL_ACCESS_SET_ID')
		 and gjh.JE_CATEGORY= gjct.je_category_name -- SELO EDB333
		 and gjct.language= 'F' -- SELO EDB333
       group by gcc.segment8, gcc.segment6, gjh.period_name, gcc.segment4, gjct.USER_JE_CATEGORY_NAME;
  
    TYPE t_ecrit_compt IS TABLE OF cur_ecrit_cmpt%ROWTYPE index by binary_integer;
    lt_ecrit_compt t_ecrit_compt;
  
    --ln_step PLS_INTEGER := 10000;
  
  BEGIN
  
    p_put_debug_message('Dans la procedure p_extract_data (' ||
                        p_directory_name || ';' || p_file_name || ';' ||
                        p_nb_lignes || ')');
  
    -- récuperation de la période au format us
    vv_periode_us := f_get_us_periode_name(p_period_name);
  
    -- Verification de l'existence du directory
    p_check_directory(p_directory_name);
  
    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, p_file_name, 'W');
  
    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      p_put_debug_message('Le fichier ' || p_directory_name || '/' ||
                          p_file_name || ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
    END IF;
  
    -- Extraction des donnees
    OPEN cur_ecrit_cmpt;
    LOOP
      FETCH cur_ecrit_cmpt BULK COLLECT
        INTO lt_ecrit_compt LIMIT 100000;
    
      IF lt_ecrit_compt.COUNT > 0 THEN
        FOR i in lt_ecrit_compt.FIRST .. lt_ecrit_compt.LAST LOOP
        
          vv_region  := NULL;
          vv_societe := NULL;
          vv_dkcode  := NULL;
        
          IF substr(lt_ecrit_compt(i).segment8, 1, 1) != ('0') THEN
          
            BEGIN
            
              SELECT substr(hou.name, 1, 3), substr(hou.name, 4, 4)
                INTO vv_region, vv_societe
                FROM hr_organization_units hou, pa_projects_all ppa
               WHERE hou.organization_id = ppa.org_id
                 AND ppa.segment1 = lt_ecrit_compt(i).segment8;
            
              vv_dkcode := f_get_DKCODE_region(vv_region);
            
              vv_ligne := vv_dkcode || K_SEPARATOR || vv_societe ||
                          K_SEPARATOR || lt_ecrit_compt(i).segment8 ||
                          K_SEPARATOR || lt_ecrit_compt(i).segment6 ||
						  K_SEPARATOR || lt_ecrit_compt(i).Categorie || -- SELO EDB333
                          K_SEPARATOR || vv_periode_us || K_SEPARATOR || lt_ecrit_compt(i).segment4 ||
                          K_SEPARATOR || lt_ecrit_compt(i).solde;
            
              -- Ecrit dans le fichier
              utl_file.put_line(l_file, vv_ligne);
            
              -- Maj des compteurs
              vn_nb_lignes := vn_nb_lignes + 1;
            
            EXCEPTION
            
              WHEN OTHERS THEN
                p_put_debug_message('ERREUR ' || lt_ecrit_compt(i).segment8 ||
                                    ' - ' || SQLERRM);
              
            END;
          
          END IF; --condition exclusion
        
        END LOOP; --lt_ecrit_compt
      
      END IF; --lt_ecrit_compt.COUNT
    
      EXIT WHEN cur_ecrit_cmpt%NOTFOUND;
    
    END LOOP;
    CLOSE cur_ecrit_cmpt;
  
    --  COMMIT;
    -- Fermeture du fichier
    UTL_FILE.FCLOSE(l_file);
  
    -- Remet les valeurs des compteurs dans les parametres de la procedure
    p_nb_lignes := vn_nb_lignes;
  
  EXCEPTION
    WHEN OTHERS THEN
      p_validate(FALSE,
                 'Probleme dans la procedure p_extract_data (' || SQLERRM || ')');
    
  END p_extract_data;

  ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data_qte
  --  Description   : Extrait les ecritures comptables vers Hyperion
  --
  --  PARAMETRES    :
  --  p_directory_name        Nom du directory
  --  p_file_name             Nom du fichier
  --  p_nb_lignes             Nombre de lignes inserees
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data_qte(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                               p_file_name      IN VARCHAR2,
                               p_livre          IN VARCHAR2,
                               p_period_name    IN VARCHAR2,
                               p_nb_lignes      IN OUT VARCHAR2) IS
  
    vv_ligne      VARCHAR2(4000);
    vn_nb_lignes  NUMBER := 0;
    l_file        UTL_FILE.file_type;
    vv_region     VARCHAR2(10);
    vv_societe    VARCHAR2(10);
    vv_dkcode     VARCHAR2(10);
    vv_periode_us VARCHAR2(10);
  
    CURSOR cur_ecrit_cmpt IS
      select gcc.segment8,
             gcc.segment6,
             PCDLA.GL_PERIOD_NAME period_name,
             GCC.segment4 segment4,
             PET.UNIT_OF_MEASURE,
             sum(peia.quantity) solde
        from PA_EXPENDITURE_ITEMS_ALL PEIA,
             PA_COST_DISTRIBUTION_LINES_ALL PCDLA,
             PA_EXPENDITURE_TYPES PET,
             pa_projects_all ppa,
             APPS.GL_CODE_COMBINATIONS GCC,
             (SELECT ffvv.flex_value
                FROM fnd_flex_values ffvv, fnd_flex_value_sets ffvs
               WHERE ffvs.flex_value_set_id = ffvv.flex_value_set_id
                 AND ffvs.flex_value_set_name = 'DAOPCCF_ANALYTIQUE'
                 AND (ffvv.attribute1 like 'PL%' OR
                     ffvv.attribute1 like '40PL%')) ffv,
             gl_access_set_norm_assign_v gasn,
             gl_ledger_sets_v gls,
             gl_ledger_set_norm_assign_v glsna,
             hr_operating_units hou,
             gl_ledgers gl
       where PCDLA.EXPENDITURE_ITEM_ID = PEIA.EXPENDITURE_ITEM_ID
         and PEIA.EXPENDITURE_TYPE = PET.EXPENDITURE_TYPE
         and PEIA.project_id = ppa.project_id
         and PET.UNIT_OF_MEASURE <> 'EUR'
         and PCDLA.GL_PERIOD_NAME = p_period_name
         and PCDLA.DR_CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
         and gcc.segment4 = ffv.flex_value
         and PEIA.org_id = hou.organization_id
         and PCDLA.org_id = hou.organization_id
         and hou.set_of_books_id = gl.ledger_id
         AND gasn.ledger_name = p_livre
         AND gasn.ledger_id = gls.ledger_id(+)
         AND gls.ledger_id = glsna.ledger_set_id(+)
         AND gl.ledger_id =
             decode(glsna.ledger_id, NULL, gasn.ledger_id, glsna.ledger_id)
         and gasn.access_set_id = fnd_profile.value('GL_ACCESS_SET_ID')
       group by gcc.segment8,
                gcc.segment6,
                PCDLA.GL_PERIOD_NAME,
                GCC.segment4,
                PET.UNIT_OF_MEASURE;
  
    TYPE t_ecrit_compt IS TABLE OF cur_ecrit_cmpt%ROWTYPE index by binary_integer;
    lt_ecrit_compt t_ecrit_compt;
  
  BEGIN
  
    p_put_debug_message('Dans la procedure p_extract_data (' ||
                        p_directory_name || ';' || p_file_name || ';' ||
                        p_nb_lignes || ')');
  
    -- récuperation de la période au format us
    vv_periode_us := f_get_us_periode_name(p_period_name);
  
    -- Verification de l'existence du directory
    p_check_directory(p_directory_name);
  
    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, p_file_name, 'W');
  
    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      p_put_debug_message('Le fichier ' || p_directory_name || '/' ||
                          p_file_name || ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
    END IF;
  
    -- Extraction des donnees
    OPEN cur_ecrit_cmpt;
    LOOP
      FETCH cur_ecrit_cmpt BULK COLLECT
        INTO lt_ecrit_compt LIMIT 100000;
    
      IF lt_ecrit_compt.COUNT > 0 THEN
        FOR i in lt_ecrit_compt.FIRST .. lt_ecrit_compt.LAST LOOP
        
          vv_region  := NULL;
          vv_societe := NULL;
          vv_dkcode  := NULL;
        
          IF substr(lt_ecrit_compt(i).segment8, 1, 1) != ('0') THEN
          
            BEGIN
            
              SELECT substr(hou.name, 1, 3), substr(hou.name, 4, 4)
                INTO vv_region, vv_societe
                FROM hr_organization_units hou, pa_projects_all ppa
               WHERE hou.organization_id = ppa.org_id
                 AND ppa.segment1 = lt_ecrit_compt(i).segment8;
            
              vv_dkcode := f_get_DKCODE_region(vv_region);
            
              vv_ligne := vv_dkcode || K_SEPARATOR || vv_societe ||
                          K_SEPARATOR || lt_ecrit_compt(i).segment8 ||
                          K_SEPARATOR || lt_ecrit_compt(i).segment6 ||
						  K_SEPARATOR || '_QUANTITE' || -- SELO EDB333
                          K_SEPARATOR || vv_periode_us || K_SEPARATOR || lt_ecrit_compt(i).segment4 || '.' ||
                          f_get_UNITS_OF_MEASURE(lt_ecrit_compt(i).UNIT_OF_MEASURE) ||
                          K_SEPARATOR;
            
              --<INC0446031 JWY 02/10/2020
              IF (lt_ecrit_compt(i).UNIT_OF_MEASURE = 'HOURS') THEN
              
                vv_ligne := vv_ligne || lt_ecrit_compt(i).solde * -1;
              ELSE
                vv_ligne := vv_ligne || lt_ecrit_compt(i).solde;
              
              END IF;
              -- INC0446031 />
            
              -- Ecrit dans le fichier
              utl_file.put_line(l_file, vv_ligne);
            
              -- Maj des compteurs
              vn_nb_lignes := vn_nb_lignes + 1;
            
            EXCEPTION
            
              WHEN OTHERS THEN
                p_put_debug_message('ERREUR ' || lt_ecrit_compt(i).segment8 ||
                                    ' - ' || SQLERRM);
              
            END;
          
          END IF; --condition exclusion
        
        END LOOP; --lt_ecrit_compt
      
      END IF; --lt_ecrit_compt.COUNT
    
      EXIT WHEN cur_ecrit_cmpt%NOTFOUND;
    
    END LOOP;
    CLOSE cur_ecrit_cmpt;
  
    --  COMMIT;
    -- Fermeture du fichier
    UTL_FILE.FCLOSE(l_file);
  
    -- Remet les valeurs des compteurs dans les parametres de la procedure
    p_nb_lignes := vn_nb_lignes;
  
  EXCEPTION
    WHEN OTHERS THEN
      p_validate(FALSE,
                 'Probleme dans la procedure p_extract_data_qte (' ||
                 SQLERRM || ')');
    
  END p_extract_data_qte;

  ------------------------------------------------------------------------------------
  --  Nom           : p_bilan
  --  Description   : Affichage des stats
  --
  --  PARAMETRES    :
  --  p_livre          nom du jeu de livres
  --  p_periode        periode d'extraction
  --  p_nb_lignes      nombre de lignes extraites dans le fichier
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_bilan(p_livre     IN VARCHAR2,
                    p_periode   IN VARCHAR2,
                    p_nb_lignes IN NUMBER) IS
  
  BEGIN
  
    p_put_debug_message('Dans la procedure p_bilan (' || p_livre || '/' ||
                        p_nb_lignes || ')');
  
    Fnd_File.put_line(Fnd_File.output,
                      '---------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.output,
                      '-- PARAMETRE DU TRAITEMENT, lancé le ' ||
                      to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS'));
    Fnd_File.put_line(Fnd_File.output,
                      '---------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.output, '1) Jeu de livre : ' || p_livre);
  
    Fnd_File.put_line(Fnd_File.output, chr(10));
  
    Fnd_File.put_line(Fnd_File.output, '2) Periode : ' || p_periode);
  
    Fnd_File.put_line(Fnd_File.output, chr(10));
  
    Fnd_File.put_line(Fnd_File.output,
                      '---------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.output,
                      '-- BILAN                                                 ');
    Fnd_File.put_line(Fnd_File.output,
                      '---------------------------------------------------------');
  
    IF p_nb_lignes > 0 THEN
      Fnd_File.put_line(Fnd_File.output,
                        'Volume des lignes générées : ' || p_nb_lignes ||
                        ' lignes.');
    ELSE
      Fnd_File.put_line(Fnd_File.output, 'Aucune ligne trouvée.');
    END IF;
  
  END p_bilan;

  ------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : point d'entrée du traitement
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)
  --  pv_livre              Jeu de livres
  --
  ------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf       OUT NOCOPY VARCHAR2,
                 pn_retcode      OUT NOCOPY NUMBER,
                 pv_livre        IN VARCHAR2,
                 pv_period_param IN VARCHAR2) IS
  
    lv_current_program_unit VARCHAR2(30) := 'main';
    lv_nom_fichier          VARCHAR2(200);
    ln_nb_lignes            NUMBER := 0;
    pv_period_name          VARCHAR2(10);
    vv_annee                VARCHAR2(4);
    vv_mois                 VARCHAR2(2);
  
  BEGIN
  
    p_put_debug_message('Dans la procedure main (' || pv_livre || ')');
  
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS=''' || '.,' || '''';
  
    -- Récupération période
    IF (pv_period_param IS NULL) THEN
    
      pv_period_name := f_get_period_to_extract(pv_errbuf,
                                                pn_retcode,
                                                lv_current_program_unit);
      p_put_debug_message('Période non passée en paramètre, lancement sur ' ||
                          pv_period_name);
    
      IF pn_retcode != 0 THEN
        RAISE e_period_error;
      END IF;
    
    ELSE
    
      pv_period_name := pv_period_param;
      p_put_debug_message('Période paramétrée : ' || pv_period_name);
    
    END IF;
  
    -- Controle du parametre Jeu de livre
    IF pv_livre IS NULL THEN
      p_validate(FALSE, 'Le paramètre du traitement est vide.');
    END IF;
  
    p_put_debug_message('Selection periode');
  
    SELECT period_year, lpad(period_num, 2, '0')
      into vv_annee, vv_mois
      FROM gl_periods
     WHERE period_name = pv_period_name
       AND period_set_name = 'GROUPE';
  
    -- Construction du nom du fichier
  
    lv_nom_fichier := 'FIN01_SRC_DR_' ||
                      to_char(sysdate, 'YYYYMMDD-HH24miss') || '.csv';
    dka_tools_pkg.put_outdebug_message(lv_nom_fichier);
  
    -- Extrait les lignes d'écritures dans le fichier
    p_extract_data(K_DIRECTORY,
                   lv_nom_fichier,
                   pv_livre,
                   pv_period_name,
                   ln_nb_lignes);
  
    -- Edite un rapport de traitment
    p_bilan(pv_livre, pv_period_name, ln_nb_lignes);
  
  EXCEPTION
    WHEN e_period_error THEN
      p_put_debug_message('e_period_error : ' || pv_errbuf);
      ROLLBACK;
    
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure ' || cv_package_name || '.' ||
                    lv_current_program_unit || chr(10) || SQLERRM;
      pn_retcode := 2;
  END main;

  ------------------------------------------------------------------------------------
  --  Nom           : main_qte
  --  Description   : point d'entrée du traitement
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)
  --  pv_livre              Jeu de livres
  --
  ------------------------------------------------------------------------------------
  PROCEDURE main_qte(pv_errbuf       OUT NOCOPY VARCHAR2,
                     pn_retcode      OUT NOCOPY NUMBER,
                     pv_livre        IN VARCHAR2,
                     pv_period_param IN VARCHAR2) IS
  
    lv_current_program_unit VARCHAR2(30) := 'main_qte';
    lv_nom_fichier          VARCHAR2(200);
    ln_nb_lignes            NUMBER := 0;
    pv_period_name          VARCHAR2(10);
    vv_annee                VARCHAR2(4);
    vv_mois                 VARCHAR2(2);
  
  BEGIN
  
    p_put_debug_message('Dans la procedure main_qte (' || pv_livre || ')');
  
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS=''' || '.,' || '''';
  
    -- Récupération période
    IF (pv_period_param IS NULL) THEN
    
      pv_period_name := f_get_period_to_extract(pv_errbuf,
                                                pn_retcode,
                                                lv_current_program_unit);
      p_put_debug_message('Période non passée en paramètre, lancement sur ' ||
                          pv_period_name);
    
      IF pn_retcode != 0 THEN
        RAISE e_period_error;
      END IF;
    
    ELSE
    
      pv_period_name := pv_period_param;
      p_put_debug_message('Période paramétrée : ' || pv_period_name);
    
    END IF;
  
    -- Controle du parametre Jeu de livre
    IF pv_livre IS NULL THEN
      p_validate(FALSE, 'Le paramètre du traitement est vide.');
    END IF;
  
    p_put_debug_message('Selection periode');
  
    SELECT period_year, lpad(period_num, 2, '0')
      into vv_annee, vv_mois
      FROM gl_periods
     WHERE period_name = pv_period_name
       AND period_set_name = 'GROUPE';
  
    -- Construction du nom du fichier
  
    lv_nom_fichier := 'FIN01_SRC_QTE_' ||
                      to_char(sysdate, 'YYYYMMDD-HH24miss') || '.csv';
    dka_tools_pkg.put_outdebug_message(lv_nom_fichier);
  
    -- Extrait les lignes d'écritures dans le fichier
    p_extract_data_qte(K_DIRECTORY,
                       lv_nom_fichier,
                       pv_livre,
                       pv_period_name,
                       ln_nb_lignes);
  
    -- Edite un rapport de traitment
    p_bilan(pv_livre, pv_period_name, ln_nb_lignes);
  
  EXCEPTION
    WHEN e_period_error THEN
      p_put_debug_message('e_period_error : ' || pv_errbuf);
      ROLLBACK;
    
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure ' || cv_package_name || '.' ||
                    lv_current_program_unit || chr(10) || SQLERRM;
      pn_retcode := 2;
  END main_qte;

END DKA_IGLHYPERIONDR_PKG;
/
SHOW ERRORS;
EXIT 