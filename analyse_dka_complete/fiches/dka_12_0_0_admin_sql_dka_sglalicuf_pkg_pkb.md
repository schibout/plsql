# DKA_SGLALICUF_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SGLALICUF_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SGLALICUF_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 503 ; encodage : utf-8. SHA-256 : `b4cc2da7a7f18b9f9e8ceb0ab3beb1586abfabf021f7c353f29832509edc3383`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `MAIN` | 28 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `GL_JE_headers` | 56 |
| `DKA_STRANSCO_LINES` | 60 |
| `DKA_STRANSCO_HEADERS` | 62 |
| `GL_JE_headers` | 77 |
| `DKA_STRANSCO_LINES` | 81 |
| `DKA_STRANSCO_HEADERS` | 83 |
| `FA.fa_asset_invoices` | 129 |
| `FA.fa_asset_invoices` | 145 |
| `PA.pa_projects_all` | 172 |
| `pa_tasks` | 185 |
| `Gl_Je_Lines` | 201 |
| `pa_tasks` | 229 |
| `pa.pa_tasks` | 231 |
| `pa_tasks` | 233 |
| `pa_tasks` | 247 |
| `pa.pa_tasks` | 249 |
| `pa_tasks` | 251 |
| `Gl_Je_Lines` | 267 |
| `FA.fa_asset_invoices` | 301 |
| `FA.fa_asset_invoices` | 317 |
| `PA.pa_projects_all` | 344 |
| `pa_tasks` | 357 |
| `Gl_Je_Lines` | 373 |
| `pa_tasks` | 401 |
| `pa.pa_tasks` | 403 |
| `pa_tasks` | 405 |
| `pa_tasks` | 419 |
| `pa.pa_tasks` | 421 |
| `pa_tasks` | 423 |
| `Gl_Je_Lines` | 439 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_Log.String` | 97 |
| `fnd_flex_ext.breakup_segments` | 102 |
| `Fnd_Log.String` | 107 |
| `Fnd_Log.String` | 116 |
| `fnd_file.put_line` | 163 |
| `fnd_file.put_line` | 179 |
| `fnd_file.put_line` | 192 |
| `Fnd_Log.String` | 196 |
| `Fnd_Log.String` | 213 |
| `Fnd_Log.String` | 219 |
| `fnd_file.put_line` | 241 |
| `fnd_file.put_line` | 258 |
| `Fnd_Log.String` | 262 |
| `Fnd_Log.String` | 279 |
| `Fnd_Log.String` | 285 |
| `fnd_file.put_line` | 335 |
| `fnd_file.put_line` | 351 |
| `fnd_file.put_line` | 364 |
| `Fnd_Log.String` | 368 |
| `Fnd_Log.String` | 385 |
| `Fnd_Log.String` | 391 |
| `fnd_file.put_line` | 413 |
| `fnd_file.put_line` | 430 |
| `Fnd_Log.String` | 434 |
| `Fnd_Log.String` | 451 |
| `Fnd_Log.String` | 457 |
| `Fnd_Log.String` | 471 |
| `Fnd_Log.String` | 479 |
| `Fnd_Log.String` | 488 |
| `fnd_file.put_line` | 494 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 161, 177, 190, 239, 256, 333, 349, 362, 411, 428, 485 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
