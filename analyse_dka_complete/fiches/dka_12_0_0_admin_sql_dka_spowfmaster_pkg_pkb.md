# DKA_SPOWFMASTER_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOWFMASTER_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOWFMASTER_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 3734 ; encodage : cp1252 (repli). SHA-256 : `1f94bacae396e0c9a29d3356527249ec74444dc7e55679811cbf6c98f367802b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `print_log_message` | 71 |
| `configure_env` | 97 |
| `lance_approbation` | 153 |
| `cree_commande` | 520 |
| `recup_commande` | 621 |
| `cree_reception` | 741 |
| `archivage_contrat` | 839 |
| `diminution_quantite` | 897 |
| `diminution_quantite_facture` | 1040 |
| `reception_quantite` | 1137 |
| `lance_workflow_maitre` | 1186 |
| `lance_wf_modif_approbation` | 1268 |
| `lance_wf_resil_annule` | 1361 |
| `get_montant_presta_unit` | 1442 |
| `get_montant_imput` | 1486 |
| `test_modif_champ` | 1585 |
| `controle_statut` | 1805 |
| `modif_statut_incomplet` | 1841 |
| `modif_statut_approuve` | 1916 |
| `verif_date_resiliation` | 1995 |
| `verif_exist_facture` | 2036 |
| `archivage_date_resiliation` | 2089 |
| `approve_version_commande` | 2170 |
| `mise_a_jour_action_noneffec` | 2236 |
| `mise_a_jour_action_resiliation` | 2259 |
| `mise_a_jour_statut_appro` | 2283 |
| `action_fermer` | 2345 |
| `modif_statut_nouvelle_appro` | 2426 |
| `annuler_commande_sans_facture` | 2460 |
| `log_msg` | 2559 |
| `init` | 2583 |
| `INIT` | 2639 |
| `get_message_mail` | 2660 |
| `GET_MESSAGE` | 3165 |
| `search_id_destinataire_mail` | 3188 |
| `search_id_destinataire_mail` | 3288 |
| `search_mail` | 3310 |
| `search_mail` | 3335 |
| `mail_notification` | 3357 |
| `d` | 3454 |
| `de` | 3460 |
| `de` | 3466 |
| `d` | 3472 |
| `mail_notification` | 3486 |
| `envoi_notif_mail` | 3509 |
| `ENVOI_MAIL` | 3566 |
| `active_desactive_site_four` | 3582 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_document_types_all` | 161 |
| `dual` | 206 |
| `po_headers_all` | 240 |
| `hr_all_organization_units_tl` | 423 |
| `po_headers_all` | 441 |
| `po_headers_interface` | 654 |
| `DKA_CONTRAT_SSTR` | 695 |
| `DKA_CONTRAT_SSTR_ARCHI` | 701 |
| `DKA_CONTRAT_SSTR` | 706 |
| `po_headers_all` | 857 |
| `dka_contrat_sstr_archi` | 868 |
| `dka_contrat_sstr` | 870 |
| `dka_contrat_sstr_imput_archi` | 875 |
| `dka_contrat_sstr_imputation` | 877 |
| `dka_contrat_sstr_imputation` | 919 |
| `DKA_CONTRAT_SSTR_ARCHI` | 932 |
| `DKA_CONTRAT_SSTR` | 935 |
| `PO_HEADERS_ALL` | 947 |
| `DKA_CONTRAT_SSTR` | 951 |
| `po_headers_all` | 971 |
| `dka_contrat_sstr_imputation` | 988 |
| `dka_contrat_sstr_imputation` | 1057 |
| `po_headers_all` | 1071 |
| `dka_contrat_sstr_imputation` | 1088 |
| `po_distributions_all` | 1149 |
| `dual` | 1205 |
| `po_headers_all` | 1209 |
| `dual` | 1291 |
| `DKA_CONTRAT_SSTR` | 1298 |
| `dual` | 1384 |
| `DKA_CONTRAT_SSTR` | 1391 |
| `po_headers_all` | 1452 |
| `dka_contrat_sstr_imputation` | 1458 |
| `po_headers_all` | 1508 |
| `dka_contrat_sstr_imput_archi` | 1514 |
| `po_distributions_archive_all` | 1620 |
| `po_headers_all` | 1633 |
| `po_headers_archive_all` | 1646 |
| `po_headers_all` | 1684 |
| `po_headers_all` | 1710 |
| `po_distributions_all` | 1740 |
| `po_distributions_archive_all` | 1745 |
| `po_headers_all` | 1783 |
| `po_headers_all` | 1822 |
| `po_headers_all` | 1860 |
| `po_action_history` | 1869 |
| `po_action_history` | 1890 |
| `fnd_user` | 1897 |
| `po_headers_all` | 1937 |
| `po_action_history` | 1945 |
| `po_action_history` | 1967 |
| `fnd_user` | 1974 |
| `dka_contrat_sstr` | 1975 |
| `dka_contrat_sstr` | 2013 |
| `ap_invoices_all` | 2055 |
| `po_headers_all` | 2115 |
| `dka_contrat_sstr` | 2122 |
| `dka_contrat_sstr_imputation` | 2129 |
| `PO_HEADERS_ALL` | 2193 |
| `po_headers_all` | 2213 |
| `po_headers_all` | 2302 |
| `po_headers_archive_all` | 2305 |
| `po_headers_archive_all` | 2306 |
| `po_headers_archive_all` | 2308 |
| `po_headers_archive_all` | 2310 |
| `po_headers_archive_all` | 2311 |
| `dka_contrat_sstr` | 2314 |
| `dka_contrat_sstr_archi` | 2315 |
| `dka_contrat_sstr_archi` | 2317 |
| `dka_contrat_sstr_archi` | 2319 |
| `dka_contrat_sstr_archi` | 2321 |
| `dka_contrat_sstr_archi` | 2323 |
| `dka_contrat_sstr_imputation` | 2327 |
| `dka_contrat_sstr_imput_archi` | 2328 |
| `po_headers_all` | 2364 |
| `po_action_history` | 2371 |
| `po_action_history` | 2393 |
| `fnd_user` | 2401 |
| `po_headers_all` | 2440 |
| `dka_contrat_sstr` | 2485 |
| `po_headers_all` | 2489 |
| `po_lines_all` | 2498 |
| `po_line_locations_all` | 2511 |
| `po_headers_all` | 2526 |
| `v$database` | 2602 |
| `ap_invoices_all` | 2744 |
| `dka_contrat_sstr_imputation` | 2763 |
| `po_headers_all` | 2794 |
| `po_headers_all` | 2840 |
| `ap_invoices_all` | 2905 |
| `ap_invoices_all` | 2970 |
| `ap_invoices_all` | 3034 |
| `dka_contrat_sstr_imputation` | 3062 |
| `ap_invoices_all` | 3106 |
| `po_headers_all` | 3230 |
| `fnd_user` | 3259 |
| `nvl` | 3321 |
| `fnd_user` | 3324 |
| `v$database` | 3420 |
| `dual` | 3537 |
| `po_headers_all` | 3624 |
| `po_vendor_sites_all` | 3637 |
| `po_vendor_sites_all` | 3660 |
| `po_vendor_sites_all` | 3682 |
| `po_vendor_sites_all` | 3703 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.VALUE` | 55 |
| `fnd_file.put_line` | 84 |
| `wf_engine.getitemattrnumber` | 108 |
| `wf_engine.getitemattrnumber` | 112 |
| `wf_engine.getitemattrnumber` | 116 |
| `po_wf_debug_pkg.insert_debug` | 125 |
| `po_wf_debug_pkg.insert_debug` | 201 |
| `wf_engine.getitemattrnumber` | 208 |
| `wf_engine.getitemattrnumber` | 212 |
| `po_wf_debug_pkg.insert_debug` | 220 |
| `fnd_message.get_string` | 227 |
| `fnd_message.get_string` | 230 |
| `fnd_message.get_string` | 233 |
| `fnd_message.get_string` | 236 |
| `po_wf_debug_pkg.insert_debug` | 261 |
| `po_wf_debug_pkg.insert_debug` | 279 |
| `po_wf_debug_pkg.insert_debug` | 286 |
| `po_wf_debug_pkg.insert_debug` | 302 |
| `wf_engine.createprocess` | 308 |
| `wf_engine.setitemattrtext` | 314 |
| `wf_engine.setitemattrtext` | 319 |
| `wf_engine.setitemattrtext` | 324 |
| `wf_engine.setitemattrtext` | 329 |
| `wf_engine.setitemattrtext` | 334 |
| `wf_engine.setitemattrnumber` | 339 |
| `wf_engine.setitemattrtext` | 344 |
| `wf_engine.setitemattrtext` | 349 |
| `po_vendor_sites_sv.get_transmission_defaults` | 354 |
| `wf_engine.setitemattrnumber` | 363 |
| `wf_engine.setitemattrtext` | 381 |
| `wf_engine.setitemattrtext` | 388 |
| `wf_engine.setitemattrtext` | 394 |
| `wf_engine.setitemattrtext` | 410 |
| `wf_engine.SetItemAttrText` | 415 |
| `wf_engine.SetItemAttrText` | 427 |
| `PO_WF_UTIL_PKG.SetItemAttrText` | 452 |
| `PO_WF_UTIL_PKG.SetItemAttrText` | 453 |
| `wf_engine.setitemuserkey` | 456 |
| `wf_engine.setitemparent` | 467 |
| `wf_engine.startprocess` | 474 |
| `po_wf_debug_pkg.insert_debug` | 496 |
| `wf_core.CONTEXT` | 503 |
| `po_wf_debug_pkg.insert_debug` | 539 |
| `wf_engine.getitemattrnumber` | 544 |
| `po_wf_debug_pkg.insert_debug` | 553 |
| `dka_ipogencom_pkg.main` | 556 |
| `po_wf_debug_pkg.insert_debug` | 569 |
| `wf_engine.setitemattrnumber` | 573 |
| `po_wf_debug_pkg.insert_debug` | 591 |
| `po_wf_debug_pkg.insert_debug` | 605 |
| `wf_core.CONTEXT` | 608 |
| `po_wf_debug_pkg.insert_debug` | 640 |
| `wf_engine.getitemattrnumber` | 643 |
| `po_wf_debug_pkg.insert_debug` | 672 |
| `wf_engine.setitemattrnumber` | 676 |
| `wf_engine.setitemattrnumber` | 682 |
| `wf_engine.getitemattrnumber` | 689 |
| `po_wf_debug_pkg.insert_debug` | 723 |
| `wf_core.CONTEXT` | 726 |
| `po_wf_debug_pkg.insert_debug` | 760 |
| `wf_engine.getitemattrnumber` | 765 |
| `po_wf_debug_pkg.insert_debug` | 774 |
| `dka_iporecvtotal_pkg.main` | 777 |
| `po_wf_debug_pkg.insert_debug` | 789 |
| `wf_engine.setitemattrnumber` | 793 |
| `po_wf_debug_pkg.insert_debug` | 807 |
| `po_wf_debug_pkg.insert_debug` | 822 |
| `wf_core.CONTEXT` | 825 |
| `wf_engine.getitemattrnumber` | 850 |
| `wf_engine.getitemattrnumber` | 925 |
| `wf_engine.getitemattrnumber` | 1063 |
| `wf_engine.getitemattrnumber` | 1154 |
| `wf_engine.createprocess` | 1215 |
| `wf_engine.setitemattrnumber` | 1220 |
| `wf_engine.setitemattrnumber` | 1225 |
| `wf_engine.setitemattrnumber` | 1230 |
| `wf_engine.setitemattrnumber` | 1235 |
| `wf_engine.setitemattrnumber` | 1240 |
| `wf_engine.startprocess` | 1246 |
| `wf_engine.createprocess` | 1306 |
| `wf_engine.setitemattrnumber` | 1312 |
| `wf_engine.setitemattrnumber` | 1317 |
| `wf_engine.setitemattrnumber` | 1322 |
| `wf_engine.setitemattrnumber` | 1327 |
| `wf_engine.setitemattrnumber` | 1332 |
| `wf_engine.startprocess` | 1338 |
| `wf_engine.createprocess` | 1399 |
| `wf_engine.setitemattrnumber` | 1405 |
| `wf_engine.setitemattrnumber` | 1410 |
| `wf_engine.setitemattrnumber` | 1415 |
| `wf_engine.startprocess` | 1421 |
| `wf_engine.getitemattrnumber` | 1816 |
| `wf_engine.getitemattrnumber` | 1852 |
| `wf_engine.getitemattrnumber` | 1856 |
| `wf_engine.getitemattrnumber` | 1927 |
| `wf_engine.getitemattrnumber` | 1932 |
| `wf_engine.getitemattrnumber` | 2005 |
| `wf_engine.getitemattrnumber` | 2047 |
| `wf_engine.setitemattrtext` | 2067 |
| `wf_engine.getitemattrnumber` | 2104 |
| `wf_engine.getitemattrnumber` | 2109 |
| `PO_DOCUMENT_ARCHIVE_PVT.archive_po` | 2143 |
| `wf_engine.getitemattrnumber` | 2185 |
| `wf_engine.getitemattrnumber` | 2189 |
| `PO_DOCUMENT_ARCHIVE_PVT.archive_po` | 2201 |
| `wf_engine.setitemattrtext` | 2216 |
| `wf_engine.setitemattrnumber` | 2221 |
| `wf_engine.setitemattrtext` | 2243 |
| `wf_engine.setitemattrtext` | 2266 |
| `wf_engine.getitemattrnumber` | 2294 |
| `wf_engine.getitemattrnumber` | 2298 |
| `wf_engine.getitemattrnumber` | 2356 |
| `wf_engine.getitemattrnumber` | 2360 |
| `wf_engine.setitemattrtext` | 2408 |
| `wf_engine.getitemattrnumber` | 2436 |
| `wf_engine.setitemattrtext` | 2441 |
| `wf_engine.getitemattrnumber` | 2473 |
| `wf_engine.getitemattrnumber` | 2478 |
| `wf_engine.setitemattrtext` | 2529 |
| `wf_engine.setitemattrnumber` | 2534 |
| `wf_engine.setitemattrnumber` | 2539 |
| `wf_engine.setitemattrtext` | 2544 |
| `fnd_file.put_line` | 2569 |
| `Dka_Tools_Pkg.get_parameter` | 2615 |
| `Dka_Tools_Pkg.get_parameter` | 2625 |
| `DKA_SPOCONTRAT_SSTR_PKG.get_contrat_end_date` | 2801 |
| `DKA_SPOCONTRAT_SSTR_PKG.get_contrat_start_date` | 2803 |
| `Dka_Tools_Pkg.get_message` | 2807 |
| `Dka_Tools_Pkg.get_message` | 2810 |
| `Dka_Tools_Pkg.get_message` | 2812 |
| `Dka_Tools_Pkg.get_message` | 2823 |
| `Dka_Tools_Pkg.get_message` | 2851 |
| `Dka_Tools_Pkg.get_message` | 2854 |
| `Dka_Tools_Pkg.get_message` | 2856 |
| `Dka_Tools_Pkg.get_message` | 2867 |
| `Dka_Tools_Pkg.get_message` | 2875 |
| `Dka_Tools_Pkg.get_message` | 2885 |
| `Dka_Tools_Pkg.get_message` | 2887 |
| `Dka_Tools_Pkg.get_message` | 2896 |
| `Dka_Tools_Pkg.get_message` | 2918 |
| `Dka_Tools_Pkg.get_message` | 2929 |
| `Dka_Tools_Pkg.get_message` | 2932 |
| `Dka_Tools_Pkg.get_message` | 2936 |
| `Dka_Tools_Pkg.get_message` | 2938 |
| `Dka_Tools_Pkg.get_message` | 2949 |
| `Dka_Tools_Pkg.get_message` | 2951 |
| `Dka_Tools_Pkg.get_message` | 2960 |
| `Dka_Tools_Pkg.get_message` | 2982 |
| `Dka_Tools_Pkg.get_message` | 2994 |
| `Dka_Tools_Pkg.get_message` | 2996 |
| `Dka_Tools_Pkg.get_message` | 2999 |
| `Dka_Tools_Pkg.get_message` | 3002 |
| `Dka_Tools_Pkg.get_message` | 3013 |
| `Dka_Tools_Pkg.get_message` | 3015 |
| `Dka_Tools_Pkg.get_message` | 3024 |
| `Dka_Tools_Pkg.get_message` | 3046 |
| `Dka_Tools_Pkg.get_message` | 3057 |
| `dka_spowfmaster_pkg.get_montant_imput` | 3065 |
| `Dka_Tools_Pkg.get_message` | 3067 |
| `Dka_Tools_Pkg.get_message` | 3070 |
| `Dka_Tools_Pkg.get_message` | 3074 |
| `Dka_Tools_Pkg.get_message` | 3085 |
| `Dka_Tools_Pkg.get_message` | 3087 |
| `Dka_Tools_Pkg.get_message` | 3096 |
| `Dka_Tools_Pkg.get_message` | 3118 |
| `Dka_Tools_Pkg.get_message` | 3129 |
| `Dka_Tools_Pkg.get_message` | 3131 |
| `Dka_Tools_Pkg.get_message` | 3134 |
| `Dka_Tools_Pkg.get_message` | 3136 |
| `Dka_Tools_Pkg.get_message` | 3147 |
| `Dka_Tools_Pkg.get_message` | 3158 |
| `wf_engine.getitemattrnumber` | 3379 |
| `wf_engine.GetItemAttrText` | 3384 |
| `Dka_Tools_Pkg.get_parameter` | 3389 |
| `DKA_SEND_MAIL_PKG.mail_test` | 3395 |
| `wf_engine.getitemattrnumber` | 3601 |
| `wf_engine.GetItemAttrText` | 3606 |
| `wf_engine.GetItemAttrText` | 3611 |
| `wf_engine.setitemattrtext` | 3646 |
| `wf_engine.setitemattrtext` | 3668 |
| `wf_engine.setitemattrtext` | 3689 |
| `wf_engine.setitemattrtext` | 3711 |
| `wf_core.CONTEXT` | 3726 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 709, 882, 1249, 1341, 1424, 1904, 1982, 2134, 2209, 2332, 2412, 2445, 3721 |
| when_others | 462, 501, 597, 714, 813, 860, 939, 956, 976, 1076, 1252, 1344, 1427, 1790, 2604, 2638, 3164, 3287, 3334, 3422, 3485, 3565, 3725 |
| workflow | 108, 112, 116, 208, 212, 308, 314, 319, 324, 329, 334, 339, 344, 349, 363, 381, 388, 394, 410, 415, 427, 456, 467, 474, 478, 481, 489, 502, 544, 573, 582, 594, 598, 643, 663, 676, 682, 689, 711, 715, 765, 793, 798, 810, 814, 850, 925, 955, 957, 961, 963, 1023, 1025, 1063, 1121, 1123, 1154, 1168, 1170, 1215, 1220, 1225, 1230, 1235, 1240, 1246, 1306, 1312, 1317, 1322, 1327, 1332, 1338, 1399, 1405, 1410, 1415, 1421, 1816, 1827, 1852, 1856, 1927, 1932, 1983, 2005, 2019, 2022, 2047, 2066, 2067, 2073, 2104, 2109, 2185, 2189, 2216, 2221, 2243, 2266, 2294, 2298, 2356, 2360, 2408, 2436, 2441, 2473, 2478, 2529, 2534, 2539, 2544, 3379, 3384, 3601, 3606, 3611, 3646, 3668, 3689, 3711 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
