CREATE OR REPLACE PACKAGE BODY dka_sglperutil_pkg
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SGLPERUTIL_PKG.pks
-- DESCRIPTION       : DKA_SGLPERUTIL_PKG package body :
---
--- AUTEUR           : Xavier DESCAMPS (CGEY)
--- DATE DE CREATION : 05/03/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 07/02/2006 GV   get_select_record_group : ajout restriction LOV pour code TVA sur ligne
---                 update_gl_tax_ccid : création d'une fonction qui met a jour la ccid de
---                                      la ligne de TVA GL en fonction de la ccid de la
---                                      ligne de charge correspondante
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-----------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------

    --  Nom           : get_select_record_group
    -- Description   : Renvoie le record groupe associé
    --
    --
    --
    --
    --  VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles : 0:normal
    --                         2:erreur

------------------------------------------------------------------------------------------------------------------------
    FUNCTION get_select_record_group (
        pv_record_group     IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_select   VARCHAR2 (5000);
    BEGIN
    	--Restriction code tva sur l'entete
        IF pv_record_group = 'PERIOD_NAME_QF'
        THEN
            vv_select    := REPLACE (
                                cg_rg_period_name_qf,
							    'order by',
    						    'and period_name IN '
    							|| '( select gps.period_name '
    							|| 'from gl.gl_period_statuses gps '
    							|| 'where gps.application_id = 101 '
    							|| 'and ( NVL (gps.attribute1, ''N'') = ''N'' '
    							|| ' or ( gps.attribute1 = ''Y'' and fnd_profile.value(''DKA_GL_SPECIAL_PERIOD'') = ''Y'')) ) '
                                || 'order by'
                            );

        ELSIF pv_record_group = 'DEFAULT_PERIOD_NAME_HDR_ACT'--'DEFAULT_PERIOD_NAME_ACTUAL' --RBE
        THEN
			vv_select    := REPLACE (
			                    cg_rg_header_period_actual,
							    'order by',
    						    'and period_name IN '
    							|| '( select gps.period_name '
    							|| 'from gl_period_statuses gps '
    							|| 'where gps.application_id = 101 '
    							--|| 'and gps.set_of_books_id = :world.set_of_books_id ' --RBE MigR12
    							|| 'and gps.ledger_id = :header.ledger_id '              --RBE MigR12
    							|| 'and ( NVL (gps.attribute1, ''N'') = ''N'' '
    							|| ' or ( gps.attribute1 = ''Y'' and fnd_profile.value(''DKA_GL_SPECIAL_PERIOD'') = ''Y'')) ) '
    							|| 'order by'
    							);
        ELSIF pv_record_group = 'SHOW_TAX_CODE'
        THEN
            vv_select := cg_rg_show_tax_code;
        ELSE
            vv_select    := NULL;
        END IF;

        RETURN vv_select;

    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_select_record_group;


-- -------------------------------------------------------------------------------------------------------------------------

    --  Nom           : update_gl_tax_ccid
    -- Description   : Renvoie TRUE s'il y a eu maj de la ccid tva
    --
    --
    --
    --
    --  VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles : 0:normal
    --                         2:erreur

------------------------------------------------------------------------------------------------------------------------

    FUNCTION update_gl_tax_ccid (
        pn_je_header_id     IN   NUMBER)
    RETURN BOOLEAN

    IS
      vb_update              BOOLEAN := FALSE;
      vn_ccid_tva_out        NUMBER;
      vv_segment2_ht         VARCHAR2(150);
      vv_seg1                VARCHAR2(150);
      vv_seg3                VARCHAR2(150);
      vv_seg4                VARCHAR2(150);
      vv_seg5                VARCHAR2(150);
      vv_seg6                VARCHAR2(150);
      vv_seg7                VARCHAR2(150);
      vv_seg8                VARCHAR2(150);

      -- Curseur qui sélectionne les couples de lignes GL TVA/HT
      -- en fonction du je_header_id passé en parametre
      CURSOR cur_gl_je_lines IS
      SELECT gjl1.code_combination_id ccid_tva,
             gjl2.code_combination_id ccid_ht
      FROM gl_je_lines gjl1,
           gl_je_lines gjl2
      WHERE gjl1.je_header_id = pn_je_header_id
       AND gjl1.tax_line_flag = 'Y'
       AND gjl2.je_header_id = gjl1.je_header_id
       AND gjl2.tax_group_id = gjl1.tax_group_id
       AND nvl(gjl2.tax_line_flag, 'N') = 'N'
      FOR UPDATE OF gjl1.code_combination_id;


      BEGIN

         FOR rec_gl_je_lines IN cur_gl_je_lines
         LOOP
            -- Récupération segment2 de la ccid_ht
            SELECT segment2
            INTO vv_segment2_ht
            FROM gl_code_combinations
            WHERE code_combination_id = rec_gl_je_lines.ccid_ht;

            -- Récupération segments de la ccid_tva
            SELECT segment1, segment3, segment4, segment5, segment6, segment7, segment8
            INTO vv_seg1, vv_seg3, vv_seg4, vv_seg5, vv_seg6, vv_seg7, vv_seg8
            FROM gl_code_combinations
            WHERE code_combination_id = rec_gl_je_lines.ccid_tva;

            BEGIN
                 -- Récupération ccid_tva_out
                 SELECT code_combination_id
                 INTO vn_ccid_tva_out
                 FROM gl_code_combinations
                 WHERE segment1 = vv_seg1
                   AND segment2 = vv_segment2_ht
                   AND segment3 = vv_seg3
                   AND segment4 = vv_seg4
                   AND segment5 = vv_seg5
                   AND segment6 = vv_seg6
                   AND segment7 = vv_seg7
                   AND segment8 = vv_seg8
                   AND segment9 = '0'
                   AND segment10 = '0'
                   AND segment11 = '0'
                   AND segment12 = '0';
                   
                   EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                   -- Insertion de la nouvelle combinaison
                   INSERT INTO gl_code_combinations (
                    code_combination_id,
                    chart_of_accounts_id,
                    detail_posting_allowed_flag,
                    detail_budgeting_allowed_flag,
                    account_type,
                    enabled_flag,
                    summary_flag,
                    preserve_flag,
                    segment1,
                    segment2,
                    segment3,
                    segment4,
                    segment5,
                    segment6,
                    segment7,
                    segment8,
					          segment9, 
                    segment10, 
					          segment11, 
                    segment12, 
                    reference3,
                    jgzz_recon_flag,
                    last_update_date,
                    last_updated_by
                    )
                   SELECT gl_code_combinations_s.NEXTVAL,
                         gsob.chart_of_accounts_id,
                         'Y',
                         'N',
                         'A',
                         'Y',
                         'N',
                         '',
                         vv_seg1,
                         vv_segment2_ht, 
                         vv_seg3,
                         vv_seg4,
                         vv_seg5,
                         vv_seg6,
                         vv_seg7,
                         vv_seg8,
                         '0', 
                         '0', 
                         '0', 
                         '0', 
                         'N',
                         'N',
                         SYSDATE,
                         Fnd_Global.user_id
                  --FROM   gl_sets_of_books gsob
                  --WHERE  gsob.set_of_books_id = Fnd_Profile.value ('GL_SET_OF_BKS_ID');
                  FROM   gl_ledgers gsob
                  WHERE  gsob.ledger_id = TO_NUMBER(GL_ACCESS_SET_SECURITY_PKG.GET_DEFAULT_LEDGER_ID(FND_PROFILE.value('GL_ACCESS_SET_ID'), 'R')); --MigR12

                -- Récupération de l'id
                SELECT gl_code_combinations_s.CURRVAL
                INTO   vn_ccid_tva_out
                FROM   dual;
            END;                    

            -- Le segment2 TVA doit etre identique au segment2 de la ligne HT correspondante
            IF vn_ccid_tva_out != rec_gl_je_lines.ccid_tva
            THEN
                UPDATE gl_je_lines
                SET code_combination_id = vn_ccid_tva_out
                WHERE CURRENT OF cur_gl_je_lines;
                vb_update := TRUE;
                COMMIT;
            END IF;

         END LOOP;

         RETURN vb_update;

      EXCEPTION
         
        WHEN OTHERS
        THEN
            RETURN FALSE;

      END;



-------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
END dka_sglperutil_pkg;
/
SHOW ERROR
EXIT;