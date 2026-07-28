# PROMPT DE REPRISE - Projet Réconciliation Factures Oracle BO

**Projet** : Synchronisation automatique des factures Oracle R12 vers BO (Business Objects)  
**Contexte** : Dalkia - Oracle EBS 12.2.13 - Base de données 19.25.0.0.0  
**Dernière mise à jour** : 19/02/2026

---

## 🎯 OBJECTIF DU PROJET

Forcer la synchronisation des factures non synchronisées entre Oracle et BO via mise à jour de `last_update_date` :
- **Oracle EBS R12** : Source de vérité pour les factures (module AP - table `ap_invoices_all`)
- **BO/Hercule** : Entrepôt de données décisionnel (table `DWH_ECHEANCIER_AP`)

**Problématique** : Des factures dans BO restent avec `statut_paiement <> 'PAYEE'` alors qu'elles sont payées/annulées dans Oracle.

**Solution développée** : Mettre à jour `last_update_date` dans Oracle pour forcer le dump BO quotidien à reprendre ces factures, puis restaurer les valeurs originales le lendemain.

---

## 📁 STRUCTURE DU PROJET

```
FichierNadia/
├── readme.md                           # Documentation métier originale
├── Analyse_Reconciliation_Factures_Oracle_BO.md  # Analyse technique complète (694 lignes)
├── Rapport_Verification_Factures_20260218.md     # Rapport d'analyse de 19 factures test
├── PROMPT_REPRISE_PROJET.md            # CE FICHIER
│
├── === SCRIPTS PRINCIPAUX (SYNCHRONISATION) ===
├── sync_factures_bo.bat                # ORCHESTRATEUR PRINCIPAL (.bat)
├── generer_scripts_sync.ps1            # Génère les scripts SQL de sync
├── executer_sql_sync.ps1               # Exécute les scripts SQL (backup/update/restore)
│
├── === SCRIPTS ANALYSE ===
├── extraction_factures_payees.ps1      # Extraction factures payées Oracle par année
├── reconciliation_factures.ps1         # Comparaison Oracle vs BO + génération écarts
├── analyse_detaillee_factures_impayees.ps1   # Analyse détaillée avec infos fournisseur
├── analyse_factures_impayees_batch.ps1       # Traitement par lots (> 1000 factures)
│
├── === DOSSIERS GÉNÉRÉS ===
├── sql_sync/                           # Scripts SQL générés (sauvegarde, update, restore)
├── backup/                             # Fichiers CSV de sauvegarde avant modification
├── logs/                               # Logs d'exécution
│
├── === DONNÉES D'ENTRÉE (BO) ===
├── factureImpayees/
│   ├── Factures impayees BO 2018.csv ... 2026.csv
│
├── === UTILITAIRES ===
├── decrypt.py                          # Décryptage mot de passe SQL Developer
└── env_oracle.sh                       # Variables environnement shell Unix
```

---

## 🔧 COMPOSANTS DÉVELOPPÉS

### 1. Script Principal : sync_factures_bo.bat

**ORCHESTRATEUR PRINCIPAL** - Fichier .bat qui pilote tout le processus :

```batch
:: USAGE :
sync_factures_bo.bat PREPARE 2025    :: Sauvegarde + MAJ last_update_date
sync_factures_bo.bat RESTORE 2025    :: Restaure les données originales
sync_factures_bo.bat STATUS 2025     :: Vérifie l'état des factures
sync_factures_bo.bat GENERATE 2025   :: Génère les scripts sans exécuter
```

### 2. Workflow de Synchronisation

