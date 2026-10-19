# DKA_SGLPERUTIL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SGLPERUTIL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SGLPERUTIL_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 281 ; encodage : cp1252 (repli). SHA-256 : `e6c5bac0cfd8d2fb35e92e02ae6392a027bd14940d22d366c5662a0b380c8bf0`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_select_record_group` | 53 |
| `update_gl_tax_ccid` | 121 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl.gl_period_statuses` | 68 |
| `gl_period_statuses` | 82 |
| `gl_je_lines` | 142 |
| `OF` | 149 |
| `gl_code_combinations` | 159 |
| `gl_code_combinations` | 165 |
| `gl_code_combinations` | 172 |
| `gl_code_combinations` | 190 |
| `gl_ledgers` | 242 |
| `dual` | 248 |
| `gl_je_lines` | 254 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 71 |
| `fnd_profile.value` | 87 |
| `GL_ACCESS_SET_SECURITY_PKG.GET_DEFAULT_LEDGER_ID` | 243 |
| `FND_PROFILE.value` | 243 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 258 |
| when_others | 100, 267 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
