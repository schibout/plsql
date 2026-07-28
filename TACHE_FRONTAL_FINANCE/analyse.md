# 📋 Analyse de la Procédure GET_UO_DALKIA_FROM_TACHE

**Date d'analyse** : 15/01/2026  
**Base de données** : EAI_FRONTAL_FINANCE  
**Version Oracle** : 19.25.0.0.0

---

## 1. Vue d'Ensemble

### Objectif
Cette procédure permet de récupérer l'**Unité Opérationnelle Dalkia (UO Dalkia)** à partir d'un **code tâche** et d'une **date de référence**.

### Informations Générales

| Attribut | Valeur |
|----------|--------|
| **Schéma** | EAI_FRONTAL_FINANCE |
| **Type** | PROCEDURE |
| **Statut** | VALID |
| **Date création** | 03/05/2023 |
| **Dernière modification** | 03/05/2023 |

---

## 2. Signature de la Procédure

```sql
PROCEDURE GET_UO_DALKIA_FROM_TACHE(
    input_prc  IN  EAI_FRONTAL_FINANCE.GET_UO_DALKIA_IN,
    output_prc OUT EAI_FRONTAL_FINANCE.GET_UO_DALKIA_OUT
)
```

### Type d'Entrée : GET_UO_DALKIA_IN

| Attribut | Type | Description |
|----------|------|-------------|
| `codeObjet` | VARCHAR2(10 CHAR) | Code de la tâche à rechercher |
| `dateObjet` | DATE | Date de référence pour la validité |

### Type de Sortie : GET_UO_DALKIA_OUT

| Attribut | Type | Description |
|----------|------|-------------|
| `UO_dalkia` | VARCHAR2(10 CHAR) | Code UO Dalkia trouvé (vide si erreur) |
| `code_retour` | VARCHAR2(6 CHAR) | Code de retour de l'exécution |
| `objet_erreur` | VARCHAR2(10 CHAR) | Objet en erreur (code tâche ou code Oracle) |

---

## 3. Codes de Retour

| Code | Signification | Action |
|------|---------------|--------|
| **FFI000** | ✅ Succès - UO Dalkia trouvée | Traitement normal |
| **FFI001** | ⚠️ Tâche non trouvée ou dates hors période | Vérifier le code tâche et les dates |
| **FFI999** | ❌ Erreur technique Oracle | Analyser le code ORA retourné dans `objet_erreur` |

---

## 4. Code Source Complet

```sql
PROCEDURE GET_UO_DALKIA_FROM_TACHE(
    input_prc IN EAI_FRONTAL_FINANCE.GET_UO_DALKIA_IN,
    output_prc OUT EAI_FRONTAL_FINANCE.GET_UO_DALKIA_OUT
) AS
    p_tache VARCHAR2(10 CHAR);
    p_dateTache DATE;
    p_UODalkia VARCHAR2(10 CHAR);
    p_codeRetour VARCHAR2(6 CHAR);
    p_objectErreur VARCHAR2(10 CHAR);
BEGIN
    BEGIN
        p_tache := input_prc.codeObjet;
        p_dateTache := input_prc.dateObjet;
        p_codeRetour := 'FFI000';
        p_objectErreur := '';
        
        SELECT mv.UODALKIA INTO p_UODalkia
        FROM EAI_FRONTAL_FINANCE.DKA_FFI_UODALKIA_TACHE mv
        WHERE mv.CODETACHE = p_tache
            AND mv.DATEDEBUTP <= p_dateTache 
            AND (mv.DATEFINP IS NULL OR mv.DATEFINP > p_dateTache)
            AND mv.DATEDEBUTCF <= p_dateTache 
            AND (mv.DATEFINCF IS NULL OR mv.DATEFINCF > p_dateTache);
            
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_UODalkia := '';
            p_codeRetour := 'FFI001';
            p_objectErreur := p_tache;
        WHEN OTHERS THEN
            p_UODalkia := '';
            p_codeRetour := 'FFI999';
            p_objectErreur := 'ORA' || SQLCODE;
    END;
    
    output_prc := EAI_FRONTAL_FINANCE.GET_UO_DALKIA_OUT(
        p_UODalkia, 
        p_codeRetour, 
        p_objectErreur
    );
END;
```

---

## 5. Vue Matérialisée Source : DKA_FFI_UODALKIA_TACHE

### Caractéristiques

