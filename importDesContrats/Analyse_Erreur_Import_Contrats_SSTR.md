# Analyse Erreur Import Contrats SSTR depuis iValua 
**Date d'analyse** : 16/01/2026  
**Auteur** : Samir CHIBOUT  
**Incident** : Programme DKA_IPO_SSTR_IVALUA terminé en avertissement  
**Request ID** : 46794096  

---

## 1. Description du Problème

Le programme d'import des contrats SSTR (sous-traitance) depuis iValua s'est terminé avec un statut **"Avertissement"** le 15/01/2026 à 19:25:58.

**13 contrats ont été rejetés** avec le message d'erreur :
```
La commande STxxxxxxx n'existe pas dans Oracle.
```

### Contrats concernés

| Contrat | RECORD_ID | Commande |
|---------|-----------|----------|
| CTR019079 | 22314 | ST2068109 |
| CTR019088 | 22315 | ST2069016 |
| CTR019253 | 22316 | ST2068693 |
| CTR019272 | 22317 | ST2069591 |
| CTR019283 | 22318 | ST2068222 |
| CTR019466 | 22319 | ST2068648 |
| CTR019601 | 22320 | ST2068576 |
| CTR019804 | 22321 | ST2068923 |
| CTR020423 | 22322 | ST2067853 |
| CTR021115 | 22323 | ST2069494 |
| CTR023394 | 22324 | ST2067857 |
| CTR023783 | 22325 | ST2068623 |
| CTR024272 | 22326 | ST2068357 |

---

## 2. Origine du Problème

### Cause Racine : Désynchronisation des flux iValua

Le problème vient d'un **décalage temporel entre deux flux d'import** :

| Flux | Programme | Exécution | Données |
|------|-----------|-----------|---------|
| Import Contrats SSTR | DKA_IPO_SSTR_IVALUA | **15/01/2026 19:25:26** | Contrats référençant des commandes |
| Import Commandes PO | (Import PO standard) | **16/01/2026 09:04:38** | Commandes ST20xxxxx |

**Résultat** : Les contrats ont été importés **14 heures AVANT** que les commandes référencées n'existent dans Oracle.

### Schéma du problème

```
CHRONOLOGIE
═══════════════════════════════════════════════════════════════════════

  15/01/2026 19:25:26                    16/01/2026 09:04:38
         │                                        │
         ▼                                        ▼
  ┌─────────────────┐                    ┌─────────────────┐
  │ Import Contrats │                    │ Import Commandes│
  │     SSTR        │                    │      PO         │
  └────────┬────────┘                    └────────┬────────┘
           │                                      │
           ▼                                      ▼
  ┌─────────────────┐                    ┌─────────────────┐
  │ Validation :    │                    │ Création dans   │
  │ Commande existe?│──── NON ❌          PO_HEADERS_ALL   │
  └─────────────────┘                    └─────────────────┘
           │
           ▼
  ┌─────────────────┐
  │ REJET : 13      │
  │ contrats        │
  └─────────────────┘
```

---

## 3. Requêtes SQL Utilisées pour l'Analyse

### 3.1 Vérification de l'existence des commandes

```sql
-- Requête 1 : Vérifier si les commandes existent dans Oracle
SELECT 
    PHA.SEGMENT1 AS NUM_COMMANDE,
    PHA.PO_HEADER_ID,
    PHA.TYPE_LOOKUP_CODE AS TYPE_COMMANDE,
    PHA.AUTHORIZATION_STATUS AS STATUT,
    PHA.APPROVED_FLAG AS APPROUVE,
    PHA.CANCEL_FLAG AS ANNULE,
    PHA.CLOSED_CODE AS CODE_CLOTURE,
    TO_CHAR(PHA.CREATION_DATE, 'DD/MM/YYYY') AS DATE_CREATION,
    PHA.ORG_ID
FROM PO.PO_HEADERS_ALL PHA
WHERE PHA.SEGMENT1 IN (
    'ST2068109', 'ST2069016', 'ST2068693', 'ST2069591', 'ST2068222',
    'ST2068648', 'ST2068576', 'ST2068923', 'ST2067853', 'ST2069494',
    'ST2067857', 'ST2068623', 'ST2068357'
)
ORDER BY PHA.SEGMENT1;
```

**Résultat** : Les 13 commandes existent toutes avec statut APPROVED et OPEN.

### 3.2 Vérification des dates de création vs import

