# DKA_SPOMAJCATKPI_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOMAJCATKPI_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOMAJCATKPI_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 725 ; encodage : cp1252 (repli). SHA-256 : `92149c9f67cc2f64f7c194f6c153795e62db84f184e0573b6b74b1260966b9cd`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 50 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_sicxrechcat_hist` | 54 |
| `icx_cat_items_ctx_hdrs_tlp` | 274 |
| `icx_por_category_order_map` | 308 |
| `icx_por_category_order_map` | 322 |
| `icx_cat_items_ctx_hdrs_tlp` | 620 |
| `icx_por_category_order_map` | 654 |
| `icx_por_category_order_map` | 668 |
| `dka_sicxrechcat_hist` | 683 |
| `dka_sicxrechcat_hist` | 696 |
| `dka_sicxrechcat_hist` | 704 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 372 |
| `dka_tools_pkg.put_log_message` | 396 |
| `dka_tools_pkg.put_log_message` | 412 |
| `dka_tools_pkg.put_log_message` | 713 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 711 |
| when_others | 716 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOMAJCATKPI / DKA | `dka_spomajcatkpi_pkg.main` | dka/12.0.0/admin/import/DKA_SPOMAJCATKPI_F_PRG.ldt:420 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
