# DKA_SARLETTZERO_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARLETTZERO_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARLETTZERO_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1008 ; encodage : cp1252 (repli). SHA-256 : `02d4cf3c63d2df8970280628730b3e7be32569933654c3fafb953e23c3e0d033`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `log_msg` | 56 |
| `writeout` | 74 |
| `sortie_traitement` | 101 |
| `entete_de_sortie` | 122 |
| `fin_de_sortie` | 145 |
| `reglement_lettrage` | 166 |
| `extraction_reglement` | 494 |
| `SEND_MSG` | 634 |
| `ENVOI_MAIL` | 783 |
| `MAIN` | 914 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `hz_cust_accounts` | 202 |
| `hz_cust_accounts` | 253 |
| `apps.fnd_profile_options_vl` | 297 |
| `dual` | 324 |
| `AR_RECEIPT_METHODS` | 337 |
| `fnd_user` | 519 |
| `hz_cust_accounts` | 523 |
| `fnd_flex_value_sets` | 792 |
| `CTE` | 802 |
| `hr_operating_units` | 950 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 64 |
| `FND_FILE.PUT_LINE` | 79 |
| `Fnd_File.put_line` | 85 |
| `Fnd_File.put_line` | 87 |
| `Fnd_File.put_line` | 88 |
| `Fnd_File.put_line` | 89 |
| `Fnd_File.put_line` | 90 |
| `Fnd_File.put_line` | 91 |
| `fnd_file.put_line` | 104 |
| `fnd_file.put_line` | 107 |
| `fnd_file.put_line` | 109 |
| `fnd_file.put_line` | 111 |
| `dka_tools_pkg.put_log_message` | 309 |
| `fnd_global.apps_initialize` | 312 |
| `DKA_TOOLS_PKG.put_log_message` | 329 |
| `DKA_TOOLS_PKG.put_log_message` | 332 |
| `DKA_TOOLS_PKG.put_log_message` | 340 |
| `DKA_TOOLS_PKG.put_log_message` | 342 |
| `AR_RECEIPT_API_PUB.CREATE_CASH` | 345 |
| `DKA_TOOLS_PKG.put_log_message` | 369 |
| `DKA_TOOLS_PKG.put_log_message` | 370 |
| `DKA_TOOLS_PKG.put_log_message` | 372 |
| `DKA_TOOLS_PKG.put_log_message` | 375 |
| `FND_MSG_PUB.Get` | 379 |
| `DKA_TOOLS_PKG.put_log_message` | 384 |
| `DKA_TOOLS_PKG.put_log_message` | 389 |
| `DKA_TOOLS_PKG.put_log_message` | 395 |
| `AR_RECEIPT_API_PUB.APPLY` | 397 |
| `DKA_TOOLS_PKG.put_log_message` | 410 |
| `DKA_TOOLS_PKG.put_log_message` | 413 |
| `DKA_TOOLS_PKG.put_log_message` | 417 |
| `FND_MSG_PUB.Get` | 421 |
| `DKA_TOOLS_PKG.put_log_message` | 426 |
| `fnd_file.put_line` | 441 |
| `fnd_file.put_line` | 455 |
| `fnd_file.put_line` | 456 |
| `dka_Tools_Pkg.put_log_message` | 471 |
| `dka_Tools_Pkg.put_log_message` | 473 |
| `dka_Tools_Pkg.put_log_message` | 477 |
| `dka_tools_pkg.put_debug_message` | 555 |
| `dka_tools_pkg.put_log_message` | 570 |
| `dka_tools_pkg.put_log_message` | 587 |
| `dka_tools_pkg.put_log_message` | 606 |
| `dka_tools_pkg.put_log_message` | 611 |
| `dka_Tools_Pkg.put_log_message` | 616 |
| `dka_Tools_Pkg.put_log_message` | 621 |
| `fnd_file.put_line` | 661 |
| `fnd_file.put_line` | 676 |
| `fnd_file.put_line` | 680 |
| `fnd_file.put_line` | 715 |
| `dka_Tools_Pkg.put_log_message` | 764 |
| `dka_Tools_Pkg.put_log_message` | 769 |
| `dka_tools_pkg.put_log_message` | 806 |
| `dka_tools_pkg.get_parameter` | 811 |
| `fnd_file.put_line` | 819 |
| `fnd_file.put_line` | 833 |
| `fnd_file.put_line` | 846 |
| `fnd_file.put_line` | 856 |
| `fnd_file.put_line` | 867 |
| `fnd_file.put_line` | 871 |
| `fnd_file.put_line` | 893 |
| `fnd_file.put_line` | 895 |
| `fnd_file.put_line` | 902 |
| `fnd_file.put_line` | 903 |
| `DKA_TOOLS_PKG.put_log_message` | 928 |
| `DKA_TOOLS_PKG.put_log_message` | 933 |
| `dka_Tools_Pkg.put_log_message` | 943 |
| `DKA_TOOLS_PKG.put_log_message` | 948 |
| `dka_tools_pkg.put_debug_message` | 952 |
| `dka_Tools_Pkg.put_log_message` | 963 |
| `dka_tools_pkg.put_log_message` | 966 |
| `dka_tools_pkg.put_log_message` | 967 |
| `dka_Tools_Pkg.put_log_message` | 973 |
| `dka_Tools_Pkg.put_log_message` | 993 |
| `dka_Tools_Pkg.put_log_message` | 998 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 82, 470, 615, 740, 763, 992 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_CAMPAGNE_LETTRAGE_ZERO / DKA | `DKA_SARLETTZERO_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SARLETTZERO.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
