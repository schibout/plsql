# 🔴 Diagnostic : Timeout DKA_GENERATE_URL_IMAGE_BDC

**Date** : 09/03/2026  
**Erreur** : "Erreur d'E/S: Une connexion existante a dû être fermée par l'hôte distant"  
**Commande** : `DKA_GENERATE_URL_IMAGE_BDC (01/01/2026, 31/12/2026)`

---

## 1. CAUSE RACINE : VOLUME TROP IMPORTANT

### 1.1 Volume Estimé (3 premiers mois 2026)

```
Janvier   : 51 109 BDC avec documents
Février   : 67 030 BDC avec documents  
Mars      : 23 389 BDC avec documents
──────────────────────────────────────
Total     : 141 528 BDC (3 mois)
```

**Projection année complète** : **~450 000 à 600 000 BDC** 📊

### 1.2 Complexité de la Procédure BDC

La procédure `DKA_GENERATE_URL_IMAGE_BDC` est **plus complexe** que `DKA_GENERATE_URL_IMAGE_FACTURE` :

```sql
1. DELETE FROM DKA_JMETER_ST.EXTRACTION_BDC;          -- Nettoyage
2. COMMIT;

3. INSERT ... (UNION de 2 requêtes)                   -- Extraction
   ├─ Requête 1 : BDC commençant par 'BC%' (URLs directs)
   └─ Requête 2 : Autres BDC (génération URLs via API)
4. COMMIT;

5. UPDATE FND_LOB_ACCESS SET TIMESTAMP = '2050';      -- Prolongation
6. COMMIT;

7. UPDATE ... REPLACE URL (vv_param2 -> vv_param4);  -- Nettoyage URL 1
8. COMMIT;

9. UPDATE ... REPLACE URL (vv_param3 -> vv_param4);  -- Nettoyage URL 2
10. COMMIT;

11. UPDATE ... REPLACE '/sheet/pdf/cancel';           -- Nettoyage URL 3
12. COMMIT;

13. UPDATE ... REPLACE '/sheet/pdf';                  -- Nettoyage URL 4
14. COMMIT;
```

**Résultat** : 7 COMMITS + 6 requêtes lourdes sur **~500 000 lignes** → **Timeout inévitable**

### 1.3 Temps d'Exécution Estimé

| Volume | Étapes | Temps estimé | Résultat |
|--------|--------|--------------|----------|
| 1 mois (50-70K) | 7 COMMITS + 6 requêtes | 5-10 minutes | ✅ OK |
| 3 mois (150K) | 7 COMMITS + 6 requêtes | 20-30 minutes | ⚠️ Risque timeout |
| 1 an (500K) | 7 COMMITS + 6 requêtes | 60-120 minutes | 🔴 TIMEOUT GARANTI |

**Timeout SQL Developer/SQLcl standard** : 30-60 minutes max

---

## 2. SOLUTIONS IMMÉDIATES

### ✅ SOLUTION 1 : Traiter par Mois (RECOMMANDÉ)

```sql
-- Janvier 2026
BEGIN 
    DKA_GENERATE_URL_IMAGE_BDC(
        TO_DATE('01/01/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'),
        TO_DATE('31/01/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
    );
END;
/

-- Février 2026
BEGIN 
    DKA_GENERATE_URL_IMAGE_BDC(
        TO_DATE('01/02/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'),
        TO_DATE('28/02/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
    );
END;
/

-- Mars 2026
BEGIN 
    DKA_GENERATE_URL_IMAGE_BDC(
        TO_DATE('01/03/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'),
        TO_DATE('31/03/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
    );
END;
/

-- ... répéter pour tous les mois
```

**Avantages** :
- ✅ Traitement < 10 minutes par mois
- ✅ Pas de timeout
- ✅ Possibilité de reprendre en cas d'erreur
- ✅ Monitoring mensuel du volume

**Note** : La table `DKA_JMETER_ST.EXTRACTION_BDC` est vidée à chaque appel (`DELETE FROM`), donc les résultats **s'accumulent** entre les mois.

⚠️ **ATTENTION** : Vérifier si c'est le comportement souhaité ou s'il faut tout retraiter d'un coup.

