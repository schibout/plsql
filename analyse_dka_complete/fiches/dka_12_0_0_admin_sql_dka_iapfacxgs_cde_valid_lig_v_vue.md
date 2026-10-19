# DKA_IAPFACXGS_CDE_VALID_LIG_V.vue

Source : [dka/12.0.0/admin/sql/DKA_IAPFACXGS_CDE_VALID_LIG_V.vue](../../dka/12.0.0/admin/sql/DKA_IAPFACXGS_CDE_VALID_LIG_V.vue).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 89 ; encodage : cp1252 (repli). SHA-256 : `8997c90763e100a16e9e613984e82b389eaba49d6bec6947b0e3271229e69384`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_headers_all` | 54 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_iapfacxgs_pkg.get_id_br` | 39 |
| `dka_iapfacxgs_pkg.get_num_br` | 40 |
| `dka_iapfacxgs_pkg.get_packing_slip` | 41 |
| `dka_iapfacxgs_pkg.get_num_ligne_br` | 42 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
