# DKA_SXLAACCPB_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SXLAACCPB_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SXLAACCPB_PKG.pkb).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 540 ; encodage : cp1252 (repli). SHA-256 : `7719d178f7b810affaf0e85b5184623efff18fcb593edc4b233630848a41bc19`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 118 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_ledgers` | 206 |
| `xla_events` | 208 |
| `xla.xla_transaction_entities` | 209 |
| `fnd_concurrent_programs` | 244 |
| `fnd_responsibility` | 264 |
| `XLA_LOOKUPS` | 298 |
| `XLA_LOOKUPS` | 305 |
| `XLA_LOOKUPS` | 312 |
| `XLA_LOOKUPS` | 319 |
| `XLA_LOOKUPS` | 326 |
| `XLA_LOOKUPS` | 333 |
| `XLA_LOOKUPS` | 340 |
| `XLA_LOOKUPS` | 348 |
| `XLA_LOOKUPS` | 360 |
| `XLA_LOOKUPS` | 361 |
| `DUAL` | 362 |
| `XLA_LOOKUPS` | 363 |
| `xla_lookups` | 364 |
| `fnd_application_tl` | 365 |
| `fnd_application_tl` | 366 |
| `XLA_LOOKUPS` | 369 |
| `gl_ledgers` | 370 |
| `XLA_LOOKUPS` | 371 |
| `XLA_LOOKUPS` | 372 |
| `XLA_LOOKUPS` | 373 |
| `gl_period_statuses` | 407 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.get_parameter` | 224 |
| `dka_tools_pkg.put_debug_message` | 234 |
| `fnd_global.apps_initialize` | 269 |
| `dka_tools_pkg.put_debug_message` | 276 |
| `dka_tools_pkg.put_debug_message` | 293 |
| `fnd_profile.value` | 365 |
| `fnd_profile.value` | 366 |
| `fnd_profile.value` | 376 |
| `fnd_profile.value` | 377 |
| `dka_tools_pkg.put_debug_message` | 417 |
| `FND_REQUEST.add_layout` | 420 |
| `fnd_request.submit_request` | 428 |
| `dka_tools_pkg.put_debug_message` | 482 |
| `dka_tools_pkg.put_log_message` | 491 |
| `fnd_concurrent.wait_for_request` | 505 |
| `dka_tools_pkg.put_outdebug_message` | 513 |
| `dka_tools_pkg.put_log_message` | 517 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 498 |
| when_others | 527 |
| soumission | 428 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SXLAACCPB / DKA | `DKA_SXLAACCPB_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SXLAACCPB.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
