# DKA_PO_HEADERS_AUR.trg

Source : [dka/12.0.0/admin/sql/DKA_PO_HEADERS_AUR.trg](../../dka/12.0.0/admin/sql/DKA_PO_HEADERS_AUR.trg).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 207 ; encodage : cp1252 (repli). SHA-256 : `e0a88dd7435c588946265cb062556faefadfd705734c2dbc27058a2a41131901`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_PO_HEADERS_AUR` | 1 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ON` | 23 |
| `PO_GA_ORG_ASSIGNMENTS` | 42 |
| `DKA_PO_GA_ORG_ASSIGNMENTS` | 51 |
| `DKA_PO_GA_ORG_ASSIGNMENTS` | 55 |
| `PO_GA_ORG_ASSIGNMENTS` | 69 |
| `PO_GA_ORG_ASSIGNMENTS` | 75 |
| `DKA_PO_GA_ORG_ASSIGNMENTS` | 83 |
| `DKA_PO_GA_ORG_ASSIGNMENTS` | 100 |
| `DKA_PO_GA_ORG_ASSIGNMENTS` | 126 |
| `DKA_PO_GA_ORG_ASSIGNMENTS` | 149 |
| `PO_GA_ORG_ASSIGNMENTS` | 159 |
| `ICX_CAT_ITEMS_CTX_DTLS_TLP` | 164 |
| `po_lines_all` | 166 |
| `ICX_CAT_ITEMS_CTX_HDRS_TLP` | 170 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 112, 136, 203 |
| suppression | 51, 75, 164, 170 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
