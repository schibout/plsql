# DKA_IGLHYPERIONDR_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IGLHYPERIONDR_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IGLHYPERIONDR_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 899 ; encodage : cp1252 (repli). SHA-256 : `6f3010a789c11893764aadf976d3a2cbdec3add5f79c6ac764ea7423d8c23732`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `p_put_debug_message` | 50 |
| `p_validate` | 67 |
| `p_check_directory` | 91 |
| `f_get_DKCODE_region` | 126 |
| `f_get_UNITS_OF_MEASURE` | 148 |
| `f_get_us_periode_name` | 177 |
| `f_get_period_to_extract` | 204 |
| `p_extract_data` | 333 |
| `p_extract_data` | 399 |
| `p_extract_data` | 487 |
| `p_extract_data_qte` | 501 |
| `p_extract_data` | 565 |
| `p_extract_data_qte` | 664 |
| `p_bilan` | 679 |
| `p_bilan` | 685 |
| `main` | 730 |
| `main` | 744 |
| `main_qte` | 818 |
| `main_qte` | 832 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `all_directories` | 95 |
| `dka_stransco_headers` | 132 |
| `dka_stransco_headers` | 154 |
| `gl_periods` | 189 |
| `gl_periods` | 218 |
| `PER_SECURITY_PROFILES_V` | 221 |
| `DKA_PARAMETERS` | 246 |
| `DKA_PARAMETERS` | 259 |
| `gl_periods` | 289 |
| `gl_periods` | 295 |
| `gl_je_headers` | 354 |
| `fnd_flex_values` | 363 |
| `hr_organization_units` | 439 |
| `PA_EXPENDITURE_ITEMS_ALL` | 522 |
| `fnd_flex_values` | 528 |
| `hr_organization_units` | 605 |
| `gl_periods` | 777 |
| `gl_periods` | 865 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 54 |
| `fnd_profile.value` | 227 |
| `Dka_Tools_Pkg.get_parameter` | 238 |
| `Dka_Tools_Pkg.get_parameter` | 251 |
| `fnd_profile.value` | 387 |
| `fnd_profile.value` | 553 |
| `Fnd_File.put_line` | 688 |
| `Fnd_File.put_line` | 690 |
| `Fnd_File.put_line` | 693 |
| `Fnd_File.put_line` | 695 |
| `Fnd_File.put_line` | 697 |
| `Fnd_File.put_line` | 699 |
| `Fnd_File.put_line` | 701 |
| `Fnd_File.put_line` | 703 |
| `Fnd_File.put_line` | 705 |
| `Fnd_File.put_line` | 707 |
| `Fnd_File.put_line` | 711 |
| `Fnd_File.put_line` | 715 |
| `dka_tools_pkg.put_outdebug_message` | 785 |
| `dka_tools_pkg.put_outdebug_message` | 873 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 800, 888 |
| when_others | 316, 460, 485, 637, 662, 802, 890 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IHYPERION / DKA | `DKA_IGLHYPERIONDR_PKG.main` | dka/12.0.0/admin/import/DKA_IHYPERION_F.prt:494 |
| DKA_IHYPERION_QTE / DKA | `DKA_IGLHYPERIONDR_PKG.main_qte` | dka/12.0.0/admin/import/DKA_IHYPERION_QTE_F.prt:494 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
