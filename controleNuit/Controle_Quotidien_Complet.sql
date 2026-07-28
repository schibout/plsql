-- =====================================================================
-- Contrôle Quotidien Complet - Vérifications du Matin
-- =====================================================================
-- Date de création : 04/02/2026
-- Auteur : Copilot
-- Base de données : Oracle EBS 12.2.13
-- Outil : SQL Developer
--
-- OBJECTIF : Rapport de contrôle quotidien à exécuter chaque matin
--            pour vérifier les traitements de la nuit et les flux.
--
-- DOMAINES CONTRÔLÉS :
--   1. DSP (iValua) - Flux fournisseurs, commandes, réceptions, déblocage
--   2. Notes de frais (Notilus)
--   3. Factures (Xerox, Tradeshift, DSP)
--   4. Écritures GL (Interface et créations)
--   5. Traitements concurrents de la nuit
--   6. Rapprochement Bancaire (RB)
--
-- USAGE : Exécuter chaque matin avant 9h
-- =====================================================================

-- =============================================================================
-- SECTION 1 : PARAMÈTRES
-- =============================================================================

VAR v_nb_jours_histo   NUMBER;
VAR v_heure_fermeture  NUMBER;
VAR v_heure_ouverture  NUMBER;

BEGIN
    -- =========================================================================
    -- PARAMÈTRES GÉNÉRAUX
    -- =========================================================================
    :v_nb_jours_histo   := 3;    -- Nombre de jours d'historique à afficher
    :v_heure_fermeture  := 19;   -- Heure de fermeture du service (19h)
    :v_heure_ouverture  := 7;    -- Heure d'ouverture du service (7h)
    -- =========================================================================
END;
/

