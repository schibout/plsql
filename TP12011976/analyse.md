# Analyse Incident DKA_IARPAFAC - TP12011976

## Informations du ticket

| Attribut | Valeur |
|----------|--------|
| **Programme** | DKA_IARPAFAC (DKA : Import des Factures clients) |
| **REQUEST_ID** | 46750251 |
| **Statut** | Terminé - Erreur |
| **Date début** | 09/01/2026 19:12:27 |
| **Date fin** | 09/01/2026 19:18:16 |
| **Durée** | ~6 minutes |

---

## Erreur rencontrée

```
ORA-00001: violation de contrainte unique (AR.DKA_RA_INTERFACE_LINES_U1)
Une erreur est survenue lors des contrôles d'une ligne de facture.
Veuillez contacter le support technique
```

---

## Analyse de la cause racine

### 1. Contrainte unique violée

La contrainte `AR.DKA_RA_INTERFACE_LINES_U1` est un index unique sur la table `AR.RA_INTERFACE_LINES_ALL` portant sur les colonnes :

| Position | Colonne |
|----------|---------|
| 1 | INTERFACE_LINE_CONTEXT |
| 2 | INTERFACE_LINE_ATTRIBUTE1 |
| 3 | INTERFACE_LINE_ATTRIBUTE2 |
| 4 | INTERFACE_LINE_ATTRIBUTE3 |
| 5 | INTERFACE_LINE_ATTRIBUTE4 |
| 6 | INTERFACE_LINE_ATTRIBUTE5 |
| 7 | REQUEST_ID |

### 2. Source du problème

Le fichier source des factures clients contient **des lignes en doublon** avec la même combinaison de clés métier.

#### Fichiers d'entrée analysés

| Fichier | Origine | Nb lignes |
|---------|---------|-----------|
| FAC02_SRC_FACTURESCLIENTS_080126-023614_ST_FAC02_639034365744468566_001 | GCA | 101 660 |
| FAC02_SRC_FACTURESCLIENTS_090126-024105_ST_FAC02_639035232651221257_001 | GCA | 93 162 |
| HEF01_SRC_FACTURESCLIENTS_090126-010513_ST_HEF01_639035175136086871_001 | CYC | 1 225 |

### 3. Statistiques de traitement

| Statut (OA_STATUS) | Signification | Nombre de lignes |
|--------------------|---------------|------------------|
| A | Acceptées | 138 906 |
| P | En cours de traitement | 75 017 |
| R | Rejetées (doublons) | 138 |
| **Total** | | **214 061** |

### 4. Doublons identifiés

**30 combinaisons de factures en doublon** ont été détectées dans les lignes rejetées.

#### Exemple principal : Facture 0001S2601P211

Cette facture apparaît **7 fois** pour la ligne 1 avec le même code tâche :

| IARPAFAC_ID | LINE_NUMBER | TASK_CODE | FMT_AMOUNT |
|-------------|-------------|-----------|------------|
| 43072952 | 1 | GL0012100A | 75,17 |
| 43072953 | 1 | GL0012100A | 100,16 |
| 43072954 | 1 | GL0012100A | 201,45 |
| 43072955 | 1 | GL0012100A | 300,69 |
| 43072956 | 1 | GL0012100A | 400,64 |
| 43072957 | 1 | GL0012100A | 805,78 |
| 43072958 | 1 | GL0012100A | 3941,54 |

#### Autres factures en doublon

| Facture | Ligne | Code Tâche | Nb occurrences |
|---------|-------|------------|----------------|
| 0001S2601P211 | 1 | GL0012100A | 7 |
| 0001S2601P211 | 2 | (vide) | 3 |
| 0001C26017300-0001C26017310 | 1-2 | GL1596773P | 2 chacune |
| 0001N26017638-0001N26017639 | 1-2 | GL0013501S | 2 chacune |
| 0441X26010904 | 1-2 | GL1645236L | 2 |
| 0001C2601N843 | 1-2 | GL0027720A | 2 |

---

## Diagnostic technique

### Flux de données
Système source (FAC02/HEF01)
        ↓
   Fichier plat
        ↓
DKA.DKA_IARPAFAC_INTERFACE (table staging)
        ↓
   DKA_IARPAFAC_PKG (package PL/SQL)
        ↓
AR.RA_INTERFACE_LINES_ALL (interface Oracle AR standard)
        ↓ [ERREUR ICI - Contrainte unique violée]
   AutoInvoice
        ↓
