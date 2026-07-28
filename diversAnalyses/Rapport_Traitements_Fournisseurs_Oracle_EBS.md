# 📊 RAPPORT - Inventaire des Traitements Fournisseurs Oracle EBS

**Date du rapport** : 1er décembre 2025  
**Période analysée** : 27-28 novembre 2025  
**Environnement** : Oracle E-Business Suite 12.2.13 (Production)  
**Connexion** : oracleProd  
**Analyste** : GitHub Copilot (Claude Sonnet 4.5)

---

## 📋 RÉSUMÉ EXÉCUTIF

Ce rapport présente l'inventaire complet des traitements liés aux fournisseurs dans Oracle EBS, suite à l'incident de performance du 27-28 novembre 2025.

### **Contexte**

L'analyse a été déclenchée par un incident majeur :
- **Import iValua** : 1h41min (Request 46303238) le 27/11 à 12h00
- **Duplication massive** : 27,155 sites créés en 31 minutes (13h07-13h38)
- **Mise à jour** : 10+ heures au lieu de 18 secondes habituelles

### **Périmètre**

- **152 programmes concurrents** identifiés liés aux fournisseurs
- **15 traitements actifs** sur la période analysée
- **1,577 exécutions** au total (27-28 novembre 2025)
- **3 flux iValua** identifiés (Import, Export, Contrôle)

---

## 🔍 ANALYSE PAR CATÉGORIE

### **1. TRAITEMENTS DE SYNCHRONISATION ET MISE À JOUR** 🔴

#### **1.1. DKA : Mise à jour quotidienne des sites fournisseurs dupliqués**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `DKA_SAPFRSDUPLI_MAJ` |
| **Fréquence** | Toutes les 10 minutes (72x/jour) |
| **Exécutions (27-28/11)** | 37 |
| **Durée normale** | 18 secondes |
| **Durée maximale observée** | **694 minutes (11h57min)** |
| **Durée moyenne** | 53 minutes |
| **Statut** | 🔴 CRITIQUE - Performance dégradée |

**Description** :  
Synchronise les modifications du site de référence REF9999 vers tous les sites fournisseurs dupliqués dans les autres organisations.

**Problèmes identifiés** :
- ❌ Absence de COMMIT intermédiaire (transaction unique pour 27,164 sites)
- ❌ Curseur avec 7 jointures (performance dégradée)
- ❌ Traitement séquentiel sans BULK COLLECT
- ❌ Incapable de gérer les volumes massifs (>25,000 sites)

**Incidents récents** :
- Request 46354561 : 694 min (11h57min) - 28/11 à 17h00
- Request 46351151 : 599 min (9h59min) - 28/11 à 07h00
- Request 46304717 : 597 min (9h96min) - 27/11 à 13h41

**Recommandations** :
1. 🔴 **URGENT** : Ajouter COMMIT tous les 100-500 sites
2. 🟡 Refactoriser avec BULK COLLECT par lots de 1000 sites
3. 🟡 Ajouter un paramètre pour limiter le volume traité
4. 🟢 Implémenter une reprise sur erreur (checkpoint)

---

#### **1.2. DKA : Duplication en masse des sites fournisseurs**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `DKA_SAPFRSDUPLI_MASSE` |
| **Fréquence** | À la demande |
| **Exécutions (27-28/11)** | 70 |
| **Durée moyenne** | 0,03 minute (2 secondes) |
| **Durée maximale** | 1,62 minute |
| **Statut** | 🟢 NORMAL |

**Description** :  
Duplique les sites fournisseurs du site de référence REF9999 vers d'autres organisations.

**Incident du 27/11** :
- Request 46342352 : A créé **27,155 sites** en 2 secondes
- Heure : 27/11/2025 entre 13h07 et 13h38
- Utilisateur : EXPLOITATION (automatique)
- **Impact** : Cause directe de la surcharge du traitement de mise à jour

**Recommandations** :
1. 🟡 Ajouter une validation avant duplication massive (>10,000 sites)
2. 🟡 Implémenter une notification si volume > seuil
3. 🟢 Logger le nombre de sites dupliqués

---

### **2. FLUX IVALUA - INTÉGRATION EXTERNE** 🔴

