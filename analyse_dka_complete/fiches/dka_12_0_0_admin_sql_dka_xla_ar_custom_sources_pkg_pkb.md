# DKA_XLA_AR_CUSTOM_SOURCES_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_XLA_AR_CUSTOM_SOURCES_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_XLA_AR_CUSTOM_SOURCES_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 427 ; encodage : cp1252 (repli). SHA-256 : `4349424420c617cf7f14f426bd2f39bc9c978b067bbde3839d8c18ea25d24288`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Trace` | 47 |
| `Trace` | 59 |
| `Init_Module` | 70 |
| `Init_Module` | 92 |
| `Exit_Module` | 101 |
| `Exit_Module` | 112 |
| `get_Rcpt_Customer_Detail` | 132 |
| `get_hz_cust_acct_sites_att8` | 209 |
| `get_profile_class` | 288 |
| `get_tax_code` | 357 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ar_cash_receipt_history_all` | 166 |
| `ar_cash_receipts_all` | 167 |
| `hz_cust_accounts_all` | 169 |
| `hz_parties` | 171 |
| `hz_cust_site_uses_all` | 173 |
| `hz_cust_acct_sites_all` | 242 |
| `HZ_CUST_ACCT_SITES_ALL` | 253 |
| `hz_customer_profiles` | 320 |
| `ra_customer_trx_lines_all` | 386 |
| `ZX_LINES` | 398 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_log.string` | 53 |
| `Fnd_Profile.Put` | 75 |
| `Fnd_Profile.Put` | 76 |
| `Fnd_Profile.Put` | 77 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 58, 91, 111, 191, 271, 338, 418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
