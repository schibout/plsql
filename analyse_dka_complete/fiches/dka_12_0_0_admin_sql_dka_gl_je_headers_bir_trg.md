# DKA_GL_JE_HEADERS_BIR.trg

Source : [dka/12.0.0/admin/sql/DKA_GL_JE_HEADERS_BIR.trg](../../dka/12.0.0/admin/sql/DKA_GL_JE_HEADERS_BIR.trg).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 85 ; encodage : cp1252 (repli). SHA-256 : `5d9f175ce64e81541988fc8d52f6912fcdad37f09dc0c886faf3610e193a7f20`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_GL_JE_HEADERS_BIR` | 2 |
| `DKA_GL_JE_HEADERS_BIR` | 4 |
| `DKA_GL_JE_HEADERS_BIR` | 6 |
| `Dka_Gl_Je_Headers_Bir` | 83 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `Gl_Recurring_Headers_V` | 51 |
| `Fnd_Flex_Value_Sets` | 55 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 75 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
