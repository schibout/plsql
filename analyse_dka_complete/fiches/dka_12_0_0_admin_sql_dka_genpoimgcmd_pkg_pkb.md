# DKA_GENPOIMGCMD_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_GENPOIMGCMD_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_GENPOIMGCMD_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 436 ; encodage : cp1252 (repli). SHA-256 : `c15203a96eadf5fbb23dc141185e0c11d1b4928af875ee2922f069e8f0299027`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 45 |
| `main` | 153 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_headers_all` | 186 |
| `fnd_attached_documents` | 192 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.get` | 76 |
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
| `Fnd_File.put_line` | 248 |
| `Fnd_File.put_line` | 249 |
| `Fnd_File.put_line` | 253 |
| `Fnd_File.put_line` | 254 |
| `Fnd_File.put_line` | 255 |
| `Fnd_File.put_line` | 256 |
| `Fnd_File.put_line` | 258 |
| `Fnd_File.put_line` | 259 |
| `Fnd_File.put_line` | 260 |
| `Dka_Tools_Pkg.put_outdebug_message` | 274 |
| `fnd_submit.set_request_set` | 275 |
| `fnd_submit.set_org_id` | 280 |
| `Dka_Tools_Pkg.put_outdebug_message` | 286 |
| `fnd_submit.submit_program` | 288 |
| `fnd_submit.set_org_id` | 318 |
| `Dka_Tools_Pkg.put_outdebug_message` | 321 |
| `fnd_submit.submit_program` | 322 |
| `Dka_Tools_Pkg.put_outdebug_message` | 328 |
| `fnd_submit.submit_set` | 329 |
| `Dka_Tools_Pkg.put_outdebug_message` | 334 |
| `Dka_Tools_Pkg.put_outdebug_message` | 337 |
| `Dka_Tools_Pkg.put_outdebug_message` | 341 |
| `Dka_Tools_Pkg.put_outdebug_message` | 346 |
| `Dka_Tools_Pkg.put_outdebug_message` | 352 |
| `Fnd_File.put_line` | 357 |
| `Fnd_Concurrent.wait_for_request` | 359 |
| `Fnd_file.put_line` | 368 |
| `Fnd_File.put_line` | 373 |
| `Fnd_File.put_line` | 374 |
| `Fnd_File.put_line` | 377 |
| `Fnd_File.put_line` | 378 |
| `fnd_file.put_line` | 385 |
| `Fnd_File.put_line` | 389 |
| `Fnd_File.put_line` | 393 |
| `Fnd_File.put_line` | 395 |
| `Fnd_File.put_line` | 400 |
| `Fnd_File.put_line` | 401 |
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
| `Fnd_File.put_line` | 418 |
| `Fnd_File.put_line` | 419 |
| `Fnd_File.put_line` | 420 |
| `Fnd_File.put_line` | 421 |
| `Fnd_File.put_line` | 422 |
| `Fnd_File.put_line` | 423 |
| `Fnd_File.put_line` | 424 |
| `Fnd_File.put_line` | 425 |
| `Fnd_File.put_line` | 426 |
| `Fnd_File.put_line` | 427 |
| `Fnd_File.put_line` | 428 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 330 |
| rollback | 412, 429 |
| when_others | 82, 414 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_GENPOIMGCMD / DKA | `DKA_GENPOIMGCMD_PKG.main` | dka/12.0.0/admin/import/DKA_GENPOIMGCMD.prt:961 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
