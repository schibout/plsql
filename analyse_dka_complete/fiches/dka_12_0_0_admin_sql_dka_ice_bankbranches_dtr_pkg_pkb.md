# DKA_ICE_BANKBRANCHES_DTR_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_ICE_BANKBRANCHES_DTR_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_ICE_BANKBRANCHES_DTR_PKG.pkb).

Famille proposée par convention de nommage : **Banques / trésorerie**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 365 ; encodage : utf-8. SHA-256 : `c1d8816c1b6a8bff4ba44965ce97daa04bc17c95b9fc1e019a0e6d8dde145721`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `p_put_debug_message` | 41 |
| `p_validate` | 58 |
| `p_check_directory` | 81 |
| `p_extract_data` | 115 |
| `p_extract_data` | 176 |
| `p_extract_data` | 226 |
| `output_header` | 241 |
| `p_bilan` | 285 |
| `main` | 322 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `all_directories` | 84 |
| `DUAL` | 130 |
| `DKA_BANK_BRANCHES_V` | 165 |
| `fnd_concurrent_programs` | 253 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 45 |
| `Fnd_File.put_line` | 173 |
| `Fnd_File.put_line` | 174 |
| `Fnd_File.put_line` | 175 |
| `Fnd_File.put_line` | 189 |
| `Fnd_File.put_line` | 208 |
| `Fnd_File.put_line` | 211 |
| `Fnd_File.put_line` | 227 |
| `Fnd_File.put_line` | 265 |
| `Fnd_File.put_line` | 266 |
| `Fnd_File.put_line` | 268 |
| `Fnd_File.put_line` | 270 |
| `Fnd_File.put_line` | 273 |
| `Fnd_File.put_line` | 289 |
| `Fnd_File.put_line` | 290 |
| `Fnd_File.put_line` | 291 |
| `Fnd_File.put_line` | 292 |
| `Fnd_File.put_line` | 293 |
| `Fnd_File.put_line` | 294 |
| `Fnd_File.put_line` | 295 |
| `Fnd_File.put_line` | 300 |
| `Fnd_File.put_line` | 301 |
| `Fnd_File.put_line` | 302 |
| `Fnd_File.put_line` | 305 |
| `Fnd_File.put_line` | 307 |
| `Fnd_File.put_line` | 332 |
| `fnd_date.canonical_to_date` | 337 |
| `fnd_date.canonical_to_date` | 338 |
| `Fnd_File.put_line` | 344 |
| `Fnd_File.put_line` | 350 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 214 |
| when_others | 225, 260, 357 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_ICE_BANKBRANCHES_DTR / DKA | `DKA_ICE_BANKBRANCHES_DTR_PKG.main` | dka/12.0.0/admin/import/DKA_ICE_BANKBRANCHES_DTR.prt:475 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
