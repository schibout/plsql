# DKA_AUTO_ARXCOA2.sql

Source : [dka/12.0.0/sql/DKA_AUTO_ARXCOA2.sql](../../dka/12.0.0/sql/DKA_AUTO_ARXCOA2.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 712 ; encodage : cp1252 (repli). SHA-256 : `448db09253d60c2bc1bd85f45090af89294ae1cefda0d30172eb5c8b1ffb0883`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `positionnement_contexte` | 211 |
| `soumission_traitement` | 304 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_flex_value_sets` | 111 |
| `fnd_concurrent_requests` | 136 |
| `fnd_concurrent_requests` | 172 |
| `fnd_user` | 223 |
| `fnd_responsibility` | 242 |
| `fnd_concurrent_programs` | 261 |
| `fnd_concurrent_requests` | 422 |
| `gl_periods` | 560 |
| `gl_period_statuses` | 563 |
| `gl_ledgers` | 565 |
| `gl_period_statuses` | 647 |
| `gl_period_statuses` | 650 |
| `all_directories` | 658 |
| `DUAL` | 705 |
| `DUAL` | 710 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.INITIALIZE` | 276 |
| `Fnd_Request.submit_request` | 306 |
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
| `Fnd_Profile.VALUE` | 441 |
| `Dka_Tools_Pkg.get_parameter` | 448 |
| `Dka_Tools_Pkg.tab_request_params` | 575 |
| `Dka_Tools_Pkg.tab_request_params` | 576 |
| `Dka_Tools_Pkg.tab_request_params` | 577 |
| `Dka_Tools_Pkg.tab_request_params` | 578 |
| `Dka_Tools_Pkg.tab_request_params` | 579 |
| `Dka_Tools_Pkg.tab_request_params` | 580 |
| `Dka_Tools_Pkg.tab_request_params` | 581 |
| `Dka_Tools_Pkg.tab_request_params` | 582 |
| `Dka_Tools_Pkg.tab_request_params` | 583 |
| `Dka_Tools_Pkg.tab_request_params` | 584 |
| `Dka_Tools_Pkg.tab_request_params` | 585 |
| `Dka_Tools_Pkg.tab_request_params` | 586 |
| `Dka_Tools_Pkg.tab_request_params` | 587 |
| `Dka_Tools_Pkg.tab_request_params` | 588 |
| `Dka_Tools_Pkg.tab_request_params` | 589 |
| `Dka_Tools_Pkg.tab_request_params` | 590 |
| `Dka_Tools_Pkg.tab_request_params` | 591 |
| `Dka_Tools_Pkg.tab_request_params` | 592 |
| `Dka_Tools_Pkg.tab_request_params` | 593 |
| `Dka_Tools_Pkg.tab_request_params` | 602 |
| `Dka_Tools_Pkg.tab_request_params` | 603 |
| `Dka_Tools_Pkg.tab_request_params` | 604 |
| `Dka_Tools_Pkg.tab_request_params` | 605 |
| `Dka_Tools_Pkg.tab_request_params` | 606 |
| `Dka_Tools_Pkg.tab_request_params` | 607 |
| `Dka_Tools_Pkg.tab_request_params` | 608 |
| `Dka_Tools_Pkg.tab_request_params` | 609 |
| `Dka_Tools_Pkg.tab_request_params` | 610 |
| `Dka_Tools_Pkg.tab_request_params` | 611 |
| `Dka_Tools_Pkg.tab_request_params` | 612 |
| `Dka_Tools_Pkg.tab_request_params` | 613 |
| `Dka_Tools_Pkg.tab_request_params` | 614 |
| `Fnd_Concurrent.wait_for_request` | 627 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 415, 425 |
| when_others | 227, 246, 267, 568, 661, 697 |
| soumission | 306 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AUTO_ARXCOA2 / DKA | `DKA_AUTO_ARXCOA2` | dka/12.0.0/admin/import/DKA_AUTO_ARXCOA2_F.prt:419 |
| DKA_AUTO_ARXCOA2 / DKA | `DKA_AUTO_ARXCOA2` | dka/12.0.0/admin/import/DKA_AUTO_ARXCOA2_F.prt:419 |
| DKA_AUTO_ARXCOA2 / DKA | `DKA_AUTO_ARXCOA2` | dka/12.0.0/admin/import/DKA_AUTO_ARXCOA2_US.prt:419 |
| DKA_AUTO_ARXCOA2 / DKA | `DKA_AUTO_ARXCOA2` | dka/12.0.0/admin/import/DKA_AUTO_ARXCOA2_US.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
