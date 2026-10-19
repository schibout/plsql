# DKA_SPOMAJPD_PKG.PKB

Source : [dka/12.0.0/admin/sql/DKA_SPOMAJPD_PKG.PKB](../../dka/12.0.0/admin/sql/DKA_SPOMAJPD_PKG.PKB).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 172 ; encodage : cp1252 (repli). SHA-256 : `7975bc0160484f4ca6d6f4c7d83551f697b62471b32f9a2b971f0fbe8ca3e5ed`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 36 |
| `main` | 90 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_programs` | 51 |
| `PO_HEADERS_ALL` | 118 |
| `PO_HEADERS_ALL` | 132 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 66 |
| `Fnd_File.put_line` | 67 |
| `Fnd_File.put_line` | 68 |
| `Fnd_File.put_line` | 69 |
| `Fnd_File.put_line` | 70 |
| `fnd_file.put_line` | 122 |
| `fnd_file.put_line` | 127 |
| `fnd_file.put_line` | 138 |
| `Fnd_File.put_line` | 150 |
| `Fnd_File.put_line` | 151 |
| `Fnd_File.put_line` | 152 |
| `Fnd_File.put_line` | 153 |
| `Fnd_File.put_line` | 159 |
| `Fnd_File.put_line` | 160 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 59, 121, 155 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOMAJPD / DKA | `DKA_SPOMAJPD_PKG.main` | dka/12.0.0/admin/import/DKA_SPOMAJPD.prt:496 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