-- Affichage des paramètres et date du jour
SELECT TO_CHAR(SYSDATE, 'DD/MM/YYYY') AS "Date du contrôle",
       TO_CHAR(SYSDATE, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH') AS "Jour",
       :v_nb_jours_histo AS "Jours historique",
       :v_heure_fermeture || 'h - ' || :v_heure_ouverture || 'h' AS "Plage nuit"
FROM   DUAL;

SET SERVEROUTPUT ON SIZE UNLIMITED

-- =============================================================================
-- SECTION 2 : SYNTHÈSE GLOBALE
-- =============================================================================

DECLARE
    v_nb_flux_dsp       NUMBER := 0;
    v_nb_ndf            NUMBER := 0;
    v_nb_fac_xerox      NUMBER := 0;
    v_nb_fac_tradeshift NUMBER := 0;
    v_nb_fac_dsp        NUMBER := 0;
    v_nb_gl_interface   NUMBER := 0;
    v_nb_gl_lignes      NUMBER := 0;
    v_nb_traitements    NUMBER := 0;
    v_nb_erreurs        NUMBER := 0;
    v_nb_warnings       NUMBER := 0;
    v_nb_rb_imports     NUMBER := 0;
    v_nb_images_manq    NUMBER := 0;
    v_stat_flux_dsp      VARCHAR2(2) := 'W';
    v_stat_ndf           VARCHAR2(2) := 'W';
    v_stat_xerox         VARCHAR2(2) := 'W';
    v_stat_tradeshift    VARCHAR2(2) := 'W';
    v_stat_fac_dsp       VARCHAR2(2) := 'W';
    v_stat_gl_interface  VARCHAR2(2) := 'W';
    v_stat_gl_lignes     VARCHAR2(2) := 'W';
    v_stat_rb_imports    VARCHAR2(2) := 'W';
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('RAPPORT DE CONTRÔLE QUOTIDIEN - ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE('Jour : ' || TO_CHAR(SYSDATE, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'));
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Comptage flux DSP (hier)
    SELECT COUNT(DISTINCT file_name)
    INTO   v_nb_flux_dsp
    FROM   (
        SELECT file_name FROM dka_ipofrs_hist_entetes WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
        UNION ALL
        SELECT file_name FROM dka_ipocde_hist_headers WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
        UNION ALL
        SELECT file_name FROM dka_iporec_hist_interface WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
        UNION ALL
        SELECT file_name FROM dka_iapfac_debloc_hist_interf WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
    );
    
    -- Comptage Notes de frais (hier)
    SELECT COUNT(*)
    INTO   v_nb_ndf
    FROM   ap_invoices_all
    WHERE  attribute9 = 'NOT'
    AND    TRUNC(creation_date) = TRUNC(SYSDATE - 1);
    
    -- Comptage factures par source (hier)
    BEGIN
        SELECT NVL(SUM(CASE WHEN SUBSTR(imagefile, 1, 3) = 'VE1' THEN 1 ELSE 0 END), 0),
               NVL(SUM(CASE WHEN SUBSTR(imagefile, 1, 3) = 'L56' THEN 1 ELSE 0 END), 0),
               NVL(SUM(CASE WHEN SUBSTR(imagefile, 1, 3) = 'DSP' THEN 1 ELSE 0 END), 0)
        INTO   v_nb_fac_xerox, v_nb_fac_tradeshift, v_nb_fac_dsp
        FROM   dka_iapfacxgs_reporting_all
        WHERE  date_creation = TO_CHAR(SYSDATE - 1, 'YYYYMMDD');
    EXCEPTION
        WHEN OTHERS THEN
            v_nb_fac_xerox := 0;
            v_nb_fac_tradeshift := 0;
            v_nb_fac_dsp := 0;
    END;
    
    -- Comptage écritures GL interface
    SELECT COUNT(*)
    INTO   v_nb_gl_interface
    FROM   gl_interface
    WHERE  date_created > TRUNC(SYSDATE - 1);
    
    -- Comptage lignes GL créées hier
    SELECT COUNT(*)
    INTO   v_nb_gl_lignes
    FROM   gl_je_lines
    WHERE  TRUNC(creation_date) = TRUNC(SYSDATE - 1);
    
    -- Comptage traitements nuit + erreurs
    SELECT COUNT(*),
           SUM(CASE WHEN status_code = 'E' THEN 1 ELSE 0 END),
           SUM(CASE WHEN status_code = 'G' THEN 1 ELSE 0 END)
    INTO   v_nb_traitements, v_nb_erreurs, v_nb_warnings
    FROM   fnd_concurrent_requests
    WHERE  actual_start_date >= TRUNC(SYSDATE - 1) + :v_heure_fermeture / 24
    AND    actual_start_date < TRUNC(SYSDATE) + :v_heure_ouverture / 24;
    
    -- Comptage imports RB
    BEGIN
        SELECT COUNT(*)
        INTO   v_nb_rb_imports
        FROM   rb_batch_import
        WHERE  TRUNC(import_date) = TRUNC(SYSDATE - 1);
    EXCEPTION
        WHEN OTHERS THEN v_nb_rb_imports := 0;
    END;
    
    -- Comptage images manquantes Xerox
    BEGIN
        SELECT COUNT(*)
        INTO   v_nb_images_manq
        FROM   dka_iapfacxgs_reporting_all dir
        JOIN   ap_invoices_all aia ON aia.invoice_num = dir.num_fact AND aia.creation_date > SYSDATE - 30
        WHERE  dir.nom_fichier LIKE 'VE1_DAL%'
        AND    dir.date_creation = TO_CHAR(SYSDATE - 1, 'YYYYMMDD')
        AND    NOT EXISTS (
            SELECT 1
            FROM   fnd_documents fd
            WHERE  fd.creation_date > SYSDATE - 30
            AND    (SUBSTR(fd.file_name, 1, LENGTH(fd.file_name) - 4) = aia.attribute3
                    OR fd.file_name = aia.attribute3)
        );
    EXCEPTION
        WHEN OTHERS THEN v_nb_images_manq := 0;
    END;

    -- Détermination des statuts (OK/W)
    IF v_nb_flux_dsp = 5 THEN
        v_stat_flux_dsp := 'OK';
    END IF;

    IF v_nb_ndf > 0 THEN
        v_stat_ndf := 'OK';
    END IF;

    IF v_nb_fac_xerox > 0 THEN
        v_stat_xerox := 'OK';
    END IF;

    IF v_nb_fac_tradeshift > 0 THEN
        v_stat_tradeshift := 'OK';
    END IF;

    IF v_nb_fac_dsp = 0 AND v_nb_flux_dsp = 5 THEN
        v_stat_fac_dsp := 'OK';
    END IF;

    IF v_nb_gl_interface > 0 THEN
        v_stat_gl_interface := 'OK';
    END IF;

    IF v_nb_gl_lignes > 0 THEN
        v_stat_gl_lignes := 'OK';
    END IF;

    IF v_nb_rb_imports > 0 THEN
        v_stat_rb_imports := 'OK';
    END IF;
    
    -- Affichage synthèse
    DBMS_OUTPUT.PUT_LINE('┌──────────────────────────────────────────────────────────┐');
    DBMS_OUTPUT.PUT_LINE('│                      SYNTHÈSE DU JOUR                    │');
    DBMS_OUTPUT.PUT_LINE('├──────────────────────────────────────────────────────────┤');
    DBMS_OUTPUT.PUT_LINE('│ Flux DSP (fichiers)         : ' || LPAD(v_nb_flux_dsp, 5) || '   [' || v_stat_flux_dsp || '] │');
    DBMS_OUTPUT.PUT_LINE('│ Notes de frais Notilus      : ' || LPAD(v_nb_ndf, 5) || '   [' || v_stat_ndf || '] │');
    DBMS_OUTPUT.PUT_LINE('│ Factures Xerox              : ' || LPAD(v_nb_fac_xerox, 5) || '   [' || v_stat_xerox || '] │');
    DBMS_OUTPUT.PUT_LINE('│ Factures Tradeshift         : ' || LPAD(v_nb_fac_tradeshift, 6) || '   [' || v_stat_tradeshift || '] │');
    DBMS_OUTPUT.PUT_LINE('│ Factures DSP                : ' || LPAD(v_nb_fac_dsp, 5) || '   [' || v_stat_fac_dsp || '] │');
    DBMS_OUTPUT.PUT_LINE('│ Écritures GL (interface)    : ' || LPAD(v_nb_gl_interface, 5) || '   [' || v_stat_gl_interface || '] │');
    DBMS_OUTPUT.PUT_LINE('│ Lignes GL créées            : ' || LPAD(v_nb_gl_lignes, 5) || '   [' || v_stat_gl_lignes || '] │');
    DBMS_OUTPUT.PUT_LINE('│ Imports RB                  : ' || LPAD(v_nb_rb_imports, 5) || '   [' || v_stat_rb_imports || '] │');
    DBMS_OUTPUT.PUT_LINE('├──────────────────────────────────────────────────────────┤');
    DBMS_OUTPUT.PUT_LINE('│ Traitements nuit            : ' || LPAD(v_nb_traitements, 5) || '              │');
    
    IF v_nb_erreurs > 0 THEN
        DBMS_OUTPUT.PUT_LINE('│ *** ERREURS ***             : ' || LPAD(v_nb_erreurs, 5) || '            │');
    ELSE
        DBMS_OUTPUT.PUT_LINE('│ Erreurs                     : ' || LPAD(v_nb_erreurs, 5) || '            │');
    END IF;
    
    IF v_nb_warnings > 0 THEN
        DBMS_OUTPUT.PUT_LINE('│ Avertissements              : ' || LPAD(v_nb_warnings, 5) || '            │');
    END IF;
    
    IF v_nb_images_manq > 0 THEN
        DBMS_OUTPUT.PUT_LINE('│ *** IMAGES MANQUANTES ***   : ' || LPAD(v_nb_images_manq, 5) || '            │');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('└──────────────────────────────────────────────────────────┘');
    
    -- Alertes
    DBMS_OUTPUT.PUT_LINE('');
    IF v_nb_erreurs > 0 THEN
        DBMS_OUTPUT.PUT_LINE('⚠️  ALERTE : ' || v_nb_erreurs || ' traitement(s) en ERREUR - Voir Section 6');
    END IF;
    IF v_nb_flux_dsp < 5 AND TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') NOT IN ('SAT', 'SUN', 'MON') THEN
        DBMS_OUTPUT.PUT_LINE('⚠️  ALERTE : Moins de 5 flux DSP attendus (normal: 5/jour ouvré)');
    END IF;
    IF v_nb_images_manq > 0 THEN
        DBMS_OUTPUT.PUT_LINE('⚠️  ALERTE : ' || v_nb_images_manq || ' factures Xerox sans image - Voir Section 4');
    END IF;
    IF TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') = 'MON' AND v_nb_rb_imports = 0 THEN
        DBMS_OUTPUT.PUT_LINE('⚠️  RAPPEL LUNDI : Charger manuellement le fichier SG (rattrapage)');
    END IF;
    
