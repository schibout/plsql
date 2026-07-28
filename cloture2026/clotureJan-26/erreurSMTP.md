# Analyse des traitements - Clôture Janvier 2026

## 1. Erreur Export Factures iValua (01/02/2026)

### Traitement en erreur

| Élément | Valeur |
|---------|--------|
| **Request ID** | 46957735 |
| **Programme** | `DKA_IAPFAC_IVALUA` - "DKA : Export des données Factures vers iValua" |
| **Date/Heure** | 01/02/2026 10:46:34 → 11:09:43 |
| **Statut** | Error |
| **Factures traitées** | 11 141 en-têtes |

### Cause de l'erreur

Le script shell `DKA_SLAUNCHER_CONCAT` (Request 46957742) a échoué avec **"Programme sortie avec statut 2"**.

**Message d'erreur :**
```
find: 'DSP01_INV_*_20260201104634*.csv': No such file or directory
```

**Problème identifié :** Les guillemets typographiques UTF-8 (`'` et `'`) dans le script shell sont mal interprétés en ISO-8859-1, causant l'échec de la commande `find`.

### Emplacements

- **Script shell** : `/u01/application/V12/fs2/EBSapps/appl/dka/12.0.0/bin/DKA_SLAUNCHER_CONCAT`
- **Répertoire fichiers** : `/data/flf/files/PDBFINP1/data/out`
- **Log erreur** : `/data/flf/files/PDBFINP1/logs/appl/conc/log/l46957742.req`

### Solution

Corriger le script shell en remplaçant les guillemets typographiques par des apostrophes ASCII standard (`'`).

---

## 2. Traitements DTR (31/01/2026 18:47)

### Requête de recherche des traitements DTR

```sql
-- Recherche des traitements DTR terminés autour de 18:47:15 le 31/01/2026
SELECT FCR.REQUEST_ID,
       FCP.CONCURRENT_PROGRAM_NAME AS CODE_PROGRAMME,
       FCP.USER_CONCURRENT_PROGRAM_NAME AS NOM_PROGRAMME,
       FL.MEANING AS STATUT,
       TO_CHAR(FCR.ACTUAL_START_DATE, 'DD/MM/YYYY HH24:MI:SS') AS DEBUT,
       TO_CHAR(FCR.ACTUAL_COMPLETION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS FIN
FROM APPS.FND_CONCURRENT_REQUESTS FCR
JOIN APPS.FND_CONCURRENT_PROGRAMS_VL FCP 
    ON FCR.CONCURRENT_PROGRAM_ID = FCP.CONCURRENT_PROGRAM_ID
    AND FCR.PROGRAM_APPLICATION_ID = FCP.APPLICATION_ID
JOIN APPS.FND_LOOKUPS FL 
    ON FL.LOOKUP_TYPE = 'CP_STATUS_CODE' 
    AND FL.LOOKUP_CODE = FCR.STATUS_CODE
WHERE FCR.ACTUAL_START_DATE BETWEEN TO_DATE('31/01/2026 18:46:00', 'DD/MM/YYYY HH24:MI:SS') 
                                AND TO_DATE('31/01/2026 18:48:00', 'DD/MM/YYYY HH24:MI:SS')
AND (FCP.CONCURRENT_PROGRAM_NAME LIKE '%DTR%' 
     OR FCP.CONCURRENT_PROGRAM_NAME LIKE 'DKA_IAR%'
     OR FCP.CONCURRENT_PROGRAM_NAME LIKE 'DKA_ICE%')
ORDER BY FCR.ACTUAL_START_DATE;
```

### Résultats

| Request ID | Programme | Nom | Début | Fin |
|------------|-----------|-----|-------|-----|
| 46950804 | `DKA_IAR_EVENEMENTS_DTR` | DKA : Extraction des évènements AR | 31/01/2026 18:46:57 | 31/01/2026 18:47:00 |
| 46950807 | `DKA_ICE_BANKBRANCHES_DTR` | DKA : Extraction des coordonnées bancaires | 31/01/2026 18:46:57 | 31/01/2026 18:47:08 |

