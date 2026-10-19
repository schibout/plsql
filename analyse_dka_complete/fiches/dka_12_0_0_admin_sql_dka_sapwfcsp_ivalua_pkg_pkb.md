# DKA_SAPWFCSP_IVALUA_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPWFCSP_IVALUA_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPWFCSP_IVALUA_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 3562 ; encodage : cp1252 (repli). SHA-256 : `42531622e7c55cfca7ebe844cdee30ef37c0c7c98c7627a4c13bc073b5dc0b16`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `update_data` | 35 |
| `notif_csp_ano_imput_att_ivalua` | 188 |
| `pose_blocage` | 437 |
| `maj_blocage` | 551 |
| `notif_dest_ivalua` | 664 |
| `insert_history_ivalua` | 874 |
| `pre_notification_ivalua` | 1163 |
| `get_action_history_ivalua` | 1309 |
| `get_infos_ap_ivalua` | 1763 |
| `notif_reponse_ivalua` | 2056 |
| `traitement_blocage_ivalua` | 2198 |
| `debloque_null` | 2597 |
| `is_ivalua_order` | 2703 |
| `notif_ecartprix_ivalua` | 2758 |
| `get_ecart_prix_ivalua` | 2913 |
| `insert_history_wf_ivalua` | 3040 |
| `notif_CSP_ANO_QTY_REC_IV` | 3107 |
| `notif_CSP_ANO_QTY_ORD_IV` | 3267 |
| `get_reponse_blocage_ivalua` | 3427 |
| `verif_blocage_ivalua` | 3523 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `Backend` | 52 |
| `per_people_f` | 63 |
| `per_people_f` | 72 |
| `ap_invoices_all` | 84 |
| `ap_holds_all` | 91 |
| `fnd_flex_value_sets` | 100 |
| `ap_holds_all` | 119 |
| `fnd_user` | 145 |
| `wf_notifications` | 149 |
| `fnd_form_functions` | 295 |
| `fnd_user` | 498 |
| `ap_hold_codes` | 514 |
| `du` | 609 |
| `ap_holds_all` | 616 |
| `ap_holds_all` | 624 |
| `ap_holds_all` | 753 |
| `attribute4` | 812 |
| `ap_holds_all` | 814 |
| `ap_holds_all` | 828 |
| `fnd_user` | 840 |
| `per_all_people_f` | 966 |
| `dual` | 1004 |
| `ap_holds_all` | 1016 |
| `FND_LOOKUP_VALUES` | 1027 |
| `ap_inv_aprvl_hist_all` | 1040 |
| `dual` | 1075 |
| `FND_LOOKUP_VALUES` | 1086 |
| `dka_ap_inv_aprvl_hist_all` | 1098 |
| `ap_inv_aprvl_hist_all` | 1328 |
| `ap_inv_aprvl_hist_all` | 1342 |
| `ap_inv_aprvl_hist_all` | 1358 |
| `dka_ap_inv_aprvl_hist_all` | 1376 |
| `dka_ap_inv_aprvl_hist_all` | 1390 |
| `dka_ap_inv_aprvl_hist_all` | 1406 |
| `ap_inv_aprvl_hist_all` | 1490 |
| `ap_inv_aprvl_hist_all` | 1535 |
| `dka_ap_inv_aprvl_hist_all` | 1621 |
| `dka_ap_inv_aprvl_hist_all` | 1666 |
| `fnd_user` | 2242 |
| `fnd_user` | 2247 |
| `ap_inv_aprvl_hist_all` | 2275 |
| `ap_inv_aprvl_hist_all` | 2278 |
| `ap_hold_codes` | 2299 |
| `ap_holds_all` | 2312 |
| `ap_invoices_all` | 2339 |
| `po_headers_all` | 2347 |
| `ap_holds_all` | 2354 |
| `ap_holds_all` | 2400 |
| `ap_holds_all` | 2419 |
| `ap_holds_all` | 2433 |
| `ap_holds_all` | 2462 |
| `ap_holds_all` | 2486 |
| `ap_hold_codes` | 2499 |
| `ap_holds_all` | 2521 |
| `ap_holds_all` | 2525 |
| `ap_holds_all` | 2563 |
| `fnd_user` | 2650 |
| `ap_invoice_distributions_all` | 2722 |
| `ap_invoice_distributions_all` | 2730 |
| `ap_holds_all` | 2925 |
| `fnd_user` | 3197 |
| `fnd_user` | 3358 |
| `ap_inv_aprvl_hist_all` | 3460 |
| `ap_inv_aprvl_hist_all` | 3463 |
| `ap_holds_all` | 3542 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_sapwfcsp_pkg.print_wf_message` | 111 |
| `dka_sapwfcsp_pkg.print_wf_message` | 115 |
| `wf_notification.setattrtext` | 162 |
| `wf_notification.setattrtext` | 164 |
| `wf_notification.respond` | 166 |
| `wf_engine.setitemattrnumber` | 226 |
| `wf_engine.setitemattrnumber` | 231 |
| `dka_sapwfcsp_pkg.print_wf_message` | 240 |
| `dka_sapwfcsp_pkg.print_wf_message` | 246 |
| `wf_engine.getitemattrtext` | 252 |
| `wf_notification.getattrtext` | 257 |
| `wf_notification.getattrtext` | 260 |
| `wf_notification.getattrtext` | 262 |
| `fnd_message.get_string` | 270 |
| `dka_sapwfcsp_pkg.print_wf_message` | 271 |
| `fnd_message.get_string` | 280 |
| `wf_engine.getitemattrnumber` | 285 |
| `fnd_run_function.get_run_function_url` | 298 |
| `wf_engine.setitemattrtext` | 311 |
| `wf_engine.setitemattrnumber` | 334 |
| `wf_engine.setitemattrnumber` | 339 |
| `wf_engine.setitemattrnumber` | 343 |
| `wf_engine.setitemattrnumber` | 348 |
| `wf_engine.setitemattrnumber` | 353 |
| `wf_notification.getattrtext` | 362 |
| `wf_engine.setitemattrtext` | 365 |
| `wf_engine.setitemattrtext` | 372 |
| `wf_notification.responder` | 375 |
| `wf_engine.setitemattrtext` | 384 |
| `wf_engine.setitemattrtext` | 391 |
| `dka_tools_pkg.get_message` | 394 |
| `WF_DIRECTORY.GetRoleDisplayName` | 406 |
| `wf_engine.setitemattrtext` | 416 |
| `wf_notification.responder` | 419 |
| `dka_sapwfcsp_pkg.print_wf_message` | 422 |
| `dka_sapwfcsp_pkg.print_wf_message` | 459 |
| `wf_engine.getitemattrnumber` | 463 |
| `dka_sapwfcsp_pkg.print_wf_message` | 467 |
| `wf_engine.getactivityattrtext` | 473 |
| `dka_sapwfcsp_pkg.print_wf_message` | 478 |
| `wf_engine.getactivityattrtext` | 484 |
| `dka_sapwfcsp_pkg.print_wf_message` | 489 |
| `wf_engine.getitemattrnumber` | 501 |
| `dka_sapwfcsp_pkg.print_wf_message` | 506 |
| `dka_sapwfcsp_pkg.print_wf_message` | 517 |
| `dka_sapwfcsp_pkg.cree_blocage_ap` | 523 |
| `wf_engine.getitemattrnumber` | 569 |
| `wf_engine.getactivityattrtext` | 573 |
| `wf_engine.getactivityattrnumber` | 578 |
| `wf_engine.getitemattrnumber` | 584 |
| `wf_engine.getactivityattrtext` | 590 |
| `wf_engine.getactivityattrtext` | 595 |
| `wf_engine.getactivityattrtext` | 600 |
| `dka_sapwfcsp_pkg.print_wf_message` | 607 |
| `dka_sapwfcsp_pkg.print_wf_message` | 634 |
| `dka_sapwfcsp_pkg.print_wf_message` | 642 |
| `wf_core.context` | 647 |
| `wf_engine.setitemattrnumber` | 700 |
| `wf_engine.setitemattrnumber` | 705 |
| `dka_sapwfcsp_pkg.print_wf_message` | 714 |
| `dka_sapwfcsp_pkg.print_wf_message` | 720 |
| `wf_notification.getattrtext` | 726 |
| `dka_sapwfcsp_pkg.print_wf_message` | 728 |
| `wf_engine.getitemattrnumber` | 733 |
| `wf_engine.getitemattrnumber` | 737 |
| `wf_engine.getitemattrnumber` | 741 |
| `dka_sapwfcsp_pkg.print_wf_message` | 747 |
| `fnd_message.get_string` | 762 |
| `dka_sapwfcsp_pkg.print_wf_message` | 763 |
| `wf_engine.setitemattrnumber` | 786 |
| `wf_engine.setitemattrnumber` | 791 |
| `wf_engine.setitemattrnumber` | 795 |
| `wf_engine.setitemattrnumber` | 800 |
| `wf_engine.setitemattrnumber` | 805 |
| `dka_sapwfcsp_pkg.print_wf_message` | 810 |
| `dka_sapwfcsp_pkg.print_wf_message` | 822 |
| `WF_DIRECTORY.GetRoleDisplayName` | 849 |
| `dka_sapwfcsp_pkg.print_wf_message` | 858 |
| `dka_sapwfcsp_pkg.print_wf_message` | 897 |
| `dka_sapwfcsp_pkg.print_wf_message` | 906 |
| `dka_sapwfcsp_pkg.print_wf_message` | 911 |
| `wf_engine.getitemattrnumber` | 917 |
| `dka_sapwfcsp_pkg.print_wf_message` | 920 |
| `wf_engine.getitemattrnumber` | 927 |
| `dka_sapwfcsp_pkg.print_wf_message` | 931 |
| `dka_sapwfcsp_pkg.print_wf_message` | 937 |
| `dka_sapwfcsp_pkg.print_wf_message` | 946 |
| `wf_notification.responder` | 953 |
| `dka_sapwfcsp_pkg.print_wf_message` | 955 |
| `dka_sapwfcsp_pkg.print_wf_message` | 979 |
| `wf_engine.getitemattrnumber` | 992 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1006 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1033 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1077 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1092 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1132 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1147 |
| `wf_engine.getitemattrtext` | 1182 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1187 |
| `dka_sapgetimg_wf_pkg.get_url_image_facture_ivalua` | 1196 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1198 |
| `dka_sapgetimg_wf_pkg.get_url_image_facture_ivalua` | 1205 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1207 |
| `wf_engine.setitemattrtext` | 1218 |
| `wf_engine.getitemattrnumber` | 1223 |
| `dka_sapgetimg_wf_pkg.get_url_image_bdc_ivalua` | 1228 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1233 |
| `wf_engine.setitemattrtext` | 1237 |
| `wf_engine.setitemattrtext` | 1242 |
| `wf_engine.SetItemAttrText` | 1250 |
| `wf_engine.setitemattrtext` | 1257 |
| `wf_engine.setitemattrtext` | 1264 |
| `dka_tools_pkg.get_message` | 1267 |
| `wf_engine.setitemattrtext` | 1269 |
| `dka_tools_pkg.get_message` | 1272 |
| `wf_engine.setitemattrtext` | 1274 |
| `dka_tools_pkg.get_message` | 1277 |
| `wf_engine.SetItemAttrText` | 1280 |
| `dka_tools_pkg.get_message` | 1283 |
| `wf_engine.SetItemAttrText` | 1286 |
| `dka_tools_pkg.get_message` | 1289 |
| `wf_engine.SetItemAttrText` | 1291 |
| `dka_tools_pkg.get_message` | 1294 |
| `dka_sapwfcsp_pkg.get_item_info` | 1420 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1424 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1431 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1440 |
| `fnd_message.get_string` | 1451 |
| `fnd_message.get_string` | 1458 |
| `fnd_message.get_string` | 1464 |
| `fnd_message.get_string` | 1470 |
| `fnd_message.get_string` | 1476 |
| `wf_engine.getitemattrnumber` | 1481 |
| `wf_notification.writetoclob` | 1741 |
| `wf_notification.writetoclob` | 1745 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1748 |
| `dka_sapwfcsp_pkg.get_item_info` | 1787 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1791 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1799 |
| `wf_notification.getattrtext` | 1809 |
| `dka_sapwfcsp_pkg.print_wf_message` | 1816 |
| `wf_engine.getitemattrtext` | 1822 |
| `wf_engine.getitemattrtext` | 1826 |
| `wf_engine.getitemattrnumber` | 1830 |
| `wf_engine.getitemattrdate` | 1834 |
| `wf_engine.getitemattrtext` | 1838 |
| `wf_engine.getitemattrtext` | 1842 |
| `wf_engine.getitemattrtext` | 1846 |
| `wf_engine.getitemattrtext` | 1850 |
| `wf_engine.getitemattrtext` | 1854 |
| `wf_engine.getitemattrtext` | 1858 |
| `fnd_message.get_string` | 1873 |
| `fnd_message.get_string` | 1879 |
| `fnd_message.get_string` | 1885 |
| `fnd_message.get_string` | 1892 |
| `fnd_message.get_string` | 1898 |
| `fnd_message.get_string` | 1905 |
| `fnd_message.get_string` | 1912 |
| `fnd_message.get_string` | 1919 |
| `fnd_message.get_string` | 1926 |
| `fnd_message.get_string` | 1933 |
| `fnd_message.get_string` | 1940 |
| `fnd_message.get_string` | 1947 |
| `fnd_message.get_string` | 1953 |
| `fnd_message.get_string` | 1959 |
| `dka_sapwfcsp_pkg.get_blocages_ap` | 2031 |
| `wf_notification.writetoclob` | 2036 |
| `wf_notification.writetoclob` | 2039 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2041 |
| `wf_engine.setitemattrnumber` | 2087 |
| `wf_engine.setitemattrnumber` | 2092 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2101 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2107 |
| `wf_notification.getattrtext` | 2113 |
| `fnd_message.get_string` | 2120 |
| `wf_engine.setitemattrtext` | 2123 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2136 |
| `wf_engine.setitemattrtext` | 2144 |
| `wf_notification.responder` | 2147 |
| `wf_engine.setitemattrnumber` | 2158 |
| `wf_engine.setitemattrnumber` | 2163 |
| `wf_engine.setitemattrnumber` | 2167 |
| `wf_engine.setitemattrnumber` | 2172 |
| `wf_engine.setitemattrnumber` | 2177 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2184 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2223 |
| `wf_engine.getitemattrnumber` | 2229 |
| `wf_engine.getitemattrnumber` | 2233 |
| `wf_engine.getitemattrnumber` | 2250 |
| `wf_engine.getitemattrnumber` | 2254 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2258 |
| `wf_engine.getitemattrtext` | 2263 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2267 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2284 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2292 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2303 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2317 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2327 |
| `fnd_file.put_line` | 2364 |
| `dka_sapwfcsp_pkg.leve_blocage` | 2379 |
| `WF_DIRECTORY.GetRoleDisplayName` | 2398 |
| `dka_sapwfcsp_pkg.leve_blocage` | 2408 |
| `dka_sapwfcsp_pkg.leve_blocage` | 2440 |
| `WF_DIRECTORY.GetRoleDisplayName` | 2460 |
| `dka_stransco_pkg.get_value_f` | 2475 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2479 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2491 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2502 |
| `dka_sapwfcsp_pkg.cree_blocage_ap` | 2506 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2530 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2536 |
| `dka_sapwfcsp_pkg.leve_blocage` | 2540 |
| `WF_DIRECTORY.GetRoleDisplayName` | 2560 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2576 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2612 |
| `wf_engine.getitemattrnumber` | 2616 |
| `wf_engine.getactivityattrtext` | 2620 |
| `wf_engine.getactivityattrtext` | 2625 |
| `wf_engine.getactivityattrtext` | 2630 |
| `wf_engine.getactivityattrtext` | 2637 |
| `wf_engine.getitemattrnumber` | 2653 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2658 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2664 |
| `dka_sapwfcsp_pkg.leve_blocage` | 2673 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2689 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2712 |
| `wf_engine.getitemattrnumber` | 2717 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2744 |
| `wf_engine.setitemattrnumber` | 2790 |
| `wf_engine.setitemattrnumber` | 2795 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2804 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2810 |
| `wf_notification.getattrtext` | 2816 |
| `wf_notification.GetAttrText` | 2819 |
| `wf_engine.setitemattrnumber` | 2840 |
| `wf_engine.setitemattrnumber` | 2845 |
| `wf_engine.setitemattrnumber` | 2849 |
| `wf_engine.setitemattrnumber` | 2854 |
| `wf_engine.setitemattrnumber` | 2859 |
| `fnd_message.get_string` | 2867 |
| `wf_notification.getattrtext` | 2876 |
| `wf_engine.setitemattrtext` | 2879 |
| `wf_engine.setitemattrtext` | 2886 |
| `wf_notification.responder` | 2889 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2897 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2951 |
| `dka_sapwfcsp_pkg.get_item_info` | 2958 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2963 |
| `dka_sapwfcsp_pkg.print_wf_message` | 2972 |
| `fnd_message.get_string` | 2987 |
| `fnd_message.get_string` | 2991 |
| `fnd_message.get_string` | 2995 |
| `fnd_message.get_string` | 2999 |
| `fnd_message.get_string` | 3003 |
| `wf_notification.writetoclob` | 3029 |
| `wf_notification.writetoclob` | 3032 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3034 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3058 |
| `wf_engine.GetActivityAttrText` | 3064 |
| `wf_engine.GetActivityAttrText` | 3069 |
| `wf_engine.GetActivityAttrText` | 3074 |
| `wf_engine.GetActivityAttrText` | 3079 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3083 |
| `WF_DIRECTORY.GetRoleDisplayName` | 3094 |
| `wf_engine.SetItemAttrNumber` | 3140 |
| `wf_engine.SetItemAttrNumber` | 3145 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3155 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3162 |
| `wf_notification.GetAttrText` | 3168 |
| `wf_notification.GetAttrText` | 3172 |
| `wf_engine.setitemattrtext` | 3199 |
| `wf_engine.SetItemAttrNumber` | 3205 |
| `wf_engine.SetItemAttrNumber` | 3210 |
| `wf_engine.SetItemAttrNumber` | 3214 |
| `fnd_message.get_string` | 3222 |
| `wf_notification.GetAttrText` | 3231 |
| `wf_engine.SetItemAttrText` | 3234 |
| `wf_engine.setitemattrtext` | 3241 |
| `wf_notification.responder` | 3244 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3252 |
| `wf_engine.SetItemAttrNumber` | 3300 |
| `wf_engine.SetItemAttrNumber` | 3305 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3315 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3322 |
| `wf_notification.GetAttrText` | 3328 |
| `wf_notification.GetAttrText` | 3332 |
| `wf_engine.setitemattrtext` | 3360 |
| `wf_engine.SetItemAttrNumber` | 3366 |
| `wf_engine.SetItemAttrNumber` | 3371 |
| `wf_engine.SetItemAttrNumber` | 3375 |
| `fnd_message.get_string` | 3383 |
| `wf_notification.GetAttrText` | 3392 |
| `wf_engine.SetItemAttrText` | 3395 |
| `wf_engine.setitemattrtext` | 3402 |
| `wf_notification.responder` | 3405 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3413 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3438 |
| `wf_engine.getitemattrnumber` | 3444 |
| `wf_engine.getitemattrnumber` | 3448 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3452 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3473 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3481 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3489 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3498 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3506 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3531 |
| `wf_engine.getitemattrnumber` | 3536 |
| `dka_sapwfcsp_pkg.print_wf_message` | 3553 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 170, 2470, 2568 |
| rollback | 173 |
| when_others | 69, 172, 377, 640, 1131, 1214, 1230, 1499, 1546, 1630, 1677, 1812, 2283, 2316, 2363, 2642, 2891, 3246, 3407, 3472 |
| workflow | 213, 226, 231, 236, 245, 252, 269, 279, 285, 311, 334, 339, 343, 348, 353, 360, 365, 372, 384, 391, 416, 453, 455, 463, 473, 484, 501, 535, 537, 564, 565, 569, 573, 578, 584, 590, 595, 600, 687, 700, 705, 710, 719, 733, 737, 741, 761, 786, 791, 795, 800, 805, 854, 917, 927, 951, 992, 1175, 1177, 1182, 1218, 1223, 1237, 1242, 1250, 1257, 1264, 1269, 1274, 1280, 1286, 1291, 1481, 1822, 1826, 1830, 1834, 1838, 1842, 1846, 1850, 1854, 1858, 2074, 2087, 2092, 2097, 2106, 2119, 2123, 2144, 2158, 2163, 2167, 2172, 2177, 2229, 2233, 2250, 2254, 2263, 2288, 2321, 2581, 2583, 2616, 2620, 2625, 2630, 2637, 2653, 2685, 2687, 2717, 2739, 2741, 2777, 2790, 2795, 2800, 2809, 2840, 2845, 2849, 2854, 2859, 2866, 2874, 2879, 2886, 3051, 3053, 3064, 3069, 3074, 3079, 3127, 3140, 3145, 3150, 3160, 3199, 3205, 3210, 3214, 3221, 3228, 3234, 3241, 3287, 3300, 3305, 3310, 3320, 3360, 3366, 3371, 3375, 3382, 3389, 3395, 3402, 3444, 3448, 3536, 3548, 3550 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
