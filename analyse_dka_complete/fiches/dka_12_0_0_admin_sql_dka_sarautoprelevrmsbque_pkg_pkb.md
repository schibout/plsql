# DKA_SARAUTOPRELEVRMSBQUE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARAUTOPRELEVRMSBQUE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARAUTOPRELEVRMSBQUE_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 459 ; encodage : cp1252 (repli). SHA-256 : `8cb556ccf709b43d7fc987231ee1cbe38e3f23b2059139ffe3db6fc1b8f90cde`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 40 |
| `output_end` | 69 |
| `SEND_MSG` | 90 |
| `main` | 254 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 287 |
| `fnd_flex_value_sets` | 296 |

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
| `fnd_file.put_line` | 119 |
| `fnd_file.put_line` | 134 |
| `fnd_file.put_line` | 149 |
| `fnd_file.put_line` | 154 |
| `fnd_file.put_line` | 189 |
| `fnd_file.put_line` | 312 |
| `fnd_request.add_layout` | 315 |
| `fnd_request.submit_request` | 322 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 338 |
| `Fnd_File.put_line` | 363 |
| `fnd_file.put_line` | 369 |
| `Dka_Tools_Pkg.get_parameter` | 372 |
| `fnd_file.put_line` | 382 |
| `fnd_file.put_line` | 388 |
| `fnd_file.put_line` | 395 |
| `fnd_file.put_line` | 406 |
| `fnd_file.put_line` | 413 |
| `fnd_file.put_line` | 430 |
| `Fnd_File.put_line` | 441 |
| `Fnd_File.put_line` | 448 |
| `Fnd_File.put_line` | 452 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 335 |
| when_others | 213 |
| soumission | 322 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
