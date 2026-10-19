# DKA_XX_LOADER_UTILS_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_XX_LOADER_UTILS_PKG.pks](../../dka/12.0.0/admin/sql/DKA_XX_LOADER_UTILS_PKG.pks).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 426 ; encodage : cp1252 (repli). SHA-256 : `b9e42ab0c50c1b6f37cee51464f15f0cda468a59e6f4db53ad92b0aee93b2c75`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `debug_on` | 28 |
| `debug_off` | 29 |
| `version` | 31 |
| `message` | 32 |
| `get_element` | 34 |
| `get_appl_short_name` | 40 |
| `get_vset_long` | 44 |
| `create_value_set` | 53 |
| `df_setup` | 76 |
| `df_context` | 86 |
| `df_segment` | 95 |
| `df_setup_tl` | 117 |
| `df_context_tl` | 125 |
| `df_segment_tl` | 134 |
| `executable` | 148 |
| `executable_desc` | 159 |
| `program` | 167 |
| `program_desc` | 192 |
| `parameter` | 200 |
| `parameter_desc` | 220 |
| `request_group` | 229 |
| `request_group_unit` | 235 |
| `create_update_exe_p` | 241 |
| `update_exe_p` | 252 |
| `delete_exe_prog_p` | 260 |
| `delete_params_prog_p` | 268 |
| `request_set` | 273 |
| `request_set_desc` | 283 |
| `request_stage` | 292 |
| `request_stage_desc` | 306 |
| `link_stage` | 316 |
| `set_program` | 325 |
| `set_program_param` | 339 |
| `set_incompatibility` | 354 |
| `prog_incompatibility` | 364 |
| `dka_fnd_lookup_type` | 376 |
| `dka_fnd_lookup_values_desc` | 385 |
| `dka_fnd_profile_options_desc` | 393 |
| `message` | 400 |
| `dka_parameter` | 407 |

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
| rollback | 2 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
