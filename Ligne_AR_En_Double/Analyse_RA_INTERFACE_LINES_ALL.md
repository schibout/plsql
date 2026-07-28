# Analyse de la Table d'Interface AR - RA_INTERFACE_LINES_ALL

**Date** : 05/03/2026  
**Base de données** : Oracle EBS 12.2.13 Production  
**Module** : Accounts Receivable (AR) - Open Interface  
**Table concernée** : `AR.RA_INTERFACE_LINES_ALL`

---

## 📋 Résumé Exécutif

La table `RA_INTERFACE_LINES_ALL` est la **table d'interface standard Oracle EBS** pour l'import des factures clients (AR Invoice). Elle permet de charger les factures depuis des systèmes externes vers Oracle Receivables avant leur validation et comptabilisation.

### Caractéristiques Clés
- **Type** : Table d'interface temporaire (staging)
- **Programme** : AutoInvoice (RAXMTR - Revenue Accounting)
- **Flux** : Système externe → RA_INTERFACE_LINES_ALL → RA_CUSTOMER_TRX_ALL (factures validées)
- **Contrainte unique** : `DKA_RA_INTERFACE_LINES_U1` (personnalisée Dalkia)

### Risques Identifiés
- **Doublons à l'insertion** : Violation de contrainte unique `DKA_RA_INTERFACE_LINES_U1`
- **Données orphelines** : Lignes non traitées restant dans l'interface
- **Erreurs de validation** : Factures rejetées par AutoInvoice nécessitant correction manuelle

---

## 🏗️ 1. Structure de la Table

### 1.1. Informations Générales

| Attribut | Valeur |
|----------|--------|
| **Schéma** | AR (Apps Receivables) |
| **Nom complet** | AR.RA_INTERFACE_LINES_ALL |
| **Type** | Table d'interface (temporaire) |
| **Partitionnement** | Non partitionnée |
| **Rôle** | Chargement des factures AR avant validation par AutoInvoice |

### 1.2. Colonnes Principales

#### Colonnes d'Identification

| Colonne | Type | Obligatoire | Description |
|---------|------|-------------|-------------|
| **INTERFACE_LINE_ID** | NUMBER | Oui (PK) | Identifiant unique de la ligne d'interface |
| **INTERFACE_LINE_CONTEXT** | VARCHAR2(30) | Oui | Contexte métier (ex: 'DKA_FACTURES_CLIENTS') |
| **INTERFACE_LINE_ATTRIBUTE1-15** | VARCHAR2(30) | Variable | Attributs flexibles pour clés métier personnalisées |
| **REQUEST_ID** | NUMBER | Non | ID du programme concurrent qui a créé la ligne |

#### Colonnes Métier (Facture)

| Colonne | Type | Description |
|---------|------|-------------|
| **TRX_NUMBER** | VARCHAR2(20) | Numéro de facture |
| **TRX_DATE** | DATE | Date de transaction |
| **LINE_NUMBER** | NUMBER | Numéro de ligne dans la facture |
| **LINE_TYPE** | VARCHAR2(20) | Type de ligne (LINE, TAX, FREIGHT, CHARGES) |
| **QUANTITY** | NUMBER | Quantité |
| **UNIT_SELLING_PRICE** | NUMBER | Prix unitaire |
| **AMOUNT** | NUMBER | Montant de la ligne |
| **DESCRIPTION** | VARCHAR2(240) | Description de la ligne |

#### Colonnes Client

| Colonne | Type | Description |
|---------|------|-------------|
| **CUSTOMER_TRX_ID** | NUMBER | ID de la facture (si déjà créée) |
| **CUSTOMER_ID** | NUMBER | ID du client Oracle |
| **CUSTOMER_NUMBER** | VARCHAR2(30) | Numéro du client |
| **BILL_TO_CUSTOMER_ID** | NUMBER | Client facturé |
| **SHIP_TO_CUSTOMER_ID** | NUMBER | Client de livraison |

#### Colonnes Comptables

