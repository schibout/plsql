create or replace package DKA_XLA_AP_CUSTOM_SOURCES_PKG as
  -- -----------------------------------------------------------------------------------------
  -- Program     : DKA_XLA_AP_CUSTOM_SOURCES_PKG
  -- $Header     : DKA_XLA_AP_CUSTOM_SOURCES_PKG.pks 1.0 2016/10/14 00:00:00 jlaunay $
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
    return varchar2;
    
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
--             p_ledger_id        in number
            )
    return varchar2;

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
    return varchar2;    

end DKA_XLA_AP_CUSTOM_SOURCES_PKG;
/
SHOW ERRORS PACKAGE DKA_XLA_FA_CUSTOM_SOURCES_PKG;
EXIT
