# DKA_AP_INVOICE_DIST_BIR.trg

Source : [dka/12.0.0/admin/sql/DKA_AP_INVOICE_DIST_BIR.trg](../../dka/12.0.0/admin/sql/DKA_AP_INVOICE_DIST_BIR.trg).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 660 ; encodage : cp1252 (repli). SHA-256 : `e241fa4f1ff5d18116331de22dc8b65e8d5383c6024490e9472b8682ac98e5c4`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `dka_ap_invoice_dist_bir` | 1 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ON` | 28 |
| `ap_invoices_all` | 72 |
| `pa_tasks` | 130 |
| `gl_period_statuses` | 144 |
| `pa_projects_all` | 161 |
| `pa_tasks` | 181 |
| `gl_code_combinations` | 227 |
| `PA_TASKS` | 252 |
| `ap_invoice_lines_all` | 285 |
| `pa_projects_all` | 300 |
| `pa_projects_all` | 312 |
| `ap_invoices_all` | 408 |
| `pa_segment_rule_pairings` | 429 |
| `pa_segment_rule_pairings` | 471 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_PA_TOOLS_PKG.get_project_info` | 64 |
| `Dka_pa_Tools_Pkg.pa_check_transaction_data` | 195 |
| `FND_LOG.STRING` | 213 |
| `Dka_pa_Tools_Pkg.pa_get_code_z_refac` | 233 |
| `Dka_pa_Tools_Pkg.pa_check_transaction_data` | 263 |
| `DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts` | 348 |
| `FND_LOG.STRING` | 358 |
| `Dka_Spaautoaccounting_Pkg.Run_Cpt_Groupe_Couts_f` | 370 |
| `Dka_Spaautoaccounting_Pkg.run_cpt_groupe_couts_f` | 380 |
| `FND_LOG.STRING` | 394 |
| `Dka_Spaautoaccounting_Pkg.code_interco` | 413 |
| `DKA_PA_TOOLS_PKG.pa_run_accounting_rule` | 436 |
| `DKA_PA_TOOLS_PKG.pa_run_accounting_rule` | 453 |
| `Dka_Tools_Pkg.put_debug_message` | 460 |
| `DKA_PA_TOOLS_PKG.pa_run_accounting_rule` | 478 |
| `Dka_pa_Tools_Pkg.pa_run_accounting_rule` | 494 |
| `Dka_Tools_Pkg.put_debug_message` | 501 |
| `Dka_Pa_Tools_Pkg.pa_run_accounting_rule` | 509 |
| `Dka_Pa_Tools_Pkg.pa_run_accounting_rule` | 517 |
| `Dka_Pa_Tools_Pkg.pa_run_accounting_rule` | 525 |
| `Dka_Tools_Pkg.put_debug_message` | 531 |
| `Dka_Tools_Pkg.get_code_combination_id` | 539 |
| `FND_LOG.STRING` | 618 |
| `FND_LOG.STRING` | 632 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 150, 256, 654 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
