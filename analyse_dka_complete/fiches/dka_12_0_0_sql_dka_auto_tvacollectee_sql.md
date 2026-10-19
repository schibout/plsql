# DKA_AUTO_TVACOLLECTEE.sql

Source : [dka/12.0.0/sql/DKA_AUTO_TVACOLLECTEE.sql](../../dka/12.0.0/sql/DKA_AUTO_TVACOLLECTEE.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 629 ; encodage : cp1252 (repli). SHA-256 : `f300841f94fba12190f7cc35b13438f366dd7723c9a3cdfb1f1dfb5cfe099d3e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `positionnement_contexte` | 199 |
| `soumission_traitement` | 274 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_flex_value_sets` | 114 |
| `fnd_concurrent_requests` | 138 |
| `fnd_concurrent_requests` | 172 |
| `fnd_user` | 211 |
| `fnd_responsibility` | 230 |
| `fnd_concurrent_programs` | 249 |
| `fnd_concurrent_requests` | 392 |
| `gl_periods` | 512 |
| `gl_period_statuses` | 515 |
| `gl_ledgers` | 517 |
| `all_directories` | 589 |
| `DUAL` | 623 |
| `DUAL` | 628 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 263 |
| `fnd_profile.value` | 265 |
| `fnd_request.submit_request` | 276 |
| `dka_tools_pkg.tab_request_params` | 282 |
| `dka_tools_pkg.tab_request_params` | 283 |
| `dka_tools_pkg.tab_request_params` | 284 |
| `dka_tools_pkg.tab_request_params` | 285 |
| `dka_tools_pkg.tab_request_params` | 286 |
| `dka_tools_pkg.tab_request_params` | 287 |
| `dka_tools_pkg.tab_request_params` | 288 |
| `dka_tools_pkg.tab_request_params` | 289 |
| `dka_tools_pkg.tab_request_params` | 290 |
| `dka_tools_pkg.tab_request_params` | 291 |
| `dka_tools_pkg.tab_request_params` | 292 |
| `dka_tools_pkg.tab_request_params` | 293 |
| `dka_tools_pkg.tab_request_params` | 294 |
| `dka_tools_pkg.tab_request_params` | 295 |
| `dka_tools_pkg.tab_request_params` | 296 |
| `dka_tools_pkg.tab_request_params` | 297 |
| `dka_tools_pkg.tab_request_params` | 298 |
| `dka_tools_pkg.tab_request_params` | 299 |
| `dka_tools_pkg.tab_request_params` | 300 |
| `dka_tools_pkg.tab_request_params` | 301 |
| `dka_tools_pkg.tab_request_params` | 302 |
| `dka_tools_pkg.tab_request_params` | 303 |
| `dka_tools_pkg.tab_request_params` | 304 |
| `dka_tools_pkg.tab_request_params` | 305 |
| `dka_tools_pkg.tab_request_params` | 306 |
| `dka_tools_pkg.tab_request_params` | 307 |
| `dka_tools_pkg.tab_request_params` | 308 |
| `dka_tools_pkg.tab_request_params` | 309 |
| `dka_tools_pkg.tab_request_params` | 310 |
| `dka_tools_pkg.tab_request_params` | 311 |
| `dka_tools_pkg.tab_request_params` | 312 |
| `dka_tools_pkg.tab_request_params` | 313 |
| `dka_tools_pkg.tab_request_params` | 314 |
| `dka_tools_pkg.tab_request_params` | 315 |
| `dka_tools_pkg.tab_request_params` | 316 |
| `dka_tools_pkg.tab_request_params` | 317 |
| `dka_tools_pkg.tab_request_params` | 318 |
| `dka_tools_pkg.tab_request_params` | 319 |
| `dka_tools_pkg.tab_request_params` | 320 |
| `dka_tools_pkg.tab_request_params` | 321 |
| `dka_tools_pkg.tab_request_params` | 322 |
| `dka_tools_pkg.tab_request_params` | 323 |
| `dka_tools_pkg.tab_request_params` | 324 |
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
| `FND_PROFILE.VALUE` | 402 |
| `dka_tools_pkg.get_parameter` | 409 |
| `dka_tools_pkg.get_request_set_params` | 484 |
| `dka_tools_pkg.tab_request_params` | 504 |
| `dka_tools_pkg.tab_request_params` | 524 |
| `dka_tools_pkg.tab_request_params` | 529 |
| `dka_tools_pkg.tab_request_params` | 535 |
| `dka_tools_pkg.tab_request_params` | 536 |
| `fnd_concurrent.wait_for_request` | 551 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 385, 395 |
| when_others | 215, 234, 255, 592, 614 |
| soumission | 276 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AUTO_TVACOLLECTEE / DKA | `DKA_AUTO_TVACOLLECTEE` | dka/12.0.0/admin/import/DKA_AUTO_TVACOLLECTEE.prt:404 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
