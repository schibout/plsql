# DKA_SAP_DEL_TAB_HISTORY_FOUR.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAP_DEL_TAB_HISTORY_FOUR.pkb](../../dka/12.0.0/admin/sql/DKA_SAP_DEL_TAB_HISTORY_FOUR.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 125 ; encodage : utf-8. SHA-256 : `a330e00a47c420fadb89d6ec9223c5b9b8f2a3bd5e329bd5d26d8d6b715e631b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 43 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_SAPFRS_MAJ_SITES` | 86 |
| `DKA_SAPFRS_MAJ_HEADERS` | 89 |
| `DKA_SAPFRS_MAJ_SITES_HIST` | 91 |
| `DKA_SAPFRS_MAJ_SITES` | 92 |
| `DKA_SAPFRS_MAJ_HEADERS_HIST` | 94 |
| `DKA_SAPFRS_MAJ_HEADERS` | 95 |
| `DKA_SAPFRS_MAJ_SITES` | 97 |
| `DKA_SAPFRS_MAJ_HEADERS` | 99 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 68 |
| `Fnd_File.put_line` | 69 |
| `Fnd_File.put_line` | 70 |
| `Fnd_File.put_line` | 71 |
| `Fnd_File.put_line` | 72 |
| `dka_tools_pkg.get_parameter` | 73 |
| `fnd_file.put_line` | 103 |
| `fnd_file.put_line` | 104 |
| `fnd_file.put_line` | 105 |
| `Fnd_File.put_line` | 107 |
| `fnd_file.put_line` | 108 |
| `Fnd_File.put_line` | 111 |
| `Fnd_File.put_line` | 117 |
| `Fnd_File.put_line` | 118 |
| `Fnd_File.put_line` | 119 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 101 |
| when_others | 113 |
| suppression | 97, 99 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAP_DEL_TAB_HISTORY_FOUR / DKA | `DKA_SAP_DEL_TAB_HISTORY_FOUR.main` | dka/12.0.0/admin/import/DKA_SAP_DEL_TAB_HISTORY_FOUR.prt:444 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
