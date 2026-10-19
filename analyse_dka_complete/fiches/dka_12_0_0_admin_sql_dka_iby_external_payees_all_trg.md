# DKA_IBY_EXTERNAL_PAYEES_ALL.trg

Source : [dka/12.0.0/admin/sql/DKA_IBY_EXTERNAL_PAYEES_ALL.trg](../../dka/12.0.0/admin/sql/DKA_IBY_EXTERNAL_PAYEES_ALL.trg).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 107 ; encodage : cp1252 (repli). SHA-256 : `a44e8cd0cacc4a0477705a330728e632025c3cdce507cb7e7b3f4b0f1c4b8ce1`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_IBY_EXTERNAL_PAYEES_ALL` | 20 |
| `APPS.DKA_IBY_EXTERNAL_PAYEES_ALL` | 22 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `OR` | 23 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_sapfrs_history_pkg.get_vendor_id` | 38 |
| `dka_sapfrs_history_pkg.get_user_name` | 55 |
| `dka_sapfrs_history_pkg.insert_supplier_sites_history` | 63 |
| `dka_sapfrs_history_pkg.insert_supplier_sites_history` | 74 |
| `dka_sapfrs_history_pkg.insert_supplier_sites_history` | 85 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 100 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
