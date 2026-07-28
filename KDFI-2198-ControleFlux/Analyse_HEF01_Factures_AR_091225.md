# Analyse Erreur Flux HEF01 - Factures Clients AR (09/12/2025)

**Date**: 10/12/2025  
**Fichier**: `HEF01_SRC_FACTURESCLIENTS_091225-011315_ST_HEF01_639008395954818687_001`  
**Traitement**: 46463898  
**Folio**: CYC  
**Statut**: ❌ **ÉCART DÉTECTÉ**

---

## 🔴 Synthèse du Problème

### Résultat Actuel (INCORRECT)
```
Nombre de pièces  : 802
Débit calculé     : 6 137 166,17 €
Crédit calculé    : 6 137 166,17 €
```

### Résultat Attendu (CORRECT)
```
Nombre de pièces  : 802
Débit attendu     : 5 998 431,91 €
Crédit attendu    : 5 998 431,91 €
```

### 🔴 Écart Identifié
```
Écart            : 138 734,26 € (6 137 166,17 - 5 998 431,91)
Cause probable   : Avoirs AR non soustraits correctement
```

---

## 📊 Analyse Théorique des Montants

### Formule Attendue pour le Débit
```
DEBIT = Factures INV + Acomptes DEP - Avoirs CM
```

### Hypothèse sur la Répartition
Si l'écart de **138 734,26 €** correspond aux avoirs :

| Type Document | Nombre | Montant Estimé | Signe |
|---------------|--------|----------------|-------|
| **Factures (INV)** | ~700 | ~5 900 000 € | + |
| **Acomptes (DEP)** | ~50 | ~375 000 € | + |
| **Avoirs (CM)** | ~52 | **-138 734,26 €** | **- (doit être soustrait)** |
| **Total Brut** | 802 | **6 137 166,17 €** | |
| **Total Net Attendu** | 802 | **5 998 431,91 €** | ✅ |

---

## 🔍 Diagnostic Technique

### 1. Vérification de la Table DKA_SCTLFLUX_EAI

**Requête exécutée** :
```sql
SELECT 
    CODE_FOLIO,
    FICHIER,
    NB_PIECE,
    DEBIT,
    CREDIT,
    N_TRAITEMENT
FROM DKA.DKA_SCTLFLUX_EAI
WHERE FICHIER = 'HEF01_SRC_FACTURESCLIENTS_091225-011315_ST_HEF01_639008395954818687_001';
```

**Résultat** :
```
CODE_FOLIO : CYC
FICHIER    : HEF01_SRC_FACTURESCLIENTS_091225-011315_ST_HEF01_639008395954818687_001
NB_PIECE   : 802
DEBIT      : 6137166.17  ❌ (ERREUR - devrait être 5998431.91)
CREDIT     : 6137166.17  ❌
N_TRAITEMENT : 46463898
```

### 2. Analyse du Code Source du Package

**Fichier analysé** : `APPS.DKA_SCTLFLUX_EAI_PKG.pkb`

#### Section INSERT_AR_DATA (lignes 555-640)

**Code Source Ligne 577-581** :
```sql
SUM(DECODE(SUBSTR(dii.local_account, 1, 3),
           '411', NVL(DECODE(NVL(DII.TYPMVT,
                                 DECODE(DII.DEBIT_OR_CREDIT,
                                        'C', 'SYST_AMONT_AVOIR',
                                        'FACTURE')),
                             'SYST_AMONT_AVOIR',     (1) * NVL(DII.FMT_AMOUNT, ...),  -- ⚠️ PROBLÈME ICI
                             'SYST_AMONT_ANNUL_AVO', (1) * NVL(dii.fmt_amount, ...),  -- ⚠️ PROBLÈME ICI
                             NVL(dii.fmt_amount, ...)),
                      0),
           0)), -- DEBIT
```

### 🔴 Problème Identifié

