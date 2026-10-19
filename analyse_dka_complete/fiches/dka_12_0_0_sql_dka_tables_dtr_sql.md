# DKA_TABLES_DTR.sql

Source : [dka/12.0.0/sql/DKA_TABLES_DTR.sql](../../dka/12.0.0/sql/DKA_TABLES_DTR.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 11809 ; encodage : cp1252 (repli). SHA-256 : `71ec88ddc949ad40e967c980448208d34604f470f3de27a3ee91bb26587e5bca`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `AK.AK_RESP_SECURITY_ATTRIBUTES` | 201 |
| `AK.AK_WEB_USER_SEC_ATTR_VALUES` | 216 |
| `AP.AP_CHECKS_ALL` | 376 |
| `AP.AP_HOLDS_ALL` | 418 |
| `AP.AP_INVOICE_DISTRIBUTIONS_ALL` | 666 |
| `AP.AP_INVOICE_LINES_ALL` | 872 |
| `AP.AP_INVOICE_PAYMENTS_ALL` | 971 |
| `AP.AP_INVOICES_ALL` | 1169 |
| `AP.AP_PAYMENT_SCHEDULES_ALL` | 1249 |
| `AP.AP_SUPPLIERS` | 1433 |
| `AP.AP_SUPPLIER_SITES_ALL` | 1602 |
| `AP.AP_TERMS_TL` | 1638 |
| `AR.AR_ADJUSTMENTS_ALL` | 1737 |
| `AR.AR_CASH_RECEIPTS_ALL` | 1865 |
| `AR.AR_COLLECTORS` | 1902 |
| `AR.AR_PAYMENT_SCHEDULES_ALL` | 2038 |
| `AR.AR_RECEIVABLE_APPLICATIONS_ALL` | 2178 |
| `AR.AR_RECEIPT_METHODS` | 2247 |
| `CE.CE_BANK_ACCOUNTS` | 2374 |
| `DKA.DKA_CONTRAT_SSTR_IMPUTATION` | 2394 |
| `DKA.DKA_CONTRAT_SSTR` | 2428 |
| `AR.RA_CUST_TRX_LINE_GL_DIST_ALL` | 2527 |
| `FA.FA_ADDITIONS_B` | 2611 |
| `FA.FA_ADDITIONS_TL` | 2624 |
| `FA.FA_ADJUSTMENTS` | 2673 |
| `FA.FA_ASSET_INVOICES` | 2738 |
| `FA.FA_BOOK_CONTROLS` | 2895 |
| `FA.FA_BOOKS` | 3031 |
| `FA.FA_CALENDAR_PERIODS` | 3045 |
| `FA.FA_CATEGORIES_B` | 3111 |
| `FA.FA_CATEGORIES_TL` | 3124 |
| `FA.FA_CATEGORY_BOOKS` | 3212 |
| `FA.FA_DEPRN_DETAIL` | 3256 |
| `FA.FA_DEPRN_PERIODS` | 3287 |
| `FA.FA_DEPRN_SUMMARY` | 3327 |
| `FA.FA_DISTRIBUTION_ACCOUNTS` | 3366 |
| `FA.FA_DISTRIBUTION_HISTORY` | 3388 |
| `FA.FA_LOCATIONS` | 3423 |
| `FA.FA_LOOKUPS_B` | 3455 |
| `FA.FA_LOOKUPS_TL` | 3472 |
| `FA.FA_MC_BOOK_CONTROLS` | 3500 |
| `FA.FA_MC_BOOKS` | 3629 |
| `FA.FA_MC_DEPRN_SUMMARY` | 3671 |
| `FA.FA_RETIREMENTS` | 3733 |
| `FA.FA_TRANSACTION_HEADERS` | 3774 |
| `APPLSYS.FND_APPLICATION` | 3789 |
| `APPLSYS.FND_APPLICATION_TL` | 3805 |
| `APPLSYS.FND_ATTACHED_DOCUMENTS` | 3849 |
| `APPLSYS.FND_FLEX_VALUES` | 3924 |
| `APPLSYS.FND_FLEX_VALUE_SETS` | 3953 |
| `APPLSYS.FND_FLEX_VALUES_TL` | 3969 |
| `APPLSYS.FND_ID_FLEX_STRUCTURES_TL` | 3988 |
| `APPLSYS.FND_LOOKUP_VALUES` | 4029 |
| `APPLSYS.FND_PROFILE_OPTIONS` | 4065 |
| `APPLSYS.FND_PROFILE_OPTIONS_TL` | 4081 |
| `APPLSYS.FND_PROFILE_OPTION_VALUES` | 4099 |
| `APPLSYS.FND_REQUEST_GROUPS` | 4115 |
| `APPLSYS.FND_RESPONSIBILITY` | 4140 |
| `APPLSYS.FND_RESPONSIBILITY_TL` | 4157 |
| `APPLSYS.FND_SECURITY_GROUPS` | 4170 |
| `APPLSYS.FND_USER` | 4201 |
| `GL.GL_BALANCES` | 4242 |
| `GL.GL_CODE_COMBINATIONS` | 4358 |
| `GL.GL_JE_BATCHES` | 4435 |
| `GL.GL_JE_CATEGORIES_TL` | 4459 |
| `GL.GL_JE_HEADERS` | 4552 |
| `GL.GL_JE_LINES` | 4650 |
| `GL.GL_JE_LINES_RECON` | 4666 |
| `GL.GL_JE_SOURCES_TL` | 4694 |
| `GL.GL_LEDGER_CONFIGURATIONS` | 4724 |
| `GL.GL_LEDGER_NORM_SEG_VALS` | 4760 |
| `GL.GL_LEDGERS` | 4853 |
| `GL.GL_PERIOD_STATUSES` | 4887 |
| `GL.GL_RECURRING_LINE_CALC_RULES` | 4948 |
| `GL.GL_RECURRING_BATCHES` | 4986 |
| `GL.GL_RECURRING_HEADERS` | 5020 |
| `GL.GL_RECURRING_LINES` | 5047 |
| `HR.HR_ALL_ORGANIZATION_UNITS` | 5105 |
| `HR.HR_LOCATIONS_ALL` | 5199 |
| `AR.HZ_CUST_ACCOUNTS` | 5342 |
| `AR.HZ_CUST_ACCT_SITES_ALL` | 5422 |
| `AR.HZ_CUSTOMER_PROFILES` | 5546 |
| `AR.HZ_CUST_SITE_USES_ALL` | 5667 |
| `AR.HZ_GEOGRAPHIES` | 5740 |
| `AR.HZ_LOCATIONS` | 5860 |
| `AR.HZ_PARTIES` | 6003 |
| `AR.HZ_PARTY_SITES` | 6082 |
| `IBY.IBY_EXT_BANK_ACCOUNTS` | 6155 |
| `IBY.IBY_EXTERNAL_PAYEES_ALL` | 6192 |
| `IBY.IBY_EXT_PARTY_PMT_MTHDS` | 6209 |
| `IBY.IBY_PAYMENTS_ALL` | 6450 |
| `INV.MTL_CATEGORIES_B` | 6511 |
| `INV.MTL_CATEGORIES_TL` | 6526 |
| `PA.PA_COST_DISTRIBUTION_LINES_ALL` | 6622 |
| `PA.PA_CUST_EVENT_RDL_ALL` | 6699 |
| `PA.PA_DRAFT_REVENUES_ALL` | 6752 |
| `PA.PA_EVENTS` | 6870 |
| `PA.PA_EVENT_TYPES` | 6903 |
| `PA.PA_EXPENDITURE_ITEMS_ALL` | 7118 |
| `PA.PA_EXPENDITURE_TYPES` | 7154 |
| `PA.PA_IND_RATE_SCHEDULES_ALL_BG` | 7180 |
| `PA.PA_PERIODS_ALL` | 7196 |
| `PA.PA_PROJECT_ASSET_ASSIGNMENTS` | 7224 |
| `PA.PA_PROJECT_ASSET_LINE_DETAILS` | 7243 |
| `PA.PA_PROJECT_ASSET_LINES_ALL` | 7293 |
| `PA.PA_PROJECT_ASSETS_ALL` | 7362 |
| `PA.PA_PROJECTS_ALL` | 7592 |
| `PA.PA_PROJECT_STATUSES` | 7637 |
| `PA.PA_TASKS` | 7759 |
| `HR.PER_ALL_ASSIGNMENTS_F` | 7879 |
| `HR.PER_ALL_PEOPLE_F` | 8035 |
| `HR.PER_ASSIGNMENT_STATUS_TYPES` | 8055 |
| `HR.PER_GRADES_TL` | 8068 |
| `HR.PER_JOBS` | 8136 |
| `HR.PER_JOBS_TL` | 8149 |
| `HR.PER_ORGANIZATION_STRUCTURES` | 8190 |
| `HR.PER_ORG_STRUCTURE_ELEMENTS` | 8211 |
| `HR.PER_ORG_STRUCTURE_VERSIONS` | 8233 |
| `HR.PER_SECURITY_ORGANIZATIONS` | 8247 |
| `HR.PER_SECURITY_PROFILES` | 8294 |
| `PO.PO_ACTION_HISTORY` | 8320 |
| `PO.PO_CONTROL_FUNCTIONS` | 8359 |
| `PO.PO_CONTROL_GROUPS_ALL` | 8393 |
| `PO.PO_CONTROL_RULES` | 8489 |
| `PO.PO_DISTRIBUTIONS_ALL` | 8642 |
| `PO.PO_HEADERS_ALL` | 8848 |
| `PO.PO_HEADERS_ARCHIVE_ALL` | 9053 |
| `PO.PO_LINE_LOCATIONS_ALL` | 9234 |
| `PO.PO_LINES_ALL` | 9425 |
| `PO.PO_LINES_ARCHIVE_ALL` | 9616 |
| `PO.PO_POSITION_CONTROLS_ALL` | 9653 |
| `PO.PO_REQ_DISTRIBUTIONS_ALL` | 9743 |
| `PO.PO_REQUISITION_HEADERS_ALL` | 9842 |
| `PO.PO_REQUISITION_LINES_ALL` | 10077 |
| `AR.RA_BATCH_SOURCES_ALL` | 10180 |
| `AR.RA_CUSTOMER_TRX_ALL` | 10376 |
| `AR.RA_CUSTOMER_TRX_LINES_ALL` | 10549 |
| `AR.RA_CUST_TRX_TYPES_ALL` | 10637 |
| `AR.RA_TERMS_TL` | 10653 |
| `PO.RCV_SHIPMENT_HEADERS` | 10748 |
| `PO.RCV_TRANSACTIONS` | 10886 |
| `DKA.DKA_SAP_STATUT_FACTURE` | 10898 |
| `DKA.DKA_STRANSCO_HEADERS` | 10921 |
| `DKA.DKA_STRANSCO_LINES` | 10940 |
| `APPLSYS.WF_LOCAL_USER_ROLES` | 10970 |
| `APPLSYS.WF_NOTIFICATIONS` | 11061 |
| `APPLSYS.WF_USER_ROLE_ASSIGNMENTS` | 11093 |
| `XLE.XLE_ENTITY_PROFILES` | 11156 |
| `ZX.ZX_LINES` | 11470 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 175, 11473, 11796, 11805 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
