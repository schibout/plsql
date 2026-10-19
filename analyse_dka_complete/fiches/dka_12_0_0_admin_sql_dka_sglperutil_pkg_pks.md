# DKA_SGLPERUTIL_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SGLPERUTIL_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SGLPERUTIL_PKG.pks).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 142 ; encodage : cp1252 (repli). SHA-256 : `4a02d24a029142a772ff0361d1e462151a4ce06cd16a3f37555a496348dd1f32`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_select_record_group` | 125 |
| `update_gl_tax_ccid` | 133 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_periods` | 37 |
| `gl_period_statuses_actual_v` | 42 |
| `ZX_SCO_RATES` | 89 |
| `zx_account_rates` | 99 |
| `zx_account_rates` | 107 |

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
