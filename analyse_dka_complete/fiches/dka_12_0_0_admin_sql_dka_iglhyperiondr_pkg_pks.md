# DKA_IGLHYPERIONDR_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_IGLHYPERIONDR_PKG.pks](../../dka/12.0.0/admin/sql/DKA_IGLHYPERIONDR_PKG.pks).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 51 ; encodage : cp1252 (repli). SHA-256 : `33b0fbbc19385ed87b1150f45b3b954c954cc2138535f894ba472c06a143bf5d`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 39 |
| `main_qte` | 44 |

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
| DKA_IHYPERION / DKA | `DKA_IGLHYPERIONDR_PKG.main` | dka/12.0.0/admin/import/DKA_IHYPERION_F.prt:494 |
| DKA_IHYPERION_QTE / DKA | `DKA_IGLHYPERIONDR_PKG.main_qte` | dka/12.0.0/admin/import/DKA_IHYPERION_QTE_F.prt:494 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
