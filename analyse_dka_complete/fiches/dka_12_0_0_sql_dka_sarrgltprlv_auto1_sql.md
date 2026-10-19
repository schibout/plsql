# DKA_SARRGLTPRLV_AUTO1.sql

Source : [dka/12.0.0/sql/DKA_SARRGLTPRLV_AUTO1.sql](../../dka/12.0.0/sql/DKA_SARRGLTPRLV_AUTO1.sql).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 239 ; encodage : cp1252 (repli). SHA-256 : `2dfa0d5397bd61767418ae76424f1e7775e34d5a5954c0501a1eb0b7d7bc6d60`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `MO_GLOB_ORG_ACCESS_TMP` | 63 |
| `fnd_responsibility` | 73 |
| `fnd_user` | 78 |
| `fnd_concurrent_programs` | 88 |
| `DUAL` | 125 |
| `DUAL` | 238 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 94 |
| `dka_tools_pkg.get_request_set_params` | 101 |
| `fnd_request.submit_request` | 131 |
| `Fnd_Concurrent.wait_for_request` | 174 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 143 |
| when_others | 231 |
| soumission | 131 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