| Attribut | Valeur |
|----------|--------|
| **Type** | Materialized View + Table |
| **Nombre de lignes** | **1 720 347** |
| **Mode rafraîchissement** | FAST ON COMMIT |
| **Dernier refresh** | 30/12/2025 16:18:38 |
| **Statut** | UNUSABLE (nécessite refresh) |
| **Tablespace** | TBS_PFE_FLOW_DATA |
| **Cache** | Oui |

### Structure

| Colonne | Type | Nullable | Description |
|---------|------|----------|-------------|
| `CODETACHE` | VARCHAR2(10) | Oui | Code de la tâche |
| `UODALKIA` | VARCHAR2(10) | Oui | Code UO Dalkia |
| `DATEDEBUTP` | DATE | Non | Date début validité projet |
| `DATEFINP` | DATE | Oui | Date fin validité projet |
| `DATEDEBUTCF` | DATE | Non | Date début validité centre finance |
| `DATEFINCF` | DATE | Oui | Date fin validité centre finance |
| `TACHE_ROWID` | ROWID | Oui | Référence ligne tâche |
| `PROJET_ROWID` | ROWID | Oui | Référence ligne projet |
| `CENTREF_ROWID` | ROWID | Oui | Référence ligne centre finance |

### Index

| Index | Colonnes | Type | Statut |
|-------|----------|------|--------|
| `IDX_DKA_FFI_UODALKIA_TACHE_T` | CODETACHE | NORMAL, NON UNIQUE | VALID |

### Requête de Définition

```sql
SELECT
    t.CODETACHE AS CODETACHE,
    cf.UODALKIA AS UODALKIA,
    p.DATEDEBUT AS DATEDEBUTP,
    p.DATEFIN AS DATEFINP,
    cf.DATEDEBUT AS DATEDEBUTCF,
    cf.DATEFIN AS DATEFINCF,
    t.ROWID AS TACHE_ROWID,
    p.ROWID AS PROJET_ROWID,
    cf.ROWID AS CENTREF_ROWID
FROM EAI_FRONTAL_FINANCE.DKA_FFI_TACHE t,
     EAI_FRONTAL_FINANCE.DKA_FFI_PROJET p,
     EAI_FRONTAL_FINANCE.DKA_FFI_CENTRE_FINANCE cf
WHERE t.PARENTPROJET = p.CODEPROJET
  AND p.PARENTCENTREFINANCE = cf.CODECENTREFINANCE
```

---

## 6. Tables Sources

| Table | Nombre de lignes | Rôle |
|-------|------------------|------|
| `DKA_FFI_TACHE` | **1 577 401** | Référentiel des tâches |
| `DKA_FFI_PROJET` | **86 621** | Référentiel des projets |
| `DKA_FFI_CENTRE_FINANCE` | **1 944** | Référentiel des centres financiers avec UO Dalkia |

### Modèle de Données

```
┌─────────────────────────┐
│  DKA_FFI_CENTRE_FINANCE │
│  (1 944 lignes)         │
│  • CODECENTREFINANCE    │
│  • UODALKIA            ◄──── UO Dalkia est ici !
│  • DATEDEBUT/DATEFIN    │
└───────────┬─────────────┘
            │ 1:N
            ▼
┌─────────────────────────┐
│     DKA_FFI_PROJET      │
│     (86 621 lignes)     │
│  • CODEPROJET           │
│  • PARENTCENTREFINANCE  │
│  • DATEDEBUT/DATEFIN    │
└───────────┬─────────────┘
            │ 1:N
            ▼
┌─────────────────────────┐
│     DKA_FFI_TACHE       │
│   (1 577 401 lignes)    │
│  • CODETACHE           ◄──── Entrée de la recherche
│  • PARENTPROJET         │
└─────────────────────────┘
```

---

## 7. Logique Fonctionnelle

### Algorithme de Recherche

1. **Entrée** : Code tâche + Date de référence
2. **Recherche** dans la vue matérialisée `DKA_FFI_UODALKIA_TACHE`
3. **Critères de validité** :
   - Le code tâche doit correspondre exactement
   - La date doit être **≥ DATEDEBUTP** (début projet)
   - La date doit être **< DATEFINP** (fin projet) ou DATEFINP NULL
   - La date doit être **≥ DATEDEBUTCF** (début centre finance)
   - La date doit être **< DATEFINCF** (fin centre finance) ou DATEFINCF NULL
