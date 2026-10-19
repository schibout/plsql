# DKA_FUSPOMAJPFTF_Maitre_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_FUSPOMAJPFTF_Maitre_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_FUSPOMAJPFTF_Maitre_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 286 ; encodage : cp1252 (repli). SHA-256 : `df7cffc09e4e66a5c044cb6f1fb6740effb25c1d1b3291c6d51008038b7f8c6a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 33 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_requisition_headers_all` | 41 |
| `HR_ORGANIZATION_UNITS` | 52 |
| `HR_ORGANIZATION_UNITS` | 63 |
| `PO_HEADERS_ALL` | 75 |
| `HR_ORGANIZATION_UNITS` | 89 |
| `HR_ORGANIZATION_UNITS` | 100 |
| `fnd_responsibility` | 155 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_PROFILE.VALUE` | 132 |
| `Fnd_File.put_line` | 136 |
| `Fnd_File.put_line` | 137 |
| `fnd_file.put_line` | 140 |
| `fnd_file.put_line` | 141 |
| `fnd_file.put_line` | 142 |
| `fnd_file.put_line` | 147 |
| `fnd_file.put_line` | 148 |
| `FND_GLOBAL.APPS_INITIALIZE` | 160 |
| `Fnd_Request.set_org_id` | 167 |
| `fnd_file.put_line` | 175 |
| `fnd_file.put_line` | 176 |
| `Fnd_Request.submit_request` | 184 |
| `Fnd_File.put_line` | 196 |
| `Fnd_File.put_line` | 202 |
| `Fnd_File.put_line` | 203 |
| `fnd_file.put_line` | 211 |
| `fnd_file.put_line` | 212 |
| `fnd_file.put_line` | 213 |
| `Fnd_File.put_line` | 218 |
| `Fnd_Concurrent.wait_for_request` | 222 |
| `Fnd_file.put_line` | 231 |
| `Fnd_File.put_line` | 237 |
| `Fnd_File.put_line` | 240 |
| `Fnd_File.put_line` | 245 |
| `Fnd_File.put_line` | 248 |
| `fnd_file.put_line` | 258 |
| `Fnd_File.put_line` | 263 |
| `Fnd_File.put_line` | 271 |
| `Fnd_File.put_line` | 278 |
| `Fnd_File.put_line` | 279 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKAFUSPOMAJPFTF` | 184 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 198 |
| when_others | 170, 274 |
| soumission | 184 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKAFUSPOMAJPFTF_MAITRE / DKA | `DKA_FUSPOMAJPFTF_Maitre_PKG.Main` | dka/12.0.0/admin/import/DKA_FUSPOMAJPFTF_MAITRE.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
