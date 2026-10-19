# DKA_SPOBON_STOCIMG_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOBON_STOCIMG_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOBON_STOCIMG_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 772 ; encodage : cp1252 (repli). SHA-256 : `6a673c88d221c6c26c823ac1ebdcd2c4efbe2a37ed310dbc14b263881703530e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 52 |
| `get_po_header_id` | 139 |
| `get_doc_bdc` | 168 |
| `chargement_image` | 286 |
| `delete_image` | 365 |
| `create_attached_document_bdc` | 400 |
| `update_attached_document_bdc` | 538 |
| `main` | 591 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_document_categories` | 108 |
| `fnd_document_datatypes` | 116 |
| `po_headers_all` | 148 |
| `fnd_attached_documents` | 180 |
| `fnd_documents_tl` | 235 |
| `dual` | 315 |
| `fnd_lobs` | 319 |
| `fnd_attached_documents` | 421 |
| `DUAL` | 434 |
| `fnd_documents_tl` | 436 |
| `fnd_documents` | 460 |
| `DUAL` | 490 |
| `fnd_attached_documents` | 492 |
| `fnd_documents_tl` | 551 |
| `fnd_documents` | 558 |
| `fnd_concurrent_requests` | 640 |
| `po_headers` | 661 |
| `ATTACHED` | 719 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 61 |
| `Dka_Tools_Pkg.get_parameter` | 75 |
| `Dka_Tools_Pkg.put_debug_message` | 89 |
| `Dka_Tools_Pkg.get_parameter` | 91 |
| `Dka_Tools_Pkg.put_debug_message` | 111 |
| `Dka_Tools_Pkg.put_debug_message` | 119 |
| `dka_tools_pkg.put_debug_message` | 121 |
| `dka_tools_pkg.put_debug_message` | 191 |
| `dka_tools_pkg.put_debug_message` | 247 |
| `dka_tools_pkg.put_debug_message` | 262 |
| `dka_tools_pkg.put_debug_message` | 267 |
| `dka_tools_pkg.put_debug_message` | 302 |
| `dka_tools_pkg.put_debug_message` | 317 |
| `dka_tools_pkg.put_debug_message` | 339 |
| `dka_tools_pkg.put_debug_message` | 343 |
| `dka_tools_pkg.put_debug_message` | 347 |
| `dka_tools_pkg.put_debug_message` | 349 |
| `dka_tools_pkg.put_debug_message` | 372 |
| `dka_Tools_Pkg.put_outdebug_message` | 378 |
| `dka_tools_pkg.put_debug_message` | 379 |
| `dka_tools_pkg.put_debug_message` | 382 |
| `dka_tools_pkg.put_debug_message` | 384 |
| `dka_tools_pkg.put_debug_message` | 413 |
| `dka_Tools_Pkg.put_outdebug_message` | 514 |
| `dka_tools_pkg.put_debug_message` | 515 |
| `dka_tools_pkg.put_debug_message` | 519 |
| `dka_tools_pkg.put_debug_message` | 521 |
| `dka_tools_pkg.put_debug_message` | 548 |
| `Dka_Tools_Pkg.put_outdebug_message` | 565 |
| `dka_tools_pkg.put_debug_message` | 567 |
| `dka_tools_pkg.put_debug_message` | 570 |
| `dka_tools_pkg.put_debug_message` | 572 |
| `dka_tools_pkg.put_debug_message` | 612 |
| `Dka_Tools_Pkg.put_debug_message` | 617 |
| `Dka_Tools_Pkg.put_outdebug_message` | 625 |
| `Dka_Tools_Pkg.put_outdebug_message` | 629 |
| `Dka_Tools_Pkg.put_outdebug_message` | 630 |
| `Dka_Tools_Pkg.put_outdebug_message` | 650 |
| `Dka_Tools_Pkg.put_outdebug_message` | 651 |
| `Dka_Tools_Pkg.put_outdebug_message` | 652 |
| `Dka_Tools_Pkg.put_outdebug_message` | 653 |
| `Dka_Tools_Pkg.put_outdebug_message` | 654 |
| `Dka_Tools_Pkg.put_outdebug_message` | 655 |
| `Dka_Tools_Pkg.put_outdebug_message` | 675 |
| `Dka_Tools_Pkg.put_outdebug_message` | 677 |
| `Dka_Tools_Pkg.put_outdebug_message` | 678 |
| `Dka_Tools_Pkg.put_outdebug_message` | 679 |
| `Dka_Tools_Pkg.put_outdebug_message` | 691 |
| `Dka_Tools_Pkg.put_outdebug_message` | 708 |
| `Dka_Tools_Pkg.put_outdebug_message` | 720 |
| `Dka_Tools_Pkg.put_outdebug_message` | 734 |
| `Dka_Tools_Pkg.put_outdebug_message` | 751 |
| `Dka_Tools_Pkg.put_outdebug_message` | 756 |
| `Dka_Tools_Pkg.put_outdebug_message` | 757 |
| `dka_tools_pkg.put_debug_message` | 759 |
| `Dka_Tools_Pkg.put_outdebug_message` | 765 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 352, 387, 524, 575 |
| when_others | 123, 251, 270, 346, 381, 518, 569 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOBON_STOCIMG / DKA | `dka_spobon_stocimg_pkg.main` | dka/12.0.0/admin/import/DKA_SPOBON_STOCIMG_F.prt:419 |
| DKA_SPOBON_STOCIMG / DKA | `dka_spobon_stocimg_pkg.main` | dka/12.0.0/admin/import/DKA_SPOBON_STOCIMG_F.prt:419 |
| DKA_SPOBON_STOCIMG / DKA | `dka_spobon_stocimg_pkg.main` | dka/12.0.0/admin/import/DKA_SPOBON_STOCIMG_US.prt:419 |
| DKA_SPOBON_STOCIMG / DKA | `dka_spobon_stocimg_pkg.main` | dka/12.0.0/admin/import/DKA_SPOBON_STOCIMG_US.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
