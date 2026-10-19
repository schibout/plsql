# DKA_TVA_COLLECTEE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_TVA_COLLECTEE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_TVA_COLLECTEE_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 794 ; encodage : cp1252 (repli). SHA-256 : `ba3461ada96f3c19a13c99ab62f4080b479e9678d1940718ccf0389b63d6197e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `insert_data` | 70 |
| `Insert_data` | 87 |
| `insert_data` | 475 |
| `update_totaux_fact_regl` | 495 |
| `update_totaux_fact_regl` | 576 |
| `update_amount_ht_tva` | 598 |
| `update_montant_regle` | 666 |
| `delete_data` | 748 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_period_statuses` | 100 |
| `dka_tva_collectee` | 106 |
| `ra_customer_trx_all` | 137 |
| `ra_customer_trx_lines_all` | 158 |
| `ZX_LINES` | 163 |
| `Fnd_Flex_Value_Sets` | 171 |
| `dka_tva_collectee` | 192 |
| `ra_customer_trx_all` | 229 |
| `zx_lines` | 280 |
| `ra_cust_trx_line_gl_dist_all` | 287 |
| `dka_tva_collectee` | 319 |
| `ra_customer_trx_all` | 355 |
| `zx_lines` | 405 |
| `ar_receivable_applications_all` | 420 |
| `dka_tva_collectee` | 508 |
| `dka_tva_collectee` | 520 |
| `ra_cust_trx_line_gl_dist_all` | 522 |
| `ar_receivable_applications_all` | 526 |
| `ar_adjustments_all` | 551 |
| `dka_tva_collectee` | 558 |
| `dka_tva_collectee` | 610 |
| `dka_tva_collectee` | 621 |
| `dka_tva_collectee` | 632 |
| `dka_tva_collectee` | 678 |
| `dka_tva_collectee` | 700 |
| `dka_tva_collectee` | 765 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_outdebug_message` | 87 |
| `dka_tools_pkg.put_outdebug_message` | 104 |
| `dka_tools_pkg.put_outdebug_message` | 183 |
| `dka_tools_pkg.put_outdebug_message` | 185 |
| `dka_tools_pkg.put_outdebug_message` | 188 |
| `dka_tools_pkg.put_outdebug_message` | 190 |
| `dka_tools_pkg.put_outdebug_message` | 310 |
| `dka_tools_pkg.put_outdebug_message` | 312 |
| `dka_tools_pkg.put_outdebug_message` | 315 |
| `dka_tools_pkg.put_outdebug_message` | 317 |
| `dka_tools_pkg.put_outdebug_message` | 425 |
| `dka_tools_pkg.put_outdebug_message` | 427 |
| `dka_tools_pkg.put_outdebug_message` | 430 |
| `dka_tools_pkg.put_outdebug_message` | 467 |
| `dka_tools_pkg.put_outdebug_message` | 468 |
| `dka_tools_pkg.put_outdebug_message` | 476 |
| `dka_tools_pkg.put_outdebug_message` | 477 |
| `dka_tools_pkg.put_outdebug_message` | 516 |
| `dka_tools_pkg.put_debug_message` | 567 |
| `dka_tools_pkg.put_outdebug_message` | 576 |
| `dka_tools_pkg.put_debug_message` | 580 |
| `dka_tools_pkg.put_outdebug_message` | 607 |
| `dka_tools_pkg.put_outdebug_message` | 618 |
| `dka_tools_pkg.put_outdebug_message` | 629 |
| `dka_tools_pkg.put_outdebug_message` | 640 |
| `dka_tools_pkg.put_outdebug_message` | 641 |
| `dka_tools_pkg.put_debug_message` | 646 |
| `dka_tools_pkg.put_outdebug_message` | 689 |
| `dka_tools_pkg.put_outdebug_message` | 717 |
| `dka_tools_pkg.put_outdebug_message` | 721 |
| `dka_tools_pkg.put_debug_message` | 725 |
| `dka_tools_pkg.put_outdebug_message` | 760 |
| `dka_tools_pkg.put_outdebug_message` | 774 |
| `dka_tools_pkg.put_outdebug_message` | 777 |
| `dka_tools_pkg.put_outdebug_message` | 780 |
| `dka_tools_pkg.put_outdebug_message` | 787 |
| `dka_tools_pkg.put_outdebug_message` | 788 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 431, 441, 452, 462, 775 |
| rollback | 466, 473, 645, 724, 784 |
| when_others | 471, 565, 578, 643, 722, 782 |
| suppression | 765 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