```sql
-- Requête 2 : Comparer les heures de création avec l'heure d'import
SELECT 
    PHA.SEGMENT1 AS NUM_COMMANDE,
    TO_CHAR(PHA.CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS DATE_CREATION,
    TO_CHAR(PHA.LAST_UPDATE_DATE, 'DD/MM/YYYY HH24:MI:SS') AS DERNIERE_MAJ,
    PHA.AUTHORIZATION_STATUS AS STATUT,
    CASE 
        WHEN PHA.CREATION_DATE > TO_DATE('15/01/2026 19:25:26', 'DD/MM/YYYY HH24:MI:SS') 
        THEN 'Créée APRES import'
        ELSE 'Créée AVANT import'
    END AS TIMING_VS_IMPORT
FROM PO.PO_HEADERS_ALL PHA
WHERE PHA.SEGMENT1 IN (
    'ST2068109', 'ST2069016', 'ST2068693', 'ST2069591', 'ST2068222',
    'ST2068648', 'ST2068576', 'ST2068923', 'ST2067853', 'ST2069494',
    'ST2067857', 'ST2068623', 'ST2068357'
)
ORDER BY PHA.CREATION_DATE;
```

**Résultat obtenu** :

| Commande | Date Création | Statut | Timing |
|----------|---------------|--------|--------|
| ST2067857 | 16/01/2026 09:04:38 | APPROVED | Créée APRES import |
| ST2067853 | 16/01/2026 09:04:38 | APPROVED | Créée APRES import |
| ST2068357 | 16/01/2026 09:04:39 | APPROVED | Créée APRES import |
| ST2068576 | 16/01/2026 09:04:39 | APPROVED | Créée APRES import |
| ST2068222 | 16/01/2026 09:04:39 | APPROVED | Créée APRES import |
| ST2068109 | 16/01/2026 09:04:39 | APPROVED | Créée APRES import |
| ST2068623 | 16/01/2026 09:04:39 | APPROVED | Créée APRES import |
| ST2068693 | 16/01/2026 09:04:39 | APPROVED | Créée APRES import |
| ST2068648 | 16/01/2026 09:04:39 | APPROVED | Créée APRES import |
| ST2068923 | 16/01/2026 09:04:40 | APPROVED | Créée APRES import |
| ST2069016 | 16/01/2026 09:04:40 | APPROVED | Créée APRES import |
| ST2069494 | 16/01/2026 09:04:41 | APPROVED | Créée APRES import |
| ST2069591 | 16/01/2026 09:04:41 | APPROVED | Créée APRES import |

**Conclusion** : Toutes les commandes ont été créées **APRÈS** l'exécution de l'import des contrats.

---

## 4. Comment Corriger

### 4.1 Correction Immédiate

**Relancer le programme d'import des contrats SSTR** :

