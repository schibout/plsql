# DKA_AUTO_MOUVT_ACTIF_2054AB.sql

Source : [dka/12.0.0/sql/DKA_AUTO_MOUVT_ACTIF_2054AB.sql](../../dka/12.0.0/sql/DKA_AUTO_MOUVT_ACTIF_2054AB.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 884 ; encodage : cp1252 (repli). SHA-256 : `9ff041efce934afaa9c59e0246fa8e106e03dc97f607df892d831c9b7ba1d191`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `positionnement_contexte` | 194 |
| `soumission_traitement` | 268 |
| `verif_period_FA` | 394 |
| `livre_comptable` | 439 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_user` | 206 |
| `fnd_responsibility` | 225 |
| `fnd_concurrent_programs` | 244 |
| `fa_deprn_periods` | 403 |
| `fa_deprn_periods` | 406 |
| `fa_deprn_periods` | 419 |
| `fa_deprn_periods` | 422 |
| `fa_book_controls` | 449 |
| `v$parameter` | 477 |
| `dka_auto_etat` | 508 |
| `HR_OPERATING_UNITs` | 577 |
| `dka_auto_etat` | 853 |
| `DUAL` | 874 |
| `DUAL` | 876 |
| `DUAL` | 883 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 258 |
| `fnd_profile.value` | 260 |
| `fnd_request.submit_request` | 270 |
| `dka_tools_pkg.tab_request_params` | 275 |
| `dka_tools_pkg.tab_request_params` | 276 |
| `dka_tools_pkg.tab_request_params` | 277 |
| `dka_tools_pkg.tab_request_params` | 278 |
| `dka_tools_pkg.tab_request_params` | 279 |
| `dka_tools_pkg.tab_request_params` | 280 |
| `dka_tools_pkg.tab_request_params` | 281 |
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
| `FND_PROFILE.VALUE` | 468 |
| `dka_tools_pkg.get_parameter` | 539 |
| `dka_tools_pkg.get_request_set_params` | 686 |
| `dka_tools_pkg.tab_request_params` | 704 |
| `dka_tools_pkg.tab_request_params` | 708 |
| `dka_tools_pkg.tab_request_params` | 714 |
| `dka_tools_pkg.tab_request_params` | 722 |
| `dka_tools_pkg.tab_request_params` | 723 |
| `dka_tools_pkg.tab_request_params` | 735 |
| `dka_tools_pkg.tab_request_params` | 736 |
| `dka_tools_pkg.tab_request_params` | 746 |
| `dka_tools_pkg.tab_request_params` | 747 |
| `dka_tools_pkg.tab_request_params` | 758 |
| `dka_tools_pkg.tab_request_params` | 759 |
| `dka_tools_pkg.tab_request_params` | 770 |
| `dka_tools_pkg.tab_request_params` | 771 |
| `dka_tools_pkg.tab_request_params` | 772 |
| `dka_tools_pkg.tab_request_params` | 773 |
| `dka_tools_pkg.tab_request_params` | 774 |
| `fnd_concurrent.wait_for_request` | 800 |
| `Fnd_Profile.VALUE` | 858 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

| Élément | Ligne source |
|---|---:|
| `$DKA_TOP/bin/DKA_MOUVT_ACTIF_2054AB_BOR.sh` | 879 |

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 381, 862 |
| when_others | 210, 229, 250, 410, 426, 457, 485, 526, 866 |
| soumission | 270 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AUTO_MOUVT_ACTIF_2054AB / DKA | `DKA_AUTO_MOUVT_ACTIF_2054AB` | dka/12.0.0/admin/import/DKA_AUTO_MOUVT_ACTIF_2054AB.prt:510 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
