# DKA_SAPCLOTURE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPCLOTURE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPCLOTURE_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1184 ; encodage : cp1252 (repli). SHA-256 : `e56f68e2b90c09808fdc928f04a5f5e4aa25cccc554ce18093ca4b7f7f5059c3`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `cherche_period` | 60 |
| `cherche_next_period` | 125 |
| `main` | 556 |
| `launch_xdodtexe` | 918 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_period_statuses` | 81 |
| `gl_period_statuses` | 84 |
| `gl_period_statuses` | 145 |
| `gl_period_statuses` | 147 |
| `GL_ACCESS_SET_LEDGERS` | 596 |
| `gl_period_statuses` | 817 |
| `ap_invoices_interface` | 842 |
| `ap_system_parameters_all` | 847 |
| `GL_ACCESS_SET_LEDGERS` | 958 |
| `FND_LOOKUPS` | 1007 |
| `FND_MO_REPORTING_ENTITIES_V` | 1017 |
| `fnd_lookups` | 1032 |
| `fnd_lookups` | 1041 |
| `fnd_lookups` | 1049 |
| `gl_period_statuses` | 1058 |
| `gl_period_statuses` | 1074 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 609 |
| `Fnd_File.put_line` | 613 |
| `Fnd_File.put_line` | 615 |
| `Fnd_File.put_line` | 616 |
| `Fnd_File.put_line` | 617 |
| `Fnd_File.put_line` | 618 |
| `Fnd_File.put_line` | 620 |
| `Fnd_File.put_line` | 621 |
| `Fnd_File.put_line` | 622 |
| `Fnd_File.put_line` | 623 |
| `FND_PROFILE.VALUE` | 628 |
| `FND_PROFILE.VALUE` | 629 |
| `FND_PROFILE.VALUE` | 630 |
| `FND_GLOBAL.APPS_INITIALIZE` | 632 |
| `fnd_profile.VALUE` | 645 |
| `Fnd_File.put_line` | 646 |
| `Fnd_File.put_line` | 648 |
| `dka_sapcloture_pkg.cherche_period` | 650 |
| `Fnd_File.put_line` | 655 |
| `Fnd_File.put_line` | 656 |
| `Fnd_File.put_line` | 661 |
| `Fnd_File.put_line` | 663 |
| `Fnd_File.put_line` | 664 |
| `dka_sapcloture_pkg.cherche_next_period` | 666 |
| `Fnd_File.put_line` | 668 |
| `Fnd_File.put_line` | 670 |
| `Fnd_File.put_line` | 671 |
| `Fnd_File.put_line` | 672 |
| `Fnd_File.put_line` | 678 |
| `Fnd_File.put_line` | 679 |
| `Fnd_File.put_line` | 682 |
| `Fnd_File.put_line` | 683 |
| `Fnd_File.put_line` | 684 |
| `Fnd_File.put_line` | 685 |
| `Fnd_File.put_line` | 692 |
| `Fnd_File.put_line` | 694 |
| `ap_period_close_pkg.process_period` | 696 |
| `Fnd_File.put_line` | 808 |
| `Fnd_File.put_line` | 813 |
| `Fnd_File.put_line` | 814 |
| `Fnd_File.put_line` | 831 |
| `Fnd_File.put_line` | 853 |
| `Fnd_File.put_line` | 854 |
| `Fnd_File.put_line` | 858 |
| `Fnd_File.put_line` | 864 |
| `Fnd_File.put_line` | 873 |
| `dka_tools_pkg.get_message` | 874 |
| `Fnd_File.put_line` | 875 |
| `Fnd_File.put_line` | 887 |
| `Fnd_File.put_line` | 891 |
| `Fnd_File.put_line` | 892 |
| `Fnd_File.put_line` | 893 |
| `Fnd_File.put_line` | 894 |
| `Fnd_File.put_line` | 964 |
| `fnd_profile.VALUE` | 965 |
| `Fnd_File.put_line` | 966 |
| `FND_PROFILE.VALUE` | 968 |
| `FND_PROFILE.VALUE` | 969 |
| `FND_PROFILE.VALUE` | 970 |
| `FND_GLOBAL.APPS_INITIALIZE` | 972 |
| `Fnd_File.put_line` | 979 |
| `dka_sapcloture_pkg.cherche_period` | 980 |
| `Fnd_File.put_line` | 985 |
| `Fnd_File.put_line` | 986 |
| `Fnd_File.put_line` | 991 |
| `Fnd_File.put_line` | 993 |
| `Fnd_File.put_line` | 994 |
| `dka_sapcloture_pkg.cherche_next_period` | 996 |
| `Fnd_File.put_line` | 998 |
| `Fnd_File.put_line` | 1003 |
| `Fnd_File.put_line` | 1012 |
| `Fnd_File.put_line` | 1027 |
| `Fnd_File.put_line` | 1028 |
| `Fnd_File.put_line` | 1037 |
| `Fnd_File.put_line` | 1045 |
| `Fnd_File.put_line` | 1053 |
| `FND_GLOBAL.APPS_INITIALIZE` | 1065 |
| `Fnd_File.put_line` | 1072 |
| `Fnd_File.put_line` | 1073 |
| `FND_REQUEST.ADD_LAYOUT` | 1086 |
| `Fnd_Request.submit_request` | 1092 |
| `fnd_file.put_line` | 1112 |
| `Fnd_File.put_line` | 1115 |
| `Fnd_File.put_line` | 1118 |
| `Fnd_File.put_line` | 1119 |
| `Fnd_File.put_line` | 1130 |
| `Fnd_File.put_line` | 1134 |
| `Fnd_Concurrent.wait_for_request` | 1144 |
| `Fnd_file.put_line` | 1147 |
| `Fnd_File.put_line` | 1153 |
| `Fnd_File.put_line` | 1154 |
| `Fnd_File.put_line` | 1158 |
| `fnd_file.put_line` | 1166 |
| `Fnd_File.put_line` | 1169 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `APXUATR_XMLP` | 1092 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 826, 856, 1084, 1117 |
| when_others | 102, 161, 828, 861, 900, 1023, 1175 |
| soumission | 1092 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPCLOTURE / DKA | `dka_sapcloture_pkg.main` | dka/12.0.0/admin/import/DKA_SAPCLOTURE.prt:419 |
| DKA_XDODTEXE / DKA | `DKA_SAPCLOTURE_PKG.launch_xdodtexe` | dka/12.0.0/admin/import/DKA_XDODTEXE.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