AR.RA_CUSTOMER_TRX_ALL (factures clients finales)
`

### Cause de l'échec

Le package `DKA_IARPAFAC_PKG` tente d'insérer dans `RA_INTERFACE_LINES_ALL` plusieurs lignes avec la **même combinaison de clés** (construites à partir de INVOICE_NUMBER, LINE_NUMBER, COMPANY_CODE, TASK_CODE).

Lors de l'insertion de la 2ème ligne avec les mêmes attributs, la contrainte unique `DKA_RA_INTERFACE_LINES_U1` lève l'exception `ORA-00001`.

---

## Actions correctives

### Court terme (résolution immédiate)

#### 1. Identifier les lignes en doublon à supprimer

```sql
-- Liste des doublons à traiter
SELECT IARPAFAC_ID, INVOICE_NUMBER, LINE_NUMBER, COMPANY_CODE, TASK_CODE
FROM DKA.DKA_IARPAFAC_INTERFACE
WHERE OA_STATUS = 'R'
  AND OA_REQUEST_ID = 46750251;
```

#### 2. Option A : Supprimer les doublons et relancer

```sql
-- Supprimer les 138 lignes rejetées en doublon
DELETE FROM DKA.DKA_IARPAFAC_INTERFACE
WHERE OA_STATUS = 'R'
  AND OA_REQUEST_ID = 46750251;

COMMIT;

-- Puis relancer le programme DKA_IARPAFAC
```

#### 3. Option B : Réinitialiser le statut pour retraitement

```sql
-- Réinitialiser les lignes rejetées pour ne garder qu'une occurrence
UPDATE DKA.DKA_IARPAFAC_INTERFACE
SET OA_STATUS = NULL, OA_REQUEST_ID = NULL
WHERE OA_STATUS = 'R'
  AND OA_REQUEST_ID = 46750251
  AND IARPAFAC_ID IN (
      SELECT MIN(IARPAFAC_ID)
      FROM DKA.DKA_IARPAFAC_INTERFACE
      WHERE OA_STATUS = 'R'
        AND OA_REQUEST_ID = 46750251
      GROUP BY INVOICE_NUMBER, LINE_NUMBER, COMPANY_CODE, TASK_CODE
  );

-- Supprimer les autres doublons
DELETE FROM DKA.DKA_IARPAFAC_INTERFACE
WHERE OA_STATUS = 'R'
  AND OA_REQUEST_ID = 46750251;

COMMIT;
```

### Moyen terme (prévention)

1. **Investiguer le système source FAC02** : Comprendre pourquoi le fichier d'extraction contient des doublons

2. **Ajouter un contrôle de dédoublonnement** dans le package `DKA_IARPAFAC_PKG` :
   - Soit au chargement dans la table staging
   - Soit avant l'insertion dans `RA_INTERFACE_LINES_ALL`

3. **Améliorer la gestion d'erreur** : Capturer l'exception `ORA-00001` pour identifier précisément la ligne en erreur dans les logs

---

## Conclusion

| Élément | Détail |
|---------|--------|
| **Cause** | Doublons dans le fichier source FAC02 du 09/01/2026 |
| **Impact** | 138 lignes de factures non importées |
| **Criticité** | Moyenne (données non perdues, récupérables) |
| **Action requise** | Nettoyage des doublons + relance du traitement |

---

## Annexes

### Requête de vérification post-correction

```sql
-- Vérifier qu'il n'y a plus de doublons
SELECT INVOICE_NUMBER, LINE_NUMBER, COMPANY_CODE, TASK_CODE,
       COUNT(*) AS NB
FROM DKA.DKA_IARPAFAC_INTERFACE
WHERE OA_STATUS IS NULL
GROUP BY INVOICE_NUMBER, LINE_NUMBER, COMPANY_CODE, TASK_CODE
HAVING COUNT(*) > 1;
```

### Historique des exécutions récentes

| REQUEST_ID | Date | Statut | Nb lignes |
|------------|------|--------|-----------|
| 46750251 | 09/01/2026 | Erreur | 214 061 |
| 46736682 | 08/01/2026 | OK | 0 |
| 46728479 | 07/01/2026 | OK | 0 |
| 46716908 | 06/01/2026 | OK | 0 |

---

*Document généré le 12/01/2026 - Analyse incident TP12011976*