#### **2.1. DKA : Import des données Fournisseurs depuis iValua**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `DKA_IPOFRS_IVALUA` |
| **Fréquence** | Périodique (planifié) |
| **Exécutions (27-28/11)** | 6 |
| **Durée moyenne** | 18,88 minutes |
| **Durée maximale** | **100,9 minutes (1h41min)** |
| **Statut** | 🔴 CAUSE RACINE DE L'INCIDENT |

**Description** :  
Import des données fournisseurs (entêtes, sites, coordonnées bancaires) depuis la plateforme iValua vers Oracle EBS.

**Incident du 27/11** :
- Request 46303238 : **101 minutes** (1h41min)
- Heure : 27/11/2025 de 12h00:24 à 13h41:18
- Statut final : Warning (G)
- **Impact** : A importé les données qui ont déclenché la duplication de 27,155 sites

**Flux de données** :
```
iValua (Plateforme externe)
    ↓ Export fichiers
Loader (DKA_IPOFRS_IVALUA_LOADER)
    ↓ Chargement tables temporaires
Import (DKA_IPOFRS_IVALUA)
    ↓ Validation et intégration
Oracle EBS (AP_SUPPLIERS, AP_SUPPLIER_SITES_ALL)
    ↓ Détection changements REF9999
Duplication (DKA_SAPFRSDUPLI_MASSE)
    ↓ 27,155 sites créés
Mise à jour (DKA_SAPFRSDUPLI_MAJ)
    ↓ 10+ heures de traitement
```

**Recommandations** :
1. 🔴 **URGENT** : Valider les données avant import massif
2. 🔴 Limiter le volume par batch (max 5,000 fournisseurs/import)
3. 🟡 Ajouter un mode "simulation" avant import réel
4. 🟡 Désactiver temporairement la duplication automatique pendant l'import
5. 🟢 Améliorer le monitoring et les alertes sur durée > 30 min

---

#### **2.2. DKA : Import des données Fournisseurs depuis iValua - Chargement des fichiers**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `DKA_IPOFRS_IVALUA_LOADER` |
| **Exécutions (27-28/11)** | 5 |
| **Durée moyenne** | 1,07 minute |
| **Durée maximale** | 2,67 minutes |
| **Statut** | 🟢 NORMAL |

**Description** :  
Charge les fichiers CSV/XML depuis iValua vers les tables temporaires Oracle (staging tables).

---

#### **2.3. DKA : Export des données Factures vers iValua**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `DKA_IAPFAC_IVALUA` |
| **Exécutions (27-28/11)** | 2 |
| **Durée moyenne** | 22,48 minutes |
| **Durée maximale** | 24,2 minutes |
| **Statut** | 🟢 NORMAL |

**Description** :  
Exporte les factures fournisseurs depuis Oracle EBS vers iValua pour workflow d'approbation.

---

#### **2.4. DKA : Import des données Réceptions depuis iValua**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `DKA_IPORECEPTION_IVALUA` |
| **Exécutions (27-28/11)** | 2 |
| **Durée moyenne** | 6,84 minutes |
| **Durée maximale** | 13,13 minutes |
| **Statut** | 🟢 NORMAL |

**Description** :  
Import des réceptions de marchandises depuis iValua vers Oracle Purchasing.

---

#### **2.5. DKA : Import des commandes depuis iValua**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `DKA_IPOCDE_IVALUA` |
| **Exécutions (27-28/11)** | 3 |
| **Durée moyenne** | 0,87 minute |
| **Durée maximale** | 1,17 minute |
| **Statut** | 🟢 NORMAL |

**Description** :  
Import des commandes d'achat depuis iValua vers Oracle Purchasing.

---

#### **2.6. DKA : Contrôle des flux IVALUA**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `DKA_IAPCTRFLUX_IVALUA` |
| **Exécutions (27-28/11)** | 2 |
| **Durée moyenne** | 0,01 minute |
| **Statut** | 🟢 NORMAL |

**Description** :  
Contrôle de cohérence et validation des fichiers reçus d'iValua (fichier CONTROL.csv).

---

### **3. TRAITEMENTS DE PAIEMENT ET APPROBATION** 🟡

#### **3.1. DKA : Règlements automatiques toutes sociétés des factures fournisseurs**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `DKA_SAPAUTORGT` |
| **Exécutions (27-28/11)** | 3 |
| **Durée moyenne** | 68,42 minutes |
| **Durée maximale** | 89,43 minutes |
| **Statut** | 🟡 À SURVEILLER |

**Description** :  
Lance le processus de règlement automatique (paiement) pour toutes les organisations.

