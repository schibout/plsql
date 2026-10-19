# DKA_SPOCLOSCOM_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SPOCLOSCOM_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SPOCLOSCOM_PKG.pks).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 155 ; encodage : cp1252 (repli). SHA-256 : `cd6d86db929a8c0545e76aaad86633843ea73c496589c74a9fa4c8f3a82f7f07`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 29 |
| `Cloture_ligne_commande` | 43 |
| `Cloture_ligne_livraison` | 60 |
| `Cloture_entete_commande` | 78 |
| `Select_ligne_cde_proj_ferme` | 95 |
| `Select_ligne_cde_ancienne` | 112 |
| `lancement_par_region` | 131 |
| `main` | 147 |

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
| DKA_SPOCLOSCOM / DKA | `DKA_SPOCLOSCOM_PKG.lancement_par_region` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_F.prt:461 |
| DKA_SPOCLOSCOM / DKA | `DKA_SPOCLOSCOM_PKG.lancement_par_region` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_F.prt:461 |
| DKA_SPOCLOSCOM_PR / DKA | `DKA_SPOCLOSCOM_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_PR_F.prt:480 |
| DKA_SPOCLOSCOM_PR / DKA | `DKA_SPOCLOSCOM_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_PR_F.prt:480 |
| DKA_SPOCLOSCOM_PR / DKA | `DKA_SPOCLOSCOM_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_PR_US.prt:480 |
| DKA_SPOCLOSCOM_PR / DKA | `DKA_SPOCLOSCOM_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_PR_US.prt:480 |
| DKA_SPOCLOSCOM / DKA | `DKA_SPOCLOSCOM_PKG.lancement_par_region` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_US.prt:461 |
| DKA_SPOCLOSCOM / DKA | `DKA_SPOCLOSCOM_PKG.lancement_par_region` | dka/12.0.0/admin/import/DKA_SPOCLOSCOM_US.prt:461 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