| Colonne | Type | Description |
|---------|------|-------------|
| **CODE_COMBINATION_ID** | NUMBER | ID de la combinaison comptable GL |
| **TAX_CODE** | VARCHAR2(50) | Code TVA |
| **CURRENCY_CODE** | VARCHAR2(15) | Devise de la transaction |

#### Colonnes de Contrôle

| Colonne | Type | Description |
|---------|------|-------------|
| **ORG_ID** | NUMBER | Organisation (multi-org) |
| **INTERFACE_STATUS** | VARCHAR2(30) | Statut (NULL=nouveau, SUCCESS=traité, ERROR=erreur) |
| **REQUEST_ID** | NUMBER | ID du programme concurrent |
| **CREATION_DATE** | DATE | Date de création |
| **CREATED_BY** | NUMBER | Utilisateur créateur |
| **LAST_UPDATE_DATE** | DATE | Date de dernière modification |
| **LAST_UPDATED_BY** | NUMBER | Utilisateur modificateur |

### 1.3. Contrainte Unique Personnalisée (Dalkia)

#### Index `DKA_RA_INTERFACE_LINES_U1`

```sql
CREATE UNIQUE INDEX AR.DKA_RA_INTERFACE_LINES_U1 
ON AR.RA_INTERFACE_LINES_ALL (
    INTERFACE_LINE_CONTEXT,
    INTERFACE_LINE_ATTRIBUTE1,   -- Généralement : INVOICE_NUMBER
    INTERFACE_LINE_ATTRIBUTE2,   -- Généralement : LINE_NUMBER
    INTERFACE_LINE_ATTRIBUTE3,   -- Généralement : COMPANY_CODE
    INTERFACE_LINE_ATTRIBUTE4,   -- Généralement : TASK_CODE ou autre
    INTERFACE_LINE_ATTRIBUTE5,   -- Généralement : FIC_IDENT ou autre
    REQUEST_ID
);
```

**Objectif** : Empêcher l'insertion de doublons lors du chargement par le package `DKA_IARPAFAC_PKG`.

**Impact** :
- ✅ Prévient les doublons à l'insertion
- ⚠️ Génère une erreur `ORA-00001` si tentative d'insertion de doublon
- 🔧 Nécessite un nettoyage préalable des doublons dans `DKA_IARPAFAC_INTERFACE` avant insertion

---

## 🔎 2. Flux de Données

### 2.1. Architecture du Processus

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FLUX D'IMPORT DES FACTURES AR                    │
└─────────────────────────────────────────────────────────────────────┘

1. SOURCES EXTERNES
   ├── FAC02 (GCA - Fichiers factures clients)
   ├── HEF01 (CYC - Hercule)
   └── Autres systèmes

             ↓ Fichiers plats (CSV/TXT)

2. TABLE DE STAGING DALKIA
   DKA.DKA_IARPAFAC_INTERFACE
   ├── Colonnes : IARPAFAC_ID, INVOICE_NUMBER, LINE_NUMBER, LINE_TYPE,
   │              LOCAL_ACCOUNT, COMPANY_CODE, ORIGIN, FIC_IDENT, etc.
   ├── Programme : DKA_IARPAFAC_LOADER (chargement fichiers)
   └── Statut : OA_STATUS (A=accepté, P=en cours, R=rejeté)

             ↓ Package DKA_IARPAFAC_PKG

3. TABLE D'INTERFACE ORACLE AR
   AR.RA_INTERFACE_LINES_ALL
   ├── Colonnes standard Oracle : TRX_NUMBER, TRX_DATE, AMOUNT, etc.
   ├── Mapping attributs : 
   │   ├── INTERFACE_LINE_ATTRIBUTE1 = INVOICE_NUMBER
   │   ├── INTERFACE_LINE_ATTRIBUTE2 = LINE_NUMBER
   │   ├── INTERFACE_LINE_ATTRIBUTE3 = COMPANY_CODE
   │   └── INTERFACE_LINE_ATTRIBUTE4 = TASK_CODE
   └── Contrainte unique : DKA_RA_INTERFACE_LINES_U1

             ↓ Programme AutoInvoice (RAXMTR)

