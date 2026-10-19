# DKA_IAPCTRFLUX_IVALUA_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_IAPCTRFLUX_IVALUA_PKG.pks](../../dka/12.0.0/admin/sql/DKA_IAPCTRFLUX_IVALUA_PKG.pks).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 33 ; encodage : utf-8. SHA-256 : `c71f0d63cca7df117c0b7aba231364eb0819772e5b2995a939dca3430d1eed8b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 24 |
| `insert_dka_iapctrflux_ivalua` | 27 |

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
| DKA_IAPCTRFLUX_IVALUA / DKA | `DKA_IAPCTRFLUX_IVALUA_PKG.main` | dka/12.0.0/admin/import/DKA_IAPCTRFLUX_IVALUA_F_PRG.ldt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
