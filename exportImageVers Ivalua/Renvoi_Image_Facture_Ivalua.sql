-- =====================================================================
-- Renvoi d'une facture (données + image) vers iValua
-- =====================================================================
-- Date de création : 11/05/2026
-- Auteur : GitHub Copilot
-- Base de données : Oracle EBS 12.2.13 (DB 19.25.0.0.0)
--
-- =====================================================================
-- ARCHITECTURE DES DEUX PROGRAMMES
-- =====================================================================
--
-- DKA_IAPFAC_IVALUA  (données de factures)
--   ├─ Lit : DKA_PARAMETERS.DATE_VALUE où program_code = 'DKA_IAPFAC_IVALUA'
--   │         parameter_name = 'DATE_DERNIERE_EXECUTION'
--   ├─ Sélectionne : AP_INVOICES_ALL où LAST_UPDATE_DATE > DATE_DERNIERE_EXECUTION
--   │               (+ ap_invoice_lines_all, ap_holds_all, fnd_attached_documents)
--   ├─ Génère : CSV/ZIP → NAS → iValua
--   ├─ Déclenche automatiquement : DKA_IAPIMG_IVALUA (programme enfant)
--   └─ Met à jour : DATE_DERNIERE_EXECUTION = SYSDATE (en fin d'exécution)
--
-- DKA_IAPIMG_IVALUA  (images de factures) — script shell DKA_IAPIMGFAC_IVALUA
--   ├─ Appelé EN ENFANT par DKA_IAPFAC_IVALUA avec :
--   │   ARGUMENT1 = nom fichier (DSP01_INV_ENTETE_IMG_YYYYMMDDHH24MISS_ST_FIN01_{req_id})
--   │   ARGUMENT2 = date pivot (format DD/MM/YYYY"T"HH24:MI:SS)
--   ├─ Lit : DKA_JMETER_ST.EXTRACTION_FACTURE (peuplée par DKA_GENERATE_URL_IMAGE_FACTURE)
--   └─ Filtre les images par la date pivot passée en argument
--
-- CONCLUSION :
--   Pour renvoyer une facture COMPLÈTE (données + image), il suffit de
--   relancer DKA_IAPFAC_IVALUA après avoir "touché" la facture.
--   DKA_IAPIMG_IVALUA sera automatiquement lancé en sous-programme.
--
-- ⚠️  PRÉCONDITION IMAGE :
--   DKA_JMETER_ST.EXTRACTION_FACTURE doit contenir l'URL de la facture.
--   Si elle a été nettoyée (DELETE au début de DKA_GENERATE_URL_IMAGE_FACTURE),
--   relancer DKA_GENERATE_URL_IMAGE_FACTURE d'abord (voir ÉTAPE 2b).
--
-- VOIR : README.md, Analyse_Detaillee_Package_DKA_GENERATE_URL_IMAGE_FACTURE.md
-- =====================================================================


-- =====================================================================
-- ÉTAPE 0 : VÉRIFIER la date pivot actuelle et la facture
-- =====================================================================

-- Date pivot courante (seules les factures modifiées APRÈS cette date seront exportées)
SELECT program_code,
       parameter_name,
       TO_CHAR(date_value, 'DD/MM/YYYY HH24:MI:SS') AS date_derniere_execution
FROM   DKA_PARAMETERS
WHERE  program_code    = 'DKA_IAPFAC_IVALUA'
  AND  parameter_name  = 'DATE_DERNIERE_EXECUTION';
-- ⟹ Valeur au 11/05/2026 : 10/05/2026 00:50:54
-- Toute facture avec LAST_UPDATE_DATE <= cette date NE SERA PAS exportée


-- =====================================================================
-- ÉTAPE 1 : IDENTIFIER la facture et son image
-- =====================================================================
-- Remplacer :v_invoice_num par le numéro de facture à renvoyer

SELECT
    aia.invoice_id,
    aia.invoice_num,
    aia.invoice_date,
    aia.vendor_id,
    aia.amount,
    aia.last_update_date,
    fd.document_id,
    fd.media_id,
    fdt.description     AS doc_description,
    fdct.name           AS doc_category,
    fla.access_id,
    fla.timestamp       AS access_expiry,
    DKA_construct_download_url(fd.media_id) AS url_generee
FROM   apps.ap_invoices_all aia
JOIN   apps.fnd_attached_documents fad
    ON fad.pk1_value = aia.invoice_id
   AND fad.entity_name = 'AP_INVOICES'
JOIN   apps.fnd_documents fd
    ON fd.document_id = fad.document_id
JOIN   apps.fnd_document_categories_tl fdct
    ON fdct.category_id = fd.category_id
   AND fdct.language = 'F'
   AND fdct.name = 'MISC'
JOIN   apps.fnd_lob_access fla
    ON fla.file_id = fd.media_id
JOIN   apps.fnd_documents_tl fdt
    ON fdt.document_id = fd.document_id
   AND fdt.language = 'F'
   AND fdt.description = 'IMAGE FACTURE'
JOIN   apps.fnd_document_datatypes fdat
    ON fdat.datatype_id = fd.datatype_id
   AND fdat.language = 'F'
   AND fdat.name = 'FILE'
WHERE  aia.invoice_num = :v_invoice_num   -- ← remplacer par le numéro de facture
ORDER  BY fd.media_id DESC, fla.timestamp DESC
FETCH FIRST 5 ROWS ONLY;


-- =====================================================================
-- ÉTAPE 2 : VÉRIFIER l'état actuel dans la table de staging
-- =====================================================================
-- Vérifier si la facture est déjà présente dans EXTRACTION_FACTURE

SELECT *
FROM   dka_jmeter_st.extraction_facture
WHERE  invoice_id = :v_invoice_id;    -- ← invoice_id trouvé à l'étape 1


-- =====================================================================
-- ÉTAPE 3 : INSÉRER dans la table de staging pour renvoi
-- =====================================================================
-- Supprimer l'éventuelle ligne existante, puis insérer la nouvelle URL

BEGIN

    -- Supprimer l'ancienne entrée si elle existe
    DELETE FROM dka_jmeter_st.extraction_facture
    WHERE  invoice_id = :v_invoice_id;

    -- Insérer l'URL régénérée via l'API Oracle
    INSERT INTO dka_jmeter_st.extraction_facture (invoice_id, url, access_id)
    SELECT invoice_id, url, access_id
    FROM (
        SELECT
            aia.invoice_id,
            DKA_construct_download_url(fd.media_id)   url,
            TO_CHAR(fla.access_id)                    access_id,
            ROW_NUMBER() OVER (
                PARTITION BY aia.invoice_id
                ORDER BY fd.media_id DESC, fla.timestamp DESC
            ) ordre
        FROM   apps.ap_invoices_all aia
        JOIN   apps.fnd_attached_documents fad
            ON fad.pk1_value = aia.invoice_id
           AND fad.entity_name = 'AP_INVOICES'
        JOIN   apps.fnd_documents fd
            ON fd.document_id = fad.document_id
        JOIN   apps.fnd_document_categories_tl fdct
            ON fdct.category_id = fd.category_id
           AND fdct.language = 'F'
           AND fdct.name = 'MISC'
        JOIN   apps.fnd_lob_access fla
            ON fla.file_id = fd.media_id
        JOIN   apps.fnd_documents_tl fdt
            ON fdt.document_id = fd.document_id
           AND fdt.language = 'F'
           AND fdt.description = 'IMAGE FACTURE'
        JOIN   apps.fnd_document_datatypes fdat
            ON fdat.datatype_id = fd.datatype_id
           AND fdat.language = 'F'
           AND fdat.name = 'FILE'
        WHERE  aia.invoice_id = :v_invoice_id   -- ← invoice_id de la facture à renvoyer
    )
    WHERE ordre = 1;

    -- Renouveler l'accès FND_LOB_ACCESS (expiry = 01/01/2050, comme la procédure standard)
    UPDATE apps.fnd_lob_access
    SET    timestamp = TO_DATE('01/01/2050', 'DD/MM/YYYY')
    WHERE  access_id IN (
               SELECT TO_NUMBER(access_id)
               FROM   dka_jmeter_st.extraction_facture
               WHERE  invoice_id = :v_invoice_id
           )
      AND  timestamp <> TO_DATE('01/01/2050', 'DD/MM/YYYY');

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('✅ Facture ' || :v_invoice_id || ' insérée dans EXTRACTION_FACTURE — prête pour renvoi vers iValua.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('❌ Erreur : ' || SQLERRM);
        RAISE;
END;
/


-- =====================================================================
-- ÉTAPE 4 : VÉRIFIER l'insertion
-- =====================================================================

SELECT ef.invoice_id,
       ef.url,
       ef.access_id,
       aia.invoice_num,
       aia.invoice_date
FROM   dka_jmeter_st.extraction_facture ef
JOIN   apps.ap_invoices_all aia ON aia.invoice_id = ef.invoice_id
WHERE  ef.invoice_id = :v_invoice_id;


-- =====================================================================
-- ÉTAPE 5 : LANCER le programme concurrent DKA_IAPIMG_IVALUA
-- =====================================================================
-- À lancer IMMÉDIATEMENT après cette insertion, via :
--   EBS > Responsibility Finance > Requêtes > Lancer
--   Programme : "DKA : Export des images Factures vers iValua"
--
-- Ou via l'API FND_REQUEST si disponible :
/*
DECLARE
    v_request_id NUMBER;
BEGIN
    v_request_id := fnd_request.submit_request(
        application => 'DKA',
        program     => 'DKA_IAPIMG_IVALUA',
        description => NULL,
        start_time  => NULL,
        sub_request => FALSE
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Request ID lancé : ' || v_request_id);
END;
/
*/

-- =====================================================================
-- =====================================================================
-- MÉTHODE ALTERNATIVE (RECOMMANDÉE) : RENVOI COMPLET VIA DKA_IAPFAC_IVALUA
-- =====================================================================
-- Cette méthode renvoie à la fois les DONNÉES et l'IMAGE de la facture.
-- DKA_IAPFAC_IVALUA lance automatiquement DKA_IAPIMG_IVALUA en programme enfant.
-- =====================================================================

-- ÉTAPE A : Toucher la facture pour que LAST_UPDATE_DATE > DATE_DERNIERE_EXECUTION
-- ⚠️  Cette action met à jour LAST_UPDATE_DATE sur AP_INVOICES_ALL (traçabilité).
--     Elle est réversible mais visible dans l'historique de la facture.

BEGIN
    UPDATE ap_invoices_all
    SET    last_update_date = SYSDATE,
           last_updated_by  = fnd_global.user_id
    WHERE  invoice_id = :v_invoice_id;    -- ← invoice_id de la facture à renvoyer
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✅ LAST_UPDATE_DATE mis à SYSDATE pour invoice_id=' || :v_invoice_id);
    DBMS_OUTPUT.PUT_LINE('   DATE_DERNIERE_EXECUTION actuelle : 10/05/2026 00:50:54');
    DBMS_OUTPUT.PUT_LINE('   La facture sera sélectionnée au prochain run de DKA_IAPFAC_IVALUA');
END;
/


-- ÉTAPE B : Pré-peupler EXTRACTION_FACTURE pour l'image
--   (si la table a été vidée depuis la dernière exécution)
--   Ré-insérer l'URL de l'image pour que DKA_IAPIMG_IVALUA la trouve
BEGIN
    DELETE FROM dka_jmeter_st.extraction_facture WHERE invoice_id = :v_invoice_id;

    INSERT INTO dka_jmeter_st.extraction_facture (invoice_id, url, access_id)
    SELECT invoice_id, url, access_id FROM (
        SELECT aia.invoice_id,
               DKA_construct_download_url(fd.media_id) url,
               TO_CHAR(fla.access_id) access_id,
               ROW_NUMBER() OVER (PARTITION BY aia.invoice_id ORDER BY fd.media_id DESC, fla.timestamp DESC) ordre
        FROM   apps.ap_invoices_all aia
        JOIN   apps.fnd_attached_documents fad  ON fad.pk1_value = aia.invoice_id AND fad.entity_name = 'AP_INVOICES'
        JOIN   apps.fnd_documents fd            ON fd.document_id = fad.document_id
        JOIN   apps.fnd_document_categories_tl fdct ON fdct.category_id = fd.category_id AND fdct.language = 'F' AND fdct.name = 'MISC'
        JOIN   apps.fnd_lob_access fla          ON fla.file_id = fd.media_id
        JOIN   apps.fnd_documents_tl fdt        ON fdt.document_id = fd.document_id AND fdt.language = 'F' AND fdt.description = 'IMAGE FACTURE'
        JOIN   apps.fnd_document_datatypes fdat ON fdat.datatype_id = fd.datatype_id AND fdat.language = 'F' AND fdat.name = 'FILE'
        WHERE  aia.invoice_id = :v_invoice_id
    ) WHERE ordre = 1;

    -- Renouveler l'accès
    UPDATE apps.fnd_lob_access
    SET    timestamp = TO_DATE('01/01/2050', 'DD/MM/YYYY')
    WHERE  access_id IN (SELECT TO_NUMBER(access_id) FROM dka_jmeter_st.extraction_facture WHERE invoice_id = :v_invoice_id)
      AND  timestamp <> TO_DATE('01/01/2050', 'DD/MM/YYYY');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✅ EXTRACTION_FACTURE peuplée pour invoice_id=' || :v_invoice_id);
END;
/


-- ÉTAPE C : Lancer DKA_IAPFAC_IVALUA
--   EBS > Responsibility Finance > Requêtes > Lancer
--   Programme : "DKA : Export des données Factures vers iValua"
--   (il lancera automatiquement DKA_IAPIMG_IVALUA en programme enfant)
/*
DECLARE
    v_request_id NUMBER;
BEGIN
    v_request_id := fnd_request.submit_request(
        application => 'DKA',
        program     => 'DKA_IAPFAC_IVALUA',
        description => NULL,
        start_time  => NULL,
        sub_request => FALSE
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('DKA_IAPFAC_IVALUA lancé — Request ID : ' || v_request_id);
END;
/
*/


-- ÉTAPE D : Vérifier l'exécution (après fin du traitement)
SELECT fcr.request_id,
       fcp.user_concurrent_program_name                                              AS programme,
       TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS')                      AS debut,
       TO_CHAR(fcr.actual_completion_date, 'DD/MM/YYYY HH24:MI:SS')                 AS fin,
       ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2)     AS duree_min,
       fcr.status_code,
       fcr.parent_request_id
FROM   fnd_concurrent_requests fcr
JOIN   fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE  fcp.concurrent_program_name IN ('DKA_IAPFAC_IVALUA', 'DKA_IAPIMG_IVALUA')
  AND  fcr.actual_start_date >= TRUNC(SYSDATE)
ORDER  BY fcr.actual_start_date DESC;

-- =====================================================================
-- RENVOI DE PLUSIEURS FACTURES (variante en masse)
-- =====================================================================
-- Exemple : renvoyer toutes les factures d'hier sans image dans iValua
/*
BEGIN
    DELETE FROM dka_jmeter_st.extraction_facture;

    INSERT INTO dka_jmeter_st.extraction_facture (invoice_id, url, access_id)
    SELECT invoice_id, url, access_id
    FROM (
        SELECT
            aia.invoice_id,
            DKA_construct_download_url(fd.media_id)   url,
            TO_CHAR(fla.access_id)                    access_id,
            ROW_NUMBER() OVER (
                PARTITION BY aia.invoice_id
                ORDER BY fd.media_id DESC, fla.timestamp DESC
            ) ordre
        FROM   apps.ap_invoices_all aia
        JOIN   apps.fnd_attached_documents fad
            ON fad.pk1_value = aia.invoice_id
           AND fad.entity_name = 'AP_INVOICES'
        JOIN   apps.fnd_documents fd
            ON fd.document_id = fad.document_id
        JOIN   apps.fnd_document_categories_tl fdct
            ON fdct.category_id = fd.category_id
           AND fdct.language = 'F'
           AND fdct.name = 'MISC'
        JOIN   apps.fnd_lob_access fla
            ON fla.file_id = fd.media_id
        JOIN   apps.fnd_documents_tl fdt
            ON fdt.document_id = fd.document_id
           AND fdt.language = 'F'
           AND fdt.description = 'IMAGE FACTURE'
        JOIN   apps.fnd_document_datatypes fdat
            ON fdat.datatype_id = fd.datatype_id
           AND fdat.language = 'F'
           AND fdat.name = 'FILE'
        WHERE  aia.invoice_id IN (
                   -- Remplacer par la liste des INVOICE_ID à renvoyer
                   :v_invoice_id_1,
                   :v_invoice_id_2
               )
    )
    WHERE ordre = 1;

    UPDATE apps.fnd_lob_access
    SET    timestamp = TO_DATE('01/01/2050', 'DD/MM/YYYY')
    WHERE  access_id IN (
               SELECT TO_NUMBER(access_id) FROM dka_jmeter_st.extraction_facture
           )
      AND  timestamp <> TO_DATE('01/01/2050', 'DD/MM/YYYY');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✅ ' || SQL%ROWCOUNT || ' facture(s) prêtes pour renvoi.');
END;
/
*/
