# DKA_GL_TOOLS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_GL_TOOLS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_GL_TOOLS_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 268 ; encodage : cp1252 (repli). SHA-256 : `dcc6c36969e69af79de9d7319df8e4475dcd508eb3b37d17dc606db99031ae7d`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `gl_get_lookup_meaning` | 43 |
| `get_legder_id` | 75 |
| `gl_get_category_autorev_flag` | 112 |
| `period_gl_to_close` | 171 |
| `gl_is_special_period_open` | 218 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_lookups` | 53 |
| `gl_ledgers` | 85 |
| `gl_autoreverse_options` | 134 |
| `gl_autoreverse_options` | 140 |
| `gl_automatic_posting_sets` | 187 |
| `gl_period_statuses_v` | 231 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `gl_access_set_security_pkg.get_default_ledger_id` | 127 |
| `FND_PROFILE.value` | 127 |
| `gl_access_set_security_pkg.get_default_ledger_id` | 233 |
| `FND_PROFILE.value` | 233 |
| `Fnd_Profile.VALUE` | 244 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 59, 91, 152, 199, 260 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
