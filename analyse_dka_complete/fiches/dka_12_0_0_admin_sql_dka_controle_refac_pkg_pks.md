# DKA_CONTROLE_REFAC_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_CONTROLE_REFAC_PKG.pks](../../dka/12.0.0/admin/sql/DKA_CONTROLE_REFAC_PKG.pks).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 61 ; encodage : cp1252 (repli). SHA-256 : `8ac38aaa1dd45a8c14381144c2959d0c7660757a72ced8044ec8c24b02ca4563`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Step_1` | 26 |
| `Step_2` | 29 |
| `Step_3` | 33 |
| `Step_4` | 37 |
| `Step_5` | 41 |
| `Step_6` | 44 |
| `Step_7` | 47 |
| `Step_8` | 50 |
| `Main` | 53 |

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
| DKA_CONTROLE_REFAC / DKA | `dka_controle_refac_pkg.main` | dka/12.0.0/admin/import/DKA_CONTROLE_REFAC.prt:545 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
