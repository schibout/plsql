# Analyse et Procédure d'Annulation - Règlement 400011351

**Date d'analyse** : 27 janvier 2026  
**Contexte** : Clôture janvier 2026 - Règlement non comptabilisé à annuler  
**Base de données** : Oracle EBS 12.2.13 (19.25.0.0.0)

---

## 1. Contexte et Problématique

Un règlement portant le numéro **400011351** apparaît dans les enregistrements de clôture avec le statut suivant :
- **PAYMENT_HISTORY_ID** : 5317735
- **CHECK_ID** : 4880146
- **Transaction Type** : PAYMENT CREATED
- **Posted Flag** : N (Non comptabilisé)
- **TRX_BANK_AMOUNT** : NULL
- **Période** : JAN-26
- **Organisation** : 86 (DEW0001)

Ce paiement doit être annulé car il n'est pas comptabilisé et ne correspond à aucune opération valide.

---

## 2. Analyse du Règlement

### 2.1 Identification Complète

```sql
-- Requête d'identification du règlement
SELECT 
    AC.CHECK_ID,
    AC.CHECK_NUMBER,
    AC.CHECK_DATE,
    AC.AMOUNT,
    AC.CURRENCY_CODE,
    AC.STATUS_LOOKUP_CODE,
    AC.VOID_DATE,
    AC.ORG_ID,
    AC.VENDOR_ID,
    PV.VENDOR_NAME,
    PVS.VENDOR_SITE_CODE,
    ABA.BANK_ACCOUNT_NAME,
    AC.FUTURE_PAY_DUE_DATE,
    AC.CLEARED_DATE
FROM AP.AP_CHECKS_ALL AC
LEFT JOIN AP.AP_BANK_ACCOUNTS_ALL ABA 
    ON AC.BANK_ACCOUNT_ID = ABA.BANK_ACCOUNT_ID
LEFT JOIN AP.AP_SUPPLIERS PV 
    ON AC.VENDOR_ID = PV.VENDOR_ID
LEFT JOIN AP.AP_SUPPLIER_SITES_ALL PVS
    ON AC.VENDOR_SITE_ID = PVS.VENDOR_SITE_ID
WHERE AC.CHECK_ID = 4880146
    AND AC.ORG_ID = 86;
```

**Résultats** :
| Champ | Valeur |
|-------|--------|
| CHECK_ID | 4880146 |
| CHECK_NUMBER | 400011351 |
| CHECK_DATE | 16/01/26 |
| AMOUNT | 0,00 EUR |
| STATUS_LOOKUP_CODE | NEGOTIABLE |
| VOID_DATE | NULL |
| ORG_ID | 86 |
| VENDOR_ID | 8651 |
| VENDOR_NAME | EUROFINS LEA |
| VENDOR_SITE_CODE | FRA13290 |
| BANK_ACCOUNT_NAME | (vide) |
| CLEARED_DATE | NULL |

### 2.2 Historique de Paiement

```sql
-- Vérification de l'historique du paiement
SELECT 
    APH.PAYMENT_HISTORY_ID,
    APH.CHECK_ID,
    APH.TRANSACTION_TYPE,
    APH.TRX_BANK_AMOUNT,
    APH.POSTED_FLAG,
    APH.ACCOUNTING_DATE,
    APH.CREATION_DATE,
    APH.CREATED_BY
FROM AP.AP_PAYMENT_HISTORY_ALL APH
WHERE APH.CHECK_ID = 4880146
    AND APH.ORG_ID = 86
ORDER BY APH.PAYMENT_HISTORY_ID;
```

**Résultats** :
- **PAYMENT_HISTORY_ID** : 5317735
- **TRANSACTION_TYPE** : PAYMENT CREATED
- **TRX_BANK_AMOUNT** : NULL
- **POSTED_FLAG** : N (Non comptabilisé)
- **ACCOUNTING_DATE** : 16/01/26
- **CREATION_DATE** : 16/01/26
- **CREATED_BY** : 34279

