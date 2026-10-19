# DKA_SPASINISTRE_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SPASINISTRE_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SPASINISTRE_PKG.pks).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 200 ; encodage : cp1252 (repli). SHA-256 : `2354f0321c2eabb01be5b5ee763f003705869e0b892e19c2516aa57a1601573d`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 43 |
| `clear_spasinistre_tmp` | 63 |
| `get_sum_charges` | 79 |
| `process_active_tasks` | 100 |
| `create_output` | 119 |
| `gl_open_interface` | 134 |
| `main` | 152 |
| `reverse` | 172 |
| `main_extourne` | 192 |

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
| DKA_SPASINISTRE / DKA | `DKA_SPASINISTRE_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SPASINISTRE.prt:495 |
| DKA_SPASINISTRE_EXTOURNE / DKA | `DKA_SPASINISTRE_PKG.MAIN_EXTOURNE` | dka/12.0.0/admin/import/DKA_SPASINISTRE_EXTOURNE.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
