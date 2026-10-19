create or replace package body DKA_XLA_FA_CUSTOM_SOURCES_PKG as
  -- -----------------------------------------------------------------------------------------
  -- Program     : DKA_XLA_FA_CUSTOM_SOURCES_PKG
  -- $Header     : DKA_XLA_FA_CUSTOM_SOURCES_PKG.pks 1.0 2016/10/14 00:00:00 jlaunay $
  -- Description : Source spécifiques pour le SLA
  -- -----------------------------------------------------------------------------------------
  -- Historique des modifications
  -- Version  Date        Auteur
  --          Description
  -- -----------------------------------------------------------------------------------------
  -- 1.0      2016/10/14  Josselin LAUNAY
  --          Version Initiale
  -- 1.1      2017/10/05  Nicolas BOUSSEKEYT
  --          artf2237548 : SPE205 - Modifications SLA FA : récupération des comptes d'annulation dans le CUF comptes de c atégorie - defect ORACLE_R12#969              
  --  1.2     31/10/2017  Nicolas BOUSSEKEYT
  --          artf2268989 - SPE037 et SPE205 - La transco MIGR_GROUP_ACCOUNT_CLASS_BILAN ne doit effectivement contenir que des comptes de bilan
  --  1.3     11/09/2018  Nicolas BOUSSEKEYT artf2664451 - INC0218966 - Erreur code flux_Cession d'immo 
 
  -- -----------------------------------------------------------------------------------------
  c_level_statement     constant number       := fnd_log.level_statement;
  c_level_procedure     constant number       := fnd_log.level_procedure;
  c_level_event         constant number       := fnd_log.level_event;
  c_level_exception     constant number       := fnd_log.level_exception;
  c_level_error         constant number       := fnd_log.level_error;
  c_level_unexpected    constant number       := fnd_log.level_unexpected;
  c_level_log_disabled  constant number       := 99;

  g_log_level           number := fnd_log.g_current_runtime_level;
  g_log_package         varchar2(1000) := 'DKA_XLA_FA_CUSTOM_SOURCES_PKG';
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
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
  end get_Segment_Column_Name;    

  -- -----------------------------------------------------------------------------------------
  -- is_TAX_Book
  --
  -- Called by Customs Sources
  --    Assets : DKA_IS_FA_TAX_BOOK
  --
  -- Parameters :
  --    p_book_type_code => Asset book type code
  --
  -- Output :
  --    Y : The current book type is a TAX book
  --    N : The current book type is not a TAX book
  -- -----------------------------------------------------------------------------------------  

  function  is_TAX_Book (
             p_book_type_code in varchar2
            )
    return varchar2
  is  
    c_log_module          varchar2(100) := g_log_package||'.is_TAX_Book';
    
    lv_is_TAX_Book        varchar2(50);
  begin
    --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;

    --
    -- Display parameters for debug purpose
    --
    Trace('Book Type Code : '||p_book_type_code, c_level_statement);    
            
    --
    -- Get column name
    --
    select  case  count(1)
                  when 1 then 'Y'
                  else 'N'
            end
    into    lv_is_TAX_Book
    from    fa_book_controls fbc
    where   fbc.book_type_code = p_book_type_code
    and     fbc.book_class = 'TAX'
    ;
    
    Trace('Is book type code '||p_book_type_code||' a TAX book ? : '||lv_is_TAX_Book, c_level_statement);

    --
    -- Reset function login procedure
    --
    Exit_Module;

    return lv_is_TAX_Book;
   
  exception
    when others then
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
  end is_TAX_Book;   
    
  -- -----------------------------------------------------------------------------------------
  -- is_IFRS_Category
  --
  -- Appel par les customs sources
  --    Assets : DKA_FA_IS_IFRS_CATEGORY
  --
  -- Parametres :
  --    p_category_id => Identifiant de la category FA
  --
  -- Sortie :
  --    Y : La categorie est IFRS
  --    N : La categorie n'est pas IFRS  
  -- -----------------------------------------------------------------------------------------
  function  is_IFRS_Category (
             p_category_id in number
            )
    return varchar2
  is
    c_log_module          varchar2(100) := g_log_package||'.is_IFRS_Category';
    
    lv_is_IFRS_Category   varchar2(1);
  begin
    --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;   

    --
    -- Display parameters for debug purpose
    --
    Trace('Category ID : '||p_category_id, c_level_statement);     
            
    --
    -- Check if a Tax book exists for the current category
    --
    select  case  count(1)
                  when 1 then 'Y'
                  else 'N'
            end
    into    lv_is_IFRS_Category
    from    fa_categories_vl fc
    where   1 = 1
    and     fc.category_id = p_category_id
    and     exists (
              select  1
              from    fa_category_books fcb
                      join fa_book_controls fbc
                        on fcb.book_type_code = fbc.book_type_code
              where   fc.category_id = fcb.category_id
              and     fbc.book_class = 'TAX'
            );
    
    Trace('Is category_id '||p_category_id||' IFRS ? : '||lv_is_IFRS_Category, c_level_statement);

    --
    -- Reset function login procedure
    --
    Exit_Module;

    return lv_is_IFRS_Category;
   
  exception
    when others then
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
  end is_IFRS_Category;

  -- -----------------------------------------------------------------------------------------
  -- get_IFRS_account
  --
  -- Called by Customs Sources
  --    Assets : DKA_FA_IFRS_COST_LOC_ACCT
  --             DKA_FA_IFRS_COST_GRP_ACCT
  --             DKA_FA_IFRS_CLEAR_LOC_ACCT
  --             DKA_FA_IFRS_CLEAR_GRP_ACCT
  --
  -- Parameters :
  --    p_category_id       =>  Asset category ID
  --    p_ledger_id         =>  Ledger ID
  --    p_segment_type      =>  Type of account
  --                            Possible values :
  --                              GL_ACCOUNT
  --                              XARGOS_ACCOUNT
  --    p_account_type      =>  Category of account
  --                            Possible values :
  --                              COST : Compte d'immobilisation
  --                              CLEARING : Lettrage des immobilisations
  --                              DEPRN_EXPENSE : Dotation amort.
  --                              DEPRN_RESERVE : Amortissement cumulé
  --                              BONUS_EXPENSE : Charges exceptionnelles
  --                              BONUS_RESERVE : Amortissement cumulé except.
  --                              REVAL_RESERVE : Plus-value de réévaluation
  --                              REVAL_AMORT : Amortissement de réévaluation
  --                              WIP_COST : Compte des productions à soi-même
  --                              WIP_CLEARING : Lettrage des productions à soi-même
  --                              IMPAIR_EXPENSE : Dotation pour dépréciation
  --                              IMPAIR_RESERVE : Dépréciation cumulée
  --                              UNPLAN_EXPENSE : Dotation aux amortissements non planif.
  --                              ALT_COST : Autre compte d'immobilisations
  --                              WRITE_OFF : Charges d'annulation
  --                              PROCEEDS_OF_SALE_GAIN : Plus-value de produit de cession
  --                              PROCEEDS_OF_SALE_LOSS : Moins-value de produit de cession
  --                              PROCEEDS_OF_SALE_CLEARING : Lettrage de produit de cession
  --                              COST_OF_REMOVAL_GAIN : Plus-value de cout de cession
  --                              COST_OF_REMOVAL_LOSS : Moins-value de cout de cession
  --                              COST_OF_REMOVAL_CLEARING : Lettrage de cout de cession 
  --                              NBV_RETIRED_GAIN : Plus-value de VNC
  --                              NBV_RETIRED_LOSS : Moins-value de VNC
  --                              REVAL_RSV_RETIRED_GAIN : Plus-value de réévaluation
  --                              REVAL_RSV_RETIRED_LOSS : Moins-value de réévaluation
  --                              DEFERRED_DEPRN_RESERVE : Provision pour écart d'amortissement
  --                              DEFERRED_DEPRN_EXPENSE : Ecarts de dotation aux amortissements
  --                              DEPRN_ADJUSTMENT : Ajustement des amortissements
  --
  -- Output :
  --    Natural Account segment value
  -- -----------------------------------------------------------------------------------------
  function  get_IFRS_account (
             p_category_id      in number,
             p_ledger_id        in number,
             p_segment_type     in varchar2,
             p_account_type     in varchar2
            )
    return varchar2
  is
    c_log_module          varchar2(100) := g_log_package||'.get_IFRS_account';
    
    lv_column_name        varchar2(50);
    lv_account            varchar2(50);
    
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
    Trace('Category ID : '||p_category_id, c_level_statement);    
    Trace('Ledger ID : '||p_ledger_id, c_level_statement);    
    Trace('Segment type : '||p_segment_type, c_level_statement);    
    Trace('Account type : '||p_account_type, c_level_statement);    
        
    --
    -- Get the corresponding application column name
    --
    lv_column_name := get_Segment_Column_Name (
                         p_ledger_id    => p_ledger_id,
                         p_segment_type => p_segment_type);

  -- 1.1      2017/10/05  Nicolas BOUSSEKEYT
  --          artf2237548 : SPE205 - Modifications SLA FA : récupération des comptes d'annulation dans le CUF comptes de c atégorie - defect ORACLE_R12#969              
    if p_account_type in (/*'COST', 'CLEARING', 'DEPRN_EXPENSE', 'DEPRN_RESERVE',*/ 'BONUS_EXPENSE', 'BONUS_RESERVE',
                          'REVAL_RESERVE', 'REVAL_AMORT', 'WIP_COST', 'WIP_CLEARING', 
                          'IMPAIR_EXPENSE', 'IMPAIR_RESERVE', 'UNPLAN_EXPENSE', 'ALT_COST', 'WRITE_OFF') then
      --
      -- Build select statement from Asset Categories
      --          
      l_sql := '
      select  gcc.'||lv_column_name||'
      from    fa_category_books fcb
              join fa_book_controls fbc
                on fcb.book_type_code = fbc.book_type_code
                and fbc.book_class = ''TAX''
              join gl_code_combinations_kfv gcc
                on case when '''||p_account_type||''' = ''COST''
                        then fcb.asset_cost_account_ccid
                        when '''||p_account_type||''' = ''CLEARING''
                        then fcb.asset_clearing_account_ccid
                        when '''||p_account_type||''' = ''DEPRN_EXPENSE''
                        then fcb.deprn_expense_account_ccid
                        when '''||p_account_type||''' = ''DEPRN_RESERVE''
                        then fcb.reserve_account_ccid
                        when '''||p_account_type||''' = ''BONUS_EXPENSE''
                        then fcb.bonus_expense_account_ccid
                        when '''||p_account_type||''' = ''BONUS_RESERVE''
                        then fcb.bonus_reserve_acct_ccid
                        when '''||p_account_type||''' = ''REVAL_RESERVE''
                        then fcb.reval_reserve_account_ccid 
                        when '''||p_account_type||''' = ''REVAL_AMORT''
                        then fcb.reval_amort_account_ccid 
                        when '''||p_account_type||''' = ''WIP_COST''
                        then fcb.wip_cost_account_ccid
                        when '''||p_account_type||''' = ''WIP_CLEARING''
                        then fcb.wip_clearing_account_ccid
                        when '''||p_account_type||''' = ''IMPAIR_EXPENSE''
                        then fcb.impair_expense_account_ccid
                        when '''||p_account_type||''' = ''IMPAIR_RESERVE''
                        then fcb.impair_reserve_account_ccid
                        when '''||p_account_type||''' = ''UNPLAN_EXPENSE''
                        then fcb.unplan_expense_account_ccid
                        when '''||p_account_type||''' = ''ALT_COST''
                        then fcb.alt_cost_account_ccid
                        when '''||p_account_type||''' = ''WRITE_OFF''
                        then fcb.write_off_account_ccid
                    end = gcc.code_combination_id
      where   fcb.category_id = '||p_category_id||'
      and     fbc.set_of_books_id = '||p_ledger_id;

    elsif p_account_type in ('PROCEEDS_OF_SALE_GAIN', 'PROCEEDS_OF_SALE_LOSS', 'PROCEEDS_OF_SALE_CLEARING',
                             'COST_OF_REMOVAL_GAIN', 'COST_OF_REMOVAL_LOSS', 'COST_OF_REMOVAL_CLEARING',
                             'NBV_RETIRED_GAIN', 'NBV_RETIRED_LOSS', 'REVAL_RSV_RETIRED_GAIN', 'REVAL_RSV_RETIRED_LOSS',
                             'DEFERRED_DEPRN_RESERVE', 'DEFERRED_DEPRN_EXPENSE', 'DEPRN_ADJUSTMENT') then
    
      --
      -- Build select statement from Asset bOOKS
      --          
      if p_segment_type = 'GL_ACCOUNT' then
        
        l_sql := '
        select  fbc.'||p_account_type||'_acct
        from    fa_category_books fcb
                join fa_book_controls fbc
                  on fcb.book_type_code = fbc.book_type_code
                  and fbc.book_class = ''TAX''
        where   fcb.category_id = '||p_category_id||'
        and     fbc.set_of_books_id = '||p_ledger_id;
        
      else 
        --  1.2     31/10/2017  Nicolas BOUSSEKEYT
        --          artf2268989 - SPE037 et SPE205 - La transco MIGR_GROUP_ACCOUNT_CLASS_BILAN ne doit effectivement contenir que des comptes de bilan
        --where   dth.set_name = ''MIGR_GROUP_ACCOUNT_CLASS_BILAN'' 
        l_sql := '
        select  dtl.return_value
        from    dka_stransco_headers dth
                join dka_stransco_lines dtl
                  on dth.set_id = dtl.set_id
        where   dth.set_name = ''DKA_TRANSCO_LOCAL_GROUPE''   
        and     dtl.enable = ''Y''
        and     sysdate between nvl(dtl.start_date, sysdate) and nvl(dtl.end_date, sysdate)
        and     dtl.param1_value in (
                  select  fbc.'||p_account_type||'_acct
                  from    fa_category_books fcb
                          join fa_book_controls fbc
                            on fcb.book_type_code = fbc.book_type_code
                            and fbc.book_class = ''TAX''
                  where   fcb.category_id = '||p_category_id||'
                  and     fbc.set_of_books_id = '||p_ledger_id||'
                )';
      
      end if;
  -- 1.1      2017/10/05  Nicolas BOUSSEKEYT
  --          artf2237548 : SPE205 - Modifications SLA FA : récupération des comptes d'annulation dans le CUF comptes de c atégorie - defect ORACLE_R12#969              
    elsif p_account_type in ('COST', 'CLEARING', 'DEPRN_EXPENSE', 'DEPRN_RESERVE') then
      
      l_sql := '
         SELECT CASE
            WHEN '''||p_account_type||''' = ''COST'' THEN
             fcb.attribute1
            WHEN '''||p_account_type||''' = ''CLEARING'' THEN
             fcb.attribute2
            WHEN '''||p_account_type||''' = ''DEPRN_EXPENSE'' THEN
             fcb.attribute3
            WHEN '''||p_account_type||''' = ''DEPRN_RESERVE'' THEN
             fcb.attribute4
          END
     FROM fa_category_books fcb
     JOIN fa_book_controls fbc ON fcb.book_type_code = fbc.book_type_code
                              AND fbc.book_class = ''CORPORATE''
      where   fcb.category_id = '||p_category_id||'
      and     fbc.set_of_books_id = '||p_ledger_id; 
      
      Trace('SQL statement : '||l_sql, c_level_statement);    
      
      execute immediate l_sql into lv_account;

      Trace('Account is : '||lv_account, c_level_statement);    
    
      if lv_account IS NULL then
    
        --
        -- Build select statement from Asset Categories
        --          
        l_sql := '
        select  gcc.'||lv_column_name||'
        from    fa_category_books fcb
                join fa_book_controls fbc
                  on fcb.book_type_code = fbc.book_type_code
                  and fbc.book_class = ''TAX''
                join gl_code_combinations_kfv gcc
                  on case when '''||p_account_type||''' = ''COST''
                          then fcb.asset_cost_account_ccid
                          when '''||p_account_type||''' = ''CLEARING''
                          then fcb.asset_clearing_account_ccid
                          when '''||p_account_type||''' = ''DEPRN_EXPENSE''
                          then fcb.deprn_expense_account_ccid
                          when '''||p_account_type||''' = ''DEPRN_RESERVE''
                          then fcb.reserve_account_ccid
                          when '''||p_account_type||''' = ''BONUS_EXPENSE''
                          then fcb.bonus_expense_account_ccid
                          when '''||p_account_type||''' = ''BONUS_RESERVE''
                          then fcb.bonus_reserve_acct_ccid
                          when '''||p_account_type||''' = ''REVAL_RESERVE''
                          then fcb.reval_reserve_account_ccid 
                          when '''||p_account_type||''' = ''REVAL_AMORT''
                          then fcb.reval_amort_account_ccid 
                          when '''||p_account_type||''' = ''WIP_COST''
                          then fcb.wip_cost_account_ccid
                          when '''||p_account_type||''' = ''WIP_CLEARING''
                          then fcb.wip_clearing_account_ccid
                          when '''||p_account_type||''' = ''IMPAIR_EXPENSE''
                          then fcb.impair_expense_account_ccid
                          when '''||p_account_type||''' = ''IMPAIR_RESERVE''
                          then fcb.impair_reserve_account_ccid
                          when '''||p_account_type||''' = ''UNPLAN_EXPENSE''
                          then fcb.unplan_expense_account_ccid
                          when '''||p_account_type||''' = ''ALT_COST''
                          then fcb.alt_cost_account_ccid
                          when '''||p_account_type||''' = ''WRITE_OFF''
                          then fcb.write_off_account_ccid
                      end = gcc.code_combination_id
        where   fcb.category_id = '||p_category_id||'
        and     fbc.set_of_books_id = '||p_ledger_id;
      elsif p_segment_type != 'GL_ACCOUNT' then
        --  1.2     31/10/2017  Nicolas BOUSSEKEYT
        --          artf2268989 - SPE037 et SPE205 - La transco MIGR_GROUP_ACCOUNT_CLASS_BILAN ne doit effectivement contenir que des comptes de bilan
        -- where   dth.set_name = ''MIGR_GROUP_ACCOUNT_CLASS_BILAN''  
        l_sql := '
        select  dtl.return_value
        from    dka_stransco_headers dth
                join dka_stransco_lines dtl
                  on dth.set_id = dtl.set_id
        where   dth.set_name = ''DKA_TRANSCO_LOCAL_GROUPE''  
        and     dtl.enable = ''Y''
        and     sysdate between nvl(dtl.start_date, sysdate) and nvl(dtl.end_date, sysdate)
        and     dtl.param1_value = '''||lv_account||'''';
      end if;
  -- Fin 1.1      2017/10/05  Nicolas BOUSSEKEYT
  --          artf2237548 : SPE205 - Modifications SLA FA : récupération des comptes d'annulation dans le CUF comptes de c atégorie - defect ORACLE_R12#969              
    end if;

    Trace('SQL statement : '||l_sql, c_level_statement);    
    
    execute immediate l_sql into lv_account;

    Trace('Account is : '||lv_account, c_level_statement);    
      
    --
    -- Reset function login procedure
    --
    Exit_Module;

    return lv_account;
   
  exception
    when NO_DATA_FOUND then
       Trace('No data found !'); 
       RETURN '0';
    when others then
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
  end get_IFRS_account;


