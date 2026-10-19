# DKA_SGLALIREFEMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SGLALIREFEMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SGLALIREFEMP_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 268 ; encodage : cp1252 (repli). SHA-256 : `4b8f22f611555ae9f38875bd23e78a625867aa09aa364ba762ababcce5b2def9`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 24 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_interface_control` | 40 |
| `gl_interface` | 45 |
| `fnd_flex_value_sets` | 67 |
| `gl_interface` | 75 |
| `fnd_flex_value_sets` | 100 |
| `gl_code_combinations` | 112 |
| `fnd_flex_value_sets` | 132 |
| `gl_code_combinations` | 140 |
| `fnd_flex_value_sets` | 161 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_log.string` | 177 |
| `fnd_log.string` | 185 |
| `fnd_log.string` | 189 |
| `fnd_log.string` | 204 |
| `fnd_log.string` | 228 |
| `fnd_log.string` | 244 |
| `fnd_log.string` | 254 |
| `fnd_file.put_line` | 260 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 251 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
