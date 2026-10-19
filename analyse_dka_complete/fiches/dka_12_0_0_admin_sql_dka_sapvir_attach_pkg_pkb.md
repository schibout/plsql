# DKA_SAPVIR_ATTACH_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPVIR_ATTACH_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPVIR_ATTACH_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 721 ; encodage : cp1252 (repli). SHA-256 : `b9f309d2ef706bcef1aed7a77be25b1e0e28a460dd09955efc474e526a628f37`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 42 |
| `log_msg` | 56 |
| `init` | 78 |
| `get_doc_avr` | 170 |
| `chargement_image` | 259 |
| `delete_image` | 333 |
| `create_attached_document_avr` | 369 |
| `update_attached_document_avr` | 505 |
| `main` | 553 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_document_categories` | 135 |
| `fnd_document_datatypes` | 145 |
| `fnd_attached_documents` | 179 |
| `fnd_documents_tl` | 207 |
| `dual` | 285 |
| `fnd_lobs` | 287 |
| `fnd_attached_documents` | 387 |
| `DUAL` | 396 |
| `fnd_documents_tl` | 398 |
| `fnd_documents` | 421 |
| `DUAL` | 450 |
| `fnd_attached_documents` | 452 |
| `fnd_documents_tl` | 517 |
| `DKA_SAPVIR_ATTACH_TMP` | 573 |
| `fnd_concurrent_requests` | 603 |
| `ATTACHED` | 647 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 45 |
| `fnd_file.put_line` | 66 |
| `fnd_profile.value` | 94 |
| `Dka_Tools_Pkg.get_parameter` | 97 |
| `Dka_Tools_Pkg.get_parameter` | 116 |
| `dka_Tools_Pkg.put_outdebug_message` | 475 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 321, 356, 492, 539 |
| when_others | 154, 224, 245, 314, 349, 483, 530, 709 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPVIR_ATTACH / DKA | `DKA_SAPVIR_ATTACH_PKG.main` | dka/12.0.0/admin/import/DKA_SAPVIR_ATTACH.prt:420 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
