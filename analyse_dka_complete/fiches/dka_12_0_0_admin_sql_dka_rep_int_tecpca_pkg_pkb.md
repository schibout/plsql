# DKA_REP_INT_TECPCA_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REP_INT_TECPCA_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REP_INT_TECPCA_PKG.pkb).

Famille proposée par convention de nommage : **Fusion / reprise**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 526 ; encodage : cp1252 (repli). SHA-256 : `b4d0e964e72391bf1ae640d9c69e8055be0c9f54f3a10013e5ef78bb6b1c54d8`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `launch_loader` | 60 |
| `validate_data` | 198 |
| `import_data` | 302 |
| `generate_output` | 403 |
| `main` | 460 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka.dka_maj_indicateurs_tecpca` | 166 |
| `dka.dka_maj_indicateurs_tecpca` | 208 |
| `dka.dka_maj_indicateurs_tecpca` | 230 |
| `dka.dka_maj_indicateurs_tecpca` | 237 |
| `pa_projects_all` | 247 |
| `dka.dka_maj_indicateurs_tecpca` | 255 |
| `dka.dka_maj_indicateurs_tecpca` | 263 |
| `dka.dka_maj_indicateurs_tecpca` | 310 |
| `dka.dka_maj_indicateurs_tecpca` | 318 |
| `dka.dka_maj_indicateurs_tecpca` | 325 |
| `pa_tasks` | 348 |
| `dka.dka_maj_indicateurs_tecpca` | 352 |
| `dka.dka_maj_indicateurs_tecpca` | 361 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 71 |
| `fnd_file.put_line` | 74 |
| `fnd_file.put_line` | 78 |
| `fnd_file.put_line` | 79 |
| `fnd_file.put_line` | 80 |
| `fnd_request.set_print_options` | 85 |
| `fnd_request.submit_request` | 88 |
| `fnd_file.put_line` | 102 |
| `fnd_file.put_line` | 107 |
| `fnd_file.put_line` | 111 |
| `fnd_file.put_line` | 113 |
| `fnd_concurrent.wait_for_request` | 118 |
| `fnd_file.put_line` | 127 |
| `fnd_file.put_line` | 133 |
| `fnd_file.put_line` | 136 |
| `fnd_file.put_line` | 141 |
| `fnd_file.put_line` | 151 |
| `fnd_file.put_line` | 157 |
| `fnd_file.put_line` | 168 |
| `fnd_file.put_line` | 176 |
| `fnd_file.put_line` | 177 |
| `fnd_file.put_line` | 213 |
| `dka_rep_transco_pkg.get_transco` | 224 |
| `fnd_file.put_line` | 269 |
| `fnd_file.put_line` | 279 |
| `fnd_file.put_line` | 280 |
| `fnd_file.put_line` | 340 |
| `fnd_file.put_line` | 372 |
| `fnd_file.put_line` | 382 |
| `fnd_file.put_line` | 383 |
| `dka_tools_pkg.put_log_message` | 408 |
| `dka_tools_pkg.put_outdebug_message` | 416 |
| `dka_tools_pkg.put_outdebug_message` | 417 |
| `dka_tools_pkg.put_outdebug_message` | 418 |
| `dka_tools_pkg.put_outdebug_message` | 419 |
| `dka_tools_pkg.put_outdebug_message` | 422 |
| `dka_tools_pkg.put_outdebug_message` | 424 |
| `dka_tools_pkg.put_outdebug_message` | 427 |
| `dka_tools_pkg.put_outdebug_message` | 431 |
| `dka_tools_pkg.put_log_message` | 432 |
| `dka_tools_pkg.put_log_message` | 438 |
| `dka_tools_pkg.put_outdebug_message` | 439 |
| `fnd_file.put_line` | 484 |
| `fnd_file.put_line` | 492 |
| `fnd_file.put_line` | 513 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_LOADER_REPINTTECPCA` | 88 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 110, 266, 273, 370 |
| when_others | 173, 276, 358, 377, 435, 518 |
| soumission | 88 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPINTTECPCA / DKA | `DKA_REP_INT_TECPCA_PKG.Main` | dka/12.0.0/admin/import/DKA_REPINTTECPCA.prt:546 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
