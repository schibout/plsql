# DKA_SFAGENIMMO_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SFAGENIMMO_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SFAGENIMMO_PKG.pkb).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1054 ; encodage : cp1252 (repli). SHA-256 : `82d7b16bdd07b0c3c1e3fcd4ef398951287ed0759a6ad0dcab9ccc1d91f382da`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `GET_MASS_EXPENSE_CCID` | 48 |
| `transfer_immo` | 193 |
| `auto_acquis` | 304 |
| `imput_acquis` | 506 |
| `copie_hvp` | 790 |
| `valider_immo` | 967 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fa_category_books` | 80 |
| `pa_tasks` | 100 |
| `pa.pa_tasks` | 102 |
| `fa_categories` | 120 |
| `hr_operating_units` | 231 |
| `FA_MASS_ADDITIONS` | 313 |
| `hr_operating_units` | 354 |
| `fa_asset_keywords` | 397 |
| `FA_MASSADD_DISTRIBUTIONS` | 426 |
| `FA_MASS_ADDITIONS` | 447 |
| `fnd_req_set_run_form_v` | 536 |
| `hr_operating_units` | 555 |
| `fnd_responsibility` | 567 |
| `fnd_request_sets` | 574 |
| `hr_operating_units` | 829 |
| `fnd_responsibility` | 839 |
| `fnd_user` | 844 |
| `FA_DEPRN_PERIODS` | 860 |
| `FA_DEPRN_PERIODS` | 880 |
| `fnd_responsibility` | 994 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_SPAAUTOACCOUNTING_PKG.uo_projet` | 93 |
| `dka_pa_tools_pkg.get_class_project` | 105 |
| `dka_pa_tools_pkg.get_centre_finance` | 128 |
| `dka_pa_tools_pkg.get_class_project` | 131 |
| `dka_Tools_Pkg.put_log_message` | 143 |
| `Dka_Tools_Pkg.get_code_combination_id` | 147 |
| `dka_Tools_Pkg.put_log_message` | 228 |
| `FND_REQUEST.SET_ORG_ID` | 235 |
| `dka_Tools_Pkg.put_log_message` | 237 |
| `fnd_request.submit_request` | 239 |
| `dka_Tools_Pkg.put_log_message` | 252 |
| `dka_Tools_Pkg.put_log_message` | 256 |
| `dka_Tools_Pkg.put_log_message` | 260 |
| `Fnd_Concurrent.wait_for_request` | 263 |
| `dka_Tools_Pkg.put_log_message` | 264 |
| `dka_Tools_Pkg.put_log_message` | 265 |
| `dka_Tools_Pkg.put_log_message` | 268 |
| `dka_Tools_Pkg.put_log_message` | 272 |
| `dka_Tools_Pkg.put_log_message` | 276 |
| `DKA_SPAAUTOACCOUNTING_PKG.uo_projet` | 317 |
| `dka_Tools_Pkg.put_log_message` | 351 |
| `dka_Tools_Pkg.put_log_message` | 356 |
| `fnd_file.put_line` | 358 |
| `fnd_file.put_line` | 359 |
| `fnd_file.put_line` | 361 |
| `fnd_file.put_line` | 364 |
| `fnd_file.put_line` | 366 |
| `fnd_file.put_line` | 367 |
| `fnd_file.put_line` | 368 |
| `fnd_file.put_line` | 369 |
| `fnd_file.put_line` | 371 |
| `fnd_file.put_line` | 372 |
| `dka_Tools_Pkg.put_log_message` | 389 |
| `dka_Tools_Pkg.put_log_message` | 411 |
| `dka_Tools_Pkg.put_log_message` | 441 |
| `dka_Tools_Pkg.put_log_message` | 446 |
| `fnd_file.put_line` | 457 |
| `fnd_file.put_line` | 460 |
| `fnd_file.put_line` | 472 |
| `fnd_file.put_line` | 475 |
| `fnd_file.put_line` | 476 |
| `fnd_file.put_line` | 477 |
| `fnd_file.put_line` | 478 |
| `dka_Tools_Pkg.put_log_message` | 480 |
| `dka_Tools_Pkg.put_log_message` | 481 |
| `dka_Tools_Pkg.put_log_message` | 482 |
| `dka_Tools_Pkg.put_log_message` | 483 |
| `dka_Tools_Pkg.put_log_message` | 552 |
| `Fnd_Global.apps_initialize` | 577 |
| `Fnd_Submit.set_request_set` | 580 |
| `Dka_Tools_Pkg.put_debug_message` | 582 |
| `DKA_TOOLS_PKG.get_request_set_params` | 589 |
| `Fnd_Submit.set_print_options` | 609 |
| `Dka_Tools_Pkg.put_debug_message` | 616 |
| `Dka_Tools_Pkg.tab_request_params` | 624 |
| `Fnd_Submit.submit_program` | 627 |
| `Dka_Tools_Pkg.tab_request_params` | 631 |
| `Dka_Tools_Pkg.tab_request_params` | 632 |
| `Dka_Tools_Pkg.tab_request_params` | 633 |
| `Dka_Tools_Pkg.tab_request_params` | 634 |
| `Dka_Tools_Pkg.tab_request_params` | 635 |
| `Dka_Tools_Pkg.tab_request_params` | 636 |
| `Dka_Tools_Pkg.tab_request_params` | 637 |
| `Dka_Tools_Pkg.tab_request_params` | 638 |
| `Dka_Tools_Pkg.tab_request_params` | 639 |
| `Dka_Tools_Pkg.tab_request_params` | 640 |
| `Dka_Tools_Pkg.tab_request_params` | 641 |
| `Dka_Tools_Pkg.tab_request_params` | 642 |
| `Dka_Tools_Pkg.tab_request_params` | 643 |
| `Dka_Tools_Pkg.tab_request_params` | 644 |
| `Dka_Tools_Pkg.tab_request_params` | 645 |
| `Dka_Tools_Pkg.tab_request_params` | 646 |
| `Dka_Tools_Pkg.tab_request_params` | 647 |
| `Dka_Tools_Pkg.tab_request_params` | 648 |
| `Dka_Tools_Pkg.tab_request_params` | 649 |
| `Dka_Tools_Pkg.tab_request_params` | 650 |
| `Dka_Tools_Pkg.tab_request_params` | 651 |
| `Dka_Tools_Pkg.tab_request_params` | 652 |
| `Dka_Tools_Pkg.tab_request_params` | 653 |
| `Dka_Tools_Pkg.tab_request_params` | 654 |
| `Dka_Tools_Pkg.tab_request_params` | 655 |
| `Dka_Tools_Pkg.tab_request_params` | 656 |
| `Dka_Tools_Pkg.tab_request_params` | 657 |
| `Dka_Tools_Pkg.tab_request_params` | 658 |
| `Dka_Tools_Pkg.tab_request_params` | 659 |
| `Dka_Tools_Pkg.tab_request_params` | 660 |
| `Dka_Tools_Pkg.tab_request_params` | 661 |
| `Dka_Tools_Pkg.tab_request_params` | 662 |
| `Dka_Tools_Pkg.tab_request_params` | 663 |
| `Dka_Tools_Pkg.tab_request_params` | 664 |
| `Dka_Tools_Pkg.tab_request_params` | 665 |
| `Dka_Tools_Pkg.tab_request_params` | 666 |
| `Dka_Tools_Pkg.tab_request_params` | 667 |
| `Dka_Tools_Pkg.tab_request_params` | 668 |
| `Dka_Tools_Pkg.tab_request_params` | 669 |
| `Dka_Tools_Pkg.tab_request_params` | 670 |
| `Dka_Tools_Pkg.tab_request_params` | 671 |
| `Dka_Tools_Pkg.tab_request_params` | 672 |
| `Dka_Tools_Pkg.tab_request_params` | 673 |
| `Dka_Tools_Pkg.tab_request_params` | 674 |
| `Dka_Tools_Pkg.tab_request_params` | 675 |
| `Dka_Tools_Pkg.tab_request_params` | 676 |
| `Dka_Tools_Pkg.tab_request_params` | 677 |
| `Dka_Tools_Pkg.tab_request_params` | 678 |
| `Dka_Tools_Pkg.tab_request_params` | 679 |
| `Dka_Tools_Pkg.tab_request_params` | 680 |
| `Dka_Tools_Pkg.tab_request_params` | 681 |
| `Dka_Tools_Pkg.tab_request_params` | 682 |
| `Dka_Tools_Pkg.tab_request_params` | 683 |
| `Dka_Tools_Pkg.tab_request_params` | 684 |
| `Dka_Tools_Pkg.tab_request_params` | 685 |
| `Dka_Tools_Pkg.tab_request_params` | 686 |
| `Dka_Tools_Pkg.tab_request_params` | 687 |
| `Dka_Tools_Pkg.tab_request_params` | 688 |
| `Dka_Tools_Pkg.tab_request_params` | 689 |
| `Dka_Tools_Pkg.tab_request_params` | 690 |
| `Dka_Tools_Pkg.tab_request_params` | 691 |
| `Dka_Tools_Pkg.tab_request_params` | 692 |
| `Dka_Tools_Pkg.tab_request_params` | 693 |
| `Dka_Tools_Pkg.tab_request_params` | 694 |
| `Dka_Tools_Pkg.tab_request_params` | 695 |
| `Dka_Tools_Pkg.tab_request_params` | 696 |
| `Dka_Tools_Pkg.tab_request_params` | 697 |
| `Dka_Tools_Pkg.tab_request_params` | 698 |
| `Dka_Tools_Pkg.tab_request_params` | 699 |
| `Dka_Tools_Pkg.tab_request_params` | 700 |
| `Dka_Tools_Pkg.tab_request_params` | 701 |
| `Dka_Tools_Pkg.tab_request_params` | 702 |
| `Dka_Tools_Pkg.tab_request_params` | 703 |
| `Dka_Tools_Pkg.tab_request_params` | 704 |
| `Dka_Tools_Pkg.tab_request_params` | 705 |
| `Dka_Tools_Pkg.tab_request_params` | 706 |
| `Dka_Tools_Pkg.tab_request_params` | 707 |
| `Dka_Tools_Pkg.tab_request_params` | 708 |
| `Dka_Tools_Pkg.tab_request_params` | 709 |
| `Dka_Tools_Pkg.tab_request_params` | 710 |
| `Dka_Tools_Pkg.tab_request_params` | 711 |
| `Dka_Tools_Pkg.tab_request_params` | 712 |
| `Dka_Tools_Pkg.tab_request_params` | 713 |
| `Dka_Tools_Pkg.tab_request_params` | 714 |
| `Dka_Tools_Pkg.tab_request_params` | 715 |
| `Dka_Tools_Pkg.tab_request_params` | 716 |
| `Dka_Tools_Pkg.tab_request_params` | 717 |
| `Dka_Tools_Pkg.tab_request_params` | 718 |
| `Dka_Tools_Pkg.tab_request_params` | 719 |
| `Dka_Tools_Pkg.tab_request_params` | 720 |
| `Dka_Tools_Pkg.tab_request_params` | 721 |
| `Dka_Tools_Pkg.tab_request_params` | 722 |
| `Dka_Tools_Pkg.tab_request_params` | 723 |
| `Dka_Tools_Pkg.tab_request_params` | 724 |
| `Dka_Tools_Pkg.tab_request_params` | 725 |
| `Dka_Tools_Pkg.tab_request_params` | 726 |
| `Dka_Tools_Pkg.tab_request_params` | 727 |
| `Dka_Tools_Pkg.tab_request_params` | 728 |
| `Dka_Tools_Pkg.tab_request_params` | 729 |
| `Dka_Tools_Pkg.tab_request_params` | 730 |
| `Dka_Tools_Pkg.put_debug_message` | 733 |
| `Fnd_Submit.submit_set` | 740 |
| `Dka_Tools_Pkg.put_debug_message` | 746 |
| `dka_Tools_Pkg.put_log_message` | 749 |
| `Fnd_Concurrent.wait_for_request` | 752 |
| `dka_Tools_Pkg.put_log_message` | 753 |
| `dka_Tools_Pkg.put_log_message` | 754 |
| `dka_Tools_Pkg.put_log_message` | 757 |
| `dka_Tools_Pkg.put_log_message` | 759 |
| `dka_Tools_Pkg.put_log_message` | 763 |
| `dka_Tools_Pkg.put_log_message` | 826 |
| `dka_Tools_Pkg.put_log_message` | 834 |
| `dka_Tools_Pkg.put_log_message` | 847 |
| `fnd_global.apps_initialize` | 848 |
| `dka_Tools_Pkg.put_log_message` | 897 |
| `dka_Tools_Pkg.put_log_message` | 901 |
| `dka_Tools_Pkg.put_log_message` | 905 |
| `fnd_request.submit_request` | 906 |
| `dka_Tools_Pkg.put_log_message` | 917 |
| `dka_Tools_Pkg.put_log_message` | 921 |
| `dka_Tools_Pkg.put_log_message` | 925 |
| `Fnd_Concurrent.wait_for_request` | 928 |
| `dka_Tools_Pkg.put_log_message` | 929 |
| `dka_Tools_Pkg.put_log_message` | 930 |
| `dka_Tools_Pkg.put_log_message` | 933 |
| `dka_Tools_Pkg.put_log_message` | 935 |
| `dka_Tools_Pkg.put_log_message` | 939 |
| `dka_Tools_Pkg.put_log_message` | 989 |
| `dka_Tools_Pkg.put_log_message` | 997 |
| `fnd_global.apps_initialize` | 998 |
| `FND_REQUEST.SET_ORG_ID` | 1001 |
| `dka_Tools_Pkg.put_log_message` | 1003 |
| `fnd_request.submit_request` | 1004 |
| `dka_Tools_Pkg.put_log_message` | 1012 |
| `dka_Tools_Pkg.put_log_message` | 1016 |
| `dka_Tools_Pkg.put_log_message` | 1020 |
| `Fnd_Concurrent.wait_for_request` | 1024 |
| `dka_Tools_Pkg.put_log_message` | 1025 |
| `dka_Tools_Pkg.put_log_message` | 1026 |
| `dka_Tools_Pkg.put_log_message` | 1029 |
| `dka_Tools_Pkg.put_log_message` | 1031 |
| `dka_Tools_Pkg.put_log_message` | 1035 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `PAXCPCAL` | 239 |
| `PACFATBP` | 1004 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 259, 468, 742, 924, 1019 |
| when_others | 86, 123, 138, 170, 283, 401, 431, 486, 770, 896, 900, 946, 1042 |
| soumission | 239, 906, 1004 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_FA_AUTOACQ / DKA | `DKA_SFAGENIMMO_PKG.auto_acquis` | dka/12.0.0/admin/import/DKA_FA_AUTOACQ.prt:482 |
| DKA_FA_FAMCP / DKA | `DKA_SFAGENIMMO_PKG.copie_hvp` | dka/12.0.0/admin/import/DKA_FA_FAMCP.prt:481 |
| DKA_FA_FNDRSSUB46 / DKA | `DKA_SFAGENIMMO_PKG.imput_acquis` | dka/12.0.0/admin/import/DKA_FA_FNDRSSUB46.prt:482 |
| DKA_FA_PACFATBP / DKA | `DKA_SFAGENIMMO_PKG.valider_immo` | dka/12.0.0/admin/import/DKA_FA_PACFATBP.prt:484 |
| DKA_FA_PAXCPCAL / DKA | `DKA_SFAGENIMMO_PKG.transfer_immo` | dka/12.0.0/admin/import/DKA_FA_PAXCPCAL.prt:484 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
