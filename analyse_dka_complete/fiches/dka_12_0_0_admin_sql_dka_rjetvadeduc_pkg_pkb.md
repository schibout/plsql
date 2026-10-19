# DKA_RJETVADEDUC_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_RJETVADEDUC_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_RJETVADEDUC_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1390 ; encodage : cp1252 (repli). SHA-256 : `0f12f76af8c0557be7458b408b0ce48e571658efbdcebe595ae0a64a6b7568d7`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `calcul_tva_cre` | 51 |
| `calcul_tva_deb` | 848 |
| `dka_check_codetva` | 1360 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_RJETVADEDUC_CRE` | 77 |
| `Fnd_Concurrent_Requests` | 80 |
| `zx_rec_nrec_dist` | 525 |
| `ap_invoice_payments_all` | 553 |
| `ap_invoices_all` | 596 |
| `zx_rec_nrec_dist` | 671 |
| `ap_invoice_payments_all` | 681 |
| `ap_invoices_all` | 708 |
| `DKA_RJETVADEDUC_CRE` | 790 |
| `DKA_RJETVADEDUC_DEB` | 874 |
| `Fnd_Concurrent_Requests` | 877 |
| `zx_rec_nrec_dist` | 1237 |
| `DKA_RJETVADEDUC_DEB` | 1300 |
| `gl_code_combinations` | 1370 |
| `ZX_JRNL_ACCOUNTS_EXTRACT_V` | 1371 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.Put_Debug_Message` | 75 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 89 |
| `Dka_Tools_Pkg.put_debug_message` | 94 |
| `Dka_Tools_Pkg.put_debug_message` | 95 |
| `DKA_RJETVADEDUC_PKG.dka_check_codetva` | 518 |
| `DKA_RJETVADEDUC_PKG.dka_check_codetva` | 641 |
| `DKA_RJETVADEDUC_PKG.dka_check_codetva` | 664 |
| `DKA_RJETVADEDUC_PKG.dka_check_codetva` | 753 |
| `Dka_Tools_Pkg.put_debug_message` | 774 |
| `Dka_Tools_Pkg.put_debug_message` | 826 |
| `Dka_Tools_Pkg.put_debug_message` | 827 |
| `Dka_Tools_Pkg.put_debug_message` | 830 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 872 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 886 |
| `Dka_Tools_Pkg.put_debug_message` | 891 |
| `Dka_Tools_Pkg.put_debug_message` | 892 |
| `DKA_RJETVADEDUC_PKG.dka_check_codetva` | 1230 |
| `DKA_RJETVADEDUC_PKG.dka_check_codetva` | 1265 |
| `Dka_Tools_Pkg.put_debug_message` | 1283 |
| `Dka_Tools_Pkg.put_debug_message` | 1284 |
| `Dka_Tools_Pkg.put_debug_message` | 1336 |
| `Dka_Tools_Pkg.put_debug_message` | 1337 |
| `Dka_Tools_Pkg.put_debug_message` | 1340 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 87, 884 |
| when_others | 825, 838, 1335, 1349, 1376 |
| suppression | 77, 874 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
