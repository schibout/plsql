# Analyse Erreur ORA-00904 - Control_Fournisseur.sql

**Date d'analyse** : 04/05/2026  
**Auteur** : S. Chibout  
**Base de données** : Oracle EBS 12.2.13 (19.25.0.0.0)

---

## 1. Erreur Rencontrée

```
cx_Oracle.DatabaseError: ORA-00904: "PV"."PAY_GROUP_LOOKUP_CODE": invalid identifier
```

**Contexte** : Exécution de la requête `Control_Fournisseur.sql` depuis le lanceur central.

---

## 2. Cause Racine

### 2.1 Analyse du problème

La requête accède à `PAY_GROUP_LOOKUP_CODE` via l'alias `PV` qui pointe sur **`AP.AP_SUPPLIERS`** (schéma AP, table de base) :

```sql
FROM AP.AP_SUPPLIERS PV
...
PV.PAY_GROUP_LOOKUP_CODE
```

En Oracle EBS 12.2, la colonne `PAY_GROUP_LOOKUP_CODE` n'est **pas exposée** directement par la table de base `AP.AP_SUPPLIERS`. Elle est accessible uniquement via :

- La vue applicative **`APPS.AP_SUPPLIERS`** (synonym géré par le schéma APPS)
- Ou en passant par **`AP.AP_SUPPLIER_SITES_ALL`** au niveau des sites

### 2.2 Confirmation

```sql
-- Vérification de la présence de la colonne sur la table de base
SELECT COLUMN_NAME
FROM ALL_TAB_COLUMNS
WHERE TABLE_NAME = 'AP_SUPPLIERS'
  AND OWNER = 'AP'
  AND COLUMN_NAME = 'PAY_GROUP_LOOKUP_CODE';
-- → 0 ligne : colonne absente du schéma AP

-- Vérification sur la vue APPS
SELECT COLUMN_NAME
FROM ALL_TAB_COLUMNS
WHERE TABLE_NAME = 'AP_SUPPLIERS'
  AND OWNER = 'APPS'
  AND COLUMN_NAME = 'PAY_GROUP_LOOKUP_CODE';
-- → 1 ligne : colonne présente via la vue APPS
```

### 2.3 Occurrences dans la requête

La colonne `PAY_GROUP_LOOKUP_CODE` est référencée dans les sections suivantes :

| Section | Code Contrôle | Utilisation |
|---------|--------------|-------------|
| UNION 1 | 01_TYPE_ET_CLASSE_RGLT_INCOHERENTS | SELECT + WHERE (conditions EMPLOYE/GROUPEDKA/GROUPEHORSDKA/TIERS) |
| UNION 4 | 04_PAS_DE_TYPE_FOURNISSEUR | SELECT |
| UNION 9 | 09_CLASSE_RGLT_NON_VALIDE | SELECT + WHERE NOT IN |

---

## 3. Correction Appliquée

### Substitution de schéma

Remplacer toutes les occurrences de `AP.AP_SUPPLIERS` par `APPS.AP_SUPPLIERS` :

```sql
-- AVANT (erreur)
FROM AP.AP_SUPPLIERS PV

-- APRÈS (corrigé)
FROM APPS.AP_SUPPLIERS PV
```

Cette correction s'applique sur **toutes les occurrences** dans les UNION ALL (sections 01, 02, 04, 05, 06, 08, 09, 10, 11).

> La vue `APPS.AP_SUPPLIERS` expose l'ensemble des colonnes du fournisseur incluant `PAY_GROUP_LOOKUP_CODE`, contrairement à la table de base `AP.AP_SUPPLIERS`.

---

## 4. Fichier Corrigé

Voir : `Control_Fournisseur_CORRIGEE.sql` dans ce dossier.

---

## 5. Vérification Post-Correction

```sql
-- Test rapide : vérifier l'accès à PAY_GROUP_LOOKUP_CODE via APPS
SELECT PV.SEGMENT1, PV.VENDOR_NAME, PV.PAY_GROUP_LOOKUP_CODE
FROM APPS.AP_SUPPLIERS PV
WHERE ROWNUM <= 5;
-- Doit retourner des lignes sans ORA-00904
```
