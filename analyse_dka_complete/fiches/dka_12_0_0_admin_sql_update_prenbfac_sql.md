# UPDATE_PRENBFAC.sql

Source : [dka/12.0.0/admin/sql/UPDATE_PRENBFAC.sql](../../dka/12.0.0/admin/sql/UPDATE_PRENBFAC.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 33 ; encodage : utf-8. SHA-256 : `755402716b4b53bce9b7f5c0f82362ae01381648fdd069a3f4584e853f219173`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `PRENBFAC` | 4 |
| `DKA.DKA_IAPFACXGS_REPORTING_ALL` | 11 |
| `DKA.DKA_IAPFACXGS_INTERFACE` | 14 |
| `DKA.DKA_IAPFACXGS_INT_HIST_LINES` | 17 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 20, 32 |
| rollback | 7, 8 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
