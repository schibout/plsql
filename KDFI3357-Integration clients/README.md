# KDFI3357 - Intégration Clients depuis SIC/IFS vers Oracle AR

**Date de création** : 10/12/2025  
**Module Oracle EBS** : Receivables (AR)  
**Interface** : SIC/IFS → Oracle AR  
**Statut** : ⚠️ **ERREURS D'INTÉGRATION DÉTECTÉES**

---

## 📋 Vue d'Ensemble

Ce dossier documente l'interface d'intégration des clients depuis le système **SIC/IFS** (Système d'Information Client / IFS) vers le module **Oracle Receivables (AR)** de l'EBS.

### Contexte Business
- **Système source** : SIC/IFS (gestion clients centralisée)
- **Système cible** : Oracle EBS R12 Receivables
- **Fréquence** : Exécution quotidienne (~17h00)
- **Volume** : Traitement de centaines de clients et adresses

---

## 🔴 Problème Actuel

### Dernière Exécution (09/12/2025)
**Request ID** : 46454809  
**Période** : 09/12/2025 17:01:03 - 17:46:06  
**Statut** : ⚠️ **Warning / Completed Normal**

### Statistiques d'Erreurs
```
┌─────────────────────────────────────────────────────┐
│ ERREURS D'INTÉGRATION - REQUEST 46454809            │
├─────────────────────────────────────────────────────┤
│ Clients/Adresses Rejetés : 5,330                    │
│ Collectors Rejetés       : 319                      │
│ TOTAL ERREURS           : 5,649                     │
└─────────────────────────────────────────────────────┘
```

### Répartition des Erreurs par Type

| Type d'Erreur | Nombre | % | Description |
|---------------|--------|---|-------------|
| **DOUBLON_CODE_ANAEL** | 3,203 | 60% | Code ANAEL présent sur un autre client |
| **ERREUR_COMPTABLE** | 1,433 | 27% | Calcul des clés comptables impossible (GET_GL_ID) |
| **PAS_DE_COLLECTOR** | 649 | 12% | Agents de recouvrement manquants |
| **NUMERO_ANAEL_INVALIDE** | 1 | <1% | Format du code ANAEL invalide |
| **Collectors rejetés** | 319 | - | Numéro client inconnu (164) / Collector inactif (153) |

---

## 📁 Structure du Dossier

```
KDFI3357-Integration clients/
│
├── README.md                    ⭐ Ce fichier (vue d'ensemble)
└── README_IFS_AR.md            ⭐⭐⭐ Documentation technique complète
```

---

## 🔍 Analyse Détaillée des Erreurs

### 1. Doublons Code ANAEL (3,203 erreurs - 60%)

**Problème** : Un même code ANAEL est assigné à plusieurs clients/établissements.

**Clients les plus impactés** :
- **ALEFPA** (00000082) : 41+ adresses rejetées
- **LAMY** (00001693) : 35+ adresses rejetées  
- **SOCIETE GENERALE** (00000724) : 11 adresses
- **CROIX ROUGE FRANCAISE** (00002918) : 24 adresses
- **AFEJI HAUTS DE FRANCE** (00002609) : 21 adresses

**Action requise** :
1. Vérifier dans SIC/IFS le lien établissement/client
2. S'assurer qu'un code ANAEL = 1 seul client
3. Corriger les duplications à la source

### 2. Erreurs Comptables (1,433 erreurs - 27%)

**Message** : `"Calcul des cles comptables impossible GET_GL_ID"`

**Causes possibles** :
- CDG (Centre de Gestion) invalide ou inexistant
- SOC (Société) invalide ou inexistant
- Paramétrage manquant dans les tables :
  - `DKA_ICLIENTS_CLESCO` (correspondance CDG/SOC → Compte GL)
  - `DKA_ICLIENTS_CDG` (liste des CDG valides)

**Action requise** :
1. Vérifier les paramètres comptables dans les tables DKA
2. S'assurer que tous les CDG/SOC existent dans le référentiel
3. Compléter les mappings manquants

### 3. Collectors Manquants (649 erreurs - 12%)

**Message** : `"Il n'a pas de collectors pour ce client"`

**Exemples de clients concernés** :
- **Communes** : SAINT JEAN DE BRAYE, BLENDECQUES, THIANT
- **Établissements publics** : CROUS, universités, hôpitaux
- **Entreprises** : AIR LIQUIDE, AXEREAL ELEVAGE, REGUS PARIS

**Action requise** :
1. Compléter la table `DKA_ICLIENTIFS_COLLECTORS` depuis SIC/IFS
2. Assigner des agents de recouvrement (collectors) à chaque client
3. Vérifier les règles d'affectation par CDG

### 4. Collectors Rejetés (319 erreurs)

**Répartition** :
- **164 erreurs** : `"Numero de client inconnu"`
- **153 erreurs** : `"Collector inconnu ou inactif"`
- **2 erreurs** : Autres

**Action requise** :
1. Synchroniser les numéros clients entre SIC/IFS et Oracle
2. Vérifier le statut des collectors dans Oracle (actif/inactif)
3. Mettre à jour les données de référence

---

## 🏗️ Architecture de l'Interface

### Flux de Données
```
┌─────────────┐      ┌──────────────────┐      ┌─────────────────┐
│  SIC/IFS    │─────>│ Tables Interface │─────>│   Oracle AR     │
│  (Source)   │      │  DKA_ICLIENTIFS  │      │  (RA_CUSTOMERS) │
└─────────────┘      └──────────────────┘      └─────────────────┘
                              │
                              │ Erreurs
                              ▼
                     ┌──────────────────┐
                     │  DKA_ICLIENTIFS  │
                     │   _INTERFACE     │
                     │ (OA_STATUS='R')  │
                     └──────────────────┘
```

### Tables Clés

| Table | Owner | Description |
|-------|-------|-------------|
| `DKA_ICLIENTIFS_INTERFACE` | DKA | Staging pour clients/adresses (32 colonnes) |
| `DKA_ICLIENTIFS_COLLECTORS` | DKA | Agents de recouvrement par client/CDG |
| `RA_CUSTOMERS_INTERFACE_ALL` | AR | Interface standard Oracle pour clients |
| `RA_CUSTOMER_INTERFACE_ALL` | AR | Interface standard Oracle (ancienne) |
| `RA_CUSTOMERS` | AR | Table finale des clients Oracle |

### Programmes Concurrents

| Programme | Phase | Description |
|-----------|-------|-------------|
| `DKA_ICLIENTIFS_1` | Pre-OI | Préparation des données |
| `DKA_ICLIENTIFS_2` | Post-OI | Post-traitement |
| `DKA_ICLIENTIFS_3` | OI | Import Oracle standard |

---

## 📊 Statuts des Enregistrements

### Champ `OA_STATUS` dans DKA_ICLIENTIFS_INTERFACE

| Code | Signification | Description |
|------|---------------|-------------|
| **P** | Pending | En attente de traitement |
| **A** | Accepted | Accepté et intégré avec succès |
| **E** | Error | Erreur technique |
| **R** | Rejected | **Rejeté (règles métier)** ⚠️ |

**Note** : Les 5,330 enregistrements en erreur ont `OA_STATUS = 'R'`.

---

## 🔎 Requêtes SQL Utiles

### 1. Lister les Erreurs par Type
```sql
SELECT 
    CASE 
        WHEN error_message LIKE '%Code ANAEL présent sur un autre client%' THEN 'DOUBLON_CODE_ANAEL'
        WHEN error_message LIKE '%GET_GL_ID%' THEN 'ERREUR_COMPTABLE'
        WHEN error_message LIKE '%collectors%' THEN 'PAS_DE_COLLECTOR'
        ELSE 'AUTRE'
    END as type_erreur,
    COUNT(*) as nombre,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as pourcentage
FROM DKA.DKA_ICLIENTIFS_INTERFACE
WHERE oa_status = 'R'
  AND oa_request_id = 46454809
GROUP BY 
    CASE 
        WHEN error_message LIKE '%Code ANAEL présent sur un autre client%' THEN 'DOUBLON_CODE_ANAEL'
        WHEN error_message LIKE '%GET_GL_ID%' THEN 'ERREUR_COMPTABLE'
        WHEN error_message LIKE '%collectors%' THEN 'PAS_DE_COLLECTOR'
        ELSE 'AUTRE'
    END
ORDER BY nombre DESC;
```

### 2. Top 10 des Clients avec le Plus d'Erreurs
```sql
SELECT 
    customer_number,
    customer_name,
    COUNT(*) as nb_adresses_rejetees,
    MIN(error_message) as exemple_erreur
FROM DKA.DKA_ICLIENTIFS_INTERFACE
WHERE oa_status = 'R'
  AND oa_request_id = 46454809
GROUP BY customer_number, customer_name
ORDER BY COUNT(*) DESC
FETCH FIRST 10 ROWS ONLY;
```

### 3. Vérifier l'Historique d'un Client
```sql
SELECT 
    customer_number,
    customer_name,
    ref_address,
    oa_status,
    error_message,
    TO_CHAR(timestamp, 'DD/MM/YYYY HH24:MI') as date_erreur,
    oa_request_id
FROM DKA.DKA_ICLIENTIFS_INTERFACE
WHERE customer_number = '00000082'  -- Exemple : ALEFPA
  AND oa_status = 'R'
ORDER BY timestamp DESC;
```

### 4. Dernière Exécution du Programme
```sql
SELECT 
    request_id,
    TO_CHAR(actual_start_date, 'DD/MM/YYYY HH24:MI:SS') as debut,
    TO_CHAR(actual_completion_date, 'DD/MM/YYYY HH24:MI:SS') as fin,
    ROUND((actual_completion_date - actual_start_date) * 24 * 60, 1) as duree_minutes,
    phase_code,
    status_code
FROM fnd_concurrent_requests
WHERE concurrent_program_id IN (
    SELECT concurrent_program_id
    FROM fnd_concurrent_programs_vl
    WHERE concurrent_program_name LIKE 'DKA_ICLIENTIFS%'
)
ORDER BY request_id DESC
FETCH FIRST 3 ROWS ONLY;
```

---

## 📝 Règles de Gestion (Extraits)

### RG1 - Code ANAEL Unique
> Un code ANAEL ne peut être associé qu'à un seul client dans Oracle AR.

### RG5 - Clés Comptables Obligatoires
> Tout client doit avoir un CDG et une SOC valides pour générer ses clés comptables (compte 411xxx).

### RG12 - Collectors Obligatoires
> Chaque client doit avoir au moins un collector assigné pour la gestion du recouvrement.

**📄 Documentation complète** : `README_IFS_AR.md` (30 règles documentées)

---

## 🛠️ Plan de Remédiation

### Phase 1 : Correction des Doublons ANAEL (Priorité 1)
- [ ] Extraire la liste complète des codes ANAEL en doublon
- [ ] Identifier le client légitime pour chaque code
- [ ] Corriger dans SIC/IFS
- [ ] Ré-exécuter l'interface

### Phase 2 : Paramétrage Comptable (Priorité 2)
- [ ] Auditer les tables `DKA_ICLIENTS_CLESCO` et `DKA_ICLIENTS_CDG`
- [ ] Compléter les mappings CDG/SOC → Comptes GL manquants
- [ ] Valider avec la comptabilité

### Phase 3 : Affectation Collectors (Priorité 3)
- [ ] Définir les règles d'affectation par CDG
- [ ] Alimenter `DKA_ICLIENTIFS_COLLECTORS` depuis SIC/IFS
- [ ] Vérifier les collectors actifs dans Oracle

### Phase 4 : Monitoring Continu
- [ ] Mettre en place des alertes sur les erreurs d'intégration
- [ ] Dashboard des KPI d'intégration (taux de succès, types d'erreurs)
- [ ] Documentation des erreurs récurrentes

