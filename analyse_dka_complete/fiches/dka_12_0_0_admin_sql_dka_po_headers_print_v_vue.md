# DKA_PO_HEADERS_PRINT_V.vue

Source : [dka/12.0.0/admin/sql/DKA_PO_HEADERS_PRINT_V.vue](../../dka/12.0.0/admin/sql/DKA_PO_HEADERS_PRINT_V.vue).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 279 ; encodage : cp1252 (repli). SHA-256 : `016afb2b0c54b69136f4ba728cc964f3cdc0b20290cbd54bb3eaad67b3c3735c`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_po_headers_print_niv1_v` | 265 |
| `po_line_locations_all` | 276 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 167 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 168 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 169 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 170 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 172 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 177 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 199 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 201 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 206 |
| `DKA_SPOBON_PKG.nb_promised_date` | 210 |
| `DKA_SPOBON_PKG.nb_promised_date` | 212 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 217 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 224 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
