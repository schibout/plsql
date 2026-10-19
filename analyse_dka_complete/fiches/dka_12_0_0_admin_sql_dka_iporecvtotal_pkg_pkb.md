# DKA_IPORECVTOTAL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IPORECVTOTAL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IPORECVTOTAL_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1419 ; encodage : cp1252 (repli). SHA-256 : `230b905959b7077bf372f4608323876b6fb8fca3d0170740cb07dcb5828e85be`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `put_line_log` | 41 |
| `put_line_out` | 53 |
| `insert_rcv_headers` | 76 |
| `insert_rcv_transactions` | 142 |
| `correction_reception` | 238 |
| `complement_recept_correction` | 654 |
| `complement_recept_correction_2` | 824 |
| `wait_rvctp` | 1186 |
| `main` | 1239 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `rcv_headers_interface` | 87 |
| `rcv_transactions_interface` | 160 |
| `dka_contrat_sstr_imputation` | 289 |
| `DKA_CONTRAT_SSTR_ARCHI` | 306 |
| `DKA_CONTRAT_SSTR` | 309 |
| `po_headers_all` | 325 |
| `dka_contrat_sstr_imputation` | 354 |
| `po_headers_all` | 395 |
| `dual` | 415 |
| `rcv_transactions` | 431 |
| `rcv_transactions_interface` | 445 |
| `dual` | 522 |
| `rcv_transactions` | 539 |
| `rcv_transactions_interface` | 554 |
| `po_distributions_all` | 689 |
| `po_headers_all` | 704 |
| `po_headers_all` | 737 |
| `dual` | 786 |
| `po_distributions_all` | 858 |
| `po_headers_all` | 873 |
| `po_headers_all` | 914 |
| `dual` | 935 |
| `rcv_transactions` | 952 |
| `rcv_transactions_interface` | 967 |
| `dual` | 1044 |
| `rcv_transactions` | 1061 |
| `rcv_transactions_interface` | 1076 |
| `po_headers_all` | 1269 |
| `po_headers_all` | 1282 |
| `rcv_shipment_lines` | 1297 |
| `po_headers_all` | 1318 |
| `dual` | 1366 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 43 |
| `fnd_file.put_line` | 55 |
| `wf_engine.getitemattrnumber` | 297 |
| `dka_spowfmaster_pkg.get_montant_presta_unit` | 341 |
| `dka_spowfmaster_pkg.get_montant_imput` | 343 |
| `wf_engine.setitemattrnumber` | 632 |
| `wf_engine.setitemattrnumber` | 637 |
| `wf_engine.getitemattrnumber` | 715 |
| `wf_engine.setitemattrnumber` | 800 |
| `wf_engine.getitemattrnumber` | 884 |
| `wf_engine.setitemattrnumber` | 1154 |
| `wf_engine.setitemattrnumber` | 1159 |
| `fnd_concurrent.wait_for_request` | 1200 |
| `dka_tools_pkg.get_message` | 1289 |
| `dka_tools_pkg.get_message` | 1303 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 625, 779, 1148, 1358 |
| rollback | 1411 |
| when_others | 45, 57, 121, 222, 315, 330, 405, 418, 525, 789, 924, 938, 1047, 1220, 1410 |
| workflow | 297, 632, 637, 715, 800, 807, 809, 884, 1154, 1159, 1166, 1168 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
