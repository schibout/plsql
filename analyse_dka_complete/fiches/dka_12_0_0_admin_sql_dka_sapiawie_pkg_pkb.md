# DKA_SAPIAWIE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPIAWIE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPIAWIE_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 483 ; encodage : cp1252 (repli). SHA-256 : `df419ca4c006b98a321862e14fff82f5d84fcf5a78b8f138a582394f9bc51914`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `print_log_message` | 32 |
| `print_wf_message` | 60 |
| `is_facture_perimetre_CSP` | 85 |
| `insert_history` | 167 |
| `approuve_facture_auto_pl` | 232 |
| `approuve_facture_auto` | 283 |
| `lance_workflow_CSP` | 317 |
| `Invoice_image_exists` | 390 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_WF_DEBUG` | 70 |
| `hr_all_organization_units` | 115 |
| `dka_stransco_headers` | 131 |
| `dual` | 180 |
| `AP_INVOICES_ALL` | 184 |
| `AP_INV_APRVL_HIST` | 187 |
| `AP_INVOICES_all` | 240 |
| `AP_INVOICE_LINES_ALL` | 253 |
| `ap_invoices_all` | 257 |
| `dual` | 339 |
| `AP_INVOICES_all` | 410 |
| `DKA_STRANSCO_HEADERS` | 419 |
| `fnd_attached_documents` | 443 |
| `AP_INVOICES_ALL` | 463 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `wf_core.CONTEXT` | 43 |
| `fnd_file.put_line` | 45 |
| `WF_ENGINE.SETITEMATTRNumber` | 122 |
| `FND_PROFILE.VALUE` | 207 |
| `fnd_profile.value` | 209 |
| `fnd_profile.value` | 212 |
| `fnd_profile.value` | 213 |
| `FND_PROFILE.VALUE` | 296 |
| `wf_engine.createprocess` | 346 |
| `wf_engine.setitemparent` | 353 |
| `wf_engine.setitemattrnumber` | 362 |
| `wf_engine.startprocess` | 369 |
| `DKA_SAPWFCSP_PKG.print_wf_message` | 429 |
| `DKA_SAPWFCSP_PKG.print_wf_message` | 430 |
| `DKA_SAPWFCSP_PKG.print_wf_message` | 431 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 71, 216, 374, 473 |
| transaction_autonome | 63 |
| when_others | 377, 476 |
| workflow | 122, 298, 346, 353, 362, 369, 373, 378, 477 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
