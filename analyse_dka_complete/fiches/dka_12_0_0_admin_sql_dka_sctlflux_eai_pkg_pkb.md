# DKA_SCTLFLUX_EAI_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SCTLFLUX_EAI_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SCTLFLUX_EAI_PKG.pkb).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1137 ; encodage : cp1252 (repli). SHA-256 : `8da630c2408a7a2126fa9e18a8323d410fc5515f168d66658399b227be053466`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 52 |
| `log_msg` | 66 |
| `INSERT_GL_DATA` | 89 |
| `INSERT_AP_DATA` | 281 |
| `INSERT_AR_DATA` | 496 |
| `main` | 924 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `GL_INTERFACE` | 100 |
| `FND_FLEX_VALUES_VL` | 107 |
| `gl_ledgers` | 120 |
| `DKA_SCTLFLUX_EAI` | 127 |
| `GL_INTERFACE` | 152 |
| `FND_FLEX_VALUES_VL` | 157 |
| `GL_JE_LINES` | 177 |
| `FND_FLEX_VALUES_VL` | 186 |
| `GL_JE_HEADERS` | 195 |
| `gl_ledgers` | 201 |
| `DKA_SCTLFLUX_EAI` | 209 |
| `GL_JE_LINES` | 234 |
| `FND_FLEX_VALUES_VL` | 242 |
| `GL_JE_HEADERS` | 251 |
| `AP_INVOICES_INTERFACE` | 292 |
| `FND_FLEX_VALUES_VL` | 300 |
| `DKA_SCTLFLUX_EAI` | 315 |
| `AP_INVOICES_INTERFACE` | 340 |
| `FND_FLEX_VALUES_VL` | 346 |
| `DKA_SCTLFLUX_EAI` | 366 |
| `AP_INVOICES_INTERFACE` | 370 |
| `AP_INVOICES_ALL` | 387 |
| `FND_FLEX_VALUES_VL` | 395 |
| `DKA_SCTLFLUX_EAI` | 409 |
| `AP_INVOICES_ALL` | 434 |
| `FND_FLEX_VALUES_VL` | 440 |
| `DKA_SCTLFLUX_EAI` | 458 |
| `AP_INVOICES_ALL` | 462 |
| `DKA_SCTLFLUX_ARFLAG_EAI` | 508 |
| `DKA_IARPAFAC_INTERFACE` | 517 |
| `FND_FLEX_VALUES_VL` | 527 |
| `DKA_SCTLFLUX_ARFLAG_EAI` | 535 |
| `DKA_SCTLFLUX_EAI` | 544 |
| `DKA_IARPAFAC_INTERFACE` | 589 |
| `FND_FLEX_VALUES_VL` | 598 |
| `DKA_SCTLFLUX_ARFLAG_EAI` | 606 |
| `RA_INTERFACE_LINES` | 621 |
| `FND_FLEX_VALUES_VL` | 627 |
| `DKA_SCTLFLUX_ARFLAG_EAI` | 641 |
| `DKA_SCTLFLUX_EAI` | 652 |
| `RA_INTERFACE_LINES_ALL` | 679 |
| `FND_FLEX_VALUES_VL` | 690 |
| `DKA_SCTLFLUX_EAI` | 709 |
| `RA_INTERFACE_LINES_ALL` | 715 |
| `RA_CUSTOMER_TRX_LINES_ALL` | 735 |
| `RA_CUSTOMER_TRX_LINES_ALL` | 736 |
| `RA_CUSTOMER_TRX_LINES_ALL` | 739 |
| `RA_CUSTOMER_TRX` | 758 |
| `DKA_SCTLFLUX_ARFLAG_EAI` | 764 |
| `RA_CUSTOMER_TRX_LINES_ALL` | 776 |
| `FND_FLEX_VALUES_VL` | 783 |
| `RA_CUSTOMER_TRX` | 794 |
| `DKA_SCTLFLUX_ARFLAG_EAI` | 800 |
| `DKA_SCTLFLUX_EAI` | 812 |
| `RA_CUSTOMER_TRX_LINES_ALL` | 838 |
| `FND_FLEX_VALUES_VL` | 856 |
| `RA_CUSTOMER_TRX` | 867 |
| `DKA_SCTLFLUX_EAI` | 878 |
| `RA_CUSTOMER_TRX_LINES_ALL` | 883 |
| `DKA_SCTLFLUX_EAI` | 946 |
| `fnd_concurrent_requests` | 1004 |
| `DKA_SCTLFLUX_EAI` | 1067 |
| `DKA_SCTLFLUX_EAI` | 1110 |
| `DKA_SCTLFLUX_EAI` | 1115 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 35 |
| `FND_PROFILE.VALUE` | 38 |
| `fnd_file.put_line` | 55 |
| `fnd_file.put_line` | 76 |
| `Dka_Tools_Pkg.get_parameter` | 979 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 173, 261, 362, 383, 454, 476, 617, 705, 730, 874, 903, 1093, 1119 |
| when_others | 265, 480, 907, 1016, 1128 |
| suppression | 1110 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SCTLFLUX_EAI / DKA | `DKA_SCTLFLUX_EAI_PKG.main` | dka/12.0.0/admin/import/DKA_SCTLFLUX_EAI.prt:611 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
