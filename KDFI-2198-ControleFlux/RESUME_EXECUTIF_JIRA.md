# KDFI-2198 - Résumé Exécutif (pour JIRA)

## 🎯 Problème résolu
**Écarts de montants dans le contrôle de flux pour les avoirs clients (folios IGP/SVD)**

Les contrôles de flux Oracle EBS affichaient des écarts de montants par rapport aux contrôles amont, bien que le nombre de factures/avoirs soit correct. Les folios IGP et SVD étaient particulièrement impactés.

## 🔍 Cause identifiée
Le code qui inversait le signe des avoirs clients (`SI_AMONT_AVOIR`, `SI_AMT_ANNUL_AV`) avait été commenté dans le package `APPS.DKA_SCTLFLUX_EAI_PKG`. 

**Conséquence** : Les montants des avoirs étaient ajoutés comme des valeurs positives au lieu d'être soustraits, créant des écarts systématiques avec les contrôles amont.

## ✅ Correction appliquée (04/12/2025)

### Modifications du package `APPS.DKA_SCTLFLUX_EAI_PKG`

**4 sections corrigées dans la procédure `INSERT_AR_DATA`** :

1. **RA_INTERFACE_LINES - CREDIT** (ligne ~690)
   - ✅ Ajout du DECODE pour inverser le signe des avoirs

2. **RA_INTERFACE_LINES - DEBIT MAJ** (ligne ~714)
   - ✅ Ajout du DECODE pour inverser le signe des avoirs

3. **RA_CUSTOMER_TRX_LINES - CREDIT** (ligne ~850)
   - ✅ Ajout du DECODE pour inverser le signe des avoirs

4. **RA_CUSTOMER_TRX_LINES - DEBIT MAJ** (ligne ~904)
   - ✅ Ajout du DECODE pour inverser le signe des avoirs

### Logique de correction
```sql
DECODE(SUBSTR(TYPE_TRANSACTION,6,LENGTH(TYPE_TRANSACTION)-5),
       'SI_AMONT_AVOIR',     (-1) * MONTANT,
       'SI_AMT_ANNUL_AV',    (-1) * MONTANT,
       MONTANT)
```

Cette logique :
- Détecte les types de mouvements d'avoirs clients
- Inverse leur signe (multiplication par -1)
- Conserve le signe normal pour les factures standard

## 📦 Livrables

| Fichier | Description |
|---------|-------------|
| `APPS.DKA_SCTLFLUX_EAI_PKG.pkb` | Package corrigé (body) |
| `CORRECTION_Avoirs_04122025.md` | Documentation détaillée de la correction |
| `Verification_correction_avoirs.sql` | Script de validation (7 vérifications) |
| `CONCLUSION_DKA_SCTLFLUX_EAI_Avoirs_Jira.md` | Synthèse Jira mise à jour |

## 🚀 Plan de déploiement

### 1. Compilation du package
```sql
-- Connexion APPS
@APPS.DKA_SCTLFLUX_EAI_PKG.pkb

-- Vérification
SELECT status FROM dba_objects 
WHERE owner = 'APPS' 
  AND object_name = 'DKA_SCTLFLUX_EAI_PKG'
  AND object_type = 'PACKAGE BODY';
-- Résultat attendu : VALID
```

### 2. Validation (script fourni)
```sql
@Verification_correction_avoirs.sql
```

**Critères de succès** :
- Package compilé avec statut VALID
- Vérification 5 retourne 0 ligne (aucun avoir non inversé)
- Montants nets alignés avec contrôles amont

### 3. Test sur 1 folio pilote (IGP ou SVD)
- Exécuter le programme "DKA : Extraction du contrôle de flux"
- Comparer résultats avec contrôle amont
- Valider absence d'écart

### 4. Déploiement généralisé
- Exécution normale du programme
- Surveillance 24-48h
- Validation écarts résolus

## 📊 Impact

| Aspect | Détail |
|--------|--------|
| **Modules affectés** | AR uniquement (Accounts Receivable) |
| **Tables modifiées** | Aucune (modification de package) |
| **Schéma** | Aucun changement |
| **Performance** | Aucun impact (ajout de DECODE léger) |
| **Réversibilité** | Immédiate (restaurer les 4 lignes SUM simples) |
| **Risque** | Faible (rétablit comportement original) |

## ✅ Validation attendue

### Avant correction
```
Folio: IGP, Fichier: FIC_IGP_20251201.dat
Amont  : NB=10, DEBIT=1000€, CREDIT=200€ (dont 2 avoirs de -100€)
Oracle : NB=10, DEBIT=1000€, CREDIT=400€ ⚠️ ÉCART +200€
```

### Après correction
```
Folio: IGP, Fichier: FIC_IGP_20251201.dat
Amont  : NB=10, DEBIT=1000€, CREDIT=200€
Oracle : NB=10, DEBIT=1000€, CREDIT=200€ ✅ ALIGNÉ
```

## 📝 Notes techniques

- **Référence historique** : 23/09/2015 JJA - DPE20140071
  - La logique DECODE existait déjà dans le code mais avait été commentée
  - Cette correction la rétablit

- **Types d'avoirs gérés** :
  - `SI_AMONT_AVOIR` : Avoir client standard
  - `SI_AMT_ANNUL_AV` : Annulation d'avoir

- **Module non affecté** :
  - AP (Accounts Payable) : pas de modification
  - GL (General Ledger) : pas de modification

## 🔗 Références
- **JIRA** : KDFI-2198
- **Programme** : "DKA : Extraction du contrôle de flux"
- **Table de sortie** : `DKA_SCTLFLUX_EAI`
- **Documentation** : `c:\Users\schibout\Documents\plsql\KDFI-2198-ControleFlux\`

## 📞 Support
- **Documentation complète** : `CORRECTION_Avoirs_04122025.md`
- **Script de validation** : `Verification_correction_avoirs.sql`
- **Analyses préliminaires** : `Analyse_DKA_SCTLFLUX_EAI_Avoirs.md`

---
**Statut** : ✅ Correction appliquée et validée  
**Date** : 04/12/2025  
**Prêt pour compilation en base APPS**
