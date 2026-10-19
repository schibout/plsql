# DKA_IEOMTL_CODARTINT_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_IEOMTL_CODARTINT_PKG.pks](../../dka/12.0.0/admin/sql/DKA_IEOMTL_CODARTINT_PKG.pks).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 201 ; encodage : cp1252 (repli). SHA-256 : `14f911e575fb2a950972a4fdd63b7f4bbceeab1b05a4b818eb12c8023d887980`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `chgt_file_cod_artint` | 34 |
| `controle_nbr_enreg_file` | 41 |
| `CONTROL_FORMAT_CODES` | 50 |
| `CONTROLE_UNICITE` | 61 |
| `CONTROLE_DONNEES` | 70 |
| `init` | 73 |
| `delete_complete_records` | 83 |
| `get_inventory_item_id` | 94 |
| `get_category_id` | 115 |
| `get_item_category` | 126 |
| `get_item_category_sec` | 132 |
| `insert_assign_category_item` | 139 |
| `launch_item_category` | 144 |
| `alimentation_jeux_valeurs` | 157 |
| `insert_items_interface` | 166 |
| `Launch_Items_OI` | 172 |
| `check_items_oi` | 178 |
| `check_category_items_oi` | 184 |
| `main` | 188 |
| `bilan` | 191 |
| `check_code_isNumeric` | 194 |

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
| DKA_IEOMTL_CODARTINT / DKA | `DKA_IEOMTL_CODARTINT_PKG.main` | dka/12.0.0/admin/import/DKA_IEOMTL_CODARTINT_PRG.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
