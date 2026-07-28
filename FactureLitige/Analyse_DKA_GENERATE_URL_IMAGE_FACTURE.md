# Analyse : Appel de Procédure DKA_GENERATE_URL_IMAGE_FACTURE

**Date de l'analyse** : 09/03/2026  
**Procédure analysée** : `DKA_GENERATE_URL_IMAGE_FACTURE`  
**Contexte** : Génération d'URLs pour images de factures sur une période annuelle

---

## 1. SYNTHÈSE DE L'APPEL

```sql
exec DKA_GENERATE_URL_IMAGE_FACTURE ( 
    TO_DATE ('01/01/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'), 
    TO_DATE ('31/12/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS')
);
-- Ajout de la deuxième date pivot au lancement de la procédure - Cédric le 24/04/2023
exit
```

### Paramètres Identifiés

| Paramètre | Valeur | Type | Description Présumée |
|-----------|--------|------|---------------------|
| **p_date_debut** | 01/01/2026 00:00:00 | DATE | Date de début de période pour la génération |
| **p_date_fin** | 31/12/2026 00:00:00 | DATE | Date de fin de période (pivot ajouté en 2023) |

### Période Couverte
- **Début** : 1er janvier 2026
- **Fin** : 31 décembre 2026
- **Durée** : 365 jours (année complète 2026)

---

## 2. OBJECTIF PRÉSUMÉ

D'après le nom de la procédure et le contexte Oracle EBS, cette procédure semble :

1. **Générer des URLs** pointant vers les images de factures stockées dans `FND_DOCUMENTS`
2. **Traiter les factures** créées sur la période spécifiée (année 2026)
3. **Stocker ces URLs** probablement dans une table custom (ex: `DKA_IAPFAC_*`)
4. **Intégration iValua** : Préparer l'export des images vers le système iValua

---

## 3. CONTEXTE TECHNIQUE

### 3.1 Système de Gestion d'Images de Factures

Dans Oracle EBS, les images de factures sont gérées via :

```
┌─────────────────────────────────────────────────────────────┐
│                   Flux d'Images de Factures                  │
└─────────────────────────────────────────────────────────────┘

1. SCAN/RÉCEPTION
   ├─ Xerox (VE1_DAL*)
   ├─ Tradeshift (L56*)
   └─ DSP (DSP*)

2. STOCKAGE ORACLE
   ├─ FND_DOCUMENTS (métadonnées + référence fichier)
   ├─ FND_DOCUMENTS_TL (traductions)
   └─ FND_LOBS (contenu binaire, obsolète en 12.2)

3. LIAISON FACTURE
   └─ AP_INVOICES_ALL.ATTRIBUTE3 = FND_DOCUMENTS.FILE_NAME

4. REPORTING
   └─ DKA_IAPFACXGS_REPORTING_ALL (table de suivi)

5. EXPORT iVALUA
   └─ DKA : Export des images Factures vers iValua (programme concurrent)
```

### 3.2 Tables Impliquées (Présumé)

| Table | Rôle Présumé dans la Procédure |
|-------|-------------------------------|
| `AP_INVOICES_ALL` | Source : factures sur la période 01/01-31/12/2026 |
| `FND_DOCUMENTS` | Récupération métadonnées images (FILE_NAME, URL) |
| `DKA_IAPFACXGS_REPORTING_ALL` | Reporting : suivi des factures par source |
| `DKA_IAPFAC_*` (table cible) | Stockage des URLs générées (à identifier) |

---

## 4. ÉVOLUTION HISTORIQUE

### 4.1 Ajout de la Deuxième Date (24/04/2023)

**Commentaire** : *"Ajout de la deuxième date pivot au lancement de la procédure - Cédric le 24/04/2023"*

#### AVANT (Version Initiale)
```sql
-- Probablement avec un seul paramètre
exec DKA_GENERATE_URL_IMAGE_FACTURE ( TO_DATE('01/01/2026', 'DD/MM/YYYY') );
```

**Problème présumé** :
- Traitement ouvert (toutes les factures depuis date de début)
- Pas de borne supérieure → risque de traiter trop de données
- Performance dégradée avec accumulation de factures

