# DKA_SCTRLMOD_MOA_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SCTRLMOD_MOA_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SCTRLMOD_MOA_PKG.pkb).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2094 ; encodage : cp1252 (repli). SHA-256 : `9f50f2f2686f140f81ea8194e86545d1226ffd6450910d699b56253998942df3`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 59 |
| `log_msg` | 73 |
| `init` | 94 |
| `INIT` | 139 |
| `write_boundary` | 151 |
| `begin_attachment` | 167 |
| `end_attachment` | 208 |
| `envoi_sans_fichier` | 228 |
| `envoi_avec_fichier` | 425 |
| `recherche_mail` | 710 |
| `RECHERCHE_MAIL` | 754 |
| `edition_output_mail` | 770 |
| `EDITION_OUTPUT_MAIL` | 861 |
| `send_mail` | 874 |
| `EDITION_OUTPUT_MAIL` | 1000 |
| `lance_trait_mail` | 1031 |
| `edition_output` | 1133 |
| `EDITION_OUTPUT` | 1222 |
| `main` | 1241 |
| `EDITION_OUTPUT` | 2070 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `all_directories` | 106 |
| `v$database` | 120 |
| `fnd_flex_values_vl` | 244 |
| `fnd_flex_values_vl` | 253 |
| `DKA_SCTRLMOD_MOA_FILE` | 454 |
| `fnd_flex_values_vl` | 464 |
| `fnd_flex_values_vl` | 473 |
| `fnd_flex_values_vl` | 715 |
| `fnd_flex_values_vl` | 783 |
| `v$database` | 804 |
| `fnd_application` | 809 |
| `fnd_conc_req_summary_v` | 815 |
| `FND_CONCURRENT_REQUESTS` | 898 |
| `DKA_SCTRLMOD_MOA_FILE` | 923 |
| `DKA_SCTRLMOD_MOA_FILE` | 952 |
| `DKA_SCTRLMOD_MOA_FILE` | 983 |
| `fnd_concurrent_programs` | 1053 |
| `DKA_SCTRLMOD_MOA_FILE` | 1149 |
| `v$database` | 1164 |
| `fnd_application` | 1169 |
| `fnd_conc_req_summary_v` | 1175 |
| `fnd_flex_values_vl` | 1253 |
| `fnd_flex_values_vl` | 1327 |
| `fnd_flex_values_vl` | 1348 |
| `fnd_flex_values_vl` | 1369 |
| `dual` | 1386 |
| `fnd_flex_values_vl` | 1398 |
| `DKA_SCTRLMOD_MOA_REQUETE` | 1434 |
| `DKA_SCTRLMOD_MOA_FILE` | 1489 |
| `DKA_SCTRLMOD_MOA_REQUETE` | 1539 |
| `DKA_SCTRLMOD_MOA_FILE` | 1604 |
| `DKA_SCTRLMOD_MOA_FILE` | 1669 |
| `DKA_SCTRLMOD_MOA_FILE` | 1734 |
| `DKA_SCTRLMOD_MOA_FILE` | 1799 |
| `DKA_SCTRLMOD_MOA_FILE` | 1864 |
| `DKA_SCTRLMOD_MOA_FILE` | 1929 |
| `DKA_SCTRLMOD_MOA_FILE` | 1994 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 25 |
| `fnd_file.put_line` | 62 |
| `fnd_file.put_line` | 83 |
| `Dka_Tools_Pkg.get_parameter` | 109 |
| `Dka_Tools_Pkg.get_parameter` | 122 |
| `DKA_TOOLS_PKG.put_log_message` | 136 |
| `DKA_TOOLS_PKG.put_log_message` | 141 |
| `Dka_Tools_Pkg.get_message` | 266 |
| `Dka_Tools_Pkg.get_message` | 273 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 404 |
| `Dka_Tools_Pkg.get_message` | 487 |
| `Dka_Tools_Pkg.get_message` | 495 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 692 |
| `fnd_profile.VALUE` | 810 |
| `fnd_profile.VALUE` | 828 |
| `fnd_request.submit_request` | 1063 |
| `fnd_concurrent.wait_for_request` | 1082 |
| `fnd_profile.VALUE` | 1170 |
| `fnd_profile.VALUE` | 1188 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 985, 1072, 1505, 1620, 1685, 1750, 1815, 1880, 1945, 2010, 2026 |
| when_others | 138, 406, 695, 753, 819, 859, 1011, 1057, 1112, 1179, 1220, 1575, 1640, 1705, 1770, 1835, 1900, 1965, 2083 |
| suppression | 983 |
| soumission | 1063 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SCTRLMOD_MOA_EDT / DKA | `DKA_SCTRLMOD_MOA_PKG.main` | dka/12.0.0/admin/import/DKA_SCTRLMOD_MOA_EDT.prt:650 |
| DKA_SCTRLMOD_MOA_MAIL / DKA | `DKA_SCTRLMOD_MOA_PKG.send_mail` | dka/12.0.0/admin/import/DKA_SCTRLMOD_MOA_MAIL.prt:459 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
