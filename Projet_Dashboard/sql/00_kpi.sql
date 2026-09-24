-- SYNTHESE - Indicateurs du jour (ORDRE | KPI | VALEUR | STATUT)
-- Reecriture en SELECT du bloc PL/SQL "SECTION 2 : SYNTHESE GLOBALE" de
-- ControleMatinGenerique/Controle_Quotidien_Complet.sql, memes regles de statut.
-- Difference : pas de repli "controle indisponible" par bloc ; si une table est
-- absente, la requete entiere echoue et export_csv.bat conserve le CSV precedent.

WITH flux AS (
    SELECT COUNT(DISTINCT file_name) AS n
    FROM   (SELECT file_name FROM dka_ipofrs_hist_entetes       WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
            UNION ALL
            SELECT file_name FROM dka_ipocde_hist_headers       WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
            UNION ALL
            SELECT file_name FROM dka_iporec_hist_interface     WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
            UNION ALL
            SELECT file_name FROM dka_iapfac_debloc_hist_interf WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1))
), ndf AS (
    SELECT COUNT(*) AS n
    FROM   ap_invoices_all
    WHERE  attribute9 = 'NOT'
    AND    TRUNC(creation_date) = TRUNC(SYSDATE - 1)
), fac AS (
    SELECT NVL(SUM(CASE WHEN SUBSTR(imagefile, 1, 3) = 'VE1' THEN 1 ELSE 0 END), 0) AS xerox,
           NVL(SUM(CASE WHEN SUBSTR(imagefile, 1, 3) = 'L56' THEN 1 ELSE 0 END), 0) AS tradeshift,
           NVL(SUM(CASE WHEN SUBSTR(imagefile, 1, 3) = 'DSP' THEN 1 ELSE 0 END), 0) AS dsp
    FROM   dka_iapfacxgs_reporting_all
    WHERE  date_creation = TO_CHAR(SYSDATE - 1, 'YYYYMMDD')
), gli AS (
    SELECT COUNT(*) AS n FROM gl_interface WHERE date_created > TRUNC(SYSDATE - 1)
), gll AS (
    SELECT COUNT(*) AS n FROM gl_je_lines WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
), nuit AS (
    -- Meme regle que le script d'origine : un G "Request Completed Normal" n'est pas un warning.
    SELECT COUNT(*) AS total,
           NVL(SUM(CASE WHEN status_code = 'E' THEN 1 ELSE 0 END), 0) AS err,
           NVL(SUM(CASE WHEN status_code = 'G'
                         AND UPPER(TRIM(NVL(completion_text, '-')))
                             NOT IN ('REQUEST COMPLETED NORMAL', 'FIN NORMALE')
                        THEN 1 ELSE 0 END), 0) AS warn
    FROM   fnd_concurrent_requests
    WHERE  actual_start_date >= TRUNC(SYSDATE - 1) + &heure_fermeture / 24
    AND    actual_start_date <  TRUNC(SYSDATE)      + &heure_ouverture / 24
    AND    requested_by IN (SELECT user_id FROM fnd_user WHERE user_name LIKE 'EXP%')
), rb AS (
    -- Fenetre veille + jour : les imports RB sont dates tantot de l'un, tantot de l'autre.
    SELECT COUNT(*) AS n
    FROM   rb_batch_import
    WHERE  TRUNC(import_date) IN (TRUNC(SYSDATE - 1), TRUNC(SYSDATE))
), img AS (
    SELECT COUNT(DISTINCT dir.num_fact) AS n
    FROM   dka_iapfacxgs_reporting_all dir
    JOIN   ap_invoices_all aia ON aia.invoice_num = dir.num_fact AND aia.creation_date > SYSDATE - 30
    WHERE  dir.nom_fichier LIKE 'VE1_DAL%'
    AND    dir.date_creation = TO_CHAR(SYSDATE - 1, 'YYYYMMDD')
    AND    NOT EXISTS (SELECT 1 FROM fnd_documents fd
                       WHERE  fd.creation_date > SYSDATE - 30
                       AND    (SUBSTR(fd.file_name, 1, LENGTH(fd.file_name) - 4) = aia.attribute3
                               OR fd.file_name = aia.attribute3))
), demat AS (
    -- Factures dematerialisees recues mais pas encore integrees.
    SELECT COUNT(*) AS n FROM dka_demat_hdr WHERE status = 'INSERE'
)
SELECT ORDRE, KPI, VALEUR, STATUT FROM (
    SELECT 1  AS ORDRE, 'Flux DSP' AS KPI, flux.n AS VALEUR, CASE WHEN flux.n >= 5 THEN 'OK' ELSE 'W' END AS STATUT FROM flux
    UNION ALL SELECT 2,  'Notes de frais',          ndf.n,          CASE WHEN ndf.n > 0 THEN 'OK' ELSE 'W' END FROM ndf
    UNION ALL SELECT 3,  'Factures Xerox',          fac.xerox,      CASE WHEN fac.xerox > 0 THEN 'OK' ELSE 'W' END FROM fac
    UNION ALL SELECT 4,  'Factures Tradeshift',     fac.tradeshift, CASE WHEN fac.tradeshift > 0 THEN 'OK' ELSE 'W' END FROM fac
    UNION ALL SELECT 5,  'Factures DSP',            fac.dsp,        CASE WHEN fac.dsp = 0 AND flux.n >= 5 THEN 'OK' ELSE 'W' END FROM fac, flux
    UNION ALL SELECT 6,  'GL interface',            gli.n,          CASE WHEN gli.n > 0 THEN 'OK' ELSE 'W' END FROM gli
    UNION ALL SELECT 7,  'Lignes GL creees',        gll.n,          CASE WHEN gll.n > 0 THEN 'OK' ELSE 'W' END FROM gll
    UNION ALL SELECT 8,  'Imports RB',              rb.n,           CASE WHEN rb.n > 0 THEN 'OK' ELSE 'W' END FROM rb
    UNION ALL SELECT 9,  'Traitements nuit',        nuit.total,     'OK' FROM nuit
    UNION ALL SELECT 10, 'Erreurs nuit',            nuit.err,       CASE WHEN nuit.err > 0 THEN 'KO' ELSE 'OK' END FROM nuit
    UNION ALL SELECT 11, 'Avertissements nuit',     nuit.warn,      CASE WHEN nuit.warn > 0 THEN 'W' ELSE 'OK' END FROM nuit
    UNION ALL SELECT 12, 'Images Xerox manquantes', img.n,          CASE WHEN img.n > 0 THEN 'KO' ELSE 'OK' END FROM img
    UNION ALL SELECT 13, 'Factures demat en attente', demat.n,        CASE WHEN demat.n > 0 THEN 'W' ELSE 'OK' END FROM demat
)
ORDER BY ORDRE;
