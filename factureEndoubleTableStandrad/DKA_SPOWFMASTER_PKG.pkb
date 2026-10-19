create or replace package DKA_SFA_FUSION_SOCIETE_PKG AS
  ---------------------------------------------------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_FUSION_FA_PKG.pks
  -- DESCRIPTION       : DKA_FUSION_FA_PKG package :
  ---
  --- AUTEUR           : N. BOUSSEKEYT
  --- DATE DE CREATION : 06/08/2019
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
  -----------------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description

  -- Private type declarations
  g_transco           VARCHAR2(100) := 'FUSION_SOCIETE_VERS_SOCIETE';
  
  CURSOR Cur_Soc_fusion IS
    SELECT DISTINCT --Dsl.Return_Value Soc_To,
           substr(Dsl.Return_Value, 4) Cod_Soc_To,
           --Dsl.Param1_VaLue Soc_From,
           substr(Dsl.Param1_VaLue, 4) Cod_Soc_From,
           TRUNC(Dsl.Start_Date, 'MONTH') - 1 Date_Fusion
      FROM dka_stransco_lines Dsl, dka_stransco_headers Dsh
     WHERE Dsh.Set_Name = g_transco
       and Dsl.Set_Id = Dsh.Set_Id
       AND NVL(Dsl.Enable, 'N') = 'Y';
       
  FUNCTION xxfa_accytddeprn_get_fnc(p_asset_id NUMBER, p_book VARCHAR2, p_type VARCHAR2)
    RETURN NUMBER;
    /*********************************************************************************
    * FUNCTION *  XXFA_ACCDEPRN_GET_FNC
    * DESCRIPTION *  The following function is required to derive the Consolidated and Monthly
    *  Unplanned depreciation details for Fixed Assets.
    * PARAMETERS * ==========
    * NAME                TYPE     DESCRIPTION
    * —————–      ———- ———————————————
    * p_asset_id            IN      Asset ID
    * p_btc                 IN        Book Type Code
    *********************************************************************************/

  ---------------------------------------------------------------------
  --  Nom           : main_Ctr
  --  Description   : Procédure principale du controle des immo avant fusion
  --PARAMETRES :
  --  pv_errbuf   Entrée/Sortie          message d'erreur
  --  VALEUR RETOURNEE :  pn_retcode
  --Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ---------------------------------------------------------------------
  PROCEDURE main_Ctr(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER);
  
    ------------------------------------------------------------------------------------
  -- Nom              : Main_export
  -- Description      : Procédure principale du traitement
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
  PROCEDURE main_export(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER);
  
  ------------------------------------------------------------------------------------
  -- Nom              : Main_import
  -- Description      : Procédure principale du traitement
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
  PROCEDURE main_import(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER, P_MODE_SIMULATION IN VARCHAR2);
  
  ------------------------------------------------------------------------------------
  -- Nom              : main_control_insert
  -- Description      : Procédure principale d'insertion des immos
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
  PROCEDURE main_control_insert(p_errbuf  OUT VARCHAR2,
                                p_retcode OUT NUMBER);
                                
  ------------------------------------------------------------------------------------
  -- Nom              : Main_import_fa
  -- Description      : Procédure principale d'insertion des immos
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
  PROCEDURE main_import_fa(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER);

end DKA_SFA_FUSION_SOCIETE_PKG;
/
SHOW ERRORS;
EXIT