4. **Sortie** : UO Dalkia du centre financier parent

### Diagramme de Flux

```
┌──────────────────────────────┐
│     Appel Procédure          │
│  (codeObjet, dateObjet)      │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│  Recherche dans MV           │
│  DKA_FFI_UODALKIA_TACHE      │
│  WHERE CODETACHE = p_tache   │
│    AND dates valides         │
└──────────────┬───────────────┘
               │
       ┌───────┴───────┐
       │               │
       ▼               ▼
┌─────────────┐  ┌─────────────┐
│  TROUVÉ     │  │ NON TROUVÉ  │
│  FFI000     │  │   FFI001    │
│  UO_Dalkia  │  │  (vide)     │
└─────────────┘  └─────────────┘
```

---

## 8. Procédures Connexes

| Procédure | Description | Dernière modification |
|-----------|-------------|----------------------|
| `GET_UO_DALKIA_FROM_TACHE` | Recherche par code tâche | 03/05/2023 |
| `GET_UO_DALKIA_FROM_PROJET` | Recherche par code projet | 30/12/2025 |
| `GET_UO_DALKIA_FROM_CF` | Recherche par centre finance | 03/05/2023 |

Ces trois procédures partagent les mêmes types IN/OUT et permettent de retrouver l'UO Dalkia à différents niveaux de la hiérarchie.

---

## 9. Contrôles de Refresh de la Vue Matérialisée

### 9.1 État Actuel Détecté

| Contrôle | Valeur | Statut |
|----------|--------|--------|
| **Staleness** | UNUSABLE | ❌ Critique |
| **Dernier refresh** | 30/12/2025 16:18:38 | ⚠️ 16 jours |
| **Lignes dans MV** | 1 720 347 | - |
| **Lignes attendues** | 1 677 701 | - |
| **Écart** | +42 646 lignes | ⚠️ MV désynchronisée |
| **Changements en attente (Tâches)** | 8 467 | ⚠️ |
| **Changements en attente (CF)** | 395 | ⚠️ |

### 9.2 Problème Identifié : Log Manquant

| Table Source | Mview Log | Statut |
|--------------|-----------|--------|
| DKA_FFI_TACHE | MLOG$_DKA_FFI_TACHE | ✅ OK |
| DKA_FFI_CENTRE_FINANCE | MLOG$_DKA_FFI_CENTRE_FINAN | ✅ OK |
| DKA_FFI_PROJET | **MANQUANT** | ❌ **PROBLÈME** |

> ⚠️ **Le MVIEW LOG sur DKA_FFI_PROJET est manquant !** Cela empêche le refresh FAST de fonctionner correctement.

---

## 10. Requêtes de Contrôle

### 10.1 Contrôle Pré-Refresh : Vérification de l'État

```sql
-- =====================================================================
-- CONTRÔLE 1 : État général de la vue matérialisée
-- =====================================================================
SELECT 
    mview_name,
    staleness,
    TO_CHAR(stale_since, 'DD/MM/YYYY HH24:MI:SS') as stale_depuis,
    compile_state,
    refresh_mode,
    refresh_method,
    fast_refreshable,
    last_refresh_type,
    TO_CHAR(last_refresh_date, 'DD/MM/YYYY HH24:MI:SS') as dernier_refresh
FROM user_mviews 
WHERE mview_name = 'DKA_FFI_UODALKIA_TACHE';
```

### 10.2 Contrôle Pré-Refresh : Changements en Attente

```sql
-- =====================================================================
-- CONTRÔLE 2 : Nombre de changements en attente dans les logs
-- =====================================================================
SELECT 'MLOG$_DKA_FFI_TACHE' as log_table, COUNT(*) as changements_en_attente 
FROM MLOG$_DKA_FFI_TACHE
UNION ALL
SELECT 'MLOG$_DKA_FFI_CENTRE_FINAN', COUNT(*) 
FROM MLOG$_DKA_FFI_CENTRE_FINAN;
```

### 10.3 Contrôle Pré-Refresh : Intégrité des Données Sources

