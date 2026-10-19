# DKA_AUTO_JEFRTXDC.sql

Source : [dka/12.0.0/sql/DKA_AUTO_JEFRTXDC.sql](../../dka/12.0.0/sql/DKA_AUTO_JEFRTXDC.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 706 ; encodage : cp1252 (repli). SHA-256 : `b2620ec2292ee261e792081cf17e0baa3ac7d651b9e26c8ac5d639f1c682049e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `positionnement_contexte` | 250 |
| `soumission_traitement` | 330 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_ledgers` | 161 |
| `fnd_concurrent_requests` | 187 |
| `fnd_concurrent_requests` | 222 |
| `fnd_user` | 265 |
| `fnd_responsibility` | 284 |
| `fnd_concurrent_programs` | 304 |
| `fnd_concurrent_requests` | 448 |
| `gl_periods` | 589 |
| `gl_period_statuses` | 592 |
| `gl_ledgers` | 594 |
| `all_directories` | 667 |
| `DUAL` | 700 |
| `DUAL` | 705 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 320 |
| `fnd_request.submit_request` | 332 |
| `dka_tools_pkg.tab_request_params` | 338 |
| `dka_tools_pkg.tab_request_params` | 339 |
| `dka_tools_pkg.tab_request_params` | 340 |
| `dka_tools_pkg.tab_request_params` | 341 |
| `dka_tools_pkg.tab_request_params` | 342 |
| `dka_tools_pkg.tab_request_params` | 343 |
| `dka_tools_pkg.tab_request_params` | 344 |
| `dka_tools_pkg.tab_request_params` | 345 |
| `dka_tools_pkg.tab_request_params` | 346 |
| `dka_tools_pkg.tab_request_params` | 347 |
| `dka_tools_pkg.tab_request_params` | 348 |
| `dka_tools_pkg.tab_request_params` | 349 |
| `dka_tools_pkg.tab_request_params` | 350 |
| `dka_tools_pkg.tab_request_params` | 351 |
| `dka_tools_pkg.tab_request_params` | 352 |
| `dka_tools_pkg.tab_request_params` | 353 |
| `dka_tools_pkg.tab_request_params` | 354 |
| `dka_tools_pkg.tab_request_params` | 355 |
| `dka_tools_pkg.tab_request_params` | 356 |
| `dka_tools_pkg.tab_request_params` | 357 |
| `dka_tools_pkg.tab_request_params` | 358 |
| `dka_tools_pkg.tab_request_params` | 359 |
| `dka_tools_pkg.tab_request_params` | 360 |
| `dka_tools_pkg.tab_request_params` | 361 |
| `dka_tools_pkg.tab_request_params` | 362 |
| `dka_tools_pkg.tab_request_params` | 363 |
| `dka_tools_pkg.tab_request_params` | 364 |
| `dka_tools_pkg.tab_request_params` | 365 |
| `dka_tools_pkg.tab_request_params` | 366 |
| `dka_tools_pkg.tab_request_params` | 367 |
| `dka_tools_pkg.tab_request_params` | 368 |
| `dka_tools_pkg.tab_request_params` | 369 |
| `dka_tools_pkg.tab_request_params` | 370 |
| `dka_tools_pkg.tab_request_params` | 371 |
| `dka_tools_pkg.tab_request_params` | 372 |
| `dka_tools_pkg.tab_request_params` | 373 |
| `dka_tools_pkg.tab_request_params` | 374 |
| `dka_tools_pkg.tab_request_params` | 375 |
| `dka_tools_pkg.tab_request_params` | 376 |
| `dka_tools_pkg.tab_request_params` | 377 |
| `dka_tools_pkg.tab_request_params` | 378 |
| `dka_tools_pkg.tab_request_params` | 379 |
| `dka_tools_pkg.tab_request_params` | 380 |
| `dka_tools_pkg.tab_request_params` | 381 |
| `dka_tools_pkg.tab_request_params` | 382 |
| `dka_tools_pkg.tab_request_params` | 383 |
| `dka_tools_pkg.tab_request_params` | 384 |
| `dka_tools_pkg.tab_request_params` | 385 |
| `dka_tools_pkg.tab_request_params` | 386 |
| `dka_tools_pkg.tab_request_params` | 387 |
| `dka_tools_pkg.tab_request_params` | 388 |
| `dka_tools_pkg.tab_request_params` | 389 |
| `dka_tools_pkg.tab_request_params` | 390 |
| `dka_tools_pkg.tab_request_params` | 391 |
| `dka_tools_pkg.tab_request_params` | 392 |
| `dka_tools_pkg.tab_request_params` | 393 |
| `dka_tools_pkg.tab_request_params` | 394 |
| `dka_tools_pkg.tab_request_params` | 395 |
| `dka_tools_pkg.tab_request_params` | 396 |
| `dka_tools_pkg.tab_request_params` | 397 |
| `dka_tools_pkg.tab_request_params` | 398 |
| `dka_tools_pkg.tab_request_params` | 399 |
| `dka_tools_pkg.tab_request_params` | 400 |
| `dka_tools_pkg.tab_request_params` | 401 |
| `dka_tools_pkg.tab_request_params` | 402 |
| `dka_tools_pkg.tab_request_params` | 403 |
| `dka_tools_pkg.tab_request_params` | 404 |
| `dka_tools_pkg.tab_request_params` | 405 |
| `dka_tools_pkg.tab_request_params` | 406 |
| `dka_tools_pkg.tab_request_params` | 407 |
| `dka_tools_pkg.tab_request_params` | 408 |
| `dka_tools_pkg.tab_request_params` | 409 |
| `dka_tools_pkg.tab_request_params` | 410 |
| `dka_tools_pkg.tab_request_params` | 411 |
| `dka_tools_pkg.tab_request_params` | 412 |
| `dka_tools_pkg.tab_request_params` | 413 |
| `dka_tools_pkg.tab_request_params` | 414 |
| `dka_tools_pkg.tab_request_params` | 415 |
| `dka_tools_pkg.tab_request_params` | 416 |
| `dka_tools_pkg.tab_request_params` | 417 |
| `dka_tools_pkg.tab_request_params` | 418 |
| `dka_tools_pkg.tab_request_params` | 419 |
| `dka_tools_pkg.tab_request_params` | 420 |
| `dka_tools_pkg.tab_request_params` | 421 |
| `dka_tools_pkg.tab_request_params` | 422 |
| `dka_tools_pkg.tab_request_params` | 423 |
| `dka_tools_pkg.tab_request_params` | 424 |
| `dka_tools_pkg.tab_request_params` | 425 |
| `dka_tools_pkg.tab_request_params` | 426 |
| `dka_tools_pkg.tab_request_params` | 427 |
| `dka_tools_pkg.tab_request_params` | 428 |
| `dka_tools_pkg.tab_request_params` | 429 |
| `dka_tools_pkg.tab_request_params` | 430 |
| `dka_tools_pkg.tab_request_params` | 431 |
| `dka_tools_pkg.tab_request_params` | 432 |
| `dka_tools_pkg.tab_request_params` | 433 |
| `dka_tools_pkg.tab_request_params` | 434 |
| `dka_tools_pkg.tab_request_params` | 435 |
| `dka_tools_pkg.tab_request_params` | 436 |
| `dka_tools_pkg.tab_request_params` | 437 |
| `dka_tools_pkg.get_request_set_params` | 563 |
| `Dka_Tools_Pkg.tab_request_params` | 588 |
| `dka_tools_pkg.tab_request_params` | 600 |
| `dka_tools_pkg.tab_request_params` | 601 |
| `dka_tools_pkg.tab_request_params` | 618 |
| `dka_tools_pkg.tab_request_params` | 621 |
| `dka_tools_pkg.tab_request_params` | 622 |
| `fnd_concurrent.wait_for_request` | 638 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 441, 451 |
| when_others | 269, 289, 310, 670, 692 |
| soumission | 332 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AUTO_JEFRTXDC / DKA | `DKA_AUTO_JEFRTXDC` | dka/12.0.0/admin/import/DKA_AUTO_JEFRTXDC.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
