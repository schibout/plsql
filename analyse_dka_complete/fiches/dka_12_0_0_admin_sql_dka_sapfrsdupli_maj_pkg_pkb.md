# DKA_SAPFRSDUPLI_MAJ_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPFRSDUPLI_MAJ_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPFRSDUPLI_MAJ_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 320 ; encodage : cp1252 (repli). SHA-256 : `12f10bcd9de289794b201078ba1752cc9da62860e3c9021b137c4e84148f941a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `writeout` | 36 |
| `sortie_traitement` | 63 |
| `entete_de_sortie` | 115 |
| `fin_de_sortie` | 136 |
| `MAJ_DATE_LANCEMENT` | 159 |
| `MAIN` | 179 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_PARAMETERS` | 165 |
| `fnd_concurrent_requests` | 167 |
| `ap_supplier_sites_all` | 194 |
| `DKA_PARAMETERS` | 231 |
| `fnd_responsibility` | 244 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 271 |
| `ap_supplier_sites_all` | 279 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 22 |
| `FND_FILE.PUT_LINE` | 41 |
| `Fnd_File.put_line` | 47 |
| `Fnd_File.put_line` | 49 |
| `Fnd_File.put_line` | 50 |
| `Fnd_File.put_line` | 51 |
| `Fnd_File.put_line` | 52 |
| `Fnd_File.put_line` | 53 |
| `FND_PROFILE.VALUE` | 246 |
| `FND_GLOBAL.APPS_INITIALIZE` | 247 |
| `DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR` | 263 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 44, 235, 253, 283 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPFRSDUPLI_MAJ / DKA | `DKA_SAPFRSDUPLI_MAJ_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SAPFRSDUPLI_MAJ_PRG.prt:417 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
