# DKA_IGL_INTERFACE_EAI_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IGL_INTERFACE_EAI_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IGL_INTERFACE_EAI_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 552 ; encodage : cp1252 (repli). SHA-256 : `11ebd15661c0e13b54fa22b1e954793858e678e76455dce89c3ff5370dc16611`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 35 |
| `log_msg` | 49 |
| `get_user_eai` | 66 |
| `insert_interface_control` | 98 |
| `run_import` | 178 |
| `edition_output_entete` | 242 |
| `EDITION_OUTPUT` | 321 |
| `main` | 336 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_user` | 71 |
| `DUAL` | 112 |
| `DUAL` | 120 |
| `GL_JE_SOURCES` | 125 |
| `gl_interface_control` | 134 |
| `DKA_IGL_INTERFACE_EAI` | 251 |
| `FND_CONC_REQ_SUMMARY_V` | 277 |
| `FND_CONC_REQ_SUMMARY_V` | 290 |
| `FND_CONC_REQ_SUMMARY_V` | 302 |
| `DKA_IGL_INTERFACE_EAI` | 305 |
| `GL_INTERFACE` | 359 |
| `DKA_IGL_INTERFACE_EAI` | 366 |
| `gl_ledgers` | 402 |
| `gl_period_statuses` | 418 |
| `DKA_IGL_INTERFACE_EAI` | 462 |
| `GL_INTERFACE` | 479 |
| `GL_INTERFACE` | 495 |
| `DKA_IGL_INTERFACE_EAI` | 529 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 38 |
| `fnd_file.put_line` | 59 |
| `fnd_request.submit_request` | 198 |
| `Fnd_Stats.Gather_Table_Stats` | 514 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `GLLEZL` | 198 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 150, 214, 313, 383, 491, 507, 535 |
| when_others | 77, 155, 226, 281, 294, 319, 405, 425, 542 |
| soumission | 198 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IGL_INTERFACE_EAI / DKA | `DKA_IGL_INTERFACE_EAI_PKG.main` | dka/12.0.0/admin/import/DKA_IGL_INTERFACE_EAI.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
