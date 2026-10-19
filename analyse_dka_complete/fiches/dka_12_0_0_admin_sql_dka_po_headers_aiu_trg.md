# DKA_PO_HEADERS_AIU.trg

Source : [dka/12.0.0/admin/sql/DKA_PO_HEADERS_AIU.trg](../../dka/12.0.0/admin/sql/DKA_PO_HEADERS_AIU.trg).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 49 ; encodage : cp1252 (repli). SHA-256 : `8b402125c8dac995236103927258179f420d9e000e1358eeaef69c6891aca881`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_PO_HEADERS_AIU` | 1 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ON` | 23 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_SPOFRAIS_PORT_PKG.Inserer_ligne` | 34 |
| `DKA_SPOFRAIS_PORT_PKG.g_header_id_tab` | 34 |
| `DKA_SPOFRAIS_PORT_PKG.g_vendor_id_tab` | 35 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 44 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
