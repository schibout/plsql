PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU TRIGGER DKA_GL_JE_LINES_BIR
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TRIGGER dka_gl_je_lines_bir
----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_GL_JE_LINES_BIR.trg
-- DESCRIPTION       : Trigger sur la table GL_JE_LINES
---
--- AUTEUR           : Xavier Descamps (CGEY)
--- DATE DE CREATION : 10/12/2003
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 04/08/2004 SFE Migration Projet PHENIX 2004
--- 09/06/2005 CDE Correction ano calcul segment1 et 2
--- 16/06/2016 JPE MIGRATION R12
--- 18/10/2017 YWA artf2245522  : SPE046 - Correction Attribute - Defect Beb #1128
--- ---------- --- ---------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
BEFORE INSERT
    ON gl.gl_je_lines
    FOR EACH ROW
    WHEN (NEW.attribute11 IS NOT NULL)
DECLARE
    vv_autoreverse_flag        gl_autoreverse_options.autoreverse_flag%TYPE;
    vn_reversed_je_header_id   gl_je_headers.je_header_id%TYPE;
    vv_reversed_period_name    gl_je_headers.period_name%TYPE;
    vv_project_type            pa_project_types_all.project_type%TYPE;
    vv_errbuf                  VARCHAR2 (500);
    e_error                    EXCEPTION;
