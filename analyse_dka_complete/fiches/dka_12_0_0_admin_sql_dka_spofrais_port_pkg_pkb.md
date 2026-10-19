# DKA_SPOFRAIS_PORT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOFRAIS_PORT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOFRAIS_PORT_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1033 ; encodage : cp1252 (repli). SHA-256 : `a41a293dc2466b4d5dde3108cb6892141e8d7608777adeb9732ab16b1de214a1`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Calculer_montant` | 43 |
| `Inserer_ligne` | 103 |
| `Annuler_ligne` | 681 |
| `Supprimer_ligne` | 919 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_lines_all` | 59 |
| `PO_LINES_ALL` | 131 |
| `PO_LINES_ALL` | 136 |
| `PO_LINE_LOCATIONS_ALL` | 145 |
| `PO_LINE_LOCATIONS_ALL` | 148 |
| `PO_DISTRIBUTIONS_ALL` | 158 |
| `PO_DISTRIBUTIONS_ALL` | 161 |
| `PO_LINES_ALL` | 188 |
| `DKA_SPOPARAM_FRAIS_PORT` | 200 |
| `PO_DISTRIBUTIONS_ALL` | 697 |
| `PO_LINE_LOCATIONS_ALL` | 708 |
| `PO_LINE_LOCATIONS_ALL` | 717 |
| `PO_DISTRIBUTIONS_ALL` | 726 |
| `PO_LINES_ALL` | 736 |
| `PO_LINE_LOCATIONS_ALL` | 745 |
| `PO_DISTRIBUTIONS_ALL` | 757 |
| `PO_LINE_LOCATIONS_ALL` | 765 |
| `PO_LINE_LOCATIONS_ALL` | 773 |
| `PO_LINES_ALL` | 787 |
| `PO_LINE_LOCATIONS_ALL` | 802 |
| `PO_DISTRIBUTIONS_ALL` | 841 |
| `PO_LINE_LOCATIONS_ALL` | 867 |
| `PO_LINES_ALL` | 880 |
| `PO_LINE_LOCATIONS_ALL` | 942 |
| `PO_REQUISITION_LINES_ALL` | 957 |
| `PO_LINE_LOCATIONS_ALL` | 959 |
| `PO_REQUISITION_LINES_ALL` | 990 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_debug_message` | 53 |
| `Dka_Tools_Pkg.put_outdebug_message` | 72 |
| `Dka_Tools_Pkg.put_outdebug_message` | 80 |
| `Dka_Tools_Pkg.get_parameter` | 219 |
| `Dka_Tools_Pkg.get_parameter` | 230 |
| `Dka_Tools_Pkg.get_parameter` | 241 |
| `Dka_Tools_Pkg.get_parameter` | 252 |
| `PO_LINES_SV3.insert_line` | 269 |
| `PO_LINES_SV2.get_max_line_num` | 275 |
| `PO_LINE_LOCATIONS_PKG_S0.Insert_Row` | 422 |
| `PO_DISTRIBUTIONS_PKG1.INSERT_ROW` | 557 |
| `Dka_Tools_Pkg.put_debug_message` | 691 |
| `po_reqs_control_sv.update_reqs_status` | 967 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 77, 670, 895, 983, 1021 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
