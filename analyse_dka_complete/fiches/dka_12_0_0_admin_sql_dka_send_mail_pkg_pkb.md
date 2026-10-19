# DKA_SEND_MAIL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SEND_MAIL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SEND_MAIL_PKG.pkb).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 685 ; encodage : cp1252 (repli). SHA-256 : `d1e0786c977f52b204cebd68b98af6d4564cf9fa94292c1ff9cde42378961ccf`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `log_msg` | 38 |
| `convert_type_mime` | 59 |
| `write_boundary` | 222 |
| `begin_attachment` | 238 |
| `end_attachment` | 275 |
| `Send_Mail` | 300 |
| `mail_test` | 639 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_flex_value_sets` | 353 |
| `all_directories` | 496 |
| `v$database` | 662 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 48 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 590 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 595 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 600 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 610 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 615 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 626 |
| `Dka_Tools_Pkg.get_parameter` | 652 |
| `Fnd_Profile.VALUE` | 680 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 617, 664 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
