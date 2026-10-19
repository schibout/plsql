# DKA_SJTGLDATAJ_POST_CLOSE.sql

Source : [dka/12.0.0/sql/DKA_SJTGLDATAJ_POST_CLOSE.sql](../../dka/12.0.0/sql/DKA_SJTGLDATAJ_POST_CLOSE.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 163 ; encodage : cp1252 (repli). SHA-256 : `cad994e10653101e7bff65b5a12a306dae2041116454badc77f2810b77c531c4`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility` | 65 |
| `fnd_user` | 70 |
| `fnd_concurrent_programs` | 79 |
| `GL_AUTOMATIC_POSTING_SETS` | 93 |
| `DUAL` | 162 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.get_parameter` | 46 |
| `fnd_global.apps_initialize` | 85 |
| `fnd_profile.value` | 87 |
| `fnd_request.submit_request` | 116 |
| `fnd_concurrent.wait_for_request` | 135 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 123 |
| when_others | 97, 153 |
| soumission | 116 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
