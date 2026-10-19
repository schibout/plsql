# DKA_IEOGLETF01_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IEOGLETF01_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IEOGLETF01_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 409 ; encodage : cp1252 (repli). SHA-256 : `88337fc200eb8cecfac89e9064cd34b23119b8d9dc4ff6844b03ca0605404c15`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 65 |
| `extraction_altaven` | 236 |
| `extraction_altaven` | 244 |
| `main` | 318 |
| `main` | 331 |
| `main` | 396 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_ieogletf01_int` | 83 |
| `GL_LEDGERS` | 157 |
| `gl_ledger_relationships` | 173 |
| `gl_sets_of_books` | 192 |
| `dka_ieogletf01_int` | 245 |
| `gl_balances` | 260 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 77 |
| `dka_tools_pkg.get_flex_key_seg_value_set` | 129 |
| `dka_tools_pkg.put_log_message` | 137 |
| `dka_tools_pkg.put_log_message` | 138 |
| `dka_tools_pkg.put_log_message` | 139 |
| `dka_tools_pkg.put_log_message` | 140 |
| `dka_tools_pkg.put_log_message` | 141 |
| `dka_tools_pkg.put_outdebug_message` | 146 |
| `dka_tools_pkg.put_outdebug_message` | 166 |
| `dka_tools_pkg.put_outdebug_message` | 184 |
| `dka_tools_pkg.put_outdebug_message` | 199 |
| `dka_tools_pkg.put_log_message` | 202 |
| `dka_tools_pkg.put_log_message` | 203 |
| `dka_tools_pkg.put_log_message` | 204 |
| `dka_tools_pkg.put_log_message` | 205 |
| `dka_tools_pkg.put_log_message` | 206 |
| `dka_tools_pkg.put_log_message` | 207 |
| `dka_tools_pkg.put_log_message` | 208 |
| `dka_tools_pkg.put_log_message` | 210 |
| `dka_tools_pkg.put_outdebug_message` | 216 |
| `dka_tools_pkg.put_outdebug_message` | 221 |
| `dka_tools_pkg.put_log_message` | 244 |
| `dka_tools_pkg.put_outdebug_message` | 302 |
| `dka_tools_pkg.put_log_message` | 303 |
| `dka_tools_pkg.put_log_message` | 331 |
| `dka_tools_pkg.put_outdebug_message` | 332 |
| `dka_tools_pkg.put_outdebug_message` | 333 |
| `dka_tools_pkg.put_outdebug_message` | 334 |
| `dka_tools_pkg.put_outdebug_message` | 335 |
| `dka_tools_pkg.put_log_message` | 346 |
| `dka_ieogletf01_pkg.extraction_altaven` | 353 |
| `dka_tools_pkg.put_outdebug_message` | 361 |
| `dka_tools_pkg.put_outdebug_message` | 366 |
| `fnd_request.submit_request` | 367 |
| `dka_tools_pkg.put_outdebug_message` | 379 |
| `dka_tools_pkg.ins_prog_message` | 380 |
| `dka_tools_pkg.put_outdebug_message` | 394 |
| `dka_tools_pkg.put_log_message` | 396 |
| `dka_tools_pkg.put_outdebug_message` | 402 |
| `dka_tools_pkg.put_log_message` | 403 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_IEOGLETF01_2` | 367 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 392 |
| when_others | 217, 298, 398 |
| suppression | 83 |
| soumission | 367 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IALTAVEN_LEGALE / DKA | `DKA_IEOGLETF01_PKG.main` | dka/12.0.0/admin/import/DKA_IALTAVEN_LEGALE.prt:635 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
