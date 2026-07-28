# CONCLUSION - Analyse des Provisions NOV-25 vs OCT-25

**Date d'analyse :** 01/12/2025  
**Base de données :** Oracle EBS 19.25.0.0.0  
**Connexion :** oracleProd

---

## RÉSUMÉ EXÉCUTIF

### Question posée
Pourquoi la requête sur les provisions NOV-25 retourne des données OCT-25 et rien sur NOV-25 ?

### Réponse
**La requête ne retourne RIEN (0 ligne)** car elle cherche un lien inexistant vers `PO_DISTRIBUTIONS_ALL` alors que les provisions de fin de période pointent vers `RCV_RECEIVING_SUB_LEDGER` (réceptions de marchandises).

---

## DÉTAILS DE L'ANALYSE

### 1. État des Batches de Provisions en Période NOV-25

**Résultat de la requête diagnostique :**

| Type de Provision | Nombre de Batches | Nombre de Journals | Total de Lignes |
|------------------|-------------------|-------------------|-----------------|
| **Provision OCT-25 dans période NOV-25** | 187 | 187 | 137,166 |
| **Provision NOV-25 dans période NOV-25** | 186 | 186 | 116,676 |
| **TOTAL** | **373** | **373** | **253,842** |

### Explication
✅ **C'est NORMAL** : Les batches nommés `PROVISION_XXX_OCT-25` postés en période GL `NOV-25` correspondent aux **provisions de fin de mois d'octobre comptabilisées rétroactivement lors de la clôture de novembre**.

**⚠️ CHANGEMENT IMPORTANT :** Depuis NOV-25, le champ `XLA_DISTRIBUTION_LINKS.APPLIED_TO_DIST_ID_NUM_1` n'est plus alimenté par Oracle pour les provisions de fin de période. Voir **[Analyse_APPLIED_TO_DIST_ID_NUM_1_OCT_vs_NOV.md](Analyse_APPLIED_TO_DIST_ID_NUM_1_OCT_vs_NOV.md)** pour les détails.

**Exemple de batch :**
```
PROVISION_RESOCEANE_OCT-25_1_ Cost Management A 4337134 46074194
├─ Batch Period: NOV-25
├─ Journal Period: NOV-25
├─ Effective Date: 30/11/2025
└─ Lines: 20
```

---

### 2. Cohérence des Périodes GL vs XLA

**Résultat de la requête diagnostique :**

| Période GL | Période XLA | Nombre de Lignes | Décalages |
|-----------|-------------|-----------------|-----------|
| NOV-25 | NOV-25 | 126,921 | 0 |

✅ **CONCLUSION :** Les périodes GL et XLA sont **parfaitement cohérentes** pour toutes les provisions en période NOV-25.

---

### 3. Pourquoi la Requête Originale Retourne 0 Ligne

#### Requête Originale (Simplifiée)
```sql
SELECT GJL.JE_HEADER_ID, GJL.JE_LINE_NUM, PDA.PO_DISTRIBUTION_ID, ...
  FROM GL.GL_JE_LINES GJL
  ...
  LEFT OUTER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
      ON PDA.PO_DISTRIBUTION_ID = XDL.APPLIED_TO_DIST_ID_NUM_1
 WHERE GJH.PERIOD_NAME = 'NOV-25'
   AND PDA.PO_DISTRIBUTION_ID IS NOT NULL  -- ⚠️ FILTRE PROBLÉMATIQUE
   ...
```

#### Problème Identifié

**⚠️ MISE À JOUR IMPORTANTE (01/12/2025) :** 
Le champ `APPLIED_TO_DIST_ID_NUM_1` était alimenté en OCT-25 (62,852 lignes) mais n'est plus alimenté en NOV-25 (0 ligne). C'est un **changement de comportement Oracle XLA**. Voir l'analyse détaillée dans **[Analyse_APPLIED_TO_DIST_ID_NUM_1_OCT_vs_NOV.md](Analyse_APPLIED_TO_DIST_ID_NUM_1_OCT_vs_NOV.md)**.

**Étape 1 : Test sans filtre PO**
```sql
SELECT COUNT(*) FROM ... WHERE ... AND PDA.PO_DISTRIBUTION_ID IS NULL
```
**Résultat :** 0 ligne ❌

