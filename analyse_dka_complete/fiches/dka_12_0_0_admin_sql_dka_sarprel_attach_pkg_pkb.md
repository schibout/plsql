# DKA_SARPREL_ATTACH_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARPREL_ATTACH_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARPREL_ATTACH_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1201 ; encodage : cp1252 (repli). SHA-256 : `4570e5950adb865c49cb3a9af2af7d77e0245d20c6d4c5508724bee4caaef1c2`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 47 |
| `log_msg` | 61 |
| `init` | 83 |
| `get_doc_avr` | 175 |
| `chargement_image` | 259 |
| `delete_image` | 336 |
| `create_attached_document_avr` | 371 |
| `update_attached_document_avr` | 511 |
| `SEND_MSG` | 564 |
| `envoi_mail_avec_client` | 704 |
| `envoi_mail_sans_client` | 793 |
| `main` | 921 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_document_categories` | 142 |
| `fnd_document_datatypes` | 151 |
| `fnd_attached_documents` | 185 |
| `fnd_documents_tl` | 212 |
| `fnd_documents` | 213 |
| `dual` | 288 |
| `fnd_lobs` | 290 |
| `fnd_attached_documents` | 390 |
| `DUAL` | 399 |
| `fnd_documents_tl` | 401 |
| `fnd_documents` | 424 |
| `DUAL` | 455 |
| `fnd_attached_documents` | 457 |
| `fnd_documents_tl` | 523 |
| `fnd_documents` | 530 |
| `ar_cash_receipts_all` | 737 |
| `fnd_flex_value_sets` | 817 |
| `dka_sarautoprelev_tmp` | 833 |
| `DKA_SARPREL_ATTACH_TMP` | 951 |
| `fnd_concurrent_requests` | 962 |
| `fnd_concurrent_requests` | 1000 |
| `ATTACHED` | 1046 |
| `dka_sarautoprelev_tmp` | 1090 |
| `iby_external_payers_all` | 1110 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 50 |
| `fnd_file.put_line` | 71 |
| `Dka_Tools_Pkg.get_parameter` | 104 |
| `Dka_Tools_Pkg.get_parameter` | 123 |
| `dka_Tools_Pkg.put_outdebug_message` | 482 |
| `fnd_file.put_line` | 590 |
| `fnd_file.put_line` | 605 |
| `fnd_file.put_line` | 610 |
| `fnd_file.put_line` | 644 |
| `Dka_Tools_Pkg.get_parameter` | 748 |
| `Dka_Tools_Pkg.get_parameter` | 847 |
| `fnd_file.put_line` | 858 |
| `fnd_file.put_line` | 867 |
| `fnd_file.put_line` | 870 |
| `fnd_file.put_line` | 1082 |
| `fnd_file.put` | 1136 |
| `fnd_file.put_line` | 1149 |
| `fnd_file.put_line` | 1161 |
| `Fnd_File.put_line` | 1165 |
| `Fnd_File.put_line` | 1187 |
| `Fnd_File.put_line` | 1190 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1079 |
| rollback | 324, 358, 498, 550 |
| when_others | 159, 227, 245, 317, 351, 490, 543, 668, 772, 900, 1116, 1191 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARPREL_ATTACH / DKA | `DKA_SARPREL_ATTACH_PKG.main` | dka/12.0.0/admin/import/DKA_SARPREL_ATTACH_F.prt:460 |
| DKA_SARPREL_ATTACH / DKA | `DKA_SARPREL_ATTACH_PKG.main` | dka/12.0.0/admin/import/DKA_SARPREL_ATTACH_F.prt:460 |
| DKA_SARPREL_ATTACH / DKA | `DKA_SARPREL_ATTACH_PKG.main` | dka/12.0.0/admin/import/DKA_SARPREL_ATTACH_US.prt:460 |
| DKA_SARPREL_ATTACH / DKA | `DKA_SARPREL_ATTACH_PKG.main` | dka/12.0.0/admin/import/DKA_SARPREL_ATTACH_US.prt:460 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
