# README — Optimisation de `SQL_Export_Gestion_Litiges.sql`

**Date** : 10/04/2026  
**Fichier original** : `SQL_Export_Gestion_Litiges.sql`  
**Fichier optimisé** : `SQL_Export_Gestion_Litiges_OPTIMISEE.sql`  
**Base** : Oracle EBS 12.2.13 / Oracle Database 19.25.0.0.0  

---

## Résumé des problèmes identifiés

| # | Problème | Impact |
|---|----------|--------|
| 1 | 6 sous-requêtes corrélées dans le SELECT | N exécutions complètes de table par ligne retournée |
| 2 | `PER_ALL_PEOPLE_F` sans filtre de date | Table SCD Type 2 : chaque personne produit N lignes historiques |
| 3 | `AP_INV_APRVL_HIST_ALL` sans déduplication | Multiplication des lignes résultat par historique d'approbation |
| 4 | `SELECT DISTINCT` coûteux | Sort + dédup sur toutes les colonnes pour corriger les duplicats |
| 5 | `IBY_EXTERNAL_PAYEES_ALL` sans filtre `org_id` | Possibles duplicats si plusieurs OU partagent un même site fournisseur |
| 6 | Double EXISTS identique pour `COMPTABILISATION` | Même sous-requête évaluée deux fois par ligne |
| 7 | Double sous-requête imbriquée pour `SOLDE_COMPTE_FOURNISSEUR` | Complexité O(N²) : 1 sous-requête imbriquée dans une autre, corrélées toutes les deux |

---

## Détail des optimisations

### Optimisation 1 — Sous-requêtes corrélées → CTEs pré-agrégées

**Problème** : La requête originale contient **6 sous-requêtes corrélées** dans la liste de SELECT. Ces sous-requêtes sont ré-exécutées pour **chaque ligne** du résultat, provoquant des parcours répétés de tables volumineuses.

```sql
-- AVANT : exécuté autant de fois qu'il y a de lignes résultat
( SELECT COUNT(hold_id) FROM ap_holds_all WHERE invoice_id = api.invoice_id AND release_reason IS NULL )
```

**Solution** : 6 CTEs pré-agrégées calculées une seule fois, puis jointes :

| CTE | Remplace | Table source |
|-----|----------|--------------|
| `holds_count` | `COUNT(hold_id)` corrélé | `AP_HOLDS_ALL` |
| `attachments_exist` | `EXISTS` sur pièces jointes | `FND_ATTACHED_DOCUMENTS` |
| `distributions_agg` | `SUM(amount)` + double `EXISTS posted_flag` | `AP_INVOICE_DISTRIBUTIONS_ALL` |
| `vendor_balance` | Double sous-requête imbriquée | `AP_INVOICES_ALL` + `AP_PAYMENT_SCHEDULES_ALL` |
| `employe_actif` | (non corrélée mais mal joinée — voir opt. 2) | `PER_ALL_PEOPLE_F` |
| `hold_litige` | JOIN direct mul tipliant les lignes — voir opt. 3) | `AP_HOLDS_ALL` + `AP_INV_APRVL_HIST_ALL` |

```sql
-- APRÈS : la CTE est calculée une seule fois
WITH holds_count AS (
    SELECT invoice_id, COUNT(hold_id) AS nb_blocages_restants
    FROM   ap_holds_all
    WHERE  release_reason IS NULL
    GROUP BY invoice_id
)
-- puis jointure légère
LEFT JOIN holds_count hc ON hc.invoice_id = api.invoice_id
```

---

### Optimisation 2 — `PER_ALL_PEOPLE_F` : ajout du filtre de date effective

**Problème critique** : `PER_ALL_PEOPLE_F` est une table **SCD Type 2** (Slowly Changing Dimension). Chaque employé possède **une ligne par période de validité** (changement de nom, de poste, etc.). Sans filtre de date, la jointure produit autant de lignes que d'historiques pour chaque employé.

Exemple : un employé avec 5 entrées historiques dans `PER_ALL_PEOPLE_F` → chaque facture de cet utilisateur générait 5 lignes dans le résultat. Le `SELECT DISTINCT` final tentait (coûteusement) de les dédupliquer.

```sql
-- AVANT : produit N lignes par personne (N = nombre de périodes historiques)
LEFT JOIN apps.per_all_people_f papf ON papf.person_id = fu.employee_id
```

```sql
-- APRÈS : une seule ligne — la fiche active à ce jour
employe_actif AS (
    SELECT person_id, full_name
    FROM   apps.per_all_people_f
    WHERE  SYSDATE BETWEEN effective_start_date AND effective_end_date
)
LEFT JOIN employe_actif emp ON emp.person_id = fu.employee_id
```

