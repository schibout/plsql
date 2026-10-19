# DKA_IAPFACTTDS_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_IAPFACTTDS_PKG.pks](../../dka/12.0.0/admin/sql/DKA_IAPFACTTDS_PKG.pks).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 146 ; encodage : cp1252 (repli). SHA-256 : `8096a57c0ef810d77fd8edddeae66d6c1abd99463a731a7bf2df2088416203ab`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `determination_statut_comm` | 43 |
| `update_factures` | 59 |
| `insert_factures` | 72 |
| `reinitialisation_statuts` | 86 |
| `archivage_factures` | 99 |
| `verif_factures_archivees` | 113 |
| `creation_fichier` | 126 |
| `main` | 141 |

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
| DKA_IAPFACTTDS / DKA | `DKA_IAPFACTTDS_PKG.main` | dka/12.0.0/admin/import/DKA_IAPFACTTDS_F.prt:419 |
| DKA_IAPFACTTDS / DKA | `DKA_IAPFACTTDS_PKG.main` | dka/12.0.0/admin/import/DKA_IAPFACTTDS_F.prt:419 |
| DKA_IAPFACTTDS / DKA | `DKA_IAPFACTTDS_PKG.main` | dka/12.0.0/admin/import/DKA_IAPFACTTDS_US.prt:419 |
| DKA_IAPFACTTDS / DKA | `DKA_IAPFACTTDS_PKG.main` | dka/12.0.0/admin/import/DKA_IAPFACTTDS_US.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
