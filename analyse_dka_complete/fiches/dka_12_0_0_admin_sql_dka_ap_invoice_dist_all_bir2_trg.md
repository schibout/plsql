# DKA_AP_INVOICE_DIST_ALL_BIR2.trg

Source : [dka/12.0.0/admin/sql/DKA_AP_INVOICE_DIST_ALL_BIR2.trg](../../dka/12.0.0/admin/sql/DKA_AP_INVOICE_DIST_ALL_BIR2.trg).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 38 ; encodage : cp1252 (repli). SHA-256 : `fbd8351f0febd29f67ac22a6386c7ce84201c605ae184e409a61817a71e8ab33`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `dka_ap_invoice_dist_all_bir2` | 1 |
| `dka_ap_invoice_dist_all_bir2` | 37 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ap_invoices_all` | 23 |
| `ap_tax_codes_all` | 25 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 32 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
