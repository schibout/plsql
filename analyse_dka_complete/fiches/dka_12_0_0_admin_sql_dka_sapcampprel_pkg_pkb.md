# DKA_SAPCAMPPREL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPCAMPPREL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPCAMPPREL_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1066 ; encodage : cp1252 (repli). SHA-256 : `4cae9418ee1eee77cd26a5772c322a5274a6adce2025a75ec72a6aab6fe3aca3`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `launch_program_payment` | 42 |
| `Campagne_prelevement` | 194 |
| `Main` | 612 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ap_inv_selection_criteria_all` | 146 |
| `fnd_conc_req_summary_v` | 150 |
| `Fnd_Concurrent_Requests` | 241 |
| `ap_invoice_selection_criteria` | 253 |
| `dka_ap_prelevement_tmp` | 281 |
| `Ap_System_Parameters` | 368 |
| `ce_bank_accounts` | 401 |
| `dual` | 435 |
| `AP_PAYMENT_TEMPLATES` | 439 |
| `Gl_Period_Statuses` | 466 |
| `DKA_AP_PRELEVEMENT_TMP` | 667 |
| `ap_invoices_all` | 702 |
| `dka_ap_prelevement_tmp` | 747 |
| `of` | 749 |
| `Ap_invoices_all` | 753 |
| `of` | 760 |
| `Ap_Payment_Schedules_All` | 764 |
| `po_vendor_sites` | 819 |
| `ap_invoices_all` | 824 |
| `dka_ap_prelevement_tmp` | 864 |
| `of` | 866 |
| `Ap_invoices_all` | 870 |
| `of` | 877 |
| `Ap_Payment_Schedules_All` | 881 |
| `ap_invoices_all` | 938 |
| `dka_ap_prelevement_tmp` | 981 |
| `of` | 983 |
| `Ap_invoices_all` | 987 |
| `of` | 994 |
| `Ap_Payment_Schedules_All` | 998 |
| `Ap_Payment_Schedules_All` | 1026 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_request.submit_request` | 60 |
| `fnd_date.date_to_canonical` | 67 |
| `fnd_date.date_to_canonical` | 69 |
| `fnd_file.put_line` | 74 |
| `dka_tools_pkg.put_log_message` | 78 |
| `fnd_file.put_line` | 85 |
| `dka_tools_pkg.put_log_message` | 88 |
| `fnd_concurrent.wait_for_request` | 94 |
| `fnd_file.put_line` | 105 |
| `fnd_file.put_line` | 112 |
| `fnd_file.put_line` | 115 |
| `fnd_file.put_line` | 120 |
| `fnd_file.put_line` | 132 |
| `fnd_file.put_line` | 137 |
| `dka_tools_pkg.put_log_message` | 168 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 263 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 269 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 270 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 277 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 283 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 284 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 287 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 288 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 289 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 290 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 291 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 292 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 302 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 310 |
| `Dka_Tools_Pkg.Get_Parameter` | 312 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 319 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 320 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 321 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 322 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 323 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 324 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 325 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 331 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 333 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 335 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 337 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 339 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 341 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 347 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 348 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 349 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 350 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 351 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 352 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 353 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 354 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 355 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 363 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 364 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 374 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 375 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 379 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 380 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 381 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 382 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 383 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 384 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 385 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 386 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 396 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 397 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 405 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 406 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 410 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 411 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 412 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 413 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 414 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 415 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 416 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 417 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 418 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 429 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 430 |
| `fnd_profile.VALUE` | 433 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 447 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 448 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 449 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 450 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 451 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 452 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 453 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 454 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 477 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 478 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 488 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 489 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 493 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 494 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 495 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 496 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 497 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 498 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 499 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 500 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 514 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 516 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 523 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 524 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 525 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 526 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 527 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 528 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 529 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 530 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 535 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 545 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 546 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 558 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 559 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 560 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 561 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 562 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 563 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 566 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 567 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 570 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 574 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 580 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 626 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 628 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 629 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 630 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 631 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 632 |
| `fnd_date.canonical_to_date` | 632 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 633 |
| `fnd_date.canonical_to_date` | 633 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 634 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 635 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 636 |
| `fnd_date.canonical_to_date` | 656 |
| `fnd_date.canonical_to_date` | 657 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 659 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 660 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 661 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 662 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 679 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 680 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 681 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 682 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 684 |
| `ap_invoices_pkg.get_approval_status` | 724 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 729 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 736 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 737 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 738 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 739 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 743 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 749 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 760 |
| `Dka_Tools_Pkg.put_outdebug_message` | 773 |
| `Dka_Tools_Pkg.put_outdebug_message` | 774 |
| `Dka_Tools_Pkg.put_outdebug_message` | 778 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 782 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 797 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 798 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 799 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 800 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 802 |
| `ap_invoices_pkg.get_approval_status` | 840 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 845 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 853 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 854 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 855 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 856 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 860 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 866 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 877 |
| `Dka_Tools_Pkg.put_outdebug_message` | 890 |
| `Dka_Tools_Pkg.put_outdebug_message` | 891 |
| `Dka_Tools_Pkg.put_outdebug_message` | 895 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 899 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 913 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 914 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 915 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 916 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 920 |
| `ap_invoices_pkg.get_approval_status` | 956 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 961 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 968 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 969 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 970 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 971 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 977 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 983 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 994 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1009 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1015 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1016 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1017 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1018 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1039 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1044 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1045 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1046 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1047 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1049 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1050 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1053 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1054 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1055 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1056 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1059 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1060 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `APXPBASL` | 60 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 83 |
| rollback | 1043, 1052 |
| when_others | 155, 165, 286, 346, 378, 409, 446, 522, 577, 1051 |
| suppression | 667 |
| soumission | 60 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPCAMPPREL_PKG / DKA | `DKA_SAPCAMPPREL_PKG.main` | dka/12.0.0/admin/import/DKA_SAPCAMPPREL_PKG.prt:825 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
