# DKA_FUSPOGENIMG_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_FUSPOGENIMG_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_FUSPOGENIMG_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 439 ; encodage : cp1252 (repli). SHA-256 : `9216d519326027b10930078f677ba1533e4c83e56aaf1c42d96fc58f428fc0ef`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 39 |
| `main` | 147 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_headers_all` | 181 |
| `fnd_attached_documents` | 188 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.get` | 70 |
| `Fnd_File.put_line` | 223 |
| `Fnd_File.put_line` | 232 |
| `Fnd_File.put_line` | 233 |
| `Fnd_File.put_line` | 234 |
| `Fnd_File.put_line` | 235 |
| `Fnd_File.put_line` | 236 |
| `Fnd_File.put_line` | 238 |
| `Fnd_File.put_line` | 239 |
| `Fnd_File.put_line` | 240 |
| `Fnd_File.put_line` | 241 |
| `Fnd_File.put_line` | 242 |
| `Fnd_File.put_line` | 243 |
| `Fnd_File.put_line` | 246 |
| `Fnd_File.put_line` | 247 |
| `Fnd_File.put_line` | 249 |
| `Fnd_File.put_line` | 253 |
| `Fnd_File.put_line` | 254 |
| `Fnd_File.put_line` | 255 |
| `Fnd_File.put_line` | 256 |
| `Fnd_File.put_line` | 258 |
| `Fnd_File.put_line` | 259 |
| `Fnd_File.put_line` | 260 |
| `Dka_Tools_Pkg.put_outdebug_message` | 272 |
| `fnd_submit.set_request_set` | 273 |
| `fnd_submit.set_org_id` | 278 |
| `Dka_Tools_Pkg.put_outdebug_message` | 284 |
| `fnd_submit.submit_program` | 286 |
| `fnd_submit.set_org_id` | 316 |
| `Dka_Tools_Pkg.put_outdebug_message` | 319 |
| `fnd_submit.submit_program` | 320 |
| `Dka_Tools_Pkg.put_outdebug_message` | 326 |
| `fnd_submit.submit_set` | 327 |
| `Dka_Tools_Pkg.put_outdebug_message` | 332 |
| `Dka_Tools_Pkg.put_outdebug_message` | 335 |
| `Dka_Tools_Pkg.put_outdebug_message` | 339 |
| `Dka_Tools_Pkg.put_outdebug_message` | 344 |
| `Dka_Tools_Pkg.put_outdebug_message` | 350 |
| `Fnd_File.put_line` | 355 |
| `Fnd_Concurrent.wait_for_request` | 357 |
| `Fnd_file.put_line` | 366 |
| `Fnd_File.put_line` | 371 |
| `Fnd_File.put_line` | 372 |
| `Fnd_File.put_line` | 377 |
| `Fnd_File.put_line` | 378 |
| `fnd_file.put_line` | 385 |
| `Fnd_File.put_line` | 389 |
| `Fnd_File.put_line` | 394 |
| `Fnd_File.put_line` | 395 |
| `Fnd_File.put_line` | 397 |
| `Fnd_File.put_line` | 402 |
| `Fnd_File.put_line` | 403 |
| `Fnd_File.put_line` | 404 |
| `Fnd_File.put_line` | 405 |
| `Fnd_File.put_line` | 406 |
| `Fnd_File.put_line` | 407 |
| `Fnd_File.put_line` | 408 |
| `Fnd_File.put_line` | 409 |
| `Fnd_File.put_line` | 410 |
| `Fnd_File.put_line` | 411 |
| `Fnd_File.put_line` | 412 |
| `Fnd_File.put_line` | 413 |
| `Fnd_File.put_line` | 420 |
| `Fnd_File.put_line` | 421 |
| `Fnd_File.put_line` | 422 |
| `Fnd_File.put_line` | 423 |
| `Fnd_File.put_line` | 424 |
| `Fnd_File.put_line` | 425 |
| `Fnd_File.put_line` | 426 |
| `Fnd_File.put_line` | 427 |
| `Fnd_File.put_line` | 428 |
| `Fnd_File.put_line` | 429 |
| `Fnd_File.put_line` | 430 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 328 |
| rollback | 414, 431 |
| when_others | 76, 416 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_FUSPOGENIMG / DKA | `DKA_FUSPOGENIMG_PKG.Main` | dka/12.0.0/admin/import/DKA_FUSPOGENIMG.prt:417 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
