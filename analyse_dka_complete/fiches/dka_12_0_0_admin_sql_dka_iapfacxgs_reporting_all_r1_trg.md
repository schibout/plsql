# DKA_IAPFACXGS_REPORTING_ALL_R1.trg

Source : [dka/12.0.0/admin/sql/DKA_IAPFACXGS_REPORTING_ALL_R1.trg](../../dka/12.0.0/admin/sql/DKA_IAPFACXGS_REPORTING_ALL_R1.trg).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 24 ; encodage : utf-8. SHA-256 : `42f2f1fe0e1b85522514ded0ff531085bba0280650fd4365cbdb4d2420b082fc`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_IAPFACXGS_REPORTING_ALL_R1` | 10 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_IAPFACXGS_REPORTING_ALL.PRENBFAC` | 4 |
| `or` | 11 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 23 |
| rollback | 7, 8 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
