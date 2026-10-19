# DKA_SPOCHARGCATLG_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOCHARGCATLG_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOCHARGCATLG_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1057 ; encodage : cp1252 (repli). SHA-256 : `887b19ea964176bc8653583ec5c38dd0df23d26a5c414bfa8a94250de19efd71`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `INSERT_MESSAGE` | 55 |
| `EDIT_REPORT` | 121 |
| `duplicate_orders` | 251 |
| `duplicate_sites` | 610 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_SPOCHARGCATLG_TMP` | 69 |
| `DKA_SPOCHARGCATLG_TMP` | 133 |
| `fnd_concurrent_programs` | 152 |
| `PO_HEADERS_ALL` | 170 |
| `PO_VENDOR_SITES_ALL` | 262 |
| `PO_HEADERS_ALL` | 266 |
| `DKA_SPOCHARGCATLG_TMP` | 302 |
| `PO_HEADERS_ALL` | 311 |
| `PO_HEADERS_ALL` | 322 |
| `HR_OPERATING_UNITS` | 331 |
| `PO_GA_ORG_ASSIGNMENTS` | 350 |
| `PO_GA_ORG_ASSIGNMENTS` | 365 |
| `PO_GA_ORG_ASSIGNMENTS` | 413 |
| `PO_GA_ORG_ASSIGNMENTS` | 436 |
| `PO_GA_ORG_ASSIGNMENTS` | 465 |
| `PO_HEADERS_ALL` | 518 |
| `dual` | 536 |
| `PO_VENDOR_SITES_ALL` | 637 |
| `PO_VENDOR_SITES_ALL` | 649 |
| `PO_GA_ORG_ASSIGNMENTS` | 655 |
| `PO_HEADERS_ALL` | 666 |
| `PO_HEADERS_ALL` | 684 |
| `DKA_SPOCHARGCATLG_TMP` | 731 |
| `DKA_PARAMETERS` | 756 |
| `PO_GA_ORG_ASSIGNMENTS` | 775 |
| `PO_GA_ORG_ASSIGNMENTS` | 790 |
| `PO_GA_ORG_ASSIGNMENTS` | 817 |
| `PO_GA_ORG_ASSIGNMENTS` | 835 |
| `PO_GA_ORG_ASSIGNMENTS` | 919 |
| `PO_HEADERS_ALL` | 975 |
| `dual` | 993 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 177 |
| `Fnd_File.put_line` | 180 |
| `Fnd_File.put_line` | 182 |
| `Fnd_File.put_line` | 184 |
| `Fnd_File.put_line` | 189 |
| `Fnd_File.put_line` | 191 |
| `Fnd_File.put_line` | 192 |
| `Fnd_File.put_line` | 194 |
| `Fnd_File.put_line` | 195 |
| `Fnd_File.put_line` | 198 |
| `Fnd_File.put_line` | 200 |
| `Fnd_File.put_line` | 205 |
| `Fnd_File.put_line` | 208 |
| `Fnd_File.put_line` | 210 |
| `Fnd_File.put_line` | 211 |
| `Fnd_File.put_line` | 214 |
| `Fnd_File.put_line` | 216 |
| `Fnd_File.put_line` | 221 |
| `dka_Tools_Pkg.put_log_message` | 301 |
| `dka_Tools_Pkg.put_log_message` | 303 |
| `dka_Tools_Pkg.put_log_message` | 306 |
| `dka_Tools_Pkg.put_log_message` | 517 |
| `dka_Tools_Pkg.put_log_message` | 529 |
| `po_reqapproval_init1.start_wf_process` | 540 |
| `dka_Tools_Pkg.put_log_message` | 573 |
| `dka_Tools_Pkg.put_log_message` | 577 |
| `dka_Tools_Pkg.put_log_message` | 730 |
| `dka_Tools_Pkg.put_log_message` | 732 |
| `dka_Tools_Pkg.put_log_message` | 734 |
| `Dka_Tools_Pkg.get_parameter` | 736 |
| `dka_Tools_Pkg.put_log_message` | 743 |
| `dka_Tools_Pkg.put_log_message` | 744 |
| `dka_Tools_Pkg.put_log_message` | 752 |
| `dka_Tools_Pkg.put_log_message` | 755 |
| `dka_Tools_Pkg.put_log_message` | 762 |
| `dka_Tools_Pkg.put_log_message` | 912 |
| `dka_Tools_Pkg.put_log_message` | 974 |
| `dka_Tools_Pkg.put_log_message` | 986 |
| `po_reqapproval_init1.start_wf_process` | 997 |
| `dka_Tools_Pkg.put_log_message` | 1030 |
| `dka_Tools_Pkg.put_log_message` | 1035 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 97, 160, 226, 319, 360, 446, 588, 800, 1046 |
| suppression | 302, 731 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPODUPLCOG / DKA | `DKA_SPOCHARGCATLG_PKG.duplicate_orders` | dka/12.0.0/admin/import/DKA_SPODUPLCOG.prt:605 |
| DKA_SPODUPSITECOG / DKA | `DKA_SPOCHARGCATLG_PKG.duplicate_sites` | dka/12.0.0/admin/import/DKA_SPODUPSITECOG.prt:421 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
