create or replace PACKAGE BODY       XXEAI_INTERFACE_TOOLS_PKG AS
     ----------------------------------------------------------------------------------------------
     -- $ $
     --
     -- NOM               : XXEAI_INTERFACE_TOOLS_PKG.pkb
     -- DESCRIPTION       : XXEAI_INTERFACE_TOOLS_PKG package body : fonctions communes aux interface EAI
     ---
     --- AUTEUR           : Julien Jardez
     --- DATE DE CREATION : 19/05/2014
     --- DOC. ASSOCIEE    :497
     ---
     ----------------------------------------------------------------------------------------------
     --- NOM DU PROGRAMME :
     --- PARAMETRES       :
     ---
     --- HISTORIQUE DES MODIFICATIONS
     --- Date       Qui Description
     --- ---------- --- -------------------------------------------------------------------------
     --- 12/08/2014 BCO DGE20140007 - Ajout des outils d'interface pour GL
     --- 08/09/2014 BCO Evolution de l'appel de fonction Banque pour l'EAI
     --- 09/01/2015 BCO DPE20140114 - Trésorerie lot 2 - CAMT054 - Impayes Prélevements clients.
     --- 12/01/2015 TBO Modifications 002.3.8 et 002.4.11 suite recette fonctions GL
     --- 22/01/2015 BCO DPE20150006 - Outils d?interface AP pour l?EAI ? Problématiques de TVA
     --- 11/02/2015 BCO Modifications de la recherche de la région dans la procédure Get_Info_Invoice_Line
     --- 25/03/2015 BCO DPE20150018 - Trésorerie(Diapason) pour Get_Cle_Comptable_CUF
     --- 25/03/2015 BCO DPE20150024 - Interdire les cas de refacturation si le type de piece est a contrepassation automatique.
     --- 26/03/2015 BCO DPE20150029 - Nouvelles regles de gestion pour la détermination du centre de gestion application DIAPASON.
     --- 08/04/2015 BCO DPE20150031 ? Gestion de la région pour le compte 585000 des écritures venant de DIAPASON
     --- 10/04/2015 BCO DPE20150037 - Gestion du code partenaire pour le flux DIAPASON
     --- 13/04/2015 BCO DPE20150036 - Outils EAI AP - Modification RG détermination du Site pour les Fournisseurs Intra Groupe
     --- 20/07/2015 BCO DPE20150054 - Gestion de la TVA pour les nouvelles interfaces.
     --- 22/02/2016 JWYC MTIA DPE20160006 OGE6766 - Gestion TVA pour ECO -  PRELUDE.
     --- 12/08/2016 JWYC TASK0016084 Correctif fonction get_info_invoice_header
     --- 19/09/2016 HDE Modification pour HELIOS
     --- 08/12/2016 OBE Modification artf2061645
     --- 29/12/2016 MEG Modification artf2071034
     --- 23/01/2017 YWA Modification artf2085619
     --- 02/02/2017 YWA Modification artf2093557 Get_Cle_Comptable_CUF
     --- 08/02/2017 RBE Modification artf2097270 Get_Info_Invoice_Line
     --- 13/02/2017 OBE Modification artf2100412 / artf2100408
     --- 17/05/2017 YWA Modification artf2156152
     --- 29/05/2017 OBE - artf2159071 : SPE182 - Get_Info_Invoice_Header et Get_Info_Invoice_Line problème REFAC - Defect Bout_en_Bout_Helios_Ref #697/699
     ---                - artf2158877 : SPE182 - Get_Cle_Comptable_CUF Segment6 et compte de bilan - Defect Bout_En_Bout_Helios_Ref #692
     --- 13/06/2017 OBE - artf2171905 : SPE182 - Get_Cle_Comptable_CUF - Erreur sur projet REFAC -Defect Bout_en_Bout_Helios_Ref #775
     ---                - EDB075 Mapping SEGMENT8 et règle de validation croisée
     --- 27/06/2017 JJA - artf2182117 : SPE182 - EDB079 - Ajout région Get_Info_Invoice_Lines pour gérer la refacturation
     --- 18/07/2017 OBE artf2194552 : SPE182 - EDB081 - Gestions des écritures de trésorerie
     --- 26/07/2017 ADE artf2202194 : SPE182 - compte de bilan rectification paramètre obligatoire
     --- 31/07/2017 YWA artf2204539 : SPE182 - inversion code banque et code BIC (swift_code) - Defect Beb #855
     --- 03/08/2017 YWA artf2206549 : SPE182 - Get_Cle_Comptable_CUF - contrôles paramètres Région et Tâches - defect BeB #900
     --- 29/08/2017 YWA artf2215513 : SPE182 - Gestion des écritures de paie_Context MAT et ATTRIBUTE11 - EDB083
     --- 30/08/2017 YWA artf2216107 : SPE182 - Get_Info_Invoice_Line_Organisation de la dépense KO dans le cas REFAC - Defect Beb #1063
     --- 12/09/2017 OBE artf2222144 : SPE182 - Outils d'interface pour l'EAI - lié à modif sur SPE048 pour defect ORACLE_R12 #920
     --- 14/09/2017 OBE artf2221959 : SPE182 - SEGMENT7 retour arrière - Defect Beb 1088
     --- 05/10/2017 OBE artf2237928 : SPE182 - Rattrapage contrepassation 11i - Defect Beb #1108
     --- 07/02/2018 JJA artf2361312 : SPE182 - Correction Trésorerie Infos banques
     --- 13/03/2018 OBE artf2408078 : DPE20180009 EDB093_SPE182_Code taxe pour les tâches investissement
     --- 19/03/2018 OBE artf2408081 : DPE20180010 EDB097_SPE182_Gestion des Périodes FUTURES
     --- 27/03/2018 OBE artf2470550 : SPE182 - Correction code erreur Get_type_num_ligne_mvt_AR
   --- 04/02/2019 SFA artf3063732 : INC0283997 - Campagne règlement - IBAN sur plusieurs fournisseurs
   --- 05/08/2019 SEL artf07290731 : INC0283997 - Campagne règlement - IBAN sur plusieurs fournisseurs
   --- 17/09/2019 SFA artf07308610 :  INC0347680 - SPE182 - Interface EAI - Ajout des préfixes APPS
   --- 10/02/2021 NBO artf07438559 : INC0508700 - traitement de ces écritures par la PFE a duré plus de 3 heures
   --- 01/10/2021 ARA EDB290  DPE20210007 - Virements fournisseurs - Retirer le contrôle sur les banques et agences fermés
   --- 02/11/2023 ARA EDB281 - DGE20210006 - Alimentation du segment5 de la clé comptable
     --------------------------------------------------------------------------------------------

     -----------------------------------------------------------------
     --  Variables globales
     -----------------------------------------------------------------
     gv_step        VARCHAR2(500);
     rec_param      DKA.DKA_PARAMETERS%ROWTYPE;
     gv_errbuf      VARCHAR2(1000);
     gn_retcode     NUMBER;

     -----------------------------------------------------------------
     --  Exceptions
     -----------------------------------------------------------------
     e_main EXCEPTION;


     -----------------------------------------------------------------
     --  Curseurs
     -----------------------------------------------------------------
     cursor cur_flex_value(p_flex_value_set_name in varchar2, p_flex_value in varchar2) is
     SELECT FFV.FLEX_VALUE_SET_ID, FFV.FLEX_VALUE_ID, FFV.FLEX_VALUE, FFV.FLEX_VALUE_MEANING, FFV.DESCRIPTION,
            FFV.ENABLED_FLAG, FFV.START_DATE_ACTIVE, FFV.END_DATE_ACTIVE, FFV.SUMMARY_FLAG, FFV.VALUE_CATEGORY,
            FFV.STRUCTURED_HIERARCHY_LEVEL, FFV.HIERARCHY_LEVEL, FFV.PARENT_FLEX_VALUE_HIGH, FFV.PARENT_FLEX_VALUE_LOW,
            FFVD.*
     FROM APPS.FND_FLEX_VALUE_SETS       FFVS
     JOIN APPS.FND_FLEX_VALUES_VL        FFV  on (FFV.FLEX_VALUE_SET_ID = FFVS.FLEX_VALUE_SET_ID)
     JOIN APPS.FND_FLEX_VALUES_DFV       FFVD on (FFV.row_id = FFVD.row_id)
     WHERE 1=1
       AND FFV.FLEX_VALUE = p_flex_value
       AND FFVS.FLEX_VALUE_SET_NAME = p_flex_value_set_name
       AND (FFV.VALUE_CATEGORY = FFVS.FLEX_VALUE_SET_NAME or FFV.VALUE_CATEGORY is null)
       AND FFV.ENABLED_FLAG = 'Y'
       AND (FFV.START_DATE_ACTIVE <= SYSDATE OR FFV.START_DATE_ACTIVE IS NULL)
       AND (FFV.END_DATE_ACTIVE >= SYSDATE OR FFV.END_DATE_ACTIVE IS NULL);

     -----------------------------------------------------------------
     --  Nom           : PUT_DEBUG_MESSAGE
     --  Description   : Procédure insérant un message dans la sortie standard
     --                  si on est en mode debug
     --
     --  PARAMETRES :
     --     pv_message   Entrée      Message a insérer
     --
     --  VALEUR RETOURNEE :
     --     N/A
     -----------------------------------------------------------------
     PROCEDURE put_debug_message(pv_message VARCHAR2) IS
     BEGIN
          IF gv_debug_mode = 'Y' THEN
               --Affichage dans la sortie Standard
               DBMS_OUTPUT.PUT_LINE(SUBSTR(pv_message, 1, 255));
          END IF;
     END put_debug_message;

     -----------------------------------------------------------------
     procedure validate(p_condition in boolean, p_code_erreur in out nocopy varchar2, p_erreur in varchar2, p_message in varchar2 default null) is
     begin
       if not p_condition then
         if p_message is not null then
           put_debug_message(p_message);
         end if;
         p_code_erreur := p_erreur;
         raise e_main;
       end if;
     end validate;

     -----------------------------------------------------------------
     procedure not_null(p_param_name in varchar2, p_param_value in varchar2, p_code_erreur in out nocopy varchar2) is
     begin
       validate(p_param_value is not null, p_code_erreur, 'OAE021', 'Le parametre obligatoire ' || p_param_name || ' n''est pas renseigné.');
     end not_null;

     -----------------------------------------------------------------
     function get_project(p_project_code in APPS.PA_PROJECTS.SEGMENT1%TYPE) return APPS.PA_PROJECTS%ROWTYPE RESULT_CACHE is
       v_result APPS.PA_PROJECTS%ROWTYPE;
     begin
        select * into v_result from APPS.PA_PROJECTS_ALL where segment1 = p_project_code and project_status_code != 'CLOSED';
        return v_result;
     exception
       when others then
         return null;
     end get_project;

     -----------------------------------------------------------------
     function get_project(p_project_id in APPS.PA_PROJECTS.PROJECT_ID%TYPE) return APPS.PA_PROJECTS%ROWTYPE RESULT_CACHE is
       v_result APPS.PA_PROJECTS%ROWTYPE;
     begin
        select * into v_result from APPS.PA_PROJECTS_ALL where project_id = p_project_id and project_status_code != 'CLOSED';
        return v_result;
     exception
       when others then
         return null;
     end get_project;

     -----------------------------------------------------------------
     function get_task(p_task_number in APPS.PA_TASKS.TASK_NUMBER%TYPE) return APPS.PA_TASKS%ROWTYPE RESULT_CACHE is
       v_result APPS.PA_TASKS%ROWTYPE;
     begin
        select * into v_result from APPS.PA_TASKS where task_number = p_task_number;
        return v_result;
     exception
       when others then
         return null;
     end get_task;

     -----------------------------------------------------------------
     function get_task(p_project_id in APPS.PA_PROJECTS.PROJECT_ID%TYPE, p_task_number in APPS.PA_TASKS.TASK_NUMBER%TYPE) return APPS.PA_TASKS%ROWTYPE RESULT_CACHE is
       v_result APPS.PA_TASKS%ROWTYPE;
     begin
        select * into v_result from APPS.PA_TASKS where task_number = p_task_number and project_id = p_project_id;
        return v_result;
     exception
       when others then
         return null;
     end get_task;

     -----------------------------------------------------------------
     function get_class_affaire(p_project_id in APPS.PA_PROJECTS.PROJECT_ID%TYPE) return PA.PA_PROJECT_CLASSES%ROWTYPE RESULT_CACHE is
       v_result PA.PA_PROJECT_CLASSES%ROWTYPE;
     begin
        select * into v_result from PA.PA_PROJECT_CLASSES where project_id = p_project_id and class_category = 'AFFAIRE';
        return v_result;
     exception
       when others then
         return null;
     end get_class_affaire;

     -----------------------------------------------------------------
     function period_is_open(p_ledger_id in apps.gl_ledgers.ledger_id%type, p_gl_date in date) return boolean RESULT_CACHE is
       vn_verif_datecmpt number;
     begin
        SELECT count(1)
        INTO vn_verif_datecmpt
        FROM GL.gl_period_statuses
        WHERE application_id = 101
        AND set_of_books_id = p_ledger_id
        --AND closing_status = 'O'
    AND closing_status in ('O','F') -- OBE artf2408081
        AND adjustment_period_flag = 'N'
        AND nvl(p_gl_date, SYSDATE) BETWEEN nvl(start_date, SYSDATE) AND nvl(end_date, SYSDATE+1);

        return vn_verif_datecmpt > 0;
     exception
       when others then return false;
     end period_is_open;

     -----------------------------------------------------------------
     function is_numeric(p_value in varchar2) return boolean is
       v_num number;
     begin
       v_num := to_number(p_value);          -- attention : séparateur décimal = .
       return true;
     exception
       when value_error then return false;
     end is_numeric;

     -----------------------------------------------------------------
     function get_flex_value(p_flex_value_set_name in varchar2, p_flex_value in varchar2) return cur_flex_value%rowtype RESULT_CACHE
     is
       l_result cur_flex_value%rowtype;
     begin
       open cur_flex_value(p_flex_value_set_name, p_flex_value);
       fetch cur_flex_value into l_result;
       close cur_flex_value;
       return l_result;
     end get_flex_value;

     -----------------------------------------------------------------
     function get_task_number(p_region in varchar2, p_societe in varchar2) return APPS.PA_TASKS.TASK_NUMBER%TYPE is
       vv_task APPS.PA_TASKS.TASK_NUMBER%TYPE;
     begin

       select pt.task_number
         into vv_task
         from APPS.PA_TASKS pt
        where pt.task_number =
              (select haou.attribute12
                from hr_all_organization_units haou
                where haou.name = p_region || p_societe);

       return vv_task;

     exception
       when others then
         return null;
     end get_task_number;

     -----------------------------------------------------------------
     function check_segment_value(
       p_ledger_id     in APPS.GL_LEDGERS.ledger_id%type,
       p_segment_name  in APPS.FND_ID_FLEX_SEGMENTS.segment_name%type,
       p_value         in APPS.FND_FLEX_VALUES.flex_value%type) return boolean
     is
       cursor cur_seg_info(p_ledger_id in APPS.GL_LEDGERS.ledger_id%type, p_segment_name in APPS.FND_ID_FLEX_SEGMENTS.segment_name%type) is
       select application_id, id_flex_code, id_flex_num, application_column_name, segment_name, segment_num, enabled_flag, required_flag, display_flag, display_size,
       ffvs.flex_value_set_id, flex_value_set_name, validation_type, format_type, maximum_size
       from APPS.GL_LEDGERS           GL
       join APPS.FND_ID_FLEX_SEGMENTS FIFS on (FIFS.application_id = 101 and FIFS.id_flex_code = 'GL#' and FIFS.id_flex_num = GL.chart_of_accounts_id)
       join APPS.FND_FLEX_VALUE_SETS  FFVS on (FIFS.flex_value_set_id = FFVS.flex_value_set_id)
       where GL.ledger_id  = p_ledger_id
         and segment_name  = p_segment_name;
       v_segment_info cur_seg_info%rowtype;

       cursor cur_value_info(p_value_set_id in APPS.FND_FLEX_VALUES.flex_value_set_id%type, p_value in APPS.FND_FLEX_VALUES.flex_value%type) is
       select *
       from APPS.FND_FLEX_VALUES
       where flex_value_set_id = p_value_set_id
         and flex_value        = p_value;
       v_value_info cur_value_info%rowtype;
     begin
       open cur_seg_info(p_ledger_id, p_segment_name);
       fetch cur_seg_info into v_segment_info;
       if cur_seg_info%NOTFOUND then
         close cur_seg_info;
         put_debug_message('check_segment_value : ledger_id ou segment_name inexistant : ' || p_ledger_id || ', ' || p_segment_name);
         return false;
       end if;
       close cur_seg_info;

       if v_segment_info.validation_type != 'I' then
         put_debug_message('check_segment_value : seuls les jeux de valeurs indépendants sont pris en charge : ' || v_segment_info.flex_value_set_name);
         return false;
      end if;

      open cur_value_info(v_segment_info.flex_value_set_id, p_value);
      fetch cur_value_info into v_value_info;
      if cur_value_info%NOTFOUND then
         close cur_value_info;
         put_debug_message('check_segment_value : valeur inexistante pour le segment '|| p_segment_name || ' : ' || p_value);
         return false;
      elsif v_value_info.enabled_flag != 'Y' or not (sysdate between nvl(v_value_info.start_date_active, sysdate) and nvl(v_value_info.end_date_active, sysdate+1)) then
         close cur_value_info;
         put_debug_message('check_segment_value : valeur inactive pour le segment '|| p_segment_name || ' : ' || p_value);
         return false;
      end if;
      close cur_value_info;
      return true;
      end check_segment_value;

      -----------------------------------------------------------------
      function get_code_combination_id (
        pv_segment1              IN       VARCHAR2,
        pv_segment2              IN       VARCHAR2,
        pv_segment3              IN       VARCHAR2,
        pv_segment4              IN       VARCHAR2,
        pv_segment5              IN       VARCHAR2 default '0',
        pv_segment6              IN       VARCHAR2 default '0',
        pv_segment7              IN       VARCHAR2 default '0',
        pv_segment8              IN       VARCHAR2 default '0',
        pv_segment9              IN       VARCHAR2 default '0',
        pv_segment10             IN       VARCHAR2 default '0',
        pv_segment11             IN       VARCHAR2 default '0',
        pv_segment12             IN       VARCHAR2 default '0') return gl_code_combinations.code_combination_id%TYPE
      is
         lv_current_program_unit CONSTANT VARCHAR2(30) := 'get_code_combination_id';
         l_result                   gl_code_combinations.code_combination_id%TYPE;
         l_ledger_id                number;
         l_chart_of_accounts_id     number;
         l_segments                 APPS.Fnd_Flex_Ext.SegmentArray;
      begin
        put_debug_message(lv_current_program_unit || ' 001 : Recherche livre de la société : ' || pv_segment1);
        l_ledger_id := APPS.DKA_GL_TOOLS_PKG.get_legder_id(pv_segment1);
        if l_ledger_id is null then
          return null;
        end if;
        put_debug_message(lv_current_program_unit || ' 002 : Recherche plan de comptes : ' || l_ledger_id);
        select chart_of_accounts_id into l_chart_of_accounts_id from APPS.gl_ledgers where ledger_id = l_ledger_id;

        put_debug_message(lv_current_program_unit || ' 002 : Recherche combinaison de comptes : ' || l_chart_of_accounts_id);
        l_segments (1)        := pv_segment1;
        l_segments (2)        := pv_segment2;
        l_segments (3)        := pv_segment3;
        l_segments (4)        := pv_segment4;
        l_segments (5)        := pv_segment5;
        l_segments (6)        := pv_segment6;
        l_segments (7)        := pv_segment7;
        l_segments (8)        := pv_segment8;
        l_segments (9)        := pv_segment9;
        l_segments (10)       := pv_segment10;
        l_segments (11)       := pv_segment11;
        l_segments (12)       := pv_segment12;


		if APPS.Fnd_Flex_Ext.get_combination_id (
          application_short_name  => 'SQLGL',
          key_flex_code           => 'GL#',
          structure_number        => l_chart_of_accounts_id,
          validation_date         => sysdate,
          n_segments              => l_segments.COUNT,
          segments                => l_segments,
          combination_id          => l_result) then
          put_debug_message(lv_current_program_unit || ' 999 : FIN : ' || l_result);
          return l_result;
        else
          put_debug_message(lv_current_program_unit || ' 999 : ERREUR : ' || APPS.Fnd_Flex_Ext.get_message());
          return null;
        end if;
      exception
        when others then
          put_debug_message(lv_current_program_unit || ' 999 : ERREUR : ' || SQLERRM);
          return null;
      end get_code_combination_id;

      -----------------------------------------------------------------
      function is_currency(p_code in varchar2) return boolean RESULT_CACHE
      is
        vn_result number;
      begin
        select 1 into vn_result
        from APPS.FND_CURRENCIES
        where CURRENCY_CODE = p_code
          and ENABLED_FLAG = 'Y'
          and sysdate between nvl(START_DATE_ACTIVE, sysdate) and nvl(END_DATE_ACTIVE, sysdate+1);
        return true;
      exception
        when no_data_found then return false;
      end is_currency;

      -----------------------------------------------------------------
      function is_autoreverse(p_user_je_category_name in varchar2) return boolean RESULT_CACHE
      is
        vn_result number;
      begin

        SELECT 1
          INTO vn_result
          FROM GL.GL_AUTOREV_CRITERIA_SETS gacs, APPS.GL_AUTOREVERSE_OPTIONS_V gao
         WHERE gacs.criteria_set_id = gao.criteria_set_id
           AND gacs.criteria_set_name = 'DALKIA'
           AND gao.autoreverse_flag = 'Y'
           AND gao.user_je_category_name = p_user_je_category_name;

        return true;
      exception
        when no_data_found then return false;
      end is_autoreverse;

      -----------------------------------------------------------------
      function tax_code_exists(p_tax_rate_code in APPS.ZX_RATES_B.tax_rate_code%type,
                             p_tax_rate      in APPS.ZX_RATES_B.percentage_rate%type) -- RBE artf2097270
      return boolean RESULT_CACHE
      is
        l_result number;
      begin
        select 1 into l_result
        from APPS.ZX_RATES_B
        where nvl(tax_jurisdiction_code,'FR_JURIDICTION') = 'FR_JURIDICTION'
          and tax_rate_code = p_tax_rate_code
          and percentage_rate      = p_tax_rate -- RBE artf2097270
          and sysdate between nvl(EFFECTIVE_FROM,sysdate) and nvl(EFFECTIVE_TO,sysdate+1)
          and ACTIVE_FLAG='Y';
        return true;
      exception
        when no_data_found then
          return false;
      end tax_code_exists;

      -----------------------------------------------------------------
      function my_get_params_folio_ap(pv_FOLIO in varchar2) return cur_flex_value%ROWTYPE
      is
      begin
        return get_flex_value('DKA_PARAM_FOLIO_AP', pv_FOLIO);
      end my_get_params_folio_ap;


     -----------------------------------------------------------------
     -- FONCTIONNALITÉ 1 : INFORMATIONS BANCAIRE EN FONCTION DE L'IBAN
     --  Nom           : Get_Infos_Banque
     --  Description   : Fonction qui retourne dans un objet XXEAI_INFOS_BANQUE_OBJ
     --                  les informations de la banque
     --
     --  PARAMETRES :
     --     pv_IBAN          Entrée      IBAN
     --     po_infos_banque  Sortie      Objet regroupant le code banque,
     --                                  le nom de la banque et le code BIC
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Infos_Banque(pv_IBAN         IN VARCHAR2,
                                po_infos_banque IN OUT NOCOPY XXEAI_INFOS_BANQUE_OBJ) IS
          lv_current_program_unit CONSTANT VARCHAR2(30) := 'Get_Infos_Banque';
          lv_pays      VARCHAR2(2);
          lv_banque    VARCHAR2(5);
          lv_agence    VARCHAR2(5);
          lv_dummy     VARCHAR2(50);

          --Infos banques
          lv_CODE_BANQUE APPS.CE_BANK_BRANCHES_V.BANK_NUMBER%TYPE;
          lv_CODE_BIC    APPS.CE_BANK_BRANCHES_V.EFT_SWIFT_CODE%TYPE;
          lv_NOM_BANQUE  APPS.CE_BANK_BRANCHES_V.BANK_NAME%TYPE;
     BEGIN
       put_debug_message(lv_current_program_unit || ' 000 : DEBUT');
       not_null('pv_IBAN', pv_IBAN, lv_dummy);

       put_debug_message(lv_current_program_unit || ' 001 : Découpage de l''IBAN');
       lv_pays := substr(pv_IBAN, 1, 2);
       IF lv_pays = 'FR' then
          lv_banque    := substr(pv_IBAN, 5, 5);
          lv_agence    := substr(pv_IBAN, 10, 5);

          select EFT_SWIFT_CODE, BANK_NUMBER, BANK_NAME
          into lv_CODE_BIC,lv_CODE_BANQUE, lv_NOM_BANQUE --YWA  artf2204539
          from APPS.CE_BANK_BRANCHES_V  BB
          --where sysdate between nvl(BB.START_DATE, sysdate) and nvl(BB.END_DATE, sysdate+1) --ARA EDB290
            where nvl(BB.COUNTRY,BB.BANK_HOME_COUNTRY) = lv_pays  --EDB290
            and BB.BANK_NUMBER   = lv_banque
            and BB.BRANCH_NUMBER = lv_agence
      and rownum = 1;  -- SEL artf07290731
       ELSE
          --artf2361312
          /*select  EFT_SWIFT_CODE, BANK_NUMBER, BANK_NAME
          into lv_CODE_BIC,lv_CODE_BANQUE, lv_NOM_BANQUE --YWA artf2204539
          from APPS.CE_BANK_ACCOUNTS     A
          join APPS.CE_BANK_BRANCHES_V   BB on (BB.BRANCH_PARTY_ID = A.BANK_BRANCH_ID)
          where 1=1
            and sysdate between nvl(A.START_DATE, sysdate) and nvl(A.END_DATE, sysdate+1)
            and sysdate between nvl(BB.START_DATE, sysdate) and nvl(BB.END_DATE, sysdate+1)
            and A.IBAN_NUMBER = pv_IBAN;*/
          BEGIN
            --Compte Externe?
            SELECT EFT_SWIFT_CODE, BANK_NUMBER, BANK_NAME
            INTO lv_CODE_BIC,lv_CODE_BANQUE, lv_NOM_BANQUE
            FROM IBY_EXT_BANK_ACCOUNTS ieba
            JOIN APPS.CE_BANK_BRANCHES_V   cbb ON (cbb.BRANCH_PARTY_ID = ieba.BRANCH_ID)
            WHERE 1 = 1
             --AND SYSDATE BETWEEN NVL(cbb.START_DATE, SYSDATE) AND NVL(cbb.END_DATE, SYSDATE+1) --ARA EDB290
             AND SYSDATE BETWEEN NVL(ieba.START_DATE, SYSDATE) AND NVL(ieba.END_DATE, SYSDATE+1)
             AND IBAN = pv_IBAN
       and rownum=1; -- SEL artf07290731

            /*//---------Ajout SFA -- pour artf3063732--------------------//*/

      -- SEL artf07290731
      /*

      IF SQL%FOUND THEN
          UPDATE IBY.IBY_EXT_BANK_ACCOUNTS
         SET END_DATE =sysdate-1
          WHERE IBAN =pv_IBAN
           AND BRANCH_ID IN (SELECT BRANCH_PARTY_ID
                             FROM APPS.CE_BANK_BRANCHES_V
                     WHERE EFT_SWIFT_CODE=lv_CODE_BIC
                       AND BANK_NUMBER=lv_CODE_BANQUE
                     AND BANK_NAME=lv_NOM_BANQUE
                            );
       COMMIT;

       END IF;
       */ -- SEL artf07290731

      /*//---------fin Ajout SFA -- pour artf3063732--------------------//*/

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              --Compte Interne?
              SELECT  EFT_SWIFT_CODE, BANK_NUMBER, BANK_NAME
              INTO lv_CODE_BIC,lv_CODE_BANQUE, lv_NOM_BANQUE --YWA artf2204539
              FROM APPS.CE_BANK_ACCOUNTS     A
              JOIN APPS.CE_BANK_BRANCHES_V   BB on (BB.BRANCH_PARTY_ID = A.BANK_BRANCH_ID)
              WHERE 1=1
                and sysdate between nvl(A.START_DATE, sysdate) and nvl(A.END_DATE, sysdate+1)
                --and sysdate between nvl(BB.START_DATE, sysdate) and nvl(BB.END_DATE, sysdate+1) --ARA EDB290
                and A.IBAN_NUMBER = pv_IBAN
        and rownum=1; -- SEL artf07290731

        /*//---------Ajout SFA -- pour artf3063732--------------------//*/
             -- SEL artf07290731
      /* IF SQL%FOUND THEN
          UPDATE CE.CE_BANK_ACCOUNTS
         SET END_DATE =sysdate-1
          WHERE IBAN_NUMBER =pv_IBAN
           AND BANK_BRANCH_ID IN (SELECT BRANCH_PARTY_ID
                             FROM APPS.CE_BANK_BRANCHES_V
                     WHERE EFT_SWIFT_CODE=lv_CODE_BIC
                       AND BANK_NUMBER=lv_CODE_BANQUE
                     AND BANK_NAME=lv_NOM_BANQUE
                            );
       COMMIT;
       END IF; -- SEL artf07290731
       */
      /*//---------fin Ajout SFA -- pour artf3063732--------------------//*/
           END;
       END IF;

       put_debug_message(lv_current_program_unit || ' 003 : Création Objet');
       po_infos_banque := XXEAI_INFOS_BANQUE_OBJ(lv_CODE_BANQUE, lv_CODE_BIC, lv_NOM_BANQUE);

       put_debug_message(lv_current_program_unit || ' 999 : FIN');
    EXCEPTION
          WHEN OTHERS THEN
           --On renvoie NULL en cas d'erreur
           po_infos_banque := NULL;
           put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Infos_Banque;



     -----------------------------------------------------------------
     -- FONCTIONNALITÉ 2 : DÉTERMINER LES VALEURS CONSTANTES DU FLUX
     --  Nom           : Get_Params_FOLIO_GL
     --  Description   : Fonction qui retourne dans un objet XXEAI_CST_FLUX_GL_OBJ
     --                  les valeurs constantes du flux pour les folio déterminé.
     --
     --  PARAMETRES :
     --     pv_FOLIO         Entrée      FOLIO
     --     po_cst_flux_gl   Sortie      Objet regroupant le code erreur, code folio oracle,
     --                  statut, id Livre Comptable, Devise, Type d?écriture,
     --                  Type de la piece et l'Origine de la piece.
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Params_FOLIO_GL(pv_FOLIO       IN VARCHAR2,
                                   po_cst_flux_gl IN OUT NOCOPY XXEAI_CST_FLUX_GL_OBJ) IS
        lv_current_program_unit CONSTANT VARCHAR2(30) := 'Get_Params_FOLIO_GL';
        vv_code_erreur          VARCHAR2(50);

        vv_folio_oa         VARCHAR2(4);
        vv_status           VARCHAR2(50);
        vv_currency_code    VARCHAR2(15);
        vv_actual_flag      VARCHAR2(1);
        vv_category_name    VARCHAR2(25);
        vv_source_name      VARCHAR2(25);
        vv_application_name VARCHAR2(255);

        error_no_data EXCEPTION;
     BEGIN
        put_debug_message(lv_current_program_unit || ' 000 : Début.');
        not_null('pv_FOLIO', pv_FOLIO, vv_code_erreur);

        put_debug_message(lv_current_program_unit || ' 001 : Recherche des valeurs constantes du flux pour le folio ' || pv_FOLIO);
        BEGIN
           SELECT FFVD.CODE_FOLIO, FFVD.STATUS, FFVD.CURRENCY_CODE, FFVD.ACTUAL_FLAG, GJC.USER_JE_CATEGORY_NAME, GJS.USER_JE_SOURCE_NAME, FFVD.NOM_APPLICATION
           INTO vv_folio_oa, vv_status, vv_currency_code, vv_actual_flag, vv_category_name, vv_source_name, vv_application_name
           FROM APPS.FND_FLEX_VALUE_SETS  FFVS
           JOIN APPS.FND_FLEX_VALUES      FFV  on (FFV.FLEX_VALUE_SET_ID = FFVS.FLEX_VALUE_SET_ID)
           JOIN APPS.FND_FLEX_VALUES_DFV  FFVD on (FFV.rowid = FFVD.row_id)
           JOIN APPS.GL_JE_CATEGORIES     GJC  on (GJC.JE_CATEGORY_NAME = FFVD.USER_JE_CATEGORY_NAME)
           JOIN APPS.GL_JE_SOURCES        GJS  on (GJS.JE_SOURCE_NAME   = FFVD.USER_JE_SOURCE_NAME)
           WHERE 1=1
             AND FFV.FLEX_VALUE = pv_FOLIO
             AND FFVS.FLEX_VALUE_SET_NAME = 'DKA_PARAM_FOLIO_GL'
             AND FFV.VALUE_CATEGORY = 'DKA_PARAM_FOLIO_GL'
             AND FFV.ENABLED_FLAG = 'Y'
             AND (FFV.START_DATE_ACTIVE <= SYSDATE OR FFV.START_DATE_ACTIVE IS NULL)
             AND (FFV.END_DATE_ACTIVE >= SYSDATE OR FFV.END_DATE_ACTIVE IS NULL);
        EXCEPTION
           WHEN OTHERS THEN
             RAISE error_no_data;
        END;

        put_debug_message(lv_current_program_unit || ' 003 : Création Objet');
        po_cst_flux_gl := XXEAI_CST_FLUX_GL_OBJ('OAE000', vv_folio_oa, vv_status, vv_currency_code, vv_actual_flag, vv_category_name, vv_source_name, vv_application_name);

        put_debug_message(lv_current_program_unit || ' 999 : FIN');
     EXCEPTION
        WHEN error_no_data THEN
             po_cst_flux_gl := XXEAI_CST_FLUX_GL_OBJ('OAE001', vv_folio_oa, vv_status, vv_currency_code, vv_actual_flag, vv_category_name, vv_source_name, vv_application_name);
             put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR');
        WHEN OTHERS THEN
             po_cst_flux_gl := XXEAI_CST_FLUX_GL_OBJ('OAE999', vv_folio_oa, vv_status, vv_currency_code, vv_actual_flag, vv_category_name, vv_source_name, vv_application_name);
             put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Params_FOLIO_GL;


     -----------------------------------------------------------------
     --  Fonctionnalité 3 : Déterminer la société du projet
     --  Nom           : Get_Societe_Projet
     --  Description   : Fonction qui retourne dans un objet XXEAI_SOCIETE_OBJ
     --                  les informations de la société du projet.
     --
     --  PARAMETRES :
     --     pv_projet    Entrée      projet
     --     po_societe   Sortie      Objet regroupant le code erreur et la société oracle du projet.
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Societe_Projet(pv_projet  IN VARCHAR2,
                                  po_societe IN OUT NOCOPY XXEAI_SOCIETE_OBJ) IS
          lv_current_program_unit VARCHAR2(30) := 'Get_Societe_Projet';
          vv_code_erreur  VARCHAR2(50) := 'OAE000';
          v_project       APPS.PA_PROJECTS_ALL%ROWTYPE;
          vv_code_societe VARCHAR2(40);
     BEGIN
        put_debug_message(lv_current_program_unit || ' 001 : Recherche du projet ' || pv_projet);
        not_null('pv_projet', pv_projet, vv_code_erreur);

        v_project := get_project(pv_projet);
        validate(v_project.project_id is not null, vv_code_erreur, 'OAE002');

        put_debug_message(lv_current_program_unit || ' 001 : Recherche de la société du projet ' || v_project.project_id);
        vv_code_societe := apps.dka_spaautoaccounting_pkg.societe_projet(pn_project_id => v_project.project_id);
        validate(vv_code_societe is not null, vv_code_erreur, 'OAE003');

        po_societe := XXEAI_SOCIETE_OBJ('OAE000', vv_code_societe);
        put_debug_message(lv_current_program_unit || ' 999 : FIN');
     EXCEPTION
        WHEN e_main THEN
           po_societe := XXEAI_SOCIETE_OBJ(vv_code_erreur, vv_code_societe);
           put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR');
        WHEN OTHERS THEN
           po_societe      := XXEAI_SOCIETE_OBJ('OAE999', NULL);
           put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Societe_Projet;

     -----------------------------------------------------------------
     --  FONCTIONNALITE 4 : DETERMINER LE TYPE DE DEPENSE / EVENEMENT
     --  Nom           : Get_Type_Depense_Evenement
     --  Description   : Fonction qui retourne dans un objet XXEAI_TYP_EVT_DEP_OBJ
     --                  le type de dépense ou d'évenement.
     --
     --  PARAMETRES :
     --     po_dep_evt   Entrée      Objet regroupant le Code PR, le Code produit et le Compte Local
     --     po_societe   Sortie      Objet regroupant le Code erreur et le type de dépense/évenement.
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Type_Depense_Evenement(po_dep_evt     IN XXEAI_IN_TYP_EVT_DEP_TYP,
                                          po_typ_evt_dep IN OUT NOCOPY XXEAI_TYP_EVT_DEP_OBJ) IS
        lv_current_program_unit VARCHAR2(30) := 'Get_Type_Depense_Evenement';
        vv_code_erreur  VARCHAR2(50) := 'OAE000';
        vv_code_pr             VARCHAR2(50);
        vv_code_produit        VARCHAR2(50);
        vv_famille             VARCHAR2(50);
        vv_nature_analytique   VARCHAR2(100);
        vv_transco             VARCHAR2(100);
        vv_type_depense_evt    VARCHAR2(150);

        CURSOR cur_folio(pv_folio in varchar2) IS
        SELECT FLEX_VALUE_SET_NAME, FFVD.CODE_FOLIO, FFVD.MODE_DEP_EVT
        FROM APPS.FND_FLEX_VALUE_SETS       FFVS
        JOIN APPS.FND_FLEX_VALUES           FFV  on (FFV.FLEX_VALUE_SET_ID = FFVS.FLEX_VALUE_SET_ID)
        JOIN APPS.FND_FLEX_VALUES_DFV       FFVD on (FFV.rowid = FFVD.row_id)
        WHERE 1=1
        AND FFVD.CODE_FOLIO = pv_folio
        AND FFVS.FLEX_VALUE_SET_NAME in('DKA_PARAM_FOLIO_AP', 'DKA_PARAM_FOLIO_GL', 'DKA_PARAM_FOLIO_AR')
        AND FFV.VALUE_CATEGORY = FFVS.FLEX_VALUE_SET_NAME
        AND FFV.ENABLED_FLAG = 'Y'
        AND (FFV.START_DATE_ACTIVE <= SYSDATE OR FFV.START_DATE_ACTIVE IS NULL)
        AND (FFV.END_DATE_ACTIVE >= SYSDATE OR FFV.END_DATE_ACTIVE IS NULL);

        v_folio_info cur_folio%ROWTYPE;

        cursor cur_famille(p_code_produit in varchar2) is
        select DSL.return_value as famille
        from APPS.DKA_STRANSCO_HEADERS DSH
        join APPS.DKA_STRANSCO_LINES   DSL on (DSH.SET_ID = DSL.SET_ID)
        where 1=1
          and DSH.set_name = 'DKA_TRANSCO_PRODUIT_FAMILLE'
          and sysdate between nvl(DSL.Start_date, sysdate) and nvl(DSL.end_date, sysdate+1)
          and DSL.inactive_date is null
          and DSL.enable = 'Y'
          and p_code_produit between DSL.param1_value and DSL.param2_value;
     BEGIN
        put_debug_message(lv_current_program_unit || ' 000 : Début.');
        not_null('FOLIO', po_dep_evt.folio, vv_code_erreur);
        validate(po_dep_evt.folio != 'MOD', vv_code_erreur, 'OAE016', 'Le folio MOD n''est pas pris en charge par cette fonction');  -- TODO : créer un code erreur dédié

        put_debug_message(lv_current_program_unit || ' 001 : Recherche info folio : ' || po_dep_evt.folio);
        open cur_folio (po_dep_evt.folio);
        fetch cur_folio into v_folio_info;
        if cur_folio%notfound then
          close cur_folio;
          validate(FALSE, vv_code_erreur, 'OAE015');
        end if;
        close cur_folio;

        put_debug_message(lv_current_program_unit || ' 002 : Détermination du type de dépense/évenement : ' || v_folio_info.MODE_DEP_EVT);
        CASE v_folio_info.MODE_DEP_EVT
          WHEN 'TYPE_AS400' THEN
             not_null('NATURE1', po_dep_evt.nature1, vv_code_erreur);
             not_null('NATURE2', po_dep_evt.nature2, vv_code_erreur);
             not_null('COMPTE_LOCAL', po_dep_evt.compte_local, vv_code_erreur);
             vv_code_pr      := po_dep_evt.nature1;
             vv_code_produit := po_dep_evt.nature2;

             -- RG_F4_01
             put_debug_message(lv_current_program_unit || ' 002.1 : Interrogation de la transco DKA_TRANSCO_PRODUIT_FAMILLE');
             open cur_famille (vv_code_produit);
             fetch cur_famille into vv_famille;
             if cur_famille%notfound then
               close cur_famille;
               validate(FALSE, vv_code_erreur, 'OAE014');
             end if;
             close cur_famille;
             vv_nature_analytique := '0' || vv_code_pr || vv_famille;

          WHEN 'TYPE_ECO' THEN
             not_null('NATURE1', po_dep_evt.nature1, vv_code_erreur);
             not_null('COMPTE_LOCAL', po_dep_evt.compte_local, vv_code_erreur);
             vv_nature_analytique :=  po_dep_evt.nature1;

          WHEN 'TYPE_CID' THEN
             not_null('NATURE1', po_dep_evt.nature1, vv_code_erreur);
             vv_type_depense_evt :=  po_dep_evt.nature1;

          ELSE
            validate(FALSE, vv_code_erreur, 'OAE016', 'MODE_DEP_EVT non pris en charge :' ||v_folio_info.MODE_DEP_EVT);
        END CASE;

        -- RG_F04_02
        -- recherche du type de dépense / évenement dans la transco qui convient
        if vv_type_depense_evt is null then
          put_debug_message(lv_current_program_unit || ' 002.1 : Détermination de la transco PA');
          case
            when po_dep_evt.compte_local like '6%' THEN vv_transco := 'PA_EXPENDITURE_TYPE';
            when po_dep_evt.compte_local like '7%' THEN vv_transco := 'PA_EVENT_TYPE';
            else validate(FALSE, vv_code_erreur, 'OAE020', 'Classe de comptes non pris en charge :'  || po_dep_evt.compte_local);
          end case;

          put_debug_message(lv_current_program_unit || ' 002.1 : Interrogation de la transco ' ||  vv_transco || ' : ' || po_dep_evt.compte_local || ', ' || vv_nature_analytique);
          vv_type_depense_evt := APPS.dka_stransco_pkg.etl_get_value_f(vv_transco, sysdate, po_dep_evt.compte_local, vv_nature_analytique);
          validate(vv_type_depense_evt is not null , vv_code_erreur, 'OAE004');
        end if;

        po_typ_evt_dep := XXEAI_TYP_EVT_DEP_OBJ('OAE000', vv_type_depense_evt);
        put_debug_message(lv_current_program_unit || ' 999 : FIN');
     EXCEPTION
        WHEN e_main THEN
           po_typ_evt_dep := XXEAI_TYP_EVT_DEP_OBJ(vv_code_erreur, null);
           put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || vv_code_erreur);
        WHEN OTHERS THEN
           po_typ_evt_dep := XXEAI_TYP_EVT_DEP_OBJ('OAE999', NULL);
           put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Type_Depense_Evenement;

    --YWA artf2215513
    ----------------------------------------------------------------------------------------
    --  Fonction      : get_account_info
    --  Description   : recherche des infos du du compte local (segment3) passé en paramètre
    ----------------------------------------------------------------------------------------
    PROCEDURE get_account_info (
        pv_segment3               IN       VARCHAR2,
        pv_ledger_id              IN       NUMBER,
        pv_account_type           OUT      VARCHAR2,
        pv_flag_compte_prov_cli   OUT      VARCHAR2,
        pv_flag_tec_pca_cca       OUT      VARCHAR2,
        pv_flag_compte_chg_immo   OUT      VARCHAR2,
        pv_flag_matricule         OUT      VARCHAR2,
        pv_errbuf                 OUT      VARCHAR2,
        pv_retcode                OUT      NUMBER
    )
    IS
        v_seg3_flex_value_set_id        APPS.fnd_flex_value_sets.flex_value_set_id%TYPE; --fnd_flex_value_sets.flex_value_set_id%TYPE; -- SFA :artf07308610
        v_seg3_flex_value_set_name      APPS.fnd_flex_value_sets.flex_value_set_name%TYPE; --fnd_flex_value_sets.flex_value_set_name%TYPE;-- SFA :artf07308610
        --v_errbuf                VARCHAR2 (500);
        --v_retcode               NUMBER;
        --- 10/02/2021 NBO artf07438559 : INC0508700 - traitement de ces écritures par la PFE a duré plus de 3 heures
        ln_count                        NUMBER;
    BEGIN

        /*APPS.Dka_Tools_Pkg.get_flex_key_seg_value_set
                                        (
            pv_errbuf                    => pv_errbuf,
            pn_retcode                   => pv_retcode,
            pv_legal_flex_key_flag       => 'N',   -- on considère la ccf des organisations opérationnelles
            pn_segment_num               => 3,
            pn_flex_value_set_id         => v_seg3_flex_value_set_id,
            pv_flex_value_set_name       => v_seg3_flex_value_set_name
        );*/

        BEGIN
            SELECT ffs.flex_value_set_id,
                   ffs.flex_value_set_name
            INTO   v_seg3_flex_value_set_id,
                   v_seg3_flex_value_set_name
            FROM   APPS.fnd_id_flex_structures_vl fifst,
                   APPS.fnd_id_flex_segments fifs,
                   APPS.fnd_flex_value_sets ffs   --fnd_flex_value_sets ffs  -- SFA :artf07308610
            WHERE      fifst.id_flex_structure_code = (SELECT DISTINCT fifst2.ID_FLEX_STRUCTURE_CODE
                                                           FROM APPS.fnd_id_flex_structures_vl fifst2,
                                                               APPS.gl_ledgers  gl
                                                         WHERE  fifst2.id_flex_code = 'GL#'
                                                           AND GL.ledger_id = pv_ledger_id
                                                          AND GL.chart_of_accounts_id = fifst2.id_flex_num
                                                       )
                   AND fifst.application_id = 101
                   AND fifst.id_flex_code = 'GL#'
                   AND fifs.application_id = fifst.application_id
                   AND fifs.id_flex_code = fifst.id_flex_code
                   AND fifs.id_flex_num = fifst.id_flex_num
                   AND fifs.segment_num = 3
                   AND ffs.flex_value_set_id = fifs.flex_value_set_id;

        EXCEPTION
            WHEN OTHERS
            THEN
                pv_retcode    := 1;
                pv_errbuf     := 'get_account_info.v_seg3_flex_value_set_id:' || SQLERRM;
                return;

        END;


        SELECT SUBSTR (ffv.compiled_value_attributes, INSTR (ffv.compiled_value_attributes, CHR (10), 3, 1) + 1, 1),
               DECODE (ffv.attribute2,'Y',ffv.attribute2, 'X'),
               NVL (ffv.attribute3, 'N')
        INTO   pv_account_type,
               pv_flag_compte_prov_cli,
               pv_flag_tec_pca_cca
        FROM   APPS.fnd_flex_values_vl ffv -- fnd_flex_values_vl ffv -- SFA :artf07308610
        WHERE  ffv.flex_value = pv_segment3
           AND ffv.flex_value_set_id = v_seg3_flex_value_set_id;

        -- Controle que le compte local est compte de charge d'immo
        /*SELECT DECODE(COUNT(1), 0, 'N', 'Y')
          INTO pv_flag_compte_chg_immo
          FROM APPS.fa_categories_vl fcv,
               APPS.fa_category_books fcb
         WHERE EXISTS (SELECT 1
                         FROM APPS.fa_book_controls bc
                        WHERE nvl(date_ineffective, sysdate + 1) > sysdate
                          AND bc.book_type_code = fcb.book_type_code)
           AND fcv.category_id = fcb.category_id
           AND NVL(fcv.enabled_flag, 'N') = 'Y'
           AND fcb.asset_clearing_acct = pv_segment3;*/

   --- 10/02/2021 NBO artf07438559 : INC0508700 - traitement de ces écritures par la PFE a duré plus de 3 heures
          SELECT COUNT(1)
          INTO ln_count
          FROM APPS.fa_categories_vl fcv,
               APPS.fa_category_books fcb,
               APPS.fa_book_controls bc
         WHERE nvl(bc.date_ineffective, sysdate + 1) > sysdate
           AND bc.book_type_code = fcb.book_type_code
           AND bc.set_of_books_id = pv_ledger_id
           AND fcv.category_id = fcb.category_id
           AND NVL(fcv.enabled_flag, 'N') = 'Y'
           AND fcb.asset_clearing_acct = pv_segment3;

        -- si compte de charge d'immo alors on le traite comme un compte de charge
        --IF pv_flag_compte_chg_immo = 'Y' THEN
        IF ln_count > 0 THEN
            pv_flag_compte_chg_immo := 'Y';
            pv_account_type    := 'E';
        ELSE
           pv_flag_compte_chg_immo := 'N';
        END IF;

        -- Controle que le compte local est inclus dans le jdv DKA_COMPTE_MATRICULE
        SELECT DECODE(COUNT(1), 0, 'N', 'Y')
          INTO pv_flag_matricule
          FROM APPS.fnd_flex_value_sets ffvs, APPS.fnd_flex_values ffv --fnd_flex_value_sets ffvs, fnd_flex_values ffv -- SFA :artf07308610
         WHERE ffvs.flex_value_set_id = ffv.flex_value_set_id
           AND ffvs.flex_value_set_name = 'DKA_COMPTE_MATRICULE'
           AND ffv.flex_value = pv_segment3
           AND ffv.enabled_flag = 'Y'; -- OBE artf2222144

    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            pv_retcode    := 1;
            pv_errbuf     := 'Le compte local ' ||pv_segment3|| ' n''existe pas ';
        WHEN OTHERS
        THEN
            pv_retcode    := 1;
            pv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_account_info:' || SQLERRM;
    END get_account_info;


     -----------------------------------------------------------------
     -- FONCTIONNALITÉ 5 : DÉTERMINER LA CLÉ COMPTABLE ET LES ÉLÉMENTS DU CUF GL
     --  Nom           : Get_Cle_Comptable_CUF
     --  Description   : Fonction qui retourne dans un objet XXEAI_CLE_COMPTABLE_CUF_OBJ
     --                  les valeurs de chaque segment de la clé comptable et les champs du CUF
     --          GL pour tous les comptes locaux et selon les regles de chaque folio.
     --
     --  PARAMETRES :
     --     po_info_cle            Entrée      Objet regroupant Folio AMONT, Société de l?écriture,
     --                      Segmentation (Appartenance), Compte local, Code Partenaire,
     --                      Code projet, Type de dépense ou d?évenement, Quantité
     --     po_cle_comptable_cuf   Sortie      Objet regroupant Code Erreur, Société, Région, Compte local,
     --                      Compte Groupe, Complément groupe, Centre de cout, Code Affaire,
     --                      Code Activité, Flux, Réserve, Contexte du CUF, Id du projet, Type d?évenement,
     --                        Type de dépense, Quantité, Id du projet a refacturer
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Cle_Comptable_CUF(po_info_cle          IN XXEAI_INFO_CLE_TYP,
                                     po_cle_comptable_cuf IN OUT NOCOPY XXEAI_CLE_COMPTABLE_CUF_OBJ) IS
        lv_current_program_unit VARCHAR2(30) := 'Get_Cle_Comptable_CUF';
        vv_code_erreur          VARCHAR2(50) := 'OAE000';
        vo_result               XXEAI_CLE_COMPTABLE_CUF_OBJ;

        vv_task_info            APPS.PA_TASKS%ROWTYPE;
        vv_project_info         APPS.PA_PROJECTS%ROWTYPE;
        vv_project_refac_info   APPS.PA_PROJECTS%rowtype;
        vv_task_refac_info      APPS.PA_TASKS%ROWTYPE;

        vo_info_region XXEAI_TYPE_INFO_REGION_OBJ;
        vv_societe     VARCHAR2(40);
        vv_dkcode      VARCHAR2(40);
        vv_task_number APPS.PA_TASKS.task_number%TYPE;
        vv_class       PA.PA_PROJECT_CLASSES%ROWTYPE; --vv_class.class_code
        vv_class_refac PA.PA_PROJECT_CLASSES%ROWTYPE; -- OBE artf2171905
        vv_class_diap  PA.PA_PROJECT_CLASSES%ROWTYPE; -- OBE artf2194552
        v_flex_value   cur_flex_value%rowtype;

		--EDB281

		vv_attribute2   VARCHAR2 (2);
		v_test_cpt_mat NUMBER;

        --YWA artf2215513
        vn_count        NUMBER ;
         vv_account_type                VARCHAR2 (1);
        vv_flag_compte_prov_cli        VARCHAR2 (1);
        vv_flag_tec_pca_cca            VARCHAR2 (1);
        vv_flag_compte_chg_immo        VARCHAR2 (1);
        vv_flag_matricule              VARCHAR2 (1);
        vv_flag_cuf_actif               VARCHAR2 (1);

        v_errbuf     VARCHAR2 (5000) ;
        v_retcode       NUMBER := 0;


        cursor cur_expenditure_type(p_type_dep_evt in varchar2) is
        select pe.expenditure_type, pe.expenditure_type_id, pe.unit_of_measure as UdM
        from PA.PA_EXPENDITURE_TYPES pe
        where pe.expenditure_type = p_type_dep_evt
        and (pe.start_date_active <= SYSDATE OR pe.start_date_active IS NULL)
        and (pe.end_date_active >= SYSDATE OR pe.end_date_active IS NULL);
        vv_expenditure_type cur_expenditure_type%rowtype;

        cursor cur_event_type(p_type_dep_evt in varchar2) is
        select pe.event_type, pe.event_type_id, pe.attribute3 as UdM
        from PA.PA_EVENT_TYPES pe
        where pe.event_type = p_type_dep_evt
        and (pe.start_date_active <= SYSDATE OR pe.start_date_active IS NULL)
        and (pe.end_date_active >= SYSDATE OR pe.end_date_active IS NULL);
        vv_event_type cur_event_type%rowtype;

        vv_UdM               PA.PA_EVENT_TYPES.attribute3%TYPE;
        vo_cst_flux_gl       XXEAI_CST_FLUX_GL_OBJ;
        vv_societe_projet    VARCHAR2(40);
        vb_refac             boolean;

        -- procédure imbriquée
        procedure check_seg_value(
          p_ledger_id     in APPS.GL_LEDGERS.ledger_id%type,
          p_segment_name  in APPS.FND_ID_FLEX_SEGMENTS.segment_name%type,
          p_value         in APPS.FND_FLEX_VALUES.flex_value%type,
          p_error_code    in varchar2) is
        begin
          validate(check_segment_value(p_ledger_id, p_segment_name, p_value), vv_code_erreur, p_error_code);
        end check_seg_value;
     BEGIN
       put_debug_message(lv_current_program_unit || ' 000 : DEBUT');
       vo_result := XXEAI_CLE_COMPTABLE_CUF_OBJ(vv_code_erreur, null, null, null, null, null,   null, null, null, null, null,
                                                                null, null, null, null, null,   null, null, null, null, null,   null);

       -- parametres obligatoires
       put_debug_message(lv_current_program_unit || ' 001 : Vérification des valeurs obligatoires');
       not_null('FOLIO',        po_info_cle.folio,        vv_code_erreur);
       not_null('SOCIETE',      po_info_cle.societe,      vv_code_erreur);
     --not_null('REGION',       po_info_cle.region,       vv_code_erreur); --YWA artf2206549
       not_null('COMPTE_LOCAL', po_info_cle.compte_local, vv_code_erreur);

       -- Vérification de la validité du folio
       put_debug_message(lv_current_program_unit || ' 002 : Vérification du folio');
       Get_Params_Folio_GL(po_info_cle.FOLIO, vo_cst_flux_gl);
       validate(nvl(vo_cst_flux_gl.CODE_ERREUR, 'OAE000') = 'OAE000', vv_code_erreur, 'OAE001');

      -- Condition particuliere pour RHAPSODY --artf2202194
       IF NVL(vo_cst_flux_gl.application_name,'n/a') = 'RHAPSODY' THEN
       not_null('CODE_AFFAIRE', po_info_cle.code_affaire, vv_code_erreur);
    END IF;
         IF NVL(vo_cst_flux_gl.application_name,'n/a') <> 'RHAPSODY'
         AND NVL(vo_cst_flux_gl.application_name,'n/a') <> 'DIAPASON' --YWA artf2206549
         THEN
           not_null('TACHE_PROJET_FINANCE', po_info_cle.tache_projet_finance, vv_code_erreur);
         END IF;

       -- info du projet (project_id et task_id)
       if po_info_cle.tache_projet_finance is not null then
         put_debug_message(lv_current_program_unit || ' 002 : Recherche de la tâche et du projet finance : ' || po_info_cle.tache_projet_finance);
         vv_task_info := get_task(p_task_number => po_info_cle.tache_projet_finance);
         validate(vv_task_info.task_id is not null, vv_code_erreur, 'OAE011');
         vv_project_info := get_project(p_project_id => vv_task_info.project_id);
         validate(vv_project_info.project_id is not null, vv_code_erreur, 'OAE002');

         -- société du projet
         put_debug_message(lv_current_program_unit || ' 003 : Recherche de la société du projet : ' || vv_project_info.segment1);
         vv_societe_projet := apps.dka_spaautoaccounting_pkg.societe_projet(pn_project_id => vv_project_info.project_id);
         validate(vv_societe_projet is not null, vv_code_erreur, 'OAE007');

         --Recherche de la classification affaire
         put_debug_message(lv_current_program_unit || ' 003 : Recherche de la classification AFFAIRE du projet : ' || vv_project_info.segment1);
         vv_class := get_class_affaire(vv_task_info.project_id);
         validate(vv_class.class_code is not null, vv_code_erreur, 'OAE010');

       end if;


       -- Ledger_ID
       put_debug_message(lv_current_program_unit || ' 004 : Recherche livre de la société ' || po_info_cle.societe);
       vo_result.ledger_id := APPS.DKA_GL_TOOLS_PKG.get_legder_id(po_info_cle.societe);
       validate(vo_result.ledger_id is not null, vv_code_erreur, 'OAE041');

       -- Vérification de la validité de la date comptable
       put_debug_message(lv_current_program_unit || ' 005 : Validation période comptable ouverte : ' || po_info_cle.DATE_COMPTABLE);
       validate(period_is_open(vo_result.ledger_id, po_info_cle.DATE_COMPTABLE), vv_code_erreur, 'OAE014');

       -- segment 1 : société
       put_debug_message(lv_current_program_unit || ' 006 : Validation société : ' ||  po_info_cle.societe);
       check_seg_value(vo_result.ledger_id, 'SOCIETE', po_info_cle.societe, 'OAE006');
       vo_result.segment1 := po_info_cle.societe;

       -- segment 2 : Région
       put_debug_message(lv_current_program_unit || ' 007 : Validation region/UO');
       IF NVL(vo_cst_flux_gl.application_name,'n/a') = 'DIAPASON' THEN
        v_flex_value := get_flex_value('DKA_GLEAI_REGION_DIAPASON', po_info_cle.COMPTE_LOCAL);
        IF v_flex_value.flex_value_id is not null then
          put_debug_message(lv_current_program_unit || ' 007 : DIAPASON / DKA_GLEAI_REGION_DIAPASON');
          not_null('REGION',       po_info_cle.region,       vv_code_erreur); --YWA artf2206549
          vo_result.segment2 := po_info_cle.REGION;
          --validate(vo_result.segment2 IS NOT NULL, vv_code_erreur, 'OAE007');


        ELSIF substr(po_info_cle.COMPTE_LOCAL, 1, 2) = '51' THEN
          put_debug_message(lv_current_program_unit || ' 007 : DIAPASON / COMPTE_LOCAL');

          BEGIN
             SELECT distinct b.segment2
             INTO vo_result.segment2
             FROM
              APPS.CE_BANK_ACCOUNTS a,
              APPS.GL_CODE_COMBINATIONS_KFV b
             WHERE account_classification = 'INTERNAL'
               and sysdate between nvl(A.START_DATE, sysdate) and nvl(A.END_DATE, sysdate+1)
               AND a.asset_code_combination_id = b.code_combination_id
               AND b.segment3 = po_info_cle.compte_local
             ;
          EXCEPTION
           WHEN NO_DATA_FOUND THEN
            vo_result.segment2 := NULL;
            validate(FALSE, vv_code_erreur, 'OAE038');
           WHEN TOO_MANY_ROWS THEN
            validate(FALSE, vv_code_erreur, 'OAE038');
          END;
        ELSIF substr(po_info_cle.COMPTE_LOCAL,1,2) != '51' THEN

           v_flex_value := get_flex_value('DAOPCCF_STE', po_info_cle.SOCIETE);
           IF v_flex_value.flex_value_id is not null then
             vo_result.segment2 := v_flex_value.REGION_PRINCIPALE;
             validate(vo_result.segment2 IS NOT NULL, vv_code_erreur, 'OAE007');
           END IF;
        END IF;
       ELSE
        --Parametre obligatoire
        not_null('REGION',       po_info_cle.region,       vv_code_erreur);
        vo_result.segment2 := po_info_cle.region;
       END IF;

       put_debug_message(lv_current_program_unit || ' 007 : Validation region/UO : ' ||  vo_result.segment2);
       check_seg_value(vo_result.ledger_id, 'UO', vo_result.segment2, 'OAE007');


       -- segment 3 :  compte local
       put_debug_message(lv_current_program_unit || ' 008 : Validation compte local : ' ||  po_info_cle.compte_local);
       check_seg_value(vo_result.ledger_id, 'COMPTE_LOCAL', po_info_cle.compte_local, 'OAE005');
       vo_result.segment3 := po_info_cle.compte_local;


       --< OBE artf2194552
       -- Condition particuliere pour DIAPASON
       IF NVL(vo_cst_flux_gl.application_name,'n/a') = 'DIAPASON' THEN

         vv_task_number := get_task_number(vo_result.segment2, po_info_cle.societe);
         vv_task_info := get_task(p_task_number => vv_task_number);
         vv_project_info := get_project(p_project_id => vv_task_info.project_id);
         validate(vv_project_info.project_id is not null, vv_code_erreur, 'OAE002');

         --Recherche de la classification affaire pour diapason
         put_debug_message(lv_current_program_unit || ' Recherche de la classification AFFAIRE du projet pour diaposon : ' || vv_project_info.segment1);
         vv_class_diap := get_class_affaire(vv_task_info.project_id);
         validate(vv_class_diap.class_code is not null, vv_code_erreur, 'OAE010');

       ELSE
        -- parametres obligatoires
        --not_null('TACHE_PROJET_FINANCE', po_info_cle.tache_projet_finance, vv_code_erreur);
        null;

       END IF;
       --> OBE artf2194552


        --YWA artf2215513
        put_debug_message(lv_current_program_unit || ' 013.1 : context3 : ' || po_info_cle.compte_local);
        --YWA artf2215513
        -- Si la valeur du segment 3 commence par 51XXXX  alors -- YWA artf2215513
        IF SUBSTR (po_info_cle.compte_local, 1, 2) = '51' THEN -- YWA artf2215513
            vo_result.context3     := null; --'RB';

        ELSE
            --Ajout Contexte FRAIS pour les comptes du jeu de valeur DKA_CPT_FRAIS_BANC
            SELECT count(1)
            INTO vn_count
            FROM APPS.fnd_flex_values_vl ffv,
                 APPS.fnd_flex_value_sets ffvs
            WHERE ffvs.flex_value_set_name = 'DKA_CPT_FRAIS_BANC'
              AND ffvs.flex_value_set_id = ffv.flex_value_set_id
              AND ffv.flex_value = po_info_cle.compte_local ;

            IF vn_count <> 0 THEN
                vo_result.context3  := 'FRAIS';
            ELSE


                -- Recherche de la nature du compte local, de son flag "Compte provision client"
                -- et de son flag tec_pca_cca
                put_debug_message(lv_current_program_unit || ' 013.2 : get_account_info ');
                get_account_info (
                    pv_segment3                   => po_info_cle.compte_local,
                    pv_ledger_id                  => vo_result.ledger_id,
                    pv_account_type               => vv_account_type,
                    pv_flag_compte_prov_cli       => vv_flag_compte_prov_cli,
                    pv_flag_tec_pca_cca           => vv_flag_tec_pca_cca,
                    pv_flag_compte_chg_immo       => vv_flag_compte_chg_immo,
                    pv_flag_matricule             => vv_flag_matricule,
                    pv_errbuf                     => v_errbuf,
                    pv_retcode                    => v_retcode

                );
                put_debug_message(lv_current_program_unit || ' 013.3 : fin get_account_info ');
                IF v_retcode != 0 THEN
                    validate(v_errbuf is null, vv_code_erreur, 'OAE083',v_errbuf);
                ELSE
                    IF vv_account_type NOT IN ('E', 'R') THEN
                        vv_account_type    := 'X';
                    END IF;

                    -- Recherche des infos du type de pièce
                    --get_je_category_info (pv_user_je_category_name => pv_user_je_category_name, pv_flag_cuf_actif => vv_flag_cuf_actif);
                    SELECT NVL (gjc.attribute1, 'Y')
                    INTO   vv_flag_cuf_actif
                    FROM   APPS.gl_je_categories gjc
                    WHERE  gjc.user_je_category_name = vo_cst_flux_gl.category_name;

                    -- Constitution du contexte
                    IF vv_flag_matricule = 'N' THEN
                       vo_result.context3             := vv_flag_cuf_actif || '.' || vv_account_type || '.' || vv_flag_compte_prov_cli;

                    --EDB281

					   /*select ffv.ATTRIBUTE2
					   into vv_attribute2
					  from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
					 where ffvs.flex_value_set_id = ffv.flex_value_set_id
					   and ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
					   and ffv.ENABLED_FLAG = 'Y'
					   and nvl(ffv.START_DATE_ACTIVE, trunc(SYSDATE)) <=
						   trunc(SYSDATE)
					   and nvl(ffv.END_DATE_ACTIVE, trunc(SYSDATE)) >=
						   trunc(SYSDATE)
					   and ffv.SUMMARY_FLAG = 'N'
					   and ffv.flex_value = po_info_cle.compte_local;


					   IF vo_result.context3 = 'Y.X.Y' AND vv_attribute2 = 'Y' THEN
                        vo_result.context3 := NULL;
                       END IF;*/ --EDB281 Lot2 activer ultériereument

					   IF vo_result.context3 NOT IN ('Y.E.X','Y.R.X','Y.X.Y') THEN
                        vo_result.context3 := NULL;
                       END IF;


                    /*ELSE

                        SELECT count(1)
                        INTO vn_count
                        FROM APPS.fnd_flex_values_vl ffv,
                             APPS.fnd_flex_value_sets ffvs
                        WHERE ffvs.flex_value_set_name = 'DKA_COMPTE_MATRICULE'
                          AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                          AND ffv.flex_value = po_info_cle.compte_local
                          AND ffv.enabled_flag = 'Y'; -- OBE artf2222144


                        IF vn_count <> 0 THEN
                           // vo_result.context3             := 'MAT';

                        END IF ;
                        */ --EDB281

                    END IF;
                END IF;
            END IF;--YWA artf2215513
        END IF;
        put_debug_message(lv_current_program_unit || ' 013.1 :fin context3 : ' || vo_result.context3);

       CASE
         -- --------- COMPTES DE BILAN ---------
         WHEN substr(po_info_cle.compte_local, 1, 1) between '1' and '5' THEN
           put_debug_message(lv_current_program_unit || ' 009 : COMPTE DE BILAN');
           -- segment4 : compte analytique => Déterminé en fonction du parametre 6 en interrogeant la table de transcodification MIGR_GROUP_ACCOUNT_CLASS_BILAN
           put_debug_message(lv_current_program_unit || ' 010 : recherche transco compte local -> compte analytique : ' || po_info_cle.compte_local);
           vo_result.segment4 := APPS.dka_stransco_pkg.etl_get_value_f('MIGR_GROUP_ACCOUNT_CLASS_BILAN',  sysdate, po_info_cle.compte_local);
           check_seg_value(vo_result.ledger_id, 'COMPTE_ANALYTIQUE', vo_result.segment4, 'OAE005');

         -- --------- COMPTES DE RESULTAT ---------
         WHEN substr(po_info_cle.compte_local, 1, 1) in ('6', '7') THEN
           put_debug_message(lv_current_program_unit || ' 009 : COMPTE DE RESULTAT');

           -- parametres obligatoires
           not_null('TYPE_DEP_EVT', po_info_cle.type_dep_evt, vv_code_erreur);

           --< OBE artf2194552
           /*
           -- Condition particuliere pour DIAPASON
           IF NVL(vo_cst_flux_gl.application_name,'n/a') = 'DIAPASON' THEN

             vv_task_number := get_task_number(vo_result.segment2, po_info_cle.societe); --po_info_cle.region -- OBE
             vv_task_info := get_task(p_task_number => vv_task_number);
             vv_project_info := get_project(p_project_id => vv_task_info.project_id);
             validate(vv_project_info.project_id is not null, vv_code_erreur, 'OAE002');

           ELSE
            -- parametres obligatoires
            not_null('TACHE_PROJET_FINANCE', po_info_cle.tache_projet_finance, vv_code_erreur);

           END IF;
           */
           --> OBE artf2194552

           -- info du projet de refac
           if vv_societe_projet != po_info_cle.societe THEN
             vb_refac :=true;
             put_debug_message(lv_current_program_unit || ' 010 : Recherche de la tâche et du projet de refac : ' || po_info_cle.region || po_info_cle.societe);
             vv_project_refac_info := get_project(p_project_code => po_info_cle.region || po_info_cle.societe);
             validate(vv_project_refac_info.project_id is not null, vv_code_erreur, /*'OAE013'*/ 'OAE002');
             vv_task_refac_info := get_task(p_project_id => vv_project_refac_info.project_id, p_task_number => '1');     -- la tâche s'appelle toutjours 1
             validate(vv_task_refac_info.task_id is not null, vv_code_erreur, 'OAE013.1');

             --< OBE artf2237928
             IF is_autoreverse(vo_cst_flux_gl.category_name) THEN
              validate(FALSE, vv_code_erreur, 'OAE045');
             END IF;
             --> OBE artf2237928

           end if;

           IF is_autoreverse(vo_cst_flux_gl.category_name) THEN
             validate(LAST_DAY(TRUNC (ADD_MONTHS (SYSDATE, 1), 'MONTH')) BETWEEN
                           NVL (vv_project_info.start_date, LAST_DAY(TRUNC (ADD_MONTHS (SYSDATE, 1), 'MONTH')))
                       AND NVL (NVL (vv_project_info.completion_date, to_date(vv_project_info.attribute7,'YYYY/MM/DD HH24:MI:SS')), LAST_DAY(TRUNC (ADD_MONTHS (SYSDATE, 1), 'MONTH')))
                      , vv_code_erreur, 'OAE036');
           END IF;

           if po_info_cle.compte_local like '6%' then
             put_debug_message(lv_current_program_unit || ' 011 : Recherche du type de dépense ' || po_info_cle.TYPE_DEP_EVT);
             open cur_expenditure_type(po_info_cle.TYPE_DEP_EVT);
             fetch cur_expenditure_type into vv_expenditure_type;
             if cur_expenditure_type%notfound then
               close cur_expenditure_type;
               validate(FALSE, vv_code_erreur, 'OAE004');
             end if;
             close cur_expenditure_type;

             vv_UdM := vv_expenditure_type.UdM;
             put_debug_message(lv_current_program_unit || ' 012 : Recherche du compte analytique de couts');
             vo_result.segment4 := apps.dka_spaautoaccounting_pkg.run_cpt_groupe_couts_f(
               pn_project_id       => case when vb_refac then vv_project_refac_info.project_id else vv_project_info.project_id end,
               pv_expenditure_type => po_info_cle.TYPE_DEP_EVT,
               pn_task_id          => case when vb_refac then vv_task_refac_info.task_id else vv_task_info.task_id end,
               pn_refac_project_id => case when vb_refac then vv_project_info.project_id else NULL end /*vv_project_refac_info.project_id*/ ); -- OBE artf2171905


             -- Attribute12 : Type d'évenement
             vo_result.attribute12 := NULL;

             -- Attribute13 : Type de dépense
             vo_result.attribute13 := vv_expenditure_type.expenditure_type;


           else        -- classe 7
             put_debug_message(lv_current_program_unit || ' 011 : Recherche du type d''évenement ' || po_info_cle.TYPE_DEP_EVT);
             open cur_event_type(po_info_cle.TYPE_DEP_EVT);
             fetch cur_event_type into vv_event_type;
             if cur_event_type%notfound then
               close cur_event_type;
               validate(FALSE, vv_code_erreur, 'OAE004');
             end if;
             close cur_event_type;

             vv_UdM := vv_event_type.UdM;
             put_debug_message(lv_current_program_unit || ' 012 : Recherche du compte analytique de produits');
             vo_result.segment4 := apps.dka_spaautoaccounting_pkg.run_cpt_groupe_produit_f(
               pn_project_id       => case when vb_refac then vv_project_refac_info.project_id else vv_project_info.project_id end,
               pv_event_type       => po_info_cle.TYPE_DEP_EVT,
               pn_task_id          => case when vb_refac then vv_task_refac_info.task_id else vv_task_info.task_id end);

             -- Attribute12 : Type d'évenement
             vo_result.attribute12 := vv_event_type.event_type;

             -- Attribute13 : Type de dépense
             vo_result.attribute13 := NULL;
           end if;



           -- Attribute14 : Quantité
           put_debug_message(lv_current_program_unit || ' 013 : Validation quantité : ' || po_info_cle.quantite);
           if not is_currency(vv_UdM) then
             not_null('QUANTITE', po_info_cle.quantite, vv_code_erreur);
             validate(is_numeric(po_info_cle.quantite), vv_code_erreur, 'OAE012');
             vo_result.attribute14 := po_info_cle.quantite;
           end if;

           if vb_refac then
             vv_class_refac := get_class_affaire(vv_project_refac_info.project_id); -- OBE artf2171905
           end if;


         -- --------- CLASSE DE COMPTES INCONNUE ---------
         ELSE
           vv_code_erreur := '';
           validate(FALSE, vv_code_erreur, 'OAE005', 'Classe de comptes non pris en charge : ' || po_info_cle.compte_local);
         END CASE;

       -- CONTEXTE et ATTRIBUT PROJET
       IF vo_result.context3 = 'MAT' THEN --YWA  artf2215513
         --IF po_info_cle.code_affaire != '0' THEN
          vo_result.attribute11 := NULL; --EDB281
		  /* vo_result.attribute11 := po_info_cle.code_affaire; --EDB281 Arreter l'alimentation
         ELSE
           vo_result.attribute11 := NULL;
         END IF;*/ --EDB281

         -- Attribute17 : Id de la tâche
         vo_result.attribute17 := null;
         -- Attribute12 : Type d'évenement
         vo_result.attribute12 := null;
         -- Attribute13 : Type de dépense
         vo_result.attribute13 := null;
         -- Attribute14 : Quantité
         vo_result.attribute14 := null;
         -- Attribute15 : Id du projet a refacturer
         vo_result.attribute15 := null;
         -- Attribute18 : Id de la tâche a refacturer
         vo_result.attribute18 := null;

       ELSIF vo_result.context3 IN ('Y.E.X', 'Y.R.X', 'FRAIS') THEN
         if vb_refac then
          -- Attribute11 : Id du projet
          vo_result.attribute11 := vv_project_refac_info.project_id;
          -- Attribute15  Id du projet a refacturer
          vo_result.attribute15 := vv_project_info.project_id;
          -- Attribute17 : Id de la tâche
          vo_result.attribute17 := vv_task_refac_info.task_id;
          vo_result.attribute18 := vv_task_info.task_id;
         else
          -- Attribute11 : Id du projet
          vo_result.attribute11 := vv_project_info.project_id;
          -- Attribute18  Id de la tâche a refacturer
          vo_result.attribute17 := vv_task_info.task_id;
         end if;

       ELSE
         -- Attribute11 : Id du projet
          vo_result.attribute11 := null;
         -- Attribute17 : Id de la tâche
         vo_result.attribute17 := null;
         -- Attribute15 : Id du projet a refacturer
         vo_result.attribute15 := null;
         -- Attribute18 : Id de la tâche a refacturer
         vo_result.attribute18 := null;
         -- Attribute12 : Type d'évenement
         vo_result.attribute12 := null;
         -- Attribute13 : Type de dépense
         vo_result.attribute13 := null;
         -- Attribute14 : Quantité
         vo_result.attribute14 := null;
       END IF;

       -- Segment5 : Code interco

		BEGIN --EDB281 ARA
		SELECT count(1)
			INTO v_test_cpt_mat
		FROM (
			select ffv.flex_value
          from fnd_flex_values_vl ffv, apps.fnd_flex_value_sets ffvs
         where ffvs.flex_value_set_id = ffv.flex_value_set_id
           and ffvs.flex_value_set_name = 'DKA_COMPTE_MATRICULE'
           and ffv.ENABLED_FLAG = 'Y'
           and nvl(ffv.START_DATE_ACTIVE, trunc(SYSDATE)) <=
               trunc(SYSDATE)
           and nvl(ffv.END_DATE_ACTIVE, trunc(SYSDATE)) >=
               trunc(SYSDATE)
           and ffv.SUMMARY_FLAG = 'N'
           and ffv.flex_value = po_info_cle.compte_local
		   );
		END;

	  IF v_test_cpt_mat > 0 THEN --EDB281 ARA

		vo_result.segment5 := 'P' || po_info_cle.code_affaire;

		--END EDB281 ARA
	  ELSE


       IF NVL(vo_cst_flux_gl.application_name,'n/a') = 'RHAPSODY' THEN

         vo_result.segment5 := '0';

       ELSE

         IF po_info_cle.CODE_AFFAIRE IS NOT NULL THEN
          IF length(po_info_cle.CODE_AFFAIRE) = 4
             AND TRANSLATE (po_info_cle.CODE_AFFAIRE,' 1234567890',' ') IS NULL THEN --YWA artf2156152

           vo_result.segment5 := 'XXX'||po_info_cle.CODE_AFFAIRE;

          ELSE

           vv_societe := substr(po_info_cle.CODE_AFFAIRE,-4,4);
           vv_dkcode  := substr(po_info_cle.CODE_AFFAIRE,1,length(po_info_cle.CODE_AFFAIRE)-4);

           IF vv_dkcode IS NOT NULL THEN
             Get_region_DKCODE(vv_dkcode,vo_info_region);
             validate(nvl(vo_info_region.CODE_ERREUR, 'OAE000') = 'OAE000', vv_code_erreur, 'OAE043');

             vo_result.segment5 := vo_info_region.region||vv_societe;

           ELSE
             vo_result.segment5 := '0';
           END IF;

          END IF;

         ELSE -- po_info_cle.CODE_AFFAIRE IS NOT NULL
           vo_result.segment5 := '0';
         END IF;

       END IF;--RHAPSODY

	   END IF; --EDB281

       check_seg_value(vo_result.ledger_id, 'CODE_INTERCO', vo_result.segment5, 'OAE043');


       --< OBE artf2194552
       IF NVL(vo_cst_flux_gl.application_name,'n/a') = 'DIAPASON' THEN  -- CAS DIAPASON

       -- Segment6 : Centre finance
       put_debug_message(lv_current_program_unit || ' 013 : Validation centre_finance : ' ||  po_info_cle.centre_finance);
       check_seg_value(vo_result.ledger_id, 'CENTRE_FI', po_info_cle.centre_finance, 'OAE009');


         IF substr(po_info_cle.compte_local, 1, 1) between '1' and '5' THEN
            vo_result.segment6 := '0';
         ELSE
            IF vb_refac THEN
              SELECT h.name
              INTO vo_result.segment6
              FROM pa_projects_all p,
                hr_all_organization_units h
              WHERE h.organization_id = p.carrying_out_organization_id
              AND p.project_id        = vv_project_refac_info.project_id
              ;
            ELSE
                SELECT h.name
                INTO vo_result.segment6
                FROM pa_projects_all p,
                  hr_all_organization_units h
                WHERE h.organization_id = p.carrying_out_organization_id
                AND p.project_id        = vv_project_info.project_id
                ;
            END IF;
         END IF;

         -- Segment7 : Code affaire
         put_debug_message(lv_current_program_unit || ' 014 : Validation code_affaire');


         IF substr(po_info_cle.compte_local, 1, 1) between '1' and '5' THEN -- OBE artf2221959
            vo_result.segment7 := '0';                                      -- OBE artf2221959
         ELSE                                                               -- OBE artf2221959

           vo_result.segment7 := vv_class_diap.class_code;
           IF vb_refac THEN
            vo_result.segment7 := vv_class_refac.class_code;
           END IF;

         END IF;                                                            -- OBE artf2221959


         put_debug_message(lv_current_program_unit || ' 014 : Validation code_affaire : ' ||  vo_result.segment7);
         check_seg_value(vo_result.ledger_id, 'AFFAIRE', vo_result.segment7, 'OAE010');


       ELSE  -- PAS UN CAS DIAPASON
       --> OBE artf2194552

         -- Segment6 : Centre finance
         put_debug_message(lv_current_program_unit || ' 013 : Validation centre_finance : ' ||  po_info_cle.centre_finance);
         check_seg_value(vo_result.ledger_id, 'CENTRE_FI', po_info_cle.centre_finance, 'OAE009');

         IF substr(po_info_cle.compte_local, 1, 1) between '1' and '5' THEN -- OBE artf2158877
            vo_result.segment6 := '0';                                      -- OBE artf2158877
         ELSE                                                               -- OBE artf2158877
            IF vb_refac THEN                                                -- OBE artf2171905
              --< OBE artf2171905
              SELECT h.name
              INTO vo_result.segment6
              FROM pa_projects_all p,
                hr_all_organization_units h
              WHERE h.organization_id = p.carrying_out_organization_id
              AND p.project_id        = vv_project_refac_info.project_id
              ;
              --> OBE artf2171905
            ELSE                                                            -- OBE artf2171905
                vo_result.segment6 := nvl(po_info_cle.centre_finance, '0');
            END IF;                                                         -- OBE artf2171905
         END IF;                                                            -- OBE artf2158877

         -- Segment7 : Code affaire
         put_debug_message(lv_current_program_unit || ' 014 : Validation code_affaire');
         --check_seg_value(vo_result.ledger_id, 'AFFAIRE', po_info_cle.code_affaire, 'OAE010');

         --< OBE artf2221959
         /*
         IF po_info_cle.folio = 'PRE' OR po_info_cle.folio = 'PVR' THEN --YWA artf2093557
              IF substr(po_info_cle.compte_local, 1, 1) between '1'and '5'  THEN
                  --vo_result.segment7 := '0';
                  IF po_info_cle.TACHE_PROJET_FINANCE is not null THEN
                    vo_result.segment7 := vv_class.class_code; --YWA artf2215513
                  ELSE
                    vo_result.segment7 := '0';
                  END IF; --YWA artf2215513

              ELSIF substr(po_info_cle.compte_local, 1, 1) in ('6', '7') THEN
                  vo_result.segment7 := vv_class.class_code; --YWA artf2215513
              END IF;--YWA artf2093557
         ELSE
           --Détermination du code affaire sur le projet
           IF po_info_cle.TACHE_PROJET_FINANCE is not null THEN
             IF vb_refac THEN                                  -- OBE artf2171905
              vo_result.segment7 := vv_class_refac.class_code; -- OBE artf2171905
             ELSE                                              -- OBE artf2171905
              vo_result.segment7 := vv_class.class_code;
             END IF;                                           -- OBE artf2171905
           ELSE
              --vo_result.segment7 := '0';                -- OBE artf2194552
              vo_result.segment7 := vv_class.class_code;  -- OBE artf2194552
           END IF;
         END IF;
         */

         IF substr(po_info_cle.compte_local, 1, 1) between '1' and '5' THEN
            vo_result.segment7 := '0';
         ELSE

           IF po_info_cle.folio = 'PRE' OR po_info_cle.folio = 'PVR' THEN
                    vo_result.segment7 := vv_class.class_code;
           ELSE

               IF vb_refac THEN
                vo_result.segment7 := vv_class_refac.class_code;
               ELSE
                vo_result.segment7 := vv_class.class_code;
               END IF;

           END IF;

         END IF;
         --> OBE artf2221959

         put_debug_message(lv_current_program_unit || ' 014 : Validation code_affaire : ' ||  vo_result.segment7);
         check_seg_value(vo_result.ledger_id, 'AFFAIRE', vo_result.segment7, 'OAE010');

       END IF; -- OBE artf2194552


       -- Segment8 : Code projet finance
       IF vv_project_info.segment1 IS NOT NULL THEN
         put_debug_message(lv_current_program_unit || ' 015 : Validation projet finance : ' ||  vv_project_info.segment1);
         check_seg_value(vo_result.ledger_id, 'PROJET_FI', vv_project_info.segment1, 'OAE011');
       END IF;

       IF substr(po_info_cle.compte_local, 1, 1) between '1' and '5' THEN -- OBE EDB075
          vo_result.segment8 := '0';                                      -- OBE EDB075
       ELSE                                                               -- OBE EDB075
         IF vb_refac THEN                                           -- OBE artf2171905
          vo_result.segment8 := vv_project_refac_info.segment1;     -- OBE artf2171905
         ELSE                                                       -- OBE artf2171905
          vo_result.segment8 := nvl(vv_project_info.segment1, '0');
         END IF;                                                    -- OBE artf2171905
       END IF;


       -- Segment9 : Code flux
       vo_result.segment9 := '0';

       -- Segment10 : Réserve 1
       vo_result.segment10 := '0';

       -- Segment11 : Réserve 2
       vo_result.segment11 := '0';

       -- Segment12 : Réserve 3
       vo_result.segment12 := '0';


       --< OBE artf2194552
       IF vo_result.segment4 IS NULL THEN
        validate(vo_result.segment4 IS NOT NULL, vv_code_erreur, 'OAE008', 'Erreur : Segment4 n''a pas été déterminé');
       END IF;
       --> OBE artf2194552

       vo_result.code_erreur := vv_code_erreur;
       po_cle_comptable_cuf := vo_result;
       put_debug_message(lv_current_program_unit || ' 999 : FIN');
     EXCEPTION
       WHEN e_main THEN
         po_cle_comptable_cuf := XXEAI_CLE_COMPTABLE_CUF_OBJ(vv_code_erreur, null, null, null, null, null,   null, null, null, null, null,
                                                                             null, null, null, null, null,   null, null, null, null, null,   null);
         put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || vv_code_erreur);
       WHEN OTHERS THEN
         po_cle_comptable_cuf := XXEAI_CLE_COMPTABLE_CUF_OBJ(vv_code_erreur, null, null, null, null, null,   null, null, null, null, null,
                                                                             null, null, null, null, null,   null, null, null, null, null,   null);
         put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Cle_Comptable_CUF;


     -----------------------------------------------------------------
     --  Fonctionnalité 6 : Déterminer la société du projet en liste
     --  Nom           : Get_Societe_Projet_Liste
     --  Description   : Fonction qui retourne dans un objet XXEAI_SOCIETE_LST
     --                  la liste de société du projet a partir d'une liste de code projet.
     --
     --  PARAMETRES :
     --     pt_projet        Entrée      Objet regroupant la liste des codes projet.
     --     po_societe_lst   Sortie      Objet regroupant la liste des codes erreur
     --                  et des sociétés Oracle du projet.
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Societe_Projet_Liste(pt_projet      IN XXEAI_PROJET_TAB,
                                        po_societe_lst IN OUT NOCOPY XXEAI_SOCIETE_LST) IS
       lv_current_program_unit VARCHAR2(30) := 'Get_Societe_Projet_Liste';
       po_societe_tab          XXEAI_SOCIETE_TAB := XXEAI_SOCIETE_TAB();
       po_societe_obj          XXEAI_SOCIETE_OBJ;
       i                       NUMBER;
       vv_code_erreur          VARCHAR2(50) := 'OAE000';
     BEGIN
       i := pt_projet.FIRST;

       put_debug_message(lv_current_program_unit || ' 001 : Parcours de la liste des projets.');
       WHILE i is not null LOOP
         put_debug_message(lv_current_program_unit || ' 001.1 : Recherche de la société pour le projet : ' || pt_projet(i));
         Get_Societe_Projet(pt_projet(i), po_societe_obj);
         put_debug_message(lv_current_program_unit || ' 001.2 : Insertion de la société dans la collection des projets.');
         po_societe_tab.extend;
         po_societe_tab(po_societe_tab.last) := po_societe_obj;
         IF po_societe_obj.CODE_ERREUR != 'OAE000' THEN
           put_debug_message(lv_current_program_unit || ' 001.3 : Erreur détectée dans l''exécution.');
           vv_code_erreur := 'OAE998';
         END IF;
         i := pt_projet.NEXT(i);
       END LOOP;

       po_societe_lst := XXEAI_SOCIETE_LST(vv_code_erreur, po_societe_tab);
       put_debug_message(lv_current_program_unit || ' 999 : FIN');
    EXCEPTION
      WHEN OTHERS THEN
        po_societe_lst := XXEAI_SOCIETE_LST('OAE999', po_societe_tab);
        put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
    END Get_Societe_Projet_Liste;

     -----------------------------------------------------------------
     --  FONCTIONNALITE 7 : DETERMINER LE TYPE DE DEPENSE/EVENEMENT EN LISTE
     --  Nom           : Get_Type_Depense_Evt_Liste
     --  Description   : Fonction qui retourne dans un objet XXEAI_TYP_EVT_DEP_OBJ
     --                  une liste de type de dépense ou d'évenement.
     --
     --  PARAMETRES :
     --     pt_in_dep_evt    Entrée      Objet regroupant la liste des codes PR, codes produits et compte local.
     --     po_typ_evt_dep   Sortie      Objet regroupant Code Erreur et la liste des codes erreurs et type de dépense/évenement
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Type_Depense_Evt_Liste(pt_in_dep_evt  IN XXEAI_IN_TYP_EVT_DEP_TAB,
                                          po_typ_evt_dep IN OUT NOCOPY XXEAI_TYP_EVT_DEP_LST) IS
       lv_current_program_unit VARCHAR2(30) := 'Get_Type_Depense_Evt_Liste';
       po_type_evt_tab          XXEAI_TYP_EVT_DEP_TAB := XXEAI_TYP_EVT_DEP_TAB();
       po_type_evt_obj          XXEAI_TYP_EVT_DEP_OBJ;
       i                        NUMBER;
       vv_code_erreur           VARCHAR2(50) := 'OAE000';
     BEGIN
       i := pt_in_dep_evt.FIRST;

       put_debug_message(lv_current_program_unit || ' 001 : Parcours de la liste des folios.');
       WHILE i is not null LOOP
         put_debug_message(lv_current_program_unit || ' 001.1 : Recherche du type d''évenement pour le folio : ' || pt_in_dep_evt(i).folio);
         Get_Type_Depense_Evenement(pt_in_dep_evt(i), po_type_evt_obj);
         put_debug_message(lv_current_program_unit || ' 001.2 : Insertion du type d''évenement dans la collection.');
         po_type_evt_tab.extend;
         po_type_evt_tab(po_type_evt_tab.last) := po_type_evt_obj;
         IF po_type_evt_obj.CODE_ERREUR != 'OAE000' THEN
           put_debug_message(lv_current_program_unit || ' 001.3 : Erreur détectée dans l''exécution.');
           vv_code_erreur := 'OAE998';
         END IF;
         i := pt_in_dep_evt.NEXT(i);
       END LOOP;

       po_typ_evt_dep := XXEAI_TYP_EVT_DEP_LST(vv_code_erreur, po_type_evt_tab);
       put_debug_message(lv_current_program_unit || ' 999 : FIN');
    EXCEPTION
      WHEN OTHERS THEN
        po_typ_evt_dep := XXEAI_TYP_EVT_DEP_LST('OAE999', po_type_evt_tab);
        put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Type_Depense_Evt_Liste;

     -----------------------------------------------------------------
     -- FONCTIONNALITÉ 8 : DÉTERMINER LA CLÉ COMPTABLE ET LES ÉLÉMENTS DU CUF GL EN LISTE
     --  Nom           : Get_Cle_Comptable_CUF_Liste
     --  Description   : Fonction qui retourne dans un objet XXEAI_TYP_EVT_DEP_OBJ
     --                  les valeurs de chaque segment de la cl comptable et les champs du CUF
     --          GL pour tous les comptes locaux et selon les regles de chaque folio.
     --
     --  PARAMETRES :
     --     pt_info_cle            Entrée      Objet regroupant la liste des Folio Amont, société de l'écriture,
     --                      segmentation, compte local, code partenaire, code projet,
     --                      type de dépense/évenement et quantité.
     --     po_cle_comptable_cuf   Sortie      Objet regroupant Code Erreur et la liste des Code Erreur, Société, Région, Compte local,
     --                      Compte Groupe, Complément groupe, Centre de cout, Code Affaire,
     --                      Code Activité, Flux, Réserve, Contexte du CUF, Id du projet, Type d?évenement,
     --                        Type de dépense, Quantité, Id du projet a refacturer
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Cle_Comptable_CUF_Liste(pt_info_cle          IN XXEAI_INFO_CLE_TAB,
                                           po_cle_comptable_cuf IN OUT NOCOPY XXEAI_CLE_COMPTABLE_CUF_LST) IS
       lv_current_program_unit VARCHAR2(30) := 'Get_Cle_Comptable_CUF_Liste';
       po_cle_comptable_cuf_tab          XXEAI_CLE_COMPTABLE_CUF_TAB := XXEAI_CLE_COMPTABLE_CUF_TAB();
       po_cle_comptable_cuf_obj          XXEAI_CLE_COMPTABLE_CUF_OBJ;
       i                        NUMBER;
       vv_code_erreur           VARCHAR2(50) := 'OAE000';
     BEGIN
       i := pt_info_cle.FIRST;

       put_debug_message(lv_current_program_unit || ' 001 : Parcours de la liste');
       WHILE i is not null LOOP
         put_debug_message(lv_current_program_unit || ' 001.1 : Recherche des infos de clé comptable pour le folio : ' || pt_info_cle(i).folio);
         Get_Cle_Comptable_CUF(pt_info_cle(i), po_cle_comptable_cuf_obj);
         put_debug_message(lv_current_program_unit || ' 001.2 : Insertion du résultat dans la collection.');
         po_cle_comptable_cuf_tab.extend;
         po_cle_comptable_cuf_tab(po_cle_comptable_cuf_tab.last) := po_cle_comptable_cuf_obj;
         IF po_cle_comptable_cuf_obj.CODE_ERREUR != 'OAE000' THEN
           put_debug_message(lv_current_program_unit || ' 001.3 : Erreur détectée dans l''exécution.');
           vv_code_erreur := 'OAE998';
         END IF;
         i := pt_info_cle.NEXT(i);
       END LOOP;

       po_cle_comptable_cuf := XXEAI_CLE_COMPTABLE_CUF_LST(vv_code_erreur, po_cle_comptable_cuf_tab);
       put_debug_message(lv_current_program_unit || ' 999 : FIN');
    EXCEPTION
      WHEN OTHERS THEN
        po_cle_comptable_cuf := XXEAI_CLE_COMPTABLE_CUF_LST('OAE999', po_cle_comptable_cuf_tab);
        put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Cle_Comptable_CUF_Liste;

     ----------------------------------------------------------------------------------------------------
     --  FONCTIONNALITE 9 : DETERMINER L'IDENTIFIANT DE FACTURE/IDENTIFIANT DE LIGNE DE FACTURE.
     --  Nom           : Get_Invoice_Id
     --  Description   : Fonction qui génere dans un identifiant d'entete ou de ligne.
     --
     --  PARAMETRES :
     --     pv_Type            Entrée      valeur type ENTETE / LIGNE
     --
     --  VALEUR RETOURNEE : po_invoice_id
     --     Description       :  Si pv_Type = ENTETE alors génere l'identifiant de la facture
     --               Si pv_Type = LIGNE alors génere l'identifiant de la ligne de facture.
     --     Valeurs possibles :  Identifiant de l'entete/ligne de facture.
     ---------------------------------------------------------------------------------------------------
     PROCEDURE Get_Invoice_Id(pv_Type       IN VARCHAR2,
                              po_invoice_id IN OUT NOCOPY XXEAI_INVOICE_ID) IS
        lv_current_program_unit VARCHAR2(30) := 'Get_Invoice_Id';

        vv_code_erreur VARCHAR2(50) := 'OAE000';
        vn_invoice_id  NUMBER(15);
     BEGIN
        put_debug_message(lv_current_program_unit || ' 001 : Vérifier l''existence des champs obligatoires.');
        not_null('pv_Type', pv_Type, vv_code_erreur);

        put_debug_message(lv_current_program_unit || ' 002 : Vérification du type');
        BEGIN
          IF pv_Type = 'ENTETE' THEN
            put_debug_message(lv_current_program_unit || ' 003 : Type d''identifiant généré "' || pv_Type ||'"');
            vn_invoice_id := APPS.ap_invoices_interface_s.NEXTVAL;
          ELSIF pv_Type = 'LIGNE' THEN
            put_debug_message(lv_current_program_unit || ' 003 : Type d''identifiant généré "' || pv_Type ||'"');
            vn_invoice_id := APPS.ap_invoice_lines_interface_s.NEXTVAL;
          ELSE
            validate(FALSE, vv_code_erreur, 'OAE035', 'Type non pris en charge: ' || pv_Type);
          END IF;
        EXCEPTION
          WHEN e_main THEN
            RAISE;
          WHEN OTHERS THEN
            validate(FALSE, vv_code_erreur, 'OAE023');
        END;

        vv_code_erreur := 'OAE000';
        put_debug_message(lv_current_program_unit || ' 004 : Création Objet');
        po_invoice_id := XXEAI_INVOICE_ID(vv_code_erreur, vn_invoice_id);
        put_debug_message(lv_current_program_unit || ' 999 : FIN');
     EXCEPTION
        WHEN e_main THEN
          po_invoice_id  := XXEAI_INVOICE_ID(vv_code_erreur, NULL);
          put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR');
        WHEN OTHERS THEN
          po_invoice_id  := XXEAI_INVOICE_ID('OAE999', NULL);
          put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Invoice_Id;

     ----------------------------------------------------------------------------------------------------
     --  FONCTIONNALITE 10 : DETERMINER LES INFORMATIONS POUR UN ENTETE DE FACTURE
     --  Nom           : Get_Info_Invoice_Header
     --  Description   : Fonction qui retourne les informations du fournisseur, le type (encaissement/
     --         décaissement), le nom du groupe de paiement et l'identifiant de la clé comptable
     --           pour l'entete de la facture selon les regles de chaque FOLIO.
     --
     --  PARAMETRES :
     --     pt_in_header    Entrée      Objet contenant la liste des informations suivantes:
     --                     Code Folio Oracle
     --                  Identifiant Fournisseur Externe
     --                  Société
     --                    Appartenance
     --                    Taux de TVA
     --                    Compte Local
     --  VALEUR RETOURNEE : po_info_invoice_header
     --     Description       :  Retourne l'ensemble des informations permettant de compléter l'entete de la facture.
     --     Valeurs possibles :  Identifiant du Fournisseur
     --             Identifiant du site fournisseur
     --               Type (Encaissement / Décaissement)
     --               Nom du groupe de paiement
     --               Identifiant de la clé comptable
     --               Type de document
     ---------------------------------------------------------------------------------------------------
     PROCEDURE Get_Info_Invoice_Header(pt_in_header           IN XXEAI_IN_INVOICE_HEADER_TYP,
                                       po_info_invoice_header IN OUT NOCOPY XXEAI_INFO_INVOICE_HEADER_OBJ) IS
       lv_current_program_unit CONSTANT VARCHAR2(30) := 'Get_Info_Invoice_Header';
       vv_code_erreur          VARCHAR2(50) := 'OAE000';
       v_params_folio          cur_flex_value%ROWTYPE;

       cursor cur_supplier_groupe(p_code_part in varchar2) is
       select s.vendor_id, s.segment1, vendor_name, s.vendor_type_lookup_code, sd.*
       from APPS.AP_SUPPLIERS     s
       join APPS.PO_VENDORS_DFV   sd on (sd.row_id = s.rowid)
       where sysdate between nvl(s.START_DATE_ACTIVE, sysdate) and nvl(s.END_DATE_ACTIVE, sysdate+1)
         and s.ENABLED_FLAG='Y'
         and s.pay_group_lookup_code like 'GROUPE%'
         and sd.code_part = p_code_part;

       cursor cur_supplier_oracle(p_segment1 in varchar2) is
       select s.vendor_id, s.segment1, vendor_name, s.vendor_type_lookup_code, sd.*
       from APPS.AP_SUPPLIERS     s
       join APPS.PO_VENDORS_DFV   sd on (sd.row_id = s.rowid)
       where sysdate between nvl(s.START_DATE_ACTIVE, sysdate) and nvl(s.END_DATE_ACTIVE, sysdate+1)
         and s.ENABLED_FLAG='Y'
         and s.SEGMENT1 = p_segment1;

       cursor cur_supplier_site(
         p_vendor_id        in APPS.AP_SUPPLIER_SITES_ALL.vendor_id%TYPE,
         p_vendor_site_code in APPS.AP_SUPPLIER_SITES_ALL.vendor_site_code%TYPE,
         p_org_id           in APPS.AP_SUPPLIER_SITES_ALL.org_id%TYPE) is
       select ss.*
       from APPS.AP_SUPPLIER_SITES_ALL     ss
       where nvl(ss.INACTIVE_DATE, sysdate+1) > sysdate
         and ss.PAY_SITE_FLAG='Y'
         and ss.vendor_id = p_vendor_id
         and ss.vendor_site_code = nvl(p_vendor_site_code,ss.vendor_site_code)
         and (ss.org_id = p_org_id or p_org_id is null)
       order by ss.creation_date desc, vendor_site_id desc;

       v_task                  APPS.PA_TASKS%ROWTYPE;
       v_project               APPS.PA_PROJECTS%ROWTYPE;
       v_supplier              cur_supplier_groupe%ROWTYPE;
       v_supplier_grp          cur_supplier_groupe%ROWTYPE;
       v_supplier_site         cur_supplier_site%ROWTYPE;
       v_vendor_site_code      APPS.AP_SUPPLIER_SITES_ALL.vendor_site_code%TYPE;
       v_uo_id                 NUMBER;
       vb_fournisseur_groupe   BOOLEAN;
       vb_fournisseur          BOOLEAN;
       v_global_attribute1     varchar2(100);

     BEGIN
       put_debug_message(lv_current_program_unit || ' 000 : DEBUT');
       put_debug_message(lv_current_program_unit || ' 001 : Vérifier l''existence des champs obligatoires.');
       not_null('FOLIO',                pt_in_header.FOLIO, vv_code_erreur);
       not_null('ID_FRS_EXT',           pt_in_header.ID_FRS_EXT, vv_code_erreur);
       not_null('UO',                   pt_in_header.UO, vv_code_erreur);
       not_null('TACHE_PROJET_FINANCE', pt_in_header.TACHE_PROJET_FINANCE, vv_code_erreur);
       not_null('DATE_FACTURE',         pt_in_header.DATE_FACTURE, vv_code_erreur);

       -- Folio
       put_debug_message(lv_current_program_unit || ' 002 : Recherche des informations sur le folio : ' || pt_in_header.FOLIO);
       begin
         v_params_folio := my_get_params_folio_ap(pt_in_header.FOLIO);
       exception
         when no_data_found then
           validate(FALSE, vv_code_erreur, 'OAE015');
       end;

       -- fournisseur
       put_debug_message(lv_current_program_unit || ' 003 : Recherche du fournisseur : ' || pt_in_header.ID_FRS_EXT);
       vb_fournisseur_groupe := FALSE;
       vb_fournisseur        := FALSE;
       v_supplier_grp        := NULL;
       v_supplier            := NULL;

       if v_params_folio.TYPE_FOURNISSEUR = 'ORACLE' then
         if length(pt_in_header.ID_FRS_EXT) = 4 then
           -- fournisseur groupe
           put_debug_message(lv_current_program_unit || ' 004 : recherche d''un fournisseur groupe');
           open cur_supplier_groupe(pt_in_header.ID_FRS_EXT);
           fetch cur_supplier_groupe into v_supplier_grp;
           if cur_supplier_groupe%NOTFOUND then
             put_debug_message(lv_current_program_unit || ' 004 : Fournisseur Groupe non trouvé ' || pt_in_header.ID_FRS_EXT);
             --validate(FALSE, vv_code_erreur, 'OAE024');
           ELSE
             vb_fournisseur_groupe := TRUE;
           end if;
           close cur_supplier_groupe;
         end if;

         put_debug_message(lv_current_program_unit || ' 004 : Recherche d''un fournisseur oracle');
         open cur_supplier_oracle(NVL(SUBSTR(pt_in_header.ID_FRS_EXT, 1, INSTR(pt_in_header.ID_FRS_EXT, '-') - 1),pt_in_header.ID_FRS_EXT));--YWA artf2085619
         fetch cur_supplier_oracle into v_supplier;
         if cur_supplier_oracle%NOTFOUND then
           put_debug_message(lv_current_program_unit || ' 004 : Fournisseur non trouvé ' || pt_in_header.ID_FRS_EXT);
         ELSE
           vb_fournisseur := TRUE;
           --validate(FALSE, vv_code_erreur, 'OAE024', lv_current_program_unit || ' 004 : Fournisseur non trouvé ' || pt_in_header.ID_FRS_EXT);
         end if;
         close cur_supplier_oracle;

         IF vb_fournisseur_groupe and vb_fournisseur THEN
          v_supplier := v_supplier_grp;
         ELSIF vb_fournisseur_groupe THEN
          v_supplier := v_supplier_grp;
         ELSIF vb_fournisseur THEN
          v_supplier := v_supplier;
         ELSE
          validate(FALSE, vv_code_erreur, 'OAE024', lv_current_program_unit || ' 004 : Fournisseur non trouvé ' || pt_in_header.ID_FRS_EXT);
         END IF;

         put_debug_message(lv_current_program_unit || ' 004 : recherche de la tâche du projet : ' || pt_in_header.TACHE_PROJET_FINANCE);
         v_task := get_task(p_task_number => pt_in_header.TACHE_PROJET_FINANCE);
         --validate(v_task.task_id is not null, vv_code_erreur, 'OAE007');
         v_project := get_project(p_project_id => v_task.project_id);
         --validate(v_project.project_id is not null, vv_code_erreur, 'OAE007');

       else
         validate(FALSE, vv_code_erreur, 'OAE026', 'Non pris en charge : ' || v_params_folio.TYPE_FOURNISSEUR);
       end if;


       -- site fournisseur
       SELECT SUBSTR(pt_in_header.ID_FRS_EXT, decode(INSTR(pt_in_header.ID_FRS_EXT, '-') + 1,1,NULL,INSTR(pt_in_header.ID_FRS_EXT, '-') + 1))
       INTO v_vendor_site_code
       FROM DUAL;--YWA artf2085619

       --< OBE artf2159071
       put_debug_message(lv_current_program_unit || ' 005 : Recherche de l''id UO : ' || pt_in_header.UO);
       BEGIN
          SELECT organization_id INTO v_uo_id FROM APPS.HR_ALL_ORGANIZATION_UNITS where name = pt_in_header.UO;
       EXCEPTION
          WHEN OTHERS THEN
          Validate(FALSE, vv_code_erreur, 'OAE044',lv_current_program_unit||' 005 : UO non trouvée' );
       END;

       IF v_project.project_id IS NOT NULL AND v_uo_id = v_project.org_id THEN
        v_uo_id := v_project.org_id;
       END IF;

       /*
       IF v_project.project_id IS NULL THEN --YWA artf2085619
        put_debug_message(lv_current_program_unit || ' 005 : Recherche de l''id UO : ' || pt_in_header.UO);
        BEGIN
            SELECT organization_id INTO v_uo_id FROM APPS.HR_ALL_ORGANIZATION_UNITS where name = pt_in_header.UO;
        EXCEPTION
            WHEN OTHERS THEN
            Validate(FALSE, vv_code_erreur, 'OAE044',lv_current_program_unit||' 005 : UO non trouvée' );
        END;
       ELSE
        --UO du projet
        v_uo_id := v_project.org_id;
       END IF;
       */
       --> OBE artf2159071

       put_debug_message(lv_current_program_unit || ' 003 : Recherche du site fournisseur : ' || v_supplier.segment1 || ', ' || v_vendor_site_code || ', '||v_uo_id);
       open cur_supplier_site(v_supplier.vendor_id, v_vendor_site_code, v_uo_id);--YWA artf2085619
       fetch cur_supplier_site into v_supplier_site;
       if cur_supplier_site%NOTFOUND then
         close cur_supplier_site;
         validate(FALSE, vv_code_erreur, 'OAE025');
       end if;
       close cur_supplier_site;

       v_global_attribute1 := case v_supplier.fournisseur_services when 'Y' then 'CRE/M' else 'DEB/M' end;

       po_info_invoice_header := XXEAI_INFO_INVOICE_HEADER_OBJ(vv_code_erreur, v_supplier.vendor_id, v_supplier_site.vendor_site_id, v_global_attribute1,
         v_supplier_site.pay_group_lookup_code, v_supplier_site.accts_pay_code_combination_id, v_params_folio.nom_application, v_uo_id/*v_supplier_site.org_id*/); -- OBE artf2159071
       put_debug_message(lv_current_program_unit || ' 999 : FIN');
     EXCEPTION
       WHEN e_main THEN
         po_info_invoice_header := XXEAI_INFO_INVOICE_HEADER_OBJ(vv_code_erreur, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
         put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR');
       WHEN OTHERS THEN
         po_info_invoice_header := XXEAI_INFO_INVOICE_HEADER_OBJ(vv_code_erreur, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
         put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Info_Invoice_Header;

     ----------------------------------------------------------------------------------------------------
     --  FONCTIONNALITE 11 : DETERMINER LES VALEURS CONSTANTES DU FLUX AP
     --  Nom           : Get_Params_FOLIO_AP
     --  Description   : Fonction qui retourne l'ensemble des valeurs constantes du flux pour un folio déterminé.
     --
     --  PARAMETRES :
     --     pv_Folio    Entrée      Code Folio Amont
     --  VALEUR RETOURNEE : po_cst_flux_ap
     --     Description       :  Retourne l'ensemble des constantes du flux.
     --     Valeurs possibles :  Code Erreur
     --             Code devise de la facture
     --               Code folio Oracle
     --               Catégorie de la structure du CUF dépendant de la localisation
     --               Origine de la facture
     --               Type de taux dérivés
     --               Taux dérivés
     --               Devise de reglement
     --               Nom de l'application permettant de déterminer le Type de document.
     --               Identifiant de l'organisation.
     ---------------------------------------------------------------------------------------------------
     PROCEDURE Get_Params_FOLIO_AP(pv_Folio       IN VARCHAR2,
                                   po_cst_flux_ap IN OUT NOCOPY XXEAI_CST_FLUX_AP_OBJ) IS
        lv_current_program_unit      CONSTANT VARCHAR2(30) := 'Get_Params_FOLIO_AP';
        vv_code_erreur               VARCHAR2(50) := 'OAE000';

        vv_params_folio              cur_flex_value%ROWTYPE;
      BEGIN
        put_debug_message(lv_current_program_unit || ' 000 : DEBUT');
        put_debug_message(lv_current_program_unit || ' 001 : Vérifier l''existence des champs obligatoires.');
        not_null('pv_Folio',  pv_Folio, vv_code_erreur);

        put_debug_message(lv_current_program_unit || ' 001 : Recherche des valeurs constantes du flux pour le folio ' || pv_FOLIO);
        vv_params_folio := my_get_params_folio_ap(pv_folio);
        validate(vv_params_folio.flex_value is not null, vv_code_erreur, 'OAE001');

        put_debug_message(lv_current_program_unit || ' 003 : Création Objet');
        po_cst_flux_ap := XXEAI_CST_FLUX_AP_OBJ('OAE000',
          vv_params_folio.INVOICE_CURRENCY_CODE, vv_params_folio.CODE_FOLIO, vv_params_folio.GLOBAL_ATTRIBUTE_CATEGORY, vv_params_folio.SOURCE,
          vv_params_folio.PAYMENT_CROSS_RATE_TYPE, vv_params_folio.PAYMENT_CROSS_RATE, vv_params_folio.PAYMENT_CURRENCY_CODE);
        put_debug_message(lv_current_program_unit || ' 999 : FIN');
     EXCEPTION
        WHEN e_main THEN
          po_cst_flux_ap  := XXEAI_CST_FLUX_AP_OBJ(vv_code_erreur, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
          put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR');
        WHEN OTHERS THEN
            po_cst_flux_ap := XXEAI_CST_FLUX_AP_OBJ('OAE001', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
            put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Params_FOLIO_AP;

     ----------------------------------------------------------------------------------------------------
     --  FONCTIONNALITE 12 : DETERMINER LES INFORMATIONS POUR UNE LIGNE DE FACTURE
     --  Nom           : Get_Info_Invoice_Line
     --  Description   : Fonction qui retourne les informations pour les lignes de facture selon les regles de chaque Folio
     --
     --  PARAMETRES :
     --     pt_info_line    Entrée      Objet contenant la liste des informations suivantes:
     --                     Code FOLIO Oracle
     --                     Code du Projet / Appartenance
     --                     Nature1
     --                     Nature2
     --                     Identifiant Fournisseur Externe
     --                     Société
     --                     Compte Local
     --                     Taux de TVA
     --                     Date Comptable
     --  VALEUR RETOURNEE : po_info_invoice_line
     --     Description       :  Retourne l'ensemble des informations permettant de compléter l'entete de la facture.
     --     Valeurs possibles :  Code erreur
     --                Type de ligne de ventilation
     --                Identifiant de la clé comptable
     --                Catégorie de structure
     --                Identifiant du projet de refacturation
     --                Identifiant du projet
     --                Identifiant de tâche
     --                Type de dépense
     --                Identifiant de l?organisation de dépense
     --                Code de TAX
     ---------------------------------------------------------------------------------------------------
     PROCEDURE Get_Info_Invoice_Line(pt_info_line         IN XXEAI_IN_INVOICE_LINE_TYP,
                                     po_info_invoice_line IN OUT NOCOPY XXEAI_INFO_INVOICE_LINE_OBJ) IS
        lv_current_program_unit      CONSTANT VARCHAR2(30) := 'Get_Info_Invoice_Line';
        vv_code_erreur               VARCHAR2(50) := 'OAE000';
        v_result                     XXEAI_INFO_INVOICE_LINE_OBJ := XXEAI_INFO_INVOICE_LINE_OBJ(null, null, null, null, null, null,   null, null, null, null, null);
        v_flex_value                 cur_flex_value%rowtype;
        vv_task_info                 APPS.PA_TASKS%ROWTYPE;
        vv_project_info              APPS.PA_PROJECTS_ALL%ROWTYPE;
        vn_ledger_id                 NUMBER;
        vv_code_societe              VARCHAR2(40);
        vv_code_region               VARCHAR2(40); -- Region passée en paramètre
        vv_compte_analytique         VARCHAR2(40);
        vv_project_refac_info        APPS.PA_PROJECTS_ALL%ROWTYPE;
        vv_tache_refac_info          APPS.PA_TASKS%ROWTYPE;
        vo_typ_evt_dep               XXEAI_TYP_EVT_DEP_OBJ;
    vv_caractere_tax             VARCHAR2(1); -- OBE artf2408078

     BEGIN
       put_debug_message(lv_current_program_unit || ' 000 : DEBUT');
       put_debug_message(lv_current_program_unit || ' 001 : Vérifier l''existence des champs obligatoires.');
       not_null('FOLIO_ORACLE',          pt_info_line.FOLIO_ORACLE, vv_code_erreur);
       not_null('TACHE_PROJET',          pt_info_line.TACHE_PROJET, vv_code_erreur);
       --not_null('NATURE1',               pt_info_line.NATURE1, vv_code_erreur);--YWA artf2085619
       not_null('SOCIETE',               pt_info_line.SOCIETE, vv_code_erreur);
       not_null('REGION',                pt_info_line.REGION, vv_code_erreur);
       not_null('COMPTE_LOCAL',          pt_info_line.COMPTE_LOCAL, vv_code_erreur);
       not_null('TAX_RATE',              pt_info_line.TAX_RATE, vv_code_erreur);
       not_null('DATE_FACTURE',          pt_info_line.DATE_FACTURE, vv_code_erreur);
       not_null('REGIME_TVA',            pt_info_line.REGIME_TVA, vv_code_erreur);


       --Type de ligne de ventilation.  Si le compte local est présent dans le jeu de valeurs DKA_LOCAL_ACCOUNT_DIVERS (cf. §5.1.1), le type de ligne de ventilation aura la valeur 'MISCELLANEOUS'.
        -- Si le compte local commence par la valeur '4' le type de ligne de ventilation aura la valeur 'TAX'.
        -- Sinon le type de ligne aura la valeur 'ITEM'.
       put_debug_message(lv_current_program_unit || ' 002 : Type de ligne de ventilation');
       v_flex_value := get_flex_value('DKA_LOCAL_ACCOUNT_DIVERS', pt_info_line.COMPTE_LOCAL);
       if v_flex_value.flex_value_id is not null then
         v_result.LINE_TYPE_LOOKUP_CODE := 'MISCELLANEOUS';
       elsif pt_info_line.COMPTE_LOCAL like '4%' then
         v_result.LINE_TYPE_LOOKUP_CODE := 'TAX';
       else

         v_result.LINE_TYPE_LOOKUP_CODE := 'ITEM';
         not_null('NATURE1',               pt_info_line.NATURE1, vv_code_erreur);--YWA artf2085619
       end if;

       put_debug_message(lv_current_program_unit || ' 003 : Recherche de la tâche et du projet finance : ' || pt_info_line.TACHE_PROJET);
       vv_task_info := get_task(p_task_number => pt_info_line.TACHE_PROJET);
       validate(vv_task_info.task_id is not null, vv_code_erreur, 'OAE011');
       vv_project_info := get_project(p_project_id => vv_task_info.project_id);
       validate(vv_project_info.project_id is not null, vv_code_erreur, 'OAE002');

       -- société du projet
       put_debug_message(lv_current_program_unit || ' 004 : Recherche de la société du projet : ' || vv_project_info.segment1);
       vv_code_societe := apps.dka_spaautoaccounting_pkg.societe_projet(pn_project_id => vv_project_info.project_id);
       validate(vv_code_societe is not null, vv_code_erreur, 'OAE007');

       put_debug_message(lv_current_program_unit || ' 005 : Recherche de la région du projet : ' || vv_project_info.segment1);
       vv_code_region := apps.dka_spaautoaccounting_pkg.uo_projet(pn_project_id => vv_project_info.project_id);
       validate(vv_code_region is not null, vv_code_erreur, 'OAE007');

       -- Identifiant de la clé comptable Si le type de ligne est Divers (MISCELLANEOUS), la clé comptable aura la valeur comme précisé ci- dessous.
       -- Si le type de ligne est différent de Divers (Montant HT, TVA), le champ sera vide.
       if v_result.LINE_TYPE_LOOKUP_CODE = 'MISCELLANEOUS' then
         put_debug_message(lv_current_program_unit || ' 006 : recherche du livre de la société ' || pt_info_line.SOCIETE);
         vn_ledger_id := APPS.DKA_GL_TOOLS_PKG.get_legder_id(pt_info_line.SOCIETE);
         validate(vn_ledger_id is not null, vv_code_erreur, 'OAE008');

         put_debug_message(lv_current_program_unit || ' 006 : recherche transco compte local -> compte analytique : ' || pt_info_line.compte_local);
         vv_compte_analytique := APPS.dka_stransco_pkg.etl_get_value_f('MIGR_GROUP_ACCOUNT_CLASS_BILAN',  sysdate, pt_info_line.compte_local);
         validate(check_segment_value(vn_ledger_id, 'COMPTE_ANALYTIQUE', vv_compte_analytique), vv_code_erreur, 'OAE008');

         put_debug_message(lv_current_program_unit || ' 006 : Identifiant de la clé comptable');
         v_result.DIST_CODE_COMBINATION_ID := get_code_combination_id (
           pv_segment1              => pt_info_line.SOCIETE,
           pv_segment2              => vv_code_region,
           pv_segment3              => pt_info_line.COMPTE_LOCAL,
           pv_segment4              => vv_compte_analytique,
           pv_segment5              => '0',
           pv_segment6              => '0',
           pv_segment7              => '0',
           pv_segment8              => '0',
           pv_segment9              => '0',
           pv_segment10             => '0',
           pv_segment11             => '0',
           pv_segment12             => '0');
         validate(v_result.DIST_CODE_COMBINATION_ID is not null, vv_code_erreur, 'OAE031');
       end if;

       IF v_result.LINE_TYPE_LOOKUP_CODE = 'ITEM' then
         -- Est-ce un cas de refac ?
         IF vv_code_societe != pt_info_line.SOCIETE THEN
           put_debug_message(lv_current_program_unit || ' 007 : Recherche du projet de refac : ' || pt_info_line.REGION || pt_info_line.societe);
           vv_project_refac_info := get_project(p_project_code => pt_info_line.REGION || pt_info_line.societe);
           vv_tache_refac_info := get_task(vv_project_refac_info.project_id, 1);
           validate(vv_project_refac_info.project_id is not null, vv_code_erreur, 'OAE013');
           v_result.ATTRIBUTE1                  := vv_project_info.project_id; -- vv_project_refac_info.project_id; -- OBE artf2159071
           v_result.ATTRIBUTE7                  := vv_task_info.task_id;
           v_result.PROJECT_ID                  := vv_project_refac_info.project_id;
           v_result.TASK_ID                     := vv_tache_refac_info.task_id;
           v_result.EXPENDITURE_ORGANIZATION_ID := vv_project_refac_info.CARRYING_OUT_ORGANIZATION_ID; --YWA artf2216107
         ELSE
           v_result.PROJECT_ID                  := vv_project_info.project_id;
           v_result.EXPENDITURE_ORGANIZATION_ID := vv_project_info.CARRYING_OUT_ORGANIZATION_ID;
           v_result.TASK_ID                     := vv_task_info.task_id;
         END IF;

         -- type de dépense
         put_debug_message(lv_current_program_unit || ' 008 : Recherche du type de dépense : ' ||
           pt_info_line.FOLIO_ORACLE || ', ' || pt_info_line.COMPTE_LOCAL || ', ' || pt_info_line.NATURE1 || ', ' || pt_info_line.NATURE2);
         Get_Type_Depense_Evenement(XXEAI_IN_TYP_EVT_DEP_TYP(pt_info_line.FOLIO_ORACLE, pt_info_line.NATURE1, pt_info_line.NATURE2, pt_info_line.COMPTE_LOCAL),
                                   vo_typ_evt_dep);
         validate(nvl(vo_typ_evt_dep.CODE_ERREUR, 'OAE000') = 'OAE000', vv_code_erreur, vo_typ_evt_dep.CODE_ERREUR, 'Code erreur ' || vo_typ_evt_dep.CODE_ERREUR);
         v_result.EXPENDITURE_TYPE := vo_typ_evt_dep.TYPE_DEP_EVT;
       end if;      -- v_result.LINE_TYPE_LOOKUP_CODE = 'ITEM'

       -- Si le type de ligne a la valeur TAX alors le champ TAX_CODE sera déterminé. On concatenera les informations suivantes :
       --   DED_ + le taux avec un point en séparateur +(Si le régime fiscal est CRE/M alors E si le régime fiscal est  DEB/M alors D).
       if v_result.LINE_TYPE_LOOKUP_CODE = 'TAX' then
         put_debug_message(lv_current_program_unit || ' 009 : Détermination du code de taxe : ' || pt_info_line.TAX_RATE ||', ' || pt_info_line.REGIME_TVA);

          IF pt_info_line.REGIME_TVA IN ('CRE/M','DEB/M') THEN  --RBE artf2097270

        --< OBE artf2408078
        IF vv_task_info.task_number like 'GY%' THEN
        vv_caractere_tax := 'I';
      ELSE
        vv_caractere_tax := NULL;
      END IF;
        --> OBE artf2408078

            v_result.TAX_CODE := 'DED_' ||
                                 to_char(pt_info_line.TAX_RATE, 'FM00.00') ||
                                 vv_caractere_tax ||
                                 case pt_info_line.REGIME_TVA
                                  when 'CRE/M' then 'E'
                                  when 'DEB/M' then 'D'
                                  else '?'
                                 end;
          ELSE
            v_result.TAX_CODE := pt_info_line.REGIME_TVA; --RBE artf2097270
          END IF;

          validate(tax_code_exists(v_result.TAX_CODE,pt_info_line.TAX_RATE), vv_code_erreur, 'OAE034'); --RBE artf2097270

       END IF;      -- v_result.LINE_TYPE_LOOKUP_CODE = 'TAX'


      -- Catégorie de structure. Ce champ n'est pas renseigné dans la table d'interface AP.
       v_result.ATTRIBUTE_CATEGORY := null;

       put_debug_message(lv_current_program_unit || ' 010 : Création Objet');
       v_result.CODE_ERREUR := vv_code_erreur;
       po_info_invoice_line := v_result;
       put_debug_message(lv_current_program_unit || ' 999 : FIN');

     EXCEPTION
       WHEN e_main THEN
         po_info_invoice_line := XXEAI_INFO_INVOICE_LINE_OBJ(vv_code_erreur, null, null, null, null, null,   null, null, null, null, null); -- OBE
         put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR');
       WHEN OTHERS THEN
         po_info_invoice_line := XXEAI_INFO_INVOICE_LINE_OBJ('OAE999',null , null, null, null, null,   null, null, null, null, null); -- OBE
         put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Info_Invoice_Line;

     -----------------------------------------------------------------
     --  FONCTIONNALITE 13 : DETERMINER LES INFORMATIONS POUR DES ENTETES DE FACTURE EN LISTE
     --  Nom           : Get_Info_Invoice_Header_Liste
     --  Description   : Fonction qui retourne la liste de valeurs des informations fournisseurs,
     --           les types (encaissement/décaissement), les noms de groupe de paiement et
     --           les identifiants de clé comptable en fonction de la liste de parametres en entrée.
     --
     --  PARAMETRES :
     --     pt_info_header_tab   Entrée      Objet contenant un tableau d'objet
     --     po_info_header_lst   Sortie      Objet contenant une liste d'objet XXEAI_INFO_INVOICE_HEADER_TAB
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Info_Invoice_Header_Liste(pt_info_header_tab IN XXEAI_IN_INVOICE_HEADER_TAB,
                                             po_info_header_lst IN OUT NOCOPY XXEAI_INFO_INVOICE_HEADER_LST) IS
       lv_current_program_unit VARCHAR2(30) := 'Get_Info_Invoice_Header_Liste';
       po_info_header_tab          XXEAI_INFO_INVOICE_HEADER_TAB := XXEAI_INFO_INVOICE_HEADER_TAB();
       po_info_header_obj          XXEAI_INFO_INVOICE_HEADER_OBJ;
       i                        NUMBER;
       vv_code_erreur           VARCHAR2(50) := 'OAE000';
     BEGIN
       i := pt_info_header_tab.FIRST;

       put_debug_message(lv_current_program_unit || ' 001 : Parcours de la liste');
       WHILE i is not null LOOP
         put_debug_message(lv_current_program_unit || ' 001.1 : Recherche des infos fature pour  : ' ||
         pt_info_header_tab(i).FOLIO || ',' || pt_info_header_tab(i).ID_FRS_EXT || ', ' || pt_info_header_tab(i).UO);
         Get_Info_Invoice_Header(pt_info_header_tab(i), po_info_header_obj);
         put_debug_message(lv_current_program_unit || ' 001.2 : Insertion du résultat dans la collection.');
         po_info_header_tab.extend;
         po_info_header_tab(po_info_header_tab.last) := po_info_header_obj;
         IF po_info_header_obj.CODE_ERREUR != 'OAE000' THEN
           put_debug_message(lv_current_program_unit || ' 001.3 : Erreur détectée dans l''exécution.');
           vv_code_erreur := 'OAE998';
         END IF;
         i := pt_info_header_tab.NEXT(i);
       END LOOP;

       po_info_header_lst := XXEAI_INFO_INVOICE_HEADER_LST(vv_code_erreur, po_info_header_tab);
       put_debug_message(lv_current_program_unit || ' 999 : FIN');
    EXCEPTION
      WHEN OTHERS THEN
        po_info_header_lst := XXEAI_INFO_INVOICE_HEADER_LST('OAE999', po_info_header_tab);
        put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Info_Invoice_Header_Liste;

     -----------------------------------------------------------------
     --  FONCTIONNALITE 14 : DETERMINER LES INFORMATIONS POUR LES LIGNES DE FACTURE EN LISTE
     --  Nom           : Get_Info_Invoice_Line_Liste
     --  Description   : Fonction qui retourne la liste de valeurs des informations pour les
     --           lignes de facture en fonction de la liste de parametres en entrée.
     --
     --  PARAMETRES :
     --     pt_info_line_tab     Entrée        Objet contenant un tableau d'objet
     --     po_info_line_lst     Sortie        Objet contenant une liste d'objet XXEAI_INFO_INVOICE_LINE_LST
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Info_Invoice_Line_Liste(pt_info_line_tab IN XXEAI_IN_INVOICE_LINE_TAB,
                                           po_info_line_lst IN OUT NOCOPY XXEAI_INFO_INVOICE_LINE_LST) IS
       lv_current_program_unit VARCHAR2(30) := 'Get_Info_Invoice_Line_Liste';
       po_info_line_tab          XXEAI_INFO_INVOICE_LINE_TAB := XXEAI_INFO_INVOICE_LINE_TAB();
       po_info_line_obj          XXEAI_INFO_INVOICE_LINE_OBJ;
       i                        NUMBER;
       vv_code_erreur  VARCHAR2(50) := 'OAE000';
     BEGIN
       i := pt_info_line_tab.FIRST;

       put_debug_message(lv_current_program_unit || ' 001 : Parcours de la liste');
       WHILE i is not null LOOP
         put_debug_message(lv_current_program_unit || ' 001.1 : Recherche des infos ligne pour  : ' ||
           pt_info_line_tab(i).FOLIO_ORACLE || ', '|| pt_info_line_tab(i).TACHE_PROJET || ', '|| pt_info_line_tab(i).NATURE1 || ', '||
           pt_info_line_tab(i).NATURE2 || ', '|| pt_info_line_tab(i).SOCIETE || ', '|| pt_info_line_tab(i).COMPTE_LOCAL);
         Get_Info_Invoice_Line(pt_info_line_tab(i), po_info_line_obj);
         put_debug_message(lv_current_program_unit || ' 001.2 : Insertion du résultat dans la collection.');
         po_info_line_tab.extend;
         po_info_line_tab(po_info_line_tab.last) := po_info_line_obj;
         IF po_info_line_obj.CODE_ERREUR != 'OAE000' THEN
           put_debug_message(lv_current_program_unit || ' 001.3 : Erreur détectée dans l''exécution.');
           vv_code_erreur := 'OAE998';
         END IF;
         i := pt_info_line_tab.NEXT(i);
       END LOOP;

       po_info_line_lst := XXEAI_INFO_INVOICE_LINE_LST(vv_code_erreur, po_info_line_tab);
       put_debug_message(lv_current_program_unit || ' 999 : FIN');
    EXCEPTION
      WHEN OTHERS THEN
        po_info_line_lst := XXEAI_INFO_INVOICE_LINE_LST('OAE999', po_info_line_tab);
        put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Info_Invoice_Line_Liste;

     -----------------------------------------------------------------
     --  FONCTIONNALITE 15 : DETERMINER L'IDENTIFIANT DE FACTURE/IDENTIFIANT DE LIGNE DE FACTURE EN LISTE
     --  Nom           : Get_Invoice_Id_Liste
     --  Description   : Fonction qui retourne la liste de valeurs des nouveaux identifiants de factures
     --           ou des nouveaux identifiants de lignes de factures suivant la liste de parametres en entrée.
     --
     --  PARAMETRES :
     --     pt_type         Entrée        Objet contenant un tableau d'objet
     --     po_invoice_id_lst     Sortie        Objet contenant une liste d'objet XXEAI_INVOICE_ID_LST
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Invoice_Id_Liste(pt_type           IN XXEAI_TYPE_ENTETE_LIGNE_TAB,
                                    po_invoice_id_lst IN OUT NOCOPY XXEAI_INVOICE_ID_LST) IS
       lv_current_program_unit VARCHAR2(30) := 'Get_Invoice_Id_Liste';
       po_invoice_id_tab       XXEAI_INVOICE_ID_TAB := XXEAI_INVOICE_ID_TAB();
       po_invoice_id           XXEAI_INVOICE_ID;
       i                       NUMBER;
       vv_code_erreur  VARCHAR2(50) := 'OAE000';
     BEGIN
       i := pt_type.FIRST;

       put_debug_message(lv_current_program_unit || ' 001 : Parcours de la liste des types.');
       WHILE i is not null LOOP
         put_debug_message(lv_current_program_unit || ' 001.1 : Récupération de l''identifiant : ' || pt_type(i));
         Get_Invoice_Id(pt_type(i), po_invoice_id);
         po_invoice_id_tab.extend;
         po_invoice_id_tab(po_invoice_id_tab.last) := po_invoice_id;
         IF po_invoice_id.CODE_ERREUR != 'OAE000' THEN
           put_debug_message(lv_current_program_unit || ' 001.3 : Erreur détectée dans l''exécution.');
           vv_code_erreur := 'OAE998';
         END IF;
         i := pt_type.NEXT(i);
       END LOOP;

       po_invoice_id_lst := XXEAI_INVOICE_ID_LST(vv_code_erreur, po_invoice_id_tab);
       put_debug_message(lv_current_program_unit || ' 999 : FIN');
     EXCEPTION
       WHEN OTHERS THEN
         po_invoice_id_lst := XXEAI_INVOICE_ID_LST('OAE999', po_invoice_id_tab);
         put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Invoice_Id_Liste;

     -----------------------------------------------------------------
     --  FONCTIONNALITE 16 : DÉTERMINER LES TYPE ET NUMERO DE LIGNE ET LE TYPE DE MOUVEMENT AR
     --  Nom           : Get_type_num_ligne_mvt_AR
     --  Description   : Cette fonction sert a retourner le type de ligne, le numéro de ligne et le type de mouvement d'une
     --                  facture AR en fonction du compte local, du sous compte, du signe, du débit/crédit et du montant
     --                  fournis par les amonts.
     --
     --  PARAMETRES :
     --     pt_in_info_ligne         Entrée        Objet contenant le compte local, le sous-compte, le signe, Débit/crédit, et le montant
     --     po_info_ligne_mvt_ar     Sortie        Objet contenant le code erreur, le type de ligne, le numéro de ligne et le type de mouvement
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_type_num_ligne_mvt_AR(pt_in_info_ligne     IN XXEAI_IN_LIGNE_MVT_AR_TYP,
                                         po_info_ligne_mvt_ar IN OUT NOCOPY XXEAI_TYPE_AR_OBJ) IS
        lv_current_program_unit VARCHAR2(30) := 'Get_type_num_ligne_mvt_AR';

        -- valeurs retournées --
        vv_code_erreur  VARCHAR2(50) := 'OAE000';         -- Code Erreur
        vv_line_type      VARCHAR2(25);         -- Type de ligne
        vn_line_num       NUMBER(15);           -- Numéro de ligne
        vv_type_mvt       VARCHAR2(50);         -- Type de mouvement
     BEGIN
        put_debug_message(lv_current_program_unit || ' 001 : Début');
        not_null('COMPTE_LOCAL', pt_in_info_ligne.COMPTE_LOCAL, vv_code_erreur);

        -- détermination du LINE_TYPE :
        if pt_in_info_ligne.COMPTE_LOCAL like '411%' and pt_in_info_ligne.SOUS_COMPTE is not null then
          vv_line_type := 'CLIENT';
        elsif substr(pt_in_info_ligne.COMPTE_LOCAL, 1, 1) in ('1', '6', '7') and pt_in_info_ligne.COMPTE_LOCAL not like '165%' THEN
          vv_line_type := 'PRODUIT';
        elsif pt_in_info_ligne.COMPTE_LOCAL like '4457%' THEN
          vv_line_type := 'GESTION';
        elsif pt_in_info_ligne.COMPTE_LOCAL like '467%' or pt_in_info_ligne.COMPTE_LOCAL like '165%' THEN
          vv_line_type := 'SURTAXE';
        else
          validate(FALSE, vv_code_erreur, 'OAE038', 'Impossible de déterminer le type de ligne AR. Compte local=' || pt_in_info_ligne.COMPTE_LOCAL); -- OBE artf2470550
        end if;

        -- détermination du LINE_NUMBER :
        vn_line_num := case vv_line_type
          when 'CLIENT'  THEN 0
          when 'PRODUIT' THEN 1
          when 'GESTION' THEN 2
          when 'SURTAXE' THEN 3
          else 99
        end;

        if vv_line_type = 'CLIENT' THEN
          case
            when pt_in_info_ligne.SIGNE='+' and pt_in_info_ligne.DEBIT_CREDIT='D' and pt_in_info_ligne.MONTANT = 3 then
             vv_type_mvt := 'SI_AMT_PETIT_MT';
            when pt_in_info_ligne.SIGNE='+' and pt_in_info_ligne.DEBIT_CREDIT='D'                                  then
              vv_type_mvt := 'SI_AMT_FACTURE';
            when pt_in_info_ligne.SIGNE='+' and pt_in_info_ligne.DEBIT_CREDIT='C'                                  then
              vv_type_mvt := 'SI_AMONT_AVOIR';
            when pt_in_info_ligne.SIGNE='-' and pt_in_info_ligne.DEBIT_CREDIT='D'                                  then
              vv_type_mvt := 'SI_AMT_ANNUL_FA';
            when pt_in_info_ligne.SIGNE='-' and pt_in_info_ligne.DEBIT_CREDIT='C'                                  then
              vv_type_mvt := 'SI_AMT_ANNUL_AV';
            else
              validate(FALSE, vv_code_erreur, 'OAE039', 'Impossible de déterminer le type de mouvement AR. SIGNE=' || pt_in_info_ligne.SIGNE);
          end case;
        else
          vv_type_mvt := NULL;  -- si le type de mvt n'est pas CLIENT, on renvoit NULL
        end if;

        po_info_ligne_mvt_ar := XXEAI_TYPE_AR_OBJ('OAE000', vv_line_type, vn_line_num, vv_type_mvt);
        put_debug_message(lv_current_program_unit || ' 999 : FIN');
    EXCEPTION
          WHEN e_main THEN
               po_info_ligne_mvt_ar := XXEAI_TYPE_AR_OBJ(nvl(vv_code_erreur, 'OAE999'), vv_line_type, vn_line_num, vv_type_mvt);
               put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR');
          WHEN OTHERS THEN
               po_info_ligne_mvt_ar := XXEAI_TYPE_AR_OBJ('OAE999', vv_line_type, vn_line_num, vv_type_mvt);
               put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
    END Get_type_num_ligne_mvt_AR;

     -----------------------------------------------------------------
     --  FONCTIONNALITE 17 : Déterminer la région a partir du DKCODE
     --  Nom           : Get_region_DKCODE
     --  Description   : Cette fonction servira a retourner la région en fonction du DKcode. Chaque Unité Opérationnelle aura un DKcode
     --                  (de type BxxxxxxxxK avec xxxxxxxx le code numérique et K le caractere de contrôle) et suivant le jeu de transcodification
     --                  DKA_DKCODE_UO (DKCode <> UO_DALKIA)  on en déduira la région
     --
     --  PARAMETRES :
     --     pv_DKcode                Entrée        DKcode
     --     po_info_region           Sortie        Objet contenant le code erreur, et la région
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_region_DKCODE(pv_DKcode IN VARCHAR2,
                                 po_info_region IN OUT NOCOPY XXEAI_TYPE_INFO_REGION_OBJ) IS
       lv_current_program_unit CONSTANT VARCHAR2(30) := 'Get_region_DKCODE';
       vv_code_erreur          VARCHAR2(50) := 'OAE000';         -- Code Erreur
       l_result                VARCHAR2(200);
     BEGIN
        put_debug_message(lv_current_program_unit || ' 001 : Début');
        not_null('pv_DKcode', pv_DKcode, vv_code_erreur);

        l_result :=  APPS.dka_stransco_pkg.etl_get_value_f('DKA_DKCODE_UO', sysdate, pv_DKcode);
        validate(l_result is not null, vv_code_erreur, 'OAE040');

        po_info_region := XXEAI_TYPE_INFO_REGION_OBJ('OAE000', l_result);
        put_debug_message(lv_current_program_unit || ' 999 : FIN');
     EXCEPTION
        WHEN e_main THEN
           po_info_region := XXEAI_TYPE_INFO_REGION_OBJ(nvl(vv_code_erreur, 'OAE999'), null);
           put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR');
        WHEN OTHERS THEN
           po_info_region := XXEAI_TYPE_INFO_REGION_OBJ('OAE999', null);
           put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END;

     -----------------------------------------------------------------
     -- FONCTIONNALITÉ 18 : INFORMATIONS BANCAIRE EN FONCTION DE L'IBAN SUR DES COMPTES DE BANQUES INTERNES (BANQUE DALKIA)
     --  Nom           : Get_Infos_Banque_Interne
     --  Description   : Fonction qui retourne le nom de la banque interne DALKIA
     --
     --  PARAMETRES :
     --     pv_IBAN          Entrée      IBAN
     --     pv_Banque_Name   Sortie      Nom de la Banque INTERNE Dalkia
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Infos_Banque_Interne(pv_IBAN        IN VARCHAR2,
                                        pv_Banque_Name IN OUT NOCOPY VARCHAR2) IS
       lv_current_program_unit CONSTANT VARCHAR2(30) := 'Get_Infos_Banque_Interne';
       l_result                APPS.CE_BANK_ACCOUNTS.bank_account_name%TYPE;
     BEGIN
       put_debug_message(lv_current_program_unit || ' 001 : Début');

       select bank_account_name into l_result
       from APPS.CE_BANK_ACCOUNTS     A
       where 1=1
         and account_classification = 'INTERNAL'
         and sysdate between nvl(A.START_DATE, sysdate) and nvl(A.END_DATE, sysdate+1)
         and A.IBAN_NUMBER = pv_IBAN;

       pv_Banque_Name := nvl(l_result, 'Banque inconnue ' || pv_IBAN);
       put_debug_message(lv_current_program_unit || ' 999 : FIN');
     EXCEPTION
        WHEN e_main THEN
             pv_Banque_Name := 'Banque inconnue ' || pv_IBAN;
             put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR');
        WHEN OTHERS THEN
             pv_Banque_Name := 'Banque inconnue ' || pv_IBAN;
             put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Infos_Banque_Interne;

     -----------------------------------------------------------------
     -- FONCTIONNALITÉ 19 : INFORMATIONS SUR LES CODES REJETS SUR LES PRELEVEMENTS CLIENTS (ETAT CAMT054)
     --  Nom           : Get_Infos_Rejets_Sepa
     --  Description   : Fonction qui retourne le nom de la banque interne DALKIA
     --
     --  PARAMETRES :
     --     pv_IBAN          Entrée      IBAN
     --     pv_Banque_Name   Sortie      Nom de la Banque INTERNE Dalkia
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Infos_Rejets_Sepa(pv_Code_Rejet        IN VARCHAR2,
                                     pv_Description_Rejet IN OUT NOCOPY VARCHAR2) IS
       lv_current_program_unit CONSTANT VARCHAR2(30) := 'Get_Infos_Rejets_Sepa';
       l_result                APPS.FND_FLEX_VALUES_VL.description%TYPE;
     BEGIN
       put_debug_message(lv_current_program_unit || ' 001 : Début');
       l_result := get_flex_value('DKA_CODE_REJETS_SEPA', pv_Code_Rejet).description;
       pv_Description_Rejet := nvl(l_result, 'Code inconnu ' || pv_Code_Rejet);
       put_debug_message(lv_current_program_unit || ' 999 : FIN');
     EXCEPTION
        WHEN e_main THEN
             pv_Description_Rejet := 'Code inconnu ' || pv_Code_Rejet;
             put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR');
        WHEN OTHERS THEN
             pv_Description_Rejet := 'Code inconnu ' || pv_Code_Rejet;
             put_debug_message(lv_current_program_unit || ' 999 : FIN ERREUR : ' || SQLERRM);
     END Get_Infos_Rejets_Sepa;

-----------------------------------------------------------------
-----------------------------------------------------------------
-- init du package
BEGIN
   APPS.Dka_Tools_Pkg.get_parameter(
     pv_program_code     => 'INTERFACE_TOOLS_EAI',
     pv_parameter_name   => 'DEBUG_MODE',
     pr_data             => rec_param,
     pn_retcode          => gn_retcode,
     pv_err_msg          => gv_errbuf);

     gv_debug_mode := rec_param.varchar2_value;
END XXEAI_INTERFACE_TOOLS_PKG; -- body du package