# FA_RECLASS_HOOK_CCID_PKG.pkb

Source : [dka/12.0.0/admin/sql/FA_RECLASS_HOOK_CCID_PKG.pkb](../../dka/12.0.0/admin/sql/FA_RECLASS_HOOK_CCID_PKG.pkb).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 283 ; encodage : utf-8. SHA-256 : `e680077890fb27f909c205b32cc737f3ac6bfd7b606c7c84e2e3d06b539b73f0`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `GET_NEW_CCID` | 30 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fa_additions_b` | 84 |
| `fa_distribution_history` | 95 |
| `fa_book_controls` | 108 |
| `fa_book_controls` | 132 |
| `dual` | 234 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_FLEX_WORKFLOW.INITIALIZE` | 135 |
| `wf_engine.SetItemAttrText` | 143 |
| `wf_engine.SetItemAttrText` | 148 |
| `wf_engine.SetItemAttrNumber` | 152 |
| `wf_engine.SetItemAttrNumber` | 157 |
| `wf_engine.SetItemAttrText` | 162 |
| `wf_engine.SetItemAttrNumber` | 166 |
| `wf_engine.SetItemAttrNumber` | 170 |
| `wf_engine.SetItemAttrNumber` | 174 |
| `FND_FLEX_WORKFLOW.GENERATE` | 180 |
| `FND_MESSAGE.PARSE_ENCODED` | 198 |
| `FND_FLEX_EXT.get_ccid` | 235 |
| `FND_MESSAGE.SET_ENCODED` | 243 |
| `wf_core.context` | 264 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 263, 273 |
| when_others | 262, 272 |
| workflow | 143, 148, 152, 157, 162, 166, 170, 174 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