#### APRÈS (Version Actuelle)
```sql
-- Avec deux paramètres : début ET fin
exec DKA_GENERATE_URL_IMAGE_FACTURE ( 
    TO_DATE('01/01/2026', 'DD/MM/YYYY'),  -- Date début
    TO_DATE('31/12/2026', 'DD/MM/YYYY')   -- Date fin (ajoutée)
);
```

**Avantages** :
- ✅ Fenêtre de traitement explicite et bornée
- ✅ Possibilité de retraiter une période spécifique
- ✅ Performance maîtrisée (volume prévisible)
- ✅ Parallélisation possible par tranches de dates

---

## 5. LOGIQUE MÉTIER PRÉSUMÉE

### 5.1 Algorithme Probable

```sql
-- Pseudo-code de la procédure
PROCEDURE DKA_GENERATE_URL_IMAGE_FACTURE (
    p_date_debut IN DATE,
    p_date_fin IN DATE
) IS
BEGIN
    -- 1. Sélectionner les factures de la période
    FOR rec IN (
        SELECT aia.invoice_id,
               aia.invoice_num,
               aia.attribute3 AS image_filename,
               aia.creation_date
        FROM ap_invoices_all aia
        WHERE aia.creation_date BETWEEN p_date_debut AND p_date_fin
          AND aia.attribute3 IS NOT NULL  -- Facture avec image
    ) LOOP
    
        -- 2. Rechercher l'image dans FND_DOCUMENTS
        SELECT fd.url, fd.file_id, fd.file_name
        INTO v_url, v_file_id, v_file_name
        FROM fnd_documents fd
        WHERE fd.file_name = rec.image_filename
          OR SUBSTR(fd.file_name, 1, LENGTH(fd.file_name) - 4) = rec.image_filename;
        
        -- 3. Construire l'URL complète (contexte + file_id)
        v_url_complete := 'https://ebs.dalkia.fr/OA_MEDIA/' || v_file_id;
        
        -- 4. Stocker l'URL dans une table custom
        INSERT INTO dka_iapfac_images_url (
            invoice_id, 
            invoice_num, 
            image_url, 
            file_id, 
            creation_date
        ) VALUES (
            rec.invoice_id, 
            rec.invoice_num, 
            v_url_complete, 
            v_file_id, 
            SYSDATE
        );
        
        -- 5. Commit par lot (ex: tous les 1000)
        IF MOD(compteur, 1000) = 0 THEN
            COMMIT;
        END IF;
        
    END LOOP;
    
    -- 6. Commit final
    COMMIT;
    
    -- 7. Générer rapport
    DBMS_OUTPUT.PUT_LINE('Traitement terminé : ' || compteur || ' URLs générées');
    
END;
```

### 5.2 Cas d'Usage

#### **Cas 1 : Génération Annuelle (usage standard)**
```sql
-- Génération pour l'année complète 2026
exec DKA_GENERATE_URL_IMAGE_FACTURE ( 
    TO_DATE('01/01/2026', 'DD/MM/YYYY'), 
    TO_DATE('31/12/2026', 'DD/MM/YYYY')
);
```
**Contexte** : Préparation annuelle pour reporting ou archivage

#### **Cas 2 : Retraitement Mensuel**
```sql
-- Correction pour le mois de novembre 2025
exec DKA_GENERATE_URL_IMAGE_FACTURE ( 
    TO_DATE('01/11/2025', 'DD/MM/YYYY'), 
    TO_DATE('30/11/2025', 'DD/MM/YYYY')
);
```
**Contexte** : Suite à un incident ou images manquantes

#### **Cas 3 : Retraitement d'une Journée**
```sql
-- Retraitement suite à incident Xerox du 15/11/2025
exec DKA_GENERATE_URL_IMAGE_FACTURE ( 
    TO_DATE('15/11/2025', 'DD/MM/YYYY'), 
    TO_DATE('15/11/2025 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
);
```
**Contexte** : Correction ciblée après anomalie quotidienne

---

## 6. POINTS D'ATTENTION

### 6.1 🔴 Performance sur Année Complète

**Volume estimé** (basé sur les données de contrôle de nuit) :

| Source | Factures/jour (moy.) | Factures/an (estimé) |
|--------|---------------------|---------------------|
| Xerox (VE1) | ~150-200 | ~55 000 |
| Tradeshift (L56) | ~50-100 | ~20 000 |
| DSP | Variable | ~10 000 |
| **TOTAL** | **~200-300** | **~85 000 factures** |