```sql
-- =====================================================================
-- CONTRÔLE 3 : Intégrité référentielle des données sources
-- =====================================================================
SELECT 
    'Tâches orphelines (sans projet parent)' as controle,
    COUNT(*) as nb_anomalies,
    CASE WHEN COUNT(*) > 0 THEN '⚠️ ATTENTION' ELSE '✅ OK' END as statut
FROM DKA_FFI_TACHE t
WHERE NOT EXISTS (
    SELECT 1 FROM DKA_FFI_PROJET p 
    WHERE p.CODEPROJET = t.PARENTPROJET
)
UNION ALL
SELECT 
    'Projets orphelins (sans centre finance)',
    COUNT(*),
    CASE WHEN COUNT(*) > 0 THEN '⚠️ ATTENTION' ELSE '✅ OK' END
FROM DKA_FFI_PROJET p
WHERE NOT EXISTS (
    SELECT 1 FROM DKA_FFI_CENTRE_FINANCE cf 
    WHERE cf.CODECENTREFINANCE = p.PARENTCENTREFINANCE
)
UNION ALL
SELECT 
    'Centres finance sans UO Dalkia',
    COUNT(*),
    CASE WHEN COUNT(*) > 0 THEN '❌ CRITIQUE' ELSE '✅ OK' END
FROM DKA_FFI_CENTRE_FINANCE
WHERE UODALKIA IS NULL;
```

### 10.4 Contrôle Pré-Refresh : Cohérence des Dates

```sql
-- =====================================================================
-- CONTRÔLE 4 : Dates incohérentes (fin < début)
-- =====================================================================
SELECT 
    'Projets avec date fin < date début' as controle,
    COUNT(*) as anomalies
FROM DKA_FFI_PROJET
WHERE DATEFIN IS NOT NULL AND DATEFIN < DATEDEBUT
UNION ALL
SELECT 
    'Centres finance avec date fin < date début',
    COUNT(*)
FROM DKA_FFI_CENTRE_FINANCE
WHERE DATEFIN IS NOT NULL AND DATEFIN < DATEDEBUT;
```

### 10.5 Contrôle Pré-Refresh : Doublons Potentiels

```sql
-- =====================================================================
-- CONTRÔLE 5 : Tâches avec plusieurs UO Dalkia actives (doublons)
-- Risque de TOO_MANY_ROWS dans la procédure
-- =====================================================================
SELECT 
    CODETACHE,
    COUNT(*) as nb_uo_actives,
    LISTAGG(UODALKIA, ', ') WITHIN GROUP (ORDER BY UODALKIA) as uo_list
FROM DKA_FFI_UODALKIA_TACHE
WHERE (DATEFINP IS NULL OR DATEFINP > SYSDATE)
  AND (DATEFINCF IS NULL OR DATEFINCF > SYSDATE)
GROUP BY CODETACHE
HAVING COUNT(*) > 1
ORDER BY nb_uo_actives DESC;
```

### 10.6 Contrôle Post-Refresh : Comparaison Volumes

```sql
-- =====================================================================
-- CONTRÔLE 6 : Comparaison du nombre de lignes MV vs Source
-- À exécuter APRÈS le refresh
-- =====================================================================
SELECT 
    (SELECT COUNT(*) FROM DKA_FFI_UODALKIA_TACHE) as nb_lignes_mv,
    (SELECT COUNT(*) 
     FROM DKA_FFI_TACHE t
     JOIN DKA_FFI_PROJET p ON t.PARENTPROJET = p.CODEPROJET
     JOIN DKA_FFI_CENTRE_FINANCE cf ON p.PARENTCENTREFINANCE = cf.CODECENTREFINANCE
    ) as nb_lignes_attendu,
    (SELECT COUNT(*) FROM DKA_FFI_UODALKIA_TACHE) - 
    (SELECT COUNT(*) 
     FROM DKA_FFI_TACHE t
     JOIN DKA_FFI_PROJET p ON t.PARENTPROJET = p.CODEPROJET
     JOIN DKA_FFI_CENTRE_FINANCE cf ON p.PARENTCENTREFINANCE = cf.CODECENTREFINANCE
    ) as ecart
FROM dual;
```

### 10.7 Contrôle Post-Refresh : Vérification Index

```sql
-- =====================================================================
-- CONTRÔLE 7 : État des index après refresh
-- =====================================================================
SELECT 
    index_name,
    index_type,
    status,
    CASE WHEN status = 'VALID' THEN '✅ OK' ELSE '❌ REBUILD REQUIS' END as action
FROM user_indexes
WHERE table_name = 'DKA_FFI_UODALKIA_TACHE';
```

### 10.8 Contrôle Post-Refresh : Logs Vidés

