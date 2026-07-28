# Analyse Erreur OAE043 - Import Fichier de Paie

**Date d'analyse** : 22/01/2026  
**Package concerné** : `XXEAI.XXEAI_INTERFACE_TOOLS_PKG.GET_CLE_COMPTABLE_CUF`  
**Code erreur** : OAE043 - "Impossible de déterminer le code interco (segment5)"

---

## 1. Données en erreur

Extrait du fichier `fichierRejet.txt` :
```
GEN0001202601;29/01/2026;EUR;0001;641110;0;B00002613V;GK0458545Z;...;ECRITURES DE PAIE GENERALES;PRE;;SALAIRES & APPOINTEMENTS;...
```

| Champ | Valeur | Description |
|-------|--------|-------------|
| Société | `0001` | DALKIA (ledger_id = 2022) |
| Compte local | `641110` | SALAIRES & APPOINTEMENTS |
| Code affaire | `B00002613V` | Matricule salarié |
| Tâche projet | `GK0458545Z` | Code tâche projet |
| Folio | `PRE` | Écritures de paie |
| Application | `RHAPSODY` | Système source paie |

---

## 2. Localisation de l'erreur OAE043 dans le code

L'erreur **OAE043** est déclenchée à **2 endroits** dans la procédure `Get_Cle_Comptable_CUF` :

### Ligne 1498 - Échec de Get_region_DKCODE
```plsql
validate(nvl(vo_info_region.CODE_ERREUR, 'OAE000') = 'OAE000', vv_code_erreur, 'OAE043');
```
→ Cette erreur se produit si le code DKCODE ne peut pas être résolu en région.

### Ligne 1516 - Validation finale du segment5
```plsql
check_seg_value(vo_result.ledger_id, 'CODE_INTERCO', vo_result.segment5, 'OAE043');
```
→ Cette erreur se produit si la valeur calculée de `segment5` n'existe pas dans le jeu de valeurs `DAOPCCF_INTERCO`.

---

## 3. Logique de détermination du segment5 (lignes 1453-1516)

```
┌─────────────────────────────────────────────────────────────────┐
│ Compte 641110 dans DKA_COMPTE_MATRICULE ?                       │
│ → NON (v_test_cpt_mat = 0)                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Application = 'RHAPSODY' ?                                      │
│ → OUI (configuré dans DKA_PARAM_FOLIO_GL pour folio PRE)        │
│ → segment5 := '0'                                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Validation : check_seg_value(2022, 'CODE_INTERCO', '0')         │
│ → Valeur '0' existe dans DAOPCCF_INTERCO ? OUI ✓                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Vérifications effectuées

### 4.1 Configuration du folio PRE
```sql
SELECT NOM_APPLICATION FROM DKA_PARAM_FOLIO_GL WHERE FOLIO = 'PRE'
-- Résultat : RHAPSODY ✓
```

### 4.2 Valeur '0' dans CODE_INTERCO
```sql
SELECT * FROM DAOPCCF_INTERCO WHERE flex_value = '0'
-- Résultat : Existe, ENABLED_FLAG = 'Y' ✓
```

### 4.3 Compte 641110 dans DKA_COMPTE_MATRICULE
```sql
SELECT * FROM DKA_COMPTE_MATRICULE WHERE flex_value = '641110'
-- Résultat : N'existe PAS ✗
```

---

## 5. Hypothèse de la cause racine

### ⚠️ Le compte 641110 devrait-il être dans DKA_COMPTE_MATRICULE ?

D'après la modification **EDB281** (02/11/2023), si un compte est dans `DKA_COMPTE_MATRICULE`, alors :
```plsql
vo_result.segment5 := 'P' || po_info_cle.code_affaire;
-- Exemple : 'P' + 'B00002613V' = 'PB00002613V'
```

Cependant, la valeur `PB00002613V` **n'existe pas** dans le jeu de valeurs `DAOPCCF_INTERCO`.

### Scénario probable de l'erreur

1. Le compte `641110` (Salaires & Appointements) **n'est pas** dans `DKA_COMPTE_MATRICULE`
2. L'application **devrait** être RHAPSODY → segment5 = '0'
3. **MAIS** l'erreur est levée, ce qui suggère que :
   - Soit le folio n'est pas correctement lu
   - Soit une autre condition force l'entrée dans le bloc ELSE où `Get_region_DKCODE` échoue

### Bloc ELSE problématique (lignes 1485-1510)
```plsql
IF po_info_cle.CODE_AFFAIRE IS NOT NULL THEN
  IF length(po_info_cle.CODE_AFFAIRE) = 4
     AND TRANSLATE(po_info_cle.CODE_AFFAIRE,' 1234567890',' ') IS NULL THEN
    -- Code affaire = 4 chiffres → segment5 := 'XXX'||code_affaire
    
  ELSE
    -- Code affaire type matricule → appel Get_region_DKCODE
    vv_societe := substr(po_info_cle.CODE_AFFAIRE,-4,4);  -- '613V'
    vv_dkcode  := substr(po_info_cle.CODE_AFFAIRE,1,length-4);  -- 'B000026'
    
    Get_region_DKCODE(vv_dkcode, vo_info_region);
    validate(..., 'OAE043');  ← ERREUR ICI si Get_region_DKCODE échoue
