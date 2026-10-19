# DKA_PO_DIST_INTERFACE_BIR.trg

Source : [dka/12.0.0/admin/sql/DKA_PO_DIST_INTERFACE_BIR.trg](../../dka/12.0.0/admin/sql/DKA_PO_DIST_INTERFACE_BIR.trg).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 118 ; encodage : cp1252 (repli). SHA-256 : `337f0ded2fdb64f8d009641d3b17d833955917eb9fe736c83d071630d71c8b28`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `dka_po_dist_interface_bir` | 21 |
| `dka_po_dist_interface_bir` | 23 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_headers_interface` | 46 |
| `po_requisition_lines_all` | 63 |
| `po_requisition_lines_all` | 82 |
| `po_lines_interface` | 96 |
| `po_requisition_lines_all` | 98 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 49, 69, 85, 105 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
