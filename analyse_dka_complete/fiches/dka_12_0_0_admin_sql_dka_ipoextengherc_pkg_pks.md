# DKA_IPOEXTENGHERC_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_IPOEXTENGHERC_PKG.pks](../../dka/12.0.0/admin/sql/DKA_IPOEXTENGHERC_PKG.pks).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 132 ; encodage : cp1252 (repli). SHA-256 : `e7133491583c24e3d02307911a2703a2f36d6e15295e31877380547b892a1e6e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `p_put_debug_message` | 36 |
| `p_validate` | 40 |
| `p_check_directory` | 47 |
| `p_extract_data_cmd` | 53 |
| `p_extract_data_inv` | 64 |
| `p_extract_data_maind` | 75 |
| `p_extract_data_refac` | 93 |
| `output_header` | 105 |
| `main` | 111 |
| `bilan` | 118 |
| `compression_fichier_sortie` | 125 |

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
| DKA_IPAEXT_ENG_HER / DKA | `DKA_IPOEXTENGHERC_PKG.main` | dka/12.0.0/admin/import/DKA_IPAEXT_ENG_HER_PRG.ldt:534 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
