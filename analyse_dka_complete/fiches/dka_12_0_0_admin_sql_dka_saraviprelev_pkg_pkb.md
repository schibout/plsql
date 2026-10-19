# DKA_SARAVIPRELEV_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARAVIPRELEV_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARAVIPRELEV_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 524 ; encodage : cp1252 (repli). SHA-256 : `095618dc6779dfde26f07950b9b979834ba7033d3cab3d3328e1ae07c7a8d2a6`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 54 |
| `log_msg` | 68 |
| `lance_trait_pdf` | 93 |
| `lance_trait` | 225 |
| `edition_output` | 321 |
| `EDITION_OUTPUT` | 410 |
| `main` | 426 |
| `MAIN` | 515 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_programs` | 121 |
| `fnd_application` | 122 |
| `DKA_SARPREL_ATTACH_TMP` | 185 |
| `fnd_concurrent_programs` | 250 |
| `fnd_application` | 251 |
| `DKA_SARAUTOPRELEV_TMP` | 336 |
| `v$database` | 352 |
| `fnd_application` | 357 |
| `fnd_conc_req_summary_v` | 363 |
| `DKA_SARAUTOPRELEV_TMP` | 439 |
| `DKA_SARPREL_ATTACH_TMP` | 461 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 39 |
| `fnd_profile.value` | 40 |
| `fnd_file.put_line` | 57 |
| `fnd_file.put_line` | 78 |
| `fnd_request.add_layout` | 138 |
| `fnd_request.submit_request` | 145 |
| `fnd_concurrent.wait_for_request` | 163 |
| `fnd_request.submit_request` | 260 |
| `fnd_concurrent.wait_for_request` | 277 |
| `fnd_profile.VALUE` | 358 |
| `fnd_profile.VALUE` | 375 |
| `fnd_profile.value` | 445 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 154, 268, 490 |
| when_others | 125, 207, 254, 304, 367, 408, 514 |
| suppression | 461 |
| soumission | 145, 260 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARAVIPRELEV / DKA | `DKA_SARAVIPRELEV_PKG.main` | dka/12.0.0/admin/import/DKA_SARAVIPRELEV_F.prt:419 |
| DKA_SARAVIPRELEV / DKA | `DKA_SARAVIPRELEV_PKG.main` | dka/12.0.0/admin/import/DKA_SARAVIPRELEV_F.prt:419 |
| DKA_SARAVIPRELEV / DKA | `DKA_SARAVIPRELEV_PKG.main` | dka/12.0.0/admin/import/DKA_SARAVIPRELEV_US.prt:419 |
| DKA_SARAVIPRELEV / DKA | `DKA_SARAVIPRELEV_PKG.main` | dka/12.0.0/admin/import/DKA_SARAVIPRELEV_US.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
