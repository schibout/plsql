# DKA_IAPLOADIMG_XEROX_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IAPLOADIMG_XEROX_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IAPLOADIMG_XEROX_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 848 ; encodage : cp1252 (repli). SHA-256 : `43426dd15f64f70753b089cddb49c3b55a38c394186e03026954721f88e24e5a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 66 |
| `chargement_image` | 166 |
| `create_attached_doc` | 239 |
| `delete_attached_doc` | 372 |
| `stockage_image_facture_AP` | 430 |
| `Stockage_image_facture_OI` | 559 |
| `Purge_document_joint_oi` | 692 |
| `main` | 783 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_document_categories` | 132 |
| `fnd_document_datatypes` | 140 |
| `dual` | 195 |
| `fnd_lobs` | 197 |
| `fnd_attached_documents` | 259 |
| `DUAL` | 273 |
| `fnd_documents_tl` | 275 |
| `fnd_documents` | 298 |
| `DUAL` | 325 |
| `fnd_attached_documents` | 327 |
| `fnd_documents_tl` | 387 |
| `ap_invoices_all` | 436 |
| `ap_invoices_all` | 442 |
| `fnd_attached_documents` | 448 |
| `ap_invoices_interface` | 565 |
| `ap_invoices_interface` | 573 |
| `fnd_attached_documents` | 581 |
| `fnd_attached_documents` | 699 |
| `ap_invoices_interface` | 702 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 76 |
| `Dka_Tools_Pkg.get_parameter` | 99 |
| `Dka_Tools_Pkg.put_debug_message` | 114 |
| `Dka_Tools_Pkg.get_parameter` | 115 |
| `Dka_Tools_Pkg.put_debug_message` | 135 |
| `Dka_Tools_Pkg.put_debug_message` | 143 |
| `dka_tools_pkg.put_debug_message` | 144 |
| `dka_tools_pkg.put_debug_message` | 182 |
| `dka_tools_pkg.put_debug_message` | 217 |
| `dka_tools_pkg.put_debug_message` | 221 |
| `dka_tools_pkg.put_debug_message` | 253 |
| `dka_tools_pkg.put_debug_message` | 348 |
| `dka_tools_pkg.put_debug_message` | 352 |
| `dka_tools_pkg.put_debug_message` | 380 |
| `dka_Tools_Pkg.put_outdebug_message` | 406 |
| `dka_tools_pkg.put_debug_message` | 407 |
| `dka_tools_pkg.put_debug_message` | 410 |
| `dka_tools_pkg.put_debug_message` | 467 |
| `dka_tools_pkg.put_outdebug_message` | 469 |
| `Dka_Tools_Pkg.put_outdebug_message` | 492 |
| `Dka_Tools_Pkg.put_outdebug_message` | 496 |
| `Dka_Tools_Pkg.put_outdebug_message` | 503 |
| `dka_tools_pkg.put_debug_message` | 504 |
| `Dka_Tools_Pkg.put_outdebug_message` | 510 |
| `dka_tools_pkg.put_debug_message` | 511 |
| `fnd_file.put_line` | 529 |
| `dka_tools_pkg.put_outdebug_message` | 530 |
| `dka_tools_pkg.put_outdebug_message` | 531 |
| `dka_tools_pkg.put_outdebug_message` | 532 |
| `dka_tools_pkg.put_outdebug_message` | 533 |
| `dka_tools_pkg.put_debug_message` | 535 |
| `dka_tools_pkg.put_debug_message` | 541 |
| `dka_tools_pkg.put_debug_message` | 600 |
| `fnd_file.put_line` | 602 |
| `Dka_Tools_Pkg.put_outdebug_message` | 603 |
| `Dka_Tools_Pkg.put_outdebug_message` | 625 |
| `Dka_Tools_Pkg.put_outdebug_message` | 629 |
| `Dka_Tools_Pkg.put_outdebug_message` | 636 |
| `dka_tools_pkg.put_debug_message` | 637 |
| `Dka_Tools_Pkg.put_outdebug_message` | 643 |
| `dka_tools_pkg.put_debug_message` | 644 |
| `fnd_file.put_line` | 663 |
| `dka_tools_pkg.put_outdebug_message` | 664 |
| `dka_Tools_pkg.put_outdebug_message` | 665 |
| `dka_Tools_pkg.put_outdebug_message` | 666 |
| `dka_Tools_pkg.put_outdebug_message` | 667 |
| `dka_tools_pkg.put_debug_message` | 669 |
| `dka_tools_pkg.put_debug_message` | 674 |
| `dka_tools_pkg.put_debug_message` | 716 |
| `fnd_file.put_line` | 719 |
| `Dka_Tools_Pkg.put_outdebug_message` | 720 |
| `Dka_Tools_Pkg.put_outdebug_message` | 739 |
| `dka_tools_pkg.put_debug_message` | 740 |
| `fnd_file.put_line` | 754 |
| `dka_tools_pkg.put_outdebug_message` | 755 |
| `dka_Tools_pkg.put_outdebug_message` | 756 |
| `dka_Tools_pkg.put_outdebug_message` | 757 |
| `dka_tools_pkg.put_debug_message` | 759 |
| `dka_tools_pkg.put_debug_message` | 764 |
| `dka_tools_pkg.put_debug_message` | 790 |
| `dka_tools_pkg.put_outdebug_message` | 801 |
| `dka_tools_pkg.put_outdebug_message` | 811 |
| `dka_tools_pkg.put_outdebug_message` | 820 |
| `dka_tools_pkg.put_outdebug_message` | 829 |
| `Fnd_File.put_line` | 832 |
| `dka_tools_pkg.get_message` | 832 |
| `Fnd_File.put_line` | 833 |
| `dka_tools_pkg.put_debug_message` | 835 |
| `dka_tools_pkg.put_debug_message` | 839 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 494, 627 |
| rollback | 224, 355, 413, 506, 514, 544, 639, 647, 677, 742, 767, 842 |
| when_others | 147, 220, 351, 390, 409, 508, 540, 641, 673, 763, 838 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IAPLOADIMG_XEROX / DKA | `DKA_IAPLOADIMG_XEROX_PKG.MAIN` | dka/12.0.0/admin/import/DKA_IAPLOADIMG_XEROX.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
