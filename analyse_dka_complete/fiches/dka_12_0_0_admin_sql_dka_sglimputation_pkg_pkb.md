# DKA_SGLIMPUTATION_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SGLIMPUTATION_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SGLIMPUTATION_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 366 ; encodage : cp1252 (repli). SHA-256 : `a183aae97cb6e5f949b4aec70a594b9bf106fe473da5b437aa300f2f0ee5804c`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 39 |
| `log_msg` | 54 |
| `p_put_debug_message` | 74 |
| `main` | 95 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `apps.fnd_concurrent_requests` | 137 |
| `fnd_responsibility` | 178 |
| `fnd_concurrent_programs` | 194 |
| `GL_AUTOMATIC_POSTING_SETS` | 214 |
| `apps.fnd_concurrent_requests` | 287 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 24 |
| `fnd_profile.value` | 25 |
| `FND_PROFILE.value` | 26 |
| `fnd_file.put_line` | 42 |
| `fnd_file.put_line` | 64 |
| `dka_tools_pkg.put_log_message` | 78 |
| `Dka_Tools_Pkg.get_parameter` | 156 |
| `fnd_global.apps_initialize` | 204 |
| `fnd_profile.value` | 206 |
| `fnd_request.submit_request` | 230 |
| `fnd_concurrent.wait_for_request` | 257 |
| `fnd_concurrent.wait_for_request` | 311 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 243, 315 |
| when_others | 218, 352 |
| soumission | 230 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SGLIMPUTATION / DKA | `DKA_SGLIMPUTATION_PKG.main` | dka/12.0.0/admin/import/DKA_SGLIMPUTATION.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
