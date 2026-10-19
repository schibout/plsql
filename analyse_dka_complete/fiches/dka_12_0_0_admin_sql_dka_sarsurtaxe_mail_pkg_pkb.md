# DKA_SARSURTAXE_MAIL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARSURTAXE_MAIL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARSURTAXE_MAIL_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 593 ; encodage : cp1252 (repli). SHA-256 : `3e57ffe9f0dd5d3802b9339611a97ab8ce3c270f253b063a62ab4ecd46bc088e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 45 |
| `write_boundary` | 133 |
| `begin_attachment` | 153 |
| `end_attachment` | 184 |
| `envoi_mail` | 209 |
| `ENVOI_MAIL` | 318 |
| `file_zip_affact` | 338 |
| `main` | 424 |
| `main` | 483 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `v$database` | 72 |
| `fnd_concurrent_programs` | 360 |
| `fnd_flex_value_sets` | 435 |
| `all_directories` | 479 |
| `FND_REQUEST_SET_PROGRAMS` | 499 |
| `FND_CONCURRENT_PROGRAMS_TL` | 523 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 53 |
| `fnd_profile.value` | 64 |
| `Dka_Tools_Pkg.put_debug_message` | 80 |
| `Dka_Tools_Pkg.get_parameter` | 86 |
| `Dka_Tools_Pkg.put_debug_message` | 90 |
| `Dka_Tools_Pkg.get_parameter` | 97 |
| `Dka_Tools_Pkg.put_debug_message` | 100 |
| `Dka_Tools_Pkg.get_parameter` | 107 |
| `Dka_Tools_Pkg.put_debug_message` | 110 |
| `dka_tools_pkg.put_debug_message` | 116 |
| `Dka_Tools_Pkg.get_message` | 231 |
| `Dka_Tools_Pkg.get_message` | 234 |
| `dka_tools_pkg.put_log_message` | 251 |
| `Dka_Tools_Pkg.put_outdebug_message` | 310 |
| `Dka_Tools_Pkg.put_outdebug_message` | 312 |
| `Dka_Tools_Pkg.put_outdebug_message` | 320 |
| `fnd_request.submit_request` | 370 |
| `fnd_concurrent.wait_for_request` | 392 |
| `DKA_TOOLS_PKG.PUT_LOG_MESSAGE` | 485 |
| `DKA_TOOLS_PKG.PUT_LOG_MESSAGE` | 486 |
| `dka_tools_pkg.put_log_message` | 539 |
| `dka_tools_pkg.put_log_message` | 540 |
| `dka_tools_pkg.put_log_message` | 555 |
| `Dka_Tools_Pkg.put_outdebug_message` | 564 |
| `Dka_Tools_Pkg.put_outdebug_message` | 565 |
| `Dka_Tools_Pkg.put_outdebug_message` | 566 |
| `Dka_Tools_Pkg.put_outdebug_message` | 567 |
| `Dka_Tools_Pkg.put_outdebug_message` | 571 |
| `Dka_Tools_Pkg.put_outdebug_message` | 572 |
| `DKA_TOOLS_PKG.PUT_LOG_MESSAGE` | 575 |
| `dka_tools_pkg.put_log_message` | 579 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 382 |
| when_others | 74, 118, 250, 317, 365, 410, 482, 536, 554, 583 |
| soumission | 370 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARSURTAXE_MAIL / DKA | `DKA_SARSURTAXE_MAIL_PKG.main` | dka/12.0.0/admin/import/DKA_SARSURTAXE_MAIL.prt:406 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
