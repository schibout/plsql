# Analyse des Chaînes Control-M – Programmes Concurrents Oracle EBS

## Date : 06/02/2026
## Auteur : GitHub Copilot
## Contexte : Oracle EBS 12.2.13 – Dalkia

---

## 1. Contexte

Control-M orchestre les traitements Oracle EBS en appelant des scripts shell qui utilisent l'utilitaire **`concsub`** pour soumettre des programmes concurrents.

### Convention de nommage Control-M

Le nom du job Control-M contient toujours le programme lancé :

```
FINFIN_J18TRT_04_IMP01_Q : DKA_IPAPROJETHRM_JOB.sh (DKA : Lanceur (SHELL))
```

| Élément | Description |
|---------|-------------|
| `FINFIN` | Domaine / Application |
| `J18TRT_04` | Identifiant de chaîne / séquence |
| `IMP01_Q` | Type de traitement (import, queue) |
| `DKA_IPAPROJETHRM_JOB.sh` | Script shell lancé |
| `DKA_IPAPROJETHRM` | **Nom court du programme concurrent** |
| `DKA : Lanceur (SHELL)` | Application / méthode d'exécution |

### Fonctionnement de `concsub`

```bash
concsub APPS/<pwd> <RESP_APP> <RESP_KEY> <SEC_GROUP> WAIT=Y \
  CONCURRENT <APP_SHORT_NAME> <PROGRAM_SHORT_NAME> [params...]
```

Le **`PROGRAM_SHORT_NAME`** correspond au champ `CONCURRENT_PROGRAM_NAME` dans `FND_CONCURRENT_PROGRAMS`.

---

## 2. Requêtes SQL

### 2.1 Recherche d'un programme concurrent par nom court (extrait du nom Control-M)

```sql
-- =====================================================================
-- Recherche d'un programme concurrent à partir du nom Control-M
-- =====================================================================
-- Utilisation : remplacer &NOM_PROGRAMME par le nom extrait du job
-- Control-M (ex: DKA_IPAPROJETHRM pour DKA_IPAPROJETHRM_JOB.sh)
-- =====================================================================
SELECT
    FCP.CONCURRENT_PROGRAM_NAME   AS NOM_COURT,
    FCP.USER_CONCURRENT_PROGRAM_NAME AS NOM_UTILISATEUR,
    FA.APPLICATION_SHORT_NAME     AS APPLICATION,
    FA.APPLICATION_NAME           AS NOM_APPLICATION,
    FCP.DESCRIPTION               AS DESCRIPTION,
    FE.EXECUTABLE_NAME            AS EXECUTABLE,
    FE.EXECUTION_FILE_NAME        AS FICHIER_EXECUTION,
    DECODE(FE.EXECUTION_METHOD_CODE,
        'P', 'PL/SQL Stored Procedure',
        'L', 'SQL*Loader',
        'Q', 'SQL*Plus',
        'H', 'Host (Shell Script)',
        'I', 'PL/SQL Stored Procedure (Immediate)',
        'A', 'Spawned',
        'J', 'Java Stored Procedure',
        'K', 'Java Concurrent Program',
        'M', 'Multi Language Function',
        'S', 'Immediate',
        'X', 'FlexRpt',
        'B', 'Request Set Stage Function',
        FE.EXECUTION_METHOD_CODE
    )                             AS METHODE_EXECUTION,
    FCP.ENABLED_FLAG              AS ACTIF
FROM
    APPLSYS.FND_CONCURRENT_PROGRAMS_VL FCP
    JOIN APPLSYS.FND_APPLICATION_VL FA
        ON FA.APPLICATION_ID = FCP.APPLICATION_ID
    LEFT JOIN APPLSYS.FND_EXECUTABLES FE
        ON FE.EXECUTABLE_ID = FCP.EXECUTABLE_ID
        AND FE.APPLICATION_ID = FCP.EXECUTABLE_APPLICATION_ID
WHERE
    UPPER(FCP.CONCURRENT_PROGRAM_NAME) LIKE UPPER('%&NOM_PROGRAMME%')
ORDER BY
    FCP.CONCURRENT_PROGRAM_NAME;
```

### 2.2 Historique d'exécution d'un programme (dernières exécutions)

