CREATE OR REPLACE PACKAGE BODY APPS.DKA_SPOSSTR_EXT_PKG IS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_SPOSSTR_EXT_PKG.pkb
    -- DESCRIPTION      : DKA_SPOSSTR_EXT_PKG Package Body
    --
    -- AUTEUR           : Anas RAOUF (Capgemini)
    -- DATE DE CREATION : 06/12/2024
    -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
    -- -----------------------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- -----------------------------------------------------------------------------
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    TYPE summary_typ IS RECORD 
    (
     loaded_header_rows               NUMBER      -- Nb des en-entétes chargées en table specifique
    ,loaded_transaction_rows          NUMBER      -- Nb des transactions chargés en table specifique
    ,rec_final_rows                   NUMBER      -- Nb des en-entétes chargées en table specifique
    ,rejected_header_rows             NUMBER      -- Nb de Lignes en-entétes rejectées
    ,rejected_io_rows                 NUMBER      -- Nb de Lignes transaction rejectés
    ,complete_header_rows             NUMBER      -- SELO
    ,inserted_header_rows             NUMBER      -- Nb de Lignes en-entétes insérées
    ,inserted_transaction_rows        NUMBER      -- Nb de Lignes transaction insérés
    ,purged_header_rows               NUMBER      -- Nb de Lignes purgées en table spécifique   
    ,purged_interface_rows            NUMBER      -- Nb de Lignes purgées en table spécifique 
    , purged_errors_rows              NUMBER
    , purged_transaction_rows         NUMBER
    ,message_flag                     NUMBER      -- Flag d'entete etat des erreurs
    ,reprise_flag                     VARCHAR2(1) -- Flag reprise
    ,warning_flag                     VARCHAR2(1) -- Flag warning
    );

    g_summary                      summary_typ;
    g_request_id      VARCHAR2(30) := fnd_global.CONC_REQUEST_ID;
    gv_created_by      VARCHAR2(60) := fnd_profile.value('USER_NAME');

  g_user_id          PLS_INTEGER  := fnd_profile.value('USER_ID');
  g_resp_id          PLS_INTEGER  := fnd_profile.value('RESP_ID');
    g_org_id           PLS_INTEGER  := FND_GLOBAL.org_id;
  g_resp_appl_id     PLS_INTEGER  := fnd_global.resp_appl_id;
    g_login_id                     fnd_logins.login_id%TYPE;
  cv_directory CONSTANT VARCHAR2(50) := 'DKA_OUT_DIR';

  gn_nbre_reconduction NUMBER(15);

    -- Variable d'exception :
    e_envoi_mail EXCEPTION;
    e_mail EXCEPTION;

    -- Variable contenant l'entéte et le corps du mail.
    gv_objet VARCHAR2(4000);
    gv_corps VARCHAR2(4000);

    TYPE liste_destinataires IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;


