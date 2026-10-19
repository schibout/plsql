# DKA_SRBCTRLRB_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SRBCTRLRB_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SRBCTRLRB_PKG.pkb).

Famille proposée par convention de nommage : **Banques / trésorerie**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 648 ; encodage : cp1252 (repli). SHA-256 : `4c40fe4fff141be0a6210e5fb37a98c357374ec034002d7fef98ce5b1431ece4`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_time` | 50 |
| `get_parameters` | 64 |
| `SEND_MSG` | 102 |
| `CONTROL_BANK_STATEMENT` | 204 |
| `GET_PREV_WORKING_DAY` | 421 |
| `affichage_fichier_sortie` | 458 |
| `main` | 501 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `RB_BANK_ACCOUNTS_ALL` | 300 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 73 |
| `dka_tools_pkg.put_debug_message` | 76 |
| `fnd_date.canonical_to_date` | 78 |
| `dka_tools_pkg.put_debug_message` | 81 |
| `dka_tools_pkg.put_log_message` | 86 |
| `dka_tools_pkg.put_log_message` | 88 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 126 |
| `Dka_Tools_Pkg.get_parameter` | 127 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 133 |
| `Dka_Tools_Pkg.get_parameter` | 134 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 144 |
| `Fnd_Message.Set_Name` | 146 |
| `Fnd_Message.SET_TOKEN` | 147 |
| `Fnd_Message.Set_Name` | 150 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 153 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 157 |
| `Fnd_Message.Set_Name` | 159 |
| `Fnd_Message.SET_TOKEN` | 160 |
| `Fnd_Message.Set_Name` | 163 |
| `Fnd_Message.SET_TOKEN` | 164 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 167 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 171 |
| `DKA_SEND_MAIL_PKG.Send_Mail` | 172 |
| `dka_tools_pkg.put_log_message` | 189 |
| `dka_tools_pkg.put_log_message` | 191 |
| `dka_tools_pkg.put_debug_message` | 326 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 334 |
| `Fnd_File.put_line` | 356 |
| `Fnd_File.put_line` | 385 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 391 |
| `dka_tools_pkg.put_log_message` | 407 |
| `dka_tools_pkg.put_log_message` | 409 |
| `dka_tools_pkg.IS_BANK_HOLIDAY` | 428 |
| `dka_tools_pkg.put_log_message` | 432 |
| `dka_tools_pkg.put_log_message` | 435 |
| `dka_tools_pkg.put_log_message` | 443 |
| `dka_tools_pkg.put_log_message` | 445 |
| `dka_tools_pkg.put_debug_message` | 466 |
| `dka_tools_pkg.put_debug_message` | 469 |
| `dka_tools_pkg.put_debug_message` | 473 |
| `dka_tools_pkg.put_outdebug_message` | 475 |
| `dka_tools_pkg.put_outdebug_message` | 476 |
| `dka_tools_pkg.put_debug_message` | 479 |
| `dka_tools_pkg.put_log_message` | 484 |
| `dka_tools_pkg.put_log_message` | 486 |
| `dka_tools_pkg.put_log_message` | 521 |
| `dka_tools_pkg.put_log_message` | 522 |
| `dka_tools_pkg.put_log_message` | 523 |
| `dka_tools_pkg.put_log_message` | 524 |
| `dka_tools_pkg.put_log_message` | 535 |
| `dka_tools_pkg.put_log_message` | 536 |
| `dka_tools_pkg.put_log_message` | 541 |
| `dka_tools_pkg.put_log_message` | 542 |
| `dka_tools_pkg.put_log_message` | 543 |
| `dka_tools_pkg.put_log_message` | 544 |
| `dka_tools_pkg.put_log_message` | 551 |
| `dka_tools_pkg.put_log_message` | 552 |
| `dka_tools_pkg.put_log_message` | 557 |
| `dka_tools_pkg.put_log_message` | 558 |
| `dka_tools_pkg.put_log_message` | 559 |
| `dka_tools_pkg.put_log_message` | 560 |
| `dka_tools_pkg.put_log_message` | 567 |
| `dka_tools_pkg.put_log_message` | 568 |
| `dka_tools_pkg.put_log_message` | 574 |
| `dka_tools_pkg.put_log_message` | 575 |
| `dka_tools_pkg.put_log_message` | 576 |
| `dka_tools_pkg.put_log_message` | 577 |
| `dka_tools_pkg.put_log_message` | 584 |
| `dka_tools_pkg.put_log_message` | 585 |
| `dka_tools_pkg.put_log_message` | 590 |
| `dka_tools_pkg.put_log_message` | 591 |
| `dka_tools_pkg.put_log_message` | 592 |
| `dka_tools_pkg.put_log_message` | 593 |
| `dka_tools_pkg.put_log_message` | 600 |
| `dka_tools_pkg.put_log_message` | 601 |
| `dka_tools_pkg.put_log_message` | 608 |
| `dka_tools_pkg.put_log_message` | 610 |
| `dka_tools_pkg.put_log_message` | 614 |
| `dka_tools_pkg.put_log_message` | 616 |
| `dka_tools_pkg.put_log_message` | 620 |
| `dka_tools_pkg.put_log_message` | 622 |
| `dka_tools_pkg.put_log_message` | 626 |
| `dka_tools_pkg.put_log_message` | 628 |
| `dka_tools_pkg.put_log_message` | 632 |
| `dka_tools_pkg.put_log_message` | 634 |
| `dka_tools_pkg.put_log_message` | 639 |
| `dka_tools_pkg.put_log_message` | 641 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 84, 187, 400, 441, 482, 637 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SRBCTRLRB / DKA | `DKA_SRBCTRLRB_PKG.main` | dka/12.0.0/admin/import/DKA_SRBCTRLRB.prt:460 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
