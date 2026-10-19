# DKA_REPFAIMOIMP_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_REPFAIMOIMP_PKG.pks](../../dka/12.0.0/admin/sql/DKA_REPFAIMOIMP_PKG.pks).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 42 ; encodage : cp1252 (repli). SHA-256 : `3b129193214eb0ea1675ee2217045cb8e436764be1a7db6e348cd57ffee78f53`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 31 |

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
| rollback | 2 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPFAIMOIMP / DKA | `DKA_REPFAIMOIMP_PKG.Main` | dka/12.0.0/admin/import/DKA_REPFAIMOIMP.prt:515 |
| DKA_REPFAIMOIMPCAL / DKA | `DKA_REPFAIMOIMP_PKG.Main_calisto` | dka/12.0.0/admin/import/DKA_REPFAIMOIMPCAL.prt:533 |
| DKA_REPFAIMOIMPSOC / DKA | `DKA_REPFAIMOIMP_PKG.Main_immo` | dka/12.0.0/admin/import/DKA_REPFAIMOIMPSOC.prt:533 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
