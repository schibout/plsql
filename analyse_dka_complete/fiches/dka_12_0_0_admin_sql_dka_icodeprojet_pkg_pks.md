# DKA_ICODEPROJET_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_ICODEPROJET_PKG.pks](../../dka/12.0.0/admin/sql/DKA_ICODEPROJET_PKG.pks).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 186 ; encodage : cp1252 (repli). SHA-256 : `363b142e2709df5044c68a9a5905aa01cefc29ccf671b766699d5b930abebc98`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `centre_finance` | 34 |
| `projets` | 54 |
| `update_project_closed` | 74 |
| `update_project_enclosed` | 92 |
| `update_month_org_project` | 110 |
| `update_month_org_task` | 130 |
| `update_project_month_status` | 149 |
| `update_month_project` | 165 |
| `main2` | 181 |

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
| DKA_ICENTREFIN / DKA | `DKA_ICODEPROJET_PKG.centre_finance` | dka/12.0.0/admin/import/DKA_ICENTREFIN.prt:460 |
| DKA_ICODEPROJET_2 / DKA | `dka_icodeprojet_pkg.main2` | dka/12.0.0/admin/import/DKA_ICODEPROJET_2.prt:404 |
| DKA_IPROJECT / DKA | `DKA_ICODEPROJET_PKG.projets` | dka/12.0.0/admin/import/DKA_IPROJECT.prt:422 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