END;
/

-- =============================================================================
-- SECTION 3 : FLUX DSP (iValua)
-- =============================================================================
-- Attendu jours ouvrés : 5 fichiers (2 SUP, 1 CDE, 1 REC, 1 DEBLOC)

BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== DSP - Détail des flux (fichiers) ===');
END;
/

SELECT 'DSP' AS CONTROLE,
       date_creation,
       jour_creation,
       CASE 
           WHEN file_name LIKE '%SUP%' THEN 'FOURNISSEURS'
           WHEN file_name LIKE '%CDE%' OR file_name LIKE 'ORDER%' THEN 'COMMANDES'
           WHEN file_name LIKE '%REC%' THEN 'RECEPTIONS'
           WHEN file_name LIKE '%DEB%' OR file_name LIKE '%DEBLOC%' THEN 'DEBLOCAGE'
           ELSE 'AUTRE'
       END AS TYPE_FLUX,
       file_name
FROM (
    -- Fournisseurs
    SELECT DISTINCT TRUNC(dih.creation_date) AS date_creation,
           TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH') AS jour_creation,
           dih.file_name
    FROM   dka_ipofrs_hist_entetes dih
    WHERE  dih.creation_date > SYSDATE - :v_nb_jours_histo
    
    UNION ALL
    
    -- Commandes
    SELECT DISTINCT TRUNC(dih.creation_date),
           TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'),
           dih.file_name
    FROM   dka_ipocde_hist_headers dih
    WHERE  dih.creation_date > SYSDATE - :v_nb_jours_histo
    
    UNION ALL
    
    -- Réceptions
    SELECT DISTINCT TRUNC(dih.creation_date),
           TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'),
           dih.file_name
    FROM   dka_iporec_hist_interface dih
    WHERE  dih.creation_date > SYSDATE - :v_nb_jours_histo
    
    UNION ALL
    
    -- Déblocage
    SELECT DISTINCT TRUNC(dih.creation_date),
           TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'),
           dih.file_name
    FROM   dka_iapfac_debloc_hist_interf dih
    WHERE  dih.creation_date > SYSDATE - :v_nb_jours_histo
)
ORDER BY date_creation DESC, TYPE_FLUX, file_name;

