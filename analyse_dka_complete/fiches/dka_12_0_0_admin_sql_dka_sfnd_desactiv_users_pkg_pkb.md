# DKA_SFND_DESACTIV_USERS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SFND_DESACTIV_USERS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SFND_DESACTIV_USERS_PKG.pkb).

Famille proposée par convention de nommage : **FND / administration**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 345 ; encodage : cp1252 (repli). SHA-256 : `2a2c7aa7e8e0e905f0557796d2cfa866e62ccd75ee1ed77bb86d70a577af87aa`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 26 |
| `get_purchasing_users` | 69 |
| `get_financial_users` | 153 |
| `get_employee_users` | 237 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_user` | 81 |
| `ak_web_user_sec_attr_values` | 87 |
| `per_all_people_f` | 101 |
| `per_all_assignments_f` | 104 |
| `fnd_user` | 132 |
| `fnd_user` | 165 |
| `ak_web_user_sec_attr_values` | 171 |
| `fnd_user_resp_groups` | 183 |
| `per_all_people_f` | 188 |
| `per_all_assignments_f` | 191 |
| `fnd_user` | 217 |
| `fnd_user` | 255 |
| `ak_web_user_sec_attr_values` | 266 |
| `per_all_assignments_f` | 273 |
| `fnd_user` | 309 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_tools_pkg.put_outdebug_message` | 49 |
| `DKA_tools_pkg.put_outdebug_message` | 50 |
| `DKA_tools_pkg.put_outdebug_message` | 51 |
| `DKA_tools_pkg.put_outdebug_message` | 57 |
| `DKA_tools_pkg.put_outdebug_message` | 58 |
| `DKA_tools_pkg.put_outdebug_message` | 59 |
| `DKA_tools_pkg.put_outdebug_message` | 60 |
| `DKA_tools_pkg.put_outdebug_message` | 61 |
| `DKA_tools_pkg.put_outdebug_message` | 62 |
| `DKA_tools_pkg.put_outdebug_message` | 63 |
| `DKA_tools_pkg.put_outdebug_message` | 121 |
| `DKA_tools_pkg.put_outdebug_message` | 122 |
| `DKA_tools_pkg.put_outdebug_message` | 123 |
| `DKA_tools_pkg.put_outdebug_message` | 137 |
| `DKA_tools_pkg.put_outdebug_message` | 205 |
| `DKA_tools_pkg.put_outdebug_message` | 206 |
| `DKA_tools_pkg.put_outdebug_message` | 207 |
| `DKA_tools_pkg.put_outdebug_message` | 208 |
| `DKA_tools_pkg.put_outdebug_message` | 222 |
| `DKA_tools_pkg.put_outdebug_message` | 290 |
| `DKA_tools_pkg.put_outdebug_message` | 291 |
| `DKA_tools_pkg.put_outdebug_message` | 292 |
| `DKA_tools_pkg.put_outdebug_message` | 293 |
| `DKA_tools_pkg.put_outdebug_message` | 315 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 64 |
| when_others | 140, 225, 329 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SFND_DESACTIV_USERS / DKA | `DKA_SFND_DESACTIV_USERS_PKG.main` | dka/12.0.0/admin/import/DKA_SFND_DESACTIV_USERS.prt:461 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
