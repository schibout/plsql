create or replace package body DKA_XLA_AP_CUSTOM_SOURCES_PKG as
  -- -----------------------------------------------------------------------------------------
  -- Program     : DKA_XLA_AP_CUSTOM_SOURCES_PKG
  -- $Header     : DKA_XLA_AP_CUSTOM_SOURCES_PKG.pks 1.1 2016/10/14 00:00:00 jlaunay $
  -- Description : Source spécifiques pour le SLA
  -- -----------------------------------------------------------------------------------------
  -- Historique des modifications
  -- Version  Date        Auteur
  --          Description
  -- -----------------------------------------------------------------------------------------
  -- 1.0      2016/10/14  Josselin LAUNAY
  --          Version Initiale
  -- 1.1      2017/02/06  Josselin LAUNAY
  --          artf2096323 : SPE200 - DEFECT531 - AP - Comptabilisation des pièces DALKIA
  -- 1.2      2018/02/26 Nicolas BOUSSEKEYT
  --          artf2388535 : SPE200 - Faire la recherche du 10ème caractère du code de taxe avec la code TVA de la ligne AP sans le rechercher dans eTax
  -- -----------------------------------------------------------------------------------------
  c_level_statement     constant number       := fnd_log.level_statement;
  c_level_procedure     constant number       := fnd_log.level_procedure;
  c_level_event         constant number       := fnd_log.level_event;
  c_level_exception     constant number       := fnd_log.level_exception;
  c_level_error         constant number       := fnd_log.level_error;
  c_level_unexpected    constant number       := fnd_log.level_unexpected;
  c_level_log_disabled  constant number       := 99;

  g_log_level           number := fnd_log.g_current_runtime_level;
  g_log_package         varchar2(1000) := 'DKA_XLA_AP_CUSTOM_SOURCES_PKG';
  g_log_enabled         boolean := false;

  g_log_module_parent   varchar2(1000);
  g_log_module          varchar2(1000);

  -- -----------------------------------------------------------------------------------------
  -- Trace
  --
  -- Create a trace of the program execution
  --
  -- The loging activation is managed by the Profile Options
  --    - "FND: Debug Log Enabled"
  --    - "FND: Debug Log Level"
  --    - "FND: Debug Log Module"
  --
  -- Log messages are written in FND_LOG_MESSAGES
  --
  -- Parametres :
  --    p_msg => Message
  --    p_level => Level of the message
  --    p_module => Module tu be traced
  -- -----------------------------------------------------------------------------------------
  procedure Trace (
      p_msg    in varchar2,
      p_level  in number default c_level_statement,
      p_module in varchar2 default g_log_module )
  is
  begin
    fnd_log.string(p_level, p_module, p_msg);

  exception
    when app_exception.application_exception then
      raise;
    when others then
      -- 1.2  2018/02/26 NBO - artf2388535 : SPE200 - Faire la recherche du 10ème caractère du code de taxe avec la code TVA de la ligne AP sans le rechercher dans eTax
      --app_exception.raise_exception( exception_text => 'unexpected error in procedure Trace') ;
      xla_exceptions_pkg.raise_message(p_location => 'unexpected error in procedure Trace');
  end Trace;

  -- -----------------------------------------------------------------------------------------
  -- Init_Module
  --
  -- Initialize logging module
  --
  -- Parameters :
  --    p_log_module => Module name
  -- -----------------------------------------------------------------------------------------
  procedure Init_Module (
      p_log_module    in varchar2 )
  is
  begin
    if g_log_enabled then
      Fnd_Profile.Put('AFLOG_ENABLED', 'Y');
      Fnd_Profile.Put('AFLOG_MODULE', g_log_package||'%');
      Fnd_Profile.Put('AFLOG_LEVEL', c_level_statement);

      g_log_enabled := false;
    end if;

    g_log_module_parent := g_log_module;
    g_log_module := p_log_module;

    Trace('+---------------------------------------------------------------------------+');
    Trace('Begin '||g_log_module, c_level_procedure);

  exception
    when app_exception.application_exception then
      raise;
    when others then
      -- 1.2  2018/02/26 NBO - artf2388535 : SPE200 - Faire la recherche du 10ème caractère du code de taxe avec la code TVA de la ligne AP sans le rechercher dans eTax
      xla_exceptions_pkg.raise_message(p_location => 'unexpected error in procedure Init_Module');
  end Init_Module;

  -- -----------------------------------------------------------------------------------------
  -- Exit_Module
  --
  -- Restore previous logging module
  --
  -- -----------------------------------------------------------------------------------------
  procedure Exit_Module
  is
  begin
    Trace('End '||g_log_module, c_level_procedure);
    Trace('+---------------------------------------------------------------------------+');

    g_log_module := g_log_module_parent;
  exception
    when app_exception.application_exception then
      raise;
    when others then
      -- 1.2  2018/02/26 NBO - artf2388535 : SPE200 - Faire la recherche du 10ème caractère du code de taxe avec la code TVA de la ligne AP sans le rechercher dans eTax
      --app_exception.raise_exception( exception_text => 'unexpected error in procedure Exit_Module') ;
      xla_exceptions_pkg.raise_message
           (p_location => 'unexpected error in procedure Exit_Module');
  end Exit_Module;

  -- -----------------------------------------------------------------------------------------
  -- get_Segment_Column
  --
  -- Parametres :
  --    p_ledger_id       => Identifiant du livre de compte
  --    p_segment_type    => Qualificatif du segment recherché
  --                        Possible values :
  --                          GL_ACCOUNT
  --                          XARGOS_ACCOUNT
  --
  -- Sortie :
  --    Application column name
  -- -----------------------------------------------------------------------------------------
  function  get_Segment_Column_Name (
             p_ledger_id in number,
             p_segment_type in varchar2
            )
    return varchar2
  is
    c_log_module          varchar2(100) := g_log_package||'.get_Segment_Column_Name';

    lv_column_name        varchar2(50);
  begin
    --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;

    --
    -- Display parameters for debug purpose
    --
    Trace('Ledger ID : '||p_ledger_id, c_level_statement);
    Trace('Segment type : '||p_segment_type, c_level_statement);

    --
    -- Get column name
    --
    select  fsav.application_column_name
    into    lv_column_name
    from    gl_ledgers gl
            join fnd_segment_attribute_values fsav
              on fsav.application_id = 101
              and fsav.id_flex_code = 'GL#'
              and fsav.id_flex_num = gl.chart_of_accounts_id
    where   gl.ledger_id = p_ledger_id
    and     fsav.segment_attribute_type = p_segment_type
    and     fsav.attribute_value = 'Y'
    ;

    Trace('Column is : '||lv_column_name, c_level_statement);

    --
    -- Reset function login procedure
    --
    Exit_Module;

    return lv_column_name;

  exception
    when others then
      -- 1.2  2018/02/26 NBO - artf2388535 : SPE200 - Faire la recherche du 10ème caractère du code de taxe avec la code TVA de la ligne AP sans le rechercher dans eTax
      --app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
      xla_exceptions_pkg.raise_message
           (p_location => 'unexpected error in procedure '||c_log_module||', '||sqlerrm);
  end get_Segment_Column_Name;
  
  -- -----------------------------------------------------------------------------------------
  -- is_Asset_Line
  --
  -- Called by Customs Sources
  --    Payables : DKA_AP_IS_ASSET_LINE
  --
  -- Parameters :
  --    p_inv_dist_id => Invoice distribution ID
  --    p_ledger_id   => Ledger ID
  --
  -- Output :
  --    Y : The current line is an Asset line (using a clearing account or an asset tax code) 
  --    N : TThe current line is not an Asset line
  -- -----------------------------------------------------------------------------------------

  function  is_Asset_Line (
             p_inv_dist_id      in number,
             p_ledger_id        in number
            )
    return varchar2
  is
    c_log_module          varchar2(100) := g_log_package||'.is_Asset_Line';

    lv_column_name        varchar2(50);
    lv_account            varchar2(50);
    lv_tax_rate_code      varchar2(50);

    l_sql                 varchar2(4000);

    lv_is_Asset_Account   varchar2(50) := 'N';
    lv_is_Asset_Tax_Rate  varchar2(50) := 'N';
    
    lv_is_Asset_Line      varchar2(50) := 'N';
  begin
    --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;

    --
    -- Display parameters for debug purpose
    --
    Trace('Invoice distribution ID : '||p_inv_dist_id, c_level_statement);  
    Trace('Ledger ID : '||p_ledger_id, c_level_statement);  

    --
    -- Get the corresponding application column name
    --
    lv_column_name := get_Segment_Column_Name (
                         p_ledger_id    => p_ledger_id,
                         p_segment_type => 'GL_ACCOUNT');    

    --
    -- Build select statement from Account and Tax code
    --
    l_sql := '
    select  gcc.'||lv_column_name||',
            case when ail.line_type_lookup_code = ''TAX''
                then ail.tax_rate_code
                else ail.tax_classification_code
            end tax_rate_code
    from    ap_invoice_distributions_all aid
            join ap_invoice_lines_all ail
              on aid.invoice_id = ail.invoice_id
              and aid.invoice_line_number = ail.line_number
            join gl_code_combinations_kfv gcc
              on aid.dist_code_combination_id = gcc.code_combination_id
    where   aid.invoice_distribution_id = '||p_inv_dist_id||'
    union all
    select  gcc.'||lv_column_name||',
            case when ail.line_type_lookup_code = ''TAX''
                then ail.tax_rate_code
                else ail.tax_classification_code
            end tax_rate_code
    from    ap_self_assessed_tax_dist_all asatd
            join ap_invoice_lines_all ail
              on asatd.invoice_id = ail.invoice_id
              and asatd.invoice_line_number = ail.line_number
            join gl_code_combinations_kfv gcc
              on asatd.dist_code_combination_id = gcc.code_combination_id
    where   asatd.invoice_distribution_id = '||p_inv_dist_id;    


    Trace('SQL statement : '||l_sql, c_level_statement);

    execute immediate l_sql into lv_account, lv_tax_rate_code;
    
    Trace('GL account is : '||lv_account, c_level_statement);  
    Trace('Tax rate code is : '||lv_tax_rate_code, c_level_statement);      
    
    if lv_account is not null then

      Trace('Checking account : '||lv_account, c_level_statement);  

        select  case when count(1) > 0 
                     then 'Y'
                     else 'N'
                end 
        into    lv_is_Asset_Account
        from    fa_category_books fcb
                join gl_code_combinations_kfv gcc
                  on fcb.asset_clearing_account_ccid = gcc.code_combination_id
        where   gcc.segment3 = lv_account;
    end if;
    
    if lv_tax_rate_code is not null then

      Trace('Checking tax code : '||lv_tax_rate_code, c_level_statement);  

      -- 1.2  2018/02/26 NBO - artf2388535 : SPE200 - Faire la recherche du 10ème caractère du code de taxe avec la code TVA de la ligne AP sans le rechercher dans eTax
      /*select  case when substr(zr.tax_rate_code, 10, 1) = 'I' 
                   then 'Y'
                   else 'N'
              end 
      into    lv_is_Asset_Tax_Rate
      from    zx_rates_vl zr
      where   sysdate between nvl(zr.effective_from, sysdate - 1) and nvl(zr.effective_to, sysdate + 1)
      and     zr.tax_rate_code = lv_tax_rate_code;   */
      select case when substr(lv_tax_rate_code, 10, 1) = 'I' 
                   then 'Y'
                   else 'N'
              end 
      into    lv_is_Asset_Tax_Rate
      from dual;
    end if;    
    
    lv_is_Asset_Line := greatest(lv_is_Asset_Account, lv_is_Asset_Tax_Rate);

    Trace('Is line '||p_inv_dist_id||' an asset line ? : '||lv_is_Asset_Line, c_level_statement);
    
    --
    -- Reset function login procedure
    --
    Exit_Module;
    
    return lv_is_Asset_Line;

  exception
    when others then
      -- 1.2  2018/02/26 NBO - artf2388535 : SPE200 - Faire la recherche du 10ème caractère du code de taxe avec la code TVA de la ligne AP sans le rechercher dans eTax
      --app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
        xla_exceptions_pkg.raise_message
           (p_location => 'unexpected error in procedure '||c_log_module||', '||sqlerrm);
  end is_Asset_Line;

  -- -----------------------------------------------------------------------------------------
  -- get_Tax_Code
  --
  -- Called by Customs Sources
  --    Payables : DKA_AP_TAX_CODE
  --
  -- Parameters :
  --    p_inv_dist_id => Invoice distribution ID
  --    p_ledger_id   => Ledger ID
  --
  -- Output :
  --    Tax code
  -- -----------------------------------------------------------------------------------------

  function  get_Tax_Code (
             p_inv_dist_id      in number
             --p_ledger_id        in number
            )
    return varchar2
  is
    c_log_module          varchar2(100) := g_log_package||'.get_Tax_Code';

    lv_tax_rate_code      varchar2(50);

    l_sql                 varchar2(4000);

  begin
    --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;

    --
    -- Display parameters for debug purpose
    --
    Trace('Invoice distribution ID : '||p_inv_dist_id, c_level_statement);  
