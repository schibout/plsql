# DKA_SSATIPOIDSMAIL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SSATIPOIDSMAIL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SSATIPOIDSMAIL_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 529 ; encodage : cp1252 (repli). SHA-256 : `0241e90b4692496857348d54712863a781a82dcd644c5951114ccc2026012294`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 40 |
| `output_end` | 69 |
| `SEND_MSG` | 90 |
| `main` | 281 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_flex_values_tl` | 115 |
| `fnd_concurrent_requests` | 134 |
| `fnd_concurrent_requests` | 311 |
| `fnd_flex_values_tl` | 320 |
| `fnd_flex_values_tl` | 335 |
| `fnd_flex_values_tl` | 353 |
| `fnd_concurrent_requests` | 371 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 43 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 44 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 46 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 49 |
| `fnd_file.put_line` | 50 |
| `Fnd_File.put_line` | 73 |
| `Fnd_File.put_line` | 74 |
| `Fnd_File.put_line` | 77 |
| `fnd_file.put_line` | 146 |
| `fnd_file.put_line` | 161 |
| `fnd_file.put_line` | 176 |
| `fnd_file.put_line` | 181 |
| `fnd_file.put_line` | 216 |
| `fnd_file.put_line` | 382 |
| `fnd_request.add_layout` | 385 |
| `fnd_request.submit_request` | 392 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 402 |
| `Fnd_File.put_line` | 427 |
| `fnd_file.put_line` | 433 |
| `Dka_Tools_Pkg.get_parameter` | 436 |
| `fnd_file.put_line` | 446 |
| `fnd_file.put_line` | 452 |
| `fnd_file.put_line` | 459 |
| `fnd_file.put_line` | 470 |
| `fnd_file.put_line` | 477 |
| `fnd_file.put_line` | 482 |
| `fnd_file.put_line` | 500 |
| `Fnd_File.put_line` | 511 |
| `Fnd_File.put_line` | 518 |
| `Fnd_File.put_line` | 522 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 399 |
| when_others | 130, 240, 367 |
| soumission | 392 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SSATIPOIDSMAIL / DKA | `DKA_SSATIPOIDSMAIL_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SSATIPOIDSMAIL.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
