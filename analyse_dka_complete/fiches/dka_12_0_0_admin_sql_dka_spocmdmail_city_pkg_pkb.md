# DKA_SPOCMDMAIL_CITY_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOCMDMAIL_CITY_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOCMDMAIL_CITY_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1079 ; encodage : cp1252 (repli). SHA-256 : `4d6a093d1f6bce191fa8a860ef82166ca673b46ad2e1c3f307e9ace65ac989a2`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 97 |
| `output_end` | 151 |
| `out_msg` | 171 |
| `log_msg` | 186 |
| `check_value_set` | 203 |
| `init` | 255 |
| `write_boundary` | 660 |
| `begin_attachment` | 676 |
| `end_attachment` | 717 |
| `SEND_MSG` | 738 |
| `main` | 896 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_programs` | 112 |
| `fnd_flex_value_sets` | 211 |
| `fnd_flex_values` | 212 |
| `fnd_flex_value_sets` | 297 |
| `ap_invoices_all` | 339 |
| `PA_PROJECTS_ALL` | 445 |
| `PA_TASKS` | 457 |
| `PO_HEADERS_ALL` | 485 |
| `PO_HEADERS_ALL` | 508 |
| `PO_HEADERS_ALL` | 521 |
| `PO_HEADERS_ALL` | 554 |
| `po_action_history` | 570 |
| `fnd_flex_values_vl` | 920 |
| `fnd_flex_values_vl` | 929 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 45 |
| `fnd_profile.value` | 47 |
| `fnd_profile.value` | 48 |
| `Fnd_File.put_line` | 127 |
| `Fnd_File.put_line` | 128 |
| `Fnd_File.put_line` | 129 |
| `Fnd_File.put_line` | 130 |
| `Fnd_File.put_line` | 131 |
| `Fnd_File.put_line` | 158 |
| `Fnd_File.put_line` | 159 |
| `Fnd_File.put_line` | 160 |
| `fnd_file.put_line` | 174 |
| `fnd_file.put_line` | 196 |
| `Fnd_File.put_line` | 373 |
| `dka_tools_pkg.check_directory` | 384 |
| `Fnd_File.put_line` | 392 |
| `fnd_file.put_line` | 646 |
| `fnd_file.put_line` | 767 |
| `fnd_file.put_line` | 782 |
| `fnd_file.put_line` | 797 |
| `fnd_file.put_line` | 802 |
| `fnd_file.put_line` | 837 |
| `Fnd_File.put_line` | 947 |
| `Fnd_File.put_line` | 948 |
| `Fnd_File.put_line` | 959 |
| `Dka_Tools_Pkg.get_parameter` | 963 |
| `Fnd_File.put_line` | 970 |
| `Dka_Tools_Pkg.get_message` | 979 |
| `Fnd_File.put_line` | 985 |
| `Dka_Tools_Pkg.get_message` | 990 |
| `Fnd_File.put_line` | 996 |
| `fnd_file.put_line` | 1006 |
| `Fnd_File.put_line` | 1019 |
| `Fnd_File.put` | 1045 |
| `Fnd_File.put` | 1051 |
| `Fnd_File.put_line` | 1052 |
| `Fnd_File.put_line` | 1054 |
| `Fnd_File.put_line` | 1063 |
| `Fnd_File.put_line` | 1064 |
| `Fnd_File.put_line` | 1070 |
| `Fnd_File.put_line` | 1071 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 120, 449, 461, 514, 528, 561, 648, 862 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOCMDMAIL_CITY / DKA | `DKA_SPOCMDMAIL_CITY_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCMDMAIL_CITY.prt:536 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
