# DKA_AUTO_SAPDAS2_CTL.sql

Source : [dka/12.0.0/sql/DKA_AUTO_SAPDAS2_CTL.sql](../../dka/12.0.0/sql/DKA_AUTO_SAPDAS2_CTL.sql).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 658 ; encodage : cp1252 (repli). SHA-256 : `19c73fff8a0d7e58030f16c023587fc7712932f3ee85490610bf6ef67656fab8`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `positionnement_contexte` | 96 |
| `soumission_traitement` | 198 |
| `verif_date` | 323 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_user` | 109 |
| `fnd_responsibility` | 129 |
| `fnd_concurrent_programs` | 153 |
| `fnd_concurrent_programs` | 169 |
| `dual` | 328 |
| `dka_auto_etat` | 359 |
| `gl_ledgers` | 407 |
| `fnd_flex_values` | 408 |
| `fnd_flex_value_sets` | 409 |
| `gl_ledger_relationships` | 410 |
| `PER_SECURITY_ORGANIZATIONS` | 418 |
| `dual` | 447 |
| `fnd_concurrent_programs` | 577 |
| `fnd_concurrent_request_class` | 580 |
| `dka_auto_etat` | 621 |
| `fnd_concurrent_programs` | 642 |
| `fnd_concurrent_request_class` | 645 |
| `DUAL` | 657 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_Global.apps_initialize` | 187 |
| `Fnd_Profile.value` | 189 |
| `Fnd_Request.submit_request` | 200 |
| `Dka_Tools_Pkg.tab_request_params` | 205 |
| `Dka_Tools_Pkg.tab_request_params` | 206 |
| `Dka_Tools_Pkg.tab_request_params` | 207 |
| `Dka_Tools_Pkg.tab_request_params` | 208 |
| `Dka_Tools_Pkg.tab_request_params` | 209 |
| `Fnd_Profile.VALUE` | 342 |
| `Dka_Tools_Pkg.get_parameter` | 386 |
| `Dka_Tools_Pkg.tab_request_params` | 546 |
| `Dka_Tools_Pkg.tab_request_params` | 547 |
| `Dka_Tools_Pkg.tab_request_params` | 548 |
| `Dka_Tools_Pkg.tab_request_params` | 549 |
| `Dka_Tools_Pkg.tab_request_params` | 550 |
| `Dka_Tools_Pkg.tab_request_params` | 559 |
| `Dka_Tools_Pkg.tab_request_params` | 560 |
| `Dka_Tools_Pkg.tab_request_params` | 561 |
| `Dka_Tools_Pkg.tab_request_params` | 562 |
| `Dka_Tools_Pkg.tab_request_params` | 563 |
| `Fnd_Concurrent.wait_for_request` | 593 |
| `Fnd_Profile.VALUE` | 626 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 174, 311, 584, 630, 649 |
| when_others | 113, 133, 159, 177, 331, 375, 450, 634 |
| soumission | 200 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AUTO_SAPDAS2_CTL / DKA | `DKA_AUTO_SAPDAS2_CTL` | dka/12.0.0/admin/import/DKA_AUTO_SAPDAS2_CTL_F.prt:419 |
| DKA_AUTO_SAPDAS2_CTL / DKA | `DKA_AUTO_SAPDAS2_CTL` | dka/12.0.0/admin/import/DKA_AUTO_SAPDAS2_CTL_F.prt:419 |
| DKA_AUTO_SAPDAS2_CTL / DKA | `DKA_AUTO_SAPDAS2_CTL` | dka/12.0.0/admin/import/DKA_AUTO_SAPDAS2_CTL_US.prt:419 |
| DKA_AUTO_SAPDAS2_CTL / DKA | `DKA_AUTO_SAPDAS2_CTL` | dka/12.0.0/admin/import/DKA_AUTO_SAPDAS2_CTL_US.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
