# DKA_SGLEQUILIB_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SGLEQUILIB_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SGLEQUILIB_PKG.pks).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 241 ; encodage : cp1252 (repli). SHA-256 : `3f0cdb1a63828a0dbd16cbe2884c7bc6a4d0f8c11dab2dff515c41090f75be54`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Init` | 41 |
| `launch_request` | 58 |
| `wait_GLPRJE` | 78 |
| `wait_GLPAUTOP` | 98 |
| `wait_GLPOS` | 118 |
| `delete_batch` | 136 |
| `delete_header` | 154 |
| `delete_lines` | 173 |
| `check_data` | 190 |
| `run_posting` | 204 |
| `get_first_char` | 215 |
| `main` | 231 |

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
| DKA_SGLEQUILIB / DKA | `DKA_SGLEQUILIB_PKG.main` | dka/12.0.0/admin/import/DKA_SGLEQUILIB.prt:483 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