```sql
-- =====================================================================
-- CONTRÔLE 8 : Vérifier que les logs sont vidés après refresh COMPLETE
-- =====================================================================
SELECT 
    'MLOG$_DKA_FFI_TACHE' as log_table, 
    COUNT(*) as lignes_restantes,
    CASE WHEN COUNT(*) = 0 THEN '✅ OK' ELSE '⚠️ Non vidé' END as statut
FROM MLOG$_DKA_FFI_TACHE
UNION ALL
SELECT 
    'MLOG$_DKA_FFI_CENTRE_FINAN', 
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ OK' ELSE '⚠️ Non vidé' END
FROM MLOG$_DKA_FFI_CENTRE_FINAN;
```

---

## 11. Script de Refresh avec Contrôles Intégrés

```sql
-- =====================================================================
-- SCRIPT DE REFRESH COMPLET AVEC CONTRÔLES
-- =====================================================================
-- Date : 15/01/2026
-- Vue : DKA_FFI_UODALKIA_TACHE
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON

DECLARE
    v_nb_mv_avant     NUMBER;
    v_nb_mv_apres     NUMBER;
    v_nb_source       NUMBER;
    v_nb_orphelins    NUMBER;
    v_staleness       VARCHAR2(30);
    v_start_time      TIMESTAMP := SYSTIMESTAMP;
    v_end_time        TIMESTAMP;
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('REFRESH DKA_FFI_UODALKIA_TACHE');
    DBMS_OUTPUT.PUT_LINE('Début : ' || TO_CHAR(v_start_time, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    -- CONTRÔLE PRE-REFRESH 1 : État actuel
    SELECT staleness INTO v_staleness 
    FROM user_mviews WHERE mview_name = 'DKA_FFI_UODALKIA_TACHE';
    DBMS_OUTPUT.PUT_LINE('État avant refresh : ' || v_staleness);
    
    -- CONTRÔLE PRE-REFRESH 2 : Nombre de lignes avant
    SELECT COUNT(*) INTO v_nb_mv_avant FROM DKA_FFI_UODALKIA_TACHE;
    DBMS_OUTPUT.PUT_LINE('Lignes MV avant : ' || TO_CHAR(v_nb_mv_avant, '999,999,999'));
    
    -- CONTRÔLE PRE-REFRESH 3 : Tâches orphelines
    SELECT COUNT(*) INTO v_nb_orphelins
    FROM DKA_FFI_TACHE t
    WHERE NOT EXISTS (SELECT 1 FROM DKA_FFI_PROJET p WHERE p.CODEPROJET = t.PARENTPROJET);
    DBMS_OUTPUT.PUT_LINE('Tâches orphelines : ' || v_nb_orphelins);
    
    IF v_nb_orphelins > 500 THEN
        DBMS_OUTPUT.PUT_LINE('⚠️ ATTENTION : Nombre élevé de tâches orphelines !');
    END IF;
    
    -- REFRESH COMPLET (COMPLETE car FAST impossible sans log sur PROJET)
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> Exécution du REFRESH COMPLETE...');
    
    DBMS_MVIEW.REFRESH(
        list                 => 'EAI_FRONTAL_FINANCE.DKA_FFI_UODALKIA_TACHE',
        method               => 'C',  -- Complete refresh
        atomic_refresh       => TRUE,
        out_of_place         => FALSE
    );
    
    v_end_time := SYSTIMESTAMP;
    
    -- CONTRÔLE POST-REFRESH 1 : État après
    SELECT staleness INTO v_staleness 
    FROM user_mviews WHERE mview_name = 'DKA_FFI_UODALKIA_TACHE';
    DBMS_OUTPUT.PUT_LINE('État après refresh : ' || v_staleness);
    
    -- CONTRÔLE POST-REFRESH 2 : Nombre de lignes après
    SELECT COUNT(*) INTO v_nb_mv_apres FROM DKA_FFI_UODALKIA_TACHE;
    DBMS_OUTPUT.PUT_LINE('Lignes MV après : ' || TO_CHAR(v_nb_mv_apres, '999,999,999'));
    
    -- CONTRÔLE POST-REFRESH 3 : Lignes attendues
    SELECT COUNT(*) INTO v_nb_source
    FROM DKA_FFI_TACHE t
    JOIN DKA_FFI_PROJET p ON t.PARENTPROJET = p.CODEPROJET
    JOIN DKA_FFI_CENTRE_FINANCE cf ON p.PARENTCENTREFINANCE = cf.CODECENTREFINANCE;
    
    DBMS_OUTPUT.PUT_LINE('Lignes source : ' || TO_CHAR(v_nb_source, '999,999,999'));
    
    -- VALIDATION
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('RÉSUMÉ');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Durée : ' || 
        EXTRACT(MINUTE FROM (v_end_time - v_start_time)) || ' min ' ||
        ROUND(EXTRACT(SECOND FROM (v_end_time - v_start_time))) || ' sec');
    DBMS_OUTPUT.PUT_LINE('Delta lignes : ' || TO_CHAR(v_nb_mv_apres - v_nb_mv_avant, 'S999,999'));
    
    IF v_nb_mv_apres = v_nb_source THEN
        DBMS_OUTPUT.PUT_LINE('✅ REFRESH RÉUSSI - Données synchronisées');
    ELSE
        DBMS_OUTPUT.PUT_LINE('⚠️ ÉCART DÉTECTÉ : ' || (v_nb_mv_apres - v_nb_source) || ' lignes');
        DBMS_OUTPUT.PUT_LINE('   (Normal si tâches orphelines)');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ ERREUR : ' || SQLERRM);
        RAISE;
END;
/
```

