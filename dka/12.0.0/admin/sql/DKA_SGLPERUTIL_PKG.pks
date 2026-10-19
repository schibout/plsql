/* Formatted on 02/07/2002 20:00 (Formatter Plus v4.5.2) */
CREATE OR REPLACE PACKAGE dka_sglperutil_pkg
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SGLPERUTIL_PKG.pks
-- DESCRIPTION       : DKA_SGLPERUTIL_PKG package spec :
---
--- AUTEUR           : Xavier DESCAMPS (CGEY)
--- DATE DE CREATION : 05/03/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 07/02/2006 GV  - Ajout requete sélection du code TVA
---                - Création de la fonction update_gl_tax_ccid qui met a jour la ccid de la
---                  ligne de TVA GL en fonction de la ccid de la ligne de charge associée 
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

------------------------------------------------------------------------------------------------------------------------
    cg_rg_period_name_qf                    CONSTANT VARCHAR2 (5000)
                --:= 'select period_name from gl_period_statuses_name_v where application_id = 101 and set_of_books_id = :world.set_of_books_id order by period_year desc, period_num desc';  --RBE MigR12
                  := 'select p.period_name FROM gl_periods p WHERE p.period_set_name = :PARAMETER.period_set_name and p.period_type = :PARAMETER.accounted_period_type order by p.period_year desc, p.period_num desc';  --RBE MigR12

------------------------------------------------------------------------------------------------------------------------
    cg_rg_header_period_actual             CONSTANT VARCHAR2 (5000)
                --:= 'select period_name, start_date, end_date, period_num, period_year from gl_period_statuses_actual_v where set_of_books_id = :world.set_of_books_id order by period_year desc, period_num desc';--RBE MigR12
                  := 'select period_name, start_date, end_date, period_num, period_year from gl_period_statuses_actual_v where ledger_id = :header.ledger_id order by period_year desc, period_num desc';     --RBE MigR12

