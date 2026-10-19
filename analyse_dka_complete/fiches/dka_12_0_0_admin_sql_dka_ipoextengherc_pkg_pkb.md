# DKA_IPOEXTENGHERC_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IPOEXTENGHERC_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IPOEXTENGHERC_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1406 ; encodage : cp1252 (repli). SHA-256 : `6e574b8c6c2c80ca7336eb4aac79b01ee69f934fb2f5ecde3bbcda88db3808ba`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `p_put_debug_message` | 63 |
| `p_validate` | 80 |
| `p_check_directory` | 104 |
| `p_extract_data_cmd` | 147 |
| `p_extract_data_cmd` | 477 |
| `p_extract_data_inv` | 491 |
| `p_extract_data_inv` | 758 |
| `p_extract_data_maind` | 773 |
| `p_extract_data_maind` | 919 |
| `p_extract_data_refac` | 934 |
| `p_extract_data_refac` | 1105 |
| `output_header` | 1117 |
| `main` | 1161 |
| `bilan` | 1244 |
| `compression_fichier_sortie` | 1314 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `all_directories` | 108 |
| `PA.PA_TASKS` | 167 |
| `PO.PO_DISTRIBUTIONS_ALL` | 295 |
| `TASK` | 297 |
| `HR.HR_ALL_ORGANIZATION_UNITS` | 298 |
| `PO.PO_LINE_LOCATIONS_ALL` | 299 |
| `PO.PO_LINES_ALL` | 300 |
| `PO.PO_HEADERS_ALL` | 301 |
| `AP.AP_SUPPLIERS` | 302 |
| `PO.PO_REQUISITION_LINES_ALL` | 303 |
| `PO.PO_REQUISITION_HEADERS_ALL` | 304 |
| `APPS.MTL_CATEGORIES_B_KFV` | 305 |
| `FND_ID_FLEX_STRUCTURES_VL` | 306 |
| `PER_SECURITY_ORGANIZATIONS` | 317 |
| `PER_SECURITY_PROFILES` | 323 |
| `fnd_attached_documents` | 406 |
| `fnd_lob_access` | 420 |
| `PA.PA_TASKS` | 510 |
| `AP.AP_INVOICE_DISTRIBUTIONS_ALL` | 573 |
| `TASK` | 575 |
| `HR.HR_ALL_ORGANIZATION_UNITS` | 576 |
| `AP.AP_INVOICES_ALL` | 577 |
| `AP.AP_SUPPLIERS` | 578 |
| `GL.GL_CODE_COMBINATIONS` | 579 |
| `PER_SECURITY_ORGANIZATIONS` | 599 |
| `PER_SECURITY_PROFILES` | 605 |
| `fnd_flex_value_sets` | 613 |
| `fnd_attached_documents` | 689 |
| `fnd_lob_access` | 704 |
| `PA.PA_TASKS` | 791 |
| `PA.PA_EXPENDITURE_ITEMS_ALL` | 826 |
| `TASK` | 828 |
| `HR.HR_ALL_ORGANIZATION_UNITS` | 829 |
| `PER_SECURITY_ORGANIZATIONS` | 840 |
| `PER_SECURITY_PROFILES` | 846 |
| `PA.PA_TASKS` | 953 |
| `gl_je_headers` | 997 |
| `hr_operating_units` | 1017 |
| `fnd_flex_value_sets` | 1057 |
| `fnd_concurrent_programs` | 1129 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 67 |
| `fnd_gfm.construct_download_url` | 425 |
| `fnd_gfm.construct_download_url` | 709 |
| `Fnd_File.put_line` | 1141 |
| `Fnd_File.put_line` | 1142 |
| `Fnd_File.put_line` | 1144 |
| `Fnd_File.put_line` | 1146 |
| `Fnd_File.put_line` | 1149 |
| `Fnd_File.put_line` | 1186 |
| `Fnd_File.put_line` | 1201 |
| `Fnd_File.put_line` | 1213 |
| `Fnd_File.put_line` | 1217 |
| `Fnd_File.put_line` | 1256 |
| `Fnd_File.put_line` | 1258 |
| `Fnd_File.put_line` | 1261 |
| `Fnd_File.put_line` | 1263 |
| `Fnd_File.put_line` | 1265 |
| `Fnd_File.put_line` | 1267 |
| `Fnd_File.put_line` | 1269 |
| `Fnd_File.put_line` | 1271 |
| `Fnd_File.put_line` | 1273 |
| `Fnd_File.put_line` | 1275 |
| `Fnd_File.put_line` | 1280 |
| `Fnd_File.put_line` | 1284 |
| `Fnd_File.put_line` | 1288 |
| `Fnd_File.put_line` | 1292 |
| `Fnd_File.put_line` | 1296 |
| `Fnd_File.put_line` | 1300 |
| `Fnd_File.put_line` | 1305 |
| `Fnd_File.put_line` | 1309 |
| `FND_REQUEST.SUBMIT_REQUEST` | 1329 |
| `Fnd_File.put_line` | 1358 |
| `Fnd_File.put_line` | 1362 |
| `Fnd_File.put_line` | 1366 |
| `Fnd_File.put_line` | 1369 |
| `fnd_concurrent.wait_for_request` | 1371 |
| `Fnd_File.put_line` | 1378 |
| `Fnd_File.put_line` | 1383 |
| `Fnd_File.put_line` | 1388 |
| `Fnd_File.put_line` | 1390 |
| `Fnd_File.put_line` | 1393 |
| `Fnd_File.put_line` | 1399 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_COMPRESS_FICHIER` | 1329 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1355 |
| when_others | 438, 452, 476, 721, 735, 757, 896, 918, 1082, 1104, 1136, 1234, 1397 |
| soumission | 1329 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IPAEXT_ENG_HER / DKA | `DKA_IPOEXTENGHERC_PKG.main` | dka/12.0.0/admin/import/DKA_IPAEXT_ENG_HER_PRG.ldt:534 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
