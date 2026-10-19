# DKA_AUTO_SAPDAS2_GEN.sql

Source : [dka/12.0.0/sql/DKA_AUTO_SAPDAS2_GEN.sql](../../dka/12.0.0/sql/DKA_AUTO_SAPDAS2_GEN.sql).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 767 ; encodage : cp1252 (repli). SHA-256 : `d83d856e43120cd7a28b3332b31bc200b941bdb685a9048f493f583a71274128`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `display_msg` | 122 |
| `positionnement_contexte` | 131 |
| `soumission_traitement` | 254 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `XLE_ENTITY_PROFILES` | 109 |
| `hr_operating_units` | 110 |
| `fnd_user` | 144 |
| `fnd_responsibility` | 164 |
| `fnd_concurrent_programs` | 188 |
| `fnd_concurrent_programs` | 204 |
| `dka_auto_etat` | 421 |
| `dual` | 503 |
| `fnd_responsibility` | 543 |
| `fnd_concurrent_programs` | 666 |
| `fnd_concurrent_request_class` | 669 |
| `dka_auto_etat` | 727 |
| `fnd_concurrent_programs` | 751 |
| `fnd_concurrent_request_class` | 754 |
| `DUAL` | 766 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_FILE.PUT_LINE` | 125 |
| `fnd_global.INITIALIZE` | 225 |
| `Fnd_Profile.value` | 245 |
| `Fnd_Request.submit_request` | 256 |
| `Dka_Tools_Pkg.tab_request_params` | 261 |
| `Dka_Tools_Pkg.tab_request_params` | 262 |
| `Dka_Tools_Pkg.tab_request_params` | 263 |
| `Dka_Tools_Pkg.tab_request_params` | 264 |
| `Dka_Tools_Pkg.tab_request_params` | 265 |
| `Dka_Tools_Pkg.tab_request_params` | 266 |
| `Fnd_Profile.VALUE` | 398 |
| `Dka_Tools_Pkg.get_parameter` | 449 |
| `FND_CONCURRENT.SET_COMPLETION_STATUS` | 454 |
| `FND_CONCURRENT.SET_COMPLETION_STATUS` | 511 |
| `FND_REQUEST.SET_OPTIONS` | 565 |
| `Dka_Tools_Pkg.tab_request_params` | 627 |
| `Dka_Tools_Pkg.tab_request_params` | 628 |
| `Dka_Tools_Pkg.tab_request_params` | 629 |
| `Dka_Tools_Pkg.tab_request_params` | 630 |
| `Dka_Tools_Pkg.tab_request_params` | 632 |
| `Dka_Tools_Pkg.tab_request_params` | 633 |
| `Dka_Tools_Pkg.tab_request_params` | 643 |
| `Dka_Tools_Pkg.tab_request_params` | 649 |
| `Dka_Tools_Pkg.tab_request_params` | 650 |
| `Dka_Tools_Pkg.tab_request_params` | 651 |
| `Fnd_Concurrent.wait_for_request` | 682 |
| `FND_CONCURRENT.SET_COMPLETION_STATUS` | 712 |
| `FND_CONCURRENT.SET_COMPLETION_STATUS` | 717 |
| `FND_CONCURRENT.SET_COMPLETION_STATUS` | 720 |
| `Fnd_Profile.VALUE` | 732 |
| `FND_CONCURRENT.SET_COMPLETION_STATUS` | 745 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 209, 367, 673, 736, 758 |
| when_others | 148, 168, 194, 212, 438, 506, 740 |
| soumission | 256 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_AUTO_SAPDAS2_GEN / DKA | `DKA_AUTO_SAPDAS2_GEN` | dka/12.0.0/admin/import/DKA_AUTO_SAPDAS2_GEN_F.prt:419 |
| DKA_AUTO_SAPDAS2_GEN / DKA | `DKA_AUTO_SAPDAS2_GEN` | dka/12.0.0/admin/import/DKA_AUTO_SAPDAS2_GEN_F.prt:419 |
| DKA_AUTO_SAPDAS2_GEN / DKA | `DKA_AUTO_SAPDAS2_GEN` | dka/12.0.0/admin/import/DKA_AUTO_SAPDAS2_GEN_US.prt:419 |
| DKA_AUTO_SAPDAS2_GEN / DKA | `DKA_AUTO_SAPDAS2_GEN` | dka/12.0.0/admin/import/DKA_AUTO_SAPDAS2_GEN_US.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
