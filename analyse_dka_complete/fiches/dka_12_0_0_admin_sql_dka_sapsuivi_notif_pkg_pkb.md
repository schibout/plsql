# DKA_SAPSUIVI_NOTIF_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPSUIVI_NOTIF_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPSUIVI_NOTIF_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1423 ; encodage : cp1252 (repli). SHA-256 : `db14e2182e1fdd1c5eabc27f147f734fd112d71fabdf0bfcdfea6f734af79916`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `log_msg` | 68 |
| `out_msg` | 90 |
| `get_time` | 104 |
| `get_tl_code_blocage` | 116 |
| `get_infos_cde` | 162 |
| `get_infos_da` | 208 |
| `get_convert_html` | 260 |
| `denormalize_notification` | 290 |
| `denormalize_notification` | 350 |
| `init` | 364 |
| `INIT` | 526 |
| `envoi_mail` | 544 |
| `ENVOI_MAIL` | 716 |
| `envoi_all_mail` | 735 |
| `d` | 1145 |
| `d` | 1255 |
| `ENVOI_ALL_MAIL` | 1261 |
| `edition_output` | 1276 |
| `EDITION_OUTPUT` | 1285 |
| `main` | 1304 |
| `d` | 1365 |
| `d` | 1375 |
| `INIT` | 1402 |
| `ENVOI_ALL_MAIL` | 1406 |
| `EDITION_OUTPUT` | 1410 |
| `MAIN` | 1414 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ap_invoice_distributions_all` | 173 |
| `po_distributions_all` | 220 |
| `wf_notifications` | 296 |
| `wf_notifications` | 303 |
| `wf_notifications` | 755 |
| `wf_notifications` | 803 |
| `wf_notification_attributes` | 853 |
| `wf_notification_attributes` | 864 |
| `wf_notifications` | 867 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 78 |
| `fnd_file.put_line` | 93 |
| `wf_notification.Denormalize_Notification` | 337 |
| `Dka_Tools_Pkg.get_parameter` | 381 |
| `Dka_Tools_Pkg.get_parameter` | 392 |
| `Dka_Tools_Pkg.get_message` | 499 |
| `Dka_Tools_Pkg.get_message` | 500 |
| `Dka_Tools_Pkg.get_message` | 505 |
| `Dka_Tools_Pkg.get_message` | 506 |
| `Dka_Tools_Pkg.get_message` | 507 |
| `Dka_Tools_Pkg.get_message` | 508 |
| `Dka_Tools_Pkg.get_message` | 509 |
| `Dka_Tools_Pkg.get_message` | 513 |
| `Dka_Tools_Pkg.get_message` | 514 |
| `Dka_Tools_Pkg.get_message` | 612 |
| `Dka_Tools_Pkg.get_message` | 619 |
| `Dka_Tools_Pkg.get_message` | 624 |
| `Dka_Tools_Pkg.get_message` | 641 |
| `DKA_SEND_MAIL_PKG.mail_test` | 1324 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 148, 194, 246, 273, 349, 525, 711, 1161, 1260, 1283, 1413 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPSUIVI_NOTIF / DKA | `DKA_SAPSUIVI_NOTIF_PKG.main` | dka/12.0.0/admin/import/DKA_SAPSUIVI_NOTIF.prt:521 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
