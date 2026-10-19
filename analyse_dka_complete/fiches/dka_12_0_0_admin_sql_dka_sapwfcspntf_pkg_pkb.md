# DKA_SAPWFCSPNTF_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPWFCSPNTF_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPWFCSPNTF_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 200 ; encodage : cp1252 (repli). SHA-256 : `e3ce7e46ecaf7adc52d4184200c1d1672b91ae7a6efccf7399d610726d78d35a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main` | 41 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `wf_notifications` | 52 |
| `DKA_STRANSCO_HEADERS` | 58 |
| `ap_invoices_interface` | 64 |
| `wf_notifications` | 76 |
| `DKA_STRANSCO_HEADERS` | 82 |
| `ap_holds_all` | 87 |
| `wf_items` | 114 |
| `wf_notifications` | 129 |
| `dual` | 149 |
| `AP_INVOICES_ALL` | 153 |
| `AP_INV_APRVL_HIST` | 156 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 107 |
| `dka_tools_pkg.put_log_message` | 109 |
| `wf_engine.abortprocess` | 120 |
| `wf_notification.cancel` | 134 |
| `dka_tools_pkg.put_log_message` | 193 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 187 |
| when_others | 190 |
| workflow | 120 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