### ✅ SOLUTION 2 : Traiter par Trimestre

Si le traitement mensuel est trop fastidieux :

```sql
-- Q1 2026 (Jan-Fev-Mar)
BEGIN 
    DKA_GENERATE_URL_IMAGE_BDC(
        TO_DATE('01/01/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'),
        TO_DATE('31/03/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
    );
END;
/

-- Q2 2026 (Avr-Mai-Juin)
BEGIN 
    DKA_GENERATE_URL_IMAGE_BDC(
        TO_DATE('01/04/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'),
        TO_DATE('30/06/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
    );
END;
/

-- Q3 2026 (Juil-Aout-Sept)
BEGIN 
    DKA_GENERATE_URL_IMAGE_BDC(
        TO_DATE('01/07/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'),
        TO_DATE('30/09/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
    );
END;
/

-- Q4 2026 (Oct-Nov-Dec)
BEGIN 
    DKA_GENERATE_URL_IMAGE_BDC(
        TO_DATE('01/10/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'),
        TO_DATE('31/12/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
    );
END;
/
```

**Durée estimée** : 15-25 minutes par trimestre

### ⚠️ SOLUTION 3 : Augmenter le Timeout (SI NÉCESSAIRE)

Si vous voulez absolument traiter toute l'année d'un coup :

**Dans SQL Developer** :
```
Outils → Préférences → Base de données → Avancé
└─ Délai de connexion HTTP : 7200 secondes (2 heures)
```

**Dans SQLcl** :
```sql
SET TIMEOUT 7200000  -- 2 heures en millisecondes
```

**Dans la session Oracle** :
```sql
-- Augmenter les timeouts réseau
ALTER SESSION SET "_SQLNET_EXPIRE_TIME" = 0;  -- Désactiver timeout
```

⚠️ **Attention** : Même avec timeout élevé, le traitement peut échouer pour d'autres raisons (mémoire, rollback segment, etc.).

---

## 3. PROBLÈME ADDITIONNEL : DELETE vs ACCUMULATION

### 3.1 Comportement Actuel

```sql
DELETE FROM DKA_JMETER_ST.EXTRACTION_BDC;  -- Vide TOUTE la table
COMMIT;

INSERT INTO DKA_JMETER_ST.EXTRACTION_BDC ...;  -- Insère période demandée
COMMIT;
```

**Conséquence** : Si vous traitez mois par mois, **chaque nouveau mois écrase les précédents** !

### 3.2 Solutions

#### Option A : Désactiver le DELETE (modifier la procédure)

```sql
-- Commenter la ligne 49
-- DELETE FROM DKA_JMETER_ST.EXTRACTION_BDC;
-- COMMIT;
```

**Impact** : Les données s'accumulent → Traiter mois par mois OK

#### Option B : Gérer manuellement (sans modifier la procédure)

```sql
-- 1. Traiter Janvier
BEGIN DKA_GENERATE_URL_IMAGE_BDC(...); END;
/

-- 2. Sauvegarder les données de Janvier
CREATE TABLE EXTRACTION_BDC_BACKUP_JAN AS
SELECT * FROM DKA_JMETER_ST.EXTRACTION_BDC;

-- 3. Traiter Février
BEGIN DKA_GENERATE_URL_IMAGE_BDC(...); END;
/

-- 4. Réinsérer Janvier
INSERT INTO DKA_JMETER_ST.EXTRACTION_BDC
SELECT * FROM EXTRACTION_BDC_BACKUP_JAN;
COMMIT;

-- Répéter pour chaque mois...
```

**Impact** : Fastidieux mais fonctionne

#### Option C : Table temporaire globale (IDÉAL)

```sql
-- Créer une table temporaire pour accumuler les résultats
CREATE GLOBAL TEMPORARY TABLE EXTRACTION_BDC_TEMP (
    PO_HEADER_ID NUMBER,
    URL VARCHAR2(2000),
    ACCESS_ID VARCHAR2(50)
) ON COMMIT PRESERVE ROWS;

-- Traiter mois par mois en accumulant dans TEMP
FOR each month LOOP
    BEGIN DKA_GENERATE_URL_IMAGE_BDC(...); END;
    
    INSERT INTO EXTRACTION_BDC_TEMP
    SELECT * FROM DKA_JMETER_ST.EXTRACTION_BDC;
    COMMIT;
END LOOP;

-- À la fin, copier tout dans la table finale
TRUNCATE TABLE DKA_JMETER_ST.EXTRACTION_BDC;
INSERT INTO DKA_JMETER_ST.EXTRACTION_BDC
SELECT * FROM EXTRACTION_BDC_TEMP;
COMMIT;
```

