CREATE OR REPLACE PACKAGE BODY DKA_AP_TOOLS_PKG AS
----------------------------------------------------------------------------------------------
-- $Id$
--
-- NOM               : DKA_AP_TOOLS_PKG.pkb
-- DESCRIPTION       : DKA_AP_TOOLS_PKG package body : fonctions communes
---
--- AUTEUR           : J.JARDEZ
--- DATE DE CREATION : 16/03/2016
--- DOC. ASSOCIEE    :
---
----------------------------------------------------------------------------------------------
--- NOM DU PROGRAMME :
--- PARAMETRES       :
---
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  16/03/2016 JJA Portage Helios 2016
--  19/05/2016 RBE Ajout de la fonction get_Attribute12DSP_Facture
--  10/01/2016 MEG Modification dans le cadre de l'artf2077959 
--  04/04.2018 NBO artf2473843 - COM001 - Fonction d'application de la TVA AUTOLIQUIDE
--  03/05/2018 RBE EDB 106 : Ajout fonction get_is_vendor_analyse
--  11/10/2018 MEN artf3038490 : Correctif "Gestion des acomptes" - SPE188 et COM001
--  29/06/2022 ARA EDB337
--  14/06/2023 ARA EDB358 : Pays du fournisseur doit être présent dans le jeu de valeur DKA_TVA_AUTOLIQUIDEE
--------------------------------------------------------------------------------------------
-----------------------------------------------------------------
--  Variables globales
-----------------------------------------------------------------
    gv_debug_mode        VARCHAR2 (1);
    gv_step              VARCHAR2 (500);
----------------------------------------------------------------------------
--  Nom           : get_Attribute12DSP_Facture
--  Description   : Fonction pour affichée le libelle (pour le moment user_name)
--                  correspondant a l'ID du CUF attribute12 de la facture  (pour le moment user_id )
--                  mais comme le jeu de valeurs peut etre modifie a tout moemnt...
-- PARAMETRES     :
--  pv_attribute12    la valeur présente dans le CUF
--
-- VALEUR RETOURNEE :
--  vv_attribute12dsp    le libellé correspondant (utilisé pour le workflow, dans le forms de passerelle de factures)
----------------------------------------------------------------------------
FUNCTION get_Attribute12DSP_Facture (pv_attribute12  ap_invoices_all.attribute12%TYPE) 
  RETURN VARCHAR2 
IS

 vv_attribute12dsp     varchar2(4000);
 vv_select             varchar2(4000);
 vv_where_lg           long;
 vv_where              varchar2(4000);
 vv_flex_value_set_id  fnd_descr_flex_column_usages.flex_value_set_id%TYPE;

BEGIN


  	--SELECTION DU JEU DE VALEUR
    select
     fdfcu.flex_value_set_id
    into
     vv_flex_value_set_id
    from
     fnd_descr_flex_column_usages fdfcu
    where
     fdfcu.application_id = 200
		 AND fdfcu.descriptive_flexfield_name = 'AP_INVOICES_INTERFACE'
		 AND fdfcu.descriptive_flex_context_code =  'XGS'
		 AND fdfcu.application_column_name = 'ATTRIBUTE12'
		 AND fdfcu.end_user_column_name = 'MATRICULE_CSP';

	    SELECT
			 'SELECT '||
			 nvl(upper(ffvt.value_column_name ),'NULL')   ||
			 ' FROM '||ffvt.application_table_name ||' ',
			 ffvt.additional_where_clause , ' AND ' || id_column_name || ' = ' ||pv_attribute12
			 into vv_select, vv_where_lg , vv_where
			FROM
			 fnd_flex_validation_tables   ffvt
			WHERE
			 ffvt.flex_value_set_id = vv_flex_value_set_id;

	    execute immediate vv_select || vv_where_lg || vv_where
	    INTO   vv_attribute12dsp;

      return vv_attribute12dsp;
      
EXCEPTION
	when others then
    return null;
END get_Attribute12DSP_Facture;

