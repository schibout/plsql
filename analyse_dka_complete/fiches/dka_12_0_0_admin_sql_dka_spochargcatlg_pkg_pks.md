# DKA_SPOCHARGCATLG_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SPOCHARGCATLG_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SPOCHARGCATLG_PKG.pks).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 66 ; encodage : utf-8. SHA-256 : `93bb79f49c4d26729b240fe7628f75b56d759eaa89c648986dab79dac2863182`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `duplicate_orders` | 36 |
| `duplicate_sites` | 58 |

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
| DKA_SPODUPLCOG / DKA | `DKA_SPOCHARGCATLG_PKG.duplicate_orders` | dka/12.0.0/admin/import/DKA_SPODUPLCOG.prt:605 |
| DKA_SPODUPSITECOG / DKA | `DKA_SPOCHARGCATLG_PKG.duplicate_sites` | dka/12.0.0/admin/import/DKA_SPODUPSITECOG.prt:421 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
