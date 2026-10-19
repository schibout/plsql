# DKA_SARCLOTURE_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SARCLOTURE_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SARCLOTURE_PKG.pks).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 271 ; encodage : cp1252 (repli). SHA-256 : `d0d00f280ec74307eab53787ca4fc10746645feae631f78dd550416ccdbaa6a1`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `cherche_period` | 43 |
| `cherche_next_period` | 65 |
| `ar_check_unposted_items_gl` | 89 |
| `ar_check_unposted_adjustments` | 110 |
| `ar_check_unposted_distribution` | 132 |
| `ar_check_unposted_gl_dist` | 155 |
| `ar_check_unposted_receivable` | 177 |
| `ar_check_unposted_receipt_hist` | 199 |
| `ar_check_cash_receipts` | 221 |
| `ar_check_unposted_transaction` | 243 |
| `main` | 263 |

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
| DKA_SARCLOTURE / DKA | `dka_sarcloture_pkg.main` | dka/12.0.0/admin/import/DKA_SARCLOTURE.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
