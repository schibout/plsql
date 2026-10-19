# DKA_SCTRLMODULE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SCTRLMODULE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SCTRLMODULE_PKG.pkb).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1567 ; encodage : cp1252 (repli). SHA-256 : `0884a30b7b89fa92e03d9577e0fe640dd89994a6bf50474e3b79bfc318a22354`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 67 |
| `log_msg` | 81 |
| `init` | 102 |
| `INIT` | 147 |
| `write_boundary` | 159 |
| `begin_attachment` | 175 |
| `end_attachment` | 216 |
| `envoi_sans_fichier` | 236 |
| `envoi_avec_fichier` | 385 |
| `recherche_mail` | 622 |
| `RECHERCHE_MAIL` | 666 |
| `edition_output_mail` | 682 |
| `EDITION_OUTPUT_MAIL` | 773 |
| `envoi_mail` | 786 |
| `EDITION_OUTPUT_MAIL` | 922 |
| `lance_trait_mail` | 953 |
| `edition_output` | 1048 |
| `EDITION_OUTPUT` | 1137 |
| `main` | 1156 |
| `EDITION_OUTPUT` | 1548 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `all_directories` | 114 |
| `v$database` | 128 |
| `fnd_flex_value_sets` | 251 |
| `DKA_SCTRLMODULE_FILE` | 413 |
| `fnd_flex_value_sets` | 423 |
| `fnd_flex_values_vl` | 627 |
| `fnd_flex_values_vl` | 695 |
| `v$database` | 716 |
| `fnd_application` | 721 |
| `fnd_conc_req_summary_v` | 727 |
| `FND_CONCURRENT_REQUESTS` | 810 |
| `DKA_SCTRLMODULE_FILE` | 845 |
| `DKA_SCTRLMODULE_FILE` | 874 |
| `DKA_SCTRLMODULE_FILE` | 905 |
| `fnd_concurrent_programs` | 975 |
| `DKA_SCTRLMODULE_FILE` | 1064 |
| `v$database` | 1079 |
| `fnd_application` | 1084 |
| `fnd_conc_req_summary_v` | 1090 |
| `fnd_flex_values_vl` | 1166 |
| `fnd_flex_values_vl` | 1226 |
| `fnd_flex_values_vl` | 1247 |
| `fnd_flex_values_vl` | 1268 |
| `fnd_flex_values_vl` | 1292 |
| `DKA_SCTRLMODULE_REQUETE` | 1323 |
| `DKA_SCTRLMODULE_FILE` | 1375 |
| `DKA_SCTRLMODULE_REQUETE` | 1417 |
| `DKA_SCTRLMODULE_FILE` | 1481 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 33 |
| `fnd_file.put_line` | 70 |
| `fnd_file.put_line` | 91 |
| `Dka_Tools_Pkg.get_parameter` | 117 |
| `Dka_Tools_Pkg.get_parameter` | 130 |
| `DKA_TOOLS_PKG.put_log_message` | 144 |
| `DKA_TOOLS_PKG.put_log_message` | 149 |
| `Dka_Tools_Pkg.get_message` | 266 |
| `Dka_Tools_Pkg.get_message` | 275 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 364 |
| `Dka_Tools_Pkg.get_message` | 438 |
| `Dka_Tools_Pkg.get_message` | 448 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 605 |
| `fnd_profile.VALUE` | 722 |
| `fnd_profile.VALUE` | 740 |
| `fnd_request.submit_request` | 985 |
| `fnd_concurrent.wait_for_request` | 1004 |
| `fnd_profile.VALUE` | 1085 |
| `fnd_profile.VALUE` | 1103 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 907, 994, 1504 |
| when_others | 146, 366, 607, 665, 731, 771, 933, 979, 1028, 1094, 1135, 1452, 1556 |
| suppression | 905 |
| soumission | 985 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SCTRLMODULE_EDT / DKA | `DKA_SCTRLMODULE_PKG.main` | dka/12.0.0/admin/import/DKA_SCTRLMODULE_EDT.prt:492 |
| DKA_SCTRLMODULE_MAIL / DKA | `DKA_SCTRLMODULE_PKG.envoi_mail` | dka/12.0.0/admin/import/DKA_SCTRLMODULE_MAIL.prt:459 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
