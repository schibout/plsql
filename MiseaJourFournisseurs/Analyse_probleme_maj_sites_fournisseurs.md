# 🔍 Analyse du problème - Mise à jour quotidienne des sites fournisseurs dupliqués

**Date de l'analyse** : 28 novembre 2025  
**Programme** : DKA : Mise à jour quotidienne des sites fournisseurs dupliqués  
**Package PL/SQL** : DKA_SAPFRSDUPLI_MAJ_PKG.MAIN

---

## 📊 Résumé du problème

### **Situation actuelle**
- **Request ID actuel** : 46351151
- **Lancé le** : 28/11/2025 à 07:00:07
- **Durée en cours** : **8 heures** (toujours en cours)
- **Statut** : Running (R)

### **Incident précédent (hier)**
- **Request ID** : 46304717
- **Lancé le** : 27/11/2025 à 13:41:19
- **Terminé le** : 27/11/2025 à 23:39:06
- **Durée totale** : **597.78 minutes (9h 58min)**
- **Statut final** : Warning (G)

### **Performance normale**
- **Durée habituelle** : ~18 secondes
- **Durée maximale normale** : 15 minutes
- **Fréquence d'exécution** : Toutes les 10 minutes (72 fois/jour)

---

## 🔍 Analyse du code PL/SQL

### **Description du programme**

Le package `DKA_SAPFRSDUPLI_MAJ_PKG` effectue la mise à jour quotidienne des sites fournisseurs dupliqués dans Oracle EBS.

**Auteur** : Asma AMENKOUR (Capgemini)  
**Date de création** : 08/07/2020  
**Dernière modification** : INC0617119 / KDFI-652

---

### **Logique du traitement**

#### **1. Récupération de la date de dernière mise à jour**
```sql
SELECT date_value
FROM DKA_PARAMETERS
WHERE program_code = 'DKA_SAPFRSDUPLI_MAJ'
AND parameter_name = 'DATE_DERNIERE_MAJ';
```

#### **2. Curseur SITE_A_MAJ - Sélection des sites à traiter**

Le curseur identifie les sites fournisseurs de la référence REF9999 qui ont été modifiés depuis la dernière exécution :

**Tables interrogées** :
- `ap_supplier_sites_all` (sites fournisseurs)
- `ap_suppliers` (fournisseurs)
- `hr_operating_units` (unités opérationnelles)
- `iby_ext_bank_accounts` (comptes bancaires)
- `iby_pmt_instr_uses_all` (instruments de paiement)
- `iby_external_payees_all` (payeurs externes)
- `iby_ext_party_pmt_mthds` (méthodes de paiement)

**Condition de sélection** :
```sql
WHERE hou.name = 'REF9999'
AND (ieppm.last_update_date > p_date_maj 
     OR assa.last_update_date > p_date_maj 
     OR ipi.LAST_UPDATE_DATE > p_date_maj 
     OR iep.LAST_UPDATE_DATE > p_date_maj)
```

#### **3. Traitement de chaque site**

Pour chaque site trouvé, le programme appelle :
```plsql
DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR(
    rec_site_a_maj.vendor_site_id,
    v_result_maj,
    v_nbr_maj_succes,
    v_nbr_maj_echec,
    v_maj_code_echec,
    v_id_liste_erreur
);
```

#### **4. Mise à jour de la date de lancement**
```sql
UPDATE DKA_PARAMETERS
SET date_value = (SELECT requested_start_date 
                  FROM fnd_concurrent_requests 
                  WHERE request_id = g_request_id)
WHERE program_code = 'DKA_SAPFRSDUPLI_MAJ'
AND parameter_name = 'DATE_DERNIERE_MAJ';
```

---

## ⚠️ Causes probables du problème

### **1. Volume anormal de données à traiter** 🔴

**Hypothèse** : Le curseur `SITE_A_MAJ` retourne un nombre anormalement élevé de sites à traiter.

