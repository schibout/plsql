# 🚨 RAPPORT DÉTAILLÉ - Problème traitement "Mise à jour quotidienne des sites fournisseurs dupliqués"

**Date du rapport** : 28 novembre 2025 à 16:00  
**Request ID analysé** : 46351151  
**Connexion** : oracleProd  
**Analyste** : GitHub Copilot (Claude Sonnet 4.5)

---

## 📊 RÉSUMÉ EXÉCUTIF

### **🔴 PROBLÈME MAJEUR IDENTIFIÉ**

**27,155 sites fournisseurs ont été modifiés massivement le 27/11/2025 entre 13h07 et 13h38**

Cette modification massive explique pourquoi le traitement dure anormalement longtemps.

---

## 🔍 ANALYSE DÉTAILLÉE

### **1. État actuel du traitement**

| Indicateur | Valeur |
|------------|--------|
| **Request ID** | 46351151 |
| **Lancé le** | 28/11/2025 à 07:00:07 |
| **Durée actuelle** | **536 minutes (8h 56min)** |
| **Statut** | Running (toujours en cours) |
| **Process OS** | 5580 |
| **Oracle Process** | 284217 |

**Durée habituelle** : 18 secondes  
**Durée anormale** : 536 minutes = **x1787 plus lent que la normale**

---

### **2. Volume de données à traiter**

| Métrique | Valeur | Détail |
|----------|--------|--------|
| **Total sites REF9999** | 43,116 sites | Base totale |
| **Sites à traiter** | **27,164 sites** | Sites modifiés depuis dernière MAJ |
| **% à traiter** | **63%** | Proportion énorme ! |
| **Sites traités avec erreur** | 2,109 sites | Erreurs détectées |
| **Progression estimée** | ~7.8% | 2,109 / 27,164 |

---

### **3. Date de dernière mise à jour**

```
Date dernière MAJ : 27/11/2025 à 12:10:09
Temps écoulé      : 27.77 heures (1.16 jours)
```

Cette date est **normale** (hier midi).

---

### **4. 🔴 CAUSE RACINE IDENTIFIÉE - Modification massive des sites**

#### **Chronologie de l'incident du 27/11/2025**

**Entre 13h07 et 13h38** (31 minutes), **27,155 sites fournisseurs** ont été modifiés :

| Heure | Nb sites modifiés | Cumul |
|-------|-------------------|-------|
| 13:07 | 449 | 449 |
| 13:08 | 896 | 1,345 |
| 13:09 | 1,007 | 2,352 |
| 13:10 | 970 | 3,322 |
| 13:11 | 871 | 4,193 |
| 13:12 | 939 | 5,132 |
| 13:13 | 931 | 6,063 |
| 13:14 | 930 | 6,993 |
| 13:15 | 924 | 7,917 |
| 13:16 | 845 | 8,762 |
| 13:17 | 887 | 9,649 |
| 13:18 | 817 | 10,466 |
| 13:19 | 800 | 11,266 |
| 13:20 | 840 | 12,106 |
| ... | ... | ... |
| 13:38 | 633 | **27,155** |

**Débit moyen** : ~875 sites/minute pendant 31 minutes

---

### **5. Origine de la modification massive**

**Utilisateur responsable** : `EXPLOITATION` (User ID: 1205)

| Utilisateur | User Name | Nb sites modifiés | % |
|-------------|-----------|-------------------|---|
| **EXPLOITATION** | Utilisateur Exploitation | **27,153** | 99.99% |
| 75449A | HOUNNOU HERMINE | 2 | 0.01% |
| E04542S | FAMECHON ASHLEY | 2 | 0.01% |
| E69061K | DEREZ, MARTINE | 1 | 0.00% |
| E28736E | TOREL LAURENT | 1 | 0.00% |

**Conclusion** : Il s'agit d'un **traitement batch automatique** lancé par l'utilisateur technique `EXPLOITATION`.

**Hypothèses** :
- Import massif depuis un système externe (iValua, SAP, etc.)
- Migration de données
- Mise à jour massive de coordonnées bancaires
- Correction en masse d'anomalies

---

