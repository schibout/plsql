# DKA_SARSURTAXE.sql

Source : [dka/12.0.0/sql/DKA_SARSURTAXE.sql](../../dka/12.0.0/sql/DKA_SARSURTAXE.sql).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 213 ; encodage : cp1252 (repli). SHA-256 : `32346c78eddfdadf85b69b3a339383942564a9be54a8dacb5068f9b36ff6843f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `hr_all_organization_units` | 54 |
| `ra_cust_trx_line_gl_dist_all` | 56 |
| `fnd_user` | 120 |
| `fnd_request_sets` | 128 |
| `fnd_responsibility` | 141 |
| `DUAL` | 212 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_AR_TOOLS_PKG.issurtaxeaccount` | 73 |
| `fnd_global.apps_initialize` | 146 |
| `fnd_profile.value` | 153 |
| `FND_REQUEST.SET_OPTIONS` | 155 |
| `dka_tools_pkg.launch_request_set` | 159 |
| `fnd_concurrent.wait_for_request` | 183 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 169 |
| when_others | 204 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARSURTAXE_RDF / DKA | `DKA_SARSURTAXE` | dka/12.0.0/admin/import/DKA_SARSURTAXE_RDF.prt:473 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
