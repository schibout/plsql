# DKA_WF_ITEM_ACTIVITY_STAT_AUR.trg

Source : [dka/12.0.0/admin/sql/DKA_WF_ITEM_ACTIVITY_STAT_AUR.trg](../../dka/12.0.0/admin/sql/DKA_WF_ITEM_ACTIVITY_STAT_AUR.trg).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 129 ; encodage : utf-8. SHA-256 : `67bcaf2d9144267d6f6efde0ae09008d08eb02635d34ef936f4db8e802411232`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_WF_ITEM_ACTIVITY_STAT_AUR` | 1 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ON` | 24 |
| `po_headers_all` | 45 |
| `ICX_CAT_ITEMS_CTX_HDRS_TLP` | 57 |
| `DKA_PO_GA_ORG_ASSIGNMENTS` | 63 |
| `PO_GA_ORG_ASSIGNMENTS` | 73 |
| `po_lines_all` | 81 |
| `PO_GA_ORG_ASSIGNMENTS` | 95 |
| `PO_GA_ORG_ASSIGNMENTS` | 101 |
| `DKA_PO_GA_ORG_ASSIGNMENTS` | 113 |
| `DKA_PO_GA_ORG_ASSIGNMENTS` | 118 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 48, 125 |
| suppression | 95, 118 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
