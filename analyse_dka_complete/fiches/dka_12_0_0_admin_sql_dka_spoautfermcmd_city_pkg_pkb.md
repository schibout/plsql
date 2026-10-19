# DKA_SPOAUTFERMCMD_CITY_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOAUTFERMCMD_CITY_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOAUTFERMCMD_CITY_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 530 ; encodage : cp1252 (repli). SHA-256 : `32e9dbcfbf6ed85c3689d324b46705becd30c49a0f9cf10e2012cfe077d3525e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 57 |
| `output_end` | 111 |
| `out_msg` | 131 |
| `log_msg` | 146 |
| `main` | 161 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_programs` | 72 |
| `fnd_flex_values_vl` | 215 |
| `fnd_concurrent_requests` | 224 |
| `gl_periods` | 238 |
| `gl_period_statuses` | 241 |
| `hr_operating_units` | 244 |
| `PER_SECURITY_ORGANIZATIONS` | 246 |
| `PER_SECURITY_PROFILES` | 249 |
| `fnd_concurrent_programs` | 278 |
| `fnd_concurrent_programs` | 370 |
| `fnd_responsibility_vl` | 384 |
| `fnd_user` | 389 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 27 |
| `fnd_profile.value` | 29 |
| `fnd_profile.value` | 30 |
| `Fnd_File.put_line` | 87 |
| `Fnd_File.put_line` | 88 |
| `Fnd_File.put_line` | 89 |
| `Fnd_File.put_line` | 90 |
| `Fnd_File.put_line` | 91 |
| `Fnd_File.put_line` | 118 |
| `Fnd_File.put_line` | 119 |
| `Fnd_File.put_line` | 120 |
| `fnd_file.put_line` | 134 |
| `fnd_file.put_line` | 156 |
| `fnd_request.submit_request` | 288 |
| `fnd_concurrent.wait_for_request` | 315 |
| `Fnd_File.put_line` | 341 |
| `Fnd_File.put_line` | 342 |
| `Fnd_File.put_line` | 345 |
| `Fnd_File.put_line` | 348 |
| `Fnd_File.put_line` | 357 |
| `Fnd_File.put_line` | 358 |
| `fnd_global.apps_initialize` | 393 |
| `fnd_profile.value` | 394 |
| `fnd_request.submit_request` | 397 |
| `fnd_concurrent.wait_for_request` | 439 |
| `Fnd_File.put_line` | 471 |
| `Fnd_File.put_line` | 475 |
| `Fnd_File.put_line` | 487 |
| `Fnd_File.put_line` | 504 |
| `Fnd_File.put_line` | 505 |
| `Fnd_File.put_line` | 506 |
| `Fnd_File.put_line` | 507 |
| `Fnd_File.put_line` | 512 |
| `Fnd_File.put_line` | 513 |
| `Fnd_File.put_line` | 514 |
| `Fnd_File.put_line` | 515 |
| `Fnd_File.put_line` | 521 |
| `Fnd_File.put_line` | 522 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 300, 410 |
| when_others | 80, 253, 517 |
| soumission | 288, 397 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOAUTFERMCMD_CITY / DKA | `DKA_SPOAUTFERMCMD_CITY_PKG.main` | dka/12.0.0/admin/import/DKA_SPOAUTFERMCMD_CITY.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
