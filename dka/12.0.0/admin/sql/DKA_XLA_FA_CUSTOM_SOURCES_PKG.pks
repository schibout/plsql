create or replace package DKA_XLA_FA_CUSTOM_SOURCES_PKG as
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
  -- 1.1     11/09/2018  Nicolas BOUSSEKEYT artf2664451 - INC0218966 - Erreur code flux_Cession d'immo 
   -- -----------------------------------------------------------------------------------------

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
    return varchar2;  
    
  -- -----------------------------------------------------------------------------------------
  -- is_IFRS_Category
  --
  -- Called by Customs Sources
  --    Assets : DKA_FA_IS_IFRS_CATEGORY
  --
  -- Parameters :
  --    p_category_id => Asset category ID
  --
  -- Output :
  --    Y : A tax book is associated to the category
  --    N : No tax book is associated to the category
  -- -----------------------------------------------------------------------------------------  

  function  is_IFRS_Category (
             p_category_id in number
            )
    return varchar2;    
    
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
    return varchar2;    
  -------------------------------------------------------------------------------------
  FUNCTION  GET_FA_PROV_LOCAL (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2;
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
    return varchar2;
    
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
    return varchar2;    
    
  -- 1.1     11/09/2018  Nicolas BOUSSEKEYT artf2664451 - INC0218966 - Erreur code flux_Cession d'immo 
  -- -----------------------------------------------------------------------------------------
  -- is_F44
  --
  -- Called by Customs Sources
  --    Assets : DKA_IS_FA_TAX_BOOK
  --
  -- Parameters :
  --    p_book_type_code => Asset book type code
  --    p_category_id => Id category
  --    
  --
  -- Output :
  --    Y : The Category/book is F44 .
  --    N : The Category/book is not F44 .
  -- -----------------------------------------------------------------------------------------  

  FUNCTION is_f44(p_book_type_code IN VARCHAR2, p_category_id IN NUMBER)
    RETURN VARCHAR2;

  -- 1.1     11/09/2018  Nicolas BOUSSEKEYT artf2664451 - INC0218966 - Erreur code flux_Cession d'immo 
  -- -----------------------------------------------------------------------------------------
  -- is_F60
  --
  -- Called by Customs Sources
  --    Assets : DKA_IS_FA_TAX_BOOK
  --
  -- Parameters :
  --    p_book_type_code => Asset book type code
  --    p_category_id => Id category
  --    
  --
  -- Output :
  --    Y : The Category/book is F60 .
  --    N : The Category/book is not F60 .
  -- -----------------------------------------------------------------------------------------  

  FUNCTION is_f60(p_book_type_code IN VARCHAR2, p_category_id IN NUMBER)
    RETURN VARCHAR2;
    
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
    RETURN VARCHAR2;

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
    return varchar2;
------------------------------------------------------------------------------------------------
 FUNCTION  GET_FA_PROV_GROUPE (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2;
------------------------------------------------------------------------------------------------
FUNCTION  GET_FA_PROV_ANNUL_LOCAL (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2;
------------------------------------------------------------------------------------------------
 FUNCTION  GET_FA_PROV_ANNUL_GROUPE (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2;
------------------------------------------------------------------------------------------------
FUNCTION  DKA_FA_RETIRT_SUBIPR_DOT_LOC (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2;
----------------------------------------------------------------------------------------------------------------------
 FUNCTION  DKA_FA_RETIRT_SUBIPR_DOT_GP (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2;
------------------------------------------------------------------------------------------------------------------------------
FUNCTION  DKA_FA_RETIRT_SUBIPR_DOT_AN_LO (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2;
----------------------------------------------------------------------------------------------------------------------
 FUNCTION  DKA_FA_RETIRT_SUBIPR_DOT_AN_GP (
             p_category_id      IN NUMBER
            )
    RETURN VARCHAR2;
----------------------------------------------------------------------------------------------------------------------
FUNCTION  DKA_FA_NBV_RETIRED_LOSS_GP_SEG (
             p_ledger_id        IN NUMBER,
			 p_book_type_code   IN VARCHAR2
            )
    RETURN VARCHAR2;
----------------------------------------------------------------------------------------------------------------------    
FUNCTION  DKA_FA_RECLASS_NIFRS_IFRS (
           p_event_id        IN NUMBER
          )
  RETURN VARCHAR2;
----------------------------------------------------------------------------------------------------------------------
function  get_RECLASS_IFRS_account (
           p_event_id      in number,
           p_ledger_id        in number,
           p_segment_type     in varchar2,
           p_account_type     in varchar2
          )
  return varchar2;
  
end DKA_XLA_FA_CUSTOM_SOURCES_PKG;
/
SHOW ERRORS PACKAGE DKA_XLA_FA_CUSTOM_SOURCES_PKG;
EXIT