-----------------------------------------------------------------
--  Nom           : APPLY_TVA_AUTOLIQUIDEE
--  Description   : Procedure utilisée pour ajouter les lignes de TVA AUTOLIQUIDEE
--
--  PARAMETRES :
--     pv_source     Entrée      Source
--     pv_folio      Entrée      Code folio
--     pv_group_id   Entrée      Group ID
--     pn_org_id     Entrée      Org ID
--
--  VALEUR RETOURNEE :
--     pv_errbuf       :  Message de sortie
--     pn_retcode      :  '0'=OK, '2'=Erreur
-----------------------------------------------------------------
    PROCEDURE apply_tva_autoliquidee (pv_errbuf       OUT      VARCHAR2,
                                      pn_retcode      OUT      NUMBER,
                                      pv_source    IN          VARCHAR2,
                                      pv_folio     IN          VARCHAR2,
                                      pv_group_id  IN          VARCHAR2,
                                      pn_org_id    IN          NUMBER) IS

      lv_current_program_unit  VARCHAR2(30) := 'apply_tva_autoliquidee';

      cv_autoli     CONSTANT VARCHAR2(30) := 'AUTOLIQ';
      cv_offauto    CONSTANT VARCHAR2(30) := 'OFFAUTOLQ';
      cv_separateur CONSTANT VARCHAR2(1)  := '_';

      CURSOR c_facture_eligible( cv_source   VARCHAR2,
                                 cv_folio    VARCHAR2,
                                 cv_group_id VARCHAR2) IS
        SELECT
         aii.invoice_id,
         aii.invoice_num,
         aii.invoice_date,
         aii.invoice_amount,
         aii.accts_pay_code_combination_id,
         aii.org_id,
		 aii.attribute10 --EDB337 ARA
        FROM ap_invoices_interface aii
        WHERE
         --RG1
         AII.SOURCE = cv_source
         AND aii.attribute9 = cv_folio
         AND aii.group_id = cv_group_id
         AND nvl(AII.STATUS,'REJECTED') = 'REJECTED'
         AND aii.accts_pay_code_combination_id IS NOT NULL
         AND aii.org_id = pn_org_id
         AND NOT EXISTS (SELECT NULL
                         FROM ap_invoice_lines_interface aili
                         WHERE aili.invoice_id            = aii.invoice_id
                           AND aili.line_type_lookup_code = 'TAX'
                           AND aili.tax_code              LIKE '%'||cv_autoli||'%')
         --TRANSCO
         AND EXISTS  (SELECT NULL
                      FROM
                       dka_stransco_headers dsh,
                       dka_stransco_lines dsl
                      WHERE dsh.set_name = 'TVA_AUTO_LIQUIDEE'
                      AND dsh.set_id = dsl.set_id
                      AND dsl.param1_value = cv_source
                      AND dsl.param2_value = cv_folio
                      AND nvl(dsh.inactive_date,SYSDATE) >= SYSDATE
                      AND dsl.enable = 'Y'
                      AND SYSDATE BETWEEN nvl(dsl.start_date,SYSDATE) AND nvl(dsl.end_date,SYSDATE))
         --RG2 -- Existe une ligne de taxe exonérée
         AND EXISTS  (SELECT NULL
                      FROM ap_invoice_lines_interface aili,
                       zx_rates_vl zr
                      WHERE aili.invoice_id          = aii.invoice_id
                      AND aili.line_type_lookup_code = 'TAX'
                      AND aili.tax_code              = zr.tax_rate_code
                      AND zr.percentage_rate         = 0)
         --RG3 -- Sommes des lignes de factures = Montant facture
         AND aii.invoice_amount = ( SELECT SUM(aili.amount)
                                    FROM ap_invoice_lines_interface aili
                                    WHERE aili.invoice_id            = aii.invoice_id
                                      AND aili.line_type_lookup_code = 'ITEM')
         --RG4 et RG5 --Fournisseur ayant TVA intracom et Site en France
         AND EXISTS (SELECT NULL
                     FROM
                      po_vendors pv,
                      po_vendor_sites_all pvsa
                     WHERE
                      pv.vendor_id              = pvsa.vendor_id
                      AND pv.vendor_id          = nvl(aii.vendor_id,pv.vendor_id)
                      AND pv.segment1           = nvl(aii.vendor_num,pv.segment1)
                      AND pvsa.vendor_site_id   = nvl(aii.vendor_site_id,pvsa.vendor_site_id)
                      AND pvsa.vendor_site_code = nvl(aii.vendor_site_code,pvsa.vendor_site_code)
                      AND pvsa.org_id           = aii.org_id
                      --AND pvsa.country          = 'FR' --ARA EDB358
					  AND pvsa.country  IN (
											SELECT ffv.flex_value
												 from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
												where ffvs.flex_value_set_id = ffv.flex_value_set_id
												and ffvs.flex_value_set_name = 'DKA_TVA_AUTOLIQUIDEE'
												  AND ffvs.flex_value_set_id = ffv.flex_value_set_id
												  AND ffv.enabled_flag = 'Y') --ARA EDB358
                      AND pv.vat_registration_num IS NOT NULL)
      ;

      lv_societe         gl_code_combinations_kfv.segment1%TYPE;
      lv_region          gl_code_combinations_kfv.segment2%TYPE;

      ln_autoli_tax_id   zx_rates_vl.tax_rate_id%TYPE;
      lv_autoli_name     zx_rates_vl.tax_rate_code%TYPE;
      ln_autoli_rate     zx_rates_vl.percentage_rate%TYPE;
      lv_autoli_descrip  zx_rates_vl.description%TYPE;
      lv_offset_tax_rate_code zx_rates_vl.offset_tax_rate_code%TYPE;
      lv_autoli_tax_regime_code   zx_rates_vl.tax_regime_code%TYPE;
      lv_autoli_tax               zx_rates_vl.tax%TYPE;
      lv_autoli_tax_status_code   zx_rates_vl.tax_status_code%TYPE;
      lv_autoli_tax_juridict_code zx_rates_vl.tax_jurisdiction_code%TYPE;
           
      
      
      ln_offauto_tax_id  zx_rates_vl.tax_rate_id%TYPE;
      lv_offauto_name    zx_rates_vl.tax_rate_code%TYPE;
      ln_offauto_rate    zx_rates_vl.percentage_rate%TYPE;
      lv_offauto_descrip zx_rates_vl.description%TYPE;
      lv_offauto_tax_regime_code   zx_rates_vl.tax_regime_code%TYPE;
      lv_offauto_tax               zx_rates_vl.tax%TYPE;
      lv_offauto_tax_status_code   zx_rates_vl.tax_status_code%TYPE;
      lv_offauto_tax_juridict_code zx_rates_vl.tax_jurisdiction_code%TYPE;
           
      ln_facture_traitee PLS_INTEGER := 0;
      ln_facture_erreur  PLS_INTEGER := 0;

      e_taux_diff        EXCEPTION;
	  
	  -- EDB337 ARA
	  vn_mht_devise         NUMBER;
	  vn_mttc_devise    	NUMBER;

    BEGIN

      gv_step  := lv_current_program_unit||' 000 : DEBUT';
      --Dka_Tools_Pkg.put_log_message (gv_step);

      pv_errbuf  := '';
      pn_retcode := 0;

      gv_step  := lv_current_program_unit||' 001 : Recherche des factures éligibles';
      --Dka_Tools_Pkg.put_log_message (gv_step);
	  
	  

      FOR l_facture in c_facture_eligible(pv_source,pv_folio,pv_group_id) LOOP
	  
		--EDB337 ARA
		  
		  SELECT MHT_DEVISE , MTTC_DEVISE 
		  INTO vn_mht_devise , vn_mttc_devise
		  from dka_iapfacxgs_reporting_all dira , AP_INVOICES_INTERFACE aii
		  where dira.reference_lad = l_facture.attribute10 
		  and aii.invoice_id = l_facture.invoice_id;
		  
		IF NVL(vn_mht_devise, -1) = NVL(vn_mttc_devise , -1) THEN
		  
        BEGIN
		  
          gv_step  := lv_current_program_unit||' 002 : SAVEPOINT';
          --Dka_Tools_Pkg.put_log_message (gv_step);
          SAVEPOINT new_facture;

          --Détermination SOCIETE REGION
          gv_step  := lv_current_program_unit||' 003 : Détermination SOCIETE REGION';
          --Dka_Tools_Pkg.put_log_message (gv_step);
          SELECT
           segment1,   segment2
          INTO
           lv_societe, lv_region
          FROM
           gl_code_combinations_kfv gcc
          WHERE
           gcc.code_combination_id = l_facture.accts_pay_code_combination_id;

          --Recherche code TVA AUTOLI
          gv_step  := lv_current_program_unit||' 004 : Recherche code TVA AUTOLI :'||lv_societe||'/'||lv_region;
          --Dka_Tools_Pkg.put_log_message (gv_step);
          SELECT
           zr.tax_rate_id,
           zr.tax_rate_code,
           zr.percentage_rate,
           nvl(zr.description,zr.tax_rate_code),
           zr.offset_tax_rate_code,
           --
           zr.tax_regime_code,
           zr.tax,
           zr.tax_status_code,
           zr.tax_jurisdiction_code       
          INTO
           ln_autoli_tax_id,
           lv_autoli_name,
           ln_autoli_rate,
           lv_autoli_descrip,
           lv_offset_tax_rate_code,
           --
           lv_autoli_tax_regime_code,
           lv_autoli_tax,
           lv_autoli_tax_status_code,
           lv_autoli_tax_juridict_code
          FROM zx_rates_vl zr
          WHERE
           zr.tax_rate_code = 'DED_20.00_'||cv_autoli --Taux a déterminer
           AND l_facture.invoice_date BETWEEN nvl(zr.effective_from,LEAST(SYSDATE,l_facture.invoice_date))
                                          AND nvl(zr.effective_to,GREATEST(SYSDATE,l_facture.invoice_date))
           AND zr.active_flag         = 'Y';

          --Recherche code TVA OFFAUTO
          gv_step  := lv_current_program_unit||' 005 : Recherche code TVA OFFAUTO :'||lv_societe||'/'||lv_region;
          --Dka_Tools_Pkg.put_log_message (gv_step);
          SELECT
           zr.tax_rate_id,
           zr.tax_rate_code,
           zr.percentage_rate,
           nvl(zr.description,zr.tax_rate_code),
           --
           zr.tax_regime_code,
           zr.tax,
           zr.tax_status_code,
           zr.tax_jurisdiction_code       
          INTO
           ln_offauto_tax_id,
           lv_offauto_name,
           ln_offauto_rate,
           lv_offauto_descrip,
           --
           lv_offauto_tax_regime_code,
           lv_offauto_tax,
           lv_offauto_tax_status_code,
           lv_offauto_tax_juridict_code      
          FROM zx_rates_vl zr
          WHERE
           zr.tax_rate_code = lv_offset_tax_rate_code
           AND l_facture.invoice_date BETWEEN nvl(zr.effective_from,LEAST(SYSDATE,l_facture.invoice_date))
                                          AND nvl(zr.effective_to,GREATEST(SYSDATE,l_facture.invoice_date))
           AND zr.active_flag         = 'Y';


          gv_step  := lv_current_program_unit||' 006 : Controle égalité des taux AUTOLI et OFFAUTO';
          --Dka_Tools_Pkg.put_log_message (gv_step);
          IF ln_autoli_rate != (-1) * ln_offauto_rate THEN
           gv_step  := lv_current_program_unit||' 006 : Taux AUTOLI et OFFAUTO différents : '||lv_autoli_name||'/'||lv_offauto_name;
           --Dka_Tools_Pkg.put_log_message (gv_step);
           RAISE e_taux_diff;
          END IF;

          --INSERTION LIGNE AUTOLI
          gv_step  := lv_current_program_unit||' 007 : Insertion ligne AUTOLI';
          --Dka_Tools_Pkg.put_log_message (gv_step);
          INSERT INTO Ap_Invoice_Lines_Interface
           (INVOICE_ID
            ,INVOICE_LINE_ID
            ,LINE_NUMBER
            ,LINE_TYPE_LOOKUP_CODE
            ,LINE_GROUP_NUMBER
            ,AMOUNT
            ,ACCOUNTING_DATE
            ,DESCRIPTION
            ,AMOUNT_INCLUDES_TAX_FLAG
            ,PRORATE_ACROSS_FLAG
            ,TAX_CODE
            ,FINAL_MATCH_FLAG
            ,PO_HEADER_ID
            ,PO_NUMBER
            ,PO_LINE_ID
            ,PO_LINE_NUMBER
            ,PO_LINE_LOCATION_ID
            ,PO_SHIPMENT_NUM
            ,PO_DISTRIBUTION_ID
            ,PO_DISTRIBUTION_NUM
            ,PO_UNIT_OF_MEASURE
            ,INVENTORY_ITEM_ID
            ,ITEM_DESCRIPTION
            ,QUANTITY_INVOICED
            ,SHIP_TO_LOCATION_CODE
            ,UNIT_PRICE
            ,DISTRIBUTION_SET_ID
            ,DISTRIBUTION_SET_NAME
            ,DIST_CODE_CONCATENATED
            ,DIST_CODE_COMBINATION_ID
            ,AWT_GROUP_ID
            ,AWT_GROUP_NAME
            ,LAST_UPDATED_BY
            ,LAST_UPDATE_DATE
            ,LAST_UPDATE_LOGIN
            ,CREATED_BY
            ,CREATION_DATE
            ,ATTRIBUTE_CATEGORY
            ,ATTRIBUTE1
            ,ATTRIBUTE2
            ,ATTRIBUTE3
            ,ATTRIBUTE4
            ,ATTRIBUTE5
            ,ATTRIBUTE6
            ,ATTRIBUTE7
            ,ATTRIBUTE8
            ,ATTRIBUTE9
            ,ATTRIBUTE10
            ,ATTRIBUTE11
            ,ATTRIBUTE12
            ,ATTRIBUTE13
            ,ATTRIBUTE14
            ,ATTRIBUTE15
            ,GLOBAL_ATTRIBUTE_CATEGORY
            ,GLOBAL_ATTRIBUTE1
            ,GLOBAL_ATTRIBUTE2
            ,GLOBAL_ATTRIBUTE3
            ,GLOBAL_ATTRIBUTE4
            ,GLOBAL_ATTRIBUTE5
            ,GLOBAL_ATTRIBUTE6
            ,GLOBAL_ATTRIBUTE7
            ,GLOBAL_ATTRIBUTE8
            ,GLOBAL_ATTRIBUTE9
            ,GLOBAL_ATTRIBUTE10
            ,GLOBAL_ATTRIBUTE11
            ,GLOBAL_ATTRIBUTE12
            ,GLOBAL_ATTRIBUTE13
            ,GLOBAL_ATTRIBUTE14
            ,GLOBAL_ATTRIBUTE15
            ,GLOBAL_ATTRIBUTE16
            ,GLOBAL_ATTRIBUTE17
            ,GLOBAL_ATTRIBUTE18
            ,GLOBAL_ATTRIBUTE19
            ,GLOBAL_ATTRIBUTE20
            ,PO_RELEASE_ID
            ,RELEASE_NUM
            ,ACCOUNT_SEGMENT
            ,BALANCING_SEGMENT
            ,COST_CENTER_SEGMENT
            ,PROJECT_ID
            ,TASK_ID
            ,EXPENDITURE_TYPE
            ,EXPENDITURE_ITEM_DATE
            ,EXPENDITURE_ORGANIZATION_ID
            ,PROJECT_ACCOUNTING_CONTEXT
            ,PA_ADDITION_FLAG
            ,PA_QUANTITY
            ,USSGL_TRANSACTION_CODE
            ,STAT_AMOUNT
            ,TYPE_1099
            ,INCOME_TAX_REGION
            ,ASSETS_TRACKING_FLAG
            ,PRICE_CORRECTION_FLAG
            ,ORG_ID
            ,RECEIPT_NUMBER
            ,RECEIPT_LINE_NUMBER
            ,MATCH_OPTION
            ,PACKING_SLIP
            ,RCV_TRANSACTION_ID
            ,PA_CC_AR_INVOICE_ID
            ,PA_CC_AR_INVOICE_LINE_NUM
            ,REFERENCE_1
            ,REFERENCE_2
            ,PA_CC_PROCESSED_CODE
            ,TAX_RECOVERY_RATE
            ,TAX_RECOVERY_OVERRIDE_FLAG
            ,TAX_RECOVERABLE_FLAG
            ,TAX_CODE_OVERRIDE_FLAG
            ,TAX_CODE_ID
            ,CREDIT_CARD_TRX_ID
            ,AWARD_ID
            ,VENDOR_ITEM_NUM
            ,TAXABLE_FLAG
            ,PRICE_CORRECT_INV_NUM
            ,EXTERNAL_DOC_LINE_REF
            --
            ,TAX_REGIME_CODE       
            ,TAX                   
            ,TAX_JURISDICTION_CODE 
            ,TAX_STATUS_CODE       
            ,TAX_RATE_ID           
            ,TAX_RATE_CODE)
          VALUES
           (l_facture.invoice_id    --INVOICE_ID
            ,NULL                   --INVOICE_LINE_ID
            ,NULL                   --LINE_NUMBER
            ,'TAX'                  --LINE_TYPE_LOOKUP_CODE
            ,NULL                   --LINE_GROUP_NUMBER
            ,round(l_facture.invoice_amount*ln_autoli_rate/100,2) --AMOUNT
            ,NULL                   --ACCOUNTING_DATE
            ,lv_autoli_descrip      --DESCRIPTION
            ,NULL                   --AMOUNT_INCLUDES_TAX_FLAG
            ,NULL                   --PRORATE_ACROSS_FLAG
            ,lv_autoli_name         --TAX_CODE
            ,NULL                   --FINAL_MATCH_FLAG
            ,NULL                   --PO_HEADER_ID
            ,NULL                   --PO_NUMBER
            ,NULL                   --PO_LINE_ID
            ,NULL                   --PO_LINE_NUMBER
            ,NULL                   --PO_LINE_LOCATION_ID
            ,NULL                   --PO_SHIPMENT_NUM
            ,NULL                   --PO_DISTRIBUTION_ID
            ,NULL                   --PO_DISTRIBUTION_NUM
            ,NULL                   --PO_UNIT_OF_MEASURE
            ,NULL                   --INVENTORY_ITEM_ID
            ,NULL                   --ITEM_DESCRIPTION
            ,NULL                   --QUANTITY_INVOICED
            ,NULL                   --SHIP_TO_LOCATION_CODE
            ,NULL                   --UNIT_PRICE
            ,NULL                   --DISTRIBUTION_SET_ID
            ,NULL                   --DISTRIBUTION_SET_NAME
            ,NULL                   --DIST_CODE_CONCATENATED
            ,NULL                   --DIST_CODE_COMBINATION_ID
            ,NULL                   --AWT_GROUP_ID
            ,NULL                   --AWT_GROUP_NAME
            ,fnd_profile.value('USER_ID') --LAST_UPDATED_BY
            ,SYSDATE                --LAST_UPDATE_DATE
            ,fnd_profile.value('LOGIN_ID')--LAST_UPDATE_LOGIN
            ,fnd_profile.value('USER_ID') --CREATED_BY
            ,SYSDATE                --CREATION_DATE
            ,NULL                   --ATTRIBUTE_CATEGORY
            ,NULL                   --ATTRIBUTE1
            ,NULL                   --ATTRIBUTE2
            ,NULL                   --ATTRIBUTE3
            ,NULL                   --ATTRIBUTE4
            ,NULL                   --ATTRIBUTE5
            ,NULL                   --ATTRIBUTE6
            ,NULL                   --ATTRIBUTE7
            ,NULL                   --ATTRIBUTE8
            ,NULL                   --ATTRIBUTE9
            ,NULL                   --ATTRIBUTE10
            ,NULL                   --ATTRIBUTE11
            ,NULL                   --ATTRIBUTE12
            ,NULL                   --ATTRIBUTE13
            ,NULL                   --ATTRIBUTE14
            ,NULL                   --ATTRIBUTE15
            ,NULL                   --GLOBAL_ATTRIBUTE_CATEGORY
            ,NULL                   --GLOBAL_ATTRIBUTE1
            ,NULL                   --GLOBAL_ATTRIBUTE2
            ,NULL                   --GLOBAL_ATTRIBUTE3
            ,NULL                   --GLOBAL_ATTRIBUTE4
            ,NULL                   --GLOBAL_ATTRIBUTE5
            ,NULL                   --GLOBAL_ATTRIBUTE6
            ,NULL                   --GLOBAL_ATTRIBUTE7
            ,NULL                   --GLOBAL_ATTRIBUTE8
            ,NULL                   --GLOBAL_ATTRIBUTE9
            ,NULL                   --GLOBAL_ATTRIBUTE10
            ,NULL                   --GLOBAL_ATTRIBUTE11
            ,NULL                   --GLOBAL_ATTRIBUTE12
            ,NULL                   --GLOBAL_ATTRIBUTE13
            ,NULL                   --GLOBAL_ATTRIBUTE14
            ,NULL                   --GLOBAL_ATTRIBUTE15
            ,NULL                   --GLOBAL_ATTRIBUTE16
            ,NULL                   --GLOBAL_ATTRIBUTE17
            ,NULL                   --GLOBAL_ATTRIBUTE18
            ,NULL                   --GLOBAL_ATTRIBUTE19
            ,NULL                   --GLOBAL_ATTRIBUTE20
            ,NULL                   --PO_RELEASE_ID
            ,NULL                   --RELEASE_NUM
            ,NULL                   --ACCOUNT_SEGMENT
            ,NULL                   --BALANCING_SEGMENT
            ,NULL                   --COST_CENTER_SEGMENT
            ,NULL                   --PROJECT_ID
            ,NULL                   --TASK_ID
            ,NULL                   --EXPENDITURE_TYPE
            ,NULL                   --EXPENDITURE_ITEM_DATE
            ,NULL                   --EXPENDITURE_ORGANIZATION_ID
            ,NULL                   --PROJECT_ACCOUNTING_CONTEXT
            ,NULL                   --PA_ADDITION_FLAG
            ,NULL                   --PA_QUANTITY
            ,NULL                   --USSGL_TRANSACTION_CODE
            ,NULL                   --STAT_AMOUNT
            ,NULL                   --TYPE_1099
            ,NULL                   --INCOME_TAX_REGION
            ,NULL                   --ASSETS_TRACKING_FLAG
            ,NULL                   --PRICE_CORRECTION_FLAG
            ,l_facture.org_id       --ORG_ID
            ,NULL                   --RECEIPT_NUMBER
            ,NULL                   --RECEIPT_LINE_NUMBER
            ,NULL                   --MATCH_OPTION
            ,NULL                   --PACKING_SLIP
            ,NULL                   --RCV_TRANSACTION_ID
            ,NULL                   --PA_CC_AR_INVOICE_ID
            ,NULL                   --PA_CC_AR_INVOICE_LINE_NUM
            ,NULL                   --REFERENCE_1
            ,NULL                   --REFERENCE_2
            ,NULL                   --PA_CC_PROCESSED_CODE
            ,NULL                   --TAX_RECOVERY_RATE
            ,NULL                   --TAX_RECOVERY_OVERRIDE_FLAG
            ,'Y'                    --TAX_RECOVERABLE_FLAG
            ,NULL                   --TAX_CODE_OVERRIDE_FLAG
            ,NULL                   --TAX_CODE_ID
            ,NULL                   --CREDIT_CARD_TRX_ID
            ,NULL                   --AWARD_ID
            ,NULL                   --VENDOR_ITEM_NUM
            ,NULL                   --TAXABLE_FLAG
            ,NULL                   --PRICE_CORRECT_INV_NUM
            ,NULL                   --EXTERNAL_DOC_LINE_REF
            --
            ,lv_autoli_tax_regime_code      --TAX_REGIME_CODE
            ,lv_autoli_tax                  --TAX
            ,lv_autoli_tax_juridict_code    --TAX_JURISDICTION_CODE
            ,lv_autoli_tax_status_code      --TAX_STATUS_CODE
            ,NULL                           --TAX_RATE_ID
            ,lv_autoli_name                 --TAX_RATE_CODE
          );

          --INSERTION LIGNE OFFAUTO
          gv_step  := lv_current_program_unit||' 008 : Insertion ligne OFFAUTO';
          --Dka_Tools_Pkg.put_log_message (gv_step);
          INSERT INTO Ap_Invoice_Lines_Interface
           (INVOICE_ID
            ,INVOICE_LINE_ID
            ,LINE_NUMBER
            ,LINE_TYPE_LOOKUP_CODE
            ,LINE_GROUP_NUMBER
            ,AMOUNT
            ,ACCOUNTING_DATE
            ,DESCRIPTION
            ,AMOUNT_INCLUDES_TAX_FLAG
            ,PRORATE_ACROSS_FLAG
            ,TAX_CODE
            ,FINAL_MATCH_FLAG
            ,PO_HEADER_ID
            ,PO_NUMBER
            ,PO_LINE_ID
            ,PO_LINE_NUMBER
            ,PO_LINE_LOCATION_ID
            ,PO_SHIPMENT_NUM
            ,PO_DISTRIBUTION_ID
            ,PO_DISTRIBUTION_NUM
            ,PO_UNIT_OF_MEASURE
            ,INVENTORY_ITEM_ID
            ,ITEM_DESCRIPTION
            ,QUANTITY_INVOICED
            ,SHIP_TO_LOCATION_CODE
            ,UNIT_PRICE
            ,DISTRIBUTION_SET_ID
            ,DISTRIBUTION_SET_NAME
            ,DIST_CODE_CONCATENATED
            ,DIST_CODE_COMBINATION_ID
            ,AWT_GROUP_ID
            ,AWT_GROUP_NAME
            ,LAST_UPDATED_BY
            ,LAST_UPDATE_DATE
            ,LAST_UPDATE_LOGIN
            ,CREATED_BY
            ,CREATION_DATE
            ,ATTRIBUTE_CATEGORY
            ,ATTRIBUTE1
            ,ATTRIBUTE2
            ,ATTRIBUTE3
            ,ATTRIBUTE4
            ,ATTRIBUTE5
            ,ATTRIBUTE6
            ,ATTRIBUTE7
            ,ATTRIBUTE8
            ,ATTRIBUTE9
            ,ATTRIBUTE10
            ,ATTRIBUTE11
            ,ATTRIBUTE12
            ,ATTRIBUTE13
            ,ATTRIBUTE14
            ,ATTRIBUTE15
            ,GLOBAL_ATTRIBUTE_CATEGORY
            ,GLOBAL_ATTRIBUTE1
            ,GLOBAL_ATTRIBUTE2
            ,GLOBAL_ATTRIBUTE3
            ,GLOBAL_ATTRIBUTE4
            ,GLOBAL_ATTRIBUTE5
            ,GLOBAL_ATTRIBUTE6
            ,GLOBAL_ATTRIBUTE7
            ,GLOBAL_ATTRIBUTE8
            ,GLOBAL_ATTRIBUTE9
            ,GLOBAL_ATTRIBUTE10
            ,GLOBAL_ATTRIBUTE11
            ,GLOBAL_ATTRIBUTE12
            ,GLOBAL_ATTRIBUTE13
            ,GLOBAL_ATTRIBUTE14
            ,GLOBAL_ATTRIBUTE15
            ,GLOBAL_ATTRIBUTE16
            ,GLOBAL_ATTRIBUTE17
            ,GLOBAL_ATTRIBUTE18
            ,GLOBAL_ATTRIBUTE19
            ,GLOBAL_ATTRIBUTE20
            ,PO_RELEASE_ID
            ,RELEASE_NUM
            ,ACCOUNT_SEGMENT
            ,BALANCING_SEGMENT
            ,COST_CENTER_SEGMENT
            ,PROJECT_ID
            ,TASK_ID
            ,EXPENDITURE_TYPE
            ,EXPENDITURE_ITEM_DATE
            ,EXPENDITURE_ORGANIZATION_ID
            ,PROJECT_ACCOUNTING_CONTEXT
            ,PA_ADDITION_FLAG
            ,PA_QUANTITY
            ,USSGL_TRANSACTION_CODE
            ,STAT_AMOUNT
            ,TYPE_1099
            ,INCOME_TAX_REGION
            ,ASSETS_TRACKING_FLAG
            ,PRICE_CORRECTION_FLAG
            ,ORG_ID
            ,RECEIPT_NUMBER
            ,RECEIPT_LINE_NUMBER
            ,MATCH_OPTION
            ,PACKING_SLIP
            ,RCV_TRANSACTION_ID
            ,PA_CC_AR_INVOICE_ID
            ,PA_CC_AR_INVOICE_LINE_NUM
            ,REFERENCE_1
            ,REFERENCE_2
            ,PA_CC_PROCESSED_CODE
            ,TAX_RECOVERY_RATE
            ,TAX_RECOVERY_OVERRIDE_FLAG
            ,TAX_RECOVERABLE_FLAG
            ,TAX_CODE_OVERRIDE_FLAG
            ,TAX_CODE_ID
            ,CREDIT_CARD_TRX_ID
            ,AWARD_ID
            ,VENDOR_ITEM_NUM
            ,TAXABLE_FLAG
            ,PRICE_CORRECT_INV_NUM
            ,EXTERNAL_DOC_LINE_REF
            --
            ,TAX_REGIME_CODE       
            ,TAX                   
            ,TAX_JURISDICTION_CODE 
            ,TAX_STATUS_CODE       
            ,TAX_RATE_ID           
            ,TAX_RATE_CODE)
          VALUES
           (l_facture.invoice_id    --INVOICE_ID
            ,NULL                   --INVOICE_LINE_ID
            ,NULL                   --LINE_NUMBER
            ,'TAX'                  --LINE_TYPE_LOOKUP_CODE
            ,NULL                   --LINE_GROUP_NUMBER
            ,round(l_facture.invoice_amount*ln_offauto_rate/100,2) --AMOUNT
            ,NULL                   --ACCOUNTING_DATE
            ,lv_offauto_descrip     --DESCRIPTION
            ,NULL                   --AMOUNT_INCLUDES_TAX_FLAG
            ,NULL                   --PRORATE_ACROSS_FLAG
            ,lv_offauto_name        --TAX_CODE
            ,NULL                   --FINAL_MATCH_FLAG
            ,NULL                   --PO_HEADER_ID
            ,NULL                   --PO_NUMBER
            ,NULL                   --PO_LINE_ID
            ,NULL                   --PO_LINE_NUMBER
            ,NULL                   --PO_LINE_LOCATION_ID
            ,NULL                   --PO_SHIPMENT_NUM
            ,NULL                   --PO_DISTRIBUTION_ID
            ,NULL                   --PO_DISTRIBUTION_NUM
            ,NULL                   --PO_UNIT_OF_MEASURE
            ,NULL                   --INVENTORY_ITEM_ID
            ,NULL                   --ITEM_DESCRIPTION
            ,NULL                   --QUANTITY_INVOICED
            ,NULL                   --SHIP_TO_LOCATION_CODE
            ,NULL                   --UNIT_PRICE
            ,NULL                   --DISTRIBUTION_SET_ID
            ,NULL                   --DISTRIBUTION_SET_NAME
            ,NULL                   --DIST_CODE_CONCATENATED
            ,NULL                   --DIST_CODE_COMBINATION_ID
            ,NULL                   --AWT_GROUP_ID
            ,NULL                   --AWT_GROUP_NAME
            ,fnd_profile.value('USER_ID') --LAST_UPDATED_BY
            ,SYSDATE                --LAST_UPDATE_DATE
            ,fnd_profile.value('LOGIN_ID')--LAST_UPDATE_LOGIN
            ,fnd_profile.value('USER_ID') --CREATED_BY
            ,SYSDATE                --CREATION_DATE
            ,NULL                   --ATTRIBUTE_CATEGORY
            ,NULL                   --ATTRIBUTE1
            ,NULL                   --ATTRIBUTE2
            ,NULL                   --ATTRIBUTE3
            ,NULL                   --ATTRIBUTE4
            ,NULL                   --ATTRIBUTE5
            ,NULL                   --ATTRIBUTE6
            ,NULL                   --ATTRIBUTE7
            ,NULL                   --ATTRIBUTE8
            ,NULL                   --ATTRIBUTE9
            ,NULL                   --ATTRIBUTE10
            ,NULL                   --ATTRIBUTE11
            ,NULL                   --ATTRIBUTE12
            ,NULL                   --ATTRIBUTE13
            ,NULL                   --ATTRIBUTE14
            ,NULL                   --ATTRIBUTE15
            ,NULL                   --GLOBAL_ATTRIBUTE_CATEGORY
            ,NULL                   --GLOBAL_ATTRIBUTE1
            ,NULL                   --GLOBAL_ATTRIBUTE2
            ,NULL                   --GLOBAL_ATTRIBUTE3
            ,NULL                   --GLOBAL_ATTRIBUTE4
            ,NULL                   --GLOBAL_ATTRIBUTE5
            ,NULL                   --GLOBAL_ATTRIBUTE6
            ,NULL                   --GLOBAL_ATTRIBUTE7
            ,NULL                   --GLOBAL_ATTRIBUTE8
            ,NULL                   --GLOBAL_ATTRIBUTE9
            ,NULL                   --GLOBAL_ATTRIBUTE10
            ,NULL                   --GLOBAL_ATTRIBUTE11
            ,NULL                   --GLOBAL_ATTRIBUTE12
            ,NULL                   --GLOBAL_ATTRIBUTE13
            ,NULL                   --GLOBAL_ATTRIBUTE14
            ,NULL                   --GLOBAL_ATTRIBUTE15
            ,NULL                   --GLOBAL_ATTRIBUTE16
            ,NULL                   --GLOBAL_ATTRIBUTE17
            ,NULL                   --GLOBAL_ATTRIBUTE18
            ,NULL                   --GLOBAL_ATTRIBUTE19
            ,NULL                   --GLOBAL_ATTRIBUTE20
            ,NULL                   --PO_RELEASE_ID
            ,NULL                   --RELEASE_NUM
            ,NULL                   --ACCOUNT_SEGMENT
            ,NULL                   --BALANCING_SEGMENT
            ,NULL                   --COST_CENTER_SEGMENT
            ,NULL                   --PROJECT_ID
            ,NULL                   --TASK_ID
            ,NULL                   --EXPENDITURE_TYPE
            ,NULL                   --EXPENDITURE_ITEM_DATE
            ,NULL                   --EXPENDITURE_ORGANIZATION_ID
            ,NULL                   --PROJECT_ACCOUNTING_CONTEXT
            ,NULL                   --PA_ADDITION_FLAG
            ,NULL                   --PA_QUANTITY
            ,NULL                   --USSGL_TRANSACTION_CODE
            ,NULL                   --STAT_AMOUNT
            ,NULL                   --TYPE_1099
            ,NULL                   --INCOME_TAX_REGION
            ,NULL                   --ASSETS_TRACKING_FLAG
            ,NULL                   --PRICE_CORRECTION_FLAG
            ,l_facture.org_id       --ORG_ID
            ,NULL                   --RECEIPT_NUMBER
            ,NULL                   --RECEIPT_LINE_NUMBER
            ,NULL                   --MATCH_OPTION
            ,NULL                   --PACKING_SLIP
            ,NULL                   --RCV_TRANSACTION_ID
            ,NULL                   --PA_CC_AR_INVOICE_ID
            ,NULL                   --PA_CC_AR_INVOICE_LINE_NUM
            ,NULL                   --REFERENCE_1
            ,NULL                   --REFERENCE_2
            ,NULL                   --PA_CC_PROCESSED_CODE
            ,NULL                   --TAX_RECOVERY_RATE
            ,NULL                   --TAX_RECOVERY_OVERRIDE_FLAG
            ,'Y'                    --TAX_RECOVERABLE_FLAG
            ,NULL                   --TAX_CODE_OVERRIDE_FLAG
            ,NULL                   --TAX_CODE_ID
            ,NULL                   --CREDIT_CARD_TRX_ID
            ,NULL                   --AWARD_ID
            ,NULL                   --VENDOR_ITEM_NUM
            ,NULL                   --TAXABLE_FLAG
            ,NULL                   --PRICE_CORRECT_INV_NUM
            ,NULL                   --EXTERNAL_DOC_LINE_REF
            --
            ,lv_offauto_tax_regime_code      --TAX_REGIME_CODE
            ,lv_offauto_tax                  --TAX
            ,lv_offauto_tax_juridict_code    --TAX_JURISDICTION_CODE
            ,lv_offauto_tax_status_code      --TAX_STATUS_CODE
            ,NULL                           --TAX_RATE_ID
            ,lv_offauto_name                 --TAX_RATE_CODE
          );

          gv_step  := lv_current_program_unit||' 009 : Suppression des lignes de TVA exonéré';
          --Dka_Tools_Pkg.put_log_message (gv_step);

          DELETE FROM Ap_Invoice_Lines_Interface aili
          WHERE
           aili.invoice_id = l_facture.invoice_id
           AND  aili.line_type_lookup_code = 'TAX'
           AND EXISTS (SELECT NULL
                       FROM zx_rates_vl zr
                       WHERE
                           aili.tax_code       = zr.tax_rate_code
                       AND zr.percentage_rate  = 0);

          gv_step  := lv_current_program_unit||' 009 : Suppression des lignes de TVA exonéré : '||SQL%ROWCOUNT;
          --Dka_Tools_Pkg.put_log_message (gv_step);

          --  04/04.2018 NBO artf2473843 - COM001 - Fonction d'application de la TVA AUTOLIQUIDE
          gv_step  := lv_current_program_unit||' 010 : Mise à jour des lignes ITEM avec taux AUTOLI';
          --Dka_Tools_Pkg.put_debug_message (gv_step);

          UPDATE Ap_Invoice_Lines_Interface aili
          SET
           aili.TAX_CODE    = lv_autoli_name,
           aili.TAX_CODE_ID = ln_autoli_tax_id
          WHERE
           aili.invoice_id = l_facture.invoice_id
           AND  aili.line_type_lookup_code = 'ITEM';

          gv_step  := lv_current_program_unit||' 010 : Mise à jour des lignes ITEM avec taux AUTOLI : '||SQL%ROWCOUNT;
          

          ln_facture_traitee := ln_facture_traitee + 1;

          gv_step  := lv_current_program_unit||' 011 : COMMIT!';
          --Dka_Tools_Pkg.put_log_message (gv_step);
          COMMIT;

        EXCEPTION
          WHEN OTHERS THEN
           gv_step := 'Erreur lors de : ' || gv_step || ' : ' || SQLERRM;
           Dka_Tools_Pkg.put_log_message (gv_step);

           ln_facture_erreur := ln_facture_erreur + 1;

           ROLLBACK TO new_facture;
		 
		
        END;
		
		END IF; --EDB337 ARA
		
      END LOOP;

      gv_step  := lv_current_program_unit||' 12 : Factures traitées  : '||ln_facture_traitee;
      --Dka_Tools_Pkg.put_log_message (gv_step);

      gv_step  := lv_current_program_unit||' 13 : Factures en erreur : '||ln_facture_erreur;
      --Dka_Tools_Pkg.put_log_message (gv_step);

      pv_errbuf := 'Factures traitées  : '||ln_facture_traitee || ' / ' ||
                   'Factures en erreur : '||ln_facture_erreur;

      gv_step  := lv_current_program_unit||' 999 : FIN';
      --Dka_Tools_Pkg.put_log_message (gv_step);

    EXCEPTION
     WHEN OTHERS THEN
      pv_errbuf  :=  lv_current_program_unit||' EEE : ERREUR lors de :'||gv_step;
      pn_retcode := 2;
    END apply_tva_autoliquidee;


