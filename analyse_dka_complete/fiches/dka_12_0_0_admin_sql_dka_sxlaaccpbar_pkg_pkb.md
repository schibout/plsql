# DKA_SXLAACCPBAR_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SXLAACCPBAR_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SXLAACCPBAR_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 471 ; encodage : cp1252 (repli). SHA-256 : `996449453fded6b8fe3cfe2fdb784ce5bb8a240e2f4734437184cd8e7a7bb022`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 38 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_access_set_assignments` | 115 |
| `xla_events` | 120 |
| `xla.xla_transaction_entities` | 121 |
| `fnd_concurrent_programs` | 171 |
| `fnd_responsibility` | 178 |
| `XLA_LOOKUPS` | 204 |
| `XLA_LOOKUPS` | 211 |
| `XLA_LOOKUPS` | 218 |
| `XLA_LOOKUPS` | 225 |
| `XLA_LOOKUPS` | 232 |
| `XLA_LOOKUPS` | 239 |
| `XLA_LOOKUPS` | 246 |
| `XLA_LOOKUPS` | 253 |
| `XLA_LOOKUPS` | 259 |
| `XLA_LOOKUPS` | 261 |
| `DUAL` | 263 |
| `XLA_LOOKUPS` | 265 |
| `xla_lookups` | 267 |
| `fnd_application_tl` | 269 |
| `fnd_application_tl` | 271 |
| `XLA_LOOKUPS` | 274 |
| `XLA_LOOKUPS` | 277 |
| `XLA_LOOKUPS` | 279 |
| `XLA_LOOKUPS` | 281 |
| `gl_period_statuses` | 316 |
| `gl_period_statuses` | 320 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_Profile.VALUE` | 116 |
| `Dka_Tools_Pkg.get_parameter` | 137 |
| `dka_tools_pkg.put_debug_message` | 144 |
| `dka_tools_pkg.put_debug_message` | 145 |
| `dka_tools_pkg.put_debug_message` | 162 |
| `fnd_global.apps_initialize` | 182 |
| `dka_tools_pkg.put_debug_message` | 185 |
| `dka_tools_pkg.put_debug_message` | 198 |
| `fnd_profile.value` | 269 |
| `fnd_profile.value` | 271 |
| `fnd_profile.value` | 285 |
| `fnd_profile.value` | 286 |
| `dka_tools_pkg.put_debug_message` | 349 |
| `FND_REQUEST.add_layout` | 352 |
| `fnd_request.submit_request` | 360 |
| `dka_tools_pkg.put_debug_message` | 414 |
| `dka_tools_pkg.put_debug_message` | 424 |
| `fnd_concurrent.wait_for_request` | 438 |
| `dka_tools_pkg.put_outdebug_message` | 446 |
| `dka_tools_pkg.put_debug_message` | 450 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 431 |
| when_others | 461 |
| soumission | 360 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SXLAACCPBAR / DKA | `DKA_SXLAACCPBAR_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SXLAACCPBAR.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