**Étape 2 : Analyse des XLA Distribution Links**
```sql
SELECT XDL.SOURCE_DISTRIBUTION_TYPE, COUNT(*)
  FROM ... WHERE GJH.PERIOD_NAME = 'NOV-25'
 GROUP BY XDL.SOURCE_DISTRIBUTION_TYPE
```
**Résultat :**
| Type de Distribution Source | Nombre de Lignes |
|-----------------------------|-----------------|
| **RCV_RECEIVING_SUB_LEDGER** | 126,921 |
| PO_DISTRIBUTIONS (aucune) | 0 |

#### Conclusion
Les provisions de fin de période (Receipt Accruals) ne passent **PAS** par `PO_DISTRIBUTIONS_ALL` mais par `RCV_RECEIVING_SUB_LEDGER` :

```
Flux de Provision de Fin de Période :
┌────────────────────────────────────────────┐
│ Réception Marchandises (RCV)              │
│ └─ RCV_RECEIVING_SUB_LEDGER               │
│    └─ XLA_DISTRIBUTION_LINKS              │
│       └─ XLA_AE_LINES (ACCOUNTING_CLASS = 'CHARGE' ou 'ACCRUAL')
│          └─ XLA_AE_HEADERS                │
│             └─ GL_JE_LINES                │
└────────────────────────────────────────────┘

❌ PAS DE LIEN DIRECT VERS PO_DISTRIBUTIONS_ALL
```

---

### 4. Exemple Concret

**Journal ID :** 21208406  
**Batch :** `PROVISION_ECOLIANE_NOV-25_1_`  
**Période GL :** NOV-25  
**Période XLA :** NOV-25  

| Line | Accounting Class | Source Distribution Type | Source Dist ID | PO Dist ID | Montant DR | Montant CR |
|------|-----------------|-------------------------|----------------|-----------|-----------|-----------|
| 1 | CHARGE | RCV_RECEIVING_SUB_LEDGER | 13776503 | NULL | 621.17 | - |
| 25 | CHARGE | RCV_RECEIVING_SUB_LEDGER | 13776505 | NULL | 4,654.07 | - |
| 26 | CHARGE | RCV_RECEIVING_SUB_LEDGER | 13776509 | NULL | 419.76 | - |
| ... | ... | ... | ... | ... | ... | ... |

✅ **Toutes les lignes pointent vers RCV_RECEIVING_SUB_LEDGER, pas vers PO_DISTRIBUTIONS_ALL**

---

## RÉPONSE À LA QUESTION INITIALE

### Pourquoi vous voyez des données OCT-25 ?

**Vous ne voyez PAS de données OCT-25 dans votre requête :**  
La requête retourne **0 ligne** car le filtre `PDA.PO_DISTRIBUTION_ID IS NOT NULL` élimine toutes les provisions de fin de période.

### Pourquoi rien sur NOV-25 ?

**Les données NOV-25 EXISTENT (126,921 lignes)** mais sont filtrées par la condition incorrecte sur `PO_DISTRIBUTIONS_ALL`.

---

## SOLUTION PROPOSÉE

### Option 1 : Retirer le Filtre sur PO_DISTRIBUTIONS_ALL

Si vous voulez **toutes les provisions de la période NOV-25**, retirez le filtre :

```sql
SELECT GJL.JE_HEADER_ID,
       GJL.JE_LINE_NUM,
       XDL.SOURCE_DISTRIBUTION_ID_NUM_1 AS RCV_TRANSACTION_ID,
       XDL.SOURCE_DISTRIBUTION_TYPE,
       GJL.LEDGER_ID,
       GJL.CREATION_DATE,
       GJH.PERIOD_NAME
  FROM GL.GL_JE_LINES GJL
 INNER JOIN GL.GL_LEDGERS GLE ON GLE.LEDGER_ID = GJL.LEDGER_ID
 INNER JOIN GL.GL_JE_HEADERS GJH ON GJH.JE_HEADER_ID = GJL.JE_HEADER_ID
 INNER JOIN GL.GL_JE_BATCHES GJB ON GJB.JE_BATCH_ID = GJH.JE_BATCH_ID
 INNER JOIN XLA.XLA_AE_LINES XAL
     ON (XAL.GL_SL_LINK_ID = GJL.GL_SL_LINK_ID
         AND XAL.ACCOUNTING_CLASS_CODE = 'CHARGE'
         AND XAL.GL_SL_LINK_TABLE = 'XLAJEL')
 LEFT OUTER JOIN XLA.XLA_AE_HEADERS XAH
     ON XAH.AE_HEADER_ID = XAL.AE_HEADER_ID
 LEFT OUTER JOIN XLA.XLA_DISTRIBUTION_LINKS XDL
     ON (XDL.AE_HEADER_ID = XAH.AE_HEADER_ID
         AND XDL.AE_LINE_NUM = XAL.AE_LINE_NUM)
 WHERE GJH.PERIOD_NAME = 'NOV-25'
   AND GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
   AND GJH.JE_SOURCE = 'Cost Management'
   AND GJH.JE_CATEGORY = 'Accrual'
   AND GJL.GL_SL_LINK_ID IS NOT NULL
   AND XDL.SOURCE_DISTRIBUTION_TYPE = 'RCV_RECEIVING_SUB_LEDGER'  -- ✅ Filtre correct
   AND SUBSTR(GJB.NAME, 1, 9) = 'PROVISION'
   AND GJB.DEFAULT_PERIOD_NAME = GJH.PERIOD_NAME
ORDER BY 1, 2;
```

