# Analyse Import Contrats SSTR - 16/01/2026

**Auteur** : Samir CHIBOUT

## Résumé Exécutif

| Élément | Valeur |
|---------|--------|
| **Date de l'incident** | 15/01/2026 |
| **Programme concerné** | DKA_IPO_SSTR_IVALUA (DKA : Import des contrats SSTR depuis iValua) |
| **Request ID** | 46794096 |
| **Statut** | Terminé avec **Avertissement** |
| **Nombre de rejets** | 13 contrats |
| **Cause** | Commandes non présentes dans Oracle au moment de l'import |

---

## 1. Contexte de l'Incident

### 1.1 Exécution du Programme

| Champ | Valeur |
|-------|--------|
| Request ID | 46794096 |
| Programme parent | DKA_SLAUNCHER (Request ID: 46794095) |
| Shell lancé | DKA_IPOCTRSSTR_CHARG_JOB.sh |
| Début | 15/01/2026 19:25:26 |
| Fin | 15/01/2026 19:25:58 |
| Durée | 32 secondes |
| Paramètres | N |

### 1.2 Message d'Erreur

```
Liste des rejets de validation :
---------------------
Contrat n° CTRxxxxxx / RECORD_ID xxxxx : La commande STxxxxxxx n'existe pas dans Oracle.
```

---

## 2. Liste des Contrats Rejetés

| Contrat | RECORD_ID | Commande Référencée |
|---------|-----------|---------------------|
| CTR019079 | 22314 | ST2068109 |
| CTR019088 | 22315 | ST2069016 |
| CTR019253 | 22316 | ST2068693 |
| CTR019272 | 22317 | ST2069591 |
| CTR019283 | 22318 | ST2068222 |
| CTR019466 | 22319 | ST2068648 |
| CTR019601 | 22320 | ST2068576 |
| CTR019804 | 22321 | ST2068923 |
| CTR020423 | 22322 | ST2067853 |
| CTR021115 | 22323 | ST2069494 |
| CTR023394 | 22324 | ST2067857 |
| CTR023783 | 22325 | ST2068623 |
| CTR024272 | 22326 | ST2068357 |

---

## 3. Analyse des Commandes

### 3.1 Vérification dans Oracle (16/01/2026)

Requête exécutée :
```sql
SELECT 
    PHA.SEGMENT1 AS NUM_COMMANDE,
    TO_CHAR(PHA.CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS DATE_CREATION,
    PHA.AUTHORIZATION_STATUS AS STATUT,
    PHA.CLOSED_CODE AS CODE_CLOTURE
FROM PO.PO_HEADERS_ALL PHA
WHERE PHA.SEGMENT1 IN ('ST2068109', 'ST2069016', ...)
```

### 3.2 Résultat : Toutes les commandes existent maintenant

| Commande | Date Création | Statut | Code Clôture | ORG_ID |
|----------|---------------|--------|--------------|--------|
| ST2067853 | 16/01/2026 09:04:38 | APPROVED | OPEN | 85 |
| ST2067857 | 16/01/2026 09:04:38 | APPROVED | OPEN | 5191 |
| ST2068109 | 16/01/2026 09:04:39 | APPROVED | OPEN | 91 |
| ST2068222 | 16/01/2026 09:04:39 | APPROVED | OPEN | 131 |
| ST2068357 | 16/01/2026 09:04:39 | APPROVED | OPEN | 86 |
| ST2068576 | 16/01/2026 09:04:39 | APPROVED | OPEN | 305 |
| ST2068623 | 16/01/2026 09:04:39 | APPROVED | OPEN | 87 |
| ST2068648 | 16/01/2026 09:04:39 | APPROVED | OPEN | 88 |
| ST2068693 | 16/01/2026 09:04:39 | APPROVED | OPEN | 90 |
| ST2068923 | 16/01/2026 09:04:40 | APPROVED | OPEN | 85 |
| ST2069016 | 16/01/2026 09:04:40 | APPROVED | OPEN | 88 |
| ST2069494 | 16/01/2026 09:04:41 | APPROVED | OPEN | 249 |
| ST2069591 | 16/01/2026 09:04:41 | APPROVED | OPEN | 91 |

