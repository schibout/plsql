# DKA_IEOGLVEC01_FILE_GENERATION.sql

Source : [dka/12.0.0/sql/DKA_IEOGLVEC01_FILE_GENERATION.sql](../../dka/12.0.0/sql/DKA_IEOGLVEC01_FILE_GENERATION.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 235 ; encodage : utf-8. SHA-256 : `51642e9e1aa0a84822c75365cb17f56c208856610ea8e8f1c19b175952347bdf`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DUAL` | 37 |
| `dka_ieoglvec01_int` | 60 |
| `dka_ieoglvec01_int` | 92 |
| `dka_ieoglvec01_int` | 127 |
| `dka_ieoglvec01_int` | 169 |
| `dka_ieoglvec01_int` | 186 |
| `dka_ieoglvec01_int` | 207 |
| `fnd_flex_values` | 221 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_ieoglvec01_pkg.get_gl_period_end_date` | 42 |
| `dka_ieoglvec01_pkg.get_gl_period_end_date` | 44 |
| `dka_ieoglvec01_pkg.get_gl_period_end_date` | 74 |
| `dka_ieoglvec01_pkg.get_gl_period_end_date` | 76 |
| `dka_ieoglvec01_pkg.get_gl_period_end_date` | 109 |
| `dka_ieoglvec01_pkg.get_gl_period_end_date` | 111 |
| `dka_ieoglvec01_pkg.get_gl_period_end_date` | 143 |
| `dka_ieoglvec01_pkg.get_gl_period_end_date` | 145 |

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
| DKA_IEOGLVEC01_FILE / DKA | `DKA_IEOGLVEC01_FILE_GENERATION` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_FILE_F.prt:472 |
| DKA_IEOGLVEC01_FILE / DKA | `DKA_IEOGLVEC01_FILE_GENERATION` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_FILE_F.prt:472 |
| DKA_IEOGLVEC01_FILE / DKA | `DKA_IEOGLVEC01_FILE_GENERATION` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_FILE_US.prt:472 |
| DKA_IEOGLVEC01_FILE / DKA | `DKA_IEOGLVEC01_FILE_GENERATION` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_FILE_US.prt:472 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
