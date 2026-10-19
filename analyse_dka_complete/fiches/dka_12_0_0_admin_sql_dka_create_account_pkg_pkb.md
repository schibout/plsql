# DKA_CREATE_ACCOUNT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_CREATE_ACCOUNT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_CREATE_ACCOUNT_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1642 ; encodage : cp1252 (repli). SHA-256 : `c153eaee26d4eb8b54d62d1da09ad3d59434399a7eba051e9c36b8b6bfd74cf1`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 61 |
| `get_receivables_trx_id` | 93 |
| `get_ccid` | 129 |
| `find_bank_info` | 167 |
| `check_mandatory_param` | 235 |
| `create_bank_acct` | 275 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA.DKA_COMPTE_BANC_INT` | 84 |
| `CE_BANK_ACCOUNTS` | 86 |
| `ar_receivables_trx_all` | 104 |
| `gl_code_combinations` | 137 |
| `hz_parties` | 178 |
| `sys.dual` | 285 |
| `CE_BANK_ACCOUNTS` | 287 |
| `hz_organization_profiles` | 290 |
| `CE_BANK_ACCOUNTS` | 464 |
| `xtr_parties_v` | 670 |
| `xtr_party_info` | 677 |
| `ce_bank_branches_v` | 682 |
| `HR_ORGANIZATION_INFORMATION_V` | 797 |
| `hr_all_organization_units` | 889 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_PROFILE.value` | 59 |
| `Fnd_File.put_line` | 111 |
| `Fnd_File.put_line` | 117 |
| `Fnd_File.put_line` | 144 |
| `Fnd_File.put_line` | 149 |
| `fnd_message.set_name` | 215 |
| `fnd_message.set_name` | 238 |
| `fnd_message.set_token` | 239 |
| `fnd_api.to_boolean` | 332 |
| `fnd_message.set_name` | 406 |
| `fnd_msg_pub.count_and_get` | 744 |
| `fnd_msg_pub.count_and_get` | 754 |
| `fnd_msg_pub.count_and_get` | 763 |
| `fnd_message.set_name` | 772 |
| `fnd_message.set_token` | 773 |
| `fnd_msg_pub.count_and_get` | 775 |
| `fnd_flex_ext.get_ccid` | 846 |
| `Fnd_File.put_line` | 876 |
| `Fnd_File.put_line` | 880 |
| `Fnd_File.put_line` | 884 |
| `dka_tools_pkg.get_code_combination_id` | 936 |
| `Fnd_File.put_line` | 992 |
| `dka_tools_pkg.get_code_combination_id` | 996 |
| `Fnd_File.put_line` | 1050 |
| `dka_tools_pkg.get_code_combination_id` | 1053 |
| `Fnd_File.put_line` | 1124 |
| `dka_tools_pkg.get_code_combination_id` | 1127 |
| `Fnd_File.put_line` | 1268 |
| `dka_tools_pkg.get_code_combination_id` | 1271 |
| `Fnd_File.put_line` | 1413 |
| `dka_tools_pkg.get_code_combination_id` | 1416 |
| `Fnd_File.put_line` | 1558 |
| `fnd_flex_ext.get_ccid` | 1587 |
| `Fnd_File.put_line` | 1615 |
| `Fnd_File.put_line` | 1620 |
| `Fnd_File.put_line` | 1624 |
| `Fnd_File.put_line` | 1633 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 752, 761, 770 |
| when_others | 115, 147, 769, 1632 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_CREATE_ACCOUNT_PKG / DKA | `DKA_CREATE_ACCOUNT_PKG.main` | dka/12.0.0/admin/import/DKA_CREATE_ACCOUNT_PKG_F.prt:458 |
| DKA_CREATE_ACCOUNT_PKG / DKA | `DKA_CREATE_ACCOUNT_PKG.main` | dka/12.0.0/admin/import/DKA_CREATE_ACCOUNT_PKG_F.prt:458 |
| DKA_CREATE_ACCOUNT_PKG / DKA | `DKA_CREATE_ACCOUNT_PKG.main` | dka/12.0.0/admin/import/DKA_CREATE_ACCOUNT_PKG_US.prt:458 |
| DKA_CREATE_ACCOUNT_PKG / DKA | `DKA_CREATE_ACCOUNT_PKG.main` | dka/12.0.0/admin/import/DKA_CREATE_ACCOUNT_PKG_US.prt:458 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
