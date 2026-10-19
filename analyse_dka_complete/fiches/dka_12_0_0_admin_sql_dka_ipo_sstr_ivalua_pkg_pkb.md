# DKA_IPO_SSTR_IVALUA_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IPO_SSTR_IVALUA_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IPO_SSTR_IVALUA_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1242 ; encodage : cp1252 (repli). SHA-256 : `e4687ce47ce57743919bf11b4515269c49d8c0300cae9db1cd8edbed4eb8cd5d`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Writeout` | 34 |
| `SORTIE_TRAITEMENT` | 59 |
| `entete_de_sortie` | 148 |
| `fin_de_sortie` | 169 |
| `UPDATE_RECORD` | 192 |
| `LANCE_CHARGEMENT_FICHIER` | 309 |
| `PURGE_DONNEE_TRAITEE` | 437 |
| `PREPARATION_DONNEE` | 470 |
| `MAJ_DONNEE_ATRAITEE` | 557 |
| `DETERMINATION_ACTION` | 587 |
| `VALIDATION_DONNEES` | 642 |
| `IMPORT_DONNEES` | 887 |
| `ENREGISTREMENT_COMPTEUR` | 1046 |
| `UPDATE_RECORD2` | 1076 |
| `MAIN` | 1127 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_PROGRAM_MESSAGES` | 68 |
| `DKA_IPOCTR_SSTR_IVALUA_REPORT` | 201 |
| `DKA_IPOCTR_SSTR_IVALUA` | 238 |
| `DKA_IPOCTR_SSTR_IVALUA_HIST` | 249 |
| `DKA_IPOCTR_SSTR_IVALUA` | 286 |
| `DKA_IPOCTR_SSTR_IVALUA` | 446 |
| `DKA_IPOCTR_SSTR_IVALUA` | 481 |
| `DKA_IPOCTR_SSTR_IVALUA` | 494 |
| `DKA_IPOCTR_SSTR_IVALUA_REPORT` | 507 |
| `DKA_IPOCTR_SSTR_IVALUA` | 517 |
| `DKA_PROGRAM_MESSAGES` | 530 |
| `DKA_IPOCTR_SSTR_IVALUA` | 565 |
| `DKA_IPOCTR_SSTR_IVALUA` | 567 |
| `ou` | 597 |
| `DKA_IPOCTR_SSTR_IVALUA` | 601 |
| `DKA_SPO_CONTRAT_SSTR_IVALUA` | 607 |
| `DKA_IPOCTR_SSTR_IVALUA` | 615 |
| `DKA_SPO_CONTRAT_SSTR_IVALUA` | 622 |
| `DKA_IPOCTR_SSTR_IVALUA` | 646 |
| `Po_Headers_All` | 809 |
| `Po_Headers_All` | 814 |
| `DKA_IPOCTR_SSTR_IVALUA` | 843 |
| `DKA_IPOCTR_SSTR_IVALUA` | 857 |
| `DKA_IPOCTR_SSTR_IVALUA` | 893 |
| `DKA_IPOCTR_SSTR_IVALUA` | 902 |
| `DUAL` | 925 |
| `Po_Headers_All` | 928 |
| `DKA_SPO_CONTRAT_SSTR_IVALUA` | 934 |
| `statut` | 971 |
| `DKA_IPOCTR_SSTR_IVALUA` | 972 |
| `statut` | 980 |
| `DKA_SPO_CONTRAT_SSTR_IVALUA` | 988 |
| `statut` | 1008 |
| `statut` | 1012 |
| `DKA_IPOCTR_SSTR_IVALUA` | 1013 |
| `statut` | 1021 |
| `DKA_IPOCTR_SSTR_IVALUA` | 1051 |
| `DKA_IPOCTR_SSTR_IVALUA` | 1059 |
| `DKA_SPO_CONTRAT_SSTR_IVALUA` | 1081 |
| `DKA_IPOCTR_SSTR_IVALUA` | 1082 |
| `DKA_IPOCTR_SSTR_IVALUA_REPORT` | 1087 |
| `DKA_IPOCTR_SSTR_IVALUA_REPORT` | 1102 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 16 |
| `FND_FILE.PUT_LINE` | 39 |
| `Fnd_File.put_line` | 45 |
| `Fnd_File.put_line` | 47 |
| `Fnd_File.put_line` | 48 |
| `Fnd_File.put_line` | 49 |
| `Fnd_File.put_line` | 50 |
| `Fnd_File.put_line` | 51 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 93 |
| `DKA_TOOLS_PKG.put_log_message` | 137 |
| `DKA_TOOLS_PKG.get_message` | 243 |
| `DKA_TOOLS_PKG.put_log_message` | 244 |
| `DKA_TOOLS_PKG.get_message` | 291 |
| `DKA_TOOLS_PKG.put_log_message` | 292 |
| `DKA_TOOLS_PKG.put_log_message` | 299 |
| `DKA_TOOLS_PKG.put_log_message` | 300 |
| `Fnd_File.put_line` | 332 |
| `Fnd_File.put_line` | 335 |
| `FND_REQUEST.SET_OPTIONS` | 338 |
| `FND_REQUEST.submit_request` | 340 |
| `DKA_TOOLS_PKG.put_log_message` | 351 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 352 |
| `DKA_TOOLS_PKG.put_log_message` | 365 |
| `DKA_TOOLS_PKG.put_log_message` | 370 |
| `DKA_TOOLS_PKG.put_log_message` | 375 |
| `Fnd_File.put_line` | 376 |
| `DKA_TOOLS_PKG.put_log_message` | 391 |
| `DKA_TOOLS_PKG.put_log_message` | 427 |
| `DKA_TOOLS_PKG.put_log_message` | 428 |
| `DKA_TOOLS_PKG.put_log_message` | 445 |
| `DKA_TOOLS_PKG.ins_prog_message` | 453 |
| `DKA_TOOLS_PKG.put_log_message` | 488 |
| `DKA_TOOLS_PKG.put_log_message` | 529 |
| `DKA_TOOLS_PKG.ins_prog_message` | 539 |
| `DKA_TOOLS_PKG.put_log_message` | 574 |
| `DKA_TOOLS_PKG.put_log_message` | 575 |
| `DKA_TOOLS_PKG.put_log_message` | 598 |
| `DKA_TOOLS_PKG.put_log_message` | 632 |
| `DKA_TOOLS_PKG.put_log_message` | 633 |
| `DKA_TOOLS_PKG.put_log_message` | 668 |
| `DKA_TOOLS_PKG.put_log_message` | 669 |
| `DKA_TOOLS_PKG.put_log_message` | 674 |
| `DKA_TOOLS_PKG.get_message` | 677 |
| `DKA_TOOLS_PKG.ins_prog_message` | 678 |
| `DKA_TOOLS_PKG.put_log_message` | 688 |
| `DKA_TOOLS_PKG.put_log_message` | 692 |
| `DKA_TOOLS_PKG.get_message` | 695 |
| `DKA_TOOLS_PKG.ins_prog_message` | 696 |
| `DKA_TOOLS_PKG.put_log_message` | 706 |
| `DKA_TOOLS_PKG.put_log_message` | 710 |
| `DKA_TOOLS_PKG.get_message` | 713 |
| `DKA_TOOLS_PKG.ins_prog_message` | 714 |
| `DKA_TOOLS_PKG.put_log_message` | 724 |
| `DKA_TOOLS_PKG.put_log_message` | 728 |
| `DKA_TOOLS_PKG.get_message` | 731 |
| `DKA_TOOLS_PKG.ins_prog_message` | 732 |
| `DKA_TOOLS_PKG.put_log_message` | 742 |
| `DKA_TOOLS_PKG.put_log_message` | 747 |
| `DKA_TOOLS_PKG.get_message` | 750 |
| `DKA_TOOLS_PKG.ins_prog_message` | 752 |
| `DKA_TOOLS_PKG.put_log_message` | 762 |
| `DKA_TOOLS_PKG.put_log_message` | 766 |
| `DKA_TOOLS_PKG.get_message` | 769 |
| `DKA_TOOLS_PKG.ins_prog_message` | 770 |
| `DKA_TOOLS_PKG.put_log_message` | 780 |
| `DKA_TOOLS_PKG.put_log_message` | 785 |
| `DKA_TOOLS_PKG.get_message` | 788 |
| `DKA_TOOLS_PKG.ins_prog_message` | 789 |
| `DKA_TOOLS_PKG.put_log_message` | 799 |
| `DKA_TOOLS_PKG.put_log_message` | 805 |
| `DKA_TOOLS_PKG.get_message` | 824 |
| `DKA_TOOLS_PKG.ins_prog_message` | 826 |
| `DKA_TOOLS_PKG.put_log_message` | 836 |
| `DKA_TOOLS_PKG.put_log_message` | 854 |
| `DKA_TOOLS_PKG.put_log_message` | 876 |
| `DKA_TOOLS_PKG.put_log_message` | 877 |
| `DKA_TOOLS_PKG.put_log_message` | 918 |
| `DKA_TOOLS_PKG.put_log_message` | 920 |
| `DKA_TOOLS_PKG.put_log_message` | 922 |
| `DKA_TOOLS_PKG.put_log_message` | 930 |
| `DKA_TOOLS_PKG.put_log_message` | 933 |
| `DKA_TOOLS_PKG.put_log_message` | 971 |
| `DKA_TOOLS_PKG.put_log_message` | 980 |
| `DKA_TOOLS_PKG.put_log_message` | 1008 |
| `DKA_TOOLS_PKG.put_log_message` | 1012 |
| `DKA_TOOLS_PKG.put_log_message` | 1021 |
| `DKA_TOOLS_PKG.put_log_message` | 1032 |
| `DKA_TOOLS_PKG.put_log_message` | 1033 |
| `DKA_TOOLS_PKG.put_log_message` | 1066 |
| `DKA_TOOLS_PKG.put_log_message` | 1067 |
| `DKA_TOOLS_PKG.put_log_message` | 1115 |
| `DKA_TOOLS_PKG.put_log_message` | 1116 |
| `DKA_TOOLS_PKG.put_log_message` | 1139 |
| `DKA_TOOLS_PKG.put_log_message` | 1148 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1152 |
| `DKA_TOOLS_PKG.put_log_message` | 1158 |
| `DKA_TOOLS_PKG.put_log_message` | 1170 |
| `DKA_TOOLS_PKG.put_log_message` | 1181 |
| `DKA_TOOLS_PKG.put_log_message` | 1190 |
| `DKA_TOOLS_PKG.put_log_message` | 1199 |
| `DKA_TOOLS_PKG.put_log_message` | 1209 |
| `DKA_TOOLS_PKG.put_log_message` | 1233 |
| `DKA_TOOLS_PKG.put_log_message` | 1234 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 294, 348, 396, 448, 534, 871, 1026, 1100 |
| when_others | 42, 133, 241, 289, 296, 424, 450, 501, 536, 571, 629, 873, 929, 979, 1007, 1020, 1029, 1063, 1112, 1230 |
| suppression | 446, 517, 530 |
| soumission | 340 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IPO_SSTR_IVALUA / DKA | `DKA_IPO_SSTR_IVALUA_PKG.Main` | dka/12.0.0/admin/import/DKA_IPO_SSTR_IVALUA.prt:480 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