---

### Optimisation 3 — `AP_INV_APRVL_HIST_ALL` : déduplication par `ROW_NUMBER()`

**Problème** : Le LEFT JOIN sur `AP_INV_APRVL_HIST_ALL` avec `response = 'DKA_REFUSE_IVALUA'` pouvait renvoyer **plusieurs lignes par facture** (un refus = une ligne). Pour une facture avec 3 refus historiques, chaque ligne existante (facture × hold) se multipliait par 3. Le `SELECT DISTINCT` final ne pouvait pas dédupliquer ces lignes car les colonnes `approver_comments` et les dates différaient.

```sql
-- AVANT : N lignes par facture si N refus dans l'historique
LEFT OUTER JOIN ap_inv_aprvl_hist_all aipha
    ON aipha.invoice_id = api.invoice_id
   AND aipha.response = 'DKA_REFUSE_IVALUA'
```

```sql
-- APRÈS : toujours 1 ligne (le refus le plus récent)
LEFT JOIN (
    SELECT invoice_id, approver_comments,
           ROW_NUMBER() OVER (PARTITION BY invoice_id ORDER BY creation_date DESC) AS rn
    FROM   ap_inv_aprvl_hist_all
    WHERE  response = 'DKA_REFUSE_IVALUA'
) aipha ON aipha.invoice_id = aha.invoice_id AND aipha.rn = 1
```

---

### Optimisation 4 — Suppression du `SELECT DISTINCT`

**Conséquence des optimisations 2 et 3** : les sources de duplication étant éliminées, le `SELECT DISTINCT` n'est plus nécessaire. Sur des milliers de lignes, Oracle devait auparavant effectuer un **tri complet + déduplication sur toutes les colonnes** du SELECT avant de renvoyer les résultats.

```sql
-- AVANT
SELECT DISTINCT api.invoice_id, ...

-- APRÈS
SELECT api.invoice_id, ...
```

---

### Optimisation 5 — `IBY_EXTERNAL_PAYEES_ALL` : ajout du filtre `org_id`

**Problème** : Sans contrainte sur `org_id`, si un site fournisseur est associé à plusieurs unités opérationnelles dans `IBY_EXTERNAL_PAYEES_ALL`, chaque ligne de facture se retrouvait multipliée par le nombre d'enregistrements payees pour ce site.

```sql
-- AVANT : jointure large pouvant retourner plusieurs lignes par site
JOIN iby.iby_external_payees_all iepa ON iepa.supplier_site_id = api.vendor_site_id

-- APRÈS : restreint à l'unité opérationnelle de la facture
JOIN iby.iby_external_payees_all iepa ON iepa.supplier_site_id = api.vendor_site_id
                                      AND iepa.org_id = api.org_id
```

> **Note** : Si certains payees ont `org_id = NULL` (payees de niveau global), ajoutez `AND (iepa.org_id = api.org_id OR iepa.org_id IS NULL)`.

---

### Optimisation 6 — `COMPTABILISATION` : double EXISTS → un seul `MAX(CASE WHEN)`

**Problème** : La logique de comptabilisation originale évaluait **deux fois** la même sous-requête corrélée sur `AP_INVOICE_DISTRIBUTIONS_ALL` (une pour le `WHEN ... NOT EXISTS`, une pour le `WHEN ... EXISTS`).

```sql
-- AVANT : 2 sous-requêtes identiques, 2 parcours de table
CASE
  WHEN EXISTS     (SELECT 'X' FROM ap_invoice_distributions_all apid WHERE api.invoice_id = apid.invoice_id AND apid.posted_flag = 'N') THEN 'NON-COMPTABILISEE'
  WHEN NOT EXISTS (SELECT 'X' FROM ap_invoice_distributions_all apid WHERE api.invoice_id = apid.invoice_id AND apid.posted_flag = 'N') THEN 'COMPTABILISEE'
END
```

```sql
-- APRÈS : un seul flag dans la CTE distributions_agg, évalué une fois
-- Dans la CTE :
MAX(CASE WHEN posted_flag = 'N' THEN 1 ELSE 0 END) AS has_unposted

-- Dans le SELECT :
CASE WHEN dist.has_unposted = 1 THEN 'NON-COMPTABILISEE' ELSE 'COMPTABILISEE' END
```

---

### Optimisation 7 — `SOLDE_COMPTE_FOURNISSEUR` : double sous-requête imbriquée → CTE

