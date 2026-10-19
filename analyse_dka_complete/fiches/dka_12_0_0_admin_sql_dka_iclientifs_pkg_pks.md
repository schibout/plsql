# DKA_ICLIENTIFS_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_ICLIENTIFS_PKG.pks](../../dka/12.0.0/admin/sql/DKA_ICLIENTIFS_PKG.pks).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 158 ; encodage : cp1252 (repli). SHA-256 : `79e0b46eda8890d9a46e0763598e6dc81d15412c0a27734c8d95f137e30404b3`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 38 |
| `pre_OI` | 49 |
| `IN_OI` | 57 |
| `post_OI` | 68 |
| `address_exists` | 81 |
| `get_collector_from_cust_cdg` | 116 |
| `customer_exists` | 130 |
| `show_rejected_records` | 137 |
| `delete_duplicate_data` | 144 |
| `pre_import_client` | 151 |

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
| DKA_ICLIENTIFS_1 / DKA | `dka_iclientifs_pkg.pre_oi` | dka/12.0.0/admin/import/DKA_ICLIENTIFS_1.prt:404 |
| DKA_ICLIENTIFS_2 / DKA | `dka_iclientifs_pkg.post_oi` | dka/12.0.0/admin/import/DKA_ICLIENTIFS_2.prt:404 |
| DKA_ICLIENTIFS_3 / DKA | `dka_iclientifs_pkg.IN_OI` | dka/12.0.0/admin/import/DKA_ICLIENTIFS_3.prt:419 |
| DKA_ICLIENTIFS_4 / DKA | `DKA_ICLIENTIFS_PKG.pre_import_client` | dka/12.0.0/admin/import/DKA_ICLIENTIFS_4.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
