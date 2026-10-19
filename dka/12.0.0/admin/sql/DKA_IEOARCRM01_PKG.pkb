CREATE OR REPLACE PACKAGE BODY DKA_IEOARCRM01_PKG AS
     ----------------------------------------------------------------------------------------------
     -- $ $
     --
     -- NOM               : DKA_IEOARCRM01_PKG.pkb
     -- DESCRIPTION       : DKA_IEOARCRM01_PKG package body : ENCAPSULATION DES REQUETES CRM
     ---
     --- AUTEUR           : H Descroizette
     --- DATE DE CREATION : 06/10/2016  
     --- DOC. ASSOCIEE    :
     ---
     ----------------------------------------------------------------------------------------------
     --- NOM DU PROGRAMME :
     --- PARAMETRES       :
     ---
     --- HISTORIQUE DES MODIFICATIONS
     --- Date       Qui Description
     --- ---------- --- -------------------------------------------------------------------------
     --
     --------------------------------------------------------------------------------------------



-- ============= Exceptions ============
E_FATAL_ERROR EXCEPTION;  
PRAGMA EXCEPTION_INIT (E_FATAL_ERROR, -20012);
K_FATAL_ERROR_NUM  CONSTANT NUMBER := -20012;

-- ============= Types ============
type T_COLUMN_VALUES is table of varchar2(32767) index by pls_integer;

-- ============= Constantes ============

K_SEPARATOR CONSTANT VARCHAR2(2) := ';';
K_DIRECTORY CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';

K_DIVISION constant VARCHAR2(50) := 'DALKIA';

-- ============= Variables globales ============
gv_SYSTEM_ORIGINE varchar2(40);

-- ============= Procédures et fonctions ============


-----------------------------------------------------------------
procedure put_debug_message(p_message in varchar2) 
is
begin
  dka_tools_pkg.put_debug_message(p_message);
  --dbms_output.put_line(p_message);
end put_debug_message;

-----------------------------------------------------------------
procedure validate(p_condition in boolean, p_message in varchar2 default null) 
is
begin
 if not p_condition then 
   if p_message is not null then 
     put_debug_message(p_message);           
   end if;
   RAISE_APPLICATION_ERROR(K_FATAL_ERROR_NUM, nvl(p_message, 'Erreur fatale : '));
 end if;
end validate;

-----------------------------------------------------------------
procedure not_null(p_param_name in varchar2, p_param_value in varchar2) is
begin
 validate(p_param_value is not null, 'Le parametre obligatoire ' || p_param_name || ' n''est pas renseigné.');
end not_null; 
  
  
---------------------------------------------------------------------------------------------------------------
procedure write_CSV_line(p_values in T_COLUMN_VALUES, p_file in out nocopy UTL_FILE.file_type)
is
  l_val varchar2(32767);
begin
  if p_values.count= 0  then
    return;
  end if;
  
  for i in p_values.FIRST .. p_values.LAST loop
    l_val := replace(p_values(i), chr(10), ' ');
    if INSTR(l_val, '"') > 0 or INSTR(l_val, K_SEPARATOR) > 0 then 
      l_val := '"' || replace(l_val, '"', '""') || '"';   -- on double les guillemets et on encadre la valeur avec des guillemets
    end if;
    
    IF i != p_values.FIRST THEN
      utl_file.put(p_file, K_SEPARATOR);
    end if;
    utl_file.put(p_file, l_val);
  end loop;
  
  utl_file.new_line(p_file);
end;
  
---------------------------------------------------------------------------------------------------------------
procedure check_directory(p_directory_name in ALL_DIRECTORIES.directory_name%type)
is
begin
  dka_tools_pkg.check_directory(p_directory_name);     
end check_directory;
  
---------------------------------------------------------------------------------------------------------------
  --  Nom           : dump_query
  --  Description   : Export du contenu d'une requete SQL en CSV. Retourne le nb d'enreg exportés
  --
  --  PARAMETRES    : p_directory_name       Répertoire de destination  
  --                  p_file_name            Fichier CSV de destination
  --                  p_cursor_num        handle de curseur retourné par dbms_sql
---------------------------------------------------------------------------------------------------------------
function  dump_query(
  p_directory_name   IN            ALL_DIRECTORIES.directory_name%type,
  p_file_name        IN            VARCHAR2,
  p_cursor_num       IN            INTEGER) return pls_integer
IS
  lv_current_program_unit CONSTANT varchar2(32) := 'dump_query';
  K_TIMESTAMP_FORMAT CONSTANT varchar2(100) := 'DD/MM/YYYY HH24:MI:SSxFF TZH:TZM';
  K_DATE_FORMAT      CONSTANT varchar2(100) := 'DD/MM/YYYY';
  K_NUMBER_FORMAT    CONSTANT varchar2(100) := 'FM999999999990D00';
  K_INTEGER_FORMAT   CONSTANT varchar2(100) := 'FM999999999990';
  
  l_file             UTL_FILE.file_type;
  
  l_coldesc_tab      DBMS_SQL.DESC_TAB2;
  l_colcount         integer;
  l_rc               number;


  l_column_values    T_COLUMN_VALUES;
  l_width            integer;
  l_number           number;
  l_date             date;
  l_value            varchar2(32767);
  l_line_count       pls_integer := 0;
