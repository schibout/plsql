# DKA : Export des images Factures vers iValua

## Identification

| Attribut | Valeur |
|----------|--------|
| **Nom utilisateur** | `DKA : Export des images Factures vers iValua` |
| **Nom technique** | `DKA_IAPIMG_IVALUA` |
| **Application** | DKA (custom Dalkia) |
| **Module Oracle EBS** | AP (Accounts Payable) |
| **Type** | Programme concurrent PL/SQL |

---

## 1. Objectif

Ce programme exporte les images scannées des factures fournisseurs stockées dans Oracle EBS vers le système **iValua** (système de gestion des achats). Il s'inscrit dans la chaîne d'intégration AP ↔ iValua qui permet à iValua de visualiser et traiter les justificatifs des factures.

---

## 2. Architecture du flux

```
┌─────────────────────────────────────────────────────────────────────┐
│                   Flux complet images de factures                    │
└─────────────────────────────────────────────────────────────────────┘

1. RÉCEPTION DES IMAGES (scan / intégration)
   ├─ Xerox     → fichiers VE1_DAL*  (intégrés via DKA_IAPFACXGS)
   ├─ Tradeshift → fichiers L56*
   └─ DSP       → fichiers DSP*

2. STOCKAGE ORACLE EBS
   ├─ FND_DOCUMENTS          (métadonnées + nom fichier)
   ├─ FND_DOCUMENTS_TL       (traductions)
   └─ AP_INVOICES_ALL.ATTRIBUTE3  (lien facture ↔ image via FILE_NAME)

3. REPORTING / SUIVI
   └─ DKA_IAPFACXGS_REPORTING_ALL  (table de suivi des factures par source)

4. GÉNÉRATION DES URLS (procédure préparatoire)
   └─ DKA_GENERATE_URL_IMAGE_FACTURE(p_date_debut, p_date_fin)
       └─> Table cible d'URLs (DKA_IAPFAC_IMAGES_URL ou équivalent)

5. EXPORT VERS iVALUA
   └─ DKA_IAPIMG_IVALUA (ce programme)
       └─> iValua reçoit les URLs et télécharge les images

6. RETOUR iVALUA (flux inverse)
   ├─ DKA_IAPFAC_IVALUA          → Export données factures vers iValua
   ├─ DKA_IAPFAC_DEBLOC_LOADER   → Chargement fichier codes déblocage
   └─ DKA_IAPFAC_DEBLOC_INTERFACE→ Import codes déblocage factures depuis iValua
```

---

## 3. Programmes Oracle EBS associés

| Programme | Nom technique | Rôle | Heure batch |
|-----------|---------------|------|-------------|
| Export images Factures vers iValua | `DKA_IAPIMG_IVALUA` | **Ce programme** — export images | 01:01 / 03:13 |
| Export données Factures vers iValua | `DKA_IAPFAC_IVALUA` | Export métadonnées factures | 03:24 |
| Intégration des factures XEROX | `DKA_IAPFACXGS` | Import factures Xerox | 20:35 |
| Chargement factures ZCI | `DKA_IAPFACZCI_LOADER` | Chargement fichier ZCI | 20:33 |
| Import codes déblocage depuis iValua - Loader | `DKA_IAPFAC_DEBLOC_LOADER` | Chargement fichier déblocage | 21:32 |
| Import codes déblocage depuis iValua | `DKA_IAPFAC_DEBLOC_INTERFACE` | Intégration codes déblocage | 21:32 |
| Extraction statut factures TradeShift | `DKA_IAPFACTTDS` | Suivi statut Tradeshift | 03:24 |

---

## 4. Procédure préparatoire : `DKA_GENERATE_URL_IMAGE_FACTURE`

Avant l'export, la procédure `DKA_GENERATE_URL_IMAGE_FACTURE` prépare les URLs des images de factures.

### Signature

```sql
PROCEDURE DKA_GENERATE_URL_IMAGE_FACTURE (
    p_date_debut IN DATE,  -- Date de début de la période
    p_date_fin   IN DATE   -- Date de fin (ajouté le 24/04/2023 - Cédric)
)
```

### Appel standard (année courante)

```sql
exec DKA_GENERATE_URL_IMAGE_FACTURE ( 
    TO_DATE('01/01/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'), 
    TO_DATE('31/12/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
);
```

