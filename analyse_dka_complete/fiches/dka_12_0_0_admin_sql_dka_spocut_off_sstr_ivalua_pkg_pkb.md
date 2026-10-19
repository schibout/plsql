# DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1464 ; encodage : cp1252 (repli). SHA-256 : `1359ab834da1760133282fd851c58ac5eb2ca5ee9a394d6f89a9ebdca53b849a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `log_msg` | 53 |
| `out_msg` | 72 |
| `init` | 91 |
| `get_charge_theorique_imput` | 237 |
| `main` | 350 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_period_statuses` | 193 |
| `po_headers_all` | 430 |
| `dual` | 626 |
| `dual` | 629 |
| `gl_je_sources` | 638 |
| `gl_interface_control` | 642 |
| `gl_ledgers` | 726 |
| `gl_interface` | 836 |
| `gl_interface` | 995 |
| `gl_interface` | 1135 |
| `gl_interface` | 1213 |
| `gl_interface` | 1291 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 60 |
| `fnd_file.put_line` | 74 |
| `dka_tools_pkg.get_parameter` | 107 |
| `dka_tools_pkg.get_parameter` | 120 |
| `dka_tools_pkg.get_parameter` | 133 |
| `dka_tools_pkg.get_parameter` | 146 |
| `dka_stransco_pkg.get_value_f` | 159 |
| `dka_stransco_pkg.get_value_f` | 170 |
| `dka_stransco_pkg.get_value_f` | 181 |
| `fnd_profile.value` | 200 |
| `DKA_SPAAUTOACCOUNTING_PKG.societe_projet` | 392 |
| `DKA_SPAAUTOACCOUNTING_PKG.uo_projet` | 394 |
| `DKA_SPAAUTOACCOUNTING_PKG.cpt_groupe_couts` | 397 |
| `dka_spaautoaccounting_pkg.get_interco_fourn_f` | 402 |
| `dka_spaautoaccounting_pkg.centrefi` | 404 |
| `Dka_Spaautoaccounting_Pkg.affaire` | 406 |
| `Dka_Spaautoaccounting_Pkg.projetfi` | 408 |
| `DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts` | 792 |
| `Dka_Tools_Pkg.get_code_combination_id` | 801 |
| `DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts` | 951 |
| `Dka_Tools_Pkg.get_code_combination_id` | 960 |
| `fnd_request.submit_request` | 1393 |
| `fnd_concurrent.wait_for_request` | 1417 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `GLLEZL` | 1393 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1377, 1415 |
| when_others | 219, 320, 1455 |
| soumission | 1393 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOCUT_OFF_SSTR_IVALUA / DKA | `DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.Main` | dka/12.0.0/admin/import/DKA_SPOCUT_OFF_SSTR_IVALUA.prt:545 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