BEGIN  
  put_debug_message('DEBUT ' || lv_current_program_unit);
  not_null('p_directory_name', p_directory_name);
  not_null('p_file_name', p_file_name);

  put_debug_message('Création du fichier ' || p_directory_name || ':' || p_file_name);
  check_directory(p_directory_name);
  l_file := UTL_FILE.fopen( p_directory_name, p_file_name, 'W'); 
  
  -- Vérification du curseur reçu  -- Attention : c'est la responsabilité de l'appelant de fermer ce curseur apres usage
  IF NOT dbms_sql.is_open(p_cursor_num) THEN 
    RAISE_APPLICATION_ERROR(K_FATAL_ERROR_NUM, 'Le curseur n''est pas ouvert');
  END IF;  
  
  -- récupération du type des colonnes de la requete
  DBMS_SQL.DESCRIBE_COLUMNS2(p_cursor_num, l_colcount, l_coldesc_tab);

  FOR i IN 1 .. l_coldesc_tab.COUNT LOOP
    l_width := LEAST(60, l_coldesc_tab(i).col_max_len);
    CASE 
      WHEN l_coldesc_tab(i).col_type in (2, 182, 183)  THEN 
        dbms_sql.define_column(p_cursor_num, i, l_number);           -- NUMBER      
      WHEN  l_coldesc_tab(i).col_type in (12, 180, 181, 231)  THEN 
        dbms_sql.define_column(p_cursor_num, i, l_date);             -- DATE        
      ELSE       
        dbms_sql.define_column(p_cursor_num, i, l_value, l_width);   -- VARCHAR2, NVARCHAR2      
    END CASE;
  end loop;

  -- Exécution du curseur
  put_debug_message('Exécution de la requete');  
  BEGIN
    l_rc := DBMS_SQL.EXECUTE(p_cursor_num);
  EXCEPTION
    WHEN others THEN
      IF SQLCODE != -1001 THEN RAISE; END IF;  
  END;
  put_debug_message('Exécution terminée');   

  --  Ecriture du fichier 
  put_debug_message('Ecriture du fichier');   
  LOOP   
    EXIT WHEN DBMS_SQL.FETCH_ROWS(p_cursor_num) <= 0;
    FOR i IN 1 .. l_coldesc_tab.COUNT LOOP
    CASE 
      WHEN l_coldesc_tab(i).col_type in (1, 11, 23, 24, 69, 96, 112)  THEN    
        dbms_sql.COLUMN_VALUE(p_cursor_num, i, l_value);         -- VARCHAR2, NVARCHAR2   
      WHEN l_coldesc_tab(i).col_type in (2, 182, 183)  THEN      -- NUMBER      
        dbms_sql.COLUMN_VALUE(p_cursor_num, i, l_number);                                           
        if l_coldesc_tab(i).col_name like 'ID%' or l_coldesc_tab(i).col_scale = 0 then 
          l_value := to_char(l_number, K_INTEGER_FORMAT); 
        else
          l_value := to_char(l_number, K_NUMBER_FORMAT);
        end if;           
      WHEN  l_coldesc_tab(i).col_type in (12, 180, 181, 231)  THEN 
        dbms_sql.COLUMN_VALUE(p_cursor_num, i, l_date);     
        l_value := to_char(l_date, K_DATE_FORMAT);              -- DATE        
      ELSE       
        l_value := '[' || l_coldesc_tab(i).col_name  ||']';        
      END CASE; 
      l_column_values(i) := l_value;
    END LOOP;
    
    write_CSV_line(l_column_values, l_file);
     
    l_line_count := l_line_count + 1;
    IF l_line_count MOD 100 = 0 THEN
      put_debug_message('déja ' || l_line_count || ' enregistrements écrits...');
    END IF;               
  END LOOP; 
  
  -- fermeture du fichier
  UTL_FILE.FCLOSE(l_file);
  put_debug_message(l_line_count || ' enregistrements écrits.');
 
  put_debug_message('FIN ' || lv_current_program_unit); 
  return l_line_count;
EXCEPTION
  WHEN OTHERS THEN
    if UTL_FILE.is_open(l_file) then UTL_FILE.FCLOSE(l_file); end if;
    put_debug_message('ERREUR ' || lv_current_program_unit || ' : ' || SQLERRM);
    raise; 
END dump_query;
  
/*  
---------------------------------------------------------------------------------------------------------------
function  dump_query2(
  p_directory_name   IN            ALL_DIRECTORIES.directory_name%type,
  p_file_name        IN            VARCHAR2,
  p_cursor_num       IN            INTEGER) return pls_integer
IS
  lv_current_program_unit CONSTANT varchar2(32) := 'dump_query';
  
  l_file             UTL_FILE.file_type;
  
  l_coldesc_tab      DBMS_SQL.DESC_TAB2;
  l_colcount         integer;
  l_rc               number;
BEGIN
  put_debug_message('DEBUT ' || lv_current_program_unit);
  not_null('p_directory_name', p_directory_name);
  not_null('p_file_name', p_file_name);

  put_debug_message('Création du fichier ' || p_directory_name || ':' || p_file_name);
  check_directory(p_directory_name);
  l_file := UTL_FILE.fopen( p_directory_name, p_file_name, 'W'); 
  
  -- Vérification du curseur reçu  -- Attention : c'est la responsabilité de l'appelant de fermer ce curseur apres usage
  IF NOT dbms_sql.is_open(p_cursor_num) THEN 
    RAISE_APPLICATION_ERROR(K_FATAL_ERROR_NUM, 'Le curseur n''est pas ouvert');
  END IF;  
  
  -- récupération du type des colonnes de la requete
  DBMS_SQL.DESCRIBE_COLUMNS2(p_cursor_num, l_colcount, l_coldesc_tab);

  -- construction d'une requete dynamique de conversion en CSV
  FOR i IN 1 .. l_coldesc_tab.COUNT LOOP
    l_width := LEAST(60, l_coldesc_tab(i).col_max_len);
    CASE 
      WHEN l_coldesc_tab(i).col_type in (2, 182, 183)  THEN 
        dbms_sql.define_column(p_cursor_num, i, l_number);           -- NUMBER      
      WHEN  l_coldesc_tab(i).col_type in (12, 180, 181, 231)  THEN 
        dbms_sql.define_column(p_cursor_num, i, l_date);             -- DATE        
      ELSE       
        dbms_sql.define_column(p_cursor_num, i, l_value, l_width);   -- VARCHAR2, NVARCHAR2      
    END CASE;
  END LOOP;
  
  
END dump_query2; 
*/
---------------------------------------------------------------------------------------------------------------
  --  Nom           : Fournisseurs
  --  Description   : Extraction des fournisseurs
  --
  --  PARAMETRES    : aucun
---------------------------------------------------------------------------------------------------------------
procedure Extract_CSV(
  p_file_prefix      IN            VARCHAR2,
  p_cursor           IN OUT NOCOPY SYS_REFCURSOR)
is
  lv_current_program_unit constant varchar2(32) := 'Extract_CSV';
  l_start_time            TIMESTAMP := current_timestamp;
  l_cursor_num            integer;
  l_record_count          pls_integer;
  l_elapsed               number;
begin
  put_debug_message('DEBUT ' || lv_current_program_unit);  
  l_cursor_num := dbms_sql.to_cursor_number(p_cursor);
  l_record_count := dump_query(K_DIRECTORY, p_file_prefix || to_char(sysdate, 'YYYYMMDD')|| '.csv', l_cursor_num);
  dbms_sql.close_cursor(l_cursor_num);
    
  l_elapsed := round(sysdate + (current_timestamp-l_start_time)*86400 - sysdate, 2);
  put_debug_message('Terminé en ' || to_char(l_elapsed, 'FM999990D000') || 's ; ' || 
    'débit=' || case when l_record_count > 0 then to_char(l_record_count/l_elapsed, 'FM99990D00') else 'N/A' end || ' enreg./s');    
  put_debug_message('FIN ' || lv_current_program_unit);  
exception
  when Others then 
    if dbms_sql.is_open(l_cursor_num) then dbms_sql.close_cursor(l_cursor_num); end if;
    put_debug_message('ERREUR ' || lv_current_program_unit || ' : ' || SQLERRM);
    raise; 
