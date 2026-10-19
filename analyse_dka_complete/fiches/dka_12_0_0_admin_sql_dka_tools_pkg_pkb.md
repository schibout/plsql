# DKA_TOOLS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_TOOLS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_TOOLS_PKG.pkb).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2539 ; encodage : cp1252 (repli). SHA-256 : `f5b9e88f254d2c606dc28982b5a5de3bd2072db98cf5cd952279b48f8440aae4`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `numeric_check` | 46 |
| `put_debug_message` | 78 |
| `put_log_message` | 109 |
| `put_outdebug_message` | 137 |
| `put_out_header` | 161 |
| `get_filename` | 216 |
| `get_environment_variable` | 257 |
| `open_utl_file` | 297 |
| `open_utl_file_append` | 350 |
| `get_message` | 402 |
| `get_parameter` | 516 |
| `check_dka_parameters` | 557 |
| `get_code_combination_id` | 731 |
| `get_code_combination_id` | 899 |
| `segment_size` | 983 |
| `get_flex_key_seg_value_set` | 1017 |
| `ins_prog_message` | 1071 |
| `get_cuf_flex_value` | 1130 |
| `get_segments_from_ccid` | 1202 |
| `get_request_set_params` | 1311 |
| `cas_particuliers` | 1376 |
| `launch_request_set` | 1665 |
| `get_code_societe` | 1931 |
| `get_org_id` | 1978 |
| `trt_car_spec` | 2019 |
| `is_bank_holiday` | 2085 |
| `get_next_working_day` | 2157 |
| `add_error_stack` | 2184 |
| `print_error_stack` | 2204 |
| `clear_error_stack` | 2219 |
| `Create_Table_Online_Patching` | 2243 |
| `Create_Table_Online_Patching` | 2351 |
| `check_directory` | 2361 |
| `check_transco` | 2384 |
| `check_value_set` | 2420 |
| `check_parameter` | 2454 |
| `check_message` | 2469 |
| `check_flex_segment` | 2490 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `sys.DUAL` | 60 |
| `fnd_concurrent_programs` | 179 |
| `gl_access_set_assignments` | 230 |
| `fnd_env_context` | 268 |
| `dka_parameters` | 531 |
| `dka_parameters` | 591 |
| `dka_parameters` | 622 |
| `dual` | 653 |
| `dka_parameters` | 667 |
| `gl_access_set_assignments` | 772 |
| `gl_code_combinations` | 793 |
| `fnd_id_flex_segments` | 986 |
| `fnd_id_flex_structures_vl` | 1033 |
| `fnd_id_flex_structures_vl` | 1039 |
| `dka_program_messages` | 1085 |
| `fnd_flex_values` | 1150 |
| `gl_code_combinations` | 1274 |
| `fnd_request_set_program_args` | 1336 |
| `fnd_descr_flex_column_usages` | 1361 |
| `gl_sets_of_books` | 1393 |
| `gl_sets_of_books` | 1394 |
| `gl_ledgers` | 1397 |
| `gl_lookups` | 1398 |
| `fnd_flex_validation_tables` | 1476 |
| `fnd_flex_validation_tables` | 1581 |
| `fnd_req_set_run_form_v` | 1689 |
| `fnd_responsibility` | 1703 |
| `fnd_user` | 1710 |
| `fnd_request_sets` | 1715 |
| `hr_all_organization_units` | 1946 |
| `hr_all_organization_units` | 1993 |
| `dual` | 2042 |
| `dual` | 2051 |
| `dual` | 2064 |
| `all_tab_columns` | 2250 |
| `all_tables` | 2266 |
| `all_directories` | 2365 |
| `dka_stransco_headers` | 2389 |
| `dka_stransco_lines` | 2390 |
| `fnd_flex_value_sets` | 2425 |
| `fnd_flex_values` | 2426 |
| `DKA_PARAMETERS` | 2457 |
| `FND_NEW_MESSAGES` | 2473 |
| `FND_APPLICATION` | 2474 |
| `fnd_application` | 2503 |
| `fnd_descriptive_flexs` | 2504 |
| `fnd_descr_flex_column_usages` | 2505 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 93 |
| `Fnd_File.put_line` | 122 |
| `Fnd_File.put_line` | 143 |
| `Dka_Tools_Pkg.put_debug_message` | 145 |
| `Fnd_File.put_line` | 168 |
| `Fnd_File.put_line` | 169 |
| `Fnd_File.put_line` | 170 |
| `Fnd_File.put_line` | 171 |
| `Fnd_File.put_line` | 193 |
| `Fnd_File.put_line` | 194 |
| `Fnd_File.put_line` | 195 |
| `Fnd_File.put_line` | 196 |
| `Fnd_File.put_line` | 197 |
| `Fnd_File.put_line` | 198 |
| `Fnd_File.put_line` | 199 |
| `Fnd_File.put_line` | 200 |
| `Fnd_File.put_line` | 201 |
| `Fnd_Profile.VALUE` | 234 |
| `Fnd_Message.set_name` | 437 |
| `Fnd_Message.set_token` | 442 |
| `Fnd_Message.set_token` | 447 |
| `Fnd_Message.set_token` | 452 |
| `Fnd_Message.set_token` | 457 |
| `Fnd_Message.set_token` | 462 |
| `Fnd_Message.set_token` | 467 |
| `Fnd_Message.set_token` | 472 |
| `Fnd_Message.set_token` | 477 |
| `Fnd_Message.set_token` | 482 |
| `Fnd_Message.set_token` | 487 |
| `Fnd_Profile.VALUE` | 773 |
| `Fnd_Flex_Ext.get_combination_id` | 832 |
| `Fnd_Profile.VALUE` | 992 |
| `Fnd_Profile.VALUE` | 1042 |
| `dka_tools_pkg.put_debug_message` | 1172 |
| `Fnd_Profile.VALUE` | 1281 |
| `fnd_profile.value` | 1380 |
| `fnd_profile.value` | 1381 |
| `fnd_profile.value` | 1382 |
| `fnd_profile.value` | 1383 |
| `fnd_profile.value` | 1384 |
| `fnd_profile.value` | 1385 |
| `fnd_profile.value` | 1386 |
| `fnd_profile.value` | 1387 |
| `fnd_profile.value` | 1388 |
| `fnd_profile.value` | 1389 |
| `fnd_profile.value` | 1390 |
| `fnd_profile.value` | 1391 |
| `fnd_profile.value` | 1392 |
| `fnd_profile.value` | 1393 |
| `fnd_profile.value` | 1394 |
| `fnd_profile.value` | 1395 |
| `Fnd_Profile.VALUE` | 1396 |
| `gl_access_set_security_pkg.get_default_ledger_id` | 1397 |
| `Fnd_Profile.VALUE` | 1397 |
| `Fnd_Profile.VALUE` | 1458 |
| `Fnd_Flex_Val_Api.get_table_vset_select` | 1480 |
| `Fnd_Profile.VALUE` | 1563 |
| `Fnd_Flex_Val_Api.get_table_vset_select` | 1585 |
| `Fnd_Global.apps_initialize` | 1718 |
| `fnd_profile.value` | 1721 |
| `Fnd_Submit.set_request_set` | 1724 |
| `Dka_Tools_Pkg.put_debug_message` | 1726 |
| `Dka_Tools_Pkg.put_debug_message` | 1727 |
| `Fnd_Submit.set_print_options` | 1756 |
| `Dka_Tools_Pkg.put_debug_message` | 1763 |
| `Dka_Tools_Pkg.put_debug_message` | 1766 |
| `Fnd_Submit.submit_program` | 1775 |
| `Dka_Tools_Pkg.tab_request_params` | 1779 |
| `Dka_Tools_Pkg.tab_request_params` | 1780 |
| `Dka_Tools_Pkg.tab_request_params` | 1781 |
| `Dka_Tools_Pkg.tab_request_params` | 1782 |
| `Dka_Tools_Pkg.tab_request_params` | 1783 |
| `Dka_Tools_Pkg.tab_request_params` | 1784 |
| `Dka_Tools_Pkg.tab_request_params` | 1785 |
| `Dka_Tools_Pkg.tab_request_params` | 1786 |
| `Dka_Tools_Pkg.tab_request_params` | 1787 |
| `Dka_Tools_Pkg.tab_request_params` | 1788 |
| `Dka_Tools_Pkg.tab_request_params` | 1789 |
| `Dka_Tools_Pkg.tab_request_params` | 1790 |
| `Dka_Tools_Pkg.tab_request_params` | 1791 |
| `Dka_Tools_Pkg.tab_request_params` | 1792 |
| `Dka_Tools_Pkg.tab_request_params` | 1793 |
| `Dka_Tools_Pkg.tab_request_params` | 1794 |
| `Dka_Tools_Pkg.tab_request_params` | 1795 |
| `Dka_Tools_Pkg.tab_request_params` | 1796 |
| `Dka_Tools_Pkg.tab_request_params` | 1797 |
| `Dka_Tools_Pkg.tab_request_params` | 1798 |
| `Dka_Tools_Pkg.tab_request_params` | 1799 |
| `Dka_Tools_Pkg.tab_request_params` | 1800 |
| `Dka_Tools_Pkg.tab_request_params` | 1801 |
| `Dka_Tools_Pkg.tab_request_params` | 1802 |
| `Dka_Tools_Pkg.tab_request_params` | 1803 |
| `Dka_Tools_Pkg.tab_request_params` | 1804 |
| `Dka_Tools_Pkg.tab_request_params` | 1805 |
| `Dka_Tools_Pkg.tab_request_params` | 1806 |
| `Dka_Tools_Pkg.tab_request_params` | 1807 |
| `Dka_Tools_Pkg.tab_request_params` | 1808 |
| `Dka_Tools_Pkg.tab_request_params` | 1809 |
| `Dka_Tools_Pkg.tab_request_params` | 1810 |
| `Dka_Tools_Pkg.tab_request_params` | 1811 |
| `Dka_Tools_Pkg.tab_request_params` | 1812 |
| `Dka_Tools_Pkg.tab_request_params` | 1813 |
| `Dka_Tools_Pkg.tab_request_params` | 1814 |
| `Dka_Tools_Pkg.tab_request_params` | 1815 |
| `Dka_Tools_Pkg.tab_request_params` | 1816 |
| `Dka_Tools_Pkg.tab_request_params` | 1817 |
| `Dka_Tools_Pkg.tab_request_params` | 1818 |
| `Dka_Tools_Pkg.tab_request_params` | 1819 |
| `Dka_Tools_Pkg.tab_request_params` | 1820 |
| `Dka_Tools_Pkg.tab_request_params` | 1821 |
| `Dka_Tools_Pkg.tab_request_params` | 1822 |
| `Dka_Tools_Pkg.tab_request_params` | 1823 |
| `Dka_Tools_Pkg.tab_request_params` | 1824 |
| `Dka_Tools_Pkg.tab_request_params` | 1825 |
| `Dka_Tools_Pkg.tab_request_params` | 1826 |
| `Dka_Tools_Pkg.tab_request_params` | 1827 |
| `Dka_Tools_Pkg.tab_request_params` | 1828 |
| `Dka_Tools_Pkg.tab_request_params` | 1829 |
| `Dka_Tools_Pkg.tab_request_params` | 1830 |
| `Dka_Tools_Pkg.tab_request_params` | 1831 |
| `Dka_Tools_Pkg.tab_request_params` | 1832 |
| `Dka_Tools_Pkg.tab_request_params` | 1833 |
| `Dka_Tools_Pkg.tab_request_params` | 1834 |
| `Dka_Tools_Pkg.tab_request_params` | 1835 |
| `Dka_Tools_Pkg.tab_request_params` | 1836 |
| `Dka_Tools_Pkg.tab_request_params` | 1837 |
| `Dka_Tools_Pkg.tab_request_params` | 1838 |
| `Dka_Tools_Pkg.tab_request_params` | 1839 |
| `Dka_Tools_Pkg.tab_request_params` | 1840 |
| `Dka_Tools_Pkg.tab_request_params` | 1841 |
| `Dka_Tools_Pkg.tab_request_params` | 1842 |
| `Dka_Tools_Pkg.tab_request_params` | 1843 |
| `Dka_Tools_Pkg.tab_request_params` | 1844 |
| `Dka_Tools_Pkg.tab_request_params` | 1845 |
| `Dka_Tools_Pkg.tab_request_params` | 1846 |
| `Dka_Tools_Pkg.tab_request_params` | 1847 |
| `Dka_Tools_Pkg.tab_request_params` | 1848 |
| `Dka_Tools_Pkg.tab_request_params` | 1849 |
| `Dka_Tools_Pkg.tab_request_params` | 1850 |
| `Dka_Tools_Pkg.tab_request_params` | 1851 |
| `Dka_Tools_Pkg.tab_request_params` | 1852 |
| `Dka_Tools_Pkg.tab_request_params` | 1853 |
| `Dka_Tools_Pkg.tab_request_params` | 1854 |
| `Dka_Tools_Pkg.tab_request_params` | 1855 |
| `Dka_Tools_Pkg.tab_request_params` | 1856 |
| `Dka_Tools_Pkg.tab_request_params` | 1857 |
| `Dka_Tools_Pkg.tab_request_params` | 1858 |
| `Dka_Tools_Pkg.tab_request_params` | 1859 |
| `Dka_Tools_Pkg.tab_request_params` | 1860 |
| `Dka_Tools_Pkg.tab_request_params` | 1861 |
| `Dka_Tools_Pkg.tab_request_params` | 1862 |
| `Dka_Tools_Pkg.tab_request_params` | 1863 |
| `Dka_Tools_Pkg.tab_request_params` | 1864 |
| `Dka_Tools_Pkg.tab_request_params` | 1865 |
| `Dka_Tools_Pkg.tab_request_params` | 1866 |
| `Dka_Tools_Pkg.tab_request_params` | 1867 |
| `Dka_Tools_Pkg.tab_request_params` | 1868 |
| `Dka_Tools_Pkg.tab_request_params` | 1869 |
| `Dka_Tools_Pkg.tab_request_params` | 1870 |
| `Dka_Tools_Pkg.tab_request_params` | 1871 |
| `Dka_Tools_Pkg.tab_request_params` | 1872 |
| `Dka_Tools_Pkg.tab_request_params` | 1873 |
| `Dka_Tools_Pkg.tab_request_params` | 1874 |
| `Dka_Tools_Pkg.tab_request_params` | 1875 |
| `Dka_Tools_Pkg.tab_request_params` | 1876 |
| `Dka_Tools_Pkg.tab_request_params` | 1877 |
| `Dka_Tools_Pkg.tab_request_params` | 1878 |
| `Dka_Tools_Pkg.put_debug_message` | 1881 |
| `Dka_Tools_Pkg.put_debug_message` | 1884 |
| `Fnd_Submit.submit_set` | 1892 |
| `Dka_Tools_Pkg.put_debug_message` | 1898 |
| `Dka_Tools_Pkg.put_debug_message` | 1899 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 2340 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 2344 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 2348 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 2353 |
| `Fnd_Profile.VALUE` | 2535 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1107, 1894, 2323 |
| rollback | 1111 |
| transaction_autonome | 1083 |
| when_others | 187, 329, 382, 495, 539, 876, 963, 1059, 1109, 1169, 1291, 1526, 1630, 1908, 1956, 2003, 2071, 2143, 2174, 2194, 2281, 2328, 2349 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
