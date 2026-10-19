# DKA_GL_TOOLS_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_GL_TOOLS_PKG.pks](../../dka/12.0.0/admin/sql/DKA_GL_TOOLS_PKG.pks).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 134 ; encodage : cp1252 (repli). SHA-256 : `b2e92f8fc44e266ebb917d6517fda6f83a969030fbef469ac00d88261a02a6ca`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `gl_get_lookup_meaning` | 41 |
| `get_legder_id` | 58 |
| `gl_get_category_autorev_flag` | 80 |
| `period_gl_to_close` | 102 |
| `gl_is_special_period_open` | 123 |

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