end Extract_CSV;
  
---------------------------------------------------------------------------------------------------------------
  --  Nom           : Fournisseurs
  --  Description   : Extraction des fournisseurs
  --
  --  PARAMETRES    : aucun
---------------------------------------------------------------------------------------------------------------
procedure Fournisseurs
IS
  lv_current_program_unit constant varchar2(32) := 'Fournisseurs';
  l_start_time            TIMESTAMP := current_timestamp;
  l_cursor1               SYS_REFCURSOR;
  l_cursor_num            integer;
  l_record_count          pls_integer;
  l_elapsed               number;
BEGIN
  put_debug_message('DEBUT ' || lv_current_program_unit);

  open l_cursor1 FOR 
  select gv_SYSTEM_ORIGINE          as SYSTEM_ORIGINE,
         aps.vendor_id               as ID_FOURNISSEUR, 
         apsa.vendor_site_id         as ID_SITE,
         K_DIVISION                  as DIVISION,
         null                        as CODE_SOCIETE,
         null                        as NOM_SOCIETE,
         substr(haou.name, 1, 3)     as CODE_REGION,
         aps.vendor_name             as NOM_FOURNISSEUR,
         aps.segment1                as NUM_FOURNISSEUR,
         nvl(ztf2.rep_registration_number, ztf1.rep_registration_number) as TVA_INTRACO,
         apsa.vendor_site_code       as CODE_SITE,
         aps.num_1099                as SIREN,
         decode (apsa.purchasing_site_flag, 'Y', 'O', 'N', 'N') as SITE_ACHAT,
         decode (apsa.pay_site_flag, 'Y', 'O', 'N', 'N')        as SITE_REGLEMENT,
         aps.invoice_currency_code   as DEVISE,
         ieppm.payment_method_code   as MODE_REGLEMENT,
         att.name                    as CONDITION_REGLEMENT,
         '?'                         as FACTOR,
         replace(cb.bank_number || '.' || cbb.branch_number || '.' || ieba.bank_account_num || '.' || ieba.check_digits, '...', null) as RIB
  from ap_suppliers                               aps
  join ap_supplier_sites_all                      apsa  on (apsa.vendor_id = aps.vendor_id and nvl(apsa.INACTIVE_DATE, sysdate+1) > trunc(sysdate))
  join ap_terms_tl                                att   on (att.term_id = apsa.terms_id and att.language='F')
  join hr_all_organization_units                  haou  on (haou.organization_id = apsa.org_id)
  left outer join zx_party_tax_profile            ztf1  on (ztf1.party_type_code='THIRD_PARTY' and ztf1.party_id = aps.party_id) 
  left outer join zx_party_tax_profile            ztf2  on (ztf2.party_type_code='THIRD_PARTY_SITE' and ztf2.party_id = apsa.party_site_id) 
  left outer join iby_external_payees_all         iepa  on (iepa.supplier_site_id = apsa.vendor_site_id and iepa.org_id = apsa.org_id and nvl(iepa.INACTIVE_DATE, sysdate+1) > trunc(sysdate))
  left outer join iby_ext_party_pmt_mthds         ieppm on (ieppm.payment_flow = 'DISBURSEMENTS' and ieppm.payment_function='PAYABLES_DISB' and ieppm.primary_flag='Y'
                                                            and nvl(ieppm.inactive_date, sysdate) > trunc(sysdate)
                                                            and ieppm.ext_pmt_party_id=iepa.ext_payee_id )
  left outer join iby_pmt_instr_uses_all          ipiua on (ipiua.payment_flow = 'DISBURSEMENTS' and ipiua.instrument_type='BANKACCOUNT'
                                                            and ipiua.ext_pmt_party_id=iepa.ext_payee_id 
                                                            and ipiua.order_of_preference=1
                                                            and sysdate between nvl(ipiua.start_date,sysdate) and nvl(ipiua.end_date, sysdate+1))
  left outer join iby_ext_bank_accounts          ieba on (ieba.ext_bank_account_id = ipiua.instrument_id  and sysdate between nvl(ieba.start_date,sysdate) and nvl(ieba.end_date, sysdate+1))
  left outer join ce_bank_branches_v             cbb  on (ieba.branch_id = cbb.branch_party_id)
  left outer join ce_banks_v                     cb   on (cb.bank_party_id = cbb.bank_party_id) 
  where 1=1
    and vendor_type_lookup_code not in ('EMPLOYEE');
    
  Extract_CSV( 'CRM_FOURNISSEURS_', l_cursor1);

  put_debug_message('FIN ' || lv_current_program_unit);  
exception
  when Others then 
    put_debug_message('ERREUR ' || lv_current_program_unit || ' : ' || SQLERRM);
    raise; 
END Fournisseurs;


---------------------------------------------------------------------------------------------------------------
  --  Nom           : Reglements
  --  Description   : Extraction des Reglements
  --
  --  PARAMETRES    : aucun
---------------------------------------------------------------------------------------------------------------
procedure Reglements
IS
  lv_current_program_unit constant varchar2(32) := 'Reglements';
  l_start_time            TIMESTAMP := current_timestamp;
  l_cursor1               SYS_REFCURSOR;
  l_cursor_num            integer;
  l_record_count          pls_integer;
  l_elapsed               number;