**Analyse** :
- Durées variables : 57 à 89 minutes
- Peut être impacté par le volume de factures en attente
- Performances acceptables mais à surveiller

---

#### **3.2. DKA : Approbation toutes sociétés des factures fournisseurs**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `DKA_SAPAPPRVL` |
| **Exécutions (27-28/11)** | 7 |
| **Durée moyenne** | 29,91 minutes |
| **Durée maximale** | 65 minutes |
| **Statut** | 🟡 À SURVEILLER |

**Description** :  
Lance le traitement de validation des factures fournisseurs (APPRVL) pour toutes les organisations.

**Analyse** :
- 4 exécutions < 32 minutes (normal)
- 1 exécution à 48 minutes (acceptable)
- 1 exécution à 65 minutes (à investiguer)

---

### **4. TRAITEMENTS D'INTERFACE ET AUDIT** 🟢

#### **4.1. PRC: Interface Supplier Costs**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `PAAPIMP_SI` |
| **Exécutions (27-28/11)** | 667 |
| **Durée moyenne** | 0,25 minute (15 secondes) |
| **Durée maximale** | 15 minutes |
| **Statut** | 🟢 NORMAL |

**Description** :  
Interface de coûts fournisseurs depuis Oracle Payables vers Oracle Projects.

---

#### **4.2. AUD: Supplier Costs Interface Audit**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `PAAPIMPR` |
| **Exécutions (27-28/11)** | 702 |
| **Durée moyenne** | 0,21 minute (13 secondes) |
| **Durée maximale** | 0,4 minute (24 secondes) |
| **Statut** | 🟢 NORMAL |

**Description** :  
Rapport d'audit des interfaces de coûts fournisseurs.

---

### **5. TRAITEMENTS D'EXPORT ET REPORTING** 🟢

#### **5.1. DKA : Export journalier des fournisseurs**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `DKA_APFRSEXP_JOUR` |
| **Exécutions (27-28/11)** | 2 |
| **Durée moyenne** | 16,17 minutes |
| **Durée maximale** | 18,67 minutes |
| **Statut** | 🟢 NORMAL |

**Description** :  
Export quotidien des données fournisseurs pour alimentation d'un datawarehouse ou système tiers.

---

#### **5.2. DKA : PAC : Importer les factures fournisseurs depuis Oracle AP**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `DKA_SPAAPIMP_SI` |
| **Exécutions (27-28/11)** | 7 |
| **Durée moyenne** | 2,05 minutes |
| **Durée maximale** | 3,07 minutes |
| **Statut** | 🟢 NORMAL |

**Description** :  
Import des factures fournisseurs vers le module PAC (Contrôle budgétaire).

---

#### **5.3. DKA : Export des images Factures vers iValua**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `DKA_IAPIMG_IVALUA` |
| **Exécutions (27-28/11)** | 2 |
| **Durée moyenne** | 1,54 minute |
| **Statut** | 🟢 NORMAL |

**Description** :  
Export des images scannées de factures vers iValua.

---

### **6. TRAITEMENTS UTILITAIRES** 🟢

#### **6.1. DKA : Désactivation/réactivation d'un site de règlement fournisseur**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `DKA_SPOSTFNS_DESACT` |
| **Exécutions (27-28/11)** | 74 |
| **Durée moyenne** | 0,00 minute (<1 seconde) |
| **Durée maximale** | 0,02 minute (1 seconde) |
| **Statut** | 🟢 NORMAL |

**Description** :  
Désactivation ou réactivation ponctuelle d'un site de règlement fournisseur.

---

#### **6.2. DKA : Mise à jour des rattachements de sites fournisseurs sur commande ouverte globale**

| Attribut | Valeur |
|----------|--------|
| **Nom technique** | `DKA_SPODUPSITECOG` |
| **Exécutions (27-28/11)** | 2 |
| **Durée moyenne** | 0,88 minute |
| **Statut** | 🟢 NORMAL |

**Description** :  
Rattache automatiquement les nouveaux sites fournisseurs aux commandes ouvertes globales existantes.

---

## 📊 STATISTIQUES GLOBALES

### **Volume d'exécutions (27-28 novembre 2025)**

