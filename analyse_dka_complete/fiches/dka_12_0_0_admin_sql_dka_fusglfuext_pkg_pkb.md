# DKA_FUSGLFUEXT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_FUSGLFUEXT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_FUSGLFUEXT_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2720 ; encodage : cp1252 (repli). SHA-256 : `f0006521d11d4705e10b7301f074359eaff8b5e704b1c769ece4242d8d600ce7`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `EXTRACT_DATA` | 41 |
| `UPDATE_TMP` | 895 |
| `VALIDATE_DATA` | 942 |
| `IMPORT_DATA` | 1432 |
| `ARCHIVE_DATA` | 2534 |
| `MAIN` | 2597 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_STRANSCO_LINES` | 52 |
| `gl_balances` | 105 |
| `gl_balances` | 190 |
| `CE_bank_accounts` | 215 |
| `gl_balances` | 288 |
| `GL_JE_HEADERS` | 376 |
| `CE_bank_accounts` | 411 |
| `GL_JE_HEADERS` | 471 |
| `CE_bank_accounts` | 508 |
| `DKA_SGLFUSION_TMP` | 532 |
| `DKA_SGLFUSION_TMP` | 541 |
| `DKA_SGLFUSION_TMP` | 609 |
| `DKA_SGLFUSION_TMP` | 676 |
| `DKA_SGLFUSION_TMP` | 743 |
| `DKA_SGLFUSION_TMP` | 813 |
| `DKA_SGLFUSION_TMP` | 908 |
| `DKA_SGLFUSION_TMP` | 980 |
| `DKA_SGLFUSION_TMP` | 984 |
| `DKA_STRANSCO_LINES` | 995 |
| `DKA_STRANSCO_LINES` | 1011 |
| `DKA_STRANSCO_LINES` | 1027 |
| `DKA_STRANSCO_LINES` | 1042 |
| `DKA_STRANSCO_LINES` | 1057 |
| `DKA_STRANSCO_LINES` | 1074 |
| `DKA_STRANSCO_LINES` | 1090 |
| `DKA_STRANSCO_LINES` | 1104 |
| `DKA_STRANSCO_LINES` | 1119 |
| `DKA_STRANSCO_LINES` | 1135 |
| `DKA_STRANSCO_LINES` | 1150 |
| `DKA_STRANSCO_LINES` | 1165 |
| `DKA_STRANSCO_LINES` | 1180 |
| `DKA_STRANSCO_LINES` | 1195 |
| `DKA_STRANSCO_LINES` | 1210 |
| `DKA_SGLFUSION_TMP` | 1247 |
| `DKA_SGLFUSION_TMP` | 1250 |
| `gl_balances` | 1318 |
| `dans` | 1400 |
| `DKA_SGLFUSION_TMP` | 1465 |
| `DKA_SGLFUSION_TMP` | 1469 |
| `DKA_SGLFUSION_TMP` | 1515 |
| `DKA_SGLFUSION_TMP` | 1598 |
| `DKA_SGLFUSION_TMP` | 1644 |
| `DKA_STRANSCO_LINES` | 2540 |
| `DKA_STRANSCO_HEADERS` | 2542 |
| `DKA_STRANSCO_LINES_HIST` | 2552 |
| `DKA_STRANSCO_LINES` | 2579 |
| `DKA_STRANSCO_HEADERS` | 2580 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 597 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 666 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 733 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 802 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 871 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1004 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1020 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1036 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1051 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1065 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1083 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1098 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1113 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1127 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1144 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1158 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1174 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1188 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1204 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1218 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 1307 |
| `Fnd_File.put_line` | 1400 |
| `DKA_TOOLS_PKG.OPEN_UTL_FILE` | 1662 |
| `DKA_TOOLS_PKG.OPEN_UTL_FILE` | 1663 |
| `DKA_TOOLS_PKG.OPEN_UTL_FILE` | 1664 |
| `DKA_TOOLS_PKG.OPEN_UTL_FILE` | 1665 |
| `DKA_TOOLS_PKG.OPEN_UTL_FILE` | 1666 |
| `DKA_TOOLS_PKG.OPEN_UTL_FILE` | 2093 |
| `DKA_TOOLS_PKG.OPEN_UTL_FILE` | 2094 |
| `DKA_TOOLS_PKG.OPEN_UTL_FILE` | 2095 |
| `DKA_TOOLS_PKG.OPEN_UTL_FILE` | 2096 |
| `DKA_TOOLS_PKG.OPEN_UTL_FILE` | 2097 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2099 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 2574 |
| `DKA_TOOLS_PKG.Put_Outdebug_Message` | 2587 |
| `Fnd_File.put_line` | 2606 |
| `Fnd_File.put_line` | 2607 |
| `Fnd_File.put_line` | 2619 |
| `Fnd_File.put_line` | 2632 |
| `Fnd_File.put_line` | 2647 |
| `Fnd_File.put_line` | 2660 |
| `Fnd_File.put_line` | 2690 |
| `Fnd_File.put_line` | 2691 |
| `Fnd_File.put_line` | 2692 |
| `Fnd_File.put_line` | 2693 |
| `Fnd_File.put_line` | 2698 |
| `Fnd_File.put_line` | 2699 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2702 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2703 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2704 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2705 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2706 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2707 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2708 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2709 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2710 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2711 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 533, 602, 671, 738, 808, 877, 920, 1306, 1412, 2591, 2684 |
| when_others | 595, 664, 731, 800, 869, 1002, 1018, 1034, 1049, 1063, 1081, 1096, 1111, 1125, 1142, 1156, 1172, 1186, 1202, 1216, 1399, 2572, 2585, 2694 |
| suppression | 532, 2579 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_FUSGLCTRLFU / DKA | `DKA_FUSGLFUEXT_PKG.main` | dka/12.0.0/admin/import/DKA_FUSGLFUEXT.prt:474 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
