# DKA_SPOXRAF.sql

Source : [dka/12.0.0/sql/DKA_SPOXRAF.sql](../../dka/12.0.0/sql/DKA_SPOXRAF.sql).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 259 ; encodage : cp1252 (repli). SHA-256 : `08f6a5eeac8087848062156da328079769b3b90253f37351f95c6dd3cd419794`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_user` | 100 |
| `hr_operating_units` | 109 |
| `PER_SECURITY_ORGANIZATIONS` | 117 |
| `PER_SECURITY_PROFILES` | 120 |
| `fnd_concurrent_programs` | 142 |
| `fnd_responsibility` | 158 |
| `DUAL` | 258 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 169 |
| `fnd_profile.value` | 174 |
| `fnd_request.submit_request` | 179 |
| `Fnd_Concurrent.wait_for_request` | 213 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 188, 236 |
| when_others | 103, 162, 250 |
| soumission | 179 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
