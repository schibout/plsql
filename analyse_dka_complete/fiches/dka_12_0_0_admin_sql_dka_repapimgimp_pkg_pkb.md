# DKA_REPAPIMGIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPAPIMGIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPAPIMGIMP_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 390 ; encodage : cp1252 (repli). SHA-256 : `ef2145cd341c8fd6ac7570b3a80e514b9847930636e436d6c0297a5ebdabd873`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `log` | 61 |
| `output` | 69 |
| `Error` | 77 |
| `init` | 95 |
| `Create_attachment` | 108 |
| `import_image` | 232 |
| `import_blobs` | 280 |
| `new_org` | 289 |
| `MAIN` | 351 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `AP_INVOICES_ALL` | 37 |
| `HR_ALL_ORGANIZATION_UNITS` | 38 |
| `AP_SUPPLIER_SITES_ALL` | 39 |
| `AP_SUPPLIERS` | 40 |
| `FND_ATTACHED_DOCUMENTS` | 45 |
| `FND_DOCUMENTS` | 46 |
| `FND_DOCUMENTS_TL` | 47 |
| `FND_DOCUMENT_CATEGORIES_VL` | 100 |
| `fnd_lobs` | 126 |
| `DKA_AP_INV_LOBS` | 130 |
| `fnd_attached_documents` | 167 |
| `DKA_AP_INV_ATTACHED_DOCS` | 238 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 64 |
| `fnd_file.put_line` | 72 |
| `fnd_documents_pkg.insert_row` | 137 |
| `fnd_attached_documents_pkg.insert_row` | 175 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 372, 373 |
| rollback | 275, 375, 376 |
| when_others | 102, 225, 274, 344, 380 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPAPIMGIMP / DKA | `DKA_REPAPIMGIMP_PKG.MAIN` | dka/12.0.0/admin/import/DKA_REPAPIMGIMP.prt:539 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