-- Synthèse par jour et type de flux
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== DSP - Synthèse par jour et type ===');
END;
/
SELECT date_creation,
       jour_creation,
       SUM(CASE WHEN TYPE_FLUX = 'FOURNISSEURS' THEN 1 ELSE 0 END) AS NB_SUP,
       SUM(CASE WHEN TYPE_FLUX = 'COMMANDES' THEN 1 ELSE 0 END) AS NB_CDE,
       SUM(CASE WHEN TYPE_FLUX = 'RECEPTIONS' THEN 1 ELSE 0 END) AS NB_REC,
       SUM(CASE WHEN TYPE_FLUX = 'DEBLOCAGE' THEN 1 ELSE 0 END) AS NB_DEB,
       COUNT(*) AS TOTAL
FROM (
    SELECT DISTINCT TRUNC(dih.creation_date) AS date_creation,
           TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH') AS jour_creation,
           'FOURNISSEURS' AS TYPE_FLUX
    FROM   dka_ipofrs_hist_entetes dih
    WHERE  dih.creation_date > SYSDATE - :v_nb_jours_histo
    UNION ALL
    SELECT DISTINCT TRUNC(dih.creation_date), TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'), 'COMMANDES'
    FROM   dka_ipocde_hist_headers dih WHERE dih.creation_date > SYSDATE - :v_nb_jours_histo
    UNION ALL
    SELECT DISTINCT TRUNC(dih.creation_date), TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'), 'RECEPTIONS'
    FROM   dka_iporec_hist_interface dih WHERE dih.creation_date > SYSDATE - :v_nb_jours_histo
    UNION ALL
    SELECT DISTINCT TRUNC(dih.creation_date), TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'), 'DEBLOCAGE'
    FROM   dka_iapfac_debloc_hist_interf dih WHERE dih.creation_date > SYSDATE - :v_nb_jours_histo
)
GROUP BY date_creation, jour_creation
ORDER BY date_creation DESC;

