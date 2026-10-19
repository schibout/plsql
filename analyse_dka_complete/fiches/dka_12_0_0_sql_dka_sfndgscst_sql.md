# DKA_SFNDGSCST.sql

Source : [dka/12.0.0/sql/DKA_SFNDGSCST.sql](../../dka/12.0.0/sql/DKA_SFNDGSCST.sql).

Famille proposée par convention de nommage : **FND / administration**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 134 ; encodage : cp1252 (repli). SHA-256 : `dcf8cb7beca55872650b6f135a56927122e509fbc7f4932cd73c78adf5fa0406`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility` | 50 |
| `fnd_user` | 55 |
| `fnd_concurrent_programs` | 65 |
| `DUAL` | 133 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 71 |
| `fnd_profile.value` | 73 |
| `fnd_request.submit_request` | 76 |
| `fnd_concurrent.wait_for_request` | 104 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 93 |
| when_others | 125 |
| soumission | 76 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