BEGIN
  put_debug_message('DEBUT ' || lv_current_program_unit);
  
  -- La ligne ci-dessous est nécessaire pour éviter l'erreur ORA-01792 maximum number of columns in a table or view is 1000 
  -- Voir "Select Statement Throws ORA-01792 Error in 12c" (Doc ID 1951689.1)
  execute immediate q'[alter session set "_fix_control"='17376322:OFF']';      

  open l_cursor1 FOR 
    select gv_SYSTEM_ORIGINE          as SYSTEM_ORIGINE,
           aia.vendor_id               as ID_FOURNISSEUR, 
           aia.vendor_site_id          as ID_SITE,
           K_DIVISION                  as DIVISION,
           aia.invoice_id              as ID_FACTURE,
           SUBSTR (haou.name, -4, 4)   as CODE_SOCIETE,
           NULL                        as NOM_SOCIETE,
           substr(haou.name, 1, 3)     as CODE_REGION,  
           flv.displayed_field         as TYPE_FACTURE,
           fdsc.name                   as NOM_TYPE_PIECE,
           aia.invoice_num             as NUM_FACTURE,
           aia.description             as DESCRIPTION,
           greatest(least(aia.invoice_date, date'2078-12-31'), date'1900-01-01') as DATE_FACTURE, 
           aia.invoice_currency_code   as DEVISE_FACTURE,
           aia.invoice_amount          as MONTANT_TTC,
           aia.payment_currency_code   as DEVISE,
           ipa.payment_amount          as MONTANT_REGLEMENT,
           idpa.payment_amount         as MONTANT_REG_FACT,
           DECODE (ipa.PAYMENT_METHOD_CODE,
            'CHECK', 'Cheque',
            'CLEARING', 'LCR',
            'WIRE', 'Prélevement',
            'EFT', 'Virement', 
            'Autre')     as MODE_REGLEMENT,
           greatest(least(apsa.due_date, date'2078-12-31'), date'1900-01-01') as DATE_ECHEANCE, 
           greatest(least(ipa.payment_date, date'2078-12-31'), date'1900-01-01') as DATE_REGLEMENT, 
           ipa.payment_currency_code   as DEVISE_REGLEMENT,
           replace(ipa.int_bank_number || '.' || ipa.int_bank_branch_number || '.' || ipa.int_bank_account_number || '.' || cba.check_digits, '...', null) as COMPTE_REGLEMENT,
           NULL                        as URL_FACTURE,
           ipa.paper_document_number   as NUMERO_REGLEMENT,
           ipa.payment_id              as ID_REGLEMENT
    from iby_payments_all                        ipa
    join hr_all_organization_units               haou  on (haou.organization_id = ipa.org_id)
    join IBY_DOCS_PAYABLE_ALL                    idpa  on (idpa.payment_id = ipa.payment_id)
    join ap_payment_schedules_all                apsa  on (apsa.invoice_id = idpa.calling_app_doc_unique_ref2 and apsa.payment_num = idpa.calling_app_doc_unique_ref3)
    join ap_invoices_all                         aia   on (aia.invoice_id = apsa.invoice_id and aia.org_id = apsa.org_id)
    join ap_lookup_codes                         flv   on (flv.lookup_code = aia.invoice_type_lookup_code 
                                                           and flv.lookup_type = 'INVOICE TYPE')
    join fnd_doc_sequence_categories             fdsc  on (fdsc.code = aia.doc_category_code and fdsc.application_id = 200 and fdsc.table_name = 'AP_INVOICES_ALL')
    left outer join ce_bank_accounts             cba   on (cba.bank_account_id = ipa.internal_bank_account_id)
    where 1=1
      and aia.payment_status_flag = 'Y'
      and ipa.payment_status = 'FORMATTED'
      and ipa.payments_complete_flag='Y'
      and ipa.payment_date > SYSDATE - 182;
      
  Extract_CSV( 'CRM_REGLEMENTS_', l_cursor1);

  put_debug_message('FIN ' || lv_current_program_unit);  
exception
  when Others then 
    put_debug_message('ERREUR ' || lv_current_program_unit || ' : ' || SQLERRM);
    raise; 
END Reglements;


---------------------------------------------------------------------------------------------------------------
  --  Nom           : Factures_payees
  --  Description   : Extraction des Factures_payees
  --
  --  PARAMETRES    : aucun
---------------------------------------------------------------------------------------------------------------
procedure Factures_payees
IS
  lv_current_program_unit constant varchar2(32) := 'Factures_payees';
  l_start_time            TIMESTAMP := current_timestamp;
  l_cursor1               SYS_REFCURSOR;
  l_cursor_num            integer;
  l_record_count          pls_integer;
  l_elapsed               number;
BEGIN
  put_debug_message('DEBUT ' || lv_current_program_unit);
  
  -- La ligne ci-dessous est nécessaire pour éviter l'erreur ORA-01792 maximum number of columns in a table or view is 1000 
  -- Voir "Select Statement Throws ORA-01792 Error in 12c" (Doc ID 1951689.1)
  execute immediate q'[alter session set "_fix_control"='17376322:OFF']';      

  open l_cursor1 FOR 
    with rglt as (
    -- Les reglements émis depuis moins de 182 jours avec l'échéance de facturation concernée par le reglement. L'échéance la plus récente porte le rang (rk) 1 
    select ipa.org_id, ipa.payment_id as payment_id, idpa.calling_app_doc_unique_ref2 as invoice_id, idpa.calling_app_doc_unique_ref3 as payment_num, 
           ipa.payment_date, ipa.payment_currency_code, ipa.payment_amount, ipa.payment_method_code, idpa.payment_amount as inv_payment_amount,
           ipa.internal_bank_account_id, ipa.int_bank_number, ipa.int_bank_branch_number, ipa.int_bank_account_number,
           dense_rank() over (partition by ipa.org_id, idpa.calling_app_doc_unique_ref2, idpa.calling_app_doc_unique_ref3 order by ipa.payment_date desc) as rk
    from iby_payments_all                        ipa
    join IBY_DOCS_PAYABLE_ALL                    idpa  on (idpa.payment_id = ipa.payment_id)
      and ipa.payment_status = 'FORMATTED'
      and ipa.payments_complete_flag='Y'
      and ipa.payment_date > SYSDATE - 182
    ) 
    select gv_SYSTEM_ORIGINE          as SYSTEM_ORIGINE,
           aia.vendor_id               as ID_FOURNISSEUR, 
           aia.vendor_site_id          as ID_SITE,
           K_DIVISION                  as DIVISION,
           aia.invoice_id              as ID_FACTURE,
           SUBSTR (haou.name, -4, 4)   as CODE_SOCIETE,
           NULL                        as NOM_SOCIETE,
           substr(haou.name, 1, 3)     as CODE_REGION,  
           flv.meaning                 as TYPE_FACTURE,
           fdsc.name                   as NOM_TYPE_PIECE,
           aia.invoice_num             as NUM_FACTURE,
           aia.description             as DESCRIPTION,
           greatest(least(aia.invoice_date, date'2078-12-31'), date'1900-01-01') as DATE_FACTURE, 
           aia.invoice_currency_code   as DEVISE_FACTURE,
           aia.invoice_amount          as MONTANT_TTC,
           aia.payment_currency_code   as DEVISE,
           rglt.payment_amount         as MONTANT_REGLEMENT,
           rglt.inv_payment_amount     as MONTANT_REG_FACT,
           DECODE (rglt.payment_method_code,
            'CHECK', 'Cheque',
            'CLEARING', 'LCR',
            'WIRE', 'Prélevement',
            'EFT', 'Virement', 
            'Autre')     as MODE_REGLEMENT,
           greatest(least(apsa.due_date, date'2078-12-31'), date'1900-01-01') as DATE_ECHEANCE, 
           greatest(least(rglt.payment_date, date'2078-12-31'), date'1900-01-01') as DATE_REGLEMENT, 
           rglt.payment_currency_code  as DEVISE_REGLEMENT,
           replace(rglt.int_bank_number || '.' || rglt.int_bank_branch_number || '.' || rglt.int_bank_account_number || '.' || cba.check_digits, '...', null) as COMPTE_REGLEMENT,
           NULL                        as URL_FACTURE
    from rglt
    join hr_all_organization_units               haou  on (haou.organization_id = rglt.org_id)
    join ap_payment_schedules_all                apsa  on (apsa.invoice_id = rglt.invoice_id and apsa.payment_num = rglt.payment_num)
    join ap_invoices_all                         aia   on (aia.invoice_id = apsa.invoice_id and aia.org_id = apsa.org_id)
    join fnd_lookup_values                       flv   on (flv.lookup_code = aia.invoice_type_lookup_code 
                                                           and flv.lookup_type = 'INVOICE TYPE' and flv.language = 'F' 
                                                           and security_group_id=0 and view_application_id=200)
    join fnd_doc_sequence_categories             fdsc  on (fdsc.code = aia.doc_category_code and fdsc.application_id = 200 and fdsc.table_name = 'AP_INVOICES_ALL')
    left outer join ce_bank_accounts             cba   on (cba.bank_account_id = rglt.internal_bank_account_id)
    where 1=1
      and aia.payment_status_flag = 'Y'
      and rglt.rk=1;      
  
  Extract_CSV( 'CRM_FACT_REG_', l_cursor1);

  put_debug_message('FIN ' || lv_current_program_unit);  
