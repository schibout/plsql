# DKA_AR_ADJUSTMENTS_ALL_BIR.trg

Source : [dka/12.0.0/admin/sql/DKA_AR_ADJUSTMENTS_ALL_BIR.trg](../../dka/12.0.0/admin/sql/DKA_AR_ADJUSTMENTS_ALL_BIR.trg).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 86 ; encodage : cp1252 (repli). SHA-256 : `7b51df7b51aa5c74bc69f94330c2722805d2e2317b96f42e891aff2103e3a3a0`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_AR_ADJUSTMENTS_ALL_BIR` | 1 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_code_combinations` | 32 |
| `pa_projects_all` | 40 |
| `ar_receivables_trx_all` | 52 |
| `pa_tasks` | 58 |
| `ar_adjustments_all` | 67 |
| `ar_adjustments_all` | 70 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 81 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
