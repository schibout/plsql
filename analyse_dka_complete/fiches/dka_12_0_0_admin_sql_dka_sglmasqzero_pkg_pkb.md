# DKA_SGLMASQZERO_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SGLMASQZERO_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SGLMASQZERO_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 117 ; encodage : cp1252 (repli). SHA-256 : `7af49a396dc0a11280e4669ccd94d1c6d5ff9747e410b62e2a6d0a52a509190d`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 23 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_interface_control` | 38 |
| `gl_code_combinations` | 65 |
| `gl_interface` | 71 |
| `gl_code_combinations` | 78 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_log.string` | 45 |
| `fnd_log.string` | 53 |
| `fnd_log.string` | 93 |
| `fnd_log.string` | 103 |
| `fnd_file.put_line` | 109 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 100 |
| suppression | 61, 71 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