---

## 4. Diagnostic

### 4.1 Cause Racine : Désynchronisation Temporelle

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CHRONOLOGIE DES ÉVÉNEMENTS                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  15/01/2026 19:25:26  ──►  Import contrats SSTR depuis iValua       │
│                            ❌ Les 13 commandes N'EXISTENT PAS       │
│                            ⚠️ 13 rejets de validation               │
│                                                                     │
│  ~~~~~~~~~~~~~ NUIT DU 15 AU 16 JANVIER ~~~~~~~~~~~~~               │
│                                                                     │
│  16/01/2026 09:04:38  ──►  Création des commandes dans Oracle      │
│                            ✅ Import PO depuis iValua               │
│                            ✅ 13 commandes créées et approuvées     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.2 Explication

Le programme d'import des **contrats SSTR** (sous-traitance) s'est exécuté **AVANT** que les **commandes PO** associées ne soient créées dans Oracle.

- **Import contrats** : 15/01/2026 à 19:25:26
- **Création commandes** : 16/01/2026 à 09:04:38

**Écart temporel** : ~14 heures

### 4.3 Flux iValua → Oracle

```
iValua                                    Oracle EBS
┌──────────┐                             ┌──────────────┐
│ Contrats │ ──── DKA_IPO_SSTR_IVALUA ──►│ Validation   │
│  SSTR    │      (15/01 19:25)          │ ❌ ÉCHEC     
└──────────┘                             └──────────────┘
                                                ▲
                                                │ Référence
┌──────────┐                             ┌──────────────┐
│ Commandes│ ──── Import PO ────────────►│ PO_HEADERS   │
│   PO     │      (16/01 09:04)          │ ✅ CRÉÉES    
└──────────┘                             └──────────────┘
```

---

## 5. Impact

| Critère | Évaluation |
|---------|------------|
| **Criticité** | Faible |
| **Données perdues** | Non - contrats en attente de retraitement |
| **Intégrité** | Intègre - validation a fonctionné correctement |
| **Utilisateurs impactés** | Équipe SSTR / Sous-traitance |

---

## 6. Recommandations

### 6.1 Action Immédiate

**Relancer le programme d'import des contrats SSTR** :
- Programme : `DKA_IPO_SSTR_IVALUA`
- Les 13 commandes sont maintenant présentes et approuvées
- L'import devrait réussir

### 6.2 Actions Préventives (Moyen Terme)

| Action | Description | Priorité |
|--------|-------------|----------|
| **Revoir l'ordonnancement** | S'assurer que l'import des commandes PO s'exécute AVANT l'import des contrats SSTR | Haute |
| **Ajouter dépendance** | Configurer une dépendance entre les jobs dans le scheduler Oracle | Moyenne |
| **Mécanisme de retry** | Implémenter un retraitement automatique des rejets après X heures | Basse |

### 6.3 Ordonnancement Proposé

```
Séquence recommandée :
1. Import Commandes PO depuis iValua    (DKA_IPO_xxx)
2. Approbation/Validation automatique
3. Import Contrats SSTR depuis iValua   (DKA_IPO_SSTR_IVALUA)
```

---

## 7. Requête de Vérification

Pour vérifier si les contrats ont été retraités avec succès :

```sql
-- Vérifier le statut des contrats dans la table de staging
SELECT 
    RECORD_ID,
    CONTRACT_NUMBER,
    PO_NUMBER,
    STATUS,
    ERROR_MESSAGE,
    CREATION_DATE,
    LAST_UPDATE_DATE
FROM APPS.DKA_IPO_SSTR_IVALUA_STG  -- À adapter selon le nom réel de la table
WHERE RECORD_ID BETWEEN 22314 AND 22326
ORDER BY RECORD_ID;
```
---
**Action requise** : Relancer l'import des contrats SSTR
---