-- =============================================================================
-- SECTION 4 : NOTES DE FRAIS (Notilus)
-- =============================================================================
-- Des NdF sont normalement créées tous les jours ouvrés

BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== NOTILUS - Comptage des notes de frais ===');
END;
/
SELECT 'NOTILUS' AS CONTROLE,
       TRUNC(creation_date) AS date_creation,
       TO_CHAR(creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH') AS jour,
       COUNT(*) AS nb_ndf,
       SUM(invoice_amount) AS montant_total
FROM   ap_invoices_all
WHERE  attribute9 = 'NOT'
AND    creation_date > SYSDATE - :v_nb_jours_histo
GROUP BY TRUNC(creation_date), TO_CHAR(creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH')
ORDER BY TRUNC(creation_date) DESC;

-- =============================================================================
-- SECTION 5 : FACTURES (Xerox, Tradeshift, DSP)
-- =============================================================================
-- Attendu jours ouvrés : 3 fichiers (XEROX, TRADESHIFT, DSP)
-- Samedi/Dimanche : 1 fichier TRADESHIFT possible

BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== FACTURES - Synthèse par source ===');
END;
/
SELECT 'FACTURES' AS CONTROLE,
       date_creation,
       DECODE(SUBSTR(imagefile, 1, 3),
              'VE1', 'XEROX',
              'L56', 'TRADESHIFT',
              'DSP', 'DSP',
              'AUTRES') AS SOURCE,
       COUNT(*) AS nb_factures
FROM   dka_iapfacxgs_reporting_all
WHERE  TO_DATE(date_creation, 'YYYYMMDD') > SYSDATE - :v_nb_jours_histo
GROUP BY date_creation, DECODE(SUBSTR(imagefile, 1, 3), 'VE1', 'XEROX', 'L56', 'TRADESHIFT', 'DSP', 'DSP', 'AUTRES')
ORDER BY date_creation DESC, SOURCE;

-- Factures Xerox SANS images (ALERTE)
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== XEROX - Factures SANS images (ALERTE) ===');
END;
/
SELECT 'XEROX_SANS_IMAGE' AS ALERTE,
       dir.date_creation,
       dir.num_fact,
       dir.reference_lad,
       aia.invoice_id,
       aia.vendor_id
FROM   dka_iapfacxgs_reporting_all dir
JOIN   ap_invoices_all aia ON aia.invoice_num = dir.num_fact AND aia.creation_date > SYSDATE - 30
WHERE  dir.nom_fichier LIKE 'VE1_DAL%'
AND    dir.date_creation = TO_CHAR(SYSDATE - 1, 'YYYYMMDD')
AND    NOT EXISTS (
    SELECT 1
    FROM   fnd_documents fd
    WHERE  fd.creation_date > SYSDATE - 30
    AND    (SUBSTR(fd.file_name, 1, LENGTH(fd.file_name) - 4) = aia.attribute3
            OR fd.file_name = aia.attribute3)
);

-- Nombre de factures Xerox AVEC images (OK)
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== XEROX - Factures AVEC images (OK) ===');
END;
/
SELECT 'XEROX_AVEC_IMAGE' AS STATUT,
       COUNT(*) AS nb_ok
FROM   dka_iapfacxgs_reporting_all dir
JOIN   ap_invoices_all aia ON aia.invoice_num = dir.num_fact AND aia.creation_date > SYSDATE - 30
JOIN   fnd_documents fd ON fd.creation_date > SYSDATE - 30
       AND (SUBSTR(fd.file_name, 1, LENGTH(fd.file_name) - 4) = aia.attribute3
            OR fd.file_name = aia.attribute3)
WHERE  dir.nom_fichier LIKE 'VE1_DAL%'
AND    dir.date_creation = TO_CHAR(SYSDATE - 1, 'YYYYMMDD');

-- =============================================================================
-- SECTION 6 : ÉCRITURES GL
-- =============================================================================

-- Lignes en interface (en attente de traitement)
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== GL - Interface (en attente) ===');
END;
/
SELECT 'GL_INTERFACE' AS CONTROLE,
       attribute10 AS SOURCE,
       attribute9 AS TYPE,
       status,
       COUNT(*) AS nb_lignes,
       SUM(entered_dr) AS total_debit,
       SUM(entered_cr) AS total_credit
FROM   gl_interface
GROUP BY attribute10, attribute9, status
ORDER BY attribute10, attribute9;

-- Lignes GL créées ces derniers jours
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== GL - Lignes créées ===');
END;
/
SELECT 'GL_CREES' AS CONTROLE,
       TRUNC(creation_date) AS date_creation,
       attribute10 AS SOURCE,
       COUNT(*) AS nb_lignes,
       SUM(entered_dr) AS total_debit
FROM   gl_je_lines
WHERE  creation_date > SYSDATE - :v_nb_jours_histo
GROUP BY TRUNC(creation_date), attribute10
ORDER BY TRUNC(creation_date) DESC, attribute10 DESC;

-- =============================================================================
-- SECTION 7 : TRAITEMENTS DE LA NUIT
-- =============================================================================
-- Plage : 19h (veille) à 7h (matin)

-- Synthèse par statut
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== NUIT - Synthèse par statut ===');
END;
/
SELECT 'NUIT_SYNTHESE' AS CONTROLE,
       CASE status_code
           WHEN 'C' THEN 'OK'
           WHEN 'E' THEN '*** ERREUR ***'
           WHEN 'G' THEN 'WARNING'
           WHEN 'R' THEN 'EN COURS'
           WHEN 'W' THEN 'EN ATTENTE'
           ELSE 'AUTRE (' || status_code || ')'
       END AS statut,
       COUNT(*) AS nb
FROM   fnd_concurrent_requests
WHERE  actual_start_date >= TRUNC(SYSDATE - 1) + :v_heure_fermeture / 24
AND    actual_start_date < TRUNC(SYSDATE) + :v_heure_ouverture / 24
GROUP BY CASE status_code
           WHEN 'C' THEN 'OK'
           WHEN 'E' THEN '*** ERREUR ***'
           WHEN 'G' THEN 'WARNING'
           WHEN 'R' THEN 'EN COURS'
           WHEN 'W' THEN 'EN ATTENTE'
           ELSE 'AUTRE (' || status_code || ')'
       END
ORDER BY 1;

-- Détail des ERREURS
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== NUIT - Détail des ERREURS ===');
END;
/
SELECT 'ERREUR' AS ALERTE,
       fcr.request_id,
       fcp.user_concurrent_program_name AS programme,
       TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS') AS debut,
       TO_CHAR(fcr.actual_completion_date, 'DD/MM HH24:MI:SS') AS fin,
       ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 1) AS duree_min,
       SUBSTR(fcr.completion_text, 1, 100) AS message
FROM   fnd_concurrent_requests fcr
JOIN   fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + :v_heure_fermeture / 24
AND    fcr.actual_start_date < TRUNC(SYSDATE) + :v_heure_ouverture / 24
AND    fcr.status_code = 'E'
ORDER BY fcr.actual_start_date DESC;

-- Détail des WARNINGS
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== NUIT - Détail des WARNINGS ===');
END;
/
SELECT 'WARNING' AS ALERTE,
       fcr.request_id,
       fcp.user_concurrent_program_name AS programme,
       TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS') AS debut,
       ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 1) AS duree_min,
       SUBSTR(fcr.completion_text, 1, 100) AS message