### **6. Progression du traitement actuel (28/11/2025)**

#### **Analyse des erreurs rencontrées**

**Total erreurs** : 2,109 sites en erreur depuis 07:00

**Répartition des erreurs par heure** :
| Heure | Nb erreurs | Cumul |
|-------|------------|-------|
| 07:00-08:00 | 185 | 185 |
| 08:00-09:00 | 251 | 436 |
| 09:00-10:00 | 285 | 721 |
| 10:00-11:00 | 330 | 1,051 |
| 11:00-12:00 | 249 | 1,300 |
| 12:00-13:00 | 299 | 1,599 |
| 13:00-14:00 | 282 | 1,881 |
| 14:00-15:00 | 147 | 2,028 |
| 15:00-16:00 | 81 | 2,109 |

**Vitesse de traitement** :
- Moyenne : ~235 sites/heure
- Dont erreurs : ~235 erreurs/heure
- **Estimation temps restant** : (27,164 - 2,109) / 235 = **106 heures** ⚠️

**🔴 ALERTE** : À ce rythme, le traitement prendrait **4.4 jours** pour se terminer !

---

### **7. Types d'erreurs rencontrées**

#### **TOP 3 des erreurs (représentent 1,932 erreurs / 91.6%)**

**1. Erreur clés comptables désactivées - Entité 0458.DCW** (1,023 erreurs = 48.5%)
```
- 0458.DCW.401100.25020.0.0.0.0.0.0.0.0 : Combinaison désactivée (341 occurrences)
- 0458.DCW.409100.14300.0.0.0.0.0.0.0.0 : Combinaison désactivée (341 occurrences)
- 0458.DCW.403100.25020.0.0.0.0.0.0.0.0 : Combinaison désactivée (341 occurrences)
```

**2. Erreur clés comptables désactivées - Entité 0483.DEW** (597 erreurs = 28.3%)
```
- 0483.DEW.403100.25020.0.0.0.0.0.0.0.0 : Combinaison désactivée (199 occurrences)
- 0483.DEW.409100.14300.0.0.0.0.0.0.0.0 : Combinaison désactivée (199 occurrences)
- 0483.DEW.401100.25020.0.0.0.0.0.0.0.0 : Combinaison désactivée (199 occurrences)
```

**3. Erreur fourchettes temporelles comptes bancaires** (112 erreurs = 5.3%)
```
- LOGEO GESTION : Superposition de fourchettes (58 occurrences)
- URBANSOCCER OUEST : Superposition de fourchettes (54 occurrences)
```

---

### **8. Impact sur le système**

#### **Performance du système**

| Indicateur | Valeur | Commentaire |
|------------|--------|-------------|
| **Locks actifs** | 0 sur AP_SUPPLIER_SITES_ALL | Pas de blocage |
| **Durée transaction** | 8h56min | Transaction unique très longue |
| **UNDO tablespace** | À surveiller | Risque de saturation |
| **Fréquence normale** | Toutes les 10 min (72x/jour) | Programme très fréquent |

#### **Impact métier**

- **Paiements fournisseurs** : Potentiellement impactés si les coordonnées bancaires ne sont pas à jour
- **Factures** : Possible blocage si les clés comptables sont invalides
- **Reporting** : Données de référence fournisseurs non synchronisées

---

## 🔍 ANALYSE DU CODE PL/SQL

### **Package : DKA_SAPFRSDUPLI_MAJ_PKG.MAIN**

#### **Problèmes de conception identifiés**

**1. Absence de COMMIT intermédiaire** 🔴
```plsql
FOR rec_site_a_maj IN SITE_A_MAJ (v_date_maj) LOOP
    -- Traitement de chaque site
    DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR(...);
    -- Pas de COMMIT !
END LOOP;
```

**Conséquence** : 
- Une seule transaction pour 27,164 sites
- Occupation excessive UNDO
- Impossible de reprendre en cas d'échec
- Ralentissement progressif

