# DKA_SJTGLDATAJ_POST_OPEN.sql

Source : [dka/12.0.0/sql/DKA_SJTGLDATAJ_POST_OPEN.sql](../../dka/12.0.0/sql/DKA_SJTGLDATAJ_POST_OPEN.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 148 ; encodage : cp1252 (repli). SHA-256 : `6087125e68a6024368bb2cd93f846e98a34fcf01ca75cc67df3d131dc901a3fe`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility` | 63 |
| `fnd_user` | 68 |
| `fnd_concurrent_programs` | 77 |
| `DUAL` | 147 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.get_parameter` | 45 |
| `fnd_global.apps_initialize` | 83 |
| `fnd_profile.value` | 85 |
| `fnd_request.submit_request` | 98 |
| `fnd_concurrent.wait_for_request` | 116 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 104 |
| when_others | 138 |
| soumission | 98 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
