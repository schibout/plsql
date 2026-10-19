# DKA_AUTO_GL_DECLAR_TVA.sql

Source : [dka/12.0.0/sql/DKA_AUTO_GL_DECLAR_TVA.sql](../../dka/12.0.0/sql/DKA_AUTO_GL_DECLAR_TVA.sql).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 637 ; encodage : cp1252 (repli). SHA-256 : `ebc7d59dbcfa35fdb21ce3b05410fa07016ab9d22151bcafb74976516d4b3037`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `positionnement_contexte` | 194 |
| `soumission_traitement` | 270 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_flex_value_sets` | 105 |
| `fnd_concurrent_requests` | 131 |
| `fnd_concurrent_requests` | 166 |
| `fnd_user` | 206 |
| `fnd_responsibility` | 225 |
| `fnd_concurrent_programs` | 244 |
| `fnd_concurrent_requests` | 388 |
| `gl_period_statuses` | 504 |
| `gl_period_statuses` | 507 |
| `gl_period_statuses` | 567 |
| `gl_period_statuses` | 570 |
| `all_directories` | 578 |
| `DUAL` | 631 |
| `DUAL` | 636 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_Global.apps_initialize` | 258 |
| `Fnd_Profile.value` | 260 |
| `Fnd_Request.submit_request` | 272 |
| `Dka_Tools_Pkg.tab_request_params` | 278 |
| `Dka_Tools_Pkg.tab_request_params` | 279 |
| `Dka_Tools_Pkg.tab_request_params` | 280 |
| `Dka_Tools_Pkg.tab_request_params` | 281 |
| `Dka_Tools_Pkg.tab_request_params` | 282 |
| `Dka_Tools_Pkg.tab_request_params` | 283 |
| `Dka_Tools_Pkg.tab_request_params` | 284 |
| `Dka_Tools_Pkg.tab_request_params` | 285 |
| `Dka_Tools_Pkg.tab_request_params` | 286 |
| `Dka_Tools_Pkg.tab_request_params` | 287 |
| `Dka_Tools_Pkg.tab_request_params` | 288 |
| `Dka_Tools_Pkg.tab_request_params` | 289 |
| `Dka_Tools_Pkg.tab_request_params` | 290 |
| `Dka_Tools_Pkg.tab_request_params` | 291 |
| `Dka_Tools_Pkg.tab_request_params` | 292 |
| `Dka_Tools_Pkg.tab_request_params` | 293 |
| `Dka_Tools_Pkg.tab_request_params` | 294 |
| `Dka_Tools_Pkg.tab_request_params` | 295 |
| `Dka_Tools_Pkg.tab_request_params` | 296 |
| `Dka_Tools_Pkg.tab_request_params` | 297 |
| `Dka_Tools_Pkg.tab_request_params` | 298 |
| `Dka_Tools_Pkg.tab_request_params` | 299 |
| `Dka_Tools_Pkg.tab_request_params` | 300 |
| `Dka_Tools_Pkg.tab_request_params` | 301 |
| `Dka_Tools_Pkg.tab_request_params` | 302 |
| `Dka_Tools_Pkg.tab_request_params` | 303 |
| `Dka_Tools_Pkg.tab_request_params` | 304 |
| `Dka_Tools_Pkg.tab_request_params` | 305 |
| `Dka_Tools_Pkg.tab_request_params` | 306 |
| `Dka_Tools_Pkg.tab_request_params` | 307 |
| `Dka_Tools_Pkg.tab_request_params` | 308 |
| `Dka_Tools_Pkg.tab_request_params` | 309 |
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
| `Fnd_Profile.VALUE` | 398 |
| `Dka_Tools_Pkg.get_parameter` | 406 |
| `Dka_Tools_Pkg.get_request_set_params` | 479 |
| `Dka_Tools_Pkg.tab_request_params` | 497 |
| `Dka_Tools_Pkg.tab_request_params` | 498 |
| `Dka_Tools_Pkg.tab_request_params` | 503 |
| `Dka_Tools_Pkg.tab_request_params` | 521 |
| `Dka_Tools_Pkg.tab_request_params` | 522 |
| `Dka_Tools_Pkg.tab_request_params` | 527 |
| `Fnd_Concurrent.wait_for_request` | 544 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 381, 391 |
| when_others | 210, 229, 250, 581, 622 |
| soumission | 272 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AUTO_GL_DECLAR_TVA / DKA | `DKA_AUTO_GL_DECLAR_TVA` | dka/12.0.0/admin/import/DKA_AUTO_GL_DECLAR_TVA.prt:404 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
