# DKA_HZ_PARTY_SITES.trg

Source : [dka/12.0.0/admin/sql/DKA_HZ_PARTY_SITES.trg](../../dka/12.0.0/admin/sql/DKA_HZ_PARTY_SITES.trg).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 109 ; encodage : cp1252 (repli). SHA-256 : `f0f02096efa7141d05b9061e445cf4dc993ab3514c3c148bb2f60d0d66afc28f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_HZ_PARTY_SITES` | 20 |
| `DKA_HZ_PARTY_SITES` | 22 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `OR` | 23 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_sapfrs_history_pkg.get_vendor_party` | 38 |
| `dka_sapfrs_history_pkg.get_user_name` | 58 |
| `dka_sapfrs_history_pkg.insert_supplier_sites_history` | 65 |
| `dka_sapfrs_history_pkg.insert_supplier_sites_history` | 78 |
| `dka_sapfrs_history_pkg.insert_supplier_sites_history` | 89 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 103 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
