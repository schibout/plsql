# DKA_SPAAUTOACCOUNTING_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SPAAUTOACCOUNTING_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SPAAUTOACCOUNTING_PKG.pks).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 573 ; encodage : cp1252 (repli). SHA-256 : `f36a3fcb7981f7bc56e24da82a82a3524674b044124c97ebf9dc7fa32043951c`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 46 |
| `get_org_id_f` | 65 |
| `get_organisation_f` | 85 |
| `get_project_type_f` | 103 |
| `get_project_code_f` | 121 |
| `get_pa_code_express_f` | 140 |
| `get_task_asset_category_f` | 160 |
| `get_back_billing_project_f` | 179 |
| `get_dest_projet_f` | 197 |
| `get_affaire_projet_f` | 215 |
| `get_task_template_f` | 233 |
| `get_task_attribute_f` | 251 |
| `get_interco_fourn_f` | 269 |
| `get_vendor_site_id_f` | 288 |
| `get_project_id_f` | 307 |
| `centrefi` | 325 |
| `affaire` | 343 |
| `flux` | 361 |
| `societe_projet` | 379 |
| `projetfi` | 397 |
| `uo_projet` | 415 |
| `code_interco` | 435 |
| `cpt_local_couts` | 457 |
| `cpt_groupe_couts` | 482 |
| `cpt_groupe_produit` | 507 |
| `run_cpt_groupe_couts_f` | 534 |
| `run_cpt_groupe_produit_f` | 560 |

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
