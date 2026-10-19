# DKA_IPOHYPERION_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_IPOHYPERION_PKG.pks](../../dka/12.0.0/admin/sql/DKA_IPOHYPERION_PKG.pks).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 59 ; encodage : cp1252 (repli). SHA-256 : `5ccf638cbe391398cb74ce0b0b57f6f96f857b3f651215f65b9a28b89ac7bb67`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 39 |
| `main_detail_sstr` | 53 |

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
| DKA_IPOHYPERION / DKA | `DKA_IPOHYPERION_PKG.main` | dka/12.0.0/admin/import/DKA_IPOHYPERION.prt:418 |
| DKA_IPOHYPERION_DETAIL_SSTR / DKA | `DKA_IPOHYPERION_PKG.main_detail_sstr` | dka/12.0.0/admin/import/DKA_IPOHYPERION_DETAIL_SSTR.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