```

Le code affaire `B00002613V` n'est **ni** 4 chiffres, **ni** un DKCODE valide, ce qui provoque l'erreur.

---

## 6. Solutions recommandées

### Option 1 : Ajouter le compte 641110 dans DKA_COMPTE_MATRICULE (si applicable)

Si les écritures de paie sur le compte 641110 doivent porter un matricule dans segment5 :
1. Ajouter `641110` au jeu de valeurs `DKA_COMPTE_MATRICULE`
2. Créer les valeurs `PB00002613V` (et autres matricules) dans `DAOPCCF_INTERCO`

### Option 2 : Forcer segment5 = '0' pour RHAPSODY (correction code)

Vérifier que la condition `vo_cst_flux_gl.application_name = 'RHAPSODY'` est bien évaluée **avant** le parsing du code_affaire.

### Option 3 : Vérifier l'intégrité des données source

S'assurer que le fichier de paie RHAPSODY envoie bien les bons champs dans le bon ordre.

---

## 7. Requête de diagnostic

```sql
-- Vérifier si le folio PRE est correctement paramétré
SELECT FFV.FLEX_VALUE AS FOLIO, 
       FFVD.NOM_APPLICATION
FROM APPS.FND_FLEX_VALUE_SETS FFVS
JOIN APPS.FND_FLEX_VALUES FFV ON (FFV.FLEX_VALUE_SET_ID = FFVS.FLEX_VALUE_SET_ID)
JOIN APPS.FND_FLEX_VALUES_DFV FFVD ON (FFV.rowid = FFVD.row_id)
WHERE FFVS.FLEX_VALUE_SET_NAME = 'DKA_PARAM_FOLIO_GL'
AND FFV.VALUE_CATEGORY = 'DKA_PARAM_FOLIO_GL'
AND FFV.FLEX_VALUE = 'PRE';

-- Vérifier si le compte devrait être dans DKA_COMPTE_MATRICULE
SELECT ffv.flex_value, ffv.description
FROM APPS.fnd_flex_values_vl ffv
JOIN APPS.fnd_flex_value_sets ffvs ON ffvs.flex_value_set_id = ffv.flex_value_set_id
WHERE ffvs.flex_value_set_name = 'DKA_COMPTE_MATRICULE'
AND ffv.flex_value LIKE '64%'
ORDER BY ffv.flex_value;
```

---

## 8. Résumé

| Élément | Statut | Commentaire |
|---------|--------|-------------|
| Folio PRE configuré | ✅ | NOM_APPLICATION = RHAPSODY |
| Valeur '0' dans DAOPCCF_INTERCO | ✅ | Existe et active |
| Compte 641110 dans DKA_COMPTE_MATRICULE | ❌ | Absent |
| Code affaire B00002613V reconnu | ❌ | Ni 4 chiffres, ni DKCODE valide |

**Cause probable** : Le code entre dans le bloc ELSE (non-RHAPSODY ou non-matricule) et échoue sur `Get_region_DKCODE` car `B00002613V` n'est pas un DKCODE valide.

**Action recommandée** : Vérifier si le compte 641110 doit être ajouté à `DKA_COMPTE_MATRICULE` et créer les valeurs matricules correspondantes dans `DAOPCCF_INTERCO`.
