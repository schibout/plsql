# DKA_REP_TRANSCO_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REP_TRANSCO_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REP_TRANSCO_PKG.pkb).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1531 ; encodage : cp1252 (repli). SHA-256 : `f4615036547bb3977a165fa2b7da0551d1857a0c6c1d868b85dab5c4156b2f7d`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_transco` | 59 |
| `get_transco` | 173 |
| `get_transco` | 258 |
| `get_transco` | 343 |
| `get_transco` | 417 |
| `get_transco` | 504 |
| `get_transco` | 592 |
| `get_transco` | 681 |
| `get_transco` | 771 |
| `get_transco` | 862 |
| `get_transco` | 954 |
| `get_transco` | 1047 |
| `get_transco_f` | 1136 |
| `get_cle_transco_f` | 1238 |
| `get_complement_compte` | 1340 |
| `get_cle_transco` | 1437 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_REP_TRANSCO_LINES` | 114 |
| `hr_all_organization_units` | 1354 |
| `FND_FLEX_VALUES_VL` | 1383 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.get_code_combination_id` | 1295 |
| `dka_tools_pkg.numeric_check` | 1369 |
| `DKA_REP_TRANSCO_PKG.get_transco_f` | 1474 |
| `DKA_REP_TRANSCO_PKG.get_transco_f` | 1478 |
| `DKA_REP_TRANSCO_PKG.get_transco_f` | 1485 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 1489 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 148, 232, 316, 401, 475, 562, 650, 739, 829, 920, 1012, 1105, 1213, 1323, 1400, 1511 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
