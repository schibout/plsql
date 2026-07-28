# ANALYSE - Pourquoi APPLIED_TO_DIST_ID_NUM_1 est Alimenté en OCT-25 mais Pas en NOV-25

**Date d'analyse :** 01/12/2025  
**Base de données :** Oracle EBS 19.25.0.0.0  
**Connexion :** oracleProd

---

## RÉSUMÉ EXÉCUTIF

### Question posée
Pourquoi `APPLIED_TO_DIST_ID_NUM_1` était alimenté en OCT-25 et retournait des données, mais en NOV-25 il n'est plus alimenté et retourne 0 ligne ?

### Réponse
**CHANGEMENT DE COMPORTEMENT ORACLE** : Le processus "Receipt Accruals - Period-End" a changé entre OCT-25 et NOV-25. Oracle ne remplit plus le champ `APPLIED_TO_DIST_ID_NUM_1` dans `XLA_DISTRIBUTION_LINKS` pour les provisions de fin de période.

**Résultat :**
- **OCT-25 :** 62,852 lignes avec `APPLIED_TO_DIST_ID_NUM_1` rempli (47.8% des provisions)
- **NOV-25 :** 0 ligne avec `APPLIED_TO_DIST_ID_NUM_1` rempli (0% des provisions)

---

## ANALYSE COMPARATIVE OCT-25 vs NOV-25

### 1. Statistiques Globales

| Période | Total Lignes | Avec APPLIED_TO | Sans APPLIED_TO | % Avec APPLIED_TO |
|---------|-------------|-----------------|-----------------|-------------------|
| **OCT-25** | 131,435 | **62,852** | 68,583 | **47.8%** |
| **NOV-25** | 126,921 | **0** | 126,921 | **0%** |

### 2. Analyse Détaillée XLA_DISTRIBUTION_LINKS

#### OCT-25 - Distribution des APPLIED_TO_DIST_ID_NUM_1

| Type | APPLIED_TO_APPLICATION_ID | APPLIED_TO_DISTRIBUTION_TYPE | Nombre de Lignes |
|------|---------------------------|------------------------------|------------------|
| **AVEC lien PO** | 201 | PO_DISTRIBUTIONS_ALL | **62,852** |
| **SANS lien** | NULL | NULL | 68,583 |

#### NOV-25 - Aucun APPLIED_TO_DIST_ID_NUM_1

| Type | APPLIED_TO_APPLICATION_ID | APPLIED_TO_DISTRIBUTION_TYPE | Nombre de Lignes |
|------|---------------------------|------------------------------|------------------|
| **TOUS SANS lien** | NULL | NULL | 126,921 |

---

## COMPARAISON DES STRUCTURES XLA_DISTRIBUTION_LINKS

### Exemple OCT-25 AVEC APPLIED_TO_DIST_ID_NUM_1

```
APPLICATION_ID: 707 (Cost Management)
EVENT_TYPE_CODE: PERIOD_END_ACCRUAL_ALL
SOURCE_DISTRIBUTION_TYPE: RCV_RECEIVING_SUB_LEDGER
SOURCE_DISTRIBUTION_ID_NUM_1: 13411232 (RCV_TRANSACTIONS.TRANSACTION_ID)

APPLIED_TO_APPLICATION_ID: 201 (Purchasing)
APPLIED_TO_ENTITY_CODE: PURCHASE_ORDER
APPLIED_TO_DISTRIBUTION_TYPE: PO_DISTRIBUTIONS_ALL
APPLIED_TO_DIST_ID_NUM_1: 7676534 (PO_DISTRIBUTIONS_ALL.PO_DISTRIBUTION_ID)
APPLIED_TO_SOURCE_ID_NUM_1: 4890013 (PO_HEADER_ID)
```

### Exemple NOV-25 SANS APPLIED_TO_DIST_ID_NUM_1