/*  
  -- -----------------------------------------------------------------------------------------
  -- get_IFRS_Social_Account
  --
  -- Appel par les customs sources
  --    Assets : DKA_IFRS_SOCIAL_ACCOUNT
  --
  -- Parametres :
  --    p_ledger_id => Identifiant du livre de compte
  --    p_natural_account => Valeur du Natural Account SOCIAL
  -- -----------------------------------------------------------------------------------------
  function  get_IFRS_Social_Account (
             p_ledger_id in number,
             p_natural_account in varchar2 default NULL
            )
    return varchar2
  is
    c_log_module          varchar2(100) := g_log_package||'.get_IFRS_Social_Account';
    
    ln_flex_value_set_id  number;
    lv_ifrs_account       varchar2(50);
  begin
    --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;
    
    --
    -- Get GL_ACCOUNT flex_value_set_id 
    --
    select  fifs.flex_value_set_id
    into    ln_flex_value_set_id
    from    fnd_id_flex_segments fifs
            join gl_ledgers gl
              on fifs.application_id = 101
              and fifs.id_flex_code = 'GL#'
              and fifs.id_flex_num = gl.chart_of_accounts_id
            join fnd_segment_attribute_values fsav
              on fifs.application_id = fsav.application_id
              and fifs.id_flex_code = fsav.id_flex_code
              and fifs.id_flex_num = fsav.id_flex_num
              and fifs.application_column_name = fsav.application_column_name
    where fsav.segment_attribute_type = 'GL_ACCOUNT'
    and   fsav.attribute_value = 'Y'  
    and   gl.ledger_id = p_ledger_id;
    
    Trace('GL_ACCOUNT flex_value_set_id for ledger '||p_ledger_id||' is : '||ln_flex_value_set_id, c_level_statement);
    
    --
    -- Get IFRS Social Account 
    --
    select  ffvd.local_ifrs
    into    lv_ifrs_account
    from    fnd_flex_values ffv
            join fnd_flex_values_dfv ffvd
              on ffv.rowid = ffvd.row_id
    where   ffv.flex_value_set_id = ln_flex_value_set_id     
    and     ffv.flex_value = p_natural_account;
     
    Trace('IFRS_Social_Account for account  '||p_natural_account||' is : '||lv_ifrs_account, c_level_statement);

    --
    -- Reset function login procedure
    --
    Exit_Module;

    return lv_ifrs_account;
   
  exception
    when others then
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
  end get_IFRS_Social_Account;
*/

  -- -----------------------------------------------------------------------------------------
  -- get_Project_Number
  --
  -- Called by Customs Sources
  --    Assets : DKA_FA_PROJECT_NUMBER
  --
  -- Parameters :
  --    p_asset_id => identifiant d'immobiliation
  --
  -- Output :
  --    Project number of the first source line with a non blank project number
  -- -----------------------------------------------------------------------------------------  

  function  get_Project_Number (
             p_asset_id in number
            )
    return varchar2
  is  
    c_log_module          varchar2(100) := g_log_package||'.get_Project_Number';
    
    lv_project_number     varchar2(50);
  begin
    --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;

    --
    -- Display parameters for debug purpose
    --
    Trace('Asset ID : '||p_asset_id, c_level_statement);    
            
    --
    -- Get project number
    --
    begin
      select distinct pp.segment1
      into    lv_project_number
      from    pa_projects_all pp
              join fa_invoice_details_v fid
                on pp.project_id = fid.project_id
      where   fid.asset_invoice_id = (          
                select  min(asset_invoice_id)
                from    fa_invoice_details_v
                where   asset_id = p_asset_id
                and     project_id is not null
              );
    exception
      when no_data_found then
        lv_project_number := null;
    end;
    
    Trace('Project Number : '||lv_project_number, c_level_statement);

    --
    -- Reset function login procedure
    --
    Exit_Module;

    return lv_project_number;
   
  exception
    when others then
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
  end get_Project_Number;  
  
  -- -----------------------------------------------------------------------------------------
  -- get_Task_Number
  --
  -- Called by Customs Sources
  --    Assets : DKA_FA_TASK_NUMBER
  --
  -- Parameters :
  --    p_asset_id => identifiant d'immobiliation
  --
  -- Output :
  --    Task number of the first source line with a non blank task number
  -- -----------------------------------------------------------------------------------------  

  function  get_Task_Number (
             p_asset_id in number
            )
    return varchar2
  is  
    c_log_module          varchar2(100) := g_log_package||'.get_Task_Number';
    
    lv_task_number        varchar2(50);
  begin
    --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;

    --
    -- Display parameters for debug purpose
    --
    Trace('Asset ID : '||p_asset_id, c_level_statement);    
            
    --
    -- Get project number
    --
    begin
      select  distinct pt.task_number
      into    lv_task_number
      from    pa_tasks pt
              join fa_invoice_details_v fid
                on pt.task_id = fid.task_id
      where   fid.asset_invoice_id = (          
                select  min(asset_invoice_id)
                from    fa_invoice_details_v
                where   asset_id = p_asset_id
                and     task_id is not null
              );

    exception
      when no_data_found then
        lv_task_number := null;
    end;
    
    Trace('Project Number : '||lv_task_number, c_level_statement);

    --
    -- Reset function login procedure
    --
    Exit_Module;

    return lv_task_number;
   
  exception
    when others then
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
  end get_Task_Number;  

  --  1.3     11/09/2018  Nicolas BOUSSEKEYT artf2664451 - INC0218966 - Erreur code flux_Cession d'immo 
  FUNCTION is_f44(p_book_type_code IN VARCHAR2, p_category_id IN NUMBER)
    RETURN VARCHAR2 IS
    c_log_module VARCHAR2(100) := g_log_package || '.is_F44';
    lv_yes_no    VARCHAR2(10);
    ln_cpt       NUMBER;
  
  BEGIN
    --
    -- Activate function login procedure
    --
    init_module(p_log_module => c_log_module);
  
    --
    -- Display parameters for debug purpose
    --
    trace('Book Type Code : ' || p_book_type_code, c_level_statement);
  
    SELECT COUNT(1)
      INTO ln_cpt
      FROM fa_book_controls fbc
     WHERE book_type_code = p_book_type_code
       AND book_class = 'CORPORATE';
  
    IF ln_cpt = 1 THEN
      SELECT CASE
               WHEN (segment2 IN ('SUB', 'SUBI12', 'SUBI12PRCI', 'CUI12PR', 'SUBI4')) THEN
                'Y'
               ELSE
                'N'
             END
        INTO lv_yes_no
        FROM fa_categories_vl fc
       WHERE fc.category_id = p_category_id;
    ELSE
      lv_yes_no := 'N';
    END IF;
  
    --
    -- Get column name
    --
  
    trace('Is book type code ' || p_book_type_code || ' a F44 ? : ' ||
          lv_yes_no,
          c_level_statement);
  
    --
    -- Reset function login procedure
    --
    exit_module;
  
    RETURN lv_yes_no;
  
  EXCEPTION
    WHEN OTHERS THEN
      app_exception.raise_exception(exception_text => 'unexpected error in procedure ' ||
                                                      c_log_module || ', ' ||
                                                      SQLERRM);
  END is_f44;

    --  1.3     11/09/2018  Nicolas BOUSSEKEYT artf2664451 - INC0218966 - Erreur code flux_Cession d'immo 
    FUNCTION is_f60(p_book_type_code IN VARCHAR2, p_category_id IN NUMBER)
    RETURN VARCHAR2 IS
    c_log_module VARCHAR2(100) := g_log_package || '.is_F60';
    lv_yes_no    VARCHAR2(10);
    ln_cpt       NUMBER;
  
  BEGIN
    --
    -- Activate function login procedure
    --
    init_module(p_log_module => c_log_module);
  
    --
    -- Display parameters for debug purpose
    --
    trace('Book Type Code : ' || p_book_type_code, c_level_statement);
  
    SELECT COUNT(1)
      INTO ln_cpt
      FROM fa_book_controls fbc
     WHERE book_type_code = p_book_type_code
       AND book_class = 'CORPORATE';
  
    IF ln_cpt = 1 THEN
      SELECT CASE
               WHEN (segment2 IN ('CEE', 'CEEI12', 'DRC', 'DRCI12')) THEN
                'Y'
               ELSE
                'N'
             END
        INTO lv_yes_no
        FROM fa_categories_vl fc
       WHERE fc.category_id = p_category_id;
    ELSE
      lv_yes_no := 'N';
    END IF;
  
    --
    -- Get column name
    --
  
    trace('Is book type code ' || p_book_type_code || ' a F60 ? : ' ||
          lv_yes_no,
          c_level_statement);
  
    --
    -- Reset function login procedure
    --
    exit_module;
  
    RETURN lv_yes_no;
  
  EXCEPTION
    WHEN OTHERS THEN
      app_exception.raise_exception(exception_text => 'unexpected error in procedure ' ||
                                                      c_log_module || ', ' ||
                                                      SQLERRM);
  END is_f60;
  
    -- 1.1     28/03/2019  Nicolas BOUSSEKEYT EDB234
  -- -----------------------------------------------------------------------------------------
  -- is_category_name
  --
  -- Called by Customs Sources
  --    Assets : DKA_FA_IS_CATEGORY_NAME
  --
  -- Parameters :
  --    p_category_id => Id category
  --    p_category_name => Category Name
  --
  -- Output :
  --    Y : The Category/book is Category Name
  --    N : The Category/book is not Category Name
  -- -----------------------------------------------------------------------------------------  

  FUNCTION is_category_name(p_category_id IN NUMBER, p_category_name IN VARCHAR2)
    RETURN VARCHAR2 IS
    c_log_module VARCHAR2(100) := g_log_package || '.is_category_name';
    lv_yes_no    VARCHAR2(10);
    ln_cpt       NUMBER;
  
  BEGIN
    --
    -- Activate function login procedure
    --
    init_module(p_log_module => c_log_module);
  
    SELECT COUNT(1)
        INTO ln_cpt
        FROM fa_categories_vl fc
       WHERE fc.category_id = p_category_id
       AND segment2 = p_category_name;
       
    IF ln_cpt > 0 THEN
      lv_yes_no := 'Y';
    ELSE
      lv_yes_no := 'N';
    END IF;
   
    --
    -- Get column name
    --
  
    trace('Is a category name ('||p_category_name||' ? : ' ||
          lv_yes_no,
          c_level_statement);
  
    --
    -- Reset function login procedure
    --
    exit_module;
  
    RETURN lv_yes_no;
  
  EXCEPTION
    WHEN OTHERS THEN
      app_exception.raise_exception(exception_text => 'unexpected error in procedure ' ||
                                                      c_log_module || ', ' ||
                                                      SQLERRM);
  END is_category_name;

  -- -----------------------------------------------------------------------------------------
  -- get_SOCIAL_account
  --
  -- Called by Customs Sources
  --    Assets : 
  --
  -- Parameters :
  --    p_category_id       =>  Asset category ID
  --    p_ledger_id         =>  Ledger ID
  --    p_segment_type      =>  Type of account
  --                            Possible values :
  --                              GL_ACCOUNT
  --                              XARGOS_ACCOUNT
  --
  -- Output :
  --    Natural Account segment value
  -- -----------------------------------------------------------------------------------------  
  function  get_SOCIAL_account (
             p_category_id      in number,
             p_ledger_id        in number,
             p_segment_type     in varchar2
             )
    return varchar2
  is
    c_log_module          varchar2(100) := g_log_package||'.get_SOCIAL_account';
    
    lv_column_name        varchar2(50);
    lv_account            varchar2(50);
    
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
    Trace('Category ID : '||p_category_id, c_level_statement);    
    Trace('Ledger ID : '||p_ledger_id, c_level_statement);    
    Trace('Segment type : '||p_segment_type, c_level_statement);    
        
    --
    -- Get the corresponding application column name
    --
    lv_column_name := get_Segment_Column_Name (
                         p_ledger_id    => p_ledger_id,
                         p_segment_type => p_segment_type);
                         
    l_sql := 'select  gcc.'||lv_column_name||'
        from    fa_category_books fcb
                join fa_book_controls fbc
                  on fcb.book_type_code = fbc.book_type_code
                  and fbc.book_class = ''CORPORATE''
                join gl_code_combinations_kfv gcc
                on fcb.deprn_expense_account_ccid = gcc.code_combination_id
        where   fcb.category_id = '||p_category_id||'
        and     fbc.set_of_books_id = '||p_ledger_id;
        
    Trace('SQL statement : '||l_sql, c_level_statement);    
    
    execute immediate l_sql into lv_account;

    Trace('Account is : '||lv_account, c_level_statement);    
      
    --
    -- Reset function login procedure
    --
    Exit_Module;

    return lv_account;
   
  exception
    when NO_DATA_FOUND then
       Trace('No data found !'); 
       RETURN '0';
    when others then
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
  end get_SOCIAL_account;
