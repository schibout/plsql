# DKA_SPOBON_WF_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOBON_WF_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOBON_WF_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 917 ; encodage : cp1252 (repli). SHA-256 : `0ba3858599d011a55a8e3bf3e562959092d4155cbf2b0e1395b0e25a12980c18`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `is_order_ssp_approved` | 63 |
| `print_order_pdf` | 142 |
| `print_and_fax_order_pdf` | 305 |
| `is_asset_order` | 602 |
| `last_approb_da` | 674 |
| `is_ivalua_order` | 878 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_requisition_headers_all` | 91 |
| `po_headers_all` | 172 |
| `fnd_responsibility` | 198 |
| `po_headers_all` | 272 |
| `po_headers_all` | 335 |
| `fnd_responsibility` | 361 |
| `FND_DESCR_FLEX_COL_USAGE_VL` | 399 |
| `po_headers_all` | 563 |
| `po_headers_all` | 624 |
| `po_distributions_all` | 626 |
| `po_distributions_all` | 725 |
| `po_distributions_all` | 738 |
| `po_line_locations_all` | 756 |
| `PO_ACTION_HISTORY` | 840 |
| `PO_HEADERS_ALL` | 896 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `wf_engine.getitemattrnumber` | 83 |
| `po_wf_debug_pkg.insert_debug` | 85 |
| `wf_core.CONTEXT` | 124 |
| `po_wf_debug_pkg.insert_debug` | 166 |
| `wf_engine.getitemattrnumber` | 168 |
| `po_wf_debug_pkg.insert_debug` | 177 |
| `PO_MOAC_UTILS_PVT.set_org_context` | 192 |
| `fnd_profile.get` | 202 |
| `FND_GLOBAL.APPS_INITIALIZE` | 204 |
| `Fnd_Request.set_org_id` | 210 |
| `fnd_file.put_line` | 217 |
| `fnd_file.put_line` | 218 |
| `po_wf_debug_pkg.insert_debug` | 224 |
| `fnd_profile.get` | 227 |
| `fnd_request.set_options` | 232 |
| `FND_PROFILE.VALUE` | 232 |
| `fnd_profile.get` | 238 |
| `fnd_request.set_print_options` | 239 |
| `po_wf_debug_pkg.insert_debug` | 243 |
| `fnd_request.submit_request` | 244 |
| `po_wf_debug_pkg.insert_debug` | 270 |
| `po_wf_debug_pkg.insert_debug` | 278 |
| `wf_core.CONTEXT` | 283 |
| `wf_core.CONTEXT` | 287 |
| `po_wf_debug_pkg.insert_debug` | 329 |
| `wf_engine.getitemattrnumber` | 331 |
| `po_wf_debug_pkg.insert_debug` | 340 |
| `PO_MOAC_UTILS_PVT.set_org_context` | 355 |
| `fnd_profile.get` | 365 |
| `FND_GLOBAL.APPS_INITIALIZE` | 367 |
| `Fnd_Request.set_org_id` | 373 |
| `fnd_file.put_line` | 379 |
| `fnd_file.put_line` | 380 |
| `po_wf_debug_pkg.insert_debug` | 388 |
| `fnd_profile.get` | 391 |
| `fnd_profile.get` | 408 |
| `fnd_request.set_print_options` | 409 |
| `po_wf_debug_pkg.insert_debug` | 411 |
| `po_wf_debug_pkg.insert_debug` | 415 |
| `fnd_submit.set_org_id` | 416 |
| `po_wf_debug_pkg.insert_debug` | 420 |
| `fnd_submit.set_nls_options` | 423 |
| `fnd_submit.set_request_set` | 429 |
| `fnd_submit.set_org_id` | 434 |
| `fnd_submit.set_nls_options` | 437 |
| `po_wf_debug_pkg.insert_debug` | 445 |
| `fnd_submit.submit_program` | 447 |
| `fnd_submit.set_org_id` | 488 |
| `fnd_submit.set_nls_options` | 491 |
| `po_wf_debug_pkg.insert_debug` | 498 |
| `fnd_submit.submit_program` | 500 |
| `fnd_submit.set_org_id` | 513 |
| `fnd_submit.set_nls_options` | 516 |
| `po_wf_debug_pkg.insert_debug` | 523 |
| `fnd_submit.submit_program` | 525 |
| `fnd_submit.set_org_id` | 535 |
| `fnd_submit.set_nls_options` | 538 |
| `po_wf_debug_pkg.insert_debug` | 545 |
| `fnd_submit.submit_program` | 547 |
| `po_wf_debug_pkg.insert_debug` | 556 |
| `fnd_submit.submit_set` | 557 |
| `po_wf_debug_pkg.insert_debug` | 560 |
| `po_wf_debug_pkg.insert_debug` | 576 |
| `wf_core.CONTEXT` | 580 |
| `wf_core.CONTEXT` | 584 |
| `wf_engine.getitemattrnumber` | 616 |
| `po_wf_debug_pkg.insert_debug` | 618 |
| `wf_core.CONTEXT` | 656 |
| `po_wf_debug_pkg.insert_debug` | 702 |
| `wf_engine.GetItemAttrNumber` | 705 |
| `po_wf_debug_pkg.insert_debug` | 711 |
| `wf_engine.GetItemAttrNumber` | 714 |
| `po_wf_debug_pkg.insert_debug` | 720 |
| `po_wf_debug_pkg.insert_debug` | 731 |
| `po_wf_debug_pkg.insert_debug` | 746 |
| `po_wf_debug_pkg.insert_debug` | 784 |
| `wf_engine.SetItemAttrNumber` | 789 |
| `wf_engine.SetItemAttrText` | 795 |
| `wf_engine.SetItemAttrText` | 803 |
| `wf_engine.SetItemAttrNumber` | 809 |
| `wf_engine.SetItemAttrText` | 815 |
| `wf_engine.SetItemAttrText` | 821 |
| `wf_engine.SetItemAttrText` | 829 |
| `wf_engine.SetItemAttrText` | 835 |
| `wf_core.CONTEXT` | 860 |
| `po_wf_debug_pkg.insert_debug` | 889 |
| `wf_engine.GetItemAttrNumber` | 892 |
| `wf_core.CONTEXT` | 909 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_SPOBON_PDF` | 244 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 845 |
| when_others | 122, 213, 285, 376, 404, 582, 633, 654, 859, 908 |
| soumission | 244 |
| workflow | 83, 112, 115, 121, 168, 181, 183, 276, 331, 344, 346, 574, 616, 644, 647, 653, 705, 714, 789, 795, 803, 809, 815, 821, 829, 835, 847, 851, 858, 892, 899, 901, 907 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
