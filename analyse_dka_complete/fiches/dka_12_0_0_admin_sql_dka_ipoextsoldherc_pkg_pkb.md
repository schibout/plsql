# DKA_IPOEXTSOLDHERC_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IPOEXTSOLDHERC_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IPOEXTSOLDHERC_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1037 ; encodage : cp1252 (repli). SHA-256 : `b320d66e6243f19bde5f55a46b6b7cd34f29c5b0a3ff296dd320eaf98e39ad87`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `p_put_debug_message` | 57 |
| `p_validate` | 74 |
| `p_check_directory` | 98 |
| `p_extract_data` | 137 |
| `p_extract_data` | 513 |
| `p_extract_data_type_p3` | 526 |
| `p_extract_data_type_p6` | 631 |
| `p_extract_data_type_p6` | 644 |
| `p_extract_data_type_p6` | 750 |
| `output_header` | 762 |
| `PURGE_TABLE` | 804 |
| `main` | 818 |
| `bilan` | 890 |
| `compression_fichier_sortie` | 937 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `all_directories` | 102 |
| `pa_projects_all` | 158 |
| `PER_SECURITY_ORGANIZATIONS` | 168 |
| `PER_SECURITY_PROFILES` | 174 |
| `gl_periods` | 185 |
| `gl_periods` | 207 |
| `gl_periods` | 215 |
| `pa_cust_event_rdl_all` | 230 |
| `FND_FLEX_VALUES_VL` | 255 |
| `FND_FLEX_VALUE_SETS` | 263 |
| `DKA_IPOEXTSOLDHERC` | 278 |
| `pa_cust_event_rdl_all` | 305 |
| `FND_FLEX_VALUES_VL` | 330 |
| `FND_FLEX_VALUE_SETS` | 338 |
| `DKA_IPOEXTSOLDHERC` | 353 |
| `pa_cost_distribution_lines_all` | 381 |
| `FND_FLEX_VALUES_VL` | 398 |
| `FND_FLEX_VALUE_SETS` | 406 |
| `DKA_IPOEXTSOLDHERC` | 421 |
| `pa_cost_distribution_lines_all` | 449 |
| `FND_FLEX_VALUES_VL` | 466 |
| `FND_FLEX_VALUE_SETS` | 474 |
| `DKA_IPOEXTSOLDHERC` | 489 |
| `DKA_IPOEXTSOLDHERC` | 552 |
| `DKA_IPOEXTSOLDHERC` | 670 |
| `fnd_concurrent_programs` | 774 |
| `DKA_IPOEXTSOLDHERC` | 806 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 61 |
| `FND_PROFILE.VALUE` | 293 |
| `FND_PROFILE.VALUE` | 295 |
| `FND_PROFILE.VALUE` | 368 |
| `FND_PROFILE.VALUE` | 370 |
| `FND_PROFILE.VALUE` | 436 |
| `FND_PROFILE.VALUE` | 438 |
| `FND_PROFILE.VALUE` | 504 |
| `FND_PROFILE.VALUE` | 506 |
| `Fnd_File.put_line` | 786 |
| `Fnd_File.put_line` | 787 |
| `Fnd_File.put_line` | 789 |
| `Fnd_File.put_line` | 791 |
| `Fnd_File.put_line` | 794 |
| `Fnd_File.put_line` | 845 |
| `Fnd_File.put_line` | 854 |
| `Fnd_File.put_line` | 863 |
| `Fnd_File.put_line` | 867 |
| `Fnd_File.put_line` | 898 |
| `Fnd_File.put_line` | 900 |
| `Fnd_File.put_line` | 903 |
| `Fnd_File.put_line` | 905 |
| `Fnd_File.put_line` | 908 |
| `Fnd_File.put_line` | 910 |
| `Fnd_File.put_line` | 912 |
| `Fnd_File.put_line` | 914 |
| `Fnd_File.put_line` | 919 |
| `Fnd_File.put_line` | 923 |
| `Fnd_File.put_line` | 927 |
| `Fnd_File.put_line` | 931 |
| `FND_REQUEST.SUBMIT_REQUEST` | 952 |
| `Fnd_File.put_line` | 981 |
| `Fnd_File.put_line` | 985 |
| `Fnd_File.put_line` | 989 |
| `Fnd_File.put_line` | 992 |
| `fnd_concurrent.wait_for_request` | 994 |
| `Fnd_File.put_line` | 1001 |
| `Fnd_File.put_line` | 1006 |
| `Fnd_File.put_line` | 1011 |
| `Fnd_File.put_line` | 1013 |
| `Fnd_File.put_line` | 1016 |
| `Fnd_File.put_line` | 1017 |
| `Fnd_File.put_line` | 1023 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_COMPRESS_FICH_HERC` | 952 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 807, 844, 978 |
| when_others | 512, 630, 749, 781, 880, 1021 |
| suppression | 806 |
| soumission | 952 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_EXTRSOLD_HERC / DKA | `DKA_IPOEXTSOLDHERC_PKG.main` | dka/12.0.0/admin/import/DKA_EXTRSOLD_HERC_PRG.ldt:434 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
