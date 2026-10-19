# DKA_SPORES_CONTRAT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPORES_CONTRAT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPORES_CONTRAT_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1669 ; encodage : cp1252 (repli). SHA-256 : `7942a1d3e317ffb3b63ebedafba81b2b7d88fb7eee18821778a4b650f5b3466f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `log_msg` | 70 |
| `out_msg` | 92 |
| `get_time` | 106 |
| `init` | 120 |
| `INIT` | 177 |
| `maj_po` | 193 |
| `MAJ_PO` | 232 |
| `maj_po_fin` | 248 |
| `MAJ_PO_FIN` | 264 |
| `maj_flag_avert` | 280 |
| `MAJ_FLAG_AVERT` | 291 |
| `get_message` | 307 |
| `GET_MESSAGE` | 356 |
| `get_message_fin` | 373 |
| `GET_MESSAGE` | 433 |
| `envoi_mail` | 452 |
| `ENVOI_MAIL` | 508 |
| `envoi_notif` | 526 |
| `ENVOI_NOTIF` | 594 |
| `check_contrat_avert` | 612 |
| `de` | 701 |
| `d` | 709 |
| `CHECK_CONTRAT_AVERT` | 743 |
| `check_contrat_max_renouv` | 762 |
| `de` | 851 |
| `d` | 859 |
| `CHECK_CONTRAT_AVERT` | 893 |
| `check_contrat_nmax_renouv` | 913 |
| `de` | 1001 |
| `d` | 1009 |
| `CHECK_CONTRAT_AVERT` | 1043 |
| `check_contrat` | 1061 |
| `d` | 1148 |
| `d` | 1219 |
| `de` | 1235 |
| `d` | 1243 |
| `CHECK_CONTRAT` | 1269 |
| `check_contrat_fin` | 1287 |
| `de` | 1380 |
| `d` | 1388 |
| `CHECK_CONTRAT` | 1414 |
| `edition_output` | 1429 |
| `EDITION_OUTPUT` | 1444 |
| `main` | 1461 |
| `INIT` | 1632 |
| `CHECK_CONTRAT_AVERT` | 1636 |
| `CHECK_CONTRAT_MAX_RENOUV` | 1640 |
| `CHECK_CONTRAT_NMAX_RENOUV` | 1644 |
| `CHECK_CONTRAT` | 1648 |
| `EDITION_OUTPUT` | 1652 |
| `CHECK_CONTRAT_FIN` | 1657 |
| `MAIN` | 1661 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `PO_HEADERS_ALL` | 198 |
| `DKA_CONTRAT_SSTR` | 212 |
| `DKA_CONTRAT_SSTR_IMPUTATION` | 224 |
| `PO_HEADERS_ALL` | 253 |
| `DKA_CONTRAT_SSTR` | 285 |
| `po_headers_all` | 324 |
| `po_headers_all` | 390 |
| `nvl` | 467 |
| `fnd_user` | 469 |
| `dual` | 542 |
| `fnd_user` | 555 |
| `po_headers` | 629 |
| `po_headers` | 779 |
| `po_headers` | 930 |
| `po_headers` | 1077 |
| `po_headers_archive_all` | 1123 |
| `po_headers_all` | 1134 |
| `po_headers_archive_all` | 1140 |
| `po_headers` | 1304 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 80 |
| `fnd_file.put_line` | 95 |
| `Dka_Tools_Pkg.get_parameter` | 132 |
| `Dka_Tools_Pkg.get_parameter` | 147 |
| `Dka_Tools_Pkg.get_parameter` | 158 |
| `Dka_Tools_Pkg.get_message` | 330 |
| `Dka_Tools_Pkg.get_message` | 333 |
| `Dka_Tools_Pkg.get_message` | 342 |
| `Dka_Tools_Pkg.get_message` | 345 |
| `Dka_Tools_Pkg.get_message` | 396 |
| `Dka_Tools_Pkg.get_message` | 399 |
| `Dka_Tools_Pkg.get_message` | 409 |
| `Dka_Tools_Pkg.get_message` | 412 |
| `Dka_Tools_Pkg.get_message` | 420 |
| `Dka_Tools_Pkg.get_message` | 423 |
| `wf_engine.CreateProcess` | 545 |
| `wf_engine.SetItemAttrText` | 559 |
| `wf_engine.SetItemAttrNumber` | 566 |
| `wf_engine.SetItemAttrText` | 573 |
| `wf_engine.SetItemAttrText` | 580 |
| `wf_engine.StartProcess` | 586 |
| `PO_DOCUMENT_ARCHIVE_PVT.archive_po` | 1158 |
| `DKA_SEND_MAIL_PKG.mail_test` | 1491 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 697, 847, 997, 1215, 1368 |
| rollback | 707, 715, 723, 730, 857, 865, 873, 880, 1007, 1015, 1023, 1030, 1225, 1233, 1241, 1249, 1256, 1378, 1386, 1394, 1401 |
| when_others | 176, 231, 263, 290, 355, 432, 507, 593, 724, 742, 874, 892, 1024, 1042, 1147, 1250, 1268, 1395, 1413, 1442, 1660 |
| workflow | 545, 559, 566, 573, 580, 586 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPORES_CONTRAT / DKA | `DKA_SPORES_CONTRAT_PKG.main` | dka/12.0.0/admin/import/DKA_SPORES_CONTRAT.prt:459 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
