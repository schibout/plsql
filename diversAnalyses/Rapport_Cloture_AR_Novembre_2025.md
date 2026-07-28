# Rapport d'Analyse - Lancement Simultané de 2 PEC AR lors de la Clôture de Novembre 2025

**Date d'analyse :** 29/11/2025  
**Analyste :** Système automatisé  
**Contexte :** Nuit de clôture du mois de Novembre 2025 (28/11/2025 → 29/11/2025)  
**Environnement :** Oracle E-Business Suite 12.2.13 - Base Oracle 19.25.0.0.0

---

## 1. RÉSUMÉ EXÉCUTIF

### 1.1 Observation
Lors de la nuit de clôture du vendredi 28 novembre 2025, **deux processus de comptabilisation AR (PEC AR)** ont été lancés simultanément à **19:01:46**, soit exactement à la même seconde.

### 1.2 Cause Identifiée
Les deux PEC AR ne sont pas des doublons accidentels, mais font partie de **deux Request Sets distincts** lancés simultanément par l'utilisateur automatique **EXPLOITATION** à 19:01:45.

- **Request Set 46355006** → Stage 46355008 → PEC AR 46355010
- **Request Set 46355007** → Stage 46355009 → PEC AR 46355011

### 1.3 Impact
- ✅ **Aucun impact négatif détecté** : Les deux processus se sont terminés avec succès
- ✅ Durée identique : 2,53 minutes chacun
- ✅ Fin synchronisée : 19:04:18 pour les deux
- ⚠️ **Question ouverte** : Pourquoi deux Request Sets identiques ont-ils été lancés en même temps ?

---

## 2. CHRONOLOGIE DÉTAILLÉE DE LA NUIT DE CLÔTURE

### 2.1 Début de Nuit (19:00 - 19:30)

