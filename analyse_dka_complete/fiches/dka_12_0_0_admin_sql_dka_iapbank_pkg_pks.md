# DKA_IAPBANK_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_IAPBANK_PKG.pks](../../dka/12.0.0/admin/sql/DKA_IAPBANK_PKG.pks).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 186 ; encodage : cp1252 (repli). SHA-256 : `edd4265bd2cedc8a097b27981333f1e372d5487a08ca1be67ca63e70b46c68b7`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `historize_file_tmp_gui` | 36 |
| `historize_file_tmp_etab` | 48 |
| `dka_chgt_file_situa_gui` | 61 |
| `dka_chgt_file_situa_etab` | 74 |
| `controle_nbr_enreg_file` | 113 |
| `controle_coherence_file` | 125 |
| `verif_end_guichet` | 138 |
| `simulation_insert_file` | 165 |
| `main` | 177 |

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
| DKA_IAPBANK_CTRL / DKA | `DKA_IAPBANK_PKG.main` | dka/12.0.0/admin/import/DKA_IAPBANK_CTRL.prt:460 |
| DKA_IAPBANK_CTRL / DKA | `DKA_IAPBANK_PKG.main` | dka/12.0.0/admin/import/DKA_IAPBANK_CTRL.prt:460 |
| DKA_IAPBANK_MAJ / DKA | `DKA_IAPBANK_PKG.main` | dka/12.0.0/admin/import/DKA_IAPBANK_MAJ.prt:460 |
| DKA_IAPBANK_MAJ / DKA | `DKA_IAPBANK_PKG.main` | dka/12.0.0/admin/import/DKA_IAPBANK_MAJ.prt:460 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
