# DKA_IAPFAC_IVALUA_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IAPFAC_IVALUA_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IAPFAC_IVALUA_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1902 ; encodage : utf-8. SHA-256 : `80cec68aec23282bf3a4772df5a782e91cfef43731f586c57e19a34888f9f6cb`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `writeout` | 129 |
| `sortie_traitement` | 156 |
| `entete_de_sortie` | 181 |
| `fin_de_sortie` | 204 |
| `MAJ_DATE_LANCEMENT` | 228 |
| `purge_tables` | 330 |
| `generate_files` | 347 |
| `checkFileExistOrNot` | 1298 |
| `dka_retrieve_lob_to_file` | 1322 |
| `EXPORT_IMG` | 1417 |
| `LANCE_EXPORT_IMG` | 1528 |
| `log_supervision` | 1651 |
| `UPDATE_ATTACH_DOC` | 1784 |
| `MAIN` | 1824 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_PARAMETERS` | 234 |
| `DKA_IAPFAC_IVALUA` | 332 |
| `dka_iapfac_ivalua_img_maj` | 336 |
| `ap_invoices_all` | 431 |
| `po_headers_all` | 464 |
| `ap_holds_all` | 483 |
| `ap_invoice_lines_all` | 487 |
| `dka_iapfac_ivalua_img_maj` | 498 |
| `ap_invoices_all` | 570 |
| `ap_holds_all` | 596 |
| `ap_holds_all` | 605 |
| `ap_invoice_lines_all` | 609 |
| `dka_iapfac_ivalua_img_maj` | 621 |
| `ap_invoice_lines_all` | 647 |
| `ap_holds_all` | 697 |
| `ap_holds_all` | 719 |
| `fnd_flex_value_sets` | 728 |
| `AP_INVOICES_all` | 767 |
| `AP_INVOICES_ALL` | 804 |
| `dba_directories` | 857 |
| `dka_iapfac_ivalua_img_maj` | 963 |
| `fnd_attached_documents` | 968 |
| `fnd_documents_tl` | 989 |
| `ap_payment_schedules_all` | 1021 |
| `DKA_IAPFAC_IVALUA` | 1074 |
| `fnd_lobs` | 1099 |
| `fnd_documents_tl` | 1104 |
| `fnd_documents` | 1108 |
| `ap_invoice_distributions_all` | 1122 |
| `fnd_documents` | 1429 |
| `dual` | 1463 |
| `all_directories` | 1467 |
| `fnd_attached_documents` | 1490 |
| `DKA_IAPFAC_IVALUA` | 1662 |
| `fnd_documents` | 1688 |
| `fnd_documents` | 1788 |
| `fnd_attached_documents` | 1808 |
| `DKA_PARAMETERS` | 1840 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 95 |
| `FND_FILE.PUT_LINE` | 134 |
| `Fnd_File.put_line` | 140 |
| `Fnd_File.put_line` | 142 |
| `Fnd_File.put_line` | 143 |
| `Fnd_File.put_line` | 144 |
| `Fnd_File.put_line` | 145 |
| `Fnd_File.put_line` | 146 |
| `AP_INVOICES_PKG.GET_APPROVAL_STATUS` | 390 |
| `AP_INVOICES_PKG.GET_APPROVAL_STATUS` | 528 |
| `DKA_TOOLS_PKG.put_log_message` | 897 |
| `DKA_TOOLS_PKG.put_log_message` | 961 |
| `DKA_TOOLS_PKG.put_log_message` | 976 |
| `DKA_TOOLS_PKG.put_log_message` | 979 |
| `DKA_TOOLS_PKG.put_log_message` | 1229 |
| `DKA_TOOLS_PKG.put_log_message` | 1232 |
| `fnd_file.put_line` | 1240 |
| `fnd_request.submit_request` | 1241 |
| `DKA_TOOLS_PKG.put_log_message` | 1254 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 1255 |
| `DKA_TOOLS_PKG.put_log_message` | 1267 |
| `DKA_TOOLS_PKG.put_log_message` | 1272 |
| `DKA_TOOLS_PKG.put_log_message` | 1276 |
| `Fnd_File.put_line` | 1277 |
| `DKA_TOOLS_PKG.put_log_message` | 1282 |
| `Fnd_File.put_line` | 1555 |
| `Fnd_File.put_line` | 1558 |
| `FND_REQUEST.submit_request` | 1560 |
| `DKA_TOOLS_PKG.put_log_message` | 1572 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 1573 |
| `DKA_TOOLS_PKG.put_log_message` | 1586 |
| `DKA_TOOLS_PKG.put_log_message` | 1591 |
| `DKA_TOOLS_PKG.put_log_message` | 1596 |
| `DKA_TOOLS_PKG.put_log_message` | 1634 |
| `DKA_TOOLS_PKG.put_log_message` | 1835 |
| `DKA_TOOLS_PKG.put_log_message` | 1850 |
| `DKA_TOOLS_PKG.put_log_message` | 1854 |
| `DKA_TOOLS_PKG.put_log_message` | 1862 |
| `DKA_TOOLS_PKG.put_log_message` | 1874 |
| `DKA_TOOLS_PKG.put_log_message` | 1880 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_SLAUNCHER` | 1241 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 333, 337, 1113, 1250, 1517, 1569, 1639 |
| when_others | 137, 1311, 1378, 1844 |
| suppression | 332, 336 |
| soumission | 1241, 1560 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IAPFAC_IVALUA / DKA | `DKA_IAPFAC_IVALUA_PKG.MAIN` | dka/12.0.0/admin/import/DKA_IAPFAC_IVALUA_PRG.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