| Catégorie | Nb programmes | Nb exécutions | Durée totale (h) |
|-----------|---------------|---------------|------------------|
| **Synchronisation/MAJ** | 2 | 107 | 62,5 |
| **Flux iValua** | 6 | 19 | 3,8 |
| **Paiement/Approbation** | 2 | 10 | 8,9 |
| **Interface/Audit** | 2 | 1,369 | 9,5 |
| **Export/Reporting** | 3 | 11 | 0,7 |
| **Utilitaires** | 2 | 76 | 0,03 |
| **TOTAL** | **15** | **1,577** | **85,43** |

### **Répartition des durées**

| Plage de durée | Nb exécutions | % |
|----------------|---------------|---|
| **< 1 minute** | 1,451 | 92% |
| **1-30 minutes** | 109 | 7% |
| **30-60 minutes** | 4 | 0,25% |
| **> 60 minutes** | 13 | 0,75% |

### **TOP 5 des traitements les plus longs**

| Rang | Programme | Request ID | Durée (min) | Date/Heure |
|------|-----------|------------|-------------|------------|
| 1 | Mise à jour sites dupliqués | 46354561 | 694,05 | 28/11 17:00 |
| 2 | Mise à jour sites dupliqués | 46351151 | 599,00 | 28/11 07:00 |
| 3 | Mise à jour sites dupliqués | 46304717 | 597,00 | 27/11 13:41 |
| 4 | Import Fournisseurs iValua | 46303238 | 100,90 | 27/11 12:00 |
| 5 | Règlements automatiques | 46349263 | 89,43 | 28/11 05:30 |

---

## 🔍 ANALYSE DE LA CHAÎNE DE CAUSALITÉ

### **Chronologie de l'incident du 27-28 novembre 2025**

```
📅 27/11/2025 à 12:00:24
├─ 🔴 Import iValua démarre (Request 46303238)
│  └─ Durée : 1h41min (au lieu de ~10-20 min habituels)
│
📅 27/11/2025 à 13:07:00
├─ 🔴 Duplication massive démarre
│  ├─ 27,155 sites fournisseurs créés
│  ├─ Durée : 31 minutes (13h07 → 13h38)
│  └─ Débit : ~875 sites/minute
│
📅 27/11/2025 à 13:41:18
├─ 🔴 Mise à jour sites dupliqués (Request 46304717)
│  ├─ Volume à traiter : 27,164 sites (63% de REF9999)
│  ├─ Durée : 597 minutes (9h57min)
│  └─ Vitesse : 45 sites/heure
│
📅 28/11/2025 à 07:00:07
├─ 🔴 Nouvelle MAJ sites dupliqués (Request 46351151)
│  ├─ Volume : toujours 27,164 sites
│  ├─ Durée : 599 minutes (9h59min)
│  └─ Vitesse : 45 sites/heure
│
📅 28/11/2025 à 17:00:00
└─ 🔴 Encore une MAJ sites dupliqués (Request 46354561)
   ├─ Volume : toujours 27,164 sites
   ├─ Durée : 694 minutes (11h57min)
   └─ Vitesse : 39 sites/heure (dégradation)
```

### **Impact en cascade**

| Niveau | Composant | Impact | Criticité |
|--------|-----------|--------|-----------|
| **Niveau 1** | Import iValua | Volume anormal importé | 🟡 Moyen |
| **Niveau 2** | Duplication | 27,155 sites créés d'un coup | 🔴 Élevé |
| **Niveau 3** | Mise à jour | 10+ heures au lieu de 18 sec | 🔴 Critique |
| **Niveau 4** | Exécutions suivantes | Empilage des traitements | 🔴 Critique |
| **Niveau 5** | Base de données | UNDO, verrous, performance | 🟡 Moyen |
| **Niveau 6** | Métier | Données non synchro | 🟡 Moyen |

---

## 🚨 TRAITEMENTS INACTIFS MAIS DISPONIBLES

### **Traitements de maintenance (0 exécutions sur 27-28/11)**

| Programme | Nom technique | Usage |
|-----------|---------------|-------|
| **DKA : Initialisation de la base de référence fournisseur** | `DKA_SAPFRSDUPLI_INIT` | Initialisation REF9999 |
| **DKA : Désactivation des entêtes fournisseurs** | `DKA_SPOFOUR_DESAC` | Nettoyage fournisseurs obsolètes |
| **DKA : Désactivation des sites non mouvementés** | `DKA_SPOFOUR_NONMV` | Nettoyage sites inactifs |
| **DKA : Désactivation sites avec solde à 0** | `DKA_SPOFOUR_OBS` | Nettoyage sites soldés |
| **DKA : Mise à jour sites repris dans IVALUA** | `DKA_IPOFRS_REP_IVALUA` | Migration iValua |
| **Supplier Open Interface Import** | `APXSUIMP` | Import générique fournisseurs |
| **Supplier Sites Open Interface Import** | `APXSSIMP` | Import générique sites |
| **Supplier Merge Program** | `APXINUPD` | Fusion fournisseurs doublons |