**Causes possibles** :
- Modification massive de sites dans REF9999
- Problème avec la date de dernière MAJ dans `DKA_PARAMETERS`
- Import massif de fournisseurs depuis un système externe (iValua, SAP, etc.)

**Vérification nécessaire** :
```sql
SELECT date_value
FROM DKA_PARAMETERS
WHERE program_code = 'DKA_SAPFRSDUPLI_MAJ'
AND parameter_name = 'DATE_DERNIERE_MAJ';
```

Si cette date est très ancienne ou nulle, le curseur sélectionnerait TOUS les sites fournisseurs !

---

### **2. Performance des jointures** 🟡

Le curseur effectue **7 jointures** dont plusieurs en OUTER JOIN :
- `iby_ext_bank_accounts` (+)
- `iby_pmt_instr_uses_all` (+)
- `iby_external_payees_all` (+)

**Problème potentiel** :
- Absence d'index sur les colonnes de jointure
- Statistiques obsolètes
- Plan d'exécution inefficace

---

### **3. Boucle de traitement non optimisée** 🟡

Pour chaque site, le programme :
1. Appelle `DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR`
2. En cas d'erreur, boucle sur `DKA_SAPFRSDUPLI_ERROR_TMP`
3. Effectue un SELECT supplémentaire pour récupérer le nom de l'UO

**Si 10,000 sites sont traités** :
- 10,000 appels à `MAJ_SITE_FOURNISSEUR`
- Possiblement 10,000+ requêtes supplémentaires
- Pas de traitement par batch (COMMIT/ROLLBACK)

---

### **4. Absence de COMMIT intermédiaire** 🔴

Le code ne contient **AUCUN COMMIT** dans la boucle principale.

**Conséquence** :
- Une seule transaction pour tous les sites
- Occupation excessive de l'UNDO tablespace
- Risque de blocage d'autres traitements
- Impossible de reprendre en cas d'échec

---

### **5. Package appelé inconnu** ⚠️

Le traitement appelle `DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR` que nous n'avons pas analysé.

**Ce package pourrait** :
- Effectuer des opérations longues par site
- Contenir des boucles imbriquées
- Faire des appels externes (API, fichiers, etc.)
- Avoir des problèmes de performance

---

## 🔧 Vérifications immédiates à effectuer

### **1. Vérifier la date de dernière MAJ**
```sql
SELECT date_value,
       SYSDATE - date_value as jours_depuis_derniere_maj
FROM DKA_PARAMETERS
WHERE program_code = 'DKA_SAPFRSDUPLI_MAJ'
AND parameter_name = 'DATE_DERNIERE_MAJ';
```

### **2. Compter le nombre de sites à traiter**
```sql
SELECT COUNT(*) as nb_sites_a_traiter
FROM ap_supplier_sites_all assa
, ap_suppliers ass
, hr_operating_units hou
, iby_ext_bank_accounts ieb
, iby_pmt_instr_uses_all ipi
, iby_external_payees_all iep
, iby_ext_party_pmt_mthds ieppm
WHERE assa.vendor_id = ass.vendor_id
AND hou.organization_id = assa.org_id
AND hou.name = 'REF9999'
AND iep.ext_payee_id = ieppm.ext_pmt_party_id
AND iep.supplier_site_id(+) = assa.vendor_site_id
AND iep.ext_payee_id = ipi.ext_pmt_party_id(+)
AND ipi.instrument_id = ieb.ext_bank_account_id(+)
AND ipi.payment_function(+) = 'PAYABLES_DISB'
AND (ieppm.last_update_date > (SELECT date_value FROM DKA_PARAMETERS 
                                WHERE program_code = 'DKA_SAPFRSDUPLI_MAJ' 
                                AND parameter_name = 'DATE_DERNIERE_MAJ')
     OR assa.last_update_date > (SELECT date_value FROM DKA_PARAMETERS 
                                 WHERE program_code = 'DKA_SAPFRSDUPLI_MAJ' 
                                 AND parameter_name = 'DATE_DERNIERE_MAJ')
     OR ipi.LAST_UPDATE_DATE > (SELECT date_value FROM DKA_PARAMETERS 
                                WHERE program_code = 'DKA_SAPFRSDUPLI_MAJ' 
                                AND parameter_name = 'DATE_DERNIERE_MAJ')
     OR iep.LAST_UPDATE_DATE > (SELECT date_value FROM DKA_PARAMETERS 
                                WHERE program_code = 'DKA_SAPFRSDUPLI_MAJ' 
                                AND parameter_name = 'DATE_DERNIERE_MAJ'));
```