> ⚠️ **Point d'attention** : La date de fin doit être `23:59:59` (et non `00:00:00`) pour inclure les factures du dernier jour de la période.

### Logique principale

1. Sélectionner les factures de la période (`AP_INVOICES_ALL` où `ATTRIBUTE3 IS NOT NULL`)
2. Rechercher l'image associée dans `FND_DOCUMENTS` via `FILE_NAME`
3. Construire l'URL complète (contexte Oracle + identifiant fichier)
4. Stocker l'URL dans la table custom cible
5. Commits intermédiaires par lot (performance)

### Retraitement par période

```sql
-- Retraitement mensuel (ex : correction novembre 2025)
exec DKA_GENERATE_URL_IMAGE_FACTURE ( 
    TO_DATE('01/11/2025 00:00:00', 'DD/MM/YYYY HH24:MI:SS'), 
    TO_DATE('30/11/2025 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
);

-- Retraitement journalier (ex : incident Xerox du 15/11/2025)
exec DKA_GENERATE_URL_IMAGE_FACTURE ( 
    TO_DATE('15/11/2025 00:00:00', 'DD/MM/YYYY HH24:MI:SS'), 
    TO_DATE('15/11/2025 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
);
```

---

## 5. Tables impliquées

| Table | Schéma | Rôle |
|-------|--------|------|
| `AP_INVOICES_ALL` | AP | Source : factures (lien image via `ATTRIBUTE3`) |
| `FND_DOCUMENTS` | FND | Métadonnées images (FILE_NAME, URL, FILE_ID) |
| `FND_DOCUMENTS_TL` | FND | Traductions des documents |
| `DKA_IAPFACXGS_REPORTING_ALL` | DKA | Reporting et suivi des factures par source |
| `DKA_IAPFAC_DEBLOC_HIST_INTERF` | DKA | Historique des codes de déblocage (retour iValua) |
| `DKA_IAPFAC_IMAGES_URL` | DKA | Stockage des URLs générées (sortie procédure) |
| `DKA_IAPFAC_IVALUA_INTERFACE` | DKA | Table d'interface export vers iValua |

---

## 6. Statistiques d'exécution

### Données de production (source : `FND_CONCURRENT_REQUESTS`)

| Période | Nb exécutions | Durée moyenne | Durée max | Durée min | Durée totale |
|---------|--------------|---------------|-----------|-----------|--------------|
| Mars 2026 | 96 | 1,23 min | 2,05 min | 0,65 min | 118,27 min |
| Avril 2026 | 104 | 1,19 min | 2,28 min | 0,07 min | 124,27 min |

- **Fréquence batch** : ~2 exécutions par nuit (01:01 et 03:13)
- **Fréquence mensuelle** : ~19 exécutions/mois (données nuit)
- **Statut nominal** : `Normal` ✅

### Requête de suivi des exécutions

```sql
SELECT fcr.request_id,
       TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS')       AS date_debut,
       TO_CHAR(fcr.actual_completion_date, 'DD/MM/YYYY HH24:MI:SS')   AS date_fin,
       ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2) AS duree_minutes,
       fcr.phase_code,
       fcr.status_code,
       fcr.argument_text
FROM   fnd_concurrent_requests fcr
JOIN   fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE  fcp.concurrent_program_name = 'DKA_IAPIMG_IVALUA'
  AND  fcr.actual_start_date >= TRUNC(SYSDATE) - 30
ORDER  BY fcr.actual_start_date DESC;
```

---

## 7. Contrôles et alertes

### Contrôle quotidien (détecté dans `DKA_IAPFACXGS_REPORTING_ALL`)

Le contrôle du matin surveille les **factures Xerox sans image** — une alerte est levée si des factures présentes dans `DKA_IAPFACXGS_REPORTING_ALL` n'ont pas d'image associée dans `FND_DOCUMENTS`.

```sql
-- Factures Xerox sans image (ALERTE)
SELECT dir.file_name,
       dir.invoice_num,
       dir.creation_date
FROM   dka_iapfacxgs_reporting_all dir
WHERE  TRUNC(dir.creation_date) = TRUNC(SYSDATE - 1)
  AND  dir.file_name NOT IN (
           SELECT file_name FROM dka_iapfac_debloc_hist_interf
           WHERE  TRUNC(creation_date) = TRUNC(SYSDATE - 1)
       );
```