exception
  when Others then 
    put_debug_message('ERREUR ' || lv_current_program_unit || ' : ' || SQLERRM);
    raise; 
END Factures_payees;

---------------------------------------------------------------------------------------------------------------
  --  Nom           : Factures_non_payees
  --  Description   : Extraction des Factures_non_payees
  --
  --  PARAMETRES    : aucun
---------------------------------------------------------------------------------------------------------------
procedure Factures_non_payees
IS
  lv_current_program_unit constant varchar2(32) := 'Factures_non_payees';
  l_start_time            TIMESTAMP := current_timestamp;
  l_cursor1               SYS_REFCURSOR;
  l_cursor_num            integer;
  l_record_count          pls_integer;
  l_elapsed               number;
BEGIN
  put_debug_message('DEBUT ' || lv_current_program_unit);
  
  -- La ligne ci-dessous est nécessaire pour éviter l'erreur ORA-01792 maximum number of columns in a table or view is 1000 
  -- Voir "Select Statement Throws ORA-01792 Error in 12c" (Doc ID 1951689.1)
  execute immediate q'[alter session set "_fix_control"='17376322:OFF']';      

  open l_cursor1 FOR 
  WITH societes as (
    -- liste des sociétés du groupe DALKIA
    select ffv.flex_value as company_code, ffv.description as company_name
    from gl_ledgers               gl
    join fnd_id_flex_segments     fifs on (gl.chart_of_accounts_id = fifs.id_flex_num)
    join fnd_flex_values_vl       ffv  on (ffv.flex_value_set_id = fifs.flex_value_set_id)
    where 1=1
      and gl.name = 'DALKIA'
      and fifs.application_id=101
      and fifs.id_flex_code='GL#'
      and fifs.segment_name = 'SOCIETE'
  ), 
  invoices as (
    -- les échéances de factures non payées ou partiellement payées
    select 'FACTURE' as type, aia.org_id, aia.invoice_id, aia.vendor_id, aia.vendor_site_id, aia.invoice_type_lookup_code,
           aia.invoice_num, aia.description, aia.invoice_currency_code, aia.invoice_amount, aia.amount_paid, 
           nvl(aia.payment_currency_code, aia.invoice_currency_code) as payment_currency_code, aia.wfapproval_status, aia.doc_category_code, aia.invoice_date,
           apsa.payment_num, apsa.external_bank_account_id, apsa.payment_method_code, apsa.due_date, 
           aiad."NUMÉRO_INVOICE",
           dense_rank() over (partition by aia.invoice_id order by apsa.payment_num) as payment_rank_num    -- 1 = la prochaine échéance non payée
    from ap_invoices_all             aia
    join ap_invoices_all_dfv         aiad on (aiad.row_id = aia.rowid)
    join ap_payment_schedules_all    apsa on (apsa.invoice_id = aia.invoice_id)
    where aia.payment_status_flag IN ('P', 'N')
      and aia.invoice_type_lookup_code != 'EXPENSE REPORT'
      and aia.cancelled_date IS NULL
      and apsa.payment_status_flag IN ('N', 'P')
    union all
    -- les factures annulées
    select 'FACTURE_ANNULEE' as type, aia.org_id, aia.invoice_id, aia.vendor_id, aia.vendor_site_id, aia.invoice_type_lookup_code,
           aia.invoice_num, aia.description, aia.invoice_currency_code, aia.invoice_amount, aia.amount_paid, 
           nvl(aia.payment_currency_code, aia.invoice_currency_code) as payment_currency_code, aia.wfapproval_status, aia.doc_category_code, aia.invoice_date,
           null as payment_num, null as external_bank_account_id, null as payment_method_code, null as due_date, 
            aiad."NUMÉRO_INVOICE",
           1 as payment_rank_num    
    from ap_invoices_all             aia
    join ap_invoices_all_dfv         aiad  on (aiad.row_id = aia.rowid)
    where aia.payment_status_flag IN ('P', 'N', 'Y')
      and aia.invoice_type_lookup_code != 'EXPENSE REPORT'
      and aia.cancelled_date IS NOT NULL 
  ), 
  invoices2 as (
    -- les codes blocage de la facture
    select i.type, i.org_id, i.invoice_id, i.vendor_id, i.vendor_site_id, i.invoice_type_lookup_code,
           i.invoice_num, i.description, i.invoice_currency_code, i.invoice_amount, i.amount_paid, 
           i.payment_currency_code, i.wfapproval_status, i.doc_category_code, i.invoice_date,
           i.payment_num, i.external_bank_account_id, i.payment_method_code, i.due_date, 
           i."NUMÉRO_INVOICE",
           sum(case when nvl(aha.release_lookup_code, 'N')='N' and aha.hold_lookup_code in  ('PRICE', 'MAX SHIP AMOUNT') then 1 end) as ecart_prix,
           sum(case when nvl(aha.release_lookup_code, 'N')='N' and aha.hold_lookup_code in  ('QTY REC', 'QTY ORD') then 1 end) as ecart_qte,
           sum(case when nvl(aha.release_lookup_code, 'N')='N' and aha.hold_lookup_code like 'En litige%' then 1 end) as litige_actif,
           sum(case when nvl(aha.release_lookup_code, 'N')='O' and aha.hold_lookup_code like 'En litige%' then 1 end) as litige_leve,
           sum(case when nvl(aha.release_lookup_code, 'N')='N' and aha.hold_lookup_code in  ('DIST VARIANCE') then 1 end) as facture_eq,
           sum(case when nvl(aha.release_lookup_code, 'N')='N' and aha.hold_lookup_code in  ('Incohérence commande', 'Blocage Fres Multi Cde', 
                                                                                             'Commande inconnue', 'Blocage cmde + 6 lignes') then 1 end) as pb_commande,
          sum(case when nvl(aha.release_lookup_code, 'N')='N' then 1 else 0 end) as nb_blocages                                                                                           
    from invoices        i
    left outer join ap.ap_holds_all aha on (aha.invoice_id = i.invoice_id)
    where i.payment_rank_num = 1
    group by i.type, i.org_id, i.invoice_id, i.vendor_id, i.vendor_site_id, i.invoice_type_lookup_code,
           i.invoice_num, i.description, i.invoice_currency_code, i.invoice_amount, i.amount_paid, 
           i.payment_currency_code, i.wfapproval_status, i.doc_category_code, i.invoice_date,
           i.payment_num, i.external_bank_account_id, i.payment_method_code, i.due_date, 
           i."NUMÉRO_INVOICE"
  ), 
  invoices3 as (
    -- parcours des ditributions pour déterminer le statut de comptabilisation. 
    --   TODO : vérifier si l'API officielle AP_INVOICES_UTILITY_PKG.get_posting_status pourrait convenir sans impacter les performances
    /*select i.type, i.org_id, i.invoice_id, i.vendor_id, i.vendor_site_id, i.invoice_type_lookup_code,
       i.invoice_num, i.description, i.invoice_currency_code, i.invoice_amount, i.amount_paid, 
       i.payment_currency_code, i.wfapproval_status, i.doc_category_code, i.invoice_date,
       i.payment_num, i.external_bank_account_id, i.payment_method_code, i.due_date, 
       i."NUMÉRO_INVOICE", i.ecart_prix, i.ecart_qte, i.litige_actif, i.litige_leve, i.facture_eq, i.pb_commande, i.nb_blocages, 
       case  nvl(sum(decode(aida.posted_flag, 'Y', 1, 0)), 0)
         when count(*) then 'Oui' 
         when 0        then 'Non'
         else 'Partiel'
       end as statut_compta
    from invoices2 i
    left outer join ap_invoice_distributions_all aida on (aida.invoice_id = i.invoice_id)
    group by i.type, i.org_id, i.invoice_id, i.vendor_id, i.vendor_site_id, i.invoice_type_lookup_code,
       i.invoice_num, i.description, i.invoice_currency_code, i.invoice_amount, i.amount_paid, 
       i.payment_currency_code, i.wfapproval_status, i.doc_category_code, i.invoice_date,
       i.payment_num, i.external_bank_account_id, i.payment_method_code, i.due_date, 
       i."NUMÉRO_INVOICE", i.ecart_prix, i.ecart_qte, i.litige_actif, i.litige_leve, i.facture_eq, i.pb_commande, i.nb_blocages*/
    select i.*, 
           case AP_INVOICES_UTILITY_PKG.get_posting_status(i.invoice_id)
             when 'Y' then 'Oui'
             when 'N' then 'Non'
             when 'P' then 'Partiel'
             else '?'
           end as statut_compta
    from  invoices2 i
  ),
  invoices4 as (
    -- Les commandes rapprochées de la facture. Attention : si une facture est rapprochée de 2 commandes, elle sera dédoublée a l'issue de cette sous-requete
    select i.type, i.org_id, i.invoice_id, i.vendor_id, i.vendor_site_id, i.invoice_type_lookup_code,
           i.invoice_num, i.description, i.invoice_currency_code, i.invoice_amount, i.amount_paid, 
           i.payment_currency_code, i.wfapproval_status, i.doc_category_code, i.invoice_date,
           i.payment_num, i.external_bank_account_id, i.payment_method_code, i.due_date, 
           i."NUMÉRO_INVOICE",
           ecart_prix, ecart_qte, litige_actif, litige_leve, facture_eq, pb_commande, nb_blocages, statut_compta,
           pda.po_header_id,            
           sum(case when aila.line_type_lookup_code != 'TAX' then aila.amount end) as montant_ht,
           sum(aila.amount)                                                        as total_lignes, 
           case when type = 'FACTURE_ANNULEE' then 'Annulé' when nb_blocages=0 then 'Validé' else 'A revalider' end as statut_validation
    from invoices3 i
    left outer join ap_invoice_lines_all    aila on (aila.invoice_id = i.invoice_id )
    left outer join po_distributions_all    pda  on (pda.po_distribution_id = aila.po_distribution_id )
    group by 
       type, i.org_id, i.invoice_id, i.vendor_id, i.vendor_site_id, i.invoice_type_lookup_code,
       i.invoice_num, i.description, i.invoice_currency_code, i.invoice_amount, i.amount_paid, 
       i.payment_currency_code, i.wfapproval_status, i.doc_category_code, i.invoice_date,
       i.payment_num, i.external_bank_account_id, i.payment_method_code, i.due_date, 
       i."NUMÉRO_INVOICE", 
       ecart_prix, ecart_qte, litige_actif, litige_leve, facture_eq, pb_commande, nb_blocages, statut_compta, pda.po_header_id
  ),
  interfaced_invoices as (
    -- Les factures interfacées
    select 'OPEN_INTERFACE' as type, aii.org_id, aii.invoice_id, aii.vendor_id, aii.vendor_site_id, aii.invoice_type_lookup_code,
           aii.invoice_num, aii.description, aii.invoice_currency_code, aii.invoice_amount, 0 as amount_paid, 
           nvl(aii.payment_currency_code, aii.invoice_currency_code) as payment_currency_code, null as wfapproval_status, aii.doc_category_code, aii.invoice_date,
           null as payment_num, null as external_bank_account_id, null as payment_method_code, null as due_date, 
           aii.attribute3 as "NUMÉRO_INVOICE",
           0 as ecart_prix, 0 as ecart_qte, 0 as litige_actif, 0 as litige_leve, 1 as facture_eq, 0 as pb_commande, 0 as nb_blocages, 'Non' as statut_compta,
           null as po_header_id, 0.00 as montant_ht, 0.00 as total_lignes, 'PASSERELLLE' as statut_validation      
    from ap_invoices_interface aii
    where aii.invoice_type_lookup_code != 'EXPENSE REPORT'    
  ), 
  all_invoices as (
    -- L'ensemble des factures a extraire
    select * from invoices4
    union all
    select * from interfaced_invoices
  )
  -- Requete principale
  SELECT  gv_SYSTEM_ORIGINE                                                           "SYSTEM_ORIGINE",
          aia.vendor_id                                                                "ID_FOURNISSEUR",
          aia.vendor_site_id                                                           "ID_SITE",
          K_DIVISION                                                                   "DIVISION",
          aia.invoice_id                                                               "ID_FACTURE",
          s.company_code                                                               "CODE_SOCIETE",
          SUBSTR (s.company_name, 1, 50)                                               "NOM_SOCIETE",
          SUBSTR (haou.name, 1, 3)                                                     "CODE_REGION",
          flv.displayed_field                                                          "TYPE_FACTURE",
          fdsc.name                                                                    "NOM_TYPE_FACTURE",
          REPLACE (aia.invoice_num, ';', ',')                                          "NUM_FACTURE",
          REPLACE (aia.description, ';', ',')                                          "DESCRIPTION",
          greatest(least(aia.invoice_date, date'2078-12-31'), date'1900-01-01')        "DATE_FACTURE",
          aia.invoice_currency_code                                                    "DEVISE_FACTURE",
          --aia.invoice_amount                                                           "MONTANT_TTC",
          aia.total_lignes                                                             "TOTAL_LIGNE",
          aia.montant_ht                                                               "MONTANT_HT",
          aia.po_header_id                                                             "ID_COMMANDE",          
          NVL (aia.amount_paid, 0)                                                     "MONTANT_REG",
          0                                                                            "MONTANT_ACOMPTE",
          aia.payment_currency_code                                                    "DEVISE",
          DECODE (aia.payment_method_code,
                  'CHECK',    'Cheque',
                  'CLEARING', 'LCR',
                  'WIRE',     'Prélevement',
                  'EFT',      'Virement')                                              "MODE_REGLEMENT",
          greatest(least(TRUNC(aia.due_date), date'2078-12-31'), date'1900-01-01')     "DATE_ECHEANCE",
          replace(ieba.bank_number || '.' || ieba.branch_number || '.' || ieba.bank_account_number || '.' || ieba.check_digits, '...', null) as "COMPTE_REGLEMENT",  
          aia.nb_blocages                                                              "NB_BLOCAGES",
          statut_validation                                                            "STATUT_VALIDATION",
          statut_compta                                                                "STATUT_COMPTA",          
          DECODE (aia.wfapproval_status,
                  'WFAPPROVED',         'Approuvé',
                  'INITIATED',          'Lancé',
                  'MANUALLY APPROVED',  'Approuvé manuellement',
                  'NOT REQUIRED',       'Non obligatoire',
                  'REJECTED',           'Rejeté',
                  'REQUIRED',           'Obligatoire')                                 "STATUT_WF",
          decode(aia.ecart_prix, 0, 'N', 'O')                                          "ECART_PRIX",
          decode(ecart_qte, 0, 'N', 'O')                                               "ECART_QTY",
          decode(pb_commande, 0, 'N', 'O')                                             "PB_COMMANDE",
          decode(litige_actif, 0, 'N', 'O')                                            "LITIGE_ACTIF",
          decode(litige_leve, 0, 'N', 'O')                                             "LITIGE_LEVE",
          decode(facture_eq, 0, 'N', 'O')                                              "FACTURE_EQ",
          NULL                                                                         "URL_FACTURE",
          aia."NUMÉRO_INVOICE"                                                         "LAD_XEROX"
  from            all_invoices                   aia
  join            hr_all_organization_units      haou  on (haou.organization_id = aia.org_id)
  left outer join ap_lookup_codes                flv   on (flv.lookup_code = aia.invoice_type_lookup_code and flv.lookup_type = 'INVOICE TYPE')
  left outer join fnd_doc_sequence_categories    fdsc  on (fdsc.code = aia.doc_category_code and fdsc.application_id = 200 AND fdsc.table_name = 'AP_INVOICES_ALL')
  left outer join societes                       s     on (s.company_code = SUBSTR (haou.name, -4, 4))
  left outer join IBY_EXTERNAL_BANK_ACCOUNTS_V   ieba  on (ieba.ext_bank_account_id = aia.external_bank_account_id);
    
  /*
     TOTAL_LIGNES      Total des lignes (tous types confondus)
     MONTANT_HT        Somme des lignes d'ITEM (ou MISC). Montant hors taxe de la facture qui est rapproché de la commande ID_COMMANDE (si rapprochée)
     ID_COMMANDE       La ou les commandes rapprochées aux lignes de la facture
     STATUT_COMPTA     Oui = Toutes les lignes sont comptabilisées. Non = Aucune ligne comptabilisée. Partiel = pas toutes
     NB_BLOCAGES       Nombre de blocages pas débloqués de cette facture
     ECART_PRIX        O = présence d'un blocage PRICE ou MAX SHIP AMOUNT pas débloqué
     ECART_QTY         O = présence d'un blocage QTY REC ou QTY ORD pas débloqué
     LITIGE_ACTIF      O = présence d'un blocage En litige pas débloqué
     LITIGE_LEVE       O = présence d'un blocage En litige débloqué
     FACTURE_EQ        O = présence d'un blocage DIST VARIANCE
     PB_COMMANDE       O = présence d'un blocage 'Incohérence commande', 'Blocage Fres Multi Cde', 'Commande inconnue' ou 'Blocage cmde + 6 lignes' pas débloqué 
     STATUT_VALIDATION 'PASSERELLE' si dans l'open-interface, 'Annulé' si annulée', 'Validé' si plus de blocage, 'A revalider' sinon.
  */     
  
    
  Extract_CSV( 'CRM_FACT_NONREG_', l_cursor1);

  put_debug_message('FIN ' || lv_current_program_unit);  