### 2.3 Factures Liées

```sql
-- Vérification des factures liées au paiement
SELECT 
    AIP.CHECK_ID,
    AIP.INVOICE_ID,
    AI.INVOICE_NUM,
    AI.INVOICE_AMOUNT,
    AIP.AMOUNT AS PAYMENT_AMOUNT,
    AI.INVOICE_DATE,
    AI.PAYMENT_STATUS_FLAG,
    AI.CANCELLED_DATE,
    AIP.REVERSAL_FLAG
FROM AP.AP_INVOICE_PAYMENTS_ALL AIP
JOIN AP.AP_INVOICES_ALL AI 
    ON AIP.INVOICE_ID = AI.INVOICE_ID
WHERE AIP.CHECK_ID = 4880146
    AND AIP.ORG_ID = 86;
```

**Résultat** : Aucune facture liée (0 ligne retournée)

### 2.4 Problème du Numéro Non-Unique

```sql
-- Vérification de l'unicité du numéro de chèque
SELECT 
    COUNT(*) AS NB_OCCURENCES,
    COUNT(DISTINCT ORG_ID) AS NB_ORGS
FROM AP.AP_CHECKS_ALL
WHERE CHECK_NUMBER = '400011351';
```

**Constatation** : Le numéro 400011351 existe **11 fois** dans différentes organisations (ORG_ID: 85, 86, 87, 88, 89, 90, 91, 130), ce qui explique pourquoi la recherche par numéro seul est ambiguë.

---

## 3. Analyse de Faisabilité d'Annulation

### 3.1 Critères d'Annulation Validés

✅ **Paiement non rapproché** : CLEARED_DATE = NULL  
✅ **Non comptabilisé** : POSTED_FLAG = 'N'  
✅ **Aucune facture liée** : Aucun enregistrement dans AP_INVOICE_PAYMENTS_ALL  
✅ **Statut annulable** : STATUS_LOOKUP_CODE = 'NEGOTIABLE'  
✅ **Pas d'annulation précédente** : VOID_DATE = NULL  
✅ **Montant zéro** : Aucun impact financier

### 3.2 Programme Concurrent Oracle Applicable

Recherche du programme d'annulation :

```sql
-- Identification des programmes d'annulation disponibles
SELECT 
    FCP.CONCURRENT_PROGRAM_NAME,
    FCP.USER_CONCURRENT_PROGRAM_NAME,
    FCP.ENABLED_FLAG,
    FCP.EXECUTION_METHOD_CODE
FROM APPS.FND_CONCURRENT_PROGRAMS_VL FCP
WHERE FCP.CONCURRENT_PROGRAM_NAME LIKE '%VOID%'
   OR FCP.USER_CONCURRENT_PROGRAM_NAME LIKE '%Void%Payment%'
   OR FCP.USER_CONCURRENT_PROGRAM_NAME LIKE '%Annul%paiement%'
ORDER BY FCP.CONCURRENT_PROGRAM_NAME;
```

**Programme identifié** : **PYVOIDPY** - Void Cheque Payments (Actif)

---

## 4. Procédure d'Annulation

### 4.1 Méthode Recommandée - Interface Oracle (SIMPLE)

**Navigation** :
```
Achats > Paiements > Paiements/Annulations > Annulation de paiements
```

**Paramètres** :
1. **Organisation** : DEW0001 (ORG_ID 86)
2. **Annuler par** : Numéro de chèque
3. **Du numéro de chèque** : 400011351
4. **Au numéro de chèque** : 400011351
5. **Date d'annulation** : 27/01/2026
6. **Motif** : "Paiement créé par erreur - montant zéro"

### 4.2 Méthode Alternative - Programme Concurrent PL/SQL

