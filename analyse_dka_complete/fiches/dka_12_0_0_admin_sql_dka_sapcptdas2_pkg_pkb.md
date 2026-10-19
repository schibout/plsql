# DKA_SAPCPTDAS2_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPCPTDAS2_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPCPTDAS2_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 192 ; encodage : cp1252 (repli). SHA-256 : `ca9444c16571a987133373cf92d97487e2ce892afd9457ab1f44181c85e5b061`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_code_das` | 47 |
| `check_das_required` | 155 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_flex_values` | 65 |
| `fnd_flex_values` | 172 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.get_flex_key_seg_value_set` | 74 |
| `dka_tools_pkg.get_message` | 104 |
| `dka_tools_pkg.get_message` | 132 |
| `dka_tools_pkg.get_flex_key_seg_value_set` | 168 |
| `dka_tools_pkg.get_message` | 179 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 134, 183 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
