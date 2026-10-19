# DKA_SARAUTOPRELEV_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SARAUTOPRELEV_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SARAUTOPRELEV_PKG.pks).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 105 ; encodage : cp1252 (repli). SHA-256 : `e13aa361466ce117b7de14803ca17f7aefca2804898d4e9629f5d82059acecde`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `INSERT_PRELEV` | 58 |
| `INSERT_PRELEV_EXP` | 64 |
| `CREATE_DDIMPORT` | 82 |
| `MAIN` | 98 |

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
| DKA_CREATE_DDIMPORT_FILE / DKA | `DKA_SARAUTOPRELEV_PKG.CREATE_DDIMPORT` | dka/12.0.0/admin/import/DKA_CREATE_DDIMPORT_FILE_F.prt:458 |
| DKA_CREATE_DDIMPORT_FILE / DKA | `DKA_SARAUTOPRELEV_PKG.CREATE_DDIMPORT` | dka/12.0.0/admin/import/DKA_CREATE_DDIMPORT_FILE_F.prt:458 |
| DKA_CREATE_DDIMPORT_FILE / DKA | `DKA_SARAUTOPRELEV_PKG.CREATE_DDIMPORT` | dka/12.0.0/admin/import/DKA_CREATE_DDIMPORT_FILE_US.prt:458 |
| DKA_CREATE_DDIMPORT_FILE / DKA | `DKA_SARAUTOPRELEV_PKG.CREATE_DDIMPORT` | dka/12.0.0/admin/import/DKA_CREATE_DDIMPORT_FILE_US.prt:458 |
| DKA_SARAUTOPRELEV / DKA | `DKA_SARAUTOPRELEV_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SARAUTOPRELEV_F.prt:460 |
| DKA_SARAUTOPRELEV / DKA | `DKA_SARAUTOPRELEV_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SARAUTOPRELEV_F.prt:460 |
| DKA_SARAUTOPRELEV / DKA | `DKA_SARAUTOPRELEV_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SARAUTOPRELEV_US.prt:460 |
| DKA_SARAUTOPRELEV / DKA | `DKA_SARAUTOPRELEV_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SARAUTOPRELEV_US.prt:460 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
