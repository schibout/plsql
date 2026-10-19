# DKA_IEOGLVEC01_INS_FLEX_VALUE.sql

Source : [dka/12.0.0/sql/DKA_IEOGLVEC01_INS_FLEX_VALUE.sql](../../dka/12.0.0/sql/DKA_IEOGLVEC01_INS_FLEX_VALUE.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 338 ; encodage : utf-8. SHA-256 : `6932d9d240914424cbb8f1fc3ff0a2c3f184c7c2b57cf4652f2bf477dec6645c`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_ieoglvec01_load_flex_value` | 40 |
| `dka_ieoglvec01_load_flex_value` | 51 |
| `dka_ieoglvec01_load_flex_value` | 83 |
| `fnd_flex_value_sets` | 90 |
| `fnd_languages` | 119 |
| `dual` | 124 |
| `dka_ieoglvec01_load_flex_value` | 132 |
| `fnd_flex_values_tl` | 146 |
| `fnd_flex_values` | 151 |
| `dka_ieoglvec01_load_flex_value` | 163 |
| `of` | 169 |
| `fnd_flex_values` | 181 |
| `fnd_flex_values_tl` | 205 |
| `fnd_languages` | 226 |
| `dka_ieoglvec01_load_flex_value` | 229 |
| `dka_ieoglvec01_load_flex_value` | 245 |
| `VALUE` | 261 |
| `dka_ieoglvec01_load_flex_value` | 264 |
| `dka_ieoglvec01_load_flex_value` | 283 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_ieoglvec01_pkg.get_application_short_name` | 62 |
| `Fnd_File.put_line` | 77 |
| `dka_ieoglvec01_pkg.get_message` | 77 |
| `Fnd_File.put_line` | 83 |
| `Fnd_File.put_line` | 95 |
| `Fnd_File.put_line` | 98 |
| `dka_ieoglvec01_pkg.get_message` | 134 |
| `Fnd_File.put_line` | 169 |
| `Fnd_File.put_line` | 178 |
| `Fnd_File.put_line` | 241 |
| `Fnd_File.put_line` | 243 |
| `dka_ieoglvec01_pkg.get_message` | 247 |
| `Fnd_File.put_line` | 261 |
| `dka_ieoglvec01_pkg.get_message` | 266 |
| `Fnd_File.put_line` | 277 |
| `Fnd_File.put_line` | 280 |
| `Fnd_File.put_line` | 281 |
| `Fnd_File.put_line` | 298 |
| `Fnd_File.put_line` | 299 |
| `Fnd_File.put_line` | 303 |
| `dka_ieoglvec01_pkg.get_message` | 303 |
| `Fnd_File.put_line` | 304 |
| `dka_ieoglvec01_pkg.get_message` | 304 |
| `Fnd_File.put_line` | 305 |
| `dka_ieoglvec01_pkg.get_message` | 305 |
| `Fnd_File.put_line` | 306 |
| `dka_ieoglvec01_pkg.get_message` | 306 |
| `Fnd_File.put_line` | 307 |
| `Fnd_File.put_line` | 314 |
| `dka_ieoglvec01_pkg.get_message` | 314 |
| `Fnd_File.put_line` | 319 |
| `Fnd_File.put_line` | 323 |
| `Fnd_File.put_line` | 324 |
| `Fnd_File.put_line` | 329 |
| `dka_ieoglvec01_pkg.get_message` | 329 |
| `Fnd_File.put_line` | 331 |
| `Fnd_File.put_line` | 332 |
| `dka_ieoglvec01_pkg.get_message` | 332 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 239, 259, 274, 322 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IEOGLVEC01_INS_FLEX_VALUE / DKA | `DKA_IEOGLVEC01_INS_FLEX_VALUE` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_INS_FLEX_VALUE_F.prt:458 |
| DKA_IEOGLVEC01_INS_FLEX_VALUE / DKA | `DKA_IEOGLVEC01_INS_FLEX_VALUE` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_INS_FLEX_VALUE_F.prt:458 |
| DKA_IEOGLVEC01_INS_FLEX_VALUE / DKA | `DKA_IEOGLVEC01_INS_FLEX_VALUE` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_INS_FLEX_VALUE_US.prt:458 |
| DKA_IEOGLVEC01_INS_FLEX_VALUE / DKA | `DKA_IEOGLVEC01_INS_FLEX_VALUE` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_INS_FLEX_VALUE_US.prt:458 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
