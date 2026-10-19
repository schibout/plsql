# DKA_REPPOACHIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPPOACHIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPPOACHIMP_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1016 ; encodage : cp1252 (repli). SHA-256 : `5ec797b3eef2ca0354ce38cf957239bb649c76947b2889b3116239990f29c843`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 70 |
| `output_header` | 152 |
| `Request_parameters` | 202 |
| `output_end` | 300 |
| `print_errors` | 328 |
| `Launch_Loader` | 376 |
| `validate_data` | 521 |
| `create_data` | 598 |
| `Report_Bilan` | 707 |
| `set_recovery_mode` | 769 |
| `purge_data` | 802 |
| `main` | 839 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 115 |
| `fnd_concurrent_programs` | 164 |
| `fnd_concurrent_requests` | 206 |
| `fnd_concurrent_requests` | 237 |
| `fnd_concurrent_requests` | 259 |
| `DKA_PROGRAM_MESSAGES` | 332 |
| `DKA_REP_ACHETEURS` | 452 |
| `DKA_REP_ACHETEURS` | 458 |
| `DKA_REP_ACHETEURS` | 525 |
| `per_all_people_f` | 543 |
| `per_all_people_f` | 545 |
| `DKA_REP_ACHETEURS` | 547 |
| `DKA_REP_ACHETEURS` | 563 |
| `DKA_REP_ACHETEURS` | 602 |
| `DKA_REP_ACHETEURS` | 655 |
| `DKA_REP_ACHETEURS` | 673 |
| `DKA_REP_ACHETEURS` | 775 |
| `DKA_REP_ACHETEURS` | 807 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 79 |
| `fnd_profile.value` | 97 |
| `Fnd_File.put_line` | 108 |
| `Fnd_File.put_line` | 119 |
| `fnd_file.put_line` | 129 |
| `Fnd_File.put_line` | 176 |
| `Fnd_File.put_line` | 177 |
| `Fnd_File.put_line` | 179 |
| `Fnd_File.put_line` | 181 |
| `Fnd_File.put_line` | 184 |
| `Fnd_File.put_line` | 222 |
| `Fnd_File.put_line` | 223 |
| `Fnd_File.put_line` | 224 |
| `Fnd_File.put_line` | 225 |
| `Fnd_File.put_line` | 243 |
| `Fnd_File.put_line` | 246 |
| `Fnd_File.put_line` | 265 |
| `Fnd_File.put_line` | 268 |
| `Fnd_File.put_line` | 273 |
| `Fnd_File.put_line` | 276 |
| `Fnd_File.put_line` | 277 |
| `Fnd_File.put_line` | 306 |
| `Fnd_File.put_line` | 307 |
| `Fnd_File.put_line` | 310 |
| `fnd_file.put_line` | 339 |
| `fnd_file.put_line` | 340 |
| `fnd_file.put_line` | 342 |
| `fnd_file.put_line` | 344 |
| `fnd_file.put_line` | 345 |
| `Fnd_File.put_line` | 349 |
| `Fnd_File.put_line` | 385 |
| `Fnd_File.put_line` | 388 |
| `fnd_file.put_line` | 392 |
| `fnd_file.put_line` | 393 |
| `fnd_file.put_line` | 394 |
| `fnd_request.set_print_options` | 399 |
| `Fnd_Request.submit_request` | 402 |
| `fnd_file.put_line` | 415 |
| `Fnd_File.put_line` | 419 |
| `Fnd_File.put_line` | 423 |
| `Fnd_File.put_line` | 425 |
| `Fnd_Concurrent.wait_for_request` | 430 |
| `Fnd_file.put_line` | 439 |
| `Fnd_File.put_line` | 445 |
| `Fnd_File.put_line` | 448 |
| `Fnd_File.put_line` | 460 |
| `Fnd_File.put_line` | 466 |
| `fnd_file.put_line` | 476 |
| `Fnd_File.put_line` | 482 |
| `Fnd_File.put_line` | 489 |
| `Fnd_File.put_line` | 497 |
| `Fnd_File.put_line` | 498 |
| `Fnd_File.put_line` | 550 |
| `dka_tools_pkg.ins_prog_message` | 551 |
| `Fnd_File.put_line` | 575 |
| `Fnd_File.put_line` | 576 |
| `PO_AGENTS_PKG.Insert_Row` | 627 |
| `Fnd_File.put_line` | 661 |
| `dka_tools_pkg.ins_prog_message` | 662 |
| `Fnd_File.put_line` | 686 |
| `Fnd_File.put_line` | 687 |
| `Fnd_File.put_line` | 711 |
| `fnd_file.put_line` | 723 |
| `fnd_file.put_line` | 724 |
| `fnd_file.put_line` | 725 |
| `fnd_file.put_line` | 726 |
| `fnd_file.put_line` | 729 |
| `fnd_file.put_line` | 732 |
| `fnd_file.put_line` | 739 |
| `Fnd_File.put_line` | 740 |
| `Fnd_File.put_line` | 748 |
| `Fnd_File.put_line` | 749 |
| `Fnd_File.put_line` | 781 |
| `Fnd_File.put_line` | 782 |
| `Fnd_File.Put_Line` | 806 |
| `Fnd_File.Put_Line` | 808 |
| `Fnd_File.put_line` | 815 |
| `Fnd_File.put_line` | 816 |
| `Fnd_File.put_line` | 856 |
| `Fnd_File.put_line` | 863 |
| `Fnd_File.put_line` | 882 |
| `Fnd_File.put_line` | 895 |
| `Fnd_File.put_line` | 913 |
| `Fnd_File.put_line` | 927 |
| `Fnd_File.put_line` | 956 |
| `Fnd_File.put_line` | 978 |
| `Fnd_File.put_line` | 979 |
| `Fnd_File.put_line` | 981 |
| `Fnd_File.put_line` | 989 |
| `Fnd_File.put_line` | 990 |
| `Fnd_File.put_line` | 991 |
| `Fnd_File.put_line` | 995 |
| `Fnd_File.put_line` | 1002 |
| `Fnd_File.put_line` | 1006 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_LOADER_REPPOACHIMP` | 402 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 422, 569, 680 |
| rollback | 2 |
| when_others | 131, 171, 494, 549, 572, 660, 683, 745, 778, 812, 999 |
| suppression | 807 |
| soumission | 402 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPPOACHIMP / DKA | `DKA_REPPOACHIMP_PKG.main` | dka/12.0.0/admin/import/DKA_REPPOACHIMP.prt:438 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
