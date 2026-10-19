create or replace PACKAGE BODY DKA_SGLCTRLFLUXIFRS_PKG
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJECT          : DALKIA Oracle Applications
-- NAME             : DKA_SGLCTRLFLUXIFRS.pkb
-- DESCRIPTION      : Package body VECTOR IFRS Flew control
-- AUTHOR           : CDEL (CG)
-- CREATION DATE    : 09/04/2008
-- COMMENTS         : Execute on SQLPLUS with user APPS
--------------------------------------------------------------------------------------------
-- MODIFICATION HISTORY
-- Date       Who Description
-- ---------- --- -------------------------------------------------------------------------
-- 24/02/2016 PBR Migration R12.
-- 21/06/2017 YWA artf2178310 
--------------------------------------------------------------------------------------------


----------------------------------------------------------------------------
--  Nom           : init
--  Description   : Procédure d'initialisation
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
    PROCEDURE init (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        rec_param   dka_parameters%ROWTYPE;
        vv_category fnd_document_categories.name%TYPE;

    BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - begin of procedure Init');
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        
        -- Choix de la langue
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''FRENCH''';
        
        -- global variables
        gn_request_id                   := fnd_global.conc_request_id;
        gv_application_short_name       := dka_ieoglvec01_pkg.get_application_short_name(Fnd_Global.prog_appl_id);
        
        --gn_set_of_books_id              := Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID'); --R12 .

        -- specific variables
        gv_nature                            := dka_ieoglvec01_pkg.get_message(gv_application_short_name,'DKA_SGLCTRLFLUXIFRS_NATURE');
        gv_title                             := dka_ieoglvec01_pkg.get_message(gv_application_short_name,'DKA_SGLCTRLFLUXIFRS_TITLE');
        gv_total                             := dka_ieoglvec01_pkg.get_message(gv_application_short_name,'DKA_SGLCTRLFLUXIFRS_TOTAL');
        gv_columns                           := dka_ieoglvec01_pkg.get_message(gv_application_short_name,'DKA_SGLCTRLFLUXIFRS_COLUMNS');
        gv_description_F00                   := dka_ieoglvec01_pkg.get_message(gv_application_short_name,'DKA_SGLCTRLFLUXIFRS_DESC_F00');
        gv_description_F99                   := dka_ieoglvec01_pkg.get_message(gv_application_short_name,'DKA_SGLCTRLFLUXIFRS_DESC_F99');
        gv_list_argos_account                := dka_ieoglvec01_pkg.get_message(gv_application_short_name,'DKA_SGLCTRLFLUXIFRS_ARG_ACCNT');


        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - end of procedure Init');

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode   := 2;
            pv_errbuf    := 'INIT : ' ||SQLERRM;
    END init;



-----------------------------------------------------------------
--  Name          : GET_CUF_FLEX_VALUE_SET_ID
--  Description   : Function to find flex value set ID of descriptive flexfield link to a qualifier
--                  in parameter
--
--  PARAMETERS :
--     pv_qualifier           qualifier code
--     pv_code_attribute      attribute code
--
--  RETURN VALUE :
--     attribute_num       :  attribute number in CUF
-----------------------------------------------------------------
    FUNCTION get_cuf_flex_value_set_id (
        pv_qualifier        IN   VARCHAR2,
        pv_code_attribute   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_flex_value_set_id             VARCHAR2(12);
    BEGIN
        -- Initialisation
        vv_flex_value_set_id := NULL;

        -- attribute number link to attribute code and qualifier
        BEGIN
        SELECT DISTINCT fdfcu.flex_value_set_id
        INTO   vv_flex_value_set_id
        FROM   fnd_segment_attribute_values fsav,
               gl_sets_of_books gsob,
               fnd_id_flex_segments fifs,
               fnd_flex_value_sets ffvs,
               fnd_descr_flex_col_usage_vl fdfcu,
               fnd_application fa_fnd,
               fnd_application fa_gl
        WHERE  fsav.id_flex_num = gsob.chart_of_accounts_id
          AND  fsav.application_id = fa_gl.application_id
          AND  fifs.application_column_name = fsav.application_column_name
          AND  fifs.id_flex_num = gsob.chart_of_accounts_id
          AND  ffvs.flex_value_set_id = fifs.flex_value_set_id
          AND  fdfcu.descriptive_flex_context_code = ffvs.flex_value_set_name
          AND  fdfcu.application_id = fa_fnd.application_id
          AND  gsob.set_of_books_id IN (select ledger_id FROM GL_access_set_assignments where access_set_id = (fnd_profile.value('GL_ACCESS_SET_ID'))) --R12
          AND  fsav.id_flex_code = 'GL#'
          AND  fsav.attribute_value = 'Y'
          AND  fifs.id_flex_code = 'GL#'
          AND  fdfcu.descriptive_flexfield_name    = 'FND_FLEX_VALUES'
          AND  fdfcu.enabled_flag = 'Y'
          AND  fdfcu.display_flag = 'Y'
          AND  fa_fnd.application_short_name = 'FND'
          AND  fa_gl.application_short_name = 'SQLGL'
          AND  fsav.segment_attribute_type = pv_qualifier
          AND  fdfcu.end_user_column_name  = pv_code_attribute;
          
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            vv_flex_value_set_id := NULL;
        END;


        ----- return value -----
        RETURN (vv_flex_value_set_id);
    END get_cuf_flex_value_set_id;


-----------------------------------------------------------------
--  Name          : GET_DESCRIPTION_FLOW
--  Description   : Function to find description of flow value
--                  in parameter
--
--  PARAMETERS :
--     pv_flow                flow code
--
--  RETURN VALUE :
--     decsription_flow       :  description in CUF
-----------------------------------------------------------------
    FUNCTION get_description_flow (
        pv_flow        IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_description_flow             VARCHAR2(240);
        vv_flex_value_set_id            NUMBER;
    BEGIN
        -- Initialisation
        vv_description_flow := NULL;
        vv_flex_value_set_id := dka_ieoglvec01_pkg.get_qual_flex_value_set_id('XARGOS_FLOW');

        -- flex value description
        BEGIN
        SELECT ffvt.description
        INTO   vv_description_flow
        FROM   fnd_flex_values_tl ffvt,
               fnd_flex_values ffv
        WHERE  ffvt.flex_value_id = ffv.flex_value_id
          AND  ffv.flex_value_set_id = vv_flex_value_set_id
          AND  ffvt.language = USERENV('LANG')
          AND  ffv.flex_value = pv_flow;
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            vv_description_flow := NULL;
        END;


        ----- return value -----
        RETURN (vv_description_flow);
    END get_description_flow;

-----------------------------------------------------------------
--  Name          : DELETE_DKA_SGLCTRLFLUXIFRS_TMP
--  Description   : delete data in temporary table DKA_SGLCTRLFLUXIFRS_TMP
--
--
--  PARAMETERS :
--  pn_request_id     Input           Request_Id
--  pv_errbuf   Input/Output          Error message
--
--  RETURN VALUE :
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
-----------------------------------------------------------------
    PROCEDURE delete_dka_sglctrlfluxifrs_tmp (
        pn_request_id     IN       NUMBER,
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    )
    IS


    BEGIN
    pn_retcode := 0;

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Begin of procedure delete_dka_sglctrlfluxifrs_tmp');

    DELETE dka_sglctrlfluxifrs_tmp
    WHERE  request_id = pn_request_id;

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Rows deleted : ' || TO_CHAR (SQL%ROWCOUNT));
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure delete_dka_sglctrlfluxifrs_tmp');

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || pv_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure delete_dka_sglctrlfluxifrs_tmp : EXCEPTION OTHERS ');
    END delete_dka_sglctrlfluxifrs_tmp;


-----------------------------------------------------------------
--  Name          : INSERT_DKA_SGLCTRLFLUXIFRS_TMP
--  Description   : Insert data in temporary table DKA_SGLCTRLFLUXIFRS_TMP
--
--
--  PARAMETERS :
--     pv_period_name         period name
--     pv_company_code        company code
--     pv_op_unit             operating unit
--     pv_conso_code         conso code
--     pv_errbuf      Input/Output          Error message
--
--  RETURN VALUE :
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
-----------------------------------------------------------------
    PROCEDURE insert_dka_sglctrlfluxifrs_tmp (
        pv_period_name    IN       VARCHAR2,
        pv_company_code   IN       VARCHAR2,
        pv_op_unit        IN       VARCHAR2,
        pv_conso_code    IN       VARCHAR2,
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    )
    IS
        sql_req                          VARCHAR2(4000);
        vv_seg_local_account_num         VARCHAR2(12);
        vv_seg_argos_account_num         VARCHAR2(12);
        vv_seg_op_unit_num               VARCHAR2(12);
        vv_seg_gl_balancing_num          VARCHAR2(12);
        vv_seg_flow_num                  VARCHAR2(12);
        vv_att_argos_excluded            VARCHAR2(12);
        vn_set_of_books_id               NUMBER;
        vv_flex_val_set_name_argos       VARCHAR2(60);
        vv_begin_period_name             VARCHAR2(10);

    BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||  'Begin of procedure insert_dka_sglctrlfluxifrs_tmp');

        vv_seg_gl_balancing_num    := dka_ieoglvec01_pkg.get_segment_num('GL_BALANCING');
        vv_seg_local_account_num   := dka_ieoglvec01_pkg.get_segment_num('GL_ACCOUNT');
        vv_seg_argos_account_num   := dka_ieoglvec01_pkg.get_segment_num('XARGOS_ACCOUNT');
        vv_seg_op_unit_num         := dka_ieoglvec01_pkg.get_segment_num('XARGOS_OPERATING_UNIT');
        vv_seg_flow_num            := dka_ieoglvec01_pkg.get_segment_num('XARGOS_FLOW');
        vv_att_argos_excluded      := dka_ieoglvec01_pkg.get_cuf_attribute_num('XARGOS_ACCOUNT','ARGOS_EXCLUDED');
        vv_flex_val_set_name_argos := dka_ieoglvec01_pkg.get_qual_flex_value_set_name('XARGOS_ACCOUNT');
        vv_begin_period_name       := 'JAN-'||substr(pv_period_name,5,2);

        -- Insert data only if qualifier are setuped
        IF (vv_seg_gl_balancing_num IS NOT NULL
            AND vv_seg_op_unit_num IS NOT NULL
            AND vv_seg_local_account_num IS NOT NULL
            AND vv_seg_argos_account_num IS NOT NULL
            AND vv_seg_flow_num IS NOT NULL
            AND vv_att_argos_excluded IS NOT NULL
            )

        THEN

            -- Insert begin_balance of the year
            sql_req := 'INSERT INTO dka_sglctrlfluxifrs_tmp '||
                                   '(request_id,'||
                                   'line_type,'||
                                   'period_name,'||
                                   'company_code,'||
                                   'operating_unit,'||
                                   'conso_code,'||
                                   'local_account,'||
                                   'group_account,'||
                                   'flow,'||
                                   'currency_code,'||
                                   'begin_balance,'||
                                   'amount)'||
                        '(SELECT  '||gn_request_id||', '||
                                  '''OPEN_BAL'','||
                                  'gb.period_name,'||
                                  ':pv_company_code,'||
                                  ':pv_op_unit,'||
                                  ':pv_conso_code,'||
                                  'gcc.'||vv_seg_local_account_num||','||
                                  'gcc.'||vv_seg_argos_account_num||','||
                                  'gcc.'||vv_seg_flow_num||','||
                                  'gsob.currency_code,'||
                                  'SUM (gb.begin_balance_dr - gb.begin_balance_cr)/1000,'||
                                  '''0'''||
                        ' FROM     gl_ledgers gsob,'||
                                  'gl_balances gb,'||
                                  'gl_code_combinations gcc '||
                         'WHERE        1 = 1 '||
                                 ' AND gcc.code_combination_id = gb.code_combination_id '||
                                 ' AND gb.ledger_id = gsob.ledger_id '||
                                 ' AND gsob.ledger_id = '||gn_set_of_books_id||
                                 ' AND gb.actual_flag = ''A'' '||
                                 ' AND gb.template_id IS NULL '||
                                 ' AND gb.currency_code = gsob.currency_code '||
                                 ' AND gcc.'||vv_seg_gl_balancing_num||' = :pv_company_code'||
                                 ' AND gcc.'||vv_seg_op_unit_num||' = :pv_op_unit'||
                                 ' AND gcc.summary_flag = ''N'' '||
                                 ' AND gcc.template_id IS NULL '||
                                 ' AND gb.period_name = :vv_begin_period_name'||
                                 ' AND gcc.'||vv_seg_argos_account_num||' NOT IN (SELECT ffv.flex_value '||
                                                                                 'FROM   fnd_flex_values ffv, '||
                                                                                        'fnd_flex_value_sets ffvs '||
                                                                                 'WHERE      ffv.flex_value_set_id = ffvs.flex_value_set_id '||
                                                                                        ' AND ffvs.flex_value_set_name = '''||vv_flex_val_set_name_argos||
                                                                                        '''AND ffv.'||vv_att_argos_excluded||' = ''Y'' )'||
                                  ' AND substr(gcc.'||vv_seg_argos_account_num||',1,2) IN '||gv_list_argos_account||
                      ' GROUP BY  gb.period_name,'||
                                  'gsob.currency_code,'||
                                  'gcc.'||vv_seg_local_account_num||','||
                                  'gcc.'||vv_seg_argos_account_num||','||
                                  'gcc.'||vv_seg_flow_num||')'
                         ;

            EXECUTE IMMEDIATE sql_req USING pv_company_code, pv_op_unit, pv_conso_code, pv_company_code, pv_op_unit, vv_begin_period_name;

            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Rows inserted into dka_sglctrlfluxifrs_tmp : '|| TO_CHAR (SQL%ROWCOUNT));
            Fnd_File.put_line (Fnd_File.LOG,pv_company_code||' : '||dka_ieoglvec01_pkg.get_message('SQLGL','GL_REC_INS','REC', TO_CHAR (SQL%ROWCOUNT),'TABLE','dka_sglctrlfluxifrs_tmp'));


            sql_req := 'INSERT INTO dka_sglctrlfluxifrs_tmp '||
                                   '(request_id,'||
                                   'line_type,'||
                                   'period_name,'||
                                   'company_code,'||
                                   'operating_unit,'||
                                   'conso_code,'||
                                   'local_account,'||
                                   'group_account,'||
                                   'flow,'||
                                   'currency_code,'||
                                   'begin_balance,'||
                                   'amount)'||
                        '(SELECT  '||gn_request_id||', '||
                                  '''MONTH_BAL'','||
                                  'gb.period_name,'||
                                  ':pv_company_code,'||
                                  ':pv_op_unit,'||
                                  ':pv_conso_code,'||
                                  'gcc.'||vv_seg_local_account_num||','||
                                  'gcc.'||vv_seg_argos_account_num||','||
                                  'gcc.'||vv_seg_flow_num||','||
                                  'gsob.currency_code,'||
                                  'SUM (gb.begin_balance_dr - gb.begin_balance_cr)/1000,'||
                                  'SUM (gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr)/1000'||
                        ' FROM     gl_ledgers gsob,'||
                                  'gl_balances gb,'||
                                  'gl_code_combinations gcc '||
                         'WHERE        1 = 1 '||
                                 ' AND gcc.code_combination_id = gb.code_combination_id '||
                                 ' AND gb.ledger_id = gsob.ledger_id '||
                                 ' AND gsob.ledger_id = '||gn_set_of_books_id||
                                 ' AND gb.actual_flag = ''A'' '||
                                 ' AND gb.template_id IS NULL '||
                                 ' AND gb.currency_code = gsob.currency_code '||
                                 ' AND gcc.'||vv_seg_gl_balancing_num||' = :pv_company_code'||
                                 ' AND gcc.'||vv_seg_op_unit_num||' = :pv_op_unit'||
                                 ' AND gcc.summary_flag = ''N'' '||
                                 ' AND gcc.template_id IS NULL '||
                                 ' AND gb.period_name = :pv_period_name'||
                                 ' AND gcc.'||vv_seg_argos_account_num||' NOT IN (SELECT ffv.flex_value '||
                                                                                 'FROM   fnd_flex_values ffv, '||
                                                                                        'fnd_flex_value_sets ffvs '||
                                                                                 'WHERE      ffv.flex_value_set_id = ffvs.flex_value_set_id '||
                                                                                        ' AND ffvs.flex_value_set_name = '''||vv_flex_val_set_name_argos|| --16/11/2007
                                                                                        '''AND ffv.'||vv_att_argos_excluded||' = ''Y'' )'||
                                  ' AND substr(gcc.'||vv_seg_argos_account_num||',1,2) IN '||gv_list_argos_account||
                      ' GROUP BY gb.period_name,'||
                                  'gsob.currency_code,'||
                                  'gcc.'||vv_seg_local_account_num||','||
                                  'gcc.'||vv_seg_argos_account_num||','||
                                  'gcc.'||vv_seg_flow_num||')'
                         ;

            EXECUTE IMMEDIATE sql_req USING pv_company_code, pv_op_unit, pv_conso_code, pv_company_code, pv_op_unit, pv_period_name;

            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Rows inserted into dka_sglctrlfluxifrs_tmp : '|| TO_CHAR (SQL%ROWCOUNT));
            Fnd_File.put_line (Fnd_File.LOG,pv_company_code||' : '||dka_ieoglvec01_pkg.get_message('SQLGL','GL_REC_INS','REC', TO_CHAR (SQL%ROWCOUNT),'TABLE','dka_sglctrlfluxifrs_tmp'));


        ELSE

            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'No rows inserted into dka_sglctrlfluxifrs_tmp : All qualifier and descriptive flexfield are not correctly setuped');

        END IF;

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure insert_dka_sglctrlfluxifrs_tmp');

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || pv_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'End of procedure insert_dka_sglctrlfluxifrs_tmp : EXCEPTION OTHERS ');
    END insert_dka_sglctrlfluxifrs_tmp;


-----------------------------------------------------------------
--  Name          : UPDATE_DKA_SGLCTRLFLUXIFRS_TMP
--  Description   : Update data in temporary table DKA_SGLCTRLFLUXIFRS_TMP
--
--
--  PARAMETERS :
--    pv_conso_code         conso code
--    pv_errbuf   Input/Output          Error message
--
--  RETURN VALUE :
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
-----------------------------------------------------------------
    PROCEDURE update_dka_sglctrlfluxifrs_tmp (
        pv_conso_code    IN       VARCHAR2,
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    )
    IS


        CURSOR cur_account_vector(pv_conso_code VARCHAR2)
            IS
            SELECT conso_code,
                   local_account,
                   group_account,
                   sum(amount) sum_amount,
                   dka_ieoglvec01_pkg.get_cuf_attribute_value('XARGOS_ACCOUNT',
                                                               group_account,
                                                               decode (SIGN(sum(amount)), -1, 'ARGOS_ACCOUNT_C', 'ARGOS_ACCOUNT_D')
                                           ) argos_account,
                   dka_ieoglvec01_pkg.get_cuf_attribute_value('XARGOS_ACCOUNT', group_account, 'ARGOS_NATURE_SOURCE') nature
            FROM   dka_sglctrlfluxifrs_tmp
            WHERE  request_id = gn_request_id
              AND  conso_code = pv_conso_code
              AND  line_type = 'MONTH_BAL' -- argos_account are calculated on MONTH_BAL line type but applied on all line types
            GROUP BY conso_code,
                     local_account,
                     group_account
            ;

        rec_account_vector cur_account_vector%ROWTYPE;


    BEGIN

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Begin of procedure update_dka_ieoglvec01_int');



           -- Update argos_account and nature
           OPEN cur_account_vector (pv_conso_code);

           LOOP
           BEGIN
               FETCH cur_account_vector INTO rec_account_vector;
               EXIT WHEN cur_account_vector%NOTFOUND;

                  BEGIN

                      UPDATE dka_sglctrlfluxifrs_tmp
                         SET argos_account   = rec_account_vector.argos_account
                            ,nature          = rec_account_vector.nature
                       WHERE request_id            = gn_request_id
                         AND conso_code           = pv_conso_code
                         AND local_account         = rec_account_vector.local_account
                         AND group_account         = rec_account_vector.group_account;

                  EXCEPTION
                  WHEN OTHERS
                  THEN
                      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ERROR UPDATE TABLE dka_sglctrlfluxifrs_tmp');
                      pn_retcode := sqlcode;
                      pv_errbuf := substr(sqlerrm,1,400);
                      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> sqlcode = ' || pn_retcode );
                      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ' ||pv_errbuf);
                  END;

           EXCEPTION
           WHEN OTHERS
           THEN
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ERROR READ CURSOR rec_account_vector');
              pn_retcode := sqlcode;
              pv_errbuf := substr(sqlerrm,1,400);
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> sqlcode = ' || pn_retcode );
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ' ||pv_errbuf);
           END;

           END LOOP;

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure update_dka_sglctrlfluxifrs_tmp');

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || pv_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure update_dka_sglctrlfluxifrs_tmp : EXCEPTION OTHERS ');
    END update_dka_sglctrlfluxifrs_tmp;


-----------------------------------------------------------------
--  Name          : LOAD_DKA_IEOGLVEC01_INT
--  Description   : Load data in temporary table DKA_IEOGLVEC01_INT
--
--
--  PARAMETERS :
--    pv_conso_code         conso code
--    pv_period_name         Name of period
--    pv_errbuf   Input/Output          Error message
--
--  RETURN VALUE :
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
-----------------------------------------------------------------
    PROCEDURE load_dka_sglctrlfluxifrs_tmp (
        pv_conso_code    IN       VARCHAR2,
        pv_period_name    IN       VARCHAR2,
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    )
    IS

        e_error           EXCEPTION;
        vv_errbuf         VARCHAR2 (500);
        vn_retcode        NUMBER;

        --r12
        CURSOR cur_company(pv_conso_code VARCHAR2)
            IS
            SELECT DISTINCT
                   balancing_seg_value,
                   operating_unit
            FROM   dka_ieoglvec01_conso_code_v
            WHERE  conso_code = pv_conso_code;

        rec_company cur_company%ROWTYPE;

    BEGIN

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Begin of procedure load_dka_sglctrlfluxifrs_tmp');
    Fnd_File.put_line (Fnd_File.LOG, 'conso code : '||pv_conso_code);


           OPEN cur_company (pv_conso_code);

           LOOP
           BEGIN
               FETCH cur_company INTO rec_company;
               EXIT WHEN cur_company%NOTFOUND;

                  BEGIN

                  insert_dka_sglctrlfluxifrs_tmp
                                (pv_period_name,
                                 rec_company.balancing_seg_value,
                                 rec_company.operating_unit,
                                 pv_conso_code,
                                 vv_errbuf,
                                 vn_retcode
                                 );

                 IF vn_retcode = 1
                 THEN
                     pn_retcode   := 1;
                     pv_errbuf    := vv_errbuf;
                 ELSIF vn_retcode != 0
                 THEN
                     pn_retcode   := 2;
                     pv_errbuf    := vv_errbuf;
                     RAISE e_error;
                 END IF;

               END;

          EXCEPTION
          WHEN OTHERS
          THEN
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ERROR READ VIEW dka_ieoglvec01_conso_code');
              pn_retcode := sqlcode;
              pv_errbuf := substr(sqlerrm,1,400);
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> sqlcode = ' || pn_retcode );
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ' ||pv_errbuf);
          END;

          END LOOP;


          update_dka_sglctrlfluxifrs_tmp (pv_conso_code, vv_errbuf, vn_retcode);

          IF vn_retcode = 1
          THEN
              pn_retcode   := 1;
              pv_errbuf    := vv_errbuf;
          ELSIF vn_retcode != 0
          THEN
              pn_retcode   := 2;
              pv_errbuf    := vv_errbuf;
              RAISE e_error;
          END IF;


    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure load_dka_sglctrlfluxifrs_tmp');

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || pv_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure load_dka_sglctrlfluxifrs_tmp : EXCEPTION OTHERS ');
    END load_dka_sglctrlfluxifrs_tmp;


----------------------------------------------------------------------------
--  Name          : extraction_file
--  Description   : Request control procedure
--
--  PARAMETERS :
--    pv_errbuf   Input/Output          error message
--
--  RETURN VALUE :
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
----------------------------------------------------------------------------
    PROCEDURE extraction_file (
        pv_nature        IN       VARCHAR2,
        pv_errbuf        IN OUT   VARCHAR2,
        pn_retcode       IN OUT   NUMBER
    )
    IS
        e_fatal_error                 EXCEPTION;
        vn_sum_F00                    NUMBER;
        vn_sum_F13                    NUMBER;
        vn_sum_F17                    NUMBER;
        vn_sum_F20                    NUMBER;
        vn_sum_F40                    NUMBER;
        vn_sum_F25                    NUMBER;
        vn_sum_F44                    NUMBER;
        vn_sum_F48                    NUMBER;
        vn_sum_F50                    NUMBER;
        vn_sum_F52                    NUMBER;
        vn_sum_F81                    NUMBER;
        vn_sum_F94                    NUMBER;
        vn_sum_F60                    NUMBER;
        vn_sum_F99                    NUMBER;
        vv_argos_nature_source_set_id NUMBER;
        vv_argos_account_set_id       NUMBER;
        vn_amount_F99                 NUMBER;


        CURSOR cur_nature (pv_nature VARCHAR2, pv_argos_nature_source_set_id NUMBER)
            IS
            SELECT ffv.flex_value resi_nature,
                   ffvt.description
            FROM   fnd_flex_values ffv,
                   fnd_flex_values_tl ffvt
            WHERE     ffvt.flex_value_id = ffv.flex_value_id
                  AND ffv.flex_value_set_id = pv_argos_nature_source_set_id
                  AND ffv.enabled_flag = 'Y'
                  AND ffv.summary_flag = 'N'
                  AND ffvt.language = USERENV('LANG')
                  AND ffv.flex_value = nvl(pv_nature, ffv.flex_value)
                  AND ffv.flex_value IN (SELECT distinct nature
                                         FROM dka_sglctrlfluxifrs_tmp dst
                                         WHERE request_id = gn_request_id)
            ;

        rec_nature cur_nature%ROWTYPE;

        CURSOR cur_flow_amount (pv_resi_nature VARCHAR2, pv_argos_account_set_id NUMBER)
            IS
            SELECT dst.local_account,
                   dst.group_account,
                   dst.argos_account,
                   ffvt.description,
                   round(sum(decode(dst.line_type,'OPEN_BAL',dst.begin_balance,0))) F00,
                   round(sum(decode(dst.line_type,'MONTH_BAL',decode(dst.flow,'F13',dst.amount,0),0)) - sum(decode(dst.line_type,'OPEN_BAL',decode(dst.flow,'F13',dst.begin_balance,0),0))) F13_amount,
                   round(sum(decode(dst.line_type,'MONTH_BAL',decode(dst.flow,'F17',dst.amount,0),0)) - sum(decode(dst.line_type,'OPEN_BAL',decode(dst.flow,'F17',dst.begin_balance,0),0))) F17_amount,
                   round(sum(decode(dst.line_type,'MONTH_BAL',decode(dst.flow,'F20',dst.amount,0),0)) - sum(decode(dst.line_type,'OPEN_BAL',decode(dst.flow,'F20',dst.begin_balance,0),0))) F20_amount,
                   round(sum(decode(dst.line_type,'MONTH_BAL',decode(dst.flow,'F40',dst.amount,0),0)) - sum(decode(dst.line_type,'OPEN_BAL',decode(dst.flow,'F40',dst.begin_balance,0),0))) F40_amount,
                   round(sum(decode(dst.line_type,'MONTH_BAL',decode(dst.flow,'F25',dst.amount,0),0)) - sum(decode(dst.line_type,'OPEN_BAL',decode(dst.flow,'F25',dst.begin_balance,0),0))) F25_amount,
                   round(sum(decode(dst.line_type,'MONTH_BAL',decode(dst.flow,'F44',dst.amount,0),0)) - sum(decode(dst.line_type,'OPEN_BAL',decode(dst.flow,'F44',dst.begin_balance,0),0))) F44_amount,
                   round(sum(decode(dst.line_type,'MONTH_BAL',decode(dst.flow,'F60',dst.amount,0),0)) - sum(decode(dst.line_type,'OPEN_BAL',decode(dst.flow,'F60',dst.begin_balance,0),0))) F60_amount,
                   round(sum(decode(dst.line_type,'MONTH_BAL',decode(dst.flow,'F48',dst.amount,0),0)) - sum(decode(dst.line_type,'OPEN_BAL',decode(dst.flow,'F48',dst.begin_balance,0),0))) F48_amount,
                   round(sum(decode(dst.line_type,'MONTH_BAL',decode(dst.flow,'F50',dst.amount,0),0)) - sum(decode(dst.line_type,'OPEN_BAL',decode(dst.flow,'F50',dst.begin_balance,0),0))) F50_amount,
                   round(sum(decode(dst.line_type,'MONTH_BAL',decode(dst.flow,'F52',dst.amount,0),0)) - sum(decode(dst.line_type,'OPEN_BAL',decode(dst.flow,'F52',dst.begin_balance,0),0))) F52_amount,
                   round(sum(decode(dst.line_type,'MONTH_BAL',decode(dst.flow,'F81',dst.amount,0),0)) - sum(decode(dst.line_type,'OPEN_BAL',decode(dst.flow,'F81',dst.begin_balance,0),0))) F81_amount,
                   round(sum(decode(dst.line_type,'MONTH_BAL',decode(dst.flow,'F94',dst.amount,0),0)) - sum(decode(dst.line_type,'OPEN_BAL',decode(dst.flow,'F94',dst.begin_balance,0),0))) F94_amount
            FROM   dka_sglctrlfluxifrs_tmp dst,
                   fnd_flex_values ffv,
                   fnd_flex_values_tl ffvt
            WHERE    ffv.flex_value_id = ffvt.flex_value_id
                 AND ffvt.language = USERENV('LANG')
                 AND ffv.flex_value = dst.argos_account
                 AND ffv.flex_value_set_id = pv_argos_account_set_id
                 AND dst.nature = pv_resi_nature
                 AND dst.request_id = gn_request_id
            GROUP BY dst.local_account,
                     dst.group_account,
                     dst.argos_account,
                     ffvt.description
            ;

        rec_flow_amount cur_flow_amount%ROWTYPE;


    BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||  'Begin of procedure extraction_file');

         vv_argos_nature_source_set_id := get_cuf_flex_value_set_id('XARGOS_ACCOUNT','ARGOS_NATURE_SOURCE');
         vv_argos_account_set_id       := get_cuf_flex_value_set_id('XARGOS_ACCOUNT','ARGOS_ACCOUNT_C');

           OPEN cur_nature (pv_nature, vv_argos_nature_source_set_id);

           LOOP
           BEGIN
               FETCH cur_nature INTO rec_nature;
               EXIT WHEN cur_nature%NOTFOUND;

                  BEGIN

                  Fnd_File.put_line (Fnd_File.output,gv_nature||' : '||rec_nature.resi_nature||' '||rec_nature.description||';');
                  Fnd_File.put_line (Fnd_File.output,CHR(10));
                  Fnd_File.put_line (Fnd_File.output,';'||gv_title||';');
                  Fnd_File.put_line (Fnd_File.output,gv_columns);
                  Fnd_File.put_line (Fnd_File.output,';;;;'||gv_description_F00||';'||get_description_flow('F13')||';'||get_description_flow('F17')||';'||get_description_flow('F20')
                                 ||';'||get_description_flow('F40')||';'||get_description_flow('F25')||';'||get_description_flow('F44')||';'||get_description_flow('F48')
                                 ||';'||get_description_flow('F50')||';'||get_description_flow('F52')||';'||get_description_flow('F81')||';'||get_description_flow('F94')
                                 ||';'||get_description_flow('F60')||';'||gv_description_F99||';');


                  -- variables initialisation
                  vn_sum_F00 := 0;
                  vn_sum_F13 := 0;
                  vn_sum_F17 := 0;
                  vn_sum_F20 := 0;
                  vn_sum_F40 := 0;
                  vn_sum_F25 := 0;
                  vn_sum_F44 := 0;
                  vn_sum_F48 := 0;
                  vn_sum_F50 := 0;
                  vn_sum_F52 := 0;
                  vn_sum_F81 := 0;
                  vn_sum_F94 := 0;
                  vn_sum_F60 := 0;
                  vn_sum_F99 := 0;


                  OPEN cur_flow_amount (rec_nature.resi_nature, vv_argos_account_set_id);
                  LOOP
                  BEGIN
                      FETCH cur_flow_amount INTO rec_flow_amount;
                      EXIT WHEN cur_flow_amount%NOTFOUND;

                      BEGIN

                          -- F99 amount determination
                          vn_amount_F99 := rec_flow_amount.F00 + rec_flow_amount.F13_amount + rec_flow_amount.F17_amount +
                                           rec_flow_amount.F20_amount + rec_flow_amount.F40_amount + rec_flow_amount.F25_amount +
                                           rec_flow_amount.F44_amount + rec_flow_amount.F48_amount + rec_flow_amount.F50_amount +
                                           rec_flow_amount.F52_amount + rec_flow_amount.F81_amount + rec_flow_amount.F94_amount +
                                           rec_flow_amount.F60_amount;

                          Fnd_File.put_line (Fnd_File.output,rec_flow_amount.local_account||';'||
                                      rec_flow_amount.group_account||';'||
                                      rec_flow_amount.argos_account||';'||
                                      rec_flow_amount.description||';'||
                                      rec_flow_amount.F00||';'||
                                      rec_flow_amount.F13_amount||';'||
                                      rec_flow_amount.F17_amount||';'||
                                      rec_flow_amount.F20_amount||';'||
                                      rec_flow_amount.F40_amount||';'||
                                      rec_flow_amount.F25_amount||';'||
                                      rec_flow_amount.F44_amount||';'||
                                      rec_flow_amount.F48_amount||';'||
                                      rec_flow_amount.F50_amount||';'||
                                      rec_flow_amount.F52_amount||';'||
                                      rec_flow_amount.F81_amount||';'||
                                      rec_flow_amount.F94_amount||';'||
                                      rec_flow_amount.F60_amount||';'||
                                      vn_amount_F99||';'
                                      );

                           vn_sum_F00 := vn_sum_F00 + rec_flow_amount.F00;
                           vn_sum_F13 := vn_sum_F13 + rec_flow_amount.F13_amount;
                           vn_sum_F17 := vn_sum_F17 + rec_flow_amount.F17_amount;
                           vn_sum_F20 := vn_sum_F20 + rec_flow_amount.F20_amount;
                           vn_sum_F40 := vn_sum_F40 + rec_flow_amount.F40_amount;
                           vn_sum_F25 := vn_sum_F25 + rec_flow_amount.F25_amount;
                           vn_sum_F44 := vn_sum_F44 + rec_flow_amount.F44_amount;
                           vn_sum_F48 := vn_sum_F48 + rec_flow_amount.F48_amount;
                           vn_sum_F50 := vn_sum_F50 + rec_flow_amount.F50_amount;
                           vn_sum_F52 := vn_sum_F52 + rec_flow_amount.F52_amount;
                           vn_sum_F81 := vn_sum_F81 + rec_flow_amount.F81_amount;
                           vn_sum_F94 := vn_sum_F94 + rec_flow_amount.F94_amount;
                           vn_sum_F60 := vn_sum_F60 + rec_flow_amount.F60_amount;
                           vn_sum_F99 := vn_sum_F99 + vn_amount_F99;


                       END;
                  END;
                  END LOOP;
                  CLOSE cur_flow_amount;

                          Fnd_File.put_line (Fnd_File.output,gv_total||';;;;'
                              ||vn_sum_F00||';'
                              ||vn_sum_F13||';'
                              ||vn_sum_F17||';'
                              ||vn_sum_F20||';'
                              ||vn_sum_F40||';'
                              ||vn_sum_F25||';'
                              ||vn_sum_F44||';'
                              ||vn_sum_F48||';'
                              ||vn_sum_F50||';'
                              ||vn_sum_F52||';'
                              ||vn_sum_F81||';'
                              ||vn_sum_F94||';'
                              ||vn_sum_F60||';'
                              ||vn_sum_F99||';'
                              ||CHR(10)||CHR(10));


                  END;

           END;
           END LOOP;

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||  'End of procedure extraction_file');


    EXCEPTION
        WHEN e_fatal_error
        THEN
            ROLLBACK;
            pn_retcode   := 2;
            pv_errbuf    := 'EXTRACTION_FILE - FATAL ERROR : '||pv_errbuf;
        WHEN OTHERS
        THEN
            ROLLBACK;
            pn_retcode   := 2;
            pv_errbuf    := 'EXTRACTION_FILE - EXCEPTION OTHERS : '||substr(SQLERRM,1,450);
    END extraction_file;


----------------------------------------------------------------------------
--  Name          : main
--  Description   : Request main procedure
--
--  PARAMETERS :
--    pv_conso_code         conso code
--    pv_period_name         Name of period
--    pv_errbuf   Input/Output          error message
--
--  RETURN VALUE :
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
----------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf        IN OUT   VARCHAR2,
        pn_retcode       IN OUT   NUMBER,
        pv_conso_code   IN       VARCHAR2,
        pv_period_name   IN       VARCHAR2,
        pv_nature        IN       VARCHAR2
    )
    IS
        vv_errbuf                     VARCHAR2 (500);
        vn_retcode                    NUMBER;
        e_fatal_error                 EXCEPTION;
        vv_period_num                 NUMBER;
        
        
       /* CURSOR cur_ledgers
        IS
        SELECT LEDGER_ID 
        FROM GL_ACCESS_SET_ASSIGNMENTS
        where access_set_id = (fnd_profile.value('GL_ACCESS_SET_ID'));*/--YWA artf2178310 

    
    BEGIN

        -- Parameters initialisation
        vn_retcode := 0;
        vv_errbuf := NULL;


        -----------------------------------------
        -- Variables initialisation            --
        -----------------------------------------

        init (vv_errbuf
            , vn_retcode);

        IF vn_retcode != 0
        THEN
          pv_errbuf := vv_errbuf;
          RAISE e_fatal_error;
        END IF;


        -----------------------------------------
        -- Loading all data in temporary table --
        -----------------------------------------

        --FOR rec_ledgers IN cur_ledgers
        --LOOP
        
            --YWA artf2178310 
            SELECT distinct ledger_id
            INTO gn_set_of_books_id
            FROM gl_ledgers gl,dka_ieoglvec01_conso_code_v conso
            WHERE conso.balancing_seg_value = gl.short_name
            and  conso.conso_code =pv_conso_code;
                        
                        
          --gn_set_of_books_id := rec_ledgers.ledger_id; --YWA artf2178310 
          
          load_dka_sglctrlfluxifrs_tmp (pv_conso_code
                                      , pv_period_name
                                      , vv_errbuf
                                      , vn_retcode);

          IF vn_retcode != 0
          THEN
            pv_errbuf := vv_errbuf;
            RAISE e_fatal_error;
          END IF;
        --END LOOP;--YWA artf2178310 
        -----------------------------------------
        -- Output file                         --
        -----------------------------------------


        extraction_file (pv_nature
                       , vv_errbuf
                       , vn_retcode);

        IF vn_retcode != 0
        THEN
          pv_errbuf := vv_errbuf;
          RAISE e_fatal_error;
        END IF;


        ------------------------------------------
        -- Delete table dka_sglctrlfluxifrs_tmp --
        ------------------------------------------
        delete_dka_sglctrlfluxifrs_tmp (gn_request_id, vv_errbuf, vn_retcode);

        IF vn_retcode = 1
        THEN
            pn_retcode   := 1;
            pv_errbuf    := vv_errbuf;
        ELSIF vn_retcode != 0
        THEN
            pn_retcode   := 2;
            pv_errbuf    := vv_errbuf;
            RAISE e_fatal_error;
        END IF;



        Fnd_File.put_line (Fnd_File.LOG,'******* '||dka_ieoglvec01_pkg.get_message('FND','CONC-CP COMPLETED')||' *******');

    EXCEPTION
        WHEN e_fatal_error
        THEN
            ROLLBACK;
            pn_retcode   := 2;
            pv_errbuf    := 'MAIN - FATAL ERROR : '||pv_errbuf;
        WHEN OTHERS
        THEN
            ROLLBACK;
            pn_retcode   := 2;
            pv_errbuf    := 'MAIN - EXCEPTION OTHERS : '||substr(SQLERRM,1,450);
    END main;



END DKA_SGLCTRLFLUXIFRS_PKG;
/
SHOW ERROR

EXIT
 
