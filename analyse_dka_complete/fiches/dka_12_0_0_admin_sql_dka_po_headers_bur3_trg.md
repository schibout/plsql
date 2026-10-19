# DKA_PO_HEADERS_BUR3.trg

Source : [dka/12.0.0/admin/sql/DKA_PO_HEADERS_BUR3.trg](../../dka/12.0.0/admin/sql/DKA_PO_HEADERS_BUR3.trg).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 215 ; encodage : cp1252 (repli). SHA-256 : `6f637d6d3a2e283286b7bf294ef74beec8da99a6376c7dbd4a247286c1cf4a98`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `dka_po_headers_bur3` | 27 |
| `dka_po_headers_bur3` | 29 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ON` | 30 |
| `FND_DESCR_FLEX_COL_USAGE_VL` | 62 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `PO_MOAC_UTILS_PVT.set_org_context` | 53 |
| `fnd_profile.get` | 55 |
| `fnd_profile.get` | 56 |
| `fnd_submit.set_mode` | 71 |
| `fnd_submit.set_org_id` | 75 |
| `fnd_submit.set_nls_options` | 78 |
| `fnd_submit.set_request_set` | 84 |
| `fnd_submit.set_org_id` | 88 |
| `fnd_submit.set_nls_options` | 91 |
| `fnd_submit.submit_program` | 98 |
| `fnd_submit.set_org_id` | 137 |
| `fnd_submit.set_nls_options` | 140 |
| `fnd_submit.submit_program` | 147 |
| `fnd_submit.set_org_id` | 157 |
| `fnd_submit.set_nls_options` | 160 |
| `fnd_submit.submit_program` | 167 |
| `fnd_submit.set_org_id` | 175 |
| `fnd_submit.set_nls_options` | 178 |
| `fnd_submit.submit_program` | 185 |
| `fnd_submit.submit_set` | 194 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 67 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
