# DKA_POWFPOAG.wft

Source : [dka/12.0.0/admin/import/DKA_POWFPOAG.wft](../../dka/12.0.0/admin/import/DKA_POWFPOAG.wft).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 14387 ; encodage : utf-8. SHA-256 : `da803703aa6a5f85995b7fbf0e3ef1715b4483fece02399a0095148224e7647f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `REFERENCES` | 134 |
| `Code` | 1006 |
| `Display` | 2088 |
| `Date` | 2123 |
| `a` | 2824 |
| `Agent` | 3216 |
| `Agent` | 3220 |
| `Agent` | 3224 |
| `form` | 3887 |
| `flexbuilde` | 4270 |
| `Item` | 4424 |
| `the` | 4425 |
| `flexbuilde` | 4516 |
| `account` | 4803 |
| `Item` | 5035 |
| `account` | 5190 |
| `account` | 5769 |
| `flexbuilde` | 5952 |
| `account` | 6664 |
| `account` | 6996 |
| `org` | 7651 |
| `Organization` | 7730 |
| `the` | 7731 |
| `rule` | 7764 |
| `account` | 8784 |
| `Organization` | 8940 |
| `Organization` | 8941 |
| `account` | 8975 |
| `Organization` | 9131 |
| `the` | 9132 |
| `Organization` | 9146 |
| `the` | 9147 |
| `flexbuilde` | 9422 |
| `Code` | 9613 |
| `Code` | 9643 |
| `other` | 9689 |
| `Code` | 9755 |
| `other` | 9799 |
| `account` | 12323 |
| `account` | 13114 |
| `org` | 13322 |
| `account` | 13535 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| rollback | 2402, 2420, 2443, 2461 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