-----------------------------------------------------------------
--  Nom           : APPLY_ACOMPTE
--  Description   : Procedure utilisée pour rapprocher les acomptes des factures AP
--
--  PARAMETRES :
--     pv_source     Entrée      Source
--     pv_folio      Entrée      Code folio
--     pv_group_id   Entrée      Group ID
--     pn_org_id     Entrée      Org ID
--
--  VALEUR RETOURNEE :
--     pv_errbuf       :  Message de sortie
--     pn_retcode      :  '0'=OK, '2'=Erreur
-----------------------------------------------------------------
PROCEDURE apply_acompte(pv_errbuf   OUT VARCHAR2,
                        pn_retcode  OUT NUMBER,
                        pv_source   IN VARCHAR2,
                        pv_folio    IN VARCHAR2,
                        pv_group_id IN VARCHAR2,
                        pn_org_id   IN NUMBER) IS

  lv_current_program_unit  VARCHAR2(30) := 'apply_acompte';

  -- Récupération des couples Site / Devise pour lesquels il y a des factures eligibles
  CURSOR c_fournisseur_site(cv_source VARCHAR2, cv_folio VARCHAR2, cv_group_id VARCHAR2) IS
    SELECT DISTINCT aii.vendor_site_id,
                    aii.invoice_currency_code,
                    aii.org_id
      FROM ap_invoices_interface aii
     WHERE AII.SOURCE = cv_source
       AND aii.attribute9 = cv_folio
       AND aii.group_id = cv_group_id
       AND nvl(AII.STATUS, 'REJECTED') = 'REJECTED'
       AND invoice_type_lookup_code in ( 'STANDARD' , 'EXPENSE REPORT') --11/10/2018
       AND aii.org_id = pn_org_id
       AND aii.vendor_site_id IS NOT NULL;

  -- Récupération des factures éligibles selon le couple Site / Devise renseigné
  CURSOR c_facture_eligible(cv_source VARCHAR2, cv_folio VARCHAR2, cv_group_id VARCHAR2, cv_vendor_site_id NUMBER, cv_devise VARCHAR2) IS
    SELECT aii.invoice_id,
           aii.invoice_num,
           aii.invoice_date,
           aii.invoice_amount,
           aii.accts_pay_code_combination_id,
           aii.status,
           aii.org_id
      FROM ap_invoices_interface aii
     WHERE AII.SOURCE = cv_source
       AND aii.attribute9 = cv_folio
       AND aii.group_id = cv_group_id
       AND nvl(AII.STATUS, 'REJECTED') = 'REJECTED'
       AND invoice_type_lookup_code in ( 'STANDARD' , 'EXPENSE REPORT') --11/10/2018
       AND aii.org_id = pn_org_id
       AND aii.vendor_site_id = cv_vendor_site_id
       and aii.invoice_currency_code = cv_devise
  order by aii.status desc;

  vn_montant_non_rapproche  NUMBER;
  vn_montant_part_rapproche NUMBER;
  vn_montant_dispo          NUMBER;

  vn_nb_lignes_rapprochees NUMBER := 0;

  vv_tmp_prepay_num NUMBER;


