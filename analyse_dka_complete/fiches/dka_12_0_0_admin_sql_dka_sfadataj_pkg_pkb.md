# DKA_SFADATAJ_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SFADATAJ_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SFADATAJ_PKG.pkb).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1231 ; encodage : utf-8. SHA-256 : `67c62af4bcf3717396a161fcafdc005fd85670c3d5b7768035c4578dc04f1b7a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `generer_comptes` | 54 |
| `calcul_values` | 183 |
| `transfer_immo` | 304 |
| `imput_acquis` | 493 |
| `copie_hvp` | 836 |
| `valider_immo` | 1083 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fa_books` | 63 |
| `fnd_responsibility` | 96 |
| `fa_books` | 191 |
| `fnd_responsibility` | 224 |
| `PER_SECURITY_ORGANIZATIONS` | 315 |
| `fnd_responsibility` | 356 |
| `PA_PERIODS_ALL` | 373 |
| `FA_BOOK_CONTROLS_SEC` | 501 |
| `FA_MASS_ADDITIONS` | 504 |
| `fnd_req_set_run_form_v` | 533 |
| `fnd_responsibility` | 570 |
| `fnd_request_sets` | 577 |
| `FA_BOOK_CONTROLS_SEC` | 845 |
| `PER_SECURITY_ORGANIZATIONS` | 851 |
| `PER_SECURITY_PROFILES` | 854 |
| `fnd_responsibility` | 909 |
| `fnd_user` | 914 |
| `FA_DEPRN_PERIODS` | 935 |
| `FA_DEPRN_PERIODS` | 955 |
| `PER_SECURITY_ORGANIZATIONS_V` | 1091 |
| `fnd_responsibility` | 1129 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_Tools_Pkg.put_log_message` | 91 |
| `dka_Tools_Pkg.put_log_message` | 99 |
| `fnd_global.apps_initialize` | 100 |
| `Fnd_Request.submit_request` | 110 |
| `dka_Tools_Pkg.put_log_message` | 119 |
| `dka_Tools_Pkg.put_log_message` | 127 |
| `Fnd_Concurrent.wait_for_request` | 135 |
| `dka_Tools_Pkg.put_log_message` | 136 |
| `dka_Tools_Pkg.put_log_message` | 137 |
| `dka_Tools_Pkg.put_log_message` | 140 |
| `dka_Tools_Pkg.put_log_message` | 143 |
| `dka_Tools_Pkg.put_log_message` | 146 |
| `dka_Tools_Pkg.put_log_message` | 153 |
| `dka_tools_pkg.put_log_message` | 154 |
| `dka_Tools_Pkg.put_log_message` | 155 |
| `dka_tools_pkg.put_log_message` | 156 |
| `dka_tools_pkg.put_log_message` | 157 |
| `dka_tools_pkg.put_log_message` | 158 |
| `dka_tools_pkg.put_log_message` | 159 |
| `dka_tools_pkg.put_log_message` | 160 |
| `dka_Tools_Pkg.put_log_message` | 161 |
| `dka_Tools_Pkg.put_log_message` | 162 |
| `dka_Tools_Pkg.put_log_message` | 219 |
| `dka_Tools_Pkg.put_log_message` | 227 |
| `fnd_global.apps_initialize` | 228 |
| `dka_Tools_Pkg.put_log_message` | 245 |
| `fnd_request.submit_request` | 246 |
| `dka_Tools_Pkg.put_log_message` | 257 |
| `dka_Tools_Pkg.put_log_message` | 265 |
| `Fnd_Concurrent.wait_for_request` | 273 |
| `dka_Tools_Pkg.put_log_message` | 274 |
| `dka_Tools_Pkg.put_log_message` | 275 |
| `dka_Tools_Pkg.put_log_message` | 278 |
| `dka_Tools_Pkg.put_log_message` | 281 |
| `dka_Tools_Pkg.put_log_message` | 284 |
| `dka_Tools_Pkg.put_log_message` | 292 |
| `dka_tools_pkg.put_log_message` | 293 |
| `dka_Tools_Pkg.put_log_message` | 294 |
| `dka_tools_pkg.put_log_message` | 295 |
| `dka_tools_pkg.put_log_message` | 296 |
| `dka_tools_pkg.put_log_message` | 297 |
| `dka_tools_pkg.put_log_message` | 298 |
| `dka_tools_pkg.put_log_message` | 299 |
| `dka_Tools_Pkg.put_log_message` | 300 |
| `dka_Tools_Pkg.put_log_message` | 301 |
| `fnd_profile.value` | 347 |
| `dka_Tools_Pkg.put_log_message` | 351 |
| `dka_Tools_Pkg.put_log_message` | 359 |
| `fnd_global.apps_initialize` | 360 |
| `FND_REQUEST.SET_ORG_ID` | 368 |
| `dka_Tools_Pkg.put_log_message` | 380 |
| `dka_Tools_Pkg.put_log_message` | 384 |
| `fnd_request.submit_request` | 386 |
| `dka_Tools_Pkg.put_log_message` | 400 |
| `dka_Tools_Pkg.put_log_message` | 408 |
| `dka_Tools_Pkg.put_log_message` | 415 |
| `Fnd_Concurrent.wait_for_request` | 422 |
| `dka_Tools_Pkg.put_log_message` | 423 |
| `dka_Tools_Pkg.put_log_message` | 424 |
| `dka_Tools_Pkg.put_log_message` | 427 |
| `dka_Tools_Pkg.put_log_message` | 430 |
| `dka_Tools_Pkg.put_log_message` | 433 |
| `dka_Tools_Pkg.put_log_message` | 442 |
| `dka_tools_pkg.put_log_message` | 443 |
| `dka_Tools_Pkg.put_log_message` | 444 |
| `dka_tools_pkg.put_log_message` | 445 |
| `dka_tools_pkg.put_log_message` | 446 |
| `dka_tools_pkg.put_log_message` | 447 |
| `dka_tools_pkg.put_log_message` | 448 |
| `dka_tools_pkg.put_log_message` | 449 |
| `dka_Tools_Pkg.put_log_message` | 450 |
| `Fnd_File.put_line` | 452 |
| `Fnd_File.put_line` | 453 |
| `Fnd_File.put_line` | 454 |
| `Fnd_File.put_line` | 455 |
| `Fnd_File.put_line` | 456 |
| `Fnd_File.put_line` | 457 |
| `Fnd_File.put_line` | 458 |
| `Fnd_File.put_line` | 459 |
| `Fnd_File.put_line` | 460 |
| `Fnd_Global.apps_initialize` | 580 |
| `Fnd_Submit.set_request_set` | 586 |
| `Dka_Tools_Pkg.put_debug_message` | 588 |
| `DKA_TOOLS_PKG.get_request_set_params` | 596 |
| `Fnd_Submit.set_print_options` | 616 |
| `Dka_Tools_Pkg.put_debug_message` | 623 |
| `Dka_Tools_Pkg.tab_request_params` | 631 |
| `Fnd_Submit.submit_program` | 634 |
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
| `Dka_Tools_Pkg.tab_request_params` | 731 |
| `Dka_Tools_Pkg.tab_request_params` | 732 |
| `Dka_Tools_Pkg.tab_request_params` | 733 |
| `Dka_Tools_Pkg.tab_request_params` | 734 |
| `Dka_Tools_Pkg.tab_request_params` | 735 |
| `Dka_Tools_Pkg.tab_request_params` | 736 |
| `Dka_Tools_Pkg.tab_request_params` | 737 |
| `Dka_Tools_Pkg.put_debug_message` | 740 |
| `Fnd_Submit.submit_set` | 747 |
| `Dka_Tools_Pkg.put_debug_message` | 753 |
| `dka_Tools_Pkg.put_log_message` | 760 |
| `Fnd_Concurrent.wait_for_request` | 767 |
| `dka_Tools_Pkg.put_log_message` | 768 |
| `dka_Tools_Pkg.put_log_message` | 769 |
| `dka_Tools_Pkg.put_log_message` | 772 |
| `dka_Tools_Pkg.put_log_message` | 775 |
| `dka_Tools_Pkg.put_log_message` | 778 |
| `dka_Tools_Pkg.put_log_message` | 786 |
| `dka_tools_pkg.put_log_message` | 787 |
| `dka_Tools_Pkg.put_log_message` | 788 |
| `dka_tools_pkg.put_log_message` | 789 |
| `dka_tools_pkg.put_log_message` | 790 |
| `dka_tools_pkg.put_log_message` | 791 |
| `dka_tools_pkg.put_log_message` | 792 |
| `dka_tools_pkg.put_log_message` | 793 |
| `dka_Tools_Pkg.put_log_message` | 794 |
| `Fnd_File.put_line` | 796 |
| `Fnd_File.put_line` | 797 |
| `Fnd_File.put_line` | 798 |
| `Fnd_File.put_line` | 799 |
| `Fnd_File.put_line` | 800 |
| `Fnd_File.put_line` | 801 |
| `Fnd_File.put_line` | 802 |
| `Fnd_File.put_line` | 803 |
| `dka_Tools_Pkg.put_log_message` | 904 |
| `dka_Tools_Pkg.put_log_message` | 917 |
| `fnd_global.apps_initialize` | 918 |
| `dka_Tools_Pkg.put_log_message` | 972 |
| `dka_Tools_Pkg.put_log_message` | 977 |
| `dka_Tools_Pkg.put_log_message` | 981 |
| `fnd_request.submit_request` | 982 |
| `dka_Tools_Pkg.put_log_message` | 993 |
| `dka_Tools_Pkg.put_log_message` | 997 |
| `dka_Tools_Pkg.put_log_message` | 1005 |
| `Fnd_Concurrent.wait_for_request` | 1012 |
| `dka_Tools_Pkg.put_log_message` | 1013 |
| `dka_Tools_Pkg.put_log_message` | 1014 |
| `dka_Tools_Pkg.put_log_message` | 1017 |
| `dka_Tools_Pkg.put_log_message` | 1020 |
| `dka_Tools_Pkg.put_log_message` | 1023 |
| `dka_Tools_Pkg.put_log_message` | 1031 |
| `dka_tools_pkg.put_log_message` | 1032 |
| `dka_Tools_Pkg.put_log_message` | 1033 |
| `dka_tools_pkg.put_log_message` | 1034 |
| `dka_tools_pkg.put_log_message` | 1035 |
| `dka_tools_pkg.put_log_message` | 1036 |
| `dka_tools_pkg.put_log_message` | 1037 |
| `dka_tools_pkg.put_log_message` | 1038 |
| `dka_Tools_Pkg.put_log_message` | 1039 |
| `Fnd_File.put_line` | 1041 |
| `Fnd_File.put_line` | 1042 |
| `Fnd_File.put_line` | 1043 |
| `Fnd_File.put_line` | 1044 |
| `Fnd_File.put_line` | 1045 |
| `Fnd_File.put_line` | 1046 |
| `Fnd_File.put_line` | 1047 |
| `Fnd_File.put_line` | 1048 |
| `Fnd_File.put_line` | 1049 |
| `fnd_profile.value` | 1092 |
| `dka_Tools_Pkg.put_log_message` | 1124 |
| `dka_Tools_Pkg.put_log_message` | 1132 |
| `fnd_global.apps_initialize` | 1133 |
| `FND_REQUEST.SET_ORG_ID` | 1139 |
| `dka_Tools_Pkg.put_log_message` | 1141 |
| `fnd_request.submit_request` | 1142 |
| `dka_Tools_Pkg.put_log_message` | 1150 |
| `dka_Tools_Pkg.put_log_message` | 1154 |
| `dka_Tools_Pkg.put_log_message` | 1162 |
| `Fnd_Concurrent.wait_for_request` | 1169 |
| `dka_Tools_Pkg.put_log_message` | 1170 |
| `dka_Tools_Pkg.put_log_message` | 1171 |
| `dka_Tools_Pkg.put_log_message` | 1174 |
| `dka_Tools_Pkg.put_log_message` | 1177 |
| `dka_Tools_Pkg.put_log_message` | 1180 |
| `dka_Tools_Pkg.put_log_message` | 1188 |
| `dka_tools_pkg.put_log_message` | 1189 |
| `dka_Tools_Pkg.put_log_message` | 1190 |
| `dka_tools_pkg.put_log_message` | 1191 |
| `dka_tools_pkg.put_log_message` | 1192 |
| `dka_tools_pkg.put_log_message` | 1193 |
| `dka_tools_pkg.put_log_message` | 1194 |
| `dka_tools_pkg.put_log_message` | 1195 |
| `dka_Tools_Pkg.put_log_message` | 1196 |
| `Fnd_File.put_line` | 1198 |
| `Fnd_File.put_line` | 1199 |
| `Fnd_File.put_line` | 1200 |
| `Fnd_File.put_line` | 1201 |
| `Fnd_File.put_line` | 1202 |
| `Fnd_File.put_line` | 1203 |
| `Fnd_File.put_line` | 1204 |
| `Fnd_File.put_line` | 1205 |
| `Fnd_File.put_line` | 1206 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `FAGDA` | 110 |
| `FARET` | 246 |
| `PAXCPCAL` | 386 |
| `PACFATBP` | 1142 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 126, 264, 414, 749, 1004, 1161 |
| when_others | 378, 474, 817, 971, 976, 1063, 1220 |
| soumission | 110, 246, 386, 982, 1142 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_FAGDA / DKA | `DKA_SFADATAJ_PKG.generer_comptes` | dka/12.0.0/admin/import/DKA_FAGDA.prt:419 |
| DKA_FAMCP / DKA | `DKA_SFADATAJ_PKG.copie_hvp` | dka/12.0.0/admin/import/DKA_FAMCP.prt:419 |
| DKA_FARET / DKA | `DKA_SFADATAJ_PKG.calcul_values` | dka/12.0.0/admin/import/DKA_FARET.prt:419 |
| DKA_FNDRSSUB46 / DKA | `DKA_SFADATAJ_PKG.imput_acquis` | dka/12.0.0/admin/import/DKA_FNDRSSUB46.prt:419 |
| DKA_PACFATBP / DKA | `DKA_SFADATAJ_PKG.valider_immo` | dka/12.0.0/admin/import/DKA_PACFATBP.prt:420 |
| DKA_PAXCPCAL / DKA | `DKA_SFADATAJ_PKG.transfer_immo` | dka/12.0.0/admin/import/DKA_PAXCPCAL.prt:421 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
