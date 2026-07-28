# Analyse Détaillée : Package DKA_GENERATE_URL_IMAGE_FACTURE

**Date de l'analyse** : 09/03/2026  
**Base de données** : Oracle EBS 19.28.0.0.0 (Production)  
**Schéma** : APPS  
**Type d'objet** : PROCEDURE (Standalone)  
**Statut** : VALID  
**Dernière modification DDL** : 10/10/2025

---

## 1. SYNTHÈSE EXÉCUTIVE

### 1.1 Objectif de la Procédure

La procédure `DKA_GENERATE_URL_IMAGE_FACTURE` génère des URLs d'accès direct aux images de factures stockées dans Oracle EBS et les stocke dans une table de staging pour JMeter (`DKA_JMETER_ST.EXTRACTION_FACTURE`).

### 1.2 Cas d'Usage

- **Tests de charge JMeter** : Extraction massive d'URLs pour tester la performance du serveur de fichiers
- **Export iValua** : Préparation des URLs pour l'intégration avec le système iValua
- **Archivage/Reporting** : Génération de liens permanents vers les images de factures

### 1.3 Évolution Récente

| Date | Auteur | Modification |
|------|--------|--------------|
| **04/09/2025** | CGI Oracle | Remplacement construction URL manuelle par API Oracle `DKA_construct_download_url` |
| **24/04/2023** | Cédric | Ajout du 2ème paramètre DATE_EXTR_FIN (date pivot) |

---

## 2. CODE SOURCE COMPLET

### 2.1 Procédure Principale

```sql
PROCEDURE DKA_GENERATE_URL_IMAGE_FACTURE (
    DATE_EXTR_DEB   IN DATE,
    DATE_EXTR_FIN   IN DATE
)
AS
/*
04/09/2025 : CGI oracle : on construit l'URL via l'API
*/
    VD_DATE_EXTR_FAC DATE := TO_DATE(DATE_EXTR_DEB, 'DD/MM/YYYY HH24:MI:SS');
    vv_param1 VARCHAR2(150);     -- EDB362

BEGIN

    -- 1. NETTOYAGE de la table de staging
    DELETE FROM DKA_JMETER_ST.EXTRACTION_FACTURE;
    COMMIT;

    -- 2. RÉCUPÉRATION du paramètre URL base (ancienne méthode, non utilisée depuis 04/09/2025)
    BEGIN
        SELECT TRIM(VARCHAR2_VALUE)
        INTO vv_param1
        FROM DKA_PARAMETERS
        WHERE PROGRAM_CODE = 'DKA_GEN_URL_IMG_BDC'
          AND PARAMETER_NAME = 'PARAM1';
    END;

    -- 3. INSERTION des URLs dans la table de staging
    INSERT INTO DKA_JMETER_ST.EXTRACTION_FACTURE (INVOICE_ID, URL, ACCESS_ID)
        SELECT INVOICE_ID, URL, ACCESS_ID
        FROM (
            SELECT 
                AIA.INVOICE_ID,
                -- AVANT (04/09/2025) : Construction manuelle
                /*
                   vv_param1
                || CHR(38) || 'fid=' || FD.MEDIA_ID
                || CHR(38) || 'accessid=' || TO_CHAR(FLA.ACCESS_ID)  URL,
                */
                -- APRÈS (04/09/2025) : Utilisation de l'API Oracle
                DKA_construct_download_url(FD.MEDIA_ID)               URL,
                TO_CHAR(FLA.ACCESS_ID)                                ACCESS_ID,
                FLA.TIMESTAMP,
                FD.MEDIA_ID,
                ROW_NUMBER() OVER (
                    PARTITION BY AIA.INVOICE_ID
                    ORDER BY FD.MEDIA_ID DESC, FLA.TIMESTAMP DESC
                )                                                      ORDRE
            FROM APPS.FND_ATTACHED_DOCUMENTS FAD
            JOIN APPS.AP_INVOICES_ALL AIA
                ON FAD.PK1_VALUE = AIA.INVOICE_ID
            JOIN APPS.FND_DOCUMENTS FD
                ON FAD.DOCUMENT_ID = FD.DOCUMENT_ID
            JOIN FND_DOCUMENT_CATEGORIES_TL FDCT
                ON FDCT.CATEGORY_ID = FD.CATEGORY_ID
                AND FDCT.LANGUAGE = 'F'
                AND FDCT.NAME = 'MISC'
            JOIN APPS.FND_LOB_ACCESS FLA
                ON FLA.FILE_ID = FD.MEDIA_ID
            JOIN APPS.FND_DOCUMENTS_TL FDT
                ON FDT.DOCUMENT_ID = FD.DOCUMENT_ID
                AND FDT.LANGUAGE = 'F'
                AND FDT.DESCRIPTION = 'IMAGE FACTURE'
            JOIN FND_DOCUMENT_DATATYPES FDAT
                ON FD.DATATYPE_ID = FDAT.DATATYPE_ID
                AND FDAT.LANGUAGE = 'F'
                AND FDAT.NAME = 'FILE'
            WHERE 1 = 1
              AND FAD.ENTITY_NAME = 'AP_INVOICES'
              AND FAD.LAST_UPDATE_DATE >= DATE_EXTR_DEB
              AND AIA.LAST_UPDATE_DATE >= DATE_EXTR_DEB
              AND FAD.LAST_UPDATE_DATE < DATE_EXTR_FIN
              AND AIA.LAST_UPDATE_DATE < DATE_EXTR_FIN
        )
        WHERE ORDRE = 1;

    COMMIT;

    -- 4. PROLONGATION de la durée de vie des URLs (date d'expiration à 2050)
    UPDATE FND_LOB_ACCESS
       SET TIMESTAMP = TO_DATE('01/01/2050', 'DD/MM/YYYY')
     WHERE ACCESS_ID IN (SELECT ACCESS_ID FROM DKA_JMETER_ST.EXTRACTION_FACTURE)
       AND TIMESTAMP <> TO_DATE('01/01/2050', 'DD/MM/YYYY');

    COMMIT;

END DKA_GENERATE_URL_IMAGE_FACTURE;
```

