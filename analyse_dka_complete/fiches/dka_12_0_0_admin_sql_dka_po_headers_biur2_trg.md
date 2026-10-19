# DKA_PO_HEADERS_BIUR2.trg

Source : [dka/12.0.0/admin/sql/DKA_PO_HEADERS_BIUR2.trg](../../dka/12.0.0/admin/sql/DKA_PO_HEADERS_BIUR2.trg).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 438 ; encodage : cp1252 (repli). SHA-256 : `81767d763096dd4f73b92c918daff900ecc583e0295991d7c303ef2832e394eb`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

| Élément | Ligne source |
|---|---:|
| `DKA_PO_HEADERS_BIUR2` | 1 |
| `PO` | 434 |

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ON` | 39 |
| `PO.PO_LINES_ALL` | 75 |
| `DKA_SPOPARAM_FRAIS_PORT` | 92 |
| `DKA_SPOPARAM_FRAIS_PORT` | 200 |
| `PO.PO_LINES_ALL` | 211 |
| `PO.PO_LINES_ALL` | 263 |
| `DKA_SPOPARAM_FRAIS_PORT` | 365 |
| `PO.PO_LINES_ALL` | 394 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_SPOFRAIS_PORT_PKG.Supprimer_ligne` | 124 |
| `DKA_SPOFRAIS_PORT_PKG.Annuler_ligne` | 137 |
| `DKA_SPOFRAIS_PORT_PKG.Supprimer_ligne` | 160 |
| `DKA_SPOFRAIS_PORT_PKG.Annuler_ligne` | 177 |
| `DKA_SPOFRAIS_PORT_PKG.Calculer_montant` | 190 |
| `DKA_SPOFRAIS_PORT_PKG.g_header_id_tab` | 232 |
| `DKA_SPOFRAIS_PORT_PKG.g_vendor_id_tab` | 233 |
| `DKA_SPOFRAIS_PORT_PKG.g_header_id_tab` | 243 |
| `DKA_SPOFRAIS_PORT_PKG.g_vendor_id_tab` | 244 |
| `DKA_SPOFRAIS_PORT_PKG.Supprimer_ligne` | 282 |
| `DKA_SPOFRAIS_PORT_PKG.Annuler_ligne` | 286 |
| `DKA_SPOFRAIS_PORT_PKG.Supprimer_ligne` | 321 |
| `DKA_SPOFRAIS_PORT_PKG.Annuler_ligne` | 334 |
| `DKA_SPOFRAIS_PORT_PKG.Supprimer_ligne` | 407 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 300, 378, 417, 426, 432 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
