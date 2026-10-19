# DKA_TOOLS_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_TOOLS_PKG.pks](../../dka/12.0.0/admin/sql/DKA_TOOLS_PKG.pks).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 713 ; encodage : cp1252 (repli). SHA-256 : `2c36ae53e9806a3f22d067bb4690de6e54ad211934cc4f5429aa1cd2c2ddd6fa`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `numeric_check` | 49 |
| `put_log_message` | 68 |
| `put_debug_message` | 84 |
| `put_outdebug_message` | 102 |
| `put_out_header` | 119 |
| `get_filename` | 133 |
| `get_environment_variable` | 154 |
| `open_utl_file` | 177 |
| `open_utl_file_append` | 200 |
| `get_message` | 222 |
| `get_parameter` | 266 |
| `get_code_combination_id` | 302 |
| `get_code_combination_id` | 338 |
| `check_dka_parameters` | 359 |
| `segment_size` | 376 |
| `get_flex_key_seg_value_set` | 382 |
| `ins_prog_message` | 397 |
| `get_cuf_flex_value` | 423 |
| `get_segments_from_ccid` | 455 |
| `get_request_set_params` | 493 |
| `launch_request_set` | 503 |
| `get_code_societe` | 530 |
| `get_org_id` | 553 |
| `trt_car_spec` | 570 |
| `is_bank_holiday` | 583 |
| `get_next_working_day` | 596 |
| `add_error_stack` | 608 |
| `print_error_stack` | 619 |
| `clear_error_stack` | 627 |
| `Create_Table_Online_Patching` | 645 |
| `check_directory` | 656 |
| `check_transco` | 664 |
| `check_value_set` | 672 |
| `check_parameter` | 681 |
| `check_message` | 690 |
| `check_flex_segment` | 702 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