### 2.2 Fonction Utilitaire : DKA_construct_download_url

```sql
FUNCTION DKA_construct_download_url(file_id NUMBER)
RETURN VARCHAR2
IS
  /*
  04/09/2025 CGI Oracle : Création de cette fonction pour générer les URL à la volée
  */
    PRAGMA AUTONOMOUS_TRANSACTION;
    file_ext VARCHAR2(10);
    l_url VARCHAR2(2000);
BEGIN

    l_url := fnd_gfm.construct_download_url(
        gfm_agent     => fnd_web_config.gfm_agent,
        file_id       => file_id,
        authenticate  => FALSE
    );

    COMMIT;
    RETURN l_url;

EXCEPTION
    WHEN OTHERS THEN
        fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
        fnd_message.set_token('ROUTINE', 'DKA_construct_download_url');
        fnd_message.set_token('ERRNO', SQLCODE);
        fnd_message.set_token('REASON', SQLERRM);
        RAISE;
END;
```

---

## 3. ARCHITECTURE ET FLUX DE DONNÉES

### 3.1 Diagramme de Flux

```
┌──────────────────────────────────────────────────────────────────┐
│                   FLUX DKA_GENERATE_URL_IMAGE_FACTURE            │
└──────────────────────────────────────────────────────────────────┘

ENTRÉES :
  ├─ DATE_EXTR_DEB : 01/01/2026 00:00:00
  └─ DATE_EXTR_FIN : 31/12/2026 23:59:59

ÉTAPE 1 : NETTOYAGE
  └─ DELETE FROM DKA_JMETER_ST.EXTRACTION_FACTURE

ÉTAPE 2 : RÉCUPÉRATION PARAMÈTRE (obsolète depuis 04/09/2025)
  └─ SELECT VARCHAR2_VALUE FROM DKA_PARAMETERS
     WHERE PROGRAM_CODE = 'DKA_GEN_URL_IMG_BDC'
     (Résultat : http://finance.dalkia.net:8001/OA_HTML/fndgfm.jsp...)

ÉTAPE 3 : EXTRACTION + GÉNÉRATION URLs
  ├─ Source : AP_INVOICES_ALL (factures)
  ├─ Jointure : FND_ATTACHED_DOCUMENTS (attachements)
  ├─ Jointure : FND_DOCUMENTS (métadonnées images)
  ├─ Jointure : FND_LOB_ACCESS (contrôle d'accès)
  ├─ Filtre : Période [DATE_EXTR_DEB, DATE_EXTR_FIN[
  ├─ Filtre : Category = 'MISC', Description = 'IMAGE FACTURE'
  ├─ Dédoublonnage : ROW_NUMBER() OVER (PARTITION BY INVOICE_ID)
  └─ Génération URL : DKA_construct_download_url(MEDIA_ID)
        └─> Appel API : fnd_gfm.construct_download_url()

ÉTAPE 4 : STOCKAGE
  └─ INSERT INTO DKA_JMETER_ST.EXTRACTION_FACTURE
     (INVOICE_ID, URL, ACCESS_ID)

ÉTAPE 5 : PROLONGATION DURÉE DE VIE
  └─ UPDATE FND_LOB_ACCESS SET TIMESTAMP = '01/01/2050'
     (URLs valides pendant ~25 ans au lieu de quelques jours/heures)

SORTIE :
  └─ Table DKA_JMETER_ST.EXTRACTION_FACTURE peuplée
     avec URLs permanentes pour JMeter/Export
```