exception
  when Others then 
    put_debug_message('ERREUR ' || lv_current_program_unit || ' : ' || SQLERRM);
    raise;  
END Factures_non_payees;


---------------------------------------------------------------------------------------------------------------
  --  Nom           : Commandes
  --  Description   : Extraction des Commandes
  --
  --  PARAMETRES    : aucun
---------------------------------------------------------------------------------------------------------------
procedure Commandes
IS
  lv_current_program_unit constant varchar2(32) := 'Commandes';
  l_start_time            TIMESTAMP := current_timestamp;
  l_cursor1               SYS_REFCURSOR;
  l_cursor_num            integer;
  l_record_count          pls_integer;
  l_elapsed               number;
BEGIN
  put_debug_message('DEBUT ' || lv_current_program_unit);
  
  -- La ligne ci-dessous est nécessaire pour éviter l'erreur ORA-01792 maximum number of columns in a table or view is 1000 
  -- Voir "Select Statement Throws ORA-01792 Error in 12c" (Doc ID 1951689.1)
  execute immediate q'[alter session set "_fix_control"='17376322:OFF']';      

  OPEN l_cursor1 FOR 
  WITH societes as (
    select gl.ledger_id, ffv.flex_value as company_code, ffv.description as company_name
    from gl_ledgers               gl
    join fnd_id_flex_segments     fifs on (gl.chart_of_accounts_id = fifs.id_flex_num)
    join fnd_flex_values_vl       ffv  on (ffv.flex_value_set_id = fifs.flex_value_set_id)
    where 1=1
      and fifs.application_id=101
      and fifs.id_flex_code='GL#'
      and fifs.segment_name = 'SOCIETE'
  )  
   SELECT  gv_SYSTEM_ORIGINE                                                      "SYSTEM_ORIGINE",
           pha.vendor_site_id                                                      "ID_FOURNISSEUR",
           pha.vendor_id                                                           "ID_SITE",
           K_DIVISION                                                              "DIVISION",
           pha.po_header_id                                                        "ID_COMMANDE",
           MIN (gcc.segment1)                                                      "CODE_SOCIETE",
           MIN (s.company_name)                                                    "NOM_SOCIETE",
           MIN (gcc.segment2)                                                      "CODE_REGION",
           pha.segment1                                                            "NUM_COMMANDE",
           TRUNC (pha.creation_date)                                               "DATE_COMMANDE",
           NVL (ROUND (SUM (pla.quantity * pla.unit_price), 2), 0)                 "MONTANT_COMMANDE",
           NVL (ROUND (SUM (plla.QUANTITY_BILLED * pla.unit_price), 2), 0)         "MONTANT_FACTURE",
           fu.description                                                          "ACHETEUR",
           flv.displayed_field                                                     "STATUT_APPROB",
           flv2.displayed_field                                                    "STATUT_FERMETURE",
           pha.revision_num                                                        "VERSION",
           CASE
              WHEN NVL (ROUND (SUM (plla.QUANTITY_RECEIVED * pla.unit_price), 2), 0) = 0 THEN 'N'
              WHEN NVL (ROUND (SUM (plla.QUANTITY_RECEIVED * pla.unit_price), 2), 0) >= 
                     NVL (ROUND (SUM (pla.quantity * pla.unit_price), 2), 0)             THEN 'O'
              ELSE 'P'
           END                                                                     "COMMANDE_REC",
           CASE
              WHEN NVL (ROUND (SUM (plla.QUANTITY_BILLED * pla.unit_price), 2), 0) = 0 THEN 'N'
              WHEN NVL (ROUND (SUM (plla.QUANTITY_BILLED * pla.unit_price), 2), 0) >= 
                     NVL (ROUND (SUM (pla.quantity * pla.unit_price), 2), 0)           THEN 'O'
              ELSE 'P'
           END                                                                     "COMMANDE_FAC",
           NULL                                                                    "URL_COMMANDE"
      FROM po_headers_all                     pha
      join FND_USER                           fu    on (pha.created_by = fu.user_id)
      join po_lookup_codes                    flv   on (flv.lookup_code = pha.authorization_status AND flv.lookup_type = 'AUTHORIZATION STATUS')
      join po_lookup_codes                    flv2  on (flv2.lookup_code = pha.closed_code AND flv2.lookup_type = 'DOCUMENT STATE')
      join PO_LINES_ALL                       pla   on (pha.po_header_id = pla.po_header_id)
      join PO_LINE_LOCATIONS_ALL              plla  on (pla.po_line_id = plla.PO_line_ID)
      join po_distributions_all               pda   on (pda.line_location_id = plla.line_location_id)
      join gl_code_combinations               gcc   on (gcc.code_combination_id = pda.code_combination_id)
      join societes                           s     on (s.ledger_id = pda.set_of_books_id and s.company_code = gcc.segment1)         
     WHERE 1=1
           AND pha.type_lookup_code != 'CONTRACT'
           AND (exists (select 'Une facture non payée rapprochée de cette commande' 
                        from ap_invoices_all aia
                        join ap_invoice_distributions_all aida on (aida.invoice_id = aia.invoice_id)
                        where aida.po_distribution_id = pda.po_distribution_id
                          and aia.payment_status_flag != 'Y' )
                OR NVL(pha.CLOSED_CODE,'OPEN') = 'OPEN'
                   AND pha.CLOSED_DATE IS NULL
                   AND EXISTS (SELECT 'Au moins une ligne non facturée'
                               FROM po_lines_all          pla2 
                               JOIN po_line_locations_all plla2 on (pla2.po_line_id = plla2.po_line_id)
                               WHERE pla2.po_header_id = pha.po_header_id 
                                 AND plla2.quantity_billed = 0)
               )
           --AND ( (gv_SYSTEM_ORIGINE = 'ORA_DAL' AND pha.org_id = 81) OR (gv_SYSTEM_ORIGINE = 'ORA_CSP' AND pha.org_id != 81))
  GROUP BY gv_SYSTEM_ORIGINE,
           pha.vendor_site_id,
           pha.vendor_id,
           pha.po_header_id,
           pha.segment1,
           pha.creation_date,
           pha.currency_code,
           fu.description,
           flv.displayed_field,
           flv2.displayed_field,
           pha.revision_num;
          
  Extract_CSV( 'CRM_COMMANDES_', l_cursor1);

  put_debug_message('FIN ' || lv_current_program_unit);  
