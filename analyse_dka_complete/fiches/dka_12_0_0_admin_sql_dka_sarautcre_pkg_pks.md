# DKA_SARAUTCRE_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SARAUTCRE_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SARAUTCRE_PKG.pks).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 51 ; encodage : cp1252 (repli). SHA-256 : `cbdd186156b87fec66473efd297672ce787dc9b288fae3185a2a939b301b2f11`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main_evenement` | 31 |
| `main_reglement` | 35 |
| `main_sequence` | 39 |
| `main_comptes` | 43 |

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
| rollback | 2 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARAUTCRE_COMPTE / DKA | `DKA_SARAUTCRE_PKG.MAIN_COMPTES` | dka/12.0.0/admin/import/DKA_SARAUTCRE_COMPTE.ldt:476 |
| DKA_SARAUTCRE_EVENEMENT / DKA | `DKA_SARAUTCRE_PKG.MAIN_EVENEMENT` | dka/12.0.0/admin/import/DKA_SARAUTCRE_EVENEMENT.ldt:476 |
| DKA_SARAUTCRE_REGLEMENT / DKA | `DKA_SARAUTCRE_PKG.MAIN_REGLEMENT` | dka/12.0.0/admin/import/DKA_SARAUTCRE_REGLEMENT.ldt:476 |
| DKA_SARAUTCRE_SEQUENCE / DKA | `DKA_SARAUTCRE_PKG.MAIN_SEQUENCE` | dka/12.0.0/admin/import/DKA_SARAUTCRE_SEQUENCE.ldt:476 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
