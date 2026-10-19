# DKA_SGLCTRLFLUXIFRS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SGLCTRLFLUXIFRS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SGLCTRLFLUXIFRS_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1005 ; encodage : cp1252 (repli). SHA-256 : `32fb409e44c822ee7f122bb3988ef23c672eb19308f958c52495ef3f33392793`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 31 |
| `Init` | 41 |
| `Init` | 64 |
| `get_cuf_flex_value_set_id` | 87 |
| `get_description_flow` | 151 |
| `delete_dka_sglctrlfluxifrs_tmp` | 196 |
| `delete_dka_sglctrlfluxifrs_tmp` | 207 |
| `delete_dka_sglctrlfluxifrs_tmp` | 213 |
| `delete_dka_sglctrlfluxifrs_tmp` | 221 |
| `insert_dka_sglctrlfluxifrs_tmp` | 240 |
| `insert_dka_sglctrlfluxifrs_tmp` | 262 |
| `insert_dka_sglctrlfluxifrs_tmp` | 411 |
| `insert_dka_sglctrlfluxifrs_tmp` | 419 |
| `update_dka_sglctrlfluxifrs_tmp` | 435 |
| `update_dka_ieoglvec01_int` | 468 |
| `update_dka_sglctrlfluxifrs_tmp` | 512 |
| `update_dka_sglctrlfluxifrs_tmp` | 520 |
| `load_dka_sglctrlfluxifrs_tmp` | 537 |
| `load_dka_sglctrlfluxifrs_tmp` | 562 |
| `load_dka_sglctrlfluxifrs_tmp` | 624 |
| `load_dka_sglctrlfluxifrs_tmp` | 632 |
| `extraction_file` | 646 |
| `extraction_file` | 730 |
| `extraction_file` | 850 |
| `main` | 879 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_segment_attribute_values` | 102 |
| `GL_access_set_assignments` | 116 |
| `fnd_flex_values_tl` | 167 |
| `dka_sglctrlfluxifrs_tmp` | 285 |
| `gl_ledgers` | 310 |
| `fnd_flex_values` | 326 |
| `dka_sglctrlfluxifrs_tmp` | 345 |
| `gl_ledgers` | 370 |
| `fnd_flex_values` | 386 |
| `dka_sglctrlfluxifrs_tmp` | 454 |
| `dka_sglctrlfluxifrs_tmp` | 482 |
| `TABLE` | 493 |
| `dka_ieoglvec01_conso_code_v` | 555 |
| `fnd_flex_values` | 676 |
| `dka_sglctrlfluxifrs_tmp` | 685 |
| `dka_sglctrlfluxifrs_tmp` | 710 |
| `gl_ledgers` | 931 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 41 |
| `dka_ieoglvec01_pkg.get_application_short_name` | 50 |
| `dka_ieoglvec01_pkg.get_message` | 55 |
| `dka_ieoglvec01_pkg.get_message` | 56 |
| `dka_ieoglvec01_pkg.get_message` | 57 |
| `dka_ieoglvec01_pkg.get_message` | 58 |
| `dka_ieoglvec01_pkg.get_message` | 59 |
| `dka_ieoglvec01_pkg.get_message` | 60 |
| `dka_ieoglvec01_pkg.get_message` | 61 |
| `Fnd_File.put_line` | 64 |
| `fnd_profile.value` | 116 |
| `dka_ieoglvec01_pkg.get_qual_flex_value_set_id` | 161 |
| `Fnd_File.put_line` | 207 |
| `Fnd_File.put_line` | 212 |
| `Fnd_File.put_line` | 213 |
| `Fnd_File.put_line` | 220 |
| `Fnd_File.put_line` | 221 |
| `Fnd_File.put_line` | 262 |
| `dka_ieoglvec01_pkg.get_segment_num` | 264 |
| `dka_ieoglvec01_pkg.get_segment_num` | 265 |
| `dka_ieoglvec01_pkg.get_segment_num` | 266 |
| `dka_ieoglvec01_pkg.get_segment_num` | 267 |
| `dka_ieoglvec01_pkg.get_segment_num` | 268 |
| `dka_ieoglvec01_pkg.get_cuf_attribute_num` | 269 |
| `dka_ieoglvec01_pkg.get_qual_flex_value_set_name` | 270 |
| `Fnd_File.put_line` | 341 |
| `Fnd_File.put_line` | 342 |
| `dka_ieoglvec01_pkg.get_message` | 342 |
| `Fnd_File.put_line` | 401 |
| `Fnd_File.put_line` | 402 |
| `dka_ieoglvec01_pkg.get_message` | 402 |
| `Fnd_File.put_line` | 407 |
| `Fnd_File.put_line` | 411 |
| `Fnd_File.put_line` | 418 |
| `Fnd_File.put_line` | 419 |
| `dka_ieoglvec01_pkg.get_cuf_attribute_value` | 449 |
| `dka_ieoglvec01_pkg.get_cuf_attribute_value` | 453 |
| `Fnd_File.put_line` | 468 |
| `Fnd_File.put_line` | 493 |
| `Fnd_File.put_line` | 496 |
| `Fnd_File.put_line` | 497 |
| `Fnd_File.put_line` | 503 |
| `Fnd_File.put_line` | 506 |
| `Fnd_File.put_line` | 507 |
| `Fnd_File.put_line` | 512 |
| `Fnd_File.put_line` | 519 |
| `Fnd_File.put_line` | 520 |
| `Fnd_File.put_line` | 562 |
| `Fnd_File.put_line` | 563 |
| `Fnd_File.put_line` | 600 |
| `Fnd_File.put_line` | 603 |
| `Fnd_File.put_line` | 604 |
| `Fnd_File.put_line` | 624 |
| `Fnd_File.put_line` | 631 |
| `Fnd_File.put_line` | 632 |
| `Fnd_File.put_line` | 730 |
| `Fnd_File.put_line` | 744 |
| `Fnd_File.put_line` | 745 |
| `Fnd_File.put_line` | 746 |
| `Fnd_File.put_line` | 747 |
| `Fnd_File.put_line` | 748 |
| `Fnd_File.put_line` | 786 |
| `Fnd_File.put_line` | 827 |
| `Fnd_File.put_line` | 850 |
| `Fnd_File.put_line` | 983 |
| `dka_ieoglvec01_pkg.get_message` | 983 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 856, 861, 988, 993 |
| when_others | 67, 216, 414, 491, 501, 515, 598, 627, 859, 991 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SGLCTRLFLUXIFRS / DKA | `dka_sglctrlfluxifrs_pkg.main` | dka/12.0.0/admin/import/DKA_SGLCTRLFLUXIFRS_F.prt:611 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