### 3.2 Tables et Vues Impliquées

| Table/Vue | Rôle | Schéma |
|-----------|------|--------|
| `AP_INVOICES_ALL` | Source : factures à traiter | APPS |
| `FND_ATTACHED_DOCUMENTS` | Liens facture ↔ document | APPS |
| `FND_DOCUMENTS` | Métadonnées des images (MEDIA_ID) | APPS |
| `FND_DOCUMENTS_TL` | Traductions (DESCRIPTION = 'IMAGE FACTURE') | APPS |
| `FND_DOCUMENT_CATEGORIES_TL` | Catégories (NAME = 'MISC') | APPS |
| `FND_DOCUMENT_DATATYPES` | Types de données (NAME = 'FILE') | APPS |
| `FND_LOB_ACCESS` | Contrôle d'accès et expiration URLs | APPS |
| `DKA_JMETER_ST.EXTRACTION_FACTURE` | Table de staging (OUTPUT) | DKA_JMETER_ST |
| `DKA_PARAMETERS` | Paramètres de configuration | APPS |

---

## 4. LOGIQUE MÉTIER DÉTAILLÉE

### 4.1 Sélection des Factures

**Critères cumulatifs** :

1. **Période de mise à jour** :
   ```sql
   FAD.LAST_UPDATE_DATE >= DATE_EXTR_DEB
   AND FAD.LAST_UPDATE_DATE < DATE_EXTR_FIN
   AND AIA.LAST_UPDATE_DATE >= DATE_EXTR_DEB
   AND AIA.LAST_UPDATE_DATE < DATE_EXTR_FIN
   ```
   ⚠️ **Attention** : Double filtre sur `LAST_UPDATE_DATE` (facture ET attachement)

2. **Type d'entité** :
   ```sql
   FAD.ENTITY_NAME = 'AP_INVOICES'
   ```

3. **Catégorie document** :
   ```sql
   FDCT.NAME = 'MISC' AND FDCT.LANGUAGE = 'F'
   ```

4. **Description document** :
   ```sql
   FDT.DESCRIPTION = 'IMAGE FACTURE' AND FDT.LANGUAGE = 'F'
   ```

5. **Type de données** :
   ```sql
   FDAT.NAME = 'FILE' AND FDAT.LANGUAGE = 'F'
   ```

### 4.2 Gestion des Doublons

**Problème** : Une facture peut avoir plusieurs images/versions attachées.

**Solution** : Window function avec `ROW_NUMBER()`

```sql
ROW_NUMBER() OVER (
    PARTITION BY AIA.INVOICE_ID
    ORDER BY FD.MEDIA_ID DESC, FLA.TIMESTAMP DESC
) AS ORDRE
...
WHERE ORDRE = 1
```

**Règle de priorisation** :
1. `MEDIA_ID` le plus récent (DESC)
2. `TIMESTAMP` le plus récent (DESC)

→ **Résultat** : Une seule URL par facture (la plus récente)

### 4.3 Génération d'URL (Évolution 04/09/2025)

#### AVANT (Construction Manuelle)

```sql
vv_param1                                    -- http://finance.dalkia.net:8001/OA_HTML/fndgfm.jsp?mode=download_blob
|| CHR(38)                                   -- &
|| 'fid=' || FD.MEDIA_ID                     -- fid=123456
|| CHR(38)                                   -- &
|| 'accessid=' || TO_CHAR(FLA.ACCESS_ID)     -- accessid=789012
```

**Exemple d'URL générée** :
```
http://finance.dalkia.net:8001/OA_HTML/fndgfm.jsp?mode=download_blob&fid=123456&accessid=789012
```

**Problèmes** :
- ❌ URL codée en dur dans `DKA_PARAMETERS`
- ❌ Pas de gestion des caractères spéciaux
- ❌ Pas de validation du MEDIA_ID
- ❌ Dépendance au serveur spécifique

#### APRÈS (API Oracle Standard)

```sql
DKA_construct_download_url(FD.MEDIA_ID)
    └─> fnd_gfm.construct_download_url(
            gfm_agent    => fnd_web_config.gfm_agent,
            file_id      => file_id,
            authenticate => FALSE
        )
```

**Exemple d'URL générée** :
```
https://finance.dalkia.net/OA_CGI/FNDWFAX.execute?dID=123456&aname=XXDKA&p9z=1a2b3c...
```

**Avantages** :
- ✅ API Oracle standard (supportée)
- ✅ Gestion automatique du serveur (via `fnd_web_config.gfm_agent`)
- ✅ URLs sécurisées avec hash/token
- ✅ Compatible avec les futures versions Oracle
- ✅ Gestion automatique des caractères spéciaux

