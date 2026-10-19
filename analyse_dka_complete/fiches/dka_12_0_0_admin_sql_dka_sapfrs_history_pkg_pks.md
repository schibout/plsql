# dka_sapfrs_history_pkg.pks

Source : [dka/12.0.0/admin/sql/dka_sapfrs_history_pkg.pks](../../dka/12.0.0/admin/sql/dka_sapfrs_history_pkg.pks).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 95 ; encodage : cp1252 (repli). SHA-256 : `26f1800fd8229a38f3919a0cb8cc6f5767b1caacd3c19edc116fd493856bfabf`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_user_name` | 32 |
| `get_term_name` | 34 |
| `get_payement_method` | 36 |
| `get_vendor_site_id` | 40 |
| `get_vendor_id` | 45 |
| `get_vendor_name` | 48 |
| `get_vendor_party` | 52 |
| `insert_supplier_mode_p` | 56 |
| `insert_supplier_history` | 65 |
| `insert_supplier_sites_history` | 74 |
| `INSERT_CUSTOMER_HISTORY` | 83 |

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

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
