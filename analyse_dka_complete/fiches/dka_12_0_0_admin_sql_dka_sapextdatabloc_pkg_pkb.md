# DKA_SAPEXTDATABLOC_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPEXTDATABLOC_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPEXTDATABLOC_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 587 ; encodage : cp1252 (repli). SHA-256 : `ce1e1cb2d46e85725084913ed042ca79bcdf9cf632dccf230a6fb5fe6b987a61`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 44 |
| `output_end` | 97 |
| `extraction_blocage` | 125 |
| `main` | 528 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_programs` | 59 |
| `apps.fnd_user` | 159 |
| `apps.per_people_f` | 167 |
| `AP_HOLDS_ALL` | 169 |
| `dka_sblocage` | 221 |
| `dka_parameters` | 259 |
| `dka_parameters` | 265 |
| `dka_sblocage` | 279 |
| `fnd_concurrent_requests` | 282 |
| `dka_sblocage` | 318 |
| `dba_directories` | 409 |
| `dka_parameters` | 493 |
| `dka_parameters` | 498 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 74 |
| `Fnd_File.put_line` | 75 |
| `Fnd_File.put_line` | 76 |
| `Fnd_File.put_line` | 77 |
| `Fnd_File.put_line` | 78 |
| `Fnd_File.put_line` | 104 |
| `Fnd_File.put_line` | 105 |
| `Fnd_File.put_line` | 106 |
| `dka_tools_pkg.put_debug_message` | 255 |
| `dka_tools_pkg.put_debug_message` | 277 |
| `dka_tools_pkg.put_debug_message` | 289 |
| `dka_tools_pkg.put_debug_message` | 302 |
| `dka_tools_pkg.put_debug_message` | 311 |
| `dka_tools_pkg.put_log_message` | 369 |
| `dka_tools_pkg.put_debug_message` | 382 |
| `dka_tools_pkg.put_debug_message` | 394 |
| `dka_tools_pkg.put_log_message` | 416 |
| `dka_tools_pkg.put_log_message` | 421 |
| `dka_tools_pkg.put_log_message` | 433 |
| `dka_tools_pkg.put_debug_message` | 453 |
| `dka_tools_pkg.put_debug_message` | 457 |
| `dka_tools_pkg.put_debug_message` | 491 |
| `dka_tools_pkg.put_debug_message` | 503 |
| `Fnd_File.put_line` | 551 |
| `Fnd_File.put_line` | 556 |
| `Fnd_File.put_line` | 557 |
| `Fnd_File.put_line` | 558 |
| `Fnd_File.put_line` | 568 |
| `Fnd_File.put_line` | 569 |
| `Fnd_File.put_line` | 570 |
| `Fnd_File.put_line` | 571 |
| `Fnd_File.put_line` | 576 |
| `Fnd_File.put_line` | 577 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 292, 372, 502 |
| when_others | 67, 269, 367, 455, 506, 572 |
| suppression | 279 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPEXTDATABLOC / DKA | `DKA_SAPEXTDATABLOC_PKG.main` | dka/12.0.0/admin/import/DKA_SAPEXTDATABLOC.prt:417 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