--    Trace('Ledger ID : '||p_ledger_id, c_level_statement);  

    --
    -- Build select statement for Tax code
    --
    l_sql := '
    select  case when ail.line_type_lookup_code = ''TAX''
                then ail.tax_rate_code
                else ail.tax_classification_code
            end tax_rate_code
    from    ap_invoice_distributions_all aid
            join ap_invoice_lines_all ail
              on aid.invoice_id = ail.invoice_id
              and aid.invoice_line_number = ail.line_number
    where   aid.invoice_distribution_id = '||p_inv_dist_id||'
    union all
    select  case when ail.line_type_lookup_code = ''TAX''
                then ail.tax_rate_code
                else ail.tax_classification_code
            end tax_rate_code
    from    ap_self_assessed_tax_dist_all asatd
            join ap_invoice_lines_all ail
              on asatd.invoice_id = ail.invoice_id
              and asatd.invoice_line_number = ail.line_number
    where   asatd.invoice_distribution_id = '||p_inv_dist_id;

    Trace('SQL statement : '||l_sql, c_level_statement);

    execute immediate l_sql into lv_tax_rate_code;
    
    Trace('Tax rate code is : '||lv_tax_rate_code, c_level_statement);      
    
    --
    -- Reset function login procedure
    --
    Exit_Module;
    
    return lv_tax_rate_code;

  exception
    when others then
      -- 1.2  2018/02/26 NBO - artf2388535 : SPE200 - Faire la recherche du 10ème caractère du code de taxe avec la code TVA de la ligne AP sans le rechercher dans eTax
      --app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
      xla_exceptions_pkg.raise_message(p_location => 'unexpected error in procedure '||c_log_module||', '||sqlerrm);
  end get_Tax_Code;
  
  -- -----------------------------------------------------------------------------------------
  -- get_Liability_Account
  --
  -- Called by Customs Sources
  --    Payables : DKA_AP_LIAB_ASSET_ACCT_LOC
  --               DKA_AP_LIAB_ASSET_ACCT_GRP
  --
  -- Parameters :
  --    p_inv_dist_id       =>  Invoice distribution ID
  --    p_ledger_id         =>  Ledger ID
  --    p_segment_type      =>  Type of account
  --                            Possible values :
  --                              GL_ACCOUNT
  --                              XARGOS_ACCOUNT
  --
  -- Output :
  --    Account segment value
  -- -----------------------------------------------------------------------------------------

  function  get_Liability_Account (
             p_inv_dist_id      in number,
             p_ledger_id        in number,
             p_segment_type     in varchar2
            )
    return varchar2
  is
    c_log_module          varchar2(100) := g_log_package||'.get_Liability_Account';
    
    cv_set_name_liab      varchar2(50) := 'DKA_AP_ASSET_LIAB_ACCOUNT';
    cv_set_name_grp       varchar2(50) := 'MIGR_GROUP_ACCOUNT_CLASS_BILAN';
    
    
    lv_column_name        varchar2(50);
    lv_account            varchar2(50);

    l_sql                 varchar2(4000);
    lv_errbuf             varchar2(4000);
  begin
    --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;

    --
    -- Display parameters for debug purpose
    --
    Trace('Invoice distribution ID : '||p_inv_dist_id, c_level_statement);  
    Trace('Ledger ID : '||p_ledger_id, c_level_statement);  
    Trace('Segment type : '||p_segment_type, c_level_statement);

    --
    -- Get the corresponding application column name
    --
    lv_column_name := get_Segment_Column_Name (
                         p_ledger_id    => p_ledger_id,
                         p_segment_type => 'GL_ACCOUNT');    

    --
    -- Build select statement from Account
    --
    l_sql := '
    select  gcc.'||lv_column_name||'
    from    ap_invoices_all ai
            join ap_invoice_distributions_all aid
              on ai.invoice_id = aid.invoice_id
            join gl_code_combinations_kfv gcc
              on ai.accts_pay_code_combination_id = gcc.code_combination_id
    where   aid.invoice_distribution_id = '||p_inv_dist_id||'
    union all
    select  gcc.'||lv_column_name||'
    from    ap_invoices_all ai
            join ap_self_assessed_tax_dist_all asatd
              on ai.invoice_id = asatd.invoice_id
            join gl_code_combinations_kfv gcc
              on ai.accts_pay_code_combination_id = gcc.code_combination_id
    where   asatd.invoice_distribution_id = '||p_inv_dist_id;    
    
    Trace('SQL statement : '||l_sql, c_level_statement);

    execute immediate l_sql into lv_account;

    Trace('Account is : '||lv_account, c_level_statement);
    
    --
    -- Map liability Account to Asset liability Account
    --    
    lv_account := dka_stransco_pkg.get_value_f (
                     pv_set_name            => cv_set_name_liab,
                     pd_date                => SYSDATE,
                     pv_errbuf              => lv_errbuf,
                     pv_param1              => lv_account
                     );

    if lv_errbuf is not null then
      Trace('Error transcoding from '||cv_set_name_liab||' : '||lv_errbuf, c_level_error);
    end if;

    --
    -- Map Local Account to Analytique Account
    --        
    if p_segment_type = 'XARGOS_ACCOUNT' then
      lv_account := dka_stransco_pkg.get_value_f (
                       pv_set_name            => cv_set_name_grp,
                       pd_date                => SYSDATE,
                       pv_errbuf              => lv_errbuf,
                       pv_param1              => lv_account
                       );      
    
      if lv_errbuf is not null then
        Trace('Error transcoding from '||cv_set_name_grp||' : '||lv_errbuf, c_level_error);
      end if;                       
    end if;
    
    Trace('Asset Account is : '||lv_account, c_level_statement);
    
    --
    -- Reset function login procedure
    --
    Exit_Module;
    
    return lv_account;

  exception
    when others then
      -- 1.2  2018/02/26 NBO - artf2388535 : SPE200 - Faire la recherche du 10ème caractère du code de taxe avec la code TVA de la ligne AP sans le rechercher dans eTax
      --app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
      xla_exceptions_pkg.raise_message(p_location => 'unexpected error in procedure '||c_log_module||', '||sqlerrm);
  end get_Liability_Account;
  
end DKA_XLA_AP_CUSTOM_SOURCES_PKG;
/
SHOW ERRORS PACKAGE BODY DKA_XLA_FA_CUSTOM_SOURCES_PKG;
EXIT
