# DKA_FUSPOCMDEXP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_FUSPOCMDEXP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_FUSPOCMDEXP_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1325 ; encodage : cp1252 (repli). SHA-256 : `cf1ceba82f88caf805472a3fb43922fd0d6bf98304a053ef7c5b15d90b6fc2ee`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Main` | 37 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `PO_HEADERS_ALL` | 80 |
| `po_line_locations_all` | 107 |
| `PO_DISTRIBUTIONS_ALL` | 118 |
| `HR_ORGANIZATION_UNITS` | 138 |
| `PO_HEADERS_ALL` | 221 |
| `po_line_locations_all` | 248 |
| `PO_DISTRIBUTIONS_ALL` | 260 |
| `HR_ORGANIZATION_UNITS` | 282 |
| `DKA_CONTRAT_SSTR` | 297 |
| `PO_HEADERS_ALL` | 389 |
| `PO_HEADERS_ALL` | 459 |
| `PO_LINE_LOCATIONS_ALL` | 471 |
| `PER_ALL_PEOPLE_F` | 500 |
| `PO_HEADERS_ALL` | 544 |
| `DKA_SPOFUSION_HEADERS_TMP` | 575 |
| `HR_ORGANIZATION_UNITS` | 581 |
| `HR_ORGANIZATION_UNITS` | 624 |
| `DKA_SPOFUSION_HEADERS_TMP` | 734 |
| `HR_ORGANIZATION_UNITS` | 737 |
| `DKA_SPOFUSION_LINES_TMP` | 751 |
| `HR_ORGANIZATION_UNITS` | 754 |
| `DKA_SPOFUSION_DISTRIBS_TMP` | 768 |
| `HR_ORGANIZATION_UNITS` | 771 |
| `DKA_SPOFUSION_HEADERS_TMP` | 829 |
| `DKA_SPOFUSION_LINES_TMP` | 1010 |
| `DKA_SPOFUSION_DISTRIBS_TMP` | 1214 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 666 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 667 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 668 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 669 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 670 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 671 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 674 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 675 |
| `Dka_Tools_Pkg.put_log_message` | 680 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 681 |
| `dka_Tools_Pkg.put_log_message` | 885 |
| `dka_tools_pkg.put_debug_message` | 902 |
| `dka_Tools_Pkg.put_log_message` | 1071 |
| `dka_tools_pkg.put_debug_message` | 1081 |
| `dka_Tools_Pkg.put_log_message` | 1256 |
| `dka_tools_pkg.put_debug_message` | 1263 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1275 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1277 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1279 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1281 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1284 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1285 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1286 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1287 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1288 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1291 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1294 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1295 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1296 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1297 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1314 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1315 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1316 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1317 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1318 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 879, 1065, 1251, 1298 |
| rollback | 1309 |
| when_others | 639, 883, 901, 1069, 1080, 1255, 1262, 1300 |
| suppression | 734, 751, 768 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_FUSPOCMDEXP / DKA | `DKA_FUSPOCMDEXP_PKG.Main` | dka/12.0.0/admin/import/DKA_FUSPOCMDEXP.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
