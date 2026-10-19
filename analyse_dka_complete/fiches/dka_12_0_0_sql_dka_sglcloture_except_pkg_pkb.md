# DKA_SGLCLOTURE_EXCEPT_PKG.pkb

Source : [dka/12.0.0/sql/DKA_SGLCLOTURE_EXCEPT_PKG.pkb](../../dka/12.0.0/sql/DKA_SGLCLOTURE_EXCEPT_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 496 ; encodage : cp1252 (repli). SHA-256 : `912a248eaa3c74e3b72153999f9f8b01281e29aacb658a0f562c8dc1b0c32fd3`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `check_setup` | 50 |
| `get_autoposting_set` | 107 |
| `get_period` | 126 |
| `period_gl_courante` | 151 |
| `my_wait_for_request` | 181 |
| `my_submit_request` | 233 |
| `Close_GL_Period` | 289 |
| `main` | 418 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_automatic_posting_sets` | 40 |
| `gl_automatic_posting_options` | 41 |
| `gl_access_sets` | 71 |
| `gl_period_statuses` | 130 |
| `gl_period_statuses` | 155 |
| `gl_je_lines` | 363 |
| `gl_code_combinations` | 367 |
| `GL_ACCESS_SET_LEDGERS` | 429 |
| `GL_LEDGERS` | 430 |
| `gl_automatic_posting_sets` | 477 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 56 |
| `Fnd_Profile.VALUE` | 62 |
| `dka_tools_pkg.put_debug_message` | 63 |
| `dka_tools_pkg.put_debug_message` | 73 |
| `dka_tools_pkg.put_debug_message` | 85 |
| `fnd_concurrent.wait_for_request` | 194 |
| `dka_tools_pkg.put_debug_message` | 204 |
| `dka_tools_pkg.put_debug_message` | 207 |
| `dka_tools_pkg.put_debug_message` | 211 |
| `dka_tools_pkg.put_debug_message` | 214 |
| `fnd_request.submit_request` | 250 |
| `dka_tools_pkg.put_debug_message` | 266 |
| `dka_tools_pkg.put_debug_message` | 300 |
| `dka_tools_pkg.put_debug_message` | 301 |
| `dka_tools_pkg.put_debug_message` | 305 |
| `dka_tools_pkg.put_debug_message` | 310 |
| `dka_tools_pkg.put_debug_message` | 316 |
| `dka_tools_pkg.put_debug_message` | 318 |
| `gl_period_statuses_pkg.get_next_period` | 322 |
| `dka_tools_pkg.put_debug_message` | 323 |
| `dka_tools_pkg.put_debug_message` | 325 |
| `dka_tools_pkg.put_debug_message` | 347 |
| `dka_tools_pkg.put_debug_message` | 361 |
| `dka_tools_pkg.put_debug_message` | 369 |
| `dka_tools_pkg.put_debug_message` | 372 |
| `dka_tools_pkg.put_debug_message` | 384 |
| `dka_tools_pkg.put_debug_message` | 402 |
| `dka_tools_pkg.put_debug_message` | 435 |
| `dka_tools_pkg.put_debug_message` | 436 |
| `Fnd_Profile.VALUE` | 442 |
| `dka_tools_pkg.put_debug_message` | 452 |
| `dka_tools_pkg.put_debug_message` | 453 |
| `dka_tools_pkg.put_debug_message` | 464 |
| `dka_tools_pkg.put_debug_message` | 465 |
| `dka_tools_pkg.put_debug_message` | 476 |
| `dka_tools_pkg.put_debug_message` | 485 |
| `dka_tools_pkg.put_debug_message` | 488 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 269, 483 |
| when_others | 487 |
| soumission | 250 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SGLCLOTURE_EXCEPT / DKA | `DKA_SGLCLOTURE_EXCEPT_PKG.main` | dka/12.0.0/admin/import/DKA_SGLCLOTURE_EXCEPT.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
