# DKA_SPOWFDA_ERRORS_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SPOWFDA_ERRORS_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SPOWFDA_ERRORS_PKG.pks).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 172 ; encodage : cp1252 (repli). SHA-256 : `a15d4677992eaed0ede67241e68fccaee2e30ca1d9920fe6b6d658365f29d706`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 32 |
| `insert_dka_spowfda_errors` | 47 |
| `maj_da` | 64 |
| `fermeture_notif_erreur` | 82 |
| `mail` | 102 |
| `deblocage_da` | 125 |
| `envoi_mail` | 143 |
| `main` | 161 |

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
| DKA_SPOWFDA_ERRORS / DKA | `dka_spowfda_errors_pkg.main` | dka/12.0.0/admin/import/DKA_SPOWFDA_ERRORS.prt:458 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
