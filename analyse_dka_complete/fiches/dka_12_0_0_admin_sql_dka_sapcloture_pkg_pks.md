# DKA_SAPCLOTURE_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SAPCLOTURE_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SAPCLOTURE_PKG.pks).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 219 ; encodage : cp1252 (repli). SHA-256 : `16c255674e82663fb0ce222148f2e6a385f9d9fd527e4a39fa6b0c58655584ae`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `cherche_period` | 47 |
| `cherche_next_period` | 67 |
| `main` | 195 |
| `launch_xdodtexe` | 211 |

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
| DKA_SAPCLOTURE / DKA | `dka_sapcloture_pkg.main` | dka/12.0.0/admin/import/DKA_SAPCLOTURE.prt:419 |
| DKA_XDODTEXE / DKA | `DKA_SAPCLOTURE_PKG.launch_xdodtexe` | dka/12.0.0/admin/import/DKA_XDODTEXE.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