### Vérification avant exécution

```sql
-- Volume des factures avec image à traiter
SELECT TO_CHAR(creation_date, 'YYYY-MM') AS mois,
       COUNT(*)                           AS nb_factures
FROM   ap_invoices_all
WHERE  creation_date >= TO_DATE('01/01/2026', 'DD/MM/YYYY')
  AND  creation_date <  TO_DATE('01/01/2027', 'DD/MM/YYYY')
  AND  attribute3 IS NOT NULL
GROUP  BY TO_CHAR(creation_date, 'YYYY-MM')
ORDER  BY mois;
```

### Vérification après exécution

```sql
-- Comparaison source vs URLs générées
SELECT 'URLs générées'    AS statut, COUNT(*) AS nb
FROM   dka_iapfac_images_url
WHERE  creation_date >= TRUNC(SYSDATE)
UNION ALL
SELECT 'Factures source'  AS statut, COUNT(*) AS nb
FROM   ap_invoices_all
WHERE  creation_date >= TO_DATE('01/01/2026', 'DD/MM/YYYY')
  AND  creation_date <  TO_DATE('01/01/2027', 'DD/MM/YYYY')
  AND  attribute3 IS NOT NULL;
```

---

## 8. Points d'attention et incidents connus

### 🔴 Date de fin à 00:00:00 (bogue potentiel)

L'appel historique utilisait `TO_DATE('31/12/2026 00:00:00', ...)` pour la date de fin, ce qui **exclut toutes les factures du 31 décembre**.

**Correction** :
```sql
-- ❌ Incorrect (exclut le 31 décembre)
TO_DATE('31/12/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS')

-- ✅ Correct
TO_DATE('31/12/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
```

### ⚠️ Batch non lancé (incident 17/03/2026)

Le 17/03/2026, `DKA_IAPIMG_IVALUA` n'a pas été exécuté (0 exécution à 03:43). Cet incident est documenté dans `controlMnonLance/Analyse_Batch_Non_Lance_17032026.md`.

### ⚠️ Volume estimé

| Source | Factures/jour (moy.) | Factures/an (estimé) |
|--------|---------------------|---------------------|
| Xerox | ~150–200 | ~55 000 |
| Tradeshift | ~50–100 | ~20 000 |
| DSP | Variable | ~10 000 |
| **TOTAL** | **~200–300** | **~85 000** |

Pour un traitement annuel, la durée estimée est de **5 à 10 minutes** (sans optimisation).

---

## 9. Procédure de renvoi d'une image

Voir le script [Renvoi_Image_Facture_Ivalua.sql](Renvoi_Image_Facture_Ivalua.sql) pour le détail complet.

### Contexte technique

Le programme `DKA_IAPIMG_IVALUA` lit la table de staging `DKA_JMETER_ST.EXTRACTION_FACTURE`.  
Cette table est alimentée par `DKA_GENERATE_URL_IMAGE_FACTURE`, qui filtre sur `LAST_UPDATE_DATE` (pas sur `CREATION_DATE`).  
Pour forcer le renvoi d'une image spécifique, il faut **insérer directement** dans cette table, puis relancer `DKA_IAPIMG_IVALUA`.

> ⚠️ `DKA_GENERATE_URL_IMAGE_FACTURE` commence toujours par un `DELETE` complet de `EXTRACTION_FACTURE`. Il faut relancer `DKA_IAPIMG_IVALUA` **immédiatement** après l'insertion manuelle, avant la prochaine exécution automatique de la procédure.

### Étapes

**1. Identifier la facture**
```sql
-- Trouver l'INVOICE_ID et l'URL générée
SELECT aia.invoice_id, aia.invoice_num,
       DKA_construct_download_url(fd.media_id) AS url_generee,
       fla.access_id
FROM   apps.ap_invoices_all aia
JOIN   apps.fnd_attached_documents fad  ON fad.pk1_value = aia.invoice_id AND fad.entity_name = 'AP_INVOICES'
JOIN   apps.fnd_documents fd            ON fd.document_id = fad.document_id
JOIN   apps.fnd_document_categories_tl fdct ON fdct.category_id = fd.category_id AND fdct.language = 'F' AND fdct.name = 'MISC'
JOIN   apps.fnd_lob_access fla          ON fla.file_id = fd.media_id
JOIN   apps.fnd_documents_tl fdt        ON fdt.document_id = fd.document_id AND fdt.language = 'F' AND fdt.description = 'IMAGE FACTURE'
JOIN   apps.fnd_document_datatypes fdat ON fdat.datatype_id = fd.datatype_id AND fdat.language = 'F' AND fdat.name = 'FILE'
WHERE  aia.invoice_num = :v_invoice_num;
```

