# DKA_GLXRCAUT.sql

Source : [dka/12.0.0/sql/DKA_GLXRCAUT.sql](../../dka/12.0.0/sql/DKA_GLXRCAUT.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 721 ; encodage : cp1252 (repli). SHA-256 : `d884d4aef6019002c2aba32d32ef1f3e059e096ab27321e212d84493d6f40ab2`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_period_statuses` | 101 |
| `fnd_responsibility` | 141 |
| `fnd_user` | 146 |
| `fnd_concurrent_programs` | 156 |
| `GL_ACCESS_SETS` | 197 |
| `gl_period_statuses` | 335 |
| `gl_period_statuses` | 341 |
| `gl_period_statuses` | 382 |
| `gl_period_statuses` | 389 |
| `gl_period_statuses` | 430 |
| `gl_period_statuses` | 437 |
| `DUAL` | 720 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.VALUE` | 109 |
| `fnd_global.apps_initialize` | 162 |
| `fnd_profile.value` | 164 |
| `fnd_profile.VALUE` | 183 |
| `fnd_request.submit_request` | 347 |
| `fnd_request.submit_request` | 394 |
| `fnd_request.submit_request` | 442 |
| `Fnd_Concurrent.wait_for_request` | 681 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 374, 421, 469 |
| when_others | 711 |
| soumission | 347, 394, 442 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
