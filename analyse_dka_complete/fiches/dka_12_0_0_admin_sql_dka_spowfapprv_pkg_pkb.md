# DKA_SPOWFAPPRV_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOWFAPPRV_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOWFAPPRV_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 485 ; encodage : cp1252 (repli). SHA-256 : `a7f004ca31dc1cd7f166ffe094c36452080b5cebfa60c18e89f4aed06094d810`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `updtpoitemtype` | 45 |
| `updtreqitemtype` | 83 |
| `updtrelitemtype` | 121 |
| `register_doc_submitted` | 164 |
| `alim_description_contrat_sstr` | 281 |
| `PO_NEW_COMMUNICATION` | 442 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_headers` | 55 |
| `po_requisition_headers` | 93 |
| `po_releases` | 132 |
| `po_headers_all` | 349 |
| `po_headers_all` | 362 |
| `po_headers_all` | 393 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.VALUE` | 28 |
| `wf_core.CONTEXT` | 67 |
| `wf_core.CONTEXT` | 105 |
| `wf_core.CONTEXT` | 144 |
| `po_wf_debug_pkg.insert_debug` | 184 |
| `wf_engine.getitemattrnumber` | 198 |
| `fnd_client_info.set_org_context` | 205 |
| `wf_engine.getitemattrtext` | 209 |
| `wf_engine.getitemattrtext` | 213 |
| `po_wf_debug_pkg.insert_debug` | 242 |
| `po_reqapproval_init1.get_error_doc` | 247 |
| `po_reqapproval_init1.get_preparer_user_name` | 249 |
| `wf_core.CONTEXT` | 251 |
| `po_reqapproval_init1.send_error_notif` | 254 |
| `PO_WF_DEBUG_PKG.insert_debug` | 303 |
| `PO_REQAPPROVAL_INIT1.Set_doc_mgr_context` | 315 |
| `wf_engine.GetItemAttrNumber` | 318 |
| `fnd_client_info.set_org_context` | 324 |
| `wf_engine.GetItemAttrText` | 328 |
| `wf_engine.GetItemAttrNumber` | 332 |
| `wf_engine.SetItemAttrText` | 339 |
| `wf_engine.SetItemAttrText` | 369 |
| `wf_engine.SetItemAttrText` | 376 |
| `wf_engine.SetItemAttrText` | 402 |
| `po_wf_debug_pkg.insert_debug` | 418 |
| `po_reqapproval_init1.get_error_doc` | 423 |
| `po_reqapproval_init1.get_preparer_user_name` | 425 |
| `wf_core.CONTEXT` | 427 |
| `po_reqapproval_init1.send_error_notif` | 430 |
| `PO_WF_DEBUG_PKG.insert_debug` | 455 |
| `PO_WF_DEBUG_PKG.insert_debug` | 474 |
| `wf_core.context` | 476 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 63, 101, 140 |
| transaction_autonome | 86, 124 |
| when_others | 66, 104, 143, 246, 375, 422, 471 |
| workflow | 189, 192, 198, 209, 213, 235, 307, 309, 318, 328, 332, 339, 369, 376, 402, 411, 460, 462, 467 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
