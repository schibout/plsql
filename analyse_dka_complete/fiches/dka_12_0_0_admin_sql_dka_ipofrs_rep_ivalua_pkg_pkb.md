# DKA_IPOFRS_REP_IVALUA_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IPOFRS_REP_IVALUA_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IPOFRS_REP_IVALUA_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1077 ; encodage : cp1252 (repli). SHA-256 : `a2cd8694e14acffba52a6d44dcc47df888cfbe9e4b5eb29c2227448320a99ad2`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `writeout` | 48 |
| `entete_de_sortie` | 84 |
| `SORTIE_TRAITEMENT` | 114 |
| `fin_de_sortie` | 181 |
| `PURGE_TABLE` | 206 |
| `LANCE_CHARGEMENT_FICHIER` | 223 |
| `PURGE_DONNEE` | 333 |
| `CONTROLE_DONNEE` | 370 |
| `MAJ_REFERENTIEL` | 703 |
| `BILAN` | 756 |
| `INIT_SEQUENCE` | 885 |
| `ENREGISTREMENT_COMPTEUR` | 901 |
| `MAIN` | 940 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_PROGRAM_MESSAGES` | 126 |
| `DKA_IPOFRS_MAJ_SITES_REPRIS` | 208 |
| `DKA_IPOFRS_MAJ_SITES_REPRIS` | 295 |
| `DKA_IPOFRS_MAJ_SITES_REPRIS` | 342 |
| `DKA_PROGRAM_MESSAGES` | 343 |
| `DKA_IPOFRS_MAJ_SITES_REPRIS` | 384 |
| `ap_suppliers` | 452 |
| `ap_supplier_sites_all` | 482 |
| `ap_supplier_sites_all` | 510 |
| `ap_supplier_sites_all` | 542 |
| `DKA_IPOFRS_MAJ_SITES_REPRIS` | 572 |
| `DKA_IPOFRS_MAJ_SITES_REPRIS` | 597 |
| `ap_supplier_sites_all` | 623 |
| `DKA_IPOFRS_MAJ_SITES_REPRIS` | 651 |
| `DKA_IPOFRS_MAJ_SITES_REPRIS` | 664 |
| `DKA_IPOFRS_MAJ_SITES_REPRIS` | 711 |
| `AP_SUPPLIER_SITES_ALL` | 719 |
| `DKA_IPOFRS_MAJ_SITES_REPRIS` | 725 |
| `DKA_IPOFRS_MAJ_SITES_REPRIS` | 736 |
| `AP_SUPPLIERS` | 760 |
| `AP_SUPPLIERS` | 771 |
| `AP_SUPPLIER_SITES_ALL` | 778 |
| `AP_SUPPLIERS` | 799 |
| `AP_SUPPLIERS` | 834 |
| `AP_SUPPLIER_SITES_ALL` | 841 |
| `DKA_IPOFRS_MAJ_SITES_REPRIS` | 916 |
| `DKA_IPOFRS_MAJ_SITES_REPRIS` | 921 |
| `DKA_IPOFRS_MAJ_SITES_REPRIS` | 927 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 15 |
| `FND_FILE.PUT_LINE` | 53 |
| `Fnd_File.put_line` | 59 |
| `Fnd_File.put_line` | 61 |
| `Fnd_File.put_line` | 62 |
| `Fnd_File.put_line` | 63 |
| `Fnd_File.put_line` | 64 |
| `Fnd_File.put_line` | 65 |
| `Fnd_File.put_line` | 248 |
| `Fnd_File.put_line` | 251 |
| `FND_REQUEST.submit_request` | 252 |
| `DKA_TOOLS_PKG.put_log_message` | 262 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 263 |
| `DKA_TOOLS_PKG.put_log_message` | 276 |
| `DKA_TOOLS_PKG.put_log_message` | 281 |
| `DKA_TOOLS_PKG.put_log_message` | 286 |
| `Fnd_File.put_line` | 287 |
| `DKA_TOOLS_PKG.put_log_message` | 301 |
| `DKA_TOOLS_PKG.put_log_message` | 309 |
| `DKA_TOOLS_PKG.put_log_message` | 340 |
| `DKA_TOOLS_PKG.ins_prog_message` | 350 |
| `DKA_TOOLS_PKG.get_message` | 397 |
| `DKA_TOOLS_PKG.ins_prog_message` | 398 |
| `DKA_TOOLS_PKG.get_message` | 413 |
| `DKA_TOOLS_PKG.ins_prog_message` | 414 |
| `DKA_TOOLS_PKG.get_message` | 431 |
| `DKA_TOOLS_PKG.ins_prog_message` | 432 |
| `DKA_TOOLS_PKG.get_message` | 457 |
| `DKA_TOOLS_PKG.ins_prog_message` | 461 |
| `DKA_TOOLS_PKG.get_message` | 487 |
| `DKA_TOOLS_PKG.ins_prog_message` | 491 |
| `DKA_TOOLS_PKG.get_message` | 517 |
| `DKA_TOOLS_PKG.ins_prog_message` | 521 |
| `DKA_TOOLS_PKG.get_message` | 549 |
| `DKA_TOOLS_PKG.ins_prog_message` | 555 |
| `DKA_TOOLS_PKG.get_message` | 576 |
| `DKA_TOOLS_PKG.ins_prog_message` | 580 |
| `DKA_TOOLS_PKG.get_message` | 602 |
| `DKA_TOOLS_PKG.ins_prog_message` | 606 |
| `DKA_TOOLS_PKG.get_message` | 630 |
| `DKA_TOOLS_PKG.ins_prog_message` | 634 |
| `DKA_TOOLS_PKG.ins_prog_message` | 681 |
| `DKA_TOOLS_PKG.put_log_message` | 715 |
| `DKA_TOOLS_PKG.put_log_message` | 735 |
| `DKA_TOOLS_PKG.put_log_message` | 810 |
| `DKA_TOOLS_PKG.put_log_message` | 850 |
| `DKA_TOOLS_PKG.put_log_message` | 957 |
| `DKA_TOOLS_PKG.put_log_message` | 969 |
| `Dka_Tools_Pkg.put_outdebug_message` | 973 |
| `DKA_TOOLS_PKG.put_log_message` | 981 |
| `DKA_TOOLS_PKG.put_log_message` | 990 |
| `DKA_TOOLS_PKG.put_log_message` | 1007 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1033 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1034 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1035 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1036 |
| `Dka_Tools_Pkg.put_log_message` | 1037 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1038 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1039 |
| `Dka_Tools_Pkg.put_log_message` | 1044 |
| `Dka_Tools_Pkg.put_log_message` | 1047 |
| `Dka_Tools_Pkg.put_log_message` | 1048 |
| `Dka_Tools_Pkg.put_log_message` | 1050 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1058 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1059 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1060 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1061 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1062 |
| `Dka_Tools_Pkg.put_log_message` | 1063 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1064 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1065 |
| `Dka_Tools_Pkg.put_log_message` | 1066 |
| `Dka_Tools_Pkg.put_log_message` | 1067 |
| `Dka_Tools_Pkg.put_log_message` | 1069 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 211, 259, 314, 345, 675, 745 |
| rollback | 1051, 1070 |
| when_others | 56, 298, 347, 678, 733, 807, 848, 1053 |
| suppression | 208, 342, 343 |
| soumission | 252 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IPOFRS_REP_IVALUA / DKA | `DKA_IPOFRS_REP_IVALUA_PKG.main` | dka/12.0.0/admin/import/DKA_IPOFRS_REP_IVALUA_F_PRG.ldt:518 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
