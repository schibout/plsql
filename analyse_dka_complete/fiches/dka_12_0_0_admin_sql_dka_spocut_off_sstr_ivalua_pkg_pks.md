# DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.pks).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 72 ; encodage : cp1252 (repli). SHA-256 : `4e34208423cc6377710d40e801487c59956b28ad970aa3fbfb9ca0307bedce38`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_charge_theorique_imput` | 34 |
| `main` | 63 |

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
| DKA_SPOCUT_OFF_SSTR_IVALUA / DKA | `DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.Main` | dka/12.0.0/admin/import/DKA_SPOCUT_OFF_SSTR_IVALUA.prt:545 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
