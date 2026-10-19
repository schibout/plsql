# DKA_SPOBON_XML_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOBON_XML_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOBON_XML_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 3691 ; encodage : cp1252 (repli). SHA-256 : `bf0ae102d5d560aa8c7f55a0b225c21a9786498602d0c72f4d3853e0483f7652`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `log_msg` | 124 |
| `out_msg` | 146 |
| `get_time` | 161 |
| `convert_type_mime` | 173 |
| `get_order_header_note` | 266 |
| `get_req_file` | 462 |
| `get_order_line_note` | 552 |
| `get_order_line_shipment` | 640 |
| `write_boundary` | 717 |
| `begin_attachment` | 733 |
| `end_attachment` | 760 |
| `init` | 777 |
| `INIT` | 1055 |
| `maj_order` | 1070 |
| `MAJ_ORDER` | 1111 |
| `construction_xml` | 1125 |
| `CONSTRUCTION_XML` | 2622 |
| `send_mail_ref` | 2638 |
| `SEND_MAIL_REF` | 2706 |
| `envoi_mail` | 2719 |
| `ENVOI_MAIL` | 3363 |
| `edition_output` | 3379 |
| `EDITION_OUTPUT` | 3463 |
| `main` | 3477 |
| `INIT` | 3613 |
| `CONSTRUCTION_XML` | 3632 |
| `ENVOI_MAIL` | 3636 |
| `MAJ_ORDER` | 3641 |
| `EDITION_OUTPUT` | 3674 |
| `MAIN` | 3682 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_attached_documents` | 304 |
| `fnd_attached_documents` | 328 |
| `fnd_attached_documents` | 486 |
| `fnd_lobs` | 510 |
| `fnd_attached_documents` | 556 |
| `fnd_attached_documents` | 578 |
| `fnd_attached_documents` | 646 |
| `fnd_documents_short_text` | 681 |
| `fnd_documents_long_text` | 690 |
| `fnd_concurrent_requests` | 808 |
| `hr_operating_units` | 840 |
| `fnd_responsibility_tl` | 851 |
| `fnd_concurrent_requests` | 892 |
| `all_directories` | 923 |
| `po_headers` | 946 |
| `v$database` | 994 |
| `po_headers` | 1088 |
| `PO_HEADERS_ARCHIVE` | 1097 |
| `fnd_flex_value_sets` | 1151 |
| `per_phones` | 1164 |
| `Per_Assignments_f` | 1178 |
| `PO_REQUISITION_LINES_ALL` | 1229 |
| `dka_po_headers_print_niv1_v` | 1279 |
| `HZ_PARTY_SITES` | 1310 |
| `po_line_locations` | 1336 |
| `pa_projects_all` | 1500 |
| `ICX_CAT_ITEMS_TLP` | 1572 |
| `to_char` | 2384 |
| `to_char` | 2415 |
| `to_char` | 2582 |
| `fnd_application` | 3402 |
| `fnd_conc_req_summary_v` | 3408 |
| `po_headers` | 3525 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 134 |
| `fnd_file.put_line` | 149 |
| `fnd_global.apps_initialize` | 859 |
| `Dka_Tools_Pkg.get_parameter` | 970 |
| `Dka_Tools_Pkg.get_parameter` | 981 |
| `Dka_Tools_Pkg.get_parameter` | 1000 |
| `Dka_Tools_Pkg.get_parameter` | 1007 |
| `Dka_Tools_Pkg.get_parameter` | 1025 |
| `Dka_Tools_Pkg.get_parameter` | 1032 |
| `DKA_SPOBON_PKG.nb_promised_date` | 1140 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1192 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1193 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1194 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1195 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1196 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1199 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1210 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1211 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1235 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1237 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1239 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1241 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1243 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1245 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1256 |
| `DKA_SPOBON_PKG.nb_ship_to_location_id` | 1258 |
| `Dka_Tools_Pkg.get_message` | 2757 |
| `Fnd_Message.set_name` | 2765 |
| `Fnd_Message.set_token` | 2766 |
| `Fnd_Message.set_token` | 2767 |
| `Fnd_Message.set_token` | 2768 |
| `Fnd_Message.set_token` | 2769 |
| `Fnd_Message.set_token` | 2770 |
| `Fnd_Message.set_token` | 2771 |
| `Fnd_Message.set_token` | 2772 |
| `Fnd_Message.set_token` | 2776 |
| `Fnd_Message.set_token` | 2777 |
| `Fnd_Message.set_token` | 2778 |
| `Fnd_Message.set_token` | 2779 |
| `Fnd_Message.set_token` | 2780 |
| `Fnd_Message.set_token` | 2781 |
| `Dka_Tools_Pkg.get_message` | 3330 |
| `Dka_Tools_Pkg.get_message` | 3332 |
| `Dka_Tools_Pkg.get_message` | 3339 |
| `Dka_Tools_Pkg.get_message` | 3341 |
| `Dka_Tools_Pkg.get_message` | 3353 |
| `Dka_Tools_Pkg.get_message` | 3355 |
| `fnd_profile.VALUE` | 3403 |
| `fnd_profile.VALUE` | 3421 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3684 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 442, 529, 1054, 1110, 1578, 1596, 2621, 2702, 2785, 3362, 3412, 3461, 3681 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOBON_XML / DKA | `DKA_SPOBON_XML_PKG.main` | dka/12.0.0/admin/import/DKA_SPOBON_XML_F.prt:579 |
| DKA_SPOBON_XML / DKA | `DKA_SPOBON_XML_PKG.main` | dka/12.0.0/admin/import/DKA_SPOBON_XML_F.prt:579 |
| DKA_SPOBON_XML / DKA | `DKA_SPOBON_XML_PKG.main` | dka/12.0.0/admin/import/DKA_SPOBON_XML_US.prt:579 |
| DKA_SPOBON_XML / DKA | `DKA_SPOBON_XML_PKG.main` | dka/12.0.0/admin/import/DKA_SPOBON_XML_US.prt:579 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
