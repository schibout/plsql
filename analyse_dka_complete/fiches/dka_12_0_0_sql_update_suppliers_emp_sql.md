# UPDATE_SUPPLIERS_EMP.sql

Source : [dka/12.0.0/sql/UPDATE_SUPPLIERS_EMP.sql](../../dka/12.0.0/sql/UPDATE_SUPPLIERS_EMP.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 122 ; encodage : cp1252 (repli). SHA-256 : `2e1c19ee57ccb4d2e0e763da9b1dbc0070f0cd8db6e818b58b7fd99129115562`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ap_suppliers` | 27 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `ap_vendor_pub_pkg.update_vendor` | 79 |
| `fnd_msg_pub.get` | 100 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
