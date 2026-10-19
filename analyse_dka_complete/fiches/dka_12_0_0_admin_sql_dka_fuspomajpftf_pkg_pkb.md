# DKA_FUSPOMAJPFTF_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_FUSPOMAJPFTF_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_FUSPOMAJPFTF_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 982 ; encodage : cp1252 (repli). SHA-256 : `1e3aa61f519e160ad1bba6432a2a8e7c58e7471e330a5960be7bb9a46dc7a7fe`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 33 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_requisition_headers_all` | 56 |
| `HR_ORGANIZATION_UNITS` | 70 |
| `HR_ORGANIZATION_UNITS` | 82 |
| `PO_HEADERS_ALL` | 117 |
| `HR_ORGANIZATION_UNITS` | 131 |
| `HR_ORGANIZATION_UNITS` | 143 |
| `hr_organization_units` | 303 |
| `HR_ORGANIZATION_UNITS` | 313 |
| `hr_organization_units` | 410 |
| `fnd_responsibility` | 418 |
| `pa_tasks` | 437 |
| `gl_sets_of_books` | 460 |
| `po_req_distributions_all` | 605 |
| `hr_organization_units` | 717 |
| `fnd_responsibility` | 725 |
| `pa_tasks` | 743 |
| `gl_sets_of_books` | 768 |
| `PO_DISTRIBUTIONS_ALL` | 916 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 307 |
| `Fnd_File.put_line` | 336 |
| `Fnd_File.put_line` | 351 |
| `Fnd_File.put_line` | 352 |
| `Fnd_File.put_line` | 353 |
| `Fnd_File.put_line` | 354 |
| `Fnd_File.put_line` | 355 |
| `Fnd_File.put_line` | 389 |
| `Fnd_File.put_line` | 423 |
| `Fnd_File.put_line` | 424 |
| `Fnd_File.put_line` | 428 |
| `Fnd_File.put_line` | 446 |
| `Fnd_File.put_line` | 447 |
| `fnd_global.APPS_INITIALIZE` | 453 |
| `Fnd_File.put_line` | 457 |
| `Fnd_File.put_line` | 465 |
| `Fnd_File.put_line` | 466 |
| `Fnd_File.put_line` | 467 |
| `po_wf_build_account_init.start_workflow` | 475 |
| `Fnd_File.put_line` | 589 |
| `Fnd_File.put_line` | 590 |
| `Fnd_File.put_line` | 591 |
| `Fnd_File.put_line` | 592 |
| `Fnd_File.put_line` | 593 |
| `Fnd_File.put_line` | 594 |
| `Fnd_File.put_line` | 597 |
| `Fnd_File.put_line` | 598 |
| `Fnd_File.put_line` | 599 |
| `Fnd_File.put_line` | 616 |
| `Fnd_File.put_line` | 619 |
| `Fnd_File.put_line` | 628 |
| `Fnd_File.put_line` | 634 |
| `Fnd_File.put_line` | 643 |
| `Fnd_File.put_line` | 644 |
| `Fnd_File.put_line` | 645 |
| `Fnd_File.put_line` | 646 |
| `Fnd_File.put_line` | 647 |
| `Fnd_File.put_line` | 648 |
| `Fnd_File.put_line` | 649 |
| `Fnd_File.put_line` | 650 |
| `Fnd_File.put_line` | 651 |
| `Fnd_File.put_line` | 652 |
| `Fnd_File.put_line` | 653 |
| `Fnd_File.put_line` | 658 |
| `Fnd_File.put_line` | 659 |
| `Fnd_File.put_line` | 660 |
| `Fnd_File.put_line` | 661 |
| `Fnd_File.put_line` | 662 |
| `Fnd_File.put_line` | 695 |
| `Fnd_File.put_line` | 730 |
| `Fnd_File.put_line` | 731 |
| `Fnd_File.put_line` | 734 |
| `Fnd_File.put_line` | 753 |
| `Fnd_File.put_line` | 754 |
| `fnd_global.APPS_INITIALIZE` | 761 |
| `Fnd_File.put_line` | 765 |
| `Fnd_File.put_line` | 773 |
| `Fnd_File.put_line` | 774 |
| `po_wf_build_account_init.start_workflow` | 782 |
| `Fnd_File.put_line` | 897 |
| `Fnd_File.put_line` | 899 |
| `Fnd_File.put_line` | 900 |
| `Fnd_File.put_line` | 901 |
| `Fnd_File.put_line` | 902 |
| `Fnd_File.put_line` | 903 |
| `Fnd_File.put_line` | 905 |
| `Fnd_File.put_line` | 906 |
| `Fnd_File.put_line` | 907 |
| `Fnd_File.put_line` | 930 |
| `Fnd_File.put_line` | 931 |
| `Fnd_File.put_line` | 935 |
| `Fnd_File.put_line` | 942 |
| `Fnd_File.put_line` | 948 |
| `Fnd_File.put_line` | 957 |
| `Fnd_File.put_line` | 958 |
| `Fnd_File.put_line` | 959 |
| `Fnd_File.put_line` | 960 |
| `Fnd_File.put_line` | 961 |
| `Fnd_File.put_line` | 962 |
| `Fnd_File.put_line` | 963 |
| `Fnd_File.put_line` | 964 |
| `Fnd_File.put_line` | 967 |
| `Fnd_File.put_line` | 968 |
| `Fnd_File.put_line` | 972 |
| `Fnd_File.put_line` | 973 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 306, 328, 421, 444, 463, 728, 751, 771, 971 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKAFUSPOMAJPFTF / DKA | `DKA_FUSPOMAJPFTF_PKG.Main` | dka/12.0.0/admin/import/DKA_FUSPOMAJPFTF.prt:458 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