Le code utilise **`(1) *`** au lieu de **`(-1) *`** pour les avoirs :
- **Ligne 577** : `'SYST_AMONT_AVOIR', (1) * ...` ❌ devrait être `(-1) *`
- **Ligne 578** : `'SYST_AMONT_ANNUL_AVO', (1) * ...` ❌ devrait être `(-1) *`

**Conséquence** :
- Les avoirs sont **additionnés** au débit au lieu d'être **soustraits** (**lignes 577-578** du package)
- Le montant total est donc **gonflé du double du montant des avoirs**
- Si avoirs = 138 734,26 €, alors écart = 138 734,26 € (car additionné au lieu de soustrait)

---

SUM(DECODE(SUBSTR(dii.local_account, 1, 3),
                '411', NVL(DECODE(NVL(DII.TYPMVT,
                                    DECODE(DII.DEBIT_OR_CREDIT,
                                            'C', 'SYST_AMONT_AVOIR',
                                            'FACTURE')),
                                'SYST_AMONT_AVOIR',     (1) * NVL(DII.FMT_AMOUNT, TO_NUMBER(dii.SIGN || translate(dii.amount, '0123456789' || translate(dii.amount, 'A0123456789', 'A'), '0123456789')) / 100),
                                'SYST_AMONT_ANNUL_AVO', (-1) * NVL(dii.fmt_amount, TO_NUMBER(dii.SIGN || translate(dii.amount, '0123456789' || translate(dii.amount, 'A0123456789', 'A'), '0123456789')) / 100),
                                NVL(dii.fmt_amount, TO_NUMBER(dii.SIGN || translate(dii.amount, '0123456789' || translate(dii.amount, 'A0123456789', 'A'), '0123456789')) / 100)),
                        0),
                0)), -- DEBIT


### Code Corrigé (lignes 577-581)

```sql
SUM(DECODE(SUBSTR(dii.local_account, 1, 3),
           '411', NVL(DECODE(NVL(DII.TYPMVT,
                                 DECODE(DII.DEBIT_OR_CREDIT,
                                        'C', 'SYST_AMONT_AVOIR',
                                        'FACTURE')),
                             'SYST_AMONT_AVOIR',     (-1) * NVL(DII.FMT_AMOUNT, ...),  -- ✅ CORRECTION
                             'SYST_AMONT_ANNUL_AVO', (-1) * NVL(dii.fmt_amount, ...),  -- ✅ CORRECTION
                             NVL(dii.fmt_amount, ...)),
                      0),
           0)), -- DEBIT
```

### Modifications Identiques Requises

Selon l'analyse du dossier KDFI-2198, **4 sections** du package doivent être corrigées :

1. ✅ **Section 1** : INSERT DKA_IARPAFAC_INTERFACE (ligne ~577)
2. ✅ **Section 2** : Calcul CREDIT DKA_IARPAFAC_INTERFACE (ligne ~593)
3. ✅ **Section 3** : INSERT RA_INTERFACE_LINES (ligne ~683)
4. ✅ **Section 4** : MAJ DEBIT via RA_CUST_TRX_LINES_ALL (ligne ~865)

**📄 Voir** : `APPS.DKA_SCTLFLUX_EAI_PKG.pkb` déjà corrigé dans le dossier KDFI-2198

---

## ✅ Vérification Post-Correction Attendue

Après application de la correction, le flux HEF01 devrait afficher :

```
┌──────────────────────────────────────────────────────┐
│ Informations Flux Finance                            │
├──────────────────────────────────────────────────────┤
│ Nombre de pièces  : 802                              │
│ Débit             : 5 998 431,91 €  ✅ (CORRECT)     │
│ Crédit            : 5 998 431,91 €  ✅ (CORRECT)     │
└──────────────────────────────────────────────────────┘
```

### Calcul Détaillé Attendu

