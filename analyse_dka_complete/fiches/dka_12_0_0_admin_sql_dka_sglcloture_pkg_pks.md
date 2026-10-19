# DKA_SGLCLOTURE_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SGLCLOTURE_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SGLCLOTURE_PKG.pks).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 192 ; encodage : cp1252 (repli). SHA-256 : `11e8e96868f5c673e615339bac11c1e517ca782045077deda1a92907986afe97`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_configuration_id` | 28 |
| `get_legal` | 42 |
| `get_restit` | 56 |
| `period_to_close` | 72 |
| `period_to_open` | 92 |
| `CONSOLIDATION_RESTIT` | 114 |
| `open_next_period` | 130 |
| `CLOSE_PREVIOUS_PERIOD` | 151 |
| `CLOSE_LEDGER` | 172 |
| `main` | 185 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SGLCLOTURE / DKA | `DKA_SGLCLOTURE_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SGLCLOTURE.prt:483 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
