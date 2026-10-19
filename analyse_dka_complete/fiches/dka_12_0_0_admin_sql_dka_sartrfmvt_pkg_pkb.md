# DKA_SARTRFMVT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARTRFMVT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARTRFMVT_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 228 ; encodage : cp1252 (repli). SHA-256 : `9722344fa6b54fdcd68475463fd45b5e3bb2d1408b299ef9833870d98f06de17`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `cherche_period` | 16 |
| `cherche_next_period` | 95 |
| `main` | 144 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_period_statuses` | 39 |
| `gl_period_statuses` | 43 |
| `gl_period_statuses` | 113 |
| `gl_period_statuses` | 115 |
| `DKA_IARPAFAC_INTERFACE` | 163 |
| `fnd_responsibility` | 174 |
| `dka_iarpafac_interface` | 209 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_global.apps_initialize` | 177 |
| `dka_tools_pkg.put_debug_message` | 181 |
| `dka_tools_pkg.put_debug_message` | 182 |
| `dka_tools_pkg.put_debug_message` | 183 |
| `fnd_profile.VALUE` | 186 |
| `Fnd_File.put_line` | 190 |
| `Fnd_File.put_line` | 191 |
| `Fnd_File.put_line` | 216 |
| `Fnd_File.put_line` | 219 |
| `Fnd_File.put_line` | 221 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 215 |
| when_others | 62, 127 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