1. Accéder à Oracle EBS → Navigator → Requests → Submit Request
2. Sélectionner le programme : **DKA : Import des contrats SSTR depuis iValua**
3. Paramètre : `N` (comme l'exécution précédente)
4. Soumettre la requête

Les 13 contrats en erreur seront retraités et devraient maintenant être validés car les commandes existent.

### 4.2 Vérification après relance

```sql
-- Vérifier le succès du retraitement
SELECT 
    FCR.REQUEST_ID,
    FCPV.USER_CONCURRENT_PROGRAM_NAME AS PROGRAMME,
    FCR.PHASE_CODE,
    FCR.STATUS_CODE,
    TO_CHAR(FCR.ACTUAL_START_DATE, 'DD/MM/YYYY HH24:MI:SS') AS DEBUT,
    TO_CHAR(FCR.ACTUAL_COMPLETION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS FIN
FROM FND_CONCURRENT_REQUESTS FCR
JOIN FND_CONCURRENT_PROGRAMS_VL FCPV 
    ON FCR.CONCURRENT_PROGRAM_ID = FCPV.CONCURRENT_PROGRAM_ID
WHERE FCPV.CONCURRENT_PROGRAM_NAME = 'DKA_IPO_SSTR_IVALUA'
    AND FCR.ACTUAL_START_DATE >= TRUNC(SYSDATE)
ORDER BY FCR.REQUEST_ID DESC;
```

### 4.3 Corrections Préventives (Long Terme)

#### Option A : Revoir l'ordonnancement des jobs

Modifier la planification pour que l'import des **commandes PO** s'exécute **AVANT** l'import des **contrats SSTR** :

```
Ordre recommandé :
1. DKA_IPO_xxx (Import Commandes PO)     → 19:00
2. Validation/Approbation PO             → 19:15
3. DKA_IPO_SSTR_IVALUA (Import Contrats) → 19:30
```

#### Option B : Ajouter une dépendance entre les jobs

Configurer dans Oracle Concurrent Manager une dépendance :
- **DKA_IPO_SSTR_IVALUA** dépend de la fin de l'import des commandes PO

#### Option C : Mécanisme de retry automatique

Modifier le package PL/SQL pour :
1. Logger les contrats en erreur dans une table de staging
2. Planifier un job de reprise automatique après X heures
3. Retraiter uniquement les enregistrements en échec

---

## 5. Code Source Générant l'Erreur

### 5.1 Programme et Package

| Élément | Valeur |
|---------|--------|
| Programme | DKA_IPO_SSTR_IVALUA |
| Package PL/SQL | `DKA_IPO_SSTR_IVALUA_PKG.Main` |
| Message FND | `DKA_IPOCTR_SSTR_VT08` |
| Texte du message | "La commande &NUM_COMMANDE n'existe pas dans Oracle." |

### 5.2 Code de Validation (Lignes 802-837)

```sql
----- Contrôle de coherence de données dans le systeme oracle
    v_etape:= 'Contrôle de l''existence du numéro de commande';
    DKA_TOOLS_PKG.put_log_message(v_etape);
    BEGIN
      SELECT  po_header_Id , Org_Id
      INTO   v_po_header_Id, v_org_Id
      FROM   Po_Headers_All pha
      WHERE  pha.Segment1 = rec_donnee.NUM_COMMANDE ;

      SELECT  count(*)
      INTO   v_exist_po
      FROM   Po_Headers_All pha
      WHERE  pha.Segment1 = rec_donnee.NUM_COMMANDE ;

     Exception when No_Data_Found Then
       v_po_header_Id := null;
       v_exist_po := 0;

    END ;
    
    -- *** ICI SE GENERE L'ERREUR ***
    IF v_exist_po = 0  and rec_donnee.NUM_COMMANDE is not null THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCTR_SSTR_VT08','NUM_COMMANDE',rec_donnee.NUM_COMMANDE);

        DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     ,'VALIDATION'
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     , rec_donnee.record_id
                                     ,'NUM_COMMANDE'
                                     ,rec_donnee.NUM_COMMANDE
                                     ,'E'
                                     ,l_message
                                      );
        DKA_TOOLS_PKG.put_log_message(l_message);
        v_flag_erreur_ctr := TRUE;  -- Marque le contrat en erreur
    END IF ;
```

### 5.3 Logique de Traitement

```
┌─────────────────────────────────────────────────────────────────┐
│           FLUX DE VALIDATION DU CONTRAT SSTR                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Lecture du contrat depuis DKA_IPOCTR_SSTR_IVALUA           │
│     └── rec_donnee.NUM_COMMANDE = 'ST2068109'                  │
│                                                                 │
│  2. Recherche dans PO_HEADERS_ALL                              │
│     └── SELECT ... WHERE Segment1 = 'ST2068109'                │
│                                                                 │
│  3. Résultat : NO_DATA_FOUND                                   │
│     └── v_exist_po = 0                                         │
│                                                                 │
│  4. Condition remplie : v_exist_po = 0 AND NUM_COMMANDE IS NOT NULL │
│     └── Génère message DKA_IPOCTR_SSTR_VT08                    │
│     └── v_flag_erreur_ctr = TRUE                               │
│                                                                 │
│  5. Mise à jour statut                                          │
│     └── UPDATE DKA_IPOCTR_SSTR_IVALUA SET STATUT = 'REJECTED'  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.4 Table de Staging

Les contrats rejetés sont marqués avec `STATUT = 'REJECTED'` dans la table `DKA_IPOCTR_SSTR_IVALUA`.

```sql
-- Vérifier les contrats rejetés dans la table de staging
SELECT 
    RECORD_ID,
    NUM_CONTRAT,
    NUM_COMMANDE,
    STATUT,
    REQUEST_ID,
    TO_CHAR(LAST_UPDATE_DATE, 'DD/MM/YYYY HH24:MI:SS') AS DATE_MAJ
FROM APPS.DKA_IPOCTR_SSTR_IVALUA
WHERE RECORD_ID BETWEEN 22314 AND 22326
ORDER BY RECORD_ID;
```

---

## 6. Résumé

| Élément | Détail |
|---------|--------|
| **Problème** | 13 contrats rejetés car commandes inexistantes |
| **Cause** | Flux import contrats exécuté avant flux import commandes |
| **Écart temporel** | ~14 heures |
| **Statut actuel** | ✅ Commandes maintenant disponibles |
| **Action requise** | Relancer DKA_IPO_SSTR_IVALUA |
| **Prévention** | Revoir l'ordonnancement des flux iValua |

---

*Analyse réalisée le 16/01/2026*
