# DKA_SPOCREATEPO_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOCREATEPO_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOCREATEPO_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 250 ; encodage : cp1252 (repli). SHA-256 : `38398f596ae0e733d4af1cecb9a776dcb79ed6f684a2add2cb3447909a2c9c75`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `does_contract_exist` | 46 |
| `is_autocreation_authorized` | 181 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_headers` | 105 |
| `PO_REQUISITION_LINES_ALL` | 143 |
| `po_vendors` | 218 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.VALUE` | 27 |
| `po_wf_util_pkg.getitemattrnumber` | 68 |
| `po_wf_util_pkg.getitemattrnumber` | 72 |
| `po_wf_util_pkg.getitemattrtext` | 76 |
| `po_wf_util_pkg.GetItemAttrText` | 81 |
| `po_wf_util_pkg.GetItemAttrNumber` | 85 |
| `po_wf_util_pkg.setitemattrnumber` | 129 |
| `po_wf_util_pkg.setitemattrtext` | 133 |
| `wf_core.CONTEXT` | 148 |
| `wf_core.CONTEXT` | 164 |
| `po_wf_util_pkg.getitemattrnumber` | 195 |
| `po_wf_util_pkg.getitemattrnumber` | 199 |
| `wf_core.CONTEXT` | 240 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 119, 147, 163, 222, 239 |
| workflow | 92, 153, 157, 209, 231, 233 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