### **3. Vérifier si le traitement actuel progresse**
```sql
SELECT COUNT(*) as nb_sites_traites
FROM DKA_SAPFRSDUPLI_ERROR_TMP
WHERE creation_date >= TO_DATE('28/11/2025 07:00:00', 'DD/MM/YYYY HH24:MI:SS');
```

### **4. Analyser le package appelé**
```sql
SELECT text
FROM dba_source
WHERE name = 'DKA_SAPFRSDUPLI_PKG'
AND type = 'PACKAGE BODY'
AND UPPER(text) LIKE '%MAJ_SITE_FOURNISSEUR%'
ORDER BY line;
```

---

## 🚨 Actions recommandées

### **Immédiat (aujourd'hui)**

1. **TUER le traitement actuel (46351151)** s'il est bloqué
   ```sql
   -- Identifier la session
   SELECT s.sid, s.serial#
   FROM v$session s
   WHERE s.module LIKE '%46351151%';
   
   -- Tuer la session (à faire par le DBA)
   -- ALTER SYSTEM KILL SESSION 'sid,serial#' IMMEDIATE;
   ```

2. **Vérifier et corriger la date de dernière MAJ** si elle est anormale
   ```sql
   UPDATE DKA_PARAMETERS
   SET date_value = SYSDATE - 1/24  -- 1 heure avant
   WHERE program_code = 'DKA_SAPFRSDUPLI_MAJ'
   AND parameter_name = 'DATE_DERNIERE_MAJ';
   COMMIT;
   ```

3. **Désactiver temporairement l'exécution automatique** du programme

---

### **Court terme (cette semaine)**

1. **Analyser le package `DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR`**
2. **Optimiser le curseur** (index, statistiques, plan d'exécution)
3. **Ajouter des COMMIT intermédiaires** dans la boucle (tous les 100 sites par exemple)
4. **Ajouter des logs de progression** pour suivre l'avancement
5. **Limiter le nombre de sites traités** par exécution (max 1000 par exemple)

---

### **Moyen terme (ce mois)**

1. **Refactoriser le code** pour utiliser du traitement par lots (BULK COLLECT)
2. **Ajouter une gestion de reprise** en cas d'échec
3. **Créer des alertes** si la durée dépasse 5 minutes
4. **Paralléliser le traitement** si le volume le justifie
5. **Documenter les causes racines** et les corrections apportées

---

## 📝 Checklist de diagnostic

- [ ] Date de dernière MAJ vérifiée dans DKA_PARAMETERS
- [ ] Nombre de sites à traiter compté
- [ ] Package DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR analysé
- [ ] Logs du traitement 46304717 (hier) consultés
- [ ] Logs du traitement 46351151 (aujourd'hui) consultés
- [ ] Plan d'exécution du curseur SITE_A_MAJ analysé
- [ ] Index sur les tables de jointure vérifiés
- [ ] Statistiques des tables mises à jour
- [ ] Monitoring de l'UNDO tablespace effectué
- [ ] Équipe métier contactée pour comprendre les modifications massives

---

## 📞 Contacts

**Équipe technique** :
- DBA Oracle : dba@dalkia.fr
- Admin EBS : ebs-admin@dalkia.fr

**Équipe fonctionnelle** :
- Responsable Fournisseurs : ap-manager@dalkia.fr
- Auteur du package : Asma AMENKOUR (Capgemini)

---

**Analyse effectuée le** : 28/11/2025 à 15:00  
**Connexion** : oracleProd  
**Analyste** : GitHub Copilot (Claude Sonnet 4.5)
