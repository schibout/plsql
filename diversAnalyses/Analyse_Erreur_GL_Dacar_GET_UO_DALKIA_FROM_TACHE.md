# Analyse de l'Erreur GL Dacar - GET_UO_DALKIA_FROM_TACHE

## Contexte de l'Erreur

**Message d'erreur complet** :  
`VHC02_SRC_ECRITURESGL_241225-050002|GET_UO_DALKIA_FROM_TACHE|ASSURANCE202512-0001`

**Système affecté** : Deux pièces GL Dacar rejetées par la PFE (Plate-Forme d'Échanges)  
**Date** : 24/12/2025 à 05:00:02  
**Référence** : ASSURANCE202512-0001

## Origine du Problème

### Package XXEAI_INTERFACE_TOOLS_PKG

L'erreur provient du package **XXEAI.XXEAI_INTERFACE_TOOLS_PKG** (package EAI - Enterprise Application Integration).

#### Fonction Incriminée : `get_task_number`

**Localisation** : XXEAI_INTERFACE_TOOLS_PKG body, lignes 234-251

```sql
function get_task_number(p_region in varchar2, p_societe in varchar2) 
return APPS.PA_TASKS.TASK_NUMBER%TYPE is
  vv_task APPS.PA_TASKS.TASK_NUMBER%TYPE;
begin
  select pt.task_number
    into vv_task
    from APPS.PA_TASKS pt
   where pt.task_number =
         (select haou.attribute12
           from hr_all_organization_units haou
           where haou.name = p_region || p_societe);
  
  return vv_task;
exception
  when others then
    return null;
end get_task_number;
```

#### Contexte d'Appel (Ligne 1143)

Le code appelant est conditionné pour l'application DIAPASON :

```sql
-- Condition particuliere pour DIAPASON
IF NVL(vo_cst_flux_gl.application_name,'n/a') = 'DIAPASON' THEN
  vv_task_number := get_task_number(vo_result.segment2, po_info_cle.societe);
  vv_task_info := get_task(p_task_number => vv_task_number);
  vv_project_info := get_project(p_project_id => vv_task_info.project_id);
  validate(vv_project_info.project_id is not null, vv_code_erreur, 'OAE002');
  
  --Recherche de la classification affaire pour diapason
  vv_class_diap := get_class_affaire(vv_task_info.project_id);
  validate(vv_class_diap.class_code is not null, vv_code_erreur, 'OAE010');
END IF;
```

## Analyse de la Cause Racine

### 1. Mécanisme de Récupération de l'Operating Unit

Le système essaie de déterminer l'Operating Unit (UO) Dalkia à partir d'une tâche projet via le flux suivant :

```
Région + Société → HR_ALL_ORGANIZATION_UNITS.NAME 
                 → HR_ALL_ORGANIZATION_UNITS.ATTRIBUTE12 (task_number)
                 → PA_TASKS.TASK_NUMBER
                 → PA_TASKS.PROJECT_ID
```

### 2. Problème Identifié

**La fonction `get_task_number` retourne NULL** quand :
- Aucune Operating Unit n'existe avec `NAME = région || société` 
- Ou l'ATTRIBUTE12 (task_number) n'est pas renseigné pour cette UO

Pour **Dacar**, les données suivantes sont manquantes ou incorrectes :
- Soit l'Operating Unit n'existe pas dans HR_ALL_ORGANIZATION_UNITS
- Soit le champ ATTRIBUTE12 (lien vers le task_number) n'est pas renseigné

### 3. Table de Transcodification DKA_DKCODE_UO

Le système utilise également une table de transcodification **DKA_DKCODE_UO** (DKCode ↔ UO_DALKIA) pour déduire la région à partir du DKcode.

**Fonction associée** : `Get_region_DKCODE` (ligne 2581)

```sql
PROCEDURE Get_region_DKCODE(pv_DKcode IN VARCHAR2,
                            po_info_region IN OUT NOCOPY XXEAI_TYPE_INFO_REGION_OBJ) IS
  l_result VARCHAR2(200);
BEGIN
  l_result := APPS.dka_stransco_pkg.etl_get_value_f('DKA_DKCODE_UO', sysdate, pv_DKcode);
  validate(l_result is not null, vv_code_erreur, 'OAE040');
  po_info_region := XXEAI_TYPE_INFO_REGION_OBJ('OAE000', l_result);
END;
```

## Requêtes de Diagnostic

### 1. Vérifier l'existence de l'Operating Unit pour Dacar

```sql
-- Chercher Operating Units Dacar
SELECT 
    ORGANIZATION_ID,
    NAME AS "UO_Name (Région+Société)",
    ATTRIBUTE12 AS "Task_Number",
    DATE_FROM,
    DATE_TO
FROM 
    APPS.HR_ALL_ORGANIZATION_UNITS
WHERE 
    UPPER(NAME) LIKE '%DACAR%'
    OR ORGANIZATION_ID IN (
        SELECT DISTINCT organization_id 
        FROM hr_all_organization_units
        WHERE name LIKE '%DAC%'
    )
ORDER BY 
    NAME;
```

### 2. Vérifier la table de transcodification DKA_DKCODE_UO

```sql
-- Vérifier la transcodification DKCode → UO pour Dacar
SELECT 
    *
FROM 
    APPS.DKA_STRANSCO_TAB
WHERE 
    TRANSCO_NAME = 'DKA_DKCODE_UO'
    AND (
        UPPER(CODE_SOURCE) LIKE '%DACAR%'
        OR UPPER(CODE_CIBLE) LIKE '%DACAR%'
    )
ORDER BY 
    CODE_SOURCE;
```

### 3. Identifier les pièces GL en erreur

```sql
-- Rechercher les pièces GL rejetées pour ASSURANCE202512-0001
SELECT 
    STATUS,
    USER_JE_SOURCE_NAME,
    GROUP_ID,
    REFERENCE1,
    REFERENCE2,
    REFERENCE10,
    ATTRIBUTE1,
    ATTRIBUTE2,
    SEGMENT2 AS "UO",
    SEGMENT1 AS "Société",
    ENTERED_DR,
    ENTERED_CR,
    CURRENCY_CODE
FROM 
    APPS.GL_INTERFACE
WHERE 
    (REFERENCE1 LIKE '%ASSURANCE202512-0001%'
     OR REFERENCE10 LIKE '%ASSURANCE202512-0001%'
     OR REFERENCE2 LIKE '%VHC02_SRC_ECRITURESGL%')
    AND STATUS = 'E'
    AND TRUNC(DATE_CREATED) >= TO_DATE('24/12/2025', 'DD/MM/YYYY')
ORDER BY 
    DATE_CREATED DESC;
```

### 4. Vérifier les tâches projet associées aux UO existantes

```sql
-- Vérifier les PA_TASKS référencés dans ATTRIBUTE12
SELECT 
    haou.ORGANIZATION_ID,
    haou.NAME AS "UO_Name",
    haou.ATTRIBUTE12 AS "Task_Number",
    pt.TASK_ID,
    pt.TASK_NAME,
    pt.PROJECT_ID,
    pp.SEGMENT1 AS "Project_Number",
    pp.NAME AS "Project_Name"
FROM 
    APPS.HR_ALL_ORGANIZATION_UNITS haou
    LEFT JOIN APPS.PA_TASKS pt ON pt.TASK_NUMBER = haou.ATTRIBUTE12
    LEFT JOIN APPS.PA_PROJECTS_ALL pp ON pt.PROJECT_ID = pp.PROJECT_ID
WHERE 
    haou.NAME LIKE '%DAC%'
    OR haou.ORGANIZATION_ID IN (
        SELECT organization_id 
        FROM gl_ledger_le_bsv_specific_v
        WHERE name LIKE '%DACAR%'
    )
ORDER BY 
    haou.NAME;
```

## Solutions Possibles

### ⭐ Solution 1 : Mettre à Jour ATTRIBUTE12 de l'UO DNA0001 (RECOMMANDÉE)

**Action** : Mettre à jour le champ ATTRIBUTE12 de l'Operating Unit DNA0001 avec la bonne tâche

```sql
-- Vérification avant modification
SELECT 
    ORGANIZATION_ID,
    NAME AS "UO Name",
    ATTRIBUTE12 AS "Task Number Actuel"
FROM 
    APPS.HR_ALL_ORGANIZATION_UNITS
WHERE 
    ORGANIZATION_ID = 89
    AND NAME = 'DNA0001';
-- Résultat attendu : ATTRIBUTE12 = 'GK0001338W' (ancien)

-- Mise à jour
UPDATE APPS.HR_ALL_ORGANIZATION_UNITS
SET ATTRIBUTE12 = 'GK1596490T',
    LAST_UPDATE_DATE = SYSDATE,
    LAST_UPDATED_BY = FND_GLOBAL.USER_ID
WHERE ORGANIZATION_ID = 89
  AND NAME = 'DNA0001';

COMMIT;

-- Vérification après modification
SELECT 
    ORGANIZATION_ID,
    NAME AS "UO Name",
    ATTRIBUTE12 AS "Task Number Nouveau"
FROM 
    APPS.HR_ALL_ORGANIZATION_UNITS
WHERE 
    ORGANIZATION_ID = 89
    AND NAME = 'DNA0001';
-- Résultat attendu : ATTRIBUTE12 = 'GK1596490T' (nouveau)
```

**Impact** : Tous les flux GL pour DNA0001 utiliseront désormais la tâche GK1596490T

**⚠️ ATTENTION** : Vérifier avec l'équipe fonctionnelle que GK1596490T est bien la bonne tâche pour DNA0001. Si l'ancienne tâche GK0001338W était utilisée par d'autres flux, il faudra les adapter.

### Solution 2 : Créer une Nouvelle UO pour la Tâche GK1596490T

**Action** : S'assurer qu'une Operating Unit existe pour Dacar dans HR_ALL_ORGANIZATION_UNITS

1. Identifier la combinaison Région + Société correcte pour Dacar
2. Vérifier/créer l'Operating Unit avec NAME = Région || Société
3. Renseigner le champ ATTRIBUTE12 avec le task_number approprié du projet PA

**Navigation EBS** :  
`Configuration système > Organisation > HR Organizations`

### Solution 2 : Créer une Nouvelle UO pour la Tâche GK1596490T

**Action** : Si DNA0001 doit conserver GK0001338W, créer une nouvelle UO pour GK1596490T

Cette solution n'est recommandée QUE si DNA0001 utilise réellement deux tâches différentes pour des flux différents.

**Navigation EBS** :  
`Configuration système > Organisation > HR Organizations`

### Solution 3 : Modifier la Logique d'XXEAI_INTERFACE_TOOLS_PKG

**Action** : Améliorer la fonction pour rechercher l'UO via le projet de la tâche

```sql
-- Nouvelle version de get_task_number qui recherche par Project_ID
function get_task_number_by_project(p_task_number in varchar2) 
return APPS.HR_ALL_ORGANIZATION_UNITS.NAME%TYPE is
  vv_uo_name APPS.HR_ALL_ORGANIZATION_UNITS.NAME%TYPE;
begin
  -- Rechercher l'UO via le projet de la tâche
  select haou.name
    into vv_uo_name
    from APPS.PA_TASKS pt
    join APPS.PA_PROJECTS_ALL pp on pt.project_id = pp.project_id
    join APPS.HR_ALL_ORGANIZATION_UNITS haou on pp.org_id = haou.organization_id
   where pt.task_number = p_task_number
     and rownum = 1;
  
  return vv_uo_name;
exception
  when others then
    return null;
end get_task_number_by_project;
```

**Impact** : Cette approche est plus robuste car elle ne dépend pas de la maintenance manuelle de ATTRIBUTE12.

### Solution 4 : Correction Temporaire pour Débloquer le Flux

**Action** : Ajouter/corriger l'entrée de transcodification pour le DKCode Dacar

```sql
-- Exemple d'insertion (à adapter selon les valeurs réelles)
INSERT INTO APPS.DKA_STRANSCO_TAB (
    TRANSCO_NAME,
    CODE_SOURCE,
    CODE_CIBLE,
    DATE_DEBUT,
    DATE_FIN,
    LAST_UPDATE_DATE,
    LAST_UPDATED_BY
) VALUES (
    'DKA_DKCODE_UO',
    '<DKCode_Dacar>',      -- Ex: 'B12345678K'
    '<Region_Dacar>',       -- Ex: 'XX'
    SYSDATE,
    NULL,
    SYSDATE,
    FND_GLOBAL.USER_ID
);
COMMIT;
```

**Note** : Utiliser le package DKA_STRANSCO_PKG pour maintenir cette table :
```sql
APPS.dka_stransco_pkg.etl_set_value(
    p_transco_name => 'DKA_DKCODE_UO',
    p_code_source  => '<DKCode_Dacar>',
    p_code_cible   => '<Region_Dacar>',
    p_date_debut   => SYSDATE
);
```

### Solution 3 : Créer le Projet et la Tâche PA

Si le problème est que le task_number référencé n'existe pas dans PA_TASKS :

1. Créer un projet PA pour Dacar
2. Créer la tâche '1' par défaut (task_number)
3. Mettre à jour HR_ALL_ORGANIZATION_UNITS.ATTRIBUTE12 avec ce task_number

**Navigation EBS** :  
`Projets > Projets > Créer un projet`

### Solution 4 : Exclure Dacar du Traitement DIAPASON

Si Dacar ne doit pas passer par le flux DIAPASON :

**Action** : Modifier la condition dans XXEAI_INTERFACE_TOOLS_PKG (ligne 1141) pour exclure Dacar

```sql
-- Condition particuliere pour DIAPASON (sauf Dacar)
IF NVL(vo_cst_flux_gl.application_name,'n/a') = 'DIAPASON' 
   AND vo_result.segment2 <> '<Code_UO_Dacar>' THEN  -- Ajouter cette condition
```

## Données Identifiées

### Tâche et Projet Concernés

**Tâche** : GK1596490T (Task ID 3974777)
- **Nom** : TF TRAVAUX DTGP MIDI
- **Projet** : FB0092005B (Project ID 3389670)
- **Nom Projet** : FB0092005B-DNA_0001PF ORG TRAV

### Operating Unit Associée

**Operating Unit** : DNA0001 (Organization ID 89)
- **Task Number actuel dans ATTRIBUTE12** : **GK0001338W** ❌
- **Task Number attendu** : **GK1596490T** ✅

### LE PROBLÈME IDENTIFIÉ

L'Operating Unit DNA0001 (qui gère le projet FB0092005B) a dans son champ ATTRIBUTE12 la valeur **"GK0001338W"**, mais le flux GL essaie de retrouver l'UO à partir de la tâche **"GK1596490T"**.

**Résultat** : La fonction `get_task_number` ne trouve aucune UO avec ATTRIBUTE12 = 'GK1596490T', retourne NULL, et le traitement échoue avec l'erreur "GET_UO_DALKIA_FROM_TACHE".

## Codes Erreur Associés

- **OAE002** : Projet non trouvé (validate project_id is not null)
- **OAE007** : Validation segment UO échouée
- **OAE010** : Classification affaire non trouvée pour DIAPASON
- **OAE040** : Région non trouvée dans DKA_DKCODE_UO

## Vérifications Post-Correction

Après avoir appliqué la Solution 1 (mise à jour ATTRIBUTE12), exécuter ces requêtes pour valider :

```sql
-- 1. Vérifier que la fonction get_task_number retourne bien un résultat
SELECT 
    pt.task_number,
    haou.name AS "UO trouvée"
FROM 
    APPS.PA_TASKS pt
    LEFT JOIN APPS.HR_ALL_ORGANIZATION_UNITS haou 
        ON haou.attribute12 = pt.task_number
WHERE 
    pt.task_number = 'GK1596490T';
-- Résultat attendu : UO trouvée = 'DNA0001'

-- 2. Vérifier la cohérence entre Projet et UO
SELECT 
    pt.task_number AS "Tâche",
    pp.segment1 AS "Projet",
    haou.name AS "UO du Projet",
    haou.attribute12 AS "Tâche dans ATTRIBUTE12",
    CASE 
        WHEN pt.task_number = haou.attribute12 THEN '✓ COHERENT'
        ELSE '✗ INCOHERENT'
    END AS "Statut"
FROM 
    APPS.PA_TASKS pt
    JOIN APPS.PA_PROJECTS_ALL pp ON pt.project_id = pp.project_id
    JOIN APPS.HR_ALL_ORGANIZATION_UNITS haou ON pp.org_id = haou.organization_id
WHERE 
    pt.task_number = 'GK1596490T';
-- Résultat attendu : Statut = '✓ COHERENT'

-- 3. Retraiter les pièces GL en erreur
-- À exécuter après correction pour relancer le traitement
SELECT 
    GROUP_ID,
    COUNT(*) AS "Nb Lignes",
    SUM(ENTERED_DR) AS "Total Débit",
    SUM(ENTERED_CR) AS "Total Crédit"
FROM 
    APPS.GL_INTERFACE
WHERE 
    STATUS = 'E'
    AND (REFERENCE1 LIKE '%ASSURANCE202512-0001%'
         OR REFERENCE10 LIKE '%ASSURANCE202512-0001%')
GROUP BY 
    GROUP_ID;
```

## Recommandations

1. **Urgent** : Exécuter les requêtes de diagnostic pour identifier précisément la cause
2. **Court terme** : Créer/corriger les données manquantes (UO, transcodification, tâche)
3. **Moyen terme** : Documenter le processus de configuration pour les nouvelles entités
4. **Long terme** : Améliorer la gestion d'erreur pour fournir des messages plus explicites

## Fichiers Concernés

- **Package** : XXEAI.XXEAI_INTERFACE_TOOLS_PKG (spec + body)
- **Fonction** : get_task_number (lignes 234-251)
- **Contexte d'appel** : Get_Cle_Comptable_CUF (lignes 1143-1151)
- **Table de référence** : HR_ALL_ORGANIZATION_UNITS.ATTRIBUTE12
- **Table de transcodification** : DKA_STRANSCO_TAB (TRANSCO_NAME = 'DKA_DKCODE_UO')

---

**Date d'analyse** : 29/12/2025  
**Analyste** : GitHub Copilot  
**Base de données** : Oracle EBS 12.2.13 (19.25.0.0.0)
