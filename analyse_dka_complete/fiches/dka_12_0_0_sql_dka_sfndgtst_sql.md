# DKA_SFNDGTST.sql

Source : [dka/12.0.0/sql/DKA_SFNDGTST.sql](../../dka/12.0.0/sql/DKA_SFNDGTST.sql).

Famille proposée par convention de nommage : **FND / administration**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 136 ; encodage : cp1252 (repli). SHA-256 : `f50815636f45bf48ee0320e669359eb797a3dffd9086c849c21660b8ee4b948a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility` | 52 |
| `fnd_user` | 57 |
| `fnd_concurrent_programs` | 67 |
| `DUAL` | 135 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 73 |
| `fnd_profile.value` | 75 |
| `fnd_request.submit_request` | 79 |
| `fnd_concurrent.wait_for_request` | 106 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 96 |
| when_others | 127 |
| soumission | 79 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
