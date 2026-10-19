# DKA_IAPEMPLNOT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IAPEMPLNOT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IAPEMPLNOT_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 380 ; encodage : cp1252 (repli). SHA-256 : `02a0d36c8e966c58b33efaa6afc89e37efae0c9b30ddcbb113e2919d447298ce`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `CALCUL_DATE_SITUATION` | 44 |
| `Main` | 72 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `per_all_people_f` | 89 |
| `per_all_assignments_f` | 97 |
| `per_all_people_f` | 103 |
| `per_all_assignments_f` | 106 |
| `per_all_people_f` | 113 |
| `per_all_assignments_f` | 134 |
| `per_all_people_f` | 142 |
| `per_all_assignments_f` | 147 |
| `DKA_IAPEMPLNOT_INTERFACE` | 261 |
| `per_all_people_f` | 299 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 203 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 204 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 205 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 207 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 210 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 211 |
| `dka_tools_pkg.put_debug_message` | 218 |
| `dka_tools_pkg.put_debug_message` | 224 |
| `dka_tools_pkg.put_debug_message` | 229 |
| `dka_tools_pkg.put_debug_message` | 333 |
| `dka_tools_pkg.put_debug_message` | 340 |
| `dka_tools_pkg.put_debug_message` | 344 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 351 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 353 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 355 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 356 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 357 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 358 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 359 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 368 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 369 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 370 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 371 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 372 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 360 |
| rollback | 363 |
| when_others | 338, 362 |
| truncate | 192 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IAPEMPLNOT / DKA | `DKA_IAPEMPLNOT_PKG.Main` | dka/12.0.0/admin/import/DKA_IAPEMPLNOT.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
