# DKA_SARENCAIS_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SARENCAIS_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SARENCAIS_PKG.pks).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 289 ; encodage : cp1252 (repli). SHA-256 : `936bead251958c630f6a7da35e1b4786bb0f28f6616fe8d6feff47481f5a576b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 41 |
| `get_ap_payments` | 58 |
| `get_ar_period_date_f` | 75 |
| `get_customer_partner` | 100 |
| `check_periods` | 124 |
| `insert_ar_transmission` | 143 |
| `insert_ar_interface` | 164 |
| `populate_data` | 182 |
| `run_import` | 199 |
| `run_all_imports` | 220 |
| `tieback` | 238 |
| `output_status` | 252 |
| `create_output` | 268 |
| `main` | 282 |

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

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARENCAIS / DKA | `dka_sarencais_pkg.main` | dka/12.0.0/admin/import/DKA_SARENCAIS_F.prt:419 |
| DKA_SARENCAIS / DKA | `dka_sarencais_pkg.main` | dka/12.0.0/admin/import/DKA_SARENCAIS_F.prt:419 |
| DKA_SARENCAIS / DKA | `dka_sarencais_pkg.main` | dka/12.0.0/admin/import/DKA_SARENCAIS_US.prt:419 |
| DKA_SARENCAIS / DKA | `dka_sarencais_pkg.main` | dka/12.0.0/admin/import/DKA_SARENCAIS_US.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
