# DKA_SPOCLOTURE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOCLOTURE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOCLOTURE_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 425 ; encodage : cp1252 (repli). SHA-256 : `04c1bba7659a7620033b478463dc0c54eadfc0dd7e94bcfb103ee49335aa246d`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `period_to_close` | 44 |
| `period_to_open` | 99 |
| `open_next_period` | 155 |
| `cloture_livre` | 199 |
| `main` | 317 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_period_statuses` | 62 |
| `gl_period_statuses` | 67 |
| `gl_period_statuses` | 117 |
| `gl_period_statuses` | 119 |
| `gl_period_statuses` | 167 |
| `gl_access_set_assignments` | 333 |
| `fnd_responsibility` | 342 |
| `gl_period_statuses` | 353 |
| `gl_access_set_assignments` | 357 |
| `gl_period_statuses` | 364 |
| `gl_access_set_assignments` | 368 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 72 |
| `dka_tools_pkg.put_log_message` | 77 |
| `dka_tools_pkg.put_log_message` | 81 |
| `dka_tools_pkg.put_log_message` | 129 |
| `dka_tools_pkg.put_log_message` | 137 |
| `dka_tools_pkg.put_log_message` | 182 |
| `dka_tools_pkg.put_debug_message` | 224 |
| `dka_tools_pkg.put_debug_message` | 228 |
| `dka_po_tools_pkg.update_period_statuses` | 242 |
| `dka_tools_pkg.put_debug_message` | 248 |
| `dka_tools_pkg.put_debug_message` | 267 |
| `dka_tools_pkg.put_log_message` | 272 |
| `dka_tools_pkg.put_debug_message` | 291 |
| `dka_tools_pkg.put_debug_message` | 296 |
| `Fnd_Profile.VALUE` | 334 |
| `dka_tools_pkg.put_log_message` | 344 |
| `fnd_global.apps_initialize` | 347 |
| `Fnd_Profile.VALUE` | 358 |
| `Fnd_Profile.VALUE` | 369 |
| `dka_tools_pkg.put_log_message` | 382 |
| `dka_tools_pkg.put_log_message` | 392 |
| `dka_tools_pkg.put_log_message` | 400 |
| `dka_tools_pkg.put_log_message` | 401 |
| `dka_tools_pkg.put_log_message` | 405 |
| `dka_tools_pkg.put_log_message` | 406 |
| `dka_tools_pkg.put_log_message` | 407 |
| `dka_tools_pkg.put_log_message` | 408 |
| `dka_tools_pkg.put_log_message` | 409 |
| `dka_tools_pkg.put_log_message` | 410 |
| `dka_tools_pkg.put_log_message` | 411 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 175 |
| when_others | 79, 135, 180, 299, 416 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOCLOTURE / DKA | `DKA_SPOCLOTURE_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SPOCLOTURE.prt:417 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