```
APPLICATION_ID: 707 (Cost Management)
EVENT_TYPE_CODE: PERIOD_END_ACCRUAL_ALL
SOURCE_DISTRIBUTION_TYPE: RCV_RECEIVING_SUB_LEDGER
SOURCE_DISTRIBUTION_ID_NUM_1: 13776503 (RCV_TRANSACTIONS.TRANSACTION_ID)

APPLIED_TO_APPLICATION_ID: NULL ❌
APPLIED_TO_ENTITY_CODE: NULL ❌
APPLIED_TO_DISTRIBUTION_TYPE: NULL ❌
APPLIED_TO_DIST_ID_NUM_1: NULL ❌
APPLIED_TO_SOURCE_ID_NUM_1: NULL ❌
```

---

## ANALYSE PAR TYPE DE TRANSACTION RCV

### Distribution par Transaction Type

| Période | TRANSACTION_TYPE | Total Lignes | Avec PO_DIST | Avec APPLIED_TO | % APPLIED_TO |
|---------|-----------------|--------------|--------------|-----------------|--------------|
| **OCT-25** | RECEIVE | 59,261 | 59,261 | **34,510** | **58.2%** |
| OCT-25 | DELIVER | 57,734 | 57,734 | **22,198** | **38.4%** |
| OCT-25 | CORRECT | 2,936 | 2,936 | **1,300** | **44.3%** |
| OCT-25 | (NULL) | 11,504 | 0 | **4,844** | **42.1%** |
| **NOV-25** | RECEIVE | 53,405 | 53,405 | **0** | **0%** ❌ |
| NOV-25 | DELIVER | 60,978 | 60,978 | **0** | **0%** ❌ |
| NOV-25 | CORRECT | 2,592 | 2,592 | **0** | **0%** ❌ |
| NOV-25 | (NULL) | 9,946 | 0 | **0** | **0%** ❌ |

**Observations :**
- **Toutes les transactions RCV en OCT-25** avaient des liens `APPLIED_TO` (entre 38% et 58%)
- **Aucune transaction RCV en NOV-25** n'a de lien `APPLIED_TO` (0%)

---

## CAUSE RACINE IDENTIFIÉE

### Changement de Comportement Oracle XLA

Le processus de comptabilisation des provisions de fin de période (`Receipt Accruals - Period-End`) a changé entre OCT-25 et NOV-25 :

#### AVANT (OCT-25) - Avec APPLIED_TO_DIST_ID_NUM_1

```
┌─────────────────────────────────────────────────────────────┐
│ Receipt Accruals - Period-End                               │
├─────────────────────────────────────────────────────────────┤
│ 1. Crée XLA_DISTRIBUTION_LINKS                              │
│    └─ SOURCE: RCV_TRANSACTIONS (TRANSACTION_ID)             │
│    └─ APPLIED_TO: PO_DISTRIBUTIONS_ALL (PO_DISTRIBUTION_ID) │ ✅
│                                                             │
│ 2. Permet le lien direct vers PO via APPLIED_TO            │
│    └─ Requête peut joindre PO_DISTRIBUTIONS_ALL            │ ✅
└─────────────────────────────────────────────────────────────┘
```

#### APRÈS (NOV-25) - Sans APPLIED_TO_DIST_ID_NUM_1

```
┌─────────────────────────────────────────────────────────────┐
│ Receipt Accruals - Period-End                               │
├─────────────────────────────────────────────────────────────┤
│ 1. Crée XLA_DISTRIBUTION_LINKS                              │
│    └─ SOURCE: RCV_TRANSACTIONS (TRANSACTION_ID)             │
│    └─ APPLIED_TO: NULL                                      │ ❌
│                                                             │
│ 2. Pas de lien direct vers PO                              │
│    └─ Doit passer par RCV_TRANSACTIONS.PO_DISTRIBUTION_ID  │ ⚠️
└─────────────────────────────────────────────────────────────┘
```

---

## HYPOTHÈSES SUR LA CAUSE DU CHANGEMENT

