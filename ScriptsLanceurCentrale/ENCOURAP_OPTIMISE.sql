WITH
    -- 1. Périmètre des factures ouvertes (évite de scanner tout l'historique R12)
    FACTURES_OUVERTES AS (
        SELECT /*+ MATERIALIZE */ DISTINCT
               API.INVOICE_ID,
               API.VENDOR_ID,
               API.ORG_ID,
               API.VENDOR_SITE_ID,
               API.CREATION_DATE,
               API.INVOICE_AMOUNT,
               API.PAYMENT_STATUS_FLAG,
               API.INVOICE_TYPE_LOOKUP_CODE
          FROM AP_INVOICES_ALL API
          JOIN AP_PAYMENT_SCHEDULES_ALL APPSA
            ON API.INVOICE_ID = APPSA.INVOICE_ID
         WHERE APPSA.AMOUNT_REMAINING <> 0
           AND API.SOURCE <> 'SURTAXE'
    ),
    -- 2. Calcul des statuts PL/SQL (exécuté 1 seule fois par INVOICE_ID au lieu de 2 fois par ligne)
    STATUTS_FACTURE AS (
        SELECT FO.INVOICE_ID,
               AP_INVOICES_PKG.GET_POSTING_STATUS (FO.INVOICE_ID) AS COMPTA,
               AP_INVOICES_PKG.GET_APPROVAL_STATUS (
                   FO.INVOICE_ID,
                   FO.INVOICE_AMOUNT,
                   FO.PAYMENT_STATUS_FLAG,
                   FO.INVOICE_TYPE_LOOKUP_CODE
               ) AS STATUT_VALIDATION,
               AP_INVOICES_PKG.SELECTED_FOR_PAYMENT_FLAG (FO.INVOICE_ID) AS SEL_PMT_FLAG
          FROM FACTURES_OUVERTES FO
    ),
    -- 3. Pré-agrégation des blocages en une seule lecture de AP_HOLDS_ALL
    HOLDS_SUMMARY AS (
        SELECT AHA.INVOICE_ID,
               COUNT (CASE WHEN AHA.RELEASE_REASON IS NULL THEN 1 END) AS NB_BLOCAGES_RESTANTS,
               COUNT (CASE WHEN AHA.RELEASE_REASON IS NULL AND AHA.ATTRIBUTE4 = 'Y' THEN 1 END) AS NB_BLOCAGES_IVALUA_RESTANTS,
               COUNT (CASE WHEN AHA.RELEASE_REASON IS NULL AND AHA.HOLD_LOOKUP_CODE = 'Blocage Fres Affact' THEN 1 END) AS NB_BLOCAGES_AFF_RESTANT,
               COUNT (CASE WHEN AHA.HOLD_LOOKUP_CODE = 'Blocage Fres Affact' THEN 1 END) AS NB_BLOCAGES_AFFACTURAGE,
               MAX (CASE WHEN AHA.RELEASE_REASON IS NULL AND UPPER (AHA.HOLD_LOOKUP_CODE) LIKE '%LITIGE%' THEN 'OUI' ELSE 'NON' END) AS LITIGE_ACTIF,
               MAX (CASE WHEN AHA.RELEASE_REASON IS NULL AND AHA.ATTRIBUTE4 = 'Y' THEN 'OUI' ELSE 'NON' END) AS BLOCAGE_IVALUA_ACTIF,
               COUNT (CASE WHEN AHA.HOLD_LOOKUP_CODE <> 'QTY REC' THEN 1 END) AS NB_HOLDS_NON_QTY_REC,
               COUNT (CASE WHEN AHA.CREATION_DATE <= FO.CREATION_DATE + 0.5 THEN 1 END) AS NB_HOLDS_CREATION_12H,
               MAX (CASE WHEN AHA.RELEASE_LOOKUP_CODE IS NOT NULL THEN AHA.LAST_UPDATE_DATE END) AS MAX_RELEASE_DATE
          FROM FACTURES_OUVERTES FO
          JOIN AP_HOLDS_ALL AHA
            ON AHA.INVOICE_ID = FO.INVOICE_ID
         GROUP BY AHA.INVOICE_ID
    ),
    -- 4. Somme des distributions sur les seules factures ouvertes
    DIST_SUMMARY AS (
        SELECT APID1.INVOICE_ID,
               SUM (APID1.AMOUNT) AS TOTAL_LIGNES
          FROM FACTURES_OUVERTES FO
          JOIN AP_INVOICE_DISTRIBUTIONS_ALL APID1
            ON APID1.INVOICE_ID = FO.INVOICE_ID
         GROUP BY APID1.INVOICE_ID
    ),
    -- 5. Comptage de toutes les échéances (payées ou non) pour l'étalement échéancier
    SCHED_SUMMARY AS (
        SELECT APPSA3.INVOICE_ID,
               CASE WHEN COUNT (*) > 1 THEN 'OUI' ELSE 'NON' END AS ETALEMENT_ECHEANCIER
          FROM FACTURES_OUVERTES FO
          JOIN AP_PAYMENT_SCHEDULES_ALL APPSA3
            ON APPSA3.INVOICE_ID = FO.INVOICE_ID
         GROUP BY APPSA3.INVOICE_ID
    ),
    -- 6. Calcul mutualisé des soldes comptes fournisseurs et sites
    VENDOR_BALANCES AS (
        SELECT API2.VENDOR_ID,
               API2.ORG_ID,
               API2.VENDOR_SITE_ID,
               SUM (APPSA2.AMOUNT_REMAINING) AS SOLDE_SITE,
               SUM (SUM (APPSA2.AMOUNT_REMAINING)) OVER (PARTITION BY API2.VENDOR_ID, API2.ORG_ID) AS SOLDE_FOURNISSEUR
          FROM (SELECT DISTINCT VENDOR_ID, ORG_ID FROM FACTURES_OUVERTES) V_ACTIFS
          JOIN AP_INVOICES_ALL API2
            ON API2.VENDOR_ID = V_ACTIFS.VENDOR_ID
           AND API2.ORG_ID = V_ACTIFS.ORG_ID
          JOIN AP_PAYMENT_SCHEDULES_ALL APPSA2
            ON APPSA2.INVOICE_ID = API2.INVOICE_ID
         GROUP BY API2.VENDOR_ID, API2.ORG_ID, API2.VENDOR_SITE_ID
    ),
    -- 7. Sous-requête T1 contenant exactement les 70 colonnes d'origine
    T1 AS (
        SELECT DISTINCT
               /* Col 07 */ API.INVOICE_ID,                                    --=3512800
               /* Col 08 */ API.SOURCE,
               /* Col 09 */ API.ATTRIBUTE9,
               /* Col 10 */ SUBSTR (UO.NAME, 1, 3) AS REGION,
               /* Col 11 */ SUBSTR (UO.NAME, 4, 4) AS CODE_SOCIETE,
               /* Col 12 */ GLL.NAME AS SOCIETE,
               /* Col 13 */ DECODE (APPSA.PAYMENT_METHOD_CODE,
                                    'WIRE', 'PRELEVEMENT',
                                    'EFT', 'VIREMENT ELECTRONIQUE',
                                    'CHECK', 'CHEQUES',
                                    'OUTSOURCED_CHECK', 'CHEQUE EXTERNALISE',
                                    APPSA.PAYMENT_METHOD_CODE) AS MODE_REGLEMENT_FACTURE,
               /* Col 14 */ API.INVOICE_NUM AS NUMERO_FACTURE,
               /* Col 15 */ API.DESCRIPTION AS DESCRIPTION_FACTURE,
               /* Col 16 */ API.DOC_SEQUENCE_VALUE AS NUMERO_CHRONO,
               /* Col 17 */ API.INVOICE_TYPE_LOOKUP_CODE AS TYPE_FACTURE,
               /* Col 18 */ API.ATTRIBUTE13 AS NO_COMMANDE_XEROX,
               /* Col 19 */ APS.VENDOR_NAME AS FOURNISSEUR,
               /* Col 20 */ APS.SEGMENT1 AS CODE_FOURNISSEUR,
               /* Col 21 */ APSS.VENDOR_SITE_CODE AS CODE_SITE,
               /* Col 22 */ APSS.VENDOR_SITE_ID AS VENDOR_SITE_ID,
               /* Col 23 */ APSS.ATTRIBUTE4 AS IVALUA_SITE_ID,
               /* Col 24 */ (SELECT SITE_REF.VENDOR_SITE_ID
                               FROM AP_SUPPLIER_SITES_ALL SITE_REF
                               JOIN HR_ORGANIZATION_UNITS UO_REF
                                 ON UO_REF.ORGANIZATION_ID = SITE_REF.ORG_ID
                                AND UO_REF.NAME = 'REF9999'
                              WHERE SITE_REF.PARTY_SITE_ID = APSS.PARTY_SITE_ID) AS REF_SITE_ID,
               /* Col 25 */ DECODE (PMT_MTHDS.PAYMENT_METHOD_CODE,
                                    'WIRE', 'PRELEVEMENT',
                                    'EFT', 'VIREMENT ELECTRONIQUE',
                                    'CHECK', 'CHEQUES',
                                    'OUTSOURCED_CHECK', 'CHEQUE EXTERNALISE',
                                    'NULL') MODE_REGLEMENT_SITE,
               /* Col 26 */ APSS.PAY_SITE_FLAG AS SITE_RGLT,
               /* Col 27 */ API.INVOICE_DATE AS DATE_FACTURE,
               /* Col 28 */ APPSA.DUE_DATE AS DATE_ECHEANCE,
               /* Col 29 */ APPSA.PAYMENT_PRIORITY AS PRIORITE_REGLT,
               /* Col 30 */ API.CREATION_DATE AS DATE_CREATION_FACTURE,
               /* Col 31 */ FU.USER_NAME AS UTILISATEUR_CREATION_FACTURE,
               /* Col 32 */ PAPF.FULL_NAME AS EMPLOYE_CREATION_FACTURE,
               /* Col 33 */ API.WFAPPROVAL_STATUS STATUT,
               /* Col 34 */ (SELECT DISTINCT LV.MEANING
                               FROM FND_LOOKUP_VALUES LV
                              WHERE LV.LANGUAGE = 'F'
                                AND LV.VIEW_APPLICATION_ID = 200
                                AND LV.LOOKUP_TYPE = 'AP_WFAPPROVAL_STATUS'
                                AND LV.LOOKUP_CODE = API.WFAPPROVAL_STATUS) AS STATUT_APPROBATION_LIBELLE,
               /* Col 35 */ API.ATTRIBUTE3 AS IMAGES_XEROX,
               /* Col 36 */ NVL (HS.NB_BLOCAGES_RESTANTS, 0) AS NB_BLOCAGES_FACTURE_RESTANTS,
               /* Col 37 */ NVL (HS.NB_BLOCAGES_IVALUA_RESTANTS, 0) AS NB_BLOCAGES_IVALUA_RESTANTS,
               /* Col 38 */ NVL (HS.NB_BLOCAGES_AFF_RESTANT, 0) AS NB_BLOCAGES_AFF_RESTANT,
               /* Col 39 */ NVL (HS.NB_BLOCAGES_AFFACTURAGE, 0) AS NB_BLOCAGES_AFFACTURAGE,
               /* Col 40 */ NVL (HS.LITIGE_ACTIF, 'NON') AS LITIGE_ACTIF,
               /* Col 41 */ NVL (HS.BLOCAGE_IVALUA_ACTIF, 'NON') AS BLOCAGE_IVALUA_ACTIF,
               /* Col 42 */ CASE
                                WHEN EXISTS (
                                    SELECT 'X'
                                      FROM FND_ATTACHED_DOCUMENTS FAD
                                     WHERE FAD.PK1_VALUE = TO_CHAR (API.INVOICE_ID)
                                       AND FAD.ENTITY_NAME = 'AP_INVOICES'
                                ) THEN 'OUI'
                                ELSE 'NON'
                            END AS EXIST_IMAGE_FACTURE,
               /* Col 43 */ (SELECT FDT.DESCRIPTION
                               FROM FND_ATTACHED_DOCUMENTS FAD,
                                    FND_DOCUMENTS_TL FDT
                              WHERE FAD.ENTITY_NAME = 'AP_INVOICES'
                                AND FAD.PK1_VALUE = TO_CHAR (API.INVOICE_ID)
                                AND FDT.LANGUAGE = 'F'
                                AND FDT.DOCUMENT_ID = FAD.DOCUMENT_ID
                                AND ROWNUM = 1) AS NOM_IMAGE,
               /* Col 44 */ APPSA.HOLD_FLAG AS BLOCAGE_ECHEANCIER,
               /* Col 45 */ NVL (SS.ETALEMENT_ECHEANCIER, 'NON') AS "Etalement Echéancier",
               /* Col 46 */ API.INVOICE_AMOUNT AS MONTANT_TTC,
               /* Col 47 */ DS.TOTAL_LIGNES AS TOTAL_LIGNES,
               /* Col 48 */ API.AMOUNT_PAID AS MONTANT_RÉGLÉ,
               /* Col 49 */ APPSA.AMOUNT_REMAINING AS RESTE_DU,
               /* Col 50 */ VB.SOLDE_FOURNISSEUR AS SOLDE_COMPTE_FOURNISSEUR,
               /* Col 51 */ VB.SOLDE_SITE AS SOLDE_COMPTE_FRSS_UO_SITE_RGT,
               /* Col 52 */ API.PAY_GROUP_LOOKUP_CODE AS TYPE_REGLEMENT,
               /* Col 53 */ GCC.SEGMENT3 AS COMPTE_COLLECTIF,
               /* Col 54 */ GCC.SEGMENT5 AS CODE_PARTENAIRE,
               /* Col 55 */ IEBA.BANK_ACCOUNT_NAME AS NOM_COMPTE_BANCAIRE,
               /* Col 56 */ IEBA.BANK_ACCOUNT_NUM AS NUMÉRO_COMPTE_BANCAIRE,
               /* Col 57 */ IEBA.IBAN AS IBAN,
               /* Col 58 */ TO_CHAR (IEBA.END_DATE, 'DD/MM/YYYY') DATE_DESACTIVATION_CPTE_SITE,
               /* Col 59 */ IEBA2.BANK_ACCOUNT_NAME AS NOM_CPTE_BANCAIRE_ECHEANCIER,
               /* Col 60 */ IEBA2.BANK_ACCOUNT_NUM AS NUM_CPTE_BANCAIRE_ECHEANCIER,
               /* Col 61 */ TO_CHAR (IEBA2.END_DATE, 'DD/MM/YYYY') DATE_DESACTIVATION_CPTE_ECHEAN,
               /* Col 62 */ NVL (IEBA2.FOREIGN_PAYMENT_USE_FLAG, 'N') AUTORISE_RGLT_INTERNATIONAUX,
               /* Col 63 */ API.INVOICE_TYPE_LOOKUP_CODE,
               /* Col 64 */ API.PAYMENT_STATUS_FLAG,
               /* Col 65 */ API.INVOICE_AMOUNT,
               /* Col 66 */ PMT_MTHDS.inactive_date,
               /* Col 67 */ PMT_MTHDS.primary_flag,
               /* Col 68 */ CASE
                                WHEN (NVL (HS.NB_HOLDS_NON_QTY_REC, 0) = 0
                                      AND EXISTS (
                                          SELECT 'X'
                                            FROM AP_INVOICE_LINES_ALL AILA
                                           WHERE AILA.INVOICE_ID = API.INVOICE_ID
                                      )
                                      AND EXISTS (
                                          SELECT 'X'
                                            FROM AP_HOLDS_ALL AHA,
                                                 PO_LINE_LOCATIONS_ALL PLLA
                                           WHERE AHA.INVOICE_ID = API.INVOICE_ID
                                             AND AHA.HOLD_LOOKUP_CODE = 'QTY REC'
                                             AND PLLA.LINE_LOCATION_ID = AHA.LINE_LOCATION_ID
                                             AND NOT EXISTS (
                                                 SELECT 'X'
                                                   FROM RCV_TRANSACTIONS A
                                                  WHERE PLLA.PO_HEADER_ID = A.PO_HEADER_ID
                                                    AND PLLA.PO_LINE_ID = A.PO_LINE_ID
                                                    AND A.CREATION_DATE <= API.CREATION_DATE
                                             )
                                      ))
                                     OR NVL (HS.NB_HOLDS_CREATION_12H, 0) = 0
                                THEN 'OUI'
                                ELSE 'NON'
                            END AS ByPass_CSP,
               /* Col 69 */ FND_GFM.CONSTRUCT_DOWNLOAD_URL (FND_WEB_CONFIG.GFM_AGENT, FD.MEDIA_ID) url,
               /* Col 70 */ (SELECT NAME FROM APPS.AP_TERMS WHERE TERM_ID = API.TERMS_ID) CONDITION_PAIEMENT,
               /* Col 71 */ TO_CHAR (HS.MAX_RELEASE_DATE, 'DD/MM/YYYY HH24:MI:SS') DATE_DERNIER_DEBLOCAGE,
               /* Col 72 */ A2.END_DATE "Date fin Affectation CPTE",
               /* Col 73 */ IEBA2.IBAN AS IBAN_ECHEANCIER,
               /* Col 74 */ A3.END_DATE "Date fin Affectation CPTE ECHEAN",
               /* Col 75 */ API.ATTRIBUTE5 IBAN_DEMAT,
               /* Col 76 */ API.ATTRIBUTE11 DATE_ECHEANCE_DEMAT
          FROM FACTURES_OUVERTES FO
          JOIN AP_INVOICES_ALL API
            ON API.INVOICE_ID = FO.INVOICE_ID
          JOIN AP_PAYMENT_SCHEDULES_ALL APPSA
            ON API.INVOICE_ID = APPSA.INVOICE_ID
           AND APPSA.AMOUNT_REMAINING <> 0
           AND API.SOURCE <> 'SURTAXE'
          JOIN AP_SUPPLIERS APS
            ON API.VENDOR_ID = APS.VENDOR_ID
          JOIN AP_SUPPLIER_SITES_ALL APSS
            ON API.VENDOR_SITE_ID = APSS.VENDOR_SITE_ID
          JOIN HR_ORGANIZATION_UNITS UO
            ON API.ORG_ID = UO.ORGANIZATION_ID
          JOIN GL_LEDGERS GLL
            ON API.SET_OF_BOOKS_ID = GLL.LEDGER_ID
          JOIN GL_CODE_COMBINATIONS GCC
            ON API.ACCTS_PAY_CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
          JOIN IBY.IBY_EXTERNAL_PAYEES_ALL IEPA
            ON IEPA.SUPPLIER_SITE_ID = API.VENDOR_SITE_ID
          LEFT JOIN APPS.IBY_EXT_PARTY_PMT_MTHDS PMT_MTHDS
            ON PMT_MTHDS.EXT_PMT_PARTY_ID = IEPA.EXT_PAYEE_ID
          LEFT JOIN APPS.FND_USER FU
            ON FU.USER_ID = API.CREATED_BY
          LEFT JOIN IBY_EXT_BANK_ACCOUNTS IEBA
            ON API.EXTERNAL_BANK_ACCOUNT_ID = IEBA.EXT_BANK_ACCOUNT_ID
          LEFT OUTER JOIN IBY_PMT_INSTR_USES_ALL A2
            ON A2.EXT_PMT_PARTY_ID = IEPA.EXT_PAYEE_ID
           AND A2.INSTRUMENT_ID = IEBA.EXT_BANK_ACCOUNT_ID
           AND A2.PAYMENT_FUNCTION = 'PAYABLES_DISB'
          LEFT JOIN IBY_EXT_BANK_ACCOUNTS IEBA2
            ON APPSA.EXTERNAL_BANK_ACCOUNT_ID = IEBA2.EXT_BANK_ACCOUNT_ID
          LEFT OUTER JOIN IBY_PMT_INSTR_USES_ALL A3
            ON A3.EXT_PMT_PARTY_ID = IEPA.EXT_PAYEE_ID
           AND A3.INSTRUMENT_ID = IEBA2.EXT_BANK_ACCOUNT_ID
           AND A3.PAYMENT_FUNCTION = 'PAYABLES_DISB'
          LEFT JOIN APPS.PER_ALL_PEOPLE_F PAPF
            ON PAPF.PERSON_ID = FU.EMPLOYEE_ID
           AND PAPF.EFFECTIVE_START_DATE = (
               SELECT MAX (PAPF2.EFFECTIVE_START_DATE)
                 FROM APPS.PER_ALL_PEOPLE_F PAPF2
                WHERE PAPF2.PERSON_ID = PAPF.PERSON_ID
           )
          -- TO_CHAR(API.INVOICE_ID) pour activer l'index standard sur FND_ATTACHED_DOCUMENTS
          LEFT OUTER JOIN FND_ATTACHED_DOCUMENTS FAD
            ON FAD.PK1_VALUE = TO_CHAR (API.INVOICE_ID)
           AND FAD.ENTITY_NAME = 'AP_INVOICES'
           AND FAD.SEQ_NUM = '10'
          LEFT OUTER JOIN APPS.FND_DOCUMENTS FD
            ON FAD.DOCUMENT_ID = FD.DOCUMENT_ID
           AND FD.MEDIA_ID = (
               SELECT MAX (FD2.MEDIA_ID)
                 FROM FND_DOCUMENTS FD2
                WHERE FD.DOCUMENT_ID = FD2.DOCUMENT_ID
           )
          LEFT JOIN HOLDS_SUMMARY HS
            ON HS.INVOICE_ID = API.INVOICE_ID
          LEFT JOIN DIST_SUMMARY DS
            ON DS.INVOICE_ID = API.INVOICE_ID
          LEFT JOIN SCHED_SUMMARY SS
            ON SS.INVOICE_ID = API.INVOICE_ID
          LEFT JOIN VENDOR_BALANCES VB
            ON VB.VENDOR_ID = API.VENDOR_ID
           AND VB.ORG_ID = API.ORG_ID
           AND VB.VENDOR_SITE_ID = API.VENDOR_SITE_ID
         WHERE 1 = 1
           --CONDITION PAIEMENT FOUR PAR DEFAUT
           AND NVL (PMT_MTHDS.PRIMARY_FLAG, 'Y') = 'Y'
           AND NVL (PMT_MTHDS.INACTIVE_DATE, SYSDATE + 1) > SYSDATE
           --AND APS.SEGMENT1 = '58954'
           --AND API.INVOICE_NUM = '33122859'
           --AND API.INVOICE_ID = 11586
           --AND UO.NAME = 'DLS0001'
    )
-- 8. SELECT final conservant les 6 colonnes d'en-tête + T1.* (total = 76 colonnes)
SELECT /* Col 01 */ T1.INVOICE_ID,
       /* Col 02 */ SF.COMPTA AS COMPTA,
       /* Col 03 */ DECODE (SF.COMPTA,
                            'Y', 'Comptabilisé',
                            'N', 'Non Comptabilisé',
                            'P', 'Partiellement Compta',
                            '') AS COMPTABILISATION,
       /* Col 04 */ SF.STATUT_VALIDATION AS STATUT_VALIDATION,
       /* Col 05 */ DECODE (SF.STATUT_VALIDATION,
                            'APPROVED', 'Validé',
                            'NEEDS REAPPROVAL', 'A REVALIDER',
                            'NEVER APPROVED', 'JAMAIS VALIDÉ',
                            'UNPAID', 'NON REGLÉ',
                            '') AS LIBELLÉ_STATUT_VALIDATION,
       /* Col 06 */ DECODE (SF.SEL_PMT_FLAG,
                            'Y', 'OUI',
                            'NON') AS "Sélectionnée pour règlement",
       /* Col 07 à 76 */ T1.*
  FROM T1
  JOIN STATUTS_FACTURE SF
    ON SF.INVOICE_ID = T1.INVOICE_ID
 ORDER BY T1.REGION,
          T1.SOCIETE,
          T1.CODE_FOURNISSEUR,
          T1.NUMERO_FACTURE;