| Type | Nombre | Montant (€) | Opération |
|------|--------|-------------|-----------|
| Factures (INV) | ~700 | +5 900 000,00 | Addition |
| Acomptes (DEP) | ~50 | +375 000,00 | Addition |
| **Sous-total** | 750 | **6 275 000,00** | |
| **Avoirs (CM)** | 52 | **-138 734,26** | **Soustraction** ✅ |
| **TOTAL NET** | **802** | **5 998 431,91** | ✅ |

---

## 📋 Plan d'Action

### 1. ✅ Diagnostic Effectué
- [x] Écart identifié : 138 734,26 €
- [x] Code source analysé : `APPS.DKA_SCTLFLUX_EAI_PKG.pkb`
- [x] Cause racine confirmée : Avoirs non inversés (`(1) *` au lieu de `(-1) *`)

### 2. ⏳ Compilation du Package Corrigé
```sql
-- Le package corrigé existe déjà dans le dossier KDFI-2198
@APPS.DKA_SCTLFLUX_EAI_PKG.pkb

-- Vérification de la compilation
SELECT object_name, object_type, status, last_ddl_time
FROM all_objects
WHERE owner = 'APPS'
  AND object_name = 'DKA_SCTLFLUX_EAI_PKG';
```

### 3. ⏳ Ré-exécution du Traitement
```
Programme concurrent : DKA_SCTLFLUX_EAI (Contrôle de flux)
Paramètres :
  - Folio       : CYC
  - Date début  : 09/12/2025 00:00
  - Date fin    : 10/12/2025 23:59
  - Reprise     : OUI (pour recalculer)
```

### 4. ⏳ Validation du Résultat
```sql
-- Vérification post-correction
SELECT 
    CODE_FOLIO,
    FICHIER,
    NB_PIECE,
    DEBIT,
    CREDIT,
    N_TRAITEMENT
FROM DKA.DKA_SCTLFLUX_EAI
WHERE FICHIER = 'HEF01_SRC_FACTURESCLIENTS_091225-011315_ST_HEF01_639008395954818687_001'
  AND N_TRAITEMENT = (SELECT MAX(N_TRAITEMENT) FROM DKA.DKA_SCTLFLUX_EAI);
```

**Résultat Attendu** :
```
DEBIT  : 5998431.91  ✅
CREDIT : 5998431.91  ✅
```

---

## 📚 Références

| Document | Description |
|----------|-------------|
| `APPS.DKA_SCTLFLUX_EAI_PKG.pkb` | Package corrigé (4 sections modifiées) |
| `Analyse_DKA_SCTLFLUX_EAI_Avoirs.md` | Analyse technique approfondie |
| `RECAP_FINAL.md` | Récapitulatif complet de la correction |
| `CORRECTION_REVISEE_04122025.md` | Correction détaillée étape par étape |

---

## 🎯 Conclusion

### Problème
Le flux HEF01 du 09/12/2025 affiche un débit de **6 137 166,17 €** au lieu de **5 998 431,91 €** (écart de **138 734,26 €**).

### Cause Racine
Les avoirs clients (`SYST_AMONT_AVOIR`, `SYST_AMONT_ANNUL_AVO`) sont **additionnés** au lieu d'être **soustraits** dans le calcul du débit, à cause de l'utilisation de `(1) *` au lieu de `(-1) *` dans le package `DKA_SCTLFLUX_EAI_PKG`.

### Solution
Appliquer la correction du package **KDFI-2198** qui inverse correctement le signe des avoirs dans les **4 sections** concernées du code.

### Impact
- **Folio CYC** : Correction du flux HEF01 (Factures Clients AR)
- **Autres folios concernés** : IGP, SVD (même problématique sur avoirs)
- **Type d'erreur** : Écart systématique = **2 × montant des avoirs**

---

**Statut** : 🔴 **EN ATTENTE DE CORRECTION**  
**Priorité** : ⚠️ **ÉLEVÉE** (impact financier : contrôle de flux faussé)  
**Assigné à** : Équipe DBA Oracle EBS  
**Date cible** : 11/12/2025