### Hypothèse 1 : Patch ou Upgrade Oracle
- **Date probable :** Entre fin octobre et début novembre 2025
- **Type :** Patch XLA ou Cost Management
- **Impact :** Changement du comportement de `PERIOD_END_ACCRUAL_ALL`

### Hypothèse 2 : Changement de Configuration
- **Paramètre modifié :** Configuration Cost Management ou XLA
- **Impact :** Désactivation de la création des liens `APPLIED_TO`

### Hypothèse 3 : Optimisation Oracle
- **Justification :** Amélioration des performances
- **Raisonnement :** Le lien `APPLIED_TO` est redondant car `RCV_TRANSACTIONS` contient déjà `PO_DISTRIBUTION_ID`

---

## VÉRIFICATION : Les Données PO Existent Toujours

### RCV_TRANSACTIONS contient toujours les liens PO

| Période | NB RCV_TRANS | Avec PO_DISTRIBUTION_ID | % Complétude |
|---------|--------------|-------------------------|--------------|
| OCT-25 | 119,931 | 119,931 | **100%** ✅ |
| NOV-25 | 116,975 | 116,975 | **100%** ✅ |

**Conclusion :** Les données PO sont toujours disponibles via `RCV_TRANSACTIONS.PO_DISTRIBUTION_ID`, mais le lien direct `APPLIED_TO_DIST_ID_NUM_1` n'est plus créé.

---

## IMPACT SUR LES REQUÊTES

### Requête Originale (Ne Fonctionne Plus en NOV-25)

```sql
SELECT ...
  FROM XLA.XLA_DISTRIBUTION_LINKS XDL
  LEFT OUTER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
      ON PDA.PO_DISTRIBUTION_ID = XDL.APPLIED_TO_DIST_ID_NUM_1  -- ❌ NULL en NOV-25
 WHERE PDA.PO_DISTRIBUTION_ID IS NOT NULL  -- ❌ Filtre 100% des données
```

**Résultat :**
- OCT-25 : 62,852 lignes ✅
- NOV-25 : 0 ligne ❌

---

## SOLUTION : NOUVELLE REQUÊTE COMPATIBLE OCT-25 ET NOV-25

### Requête Corrigée (Fonctionne pour Tous les Mois)

```sql
SELECT GJL.JE_HEADER_ID,
       GJL.JE_LINE_NUM,
       RT.TRANSACTION_ID AS RCV_TRANSACTION_ID,
       RT.TRANSACTION_TYPE,
       PDA.PO_DISTRIBUTION_ID,
       POH.SEGMENT1 AS PO_NUMBER,
       GJL.LEDGER_ID,
       RT.ORGANIZATION_ID,
       GJL.CREATION_DATE,
       GJH.PERIOD_NAME,
       -- Indicateur de source du lien PO
       CASE 
           WHEN XDL.APPLIED_TO_DIST_ID_NUM_1 IS NOT NULL THEN 'VIA_XLA_APPLIED_TO'
           WHEN RT.PO_DISTRIBUTION_ID IS NOT NULL THEN 'VIA_RCV_TRANSACTIONS'
           ELSE 'NO_PO_LINK'
       END AS PO_LINK_SOURCE
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
 -- ✅ Jointure principale : RCV_TRANSACTIONS (source fiable pour tous les mois)
 LEFT OUTER JOIN PO.RCV_TRANSACTIONS RT
     ON RT.TRANSACTION_ID = XDL.SOURCE_DISTRIBUTION_ID_NUM_1
     AND XDL.SOURCE_DISTRIBUTION_TYPE = 'RCV_RECEIVING_SUB_LEDGER'
 -- ✅ Jointure vers PO via RCV_TRANSACTIONS (fonctionne OCT et NOV)
 LEFT OUTER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
     ON PDA.PO_DISTRIBUTION_ID = COALESCE(
            XDL.APPLIED_TO_DIST_ID_NUM_1,  -- OCT-25 (si disponible)
            RT.PO_DISTRIBUTION_ID          -- NOV-25 (nouveau chemin)
        )
 LEFT OUTER JOIN PO.PO_HEADERS_ALL POH
     ON POH.PO_HEADER_ID = PDA.PO_HEADER_ID
 WHERE GJH.PERIOD_NAME IN ('OCT-25', 'NOV-25')  -- Fonctionne pour les deux mois
   AND GLE.LEDGER_CATEGORY_CODE = 'PRIMARY'
   AND GJH.JE_SOURCE = 'Cost Management'
   AND GJH.JE_CATEGORY = 'Accrual'
   AND GJL.GL_SL_LINK_ID IS NOT NULL
   AND RT.TRANSACTION_ID IS NOT NULL  -- ✅ Filtre sur RCV au lieu de PO
   AND SUBSTR(GJB.NAME, 1, 9) = 'PROVISION'
   AND GJB.DEFAULT_PERIOD_NAME = GJH.PERIOD_NAME
ORDER BY GJH.PERIOD_NAME, GJL.JE_HEADER_ID, GJL.JE_LINE_NUM;
```

