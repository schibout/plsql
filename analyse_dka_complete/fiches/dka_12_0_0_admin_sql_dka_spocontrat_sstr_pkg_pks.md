# DKA_SPOCONTRAT_SSTR_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SPOCONTRAT_SSTR_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SPOCONTRAT_SSTR_PKG.pks).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 402 ; encodage : cp1252 (repli). SHA-256 : `a0986733d01a49a160106094f99b51d3ae139f744fedfb94464753bc4cf56afb`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_varchar2_parameter` | 46 |
| `get_number_parameter` | 62 |
| `check_vendor` | 77 |
| `check_vendor_site` | 91 |
| `check_lieu_livraison` | 105 |
| `check_lieu_facturation` | 119 |
| `check_nature_prestation` | 133 |
| `check_gestionnaire` | 147 |
| `check_projet` | 163 |
| `check_expenditure_type` | 181 |
| `get_affich_imput` | 196 |
| `get_first_revnum_ctr_annuel` | 211 |
| `get_last_revnum_ctr_annuel` | 225 |
| `get_invoices_count` | 241 |
| `check_montant_facture` | 260 |
| `check_montant_imput_facture` | 288 |
| `get_ccid` | 318 |
| `get_contrat_end_date` | 341 |
| `get_contrat_start_date` | 360 |
| `get_numcommande` | 374 |
| `get_info_region` | 383 |
| `get_info_org` | 395 |

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

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
