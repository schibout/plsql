# DKA_SPORECEP_FRAISPORT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPORECEP_FRAISPORT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPORECEP_FRAISPORT_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 865 ; encodage : cp1252 (repli). SHA-256 : `054219166ccbf28b71fc8214b3f39e0c2ae1bdde205b1c487def74358687a7bc`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `put_line_log` | 48 |
| `put_line_out` | 64 |
| `get_param_varchar` | 80 |
| `init` | 113 |
| `insert_rcv_headers` | 184 |
| `insert_rcv_transactions` | 269 |
| `insert_suivi` | 370 |
| `update_suivi` | 439 |
| `wait_RVCTP` | 498 |
| `main` | 551 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `RCV_HEADERS_INTERFACE` | 198 |
| `RCV_TRANSACTIONS_INTERFACE` | 288 |
| `dual` | 388 |
| `DKA_SPORECEP_TMP` | 391 |
| `DKA_SPORECEP_TMP` | 449 |
| `rcv_headers_interface` | 450 |
| `DKA_SPORECEP_TMP` | 456 |
| `po_interface_errors` | 457 |
| `DKA_SPORECEP_TMP` | 467 |
| `rcv_headers_interface` | 468 |
| `rcv_transactions` | 566 |
| `po_lines_all` | 570 |
| `po_lines_all` | 576 |
| `po_lines_all` | 587 |
| `po_lines_all` | 593 |
| `po_distributions_all` | 625 |
| `DKA_SPORECEP_TMP` | 654 |
| `dka_parameters` | 839 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 53 |
| `fnd_file.put_line` | 69 |
| `dka_tools_pkg.get_parameter` | 88 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 515 |
| `Fnd_Request.Submit_Request` | 743 |
| `dka_tools_pkg.put_outdebug_message` | 762 |
| `dka_tools_pkg.put_outdebug_message` | 763 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `RVCTP` | 743 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 155, 452, 463, 473, 724, 730, 757 |
| rollback | 852, 857 |
| when_others | 55, 71, 102, 161, 243, 345, 414, 476, 533, 855 |
| soumission | 743 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPORECEP_FRAISPORT / DKA | `DKA_SPORECEP_FRAISPORT_PKG.main` | dka/12.0.0/admin/import/DKA_SPORECEP_FRAISPORT_F.prt:475 |
| DKA_SPORECEP_FRAISPORT / DKA | `DKA_SPORECEP_FRAISPORT_PKG.main` | dka/12.0.0/admin/import/DKA_SPORECEP_FRAISPORT_F.prt:475 |
| DKA_SPORECEP_FRAISPORT / DKA | `DKA_SPORECEP_FRAISPORT_PKG.main` | dka/12.0.0/admin/import/DKA_SPORECEP_FRAISPORT_US.prt:475 |
| DKA_SPORECEP_FRAISPORT / DKA | `DKA_SPORECEP_FRAISPORT_PKG.main` | dka/12.0.0/admin/import/DKA_SPORECEP_FRAISPORT_US.prt:475 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
