# DKA_SPACLOTURE_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SPACLOTURE_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SPACLOTURE_PKG.pks).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 231 ; encodage : cp1252 (repli). SHA-256 : `4cd2568023256f9ed63ad3f6e75ccd58e6ad0a1389b98b3dfef08644d6b1b55a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `cherche_period` | 44 |
| `cherche_next_period` | 64 |
| `pa_check_transfer_to_ap` | 86 |
| `pa_check_cost_transfer_to_ap` | 111 |
| `pa_check_cross_charge` | 135 |
| `pa_check_draft_revenue` | 158 |
| `pa_check_cst_pm` | 180 |
| `pa_check_trans_uncosted` | 203 |
| `main` | 224 |

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
| DKA_SPACLOTURE / DKA | `dka_spacloture_pkg.main` | dka/12.0.0/admin/import/DKA_SPACLOTURE.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
