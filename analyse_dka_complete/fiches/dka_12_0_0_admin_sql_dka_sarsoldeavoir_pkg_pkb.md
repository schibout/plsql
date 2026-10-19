# DKA_SARSOLDEAVOIR_pkg.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARSOLDEAVOIR_pkg.pkb](../../dka/12.0.0/admin/sql/DKA_SARSOLDEAVOIR_pkg.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 923 ; encodage : cp1252 (repli). SHA-256 : `be7d44a9182eac55f176b85d33e64bd9c085a591a3d2b8ea6fe588c1101551b8`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `solde_avoirs_creat_remb` | 38 |
| `main` | 640 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_ar_remboursement_avoirs` | 111 |
| `dka_ar_remboursement_avoirs` | 115 |
| `DKA_ARREMB_REPORTING` | 125 |
| `DKA_ARREMB_REPORTING` | 127 |
| `dka_ar_remboursement_avoirs` | 129 |
| `ra_customer_trx_all` | 154 |
| `apps.fnd_profile_options_vl` | 188 |
| `ar_cash_receipts_all` | 215 |
| `ar_payment_schedules_all` | 238 |
| `AR_RECEIPT_METHODS` | 256 |
| `dka_ar_remboursement_avoirs` | 277 |
| `DKA_ARREMB_REPORTING` | 355 |
| `activity_flag` | 364 |
| `DKA_ARREMB_REPORTING` | 374 |
| `activity_flag` | 383 |
| `ar_cash_receipts_all` | 398 |
| `AR_CASH_RECEIPTS_ALL` | 415 |
| `DKA_ARREMB_REPORTING` | 497 |
| `activity_flag` | 504 |
| `DKA_ARREMB_REPORTING` | 513 |
| `activity_flag` | 520 |
| `ra_customer_trx_all` | 542 |
| `dka_parameters` | 607 |
| `DKA_ARREMB_REPORTING` | 686 |
| `DKA_ARREMB_REPORTING` | 691 |
| `DKA_ARREMB_REPORTING` | 696 |
| `dka_ar_remboursement_avoirs` | 701 |
| `dka_ar_remboursement_avoirs` | 707 |
| `dka_ar_remboursement_avoirs` | 714 |
| `dka_ar_remboursement_avoirs` | 726 |
| `dka_ar_remboursement_avoirs` | 789 |
| `dka_ar_remboursement_avoirs` | 822 |
| `ar_receivables_trx_all` | 856 |
| `dka_ar_remboursement_avoirs` | 891 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 139 |
| `dka_tools_pkg.put_log_message` | 140 |
| `dka_tools_pkg.put_log_message` | 141 |
| `dka_tools_pkg.put_log_message` | 142 |
| `dka_tools_pkg.put_log_message` | 143 |
| `dka_tools_pkg.put_log_message` | 144 |
| `dka_tools_pkg.put_log_message` | 169 |
| `dka_tools_pkg.put_log_message` | 172 |
| `dka_tools_pkg.put_log_message` | 198 |
| `dka_tools_pkg.put_log_message` | 199 |
| `dka_tools_pkg.put_log_message` | 200 |
| `fnd_global.apps_initialize` | 203 |
| `dka_tools_pkg.put_log_message` | 206 |
| `dka_tools_pkg.put_log_message` | 222 |
| `dka_tools_pkg.put_log_message` | 225 |
| `dka_tools_pkg.put_log_message` | 246 |
| `dka_tools_pkg.put_log_message` | 260 |
| `dka_tools_pkg.put_log_message` | 263 |
| `dka_tools_pkg.put_log_message` | 269 |
| `dka_tools_pkg.put_log_message` | 284 |
| `dka_tools_pkg.put_log_message` | 289 |
| `dka_tools_pkg.put_log_message` | 294 |
| `ar_receipt_api_pub.create_cash` | 295 |
| `dka_tools_pkg.put_log_message` | 331 |
| `dka_tools_pkg.put_log_message` | 334 |
| `dka_tools_pkg.put_log_message` | 336 |
| `dka_tools_pkg.put_log_message` | 338 |
| `dka_tools_pkg.put_log_message` | 342 |
| `FND_MSG_PUB.Get` | 346 |
| `dka_tools_pkg.put_log_message` | 347 |
| `dka_tools_pkg.put_log_message` | 352 |
| `dka_tools_pkg.put_log_message` | 364 |
| `dka_tools_pkg.put_log_message` | 365 |
| `dka_tools_pkg.put_log_message` | 383 |
| `dka_tools_pkg.put_log_message` | 384 |
| `dka_tools_pkg.put_log_message` | 390 |
| `dka_tools_pkg.put_log_message` | 405 |
| `dka_tools_pkg.put_log_message` | 408 |
| `dka_tools_pkg.put_log_message` | 441 |
| `dka_tools_pkg.put_log_message` | 443 |
| `dka_tools_pkg.put_log_message` | 445 |
| `dka_tools_pkg.put_log_message` | 447 |
| `dka_tools_pkg.put_log_message` | 453 |
| `ar_receipt_api_pub.apply` | 454 |
| `dka_tools_pkg.put_log_message` | 468 |
| `dka_tools_pkg.put_log_message` | 469 |
| `dka_tools_pkg.put_log_message` | 471 |
| `dka_tools_pkg.put_log_message` | 473 |
| `dka_tools_pkg.put_log_message` | 475 |
| `dka_tools_pkg.put_log_message` | 482 |
| `dka_tools_pkg.put_log_message` | 484 |
| `fnd_msg_pub.get` | 487 |
| `dka_tools_pkg.put_log_message` | 493 |
| `dka_tools_pkg.put_log_message` | 504 |
| `dka_tools_pkg.put_log_message` | 505 |
| `dka_tools_pkg.put_log_message` | 509 |
| `dka_tools_pkg.put_log_message` | 520 |
| `dka_tools_pkg.put_log_message` | 521 |
| `dka_tools_pkg.put_log_message` | 528 |
| `dka_tools_pkg.put_log_message` | 538 |
| `dka_tools_pkg.put_log_message` | 539 |
| `dka_tools_pkg.put_log_message` | 540 |
| `dka_tools_pkg.put_log_message` | 556 |
| `fnd_request.submit_request` | 558 |
| `dka_tools_pkg.put_log_message` | 569 |
| `dka_tools_pkg.put_log_message` | 572 |
| `fnd_concurrent.wait_for_request` | 574 |
| `Dka_Tools_Pkg.put_log_message` | 587 |
| `Dka_Tools_Pkg.put_log_message` | 590 |
| `Dka_Tools_Pkg.put_log_message` | 593 |
| `Dka_Tools_Pkg.put_log_message` | 598 |
| `dka_tools_pkg.put_log_message` | 621 |
| `dka_tools_pkg.put_log_message` | 678 |
| `dka_tools_pkg.put_log_message` | 720 |
| `dka_tools_pkg.put_log_message` | 730 |
| `fnd_file.put_line` | 731 |
| `fnd_file.put_line` | 733 |
| `fnd_file.put_line` | 734 |
| `fnd_file.put_line` | 736 |
| `fnd_file.put_line` | 738 |
| `fnd_file.put_line` | 740 |
| `fnd_file.put_line` | 742 |
| `fnd_file.put_line` | 744 |
| `fnd_file.put_line` | 750 |
| `fnd_file.put_line` | 752 |
| `fnd_file.put_line` | 754 |
| `fnd_file.put_line` | 761 |
| `fnd_file.put_line` | 763 |
| `fnd_file.put_line` | 765 |
| `fnd_file.put_line` | 771 |
| `fnd_file.put_line` | 773 |
| `fnd_file.put_line` | 775 |
| `fnd_file.put_line` | 777 |
| `fnd_file.put_line` | 779 |
| `fnd_file.put_line` | 781 |
| `fnd_file.put_line` | 792 |
| `fnd_file.put_line` | 804 |
| `fnd_file.put_line` | 806 |
| `fnd_file.put_line` | 808 |
| `fnd_file.put_line` | 810 |
| `fnd_file.put_line` | 812 |
| `fnd_file.put_line` | 814 |
| `fnd_file.put_line` | 827 |
| `fnd_file.put_line` | 841 |
| `fnd_file.put_line` | 843 |
| `fnd_file.put_line` | 845 |
| `fnd_file.put_line` | 847 |
| `fnd_file.put_line` | 849 |
| `fnd_file.put_line` | 851 |
| `fnd_file.put_line` | 866 |
| `fnd_file.put_line` | 873 |
| `fnd_file.put_line` | 875 |
| `fnd_file.put_line` | 877 |
| `fnd_file.put_line` | 879 |
| `fnd_file.put_line` | 881 |
| `fnd_file.put_line` | 883 |
| `fnd_file.put_line` | 893 |
| `dka_tools_pkg.put_log_message` | 905 |
| `dka_tools_pkg.put_log_message` | 915 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_SLAUNCHER` | 558 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 131, 360, 388, 478, 526, 546, 566, 612 |
| rollback | 908 |
| when_others | 167, 245, 283, 363, 382, 403, 438, 503, 519, 619, 914 |
| suppression | 125 |
| soumission | 558 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARSOLDEAVOIR / DKA | `DKA_SARSOLDEAVOIR_PKG.main` | dka/12.0.0/admin/import/DKA_SARSOLDEAVOIR.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
