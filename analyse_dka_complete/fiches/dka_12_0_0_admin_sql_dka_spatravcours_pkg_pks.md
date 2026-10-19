# DKA_SPATRAVCOURS_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SPATRAVCOURS_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SPATRAVCOURS_PKG.pks).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 210 ; encodage : cp1252 (repli). SHA-256 : `3c60e319fdd211354fb5172603baf4929c4b07065bc27052cedfb38e5a903565`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 48 |
| `clear_spatravcours_tmp` | 68 |
| `maj_calcule` | 83 |
| `maj_facture` | 100 |
| `process_projects` | 119 |
| `create_output` | 137 |
| `gl_open_interface` | 152 |
| `main` | 169 |
| `reverse` | 186 |
| `main_reverse` | 201 |

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
| DKA_SPATRAVCOURS / DKA | `DKA_SPATRAVCOURS_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SPATRAVCOURS.prt:494 |
| DKA_SPATRAVCOURS_EXTOURNE / DKA | `DKA_SPATRAVCOURS_PKG.main_reverse` | dka/12.0.0/admin/import/DKA_SPATRAVCOURS_EXTOURNE.prt:421 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