---

## 📚 Documentation de Référence

| Document | Description |
|----------|-------------|
| **README_IFS_AR.md** | Documentation technique complète (architecture, tables, règles) |
| `DKA_ICLIENTIFS_PKG` | Package PL/SQL de traitement de l'interface |
| Oracle Doc : Customer Interface | Documentation Oracle standard pour RA_CUSTOMERS_INTERFACE |

---

## 📞 Contacts

| Rôle | Responsable | Système |
|------|-------------|---------|
| **Admin SIC/IFS** | Équipe Source | Correction des données ANAEL, collectors |
| **Admin Oracle AR** | DBA Oracle | Paramétrage comptable, tables DKA |
| **Support Utilisateurs** | Équipe Métier | Validation règles de gestion |

---

## 📈 Indicateurs Clés (KPI)

### Dernière Exécution (09/12/2025)
```
Taux de succès         : N/A (données incomplètes)
Enregistrements traités : 5,649+ (dont 5,649 rejetés)
Durée d'exécution      : 45 minutes (17:01 - 17:46)
Statut final           : Warning / Completed Normal
```

### Objectifs Cibles
```
Taux de succès cible   : > 95%
Erreurs acceptables    : < 5% (erreurs métier légitimes)
Temps d'exécution max  : < 1 heure
Fréquence exécution    : Quotidienne (17h00)
```

---

## 🚀 Prochaines Étapes

1. **Analyse approfondie** des 3,203 doublons ANAEL
2. **Réunion de cadrage** avec les équipes SIC/IFS et Oracle AR
3. **Correction prioritaire** : Top 10 clients (ALEFPA, LAMY, etc.)
4. **Test de l'interface** après corrections sur environnement de développement
5. **Déploiement en production** avec monitoring renforcé

---

**Dernière mise à jour** : 10/12/2025  
**Statut du dossier** : 🔴 **EN COURS D'ANALYSE**  
**Priorité** : ⚠️ **ÉLEVÉE** (impact opérationnel : clients non intégrés)
