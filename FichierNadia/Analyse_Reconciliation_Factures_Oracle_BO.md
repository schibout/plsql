# Analyse - Procédure de Réconciliation Factures Payées Oracle R12 / BO

**Date d'analyse** : 18/02/2026  
**Auteur** : GitHub Copilot  
**Base de données** : Oracle EBS 12.2.13 + Base BO (Hercule)  
**Périmètre** : Contrôle quotidien des écarts de statut de paiement AP

---

## 1. CONTEXTE ET OBJECTIF

### Problématique Métier

Les factures fournisseurs payées dans Oracle EBS (module AP) doivent être synchronisées quotidiennement avec l'entrepôt de données BO (DWH_ECHEANCIER_AP). Des écarts apparaissent régulièrement où des factures marquées `PAYMENT_STATUS_FLAG = 'Y'` dans Oracle restent avec `statut_paiement <> 'PAYEE'` dans BO.

### Workflow Actuel

```
┌─────────────────┐     Email quotidien     ┌──────────────────┐
│  Oracle R12     │────────────────────────>│   Équipe Nadia   │
│  (Hind)         │   Factures payées J-1   │   (Contrôle BO)  │
└─────────────────┘                         └──────────────────┘
                                                      │
                                                      ▼
                                            ┌──────────────────┐
                                            │ Détection écarts │
                                            │  dans BO/Hercule │
                                            └──────────────────┘
                                                      │
                                             Si écart │
                                                      ▼
                                            ┌──────────────────┐
                                            │ Retour à Hind    │
                                            │ + Escalade TMA   │
                                            └──────────────────┘
```

### Processus Actuel

1. **Extraction Oracle** (par Hind) - Factures payées veille avec paiements non annulés
2. **Import manuel BO** - Chargement dans table temporaire `TRAVAIL_FACTURE_ORACLER12_PAYEES`
3. **Contrôle BO** - Requête de détection des écarts (2 versions proposées)
4. **Action corrective** - Email à Hind pour mise à jour du dump si écart détecté

---

## 2. ANALYSE TECHNIQUE DES REQUÊTES

### 2.1 Requête Oracle R12 - Extraction des Factures Payées

```sql
SELECT    
    aia.invoice_id as ID_FACTURE,
    aia.invoice_num,
    aia.payment_status_flag,
    aia.last_update_date
FROM ap_invoices_all aia        
WHERE aia.PAYMENT_STATUS_FLAG = 'Y'
  AND nvl(AMOUNT_PAID,0) != 0
  AND invoice_amount != 0
  AND trunc(aia.last_update_date) = trunc(sysdate-1)
  AND exists (
      SELECT 1
      FROM AP_INVOICE_PAYMENTS_all AIP, AP_CHECKS_ALL AC
      WHERE aia.INVOICE_ID = AIP.INVOICE_ID
        AND AIP.CHECK_ID = AC.CHECK_ID
        AND ac.status_lookup_code != 'VOIDED'
        AND trunc(aip.last_update_date) = trunc(sysdate-1)
  )
ORDER BY aia.last_update_date desc;
```

**Points positifs** :
- ✅ Filtre sur `status_lookup_code != 'VOIDED'` exclut les paiements annulés
- ✅ Double vérification sur `last_update_date` (facture ET paiement modifiés J-1)
- ✅ Exclusion des montants nuls

**Points d'attention** :
- ⚠️ **Requête incomplète** : Ne retourne que 4 colonnes alors que BO compare aussi `NUM_FACTURE`
- ⚠️ **Risque de faux positifs** : `last_update_date` sur facture peut changer sans lien avec paiement
- ⚠️ **Performance** : `trunc()` sur colonnes indexées empêche l'utilisation d'index
- ⚠️ **Logique floue** : Si paiement créé J-2 mais facture mise à jour J-1 → non détecté

