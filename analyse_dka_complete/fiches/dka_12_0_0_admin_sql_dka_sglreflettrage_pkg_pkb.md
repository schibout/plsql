# DKA_SGLREFLETTRAGE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SGLREFLETTRAGE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SGLREFLETTRAGE_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 569 ; encodage : cp1252 (repli). SHA-256 : `a5ec89438e8e9952d4f989cba5b0f3769b138d79a6017e0b88327e2a4e39e876`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 45 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_je_lines` | 68 |
| `gl_je_lines` | 122 |
| `GL_PERIODS` | 172 |
| `GL_PERIOD_TYPES` | 178 |
| `gl_je_batches` | 221 |
| `gl_je_headers` | 222 |
| `gl_je_categories_vl` | 226 |
| `gl_je_lines` | 229 |
| `gl_code_combinations_kfv` | 231 |
| `gl_periods` | 233 |
| `gl_periods` | 235 |
| `gl_access_sets` | 242 |
| `fnd_flex_value_sets` | 249 |
| `gl_je_lines_recon` | 258 |
| `gl_je_batches` | 261 |
| `gl_je_headers` | 266 |
| `gl_je_lines` | 269 |
| `gl_je_lines_recon` | 272 |
| `gl_access_sets` | 306 |
| `gl_je_lines_recon` | 349 |
| `gl_je_lines_recon` | 419 |
| `gl_je_lines_recon` | 491 |
| `gl_je_lines_recon` | 500 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 58 |
| `dka_tools_pkg.put_log_message` | 317 |
| `dka_tools_pkg.put_log_message` | 323 |
| `dka_tools_pkg.put_log_message` | 326 |
| `dka_tools_pkg.put_log_message` | 327 |
| `dka_tools_pkg.put_log_message` | 328 |
| `dka_tools_pkg.put_log_message` | 331 |
| `dka_tools_pkg.put_debug_message` | 339 |
| `fnd_profile.value` | 353 |
| `fnd_profile.value` | 354 |
| `dka_tools_pkg.put_debug_message` | 358 |
| `dka_tools_pkg.put_log_message` | 363 |
| `dka_tools_pkg.put_log_message` | 376 |
| `dka_tools_pkg.put_log_message` | 379 |
| `dka_tools_pkg.put_log_message` | 380 |
| `dka_tools_pkg.put_log_message` | 381 |
| `dka_tools_pkg.put_log_message` | 384 |
| `dka_tools_pkg.put_debug_message` | 392 |
| `fnd_profile.value` | 423 |
| `fnd_profile.value` | 424 |
| `dka_tools_pkg.put_debug_message` | 428 |
| `dka_tools_pkg.put_log_message` | 434 |
| `dka_tools_pkg.put_log_message` | 447 |
| `dka_tools_pkg.put_log_message` | 450 |
| `dka_tools_pkg.put_log_message` | 451 |
| `dka_tools_pkg.put_log_message` | 452 |
| `dka_tools_pkg.put_log_message` | 455 |
| `dka_tools_pkg.put_debug_message` | 463 |
| `fnd_profile.value` | 495 |
| `fnd_profile.value` | 496 |
| `fnd_profile.value` | 504 |
| `fnd_profile.value` | 505 |
| `dka_tools_pkg.put_debug_message` | 509 |
| `dka_tools_pkg.put_debug_message` | 514 |
| `dka_tools_pkg.put_log_message` | 520 |
| `dka_tools_pkg.put_log_message` | 533 |
| `dka_tools_pkg.put_log_message` | 537 |
| `dka_tools_pkg.put_outdebug_message` | 540 |
| `dka_tools_pkg.put_outdebug_message` | 541 |
| `dka_tools_pkg.put_outdebug_message` | 542 |
| `dka_tools_pkg.put_outdebug_message` | 543 |
| `dka_tools_pkg.put_outdebug_message` | 545 |
| `dka_tools_pkg.put_outdebug_message` | 547 |
| `dka_tools_pkg.put_outdebug_message` | 550 |
| `dka_tools_pkg.put_outdebug_message` | 552 |
| `dka_tools_pkg.put_outdebug_message` | 553 |
| `dka_tools_pkg.put_outdebug_message` | 555 |
| `dka_tools_pkg.put_log_message` | 561 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 366, 371, 437, 442, 523, 528 |
| rollback | 562 |
| when_others | 558 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SGLREFLETTRAGE / DKA | `DKA_SGLREFLETTRAGE_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SGLREFLETTRAGE.prt:489 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