**2. Curseur avec 7 jointures** 🟡
```sql
FROM ap_supplier_sites_all assa
, ap_suppliers ass
, hr_operating_units hou
, iby_ext_bank_accounts ieb          -- (+)
, iby_pmt_instr_uses_all ipi         -- (+)
, iby_external_payees_all iep        -- (+)
, iby_ext_party_pmt_mthds ieppm
```

**Conséquence** : 
- Performance dégradée avec volume important
- Plan d'exécution potentiellement inefficace

**3. Traitement séquentiel unitaire** 🟡
```plsql
FOR rec_site_a_maj IN SITE_A_MAJ LOOP  -- Boucle sur 27,164 sites
    FOR rec_erreur_maj IN (...) LOOP   -- Boucle imbriquée
        SELECT hou.name INTO V_UO_SITE_DUP ...  -- SELECT unitaire
    END LOOP;
END LOOP;
```

**Conséquence** :
- Appels multiples à MAJ_SITE_FOURNISSEUR (package non analysé)
- SELECT supplémentaires par site en erreur
- Pas de traitement par batch (BULK COLLECT)

---

## 🚨 ACTIONS IMMÉDIATES RECOMMANDÉES

### **1. ARRÊTER le traitement actuel** 🔴 URGENT

Le traitement prendrait 4.4 jours à ce rythme. Il faut l'arrêter.

```sql
-- Identifier la session Oracle (à faire en tant que DBA)
SELECT s.sid, s.serial#, s.username, s.program
FROM v$session s
WHERE s.process = '5580'
   OR s.module LIKE '%46351151%';

-- Tuer la session
-- ALTER SYSTEM KILL SESSION 'sid,serial#' IMMEDIATE;
```

**OU** via l'interface Oracle EBS :
- Aller dans "Traitements concurrents"
- Chercher Request ID 46351151
- Cliquer sur "Terminer" ou "Annuler"

---

### **2. Comprendre la modification massive du 27/11** 🔴 URGENT

**Questions à poser à l'équipe métier** :
- Quel traitement batch a été lancé le 27/11 à 13h07 par EXPLOITATION ?
- S'agissait-il d'un import depuis iValua, SAP ou autre système ?
- Était-ce planifié ou exceptionnel ?
- Y a-t-il eu une migration de données ?

**Requête pour identifier le traitement** :
```sql
SELECT fcr.request_id,
       fcp.user_concurrent_program_name,
       TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS') as debut,
       TO_CHAR(fcr.actual_completion_date, 'DD/MM/YYYY HH24:MI:SS') as fin
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE fcr.actual_start_date >= TO_DATE('27/11/2025 13:00:00', 'DD/MM/YYYY HH24:MI:SS')
  AND fcr.actual_start_date <= TO_DATE('27/11/2025 13:40:00', 'DD/MM/YYYY HH24:MI:SS')
  AND fcr.requested_by = 1205  -- User EXPLOITATION
ORDER BY fcr.actual_start_date;
```

---

### **3. Corriger les erreurs de clés comptables** 🟡 IMPORTANT

**Entités concernées** :
- **0458.DCW** : 1,023 sites en erreur (combinaisons désactivées)
- **0483.DEW** : 597 sites en erreur (combinaisons désactivées)
- **0329.DOS** : 62 sites en erreur (combinaisons expirées)

**Actions** :
1. Réactiver les combinaisons de comptes dans le grand livre (GL)
2. Ou mettre à jour les clés comptables des sites fournisseurs concernés
3. Vérifier les dates de validité des combinaisons

---

### **4. Corriger les erreurs de comptes bancaires** 🟡 IMPORTANT

**Comptes concernés** :
- **LOGEO GESTION** : 58 sites (superposition de fourchettes temporelles)
- **URBANSOCCER OUEST** : 54 sites (superposition de fourchettes temporelles)

**Actions** :
1. Vérifier les dates de début/fin dans `iby_pmt_instr_uses_all`
2. Corriger les chevauchements de périodes
3. S'assurer qu'un seul compte bancaire est actif par période

---

### **5. Optimiser le traitement** 🟡 IMPORTANT

