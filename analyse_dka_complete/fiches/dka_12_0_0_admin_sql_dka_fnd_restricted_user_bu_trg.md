# DKA_FND_RESTRICTED_USER_BU.trg

Source : [dka/12.0.0/admin/sql/DKA_FND_RESTRICTED_USER_BU.trg](../../dka/12.0.0/admin/sql/DKA_FND_RESTRICTED_USER_BU.trg).

Famille proposée par convention de nommage : **FND / administration**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 73 ; encodage : cp1252 (repli). SHA-256 : `ca3053eb0bbfa2a1cfa9070c24a59f67fa78f834289cc36e32f1c4a68857de2b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_FND_RESTRICTED_USER_BU` | 1 |
| `DKA_FND_RESTRICTED_USER_BU` | 72 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ON` | 18 |
| `dka_parameters` | 39 |
| `ak_web_user_sec_attr_values` | 53 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 45 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
