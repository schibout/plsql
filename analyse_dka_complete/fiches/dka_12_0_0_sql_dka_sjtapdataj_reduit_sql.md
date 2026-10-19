# DKA_SJTAPDATAJ_REDUIT.sql

Source : [dka/12.0.0/sql/DKA_SJTAPDATAJ_REDUIT.sql](../../dka/12.0.0/sql/DKA_SJTAPDATAJ_REDUIT.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 122 ; encodage : cp1252 (repli). SHA-256 : `fbe4e847c29f02b665322e251fa0578824e6ed1115864df32b7503a792b4e772`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility` | 46 |
| `fnd_user` | 51 |
| `fnd_request_sets` | 59 |
| `DUAL` | 121 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 65 |
| `fnd_profile.value` | 67 |
| `dka_tools_pkg.launch_request_set` | 70 |
| `fnd_concurrent.wait_for_request` | 92 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 80 |
| when_others | 113 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