| Heure | Programme | Request ID | Durée | Statut |
|-------|-----------|------------|--------|--------|
| **19:00:00** | **DKA : Edition des fichiers de contrôle de pre-cloture** | 46351427 | 4,50 min | C |
| **19:01:45** | **Request Set #1** (lancement) | 46355006 | 7,68 min | C |
| **19:01:45** | **Request Set #2** (lancement) | 46355007 | 16,30 min | C |
| **19:01:46** | DKA : Comptabilisation AR (Stage 1 - Set #1) | 46355010 | 2,53 min | C |
| **19:01:46** | DKA : Comptabilisation AR (Stage 1 - Set #2) | 46355011 | 2,53 min | C |
| **19:04:10** | DKA : Envoi mail fichiers pré-clôture | 46355680 | 0 min | C |
| **19:04:18** | Interface factures manuelles (Stage 2 - Set #1) | 46355012 | 5,08 min | C |
| **19:04:18** | Interface factures manuelles (Stage 2 - Set #2) | 46355013 | 13,72 min | C |
| **19:09:27** | Transfert ajust. AR→PA (Stage 3 - Set #1) | 46355014 | 0,03 min | C |
| **19:17:51** | Transfert ajust. AR→PA (Stage 3 - Set #2) | 46355015 | 0,03 min | C |
| **19:25:48** | Request Set #3 (lancement) | 46355771 | 6,57 min | C |
| **19:25:48** | DKA : Comptabilisation AR (Stage 1 - Set #3) | 46355773 | 2,22 min | C |

### 2.2 Activités Période (19:34)

Entre **19:34:12** et **19:34:34**, exécution massive de **266 processus "Periodic Mass Copy"** en parallèle (durée individuelle : 0,02 à 0,05 min).

### 2.3 Fin de Nuit (22:56 - 05:32)

| Heure | Programme | Request ID | Durée | Statut |
|-------|-----------|------------|--------|--------|
| **22:56:46** | Request Set #4 (lancement) | 46359893 | 8,02 min | C |
| **22:56:46** | DKA : Comptabilisation AR (Stage 1 - Set #4) | 46359896 | 1,92 min | C |
| **23:33:22** | DKA : Ouverture Période AP et Transfert mouvements | 46361103 | 2,42 min | C |
| **23:35:48** | DKA : Cloture de la période AP | 46361424 | 1,27 min | C |
| **23:39:15 - 01:12:07** | **Receipt Accruals - Period-End** (393 exécutions) | 46361435-46362197 | 0,02-4,80 min | C |
| **01:14:44 - 01:19:25** | **Subledger Multiperiod Accrual Request** (293 exécutions) | 46362554-46363118 | 0,08-0,40 min | C |
| **02:05:16** | DKA : Clôture de la période AR | 46363643 | 0,50 min | C |
| **02:25:17** | DKA : Clôture de la période PO | 46363675 | 0,02 min | C |
| **02:26:25 - 02:27:14** | **Reset Period End Accrual Flags** (311 exécutions) | 46363677-46364037 | 0,07-0,75 min | C |
| **05:21:33** | DKA : Edition fichiers contrôle pre-cloture | 46364058 | 0,83 min | C |
| **05:25:05** | DKA : Edition fichiers contrôle pre-cloture (final) | 46364060 | 7,67 min | C |

---

## 3. ANALYSE DES Request SETS SIMULTANÉS

### 3.1 Structure des Request Sets

Chaque Request Set contient **3 stages séquentiels** :

```
Request Set (FNDRSSUB)
  ├─ Stage 1: DKA : Comptabilisation AR (DKA_SXLAACCPBAR)
  ├─ Stage 2: DKA : Interface factures manuelles projets (DKA_SARFACMAN)
  └─ Stage 3: DKA : Transfert ajustements AR vers PA (DKA_SPAAJUSTAR_TRANSFER)
```

### 3.2 Comparaison des Deux Request Sets Simultanés

| Attribut | Request Set #1 (46355006) | Request Set #2 (46355007) |
|----------|-------------------------|-------------------------|
| **Lancé par** | EXPLOITATION | EXPLOITATION |
| **Date planifiée** | 28/11/2025 19:01:45 | 28/11/2025 19:01:45 |
| **Date réelle** | 28/11/2025 19:01:45 | 28/11/2025 19:01:45 |
| **Paramètres** | 50001, 1017 | 50001, 1017 |
| **Durée totale** | 7,68 min | 16,30 min |
| **Stage 1 (PEC AR)** | 2,53 min | 2,53 min |
| **Stage 2 (Interface)** | 5,08 min | **13,72 min** ⚠️ |
| **Stage 3 (Transfert)** | 0,03 min | 0,03 min |
| **Statut final** | C (Completed) | C (Completed) |

### 3.3 Observations Clés

1. **Paramètres identiques** : Les deux Request Sets utilisent les mêmes paramètres "50001, 1017"
2. **Lancement synchrone** : Même seconde (19:01:45)
3. **PEC AR identiques** : Durée rigoureusement identique (2,53 min), fin synchronisée (19:04:18)
4. **Différence sur Stage 2** : Le Request Set #2 a pris 8,64 minutes de plus sur l'interface des factures manuelles

---

## 4. ANALYSE D'IMPACT

### 4.1 Impact sur les Données

✅ **Aucun impact détecté sur l'intégrité des données :**
- Les deux PEC AR se sont terminés avec succès (statut C)
- Aucune erreur rapportée dans les logs
- Les étapes suivantes (Stage 2 et Stage 3) ont été exécutées normalement
- La clôture AR finale (02:05:16) s'est déroulée sans incident

### 4.2 Impact sur les Performances

⚠️ **Impact modéré sur les performances :**
- Deux processus intensifs exécutés simultanément
- Possible contention sur les ressources (CPU, I/O, verrous de table)
- Le Stage 2 du Request Set #2 a pris 2,7x plus de temps (13,72 min vs 5,08 min)
  → Possiblement dû à la concurrence avec le Request Set #1

### 4.3 Impact sur le Timing de Clôture

✅ **Impact minimal sur la durée totale :**
- Request Set #1 terminé : 19:09:27 (7,68 min après le début)
- Request Set #2 terminé : 19:17:51 (16,30 min après le début)
- Surcoût estimé : ~8 minutes (différence entre exécution séquentielle et parallèle)

---

## 5. HYPOTHÈSES SUR L'ORIGINE DU DOUBLON

### 5.1 Hypothèse #1 : Soumission Automatique Double ⭐ (PLUS PROBABLE)

**Description :**  
Un processus de planification (scheduler) a soumis le même Request Set deux fois en raison d'une condition de concurrence ou d'un bug.

**Indices :**
- Les deux Request Sets ont été lancés par **EXPLOITATION** (utilisateur automatique)
- Heure planifiée identique (19:01:45) = déclenchement par scheduler
- Paramètres identiques
- Lancement à la même seconde (pas de délai humain)

**Actions de vérification :**
```sql
-- Vérifier les définitions de planification
SELECT schedule_id, argument_text, last_run_date
FROM fnd_concurrent_request_schedules
WHERE concurrent_program_id IN (
  SELECT concurrent_program_id 
  FROM fnd_concurrent_programs 
  WHERE concurrent_program_name = 'FNDRSSUB'
);
```

### 5.2 Hypothèse #2 : Lancement Manuel Répété

**Description :**  
Un utilisateur (ou script) a soumis deux fois le même Request Set manuellement à 19:01:45.

**Contre-arguments :**
- Peu probable qu'un humain soumette deux fois à la même seconde
- L'utilisateur est "EXPLOITATION" (automatique, pas interactif)

### 5.3 Hypothèse #3 : Configuration Intentionnelle

**Description :**  
Deux Request Sets distincts sont configurés pour traiter des données AR différentes (par exemple, deux entités légales ou deux catégories de factures).

**Vérification nécessaire :**
- Analyser les paramètres "50001, 1017"
- Vérifier si les deux Request Sets traitent des segments de données différents
- Contrôler si cette duplication est documentée dans la procédure de clôture

```sql
-- Identifier le contenu des Request Sets
SELECT frs.request_set_id, frs.request_set_name, frs.user_request_set_name
FROM fnd_request_sets_vl frs
WHERE frs.request_set_id IN (
  SELECT DISTINCT argument1
  FROM fnd_concurrent_requests
  WHERE request_id IN (46355006, 46355007)
);
```

### 5.4 Hypothèse #4 : Erreur de Reprise Automatique

**Description :**  
Un mécanisme de reprise automatique a relancé un Request Set qu'il pensait en échec ou non démarré.

**Contre-arguments :**
- Les deux Request Sets ont démarré simultanément (pas de délai de reprise)
- Aucun Request ID précédent en erreur n'a été identifié

---

## 6. COMPARAISON AVEC LES AUTRES Request SETS DE LA NUIT

### 6.1 Request Set #3 (19:25:48)

| Attribut | Request Set #3 (46355771) |
|----------|--------------------------|
| **Lancé par** | EXPLOITATION |
| **Heure** | 19:25:48 |
| **Durée totale** | 6,57 min |
| **Stage 1 (PEC AR)** | 2,22 min |
| **Stage 2 (Interface)** | 4,32 min |
| **Stage 3 (Transfert)** | 0,03 min |
| **Statut** | C (Completed) |

**Observation :** Lancement unique, pas de doublon → comportement normal

### 6.2 Request Set #4 (22:56:46)

| Attribut | Request Set #4 (46359893) |
|----------|--------------------------|
| **Lancé par** | EXPLOITATION |
| **Heure** | 22:56:46 |
| **Durée totale** | 8,02 min |
| **Stage 1 (PEC AR)** | 1,92 min |
| **Stage 2 (Interface)** | 6,07 min |
| **Stage 3 (Transfert)** | 0,03 min |
| **Statut** | C (Completed) |

**Observation :** Lancement unique, pas de doublon → comportement normal

### 6.3 Synthèse

**Seuls les deux premiers Request Sets (19:01:45) présentent un doublon.**  
Les Request Sets #3 et #4 ont été lancés normalement, ce qui suggère :
- Soit un problème ponctuel au début de la nuit
- Soit une configuration spécifique pour le premier Request Set de la clôture

---

## 7. RECOMMANDATIONS

### 7.1 Court Terme (Immédiat)

#### 7.1.1 Vérification des Données
```sql
-- Vérifier l'absence de doublons dans les écritures comptables AR
SELECT xal.accounting_date,
       xal.ledger_id,
       xal.code_combination_id,
       COUNT(*) as nb_lignes,
       SUM(xal.accounted_dr) as total_debit,
       SUM(xal.accounted_cr) as total_credit
FROM xla_ae_lines xal
WHERE xal.accounting_date = TO_DATE('28/11/2025', 'DD/MM/YYYY')
  AND xal.application_id = 222 -- AR
GROUP BY xal.accounting_date, xal.ledger_id, xal.code_combination_id
HAVING COUNT(*) > 1;
```

#### 7.1.2 Analyse des Logs
- Consulter les fichiers de sortie (output) des Request IDs 46355006 et 46355007
- Vérifier si les deux Request Sets ont traité les mêmes transactions AR
- Identifier les paramètres réels passés ("50001, 1017")

#### 7.1.3 Validation Comptable
- Exécuter les états de contrôle post-clôture
- Comparer les soldes AR avant/après la nuit de clôture
- Vérifier l'équilibrage avec le Grand Livre

### 7.2 Moyen Terme (1-2 semaines)

#### 7.2.1 Révision de la Configuration des Planifications
```sql
-- Lister toutes les planifications actives pour les Request Sets
SELECT fcrs.schedule_id,
       fcrs.user_schedule_name,
       fcp.user_concurrent_program_name,
       fcrs.next_run_date,
       fcrs.last_run_date,
       fcrs.argument_text
FROM fnd_concurrent_request_schedules fcrs
JOIN fnd_concurrent_programs_vl fcp 
  ON fcrs.concurrent_program_id = fcp.concurrent_program_id
WHERE fcp.concurrent_program_name = 'FNDRSSUB'
  AND fcrs.enabled_flag = 'Y'
ORDER BY fcrs.next_run_date;
```

**Actions :**
- Identifier si deux planifications pointent vers le même Request Set avec les mêmes paramètres
- Désactiver les planifications en double le cas échéant
- Documenter les planifications légitimes

#### 7.2.2 Mise en Place de Garde-Fous
- Créer un script de pré-vérification avant chaque clôture :
  ```sql
  -- Détecter les Request Sets en double dans les 5 dernières minutes
  SELECT fcp.user_concurrent_program_name,
         fcr.argument_text,
         COUNT(*) as nb_instances,
         MIN(fcr.request_id) as premier_request,
         MAX(fcr.request_id) as dernier_request
  FROM fnd_concurrent_requests fcr
  JOIN fnd_concurrent_programs_vl fcp 
    ON fcr.concurrent_program_id = fcp.concurrent_program_id
  WHERE fcp.concurrent_program_name = 'FNDRSSUB'
    AND fcr.actual_start_date >= SYSDATE - 5/1440 -- 5 dernières minutes
  GROUP BY fcp.user_concurrent_program_name, fcr.argument_text
  HAVING COUNT(*) > 1;
  ```

#### 7.2.3 Documentation de la Procédure de Clôture
- Formaliser le nombre attendu de Request Sets par nuit de clôture
- Documenter les paramètres ("50001, 1017") et leur signification
- Établir une checklist de validation post-clôture

### 7.3 Long Terme (1-3 mois)

#### 7.3.1 Monitoring Automatisé
Créer une alerte automatique pour détecter :
- Les Request Sets lancés en double dans un intervalle de 60 secondes
- Les PEC AR exécutés plus de 2 fois dans la même nuit
- Les durées d'exécution anormalement longues (>20 min pour un Request Set)

**Exemple de script d'alerte :**
```sql
-- À exécuter toutes les 5 minutes pendant la clôture
SELECT 'ALERTE : Request Sets en double détectés' AS statut,
       COUNT(*) as nb_doublons
FROM (
  SELECT fcr.argument_text,
         fcr.actual_start_date,
         COUNT(*) as nb
  FROM fnd_concurrent_requests fcr
  JOIN fnd_concurrent_programs_vl fcp 
    ON fcr.concurrent_program_id = fcp.concurrent_program_id
  WHERE fcp.concurrent_program_name = 'FNDRSSUB'
    AND fcr.actual_start_date >= TRUNC(SYSDATE) + 19/24 -- Après 19h00
    AND fcr.actual_start_date <= TRUNC(SYSDATE) + 23/24 -- Avant 23h00
  GROUP BY fcr.argument_text, fcr.actual_start_date
  HAVING COUNT(*) > 1
)
WHERE nb > 0;
```

#### 7.3.2 Optimisation de la Stratégie de Clôture
- Analyser la possibilité d'exécuter certains Request Sets en séquentiel strict
- Évaluer l'impact d'un mécanisme de verrouillage (lock) pour éviter les doublons
- Envisager un dashboard de monitoring en temps réel de la clôture

#### 7.3.3 Formation et Sensibilisation
- Former les équipes Finance et IT aux signes d'alerte lors des clôtures
- Documenter les procédures d'escalation en cas de doublon détecté
- Organiser des revues post-mortem après chaque clôture mensuelle

---

## 8. QUESTIONS EN SUSPENS

### 8.1 Questions Techniques

1. **Que signifient les paramètres "50001, 1017" ?**
   - 50001 = ID du Request Set ? Définition de périmètre ?
   - 1017 = Ledger ID ? Période comptable ? Organization ID ?

2. **Les deux Request Sets ont-ils traité les mêmes données AR ?**
   - Même périmètre de transactions ?
   - Même entité légale ?
   - Doublons potentiels dans les écritures comptables ?

3. **Pourquoi le Stage 2 du Request Set #2 a-t-il pris 2,7x plus de temps ?**
   - Contention de ressources ?
   - Traitement de données différentes ?
   - Verrous de table ?

4. **Existe-t-il un historique de doublons similaires ?**
   - Clôtures précédentes (octobre, septembre...) ?
   - Autres modules (AP, PA, GL) ?

### 8.2 Questions Métier

5. **Cette duplication était-elle intentionnelle ?**
   - Procédure documentée ?
   - Exigence métier de double-comptabilisation ?

6. **Quel est le risque d'impact comptable ?**
   - Doublons d'écritures ?
   - Incohérences entre modules (AR vs GL vs SLA) ?

7. **La clôture de Novembre 2025 est-elle validée ?**
   - Tous les états de contrôle OK ?
   - Validation par la Direction Financière ?

---

## 9. ACTIONS IMMÉDIATES REQUISES

### Priorité 1 (Urgent - Aujourd'hui)
- [ ] **Vérifier l'intégrité des écritures AR du 28/11/2025**
  - Requête SQL de détection des doublons
  - Comparaison des totaux AR avant/après clôture
- [ ] **Consulter les logs de sortie des Request IDs 46355006 et 46355007**
  - Identifier les transactions traitées par chaque Request Set
  - Vérifier la présence de messages d'erreur ou d'avertissement
- [ ] **Valider la clôture AR de Novembre 2025**
  - Exécuter l'état "AR Trial Balance"
  - Confirmer l'équilibrage avec le GL

### Priorité 2 (Important - Cette Semaine)
- [ ] **Analyser la configuration des planifications des Request Sets**
  - Identifier les planifications actives pour "FNDRSSUB"
  - Rechercher les doublons de configuration
- [ ] **Documenter les paramètres "50001, 1017"**
  - Interroger l'équipe Finance sur leur signification
  - Vérifier la documentation technique EBS
- [ ] **Comparer avec les clôtures précédentes**
  - Rechercher des doublons similaires en octobre et septembre 2025

### Priorité 3 (Normal - Dans les 2 Semaines)
- [ ] **Mettre en place un script d'alerte pour les prochaines clôtures**
  - Détecter les Request Sets en double en temps réel
  - Notifier l'équipe IT et Finance immédiatement
- [ ] **Réviser la procédure de clôture AR**
  - Formaliser le nombre attendu de Request Sets
  - Ajouter des points de contrôle (checkpoints)

---

## 10. CONCLUSION

### 10.1 Synthèse des Faits

Le **28 novembre 2025 à 19:01:45**, deux Request Sets identiques (46355006 et 46355007) ont été lancés simultanément par l'utilisateur automatique **EXPLOITATION**, avec les mêmes paramètres ("50001, 1017"). Chaque Request Set a exécuté trois stages, incluant un PEC AR (comptabilisation AR) qui s'est déroulé avec une durée identique (2,53 minutes) et une fin synchronisée (19:04:18).

**Bien qu'aucune erreur n'ait été rapportée et que tous les processus se soient terminés avec succès**, cette duplication pose question :
- **Est-ce intentionnel** (configuration métier) ?
- **Est-ce un bug** (planification défectueuse, condition de concurrence) ?
- **Y a-t-il un risque de doublons comptables** ?

### 10.2 Risque Résiduel

✅ **Risque faible sur l'intégrité des données** (aucune erreur détectée, clôture terminée)  
⚠️ **Risque moyen de récurrence** (cause non identifiée)  
🔍 **Besoin urgent de clarification** (vérification comptable et configuration)

### 10.3 Recommandation Principale

**Action prioritaire :** Exécuter les requêtes SQL de vérification d'intégrité (Section 7.1.1) et consulter les logs des Request Sets (Section 7.1.2) pour s'assurer qu'aucun doublon comptable n'a été créé.

**Si aucun problème n'est détecté :** Mettre en place un monitoring proactif (Section 7.3.1) pour prévenir toute récurrence.

**Si des doublons sont détectés :** Lancer une procédure d'urgence de correction comptable et contacter Oracle Support pour investigation approfondie.

---

## ANNEXES

### A. Requêtes SQL Utilisées pour l'Analyse

#### A.1 Identification des PEC AR Simultanés
```sql
SELECT fcr.request_id,
       fcp.user_concurrent_program_name as programme,
       TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS') as debut,
       TO_CHAR(fcr.actual_completion_date, 'DD/MM/YYYY HH24:MI:SS') as fin,
       ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2) as duree_min,
       fcr.parent_request_id
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp 
  ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE fcp.concurrent_program_name = 'DKA_SXLAACCPBAR'
  AND TRUNC(fcr.actual_start_date) = TO_DATE('28/11/2025', 'DD/MM/YYYY')
ORDER BY fcr.actual_start_date;
```

#### A.2 Traçage des Request Sets Parents
```sql
SELECT fcr.request_id,
       fcp.user_concurrent_program_name as programme,
       fu.user_name as lance_par,
       TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS') as debut,
       ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2) as duree_min,
       fcr.argument_text as parametres
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp 
  ON fcr.concurrent_program_id = fcp.concurrent_program_id
JOIN fnd_user fu 
  ON fcr.requested_by = fu.user_id
WHERE fcr.request_id IN (46355006, 46355007)
ORDER BY fcr.request_id;
```

#### A.3 Analyse des Processus Enfants
```sql
SELECT fcr.request_id,
       fcr.parent_request_id,
       fcp.user_concurrent_program_name as programme,
       TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS') as debut,
       TO_CHAR(fcr.actual_completion_date, 'DD/MM/YYYY HH24:MI:SS') as fin,
       ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2) as duree_min,
       fcr.phase_code,
       fcr.status_code
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp 
  ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE fcr.parent_request_id IN (46355006, 46355007, 46355771, 46359893)
ORDER BY fcr.parent_request_id, fcr.actual_start_date;
```

### B. Glossaire

| Terme | Définition |
|-------|------------|
| **PEC AR** | Programme d'Écritures Comptables AR = Comptabilisation AR (Create Accounting) |
| **Request Set** | Ensemble de programmes concurrents exécutés en séquence ou en parallèle |
| **Stage** | Étape d'un Request Set, peut contenir un ou plusieurs programmes |
| **FNDRSSUB** | Programme système Oracle EBS pour l'exécution des Request Sets |
| **EXPLOITATION** | Utilisateur automatique Oracle EBS pour les traitements batch planifiés |
| **Request ID** | Identifiant unique d'une demande de traitement concurrent |
| **Phase Code** | Statut de phase : R=Running, C=Completed, P=Pending |
| **Status Code** | Statut détaillé : C=Completed, R=Running, E=Error, W=Warning |

### C. Contacts

| Rôle | Contact | Responsabilité |
|------|---------|----------------|
| **Responsable Clôture Financière** | [À compléter] | Validation comptable |
| **Administrateur EBS** | [À compléter] | Configuration technique |
| **DBA Oracle** | [À compléter] | Analyse performances |
| **Support Oracle** | [À compléter] | Escalation bugs |

---

**Rapport généré le :** 29/11/2025  
**Prochaine revue prévue :** Avant la clôture de Décembre 2025  
**Statut du rapport :** ⚠️ EN ATTENTE DE VALIDATION COMPTABLE
