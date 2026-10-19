# DKA_CREATE_ACCOUNT_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_CREATE_ACCOUNT_PKG.pks](../../dka/12.0.0/admin/sql/DKA_CREATE_ACCOUNT_PKG.pks).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 145 ; encodage : utf-8. SHA-256 : `70227f02d39a8325ccedd742f4cb5f57f6937c2e4195db99c66ed4ca24513a04`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 140 |

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
| DKA_CREATE_ACCOUNT_PKG / DKA | `DKA_CREATE_ACCOUNT_PKG.main` | dka/12.0.0/admin/import/DKA_CREATE_ACCOUNT_PKG_F.prt:458 |
| DKA_CREATE_ACCOUNT_PKG / DKA | `DKA_CREATE_ACCOUNT_PKG.main` | dka/12.0.0/admin/import/DKA_CREATE_ACCOUNT_PKG_F.prt:458 |
| DKA_CREATE_ACCOUNT_PKG / DKA | `DKA_CREATE_ACCOUNT_PKG.main` | dka/12.0.0/admin/import/DKA_CREATE_ACCOUNT_PKG_US.prt:458 |
| DKA_CREATE_ACCOUNT_PKG / DKA | `DKA_CREATE_ACCOUNT_PKG.main` | dka/12.0.0/admin/import/DKA_CREATE_ACCOUNT_PKG_US.prt:458 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
