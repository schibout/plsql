# DKA_EXTR_DA_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_EXTR_DA_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_EXTR_DA_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 422 ; encodage : utf-8. SHA-256 : `ad1f3af1ada472d6eae4f5a476ead1a11c91a4c9233e5d6c8d9e6161bc067354`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `dka_inserer_element` | 24 |
| `MAIN` | 61 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `HR.PER_ALL_PEOPLE_F` | 121 |
| `HR.PER_ALL_ASSIGNMENTS_F` | 122 |
| `HR.PER_JOBS` | 124 |
| `HR.HR_ALL_ORGANIZATION_UNITS` | 126 |
| `HR.PER_ALL_PEOPLE_F` | 133 |
| `HR.PER_ALL_ASSIGNMENTS_F` | 138 |
| `HR.PER_JOBS` | 142 |
| `PO.PO_REQUISITION_HEADERS_ALL` | 172 |
| `HR.HR_ALL_ORGANIZATION_UNITS` | 173 |
| `PO.PO_REQUISITION_LINES_ALL` | 175 |
| `PO.PO_REQ_DISTRIBUTIONS_ALL` | 177 |
| `INV.MTL_CATEGORIES_B` | 179 |
| `INV.MTL_CATEGORIES_TL` | 181 |
| `PA.PA_TASKS` | 184 |
| `D` | 186 |
| `ap_suppliers` | 263 |
| `INV.MTL_CATEGORIES_TL` | 285 |
| `ap_suppliers` | 299 |
| `PER_ALL_PEOPLE_F` | 316 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_Tools_Pkg.put_log_message` | 52 |
| `dka_Tools_Pkg.put_log_message` | 207 |
| `fnd_date.canonical_to_date` | 209 |
| `fnd_date.canonical_to_date` | 210 |
| `dka_Tools_Pkg.put_log_message` | 212 |
| `dka_Tools_Pkg.put_log_message` | 214 |
| `dka_Tools_Pkg.put_log_message` | 215 |
| `dka_Tools_Pkg.put_log_message` | 216 |
| `dka_Tools_Pkg.put_log_message` | 217 |
| `dka_Tools_Pkg.put_log_message` | 218 |
| `dka_Tools_Pkg.put_log_message` | 219 |
| `dka_Tools_Pkg.put_log_message` | 220 |
| `dka_Tools_Pkg.put_log_message` | 221 |
| `dka_Tools_Pkg.put_log_message` | 222 |
| `dka_Tools_Pkg.put_log_message` | 223 |
| `dka_Tools_Pkg.put_log_message` | 224 |
| `dka_Tools_Pkg.put_log_message` | 225 |
| `dka_Tools_Pkg.put_log_message` | 226 |
| `dka_Tools_Pkg.put_log_message` | 227 |
| `dka_Tools_Pkg.put_log_message` | 244 |
| `fnd_file.put_line` | 401 |
| `fnd_file.put_line` | 404 |
| `dka_Tools_Pkg.put_log_message` | 410 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 50, 277, 291, 304, 324, 412 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_EXTR_DA / DKA | `DKA_EXTR_DA_PKG.main` | dka/12.0.0/admin/import/DKA_EXTRAC_DA.prt:1045 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
