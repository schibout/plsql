# DKA_SPOBON_POAPPRV.wft

Source : [dka/12.0.0/admin/import/DKA_SPOBON_POAPPRV.wft](../../dka/12.0.0/admin/import/DKA_SPOBON_POAPPRV.wft).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 48379 ; encodage : cp1252 (repli). SHA-256 : `4df72ecc95ecf6c569cdf76e9f41d8f72eb08072663b187ec339f312efbde916`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `REFERENCES` | 134 |
| `Role` | 15136 |
| `Role` | 15137 |
| `Role` | 18786 |
| `Role` | 18787 |
| `Role` | 18953 |
| `Role` | 18954 |
| `Role` | 19142 |
| `Role` | 19143 |
| `Role` | 19331 |
| `Role` | 19332 |
| `Role` | 19514 |
| `Role` | 19515 |
| `Role` | 19677 |
| `Role` | 19678 |
| `REQUEST_REJECTED_FYI` | 19691 |
| `Role` | 19831 |
| `Role` | 19832 |
| `Role` | 20013 |
| `Role` | 20014 |
| `Role` | 20196 |
| `Role` | 20197 |
| `APPR` | 41210 |
| `APPR` | 41246 |
| `APPROVER` | 41286 |
| `APPROVER` | 41333 |
| `APPROVER` | 41351 |
| `SSP` | 45456 |
| `S` | 45457 |
| `PO` | 45502 |
| `PO` | 45503 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 5602, 5621, 5646, 5665 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
