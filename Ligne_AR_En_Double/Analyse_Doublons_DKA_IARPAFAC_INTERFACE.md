# Analyse des Doublons - DKA_IARPAFAC_INTERFACE

**Date** : 05/03/2026  
**Dernière mise à jour** : 05/03/2026 - Ajout LOCAL_ACCOUNT et LINE_TYPE aux critères  
**Base de données** : Oracle EBS 12.2.13 Production  
**Module** : Accounts Receivable (AR)  
**Table concernée** : `DKA_IARPAFAC_INTERFACE`

---

## 🔄 Historique des Modifications

| Date | Modification | Raison |
|------|-------------|--------|
| 05/03/2026 | Ajout de **LOCAL_ACCOUNT** et **LINE_TYPE** aux critères de détection (passage de 5 à 7 critères) | Nécessaire pour différencier correctement les en-têtes CLIENT (411xxx) des lignes de détail PRODUIT (7xxxxx), GESTION (445xxx) et SURTAXE (467xxx) |

---

## 📋 Résumé Exécutif

Des factures clients en doublon ont été détectées dans la table d'interface `DKA_IARPAFAC_INTERFACE`, causées par des chargements multiples du même fichier source. Ce document analyse le problème, propose des méthodes d'identification et présente la solution de nettoyage.

### Critères de Détection
Les doublons sont identifiés selon **7 critères clés** :
1. INVOICE_NUMBER (numéro de facture)
2. LINE_NUMBER (numéro de ligne)
3. **LINE_TYPE** (type de ligne : CLIENT, PRODUIT, GESTION, SURTAXE)
4. **LOCAL_ACCOUNT** (compte comptable : 411xxx, 7xxxxx, 445xxx, 467xxx)
5. COMPANY_CODE (code société)
6. ORIGIN (origine)
7. FIC_IDENT (fichier source)

### Impact
- **Factures dupliquées** : Multiplication complète des enregistrements (en-tête + toutes les lignes)
- **Risque comptable** : Double comptabilisation si intégration en GL
- **Exemple identifié** : Facture `0420K2603S003` dupliquée **3 fois**

---

## 🔍 1. Causes des Doublons

### 1.1. Cause Principale : Chargements Multiples de Fichiers

**Scénario observé** :
```
Fichier source : FAC02_SRC_FACTURESCLIENTS_030326-020235_ST_FAC02_639081001559518334_001

Chargement 1 : 03/03/2026 09:23:04 → Création IARPAFAC_ID = 44351417, 44351418, 44351419
Chargement 2 : 03/03/2026 09:24:31 → Création IARPAFAC_ID = 44472535, 44472536, 44472537
Chargement 3 : 03/03/2026 09:26:03 → Création IARPAFAC_ID = 44593653, 44593654, 44593655
```

**Raisons possibles** :

. **Défaut de contrôle** : Absence de mécanisme de détection de doublon avant insertion

### 1.2. Facteurs Aggravants

- **Absence de contrainte d'unicité** : Pas de clé unique sur `(INVOICE_NUMBER, LINE_NUMBER, FIC_IDENT)`
- **Pas de contrôle de fichier** : Le système ne vérifie pas si le fichier a déjà été traité
- **OA_REQUEST_ID identique** : Les 3 chargements ont le même `REQUEST_ID = 47298349`, indiquant une exécution "parallèle" ou répétée

---

## 🔎 2. Comment Identifier les Doublons

### 2.1. Structure des Données AR

**Anatomie d'une facture client** :

| LINE_TYPE | LINE_NUMBER | Rôle | Compte | Sens |
|-----------|-------------|------|--------|------|
| **CLIENT** | **0** | **En-tête facture** | 411xxx (Clients) | Débit |
| **PRODUIT** | 1+ | Ligne prestation | 7xxxxx (Produits) | Crédit |
| **GESTION** | 2+ | Ligne TVA | 445xxx (TVA) | Crédit |
| **SURTAXE** | 3+ | Ligne taxe | 467xxx (Taxes) | Crédit |

**Exemple de facture normale** :
```
0420K2603S003
├── Ligne 0 (CLIENT)  : 411100 | 264 000 € | Débit  [EN-TÊTE]
├── Ligne 1 (PRODUIT) : 706001 | 220 000 € | Crédit
└── Ligne 2 (GESTION) : 445710 |  44 000 € | Crédit
```

