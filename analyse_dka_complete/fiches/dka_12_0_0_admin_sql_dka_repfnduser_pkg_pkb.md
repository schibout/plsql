# DKA_REPFNDUSER_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPFNDUSER_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPFNDUSER_PKG.pkb).

Famille proposée par convention de nommage : **FND / administration**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1047 ; encodage : cp1252 (repli). SHA-256 : `51da3f7f3e10d2a510546a765a7d3a77cdce8f41a23d6bf8871b61bce82d2938`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 81 |
| `output_header` | 162 |
| `Request_parameters` | 212 |
| `output_end` | 310 |
| `print_errors` | 338 |
| `Launch_Loader` | 393 |
| `validate_data` | 538 |
| `create_data` | 596 |
| `Report_Bilan` | 734 |
| `set_recovery_mode` | 797 |
| `purge_data` | 830 |
| `main` | 866 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 125 |
| `fnd_concurrent_programs` | 174 |
| `fnd_concurrent_requests` | 216 |
| `fnd_concurrent_requests` | 247 |
| `fnd_concurrent_requests` | 269 |
| `DKA_REP_USERS` | 342 |
| `DKA_REP_USERS` | 469 |
| `DKA_REP_USERS` | 475 |
| `DKA_REP_USERS` | 547 |
| `FND_USER` | 549 |
| `PER_ALL_PEOPLE_F` | 551 |
| `USER_ID` | 559 |
| `DKA_REP_USERS` | 599 |
| `OF` | 602 |
| `DKA_REP_USERS` | 656 |
| `USER` | 659 |
| `DKA_REP_USERS` | 669 |
| `DKA_REP_USERS` | 682 |
| `DKA_REP_USERS` | 694 |
| `DKA_REP_USERS` | 803 |
| `DKA_REP_USERS` | 835 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 90 |
| `fnd_profile.value` | 108 |
| `dka_tools_pkg.put_log_message` | 118 |
| `dka_tools_pkg.put_log_message` | 129 |
| `dka_tools_pkg.put_log_message` | 139 |
| `dka_tools_pkg.put_outdebug_message` | 186 |
| `dka_tools_pkg.put_outdebug_message` | 187 |
| `dka_tools_pkg.put_outdebug_message` | 189 |
| `dka_tools_pkg.put_outdebug_message` | 191 |
| `dka_tools_pkg.put_outdebug_message` | 194 |
| `dka_tools_pkg.put_outdebug_message` | 232 |
| `dka_tools_pkg.put_outdebug_message` | 233 |
| `dka_tools_pkg.put_log_message` | 234 |
| `dka_tools_pkg.put_log_message` | 235 |
| `dka_tools_pkg.put_outdebug_message` | 253 |
| `dka_tools_pkg.put_log_message` | 256 |
| `dka_tools_pkg.put_outdebug_message` | 275 |
| `dka_tools_pkg.put_log_message` | 278 |
| `dka_tools_pkg.put_outdebug_message` | 283 |
| `dka_tools_pkg.put_outdebug_message` | 286 |
| `dka_tools_pkg.put_log_message` | 287 |
| `dka_tools_pkg.put_outdebug_message` | 316 |
| `dka_tools_pkg.put_outdebug_message` | 317 |
| `dka_tools_pkg.put_outdebug_message` | 320 |
| `dka_tools_pkg.put_outdebug_message` | 350 |
| `dka_tools_pkg.put_outdebug_message` | 351 |
| `dka_tools_pkg.put_outdebug_message` | 353 |
| `dka_tools_pkg.put_outdebug_message` | 356 |
| `dka_tools_pkg.put_outdebug_message` | 357 |
| `dka_tools_pkg.put_outdebug_message` | 361 |
| `dka_tools_pkg.put_log_message` | 369 |
| `dka_tools_pkg.put_log_message` | 370 |
| `dka_tools_pkg.put_log_message` | 402 |
| `dka_tools_pkg.put_log_message` | 405 |
| `dka_tools_pkg.put_outdebug_message` | 409 |
| `dka_tools_pkg.put_outdebug_message` | 410 |
| `dka_tools_pkg.put_outdebug_message` | 411 |
| `fnd_request.set_print_options` | 416 |
| `Fnd_Request.submit_request` | 419 |
| `dka_tools_pkg.put_log_message` | 432 |
| `dka_tools_pkg.put_outdebug_message` | 436 |
| `dka_tools_pkg.put_log_message` | 440 |
| `dka_tools_pkg.put_outdebug_message` | 442 |
| `Fnd_Concurrent.wait_for_request` | 447 |
| `dka_tools_pkg.put_log_message` | 456 |
| `dka_tools_pkg.put_log_message` | 462 |
| `dka_tools_pkg.put_outdebug_message` | 465 |
| `dka_tools_pkg.put_log_message` | 477 |
| `dka_tools_pkg.put_log_message` | 483 |
| `dka_tools_pkg.put_log_message` | 493 |
| `dka_tools_pkg.put_outdebug_message` | 499 |
| `dka_tools_pkg.put_log_message` | 506 |
| `dka_tools_pkg.put_log_message` | 514 |
| `dka_tools_pkg.put_log_message` | 515 |
| `dka_tools_pkg.put_log_message` | 543 |
| `dka_tools_pkg.put_log_message` | 560 |
| `dka_tools_pkg.put_log_message` | 562 |
| `dka_tools_pkg.put_log_message` | 565 |
| `dka_tools_pkg.put_log_message` | 573 |
| `dka_tools_pkg.put_log_message` | 574 |
| `dka_tools_pkg.put_log_message` | 611 |
| `dka_tools_pkg.put_log_message` | 615 |
| `dka_tools_pkg.put_log_message` | 621 |
| `FND_USER_PKG.CreateUser` | 623 |
| `dka_tools_pkg.put_log_message` | 705 |
| `dka_tools_pkg.put_log_message` | 713 |
| `dka_tools_pkg.put_log_message` | 714 |
| `dka_tools_pkg.put_log_message` | 738 |
| `dka_tools_pkg.put_outdebug_message` | 750 |
| `dka_tools_pkg.put_outdebug_message` | 751 |
| `dka_tools_pkg.put_outdebug_message` | 752 |
| `dka_tools_pkg.put_outdebug_message` | 753 |
| `dka_tools_pkg.put_outdebug_message` | 756 |
| `dka_tools_pkg.put_outdebug_message` | 759 |
| `dka_tools_pkg.put_outdebug_message` | 762 |
| `dka_tools_pkg.put_outdebug_message` | 767 |
| `dka_tools_pkg.put_log_message` | 768 |
| `dka_tools_pkg.put_log_message` | 776 |
| `dka_tools_pkg.put_log_message` | 777 |
| `dka_tools_pkg.put_log_message` | 809 |
| `dka_tools_pkg.put_log_message` | 810 |
| `dka_tools_pkg.put_log_message` | 834 |
| `dka_tools_pkg.put_log_message` | 836 |
| `dka_tools_pkg.put_log_message` | 843 |
| `dka_tools_pkg.put_log_message` | 844 |
| `dka_tools_pkg.put_log_message` | 883 |
| `dka_tools_pkg.put_log_message` | 890 |
| `dka_tools_pkg.put_log_message` | 926 |
| `dka_tools_pkg.put_log_message` | 944 |
| `dka_tools_pkg.put_log_message` | 958 |
| `dka_tools_pkg.put_log_message` | 987 |
| `dka_tools_pkg.put_log_message` | 1009 |
| `dka_tools_pkg.put_outdebug_message` | 1010 |
| `dka_tools_pkg.put_log_message` | 1012 |
| `dka_tools_pkg.put_log_message` | 1020 |
| `dka_tools_pkg.put_outdebug_message` | 1021 |
| `dka_tools_pkg.put_log_message` | 1022 |
| `dka_tools_pkg.put_outdebug_message` | 1026 |
| `dka_tools_pkg.put_log_message` | 1033 |
| `dka_tools_pkg.put_outdebug_message` | 1037 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_LOADER_REPFNDUSER` | 419 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 439, 562, 563 |
| rollback | 2 |
| when_others | 141, 181, 368, 511, 570, 690, 710, 773, 806, 840, 1030 |
| suppression | 835 |
| soumission | 419 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPFNDUSER / DKA | `DKA_REPFNDUSER_PKG.main` | dka/12.0.0/admin/import/DKA_REPFNDUSER.prt:480 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
