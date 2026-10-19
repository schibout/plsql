# DKA_SARENCAIS_MAIL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARENCAIS_MAIL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARENCAIS_MAIL_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 729 ; encodage : cp1252 (repli). SHA-256 : `dd9d01aab3d68bf82c114f9e6ec301f6f68e1f5933a95bee078b57f23b308806`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Attente_Fin_Trait_Sarencais` | 53 |
| `init` | 152 |
| `write_boundary` | 246 |
| `begin_attachment` | 264 |
| `end_attachment` | 306 |
| `envoi_mail` | 329 |
| `ENVOI_MAIL` | 440 |
| `file_zip_affact` | 459 |
| `main` | 545 |
| `main` | 607 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 81 |
| `v$database` | 172 |
| `fnd_concurrent_programs` | 478 |
| `fnd_flex_value_sets` | 550 |
| `all_directories` | 603 |
| `FND_CONCURRENT_PROGRAMS_TL` | 621 |
| `FND_CONCURRENT_PROGRAMS_TL` | 636 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.Put_Debug_Message` | 69 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 76 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 90 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 94 |
| `Fnd_Concurrent.Wait_For_Request` | 96 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 106 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 109 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 113 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 118 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 128 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 131 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 138 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 139 |
| `dka_tools_pkg.put_debug_message` | 157 |
| `Dka_Tools_Pkg.put_debug_message` | 180 |
| `Dka_Tools_Pkg.get_parameter` | 188 |
| `Dka_Tools_Pkg.put_debug_message` | 196 |
| `Dka_Tools_Pkg.get_parameter` | 203 |
| `Dka_Tools_Pkg.put_debug_message` | 210 |
| `Dka_Tools_Pkg.get_parameter` | 217 |
| `Dka_Tools_Pkg.put_debug_message` | 224 |
| `dka_tools_pkg.put_debug_message` | 231 |
| `Dka_Tools_Pkg.get_message` | 349 |
| `Dka_Tools_Pkg.get_message` | 351 |
| `dka_tools_pkg.put_log_message` | 368 |
| `Dka_Tools_Pkg.put_outdebug_message` | 430 |
| `Dka_Tools_Pkg.put_outdebug_message` | 433 |
| `Dka_Tools_Pkg.put_outdebug_message` | 442 |
| `fnd_request.submit_request` | 488 |
| `fnd_concurrent.wait_for_request` | 508 |
| `DKA_TOOLS_PKG.PUT_LOG_MESSAGE` | 609 |
| `DKA_TOOLS_PKG.PUT_LOG_MESSAGE` | 610 |
| `dka_tools_pkg.put_log_message` | 653 |
| `dka_tools_pkg.put_log_message` | 676 |
| `Dka_Tools_Pkg.put_outdebug_message` | 690 |
| `Dka_Tools_Pkg.put_outdebug_message` | 691 |
| `Dka_Tools_Pkg.put_outdebug_message` | 693 |
| `Dka_Tools_Pkg.put_outdebug_message` | 695 |
| `Dka_Tools_Pkg.put_outdebug_message` | 705 |
| `Dka_Tools_Pkg.put_outdebug_message` | 706 |
| `DKA_TOOLS_PKG.PUT_LOG_MESSAGE` | 709 |
| `dka_tools_pkg.put_log_message` | 715 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 499 |
| when_others | 84, 134, 174, 233, 367, 439, 482, 532, 606, 649, 675, 720 |
| soumission | 488 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARENCAIS_MAIL / DKA | `DKA_SARENCAIS_MAIL_PKG.main` | dka/12.0.0/admin/import/DKA_SARENCAIS_MAIL_F.prt:419 |
| DKA_SARENCAIS_MAIL / DKA | `DKA_SARENCAIS_MAIL_PKG.main` | dka/12.0.0/admin/import/DKA_SARENCAIS_MAIL_F.prt:419 |
| DKA_SARENCAIS_MAIL / DKA | `DKA_SARENCAIS_MAIL_PKG.main` | dka/12.0.0/admin/import/DKA_SARENCAIS_MAIL_US.prt:419 |
| DKA_SARENCAIS_MAIL / DKA | `DKA_SARENCAIS_MAIL_PKG.main` | dka/12.0.0/admin/import/DKA_SARENCAIS_MAIL_US.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
