# DKA_FUSPORECVTOTAL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_FUSPORECVTOTAL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_FUSPORECVTOTAL_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 765 ; encodage : cp1252 (repli). SHA-256 : `1578a60dee25ee5f6d7c7f2f3165aebc6daeb1c0009cdf3933a4255123a07a02`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `put_line_log` | 35 |
| `put_line_out` | 47 |
| `Launch_OI` | 73 |
| `insert_rcv_headers` | 204 |
| `insert_rcv_transactions` | 273 |
| `wait_rvctp` | 374 |
| `main` | 426 |
| `insert_rcv_headers` | 601 |
| `insert_rcv_transactions` | 619 |
| `Launch_OI` | 712 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `rcv_headers_interface` | 109 |
| `rcv_headers_interface` | 216 |
| `rcv_transactions_interface` | 291 |
| `PO_HEADERS_ALL` | 457 |
| `HR_ORGANIZATION_UNITS` | 466 |
| `Hr_organization_units` | 475 |
| `rcv_shipment_lines` | 480 |
| `po_headers_all` | 494 |
| `PO_INTERFACE_ERRORS` | 504 |
| `rcv_headers_interface` | 507 |
| `PO_INTERFACE_ERRORS` | 518 |
| `rcv_headers_interface` | 522 |
| `rcv_transactions_interface` | 536 |
| `rcv_headers_interface` | 538 |
| `PO_INTERFACE_ERRORS` | 542 |
| `rcv_headers_interface` | 545 |
| `rcv_headers_interface` | 549 |
| `dual` | 556 |
| `po_headers_all` | 585 |
| `dual` | 597 |
| `rcv_headers_interface` | 724 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 37 |
| `fnd_file.put_line` | 49 |
| `Fnd_File.put_line` | 92 |
| `Fnd_File.put_line` | 93 |
| `fnd_file.put_line` | 96 |
| `fnd_file.put_line` | 97 |
| `fnd_file.put_line` | 98 |
| `fnd_stats.gather_table_stats` | 101 |
| `fnd_stats.gather_table_stats` | 102 |
| `fnd_request.submit_request` | 115 |
| `fnd_file.put_line` | 127 |
| `Fnd_File.put_line` | 129 |
| `Fnd_File.put_line` | 134 |
| `Fnd_File.put_line` | 135 |
| `Fnd_Concurrent.wait_for_request` | 148 |
| `Fnd_file.put_line` | 151 |
| `Fnd_File.put_line` | 157 |
| `Fnd_File.put_line` | 158 |
| `Fnd_File.put_line` | 162 |
| `fnd_file.put_line` | 170 |
| `Fnd_File.put_line` | 173 |
| `Fnd_File.put_line` | 177 |
| `Fnd_File.put_line` | 184 |
| `Fnd_File.put_line` | 185 |
| `fnd_concurrent.wait_for_request` | 388 |
| `Dka_Tools_Pkg.get_parameter` | 561 |
| `Fnd_File.put_line` | 730 |
| `Fnd_File.put_line` | 731 |
| `Fnd_File.put_line` | 733 |
| `Fnd_File.put_line` | 734 |
| `Fnd_File.put_line` | 735 |
| `Fnd_File.put_line` | 736 |
| `Fnd_File.put_line` | 740 |
| `Fnd_File.put_line` | 747 |
| `Fnd_File.put_line` | 753 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `RVCTP` | 115 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 133, 552, 640 |
| rollback | 756 |
| when_others | 39, 51, 180, 252, 353, 408, 755 |
| suppression | 536, 542, 549 |
| soumission | 115 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKAFUSPORECVTOTAL / DKA | `DKA_FUSPORECVTOTAL_PKG.Main` | dka/12.0.0/admin/import/DKA_FUSPORECVTOTAL.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
