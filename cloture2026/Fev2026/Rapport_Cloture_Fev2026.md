# Rapport de Vérification - Clôture Février 2026

**Date d'analyse :** 02/03/2026  
**Période analysée :** 27/02/2026 23:00 → 28/02/2026 08:00  
**Base de données :** Oracle EBS 12.2.13 (Oracle 19.28.0.0.0)  
**Connexion :** oracleProd

---

## 1. Synthèse Exécutive

| Indicateur | Valeur |
|------------|--------|
| **Traitements critiques vérifiés** | 10 |
| **Statut OK** | 8 |
| **Warnings** | 2 |
| **Erreurs bloquantes** | 0 |
| **Traitements encore en cours** | 4 |

### ✅ Verdict Global : CLÔTURE RÉUSSIE (avec points d'attention mineurs)

---

## 2. Détail des Traitements Critiques de Clôture

### 2.1 DKA : Imputation des charges d'achats

| Élément | Valeur |
|---------|--------|
| **Request ID** | 47237673 |
| **Statut** | ✅ OK |
| **Début** | 27/02/2026 23:40:35 |
| **Fin** | 28/02/2026 01:15:36 |
| **Durée** | 95.02 minutes |
| **Message** | Fin normale |

**Commentaire :** Traitement nominal, durée dans les standards habituels (~1h30).

---

### 2.2 DKA : Clôture de la période AR

| Élément | Valeur |
|---------|--------|
| **Request ID** | 47239901 |
| **Statut** | ✅ OK |
| **Début** | 28/02/2026 01:52:11 |
| **Fin** | 28/02/2026 01:52:44 |
| **Durée** | 0.55 minute (33 secondes) |
| **Message** | Fin normale |

**Commentaire :** Exécution très rapide, conforme aux attentes. Pas de déclenchement d'astreinte comme prévu.

---

### 2.3 DKA : Cloture de la période AP

| Élément | Valeur |
|---------|--------|
| **Request ID** | 47237650 |
| **Statut** | ✅ OK |
| **Début** | 27/02/2026 23:38:23 |
| **Fin** | 27/02/2026 23:39:30 |
| **Durée** | 1.12 minute |
| **Message** | Fin normale |

**Commentaire :** Clôture AP effectuée avant le début de l'imputation des charges.

---

### 2.4 DKA : Clôture de la période PO (SSP)

| Élément | Valeur |
|---------|--------|
| **Request ID** | 47241885 |
| **Statut** | ⚠️ Warning |
| **Début** | 28/02/2026 02:24:41 |
| **Fin** | 28/02/2026 02:24:43 |
| **Durée** | 0.03 minute (2 secondes) |
| **Message** | *(vide)* |

**Commentaire :** Warning sans message explicite. À investiguer dans les logs de la requête 47241885 pour identifier la cause. Le traitement parent (Lanceur SHELL 47241884) indique "Fin Anormale".

**Action recommandée :** Vérifier le fichier log de la requête 47241885 via :
```sql
SELECT * FROM FND_CONCURRENT_REQUESTS WHERE REQUEST_ID = 47241885;
```

---

### 2.5 DKA : Génération des OD CAP multi-société

| Élément | Valeur |
|---------|--------|
| **Request ID** | 47239368 |
| **Statut** | ✅ OK |
| **Début** | 28/02/2026 01:16:45 |
| **Fin** | 28/02/2026 01:17:51 |
| **Durée** | 1.10 minute |
| **Message** | Fin normale |

**Commentaire :** Traitement nominal.

---

### 2.6 DKA : Calcul des TEC et PCA

| Élément | Valeur |
|---------|--------|
| **Nombre de requêtes** | ~80 |
| **Statut global** | ✅ OK |
| **Plage horaire** | 28/02/2026 01:54:27 → 02:52:22 |
| **Durée max** | 57.52 minutes (Request 47239979) |
| **Message** | Fin normale (tous) |

**Détail des requêtes les plus longues :**

| Request ID | Durée (min) | Fin |
|------------|-------------|-----|
| 47239979 | 57.52 | 28/02/2026 02:52:22 |
| 47239985 | 42.48 | 28/02/2026 02:37:23 |
| 47239976 | 18.00 | 28/02/2026 02:12:50 |
| 47239981 | 18.00 | 28/02/2026 02:12:52 |
| 47239971 | 16.97 | 28/02/2026 02:11:21 |

**Commentaire :** Tous les calculs TEC/PCA terminés avec succès.

---

