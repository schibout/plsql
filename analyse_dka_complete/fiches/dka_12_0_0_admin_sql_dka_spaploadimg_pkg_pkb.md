# DKA_SPAPLOADIMG_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPAPLOADIMG_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPAPLOADIMG_PKG.pkb).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 574 ; encodage : cp1252 (repli). SHA-256 : `618fd3e1530f2dd87a0e1748f46343e8b0c13647d56b60765f78d526556b7229`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 74 |
| `charge_image` | 345 |
| `attach_doc_facture` | 430 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ap_invoices_all` | 79 |
| `fnd_flex_value_sets` | 82 |
| `ap_invoices_all` | 92 |
| `fnd_flex_value_sets` | 95 |
| `fnd_attached_documents` | 104 |
| `fnd_document_categories` | 135 |
| `fnd_document_datatypes` | 141 |
| `fnd_document_datatypes` | 147 |
| `fnd_flex_value_sets` | 172 |
| `dual` | 363 |
| `dual` | 384 |
| `fnd_lobs` | 386 |
| `DUAL` | 442 |
| `fnd_documents_tl` | 444 |
| `fnd_documents` | 501 |
| `DUAL` | 531 |
| `fnd_attached_documents` | 533 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_log_message` | 130 |
| `Dka_Tools_Pkg.put_log_message` | 184 |
| `Dka_Tools_Pkg.put_log_message` | 208 |
| `Dka_Tools_Pkg.get_parameter` | 218 |
| `Dka_Tools_Pkg.put_log_message` | 235 |
| `Dka_Tools_Pkg.put_log_message` | 240 |
| `Dka_Tools_Pkg.put_log_message` | 250 |
| `dka_tools_pkg.put_log_message` | 251 |
| `Dka_Tools_Pkg.put_log_message` | 258 |
| `dka_tools_pkg.put_log_message` | 259 |
| `Dka_Tools_Pkg.put_log_message` | 278 |
| `dka_tools_pkg.put_log_message` | 279 |
| `Dka_Tools_Pkg.put_log_message` | 280 |
| `Dka_Tools_Pkg.put_log_message` | 281 |
| `Dka_Tools_Pkg.put_log_message` | 282 |
| `dka_tools_pkg.put_log_message` | 292 |
| `dka_tools_pkg.put_log_message` | 410 |
| `dka_tools_pkg.put_log_message` | 412 |
| `dka_tools_pkg.put_log_message` | 560 |
| `dka_tools_pkg.put_log_message` | 562 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 211, 237 |
| rollback | 254, 262, 296, 416, 565 |
| when_others | 183, 256, 291, 365, 408, 558 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_APLOADIMG / DKA | `DKA_SPAPLOADIMG_PKG.main` | dka/12.0.0/admin/import/DKA_APLOADIMG.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