------------------------------------------------------------------------------------------------------------------------------
FUNCTION  GET_FA_PROV_LOCAL (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2
	IS
    c_log_module          VARCHAR2(100) := g_log_package||'.GET_FA_PROV_LOCAL';
	lv_account            VARCHAR2(50); 
    l_sql                 VARCHAR2(4000);
	
	BEGIN
    --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;
      
    --
    -- Display parameters for debug purpose
    --
    Trace('Category ID : '||p_category_id, c_level_statement);
	
	l_sql := 'SELECT distinct attribute4 
	          FROM FA_CATEGORIES_VL
              WHERE category_id = '||p_category_id||'';
			  
	Trace('SQL statement : '||l_sql, c_level_statement);    
      
      EXECUTE IMMEDIATE l_sql INTO lv_account;

      Trace('Account is : '||lv_account, c_level_statement);
	  
	  --
      -- Reset function login procedure
      --
      Exit_Module;
	  
	  RETURN lv_account;
   
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
       Trace('No data found !'); 
       RETURN '0';
      WHEN OTHERS THEN
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||SQLERRM) ;
   
 END GET_FA_PROV_LOCAL;
 ----------------------------------------------------------------------------------------------------------------------
 FUNCTION  GET_FA_PROV_GROUPE (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2
	IS
    c_log_module          VARCHAR2(100) := g_log_package||'.GET_FA_PROV_GROUPE';
	lv_account            VARCHAR2(50); 
    l_sql                 VARCHAR2(4000);
	
	BEGIN
	
	--
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;
      
    --
    -- Display parameters for debug purpose
    --
    Trace('Category ID : '||p_category_id, c_level_statement);
	
	l_sql := 'SELECT return_value
              FROM DKA_STRANSCO_LINES 
              WHERE set_id=(SELECT SET_ID
                            FROM DKA_STRANSCO_HEADERS 
                            WHERE  UPPER(SET_NAME) = ''DKA_TRANSCO_LOCAL_GROUPE'')
              AND param1_value in (SELECT distinct attribute4 
			                       FROM FA_CATEGORIES_VL
                                   WHERE category_id = '||p_category_id||')';
	
	Trace('SQL statement : '||l_sql, c_level_statement);    
      
      EXECUTE IMMEDIATE l_sql INTO lv_account;

      Trace('Account is : '||lv_account, c_level_statement);
	  
	  --
      -- Reset function login procedure
      --
      Exit_Module;
	  
	  RETURN lv_account;
   
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
       Trace('No data found !'); 
       RETURN '0';
      WHEN OTHERS THEN
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||SQLERRM) ;
   
 END GET_FA_PROV_GROUPE;
 ------------------------------------------------------------------------------------------------------------------------------
