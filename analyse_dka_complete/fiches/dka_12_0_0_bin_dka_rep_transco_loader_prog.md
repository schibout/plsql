# DKA_REP_TRANSCO_LOADER.prog

Source : [dka/12.0.0/bin/DKA_REP_TRANSCO_LOADER.prog](../../dka/12.0.0/bin/DKA_REP_TRANSCO_LOADER.prog).

Famille proposée par convention de nommage : **Contrôles transversaux**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 128 ; encodage : utf-8. SHA-256 : `74f1a307db25528b79a3fb0a4a596edd6645e970b7d6e6a2c25d053b4bba571e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_programs_vl` | 40 |

## Références de forme appel package.membre

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

| Élément | Ligne source |
|---|---:|
| `$DKA_TOP/bin/DKA_REP_TRANSCO_SQLLOADER.sh` | 83 |

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| sqlplus | 35 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REP_TRANSCO_LOADER / DKA | `DKA_REP_TRANSCO_LOADER` | dka/12.0.0/admin/import/DKA_REP_TRANSCO_LOADER_F.prt:460 |
| DKA_REP_TRANSCO_LOADER / DKA | `DKA_REP_TRANSCO_LOADER` | dka/12.0.0/admin/import/DKA_REP_TRANSCO_LOADER_F.prt:460 |
| DKA_REP_TRANSCO_LOADER / DKA | `DKA_REP_TRANSCO_LOADER` | dka/12.0.0/admin/import/DKA_REP_TRANSCO_LOADER_US.prt:460 |
| DKA_REP_TRANSCO_LOADER / DKA | `DKA_REP_TRANSCO_LOADER` | dka/12.0.0/admin/import/DKA_REP_TRANSCO_LOADER_US.prt:460 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
