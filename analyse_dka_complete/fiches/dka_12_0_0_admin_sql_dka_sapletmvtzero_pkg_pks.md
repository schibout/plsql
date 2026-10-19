# DKA_SAPLETMVTZERO_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SAPLETMVTZERO_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SAPLETMVTZERO_PKG.pks).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 61 ; encodage : cp1252 (repli). SHA-256 : `8d609519a3ebe03a2697d052a46372c9e5c44390a5dbdbeb3280e4ce8b527d93`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Main` | 55 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_PROFILE.VALUE` | 27 |
| `FND_PROFILE.VALUE` | 28 |

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
| DKA_SAPLETMVTZERO / DKA | `DKA_SAPLETMVTZERO_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SAPLETMVTZERO.prt:403 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