FUNCTION  GET_FA_PROV_ANNUL_LOCAL (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2
	IS
    c_log_module          VARCHAR2(100) := g_log_package||'.GET_FA_PROV_ANNUL_LOCAL';
	lv_account            VARCHAR2(50); 
    l_sql                 VARCHAR2(4000);
	
	BEGIN
    --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;
      
    --
    -- Display parameters for debug purpose
    --
    Trace('Category ID : '||p_category_id, c_level_statement);
	
	l_sql := 'SELECT distinct attribute5 
	          FROM FA_CATEGORIES_VL
              WHERE category_id = '||p_category_id||'';
			  
	Trace('SQL statement : '||l_sql, c_level_statement);    
      
      EXECUTE IMMEDIATE l_sql INTO lv_account;

      Trace('Account is : '||lv_account, c_level_statement);
	  
	  --
      -- Reset function login procedure
      --
      Exit_Module;
	  
	  RETURN lv_account;
   
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
       Trace('No data found !'); 
       RETURN '0';
      WHEN OTHERS THEN
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||SQLERRM) ;
   
 END GET_FA_PROV_ANNUL_LOCAL;
------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
 FUNCTION  GET_FA_PROV_ANNUL_GROUPE (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2
	IS
    c_log_module          VARCHAR2(100) := g_log_package||'.GET_FA_PROV_ANNUL_GROUPE';
	lv_account            VARCHAR2(50); 
    l_sql                 VARCHAR2(4000);
	
	BEGIN
	
	--
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;
      
    --
    -- Display parameters for debug purpose
    --
    Trace('Category ID : '||p_category_id, c_level_statement);
	
	l_sql := 'SELECT return_value
              FROM DKA_STRANSCO_LINES 
              WHERE set_id=(SELECT SET_ID
                            FROM DKA_STRANSCO_HEADERS 
                            WHERE  UPPER(SET_NAME) = ''DKA_TRANSCO_LOCAL_GROUPE'')
              AND param1_value in (SELECT distinct attribute5 
			                       FROM FA_CATEGORIES_VL
                                   WHERE category_id = '||p_category_id||')';
	
	Trace('SQL statement : '||l_sql, c_level_statement);    
      
      EXECUTE IMMEDIATE l_sql INTO lv_account;

      Trace('Account is : '||lv_account, c_level_statement);
	  
	  --
      -- Reset function login procedure
      --
      Exit_Module;
	  
	  RETURN lv_account;
   
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
       Trace('No data found !'); 
       RETURN '0';
      WHEN OTHERS THEN
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||SQLERRM) ;
   
 END GET_FA_PROV_ANNUL_GROUPE;
