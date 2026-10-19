# DKA_SAPXCRRCR_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPXCRRCR_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPXCRRCR_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 544 ; encodage : cp1252 (repli). SHA-256 : `74d110e1ff3597a8ed6df1670fe213dc7ffb9c1fe5cb631130935cf08ea7eaed`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 52 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `PER_SECURITY_PROFILES_V` | 123 |
| `FINANCIALS_SYSTEM_PARAMS_ALL` | 129 |
| `fnd_user` | 225 |
| `dka_stransco_lines` | 240 |
| `fnd_responsibility` | 260 |
| `fnd_responsibility` | 282 |
| `AP_PAYMENT_TEMPLATES` | 435 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_PROFILE.VALUE` | 128 |
| `dka_tools_pkg.put_log_message` | 157 |
| `dka_tools_pkg.put_log_message` | 158 |
| `dka_tools_pkg.put_log_message` | 159 |
| `dka_tools_pkg.put_log_message` | 162 |
| `Dka_Tools_Pkg.put_log_message` | 207 |
| `Dka_Tools_Pkg.put_log_message` | 232 |
| `Dka_Tools_Pkg.put_log_message` | 264 |
| `dka_tools_pkg.get_parameter` | 269 |
| `Dka_Tools_Pkg.put_log_message` | 278 |
| `Dka_Tools_Pkg.put_log_message` | 289 |
| `Dka_Tools_Pkg.put_log_message` | 296 |
| `Dka_Tools_Pkg.put_log_message` | 297 |
| `Dka_Tools_Pkg.put_log_message` | 298 |
| `fnd_global.apps_initialize` | 299 |
| `fnd_profile.value` | 420 |
| `fnd_request.set_print_options` | 425 |
| `Fnd_Request.set_org_id` | 429 |
| `Dka_Tools_Pkg.put_log_message` | 430 |
| `fnd_request.submit_request` | 441 |
| `Dka_Tools_Pkg.put_log_message` | 463 |
| `dka_tools_pkg.put_outdebug_message` | 471 |
| `fnd_concurrent.wait_for_request` | 483 |
| `dka_tools_pkg.put_outdebug_message` | 495 |
| `dka_tools_pkg.put_outdebug_message` | 504 |
| `dka_tools_pkg.put_outdebug_message` | 510 |
| `dka_tools_pkg.put_outdebug_message` | 513 |
| `dka_tools_pkg.put_outdebug_message` | 521 |
| `dka_tools_pkg.put_outdebug_message` | 522 |
| `dka_tools_pkg.put_outdebug_message` | 523 |
| `dka_tools_pkg.put_outdebug_message` | 524 |
| `dka_tools_pkg.put_outdebug_message` | 525 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_APXCRRCR` | 441 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 478 |
| when_others | 263, 286, 535 |
| soumission | 441 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPXCRRCR / DKA | `dka_sapxcrrcr_pkg.main` | dka/12.0.0/admin/import/DKA_SAPXCRRCR.prt:729 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
