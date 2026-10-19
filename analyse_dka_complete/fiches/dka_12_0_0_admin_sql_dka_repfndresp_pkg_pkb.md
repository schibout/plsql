# DKA_REPFNDRESP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPFNDRESP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPFNDRESP_PKG.pkb).

Famille proposée par convention de nommage : **FND / administration**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1159 ; encodage : cp1252 (repli). SHA-256 : `2284d1b78f2d40e8f235a164f3acd2badd06da069cbf2622316cb18fe03da9f7`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 77 |
| `output_header` | 158 |
| `Request_parameters` | 208 |
| `output_end` | 306 |
| `print_errors` | 334 |
| `Launch_Loader` | 395 |
| `validate_data` | 540 |
| `create_data` | 741 |
| `Report_Bilan` | 853 |
| `set_recovery_mode` | 913 |
| `purge_data` | 946 |
| `main` | 982 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 121 |
| `fnd_concurrent_programs` | 170 |
| `fnd_concurrent_requests` | 212 |
| `fnd_concurrent_requests` | 243 |
| `fnd_concurrent_requests` | 265 |
| `DKA_PROGRAM_MESSAGES` | 345 |
| `DKA_REP_RESP` | 471 |
| `DKA_REP_RESP` | 477 |
| `DKA_REP_RESP` | 544 |
| `FND_USER_RESP_GROUPS` | 581 |
| `FND_RESPONSIBILITY_VL` | 612 |
| `fnd_user` | 639 |
| `FND_APPLICATION_TL` | 666 |
| `DKA_REP_RESP` | 691 |
| `DKA_REP_RESP` | 698 |
| `DKA_REP_RESP` | 753 |
| `OF` | 763 |
| `DKA_REP_RESP` | 792 |
| `DKA_REP_RESP` | 810 |
| `DKA_REP_RESP` | 919 |
| `DKA_REP_RESP` | 951 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 86 |
| `fnd_profile.value` | 104 |
| `dka_tools_pkg.put_log_message` | 114 |
| `dka_tools_pkg.put_log_message` | 125 |
| `dka_tools_pkg.put_log_message` | 135 |
| `dka_tools_pkg.put_outdebug_message` | 182 |
| `dka_tools_pkg.put_outdebug_message` | 183 |
| `dka_tools_pkg.put_outdebug_message` | 185 |
| `dka_tools_pkg.put_outdebug_message` | 187 |
| `dka_tools_pkg.put_outdebug_message` | 190 |
| `dka_tools_pkg.put_outdebug_message` | 228 |
| `dka_tools_pkg.put_outdebug_message` | 229 |
| `dka_tools_pkg.put_log_message` | 230 |
| `dka_tools_pkg.put_log_message` | 231 |
| `dka_tools_pkg.put_outdebug_message` | 249 |
| `dka_tools_pkg.put_log_message` | 252 |
| `dka_tools_pkg.put_outdebug_message` | 271 |
| `dka_tools_pkg.put_log_message` | 274 |
| `dka_tools_pkg.put_outdebug_message` | 279 |
| `dka_tools_pkg.put_outdebug_message` | 282 |
| `dka_tools_pkg.put_log_message` | 283 |
| `dka_tools_pkg.put_outdebug_message` | 312 |
| `dka_tools_pkg.put_outdebug_message` | 313 |
| `dka_tools_pkg.put_outdebug_message` | 316 |
| `dka_tools_pkg.put_outdebug_message` | 352 |
| `dka_tools_pkg.put_outdebug_message` | 353 |
| `dka_tools_pkg.put_outdebug_message` | 355 |
| `dka_tools_pkg.put_outdebug_message` | 358 |
| `dka_tools_pkg.put_outdebug_message` | 359 |
| `dka_tools_pkg.put_outdebug_message` | 362 |
| `dka_tools_pkg.put_log_message` | 371 |
| `dka_tools_pkg.put_log_message` | 372 |
| `dka_tools_pkg.put_log_message` | 404 |
| `dka_tools_pkg.put_log_message` | 407 |
| `dka_tools_pkg.put_outdebug_message` | 411 |
| `dka_tools_pkg.put_outdebug_message` | 412 |
| `dka_tools_pkg.put_outdebug_message` | 413 |
| `fnd_request.set_print_options` | 418 |
| `Fnd_Request.submit_request` | 421 |
| `dka_tools_pkg.put_log_message` | 434 |
| `dka_tools_pkg.put_outdebug_message` | 438 |
| `dka_tools_pkg.put_log_message` | 442 |
| `dka_tools_pkg.put_outdebug_message` | 444 |
| `Fnd_Concurrent.wait_for_request` | 449 |
| `dka_tools_pkg.put_log_message` | 458 |
| `dka_tools_pkg.put_log_message` | 464 |
| `dka_tools_pkg.put_outdebug_message` | 467 |
| `dka_tools_pkg.put_log_message` | 479 |
| `dka_tools_pkg.put_log_message` | 485 |
| `dka_tools_pkg.put_log_message` | 495 |
| `dka_tools_pkg.put_outdebug_message` | 501 |
| `dka_tools_pkg.put_log_message` | 508 |
| `dka_tools_pkg.put_log_message` | 516 |
| `dka_tools_pkg.put_log_message` | 517 |
| `dka_tools_pkg.put_log_message` | 560 |
| `dka_tools_pkg.ins_prog_message` | 590 |
| `dka_tools_pkg.ins_prog_message` | 622 |
| `dka_tools_pkg.ins_prog_message` | 649 |
| `dka_tools_pkg.ins_prog_message` | 677 |
| `dka_tools_pkg.put_log_message` | 710 |
| `dka_tools_pkg.put_log_message` | 718 |
| `dka_tools_pkg.put_log_message` | 719 |
| `dka_tools_pkg.put_log_message` | 772 |
| `dka_tools_pkg.put_log_message` | 776 |
| `FND_USER_PKG.addresp` | 781 |
| `dka_tools_pkg.put_log_message` | 803 |
| `dka_tools_pkg.put_log_message` | 824 |
| `dka_tools_pkg.put_log_message` | 832 |
| `dka_tools_pkg.put_log_message` | 833 |
| `dka_tools_pkg.put_log_message` | 857 |
| `dka_tools_pkg.put_outdebug_message` | 869 |
| `dka_tools_pkg.put_outdebug_message` | 870 |
| `dka_tools_pkg.put_outdebug_message` | 871 |
| `dka_tools_pkg.put_outdebug_message` | 872 |
| `dka_tools_pkg.put_outdebug_message` | 875 |
| `dka_tools_pkg.put_outdebug_message` | 878 |
| `dka_tools_pkg.put_outdebug_message` | 883 |
| `dka_tools_pkg.put_log_message` | 884 |
| `dka_tools_pkg.put_log_message` | 892 |
| `dka_tools_pkg.put_log_message` | 893 |
| `dka_tools_pkg.put_log_message` | 925 |
| `dka_tools_pkg.put_log_message` | 926 |
| `dka_tools_pkg.put_log_message` | 950 |
| `dka_tools_pkg.put_log_message` | 952 |
| `dka_tools_pkg.put_log_message` | 959 |
| `dka_tools_pkg.put_log_message` | 960 |
| `dka_tools_pkg.put_log_message` | 999 |
| `dka_tools_pkg.put_log_message` | 1006 |
| `dka_tools_pkg.put_log_message` | 1038 |
| `dka_tools_pkg.put_log_message` | 1056 |
| `dka_tools_pkg.put_log_message` | 1070 |
| `dka_tools_pkg.put_log_message` | 1099 |
| `dka_tools_pkg.put_log_message` | 1121 |
| `dka_tools_pkg.put_outdebug_message` | 1122 |
| `dka_tools_pkg.put_log_message` | 1124 |
| `dka_tools_pkg.put_log_message` | 1132 |
| `dka_tools_pkg.put_outdebug_message` | 1133 |
| `dka_tools_pkg.put_log_message` | 1134 |
| `dka_tools_pkg.put_outdebug_message` | 1138 |
| `dka_tools_pkg.put_log_message` | 1145 |
| `dka_tools_pkg.put_outdebug_message` | 1149 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_LOADER_REPFNDRESP` | 421 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 441, 708, 822 |
| rollback | 2 |
| when_others | 137, 177, 370, 513, 602, 618, 645, 673, 715, 800, 829, 889, 922, 956, 1142 |
| suppression | 951 |
| soumission | 421 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPFNDRESP / DKA | `DKA_REPFNDRESP_PKG.main` | dka/12.0.0/admin/import/DKA_REPFNDRESP.prt:481 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
