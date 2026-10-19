# DKA_IARPAFAC_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_IARPAFAC_PKG.pks](../../dka/12.0.0/admin/sql/DKA_IARPAFAC_PKG.pks).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 576 ; encodage : cp1252 (repli). SHA-256 : `be400b3c928e7808eb2ba465e8a07842a951abbceb2b5a8409ea6ed6cb27efec`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `create_ext_instrument` | 61 |
| `load_invoice_header` | 81 |
| `load_invoice_line` | 105 |
| `get_acct_area` | 135 |
| `get_ar_gl_date` | 157 |
| `get_transaction_type` | 177 |
| `get_ccid_ttc` | 193 |
| `get_ccid_tax` | 226 |
| `get_ccid_attributes_line` | 271 |
| `get_ccid_surtaxe` | 316 |
| `get_ar_tax` | 345 |
| `get_customer_info` | 374 |
| `check_project` | 404 |
| `update_request_id` | 427 |
| `update_group_id` | 447 |
| `get_millesim_batch_id` | 470 |
| `init` | 490 |
| `run_import` | 510 |
| `run_recyclage_rejections` | 537 |
| `update_prlvt_invoice` | 555 |
| `main` | 570 |

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
| DKA_IARPAFAC / DKA | `DKA_IARPAFAC_PKG.Main` | dka/12.0.0/admin/import/DKA_IARPAFAC.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
