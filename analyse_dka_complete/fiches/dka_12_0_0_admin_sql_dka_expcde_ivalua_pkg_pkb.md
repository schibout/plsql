# DKA_EXPCDE_IVALUA_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_EXPCDE_IVALUA_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_EXPCDE_IVALUA_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1390 ; encodage : cp1252 (repli). SHA-256 : `eda93597257edf3ff53ffbeea5ac1db2555082b64899c39b50bde317fb9057a5`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 66 |
| `log_msg` | 81 |
| `init` | 102 |
| `INIT` | 154 |
| `write_boundary` | 166 |
| `begin_attachment` | 182 |
| `p_put_debug_message` | 224 |
| `p_validate` | 242 |
| `end_attachment` | 263 |
| `envoi_avec_fichier` | 283 |
| `recherche_mail` | 513 |
| `RECHERCHE_MAIL` | 557 |
| `edition_output_mail` | 572 |
| `send_mail` | 714 |
| `EDITION_OUTPUT_MAIL` | 778 |
| `edition_output` | 814 |
| `EDITION_OUTPUT` | 900 |
| `p_check_directory` | 912 |
| `validate_data` | 968 |
| `p_extract_data_excel` | 1030 |
| `p_extract_data_excel` | 1202 |
| `main` | 1222 |
| `VALIDATE_DATA` | 1247 |
| `EXTRACTION` | 1255 |
| `dans` | 1314 |
| `EDITION_OUTPUT` | 1362 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `all_directories` | 114 |
| `v$database` | 128 |
| `fnd_flex_values_vl` | 309 |
| `DKA_EXPCDE_IVALUA_FILE` | 321 |
| `fnd_flex_values_vl` | 518 |
| `fnd_flex_values_vl` | 585 |
| `v$database` | 606 |
| `fnd_application` | 611 |
| `fnd_conc_req_summary_v` | 617 |
| `DKA_EXPCDE_IVALUA_FILE` | 743 |
| `DKA_EXPCDE_IVALUA_FILE` | 761 |
| `DKA_EXPCDE_IVALUA_FILE` | 827 |
| `v$database` | 842 |
| `fnd_application` | 847 |
| `fnd_conc_req_summary_v` | 853 |
| `all_directories` | 918 |
| `dka.DKA_SPOCDE_TRANSFRS_HIST` | 973 |
| `DKA_SPOCDE_TRANSFRS_HIST` | 993 |
| `DKA_SPOCDE_TRANSFRS_HIST` | 1044 |
| `OF` | 1047 |
| `DKA_SPOCDE_TRANSFRS_HIST` | 1081 |
| `DKA_EXPCDE_IVALUA_FILE` | 1164 |
| `DKA_SPOCDE_TRANSFRS_HIST` | 1180 |
| `DKA_EXPCDE_IVALUA_FILE` | 1267 |
| `fnd_flex_values_vl` | 1282 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 24 |
| `fnd_profile.value` | 25 |
| `fnd_file.put_line` | 69 |
| `fnd_file.put_line` | 91 |
| `Dka_Tools_Pkg.get_parameter` | 117 |
| `Dka_Tools_Pkg.get_parameter` | 130 |
| `DKA_TOOLS_PKG.put_log_message` | 151 |
| `DKA_TOOLS_PKG.put_log_message` | 156 |
| `dka_tools_pkg.put_log_message` | 228 |
| `Dka_Tools_Pkg.get_message` | 330 |
| `Dka_Tools_Pkg.get_message` | 335 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 400 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 495 |
| `fnd_profile.VALUE` | 612 |
| `fnd_profile.VALUE` | 848 |
| `Fnd_File.put_line` | 1004 |
| `Fnd_File.put_line` | 1013 |
| `Fnd_File.put_line` | 1014 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 763, 1006, 1174, 1188 |
| when_others | 153, 498, 556, 621, 699, 794, 857, 898, 1010, 1147, 1200, 1380 |
| suppression | 761 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_EXPCDE_TRANSFRS_IVALUA / DKA | `DKA_EXPCDE_IVALUA_PKG.main` | dka/12.0.0/admin/import/DKA_EXPCDE_TRANSFRS_IVALUA.prt:422 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
