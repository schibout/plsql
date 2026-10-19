create or replace package DKA_XLA_AR_CUSTOM_SOURCES_PKG as
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
  -- -----------------------------------------------------------------------------------------
   
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
    return varchar2;  
    
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

  function  get_hz_cust_acct_sites_att8 (
             p_cust_acct_site_id  in number,
             p_cust_acct_id in number,
             p_org_id in number
            )
    return varchar2;
    
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

  function  get_profile_class (
             p_cust_acct_id  in number
            )
    return varchar2;
    
  -- -----------------------------------------------------------------------------------------
  -- get_tax_code
  --
  -- Called by Customs Sources
--    Receivables : DKA_AR_TRX_TAX_TAXCODE,
  --                DKA_AR_TRX_LINE_TAXCODE,
  --                DKA_AR_CM_TAX_TAXCODE
  -- Parameters :
  --    P_CUSTOMER_TRX_LINE_ID
  --    P_WHERE (LINE, ETAX
  --
  -- Output :
  --    Tax Code
  -- -----------------------------------------------------------------------------------------

  function  get_tax_code (
             P_CUSTOMER_TRX_LINE_ID  in number,
             P_WHERE in varchar2
            )
    return varchar2;  
  
end DKA_XLA_AR_CUSTOM_SOURCES_PKG;
/
SHOW ERRORS PACKAGE DKA_XLA_AR_CUSTOM_SOURCES_PKG;
EXIT