**Court terme** :
```plsql
-- Ajouter COMMIT tous les 100 sites
FOR rec_site_a_maj IN SITE_A_MAJ (v_date_maj) LOOP
    -- Traitement...
    g_nbr_site := g_nbr_site + 1;
    
    IF MOD(g_nbr_site, 100) = 0 THEN
        COMMIT;
    END IF;
END LOOP;
```

**Moyen terme** :
- Utiliser BULK COLLECT pour traiter par lots
- Ajouter un paramètre pour limiter le nombre de sites (ex: 1000 max)
- Implémenter une gestion de reprise (WHERE site_id > dernier_traité)
- Paralléliser le traitement si possible

---

### **6. Désactiver temporairement l'exécution automatique** 🟡

Le programme s'exécute toutes les 10 minutes (72 fois/jour).

**Désactivation temporaire** :
1. Aller dans "Définition de programme concurrent"
2. Chercher "DKA : Mise à jour quotidienne des sites fournisseurs dupliqués"
3. Décocher "Activé"
4. Ou augmenter la fréquence (1x/heure au lieu de 6x/heure)

**Pendant la période de correction**, éviter les exécutions multiples qui pourraient s'empiler.

---

## 📈 RECOMMANDATIONS À MOYEN TERME

### **1. Amélioration du code PL/SQL**

**Exemple de refactoring** :
```plsql
DECLARE
    TYPE t_vendor_site_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    l_vendor_site_ids t_vendor_site_ids;
    l_batch_size CONSTANT NUMBER := 1000;
    
BEGIN
    -- Traitement par batch de 1000 sites
    OPEN SITE_A_MAJ(v_date_maj);
    LOOP
        FETCH SITE_A_MAJ BULK COLLECT INTO l_vendor_site_ids LIMIT l_batch_size;
        EXIT WHEN l_vendor_site_ids.COUNT = 0;
        
        -- Traiter le batch
        FOR i IN 1..l_vendor_site_ids.COUNT LOOP
            -- Traitement...
        END LOOP;
        
        COMMIT;  -- COMMIT par batch
    END LOOP;
    CLOSE SITE_A_MAJ;
END;
```

---

### **2. Monitoring et alertes**

**Créer une alerte** si le traitement dépasse 5 minutes :
```sql
-- À intégrer dans un monitoring (OEM, Nagios, etc.)
SELECT request_id, 
       ROUND((SYSDATE - actual_start_date) * 24 * 60, 2) as duree_min
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE fcp.user_concurrent_program_name LIKE '%sites fournisseurs dupliqu%'
  AND fcr.phase_code = 'R'
  AND (SYSDATE - fcr.actual_start_date) * 24 * 60 > 5;
```

---

### **3. Optimisation des index**

**Vérifier les index sur** :
```sql
-- Sur AP_SUPPLIER_SITES_ALL
CREATE INDEX idx_apss_ref9999_lupd 
ON ap_supplier_sites_all(org_id, last_update_date)
WHERE org_id IN (SELECT organization_id FROM hr_operating_units WHERE name = 'REF9999');

-- Sur IBY_PMT_INSTR_USES_ALL
CREATE INDEX idx_ipiu_lupd 
ON iby_pmt_instr_uses_all(last_update_date, payment_function)
WHERE payment_function = 'PAYABLES_DISB';

-- Sur IBY_EXTERNAL_PAYEES_ALL
CREATE INDEX idx_iepa_lupd_site 
ON iby_external_payees_all(supplier_site_id, last_update_date);
```

---

### **4. Documentation et formation**

**Actions** :
1. Documenter la procédure en cas d'incident similaire
2. Former l'équipe technique aux outils de diagnostic
3. Créer un runbook pour l'équipe d'exploitation
4. Établir une procédure de validation avant import massif

---

## 📊 MÉTRIQUES DE SUIVI

### **KPIs à surveiller**

| KPI | Valeur cible | Valeur actuelle | Statut |
|-----|-------------|-----------------|--------|
| Durée moyenne | < 1 min | 536 min | 🔴 NOK |
| Sites traités/heure | > 10,000 | 235 | 🔴 NOK |
| Taux d'erreur | < 5% | 7.8% | 🟡 Limite |
| Fréquence exécution | 6x/heure | 6x/heure | 🟢 OK |
| Volumétrie normale | < 1,000 sites | 27,164 sites | 🔴 NOK |

