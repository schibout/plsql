# Mapping Complet : Fichier Source → Oracle AR

**Date** : 12/01/2026  
**Incident** : REQUEST_ID 46750251 - ORA-00001 violation de contrainte unique

---

## 1. Flux de Données

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           FICHIER SOURCE (FAC02/GCA)                            │
│  FAC02_SRC_FACTURESCLIENTS_090126-024105_ST_FAC02_639035232651221257_001        │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    TABLE STAGING : DKA.DKA_IARPAFAC_INTERFACE                   │
│  Colonnes : ORIGIN, COMPANY_CODE, INVOICE_NUMBER, LINE_NUMBER, TASK_CODE,      │
│             LINE_TYPE, FMT_AMOUNT, DESCRIPTION, FIC_IDENT, OA_STATUS...        │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        │  Package DKA_IARPAFAC_PKG
                                        │  (Transformation & Insertion)
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    TABLE INTERFACE : AR.RA_INTERFACE_LINES_ALL                  │
│  Contrainte unique : DKA_RA_INTERFACE_LINES_U1                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        │  AutoInvoice (Programme Oracle Standard)
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    FACTURES AR : AR.RA_CUSTOMER_TRX_ALL                         │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Mapping Détaillé des Colonnes

### Fichier Source → Table Staging

| Champ Fichier | Colonne DKA_IARPAFAC_INTERFACE | Exemple |
|---------------|--------------------------------|---------|
| Origine       | ORIGIN                         | GCA     |
| Société       | COMPANY_CODE                   | 0001    |
| N° Facture    | INVOICE_NUMBER                 | 0001S2601P211 |
| N° Ligne      | LINE_NUMBER                    | 1       |
| Code Tâche    | TASK_CODE                      | GL0012100A |
| Type Ligne    | LINE_TYPE                      | PRODUIT |
| Montant       | FMT_AMOUNT                     | 7517 (centimes) |
| Description   | DESCRIPTION                    | 3049552T 101 |

### Table Staging → Table Interface Oracle AR

| Colonne DKA_IARPAFAC_INTERFACE | Colonne RA_INTERFACE_LINES_ALL | Dans Index Unique ? |
|--------------------------------|--------------------------------|---------------------|
| (fixe)                         | INTERFACE_LINE_CONTEXT         | ✅ Position 1 |
| **ORIGIN**                     | **INTERFACE_LINE_ATTRIBUTE1**  | ✅ Position 2 |
| **COMPANY_CODE**               | **INTERFACE_LINE_ATTRIBUTE2**  | ✅ Position 3 |
| **INVOICE_NUMBER**             | **INTERFACE_LINE_ATTRIBUTE3**  | ✅ Position 4 |
| **LINE_NUMBER**                | **INTERFACE_LINE_ATTRIBUTE4**  | ✅ Position 5 ⚠️ **PROBLÈME** |
| (période YYYYMM)               | **INTERFACE_LINE_ATTRIBUTE5**  | ✅ Position 6 |
| (ID exécution)                 | **REQUEST_ID**                 | ✅ Position 7 |
| FMT_AMOUNT                     | AMOUNT                         | ❌ Non |
| DESCRIPTION                    | DESCRIPTION                    | ❌ Non |
| TASK_CODE                      | INTERFACE_LINE_ATTRIBUTE6+     | ❌ Non |

---

## 3. Mise en Évidence de l'Erreur

### Données dans le Fichier Source

Pour la facture **0001S2601P211**, le fichier contient :

| Ligne | ORIGIN | COMPANY | INVOICE_NUMBER | LINE_NUMBER | MONTANT (€) | TASK_CODE |
|-------|--------|---------|----------------|-------------|-------------|-----------|
| 1     | GCA    | 0001    | 0001S2601P211  | **1**       | 75,17       | GL0012100A |
| 2     | GCA    | 0001    | 0001S2601P211  | **1**       | 100,16      | GL0012100A |
| 3     | GCA    | 0001    | 0001S2601P211  | **1**       | 201,45      | GL0012100A |
| 4     | GCA    | 0001    | 0001S2601P211  | **1**       | 300,69      | GL0012100A |
| 5     | GCA    | 0001    | 0001S2601P211  | **1**       | 400,64      | GL0012100A |
| 6     | GCA    | 0001    | 0001S2601P211  | **1**       | 805,78      | GL0012100A |
| 7     | GCA    | 0001    | 0001S2601P211  | **1**       | 3 941,54    | GL0012100A |

### Clé Unique Générée

