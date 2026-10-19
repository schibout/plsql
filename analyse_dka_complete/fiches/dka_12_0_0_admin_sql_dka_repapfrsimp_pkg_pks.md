# DKA_REPAPFRSIMP_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_REPAPFRSIMP_PKG.pks](../../dka/12.0.0/admin/sql/DKA_REPAPFRSIMP_PKG.pks).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 66 ; encodage : utf-8. SHA-256 : `6993660979e5e1034263fed2e5b557d9d326eaf8ac0509d5d868ff7bddb45d31`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `MAIN` | 34 |
| `update_parent_vendor` | 58 |

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
| DKA_REPAPFRSIMP / DKA | `DKA_REPAPFRSIMP_PKG.MAIN` | dka/12.0.0/admin/import/DKA_REPAPFRSIMP.prt:557 |
| DKA_REPAPFRSMAJ / DKA | `DKA_REPAPFRSIMP_PKG.update_parent_vendor` | dka/12.0.0/admin/import/DKA_REPAPFRSMAJ.prt:420 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
