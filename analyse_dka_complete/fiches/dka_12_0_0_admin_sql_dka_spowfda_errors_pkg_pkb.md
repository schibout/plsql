# DKA_SPOWFDA_ERRORS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOWFDA_ERRORS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOWFDA_ERRORS_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 812 ; encodage : cp1252 (repli). SHA-256 : `f09b090eba52713da11e3df9c23667fe703c454a57f90470f465188e898d342f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 55 |
| `insert_dka_spowfda_errors` | 155 |
| `maj_da` | 271 |
| `fermeture_notif_erreur` | 317 |
| `mail` | 410 |
| `deblocage_da` | 491 |
| `envoi_mail` | 609 |
| `main` | 754 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_spowfda_errors` | 171 |
| `po_requisition_headers_all` | 211 |
| `wf_item_activity_statuses` | 228 |
| `po_requisition_headers_all` | 286 |
| `wf_notifications` | 334 |
| `wf_item_activity_statuses` | 346 |
| `wf_item_activity_statuses` | 356 |
| `wf_items` | 367 |
| `wf_item_activity_statuses` | 376 |
| `dka_spowfda_errors` | 503 |
| `dka_spowfda_errors` | 545 |
| `dka_spowfda_errors` | 561 |
| `dka_spowfda_errors` | 571 |
| `dka_spowfda_errors` | 625 |
| `dka_spowfda_errors` | 673 |
| `dka_spowfda_errors` | 700 |
| `dka_spowfda_errors` | 712 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 62 |
| `Dka_Tools_Pkg.get_parameter` | 89 |
| `Dka_Tools_Pkg.put_debug_message` | 103 |
| `Dka_Tools_Pkg.get_parameter` | 105 |
| `Dka_Tools_Pkg.put_debug_message` | 119 |
| `Dka_Tools_Pkg.get_parameter` | 121 |
| `Dka_Tools_Pkg.put_debug_message` | 133 |
| `dka_tools_pkg.put_debug_message` | 137 |
| `dka_tools_pkg.put_debug_message` | 163 |
| `Dka_Tools_Pkg.put_outdebug_message` | 167 |
| `Dka_Tools_Pkg.put_outdebug_message` | 168 |
| `Dka_Tools_Pkg.put_outdebug_message` | 243 |
| `Dka_Tools_Pkg.put_outdebug_message` | 244 |
| `Dka_Tools_Pkg.put_outdebug_message` | 246 |
| `Dka_Tools_Pkg.put_outdebug_message` | 247 |
| `dka_tools_pkg.put_debug_message` | 251 |
| `dka_tools_pkg.put_debug_message` | 279 |
| `Dka_Tools_Pkg.put_debug_message` | 284 |
| `dka_tools_pkg.put_debug_message` | 293 |
| `dka_tools_pkg.put_debug_message` | 296 |
| `dka_tools_pkg.put_debug_message` | 326 |
| `Dka_Tools_Pkg.put_debug_message` | 331 |
| `dka_tools_pkg.put_debug_message` | 341 |
| `dka_tools_pkg.put_debug_message` | 363 |
| `dka_tools_pkg.put_debug_message` | 372 |
| `dka_tools_pkg.put_debug_message` | 385 |
| `dka_tools_pkg.put_debug_message` | 388 |
| `dka_tools_pkg.put_debug_message` | 428 |
| `Dka_Tools_Pkg.put_debug_message` | 433 |
| `Dka_Tools_Pkg.get_message` | 437 |
| `Dka_Tools_Pkg.get_message` | 448 |
| `dka_tools_pkg.put_debug_message` | 469 |
| `dka_tools_pkg.put_debug_message` | 510 |
| `Dka_Tools_Pkg.put_debug_message` | 515 |
| `Dka_Tools_Pkg.put_outdebug_message` | 517 |
| `Dka_Tools_Pkg.put_outdebug_message` | 518 |
| `Dka_Tools_Pkg.put_outdebug_message` | 525 |
| `Dka_Tools_Pkg.put_outdebug_message` | 526 |
| `Dka_Tools_Pkg.put_debug_message` | 537 |
| `Dka_Tools_Pkg.put_outdebug_message` | 576 |
| `Dka_Tools_Pkg.put_outdebug_message` | 586 |
| `dka_tools_pkg.put_debug_message` | 587 |
| `dka_tools_pkg.put_debug_message` | 635 |
| `Dka_Tools_Pkg.put_debug_message` | 641 |
| `Dka_Tools_Pkg.put_outdebug_message` | 643 |
| `Dka_Tools_Pkg.put_outdebug_message` | 644 |
| `Dka_Tools_Pkg.put_outdebug_message` | 651 |
| `Dka_Tools_Pkg.put_outdebug_message` | 652 |
| `Dka_Tools_Pkg.put_debug_message` | 664 |
| `Dka_Tools_Pkg.put_outdebug_message` | 671 |
| `Dka_Tools_Pkg.put_debug_message` | 706 |
| `Dka_Tools_Pkg.put_outdebug_message` | 707 |
| `Dka_Tools_Pkg.put_outdebug_message` | 717 |
| `dka_tools_pkg.put_debug_message` | 730 |
| `Dka_Tools_Pkg.put_outdebug_message` | 731 |
| `dka_tools_pkg.put_debug_message` | 761 |
| `Dka_Tools_Pkg.put_debug_message` | 766 |
| `DKA_SEND_MAIL_PKG.mail_test` | 772 |
| `dka_tools_pkg.put_debug_message` | 773 |
| `Dka_Tools_Pkg.put_outdebug_message` | 781 |
| `Dka_Tools_Pkg.put_outdebug_message` | 785 |
| `Dka_Tools_Pkg.put_outdebug_message` | 786 |
| `Dka_Tools_Pkg.put_outdebug_message` | 799 |
| `Dka_Tools_Pkg.put_outdebug_message` | 800 |
| `dka_tools_pkg.put_debug_message` | 802 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 139, 253, 299, 392, 472, 590, 734 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOWFDA_ERRORS / DKA | `dka_spowfda_errors_pkg.main` | dka/12.0.0/admin/import/DKA_SPOWFDA_ERRORS.prt:458 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
