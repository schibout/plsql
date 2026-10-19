# DKA_XLA_AP_CUSTOM_SOURCES_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_XLA_AP_CUSTOM_SOURCES_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_XLA_AP_CUSTOM_SOURCES_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 553 ; encodage : cp1252 (repli). SHA-256 : `ba9425e4ca33726c0e4a15d03b60141eba65a3a379dd991ac9d81069001d7581`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Trace` | 50 |
| `Trace` | 64 |
| `Init_Module` | 75 |
| `Init_Module` | 98 |
| `Exit_Module` | 107 |
| `Exit_Module` | 121 |
| `get_Segment_Column_Name` | 137 |
| `is_Asset_Line` | 206 |
| `get_Tax_Code` | 351 |
| `get_Liability_Account` | 439 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_ledgers` | 164 |
| `fnd_segment_attribute_values` | 165 |
| `ap_invoice_distributions_all` | 253 |
| `ap_invoice_lines_all` | 254 |
| `gl_code_combinations_kfv` | 257 |
| `ap_self_assessed_tax_dist_all` | 266 |
| `ap_invoice_lines_all` | 267 |
| `gl_code_combinations_kfv` | 270 |
| `fa_category_books` | 291 |
| `gl_code_combinations_kfv` | 292 |
| `dual` | 315 |
| `ap_invoice_distributions_all` | 384 |
| `ap_invoice_lines_all` | 385 |
| `ap_self_assessed_tax_dist_all` | 394 |
| `ap_invoice_lines_all` | 395 |
| `ap_invoices_all` | 483 |
| `ap_invoice_distributions_all` | 484 |
| `gl_code_combinations_kfv` | 486 |
| `ap_invoices_all` | 491 |
| `ap_self_assessed_tax_dist_all` | 492 |
| `gl_code_combinations_kfv` | 494 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_log.string` | 56 |
| `Fnd_Profile.Put` | 80 |
| `Fnd_Profile.Put` | 81 |
| `Fnd_Profile.Put` | 82 |
| `dka_stransco_pkg.get_value_f` | 507 |
| `dka_stransco_pkg.get_value_f` | 522 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 61, 96, 117, 184, 330, 414, 544 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