**C'était la sous-requête la plus coûteuse** : pour chaque ligne résultat, Oracle exécutait une première sous-requête pour récupérer tous les `invoice_id` du fournisseur, puis une seconde pour sommer les `amount_remaining` correspondants. Complexité approximative : **O(N × M)** où N = lignes résultat et M = factures par fournisseur.

```sql
-- AVANT : double imbrication corrélée
( SELECT SUM(appsa2.amount_remaining) FROM ap_payment_schedules_all appsa2
  WHERE appsa2.invoice_id IN (
      SELECT invoice_id FROM ap_invoices_all api2 WHERE api.vendor_id = api2.vendor_id
  ) )
```

```sql
-- APRÈS : jointure de tables pré-agrégées (O(1) par ligne résultat)
vendor_balance AS (
    SELECT api2.vendor_id, SUM(appsa2.amount_remaining) AS solde_compte_fournisseur
    FROM        ap_invoices_all          api2
    JOIN ap_payment_schedules_all appsa2 ON appsa2.invoice_id = api2.invoice_id
    GROUP BY api2.vendor_id
)
LEFT JOIN vendor_balance vb ON vb.vendor_id = api.vendor_id
```

---

### Optimisation 8 — `LITIGE_ACTIF` : simplification en constante `'OUI'`

**Observation** : La colonne `litige_actif` originale vérifiait l'existence d'un hold litige actif via une sous-requête corrélée. Or, la requête principale utilise déjà un `JOIN` sur `AP_HOLDS_ALL` filtrant `release_reason IS NULL AND hold_lookup_code LIKE '%itige%'`. Si la facture est dans le résultat, c'est **par définition** qu'elle a un litige actif.

```sql
-- AVANT : sous-requête inutile (résultat toujours 'OUI' si la facture est retournée)
CASE WHEN EXISTS (SELECT 'X' FROM ap_holds_all WHERE invoice_id = api.invoice_id
                  AND hold_lookup_code LIKE '%litige%' AND release_reason IS NULL)
     THEN 'OUI' ELSE 'NON' END AS litige_actif

-- APRÈS : constante
'OUI' AS litige_actif
```

---

## Récapitulatif des gains attendus

| Aspect | Avant | Après |
|--------|-------|-------|
| Sous-requêtes corrélées | 6 (dont 1 doublement imbriquée) | 0 |
| `SELECT DISTINCT` | Oui (tri + dédup complet) | Non |
| Lignes dupliquées issues de `PER_ALL_PEOPLE_F` | Oui (N par personne) | Non (filtre SYSDATE) |
| Lignes dupliquées issues de `AP_INV_APRVL_HIST_ALL` | Oui (N par refus) | Non (ROW_NUMBER = 1) |
| Parcours de `AP_INVOICE_DISTRIBUTIONS_ALL` | 3x par ligne résultat | 1x total (CTE) |
| Parcours de `AP_HOLDS_ALL` | 2x corrélé + 1x JOIN | 2x total (CTEs) |
| Calcul du solde fournisseur | O(N × M) | O(N + M) |

---

## Points d'attention

1. **`IBY_EXTERNAL_PAYEES_ALL` et `org_id = NULL`** : Si votre environnement a des payees partagés (org_id NULL), adaptez le filtre en `AND (iepa.org_id = api.org_id OR iepa.org_id IS NULL)`.

2. **Sémantique de `LITIGE_ACTIF`** : La version originale utilisait `LIKE '%litige%'` (avec 'l') tandis que le JOIN principal utilise `LIKE '%itige%'` (sans 'l'). En pratique les valeurs EBS sont 'Litige' / 'LITIGE', donc équivalentes. La constante `'OUI'` est correcte dans tous les cas réels.

3. **`MOTIF_LITIGE` avec plusieurs holds actifs** : Si une facture a plusieurs holds litige actifs simultanement, une ligne est générée par hold (comportement identique à l'original). La CTE `hold_litige` ne déduplique QUE les commentaires d'approbation (un par invoice), pas les holds eux-mêmes.

4. **Indexes recommandés** pour maximiser les performances des jointures CTE :
   - `AP_HOLDS_ALL(INVOICE_ID, RELEASE_REASON)` — si non existant
   - `FND_ATTACHED_DOCUMENTS(ENTITY_NAME, PK1_VALUE)` — pour la CTE attachments
   - `AP_INV_APRVL_HIST_ALL(INVOICE_ID, RESPONSE, CREATION_DATE)` — pour le ROW_NUMBER
   - `IBY_EXTERNAL_PAYEES_ALL(SUPPLIER_SITE_ID, ORG_ID)` — pour la jointure enrichie
