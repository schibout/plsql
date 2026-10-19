# DKA_SARREFAC_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SARREFAC_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SARREFAC_PKG.pks).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 179 ; encodage : cp1252 (repli). SHA-256 : `c98323ee6dc98eae105b48a0da5af20b1ba483d35a617c6edc1d6c4f632af6a4`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `is_transaction_type_refac` | 44 |
| `get_select_record_group` | 65 |
| `check_ap_invoice` | 86 |
| `pa_check_transaction_data` | 109 |
| `main` | 135 |
| `run_all_invoice_printing` | 152 |
| `send_mail` | 168 |

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
| DKA_SARREFAC / DKA | `dka_sarrefac_pkg.main` | dka/12.0.0/admin/import/DKA_SARREFAC.prt:419 |
| DKA_SARREFAC_PRT / DKA | `dka_sarrefac_pkg.run_all_invoice_printing` | dka/12.0.0/admin/import/DKA_SARREFAC_PRT.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