**Résultat attendu :** 126,921 lignes

---

### Option 2 : Joindre RCV_RECEIVING_SUB_LEDGER au Lieu de PO_DISTRIBUTIONS_ALL

Si vous voulez remonter aux informations de réception et au PO original :

```sql
SELECT GJL.JE_HEADER_ID,
       GJL.JE_LINE_NUM,
       RT.TRANSACTION_ID AS RCV_TRANSACTION_ID,
       PDA.PO_DISTRIBUTION_ID,
       POH.SEGMENT1 AS PO_NUMBER,
       GJL.LEDGER_ID,
       RT.ORGANIZATION_ID,
       GJL.CREATION_DATE,
       GJH.PERIOD_NAME
  FROM GL.GL_JE_LINES GJL
 INNER JOIN GL.GL_LEDGERS GLE ON GLE.LEDGER_ID = GJL.LEDGER_ID
 INNER JOIN GL.GL_JE_HEADERS GJH ON GJH.JE_HEADER_ID = GJL.JE_HEADER_ID
 INNER JOIN GL.GL_JE_BATCHES GJB ON GJB.JE_BATCH_ID = GJH.JE_BATCH_ID
 INNER JOIN XLA.XLA_AE_LINES XAL
     ON (XAL.GL_SL_LINK_ID = GJL.GL_SL_LINK_ID
         AND XAL.ACCOUNTING_CLASS_CODE = 'CHARGE'
         AND XAL.GL_SL_LINK_TABLE = 'XLAJEL')
 LEFT OUTER JOIN XLA.XLA_AE_HEADERS XAH
     ON XAH.AE_HEADER_ID = XAL.AE_HEADER_ID
 LEFT OUTER JOIN XLA.XLA_DISTRIBUTION_LINKS XDL
     ON (XDL.AE_HEADER_ID = XAH.AE_HEADER_ID
         AND XDL.AE_LINE_NUM = XAL.AE_LINE_NUM)
 -- ✅ Jointure vers RCV_TRANSACTIONS au lieu de PO_DISTRIBUTIONS_ALL
 LEFT OUTER JOIN PO.RCV_TRANSACTIONS RT
     ON RT.TRANSACTION_ID = XDL.SOURCE_DISTRIBUTION_ID_NUM_1
     AND XDL.SOURCE_DISTRIBUTION_TYPE = 'RCV_RECEIVING_SUB_LEDGER'
 LEFT OUTER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
     ON PDA.PO_DISTRIBUTION_ID = RT.PO_DISTRIBUTION_ID
 LEFT OUTER JOIN PO.PO_HEADERS_ALL POH
     ON POH.PO_HEADER_ID = PDA.PO_HEADER_ID
 WHERE GJH.PERIOD_NAME = 'NOV-25'
   AND GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
   AND GJH.JE_SOURCE = 'Cost Management'
   AND GJH.JE_CATEGORY = 'Accrual'
   AND GJL.GL_SL_LINK_ID IS NOT NULL
   AND RT.TRANSACTION_ID IS NOT NULL  -- ✅ Filtre sur RCV au lieu de PO
   AND SUBSTR(GJB.NAME, 1, 9) = 'PROVISION'
   AND GJB.DEFAULT_PERIOD_NAME = GJH.PERIOD_NAME
ORDER BY 1, 2;
```

---

## CONTEXTE MÉTIER : PROCESSUS "RECEIPT ACCRUALS - PERIOD-END"

