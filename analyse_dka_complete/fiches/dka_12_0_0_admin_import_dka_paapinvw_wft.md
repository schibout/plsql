# DKA_PAAPINVW.wft

Source : [dka/12.0.0/admin/import/DKA_PAAPINVW.wft](../../dka/12.0.0/admin/import/DKA_PAAPINVW.wft).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 6748 ; encodage : utf-8. SHA-256 : `c34ffb391826062786663f92b0ba93b5646f9ed7fa9c1fb725373cbd9d71564c`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `REFERENCES` | 134 |
| `Display` | 1445 |
| `Date` | 1480 |
| `a` | 2172 |
| `Agent` | 2564 |
| `Agent` | 2568 |
| `Agent` | 2572 |
| `Flexbuilder` | 3890 |
| `Flexbuilder` | 3952 |
| `Flexbuilder` | 3953 |
| `Code` | 4036 |
| `Code` | 4066 |
| `other` | 4112 |
| `Code` | 4178 |
| `other` | 4222 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 1750, 1768, 1791, 1809 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