---

## 12. Création du Log Manquant (Recommandé)

```sql
-- =====================================================================
-- CORRECTION : Créer le MVIEW LOG manquant sur DKA_FFI_PROJET
-- Permettra le FAST REFRESH au lieu du COMPLETE
-- =====================================================================

CREATE MATERIALIZED VIEW LOG ON EAI_FRONTAL_FINANCE.DKA_FFI_PROJET
WITH ROWID, SEQUENCE (CODEPROJET, PARENTCENTREFINANCE, DATEDEBUT, DATEFIN)
INCLUDING NEW VALUES;

-- Vérification
SELECT master, log_table, rowids, sequence, include_new_values
FROM user_mview_logs
WHERE master = 'DKA_FFI_PROJET';
```

---

## 13. Job de Contrôle Automatique (Optionnel)

```sql
-- =====================================================================
-- JOB : Vérification quotidienne de l'état de la MV
-- =====================================================================

BEGIN
    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CHECK_MV_UODALKIA_TACHE',
        job_type        => 'PLSQL_BLOCK',
        job_action      => q'[
            DECLARE
                v_staleness VARCHAR2(30);
                v_ecart NUMBER;
            BEGIN
                SELECT staleness INTO v_staleness 
                FROM user_mviews WHERE mview_name = 'DKA_FFI_UODALKIA_TACHE';
                
                IF v_staleness IN ('UNUSABLE', 'STALE') THEN
                    -- Envoyer alerte ou logger
                    INSERT INTO DKA_FFI_LOG_ALERTES (
                        date_alerte, type_alerte, message
                    ) VALUES (
                        SYSDATE, 'MV_STALE', 
                        'DKA_FFI_UODALKIA_TACHE est ' || v_staleness
                    );
                    COMMIT;
                END IF;
            END;
        ]',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=7; BYMINUTE=0',
        enabled         => TRUE,
        comments        => 'Vérification quotidienne état MV UODALKIA_TACHE'
    );
END;
/
```

---

## 14. Tableau de Bord des Contrôles

