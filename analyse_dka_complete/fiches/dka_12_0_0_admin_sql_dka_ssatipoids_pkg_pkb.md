# DKA_SSATIPOIDS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SSATIPOIDS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SSATIPOIDS_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 405 ; encodage : cp1252 (repli). SHA-256 : `397ec611cba25b537f0617de23f87aa17514d0ae5ca22b6cecdc7fe371a3e6d2`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `character_weight` | 38 |
| `amount_weight` | 76 |
| `beneficiary_weight` | 122 |
| `main` | 175 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_ssatipoids` | 46 |
| `DKA_IEOAPSAT01_APIMP_HDR` | 200 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_SSATIPOIDS_PKG.character_weight` | 92 |
| `DKA_SSATIPOIDS_PKG.character_weight` | 137 |
| `dka_ssatipoids_pkg.amount_weight` | 308 |
| `dka_ssatipoids_pkg.beneficiary_weight` | 316 |
| `dka_tools_pkg.put_debug_message` | 328 |
| `dka_tools_pkg.put_debug_message` | 329 |
| `dka_tools_pkg.put_debug_message` | 330 |
| `dka_tools_pkg.put_outdebug_message` | 376 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 56, 104, 150, 394 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SSATIPOIDS / DKA | `dka_ssatipoids_pkg.main` | dka/12.0.0/admin/import/DKA_SSATIPOIDS.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
