# DKA_AUTO_AMOR_FISC.sql

Source : [dka/12.0.0/sql/DKA_AUTO_AMOR_FISC.sql](../../dka/12.0.0/sql/DKA_AUTO_AMOR_FISC.sql).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 899 ; encodage : cp1252 (repli). SHA-256 : `8f1f37ffbbb48e3e04b59b16203b654caf4c9d6c0fa217eea5055c8d3ec9fc80`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `positionnement_contexte` | 190 |
| `soumission_traitement` | 265 |
| `verif_period_FA` | 391 |
| `livre_comptable` | 436 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_user` | 202 |
| `fnd_responsibility` | 221 |
| `fnd_concurrent_programs` | 240 |
| `fa_deprn_periods` | 400 |
| `fa_deprn_periods` | 403 |
| `fa_deprn_periods` | 416 |
| `fa_deprn_periods` | 419 |
| `fa_book_controls` | 446 |
| `v$parameter` | 477 |
| `dka_auto_etat` | 508 |
| `HR_OPERATING_UNITs` | 579 |
| `dka_auto_etat` | 867 |
| `DUAL` | 889 |
| `DUAL` | 891 |
| `DUAL` | 898 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_Global.apps_initialize` | 254 |
| `Fnd_Profile.value` | 256 |
| `Fnd_Request.submit_request` | 267 |
| `Dka_Tools_Pkg.tab_request_params` | 272 |
| `Dka_Tools_Pkg.tab_request_params` | 273 |
| `Dka_Tools_Pkg.tab_request_params` | 274 |
| `Dka_Tools_Pkg.tab_request_params` | 275 |
| `Dka_Tools_Pkg.tab_request_params` | 276 |
| `Dka_Tools_Pkg.tab_request_params` | 277 |
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
| `Fnd_Profile.VALUE` | 468 |
| `Dka_Tools_Pkg.get_parameter` | 539 |
| `Dka_Tools_Pkg.get_request_set_params` | 698 |
| `Dka_Tools_Pkg.tab_request_params` | 716 |
| `Dka_Tools_Pkg.tab_request_params` | 736 |
| `Dka_Tools_Pkg.tab_request_params` | 737 |
| `Dka_Tools_Pkg.tab_request_params` | 749 |
| `Dka_Tools_Pkg.tab_request_params` | 750 |
| `Dka_Tools_Pkg.tab_request_params` | 760 |
| `Dka_Tools_Pkg.tab_request_params` | 761 |
| `Dka_Tools_Pkg.tab_request_params` | 772 |
| `Dka_Tools_Pkg.tab_request_params` | 773 |
| `Dka_Tools_Pkg.tab_request_params` | 784 |
| `Dka_Tools_Pkg.tab_request_params` | 785 |
| `Dka_Tools_Pkg.tab_request_params` | 786 |
| `Dka_Tools_Pkg.tab_request_params` | 787 |
| `Fnd_Concurrent.wait_for_request` | 813 |
| `Fnd_Profile.VALUE` | 872 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

| Élément | Ligne source |
|---|---:|
| `$DKA_TOP/bin/DKA_AMOR_FISC_BOR.sh` | 894 |

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 378, 876 |
| when_others | 206, 225, 246, 407, 423, 457, 485, 526, 880 |
| soumission | 267 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AUTO_AMOR_FISC / DKA | `DKA_AUTO_AMOR_FISC` | dka/12.0.0/admin/import/DKA_AUTO_AMOR_FISC.prt:444 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
