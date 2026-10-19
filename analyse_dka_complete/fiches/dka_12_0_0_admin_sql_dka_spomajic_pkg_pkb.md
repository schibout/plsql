# DKA_SPOMAJIC_PKG.PKB

Source : [dka/12.0.0/admin/sql/DKA_SPOMAJIC_PKG.PKB](../../dka/12.0.0/admin/sql/DKA_SPOMAJIC_PKG.PKB).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 842 ; encodage : cp1252 (repli). SHA-256 : `1770d65a33a35bd8a35121e889786574fe9e07270a40f127aa03be40864ebc23`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 36 |
| `main` | 90 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_programs` | 51 |
| `PO.PO_DISTRIBUTIONS_ALL` | 352 |
| `hr_organization_units` | 424 |
| `PO.PO_DISTRIBUTIONS_ALL` | 427 |
| `fnd_responsibility` | 437 |
| `pa_tasks` | 452 |
| `pa_tasks` | 467 |
| `hr_organization_units` | 492 |
| `PA_EXPENDITURE_TYPES` | 507 |
| `gl_sets_of_books` | 519 |
| `FND_NEW_MESSAGES` | 660 |
| `PO_DISTRIBUTIONS_ALL` | 752 |
| `gl_code_combinations` | 768 |
| `gl_code_combinations` | 773 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 66 |
| `Fnd_File.put_line` | 67 |
| `Fnd_File.put_line` | 68 |
| `Fnd_File.put_line` | 69 |
| `Fnd_File.put_line` | 70 |
| `fnd_file.put_line` | 372 |
| `Fnd_File.put_line` | 378 |
| `Fnd_File.put_line` | 444 |
| `Fnd_File.put_line` | 445 |
| `Fnd_File.put_line` | 448 |
| `Fnd_File.put_line` | 477 |
| `Fnd_File.put_line` | 478 |
| `Fnd_File.put_line` | 484 |
| `Fnd_File.put_line` | 485 |
| `Fnd_File.put_line` | 497 |
| `Fnd_File.put_line` | 498 |
| `fnd_global.APPS_INITIALIZE` | 512 |
| `Fnd_File.put_line` | 516 |
| `Fnd_File.put_line` | 524 |
| `Fnd_File.put_line` | 525 |
| `Fnd_File.put_line` | 526 |
| `po_wf_build_account_init.start_workflow` | 533 |
| `Fnd_File.put_line` | 657 |
| `Fnd_File.put_line` | 673 |
| `Fnd_File.put_line` | 674 |
| `Fnd_File.put_line` | 675 |
| `Fnd_File.put_line` | 676 |
| `Fnd_File.put_line` | 677 |
| `Fnd_File.put_line` | 678 |
| `Fnd_File.put_line` | 681 |
| `Fnd_File.put_line` | 682 |
| `Fnd_File.put_line` | 683 |
| `Fnd_File.put_line` | 684 |
| `fnd_file.put_line` | 778 |
| `fnd_file.put_line` | 779 |
| `fnd_file.put_line` | 780 |
| `fnd_file.put_line` | 781 |
| `fnd_file.put_line` | 782 |
| `fnd_file.put_line` | 783 |
| `Fnd_File.put_line` | 787 |
| `Fnd_File.put_line` | 791 |
| `Fnd_File.put_line` | 798 |
| `Fnd_File.put_line` | 804 |
| `Fnd_File.put_line` | 819 |
| `Fnd_File.put_line` | 820 |
| `Fnd_File.put_line` | 821 |
| `Fnd_File.put_line` | 822 |
| `Fnd_File.put_line` | 828 |
| `Fnd_File.put_line` | 829 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 59, 371, 440, 475, 495, 522, 663, 824 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOMAJIC / DKA | `DKA_SPOMAJIC_PKG.main` | dka/12.0.0/admin/import/DKA_SPOMAJIC.prt:565 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
