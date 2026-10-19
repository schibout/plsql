/* Formatted on 03/11/2002 16:18 (Formatter Plus v4.5.2) */
----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_GL_JE_LINES_RECON_AIUR.trg
-- DESCRIPTION       : Trigger sur la table GL_JE_LINES
---
--- AUTEUR           : Oussama BENHAYOUN
--- DATE DE CREATION : 26/09/2017
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 02/11/2023 ARA EDB281 EDB281 - DGE20210006 - Alimentation du segment5 de la clé comptable
--------------------------------------------------------------------------------------------


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU TRIGGER DKA_GL_JE_LINES_RECON_AIUR
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE TRIGGER DKA_GL_JE_LINES_RECON_AIUR
    AFTER INSERT OR UPDATE
    ON gl.gl_je_lines
    FOR EACH ROW
    
DECLARE

    vv_segment3       VARCHAR2(25);
	vv_segment5		  VARCHAR2(25); --ARA
    pv_flag_matricule VARCHAR2(1);
	vv_jgzz_recon_ref VARCHAR2(100);

BEGIN

    
    SELECT segment3 , segment5 --EDB281 ARA
    INTO vv_segment3 , vv_segment5
    FROM gl_code_combinations
    WHERE code_combination_id = :NEW.code_combination_id ;
    
    SELECT DECODE(COUNT(1), 0, 'N', 'Y')
    INTO pv_flag_matricule
    FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
    WHERE ffvs.flex_value_set_id = ffv.flex_value_set_id
    AND ffvs.flex_value_set_name = 'DKA_COMPTE_MATRICULE'
    AND ffv.flex_value = vv_segment3
    AND ffv.enabled_flag = 'Y';    
	
	BEGIN
		SELECT NVL(JGZZ_RECON_REF,'NULL')
		INTO vv_jgzz_recon_ref
		FROM gl_je_lines_recon
		WHERE je_header_id      = :NEW.je_header_id
		AND je_line_num         = :NEW.je_line_num;
	EXCEPTION
		WHEN OTHERS THEN
		vv_jgzz_recon_ref := 'NULL';
	END;
    
    IF pv_flag_matricule = 'Y' THEN
		IF vv_jgzz_recon_ref NOT LIKE vv_segment5 THEN--:NEW.attribute11||'%' THEN
			UPDATE gl_je_lines_recon
		--	SET JGZZ_RECON_REF = DECODE(JGZZ_RECON_REF,NULL,:NEW.attribute11,:NEW.attribute11||'-'||JGZZ_RECON_REF) --changer att11 par segment5
			SET JGZZ_RECON_REF = DECODE(JGZZ_RECON_REF,NULL,vv_segment5,vv_segment5||'-'||JGZZ_RECON_REF) --EDB281 ARA
			WHERE je_header_id      = :NEW.je_header_id
			AND je_line_num         = :NEW.je_line_num;
		END IF;
      
    END IF;


EXCEPTION
    WHEN OTHERS THEN
      NULL;
END;
/

SHOW ERROR
EXIT;
