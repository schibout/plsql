# DKA_MAIL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_MAIL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_MAIL_PKG.pkb).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 684 ; encodage : cp1252 (repli). SHA-256 : `284fcdb71dbee9ff273fd5cd8e08c5d65eaf159789caa5184bbaf46e5304722e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 51 |
| `log_msg` | 65 |
| `init` | 86 |
| `INIT` | 114 |
| `write_boundary` | 125 |
| `begin_attachment` | 141 |
| `end_attachment` | 181 |
| `envoi_avec_fichier` | 201 |
| `envoi_mail` | 595 |
| `EDITION_OUTPUT_MAIL` | 663 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `all_directories` | 98 |
| `fnd_conc_req_outputs` | 222 |
| `dka.dka_mail_param` | 272 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 54 |
| `fnd_file.put_line` | 75 |
| `dka_tools_pkg.get_parameter` | 101 |
| `dka_tools_pkg.put_log_message` | 115 |
| `dka_tools_pkg.put_debug_message` | 573 |
| `fnd_concurrent.wait_for_request` | 624 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 113, 575, 674 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_MAIL / DKA | `dka_mail_pkg.envoi_mail` | dka/12.0.0/admin/import/DKA_MAIL.prt:458 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
