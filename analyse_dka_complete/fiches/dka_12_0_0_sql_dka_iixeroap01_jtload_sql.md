# DKA_IIXEROAP01_JTLOAD.sql

Source : [dka/12.0.0/sql/DKA_IIXEROAP01_JTLOAD.sql](../../dka/12.0.0/sql/DKA_IIXEROAP01_JTLOAD.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 125 ; encodage : cp1252 (repli). SHA-256 : `c3e90e66be342f18e80b2f6ed94397b54f216576ef71501290b15a7a95423851`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility` | 48 |
| `fnd_user` | 53 |
| `fnd_request_sets` | 61 |
| `DUAL` | 124 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 67 |
| `fnd_profile.value` | 70 |
| `dka_tools_pkg.launch_request_set` | 73 |
| `fnd_concurrent.wait_for_request` | 95 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 83 |
| when_others | 116 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
