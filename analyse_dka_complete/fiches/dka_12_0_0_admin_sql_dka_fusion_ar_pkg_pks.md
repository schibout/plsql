# DKA_FUSION_AR_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_FUSION_AR_PKG.pks](../../dka/12.0.0/admin/sql/DKA_FUSION_AR_PKG.pks).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 33 ; encodage : cp1252 (repli). SHA-256 : `7582946247dbe4fd9479b7fd1e8d71fb8fc4758d9bcd2584f90234a9d82f227e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `MAIN` | 23 |
| `FUSION` | 24 |
| `ANNULATION_REGLEMENTS` | 25 |
| `POST_FUSION_AR` | 26 |
| `LISTE_MOUVEMENTS` | 27 |
| `LETTRAGE_ZERO` | 28 |
| `CTR` | 29 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_FUSAR_ANNUL / DKA | `DKA_FUSION_AR_PKG.ANNULATION_REGLEMENTS` | dka/12.0.0/admin/import/DKA_FUSAR_ANNUL.ldt:494 |
| DKA_FUSAR_CTR / DKA | `DKA_FUSION_AR_PKG.CTR` | dka/12.0.0/admin/import/DKA_FUSAR_CTR.ldt:477 |
| DKA_FUSAR_FUSION / DKA | `DKA_FUSION_AR_PKG.FUSION` | dka/12.0.0/admin/import/DKA_FUSAR_FUSION.ldt:494 |
| DKA_FUSAR_LETTR / DKA | `DKA_FUSION_AR_PKG.LETTRAGE_ZERO` | dka/12.0.0/admin/import/DKA_FUSAR_LETTR.ldt:494 |
| DKA_FUSAR_LIST / DKA | `DKA_FUSION_AR_PKG.LISTE_MOUVEMENTS` | dka/12.0.0/admin/import/DKA_FUSAR_LIST.ldt:479 |
| DKA_FUSAR_POST / DKA | `DKA_FUSION_AR_PKG.POST_FUSION_AR` | dka/12.0.0/admin/import/DKA_FUSAR_POST.ldt:494 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
