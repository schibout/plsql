# DKA_SAPPOST_APPRO_MVT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPPOST_APPRO_MVT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPPOST_APPRO_MVT_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 105 ; encodage : cp1252 (repli). SHA-256 : `dbdd0fb473d4d24be7d992ce093d19d1ef3d6a601e96ab99d829d5c1cddb06b5`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `respond_sysadmin_notif` | 29 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `wf_lookups` | 49 |
| `wf_notifications` | 53 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `wf_notification.setattrtext` | 71 |
| `wf_notification.respond` | 74 |
| `fnd_message.set_name` | 78 |
| `fnd_message.set_token` | 79 |
| `fnd_message.set_token` | 80 |
| `fnd_message.set_name` | 92 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 90, 95, 97 |
| when_others | 77, 96 |
| workflow | 70 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPPOST_APPRO_MVT / DKA | `dka_sappost_appro_mvt_pkg.respond_sysadmin_notif` | dka/12.0.0/admin/import/DKA_SAPPOST_APPRO_MVT.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
