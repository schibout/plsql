# DKA_REPGLPIECEREPIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPGLPIECEREPIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPGLPIECEREPIMP_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1809 ; encodage : cp1252 (repli). SHA-256 : `c2880bdaab9695029ea1c87dbdc812f3fb5bfb9110f4fd3aa14167c2a5a0b61c`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 79 |
| `output_header` | 172 |
| `Request_parameters` | 225 |
| `output_end` | 315 |
| `Add_Message` | 345 |
| `Launch_Loader` | 402 |
| `validate_data` | 513 |
| `import_data` | 1062 |
| `Report_Bilan` | 1509 |
| `set_recovery_mode` | 1576 |
| `purge_data` | 1615 |
| `main` | 1656 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 133 |
| `fnd_concurrent_programs` | 187 |
| `fnd_concurrent_requests` | 231 |
| `fnd_concurrent_requests` | 262 |
| `fnd_concurrent_requests` | 279 |
| `DKA_REP_PIECES_TMP` | 463 |
| `DKA_REP_PIECES_TMP` | 567 |
| `GL_LEDGERS` | 598 |
| `GL_LEDGERS` | 622 |
| `Fnd_Flex_Value_Sets` | 637 |
| `GL_JE_CATEGORIES` | 650 |
| `PA_PROJECTS_ALL` | 682 |
| `PA_tasks` | 697 |
| `GL_CODE_COMBINATIONS` | 802 |
| `GL_CODE_COMBINATIONS` | 907 |
| `DKA_REP_PIECES_TMP` | 953 |
| `DKA_REP_PIECES_TMP` | 981 |
| `DKA_REP_PIECES_TMP` | 1006 |
| `DKA_REP_PIECES_TMP` | 1013 |
| `DKA_REP_PIECES_TMP` | 1019 |
| `DKA_REP_PIECES_TMP` | 1074 |
| `DKA_REP_PIECES_TMP` | 1085 |
| `DKA_REP_PIECES_TMP` | 1089 |
| `DKA_REP_PIECES_TMP` | 1108 |
| `DKA_REP_PIECES_TMP` | 1133 |
| `GL_RECURRING_BATCHES` | 1165 |
| `DUAL` | 1185 |
| `GL_RECURRING_BATCHES` | 1190 |
| `DKA_REP_PIECES_TMP` | 1238 |
| `DKA_REP_PIECES_TMP` | 1251 |
| `DUAL` | 1268 |
| `GL_RECURRING_HEADERS` | 1273 |
| `DKA_REP_PIECES_TMP` | 1320 |
| `DKA_REP_PIECES_TMP` | 1334 |
| `GL_RECURRING_LINES` | 1349 |
| `DKA_REP_PIECES_TMP` | 1392 |
| `DKA_REP_PIECES_TMP` | 1408 |
| `GL_RECURRING_LINE_CALC_RULES` | 1422 |
| `DKA_REP_PIECES_TMP` | 1451 |
| `DKA_REP_PIECES_TMP` | 1526 |
| `DKA_REP_PIECES_TMP` | 1532 |
| `DKA_REP_PIECES_TMP` | 1586 |
| `DKA_REP_PIECES_TMP` | 1627 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 93 |
| `Fnd_File.put_line` | 126 |
| `Fnd_File.put_line` | 138 |
| `fnd_file.put_line` | 147 |
| `Fnd_File.put_line` | 202 |
| `Fnd_File.put_line` | 203 |
| `Fnd_File.put_line` | 204 |
| `Fnd_File.put_line` | 205 |
| `Fnd_File.put_line` | 206 |
| `Fnd_File.put_line` | 247 |
| `Fnd_File.put_line` | 248 |
| `Fnd_File.put_line` | 249 |
| `Fnd_File.put_line` | 250 |
| `Fnd_File.put_line` | 267 |
| `Fnd_File.put_line` | 268 |
| `Fnd_File.put_line` | 284 |
| `Fnd_File.put_line` | 285 |
| `Fnd_File.put_line` | 288 |
| `Fnd_File.put_line` | 291 |
| `Fnd_File.put_line` | 292 |
| `Fnd_File.put_line` | 324 |
| `Fnd_File.put_line` | 325 |
| `Fnd_File.put_line` | 326 |
| `Fnd_File.put_line` | 356 |
| `Fnd_File.put_line` | 358 |
| `Fnd_File.put_line` | 360 |
| `Fnd_File.put_line` | 362 |
| `Fnd_File.put_line` | 368 |
| `dka_tools_pkg.ins_prog_message` | 372 |
| `Fnd_File.put_line` | 414 |
| `Fnd_File.put_line` | 415 |
| `fnd_file.put_line` | 418 |
| `fnd_file.put_line` | 419 |
| `fnd_file.put_line` | 420 |
| `fnd_request.set_print_options` | 425 |
| `Fnd_Request.submit_request` | 428 |
| `fnd_file.put_line` | 439 |
| `Fnd_File.put_line` | 442 |
| `Fnd_File.put_line` | 445 |
| `Fnd_File.put_line` | 446 |
| `Fnd_Concurrent.wait_for_request` | 449 |
| `Fnd_file.put_line` | 452 |
| `Fnd_File.put_line` | 458 |
| `Fnd_File.put_line` | 459 |
| `Fnd_File.put_line` | 468 |
| `fnd_file.put_line` | 476 |
| `Fnd_File.put_line` | 479 |
| `Fnd_File.put_line` | 485 |
| `Fnd_File.put_line` | 492 |
| `Fnd_File.put_line` | 493 |
| `Fnd_File.put_line` | 578 |
| `Fnd_File.put_line` | 579 |
| `dka_rep_transco_pkg.get_transco` | 673 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 726 |
| `DKA_REP_TRANSCO_PKG.get_cle_transco` | 758 |
| `Dka_Tools_Pkg.get_code_combination_id` | 783 |
| `DKA_SPAAUTOACCOUNTING_PKG.societe_projet` | 825 |
| `DKA_SPAAUTOACCOUNTING_PKG.uo_projet` | 827 |
| `DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts` | 831 |
| `DKA_SPAAUTOACCOUNTING_PKG.run_cpt_groupe_couts_f` | 835 |
| `Dka_Pa_Tools_Pkg.pa_run_accounting_rule` | 842 |
| `Dka_Spaautoaccounting_Pkg.run_cpt_groupe_produit_f` | 851 |
| `DKA_REP_TRANSCO_PKG.get_complement_compte` | 868 |
| `DKA_SPAAUTOACCOUNTING_PKG.centrefi` | 872 |
| `DKA_SPAAUTOACCOUNTING_PKG.affaire` | 874 |
| `dka_spaautoaccounting_pkg.projetfi` | 876 |
| `DKA_TOOLS_PKG.get_code_combination_id` | 886 |
| `Fnd_File.put_line` | 1033 |
| `Fnd_File.put_line` | 1041 |
| `Fnd_File.put_line` | 1042 |
| `Fnd_File.put_line` | 1149 |
| `Fnd_File.put_line` | 1150 |
| `Fnd_File.put_line` | 1153 |
| `Fnd_File.put_line` | 1154 |
| `Fnd_File.put_line` | 1156 |
| `Fnd_File.put_line` | 1158 |
| `Fnd_File.put_line` | 1171 |
| `Fnd_File.put_line` | 1483 |
| `Fnd_File.put_line` | 1490 |
| `Fnd_File.put_line` | 1491 |
| `Fnd_File.put_line` | 1516 |
| `fnd_file.put_line` | 1536 |
| `fnd_file.put_line` | 1537 |
| `fnd_file.put_line` | 1538 |
| `fnd_file.put_line` | 1540 |
| `fnd_file.put_line` | 1542 |
| `fnd_file.put_line` | 1544 |
| `fnd_file.put_line` | 1546 |
| `fnd_file.put_line` | 1547 |
| `fnd_file.put_line` | 1548 |
| `fnd_file.put_line` | 1549 |
| `fnd_file.put_line` | 1551 |
| `Fnd_File.put_line` | 1552 |
| `Fnd_File.put_line` | 1560 |
| `Fnd_File.put_line` | 1561 |
| `Fnd_File.put_line` | 1598 |
| `Fnd_File.put_line` | 1599 |
| `Fnd_File.Put_Line` | 1623 |
| `Fnd_File.Put_Line` | 1630 |
| `Fnd_File.put_line` | 1637 |
| `Fnd_File.put_line` | 1638 |
| `Fnd_File.put_line` | 1676 |
| `Fnd_File.put_line` | 1682 |
| `Fnd_File.put_line` | 1700 |
| `Fnd_File.put_line` | 1714 |
| `Fnd_File.put_line` | 1781 |
| `Fnd_File.put_line` | 1782 |
| `Fnd_File.put_line` | 1784 |
| `Fnd_File.put_line` | 1792 |
| `Fnd_File.put_line` | 1793 |
| `Fnd_File.put_line` | 1794 |
| `Fnd_File.put_line` | 1795 |
| `Fnd_File.put_line` | 1800 |
| `Fnd_File.put_line` | 1801 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_LOADER_REPGLPIECEREP` | 428 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 444, 1031, 1481, 1778 |
| rollback | 2 |
| when_others | 149, 195, 488, 602, 625, 654, 686, 702, 807, 911, 1037, 1246, 1328, 1402, 1467, 1486, 1556, 1594, 1633, 1796 |
| suppression | 1627 |
| soumission | 428 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPGLPIECEREPIMP / DKA | `DKA_REPGLPIECEREPIMP_PKG.main` | dka/12.0.0/admin/import/DKA_REPGLPIECEREPIMP.prt:496 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
