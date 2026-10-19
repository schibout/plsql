# DKA_SFABUDGET.pks

Source : [dka/12.0.0/admin/sql/DKA_SFABUDGET.pks](../../dka/12.0.0/admin/sql/DKA_SFABUDGET.pks).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 511 ; encodage : cp1252 (repli). SHA-256 : `437906facd198df030963766668d1242058370c3ad0d84a47872959ec8cce95f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `DKA_DEL_SFABUDGET_WORK` | 32 |
| `DKA_BOOK_PERIODS_CTR` | 51 |
| `DKA_BOOK_MAIN_CTR` | 70 |
| `DKA_MAIN_CTR` | 87 |
| `DKA_WAIT_FAGDA` | 103 |
| `DKA_SUBMIT_FAGDA` | 121 |
| `DKA_CTR_ALL_CCID` | 140 |
| `DKA_MAIN_FAGDA` | 159 |
| `DKA_WAIT_FAPROJ` | 175 |
| `DKA_SUBMIT_FAPROJ` | 195 |
| `DKA_FIRST_PERIODE` | 217 |
| `DKA_FIRST_PERIODE_NEW` | 237 |
| `DKA_MAIN_FAPROJ` | 256 |
| `DKA_INS_TRAITEMENT` | 276 |
| `DKA_GET_APPARTENANCE` | 297 |
| `DKA_GET_CENTRE` | 315 |
| `DKA_UPDATE_DATA` | 333 |
| `DKA_MAIN_COPY_DATA` | 352 |
| `DKA_MAIN_GEN_DATA` | 370 |
| `DKA_REQUEST_DROP_TABLE` | 390 |
| `DKA_MAIN_DROP_TABLE` | 408 |
| `p_validate` | 423 |
| `p_extr_data_justif` | 435 |
| `EDIT_REG_JUSTIF` | 440 |
| `EDIT_REG_HYP` | 447 |
| `p_extr_data_justif_REG` | 454 |
| `p_extr_data_hyperion` | 460 |
| `p_extr_data_hyperion_REG` | 465 |
| `SEND_MSG` | 481 |
| `main` | 499 |

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

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
