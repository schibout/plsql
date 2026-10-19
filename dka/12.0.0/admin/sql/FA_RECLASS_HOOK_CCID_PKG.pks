create or replace package FA_RECLASS_HOOK_CCID_PKG as
  ----------------------------------------------------------------------------------------------
  -- NOM               : FA_RECLASS_HOOK_CCID_PKG.pks
  -- DESCRIPTION       : FA_RECLASS_HOOK_CCID_PKG package spec : Pour lancer generator compte FA
  --                     Au niveau de l ecran des immobilisations
  ---
  --- AUTEUR           : RBELAYAC
  --- DATE DE CREATION : 22/05/2018
  --- DOC. ASSOCIEE    :
  ---
  ----------------------------------------------------------------------------------------------
  --- NOM DU PROGRAMME :
  --- PARAMETRES       :
  ---
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --  22/05/2018 RBE artf2413227: INC0193633 - FA erreur lors du changement de catégorie 
  ----------------------------------------------------------------------------------------------
  
  
/* $Header: FARCLCIDS.pls 120.0.12020000.2 2013/02/28 13:49:46 rmandali noship $ */

  -- Purpose :

  -- Public type declarations

  -- Public constant declarations

  -- Public variable declarations

  -- Public function and procedure declarations

  FUNCTION GET_NEW_CCID(p_trans_rec          IN      FA_API_TYPES.trans_rec_type
                       ,p_asset_hdr_rec      IN      FA_API_TYPES.asset_hdr_rec_type
                       ,p_asset_cat_rec_new  IN      FA_API_TYPES.asset_cat_rec_type
                       ,p_dist_rec_old       IN      FA_API_TYPES.asset_dist_rec_type
                       ,p_dist_rec_new       IN      FA_API_TYPES.asset_dist_rec_type
                       ,p_expense_ccid       OUT     NOCOPY NUMBER
                       ,p_log_level_rec      IN      FA_API_TYPES.log_level_rec_type default null) return boolean;

end FA_RECLASS_HOOK_CCID_PKG;
/
SHOW ERRORS
EXIT;