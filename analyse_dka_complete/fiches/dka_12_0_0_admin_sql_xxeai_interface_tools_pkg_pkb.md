# XXEAI_INTERFACE_TOOLS_PKG.pkb

Source : [dka/12.0.0/admin/sql/XXEAI_INTERFACE_TOOLS_PKG.pkb](../../dka/12.0.0/admin/sql/XXEAI_INTERFACE_TOOLS_PKG.pkb).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2689 ; encodage : cp1252 (repli). SHA-256 : `e84ec57a000d8553b379941dce80532ea9adf8cb68d99eb082a98f3571166821`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `put_debug_message` | 112 |
| `validate` | 121 |
| `not_null` | 133 |
| `get_project` | 139 |
| `get_project` | 150 |
| `get_task` | 161 |
| `get_task` | 172 |
| `get_class_affaire` | 183 |
| `period_is_open` | 194 |
| `is_numeric` | 213 |
| `get_flex_value` | 223 |
| `get_task_number` | 234 |
| `check_segment_value` | 254 |
| `get_code_combination_id` | 306 |
| `is_currency` | 370 |
| `is_autoreverse` | 385 |
| `tax_code_exists` | 404 |
| `my_get_params_folio_ap` | 424 |
| `Get_Infos_Banque` | 446 |
| `Get_Params_FOLIO_GL` | 581 |
| `Get_Societe_Projet` | 648 |
| `Get_Type_Depense_Evenement` | 690 |
| `get_account_info` | 804 |
| `Get_Cle_Comptable_CUF` | 953 |
| `check_seg_value` | 1013 |
| `Get_Societe_Projet_Liste` | 1718 |
| `Get_Type_Depense_Evt_Liste` | 1764 |
| `Get_Cle_Comptable_CUF_Liste` | 1816 |
| `Get_Invoice_Id` | 1861 |
| `Get_Info_Invoice_Header` | 1926 |
| `Get_Params_FOLIO_AP` | 2122 |
| `Get_Info_Invoice_Line` | 2180 |
| `Get_Info_Invoice_Header_Liste` | 2360 |
| `Get_Info_Invoice_Line_Liste` | 2407 |
| `Get_Invoice_Id_Liste` | 2455 |
| `Get_type_num_ligne_mvt_AR` | 2501 |
| `Get_region_DKCODE` | 2581 |
| `Get_Infos_Banque_Interne` | 2617 |
| `Get_Infos_Rejets_Sepa` | 2655 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `APPS.FND_FLEX_VALUE_SETS` | 90 |
| `APPS.FND_FLEX_VALUES_VL` | 91 |
| `APPS.FND_FLEX_VALUES_DFV` | 92 |
| `APPS.PA_PROJECTS_ALL` | 142 |
| `APPS.PA_PROJECTS_ALL` | 153 |
| `APPS.PA_TASKS` | 164 |
| `APPS.PA_TASKS` | 175 |
| `PA.PA_PROJECT_CLASSES` | 186 |
| `GL.gl_period_statuses` | 199 |
| `APPS.PA_TASKS` | 240 |
| `hr_all_organization_units` | 243 |
| `APPS.GL_LEDGERS` | 262 |
| `APPS.FND_ID_FLEX_SEGMENTS` | 263 |
| `APPS.FND_FLEX_VALUE_SETS` | 264 |
| `APPS.FND_FLEX_VALUES` | 271 |
| `APPS.gl_ledgers` | 332 |
| `APPS.FND_CURRENCIES` | 375 |
| `GL.GL_AUTOREV_CRITERIA_SETS` | 392 |
| `APPS.ZX_RATES_B` | 411 |
| `APPS.CE_BANK_BRANCHES_V` | 470 |
| `IBY_EXT_BANK_ACCOUNTS` | 490 |
| `APPS.CE_BANK_BRANCHES_V` | 491 |
| `APPS.CE_BANK_ACCOUNTS` | 525 |
| `APPS.CE_BANK_BRANCHES_V` | 526 |
| `APPS.FND_FLEX_VALUE_SETS` | 603 |
| `APPS.FND_FLEX_VALUES` | 604 |
| `APPS.FND_FLEX_VALUES_DFV` | 605 |
| `APPS.GL_JE_CATEGORIES` | 606 |
| `APPS.GL_JE_SOURCES` | 607 |
| `APPS.FND_FLEX_VALUE_SETS` | 703 |
| `APPS.FND_FLEX_VALUES` | 704 |
| `APPS.FND_FLEX_VALUES_DFV` | 705 |
| `APPS.DKA_STRANSCO_HEADERS` | 718 |
| `APPS.DKA_STRANSCO_LINES` | 719 |
| `APPS.fnd_id_flex_structures_vl` | 839 |
| `APPS.fnd_id_flex_structures_vl` | 843 |
| `APPS.fnd_flex_values_vl` | 873 |
| `APPS.fa_categories_vl` | 893 |
| `APPS.fnd_flex_value_sets` | 915 |
| `PA.PA_EXPENDITURE_TYPES` | 993 |
| `PA.PA_EVENT_TYPES` | 1001 |
| `APPS.CE_BANK_ACCOUNTS` | 1100 |
| `APPS.fnd_flex_values_vl` | 1173 |
| `APPS.gl_je_categories` | 1211 |
| `fnd_flex_values_vl` | 1458 |
| `pa_projects_all` | 1533 |
| `pa_projects_all` | 1541 |
| `pa_projects_all` | 1583 |
| `APPS.AP_SUPPLIERS` | 1934 |
| `APPS.PO_VENDORS_DFV` | 1935 |
| `APPS.AP_SUPPLIERS` | 1943 |
| `APPS.PO_VENDORS_DFV` | 1944 |
| `APPS.AP_SUPPLIER_SITES_ALL` | 1954 |
| `DUAL` | 2048 |
| `APPS.HR_ALL_ORGANIZATION_UNITS` | 2053 |
| `APPS.CE_BANK_ACCOUNTS` | 2625 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_GL_TOOLS_PKG.get_legder_id` | 327 |
| `Fnd_Flex_Ext.get_combination_id` | 349 |
| `Fnd_Flex_Ext.get_message` | 360 |
| `dka_spaautoaccounting_pkg.societe_projet` | 662 |
| `dka_stransco_pkg.etl_get_value_f` | 784 |
| `dka_spaautoaccounting_pkg.societe_projet` | 1058 |
| `DKA_GL_TOOLS_PKG.get_legder_id` | 1071 |
| `dka_stransco_pkg.etl_get_value_f` | 1273 |
| `dka_spaautoaccounting_pkg.run_cpt_groupe_couts_f` | 1337 |
| `dka_spaautoaccounting_pkg.run_cpt_groupe_produit_f` | 1363 |
| `dka_spaautoaccounting_pkg.societe_projet` | 2234 |
| `dka_spaautoaccounting_pkg.uo_projet` | 2238 |
| `DKA_GL_TOOLS_PKG.get_legder_id` | 2245 |
| `dka_stransco_pkg.etl_get_value_f` | 2249 |
| `dka_stransco_pkg.etl_get_value_f` | 2590 |
| `Dka_Tools_Pkg.get_parameter` | 2677 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 145, 156, 167, 178, 189, 209, 249, 364, 557, 616, 628, 671, 794, 858, 926, 1696, 1745, 1791, 1843, 1885, 1897, 2055, 2097, 2146, 2340, 2388, 2436, 2481, 2561, 2599, 2637, 2668 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
