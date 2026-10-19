# DKA_SARFACMAN_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SARFACMAN_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SARFACMAN_PKG.pks).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 425 ; encodage : cp1252 (repli). SHA-256 : `3df5d8bb1fc11468133b496b86216c23c31c5787d0e820d6723ce7315f14155e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_select_record_group` | 51 |
| `init` | 69 |
| `get_acct_combination` | 89 |
| `purge_sarfacman_tmp` | 127 |
| `insert_sarfacman_tmp` | 147 |
| `insert_pa_events` | 166 |
| `get_societe` | 187 |
| `get_dr_code_combination_id` | 207 |
| `get_code_saisie` | 227 |
| `get_attribute_category` | 246 |
| `events_status_rejection` | 265 |
| `events_type_rejection` | 285 |
| `amount_sign` | 306 |
| `get_code_partenaire` | 329 |
| `get_code_partenaire_desc` | 349 |
| `create_output` | 367 |
| `get_data_for_refaccuf` | 386 |
| `main` | 416 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ar_lookups` | 31 |
| `ra_customer_trx_lines` | 32 |

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
| DKA_SARFACMAN / DKA | `dka_sarfacman_pkg.main` | dka/12.0.0/admin/import/DKA_SARFACMAN.prt:482 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