BEGIN

  gv_step  := lv_current_program_unit||' 000 : DEBUT';
  --Dka_Tools_Pkg.put_log_message (gv_step);

  pv_errbuf  := '';
  pn_retcode := 0;


  gv_step  := lv_current_program_unit||' 001 : Réinitialisation des PREPAY_AMOUNT_APPLY : ';
  --Dka_Tools_Pkg.put_log_message (gv_step);

  /* Réinitialisation du champ PREPAY_AMOUNT_APPLY sur l'ensemble des factures concernées */
  UPDATE ap_invoices_interface aii
     SET PREPAY_APPLY_AMOUNT = NULL
   WHERE AII.SOURCE = pv_source
     AND aii.attribute9 = pv_folio
     AND aii.group_id = pv_group_id
     AND nvl(AII.STATUS, 'REJECTED') = 'REJECTED'
     AND invoice_type_lookup_code in ( 'STANDARD' , 'EXPENSE REPORT') --11/10/2018
     AND aii.org_id = pn_org_id
     AND aii.vendor_site_id IS NOT NULL;

  gv_step  := lv_current_program_unit||' 002 : Réinitialisation des PREPAY_AMOUNT_APPLY : '||SQL%ROWCOUNT;
  --Dka_Tools_Pkg.put_log_message (gv_step);

  COMMIT;
  

  gv_step  := lv_current_program_unit||' 003 : Récupération des couples fournisseur/site pour lesquels il existe des factures dans l''open interface';
  --Dka_Tools_Pkg.put_log_message (gv_step);

  /* Recuperation des couples fournisseur/site pour lesquels il existe des factures dans l'open interface */
  FOR c_fs IN c_fournisseur_site(pv_source, pv_folio, pv_group_id) LOOP

    gv_step  := lv_current_program_unit||' 004 : Site/devise/Org : ' || c_fs.vendor_site_id||'/'|| 
                                                                           c_fs.invoice_currency_code||'/'||
                                                                           c_fs.org_id;
    --Dka_Tools_Pkg.put_log_message (gv_step);
    
    vn_montant_non_rapproche  := 0;
    vn_montant_part_rapproche := 0;
    vn_montant_dispo          := 0;

    /* Recuperer les acomptes non rapprochés disponibles */
    gv_step  := lv_current_program_unit||' 005 : Recuperer les acomptes non rapprochés disponibles : ';
    --Dka_Tools_Pkg.put_log_message (gv_step);
    SELECT nvl(sum(amount),0)
      INTO vn_montant_non_rapproche
      FROM AP_INVOICES_ALL              aia,
           AP_PAYMENT_SCHEDULES_ALL     apsa,
           AP_INVOICE_DISTRIBUTIONS_ALL aida
     WHERE aia.invoice_id = apsa.invoice_id
       AND aia.invoice_id = aida.invoice_id
       AND aia.vendor_site_id = c_fs.vendor_site_id
       AND aia.invoice_currency_code = c_fs.invoice_currency_code
       AND aia.invoice_type_lookup_code = 'PREPAYMENT'
       AND AIA.EARLIEST_SETTLEMENT_DATE IS NOT NULL -- Ponctuel
       AND aia.WFAPPROVAL_STATUS = 'WFAPPROVED' -- Approuvé
       AND apsa.payment_status_flag = 'Y' 
       AND apsa.AMOUNT_REMAINING = 0 -- Réglé
       AND aia.org_id = pn_org_id
       AND nvl(aida.reversal_flag, 'N') != 'Y'
       AND aia.invoice_id not in
           (SELECT invoice_id 
            FROM AP_INVOICE_DISTRIBUTIONS_ALL aida3 
            WHERE aia.invoice_id = aida3.invoice_id 
              AND match_status_flag != 'A') -- Validé
       AND NOT EXISTS
          (SELECT 1 
           FROM AP_INVOICE_DISTRIBUTIONS_ALL 
           WHERE prepay_distribution_id = aida.invoice_distribution_id 
             and nvl(reversal_flag, 'N') != 'Y'); -- non rapproché
     
    gv_step  := lv_current_program_unit||' 005 : Recuperer les acomptes non rapprochés disponibles : '||vn_montant_non_rapproche;
    --Dka_Tools_Pkg.put_log_message (gv_step);
    

    /* Recuperer les acomptes partiellement rapprochés disponibles */
    gv_step  := lv_current_program_unit||' 006 : Recuperer les acomptes partiellement rapprochés disponibles : ';
    --Dka_Tools_Pkg.put_log_message (gv_step);
    
    SELECT nvl(sum(s1),0) + nvl(sum(s2),0) --   Addition car les montants de la table aida2 sont négatifs
    INTO vn_montant_part_rapproche
    FROM (
      SELECT aida.invoice_id, nvl(aida.amount,0) s1, nvl(sum(aida2.amount),0) s2
        FROM AP_INVOICES_ALL              aia,
             AP_PAYMENT_SCHEDULES_ALL     apsa,
             AP_INVOICE_DISTRIBUTIONS_ALL aida,
             AP_INVOICE_DISTRIBUTIONS_ALL aida2
       WHERE aia.invoice_id = apsa.invoice_id
         AND aia.invoice_id = aida.invoice_id
         AND aida.invoice_distribution_id = aida2.prepay_distribution_id -- (partiellement) rapproché
         AND aia.vendor_site_id = c_fs.vendor_site_id
         AND aia.invoice_currency_code = c_fs.invoice_currency_code
         AND aia.invoice_type_lookup_code = 'PREPAYMENT'
         AND aia.org_id = pn_org_id
         AND AIA.EARLIEST_SETTLEMENT_DATE IS NOT NULL -- Ponctuel
         AND aia.WFAPPROVAL_STATUS = 'WFAPPROVED' -- Approuvé
         AND apsa.payment_status_flag = 'Y' 
         AND apsa.AMOUNT_REMAINING = 0 -- Réglé
         AND aia.invoice_id not in
             (SELECT invoice_id 
              from AP_INVOICE_DISTRIBUTIONS_ALL aida3 
              where aia.invoice_id = aida3.invoice_id 
              and match_status_flag != 'A') -- Validé
         AND nvl(aida.reversal_flag, 'N') != 'Y'
         AND nvl(aida2.reversal_flag, 'N') != 'Y'
         AND aida2.LINE_TYPE_LOOKUP_CODE = 'PREPAY'
     GROUP BY aida.invoice_id, aida.amount);
    
    gv_step  := lv_current_program_unit||' 006 : Recuperer les acomptes partiellement rapprochés disponibles : '||vn_montant_part_rapproche;
    --Dka_Tools_Pkg.put_log_message (gv_step);
    
    vn_montant_dispo := vn_montant_non_rapproche + vn_montant_part_rapproche;
    gv_step  := lv_current_program_unit||' 007 : Montant disponible dans les acomptes : '||vn_montant_dispo;
    --Dka_Tools_Pkg.put_log_message (gv_step);
    
    /* Dans le cas ou il y a de la disponibilité dans les acomptes .. */
    IF (vn_montant_dispo > 0) THEN
    
      BEGIN
      /* Parcours des factures sur lesquelles on peut imputer des montants */
      FOR c_fe IN c_facture_eligible(pv_source,
                                     pv_folio,
                                     pv_group_id,
                                     c_fs.vendor_site_id,
                                     c_fs.invoice_currency_code) LOOP

        gv_step  := lv_current_program_unit||' 008 : Facture Id - '||c_fe.invoice_id || ' / Num - ' || c_fe.invoice_num|| ' / Montant - '||c_fe.invoice_amount;
        --Dka_Tools_Pkg.put_log_message (gv_step);
    
        
        IF (vn_montant_dispo > 0) THEN

          /* Si la facture est plus volumineuse que le montant d'acompte disponible */
          IF (c_fe.invoice_amount >= vn_montant_dispo) THEN
            
            gv_step  := lv_current_program_unit||' 009 : Facture >= Acompte';
            --Dka_Tools_Pkg.put_log_message (gv_step); 
            
            UPDATE AP_INVOICES_INTERFACE
               SET PREPAY_APPLY_AMOUNT = vn_montant_dispo,
                   PREPAY_GL_DATE = trunc(sysdate),  --11/10/2018			   
                   global_attribute5 = to_char(sysdate, 'HH24:MI:SS')
             WHERE invoice_id = c_fe.invoice_id
               AND invoice_type_lookup_code in ( 'STANDARD' , 'EXPENSE REPORT'); --11/10/2018

            vn_nb_lignes_rapprochees := vn_nb_lignes_rapprochees + SQL%ROWCOUNT;
            --Dka_Tools_Pkg.put_log_message('Nb lignes mises a jour : ' || SQL%ROWCOUNT);

            vn_montant_dispo := 0;
            
            gv_step  := lv_current_program_unit||' 010 : Montant restant dans les acomptes : '||vn_montant_dispo;
            --Dka_Tools_Pkg.put_log_message (gv_step); 
            
          /* Sinon, la facture est moins volumineuse que le montant d'acompte disponible */
          ELSE

            gv_step  := lv_current_program_unit||' 011 : Facture < Acompte';
            --Dka_Tools_Pkg.put_log_message (gv_step); 
           
            UPDATE AP_INVOICES_INTERFACE
               SET PREPAY_APPLY_AMOUNT = c_fe.invoice_amount, global_attribute5 = to_char(sysdate, 'HH24:MI:SS')
             WHERE invoice_id = c_fe.invoice_id
               AND invoice_type_lookup_code in ( 'STANDARD' , 'EXPENSE REPORT'); --11/10/2018

            vn_nb_lignes_rapprochees := vn_nb_lignes_rapprochees + SQL%ROWCOUNT;
            --Dka_Tools_Pkg.put_log_message('Nb lignes mises a jour : ' || SQL%ROWCOUNT);
            
            vn_montant_dispo := vn_montant_dispo - c_fe.invoice_amount;

            gv_step  := lv_current_program_unit||' 012 : Montant restant dans les acomptes : '||vn_montant_dispo;
            --Dka_Tools_Pkg.put_log_message (gv_step); 

          END IF;

        ELSE
          gv_step  := lv_current_program_unit||' 013 : Plus d''acompte disponible';
          --Dka_Tools_Pkg.put_log_message (gv_step);
        END IF;

      END LOOP; --c_facture_eligible

      EXCEPTION
        WHEN OTHERS THEN
          gv_step := 'Erreur lors de : ' || gv_step || ' : ' || SQLERRM;
          Dka_Tools_Pkg.put_log_message (gv_step);
          ROLLBACK;
      END;
      
    END IF; --vn_montant_dispo > 0

  END LOOP; --c_fournisseur_site

  COMMIT;

  gv_step  := lv_current_program_unit||' 12 : Nombre lignes rapprochees : '||vn_nb_lignes_rapprochees;
  --Dka_Tools_Pkg.put_log_message (gv_step);

  pv_errbuf := 'Nombre lignes rapprochees : '||vn_nb_lignes_rapprochees;

  gv_step  := lv_current_program_unit||' 999 : FIN';
  --Dka_Tools_Pkg.put_log_message (gv_step);