```sql
-- =====================================================================
-- Historique des exécutions récentes d'un programme concurrent
-- =====================================================================
-- Permet de vérifier que le programme est bien lancé via Control-M
-- (les soumissions concsub apparaissent généralement avec REQUESTED_BY = SYSADMIN ou un user technique)
-- =====================================================================
SELECT
    FCR.REQUEST_ID,
    FCP.CONCURRENT_PROGRAM_NAME    AS NOM_COURT,
    FCP.USER_CONCURRENT_PROGRAM_NAME AS NOM_UTILISATEUR,
    FCR.REQUEST_DATE,
    FCR.ACTUAL_START_DATE          AS DEBUT,
    FCR.ACTUAL_COMPLETION_DATE     AS FIN,
    ROUND((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60, 2) AS DUREE_MIN,
    FCR.PHASE_CODE,
    FCR.STATUS_CODE,
    DECODE(FCR.PHASE_CODE,
        'C', 'Terminé',
        'R', 'En cours',
        'P', 'En attente',
        'I', 'Inactif',
        FCR.PHASE_CODE
    )                              AS PHASE,
    DECODE(FCR.STATUS_CODE,
        'C', 'Normal',
        'E', 'Erreur',
        'G', 'Avertissement',
        'W', 'En attente',
        'X', 'Terminé',
        'T', 'Arrêté',
        FCR.STATUS_CODE
    )                              AS STATUT,
    FU.USER_NAME                   AS SOUMIS_PAR,
    FCR.ARGUMENT_TEXT              AS PARAMETRES
FROM
    APPLSYS.FND_CONCURRENT_REQUESTS FCR
    JOIN APPLSYS.FND_CONCURRENT_PROGRAMS_VL FCP
        ON FCP.CONCURRENT_PROGRAM_ID = FCR.CONCURRENT_PROGRAM_ID
        AND FCP.APPLICATION_ID = FCR.PROGRAM_APPLICATION_ID
    JOIN APPLSYS.FND_USER FU
        ON FU.USER_ID = FCR.REQUESTED_BY
WHERE
    UPPER(FCP.CONCURRENT_PROGRAM_NAME) LIKE UPPER('%&NOM_PROGRAMME%')
    AND FCR.REQUEST_DATE >= SYSDATE - 30  -- 30 derniers jours
ORDER BY
    FCR.REQUEST_DATE DESC
FETCH FIRST 50 ROWS ONLY;
```

### 2.3 Liste de tous les programmes DKA (custom Dalkia) utilisés par Control-M

```sql
-- =====================================================================
-- Inventaire des programmes concurrents custom DKA
-- =====================================================================
-- Ces programmes sont typiquement ceux lancés par les chaînes Control-M
-- =====================================================================
SELECT
    FCP.CONCURRENT_PROGRAM_NAME    AS NOM_COURT,
    FCP.USER_CONCURRENT_PROGRAM_NAME AS NOM_UTILISATEUR,
    FA.APPLICATION_SHORT_NAME      AS APPLICATION,
    FE.EXECUTABLE_NAME             AS EXECUTABLE,
    FE.EXECUTION_FILE_NAME         AS FICHIER_EXECUTION,
    DECODE(FE.EXECUTION_METHOD_CODE,
        'P', 'PL/SQL',
        'H', 'Host/Shell',
        'L', 'SQL*Loader',
        'Q', 'SQL*Plus',
        'J', 'Java',
        FE.EXECUTION_METHOD_CODE
    )                              AS TYPE_EXECUTION,
    FCP.ENABLED_FLAG               AS ACTIF,
    (SELECT COUNT(*)
     FROM APPLSYS.FND_CONCURRENT_REQUESTS FCR2
     WHERE FCR2.CONCURRENT_PROGRAM_ID = FCP.CONCURRENT_PROGRAM_ID
       AND FCR2.PROGRAM_APPLICATION_ID = FCP.APPLICATION_ID
       AND FCR2.REQUEST_DATE >= SYSDATE - 30
    )                              AS NB_EXEC_30J
FROM
    APPLSYS.FND_CONCURRENT_PROGRAMS_VL FCP
    JOIN APPLSYS.FND_APPLICATION_VL FA
        ON FA.APPLICATION_ID = FCP.APPLICATION_ID
    LEFT JOIN APPLSYS.FND_EXECUTABLES FE
        ON FE.EXECUTABLE_ID = FCP.EXECUTABLE_ID
        AND FE.APPLICATION_ID = FCP.EXECUTABLE_APPLICATION_ID
WHERE
    (FA.APPLICATION_SHORT_NAME LIKE 'DKA%'
     OR FCP.CONCURRENT_PROGRAM_NAME LIKE 'DKA%')
    AND FCP.ENABLED_FLAG = 'Y'
ORDER BY
    FA.APPLICATION_SHORT_NAME,
    FCP.CONCURRENT_PROGRAM_NAME;
```

### 2.4 Programmes lancés par un utilisateur technique (soumissions Control-M)

