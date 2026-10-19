# DKA_AUTO_AR_JUST_TVA_ENC.sql

Source : [dka/12.0.0/sql/DKA_AUTO_AR_JUST_TVA_ENC.sql](../../dka/12.0.0/sql/DKA_AUTO_AR_JUST_TVA_ENC.sql).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 653 ; encodage : cp1252 (repli). SHA-256 : `e53d8b19cb5f913dbb05e6573e306cf7d4b000c980ac882fbb82b8d55ba1b182`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `positionnement_contexte` | 205 |
| `soumission_traitement` | 301 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_flex_value_sets` | 117 |
| `fnd_concurrent_requests` | 142 |
| `fnd_concurrent_requests` | 178 |
| `fnd_user` | 217 |
| `fnd_responsibility` | 236 |
| `fnd_concurrent_programs` | 255 |
| `fnd_concurrent_requests` | 420 |
| `gl_periods` | 537 |
| `gl_period_statuses` | 540 |
| `gl_ledgers` | 542 |
| `all_directories` | 613 |
| `DUAL` | 647 |
| `DUAL` | 652 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.INITIALIZE` | 271 |
| `Fnd_Request.submit_request` | 304 |
| `Dka_Tools_Pkg.tab_request_params` | 310 |
| `Dka_Tools_Pkg.tab_request_params` | 311 |
| `Dka_Tools_Pkg.tab_request_params` | 312 |
| `Dka_Tools_Pkg.tab_request_params` | 313 |
| `Dka_Tools_Pkg.tab_request_params` | 314 |
| `Dka_Tools_Pkg.tab_request_params` | 315 |
| `Dka_Tools_Pkg.tab_request_params` | 316 |
| `Dka_Tools_Pkg.tab_request_params` | 317 |
| `Dka_Tools_Pkg.tab_request_params` | 318 |
| `Dka_Tools_Pkg.tab_request_params` | 319 |
| `Dka_Tools_Pkg.tab_request_params` | 320 |
| `Dka_Tools_Pkg.tab_request_params` | 321 |
| `Dka_Tools_Pkg.tab_request_params` | 322 |
| `Dka_Tools_Pkg.tab_request_params` | 323 |
| `Dka_Tools_Pkg.tab_request_params` | 324 |
| `Dka_Tools_Pkg.tab_request_params` | 325 |
| `Dka_Tools_Pkg.tab_request_params` | 326 |
| `Dka_Tools_Pkg.tab_request_params` | 327 |
| `Dka_Tools_Pkg.tab_request_params` | 328 |
| `Dka_Tools_Pkg.tab_request_params` | 329 |
| `Dka_Tools_Pkg.tab_request_params` | 330 |
| `Dka_Tools_Pkg.tab_request_params` | 331 |
| `Dka_Tools_Pkg.tab_request_params` | 332 |
| `Dka_Tools_Pkg.tab_request_params` | 333 |
| `Dka_Tools_Pkg.tab_request_params` | 334 |
| `Dka_Tools_Pkg.tab_request_params` | 335 |
| `Dka_Tools_Pkg.tab_request_params` | 336 |
| `Dka_Tools_Pkg.tab_request_params` | 337 |
| `Dka_Tools_Pkg.tab_request_params` | 338 |
| `Dka_Tools_Pkg.tab_request_params` | 339 |
| `Dka_Tools_Pkg.tab_request_params` | 340 |
| `Dka_Tools_Pkg.tab_request_params` | 341 |
| `Dka_Tools_Pkg.tab_request_params` | 342 |
| `Dka_Tools_Pkg.tab_request_params` | 343 |
| `Dka_Tools_Pkg.tab_request_params` | 344 |
| `Dka_Tools_Pkg.tab_request_params` | 345 |
| `Dka_Tools_Pkg.tab_request_params` | 346 |
| `Dka_Tools_Pkg.tab_request_params` | 347 |
| `Dka_Tools_Pkg.tab_request_params` | 348 |
| `Dka_Tools_Pkg.tab_request_params` | 349 |
| `Dka_Tools_Pkg.tab_request_params` | 350 |
| `Dka_Tools_Pkg.tab_request_params` | 351 |
| `Dka_Tools_Pkg.tab_request_params` | 352 |
| `Dka_Tools_Pkg.tab_request_params` | 353 |
| `Dka_Tools_Pkg.tab_request_params` | 354 |
| `Dka_Tools_Pkg.tab_request_params` | 355 |
| `Dka_Tools_Pkg.tab_request_params` | 356 |
| `Dka_Tools_Pkg.tab_request_params` | 357 |
| `Dka_Tools_Pkg.tab_request_params` | 358 |
| `Dka_Tools_Pkg.tab_request_params` | 359 |
| `Dka_Tools_Pkg.tab_request_params` | 360 |
| `Dka_Tools_Pkg.tab_request_params` | 361 |
| `Dka_Tools_Pkg.tab_request_params` | 362 |
| `Dka_Tools_Pkg.tab_request_params` | 363 |
| `Dka_Tools_Pkg.tab_request_params` | 364 |
| `Dka_Tools_Pkg.tab_request_params` | 365 |
| `Dka_Tools_Pkg.tab_request_params` | 366 |
| `Dka_Tools_Pkg.tab_request_params` | 367 |
| `Dka_Tools_Pkg.tab_request_params` | 368 |
| `Dka_Tools_Pkg.tab_request_params` | 369 |
| `Dka_Tools_Pkg.tab_request_params` | 370 |
| `Dka_Tools_Pkg.tab_request_params` | 371 |
| `Dka_Tools_Pkg.tab_request_params` | 372 |
| `Dka_Tools_Pkg.tab_request_params` | 373 |
| `Dka_Tools_Pkg.tab_request_params` | 374 |
| `Dka_Tools_Pkg.tab_request_params` | 375 |
| `Dka_Tools_Pkg.tab_request_params` | 376 |
| `Dka_Tools_Pkg.tab_request_params` | 377 |
| `Dka_Tools_Pkg.tab_request_params` | 378 |
| `Dka_Tools_Pkg.tab_request_params` | 379 |
| `Dka_Tools_Pkg.tab_request_params` | 380 |
| `Dka_Tools_Pkg.tab_request_params` | 381 |
| `Dka_Tools_Pkg.tab_request_params` | 382 |
| `Dka_Tools_Pkg.tab_request_params` | 383 |
| `Dka_Tools_Pkg.tab_request_params` | 384 |
| `Dka_Tools_Pkg.tab_request_params` | 385 |
| `Dka_Tools_Pkg.tab_request_params` | 386 |
| `Dka_Tools_Pkg.tab_request_params` | 387 |
| `Dka_Tools_Pkg.tab_request_params` | 388 |
| `Dka_Tools_Pkg.tab_request_params` | 389 |
| `Dka_Tools_Pkg.tab_request_params` | 390 |
| `Dka_Tools_Pkg.tab_request_params` | 391 |
| `Dka_Tools_Pkg.tab_request_params` | 392 |
| `Dka_Tools_Pkg.tab_request_params` | 393 |
| `Dka_Tools_Pkg.tab_request_params` | 394 |
| `Dka_Tools_Pkg.tab_request_params` | 395 |
| `Dka_Tools_Pkg.tab_request_params` | 396 |
| `Dka_Tools_Pkg.tab_request_params` | 397 |
| `Dka_Tools_Pkg.tab_request_params` | 398 |
| `Dka_Tools_Pkg.tab_request_params` | 399 |
| `Dka_Tools_Pkg.tab_request_params` | 400 |
| `Dka_Tools_Pkg.tab_request_params` | 401 |
| `Dka_Tools_Pkg.tab_request_params` | 402 |
| `Dka_Tools_Pkg.tab_request_params` | 403 |
| `Dka_Tools_Pkg.tab_request_params` | 404 |
| `Dka_Tools_Pkg.tab_request_params` | 405 |
| `Dka_Tools_Pkg.tab_request_params` | 406 |
| `Dka_Tools_Pkg.tab_request_params` | 407 |
| `Dka_Tools_Pkg.tab_request_params` | 408 |
| `Dka_Tools_Pkg.tab_request_params` | 409 |
| `Fnd_Profile.VALUE` | 433 |
| `Dka_Tools_Pkg.get_parameter` | 440 |
| `Dka_Tools_Pkg.get_request_set_params` | 513 |
| `Dka_Tools_Pkg.tab_request_params` | 531 |
| `Dka_Tools_Pkg.tab_request_params` | 536 |
| `Dka_Tools_Pkg.tab_request_params` | 554 |
| `Dka_Tools_Pkg.tab_request_params` | 555 |
| `Fnd_Concurrent.wait_for_request` | 570 |
| `Fnd_File.put_line` | 603 |
| `Fnd_File.put_line` | 604 |
| `Fnd_File.put_line` | 605 |
| `Fnd_File.put_line` | 606 |
| `Fnd_File.put_line` | 607 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 413, 423 |
| when_others | 221, 240, 261, 616, 638 |
| soumission | 304 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AUTO_AR_JUST_TVA_ENC / DKA | `DKA_AUTO_AR_JUST_TVA_ENC` | dka/12.0.0/admin/import/DKA_AUTO_AR_JUST_TVA_ENC.prt:421 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