### Lanceurs shell associés (terminés à 18:47:15)

| Request ID | Script Shell | Fin |
|------------|--------------|-----|
| 46950793 | `DKA_IAR_EVENEMENTS_DTR_JOB.sh` | 31/01/2026 18:47:15 |
| 46950796 | `DKA_ICE_BANKBRANCHES_DTR_JOB.sh` | 31/01/2026 18:47:15 |

### Requête pour les lanceurs shell

```sql
-- Recherche des lanceurs shell terminés à 18:47:15
SELECT FCR.REQUEST_ID,
       FCR.PARENT_REQUEST_ID,
       FCP.CONCURRENT_PROGRAM_NAME AS CODE_PROGRAMME,
       FCP.USER_CONCURRENT_PROGRAM_NAME AS NOM_PROGRAMME,
       FL.MEANING AS STATUT,
       TO_CHAR(FCR.ACTUAL_START_DATE, 'DD/MM/YYYY HH24:MI:SS') AS DEBUT,
       TO_CHAR(FCR.ACTUAL_COMPLETION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS FIN,
       FCR.ARGUMENT1 AS SCRIPT_SHELL
FROM APPS.FND_CONCURRENT_REQUESTS FCR
JOIN APPS.FND_CONCURRENT_PROGRAMS_VL FCP 
    ON FCR.CONCURRENT_PROGRAM_ID = FCP.CONCURRENT_PROGRAM_ID
    AND FCR.PROGRAM_APPLICATION_ID = FCP.APPLICATION_ID
JOIN APPS.FND_LOOKUPS FL 
    ON FL.LOOKUP_TYPE = 'CP_STATUS_CODE' 
    AND FL.LOOKUP_CODE = FCR.STATUS_CODE
WHERE FCR.ACTUAL_COMPLETION_DATE BETWEEN TO_DATE('31/01/2026 18:47:10', 'DD/MM/YYYY HH24:MI:SS') 
                                      AND TO_DATE('31/01/2026 18:47:20', 'DD/MM/YYYY HH24:MI:SS')
ORDER BY FCR.ACTUAL_COMPLETION_DATE;
```

---

## 3. Requêtes utiles

### Liste des programmes DTR disponibles

```sql
SELECT FCP.CONCURRENT_PROGRAM_NAME AS CODE_PROGRAMME,
       FCP.USER_CONCURRENT_PROGRAM_NAME AS NOM_PROGRAMME
FROM APPS.FND_CONCURRENT_PROGRAMS_VL FCP
WHERE UPPER(FCP.CONCURRENT_PROGRAM_NAME) LIKE '%DTR%'
AND FCP.ENABLED_FLAG = 'Y'
ORDER BY FCP.CONCURRENT_PROGRAM_NAME;
```

### Recherche d'un traitement par date de fin exacte

```sql
SELECT FCR.REQUEST_ID,
       FCP.CONCURRENT_PROGRAM_NAME AS CODE_PROGRAMME,
       FCP.USER_CONCURRENT_PROGRAM_NAME AS NOM_PROGRAMME,
       FL.MEANING AS STATUT,
       TO_CHAR(FCR.ACTUAL_START_DATE, 'DD/MM/YYYY HH24:MI:SS') AS DEBUT,
       TO_CHAR(FCR.ACTUAL_COMPLETION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS FIN
FROM APPS.FND_CONCURRENT_REQUESTS FCR
JOIN APPS.FND_CONCURRENT_PROGRAMS_VL FCP 
    ON FCR.CONCURRENT_PROGRAM_ID = FCP.CONCURRENT_PROGRAM_ID
    AND FCR.PROGRAM_APPLICATION_ID = FCP.APPLICATION_ID
JOIN APPS.FND_LOOKUPS FL 
    ON FL.LOOKUP_TYPE = 'CP_STATUS_CODE' 
    AND FL.LOOKUP_CODE = FCR.STATUS_CODE
WHERE FCR.ACTUAL_COMPLETION_DATE = TO_DATE('31/01/2026 18:47:15', 'DD/MM/YYYY HH24:MI:SS')
ORDER BY FCR.REQUEST_ID;
```
