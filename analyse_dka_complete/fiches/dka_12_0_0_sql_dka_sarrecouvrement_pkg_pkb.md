# DKA_SARRECOUVREMENT_PKG.pkb

Source : [dka/12.0.0/sql/DKA_SARRECOUVREMENT_PKG.pkb](../../dka/12.0.0/sql/DKA_SARRECOUVREMENT_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1401 ; encodage : cp1252 (repli). SHA-256 : `0ae4efab7ba99ab8b518e5a9809c27926834af3c4008545ec7986ec1033c46ef`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Get_Last_Date` | 76 |
| `Get_Lib_Centre_Gestion` | 125 |
| `Get_Classe_Client` | 169 |
| `Get_Categorie_Client` | 208 |
| `Get_Region` | 237 |
| `Extraction_Encours` | 273 |
| `Extraction_Avoirs` | 962 |
| `Extraction_Ratios` | 1382 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `Gl_Period_Statuses` | 86 |
| `Fnd_Flex_Value_Sets` | 138 |
| `Ar_Lookups` | 182 |
| `Ar_Lookups` | 221 |
| `hr_operating_units` | 243 |
| `Ar_Payment_Schedules` | 314 |
| `Ra_Customer_Trx_All` | 315 |
| `Ra_Customer_Trx_All_DFV` | 316 |
| `Ra_Cust_Trx_Types_All` | 317 |
| `Ra_Cust_Trx_Line_Gl_Dist_All` | 318 |
| `Gl_Code_Combinations` | 319 |
| `Hz_Cust_Site_Uses_All` | 320 |
| `AR_CUSTOMERS` | 321 |
| `Fnd_Lookup_Values_Vl` | 322 |
| `Fnd_Lookup_Values_Vl` | 323 |
| `Ar_Payment_Schedules` | 366 |
| `Ar_Cash_Receipts_All` | 367 |
| `Ar_Receivable_Applications_All` | 368 |
| `Ar_Cash_Receipt_History_All` | 369 |
| `Gl_Code_Combinations` | 370 |
| `AR_Customers` | 371 |
| `Fnd_Lookup_Values_Vl` | 372 |
| `Fnd_Lookup_Values_Vl` | 373 |
| `Ar_Cash_Receipt_History_All` | 379 |
| `Dka_Encours_Client` | 436 |
| `Dka_Encours_Client` | 476 |
| `Fnd_Concurrent_Requests` | 478 |
| `Ar_Receivable_Applications_All` | 508 |
| `Ar_Receivable_Applications_All` | 523 |
| `Ar_Adjustments_All` | 538 |
| `pa_tasks` | 570 |
| `Hz_Customer_Profiles` | 591 |
| `HZ_CUST_ACCT_SITES_all` | 608 |
| `HZ_CUST_ACCT_SITES_all_DFV` | 609 |
| `ar_customers` | 612 |
| `Dka_Encours_Client` | 651 |
| `Hz_Customer_Profiles` | 736 |
| `Ra_Addresses_All` | 761 |
| `Ra_Addresses_All` | 779 |
| `Dka_Encours_Client` | 823 |
| `Dka_Encours_Client` | 924 |
| `Ar_Payment_Schedules_all` | 1004 |
| `Ra_Customer_Trx_All` | 1005 |
| `Ra_Customer_Trx_All_DFV` | 1006 |
| `Ra_Cust_Trx_Types_All` | 1007 |
| `Ra_Cust_Trx_Line_Gl_Dist_All` | 1008 |
| `Gl_Code_Combinations` | 1009 |
| `Hz_Cust_Site_Uses_All` | 1010 |
| `AR_CUSTOMERS` | 1011 |
| `Fnd_Lookup_Values_Vl` | 1012 |
| `Fnd_Lookup_Values_Vl` | 1013 |
| `Dka_Avoirs_Client` | 1053 |
| `Dual` | 1087 |
| `Dka_Avoirs_Client` | 1097 |
| `Fnd_Concurrent_Requests` | 1099 |
| `pa_tasks` | 1133 |
| `Hz_Customer_Profiles` | 1156 |
| `HZ_CUST_ACCT_SITES_all` | 1175 |
| `HZ_CUST_ACCT_SITES_all_DFV` | 1176 |
| `AR_Customers` | 1177 |
| `Ar_Receivable_Applications_All` | 1193 |
| `Ar_Receivable_Applications_All` | 1203 |
| `Dka_Avoirs_Client` | 1239 |
| `Dka_Avoirs_Client` | 1336 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.VALUE` | 95 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 251 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 459 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 461 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 462 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 468 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 474 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 485 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 494 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 713 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 718 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 887 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 888 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 895 |
| `Fnd_File.Put_Line` | 913 |
| `Fnd_File.Put_Line` | 916 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 923 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 927 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 933 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1070 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1072 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1073 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1079 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1089 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1095 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1106 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1116 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1297 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1304 |
| `Fnd_File.Put_Line` | 1325 |
| `Fnd_File.Put_Line` | 1328 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1335 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1339 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1347 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 487, 890, 929, 1108, 1299, 1341, 1345 |
| when_others | 148, 187, 226, 579, 598, 617, 743, 788, 936, 1143, 1165, 1181, 1350 |
| suppression | 476, 924, 1097, 1336 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AVOIRS_FRANCE / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Avoirs` | dka/12.0.0/admin/import/DKA_AVOIRS_FRANCE.prt:617 |
| DKA_AVOIRS_FRANCE / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Avoirs` | dka/12.0.0/admin/import/DKA_AVOIRS_FRANCE.prt:617 |
| DKA_AVOIRS_RECOUVREMENT / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Avoirs` | dka/12.0.0/admin/import/DKA_AVOIRS_RECOUVREMENT.prt:617 |
| DKA_AVOIRS_RECOUVREMENT / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Avoirs` | dka/12.0.0/admin/import/DKA_AVOIRS_RECOUVREMENT.prt:617 |
| DKA_ENCOURS_FRANCE / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Encours` | dka/12.0.0/admin/import/DKA_ENCOURS_FRANCE.prt:617 |
| DKA_ENCOURS_FRANCE / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Encours` | dka/12.0.0/admin/import/DKA_ENCOURS_FRANCE.prt:617 |
| DKA_ENCOURS_RECOUVREMENT / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Encours` | dka/12.0.0/admin/import/DKA_ENCOURS_RECOUVREMENT.prt:617 |
| DKA_ENCOURS_RECOUVREMENT / DKA | `DKA_SARRECOUVREMENT_PKG.Extraction_Encours` | dka/12.0.0/admin/import/DKA_ENCOURS_RECOUVREMENT.prt:617 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
