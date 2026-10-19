# DKA_APUREMENT_PASSE_POST_CUTOFF.sql

Source : [dka/12.0.0/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql](../../dka/12.0.0/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 312 ; encodage : cp1252 (repli). SHA-256 : `566adf866378dbaca84152ce3ccbd2eeeb07be92743f00cf94096ab55efb4e13`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_je_lines` | 53 |
| `gl_je_headers` | 102 |
| `fnd_responsibility` | 146 |
| `fnd_user` | 151 |
| `gl_periods` | 191 |
| `gl_je_lines_recon` | 222 |
| `gl_je_lines_recon` | 245 |
| `gl_code_combinations` | 255 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.VALUE` | 74 |
| `fnd_global.apps_initialize` | 155 |
| `fnd_profile.VALUE` | 196 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 282 |
| rollback | 305 |
| when_others | 301 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