**Correction recommandée** :
```sql
-- Version optimisée avec index-friendly et sélection sur date de paiement
SELECT    
    aia.invoice_id AS ID_FACTURE,
    aia.invoice_num AS NUM_FACTURE,
    aia.payment_status_flag,
    aia.last_update_date AS FACTURE_LAST_UPDATE,
    ac.check_date AS DATE_PAIEMENT,
    ac.amount AS MONTANT_PAIEMENT
FROM ap_invoices_all aia
JOIN AP_INVOICE_PAYMENTS_all AIP 
    ON aia.INVOICE_ID = AIP.INVOICE_ID
JOIN AP_CHECKS_ALL AC 
    ON AIP.CHECK_ID = AC.CHECK_ID
WHERE aia.PAYMENT_STATUS_FLAG = 'Y'
  AND nvl(aia.AMOUNT_PAID, 0) != 0
  AND aia.invoice_amount != 0
  AND ac.status_lookup_code != 'VOIDED'
  AND ac.check_date >= trunc(sysdate-1)  -- Date du chèque/virement
  AND ac.check_date < trunc(sysdate)
ORDER BY ac.check_date DESC, aia.invoice_id;
```

---

### 2.2 Requêtes BO - Détection des Écarts

#### Version 1 : Avec clause IN (non recommandée)

```sql
SELECT ID_FACTURE, num_facture, statut_paiement, statut_facture
FROM DWH_ECHEANCIER_AP 
WHERE statut_paiement <> 'PAYEE'
  AND DWH_ECHEANCIER_AP.ID_FACTURE IN (
      SELECT ID_FACTURE FROM FINANCE.TRAVAIL_FACTURE_ORACLER12_PAYEES
  );
```

**Problèmes** :
- ❌ **Écarts masqués** : Ne détecte PAS les factures présentes dans Oracle mais absentes de BO
- ❌ **Performance** : Clause `IN` avec sous-requête peut être lente sur gros volumes
- ❌ **Pas de traçabilité** : Ne retourne pas les données Oracle pour comparaison

#### Version 2 : Avec LEFT OUTER JOIN (recommandée)

```sql
SELECT 
    TRAVAIL_FACTURE_ORACLER12_PAYEES.ID_FACTURE, 
    TRAVAIL_FACTURE_ORACLER12_PAYEES.num_facture, 
    DWH_ECHEANCIER_AP.statut_paiement, 
    DWH_ECHEANCIER_AP.statut_facture 
FROM FINANCE.TRAVAIL_FACTURE_ORACLER12_PAYEES
LEFT OUTER JOIN FINANCE.DWH_ECHEANCIER_AP 
    ON TRAVAIL_FACTURE_ORACLER12_PAYEES.ID_FACTURE = DWH_ECHEANCIER_AP.ID_FACTURE
   AND TRAVAIL_FACTURE_ORACLER12_PAYEES.NUM_FACTURE = DWH_ECHEANCIER_AP.NUM_FACTURE
WHERE DWH_ECHEANCIER_AP.statut_paiement <> 'PAYEE'
   OR DWH_ECHEANCIER_AP.ID_FACTURE IS NULL;
```

**Avantages** :
- ✅ Détecte les 2 types d'écarts : statut incorrect OU facture absente
- ✅ Jointure sur `ID_FACTURE` ET `NUM_FACTURE` (sécurité accrue)
- ✅ Retourne les données Oracle pour analyse comparative

**Amélioration proposée** :
```sql
-- Version enrichie avec typologie d'écart et données de diagnostic
SELECT 
    T.ID_FACTURE, 
    T.NUM_FACTURE,
    CASE 
        WHEN D.ID_FACTURE IS NULL THEN 'ABSENT_BO'
        WHEN D.statut_paiement <> 'PAYEE' THEN 'STATUT_INCORRECT'
        ELSE 'AUTRE'
    END AS TYPE_ECART,
    D.statut_paiement AS STATUT_BO,
    D.statut_facture AS STATUT_FACTURE_BO,
    D.type_facture,
    D.DATE_FACTURE,
    D.DATE_CREATION_FACTURE,
    T.DATE_PAIEMENT_ORACLE,  -- À ajouter dans table temporaire
    T.MONTANT_PAIEMENT_ORACLE -- À ajouter dans table temporaire
FROM FINANCE.TRAVAIL_FACTURE_ORACLER12_PAYEES T
LEFT OUTER JOIN FINANCE.DWH_ECHEANCIER_AP D
    ON T.ID_FACTURE = D.ID_FACTURE
   AND T.NUM_FACTURE = D.NUM_FACTURE
WHERE D.statut_paiement <> 'PAYEE'
   OR D.ID_FACTURE IS NULL
   OR (D.statut_facture = 'Annulé' AND D.statut_paiement = 'PAYEE'); -- Détecte incohérences
```

