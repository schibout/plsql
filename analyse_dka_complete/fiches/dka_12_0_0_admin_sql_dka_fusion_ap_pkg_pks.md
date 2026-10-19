# DKA_FUSION_AP_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pks](../../dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pks).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 172 ; encodage : cp1252 (repli). SHA-256 : `0f38816ec08001ff682e38b44d1d5e03ed8bc24109554858ead55d4fb4bc73a1`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main_Extract` | 28 |
| `main_Ctr` | 43 |
| `main_Insert` | 58 |
| `main_Post_Fusion` | 73 |
| `main_Hold_No_Cent` | 89 |
| `main_Rattchmt_Images` | 103 |
| `main_Annul_workflow` | 119 |
| `main_Let_Rec` | 134 |
| `main_Let_Maj` | 149 |
| `main_Let_Mvt` | 164 |

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
| DKA_FUSAP_ANNUL_WF / DKA | `DKA_FUSION_AP_PKG.main_Annul_workflow` | dka/12.0.0/admin/import/DKA_FUSAP_ANNUL_WF.ldt:472 |
| DKA_FUSAP_BLOCAGE / DKA | `DKA_FUSION_AP_PKG.main_Hold_No_Cent` | dka/12.0.0/admin/import/DKA_FUSAP_BLOCAGE.ldt:477 |
| DKA_FUSAP_CONTROL / DKA | `DKA_FUSION_AP_PKG.Main_Ctr` | dka/12.0.0/admin/import/DKA_FUSAP_CONTROL.ldt:477 |
| DKA_FUSAP_EXTRACT / DKA | `DKA_FUSION_AP_PKG.Main_Extract` | dka/12.0.0/admin/import/DKA_FUSAP_EXTRACT.ldt:477 |
| DKA_FUSAP_IMAGES / DKA | `DKA_FUSION_AP_PKG.main_Rattchmt_Images` | dka/12.0.0/admin/import/DKA_FUSAP_IMAGES.ldt:494 |
| DKA_FUSAP_INSERT / DKA | `DKA_FUSION_AP_PKG.Main_Insert` | dka/12.0.0/admin/import/DKA_FUSAP_INSERT.ldt:477 |
| DKA_FUSAP_MAJ_LETTRAGE / DKA | `DKA_FUSION_AP_PKG.main_Let_Maj` | dka/12.0.0/admin/import/DKA_FUSAP_MAJ_LETTRAGE.ldt:477 |
| DKA_FUSAP_MVT_LETTRAGE / DKA | `DKA_FUSION_AP_PKG.main_Let_Mvt` | dka/12.0.0/admin/import/DKA_FUSAP_MVT_LETTRAGE.ldt:477 |
| DKA_FUSAP_POST / DKA | `DKA_FUSION_AP_PKG.Main_Post_Fusion` | dka/12.0.0/admin/import/DKA_FUSAP_POST.ldt:477 |
| DKA_FUSAP_REC_LETTRAGE / DKA | `DKA_FUSION_AP_PKG.main_Let_Rec` | dka/12.0.0/admin/import/DKA_FUSAP_REC_LETTRAGE.ldt:477 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
