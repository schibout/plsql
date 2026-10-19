# DKA_XLA_FA_CUSTOM_SOURCES_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_XLA_FA_CUSTOM_SOURCES_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_XLA_FA_CUSTOM_SOURCES_PKG.pkb).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1759 ; encodage : cp1252 (repli). SHA-256 : `de2e5535af7f4109bbc1b6cb03c1802f100811aaa175411351b2d82024968563`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Trace` | 52 |
| `Trace` | 64 |
| `Init_Module` | 75 |
| `Init_Module` | 97 |
| `Exit_Module` | 106 |
| `Exit_Module` | 117 |
| `get_Segment_Column_Name` | 133 |
| `is_TAX_Book` | 198 |
| `is_IFRS_Category` | 258 |
| `get_IFRS_account` | 362 |
| `get_Project_Number` | 689 |
| `get_Task_Number` | 756 |
| `is_f44` | 812 |
| `is_f60` | 872 |
| `is_category_name` | 947 |
| `get_SOCIAL_account` | 1010 |
| `GET_FA_PROV_LOCAL` | 1075 |
| `GET_FA_PROV_GROUPE` | 1122 |
| `GET_FA_PROV_ANNUL_LOCAL` | 1175 |
| `GET_FA_PROV_ANNUL_GROUPE` | 1223 |
| `DKA_FA_RETIRT_SUBIPR_DOT_LOC` | 1277 |
| `DKA_FA_RETIRT_SUBIPR_DOT_GP` | 1325 |
| `DKA_FA_RETIRT_SUBIPR_DOT_AN_LO` | 1379 |
| `DKA_FA_RETIRT_SUBIPR_DOT_AN_GP` | 1426 |
| `DKA_FA_NBV_RETIRED_LOSS_GP_SEG` | 1479 |
| `DKA_FA_RECLASS_NIFRS_IFRS` | 1535 |
| `get_RECLASS_IFRS_account` | 1688 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_ledgers` | 160 |
| `fnd_segment_attribute_values` | 161 |
| `fa_book_controls` | 226 |
| `fa_categories_vl` | 286 |
| `fa_category_books` | 291 |
| `fa_book_controls` | 292 |
| `fa_category_books` | 408 |
| `fa_book_controls` | 409 |
| `gl_code_combinations_kfv` | 412 |
| `fa_category_books` | 459 |
| `fa_book_controls` | 460 |
| `dka_stransco_headers` | 472 |
| `dka_stransco_lines` | 473 |
| `fa_category_books` | 480 |
| `fa_book_controls` | 481 |
| `fa_category_books` | 504 |
| `fa_book_controls` | 505 |
| `fa_category_books` | 523 |
| `fa_book_controls` | 524 |
| `gl_code_combinations_kfv` | 527 |
| `dka_stransco_headers` | 567 |
| `dka_stransco_lines` | 568 |
| `pa_projects_all` | 715 |
| `fa_invoice_details_v` | 716 |
| `fa_invoice_details_v` | 720 |
| `pa_tasks` | 782 |
| `fa_invoice_details_v` | 783 |
| `fa_invoice_details_v` | 787 |
| `fa_book_controls` | 831 |
| `fa_categories_vl` | 843 |
| `fa_book_controls` | 891 |
| `fa_categories_vl` | 903 |
| `fa_categories_vl` | 961 |
| `fa_category_books` | 1045 |
| `fa_book_controls` | 1046 |
| `gl_code_combinations_kfv` | 1049 |
| `FA_CATEGORIES_VL` | 1097 |
| `DKA_STRANSCO_LINES` | 1145 |
| `DKA_STRANSCO_HEADERS` | 1147 |
| `FA_CATEGORIES_VL` | 1150 |
| `FA_CATEGORIES_VL` | 1197 |
| `DKA_STRANSCO_LINES` | 1246 |
| `DKA_STRANSCO_HEADERS` | 1248 |
| `FA_CATEGORIES_VL` | 1251 |
| `FA_CATEGORIES_VL` | 1299 |
| `DKA_STRANSCO_LINES` | 1348 |
| `DKA_STRANSCO_HEADERS` | 1350 |
| `FA_CATEGORIES_VL` | 1353 |
| `FA_CATEGORIES_VL` | 1401 |
| `DKA_STRANSCO_LINES` | 1449 |
| `DKA_STRANSCO_HEADERS` | 1451 |
| `FA_CATEGORIES_VL` | 1454 |
| `DKA_STRANSCO_LINES` | 1504 |
| `DKA_STRANSCO_HEADERS` | 1506 |
| `FA_BOOK_CONTROLS` | 1509 |
| `fa_category_books` | 1561 |
| `fa_category_books` | 1563 |
| `fa_category_books` | 1571 |
| `xla_events` | 1582 |
| `xla_events` | 1719 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_log.string` | 58 |
| `Fnd_Profile.Put` | 80 |
| `Fnd_Profile.Put` | 81 |
| `Fnd_Profile.Put` | 82 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 63, 96, 116, 180, 241, 308, 596, 739, 807, 865, 925, 987, 1071, 1117, 1170, 1217, 1271, 1319, 1373, 1421, 1474, 1530, 1633, 1752 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
