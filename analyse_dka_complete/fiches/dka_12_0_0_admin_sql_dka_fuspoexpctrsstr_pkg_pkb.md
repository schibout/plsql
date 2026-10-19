# DKA_FUSPOEXPCTRSSTR_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_FUSPOEXPCTRSSTR_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_FUSPOEXPCTRSSTR_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 923 ; encodage : cp1252 (repli). SHA-256 : `e7a847c49fcdf12bbe6b3a476dd5d284c55862d69920aef53578f5d0e37e233e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Main` | 44 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_headers_all` | 92 |
| `dka_contrat_sstr_imputation` | 117 |
| `HR_ORGANIZATION_UNITS` | 124 |
| `po_headers_archive_all` | 171 |
| `dka_contrat_sstr_imputation` | 191 |
| `dka_contrat_sstr` | 225 |
| `dka_contrat_sstr_archi` | 267 |
| `PA_TASKS` | 306 |
| `dka_contrat_sstr_imputation` | 308 |
| `PA_TASKS` | 345 |
| `dka_contrat_sstr_imput_archi` | 347 |
| `HR_ORGANIZATION_UNITS` | 392 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 420 |
| `HR_ORGANIZATION_UNITS` | 423 |
| `DKA_SPOFUSION_SSTR_DETAIL_TMP` | 436 |
| `HR_ORGANIZATION_UNITS` | 439 |
| `DKA_SPOFUSION_SSTR_IMPUT_TMP` | 452 |
| `HR_ORGANIZATION_UNITS` | 455 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 485 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 554 |
| `DKA_SPOFUSION_SSTR_DETAIL_TMP` | 626 |
| `DKA_SPOFUSION_SSTR_DETAIL_TMP` | 688 |
| `DKA_SPOFUSION_SSTR_IMPUT_TMP` | 750 |
| `DKA_SPOFUSION_SSTR_IMPUT_TMP` | 810 |
| `HR_ORGANIZATION_UNITS` | 875 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 377 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 378 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 379 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 380 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 381 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 382 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 383 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 384 |
| `Dka_Tools_Pkg.put_log_message` | 414 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 415 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 473 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 474 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 475 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 476 |
| `dka_Tools_Pkg.put_log_message` | 543 |
| `dka_Tools_Pkg.put_log_message` | 612 |
| `dka_Tools_Pkg.put_log_message` | 674 |
| `dka_Tools_Pkg.put_log_message` | 737 |
| `dka_Tools_Pkg.put_log_message` | 796 |
| `dka_Tools_Pkg.put_log_message` | 858 |
| `dka_tools_pkg.put_debug_message` | 870 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 882 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 888 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 889 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 890 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 891 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 892 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 893 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 894 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 895 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 896 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 897 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 898 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 899 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 900 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 901 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 912 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 913 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 914 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 915 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 916 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 537, 606, 668, 731, 790, 852, 905 |
| rollback | 908 |
| when_others | 407, 541, 610, 672, 735, 794, 856, 869, 907 |
| suppression | 420, 436, 452 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_FUSPOEXPCTRSSTR / DKA | `DKA_FUSPOEXPCTRSSTR_PKG.main` | dka/12.0.0/admin/import/DKA_FUSPOEXPCTRSSTR.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
