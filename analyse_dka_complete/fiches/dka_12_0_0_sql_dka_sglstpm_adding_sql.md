# DKA_SGLSTPM_ADDING.sql

Source : [dka/12.0.0/sql/DKA_SGLSTPM_ADDING.sql](../../dka/12.0.0/sql/DKA_SGLSTPM_ADDING.sql).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 205 ; encodage : cp1252 (repli). SHA-256 : `8e1b18547c452b8684ca14ca339d45decfab1f600c691bc48faa7003a825d5a8`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_GL_SUMMARY_TEMPLATES_SAVE` | 55 |
| `fnd_user` | 76 |
| `fnd_concurrent_programs` | 86 |
| `DKA_GL_SUMMARY_TEMPLATES_SAVE` | 102 |
| `DKA_GL_SUMMARY_TEMPLATES_SAVE` | 106 |
| `GL_SUMMARY_TEMPLATES` | 112 |
| `DKA_GL_SUMMARY_TEMPLATES_SAVE` | 113 |
| `fnd_responsibility` | 124 |
| `gl_sets_of_books` | 135 |
| `DUAL` | 204 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.get_parameter` | 63 |
| `fnd_global.apps_initialize` | 128 |
| `fnd_profile.value` | 130 |
| `fnd_request.submit_request` | 139 |
| `fnd_concurrent.wait_for_request` | 159 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 149 |
| when_others | 197 |
| soumission | 139 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
