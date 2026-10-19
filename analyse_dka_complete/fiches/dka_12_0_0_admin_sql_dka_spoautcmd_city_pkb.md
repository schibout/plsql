# DKA_SPOAUTCMD_CITY.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOAUTCMD_CITY.pkb](../../dka/12.0.0/admin/sql/DKA_SPOAUTCMD_CITY.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1257 ; encodage : cp1252 (repli). SHA-256 : `6ea5ff713c2e688242cc99738db2155274d6a4b9a5282026b7bc35026acd7609`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 70 |
| `Request_parameters` | 122 |
| `output_end` | 210 |
| `Add_Message` | 237 |
| `init` | 291 |
| `purge_data` | 454 |
| `validate_data` | 499 |
| `Fermer_commandes` | 871 |
| `Report_Bilan` | 1050 |
| `main` | 1170 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_programs` | 85 |
| `fnd_concurrent_requests` | 128 |
| `fnd_concurrent_requests` | 157 |
| `fnd_concurrent_requests` | 174 |
| `ap_invoices_all` | 322 |
| `hr_operating_units` | 373 |
| `DUAL` | 385 |
| `DKA_SAPCDE_CITY_TMP` | 387 |
| `dka_program_messages` | 469 |
| `DKA_SAPCDE_CITY_TMP` | 514 |
| `OF` | 518 |
| `DKA_SAPCDE_CITY_TMP` | 522 |
| `DKA_SAPCDE_CITY_TMP` | 525 |
| `DKA_SAPCDE_CITY_TMP` | 569 |
| `PO_HEADERS_ALL` | 580 |
| `DKA_SAPCDE_CITY_TMP` | 600 |
| `hr_operating_units` | 619 |
| `DKA_SAPCDE_CITY_TMP` | 624 |
| `hr_operating_units` | 634 |
| `DKA_SAPCDE_CITY_TMP` | 659 |
| `PO_HEADERS_ALL` | 677 |
| `DKA_SAPCDE_CITY_TMP` | 685 |
| `DKA_SAPCDE_CITY_TMP` | 716 |
| `PO_HEADERS_ALL` | 732 |
| `DKA_SAPCDE_CITY_TMP` | 756 |
| `PO_HEADERS_ALL` | 772 |
| `DKA_SAPCDE_CITY_TMP` | 794 |
| `DKA_SAPCDE_CITY_TMP` | 805 |
| `DKA_SAPCDE_CITY_TMP` | 819 |
| `DKA_SAPCDE_CITY_TMP` | 831 |
| `DKA_SAPCDE_CITY_TMP` | 895 |
| `OF` | 898 |
| `apps.po_headers_all` | 920 |
| `DKA_SAPCDE_CITY_TMP` | 996 |
| `dka_program_messages` | 1055 |
| `DKA_SAPCDE_CITY_TMP` | 1066 |
| `DKA_SAPCDE_CITY_TMP` | 1086 |
| `DKA_SAPCDE_CITY_TMP` | 1092 |
| `dual` | 1097 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 45 |
| `fnd_profile.value` | 47 |
| `fnd_profile.value` | 48 |
| `Fnd_File.put_line` | 100 |
| `Fnd_File.put_line` | 101 |
| `Fnd_File.put_line` | 102 |
| `Fnd_File.put_line` | 103 |
| `Fnd_File.put_line` | 104 |
| `Fnd_File.put_line` | 144 |
| `Fnd_File.put_line` | 145 |
| `Fnd_File.put_line` | 163 |
| `Fnd_File.put_line` | 180 |
| `Fnd_File.put_line` | 187 |
| `Fnd_File.put_line` | 217 |
| `Fnd_File.put_line` | 218 |
| `Fnd_File.put_line` | 219 |
| `Fnd_File.put_line` | 271 |
| `Fnd_File.put_line` | 343 |
| `fnd_file.put_line` | 434 |
| `Fnd_File.Put_Line` | 461 |
| `Fnd_File.Put_Line` | 466 |
| `Fnd_File.put_line` | 478 |
| `Fnd_File.put_line` | 479 |
| `Fnd_File.put_line` | 539 |
| `Fnd_File.put_line` | 540 |
| `dka_tools_pkg.get_message` | 555 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 556 |
| `dka_tools_pkg.get_message` | 585 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 586 |
| `fnd_file.put_line` | 598 |
| `dka_tools_pkg.get_message` | 642 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 645 |
| `fnd_file.put_line` | 657 |
| `fnd_file.put_line` | 692 |
| `dka_tools_pkg.get_message` | 699 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 702 |
| `fnd_file.put_line` | 714 |
| `dka_tools_pkg.get_message` | 740 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 741 |
| `fnd_file.put_line` | 753 |
| `dka_tools_pkg.get_message` | 778 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 779 |
| `fnd_file.put_line` | 791 |
| `fnd_file.put_line` | 814 |
| `dka_tools_pkg.get_message` | 836 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 837 |
| `Fnd_File.put_line` | 850 |
| `FND_GLOBAL.APPS_INITIALIZE` | 944 |
| `Fnd_File.put_line` | 959 |
| `po_actions.close_po` | 963 |
| `Fnd_File.put_line` | 994 |
| `Fnd_File.put_line` | 1006 |
| `dka_tools_pkg.get_message` | 1008 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1010 |
| `Fnd_File.put_line` | 1077 |
| `Fnd_File.put_line` | 1104 |
| `Fnd_File.put_line` | 1105 |
| `Fnd_File.put_line` | 1106 |
| `fnd_file.put_line` | 1118 |
| `fnd_file.put_line` | 1119 |
| `Fnd_File.put_line` | 1122 |
| `Fnd_File.put_line` | 1123 |
| `Fnd_File.put_line` | 1126 |
| `Fnd_File.put_line` | 1128 |
| `Fnd_File.put_line` | 1136 |
| `Fnd_File.put_line` | 1137 |
| `Fnd_File.put_line` | 1138 |
| `Fnd_File.put_line` | 1141 |
| `Fnd_File.put_line` | 1143 |
| `fnd_file.put_line` | 1149 |
| `Fnd_File.put_line` | 1150 |
| `Fnd_File.put_line` | 1230 |
| `Fnd_File.put_line` | 1232 |
| `Fnd_File.put_line` | 1240 |
| `Fnd_File.put_line` | 1241 |
| `Fnd_File.put_line` | 1242 |
| `Fnd_File.put_line` | 1243 |
| `Fnd_File.put_line` | 1248 |
| `Fnd_File.put_line` | 1249 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 431, 472, 852, 1028 |
| rollback | 817 |
| when_others | 93, 436, 474, 630, 691, 813, 1099, 1244 |
| suppression | 469 |
| truncate | 463 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