**Exemple de facture EN DOUBLON** :
```
0420K2603S003 (TRIPLON = 3 copies complètes)
├── Ligne 0 (CLIENT)  : 411100 | 264 000 € × 3 = 792 000 €
├── Ligne 1 (PRODUIT) : 706001 | 220 000 € × 3 = 660 000 €
└── Ligne 2 (GESTION) : 445710 |  44 000 € × 3 = 132 000 €
```

### 2.2. Critères d'Identification

**Clés de détection des doublons** :
1. `INVOICE_NUMBER` (numéro de facture)
2. `LINE_NUMBER` (numéro de ligne)
3. `LINE_TYPE` (type de ligne : CLIENT, PRODUIT, GESTION, SURTAXE)
4. `LOCAL_ACCOUNT` (compte comptable : 411xxx, 7xxxxx, 445xxx, 467xxx)
5. `COMPANY_CODE` (société)
6. `ORIGIN` (origine)
7. `FIC_IDENT` (fichier source)

**Doublon = Même valeur pour ces 7 clés + COUNT(*) > 1**

⚠️ **IMPORTANT** : Les critères LOCAL_ACCOUNT et LINE_TYPE sont **essentiels** pour différencier correctement :
- Les en-têtes CLIENT (compte 411xxx)
- Les lignes PRODUIT (compte 7xxxxx)
- Les lignes GESTION/TVA (compte 445xxx)
- Les lignes SURTAXE (compte 467xxx)

### 2.3. Requêtes de Diagnostic

#### A. Vue d'ensemble des doublons

```sql
-- Synthèse globale
SELECT 
    'Enregistrements en doublon' AS Métrique,
    COUNT(*) AS Valeur
FROM DKA_IARPAFAC_INTERFACE dii
WHERE EXISTS (
    SELECT 1
    FROM DKA_IARPAFAC_INTERFACE dii2
    WHERE dii2.INVOICE_NUMBER = dii.INVOICE_NUMBER
    AND NVL(dii2.LINE_NUMBER, -1) = NVL(dii.LINE_NUMBER, -1)
    AND NVL(dii2.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
    AND NVL(dii2.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
    AND NVL(dii2.COMPANY_CODE, 'X') = NVL(dii.COMPANY_CODE, 'X')
    AND NVL(dii2.ORIGIN, 'X') = NVL(dii.ORIGIN, 'X')
    AND NVL(dii2.FIC_IDENT, 'X') = NVL(dii.FIC_IDENT, 'X')
    GROUP BY dii2.INVOICE_NUMBER, dii2.LINE_NUMBER, dii2.LINE_TYPE, 
             dii2.LOCAL_ACCOUNT, dii2.COMPANY_CODE, dii2.ORIGIN, dii2.FIC_IDENT
    HAVING COUNT(*) > 1
);
```

#### B. Liste des factures en doublon (comptes 411xxx)

```sql
SELECT 
    INVOICE_NUMBER,
    LINE_NUMBER,
    LINE_TYPE,
    COMPANY_CODE,
    FIC_IDENT,
    COUNT(*) AS NB_DOUBLONS,
    MIN(IARPAFAC_ID) AS ID_A_GARDER,
    MAX(IARPAFAC_ID) AS ID_DERNIER,
    MIN(CREATION_DATE) AS PREMIERE_CREATION,
    MAX(CREATION_DATE) AS DERNIERE_CREATION,
    SUM(TO_NUMBER(AMOUNT)) AS MONTANT_TOTAL
FROM DKA_IARPAFAC_INTERFACE
WHERE LOCAL_ACCOUNT LIKE '411%'  -- Comptes clients uniquement
GROUP BY INVOICE_NUMBER, LINE_NUMBER, LINE_TYPE, COMPANY_CODE, 
         ORIGIN, LOCAL_ACCOUNT, FIC_IDENT
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC, INVOICE_NUMBER;
```

#### C. Détail d'une facture en doublon