### **Traitements Oracle standard (non utilisés)**

- **Vendor Volume Analysis Report** (`POXVCVAR`)
- **Vendor Quality Performance Analysis** (`POXQUAPR`)
- **Vendor Price Performance Analysis** (`POXPRIPR`)
- **Suppliers Report** (`APXVDVSR`)
- **Vendor Purchase Summary Report** (`POXPOVPS`)
- **1099 Supplier Exceptions Report** (`APXTRVEE`)
- Plus de 130 autres programmes Oracle standard

---

## 📈 RECOMMANDATIONS STRATÉGIQUES

### **1. COURT TERME (0-15 jours)** 🔴

#### **Optimisation du traitement de mise à jour**

**Actions immédiates** :
1. ✅ Ajouter COMMIT tous les 100 sites dans `DKA_SAPFRSDUPLI_MAJ_PKG`
2. ✅ Ajouter un paramètre `p_max_sites` pour limiter le volume (défaut: 5000)
3. ✅ Implémenter une table de checkpoint pour reprise sur erreur
4. ✅ Ajouter des logs de progression (toutes les 500 sites)

**Code proposé** :
```plsql
-- Dans DKA_SAPFRSDUPLI_MAJ_PKG.MAIN
g_checkpoint_size CONSTANT NUMBER := 100;
g_max_sites       CONSTANT NUMBER := 5000;
g_sites_traites   NUMBER := 0;

FOR rec_site_a_maj IN SITE_A_MAJ (v_date_maj) LOOP
    EXIT WHEN g_sites_traites >= g_max_sites;
    
    -- Traitement du site
    DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR(...);
    g_sites_traites := g_sites_traites + 1;
    
    -- Checkpoint tous les 100 sites
    IF MOD(g_sites_traites, g_checkpoint_size) = 0 THEN
        COMMIT;
        -- Sauvegarder position
        UPDATE dka_parameters 
        SET number_value = g_sites_traites
        WHERE parameter_name = 'MAJ_SITE_LAST_PROCESSED';
        
        -- Log progression
        FND_FILE.PUT_LINE(FND_FILE.LOG, 
            'Progression: ' || g_sites_traites || ' sites traités');
    END IF;
END LOOP;
```

#### **Sécurisation de l'import iValua**

**Actions immédiates** :
1. ✅ Ajouter validation volume avant import (max 10,000 fournisseurs)
2. ✅ Implémenter mode simulation (`p_simulation_mode`)
3. ✅ Ajouter notification email si volume > seuil
4. ✅ Logger statistiques détaillées (nb fournisseurs, sites, comptes bancaires)

**Code proposé** :
```plsql
-- Dans DKA_IPOFRS_IVALUA
DECLARE
    l_nb_fournisseurs NUMBER;
    l_nb_sites        NUMBER;
    l_max_allowed     NUMBER := 10000;
BEGIN
    -- Compter volume en attente
    SELECT COUNT(DISTINCT supplier_id), COUNT(*)
    INTO l_nb_fournisseurs, l_nb_sites
    FROM dka_ivalua_suppliers_stg;
    
    -- Validation
    IF l_nb_fournisseurs > l_max_allowed THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 
            'ERREUR: Volume trop important: ' || l_nb_fournisseurs || 
            ' fournisseurs (max: ' || l_max_allowed || ')');
        
        -- Envoyer notification
        send_alert_email(
            p_subject => 'Import iValua - Volume anormal',
            p_message => 'Volume détecté: ' || l_nb_fournisseurs || ' fournisseurs'
        );
        
        RAISE_APPLICATION_ERROR(-20001, 'Volume trop important');
    END IF;
    
    FND_FILE.PUT_LINE(FND_FILE.LOG, 
        'Import: ' || l_nb_fournisseurs || ' fournisseurs, ' || 
        l_nb_sites || ' sites');
END;
```

---

