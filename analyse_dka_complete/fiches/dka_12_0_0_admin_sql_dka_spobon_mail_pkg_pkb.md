# DKA_SPOBON_MAIL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOBON_MAIL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOBON_MAIL_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 921 ; encodage : cp1252 (repli). SHA-256 : `876024b47c762beaa7180a6f41dc970b79d821f01e4109f55333cd0ad773531e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 61 |
| `get_po_header_id` | 194 |
| `get_po_org_name` | 220 |
| `get_message` | 249 |
| `GET_MESSAGE` | 364 |
| `get_address_mail` | 379 |
| `GET_ADDRESS_MAIL` | 454 |
| `write_boundary` | 468 |
| `begin_attachment` | 488 |
| `end_attachment` | 518 |
| `envoi_mail` | 542 |
| `ENVOI_MAIL` | 685 |
| `main` | 702 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `v$database` | 90 |
| `DBA_DIRECTORIES` | 124 |
| `po_headers_all` | 203 |
| `po_headers_all` | 230 |
| `po_headers_all` | 270 |
| `po_headers_all` | 299 |
| `fnd_user` | 400 |
| `per_people_f` | 421 |
| `fnd_concurrent_requests` | 761 |
| `po_headers` | 788 |
| `po_headers` | 827 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 73 |
| `Dka_Tools_Pkg.put_debug_message` | 98 |
| `Dka_Tools_Pkg.get_parameter` | 135 |
| `Dka_Tools_Pkg.put_debug_message` | 138 |
| `Dka_Tools_Pkg.get_parameter` | 145 |
| `Dka_Tools_Pkg.put_debug_message` | 148 |
| `Dka_Tools_Pkg.get_parameter` | 155 |
| `Dka_Tools_Pkg.put_debug_message` | 158 |
| `Dka_Tools_Pkg.get_parameter` | 165 |
| `Dka_Tools_Pkg.put_debug_message` | 168 |
| `dka_tools_pkg.put_debug_message` | 174 |
| `dka_tools_pkg.put_debug_message` | 179 |
| `Dka_Tools_Pkg.get_message` | 345 |
| `Dka_Tools_Pkg.get_message` | 350 |
| `Dka_Tools_Pkg.put_outdebug_message` | 366 |
| `DKA_SEND_MAIL_PKG.mail_test` | 447 |
| `Dka_Tools_Pkg.put_outdebug_message` | 448 |
| `Dka_Tools_Pkg.put_outdebug_message` | 456 |
| `Dka_Tools_Pkg.put_outdebug_message` | 574 |
| `Dka_Tools_Pkg.put_outdebug_message` | 584 |
| `Dka_Tools_Pkg.put_outdebug_message` | 674 |
| `Dka_Tools_Pkg.put_outdebug_message` | 678 |
| `Dka_Tools_Pkg.put_outdebug_message` | 687 |
| `dka_tools_pkg.put_debug_message` | 731 |
| `Dka_Tools_Pkg.put_debug_message` | 736 |
| `Dka_Tools_Pkg.put_outdebug_message` | 744 |
| `Dka_Tools_Pkg.put_outdebug_message` | 748 |
| `Dka_Tools_Pkg.put_outdebug_message` | 749 |
| `dka_tools_pkg.put_outdebug_message` | 773 |
| `dka_tools_pkg.put_outdebug_message` | 774 |
| `Dka_Tools_Pkg.put_outdebug_message` | 778 |
| `Dka_Tools_Pkg.put_outdebug_message` | 779 |
| `Dka_Tools_Pkg.put_outdebug_message` | 780 |
| `Dka_Tools_Pkg.put_outdebug_message` | 781 |
| `Dka_Tools_Pkg.put_outdebug_message` | 782 |
| `Dka_Tools_Pkg.put_outdebug_message` | 803 |
| `Dka_Tools_Pkg.put_outdebug_message` | 806 |
| `Dka_Tools_Pkg.put_outdebug_message` | 808 |
| `Dka_Tools_Pkg.put_outdebug_message` | 809 |
| `Dka_Tools_Pkg.put_outdebug_message` | 810 |
| `Dka_Tools_Pkg.put_outdebug_message` | 852 |
| `Dka_Tools_Pkg.put_outdebug_message` | 853 |
| `Dka_Tools_Pkg.put_outdebug_message` | 854 |
| `Dka_Tools_Pkg.put_outdebug_message` | 864 |
| `Dka_Tools_Pkg.put_outdebug_message` | 867 |
| `Dka_Tools_Pkg.put_outdebug_message` | 875 |
| `Dka_Tools_Pkg.put_outdebug_message` | 882 |
| `Dka_Tools_Pkg.put_outdebug_message` | 886 |
| `Dka_Tools_Pkg.put_outdebug_message` | 892 |
| `Dka_Tools_Pkg.put_outdebug_message` | 894 |
| `Dka_Tools_Pkg.put_outdebug_message` | 904 |
| `Dka_Tools_Pkg.put_outdebug_message` | 905 |
| `dka_tools_pkg.put_debug_message` | 907 |
| `Dka_Tools_Pkg.put_outdebug_message` | 913 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 92, 128, 177, 179, 363, 436, 453, 684, 772, 847 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOBON_DUPLI_MAIL / DKA | `dka_spobon_mail_pkg.main` | dka/12.0.0/admin/import/DKA_SPOBON_DUPLI_MAIL_F.prt:458 |
| DKA_SPOBON_DUPLI_MAIL / DKA | `dka_spobon_mail_pkg.main` | dka/12.0.0/admin/import/DKA_SPOBON_DUPLI_MAIL_F.prt:458 |
| DKA_SPOBON_DUPLI_MAIL / DKA | `dka_spobon_mail_pkg.main` | dka/12.0.0/admin/import/DKA_SPOBON_DUPLI_MAIL_US.prt:458 |
| DKA_SPOBON_DUPLI_MAIL / DKA | `dka_spobon_mail_pkg.main` | dka/12.0.0/admin/import/DKA_SPOBON_DUPLI_MAIL_US.prt:458 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