EXCEPTION
  WHEN OTHERS THEN
    pv_errbuf  :=  lv_current_program_unit||' EEE : ERREUR lors de :'||gv_step;
    pn_retcode := 2;
END apply_acompte;

-----------------------------------------------------------------
--  Nom           : APPLY_FONCTION
--  Description   : Procedure utilisée pour utiliser l'ensemble des fonction
--
--  PARAMETRES :
--     pv_interface_origine   Entrée   Interface origine
--     pv_source              Entrée   Source
--     pv_folio               Entrée   Code folio
--     pv_group_id            Entrée   Group ID
--     pn_org_id              Entrée   Org_id
--
--  VALEUR RETOURNEE :
--     pv_errbuf       :  Message de sortie
--     pn_retcode      :  '0'=OK, '2'=Erreur
-----------------------------------------------------------------                                   
  PROCEDURE apply_fonction(pv_errbuf            OUT VARCHAR2,
                           pn_retcode           OUT NUMBER,
                           pv_interface_origine IN VARCHAR2,
                           pv_source            IN VARCHAR2,
                           pv_folio             IN VARCHAR2,
                           pv_group_id          IN VARCHAR2,
                           pn_org_id            IN NUMBER) IS
                           
  CURSOR determine_fonction(interface VARCHAR2) IS
    SELECT ffvv_parent.FLEX_VALUE
      FROM fnd_flex_value_sets ffvs_parent,
           fnd_flex_values_vl  ffvv_parent,
           fnd_flex_value_sets ffvs_enfant,
           fnd_flex_values_vl  ffvv_enfant
     WHERE ffvv_parent.FLEX_VALUE_SET_ID = ffvs_parent.flex_value_set_id
       AND ffvs_parent.flex_value_set_name = 'DKA_AP_INTERFACE_FONCTION'
       AND ffvv_enfant.FLEX_VALUE_SET_ID = ffvs_enfant.flex_value_set_id
       AND ffvs_enfant.flex_value_set_name =
           'DKA_AP_INTERFACE_FONCTION_APPL'
       AND ffvv_parent.FLEX_VALUE = ffvv_enfant.PARENT_FLEX_VALUE_LOW
       AND ffvv_enfant.FLEX_VALUE = interface
       AND ffvv_parent.enabled_flag = 'Y'
       AND SYSDATE BETWEEN nvl(ffvv_parent.start_date_active,SYSDATE) AND nvl(ffvv_parent.end_date_active,SYSDATE)
       AND ffvv_enfant.enabled_flag = 'Y'
       AND SYSDATE BETWEEN nvl(ffvv_enfant.start_date_active,SYSDATE) AND nvl(ffvv_enfant.end_date_active,SYSDATE);
       

