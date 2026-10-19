# DKA_SFAACCPB_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SFAACCPB_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SFAACCPB_PKG.pkb).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 435 ; encodage : cp1252 (repli). SHA-256 : `32e0ea76834e7bedf59a4ec4ba4256f6a0b0544d5a7f661b617464039e2a8827`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 36 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_ledgers` | 103 |
| `fa_book_controls` | 110 |
| `fnd_concurrent_programs` | 137 |
| `fnd_responsibility` | 144 |
| `XLA_LOOKUPS` | 169 |
| `XLA_LOOKUPS` | 177 |
| `XLA_LOOKUPS` | 185 |
| `XLA_LOOKUPS` | 193 |
| `XLA_LOOKUPS` | 201 |
| `XLA_LOOKUPS` | 209 |
| `XLA_LOOKUPS` | 217 |
| `XLA_LOOKUPS` | 225 |
| `XLA_LOOKUPS` | 233 |
| `XLA_LOOKUPS` | 239 |
| `DUAL` | 245 |
| `XLA_LOOKUPS` | 250 |
| `xla_lookups` | 256 |
| `fnd_application_tl` | 262 |
| `fnd_application_tl` | 268 |
| `XLA_LOOKUPS` | 274 |
| `XLA_LOOKUPS` | 280 |
| `XLA_LOOKUPS` | 286 |
| `XLA_LOOKUPS` | 292 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 120 |
| `dka_tools_pkg.put_debug_message` | 128 |
| `fnd_global.apps_initialize` | 148 |
| `dka_tools_pkg.put_debug_message` | 151 |
| `dka_tools_pkg.put_debug_message` | 157 |
| `dka_tools_pkg.put_debug_message` | 165 |
| `fnd_profile.value` | 263 |
| `fnd_profile.value` | 269 |
| `fnd_profile.value` | 298 |
| `fnd_profile.value` | 299 |
| `dka_tools_pkg.put_debug_message` | 328 |
| `fnd_request.submit_request` | 332 |
| `dka_tools_pkg.put_debug_message` | 382 |
| `dka_tools_pkg.put_debug_message` | 392 |
| `fnd_concurrent.wait_for_request` | 404 |
| `dka_tools_pkg.put_outdebug_message` | 412 |
| `dka_tools_pkg.put_debug_message` | 416 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 399 |
| when_others | 427 |
| soumission | 332 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SFAACCPB / DKA | `DKA_SFAACCPB_PKG.main` | dka/12.0.0/admin/import/DKA_SFAACCPB.prt:483 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
