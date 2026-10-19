# DKA_SRBRELBANC_CSP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SRBRELBANC_CSP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SRBRELBANC_CSP_PKG.pkb).

Famille proposée par convention de nommage : **Banques / trésorerie**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 474 ; encodage : cp1252 (repli). SHA-256 : `71868ae26210a2c0d4c20b78b4427175ea2a8661864f3ef9c57a1d8c39111626`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 34 |
| `log_msg` | 48 |
| `SRBRELBANC_ETAT_CSP` | 79 |
| `ENVOI_MAIL` | 235 |
| `check_setup` | 343 |
| `main` | 385 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `RB_LINES_ALL` | 121 |
| `CE_BANK_ACCOUNTS` | 122 |
| `CE_BANK_BRANCHES_V` | 123 |
| `GL_CODE_COMBINATIONS` | 124 |
| `dka_stransco_lines` | 132 |
| `FND_FLEX_VALUES_VL` | 142 |
| `FND_FLEX_VALUES_VL` | 151 |
| `FND_RESPONSIBILITY_TL` | 311 |
| `dka_stransco_lines` | 412 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 37 |
| `fnd_file.put_line` | 58 |
| `fnd_date.canonical_to_date` | 129 |
| `Dka_Tools_Pkg.get_parameter` | 254 |
| `Dka_Tools_Pkg.get_parameter` | 263 |
| `Dka_Tools_Pkg.get_parameter` | 271 |
| `Dka_Tools_Pkg.get_message` | 288 |
| `Dka_Tools_Pkg.get_message` | 295 |
| `DKA_SEND_MAIL_PKG.Send_Mail` | 324 |
| `dka_tools_pkg.check_directory` | 347 |
| `dka_tools_pkg.check_transco` | 350 |
| `dka_tools_pkg.check_transco` | 351 |
| `dka_tools_pkg.check_value_set` | 354 |
| `dka_tools_pkg.check_value_set` | 355 |
| `dka_tools_pkg.check_value_set` | 356 |
| `dka_tools_pkg.check_parameter` | 359 |
| `dka_tools_pkg.check_parameter` | 360 |
| `dka_tools_pkg.check_parameter` | 361 |
| `dka_tools_pkg.check_message` | 364 |
| `dka_tools_pkg.check_message` | 365 |
| `dka_tools_pkg.check_flex_segment` | 369 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 216, 315, 336, 422, 465 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SRBRELBANC_CSP / DKA | `DKA_SRBRELBANC_CSP_PKG.main` | dka/12.0.0/admin/import/DKA_SRBRELBANC_CSP.prt:654 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
