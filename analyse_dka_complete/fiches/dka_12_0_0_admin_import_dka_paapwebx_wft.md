# DKA_PAAPWEBX.wft

Source : [dka/12.0.0/admin/import/DKA_PAAPWEBX.wft](../../dka/12.0.0/admin/import/DKA_PAAPWEBX.wft).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 6642 ; encodage : utf-8. SHA-256 : `45cf7587b7f946e0e7f5eeb7cefc8f0bbcf617ae1a909fc16a4b793b9fbb311f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `REFERENCES` | 134 |
| `Display` | 1474 |
| `Date` | 1536 |
| `a` | 2220 |
| `Agent` | 2612 |
| `Agent` | 2616 |
| `Agent` | 2620 |
| `emp` | 3325 |
| `Code` | 3924 |
| `Code` | 3954 |
| `other` | 4000 |
| `Code` | 4066 |
| `other` | 4110 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 1798, 1816, 1839, 1857 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
