# DKA_SAPGETIMG_WF_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPGETIMG_WF_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPGETIMG_WF_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 718 ; encodage : cp1252 (repli). SHA-256 : `205d58feeccc703673144c34540970d50e20f100a11ba0b3879ff6b99f7b31b4`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init_ap` | 64 |
| `init_po` | 157 |
| `authorize` | 249 |
| `construct_download_url` | 287 |
| `get_url_image_facture` | 357 |
| `get_url_image_bdc` | 447 |
| `get_url_image_facture_ivalua` | 527 |
| `get_url_image_bdc_ivalua` | 616 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_document_categories` | 123 |
| `fnd_document_datatypes` | 129 |
| `fnd_document_datatypes` | 135 |
| `fnd_document_categories` | 216 |
| `fnd_document_datatypes` | 222 |
| `fnd_document_datatypes` | 228 |
| `fnd_lob_access` | 255 |
| `fnd_lobs` | 304 |
| `fnd_lobs` | 310 |
| `dual` | 387 |
| `fnd_attached_documents` | 397 |
| `fnd_attached_documents` | 476 |
| `fnd_documents_tl` | 483 |
| `dual` | 557 |
| `fnd_attached_documents` | 567 |
| `fnd_attached_documents` | 643 |
| `po_headers_all` | 649 |
| `fnd_document_datatypes` | 658 |
| `fnd_documents` | 664 |
| `fnd_documents_tl` | 679 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.get_parameter` | 77 |
| `Dka_Tools_Pkg.get_parameter` | 92 |
| `Dka_Tools_Pkg.get_parameter` | 106 |
| `Dka_Tools_Pkg.get_parameter` | 170 |
| `Dka_Tools_Pkg.get_parameter` | 185 |
| `Dka_Tools_Pkg.get_parameter` | 199 |
| `fnd_message.set_name` | 268 |
| `fnd_message.set_token` | 269 |
| `fnd_message.set_token` | 270 |
| `fnd_message.set_token` | 271 |
| `fnd_gfm.construct_download_url` | 323 |
| `fnd_message.set_name` | 336 |
| `fnd_message.set_token` | 337 |
| `fnd_message.set_token` | 338 |
| `fnd_message.set_token` | 339 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 263, 332 |
| transaction_autonome | 252, 292 |
| when_others | 139, 232, 267, 335 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
