# DKA_IPOEXTSOLDHERC_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_IPOEXTSOLDHERC_PKG.pks](../../dka/12.0.0/admin/sql/DKA_IPOEXTSOLDHERC_PKG.pks).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 105 ; encodage : cp1252 (repli). SHA-256 : `eeee71d936f4a7f0b82e14bd598200ffec90724df4b47b254cdf422814488be2`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `p_put_debug_message` | 35 |
| `p_validate` | 39 |
| `p_check_directory` | 46 |
| `p_extract_data` | 52 |
| `p_extract_data_type_p3` | 57 |
| `p_extract_data_type_p6` | 66 |
| `output_header` | 77 |
| `PURGE_TABLE` | 83 |
| `main` | 89 |
| `bilan` | 95 |
| `compression_fichier_sortie` | 98 |

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
| DKA_EXTRSOLD_HERC / DKA | `DKA_IPOEXTSOLDHERC_PKG.main` | dka/12.0.0/admin/import/DKA_EXTRSOLD_HERC_PRG.ldt:434 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
