# DKA_GENERATE_URL_IMAGE_FACTURE.sql

Source : [dka/12.0.0/sql/DKA_GENERATE_URL_IMAGE_FACTURE.sql](../../dka/12.0.0/sql/DKA_GENERATE_URL_IMAGE_FACTURE.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 88 ; encodage : utf-8. SHA-256 : `eb5ca633ed708852d8f695de5ce58b75c6fb1c8555d7dec7b8565e1a1acc5df2`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `APPS` | 1 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_JMETER_ST.EXTRACTION_FACTURE` | 12 |
| `DKA_PARAMETERS` | 21 |
| `DKA_JMETER_ST.EXTRACTION_FACTURE` | 29 |
| `APPS.FND_ATTACHED_DOCUMENTS` | 46 |
| `APPS.AP_INVOICES_ALL` | 47 |
| `APPS.FND_DOCUMENTS` | 49 |
| `FND_DOCUMENT_CATEGORIES_TL` | 51 |
| `APPS.FND_LOB_ACCESS` | 55 |
| `APPS.FND_DOCUMENTS_TL` | 57 |
| `FND_DOCUMENT_DATATYPES` | 61 |
| `FND_LOB_ACCESS` | 76 |
| `DKA_JMETER_ST.EXTRACTION_FACTURE` | 79 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_JMETER_ST.EXTRACTION_FACTURE` | 29 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 14, 73, 83 |
| suppression | 12 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