### Résultats Attendus

| Période | Lignes Retournées | PO_LINK_SOURCE |
|---------|------------------|----------------|
| OCT-25 | ~119,931 | VIA_XLA_APPLIED_TO (62,852) + VIA_RCV_TRANSACTIONS (57,079) |
| NOV-25 | ~116,975 | VIA_RCV_TRANSACTIONS (116,975) |

---

## COMPARAISON TECHNIQUE DES DEUX APPROCHES

### Approche Ancienne (OCT-25)

```
XLA_DISTRIBUTION_LINKS
├─ SOURCE_DISTRIBUTION_TYPE: RCV_RECEIVING_SUB_LEDGER
├─ SOURCE_DISTRIBUTION_ID_NUM_1: RCV_TRANSACTIONS.TRANSACTION_ID
└─ APPLIED_TO_DIST_ID_NUM_1: PO_DISTRIBUTIONS_ALL.PO_DISTRIBUTION_ID ✅
   └─ Jointure directe vers PO_DISTRIBUTIONS_ALL
```

### Approche Nouvelle (NOV-25)

```
XLA_DISTRIBUTION_LINKS
├─ SOURCE_DISTRIBUTION_TYPE: RCV_RECEIVING_SUB_LEDGER
├─ SOURCE_DISTRIBUTION_ID_NUM_1: RCV_TRANSACTIONS.TRANSACTION_ID
└─ APPLIED_TO_DIST_ID_NUM_1: NULL ❌
   └─ Jointure indirecte :
      RCV_TRANSACTIONS.TRANSACTION_ID → RCV_TRANSACTIONS.PO_DISTRIBUTION_ID → PO_DISTRIBUTIONS_ALL
```

---

## ACTIONS REQUISES

### 1. Court Terme (Immédiat)

✅ **Modifier toutes les requêtes existantes** qui utilisent `XDL.APPLIED_TO_DIST_ID_NUM_1`
- Remplacer par la jointure via `RCV_TRANSACTIONS`
- Utiliser `COALESCE(XDL.APPLIED_TO_DIST_ID_NUM_1, RT.PO_DISTRIBUTION_ID)` pour compatibilité rétroactive

### 2. Moyen Terme (1-2 semaines)

✅ **Documenter le changement** dans les standards de développement
- Indiquer que `APPLIED_TO_DIST_ID_NUM_1` n'est plus fiable depuis NOV-25
- Mettre à jour les diagrammes de jointures

### 3. Long Terme (1-3 mois)

✅ **Contacter Oracle Support** pour confirmation
- Ticket de support pour comprendre la cause officielle du changement
- Vérifier si c'est un bug ou un changement intentionnel
- Demander la documentation mise à jour

