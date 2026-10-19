# DKA_SPAAUTOACCOUNTING_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPAAUTOACCOUNTING_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPAAUTOACCOUNTING_PKG.pkb).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1296 ; encodage : cp1252 (repli). SHA-256 : `e19adcc26ff1ca5baf008e191632bb8a44625701187bbd38c7673b0a8d56591e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 66 |
| `get_org_id_f` | 185 |
| `get_organisation_f` | 216 |
| `get_pa_code_express_f` | 248 |
| `get_project_type_f` | 283 |
| `get_project_code_f` | 310 |
| `get_task_asset_category_f` | 340 |
| `get_back_billing_project_f` | 374 |
| `get_dest_projet_f` | 402 |
| `get_affaire_projet_f` | 437 |
| `get_task_template_f` | 472 |
| `get_task_attribute_f` | 501 |
| `get_vendor_site_id_f` | 530 |
| `get_project_id_f` | 567 |
| `get_interco_fourn_f` | 596 |
| `centrefi` | 626 |
| `affaire` | 670 |
| `flux` | 702 |
| `societe_projet` | 743 |
| `projetfi` | 788 |
| `uo_projet` | 832 |
| `code_interco` | 879 |
| `run_cpt_groupe_couts_f` | 955 |
| `run_cpt_groupe_produit_f` | 1099 |
| `cpt_local_couts` | 1169 |
| `cpt_groupe_couts` | 1233 |
| `cpt_groupe_produit` | 1270 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `pa_projects_all` | 194 |
| `pa_projects_all` | 223 |
| `pa_segment_value_lookup_sets` | 256 |
| `pa_projects_all` | 289 |
| `pa_projects_all` | 317 |
| `pa_tasks` | 347 |
| `fa_categories_b_kfv` | 352 |
| `pa_expenditure_items_all` | 381 |
| `PA_PROJECT_CLASSES` | 414 |
| `PA_PROJECT_CLASSES` | 449 |
| `pa_tasks` | 479 |
| `pa_tasks` | 507 |
| `pa_expenditures_all` | 539 |
| `ap_invoices_all` | 545 |
| `pa_expenditure_items_all` | 575 |
| `AP_SUPPLIER_SITES_ALL` | 603 |
| `hr_all_organization_units` | 760 |
| `hr_all_organization_units` | 849 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.get_parameter` | 77 |
| `dka_tools_pkg.get_parameter` | 90 |
| `dka_tools_pkg.get_parameter` | 103 |
| `dka_tools_pkg.get_parameter` | 116 |
| `dka_tools_pkg.get_parameter` | 129 |
| `dka_tools_pkg.get_parameter` | 142 |
| `dka_tools_pkg.get_parameter` | 155 |
| `dka_spaautoaccounting_pkg.init` | 410 |
| `dka_spaautoaccounting_pkg.init` | 445 |
| `dka_spaautoaccounting_pkg.init` | 635 |
| `dka_spaautoaccounting_pkg.get_project_type_f` | 638 |
| `dka_spaautoaccounting_pkg.get_organisation_f` | 643 |
| `dka_spaautoaccounting_pkg.get_organisation_f` | 648 |
| `dka_spaautoaccounting_pkg.get_affaire_projet_f` | 682 |
| `dka_spaautoaccounting_pkg.init` | 711 |
| `dka_spaautoaccounting_pkg.get_project_type_f` | 714 |
| `dka_spaautoaccounting_pkg.init` | 751 |
| `dka_spaautoaccounting_pkg.get_org_id_f` | 754 |
| `dka_spaautoaccounting_pkg.init` | 796 |
| `dka_spaautoaccounting_pkg.get_project_type_f` | 799 |
| `dka_spaautoaccounting_pkg.get_project_code_f` | 804 |
| `dka_spaautoaccounting_pkg.get_project_code_f` | 808 |
| `dka_spaautoaccounting_pkg.init` | 840 |
| `dka_spaautoaccounting_pkg.get_org_id_f` | 843 |
| `dka_spaautoaccounting_pkg.init` | 893 |
| `dka_spaautoaccounting_pkg.get_vendor_site_id_f` | 898 |
| `dka_spaautoaccounting_pkg.get_project_id_f` | 909 |
| `dka_spaautoaccounting_pkg.get_project_type_f` | 918 |
| `dka_spaautoaccounting_pkg.get_interco_fourn_f` | 926 |
| `dka_spaautoaccounting_pkg.init` | 976 |
| `dka_spaautoaccounting_pkg.get_project_type_f` | 979 |
| `dka_spaautoaccounting_pkg.get_task_asset_category_f` | 984 |
| `dka_spaautoaccounting_pkg.get_pa_code_express_f` | 987 |
| `dka_spaautoaccounting_pkg.get_back_billing_project_f` | 995 |
| `dka_spaautoaccounting_pkg.get_dest_projet_f` | 1004 |
| `dka_spaautoaccounting_pkg.get_pa_code_express_f` | 1014 |
| `dka_spaautoaccounting_pkg.get_pa_code_express_f` | 1023 |
| `dka_spaautoaccounting_pkg.get_task_template_f` | 1030 |
| `dka_spaautoaccounting_pkg.get_pa_code_express_f` | 1039 |
| `dka_spaautoaccounting_pkg.get_task_attribute_f` | 1045 |
| `dka_spaautoaccounting_pkg.get_pa_code_express_f` | 1053 |
| `dka_spaautoaccounting_pkg.get_dest_projet_f` | 1059 |
| `dka_spaautoaccounting_pkg.get_pa_code_express_f` | 1067 |
| `dka_spaautoaccounting_pkg.init` | 1113 |
| `dka_spaautoaccounting_pkg.get_project_type_f` | 1116 |
| `dka_spaautoaccounting_pkg.get_pa_code_express_f` | 1125 |
| `dka_spaautoaccounting_pkg.get_task_template_f` | 1131 |
| `dka_spaautoaccounting_pkg.get_pa_code_express_f` | 1138 |
| `dka_spaautoaccounting_pkg.init` | 1180 |
| `dka_spaautoaccounting_pkg.get_project_type_f` | 1183 |
| `dka_spaautoaccounting_pkg.get_task_asset_category_f` | 1188 |
| `dka_spaautoaccounting_pkg.get_pa_code_express_f` | 1193 |
| `dka_spaautoaccounting_pkg.get_pa_code_express_f` | 1205 |
| `dka_spaautoaccounting_pkg.run_cpt_groupe_couts_f` | 1243 |
| `dka_spaautoaccounting_pkg.run_cpt_groupe_produit_f` | 1278 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 168, 199, 230, 266, 294, 323, 357, 386, 421, 456, 485, 513, 550, 580, 610, 654, 687, 727, 772, 815, 861, 933, 1080, 1150, 1213, 1250, 1285 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
