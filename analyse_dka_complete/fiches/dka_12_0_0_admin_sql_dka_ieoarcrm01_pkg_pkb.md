# DKA_IEOARCRM01_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IEOARCRM01_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IEOARCRM01_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 917 ; encodage : cp1252 (repli). SHA-256 : `4486907bbc384843e4bff566785e6e7271ad1a0dea3b2adcac46ecd00894f9be`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `put_debug_message` | 46 |
| `validate` | 54 |
| `not_null` | 66 |
| `write_CSV_line` | 73 |
| `check_directory` | 97 |
| `dump_query` | 111 |
| `Extract_CSV` | 272 |
| `Fournisseurs` | 304 |
| `Reglements` | 371 |
| `Factures_payees` | 449 |
| `Factures_non_payees` | 534 |
| `Commandes` | 771 |
| `main` | 880 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ap_suppliers` | 335 |
| `ap_supplier_sites_all` | 336 |
| `ap_terms_tl` | 337 |
| `hr_all_organization_units` | 338 |
| `zx_party_tax_profile` | 339 |
| `zx_party_tax_profile` | 340 |
| `iby_external_payees_all` | 341 |
| `iby_ext_party_pmt_mthds` | 342 |
| `iby_pmt_instr_uses_all` | 345 |
| `iby_ext_bank_accounts` | 349 |
| `ce_bank_branches_v` | 350 |
| `ce_banks_v` | 351 |
| `iby_payments_all` | 418 |
| `hr_all_organization_units` | 419 |
| `IBY_DOCS_PAYABLE_ALL` | 420 |
| `ap_payment_schedules_all` | 421 |
| `ap_invoices_all` | 422 |
| `ap_lookup_codes` | 423 |
| `fnd_doc_sequence_categories` | 425 |
| `ce_bank_accounts` | 426 |
| `iby_payments_all` | 471 |
| `IBY_DOCS_PAYABLE_ALL` | 472 |
| `rglt` | 506 |
| `hr_all_organization_units` | 507 |
| `ap_payment_schedules_all` | 508 |
| `ap_invoices_all` | 509 |
| `fnd_lookup_values` | 510 |
| `fnd_doc_sequence_categories` | 513 |
| `ce_bank_accounts` | 514 |
| `gl_ledgers` | 553 |
| `fnd_id_flex_segments` | 554 |
| `fnd_flex_values_vl` | 555 |
| `ap_invoices_all` | 570 |
| `ap_invoices_all_dfv` | 571 |
| `ap_payment_schedules_all` | 572 |
| `ap_invoices_all` | 585 |
| `ap_invoices_all_dfv` | 586 |
| `invoices` | 606 |
| `ap.ap_holds_all` | 607 |
| `invoices2` | 642 |
| `invoices3` | 656 |
| `ap_invoice_lines_all` | 657 |
| `po_distributions_all` | 658 |
| `ap_invoices_interface` | 676 |
| `invoices4` | 681 |
| `interfaced_invoices` | 683 |
| `all_invoices` | 732 |
| `hr_all_organization_units` | 733 |
| `ap_lookup_codes` | 734 |
| `fnd_doc_sequence_categories` | 735 |
| `societes` | 736 |
| `IBY_EXTERNAL_BANK_ACCOUNTS_V` | 737 |
| `gl_ledgers` | 789 |
| `fnd_id_flex_segments` | 790 |
| `fnd_flex_values_vl` | 791 |
| `po_headers_all` | 826 |
| `FND_USER` | 827 |
| `po_lookup_codes` | 828 |
| `po_lookup_codes` | 829 |
| `PO_LINES_ALL` | 830 |
| `PO_LINE_LOCATIONS_ALL` | 831 |
| `po_distributions_all` | 832 |
| `gl_code_combinations` | 833 |
| `societes` | 834 |
| `ap_invoices_all` | 838 |
| `ap_invoice_distributions_all` | 839 |
| `po_lines_all` | 845 |
| `po_line_locations_all` | 846 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 49 |
| `dka_tools_pkg.check_directory` | 100 |
| `AP_INVOICES_UTILITY_PKG.get_posting_status` | 636 |
| `Dka_Tools_Pkg.get_parameter` | 891 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 169, 213, 292, 359, 437, 523, 759, 867, 907 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IEOARCRM01 / DKA | `DKA_IEOARCRM01_PKG.main` | dka/12.0.0/admin/import/DKA_IEOARCRM01.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
