# DKA_APUREMENT_PASSE_PRE_CUTOFF.sql

Source : [dka/12.0.0/admin/sql/DKA_APUREMENT_PASSE_PRE_CUTOFF.sql](../../dka/12.0.0/admin/sql/DKA_APUREMENT_PASSE_PRE_CUTOFF.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 125 ; encodage : cp1252 (repli). SHA-256 : `75f7d31033cbc84f43ab1f9b85f5960c2fa7844212683cbe813ddf5ac7b73c75`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_je_lines_recon` | 53 |
| `gl_je_lines` | 58 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.VALUE` | 75 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 95 |
| when_others | 114 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
