# DKA_RGLEXPORT89_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_RGLEXPORT89_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_RGLEXPORT89_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 801 ; encodage : cp1252 (repli). SHA-256 : `97c8a8faf487af0ca722627fea81058ee3185a65b5b6cc8fab42ca33c864c0f1`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_time` | 80 |
| `translate_texte` | 93 |
| `get_parameters` | 153 |
| `init` | 194 |
| `display_ecr_gl` | 384 |
| `affichage_fichier_sortie` | 610 |
| `main` | 664 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `l_texte_transcode` | 115 |
| `fnd_flex_values_vl` | 208 |
| `xle_registrations` | 239 |
| `hr_operating_units` | 248 |
| `gl_ledgers` | 286 |
| `fnd_flex_value_sets` | 327 |
| `gl_je_lines` | 408 |
| `gl_balances` | 500 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 139 |
| `dka_tools_pkg.put_log_message` | 142 |
| `dka_tools_pkg.put_log_message` | 179 |
| `dka_tools_pkg.put_log_message` | 182 |
| `dka_tools_pkg.put_debug_message` | 317 |
| `dka_tools_pkg.put_debug_message` | 320 |
| `dka_tools_pkg.put_log_message` | 369 |
| `dka_tools_pkg.put_log_message` | 372 |
| `dka_tools_pkg.put_log_message` | 544 |
| `fnd_file.put_line` | 553 |
| `dka_tools_pkg.put_log_message` | 556 |
| `fnd_file.put_line` | 571 |
| `dka_tools_pkg.put_log_message` | 579 |
| `dka_tools_pkg.put_log_message` | 594 |
| `dka_tools_pkg.put_log_message` | 597 |
| `dka_tools_pkg.put_outdebug_message` | 620 |
| `dka_tools_pkg.put_outdebug_message` | 621 |
| `dka_tools_pkg.put_outdebug_message` | 623 |
| `dka_tools_pkg.put_outdebug_message` | 625 |
| `dka_tools_pkg.put_outdebug_message` | 627 |
| `dka_tools_pkg.put_outdebug_message` | 629 |
| `dka_tools_pkg.put_outdebug_message` | 632 |
| `dka_tools_pkg.put_outdebug_message` | 634 |
| `dka_tools_pkg.put_outdebug_message` | 635 |
| `dka_tools_pkg.put_outdebug_message` | 636 |
| `dka_tools_pkg.put_log_message` | 645 |
| `dka_tools_pkg.put_log_message` | 648 |
| `dka_tools_pkg.put_log_message` | 685 |
| `dka_tools_pkg.put_log_message` | 686 |
| `dka_tools_pkg.put_log_message` | 687 |
| `dka_tools_pkg.put_log_message` | 689 |
| `dka_tools_pkg.put_log_message` | 697 |
| `dka_tools_pkg.put_log_message` | 698 |
| `dka_tools_pkg.put_log_message` | 703 |
| `dka_tools_pkg.put_log_message` | 704 |
| `dka_tools_pkg.put_log_message` | 705 |
| `dka_tools_pkg.put_log_message` | 707 |
| `dka_tools_pkg.put_log_message` | 715 |
| `dka_tools_pkg.put_log_message` | 716 |
| `dka_tools_pkg.put_log_message` | 721 |
| `dka_tools_pkg.put_log_message` | 722 |
| `dka_tools_pkg.put_log_message` | 723 |
| `dka_tools_pkg.put_log_message` | 725 |
| `dka_tools_pkg.put_log_message` | 733 |
| `dka_tools_pkg.put_log_message` | 734 |
| `dka_tools_pkg.put_log_message` | 739 |
| `dka_tools_pkg.put_log_message` | 740 |
| `dka_tools_pkg.put_log_message` | 741 |
| `dka_tools_pkg.put_log_message` | 743 |
| `dka_tools_pkg.put_log_message` | 751 |
| `dka_tools_pkg.put_log_message` | 752 |
| `dka_tools_pkg.put_log_message` | 758 |
| `dka_tools_pkg.put_log_message` | 761 |
| `dka_tools_pkg.put_log_message` | 766 |
| `dka_tools_pkg.put_log_message` | 769 |
| `dka_tools_pkg.put_log_message` | 774 |
| `dka_tools_pkg.put_log_message` | 777 |
| `dka_tools_pkg.put_log_message` | 782 |
| `dka_tools_pkg.put_log_message` | 785 |
| `dka_tools_pkg.put_log_message` | 790 |
| `dka_tools_pkg.put_log_message` | 793 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 591 |
| when_others | 136, 176, 366, 590, 642, 787 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_RGLEXPORT89 / DKA | `DKA_RGLEXPORT89_PKG.main` | dka/12.0.0/admin/import/DKA_RGLEXPORT89.prt:508 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