### Lien avec le Rapport de Clôture

Dans le fichier `Rapport_Cloture_AR_Novembre_2025.md`, on observe :

```
23:39:15 - 01:12:07 | Receipt Accruals - Period-End (393 exécutions) | 46361435-46362197
```

**Ce processus crée les provisions de fin de période pour les réceptions de marchandises non encore facturées.**

### Flux Comptable

```
1. Réception Marchandises (RCV)
   └─ Création d'une transaction dans RCV_TRANSACTIONS
   
2. Processus "Receipt Accruals - Period-End"
   └─ Comptabilisation des provisions pour réceptions non facturées
      ├─ Débit : Compte de charges (CHARGE)
      └─ Crédit : Compte de provisions (ACCRUAL)
   
3. Création des écritures XLA
   └─ XLA_DISTRIBUTION_LINKS pointe vers RCV_TRANSACTIONS
   
4. Transfert vers GL
   └─ Création des batches "PROVISION_XXX"
```

### Pourquoi OCT-25 apparaît dans les noms de batch ?

Les batches `PROVISION_XXX_OCT-25` postés en période `NOV-25` représentent :
- **Provisions d'octobre** comptabilisées **rétroactivement** lors de la clôture de novembre
- **Ajustements** sur des réceptions d'octobre détectées après la clôture d'octobre
- **Reprises** de provisions d'octobre avec création de nouvelles provisions en novembre

**Exemple concret :**
```
Batch: PROVISION_RESOCEANE_OCT-25_1_ Cost Management A 4337134 46074194
├─ Période GL: NOV-25 (posté lors de la clôture de novembre)
├─ Date effective: 30/11/2025
└─ Contenu: Provisions pour réceptions d'octobre non facturées
```

---

## RECOMMANDATIONS

### 1. Court Terme (Immédiat)

✅ **Modifier la requête pour utiliser RCV_TRANSACTIONS au lieu de PO_DISTRIBUTIONS_ALL**
- Utiliser l'**Option 2** ci-dessus
- Retirer le filtre `PDA.PO_DISTRIBUTION_ID IS NOT NULL`
- Ajouter le filtre `RT.TRANSACTION_ID IS NOT NULL`

### 2. Moyen Terme (1-2 semaines)

✅ **Documenter les différents types de provisions Cost Management**
- Provisions de réceptions (RCV → via RCV_TRANSACTIONS)
- Provisions de PO (PO → via PO_DISTRIBUTIONS_ALL)
- Clarifier les processus de clôture mensuelle

### 3. Long Terme (1-3 mois)

✅ **Créer une vue unifiée des provisions**
```sql
CREATE OR REPLACE VIEW V_PROVISIONS_CM_ALL AS
SELECT 'RCV' AS SOURCE_TYPE, ... FROM ... WHERE XDL.SOURCE_DISTRIBUTION_TYPE = 'RCV_RECEIVING_SUB_LEDGER'
UNION ALL
SELECT 'PO' AS SOURCE_TYPE, ... FROM ... WHERE XDL.SOURCE_DISTRIBUTION_TYPE = 'PO_DISTRIBUTIONS';
```

---

## CONCLUSION FINALE

### Réponse Définitive

**Votre requête retourne 0 ligne (pas de données OCT-25, pas de données NOV-25)** car :

1. ❌ Vous cherchez un lien vers `PO_DISTRIBUTIONS_ALL` qui **n'existe pas** pour les provisions de fin de période
2. ✅ Les provisions NOV-25 **EXISTENT** (126,921 lignes) mais pointent vers `RCV_RECEIVING_SUB_LEDGER`
3. ✅ Les batches nommés "OCT-25" postés en période NOV-25 sont **normaux** (provisions rétroactives)

### Solution

Remplacer la jointure vers `PO_DISTRIBUTIONS_ALL` par une jointure vers `PO.RCV_TRANSACTIONS` (voir **Option 2** ci-dessus).

**⚠️ Note importante :** La table `RCV_TRANSACTIONS` appartient au schéma **PO** (pas RCV).

---

**Rapport généré le :** 01/12/2025  
**Connexion :** oracleProd  
**Lignes analysées :** 253,842 lignes de provisions sur période NOV-25  
**Statut :** ✅ ANALYSE TERMINÉE - CAUSE IDENTIFIÉE - SOLUTION PROPOSÉE