```
┌─────────────────────────────────────────────────────────────────────┐
│  JOUR J (SOIR) : sync_factures_bo.bat PREPARE 2025                 │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ 1. Génère scripts SQL (generer_scripts_sync.ps1)            │   │
│  │ 2. Sauvegarde last_update_date actuelles → backup/*.csv     │   │
│  │ 3. UPDATE ap_invoices_all SET last_update_date = SYSDATE-1  │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  NUIT J→J+1 : Batch BO (Hercule)                                   │
│  Le dump BO détecte last_update_date = hier → synchronise          │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  JOUR J+1 (SOIR) : sync_factures_bo.bat RESTORE 2025               │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ 1. Lit le fichier backup/*.csv                              │   │
│  │ 2. Génère script restauration dynamique                     │   │
│  │ 3. UPDATE ap_invoices_all SET last_update_date = original   │   │
│  │ 4. Archive le fichier de sauvegarde                         │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### 3. Scripts PowerShell

| Script | Fonction | Usage |
|--------|----------|-------|
| `generer_scripts_sync.ps1` | Génère les 3 scripts SQL (sauvegarde, update, restore) | Appelé par sync_factures_bo.bat |
| `executer_sql_sync.ps1` | Exécute les scripts SQL via SQLcl/SQLPlus | Appelé par sync_factures_bo.bat |
| `extraction_factures_payees.ps1` | Extrait les factures payées Oracle pour une année | `.\extraction_factures_payees.ps1 -Annee 2026` |
| `reconciliation_factures.ps1` | Compare Oracle vs BO, génère rapport d'écarts | `.\reconciliation_factures.ps1 -Annee 2026` |

### 4. Scripts SQL Générés (dans sql_sync/)

| Script | Action |
|--------|--------|
| `01_sauvegarde_YYYY.sql` | Exporte invoice_id, last_update_date, last_updated_by vers CSV |
| `02_update_sync_YYYY.sql` | `UPDATE ap_invoices_all SET last_update_date = SYSDATE-1` |
| `03_restore_YYYY_*.sql` | Restaure les valeurs originales depuis le backup |

### 5. Configuration Oracle

```powershell
# Variables d'environnement recommandées (à définir avant exécution)
$env:ORACLE_USER = "aroux"
$env:ORACLE_PASSWORD = "***"  # Sécuriser !
$env:ORACLE_DSN = "prdscanc1pdb03.dalkia.net:1521/ebs_PDBFINP1"
```

**Clients SQL supportés** : `sqlcl`, `sql`, `sqlplus` (détection automatique)

---

## 🚀 GUIDE D'UTILISATION RAPIDE

### Cas 1 : Synchroniser les factures impayées 2025

```batch
:: Jour J (soir, après les heures de bureau)
cd C:\Users\schibout\Documents\plsql\FichierNadia
sync_factures_bo.bat PREPARE 2025

:: Vérifier que tout s'est bien passé
sync_factures_bo.bat STATUS 2025

:: Le batch BO de nuit synchronisera les factures

:: Jour J+1 (soir, après vérification que BO a bien synchronisé)
sync_factures_bo.bat RESTORE 2025
```

### Cas 2 : Générer les scripts sans exécuter (pour review)

```batch
sync_factures_bo.bat GENERATE 2025
:: Scripts disponibles dans : FichierNadia\sql_sync\
```

### Cas 3 : Vérifier l'état avant/après

```batch
sync_factures_bo.bat STATUS 2025
```

---

## 📊 REQUÊTES SQL CLÉS

### Script de Sauvegarde (généré)
```sql
SELECT 
    invoice_id || ';' || invoice_num || ';' ||
    TO_CHAR(last_update_date, 'YYYY-MM-DD HH24:MI:SS') || ';' ||
    last_updated_by || ';' || payment_status_flag
FROM ap_invoices_all
WHERE invoice_id IN (liste_ids_BO);
```

### Script de Mise à Jour (généré)
```sql
UPDATE ap_invoices_all
SET last_update_date = TRUNC(SYSDATE) - 1 + (12/24),  -- Hier à midi
    last_updated_by = -1  -- System
WHERE invoice_id IN (liste_ids_BO);
COMMIT;
```

### Script de Restauration (généré dynamiquement)
```sql
UPDATE ap_invoices_all
SET last_update_date = TO_DATE('2025-11-15 14:30:22', 'YYYY-MM-DD HH24:MI:SS'),
    last_updated_by = 1234