FROM   fnd_concurrent_requests fcr
JOIN   fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + :v_heure_fermeture / 24
AND    fcr.actual_start_date < TRUNC(SYSDATE) + :v_heure_ouverture / 24
AND    fcr.status_code = 'G'
ORDER BY fcr.actual_start_date DESC;

-- Traitements LONGS (> 30 minutes)
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== NUIT - Traitements longs (> 30 min) ===');
END;
/
SELECT 'LONG' AS TYPE,
       fcr.request_id,
       fcp.user_concurrent_program_name AS programme,
       TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI') AS debut,
       TO_CHAR(fcr.actual_completion_date, 'DD/MM HH24:MI') AS fin,
       ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 1) AS duree_min,
       CASE fcr.status_code WHEN 'C' THEN 'OK' WHEN 'E' THEN 'ERREUR' WHEN 'G' THEN 'WARNING' ELSE fcr.status_code END AS statut
FROM   fnd_concurrent_requests fcr
JOIN   fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + :v_heure_fermeture / 24
AND    fcr.actual_start_date < TRUNC(SYSDATE) + :v_heure_ouverture / 24
AND    (fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60 > 30
ORDER BY (fcr.actual_completion_date - fcr.actual_start_date) DESC;

-- Traitements EN COURS (potentiellement bloqués)
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== NUIT - Traitements en cours ===');
END;
/
SELECT 'EN_COURS' AS ALERTE,
       fcr.request_id,
       fcp.user_concurrent_program_name AS programme,
       TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS') AS debut,
       ROUND((SYSDATE - fcr.actual_start_date) * 24 * 60, 1) AS duree_actuelle_min,
       fcr.argument_text AS parametres
FROM   fnd_concurrent_requests fcr
JOIN   fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + :v_heure_fermeture / 24
AND    fcr.status_code = 'R'
ORDER BY fcr.actual_start_date;

-- =============================================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== RAPPROCHEMENT BANCAIRE (RB) ===');
END;
/
-- =============================================================================
-- Chargements automatiques : tous les jours sauf dimanche et lundi
-- RAPPEL : Le lundi, charger manuellement le fichier SG

SELECT 'RB_IMPORTS' AS CONTROLE,
       TRUNC(import_date) AS date_import,
       TO_CHAR(import_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH') AS jour,
       COUNT(*) AS nb_comptes
FROM   rb_batch_import
WHERE  import_date > SYSDATE - :v_nb_jours_histo
GROUP BY TRUNC(import_date), TO_CHAR(import_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH')
ORDER BY TRUNC(import_date) DESC;

-- =============================================================================
-- FIN DU RAPPORT
-- =============================================================================

DECLARE
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('FIN DU CONTRÔLE QUOTIDIEN - ' || TO_CHAR(SYSDATE, 'HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('=====================================================');
END;
/