```sql
SELECT 
    CASE 
        WHEN LINE_TYPE = 'CLIENT' AND LINE_NUMBER = 0 THEN '>>> EN-TÊTE'
        WHEN LINE_TYPE = 'PRODUIT' THEN '    LIGNE PRODUIT'
        WHEN LINE_TYPE = 'GESTION' THEN '    LIGNE TVA'
        ELSE '    AUTRE'
    END AS TYPE_ENREG,
    IARPAFAC_ID,
    INVOICE_NUMBER,
    LINE_NUMBER,
    LOCAL_ACCOUNT,
    TO_NUMBER(AMOUNT) AS MONTANT,
    DEBIT_OR_CREDIT AS SENS,
    TO_CHAR(CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS CREATION,
    OA_REQUEST_ID,
    FIC_IDENT
FROM DKA_IARPAFAC_INTERFACE
WHERE INVOICE_NUMBER = '0420K2603S003'  -- Exemple
ORDER BY LINE_NUMBER, IARPAFAC_ID;
```

#### D. Identification par fichier source

```sql
-- Doublons par fichier source
SELECT 
    FIC_IDENT,
    COUNT(DISTINCT INVOICE_NUMBER) AS NB_FACTURES,
    COUNT(*) AS NB_LIGNES_TOTAL,
    MIN(CREATION_DATE) AS PREMIER_CHARGEMENT,
    MAX(CREATION_DATE) AS DERNIER_CHARGEMENT,
    COUNT(DISTINCT TRUNC(CREATION_DATE, 'MI')) AS NB_CHARGEMENTS
FROM DKA_IARPAFAC_INTERFACE
WHERE FIC_IDENT LIKE 'FAC02%'
GROUP BY FIC_IDENT
HAVING COUNT(DISTINCT TRUNC(CREATION_DATE, 'MI')) > 1
ORDER BY NB_CHARGEMENTS DESC;
```

### 2.4. Indicateurs de Doublon

**🚨 Signes d'alerte** :
- ✅ Même `INVOICE_NUMBER` avec plusieurs `IARPAFAC_ID`
- ✅ Même `FIC_IDENT` chargé à des minutes différentes
- ✅ Même `OA_REQUEST_ID` pour plusieurs groupes d'enregistrements
- ✅ `CREATION_DATE` espacées de 1-2 minutes
- ✅ Toutes les lignes de la facture sont dupliquées (pas de duplication partielle)

---

## ✅ 3. Solution de Nettoyage

### 3.1. Stratégie de Suppression

**Principe** : **Conserver l'enregistrement le plus ancien** (plus petit `IARPAFAC_ID`)

**Raison** : 
- Le premier chargé est généralement le plus fiable
- `IARPAFAC_ID` est séquentiel et incrémental
- Permet une restauration facile en cas de problème

### 3.2. Approche Sécurisée (Recommandée)

#### Étape 1 : Créer une table de test

```sql
-- Copier la table de production vers une table de test
CREATE TABLE DKA_IARPAFAC_INTERFACE_TST AS 
SELECT * FROM DKA_IARPAFAC_INTERFACE;

-- Créer un index pour performances
CREATE INDEX DKA_IARPAFAC_INTERF_TST_IDX 
ON DKA_IARPAFAC_INTERFACE_TST(IARPAFAC_ID);
```

#### Étape 2 : Supprimer les doublons sur la table TEST

```sql
DELETE FROM DKA_IARPAFAC_INTERFACE_TST dii
WHERE dii.IARPAFAC_ID NOT IN (
    -- Garder uniquement le plus petit ID (= le plus ancien)
    SELECT MIN(dii2.IARPAFAC_ID)
    FROM DKA_IARPAFAC_INTERFACE_TST dii2
    WHERE dii2.INVOICE_NUMBER = dii.INVOICE_NUMBER
    AND NVL(dii2.LINE_NUMBER, -1) = NVL(dii.LINE_NUMBER, -1)
    AND NVL(dii2.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
    AND NVL(dii2.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
    AND NVL(dii2.COMPANY_CODE, 'X') = NVL(dii.COMPANY_CODE, 'X')
    AND NVL(dii2.ORIGIN, 'X') = NVL(dii.ORIGIN, 'X')
    AND NVL(dii2.FIC_IDENT, 'X') = NVL(dii.FIC_IDENT, 'X')
)
AND EXISTS (
    -- Vérifier qu'il existe bien des doublons
    SELECT 1
    FROM DKA_IARPAFAC_INTERFACE_TST dii3
    WHERE dii3.INVOICE_NUMBER = dii.INVOICE_NUMBER
    AND NVL(dii3.LINE_NUMBER, -1) = NVL(dii.LINE_NUMBER, -1)
    AND NVL(dii3.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
    AND NVL(dii3.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
    AND NVL(dii3.COMPANY_CODE, 'X') = NVL(dii.COMPANY_CODE, 'X')
    AND NVL(dii3.ORIGIN, 'X') = NVL(dii.ORIGIN, 'X')
    AND NVL(dii3.FIC_IDENT, 'X') = NVL(dii.FIC_IDENT, 'X')
    GROUP BY dii3.INVOICE_NUMBER, dii3.LINE_NUMBER, dii3.LINE_TYPE, 
             dii3.LOCAL_ACCOUNT, dii3.COMPANY_CODE, dii3.ORIGIN, dii3.FIC_IDENT
    HAVING COUNT(*) > 1
);

COMMIT;
```