--------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
FUNCTION  DKA_FA_RETIRT_SUBIPR_DOT_LOC (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2
	IS
    c_log_module          VARCHAR2(100) := g_log_package||'.DKA_FA_RETIRT_SUBIPR_DOT_LOC';
	lv_account            VARCHAR2(50); 
    l_sql                 VARCHAR2(4000);
	
	BEGIN
    --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;
      
    --
    -- Display parameters for debug purpose
    --
    Trace('Category ID : '||p_category_id, c_level_statement);
	
	l_sql := 'SELECT distinct attribute6 
	          FROM FA_CATEGORIES_VL
              WHERE category_id = '||p_category_id||'';
			  
	Trace('SQL statement : '||l_sql, c_level_statement);    
      
      EXECUTE IMMEDIATE l_sql INTO lv_account;

      Trace('Account is : '||lv_account, c_level_statement);
	  
	  --
      -- Reset function login procedure
      --
      Exit_Module;
	  
	  RETURN lv_account;
   
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
       Trace('No data found !'); 
       RETURN '0';
      WHEN OTHERS THEN
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||SQLERRM) ;
   
 END DKA_FA_RETIRT_SUBIPR_DOT_LOC;

----------------------------------------------------------------------------------------------------------------------
 FUNCTION  DKA_FA_RETIRT_SUBIPR_DOT_GP (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2
	IS
    c_log_module          VARCHAR2(100) := g_log_package||'.DKA_FA_RETIRT_SUBIPR_DOT_GP';
	lv_account            VARCHAR2(50); 
    l_sql                 VARCHAR2(4000);
	
	BEGIN
	
	--
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;
      
    --
    -- Display parameters for debug purpose
    --
    Trace('Category ID : '||p_category_id, c_level_statement);
	
	l_sql := 'SELECT return_value
              FROM DKA_STRANSCO_LINES 
              WHERE set_id=(SELECT SET_ID
                            FROM DKA_STRANSCO_HEADERS 
                            WHERE  UPPER(SET_NAME) = ''DKA_TRANSCO_LOCAL_GROUPE'')
              AND param1_value in (SELECT distinct attribute6 
			                       FROM FA_CATEGORIES_VL
                                   WHERE category_id = '||p_category_id||')';
	
	Trace('SQL statement : '||l_sql, c_level_statement);    
      
      EXECUTE IMMEDIATE l_sql INTO lv_account;

      Trace('Account is : '||lv_account, c_level_statement);
	  
	  --
      -- Reset function login procedure
      --
      Exit_Module;
	  
	  RETURN lv_account;
   
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
       Trace('No data found !'); 
       RETURN '0';
      WHEN OTHERS THEN
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||SQLERRM) ;
   
 END DKA_FA_RETIRT_SUBIPR_DOT_GP;

