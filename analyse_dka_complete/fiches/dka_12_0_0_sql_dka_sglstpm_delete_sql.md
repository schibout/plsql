# DKA_SGLSTPM_DELETE.sql

Source : [dka/12.0.0/sql/DKA_SGLSTPM_DELETE.sql](../../dka/12.0.0/sql/DKA_SGLSTPM_DELETE.sql).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 200 ; encodage : cp1252 (repli). SHA-256 : `61346559e578c7b02bdc9ce7c70664f96686f27003965ae9ac4992cea8a8cb97`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `GL_SUMMARY_TEMPLATES` | 64 |
| `fnd_user` | 86 |
| `fnd_concurrent_programs` | 96 |
| `DKA_GL_SUMMARY_TEMPLATES_SAVE` | 103 |
| `GL_SUMMARY_TEMPLATES` | 104 |
| `fnd_responsibility` | 124 |
| `gl_sets_of_books` | 138 |
| `DUAL` | 199 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.get_parameter` | 73 |
| `fnd_global.apps_initialize` | 129 |
| `fnd_profile.value` | 131 |
| `fnd_request.submit_request` | 142 |
| `fnd_concurrent.wait_for_request` | 176 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 155 |
| when_others | 192 |
| soumission | 142 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
