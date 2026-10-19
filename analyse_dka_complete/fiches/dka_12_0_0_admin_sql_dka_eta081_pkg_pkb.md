# DKA_ETA081_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_ETA081_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_ETA081_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 68 ; encodage : cp1252 (repli). SHA-256 : `0bc234e37cd112d36e032384e2ec3eee18443b0d5fafde027affe2c54f9ea6e6`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `INSERT_TABLE_P` | 19 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka` | 42 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 58 |
| `DKA_ETA081_PKG.INSERT_TABLE_P` | 58 |
| `Fnd_File.put_line` | 59 |
| `Fnd_File.put_line` | 60 |
| `Fnd_File.put_line` | 61 |
| `Fnd_File.put_line` | 62 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 56 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
