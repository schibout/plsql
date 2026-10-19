# DKA_XX_LOADER_UTILS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_XX_LOADER_UTILS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_XX_LOADER_UTILS_PKG.pkb).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2385 ; encodage : cp1252 (repli). SHA-256 : `e626670f1e216c4e63692c85b2035ef77ca7550509eefe4783a0c92894f14f9f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `debug_on` | 50 |
| `debug_off` | 55 |
| `println` | 62 |
| `message` | 74 |
| `message_init` | 79 |
| `get_meaning` | 88 |
| `invert_flag_f` | 106 |
| `get_where_clause` | 120 |
| `get_user_exit` | 138 |
| `add_event` | 158 |
| `get_request_groups` | 173 |
| `version` | 261 |
| `message` | 266 |
| `get_element` | 271 |
| `get_appl_short_name` | 291 |
| `get_vset_long` | 307 |
| `create_value_set` | 325 |
| `df_setup` | 572 |
| `df_context` | 601 |
| `df_segment` | 632 |
| `df_setup_tl` | 703 |
| `df_context_tl` | 730 |
| `df_segment_tl` | 759 |
| `executable` | 795 |
| `update_request_lines` | 849 |
| `executable_desc` | 884 |
| `program` | 921 |
| `program_desc` | 1036 |
| `parameter` | 1074 |
| `parameter_desc` | 1164 |
| `request_group` | 1251 |
| `request_group_unit` | 1281 |
| `create_update_exe_p` | 1314 |
| `update_exe_p` | 1394 |
| `delete_exe_prog_p` | 1444 |
| `delete_params_prog_p` | 1508 |
| `request_set` | 1555 |
| `request_set_desc` | 1625 |
| `request_stage` | 1664 |
| `request_stage_desc` | 1701 |
| `link_stage` | 1746 |
| `set_program` | 1801 |
| `set_program_param` | 1838 |
| `set_incompatibility` | 1891 |
| `prog_incompatibility` | 1932 |
| `dka_fnd_lookup_type` | 1980 |
| `dka_fnd_lookup_values_desc` | 2062 |
| `dka_fnd_profile_options_desc` | 2171 |
| `message` | 2194 |
| `dka_parameter` | 2260 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_lookup_values` | 94 |
| `fnd_flex_validation_tables` | 130 |
| `fnd_flex_validation_events` | 148 |
| `fnd_flex_value_sets` | 165 |
| `fnd_application` | 193 |
| `fnd_application` | 214 |
| `fnd_application` | 298 |
| `fnd_flex_value_sets` | 397 |
| `fnd_descriptive_flexs_tl` | 713 |
| `fnd_application` | 720 |
| `fnd_descr_flex_contexts_tl` | 741 |
| `fnd_application` | 749 |
| `fnd_descr_flex_col_usage_tl` | 772 |
| `fnd_application` | 782 |
| `fnd_lookups` | 822 |
| `FND_CONCURRENT_REQUESTS` | 859 |
| `fnd_concurrent_programs` | 862 |
| `FND_CONCURRENT_REQUESTS` | 869 |
| `fnd_executables_tl` | 894 |
| `fnd_executables` | 903 |
| `fnd_concurrent_programs` | 1004 |
| `fnd_concurrent_programs_tl` | 1046 |
| `fnd_concurrent_programs` | 1055 |
| `fnd_lookups` | 1115 |
| `fnd_lookups` | 1125 |
| `fnd_descr_flex_col_usage_tl` | 1179 |
| `fnd_application` | 1190 |
| `fnd_descr_flex_column_usages` | 1195 |
| `fnd_application` | 1198 |
| `fnd_descr_flex_col_usage_tl` | 1208 |
| `fnd_application` | 1219 |
| `fnd_application` | 1230 |
| `fnd_executables` | 1336 |
| `fnd_application` | 1347 |
| `fnd_executables_tl` | 1351 |
| `fnd_executables` | 1361 |
| `fnd_lookups` | 1373 |
| `fnd_executables` | 1406 |
| `fnd_application` | 1417 |
| `fnd_executables_tl` | 1421 |
| `fnd_executables` | 1431 |
| `fnd_concurrent_programs` | 1459 |
| `fnd_concurrent_programs` | 1483 |
| `fnd_application` | 1515 |
| `fnd_concurrent_programs` | 1594 |
| `fnd_request_sets` | 1599 |
| `fnd_request_sets_tl` | 1636 |
| `fnd_request_sets` | 1645 |
| `fnd_request_set_stages_tl` | 1713 |
| `fnd_application` | 1723 |
| `fnd_lookups` | 1861 |
| `DUAL` | 1910 |
| `FND_LOOKUP_TYPES` | 1999 |
| `FND_APPLICATION` | 2007 |
| `FND_APPLICATION` | 2012 |
| `FND_SECURITY_GROUPS` | 2017 |
| `FND_LOOKUP_VALUES` | 2085 |
| `fnd_profile_options_tl` | 2179 |
| `fnd_application` | 2205 |
| `fnd_new_messages` | 2209 |
| `FND_NEW_MESSAGES` | 2217 |
| `dual` | 2306 |
| `dka_parameters` | 2320 |
| `dka_parameters` | 2334 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_flex_val_api.add_event` | 169 |
| `fnd_flex_val_api.valueset_exists` | 390 |
| `fnd_flex_val_api.set_session_mode` | 412 |
| `fnd_flex_val_api.create_valueset_none` | 417 |
| `fnd_flex_val_api.create_valueset_independent` | 431 |
| `fnd_flex_val_api.create_valueset_special` | 445 |
| `fnd_flex_val_api.create_valueset_pair` | 459 |
| `fnd_flex_val_api.create_valueset_dependent` | 476 |
| `fnd_flex_val_api.create_valueset_table` | 511 |
| `fnd_flex_val_api.destructive_rename` | 550 |
| `FND_FLEX_DSC_API.SET_SESSION_MODE` | 584 |
| `FND_FLEX_DSC_API.SET_VALIDATION` | 586 |
| `FND_FLEX_DSC_API.SETUP_CONTEXT_FIELD` | 588 |
| `FND_FLEX_DSC_API.FREEZE` | 593 |
| `FND_FLEX_DSC_API.SET_SESSION_MODE` | 612 |
| `FND_FLEX_DSC_API.DELETE_CONTEXT` | 614 |
| `FND_FLEX_DSC_API.CREATE_CONTEXT` | 616 |
| `FND_FLEX_DSC_API.SET_SESSION_MODE` | 663 |
| `FND_FLEX_DSC_API.DELETE_SEGMENT` | 665 |
| `FND_FLEX_DSC_API.SET_VALIDATION` | 671 |
| `FND_FLEX_DSC_API.CREATE_SEGMENT` | 673 |
| `FND_PROGRAM.SET_SESSION_MODE` | 811 |
| `fnd_program.executable_exists` | 813 |
| `fnd_program.executable` | 829 |
| `FND_PROGRAM.SET_SESSION_MODE` | 953 |
| `fnd_program.program_exists` | 955 |
| `FND_PROGRAM.DELETE_PROGRAM` | 964 |
| `FND_PROGRAM.REGISTER` | 972 |
| `FND_PROGRAM.Add_To_Group` | 1017 |
| `FND_PROGRAM.SET_SESSION_MODE` | 1100 |
| `fnd_program.parameter_exists` | 1104 |
| `FND_PROGRAM.PARAMETER` | 1133 |
| `fnd_program.request_group_exists` | 1259 |
| `FND_PROGRAM.REQUEST_GROUP` | 1263 |
| `FND_PROGRAM.SET_SESSION_MODE` | 1289 |
| `fnd_program.program_in_group` | 1291 |
| `FND_PROGRAM.ADD_TO_GROUP` | 1297 |
| `FND_PROGRAM.SET_SESSION_MODE` | 1331 |
| `fnd_program.executable_exists` | 1333 |
| `fnd_program.executable` | 1380 |
| `FND_PROGRAM.DELETE_PARAMETER` | 1533 |
| `FND_SET.Request_Set_Exists` | 1573 |
| `FND_SET.DELETE_SET` | 1579 |
| `FND_SET.CREATE_SET` | 1584 |
| `FND_SET.Add_Set_To_Group` | 1607 |
| `FND_SET.ADD_STAGE` | 1679 |
| `FND_SET.LINK_STAGES` | 1757 |
| `FND_SET.LINK_STAGES` | 1769 |
| `FND_SET.LINK_STAGES` | 1781 |
| `FND_SET.ADD_PROGRAM` | 1816 |
| `FND_SET.PROGRAM_PARAMETER` | 1868 |
| `FND_SET.INCOMPATIBILITY` | 1912 |
| `FND_SET.INCOMPATIBILITY` | 1950 |
| `FND_PROGRAM.INCOMPATIBILITY` | 1962 |
| `Fnd_Lookup_Types_Pkg.Insert_Row` | 2025 |
| `Fnd_Lookup_Types_Pkg.Update_Row` | 2041 |
| `Fnd_Lookup_Values_Pkg.Insert_Row` | 2096 |
| `Fnd_Lookup_Values_Pkg.Update_Row` | 2132 |
| `fnd_file.put_line` | 2363 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 101, 135, 154, 247, 304, 405, 557, 564, 725, 754, 787, 838, 878, 914, 1029, 1066, 1158, 1207, 1243, 1274, 1308, 1389, 1438, 1503, 1549, 1618, 1656, 1695, 1738, 1795, 1833, 1886, 1926, 1974, 2056, 2166, 2188, 2250, 2367 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
