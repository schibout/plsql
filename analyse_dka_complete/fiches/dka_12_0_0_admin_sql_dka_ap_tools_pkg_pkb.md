# DKA_AP_TOOLS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_AP_TOOLS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_AP_TOOLS_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1410 ; encodage : cp1252 (repli). SHA-256 : `89748be80611319015c700cf7657a2cc0bfedab3954a0c3ddb18461dcaf2009b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_Attribute12DSP_Facture` | 44 |
| `apply_tva_autoliquidee` | 106 |
| `apply_acompte` | 927 |
| `apply_fonction` | 1205 |
| `get_vendor_partner` | 1291 |
| `get_is_vendor_analyse` | 1379 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_descr_flex_column_usages` | 62 |
| `fnd_flex_validation_tables` | 77 |
| `ap_invoices_interface` | 130 |
| `ap_invoice_lines_interface` | 140 |
| `dka_stransco_headers` | 146 |
| `ap_invoice_lines_interface` | 158 |
| `ap_invoice_lines_interface` | 166 |
| `po_vendors` | 171 |
| `fnd_flex_values_vl` | 184 |
| `dka_iapfacxgs_reporting_all` | 244 |
| `gl_code_combinations_kfv` | 263 |
| `zx_rates_vl` | 293 |
| `zx_rates_vl` | 323 |
| `Ap_Invoice_Lines_Interface` | 342 |
| `Ap_Invoice_Lines_Interface` | 593 |
| `Ap_Invoice_Lines_Interface` | 844 |
| `zx_rates_vl` | 849 |
| `Ap_Invoice_Lines_Interface` | 861 |
| `ap_invoices_interface` | 941 |
| `ap_invoices_interface` | 959 |
| `ap_invoices_interface` | 992 |
| `AP_INVOICES_ALL` | 1028 |
| `AP_INVOICE_DISTRIBUTIONS_ALL` | 1044 |
| `AP_INVOICE_DISTRIBUTIONS_ALL` | 1049 |
| `AP_INVOICES_ALL` | 1065 |
| `AP_INVOICE_DISTRIBUTIONS_ALL` | 1082 |
| `AP_INVOICES_INTERFACE` | 1120 |
| `AP_INVOICES_INTERFACE` | 1141 |
| `fnd_flex_value_sets` | 1215 |
| `po_vendor_sites_all` | 1303 |
| `po_vendor_sites_all` | 1334 |
| `fnd_flex_value_sets` | 1389 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 498 |
| `fnd_profile.value` | 500 |
| `fnd_profile.value` | 501 |
| `fnd_profile.value` | 749 |
| `fnd_profile.value` | 751 |
| `fnd_profile.value` | 752 |
| `Dka_Tools_Pkg.put_log_message` | 881 |
| `Dka_Tools_Pkg.put_log_message` | 1166 |
| `Dka_Tools_Pkg.put_log_message` | 1234 |
| `Dka_Tools_Pkg.put_log_message` | 1240 |
| `Dka_Tools_Pkg.put_log_message` | 1241 |
| `Dka_Tools_Pkg.put_log_message` | 1251 |
| `Dka_Tools_Pkg.put_log_message` | 1252 |
| `Dka_Tools_Pkg.put_log_message` | 1263 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 874, 876, 1005, 1174 |
| rollback | 885, 1167 |
| when_others | 88, 879, 907, 1164, 1185, 1266, 1349, 1362, 1402 |
| suppression | 844 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
