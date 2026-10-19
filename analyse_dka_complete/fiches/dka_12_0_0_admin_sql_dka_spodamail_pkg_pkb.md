# DKA_SPODAMAIL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPODAMAIL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPODAMAIL_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 641 ; encodage : cp1252 (repli). SHA-256 : `d44342455038012471f2d4894954fda3f6851ab11e68c9e2a533afb08e7d6980`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 34 |
| `p_put_debug_message` | 54 |
| `p_validate` | 70 |
| `output_end` | 102 |
| `p_check_directory` | 120 |
| `p_extract_data` | 157 |
| `p_extract_data` | 312 |
| `SEND_MSG` | 327 |
| `main` | 486 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `all_directories` | 124 |
| `po_requisition_headers_all` | 183 |
| `fnd_flex_values_tl` | 517 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 37 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 38 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 39 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 40 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 43 |
| `fnd_file.put_line` | 44 |
| `Fnd_File.put_line` | 106 |
| `Fnd_File.put_line` | 107 |
| `Fnd_File.put_line` | 110 |
| `fnd_file.put_line` | 222 |
| `fnd_file.put_line` | 234 |
| `fnd_file.put_line` | 291 |
| `fnd_file.put_line` | 300 |
| `fnd_file.put_line` | 353 |
| `fnd_file.put_line` | 368 |
| `fnd_file.put_line` | 383 |
| `fnd_file.put_line` | 388 |
| `fnd_file.put_line` | 423 |
| `fnd_file.put_line` | 538 |
| `fnd_file.put_line` | 546 |
| `Dka_Tools_Pkg.get_parameter` | 549 |
| `fnd_file.put_line` | 565 |
| `fnd_file.put_line` | 578 |
| `fnd_file.put_line` | 583 |
| `fnd_file.put_line` | 589 |
| `fnd_file.put_line` | 594 |
| `fnd_file.put_line` | 608 |
| `Fnd_File.put_line` | 619 |
| `Fnd_File.put_line` | 628 |
| `Fnd_File.put_line` | 630 |
| `Fnd_File.put_line` | 634 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 310, 445 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPODA / DKA | `DKA_SPODAMAIL_PKG.main` | dka/12.0.0/admin/import/DKA_SPODAMAIL.prt:421 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
