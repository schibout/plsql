# Analyse : Détournement des notifications hiérarchiques JORIS vers DEVILLIERS

**Date d'analyse :** 23/05/2026 — **Mise à jour :** 15/04/2026 (données vérifiées en base)  
**Demandeur :** Bruno LAPEYRE (Directeur de la Performance Opérationnelle Sud-Ouest)  
**Objet :** Les notifications pour lesquelles JORIS Olivier n'a pas la délégation remontent à DEVILLIERS Eric au lieu de BENESSE Franck (son responsable hiérarchique direct)

---

## 1. Contexte

Suite à un signalement : les factures du site **0380** traitées par JORIS Olivier, dépassant son seuil de délégation BAP (Bon à Payer), déclenchent des notifications hiérarchiques d'escalade vers **Eric DEVILLIERS** au lieu d'aller directement à **Franck BENESSE**.  

Le prédécesseur d'Olivier JORIS sur le site 0380 était Guillaume REDON, dont le nouveau responsable hiérarchique est Eric DEVILLIERS.  

> **Données vérifiées en base (15/04/2026)** : REDON a quitté le site 0380 le **30/09/2025** (changement d'affectation RH), et non en décembre 2025 comme supposé initialement. JORIS a pris le rôle `DNA0380_GESTION_RECEPTIONS` le 09/12/2025, soit 2 mois après le départ effectif de REDON.

---

## 2. Personnes impliquées

| Personne | Matricule | PERSON_ID | ASS_ATTRIBUTE3 | Chef hiérarchique DKA |
|---|---|---|---|---|
| PATRON Valérie | 44055S | 5278 | — | — |
| BENESSE Franck | 56893J | 6142 | 5278 (PATRON) | PATRON Valérie |
| DEVILLIERS Eric | 56483W | 738 | **6142 (BENESSE)** | BENESSE Franck |
| **JORIS Olivier** | **69747Y** | **40193** | **6142 (BENESSE)** | **BENESSE Franck ✓** |
| **REDON Guillaume** | **69942D** | **40700** | **738 (DEVILLIERS)** | **DEVILLIERS Eric** |

> **Note clé :** `ASS_ATTRIBUTE3` dans `PER_ALL_ASSIGNMENTS_F` est le champ personnalisé utilisé par le workflow DKA_CSP pour déterminer le supérieur hiérarchique DKA. Il est distinct du `SUPERVISOR_ID` standard Oracle HR.

---

## 3. Rôles WF actifs sur le site 0380

> **Données vérifiées en base le 15/04/2026** (requête `WF_LOCAL_USER_ROLES` + `PER_ALL_ASSIGNMENTS_F`)

| Utilisateur | Rôle WF | Depuis | Expiration |
|---|---|---|---|
| BENESSE Franck (56893J) | `FND_RESP\|ICX\|DNA0380_GESTION_RECEPTIONS\|STANDARD` | **14/04/2026** | — |
| JORIS Olivier (69747Y) | `FND_RESP\|ICX\|DNA0380_GESTION_RECEPTIONS\|STANDARD` | **09/12/2025** | — |
| JORIS Olivier (69747Y) | `FND_RESP\|ICX\|DNA0380_IP_GEST_DA_RECEPTION\|STANDARD` | 20/05/2022 | 09/12/2025 ✓ expiré |
| **REDON Guillaume (69942D)** | **`FND_RESP\|ICX\|DNA0380_IP_GEST_DA_RECEPTION\|STANDARD`** | **20/05/2022** | **NULL ← PROBLÈME** |
| **BONGRAND Christophe (69762S)** | **`FND_RESP\|ICX\|DNA0380_IP_GEST_DA_RECEPTION\|STANDARD`** | **20/05/2022** | **NULL ← PROBLÈME** |
| **PUYHARDY Nafissa (69924E)** | **`FND_RESP\|ICX\|DNA0380_IP_GEST_DA_RECEPTION\|STANDARD`** | **20/05/2022** | **NULL ← PROBLÈME** |
| **BOUCHARD Frédéric (69260F)** | **`FND_RESP\|ICX\|DNA0380_IP_GEST_DA_RECEPTION\|STANDARD`** | **20/05/2022** | **NULL ← PROBLÈME** |
| **BENMANSOUR Mohand (70073B)** | **`FND_RESP\|ICX\|DNA0380_IP_GEST_DA_RECEPTION\|STANDARD`** | **20/05/2022** | **NULL ← PROBLÈME** |

**Le problème est plus large que prévu** : 5 personnes conservent le rôle `DNA0380_IP_GEST_DA_RECEPTION` sans date d'expiration depuis mai 2022. REDON a quitté le site 0380 le **30/09/2025** (confirmé par `PER_ALL_ASSIGNMENTS_F`). Son rôle Oracle (`FND_USER_RESP_GROUPS`) est également toujours actif sans `END_DATE`.

**Seul JORIS** avait correctement vu son ancien rôle expiré (09/12/2025) lors de son passage au rôle `GESTION_RECEPTIONS`.

**Note :** BENESSE Franck a obtenu le rôle `DNA0380_GESTION_RECEPTIONS` le 14/04/2026, soit la veille de cette analyse — une action corrective partielle semble en cours.

---

## 4. Mécanisme du workflow DKA_CSP

### 4.1 Procédures clés (package `APPS.DKA_SAPWFCSP_PKG`)

**`get_superieur_hierachique` (ligne 8032-8087)**  
Détermine le supérieur d'un employé en lisant `PER_ALL_ASSIGNMENTS_F.ASS_ATTRIBUTE3` :
```sql
SELECT fu_superieur.user_name INTO vv_superieur
FROM per_all_people_f pap, per_all_assignments_f paf,
     per_all_people_f superieur, fnd_user fu, fnd_user fu_superieur
WHERE fu.user_name = pv_user_name
  AND fu.employee_id = pap.person_id
  AND paf.person_id = pap.person_id
  AND superieur.person_id = paf.ass_attribute3   -- ← ASS_ATTRIBUTE3, pas SUPERVISOR_ID
  AND fu_superieur.employee_id = superieur.person_id
  AND rownum = 1;                                -- ← Pas de filtre de date, risque multi-lignes
```

**`superieur_bap` (ligne 8098-8147)**  
Appelée par l'activité `DKA_SUPERIEUR_EMPLOYE`. Elle :
1. Lit l'attribut `VALIDEUR_BAP` (le valideur actuel)
2. Appelle `get_superieur_hierachique(VALIDEUR_BAP)` pour trouver son supérieur
3. Met à jour `VALIDEUR_BAP` avec le supérieur trouvé

**`employe_droit_habilitation` (ligne 5968-6001)**  
Appelée par l'activité `DKA_HABILITE_BAP`. Elle vérifie si le `VALIDEUR_BAP` courant a un seuil de délégation suffisant via `PER_JOBS.ATTRIBUTE1`.

### 4.2 Flux normal du workflow BAP

```
CSP reçoit notif → CSP valide et transfère au chef d'exploitation (DKA_FORWARD)
  → VALIDEUR_BAP := exploitant du site
  → DKA_NOTIF_EXPLOIT_ATTENTE_BAP envoyé à VALIDEUR_BAP
  → Exploitant répond SOUMETTRE
    → DKA_HABILITE_BAP(VALIDEUR_BAP) → N (délégation insuffisante)
      → DKA_SUPERIEUR_EMPLOYE : VALIDEUR_BAP := supérieur(VALIDEUR_BAP)
        → DKA_NOTIF_HIERAR_ATTENTE_BAP envoyé au supérieur
          → Réponse SOUMETTRE → nouvelle remontée hiérarchique si nécessaire
```

---

## 5. Cas concret analysé

### Facture CEDLK2026-01 — Item DKA_CSP `11307004_8639749`

**Chronologie des activités :**

| Date | Activité | Utilisateur | Résultat | NID |
|---|---|---|---|---|
| 04/03/2026 22:59 | `DKA_INIT_WF_AP` | — | SUCCESS | — |
| 04/03/2026 22:59 | `DKA_NOTIF_CSP_IMPUT_ATTENTE_IV` | **75438K** (CSP) | SOUMETTRE | 20457166 |
| 04/03/2026 22:59 | `DKA_NOTIF_CSP_ANO_DIVERS` | **75438K** (CSP) | DKA_APPROVE | 20457167 |
| 06/03/2026 09:39 | `DKA_NOTIF_CSP_ATTENTE_BAP` | **75438K** (CSP) | **DKA_FORWARD** | 20461946 |
| 06/03/2026 09:40 | `DKA_NOTIF_EXPLOIT_ATTENTE_BAP` | **69747Y (JORIS)** | SOUMETTRE | 20461947 |
| 10/03/2026 16:51 | `DKA_HABILITE_BAP` | — | **N** | — |
| 10/03/2026 16:51 | `DKA_SUPERIEUR_EMPLOYE` | — | SUCCESS | — |
| 10/03/2026 16:51 | `DKA_NOTIF_HIERAR_ATTENTE_BAP` | **56483W (DEVILLIERS)** | SOUMETTRE | 20472360 ✗ |
| 13/03/2026 09:18 | `DKA_HABILITE_BAP` | — | N | — |
| 13/03/2026 09:18 | `DKA_SUPERIEUR_EMPLOYE` | — | SUCCESS | — |
| 13/03/2026 09:18 | `DKA_NOTIF_HIERAR_ATTENTE_BAP` | **56893J (BENESSE)** | OPEN | 20481989 |

**Attributs de l'item (état actuel) :**

| Attribut | Valeur |
|---|---|
| `VALIDEUR_BAP` | `56893J` (BENESSE — après 2 cycles d'escalade) |
| `FORWARD_TO_USERNAME_RESPONSE` | `69942D` **(REDON ← clé du problème)** |
| `DKA_COMMENTS` | `Vu avec O JORIS (Directeur du Site) ; BAP` |
| `RESPONDER_USER_ID` | 24514 (DEVILLIERS Eric) |

---

## 6. Cause racine identifiée

### 6.1 Point de défaillance : VALIDEUR_BAP = REDON

La notification `DKA_NOTIF_EXPLOIT_ATTENTE_BAP` a bien été envoyée à **JORIS** (69747Y) le 06/03/2026. Lors de sa réponse SOUMETTRE, **JORIS a renseigné REDON (69942D) dans le champ FORWARD_TO** de l'écran de réponse de la notification.  

La procédure `notif_EXPLOIT_BAP` utilise ce champ **uniquement si le résultat est `DKA_RETRANS`** (retransmettre explicitement à quelqu'un). Pour l'action SOUMETTRE, `VALIDEUR_BAP` n'est théoriquement pas modifié. Cependant, l'attribut `FORWARD_TO_USERNAME_RESPONSE = 69942D` (REDON) est bien enregistré dans l'item WF.

Entre la réponse de JORIS (06/03) et l'exécution de `DKA_HABILITE_BAP` (10/03), `VALIDEUR_BAP` s'est retrouvé à `69942D` (REDON). Le mécanisme exact invoqué est l'une de ces voies :

**Voie A — Erreur utilisateur** : JORIS a vu REDON dans la liste des agents disponibles pour le site 0380 (car REDON a encore le rôle actif `DNA0380_IP_GEST_DA_RECEPTION`). JORIS a transféré à REDON, pensant que c'était le bon interlocuteur.

**Voie B — Sélection automatique** : La recherche de l'exploitant du site 0380 a retourné REDON (son rôle `DNA0380_IP_GEST_DA_RECEPTION` est plus ancien que `DNA0380_GESTION_RECEPTIONS` de JORIS), le rendant prioritaire dans les requêtes sans filtre de date.

**Dans les deux cas, la cause commune est identique** : REDON possède encore un rôle WF actif sur le site 0380 sans date d'expiration.

### 6.2 Cascade d'escalade incorrecte

```
VALIDEUR_BAP = REDON (69942D)
  ├── DKA_HABILITE_BAP(REDON) = N  → délégation insuffisante
  ├── DKA_SUPERIEUR_EMPLOYE : ASS_ATTRIBUTE3(REDON) = 738 (DEVILLIERS)
  │                           → VALIDEUR_BAP := 56483W (DEVILLIERS)
  ├── DKA_NOTIF_HIERAR_ATTENTE_BAP → DEVILLIERS reçoit la notif (20472360) ← ERREUR
  ├── DEVILLIERS répond SOUMETTRE
  ├── DKA_SUPERIEUR_EMPLOYE : ASS_ATTRIBUTE3(DEVILLIERS) = 6142 (BENESSE)
  │                           → VALIDEUR_BAP := 56893J (BENESSE)
  └── DKA_NOTIF_HIERAR_ATTENTE_BAP → BENESSE reçoit (20481989) ← OPEN
```

### 6.3 Flux attendu correct (si VALIDEUR_BAP = JORIS)

```
VALIDEUR_BAP = JORIS (69747Y)
  ├── DKA_HABILITE_BAP(JORIS) = N  → délégation insuffisante
  ├── DKA_SUPERIEUR_EMPLOYE : ASS_ATTRIBUTE3(JORIS) = 6142 (BENESSE)
  │                           → VALIDEUR_BAP := 56893J (BENESSE)
  └── DKA_NOTIF_HIERAR_ATTENTE_BAP → BENESSE reçoit directement ← CORRECT
```

---

## 7. Notifications actuellement ouvertes

| Notification ID | Destinataire | Statut | Item | Site | Commentaire |
|---|---|---|---|---|---|
| **20481989** | **56893J (BENESSE)** | **OPEN** | 11307004_8639749 | **0380** | **A traiter par BENESSE** |
| **20470033** | **69942D (REDON)** | **OPEN** | 11287201_8622722 | **0820** | Cas distinct — site 0820 |

La notification **20481989** est la 2ème escalade hiérarchique après DEVILLIERS. BENESSE la reçoit correctement à cette étape, mais avec 1 niveau de retard inutile (DEVILLIERS a été sollicité à tort).

La notification **20470033** (site 0820) est un cas distinct à analyser séparément.

---

## 8. Actions correctives

### Action 1 — CORRECTIF IMMÉDIAT : Expirer les rôles des 5 anciens exploitants sur site 0380

> **Périmètre élargi** : 5 personnes sont concernées, pas uniquement REDON (confirmé en base le 15/04/2026).

```sql
-- =========================================================
-- CORRECTIF : Expirer les anciens rôles WF sur site 0380
-- =========================================================
-- Vérification avant exécution
SELECT USER_NAME, ROLE_NAME, TO_CHAR(START_DATE,'DD/MM/YYYY') START_DATE,
       TO_CHAR(EXPIRATION_DATE,'DD/MM/YYYY') EXPIRATION_DATE
  FROM WF_LOCAL_USER_ROLES
 WHERE ROLE_NAME = 'FND_RESP|ICX|DNA0380_IP_GEST_DA_RECEPTION|STANDARD'
   AND EXPIRATION_DATE IS NULL;
/*
Résultat constaté le 15/04/2026 :
USER_NAME  ROLE_NAME                                            START_DATE   EXPIRATION_DATE
69942D     FND_RESP|ICX|DNA0380_IP_GEST_DA_RECEPTION|STANDARD  20/05/2022   NULL
69762S     FND_RESP|ICX|DNA0380_IP_GEST_DA_RECEPTION|STANDARD  20/05/2022   NULL
69924E     FND_RESP|ICX|DNA0380_IP_GEST_DA_RECEPTION|STANDARD  20/05/2022   NULL
69260F     FND_RESP|ICX|DNA0380_IP_GEST_DA_RECEPTION|STANDARD  20/05/2022   NULL
70073B     FND_RESP|ICX|DNA0380_IP_GEST_DA_RECEPTION|STANDARD  20/05/2022   NULL
*/

-- Exécution du correctif (après validation DBA)
UPDATE WF_LOCAL_USER_ROLES
   SET EXPIRATION_DATE = TRUNC(SYSDATE)
 WHERE ROLE_NAME = 'FND_RESP|ICX|DNA0380_IP_GEST_DA_RECEPTION|STANDARD'
   AND EXPIRATION_DATE IS NULL;
-- 5 lignes attendues

COMMIT;

-- Expirer également les responsabilités Oracle correspondantes
-- (FND_USER_RESP_GROUPS : END_DATE non renseignée pour ces utilisateurs)
UPDATE FND_USER_RESP_GROUPS_ALL FURG
   SET FURG.END_DATE = TRUNC(SYSDATE)
 WHERE FURG.RESPONSIBILITY_ID = (
    SELECT RESPONSIBILITY_ID FROM FND_RESPONSIBILITY
     WHERE RESPONSIBILITY_KEY = 'DNA0380_IP_GEST_DA_RECEPTION')
   AND FURG.USER_ID IN (
    SELECT USER_ID FROM FND_USER
     WHERE USER_NAME IN ('69942D','69762S','69924E','69260F','70073B'))
   AND (FURG.END_DATE IS NULL OR FURG.END_DATE > SYSDATE);

COMMIT;
```

> **⚠️ ATTENTION** : Ces mises à jour impactent directement les tables de workflow Oracle. La modification en production nécessite une fenêtre de maintenance ou une validation DBA. Vérifier d'abord l'impact sur d'autres items WF en cours pour chacun de ces utilisateurs.

### Action 2 — VÉRIFICATION : Confirmer la cohérence des rôles

```sql
-- Lister tous les rôles actifs pour REDON sur tous les sites
SELECT USER_NAME, ROLE_NAME, START_DATE, EXPIRATION_DATE
FROM APPLSYS.WF_LOCAL_USER_ROLES
WHERE USER_NAME = '69942D'
  AND (EXPIRATION_DATE IS NULL OR EXPIRATION_DATE > SYSDATE)
  AND ROLE_NAME LIKE 'FND_RESP|ICX|DNA%'
ORDER BY ROLE_NAME;

-- Lister les exploitants actifs du site 0380
SELECT WR.ROLE_NAME, WLUR.USER_NAME, WLUR.START_DATE, WLUR.EXPIRATION_DATE,
       PAPF.FULL_NAME
FROM APPLSYS.WF_LOCAL_USER_ROLES WLUR
JOIN APPLSYS.WF_LOCAL_ROLES WR ON WR.NAME = WLUR.ROLE_NAME
JOIN APPLSYS.FND_USER FU ON FU.USER_NAME = WLUR.USER_NAME
JOIN HR.PER_ALL_PEOPLE_F PAPF ON PAPF.PERSON_ID = FU.EMPLOYEE_ID
  AND TRUNC(SYSDATE) BETWEEN PAPF.EFFECTIVE_START_DATE AND PAPF.EFFECTIVE_END_DATE
WHERE WLUR.ROLE_NAME LIKE 'FND_RESP|ICX|DNA0380%'
  AND (WLUR.EXPIRATION_DATE IS NULL OR WLUR.EXPIRATION_DATE > SYSDATE)
ORDER BY WLUR.ROLE_NAME, WLUR.USER_NAME;
```

### Action 3 — PROCESSUS PRÉVENTIF : Procédure de changement d'exploitant

À intégrer dans les procédures RH pour tout changement d'exploitant sur un site :

1. **Désactiver le rôle de l'ancien exploitant** : Expirer la date dans `WF_LOCAL_USER_ROLES` avec `EXPIRATION_DATE = TRUNC(SYSDATE)`, et via l'IHM Oracle HR (responsabilité → date de fin)
2. **Créer/Activer le rôle du nouvel exploitant** : Via l'IHM Oracle HR, affecter la responsabilité correspondant au site (ex: `DNA0380_GESTION_RECEPTIONS`)
3. **Vérifier les notifications en cours** : S'assurer qu'aucune notification WF ouverte n'est encore adressée à l'ancien exploitant
4. **Vérifier l'ASS_ATTRIBUTE3** du nouvel exploitant : Il doit pointer vers son responsable hiérarchique DKA direct (pas vers le responsable de l'ancien exploitant)

### Action 4 — ANALYSE COMPLÉMENTAIRE : Robustesse de `get_superieur_hierachique`

La procédure `get_superieur_hierachique` (ligne 8032, package `DKA_SAPWFCSP_PKG`) **ne filtre pas par date** sur `PER_ALL_ASSIGNMENTS_F`. Si un employé a plusieurs assignments (historiques), le `rownum = 1` peut retourner un résultat non déterministe :

```sql
-- Code actuel (bugué potentiellement) :
WHERE ... AND paf.person_id = pap.person_id
  AND superieur.person_id = paf.ass_attribute3
  AND rownum = 1;   -- ← PAS de filtre EFFECTIVE_START_DATE / EFFECTIVE_END_DATE

-- Correction recommandée :
WHERE ... AND paf.person_id = pap.person_id
  AND TRUNC(SYSDATE) BETWEEN paf.effective_start_date AND paf.effective_end_date
  AND pap.person_id = pap.person_id  -- déjà présent
  AND trunc(SYSDATE) BETWEEN pap.effective_start_date AND pap.effective_end_date
  AND superieur.person_id = paf.ass_attribute3
  AND rownum = 1;
```

> Cette correction de code nécessite une demande de développement et une validation en recette avant déploiement en production.

---

## 9. Résumé et priorités

| Priorité | Action | Impact | Délai |
|---|---|---|---|
| **P1 - URGENT** | Expirer `DNA0380_IP_GEST_DA_RECEPTION` pour **5 utilisateurs** (REDON, BONGRAND, PUYHARDY, BOUCHARD, BENMANSOUR) | Empêche les futures erreurs de routage site 0380 | Immédiat |
| **P2 - IMPORTANT** | Analyser la notification 20470033 (REDON/site 0820) | Corriger une autre anomalie potentielle | Semaine en cours |
| **P3 - MOYEN** | Auditer tous les anciens exploitants sans rôle expiré | Identifier d'autres sites avec le même problème | Mois en cours |
| **P4 - PLANIFIÉ** | Documenter la procédure de changement d'exploitant | Éviter les récurrences | Prochaine version |
| **P5 - LONG TERME** | Corriger `get_superieur_hierachique` (filtre de date) | Robustesse du code | Avec prochaine évolution DKA_SAPWFCSP_PKG |

---

## 10. Requête de diagnostic rapide

```sql
-- Identifier tous les cas similaires : utilisateurs avec rôle DNA% expiré OU en double
SELECT WLUR.USER_NAME, 
       PAPF.FULL_NAME,
       WLUR.ROLE_NAME,
       WLUR.START_DATE,
       WLUR.EXPIRATION_DATE,
       (SELECT COUNT(1) FROM APPLSYS.WF_LOCAL_USER_ROLES W2
        WHERE W2.USER_NAME != WLUR.USER_NAME
          AND W2.ROLE_NAME = WLUR.ROLE_NAME
          AND (W2.EXPIRATION_DATE IS NULL OR W2.EXPIRATION_DATE > SYSDATE)
       ) AS NB_AUTRES_ACTIFS_MEME_ROLE
FROM APPLSYS.WF_LOCAL_USER_ROLES WLUR
JOIN APPLSYS.FND_USER FU ON FU.USER_NAME = WLUR.USER_NAME
JOIN HR.PER_ALL_PEOPLE_F PAPF ON PAPF.PERSON_ID = FU.EMPLOYEE_ID
  AND TRUNC(SYSDATE) BETWEEN PAPF.EFFECTIVE_START_DATE AND PAPF.EFFECTIVE_END_DATE
WHERE WLUR.ROLE_NAME LIKE 'FND_RESP|ICX|DNA%_IP_GEST_DA_RECEPTION|STANDARD'
   OR WLUR.ROLE_NAME LIKE 'FND_RESP|ICX|DNA%_GESTION_RECEPTIONS|STANDARD'
ORDER BY WLUR.ROLE_NAME, WLUR.EXPIRATION_DATE NULLS LAST;
```

---

*Analyse réalisée par GitHub Copilot - Investigation Oracle EBS 12.2 production*  
*Package analysé : `APPS.DKA_SAPWFCSP_PKG` | Workflow : `DKA_CSP` | Tables : `WF_LOCAL_USER_ROLES`, `PER_ALL_ASSIGNMENTS_F`, `WF_NOTIFICATIONS`, `WF_ITEM_ATTRIBUTE_VALUES`*
