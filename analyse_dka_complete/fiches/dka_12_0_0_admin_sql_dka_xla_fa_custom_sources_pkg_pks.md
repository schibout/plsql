# DKA_XLA_FA_CUSTOM_SOURCES_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_XLA_FA_CUSTOM_SOURCES_PKG.pks](../../dka/12.0.0/admin/sql/DKA_XLA_FA_CUSTOM_SOURCES_PKG.pks).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 292 ; encodage : cp1252 (repli). SHA-256 : `0500670c39b53872c5e5ae76fff298701a1999d43dcc503ca52b3ed175021fd3`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `is_TAX_Book` | 30 |
| `is_IFRS_Category` | 49 |
| `get_IFRS_account` | 104 |
| `GET_FA_PROV_LOCAL` | 112 |
| `get_Project_Number` | 129 |
| `get_Task_Number` | 147 |
| `is_f44` | 169 |
| `is_f60` | 189 |
| `is_category_name` | 208 |
| `get_SOCIAL_account` | 228 |
| `GET_FA_PROV_GROUPE` | 235 |
| `GET_FA_PROV_ANNUL_LOCAL` | 240 |
| `GET_FA_PROV_ANNUL_GROUPE` | 245 |
| `DKA_FA_RETIRT_SUBIPR_DOT_LOC` | 250 |
| `DKA_FA_RETIRT_SUBIPR_DOT_GP` | 255 |
| `DKA_FA_RETIRT_SUBIPR_DOT_AN_LO` | 260 |
| `DKA_FA_RETIRT_SUBIPR_DOT_AN_GP` | 265 |
| `DKA_FA_NBV_RETIRED_LOSS_GP_SEG` | 270 |
| `DKA_FA_RECLASS_NIFRS_IFRS` | 276 |
| `get_RECLASS_IFRS_account` | 281 |

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
