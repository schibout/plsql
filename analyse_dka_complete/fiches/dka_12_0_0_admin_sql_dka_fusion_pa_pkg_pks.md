# DKA_FUSION_PA_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pks](../../dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pks).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 376 ; encodage : cp1252 (repli). SHA-256 : `ca9270ef79d09741390e9509bd75b7f8508ae029e9d06d8f262a47adf56995be`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `SAUV_TABLE_SAUVEGARDE_ET01` | 34 |
| `SAUV_TABLE_INTERF_ET01` | 42 |
| `BILAN_ET01` | 51 |
| `MAIN_SAUV_PURGE` | 64 |
| `FUSION_PA_SUFFIX_Z_TRANS` | 87 |
| `main_suffix_projet` | 102 |
| `RATTACHEMENT_PROJET_FINANCE` | 117 |
| `MAIN_REC_HIST` | 132 |
| `SAUV_TABLE_SAUVEGARDE_ET07` | 152 |
| `SAUV_TABLE_INTERF_ET07` | 159 |
| `BILAN_ET07` | 166 |
| `main_rest_TAB_INT` | 177 |
| `FERMETURE_PROJET_TACHE` | 196 |
| `BILAN_ET08` | 210 |
| `main_ferm_projet` | 221 |
| `CORRECTION_ORG_PROJET` | 244 |
| `MAIN_CORREC_PROJET` | 260 |
| `REPRISE_INDICATEUR` | 280 |
| `MAIN_REPRISE_INDIC` | 296 |
| `MAJ_PR_TEC_PCA` | 316 |
| `MAIN_MAJ_PR_TEC_PCA` | 331 |
| `MAJ_PR_CCA` | 351 |
| `MAIN_MAJ_PR_CCA` | 366 |

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
| DKA_FUSPA_CORR_ORGPROJ / DKA | `DKA_FUSION_PA_PKG.MAIN_CORREC_PROJET` | dka/12.0.0/admin/import/DKA_FUSPA_CORR_ORGPROJ_PRG.ldt:559 |
| DKA_FUSPA_FERMPRTC / DKA | `DKA_FUSION_PA_PKG.main_ferm_projet` | dka/12.0.0/admin/import/DKA_FUSPA_FERMPRTC_PRG.ldt:595 |
| DKA_FUSPA_MAJ_CCA / DKA | `DKA_FUSION_PA_PKG.MAIN_MAJ_PR_CCA` | dka/12.0.0/admin/import/DKA_FUSPA_MAJ_CCA_PRG.ldt:551 |
| DKA_FUSPA_MAJ_TEC_PCA / DKA | `DKA_FUSION_PA_PKG.MAIN_MAJ_PR_TEC_PCA` | dka/12.0.0/admin/import/DKA_FUSPA_MAJ_TEC_PCA_PRG.ldt:551 |
| DKA_FUSPA_REC_ATTPR / DKA | `DKA_FUSION_PA_PKG.MAIN_REC_HIST` | dka/12.0.0/admin/import/DKA_FUSPA_REC_ATTPR_PRG.ldt:551 |
| DKA_FUSPA_REP_INDEC / DKA | `DKA_FUSION_PA_PKG.MAIN_REPRISE_INDIC` | dka/12.0.0/admin/import/DKA_FUSPA_REP_INDEC_PRG.ldt:551 |
| DKA_FUSPA_SAUVPURGTINT / DKA | `DKA_FUSION_PA_PKG.MAIN_SAUV_PURGE` | dka/12.0.0/admin/import/DKA_FUSPA_SAUVPURGTINT_PRG.ldt:417 |
| DKA_FUSPA_SUFIXAGEPRTX / DKA | `DKA_FUSION_PA_PKG.main_suffix_projet` | dka/12.0.0/admin/import/DKA_FUSPA_SUFIXAGEPRTX_PRG.ldt:559 |
| DKA_FUSPA_SUFIXRESTABINTEFR / DKA | `DKA_FUSION_PA_PKG.main_rest_TAB_INT` | dka/12.0.0/admin/import/DKA_FUSPA_SUFIXRESTABINTEFR_PRG.ldt:542 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
