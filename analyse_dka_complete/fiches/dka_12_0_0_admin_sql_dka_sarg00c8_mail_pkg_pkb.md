# DKA_SARG00C8_MAIL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARG00C8_MAIL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARG00C8_MAIL_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 308 ; encodage : cp1252 (repli). SHA-256 : `506b2dd2d12edfbfffc019ed1d40d848dc31393fc648332055a035cfe554e16c`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 34 |
| `log_msg` | 48 |
| `main` | 73 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_programs` | 155 |
| `fnd_concurrent_requests` | 162 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 37 |
| `fnd_file.put_line` | 58 |
| `Dka_Tools_Pkg.get_parameter` | 98 |
| `Dka_Tools_Pkg.get_parameter` | 111 |
| `Dka_Tools_Pkg.get_message` | 132 |
| `Dka_Tools_Pkg.get_message` | 143 |
| `DKA_SEND_MAIL_PKG.Send_Mail` | 282 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 167, 228, 298 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARG00C8_MAIL / DKA | `DKA_SARG00C8_MAIL_PKG.main` | dka/12.0.0/admin/import/DKA_SARG00C8_MAIL.prt:422 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
