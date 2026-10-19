# DKA_IAPLOADIMG_XEROX_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_IAPLOADIMG_XEROX_PKG.pks](../../dka/12.0.0/admin/sql/DKA_IAPLOADIMG_XEROX_PKG.pks).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 164 ; encodage : cp1252 (repli). SHA-256 : `6ad2f60ebc5085034fb51921ac4017ffb8ecd28dac6b8322f6a070d371c0a5de`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 43 |
| `chargement_image` | 57 |
| `create_attached_doc` | 74 |
| `delete_attached_doc` | 96 |
| `stockage_image_facture_AP` | 112 |
| `Stockage_image_facture_OI` | 127 |
| `Purge_document_joint_oi` | 142 |
| `main` | 157 |

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
| DKA_IAPLOADIMG_XEROX / DKA | `DKA_IAPLOADIMG_XEROX_PKG.MAIN` | dka/12.0.0/admin/import/DKA_IAPLOADIMG_XEROX.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
