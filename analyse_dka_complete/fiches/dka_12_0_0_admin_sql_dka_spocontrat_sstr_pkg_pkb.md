# DKA_SPOCONTRAT_SSTR_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOCONTRAT_SSTR_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOCONTRAT_SSTR_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1487 ; encodage : cp1252 (repli). SHA-256 : `324b6458ff20774793396f285e3f42cd92c9deaa3f35c7b357c414ceec29faf9`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_varchar2_parameter` | 57 |
| `get_number_parameter` | 92 |
| `check_vendor` | 126 |
| `check_vendor_site` | 162 |
| `check_lieu_livraison` | 198 |
| `check_lieu_facturation` | 233 |
| `check_projet` | 270 |
| `check_expenditure_type` | 350 |
| `check_gestionnaire` | 395 |
| `Check_nature_prestation` | 449 |
| `get_affich_imput` | 504 |
| `get_invoices_count` | 566 |
| `check_montant_facture` | 611 |
| `check_montant_imput_facture` | 738 |
| `get_first_revnum_ctr_annuel` | 881 |
| `get_last_revnum_ctr_annuel` | 916 |
| `get_ccid` | 965 |
| `get_contrat_end_date` | 1305 |
| `get_contrat_start_date` | 1347 |
| `get_numcommande` | 1398 |
| `get_info_region` | 1416 |
| `get_info_org` | 1469 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_vendors` | 139 |
| `po_vendor_sites_all` | 175 |
| `hr_locations` | 211 |
| `hr_locations` | 246 |
| `pa_projects_all` | 289 |
| `pa_projects_all` | 314 |
| `pa_expenditure_types` | 365 |
| `per_people_f` | 408 |
| `ak_web_user_sec_attr_values` | 422 |
| `dka_contrat_sstr` | 526 |
| `po_headers_archive_all` | 531 |
| `po_distributions_all` | 586 |
| `po_headers_archive_all` | 635 |
| `po_distributions_all` | 700 |
| `po_headers_archive_all` | 769 |
| `dka_contrat_sstr_imput_archi` | 774 |
| `po_distributions_all` | 852 |
| `po_headers_archive_all` | 895 |
| `po_headers_archive_all` | 931 |
| `gl_sets_of_books` | 1116 |
| `mtl_categories_kfv` | 1127 |
| `po_line_types_all_v` | 1133 |
| `pa_projects_all` | 1139 |
| `per_people_f` | 1147 |
| `po_headers_archive_all` | 1368 |
| `dka_contrat_sstr_archi` | 1370 |
| `dual` | 1402 |
| `AK_WEB_USER_SEC_ATTR_VALUES` | 1428 |
| `hr_operating_units` | 1440 |
| `po_headers_all` | 1476 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_TOOLS_PKG.GET_PARAMETER` | 68 |
| `DKA_TOOLS_PKG.GET_PARAMETER` | 103 |
| `fnd_flex_val_api.get_table_vset_select` | 466 |
| `po_wf_build_account_init.start_workflow` | 1157 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 714, 867, 1288, 1328, 1383, 1405, 1444 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
