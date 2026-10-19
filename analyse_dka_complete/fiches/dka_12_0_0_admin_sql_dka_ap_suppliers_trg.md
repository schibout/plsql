# DKA_AP_SUPPLIERS.trg

Source : [dka/12.0.0/admin/sql/DKA_AP_SUPPLIERS.trg](../../dka/12.0.0/admin/sql/DKA_AP_SUPPLIERS.trg).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 110 ; encodage : cp1252 (repli). SHA-256 : `c72a6c889ef4586c732442765e8668d61dbb4b7f4823402a122d37364e28ddb4`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_AP_SUPPLIERS` | 19 |
| `DKA_AP_SUPPLIERS` | 21 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `OR` | 22 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_sapfrs_history_pkg.get_user_name` | 38 |
| `dka_sapfrs_history_pkg.insert_supplier_history` | 71 |
| `dka_sapfrs_history_pkg.insert_supplier_history` | 81 |
| `dka_sapfrs_history_pkg.insert_supplier_history` | 91 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 104 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