Toutes ces lignes génèrent **LA MÊME CLÉ** dans l'index :

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  INTERFACE_LINE_CONTEXT  = 'DKA_IARPAFAC'                                       │
│  INTERFACE_LINE_ATTRIBUTE1 = 'GCA'           (ORIGIN)                           │
│  INTERFACE_LINE_ATTRIBUTE2 = '0001'          (COMPANY_CODE)                     │
│  INTERFACE_LINE_ATTRIBUTE3 = '0001S2601P211' (INVOICE_NUMBER)                   │
│  INTERFACE_LINE_ATTRIBUTE4 = '1'             (LINE_NUMBER) ← ⚠️ IDENTIQUE !    │
│  INTERFACE_LINE_ATTRIBUTE5 = '202601'        (Période)                          │
│  REQUEST_ID               = 46750251                                            │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Résultat

```
Insertion ligne 1 → ✅ Succès
Insertion ligne 2 → ❌ ORA-00001: violation de contrainte unique (AR.DKA_RA_INTERFACE_LINES_U1)
Insertion ligne 3 → ❌ (non tentée, programme arrêté)
...
```

---

## 4. Cause Racine

### Le Problème

Le fichier source **FAC02** génère plusieurs lignes de détail avec le **même LINE_NUMBER = 1** alors qu'elles représentent des lignes distinctes avec des montants différents.

### Impact

- **22 factures** impactées
- **91 lignes** en situation de doublon
- Programme en erreur, lignes non traitées

---

## 5. Suggestions de Correction

### Option A : Correction à la Source (RECOMMANDÉE)

**Action** : Modifier le système source FAC02/GCA pour générer des LINE_NUMBER uniques.

| Avant (Actuel) | Après (Corrigé) |
|----------------|-----------------|
| LINE_NUMBER = 1 | LINE_NUMBER = 1 |
| LINE_NUMBER = 1 | LINE_NUMBER = 2 |
| LINE_NUMBER = 1 | LINE_NUMBER = 3 |
| LINE_NUMBER = 1 | LINE_NUMBER = 4 |
| LINE_NUMBER = 1 | LINE_NUMBER = 5 |
| LINE_NUMBER = 1 | LINE_NUMBER = 6 |
| LINE_NUMBER = 1 | LINE_NUMBER = 7 |

**Avantages** :
- Corrige le problème à la racine
- Pas de modification du code Oracle
- Cohérence des données

**Responsable** : Équipe FAC02/GCA

---

### Option B : Correction dans le Package DKA_IARPAFAC_PKG

**Action** : Modifier le package pour utiliser un compteur séquentiel au lieu du LINE_NUMBER du fichier.

```sql
-- Code actuel (problématique)
pr_rec_line.line_number,  -- Interface_Line_Attribute4

-- Code corrigé (proposition)
pn_line_num_cnt,          -- Interface_Line_Attribute4 (compteur séquentiel)
```

**Avantages** :
- Correction rapide côté Oracle
- Pas de dépendance avec l'équipe source

**Inconvénients** :
- Perte de traçabilité avec le numéro de ligne source
- Nécessite validation métier

**Responsable** : Équipe EBS / DBA

---

### Option C : Ajouter le Montant dans la Clé (NON RECOMMANDÉE)

**Action** : Créer un nouvel index unique incluant AMOUNT ou un identifiant supplémentaire.

**Inconvénients** :
- Modification de la structure Oracle standard
- Risque d'effets de bord
- Complexité accrue

---

## 6. Action Immédiate (Purge des Rejets)

Pour débloquer le traitement des 126 153 lignes en attente :

```sql
-- 1. Vérifier les lignes rejetées
SELECT COUNT(*) FROM DKA.DKA_IARPAFAC_INTERFACE WHERE OA_STATUS = 'R';

-- 2. Supprimer les lignes rejetées
DELETE FROM DKA.DKA_IARPAFAC_INTERFACE WHERE OA_STATUS = 'R';
COMMIT;

-- 3. Relancer le programme DKA_IARPAFAC
-- (via Oracle EBS Concurrent Manager)
```

⚠️ **Attention** : Cette action purge les lignes en erreur mais ne corrige pas la cause racine. Les prochains fichiers avec le même problème échoueront à nouveau.

---

## 7. Résumé

| Élément | Valeur |
|---------|--------|
| **Cause** | LINE_NUMBER non unique dans le fichier source |
| **Impact** | 22 factures / 91 lignes |
| **Correction recommandée** | Modifier le système source FAC02/GCA |
| **Correction alternative** | Modifier le package DKA_IARPAFAC_PKG |
| **Action immédiate** | Purger les lignes OA_STATUS = 'R' |
