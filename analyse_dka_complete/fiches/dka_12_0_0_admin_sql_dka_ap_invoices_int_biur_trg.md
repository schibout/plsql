# DKA_AP_INVOICES_INT_BIUR.trg

Source : [dka/12.0.0/admin/sql/DKA_AP_INVOICES_INT_BIUR.trg](../../dka/12.0.0/admin/sql/DKA_AP_INVOICES_INT_BIUR.trg).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 53 ; encodage : cp1252 (repli). SHA-256 : `fcb6689a80801ddb1697d56b613b35747e13ae0971a52de6f8a8a6fc3150d4f8`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_AP_INVOICES_INT_BIUR` | 1 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ON` | 21 |
| `po_vendor_sites_all` | 38 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 47 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