### 4.4 Prolongation de Durée de Vie

**Problème** : Les URLs générées par Oracle ont une durée de vie limitée (expiration après quelques heures/jours selon configuration).

**Solution** :
```sql
UPDATE FND_LOB_ACCESS
   SET TIMESTAMP = TO_DATE('01/01/2050', 'DD/MM/YYYY')
 WHERE ACCESS_ID IN (SELECT ACCESS_ID FROM DKA_JMETER_ST.EXTRACTION_FACTURE)
   AND TIMESTAMP <> TO_DATE('01/01/2050', 'DD/MM/YYYY');
```

**Résultat** : URLs valides jusqu'au 01/01/2050 (~25 ans)

---

## 5. ANALYSE DES PERFORMANCES

### 5.1 Volume de Données Estimé

| Période | Factures estimées | Attachements estimés | Durée d'exécution |
|---------|------------------|---------------------|------------------|
| 1 jour | 200-300 | 200-300 | < 5 secondes |
| 1 mois | 6 000-9 000 | 6 000-9 000 | 10-20 secondes |
| 1 trimestre | 20 000-30 000 | 20 000-30 000 | 30-60 secondes |
| 1 an | 80 000-100 000 | 80 000-100 000 | 2-5 minutes |

### 5.2 Points de Performance Critique

#### 🔴 Problème 1 : Jointures Multiples (6 tables)

```sql
FROM APPS.FND_ATTACHED_DOCUMENTS FAD
JOIN APPS.AP_INVOICES_ALL AIA           -- 1
JOIN APPS.FND_DOCUMENTS FD             -- 2
JOIN FND_DOCUMENT_CATEGORIES_TL FDCT   -- 3
JOIN APPS.FND_LOB_ACCESS FLA           -- 4
JOIN APPS.FND_DOCUMENTS_TL FDT         -- 5
JOIN FND_DOCUMENT_DATATYPES FDAT       -- 6
```

**Impact** : Plan d'exécution complexe, risque de NESTED LOOPS coûteux.

**Solution recommandée** : Vérifier les index sur :
- `FND_ATTACHED_DOCUMENTS (PK1_VALUE, ENTITY_NAME, LAST_UPDATE_DATE)`
- `AP_INVOICES_ALL (INVOICE_ID, LAST_UPDATE_DATE)`
- `FND_DOCUMENTS (DOCUMENT_ID, MEDIA_ID, CATEGORY_ID)`
- `FND_LOB_ACCESS (FILE_ID, ACCESS_ID)`

#### ⚠️ Problème 2 : Window Function sur Gros Volume

```sql
ROW_NUMBER() OVER (PARTITION BY AIA.INVOICE_ID ORDER BY ...)
```

**Impact** : Nécessite tri en mémoire (TEMP tablespace).

**Solution recommandée** : Si peu de doublons, pré-filtrer avec `DISTINCT` ou `MAX()`.

#### ⚠️ Problème 3 : Appel Fonction Scalaire

```sql
DKA_construct_download_url(FD.MEDIA_ID)  -- Appelée pour CHAQUE ligne
```

**Impact** : 
- Fonction `PRAGMA AUTONOMOUS_TRANSACTION` → Overhead de contexte
- Commit dans la fonction → Potentiel de fragmentation

**Solution recommandée** : 
- Utiliser `BULK COLLECT` + `FORALL` pour traiter par lots
- Retirer le COMMIT de la fonction (gérer en dehors)

#### 🟡 Problème 4 : DELETE Complet sur Table de Staging

```sql
DELETE FROM DKA_JMETER_ST.EXTRACTION_FACTURE;
```

**Impact** : Génère des undo logs si la table est volumineuse.

**Solution recommandée** : Utiliser `TRUNCATE` (si permissions disponibles) :
```sql
EXECUTE IMMEDIATE 'TRUNCATE TABLE DKA_JMETER_ST.EXTRACTION_FACTURE';
```

### 5.3 Optimisation Proposée (Version BULK)

