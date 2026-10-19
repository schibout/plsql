# DKA_SPOCLOSCOM_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOCLOSCOM_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOCLOSCOM_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1295 ; encodage : cp1252 (repli). SHA-256 : `097ef43f00188f6572bc6be4e6efd80ffa9cff7a1b9e3bbdc2c88b6b0b6ca4fa`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 40 |
| `Cloture_ligne_livraison` | 120 |
| `Cloture_ligne_commande` | 169 |
| `Cloture_entete_commande` | 237 |
| `lancement_par_region` | 284 |
| `Select_ligne_cde_proj_ferme` | 633 |
| `Select_ligne_cde_ancienne` | 949 |
| `main` | 1251 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dual` | 78 |
| `po_line_locations` | 133 |
| `gl_code_combinations` | 146 |
| `po_line_locations` | 183 |
| `po_lines` | 204 |
| `po_headers` | 249 |
| `fnd_flex_value_sets` | 323 |
| `fnd_responsibility` | 345 |
| `fnd_user` | 356 |
| `fnd_concurrent_programs` | 369 |
| `po_headers` | 654 |
| `po_distributions` | 680 |
| `po_distributions` | 692 |
| `po_distributions` | 702 |
| `po_headers_all` | 714 |
| `po_lines_all` | 718 |
| `po_lines_all` | 724 |
| `po_lines_all` | 732 |
| `po_line_locations_all` | 735 |
| `po_line_locations_all` | 741 |
| `po_headers` | 972 |
| `po_line_locations` | 997 |
| `po_distributions` | 1002 |
| `po_headers_all` | 1014 |
| `po_lines_all` | 1019 |
| `po_lines_all` | 1025 |
| `po_lines_all` | 1035 |
| `po_line_locations_all` | 1038 |
| `po_line_locations_all` | 1044 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 44 |
| `Dka_Tools_Pkg.get_parameter` | 61 |
| `Dka_Tools_Pkg.put_debug_message` | 70 |
| `Dka_Tools_Pkg.put_debug_message` | 74 |
| `Dka_Tools_Pkg.get_parameter` | 81 |
| `Dka_Tools_Pkg.put_debug_message` | 90 |
| `Dka_Tools_Pkg.put_debug_message` | 94 |
| `dka_tools_pkg.put_debug_message` | 101 |
| `dka_tools_pkg.put_debug_message` | 127 |
| `dka_tools_pkg.put_debug_message` | 150 |
| `dka_tools_pkg.put_debug_message` | 175 |
| `Dka_Tools_Pkg.put_debug_message` | 181 |
| `Dka_Tools_Pkg.put_debug_message` | 202 |
| `dka_tools_pkg.put_debug_message` | 214 |
| `dka_tools_pkg.put_debug_message` | 217 |
| `dka_tools_pkg.put_debug_message` | 242 |
| `Dka_Tools_Pkg.put_debug_message` | 247 |
| `dka_tools_pkg.put_debug_message` | 258 |
| `dka_tools_pkg.put_debug_message` | 261 |
| `Dka_Tools_Pkg.put_outdebug_message` | 341 |
| `Dka_Tools_Pkg.put_outdebug_message` | 362 |
| `Dka_Tools_Pkg.put_outdebug_message` | 376 |
| `fnd_global.apps_initialize` | 378 |
| `fnd_profile.value` | 387 |
| `Dka_Tools_Pkg.put_outdebug_message` | 392 |
| `dka_tools_pkg.get_request_set_params` | 393 |
| `Dka_Tools_Pkg.put_outdebug_message` | 402 |
| `Dka_Tools_Pkg.put_outdebug_message` | 403 |
| `Dka_Tools_Pkg.put_outdebug_message` | 411 |
| `fnd_request.submit_request` | 412 |
| `dka_tools_pkg.tab_request_params` | 417 |
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
| `dka_tools_pkg.tab_request_params` | 438 |
| `dka_tools_pkg.tab_request_params` | 439 |
| `dka_tools_pkg.tab_request_params` | 440 |
| `dka_tools_pkg.tab_request_params` | 441 |
| `dka_tools_pkg.tab_request_params` | 442 |
| `dka_tools_pkg.tab_request_params` | 443 |
| `dka_tools_pkg.tab_request_params` | 444 |
| `dka_tools_pkg.tab_request_params` | 445 |
| `dka_tools_pkg.tab_request_params` | 446 |
| `dka_tools_pkg.tab_request_params` | 447 |
| `dka_tools_pkg.tab_request_params` | 448 |
| `dka_tools_pkg.tab_request_params` | 449 |
| `dka_tools_pkg.tab_request_params` | 450 |
| `dka_tools_pkg.tab_request_params` | 451 |
| `dka_tools_pkg.tab_request_params` | 452 |
| `dka_tools_pkg.tab_request_params` | 453 |
| `dka_tools_pkg.tab_request_params` | 454 |
| `dka_tools_pkg.tab_request_params` | 455 |
| `dka_tools_pkg.tab_request_params` | 456 |
| `dka_tools_pkg.tab_request_params` | 457 |
| `dka_tools_pkg.tab_request_params` | 458 |
| `dka_tools_pkg.tab_request_params` | 459 |
| `dka_tools_pkg.tab_request_params` | 460 |
| `dka_tools_pkg.tab_request_params` | 461 |
| `dka_tools_pkg.tab_request_params` | 462 |
| `dka_tools_pkg.tab_request_params` | 463 |
| `dka_tools_pkg.tab_request_params` | 464 |
| `dka_tools_pkg.tab_request_params` | 465 |
| `dka_tools_pkg.tab_request_params` | 466 |
| `dka_tools_pkg.tab_request_params` | 467 |
| `dka_tools_pkg.tab_request_params` | 468 |
| `dka_tools_pkg.tab_request_params` | 469 |
| `dka_tools_pkg.tab_request_params` | 470 |
| `dka_tools_pkg.tab_request_params` | 471 |
| `dka_tools_pkg.tab_request_params` | 472 |
| `dka_tools_pkg.tab_request_params` | 473 |
| `dka_tools_pkg.tab_request_params` | 474 |
| `dka_tools_pkg.tab_request_params` | 475 |
| `dka_tools_pkg.tab_request_params` | 476 |
| `dka_tools_pkg.tab_request_params` | 477 |
| `dka_tools_pkg.tab_request_params` | 478 |
| `dka_tools_pkg.tab_request_params` | 479 |
| `dka_tools_pkg.tab_request_params` | 480 |
| `dka_tools_pkg.tab_request_params` | 481 |
| `dka_tools_pkg.tab_request_params` | 482 |
| `dka_tools_pkg.tab_request_params` | 483 |
| `dka_tools_pkg.tab_request_params` | 484 |
| `dka_tools_pkg.tab_request_params` | 485 |
| `dka_tools_pkg.tab_request_params` | 486 |
| `dka_tools_pkg.tab_request_params` | 487 |
| `dka_tools_pkg.tab_request_params` | 488 |
| `dka_tools_pkg.tab_request_params` | 489 |
| `dka_tools_pkg.tab_request_params` | 490 |
| `dka_tools_pkg.tab_request_params` | 491 |
| `dka_tools_pkg.tab_request_params` | 492 |
| `dka_tools_pkg.tab_request_params` | 493 |
| `dka_tools_pkg.tab_request_params` | 494 |
| `dka_tools_pkg.tab_request_params` | 495 |
| `dka_tools_pkg.tab_request_params` | 496 |
| `dka_tools_pkg.tab_request_params` | 497 |
| `dka_tools_pkg.tab_request_params` | 498 |
| `dka_tools_pkg.tab_request_params` | 499 |
| `dka_tools_pkg.tab_request_params` | 500 |
| `dka_tools_pkg.tab_request_params` | 501 |
| `dka_tools_pkg.tab_request_params` | 502 |
| `dka_tools_pkg.tab_request_params` | 503 |
| `dka_tools_pkg.tab_request_params` | 504 |
| `dka_tools_pkg.tab_request_params` | 505 |
| `dka_tools_pkg.tab_request_params` | 506 |
| `dka_tools_pkg.tab_request_params` | 507 |
| `dka_tools_pkg.tab_request_params` | 508 |
| `dka_tools_pkg.tab_request_params` | 509 |
| `dka_tools_pkg.tab_request_params` | 510 |
| `dka_tools_pkg.tab_request_params` | 511 |
| `dka_tools_pkg.tab_request_params` | 512 |
| `dka_tools_pkg.tab_request_params` | 513 |
| `dka_tools_pkg.tab_request_params` | 514 |
| `dka_tools_pkg.tab_request_params` | 515 |
| `dka_tools_pkg.tab_request_params` | 516 |
| `Dka_Tools_Pkg.put_outdebug_message` | 518 |
| `Dka_Tools_Pkg.put_outdebug_message` | 524 |
| `Dka_Tools_Pkg.put_outdebug_message` | 529 |
| `fnd_concurrent.wait_for_request` | 533 |
| `Dka_Tools_Pkg.put_outdebug_message` | 542 |
| `Dka_Tools_Pkg.put_outdebug_message` | 544 |
| `fnd_concurrent.wait_for_request` | 554 |
| `Dka_Tools_Pkg.put_outdebug_message` | 564 |
| `Dka_Tools_Pkg.put_outdebug_message` | 571 |
| `Dka_Tools_Pkg.put_outdebug_message` | 577 |
| `Dka_Tools_Pkg.put_outdebug_message` | 583 |
| `Dka_Tools_Pkg.put_outdebug_message` | 596 |
| `Dka_Tools_Pkg.put_outdebug_message` | 599 |
| `Dka_Tools_Pkg.put_outdebug_message` | 601 |
| `Dka_Tools_Pkg.put_outdebug_message` | 603 |
| `Dka_Tools_Pkg.put_outdebug_message` | 605 |
| `Fnd_Date.canonical_to_date` | 687 |
| `Fnd_Date.canonical_to_date` | 698 |
| `dka_tools_pkg.put_debug_message` | 754 |
| `Dka_Tools_Pkg.put_debug_message` | 762 |
| `Dka_Tools_Pkg.put_outdebug_message` | 764 |
| `Dka_Tools_Pkg.put_outdebug_message` | 773 |
| `Dka_Tools_Pkg.put_outdebug_message` | 789 |
| `Dka_Tools_Pkg.put_outdebug_message` | 838 |
| `Dka_Tools_Pkg.put_outdebug_message` | 871 |
| `Dka_Tools_Pkg.put_outdebug_message` | 876 |
| `Dka_Tools_Pkg.put_outdebug_message` | 921 |
| `Dka_Tools_Pkg.put_outdebug_message` | 923 |
| `Dka_Tools_Pkg.put_outdebug_message` | 925 |
| `Dka_Tools_Pkg.put_outdebug_message` | 927 |
| `dka_tools_pkg.put_debug_message` | 928 |
| `dka_tools_pkg.put_debug_message` | 1056 |
| `Dka_Tools_Pkg.put_debug_message` | 1064 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1066 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1069 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1078 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1094 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1142 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1175 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1223 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1225 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1227 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1229 |
| `dka_tools_pkg.put_debug_message` | 1230 |
| `dka_tools_pkg.put_debug_message` | 1256 |
| `Dka_Tools_Pkg.put_debug_message` | 1261 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1272 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1276 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1277 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1285 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1286 |
| `dka_tools_pkg.put_debug_message` | 1288 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 521 |
| when_others | 103, 152, 220, 264, 615, 931, 1233 |
| soumission | 412 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOCLOSCOM / DKA | `DKA_SPOCLOSCOM_PKG.lancement_par_region` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_F.prt:461 |
| DKA_SPOCLOSCOM / DKA | `DKA_SPOCLOSCOM_PKG.lancement_par_region` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_F.prt:461 |
| DKA_SPOCLOSCOM_PR / DKA | `DKA_SPOCLOSCOM_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_PR_F.prt:480 |
| DKA_SPOCLOSCOM_PR / DKA | `DKA_SPOCLOSCOM_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_PR_F.prt:480 |
| DKA_SPOCLOSCOM_PR / DKA | `DKA_SPOCLOSCOM_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_PR_US.prt:480 |
| DKA_SPOCLOSCOM_PR / DKA | `DKA_SPOCLOSCOM_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_PR_US.prt:480 |
| DKA_SPOCLOSCOM / DKA | `DKA_SPOCLOSCOM_PKG.lancement_par_region` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_US.prt:461 |
| DKA_SPOCLOSCOM / DKA | `DKA_SPOCLOSCOM_PKG.lancement_par_region` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_US.prt:461 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