```sql
-- =====================================================================
-- Identifier les programmes soumis par un utilisateur technique
-- (utilisateur utilisé par Control-M pour les appels concsub)
-- =====================================================================
SELECT
    FCP.CONCURRENT_PROGRAM_NAME    AS NOM_COURT,
    FCP.USER_CONCURRENT_PROGRAM_NAME AS NOM_UTILISATEUR,
    FA.APPLICATION_SHORT_NAME      AS APPLICATION,
    COUNT(*)                       AS NB_EXECUTIONS,
    MIN(FCR.REQUEST_DATE)          AS PREMIERE_EXEC,
    MAX(FCR.REQUEST_DATE)          AS DERNIERE_EXEC,
    ROUND(AVG((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) AS DUREE_MOY_MIN,
    ROUND(MAX((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) AS DUREE_MAX_MIN,
    SUM(CASE WHEN FCR.STATUS_CODE = 'E' THEN 1 ELSE 0 END) AS NB_ERREURS
FROM
    APPLSYS.FND_CONCURRENT_REQUESTS FCR
    JOIN APPLSYS.FND_CONCURRENT_PROGRAMS_VL FCP
        ON FCP.CONCURRENT_PROGRAM_ID = FCR.CONCURRENT_PROGRAM_ID
        AND FCP.APPLICATION_ID = FCR.PROGRAM_APPLICATION_ID
    JOIN APPLSYS.FND_APPLICATION_VL FA
        ON FA.APPLICATION_ID = FCP.APPLICATION_ID
    JOIN APPLSYS.FND_USER FU
        ON FU.USER_ID = FCR.REQUESTED_BY
WHERE
    FU.USER_NAME = '&USER_CONTROLM'   -- Ex: SYSADMIN, BATCH, CTRLM...
    AND FCR.REQUEST_DATE >= SYSDATE - 30
GROUP BY
    FCP.CONCURRENT_PROGRAM_NAME,
    FCP.USER_CONCURRENT_PROGRAM_NAME,
    FA.APPLICATION_SHORT_NAME
ORDER BY
    NB_EXECUTIONS DESC;
```

### 2.5 Recherche par nom du script shell (fichier d'exécution)

```sql
-- =====================================================================
-- Recherche d'un programme par le nom du script shell
-- =====================================================================
-- Utile quand on connaît le nom du .sh depuis Control-M
-- Ex: DKA_IPAPROJETHRM_JOB.sh → chercher IPAPROJETHRM
-- =====================================================================
SELECT
    FCP.CONCURRENT_PROGRAM_NAME    AS NOM_COURT_PROGRAMME,
    FCP.USER_CONCURRENT_PROGRAM_NAME AS NOM_UTILISATEUR,
    FA.APPLICATION_SHORT_NAME      AS APPLICATION,
    FE.EXECUTABLE_NAME             AS NOM_EXECUTABLE,
    FE.EXECUTION_FILE_NAME         AS FICHIER_SCRIPT,
    FE.EXECUTION_METHOD_CODE       AS METHODE,
    FCP.ENABLED_FLAG               AS ACTIF
FROM
    APPLSYS.FND_EXECUTABLES FE
    JOIN APPLSYS.FND_CONCURRENT_PROGRAMS_VL FCP
        ON FCP.EXECUTABLE_ID = FE.EXECUTABLE_ID
        AND FCP.EXECUTABLE_APPLICATION_ID = FE.APPLICATION_ID
    JOIN APPLSYS.FND_APPLICATION_VL FA
        ON FA.APPLICATION_ID = FCP.APPLICATION_ID
WHERE
    UPPER(FE.EXECUTION_FILE_NAME) LIKE UPPER('%&NOM_SCRIPT%')
ORDER BY
    FE.EXECUTION_FILE_NAME;
```

---

## 3. Guide d'utilisation

### Extraire le nom du programme depuis le nom du job Control-M

| Nom du Job Control-M | Script Shell | Programme Concurrent |
|---|---|---|
| `FINFIN_J18TRT_04_IMP01_Q : DKA_IPAPROJETHRM_JOB.sh` | `DKA_IPAPROJETHRM_JOB.sh` | `DKA_IPAPROJETHRM` |

**Règle générale** : retirer le suffixe `_JOB.sh` du nom de script pour obtenir le `CONCURRENT_PROGRAM_NAME`.

### Workflow de diagnostic

1. **Identifier le programme** : Requête 2.1 avec le nom extrait du job Control-M
2. **Vérifier les exécutions** : Requête 2.2 pour confirmer l'activité récente
3. **Analyser les performances** : Requête 2.4 pour les statistiques de durée
4. **Recherche par script** : Requête 2.5 si le nom du programme ne correspond pas directement

---

## 4. Voir aussi

- [Rapport_Traitements_Nuit_Oracle_EBS.md](../Rapport_Traitements_Nuit_Oracle_EBS.md) – Analyse des traitements batch nocturnes
- [Rapport_Traitements_Fournisseurs_Oracle_EBS.md](../Rapport_Traitements_Fournisseurs_Oracle_EBS.md) – Traitements fournisseurs
- [Definition_programme_maj_sites_fournisseurs.sql](../sql/) – Exemple de requête de définition de programme