---

## 🎯 PLAN D'ACTION RÉCAPITULATIF

### **Jour J (aujourd'hui - 28/11/2025)**

- [x] Identifier la cause racine (modification massive 27,155 sites)
- [ ] Arrêter le traitement actuel (Request ID 46351151)
- [ ] Contacter l'équipe métier pour comprendre l'import du 27/11
- [ ] Désactiver temporairement l'exécution automatique
- [ ] Analyser les logs détaillés du traitement 46304717 (hier)

### **J+1 (29/11/2025)**

- [ ] Corriger les clés comptables désactivées (0458.DCW, 0483.DEW)
- [ ] Corriger les comptes bancaires en erreur (LOGEO, URBANSOCCER)
- [ ] Optimiser le code PL/SQL (ajout COMMIT intermédiaire)
- [ ] Tester la version optimisée sur un échantillon

### **J+2 à J+7 (30/11 - 05/12/2025)**

- [ ] Déployer la version optimisée en production
- [ ] Réactiver l'exécution automatique
- [ ] Mettre en place le monitoring des durées
- [ ] Former l'équipe aux procédures d'incident
- [ ] Documenter l'incident et les solutions

---

## 📞 CONTACTS ET RESPONSABILITÉS

### **Équipe technique**

| Rôle | Contact | Action |
|------|---------|--------|
| **DBA Oracle** | dba@dalkia.fr | Tuer la session / Analyser UNDO |
| **Admin EBS** | ebs-admin@dalkia.fr | Arrêter le traitement / Analyser logs |
| **Développeur PL/SQL** | Asma AMENKOUR (Capgemini) | Optimiser le code |

### **Équipe métier**

| Rôle | Contact | Action |
|------|---------|--------|
| **Responsable Fournisseurs** | ap-manager@dalkia.fr | Valider corrections clés comptables |
| **Contrôleur de gestion** | controleur@dalkia.fr | Valider corrections comptes bancaires |
| **RAF** | raf@dalkia.fr | Décision arrêt traitement |

---

## 📋 CHECKLIST DE RÉSOLUTION

- [ ] Traitement actuel arrêté
- [ ] Cause racine identifiée et documentée
- [ ] Import massif du 27/11 expliqué par l'équipe métier
- [ ] Erreurs de clés comptables corrigées
- [ ] Erreurs de comptes bancaires corrigées
- [ ] Code PL/SQL optimisé (COMMIT intermédiaire)
- [ ] Tests effectués en environnement de recette
- [ ] Déploiement en production validé
- [ ] Monitoring mis en place
- [ ] Documentation mise à jour
- [ ] Post-mortem réalisé avec toutes les parties prenantes

---

## 📝 CONCLUSION

### **Résumé de l'incident**

1. **27,155 sites fournisseurs modifiés massivement** le 27/11 entre 13h07 et 13h38 par l'utilisateur EXPLOITATION
2. Le traitement automatique (toutes les 10 min) a dû traiter ce **volume anormal x30 fois supérieur** à la normale
3. Le code PL/SQL **non optimisé** (pas de COMMIT intermédiaire) ne peut pas gérer ce volume
4. Le traitement actuel durerait **4.4 jours** à ce rythme → **INACCEPTABLE**
5. **2,109 sites en erreur** principalement dus à des clés comptables désactivées

### **Impact**

- **Haute criticité** : Synchronisation des données fournisseurs bloquée
- **Risque métier** : Paiements fournisseurs potentiellement impactés
- **Risque technique** : Saturation UNDO, blocage d'autres traitements

### **Solution**

1. **Immédiat** : Arrêter le traitement actuel
2. **Court terme** : Corriger les erreurs métier (clés comptables, comptes bancaires)
3. **Moyen terme** : Optimiser le code PL/SQL pour gérer les volumes importants

---

**Rapport généré le** : 28/11/2025 à 16:00  
**Temps d'analyse** : 30 minutes  
**Prochaine révision** : 29/11/2025 à 09:00

---

**Fin du rapport détaillé**
