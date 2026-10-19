CREATE OR REPLACE PACKAGE BODY APPS.DKA_IPOHYPERION_PKG AS
  ----------------------------------------------------------------------------------------------
  -- $Id$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_IPOHYPERION_PKG.pkb
  -- DESCRIPTION       : DKA_IPOHYPERION_PKG package body :
  ---
  -- AUTEUR           : HAHIOUI Saloua (CAPGEMINI)
  -- DATE DE CREATION : 03/04/2020
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       :
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- 04/03/2022 SHA - Correction suite au correctif TASK0169842
  --- 06/01/2025 ARA - EDB379
  --- 18/03/2025 ARA - EDB397
  --- ---------- --- ---------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------------
  --EXCEPTIONS
  E_PERIOD_ERROR EXCEPTION;

  --CONSTANTE
  --g_nom_traitement varchar2(50) := 'DKA : Extraction des données PO pour HYPERION';
  g_nom_traitement varchar2(100);
  cv_package_name   CONSTANT VARCHAR2(30) := 'DKA_IPOHYPERION_PKG';
  K_SEPARATOR       CONSTANT VARCHAR2(2) := ';';
  K_FATAL_ERROR_NUM CONSTANT NUMBER := -20012;
  K_DIRECTORY       CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';
  lv_current_program_unit VARCHAR2(30);
  lv_nom_fichier          VARCHAR2(200);
  ln_nb_lignes            NUMBER := 0;

  pv_errbuf      VARCHAR2(500);
  pn_retcode     NUMBER;
  pv_period_name VARCHAR2(10);

  -- variables de mail
  gv_expediteur VARCHAR2(150);
  gv_conn       VARCHAR2(30);
  g_step        VARCHAR2(500);
  gv_base       v$database.name%TYPE;
  gn_amt        BINARY_INTEGER := 672 * 3;
  BOUNDARY            CONSTANT VARCHAR2(256) := '=_NextPart_DC7E1BB5_1105_4DB3_BAE3_2A6208EB099D';
  FIRST_BOUNDARY      CONSTANT VARCHAR2(256) := '--' || BOUNDARY ||
                                                utl_tcp.CRLF;
  LAST_BOUNDARY       CONSTANT VARCHAR2(256) := '--' || BOUNDARY || '--' ||
                                                utl_tcp.CRLF;
  MULTIPART_MIME_TYPE CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary=' ||
                                                BOUNDARY;
  MAX_LINE_WIDTH PLS_INTEGER := 54;

  -- Variable d'exception :
  e_envoi_mail EXCEPTION;
  e_mail       EXCEPTION;
  e_nom_etat   EXCEPTION;

  -- Variable contenant l'entÃ¿Âªte et le corps du mail.
  gv_objet    VARCHAR2(4000);
  gv_corps    VARCHAR2(4000);
  gv_filename VARCHAR2(500);

  ------------------------------------------------------------------------------------
  --  Nom           : p_put_debug_message
  --  Description   : Ecrit dans le journal du traitement
  --
  --  PARAMETRES    : Message à afficher dans le journal
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_put_debug_message(p_message IN VARCHAR2) IS
  
  BEGIN
  
    dbms_output.put_line(p_message);
  
  END p_put_debug_message;

  ------------------------------------------------------------------------------------
  --  Nom           : p_put_out_message
  --  Description   : Ecrit dans la sortie du traitement
  --
  --  PARAMETRES    : Message à afficher dans la sortie
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_put_out_message(p_message IN VARCHAR2) IS
  
  BEGIN
  
    Fnd_File.put_line(Fnd_File.output, p_message);
  
  END p_put_out_message;

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

  ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data
  --  Description   : Extrait les ecritures comptables vers Hyperion
  --
  --  PARAMETRES    :
  --  p_directory_name        Nom du directory
  --  p_file_name             Nom du fichier
  --  pv_period_name          Periode comptable
  --  p_nb_lignes             Nombre de lignes total genere
  --  p_nb_lignes_cde         Nombre de lignes de commandes standard
  --  p_nb_lignes_sstr        Nombre de lignes de reste à faire de sous traitance
  --  pv_const_solde_cde      Valeur de la constante des commandes standards
  --  pv_const_solde_sstr     Valeur de la constante des commandes de sous traitance
  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data(p_directory_name    IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name         IN VARCHAR2,
                           pv_period_name      IN VARCHAR2,
                           p_nb_lignes         IN OUT NUMBER,
                           p_nb_lignes_cde     IN OUT NUMBER,
                           p_nb_lignes_sstr    IN OUT NUMBER,
                           pv_const_solde_cde  IN OUT VARCHAR2,
                           pv_const_solde_sstr IN OUT VARCHAR2) IS

    l_file UTL_FILE.file_type;

    vn_nb_lignes_cde  number := 0;
    vn_nb_lignes_sstr number := 0;
    vn_annee          NUMBER;

    vd_fin_periode DATE;
    vd_fin_annee   DATE;

    vv_periode_us VARCHAR2(10);
    vv_ligne      VARCHAR2(4000);

    CURSOR cde_solde IS
      SELECT projet,
             substr(uo, 4, 4) societe,
             compte_groupe,
             ROUND(sum(CASE
                         WHEN mt_reception < mt_fact_ap THEN
                          mt_commande - mt_fact_ap
                         ELSE
                          mt_commande - mt_reception
                       END) / 1000,
                   5) as solde --RG2.3
        FROM (SELECT ppa.segment1 projet,
                     gcc.segment4 compte_groupe,
                     pha.po_header_id,
                     hou.name uo,
                     pha.Segment1 commande,
                     pla.line_num,
                     pha.authorization_status,
                     pha.closed_code statut_header, -- RG1.2
                     pla.closed_code statut_line,
                     plla.closed_code statut_delivery,
                     pda.po_distribution_id,
                     pda.quantity_delivered,
                     pda.quantity_billed,
                     pda.quantity_ordered,
                     pla.unit_price,
                     pda.quantity_ordered * pla.unit_price mt_commande,
                     pda.quantity_delivered * pla.unit_price mt_reception,
                     pda.quantity_billed * pla.unit_price mt_fact_po,
                     nvl(inv_dist.mt_facture, 0) mt_fact_ap
                FROM po_distributions_all PDA,
                     po_headers_all pha,
                     hr_operating_units hou,
                     po_line_locations_all plla,
                     po_lines_all pla,
                     gl_code_combinations_kfv gcc,
                     pa_projects_all ppa,
                     (SELECT ffvv.flex_value
                        FROM fnd_flex_values ffvv, fnd_flex_value_sets ffvs
                       WHERE ffvs.flex_value_set_id = ffvv.flex_value_set_id
                         AND ffvs.flex_value_set_name = 'DAOPCCF_ANALYTIQUE'
                         AND (ffvv.attribute1 like 'PL%' OR
                             ffvv.attribute1 like '40PL%')) ffv,
                     (select po_distribution_id,
                             sum(total_dist_amount) mt_facture
                        from ap_invoice_distributions_all
                       where line_type_lookup_code = 'ITEM'
                         and reversal_flag = 'N'
                       group by po_distribution_id) inv_dist
               WHERE PHa.po_header_id = pda.po_header_id
                 AND pha.org_id = hou.organization_id
                 AND pda.line_location_id = plla.line_location_id
                 AND plla.po_line_id = pla.po_line_id
                 AND gcc.code_combination_id = pda.code_combination_id
                 AND ppa.project_id = pda.project_id
                 and gcc.segment4 = ffv.flex_value
                 AND pha.type_lookup_code = 'STANDARD' -- RG1.1
                 AND PHA.segment1 not like '%ST%' -- RG1.1
                 AND pha.closed_code = 'OPEN' -- RG1.2
                 AND nvl(pla.closed_code, 'OPEN') NOT IN
                     ('CLOSED', 'FINALLY CLOSED') -- RG1.3
                 AND nvl(plla.closed_code, 'OPEN') NOT IN
                     ('CLOSED', 'FINALLY CLOSED') -- RG1.4
                 AND substr(ppa.segment1, 1, 2) in ('FA', 'FB') -- RG1.5
                 AND pda.quantity_ordered > pda.quantity_delivered -- RG2.1
                    --     AND pda.quantity_ordered > pda.quantity_billed --RG2.2
                 AND pha.authorization_status in
                     ('APPROVED', 'IN PROCESS', 'REQUIRES REAPPROVAL') -- RG1.6
                 AND pda.po_distribution_id = inv_dist.po_distribution_id(+)) detail
       WHERE mt_commande > mt_fact_ap
       group by projet, substr(uo, 4, 4), compte_groupe; --RG3.1

    CURSOR sstr_uo IS
      select distinct ppa.org_id
        from po_headers_all       pha,
             po_distributions_all pda,
             pa_projects_all      ppa
       where pha.po_header_id = pda.po_header_id
         and pda.project_id = ppa.project_id
         and pha.segment1 like '%ST%'
         and pha.TYPE_LOOKUP_CODE = 'STANDARD'
         AND nvl(pha.closed_code, 'OPEN') NOT IN ('FINALLY CLOSED')
       order by ppa.org_id;

    CURSOR sstr_solde(vv_periode_courante VARCHAR2,
                      vd_fin_arrete       DATE,
                      vd_fin_exercice     DATE,
                      vn_org_id           NUMBER) IS
      SELECT ppa.segment1 projet,
             substr(hou.name, 4, 4) societe,
             gcc_old.segment4 compte_groupe,
             ROUND(sum(DKA_SPOCUT_OFF_PKG.get_charge_theorique_imput(to_number(pd.attribute3),
                                                                     phc.start_date,
                                                                     vd_fin_exercice) -
                       DKA_SPOCUT_OFF_PKG.get_charge_theorique_imput(to_number(pd.attribute3),
                                                                     phc.start_date,
                                                                     vd_fin_arrete)) / 1000,
                   5) solde -- RG5.1
        FROM po_headers_all ph,
             (select pha.segment1,
                     pha.po_header_id,
                     pha.start_date,
                     pha.end_date,
                     pha.revision_num,
                     dcsa_max.commande_id -- Recuperation du dernier contrat archive pour chaque commande
                from po_headers_archive_all pha,
                     (select po_header_id,
                             commande_id,
                             max(revision_num) revision_num
                        from dka_contrat_sstr_archi
                       group by po_header_id, commande_id) dcsa_max,
                     gl_periods gp
               where dcsa_max.po_header_id = pha.po_header_id
                 and dcsa_max.revision_num = pha.revision_num
                 and pha.authorization_status = 'APPROVED'
                 and pha.attribute4 in
                     ('CONTRAT DEPENDANT', 'CONTRAT SOUS-TRAITANCE')
                 and gp.period_name = vv_periode_courante
                 and gp.period_set_name = 'GROUPE'
                 AND gp.end_date BETWEEN pha.start_date and pha.end_date -- RG4.6 RG4.7 --jwyc
              ) phc, -- contrats de sous-traitance approuves
             Po_Distributions_All pd,
             po_lines_all pla,
             po_line_locations_all plla,
             gl_code_combinations gcc_old,
             pa_projects_all ppa,
             hr_operating_units hou,
             (SELECT ffvv.flex_value
                FROM fnd_flex_values ffvv, fnd_flex_value_sets ffvs
               WHERE ffvs.flex_value_set_id = ffvv.flex_value_set_id
                 AND ffvs.flex_value_set_name = 'DAOPCCF_ANALYTIQUE'
                 AND (ffvv.attribute1 like 'PL%' OR
                     ffvv.attribute1 like '40PL%')) ffv
       WHERE 1 = 1
         AND gcc_old.code_combination_id = pd.code_combination_id
         AND ppa.project_id = pd.project_id
         AND ppa.org_id = hou.organization_id
         AND ph.po_header_id = pd.po_header_id
         and ph.po_header_id = pla.po_header_id
         and pla.po_line_id = plla.po_line_id
         and pd.line_location_id = plla.line_location_id
         and pd.po_line_id = plla.po_line_id
         and gcc_old.segment4 = ffv.flex_value
         AND ph.type_lookup_code = 'STANDARD' --RG4.1
         AND ph.segment1 LIKE '%ST%' -- RG4.1
         AND ph.authorization_status = 'APPROVED'
         AND phc.segment1 =
             substr(ph.segment1, 1, instr(ph.segment1, 'ST') + 1)
         AND ph.po_header_id = phc.commande_id
         AND nvl(ph.closed_code, 'OPEN') != 'FINALLY CLOSED' -- RG4.2
         AND nvl(pla.closed_code, 'OPEN') != 'FINALLY CLOSED' -- RG4.3
         AND nvl(plla.closed_code, 'OPEN') != 'FINALLY CLOSED' -- RG4.4
         AND substr(ppa.segment1, 1, 2) in ('FA', 'FB') -- RG4.5
         AND ppa.org_id = vn_org_id
       GROUP BY ppa.segment1, substr(hou.name, 4, 4), gcc_old.segment4
     
    UNION --ARA EDB379
    
    SELECT ppa.segment1 projet,
             substr(hou.name, 4, 4) societe,
             gcc_old.segment4 compte_groupe,
             
              ROUND(sum(DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.get_charge_theorique_imput(pd.quantity_ordered,
                                                                     phc.DATE_DEBUT_PERIODE,
                                                                     phc.DATE_FIN_PERIODE,
                                                                     phc.DATE_RESILIATION,
                                                                     vd_fin_exercice) -
                      DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.get_charge_theorique_imput(pd.quantity_ordered,
                                                                     phc.DATE_DEBUT_PERIODE,
                                                                     phc.DATE_FIN_PERIODE,
                                                                     phc.DATE_RESILIATION,
                                                                     vd_fin_arrete)) / 1000,
                   5) solde 
                   
        FROM po_headers_all ph,
             (select pha.segment1,
                     pha.po_header_id,
                     pha.start_date,
                     pha.end_date,
                     max(pha.revision_num) revision_num,
                     dcsa_max.id_commande,
                     dcsa_max.NUM_CONTRAT,
                     dcsa_max.DATE_RESILIATION,
                     dcsa_max.DATE_DEBUT_PERIODE,
                     dcsa_max.DATE_FIN_PERIODE,
                     dcsa_max.MONTANT_CONTRAT
                from po_headers_archive_all pha,
                       
                       (
                       SELECT 
                          NUM_CONTRAT,
                          NUM_COMMANDE,
                          VERSION_CONTRAT,
                          VERSION_COMMANDE,
                          id_commande,
                          DATE_DEBUT_PERIODE,
                          DATE_FIN_PERIODE,
                          DATE_RESILIATION,
                          MONTANT_CONTRAT
                      FROM 
                          (SELECT 
                               NUM_CONTRAT,
                               NUM_COMMANDE,
                               VERSION_CONTRAT,
                               VERSION_COMMANDE,
                               id_commande,
                               DATE_DEBUT_PERIODE,
                               DATE_FIN_PERIODE,
                               DATE_RESILIATION,
                               MONTANT_CONTRAT,
                               ROW_NUMBER() OVER (PARTITION BY NUM_CONTRAT ORDER BY VERSION_CONTRAT DESC, VERSION_COMMANDE DESC) AS RN
                           FROM 
                               DKA_SPO_CONTRAT_SSTR_IVALUA dcs , gl_periods gp
                               where gp.period_name = vv_periode_courante
                               and gp.period_set_name = 'GROUPE'
                               AND gp.end_date BETWEEN dcs.DATE_DEBUT_PERIODE and dcs.DATE_FIN_PERIODE
                               )
                      WHERE 
                          RN = 1
                       )dcsa_max,
                     gl_periods gp
               where dcsa_max.id_commande = pha.po_header_id                
                 and pha.authorization_status = 'APPROVED'
                 and pha.attribute7 = 'IVALUA'
                 and gp.period_name = vv_periode_courante
                 and gp.period_set_name = 'GROUPE'
                 AND gp.end_date BETWEEN dcsa_max.DATE_DEBUT_PERIODE and dcsa_max.DATE_FIN_PERIODE
                 group by pha.segment1,
                     pha.po_header_id,
                     pha.start_date,
                     pha.end_date,
                     dcsa_max.id_commande,
                     dcsa_max.NUM_CONTRAT,
                     dcsa_max.DATE_RESILIATION,
                     dcsa_max.DATE_DEBUT_PERIODE,
                     dcsa_max.DATE_FIN_PERIODE,
                     dcsa_max.MONTANT_CONTRAT,
                     dcsa_max.VERSION_COMMANDE 
              ) phc,
             Po_Distributions_All pd,
             po_lines_all pla,
             po_line_locations_all plla,
             gl_code_combinations gcc_old,
             pa_projects_all ppa,
             hr_operating_units hou,
             (SELECT ffvv.flex_value
                FROM fnd_flex_values ffvv, fnd_flex_value_sets ffvs
               WHERE ffvs.flex_value_set_id = ffvv.flex_value_set_id
                 AND ffvs.flex_value_set_name = 'DAOPCCF_ANALYTIQUE'
                 AND (ffvv.attribute1 like 'PL%' OR
                     ffvv.attribute1 like '40PL%')) ffv
       WHERE 1 = 1
         AND gcc_old.code_combination_id = pd.code_combination_id
         AND ppa.project_id = pd.project_id
         AND ppa.org_id = hou.organization_id
         AND ph.po_header_id = pd.po_header_id
         and ph.po_header_id = pla.po_header_id
         and pla.po_line_id = plla.po_line_id
         and pd.line_location_id = plla.line_location_id
         and pd.po_line_id = plla.po_line_id
         and gcc_old.segment4 = ffv.flex_value
         AND ph.type_lookup_code = 'STANDARD' --RG4.1
         AND ph.segment1 LIKE 'ST%' -- RG4.1
         AND ph.authorization_status = 'APPROVED'
         AND phc.segment1 = ph.segment1
         AND ph.po_header_id = phc.id_commande
         AND nvl(ph.closed_code, 'OPEN') != 'FINALLY CLOSED' -- RG4.2
         AND nvl(pla.closed_code, 'OPEN') != 'FINALLY CLOSED' -- RG4.3
         AND nvl(plla.closed_code, 'OPEN') != 'FINALLY CLOSED' -- RG4.4
         AND substr(ppa.segment1, 1, 2) in ('FA', 'FB') -- RG4.5
         AND ppa.org_id = vn_org_id
         GROUP BY ppa.segment1, substr(hou.name, 4, 4), gcc_old.segment4;
     
          
  BEGIN

    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '    > Extract data : ' || 'Debut');

    -- Verification de l'existence du directory
    p_check_directory(p_directory_name);

    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, p_file_name, 'W');

    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                        '    > Extract data : ' || 'le fichier ' ||
                        p_directory_name || '/' || p_file_name ||
                        ' est ouvert en ecriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas etre ouvert en ecriture');
    END IF;

    SELECT period_year, end_date
      into vn_annee, vd_fin_periode
      FROM gl_periods
     WHERE period_name = pv_period_name
       AND period_set_name = 'GROUPE';

    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '    > Extract data : ' || 'Exercice : ' || vn_annee);
    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '    > Extract data : ' || 'Date de fin arrete : ' ||
                      to_char(vd_fin_periode, 'DD/MM/YYYY'));

    SELECT max(end_date)
      into vd_fin_annee
      FROM gl_periods
     WHERE period_set_name = 'GROUPE'
       AND period_year = vn_annee;

    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '    > Extract data : ' || 'Date de fin exercice : ' ||
                      to_char(vd_fin_annee, 'DD/MM/YYYY'));

    vv_periode_us := f_get_us_periode_name(pv_period_name);

    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '    > Extract data : ' ||
                      'Export du solde des commandes a receptionner');
    -- Extraction des donnees
    FOR IC in cde_solde LOOP

      vv_ligne := pv_const_solde_cde || K_SEPARATOR || vn_annee ||
                  K_SEPARATOR || vv_periode_us || K_SEPARATOR || IC.projet ||
                  K_SEPARATOR || IC.societe || K_SEPARATOR ||
                  pv_const_solde_cde || K_SEPARATOR || IC.compte_groupe ||
                  K_SEPARATOR || IC.solde;
                  
      
      -- Ecrit dans le fichier
      utl_file.put_line(l_file, vv_ligne);

      -- Maj des compteurs
      vn_nb_lignes_cde := vn_nb_lignes_cde + 1;

    END LOOP;

    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '    > Extract data : ' ||
                      'Export du solde de sous-traitance');

    -- Parcours de l'ensemble des UOs concernees
    FOR C_UO in SSTR_UO LOOP

      fnd_file.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                        '    > Extract data : ' ||
                        'Export du solde de sous-traitance - UO : ' ||
                        c_uo.org_id);

      -- Extraction des donnees
      FOR IC in sstr_solde(pv_period_name,
                           vd_fin_periode,
                           vd_fin_annee,
                           c_uo.org_id) LOOP

        vv_ligne := pv_const_solde_sstr || K_SEPARATOR || vn_annee ||
                    K_SEPARATOR || vv_periode_us || K_SEPARATOR ||
                    IC.projet || K_SEPARATOR || IC.societe || K_SEPARATOR ||
                    pv_const_solde_sstr || K_SEPARATOR || IC.compte_groupe ||
                    K_SEPARATOR || IC.solde;
                    
        -- Ecrit dans le fichier
        utl_file.put_line(l_file, vv_ligne);

        -- Maj des compteurs
        vn_nb_lignes_sstr := vn_nb_lignes_sstr + 1;

      END LOOP;
    
    END LOOP;

    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '    > Extract data : ' || 'Fermeture du fichier');

    -- Fermeture du fichier
    UTL_FILE.FCLOSE(l_file);

    -- Remet les valeurs des compteurs dans les parametres de la procedure
    p_nb_lignes      := vn_nb_lignes_cde + vn_nb_lignes_sstr;
    p_nb_lignes_sstr := vn_nb_lignes_sstr;
    p_nb_lignes_cde  := vn_nb_lignes_cde;

  EXCEPTION
    WHEN OTHERS THEN
      p_validate(FALSE,
                 'Probleme dans la procedure p_extract_data (' || SQLERRM || ')');

  END p_extract_data;
  ------------------------------------------------------------------------------------
  --  Nom           : p_extract_detail_sstr
  --  Description   : Extrait le détail du reste a faire SSTR vers Hyperion
  --
  --  PARAMETRES    :
  --  p_directory_name        Nom du directory
  --  p_file_name             Nom du fichier
  --  pv_period_name          Periode comptable
  --  p_nb_lignes_sstr        Nombre de lignes de reste à faire de sous traitance
  --  pv_const_solde_sstr     Valeur de la constante des commandes de sous traitance
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_detail_sstr(p_directory_name    IN ALL_DIRECTORIES.directory_name%type,
                                  p_file_name         IN VARCHAR2,
                                  pv_period_name      IN VARCHAR2,
                                  p_nb_lignes_sstr    IN OUT NUMBER,
                                  pv_const_solde_sstr IN OUT VARCHAR2) IS
  
    l_file UTL_FILE.file_type;
  
    vn_annee NUMBER;
  
    vd_fin_periode DATE;
    vd_fin_annee   DATE;
  
    vv_periode_us VARCHAR2(10);
    vv_ligne      VARCHAR2(4000);
    vv_dkcode     VARCHAR2(10);
  
    vn_reste_a_faire NUMBER := 0;
  
    CURSOR sstr_uo IS
      select ppa.org_id, hou.name
        from po_headers_all       pha,
             po_distributions_all pda,
             pa_projects_all      ppa,
             hr_operating_units   hou
       where pha.po_header_id = pda.po_header_id
         and pda.project_id = ppa.project_id
         AND hou.organization_id = ppa.org_id
         and pha.segment1 like '%ST%'
         and pha.TYPE_LOOKUP_CODE = 'STANDARD'
         AND nvl(pha.closed_code, 'OPEN') NOT IN ('FINALLY CLOSED')
       group by ppa.org_id, hou.name
       order by ppa.org_id;
  
    CURSOR sstr_solde(vv_periode_courante VARCHAR2,
                      vd_fin_arrete       DATE,
                      vd_fin_exercice     DATE,
                      vn_org_id           NUMBER) IS
      SELECT ppa.segment1 projet,
             substr(hou.name, 4, 4) societe,
             gcc_old.segment4 compte_groupe,
             ph.segment1 commande,
             ph.revision_num,
             pd.po_distribution_id,
             DKA_SPOCUT_OFF_PKG.get_charge_theorique_imput(to_number(pd.attribute3),
                                                           phc.start_date,
                                                           vd_fin_exercice) charge_exercice,
             DKA_SPOCUT_OFF_PKG.get_charge_theorique_imput(to_number(pd.attribute3),
                                                           phc.start_date,
                                                           vd_fin_arrete) charge_arrete,
             pv.segment1 vendor_num,
             pv.vendor_name,
             hou_cf.name cf,
             pt.task_number,
             phc.segment1 contrat,
             ph.closed_code,
             ph.closed_date,
             phc.start_date debut_commande,
             phc.end_date fin_commande,
             phc.montant_contrat
        FROM po_headers_all ph,
             (select pha.segment1,
                     pha.po_header_id,
                     pha.start_date,
                     pha.end_date,
                     pha.revision_num         version_contrat,
                     pha.blanket_total_amount montant_contrat,
                     dcsa_max.commande_id -- Récuperation du dernier contrat archivé pour chaque commande
                from po_headers_archive_all pha,
                     (select po_header_id,
                             commande_id,
                             max(revision_num) revision_num
                        from dka_contrat_sstr_archi
                       group by po_header_id, commande_id) dcsa_max,
                     gl_periods gp
               where dcsa_max.po_header_id = pha.po_header_id
                 and dcsa_max.revision_num = pha.revision_num
                 and pha.authorization_status = 'APPROVED'
                 and pha.attribute4 in
                     ('CONTRAT DEPENDANT', 'CONTRAT SOUS-TRAITANCE')
                 and gp.period_name = vv_periode_courante
                 and gp.period_set_name = 'GROUPE'
                 AND gp.end_date BETWEEN pha.start_date and pha.end_date -- RG4.6 RG4.7
              ) phc, -- contrats de sous-traitance approuvés
             Po_Distributions_All pd,
             po_lines_all pla,
             po_line_locations_all plla,
             gl_code_combinations gcc_old,
             pa_projects_all ppa,
             hr_operating_units hou,
             ----
             po_vendors            pv,
             hr_organization_units hou_cf,
             pa_tasks              pt,
             ----
             (SELECT ffvv.flex_value
                FROM fnd_flex_values ffvv, fnd_flex_value_sets ffvs
               WHERE ffvs.flex_value_set_id = ffvv.flex_value_set_id
                 AND ffvs.flex_value_set_name = 'DAOPCCF_ANALYTIQUE'
                 AND (ffvv.attribute1 like 'PL%' OR
                     ffvv.attribute1 like '40PL%')) ffv
       WHERE 1 = 1
         AND gcc_old.code_combination_id = pd.code_combination_id
         AND ppa.project_id = pd.project_id
         AND ppa.org_id = hou.organization_id
         AND ph.po_header_id = pd.po_header_id
            --
         and ph.po_header_id = pla.po_header_id
         and pla.po_line_id = plla.po_line_id
         and pd.line_location_id = plla.line_location_id
         and pd.po_line_id = plla.po_line_id
            --
         and pv.vendor_id = ph.vendor_id
         and hou_cf.organization_id = ppa.carrying_out_organization_id
         and pt.task_id = pd.task_id
            --
         and gcc_old.segment4 = ffv.flex_value
         AND ph.type_lookup_code = 'STANDARD' --RG4.1
         AND ph.segment1 LIKE '%ST%' -- RG4.1
         AND ph.authorization_status = 'APPROVED'
         AND phc.segment1 =
             substr(ph.segment1, 1, instr(ph.segment1, 'ST') + 1)
         AND ph.po_header_id = phc.commande_id
         AND nvl(ph.closed_code, 'OPEN') != 'FINALLY CLOSED' -- RG4.2
         AND nvl(pla.closed_code, 'OPEN') != 'FINALLY CLOSED' -- RG4.2
         AND nvl(plla.closed_code, 'OPEN') != 'FINALLY CLOSED' -- RG4.2
         AND substr(ppa.segment1, 1, 2) in ('FA', 'FB') -- RG4.5
         AND ppa.org_id = vn_org_id;
     
  --ARA EDB397
  CURSOR sstr_solde_ivalua(vv_periode_courante VARCHAR2,
                vd_fin_arrete       DATE,
                vd_fin_exercice     DATE,
                vn_org_id           NUMBER)
        IS
    
    SELECT   ppa.segment1 projet,
             substr(hou.name, 4, 4) societe,
             gcc_old.segment4 compte_groupe,
             ph.segment1 commande,
             ph.revision_num,
             pd.po_distribution_id,
             DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.get_charge_theorique_imput(pd.quantity_ordered,
                                                                     phc.DATE_DEBUT_PERIODE,
                                                                     phc.DATE_FIN_PERIODE,
                                                                     phc.DATE_RESILIATION,
                                                                     vd_fin_exercice) charge_exercice,
      
       DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.get_charge_theorique_imput(pd.quantity_ordered,
                                                                     phc.DATE_DEBUT_PERIODE,
                                                                     phc.DATE_FIN_PERIODE,
                                                                     phc.DATE_RESILIATION,
                                                                     vd_fin_arrete) charge_arrete,
             pv.segment1 vendor_num,
             pv.vendor_name,
             hou_cf.name cf,
             pt.task_number,
             phc.NUM_CONTRAT contrat,
             ph.closed_code,
             ph.closed_date,
             phc.DATE_DEBUT_PERIODE debut_commande,
             phc.DATE_FIN_PERIODE fin_commande,
             phc.montant_contrat
      
        FROM po_headers_all ph,
             (select pha.segment1,
                     pha.po_header_id,
                     pha.start_date,
                     pha.end_date,
                     max(pha.revision_num) revision_num,
                     dcsa_max.id_commande,
                     dcsa_max.NUM_CONTRAT,
                     dcsa_max.DATE_RESILIATION,
                     dcsa_max.DATE_DEBUT_PERIODE,
                     dcsa_max.DATE_FIN_PERIODE,
                     dcsa_max.MONTANT_CONTRAT
                from po_headers_archive_all pha,
                       
                       (
                       SELECT 
                          NUM_CONTRAT,
                          NUM_COMMANDE,
                          VERSION_CONTRAT,
                          VERSION_COMMANDE,
                          id_commande,
                          DATE_DEBUT_PERIODE,
                          DATE_FIN_PERIODE,
                          DATE_RESILIATION,
                          MONTANT_CONTRAT
                      FROM 
                          (SELECT 
                               NUM_CONTRAT,
                               NUM_COMMANDE,
                               VERSION_CONTRAT,
                               VERSION_COMMANDE,
                               id_commande,
                               DATE_DEBUT_PERIODE,
                               DATE_FIN_PERIODE,
                               DATE_RESILIATION,
                               MONTANT_CONTRAT,
                               ROW_NUMBER() OVER (PARTITION BY NUM_CONTRAT ORDER BY VERSION_CONTRAT DESC, VERSION_COMMANDE DESC) AS RN
                           FROM 
                               DKA_SPO_CONTRAT_SSTR_IVALUA dcs , gl_periods gp
                               where gp.period_name = vv_periode_courante
                               and gp.period_set_name = 'GROUPE'
                               AND gp.end_date BETWEEN dcs.DATE_DEBUT_PERIODE and dcs.DATE_FIN_PERIODE
                               )
                      WHERE 
                          RN = 1
                       )dcsa_max,
                     gl_periods gp
               where dcsa_max.id_commande = pha.po_header_id                
                 and pha.authorization_status = 'APPROVED'
                 and pha.attribute7 = 'IVALUA'
                 and gp.period_name = vv_periode_courante
                 and gp.period_set_name = 'GROUPE'
                 AND gp.end_date BETWEEN dcsa_max.DATE_DEBUT_PERIODE and dcsa_max.DATE_FIN_PERIODE
                 group by pha.segment1,
                     pha.po_header_id,
                     pha.start_date,
                     pha.end_date,
                     dcsa_max.id_commande,
                     dcsa_max.NUM_CONTRAT,
                     dcsa_max.DATE_RESILIATION,
                     dcsa_max.DATE_DEBUT_PERIODE,
                     dcsa_max.DATE_FIN_PERIODE,
                     dcsa_max.MONTANT_CONTRAT,
                     dcsa_max.VERSION_COMMANDE 
              ) phc, 
             Po_Distributions_All pd,
             po_lines_all pla,
             po_line_locations_all plla,
             gl_code_combinations gcc_old,
             pa_projects_all ppa,
             hr_operating_units hou,
             ----
             po_vendors            pv,
             hr_organization_units hou_cf,
             pa_tasks              pt,
             ----
       
             (SELECT ffvv.flex_value
                FROM fnd_flex_values ffvv, fnd_flex_value_sets ffvs
               WHERE ffvs.flex_value_set_id = ffvv.flex_value_set_id
                 AND ffvs.flex_value_set_name = 'DAOPCCF_ANALYTIQUE'
                 AND (ffvv.attribute1 like 'PL%' OR
                     ffvv.attribute1 like '40PL%')) ffv
       WHERE 1 = 1
         AND gcc_old.code_combination_id = pd.code_combination_id
         AND ppa.project_id = pd.project_id
         AND ppa.org_id = hou.organization_id
         AND ph.po_header_id = pd.po_header_id
         and ph.po_header_id = pla.po_header_id
         and pla.po_line_id = plla.po_line_id
         and pd.line_location_id = plla.line_location_id
         and pd.po_line_id = plla.po_line_id
        --
         and pv.vendor_id = ph.vendor_id
         and hou_cf.organization_id = ppa.carrying_out_organization_id
         and pt.task_id = pd.task_id
            -- 
         and gcc_old.segment4 = ffv.flex_value
         AND ph.type_lookup_code = 'STANDARD' --RG4.1
         AND ph.segment1 LIKE 'ST%' -- RG4.1
         AND ph.authorization_status = 'APPROVED'
         AND ph.po_header_id = phc.id_commande
         AND nvl(ph.closed_code, 'OPEN') != 'FINALLY CLOSED' -- RG4.2
         AND nvl(pla.closed_code, 'OPEN') != 'FINALLY CLOSED' -- RG4.3
         AND nvl(plla.closed_code, 'OPEN') != 'FINALLY CLOSED' -- RG4.4
         AND substr(ppa.segment1, 1, 2) in ('FA', 'FB') -- RG4.5
         AND ppa.org_id = vn_org_id;
  
  BEGIN
  
    Dka_Tools_Pkg.put_log_message('Dans la procedure p_extract_data');
  
    -- Verification de l'existence du directory
    p_check_directory(p_directory_name);
  
    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, p_file_name, 'W');
  
    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      Dka_Tools_Pkg.put_log_message('Le fichier ' || p_directory_name || '/' ||
                                    p_file_name ||
                                    ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
    END IF;
  
    SELECT period_year, end_date
      into vn_annee, vd_fin_periode
      FROM gl_periods
     WHERE period_name = pv_period_name
       AND period_set_name = 'GROUPE';
  
    SELECT max(end_date)
      into vd_fin_annee
      FROM gl_periods
     WHERE period_set_name = 'GROUPE'
       AND period_year = vn_annee;
  
    Dka_Tools_Pkg.put_log_message('Fin période : ' || vd_fin_periode);
    Dka_Tools_Pkg.put_log_message('Fin annee : ' || vd_fin_annee);
  
    vv_periode_us := f_get_us_periode_name(pv_period_name);
  
    vv_ligne := 'Code Origine;Exercice;Mois;Region;CF;Projet;Tache;Societe;Contrat;Commande;Statut fermeture cde;Date fermeture cde;Code fournisseur;Nom fournisseur;Date debut;Date fin;Version commande;Valeur Contrat;Compte Groupe;Charge exercice;Charge arrete;Reste a faire';
  
    -- Ecrit dans le fichier
    utl_file.put_line(l_file, vv_ligne);
  
    Dka_Tools_Pkg.put_log_message('---------------------------------------------------------------');
    Dka_Tools_Pkg.put_log_message('Parcours des UOs : ');
  
    FOR C_UO in SSTR_UO LOOP
    
      Dka_Tools_Pkg.put_log_message('UO : ' || C_UO.name || '(' ||
                                    c_uo.org_id || ')');
      vv_dkcode := f_get_DKCODE_region(substr(C_UO.name, 1, 3));
    
      FOR IC in sstr_solde(pv_period_name,
                           vd_fin_periode,
                           vd_fin_annee,
                           c_uo.org_id) LOOP
      
        vn_reste_a_faire := ROUND(IC.charge_exercice - IC.charge_arrete, 2); --RG5.1
      
        vv_ligne := pv_const_solde_sstr || K_SEPARATOR || -- Code Origine
                    vn_annee || K_SEPARATOR || -- Exercice
                    vv_periode_us || K_SEPARATOR || -- Mois
                    vv_dkcode || K_SEPARATOR || -- Region
                    IC.CF || K_SEPARATOR || -- CF
                    IC.projet || K_SEPARATOR || -- Projet
                    IC.task_number || K_SEPARATOR || -- Tache
                    '="' || IC.societe || '"' || K_SEPARATOR || -- Societe
                    IC.contrat || K_SEPARATOR || -- Contrat
                    IC.commande || K_SEPARATOR || -- Commande
                    IC.closed_code || K_SEPARATOR || -- Statut fermeture cde
                    '="' || to_char(IC.closed_date, 'DD/MM/YYYY') || '"' ||
                    K_SEPARATOR || -- Date fermeture cde
                    IC.vendor_num || K_SEPARATOR || -- Code fournisseur
                    IC.vendor_name || K_SEPARATOR || -- Nom fournisseur
                    '="' || to_char(IC.debut_commande, 'DD/MM/YYYY') || '"' ||
                    K_SEPARATOR || -- Date debut
                    '="' || to_char(IC.fin_commande, 'DD/MM/YYYY') || '"' ||
                    K_SEPARATOR || -- Date fin
                    IC.revision_num || K_SEPARATOR || -- Version commande
                    replace(IC.montant_contrat, '.', ',') || K_SEPARATOR || -- Valeur contrat
                    IC.compte_groupe || K_SEPARATOR || -- Compte groupe
                    replace(IC.charge_exercice, '.', ',') || K_SEPARATOR || -- Charge exercice
                    replace(IC.charge_arrete, '.', ',') || K_SEPARATOR || -- Charge arrete
                    replace(vn_reste_a_faire, '.', ','); -- Reste a faire
      
        -- Ecrit dans le fichier
        utl_file.put_line(l_file, vv_ligne);
      
        -- Maj des compteurs
        p_nb_lignes_sstr := p_nb_lignes_sstr + 1;
      
      END LOOP;
    
    --ARA EDB397
    FOR IC in sstr_solde_ivalua(pv_period_name,
                           vd_fin_periode,
                           vd_fin_annee,
                           c_uo.org_id) LOOP
      
        vn_reste_a_faire := ROUND(IC.charge_exercice - IC.charge_arrete, 2); --RG5.1
      
        vv_ligne := pv_const_solde_sstr || K_SEPARATOR || -- Code Origine
                    vn_annee || K_SEPARATOR || -- Exercice
                    vv_periode_us || K_SEPARATOR || -- Mois
                    vv_dkcode || K_SEPARATOR || -- Region
                    IC.CF || K_SEPARATOR || -- CF
                    IC.projet || K_SEPARATOR || -- Projet
                    IC.task_number || K_SEPARATOR || -- Tache
                    '="' || IC.societe || '"' || K_SEPARATOR || -- Societe
                    IC.contrat || K_SEPARATOR || -- Contrat
                    IC.commande || K_SEPARATOR || -- Commande
                    IC.closed_code || K_SEPARATOR || -- Statut fermeture cde
                    '="' || to_char(IC.closed_date, 'DD/MM/YYYY') || '"' ||
                    K_SEPARATOR || -- Date fermeture cde
                    IC.vendor_num || K_SEPARATOR || -- Code fournisseur
                    IC.vendor_name || K_SEPARATOR || -- Nom fournisseur
                    '="' || to_char(IC.debut_commande, 'DD/MM/YYYY') || '"' ||
                    K_SEPARATOR || -- Date debut
                    '="' || to_char(IC.fin_commande, 'DD/MM/YYYY') || '"' ||
                    K_SEPARATOR || -- Date fin
                    IC.revision_num || K_SEPARATOR || -- Version commande
                    replace(IC.montant_contrat, '.', ',') || K_SEPARATOR || -- Valeur contrat
                    IC.compte_groupe || K_SEPARATOR || -- Compte groupe
                    replace(IC.charge_exercice, '.', ',') || K_SEPARATOR || -- Charge exercice
                    replace(IC.charge_arrete, '.', ',') || K_SEPARATOR || -- Charge arrete
                    replace(vn_reste_a_faire, '.', ','); -- Reste a faire
      
        -- Ecrit dans le fichier
        utl_file.put_line(l_file, vv_ligne);
      
        -- Maj des compteurs
        p_nb_lignes_sstr := p_nb_lignes_sstr + 1;
      
      END LOOP;
    
    END LOOP;
  
    -- Fermeture du fichier
    UTL_FILE.FCLOSE(l_file);
  
    Dka_Tools_Pkg.put_log_message('Nombre de lignes extraites : ' ||
                                  p_nb_lignes_sstr);
    Dka_Tools_Pkg.put_log_message('---------------------------------------------------------------');
  
  EXCEPTION
    WHEN OTHERS THEN
      p_validate(FALSE,
                 'Probleme dans la procedure p_extract_data (' || SQLERRM || ')');
    
  END p_extract_detail_sstr;

  /*
  *************************************************************************
  * PROCEDURE NAME : output_header
  *
  * DESCRIPTION
  *  Procédure pour insérer une en-tete dans le fichier de sortie
  *
  * PARAMETERS
  * ==========
  * NAME              DESCRIPTION
  * ----------------- ------------------------------------------------------
  *
  *
  ************************************************************************
  */
  PROCEDURE output_header is
  BEGIN
  
    p_put_out_message('------------------------------------------------------------------------------');
    p_put_out_message('    Traitement     : ' || g_nom_traitement);
    p_put_out_message('    Date et Heure  : ' ||
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    p_put_out_message('------------------------------------------------------------------------------');
    p_put_out_message(' ');
  
  END;
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
    p_put_out_message(cv_line || CHR(10));
    p_put_out_message('Programme terminé le : ' ||
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
    p_put_out_message(cv_line);
  END output_end;

  /*=================================================================
  --  Nom           : INIT
  --  Description   : procedure d'initialisation
  --
  --  PARAMETRES :
  --
  --
  --=================================================================*/

  PROCEDURE init_mail(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
    rec_param dka_parameters%ROWTYPE;
    e_expediteur_vide EXCEPTION;
  
  BEGIN
    --Init des variables de sortie
    p_retcode := 0;
    p_errbuf  := '';
  
    Dka_Tools_Pkg.get_parameter('DKA_IPOHYPERION',
                                'EXPEDITEUR_MAIL',
                                rec_param,
                                p_errbuf,
                                p_retcode);
    gv_expediteur := rec_param.varchar2_value;
  
    IF gv_expediteur IS NULL THEN
      RAISE e_expediteur_vide;
    END IF;
  
    SELECT name INTO gv_base FROM v$database;
  
    Dka_Tools_Pkg.get_parameter('DKA_IPOHYPERION',
                                'SMTP_CONNECTION',
                                rec_param,
                                p_errbuf,
                                p_retcode);
    gv_conn := rec_param.varchar2_value;
  
    /*
    --Reinit des variables de sortie
    p_retcode := 0;
    p_errbuf  := '';*/
  
  EXCEPTION
    WHEN e_expediteur_vide THEN
      p_errbuf := 'Aucun expediteur trouve';
      Dka_Tools_Pkg.put_log_message(p_errbuf);
      p_retcode := 2;
    WHEN OTHERS THEN
      p_errbuf := 'Erreur procedure INIT :' || g_step || chr(10) || SQLERRM;
      Dka_Tools_Pkg.put_log_message(p_errbuf);
      p_retcode := 2;
  END init_mail;

  /*=================================================================
  --  Nom           : write_boundary
  --  Description   : ProcÃ¿Â©dure
  --
  --  PARAMETRES :
  --=================================================================*/
  PROCEDURE write_boundary(conn IN OUT NOCOPY utl_smtp.connection,
                           last IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
    IF (last) THEN
      utl_smtp.write_data(conn, LAST_BOUNDARY);
    ELSE
      utl_smtp.write_data(conn, FIRST_BOUNDARY);
    END IF;
  END write_boundary;

  /*=================================================================
  --  Nom           : begin_attachment
  --  Description   : ProcÃ¿Â©dure
  --
  --  PARAMETRES :
  --=================================================================*/
  PROCEDURE begin_attachment(conn         IN OUT NOCOPY utl_smtp.connection,
                             mime_type    IN VARCHAR2 DEFAULT 'text/plain',
                             inline       IN BOOLEAN DEFAULT TRUE,
                             filename     IN VARCHAR2 DEFAULT NULL,
                             transfer_enc IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    write_boundary(conn);
    utl_smtp.write_raw_data(conn,
                            utl_raw.cast_to_raw('Content-Type: ' ||
                                                mime_type || utl_tcp.CRLF));
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

  /*=================================================================
      --  Nom           : end_attachment
      --  Description   : ProcÃ¿Â©dure
      --
      --  PARAMETRES :
  =================================================================*/

  PROCEDURE end_attachment(conn IN OUT NOCOPY utl_smtp.connection,
                           last IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
    utl_smtp.write_data(conn, utl_tcp.CRLF || utl_tcp.CRLF);
    IF (last) THEN
      write_boundary(conn, last);
    END IF;
  END end_attachment;

  /*=================================================================
  --  Nom           : envoi_avec_fichier
  --  Description   : Envoi du message avec fichier.
  --
  --  PARAMETRES    :
  --          Pv_Errbuf    IN OUT     Message d'avertissement
  --          Pn_Retcode   IN OUT     Code erreur
  --          P_Date     IN         date echeance
  --          P_Req_Id     IN         id du traitement
  --          P_Region   IN         region
  --=================================================================*/
  PROCEDURE envoi_avec_fichier(Pv_Errbuf      IN OUT VARCHAR2,
                               Pn_Retcode     IN OUT NUMBER,
                               P_filename     IN VARCHAR2,
                               pv_period_name IN VARCHAR2) IS
    l_mesg           VARCHAR2(4000);
    l_conn           UTL_SMTP.CONNECTION;
    l_file           BFILE;
    V_FILEDIR        VARCHAR2(3000);
    l_file_len       PLS_INTEGER;
    l_modulo         PLS_INTEGER;
    l_pieces         PLS_INTEGER;
    l_filepos        PLS_INTEGER := 1; /* pointeur pour le fichier */
    l_buf            RAW(2100);
    l_data           RAW(2100);
    l_chunks         PLS_INTEGER;
    vr_reply         UTL_SMTP.REPLY;
    vv_adresses      VARCHAR2(32000);
    vb_adress_valide NUMBER;
    e_pas_destinataire EXCEPTION;
  
    vv_nom_etat VARCHAR2(30);
  
    CURSOR c_liste_destinataire IS
      SELECT ffvv.description adresse --, ffvv.flex_value
        FROM fnd_flex_value_sets ffvs, fnd_flex_values_vl ffvv
       WHERE ffvs.flex_value_set_name = 'DKA_SELENE_MAIL_CDG'
         AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
         AND ffvv.enabled_flag = 'Y'
         AND SYSDATE BETWEEN NVL(ffvv.start_date_active, SYSDATE) AND
             NVL(ffvv.end_date_active, SYSDATE);
  
  BEGIN
  
    vb_adress_valide := 0;
  
    g_step := 'ENVOI_AVEC_FICHIER 001 : RECHERCHE DE L''OBJET DU MAIL.';
    Dka_Tools_Pkg.Put_Log_Message(g_step);
    gv_objet := Dka_Tools_Pkg.get_message('DKA',
                                          'DKA_IPOHYPERION_MAIL_TITRE',
                                          'PERIODE',
                                          pv_period_name);
  
    g_step := 'ENVOI_AVEC_FICHIER 002 : RECHERCHE DU CORPS DU MAIL.';
    Dka_Tools_Pkg.Put_Log_Message(g_step);
  
    gv_corps := Dka_Tools_Pkg.get_message('DKA',
                                          'DKA_IPOHYPERION_MAIL_CORPS',
                                          'PERIODE',
                                          pv_period_name);
  
    g_step := 'ENVOI_AVEC_FICHIER 003 : CONNEXION.';
    Dka_Tools_Pkg.Put_Log_Message(g_step);
    l_conn := utl_smtp.open_connection(gv_conn, 25);
  
    g_step := 'ENVOI_AVEC_FICHIER 004 : DEBUT CONSTRUCTION MAIL.';
    Dka_Tools_Pkg.Put_Log_Message(g_step);
    utl_smtp.helo(l_conn, gv_conn);
  
    vr_reply := utl_smtp.mail(l_conn, gv_expediteur);
    g_step   := 'REPLY MAIL : ' || vr_reply.code || ' - ' || vr_reply.text;
    Dka_Tools_Pkg.Put_Log_Message(g_step);
  
    g_step := 'SEND_MAIL 003 : LISTE DESTINATAIRE';
    Dka_Tools_Pkg.Put_Log_Message(g_step);
    FOR ligne IN c_liste_destinataire LOOP
    
      vr_reply := utl_smtp.rcpt(l_conn, '<' || ligne.adresse || '>');
    
      g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' || vr_reply.text;
      Dka_Tools_Pkg.Put_Log_Message(g_step);
    
      IF vr_reply.code != '250' THEN
        g_step := 'SEND_MAIL E03 : ERREUR SUR DESTINATAIRE : ' ||
                  ligne.adresse;
        Dka_Tools_Pkg.Put_Log_Message(g_step);
        IF vb_adress_valide = 0 THEN
          vr_reply := utl_smtp.rcpt(l_conn, '<' || gv_expediteur || '>');
        
          g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
                    vr_reply.text;
          Dka_Tools_Pkg.Put_Log_Message(g_step);
          vv_adresses      := vv_adresses || ';' || gv_expediteur;
          vb_adress_valide := 1;
        END IF;
      ELSE
        vv_adresses := vv_adresses || ';' || ligne.adresse;
      END IF;
    
    END LOOP;
  
    --On retire le 1er ;
    IF LENGTH(vv_adresses) > 1 THEN
      vv_adresses := SUBSTR(vv_adresses, 2);
      Dka_Tools_Pkg.Put_Log_Message(substr('Adresse(s) destinataire(s)  : ' ||
                                           vv_adresses,
                                           1,
                                           255));
    
    ELSE
      RAISE e_pas_destinataire;
    END IF;
  
    utl_smtp.open_data(l_conn);
    l_mesg := 'Date: ' || to_char(systimestamp,
                                  'dd Mon yyyy hh24:mi:ss tzhtzm',
                                  'NLS_DATE_LANGUAGE=American') ||
              utl_tcp.CRLF || 'From: ' || gv_expediteur || utl_tcp.CRLF ||
              'To: ' || vv_adresses /*gv_plat_appro_mail*/
              || utl_tcp.CRLF || 'Subject:' || gv_objet || utl_tcp.CRLF ||
              'Reply-To: ' || gv_expediteur || utl_tcp.CRLF ||
              'Return-Path: ' || gv_expediteur || utl_tcp.CRLF ||
              'MIME-Version: 1.0' || utl_tcp.CRLF || 'Content-Type: ' ||
              MULTIPART_MIME_TYPE || utl_tcp.CRLF || utl_tcp.CRLF;
    utl_smtp.write_data(l_conn, l_mesg);
  
    -- Insertion du corps du message
    BEGIN
      begin_attachment(conn => l_conn, mime_type => 'text/html');
      utl_smtp.write_data(l_conn, gv_corps);
      end_attachment(conn => l_conn);
    END;
  
    gn_amt    := 672 * 3;
    l_filepos := 1;
  
    begin_attachment(conn         => l_conn,
                     mime_type    => 'text/csv',
                     inline       => TRUE,
                     filename     => p_filename,
                     transfer_enc => 'base64');
  
    BEGIN
    
      g_step := 'SEND_MAIL 03b : Recuperation repertoire';
      Dka_Tools_Pkg.Put_Log_Message(g_step);
    
      SELECT d.directory_name
        INTO V_FILEDIR
        FROM all_directories d
       WHERE DIRECTORY_NAME = 'DKA_OUT_DIR';
    
      g_step := 'SEND_MAIL 4 :  file ' || V_FILEDIR;
      Dka_Tools_Pkg.Put_Log_Message(g_step);
    END;
    g_step := 'SEND_MAIL 5.9 :  name file ' || p_filename;
    Dka_Tools_Pkg.Put_Log_Message(g_step);
  
    l_file := BFILENAME(V_FILEDIR, p_filename);
  
    g_step := 'SEND_MAIL 6 :  l_file ' || V_FILEDIR || '---' || p_filename;
    Dka_Tools_Pkg.Put_Log_Message(g_step);
  
    l_file_len := dbms_lob.getlength(l_file);
    l_modulo   := mod(l_file_len, gn_amt);
    l_pieces   := trunc(l_file_len / gn_amt);
    l_buf      := NULL;
  
    IF (l_modulo <> 0) THEN
      l_pieces := l_pieces + 1;
    END IF;
  
    dbms_lob.fileopen(l_file, dbms_lob.file_readonly);
    dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
    l_data := NULL;
    FOR i IN 1 .. l_pieces LOOP
      Dka_Tools_Pkg.Put_Log_Message('Step 1');
      l_filepos  := i * gn_amt + 1;
      l_file_len := l_file_len - gn_amt;
      l_data     := utl_raw.concat(l_data, l_buf);
      l_chunks   := trunc(utl_raw.length(l_data) / MAX_LINE_WIDTH);
    
      IF (i <> l_pieces) THEN
        l_chunks := l_chunks - 1;
      END IF;
      Dka_Tools_Pkg.Put_Log_Message('Step 2');
      utl_smtp.write_raw_data(l_conn, utl_encode.base64_encode(l_data));
      Dka_Tools_Pkg.Put_Log_Message('Step 3');
      l_data := NULL;
      IF (l_file_len < gn_amt AND l_file_len > 0) THEN
        gn_amt := l_file_len;
      END IF;
    
      IF l_pieces > 1 THEN
        Dka_Tools_Pkg.Put_Log_Message('Step 4');
        dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
        Dka_Tools_Pkg.Put_Log_Message('Step 5');
      END IF;
    END LOOP;
    Dka_Tools_Pkg.Put_Log_Message('Step 6');
    dbms_lob.fileclose(l_file);
    Dka_Tools_Pkg.Put_Log_Message('Step 7');
    end_attachment(conn => l_conn);
    Dka_Tools_Pkg.Put_Log_Message('Step 8');
  
    Dka_Tools_Pkg.Put_Log_Message('Step 9');
    utl_smtp.close_data(l_conn);
    Dka_Tools_Pkg.Put_Log_Message('Step 10');
    utl_smtp.quit(l_conn);
    Dka_Tools_Pkg.Put_Log_Message('Step 11');
    g_step := 'ENVOI_AVEC_FICHIER 005 ==> Mail envoye a adresse : ' ; -- SHA TASK0169842
          --    vv_adresses; -- SHA TASK0169842 
    Dka_Tools_Pkg.Put_Log_Message(g_step);
  Dka_Tools_Pkg.Put_Log_Message(vv_adresses);-- SHA TASK0169842
  
    g_step := 'ENVOI_AVEC_FICHIER 099 : FIN';
    Dka_Tools_Pkg.Put_Log_Message(g_step);
  EXCEPTION
    WHEN e_pas_destinataire THEN
      --Fermeture de la connexion
      IF l_conn.host IS NOT NULL THEN
        utl_smtp.quit(l_conn);
      END IF;
    
      Pv_Errbuf  := 'Pas de destinataire';
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);
      RAISE;
    WHEN OTHERS THEN
      Pv_Errbuf := 'ENVOI_AVEC_FICHIER 099 - ERREUR : ' || SQLERRM;
      Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);
      Pn_Retcode := 2;
      RAISE;
  END envoi_avec_fichier;

  /*===================================================================================
    --  NOM           : EDITION_OUTPUT_MAIL
    --  DESCRIPTION   : procedure d'edition du fichier de sortie pour l'envoi par mail
    --
    --  PARAMETRES :
    --
    --  P_RETCODE             code retour out
    --  P_ERRBUF              description de l'erreur out
  --==================================================================================*/
  PROCEDURE edition_output_mail(p_errbuf  OUT VARCHAR2,
                                p_retcode OUT NUMBER) IS
  
    l_appl      fnd_application.application_short_name%TYPE;
    l_prgm_name fnd_conc_req_summary_v.PROGRAM%TYPE;
  
    l_out   VARCHAR2(4000);
    l_ligne VARCHAR2(100) := '---------------------------------------------------------------';
  
    -- Curseur de recherche de l'ensemble des adresses mail de destination :
    CURSOR cur_mail IS
      select ffv.flex_value, ffv.FLEX_VALUE_MEANING, ffv.DESCRIPTION
        from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
       where ffvs.flex_value_set_id = ffv.flex_value_set_id
         and ffvs.flex_value_set_name = 'DKA_SELENE_MAIL_CDG'
         and ffv.ENABLED_FLAG = 'Y'
         and nvl(ffv.START_DATE_ACTIVE, trunc(SYSDATE)) <= trunc(SYSDATE)
         and nvl(ffv.END_DATE_ACTIVE, trunc(SYSDATE)) >= trunc(SYSDATE)
         and ffv.SUMMARY_FLAG = 'N';
  
    rec_mail cur_mail%ROWTYPE;
  BEGIN
  
    g_step := 'EDITION_OUTPUT_MAIL 000 : DEBUT';
    Dka_Tools_Pkg.Put_Log_Message(g_step);
  
    --Recuperation des informations
    BEGIN
      --RÃ¿Â©cupÃ¿Â©ration du nom de la base de donnÃ¿Â©es.
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
    p_put_debug_message(l_out);
  
    p_put_debug_message(l_ligne);
  
    --CORPS
    l_out := 'Parametre :';
    Dka_Tools_Pkg.Put_Log_Message(l_out);
    l_out := '-----------';
    Dka_Tools_Pkg.Put_Outdebug_Message(l_ligne);
    l_out := 'E-mail de destination : ';
    Dka_Tools_Pkg.Put_Outdebug_Message(l_out);
    l_out := '------------------------';
    Dka_Tools_Pkg.Put_Outdebug_Message(l_out);
    OPEN cur_mail;
    LOOP
      FETCH cur_mail
        INTO rec_mail;
      EXIT WHEN cur_mail%NOTFOUND;
      l_out := rec_mail.DESCRIPTION;
      Dka_Tools_Pkg.Put_Outdebug_Message(' - ' || rec_mail.flex_value || ' <' ||
                                         l_out || '>');
    END LOOP;
    CLOSE cur_mail;
    Dka_Tools_Pkg.Put_Outdebug_Message(l_ligne);
    l_out := 'MAIL :';
    Dka_Tools_Pkg.Put_Outdebug_Message(l_out);
    l_out := '------';
    Dka_Tools_Pkg.Put_Outdebug_Message(l_out);
    l_out := 'OBJET : ' || gv_objet;
    Dka_Tools_Pkg.Put_Outdebug_Message(l_out);
    Dka_Tools_Pkg.Put_Outdebug_Message(gv_corps);
  
    g_step := 'EDITION_OUTPUT_MAIL 999 : FIN';
    Dka_Tools_Pkg.Put_Log_Message(g_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'Erreur procedure EDITION_OUTPUT_MAIL :' || g_step ||
                   chr(10) || SQLERRM;
      Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuf);
  END edition_output_mail;

  /*================================================================================================================
  -- Procedure         : p_envoi_mail
  -- Description       : Procedure d'envoi de mail pour le detail du reste à faire de sous traitance
  -- Parametres entree : 
  --             Pv_Errbuf      IN OUT    : Message d'avertissement
  --             Pn_Retcode     IN OUT    : Code erreur
  --             P_filename     IN        : Nom du fichier
  --             pv_period_name IN        : Periode de lancement
  --
  -- Parametres sortie : AUCUN
  -- Remarques         :
  --================================================================================================================*/

  PROCEDURE p_envoi_mail(Pv_Errbuf      IN OUT VARCHAR2,
                         Pn_Retcode     IN OUT NUMBER,
                         P_filename     IN VARCHAR2,
                         pv_period_name IN VARCHAR2) IS
  
    e_edition_output_mail EXCEPTION;
  
  BEGIN
  
    g_step := 'ENVOI_MAIL 000 : DEBUT';
    Dka_Tools_Pkg.Put_Log_Message(g_step);
  
    -- Initialisation des variables d'envoi de mail :
    g_step := 'ENVOI_MAIL 001 : INITIALISATION DES VARIABLES D''ENVOI DE MAIL.';
    Dka_Tools_Pkg.Put_Log_Message(g_step);
    init_mail(Pv_Errbuf, Pn_Retcode);
    IF Pn_Retcode != 0 THEN
      g_step := 'ENVOI_MAIL 001 : ERROR - INITIALISATION DES VARIABLES D''ENVOI DE MAIL.';
      raise e_envoi_mail;
    END IF;
  
    -- Initialisation du message contenant un fichier.
    g_step := 'ENVOI_MAIL 002 : ENVOI DU MESSAGE AVEC FICHIER.';
    Dka_Tools_Pkg.Put_Log_Message(g_step);
    envoi_avec_fichier(Pv_Errbuf, Pn_Retcode, P_filename, pv_period_name);
  
    ----------------------------------------------------------------
    --Edition fichier de sortie
    ----------------------------------------------------------------
    g_step := 'ENVOI_MAIL 003 : EDITION FICHIER DE SORTIE.';
    Dka_Tools_Pkg.Put_Log_Message(g_step);
    edition_output_mail(Pv_Errbuf, Pn_Retcode);
    IF Pn_Retcode != 0 THEN
      RAISE e_edition_output_mail;
    END IF;
    g_step := 'ENVOI_MAIL 999 : FIN';
    Dka_Tools_Pkg.Put_Log_Message(g_step);
  EXCEPTION
    WHEN e_edition_output_mail THEN
      Pv_Errbuf  := 'Erreur procedure EDITION_OUTPUT_MAIL';
      Pn_Retcode := 2;
      Dka_Tools_Pkg.Put_Log_Message(Pv_Errbuf);
    WHEN e_mail THEN
      Dka_Tools_Pkg.Put_Log_Message(Pv_Errbuf);
      Pn_Retcode := 2;
    WHEN e_envoi_mail THEN
      Dka_Tools_Pkg.Put_Log_Message('ERREUR - ' || g_step);
      Pv_Errbuf := 'ERREUR : ' || SQLERRM;
      Dka_Tools_Pkg.Put_Log_Message(Pv_Errbuf);
      Pn_Retcode := 2;
    WHEN OTHERS THEN
      Dka_Tools_Pkg.Put_Log_Message('ERREUR - ' || g_step);
      Pv_Errbuf := 'ERREUR : ' || SQLERRM;
      Dka_Tools_Pkg.Put_Log_Message(Pv_Errbuf);
      Pn_Retcode := 2;
    
  END p_envoi_mail;

  ------------------------------------------------------------------------------------
  --  Nom           : p_bilan
  --  Description   : Affichage des stats
  --
  --  PARAMETRES    :
  --  p_periode        periode d'extraction
  --  p_nb_lignes      nombre de lignes extraites dans le fichier
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_bilan(p_fichier           in varchar2,
                    p_periode           IN VARCHAR2,
                    p_nb_lignes         IN OUT number,
                    p_nb_lignes_cde     IN OUT NUMBER,
                    p_nb_lignes_sstr    IN OUT NUMBER,
                    vv_const_solde_cde  in OUT VARCHAR2,
                    vv_const_solde_sstr in OUT VARCHAR2) IS
  
  BEGIN
  
    Fnd_File.put_line(Fnd_File.output,
                      ' Période de lancement : ' || p_periode);
    Fnd_File.put_line(Fnd_File.output,
                      ' Nom de fichier       : ' || p_fichier);
    Fnd_File.put_line(Fnd_File.output, chr(10));
    Fnd_File.put_line(Fnd_File.output,
                      ' Extraction du solde des commandes à réceptionner       ');
    Fnd_File.put_line(Fnd_File.output,
                      ' Code Origine         : ' || vv_const_solde_cde);
    Fnd_File.put_line(Fnd_File.output,
                      ' Nombre de lignes     : ' || p_nb_lignes_cde);
    Fnd_File.put_line(Fnd_File.output, chr(10));
    Fnd_File.put_line(Fnd_File.output,
                      ' Extraction du reste à faire de sous-traitance       ');
    Fnd_File.put_line(Fnd_File.output,
                      ' Code Origine         : ' || vv_const_solde_sstr);
    Fnd_File.put_line(Fnd_File.output,
                      ' Nombre de lignes     : ' || p_nb_lignes_sstr);
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
  --  Nom           : p_bilan
  --  Description   : Affichage des stats
  --
  --  PARAMETRES    :
  --  p_periode        periode d'extraction
  --  p_nb_lignes      nombre de lignes extraites dans le fichier
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_bilan_detail_sstr(p_fichier           in varchar2,
                                p_periode           IN VARCHAR2,
                                p_nb_lignes_sstr    IN OUT NUMBER,
                                vv_const_solde_sstr in OUT VARCHAR2) IS
  
  BEGIN
  
    Fnd_File.put_line(Fnd_File.output,
                      'Période de lancement : ' || p_periode);
    Fnd_File.put_line(Fnd_File.output,
                      'Nom de fichier       : ' || p_fichier);
    Fnd_File.put_line(Fnd_File.output, chr(10));
    Fnd_File.put_line(Fnd_File.output,
                      'Extraction du détail du reste à faire de sous-traitance       ');
    Fnd_File.put_line(Fnd_File.output,
                      'Code Origine         : ' || vv_const_solde_sstr);
  
    IF p_nb_lignes_sstr > 0 THEN
      Fnd_File.put_line(Fnd_File.output,
                        'Volume des lignes générées : ' || p_nb_lignes_sstr ||
                        ' lignes.');
    ELSE
      Fnd_File.put_line(Fnd_File.output, 'Aucune ligne trouvée.');
    END IF;
  
  END p_bilan_detail_sstr;

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
  PROCEDURE main(pv_errbuf  OUT NOCOPY VARCHAR2,
                 pn_retcode OUT NOCOPY NUMBER) IS
  
    ln_nb_lignes     number := 0;
    p_nb_lignes_cde  NUMBER := 0;
    p_nb_lignes_sstr NUMBER := 0;
  
    vv_const_solde_cde  VARCHAR2(20) := 'AMONT_PO_CDE_SOLDE';
    vv_const_solde_sstr VARCHAR2(20) := 'AMONT_PO_SSTR';
  
  BEGIN
  
    g_nom_traitement := 'DKA : Extraction des données PO pour HYPERION';
    output_header;
    lv_current_program_unit := 'main';
  
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS=''' || '.,' || '''';
  
    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Sélection de la période');
  
    BEGIN
    
      SELECT period_name
        INTO pv_period_name
        FROM gl_periods
       WHERE period_set_name = 'GROUPE'
         AND end_date = (SELECT min(start_date) - 1
                           FROM gl_period_statuses gps,
                                hr_operating_units hou,
                                gl_ledgers         gll
                          WHERE gps.set_of_books_id = hou.set_of_books_id
                            AND gps.ledger_id = gll.ledger_id
                            AND gps.closing_status = 'O'
                            AND nvl(hou.date_to, SYSDATE) >= sysdate - 1
                            AND gps.application_id = 201
                            AND closing_status = 'O');
    EXCEPTION
      WHEN OTHERS THEN
        raise E_PERIOD_ERROR;
      
    END;
  
    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Période : ' || pv_period_name);
  
    -- Construction du nom du fichier
    lv_nom_fichier := 'FIN01_SRC_COMMANDESPO_' ||
                      to_char(sysdate, 'YYYYMMDD-HH24miss') || '.csv';
    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Nom fichier : ' || lv_nom_fichier);
  
    -- Extrait les lignes d'écritures dans le fichier
    p_extract_data(K_DIRECTORY,
                   lv_nom_fichier,
                   pv_period_name,
                   ln_nb_lignes,
                   p_nb_lignes_cde,
                   p_nb_lignes_sstr,
                   vv_const_solde_cde,
                   vv_const_solde_sstr);
  
    -- Edite un rapport de traitment
    p_bilan(lv_nom_fichier,
            pv_period_name,
            ln_nb_lignes,
            p_nb_lignes_cde,
            p_nb_lignes_sstr,
            vv_const_solde_cde,
            vv_const_solde_sstr);
    output_end;
  EXCEPTION
    WHEN E_PERIOD_ERROR THEN
      pv_errbuf  := 'Erreur dans la détermination de la période ' ||
                    chr(10) || SQLERRM;
      pn_retcode := 2;
      fnd_file.put_line(Fnd_File.LOG, pv_errbuf);
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure ' || cv_package_name || '.' ||
                    lv_current_program_unit || chr(10) || SQLERRM;
      pn_retcode := 2;
      fnd_file.put_line(Fnd_File.LOG, pv_errbuf);
    
  END;

  ------------------------------------------------------------------------------------
  --  Nom           : main_detail_sstr
  --  Description   : Export du detail de sous traitance pour Hyperion
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)
  --  pv_livre              Jeu de livres
  --
  ------------------------------------------------------------------------------------
  PROCEDURE main_detail_sstr(pv_errbuf  OUT NOCOPY VARCHAR2,
                             pn_retcode OUT NOCOPY NUMBER) IS
  
    p_nb_lignes_sstr    NUMBER := 0;
    vv_const_solde_sstr VARCHAR2(20) := 'AMONT_PO_SSTR';
  
  BEGIN
  
    g_nom_traitement := 'DKA : Export du détail de sous-traitance pour HYPERION';
    output_header;
    lv_current_program_unit := 'main_detail_sstr';
  
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS=''' || '.,' || '''';
  
    Dka_Tools_Pkg.put_log_message('Sélection de la période');
  
    BEGIN
    
      SELECT period_name
        INTO pv_period_name
        FROM gl_periods
       WHERE period_set_name = 'GROUPE'
         AND end_date = (SELECT min(start_date) - 1
                           FROM gl_period_statuses gps,
                                hr_operating_units hou,
                                gl_ledgers         gll
                          WHERE gps.set_of_books_id = hou.set_of_books_id
                            AND gps.ledger_id = gll.ledger_id
                            AND gps.closing_status = 'O'
                            AND nvl(hou.date_to, SYSDATE) >= sysdate - 1
                            AND gps.application_id = 201
                            AND closing_status = 'O');
    EXCEPTION
      WHEN OTHERS THEN
        raise E_PERIOD_ERROR;
      
    END;
  
    Dka_Tools_Pkg.put_log_message('Période : ' || pv_period_name);
  
    -- Construction du nom du fichier
    lv_nom_fichier := 'FIN01_SRC_DETAILSSTR_' ||
                      to_char(sysdate, 'YYYYMMDD-HH24miss') || '.csv';
  
    Dka_Tools_Pkg.put_log_message('Nom fichier : ' || lv_nom_fichier);
  
    -- Extrait les lignes d'écritures dans le fichier
    p_extract_detail_sstr(K_DIRECTORY,
                          lv_nom_fichier,
                          pv_period_name,
                          p_nb_lignes_sstr,
                          vv_const_solde_sstr);
  
    -- Edite un rapport de traitment
    p_bilan_detail_sstr(lv_nom_fichier,
                        pv_period_name,
                        p_nb_lignes_sstr,
                        vv_const_solde_sstr);
  
    p_envoi_mail(pv_errbuf, pn_retcode, lv_nom_fichier, pv_period_name);
  
    output_end;
  EXCEPTION
    WHEN E_PERIOD_ERROR THEN
      pv_errbuf  := 'Erreur dans la détermination de la période ' ||
                    chr(10) || SQLERRM;
      pn_retcode := 2;
      fnd_file.put_line(Fnd_File.LOG, pv_errbuf);
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure ' || cv_package_name || '.' ||
                    lv_current_program_unit || chr(10) || SQLERRM;
      pn_retcode := 2;
      fnd_file.put_line(Fnd_File.LOG, pv_errbuf);
    
  END;

END DKA_IPOHYPERION_PKG;

/
SHOW ERRORS;
EXIT