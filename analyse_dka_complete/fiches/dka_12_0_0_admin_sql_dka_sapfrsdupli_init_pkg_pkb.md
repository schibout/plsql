# DKA_SAPFRSDUPLI_INIT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPFRSDUPLI_INIT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPFRSDUPLI_INIT_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1342 ; encodage : cp1252 (repli). SHA-256 : `08c57366a3dedbec9d2128320b2a912fefece2d7b187f4ffe339fa8173a75324`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `writeout` | 51 |
| `writelog` | 78 |
| `sortie_traitement` | 118 |
| `entete_de_sortie` | 220 |
| `fin_de_sortie` | 266 |
| `LANCE_CHARGEMENT_FICHIER` | 290 |
| `VALIDATION_DONNEES` | 375 |
| `MAIN` | 706 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `FND_CONCURRENT_PROGRAMS_VL` | 232 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 379 |
| `ap_supplier_sites_all` | 421 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 437 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 455 |
| `FND_TERRITORIES` | 474 |
| `DKA_STRANSCO_LINES` | 483 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 500 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 513 |
| `FND_FLEX_VALUE_SETS` | 525 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 538 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 561 |
| `AP_SUPPLIER_SITES_ALL` | 572 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 586 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 595 |
| `ap_supplier_sites_all` | 611 |
| `ap_supplier_sites_all` | 639 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 652 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 672 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 717 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 732 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 784 |
| `ALL_DIRECTORIES` | 796 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 817 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 823 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 844 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 847 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 861 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 884 |
| `hr_operating_units` | 897 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 928 |
| `AP_SUPPLIER_SITES_ALL` | 942 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 952 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 968 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 983 |
| `ap_supplier_sites_all` | 1021 |
| `ap_supplier_sites_all` | 1032 |
| `AP_INVOICES_ALL` | 1053 |
| `ap_supplier_sites_all` | 1057 |
| `ap_supplier_sites_all` | 1065 |
| `HR_OPERATING_UNITS` | 1071 |
| `ap_suppliers` | 1072 |
| `IBY_EXTERNAL_PAYEES_ALL` | 1074 |
| `ap_supplier_sites_all` | 1079 |
| `HR_OPERATING_UNITS` | 1081 |
| `ap_suppliers` | 1082 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 1092 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 1114 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 1139 |
| `fnd_responsibility` | 1171 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 1225 |
| `DKA_SAPFRSDUPLI_INIT_TMP` | 1232 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 1238 |
| `ap_supplier_sites_all` | 1247 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 1265 |
| `ap_supplier_sites_all` | 1274 |
| `hz_party_sites` | 1300 |
| `ap_supplier_sites_all` | 1302 |
| `hz_party_sites` | 1309 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 40 |
| `FND_FILE.PUT_LINE` | 56 |
| `Fnd_File.put_line` | 62 |
| `Fnd_File.put_line` | 64 |
| `Fnd_File.put_line` | 65 |
| `Fnd_File.put_line` | 66 |
| `Fnd_File.put_line` | 67 |
| `Fnd_File.put_line` | 68 |
| `fnd_file.put_line` | 90 |
| `fnd_file.put_line` | 93 |
| `fnd_file.put_line` | 97 |
| `Fnd_File.put_line` | 311 |
| `Fnd_File.put_line` | 314 |
| `FND_REQUEST.submit_request` | 315 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 328 |
| `DKA_SAPFRSDUPLI_PKG.DUPLICATION_SITE_FOURNISSEUR` | 901 |
| `FND_PROFILE.VALUE` | 1174 |
| `FND_GLOBAL.APPS_INITIALIZE` | 1176 |
| `DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR` | 1213 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 324, 692, 831, 870, 975, 1088, 1164 |
| when_others | 59, 100, 594, 625, 801, 1103, 1182, 1251, 1278 |
| suppression | 784 |
| soumission | 315 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPFRSDUPLI_INIT / DKA | `DKA_SAPFRSDUPLI_INIT_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SAPFRSDUPLI_INIT_PRG.prt:455 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
