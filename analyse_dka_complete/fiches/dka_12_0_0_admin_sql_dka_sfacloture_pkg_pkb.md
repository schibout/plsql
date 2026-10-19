# DKA_SFACLOTURE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SFACLOTURE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SFACLOTURE_PKG.pkb).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 688 ; encodage : cp1252 (repli). SHA-256 : `cbb530c06ca90a1dd2e7efb685cbb2f5b71ad00b5a964a83f31dea127b140f3d`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 51 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fa_book_controls` | 143 |
| `dka_sfacloture_trace` | 259 |
| `fa_deprn_periods` | 297 |
| `fa_book_controls` | 341 |
| `fa_deprn_summary` | 367 |
| `gl_sets_of_books` | 408 |
| `fa_book_controls` | 492 |
| `fa_book_controls` | 574 |
| `fa_book_controls` | 605 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 162 |
| `dka_tools_pkg.put_log_message` | 163 |
| `dka_tools_pkg.put_log_message` | 164 |
| `Dka_Tools_Pkg.put_log_message` | 172 |
| `Dka_Tools_Pkg.put_log_message` | 189 |
| `Dka_Tools_Pkg.put_log_message` | 191 |
| `Dka_Tools_Pkg.put_log_message` | 309 |
| `Dka_Tools_Pkg.put_log_message` | 311 |
| `Dka_Tools_Pkg.put_log_message` | 312 |
| `Fnd_Profile.VALUE` | 330 |
| `Dka_Tools_Pkg.put_debug_message` | 344 |
| `Fnd_Concurrent.get_request_status` | 348 |
| `Fnd_Profile.put` | 413 |
| `Dka_Tools_Pkg.put_log_message` | 417 |
| `Dka_Tools_Pkg.put_log_message` | 418 |
| `Fnd_Request.submit_request` | 422 |
| `Dka_Tools_Pkg.put_log_message` | 434 |
| `Fnd_Request.submit_request` | 438 |
| `Fnd_Profile.VALUE` | 450 |
| `Dka_Tools_Pkg.put_log_message` | 462 |
| `Dka_Tools_Pkg.put_log_message` | 463 |
| `Fnd_Request.submit_request` | 464 |
| `Dka_Tools_Pkg.put_log_message` | 476 |
| `Fnd_Request.submit_request` | 477 |
| `Dka_Tools_Pkg.put_log_message` | 546 |
| `Fnd_Request.submit_request` | 547 |
| `Fnd_Message.set_name` | 558 |
| `Fnd_Message.set_token` | 559 |
| `Fnd_Message.set_token` | 560 |
| `Fnd_Message.set_token` | 561 |
| `Fnd_Message.set_token` | 564 |
| `Fnd_Message.set_token` | 567 |
| `Dka_Tools_Pkg.put_log_message` | 573 |
| `Dka_Tools_Pkg.put_log_message` | 578 |
| `Dka_Tools_Pkg.put_log_message` | 600 |
| `Fnd_Request.submit_request` | 612 |
| `Dka_Tools_Pkg.put_log_message` | 629 |
| `Fnd_Concurrent.wait_for_request` | 654 |
| `Dka_Tools_Pkg.put_log_message` | 662 |
| `Dka_Tools_Pkg.put_log_message` | 667 |
| `Dka_Tools_Pkg.put_log_message` | 671 |
| `Dka_Tools_Pkg.put_log_message` | 682 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `FAGDA` | 422 |
| `FARET` | 438 |
| `FADEPR` | 464 |
| `FADEPR` | 477 |
| `FAPPT` | 547 |
| `FAMCP` | 612 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 577, 643 |
| when_others | 588, 632, 680 |
| soumission | 422, 438, 464, 477, 547, 612 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SFACLOTURE / DKA | `DKA_SFACLOTURE_pkg.main` | dka/12.0.0/admin/import/DKA_SFACLOTURE.prt:609 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
