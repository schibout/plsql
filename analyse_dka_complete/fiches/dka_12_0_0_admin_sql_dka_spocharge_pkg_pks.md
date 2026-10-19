# DKA_SPOCHARGE_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SPOCHARGE_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SPOCHARGE_PKG.pks).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 266 ; encodage : cp1252 (repli). SHA-256 : `4f940561fd0f923b737b480d2243a8b13ed51fd520c224a045f2dbcaa525ed6a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Create_PerEndAccruals` | 140 |
| `update_gl` | 174 |
| `run_prog_standard` | 193 |
| `run_prog_comptabilisation` | 209 |
| `main` | 259 |

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
| DKA_SPOCHARGE / DKA | `DKA_SPOCHARGE_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCHARGE_F.prt:477 |
| DKA_SPOCHARGE / DKA | `DKA_SPOCHARGE_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCHARGE_F.prt:477 |
| DKA_SPOCHARGE / DKA | `DKA_SPOCHARGE_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCHARGE_US.prt:477 |
| DKA_SPOCHARGE / DKA | `DKA_SPOCHARGE_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCHARGE_US.prt:477 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
