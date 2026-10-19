# DKA_IEOGLVEC01_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_IEOGLVEC01_PKG.pks](../../dka/12.0.0/admin/sql/DKA_IEOGLVEC01_PKG.pks).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 400 ; encodage : cp1252 (repli). SHA-256 : `8dea79c78e52f18b49115b91fa4b1a9eb7d43de58845d42196ac76066a51518a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_message` | 44 |
| `put_out_header` | 81 |
| `get_instance_name` | 94 |
| `get_application_short_name` | 110 |
| `get_segment_num` | 127 |
| `get_qual_flex_value_set_id` | 144 |
| `get_qual_flex_value_set_name` | 161 |
| `get_qual_value_set_val_type` | 178 |
| `get_qual_flex_value_set_parent` | 195 |
| `get_cuf_attribute_num` | 212 |
| `get_cuf_attribute_value` | 231 |
| `get_cuf_attribute_value_dep` | 252 |
| `get_conso_code` | 272 |
| `get_partner_code` | 291 |
| `qualifier_exists` | 308 |
| `attribute_exists` | 325 |
| `profile_option_exists` | 342 |
| `get_gl_period_end_date` | 357 |
| `main` | 372 |
| `control` | 390 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IEOGLVEC01_CTRL / DKA | `dka_ieoglvec01_pkg.control` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_CTRL_F.prt:419 |
| DKA_IEOGLVEC01_CTRL / DKA | `dka_ieoglvec01_pkg.control` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_CTRL_F.prt:419 |
| DKA_IEOGLVEC01_CTRL / DKA | `dka_ieoglvec01_pkg.control` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_CTRL_US.prt:419 |
| DKA_IEOGLVEC01_CTRL / DKA | `dka_ieoglvec01_pkg.control` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_CTRL_US.prt:419 |
| DKA_IEOGLVEC01_MAIN / DKA | `dka_ieoglvec01_pkg.main` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_MAIN_F.prt:498 |
| DKA_IEOGLVEC01_MAIN / DKA | `dka_ieoglvec01_pkg.main` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_MAIN_F.prt:498 |
| DKA_IEOGLVEC01_MAIN / DKA | `dka_ieoglvec01_pkg.main` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_MAIN_US.prt:498 |
| DKA_IEOGLVEC01_MAIN / DKA | `dka_ieoglvec01_pkg.main` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_MAIN_US.prt:498 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
