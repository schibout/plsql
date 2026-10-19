# DKA_IEOGLVEC01_UPD_FLEX_ATTR.sql

Source : [dka/12.0.0/sql/DKA_IEOGLVEC01_UPD_FLEX_ATTR.sql](../../dka/12.0.0/sql/DKA_IEOGLVEC01_UPD_FLEX_ATTR.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 452 ; encodage : utf-8. SHA-256 : `91429d5b74ca476009cfc3e5a84e509dc70362d931fcc137618d44712b5a4f34`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_attribute_number` | 87 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_ieoglvec01_load_flex_attr` | 69 |
| `dka_ieoglvec01_load_flex_attr` | 80 |
| `fnd_descr_flex_col_usage_vl` | 102 |
| `fnd_segment_attribute_values` | 150 |
| `GL_access_set_assignments` | 157 |
| `dka_ieoglvec01_load_flex_attr` | 179 |
| `dka_ieoglvec01_load_flex_attr` | 202 |
| `fnd_flex_values` | 271 |
| `fnd_flex_values` | 308 |
| `dka_ieoglvec01_load_flex_attr` | 346 |
| `of` | 352 |
| `dka_ieoglvec01_load_flex_attr` | 360 |
| `of` | 367 |
| `VALUE` | 375 |
| `dka_ieoglvec01_load_flex_attr` | 378 |
| `dka_ieoglvec01_load_flex_attr` | 397 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_ieoglvec01_pkg.get_application_short_name` | 125 |
| `fnd_profile.value` | 157 |
| `Fnd_File.put_line` | 170 |
| `Fnd_File.put_line` | 173 |
| `dka_ieoglvec01_pkg.get_message` | 173 |
| `Fnd_File.put_line` | 184 |
| `Fnd_File.put_line` | 194 |
| `Fnd_File.put_line` | 215 |
| `Fnd_File.put_line` | 219 |
| `Fnd_File.put_line` | 240 |
| `Fnd_File.put_line` | 352 |
| `dka_ieoglvec01_pkg.get_message` | 362 |
| `Fnd_File.put_line` | 367 |
| `Fnd_File.put_line` | 375 |
| `Fnd_File.put_line` | 391 |
| `Fnd_File.put_line` | 394 |
| `Fnd_File.put_line` | 395 |
| `Fnd_File.put_line` | 411 |
| `Fnd_File.put_line` | 415 |
| `dka_ieoglvec01_pkg.get_message` | 415 |
| `Fnd_File.put_line` | 416 |
| `dka_ieoglvec01_pkg.get_message` | 416 |
| `Fnd_File.put_line` | 417 |
| `dka_ieoglvec01_pkg.get_message` | 417 |
| `Fnd_File.put_line` | 418 |
| `Fnd_File.put_line` | 425 |
| `dka_ieoglvec01_pkg.get_message` | 425 |
| `Fnd_File.put_line` | 430 |
| `Fnd_File.put_line` | 434 |
| `Fnd_File.put_line` | 435 |
| `Fnd_File.put_line` | 442 |
| `dka_ieoglvec01_pkg.get_message` | 442 |
| `Fnd_File.put_line` | 445 |
| `Fnd_File.put_line` | 446 |
| `dka_ieoglvec01_pkg.get_message` | 446 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 373, 388, 433 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IEOGLVEC01_UPD_FLEX_ATTR / DKA | `DKA_IEOGLVEC01_UPD_FLEX_ATTR` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_UPD_FLEX_ATTR_F.prt:458 |
| DKA_IEOGLVEC01_UPD_FLEX_ATTR / DKA | `DKA_IEOGLVEC01_UPD_FLEX_ATTR` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_UPD_FLEX_ATTR_F.prt:458 |
| DKA_IEOGLVEC01_UPD_FLEX_ATTR / DKA | `DKA_IEOGLVEC01_UPD_FLEX_ATTR` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_UPD_FLEX_ATTR_US.prt:458 |
| DKA_IEOGLVEC01_UPD_FLEX_ATTR / DKA | `DKA_IEOGLVEC01_UPD_FLEX_ATTR` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_UPD_FLEX_ATTR_US.prt:458 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
