-- =====================================================================
-- Controle Quotidien Complet - Verifications du Matin
-- =====================================================================
-- Date de creation : 04/02/2026
-- Auteur : Copilot
-- Base de donnees : Oracle EBS 12.2.13
-- Outil : SQL*Plus / SQLcl
--
-- OBJECTIF : Rapport de controle quotidien a executer chaque matin
--            pour verifier les traitements de la nuit et les flux.
--
-- DOMAINES CONTROLES :
--   1. DSP (iValua) - Flux fournisseurs, commandes, receptions, deblocage
--   2. Notes de frais (Notilus)
--   3. Factures (Xerox, Tradeshift, DSP)
--   4. Ecritures GL (Interface et creations)
--   5. Traitements concurrents de la nuit
--   6. Rapprochement Bancaire (RB)
--
-- USAGE : Executer chaque matin avant 9h
-- =====================================================================

-- =============================================================================
-- SECTION 1 : PARAMETRES
-- =============================================================================

SET FEEDBACK OFF
SET VERIFY OFF

VAR v_nb_jours_histo   NUMBER;
VAR v_heure_fermeture  NUMBER;
VAR v_heure_ouverture  NUMBER;

BEGIN
    :v_nb_jours_histo   := 3;
    :v_heure_fermeture  := 19;
    :v_heure_ouverture  := 7;
END;
/

-- Formats explicites : sans eux, la colonne "Plage nuit" prend la largeur
-- maximale d'un VARCHAR2 et fait passer l'en-tete sur plusieurs lignes.
COLUMN DATE_CTRL FORMAT A12 HEADING "DATE"
COLUMN JOUR      FORMAT A10 HEADING "JOUR"
COLUMN HISTO     FORMAT 999 HEADING "HISTO(j)"
COLUMN PLAGE     FORMAT A12 HEADING "PLAGE NUIT"