------------------------------------------------------------------------------------------------------------------------------
FUNCTION  DKA_FA_RETIRT_SUBIPR_DOT_AN_LO (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2
	IS
    c_log_module          VARCHAR2(100) := g_log_package||'.DKA_FA_RETIRT_SUBIPR_DOT_AN_LO';
	lv_account            VARCHAR2(50); 
    l_sql                 VARCHAR2(4000);
	
	BEGIN
    --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;
      
    --
    -- Display parameters for debug purpose
    --
    Trace('Category ID : '||p_category_id, c_level_statement);
	
	l_sql := 'SELECT distinct attribute7 
	          FROM FA_CATEGORIES_VL
              WHERE category_id = '||p_category_id||'';
			  
	Trace('SQL statement : '||l_sql, c_level_statement);    
      
      EXECUTE IMMEDIATE l_sql INTO lv_account;

      Trace('Account is : '||lv_account, c_level_statement);
	  
	  --
      -- Reset function login procedure
      --
      Exit_Module;
	  
	  RETURN lv_account;
   
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
       Trace('No data found !'); 
       RETURN '0';
      WHEN OTHERS THEN
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||SQLERRM) ;
   
 END DKA_FA_RETIRT_SUBIPR_DOT_AN_LO;
----------------------------------------------------------------------------------------------------------------------
 FUNCTION  DKA_FA_RETIRT_SUBIPR_DOT_AN_GP (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2
	IS
    c_log_module          VARCHAR2(100) := g_log_package||'.DKA_FA_RETIRT_SUBIPR_DOT_AN_GP';
	lv_account            VARCHAR2(50); 
    l_sql                 VARCHAR2(4000);
	
	BEGIN
	
	--
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;
      
    --
    -- Display parameters for debug purpose
    --
    Trace('Category ID : '||p_category_id, c_level_statement);
	
	l_sql := 'SELECT return_value
              FROM DKA_STRANSCO_LINES 
              WHERE set_id=(SELECT SET_ID
                            FROM DKA_STRANSCO_HEADERS 
                            WHERE  UPPER(SET_NAME) = ''DKA_TRANSCO_LOCAL_GROUPE'')
              AND param1_value in (SELECT distinct attribute7 
			                       FROM FA_CATEGORIES_VL
                                   WHERE category_id = '||p_category_id||')';
	
	Trace('SQL statement : '||l_sql, c_level_statement);    
      
      EXECUTE IMMEDIATE l_sql INTO lv_account;

      Trace('Account is : '||lv_account, c_level_statement);
	  
	  --
      -- Reset function login procedure
      --
      Exit_Module;
	  
	  RETURN lv_account;
   
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
       Trace('No data found !'); 
       RETURN '0';
      WHEN OTHERS THEN
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||SQLERRM) ;
   
 END DKA_FA_RETIRT_SUBIPR_DOT_AN_GP;
 