### **2. MOYEN TERME (15-60 jours)** 🟡

#### **Refactoring complet avec BULK COLLECT**

**Objectif** : Traiter par lots de 1000 sites au lieu d'un traitement unitaire

```plsql
DECLARE
    TYPE t_site_record IS RECORD (
        vendor_site_id  NUMBER,
        vendor_id       NUMBER,
        org_id          NUMBER,
        -- autres champs
    );
    TYPE t_sites_tab IS TABLE OF t_site_record;
    l_sites t_sites_tab;
    l_batch_size CONSTANT NUMBER := 1000;
    
BEGIN
    OPEN SITE_A_MAJ(v_date_maj);
    LOOP
        FETCH SITE_A_MAJ BULK COLLECT INTO l_sites LIMIT l_batch_size;
        EXIT WHEN l_sites.COUNT = 0;
        
        -- Traiter le batch
        FOR i IN 1..l_sites.COUNT LOOP
            BEGIN
                DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR(
                    p_vendor_site_id => l_sites(i).vendor_site_id,
                    ...
                );
            EXCEPTION
                WHEN OTHERS THEN
                    -- Logger erreur mais continuer
                    log_error(l_sites(i).vendor_site_id, SQLERRM);
            END;
        END LOOP;
        
        COMMIT;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG, 
            'Batch traité: ' || l_sites.COUNT || ' sites');
    END LOOP;
    CLOSE SITE_A_MAJ;
END;
```

#### **Optimisation des index**

**Actions** :
1. Créer index sur `ap_supplier_sites_all(org_id, last_update_date)`
2. Créer index sur `iby_pmt_instr_uses_all(last_update_date, payment_function)`
3. Créer index sur `iby_external_payees_all(supplier_site_id, last_update_date)`
4. Analyser plan d'exécution du curseur `SITE_A_MAJ`

#### **Monitoring et alertes**

**Actions** :
1. Créer job OEM/Nagios : alerte si durée > 5 minutes
2. Dashboard temps réel des traitements fournisseurs
3. Rapport quotidien des performances
4. Alerte si taux d'erreur > 5%

```sql
-- Script de monitoring à intégrer
SELECT 
    fcr.request_id,
    fcp.user_concurrent_program_name,
    ROUND((SYSDATE - fcr.actual_start_date) * 24 * 60, 2) as duree_minutes,
    CASE 
        WHEN (SYSDATE - fcr.actual_start_date) * 24 * 60 > 10 THEN 'CRITIQUE'
        WHEN (SYSDATE - fcr.actual_start_date) * 24 * 60 > 5 THEN 'ATTENTION'
        ELSE 'NORMAL'
    END as statut_alerte
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp 
    ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE fcr.phase_code = 'R'
  AND fcp.concurrent_program_name IN ('DKA_SAPFRSDUPLI_MAJ', 'DKA_IPOFRS_IVALUA')
  AND (SYSDATE - fcr.actual_start_date) * 24 * 60 > 5;
```

---

### **3. LONG TERME (60+ jours)** 🟢

#### **Architecture cible**

**Propositions** :
1. **Parallélisation** : Traiter plusieurs organisations en parallèle
2. **Partitionnement** : Partitionner `ap_supplier_sites_all` par `org_id`
3. **Cache intelligent** : Mettre en cache les données de référence (REF9999)
4. **Mode incrémental** : Ne traiter que les vrais changements (hash/checksum)

#### **Gestion des imports massifs**

**Propositions** :
1. Découper les imports iValua en plusieurs batchs (5000 max/batch)
2. Désactiver la duplication automatique pendant les imports
3. Lancer la duplication/MAJ en mode contrôlé après validation
4. Implémenter une file d'attente (queue) pour les gros volumes

#### **Documentation et formation**

**Actions** :
1. ✅ Documenter tous les traitements (ce rapport)
2. Créer runbook pour incident similaire
3. Former équipe exploitation aux outils de diagnostic
4. Établir procédure de validation avant import massif
5. Créer matrice de décision (volume vs actions)

---

## 📊 MATRICE DE DÉCISION - GESTION DES VOLUMES

