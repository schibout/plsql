# DKA_SAPCLOTURE.sql

Source : [dka/12.0.0/sql/DKA_SAPCLOTURE.sql](../../dka/12.0.0/sql/DKA_SAPCLOTURE.sql).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 142 ; encodage : cp1252 (repli). SHA-256 : `30ac175377a63c0030b7dff148424104a97dee8d97c00ee3a5621f5c3864a38c`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_user` | 71 |
| `fnd_request_sets` | 79 |
| `DUAL` | 141 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.get_parameter` | 52 |
| `fnd_global.apps_initialize` | 85 |
| `fnd_profile.value` | 87 |
| `dka_tools_pkg.launch_request_set` | 90 |
| `fnd_concurrent.wait_for_request` | 112 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 100 |
| when_others | 133 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
