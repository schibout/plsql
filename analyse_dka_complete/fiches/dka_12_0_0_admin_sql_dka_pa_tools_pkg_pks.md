# DKA_PA_TOOLS_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_PA_TOOLS_PKG.pks](../../dka/12.0.0/admin/sql/DKA_PA_TOOLS_PKG.pks).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 382 ; encodage : cp1252 (repli). SHA-256 : `426a92a907946d0baaad6844036ffcd36da1f527ac1739efad4f411a9c76303b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `pa_check_transaction_data` | 48 |
| `pa_aa_run_function_transaction` | 73 |
| `pa_insert_event` | 113 |
| `pa_get_info_task` | 168 |
| `pa_get_code_z_refac` | 192 |
| `get_project_info` | 217 |
| `pa_run_accounting_rule` | 240 |
| `get_centre_finance` | 268 |
| `get_appart` | 288 |
| `get_class_project` | 308 |
| `get_parent_project` | 324 |
| `pa_get_project_task` | 344 |
| `pa_get_period` | 369 |

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

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
