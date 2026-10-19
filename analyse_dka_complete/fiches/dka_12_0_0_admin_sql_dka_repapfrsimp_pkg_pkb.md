# DKA_REPAPFRSIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPAPFRSIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPAPFRSIMP_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 4648 ; encodage : cp1252 (repli). SHA-256 : `c495b5001e5e10ce53c9c804467defecde2d9962d7ae1ccbcfd77f4461e0e6c4`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 151 |
| `init_environement` | 250 |
| `Launch_Loader` | 342 |
| `Report_Bilan` | 454 |
| `liste_des_anomalies` | 536 |
| `program_import_fournisseur` | 743 |
| `program_import_site_four` | 898 |
| `wait_sites_import` | 946 |
| `program_import_contact_four` | 1055 |
| `purge_data` | 1209 |
| `to_az` | 1317 |
| `validate_fournisseur` | 1346 |
| `validate_site_fournisseur` | 1408 |
| `validate_contact_site_f` | 1493 |
| `validate_banque` | 1557 |
| `insert_ap_suppliers_int` | 1620 |
| `insert_ap_supplier_sites_int` | 1656 |
| `insert_ap_sup_site_contact_int` | 1693 |
| `insert_factor_int` | 1729 |
| `create_contact_point` | 1913 |
| `create_phone_fax_email` | 1990 |
| `get_terms_id` | 2067 |
| `MAIN` | 2104 |
| `update_parent_vendor` | 4511 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_ap_rep_supp_tmp` | 202 |
| `dka_ap_rep_supp_sites_tmp` | 206 |
| `dka_ap_rep_supp_sites_ctct_tmp` | 210 |
| `DKA_AP_REP_SUPP_BANK_TMP` | 214 |
| `fnd_responsibility` | 302 |
| `dka_ap_rep_supp_tmp` | 417 |
| `dka_ap_rep_supp_sites_tmp` | 419 |
| `dka_ap_rep_supp_sites_ctct_tmp` | 421 |
| `dka_ap_rep_supp_bank_tmp` | 423 |
| `dka_ap_rep_supp_tmp` | 548 |
| `DKA_AP_REP_SUPP_REJECTION` | 556 |
| `DKA_AP_REP_SUPP_SITES_TMP` | 567 |
| `DKA_AP_REP_SUPP_REJECTION` | 577 |
| `DKA_AP_REP_SUPP_SITES_CTCT_TMP` | 596 |
| `DKA_AP_REP_SUPP_REJECTION` | 607 |
| `dka_ap_rep_supp_bank_tmp` | 623 |
| `ap_suppliers_int` | 804 |
| `ap_suppliers_int` | 810 |
| `DKA_AP_REP_SUPP_REJECTION` | 842 |
| `ap_supplier_int_rejections` | 849 |
| `ap_supplier_sites_int` | 983 |
| `ap_supplier_sites_int` | 1014 |
| `DKA_AP_REP_SUPP_REJECTION` | 1020 |
| `ap_supplier_int_rejections` | 1027 |
| `ap_sup_site_contact_int` | 1115 |
| `ap_sup_site_contact_int` | 1122 |
| `DKA_AP_REP_SUPP_REJECTION` | 1155 |
| `ap_supplier_int_rejections` | 1162 |
| `DKA_AP_REP_SUPP_SITES_CTCT_TMP` | 1234 |
| `AP_SUP_SITE_CONTACT_INT` | 1238 |
| `AP_SUP_SITE_CONTACT_INT` | 1250 |
| `DKA_AP_REP_SUPP_SITES_TMP` | 1257 |
| `AP_SUPPLIER_SITES_INT` | 1262 |
| `AP_SUPPLIER_SITES_INT` | 1270 |
| `DKA_AP_REP_SUPP_TMP` | 1278 |
| `AP_SUPPLIERS_INT` | 1283 |
| `AP_SUPPLIERS_INT` | 1287 |
| `AP_SUPPLIER_INT_REJECTIONS` | 1293 |
| `DKA_AP_REP_SUPP_REJECTION` | 1296 |
| `dka_ap_rep_supp_tmp` | 1362 |
| `dka_ap_rep_supp_tmp` | 1378 |
| `dka_ap_rep_supp_sites_tmp` | 1426 |
| `dka_dup_site_fournisseur` | 1435 |
| `dka_ap_rep_supp_sites_tmp` | 1452 |
| `dka_dup_site_fournisseur` | 1461 |
| `dka_ap_rep_supp_sites_ctct_tmp` | 1510 |
| `dka_ap_rep_supp_sites_ctct_tmp` | 1527 |
| `dka_ap_rep_supp_bank_tmp` | 1574 |
| `dka_ap_rep_supp_bank_tmp` | 1590 |
| `ap_suppliers_int` | 1627 |
| `ap_supplier_sites_int` | 1662 |
| `ap_sup_site_contact_int` | 1699 |
| `ap_suppliers` | 1756 |
| `ap_suppliers_int` | 1768 |
| `ap_supplier_sites_int` | 1810 |
| `ap_supplier_sites_all` | 1821 |
| `ap_supplier_sites_int` | 1825 |
| `ap_supplier_sites_int` | 1846 |
| `ap_supplier_sites_all` | 1851 |
| `ap_terms` | 2074 |
| `dka_ap_rep_supp_tmp` | 2188 |
| `dka_ap_rep_supp_sites_tmp` | 2191 |
| `dka_ap_rep_supp_sites_ctct_tmp` | 2195 |
| `dka_ap_rep_supp_sites_tmp` | 2202 |
| `dka_ap_rep_supp_sites_ctct_tmp` | 2207 |
| `dka_ap_rep_supp_sites_ctct_tmp` | 2214 |
| `dka_ap_rep_supp_sites_tmp` | 2222 |
| `dka_ap_rep_supp_bank_tmp` | 2231 |
| `fnd_flex_value_sets` | 2237 |
| `fnd_flex_values` | 2238 |
| `ap_suppliers` | 2366 |
| `ap_suppliers_int` | 2376 |
| `dka_ap_rep_supp_tmp` | 2495 |
| `dka_ap_rep_supp_sites_tmp` | 2497 |
| `dka_rep_transco_lines` | 2539 |
| `ap_suppliers_int` | 2596 |
| `ap_suppliers` | 2601 |
| `ap_suppliers` | 2639 |
| `ap_supplier_sites_int` | 2661 |
| `ap_supplier_sites_all` | 2672 |
| `ap_supplier_sites_int` | 2676 |
| `ap_supplier_sites_int` | 2693 |
| `ap_supplier_sites_all` | 2698 |
| `DUAL` | 2782 |
| `hr_operating_units` | 2869 |
| `gl_code_combinations` | 2940 |
| `dka_ap_rep_supp_sites_tmp` | 3053 |
| `dka_ap_rep_supp_sites_tmp` | 3112 |
| `ap_supplier_sites_int` | 3125 |
| `ap_supplier_sites_all` | 3130 |
| `ap_suppliers` | 3199 |
| `ap_suppliers_int` | 3200 |
| `DKA_AP_REP_SUPP_REJECTION` | 3307 |
| `ap_suppliers` | 3489 |
| `dka_ap_rep_supp_sites_tmp` | 3501 |
| `dka_ap_rep_supp_sites_tmp` | 3508 |
| `dka_ap_rep_supp_sites_tmp` | 3515 |
| `ap_suppliers` | 3528 |
| `dka_ap_rep_supp_sites_tmp` | 3539 |
| `dka_ap_rep_supp_sites_tmp` | 3546 |
| `dka_ap_rep_supp_sites_tmp` | 3553 |
| `dka_ap_rep_supp_sites_tmp` | 3610 |
| `hr_operating_units` | 3925 |
| `ap_suppliers` | 3979 |
| `ap_suppliers` | 3999 |
| `dka_ap_rep_supp_bank_tmp` | 4293 |
| `ap_suppliers` | 4316 |
| `dka_ap_rep_supp_sites_tmp` | 4318 |
| `ap_supplier_sites_all` | 4330 |
| `ap_suppliers` | 4340 |
| `iby_ext_payee_relationships` | 4356 |
| `iby_ext_payee_relationships` | 4368 |
| `dka_ap_rep_supp_tmp` | 4518 |
| `AP_SUPPLIERS` | 4557 |
| `PO_VENDORS` | 4575 |
| `AP_SUPPLIERS` | 4592 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_log_message` | 227 |
| `fnd_global.apps_initialize` | 305 |
| `Dka_Tools_Pkg.put_log_message` | 307 |
| `Dka_Tools_Pkg.put_log_message` | 314 |
| `Dka_Tools_Pkg.put_log_message` | 318 |
| `Dka_Tools_Pkg.put_log_message` | 353 |
| `Dka_Tools_Pkg.put_log_message` | 356 |
| `Dka_Tools_Pkg.put_log_message` | 357 |
| `Dka_Tools_Pkg.put_log_message` | 358 |
| `Fnd_Request.submit_request` | 364 |
| `Dka_Tools_Pkg.put_outdebug_message` | 372 |
| `Dka_Tools_Pkg.put_outdebug_message` | 377 |
| `Dka_Tools_Pkg.put_log_message` | 379 |
| `Fnd_Concurrent.wait_for_request` | 385 |
| `Dka_Tools_Pkg.put_outdebug_message` | 388 |
| `Dka_Tools_Pkg.put_outdebug_message` | 394 |
| `Dka_Tools_Pkg.put_log_message` | 395 |
| `Dka_Tools_Pkg.put_outdebug_message` | 401 |
| `Dka_Tools_Pkg.put_outdebug_message` | 409 |
| `Dka_Tools_Pkg.put_log_message` | 412 |
| `Dka_Tools_Pkg.put_log_message` | 427 |
| `Dka_Tools_Pkg.put_log_message` | 434 |
| `Dka_Tools_Pkg.put_log_message` | 435 |
| `Dka_Tools_Pkg.put_log_message` | 461 |
| `Dka_Tools_Pkg.put_outdebug_message` | 471 |
| `Dka_Tools_Pkg.put_outdebug_message` | 472 |
| `Dka_Tools_Pkg.put_outdebug_message` | 473 |
| `Dka_Tools_Pkg.put_outdebug_message` | 474 |
| `Dka_Tools_Pkg.put_outdebug_message` | 475 |
| `Dka_Tools_Pkg.put_outdebug_message` | 476 |
| `Dka_Tools_Pkg.put_outdebug_message` | 477 |
| `Dka_Tools_Pkg.put_outdebug_message` | 478 |
| `Dka_Tools_Pkg.put_outdebug_message` | 480 |
| `Dka_Tools_Pkg.put_outdebug_message` | 481 |
| `Dka_Tools_Pkg.put_outdebug_message` | 482 |
| `Dka_Tools_Pkg.put_outdebug_message` | 484 |
| `Dka_Tools_Pkg.put_outdebug_message` | 485 |
| `Dka_Tools_Pkg.put_outdebug_message` | 486 |
| `Dka_Tools_Pkg.put_outdebug_message` | 487 |
| `Dka_Tools_Pkg.put_outdebug_message` | 488 |
| `Dka_Tools_Pkg.put_outdebug_message` | 489 |
| `Dka_Tools_Pkg.put_outdebug_message` | 491 |
| `Dka_Tools_Pkg.put_outdebug_message` | 492 |
| `Dka_Tools_Pkg.put_outdebug_message` | 493 |
| `Dka_Tools_Pkg.put_outdebug_message` | 495 |
| `Dka_Tools_Pkg.put_outdebug_message` | 496 |
| `Dka_Tools_Pkg.put_outdebug_message` | 497 |
| `Dka_Tools_Pkg.put_outdebug_message` | 498 |
| `Dka_Tools_Pkg.put_outdebug_message` | 499 |
| `Dka_Tools_Pkg.put_outdebug_message` | 500 |
| `Dka_Tools_Pkg.put_outdebug_message` | 501 |
| `Dka_Tools_Pkg.put_outdebug_message` | 502 |
| `Dka_Tools_Pkg.put_log_message` | 508 |
| `Dka_Tools_Pkg.put_log_message` | 509 |
| `Dka_Tools_Pkg.put_log_message` | 517 |
| `Dka_Tools_Pkg.put_log_message` | 518 |
| `Dka_Tools_Pkg.put_log_message` | 630 |
| `Dka_Tools_Pkg.put_outdebug_message` | 640 |
| `Dka_Tools_Pkg.put_outdebug_message` | 643 |
| `Dka_Tools_Pkg.put_outdebug_message` | 645 |
| `Dka_Tools_Pkg.put_outdebug_message` | 647 |
| `Dka_Tools_Pkg.put_outdebug_message` | 649 |
| `Dka_Tools_Pkg.put_outdebug_message` | 653 |
| `Dka_Tools_Pkg.put_outdebug_message` | 656 |
| `Dka_Tools_Pkg.put_outdebug_message` | 658 |
| `Dka_Tools_Pkg.put_outdebug_message` | 660 |
| `Dka_Tools_Pkg.put_outdebug_message` | 662 |
| `Dka_Tools_Pkg.put_outdebug_message` | 664 |
| `Dka_Tools_Pkg.put_outdebug_message` | 671 |
| `Dka_Tools_Pkg.put_outdebug_message` | 675 |
| `Dka_Tools_Pkg.put_outdebug_message` | 677 |
| `Dka_Tools_Pkg.put_outdebug_message` | 679 |
| `Dka_Tools_Pkg.put_outdebug_message` | 681 |
| `Dka_Tools_Pkg.put_outdebug_message` | 683 |
| `Dka_Tools_Pkg.put_outdebug_message` | 692 |
| `Dka_Tools_Pkg.put_outdebug_message` | 695 |
| `Dka_Tools_Pkg.put_outdebug_message` | 697 |
| `Dka_Tools_Pkg.put_outdebug_message` | 699 |
| `Dka_Tools_Pkg.put_outdebug_message` | 701 |
| `Dka_Tools_Pkg.put_outdebug_message` | 703 |
| `Dka_Tools_Pkg.put_outdebug_message` | 710 |
| `Dka_Tools_Pkg.put_log_message` | 716 |
| `Dka_Tools_Pkg.put_log_message` | 717 |
| `Dka_Tools_Pkg.put_log_message` | 725 |
| `Dka_Tools_Pkg.put_log_message` | 726 |
| `Dka_Tools_Pkg.put_log_message` | 757 |
| `FND_REQUEST.SUBMIT_REQUEST` | 759 |
| `Dka_Tools_Pkg.put_outdebug_message` | 772 |
| `Dka_Tools_Pkg.put_outdebug_message` | 776 |
| `Dka_Tools_Pkg.put_log_message` | 778 |
| `Fnd_Concurrent.wait_for_request` | 789 |
| `Dka_Tools_Pkg.put_outdebug_message` | 792 |
| `Dka_Tools_Pkg.put_outdebug_message` | 798 |
| `Dka_Tools_Pkg.put_log_message` | 799 |
| `Dka_Tools_Pkg.put_outdebug_message` | 862 |
| `Dka_Tools_Pkg.put_outdebug_message` | 871 |
| `Dka_Tools_Pkg.put_log_message` | 880 |
| `Dka_Tools_Pkg.put_log_message` | 906 |
| `Fnd_Request.submit_request` | 907 |
| `Dka_Tools_Pkg.put_outdebug_message` | 921 |
| `Dka_Tools_Pkg.put_outdebug_message` | 926 |
| `Dka_Tools_Pkg.put_log_message` | 928 |
| `Fnd_Concurrent.wait_for_request` | 964 |
| `Dka_Tools_Pkg.put_outdebug_message` | 973 |
| `Dka_Tools_Pkg.put_outdebug_message` | 979 |
| `Dka_Tools_Pkg.put_outdebug_message` | 992 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1001 |
| `Dka_Tools_Pkg.put_log_message` | 1069 |
| `Fnd_Request.submit_request` | 1070 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1084 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1089 |
| `Fnd_Concurrent.wait_for_request` | 1102 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1105 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1111 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1176 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1185 |
| `Dka_Tools_Pkg.put_log_message` | 1193 |
| `Dka_Tools_Pkg.put_log_message` | 1215 |
| `Dka_Tools_Pkg.put_log_message` | 1253 |
| `Dka_Tools_Pkg.put_log_message` | 1273 |
| `Dka_Tools_Pkg.put_log_message` | 1290 |
| `Dka_Tools_Pkg.put_log_message` | 1301 |
| `Dka_Tools_Pkg.put_log_message` | 1635 |
| `Dka_Tools_Pkg.put_log_message` | 1636 |
| `Dka_Tools_Pkg.put_log_message` | 1671 |
| `Dka_Tools_Pkg.put_log_message` | 1672 |
| `Dka_Tools_Pkg.put_log_message` | 1708 |
| `Dka_Tools_Pkg.put_log_message` | 1709 |
| `Dka_Tools_Pkg.put_log_message` | 1800 |
| `hz_contact_point_v2pub.create_contact_point` | 1934 |
| `Dka_Tools_Pkg.put_log_message` | 1948 |
| `fnd_msg_pub.get` | 1952 |
| `Dka_Tools_Pkg.put_log_message` | 1963 |
| `Dka_Tools_Pkg.put_log_message` | 1971 |
| `Dka_Tools_Pkg.put_log_message` | 2049 |
| `Dka_Tools_Pkg.put_log_message` | 2081 |
| `Dka_Tools_Pkg.put_log_message` | 2084 |
| `Dka_Tools_Pkg.put_log_message` | 2085 |
| `Dka_Tools_Pkg.put_log_message` | 2252 |
| `Dka_Tools_Pkg.put_log_message` | 2253 |
| `Dka_Tools_Pkg.put_log_message` | 2254 |
| `Dka_Tools_Pkg.put_log_message` | 2255 |
| `Dka_Tools_Pkg.put_log_message` | 2256 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2258 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2259 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2260 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2261 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2262 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2263 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2266 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2267 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2268 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2269 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2270 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2271 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2272 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2273 |
| `Dka_Tools_Pkg.put_log_message` | 2277 |
| `Dka_Tools_Pkg.put_log_message` | 2278 |
| `Dka_Tools_Pkg.put_log_message` | 2279 |
| `Dka_Tools_Pkg.put_log_message` | 2280 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2282 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2283 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2284 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2290 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2303 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2304 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2305 |
| `Dka_Tools_Pkg.put_log_message` | 2306 |
| `Dka_Tools_Pkg.put_log_message` | 2307 |
| `Dka_Tools_Pkg.put_log_message` | 2308 |
| `Dka_Tools_Pkg.put_log_message` | 2309 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2319 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2322 |
| `Dka_Tools_Pkg.put_log_message` | 2337 |
| `Dka_Tools_Pkg.put_log_message` | 2338 |
| `Dka_Tools_Pkg.put_log_message` | 2339 |
| `Dka_Tools_Pkg.put_log_message` | 2340 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2341 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2342 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2343 |
| `Dka_Tools_Pkg.put_log_message` | 2344 |
| `Dka_Tools_Pkg.put_log_message` | 2349 |
| `dka_rep_transco_pkg.get_transco` | 2399 |
| `dka_rep_transco_pkg.get_transco` | 2427 |
| `dka_rep_transco_pkg.get_transco` | 2432 |
| `dka_rep_transco_pkg.get_transco` | 2439 |
| `dka_rep_transco_pkg.get_transco` | 2445 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2506 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2507 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2508 |
| `dka_rep_transco_pkg.get_transco` | 2747 |
| `dka_rep_transco_pkg.get_transco` | 2752 |
| `dka_rep_transco_pkg.get_transco` | 2765 |
| `dka_rep_transco_pkg.get_transco` | 2776 |
| `dka_rep_transco_pkg.get_transco` | 2860 |
| `dka_rep_transco_pkg.get_transco` | 2917 |
| `dka_rep_transco_pkg.get_cle_transco_f` | 2921 |
| `dka_rep_transco_pkg.get_transco` | 2976 |
| `dka_rep_transco_pkg.get_cle_transco_f` | 2980 |
| `dka_rep_transco_pkg.get_transco` | 3012 |
| `dka_rep_transco_pkg.get_cle_transco_f` | 3016 |
| `Dka_Tools_Pkg.put_log_message` | 3271 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3281 |
| `Dka_Tools_Pkg.put_log_message` | 3282 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3284 |
| `Dka_Tools_Pkg.put_log_message` | 3285 |
| `Dka_Tools_Pkg.put_log_message` | 3287 |
| `Dka_Tools_Pkg.put_log_message` | 3296 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3297 |
| `Dka_Tools_Pkg.put_log_message` | 3298 |
| `Dka_Tools_Pkg.put_log_message` | 3299 |
| `Dka_Tools_Pkg.put_log_message` | 3300 |
| `Dka_Tools_Pkg.put_log_message` | 3301 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3302 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3303 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3304 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3335 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3337 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3411 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3413 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3466 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3468 |
| `Dka_Tools_Pkg.put_log_message` | 3470 |
| `Dka_Tools_Pkg.put_log_message` | 3477 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3562 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3564 |
| `Dka_Tools_Pkg.put_log_message` | 3566 |
| `Dka_Tools_Pkg.put_log_message` | 3573 |
| `Dka_Tools_Pkg.put_log_message` | 3575 |
| `Dka_Tools_Pkg.put_log_message` | 3576 |
| `Dka_Tools_Pkg.put_log_message` | 3577 |
| `Dka_Tools_Pkg.put_log_message` | 3579 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3580 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3581 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3582 |
| `iby_ext_bankacct_pub.check_bank_exist` | 3642 |
| `iby_ext_bankacct_pub.check_bank_exist` | 3659 |
| `iby_ext_bankacct_pub.check_ext_bank_branch_exist` | 3751 |
| `iby_ext_bankacct_pub.check_ext_bank_branch_exist` | 3766 |
| `dka_rep_transco_pkg.get_transco` | 3918 |
| `iby_ext_bankacct_pub.check_ext_acct_exist` | 4036 |
| `iby_ext_bankacct_pub.create_ext_bank_acct` | 4050 |
| `fnd_msg_pub.get` | 4093 |
| `iby_ext_bankacct_pub.check_bank_acct_owner` | 4127 |
| `iby_ext_bankacct_pub.add_joint_account_owner` | 4140 |
| `fnd_msg_pub.get` | 4167 |
| `iby_disbursement_setup_pub.set_payee_instr_assignment` | 4216 |
| `fnd_msg_pub.get` | 4249 |
| `Dka_Tools_Pkg.put_log_message` | 4279 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4286 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4288 |
| `Dka_Tools_Pkg.put_log_message` | 4296 |
| `Dka_Tools_Pkg.put_log_message` | 4304 |
| `Dka_Tools_Pkg.put_log_message` | 4305 |
| `Dka_Tools_Pkg.put_log_message` | 4306 |
| `Dka_Tools_Pkg.put_log_message` | 4307 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4308 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4309 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4310 |
| `Dka_Tools_Pkg.put_log_message` | 4311 |
| `Dka_Tools_Pkg.put_log_message` | 4412 |
| `Dka_Tools_Pkg.put_log_message` | 4418 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4451 |
| `Dka_Tools_Pkg.put_log_message` | 4452 |
| `Dka_Tools_Pkg.put_log_message` | 4453 |
| `Dka_Tools_Pkg.put_log_message` | 4454 |
| `Dka_Tools_Pkg.put_log_message` | 4455 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4462 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4463 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4464 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4465 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4466 |
| `Dka_Tools_Pkg.put_log_message` | 4467 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4468 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4469 |
| `Dka_Tools_Pkg.put_log_message` | 4470 |
| `Dka_Tools_Pkg.put_log_message` | 4471 |
| `Dka_Tools_Pkg.put_log_message` | 4472 |
| `Dka_Tools_Pkg.put_log_message` | 4473 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4480 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4481 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4482 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4483 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4484 |
| `Dka_Tools_Pkg.put_log_message` | 4485 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4486 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4487 |
| `Dka_Tools_Pkg.put_log_message` | 4488 |
| `Dka_Tools_Pkg.put_log_message` | 4489 |
| `Dka_Tools_Pkg.put_log_message` | 4490 |
| `Dka_Tools_Pkg.put_log_message` | 4563 |
| `Dka_Tools_Pkg.put_log_message` | 4569 |
| `Dka_Tools_Pkg.put_log_message` | 4581 |
| `Dka_Tools_Pkg.put_log_message` | 4587 |
| `Dka_Tools_Pkg.put_log_message` | 4613 |
| `Fnd_File.put_line` | 4614 |
| `Fnd_File.put_line` | 4615 |
| `Fnd_File.put_line` | 4619 |
| `Fnd_File.put_line` | 4620 |
| `Fnd_File.put_line` | 4621 |
| `Fnd_File.put_line` | 4622 |
| `Fnd_File.put_line` | 4624 |
| `Fnd_File.put_line` | 4625 |
| `Fnd_File.put_line` | 4627 |
| `Fnd_File.put_line` | 4628 |
| `Fnd_File.put_line` | 4631 |
| `Fnd_File.put_line` | 4636 |
| `Dka_Tools_Pkg.put_log_message` | 4642 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_REPAPFRSIMP_LOADER` | 364 |
| `APXSUIMP` | 759 |
| `APXSSIMP` | 907 |
| `APXSCIMP` | 1070 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 218, 381, 781, 931, 1094, 4066, 4153, 4400, 4450 |
| rollback | 2957, 2993, 3029, 3061, 3074, 3090, 4474, 4491 |
| when_others | 228, 319, 430, 513, 721, 1370, 1386, 1444, 1470, 1519, 1535, 1582, 1598, 1634, 1670, 1707, 1799, 1856, 1970, 2048, 2083, 2369, 2379, 2544, 2605, 2703, 2951, 2956, 2992, 3028, 3136, 3212, 3497, 3535, 4020, 4402, 4476, 4565, 4583, 4639 |
| suppression | 1250, 1270, 1287, 1293, 1296, 3307 |
| soumission | 364, 759, 907, 1070 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPAPFRSIMP / DKA | `DKA_REPAPFRSIMP_PKG.MAIN` | dka/12.0.0/admin/import/DKA_REPAPFRSIMP.prt:557 |
| DKA_REPAPFRSMAJ / DKA | `DKA_REPAPFRSIMP_PKG.update_parent_vendor` | dka/12.0.0/admin/import/DKA_REPAPFRSMAJ.prt:420 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
