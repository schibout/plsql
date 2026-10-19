# DKA_REP_COUTS_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_REP_COUTS_PKG.pks](../../dka/12.0.0/admin/sql/DKA_REP_COUTS_PKG.pks).

Famille proposée par convention de nommage : **Fusion / reprise**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 132 ; encodage : utf-8. SHA-256 : `1d6d0a78106e3acc95f8018ebd1290ad22a2877517b7050dd3be8e26440a502d`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 35 |
| `Launch_Loader` | 56 |
| `insert_pa_transac_interfac_all` | 72 |
| `program_import_couts` | 89 |
| `Report_Bilan` | 106 |
| `MAIN` | 111 |

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
| DKA_REPCOUTS_IMP / DKA | `DKA_REP_COUTS_PKG.MAIN` | dka/12.0.0/admin/import/DKA_REPCOUTS_IMP.prt:594 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
