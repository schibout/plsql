# DKA_SPOASS_FOURN_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SPOASS_FOURN_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SPOASS_FOURN_PKG.pks).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 107 ; encodage : cp1252 (repli). SHA-256 : `b918a8fd11caff96cb1a1ede1fb6bc6f9f7f49f869780ac068c316a86208849b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main_1` | 44 |
| `main_2` | 63 |
| `main_3` | 83 |
| `main_4` | 96 |

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
| DKA_SPOFOUR_DESAC / DKA | `DKA_SPOASS_FOURN_PKG.main_3` | dka/12.0.0/admin/import/DKA_SPOFOUR_DESAC.prt:419 |
| DKA_SPOFOUR_NONMV / DKA | `DKA_SPOASS_FOURN_PKG.main_1` | dka/12.0.0/admin/import/DKA_SPOFOUR_NONMV.prt:518 |
| DKA_SPOFOUR_OBS / DKA | `DKA_SPOASS_FOURN_PKG.main_2` | dka/12.0.0/admin/import/DKA_SPOFOUR_OBS.prt:523 |
| DKA_SPOSTFNS_DESACT / DKA | `DKA_SPOASS_FOURN_PKG.main_4` | dka/12.0.0/admin/import/DKA_SPOSTFNS_DESACT.prt:655 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
