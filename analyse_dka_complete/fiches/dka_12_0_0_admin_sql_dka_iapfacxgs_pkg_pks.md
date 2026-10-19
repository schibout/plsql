# DKA_IAPFACXGS_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_IAPFACXGS_PKG.pks](../../dka/12.0.0/admin/sql/DKA_IAPFACXGS_PKG.pks).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 122 ; encodage : cp1252 (repli). SHA-256 : `2c66bf872eef6a86269d64ffa8455acef95a3fa16e5f4d032821fa2c14a9c0b3`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_id_br` | 34 |
| `get_num_br` | 47 |
| `get_packing_slip` | 60 |
| `get_num_ligne_br` | 73 |
| `transaction_type` | 88 |
| `import` | 97 |
| `control_double` | 105 |
| `populate_xgs_tables` | 110 |
| `populate_zci_tables` | 113 |
| `populate_dsp_tables` | 116 |

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
| DKA_IAPFACXGS / DKA | `dka_iapfacxgs_pkg.import` | dka/12.0.0/admin/import/DKA_IAPFACXGS.prt:419 |
| DKA_POPULATE_DSP_TABLES / DKA | `DKA_IAPFACXGS_PKG.populate_dsp_tables` | dka/12.0.0/admin/import/DKA_POPULATE_DSP_TABLES.ldt:419 |
| DKA_POPULATE_XGS_TABLES / DKA | `DKA_IAPFACXGS_PKG.populate_xgs_tables` | dka/12.0.0/admin/import/DKA_POPULATE_XGS_TABLES.prt:419 |
| DKA_POPULATE_ZCI_TABLES / DKA | `DKA_IAPFACXGS_PKG.populate_zci_tables` | dka/12.0.0/admin/import/DKA_POPULATE_ZCI_TABLES.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