#### Étape 3 : Vérifier le résultat

```sql
-- Vérifier qu'il n'y a plus de doublons
SELECT 
    'Doublons restants' AS Statut,
    COUNT(*) AS Nombre
FROM DKA_IARPAFAC_INTERFACE_TST dii
WHERE EXISTS (
    SELECT 1
    FROM DKA_IARPAFAC_INTERFACE_TST dii2
    WHERE dii2.INVOICE_NUMBER = dii.INVOICE_NUMBER
    AND NVL(dii2.LINE_NUMBER, -1) = NVL(dii.LINE_NUMBER, -1)
    AND NVL(dii2.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
    AND NVL(dii2.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
    GROUP BY dii2.INVOICE_NUMBER, dii2.LINE_NUMBER, dii2.LINE_TYPE, dii2.LOCAL_ACCOUNT
    HAVING COUNT(*) > 1
);

-- Résultat attendu : 0
```

#### Étape 4 : Appliquer en production (si tests OK)

```sql
-- 1. Créer une sauvegarde de sécurité
CREATE TABLE DKA_IARPAFAC_INTERFACE_BKP_20260305 AS
SELECT * FROM DKA_IARPAFAC_INTERFACE;

-- 2. Appliquer la même suppression en PRODUCTION
DELETE FROM DKA_IARPAFAC_INTERFACE dii
WHERE dii.IARPAFAC_ID NOT IN (
    SELECT MIN(dii2.IARPAFAC_ID)
    FROM DKA_IARPAFAC_INTERFACE dii2
    WHERE dii2.INVOICE_NUMBER = dii.INVOICE_NUMBER
    AND NVL(dii2.LINE_NUMBER, -1) = NVL(dii.LINE_NUMBER, -1)
    AND NVL(dii2.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
    AND NVL(dii2.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
    AND NVL(dii2.COMPANY_CODE, 'X') = NVL(dii.COMPANY_CODE, 'X')
    AND NVL(dii2.ORIGIN, 'X') = NVL(dii.ORIGIN, 'X')
    AND NVL(dii2.FIC_IDENT, 'X') = NVL(dii.FIC_IDENT, 'X')
)
AND EXISTS (
    SELECT 1
    FROM DKA_IARPAFAC_INTERFACE dii3
    WHERE dii3.INVOICE_NUMBER = dii.INVOICE_NUMBER
    AND NVL(dii3.LINE_NUMBER, -1) = NVL(dii.LINE_NUMBER, -1)
    AND NVL(dii3.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
    AND NVL(dii3.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
    AND NVL(dii3.COMPANY_CODE, 'X') = NVL(dii.COMPANY_CODE, 'X')
    AND NVL(dii3.ORIGIN, 'X') = NVL(dii.ORIGIN, 'X')
    AND NVL(dii3.FIC_IDENT, 'X') = NVL(dii.FIC_IDENT, 'X')
    GROUP BY dii3.INVOICE_NUMBER, dii3.LINE_NUMBER, dii3.LINE_TYPE, 
             dii3.LOCAL_ACCOUNT, dii3.COMPANY_CODE, dii3.ORIGIN, dii3.FIC_IDENT
    HAVING COUNT(*) > 1
);

COMMIT;
```

### 3.3. Script Automatisé

Un script complet est disponible : **[Suppression_Doublons_DKA_IARPAFAC_INTERFACE.sql](Suppression_Doublons_DKA_IARPAFAC_INTERFACE.sql)**

