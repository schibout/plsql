# DKA_SAPGETIMG_AL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPGETIMG_AL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPGETIMG_AL_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 455 ; encodage : cp1252 (repli). SHA-256 : `0b7ce9f58cbb776eca74f6b619f587722d50bdf57f78478d5be3ccf98cebd9f7`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `log_msg` | 51 |
| `init_ap` | 86 |
| `init_po` | 173 |
| `authorize` | 258 |
| `construct_download_url` | 296 |
| `get_url_image_facture` | 350 |
| `return_nom_image` | 426 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_document_categories` | 145 |
| `fnd_document_datatypes` | 151 |
| `fnd_document_categories` | 231 |
| `fnd_document_datatypes` | 237 |
| `fnd_lob_access` | 264 |
| `fnd_lobs` | 311 |
| `fnd_lobs` | 317 |
| `dual` | 377 |
| `fnd_attached_documents` | 383 |
| `fnd_documents_tl` | 434 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 62 |
| `Dka_Tools_Pkg.get_parameter` | 99 |
| `Dka_Tools_Pkg.get_parameter` | 114 |
| `Dka_Tools_Pkg.get_parameter` | 128 |
| `Dka_Tools_Pkg.get_parameter` | 186 |
| `Dka_Tools_Pkg.get_parameter` | 200 |
| `Dka_Tools_Pkg.get_parameter` | 214 |
| `fnd_message.set_name` | 277 |
| `fnd_message.set_token` | 278 |
| `fnd_message.set_token` | 279 |
| `fnd_message.set_token` | 280 |
| `fnd_web_config.trail_slash` | 323 |
| `fnd_message.set_name` | 330 |
| `fnd_message.set_token` | 331 |
| `fnd_message.set_token` | 332 |
| `fnd_message.set_token` | 333 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 272, 326 |
| transaction_autonome | 261, 301 |
| when_others | 155, 241, 276, 329 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
