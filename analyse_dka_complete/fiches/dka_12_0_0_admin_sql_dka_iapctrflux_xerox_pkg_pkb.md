# DKA_IAPCTRFLUX_XEROX_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IAPCTRFLUX_XEROX_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IAPCTRFLUX_XEROX_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 566 ; encodage : cp1252 (repli). SHA-256 : `348ba8cebe0ee401ad371220a0033125df8721e39bdc2989e38d8f62ed638fd8`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `format_date` | 51 |
| `main` | 64 |
| `insert_dka_iapctrflux_xerox` | 473 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_organisation_v` | 92 |
| `dka_iapfacxgs_interface` | 98 |
| `DKA_STRANSCO_LINES` | 117 |
| `AP_INVOICES_INTERFACE` | 124 |
| `AP_INVOICES_ALL` | 134 |
| `dka_iapctrflux_xerox` | 170 |
| `dka_stransco_lines` | 173 |
| `DKA_IAPFACXGS_INTERFACE` | 202 |
| `dka_stransco_lines` | 207 |
| `DKA_STRANSCO_LINES` | 227 |
| `AP_INVOICES_INTERFACE` | 233 |
| `dka_stransco_lines` | 237 |
| `AP_INVOICES_ALL` | 249 |
| `dka_stransco_lines` | 253 |
| `DKA_IAPCTRFLUX_XEROX` | 297 |
| `DKA_STRANSCO_LINES` | 300 |
| `DKA_IAPFACXGS_INTERFACE` | 329 |
| `dka_iapctrflux_xerox_tmp` | 489 |
| `dka.dka_iapctrflux_xerox` | 497 |
| `dka_parameters` | 505 |
| `dka.dka_iapctrflux_xerox` | 517 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_Tools_Pkg.add_error_stack` | 57 |
| `dka_Tools_Pkg.put_outdebug_message` | 156 |
| `fnd_message.get_string` | 157 |
| `dka_Tools_Pkg.put_outdebug_message` | 159 |
| `dka_Tools_Pkg.put_outdebug_message` | 162 |
| `dka_Tools_Pkg.put_outdebug_message` | 190 |
| `fnd_message.get_string` | 191 |
| `dka_Tools_Pkg.put_outdebug_message` | 194 |
| `fnd_message.get_string` | 195 |
| `dka_Tools_Pkg.put_outdebug_message` | 217 |
| `fnd_message.get_string` | 218 |
| `dka_Tools_Pkg.put_outdebug_message` | 271 |
| `fnd_message.get_string` | 272 |
| `dka_Tools_Pkg.put_outdebug_message` | 276 |
| `fnd_message.get_string` | 277 |
| `dka_Tools_Pkg.put_outdebug_message` | 281 |
| `dka_Tools_Pkg.put_outdebug_message` | 289 |
| `fnd_message.get_string` | 290 |
| `dka_Tools_Pkg.put_outdebug_message` | 315 |
| `fnd_message.get_string` | 316 |
| `dka_Tools_Pkg.put_outdebug_message` | 320 |
| `fnd_message.get_string` | 321 |
| `dka_Tools_Pkg.put_outdebug_message` | 339 |
| `fnd_message.get_string` | 340 |
| `dka_Tools_Pkg.put_outdebug_message` | 344 |
| `fnd_message.get_string` | 345 |
| `fnd_message.get_string` | 347 |
| `fnd_message.get_string` | 349 |
| `dka_Tools_Pkg.put_outdebug_message` | 361 |
| `dka_Tools_Pkg.put_outdebug_message` | 377 |
| `fnd_message.get_string` | 378 |
| `dka_Tools_Pkg.put_outdebug_message` | 413 |
| `dka_Tools_Pkg.put_outdebug_message` | 418 |
| `fnd_message.get_string` | 419 |
| `dka_Tools_Pkg.put_outdebug_message` | 428 |
| `fnd_message.get_string` | 429 |
| `dka_Tools_Pkg.put_outdebug_message` | 438 |
| `fnd_message.get_string` | 439 |
| `dka_Tools_Pkg.put_log_message` | 455 |
| `dka_Tools_Pkg.put_log_message` | 459 |
| `dka_Tools_Pkg.print_error_stack` | 460 |
| `dka_Tools_Pkg.add_error_stack` | 463 |
| `dka_Tools_Pkg.put_log_message` | 465 |
| `dka_Tools_Pkg.print_error_stack` | 466 |
| `dka_Tools_Pkg.put_log_message` | 555 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 557 |
| when_others | 56, 461, 553 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IAPCTRFLUX_XEROX / DKA | `DKA_IAPCTRFLUX_XEROX_PKG.main` | dka/12.0.0/admin/import/DKA_IAPCTRFLUX_XEROX.prt:419 |
| DKA_INSERT_CDF_XEROX / DKA | `DKA_IAPCTRFLUX_XEROX_PKG.insert_dka_iapctrflux_xerox` | dka/12.0.0/admin/import/DKA_INSERT_CDF_XEROX.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