---

## 4. SCRIPT COMPLET RECOMMANDÉ

### 4.1 Traitement Mensuel avec Sauvegarde

```sql
-- =====================================================================
-- SCRIPT : Génération URLs BDC 2026 (par mois avec accumulation)
-- =====================================================================
SET SERVEROUTPUT ON
SET TIMING ON

-- Créer table de backup si n'existe pas
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL (
    PO_HEADER_ID NUMBER,
    URL VARCHAR2(2000),
    ACCESS_ID VARCHAR2(50),
    MOIS_TRAITEMENT VARCHAR2(10)
);

-- Boucle sur les 12 mois
DECLARE
    v_start_date DATE;
    v_end_date DATE;
    v_count NUMBER;
    v_mois VARCHAR2(10);
BEGIN
    FOR i IN 1..12 LOOP
        -- Calculer dates début/fin du mois
        v_start_date := TO_DATE('01/' || LPAD(i, 2, '0') || '/2026', 'DD/MM/YYYY');
        v_end_date := LAST_DAY(v_start_date) + (86399/86400);  -- 23:59:59 du dernier jour
        v_mois := TO_CHAR(v_start_date, 'YYYY-MM');
        
        DBMS_OUTPUT.PUT_LINE('=================================================');
        DBMS_OUTPUT.PUT_LINE('Traitement ' || v_mois || ' ...');
        DBMS_OUTPUT.PUT_LINE('Début : ' || TO_CHAR(v_start_date, 'DD/MM/YYYY HH24:MI:SS'));
        DBMS_OUTPUT.PUT_LINE('Fin   : ' || TO_CHAR(v_end_date, 'DD/MM/YYYY HH24:MI:SS'));
        
        -- Appeler la procédure
        BEGIN
            DKA_GENERATE_URL_IMAGE_BDC(v_start_date, v_end_date);
            
            -- Sauvegarder les résultats du mois
            INSERT INTO DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL
            SELECT PO_HEADER_ID, URL, ACCESS_ID, v_mois
            FROM DKA_JMETER_ST.EXTRACTION_BDC;
            
            SELECT COUNT(*) INTO v_count FROM DKA_JMETER_ST.EXTRACTION_BDC;
            DBMS_OUTPUT.PUT_LINE('✓ ' || v_count || ' URLs générées pour ' || v_mois);
            
            COMMIT;
            
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('✗ ERREUR sur ' || v_mois || ' : ' || SQLERRM);
                ROLLBACK;
        END;
        
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    
    -- Statistiques finales
    DBMS_OUTPUT.PUT_LINE('=================================================');
    DBMS_OUTPUT.PUT_LINE('RÉSUMÉ FINAL');
    DBMS_OUTPUT.PUT_LINE('=================================================');
    
    FOR rec IN (
        SELECT MOIS_TRAITEMENT, COUNT(*) AS nb_urls
        FROM DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL
        GROUP BY MOIS_TRAITEMENT
        ORDER BY MOIS_TRAITEMENT
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(rec.MOIS_TRAITEMENT || ' : ' || rec.nb_urls || ' URLs');
    END LOOP;
    
    SELECT COUNT(*) INTO v_count FROM DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL;
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('TOTAL : ' || v_count || ' URLs générées');
    
END;
/

-- Vérifications finales
SELECT 'URLs par mois' AS statut, MOIS_TRAITEMENT, COUNT(*) AS nb
FROM DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL
GROUP BY MOIS_TRAITEMENT
ORDER BY MOIS_TRAITEMENT;

SELECT 'URLs uniques' AS statut, COUNT(DISTINCT PO_HEADER_ID) AS nb
FROM DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL;

SELECT 'URLs invalides' AS statut, COUNT(*) AS nb
FROM DKA_JMETER_ST.EXTRACTION_BDC_2026_FULL
WHERE URL IS NULL OR LENGTH(URL) < 20;
```