/*
 *************************************************************************
 * PROCEDURE NAME : Output_Header
 *
 * DESCRIPTION
 *  Procédure pour insérer une en-téte dans le fichier de sortie
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
        cv_line                     VARCHAR2 (1000);
  BEGIN

        cv_line    := '+-----------------------------------------------------------------------------------------------------------------+';

        Fnd_File.put_line (Fnd_File.output, cv_line );
    Fnd_File.put_line (Fnd_File.output, 'TRAITEMENT << DKA : Extraction des contrats SSTR à reprendre dans iValua >> ');
        Fnd_File.put_line (Fnd_File.output, 'Traitement n ° : '||fnd_global.conc_request_id);
        Fnd_File.put_line (Fnd_File.output, 'Programme lancé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') );
    Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
  END output_header;


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
        cv_line                     VARCHAR2 (1000);
  BEGIN

        cv_line    := '+---------------------------------------------------------------------+';

        Fnd_File.put_line (Fnd_File.output, cv_line);
        Fnd_File.put_line (Fnd_File.output, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.output, cv_line);
  END output_end;

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
  
-- -----------------------------------------------------------------------------
     -- Nom              : check_value_set
     -- Description      : Vérifie de l'existence d'un jeu de valeurs et provoque une exception s'il n'existe pas
     -- -----------------------------------------------------------------------------
     procedure check_value_set(p_value_set_name in fnd_flex_value_sets.flex_value_set_name%type
                ,p_errbuf    OUT      VARCHAR2,
                p_retcode   OUT      NUMBER) is
   
        cursor cur_value_set(p_value_set_name in varchar2) is
        select ffvs.FLEX_VALUE_SET_ID,
               sum(case when ffv.ENABLED_FLAG='Y' and sysdate between trunc(nvl(ffv.START_DATE_ACTIVE, sysdate)) and trunc(nvl(ffv.END_DATE_ACTIVE, SYSDATE+1)) then 1 else 0 end) as active_lines,
               count(ffv.flex_value_id) as lines
        from fnd_flex_value_sets        ffvs
        left outer join fnd_flex_values ffv  on (ffvs.flex_value_set_id =  ffv.flex_value_set_id)
        where ffvs.flex_value_set_name = p_value_set_name
        group by ffvs.FLEX_VALUE_SET_ID;
        l_value_set cur_value_set%rowtype;
        l_ok boolean := false;
      begin
        open cur_value_set(p_value_set_name);
        fetch cur_value_set into l_value_set;
        if cur_value_set%notfound then
          log_msg('Le jeu de valeurs ' || p_value_set_name || ' n''existe pas.');
      p_retcode := 2;
        elsif l_value_set.lines = 0 then
          log_msg('Aucune ligne n''est configurée dans le jeu de valeurs ' || p_value_set_name || '.');
      p_retcode := 2;
        elsif l_value_set.active_lines = 0 then
          log_msg('Aucune valeur n''est active dans le jeu de valeurs ' || p_value_set_name || '.');
      p_retcode := 2;
        else
          log_msg('Jeu de valeurs OK : ' || p_value_set_name);
          l_ok := true;
        end if;
        close cur_value_set;
        if not l_ok then
          p_retcode := 2;
        end if;
      end check_value_set;

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
          Pv_file_name OUT VARCHAR2
                  )
  IS

    v_current_program_unit    VARCHAR2(30);
    v_step_program_error      VARCHAR2(1000);
    program_error             EXCEPTION;
  v_num_fourn_cmd       VARCHAR2(30);
  v_record_id               NUMBER;
    v_HEADER_ID               NUMBER;
  v_UO_CMD          VARCHAR2(10);
  v_closed_date         VARCHAR2(10);
  v_auth_status         VARCHAR2(80);
  v_paiement_direct     VARCHAR2(10); --EDB288B
  v_montant               VARCHAR2(30);
  v_type_four         VARCHAR2(100);
  v_note              VARCHAR2(240);
    v_existence               VARCHAR2(10);
  v_TF            VARCHAR2(30);
  v_PF            VARCHAR2(30);
  v_description       VARCHAR2(300);
    v_count                   NUMBER;
    vn_nb_line                NUMBER;
    v_org_id_cmd              NUMBER;
  lv_csv_line varchar2(32000);
    is_found_rec boolean := false;

  fileHandler UTL_FILE.FILE_TYPE;
    filename    varchar2(70);
  
  l_param   VARCHAR2(100);
  rec_param dka_parameters%ROWTYPE;
    e_err_param EXCEPTION;
  
  

  CURSOR cur_sstr_1 (p_header_id IN NUMBER) IS
  
  SELECT
  hps.name UO,
  pha.segment1 NUM_CONTRAT,
  aps.segment1 NUM_FOURNISSEUR,
  substr(TRANSLATE(
        regexp_replace(dcs.DESCRIPTION_SPECIFIQUE_CONTRAT, '[^a-zA-Z0-9 éèêëàâäùûüôöîïçœ€.,;:!?()\]', ''),
            'ÁÀÂÄáàâäÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖóòôöÚÙÛÜúùûüÇç',
            'AAAAaaaaEEEEeeeeIIIIiiiiOOOOooooUUUUuuuuCc'
        ),1,110)  DESCRIPTION,
  substr(TRANSLATE(
        regexp_replace(dcs.REF_CONTRAT_FOURNISSEUR, '[^a-zA-Z0-9 éèêëàâäùûüôöîïçœ€.,;:!?()\]', ''),
            'ÁÀÂÄáàâäÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖóòôöÚÙÛÜúùûüÇç',
            'AAAAaaaaEEEEeeeeIIIIiiiiOOOOooooUUUUuuuuCc'
        ),1,128) REF_CONTRAT_FRS,
  pha.ATTRIBUTE5 NATURE_PRESTATION,
  dcs.NB_INTERVENTION NB_INTERVENTION_PERIODE,
  to_char(pha.START_DATE , 'DD/MM/YYYY') DATE_DEBUT_PERIODE,
  to_char(pha.END_DATE , 'DD/MM/YYYY') DATE_FIN_PERIODE,
  to_char(decode(pha.Revision_Num, 0, pha.start_date, Ref_start_date.start_date), 'DD/MM/YYYY') AS DATE_DEBUT_GLOBALE,
  to_char(add_months(pha.end_date, decode(sign(nvl(dcs.NB_RECONDUCTION,0)- dcs.RECONDUCTION_NUM), -1, 0, (nvl(dcs.NB_RECONDUCTION,0)- dcs.RECONDUCTION_NUM)*12)), 'DD/MM/YYYY') AS DATE_FIN_GLOBALE,
  ROUND(MONTHS_BETWEEN(TRUNC(pha.END_DATE),TRUNC (pha.START_DATE))) as DUREE_RECONDUCTION ,
  dcs.NB_RECONDUCTION NB_RECONDUCTION_MAX,
  dcs.RECONDUCTION_NUM,
  dcs.PREAVIS_RESILIATION,
  per.EMPLOYEE_NUMBER GESTIONNAIRE,
  pha.BLANKET_TOTAL_AMOUNT MONTANT_PERIODE_HT,
  pha.CURRENCY_CODE DEVISE,
  decode(pha.ATTRIBUTE13 , 'NON' , 'N' , 'Y') PAIEMENT_DIRECT,
  (
    SELECT segment1
    from PO_headers_all pp
    where pp.PO_HEADER_ID = dcs.COMMANDE_ID
  ) NUM_COMMANDE_SSTR,
  pap.segment1 NUM_PROJET

  FROM po_headers_all pha,
  dka_contrat_sstr dcs,
  PA_PROJECTS_ALL pap,
  hr_operating_units hps,
  ap_suppliers aps,
  per_people_v7 per,
  
  (select * from DKA_CONTRAT_SSTR_IMPUTATION dcss
         where dcss.CONTRAT_IMPUTATION_ID =
          (select max(CONTRAT_IMPUTATION_ID) 
        from DKA_CONTRAT_SSTR_IMPUTATION
        where po_header_id = dcss.po_header_id
        and UNITE_OEUVRE != 0)) dcsi,
    
  (select phaa.po_header_id, phaa.start_date 
      from po_headers_archive_all phaa
      where phaa.revision_num = (select max(dcsa1.revision_num) from dka_contrat_sstr_archi dcsa1
                   where dcsa1.reconduction_num = 0
                   and dcsa1.po_header_id = phaa.po_header_id)) Ref_start_date
  where dcs.po_header_id = pha.po_header_id
  and hps.organization_id = dcs.org_id
  and pha.vendor_id = aps.vendor_id
  and pha.type_lookup_code = 'CONTRACT'
  AND pha.closed_date IS NULL
  AND pha.authorization_status = 'APPROVED'
  AND (pha.closed_date IS NULL OR TRUNC(pha.closed_date) > TRUNC(pha.end_date))
 -- AND dcs.reconduction_num < dcs.NB_RECONDUCTION
  and Ref_start_date.po_header_id  = pha.PO_HEADER_ID
  AND per.person_id =  dcs.SIGNATAIRE_CONTRAT
  
  and pha.po_header_id = dcsi.po_header_id
  and dcsi.PROJECT_ID = pap.PROJECT_ID
  and pha.po_header_id = p_header_id
  ;
  
  CURSOR cur_sstr_reapp IS

  SELECT pha.po_header_id 
  from PO_HEADERS_ALL pha , dka_contrat_sstr dcs
  where dcs.po_header_id = pha.po_header_id
  and dcs.commande_id is null
  and pha.authorization_status = 'REQUIRES REAPPROVAL'
  and closed_code is null and closed_date IS NULL
  and add_months(pha.end_date, decode(sign(nvl(dcs.NB_RECONDUCTION,0)- dcs.RECONDUCTION_NUM), -1, 0, (nvl(dcs.NB_RECONDUCTION,0)- dcs.RECONDUCTION_NUM)*12)) > sysdate
  and type_lookup_code = 'CONTRACT'
  and dcs.reconduction_num <= dcs.NB_RECONDUCTION;
  
  CURSOR cur_sstr_approv IS
  Select pha.po_header_id
  from PO_HEADERS_ALL pha , dka_contrat_sstr dcs 
  where dcs.po_header_id = pha.po_header_id
  and pha.authorization_status = 'APPROVED'
  and dcs.commande_id is not null
  and pha.closed_code is null 
  and pha.closed_date IS NULL
  and add_months(pha.end_date, decode(sign(nvl(dcs.NB_RECONDUCTION,0)- dcs.RECONDUCTION_NUM), -1, 0, (nvl(dcs.NB_RECONDUCTION,0)- dcs.RECONDUCTION_NUM)*12)) > sysdate
  and pha.type_lookup_code = 'CONTRACT'
  and dcs.reconduction_num < dcs.NB_RECONDUCTION;
   
  
  CURSOR cur_sstr_reapprov (p_header_id IN NUMBER) IS
  SELECT
      hps.name UO,
      pha.segment1 NUM_CONTRAT,
      aps.segment1 NUM_FOURNISSEUR,
      substr(TRANSLATE(
        regexp_replace(dcsa.DESCRIPTION_SPECIFIQUE_CONTRAT, '[^a-zA-Z0-9 éèêëàâäùûüôöîïçœ€.,;:!?()\]', ''),
            'ÁÀÂÄáàâäÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖóòôöÚÙÛÜúùûüÇç',
            'AAAAaaaaEEEEeeeeIIIIiiiiOOOOooooUUUUuuuuCc'
        ),1,110)  DESCRIPTION,
      substr(TRANSLATE(
        regexp_replace(dcsa.REF_CONTRAT_FOURNISSEUR, '[^a-zA-Z0-9 éèêëàâäùûüôöîïçœ€.,;:!?()\]', ''),
            'ÁÀÂÄáàâäÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖóòôöÚÙÛÜúùûüÇç',
            'AAAAaaaaEEEEeeeeIIIIiiiiOOOOooooUUUUuuuuCc'
        ),1,128) REF_CONTRAT_FRS,  
      pha.ATTRIBUTE5 NATURE_PRESTATION,
      dcsa.NB_INTERVENTION NB_INTERVENTION_PERIODE,
      to_char(pha.START_DATE , 'DD/MM/YYYY') DATE_DEBUT_PERIODE,
      to_char(pha.END_DATE , 'DD/MM/YYYY') DATE_FIN_PERIODE,
      to_char(decode(php.Revision_Num, 0, php.start_date, Ref_start_date.start_date), 'DD/MM/YYYY') AS DATE_DEBUT_GLOBALE,
      to_char(add_months(php.end_date, decode(sign(nvl(dcs.NB_RECONDUCTION,0)- dcs.RECONDUCTION_NUM), -1, 0, (nvl(dcs.NB_RECONDUCTION,0)- dcs.RECONDUCTION_NUM)*12)), 'DD/MM/YYYY') AS DATE_FIN_GLOBALE,
      ROUND(MONTHS_BETWEEN(TRUNC(php.END_DATE),TRUNC (php.START_DATE))) as DUREE_RECONDUCTION ,
      dcsa.NB_RECONDUCTION NB_RECONDUCTION_MAX,
      dcsa.RECONDUCTION_NUM,
      dcsa.PREAVIS_RESILIATION,
      per.EMPLOYEE_NUMBER GESTIONNAIRE,
      pha.BLANKET_TOTAL_AMOUNT MONTANT_PERIODE_HT,
      pha.CURRENCY_CODE DEVISE,
      decode(pha.ATTRIBUTE13 , 'NON' , 'N' , 'Y') PAIEMENT_DIRECT,
      (
      SELECT segment1
      from PO_headers_all pp
      where pp.PO_HEADER_ID = dcsa.COMMANDE_ID
      ) NUM_COMMANDE_SSTR ,
    pap.segment1 NUM_PROJET
      
    FROM dka_contrat_sstr dcs,
    dka_contrat_sstr_archi dcsa,
  PA_PROJECTS_ALL pap,
    po_headers_all php,
    (select * from po_headers_archive_all phaa
      where phaa.revision_num = 
       (select max(revision_num) 
        from po_headers_archive_all
        where po_header_id = phaa.po_header_id)) pha,
    
    (select * from DKA_CONTRAT_SSTR_IMPUTATION dcss
         where dcss.CONTRAT_IMPUTATION_ID =
          (select max(CONTRAT_IMPUTATION_ID) 
        from DKA_CONTRAT_SSTR_IMPUTATION
        where po_header_id = dcss.po_header_id
        and UNITE_OEUVRE != 0)) dcsi ,
    
    hr_operating_units hps,
    ap_suppliers aps,
    per_people_v7 per,
    (select phaa.po_header_id, phaa.start_date 
      from po_headers_archive_all phaa
      where phaa.revision_num = (select max(dcsa1.revision_num) from dka_contrat_sstr_archi dcsa1
             where dcsa1.reconduction_num = 0
             and dcsa1.po_header_id = phaa.po_header_id)) Ref_start_date
               
    where dcsa.po_header_id = pha.po_header_id
    and hps.organization_id = dcsa.org_id
    and pha.vendor_id = aps.vendor_id
    and php.type_lookup_code = 'CONTRACT'
    AND php.closed_date IS NULL
    AND (php.closed_date IS NULL OR TRUNC(php.closed_date) > TRUNC(php.end_date))
  --  AND dcsa.reconduction_num < dcsa.NB_RECONDUCTION
    
    and dcsa.po_header_id = dcs.po_header_id
    and dcs.commande_id is null
    
    and php.po_header_id = dcs.po_header_id
    
    and dcsa.revision_num = (select max(dcsa1.revision_num)
            from dka_contrat_sstr_archi dcsa1
             where dcsa1.po_header_id = pha.po_header_id)
   
    and Ref_start_date.po_header_id  = pha.PO_HEADER_ID
    AND per.person_id =  dcsa.SIGNATAIRE_CONTRAT
  and pha.po_header_id = dcsi.po_header_id
  and dcsi.PROJECT_ID = pap.PROJECT_ID
    
    and pha.po_header_id = p_header_id;


  BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début init');

        ----------------------------------
        -- Initialisation des variables --
        ----------------------------------
        p_errbuf  := NULL;
        p_retcode := 0;
        v_current_program_unit := 'INIT';
    
    --Recuperation du nombre de reconduction max
    l_param := 'NB_RECONDUCTION_MAX';
    Dka_Tools_Pkg.get_parameter('SPORES_CONTRAT',
                  'NB_RECONDUCTION_MAX',
                  rec_param,
                  p_errbuf,
                  p_retcode);
    gn_nbre_reconduction := rec_param.number_value;
    
    log_msg('Nombre de reconduction maximum : ' || gn_nbre_reconduction);
  
    IF p_retcode != 0 THEN
      RAISE e_err_param;
    END IF;

    -- directories
        dka_tools_pkg.check_directory(cv_directory);

        ------------------------
        -- Variables globales --
        ------------------------ 

        g_user_id                      := fnd_global.user_id;
        g_login_id                     := fnd_global.login_id;
        g_request_id                   := fnd_global.conc_request_id;

      log_msg(' 000 : Initialisation du nom du fichier / nombre enregistrements.');
          filename     := 'DSP01_CTR_REPRISE_SSTR_' || TO_CHAR(SYSDATE, 'YYYYMMDDHHMMSS') || '.csv';
          Pv_file_name := filename;
      vn_nb_line   := 0;


    log_msg(' 001 : Ouverture du fichier ' || filename || ' en mode écriture.');
        fileHandler := utl_file.fopen(cv_directory, filename, 'w');


        log_msg(' 003 : Création de l''entéte du fichier.');
        utl_file.put_line(fileHandler, 'UO|NUM_CONTRAT|NUM_FOURNISSEUR|DESCRIPTION|REF_CONTRAT_FRS|NATURE_PRESTATION|NB_INTERVENTION_PERIODE|DATE_DEBUT_PERIODE|DATE_FIN_PERIODE|DATE_DEBUT_GLOBALE|DATE_FIN_GLOBALE|DUREE_RECONDUCTION|NB_RECONDUCTION_MAX|RECONDUCTION_NUM|PREAVIS_RESILIATION|GESTIONNAIRE|MONTANT_PERIODE_HT|DEVISE|PAIEMENT_DIRECT|NUM_COMMANDE_SSTR|NUM_PROJET');
    
    
    FOR rec_sstr_app in cur_sstr_approv LOOP
    
      FOR rec_sstr_1 in cur_sstr_1(rec_sstr_app.po_header_id) LOOP

      log_msg('NUM_CONTRAT :  ' || rec_sstr_1.NUM_CONTRAT);

      
      lv_csv_line := rec_sstr_1.UO || '|' || --UO
             rec_sstr_1.NUM_CONTRAT || '|' || --NUM_CONTRAT
             rec_sstr_1.NUM_FOURNISSEUR || '|' || --NUM_FOURNISSEUR
             rec_sstr_1.DESCRIPTION || '|' || --DESCRIPTION
             rec_sstr_1.REF_CONTRAT_FRS || '|' || --REF_CONTRAT_FRS
             rec_sstr_1.NATURE_PRESTATION || '|' || --NATURE_PRESTATION
             rec_sstr_1.NB_INTERVENTION_PERIODE || '|' || --NB_INTERVENTION_PERIODE
             rec_sstr_1.DATE_DEBUT_PERIODE || '|' || --DATE_DEBUT_PERIODE
             rec_sstr_1.DATE_FIN_PERIODE || '|' || --DATE_FIN_PERIODE.
             rec_sstr_1.DATE_DEBUT_GLOBALE || '|' || --DATE_DEBUT_GLOBALE
             rec_sstr_1.DATE_FIN_GLOBALE || '|' || --DATE_FIN_GLOBALE
             rec_sstr_1.DUREE_RECONDUCTION || '|' || --DUREE_RECONDUCTION
             rec_sstr_1.NB_RECONDUCTION_MAX || '|' || --NB_RECONDUCTION_MAX
             rec_sstr_1.RECONDUCTION_NUM || '|' || --RECONDUCTION_NUM
             rec_sstr_1.PREAVIS_RESILIATION || '|' || --PREAVIS_RESILIATION
             rec_sstr_1.GESTIONNAIRE || '|' || --GESTIONNAIRE
             rec_sstr_1.MONTANT_PERIODE_HT || '|' || --MONTANT_PERIODE_HT
             rec_sstr_1.DEVISE || '|' || --DEVISE
             rec_sstr_1.PAIEMENT_DIRECT || '|' || --PAIEMENT_DIRECT
             rec_sstr_1.NUM_COMMANDE_SSTR || '|' || --NUM_COMMANDE_SSTR
       rec_sstr_1.NUM_PROJET ; --NUM_PROJET

         utl_file.put_line(fileHandler, lv_csv_line);

         vn_nb_line   := vn_nb_line + 1;

      END LOOP;
      
    END LOOP;
    
    --2nd loop
    FOR rec_sstr_2 in cur_sstr_reapp LOOP
      
      FOR rec_reapprov in cur_sstr_reapprov(rec_sstr_2.po_header_id) LOOP
      
      log_msg('rec_sstr_2.po_header_id :  ' || rec_sstr_2.po_header_id);
      log_msg('NUM_CONTRAT :  ' || rec_reapprov.NUM_CONTRAT);
      
      lv_csv_line := rec_reapprov.UO || '|' || --UO
           rec_reapprov.NUM_CONTRAT || '|' || --NUM_CONTRAT
           rec_reapprov.NUM_FOURNISSEUR || '|' || --NUM_FOURNISSEUR
           rec_reapprov.DESCRIPTION || '|' || --DESCRIPTION
           rec_reapprov.REF_CONTRAT_FRS || '|' || --REF_CONTRAT_FRS
           rec_reapprov.NATURE_PRESTATION || '|' || --NATURE_PRESTATION
           rec_reapprov.NB_INTERVENTION_PERIODE || '|' || --NB_INTERVENTION_PERIODE
           rec_reapprov.DATE_DEBUT_PERIODE || '|' || --DATE_DEBUT_PERIODE
           rec_reapprov.DATE_FIN_PERIODE || '|' || --DATE_FIN_PERIODE.
           rec_reapprov.DATE_DEBUT_GLOBALE || '|' || --DATE_DEBUT_GLOBALE
           rec_reapprov.DATE_FIN_GLOBALE || '|' || --DATE_FIN_GLOBALE
           rec_reapprov.DUREE_RECONDUCTION || '|' || --DUREE_RECONDUCTION
           rec_reapprov.NB_RECONDUCTION_MAX || '|' || --NB_RECONDUCTION_MAX
           rec_reapprov.RECONDUCTION_NUM || '|' || --RECONDUCTION_NUM
           rec_reapprov.PREAVIS_RESILIATION || '|' || --PREAVIS_RESILIATION
           rec_reapprov.GESTIONNAIRE || '|' || --GESTIONNAIRE
           rec_reapprov.MONTANT_PERIODE_HT || '|' || --MONTANT_PERIODE_HT
           rec_reapprov.DEVISE || '|' || --DEVISE
           rec_reapprov.PAIEMENT_DIRECT || '|' || --PAIEMENT_DIRECT
           rec_reapprov.NUM_COMMANDE_SSTR || '|' || --NUM_COMMANDE_SSTR
       rec_reapprov.NUM_PROJET ; --NUM_PROJET

       utl_file.put_line(fileHandler, lv_csv_line);

           vn_nb_line   := vn_nb_line + 1;
      
      END LOOP;
    
    END LOOP;
    
    
    log_msg(' 005 : nb lignes extraites : ' || vn_nb_line);
        IF vn_nb_line = 0 THEN
            utl_file.fclose(fileHandler); 
        END IF;
        log_msg(' 005 : Fermeture du fichier.');
        IF utl_file.is_open(fileHandler) THEN
      utl_file.fclose(fileHandler); 
    END IF;
        log_msg(' 999 : Fin Normale.');
    EXCEPTION
        WHEN program_error THEN
             fnd_file.put_line(fnd_file.log, 'ERREUR : ' || v_step_program_error);
             RAISE; 
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'INIT : ' ||SQLERRM;
  END init;

    -----------------------------------------------------------------
  --  Nom           : Main
  --  Description   : procédure principale du traitement
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER

  -----------------------------------------------------------------
PROCEDURE main(Pv_Errbuf    IN OUT VARCHAR2,
                   Pn_Retcode   IN OUT NUMBER
                   )
IS
  v_errbuf                    VARCHAR2(2500);
  v_retcode                   NUMBER;
  Erreur_Programme            EXCEPTION;
  Erreur_mail                 EXCEPTION;
  cv_line                     VARCHAR2 (100);
  v_current_program_unit      VARCHAR2(30);
  vn_nb_line                  NUMBER;
  vv_file_name                VARCHAR2(70);
  vv_adresses           VARCHAR2(32000);
  vv_adresses_cc          VARCHAR2(32000);
  vt_adr_to     liste_destinataires;
    vt_adr_cc     liste_destinataires;
    vn_cpt        NUMBER;
    vn_cptt        NUMBER;
    rec_param dka_parameters%ROWTYPE;

BEGIN


      Output_Header;


    init (v_errbuf,v_retcode,vv_file_name);
    IF v_retcode = 2 
      THEN
          Pv_Errbuf  := v_errbuf;
          Pn_Retcode := v_retcode;
      Fnd_File.put_line (Fnd_File.OUTPUT, 'ECHEC : Le fichier n''a pas pu être généré.'); 
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10) || 'Voir le journal du traitement pour avoir plus de détail sur l''anomalie rencontrée.');
      RAISE Erreur_Programme;
      END IF;

      log_msg('Nom Fichier généré : ' || vv_file_name);
    
    out_msg('Date de dernière exécution de l''export  : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    out_msg('');
    
    out_msg('Nom du fichier généré : ' || vv_file_name);
    out_msg('');
    
    IF v_retcode = 2 
      THEN
      Fnd_File.put_line (Fnd_File.OUTPUT, 'Fin anormale du traitement : Le fichier n''a pas pu être généré.'); 
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10) || 'Voir le journal du traitement pour avoir plus de détail sur l''anomalie rencontrée.');
      out_msg('');
    ELSE
      Fnd_File.put_line (Fnd_File.OUTPUT, 'Fin normale du traitement.'); 
      out_msg('');
      END IF;
       
      output_end;
    EXCEPTION
    WHEN Erreur_Programme THEN
      Pn_Retcode   := 2;
      Pv_Errbuf    := v_errbuf;
      Fnd_File.put_line (Fnd_File.LOG, Pv_Errbuf);
      Fnd_File.put_line (Fnd_File.LOG, CHR(10)||Pv_Errbuf);
      output_end;
END main;

END DKA_SPOSSTR_EXT_PKG;

/
SHOW ERRORS;
EXIT