4. TABLES ORACLE AR (FACTURES VALIDÉES)
   AR.RA_CUSTOMER_TRX_ALL (en-têtes factures)
   AR.RA_CUSTOMER_TRX_LINES_ALL (lignes factures)
   AR.RA_CUST_TRX_LINE_GL_DIST_ALL (distributions GL)

             ↓ Validation et Comptabilisation

5. GENERAL LEDGER
   GL.GL_JE_LINES (écritures comptables)
```

### 2.2. Programmes Concurrents Impliqués

| Programme | Nom technique | Rôle |
|-----------|---------------|------|
| **Import Factures Clients** | DKA_IARPAFAC | Charger DKA_IARPAFAC_INTERFACE → RA_INTERFACE_LINES_ALL |
| **AutoInvoice Master** | RAXMTR | Valider et créer les factures depuis RA_INTERFACE_LINES_ALL |
| **AutoInvoice Execution Report** | RAXREV | Rapport d'exécution AutoInvoice |

---

## ⚠️ 3. Problèmes Courants

### 3.1. Violation de Contrainte Unique (ORA-00001)

#### Symptôme

```
ORA-00001: violation de contrainte unique (AR.DKA_RA_INTERFACE_LINES_U1)
Une erreur est survenue lors des contrôles d'une ligne de facture.
```

#### Cause Racine

Le package `DKA_IARPAFAC_PKG` tente d'insérer dans `RA_INTERFACE_LINES_ALL` plusieurs lignes avec la **même combinaison de clés** :
- INTERFACE_LINE_CONTEXT
- INTERFACE_LINE_ATTRIBUTE1 (INVOICE_NUMBER)
- INTERFACE_LINE_ATTRIBUTE2 (LINE_NUMBER)
- INTERFACE_LINE_ATTRIBUTE3 (COMPANY_CODE)
- INTERFACE_LINE_ATTRIBUTE4 (TASK_CODE)
- INTERFACE_LINE_ATTRIBUTE5 (autre)
- REQUEST_ID

#### Sources Possibles

1. **Doublons dans DKA_IARPAFAC_INTERFACE** :
   - Même fichier chargé plusieurs fois
   - Lignes dupliquées dans le fichier source
   - Erreur de traitement avec rechargement partiel

2. **Lignes non purgées** :
   - Anciennes lignes avec REQUEST_ID différent mais mêmes clés métier
   - Nécessite purge avant nouveau chargement

3. **Erreur logique de mapping** :
   - Même facture/ligne mappée plusieurs fois par erreur de programme

### 3.2. Lignes Orphelines (Non Traitées)

#### Symptôme

Lignes restant dans `RA_INTERFACE_LINES_ALL` avec `INTERFACE_STATUS IS NULL` après exécution d'AutoInvoice.

#### Causes

1. **Erreur de validation AutoInvoice** :
   - Client inexistant
   - Compte GL invalide
   - Données manquantes (montant, date, etc.)

2. **Programme AutoInvoice non exécuté** :
   - Échec du programme DKA_IARPAFAC
   - Arrêt manuel du traitement

#### Impact

- ✗ Factures non créées dans AR
- ✗ Pas de comptabilisation en GL
- ✗ Pollution de la table d'interface

### 3.3. Doublons Factures Créées

#### Symptôme

Même facture créée plusieurs fois dans `RA_CUSTOMER_TRX_ALL` avec des TRX_NUMBER différents.

#### Cause

- Chargement multiple via `RA_INTERFACE_LINES_ALL` avec clés différentes
- Absence de contrôle sur TRX_NUMBER dans l'interface

---

## 🔍 4. Requêtes de Diagnostic

### 4.1. Vue d'Ensemble de l'Interface

```sql
-- Synthèse globale : statut des lignes d'interface
SELECT 
    INTERFACE_LINE_CONTEXT,
    INTERFACE_STATUS,
    COUNT(*) AS NB_LIGNES,
    COUNT(DISTINCT INTERFACE_LINE_ATTRIBUTE1) AS NB_FACTURES,
    MIN(CREATION_DATE) AS PREMIERE_CREATION,
    MAX(CREATION_DATE) AS DERNIERE_CREATION,
    SUM(AMOUNT) AS MONTANT_TOTAL
