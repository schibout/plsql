# DKA_AR_TOOLS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_AR_TOOLS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_AR_TOOLS_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 268 ; encodage : cp1252 (repli). SHA-256 : `67ed33208b5b3f22bba8ef066bdfd1c68b1cf6cc446832a1c9d494f50e913214`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_customer_partner` | 50 |
| `alim_corresp_operations` | 166 |
| `issurtaxeaccount` | 240 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_code_combinations` | 72 |
| `gl_code_combinations` | 111 |
| `RB_BANK_TRANSACTION_CODES_LNK` | 195 |
| `AR_RECEIPT_CLASSES` | 213 |
| `AR_RECEIPT_METHODS` | 214 |
| `RB_BANK_TRANSACTION_CODES_LNK` | 218 |
| `fnd_flex_value_sets` | 247 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 208 |
| `fnd_profile.value` | 210 |
| `fnd_profile.value` | 212 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 220 |
| when_others | 130, 148, 223, 261 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
