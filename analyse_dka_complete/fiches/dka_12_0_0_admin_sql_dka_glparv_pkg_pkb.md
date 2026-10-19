# DKA_GLPARV_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_GLPARV_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_GLPARV_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 278 ; encodage : cp1252 (repli). SHA-256 : `a4b6ddb4694366cdf8f7fc492ce6cc5092d7880980600be908e2f42236fe2f18`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 52 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_access_set_assignments` | 61 |
| `GL_JE_SOURCES` | 91 |
| `gl_period_statuses` | 116 |
| `gl_period_statuses` | 161 |
| `GL_JE_SOURCES` | 263 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_Profile.VALUE` | 62 |
| `fnd_request.submit_request` | 168 |
| `fnd_profile.value` | 176 |
| `dka_tools_pkg.put_debug_message` | 186 |
| `dka_tools_pkg.put_debug_message` | 189 |
| `fnd_concurrent.wait_for_request` | 243 |
| `dka_tools_pkg.put_debug_message` | 246 |
| `dka_tools_pkg.put_debug_message` | 247 |
| `dka_tools_pkg.put_debug_message` | 251 |
| `dka_tools_pkg.put_debug_message` | 253 |
| `dka_tools_pkg.put_debug_message` | 255 |
| `dka_tools_pkg.put_debug_message` | 256 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `GLPARV` | 168 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 94, 192, 266 |
| when_others | 269 |
| soumission | 168 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_GLPARV / DKA | `dka_GLPARV_pkg.main` | dka/12.0.0/admin/import/DKA_GLPARV.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
