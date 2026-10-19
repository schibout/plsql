# DKA_IAPCTRFLUX_XEROX_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_IAPCTRFLUX_XEROX_PKG.pks](../../dka/12.0.0/admin/sql/DKA_IAPCTRFLUX_XEROX_PKG.pks).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 38 ; encodage : utf-8. SHA-256 : `43f974c004e933212a0b10e7116b30b16ca2290fdf18211989b49fdb51832996`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 27 |
| `insert_dka_iapctrflux_xerox` | 31 |

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
| DKA_IAPCTRFLUX_XEROX / DKA | `DKA_IAPCTRFLUX_XEROX_PKG.main` | dka/12.0.0/admin/import/DKA_IAPCTRFLUX_XEROX.prt:419 |
| DKA_INSERT_CDF_XEROX / DKA | `DKA_IAPCTRFLUX_XEROX_PKG.insert_dka_iapctrflux_xerox` | dka/12.0.0/admin/import/DKA_INSERT_CDF_XEROX.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
