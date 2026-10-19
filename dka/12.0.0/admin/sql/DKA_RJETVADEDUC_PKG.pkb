CREATE OR REPLACE PACKAGE BODY DKA_RJETVADEDUC_PKG AS

  ----------------------------------------------------------------------------------------------
  -- $$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_RJETVADEDUC_PKG.pkb
  -- DESCRIPTION       : DKA_RJETVADEDUC_PKG package body :
  ---
  ---                   Ce package est utilisé par le report spécifique DKA_RJETVADEDUC
  ---
  --- AUTEUR           : Thierry BOUGAULT
  --- DATE DE CREATION : 18/02/2009
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --- 17/06/2009  TB EARS00008699213 : Optimisation du traitement
  ---                Gestion des paiements annulés
  --- 23/09/2009 MSL Correction des requetes.
  --- 26/01/2010  TB Modification requête TVA/CRE pour gérer le multi-règlement d'une facture
  ---                à partir d'un même règlement
  --- 21/07/2014 BCO DPE20140051 : Gestion TVA Autoliquidée dans les états de TVA AP.
  --- 01/09/2016 RGH Migration R12
  --- 23/08/2017 YWA artf2210584 : ETA057 - Déclaration de la TVA déductible - Etat à revoir - defect ORACLE_R12 #802
  --- 31/08/2017 YWA artf2210584 : ETA057 - Déclaration de la TVA déductible - Etat à revoir - defect ORACLE_R12 #802
  --- 07/09/2017 NBO artf2210584 : ETA057 - Déclaration de la TVA déductible - Etat à revoir - defect ORACLE_R12 #802
  --- 14/09/2017 MEG artf2221764 : ETA057 - Gestion de TVA sur note de frais
  --- 27/09/2017 MEG artf2227961 : ETA057 - Revoir Montant TVA sur Facture et Montant Assujetti
  --- 05/10/2017 YWA artf2227961 : ETA057 - Revoir Montant TVA sur Facture et Montant Assujetti
  --- 20/03/2018 MEG artf2449650 : ETA057 - Lignes DSW affichees à tors pour toutes les sociétés et avec les memes montants
  --- 05/07/2018 OBE artf2825776 : INC0217729 - ETA057 - France - Déclaration de la TVA déductible
  --- 19/10/2018 SFA artf3039248 : INC0253409 - Modification champ Etats de TVA déductible
  --- 02/01/2019 NBO Optimisation problème de perf en production
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ------------------------------------------------------------------------------------------------------------------------

  -----------------------------------------------------------------
  -- NOM         : calcul_tva_cre
  -- DESCRIPTION : Alimentation de la table DKA_RJETVADEDUC_CRE
  -----------------------------------------------------------------
  PROCEDURE calcul_tva_cre(cre_request_id IN NUMBER,
                           --pv_societe           IN      VARCHAR2,
                           --pv_region            IN      VARCHAR2,
                           pv_uo IN VARCHAR2,
                           --pv_dka_company_num   IN      VARCHAR2,
                           pv_ledger     IN VARCHAR2,
                           pd_start_date IN DATE,
                           pd_end_date   IN DATE,
                           Pv_Debug_Mode IN VARCHAR2,
                           pv_errbuf     IN OUT VARCHAR2,
                           pn_retcode    OUT NUMBER

                           ) IS

  BEGIN
    -- 1

    pn_retcode := 0;
    pv_errbuf  := NULL;

    --------------------------------------------------------------
    -- Suppression des données de tous les traitements terminés --
    --------------------------------------------------------------
    IF Pv_Debug_Mode = 'N' THEN
      Dka_Tools_Pkg.Put_Debug_Message('Suppression des données des traitements précédents');

      DELETE FROM DKA_RJETVADEDUC_CRE Cre
       WHERE EXISTS
       (SELECT 'X'
                FROM Fnd_Concurrent_Requests Fcr,
                     Fnd_Concurrent_Programs Fcp
               WHERE Fcr.Concurrent_Program_Id = Fcp.Concurrent_Program_Id
                 AND Fcr.Phase_Code = 'C'
                 AND Fcp.Concurrent_Program_Name = 'DKA_RJETVADEDUC'
                 AND Fcr.Request_Id = Cre.Request_Id);

      COMMIT;

      Dka_Tools_Pkg.Put_Debug_Message('==> ' || SQL%ROWCOUNT ||
                                      ' enregistrements supprimés de la table DKA_RJETVADEDUC_CRE.');

    END IF;

    Dka_Tools_Pkg.put_debug_message('----------------- Insertion ligne pour TVA CRE/M -----------------');
    Dka_Tools_Pkg.put_debug_message(rpad('SOCIETE', 8) || ' * ' ||
                                    rpad('COMPANY', 8) || ' * ' ||
                                    rpad('CODE_TVA', 8) || ' * ' ||
                                    rpad('FACTU_NUM', 10) || ' * ' ||
                                    rpad('FACTURE_DATE', 12) || ' * ' ||
                                    rpad('PAR_DIST', 10) || ' * ' ||
                                    rpad('PART_TVA', 10) || ' * ' ||
                                    rpad('PART_REGL', 10) || ' * ' ||
                                    rpad('MONT_IMPOS', 10) || ' * ' ||
                                    rpad('TVA_RECUP', 10) || ' * ' ||
                                    rpad('KO', 3));

    FOR rec IN (--< OBE artf2825776
	            /*SELECT --CC_C.SEGMENT1 SOCIETE,
                --GCC_C.SEGMENT2 COMPANY_NUM,
                 substr(hou.name, 4, 4) SOCIETE,
                 substr(hou.name, 1, 3) COMPANY_NUM,
                 UPPER(gl.name) || UPPER(FFV.DESCRIPTION) COMPANY_NAME,
                 INV.INVOICE_ID INVOICE_ID,
                 --TAX.TAX_TYPE TAX_TYPE,-- RGH
                 --TAX.NAME CODE_TVA,-- RGH
                 --TAX.TAX_RATE TAUX_TVA,-- RGH
                 zrca.reporting_code_char_value TAX_TYPE,
                 zrb.tax_rate_code CODE_TVA,
                 zrb.percentage_rate TAUX_TVA,
                 GCC_TVA.SEGMENT3 CMP,
                 SUBSTR(INV.INVOICE_NUM, 1, 20) NUM_FACTURE,
                 INV.INVOICE_DATE DATE_FACTURE,
                 NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT) MONTANT_FACTURE_TTC,
                 ROUND(DECODE(DIS.TAX_RECOVERABLE_FLAG,
                              'Y',
                              SUM(NVL(ail.BASE_AMOUNT, ail.AMOUNT))
                              OVER(PARTITION BY ail.INVOICE_ID,
                                   ail.line_number,
                                   AIP.INVOICE_PAYMENT_ID
                                   ORDER BY NVL(ail.BASE_AMOUNT, ail.AMOUNT)),
                              0),
                       2) MONTANT_TVA_FACT,
                 ROUND(DECODE(DIS.TAX_RECOVERABLE_FLAG,
                              'Y',
                              SUM(NVL(ail.BASE_AMOUNT, ail.AMOUNT) /
                                  NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT) *
                                  AIP.AMOUNT)
                              OVER(PARTITION BY ail.INVOICE_ID,
                                   --DIS.DISTRIBUTION_LINE_NUMBER,
                                   ail.line_number,
                                   AIP.INVOICE_PAYMENT_ID -- MSL(++) / Modif TB 26/01/10
                                   ORDER BY NVL(ail.BASE_AMOUNT, ail.AMOUNT)) *
                              NVL(DIS.TAX_RECOVERY_RATE,
                                  NVL((select PERCENTAGE_RATE
                                        from ZX_RATES_B
                                       where RATE_TYPE_CODE = 'RECOVERY'
                                         and tax = zrb.tax),
                                      100)) / 100,
                              0),
                       2) MONTANT_TVA_PAR_CODE_TVA,
                 SUM(AIP.AMOUNT) OVER(PARTITION BY ail.INVOICE_ID,ail.line_number, AIP.INVOICE_PAYMENT_ID ORDER BY AIP.AMOUNT) PAY_AMT, -- MSL(++) / Modif TB 26/01/10
                 --SUM(NVL(HT.BASE_AMOUNT, HT.AMOUNT)) AMT_TXBL -- RGH
                -- sum(zl.TAXABLE_AMT) AMT_TXBL -- YWA artf2210584  -- SUM(aip.amount) AMT_TXBL
                 (SELECT sum(nvl(base_amount, amount)) from ap_invoice_lines_ALL where line_type_lookup_code != 'TAX' and invoice_id =ail.invoice_id and TAX_CLASSIFICATION_CODE = ail.tax_rate_code )AMT_TXBL, -- YWA artf2210584
                 ROUND((((SELECT sum(nvl(base_amount, amount))
                    FROM ap_invoice_lines_ALL
                  WHERE line_type_lookup_code != 'TAX'
                    AND invoice_id =ail.invoice_id
                    AND TAX_CLASSIFICATION_CODE = ail.tax_rate_code ) / NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT) * AIP.AMOUNT ) *
                              NVL(DIS.TAX_RECOVERY_RATE,
                                  NVL((select PERCENTAGE_RATE
                                        from ZX_RATES_B
                                       where RATE_TYPE_CODE = 'RECOVERY'
                                         and tax = zrb.tax),
                                      100)) / 100),2) MONTANT_ASSUJ
                  FROM AP_INVOICES              INV,
                       AP_INVOICE_DISTRIBUTIONS DIS,
                       --AP_TAX_CODES             TAX,   -- RGH
                       --AP_TAX_RECVRY_RATES      REC,   -- RGH
                       AP_CHECKS           CHK,
                       AP_INVOICE_PAYMENTS AIP,
                       --AP_INVOICE_DISTRIBUTIONS HT,    -- RGH
                       GL_CODE_COMBINATIONS  GCC_TVA,
                       ap_invoice_lines      ail, -- RGH
                       ZX_REPORT_CODES_ASSOC zrca, -- RGH
                       ZX_RATES_B            zrb, -- RGH
                       ZX_ACCOUNTS           za, -- RGH
                       zx_lines              zl, -- RGH
                       --GL_CODE_COMBINATIONS     GCC_C, -- RGH
                       FND_FLEX_VALUES_VL  FFV,
                       FND_FLEX_VALUE_SETS FFVS,
                       --FND_FLEX_VALUES_VL       FFV2, -- RGH
                       --FND_FLEX_VALUE_SETS      FFVS2 -- RGH
                       hr_operating_units hou, -- RGH
                       gl_ledgers         gl -- RGH
                 WHERE INV.INVOICE_ID = DIS.INVOICE_ID
                   AND INV.INVOICE_ID = AIP.INVOICE_ID
                   AND INV.INVOICE_ID = ail.invoice_id
                   AND GREATEST(AIP.ACCOUNTING_DATE,
                                NVL(CHK.FUTURE_PAY_DUE_DATE,
                                    AIP.ACCOUNTING_DATE),
                                ail.ACCOUNTING_DATE) BETWEEN pd_start_date AND
                       pd_end_date
                   AND CHK.CHECK_ID = AIP.CHECK_ID
                      --  DPE20140051 - Gestion des Types de TVA sur encaissement par les Codes express "TAX TYPE".
                      --  AND TAX.TAX_TYPE = 'CRE/M'
                   AND DIS.POSTED_FLAG || '' = 'Y'
                   AND DIS.MATCH_STATUS_FLAG IS NOT NULL
                   AND FFV.FLEX_VALUE = substr(hou.name, 1, 3)
                   AND FFV.FLEX_VALUE_SET_ID = FFVS.FLEX_VALUE_SET_ID
                      --- Début modifs RGH
                   and FFVS.FLEX_VALUE_SET_NAME = pv_uo
                   and hou.SET_OF_BOOKS_ID = gl.ledger_id
                   and ail.line_type_lookup_code = 'TAX'
                   and zrca.ENTITY_ID = za.tax_account_entity_id
                   and zrb.tax_rate_id = zrca.ENTITY_ID
                   and ail.tax_rate_id = zrca.ENTITY_ID
                   and zrca.entity_code = 'ZX_RATES'
                   and za.tax_account_entity_code = 'RATES'
                   and ail.org_id = za.internal_organization_id
                   and zl.application_id = 200
                   and zl.entity_code = 'AP_INVOICES'
                   and zl.trx_id = ail.invoice_id
                   and zl.TAX_RATE_ID = ail.TAX_RATE_ID
                   and zrca.reporting_code_char_value = 'CRE/M'
                   and GCC_TVA.code_combination_id =
                       dis.dist_code_combination_id
                   AND dis.invoice_line_number                 = ail.line_number --YWA artf2210584
                   and hou.SET_OF_BOOKS_ID = ail.set_of_books_id
                   and hou.SET_OF_BOOKS_ID = pv_ledger
                   and hou.organization_id = ail.org_id
                   and inv.org_id = ail.org_id
                   --- 07/09/2017 NBO artf2210584 : ETA057 - Déclaration de la TVA déductible - Etat à revoir - defect ORACLE_R12 #802
                   and inv.org_id = dis.org_id
                   AND NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT) <> 0

                   and 0 != (select sum(amount) from  AP_INVOICE_PAYMENTS_ALL where INVOICE_ID = AIP.INVOICE_ID  and
                                (ACCOUNTING_DATE BETWEEN pd_start_date AND
                       pd_end_date))--YWA artf2227961
                 GROUP BY --GCC_C.SEGMENT1,
                          --GCC_C.SEGMENT2,
                           substr(hou.name, 4, 4),
                          substr(hou.name, 1, 3),
                          INV.INVOICE_ID,
                          --UPPER(FFV2.DESCRIPTION) || UPPER(FFV.DESCRIPTION),
                          UPPER(gl.name) || UPPER(FFV.DESCRIPTION),
                          zrca.reporting_code_char_value,
                          zrb.tax_rate_code,
                          zrb.percentage_rate,
                          zrb.tax,
                          GCC_TVA.SEGMENT3,
                          SUBSTR(INV.INVOICE_NUM, 1, 20),
                          INV.INVOICE_DATE,
                          NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT),
                          DIS.TAX_RECOVERABLE_FLAG,
                          DIS.TAX_RECOVERY_RATE,
                          ail.LINE_TYPE_LOOKUP_CODE,-- YWA artf2210584
                          ail.AMOUNT,-- YWA artf2210584
                          AIP.AMOUNT,
                          ail.INVOICE_ID,-- YWA artf2210584
                          --DIS.DISTRIBUTION_LINE_NUMBER,-- YWA artf2210584
                          ail.line_number,-- YWA artf2210584
                          ail.BASE_AMOUNT,-- YWA artf2210584
                          ail.tax_rate_code,-- YWA artf2210584
                          AIP.INVOICE_PAYMENT_ID -- Modif TB 26/01/10
                HAVING ROUND(DECODE(DIS.TAX_RECOVERABLE_FLAG, 'Y', SUM(NVL(ail.BASE_AMOUNT, ail.AMOUNT) / NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT) * AIP.AMOUNT) * NVL(DIS.TAX_RECOVERY_RATE, NVL((select PERCENTAGE_RATE
                                                                                                                                                                                                    from ZX_RATES_B
                                                                                                                                                                                                   where RATE_TYPE_CODE =
                                                                                                                                                                                                         'RECOVERY'
                                                                                                                                                                                                     and tax =
                                                                                                                                                                                                         zrb.tax), 100)) / 100, 0), 2) <> 0

                UNION ALL
                SELECT --CC_C.SEGMENT1 SOCIETE,
                --GCC_C.SEGMENT2 COMPANY_NUM,
                 substr(hou.name, 4, 4) SOCIETE,
                 substr(hou.name, 1, 3) COMPANY_NUM,
                 UPPER(gl.name) || UPPER(FFV.DESCRIPTION) COMPANY_NAME,
                 INV.INVOICE_ID INVOICE_ID,
                 --TAX.TAX_TYPE TAX_TYPE,-- RGH
                 --TAX.NAME CODE_TVA,-- RGH
                 --TAX.TAX_RATE TAUX_TVA,-- RGH
                 zrca.reporting_code_char_value TAX_TYPE,
                 zrb.tax_rate_code CODE_TVA,
                 zrb.percentage_rate TAUX_TVA,
                 GCC_TVA.SEGMENT3 CMP,
                 SUBSTR(INV.INVOICE_NUM, 1, 20) NUM_FACTURE,
                 INV.INVOICE_DATE DATE_FACTURE,
                 NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT) MONTANT_FACTURE_TTC,
                 ROUND(DECODE(DIS.TAX_RECOVERABLE_FLAG,
                              'Y',
                              SUM(NVL(ail.BASE_AMOUNT, ail.AMOUNT))
                              OVER(PARTITION BY ail.INVOICE_ID,
                                   ail.line_number ORDER BY
                                   NVL(ail.BASE_AMOUNT, ail.AMOUNT)),
                              0),
                       2) MONTANT_TVA_FACT,
                 ROUND(DECODE(DIS.TAX_RECOVERABLE_FLAG,
                              'Y',
                              SUM(NVL(ail.BASE_AMOUNT, ail.AMOUNT) /
                                  NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT) *
                                  ACPTE.MONTANT_ACPTE)
                              OVER(PARTITION BY ail.INVOICE_ID,
                                   ail.line_number ORDER BY
                                   NVL(ail.BASE_AMOUNT, ail.AMOUNT)) *
                              NVL(DIS.TAX_RECOVERY_RATE,
                                  NVL((select PERCENTAGE_RATE
                                        from ZX_RATES_B
                                       where RATE_TYPE_CODE = 'RECOVERY'
                                         and tax = zrb.tax),
                                      100)) / 100,
                              0),
                       2) MONTANT_TVA_PAR_CODE_TVA,
                 SUM(ACPTE.MONTANT_ACPTE) OVER(PARTITION BY ail.INVOICE_ID, ail.line_number ORDER BY ACPTE.MONTANT_ACPTE) PAY_AMT,
                 --SUM(NVL(HT.BASE_AMOUNT, HT.AMOUNT)) AMT_TXBL
                 --sum(zl.TAXABLE_AMT) AMT_TXBL
                 (SELECT sum(nvl(base_amount, amount)) from ap_invoice_lines_ALL where line_type_lookup_code != 'TAX' and invoice_id =ail.invoice_id and TAX_CLASSIFICATION_CODE = ail.tax_rate_code)AMT_TXBL, -- YWA artf2210584
                 ROUND((((SELECT sum(nvl(base_amount, amount))
                    FROM ap_invoice_lines_ALL
                  WHERE line_type_lookup_code != 'TAX'
                    AND invoice_id =ail.invoice_id
                    AND TAX_CLASSIFICATION_CODE = ail.tax_rate_code ) / NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT) * ACPTE.MONTANT_ACPTE ) *
                              NVL(DIS.TAX_RECOVERY_RATE,
                                  NVL((select PERCENTAGE_RATE
                                        from ZX_RATES_B
                                       where RATE_TYPE_CODE = 'RECOVERY'
                                         and tax = zrb.tax),
                                      100)) / 100), 2) MONTANT_ASSUJ
                  FROM AP_INVOICES_ALL          INV,
                       AP_INVOICE_DISTRIBUTIONS DIS,
                       ap_invoice_lines         ail, -- RGH
                       --AP_TAX_CODES             TAX,   -- RGH
                       --AP_TAX_RECVRY_RATES      REC,   -- RGH
                       --AP_INVOICE_DISTRIBUTIONS HT,    -- RGH
                       ZX_REPORT_CODES_ASSOC zrca, -- RGH
                       ZX_RATES_B            zrb, -- RGH
                       ZX_ACCOUNTS           za, -- RGH
                       zx_lines              zl, -- RGH
                       GL_CODE_COMBINATIONS  GCC_TVA,
                       --GL_CODE_COMBINATIONS         GCC_C, --RGH
                       FND_FLEX_VALUES_VL  FFV,
                       FND_FLEX_VALUE_SETS FFVS,
                       --FND_FLEX_VALUES_VL           FFV2, -- RGH
                       --FND_FLEX_VALUE_SETS          FFVS2,-- RGH
                       hr_operating_units hou, -- RGH
                       gl_ledgers gl, -- RGH
                       (SELECT INVOICE_ID,
                               -SUM(NVL(AID.BASE_AMOUNT, NVL(AID.AMOUNT, 0))) MONTANT_ACPTE
                          FROM AP_INVOICE_LINES_ALL AID --AP_INVOICE_DISTRIBUTIONS_ALL --RGH
                         WHERE AID.LINE_TYPE_LOOKUP_CODE = 'PREPAY'
                           AND AID.ACCOUNTING_DATE BETWEEN pd_start_date AND
                               pd_end_date
                         GROUP BY INVOICE_ID) ACPTE
                 WHERE ACPTE.INVOICE_ID = INV.INVOICE_ID
                   AND INV.INVOICE_ID = DIS.INVOICE_ID
                   AND DIS.POSTED_FLAG || '' = 'Y'
                      --  DPE20140051 - Gestion des Types de TVA sur encaissement par les Codes express "TAX TYPE".
                      --  AND TAX.TAX_TYPE = 'CRE/M'
                   AND DIS.MATCH_STATUS_FLAG IS NOT NULL
                   AND FFV.FLEX_VALUE_SET_ID = FFVS.FLEX_VALUE_SET_ID
                   AND EXISTS
                 (SELECT 'X'
                          FROM AP_INVOICE_LINES_ALL AID --AP_INVOICE_DISTRIBUTIONS_ALL --RGH
                         WHERE AID.INVOICE_ID = INV.INVOICE_ID
                           AND AID.LINE_TYPE_LOOKUP_CODE = 'PREPAY'
                           AND AID.ACCOUNTING_DATE BETWEEN pd_start_date AND
                               pd_end_date)
                   AND NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT) <> 0
                      --- Début modifs RGH
                   and INV.INVOICE_ID = ail.invoice_id
                   and FFVS.FLEX_VALUE_SET_NAME = pv_uo
                   and FFV.FLEX_VALUE = substr(hou.name, 1, 3)
                   and hou.SET_OF_BOOKS_ID = gl.ledger_id
                   and ail.line_type_lookup_code = 'TAX'
                   and zrca.ENTITY_ID = za.tax_account_entity_id
                   and zrb.tax_rate_id = zrca.ENTITY_ID
                   and ail.tax_rate_id = zrca.ENTITY_ID
                   and zrca.entity_code = 'ZX_RATES'
                   and za.tax_account_entity_code = 'RATES'
                   and ail.org_id = za.internal_organization_id
                   and zl.application_id = 200
                   and zl.entity_code = 'AP_INVOICES'
                   and zl.trx_id = ail.invoice_id
                   and zl.TAX_RATE_ID = ail.TAX_RATE_ID
                   and zrca.reporting_code_char_value = 'CRE/M'
                   and GCC_TVA.code_combination_id =
                       dis.dist_code_combination_id
                   AND dis.invoice_line_number                 = ail.line_number --YWA artf2210584
                   and hou.SET_OF_BOOKS_ID = ail.set_of_books_id
                   and hou.SET_OF_BOOKS_ID = pv_ledger
                   and hou.organization_id = ail.org_id
                   and inv.org_id = ail.org_id
                   --- 07/09/2017 NBO artf2210584 : ETA057 - Déclaration de la TVA déductible - Etat à revoir - defect ORACLE_R12 #802
                   and inv.org_id = dis.org_id
                 GROUP BY --GCC_C.SEGMENT1,
                          --GCC_C.SEGMENT2,
                           substr(hou.name, 4, 4),
                          substr(hou.name, 1, 3),
                          INV.INVOICE_ID,
                          -- UPPER(FFV2.DESCRIPTION) || UPPER(FFV.DESCRIPTION),
                          UPPER(gl.name) || UPPER(FFV.DESCRIPTION),
                          --TAX.TAX_TYPE,
                          --TAX.NAME,
                          --TAX.TAX_RATE,
                          zrca.reporting_code_char_value,
                          zrb.tax_rate_code,
                          zrb.percentage_rate,
                          zrb.tax,
                          GCC_TVA.SEGMENT3,
                          SUBSTR(INV.INVOICE_NUM, 1, 20),
                          INV.INVOICE_DATE,
                          NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT),
                          DIS.TAX_RECOVERABLE_FLAG,
                          DIS.TAX_RECOVERY_RATE,
                          --REC.RECOVERY_RATE,
                          -- YWA artf2210584
                          ail.LINE_TYPE_LOOKUP_CODE,
                          ail.AMOUNT,
                          ail.INVOICE_ID,
                          --DIS.DISTRIBUTION_LINE_NUMBER,
                          ail.line_number,
                          ail.BASE_AMOUNT,
                          ail.tax_rate_code,
                          ACPTE.MONTANT_ACPTE -- MSL(++)
                HAVING ROUND(DECODE(DIS.TAX_RECOVERABLE_FLAG, 'Y', SUM(NVL(ail.BASE_AMOUNT, ail.AMOUNT)) * NVL(DIS.TAX_RECOVERY_RATE, NVL((select PERCENTAGE_RATE
                                                                                                                                             from ZX_RATES_B
                                                                                                                                            where RATE_TYPE_CODE =
                                                                                                                                                  'RECOVERY'
                                                                                                                                              and tax =
                                                                                                                                                  zrb.tax), 100)) / 100, 0), 2) <> 0


    UNION ALL

       SELECT  substr(hou.name, 4, 4) societe,
              substr(hou.name, 1, 3) company_num,
              UPPER(gl.name) || UPPER(ffv.description) company_name,
              inv.invoice_id invoice_id,
              zrca.reporting_code_char_value tax_type,
              zl.tax_rate_code code_tva,
              zl.tax_rate taux_tva,
              cc.segment3 cmp,
              SUBSTR(inv.invoice_num, 1, 20) num_facture,
              inv.invoice_date date_facture,
              DECODE(zrca.reporting_code_char_value, 'OFFSET', 0, nvl(inv.base_amount, inv.invoice_amount)) montant_facture_ttc,--YWA artf2227961
              sum(ROUND(DECODE(aid.tax_recoverable_flag,'Y',nvl(aid.amount,aid.base_amount),0), 2)) MONTANT_TVA_FACT,--YWA artf2227961
             -- sum(TAX_AMT) MONTANT_TVA_PAR_CODE_TVA,
               sum(ROUND((inv.amount_paid / (DECODE(zrb.tax_status_code, 'OFFSET', 0, NVL(inv.base_amount, inv.invoice_amount))))* zl.tax_amt,2))  MONTANT_TVA_PAR_CODE_TVA,--YWA artf2227961
              -- ROUND(DECODE(aid.tax_recoverable_flag,'Y',(inv.amount_paid /(DECODE(zrb.tax_status_code, 'OFFSET', 0, NVL(inv.base_amount, inv.invoice_amount)))) * zl.tax_amt,0), 2) MONTANT_TVA_PAR_CODE_TVA,
              inv.amount_paid pay_amt,--YWA artf2227961
            --  (SELECT sum(nvl(base_amount, amount)) from ap_invoice_lines_ALL where line_type_lookup_code != 'TAX' and invoice_id =ail.invoice_id and TAX_CLASSIFICATION_CODE = aid.TAX_CODE_ID)AMT_TXBL, -- YWA artf2210584
             sum(zl.taxable_amt) amt_txbl,--YWA artf2227961
             sum(ROUND((inv.amount_paid / (DECODE(zrb.tax_status_code, 'OFFSET', 0, NVL(inv.base_amount, inv.invoice_amount)))) * zl.taxable_amt,2)) MONTANT_ASSUJ--YWA artf2227961
         FROM --ap_suppliers                 ven,
              AP_INVOICES_ALL              inv,
              AP_INVOICE_LINES_ALL         ail,
              AP_INVOICE_DISTRIBUTIONS_ALL aid,
              AP_INVOICE_PAYMENTS_ALL      aip,
              AP_CHECKS_ALL                chk,
              zx_lines_v               zl,
              hr_operating_units       hou,
              gl_code_combinations     cc,
              ZX_RATES_B               zrb,
              ZX_REPORT_CODES_ASSOC    zrca,
              FND_FLEX_VALUES_VL       ffv,
              FND_FLEX_VALUE_SETS      ffvs,
              gl_ledgers               gl
        WHERE 1=1 --ven.vendor_id = inv.vendor_id
          AND ail.invoice_id = inv.invoice_id
          AND ail.invoice_id = zl.trx_id
          AND ail.line_number = zl.trx_line_id
          AND ail.set_of_books_id = hou.set_of_books_id
          AND cc.code_combination_id = aid.dist_code_combination_id
          AND inv.invoice_id = aid.invoice_id
          AND ail.line_number = aid.invoice_line_number
          AND zrb.tax_rate_id = zrca.ENTITY_ID
          AND inv.org_id = ail.org_id
          AND inv.invoice_id = aip.invoice_id
          AND chk.check_id = aip.check_id
          AND zrca.entity_code = 'ZX_RATES'
          AND aid.posted_flag || '' = 'Y'
          AND NVL(inv.base_amount, inv.invoice_amount) <> 0
          AND aid.match_status_flag IS NOT NULL
          AND aid.line_type_lookup_code = 'REC_TAX'
          AND zrb.tax_rate_id = aid.tax_code_id
          AND zrca.reporting_code_char_value = 'CRE/M'
          AND zl.cancel_flag = 'N'
          AND NVL(aid.reversal_flag, 'N') = 'N'
          AND GREATEST(aip.accounting_date, NVL(chk.future_pay_due_date, aip.accounting_date), ail.accounting_date)  BETWEEN pd_start_date AND pd_end_date
          AND hou.SET_OF_BOOKS_ID = pv_ledger
          AND hou.organization_id = ail.org_id
          AND zl.entity_code = 'AP_INVOICES'
           and zl.application_id = 200
          AND ffv.flex_value_set_id = ffvs.flex_value_set_id
          AND ffvs.flex_value_set_name = 'DAOPCCF_UO'
          AND ffv.flex_value = substr(hou.name, 1, 3)
          --and INV.INVOICE_TYPE_LOOKUP_CODE = 'EXPENSE REPORT'
          AND hou.SET_OF_BOOKS_ID = gl.ledger_id
          --YWA artf2227961
           GROUP BY substr(hou.name, 4, 4),
                     substr(hou.name, 1, 3),
                     UPPER(gl.name) || UPPER(ffv.description),
                     inv.invoice_id,
                     zrca.reporting_code_char_value,
                     zl.tax_rate_code,
                     zl.tax_rate,
                     cc.segment3,
                     SUBSTR(inv.invoice_num, 1, 20),
                     inv.invoice_date,
                     DECODE(zrca.reporting_code_char_value, 'OFFSET', 0, nvl(inv.base_amount, inv.invoice_amount)),
                     --ROUND(DECODE(aid.tax_recoverable_flag,'Y',nvl(aid.amount,aid.base_amount),0), 2) ,--YWA
                 --ROUND(DECODE(aid.tax_recoverable_flag,'Y',(inv.amount_paid /(DECODE(zrb.tax_status_code, 'OFFSET', 0, NVL(inv.base_amount, inv.invoice_amount)))) * zl.tax_amt,0), 2) ,
              inv.amount_paid --,aid.invoice_line_number
            ---   zl.taxable_amt ,
             -- ROUND((inv.amount_paid / (DECODE(zrb.tax_status_code, 'OFFSET', 0, NVL(inv.base_amount, inv.invoice_amount)))),2) * zl.tax_amt
        */

       select substr(hou.name, 4, 4) SOCIETE,
              substr(hou.name, 1, 3) COMPANY_NUM,
              UPPER(gl.name) COMPANY_NAME,
			  ai.invoice_id INVOICE_ID,
              decode(zd.def_rec_settlement_option_code,
                    'IMMEDIATE',
                    'DEB/M',
                    'CRE/M') TAX_TYPE,
			  zd.tax_rate_code CODE_TVA,
              zd.tax_rate TAUX_TVA,
              DKA_RJETVADEDUC_PKG.dka_check_codetva(zd.tax_rate_code ,gcc.segment3,zl.tax_line_id,zl.INTERNAL_ORGANIZATION_ID)CMP,--gcc.segment3 CMP,---//SFA---artf3039248 : INC0253409----récuperation du compte de taxe récupérable
			  SUBSTR(zd.trx_number,1,20) NUM_FACTURE,
			  ai.INVOICE_DATE DATE_FACTURE,
			  nvl(ai.base_amount, ai.invoice_amount) MONTANT_FACTURE_TTC,
			  ROUND(decode(zl.cancel_flag,'Y', zl.orig_tax_amt, sum(zd.rec_nrec_tax_amt_funcl_curr)) * REGLT.POURCENTAGE, 2) MONTANT_TVA_FACT,
			  REGLT.amount PAY_AMT,
			  ROUND(decode(zl.cancel_flag,'Y', zl.orig_taxable_amt, sum(zd.taxable_amt_funcl_curr)) * REGLT.POURCENTAGE, 2) AMT_TXBL
       from zx_rec_nrec_dist             zd,
            zx_lines                     zl,
            ap_invoices_all              ai,
            ap_invoice_distributions_all aid,
            gl_code_combinations         gcc,
            ap_suppliers                 ven,
            hr_operating_units           hou,
	        gl_ledgers                   gl,
            (select distinct (aip.invoice_id) INVOICE_ID,
                             sum(aip.amount) AMOUNT,
                             sum(aip.amount) / decode(nvl(decode(nvl(aia.base_amount,
                                                   aia.invoice_amount),
                                               0,
                                               aia.cancelled_amount,
                                               nvl(aia.base_amount,
                                                   nvl(aia.base_amount,
                                                       aia.invoice_amount))),
                                        sum(aip.amount)),
                                    0,
                                    1,
                                    nvl(decode(nvl(aia.base_amount,
                                                   aia.invoice_amount),
                                               0,
                                               aia.cancelled_amount,
                                               nvl(aia.base_amount,
                                                   nvl(aia.base_amount,
                                                       aia.invoice_amount))),
                                        sum(aip.amount))) POURCENTAGE
               from ap_invoice_payments_all aip,
                    ap_checks_all           ac,
                    ap_invoices_all         aia
               where aip.invoice_id = aia.invoice_id
		       and nvl(aia.base_amount, aia.invoice_amount)=0
		       /*and aia.invoice_id in (select distinct zd1.trx_id
                              from zx_rec_nrec_dist zd1 , hr_operating_units hou1
                              where zd1.application_id = 200
                              and zd1.entity_code = 'AP_INVOICES'
                              and zd1.recoverable_flag = 'Y'
                              and zd1.def_rec_settlement_option_code = 'DEFERRED'
                              and zd1.gl_date <= pd_end_date
                              and zd1.ledger_id = pv_ledger
                              and hou1.organization_id = zd1.internal_organization_id
                              and hou1.set_of_books_id = zd1.ledger_id
                              )*/
               and aip.check_id = ac.check_id
               and aip.accrual_posted_flag = 'Y'
               and GREATEST(aip.accounting_date,
                            nvl(ac.future_pay_due_date, aip.accounting_date),
                            aip.accounting_date) between pd_start_date and pd_end_date --PARAMETRES DATES
               group by aip.invoice_id, aia.base_amount, aia.invoice_amount, aia.cancelled_amount
               UNION ALL
               select distinct (aid.invoice_id) INVOICE_ID,
                        -sum(nvl(aid.base_amount, aid.amount)) AMOUNT,
                        -sum(nvl(aid.base_amount, aid.amount)) / decode(nvl(decode(nvl(aia.base_amount,
                                              aia.invoice_amount),
                                          0,
                                          aia.cancelled_amount,
                                          nvl(aia.base_amount,
                                              nvl(aia.base_amount,
                                                  aia.invoice_amount))),
                                   -sum(nvl(aid.base_amount, aid.amount))),
                               0,
                               1,
                               nvl(decode(nvl(aia.base_amount,
                                              aia.invoice_amount),
                                          0,
                                          aia.cancelled_amount,
                                          nvl(aia.base_amount,
                                              nvl(aia.base_amount,
                                                  aia.invoice_amount))),
                                   -sum(nvl(aid.base_amount, aid.amount))))  POURCENTAGE
                from ap_invoices_all aia, ap_invoice_distributions_all aid
                where aia.invoice_id = aid.invoice_id
		        and nvl(aia.base_amount, aia.invoice_amount)=0
		        /*and aia.invoice_id in (select distinct zd1.trx_id
                                    from zx_rec_nrec_dist zd1 , hr_operating_units hou1
                                    where zd1.application_id = 200
                                    and zd1.entity_code = 'AP_INVOICES'
                                    and zd1.recoverable_flag = 'Y'
                                    and zd1.def_rec_settlement_option_code = 'DEFERRED'
                                    and zd1.gl_date <= pd_end_date
                                    and zd1.ledger_id = pv_ledger--PARAMETRE LEDGER_ID
                                    and hou1.organization_id = zd1.internal_organization_id
                                    and hou1.set_of_books_id = zd1.ledger_id
                                    )*/
                 and aid.line_type_lookup_code = 'PREPAY'
                 and aid.accounting_date between pd_start_date and pd_end_date --PARAMETRES DATES
                 group by aid.invoice_id, aia.base_amount, aia.invoice_amount, aia.cancelled_amount
		     ) REGLT
        where zd.application_id = 200
            and zd.entity_code = 'AP_INVOICES'
            and zd.trx_id = ai.invoice_id
            and aid.detail_tax_dist_id = zd.rec_nrec_tax_dist_id
            and zd.recoverable_flag = 'Y'
            and aid.accrual_posted_flag = 'Y'
            and zl.tax_line_id = zd.tax_line_id
            and zl.application_id = 200
            and zl.entity_code = 'AP_INVOICES'
            and gcc.code_combination_id = aid.dist_code_combination_id
            and ven.vendor_id = ai.vendor_id
            and zd.def_rec_settlement_option_code = 'DEFERRED'
            and zd.ledger_id = pv_ledger
            and zd.gl_date <= pd_end_date
            and hou.organization_id = zd.internal_organization_id
            and hou.set_of_books_id = zd.ledger_id
            and REGLT.invoice_id = ai.invoice_id
            and REGLT.invoice_id = zd.trx_id
            and nvl(ai.base_amount, ai.invoice_amount)=0
			and hou.SET_OF_BOOKS_ID = gl.ledger_id
         group by substr(hou.name, 4, 4),
              substr(hou.name, 1, 3),
              UPPER(gl.name),
			  ai.invoice_id,
              zd.def_rec_settlement_option_code,
			  zd.tax_rate_code,
              zd.tax_rate,
			   DKA_RJETVADEDUC_PKG.dka_check_codetva(zd.tax_rate_code ,gcc.segment3,zl.tax_line_id,zl.INTERNAL_ORGANIZATION_ID), ---gcc.segment3---//SFA---artf3039248 : INC0253409----
			  SUBSTR(zd.trx_number,1,20),
			  ai.INVOICE_DATE,
			  nvl(ai.base_amount, ai.invoice_amount),
			  REGLT.amount,
			  REGLT.POURCENTAGE,
			  zl.cancel_flag,
		      zl.orig_taxable_amt,
		      zl.orig_tax_amt
       having ROUND(decode(zl.cancel_flag,'Y', zl.orig_taxable_amt, sum(zd.taxable_amt_funcl_curr)) * REGLT.POURCENTAGE, 2) <> 0

    UNION ALL

       select  substr(hou.name, 4, 4) SOCIETE,
              substr(hou.name, 1, 3) COMPANY_NUM,
              UPPER(gl.name) COMPANY_NAME,
			  ai.invoice_id INVOICE_ID,
              decode(zd.def_rec_settlement_option_code,
                    'IMMEDIATE',
                    'DEB/M',
                    'CRE/M') TAX_TYPE,
			  zd.tax_rate_code CODE_TVA,
              zd.tax_rate TAUX_TVA,
             DKA_RJETVADEDUC_PKG.dka_check_codetva(zd.tax_rate_code ,gcc.segment3,zd.tax_line_id,zd.INTERNAL_ORGANIZATION_ID)CMP,--gcc.segment3 CMP,---//SFA---artf3039248 : INC0253409----récuperation du compte de taxe récupérable
			  SUBSTR(zd.trx_number,1,20) NUM_FACTURE,
			  ai.INVOICE_DATE DATE_FACTURE,
			  nvl(ai.base_amount, ai.invoice_amount) MONTANT_FACTURE_TTC,
			  ROUND(sum(zd.rec_nrec_tax_amt_funcl_curr) * REGLT.POURCENTAGE, 2) MONTANT_TVA_FACT,
			  REGLT.amount PAY_AMT,
			  ROUND(sum(zd.taxable_amt_funcl_curr) * REGLT.POURCENTAGE, 2) AMT_TXBL
       from zx_rec_nrec_dist             zd,
            ap_invoices_all              ai,
            ap_invoice_distributions_all aid,
            gl_code_combinations         gcc,
            ap_suppliers                 ven,
            hr_operating_units           hou,
	        gl_ledgers                   gl,
            (select distinct (aip.invoice_id) INVOICE_ID,
                             sum(aip.amount) AMOUNT,
                             sum(aip.amount) / nvl(aia.base_amount, aia.invoice_amount) POURCENTAGE
            from ap_invoice_payments_all aip,
                    ap_checks_all           ac,
                    ap_invoices_all         aia
            where aip.invoice_id = aia.invoice_id
            and nvl(aia.base_amount, aia.invoice_amount)!=0
            /*and aia.invoice_id in (select distinct zd1.trx_id
                                   from zx_rec_nrec_dist zd1 , hr_operating_units hou1
                                   where zd1.application_id = 200
                                   and zd1.entity_code = 'AP_INVOICES'
                                   and zd1.recoverable_flag = 'Y'
                                   and zd1.def_rec_settlement_option_code = 'DEFERRED'
                                   and zd1.gl_date <= pd_end_date
                                   and zd1.ledger_id = pv_ledger --PARAMETRE LEDGER_ID
                                   and hou1.organization_id = zd1.internal_organization_id
                                   and hou1.set_of_books_id = zd1.ledger_id
                                   )*/
            and aip.check_id = ac.check_id
            and aip.accrual_posted_flag = 'Y'
            and GREATEST(aip.accounting_date,nvl(ac.future_pay_due_date, aip.accounting_date),aip.accounting_date) between pd_start_date and pd_end_date --PARAMETRES DATES
            group by aip.invoice_id,
                     aia.base_amount,
                     aia.invoice_amount,
                     aia.cancelled_amount --ASD
            UNION ALL
            select distinct (aid.invoice_id) INVOICE_ID,
                            -sum(nvl(aid.base_amount, aid.amount)) AMOUNT,
                            -sum(nvl(aid.base_amount, aid.amount)) / nvl(aia.base_amount, aia.invoice_amount) POURCENTAGE
            from ap_invoices_all aia, ap_invoice_distributions_all aid
            where aia.invoice_id = aid.invoice_id
            and nvl(aia.base_amount, aia.invoice_amount)!=0 --AAAAAA
            /*and aia.invoice_id in (select distinct zd1.trx_id
                                  from zx_rec_nrec_dist zd1 , hr_operating_units hou1
                                  where zd1.application_id = 200
                                  and zd1.entity_code = 'AP_INVOICES'
                                  and zd1.recoverable_flag = 'Y'
                                  and zd1.def_rec_settlement_option_code = 'DEFERRED'
                                  and zd1.gl_date <= pd_end_date
                                  and zd1.ledger_id = pv_ledger --PARAMETRE LEDGER_ID
                                  and hou1.organization_id = zd1.internal_organization_id
                                  and hou1.set_of_books_id = zd1.ledger_id
                                  )*/
            and aid.line_type_lookup_code = 'PREPAY'
            and aid.accounting_date between pd_start_date and pd_end_date --PARAMETRES DATES
            group by aid.invoice_id,
                      aia.base_amount,
                      aia.invoice_amount,
                      aia.cancelled_amount
	        ) REGLT --ASD
        where zd.application_id = 200
        and zd.entity_code = 'AP_INVOICES'
        and zd.trx_id = ai.invoice_id
        and aid.detail_tax_dist_id = zd.rec_nrec_tax_dist_id
        and zd.recoverable_flag = 'Y'
        and aid.accrual_posted_flag = 'Y'
        and gcc.code_combination_id = aid.dist_code_combination_id
        and ven.vendor_id = ai.vendor_id
        and zd.def_rec_settlement_option_code = 'DEFERRED'
        and zd.ledger_id = pv_ledger --PARAMETRE LEDGER_ID
        and zd.gl_date <= pd_end_date --PARAMETRE DATE
        and hou.organization_id = zd.internal_organization_id
        and hou.set_of_books_id = zd.ledger_id
        and REGLT.invoice_id = ai.invoice_id
        and REGLT.invoice_id = zd.trx_id
        and nvl(ai.base_amount, ai.invoice_amount)!=0
	    and hou.SET_OF_BOOKS_ID = gl.ledger_id
        group by substr(hou.name, 4, 4),
              substr(hou.name, 1, 3),
              UPPER(gl.name),
			  ai.invoice_id,
              zd.def_rec_settlement_option_code,
			  zd.tax_rate_code,
              zd.tax_rate,
			  DKA_RJETVADEDUC_PKG.dka_check_codetva(zd.tax_rate_code ,gcc.segment3,zd.tax_line_id,zd.INTERNAL_ORGANIZATION_ID),  ---gcc.segment3 ---//SFA---artf3039248 : INC0253409----
			  SUBSTR(zd.trx_number,1,20),
			  ai.INVOICE_DATE,
			  nvl(ai.base_amount, ai.invoice_amount),
              REGLT.amount,
              REGLT.POURCENTAGE
        having ROUND(sum(zd.taxable_amt_funcl_curr) * REGLT.POURCENTAGE, 2) <> 0
		--> OBE artf2825776
        )

    ---------------------------------------------Boucle principale--------------------------------------------
    -- On parcourt les lignes du curseur a l'aide d'une boucle

    ---------------------------------------------Boucle principale--------------------------------------------

    ----------------- CRE/M -----------------
     LOOP

      BEGIN
        --2

        Dka_Tools_Pkg.put_debug_message('MSG-00020: ' ||
                                        rpad(rec.societe, 10) || ' * ' ||
                                        rpad(rec.company_num, 8) || ' * ' ||
                                        rpad(rec.code_tva, 8) || ' * ' ||
                                        rpad(rec.Num_facture, 10) || ' * ' ||
                                        rpad(rec.date_facture, 12) ||
                                        ' * ' || rpad(rec.AMT_TXBL, 10) ||
                                        ' * ' || rpad(rec.MONTANT_TVA_FACT,--MONTANT_TVA_PAR_CODE_TVA,
                                                      10) || ' * ' ||
                                        rpad(rec.MONTANT_FACTURE_TTC, 10) ||
                                        ' * ' || rpad(rec.AMT_TXBL, 10) ||
                                        ' * ' || rpad(rec.PAY_AMT, 10) ||
                                        ' * ' || rpad('OK', 3));

        BEGIN
          --3
          INSERT INTO DKA_RJETVADEDUC_CRE
            (REQUEST_ID,
             SOCIETE,
             COMPANY_NUM,
             COMPANY_NAME,
             FACTURE_DATE,
             FACTURE_ID,
             FACTURE_NUM,
             COMPTE,
             TAUX_TVA,
             TYPE_TVA,
             AMOUNT_HT,
             TVA,
             REGLE_PER,
             MONT_ASSUJET,
             TVA_RECUPERABLE)
          VALUES
            (cre_request_id,
             rec.societe,
             rec.company_num,
             rec.company_name,
             rec.date_facture,
             rec.invoice_id,
             rec.Num_facture,
             rec.cmp,
             rec.taux_tva,
             rec.tax_type,
             rec.AMT_TXBL,
             rec.MONTANT_TVA_FACT,
             rec.PAY_AMT,
             rec.AMT_TXBL,--MONTANT_ASSUJ,
             rec.MONTANT_TVA_FACT --MONTANT_TVA_PAR_CODE_TVA -- MSL (++)
             );

        EXCEPTION
          WHEN OTHERS THEN
            Dka_Tools_Pkg.put_debug_message('MSG-00030: *** erreur ES03: une erreur est survenue pendant l insertion dans la table DKA_RJETVADEDUC_CRE');
            Dka_Tools_Pkg.put_debug_message('MSG-00030: *** erreur ES03 invoice_id: ' ||
                                            rec.invoice_id || ' tva :' ||
                                            rec.code_tva);
            Dka_Tools_Pkg.put_debug_message('MSG-00030: *** erreur ES03 ' ||
                                            sqlerrm || ' ' || sqlcode);
            pn_retcode := 2;
            pv_errbuf  := SQLERRM;
        END; --3
      END; --2
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := SQLERRM;

  END calcul_tva_cre; -- 1

  -----------------------------------------------------------------
  -- NOM         : calcul_tva_deb
  -- DESCRIPTION : Alimentation de la table DKA_RJETVADEDUC_DEB
  -----------------------------------------------------------------
  PROCEDURE calcul_tva_deb(deb_request_id IN NUMBER,
                           --pv_societe           IN      VARCHAR2,
                           --pv_region            IN      VARCHAR2,
                           pv_uo IN VARCHAR2,
                           --pv_dka_company_num   IN      VARCHAR2,
                           pv_ledger     IN VARCHAR2,
                           pd_start_date IN DATE,
                           pd_end_date   IN DATE,
                           Pv_Debug_Mode IN VARCHAR2,
                           pv_errbuf     IN OUT VARCHAR2,
                           pn_retcode    OUT NUMBER

                           ) IS

  BEGIN
    -- 1

    pn_retcode := 0;
    pv_errbuf  := NULL;

    --------------------------------------------------------------
    -- Suppression des données de tous les traitements terminés --
    --------------------------------------------------------------
    IF Pv_Debug_Mode = 'N' THEN
      Dka_Tools_Pkg.Put_Debug_Message('Suppression des données des traitements précédents');

      DELETE FROM DKA_RJETVADEDUC_DEB Deb
       WHERE EXISTS
       (SELECT 'X'
                FROM Fnd_Concurrent_Requests Fcr,
                     Fnd_Concurrent_Programs Fcp
               WHERE Fcr.Concurrent_Program_Id = Fcp.Concurrent_Program_Id
                 AND Fcr.Phase_Code = 'C'
                 AND Fcp.Concurrent_Program_Name = 'DKA_RJETVADEDUC'
                 AND Fcr.Request_Id = Deb.Request_Id);

      COMMIT;

      Dka_Tools_Pkg.Put_Debug_Message('==> ' || SQL%ROWCOUNT ||
                                      ' enregistrements supprimés de la table DKA_RJETVADEDUC_DEB.');

    END IF;

    Dka_Tools_Pkg.put_debug_message('----------------- Insertion ligne pour TVA DEB/M -----------------');
    Dka_Tools_Pkg.put_debug_message(rpad('SOCIETE', 8) || ' * ' ||
                                    rpad('COMPANY', 8) || ' * ' ||
                                    rpad('CODE_TVA', 8) || ' * ' ||
                                    rpad('FACTU_NUM', 10) || ' * ' ||
                                    rpad('FACTURE_DATE', 12) || ' * ' ||
                                    rpad('PAR_DIST', 10) || ' * ' ||
                                    rpad('PART_TVA', 10) || ' * ' ||
                                    rpad('PART_REGL', 10) || ' * ' ||
                                    rpad('MONT_IMPOS', 10) || ' * ' ||
                                    rpad('TVA_RECUP', 10) || ' * ' ||
                                    rpad('KO', 3));

    FOR rec IN (/*SELECT --CC_C.SEGMENT1 SOCIETE,-- RGH
                --GCC_C.SEGMENT2 COMPANY_NUM,    -- RGH
                --UPPER(FFV2.DESCRIPTION) || UPPER(FFV.DESCRIPTION) COMPANY_NAME,-- RGH
                 substr(hou.name, 4, 4) SOCIETE,
                 substr(hou.name, 1, 3) COMPANY_NUM,
                 UPPER(gl.name) || UPPER(FFV.DESCRIPTION) COMPANY_NAME,
                 INV.INVOICE_ID INVOICE_ID,
                 --TAX.TAX_TYPE TAX_TYPE,-- RGH
                 --TAX.NAME CODE_TVA,-- RGH
                 --TAX.TAX_RATE TAUX_TVA,-- RGH
                 zrca.reporting_code_char_value TAX_TYPE,
                 zrb.tax_rate_code CODE_TVA,
                 zrb.percentage_rate TAUX_TVA,
                 GCC_TVA.SEGMENT3 CMP,
                 SUBSTR(INV.INVOICE_NUM, 1, 20) NUM_FACTURE,
                 INV.INVOICE_DATE DATE_FACTURE,
                 DECODE(zrca.reporting_code_char_value,
                        'OFFSET',
                        0,
                        NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT)) MONTANT_FACTURE_TTC, --TAX.TAX_TYPE-- RGH
                 ROUND(DECODE(DIS.TAX_RECOVERABLE_FLAG,
                              'Y',
                              SUM(NVL(DIS.BASE_AMOUNT, DIS.AMOUNT)) *
                              NVL(DIS.TAX_RECOVERY_RATE,
                                  NVL((select PERCENTAGE_RATE
                                        from ZX_RATES_B
                                       where RATE_TYPE_CODE = 'RECOVERY'
                                         and tax = zrb.tax),
                                      100)) / 100,
                              0),
                       2) MONTANT_TVA_PAR_CODE_TVA, -- REC.RECOVERY_RATE --RGH
                 0 PAY_AMT,
                   DECODE(zrca.reporting_code_char_value,
                        'OFFSET',
                        0,(SELECT SUM(TAXABLE_AMT)
                           FROM  zx_lines
                          WHERE TAX_RATE_ID = ail.TAX_RATE_ID
                            AND application_id = 200
                            AND entity_code = 'AP_INVOICES'
                            AND trx_id = inv.Invoice_Id)) AMT_TXBL --YWA artf2210584
                  FROM AP_INVOICES              INV,
                       AP_INVOICE_DISTRIBUTIONS DIS,
                       ap_invoice_lines         ail,
                       --AP_TAX_CODES           TAX,
                       --AP_TAX_RECVRY_RATES    REC,
                       ZX_REPORT_CODES_ASSOC zrca, -- RGH
                       ZX_RATES_B            zrb, -- RGH
                       ZX_ACCOUNTS           za, -- RGH
                       GL_CODE_COMBINATIONS  GCC_TVA,
                       --GL_CODE_COMBINATIONS   GCC_C,
                       FND_FLEX_VALUES_VL  FFV,
                       FND_FLEX_VALUE_SETS FFVS,
                       --FND_FLEX_VALUES_VL     FFV2,
                       --FND_FLEX_VALUE_SETS    FFVS2
                       hr_operating_units hou, -- RGH
                       gl_ledgers         gl -- RGH
                 WHERE INV.INVOICE_ID = DIS.INVOICE_ID
                      --  DPE20140051 - Gestion des Types de TVA sur débits par les Codes express "TAX TYPE".
                      -- AND tax.tax_type IN ('DEB/M','INTRACOMMUNAUTAIRE', 'OFFSET')
                   AND DIS.POSTED_FLAG || '' = 'Y'
                   AND DIS.MATCH_STATUS_FLAG IS NOT NULL
                   AND FFV.FLEX_VALUE_SET_ID = FFVS.FLEX_VALUE_SET_ID
                   AND GCC_TVA.CODE_COMBINATION_ID =
                       dis.dist_code_combination_id
                   AND dis.invoice_line_number                 = ail.line_number --YWA artf2210584
                   AND dis.accounting_date BETWEEN pd_start_date AND
                       pd_end_date
                      --- Début modifs RGH
                   and INV.INVOICE_ID = ail.invoice_id
                   and FFVS.FLEX_VALUE_SET_NAME = pv_uo
                   and FFV.FLEX_VALUE = substr(hou.name, 1, 3)
                   and hou.SET_OF_BOOKS_ID = gl.ledger_id
                   and ail.line_type_lookup_code = 'TAX'
                   and zrca.ENTITY_ID = za.tax_account_entity_id
                   and zrb.tax_rate_id = zrca.ENTITY_ID
                   and ail.tax_rate_id = zrca.ENTITY_ID
                   and zrca.entity_code = 'ZX_RATES'
                   and za.tax_account_entity_code = 'RATES'
                   and ail.org_id = za.internal_organization_id
                   and zrca.reporting_code_char_value != 'CRE/M'
                   and hou.SET_OF_BOOKS_ID = ail.set_of_books_id
                   and hou.SET_OF_BOOKS_ID = pv_ledger
                   and hou.organization_id = ail.org_id
                   and inv.org_id = ail.org_id
                   --- 07/09/2017 NBO artf2210584 : ETA057 - Déclaration de la TVA déductible - Etat à revoir - defect ORACLE_R12 #802
                   and inv.org_id = dis.org_id

                 GROUP BY --GCC_C.SEGMENT1,
                          --GCC_C.SEGMENT2,
                           substr(hou.name, 4, 4),
                          substr(hou.name, 1, 3),
                          INV.INVOICE_ID,
                          --UPPER(FFV2.DESCRIPTION) || UPPER(FFV.DESCRIPTION),
                          UPPER(gl.name) || UPPER(FFV.DESCRIPTION),
                          --TAX.TAX_TYPE,
                          --TAX.NAME,
                          --TAX.TAX_RATE,
                          zrca.reporting_code_char_value,
                          zrb.tax_rate_code,
                          zrb.percentage_rate,
                          zrb.tax,
                          GCC_TVA.SEGMENT3,
                          SUBSTR(INV.INVOICE_NUM, 1, 20),
                          INV.INVOICE_DATE,
                          NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT),
                          DIS.TAX_RECOVERABLE_FLAG,
                          DIS.TAX_RECOVERY_RATE,
                          --REC.RECOVERY_RATE,
                          DIS.LINE_TYPE_LOOKUP_CODE,
                          DIS.INVOICE_ID,
                          DIS.TAX_CODE_ID,
                          DIS.BASE_AMOUNT,
                          ail.TAX_RATE_ID

                HAVING ROUND(DECODE(DIS.TAX_RECOVERABLE_FLAG, 'Y', SUM(NVL(DIS.BASE_AMOUNT, DIS.AMOUNT)) * NVL(DIS.TAX_RECOVERY_RATE, NVL((select PERCENTAGE_RATE
                                                                                                                                            from ZX_RATES_B
                                                                                                                                           where RATE_TYPE_CODE = 'RECOVERY'
                                                                                                                                             and tax =  zrb.tax), 100)) / 100, 0), 2) <> 0 --(BUG 1055480)

                UNION ALL
                SELECT --GCC_C.SEGMENT1 SOCIETE,
                --GCC_C.SEGMENT2 COMPANY_NUM,
                --UPPER(FFV2.DESCRIPTION) || UPPER(FFV.DESCRIPTION) COMPANY_NAME,
                 substr(hou.name, 4, 4) SOCIETE,
                 substr(hou.name, 1, 3) COMPANY_NUM,
                 UPPER(gl.name) || UPPER(FFV.DESCRIPTION) COMPANY_NAME,
                 INV.INVOICE_ID INVOICE_ID,
                 --TAX.TAX_TYPE                      TAX_TYPE,
                 --TAX.NAME               CODE_TVA,
                 --TAX.TAX_RATE                        TAUX_TVA,
                 zrca.reporting_code_char_value TAX_TYPE,
                 zrb.tax_rate_code              CODE_TVA,
                 zrb.percentage_rate            TAUX_TVA,

                 GCC_TVA.SEGMENT3 CMP,
                 SUBSTR(INV.INVOICE_NUM, 1, 20) NUM_FACTURE,
                 INV.INVOICE_DATE DATE_FACTURE,
                 0 MONTANT_FACTURE_TTC,
                 ROUND(DECODE(DIS.TAX_RECOVERABLE_FLAG,
                              'Y',
                              SUM(NVL(DIS.BASE_AMOUNT, DIS.AMOUNT) /
                                  NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT) *
                                  AIP.DISCOUNT_LOST) *
                              NVL(DIS.TAX_RECOVERY_RATE,
                                  NVL((select PERCENTAGE_RATE
                                        from ZX_RATES_B
                                       where RATE_TYPE_CODE = 'RECOVERY'
                                         and tax = zrb.tax),
                                      100)) / 100,
                              0),
                       2) MONTANT_TVA_PAR_CODE_TVA,
                 0 PAY_AMT,
                   DECODE(zrca.reporting_code_char_value,
                        'OFFSET',
                        0,(SELECT SUM(TAXABLE_AMT)
                           FROM  zx_lines
                          WHERE TAX_RATE_ID = ail.TAX_RATE_ID
                            AND application_id = 200
                            AND entity_code = 'AP_INVOICES'
                            AND trx_id = inv.Invoice_Id)) AMT_TXBL --YWA artf2210584


                  FROM AP_INVOICES              INV,
                       AP_INVOICE_DISTRIBUTIONS DIS,
                       ap_invoice_lines         ail,
                       --AP_TAX_CODES           TAX,
                       --AP_TAX_RECVRY_RATES    REC,
                       ZX_REPORT_CODES_ASSOC zrca, -- RGH
                       ZX_RATES_B            zrb, -- RGH
                       ZX_ACCOUNTS           za, -- RGH
                       GL_CODE_COMBINATIONS  GCC_TVA,
                       --GL_CODE_COMBINATIONS   GCC_C,
                       FND_FLEX_VALUES_VL  FFV,
                       FND_FLEX_VALUE_SETS FFVS,
                       --FND_FLEX_VALUES_VL     FFV2,
                       --FND_FLEX_VALUE_SETS    FFVS2
                       hr_operating_units  hou, -- RGH
                       gl_ledgers          gl, -- RGH
                       AP_CHECKS           CHK,
                       AP_INVOICE_PAYMENTS AIP

                 WHERE INV.INVOICE_ID = DIS.INVOICE_ID
                   AND AIP.INVOICE_ID = INV.INVOICE_ID
                   AND chk.check_id = aip.check_id
                   AND DIS.POSTED_FLAG || '' = 'Y'
                      --  DPE20140051 - Gestion des Types de TVA sur débits par les Codes express "TAX TYPE".
                      --  AND  tax.tax_type IN ('DEB/M','INTRACOMMUNAUTAIRE', 'OFFSET') -- Modif TB 03/05/07
                   AND DIS.MATCH_STATUS_FLAG IS NOT NULL
                   AND dis.invoice_line_number                 = ail.line_number --YWA artf2210584

                   AND FFV.FLEX_VALUE_SET_ID = FFVS.FLEX_VALUE_SET_ID
                   AND aip.accounting_date BETWEEN pd_start_date AND
                       pd_end_date
                   AND NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT) <> 0
                      --- Début modifs RGH
                   and INV.INVOICE_ID = ail.invoice_id
                   and FFVS.FLEX_VALUE_SET_NAME = pv_uo
                   and FFV.FLEX_VALUE = substr(hou.name, 1, 3)
                   and hou.SET_OF_BOOKS_ID = gl.ledger_id
                   and ail.line_type_lookup_code = 'TAX'
                   and zrca.ENTITY_ID = za.tax_account_entity_id
                   and zrb.tax_rate_id = zrca.ENTITY_ID
                   and ail.tax_rate_id = zrca.ENTITY_ID
                   and zrca.entity_code = 'ZX_RATES'
                   and za.tax_account_entity_code = 'RATES'
                   and ail.org_id = za.internal_organization_id
                   and zrca.reporting_code_char_value != 'CRE/M'
                   and hou.SET_OF_BOOKS_ID = ail.set_of_books_id
                   and hou.SET_OF_BOOKS_ID = pv_ledger
                   and hou.organization_id = ail.org_id
                   and inv.org_id = ail.org_id
                   --- 07/09/2017 NBO artf2210584 : ETA057 - Déclaration de la TVA déductible - Etat à revoir - defect ORACLE_R12 #802
                   and inv.org_id = dis.org_id
                   and GCC_TVA.code_combination_id =
                       dis.dist_code_combination_id

                 GROUP BY --GCC_C.SEGMENT1,
                          --GCC_C.SEGMENT2,
                           substr(hou.name, 4, 4),
                          substr(hou.name, 1, 3),
                          INV.INVOICE_ID,
                          --UPPER(FFV2.DESCRIPTION) || UPPER(FFV.DESCRIPTION),
                          UPPER(gl.name) || UPPER(FFV.DESCRIPTION),
                          --TAX.TAX_TYPE,
                          --TAX.NAME,
                          --TAX.TAX_RATE,
                          zrca.reporting_code_char_value,
                          zrb.tax_rate_code,
                          zrb.percentage_rate,
                          zrb.tax,
                          GCC_TVA.SEGMENT3,
                          SUBSTR(INV.INVOICE_NUM, 1, 20),
                          INV.INVOICE_DATE,
                          NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT),
                          DIS.TAX_RECOVERABLE_FLAG,
                          DIS.TAX_RECOVERY_RATE,
                          DIS.TAX_CODE_ID,
                          --REC.RECOVERY_RATE,
                          DIS.LINE_TYPE_LOOKUP_CODE,
                          DIS.INVOICE_ID,
                          DIS.BASE_AMOUNT,
                          ail.TAX_RATE_ID
                HAVING SUM(NVL(dis.base_amount, dis.amount) / NVL(inv.base_amount, inv.invoice_amount) * aip.discount_lost) < 0
                 AND ROUND(DECODE(dis.tax_recoverable_flag, 'Y', SUM(NVL(dis.base_amount, dis.amount) / NVL(inv.base_amount, inv.invoice_amount) * aip.discount_lost) * NVL(dis.tax_recovery_rate,
                 NVL(( select PERCENTAGE_RATE
                         from ZX_RATES_B
                        where RATE_TYPE_CODE =
                              'RECOVERY'
                          and tax =
                              zrb.tax), 100)) / 100, 0), 2) <> 0 -- (Bug 1055480)

          UNION ALL

           SELECT substr(hou.name, 4, 4) societe,
                  substr(hou.name, 1, 3) company_num,
                  UPPER(gl.name) || UPPER(ffv.description) company_name,
                  inv.invoice_id invoice_id,
                  zrca.reporting_code_char_value tax_type,
                  zl.tax_rate_code code_tva,
                  zl.tax_rate taux_tva,
                  cc.segment3 cmp,
                  SUBSTR(inv.invoice_num, 1, 20) num_facture,
                  inv.invoice_date date_facture,
                  DECODE(zrca.reporting_code_char_value, 'OFFSET', 0, nvl(inv.base_amount, inv.invoice_amount)) montant_facture_ttc,
                  SUM(ROUND(DECODE(aid.tax_recoverable_flag, 'Y', zl.tax_amt, 0), 2)) tax_amt,
                  0 PAY_AMT,
                  SUM(zl.taxable_amt) amt_txbl
             FROM ap_suppliers             ven,
                  ap_invoices              inv,
                  ap_invoice_lines         ail,
                  ap_invoice_distributions aid,
                  zx_lines_v               zl,
                  hr_operating_units       hou,
                  gl_code_combinations     cc,
                  ZX_RATES_B               zrb,
                  ZX_REPORT_CODES_ASSOC    zrca,
                  FND_FLEX_VALUES_VL       ffv,
                  FND_FLEX_VALUE_SETS      ffvs,
                  gl_ledgers               gl
            WHERE ven.vendor_id = inv.vendor_id
              AND ail.invoice_id = inv.invoice_id
              AND ail.invoice_id = zl.trx_id
              AND ail.line_number = zl.trx_line_id
              AND ail.set_of_books_id = hou.set_of_books_id
              AND cc.code_combination_id = aid.dist_code_combination_id
              AND inv.invoice_id = aid.invoice_id
              AND ail.line_number = aid.invoice_line_number
              AND zrb.tax_rate_id = zrca.ENTITY_ID
              and inv.org_id = ail.org_id
              AND zrca.entity_code = 'ZX_RATES'
              AND aid.posted_flag || '' = 'Y'
              AND NVL(inv.base_amount, inv.invoice_amount) <> 0
              AND aid.match_status_flag IS NOT NULL
              AND aid.line_type_lookup_code = 'REC_TAX'
              AND zrb.tax_rate_id = aid.tax_code_id
              AND zrca.reporting_code_char_value != 'CRE/M'
              AND zl.cancel_flag = 'N'
              AND NVL(aid.reversal_flag, 'N') = 'N'
              AND ail.accounting_date BETWEEN pd_start_date AND pd_end_date
              AND hou.SET_OF_BOOKS_ID = pv_ledger
              AND hou.organization_id = ail.org_id
              AND zl.entity_code = 'AP_INVOICES'
              AND ffv.flex_value_set_id = ffvs.flex_value_set_id
              AND ffvs.flex_value_set_name = pv_uo
              AND ffv.flex_value = substr(hou.name, 1, 3)
              AND hou.SET_OF_BOOKS_ID = gl.ledger_id
            GROUP BY substr(hou.name, 4, 4),
                     substr(hou.name, 1, 3),
                     UPPER(gl.name) || UPPER(ffv.description),
                     inv.invoice_id,
                     zrca.reporting_code_char_value,
                     zl.tax_rate_code,
                     zl.tax_rate,
                     cc.segment3,
                     SUBSTR(inv.invoice_num, 1, 20),
                     inv.invoice_date,
                     DECODE(zrca.reporting_code_char_value, 'OFFSET', 0, nvl(inv.base_amount, inv.invoice_amount))
          */

            select substr(hou.name, 4, 4) SOCIETE,
                   substr(hou.name, 1, 3) COMPANY_NUM,
			       UPPER(gl.name) COMPANY_NAME,
				   ai.INVOICE_ID INVOICE_ID,
			       decode(zd.def_rec_settlement_option_code,'IMMEDIATE','DEB/M','CRE/M') TAX_TYPE,
				   zd.tax_rate_code CODE_TVA,
                   zd.tax_rate TAUX_TVA,
                   DKA_RJETVADEDUC_PKG.dka_check_codetva(zd.tax_rate_code ,gcc.segment3,zd.tax_line_id,zd.INTERNAL_ORGANIZATION_ID)CMP,--gcc.segment3 CMP,---//SFA---artf3039248 : INC0253409----récuperation du compte de taxe récupérable
				   SUBSTR(zd.trx_number,1,20) NUM_FACTURE,
				   ai.INVOICE_DATE DATE_FACTURE,
				   nvl(ai.base_amount, ai.invoice_amount) MONTANT_FACTURE_TTC,
				   sum(zd.rec_nrec_tax_amt_funcl_curr) MONTANT_TVA_PAR_CODE_TVA,
				   0 PAY_AMT,
				   sum(zd.taxable_amt_funcl_curr) AMT_TXBL
              from zx_rec_nrec_dist zd,
                   ap_invoices_all ai,
                   ap_invoice_distributions_all aid,
                   gl_code_combinations gcc,
                   ap_suppliers ven,
                   hr_operating_units hou,
				   gl_ledgers         gl
            where zd.application_id = 200
               and zd.entity_code = 'AP_INVOICES'
               and zd.trx_id = ai.invoice_id
               and aid.detail_tax_dist_id = zd.rec_nrec_tax_dist_id
               and zd.recoverable_flag ='Y'
               and aid.accrual_posted_flag = 'Y'
               and gcc.code_combination_id = aid.dist_code_combination_id
               and ven.vendor_id = ai.vendor_id
               and zd.def_rec_settlement_option_code ='IMMEDIATE'
               and zd.ledger_id = pv_ledger
               and zd.gl_date between pd_start_date and pd_end_date
               and hou.organization_id = zd.internal_organization_id
               and hou.set_of_books_id = zd.ledger_id
			   and hou.SET_OF_BOOKS_ID = gl.ledger_id
            group by substr(hou.name, 4, 4),
                   substr(hou.name, 1, 3),
			       UPPER(gl.name),
				   ai.INVOICE_ID,
			       zd.def_rec_settlement_option_code,
				   zd.tax_rate_code,
                   zd.tax_rate,
				   DKA_RJETVADEDUC_PKG.dka_check_codetva(zd.tax_rate_code ,gcc.segment3,zd.tax_line_id,zd.INTERNAL_ORGANIZATION_ID), ---gcc.segment3, ---//SFA---artf3039248 : INC0253409----
				   SUBSTR(zd.trx_number,1,20),
				   ai.INVOICE_DATE,
				   nvl(ai.base_amount, ai.invoice_amount)
            having sum(zd.taxable_amt_funcl_curr)<>0
		  )

    ---------------------------------------------Boucle principale--------------------------------------------
    -- On parcourt les lignes du curseur a l'aide d'une boucle

    ---------------------------------------------Boucle principale--------------------------------------------

    ----------------- DEB/M -----------------
     LOOP

      BEGIN
        --2

        Dka_Tools_Pkg.put_debug_message('MSG-00020: Insertion:          ');
        Dka_Tools_Pkg.put_debug_message('MSG-00020: ' ||
                                        rpad(rec.societe, 10) || ' * ' ||
                                        rpad(rec.company_num, 8) || ' * ' ||
                                        rpad(rec.code_tva, 8) || ' * ' ||
                                        rpad(rec.Num_facture, 10) || ' * ' ||
                                        rpad(rec.date_facture, 12) ||
                                        ' * ' || rpad(rec.AMT_TXBL, 10) ||
                                        ' * ' || rpad(rec.MONTANT_TVA_PAR_CODE_TVA,
                                                      10) || ' * ' ||
                                        rpad(rec.MONTANT_FACTURE_TTC, 10) ||
                                        ' * ' || rpad(rec.AMT_TXBL, 10) ||
                                        ' * ' || rpad(rec.PAY_AMT, 10) ||
                                        ' * ' || rpad('OK', 3));

        BEGIN
          --3
          INSERT INTO DKA_RJETVADEDUC_DEB
            (REQUEST_ID,
             SOCIETE,
             COMPANY_NUM,
             COMPANY_NAME,
             FACTURE_DATE,
             FACTURE_ID,
             FACTURE_NUM,
             COMPTE,
             TAUX_TVA,
             TYPE_TVA,
             AMOUNT_HT,
             TVA,
             REGLE_PER,
             MONT_ASSUJET,
             TVA_RECUPERABLE)
          VALUES
            (deb_request_id,
             rec.societe,
             rec.company_num,
             rec.company_name,
             rec.date_facture,
             rec.invoice_id,
             rec.Num_facture,
             rec.cmp,
             rec.taux_tva,
             rec.tax_type,
             rec.AMT_TXBL,
             rec.MONTANT_TVA_PAR_CODE_TVA,
             rec.PAY_AMT,
             rec.AMT_TXBL,
             rec.MONTANT_TVA_PAR_CODE_TVA -- MSL (++)
             );

        EXCEPTION
          WHEN OTHERS THEN
            Dka_Tools_Pkg.put_debug_message('MSG-00030: *** erreur ES03: une erreur est survenue pendant l insertion dans la table DKA_RJETVADEDUC_DEB');
            Dka_Tools_Pkg.put_debug_message('MSG-00030: *** erreur ES03 invoice_id: ' ||
                                            rec.invoice_id || ' tva :' ||
                                            rec.code_tva);
            Dka_Tools_Pkg.put_debug_message('MSG-00030: *** erreur ES03 ' ||
                                            sqlerrm || ' ' || sqlcode);
            pn_retcode := 2;
            pv_errbuf  := SQLERRM;
        END; --3
      END; --2
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := SQLERRM;

  END calcul_tva_DEB; -- 2

  ----------------------------------------------------------------------------------------------------
  -- NOM         : dka_check_codetva
  -- DESCRIPTION : //SFA---artf3039248 : INC0253409 - Modification champ Etats de TVA déductible
  ----------------------------------------------------------------------------------------------------
 ---// 
   function dka_check_codetva( p_tax_rate_code         varchar2,
                              p_compte1                varchar2,
                              p_tax_line_id            number ,
                              p_organization_id        number )
     return varchar2
     as
       l_compte gl_code_combinations.segment3%type;
		begin
		    if  (p_tax_rate_code like 'DED%IE'  or p_tax_rate_code like 'DED%E') then
               BEGIN
                   select segment3 into l_compte from gl_code_combinations
                   where code_combination_id in (select rate_tax_account_ccid from ZX_JRNL_ACCOUNTS_EXTRACT_V
                   --- 02/01/2019 NBO Optimisation problème de perf en production
                                                    where tax_line_id =p_tax_line_id and organization_id =p_organization_id and rownum=1);

               EXCEPTION
               WHEN OTHERS THEN
                    l_compte := p_compte1;
               END;

		    else
		       l_compte := p_compte1;
		    end if;
     return l_compte;
   end dka_check_codetva;
---//

END DKA_RJETVADEDUC_PKG; -- PACKAGE BODY
/
SHOW ERRORS
EXIT;
