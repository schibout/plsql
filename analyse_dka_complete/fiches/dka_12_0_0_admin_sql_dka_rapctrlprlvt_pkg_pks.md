# DKA_RAPCTRLPRLVT_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_RAPCTRLPRLVT_PKG.pks](../../dka/12.0.0/admin/sql/DKA_RAPCTRLPRLVT_PKG.pks).

Famille proposée par convention de nommage : **Banques / trésorerie**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 57 ; encodage : cp1252 (repli). SHA-256 : `ca8fe8a789b4d8f8a1e654a527a2a8f4adbd0ee9a5283c5b26125bc2502a458f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 36 |
| `send_mail` | 51 |

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
| DKA_ENVOI_MAIL_PRLVT / DKA | `dka_rapctrlprlvt_pkg.send_mail` | dka/12.0.0/admin/import/DKA_ENVOI_MAIL_PRLVT.prt:417 |
| DKA_RAPCTRLPRLVT / DKA | `DKA_RAPCTRLPRLVT_PKG.main` | dka/12.0.0/admin/import/DKA_RAPCTRLPRLVT.prt:417 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
