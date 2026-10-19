# DKA_GL_JE_LINES_BIR2.trg

Source : [dka/12.0.0/admin/sql/DKA_GL_JE_LINES_BIR2.trg](../../dka/12.0.0/admin/sql/DKA_GL_JE_LINES_BIR2.trg).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 272 ; encodage : cp1252 (repli). SHA-256 : `9bd74982f67803380cdf0a613be65dab93ffa154f7e384ee017de8de4bfa45bf`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_GL_JE_LINES_BIR2` | 2 |
| `DKA_GL_JE_LINES_BIR2` | 4 |
| `DKA_GL_JE_LINES_BIR2` | 6 |
| `Dka_Gl_Je_Lines_Bir2` | 270 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `Gl_Je_Headers` | 118 |
| `Fnd_Flex_Value_Sets` | 126 |
| `Gl_Code_Combinations` | 197 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Spacutoffgl_Pkg.Controler_Line_Gl` | 203 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 262 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
