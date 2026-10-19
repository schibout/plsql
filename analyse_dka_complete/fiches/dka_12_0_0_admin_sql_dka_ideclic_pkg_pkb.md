# DKA_IDECLIC_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IDECLIC_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IDECLIC_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1217 ; encodage : cp1252 (repli). SHA-256 : `87d3ef1fa3f270ca30d81a014001dde7d0c99b7c2e5100d8828005384a7d7fac`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `calcul_solde` | 52 |
| `extract_i00rc` | 309 |
| `main` | 1135 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_period_statuses` | 103 |
| `gl_period_statuses` | 125 |
| `gl_period_statuses` | 150 |
| `gl_ledgers` | 177 |
| `gl_ledgers` | 211 |
| `gl_ledgers` | 247 |
| `hz_cust_site_uses_all` | 375 |
| `gl_access_set_ledgers` | 392 |
| `dka_i00rc` | 732 |
| `dka_i00rc` | 828 |
| `gl_period_statuses` | 1158 |
| `gl_access_set_ledgers` | 1163 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 292 |
| `dka_tools_pkg.put_log_message` | 293 |
| `fnd_profile.value` | 392 |
| `dka_tools_pkg.put_debug_message` | 727 |
| `dka_tools_pkg.put_log_message` | 750 |
| `dka_tools_pkg.put_log_message` | 886 |
| `dka_tools_pkg.put_debug_message` | 888 |
| `dka_tools_pkg.put_log_message` | 895 |
| `dka_tools_pkg.put_log_message` | 896 |
| `dka_tools_pkg.put_debug_message` | 1144 |
| `fnd_profile.value` | 1163 |
| `dka_tools_pkg.put_log_message` | 1167 |
| `dka_tools_pkg.put_log_message` | 1168 |
| `dka_tools_pkg.put_debug_message` | 1202 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 882, 1186 |
| rollback | 1206, 1209 |
| when_others | 291, 894, 1166, 1208 |
| suppression | 732 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IDECLIC / DKA | `DKA_IDECLIC_PKG.MAIN` | dka/12.0.0/admin/import/DKA_IDECLIC.prt:483 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
