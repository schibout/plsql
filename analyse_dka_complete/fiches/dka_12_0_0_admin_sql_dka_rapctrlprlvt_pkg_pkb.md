# DKA_RAPCTRLPRLVT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_RAPCTRLPRLVT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_RAPCTRLPRLVT_PKG.pkb).

Famille proposée par convention de nommage : **Banques / trésorerie**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1053 ; encodage : cp1252 (repli). SHA-256 : `b5dee86fe40857a8216cea0da9154559180d3601e9b692f8da4b3115a7f3adcf`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 38 |
| `log_msg` | 154 |
| `CONSTRUCTION_XML` | 882 |
| `send_mail` | 898 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_prel_ap_rb` | 83 |
| `dka_prel_ap_rb` | 102 |
| `dka_prel_ap_rb` | 142 |
| `dba_directories` | 821 |
| `fnd_concurrent_requests` | 827 |
| `fnd_concurrent_requests` | 902 |
| `fnd_flex_value_sets` | 908 |
| `dka.dka_mail_param` | 973 |
| `dka.dka_mail_param` | 975 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 164 |
| `fnd_file.PUT_LINE` | 863 |
| `fnd_message.set_name` | 959 |
| `fnd_message.set_name` | 962 |
| `fnd_message.set_name` | 965 |
| `fnd_message.set_token` | 966 |
| `fnd_message.set_name` | 969 |
| `fnd_request.submit_request` | 994 |
| `dka_tools_pkg.put_debug_message` | 1001 |
| `dka_tools_pkg.put_debug_message` | 1007 |
| `dka_tools_pkg.put_debug_message` | 1008 |
| `dka_tools_pkg.put_log_message` | 1016 |
| `fnd_concurrent.wait_for_request` | 1018 |
| `dka_tools_pkg.put_log_message` | 1031 |
| `dka_tools_pkg.put_log_message` | 1036 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_MAIL` | 994 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1000 |
| rollback | 1046 |
| when_others | 881, 1045 |
| suppression | 973 |
| soumission | 994 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_ENVOI_MAIL_PRLVT / DKA | `dka_rapctrlprlvt_pkg.send_mail` | dka/12.0.0/admin/import/DKA_ENVOI_MAIL_PRLVT.prt:417 |
| DKA_RAPCTRLPRLVT / DKA | `DKA_RAPCTRLPRLVT_PKG.main` | dka/12.0.0/admin/import/DKA_RAPCTRLPRLVT.prt:417 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
