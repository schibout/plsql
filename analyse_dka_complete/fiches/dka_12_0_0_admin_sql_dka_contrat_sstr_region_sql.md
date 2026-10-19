# DKA_CONTRAT_SSTR_REGION.sql

Source : [dka/12.0.0/admin/sql/DKA_CONTRAT_SSTR_REGION.sql](../../dka/12.0.0/admin/sql/DKA_CONTRAT_SSTR_REGION.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 280 ; encodage : cp1252 (repli). SHA-256 : `e392c0fee9f310441e9ce110206e894ae750c0874d74843c36c05cad2f198d0b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_user` | 53 |
| `fnd_languages` | 65 |
| `fnd_application_vl` | 80 |
| `ak_attributes` | 92 |
| `fnd_user` | 207 |
| `ak_web_user_sec_attr_values` | 221 |
| `ak_web_user_sec_attr_values` | 225 |
| `ak_web_user_sec_attr_values` | 238 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 265 |
| when_others | 56, 70, 82, 199 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
