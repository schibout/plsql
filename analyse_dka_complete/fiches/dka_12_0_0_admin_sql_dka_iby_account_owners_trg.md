# DKA_IBY_ACCOUNT_OWNERS.trg

Source : [dka/12.0.0/admin/sql/DKA_IBY_ACCOUNT_OWNERS.trg](../../dka/12.0.0/admin/sql/DKA_IBY_ACCOUNT_OWNERS.trg).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 114 ; encodage : cp1252 (repli). SHA-256 : `37b3f9bc5520d721a5a17ec33bb8db817dea46faab0d1e1caaea6e532dc34f1f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_IBY_ACCOUNT_OWNERS` | 20 |
| `DKA_IBY_ACCOUNT_OWNERS` | 22 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `OR` | 23 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_sapfrs_history_pkg.get_vendor_site_id` | 40 |
| `dka_sapfrs_history_pkg.get_vendor_id` | 43 |
| `dka_sapfrs_history_pkg.get_user_name` | 59 |
| `dka_sapfrs_history_pkg.insert_supplier_sites_history` | 69 |
| `dka_sapfrs_history_pkg.insert_supplier_sites_history` | 82 |
| `dka_sapfrs_history_pkg.insert_supplier_sites_history` | 93 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| transaction_autonome | 37 |
| when_others | 108 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
