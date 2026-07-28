# Analyse Erreur - DKA : Import des Factures clients

**Date d'analyse** : 12/01/2026  
**Ticket** : TP12011976

---

## 1. Identification du traitement en erreur

| Attribut | Valeur |
|----------|--------|
| **Programme** | DKA_IARPAFAC |
| **Description** | DKA : Import des Factures clients |
| **REQUEST_ID** | 46750251 |
| **Statut** | Terminé - Erreur |
| **Date début** | 09/01/2026 19:12:27 |
| **Date fin** | 09/01/2026 19:18:16 |

---

## 2. Message d'erreur

```
ORA-00001: violation de contrainte unique (AR.DKA_RA_INTERFACE_LINES_U1)
Une erreur est survenue lors des contrôles d'une ligne de facture.
Veuillez contacter le support technique
```

---

## 3. Cause identifiée

### Problème
Le fichier source des factures clients contient **des lignes en doublon** avec la même combinaison de clés métier (INVOICE_NUMBER + LINE_NUMBER + COMPANY_CODE + TASK_CODE).

### Contrainte violée
L'index unique `AR.DKA_RA_INTERFACE_LINES_U1` empêche l'insertion de doublons dans la table `RA_INTERFACE_LINES_ALL`.

---

## 4. État actuel des données

| Statut | Signification | Nb lignes |
|--------|---------------|-----------|
| A | Acceptées | 138 906 |
| P | En attente | 126 153 |
| R | Rejetées (doublons) | 138 |

---

## 5. Factures en doublon (lignes rejetées)

### Doublon principal : Facture 0001S2601P211

| N° Facture | Ligne | Société | Code Tâche | Nb doublons |
|------------|-------|---------|------------|-------------|
| 0001S2601P211 | 1 | 0001 | GL0012100A | **7** |
| 0001S2601P211 | 2 | 0001 | (vide) | 3 |

### Autres factures en doublon (2 occurrences chacune)

| N° Facture | Société | Code Tâche |
|------------|---------|------------|
| 0001C26017300 à 0001C26017310 | 0001 | GL1596773P |
| 0001N26017638 | 0001 | GL0013501S |
| 0001N26017639 | 0001 | GL0013501S |
| 0001C2601N843 | 0001 | GL0027720A |
| 0441X26010904 | 0441 | GL1645236L |

**Total : 30 combinaisons de doublons identifiées**

---

## 6. Actions correctives recommandées

### Option 1 : Supprimer les lignes rejetées et relancer

```sql
-- Supprimer les 138 lignes rejetées en doublon
DELETE FROM DKA.DKA_IARPAFAC_INTERFACE
WHERE OA_STATUS = 'R'
  AND OA_REQUEST_ID = 46750251;

COMMIT;
```

Puis relancer le programme `DKA_IARPAFAC` via Oracle EBS.

### Option 2 : Conserver une occurrence et supprimer les autres

```sql
-- Garder uniquement la première occurrence de chaque doublon
-- Étape 1 : Réinitialiser une ligne par groupe de doublons
UPDATE DKA.DKA_IARPAFAC_INTERFACE
SET OA_STATUS = NULL, OA_REQUEST_ID = NULL
WHERE IARPAFAC_ID IN (
    SELECT MIN(IARPAFAC_ID)
    FROM DKA.DKA_IARPAFAC_INTERFACE
    WHERE OA_STATUS = 'R'
      AND OA_REQUEST_ID = 46750251
    GROUP BY INVOICE_NUMBER, LINE_NUMBER, COMPANY_CODE, TASK_CODE );

-- Étape 2 : Supprimer les doublons restants
DELETE FROM DKA.DKA_IARPAFAC_INTERFACE
WHERE OA_STATUS = 'R'
  AND OA_REQUEST_ID = 46750251;

COMMIT;
```

---

## 7. Vérification post-correction

```sql
-- Vérifier qu'il n'y a plus de lignes rejetées
SELECT COUNT(*) AS NB_REJETS
FROM DKA.DKA_IARPAFAC_INTERFACE
WHERE OA_STATUS = 'R'
  AND OA_REQUEST_ID = 46750251;
-- Résultat attendu : 0
```

---

## 8. Conclusion

| Élément | Détail |
|---------|--------|
| **Cause** | Doublons dans le fichier source FAC02 |
| **Impact** | 138 lignes de factures non importées |
| **Criticité** | Moyenne |
| **Résolution** | Suppression des doublons + relance |

---

*Analyse réalisée le 12/01/2026*
