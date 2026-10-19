# DKA_TABLES_DTR_A_LA_DMD.sql

Source : [dka/12.0.0/sql/DKA_TABLES_DTR_A_LA_DMD.sql](../../dka/12.0.0/sql/DKA_TABLES_DTR_A_LA_DMD.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 523 ; encodage : cp1252 (repli). SHA-256 : `7a41a17b3b39a5b01e0a14b92ca91116300d585fa29de55cafe3991326afcea6`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `APPLSYS.FND_USER` | 189 |
| `HR.PER_ALL_PEOPLE_F` | 190 |
| `GL.GL_CODE_COMBINATIONS` | 191 |
| `GL.GL_PERIOD_STATUSES` | 192 |
| `PA.PA_PROJECTS_ALL` | 193 |
| `APPLSYS.FND_FLEX_VALUE_SETS` | 194 |
| `APPLSYS.FND_FLEX_VALUES` | 195 |
| `HR.HR_ALL_ORGANIZATION_UNITS` | 196 |
| `PA.PA_TASKS` | 197 |
| `XLE.XLE_ENTITY_PROFILES` | 198 |
| `GL.GL_LEDGERS` | 199 |
| `APPLSYS.FND_FLEX_VALUES_TL` | 200 |
| `GL.GL_LEDGER_CONFIGURATIONS` | 201 |
| `GL.GL_LEDGER_NORM_SEG_VALS` | 202 |
| `AR.HZ_GEOGRAPHIES` | 203 |
| `PA.PA_PROJECT_STATUSES` | 204 |
| `HR.PER_ALL_ASSIGNMENTS_F` | 205 |
| `APPLSYS.FND_APPLICATION` | 206 |
| `AP.AP_SUPPLIERS` | 207 |
| `AP.AP_SUPPLIER_SITES_ALL` | 208 |
| `GL.GL_BALANCES` | 209 |
| `GL.GL_JE_LINES` | 210 |
| `GL.GL_JE_HEADERS` | 211 |
| `GL.GL_JE_BATCHES` | 212 |
| `GL.GL_JE_LINES_RECON` | 213 |
| `AP.AP_INVOICES_ALL` | 214 |
| `AP.AP_HOLDS_ALL` | 215 |
| `AP.AP_TERMS_TL` | 216 |
| `AP.AP_INVOICE_PAYMENTS_ALL` | 217 |
| `APPLSYS.FND_ATTACHED_DOCUMENTS` | 218 |
| `IBY.IBY_EXTERNAL_PAYEES_ALL` | 219 |
| `IBY.IBY_EXT_PARTY_PMT_MTHDS` | 220 |
| `AR.HZ_PARTIES` | 221 |
| `APPLSYS.FND_ID_FLEX_STRUCTURES_TL` | 222 |
| `PA.PA_IND_RATE_SCHEDULES_ALL_BG` | 223 |
| `AP.AP_INVOICE_DISTRIBUTIONS_ALL` | 224 |
| `PA.PA_PROJECT_ASSET_ASSIGNMENTS` | 225 |
| `PA.PA_PROJECT_ASSETS_ALL` | 226 |
| `GL.GL_RECURRING_BATCHES` | 227 |
| `GL.GL_RECURRING_HEADERS` | 228 |
| `GL.GL_RECURRING_LINES` | 229 |
| `GL.GL_RECURRING_LINE_CALC_RULES` | 230 |
| `AP.AP_CHECKS_ALL` | 231 |
| `AP.AP_PAYMENT_SCHEDULES_ALL` | 232 |
| `INV.MTL_CATEGORIES_B` | 233 |
| `INV.MTL_CATEGORIES_TL` | 234 |
| `PA.PA_COST_DISTRIBUTION_LINES_ALL` | 235 |
| `PA.PA_DRAFT_REVENUES_ALL` | 236 |
| `PA.PA_EVENTS` | 237 |
| `PA.PA_EXPENDITURE_ITEMS_ALL` | 238 |
| `PA.PA_EXPENDITURE_TYPES` | 239 |
| `PA.PA_PERIODS_ALL` | 240 |
| `PA.PA_PROJECT_ASSET_LINES_ALL` | 241 |
| `PO.PO_ACTION_HISTORY` | 242 |
| `PO.PO_DISTRIBUTIONS_ALL` | 244 |
| `PO.PO_HEADERS_ALL` | 245 |
| `PO.PO_LINES_ALL` | 246 |
| `PO.PO_REQ_DISTRIBUTIONS_ALL` | 247 |
| `PO.PO_REQUISITION_HEADERS_ALL` | 248 |
| `PO.PO_REQUISITION_LINES_ALL` | 249 |
| `AR.RA_CUSTOMER_TRX_ALL` | 250 |
| `HR.HR_LOCATIONS_ALL` | 251 |
| `PA.PA_PROJECT_ASSET_LINE_DETAILS` | 252 |
| `PA.PA_EVENT_TYPES` | 253 |
| `AR.RA_CUST_TRX_LINE_GL_DIST_ALL` | 254 |
| `AR.RA_CUSTOMER_TRX_LINES_ALL` | 255 |
| `AR.AR_ADJUSTMENTS_ALL` | 256 |
| `PA.PA_CUST_EVENT_RDL_ALL` | 257 |
| `PO.PO_POSITION_CONTROLS_ALL` | 258 |
| `PO.PO_CONTROL_GROUPS_ALL` | 259 |
| `PO.PO_CONTROL_RULES` | 260 |
| `HR.PER_SECURITY_ORGANIZATIONS` | 261 |
| `HR.PER_SECURITY_PROFILES` | 262 |
| `APPLSYS.WF_NOTIFICATIONS` | 263 |
| `DKA.DKA_STRANSCO_LINES` | 264 |
| `DKA.DKA_STRANSCO_HEADERS` | 265 |
| `AP.AP_INVOICE_LINES_ALL` | 266 |
| `AR.HZ_CUST_ACCOUNTS` | 267 |
| `AR.HZ_CUST_ACCT_SITES_ALL` | 268 |
| `AR.HZ_PARTY_SITES` | 269 |
| `AR.HZ_CUST_SITE_USES_ALL` | 270 |
| `AR.HZ_LOCATIONS` | 271 |
| `ZX.ZX_LINES` | 272 |
| `AR.AR_PAYMENT_SCHEDULES_ALL` | 273 |
| `AR.AR_CASH_RECEIPTS_ALL` | 274 |
| `AR.AR_RECEIVABLE_APPLICATIONS_ALL` | 275 |
| `AR.RA_TERMS_TL` | 276 |
| `AR.AR_RECEIPT_METHODS` | 277 |
| `AR.RA_CUST_TRX_TYPES_ALL` | 278 |
| `AR.RA_BATCH_SOURCES_ALL` | 279 |
| `APPLSYS.FND_LOOKUP_VALUES` | 280 |
| `IBY.IBY_EXT_BANK_ACCOUNTS` | 281 |
| `DKA.DKA_CONTRAT_SSTR` | 282 |
| `DKA.DKA_CONTRAT_SSTR_IMPUTATION` | 283 |
| `PO.PO_LINE_LOCATIONS_ALL` | 285 |
| `PO.RCV_TRANSACTIONS` | 286 |
| `PO.RCV_SHIPMENT_HEADERS` | 287 |
| `PO.PO_LINES_ARCHIVE_ALL` | 288 |
| `PO.PO_HEADERS_ARCHIVE_ALL` | 289 |
| `APPLSYS.FND_REQUEST_GROUPS` | 290 |
| `APPLSYS.FND_APPLICATION_TL` | 291 |
| `HR.PER_JOBS_TL` | 292 |
| `HR.PER_ASSIGNMENT_STATUS_TYPES` | 293 |
| `HR.PER_JOBS` | 294 |
| `PO.PO_CONTROL_FUNCTIONS` | 295 |
| `APPLSYS.FND_RESPONSIBILITY` | 296 |
| `APPLSYS.FND_RESPONSIBILITY_TL` | 297 |
| `APPLSYS.FND_PROFILE_OPTIONS` | 298 |
| `AK.AK_WEB_USER_SEC_ATTR_VALUES` | 299 |
| `AK.AK_RESP_SECURITY_ATTRIBUTES` | 300 |
| `HR.PER_GRADES_TL` | 301 |
| `APPLSYS.FND_SECURITY_GROUPS` | 302 |
| `APPLSYS.WF_USER_ROLE_ASSIGNMENTS` | 303 |
| `APPLSYS.WF_LOCAL_USER_ROLES` | 304 |
| `HR.PER_ORGANIZATION_STRUCTURES` | 305 |
| `HR.PER_ORG_STRUCTURE_VERSIONS` | 306 |
| `HR.PER_ORG_STRUCTURE_ELEMENTS` | 307 |
| `CE.CE_BANK_ACCOUNTS` | 308 |
| `IBY.IBY_PAYMENTS_ALL` | 309 |
| `GL.GL_JE_CATEGORIES_TL` | 310 |
| `GL.GL_JE_SOURCES_TL` | 311 |
| `APPLSYS.FND_PROFILE_OPTIONS_TL` | 312 |
| `DKA.DKA_SAP_STATUT_FACTURE` | 313 |
| `FA.FA_CATEGORIES_B` | 314 |
| `FA.FA_CATEGORIES_TL` | 315 |
| `FA.FA_CATEGORY_BOOKS` | 316 |
| `FA.FA_ADJUSTMENTS` | 317 |
| `FA.FA_CALENDAR_PERIODS` | 318 |
| `FA.FA_DEPRN_DETAIL` | 319 |
| `FA.FA_BOOK_CONTROLS` | 320 |
| `FA.FA_ADDITIONS_B` | 321 |
| `FA.FA_ADDITIONS_TL` | 322 |
| `FA.FA_ASSET_INVOICES` | 323 |
| `FA.FA_BOOKS` | 324 |
| `FA.FA_DEPRN_PERIODS` | 325 |
| `FA.FA_DISTRIBUTION_HISTORY` | 326 |
| `FA.FA_LOCATIONS` | 327 |
| `FA.FA_LOOKUPS_TL` | 328 |
| `FA.FA_RETIREMENTS` | 329 |
| `FA.FA_TRANSACTION_HEADERS` | 330 |
| `FA.FA_LOOKUPS_B` | 331 |
| `FA.FA_DEPRN_SUMMARY` | 332 |
| `FA.FA_MC_DEPRN_SUMMARY` | 333 |
| `FA.FA_MC_BOOKS` | 334 |
| `FA.FA_MC_BOOK_CONTROLS` | 335 |
| `FA.FA_DISTRIBUTION_ACCOUNTS` | 336 |
| `AR.HZ_CUSTOMER_PROFILES` | 337 |
| `AR.AR_COLLECTORS` | 338 |
| `APPLSYS.FND_PROFILE_OPTION_VALUES` | 339 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 176, 342, 510, 519 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