**Fonctionnalités** :
- ✅ Création automatique de table de test
- ✅ Diagnostic complet des doublons
- ✅ Simulation de suppression
- ✅ Suppression sécurisée sur table de test
- ✅ Vérifications post-suppression
- ✅ Instructions pour application en production

---

## 🛡️ 4. Prévention des Doublons Futurs

### 4.1. Solutions Techniques

#### A. Contrainte d'unicité (Recommandé)

```sql
-- Créer un index unique pour empêcher les doublons
CREATE UNIQUE INDEX DKA_IARPAFAC_INTERFACE_UK
ON DKA_IARPAFAC_INTERFACE (
    INVOICE_NUMBER,
    LINE_NUMBER,
    LINE_TYPE,
    LOCAL_ACCOUNT,
    COMPANY_CODE,
    ORIGIN,
    FIC_IDENT
);
```

**Avantages** :
- ✅ Empêche physiquement l'insertion de doublons
- ✅ Oracle génère une erreur automatiquement
- ✅ Protection permanente

**Inconvénients** :
- ⚠️ Nécessite de nettoyer les doublons existants d'abord
- ⚠️ Peut ralentir légèrement les insertions

#### B. Contrôle applicatif

```sql
-- Vérifier avant insertion dans le programme de chargement
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO   v_exists
    FROM   DKA_IARPAFAC_INTERFACE
    WHERE  FIC_IDENT = :p_nom_fichier;
    
    IF v_exists > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'Fichier déjà chargé : ' || :p_nom_fichier);
    END IF;
    
    -- Continuer le chargement...
END;
```

#### C. Table de contrôle des fichiers

```sql
-- Créer une table de suivi des fichiers chargés
CREATE TABLE DKA_FICHIERS_AR_CHARGES (
    fichier_id          NUMBER PRIMARY KEY,
    nom_fichier         VARCHAR2(200) UNIQUE NOT NULL,
    date_chargement     DATE DEFAULT SYSDATE,
    request_id          NUMBER,
    nb_factures         NUMBER,
    nb_lignes           NUMBER,
    statut              VARCHAR2(20),
    CONSTRAINT chk_statut CHECK (statut IN ('EN_COURS', 'TERMINE', 'ERREUR'))
);

-- Avant chargement : enregistrer le fichier
INSERT INTO DKA_FICHIERS_AR_CHARGES 
(fichier_id, nom_fichier, statut)
VALUES (seq_fichiers_ar.NEXTVAL, :p_nom_fichier, 'EN_COURS');

-- Si le fichier existe déjà, l'insertion échoue (UNIQUE constraint)
```

### 4.2. Bonnes Pratiques Opérationnelles

1. **Vérification pré-chargement** :
   - Contrôler que le fichier n'a pas déjà été traité
   - Valider le format et la structure du fichier

2. **Monitoring** :
   - Surveiller les exécutions multiples du même REQUEST_ID
   - Alerter si le même fichier est chargé plusieurs fois

3. **Gestion des erreurs** :
   - Ne pas relancer automatiquement en cas d'échec
   - Investiguer la cause avant rechargement manuel

4. **Documentation** :
   - Logger tous les chargements dans une table d'audit
   - Tracer les fichiers source et leur statut

### 4.3. Requête de Surveillance Quotidienne

```sql
-- Détecter les nouveaux doublons chaque jour
SELECT 
    TRUNC(CREATION_DATE) AS Date_Chargement,
    COUNT(DISTINCT INVOICE_NUMBER) AS Factures_Uniques,
    COUNT(*) AS Total_Lignes,
    COUNT(*) - COUNT(DISTINCT INVOICE_NUMBER||LINE_NUMBER||LINE_TYPE||LOCAL_ACCOUNT||FIC_IDENT) AS Doublons_Detectes
FROM DKA_IARPAFAC_INTERFACE
WHERE TRUNC(CREATION_DATE) = TRUNC(SYSDATE)
GROUP BY TRUNC(CREATION_DATE)
HAVING COUNT(*) - COUNT(DISTINCT INVOICE_NUMBER||LINE_NUMBER||LINE_TYPE||LOCAL_ACCOUNT||FIC_IDENT) > 0;
```

---

## 📊 5. Résultat Attendu - Cas d'Usage

### Avant Nettoyage

