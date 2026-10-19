# DKA_AUTO_ETATVA0001.sql

Source : [dka/12.0.0/sql/DKA_AUTO_ETATVA0001.sql](../../dka/12.0.0/sql/DKA_AUTO_ETATVA0001.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1266 ; encodage : cp1252 (repli). SHA-256 : `6ca2ad43e649635af01617b4fd374070092fb60be71e5165ea8bd75506181691`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `positionnement_contexte` | 172 |
| `soumission_traitement` | 246 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `hr_operating_units` | 163 |
| `fnd_user` | 184 |
| `fnd_responsibility` | 203 |
| `fnd_concurrent_programs` | 222 |
| `gl_ledger_le_v` | 377 |
| `gl_period_statuses` | 412 |
| `gl_period_statuses` | 416 |
| `gl_period_statuses` | 430 |
| `all_directories` | 468 |
| `DUAL` | 1257 |
| `DUAL` | 1259 |
| `DUAL` | 1265 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 236 |
| `fnd_profile.value` | 238 |
| `fnd_request.submit_request` | 248 |
| `dka_tools_pkg.tab_request_params` | 254 |
| `dka_tools_pkg.tab_request_params` | 255 |
| `dka_tools_pkg.tab_request_params` | 256 |
| `dka_tools_pkg.tab_request_params` | 257 |
| `dka_tools_pkg.tab_request_params` | 258 |
| `dka_tools_pkg.tab_request_params` | 259 |
| `dka_tools_pkg.tab_request_params` | 260 |
| `dka_tools_pkg.tab_request_params` | 261 |
| `dka_tools_pkg.tab_request_params` | 262 |
| `dka_tools_pkg.tab_request_params` | 263 |
| `dka_tools_pkg.tab_request_params` | 264 |
| `dka_tools_pkg.tab_request_params` | 265 |
| `dka_tools_pkg.tab_request_params` | 266 |
| `dka_tools_pkg.tab_request_params` | 267 |
| `dka_tools_pkg.tab_request_params` | 268 |
| `dka_tools_pkg.tab_request_params` | 269 |
| `dka_tools_pkg.tab_request_params` | 270 |
| `dka_tools_pkg.tab_request_params` | 271 |
| `dka_tools_pkg.tab_request_params` | 272 |
| `FND_PROFILE.VALUE` | 371 |
| `dka_tools_pkg.get_parameter` | 589 |
| `dka_tools_pkg.get_request_set_params` | 624 |
| `dka_tools_pkg.tab_request_params` | 648 |
| `dka_tools_pkg.tab_request_params` | 649 |
| `dka_tools_pkg.tab_request_params` | 664 |
| `dka_tools_pkg.get_parameter` | 679 |
| `dka_tools_pkg.get_request_set_params` | 713 |
| `dka_tools_pkg.tab_request_params` | 737 |
| `dka_tools_pkg.tab_request_params` | 738 |
| `dka_tools_pkg.tab_request_params` | 753 |
| `dka_tools_pkg.get_parameter` | 768 |
| `dka_tools_pkg.get_request_set_params` | 802 |
| `dka_tools_pkg.tab_request_params` | 826 |
| `dka_tools_pkg.tab_request_params` | 827 |
| `dka_tools_pkg.tab_request_params` | 842 |
| `dka_tools_pkg.get_parameter` | 857 |
| `dka_tools_pkg.get_request_set_params` | 904 |
| `dka_tools_pkg.tab_request_params` | 928 |
| `Dka_Tools_Pkg.tab_request_params` | 929 |
| `dka_tools_pkg.tab_request_params` | 930 |
| `dka_tools_pkg.tab_request_params` | 931 |
| `dka_tools_pkg.tab_request_params` | 946 |
| `dka_tools_pkg.tab_request_params` | 948 |
| `dka_tools_pkg.get_parameter` | 967 |
| `Dka_Tools_Pkg.tab_request_params` | 1034 |
| `Dka_Tools_Pkg.tab_request_params` | 1035 |
| `Dka_Tools_Pkg.tab_request_params` | 1036 |
| `Dka_Tools_Pkg.tab_request_params` | 1037 |
| `Dka_Tools_Pkg.tab_request_params` | 1038 |
| `Dka_Tools_Pkg.tab_request_params` | 1039 |
| `Dka_Tools_Pkg.tab_request_params` | 1040 |
| `Dka_Tools_Pkg.tab_request_params` | 1041 |
| `Dka_Tools_Pkg.tab_request_params` | 1042 |
| `Dka_Tools_Pkg.tab_request_params` | 1043 |
| `Dka_Tools_Pkg.tab_request_params` | 1044 |
| `Dka_Tools_Pkg.tab_request_params` | 1045 |
| `Dka_Tools_Pkg.tab_request_params` | 1046 |
| `Dka_Tools_Pkg.tab_request_params` | 1047 |
| `Dka_Tools_Pkg.tab_request_params` | 1048 |
| `Dka_Tools_Pkg.tab_request_params` | 1049 |
| `Dka_Tools_Pkg.tab_request_params` | 1050 |
| `Dka_Tools_Pkg.tab_request_params` | 1051 |
| `Dka_Tools_Pkg.tab_request_params` | 1052 |
| `Dka_Tools_Pkg.tab_request_params` | 1068 |
| `Dka_Tools_Pkg.tab_request_params` | 1069 |
| `Dka_Tools_Pkg.tab_request_params` | 1070 |
| `Dka_Tools_Pkg.tab_request_params` | 1071 |
| `Dka_Tools_Pkg.tab_request_params` | 1072 |
| `Dka_Tools_Pkg.tab_request_params` | 1073 |
| `Dka_Tools_Pkg.tab_request_params` | 1074 |
| `Dka_Tools_Pkg.tab_request_params` | 1075 |
| `Dka_Tools_Pkg.tab_request_params` | 1076 |
| `Dka_Tools_Pkg.tab_request_params` | 1077 |
| `Dka_Tools_Pkg.tab_request_params` | 1078 |
| `Dka_Tools_Pkg.tab_request_params` | 1079 |
| `Dka_Tools_Pkg.tab_request_params` | 1080 |
| `dka_tools_pkg.get_parameter` | 1094 |
| `dka_tools_pkg.get_request_set_params` | 1128 |
| `dka_tools_pkg.tab_request_params` | 1144 |
| `dka_tools_pkg.tab_request_params` | 1145 |
| `dka_tools_pkg.tab_request_params` | 1181 |
| `fnd_concurrent.wait_for_request` | 1205 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

| Élément | Ligne source |
|---|---:|
| `$DKA_TOP/bin/DKA_ETATVA0001_BOR.sh` | 1261 |

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 360 |
| when_others | 188, 207, 228, 479, 1249 |
| soumission | 248 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AUTO_ETATVA0001 / DKA | `DKA_AUTO_ETATVA0001` | dka/12.0.0/admin/import/DKA_AUTO_ETATVA0001.prt:520 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
