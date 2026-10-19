# DKA_SARRGLTPRLV_AUTO_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARRGLTPRLV_AUTO_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARRGLTPRLV_AUTO_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1063 ; encodage : cp1252 (repli). SHA-256 : `9eb0a15485e8ed2cf985d7d3946625cd9b70ed6db4f46725f343e1be6c92307e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `wait_rvctp` | 57 |
| `MAIN1` | 135 |
| `MAIN2` | 220 |
| `MAIN3` | 305 |
| `init` | 389 |
| `INIT` | 429 |
| `out_msg` | 444 |
| `log_msg` | 460 |
| `write_boundary` | 479 |
| `begin_attachment` | 495 |
| `end_attachment` | 537 |
| `get_nom_etat` | 556 |
| `GET_NOM_ETAT` | 582 |
| `envoi_avec_fichier` | 596 |
| `edition_output_mail` | 882 |
| `EDITION_OUTPUT_MAIL` | 976 |
| `ENVOI_MAIL` | 993 |
| `EDITION_OUTPUT_MAIL` | 1040 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `v$database` | 410 |
| `fnd_concurrent_requests` | 564 |
| `fnd_concurrent_requests` | 626 |
| `fnd_flex_value_sets` | 634 |
| `all_directories` | 777 |
| `fnd_flex_values_vl` | 896 |
| `v$database` | 919 |
| `fnd_application` | 924 |
| `fnd_conc_req_summary_v` | 930 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent.wait_for_request` | 71 |
| `Fnd_File.put_line` | 81 |
| `FND_FILE.PUT_LINE` | 86 |
| `Fnd_File.put_line` | 87 |
| `FND_FILE.PUT_LINE` | 92 |
| `Fnd_File.put_line` | 93 |
| `FND_FILE.PUT_LINE` | 99 |
| `Fnd_File.put_line` | 100 |
| `FND_FILE.PUT_LINE` | 106 |
| `Fnd_File.put_line` | 107 |
| `FND_FILE.PUT_LINE` | 111 |
| `Fnd_File.put_line` | 112 |
| `FND_FILE.PUT_LINE` | 152 |
| `Fnd_File.put_line` | 153 |
| `fnd_request.add_layout` | 156 |
| `FND_REQUEST.submit_request` | 165 |
| `Fnd_File.put_line` | 177 |
| `FND_FILE.PUT_LINE` | 184 |
| `FND_REQUEST.submit_request` | 185 |
| `Fnd_File.put_line` | 196 |
| `FND_FILE.PUT_LINE` | 200 |
| `Fnd_File.put_line` | 204 |
| `Fnd_File.put_line` | 205 |
| `FND_FILE.PUT_LINE` | 237 |
| `Fnd_File.put_line` | 238 |
| `fnd_request.add_layout` | 241 |
| `FND_REQUEST.submit_request` | 250 |
| `Fnd_File.put_line` | 262 |
| `FND_FILE.PUT_LINE` | 269 |
| `FND_REQUEST.submit_request` | 270 |
| `Fnd_File.put_line` | 281 |
| `FND_FILE.PUT_LINE` | 285 |
| `Fnd_File.put_line` | 290 |
| `Fnd_File.put_line` | 291 |
| `FND_FILE.PUT_LINE` | 322 |
| `Fnd_File.put_line` | 323 |
| `fnd_request.add_layout` | 326 |
| `FND_REQUEST.submit_request` | 335 |
| `Fnd_File.put_line` | 347 |
| `FND_FILE.PUT_LINE` | 354 |
| `FND_REQUEST.submit_request` | 355 |
| `Fnd_File.put_line` | 366 |
| `FND_FILE.PUT_LINE` | 370 |
| `Fnd_File.put_line` | 374 |
| `Fnd_File.put_line` | 375 |
| `Dka_Tools_Pkg.get_parameter` | 399 |
| `Dka_Tools_Pkg.get_parameter` | 412 |
| `DKA_TOOLS_PKG.put_log_message` | 426 |
| `DKA_TOOLS_PKG.put_log_message` | 431 |
| `fnd_file.put_line` | 447 |
| `fnd_file.put_line` | 470 |
| `Dka_Tools_Pkg.get_message` | 657 |
| `Dka_Tools_Pkg.get_message` | 664 |
| `Dka_Tools_Pkg.get_message` | 753 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 857 |
| `fnd_profile.VALUE` | 925 |
| `fnd_profile.VALUE` | 943 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 176, 194, 261, 279, 346, 364 |
| when_others | 119, 203, 289, 373, 428, 580, 864, 934, 974, 1051 |
| soumission | 165, 177, 185, 196, 250, 262, 270, 281, 335, 347, 355, 366 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARRGLTPRLV_AUTO2 / DKA | `DKA_SARRGLTPRLV_AUTO_PKG.MAIN2` | dka/12.0.0/admin/import/DKA_SARRGLTPRLV_AUTO2_PRG.ldt:515 |
| DKA_SARRGLTPRLV_AUTO3 / DKA | `DKA_SARRGLTPRLV_AUTO_PKG.MAIN3` | dka/12.0.0/admin/import/DKA_SARRGLTPRLV_AUTO3_PRG.ldt:515 |
| DKA_SARRGLTPRLV_MAIL / DKA | `DKA_SARRGLTPRLV_AUTO_PKG.ENVOI_MAIL` | dka/12.0.0/admin/import/DKA_SARRGLTPRLV_AUTO_MAIL_PKG.prt:553 |
| DKA_SARRGLTPRLV_AUTO1 / DKA | `DKA_SARRGLTPRLV_AUTO_PKG.MAIN1` | dka/12.0.0/admin/import/DKA_SARRGLTPRLV_AUTO_PKG.prt:515 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
