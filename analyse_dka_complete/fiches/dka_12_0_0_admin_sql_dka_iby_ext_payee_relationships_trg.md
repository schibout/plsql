# DKA_IBY_EXT_PAYEE_RELATIONSHIPS.trg

Source : [dka/12.0.0/admin/sql/DKA_IBY_EXT_PAYEE_RELATIONSHIPS.trg](../../dka/12.0.0/admin/sql/DKA_IBY_EXT_PAYEE_RELATIONSHIPS.trg).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 125 ; encodage : cp1252 (repli). SHA-256 : `b659b54309bf8cf9592c7e7fba399f67c0908757d10edca16cb501c2d346fa89`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_IBY_EXT_PAYEE_RELATION` | 20 |
| `DKA_IBY_EXT_PAYEE_RELATION` | 22 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `OR` | 23 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_sapfrs_history_pkg.get_vendor_id` | 40 |
| `dka_sapfrs_history_pkg.get_vendor_name` | 54 |
| `dka_sapfrs_history_pkg.get_vendor_name` | 66 |
| `dka_sapfrs_history_pkg.get_user_name` | 75 |
| `dka_sapfrs_history_pkg.insert_supplier_sites_history` | 83 |
| `dka_sapfrs_history_pkg.insert_supplier_sites_history` | 94 |
| `dka_sapfrs_history_pkg.insert_supplier_sites_history` | 105 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 119 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