BEGIN

  Dka_Tools_Pkg.put_log_message('Interface : '||pv_interface_origine);

  FOR IC IN determine_fonction(pv_interface_origine) LOOP
  
    IF (IC.Flex_Value = 'ACOMPTE') THEN

      Dka_Tools_Pkg.put_log_message('  Lancement de la fonction apply_acompte');
      Dka_Tools_Pkg.put_log_message('    Source : '||pv_source||' / Folio : '||pv_folio||' / Groupe : '||pv_group_id);
      apply_acompte(pv_errbuf,
                    pn_retcode,
                    pv_source,
                    pv_folio,
                    pv_group_id,
                    pn_org_id);
    
    ELSIF (IC.Flex_Value = 'TVA_AUTOLIQUIDE') THEN
    
      Dka_Tools_Pkg.put_log_message('  Lancement de la fonction apply_tva_autoliquidee');
      Dka_Tools_Pkg.put_log_message('    Source : '||pv_source||' / Folio : '||pv_folio||' / Groupe : '||pv_group_id);
      apply_tva_autoliquidee(pv_errbuf,
                             pn_retcode,
                             pv_source,
                             pv_folio,
                             pv_group_id,
                             pn_org_id);
    END IF;
  
  END LOOP;
  
  Dka_Tools_Pkg.put_log_message('Fin de la fonction apply_fonction');

