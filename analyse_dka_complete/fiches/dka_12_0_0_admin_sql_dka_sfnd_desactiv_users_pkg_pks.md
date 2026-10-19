# DKA_SFND_DESACTIV_USERS_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SFND_DESACTIV_USERS_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SFND_DESACTIV_USERS_PKG.pks).

Famille proposée par convention de nommage : **FND / administration**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 85 ; encodage : cp1252 (repli). SHA-256 : `34b1fba8e12c5702d3aa6603045bd034a55e98c1f54bb548d2cb72316bfd8c7a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 32 |
| `get_purchasing_users` | 45 |
| `get_financial_users` | 60 |
| `get_employee_users` | 75 |

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
| DKA_SFND_DESACTIV_USERS / DKA | `DKA_SFND_DESACTIV_USERS_PKG.main` | dka/12.0.0/admin/import/DKA_SFND_DESACTIV_USERS.prt:461 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
