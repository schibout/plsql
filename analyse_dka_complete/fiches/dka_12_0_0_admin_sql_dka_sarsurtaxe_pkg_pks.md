# DKA_SARSURTAXE_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SARSURTAXE_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SARSURTAXE_PKG.pks).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 719 ; encodage : cp1252 (repli). SHA-256 : `bbf216229f46a5c453ff15ba6ee51281cae7ccbe3839693e57d4734bfa77c71a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 51 |
| `get_segment4` | 71 |
| `insert_dka_sarsurtaxe_tmp` | 92 |
| `purge_dka_sarsurtaxe_tmp` | 111 |
| `insert_ar_invoices` | 133 |
| `insert_gl_invoices_gericco` | 153 |
| `insert_ap_invoices_interface` | 172 |
| `insert_ap_inv_lines_interface` | 197 |
| `load_ap_invoices_interfaces` | 232 |
| `load_data` | 254 |
| `main` | 273 |
| `update_after_import_ap` | 293 |
| `update_ra_cust_trx_line_gl_dis` | 313 |
| `update_gl_je_lines_cuf` | 334 |
| `purge_ap_invoices_interface` | 352 |
| `main2` | 371 |
| `update_gl_je_lines` | 390 |
| `load_ref_let` | 412 |
| `main3` | 431 |
| `insert_gl_interface_control` | 450 |
| `insert_gl_interface` | 471 |
| `main4` | 491 |
| `update_dka_sarsurtaxe_tmp` | 509 |
| `main5` | 528 |
| `insert_dka_sarsurtaxe_ctl_tmp` | 544 |
| `controle_fournisseur_absent` | 561 |
| `controle_fournisseur_doublon` | 577 |
| `controle_site_frs_absent` | 592 |
| `controle_facture_negative` | 608 |
| `bilan_surtaxe` | 624 |
| `main6` | 643 |
| `main7` | 659 |
| `launch_xlaaccpb` | 676 |
| `launch_apprvl` | 692 |
| `launch_glxrcaut` | 708 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_APPRVL / DKA | `dka_sarsurtaxe_pkg.launch_apprvl` | dka/12.0.0/admin/import/DKA_APPRVL.prt:419 |
| DKA_GLXRCAUT / DKA | `dka_sarsurtaxe_pkg.launch_glxrcaut` | dka/12.0.0/admin/import/DKA_GLXRCAUT.prt:419 |
| DKA_POSTMAN / DKA | `dka_sarsurtaxe_pkg.launch_xlaaccpb` | dka/12.0.0/admin/import/DKA_POSTMAN.prt:419 |
| DKA_SARSURTAXE_1 / DKA | `dka_sarsurtaxe_pkg.main` | dka/12.0.0/admin/import/DKA_SARSURTAXE_1.prt:404 |
| DKA_SARSURTAXE_2 / DKA | `dka_sarsurtaxe_pkg.main2` | dka/12.0.0/admin/import/DKA_SARSURTAXE_2.prt:404 |
| DKA_SARSURTAXE_3 / DKA | `dka_sarsurtaxe_pkg.main3` | dka/12.0.0/admin/import/DKA_SARSURTAXE_3.prt:403 |
| DKA_SARSURTAXE_4 / DKA | `dka_sarsurtaxe_pkg.main4` | dka/12.0.0/admin/import/DKA_SARSURTAXE_4.prt:404 |
| DKA_SARSURTAXE_5 / DKA | `dka_sarsurtaxe_pkg.main5` | dka/12.0.0/admin/import/DKA_SARSURTAXE_5.prt:404 |
| DKA_SARSURTAXE_6 / DKA | `dka_sarsurtaxe_pkg.main6` | dka/12.0.0/admin/import/DKA_SARSURTAXE_6.prt:420 |
| DKA_SARSURTAXE_7 / DKA | `dka_sarsurtaxe_pkg.main7` | dka/12.0.0/admin/import/DKA_SARSURTAXE_7.prt:438 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
