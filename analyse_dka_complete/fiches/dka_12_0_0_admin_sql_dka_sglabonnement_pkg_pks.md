# DKA_SGLABONNEMENT_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SGLABONNEMENT_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SGLABONNEMENT_PKG.pks).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 128 ; encodage : cp1252 (repli). SHA-256 : `c8e5b80bf830f4747c005823c66a691aac9446b6a8c8dca973a691cb19960e73`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `check_company_and_cost_center` | 53 |
| `check_account` | 59 |
| `get_rec_header_tot_amount` | 64 |
| `get_rec_line_description` | 71 |
| `is_rule_num_in_table` | 76 |
| `Compte_Rendu` | 101 |
| `Main` | 122 |

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
| DKA_SGLABONNEMENT / DKA | `DKA_SGLABONNEMENT_PKG.main` | dka/12.0.0/admin/import/DKA_SGLABONNEMENT.prt:419 |
| DKA_SGLABONNEMENT_CR / DKA | `DKA_SGLABONNEMENT_PKG.compte_rendu` | dka/12.0.0/admin/import/DKA_SGLABONNEMENT_CR.prt:488 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