WHERE invoice_id = 12345678;
-- Répété pour chaque facture depuis le fichier backup
```

---

## ⚠️ POINTS D'ATTENTION

1. **Mot de passe** : Utiliser variables d'environnement `$env:ORACLE_PASSWORD` plutôt qu'en dur
2. **Sauvegarde obligatoire** : Ne JAMAIS faire UPDATE sans sauvegarde préalable
3. **Timing** : Exécuter PREPARE le soir, RESTORE le lendemain soir (après sync BO)
4. **Limite Oracle IN** : Les IDs sont découpés par lots de 1000 (limite clause IN)
5. **Client SQL** : Scripts détectent automatiquement sqlcl/sql/sqlplus
6. **Délimiteur CSV** : Fichiers BO peuvent utiliser `,` ou `;` - détection auto

---

## 📋 WORKFLOW RECOMMANDÉ

```
┌─────────────────────────────────────────────────────────────────────────┐
│ PRÉPARATION (unique)                                                    │
│  1. Placer le fichier BO "Factures impayees BO 2025.csv" dans          │
│     FichierNadia/factureImpayees/                                       │
│  2. Vérifier connexion Oracle : sync_factures_bo.bat STATUS 2025       │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ JOUR J - 18h00 : sync_factures_bo.bat PREPARE 2025                     │
│  → Sauvegarde créée dans backup/sauvegarde_factures_2025_*.csv         │
│  → Factures mises à jour avec last_update_date = hier                  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ NUIT J→J+1 : Batch BO automatique                                       │
│  → Le dump détecte les factures modifiées et les synchronise           │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ JOUR J+1 - Matin : Vérification dans BO                                │
│  → Confirmer que les factures sont bien passées à "PAYEE" ou "Annulé" │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ JOUR J+1 - 18h00 : sync_factures_bo.bat RESTORE 2025                   │
│  → Factures remises à leur état original                               │
│  → Fichier sauvegarde archivé dans backup/archive/                     │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🚧 DÉVELOPPEMENTS RESTANTS

### Fait ✅
- [x] Script orchestrateur .bat (sync_factures_bo.bat)
- [x] Génération automatique scripts SQL sauvegarde/update/restore
- [x] Gestion par lots (limite 1000 IDs clause IN Oracle)
- [x] Détection automatique client SQL (sqlcl/sql/sqlplus)
- [x] Archivage des sauvegardes après restauration
- [x] Logs d'exécution

### À faire 🔲
- [ ] Tests sur environnement de recette avant production
- [ ] Sécuriser credentials Oracle (vault, variables env, ou wallet)
- [ ] Intégration ControlM pour planification automatique
- [ ] Notification email après PREPARE et RESTORE
- [ ] Interface pour sélectionner les factures à synchroniser (filtre par statut)

---

## 🔗 TABLE ORACLE MODIFIÉE

| Table | Module | Colonnes impactées |
|-------|--------|-------------------|
| `AP_INVOICES_ALL` | AP | `last_update_date`, `last_updated_by` |

### Colonnes sauvegardées/restaurées
- `INVOICE_ID` : Clé primaire
- `INVOICE_NUM` : Numéro facture (pour vérification)
- `LAST_UPDATE_DATE_ORIGINAL` : Date MAJ avant modification
- `LAST_UPDATED_BY_ORIGINAL` : User ID avant modification
- `PAYMENT_STATUS_FLAG` : Statut paiement (info)

---

## 📞 CONTACTS MÉTIER

- **Hind** : Équipe Oracle R12 - Extraction factures payées quotidienne
- **Nadia** : Contrôle BO - Détection et remontée écarts
- **TMA** : Support technique - Analyse écarts

---

## 🛠️ COMMANDES UTILES

```batch
:: SYNCHRONISATION (workflow principal)
sync_factures_bo.bat PREPARE 2025    :: Jour J soir
sync_factures_bo.bat RESTORE 2025    :: Jour J+1 soir
sync_factures_bo.bat STATUS 2025     :: Vérification

:: GÉNÉRATION SCRIPTS UNIQUEMENT (review)
sync_factures_bo.bat GENERATE 2025
```

```powershell
# ANALYSE (scripts auxiliaires)
.\extraction_factures_payees.ps1 -Annee 2025
.\reconciliation_factures.ps1 -Annee 2025
.\analyse_detaillee_factures_impayees.ps1 -Annee 2025 -MaxFactures 100
```

---

## 📖 DOCUMENTATION DE RÉFÉRENCE

- [Analyse_Reconciliation_Factures_Oracle_BO.md](Analyse_Reconciliation_Factures_Oracle_BO.md) - Documentation technique complète (694 lignes)
- [Rapport_Verification_Factures_20260218.md](Rapport_Verification_Factures_20260218.md) - Résultats analyse 19 factures
- [readme.md](readme.md) - Procédure métier originale de Nadia

---

**Version** : 1.0  
**Auteur** : GitHub Copilot  
**Statut** : 🟡 En développement
