# DKA_FAFLEXWF.wft

Source : [dka/12.0.0/admin/import/DKA_FAFLEXWF.wft](../../dka/12.0.0/admin/import/DKA_FAFLEXWF.wft).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 7582 ; encodage : cp1252 (repli). SHA-256 : `0ef02eb5c858786c64cf55f6163dd1e6cc6e69d37cc47b4408507e4d132ec2f5`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `REFERENCES` | 134 |
| `the` | 2944 |
| `Default` | 2977 |
| `the` | 3209 |
| `Default` | 3242 |
| `Distribution` | 3264 |
| `Default` | 3296 |
| `Default` | 3456 |
| `Distribution` | 3499 |
| `Default` | 3531 |
| `Default` | 6501 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 1505, 1524, 1549, 1568 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
