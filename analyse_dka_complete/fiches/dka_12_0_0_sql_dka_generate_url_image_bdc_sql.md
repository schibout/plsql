# DKA_GENERATE_URL_IMAGE_BDC.sql

Source : [dka/12.0.0/sql/DKA_GENERATE_URL_IMAGE_BDC.sql](../../dka/12.0.0/sql/DKA_GENERATE_URL_IMAGE_BDC.sql).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 160 ; encodage : utf-8. SHA-256 : `e95bfd8231fbc092189d82de0f3307d3484a45a04b8134706b724cccb7713788`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `APPS` | 1 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_PARAMETERS` | 22 |
| `DKA_PARAMETERS` | 31 |
| `DKA_PARAMETERS` | 40 |
| `DKA_PARAMETERS` | 49 |
| `DKA_JMETER_ST.EXTRACTION_BDC` | 59 |
| `DKA_JMETER_ST.EXTRACTION_BDC` | 64 |
| `APPS.FND_ATTACHED_DOCUMENTS` | 66 |
| `APPS.PO_HEADERS_ALL` | 67 |
| `APPS.FND_DOCUMENTS` | 69 |
| `APPS.FND_ATTACHED_DOCUMENTS` | 95 |
| `APPS.PO_HEADERS_ALL` | 96 |
| `APPS.FND_DOCUMENTS` | 98 |
| `FND_LOB_ACCESS` | 100 |
| `FND_LOB_ACCESS` | 114 |
| `DKA_JMETER_ST.EXTRACTION_BDC` | 118 |
| `DKA_JMETER_ST.EXTRACTION_BDC` | 124 |
| `DKA_JMETER_ST.EXTRACTION_BDC` | 135 |
| `DKA_JMETER_ST.EXTRACTION_BDC` | 145 |
| `DKA_JMETER_ST.EXTRACTION_BDC` | 151 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `DKA_JMETER_ST.EXTRACTION_BDC` | 64 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 61, 111, 121, 132, 143, 149, 155 |
| suppression | 59 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