### 2.7 DKA : Gestion des CCA sur sinistres

| Élément | Valeur |
|---------|--------|
| **Nombre de requêtes** | ~100 |
| **Statut global** | ⚠️ 2 Warnings, reste OK |
| **Plage horaire** | 28/02/2026 01:54:35 → 02:13:18 |

**Requêtes en Warning :**

| Request ID | Début | Fin | Durée | Message |
|------------|-------|-----|-------|---------|
| 47239968 | 28/02/2026 01:54:45 | 28/02/2026 01:55:23 | 0.63 min | *(vide)* |
| 47240394 | 28/02/2026 02:02:32 | 28/02/2026 02:03:06 | 0.57 min | *(vide)* |

**Action recommandée :** Vérifier les fichiers logs des requêtes 47239968 et 47240394 pour identifier les sociétés/sinistres concernés.

---

### 2.8 DKA : Equilibre comptable par centre de gestion

| Élément | Valeur |
|---------|--------|
| **Request ID** | 47242273 |
| **Statut** | ✅ OK |
| **Début** | 28/02/2026 03:20:07 |
| **Fin** | 28/02/2026 03:21:42 |
| **Durée** | 1.58 minute |
| **Message** | Fin normale |

**Commentaire :** Traitement nominal, équilibre comptable vérifié.

---

### 2.9 Clôture provisoire GL (Periods - Close Period)

| Élément | Valeur |
|---------|--------|
| **Nombre de requêtes** | ~250 |
| **Statut global** | ✅ OK |
| **Plage horaire** | 28/02/2026 03:22:59 → 03:24:35 |
| **Durée moyenne** | 0.10 - 0.30 minute par période |
| **Message** | Fin normale (tous) |

**Commentaire :** Toutes les périodes GL fermées avec succès.

---

### 2.10 Refacturation intra-groupe

| Élément | Valeur |
|---------|--------|
| **Nombre de requêtes** | 15 |
| **Statut global** | ✅ OK |
| **Plage horaire** | 27/02/2026 23:36:25 → 23:38:36 |
| **Message** | Fin normale (tous) |

**Programmes exécutés :**
- DKA : Refacturation automatique (impression) - Request 47237341
- DKA : Edition des factures de refacturation - 14 requêtes

**Commentaire :** Dernier passage de refacturation terminé avant la clôture AP.

---

## 3. Erreurs Détectées (hors périmètre clôture strict)

### 3.1 Erreurs SMTP - Situation Oracle du matin

| Request ID | Programme | Heure | Message |
|------------|-----------|-------|---------|
| 47244143 | DKA : Situation Oracle du matin | 28/02/2026 03:46:32 | ERREUR : User-Defined Exception |
| 47244153 | DKA : Envoi par mail des fichiers de situation Oracle | 28/02/2026 04:12:31 | ORA-29279: erreur permanente SMTP : 552 5.3.4 Error: message file too big |

**Cause probable :** Le fichier de situation Oracle généré dépasse la limite de taille autorisée par le serveur SMTP.

**Impact :** Non bloquant pour la clôture, mais l'email de situation n'a pas été envoyé.

---

### 3.2 Erreurs TVA

| Request ID | Programme | Heure | Message |
|------------|-----------|-------|---------|
| 47244874 | DKA : Etat justificatif de l'en-cours de TVA sur encaissement | 28/02/2026 16:04:40 | Erreur GTS/Oracle Report (210.7 min) |
| 47244888 | DKA : Etat justificatif des comptes de TVA sur décaissement | 28/02/2026 16:51:46 | Erreur GTS/Oracle Report |

**Impact :** États TVA non générés pour certaines sociétés.

---

## 4. Traitements Encore en Cours

| Request ID | Programme | Début | Durée estimée |
|------------|-----------|-------|---------------|
| 47241701 | DKA : Lanceur (SHELL) | 28/02/2026 01:59:39 | >48h |
| 47241705 | DKA : Automate Edition des états de TVA pour la société 0001 | 28/02/2026 01:59:41 | >48h |
| 47241714 | DKA : France - Déclaration détaillée de la TVA déductible | 28/02/2026 02:31:23 | >48h |
| 47244880 | DKA : Etat justificatif de l'en-cours de TVA sur encaissement | 28/02/2026 16:38:11 | >33h |

**⚠️ ATTENTION :** Ces traitements sont en cours depuis plus de 48 heures. Une investigation est nécessaire.

