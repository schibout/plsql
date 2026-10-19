# DKA_IAPFACTTDS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IAPFACTTDS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IAPFACTTDS_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 851 ; encodage : cp1252 (repli). SHA-256 : `98d75ae071616b73411d0b07a2a2ff54d2a4f1e5e50022fe5cae4859a435335b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `determination_statut_comm` | 43 |
| `update_factures` | 373 |
| `insert_factures` | 427 |
| `reinitialisation_statuts` | 514 |
| `archivage_factures` | 545 |
| `verif_factures_archivees` | 594 |
| `creation_fichier` | 671 |
| `main` | 747 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `AP_INVOICES_ALL` | 75 |
| `AP_INVOICES_ALL` | 91 |
| `AP_HOLDS_ALL` | 119 |
| `FND_USER` | 125 |
| `PER_ALL_PEOPLE_F` | 130 |
| `AP_PAYMENT_SCHEDULES_ALL` | 156 |
| `AP_HOLDS_ALL` | 173 |
| `AP_PAYMENT_SCHEDULES_ALL` | 182 |
| `AP_HOLDS_ALL` | 207 |
| `PER_ALL_PEOPLE_F` | 220 |
| `AP_PAYMENT_SCHEDULES_ALL` | 264 |
| `AP_PAYMENT_SCHEDULES_ALL` | 275 |
| `AP_PAYMENT_SCHEDULES_ALL` | 302 |
| `AP_CHECKS_ALL` | 309 |
| `AP_INVOICE_PAYMENTS_ALL` | 310 |
| `AP_PAYMENT_SCHEDULES_ALL` | 340 |
| `DKA_IAPFACTTDS_TAB` | 375 |
| `DKA_IAPFACTTDS_TAB` | 395 |
| `DKA_IAPFACTTDS_TAB` | 405 |
| `DKA_IAPFACTTDS_TAB` | 468 |
| `AP_invoices_all` | 478 |
| `DKA_IAPFACTTDS_TAB` | 486 |
| `DKA_IAPFACTTDS_HIST` | 488 |
| `DKA_IAPFACTTDS_TAB` | 523 |
| `DKA_IAPFACTTDS_HIST` | 554 |
| `DKA_IAPFACTTDS_TAB` | 566 |
| `DKA_IAPFACTTDS_TAB` | 572 |
| `ap_invoices_all` | 602 |
| `dka_iapfacttds_hist` | 606 |
| `DKA_IAPFACTTDS_HIST` | 614 |
| `DKA_IAPFACTTDS_TAB` | 620 |
| `DKA_IAPFACTTDS_HIST` | 641 |
| `DKA_IAPFACTTDS_HIST` | 646 |
| `DKA_IAPFACTTDS_TAB` | 686 |
| `DKA_IAPFACTTDS_TAB` | 695 |
| `DKA_PARAMETERS` | 811 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_TOOLS_PKG.put_debug_message` | 69 |
| `Dka_Tools_Pkg.get_message` | 96 |
| `Dka_Tools_Pkg.get_message` | 139 |
| `Dka_Tools_Pkg.get_message` | 162 |
| `Dka_Tools_Pkg.get_message` | 191 |
| `Dka_Tools_Pkg.get_message` | 230 |
| `Dka_Tools_Pkg.get_message` | 241 |
| `Dka_Tools_Pkg.get_message` | 248 |
| `Dka_Tools_Pkg.get_message` | 277 |
| `Dka_Tools_Pkg.get_message` | 283 |
| `Dka_Tools_Pkg.get_message` | 293 |
| `Dka_Tools_Pkg.get_message` | 320 |
| `Dka_Tools_Pkg.get_message` | 327 |
| `DKA_TOOLS_PKG.put_debug_message` | 385 |
| `DKA_TOOLS_PKG.put_debug_message` | 439 |
| `dka_tools_pkg.get_parameter` | 444 |
| `DKA_TOOLS_PKG.put_debug_message` | 447 |
| `dka_tools_pkg.get_parameter` | 453 |
| `DKA_TOOLS_PKG.put_debug_message` | 456 |
| `DKA_TOOLS_PKG.put_debug_message` | 490 |
| `DKA_TOOLS_PKG.put_debug_message` | 520 |
| `DKA_TOOLS_PKG.put_debug_message` | 526 |
| `DKA_TOOLS_PKG.put_debug_message` | 551 |
| `DKA_TOOLS_PKG.put_debug_message` | 569 |
| `DKA_TOOLS_PKG.put_debug_message` | 574 |
| `DKA_TOOLS_PKG.put_debug_message` | 610 |
| `DKA_TOOLS_PKG.put_debug_message` | 652 |
| `DKA_TOOLS_PKG.put_debug_message` | 693 |
| `DKA_TOOLS_PKG.put_debug_message` | 700 |
| `Fnd_File.put_line` | 718 |
| `DKA_TOOLS_PKG.put_debug_message` | 722 |
| `DKA_TOOLS_PKG.put_debug_message` | 766 |
| `DKA_TOOLS_PKG.put_debug_message` | 776 |
| `DKA_TOOLS_PKG.put_debug_message` | 786 |
| `DKA_TOOLS_PKG.put_debug_message` | 796 |
| `DKA_TOOLS_PKG.put_debug_message` | 806 |
| `DKA_TOOLS_PKG.put_debug_message` | 818 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 839, 844 |
| when_others | 357, 411, 497, 529, 577, 655, 729, 840, 843 |
| suppression | 572, 646 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IAPFACTTDS / DKA | `DKA_IAPFACTTDS_PKG.main` | dka/12.0.0/admin/import/DKA_IAPFACTTDS_F.prt:419 |
| DKA_IAPFACTTDS / DKA | `DKA_IAPFACTTDS_PKG.main` | dka/12.0.0/admin/import/DKA_IAPFACTTDS_F.prt:419 |
| DKA_IAPFACTTDS / DKA | `DKA_IAPFACTTDS_PKG.main` | dka/12.0.0/admin/import/DKA_IAPFACTTDS_US.prt:419 |
| DKA_IAPFACTTDS / DKA | `DKA_IAPFACTTDS_PKG.main` | dka/12.0.0/admin/import/DKA_IAPFACTTDS_US.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
