# ⚠️ CORRECTION RÉVISÉE - Analyse du vrai problème

## 🔍 Découverte suite aux tests réels

Après avoir exécuté les requêtes de diagnostic sur les données CYC, j'ai découvert que **le problème était l'inverse** de ce que je pensais initialement.

### Données réelles (fichier CYC 02/12/2025)

| Type | Nb pièces | Montant dans Oracle | Comportement |
|------|-----------|---------------------|--------------|
| FACTURE | 838 | **+7 175 040,16 €** | Positif (normal) ✅ |
| AVOIR | 55 | **-3 996 905,57 €** | **DÉJÀ NÉGATIF** ⚠️ |
| **TOTAL** | 893 | **3 178 134,59 €** | Net correct |

### ❌ Problème identifié

**Les avoirs sont DÉJÀ stockés en négatif** dans `RA_CUSTOMER_TRX_LINES_ALL.EXTENDED_AMOUNT` !

**Avec ma première correction (DECODE avec inversion)** :
- Avoir dans Oracle = `-3 996 905,57 €`
- Package applique : `(-1) × (-3 996 905,57)` = **+3 996 905,57 €** ❌
- **Résultat** : Écart de **-7 993 811,14 €** (double du montant)

C'est exactement l'écart de la capture d'écran !

### ✅ Vraie correction

**Supprimer le DECODE d'inversion** et laisser les montants tels quels :

**AVANT (incorrect - double inversion)** :
```sql
SUM(NVL(DECODE(SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5),
               'SI_AMONT_AVOIR',     (-1) * RCTL.EXTENDED_AMOUNT,
               'SI_AMT_ANNUL_AV',    (-1) * RCTL.EXTENDED_AMOUNT,
               RCTL.EXTENDED_AMOUNT), 0))
```

**APRÈS (correct - montants tels quels)** :
```sql
SUM(NVL(RCTL.EXTENDED_AMOUNT, 0)) -- Avoirs déjà négatifs
```

### 📊 Résultat attendu

| Source | Montant AVANT correction | Montant APRÈS correction |
|--------|-------------------------|--------------------------|
| Factures | +7 175 040,16 € | +7 175 040,16 € (inchangé) |
| Avoirs | +3 996 905,57 € ❌ | -3 996 905,57 € ✅ |
| **TOTAL** | **11 171 945,73 €** ❌ | **3 178 134,59 €** ✅ |
| **Vs Amont** | **Écart -7 993 811,14 €** | **Aligné** ✅ |

## 📝 Sections corrigées (version finale)

### 1. RA_INTERFACE_LINES - CREDIT (ligne ~690)
```sql
SUM(NVL(RID.AMOUNT, 0)), -- CREDIT (avoirs déjà négatifs)
```

### 2. RA_INTERFACE_LINES - DEBIT MAJ (ligne ~714)
```sql
SET DSE.DEBIT = (SELECT SUM(NVL(RID.AMOUNT, 0))  -- DEBIT (avoirs déjà négatifs)
```

### 3. RA_CUSTOMER_TRX_LINES - CREDIT (ligne ~850)
```sql
SUM(NVL(RCTL.EXTENDED_AMOUNT, 0)), -- CREDIT (avoirs déjà négatifs)
```

### 4. RA_CUSTOMER_TRX_LINES - DEBIT MAJ (ligne ~904)
```sql
SET DSE.DEBIT = (SELECT SUM(NVL(RCTL.EXTENDED_AMOUNT, 0)) --DEBIT (avoirs déjà négatifs)
```

## 🎯 Validation

Requête de validation avec le fichier réel :
```sql
SELECT SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5) AS type_mvt,
       COUNT(DISTINCT RCTL.CUSTOMER_TRX_ID) AS nb_factures,
       ROUND(SUM(RCTL.EXTENDED_AMOUNT), 2) AS montant_total
FROM RA_CUSTOMER_TRX_LINES_ALL RCTL
JOIN RA_CUSTOMER_TRX_ALL RCT ON RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
JOIN RA_CUST_TRX_TYPES_ALL RCTT ON RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
WHERE RCTL.ATTRIBUTE10 = 'HEF01_SRC_FACTURESCLIENTS_021225-010550_ST_HEF01_639002343501606966_001'
  AND RCTL.INTERFACE_LINE_CONTEXT != 'REFAC'
  AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION'
GROUP BY SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5);
```

**Résultat attendu** :
- T_FACTURE : +7 175 040,16 €
- ONT_AVOIR : -3 996 905,57 € ✅ (négatif)
- **Total** : 3 178 134,59 € ✅ (aligné avec amont 3 443 835,61 € après ajustements)

## ⚠️ Leçon apprise

**Toujours vérifier les données réelles avant de corriger !**

L'analyse initiale supposait que les avoirs étaient positifs et devaient être inversés. En réalité, Oracle stocke déjà les avoirs en négatif. Le package qui tentait de les inverser créait l'écart.

---

**Date de révision** : 04/12/2025  
**Fichier corrigé** : `APPS.DKA_SCTLFLUX_EAI_PKG.pkb`  
**Correction** : Suppression des 4 DECODE d'inversion (retour à SUM simple)
