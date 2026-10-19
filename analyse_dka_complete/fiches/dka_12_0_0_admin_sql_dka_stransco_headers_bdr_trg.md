# DKA_STRANSCO_HEADERS_BDR.trg

Source : [dka/12.0.0/admin/sql/DKA_STRANSCO_HEADERS_BDR.trg](../../dka/12.0.0/admin/sql/DKA_STRANSCO_HEADERS_BDR.trg).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 34 ; encodage : cp1252 (repli). SHA-256 : `65e0b9ce222923ab01fbbe77ffb6b1104a335b5fe9742cfa321396b8e0c6c744`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_stransco_headers_BDR` | 1 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_STRANSCO_LINES` | 28 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| suppression | 28 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
