# DKA_REPGLSOLDESIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPGLSOLDESIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPGLSOLDESIMP_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2310 ; encodage : cp1252 (repli). SHA-256 : `49ad869396da06e680de8eea1dee5d5c6438b4fc8aaa9dacc0760e646c382161`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 74 |
| `init_environement` | 113 |
| `Launch_Loader` | 157 |
| `Transco_Segments` | 278 |
| `Transco_Unite_Operationnelle` | 400 |
| `purge_data_oi` | 435 |
| `insert_gl_interface` | 465 |
| `Control_Data` | 499 |
| `CONTROL_DATA` | 1273 |
| `insert_open_interface` | 1290 |
| `program_import_gl_soldes` | 1672 |
| `Report_Bilan` | 1823 |
| `MAIN` | 1877 |
| `MAIN2` | 2111 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility_vl` | 123 |
| `DKA_GL_REPSOLDE_TMP` | 238 |
| `DKA_GL_CONTREPASSATION_TMP` | 244 |
| `DKA_GL_REPSOLDE_TMP` | 294 |
| `DKA_GL_REPSOLDE_TMP` | 329 |
| `DKA_GL_REPSOLDE_TMP` | 362 |
| `DKA_GL_REPSOLDE_TMP` | 413 |
| `GL_INTERFACE` | 443 |
| `GL_INTERFACE` | 470 |
| `DKA_GL_REPSOLDE_TMP` | 525 |
| `DKA_GL_CONTREPASSATION_TMP` | 536 |
| `DKA_GL_REPSOLDE_TMP` | 549 |
| `DKA_GL_CONTREPASSATION_TMP` | 554 |
| `GL_JE_SOURCES` | 569 |
| `GL_JE_CATEGORIES` | 584 |
| `GL_LEDGERS` | 615 |
| `fnd_flex_value_sets` | 798 |
| `DKA_GL_REPSOLDE_TMP` | 837 |
| `GL_LEDGERS` | 881 |
| `pa_projects_all` | 1110 |
| `pa_tasks` | 1136 |
| `fnd_flex_value_sets` | 1174 |
| `DKA_GL_CONTREPASSATION_TMP` | 1209 |
| `DKA_GL_REPSOLDE_TMP` | 1242 |
| `DKA_GL_REPSOLDE_TMP` | 1247 |
| `DKA_GL_CONTREPASSATION_TMP` | 1254 |
| `DKA_GL_CONTREPASSATION_TMP` | 1259 |
| `DKA_GL_REPSOLDE_TMP` | 1306 |
| `DKA_GL_CONTREPASSATION_TMP` | 1319 |
| `GL_PERIODS` | 1356 |
| `GL_INTERFACE` | 1465 |
| `DKA_GL_REPSOLDE_TMP` | 1468 |
| `GL_PERIODS` | 1488 |
| `GL_PERIODS` | 1489 |
| `pa_projects_all` | 1572 |
| `pa_tasks` | 1603 |
| `GL_INTERFACE` | 1635 |
| `DKA_GL_CONTREPASSATION_TMP` | 1638 |
| `GL_INTERFACE` | 1647 |
| `GL_INTERFACE` | 1691 |
| `GL_INTERFACE_CONTROL` | 1697 |
| `GL_JE_SOURCES` | 1698 |
| `gl_interface_control` | 1722 |
| `gl_ledgers` | 1723 |
| `gl_je_sources` | 1725 |
| `gl_interface` | 1765 |
| `gl_interface` | 1769 |
| `gl_interface` | 1785 |
| `DKA_GL_REPSOLDE_TMP` | 1959 |
| `DKA_GL_CONTREPASSATION_TMP` | 2184 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 78 |
| `dka_tools_pkg.put_log_message` | 95 |
| `fnd_global.apps_initialize` | 130 |
| `dka_tools_pkg.put_outdebug_message` | 134 |
| `dka_tools_pkg.put_log_message` | 175 |
| `dka_tools_pkg.put_log_message` | 177 |
| `dka_tools_pkg.put_log_message` | 178 |
| `dka_tools_pkg.put_log_message` | 179 |
| `Fnd_Request.submit_request` | 186 |
| `dka_tools_pkg.put_outdebug_message` | 198 |
| `dka_tools_pkg.put_log_message` | 201 |
| `dka_tools_pkg.put_outdebug_message` | 202 |
| `Fnd_Concurrent.wait_for_request` | 205 |
| `dka_tools_pkg.put_outdebug_message` | 209 |
| `dka_tools_pkg.put_outdebug_message` | 212 |
| `dka_tools_pkg.put_log_message` | 216 |
| `dka_tools_pkg.put_log_message` | 219 |
| `dka_tools_pkg.put_outdebug_message` | 225 |
| `dka_tools_pkg.put_log_message` | 250 |
| `dka_tools_pkg.put_log_message` | 256 |
| `dka_tools_pkg.put_outdebug_message` | 257 |
| `dka_tools_pkg.put_log_message` | 298 |
| `DKA_REP_TRANSCO_PKG.get_cle_transco` | 304 |
| `DKA_REP_TRANSCO_PKG.get_cle_transco` | 338 |
| `dka_tools_pkg.put_log_message` | 380 |
| `Dka_Tools_Pkg.put_log_message` | 406 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 408 |
| `Dka_Tools_Pkg.put_log_message` | 418 |
| `dka_tools_pkg.put_log_message` | 441 |
| `dka_tools_pkg.put_log_message` | 446 |
| `dka_tools_pkg.put_log_message` | 447 |
| `dka_tools_pkg.put_outdebug_message` | 478 |
| `dka_tools_pkg.put_log_message` | 479 |
| `dka_tools_pkg.put_outdebug_message` | 576 |
| `dka_tools_pkg.put_log_message` | 577 |
| `dka_tools_pkg.put_outdebug_message` | 591 |
| `dka_tools_pkg.put_log_message` | 592 |
| `DKA_REP_TRANSCO_PKG.get_cle_transco` | 647 |
| `DKA_REP_TRANSCO_PKG.get_cle_transco` | 671 |
| `DKA_REP_TRANSCO_PKG.get_cle_transco` | 700 |
| `DKA_REP_TRANSCO_PKG.get_cle_transco` | 729 |
| `DKA_REP_TRANSCO_PKG.get_cle_transco` | 913 |
| `DKA_REP_TRANSCO_PKG.get_cle_transco` | 939 |
| `DKA_REP_TRANSCO_PKG.get_cle_transco` | 969 |
| `DKA_REP_TRANSCO_PKG.get_cle_transco` | 999 |
| `DKA_REP_TRANSCO_PKG.get_transco_f` | 1074 |
| `dka_tools_pkg.put_outdebug_message` | 1252 |
| `dka_tools_pkg.put_outdebug_message` | 1264 |
| `dka_tools_pkg.put_log_message` | 1273 |
| `dka_tools_pkg.put_log_message` | 1334 |
| `dka_tools_pkg.put_outdebug_message` | 1361 |
| `dka_tools_pkg.put_log_message` | 1362 |
| `dka_tools_pkg.put_outdebug_message` | 1496 |
| `dka_tools_pkg.put_log_message` | 1497 |
| `Dka_Tools_Pkg.put_log_message` | 1504 |
| `Dka_Tools_Pkg.IS_BANK_HOLIDAY` | 1505 |
| `Dka_Tools_Pkg.Get_Next_Working_Day` | 1508 |
| `dka_tools_pkg.put_outdebug_message` | 1652 |
| `dka_tools_pkg.put_log_message` | 1655 |
| `dka_tools_pkg.put_log_message` | 1700 |
| `GL_JOURNAL_IMPORT_PKG.populate_interface_control` | 1709 |
| `fnd_request.submit_request` | 1730 |
| `FND_PROFILE.VALUE` | 1736 |
| `dka_tools_pkg.put_outdebug_message` | 1748 |
| `dka_tools_pkg.put_outdebug_message` | 1752 |
| `Fnd_Concurrent.wait_for_request` | 1757 |
| `dka_tools_pkg.put_outdebug_message` | 1761 |
| `dka_tools_pkg.put_outdebug_message` | 1777 |
| `dka_tools_pkg.put_outdebug_message` | 1778 |
| `dka_tools_pkg.put_outdebug_message` | 1779 |
| `dka_tools_pkg.put_outdebug_message` | 1780 |
| `dka_tools_pkg.put_outdebug_message` | 1781 |
| `dka_tools_pkg.put_outdebug_message` | 1782 |
| `dka_tools_pkg.put_outdebug_message` | 1794 |
| `dka_tools_pkg.put_outdebug_message` | 1795 |
| `dka_tools_pkg.put_outdebug_message` | 1829 |
| `dka_tools_pkg.put_outdebug_message` | 1839 |
| `dka_tools_pkg.put_outdebug_message` | 1840 |
| `dka_tools_pkg.put_outdebug_message` | 1841 |
| `dka_tools_pkg.put_outdebug_message` | 1842 |
| `dka_tools_pkg.put_outdebug_message` | 1843 |
| `dka_tools_pkg.put_outdebug_message` | 1844 |
| `dka_tools_pkg.put_outdebug_message` | 1845 |
| `dka_tools_pkg.put_outdebug_message` | 1846 |
| `dka_tools_pkg.put_outdebug_message` | 1847 |
| `dka_tools_pkg.put_outdebug_message` | 1848 |
| `dka_tools_pkg.put_outdebug_message` | 1849 |
| `dka_tools_pkg.put_outdebug_message` | 1851 |
| `dka_tools_pkg.put_outdebug_message` | 1852 |
| `dka_tools_pkg.put_log_message` | 1859 |
| `dka_tools_pkg.put_outdebug_message` | 1860 |
| `dka_tools_pkg.put_outdebug_message` | 1912 |
| `dka_tools_pkg.put_outdebug_message` | 1913 |
| `dka_tools_pkg.put_log_message` | 1919 |
| `dka_tools_pkg.put_log_message` | 1933 |
| `dka_tools_pkg.put_log_message` | 1934 |
| `dka_tools_pkg.put_log_message` | 1935 |
| `dka_tools_pkg.put_outdebug_message` | 1951 |
| `dka_tools_pkg.put_log_message` | 1955 |
| `dka_tools_pkg.put_log_message` | 1968 |
| `dka_tools_pkg.put_log_message` | 1969 |
| `dka_tools_pkg.put_log_message` | 1970 |
| `dka_tools_pkg.put_log_message` | 2015 |
| `dka_tools_pkg.put_log_message` | 2028 |
| `dka_tools_pkg.put_log_message` | 2029 |
| `dka_tools_pkg.put_log_message` | 2030 |
| `dka_tools_pkg.put_log_message` | 2040 |
| `dka_tools_pkg.put_log_message` | 2056 |
| `dka_tools_pkg.put_log_message` | 2057 |
| `dka_tools_pkg.put_log_message` | 2058 |
| `dka_tools_pkg.put_log_message` | 2059 |
| `dka_tools_pkg.put_log_message` | 2066 |
| `dka_tools_pkg.put_log_message` | 2067 |
| `dka_tools_pkg.put_log_message` | 2068 |
| `dka_tools_pkg.put_log_message` | 2069 |
| `dka_tools_pkg.put_log_message` | 2070 |
| `dka_tools_pkg.put_log_message` | 2071 |
| `dka_tools_pkg.put_log_message` | 2072 |
| `dka_tools_pkg.put_log_message` | 2073 |
| `dka_tools_pkg.put_outdebug_message` | 2074 |
| `dka_tools_pkg.put_log_message` | 2081 |
| `dka_tools_pkg.put_log_message` | 2082 |
| `dka_tools_pkg.put_log_message` | 2083 |
| `dka_tools_pkg.put_log_message` | 2084 |
| `dka_tools_pkg.put_log_message` | 2085 |
| `dka_tools_pkg.put_log_message` | 2086 |
| `dka_tools_pkg.put_log_message` | 2087 |
| `dka_tools_pkg.put_log_message` | 2088 |
| `dka_tools_pkg.put_outdebug_message` | 2089 |
| `dka_tools_pkg.put_log_message` | 2090 |
| `dka_tools_pkg.put_outdebug_message` | 2145 |
| `dka_tools_pkg.put_outdebug_message` | 2146 |
| `dka_tools_pkg.put_log_message` | 2152 |
| `dka_tools_pkg.put_log_message` | 2166 |
| `dka_tools_pkg.put_log_message` | 2167 |
| `dka_tools_pkg.put_log_message` | 2168 |
| `dka_tools_pkg.put_outdebug_message` | 2176 |
| `dka_tools_pkg.put_log_message` | 2180 |
| `dka_tools_pkg.put_log_message` | 2195 |
| `dka_tools_pkg.put_log_message` | 2196 |
| `dka_tools_pkg.put_log_message` | 2197 |
| `dka_tools_pkg.put_log_message` | 2223 |
| `dka_tools_pkg.put_log_message` | 2238 |
| `dka_tools_pkg.put_log_message` | 2239 |
| `dka_tools_pkg.put_log_message` | 2240 |
| `dka_tools_pkg.put_log_message` | 2252 |
| `dka_tools_pkg.put_log_message` | 2268 |
| `dka_tools_pkg.put_log_message` | 2269 |
| `dka_tools_pkg.put_log_message` | 2270 |
| `dka_tools_pkg.put_log_message` | 2271 |
| `dka_tools_pkg.put_log_message` | 2278 |
| `dka_tools_pkg.put_log_message` | 2279 |
| `dka_tools_pkg.put_log_message` | 2280 |
| `dka_tools_pkg.put_log_message` | 2281 |
| `dka_tools_pkg.put_log_message` | 2282 |
| `dka_tools_pkg.put_log_message` | 2283 |
| `dka_tools_pkg.put_log_message` | 2284 |
| `dka_tools_pkg.put_log_message` | 2285 |
| `dka_tools_pkg.put_outdebug_message` | 2286 |
| `dka_tools_pkg.put_log_message` | 2293 |
| `dka_tools_pkg.put_log_message` | 2294 |
| `dka_tools_pkg.put_log_message` | 2295 |
| `dka_tools_pkg.put_log_message` | 2296 |
| `dka_tools_pkg.put_log_message` | 2297 |
| `dka_tools_pkg.put_log_message` | 2298 |
| `dka_tools_pkg.put_log_message` | 2299 |
| `dka_tools_pkg.put_log_message` | 2300 |
| `dka_tools_pkg.put_outdebug_message` | 2301 |
| `dka_tools_pkg.put_log_message` | 2302 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `GLLEZL` | 1730 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 200, 379, 561, 859, 1234, 1268, 1470, 1640, 1751, 1802, 2014, 2054, 2222, 2266 |
| rollback | 135, 2075, 2091, 2287, 2303 |
| when_others | 253, 477, 573, 588, 624, 890, 1114, 1140, 1271, 1360, 1495, 1856, 2077, 2289 |
| suppression | 443, 1697, 1769 |
| soumission | 186, 1730 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPGLCONTREPA / DKA | `DKA_REPGLSOLDESIMP_PKG.MAIN2` | dka/12.0.0/admin/import/DKA_REPGLCONTREPA.prt:554 |
| DKA_REPGLSOLDESIMP / DKA | `DKA_REPGLSOLDESIMP_PKG.MAIN` | dka/12.0.0/admin/import/DKA_REPGLSOLDESIMP.prt:488 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
