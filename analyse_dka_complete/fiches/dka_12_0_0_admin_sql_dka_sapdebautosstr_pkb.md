# DKA_SAPDEBAUTOSSTR.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPDEBAUTOSSTR.pkb](../../dka/12.0.0/admin/sql/DKA_SAPDEBAUTOSSTR.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 416 ; encodage : cp1252 (repli). SHA-256 : `ebeaca9eea71b49248394c5d942aa7e2fd111dbff7c2b1c14a507b6758b95c5a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 56 |
| `output_end` | 90 |
| `output_start` | 102 |
| `writeout` | 123 |
| `Report_Bilan` | 157 |
| `leve_blocage` | 240 |
| `main` | 354 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ap_invoice_lines_all` | 256 |
| `ap_holds_all` | 302 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 27 |
| `Fnd_File.put_line` | 66 |
| `Fnd_File.put_line` | 67 |
| `Fnd_File.put_line` | 68 |
| `Fnd_File.put_line` | 69 |
| `Fnd_File.put_line` | 70 |
| `Fnd_File.put_line` | 97 |
| `Fnd_File.put_line` | 98 |
| `Fnd_File.put_line` | 99 |
| `Fnd_File.put_line` | 109 |
| `Fnd_File.put_line` | 110 |
| `Fnd_File.put_line` | 111 |
| `FND_FILE.PUT_LINE` | 128 |
| `Fnd_File.put_line` | 134 |
| `Fnd_File.put_line` | 136 |
| `Fnd_File.put_line` | 137 |
| `Fnd_File.put_line` | 138 |
| `Fnd_File.put_line` | 139 |
| `Fnd_File.put_line` | 140 |
| `Fnd_File.put_line` | 165 |
| `fnd_file.put_line` | 180 |
| `fnd_file.put_line` | 181 |
| `fnd_file.put_line` | 182 |
| `Fnd_File.put_line` | 186 |
| `Fnd_File.put_line` | 187 |
| `Fnd_File.put_line` | 193 |
| `fnd_file.put_line` | 199 |
| `Fnd_File.put_line` | 201 |
| `Fnd_File.put_line` | 202 |
| `fnd_file.put_line` | 206 |
| `fnd_file.put_line` | 207 |
| `fnd_file.put_line` | 208 |
| `Fnd_File.put_line` | 217 |
| `fnd_file.put_line` | 221 |
| `Fnd_File.put_line` | 227 |
| `Fnd_File.put_line` | 228 |
| `dka_tools_pkg.put_debug_message` | 293 |
| `Fnd_File.put_line` | 378 |
| `Fnd_File.put_line` | 379 |
| `Fnd_File.put_line` | 380 |
| `Fnd_File.put_line` | 381 |
| `Fnd_File.put_line` | 390 |
| `Fnd_File.put_line` | 391 |
| `Fnd_File.put_line` | 398 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 313 |
| when_others | 131, 223, 393 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
