# DKA_SCTRLMODULE_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SCTRLMODULE_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SCTRLMODULE_PKG.pks).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 60 ; encodage : cp1252 (repli). SHA-256 : `86d19b58fdfaf7a7f68012c6504d35a71e2070871d9da34131be038bfbac0caf`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `envoi_mail` | 34 |
| `main` | 49 |

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
| DKA_SCTRLMODULE_EDT / DKA | `DKA_SCTRLMODULE_PKG.main` | dka/12.0.0/admin/import/DKA_SCTRLMODULE_EDT.prt:492 |
| DKA_SCTRLMODULE_MAIL / DKA | `DKA_SCTRLMODULE_PKG.envoi_mail` | dka/12.0.0/admin/import/DKA_SCTRLMODULE_MAIL.prt:459 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