---

### 2.3 Requête Annexe - Extraction Factures Impayées par Année

```sql
SELECT ID_FACTURE, num_facture, statut_paiement, statut_facture, 
       type_facture, DATE_FACTURE, DATE_CREATION_FACTURE
FROM DWH_ECHEANCIER_AP
WHERE statut_paiement <> 'PAYEE'
  AND type_facture = 'STANDARD'
  AND EXTRACT(YEAR FROM DATE_FACTURE) = '2024'
  AND statut_facture NOT IN ('Annulé')
ORDER BY DATE_FACTURE ASC;
```

**Usage** : Envoi périodique à Hind pour mise à jour massive du dump BO

**Problèmes** :
- ⚠️ **Comparaison de types** : `EXTRACT(YEAR ...) = '2024'` compare NUMBER avec STRING (fonctionne mais peu orthodoxe)
- ⚠️ **Filtre incomplet** : Exclut seulement 'Annulé', mais quid de 'CANCELLED', 'VOID', etc. ?
- ⚠️ **Périmètre** : Pas de filtre sur ancienneté → risque de remonter très vieilles factures

**Correction** :
```sql
SELECT 
    ID_FACTURE, 
    num_facture, 
    statut_paiement, 
    statut_facture, 
    type_facture, 
    DATE_FACTURE, 
    DATE_CREATION_FACTURE,
    DATE_ECHEANCE,  -- Si disponible
    SYSDATE - DATE_FACTURE AS ANCIENNETE_JOURS
FROM DWH_ECHEANCIER_AP
WHERE statut_paiement <> 'PAYEE'
  AND type_facture = 'STANDARD'
  AND EXTRACT(YEAR FROM DATE_FACTURE) = 2024  -- Correction type
  AND statut_facture NOT IN ('Annulé', 'CANCELLED', 'VOID')
  AND DATE_FACTURE >= DATE '2024-01-01'  -- Sécurité supplémentaire
  AND DATE_FACTURE < DATE '2025-01-01'
ORDER BY DATE_FACTURE ASC;
```

---

## 3. PROBLÈMES IDENTIFIÉS

### 3.1 Problèmes de Processus

| Problème | Impact | Criticité |
|----------|--------|-----------|
| **Processus manuel** | Délai de détection (1 jour minimum), risque d'oubli | 🔴 ÉLEVÉE |
| **Pas de traçabilité** | Impossible d'auditer l'historique des écarts | 🟠 MOYENNE |
| **Pas de SLA** | Temps de résolution non mesuré, TMA sollicitée sans priorité claire | 🟠 MOYENNE |
| **Communication email** | Risque de perte de message, pas de workflow structuré | 🟡 FAIBLE |
| **Absence de métriques** | Impossible de mesurer qualité sync Oracle→BO | 🟠 MOYENNE |

### 3.2 Problèmes Techniques

| Problème | Impact | Criticité |
|----------|--------|-----------|
| **Table temporaire manuelle** | Erreurs de saisie, chronophage | 🟠 MOYENNE |
| **Structure table incomplète** | Manque colonnes DATE_PAIEMENT, MONTANT → diagnostic limité | 🟠 MOYENNE |
| **Requête Oracle non optimale** | Filtrage sur `last_update_date` au lieu de `check_date` | 🟡 FAIBLE |
| **Pas de gestion des doublons** | Risque si plusieurs paiements sur même facture J-1 | 🟡 FAIBLE |
| **Pas de purge table temporaire** | Accumulation de données obsolètes | 🟡 FAIBLE |

### 3.3 Cas Non Couverts

1. **Factures payées en plusieurs fois** : Si 2 paiements partiels J-1 → 2 lignes dans extraction Oracle
2. **Paiements annulés puis recréés** : Si annulation + nouveau paiement même jour
3. **Écarts de timing** : Traitement batch BO peut tourner avant/après extraction Oracle
4. **Factures annulées après paiement** : `statut_facture = 'Annulé'` mais `statut_paiement = 'PAYEE'`

---

## 4. RECOMMANDATIONS

### 4.1 Court Terme (1-2 semaines)

