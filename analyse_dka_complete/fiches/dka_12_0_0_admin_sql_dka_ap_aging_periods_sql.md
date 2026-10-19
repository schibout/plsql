# DKA_AP_AGING_PERIODS.sql

Source : [dka/12.0.0/admin/sql/DKA_AP_AGING_PERIODS.sql](../../dka/12.0.0/admin/sql/DKA_AP_AGING_PERIODS.sql).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 436 ; encodage : cp1252 (repli). SHA-256 : `44f37079b63104719561eb616c85dcf7fdd370f40d68b48bfb5483725c5789ed`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Exist_Period_Name` | 52 |
| `Insert_Aging_Periods` | 88 |
| `Insert_Aging_Period_Lines` | 169 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `Ap_Aging_Periods` | 59 |
| `Dual` | 104 |
| `Ap_Aging_Periods` | 109 |
| `Dual` | 191 |
| `Ap_Aging_Period_Lines` | 196 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 426 |
| rollback | 430, 432 |
| when_others | 65, 136, 229, 431 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
