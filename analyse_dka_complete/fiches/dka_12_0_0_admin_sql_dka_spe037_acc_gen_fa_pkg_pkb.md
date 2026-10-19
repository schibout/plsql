# DKA_SPE037_ACC_GEN_FA_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPE037_ACC_GEN_FA_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPE037_ACC_GEN_FA_PKG.pkb).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 404 ; encodage : cp1252 (repli). SHA-256 : `be0e4915f38802963774988a6d0d09d6a3d9419cadaef5c8c32393dfda45fae5`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 47 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fa_distribution_history` | 150 |
| `fa_asset_invoices` | 159 |
| `fa_additions_b` | 186 |
| `pa_tasks` | 218 |
| `pa.pa_tasks` | 220 |
| `fa_additions_b` | 277 |
| `FA_BOOK_CONTROLS` | 291 |
| `fa_additions_b` | 301 |
| `FA_BOOK_CONTROLS` | 366 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `wf_engine.getitemattrnumber` | 105 |
| `wf_engine.getitemattrtext` | 112 |
| `wf_engine.getitemattrnumber` | 118 |
| `wf_engine.getitemattrnumber` | 124 |
| `wf_engine.getitemattrnumber` | 130 |
| `wf_engine.getitemattrtext` | 135 |
| `wf_engine.setitemattrnumber` | 194 |
| `DKA_SPAAUTOACCOUNTING_PKG.uo_projet` | 199 |
| `wf_engine.setitemattrtext` | 201 |
| `wf_engine.setitemattrnumber` | 206 |
| `wf_engine.setitemattrnumber` | 211 |
| `wf_engine.setitemattrtext` | 227 |
| `dka_pa_tools_pkg.get_class_project` | 235 |
| `wf_engine.setitemattrtext` | 241 |
| `dka_pa_tools_pkg.get_centre_finance` | 247 |
| `wf_engine.setitemattrtext` | 249 |
| `dka_pa_tools_pkg.get_class_project` | 255 |
| `wf_engine.setitemattrtext` | 261 |
| `wf_engine.setitemattrtext` | 284 |
| `wf_engine.getItemAttrText` | 293 |
| `wf_engine.setitemattrtext` | 324 |
| `dka_stransco_pkg.get_value_f` | 341 |
| `wf_engine.setitemattrtext` | 347 |
| `wf_engine.setitemattrnumber` | 357 |
| `wf_engine.setitemattrtext` | 374 |
| `wf_engine.setitemattrtext` | 384 |
| `wf_core.CONTEXT` | 389 |
| `wf_core.CONTEXT` | 395 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 165, 394 |
| workflow | 95, 96, 105, 112, 118, 124, 130, 135, 194, 201, 206, 211, 227, 241, 249, 261, 284, 293, 324, 347, 357, 374, 384 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
