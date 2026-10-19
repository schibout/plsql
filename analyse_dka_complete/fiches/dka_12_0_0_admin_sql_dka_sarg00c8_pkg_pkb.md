# DKA_SARG00C8_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARG00C8_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARG00C8_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 897 ; encodage : cp1252 (repli). SHA-256 : `765ecd1b3f8c159caa3359722cbbeb0c9223b5ba3589053213aeb47629c3b635`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 44 |
| `log_msg` | 58 |
| `SARG00C8_ETAT` | 85 |
| `SARG00C8_RATT` | 504 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka.dka_sarg00c8_tmp` | 126 |
| `dka.dka_Sarg00c8_tmp` | 140 |
| `Dka_Sarg00c8` | 157 |
| `Ra_Customer_Trx_All` | 160 |
| `fnd_flex_values` | 196 |
| `dka.dka_Sarg00c8_tmp` | 223 |
| `Ra_Batch_Sources_All` | 245 |
| `fnd_flex_values_vl` | 278 |
| `Dka_Sarg00c8` | 295 |
| `dka.dka_Sarg00c8_tmp` | 315 |
| `Ra_Batch_Sources_All` | 337 |
| `fnd_flex_values` | 367 |
| `fnd_flex_values` | 390 |
| `fnd_flex_value_sets` | 403 |
| `fnd_flex_value_sets` | 446 |
| `Dka_Sarg00c8` | 541 |
| `Ra_Customer_Trx_All` | 544 |
| `Gl_Period_Statuses` | 552 |
| `Gl_Period_Statuses` | 554 |
| `Gl_Period_Statuses` | 560 |
| `fnd_flex_values_vl` | 601 |
| `Ra_Batch_Sources_All` | 645 |
| `Gl_Period_Statuses` | 675 |
| `Gl_Period_Statuses` | 677 |
| `Gl_Period_Statuses` | 682 |
| `fnd_flex_values_vl` | 697 |
| `Dka_Sarg00c8` | 707 |
| `Ra_Batch_Sources_All` | 744 |
| `Gl_Period_Statuses` | 774 |
| `Gl_Period_Statuses` | 776 |
| `Gl_Period_Statuses` | 781 |
| `fnd_flex_values_vl` | 802 |
| `fnd_flex_value_sets` | 852 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 47 |
| `fnd_file.put_line` | 68 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 827 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 221, 313, 419 |
| when_others | 453, 483, 859, 888 |
| truncate | 138 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARG00C8_ETAT / DKA | `DKA_SARG00C8_PKG.SARG00C8_ETAT` | dka/12.0.0/admin/import/DKA_SARG00C8_ETAT.prt:522 |
| DKA_SARG00C8_RATT / DKA | `DKA_SARG00C8_PKG.SARG00C8_RATT` | dka/12.0.0/admin/import/DKA_SARG00C8_RATT.prt:539 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
