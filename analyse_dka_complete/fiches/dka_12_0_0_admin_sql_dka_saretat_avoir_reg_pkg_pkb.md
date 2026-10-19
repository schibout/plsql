# DKA_SARETAT_AVOIR_REG_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARETAT_AVOIR_REG_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARETAT_AVOIR_REG_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1099 ; encodage : cp1252 (repli). SHA-256 : `9336f8dceaecf82e67ed8e72658ac648759688fdd0ff7b58f2ca5c35faa87fb8`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 81 |
| `log_msg` | 98 |
| `init` | 121 |
| `INIT` | 162 |
| `write_boundary` | 176 |
| `begin_attachment` | 195 |
| `end_attachment` | 242 |
| `check_value_set` | 259 |
| `SEND_MSG` | 329 |
| `writeout` | 484 |
| `extraction_avoir_reglee` | 510 |
| `main` | 681 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `all_directories` | 134 |
| `v$database` | 147 |
| `fnd_flex_value_sets` | 281 |
| `fnd_flex_values` | 283 |
| `dka_ar_remb_avoir_list` | 519 |
| `dka_ar_remboursement_avoirs` | 524 |
| `fnd_flex_value_sets` | 723 |
| `CTE` | 734 |
| `fnd_flex_value_sets` | 744 |
| `CTE` | 755 |
| `hr_operating_units` | 760 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 86 |
| `fnd_file.put_line` | 108 |
| `dka_tools_pkg.get_parameter` | 139 |
| `dka_tools_pkg.get_parameter` | 150 |
| `dka_tools_pkg.put_log_message` | 159 |
| `dka_tools_pkg.put_log_message` | 166 |
| `fnd_file.put_line` | 358 |
| `fnd_file.put_line` | 373 |
| `fnd_file.put_line` | 388 |
| `fnd_file.put_line` | 393 |
| `fnd_file.put_line` | 428 |
| `fnd_file.put_line` | 490 |
| `fnd_file.put_line` | 495 |
| `fnd_file.put_line` | 496 |
| `fnd_file.put_line` | 497 |
| `fnd_file.put_line` | 498 |
| `fnd_file.put_line` | 499 |
| `fnd_file.put_line` | 500 |
| `dka_tools_pkg.get_parameter` | 542 |
| `dka_tools_pkg.put_log_message` | 557 |
| `dka_tools_pkg.put_log_message` | 585 |
| `dka_tools_pkg.put_log_message` | 661 |
| `dka_tools_pkg.get_parameter` | 771 |
| `fnd_file.put_line` | 774 |
| `dka_tools_pkg.put_log_message` | 784 |
| `dka_tools_pkg.put_log_message` | 785 |
| `fnd_file.put_line` | 786 |
| `fnd_file.put_line` | 787 |
| `fnd_file.put_line` | 789 |
| `fnd_file.put_line` | 790 |
| `fnd_file.put_line` | 791 |
| `fnd_file.put_line` | 793 |
| `fnd_file.put_line` | 794 |
| `dka_tools_pkg.put_log_message` | 798 |
| `fnd_file.put_line` | 815 |
| `fnd_file.put_line` | 842 |
| `fnd_file.put_line` | 852 |
| `dka_tools_pkg.put_log_message` | 864 |
| `fnd_file.put_line` | 869 |
| `fnd_file.put_line` | 906 |
| `fnd_file.put_line` | 907 |
| `fnd_file.put_line` | 914 |
| `fnd_file.put_line` | 915 |
| `dka_tools_pkg.put_log_message` | 921 |
| `dka_tools_pkg.put_log_message` | 923 |
| `dka_tools_pkg.put_log_message` | 931 |
| `dka_tools_pkg.put_log_message` | 932 |
| `dka_tools_pkg.put_log_message` | 938 |
| `fnd_file.put_line` | 939 |
| `fnd_file.put_line` | 940 |
| `fnd_file.put_line` | 942 |
| `fnd_file.put_line` | 943 |
| `fnd_file.put_line` | 944 |
| `fnd_file.put_line` | 945 |
| `fnd_file.put_line` | 946 |
| `dka_tools_pkg.put_log_message` | 950 |
| `dka_tools_pkg.get_parameter` | 954 |
| `fnd_file.put_line` | 957 |
| `fnd_file.put_line` | 975 |
| `fnd_file.put_line` | 1003 |
| `fnd_file.put_line` | 1013 |
| `fnd_file.put_line` | 1028 |
| `fnd_file.put_line` | 1065 |
| `fnd_file.put_line` | 1066 |
| `fnd_file.put_line` | 1073 |
| `fnd_file.put_line` | 1074 |
| `dka_tools_pkg.put_log_message` | 1079 |
| `dka_tools_pkg.put_log_message` | 1081 |
| `dka_tools_pkg.put_log_message` | 1089 |
| `dka_tools_pkg.put_log_message` | 1090 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 926, 1084 |
| when_others | 161, 452, 492 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARETAT_AVOIR_REG / DKA | `DKA_SARETAT_AVOIR_REG_PKG.main` | dka/12.0.0/admin/import/DKA_SARETAT_AVOIR_REG.prt:475 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
