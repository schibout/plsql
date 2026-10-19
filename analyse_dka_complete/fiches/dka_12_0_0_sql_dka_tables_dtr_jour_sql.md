# DKA_TABLES_DTR_JOUR.sql

Source : [dka/12.0.0/sql/DKA_TABLES_DTR_JOUR.sql](../../dka/12.0.0/sql/DKA_TABLES_DTR_JOUR.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 524 ; encodage : cp1252 (repli). SHA-256 : `87626b90c0590966b7525fdd5e01d3be79936ac2f98b7375b4cb7acbbbb40d75`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `APPLSYS.FND_USER` | 190 |
| `HR.PER_ALL_PEOPLE_F` | 191 |
| `GL.GL_CODE_COMBINATIONS` | 192 |
| `GL.GL_PERIOD_STATUSES` | 193 |
| `PA.PA_PROJECTS_ALL` | 194 |
| `APPLSYS.FND_FLEX_VALUE_SETS` | 195 |
| `APPLSYS.FND_FLEX_VALUES` | 196 |
| `HR.HR_ALL_ORGANIZATION_UNITS` | 197 |
| `PA.PA_TASKS` | 198 |
| `XLE.XLE_ENTITY_PROFILES` | 199 |
| `GL.GL_LEDGERS` | 200 |
| `APPLSYS.FND_FLEX_VALUES_TL` | 201 |
| `GL.GL_LEDGER_CONFIGURATIONS` | 202 |
| `GL.GL_LEDGER_NORM_SEG_VALS` | 203 |
| `AR.HZ_GEOGRAPHIES` | 204 |
| `PA.PA_PROJECT_STATUSES` | 205 |
| `HR.PER_ALL_ASSIGNMENTS_F` | 206 |
| `APPLSYS.FND_APPLICATION` | 207 |
| `AP.AP_SUPPLIERS` | 208 |
| `AP.AP_SUPPLIER_SITES_ALL` | 209 |
| `GL.GL_BALANCES` | 210 |
| `GL.GL_JE_LINES` | 211 |
| `GL.GL_JE_HEADERS` | 212 |
| `GL.GL_JE_BATCHES` | 213 |
| `GL.GL_JE_LINES_RECON` | 214 |
| `AP.AP_INVOICES_ALL` | 215 |
| `AP.AP_HOLDS_ALL` | 216 |
| `AP.AP_TERMS_TL` | 217 |
| `AP.AP_INVOICE_PAYMENTS_ALL` | 218 |
| `APPLSYS.FND_ATTACHED_DOCUMENTS` | 219 |
| `IBY.IBY_EXTERNAL_PAYEES_ALL` | 220 |
| `IBY.IBY_EXT_PARTY_PMT_MTHDS` | 221 |
| `AR.HZ_PARTIES` | 222 |
| `APPLSYS.FND_ID_FLEX_STRUCTURES_TL` | 223 |
| `PA.PA_IND_RATE_SCHEDULES_ALL_BG` | 224 |
| `AP.AP_INVOICE_DISTRIBUTIONS_ALL` | 225 |
| `PA.PA_PROJECT_ASSET_ASSIGNMENTS` | 226 |
| `PA.PA_PROJECT_ASSETS_ALL` | 227 |
| `GL.GL_RECURRING_BATCHES` | 228 |
| `GL.GL_RECURRING_HEADERS` | 229 |
| `GL.GL_RECURRING_LINES` | 230 |
| `GL.GL_RECURRING_LINE_CALC_RULES` | 231 |
| `AP.AP_CHECKS_ALL` | 232 |
| `AP.AP_PAYMENT_SCHEDULES_ALL` | 233 |
| `INV.MTL_CATEGORIES_B` | 234 |
| `INV.MTL_CATEGORIES_TL` | 235 |
| `PA.PA_COST_DISTRIBUTION_LINES_ALL` | 236 |
| `PA.PA_DRAFT_REVENUES_ALL` | 237 |
| `PA.PA_EVENTS` | 238 |
| `PA.PA_EXPENDITURE_ITEMS_ALL` | 239 |
| `PA.PA_EXPENDITURE_TYPES` | 240 |
| `PA.PA_PERIODS_ALL` | 241 |
| `PA.PA_PROJECT_ASSET_LINES_ALL` | 242 |
| `PO.PO_ACTION_HISTORY` | 243 |
| `PO.PO_DISTRIBUTIONS_ALL` | 244 |
| `PO.PO_HEADERS_ALL` | 246 |
| `PO.PO_LINES_ALL` | 247 |
| `PO.PO_REQ_DISTRIBUTIONS_ALL` | 248 |
| `PO.PO_REQUISITION_HEADERS_ALL` | 249 |
| `PO.PO_REQUISITION_LINES_ALL` | 250 |
| `AR.RA_CUSTOMER_TRX_ALL` | 251 |
| `HR.HR_LOCATIONS_ALL` | 252 |
| `PA.PA_PROJECT_ASSET_LINE_DETAILS` | 253 |
| `PA.PA_EVENT_TYPES` | 254 |
| `AR.RA_CUST_TRX_LINE_GL_DIST_ALL` | 255 |
| `AR.RA_CUSTOMER_TRX_LINES_ALL` | 256 |
| `AR.AR_ADJUSTMENTS_ALL` | 257 |
| `PA.PA_CUST_EVENT_RDL_ALL` | 258 |
| `PO.PO_POSITION_CONTROLS_ALL` | 259 |
| `PO.PO_CONTROL_GROUPS_ALL` | 260 |
| `PO.PO_CONTROL_RULES` | 261 |
| `HR.PER_SECURITY_ORGANIZATIONS` | 262 |
| `HR.PER_SECURITY_PROFILES` | 263 |
| `APPLSYS.WF_NOTIFICATIONS` | 264 |
| `DKA.DKA_STRANSCO_LINES` | 265 |
| `DKA.DKA_STRANSCO_HEADERS` | 266 |
| `AP.AP_INVOICE_LINES_ALL` | 267 |
| `AR.HZ_CUST_ACCOUNTS` | 268 |
| `AR.HZ_CUST_ACCT_SITES_ALL` | 269 |
| `AR.HZ_PARTY_SITES` | 270 |
| `AR.HZ_CUST_SITE_USES_ALL` | 271 |
| `AR.HZ_LOCATIONS` | 272 |
| `ZX.ZX_LINES` | 273 |
| `AR.AR_PAYMENT_SCHEDULES_ALL` | 274 |
| `AR.AR_CASH_RECEIPTS_ALL` | 275 |
| `AR.AR_RECEIVABLE_APPLICATIONS_ALL` | 276 |
| `AR.RA_TERMS_TL` | 277 |
| `AR.AR_RECEIPT_METHODS` | 278 |
| `AR.RA_CUST_TRX_TYPES_ALL` | 279 |
| `AR.RA_BATCH_SOURCES_ALL` | 280 |
| `APPLSYS.FND_LOOKUP_VALUES` | 281 |
| `IBY.IBY_EXT_BANK_ACCOUNTS` | 282 |
| `DKA.DKA_CONTRAT_SSTR` | 283 |
| `DKA.DKA_CONTRAT_SSTR_IMPUTATION` | 284 |
| `PO.PO_LINE_LOCATIONS_ALL` | 285 |
| `PO.RCV_TRANSACTIONS` | 287 |
| `PO.RCV_SHIPMENT_HEADERS` | 288 |
| `PO.PO_LINES_ARCHIVE_ALL` | 289 |
| `PO.PO_HEADERS_ARCHIVE_ALL` | 290 |
| `APPLSYS.FND_REQUEST_GROUPS` | 291 |
| `APPLSYS.FND_APPLICATION_TL` | 292 |
| `HR.PER_JOBS_TL` | 293 |
| `HR.PER_ASSIGNMENT_STATUS_TYPES` | 294 |
| `HR.PER_JOBS` | 295 |
| `PO.PO_CONTROL_FUNCTIONS` | 296 |
| `APPLSYS.FND_RESPONSIBILITY` | 297 |
| `APPLSYS.FND_RESPONSIBILITY_TL` | 298 |
| `APPLSYS.FND_PROFILE_OPTIONS` | 299 |
| `AK.AK_WEB_USER_SEC_ATTR_VALUES` | 300 |
| `AK.AK_RESP_SECURITY_ATTRIBUTES` | 301 |
| `HR.PER_GRADES_TL` | 302 |
| `APPLSYS.FND_SECURITY_GROUPS` | 303 |
| `APPLSYS.WF_USER_ROLE_ASSIGNMENTS` | 304 |
| `APPLSYS.WF_LOCAL_USER_ROLES` | 305 |
| `HR.PER_ORGANIZATION_STRUCTURES` | 306 |
| `HR.PER_ORG_STRUCTURE_VERSIONS` | 307 |
| `HR.PER_ORG_STRUCTURE_ELEMENTS` | 308 |
| `CE.CE_BANK_ACCOUNTS` | 309 |
| `IBY.IBY_PAYMENTS_ALL` | 310 |
| `GL.GL_JE_CATEGORIES_TL` | 311 |
| `GL.GL_JE_SOURCES_TL` | 312 |
| `APPLSYS.FND_PROFILE_OPTIONS_TL` | 313 |
| `DKA.DKA_SAP_STATUT_FACTURE` | 314 |
| `FA.FA_CATEGORIES_B` | 315 |
| `FA.FA_CATEGORIES_TL` | 316 |
| `FA.FA_CATEGORY_BOOKS` | 317 |
| `FA.FA_ADJUSTMENTS` | 318 |
| `FA.FA_CALENDAR_PERIODS` | 319 |
| `FA.FA_DEPRN_DETAIL` | 320 |
| `FA.FA_BOOK_CONTROLS` | 321 |
| `FA.FA_ADDITIONS_B` | 322 |
| `FA.FA_ADDITIONS_TL` | 323 |
| `FA.FA_ASSET_INVOICES` | 324 |
| `FA.FA_BOOKS` | 325 |
| `FA.FA_DEPRN_PERIODS` | 326 |
| `FA.FA_DISTRIBUTION_HISTORY` | 327 |
| `FA.FA_LOCATIONS` | 328 |
| `FA.FA_LOOKUPS_TL` | 329 |
| `FA.FA_RETIREMENTS` | 330 |
| `FA.FA_TRANSACTION_HEADERS` | 331 |
| `FA.FA_LOOKUPS_B` | 332 |
| `FA.FA_DEPRN_SUMMARY` | 333 |
| `FA.FA_MC_DEPRN_SUMMARY` | 334 |
| `FA.FA_MC_BOOKS` | 335 |
| `FA.FA_MC_BOOK_CONTROLS` | 336 |
| `FA.FA_DISTRIBUTION_ACCOUNTS` | 337 |
| `AR.HZ_CUSTOMER_PROFILES` | 338 |
| `AR.AR_COLLECTORS` | 339 |
| `APPLSYS.FND_PROFILE_OPTION_VALUES` | 340 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 177, 343, 511, 520 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