EXCEPTION
  WHEN OTHERS THEN
    pv_errbuf  := 'ERREUR APPLY_FONCTION : ' || SQLERRM;
    pn_retcode := 2;
  
END apply_fonction;

---------------------------------------------------------------------------------------
--  Nom           : get_vendor_partner
--  Description   : Procédure permettant d'obtenir les identifiants du fournisseur, du site fournisseur
--                  correspondant a la société passée en parametre et définis dans le centre de gestion
--                  et l'organisation passés en entrée
--
--  PARAMETRES :
--          pv_code_societe     Entrée
--          pn_org_id           Entrée
--          pn_vendor_id                Sortie
--          pn_vendor_site_id           Sortie
--          pv_errbuf           Entrée  Sortie
--          pn_retcode                  Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
PROCEDURE get_vendor_partner (
    pv_code_societe     IN       VARCHAR2,
    pn_org_id           IN       NUMBER,
    pn_vendor_id        OUT      NUMBER,
    pn_vendor_site_id   OUT      NUMBER,
    pv_errbuf           IN OUT   VARCHAR2,
    pn_retcode          OUT      NUMBER
)
IS
    CURSOR cur_vendor (pv_soc   IN   VARCHAR2) IS
      SELECT pv.vendor_id, 
             pvsa.vendor_site_id
        FROM po_vendor_sites_all pvsa, 
             po_vendors pv,
             gl_code_combinations gcc
       WHERE 1 = 1
         AND pv.vendor_id                       =    pvsa.vendor_id
         AND pvsa.accts_pay_code_combination_id =    gcc.code_combination_id
       --AND pv.attribute2                      =    pv_soc
         AND gcc.segment5                       =    pv_soc
         AND pvsa.org_id                        =    pn_org_id
         AND nvl(pvsa.pay_site_flag,'N') = 'Y' 
         AND pvsa.inactive_date IS NULL
    ORDER BY pvsa.creation_date; -- le site principal sera le premier cree

    rec_vendor       cur_vendor%ROWTYPE;
    e_vendor_error   EXCEPTION;
        