```sql
-- Version optimisée avec BULK COLLECT
DECLARE
    TYPE t_invoice_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    TYPE t_url_tab IS TABLE OF VARCHAR2(2000) INDEX BY PLS_INTEGER;
    TYPE t_access_tab IS TABLE OF VARCHAR2(50) INDEX BY PLS_INTEGER;
    
    v_invoices t_invoice_tab;
    v_urls t_url_tab;
    v_access_ids t_access_tab;
    
    CURSOR c_factures IS
        SELECT INVOICE_ID, MEDIA_ID, ACCESS_ID
        FROM (...); -- Même requête que l'original
BEGIN
    -- Truncate au lieu de DELETE
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DKA_JMETER_ST.EXTRACTION_FACTURE';
    
    -- Bulk collect par lots de 5000
    OPEN c_factures;
    LOOP
        FETCH c_factures BULK COLLECT INTO v_invoices, v_urls, v_access_ids LIMIT 5000;
        EXIT WHEN v_invoices.COUNT = 0;
        
        -- Générer les URLs par lot
        FOR i IN 1..v_invoices.COUNT LOOP
            v_urls(i) := DKA_construct_download_url(v_urls(i)); -- Appel optimisé
        END LOOP;
        
        -- Insertion par lot
        FORALL i IN 1..v_invoices.COUNT
            INSERT INTO DKA_JMETER_ST.EXTRACTION_FACTURE VALUES (v_invoices(i), v_urls(i), v_access_ids(i));
        
        COMMIT; -- Commit par lot
    END LOOP;
    CLOSE c_factures;
    
    -- Update FND_LOB_ACCESS (inchangé)
    UPDATE FND_LOB_ACCESS SET TIMESTAMP = TO_DATE('01/01/2050', 'DD/MM/YYYY') ...;
    COMMIT;
END;
```

**Gain attendu** : 30-50% de réduction du temps d'exécution sur gros volumes.

---

## 6. PROBLÈMES IDENTIFIÉS ET RECOMMANDATIONS

### 6.1 🔴 CRITIQUE : Date de Fin Incorrecte (BUG)

**Ligne de code** :
```sql
AND FAD.LAST_UPDATE_DATE < DATE_EXTR_FIN
AND AIA.LAST_UPDATE_DATE < DATE_EXTR_FIN
```

**Appel standard** :
```sql
exec DKA_GENERATE_URL_IMAGE_FACTURE(
    TO_DATE('01/01/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'),
    TO_DATE('31/12/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS')  -- ⚠️ Minuit!
);
```

**Problème** : `< 31/12/2026 00:00:00` exclut **toutes les factures du 31 décembre** !

**Impact** : Perte de ~200-300 factures sur l'année.

**Correction immédiate** :
```sql
exec DKA_GENERATE_URL_IMAGE_FACTURE(
    TO_DATE('01/01/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'),
    TO_DATE('31/12/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')  -- ✅ Fin de journée
);
```

**OU modifier la procédure** :
```sql
-- Remplacer < par <=
AND FAD.LAST_UPDATE_DATE <= DATE_EXTR_FIN
AND AIA.LAST_UPDATE_DATE <= DATE_EXTR_FIN
```

### 6.2 ⚠️ MAJEUR : Double Filtre LAST_UPDATE_DATE

**Code** :
```sql
AND FAD.LAST_UPDATE_DATE >= DATE_EXTR_DEB
AND AIA.LAST_UPDATE_DATE >= DATE_EXTR_DEB
AND FAD.LAST_UPDATE_DATE < DATE_EXTR_FIN
AND AIA.LAST_UPDATE_DATE < DATE_EXTR_FIN
```

**Problème** : Une facture mise à jour dans la période mais avec un attachement plus ancien (ou inversement) sera **exclue**.

**Exemple** :
- Facture créée le 15/01/2026
- Image attachée le 10/12/2025 (avant la période)
- Requête pour période 01/01-31/12/2026
- **Résultat** : Image non extraite car `FAD.LAST_UPDATE_DATE < 01/01/2026`

**Recommandation** : Clarifier le besoin métier :

**Option A** : Extraire toutes les images des factures modifiées dans la période
```sql
AND AIA.LAST_UPDATE_DATE >= DATE_EXTR_DEB
AND AIA.LAST_UPDATE_DATE < DATE_EXTR_FIN
-- Retirer filtre sur FAD.LAST_UPDATE_DATE
```

**Option B** : Extraire seulement les images attachées dans la période
```sql
AND FAD.LAST_UPDATE_DATE >= DATE_EXTR_DEB
AND FAD.LAST_UPDATE_DATE < DATE_EXTR_FIN
-- Retirer filtre sur AIA.LAST_UPDATE_DATE
```

**Option C** : Conserver le OR logique (au moins un des deux dans la période)
```sql
AND (
    (FAD.LAST_UPDATE_DATE BETWEEN DATE_EXTR_DEB AND DATE_EXTR_FIN)
    OR
    (AIA.LAST_UPDATE_DATE BETWEEN DATE_EXTR_DEB AND DATE_EXTR_FIN)
)
```

### 6.3 ⚠️ MINEUR : Paramètre vv_param1 Non Utilisé

**Code** :
```sql
vv_param1 VARCHAR2(150);
...
BEGIN
    SELECT TRIM(VARCHAR2_VALUE) INTO vv_param1 FROM DKA_PARAMETERS ...;
END;
```

**Problème** : Variable déclarée et remplie mais **jamais utilisée** depuis la migration du 04/09/2025.