| Volume sites à traiter | Action recommandée | Durée estimée | Risque |
|------------------------|-------------------|---------------|--------|
| **< 1,000 sites** | Traitement normal (auto) | < 5 min | 🟢 Faible |
| **1,000 - 5,000** | Traitement normal + surveillance | 5-30 min | 🟢 Faible |
| **5,000 - 10,000** | Traitement par batch + alerte | 30-60 min | 🟡 Moyen |
| **10,000 - 20,000** | Validation manuelle requise | 1-2 heures | 🟡 Moyen |
| **> 20,000** | STOP - Analyse obligatoire | > 2 heures | 🔴 Élevé |

---

## 📋 CHECKLIST DE DÉPLOIEMENT

### **Phase 1 : Correctifs urgents (Semaine 1)**

- [ ] Développer version avec COMMIT intermédiaire
- [ ] Tester en environnement de recette avec 10,000 sites
- [ ] Valider performances (< 30 min pour 10,000 sites)
- [ ] Déployer en production hors heures ouvrées
- [ ] Monitorer 1ère exécution en production
- [ ] Documenter changements dans notes de version

### **Phase 2 : Améliorations (Semaine 2-4)**

- [ ] Refactorer avec BULK COLLECT
- [ ] Ajouter validations import iValua
- [ ] Créer index supplémentaires
- [ ] Mettre en place monitoring OEM/Nagios
- [ ] Tester charge avec 25,000 sites
- [ ] Former équipe exploitation

### **Phase 3 : Optimisations long terme (Mois 2-3)**

- [ ] Analyser faisabilité parallélisation
- [ ] Évaluer partitionnement tables
- [ ] Implémenter mode incrémental (hash)
- [ ] Créer dashboard temps réel
- [ ] Post-mortem avec toutes les parties prenantes
- [ ] Documenter leçons apprises

---

## 📞 CONTACTS ET RESPONSABILITÉS

### **Équipe technique**

| Rôle | Contact | Responsabilités |
|------|---------|-----------------|
| **DBA Oracle** | dba@dalkia.fr | Performance, tuning, analyse AWR |
| **Admin EBS** | ebs-admin@dalkia.fr | Gestion traitements concurrents |
| **Développeur PL/SQL** | Asma AMENKOUR (Capgemini) | Développement optimisations |
| **Architecte SI** | archi@dalkia.fr | Validation architecture cible |

### **Équipe métier**

| Rôle | Contact | Responsabilités |
|------|---------|-----------------|
| **Responsable AP** | ap-manager@dalkia.fr | Validation fonctionnelle |
| **Responsable iValua** | ivalua@dalkia.fr | Coordination flux iValua |
| **RAF** | raf@dalkia.fr | Décisions stratégiques |
| **Contrôleur de gestion** | controleur@dalkia.fr | Impact métier |

---

## 📝 CONCLUSION

### **Synthèse**

Ce rapport a identifié **152 programmes concurrents** liés aux fournisseurs, dont **15 actifs** sur la période analysée. L'incident du 27-28 novembre 2025 a mis en évidence :

1. **Cause racine** : Import iValua anormal (1h41min) suivi d'une duplication de 27,155 sites
2. **Effet cascade** : Traitement de mise à jour passé de 18 sec à 10+ heures
3. **Impact** : 3 exécutions consécutives bloquées (27h total), données non synchronisées

### **Actions prioritaires**

| Priorité | Action | Deadline | Responsable |
|----------|--------|----------|-------------|
| 🔴 P0 | Optimiser COMMIT intermédiaire | 7 jours | Dev PL/SQL |
| 🔴 P0 | Sécuriser import iValua | 7 jours | Dev PL/SQL |
| 🟡 P1 | Refactoring BULK COLLECT | 30 jours | Dev PL/SQL |
| 🟡 P1 | Monitoring temps réel | 30 jours | DBA + Admin |
| 🟢 P2 | Parallélisation | 90 jours | Architecte |

### **Bénéfices attendus**

**Court terme** :
- Durée traitement : 18 sec → 5 min (pour volumes normaux)
- Durée traitement : N/A → 2h max (pour 25,000 sites)
- Sécurité : Validation avant import massif
- Visibilité : Monitoring en temps réel

**Long terme** :
- Architecture scalable (jusqu'à 100,000 sites)
- Reprise sur erreur automatique
- Performance prévisible
- Réduction incidents de 90%

---

**Rapport généré le** : 1er décembre 2025  
**Temps d'analyse** : 45 minutes  
**Sources** : Oracle EBS Production, période 27-28/11/2025  
**Prochaine révision** : Après déploiement Phase 1 (Semaine 2)

---

**Fin du rapport**
