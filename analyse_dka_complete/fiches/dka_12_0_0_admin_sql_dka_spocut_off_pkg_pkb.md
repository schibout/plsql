# DKA_SPOCUT_OFF_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOCUT_OFF_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOCUT_OFF_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1594 ; encodage : cp1252 (repli). SHA-256 : `e8a4a3152202d7f6d4862230490b3de4765ba2a3cc20809dae7a9eae36ba54d6`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `log_msg` | 88 |
| `out_msg` | 107 |
| `init` | 126 |
| `get_charge_theorique_imput` | 271 |
| `main` | 429 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_period_statuses` | 228 |
| `po_headers_archive_all` | 301 |
| `po_headers_archive_all` | 308 |
| `dka_contrat_sstr_imput_archi` | 316 |
| `po_headers_all` | 528 |
| `po_headers_archive_all` | 535 |
| `dka_contrat_sstr_archi` | 539 |
| `dual` | 728 |
| `dual` | 731 |
| `gl_je_sources` | 740 |
| `gl_interface_control` | 744 |
| `gl_ledgers` | 829 |
| `gl_interface` | 955 |
| `gl_interface` | 1125 |
| `gl_interface` | 1265 |
| `gl_interface` | 1343 |
| `gl_interface` | 1421 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 95 |
| `fnd_file.put_line` | 109 |
| `dka_tools_pkg.get_parameter` | 142 |
| `dka_tools_pkg.get_parameter` | 155 |
| `dka_tools_pkg.get_parameter` | 168 |
| `dka_tools_pkg.get_parameter` | 181 |
| `dka_stransco_pkg.get_value_f` | 194 |
| `dka_stransco_pkg.get_value_f` | 205 |
| `dka_stransco_pkg.get_value_f` | 216 |
| `fnd_profile.value` | 235 |
| `DKA_SPAAUTOACCOUNTING_PKG.societe_projet` | 472 |
| `DKA_SPAAUTOACCOUNTING_PKG.uo_projet` | 479 |
| `DKA_SPAAUTOACCOUNTING_PKG.cpt_groupe_couts` | 486 |
| `dka_spaautoaccounting_pkg.get_interco_fourn_f` | 493 |
| `dka_spaautoaccounting_pkg.centrefi` | 496 |
| `Dka_Spaautoaccounting_Pkg.affaire` | 498 |
| `Dka_Spaautoaccounting_Pkg.projetfi` | 501 |
| `DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts` | 911 |
| `Dka_Tools_Pkg.get_code_combination_id` | 920 |
| `DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts` | 1081 |
| `Dka_Tools_Pkg.get_code_combination_id` | 1090 |
| `fnd_request.submit_request` | 1523 |
| `fnd_concurrent.wait_for_request` | 1547 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `GLLEZL` | 1523 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1507, 1545 |
| when_others | 254, 395, 1585 |
| soumission | 1523 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOCUT_OFF / DKA | `DKA_SPOCUT_OFF_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCUT_OFF.prt:453 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