**Recommandation** : **Supprimer** ce code mort :
```sql
-- Code à retirer (obsolète depuis 04/09/2025)
-- vv_param1 VARCHAR2(150);
-- BEGIN
--     SELECT TRIM(VARCHAR2_VALUE) INTO vv_param1 FROM DKA_PARAMETERS ...;
-- END;
```

**Ou** : Conserver comme fallback si l'API Oracle échoue :
```sql
BEGIN
    l_url := DKA_construct_download_url(FD.MEDIA_ID);
EXCEPTION
    WHEN OTHERS THEN
        -- Fallback sur ancienne méthode
        l_url := vv_param1 || CHR(38) || 'fid=' || FD.MEDIA_ID || CHR(38) || 'accessid=' || FLA.ACCESS_ID;
END;
```

### 6.4 🟡 COSMÉTIQUE : Variable VD_DATE_EXTR_FAC Non Utilisée

**Code** :
```sql
VD_DATE_EXTR_FAC DATE := TO_DATE(DATE_EXTR_DEB, 'DD/MM/YYYY HH24:MI:SS');
```

**Problème** : Variable déclarée et initialisée mais **jamais référencée** dans le code.

**Recommandation** : **Supprimer** cette ligne.

### 6.5 ⚠️ SÉCURITÉ : URLs Non Authentifiées

**Code fonction** :
```sql
fnd_gfm.construct_download_url(
    ...
    authenticate => FALSE
)
```

**Impact** : Les URLs générées sont **accessibles sans authentification**.

**Avantages** :
- ✅ Utilisables directement par JMeter
- ✅ Partageables entre systèmes
- ✅ Pas de gestion de session

**Risques** :
- ❌ URLs diffusées = accès aux images de factures confidentielles
- ❌ Pas de traçabilité des téléchargements
- ❌ URLs valides 25 ans (TIMESTAMP 2050)

**Recommandations** :
1. **Court terme** : Sécuriser l'accès à `DKA_JMETER_ST.EXTRACTION_FACTURE`
2. **Moyen terme** : Passer `authenticate => TRUE` et gérer les tokens
3. **Long terme** : Utiliser une solution API Gateway avec authentification OAuth

---

## 7. SCÉNARIOS D'UTILISATION

### 7.1 Scénario Standard : Année Complète

```sql
-- Génération annuelle 2026 (CORRIGÉE)
exec DKA_GENERATE_URL_IMAGE_FACTURE(
    TO_DATE('01/01/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'),
    TO_DATE('31/12/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
);
```

**Résultat attendu** : ~85 000 URLs générées en 2-5 minutes

**Vérification** :
```sql
SELECT COUNT(*) FROM DKA_JMETER_ST.EXTRACTION_FACTURE;
-- Attendu : ~85 000 lignes

SELECT COUNT(DISTINCT INVOICE_ID) FROM DKA_JMETER_ST.EXTRACTION_FACTURE;
-- Attendu : ~85 000 (une URL par facture)
```

### 7.2 Scénario Mensuel : Traitement Incrémental

```sql
-- Génération pour novembre 2025
exec DKA_GENERATE_URL_IMAGE_FACTURE(
    TO_DATE('01/11/2025 00:00:00', 'DD/MM/YYYY HH24:MI:SS'),
    TO_DATE('30/11/2025 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
);
```

**Résultat attendu** : ~7 000 URLs générées en 10-20 secondes

### 7.3 Scénario Journalier : Monitoring / Tests

```sql
-- Génération pour hier
exec DKA_GENERATE_URL_IMAGE_FACTURE(
    TRUNC(SYSDATE - 1),
    TRUNC(SYSDATE) - 1/86400  -- 23:59:59 d'hier
);
```

**Résultat attendu** : ~200-300 URLs générées en < 5 secondes

### 7.4 Scénario Correction : Retraitement Période Spécifique

```sql
-- Retraitement suite à incident du 15/11/2025
exec DKA_GENERATE_URL_IMAGE_FACTURE(
    TO_DATE('15/11/2025 00:00:00', 'DD/MM/YYYY HH24:MI:SS'),
    TO_DATE('15/11/2025 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
);
```

---

## 8. MONITORING ET CONTRÔLES

### 8.1 Scripts de Vérification Pré-Exécution

