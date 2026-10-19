create or replace package body DKA_XLA_AR_CUSTOM_SOURCES_PKG as
  -- -----------------------------------------------------------------------------------------
  -- Program     : DKA_XLA_AR_CUSTOM_SOURCES_PKG
  -- $Header     : DKA_XLA_AR_CUSTOM_SOURCES_PKG.pks 1.0 2016/10/14 00:00:00 jlaunay $
  -- Description : Source spécifiques pour le SLA
  -- -----------------------------------------------------------------------------------------
  -- Historique des modifications
  -- Version  Date        Auteur
  --          Description
  -- -----------------------------------------------------------------------------------------
  -- 1.0      2016/10/14  Josselin LAUNAY
  --          Version Initiale
  -- 1.1      2019/10/09  NBO   artf07236536 - INC0306578 encaissements non lettrés  
  -- -----------------------------------------------------------------------------------------
  c_level_statement     constant number       := fnd_log.level_statement;
  c_level_procedure     constant number       := fnd_log.level_procedure;
  c_level_event         constant number       := fnd_log.level_event;
  c_level_exception     constant number       := fnd_log.level_exception;
  c_level_error         constant number       := fnd_log.level_error;
  c_level_unexpected    constant number       := fnd_log.level_unexpected;
  c_level_log_disabled  constant number       := 99;

  g_log_level           number := fnd_log.g_current_runtime_level;
  g_log_package         varchar2(1000) := 'DKA_XLA_AR_CUSTOM_SOURCES_PKG';
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
      app_exception.raise_exception( exception_text => 'unexpected error in procedure Trace') ;
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
      app_exception.raise_exception( exception_text => 'unexpected error in procedure Init_Module') ;
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
      app_exception.raise_exception( exception_text => 'unexpected error in procedure Exit_Module') ;
  end Exit_Module;
  
  -- -----------------------------------------------------------------------------------------
  -- get_Rcpt_Customer_Detail
  --
  -- Called by Customs Sources
  --    Receivables : DKA_AR_RCPT_CUSTOMER_NAME
  --                  DKA_AR_RCPT_CUSTOMER_NUMBER
  --                  DKA_AR_RCPT_CUSTOMER_SITE
  --
  -- Parameters :
  --    p_cash_receipt_hist_id => Cash receipt history ID
  --    p_detail_type          => Type of customer information to deliver
  --                              Possible values : NAME, NUMBER, SITE
  --
  -- Output :
  --    Customer detail
  -- -----------------------------------------------------------------------------------------

  function  get_Rcpt_Customer_Detail (
             p_cash_receipt_hist_id  in number,
             p_detail_type           in varchar2
            )
    return varchar2
  is
    c_log_module          varchar2(100) := g_log_package||'.get_Rcpt_Customer_Detail';

    lv_customer_detail    varchar2(50);

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
    Trace('Cash receipt history ID : '||p_cash_receipt_hist_id, c_level_statement);  
    Trace('Customer information : '||p_detail_type, c_level_statement);  

    --
    -- Build select statement for Tax code
    --
    l_sql := '
    select  case '''||p_detail_type||'''
              when ''NUMBER'' then hca.account_number
              when ''NAME'' then hp.party_name
              when ''SITE'' then hcsu.location
            end
    from    ar_cash_receipt_history_all acrh
            join ar_cash_receipts_all acr
              on acrh.cash_receipt_id = acr.cash_receipt_id
            left outer join hz_cust_accounts_all hca
              on acr.pay_from_customer = hca.cust_account_id
            left outer join hz_parties hp
              on hca.party_id = hp.party_id
            left outer join hz_cust_site_uses_all hcsu
              on acr.customer_site_use_id = hcsu.site_use_id
    where   acrh.cash_receipt_history_id = '||p_cash_receipt_hist_id;

    Trace('SQL statement : '||l_sql, c_level_statement);

    execute immediate l_sql into lv_customer_detail;
    
    Trace('Customer information is : '||lv_customer_detail, c_level_statement);      
    
    --
    -- Reset function login procedure
    --
    Exit_Module;
    
    return lv_customer_detail;

  exception
    when others then
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
  end get_Rcpt_Customer_Detail;  
  
  -- -----------------------------------------------------------------------------------------
  -- get_hz_cust_acct_sites_att8
  --
  -- Called by Customs Sources
  --    Receivables : DKA_AR_CUST_ACCT_SITES_ATT8
  --
  -- Parameters :
  --    p_cust_acct_site_id
  --
  -- Output :
  --    Interco détail
  -- -----------------------------------------------------------------------------------------
  -- 1.1      2019/10/09  NBO   artf07236536 - INC0306578 encaissements non lettrés  

  function  get_hz_cust_acct_sites_att8 (
             p_cust_acct_site_id  in number,
             p_cust_acct_id in number,
             p_org_id in number
            )
    return varchar2
  is
    c_log_module          varchar2(100) := g_log_package||'.get_hz_cust_acct_sites_att8';
    l_sql VARCHAR2(4000);
    lv_att8 VARCHAR2(150);

  begin
    --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;

    --
    -- Display parameters for debug purpose
    --
    Trace('p_cust_acct_site_id : '||p_cust_acct_site_id, c_level_statement);  
    Trace('p_cust_acct_id : '||p_cust_acct_id, c_level_statement);  
    Trace('p_org_id : '||p_org_id, c_level_statement);  
    
    IF (p_cust_acct_site_id IS NULL) THEN
      
      IF (p_cust_acct_id IS NULL OR p_org_id IS NULL) THEN
        RETURN '';
      END IF;
      
      SELECT attribute8
        INTO lv_att8
        FROM hz_cust_acct_sites_all
       WHERE cust_account_id = p_cust_acct_id
         AND org_id = p_org_id
         AND bill_to_flag = 'P'
         AND rownum = 1;

	ELSE
	    --
	    -- Build select statement for Tax code
	    --
	    --l_sql := 'select attribute8 from HZ_CUST_ACCT_SITES_ALL where cust_acct_site_id = '||p_cust_acct_site_id;
	    l_sql := 'select attribute8 from HZ_CUST_ACCT_SITES_ALL where party_site_id = '||p_cust_acct_site_id || ' and rownum = 1';
	
	    Trace('SQL statement : '||l_sql, c_level_statement);
	
	    execute immediate l_sql into lv_att8;
    END IF;
   
    
    Trace('Interco information is : '||lv_att8, c_level_statement);      
    
    --
    -- Reset function login procedure
    --
    Exit_Module;
    
    return lv_att8;

  exception
    when others then
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
  end get_hz_cust_acct_sites_att8;  

  -- -----------------------------------------------------------------------------------------
  -- get_profile_class
  --
  -- Called by Customs Sources
  --    Receivables : DKA_AR_CUST_ACCT_PROFILE_CLASS
  --
  -- Parameters :
  --    p_cust_acct_site_id
  --
  -- Output :
  --    Profile Class
  -- -----------------------------------------------------------------------------------------
  -- 1.1      2019/10/09  NBO   artf07236536 - INC0306578 encaissements non lettrés  
  function  get_profile_class (
             p_cust_acct_id  in number
            )
    return varchar2
  is
    c_log_module          varchar2(100) := g_log_package||'.get_profile_class';
    l_sql VARCHAR2(4000);
    lv_profile_class VARCHAR2(150);

  begin
    --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;

    --
    -- Display parameters for debug purpose
    --
    --Trace('p_cust_acct_site_id : '||p_cust_acct_site_id, c_level_statement);  
    Trace('p_cust_acct_site_id : '||p_cust_acct_id, c_level_statement);  
    
    --IF (p_cust_acct_site_id IS NULL) THEN
    IF (p_cust_acct_id IS NULL) THEN
      RETURN '';
    END IF;
    
    --
    -- Build select statement for Tax code
    --
    --l_sql := 'select attribute8 from HZ_CUST_ACCT_SITES_ALL where cust_acct_site_id = '||p_cust_acct_site_id;
    --l_sql := 'SELECT hcpc.name FROM hz_customer_profiles hcp, hz_cust_profile_classes hcpc WHERE hcp.site_use_id = '||p_cust_acct_site_id||' AND hcp.profile_class_id = hcpc.profile_class_id';
    l_sql := 'SELECT hcpc.name FROM hz_customer_profiles hcp, hz_cust_profile_classes hcpc WHERE hcp.profile_class_id = hcpc.profile_class_id AND hcp.cust_account_id =  '||p_cust_acct_id||' AND hcp.site_use_id  is null';

    Trace('SQL statement : '||l_sql, c_level_statement);

    execute immediate l_sql into lv_profile_class;
    
    Trace('Profile Class information is : '||lv_profile_class, c_level_statement);      
    
    --
    -- Reset function login procedure
    --
    Exit_Module;
    
    return lv_profile_class;

  exception
    when no_data_found then
      return null;
    when others then
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
  end get_profile_class;  

  -- -----------------------------------------------------------------------------------------
  -- get_tax_code
  --
  -- Called by Customs Sources
  --    Receivables : DKA_AR_TRX_TAX_TAXCODE,
  --                  DKA_AR_TRX_LINE_TAXCODE,
  --                  DKA_AR_CM_TAX_TAXCODE
  -- Parameters :
  --    P_CUSTOMER_TRX_LINE_ID
  --    P_WHERE (LINE, ETAX
  --
  -- Output :
  --    Tax Code
  -- -----------------------------------------------------------------------------------------

 FUNCTION get_tax_code(p_customer_trx_line_id IN NUMBER,
                       p_where                IN VARCHAR2) RETURN VARCHAR2 IS
   c_log_module     VARCHAR2(100) := g_log_package || '.get_tax_code';
   l_sql            VARCHAR2(4000) := NULL;
   lv_tax_code      VARCHAR2(150);
 
 BEGIN
   --
   -- Activate function login procedure
   --
   init_module(p_log_module => c_log_module);
 
   --
   -- Display parameters for debug purpose
   --
   trace('P_CUSTOMER_TRX_LINE_ID : ' || p_customer_trx_line_id,
         c_level_statement);
   trace('p_where : ' || p_where,
         c_level_statement);
         
   IF (p_customer_trx_line_id IS NULL) THEN
     RETURN '';
   END IF;
   
   IF (p_where = 'LINE') THEN
     --
     -- Build select statement for Tax code
     --
     l_sql := 'SELECT zl.tax_rate_code
              FROM ra_customer_trx_lines_all rctla, zx_lines zl
              WHERE rctla.customer_trx_line_id = ' || p_customer_trx_line_id || ' AND rctla.customer_trx_line_id = zl.trx_line_id
              AND rctla.customer_trx_id = zl.trx_id
              AND zl.application_id = 222';
 
     trace('SQL statement : ' || l_sql, c_level_statement);
 

   ELSIF (p_where = 'ETAX') THEN
     --
     -- Build select statement for Tax code
     --
     l_sql := 'select tax_rate_code from ZX_LINES where TAX_LINE_ID = ' || p_customer_trx_line_id;
 
     trace('SQL statement : ' || l_sql, c_level_statement);     
   END IF;
   
   IF l_sql IS NOT NULL THEN
     EXECUTE IMMEDIATE l_sql
     INTO lv_tax_code;
   END IF;
   
   --
   -- Reset function login procedure
   --
   exit_module;
 
   RETURN lv_tax_code;
 
 EXCEPTION
   WHEN no_data_found THEN
     RETURN NULL;
   WHEN OTHERS THEN
     app_exception.raise_exception(exception_text => 'unexpected error in procedure ' ||
                                                     c_log_module || ', ' ||
                                                     SQLERRM);
 END get_tax_code;
  
end DKA_XLA_AR_CUSTOM_SOURCES_PKG;
/
SHOW ERRORS PACKAGE BODY DKA_XLA_AR_CUSTOM_SOURCES_PKG;
EXIT