BEGIN
    SELECT 	gao.autoreverse_flag,
			gjh.reversed_je_header_id,
			gjh_rev.period_name
    INTO   	vv_autoreverse_flag,
			vn_reversed_je_header_id,
			vv_reversed_period_name
    FROM   	gl_je_headers gjh,
			gl_je_headers gjh_rev,
			gl_autoreverse_options gao,
			gl_ledgers gl
    WHERE   gjh.je_header_id (+) 	 = :NEW.je_header_id
    AND 	gao.je_category_name (+) = gjh.je_category
    -- JPE  16/06/2016 MIGRATION R12 Jointure nécessaire en R12
    AND 	gl.ledger_id 	  		 = gjh.ledger_id
	AND	    gao.criteria_set_id  (+) = gl.criteria_set_id 
    AND 	gjh_rev.je_header_id (+) = gjh.reversed_je_header_id;

    IF (    vv_autoreverse_flag = 'Y'
        AND vn_reversed_je_header_id IS NOT NULL
        AND vv_reversed_period_name != :NEW.period_name)
    THEN
        DECLARE
            --vv_new_segment1_2   varchar2(128);                       -- PHENIX 2004: Ajout.
            vv_old_segment1     gl_code_combinations.segment1%TYPE;
            vv_old_segment2     gl_code_combinations.segment2%TYPE;
            vv_old_segment4     gl_code_combinations.segment4%TYPE;  -- PHENIX 2004: Ajout.
            vv_old_segment6     gl_code_combinations.segment6%TYPE;  -- PHENIX 2004: segment5 -> segment6.
            --vv_new_segment1     gl_code_combinations.segment1%TYPE;
            --vv_new_segment2     gl_code_combinations.segment2%TYPE;
            vv_new_segment4     gl_code_combinations.segment4%TYPE;  -- PHENIX 2004: Ajout.
            vv_new_segment6     gl_code_combinations.segment6%TYPE;  -- PHENIX 2004: segment5 -> segment6.
            vv_account_type     gl_code_combinations.account_type%TYPE;
        BEGIN
            SELECT gcc.segment1,
                   gcc.segment2,
                   gcc.segment4,     -- PHENIX 2004: Ajout.
                   gcc.segment6,     -- PHENIX 2004: segment5 -> segment6.
                   gcc.account_type
            INTO   vv_old_segment1,
                   vv_old_segment2,
                   vv_old_segment4,  -- PHENIX 2004: Ajout.
                   vv_old_segment6,  -- PHENIX 2004: segment5 -> segment6.
                   vv_account_type
            FROM   gl_code_combinations gcc
            WHERE  gcc.code_combination_id = :NEW.code_combination_id;

            -- Récupération de l'appartenance du projet
            vv_new_segment6   := dka_pa_tools_pkg.get_centre_finance (  -- PHENIX 2004: segment5 -> segment6.
                                     fn_project_id    => TO_NUMBER (:NEW.attribute11),
                                     fd_date          => :NEW.effective_date
                                 );

            IF vv_new_segment6 IS NULL  -- PHENIX 2004: segment5 -> segment6.
            THEN
                SELECT    'ERREUR Calcul Seg 6' -- 19  -- PHENIX 2004: "Seg 5" -> "Seg 6".
                       || CHR (10)
                       || 'je_header_id ' || TO_CHAR (:NEW.je_header_id) -- 13 + 9 = 22
                       || CHR (10)
                       || 'line ' || TO_CHAR (:NEW.je_line_num) -- 5 + 5 = 10
                INTO   vv_errbuf
                FROM   gl_je_headers gjh,
                       pa_projects_all pp
                WHERE      pp.project_id = TO_NUMBER (:NEW.attribute11)
                       AND gjh.je_header_id = :NEW.je_header_id;

                RAISE e_error;
            END IF;

            -- Si le segment6 a changé, recalcul du segment4  -- PHENIX 2004: segment5 -> segment6 et segment2 -> segment4.
            IF vv_new_segment6 != vv_old_segment6             -- PHENIX 2004: segment5 -> segment6.
            THEN
                IF vv_account_type = 'E'
                THEN
                    -- Compte de charge
                    vv_new_segment4   := dka_spaautoaccounting_pkg.run_cpt_groupe_couts_f (  -- PHENIX 2004: segment2 -> segment4.
                                             pn_project_id             => TO_NUMBER (:NEW.attribute11),
                                             pv_expenditure_type       => :NEW.attribute13,
                                             pn_expenditure_item_id    => NULL,
											 pn_task_id                => :NEW.attribute17, --YWA artf2245522 
											 pn_refac_project_id       => TO_NUMBER (:NEW.attribute15)
                                         );
                ELSIF vv_account_type = 'R'
                THEN
                    -- Compte de produit
                    vv_new_segment4   := dka_spaautoaccounting_pkg.run_cpt_groupe_produit_f (  -- PHENIX 2004: segment2 -> segment4.
                                             pn_project_id   => TO_NUMBER (:NEW.attribute11),
                                             pv_event_type   => :NEW.attribute12,
                                             pn_task_id      => :NEW.attribute17  --YWA artf2245522 
                                         );
                END IF;

                IF vv_new_segment4 IS NULL  -- PHENIX 2004: segment2 -> segment4.
                THEN
                    SELECT    'ERREUR : Impossible de calculer le segment 4 :' -- PHENIX 2004: 'segment 2' -> 'segment 4'.
                           || CHR (10)
                           || 'Pièce : ' || gjh.name || ' (je_header_id = ' || TO_CHAR (:NEW.je_header_id) || ')'
                           || CHR (10)
                           || 'Ligne : ' || TO_CHAR (:NEW.je_line_num)
                           || CHR (10)
                           || 'Projet : ' || pp.segment1
                           || CHR (10)
                           || 'Type de mouvement : ' || NVL (:NEW.attribute13, :NEW.attribute12)
                    INTO   vv_errbuf
                    FROM   gl_je_headers gjh,
                           pa_projects_all pp
                    WHERE      pp.project_id = TO_NUMBER (:NEW.attribute11)
                           AND gjh.je_header_id = :NEW.je_header_id;

                    RAISE e_error;
                END IF;
            ELSE
                vv_new_segment4   := vv_old_segment4;  -- PHENIX 2004: segment2 -> segment4.
            END IF;

            -- JPE  16/06/2016 MIGRATION R12 Segment 1 et 2 non changé cette fonction n'est plus utile
            -- Récupération du couple Cdg/Soc du projet
            /*vv_new_segment1_2 := dka_ibdsoc_tools_pkg.get_proj_acct_area_company_f (  -- PHENIX 2004: vv_new_segment1 -> lv_new_segment1_2.
                                     pn_project_id    => TO_NUMBER (:NEW.attribute11),
                                     pv_return_type   => '0',
                                     pd_ref_date      => :NEW.effective_date
                                 );
            
            IF vv_new_segment1_2 IS NULL  -- PHENIX 2004: vv_new_segment1 -> lv_new_segment1_2.
            THEN
                SELECT    'ERREUR : Impossible de calculer le segment 1 :'
                       || CHR (10)
                       || 'Pièce : ' || gjh.name || ' (je_header_id = ' || TO_CHAR (:NEW.je_header_id) || ')'
                       || CHR (10)
                       || 'Ligne : ' || TO_CHAR (:NEW.je_line_num)
                       || CHR (10)
                       || 'Projet : ' || pp.segment1
                INTO   vv_errbuf
                FROM   gl_je_headers gjh,
                       pa_projects_all pp
                WHERE      pp.project_id = TO_NUMBER (:NEW.attribute11)
                       AND gjh.je_header_id = :NEW.je_header_id;

                RAISE e_error;
            END IF;

            vv_new_segment1 := substr(vv_new_segment1_2, dka_tools_pkg.segment_size(2)+1, dka_tools_pkg.segment_size(1));  -- PHENIX 2004: Ajout.
            vv_new_segment2 := substr(vv_new_segment1_2, 1, dka_tools_pkg.segment_size(2));                              -- PHENIX 2004: Ajout.

            IF (   ( vv_new_segment1 != vv_old_segment1 AND vv_new_segment2 != vv_old_segment2)  -- PHENIX 2004: Ajout ( ... AND vv_new_segment2 != vv_old_segment2).
                OR vv_new_segment4 != vv_old_segment4  -- PHENIX 2004: segment2 -> segment4.
                OR vv_new_segment6 != vv_old_segment6) -- PHENIX 2004: segment6 -> segment6.*/
			IF ( vv_new_segment4 != vv_old_segment4 OR vv_new_segment6 != vv_old_segment6) -- PHENIX 2004: segment2 -> segment4 / segment6 -> segment6.	
            THEN
                DECLARE
                    vn_ccid             gl_code_combinations.code_combination_id%TYPE;
                    vv_old_segment3     gl_code_combinations.segment3%TYPE;
                    vv_old_segment5     gl_code_combinations.segment5%TYPE;   -- PHENIX 2004: segment4 -> segment5.
                    vv_old_segment7     gl_code_combinations.segment7%TYPE;   -- PHENIX 2004: segment6 -> segment7.
                    vv_old_segment8     gl_code_combinations.segment8%TYPE;   -- PHENIX 2004: segment7 -> segment8.
                    vv_old_segment9     gl_code_combinations.segment9%TYPE;   -- PHENIX 2004: segment8 -> segment9.
                    vv_old_segment10    gl_code_combinations.segment10%TYPE;  -- PHENIX 2004: Ajout.
                    vv_old_segment11    gl_code_combinations.segment11%TYPE;  -- JPE 16/06/2016 MIGRATION R12 AJOUT DU SEGMENT 11
                    vv_old_segment12    gl_code_combinations.segment12%TYPE;  -- JPE 16/06/2016 MIGRATION R12 AJOUT DU SEGMENT 12
                    vn_retcode          NUMBER (22)                                     := 0;
                BEGIN
                    -- Récupération des segment complémentaires
                    SELECT gcc.segment3,
                           gcc.segment5,     -- PHENIX 2004: segment4 -> segment5.
                           gcc.segment7,     -- PHENIX 2004: segment6 -> segment7.
                           gcc.segment8,     -- PHENIX 2004: segment7 -> segment8.
                           gcc.segment9,     -- PHENIX 2004: segment8 -> segment9.
                           gcc.segment10,    -- PHENIX 2004: Ajout.
						   gcc.segment11,	 -- JPE 16/06/2016 MIGRATION R12 AJOUT DU SEGMENT 11
						   gcc.segment12	 -- JPE 16/06/2016 MIGRATION R12 AJOUT DU SEGMENT 12
                    INTO   vv_old_segment3,
                           vv_old_segment5,  -- PHENIX 2004: segment4 -> segment5.
                           vv_old_segment7,  -- PHENIX 2004: segment6 -> segment7.
                           vv_old_segment8,  -- PHENIX 2004: segment7 -> segment8.
                           vv_old_segment9,  -- PHENIX 2004: segment8 -> segment9.
                           vv_old_segment10,  -- PHENIX 2004: Ajout.
						   vv_old_segment11, -- JPE 16/06/2016 MIGRATION R12 AJOUT DU SEGMENT 11
						   vv_old_segment12  -- JPE 16/06/2016 MIGRATION R12 AJOUT DU SEGMENT 12
                    FROM   gl_code_combinations gcc
                    WHERE  gcc.code_combination_id = :NEW.code_combination_id;

                    -- Détermination du nouveau CCID
                    dka_tools_pkg.get_code_combination_id (
                        vv_old_segment1,
                        vv_old_segment2,
                        vv_old_segment3,
                        vv_new_segment4,  -- PHENIX 2004: vv_old_segment4 -> vv_new_segment4. 
                        vv_old_segment5,  -- PHENIX 2004: vv_new_segment5 -> vv_old_segment5.
                        vv_new_segment6,  -- PHENIX 2004: vv_old_segment6 -> vv_new_segment6.
                        vv_old_segment7,
                        vv_old_segment8,
                        vv_old_segment9,  -- PHENIX 2004: Ajout.
                        vv_old_segment10, -- PHENIX 2004: Ajout.
                        vv_old_segment11, -- JPE 16/06/2016 MIGRATION R12 AJOUT DU SEGMENT 11
                        vv_old_segment12, -- JPE 16/06/2016 MIGRATION R12 AJOUT DU SEGMENT 12.
                        vn_ccid,
                        vv_errbuf,
                        vn_retcode,
                        'Y'
                    );

                    IF NVL (vn_retcode, 0) != 0
                    THEN
                        RAISE e_error;
                    END IF;

                    :NEW.code_combination_id   := vn_ccid;
                END;
            END IF;
        END;
    END IF;
EXCEPTION
    WHEN e_error
    THEN
        vv_errbuf   :=    CHR (10)
                       || vv_errbuf
                       || CHR (10)
                       || CHR (10)
                       || CHR (10)
                       || CHR (10)
                       || CHR (10);
        app_exception.raise_exception (exception_text => vv_errbuf);
    WHEN NO_DATA_FOUND
    THEN
        NULL;
    WHEN OTHERS
    THEN
        app_exception.raise_exception (exception_text => NVL (vv_errbuf, SQLERRM));
END;
/

SHOW ERROR
EXIT;
