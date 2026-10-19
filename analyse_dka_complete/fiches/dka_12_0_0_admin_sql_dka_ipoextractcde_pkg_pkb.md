# DKA_IPOEXTRACTCDE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IPOEXTRACTCDE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IPOEXTRACTCDE_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 357 ; encodage : cp1252 (repli). SHA-256 : `c1cd0f825589d019796d9eee6887ebf6b6ad32525c070d297ae216247d5f7ccd`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `write_file` | 41 |
| `main` | 254 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_IPOEXTRACTCDE_INTERFACE` | 85 |
| `dba_directories` | 95 |
| `DKA_IPOEXTRACTCDE_INTERFACE` | 278 |
| `po_headers_all` | 294 |
| `po_line_locations_all` | 302 |
| `po_distributions_all` | 315 |
| `po_headers_all` | 325 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_message.set_name` | 87 |
| `fnd_message.get` | 89 |
| `dka_tools_pkg.put_log_message` | 100 |
| `dka_tools_pkg.put_log_message` | 123 |
| `dka_tools_pkg.put_log_message` | 125 |
| `dka_tools_pkg.put_log_message` | 126 |
| `dka_tools_pkg.put_log_message` | 134 |
| `dka_tools_pkg.put_log_message` | 142 |
| `dka_tools_pkg.put_log_message` | 150 |
| `dka_tools_pkg.put_log_message` | 158 |
| `dka_tools_pkg.put_log_message` | 166 |
| `dka_tools_pkg.put_log_message` | 174 |
| `dka_tools_pkg.put_log_message` | 182 |
| `dka_tools_pkg.put_log_message` | 190 |
| `dka_tools_pkg.put_log_message` | 198 |
| `dka_tools_pkg.put_log_message` | 206 |
| `dka_tools_pkg.put_log_message` | 214 |
| `dka_tools_pkg.put_log_message` | 222 |
| `dka_tools_pkg.put_log_message` | 230 |
| `dka_tools_pkg.put_log_message` | 231 |
| `dka_tools_pkg.put_log_message` | 268 |
| `dka_tools_pkg.put_log_message` | 270 |
| `dka_tools_pkg.put_log_message` | 274 |
| `dka_tools_pkg.put_log_message` | 334 |
| `dka_tools_pkg.put_log_message` | 343 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 124, 125, 339 |
| rollback | 333, 347 |
| when_others | 226, 332, 346 |
| truncate | 272 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IPOEXTRACTCDE / DKA | `DKA_IPOEXTRACTCDE_PKG.MAIN` | dka/12.0.0/admin/import/DKA_IPOEXTRACTCDE.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