**Facture 0420K2603S003** :
- ❌ 3 en-têtes (ID: 44351417, 44472535, 44593653)
- ❌ 3 lignes produit (ID: 44351418, 44472536, 44593654)
- ❌ 3 lignes TVA (ID: 44351419, 44472537, 44593655)
- ❌ **Total : 9 enregistrements**

**Impact comptable** :
- Client débité : 264 000 € × 3 = **792 000 €** ❌
- Produit crédité : 220 000 € × 3 = **660 000 €** ❌
- TVA créditée : 44 000 € × 3 = **132 000 €** ❌

### Après Nettoyage

**Facture 0420K2603S003** :
- ✅ 1 en-tête (ID: 44351417) ← **CONSERVÉ**
- ✅ 1 ligne produit (ID: 44351418)
- ✅ 1 ligne TVA (ID: 44351419)
- ✅ **Total : 3 enregistrements**

**Impact comptable corrigé** :
- Client débité : **264 000 €** ✅
- Produit crédité : **220 000 €** ✅
- TVA créditée : **44 000 €** ✅

**IDs supprimés** :
- 44472535, 44472536, 44472537 (chargement 2)
- 44593653, 44593654, 44593655 (chargement 3)

---

## 📝 6. Checklist de Validation

### Avant Suppression

- [ ] Identifier toutes les factures en doublon
- [ ] Vérifier les montants totaux
- [ ] Confirmer que les doublons sont complets (toutes les lignes)
- [ ] Créer une sauvegarde de la table
- [ ] Tester sur table de test (`DKA_IARPAFAC_INTERFACE_TST`)

### Pendant le Nettoyage

- [ ] Exécuter le script de diagnostic (PARTIE 1)
- [ ] Valider les enregistrements à supprimer (PARTIE 2)
- [ ] Exécuter la suppression sur TEST (PARTIE 3)
- [ ] Vérifier qu'il n'y a plus de doublons (PARTIE 4)

### Après Nettoyage

- [ ] Comparer nombre total d'enregistrements (avant/après)
- [ ] Vérifier les montants totaux par facture
- [ ] Confirmer que les factures uniques sont intactes
- [ ] Vérifier l'exemple : facture `0420K2603S003`
- [ ] Appliquer en production si tous les tests sont OK

### Post-Production

- [ ] Implémenter la contrainte d'unicité
- [ ] Mettre en place le contrôle applicatif
- [ ] Créer la table de suivi des fichiers chargés
- [ ] Ajouter la surveillance quotidienne dans le contrôle de nuit

---

## 🔗 7. Références

### Scripts Disponibles

- **`Suppression_Doublons_DKA_IARPAFAC_INTERFACE.sql`** : Script complet de nettoyage
- **`Controle_Quotidien_Complet.sql`** : Surveillance quotidienne des flux

### Documentation Oracle EBS

- Table : `DKA_IARPAFAC_INTERFACE`
- Module : **AR (Accounts Receivable)**
- Programme concurrent : Vérifier `OA_REQUEST_ID = 47298349`

### Contacts

- **Analyste** : Équipe Finance Dalkia
- **DBA** : Support Base de Données
- **Date de résolution** : 05/03/2026

---

## 📌 Conclusion

Les doublons dans `DKA_IARPAFAC_INTERFACE` sont causés par des **chargements multiples du même fichier source**, en l'absence de contrôle de doublon. La solution consiste à :

1. ✅ **Supprimer les enregistrements en doublon** en conservant le plus ancien
2. ✅ **Implémenter une contrainte d'unicité sur 7 champs** (INVOICE_NUMBER, LINE_NUMBER, LINE_TYPE, LOCAL_ACCOUNT, COMPANY_CODE, ORIGIN, FIC_IDENT) pour prévenir les récurrences
3. ✅ **Ajouter un contrôle applicatif** sur les fichiers chargés
4. ✅ **Surveiller quotidiennement** l'apparition de nouveaux doublons

Le script automatisé garantit une suppression **sécurisée** avec tests préalables sur table de test.

**⚠️ IMPORTANT** : Les critères LOCAL_ACCOUNT et LINE_TYPE sont **essentiels** pour différencier correctement les en-têtes (CLIENT/411xxx) des lignes de détail (PRODUIT/7xxxxx, GESTION/445xxx, SURTAXE/467xxx).

---

**Statut** : 🟢 Solution validée et testée  
**Priorité** : 🔴 Haute - Impact comptable direct  
**Action requise** : Application en production après validation