FUNCTION  DKA_FA_NBV_RETIRED_LOSS_GP_SEG (
             p_ledger_id        IN NUMBER,
			 p_book_type_code   IN VARCHAR2
            )
    RETURN VARCHAR2
	IS
    c_log_module          VARCHAR2(100) := g_log_package||'.DKA_FA_NBV_RETIRED_LOSS_GP_SEG';
	lv_account            VARCHAR2(50); 
    l_sql                 VARCHAR2(4000);
	
	BEGIN
	
	--
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;
      
    --
    -- Display parameters for debug purpose
    --
    Trace('Ledger ID : '||p_ledger_id, c_level_statement);
	Trace('BOOK_TYPE_CODE : '||p_book_type_code, c_level_statement);
	
	l_sql := 'SELECT return_value
              FROM DKA_STRANSCO_LINES 
              WHERE set_id=(SELECT SET_ID
                            FROM DKA_STRANSCO_HEADERS 
                            WHERE  UPPER(SET_NAME) = ''DKA_TRANSCO_LOCAL_GROUPE'')
              AND param1_value in (SELECT distinct NBV_RETIRED_LOSS_ACCT 
			                       FROM FA_BOOK_CONTROLS fbc
                                   where  fbc.set_of_books_id = '||p_ledger_id ||'
                                   and fbc.book_type_code = '''||p_book_type_code||''')';
	
	Trace('SQL statement : '||l_sql, c_level_statement);    
      
      EXECUTE IMMEDIATE l_sql INTO lv_account;

      Trace('Account is : '||lv_account, c_level_statement);
	  
	  --
      -- Reset function login procedure
      --
      Exit_Module;
	  
	  RETURN lv_account;
   
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
       Trace('No data found !'); 
       RETURN '0';
      WHEN OTHERS THEN
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||SQLERRM) ;
   
 END DKA_FA_NBV_RETIRED_LOSS_GP_SEG;

 FUNCTION  DKA_FA_RECLASS_NIFRS_IFRS (
             p_event_id        IN NUMBER
            )
    RETURN VARCHAR2
  IS
    c_log_module          VARCHAR2(100) := g_log_package||'.DKA_FA_RECLASS_NIFRS_IFRS';
    lv_account            VARCHAR2(50); 
    l_sql                 VARCHAR2(4000);
    lv_transaction_type_code VARCHAR2(100);
    ln_source_social         NUMBER;
    ln_dest_ifrs             NUMBER;
 BEGIN
  
  --
    -- Activate function login procedure
    --
    Init_Module(
      p_log_module  => c_log_module ) ;
      
    --
    -- Display parameters for debug purpose
    --
    Trace('Event ID : '||p_event_id, c_level_statement);
  
  l_sql := 'SELECT v.transaction_type_code,
       (SELECT COUNT(1)
          FROM fa_category_books fcb
         WHERE fcb.category_id = fth2.category_id
           AND NOT EXISTS (select ''x'' from fa_category_books fcb2
                          WHERE fcb2.category_id = fcb.category_id
                          AND substr(fcb2.book_type_code, 6) = ''IFRS'' 
                          AND substr(fcb2.book_type_code, 1, 4) = substr(v.book_type_code, 1, 4))
           AND substr(fcb.book_type_code, 6) = ''SOCIAL''
           AND substr(fcb.book_type_code, 1, 4) =
               substr(v.book_type_code, 1, 4)) source_social,
       (SELECT COUNT(1)
          FROM fa_category_books fcb
         WHERE fcb.category_id = v.category_id
           AND substr(fcb.book_type_code, 6) = ''IFRS''
           AND substr(fcb.book_type_code, 1, 4) =
               substr(v.book_type_code, 1, 4)) dest_ifrs
  FROM (SELECT fth.transaction_header_id,
               fth.asset_id,
               fth.category_id,
               fth.book_type_code,
               fth.transaction_type_code,
               MAX(fth2.transaction_header_id) transac_source
          FROM xla_events                   xe,
               xla_transaction_entities     ent,
               fa_transaction_history_trx_v fth,
               fa_transaction_history_trx_v fth2
         WHERE xe.event_id = '|| p_event_id ||'
           AND xe.entity_id = ent.entity_id
           AND ent.entity_code = ''TRANSACTIONS''
           AND ent.source_id_int_1 = fth.transaction_header_id
           AND fth2.asset_id = fth.asset_id
           AND fth2.book_type_code = fth.book_type_code
           AND fth2.transaction_header_id != fth.transaction_header_id
         GROUP BY fth.transaction_header_id,
                  fth.asset_id,
                  fth.category_id,
                  fth.book_type_code,
                  fth.transaction_type_code) v,
       fa_transaction_history_trx_v fth2
 WHERE v.transac_source = fth2.transaction_header_id';
  
  Trace('SQL statement : '||l_sql, c_level_statement);    
      
      EXECUTE IMMEDIATE l_sql INTO lv_transaction_type_code, ln_source_social, ln_dest_ifrs;

      Trace('Transaction type code is : '||lv_transaction_type_code, c_level_statement);
      Trace('Source social is : '||ln_source_social, c_level_statement);
      Trace('Dest IFRS is : '||ln_dest_ifrs, c_level_statement);
      
    --
      -- Reset function login procedure
      --
      Exit_Module;
    
      /*
        •  Vérifier que l’événement SLA impliqué est de type « CATEGORY_RECLASS » (XLA_EVENTS.EVENT_TYPE_CODE = CATEGORY_RECLASS)
        •  Si  ce n’est pas le cas, alors tu renvoies directement « N »
       */
      IF (lv_transaction_type_code != 'RECLASS') THEN
      
        RETURN 'N';
      --  Si catégorie source = NON IFRS et catégorie destination = IFRS alors tu renvoies « Y » ?
      ELSIF (  ln_source_social > 0 AND ln_dest_ifrs > 0 ) THEN
        RETURN 'Y';
      ELSE
        -- Pour tous les autres  cas (IFRS-IFRS, NON IFRS-NON IFRS, IFRS-NON IFRS) tu renvoies « N »
        RETURN 'N';
      END IF;
   
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
       Trace('No data found !'); 
       RETURN 'N';
      WHEN OTHERS THEN
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||SQLERRM) ;
   
 END DKA_FA_RECLASS_NIFRS_IFRS;
 
  -- -----------------------------------------------------------------------------------------
  -- get_RECLASS_IFRS_account
  --
  -- Called by Customs Sources
  --    Assets : DKA_FA_IFRS_COST_LOC_ACCT
  --             DKA_FA_IFRS_COST_GRP_ACCT
  --             DKA_FA_IFRS_CLEAR_LOC_ACCT
  --             DKA_FA_IFRS_CLEAR_GRP_ACCT
  --
  -- Parameters :
  --    p_event_id       =>  Asset category ID
  --    p_ledger_id         =>  Ledger ID
  --    p_segment_type      =>  Type of account
  --                            Possible values :
  --                              GL_ACCOUNT
  --                              XARGOS_ACCOUNT
  --    p_account_type      =>  Category of account
  --                            Possible values :
  --                              COST : Compte d'immobilisation
  --                              CLEARING : Lettrage des immobilisations
  --                              DEPRN_EXPENSE : Dotation amort.
  --                              DEPRN_RESERVE : Amortissement cumulé
  --                              BONUS_EXPENSE : Charges exceptionnelles
  --                              BONUS_RESERVE : Amortissement cumulé except.
  --                              REVAL_RESERVE : Plus-value de réévaluation
  --                              REVAL_AMORT : Amortissement de réévaluation
  --                              WIP_COST : Compte des productions à soi-même
  --                              WIP_CLEARING : Lettrage des productions à soi-même
  --                              IMPAIR_EXPENSE : Dotation pour dépréciation
  --                              IMPAIR_RESERVE : Dépréciation cumulée
  --                              UNPLAN_EXPENSE : Dotation aux amortissements non planif.
  --                              ALT_COST : Autre compte d'immobilisations
  --                              WRITE_OFF : Charges d'annulation
  --                              PROCEEDS_OF_SALE_GAIN : Plus-value de produit de cession
  --                              PROCEEDS_OF_SALE_LOSS : Moins-value de produit de cession
  --                              PROCEEDS_OF_SALE_CLEARING : Lettrage de produit de cession
  --                              COST_OF_REMOVAL_GAIN : Plus-value de cout de cession
  --                              COST_OF_REMOVAL_LOSS : Moins-value de cout de cession
  --                              COST_OF_REMOVAL_CLEARING : Lettrage de cout de cession 
  --                              NBV_RETIRED_GAIN : Plus-value de VNC
  --                              NBV_RETIRED_LOSS : Moins-value de VNC
  --                              REVAL_RSV_RETIRED_GAIN : Plus-value de réévaluation
  --                              REVAL_RSV_RETIRED_LOSS : Moins-value de réévaluation
  --                              DEFERRED_DEPRN_RESERVE : Provision pour écart d'amortissement
  --                              DEFERRED_DEPRN_EXPENSE : Ecarts de dotation aux amortissements
  --                              DEPRN_ADJUSTMENT : Ajustement des amortissements
  --
  -- Output :
  --    Natural Account segment value
  -- -----------------------------------------------------------------------------------------
  function  get_RECLASS_IFRS_account (
             p_event_id      in number,
             p_ledger_id        in number,
             p_segment_type     in varchar2,
             p_account_type     in varchar2
            )
    return varchar2
  is
    c_log_module          varchar2(100) := g_log_package||'.get_RECLASS_IFRS_account';
    
    lv_column_name        varchar2(50);
    lv_account            varchar2(50);
    ln_category_id        number;
    
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
    Trace('Event ID : '||p_event_id, c_level_statement);    
    Trace('Ledger ID : '||p_ledger_id, c_level_statement);    
    Trace('Segment type : '||p_segment_type, c_level_statement);    
    Trace('Account type : '||p_account_type, c_level_statement);  
    
    l_sql := 'SELECT fth.category_id
              FROM xla_events                   xe,
                   xla_transaction_entities     ent,
                   fa_transaction_history_trx_v fth
             WHERE xe.event_id = '|| p_event_id ||'
               AND xe.entity_id = ent.entity_id
               AND ent.entity_code = ''TRANSACTIONS''
               AND ent.source_id_int_1 = fth.transaction_header_id';
   
    Trace('SQL statement : '||l_sql, c_level_statement);    
      
    EXECUTE IMMEDIATE l_sql INTO ln_category_id;
    
    lv_account := get_IFRS_account (
             ln_category_id,
             p_ledger_id,
             p_segment_type,
             p_account_type
            );
        
 
    Trace('Account is : '||lv_account, c_level_statement);    
      
    --
    -- Reset function login procedure
    --
    Exit_Module;

    return lv_account;
   
  exception
    when NO_DATA_FOUND then
       Trace('No data found !'); 
       RETURN '0';
    when others then
      app_exception.raise_exception( exception_text => 'unexpected error in procedure '||c_log_module||', '||sqlerrm) ;
  end get_RECLASS_IFRS_account;

end DKA_XLA_FA_CUSTOM_SOURCES_PKG;
/
SHOW ERRORS PACKAGE BODY DKA_XLA_FA_CUSTOM_SOURCES_PKG;
EXIT
