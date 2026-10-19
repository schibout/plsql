# DKA_GL_JE_LINES_BIR.trg

Source : [dka/12.0.0/admin/sql/DKA_GL_JE_LINES_BIR.trg](../../dka/12.0.0/admin/sql/DKA_GL_JE_LINES_BIR.trg).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 269 ; encodage : cp1252 (repli). SHA-256 : `d464a3c6c1d29f25ec6204b3c845b2fa5e0abeb4f60daa615b19ea6de99d0b82`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_GL_JE_LINES_BIR` | 2 |
| `dka_gl_je_lines_bir` | 5 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_je_headers` | 44 |
| `gl_code_combinations` | 81 |
| `gl_je_headers` | 98 |
| `gl_je_headers` | 141 |
| `gl_code_combinations` | 215 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_pa_tools_pkg.get_centre_finance` | 85 |
| `dka_spaautoaccounting_pkg.run_cpt_groupe_couts_f` | 112 |
| `dka_spaautoaccounting_pkg.run_cpt_groupe_produit_f` | 122 |
| `dka_tools_pkg.get_code_combination_id` | 219 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 262 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
