# Analyse : Mme. NATHALIE AUZEMERY-ZEMMOUR ne reçoit pas les notifications Oracle

**Date d'analyse** : 15/04/2026  
**Utilisateur concerné** : AUZEMERY-ZEMMOUR, Mme NATHALIE  
**Login Oracle EBS** : H00034632E  
**USER_ID** : 36273  
**EMPLOYEE_ID (PERSON_ID)** : 75956  
**Email** : nathalie.auzemery-zemmour@dalkia.fr

---

## Symptôme

Mme. NATHALIE AUZEMERY-ZEMMOUR ne reçoit aucune notification par e-mail depuis Oracle EBS. Elle doit se connecter manuellement à la liste de travail (Worklist) pour voir ses notifications.

---

## Diagnostic

### 1. Compte FND_USER — OK

```
USER_ID    : 36273
USER_NAME  : H00034632E
EMAIL      : nathalie.auzemery-zemmour@dalkia.fr
START_DATE : 19/11/2025
END_DATE   : (actif)
```

Le compte est actif et porte la bonne adresse e-mail.

### 2. WF_LOCAL_ROLES — ANOMALIE DÉTECTÉE

| ORIG_SYSTEM | ORIG_SYSTEM_ID | STATUS | NOTIFICATION_PREFERENCE | EMAIL |
|-------------|---------------|--------|------------------------|-------|
| PER         | 75956         | ACTIVE | MAILHTML               | nathalie.auzemery-zemmour@dalkia.fr |
| **FND_USR** | **36273**     | **ABSENT** | — | — |

**L'entrée `FND_USR` est manquante dans `WF_LOCAL_ROLES`.**

En Oracle EBS Workflow, le Mailer utilise l'entrée `ORIG_SYSTEM='FND_USR'` pour résoudre l'adresse e-mail d'un utilisateur FND et lui acheminer les notifications. Sans cette entrée, le Mailer ne peut pas identifier le destinataire et n'envoie pas d'e-mail.

### 3. Historique des notifications WF

```
NOTIFICATION_ID : 20513643
STATUS          : CLOSED
MAIL_STATUS     : (vide — aucun e-mail envoyé)
MESSAGE_TYPE    : DKA_CSP
MESSAGE_NAME    : DKA_MSG_FWD_BAP2
BEGIN_DATE      : 23/03/2026 07:56
END_DATE        : 01/04/2026 09:33
```

Une seule notification a été générée depuis la création du compte. Elle a été clôturée via la Worklist EBS (9 jours plus tard) **sans qu'aucun e-mail n'ait jamais été envoyé** (`MAIL_STATUS` vide).

### 4. Fiche RH — OK

```
PERSON_ID          : 75956
EMPLOYEE_NUMBER    : 76735S
CURRENT_EMPLOYEE   : Y
EFFECTIVE_START    : 01/09/2025
EMAIL RH           : nathalie.auzemery-zemmour@dalkia.fr
```

La fiche RH (`PER_ALL_PEOPLE_F`) est active depuis le 01/09/2025. L'entrée `PER` dans `WF_LOCAL_ROLES` a bien été créée. Seule la propagation `FND_USR` a échoué lors de la création du compte FND le 19/11/2025.

---

## Cause Racine

Lors de la création du compte FND_USER le 19/11/2025, la synchronisation automatique du répertoire Workflow (`WF_LOCAL_SYNCH.propagate_user`) n'a pas créé l'entrée `ORIG_SYSTEM='FND_USR'` dans `WF_LOCAL_ROLES`.

Ce problème est identique à celui rencontré pour **SNOECK, EMILIE (H00036238E)** le 03/04/2026 (voir `Ajout_de_responsabilite/pbAjoutRespon/Fix_WF_Synchro_H00036238E.sql`).

---

## Solution

Forcer la synchronisation du répertoire WF pour cet utilisateur via `WF_LOCAL_SYNCH.propagate_user`.

### Script de correction

```sql
-- =====================================================================
-- Fix : Synchronisation WF_LOCAL_ROLES pour H00034632E
--       (AUZEMERY-ZEMMOUR, Mme NATHALIE)
-- =====================================================================
-- Date           : 15/04/2026
-- USER_ID        : 36273
-- EMPLOYEE_ID    : 75956

-- ÉTAPE 1 : Vérification avant correction
SELECT 
    wlr.NAME,
    wlr.ORIG_SYSTEM,
    wlr.ORIG_SYSTEM_ID,
    wlr.DISPLAY_NAME,
    wlr.STATUS,
    wlr.NOTIFICATION_PREFERENCE,
    wlr.EMAIL_ADDRESS,
    TO_CHAR(wlr.EXPIRATION_DATE,'DD/MM/YYYY') AS EXPIRATION_DATE
FROM APPLSYS.WF_LOCAL_ROLES wlr
WHERE (wlr.ORIG_SYSTEM = 'FND_USR' AND wlr.ORIG_SYSTEM_ID = 36273)
   OR (wlr.ORIG_SYSTEM = 'PER'     AND wlr.ORIG_SYSTEM_ID = 75956);

-- ÉTAPE 2 : Synchronisation WF
BEGIN
    WF_LOCAL_SYNCH.propagate_user(
        p_orig_system    => 'FND_USR',
        p_orig_system_id => 36273  -- USER_ID de H00034632E
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK : Synchronisation WF effectuée pour H00034632E (USER_ID=36273)');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERREUR : ' || SQLERRM);
        RAISE;
END;
/

-- ÉTAPE 3 : Vérification après correction
-- L'entrée FND_USR doit maintenant apparaître avec NOTIFICATION_PREFERENCE='MAILHTML'
SELECT 
    wlr.NAME,
    wlr.ORIG_SYSTEM,
    wlr.ORIG_SYSTEM_ID,
    wlr.DISPLAY_NAME,
    wlr.STATUS,
    wlr.NOTIFICATION_PREFERENCE,
    wlr.EMAIL_ADDRESS,
    TO_CHAR(wlr.EXPIRATION_DATE,'DD/MM/YYYY') AS EXPIRATION_DATE
FROM APPLSYS.WF_LOCAL_ROLES wlr
WHERE (wlr.ORIG_SYSTEM = 'FND_USR' AND wlr.ORIG_SYSTEM_ID = 36273)
   OR (wlr.ORIG_SYSTEM = 'PER'     AND wlr.ORIG_SYSTEM_ID = 75956);
```

### Résultat attendu après correction

| ORIG_SYSTEM | STATUS | NOTIFICATION_PREFERENCE |
|-------------|--------|------------------------|
| PER         | ACTIVE | MAILHTML               |
| **FND_USR** | **ACTIVE** | **MAILHTML**       |

---

## Actions complémentaires recommandées

1. **Vérifier** que le Workflow Mailer est actif (programme "Workflow Mailer Service") et surveiller les prochaines notifications pour confirmer l'envoi.
2. **Contrôler** si d'autres comptes créés en novembre 2025 présentent le même problème (absence d'entrée FND_USR dans WF_LOCAL_ROLES).
3. **Investiguer** pourquoi la synchronisation automatique échoue à la création des comptes FND (voir paramétrage du job "Directory Services Validation").
