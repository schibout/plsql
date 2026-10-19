# DKA_SPOCMDMAIL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOCMDMAIL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOCMDMAIL_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 662 ; encodage : cp1252 (repli). SHA-256 : `c764ce2154396d416620ec36dc92098fbb0709efeb5889f8bb5b04f1fd998861`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 34 |
| `output_end` | 63 |
| `p_put_debug_message` | 80 |
| `p_validate` | 96 |
| `p_check_directory` | 120 |
| `p_extract_data` | 158 |
| `p_extract_data` | 319 |
| `SEND_MSG` | 334 |
| `main` | 493 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `all_directories` | 124 |
| `PO_HEADERS_ALL` | 184 |
| `fnd_concurrent_requests` | 524 |
| `fnd_flex_values_tl` | 533 |
| `fnd_flex_values_tl` | 548 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 37 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 38 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 39 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 40 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 43 |
| `fnd_file.put_line` | 44 |
| `Fnd_File.put_line` | 67 |
| `Fnd_File.put_line` | 68 |
| `Fnd_File.put_line` | 71 |
| `fnd_file.put_line` | 229 |
| `fnd_file.put_line` | 241 |
| `fnd_file.put_line` | 298 |
| `fnd_file.put_line` | 307 |
| `fnd_file.put_line` | 360 |
| `fnd_file.put_line` | 375 |
| `fnd_file.put_line` | 390 |
| `fnd_file.put_line` | 395 |
| `fnd_file.put_line` | 430 |
| `fnd_file.put_line` | 568 |
| `fnd_file.put_line` | 576 |
| `Dka_Tools_Pkg.get_parameter` | 579 |
| `fnd_file.put_line` | 595 |
| `fnd_file.put_line` | 607 |
| `fnd_file.put_line` | 612 |
| `fnd_file.put_line` | 617 |
| `fnd_file.put_line` | 631 |
| `Fnd_File.put_line` | 641 |
| `Fnd_File.put_line` | 649 |
| `Fnd_File.put_line` | 651 |
| `Fnd_File.put_line` | 655 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 317, 452 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOCMD / DKA | `DKA_SPOCMDMAIL_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCMDMAIL.prt:421 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
