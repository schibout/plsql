# DKA_GL_JE_LINES_RECON_AIUR.trg

Source : [dka/12.0.0/admin/sql/DKA_GL_JE_LINES_RECON_AIUR.trg](../../dka/12.0.0/admin/sql/DKA_GL_JE_LINES_RECON_AIUR.trg).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 82 ; encodage : cp1252 (repli). SHA-256 : `38b3ee435615f7df922dfd568951e6ab2198e74cb21ba3013263276af15ee498`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_GL_JE_LINES_RECON_AIUR` | 22 |
| `DKA_GL_JE_LINES_RECON_AIUR` | 24 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ON` | 25 |
| `gl_code_combinations` | 41 |
| `fnd_flex_value_sets` | 46 |
| `gl_je_lines_recon` | 55 |
| `gl_je_lines_recon` | 65 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 59, 76 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