BEGIN

  OPEN cur_vendor (pv_code_societe);
  FETCH cur_vendor INTO rec_vendor;
  
  IF cur_vendor%NOTFOUND
  THEN
      
      BEGIN
        SELECT *
          INTO pn_vendor_id,
               pn_vendor_site_id 
        FROM (
              SELECT pv.vendor_id, 
                     pvsa.vendor_site_id
                FROM po_vendor_sites_all pvsa, 
                     po_vendors pv,
                     gl_code_combinations gcc
               WHERE 1 = 1
                 AND pv.vendor_id                       =    pvsa.vendor_id
                 AND pvsa.accts_pay_code_combination_id =    gcc.code_combination_id
                 AND gcc.segment5                       =    'XXX' || substr(pv_code_societe, -4)
                 AND pvsa.org_id                        =    pn_org_id
                 AND nvl(pvsa.pay_site_flag,'N') = 'Y' 
                 AND pvsa.inactive_date IS NULL
            ORDER BY pvsa.creation_date
             ) 
        WHERE ROWNUM = 1;
      
      EXCEPTION
        WHEN OTHERS THEN
             RAISE e_vendor_error;
      END;
      
  ELSE
      pn_vendor_id         := rec_vendor.vendor_id;
      pn_vendor_site_id    := rec_vendor.vendor_site_id;
  END IF;
    
EXCEPTION
    WHEN e_vendor_error THEN
       pv_errbuf     := 'get_vendor_partner : pas de fournisseur partenaire';
       pn_retcode    := 2;
    WHEN OTHERS THEN
       pv_errbuf     := 'Erreur get_vendor_partner: WHEN_OTHERS  ' || SQLERRM;
       pn_retcode    := 2;
END get_vendor_partner;

-----------------------------------------------------------------
--  Nom           : APPLY_FONCTION
--  Description   : Fonction utilisée pour verifier si le fournisseur est de type prestataire Analyse 
--
--  PARAMETRES :
--     pn_vendor_id   Entrée   Id du fournisseur
--
--  VALEUR RETOURNEE :
--     Quand le fournisseur est de type analyse : 'TRUE'
--     Sinon                                    : 'FALSE'
-----------------------------------------------------------------     

FUNCTION get_is_vendor_analyse ( 
    pn_vendor_id IN NUMBER
    )
RETURN VARCHAR2 
IS
    vn_verif     NUMBER;
BEGIN
    
    SELECT 1
    INTO vn_verif
    FROM  fnd_flex_value_sets ffvs, FND_FLEX_VALUES ffv, PO_VENDORS PV 
    WHERE ffvs.flex_value_set_name ='DKA_CODE_CATEGORIE'
    AND ffvs.flex_value_set_id = ffv.flex_value_set_id
    AND ffv.enabled_flag = 'Y' 
    AND ffv.attribute1 = 'OUI' 
    AND ffv.flex_value = REPLACE(pv.attribute8,'.','-') 
    AND pv.vendor_id = pn_vendor_Id
    AND ROWNUM = 1
    ;
    
    RETURN 'TRUE';
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'FALSE';
        
END get_is_vendor_analyse;

END DKA_AP_TOOLS_PKG; -- Corps du package
/
SHOW ERRORS
EXIT;
