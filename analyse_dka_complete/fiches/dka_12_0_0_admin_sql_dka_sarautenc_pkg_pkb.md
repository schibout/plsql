# DKA_SARAUTENC_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARAUTENC_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARAUTENC_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 772 ; encodage : cp1252 (repli). SHA-256 : `254cb56e0e3ba537aaca4208f677a005e869c8ea1054480d71150724f082a13b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 62 |
| `output_header` | 156 |
| `Request_parameters` | 206 |
| `output_end` | 304 |
| `print_errors` | 337 |
| `create_data` | 403 |
| `main` | 658 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility` | 105 |
| `fnd_concurrent_requests` | 119 |
| `fnd_concurrent_programs` | 168 |
| `fnd_concurrent_requests` | 210 |
| `fnd_concurrent_requests` | 241 |
| `fnd_concurrent_requests` | 263 |
| `DKA_PROGRAM_MESSAGES` | 341 |
| `DKA_PROGRAM_MESSAGES` | 349 |
| `ar_cash_receipts_all` | 421 |
| `AR_CASH_RECEIPT_HISTORY_ALL` | 443 |
| `dual` | 471 |
| `ar_receipt_methods` | 479 |
| `ar_cash_receipts_all` | 524 |
| `ra_customer_trx_all` | 525 |
| `AR_CASH_RECEIPTS_all` | 526 |
| `ar_cash_receipts_all` | 610 |
| `dka_program_messages` | 615 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_debug_message` | 74 |
| `fnd_profile.value` | 92 |
| `Dka_Tools_Pkg.put_debug_message` | 99 |
| `Fnd_Global.apps_initialize` | 108 |
| `Dka_Tools_Pkg.put_debug_message` | 123 |
| `Dka_Tools_Pkg.put_debug_message` | 133 |
| `Fnd_File.put_line` | 180 |
| `Fnd_File.put_line` | 181 |
| `Fnd_File.put_line` | 183 |
| `Fnd_File.put_line` | 185 |
| `Fnd_File.put_line` | 188 |
| `Fnd_File.put_line` | 226 |
| `Fnd_File.put_line` | 227 |
| `Dka_Tools_Pkg.put_debug_message` | 228 |
| `Dka_Tools_Pkg.put_debug_message` | 229 |
| `Fnd_File.put_line` | 247 |
| `Dka_Tools_Pkg.put_debug_message` | 250 |
| `Fnd_File.put_line` | 269 |
| `Dka_Tools_Pkg.put_debug_message` | 272 |
| `Fnd_File.put_line` | 277 |
| `Fnd_File.put_line` | 280 |
| `Dka_Tools_Pkg.put_debug_message` | 281 |
| `Fnd_File.put_line` | 310 |
| `Fnd_File.put_line` | 311 |
| `Fnd_File.put_line` | 314 |
| `fnd_file.put_line` | 357 |
| `fnd_file.put_line` | 358 |
| `fnd_file.put_line` | 359 |
| `fnd_file.put_line` | 360 |
| `fnd_file.put_line` | 361 |
| `fnd_file.put_line` | 362 |
| `fnd_file.put_line` | 363 |
| `Fnd_File.put_line` | 366 |
| `fnd_file.put_line` | 369 |
| `fnd_file.put_line` | 370 |
| `fnd_file.put_line` | 371 |
| `fnd_file.put_line` | 372 |
| `fnd_file.put_line` | 373 |
| `Fnd_File.put_line` | 376 |
| `Dka_Tools_Pkg.put_debug_message` | 462 |
| `Dka_Tools_Pkg.put_debug_message` | 463 |
| `Dka_Tools_Pkg.put_debug_message` | 470 |
| `Dka_Tools_Pkg.put_debug_message` | 472 |
| `Dka_Tools_Pkg.put_debug_message` | 495 |
| `Dka_Tools_Pkg.put_debug_message` | 499 |
| `AR_RECEIPT_API_PUB.Create_and_apply` | 501 |
| `Dka_Tools_Pkg.put_debug_message` | 533 |
| `Dka_Tools_Pkg.put_debug_message` | 534 |
| `Dka_Tools_Pkg.put_debug_message` | 535 |
| `Dka_Tools_Pkg.put_debug_message` | 536 |
| `dka_tools_pkg.ins_prog_message` | 538 |
| `FND_MSG_PUB.get` | 555 |
| `Dka_Tools_Pkg.put_debug_message` | 559 |
| `Dka_Tools_Pkg.put_debug_message` | 563 |
| `dka_tools_pkg.ins_prog_message` | 565 |
| `Dka_Tools_Pkg.put_debug_message` | 583 |
| `dka_tools_pkg.ins_prog_message` | 585 |
| `Dka_Tools_Pkg.put_debug_message` | 608 |
| `Dka_Tools_Pkg.put_debug_message` | 623 |
| `Dka_Tools_Pkg.put_debug_message` | 624 |
| `Dka_Tools_Pkg.put_debug_message` | 631 |
| `Dka_Tools_Pkg.put_debug_message` | 632 |
| `Dka_Tools_Pkg.put_debug_message` | 674 |
| `Dka_Tools_Pkg.put_debug_message` | 681 |
| `Dka_Tools_Pkg.put_debug_message` | 701 |
| `Dka_Tools_Pkg.put_debug_message` | 734 |
| `Fnd_File.put_line` | 735 |
| `Dka_Tools_Pkg.put_debug_message` | 737 |
| `Dka_Tools_Pkg.put_debug_message` | 745 |
| `Fnd_File.put_line` | 746 |
| `Dka_Tools_Pkg.put_debug_message` | 747 |
| `Fnd_File.put_line` | 751 |
| `Dka_Tools_Pkg.put_debug_message` | 758 |
| `Fnd_File.put_line` | 762 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 604 |
| rollback | 2 |
| when_others | 135, 175, 491, 628, 755 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARAUTENC / DKA | `DKA_SARAUTENC_PKG.main` | dka/12.0.0/admin/import/DKA_SARAUTENC.prt:420 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
