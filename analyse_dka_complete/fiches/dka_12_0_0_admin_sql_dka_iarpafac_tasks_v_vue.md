# DKA_IARPAFAC_TASKS_V.vue

Source : [dka/12.0.0/admin/sql/DKA_IARPAFAC_TASKS_V.vue](../../dka/12.0.0/admin/sql/DKA_IARPAFAC_TASKS_V.vue).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 54 ; encodage : cp1252 (repli). SHA-256 : `e3c12cfd682f782176d53731e9678cda53f9377d85a888b9e0901f0a0fcd85f5`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `pa_projects_all` | 30 |
| `gl_period_statuses` | 33 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_PROFILE.VALUE` | 42 |
| `fnd_date.canonical_to_date` | 50 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
