# DKA_SARSURTAXE_MAIL_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SARSURTAXE_MAIL_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SARSURTAXE_MAIL_PKG.pks).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 127 ; encodage : cp1252 (repli). SHA-256 : `3266fdde37319cef993b4dc40471cd9bdd53cca6a943ff69425ba3b7f4cf6944`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 42 |
| `write_boundary` | 55 |
| `begin_attachment` | 68 |
| `end_attachment` | 84 |
| `envoi_mail` | 102 |
| `main` | 118 |

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
| DKA_SARSURTAXE_MAIL / DKA | `DKA_SARSURTAXE_MAIL_PKG.main` | dka/12.0.0/admin/import/DKA_SARSURTAXE_MAIL.prt:406 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