FROM AR.RA_INTERFACE_LINES_ALL
WHERE CREATION_DATE >= TRUNC(SYSDATE) - 7  -- 7 derniers jours
GROUP BY INTERFACE_LINE_CONTEXT, INTERFACE_STATUS
ORDER BY INTERFACE_LINE_CONTEXT, INTERFACE_STATUS;
```

### 4.2. Détection de Doublons Potentiels

**Script complet** : [Detection_Doublons_RA_INTERFACE_LINES.sql](Detection_Doublons_RA_INTERFACE_LINES.sql)

```sql
-- Doublons basés sur la contrainte unique DKA_RA_INTERFACE_LINES_U1
-- Mapping réel du package DKA_IARPAFAC_PKG :
--   ATTRIBUTE1 = ORIGIN (GCA, CYC, etc.)
--   ATTRIBUTE2 = COMPANY_CODE (0001, 0441, etc.)
--   ATTRIBUTE3 = INVOICE_NUMBER (N° facture)
--   ATTRIBUTE4 = LINE_NUMBER (N° ligne)
--   ATTRIBUTE5 = Période YYYYMM (202601, etc.)

SELECT 
    INTERFACE_LINE_CONTEXT,
    INTERFACE_LINE_ATTRIBUTE1 AS ORIGIN,           -- GCA, CYC, etc.
    INTERFACE_LINE_ATTRIBUTE2 AS COMPANY_CODE,     -- 0001, 0441, etc.
    INTERFACE_LINE_ATTRIBUTE3 AS INVOICE_NUMBER,   -- N° facture
    INTERFACE_LINE_ATTRIBUTE4 AS LINE_NUMBER,      -- N° ligne
    INTERFACE_LINE_ATTRIBUTE5 AS PERIOD_YYYYMM,    -- Période (202601)
    REQUEST_ID,
    COUNT(*) AS NB_DOUBLONS,
    MIN(INTERFACE_LINE_ID) AS ID_MIN,
    MAX(INTERFACE_LINE_ID) AS ID_MAX,
    MIN(TO_CHAR(CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS')) AS PREMIERE_CREATION,
    MAX(TO_CHAR(CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS')) AS DERNIERE_CREATION,
    SUM(NVL(AMOUNT, 0)) AS MONTANT_TOTAL
FROM AR.RA_INTERFACE_LINES_ALL
WHERE INTERFACE_STATUS IS NULL  -- Lignes non traitées
  AND CREATION_DATE >= TRUNC(SYSDATE) - 7  -- 7 derniers jours
GROUP BY 
    INTERFACE_LINE_CONTEXT,
    INTERFACE_LINE_ATTRIBUTE1,  -- ORIGIN
    INTERFACE_LINE_ATTRIBUTE2,  -- COMPANY_CODE
    INTERFACE_LINE_ATTRIBUTE3,  -- INVOICE_NUMBER
    INTERFACE_LINE_ATTRIBUTE4,  -- LINE_NUMBER
    INTERFACE_LINE_ATTRIBUTE5,  -- Période
    REQUEST_ID
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC, INTERFACE_LINE_ATTRIBUTE3, INTERFACE_LINE_ATTRIBUTE4;
```

### 4.3. Lignes Non Traitées (Orphelines)

```sql
-- Lignes présentes depuis plus de 24h sans traitement
SELECT 
    INTERFACE_LINE_ID,
    INTERFACE_LINE_CONTEXT,
    INTERFACE_LINE_ATTRIBUTE1 AS INVOICE_NUMBER,
    TRX_NUMBER,
    LINE_NUMBER,
    LINE_TYPE,
    AMOUNT,
    INTERFACE_STATUS,
    ERROR_MESSAGE,
    TO_CHAR(CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS CREATION,
    REQUEST_ID,
    TRUNC(SYSDATE - CREATION_DATE) AS NB_JOURS_ATTENTE
FROM AR.RA_INTERFACE_LINES_ALL
WHERE INTERFACE_STATUS IS NULL
  AND CREATION_DATE < TRUNC(SYSDATE) - 1
ORDER BY CREATION_DATE;
```

### 4.4. Erreurs AutoInvoice

```sql
-- Lignes rejetées par AutoInvoice avec messages d'erreur
SELECT 
    INTERFACE_LINE_ID,
    TRX_NUMBER AS FACTURE,
    LINE_NUMBER,
    INTERFACE_STATUS,
    ERROR_MESSAGE,
    INVALID_VALUE,
    TO_CHAR(CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS CREATION,
    REQUEST_ID
FROM AR.RA_INTERFACE_LINES_ALL
WHERE INTERFACE_STATUS = 'ERROR'
  AND CREATION_DATE >= TRUNC(SYSDATE) - 7
ORDER BY CREATION_DATE DESC;
```

### 4.5. Comptage par REQUEST_ID

```sql
-- Statistiques par programme concurrent (REQUEST_ID)
SELECT 
    REQUEST_ID,
    COUNT(*) AS NB_LIGNES,
    COUNT(DISTINCT INTERFACE_LINE_ATTRIBUTE1) AS NB_FACTURES,
    SUM(CASE WHEN INTERFACE_STATUS IS NULL THEN 1 ELSE 0 END) AS NON_TRAITE,
    SUM(CASE WHEN INTERFACE_STATUS = 'SUCCESS' THEN 1 ELSE 0 END) AS SUCCES,
    SUM(CASE WHEN INTERFACE_STATUS = 'ERROR' THEN 1 ELSE 0 END) AS ERREUR,
    MIN(CREATION_DATE) AS DATE_DEBUT,
    MAX(LAST_UPDATE_DATE) AS DATE_FIN,
    SUM(NVL(AMOUNT, 0)) AS MONTANT_TOTAL
FROM AR.RA_INTERFACE_LINES_ALL
WHERE CREATION_DATE >= TRUNC(SYSDATE) - 30
GROUP BY REQUEST_ID
ORDER BY REQUEST_ID DESC;
```

### 4.6. Analyse d'une Facture Spécifique

```sql
-- Détail d'une facture dans l'interface
SELECT 
    INTERFACE_LINE_ID,
    INTERFACE_LINE_CONTEXT,
    INTERFACE_LINE_ATTRIBUTE1 AS ORIGIN,
    INTERFACE_LINE_ATTRIBUTE2 AS COMPANY_CODE,
    INTERFACE_LINE_ATTRIBUTE3 AS INVOICE_NUMBER,
    INTERFACE_LINE_ATTRIBUTE4 AS LINE_NUMBER,
    LINE_TYPE,
    DESCRIPTION,
    QUANTITY,
    UNIT_SELLING_PRICE,
    AMOUNT,
    CURRENCY_CODE,
    INTERFACE_STATUS,
    ERROR_MESSAGE,
    TO_CHAR(CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS CREATION,
    REQUEST_ID
FROM AR.RA_INTERFACE_LINES_ALL
WHERE INTERFACE_LINE_ATTRIBUTE3 = :p_invoice_number  -- N° facture (ex: '0001S2601P211')
  AND INTERFACE_LINE_ATTRIBUTE1 = :p_origin          -- ORIGIN (ex: 'GCA')
  AND INTERFACE_LINE_ATTRIBUTE2 = :p_company_code    -- COMPANY_CODE (ex: '0001')
ORDER BY TO_NUMBER(INTERFACE_LINE_ATTRIBUTE4), INTERFACE_LINE_ID;
```

**⚠️ IMPORTANT** : Le mapping des INTERFACE_LINE_ATTRIBUTE a été corrigé suite à l'analyse de l'incident TP12011976. Voir [Detection_Doublons_RA_INTERFACE_LINES.sql](Detection_Doublons_RA_INTERFACE_LINES.sql) pour toutes les requêtes.

---

## ✅ 5. Solutions de Nettoyage

### 5.1. Purge des Lignes Traitées avec Succès

```sql
-- Supprimer les lignes réussies (déjà transformées en factures AR)
DELETE FROM AR.RA_INTERFACE_LINES_ALL
WHERE INTERFACE_STATUS = 'SUCCESS'
  AND LAST_UPDATE_DATE < TRUNC(SYSDATE) - 7;  -- Conservées 7 jours

COMMIT;
```

**Fréquence recommandée** : Hebdomadaire

### 5.2. Suppression de Doublons Avant Insertion

**Stratégie** : Nettoyer `DKA_IARPAFAC_INTERFACE` AVANT l'insertion dans `RA_INTERFACE_LINES_ALL`.

```sql
-- Supprimer les doublons dans DKA_IARPAFAC_INTERFACE
-- (voir script Suppression_Doublons_DKA_IARPAFAC_INTERFACE.sql)

DELETE FROM DKA.DKA_IARPAFAC_INTERFACE dii
WHERE dii.IARPAFAC_ID NOT IN (
    SELECT MIN(dii2.IARPAFAC_ID)
    FROM DKA.DKA_IARPAFAC_INTERFACE dii2
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
    FROM DKA.DKA_IARPAFAC_INTERFACE dii3
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

### 5.3. Correction des Erreurs AutoInvoice

```sql
-- Supprimer les lignes en erreur pour rechargement
DELETE FROM AR.RA_INTERFACE_LINES_ALL
WHERE INTERFACE_STATUS = 'ERROR'
  AND REQUEST_ID = :p_request_id;  -- Spécifier le REQUEST_ID

COMMIT;
```

**Ensuite** : Corriger les données dans `DKA_IARPAFAC_INTERFACE` et relancer `DKA_IARPAFAC`.

### 5.4. Purge Complète pour Rechargement

⚠️ **ATTENTION** : À utiliser uniquement en environnement de test ou après accord métier.

```sql
-- Sauvegarder avant purge
CREATE TABLE RA_INTERFACE_LINES_BKP_05032026 AS
SELECT * FROM AR.RA_INTERFACE_LINES_ALL
WHERE REQUEST_ID = :p_request_id;

-- Supprimer les lignes du REQUEST_ID spécifique
DELETE FROM AR.RA_INTERFACE_LINES_ALL
WHERE REQUEST_ID = :p_request_id;

COMMIT;
```

---

## 🛡️ 6. Bonnes Pratiques

### 6.1. Prévention des Doublons

#### A. Nettoyage Préalable de DKA_IARPAFAC_INTERFACE

**Toujours** exécuter le nettoyage des doublons dans `DKA_IARPAFAC_INTERFACE` **AVANT** l'insertion dans `RA_INTERFACE_LINES_ALL`.

```sql
-- Script automatisé de nettoyage
@Suppression_Doublons_DKA_IARPAFAC_INTERFACE.sql
```

#### B. Contrôle Applicatif dans DKA_IARPAFAC_PKG

Ajouter un contrôle de doublons avant insertion :

```sql
-- Exemple de contrôle dans le package
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO   v_exists
    FROM   AR.RA_INTERFACE_LINES_ALL
    WHERE  INTERFACE_LINE_CONTEXT = :p_context
      AND  INTERFACE_LINE_ATTRIBUTE1 = :p_invoice_number
      AND  INTERFACE_LINE_ATTRIBUTE2 = :p_line_number
      AND  INTERFACE_LINE_ATTRIBUTE3 = :p_company_code
      AND  REQUEST_ID = :p_request_id;
    
    IF v_exists > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'Doublon détecté pour facture ' || :p_invoice_number || 
            ' ligne ' || :p_line_number);
    END IF;
    
    -- Continuer l'insertion...
END;
```

### 6.2. Purge Régulière

**Programme automatisé de purge** :

```sql
-- Créer un programme concurrent de purge
-- Exécution : Quotidienne (nuit)
-- Critères : 
--   - INTERFACE_STATUS = 'SUCCESS' AND LAST_UPDATE_DATE < SYSDATE - 7
--   - INTERFACE_STATUS IS NULL AND CREATION_DATE < SYSDATE - 30

DELETE FROM AR.RA_INTERFACE_LINES_ALL
WHERE (INTERFACE_STATUS = 'SUCCESS' AND LAST_UPDATE_DATE < TRUNC(SYSDATE) - 7)
   OR (INTERFACE_STATUS IS NULL AND CREATION_DATE < TRUNC(SYSDATE) - 30);

COMMIT;
```

### 6.3. Monitoring Quotidien

**Requête de surveillance** à intégrer dans `Controle_Quotidien_Complet.sql` :

```sql
-- Alerte si lignes non traitées > 24h
SELECT 
    'ALERTE_RA_INTERFACE' AS TYPE_ALERTE,
    COUNT(*) AS NB_LIGNES_BLOQUEES,
    MIN(CREATION_DATE) AS PLUS_ANCIENNE,
    MAX(CREATION_DATE) AS PLUS_RECENTE
FROM AR.RA_INTERFACE_LINES_ALL
WHERE INTERFACE_STATUS IS NULL
  AND CREATION_DATE < TRUNC(SYSDATE) - 1
HAVING COUNT(*) > 0;
```

### 6.4. Gestion des Erreurs AutoInvoice

**Processus de correction** :

1. **Identifier les erreurs** :
   ```sql
   SELECT DISTINCT ERROR_MESSAGE, COUNT(*)
   FROM AR.RA_INTERFACE_LINES_ALL
   WHERE INTERFACE_STATUS = 'ERROR'
   GROUP BY ERROR_MESSAGE;
   ```

2. **Supprimer les lignes en erreur** :
   ```sql
   DELETE FROM AR.RA_INTERFACE_LINES_ALL
   WHERE INTERFACE_STATUS = 'ERROR'
     AND REQUEST_ID = :p_request_id;
   ```

3. **Corriger les données source** dans `DKA_IARPAFAC_INTERFACE`

4. **Relancer le programme** `DKA_IARPAFAC`

---

## 📊 7. Cas d'Usage : Incident TP12011976

### Contexte

- **Date** : 09/01/2026
- **REQUEST_ID** : 46750251
- **Erreur** : `ORA-00001` - Violation de `DKA_RA_INTERFACE_LINES_U1`
- **Cause** : Doublons dans `DKA_IARPAFAC_INTERFACE` (facture 0001S2601P211 avec 7 lignes identiques)

### Solution Appliquée

1. ✅ Identification des 138 lignes en doublon (30 factures)
2. ✅ Suppression des doublons dans `DKA_IARPAFAC_INTERFACE`
3. ✅ Conservation de la ligne la plus ancienne (plus petit `IARPAFAC_ID`)
4. ✅ Relance réussie du programme `DKA_IARPAFAC`

### Résultat

- **Avant** : 214 061 lignes (dont 138 doublons)
- **Après** : 213 923 lignes (sans doublons)
- **Factures créées** : 138 906 factures validées dans AR

### Leçons Apprises

1. ⚠️ **Toujours nettoyer les doublons** dans `DKA_IARPAFAC_INTERFACE` avant insertion
2. ✅ **Contrainte DKA_RA_INTERFACE_LINES_U1** est efficace mais nécessite nettoyage préalable
3. 📋 **Documenter les doublons** pour identifier la source (fichier, système, etc.)
4. 🔄 **Automatiser le contrôle** dans le package `DKA_IARPAFAC_PKG`

---

## 📝 8. Checklist de Validation

### Avant Chargement de Factures

- [ ] Vérifier l'absence de doublons dans `DKA_IARPAFAC_INTERFACE`
- [ ] Exécuter le script de nettoyage si nécessaire
- [ ] Vérifier les données client (CUSTOMER_ID, CUSTOMER_NUMBER)
- [ ] Valider les comptes GL (CODE_COMBINATION_ID)
- [ ] Contrôler le format des dates et montants

### Après Chargement dans RA_INTERFACE_LINES_ALL

- [ ] Vérifier le nombre de lignes insérées
- [ ] Contrôler l'absence d'erreurs `ORA-00001`
- [ ] Vérifier `INTERFACE_STATUS IS NULL` (prêt pour AutoInvoice)

### Après Exécution AutoInvoice

- [ ] Vérifier `INTERFACE_STATUS = 'SUCCESS'` pour toutes les lignes
- [ ] Analyser les lignes en erreur (`INTERFACE_STATUS = 'ERROR'`)
- [ ] Confirmer la création des factures dans `RA_CUSTOMER_TRX_ALL`
- [ ] Vérifier la comptabilisation en GL si nécessaire

### Purge Régulière

- [ ] Supprimer les lignes `SUCCESS` après 7 jours
- [ ] Analyser les lignes orphelines après 30 jours
- [ ] Documenter les suppressions (REQUEST_ID, dates, nombre de lignes)

---Detection_Doublons_RA_INTERFACE_LINES.sql`** : 7 requêtes de détection des doublons (ce fichier)
- **`

## 🔗 9. Références

### Scripts Disponibles

- **`Suppression_Doublons_DKA_IARPAFAC_INTERFACE.sql`** : Nettoyage des doublons en amont
- **`Analyse_Doublons_DKA_IARPAFAC_INTERFACE.md`** : Analyse complète de la table staging
- **`TP12011976/analyse.md`** : Incident ORA-00001 résolu

### Documentation Oracle

- **Table** : `AR.RA_INTERFACE_LINES_ALL`
- **Programme** : AutoInvoice (RAXMTR)
- **Guide** : Oracle Receivables User Guide (Release 12.2)
- **Note MOS** : 1575302.1 - "AutoInvoice Import Program (RAXMTR) Overview"

### Tables Liées

| Table | Rôle |
|-------|------|
| `DKA.DKA_IARPAFAC_INTERFACE` | Table de staging Dalkia |
| `AR.RA_INTERFACE_LINES_ALL` | Interface Oracle AR (cette table) |
| `AR.RA_CUSTOMER_TRX_ALL` | Factures AR validées |
| `AR.RA_CUSTOMER_TRX_LINES_ALL` | Lignes de factures AR |
| `AR.RA_CUST_TRX_LINE_GL_DIST_ALL` | Distributions GL des factures |

### Packages PL/SQL

| Package | Rôle |
|---------|------|
| `DKA.DKA_IARPAFAC_PKG` | Insertion DKA_IARPAFAC_INTERFACE → RA_INTERFACE_LINES_ALL |
| `AR_INVOICE_API_PUB` | API Oracle pour création de factures |

---

## 📌 Conclusion

La table `RA_INTERFACE_LINES_ALL` est un point critique du flux d'import des factures AR. Les doublons causent des échecs d'insertion (`ORA-00001`) en raison de la contrainte unique `DKA_RA_INTERFACE_LINES_U1`. La solution durable consiste à :

1. ✅ **Nettoyer systématiquement** `DKA_IARPAFAC_INTERFACE` avant insertion
2. ✅ **Purger régulièrement** les lignes traitées (SUCCESS après 7 jours)
3. ✅ **Surveiller quotidiennement** les lignes orphelines et erreurs
4. ✅ **Automatiser les contrôles** dans les packages PL/SQL (DKA_IARPAFAC_PKG)

**⚠️ POINT CLÉ** : La contrainte `DKA_RA_INTERFACE_LINES_U1` protège contre les doublons mais nécessite un nettoyage préalable rigoureux de la table staging `DKA_IARPAFAC_INTERFACE`.

---

**Statut** : 🟢 Documentation complète  
**Priorité** : 🔴 Haute - Table d'interface critique  
**Action requise** : Intégrer nettoyage automatique et monitoring quotidien  
**Voir aussi** : [Analyse_Doublons_DKA_IARPAFAC_INTERFACE.md](Analyse_Doublons_DKA_IARPAFAC_INTERFACE.md)
