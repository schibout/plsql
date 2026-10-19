# DKA_SAPVIR_MAIL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPVIR_MAIL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPVIR_MAIL_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2256 ; encodage : cp1252 (repli). SHA-256 : `80f7152cc122fad7125b44b62ec333f94ddfd15e66e0756fd01ba077be30d7c5`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 82 |
| `log_msg` | 96 |
| `init` | 118 |
| `envoi_mail_adress_client_abs` | 337 |
| `ENVOI_MAIL_ADRESS_CLIENT_ABS` | 758 |
| `envoi_mail_adress_four_abs` | 782 |
| `Envoi_mail_adress_four_abs` | 856 |
| `write_boundary` | 875 |
| `begin_attachment` | 893 |
| `end_attachment` | 936 |
| `envoi_mail_client` | 1079 |
| `ENVOI_MAIL_CLIENT` | 1378 |
| `envoi_mail` | 1418 |
| `SEND_MAIL_REF` | 1717 |
| `ENVOI_MAIL` | 1725 |
| `main` | 1752 |
| `MAIN` | 2246 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `v$database` | 141 |
| `fnd_flex_value_sets` | 245 |
| `fnd_flex_value_sets` | 280 |
| `fnd_flex_value_sets` | 451 |
| `dual` | 620 |
| `DKA_SAPVIR_ATTACH_TMP` | 1795 |
| `fnd_concurrent_requests` | 1836 |
| `AP_CHECKS_ALL` | 1897 |
| `ar_customers` | 1914 |
| `hr_all_organization_units` | 1928 |
| `AP_CHECKS_ALL` | 1944 |
| `ra_customer_trx_all` | 1959 |
| `AP_INVOICES_ALL` | 1963 |
| `hz_cust_accounts` | 1987 |
| `AP_CHECKS_ALL` | 2060 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 85 |
| `fnd_file.put_line` | 106 |
| `fnd_profile.value` | 135 |
| `Dka_Tools_Pkg.get_parameter` | 156 |
| `Dka_Tools_Pkg.get_parameter` | 174 |
| `Dka_Tools_Pkg.get_parameter` | 192 |
| `Dka_Tools_Pkg.get_parameter` | 199 |
| `Dka_Tools_Pkg.get_parameter` | 215 |
| `Dka_Tools_Pkg.get_parameter` | 233 |
| `Dka_Tools_Pkg.get_message` | 465 |
| `Dka_Tools_Pkg.get_message` | 472 |
| `Dka_Tools_Pkg.get_message` | 796 |
| `Dka_Tools_Pkg.get_message` | 803 |
| `Dka_Tools_Pkg.get_message` | 1120 |
| `Dka_Tools_Pkg.get_message` | 1124 |
| `Dka_Tools_Pkg.get_message` | 1459 |
| `Dka_Tools_Pkg.get_message` | 1463 |
| `Dka_Tools_Pkg.get_message` | 1644 |
| `Dka_Tools_Pkg.get_message` | 1650 |
| `DKA_SEND_MAIL_PKG.mail_test` | 1811 |
| `dka_tools_pkg.put_outdebug_message` | 1840 |
| `dka_tools_pkg.put_outdebug_message` | 1844 |
| `Dka_Tools_Pkg.get_parameter` | 2146 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 143, 270, 305, 317, 756, 854, 1253, 1377, 1593, 1707, 1724, 1839, 1994, 2016, 2091, 2164, 2194, 2218, 2245 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPVIR_MAIL / DKA | `DKA_SAPVIR_MAIL_PKG.main` | dka/12.0.0/admin/import/DKA_SAPVIR_MAIL.prt:459 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
