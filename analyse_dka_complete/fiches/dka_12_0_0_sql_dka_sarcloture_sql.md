# DKA_SARCLOTURE.sql

Source : [dka/12.0.0/sql/DKA_SARCLOTURE.sql](../../dka/12.0.0/sql/DKA_SARCLOTURE.sql).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 274 ; encodage : cp1252 (repli). SHA-256 : `40d7be452fbd0c69c79caf159e52ba005d92b6b3ee7b36be8bd76f0f9f26452d`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility` | 49 |
| `fnd_user` | 54 |
| `fnd_request_sets` | 76 |
| `DUAL` | 273 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 82 |
| `fnd_profile.value` | 84 |
| `fnd_profile.value` | 106 |
| `dka_tools_pkg.launch_request_set` | 109 |
| `fnd_concurrent.wait_for_request` | 244 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 119 |
| when_others | 265 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