```sql
-- =====================================================================
-- Script d'annulation du règlement 400011351
-- =====================================================================
-- Date : 27/01/2026
-- Contexte : Clôture JAN-26
-- Règlement : CHECK_ID 4880146, CHECK_NUMBER 400011351, ORG_ID 86
-- Fournisseur : EUROFINS LEA
-- =====================================================================




DECLARE
    v_request_id NUMBER;
    v_user_id    NUMBER := 34279;  -- User ayant créé le paiement
    v_resp_id    NUMBER;           -- À remplacer par votre RESP_ID AP
    v_resp_appl_id NUMBER := 200;  -- SQLAP Application
    v_org_id     NUMBER := 86;     -- DEW0001
BEGIN
    -- 1. Définir le contexte de l'organisation
    MO_GLOBAL.SET_POLICY_CONTEXT('S', v_org_id);
    
    -- 2. Initialiser le contexte applicatif
    -- ATTENTION : Remplacer v_resp_id par l'ID de votre responsabilité AP
    FND_GLOBAL.APPS_INITIALIZE(
        user_id      => v_user_id,
        resp_id      => v_resp_id,
        resp_appl_id => v_resp_appl_id
    );
    
    -- 3. Soumettre le programme d'annulation PYVOIDPY
    v_request_id := FND_REQUEST.SUBMIT_REQUEST(
        application => 'SQLAP',
        program     => 'PYVOIDPY',
        description => 'Annulation règlement 400011351 - EUROFINS LEA - Clôture JAN-26',
        start_time  => SYSDATE,
        sub_request => FALSE,
        argument1   => 'CHECK_NUMBER',         -- Void By
        argument2   => '400011351',            -- From Check Number
        argument3   => '400011351',            -- To Check Number
        argument4   => TO_CHAR(TO_DATE('16/01/2026', 'DD/MM/YYYY'), 'RRRR/MM/DD HH24:MI:SS'), -- From Date
        argument5   => TO_CHAR(TO_DATE('16/01/2026', 'DD/MM/YYYY'), 'RRRR/MM/DD HH24:MI:SS'), -- To Date
        argument6   => TO_CHAR(SYSDATE, 'RRRR/MM/DD HH24:MI:SS'), -- Void Date
        argument7   => NULL,                   -- Bank Account (optionnel)
        argument8   => NULL                    -- Payment Document (optionnel)
    );
    
    COMMIT;
    
    -- 4. Afficher le résultat
    IF v_request_id > 0 THEN
        DBMS_OUTPUT.PUT_LINE('=================================================');
        DBMS_OUTPUT.PUT_LINE('Programme soumis avec succès');
        DBMS_OUTPUT.PUT_LINE('Request ID: ' || v_request_id);
        DBMS_OUTPUT.PUT_LINE('=================================================');
        DBMS_OUTPUT.PUT_LINE('Vérifier le statut dans :');
        DBMS_OUTPUT.PUT_LINE('Administration système > Demandes concurrentes > Demandes spécifiques');
        DBMS_OUTPUT.PUT_LINE('=================================================');
    ELSE
        DBMS_OUTPUT.PUT_LINE('ERREUR : Impossible de soumettre le programme');
        DBMS_OUTPUT.PUT_LINE('Vérifier les paramètres et les privilèges');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERREUR : ' || SQLERRM);
        ROLLBACK;
END;
/
```

### 4.3 Vérification Post-Annulation

```sql
-- Vérifier le statut après annulation
SELECT 
    AC.CHECK_ID,
    AC.CHECK_NUMBER,
    AC.STATUS_LOOKUP_CODE,
    AC.VOID_DATE,
    AC.VOID_BY,
    APH.TRANSACTION_TYPE,
    APH.POSTED_FLAG,
    APH.ACCOUNTING_DATE
FROM AP.AP_CHECKS_ALL AC
LEFT JOIN AP.AP_PAYMENT_HISTORY_ALL APH
    ON AC.CHECK_ID = APH.CHECK_ID
WHERE AC.CHECK_ID = 4880146
    AND AC.ORG_ID = 86
ORDER BY APH.PAYMENT_HISTORY_ID DESC;
```