------------------------------------------------------------------------------------------------------------------------
   -- Modif GV20060207
   /* --MigR12
   cg_rg_show_tax_code                     CONSTANT VARCHAR2 (5000)
                := 'SELECT tax_type, tax_code, tax_rate, tax_code_id, tax_type_code ' ||
                   ' FROM gl_tax_codes_v tc ' ||
                   ' WHERE org_id = :header.org_id ' ||
                   ' AND trunc(to_date(:header.default_effective_date)) between nvl(trunc(start_date), trunc(to_date(:header.default_effective_date))) and nvl(trunc(end_date), trunc(to_date(:header.default_effective_date))) ' ||
                   --' AND set_of_books_id = :world.set_of_books_id and valid_flag = ''Y'' ' || --RBE MigR12
                   ' AND ledger_id = :header.ledger_id and valid_flag = ''Y'' '|| --RBE MigR12
                   ' AND tax_type_code = decode (SUBSTR(:lines.account_num,1,1), 6,''I'',7,''O'') ' ||
                   ' AND tax_code like decode (SUBSTR(:lines.account_num, 1, 1), 6, substr(:lines.accounting_flexfield, 1, 4) || ''_'' || substr(:lines.accounting_flexfield, 6, 3) || ''%'', 7, ''%'') ' ||                  
                   ' AND ((tc.tax_code in ' ||
                   '      (select acc.tax_code ' ||
                   '       from gl_tax_option_accounts acc ' ||
                   --'       where acc.set_of_books_id = :world.set_of_books_id ' || --RBE MigR12
                   '       where acc.ledger_id = :header.ledger_id ' || --RBE MigR12
                   '         and acc.org_id = :header.org_id ' ||
                   '         and acc.account_segment_value = :lines.account_num ' ||
                   '         and acc.tax_type_code = tc.tax_type_code ' ||
                   '         and acc.allow_tax_code_override_flag = ''N'')) ' ||
                   '      or not exists ' ||
                   '      (select acc.tax_code ' ||
                   '       from gl_tax_option_accounts acc ' ||
                   --'       where acc.set_of_books_id = :world.set_of_books_id ' || --RBE MigR12
                   '       where acc.ledger_id = :header.ledger_id ' ||  --RBE MigR12
                   '         and acc.org_id = :header.org_id ' ||
                   '         and acc.account_segment_value = :lines.account_num ' ||
                   '         and acc.tax_type_code = tc.tax_type_code ' ||
                   '         and acc.allow_tax_code_override_flag = ''N'') ' ||
                   '    ) ' ||
                   ' ORDER BY tc.tax_type, ' ||
                   ' tc.tax_code ';
                   */
  cg_rg_show_tax_code     CONSTANT VARCHAR2 (5000)
                := ' SELECT lk.meaning TAX_TYPE, ' ||
                   '   rates.tax_regime_code TAX_REGIME_CODE,  ' ||
                   '   rates.tax TAX,  ' ||
                   '   rates.tax_status_code TAX_STATUS_CODE,  ' ||
                   '   rates.tax_rate_code TAX_RATE_CODE,  ' ||
                   '   rates.tax_jurisdiction_code TAX_JURISDICTION_CODE, ' ||
                   '   rates.tax_rate_id TAX_CODE_ID,  ' ||
                   '   decode(rates.percentage_rate, NULL, rates.quantity_rate,  ' ||
                   '          rates.percentage_rate) TAX_RATE,  ' ||
                   '   lk.lookup_code TAX_TYPE_CODE  ' ||
                   '  FROM ZX_SCO_RATES rates, GL_LOOKUPS lk  ' ||
                   '  WHERE LK.LOOKUP_CODE = DECODE(RATES.TAX_CLASS, NULL, ''T'' , ''INPUT'', ''I'', ''O'' )  ' ||
                     --RBE MigR12
                   '  AND LK.LOOKUP_CODE = DECODE (SUBSTR(:LINES.ACCOUNT_NUM,1,1), 6,''I'',7,''O'') ' ||
                   '  AND rates.tax_rate_code like decode (SUBSTR(:lines.account_num, 1, 1), 6, substr(:lines.accounting_flexfield, 1, 4) || ''_'' || substr(:lines.accounting_flexfield, 6, 3) || ''%'', 7, ''%'')   ' ||              
                   '  AND lk.lookup_type = ''TAX_TYPE''  ' ||
                   '  AND rates.active_flag = ''Y''  ' ||
                   '  AND rates.rate_type_code <> ''RECOVERY''  ' ||
                   '  AND  ' ||
                   '  (EXISTS  ' ||
                   '   (SELECT 1 FROM zx_account_rates acr  ' ||
                   '    WHERE acr.ledger_id = :HEADER.LEDGER_ID  ' ||
                   '    AND acr.account_segment_value = :LINES.ACCOUNT_NUM  ' ||
                   '    AND nvl(acr.tax_class,-99) = nvl(rates.tax_class,-99)  ' ||
                   '    AND acr.allow_rate_override_flag = ''N''  ' ||
                   '    AND acr.tax_rate_code = rates.tax_rate_code)  ' ||
                   '    OR  ' ||
                   '   NOT EXISTS  ' ||
                   '   (SELECT 1 FROM zx_account_rates acr  ' ||
                   '    WHERE acr.ledger_id = :HEADER.LEDGER_ID  ' ||
                   '    AND acr.account_segment_value = :LINES.ACCOUNT_NUM  ' ||
                   '    AND nvl(acr.tax_class,-99) = nvl(rates.tax_class,-99)  ' ||
                   '    AND acr.allow_rate_override_flag = ''N''))  ' ||
                   '    AND trunc(to_date(:HEADER.DEFAULT_EFFECTIVE_DATE,''DD-MON-RRRR''))  ' ||
                   '   BETWEEN trunc(rates.effective_from) AND nvl(trunc(rates.effective_to),  ' ||
                   '   trunc(to_date(:HEADER.DEFAULT_EFFECTIVE_DATE, ''DD-MON-RRRR'')))  ' ||
                   '    AND ((rates.tax_class IS NOT NULL AND rates.tax_status_code <>  ''STD_AR_INPUT'')  ' ||
                   '   OR rates.tax_class IS NULL)  ' ||
                   '   ORDER BY  lk.lookup_code, rates.tax_regime_code, rates.tax,  ' ||
                   '             RATES.TAX_STATUS_CODE,  ' ||
                   '             RATES.TAX_RATE_CODE '
                   ;


   -- Fin Modif GV20060207                                                                                              

    FUNCTION get_select_record_group (
        pv_record_group     IN   VARCHAR2
    )
        RETURN VARCHAR2;
        
    
    -- Modif GV20060207 : ajout fonction update_gl_tax_ccid
    
    FUNCTION update_gl_tax_ccid (
        pn_je_header_id     IN   NUMBER
    )
        RETURN BOOLEAN;      


END dka_sglperutil_pkg;
/
SHOW ERROR
EXIT;
