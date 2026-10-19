# DKA_SAPAPPRVL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPAPPRVL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPAPPRVL_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 268 ; encodage : cp1252 (repli). SHA-256 : `f8e5dbc13110e3ef0de7108fad1df08c06e7b448fe57ca30cbc7cc7fd32066bf`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 47 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `hr_operating_units` | 72 |
| `ap_invoices_all` | 75 |
| `dual` | 84 |
| `dual` | 88 |
| `gl_period_statuses` | 91 |
| `dual` | 98 |
| `ap_invoice_distributions_all` | 102 |
| `ap_self_assessed_tax_dist_all` | 112 |
| `ap_self_assessed_tax_dist_all` | 121 |
| `ap_holds_all` | 126 |
| `ap_hold_codes` | 135 |
| `ap_invoice_lines_all` | 140 |
| `ap_invoice_lines_all` | 144 |
| `ap_invoice_distributions_all` | 151 |
| `ap_invoice_distributions_all` | 155 |
| `fnd_responsibility` | 186 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.get_parameter` | 170 |
| `dka_tools_pkg.put_log_message` | 181 |
| `dka_tools_pkg.put_log_message` | 188 |
| `fnd_global.apps_initialize` | 191 |
| `fnd_request.submit_request` | 197 |
| `dka_tools_pkg.put_log_message` | 223 |
| `dka_tools_pkg.put_outdebug_message` | 234 |
| `fnd_concurrent.wait_for_request` | 235 |
| `dka_tools_pkg.put_log_message` | 244 |
| `dka_tools_pkg.put_log_message` | 247 |
| `dka_tools_pkg.put_log_message` | 257 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `APPRVL` | 197 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 229 |
| when_others | 255 |
| soumission | 197 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPAPPRVL / DKA | `DKA_SAPAPPRVL_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SAPAPPRVL.prt:420 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
