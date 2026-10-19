# DKA_EMPJOBSIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_EMPJOBSIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_EMPJOBSIMP_PKG.pkb).

Famille proposée par convention de nommage : **RH / employés**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 854 ; encodage : cp1252 (repli). SHA-256 : `25caf8e4b08b151a5971af3b3de3c3a76965c1f3ba7f90aa3ac3ab0aca0c7031`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 77 |
| `output_header` | 162 |
| `output_end` | 216 |
| `Launch_Loader` | 246 |
| `validate_data` | 353 |
| `import_data` | 441 |
| `Report_Bilan` | 631 |
| `purge_data` | 690 |
| `main` | 724 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 125 |
| `fnd_concurrent_programs` | 177 |
| `DKA_EMPLOYEE_JOBS_TMP` | 306 |
| `DKA_EMPLOYEE_JOBS_TMP` | 364 |
| `DKA_REP_TRANSCO_LINES` | 368 |
| `per_all_people_f` | 381 |
| `DKA_EMPLOYEE_JOBS_TMP` | 390 |
| `DKA_EMPLOYEE_JOBS_TMP` | 395 |
| `DKA_REP_TRANSCO_LINES` | 407 |
| `DKA_EMPLOYEE_JOBS_TMP` | 474 |
| `DKA_REP_TRANSCO_LINES` | 485 |
| `DKA_EMPLOYEE_JOBS_TMP` | 496 |
| `per_jobs` | 508 |
| `DKA_EMPLOYEE_JOBS_TMP` | 516 |
| `per_all_people_f` | 533 |
| `per_all_assignments_f` | 534 |
| `DKA_EMPLOYEE_JOBS_TMP` | 575 |
| `DKA_EMPLOYEE_JOBS_TMP` | 582 |
| `DKA_EMPLOYEE_JOBS_TMP` | 591 |
| `DKA_EMPLOYEE_JOBS_TMP` | 697 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 88 |
| `fnd_profile.value` | 104 |
| `Fnd_File.put_line` | 118 |
| `Fnd_File.put_line` | 130 |
| `fnd_file.put_line` | 137 |
| `Fnd_File.put_line` | 192 |
| `Fnd_File.put_line` | 193 |
| `Fnd_File.put_line` | 194 |
| `Fnd_File.put_line` | 195 |
| `Fnd_File.put_line` | 196 |
| `Fnd_File.put_line` | 223 |
| `Fnd_File.put_line` | 224 |
| `Fnd_File.put_line` | 225 |
| `Fnd_File.put_line` | 257 |
| `Fnd_File.put_line` | 258 |
| `fnd_file.put_line` | 261 |
| `fnd_file.put_line` | 262 |
| `fnd_file.put_line` | 263 |
| `fnd_request.set_print_options` | 268 |
| `Fnd_Request.submit_request` | 271 |
| `fnd_file.put_line` | 282 |
| `Fnd_File.put_line` | 285 |
| `Fnd_File.put_line` | 288 |
| `Fnd_File.put_line` | 289 |
| `Fnd_Concurrent.wait_for_request` | 292 |
| `Fnd_file.put_line` | 295 |
| `Fnd_File.put_line` | 301 |
| `Fnd_File.put_line` | 302 |
| `Fnd_File.put_line` | 311 |
| `fnd_file.put_line` | 319 |
| `Fnd_File.put_line` | 322 |
| `Fnd_File.put_line` | 325 |
| `Fnd_File.put_line` | 332 |
| `Fnd_File.put_line` | 333 |
| `Fnd_File.put_line` | 373 |
| `Fnd_File.put_line` | 374 |
| `fnd_file.put_line` | 399 |
| `Fnd_File.put_line` | 420 |
| `Fnd_File.put_line` | 421 |
| `fnd_file.put_line` | 501 |
| `fnd_file.put_line` | 520 |
| `Fnd_File.put_line` | 586 |
| `Fnd_File.put_line` | 595 |
| `Fnd_File.put_line` | 605 |
| `Fnd_File.put_line` | 611 |
| `Fnd_File.put_line` | 612 |
| `Fnd_File.put_line` | 638 |
| `fnd_file.put_line` | 647 |
| `fnd_file.put_line` | 648 |
| `fnd_file.put_line` | 649 |
| `fnd_file.put_line` | 651 |
| `fnd_file.put_line` | 652 |
| `fnd_file.put_line` | 654 |
| `fnd_file.put_line` | 656 |
| `fnd_file.put_line` | 657 |
| `fnd_file.put_line` | 658 |
| `fnd_file.put_line` | 660 |
| `fnd_file.put_line` | 662 |
| `Fnd_File.put_line` | 663 |
| `Fnd_File.put_line` | 671 |
| `Fnd_File.put_line` | 672 |
| `Fnd_File.Put_Line` | 699 |
| `Fnd_File.put_line` | 705 |
| `Fnd_File.put_line` | 706 |
| `Fnd_File.put_line` | 739 |
| `Fnd_File.put_line` | 743 |
| `Fnd_File.put_line` | 760 |
| `Fnd_File.put_line` | 774 |
| `Fnd_File.put_line` | 827 |
| `Fnd_File.put_line` | 828 |
| `Fnd_File.put_line` | 830 |
| `Fnd_File.put_line` | 838 |
| `Fnd_File.put_line` | 839 |
| `Fnd_File.put_line` | 840 |
| `Fnd_File.put_line` | 845 |
| `Fnd_File.put_line` | 846 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_LOADER_EMPJOBSIMP` | 271 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 287, 414, 825 |
| rollback | 2 |
| when_others | 139, 185, 328, 417, 608, 667, 702, 841 |
| suppression | 697 |
| soumission | 271 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_EMPJOBSIMP / DKA | `DKA_EMPJOBSIMP_PKG.Main` | dka/12.0.0/admin/import/DKA_EMPJOBSIMP.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
