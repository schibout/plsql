# DKA_SAREXTENCAISSCLIENT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAREXTENCAISSCLIENT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAREXTENCAISSCLIENT_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1966 ; encodage : cp1252 (repli). SHA-256 : `ce57715e341f6842af22d9372d9ffa1ab02bda43c39516e38e3018142ff5d62d`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 46 |
| `output_end` | 79 |
| `Extraction_encaissements_clients` | 111 |
| `main` | 1884 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ar_cash_receipts_all` | 198 |
| `fnd_flex_value_sets` | 214 |
| `DKA_STRANSCO_LINES` | 234 |
| `AR_RECEIPT_METHODS` | 263 |
| `AR_ADJUSTMENTS_all` | 334 |
| `rb_lines` | 353 |
| `rb_lines` | 360 |
| `ar_cash_receipts_all` | 456 |
| `fnd_flex_value_sets` | 472 |
| `DKA_STRANSCO_LINES` | 492 |
| `AR_RECEIPT_METHODS` | 521 |
| `AR_ADJUSTMENTS_all` | 592 |
| `rb_lines` | 611 |
| `rb_lines` | 618 |
| `rb_lines` | 656 |
| `rb_lines` | 663 |
| `rb_lines` | 676 |
| `rb_lines` | 683 |
| `ar_cash_receipts_all` | 734 |
| `fnd_flex_value_sets` | 751 |
| `DKA_STRANSCO_LINES` | 771 |
| `AR_RECEIPT_METHODS` | 800 |
| `AR_ADJUSTMENTS_all` | 871 |
| `ar_cash_receipts_all` | 1022 |
| `fnd_flex_value_sets` | 1040 |
| `ar_receivable_applications_all` | 1070 |
| `ar_receivable_applications_all` | 1087 |
| `AR_CASH_RECEIPTS_ALL` | 1122 |
| `ar_receivable_applications_all` | 1139 |
| `ar_receivable_applications_all` | 1153 |
| `AR_RECEIPT_METHODS` | 1168 |
| `AR_ADJUSTMENTS_all` | 1247 |
| `ar_cash_receipt_history_all` | 1258 |
| `ar_cash_receipts_all` | 1381 |
| `fnd_flex_value_sets` | 1400 |
| `ar_receivable_applications_all` | 1430 |
| `ar_receivable_applications_all` | 1447 |
| `AR_CASH_RECEIPTS_ALL` | 1482 |
| `ar_receivable_applications_all` | 1499 |
| `ar_receivable_applications_all` | 1513 |
| `AR_RECEIPT_METHODS` | 1528 |
| `AR_ADJUSTMENTS_all` | 1607 |
| `ar_cash_receipt_history_all` | 1618 |
| `dba_directories` | 1678 |
| `rb_lines` | 1736 |
| `rb_lines` | 1754 |
| `dka_parameters` | 1851 |
| `dka_parameters` | 1901 |
| `DKA_RB_LINES` | 1909 |
| `DKA_RB_LINES` | 1912 |
| `rb_lines` | 1913 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 56 |
| `Fnd_File.put_line` | 57 |
| `Fnd_File.put_line` | 58 |
| `Fnd_File.put_line` | 59 |
| `Fnd_File.put_line` | 60 |
| `Fnd_File.put_line` | 86 |
| `Fnd_File.put_line` | 87 |
| `Fnd_File.put_line` | 88 |
| `dka_tools_pkg.put_debug_message` | 1659 |
| `dka_tools_pkg.put_debug_message` | 1665 |
| `dka_tools_pkg.put_log_message` | 1686 |
| `dka_tools_pkg.put_log_message` | 1691 |
| `dka_tools_pkg.put_log_message` | 1703 |
| `dka_tools_pkg.put_debug_message` | 1849 |
| `dka_tools_pkg.put_debug_message` | 1857 |
| `Fnd_File.put_line` | 1931 |
| `Fnd_File.put_line` | 1936 |
| `Fnd_File.put_line` | 1937 |
| `Fnd_File.put_line` | 1938 |
| `Fnd_File.put_line` | 1939 |
| `Fnd_File.put_line` | 1949 |
| `Fnd_File.put_line` | 1950 |
| `Fnd_File.put_line` | 1951 |
| `Fnd_File.put_line` | 1952 |
| `Fnd_File.put_line` | 1953 |
| `Fnd_File.put_line` | 1958 |
| `Fnd_File.put_line` | 1959 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1856, 1910, 1920 |
| when_others | 1779, 1861, 1954 |
| suppression | 1909 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