exception
  when Others then 
    put_debug_message('ERREUR ' || lv_current_program_unit || ' : ' || SQLERRM);
    raise;  
END Commandes;


---------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure principale du traitement.
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
---------------------------------------------------------------------------------------------------------------
PROCEDURE main(
  pv_errbuf                   IN OUT VARCHAR2, 
  pn_retcode                  OUT NUMBER)
IS
  lv_current_program_unit constant varchar2(32) := $$PLSQL_UNIT;
  rec_param               dka_parameters%ROWTYPE;
BEGIN
  pn_retcode := 0;
  pv_errbuf  := NULL;
  put_debug_message('DEBUT ' || lv_current_program_unit);

   Dka_Tools_Pkg.get_parameter('XXVE_CRM01',
                 'SYSTEM_ORIGINE_DKA',
                 rec_param,
                 pv_errbuf,
                 pn_retcode);
   gv_SYSTEM_ORIGINE := rec_param.varchar2_value;  
  
  -- Création des 5 fichiers CSV
  Fournisseurs;
  Reglements;
  Factures_payees;
  Factures_non_payees;
  Commandes;

  put_debug_message('FIN ' || lv_current_program_unit);  
EXCEPTION
  WHEN OTHERS THEN
    put_debug_message('ERREUR ' || lv_current_program_unit || ' : ' || SQLERRM);
    pv_errbuf  := SQLERRM(SQLCODE);
    pn_retcode := 2;
END main;
    
END DKA_IEOARCRM01_PKG; -- Corps du package
/

SHOW ERRORS
EXIT;     