#### A. Améliorer la Requête Oracle
```sql
-- Requête complète avec toutes les colonnes nécessaires
SELECT    
    aia.invoice_id AS ID_FACTURE,
    aia.invoice_num AS NUM_FACTURE,
    aia.payment_status_flag,
    aia.invoice_amount,
    aia.amount_paid,
    ac.check_id AS PAIEMENT_ID,
    ac.check_number AS NUMERO_PAIEMENT,
    ac.check_date AS DATE_PAIEMENT,
    ac.amount AS MONTANT_PAIEMENT,
    ac.currency_code AS DEVISE,
    aia.last_update_date AS FACTURE_LAST_UPDATE
FROM ap_invoices_all aia
JOIN AP_INVOICE_PAYMENTS_all AIP 
    ON aia.INVOICE_ID = AIP.INVOICE_ID
JOIN AP_CHECKS_ALL AC 
    ON AIP.CHECK_ID = AC.CHECK_ID
WHERE aia.PAYMENT_STATUS_FLAG = 'Y'
  AND nvl(aia.AMOUNT_PAID, 0) != 0
  AND aia.invoice_amount != 0
  AND ac.status_lookup_code != 'VOIDED'
  AND ac.check_date >= trunc(sysdate-1)
  AND ac.check_date < trunc(sysdate)
ORDER BY ac.check_date DESC, aia.invoice_id;
```

#### B. Enrichir la Table Temporaire
```sql
CREATE TABLE FINANCE.TRAVAIL_FACTURE_ORACLER12_PAYEES (	
    ID_FACTURE NUMBER(*,0) NOT NULL,
    NUM_FACTURE VARCHAR2(500 BYTE) NOT NULL,
    PAIEMENT_ID NUMBER(*,0),
    DATE_PAIEMENT DATE,
    MONTANT_PAIEMENT NUMBER,
    DEVISE VARCHAR2(15),
    DATE_EXTRACTION DATE DEFAULT SYSDATE,
    CONSTRAINT PK_TRAVAIL_FAC_R12 PRIMARY KEY (ID_FACTURE, PAIEMENT_ID)
);

-- Index pour performance jointure
CREATE INDEX IDX_TRAVAIL_FAC_NUM ON FINANCE.TRAVAIL_FACTURE_ORACLER12_PAYEES(NUM_FACTURE);
```

#### C. Utiliser la Requête BO Optimisée
```sql
-- Requête de contrôle avec catégorisation des écarts
SELECT 
    T.ID_FACTURE, 
    T.NUM_FACTURE,
    T.DATE_PAIEMENT AS DATE_PAIEMENT_ORACLE,
    T.MONTANT_PAIEMENT AS MONTANT_ORACLE,
    D.statut_paiement AS STATUT_BO,
    D.statut_facture AS STATUT_FACTURE_BO,
    D.type_facture,
    D.DATE_FACTURE,
    CASE 
        WHEN D.ID_FACTURE IS NULL THEN 'ECART_CRITIQUE - Facture absente BO'
        WHEN D.statut_paiement <> 'PAYEE' AND D.statut_facture = 'Annulé' THEN 'ECART_MAJEUR - Facture annulée dans BO'
        WHEN D.statut_paiement <> 'PAYEE' THEN 'ECART_STANDARD - Statut incorrect'
        ELSE 'OK'
    END AS TYPE_ECART,
    T.DATE_EXTRACTION
FROM FINANCE.TRAVAIL_FACTURE_ORACLER12_PAYEES T
LEFT OUTER JOIN FINANCE.DWH_ECHEANCIER_AP D
    ON T.ID_FACTURE = D.ID_FACTURE
   AND T.NUM_FACTURE = D.NUM_FACTURE
WHERE D.statut_paiement <> 'PAYEE'
   OR D.ID_FACTURE IS NULL
ORDER BY 
    CASE 
        WHEN D.ID_FACTURE IS NULL THEN 1
        WHEN D.statut_facture = 'Annulé' THEN 2
        ELSE 3
    END,
    T.ID_FACTURE;
```

---

### 4.2 Moyen Terme (1-2 mois)

