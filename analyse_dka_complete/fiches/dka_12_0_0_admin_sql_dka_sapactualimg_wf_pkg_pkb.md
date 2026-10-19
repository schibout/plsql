# DKA_SAPACTUALIMG_WF_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPACTUALIMG_WF_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPACTUALIMG_WF_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 232 ; encodage : cp1252 (repli). SHA-256 : `5228cf66d0622f48a7ca695c20147b1b26873eff2e5e6989bede9f6b3ae4b77e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `log_msg` | 35 |
| `authorize` | 62 |
| `get_access_id` | 88 |
| `actualise_url_notif` | 111 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_lob_access` | 66 |
| `fnd_lob_access` | 69 |
| `wf_items` | 134 |
| `wf_items` | 144 |
| `fnd_lob_access` | 164 |
| `wf_items` | 182 |
| `wf_items` | 192 |
| `fnd_lob_access` | 212 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 46 |
| `fnd_message.set_name` | 79 |
| `fnd_message.set_token` | 80 |
| `fnd_message.set_token` | 81 |
| `fnd_message.set_token` | 82 |
| `Dka_Tools_Pkg.get_parameter` | 117 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 173, 221 |
| when_others | 78 |
| suppression | 66 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPURLACT / DKA | `dka_sapactualimg_wf_pkg.actualise_url_notif` | dka/12.0.0/admin/import/DKA_SAPURLACT.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