SELECT TO_CHAR(SYSDATE, 'DD/MM/YYYY')                             AS DATE_CTRL,
       RTRIM(TO_CHAR(SYSDATE, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH')) AS JOUR,
       :v_nb_jours_histo                                          AS HISTO,
       :v_heure_fermeture || 'h - ' || :v_heure_ouverture || 'h'  AS PLAGE
FROM   DUAL;

CLEAR COLUMNS

SET SERVEROUTPUT ON SIZE UNLIMITED

-- =============================================================================
-- SECTION 2 : SYNTHESE GLOBALE
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
    v_date_rb_max        DATE;
    -- Drapeaux de controle indisponible : un bloc qui echoue ne doit pas
    -- rendre un zero rassurant, il doit se signaler comme non controle.
    v_err_rb             VARCHAR2(1) := 'N';
    v_err_img            VARCHAR2(1) := 'N';
    v_err_fac            VARCHAR2(1) := 'N';
BEGIN
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('RAPPORT DE CONTROLE QUOTIDIEN - ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE('Jour : ' || TO_CHAR(SYSDATE, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'));
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('');

    SELECT COUNT(DISTINCT file_name)
    INTO   v_nb_flux_dsp
    FROM   (SELECT file_name FROM dka_ipofrs_hist_entetes      WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
            UNION ALL
            SELECT file_name FROM dka_ipocde_hist_headers      WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
            UNION ALL
            SELECT file_name FROM dka_iporec_hist_interface    WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1)
            UNION ALL
            SELECT file_name FROM dka_iapfac_debloc_hist_interf WHERE TRUNC(creation_date) = TRUNC(SYSDATE - 1));

    SELECT COUNT(*) INTO v_nb_ndf
    FROM   ap_invoices_all
    WHERE  attribute9 = 'NOT'
    AND    TRUNC(creation_date) = TRUNC(SYSDATE - 1);

    BEGIN
        SELECT NVL(SUM(CASE WHEN SUBSTR(imagefile, 1, 3) = 'VE1' THEN 1 ELSE 0 END), 0),
               NVL(SUM(CASE WHEN SUBSTR(imagefile, 1, 3) = 'L56' THEN 1 ELSE 0 END), 0),
               NVL(SUM(CASE WHEN SUBSTR(imagefile, 1, 3) = 'DSP' THEN 1 ELSE 0 END), 0)
        INTO   v_nb_fac_xerox, v_nb_fac_tradeshift, v_nb_fac_dsp
        FROM   dka_iapfacxgs_reporting_all
        WHERE  date_creation = TO_CHAR(SYSDATE - 1, 'YYYYMMDD');
    EXCEPTION
        WHEN OTHERS THEN v_err_fac := 'Y';
    END;

    SELECT COUNT(*) INTO v_nb_gl_interface
    FROM   gl_interface
    WHERE  date_created > TRUNC(SYSDATE - 1);

    SELECT COUNT(*) INTO v_nb_gl_lignes
    FROM   gl_je_lines
    WHERE  TRUNC(creation_date) = TRUNC(SYSDATE - 1);

    -- IN et non = : plusieurs comptes peuvent commencer par EXP. Avec '=',
    -- deux comptes donnent ORA-01427, et zero compte donne NULL donc aucune
    -- ligne -- le rapport annoncerait alors 0 traitement de nuit.
    -- NVL sur les SUM : sur un ensemble vide, SUM rend NULL et non 0, ce qui
    -- desamorce le test IF v_nb_erreurs > 0 et tronque la ligne d'affichage.
    SELECT COUNT(*),
           NVL(SUM(CASE WHEN status_code = 'E' THEN 1 ELSE 0 END), 0),
           NVL(SUM(CASE WHEN status_code = 'G' THEN 1 ELSE 0 END), 0)
    INTO   v_nb_traitements, v_nb_erreurs, v_nb_warnings
    FROM   fnd_concurrent_requests
    WHERE  actual_start_date >= TRUNC(SYSDATE - 1) + :v_heure_fermeture / 24
    AND    actual_start_date <  TRUNC(SYSDATE)      + :v_heure_ouverture / 24
    AND    requested_by IN (SELECT user_id FROM fnd_user WHERE user_name LIKE 'EXP%');

    -- Les imports RB tournent de nuit et sont dates tantot de la veille,
    -- tantot du jour meme. Ne regarder que SYSDATE-1 faisait remonter
    -- "0 import" a tort sur 3 des 9 dernieres executions. On prend donc la
    -- fenetre veille+jour, et on conserve la date du dernier import.
    BEGIN
        SELECT COUNT(*), MAX(TRUNC(import_date))
        INTO   v_nb_rb_imports, v_date_rb_max
        FROM   rb_batch_import
        WHERE  TRUNC(import_date) IN (TRUNC(SYSDATE - 1), TRUNC(SYSDATE));
    EXCEPTION
        WHEN OTHERS THEN
            v_nb_rb_imports := 0;
            v_err_rb        := 'Y';
    END;

    -- COUNT(DISTINCT) : invoice_num n'est pas unique en multi-organisation,
    -- la jointure sur ap_invoices_all dedouble donc les factures. Constate
    -- dans le log du 28/07 : F-2026-07-1 compte deux fois.
    BEGIN
        SELECT COUNT(DISTINCT dir.num_fact) INTO v_nb_images_manq
        FROM   dka_iapfacxgs_reporting_all dir
        JOIN   ap_invoices_all aia ON aia.invoice_num = dir.num_fact AND aia.creation_date > SYSDATE - 30
        WHERE  dir.nom_fichier LIKE 'VE1_DAL%'
        AND    dir.date_creation = TO_CHAR(SYSDATE - 1, 'YYYYMMDD')
        AND    NOT EXISTS (SELECT 1 FROM fnd_documents fd
                           WHERE  fd.creation_date > SYSDATE - 30
                           AND    (SUBSTR(fd.file_name, 1, LENGTH(fd.file_name) - 4) = aia.attribute3
                                   OR fd.file_name = aia.attribute3));
    EXCEPTION
        WHEN OTHERS THEN
            v_nb_images_manq := 0;
            v_err_img        := 'Y';
    END;

    -- Seuil DSP : 5 fichiers un jour ouvre, mais une journee plus chargee en
    -- produit davantage. On accepte donc ">= 5" au lieu d'une egalite stricte.
    IF v_nb_flux_dsp >= 5      THEN v_stat_flux_dsp      := 'OK'; END IF;
    IF v_nb_ndf > 0            THEN v_stat_ndf           := 'OK'; END IF;
    IF v_nb_fac_xerox > 0      THEN v_stat_xerox         := 'OK'; END IF;
    IF v_nb_fac_tradeshift > 0 THEN v_stat_tradeshift    := 'OK'; END IF;
    -- Aucune facture DSP attendue tant que les flux du jour sont complets.
    IF v_nb_fac_dsp = 0 AND v_nb_flux_dsp >= 5 THEN v_stat_fac_dsp := 'OK'; END IF;
    IF v_nb_gl_interface > 0   THEN v_stat_gl_interface  := 'OK'; END IF;
    IF v_nb_gl_lignes > 0      THEN v_stat_gl_lignes     := 'OK'; END IF;
    IF v_nb_rb_imports > 0     THEN v_stat_rb_imports    := 'OK'; END IF;

    -- Un controle qui n'a pas pu s'executer est marque 'KO' et non 'OK' :
    -- le zero d'un bloc en erreur ne doit jamais passer pour un bon resultat.
    IF v_err_fac = 'Y' THEN
        v_stat_xerox := 'KO'; v_stat_tradeshift := 'KO'; v_stat_fac_dsp := 'KO';
    END IF;
    IF v_err_rb = 'Y' THEN v_stat_rb_imports := 'KO'; END IF;

    DBMS_OUTPUT.PUT_LINE('+--------------------------------------------+');
    DBMS_OUTPUT.PUT_LINE('|             SYNTHESE DU JOUR               |');
    DBMS_OUTPUT.PUT_LINE('+--------------------------------------------+');
    DBMS_OUTPUT.PUT_LINE('| Flux DSP (fichiers)      : ' || LPAD(v_nb_flux_dsp, 7)       || ' [' || RPAD(v_stat_flux_dsp, 2)    || '] |');
    DBMS_OUTPUT.PUT_LINE('| Notes de frais Notilus   : ' || LPAD(v_nb_ndf, 7)            || ' [' || RPAD(v_stat_ndf, 2)         || '] |');
    DBMS_OUTPUT.PUT_LINE('| Factures Xerox           : ' || LPAD(v_nb_fac_xerox, 7)      || ' [' || RPAD(v_stat_xerox, 2)       || '] |');
    DBMS_OUTPUT.PUT_LINE('| Factures Tradeshift      : ' || LPAD(v_nb_fac_tradeshift, 7) || ' [' || RPAD(v_stat_tradeshift, 2)  || '] |');
    DBMS_OUTPUT.PUT_LINE('| Factures DSP             : ' || LPAD(v_nb_fac_dsp, 7)        || ' [' || RPAD(v_stat_fac_dsp, 2)     || '] |');
    DBMS_OUTPUT.PUT_LINE('| Ecritures GL (interface) : ' || LPAD(v_nb_gl_interface, 7)   || ' [' || RPAD(v_stat_gl_interface,2) || '] |');
    DBMS_OUTPUT.PUT_LINE('| Lignes GL creees         : ' || LPAD(v_nb_gl_lignes, 7)      || ' [' || RPAD(v_stat_gl_lignes, 2)   || '] |');
    DBMS_OUTPUT.PUT_LINE('| Imports RB               : ' || LPAD(v_nb_rb_imports, 7)     || ' [' || RPAD(v_stat_rb_imports, 2)  || '] |');
    DBMS_OUTPUT.PUT_LINE('+--------------------------------------------+');
    DBMS_OUTPUT.PUT_LINE('| Traitements nuit         : ' || LPAD(v_nb_traitements, 7)    || '      |');
    IF v_nb_erreurs > 0 THEN
        DBMS_OUTPUT.PUT_LINE('| *** ERREURS ***          : ' || LPAD(v_nb_erreurs, 7)    || '      |');
    ELSE
        DBMS_OUTPUT.PUT_LINE('| Erreurs                  : ' || LPAD(v_nb_erreurs, 7)    || '      |');
    END IF;
    DBMS_OUTPUT.PUT_LINE('| Avertissements           : ' || LPAD(v_nb_warnings, 7)       || '      |');
    IF v_nb_images_manq > 0 THEN
        DBMS_OUTPUT.PUT_LINE('| *** IMAGES MANQUANTES *** : ' || LPAD(v_nb_images_manq, 6) || '      |');
    END IF;
    DBMS_OUTPUT.PUT_LINE('+--------------------------------------------+');
    IF v_date_rb_max IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Dernier import RB : ' || TO_CHAR(v_date_rb_max, 'DD/MM/YYYY'));
    END IF;
    DBMS_OUTPUT.PUT_LINE('');

    IF v_nb_erreurs > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[!] ALERTE : ' || v_nb_erreurs || ' traitement(s) en ERREUR - Voir Section 6');
    END IF;
    IF v_nb_flux_dsp < 5 AND TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') NOT IN ('SAT', 'SUN', 'MON') THEN
        DBMS_OUTPUT.PUT_LINE('[!] ALERTE : Moins de 5 flux DSP attendus (normal: 5/jour ouvre)');
    END IF;
    IF v_nb_images_manq > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[!] ALERTE : ' || v_nb_images_manq || ' factures Xerox sans image - Voir Section 4');
    END IF;
    IF TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') = 'MON' AND v_nb_rb_imports = 0 THEN
        DBMS_OUTPUT.PUT_LINE('[!] RAPPEL LUNDI : Charger manuellement le fichier SG (rattrapage)');
    END IF;
    IF v_err_fac = 'Y' THEN
        DBMS_OUTPUT.PUT_LINE('[!] CONTROLE INDISPONIBLE : comptage des factures impossible (table ou droit).');
    END IF;
    IF v_err_rb = 'Y' THEN
        DBMS_OUTPUT.PUT_LINE('[!] CONTROLE INDISPONIBLE : comptage des imports RB impossible (table ou droit).');
    END IF;
    IF v_err_img = 'Y' THEN
        DBMS_OUTPUT.PUT_LINE('[!] CONTROLE INDISPONIBLE : controle des images Xerox impossible (table ou droit).');
    END IF;

    -- -----------------------------------------------------------------
    -- Sortie balisee, consommee par Lancer_Controle_Quotidien.ps1 pour
    -- construire le rapport HTML. Sans effet sur la lecture humaine du log.
    -- Format : ##KPI##libelle|valeur|statut
    -- -----------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('##KPI##Flux DSP|'             || v_nb_flux_dsp       || '|' || v_stat_flux_dsp);
    DBMS_OUTPUT.PUT_LINE('##KPI##Notes de frais|'       || v_nb_ndf            || '|' || v_stat_ndf);
    DBMS_OUTPUT.PUT_LINE('##KPI##Factures Xerox|'       || v_nb_fac_xerox      || '|' || v_stat_xerox);
    DBMS_OUTPUT.PUT_LINE('##KPI##Factures Tradeshift|'  || v_nb_fac_tradeshift || '|' || v_stat_tradeshift);
    DBMS_OUTPUT.PUT_LINE('##KPI##Factures DSP|'         || v_nb_fac_dsp        || '|' || v_stat_fac_dsp);
    DBMS_OUTPUT.PUT_LINE('##KPI##GL interface|'         || v_nb_gl_interface   || '|' || v_stat_gl_interface);
    DBMS_OUTPUT.PUT_LINE('##KPI##Lignes GL creees|'     || v_nb_gl_lignes      || '|' || v_stat_gl_lignes);
    DBMS_OUTPUT.PUT_LINE('##KPI##Imports RB|'           || v_nb_rb_imports     || '|' || v_stat_rb_imports);
    DBMS_OUTPUT.PUT_LINE('##KPI##Traitements nuit|'     || v_nb_traitements    || '|OK');
    DBMS_OUTPUT.PUT_LINE('##KPI##Erreurs nuit|'         || v_nb_erreurs        || '|' || CASE WHEN v_nb_erreurs   > 0 THEN 'KO' ELSE 'OK' END);
    DBMS_OUTPUT.PUT_LINE('##KPI##Avertissements nuit|'  || v_nb_warnings       || '|' || CASE WHEN v_nb_warnings  > 0 THEN 'W'  ELSE 'OK' END);
    DBMS_OUTPUT.PUT_LINE('##KPI##Images Xerox manquantes|' || v_nb_images_manq || '|' || CASE WHEN v_nb_images_manq > 0 THEN 'KO' ELSE 'OK' END);
    DBMS_OUTPUT.PUT_LINE('##META##date_controle|'  || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI'));
    DBMS_OUTPUT.PUT_LINE('##META##jour|'           || RTRIM(TO_CHAR(SYSDATE, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH')));
    DBMS_OUTPUT.PUT_LINE('##META##dernier_imp_rb|' || NVL(TO_CHAR(v_date_rb_max, 'DD/MM/YYYY'), 'aucun'));
END;
/

-- =============================================================================
-- SECTION 3 : FLUX DSP (iValua)
-- =============================================================================

PROMPT
PROMPT === DSP - Detail des flux (fichiers) ===

COLUMN SRC       FORMAT A5   HEADING "SRC"
COLUMN DATE_CR   FORMAT A8   HEADING "DATE"
COLUMN JOUR      FORMAT A10  HEADING "JOUR"
COLUMN TYPE_FLUX FORMAT A13  HEADING "TYPE"
COLUMN FILE_NAME FORMAT A70  HEADING "FICHIER"

SELECT 'DSP' AS SRC,
       TO_CHAR(date_creation, 'DD/MM/YY') AS DATE_CR,
       RTRIM(jour_creation) AS JOUR,
       -- Les fichiers de commandes arrivent nommes DSP01_PO_ENTETE_... :
       -- ni '%CDE%' ni 'ORDER%' ne les attrapaient, et ils tombaient tous
       -- dans AUTRE. Verifie sur les 9 derniers logs : COMMANDES n'y
       -- apparait jamais, alors qu'AUTRE est present chaque jour.
       CASE
           WHEN file_name LIKE '%SUP%'                              THEN 'FOURNISSEURS'
           WHEN file_name LIKE '%PO[_]%' ESCAPE '['
             OR file_name LIKE '%CDE%'
             OR file_name LIKE 'ORDER%'                             THEN 'COMMANDES'
           WHEN file_name LIKE '%REC%'                              THEN 'RECEPTIONS'
           WHEN file_name LIKE '%DEB%' OR file_name LIKE '%DEBLOC%' THEN 'DEBLOCAGE'
           ELSE 'AUTRE'
       END AS TYPE_FLUX,
       file_name
FROM (
    SELECT DISTINCT TRUNC(dih.creation_date) AS date_creation,
           TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH') AS jour_creation,
           dih.file_name
    FROM   dka_ipofrs_hist_entetes dih
    WHERE  dih.creation_date > SYSDATE - :v_nb_jours_histo
    UNION ALL
    SELECT DISTINCT TRUNC(dih.creation_date),
           TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'),
           dih.file_name
    FROM   dka_ipocde_hist_headers dih
    WHERE  dih.creation_date > SYSDATE - :v_nb_jours_histo
    UNION ALL
    SELECT DISTINCT TRUNC(dih.creation_date),
           TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'),
           dih.file_name
    FROM   dka_iporec_hist_interface dih
    WHERE  dih.creation_date > SYSDATE - :v_nb_jours_histo
    UNION ALL
    SELECT DISTINCT TRUNC(dih.creation_date),
           TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'),
           dih.file_name
    FROM   dka_iapfac_debloc_hist_interf dih
    WHERE  dih.creation_date > SYSDATE - :v_nb_jours_histo
)
ORDER BY date_creation DESC, TYPE_FLUX, file_name;

CLEAR COLUMNS

PROMPT
PROMPT === DSP - Synthese par jour et type ===

COLUMN DATE_CR  FORMAT A8   HEADING "DATE"
COLUMN JOUR     FORMAT A10  HEADING "JOUR"
COLUMN NB_SUP   FORMAT 9999 HEADING "FOURN."
COLUMN NB_CDE   FORMAT 9999 HEADING "CMDES"
COLUMN NB_REC   FORMAT 9999 HEADING "RECEP."
COLUMN NB_DEB   FORMAT 9999 HEADING "DEBLOC."
COLUMN NB_AUT   FORMAT 9999 HEADING "AUTRE"
COLUMN TOTAL    FORMAT 9999 HEADING "TOTAL"

-- Cette synthese comptait des libelles constants issus d'un DISTINCT, donc
-- au plus 1 par table et par jour : elle indiquait "1 fournisseur" un jour ou
-- 2 fichiers etaient arrives (log du 28/07). On compte desormais les fichiers.
SELECT TO_CHAR(date_creation, 'DD/MM/YY') AS DATE_CR,
       RTRIM(jour_creation)               AS JOUR,
       COUNT(DISTINCT CASE WHEN TYPE_FLUX = 'FOURNISSEURS' THEN file_name END) AS NB_SUP,
       COUNT(DISTINCT CASE WHEN TYPE_FLUX = 'COMMANDES'    THEN file_name END) AS NB_CDE,
       COUNT(DISTINCT CASE WHEN TYPE_FLUX = 'RECEPTIONS'   THEN file_name END) AS NB_REC,
       COUNT(DISTINCT CASE WHEN TYPE_FLUX = 'DEBLOCAGE'    THEN file_name END) AS NB_DEB,
       COUNT(DISTINCT CASE WHEN TYPE_FLUX = 'AUTRE'        THEN file_name END) AS NB_AUT,
       COUNT(DISTINCT file_name) AS TOTAL
FROM (
    SELECT TRUNC(dih.creation_date) AS date_creation,
           TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH') AS jour_creation,
           dih.file_name,
           CASE
               WHEN dih.file_name LIKE '%SUP%'                                  THEN 'FOURNISSEURS'
               WHEN dih.file_name LIKE '%PO[_]%' ESCAPE '['
                 OR dih.file_name LIKE '%CDE%'
                 OR dih.file_name LIKE 'ORDER%'                                 THEN 'COMMANDES'
               WHEN dih.file_name LIKE '%REC%'                                  THEN 'RECEPTIONS'
               WHEN dih.file_name LIKE '%DEB%' OR dih.file_name LIKE '%DEBLOC%' THEN 'DEBLOCAGE'
               ELSE 'AUTRE'
           END AS TYPE_FLUX
    FROM   dka_ipofrs_hist_entetes dih WHERE dih.creation_date > SYSDATE - :v_nb_jours_histo
    UNION ALL
    SELECT TRUNC(dih.creation_date), TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'), dih.file_name,
           CASE WHEN dih.file_name LIKE '%PO[_]%' ESCAPE '[' OR dih.file_name LIKE '%CDE%' THEN 'COMMANDES' ELSE 'AUTRE' END
    FROM   dka_ipocde_hist_headers dih WHERE dih.creation_date > SYSDATE - :v_nb_jours_histo
    UNION ALL
    SELECT TRUNC(dih.creation_date), TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'), dih.file_name,
           'RECEPTIONS'
    FROM   dka_iporec_hist_interface dih WHERE dih.creation_date > SYSDATE - :v_nb_jours_histo
    UNION ALL
    SELECT TRUNC(dih.creation_date), TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'), dih.file_name,
           'DEBLOCAGE'
    FROM   dka_iapfac_debloc_hist_interf dih WHERE dih.creation_date > SYSDATE - :v_nb_jours_histo
)
GROUP BY date_creation, jour_creation
ORDER BY date_creation DESC;

CLEAR COLUMNS

-- =============================================================================
-- SECTION 4 : NOTES DE FRAIS (Notilus)
-- =============================================================================

PROMPT
PROMPT === NOTILUS - Comptage des notes de frais ===

COLUMN CONTROLE    FORMAT A10   HEADING "CONTROLE"
COLUMN DATE_CR     FORMAT A8    HEADING "DATE"
COLUMN JOUR        FORMAT A10   HEADING "JOUR"
COLUMN NB_NDF      FORMAT 99999 HEADING "NB NDF"
COLUMN MONTANT_TOT FORMAT 999G999G999 HEADING "MONTANT TOTAL"

SELECT 'NOTILUS'                                                                  AS CONTROLE,
       TO_CHAR(TRUNC(creation_date), 'DD/MM/YY')                                  AS DATE_CR,
       RTRIM(TO_CHAR(creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'))           AS JOUR,
       COUNT(*)                                                                    AS NB_NDF,
       ROUND(SUM(invoice_amount))                                                  AS MONTANT_TOT
FROM   ap_invoices_all
WHERE  attribute9 = 'NOT'
AND    creation_date > SYSDATE - :v_nb_jours_histo
GROUP BY TRUNC(creation_date), TO_CHAR(creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH')
ORDER BY TRUNC(creation_date) DESC;

CLEAR COLUMNS

-- =============================================================================
-- SECTION 5 : FACTURES (Xerox, Tradeshift, DSP)
-- =============================================================================

PROMPT
PROMPT === FACTURES - Synthese par source ===

COLUMN CONTROLE   FORMAT A10   HEADING "CONTROLE"
COLUMN DATE_CR    FORMAT A8    HEADING "DATE"
COLUMN SOURCE     FORMAT A12   HEADING "SOURCE"
COLUMN NB_FACS    FORMAT 99999 HEADING "NB FACTURES"

SELECT 'FACTURES'                                                                   AS CONTROLE,
       TO_CHAR(TO_DATE(date_creation, 'YYYYMMDD'), 'DD/MM/YY')                      AS DATE_CR,
       DECODE(SUBSTR(imagefile, 1, 3), 'VE1', 'XEROX', 'L56', 'TRADESHIFT', 'DSP', 'DSP', 'AUTRES') AS SOURCE,
       COUNT(*)                                                                      AS NB_FACS
FROM   dka_iapfacxgs_reporting_all
WHERE  TO_DATE(date_creation, 'YYYYMMDD') > SYSDATE - :v_nb_jours_histo
GROUP BY date_creation, DECODE(SUBSTR(imagefile, 1, 3), 'VE1', 'XEROX', 'L56', 'TRADESHIFT', 'DSP', 'DSP', 'AUTRES')
ORDER BY date_creation DESC, SOURCE;

CLEAR COLUMNS

-- Factures Xerox SANS images (ALERTE)
-- Une ligne par facture : DATE | NUM_FACT | NOM_FICHIER | INVOICE_ID | VENDOR_ID

PROMPT
PROMPT === XEROX - Factures SANS images (ALERTE) ===

COLUMN info FORMAT A120

-- DISTINCT : invoice_num n'etant pas unique en multi-organisation, la meme
-- facture ressortait plusieurs fois avec des INV/VDR differents (F-2026-07-1
-- dans le log du 28/07). Les invoice_id sont donc regroupes sur une ligne.
SELECT dir.date_creation || ' | ' ||
       RPAD(NVL(dir.num_fact, '?'), 25) || ' | ' ||
       RPAD(NVL(MIN(dir.reference_lad), '?'), 50) || ' | ' ||
       'INV=' || LISTAGG(aia.invoice_id, ',') WITHIN GROUP (ORDER BY aia.invoice_id) AS info
FROM   dka_iapfacxgs_reporting_all dir
JOIN   ap_invoices_all aia ON aia.invoice_num = dir.num_fact AND aia.creation_date > SYSDATE - 30
WHERE  dir.nom_fichier LIKE 'VE1_DAL%'
AND    dir.date_creation = TO_CHAR(SYSDATE - 1, 'YYYYMMDD')
AND    NOT EXISTS (SELECT 1 FROM fnd_documents fd
                   WHERE  fd.creation_date > SYSDATE - 30
                   AND    (SUBSTR(fd.file_name, 1, LENGTH(fd.file_name) - 4) = aia.attribute3
                           OR fd.file_name = aia.attribute3))
GROUP BY dir.date_creation, dir.num_fact
ORDER BY dir.num_fact;

CLEAR COLUMNS

PROMPT
PROMPT === XEROX - Factures AVEC images (compteur) ===

COLUMN NB_AVEC_IMG FORMAT 99999 HEADING "NB AVEC IMAGE"

-- COUNT(DISTINCT num_fact) : la double jointure (multi-organisation cote
-- ap_invoices_all, plusieurs documents cote fnd_documents) multipliait les
-- lignes et surevaluait fortement ce compteur.
SELECT COUNT(DISTINCT dir.num_fact) AS NB_AVEC_IMG
FROM   dka_iapfacxgs_reporting_all dir
JOIN   ap_invoices_all aia ON aia.invoice_num = dir.num_fact AND aia.creation_date > SYSDATE - 30
JOIN   fnd_documents fd ON fd.creation_date > SYSDATE - 30
       AND (SUBSTR(fd.file_name, 1, LENGTH(fd.file_name) - 4) = aia.attribute3
            OR fd.file_name = aia.attribute3)
WHERE  dir.nom_fichier LIKE 'VE1_DAL%'
AND    dir.date_creation = TO_CHAR(SYSDATE - 1, 'YYYYMMDD');

CLEAR COLUMNS

-- =============================================================================
-- SECTION 6 : ECRITURES GL
-- =============================================================================

PROMPT
PROMPT === GL - Interface (en attente) ===

COLUMN CONTROLE   FORMAT A14   HEADING "CONTROLE"
COLUMN SOURCE     FORMAT A40   HEADING "SOURCE"
COLUMN TYPE_GL    FORMAT A15   HEADING "TYPE"
COLUMN STATUS_GL  FORMAT A8    HEADING "STATUS"
COLUMN NB_LIGNES  FORMAT 999G999 HEADING "NB LIGNES"
COLUMN TOT_DEBIT  FORMAT 999G999G999 HEADING "TOTAL DEBIT"
COLUMN TOT_CREDIT FORMAT 999G999G999 HEADING "TOTAL CREDIT"

-- GL_INTERFACE est volontairement lue sans borne de date : c'est le stock en
-- attente qui fait le controle. On ajoute l'anciennete de la plus vieille
-- ligne, qui est l'information reellement actionnable le matin.
COLUMN PLUS_ANCIEN FORMAT A10 HEADING "DEPUIS"
COLUMN AGE_J       FORMAT 9999 HEADING "AGE(j)"

SELECT 'GL_INTERFACE'                                AS CONTROLE,
       SUBSTR(attribute10, 1, 40)                    AS SOURCE,
       SUBSTR(attribute9,  1, 15)                    AS TYPE_GL,
       status                                        AS STATUS_GL,
       COUNT(*)                                      AS NB_LIGNES,
       ROUND(SUM(entered_dr))                        AS TOT_DEBIT,
       ROUND(SUM(entered_cr))                        AS TOT_CREDIT,
       TO_CHAR(MIN(date_created), 'DD/MM/YY')        AS PLUS_ANCIEN,
       TRUNC(SYSDATE) - TRUNC(MIN(date_created))     AS AGE_J
FROM   gl_interface
GROUP BY attribute10, attribute9, status
ORDER BY MIN(date_created);

CLEAR COLUMNS

PROMPT
PROMPT === GL - Lignes creees ===

COLUMN CONTROLE   FORMAT A10  HEADING "CONTROLE"
COLUMN DATE_CR    FORMAT A8   HEADING "DATE"
COLUMN SOURCE     FORMAT A45  HEADING "SOURCE"
COLUMN NB_LIGNES  FORMAT 999G999G999 HEADING "NB LIGNES"
COLUMN TOT_DEBIT  FORMAT 999G999G999G999 HEADING "TOTAL DEBIT"

SELECT 'GL_CREES'                                AS CONTROLE,
       TO_CHAR(TRUNC(creation_date), 'DD/MM/YY') AS DATE_CR,
       SUBSTR(attribute10, 1, 45)                AS SOURCE,
       COUNT(*)                                  AS NB_LIGNES,
       ROUND(SUM(entered_dr))                    AS TOT_DEBIT
FROM   gl_je_lines
WHERE  creation_date > SYSDATE - :v_nb_jours_histo
GROUP BY TRUNC(creation_date), attribute10
ORDER BY TRUNC(creation_date) DESC, attribute10 DESC;

CLEAR COLUMNS

-- =============================================================================
-- SECTION 7 : TRAITEMENTS DE LA NUIT
-- =============================================================================

PROMPT
PROMPT === NUIT - Synthese par statut ===

COLUMN CONTROLE  FORMAT A15  HEADING "CONTROLE"
COLUMN STATUT    FORMAT A16  HEADING "STATUT"
COLUMN NB        FORMAT 9999 HEADING "NB"

SELECT 'NUIT_SYNTHESE' AS CONTROLE,
       CASE status_code
           WHEN 'C' THEN 'OK'
           WHEN 'E' THEN '*** ERREUR ***'
           WHEN 'G' THEN 'WARNING'
           WHEN 'R' THEN 'EN COURS'
           WHEN 'W' THEN 'EN ATTENTE'
           ELSE 'AUTRE (' || status_code || ')'
       END AS STATUT,
       COUNT(*) AS NB
FROM   fnd_concurrent_requests
WHERE  actual_start_date >= TRUNC(SYSDATE - 1) + :v_heure_fermeture / 24
AND    actual_start_date <  TRUNC(SYSDATE)      + :v_heure_ouverture / 24
AND    requested_by IN (SELECT user_id FROM fnd_user WHERE user_name LIKE 'EXP%')
GROUP BY CASE status_code
             WHEN 'C' THEN 'OK'
             WHEN 'E' THEN '*** ERREUR ***'
             WHEN 'G' THEN 'WARNING'
             WHEN 'R' THEN 'EN COURS'
             WHEN 'W' THEN 'EN ATTENTE'
             ELSE 'AUTRE (' || status_code || ')'
         END
ORDER BY 1;

CLEAR COLUMNS

-- Le detail listait une ligne par demande : le 28/07, 113 lignes strictement
-- identiques ("Programme maitre de l'interface factures"), illisibles et sans
-- valeur d'analyse. On regroupe d'abord par programme, le detail nominatif
-- vient ensuite et reste borne.

PROMPT
PROMPT === NUIT - ERREURS regroupees par programme ===

COLUMN PROGRAMME  FORMAT A55   HEADING "PROGRAMME"
COLUMN NB_ERR     FORMAT 99999 HEADING "NB"
COLUMN PREMIERE   FORMAT A14   HEADING "PREMIERE"
COLUMN DERNIERE   FORMAT A14   HEADING "DERNIERE"
COLUMN MSG        FORMAT A70   HEADING "MESSAGE TYPE"

SELECT fcp.user_concurrent_program_name                       AS PROGRAMME,
       COUNT(*)                                                AS NB_ERR,
       TO_CHAR(MIN(fcr.actual_start_date), 'DD/MM HH24:MI:SS') AS PREMIERE,
       TO_CHAR(MAX(fcr.actual_start_date), 'DD/MM HH24:MI:SS') AS DERNIERE,
       SUBSTR(MIN(fcr.completion_text), 1, 70)                 AS MSG
FROM   fnd_concurrent_requests fcr
JOIN   fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + :v_heure_fermeture / 24
AND    fcr.actual_start_date <  TRUNC(SYSDATE)      + :v_heure_ouverture / 24
AND    fcr.requested_by IN (SELECT user_id FROM fnd_user WHERE user_name LIKE 'EXP%')
AND    fcr.status_code = 'E'
GROUP BY fcp.user_concurrent_program_name
ORDER BY COUNT(*) DESC;

CLEAR COLUMNS

PROMPT
PROMPT === NUIT - Detail des ERREURS (30 plus recentes) ===

COLUMN REQ_ID     FORMAT 9999999999 HEADING "REQ ID"
COLUMN PROGRAMME  FORMAT A50  HEADING "PROGRAMME"
COLUMN DEBUT      FORMAT A14  HEADING "DEBUT"
COLUMN FIN        FORMAT A14  HEADING "FIN"
COLUMN DUREE_MIN  FORMAT 9999.9 HEADING "DUREE(min)"
COLUMN MSG        FORMAT A70  HEADING "MESSAGE"

SELECT * FROM (
    SELECT fcr.request_id                                                            AS REQ_ID,
           fcp.user_concurrent_program_name                                           AS PROGRAMME,
           TO_CHAR(fcr.actual_start_date,      'DD/MM HH24:MI:SS')                   AS DEBUT,
           TO_CHAR(fcr.actual_completion_date, 'DD/MM HH24:MI:SS')                   AS FIN,
           ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 1)  AS DUREE_MIN,
           SUBSTR(fcr.completion_text, 1, 70)                                         AS MSG
    FROM   fnd_concurrent_requests fcr
    JOIN   fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
    WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + :v_heure_fermeture / 24
    AND    fcr.actual_start_date <  TRUNC(SYSDATE)      + :v_heure_ouverture / 24
    AND    fcr.requested_by IN (SELECT user_id FROM fnd_user WHERE user_name LIKE 'EXP%')
    AND    fcr.status_code = 'E'
    ORDER BY fcr.actual_start_date DESC
)
WHERE ROWNUM <= 30;

CLEAR COLUMNS

PROMPT
PROMPT === NUIT - Detail des WARNINGS ===

COLUMN REQ_ID     FORMAT 9999999999 HEADING "REQ ID"
COLUMN PROGRAMME  FORMAT A55  HEADING "PROGRAMME"
COLUMN DEBUT      FORMAT A14  HEADING "DEBUT"
COLUMN DUREE_MIN  FORMAT 9999.9 HEADING "DUREE(min)"
COLUMN MSG        FORMAT A55  HEADING "MESSAGE"

SELECT fcr.request_id                                                            AS REQ_ID,
       fcp.user_concurrent_program_name                                           AS PROGRAMME,
       TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS')                        AS DEBUT,
       ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 1)  AS DUREE_MIN,
       SUBSTR(fcr.completion_text, 1, 55)                                         AS MSG
FROM   fnd_concurrent_requests fcr
JOIN   fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + :v_heure_fermeture / 24
AND    fcr.actual_start_date <  TRUNC(SYSDATE)      + :v_heure_ouverture / 24
AND    fcr.requested_by IN (SELECT user_id FROM fnd_user WHERE user_name LIKE 'EXP%')
AND    fcr.status_code = 'G'
ORDER BY fcr.actual_start_date DESC;

CLEAR COLUMNS

PROMPT
PROMPT === NUIT - Traitements longs (> 30 min) ===

COLUMN REQ_ID     FORMAT 9999999999 HEADING "REQ ID"
COLUMN PROGRAMME  FORMAT A55  HEADING "PROGRAMME"
COLUMN DEBUT      FORMAT A12  HEADING "DEBUT"
COLUMN FIN        FORMAT A12  HEADING "FIN"
COLUMN DUREE_MIN  FORMAT 9999.9 HEADING "DUREE(min)"
COLUMN STATUT     FORMAT A8   HEADING "STATUT"

SELECT fcr.request_id                                                            AS REQ_ID,
       fcp.user_concurrent_program_name                                           AS PROGRAMME,
       TO_CHAR(fcr.actual_start_date,      'DD/MM HH24:MI')                      AS DEBUT,
       TO_CHAR(fcr.actual_completion_date, 'DD/MM HH24:MI')                      AS FIN,
       ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 1)  AS DUREE_MIN,
       CASE fcr.status_code WHEN 'C' THEN 'OK' WHEN 'E' THEN 'ERREUR' WHEN 'G' THEN 'WARNING' ELSE fcr.status_code END AS STATUT
FROM   fnd_concurrent_requests fcr
JOIN   fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + :v_heure_fermeture / 24
AND    fcr.actual_start_date <  TRUNC(SYSDATE)      + :v_heure_ouverture / 24
AND    fcr.requested_by IN (SELECT user_id FROM fnd_user WHERE user_name LIKE 'EXP%')
AND    (fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60 > 30
ORDER BY (fcr.actual_completion_date - fcr.actual_start_date) DESC;

CLEAR COLUMNS

PROMPT
PROMPT === NUIT - Traitements en cours (potentiellement bloques) ===

COLUMN REQ_ID      FORMAT 9999999999 HEADING "REQ ID"
COLUMN PROGRAMME   FORMAT A45  HEADING "PROGRAMME"
COLUMN DEBUT       FORMAT A14  HEADING "DEBUT"
COLUMN DUREE_MIN   FORMAT 9999.9 HEADING "DUREE(min)"
COLUMN PARAMETRES  FORMAT A50  HEADING "PARAMETRES"

SELECT fcr.request_id                                                           AS REQ_ID,
       fcp.user_concurrent_program_name                                          AS PROGRAMME,
       TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS')                       AS DEBUT,
       ROUND((SYSDATE - fcr.actual_start_date) * 24 * 60, 1)                    AS DUREE_MIN,
       SUBSTR(fcr.argument_text, 1, 50)                                          AS PARAMETRES
FROM   fnd_concurrent_requests fcr
JOIN   fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + :v_heure_fermeture / 24
AND    fcr.requested_by IN (SELECT user_id FROM fnd_user WHERE user_name LIKE 'EXP%')
AND    fcr.status_code = 'R'
ORDER BY fcr.actual_start_date;

CLEAR COLUMNS

-- =============================================================================
-- SECTION 8 : RAPPROCHEMENT BANCAIRE (RB)
-- =============================================================================
-- Chargements auto : tous les jours sauf dimanche et lundi
-- RAPPEL : Le lundi, charger manuellement le fichier SG

PROMPT
PROMPT === RAPPROCHEMENT BANCAIRE (RB) ===

COLUMN CONTROLE   FORMAT A12  HEADING "CONTROLE"
COLUMN DATE_CR    FORMAT A8   HEADING "DATE"
COLUMN JOUR       FORMAT A10  HEADING "JOUR"
COLUMN NB_CTES    FORMAT 9999 HEADING "NB COMPTES"

SELECT 'RB_IMPORTS'                                                               AS CONTROLE,
       TO_CHAR(TRUNC(import_date), 'DD/MM/YY')                                     AS DATE_CR,
       RTRIM(TO_CHAR(import_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'))               AS JOUR,
       COUNT(*)                                                                     AS NB_CTES
FROM   rb_batch_import
WHERE  import_date > SYSDATE - :v_nb_jours_histo
GROUP BY TRUNC(import_date), TO_CHAR(import_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH')
ORDER BY TRUNC(import_date) DESC;

CLEAR COLUMNS

-- =============================================================================
-- FIN DU RAPPORT
-- =============================================================================

PROMPT
PROMPT =====================================================
PROMPT FIN DU CONTROLE QUOTIDIEN
PROMPT =====================================================