**Temps d'exécution estimé** :
- Sans optimisation : 10-20 minutes
- Avec commits par lots : 5-10 minutes
- Avec BULK COLLECT : 2-5 minutes

### 6.2 ⚠️ Gestion des Heures (00:00:00 vs 23:59:59)

**Observation** :
```sql
TO_DATE ('01/01/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS')  -- Minuit début
TO_DATE ('31/12/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS')  -- ⚠️ Minuit fin = Exclut le 31/12!
```

**Problème** : La date de fin est fixée à `00:00:00` du 31/12, ce qui **exclut toutes les factures du 31 décembre**!

**Correction recommandée** :
```sql
TO_DATE ('31/12/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')  -- ✅ Inclut tout le 31/12
```

**OU mieux (Oracle)** :
```sql
-- Utiliser < au lieu de <= avec jour suivant
WHERE aia.creation_date >= p_date_debut
  AND aia.creation_date < p_date_fin + 1  -- < 01/01/2027 00:00:00
```

### 6.3 ⚠️ Factures Sans Image

**Scénario** : Factures présentes dans `AP_INVOICES_ALL` mais sans `ATTRIBUTE3` ou sans correspondance dans `FND_DOCUMENTS`.

**Contrôle recommandé** :
```sql
-- Factures de 2026 sans image
SELECT COUNT(*) 
FROM ap_invoices_all aia
WHERE aia.creation_date BETWEEN TO_DATE('01/01/2026', 'DD/MM/YYYY')
                            AND TO_DATE('31/12/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
  AND (aia.attribute3 IS NULL
       OR NOT EXISTS (
           SELECT 1 FROM fnd_documents fd 
           WHERE fd.file_name = aia.attribute3
              OR SUBSTR(fd.file_name, 1, LENGTH(fd.file_name) - 4) = aia.attribute3
       ));
```

### 6.4 🔍 Monitoring Recommandé

#### **Avant Exécution**
```sql
-- Compter les factures à traiter
SELECT TO_CHAR(creation_date, 'YYYY-MM') AS mois,
       COUNT(*) AS nb_factures
FROM ap_invoices_all
WHERE creation_date >= TO_DATE('01/01/2026', 'DD/MM/YYYY')
  AND creation_date < TO_DATE('01/01/2027', 'DD/MM/YYYY')
  AND attribute3 IS NOT NULL
GROUP BY TO_CHAR(creation_date, 'YYYY-MM')
ORDER BY mois;
```

#### **Après Exécution**
```sql
-- Vérifier le résultat (adapter le nom de la table cible)
SELECT 'URLs générées' AS statut, COUNT(*) AS nb
FROM dka_iapfac_images_url
WHERE creation_date >= TRUNC(SYSDATE)
UNION ALL
SELECT 'Factures source' AS statut, COUNT(*) AS nb
FROM ap_invoices_all
WHERE creation_date >= TO_DATE('01/01/2026', 'DD/MM/YYYY')
  AND creation_date < TO_DATE('01/01/2027', 'DD/MM/YYYY')
  AND attribute3 IS NOT NULL;
```

---

## 7. INTÉGRATION iVALUA

### 7.1 Lien avec Programme Concurrent

D'après le rapport des traitements fournisseurs, il existe :

**Programme** : `DKA : Export des images Factures vers iValua`  
**Nom technique** : `DKA_IAPIMG_IVALUA`  
**Fréquence** : 2 exécutions (27-28/11/2025)  
**Durée moyenne** : 1,54 minute

**Flux probable** :

```
1. DKA_GENERATE_URL_IMAGE_FACTURE (batch)
   └─> Génère les URLs dans table temporaire
   
2. DKA_IAPIMG_IVALUA (programme concurrent)
   └─> Exporte les URLs et métadonnées vers iValua
   
3. iValua
   └─> Télécharge les images via les URLs fournies
```

### 7.2 Tables Interface Probables

| Table | Rôle Présumé |
|-------|-------------|
| `DKA_IAPFAC_IMAGES_URL` | Stockage URLs générées (sortie procédure) |
| `DKA_IAPFACXGS_REPORTING_ALL` | Reporting et suivi des factures |
| `DKA_IAPFAC_IVALUA_INTERFACE` | Interface export vers iValua |

