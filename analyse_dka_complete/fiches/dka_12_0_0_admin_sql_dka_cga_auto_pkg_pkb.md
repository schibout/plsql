# DKA_CGA_AUTO_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_CGA_AUTO_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_CGA_AUTO_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 151 ; encodage : utf-8. SHA-256 : `a12ba9878a0e6f1adf04721772a5a83fc856ce6b6d416fd558c9a9538630adfb`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `AUTO_CGA` | 19 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `hr_operating_units` | 35 |
| `DKA_SPOBON_ANNEXE` | 37 |
| `hr_operating_units` | 45 |
| `Fnd_User` | 52 |
| `Fnd_Document_Categories_Tl` | 62 |
| `Fnd_Document_Datatypes` | 72 |
| `Fnd_Documents_vl` | 82 |
| `Fnd_Documents_vl` | 90 |
| `DKA_SPOBON_ANNEXE` | 101 |
| `DKA_SPOBON_ANNEXE` | 118 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 55 |
| `Fnd_File.put_line` | 65 |
| `Fnd_File.put_line` | 75 |
| `Fnd_File.put_line` | 85 |
| `Fnd_File.put_line` | 86 |
| `Fnd_File.put_line` | 93 |
| `Fnd_File.put_line` | 94 |
| `Fnd_File.put_line` | 135 |
| `Fnd_File.put_line` | 138 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 140 |
| when_others | 143 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_CGA_AUTO_EXEC / DKA | `DKA_CGA_AUTO_PKG.AUTO_CGA` | dka/12.0.0/admin/import/DKA_CGA_AUTO_PKG.prt:479 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