```sql
-- =====================================================================
-- REQUÊTE TABLEAU DE BORD : État complet en une seule requête
-- =====================================================================

SELECT 'État MV' as categorie, staleness as valeur, 
       CASE staleness WHEN 'FRESH' THEN '✅' WHEN 'STALE' THEN '⚠️' ELSE '❌' END as statut
FROM user_mviews WHERE mview_name = 'DKA_FFI_UODALKIA_TACHE'
UNION ALL
SELECT 'Dernier refresh', TO_CHAR(last_refresh_date, 'DD/MM/YYYY HH24:MI'),
       CASE WHEN last_refresh_date > SYSDATE - 1 THEN '✅' 
            WHEN last_refresh_date > SYSDATE - 7 THEN '⚠️' 
            ELSE '❌' END
FROM user_mviews WHERE mview_name = 'DKA_FFI_UODALKIA_TACHE'
UNION ALL
SELECT 'Lignes MV', TO_CHAR(COUNT(*), '999,999,999'), '📊'
FROM DKA_FFI_UODALKIA_TACHE
UNION ALL
SELECT 'Log Tâches en attente', TO_CHAR(COUNT(*), '999,999'), 
       CASE WHEN COUNT(*) = 0 THEN '✅' WHEN COUNT(*) < 1000 THEN '⚠️' ELSE '❌' END
FROM MLOG$_DKA_FFI_TACHE
UNION ALL
SELECT 'Log CF en attente', TO_CHAR(COUNT(*), '999,999'),
       CASE WHEN COUNT(*) = 0 THEN '✅' WHEN COUNT(*) < 100 THEN '⚠️' ELSE '❌' END
FROM MLOG$_DKA_FFI_CENTRE_FINAN
UNION ALL
SELECT 'Tâches orphelines', TO_CHAR(COUNT(*), '999,999'),
       CASE WHEN COUNT(*) = 0 THEN '✅' WHEN COUNT(*) < 500 THEN '⚠️' ELSE '❌' END
FROM DKA_FFI_TACHE t
WHERE NOT EXISTS (SELECT 1 FROM DKA_FFI_PROJET p WHERE p.CODEPROJET = t.PARENTPROJET)
UNION ALL
SELECT 'Index', status, CASE status WHEN 'VALID' THEN '✅' ELSE '❌' END
FROM user_indexes WHERE table_name = 'DKA_FFI_UODALKIA_TACHE';
```

---

## 15. Points d'Attention

### ⚠️ Vue Matérialisée UNUSABLE

La vue matérialisée `DKA_FFI_UODALKIA_TACHE` a un statut **UNUSABLE** depuis le dernier refresh (30/12/2025). 

**Action recommandée** :
```sql
-- Rafraîchir la vue matérialisée
EXEC DBMS_MVIEW.REFRESH('EAI_FRONTAL_FINANCE.DKA_FFI_UODALKIA_TACHE', 'C');
```

### ⚠️ Log Manquant sur DKA_FFI_PROJET

Le MVIEW LOG n'existe pas sur la table `DKA_FFI_PROJET`, ce qui :
- Empêche le FAST REFRESH
- Force un COMPLETE REFRESH à chaque fois
- Augmente la durée et la charge

### ⚠️ Tâches Orphelines

**414 tâches** n'ont pas de projet parent → elles n'apparaîtront pas dans la MV.

### ⚠️ Gestion des Exceptions

- `TOO_MANY_ROWS` n'est **pas géré explicitement** : si plusieurs lignes correspondent aux critères (cas rare mais possible avec des données incohérentes), une erreur `FFI999` sera retournée avec le code ORA.

### ⚠️ Performance

- L'index `IDX_DKA_FFI_UODALKIA_TACHE_T` sur `CODETACHE` assure une recherche efficace
- La vue est en mode **CACHE** pour optimiser les lectures répétitives

---

## 10. Exemple d'Utilisation

```sql
DECLARE
    v_input  EAI_FRONTAL_FINANCE.GET_UO_DALKIA_IN;
    v_output EAI_FRONTAL_FINANCE.GET_UO_DALKIA_OUT;
BEGIN
    -- Initialisation des paramètres
    v_input := EAI_FRONTAL_FINANCE.GET_UO_DALKIA_IN(
        'GX1633262E',  -- Code tâche
        SYSDATE        -- Date de référence
    );
    
    -- Appel de la procédure
    EAI_FRONTAL_FINANCE.GET_UO_DALKIA_FROM_TACHE(v_input, v_output);
    
    -- Analyse du résultat
    DBMS_OUTPUT.PUT_LINE('UO Dalkia : ' || v_output.UO_dalkia);
    DBMS_OUTPUT.PUT_LINE('Code retour : ' || v_output.code_retour);
    
    IF v_output.code_retour != 'FFI000' THEN
        DBMS_OUTPUT.PUT_LINE('Erreur sur : ' || v_output.objet_erreur);
    END IF;
END;
/
```

---

## 11. Résumé

| Élément | Description |
|---------|-------------|
| **Fonction** | Récupérer l'UO Dalkia à partir d'un code tâche |
| **Source** | Vue matérialisée `DKA_FFI_UODALKIA_TACHE` (1.7M lignes) |
| **Hiérarchie** | Tâche → Projet → Centre Finance → UO Dalkia |
| **Validation** | Double contrôle de dates (projet + centre finance) |
| **Performance** | Index sur CODETACHE + Cache activé |
| **État actuel** | ⚠️ MV UNUSABLE - Refresh nécessaire |