**Actions recommandées :**
1. Vérifier l'état des sessions Oracle associées
2. Analyser les verrous éventuels (V$LOCK, V$SESSION)
3. Envisager l'annulation si les traitements sont bloqués

---

## 5. Chronologie des Événements

```
27/02/2026
├── 23:36:25 - Début Refacturation intra-groupe
├── 23:38:23 - Début Clôture période AP
├── 23:38:36 - Fin Refacturation intra-groupe ✅
├── 23:39:30 - Fin Clôture période AP ✅
└── 23:40:35 - Début Imputation des charges d'achats

28/02/2026
├── 01:15:36 - Fin Imputation des charges d'achats ✅
├── 01:16:45 - Début Génération OD CAP multi-société
├── 01:17:51 - Fin Génération OD CAP ✅
├── 01:52:11 - Début Clôture période AR
├── 01:52:44 - Fin Clôture période AR ✅
├── 01:54:27 - Début Calculs TEC/PCA et CCA sur sinistre
├── 02:24:41 - Début Clôture période PO (Warning)
├── 02:52:22 - Fin derniers TEC/PCA ✅
├── 03:20:07 - Début Équilibre comptable par CDG
├── 03:21:42 - Fin Équilibre comptable ✅
├── 03:22:59 - Début Clôture provisoire GL
├── 03:24:35 - Fin Clôture provisoire GL ✅
└── 03:46:32 - Erreur Situation Oracle du matin
```

---

## 6. Requêtes SQL de Vérification

### 6.1 Vérifier les détails des Warnings PO

```sql
SELECT fcr.REQUEST_ID,
       fcr.LOGFILE_NAME,
       fcr.OUTFILE_NAME,
       fcr.ARGUMENT_TEXT
FROM FND_CONCURRENT_REQUESTS fcr
WHERE fcr.REQUEST_ID = 47241885;
```

### 6.2 Vérifier les traitements encore en cours

```sql
SELECT fcr.REQUEST_ID,
       fcp.USER_CONCURRENT_PROGRAM_NAME,
       fcr.PHASE_CODE,
       fcr.STATUS_CODE,
       TO_CHAR(fcr.ACTUAL_START_DATE, 'DD/MM/YYYY HH24:MI:SS') AS DEBUT,
       ROUND((SYSDATE - fcr.ACTUAL_START_DATE) * 24, 2) AS HEURES_EN_COURS
FROM FND_CONCURRENT_REQUESTS fcr
JOIN FND_CONCURRENT_PROGRAMS_VL fcp ON fcr.CONCURRENT_PROGRAM_ID = fcp.CONCURRENT_PROGRAM_ID
WHERE fcr.STATUS_CODE = 'R'
  AND UPPER(fcp.USER_CONCURRENT_PROGRAM_NAME) LIKE '%DKA%'
ORDER BY fcr.ACTUAL_START_DATE;
```

### 6.3 Vérifier les sessions Oracle actives pour les traitements bloqués

```sql
SELECT s.SID, s.SERIAL#, s.USERNAME, s.PROGRAM, s.STATUS,
       s.LAST_CALL_ET/60 AS MINUTES_INACTIF
FROM V$SESSION s
WHERE s.USERNAME IS NOT NULL
  AND s.STATUS = 'ACTIVE'
ORDER BY s.LAST_CALL_ET DESC;
```

---

## 7. Conclusion et Recommandations

### ✅ Points Positifs
- Tous les traitements critiques de clôture sont terminés
- La séquence d'exécution respecte les dépendances (AP → AR → PO → GL)
- Les durées d'exécution sont dans les normes habituelles
- Pas d'erreur bloquante sur le périmètre clôture

### ⚠️ Points d'Attention
1. **Clôture PO en Warning** - Investiguer la requête 47241885
2. **2 CCA sur sinistre en Warning** - Vérifier les sociétés concernées
3. **4 traitements TVA bloqués depuis >48h** - Action urgente requise
4. **Erreur SMTP** - Fichier situation Oracle trop volumineux

### 📋 Actions à Mener
1. [ ] Analyser les logs de la requête 47241885 (Clôture PO)
2. [ ] Vérifier les requêtes CCA 47239968 et 47240394
3. [ ] Investiguer et débloquer les 4 traitements TVA en cours
4. [ ] Revoir la configuration SMTP pour les fichiers volumineux

---

*Rapport généré automatiquement - GitHub Copilot*  
*Voir : [Controle_Cloture_Quotidien.sql](Controle_Cloture_Quotidien.sql)*
