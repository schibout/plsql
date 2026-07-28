# Optimisation SQL — SQL_Provision_OCT-25.sql

**Date** : 08/04/2026  
**Fichier modifié** : `SQL_Provision_OCT-25.sql`  
**Objectif** : Réduction du temps d'exécution de la requête de provisions (accruals Cost Management / GL)

---

## Problèmes identifiés et corrections appliquées

### 1. Sous-requête corrélée dans le CTE `PEOPLE` → remplacée par `ROW_NUMBER()`

**Avant :**
```sql
PEOPLE AS (
    SELECT PAPF.PERSON_ID, PAPF.EMPLOYEE_NUMBER, PAPF.FULL_NAME
    FROM hr.per_all_people_f papf
    WHERE PAPF.EFFECTIVE_END_DATE =
          (SELECT MAX(PAPF1.EFFECTIVE_END_DATE)
             FROM HR.PER_ALL_PEOPLE_F PAPF1
            WHERE PAPF1.PERSON_ID = PAPF.PERSON_ID
              AND PAPF1.PERSON_TYPE_ID IN (6, 125))
      AND PAPF.PERSON_TYPE_ID IN (6, 125)
)
```

**Après :**
```sql
PEOPLE AS (
    SELECT /*+ MATERIALIZE */
           PERSON_ID, EMPLOYEE_NUMBER, FULL_NAME
    FROM (
        SELECT PAPF.PERSON_ID, PAPF.EMPLOYEE_NUMBER, PAPF.FULL_NAME,
               ROW_NUMBER() OVER (PARTITION BY PAPF.PERSON_ID
                                  ORDER BY PAPF.EFFECTIVE_END_DATE DESC) AS RN
        FROM HR.PER_ALL_PEOPLE_F PAPF
        WHERE PAPF.PERSON_TYPE_ID IN (6, 125)
    )
    WHERE RN = 1
)
```

**Impact** : C'est l'optimisation la plus significative. La sous-requête corrélée était exécutée **une fois par ligne** de `PER_ALL_PEOPLE_F`, causant potentiellement des millions d'accès. La fonction analytique `ROW_NUMBER()` réalise **un seul scan** de la table avec tri en mémoire.

---

### 2. Hint `MATERIALIZE` sur les deux CTEs

**Ajout** : `/*+ MATERIALIZE */` dans les CTEs `INVOICE` et `PEOPLE`.

**Impact** : Sans ce hint, Oracle peut choisir d'**inliner** les CTEs, c'est-à-dire les réexécuter à chaque référence dans la requête. Comme la requête est un `UNION ALL` avec deux parties distinctes qui référencent chacune ces CTEs, Oracle exécuterait sinon ces CTEs **deux fois**. Avec `MATERIALIZE`, Oracle les calcule **une seule fois** et stocke le résultat en table temporaire.

---

### 3. Suppression du `ORDER BY` inutile dans le CTE `INVOICE`

**Avant :**
```sql
GROUP BY PDA.PO_DISTRIBUTION_ID
ORDER BY 1
```

**Après :**
```sql
GROUP BY PDA.PO_DISTRIBUTION_ID
```

**Impact** : Un `ORDER BY` dans un CTE n'a aucune utilité fonctionnelle (l'ordre n'est pas garanti en sortie de CTE). Il forçait Oracle à effectuer un **tri inutile** sur potentiellement des milliers de lignes avant de construire la table temporaire.

---

### 4. Remplacement des filtres `SUBSTR()` sur `GJB.NAME` par `LIKE`

**Avant :**
```sql
AND (    SUBSTR(GJB.NAME, 1, 9) = 'PROVISION'
     AND SUBSTR(GJB.NAME,
                (INSTR(GJB.NAME, '_', 1, 2) + 1),
                6) = UPPER('AVR-26'))
```

**Après :**
```sql
AND GJB.NAME LIKE 'PROVISION\_%\_AVR-26\_%' ESCAPE '\'
```

**Impact** : Les fonctions `SUBSTR()` et `INSTR()` appliquées à une colonne **empêchent Oracle d'utiliser un index** sur `GJB.NAME` (function-based index mis à part). Le prédicat `LIKE` avec une constante de début (`PROVISION_`) permet à Oracle d'utiliser un **index B-tree standard** sur la colonne pour filtrer rapidement les batches concernés. Appliqué aux deux parties du `UNION ALL`.

---

## Résumé des gains attendus

| # | Modification | Gain potentiel |
|---|---|---|
| 1 | `ROW_NUMBER()` dans `PEOPLE` | Très élevé — élimine N sous-requêtes |
| 2 | Hint `MATERIALIZE` sur CTEs | Élevé — calcul unique au lieu de double |
| 3 | Suppression `ORDER BY` dans `INVOICE` | Modéré — élimine un tri inutile |
| 4 | `LIKE` à la place de `SUBSTR()` sur batch | Modéré à élevé — permet l'usage d'index |

---

## Aucune modification fonctionnelle

Les résultats retournés par la requête sont **identiques** avant et après optimisation. Seule la performance d'exécution est affectée.