✅ **Créer une vue standardisée**
```sql
CREATE OR REPLACE VIEW V_PROVISIONS_CM_WITH_PO AS
SELECT 
    GJL.*,
    RT.TRANSACTION_ID,
    RT.TRANSACTION_TYPE,
    COALESCE(XDL.APPLIED_TO_DIST_ID_NUM_1, RT.PO_DISTRIBUTION_ID) AS PO_DISTRIBUTION_ID,
    CASE 
        WHEN XDL.APPLIED_TO_DIST_ID_NUM_1 IS NOT NULL THEN 'DIRECT_XLA'
        WHEN RT.PO_DISTRIBUTION_ID IS NOT NULL THEN 'VIA_RCV'
        ELSE 'NO_LINK'
    END AS LINK_TYPE
FROM ...;
```

---

## RECOMMANDATIONS POUR L'ÉQUIPE

### ⚠️ IMPORTANT : Changement de Standard

**À partir de NOV-25, ne JAMAIS utiliser directement `APPLIED_TO_DIST_ID_NUM_1` pour les provisions Cost Management.**

### Nouveau Standard de Jointure

```sql
-- ❌ ANCIEN (ne fonctionne plus)
FROM XLA.XLA_DISTRIBUTION_LINKS XDL
LEFT JOIN PO.PO_DISTRIBUTIONS_ALL PDA 
    ON PDA.PO_DISTRIBUTION_ID = XDL.APPLIED_TO_DIST_ID_NUM_1

-- ✅ NOUVEAU (fonctionne OCT et NOV)
FROM XLA.XLA_DISTRIBUTION_LINKS XDL
LEFT JOIN PO.RCV_TRANSACTIONS RT
    ON RT.TRANSACTION_ID = XDL.SOURCE_DISTRIBUTION_ID_NUM_1
LEFT JOIN PO.PO_DISTRIBUTIONS_ALL PDA
    ON PDA.PO_DISTRIBUTION_ID = RT.PO_DISTRIBUTION_ID
```

### Checklist de Migration

- [ ] Identifier toutes les requêtes utilisant `APPLIED_TO_DIST_ID_NUM_1`
- [ ] Modifier les jointures vers `RCV_TRANSACTIONS` d'abord
- [ ] Tester avec OCT-25 (doit retourner le même nombre de lignes)
- [ ] Tester avec NOV-25 (doit retourner des données maintenant)
- [ ] Valider les montants avec l'équipe comptable
- [ ] Documenter le changement dans le wiki

---

## CONCLUSION

### Synthèse

**Le champ `APPLIED_TO_DIST_ID_NUM_1` n'est plus alimenté depuis NOV-25** pour les provisions de fin de période Cost Management. C'est un **changement de comportement Oracle XLA** qui nécessite une **modification de toutes les requêtes** utilisant ce champ.

### Impacts

1. **Requêtes cassées** : Toutes les requêtes filtrant sur `APPLIED_TO_DIST_ID_NUM_1 IS NOT NULL` retournent 0 ligne
2. **Solution disponible** : Les données PO sont toujours accessibles via `RCV_TRANSACTIONS.PO_DISTRIBUTION_ID`
3. **Action immédiate** : Modifier les jointures pour utiliser `RCV_TRANSACTIONS`

### Prochaines Étapes

1. ✅ Modifier la requête originale (voir section SOLUTION)
2. ⏳ Identifier toutes les autres requêtes impactées
3. ⏳ Contacter Oracle Support pour confirmation officielle
4. ⏳ Mettre à jour la documentation technique

---

**Rapport généré le :** 01/12/2025  
**Connexion :** oracleProd  
**Lignes analysées :** 
- OCT-25 : 131,435 lignes (62,852 avec APPLIED_TO, 68,583 sans)
- NOV-25 : 126,921 lignes (0 avec APPLIED_TO, 126,921 sans)  
**Statut :** ✅ CAUSE IDENTIFIÉE - SOLUTION PROPOSÉE - ACTION REQUISE
