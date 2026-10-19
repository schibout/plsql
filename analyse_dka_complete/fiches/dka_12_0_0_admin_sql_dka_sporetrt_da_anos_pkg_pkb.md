# DKA_SPORETRT_DA_ANOS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPORETRT_DA_ANOS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPORETRT_DA_ANOS_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 822 ; encodage : cp1252 (repli). SHA-256 : `03e5517fe98690d5a7181f99dfcb841de59be766e59fa57e569f3123a9b7f55b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 38 |
| `INIT` | 90 |
| `DA_Catalog_Non_Trans_Cmd_Relan` | 102 |
| `DA_Catalog_Non_Trans_Cmd_Notif` | 298 |
| `DA_Statut_Incomplet` | 417 |
| `DA_Statut_System_Saved` | 557 |
| `recherche_mail` | 691 |
| `envoi_mail` | 755 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `v$database` | 57 |
| `PO_REQUISITION_LINES_ALL` | 112 |
| `dual` | 165 |
| `dual` | 173 |
| `DKA_SPORETRT_DA_ANOS_TMP` | 187 |
| `wf_items` | 214 |
| `DKA_SPORETRT_DA_ANOS_TMP` | 242 |
| `DKA_SPORETRT_DA_ANOS_TMP` | 255 |
| `DKA_SPORETRT_DA_ANOS_TMP` | 315 |
| `wf_item_activity_statuses` | 360 |
| `PO_REQUISITION_LINES_ALL` | 427 |
| `dual` | 473 |
| `dual` | 481 |
| `wf_items` | 504 |
| `PO_REQUISITION_LINES_ALL` | 569 |
| `dual` | 615 |
| `dual` | 623 |
| `PO_REQUISITION_HEADERS_ALL` | 637 |
| `po_requisition_headers_all` | 713 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.get_parameter` | 66 |
| `Dka_Tools_Pkg.put_log_message` | 69 |
| `Dka_Tools_Pkg.get_parameter` | 76 |
| `Dka_Tools_Pkg.put_log_message` | 78 |
| `Dka_Tools_Pkg.put_log_message` | 88 |
| `Dka_Tools_Pkg.put_log_message` | 92 |
| `Dka_Tools_Pkg.put_log_message` | 154 |
| `Dka_Tools_Pkg.put_log_message` | 155 |
| `Dka_Tools_Pkg.put_log_message` | 156 |
| `Dka_Tools_Pkg.put_log_message` | 157 |
| `Dka_Tools_Pkg.put_log_message` | 158 |
| `Dka_Tools_Pkg.put_log_message` | 170 |
| `Dka_Tools_Pkg.put_log_message` | 171 |
| `Dka_Tools_Pkg.put_log_message` | 174 |
| `Dka_Tools_Pkg.put_log_message` | 190 |
| `Dka_Tools_Pkg.put_log_message` | 197 |
| `Dka_Tools_Pkg.put_log_message` | 198 |
| `Dka_Tools_Pkg.put_log_message` | 199 |
| `Dka_Tools_Pkg.put_log_message` | 229 |
| `Dka_Tools_Pkg.put_log_message` | 231 |
| `Wf_Engine_Util.Start_Process_Internal` | 233 |
| `Dka_Tools_Pkg.put_log_message` | 254 |
| `Dka_Tools_Pkg.put_log_message` | 255 |
| `Dka_Tools_Pkg.put_log_message` | 261 |
| `Dka_Tools_Pkg.put_log_message` | 271 |
| `Dka_Tools_Pkg.put_log_message` | 272 |
| `Dka_Tools_Pkg.put_log_message` | 273 |
| `Dka_Tools_Pkg.put_log_message` | 282 |
| `Dka_Tools_Pkg.put_log_message` | 283 |
| `Dka_Tools_Pkg.put_log_message` | 284 |
| `Dka_Tools_Pkg.put_log_message` | 285 |
| `Dka_Tools_Pkg.put_log_message` | 286 |
| `Dka_Tools_Pkg.put_log_message` | 287 |
| `Dka_Tools_Pkg.put_log_message` | 340 |
| `Dka_Tools_Pkg.put_log_message` | 341 |
| `Dka_Tools_Pkg.put_log_message` | 342 |
| `Dka_Tools_Pkg.put_log_message` | 343 |
| `Dka_Tools_Pkg.put_log_message` | 344 |
| `WF_ENGINE.HandleError` | 374 |
| `Dka_Tools_Pkg.put_log_message` | 379 |
| `Dka_Tools_Pkg.put_log_message` | 383 |
| `Dka_Tools_Pkg.put_log_message` | 390 |
| `Dka_Tools_Pkg.put_log_message` | 391 |
| `Dka_Tools_Pkg.put_log_message` | 392 |
| `Dka_Tools_Pkg.put_log_message` | 401 |
| `Dka_Tools_Pkg.put_log_message` | 402 |
| `Dka_Tools_Pkg.put_log_message` | 403 |
| `Dka_Tools_Pkg.put_log_message` | 404 |
| `Dka_Tools_Pkg.put_log_message` | 405 |
| `Dka_Tools_Pkg.put_log_message` | 406 |
| `Dka_Tools_Pkg.put_log_message` | 461 |
| `Dka_Tools_Pkg.put_log_message` | 462 |
| `Dka_Tools_Pkg.put_log_message` | 463 |
| `Dka_Tools_Pkg.put_log_message` | 464 |
| `Dka_Tools_Pkg.put_log_message` | 465 |
| `Dka_Tools_Pkg.put_log_message` | 478 |
| `Dka_Tools_Pkg.put_log_message` | 479 |
| `Dka_Tools_Pkg.put_log_message` | 482 |
| `Dka_Tools_Pkg.put_log_message` | 518 |
| `Dka_Tools_Pkg.put_log_message` | 520 |
| `Wf_Engine_Util.Start_Process_Internal` | 522 |
| `Dka_Tools_Pkg.put_log_message` | 530 |
| `Dka_Tools_Pkg.put_log_message` | 531 |
| `Dka_Tools_Pkg.put_log_message` | 532 |
| `Dka_Tools_Pkg.put_log_message` | 541 |
| `Dka_Tools_Pkg.put_log_message` | 542 |
| `Dka_Tools_Pkg.put_log_message` | 543 |
| `Dka_Tools_Pkg.put_log_message` | 544 |
| `Dka_Tools_Pkg.put_log_message` | 545 |
| `Dka_Tools_Pkg.put_log_message` | 546 |
| `Dka_Tools_Pkg.put_log_message` | 604 |
| `Dka_Tools_Pkg.put_log_message` | 605 |
| `Dka_Tools_Pkg.put_log_message` | 606 |
| `Dka_Tools_Pkg.put_log_message` | 607 |
| `Dka_Tools_Pkg.put_log_message` | 608 |
| `Dka_Tools_Pkg.put_log_message` | 620 |
| `Dka_Tools_Pkg.put_log_message` | 621 |
| `Dka_Tools_Pkg.put_log_message` | 624 |
| `Dka_Tools_Pkg.put_log_message` | 634 |
| `Dka_Tools_Pkg.put_log_message` | 644 |
| `Dka_Tools_Pkg.put_log_message` | 645 |
| `Dka_Tools_Pkg.put_log_message` | 646 |
| `Dka_Tools_Pkg.put_log_message` | 652 |
| `Dka_Tools_Pkg.put_log_message` | 653 |
| `Dka_Tools_Pkg.put_log_message` | 654 |
| `Dka_Tools_Pkg.put_log_message` | 655 |
| `Dka_Tools_Pkg.put_log_message` | 656 |
| `Dka_Tools_Pkg.put_log_message` | 662 |
| `Dka_Tools_Pkg.put_log_message` | 673 |
| `Dka_Tools_Pkg.put_log_message` | 674 |
| `Dka_Tools_Pkg.put_log_message` | 675 |
| `Dka_Tools_Pkg.put_log_message` | 725 |
| `DKA_SEND_MAIL_PKG.mail_test` | 735 |
| `Dka_Tools_Pkg.put_log_message` | 736 |
| `Dka_Tools_Pkg.put_log_message` | 742 |
| `Dka_Tools_Pkg.get_message` | 775 |
| `Dka_Tools_Pkg.get_message` | 786 |
| `Dka_Tools_Pkg.put_log_message` | 815 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 189, 269, 388 |
| rollback | 277, 396, 536, 668 |
| when_others | 59, 89, 167, 192, 219, 249, 275, 367, 394, 475, 508, 534, 617, 643, 666, 721, 739, 811 |
| suppression | 187 |
| workflow | 374, 377 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPORECYL_DA_SYSTEM_SAVED / DKA | `DKA_SPORETRT_DA_ANOS_PKG.DA_Statut_System_Saved` | dka/12.0.0/admin/import/DKA_SPORECYL_DA_SYSTEM_SAVED.prt:517 |
| DKA_SPORETRT_DA_INCOMPLT / DKA | `DKA_SPORETRT_DA_ANOS_PKG.DA_Statut_Incomplet` | dka/12.0.0/admin/import/DKA_SPORETRT_DA_INCOMPLT.prt:417 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