#### A. Créer une Table d'Historique des Écarts
```sql
CREATE TABLE FINANCE.DWH_ECHEANCIER_ECARTS_HISTO (
    ECART_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    DATE_DETECTION DATE NOT NULL,
    ID_FACTURE NUMBER(*,0) NOT NULL,
    NUM_FACTURE VARCHAR2(500),
    TYPE_ECART VARCHAR2(50),
    STATUT_ORACLE VARCHAR2(50),
    STATUT_BO VARCHAR2(50),
    DATE_PAIEMENT_ORACLE DATE,
    MONTANT_ORACLE NUMBER,
    DATE_RESOLUTION DATE,
    RESOLUTION_COMMENTAIRE VARCHAR2(4000),
    CREE_PAR VARCHAR2(100) DEFAULT USER,
    DATE_CREATION DATE DEFAULT SYSDATE
);

-- Index pour recherche
CREATE INDEX IDX_ECART_FACTURE ON FINANCE.DWH_ECHEANCIER_ECARTS_HISTO(ID_FACTURE);
CREATE INDEX IDX_ECART_DATE ON FINANCE.DWH_ECHEANCIER_ECARTS_HISTO(DATE_DETECTION);
CREATE INDEX IDX_ECART_TYPE ON FINANCE.DWH_ECHEANCIER_ECARTS_HISTO(TYPE_ECART);
```

#### B. Automatiser l'Insertion dans l'Historique
```sql
-- Procédure à exécuter après contrôle quotidien
INSERT INTO FINANCE.DWH_ECHEANCIER_ECARTS_HISTO (
    DATE_DETECTION, ID_FACTURE, NUM_FACTURE, TYPE_ECART,
    STATUT_ORACLE, STATUT_BO, DATE_PAIEMENT_ORACLE, MONTANT_ORACLE
)
SELECT 
    SYSDATE,
    T.ID_FACTURE, 
    T.NUM_FACTURE,
    CASE 
        WHEN D.ID_FACTURE IS NULL THEN 'ABSENT_BO'
        WHEN D.statut_paiement <> 'PAYEE' THEN 'STATUT_INCORRECT'
    END,
    'PAYEE',
    NVL(D.statut_paiement, 'N/A'),
    T.DATE_PAIEMENT,
    T.MONTANT_PAIEMENT
FROM FINANCE.TRAVAIL_FACTURE_ORACLER12_PAYEES T
LEFT OUTER JOIN FINANCE.DWH_ECHEANCIER_AP D
    ON T.ID_FACTURE = D.ID_FACTURE
   AND T.NUM_FACTURE = D.NUM_FACTURE
WHERE T.DATE_EXTRACTION = TRUNC(SYSDATE)  -- Seulement extraction du jour
  AND (D.statut_paiement <> 'PAYEE' OR D.ID_FACTURE IS NULL);

COMMIT;
```

#### C. Créer des Métriques de Suivi
```sql
-- Vue de pilotage quotidien
CREATE OR REPLACE VIEW FINANCE.V_ECARTS_PAIEMENT_KPI AS
SELECT 
    TRUNC(DATE_DETECTION) AS JOUR,
    COUNT(*) AS NB_ECARTS_TOTAL,
    SUM(CASE WHEN TYPE_ECART = 'ABSENT_BO' THEN 1 ELSE 0 END) AS NB_ABSENT_BO,
    SUM(CASE WHEN TYPE_ECART = 'STATUT_INCORRECT' THEN 1 ELSE 0 END) AS NB_STATUT_INCORRECT,
    SUM(CASE WHEN DATE_RESOLUTION IS NOT NULL THEN 1 ELSE 0 END) AS NB_RESOLUS,
    ROUND(AVG(CASE 
        WHEN DATE_RESOLUTION IS NOT NULL 
        THEN DATE_RESOLUTION - DATE_DETECTION 
    END), 2) AS DELAI_MOYEN_RESOLUTION_JOURS
FROM FINANCE.DWH_ECHEANCIER_ECARTS_HISTO
WHERE DATE_DETECTION >= TRUNC(SYSDATE-30)
GROUP BY TRUNC(DATE_DETECTION)
ORDER BY JOUR DESC;
```

---

### 4.3 Long Terme (3-6 mois)

#### A. Automatiser le Flux Complet via Programme Concurrent Oracle

**Objectif** : Remplacer le processus manuel par un job Oracle EBS