**2. Insérer dans la table de staging**
```sql
BEGIN
    -- Nettoyer l'ancienne entrée
    DELETE FROM dka_jmeter_st.extraction_facture WHERE invoice_id = :v_invoice_id;

    -- Insérer l'URL régénérée
    INSERT INTO dka_jmeter_st.extraction_facture (invoice_id, url, access_id)
    SELECT invoice_id, url, access_id FROM (
        SELECT aia.invoice_id,
               DKA_construct_download_url(fd.media_id) url,
               TO_CHAR(fla.access_id) access_id,
               ROW_NUMBER() OVER (PARTITION BY aia.invoice_id ORDER BY fd.media_id DESC) ordre
        FROM   apps.ap_invoices_all aia
        JOIN   apps.fnd_attached_documents fad  ON fad.pk1_value = aia.invoice_id AND fad.entity_name = 'AP_INVOICES'
        JOIN   apps.fnd_documents fd            ON fd.document_id = fad.document_id
        JOIN   apps.fnd_document_categories_tl fdct ON fdct.category_id = fd.category_id AND fdct.language = 'F' AND fdct.name = 'MISC'
        JOIN   apps.fnd_lob_access fla          ON fla.file_id = fd.media_id
        JOIN   apps.fnd_documents_tl fdt        ON fdt.document_id = fd.document_id AND fdt.language = 'F' AND fdt.description = 'IMAGE FACTURE'
        JOIN   apps.fnd_document_datatypes fdat ON fdat.datatype_id = fd.datatype_id AND fdat.language = 'F' AND fdat.name = 'FILE'
        WHERE  aia.invoice_id = :v_invoice_id
    ) WHERE ordre = 1;

    -- Renouveler l'accès (expiry = 01/01/2050)
    UPDATE apps.fnd_lob_access
    SET    timestamp = TO_DATE('01/01/2050', 'DD/MM/YYYY')
    WHERE  access_id IN (SELECT TO_NUMBER(access_id) FROM dka_jmeter_st.extraction_facture WHERE invoice_id = :v_invoice_id)
      AND  timestamp <> TO_DATE('01/01/2050', 'DD/MM/YYYY');

    COMMIT;
END;
/
```

**3. Lancer immédiatement `DKA_IAPIMG_IVALUA`**  
Via EBS : Responsabilité Finance > Requêtes > Lancer > **"DKA : Export des images Factures vers iValua"**

---

## 10. Documents de référence

| Fichier | Description |
|---------|-------------|
| [FactureLitige/Analyse_DKA_GENERATE_URL_IMAGE_FACTURE.md](../FactureLitige/Analyse_DKA_GENERATE_URL_IMAGE_FACTURE.md) | Analyse détaillée de la procédure de génération d'URLs |
| [Rapport_Traitements_Fournisseurs_Oracle_EBS.md](../Rapport_Traitements_Fournisseurs_Oracle_EBS.md) | Section 5.3 — statistiques et description du programme |
| [Rapport_Traitements_Nuit_Oracle_EBS.md](../Rapport_Traitements_Nuit_Oracle_EBS.md) | Planning batch nuit — positionnement à 01:01 / 03:13 |
| [controlMnonLance/Analyse_Batch_Non_Lance_17032026.md](../controlMnonLance/Analyse_Batch_Non_Lance_17032026.md) | Incident du 17/03/2026 — batch non lancé |
| [ControleMatinGenerique/Controle_Quotidien_Complet.sql](../ControleMatinGenerique/Controle_Quotidien_Complet.sql) | Contrôle quotidien factures Xerox sans image |

---

*Dernière mise à jour : 11/05/2026 — GitHub Copilot*  
*Environnement : Oracle EBS 12.2.13 — DB 19.25.0.0.0*
