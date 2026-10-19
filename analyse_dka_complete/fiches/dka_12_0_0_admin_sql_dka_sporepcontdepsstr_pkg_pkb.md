# DKA_SPOREPCONTDEPSSTR_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOREPCONTDEPSSTR_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOREPCONTDEPSSTR_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1112 ; encodage : cp1252 (repli). SHA-256 : `4357ab03d405688ae4e769ba1cf2917115de4ecf5c25c295060c54bb824cb024`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Main` | 49 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_PO_CONTRAT_DEPSSTR_TMP` | 95 |
| `DKA_PO_CONTRAT_DEPSSTR_TMP` | 131 |
| `po_unique_identifier_control` | 140 |
| `OF` | 142 |
| `FND_USER` | 160 |
| `dka_po_contrat_depsstr_tmp` | 175 |
| `dka_po_contrat_depsstr_tmp` | 179 |
| `DKA_PO_CONTRAT_DEPSSTR_TMP` | 245 |
| `PO_HEADERS_ALL` | 264 |
| `PO_VENDORS` | 433 |
| `PO_VENDOR_SITES_ALL` | 451 |
| `hr_locations` | 470 |
| `hr_locations` | 488 |
| `mtl_categories_kfv` | 506 |
| `FND_USER` | 526 |
| `fnd_flex_value_sets` | 542 |
| `pa_expenditure_types` | 561 |
| `pa_projects_all` | 581 |
| `pa_projects_all` | 604 |
| `DUAL` | 681 |
| `DKA_PO_CONTRAT_DEPSSTR_TMP` | 700 |
| `dual` | 723 |
| `Dka_Contrat_Sstr` | 851 |
| `DKA_CONTRAT_SSTR_IMPUTATION` | 906 |
| `DKA_PO_CONTRAT_DEPSSTR_TMP` | 943 |
| `DKA_PO_CONTRAT_DEPSSTR_TMP` | 973 |
| `DKA_PO_CONTRAT_DEPSSTR_TMP` | 993 |
| `DKA_PO_CONTRAT_DEPSSTR_TMP` | 1001 |
| `DKA_CONTRAT_SSTR_ARCHI` | 1015 |
| `DKA_CONTRAT_SSTR` | 1017 |
| `DKA_CONTRAT_SSTR_IMPUT_ARCHI` | 1026 |
| `DKA_CONTRAT_SSTR_IMPUTATION` | 1028 |
| `DKA_PO_CONTRAT_DEPSSTR_TMP` | 1042 |
| `DKA_PO_CONTRAT_DEPSSTR_TMP` | 1043 |
| `DKA_PO_CONTRAT_DEPSSTR_TMP` | 1044 |
| `DKA_PO_CONTRAT_DEPSSTR_TMP` | 1045 |
| `DKA_PO_CONTRAT_DEPSSTR_TMP` | 1046 |
| `DKA_PO_CONTRAT_DEPSSTR_TMP` | 1047 |
| `DUAL` | 1054 |
| `PO_HEADERS_ALL` | 1059 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.Put_Debug_Message` | 147 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 153 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 154 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 155 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 156 |
| `FND_PROFILE.value` | 161 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 163 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 171 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 172 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 173 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 185 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 188 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 192 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 193 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 249 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 254 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 257 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 276 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 314 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 412 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 413 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 415 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 427 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 439 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 442 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 460 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 463 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 478 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 481 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 496 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 499 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 516 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 519 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 532 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 535 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 551 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 554 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 569 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 572 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 587 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 593 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 596 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 614 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 617 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 658 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 659 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 664 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 665 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 670 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 671 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 696 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 714 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 728 |
| `po_headers_sv11.insert_po` | 730 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 849 |
| `PO_REQAPPROVAL_INIT1.Start_WF_Process` | 949 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 967 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 969 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 976 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 985 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 986 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 989 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 990 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 997 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 998 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1074 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1075 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1076 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1077 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1078 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1079 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1081 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1083 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1084 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1088 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1091 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1092 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1093 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1095 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1099 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1100 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1101 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1102 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1105 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1106 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 187 |
| rollback | 992, 1000 |
| when_others | 440, 461, 479, 497, 517, 533, 552, 570, 594, 615, 996, 1098 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOREPCONTDEPSSTR_PKG / DKA | `DKA_SPOREPCONTDEPSSTR_PKG.main` | dka/12.0.0/admin/import/DKA_SPOREPCONTDEPSSTR_PKG.prt:405 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