```sql
-- Package PL/SQL
CREATE OR REPLACE PACKAGE APPS.DKA_CONTROLE_PAIEMENT_BO AS
    PROCEDURE MAIN (
        errbuf OUT VARCHAR2,
        retcode OUT VARCHAR2,
        p_date_paiement IN VARCHAR2 DEFAULT NULL  -- Format YYYY-MM-DD, défaut = SYSDATE-1
    );
END DKA_CONTROLE_PAIEMENT_BO;
/

CREATE OR REPLACE PACKAGE BODY APPS.DKA_CONTROLE_PAIEMENT_BO AS

    PROCEDURE MAIN (
        errbuf OUT VARCHAR2,
        retcode OUT VARCHAR2,
        p_date_paiement IN VARCHAR2 DEFAULT NULL
    ) IS
        v_date_paiement DATE;
        v_nb_factures NUMBER := 0;
        v_nb_ecarts NUMBER := 0;
        v_db_link_bo VARCHAR2(100) := 'BO_HERCULE_LINK';  -- DB Link vers BO
        
    BEGIN
        -- Initialisation
        v_date_paiement := NVL(TO_DATE(p_date_paiement, 'YYYY-MM-DD'), TRUNC(SYSDATE-1));
        
        FND_FILE.PUT_LINE(FND_FILE.LOG, '=== Contrôle Paiements Oracle → BO ===');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Date paiement analysée : ' || TO_CHAR(v_date_paiement, 'DD/MM/YYYY'));
        
        -- 1. Purge table temporaire
        EXECUTE IMMEDIATE 'TRUNCATE TABLE FINANCE.TRAVAIL_FACTURE_ORACLER12_PAYEES@' || v_db_link_bo;
        
        -- 2. Insertion factures payées Oracle vers table BO
        INSERT INTO FINANCE.TRAVAIL_FACTURE_ORACLER12_PAYEES@BO_HERCULE_LINK (
            ID_FACTURE, NUM_FACTURE, PAIEMENT_ID, DATE_PAIEMENT, MONTANT_PAIEMENT, DEVISE
        )
        SELECT    
            aia.invoice_id,
            aia.invoice_num,
            ac.check_id,
            ac.check_date,
            ac.amount,
            ac.currency_code
        FROM ap_invoices_all aia
        JOIN AP_INVOICE_PAYMENTS_all AIP ON aia.INVOICE_ID = AIP.INVOICE_ID
        JOIN AP_CHECKS_ALL AC ON AIP.CHECK_ID = AC.CHECK_ID
        WHERE aia.PAYMENT_STATUS_FLAG = 'Y'
          AND nvl(aia.AMOUNT_PAID, 0) != 0
          AND ac.status_lookup_code != 'VOIDED'
          AND ac.check_date >= v_date_paiement
          AND ac.check_date < v_date_paiement + 1;
        
        v_nb_factures := SQL%ROWCOUNT;
        COMMIT;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Nombre de factures payées extraites : ' || v_nb_factures);
        
        -- 3. Détection et insertion écarts
        INSERT INTO FINANCE.DWH_ECHEANCIER_ECARTS_HISTO@BO_HERCULE_LINK (
            DATE_DETECTION, ID_FACTURE, NUM_FACTURE, TYPE_ECART,
            STATUT_ORACLE, STATUT_BO, DATE_PAIEMENT_ORACLE, MONTANT_ORACLE
        )
        SELECT 
            SYSDATE,
            T.ID_FACTURE, 
            T.NUM_FACTURE,
            CASE 
                WHEN D.ID_FACTURE IS NULL THEN 'ABSENT_BO'
                WHEN D.statut_paiement <> 'PAYEE' THEN 'STATUT_INCORRECT'
            END,
            'PAYEE',
            NVL(D.statut_paiement, 'N/A'),
            T.DATE_PAIEMENT,
            T.MONTANT_PAIEMENT
        FROM FINANCE.TRAVAIL_FACTURE_ORACLER12_PAYEES@BO_HERCULE_LINK T
        LEFT OUTER JOIN FINANCE.DWH_ECHEANCIER_AP@BO_HERCULE_LINK D
            ON T.ID_FACTURE = D.ID_FACTURE
           AND T.NUM_FACTURE = D.NUM_FACTURE
        WHERE D.statut_paiement <> 'PAYEE' OR D.ID_FACTURE IS NULL;
        
        v_nb_ecarts := SQL%ROWCOUNT;
        COMMIT;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Nombre d''écarts détectés : ' || v_nb_ecarts);
        
        -- 4. Génération rapport OUTPUT
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'RAPPORT DE CONTROLE PAIEMENTS ORACLE → BO');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '===========================================');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Date paiement : ' || TO_CHAR(v_date_paiement, 'DD/MM/YYYY'));
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Factures payées Oracle : ' || v_nb_factures);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Écarts détectés : ' || v_nb_ecarts);
        
        IF v_nb_ecarts > 0 THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'DÉTAIL DES ÉCARTS :');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '-------------------');
            
            FOR rec IN (
                SELECT * FROM FINANCE.DWH_ECHEANCIER_ECARTS_HISTO@BO_HERCULE_LINK
                WHERE TRUNC(DATE_DETECTION) = TRUNC(SYSDATE)
                ORDER BY TYPE_ECART, ID_FACTURE
            ) LOOP
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 
                    rec.TYPE_ECART || ' | Facture ' || rec.NUM_FACTURE || 
                    ' (ID:' || rec.ID_FACTURE || ') | Montant: ' || rec.MONTANT_ORACLE ||
                    ' | Statut BO: ' || rec.STATUT_BO
                );
            END LOOP;
        END IF;
        
        -- Conclusion
        retcode := CASE WHEN v_nb_ecarts = 0 THEN '0' ELSE '1' END;  -- WARNING si écarts
        errbuf := CASE WHEN v_nb_ecarts = 0 THEN 'OK' ELSE v_nb_ecarts || ' écarts détectés' END;
        
    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERREUR : ' || SQLERRM);
            retcode := '2';
            errbuf := SQLERRM;
            ROLLBACK;
    END MAIN;

END DKA_CONTROLE_PAIEMENT_BO;
/
```

