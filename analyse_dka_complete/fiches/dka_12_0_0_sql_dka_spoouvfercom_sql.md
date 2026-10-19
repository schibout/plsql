# DKA_SPOOUVFERCOM.sql

Source : [dka/12.0.0/sql/DKA_SPOOUVFERCOM.sql](../../dka/12.0.0/sql/DKA_SPOOUVFERCOM.sql).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 470 ; encodage : cp1252 (repli). SHA-256 : `20ff90b280b7625ee284439ae79510e80f6b283943cfee47ecc83e5f033f7171`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_headers` | 92 |
| `po_line_locations` | 123 |
| `po_lines` | 167 |
| `po_headers` | 208 |
| `po_line_locations` | 234 |
| `po_lines` | 246 |
| `po_headers` | 257 |
| `po_line_locations` | 284 |
| `po_lines` | 298 |
| `po_headers` | 311 |
| `wf_item_activity_statuses` | 339 |
| `po_headers` | 363 |
| `wf_items` | 381 |
| `wf_items` | 402 |
| `Dka_Trace_For_Sox` | 422 |
| `DUAL` | 469 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_TOOLS_PKG.put_debug_message` | 68 |
| `DKA_TOOLS_PKG.put_debug_message` | 99 |
| `DKA_TOOLS_PKG.put_debug_message` | 113 |
| `DKA_TOOLS_PKG.put_debug_message` | 127 |
| `DKA_TOOLS_PKG.put_debug_message` | 144 |
| `DKA_TOOLS_PKG.put_debug_message` | 157 |
| `DKA_TOOLS_PKG.put_debug_message` | 172 |
| `DKA_TOOLS_PKG.put_debug_message` | 189 |
| `DKA_TOOLS_PKG.put_debug_message` | 201 |
| `DKA_TOOLS_PKG.put_debug_message` | 211 |
| `DKA_TOOLS_PKG.put_debug_message` | 223 |
| `DKA_TOOLS_PKG.put_debug_message` | 231 |
| `DKA_TOOLS_PKG.put_debug_message` | 243 |
| `DKA_TOOLS_PKG.put_debug_message` | 254 |
| `DKA_TOOLS_PKG.put_debug_message` | 267 |
| `DKA_TOOLS_PKG.put_debug_message` | 275 |
| `Fnd_Message.set_name` | 278 |
| `DKA_TOOLS_PKG.put_debug_message` | 281 |
| `DKA_TOOLS_PKG.put_debug_message` | 295 |
| `DKA_TOOLS_PKG.put_debug_message` | 308 |
| `DKA_TOOLS_PKG.put_debug_message` | 321 |
| `DKA_TOOLS_PKG.put_debug_message` | 334 |
| `DKA_TOOLS_PKG.put_debug_message` | 359 |
| `DKA_TOOLS_PKG.put_debug_message` | 375 |
| `DKA_TOOLS_PKG.put_debug_message` | 377 |
| `WF_ENGINE.abortProcess` | 389 |
| `WF_PURGE.items` | 392 |
| `DKA_TOOLS_PKG.put_debug_message` | 398 |
| `WF_ENGINE.abortProcess` | 407 |
| `WF_PURGE.items` | 410 |
| `DKA_TOOLS_PKG.put_debug_message` | 420 |
| `DKA_TOOLS_PKG.put_debug_message` | 445 |
| `DKA_TOOLS_PKG.put_debug_message` | 447 |
| `DKA_TOOLS_PKG.put_debug_message` | 453 |
| `DKA_TOOLS_PKG.put_outdebug_message` | 458 |
| `DKA_TOOLS_PKG.put_outdebug_message` | 462 |
| `DKA_TOOLS_PKG.put_outdebug_message` | 463 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

| Élément | Ligne source |
|---|---:|
| `@DKA_SPOOUVFERCOM.sql` | 12 |

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 390, 393, 408, 411, 451 |
| rollback | 461 |
| when_others | 460 |
| workflow | 389, 407 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOOUVFERCOM / DKA | `DKA_SPOOUVFERCOM` | dka/12.0.0/admin/import/DKA_SPOOUVFERCOM.prt:569 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
