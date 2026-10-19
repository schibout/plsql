# DKA_SAPCREATE_BLOCAGES_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SAPCREATE_BLOCAGES_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SAPCREATE_BLOCAGES_PKG.pks).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 70 ; encodage : cp1252 (repli). SHA-256 : `5f20ecb3710d37f30aaf452c8079fce40f305b8467655f4c0105c3f69b065e8a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Main` | 30 |
| `Blocage_date_facture` | 42 |
| `Blocage_fres_affact` | 55 |
| `cree_blocage` | 60 |

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
| DKA_SAPCREATE_BLOCAGES / DKA | `DKA_SAPCREATE_BLOCAGES_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SAPCREATE_BLOCAGES.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