**Enregistrement Programme Concurrent** :
- Nom court : `DKA_CTRL_PAIEMENT_BO`
- Nom : `Contrôle Paiements Oracle vers BO`
- Exécutable : PL/SQL Stored Procedure → `DKA_CONTROLE_PAIEMENT_BO.MAIN`
- Output : `Text`

**Planification** : Request Set quotidien à 08h00 (après batch nuit BO)

#### B. Intégration avec ControlM

**Job ControlM** :
```ini
[JOB:CTRL_PAIEMENT_BO_QUOTIDIEN]
Application = FINFIN
Sub-Application = AP
Description = Controle quotidien synchronisation paiements Oracle→BO
Command = concsub apps/****** SYSADMIN WAIT=N CONCURRENT DKA_CTRL_PAIEMENT_BO
Schedule = Every day at 08:00
Predecessors = BATCH_HERCULE_NUIT (job de chargement BO)
On-Do Actions = 
    - Si WARNING (retcode=1) : Email à nadia@dalkia.fr, hind@dalkia.fr, TMA
    - Si ERROR (retcode=2) : Alerte criticité haute + SMS astreinte
```

#### C. Tableau de Bord Business Objects

**Rapport BO** : "Suivi Qualité Synchronisation Paiements"
- **Indicateur 1** : Taux de synchronisation quotidien (% factures sans écart)
- **Indicateur 2** : Délai moyen de résolution des écarts (en heures)
- **Indicateur 3** : Top 10 types d'écarts récurrents
- **Graphique** : Évolution sur 30 jours du nombre d'écarts par type

---

## 5. ANALYSE D'IMPACT

### 5.1 Bénéfices Attendus

| Bénéfice | Court Terme | Moyen Terme | Long Terme |
|----------|-------------|-------------|------------|
| **Réduction délai détection** | - | 1 jour → 2h | 1 jour → Temps réel |
| **Traçabilité** | - | ✅ Historique complet | ✅ + Indicateurs |
| **Charge manuelle** | -20% | -60% | -95% |
| **Taux de résolution** | - | +30% | +70% |
| **Visibilité management** | - | ✅ Reporting mensuel | ✅ Dashboard temps réel |

### 5.2 Risques et Mitigations

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| **DB Link BO indisponible** | Faible | Élevé | Gestion erreur + alerte, fallback sur processus manuel |
| **Volumétrie excessive** | Moyenne | Moyen | Limite de 10 000 factures/jour, purge auto table temporaire |
| **Faux positifs** | Moyenne | Faible | Phase pilote 2 semaines avec double contrôle manuel |
| **Modification schéma BO** | Faible | Élevé | Tests unitaires sur requêtes, monitoring alertes SQL |

