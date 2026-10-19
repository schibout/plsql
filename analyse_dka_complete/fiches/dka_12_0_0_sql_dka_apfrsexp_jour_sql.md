# DKA_APFRSEXP_JOUR.sql

Source : [dka/12.0.0/sql/DKA_APFRSEXP_JOUR.sql](../../dka/12.0.0/sql/DKA_APFRSEXP_JOUR.sql).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 121 ; encodage : cp1252 (repli). SHA-256 : `3c13e611f6f305dd1905400bae00fc9c66847ec76a95012a5cbaa5abee7c328d`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility` | 46 |
| `fnd_user` | 51 |
| `fnd_concurrent_programs` | 59 |
| `DUAL` | 120 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 65 |
| `fnd_profile.value` | 67 |
| `fnd_request.submit_request` | 70 |
| `fnd_concurrent.wait_for_request` | 91 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 79 |
| when_others | 112 |
| soumission | 70 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
