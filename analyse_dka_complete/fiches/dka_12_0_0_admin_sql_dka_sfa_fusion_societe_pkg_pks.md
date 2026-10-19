# DKA_SFA_FUSION_SOCIETE_PKG.pks

Source : [dka/12.0.0/admin/sql/DKA_SFA_FUSION_SOCIETE_PKG.pks](../../dka/12.0.0/admin/sql/DKA_SFA_FUSION_SOCIETE_PKG.pks).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 122 ; encodage : cp1252 (repli). SHA-256 : `ceaf263b48d602d23eab7409501db82e399266a272e5bb1dd2bd8de03e9f7e47`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `xxfa_accytddeprn_get_fnc` | 31 |
| `main_Ctr` | 52 |
| `main_export` | 68 |
| `main_import` | 84 |
| `main_control_insert` | 100 |
| `main_import_fa` | 117 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_stransco_lines` | 26 |

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
| DKA_SFAFUSIONSOC / DKA | `DKA_SFA_FUSION_SOCIETE_PKG.main_ctr` | dka/12.0.0/admin/import/DKA_SFAFUSIONSOC.prt:417 |
| DKA_SFAFUSIONSOCCTR / DKA | `dka_sfa_fusion_societe_pkg.main_control_insert` | dka/12.0.0/admin/import/DKA_SFAFUSIONSOCCTR.prt:417 |
| DKA_SFAFUSIONSOCEXT / DKA | `dka_sfa_fusion_societe_pkg.main_export` | dka/12.0.0/admin/import/DKA_SFAFUSIONSOCEXT.prt:417 |
| DKA_SFAFUSIONSOCIMP / DKA | `dka_sfa_fusion_societe_pkg.main_import` | dka/12.0.0/admin/import/DKA_SFAFUSIONSOCIMP.prt:474 |
| DKA_SFAFUSIONSOCIMPIMMO / DKA | `dka_sfa_fusion_societe_pkg.main_import_fa` | dka/12.0.0/admin/import/DKA_SFAFUSIONSOCIMPIMMO.prt:417 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
