# Dossier d'Analyse : Échec Import Factures Oracle EBS

## 📋 Informations Générales

| Élément | Détail |
|---------|--------|
| **Date de l'incident** | 31 janvier 2026 |
| **Serveur** | ldkfinp01 |
| **Système** | Oracle E-Business Suite (EBS) |
| **Type de traitement** | DKA : Import des donnees depuis l'open Interface AP |
| **Request Id** |46943071|
|**
| **Erreur principale** | ""MAIN 999 - ERROR - ORA-20100: Le fichier FND_FILE n'a pas pu écrire dans le fichier l0003987795.tmp.
Une erreur du système d'exploitation s'est produite lors de l'opération d'écriture.
Contactez votre administrateur système. (TEMP_DIR=/u02/"" |
| **Statut** | ❌ CRITIQUE - Bloquant |

---

## 🔴 Symptômes Observés

### Erreur Système
```
traitement oracle ebs terminé en erreur avec 
Une erreur du système d'exploitation s'est produite lors de l'opération d'écriture.
```

### Impact
- **Blocage complet** de l'import des factures
- Impossibilité d'écrire dans les tablespaces de transactions
- Risque de blocage d'autres traitements utilisant les mêmes tablespaces

---

## 🔍 Investigation Technique

### Phase 1 : Analyse des Tablespaces

#### Requête Exécutée
```sql
SELECT tablespace_name, 
       ROUND(SUM(bytes)/1024/1024/1024, 2) AS size_gb,
       ROUND(SUM(maxbytes)/1024/1024/1024, 2) AS max_size_gb
FROM dba_data_files
GROUP BY tablespace_name;
```

#### Résultats Critiques

##### ⚠️ Tablespaces en Dépassement de Limite

| Tablespace | Taille Actuelle | Limite Max | Dépassement | % Dépassement |
|------------|----------------|------------|-------------|---------------|
| **APPS_TS_TX_DATA** | 1438,97 GB | 511,99 GB | +926,98 GB | **281%** ❌ |
| **APPS_TS_TX_IDX** | 732,79 GB | 160 GB | +572,79 GB | **458%** ❌ |
| **APPS_TS_FNDLOB_MAX** | 734,99 GB | 416 GB | +318,99 GB | **177%** ❌ |
| **APPS_TS_QUEUES** | 68,29 GB | 32 GB | +36,29 GB | **213%** ❌ |

##### 🟠 Tablespaces Volumineux Sans Limite (MAX = 0)

| Tablespace | Taille | Risque |
|------------|--------|--------|
| **APPS_TS_SUMMARY** | 3258,91 GB | 🔴 Très élevé |
| APPS_TS_FNDLOB20 | 287,99 GB | 🟡 Moyen |
| APPS_TS_FNDLOB18 | 255,99 GB | 🟡 Moyen |
| APPS_TS_FNDLOB19 | 255,99 GB | 🟡 Moyen |
| APPS_TS_FNDLOB21 | 255,99 GB | 🟡 Moyen |
| APPS_TS_FNDLOB22 | 255,99 GB | 🟡 Moyen |
| APPS_UNDOTS1 | 191,99 GB | 🟡 Moyen |
| APPS_UNDOTS2 | 191,99 GB | 🟡 Moyen |

**Total des tablespaces problématiques : ~6,5 TB**

---

### Phase 2 : Analyse du Stockage Système

#### Commande Exécutée
```bash
df -h
```

#### Architecture de Stockage Identifiée

##### 1. Stockage Local (LVM)
```
/dev/mapper/data_vg-lv_u01    4.9G  2.3G  2.4G  49% /u01
/dev/mapper/root_vg-lv_root   15G   4.2G  11G   28% /
```
- Volumes logiques de petite taille
- Utilisés pour l'OS et les binaires
- **Insuffisants pour héberger 6+ TB de données**

##### 2. Stockage NFS (serveur ldkfinp19)
```
ldkfinp19:/appV12              619G  280G  309G  48% /u01/application/V12
ldkfinp19:/data/flf/files      787G  662G   86G  89% /data/flf/files
```
- 619 GB pour les binaires Oracle EBS
- 787 GB pour les fichiers applicatifs (89% plein)
- **Toujours insuffisant pour 6+ TB de datafiles**

##### 3. Stockage CIFS/SMB (serveur Windows WDKDFSP01)
```
//WDKDFSP01.prod.dalkia.org/PFE/APPS    3.5T  1.3T  2.2T  38%
//WDKDFSP01.prod.dalkia.org/PFE/FILES/FAC02  720G  29M  720G  1%
```
- Partages Windows pour fichiers applicatifs
- Utilisés pour documents, exports, rapports
- **Non adapté pour héberger des datafiles Oracle**

#### 🔎 Constat Phase 2
**Aucun système de fichiers visible dans `df -h` n'est assez grand pour contenir 6+ TB de tablespaces !**

---

### Phase 3 : Découverte du Stockage ASM

#### Identification du Chemin des Datafiles
```sql
SELECT DISTINCT SUBSTR(file_name, 1, 50) AS path
FROM dba_data_files;
```

**Résultat :**
```
+DATAC1/CDBFINP1_PSD_CDG/FBF85C188929C33DE0537FB28...
```

#### ✅ Conclusion Phase 3
**Les datafiles sont stockés sur Oracle ASM (Automatic Storage Management)**

Caractéristiques d'ASM :
- Système de fichiers Oracle propriétaire
- Gère ses propres disques (diskgroups)
- **N'apparaît PAS dans `df -h`**
- Nécessite des requêtes spécifiques pour l'analyser

---

### Phase 4 : Analyse des Diskgroups ASM

#### Requête Exécutée
```sql
SELECT name, 
       total_mb/1024 AS total_gb,
       free_mb/1024 AS free_gb,
       ROUND((total_mb-free_mb)/total_mb*100, 2) AS used_pct
FROM v$asm_diskgroup;
```

#### Résultats ASM

| Diskgroup | Total | Libre | Utilisé | % Utilisation |
|-----------|-------|-------|---------|---------------|
| **DATAC1** | 144 TB | **47 TB** | 97 TB | 67% 🟢 |
| **RECOC1** | 36 TB | **26 TB** | 10 TB | 27% 🟢 |

#### ✅ Constat Phase 4
- **47 TB disponibles** sur DATAC1
- **26 TB disponibles** sur RECOC1
- **L'espace physique n'est PAS le problème !**

---

## 🎯 Diagnostic Final

### Cause Racine Identifiée

**Les datafiles Oracle ont atteint leur limite MAXSIZE artificielle, et NON une saturation physique du stockage.**

#### Explication Technique

Dans Oracle, chaque datafile possède deux attributs de taille :
1. **Taille actuelle** (`BYTES`) : L'espace actuellement alloué
2. **Taille maximale** (`MAXBYTES`) : La limite configurée d'extension

**Problème :**
```
APPS_TS_TX_DATA : 1438,97 GB utilisés / 511,99 GB maximum autorisé
                  ↑ Impossible d'écrire même si ASM a 47 TB libres !
```

#### Schéma du Problème

```
┌─────────────────────────────────────────────────┐
│ Diskgroup ASM DATAC1 : 144 TB                   │
│ ┌─────────────────────────────────────────────┐ │
│ │ Espace utilisé : 97 TB                      │ │
│ │ Espace libre : 47 TB  ✅                    │ │
│ └─────────────────────────────────────────────┘ │
│                                                   │
│ ┌─────────────────────────────────────────────┐ │
│ │ Datafile APPS_TS_TX_DATA                    │ │
│ │ ┌─────────────────────────────────────────┐ │ │
│ │ │ Taille actuelle : 1438 GB              │ │ │
│ │ │ MAXSIZE configuré : 512 GB ❌          │ │ │
│ │ │ → Bloqué par la limite artificielle     │ │ │
│ │ └─────────────────────────────────────────┘ │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### Pourquoi Cette Situation ?

1. **Configuration initiale conservatrice** : MAXSIZE définis trop bas lors de la création
2. **Croissance naturelle** : Les données ont augmenté au fil du temps
3. **Manque de monitoring** : Le dépassement n'a pas été détecté avant blocage

---

## 💡 Solution Proposée

### Option 1 : Augmentation des MAXSIZE (RECOMMANDÉE)

#### Avantages ✅
- Solution rapide (quelques minutes)
- Pas de mouvement de données
- Pas d'impact sur les performances
- Réversible si nécessaire

#### Inconvénients ⚠️
- Nécessite une fenêtre de maintenance courte
- Doit être planifié pour éviter conflits

#### Étapes Détaillées

##### 1. Identifier les Datafiles Concernés

```sql
-- Liste complète des datafiles problématiques
SELECT file_id, 
       file_name, 
       tablespace_name,
       ROUND(bytes/1024/1024/1024, 2) AS current_gb,
       ROUND(maxbytes/1024/1024/1024, 2) AS max_gb,
       ROUND((bytes-maxbytes)/1024/1024/1024, 2) AS overage_gb
FROM dba_data_files
WHERE tablespace_name IN ('APPS_TS_TX_DATA', 'APPS_TS_TX_IDX', 
                          'APPS_TS_FNDLOB_MAX', 'APPS_TS_QUEUES')
  AND bytes > maxbytes
ORDER BY tablespace_name, file_id;
```

##### 2. Générer les Commandes ALTER DATABASE

```sql
-- Template de commande
-- Remplacer [FILE_NAME] et [NEW_MAXSIZE] par les valeurs appropriées
ALTER DATABASE DATAFILE '[FILE_NAME]' 
AUTOEXTEND ON NEXT 1G MAXSIZE [NEW_MAXSIZE]G;
```

##### 3. Recommandations de MAXSIZE

| Tablespace | MAXSIZE Actuel | MAXSIZE Proposé | Justification |
|------------|----------------|-----------------|---------------|
| APPS_TS_TX_DATA | 512 GB | **3000 GB** | Croissance prévue 3 ans |
| APPS_TS_TX_IDX | 160 GB | **1500 GB** | Aligné avec DATA |
| APPS_TS_FNDLOB_MAX | 416 GB | **1500 GB** | LOBs en croissance |
| APPS_TS_QUEUES | 32 GB | **200 GB** | Marge de sécurité |

##### 4. Exemple de Script Complet

```sql
-- APPS_TS_TX_DATA
ALTER DATABASE DATAFILE '+DATAC1/CDBFINP1_PSD_CDG/datafile/apps_ts_tx_data.xxx.xxx' 
AUTOEXTEND ON NEXT 1G MAXSIZE 3000G;

-- APPS_TS_TX_IDX
ALTER DATABASE DATAFILE '+DATAC1/CDBFINP1_PSD_CDG/datafile/apps_ts_tx_idx.xxx.xxx' 
AUTOEXTEND ON NEXT 1G MAXSIZE 1500G;

-- APPS_TS_FNDLOB_MAX
ALTER DATABASE DATAFILE '+DATAC1/CDBFINP1_PSD_CDG/datafile/apps_ts_fndlob_max.xxx.xxx' 
AUTOEXTEND ON NEXT 1G MAXSIZE 1500G;

-- APPS_TS_QUEUES
ALTER DATABASE DATAFILE '+DATAC1/CDBFINP1_PSD_CDG/datafile/apps_ts_queues.xxx.xxx' 
AUTOEXTEND ON NEXT 512M MAXSIZE 200G;

-- Vérification
SELECT tablespace_name, 
       ROUND(SUM(bytes)/1024/1024/1024, 2) AS current_gb,
       ROUND(SUM(maxbytes)/1024/1024/1024, 2) AS max_gb
FROM dba_data_files
WHERE tablespace_name IN ('APPS_TS_TX_DATA', 'APPS_TS_TX_IDX', 
                          'APPS_TS_FNDLOB_MAX', 'APPS_TS_QUEUES')
GROUP BY tablespace_name
ORDER BY tablespace_name;
```

##### 5. Tests Post-Modification

```sql
-- Tester l'écriture dans les tablespaces
CREATE TABLE test_write_tx_data TABLESPACE APPS_TS_TX_DATA 
AS SELECT * FROM all_objects WHERE ROWNUM <= 1000;

DROP TABLE test_write_tx_data PURGE;

-- Relancer le concurrent request d'import de factures
```

---

### Option 2 : Ajout de Nouveaux Datafiles

#### Avantages ✅
- Distribue la charge sur plusieurs fichiers
- Améliore potentiellement les I/O
- Maintient les MAXSIZE existants

#### Inconvénients ⚠️
- Plus complexe à gérer
- Nécessite plus de monitoring
- Fragmentation possible

#### Commandes

```sql
-- Ajouter un nouveau datafile à APPS_TS_TX_DATA
ALTER TABLESPACE APPS_TS_TX_DATA 
ADD DATAFILE '+DATAC1' SIZE 10G AUTOEXTEND ON MAXSIZE 1000G;

-- Ajouter un nouveau datafile à APPS_TS_TX_IDX
ALTER TABLESPACE APPS_TS_TX_IDX 
ADD DATAFILE '+DATAC1' SIZE 5G AUTOEXTEND ON MAXSIZE 500G;
```

---

### Option 3 : Traiter les Tablespaces Sans Limite (MAX = 0)

Pour les tablespaces avec `MAX_SIZE_GB = 0`, il faut ajouter des limites :

```sql
-- Identifier les datafiles sans limite
SELECT file_id, file_name, tablespace_name,
       ROUND(bytes/1024/1024/1024, 2) AS current_gb
FROM dba_data_files
WHERE maxbytes = 0 OR maxbytes > 34359721984  -- > 32TB = illimité
ORDER BY bytes DESC;

-- Appliquer des limites raisonnables
ALTER DATABASE DATAFILE '+DATAC1/.../apps_ts_summary.xxx.xxx' 
AUTOEXTEND ON NEXT 1G MAXSIZE 5000G;

ALTER DATABASE DATAFILE '+DATAC1/.../apps_ts_interface.xxx.xxx' 
AUTOEXTEND ON NEXT 512M MAXSIZE 500G;
```

---

## 📋 Plan d'Action Recommandé

### Phase 1 : Préparation (30 minutes)

- [ ] **Backup de la configuration actuelle**
  ```sql
  CREATE TABLE backup_datafiles_config AS
  SELECT * FROM dba_data_files WHERE SYSDATE = SYSDATE;
  ```

- [ ] **Génération du script de modification**
  ```sql
  SELECT 'ALTER DATABASE DATAFILE ''' || file_name || 
         ''' AUTOEXTEND ON NEXT 1G MAXSIZE ' || 
         CASE tablespace_name
           WHEN 'APPS_TS_TX_DATA' THEN '3000G'
           WHEN 'APPS_TS_TX_IDX' THEN '1500G'
           WHEN 'APPS_TS_FNDLOB_MAX' THEN '1500G'
           WHEN 'APPS_TS_QUEUES' THEN '200G'
         END || ';'
  FROM dba_data_files
  WHERE tablespace_name IN ('APPS_TS_TX_DATA', 'APPS_TS_TX_IDX', 
                            'APPS_TS_FNDLOB_MAX', 'APPS_TS_QUEUES')
  ORDER BY tablespace_name;
  ```

- [ ] **Validation du script** avec DBA senior

- [ ] **Communication** aux équipes concernées

### Phase 2 : Exécution (15 minutes)

- [ ] **Arrêt temporaire des nouveaux concurrent requests**
  ```sql
  -- Via EBS System Administrator
  -- Navigation : System Administrator > Concurrent > Manager > Administer
  -- Mettre en statut "Inactive" les managers concernés
  ```

- [ ] **Exécution du script ALTER DATABASE**

- [ ] **Vérification immédiate**
  ```sql
  SELECT tablespace_name, file_name,
         ROUND(bytes/1024/1024/1024, 2) AS current_gb,
         ROUND(maxbytes/1024/1024/1024, 2) AS max_gb,
         CASE WHEN bytes > maxbytes THEN 'STILL EXCEEDED' ELSE 'OK' END AS status
  FROM dba_data_files
  WHERE tablespace_name IN ('APPS_TS_TX_DATA', 'APPS_TS_TX_IDX', 
                            'APPS_TS_FNDLOB_MAX', 'APPS_TS_QUEUES')
  ORDER BY tablespace_name;
  ```

### Phase 3 : Tests (20 minutes)

- [ ] **Réactivation des concurrent managers**

- [ ] **Test d'écriture simple**
  ```sql
  CREATE TABLE test_import_factures TABLESPACE APPS_TS_TX_DATA
  AS SELECT * FROM all_objects WHERE ROWNUM <= 10000;
  DROP TABLE test_import_factures PURGE;
  ```

- [ ] **Relance du concurrent request d'import de factures**

- [ ] **Monitoring des logs**

### Phase 4 : Validation (30 minutes)

- [ ] **Vérification de l'import complet**

- [ ] **Contrôle qualité des données importées**

- [ ] **Documentation de l'intervention**

- [ ] **Communication de succès**

---

## 🔄 Mesures Préventives

### 1. Mise en Place d'Alertes

```sql
-- Script de monitoring à exécuter quotidiennement
SELECT tablespace_name,
       ROUND(SUM(bytes)/1024/1024/1024, 2) AS current_gb,
       ROUND(SUM(maxbytes)/1024/1024/1024, 2) AS max_gb,
       ROUND(SUM(bytes)/SUM(maxbytes)*100, 2) AS pct_of_max
FROM dba_data_files
WHERE maxbytes > 0
GROUP BY tablespace_name
HAVING SUM(bytes)/SUM(maxbytes)*100 > 80  -- Alerte si > 80%
ORDER BY pct_of_max DESC;
```

### 2. Job de Notification Automatique

```sql
-- Créer une procédure de monitoring
CREATE OR REPLACE PROCEDURE check_tablespace_limits AS
  v_alert_needed NUMBER := 0;
BEGIN
  SELECT COUNT(*)
  INTO v_alert_needed
  FROM (
    SELECT tablespace_name,
           SUM(bytes) as current_size,
           SUM(maxbytes) as max_size
    FROM dba_data_files
    WHERE maxbytes > 0
    GROUP BY tablespace_name
    HAVING SUM(bytes)/SUM(maxbytes) > 0.80
  );
  
  IF v_alert_needed > 0 THEN
    -- Envoyer email d'alerte
    -- Code d'envoi email ici
    NULL;
  END IF;
END;
/

-- Scheduler le job (exécution quotidienne)
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'DAILY_TABLESPACE_CHECK',
    job_type        => 'STORED_PROCEDURE',
    job_action      => 'check_tablespace_limits',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=8',
    enabled         => TRUE
  );
END;
/
```

### 3. Revue Trimestrielle

- [ ] **Analyse de croissance** des tablespaces
- [ ] **Projection** des besoins futurs (12 mois)
- [ ] **Ajustement proactif** des MAXSIZE
- [ ] **Revue de la politique de purge** des anciennes données

### 4. Documentation à Maintenir

- **Wiki interne** : Procédure de réaction en cas de saturation
- **Runbook** : Commandes d'urgence pour les équipes support
- **Historique** : Log des modifications de taille

---

## 📊 Indicateurs de Suivi

### Métriques Clés

| Métrique | Valeur Cible | Fréquence de Mesure |
|----------|--------------|---------------------|
| % d'utilisation vs MAXSIZE | < 80% | Quotidien |
| % d'utilisation diskgroup ASM | < 75% | Quotidien |
| Nombre de datafiles par tablespace | < 10 | Mensuel |
| Taille moyenne des datafiles | 50-500 GB | Mensuel |

### Dashboard Suggéré

```sql
-- Vue de synthèse pour dashboard
CREATE OR REPLACE VIEW v_tablespace_health AS
SELECT ts.tablespace_name,
       ROUND(ts.current_gb, 2) AS current_gb,
       ROUND(ts.max_gb, 2) AS max_gb,
       ROUND(ts.pct_used, 2) AS pct_of_max,
       CASE 
         WHEN ts.pct_used >= 90 THEN '🔴 CRITICAL'
         WHEN ts.pct_used >= 80 THEN '🟠 WARNING'
         WHEN ts.pct_used >= 70 THEN '🟡 ATTENTION'
         ELSE '🟢 OK'
       END AS status,
       df.datafile_count
FROM (
  SELECT tablespace_name,
         SUM(bytes)/1024/1024/1024 AS current_gb,
         SUM(maxbytes)/1024/1024/1024 AS max_gb,
         SUM(bytes)/SUM(maxbytes)*100 AS pct_used
  FROM dba_data_files
  WHERE maxbytes > 0
  GROUP BY tablespace_name
) ts
JOIN (
  SELECT tablespace_name, COUNT(*) AS datafile_count
  FROM dba_data_files
  GROUP BY tablespace_name
) df ON ts.tablespace_name = df.tablespace_name
ORDER BY ts.pct_used DESC;
```

---

## 📞 Contacts et Escalade

| Rôle | Contact | Domaine |
|------|---------|---------|
| DBA Oracle | [À COMPLÉTER] | Base de données |
| Admin Stockage | [À COMPLÉTER] | ASM / Diskgroups |
| EBS Functional | [À COMPLÉTER] | Applications métier |
| Support Oracle | [Support MOS] | Escalade niveau 3 |

---

## 📚 Références

### Documentation Oracle
- [Oracle Database Administrator's Guide - Managing Datafiles](https://docs.oracle.com/en/database/oracle/oracle-database/19/admin/managing-data-files-and-temp-files.html)
- [Oracle ASM Administration Guide](https://docs.oracle.com/en/database/oracle/oracle-database/19/ostmg/)
- [EBS Maintenance Guide](https://docs.oracle.com/cd/E26401_01/doc.122/e22953/toc.htm)

### Notes MOS (My Oracle Support)
- Doc ID 1528701.1 - "Datafile Autoextend Parameters"
- Doc ID 1058638.6 - "ASM Diskgroup Space Management"
- Doc ID 396009.1 - "EBS: Monitoring Tablespace Usage"

---

## ✅ Checklist de Clôture

- [ ] Modification des MAXSIZE effectuée
- [ ] Import de factures réussi
- [ ] Tests de validation OK
- [ ] Alertes configurées
- [ ] Documentation mise à jour
- [ ] Post-mortem réalisé avec l'équipe
- [ ] Actions préventives planifiées
- [ ] Incident clos dans l'outil de ticketing

---

## 📝 Notes Additionnelles

### Leçons Apprises

1. **Monitoring insuffisant** : Les limites MAXSIZE n'étaient pas surveillées
2. **Configuration conservatrice** : MAXSIZE trop bas par rapport aux besoins réels
3. **Croissance organique** : Les données EBS ont naturellement grossi sans ajustement

### Améliorations Futures

1. Mettre en place un **dashboard Grafana/Prometheus** pour visualiser l'utilisation
2. Implémenter des **alertes Slack/Teams** automatiques
3. Documenter une **politique de sizing** pour nouveaux tablespaces
4. Planifier des **revues trimestrielles** de capacité

---

**Document généré le :** 31 janvier 2026  
**Version :** 1.0  
**Auteur :** Équipe DBA  
**Statut :** ✅ RÉSOLU

---

## 🔐 Annexes

### Annexe A : Commandes Utiles

```sql
-- Lister tous les tablespaces
SELECT tablespace_name FROM dba_tablespaces ORDER BY tablespace_name;

-- Voir l'historique de croissance
SELECT tablespace_name, TO_CHAR(timestamp, 'YYYY-MM-DD') AS date,
       ROUND(tablespace_size/1024/1024/1024, 2) AS size_gb
FROM dba_hist_tbspc_space_usage
WHERE tablespace_name IN ('APPS_TS_TX_DATA', 'APPS_TS_TX_IDX')
ORDER BY tablespace_name, timestamp DESC;

-- Identifier les objets les plus gros
SELECT owner, segment_name, segment_type, tablespace_name,
       ROUND(bytes/1024/1024/1024, 2) AS size_gb
FROM dba_segments
WHERE tablespace_name = 'APPS_TS_TX_DATA'
ORDER BY bytes DESC
FETCH FIRST 20 ROWS ONLY;
```

### Annexe B : Script de Rollback

```sql
-- En cas de problème, revenir aux anciennes valeurs
-- (Remplacer par les valeurs d'origine)
ALTER DATABASE DATAFILE '+DATAC1/...' AUTOEXTEND ON MAXSIZE 512G;
ALTER DATABASE DATAFILE '+DATAC1/...' AUTOEXTEND ON MAXSIZE 160G;
-- etc.
```

### Annexe C : Template Email de Communication

```
Objet : [RÉSOLU] Incident Oracle EBS - Import Factures

Bonjour,

L'incident concernant l'échec des imports de factures dans Oracle EBS a été résolu.

Cause identifiée : Dépassement des limites MAXSIZE configurées sur les tablespaces de données.

Action corrective : Augmentation des MAXSIZE pour permettre la croissance naturelle des données.

Statut actuel : ✅ RÉSOLU - Les imports fonctionnent normalement.

Prochaines étapes :
- Mise en place d'alertes préventives
- Revue trimestrielle des capacités

Merci de votre patience.

Cordialement,
L'équipe DBA
```
