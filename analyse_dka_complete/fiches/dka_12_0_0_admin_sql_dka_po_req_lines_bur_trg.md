# DKA_PO_REQ_LINES_BUR.trg

Source : [dka/12.0.0/admin/sql/DKA_PO_REQ_LINES_BUR.trg](../../dka/12.0.0/admin/sql/DKA_PO_REQ_LINES_BUR.trg).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 522 ; encodage : cp1252 (repli). SHA-256 : `3040f3ca4cd0036b8796342bbdaad9d1a54fd5595d2aa36f90b9c0c7b203d29b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `dka_po_req_lines_bur` | 1 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ON` | 52 |
| `po_requisition_headers_all` | 112 |
| `po_req_distributions_all` | 149 |
| `po_line_locations_all` | 157 |
| `FINANCIALS_SYSTEM_PARAMS_ALL` | 187 |
| `po_headers_all` | 241 |
| `po_headers_all` | 263 |
| `po_headers_all` | 280 |
| `po_headers_all` | 303 |
| `po_headers_all` | 319 |
| `po_headers_all` | 342 |
| `po_headers_all` | 358 |
| `fnd_flex_values` | 427 |
| `po_distributions_all` | 482 |
| `po_lines_all` | 508 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 128, 165, 233, 248, 270, 288, 310, 327, 349, 365, 492, 512 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
