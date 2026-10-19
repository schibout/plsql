# DKA_SARSELECAVOIR_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SARSELECAVOIR_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SARSELECAVOIR_PKG.pks).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 71 ; encodage : cp1252 (repli). SHA-256 : `393d9a29055b621285e64222ca85986074aa34d49c92cb2fe750c24c69729f76`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 42 |
| `log_msg` | 43 |
| `init` | 44 |
| `write_boundary` | 45 |
| `begin_attachment` | 47 |
| `end_attachment` | 52 |
| `check_value_set` | 54 |
| `writeout` | 59 |
| `sortie_traitement` | 60 |
| `extraction_avoir_nonsold` | 61 |
| `main` | 63 |

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
| DKA_SARSELECAVOIR / DKA | `DKA_SARSELECAVOIR_PKG.main` | dka/12.0.0/admin/import/DKA_SARSELECAVOIR.prt:534 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
