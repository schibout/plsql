# DKA_SRBRAPAUTO_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SRBRAPAUTO_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SRBRAPAUTO_PKG.pkb).

Famille proposée par convention de nommage : **Banques / trésorerie**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 298 ; encodage : cp1252 (repli). SHA-256 : `3dd5c91a60cd211f17faad6ca120001ea46546ec95896df139805c16addeeb83`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 45 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility` | 160 |
| `dka_prel_ap_rb` | 279 |
| `rb_lines` | 281 |
| `rb_lines` | 286 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.get_parameter` | 140 |
| `dka_tools_pkg.put_log_message` | 150 |
| `dka_tools_pkg.put_log_message` | 167 |
| `fnd_global.apps_initialize` | 172 |
| `fnd_request.submit_request` | 175 |
| `dka_tools_pkg.put_log_message` | 194 |
| `dka_tools_pkg.put_log_message` | 198 |
| `fnd_concurrent.wait_for_request` | 224 |
| `dka_tools_pkg.put_log_message` | 234 |
| `dka_tools_pkg.put_log_message` | 237 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `RBMATRUN` | 175 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 203, 291 |
| when_others | 163 |
| soumission | 175 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SRBRAPAUTO / DKA | `dka_srbrapauto_pkg.main` | dka/12.0.0/admin/import/DKA_SRBRAPAUTO.prt:420 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