---

## 6. PLAN D'ACTION

### Phase 1 - Quick Wins (Semaine 1-2)

- [ ] **J+1** : Valider corrections requêtes avec Hind et Nadia
- [ ] **J+2** : Modifier structure table temporaire (ajout colonnes DATE_PAIEMENT, MONTANT)
- [ ] **J+3** : Déployer requête BO optimisée avec LEFT JOIN
- [ ] **J+5** : Formation équipe Nadia sur nouvelle procédure

### Phase 2 - Industrialisation (Semaine 3-8)

- [ ] **S3** : Création table historique `DWH_ECHEANCIER_ECARTS_HISTO`
- [ ] **S4** : Développement package PL/SQL `DKA_CONTROLE_PAIEMENT_BO`
- [ ] **S5** : Tests unitaires sur environnement PREPROD
- [ ] **S6** : Création DB Link Oracle → BO (validation DSI)
- [ ] **S7** : Recette utilisateur avec Nadia + Hind
- [ ] **S8** : MEP production + monitoring rapproché 1 semaine

### Phase 3 - Optimisation (Mois 3-6)

- [ ] **M3** : Intégration ControlM avec gestion alertes
- [ ] **M4** : Développement rapport BO "Suivi Qualité Synchronisation"
- [ ] **M5** : Analyse statistiques 3 mois → optimisations
- [ ] **M6** : Bilan ROI + extension à d'autres flux (GL, FA)

---

## 7. ANNEXES

### 7.1 Volumétries Estimées

Basé sur analyse empirique dossier `FichierNadia` :
- **Factures payées quotidiennes** : 100-500 (estimation)
- **Taux d'écart observé** : 2-5% (à confirmer)
- **Écarts quotidiens attendus** : 2-25 factures
- **Rétention historique** : 2 ans (≈ 15 000 lignes)

### 7.2 Requêtes de Diagnostic

**Vérifier doublons dans extraction Oracle** :
```sql
SELECT ID_FACTURE, COUNT(*)
FROM FINANCE.TRAVAIL_FACTURE_ORACLER12_PAYEES
GROUP BY ID_FACTURE
HAVING COUNT(*) > 1;
```

**Analyser types d'écarts sur 30 jours** :
```sql
SELECT 
    TYPE_ECART,
    COUNT(*) AS NB_OCCURRENCES,
    ROUND(AVG(DATE_RESOLUTION - DATE_DETECTION), 2) AS DELAI_MOYEN_JOURS
FROM FINANCE.DWH_ECHEANCIER_ECARTS_HISTO
WHERE DATE_DETECTION >= TRUNC(SYSDATE-30)
GROUP BY TYPE_ECART
ORDER BY NB_OCCURRENCES DESC;
```

**Identifier factures récurrentes en écart** :
```sql
SELECT 
    ID_FACTURE,
    NUM_FACTURE,
    COUNT(*) AS NB_OCCURRENCES_ECART,
    MIN(DATE_DETECTION) AS PREMIER_ECART,
    MAX(DATE_DETECTION) AS DERNIER_ECART
FROM FINANCE.DWH_ECHEANCIER_ECARTS_HISTO
WHERE DATE_DETECTION >= TRUNC(SYSDATE-90)
GROUP BY ID_FACTURE, NUM_FACTURE
HAVING COUNT(*) > 3
ORDER BY NB_OCCURRENCES_ECART DESC;
```

---

## 8. RÉFÉRENCES

- **Documentation Oracle** : AP Payment Process (Doc ID 1299842.1)
- **Fichier source** : `FichierNadia/readme.md`
- **Flux métier** : Voir `Rapport_Traitements_Nuit_Oracle_EBS.md` (batch nocturnes)
- **Architecture BO** : Entrepôt Hercule - schéma FINANCE
- **Contact métier** : Hind (Oracle R12), Nadia (Contrôle BO), TMA (Support)

---

**Statut** : 🟢 Prêt pour validation  
**Prochaine étape** : Réunion de cadrage avec Hind, Nadia et MOA Finance
