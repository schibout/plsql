# DKA_AP_INVOICES_INTERFACE_BIUR.trg

Source : [dka/12.0.0/admin/sql/DKA_AP_INVOICES_INTERFACE_BIUR.trg](../../dka/12.0.0/admin/sql/DKA_AP_INVOICES_INTERFACE_BIUR.trg).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 92 ; encodage : cp1252 (repli). SHA-256 : `698b4ebbe19a19cf12a2a2bc9eadf00fbe35c156d01b72e0286299afb30ca964`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_AP_INVOICES_INTERFACE_BIUR` | 1 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `or` | 3 |
| `RA_CUSTOMER_TRX_ALL` | 52 |
| `AR_RECEIVABLE_APPLICATIONS_ALL` | 54 |
| `GL_CODE_COMBINATIONS` | 62 |
| `FINANCIALS_SYSTEM_PARAMETERS` | 64 |
| `GL_CODE_COMBINATIONS` | 71 |
| `RA_CUST_TRX_LINE_GL_DIST_ALL` | 73 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_PROFILE.value` | 67 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 87 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
