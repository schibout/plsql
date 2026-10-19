# DKA_SAPAUTOVIR_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPAUTOVIR_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPAUTOVIR_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 829 ; encodage : cp1252 (repli). SHA-256 : `fc6dd998c3232cec345c88969ca1944aaa68e3c99d7cd21845755db1a07150d8`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 56 |
| `log_msg` | 70 |
| `lance_trait_pdf` | 95 |
| `lance_trait_attach` | 185 |
| `lance_trait_mail` | 255 |
| `edition_output` | 349 |
| `EDITION_OUTPUT` | 625 |
| `main` | 641 |
| `MAIN` | 820 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_programs` | 112 |
| `DKA_SAPVIR_ATTACH_TMP` | 146 |
| `fnd_concurrent_programs` | 201 |
| `fnd_concurrent_programs` | 277 |
| `DKA_IEOAPSAT01_APIMP_LINE` | 364 |
| `DKA_IEOAPSAT01_APIMP_LINE` | 398 |
| `ra_customer_trx_all` | 425 |
| `AP_INVOICES_ALL` | 429 |
| `FND_CONCURRENT_PROGRAMS` | 453 |
| `v$database` | 473 |
| `fnd_application` | 478 |
| `fnd_conc_req_summary_v` | 484 |
| `FND_CONC_REQ_SUMMARY_V` | 592 |
| `FND_CONC_REQ_SUMMARY_V` | 608 |
| `DKA_IEOAPSAT01_APIMP_LINE` | 649 |
| `DKA_SAPVIR_ATTACH_TMP` | 696 |
| `FND_CONC_REQ_SUMMARY_V` | 748 |
| `FND_CONC_REQ_SUMMARY_V` | 766 |
| `FND_CONC_REQ_SUMMARY_V` | 786 |
| `FND_CONC_REQ_SUMMARY_V` | 798 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 46 |
| `fnd_file.put_line` | 59 |
| `fnd_file.put_line` | 80 |
| `fnd_request.submit_request` | 122 |
| `fnd_request.submit_request` | 211 |
| `dka_tools_pkg.get_request_set_params` | 289 |
| `fnd_request.submit_request` | 306 |
| `dka_tools_pkg.tab_request_params` | 311 |
| `fnd_profile.VALUE` | 479 |
| `fnd_profile.VALUE` | 496 |
| `fnd_profile.value` | 680 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 134, 219, 315 |
| when_others | 116, 165, 205, 236, 281, 332, 488, 623, 791, 802, 819 |
| suppression | 696 |
| soumission | 122, 211, 306 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPAUTOVIR_MAIL / DKA | `DKA_SAPAUTOVIR_PKG.main` | dka/12.0.0/admin/import/DKA_SAPAUTOVIR_MAIL.prt:404 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
