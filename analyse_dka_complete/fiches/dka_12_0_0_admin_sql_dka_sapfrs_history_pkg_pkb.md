# dka_sapfrs_history_pkg.pkb

Source : [dka/12.0.0/admin/sql/dka_sapfrs_history_pkg.pkb](../../dka/12.0.0/admin/sql/dka_sapfrs_history_pkg.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 873 ; encodage : cp1252 (repli). SHA-256 : `471617dc175fd042eaa6c3289950ff283f5e33649fe3df1345fb9515f63554ef`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_vendor_party` | 32 |
| `get_vendor_id` | 51 |
| `get_vendor_name` | 75 |
| `get_vendor_site_id` | 107 |
| `get_payement_method` | 129 |
| `get_user_name` | 156 |
| `get_term_name` | 174 |
| `insert_supplier_history` | 229 |
| `insert_supplier_sites_history` | 351 |
| `insert_supplier_mode_p` | 695 |
| `INSERT_CUSTOMER_HISTORY` | 818 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ap_supplier_sites_all` | 42 |
| `ap_supplier_sites_all` | 61 |
| `AP_SUPPLIERS` | 93 |
| `iby_external_payees_all` | 115 |
| `iby_external_payees_all` | 137 |
| `fnd_user` | 164 |
| `ap_terms` | 182 |
| `DUAL` | 247 |
| `DUAL` | 251 |
| `DKA_SAPFRS_MAJ_HEADERS` | 261 |
| `DKA_SAPFRS_MAJ_HEADERS` | 291 |
| `DKA_SAPFRS_MAJ_HEADERS` | 316 |
| `DUAL` | 374 |
| `DUAL` | 378 |
| `DKA_SAPFRS_MAJ_SITES` | 390 |
| `DKA_SAPFRS_MAJ_SITES` | 428 |
| `DKA_SAPFRS_MAJ_SITES` | 458 |
| `DKA_SAPFRS_MAJ_SITES` | 482 |
| `DKA_SAPFRS_MAJ_SITES` | 490 |
| `DKA_SAPFRS_MAJ_SITES` | 513 |
| `ap_supplier_sites_all` | 516 |
| `DKA_SAPFRS_MAJ_SITES` | 539 |
| `DKA_SAPFRS_MAJ_SITES` | 547 |
| `hr_organization_units` | 549 |
| `hr_organization_units` | 552 |
| `DKA_SAPFRS_MAJ_SITES` | 561 |
| `DKA_SAPFRS_MAJ_SITES` | 573 |
| `DKA_SAPFRS_MAJ_SITES` | 581 |
| `DKA_SAPFRS_MAJ_SITES` | 590 |
| `DKA_SAPFRS_MAJ_SITES` | 613 |
| `ap_supplier_sites_all` | 616 |
| `DKA_SAPFRS_MAJ_SITES` | 629 |
| `DKA_SAPFRS_MAJ_SITES` | 652 |
| `ap_supplier_sites_all` | 654 |
| `DKA_SAPFRS_MAJ_SITES` | 667 |
| `ap_supplier_sites_all` | 669 |
| `ap_supplier_sites_all` | 673 |
| `DKA_SAPFRS_MAJ_SITES` | 679 |
| `DUAL` | 717 |
| `DUAL` | 721 |
| `DKA_SAPFRS_MAJ_SITES` | 728 |
| `DKA_SAPFRS_MAJ_SITES` | 730 |
| `DKA_SAPFRS_MAJ_SITES` | 736 |
| `DKA_SAPFRS_MAJ_SITES` | 742 |
| `DKA_SAPFRS_MAJ_SITES` | 744 |
| `DKA_SAPFRS_MAJ_SITES` | 754 |
| `DKA_SAPFRS_MAJ_SITES` | 781 |
| `iby_pmt_instr_uses_all` | 829 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_sapfrs_history_pkg.get_user_name` | 368 |
| `dka_sapfrs_history_pkg.get_user_name` | 711 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 338, 665, 683, 805, 866 |
| when_others | 45, 69, 101, 122, 150, 168, 186, 341, 685, 808 |
| suppression | 490, 590, 629 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