---

## 8. RECOMMANDATIONS

### 8.1 Corrections Immédiates

1. **⚠️ Corriger la date de fin**
```sql
exec DKA_GENERATE_URL_IMAGE_FACTURE ( 
    TO_DATE('01/01/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'), 
    TO_DATE('31/12/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')  -- Corrigé
);
```

2. **✅ Ajouter contrôles pré-exécution**
```sql
-- Vérifier le volume avant de lancer
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM ap_invoices_all
    WHERE creation_date >= TO_DATE('01/01/2026', 'DD/MM/YYYY')
      AND creation_date < TO_DATE('01/01/2027', 'DD/MM/YYYY')
      AND attribute3 IS NOT NULL;
    
    DBMS_OUTPUT.PUT_LINE('Factures à traiter : ' || v_count);
    
    IF v_count > 100000 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Volume trop important, traiter par tranches');
    END IF;
END;
/
```

### 8.2 Optimisations à Étudier

1. **Parallélisation par trimestre**
```sql
-- Q1 2026
exec DKA_GENERATE_URL_IMAGE_FACTURE(TO_DATE('01/01/2026','DD/MM/YYYY'), TO_DATE('31/03/2026 23:59:59','DD/MM/YYYY HH24:MI:SS'));

-- Q2 2026
exec DKA_GENERATE_URL_IMAGE_FACTURE(TO_DATE('01/04/2026','DD/MM/YYYY'), TO_DATE('30/06/2026 23:59:59','DD/MM/YYYY HH24:MI:SS'));

-- Q3 2026
exec DKA_GENERATE_URL_IMAGE_FACTURE(TO_DATE('01/07/2026','DD/MM/YYYY'), TO_DATE('30/09/2026 23:59:59','DD/MM/YYYY HH24:MI:SS'));

-- Q4 2026
exec DKA_GENERATE_URL_IMAGE_FACTURE(TO_DATE('01/10/2026','DD/MM/YYYY'), TO_DATE('31/12/2026 23:59:59','DD/MM/YYYY HH24:MI:SS'));
```

2. **Ajouter paramètre COMMIT_INTERVAL** (si modification procédure possible)
```sql
exec DKA_GENERATE_URL_IMAGE_FACTURE(
    TO_DATE('01/01/2026','DD/MM/YYYY'), 
    TO_DATE('31/12/2026 23:59:59','DD/MM/YYYY HH24:MI:SS'),
    1000  -- Commit tous les 1000 enregistrements
);
```

### 8.3 Documentation à Créer

1. **Script de vérification pré-traitement**
   - Compter les factures par mois
   - Identifier les factures sans image
   - Vérifier les doublons dans `FND_DOCUMENTS`

2. **Procédure de retraitement**
   - En cas d'échec, comment identifier les factures manquantes
   - Script de nettoyage de la table cible avant relance

3. **Monitoring post-traitement**
   - Comparaison nombre de factures source vs URLs générées
   - Rapport de factures en erreur

---

## 9. CONCLUSION

### Résumé Technique

| Élément | Valeur |
|---------|--------|
| **Procédure** | `DKA_GENERATE_URL_IMAGE_FACTURE` |
| **Type** | Custom Dalkia (package DKA) |
| **Objectif** | Génération URLs images factures pour export iValua |
| **Paramètres** | 2 dates (début, fin) depuis avril 2023 |
| **Volume estimé** | ~85 000 factures/an |
| **Durée estimée** | 5-10 minutes (selon optimisation) |

### Points d'Alerte

🔴 **Date de fin incorrecte** : 31/12/2026 00:00:00 exclut les factures du 31 décembre  
⚠️ **Volume important** : 85 000 factures sur une année complète  
⚠️ **Pas de code source disponible** : Analyse basée sur conventions et contexte  

### Action Prioritaire

👉 **Corriger immédiatement la date de fin** avant exécution pour éviter de manquer les factures du 31 décembre 2026.

---

**Analyste** : GitHub Copilot  
**Date** : 09/03/2026  
**Référence** : Documentation Oracle EBS 12.2.13 - Module AP + Intégration iValua