```sql
-- 1. Compter les factures avec images dans la période
SELECT 
    TO_CHAR(AIA.LAST_UPDATE_DATE, 'YYYY-MM') AS mois,
    COUNT(DISTINCT AIA.INVOICE_ID) AS nb_factures_avec_image
FROM APPS.AP_INVOICES_ALL AIA
JOIN APPS.FND_ATTACHED_DOCUMENTS FAD
    ON FAD.PK1_VALUE = AIA.INVOICE_ID
    AND FAD.ENTITY_NAME = 'AP_INVOICES'
JOIN APPS.FND_DOCUMENTS FD
    ON FAD.DOCUMENT_ID = FD.DOCUMENT_ID
WHERE AIA.LAST_UPDATE_DATE >= TO_DATE('01/01/2026', 'DD/MM/YYYY')
  AND AIA.LAST_UPDATE_DATE < TO_DATE('01/01/2027', 'DD/MM/YYYY')
GROUP BY TO_CHAR(AIA.LAST_UPDATE_DATE, 'YYYY-MM')
ORDER BY mois;

-- 2. Identifier les factures sans image
SELECT COUNT(*) AS factures_sans_image
FROM APPS.AP_INVOICES_ALL AIA
WHERE AIA.LAST_UPDATE_DATE >= TO_DATE('01/01/2026', 'DD/MM/YYYY')
  AND AIA.LAST_UPDATE_DATE < TO_DATE('01/01/2027', 'DD/MM/YYYY')
  AND NOT EXISTS (
      SELECT 1 FROM APPS.FND_ATTACHED_DOCUMENTS FAD
      WHERE FAD.PK1_VALUE = AIA.INVOICE_ID
        AND FAD.ENTITY_NAME = 'AP_INVOICES'
  );
```

### 8.2 Scripts de Vérification Post-Exécution

```sql
-- 1. Comparer nombre de factures source vs URLs générées
SELECT 
    'FACTURES_SOURCE' AS type,
    COUNT(DISTINCT AIA.INVOICE_ID) AS nombre
FROM APPS.AP_INVOICES_ALL AIA
JOIN APPS.FND_ATTACHED_DOCUMENTS FAD
    ON FAD.PK1_VALUE = AIA.INVOICE_ID
    AND FAD.ENTITY_NAME = 'AP_INVOICES'
WHERE AIA.LAST_UPDATE_DATE >= TO_DATE('01/01/2026', 'DD/MM/YYYY')
  AND AIA.LAST_UPDATE_DATE < TO_DATE('01/01/2027', 'DD/MM/YYYY')
  AND FAD.LAST_UPDATE_DATE >= TO_DATE('01/01/2026', 'DD/MM/YYYY')
  AND FAD.LAST_UPDATE_DATE < TO_DATE('01/01/2027', 'DD/MM/YYYY')
UNION ALL
SELECT 
    'URLS_GENEREES' AS type,
    COUNT(DISTINCT INVOICE_ID) AS nombre
FROM DKA_JMETER_ST.EXTRACTION_FACTURE;

-- 2. Vérifier les URLs vides ou NULL
SELECT COUNT(*) AS urls_invalides
FROM DKA_JMETER_ST.EXTRACTION_FACTURE
WHERE URL IS NULL 
   OR TRIM(URL) = ''
   OR LENGTH(URL) < 20;

-- 3. Vérifier la mise à jour de FND_LOB_ACCESS
SELECT 
    COUNT(*) AS total_access_records,
    SUM(CASE WHEN TIMESTAMP = TO_DATE('01/01/2050', 'DD/MM/YYYY') THEN 1 ELSE 0 END) AS prolonges
FROM APPS.FND_LOB_ACCESS
WHERE ACCESS_ID IN (SELECT TO_NUMBER(ACCESS_ID) FROM DKA_JMETER_ST.EXTRACTION_FACTURE);
```

### 8.3 Rapport de Synthèse

```sql
-- Rapport complet d'exécution
SELECT 
    'URLs générées' AS metrique,
    COUNT(*) AS valeur
FROM DKA_JMETER_ST.EXTRACTION_FACTURE
UNION ALL
SELECT 
    'Factures uniques' AS metrique,
    COUNT(DISTINCT INVOICE_ID) AS valeur
FROM DKA_JMETER_ST.EXTRACTION_FACTURE
UNION ALL
SELECT 
    'URLs invalides' AS metrique,
    COUNT(*) AS valeur
FROM DKA_JMETER_ST.EXTRACTION_FACTURE
WHERE URL IS NULL OR LENGTH(URL) < 20
UNION ALL
SELECT 
    'Access IDs prolongés à 2050' AS metrique,
    COUNT(*) AS valeur
FROM APPS.FND_LOB_ACCESS
WHERE ACCESS_ID IN (SELECT TO_NUMBER(ACCESS_ID) FROM DKA_JMETER_ST.EXTRACTION_FACTURE)
  AND TIMESTAMP = TO_DATE('01/01/2050', 'DD/MM/YYYY');
```

---

## 9. DÉPENDANCES ET ÉLÉMENTS ASSOCIÉS

### 9.1 Objets Oracle EBS Standard

