# DKA_FUSION_AR_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_FUSION_AR_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_FUSION_AR_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 6498 ; encodage : cp1252 (repli). SHA-256 : `15b6584fae023cd48360e2eeea4df62a033e1f05d67b57a29f1a6d9ee74b89a0`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `debug` | 79 |
| `message` | 95 |
| `squelette_proc` | 114 |
| `initialisation` | 145 |
| `Site_Clients_Absorbante` | 229 |
| `init_facture` | 349 |
| `get_montant_reglement` | 638 |
| `get_montant_ajustement` | 675 |
| `liste_reglement` | 714 |
| `liste_facture` | 1039 |
| `extraction` | 1076 |
| `existence_banque` | 1109 |
| `mode_reglement` | 1180 |
| `categories` | 1350 |
| `sequences` | 1418 |
| `edition_liste_facture` | 1525 |
| `edition_liste_noncompta` | 1619 |
| `type_mvt` | 1783 |
| `origine_mvt` | 1893 |
| `sites_clients` | 1968 |
| `prelevement` | 2054 |
| `absorbee_absorbante` | 2118 |
| `code_tva` | 2206 |
| `valeur_valide` | 2288 |
| `valeur_generique` | 2391 |
| `creation_ccid` | 2442 |
| `init_nouveau_ccid` | 2558 |
| `maj_nouveau_ccid` | 2824 |
| `maj_ccid` | 3103 |
| `combinaison` | 3160 |
| `maj_fact_manuelle` | 3195 |
| `verif_reliquat` | 3309 |
| `encaissement` | 3358 |
| `reglt_part` | 3413 |
| `controle` | 3598 |
| `conv_reliquats` | 3769 |
| `maj_montant` | 3816 |
| `conv_avoir_facture` | 3869 |
| `insertion_facture` | 3913 |
| `get_ccid_tax` | 4280 |
| `insertion_reglement` | 4735 |
| `maj_montant_dist` | 5030 |
| `insertion` | 5092 |
| `annulation` | 5125 |
| `maj_factures` | 5217 |
| `post_fusion` | 5498 |
| `Controle_client_groupe` | 5542 |
| `liste_mvts` | 5631 |
| `lettrage` | 5777 |
| `edition` | 6047 |
| `MAIN` | 6100 |
| `CTR` | 6203 |
| `FUSION` | 6256 |
| `ANNULATION_REGLEMENTS` | 6312 |
| `POST_FUSION_AR` | 6362 |
| `LISTE_MOUVEMENTS` | 6413 |
| `LETTRAGE_ZERO` | 6456 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_AR_FUSION_REC_CTRL_TEMP` | 165 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 169 |
| `DKA_AR_FUSION_GCC_TEMP` | 173 |
| `DKA_AR_FUSION_MVT_LETTRAGE_0` | 177 |
| `DKA_AR_FUSION_FFV_TEMP` | 181 |
| `gl_period_statuses` | 188 |
| `dka_ar_fusion_inv_ctrl_temp` | 197 |
| `dka_ar_fusion_rec_ctrl_temp` | 198 |
| `dka_ar_fusion_gcc_temp` | 199 |
| `dka_ar_fusion_mvt_lettrage_0` | 200 |
| `dka_ar_fusion_ffv_temp` | 201 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 241 |
| `hz_cust_site_uses_all` | 258 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 277 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 306 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 357 |
| `ra_cust_trx_line_gl_dist_all` | 462 |
| `dka_ar_fusion_inv_ctrl_temp` | 506 |
| `OF` | 511 |
| `hr_operating_units` | 588 |
| `hr_operating_units` | 593 |
| `dka_ar_fusion_inv_ctrl_temp` | 596 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 645 |
| `ar_receivable_applications_all` | 648 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 682 |
| `ar_adjustments_all` | 685 |
| `DKA_AR_FUSION_REC_CTRL_TEMP` | 720 |
| `ar_receivable_applications_all` | 764 |
| `ar_receivable_applications_all` | 830 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 839 |
| `dka_ar_fusion_rec_ctrl_temp` | 881 |
| `dka_ar_fusion_rec_ctrl_temp` | 885 |
| `dka_ar_fusion_rec_ctrl_temp` | 901 |
| `dka_ar_fusion_rec_ctrl_temp` | 912 |
| `ar_receipt_method_accounts_all` | 926 |
| `dka_ar_fusion_rec_ctrl_temp` | 930 |
| `dka_ar_fusion_rec_ctrl_temp` | 941 |
| `gl_period_statuses` | 957 |
| `gl_period_statuses` | 968 |
| `dka_ar_fusion_rec_ctrl_temp` | 974 |
| `gl_period_statuses` | 992 |
| `gl_period_statuses` | 1007 |
| `dka_ar_fusion_rec_ctrl_temp` | 1014 |
| `CE_BANK_ACCOUNTS` | 1118 |
| `ce_bank_accounts` | 1131 |
| `ar_receipt_method_accounts_all` | 1195 |
| `ar_receipt_methods` | 1226 |
| `ar_receipt_methods` | 1230 |
| `ar_receipt_methods` | 1236 |
| `dka_ar_fusion_rec_ctrl_temp` | 1282 |
| `ar_receipt_methods` | 1285 |
| `ar_receipt_methods` | 1298 |
| `ar_receipt_methods` | 1358 |
| `fnd_doc_sequence_categories` | 1362 |
| `ar_receipt_methods` | 1426 |
| `fnd_doc_sequence_assignments` | 1429 |
| `dka_ar_fusion_inv_ctrl_temp` | 1441 |
| `fnd_doc_sequence_assignments` | 1445 |
| `dual` | 1533 |
| `dka_ar_fusion_inv_ctrl_temp` | 1552 |
| `dka_ar_fusion_inv_ctrl_temp` | 1575 |
| `dual` | 1586 |
| `dual` | 1593 |
| `ra_cust_trx_line_gl_dist_all` | 1626 |
| `dual` | 1668 |
| `dual` | 1675 |
| `ar_adjustments_all` | 1683 |
| `ra_customer_trx_all` | 1687 |
| `ar_receivable_applications_all` | 1700 |
| `ra_customer_trx_all` | 1704 |
| `dual` | 1741 |
| `dual` | 1756 |
| `ra_cust_trx_types_all` | 1788 |
| `ra_cust_trx_types_all` | 1793 |
| `dka_ar_fusion_inv_ctrl_temp` | 1798 |
| `ra_cust_trx_types_all` | 1806 |
| `dka_ar_fusion_inv_ctrl_temp` | 1854 |
| `ra_cust_trx_types_all` | 1857 |
| `ra_cust_trx_types_all` | 1861 |
| `dka_ar_fusion_inv_ctrl_temp` | 1864 |
| `ra_cust_trx_types_all` | 1867 |
| `ra_batch_sources_all` | 1898 |
| `ra_batch_sources_all` | 1905 |
| `dka_ar_fusion_inv_ctrl_temp` | 1911 |
| `hz_locations` | 1977 |
| `hz_locations` | 1991 |
| `dka_ar_fusion_rec_ctrl_temp` | 2059 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 2123 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 2131 |
| `dka_ar_fusion_inv_ctrl_temp` | 2212 |
| `zx_accounts` | 2223 |
| `dka_ar_fusion_inv_ctrl_temp` | 2244 |
| `zx_rates_b` | 2247 |
| `fnd_id_flex_segments` | 2314 |
| `dka_ar_fusion_ffv_temp` | 2333 |
| `fnd_flex_values` | 2349 |
| `dka_stransco_headers` | 2404 |
| `dka_ar_fusion_gcc_temp` | 2447 |
| `gl_code_combinations` | 2486 |
| `dka_ar_fusion_gcc_temp` | 2489 |
| `gl_code_combinations` | 2528 |
| `dka_ar_fusion_gcc_temp` | 2532 |
| `dka_ar_fusion_gcc_temp` | 2579 |
| `dka_ar_fusion_gcc_temp` | 2852 |
| `of` | 2853 |
| `dka_ar_fusion_gcc_temp` | 2966 |
| `gl_code_combinations` | 2971 |
| `gl_code_combinations` | 2975 |
| `gl_code_combinations` | 2979 |
| `dka_ar_fusion_gcc_temp` | 3059 |
| `gl_code_combinations` | 3064 |
| `gl_code_combinations` | 3068 |
| `gl_code_combinations` | 3072 |
| `gl_code_combinations` | 3109 |
| `dka_ar_fusion_gcc_temp` | 3115 |
| `gl_code_combinations` | 3124 |
| `dka_ar_fusion_gcc_temp` | 3130 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 3210 |
| `ra_batch_sources_all` | 3229 |
| `ra_batch_sources_all` | 3251 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 3274 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 3315 |
| `dka_ar_fusion_rec_ctrl_temp` | 3364 |
| `dka_ar_fusion_rec_ctrl_temp` | 3438 |
| `ar_receivable_applications_all` | 3458 |
| `dka_ar_fusion_rec_ctrl_temp` | 3474 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 3774 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 3786 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 3824 |
| `dka_ar_fusion_inv_ctrl_temp` | 3832 |
| `dka_ar_fusion_inv_ctrl_temp` | 3841 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 3876 |
| `ra_cust_trx_types_all` | 3879 |
| `dka_stransco_lines` | 3885 |
| `dka_ar_fusion_inv_ctrl_temp` | 3950 |
| `gl_period_statuses` | 3965 |
| `gl_period_statuses` | 3975 |
| `gl_period_statuses` | 3993 |
| `gl_period_statuses` | 4007 |
| `ra_interface_lines_all` | 4015 |
| `dka_ar_fusion_inv_ctrl_temp` | 4126 |
| `ra_cust_trx_types_all` | 4151 |
| `dka_ar_fusion_inv_ctrl_temp` | 4193 |
| `dka_ar_fusion_inv_ctrl_temp` | 4242 |
| `ar_vat_tax_all` | 4320 |
| `ar_vat_tax_all_b` | 4380 |
| `ar_vat_tax_all_b` | 4431 |
| `dual` | 4546 |
| `RA_INTERFACE_DISTRIBUTIONS_ALL` | 4550 |
| `ra_interface_distributions_all` | 4629 |
| `ar_receivable_applications_all` | 4756 |
| `ar_receivable_applications_all` | 4760 |
| `ar_receivable_applications_all` | 4764 |
| `ar_receivable_applications_all` | 4768 |
| `dka_ar_fusion_rec_ctrl_temp` | 4771 |
| `ar_cash_receipts_all` | 4805 |
| `ar_receipt_methods` | 4940 |
| `ra_interface_distributions_all` | 5037 |
| `ra_interface_lines_all` | 5040 |
| `ra_interface_lines_all` | 5056 |
| `dka_ar_fusion_rec_ctrl_temp` | 5135 |
| `ra_customer_trx_all` | 5234 |
| `ra_customer_trx_all` | 5246 |
| `OF` | 5251 |
| `ra_customer_trx_all` | 5256 |
| `DKA_AR_FUSION_INV_CTRL_TEMP` | 5295 |
| `ra_customer_trx_all` | 5296 |
| `ar_payment_schedules_all` | 5304 |
| `ra_cust_trx_types_all` | 5306 |
| `ra_customer_trx_all` | 5323 |
| `ar_payment_schedules_all` | 5328 |
| `ar_payment_schedules_all` | 5356 |
| `ra_customer_trx_all` | 5373 |
| `ra_customer_trx_all` | 5395 |
| `ra_customer_trx_all` | 5403 |
| `RA_CUST_TRX_LINE_GL_DIST_all` | 5407 |
| `ar_payment_schedules_all` | 5422 |
| `ar_payment_schedules_all` | 5441 |
| `dka_ar_fusion_mvt_lettrage_0` | 5557 |
| `DKA_AR_FUSION_MVT_LETTRAGE_0` | 5644 |
| `ra_customer_trx_all` | 5679 |
| `ra_customer_trx_all` | 5701 |
| `ar_receipt_methods` | 5732 |
| `ra_customer_trx_all` | 5795 |
| `dka_ar_fusion_mvt_lettrage_0` | 5808 |
| `ar_payment_schedules_all` | 5828 |
| `ar_receipt_methods` | 5878 |
| `ar_cash_receipts_all` | 5980 |
| `ar_receivable_applications_all` | 5990 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_outdebug_message` | 82 |
| `dka_tools_pkg.put_outdebug_message` | 97 |
| `FND_PROFILE.VALUE` | 156 |
| `FND_PROFILE.VALUE` | 158 |
| `dka_tools_pkg.get_code_combination_id` | 2668 |
| `dka_tools_pkg.get_code_combination_id` | 2729 |
| `dka_tools_pkg.get_code_combination_id` | 2766 |
| `dka_tools_pkg.get_code_combination_id` | 2933 |
| `dka_tools_pkg.get_code_combination_id` | 3002 |
| `dka_tools_pkg.get_code_combination_id` | 3031 |
| `ar_receipt_api_pub.Create_cash` | 4814 |
| `fnd_msg_pub.get` | 4870 |
| `AR_RECEIPT_API_PUB.Create_Apply_on_acc` | 4883 |
| `fnd_msg_pub.get` | 4926 |
| `AR_RECEIPT_API_PUB.Create_Apply_on_acc` | 4953 |
| `fnd_msg_pub.get` | 4994 |
| `AR_RECEIPT_API_PUB.reverse` | 5159 |
| `fnd_msg_pub.get` | 5184 |
| `dka_tools_pkg.put_debug_message` | 5570 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5572 |
| `dka_tools_pkg.put_outdebug_message` | 5582 |
| `dka_tools_pkg.put_outdebug_message` | 5592 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5600 |
| `dka_tools_pkg.put_debug_message` | 5606 |
| `Ar_receipt_api_pub.Create_cash` | 5886 |
| `fnd_msg_pub.get` | 5916 |
| `Ar_receipt_api_pub.apply` | 5931 |
| `fnd_msg_pub.get` | 5959 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1094, 6185, 6280, 6286, 6336, 6387, 6480 |
| rollback | 6288, 6338, 6389, 6482 |
| when_others | 99, 124, 207, 329, 616, 654, 691, 1019, 1160, 1329, 1397, 1504, 1598, 1692, 1710, 1762, 1873, 1948, 2032, 2096, 2185, 2264, 2360, 2422, 2538, 2804, 3084, 3140, 3244, 3267, 3290, 3342, 3393, 3577, 3795, 3849, 3892, 4715, 5009, 5074, 5197, 5478, 5521, 5609, 5757, 6027, 6078 |
| suppression | 197, 198, 199, 200, 201 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_FUSAR_ANNUL / DKA | `DKA_FUSION_AR_PKG.ANNULATION_REGLEMENTS` | dka/12.0.0/admin/import/DKA_FUSAR_ANNUL.ldt:494 |
| DKA_FUSAR_CTR / DKA | `DKA_FUSION_AR_PKG.CTR` | dka/12.0.0/admin/import/DKA_FUSAR_CTR.ldt:477 |
| DKA_FUSAR_FUSION / DKA | `DKA_FUSION_AR_PKG.FUSION` | dka/12.0.0/admin/import/DKA_FUSAR_FUSION.ldt:494 |
| DKA_FUSAR_LETTR / DKA | `DKA_FUSION_AR_PKG.LETTRAGE_ZERO` | dka/12.0.0/admin/import/DKA_FUSAR_LETTR.ldt:494 |
| DKA_FUSAR_LIST / DKA | `DKA_FUSION_AR_PKG.LISTE_MOUVEMENTS` | dka/12.0.0/admin/import/DKA_FUSAR_LIST.ldt:479 |
| DKA_FUSAR_POST / DKA | `DKA_FUSION_AR_PKG.POST_FUSION_AR` | dka/12.0.0/admin/import/DKA_FUSAR_POST.ldt:494 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
