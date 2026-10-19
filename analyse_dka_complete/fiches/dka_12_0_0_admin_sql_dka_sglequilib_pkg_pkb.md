# DKA_SGLEQUILIB_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SGLEQUILIB_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SGLEQUILIB_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2273 ; encodage : cp1252 (repli). SHA-256 : `4679748a2c8054716b5348525b3439da793eaf33a28d08412962686a34899af0`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_code_combination_id` | 98 |
| `get_first_char` | 123 |
| `Init` | 147 |
| `launch_request` | 258 |
| `wait_GLPRJE` | 387 |
| `wait_GLPAUTOP` | 466 |
| `wait_GLPOS` | 522 |
| `delete_batch` | 595 |
| `delete_header` | 636 |
| `delete_lines` | 805 |
| `check_data` | 849 |
| `run_posting` | 1051 |
| `check_param` | 1090 |
| `Get_Rec_Header_id` | 1193 |
| `Get_line_num` | 1359 |
| `get_code_combination_id` | 1555 |
| `insert_param` | 1607 |
| `update_num_line` | 1976 |
| `update_num_line` | 2074 |
| `main` | 2096 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dual` | 179 |
| `dual` | 183 |
| `gl_automatic_posting_sets` | 192 |
| `gl_je_categories_tl` | 234 |
| `gl_recurring_batches` | 269 |
| `gl_recurring_headers` | 274 |
| `gl_recurring_headers` | 290 |
| `Fnd_conc_req_summary_v` | 542 |
| `gl_je_batches_v` | 609 |
| `gl_je_headers_v` | 740 |
| `gl_je_lines_v` | 820 |
| `gl_je_headers` | 857 |
| `gl_je_headers` | 867 |
| `gl_je_batches` | 879 |
| `gl_je_headers` | 888 |
| `gl_code_combinations_kfv` | 1096 |
| `GL_RECURRING_LINE_CALC_RULES` | 1102 |
| `hr_operating_units` | 1130 |
| `gl_recurring_headers` | 1217 |
| `GL_LEDGERS` | 1249 |
| `gl_recurring_headers` | 1384 |
| `gl_recurring_headers` | 1422 |
| `Gl_Recurring_Lines` | 1479 |
| `gl_code_combinations` | 1576 |
| `gl_code_combinations_kfv` | 1616 |
| `GL_RECURRING_LINE_CALC_RULES` | 1633 |
| `FND_FLEX_VALUES_VL` | 1655 |
| `hr_operating_units` | 1662 |
| `GL_RECURRING_LINE_CALC_RULES` | 1698 |
| `GL_RECURRING_LINE_CALC_RULES` | 1740 |
| `GL_RECURRING_LINE_CALC_RULES` | 1811 |
| `GL_RECURRING_LINE_CALC_RULES` | 1845 |
| `GL_RECURRING_LINE_CALC_RULES` | 1856 |
| `gl_recurring_headers` | 1989 |
| `gl_recurring_lines` | 2019 |
| `gl_recurring_lines` | 2024 |
| `gl_recurring_line_calc_rules` | 2030 |
| `gl_recurring_lines` | 2049 |
| `gl_recurring_lines` | 2054 |
| `gl_recurring_line_calc_rules` | 2059 |
| `gl_access_set_assignments` | 2102 |
| `gl_summary_templates_v` | 2158 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 157 |
| `Fnd_Profile.VALUE` | 175 |
| `Fnd_Profile.VALUE` | 181 |
| `Dka_tools_pkg.put_debug_message` | 185 |
| `Dka_Tools_Pkg.get_parameter` | 187 |
| `dka_tools_pkg.put_debug_message` | 188 |
| `Dka_tools_pkg.put_debug_message` | 198 |
| `Dka_Tools_Pkg.get_parameter` | 200 |
| `Dka_tools_pkg.put_debug_message` | 203 |
| `Dka_Tools_Pkg.get_parameter` | 205 |
| `Dka_Tools_Pkg.get_parameter` | 208 |
| `Dka_Tools_Pkg.get_parameter` | 211 |
| `Dka_Tools_Pkg.get_parameter` | 214 |
| `Dka_Tools_Pkg.get_parameter` | 217 |
| `Dka_Tools_Pkg.get_parameter` | 220 |
| `Dka_Tools_Pkg.get_parameter` | 226 |
| `Dka_Tools_Pkg.get_parameter` | 229 |
| `Dka_tools_pkg.put_debug_message` | 238 |
| `dka_tools_pkg.put_debug_message` | 308 |
| `dka_tools_pkg.put_debug_message` | 310 |
| `dka_tools_pkg.put_debug_message` | 318 |
| `Fnd_Request.Submit_Request` | 320 |
| `dka_tools_pkg.put_outdebug_message` | 341 |
| `dka_tools_pkg.put_outdebug_message` | 342 |
| `dka_tools_pkg.put_outdebug_message` | 343 |
| `dka_tools_pkg.put_debug_message` | 350 |
| `dka_tools_pkg.put_debug_message` | 364 |
| `dka_tools_pkg.put_debug_message` | 403 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 407 |
| `dka_tools_pkg.put_debug_message` | 418 |
| `dka_tools_pkg.put_debug_message` | 419 |
| `dka_tools_pkg.put_debug_message` | 420 |
| `dka_tools_pkg.put_debug_message` | 421 |
| `dka_tools_pkg.put_debug_message` | 422 |
| `dka_tools_pkg.put_debug_message` | 423 |
| `dka_tools_pkg.put_debug_message` | 424 |
| `dka_tools_pkg.put_debug_message` | 439 |
| `dka_tools_pkg.put_outdebug_message` | 450 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 482 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 551 |
| `GL_JE_BATCHES_PKG.Delete_Row` | 614 |
| `GL_JE_HEADERS_PKG.Delete_Row` | 747 |
| `dka_tools_pkg.put_outdebug_message` | 780 |
| `GL_JE_LINES_PKG.Delete_Row` | 828 |
| `dka_tools_pkg.put_debug_message` | 907 |
| `dka_tools_pkg.put_debug_message` | 911 |
| `dka_tools_pkg.put_outdebug_message` | 919 |
| `dka_tools_pkg.put_outdebug_message` | 928 |
| `Dka_Sglequilib_pkg.delete_batch` | 929 |
| `dka_tools_pkg.put_debug_message` | 943 |
| `dka_tools_pkg.put_outdebug_message` | 952 |
| `Dka_Sglequilib_pkg.delete_header` | 955 |
| `dka_tools_pkg.put_outdebug_message` | 981 |
| `Dka_Sglequilib_pkg.delete_lines` | 984 |
| `dka_tools_pkg.put_debug_message` | 1029 |
| `Fnd_Request.Submit_Request` | 1053 |
| `dka_tools_pkg.put_outdebug_message` | 1071 |
| `dka_tools_pkg.put_outdebug_message` | 1072 |
| `dka_tools_pkg.put_debug_message` | 1143 |
| `dka_tools_pkg.put_outdebug_message` | 1156 |
| `dka_tools_pkg.put_outdebug_message` | 1163 |
| `dka_tools_pkg.put_debug_message` | 1172 |
| `dka_tools_pkg.put_debug_message` | 1206 |
| `dka_tools_pkg.put_debug_message` | 1234 |
| `dka_tools_pkg.put_outdebug_message` | 1240 |
| `dka_tools_pkg.put_outdebug_message` | 1252 |
| `GL_RECURRING_BATCHES_PKG.Insert_Row` | 1254 |
| `dka_tools_pkg.put_outdebug_message` | 1289 |
| `gl_recurring_headers_pkg.insert_row` | 1291 |
| `Fnd_Profile.VALUE` | 1305 |
| `dka_tools_pkg.put_outdebug_message` | 1325 |
| `dka_tools_pkg.put_outdebug_message` | 1332 |
| `dka_tools_pkg.put_debug_message` | 1334 |
| `dka_tools_pkg.put_debug_message` | 1339 |
| `dka_tools_pkg.put_debug_message` | 1374 |
| `dka_tools_pkg.put_debug_message` | 1375 |
| `dka_tools_pkg.put_debug_message` | 1376 |
| `dka_tools_pkg.put_debug_message` | 1377 |
| `dka_tools_pkg.put_outdebug_message` | 1399 |
| `dka_tools_pkg.put_debug_message` | 1401 |
| `dka_tools_pkg.put_outdebug_message` | 1416 |
| `dka_tools_pkg.put_debug_message` | 1429 |
| `dka_tools_pkg.put_outdebug_message` | 1444 |
| `Dka_Tools_Pkg.get_code_combination_id` | 1452 |
| `dka_tools_pkg.put_debug_message` | 1470 |
| `dka_tools_pkg.put_debug_message` | 1471 |
| `dka_tools_pkg.put_outdebug_message` | 1474 |
| `dka_tools_pkg.put_debug_message` | 1478 |
| `Fnd_Profile.VALUE` | 1499 |
| `dka_tools_pkg.put_outdebug_message` | 1502 |
| `dka_tools_pkg.put_outdebug_message` | 1506 |
| `dka_tools_pkg.put_outdebug_message` | 1512 |
| `dka_tools_pkg.put_outdebug_message` | 1515 |
| `dka_tools_pkg.put_debug_message` | 1522 |
| `dka_tools_pkg.put_outdebug_message` | 1573 |
| `dka_tools_pkg.put_outdebug_message` | 1586 |
| `dka_tools_pkg.put_debug_message` | 1671 |
| `dka_tools_pkg.put_outdebug_message` | 1675 |
| `dka_tools_pkg.put_outdebug_message` | 1676 |
| `dka_tools_pkg.put_debug_message` | 1688 |
| `dka_tools_pkg.put_debug_message` | 1693 |
| `dka_tools_pkg.put_debug_message` | 1703 |
| `dka_tools_pkg.put_debug_message` | 1726 |
| `dka_tools_pkg.put_debug_message` | 1731 |
| `Fnd_Profile.VALUE` | 1785 |
| `Fnd_Profile.VALUE` | 1835 |
| `Fnd_Profile.VALUE` | 1901 |
| `dka_tools_pkg.put_debug_message` | 1931 |
| `dka_tools_pkg.put_debug_message` | 1932 |
| `dka_tools_pkg.put_outdebug_message` | 1938 |
| `dka_tools_pkg.put_debug_message` | 1943 |
| `dka_tools_pkg.put_outdebug_message` | 2124 |
| `dka_tools_pkg.put_outdebug_message` | 2125 |
| `dka_tools_pkg.put_outdebug_message` | 2126 |
| `dka_tools_pkg.put_outdebug_message` | 2128 |
| `dka_tools_pkg.put_outdebug_message` | 2130 |
| `dka_tools_pkg.put_outdebug_message` | 2131 |
| `dka_tools_pkg.put_outdebug_message` | 2132 |
| `dka_tools_pkg.put_outdebug_message` | 2142 |
| `dka_tools_pkg.put_outdebug_message` | 2151 |
| `dka_tools_pkg.put_outdebug_message` | 2152 |
| `dka_tools_pkg.put_outdebug_message` | 2163 |
| `dka_tools_pkg.put_outdebug_message` | 2166 |
| `dka_tools_pkg.put_outdebug_message` | 2171 |
| `dka_tools_pkg.put_outdebug_message` | 2172 |
| `dka_tools_pkg.put_outdebug_message` | 2173 |
| `dka_tools_pkg.put_outdebug_message` | 2174 |
| `dka_tools_pkg.put_outdebug_message` | 2175 |
| `dka_tools_pkg.put_outdebug_message` | 2184 |
| `dka_tools_pkg.put_outdebug_message` | 2185 |
| `dka_tools_pkg.put_outdebug_message` | 2186 |
| `dka_tools_pkg.put_outdebug_message` | 2187 |
| `dka_tools_pkg.put_outdebug_message` | 2188 |
| `dka_tools_pkg.put_outdebug_message` | 2201 |
| `dka_tools_pkg.put_debug_message` | 2204 |
| `dka_tools_pkg.put_debug_message` | 2205 |
| `dka_tools_pkg.put_outdebug_message` | 2210 |
| `dka_tools_pkg.put_outdebug_message` | 2211 |
| `dka_tools_pkg.put_outdebug_message` | 2212 |
| `dka_tools_pkg.put_outdebug_message` | 2213 |
| `dka_tools_pkg.put_outdebug_message` | 2214 |
| `dka_tools_pkg.put_outdebug_message` | 2232 |
| `dka_tools_pkg.put_outdebug_message` | 2233 |
| `dka_tools_pkg.put_outdebug_message` | 2234 |
| `dka_tools_pkg.put_outdebug_message` | 2235 |
| `dka_tools_pkg.put_outdebug_message` | 2236 |
| `dka_tools_pkg.put_outdebug_message` | 2247 |
| `dka_tools_pkg.put_debug_message` | 2259 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `GLPRJE` | 320 |
| `GLPAUTOP` | 1053 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 362, 1066, 1952, 2070 |
| rollback | 1958, 2076, 2257, 2263 |
| when_others | 241, 367, 446, 502, 572, 576, 619, 786, 832, 1033, 1174, 1336, 1520, 1522, 1590, 1946, 1955, 2073, 2261 |
| soumission | 320, 1053 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SGLEQUILIB / DKA | `DKA_SGLEQUILIB_PKG.main` | dka/12.0.0/admin/import/DKA_SGLEQUILIB.prt:483 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
