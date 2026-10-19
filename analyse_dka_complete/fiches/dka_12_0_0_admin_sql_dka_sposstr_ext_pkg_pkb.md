# DKA_SPOSSTR_EXT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOSSTR_EXT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOSSTR_EXT_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 662 ; encodage : cp1252 (repli). SHA-256 : `e0d1675aeb7d15164fd5563b86386ea6013312ba6c5a4ad4fa01cdf31c80e231`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 81 |
| `output_end` | 112 |
| `out_msg` | 132 |
| `log_msg` | 147 |
| `check_value_set` | 164 |
| `init` | 216 |
| `main` | 594 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_flex_value_sets` | 172 |
| `fnd_flex_values` | 173 |
| `PO_headers_all` | 287 |
| `po_headers_all` | 292 |
| `DKA_CONTRAT_SSTR_IMPUTATION` | 299 |
| `DKA_CONTRAT_SSTR_IMPUTATION` | 302 |
| `po_headers_archive_all` | 307 |
| `dka_contrat_sstr_archi` | 308 |
| `PO_HEADERS_ALL` | 330 |
| `PO_HEADERS_ALL` | 341 |
| `PO_headers_all` | 383 |
| `dka_contrat_sstr` | 388 |
| `po_headers_archive_all` | 392 |
| `po_headers_archive_all` | 395 |
| `DKA_CONTRAT_SSTR_IMPUTATION` | 398 |
| `DKA_CONTRAT_SSTR_IMPUTATION` | 401 |
| `po_headers_archive_all` | 409 |
| `dka_contrat_sstr_archi` | 410 |
| `dka_contrat_sstr_archi` | 428 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 43 |
| `fnd_profile.value` | 45 |
| `fnd_profile.value` | 46 |
| `Fnd_File.put_line` | 88 |
| `Fnd_File.put_line` | 89 |
| `Fnd_File.put_line` | 90 |
| `Fnd_File.put_line` | 91 |
| `Fnd_File.put_line` | 92 |
| `Fnd_File.put_line` | 119 |
| `Fnd_File.put_line` | 120 |
| `Fnd_File.put_line` | 121 |
| `fnd_file.put_line` | 135 |
| `fnd_file.put_line` | 157 |
| `Fnd_File.put_line` | 441 |
| `Dka_Tools_Pkg.get_parameter` | 452 |
| `dka_tools_pkg.check_directory` | 466 |
| `fnd_file.put_line` | 577 |
| `Fnd_File.put_line` | 625 |
| `Fnd_File.put_line` | 626 |
| `Fnd_File.put_line` | 640 |
| `Fnd_File.put_line` | 641 |
| `Fnd_File.put_line` | 644 |
| `Fnd_File.put_line` | 653 |
| `Fnd_File.put_line` | 654 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 579 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOSSTR_EXT / DKA | `DKA_SPOSSTR_EXT_PKG.main` | dka/12.0.0/admin/import/DKA_SPOSSTR_EXT.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