### 4.2 Version Simplifiée (Manuel, un mois à la fois)

```sql
-- MOIS 1 : Janvier 2026
BEGIN 
    DKA_GENERATE_URL_IMAGE_BDC(
        TO_DATE('01/01/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'),
        TO_DATE('31/01/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
    );
END;
/

-- Vérifier le résultat
SELECT COUNT(*) AS nb_urls_janvier FROM DKA_JMETER_ST.EXTRACTION_BDC;
-- Attendu : ~51 000

-- Sauvegarder avant de continuer
CREATE TABLE EXTRACTION_BDC_JAN_2026 AS
SELECT * FROM DKA_JMETER_ST.EXTRACTION_BDC;

-- MOIS 2 : Février 2026
BEGIN 
    DKA_GENERATE_URL_IMAGE_BDC(
        TO_DATE('01/02/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'),
        TO_DATE('28/02/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
    );
END;
/

-- Réinsérer Janvier
INSERT INTO DKA_JMETER_ST.EXTRACTION_BDC
SELECT * FROM EXTRACTION_BDC_JAN_2026;
COMMIT;

-- Vérifier
SELECT COUNT(*) FROM DKA_JMETER_ST.EXTRACTION_BDC;
-- Attendu : ~51 000 (Jan) + ~67 000 (Fev) = ~118 000

-- ... répéter pour chaque mois
```

---

## 5. MONITORING PENDANT L'EXÉCUTION

### 5.1 Vérifier la Progression (autre session)

```sql
-- Compter les lignes insérées en temps réel
SELECT COUNT(*) FROM DKA_JMETER_ST.EXTRACTION_BDC;

-- Voir les derniers BDC traités
SELECT MAX(PO_HEADER_ID), MAX(TO_NUMBER(ACCESS_ID))
FROM DKA_JMETER_ST.EXTRACTION_BDC;

-- Voir les sessions actives
SELECT sid, serial#, username, status, sql_id, 
       ROUND(sofar/totalwork*100, 2) AS pct_complete
FROM v$session_longops
WHERE username = USER
  AND sofar < totalwork
ORDER BY start_time DESC;
```

### 5.2 Identifier les Requêtes Lentes

```sql
-- Top requêtes actives
SELECT sql_text, elapsed_time/1000000 AS elapsed_sec, executions
FROM v$sql
WHERE sql_text LIKE '%EXTRACTION_BDC%'
  AND parsing_schema_name = 'APPS'
ORDER BY elapsed_time DESC
FETCH FIRST 5 ROWS ONLY;
```

---

## 6. RECOMMANDATIONS FINALES

### ✅ FAIRE

1. **Traiter par MOIS** (Janvier, Février, etc.)
2. **Sauvegarder** chaque résultat mensuel dans table backup
3. **Vérifier** le nombre d'URLs après chaque mois
4. **Corriger** la date de fin : utiliser `23:59:59` au lieu de `00:00:00`
5. **Exécuter en heures creuses** (nuit/week-end) pour éviter impact production

### ❌ NE PAS FAIRE

1. ❌ Traiter toute l'année d'un coup (timeout garanti)
2. ❌ Lancer pendant les heures de pointe
3. ❌ Oublier de sauvegarder les résultats entre chaque mois
4. ❌ Ignorer les messages d'erreur (analyser chaque échec)

### 📊 DURÉE ESTIMÉE

| Approche | Durée totale | Risque timeout |
|----------|-------------|----------------|
| Année complète | 60-120 min | 🔴 ÉLEVÉ |
| Trimestriel (4×) | 60-100 min | ⚠️ MOYEN |
| Mensuel (12×) | 60-120 min | ✅ FAIBLE |
| Mensuel avec script automatique | 60-120 min | ✅ FAIBLE + Automatique |

**Conclusion** : Le traitement **mensuel automatisé** via le script PL/SQL est la solution optimale.

---

**Prochaine action** : Utiliser le script de la section 4.1 pour traiter automatiquement tous les mois de 2026.
