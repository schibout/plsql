# DKA_SAPWFSIMP.sql

Source : [dka/12.0.0/sql/DKA_SAPWFSIMP.sql](../../dka/12.0.0/sql/DKA_SAPWFSIMP.sql).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 72 ; encodage : cp1252 (repli). SHA-256 : `c4209f9a1860ca33396fc7775b332e92fe7464ba7de6a7ff383db67221aeab4d`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_PARAMETERS` | 36 |
| `DKA_PARAMETERS` | 45 |
| `DUAL` | 71 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 33 |
| `dka_tools_pkg.put_log_message` | 43 |
| `dka_tools_pkg.put_outdebug_message` | 61 |
| `dka_tools_pkg.put_outdebug_message` | 62 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 65 |
| when_others | 60 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPWFSIMP / DKA | `DKA_SAPWFSIMP` | dka/12.0.0/admin/import/DKA_SAPWFSIMP.prt:554 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