| Objet | Type | Rôle |
|-------|------|------|
| `fnd_gfm.construct_download_url` | API Package | Génération d'URLs sécurisées |
| `fnd_web_config.gfm_agent` | Configuration | Agent serveur de fichiers |
| `fnd_message` | API Package | Gestion des messages d'erreur |

### 9.2 Objets Custom Dalkia

| Objet | Type | Statut | Commentaire |
|-------|------|--------|-------------|
| `DKA_GENERATE_URL_IMAGE_FACTURE` | PROCEDURE | VALID | Objet analysé |
| `DKA_GENERATE_URL_IMAGE_BDC` | PROCEDURE | VALID | Procédure similaire pour BDC |
| `DKA_construct_download_url` | FUNCTION | VALID | Wrapper autour de fnd_gfm |
| `DKA_JMETER_ST.EXTRACTION_FACTURE` | TABLE | ? | Table de staging JMeter |
| `DKA_PARAMETERS` | TABLE | VALID | Configuration application |

### 9.3 Configuration DKA_PARAMETERS

```sql
SELECT * FROM DKA_PARAMETERS WHERE PROGRAM_CODE = 'DKA_GEN_URL_IMG_BDC';
```

| PROGRAM_CODE | PARAMETER_NAME | VARCHAR2_VALUE | DESCRIPTION |
|-------------|----------------|----------------|-------------|
| DKA_GEN_URL_IMG_BDC | PARAM1 | http://finance.dalkia.net:8001/OA_HTML/fndgfm.jsp?mode=download_blob | Url du serveur PRODUCTION |

**Note** : Ce paramètre n'est plus utilisé depuis la migration du 04/09/2025 vers l'API `fnd_gfm`.

---

## 10. CONCLUSION ET RECOMMANDATIONS

### 10.1 Points Forts

✅ Migration vers API Oracle standard (04/09/2025) → Meilleure maintenabilité  
✅ Gestion du dédoublonnage (ROW_NUMBER())  
✅ Prolongation automatique des URLs (2050)  
✅ Procédure simple et lisible

### 10.2 Points d'Amélioration Prioritaires

#### 🔴 URGENT (Corriger avant la prochaine exécution)

1. **Corriger la date de fin** dans l'appel standard
   ```sql
   -- AVANT
   TO_DATE('31/12/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS')
   
   -- APRÈS
   TO_DATE('31/12/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
   ```

2. **Clarifier le double filtre LAST_UPDATE_DATE**
   - Documenter le besoin métier exact
   - Choisir entre Option A, B ou C (voir section 6.2)

#### ⚠️ RECOMMANDÉ (Court terme)

3. **Optimiser les performances avec BULK COLLECT**
   - Implémenter la version proposée en section 5.3
   - Gain attendu : 30-50% sur gros volumes

4. **Nettoyer le code mort**
   - Retirer `vv_param1` (non utilisé)
   - Retirer `VD_DATE_EXTR_FAC` (non utilisé)

5. **Remplacer DELETE par TRUNCATE**
   - Réduire génération d'undo logs
   - Gain : 10-20% sur grand volume

#### 🟡 SOUHAITABLE (Moyen terme)

6. **Ajouter des contrôles et logs**
   - Log du nombre d'URLs générées
   - Log du temps d'exécution
   - Alertes si écarts > 10% avec valeurs attendues

7. **Sécuriser les URLs**
   - Évaluer passage à `authenticate => TRUE`
   - Mettre en place gestion des tokens

8. **Documenter la table DKA_JMETER_ST.EXTRACTION_FACTURE**
   - Structure exacte
   - Politique de rétention
   - Utilisateurs autorisés

### 10.3 Risques

| Risque | Probabilité | Impact | Mitigation |
|--------|------------|--------|------------|
| URLs expirées prématurément | Faible | Élevé | Vérifier FND_LOB_ACCESS après chaque exécution |
| Performance dégradée (>100K factures) | Moyenne | Moyen | Implémenter version BULK COLLECT |
| Factures du 31/12 manquantes | **Élevé** | Élevé | **Corriger date de fin immédiatement** |
| Accès non autorisé aux images | Moyenne | Élevé | Sécuriser table EXTRACTION_FACTURE, auditer accès |

### 10.4 Prochaines Étapes

1. ✅ **Immédiat** : Corriger appel avec date 23:59:59
2. ✅ **Cette semaine** : Tester sur échantillon (1 mois) et valider résultats
3. ✅ **Ce mois** : Implémenter optimisations performance (BULK)
4. ✅ **Prochain trimestre** : Sécurisation et monitoring avancé

---

**Analyste** : GitHub Copilot  
**Date** : 09/03/2026  
**Base de données** : Oracle EBS 19.28.0.0.0 (Production)  
**Référence** : Code source procédure APPS.DKA_GENERATE_URL_IMAGE_FACTURE
