# DKA_ScriptAttribute.sql

Source : [dka/12.0.0/admin/sql/DKA_ScriptAttribute.sql](../../dka/12.0.0/admin/sql/DKA_ScriptAttribute.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 306 ; encodage : cp1252 (repli). SHA-256 : `ff08582136c56afa63c30b750df3e1aafbccf84609b9ad4c14483204b642bfc4`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_user` | 52 |
| `fnd_languages` | 64 |
| `fnd_application_vl` | 79 |
| `ak_attributes` | 91 |
| `fnd_user` | 202 |
| `ak_web_user_sec_attr_values` | 247 |
| `ak_web_user_sec_attr_values` | 251 |
| `ak_web_user_sec_attr_values` | 264 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 292 |
| when_others | 55, 69, 81, 198 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
