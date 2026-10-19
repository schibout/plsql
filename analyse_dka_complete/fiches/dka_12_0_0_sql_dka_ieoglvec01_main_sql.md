# DKA_IEOGLVEC01_MAIN.sql

Source : [dka/12.0.0/sql/DKA_IEOGLVEC01_MAIN.sql](../../dka/12.0.0/sql/DKA_IEOGLVEC01_MAIN.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 524 ; encodage : cp1252 (repli). SHA-256 : `31b9d2b0839273da1e4abb90e9963543e9eb4948716f537709434d7f20b84fbf`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_ieoglvec01_conso_code_v` | 81 |
| `GL_LEDGERS` | 84 |
| `gl_period_statuses` | 96 |
| `GL_access_set_assignments` | 98 |
| `gl_period_statuses` | 101 |
| `fnd_concurrent_programs` | 168 |
| `fnd_user` | 176 |
| `fnd_responsibility` | 184 |
| `dka_ieoglvec01_conso_code_v` | 223 |
| `fnd_flex_value_sets` | 244 |
| `fnd_user` | 276 |
| `fnd_responsibility` | 284 |
| `DUAL` | 523 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_PROFILE.value` | 87 |
| `fnd_profile.value` | 98 |
| `fnd_global.apps_initialize` | 189 |
| `dka_tools_pkg.get_request_set_params` | 192 |
| `dka_tools_pkg.tab_request_params` | 211 |
| `fnd_global.apps_initialize` | 288 |
| `fnd_profile.value` | 290 |
| `dka_tools_pkg.tab_request_params` | 311 |
| `fnd_request.submit_request` | 319 |
| `dka_tools_pkg.tab_request_params` | 325 |
| `dka_tools_pkg.tab_request_params` | 326 |
| `dka_tools_pkg.tab_request_params` | 327 |
| `dka_tools_pkg.tab_request_params` | 328 |
| `dka_tools_pkg.tab_request_params` | 329 |
| `dka_tools_pkg.tab_request_params` | 330 |
| `dka_tools_pkg.tab_request_params` | 331 |
| `dka_tools_pkg.tab_request_params` | 332 |
| `dka_tools_pkg.tab_request_params` | 333 |
| `dka_tools_pkg.tab_request_params` | 334 |
| `dka_tools_pkg.tab_request_params` | 335 |
| `dka_tools_pkg.tab_request_params` | 336 |
| `dka_tools_pkg.tab_request_params` | 337 |
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
| `fnd_concurrent.wait_for_request` | 454 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 431 |
| when_others | 123, 154, 227, 258, 491, 515 |
| soumission | 319 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
