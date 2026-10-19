# DKA_IAPCTRFLUX_IVALUA_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IAPCTRFLUX_IVALUA_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IAPCTRFLUX_IVALUA_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 551 ; encodage : cp1252 (repli). SHA-256 : `477f1b63f031314509a75a26e137c16cc32428613eb44ebbad9128c330d82544`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `format_date` | 48 |
| `main` | 60 |
| `insert_dka_iapctrflux_ivalua` | 456 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_organisation_v` | 85 |
| `dka_iapfacxgs_interface` | 89 |
| `DKA_STRANSCO_LINES` | 109 |
| `AP_INVOICES_INTERFACE` | 115 |
| `AP_INVOICES_ALL` | 125 |
| `dka.dka_iapctrflux_ivalua` | 162 |
| `dka_stransco_lines` | 164 |
| `DKA_IAPFACXGS_INTERFACE` | 193 |
| `dka_stransco_lines` | 195 |
| `DKA_STRANSCO_LINES` | 215 |
| `AP_INVOICES_INTERFACE` | 220 |
| `dka_stransco_lines` | 225 |
| `AP_INVOICES_ALL` | 236 |
| `dka_stransco_lines` | 241 |
| `DKA.DKA_IAPCTRFLUX_IVALUA` | 284 |
| `DKA_STRANSCO_LINES` | 288 |
| `DKA_IAPFACXGS_INTERFACE` | 317 |
| `dka.dka_iapctrflux_ivalua_tmp` | 472 |
| `dka.dka_iapctrflux_ivalua` | 480 |
| `dka_parameters` | 488 |
| `dka.dka_iapctrflux_ivalua` | 501 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_Tools_Pkg.add_error_stack` | 53 |
| `dka_Tools_Pkg.put_outdebug_message` | 148 |
| `fnd_message.get_string` | 148 |
| `dka_Tools_Pkg.put_outdebug_message` | 151 |
| `dka_Tools_Pkg.put_outdebug_message` | 154 |
| `dka_Tools_Pkg.put_outdebug_message` | 181 |
| `fnd_message.get_string` | 181 |
| `dka_Tools_Pkg.put_outdebug_message` | 185 |
| `fnd_message.get_string` | 185 |
| `dka_Tools_Pkg.put_outdebug_message` | 204 |
| `fnd_message.get_string` | 204 |
| `dka_Tools_Pkg.put_outdebug_message` | 259 |
| `fnd_message.get_string` | 259 |
| `dka_Tools_Pkg.put_outdebug_message` | 264 |
| `fnd_message.get_string` | 264 |
| `dka_Tools_Pkg.put_outdebug_message` | 269 |
| `dka_Tools_Pkg.put_outdebug_message` | 276 |
| `fnd_message.get_string` | 276 |
| `dka_Tools_Pkg.put_outdebug_message` | 303 |
| `fnd_message.get_string` | 303 |
| `dka_Tools_Pkg.put_outdebug_message` | 308 |
| `fnd_message.get_string` | 308 |
| `dka_Tools_Pkg.put_outdebug_message` | 327 |
| `fnd_message.get_string` | 327 |
| `dka_Tools_Pkg.put_outdebug_message` | 332 |
| `fnd_message.get_string` | 333 |
| `fnd_message.get_string` | 336 |
| `fnd_message.get_string` | 339 |
| `dka_Tools_Pkg.put_outdebug_message` | 350 |
| `dka_Tools_Pkg.put_outdebug_message` | 365 |
| `fnd_message.get_string` | 365 |
| `dka_Tools_Pkg.put_outdebug_message` | 397 |
| `dka_Tools_Pkg.put_outdebug_message` | 402 |
| `fnd_message.get_string` | 402 |
| `dka_Tools_Pkg.put_outdebug_message` | 412 |
| `fnd_message.get_string` | 412 |
| `dka_Tools_Pkg.put_outdebug_message` | 422 |
| `fnd_message.get_string` | 422 |
| `dka_Tools_Pkg.put_log_message` | 438 |
| `dka_Tools_Pkg.put_log_message` | 442 |
| `dka_Tools_Pkg.print_error_stack` | 443 |
| `dka_Tools_Pkg.add_error_stack` | 446 |
| `dka_Tools_Pkg.put_log_message` | 448 |
| `dka_Tools_Pkg.print_error_stack` | 449 |
| `dka_Tools_Pkg.put_log_message` | 541 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 544 |
| when_others | 52, 444, 539 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IAPCTRFLUX_IVALUA / DKA | `DKA_IAPCTRFLUX_IVALUA_PKG.main` | dka/12.0.0/admin/import/DKA_IAPCTRFLUX_IVALUA_F_PRG.ldt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
