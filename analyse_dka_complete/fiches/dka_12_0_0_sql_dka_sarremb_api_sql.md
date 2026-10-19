# DKA_SARREMB_API.sql

Source : [dka/12.0.0/sql/DKA_SARREMB_API.sql](../../dka/12.0.0/sql/DKA_SARREMB_API.sql).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 375 ; encodage : cp1252 (repli). SHA-256 : `e5d146dc11433ab6c7317112381c6f8f543411ee367ae2a25771bca34b019334`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_ar_remboursement_avoirs` | 79 |
| `ra_customer_trx_all` | 95 |
| `hz_cust_accounts` | 124 |
| `ar_receivables_trx_all` | 167 |
| `ar_cash_receipts_all` | 184 |
| `hz_cust_accounts` | 199 |
| `DKA_ARREMB_REPORTING` | 286 |
| `activity_flag` | 295 |
| `DKA_ARREMB_REPORTING` | 304 |
| `activity_flag` | 313 |
| `DKA_ARREMB_REPORTING` | 346 |
| `activity_flag` | 355 |
| `DUAL` | 374 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Ar_receipt_api_pub.Activity_application` | 237 |
| `FND_MSG_PUB.Get` | 323 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 272, 291, 309, 351 |
| when_others | 106, 155, 171, 189, 220, 294, 312, 354, 365 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
