# DKA_SPOODCAP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOODCAP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOODCAP_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 559 ; encodage : cp1252 (repli). SHA-256 : `904380b29063bc3bdd2fece7b5c9544e795f31887c24c9ae9f1413a755687283`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 52 |
| `update_gl` | 90 |
| `run_prog_standard` | 382 |
| `main` | 494 |
| `update_gl` | 521 |
| `run_prog_standard` | 533 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_je_batches` | 114 |
| `DUAL` | 145 |
| `DUAL` | 150 |
| `gl_period_statuses` | 155 |
| `gl_interface_control` | 166 |
| `gl_interface` | 190 |
| `gl_je_lines` | 256 |
| `gl_interface` | 267 |
| `gl_je_lines` | 333 |
| `gl_je_lines` | 344 |
| `fnd_responsibility` | 417 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_outdebug_message` | 76 |
| `Dka_Tools_Pkg.put_log_message` | 77 |
| `Dka_Tools_Pkg.put_log_message` | 140 |
| `Dka_Tools_Pkg.put_log_message` | 164 |
| `Dka_Tools_Pkg.put_log_message` | 182 |
| `Dka_Tools_Pkg.put_log_message` | 354 |
| `Dka_Tools_Pkg.put_outdebug_message` | 360 |
| `Dka_Tools_Pkg.put_debug_message` | 361 |
| `Dka_Tools_Pkg.put_log_message` | 401 |
| `fnd_global.apps_initialize` | 420 |
| `FND_PROFILE.VALUE` | 420 |
| `Dka_Tools_Pkg.put_log_message` | 422 |
| `Fnd_Request.submit_request` | 424 |
| `FND_PROFILE.value` | 431 |
| `Dka_Tools_Pkg.put_log_message` | 446 |
| `Dka_Tools_Pkg.put_log_message` | 449 |
| `Fnd_Concurrent.wait_for_request` | 452 |
| `Dka_Tools_Pkg.put_log_message` | 454 |
| `Dka_Tools_Pkg.put_log_message` | 460 |
| `Dka_Tools_Pkg.put_log_message` | 468 |
| `Dka_Tools_Pkg.put_log_message` | 472 |
| `Dka_Tools_Pkg.put_outdebug_message` | 479 |
| `Dka_Tools_Pkg.put_log_message` | 505 |
| `DKA_SPOODCAP_PKG.update_gl` | 513 |
| `Dka_Tools_Pkg.put_log_message` | 515 |
| `DKA_SPOODCAP_PKG.run_prog_standard` | 525 |
| `Dka_Tools_Pkg.put_log_message` | 527 |
| `Fnd_File.put_line` | 536 |
| `Fnd_File.put_line` | 537 |
| `Fnd_File.put_line` | 540 |
| `Fnd_File.put_line` | 542 |
| `Dka_Tools_Pkg.put_log_message` | 546 |
| `Dka_Tools_Pkg.put_outdebug_message` | 552 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `GLLEZL` | 424 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 352, 448, 461 |
| when_others | 73, 357, 475, 549 |
| soumission | 424 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOODCAPMS / DKA | `DKA_SPOODCAP_PKG.main` | dka/12.0.0/admin/import/DKA_SPOODCAPMS.prt:438 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
