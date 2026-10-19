# DKA_OPEN_INTERFACE_AP_EAI_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_OPEN_INTERFACE_AP_EAI_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_OPEN_INTERFACE_AP_EAI_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 730 ; encodage : cp1252 (repli). SHA-256 : `fc6c75bc6ebec79aa3cb7f0304f60cb0c852b88c3a4c7f010b25150b5e05dab7`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 46 |
| `log_msg` | 60 |
| `get_user_eai` | 77 |
| `run_import` | 111 |
| `edition_output_entete` | 210 |
| `EDITION_OUTPUT` | 247 |
| `main` | 259 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_user` | 82 |
| `DKA_OPEN_INTERFACE_AP_EAI` | 219 |
| `AP_INVOICES_INTERFACE` | 275 |
| `AP_INVOICES_INTERFACE` | 302 |
| `DKA_OPEN_INTERFACE_AP_EAI` | 313 |
| `ap_invoices_interface` | 319 |
| `ap_interface_rejections` | 321 |
| `hr_operating_units` | 357 |
| `gl_period_statuses` | 411 |
| `DKA_OPEN_INTERFACE_AP_EAI` | 431 |
| `DKA_STRANSCO_HEADERS` | 446 |
| `AP_SUPPLIERS` | 453 |
| `DKA_OPEN_INTERFACE_AP_EAI` | 463 |
| `DKA_STRANSCO_HEADERS` | 491 |
| `AP_SUPPLIERS` | 499 |
| `DUAL` | 519 |
| `DKA_OPEN_INTERFACE_AP_EAI` | 521 |
| `AP_INVOICES_INTERFACE` | 549 |
| `ap_invoices_all` | 561 |
| `AP_INVOICES_INTERFACE` | 576 |
| `AP_INVOICES_INTERFACE` | 588 |
| `DKA_OPEN_INTERFACE_AP_EAI` | 620 |
| `ap_invoices_all` | 632 |
| `dka_open_interface_ap_eai` | 648 |
| `DKA_OPEN_INTERFACE_AP_EAI` | 665 |
| `fnd_concurrent_requests` | 667 |
| `ap_interface_rejections` | 679 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 49 |
| `fnd_file.put_line` | 70 |
| `Fnd_Request.submit_request` | 128 |
| `DKA_AP_TOOLS_PKG.apply_fonction` | 607 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `APXIIMPT` | 128 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 152, 383, 481, 540, 554, 591, 626 |
| when_others | 88, 194, 245, 361, 417, 435, 457, 503, 720 |
| soumission | 128 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_OPEN_INTERFACE_AP_EAI / DKA | `dka_open_interface_ap_eai_pkg.main` | dka/12.0.0/admin/import/DKA_OPEN_INTERFACE_AP_EAI.prt:482 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
