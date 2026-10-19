create or replace PACKAGE BODY DKA_IEOGLVEC01_PKG
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJECT          : DALKIA Oracle Applications
-- NAME             : DKA_IEOGLVEC01_PKG.pkb
-- DESCRIPTION      : Package body VECTOR consolidation
-- AUTHOR           : CDEL (CG)
-- CREATION DATE    : 19/10/2006
-- COMMENTS         : Execute on SQLPLUS with user APPS
--------------------------------------------------------------------------------------------
-- MODIFICATION HISTORY
-- Date       Who Description
-- ---------- --- -------------------------------------------------------------------------
-- 14/12/06   CDE Function get_cuf_attribute_num : fdfcu.form_above_prompt => fdfcu.end_user_column_name
--                Option de profil VECTOR_SEUIL_INTRAGROUPE => VECTOR_INTERCO_THRESHOLD
-- 07/03/07   CDE Recalculation of vv_amount_limit variable Update procedure Launch_request
--                      and procedure control_period_name
--                Procedure update_dka_ieoglvec01_int : New determination of accnt field
--                Add function get_gl_period_end_date
-- 26/03/07   CDE Procedure update_dka_ieoglvec01_int : update determination accnt field
--                group by tmp_seg_argos_account, tmp_seg_local_account and partner
-- 28/03/07   CDE Procedure update_dka_ieoglvec01_int : Add flexfield INTERCO_ACTIVATED
--                in accnt and partner field determination
-- 03/05/07   CDE Dependent segment managing for UK : Add functions get_qual_value_set_val_type,
--                get_qual_flex_value_set_parent, get_cuf_attribute_value_dep
--                update procedures update_dka_ieoglvec01_int and control
-- 28/05/07   CDE Evolution Uoisation : Add function get_partner_code to calculate partner according to
--                SEGMENTED_CONSO_INTERCO value and Update procedure update_dka_ieoglvec01_int and control
-- 14/09/2007  SL Procedure control : Add controls for the new qualifier XARGOS_FLOW
--                Add attribute_exists_desc_flex
-- 19/10/2007  SL Add prodecure delete_dka_iglbudvec01_int, insert_dka_iglbudvec01_int, update_dka_iglbudvec01_int
--                launch_request_bud, main_budget for budget
--                Modify procedure control add controls for the setup of budget
--		            FORECAST AND MB (monthly)
-- 15/11/2007  SL Param for file generation
-- 16/11/2007  SL optimization in insert_dka_ieoglvec01_int et insert_dka_iglbudvec01_int
-- 04/01/2008 EMA Addition of the management of the XARGOS_FLOW qualifier
-- 04/03/09    SL insert_dka_ieoglvec01_int - changes the way to get the balance for some flows
--                (other than F99). The balance of the exercice until the period (paramater)
--                 is got insstead of the balance from the begin.
-- 20/04/09    SL get_partner_code - Determinate the partner code when the area doesn't
--                belong to the company (according to SEGMENTED_CONSO_INTERCO value)
-- 29/06/2009  SL insert_dka_ieoglvec01_int - Correct the way to get the balance for the flows
-- 23/11/2016  PBR  Migration R12.
-- 19/06/2017  RBE artf2177043 : GL Etat consolidation VECTOR en erreur defect BeB #760 et Oracle_R12 #630
-- 05/07/2017  OBE artf2123666 : INT039 : Etat de synthèse
--------------------------------------------------------------------------------------------

gv_num_version_seg_name VARCHAR2(30) := 'NUM_VERSION';
gn_num_version          VARCHAR2(30)                 ;

-----------------------------------------------------------------
--  Nom           : GET_MESSAGE
--  Description   : Function to find messages in fnd_new_messages
--
--  PARAMETERS :
--      pv_application           Input      Application code
--      pv_name                  Input      Message name
--      pv_tokenx                Input      Parameter names in message
--      pv_valuex                Input      Parameter values in message
--
--  RETURN VALUE :
--     Description       : Message
-----------------------------------------------------------------
    FUNCTION get_message (
        pv_application   IN   VARCHAR2,
        pv_name          IN   VARCHAR2,
        pv_token1        IN   VARCHAR2 DEFAULT NULL,
        pv_value1        IN   VARCHAR2 DEFAULT NULL,
        pv_token2        IN   VARCHAR2 DEFAULT NULL,
        pv_value2        IN   VARCHAR2 DEFAULT NULL,
        pv_token3        IN   VARCHAR2 DEFAULT NULL,
        pv_value3        IN   VARCHAR2 DEFAULT NULL,
        pv_token4        IN   VARCHAR2 DEFAULT NULL,
        pv_value4        IN   VARCHAR2 DEFAULT NULL,
        pv_token5        IN   VARCHAR2 DEFAULT NULL,
        pv_value5        IN   VARCHAR2 DEFAULT NULL,
        pv_token6        IN   VARCHAR2 DEFAULT NULL,
        pv_value6        IN   VARCHAR2 DEFAULT NULL,
        pv_token7        IN   VARCHAR2 DEFAULT NULL,
        pv_value7        IN   VARCHAR2 DEFAULT NULL,
        pv_token8        IN   VARCHAR2 DEFAULT NULL,
        pv_value8        IN   VARCHAR2 DEFAULT NULL,
        pv_token9        IN   VARCHAR2 DEFAULT NULL,
        pv_value9        IN   VARCHAR2 DEFAULT NULL,
        pv_token10       IN   VARCHAR2 DEFAULT NULL,
        pv_value10       IN   VARCHAR2 DEFAULT NULL
    )
        RETURN VARCHAR2
    IS
        manque_param   EXCEPTION;
    BEGIN
        IF    LENGTH (LTRIM (pv_application)) = 0
           OR LENGTH (LTRIM (pv_name)) = 0
        THEN
            RAISE manque_param;
        END IF;

        -- Find message
        Fnd_Message.set_name (pv_application, pv_name);

        -- Find Tokens
        IF pv_token1 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token1, pv_value1);
        END IF;

        IF pv_token2 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token2, pv_value2);
        END IF;

        IF pv_token3 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token3, pv_value3);
        END IF;

        IF pv_token4 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token4, pv_value4);
        END IF;

        IF pv_token5 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token5, pv_value5);
        END IF;

        IF pv_token6 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token6, pv_value6);
        END IF;

        IF pv_token7 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token7, pv_value7);
        END IF;

        IF pv_token8 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token8, pv_value8);
        END IF;

        IF pv_token9 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token9, pv_value9);
        END IF;

        IF pv_token10 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token10, pv_value10);
        END IF;

        RETURN (Fnd_Message.get);
    EXCEPTION
        WHEN manque_param
        THEN
            RETURN ('ERROR : Missing parameter');
        WHEN OTHERS
        THEN
            RETURN ('ERROR : '|| SQLCODE || ' : ' || SQLERRM (SQLCODE));
    END get_message;


-----------------------------------------------------------------
--  Name          : PUT_OUT_HEADER
--  Description   : Output file Header Initialisation
--
--  PARAMETERS :
--     N/A
--
--  RETURN VALUE :
--     N/A
-----------------------------------------------------------------
    PROCEDURE put_out_header
    IS
        cv_line                     VARCHAR2 (100);
        vv_conc_program_name        fnd_concurrent_programs.concurrent_program_name%TYPE;
        vv_user_conc_program_name   fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
    BEGIN
        cv_line    := '+-------------------------------------------------------------------------+';
        Fnd_File.put_line (Fnd_File.output, cv_line);
        Fnd_File.put_line (Fnd_File.output, '');
        Fnd_File.put_line (Fnd_File.output, Fnd_Global.application_name);
        Fnd_File.put_line (Fnd_File.output, '');

        ----- Find concurrent program information -----
        BEGIN
            SELECT fcp.concurrent_program_name,
                   fcpt.user_concurrent_program_name
            INTO   vv_conc_program_name,
                   vv_user_conc_program_name
            FROM   fnd_concurrent_programs fcp,
                   fnd_concurrent_programs_tl fcpt
            WHERE      fcp.application_id = Fnd_Global.prog_appl_id
                   AND fcp.concurrent_program_id = Fnd_Global.conc_program_id
                   AND fcpt.application_id = Fnd_Global.prog_appl_id
                   AND fcpt.concurrent_program_id = Fnd_Global.conc_program_id
                   AND fcpt.LANGUAGE = Fnd_Global.current_language;
        EXCEPTION
            WHEN OTHERS
            THEN
                vv_user_conc_program_name    := '???????????????????????';
                vv_conc_program_name         := '???????';
        END;

        Fnd_File.put_line (Fnd_File.output, get_message(get_application_short_name(Fnd_Global.prog_appl_id),'DKA_IEOGLVEC01_PROG_NAME')||' : ' || vv_user_conc_program_name);
        Fnd_File.put_line (Fnd_File.output, get_message('FND','ML_CODE')||' : ' || vv_conc_program_name);
        Fnd_File.put_line (Fnd_File.output, cv_line);
        Fnd_File.put_line (Fnd_File.output, '');
        Fnd_File.put_line (Fnd_File.output, get_message('FND','UTIL-CURRENT TIME','DATE',SYSDATE,'TIME',to_char(SYSDATE,'HH24:MI:SS')));
        Fnd_File.put_line (Fnd_File.output, '');
        Fnd_File.put_line (Fnd_File.output, cv_line);
        Fnd_File.put_line (Fnd_File.output, '');
    END put_out_header;


-----------------------------------------------------------------
--  Name          : GET_INSTANCE_NAME
--  Description   : Function to find the name of gl_set_of_books
--
--  PARAMETERS :
--     pn_gl_set_of_bks_id      gl_set_of_books_id
--
--  RETURN VALUE :
--     vv_instance_name      :  Instance name
-----------------------------------------------------------------
    FUNCTION get_instance_name (
        pn_gl_set_of_bks_id   IN   NUMBER
    )
        RETURN VARCHAR2
    IS
        vv_instance_name               VARCHAR2 (30);
    BEGIN
        -- Initialisation
        vv_instance_name := NULL;

        -- Segment number link to qualifier name
        SELECT gsob.name
        INTO   vv_instance_name
        FROM   gl_ledgers gsob
        WHERE  gsob.ledger_id = pn_gl_set_of_bks_id;

        ----- return value -----
        RETURN (vv_instance_name);
    END get_instance_name;


-----------------------------------------------------------------
--  Name          : GET_APPLICATION_SHORT_NAME
--  Description   : Function to find the application short name of program request
--
--  PARAMETERS :
--     pn_appli_id      application_id
--
--  RETURN VALUE :
--     gv_application_short_name      :  application short name
-----------------------------------------------------------------
    FUNCTION get_application_short_name (
        pn_appli_id   IN   NUMBER
    )
        RETURN VARCHAR2
    IS
        vv_application_short_name       VARCHAR2 (10);
    BEGIN
        -- Initialisation
        vv_application_short_name := NULL;

        -- Segment number link to qualifier name
        SELECT fa.application_short_name
        INTO   vv_application_short_name
        FROM   fnd_application fa
        WHERE  fa.application_id = pn_appli_id;

        ----- return value -----
        RETURN (vv_application_short_name);
    END get_application_short_name;


-----------------------------------------------------------------
--  Name          : GET_SEGMENT_NUM
--  Description   : Function to find the segment number of the accounting flexfield link to a qualifier
--                  in parameter
--
--  PARAMETERS :
--     pv_qualifier      qualifier code
--
--  RETURN VALUE :
--     segment_num       :  Key segment number
-----------------------------------------------------------------
    FUNCTION get_segment_num (
        pv_qualifier   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_segment_num               VARCHAR2 (10);
    BEGIN
        -- Initialisation
        vv_segment_num := NULL;

        -- Segment number link to qualifier name
        BEGIN
        SELECT distinct fsav.application_column_name
        INTO   vv_segment_num
        FROM   fnd_segment_attribute_values fsav,
               gl_ledgers gsob
        WHERE  fsav.id_flex_num = gsob.chart_of_accounts_id
          AND  gsob.ledger_id IN (SELECT LEDGER_ID FROM gl_access_set_assignments where access_set_id = FND_PROFILE.value('GL_ACCESS_SET_ID'))
          AND  fsav.id_flex_code = 'GL#'
          AND  fsav.attribute_value = 'Y'
          AND  fsav.segment_attribute_type = pv_qualifier;
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            vv_segment_num := NULL;
        END;

        ----- return value -----
        RETURN (vv_segment_num);
    END get_segment_num;


-----------------------------------------------------------------
--  Name           : GET_QUAL_FLEX_VALUE_SET_ID
--  Description    : Function to find flex_value_set_id link to qualifier in parameter
--
--
--  PARAMETERS :
--     pv_qualifier      qualifier code
--
--  RETURN VALUE :
--     vn_flex_value_set_id       :  value set id
-----------------------------------------------------------------
    FUNCTION get_qual_flex_value_set_id (
        pv_qualifier   IN   VARCHAR2
    )
        RETURN NUMBER
    IS
        vn_flex_value_set_id       NUMBER;
    BEGIN
        -- Initialisation
        vn_flex_value_set_id := NULL;

        -- value set id link to qualifier
        BEGIN
        SELECT fifs.flex_value_set_id
        INTO   vn_flex_value_set_id
        FROM   fnd_segment_attribute_values fsav,
               fnd_id_flex_segments fifs,
               gl_ledgers gsob
        WHERE  fsav.id_flex_num = gsob.chart_of_accounts_id
          AND  fifs.id_flex_num = gsob.chart_of_accounts_id
          AND  gsob.ledger_id IN (SELECT LEDGER_ID 
                                  FROM gl_access_set_assignments 
                                  WHERE access_set_id = FND_PROFILE.value('GL_ACCESS_SET_ID') 
                                  and rownum = 1)
          AND  fifs.id_flex_code = fsav.id_flex_code
          AND  fsav.id_flex_code = 'GL#'
          AND  fsav.attribute_value = 'Y'
          AND  fifs.application_column_name = fsav.application_column_name
          AND  fsav.segment_attribute_type = pv_qualifier;
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            vn_flex_value_set_id := NULL;
        END;

        ----- return value -----
        RETURN (vn_flex_value_set_id);
    END get_qual_flex_value_set_id;

-----------------------------------------------------------------
--  Name           : GET_QUAL_FLEX_VALUE_SET_NAME
--  Description    : Function to find flex_value_set_name link to qualifier in parameter
--
--
--  PARAMETERS :
--     pv_qualifier      qualifier code
--
--  RETURN VALUE :
--     vn_flex_value_set_name      :  value set name
-----------------------------------------------------------------
    FUNCTION get_qual_flex_value_set_name (
        pv_qualifier   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vn_flex_value_set_name       VARCHAR2(60);
    BEGIN
        -- Initialisation
        vn_flex_value_set_name := NULL;

        -- value set name link to qualifier
        BEGIN
        SELECT flex_value_set_name
        INTO   vn_flex_value_set_name
        FROM   fnd_flex_value_sets ffvs
        WHERE  ffvs.flex_value_set_id = get_qual_flex_value_set_id(pv_qualifier);
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            vn_flex_value_set_name := NULL;
        END;

        ----- return value -----
        RETURN (vn_flex_value_set_name);
    END get_qual_flex_value_set_name;


-----------------------------------------------------------------
--  Name           : GET_QUAL_VALUE_SET_VAL_TYPE
--  Description    : Function to find validation type of the flex value set
--                   link to qualifier in parameter
--
--
--  PARAMETERS :
--     pv_qualifier      qualifier code
--
--  RETURN VALUE :
--     vv_validation_type      :  validation type of the flex value set (D or I)
-----------------------------------------------------------------
    FUNCTION get_qual_value_set_val_type (
        pv_qualifier   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_validation_type       VARCHAR2(1);
    BEGIN
        -- Initialisation
        vv_validation_type := NULL;

        -- validation type of the value set link to qualifier
        BEGIN
        SELECT validation_type
        INTO   vv_validation_type
        FROM   fnd_flex_value_sets ffvs
        WHERE  ffvs.flex_value_set_id = get_qual_flex_value_set_id(pv_qualifier);
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            vv_validation_type := NULL;
        END;

        ----- return value -----
        RETURN (vv_validation_type);
    END get_qual_value_set_val_type;

-----------------------------------------------------------------
--  Name           : GET_QUAL_FLEX_VALUE_SET_PARENT
--  Description    : Function to find parent flex set of the flex value set
--                   link to qualifier in parameter
--
--
--  PARAMETERS :
--     pv_qualifier      qualifier code
--
--  RETURN VALUE :
--     vn_parent_flex_value_set_id      :  parent of the flex value set dependent
-----------------------------------------------------------------
    FUNCTION get_qual_flex_value_set_parent (
        pv_qualifier   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vn_parent_flex_value_set_id       NUMBER;
    BEGIN
        -- Initialisation
        vn_parent_flex_value_set_id := NULL;

        -- validation type of the value set link to qualifier
        BEGIN
        SELECT parent_flex_value_set_id
        INTO   vn_parent_flex_value_set_id
        FROM   fnd_flex_value_sets ffvs
        WHERE  ffvs.flex_value_set_id = get_qual_flex_value_set_id(pv_qualifier);
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            vn_parent_flex_value_set_id := NULL;
        END;

        ----- return value -----
        RETURN (vn_parent_flex_value_set_id);
    END get_qual_flex_value_set_parent;

-----------------------------------------------------------------
--  Name          : GET_CUF_ATTRIBUTE_NUM
--  Description   : Function to find attribute number of descriptive flexfield link to a qualifier
--                  in parameter
--
--  PARAMETERS :
--     pv_qualifier           qualifier code
--     pv_code_attribute      attribute code
--
--  RETURN VALUE :
--     attribute_num       :  attribute number in CUF
-----------------------------------------------------------------
    FUNCTION get_cuf_attribute_num (
        pv_qualifier        IN   VARCHAR2,
        pv_code_attribute   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_attribute_num             VARCHAR2(12);
    BEGIN
        -- Initialisation
        vv_attribute_num := NULL;

        -- attribute number link to attribute code and qualifier
        BEGIN
        SELECT DISTINCT fdfcu.application_column_name
        INTO   vv_attribute_num
        FROM   fnd_segment_attribute_values fsav,
               gl_ledgers gsob,
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
          AND  gsob.ledger_id IN (SELECT LEDGER_ID FROM gl_access_set_assignments where access_set_id = FND_PROFILE.value('GL_ACCESS_SET_ID'))
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
            vv_attribute_num := NULL;
        END;


        ----- return value -----
        RETURN (vv_attribute_num);
    END get_cuf_attribute_num;


-----------------------------------------------------------------
--  Name          : GET_CUF_ATTRIBUTE_VALUE
--  Description   : Function to find attribute value of descriptive flexfield link to segment in parameter
--
--
--  PARAMETERS :
--     pv_qualifier           qualifier code
--     pv_flex_value          flex value
--     pv_code_attribute      attribute code
--
--  RETURN VALUE :
--     attribute_value       :  value of the attribute
-----------------------------------------------------------------
    FUNCTION get_cuf_attribute_value (
        pv_qualifier        IN   VARCHAR2,
        pv_flex_value       IN   VARCHAR2,
        pv_code_attribute   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_attribute_value             VARCHAR2(20);
        sql_req                        VARCHAR2(500);
        vv_attribute_number            VARCHAR2(12);
        vn_flex_value_set_id           NUMBER;
    BEGIN
        -- Initialisation
        vv_attribute_value := NULL;
        vv_attribute_number := get_cuf_attribute_num(pv_qualifier, pv_code_attribute);
        vn_flex_value_set_id := get_qual_flex_value_set_id(pv_qualifier);

        --
        IF vv_attribute_number IS NOT NULL
        THEN
        sql_req := 'SELECT '||vv_attribute_number||
                   ' FROM fnd_flex_values '||
                   'WHERE flex_value_set_id = :vn_flex_value_set_id'||
                   '  AND flex_value = :pv_flex_value';

        EXECUTE IMMEDIATE sql_req INTO vv_attribute_value USING vn_flex_value_set_id, pv_flex_value;

        ELSE
            vv_attribute_value := NULL;
        END IF;


        ----- return number -----
        RETURN (vv_attribute_value);
    END get_cuf_attribute_value;


-----------------------------------------------------------------
--  Name          : GET_CUF_ATTRIBUTE_VALUE_DEP
--  Description   : Function to find attribute value of descriptive flexfield link to segment in parameter
--                   and segment parent in parameter
--
--  PARAMETERS :
--     pv_qualifier           qualifier code
--     pv_flex_value          flex value
--     pv_parent_flex_value   parent flex value
--     pv_code_attribute      attribute code
--
--  RETURN VALUE :
--     attribute_value       :  value of the attribute
-----------------------------------------------------------------
    FUNCTION get_cuf_attribute_value_dep (
        pv_qualifier         IN   VARCHAR2,
        pv_flex_value        IN   VARCHAR2,
        pv_parent_flex_value IN   VARCHAR2,
        pv_code_attribute    IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_attribute_value             VARCHAR2(20);
        sql_req                        VARCHAR2(500);
        vv_attribute_number            VARCHAR2(12);
        vn_flex_value_set_id           NUMBER;
    BEGIN
        -- Initialisation
        vv_attribute_value := NULL;
        vv_attribute_number := get_cuf_attribute_num(pv_qualifier, pv_code_attribute);
        vn_flex_value_set_id := get_qual_flex_value_set_id(pv_qualifier);

        --
        IF vv_attribute_number IS NOT NULL
        THEN
        sql_req := 'SELECT '||vv_attribute_number||
                   ' FROM fnd_flex_values '||
                   'WHERE flex_value_set_id = :vn_flex_value_set_id'||
                   '  AND flex_value = :pv_flex_value'||
                   '  AND parent_flex_value_low = :pv_parent_flex_value';

        EXECUTE IMMEDIATE sql_req INTO vv_attribute_value USING vn_flex_value_set_id, pv_flex_value, pv_parent_flex_value;

        ELSE
            vv_attribute_value := NULL;
        END IF;


        ----- return number -----
        RETURN (vv_attribute_value);
    END get_cuf_attribute_value_dep;



-----------------------------------------------------------------
--  Name          : get_conso_code
--  Description   : Function to find CONSO code link to a balancing segment value
--
--
--  PARAMETERS :
--     pv_flex_value          flex value
--     pv_op_unit             operating unit value
--
--  RETURN VALUE :
--     attribute_value       :  value of the attribute
-----------------------------------------------------------------
    FUNCTION get_conso_code (
        pv_flex_value       IN   VARCHAR2,
        pv_op_unit         IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_attribute_value             VARCHAR2(20);

    BEGIN
        -- Initialisation      
        IF pv_op_unit IS NULL
        THEN
           vv_attribute_value := get_cuf_attribute_value('GL_BALANCING', pv_flex_value, 'MAGNITUDE_CODE');
        ELSIF get_cuf_attribute_value('GL_BALANCING', pv_flex_value, 'MAGNITUDE_CODE') = '0'
           THEN
             vv_attribute_value := get_cuf_attribute_value('GL_BALANCING', pv_flex_value, pv_op_unit);
           ELSE
             vv_attribute_value := get_cuf_attribute_value('GL_BALANCING', pv_flex_value, 'MAGNITUDE_CODE');

        END IF;

        ----- return number -----
        RETURN (vv_attribute_value);
    END get_conso_code;


-----------------------------------------------------------------
--  Name          : GET_PARTNER_CODE
--  Description   : Function to find partner code link to a partner segment value
--
--
--  PARAMETERS :
--     pv_flex_value          flex value
--     pv_op_unit             operating unit value
--
--  RETURN VALUE :
--     attribute_value       :  value of the attribute
-----------------------------------------------------------------
    FUNCTION get_partner_code (
        pv_seg_partner       IN   VARCHAR2,
        pv_op_unit           IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_attribute_value             VARCHAR2(20);
        vv_segmented_value             VARCHAR2(1);

    BEGIN
        -- Initialisation         
        vv_segmented_value := get_cuf_attribute_value('XARGOS_INTERCO', pv_seg_partner, 'SEGMENTED_MAGNITUDE_INTERCO');
        
        IF SUBSTR(pv_seg_partner, 1, 3) = 'XXX' THEN --RG14  PBR
          IF vv_segmented_value = 'Y'
          THEN
               vv_attribute_value := get_conso_code(SUBSTR(pv_seg_partner, 4, 4), pv_op_unit); --SUBSTR R12
          ELSE
             vv_attribute_value := get_cuf_attribute_value('XARGOS_INTERCO', pv_seg_partner, 'MAGNITUDE_INTERCO');
          END IF;
        ELSE
          vv_attribute_value := get_cuf_attribute_value('XARGOS_INTERCO', pv_seg_partner, 'MAGNITUDE_INTERCO');
        END IF;

        -- SL 17/04/2009
        IF vv_attribute_value is null THEN
           vv_attribute_value := get_cuf_attribute_value('XARGOS_INTERCO', pv_seg_partner, 'MAGNITUDE_INTERCO');
        END IF;


        ----- return number -----
        RETURN (vv_attribute_value);
    END get_partner_code;


-----------------------------------------------------------------
--  Name          : QUALIFIER_EXISTS
--  Description   : Function to find if a qualifier is setup
--
--  PARAMETERS :
--     pv_qualifier      qualifier code
--
--  RETURN VALUE :
--     vv_exists       :  OK/KO
-----------------------------------------------------------------
    FUNCTION qualifier_exists (
        pv_qualifier   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_exists               VARCHAR2 (2);
    BEGIN
        -- Initialisation
        vv_exists := NULL;

        -- Find if this qualifier exists
        BEGIN
        SELECT 'OK'
        INTO   vv_exists
        FROM   fnd_segment_attribute_types fsat
        WHERE  fsat.id_flex_code = 'GL#'
          AND  fsat.segment_attribute_type = pv_qualifier;

        EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
               vv_exists := 'KO';
        END;

        ----- return value -----
        RETURN (vv_exists);
    END qualifier_exists;

-----------------------------------------------------------------
--  Name          : flex_value_set_name_exists
--  Description   : Function to find if a flex value set is setup
--
--  PARAMETERS :
--     pv_qualifier      flex value set code
--
--  RETURN VALUE :
--     vv_exists       :  OK/KO
-----------------------------------------------------------------
    FUNCTION flex_value_set_name_exists (
        flex_value_set_name   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_exists               VARCHAR2 (2);
    BEGIN
        -- Initialisation
        vv_exists := NULL;

        -- Find if this qualifier exists
        BEGIN
        SELECT distinct
               'OK'
        INTO   vv_exists
        FROM   FND_FLEX_VALUE_SETS FFVS
        where  FFVS.FLEX_VALUE_SET_NAME = flex_value_set_name;

        EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
               vv_exists := 'KO';
        END;

        ----- return value -----
        RETURN (vv_exists);
    END flex_value_set_name_exists;


-----------------------------------------------------------------
--  Name          : ATTRIBUTE_EXISTS
--  Description   : Function to find if an attribute of descriptive flexfield is setup for attribute code in parameter
--
--  PARAMETERS :
--     pv_qualifier      qualifier code
--     pv_code_attribute attribute code
--
--  RETURN VALUE :
--     vv_exists       :  OK/KO
-----------------------------------------------------------------
    FUNCTION attribute_exists (
        pv_qualifier        IN   VARCHAR2,
        pv_code_attribute   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_exists               VARCHAR2 (2);
    BEGIN
        -- Initialisation
        vv_exists := NULL;

        -- Find if this attribute exists
        SELECT decode(get_cuf_attribute_num(pv_qualifier, pv_code_attribute),NULL,'KO','OK')
        INTO   vv_exists
        FROM   dual;

        ----- return value -----
        RETURN (vv_exists);
    END attribute_exists;


-----------------------------------------------------------------
--  Name          : ATTRIBUTE_EXISTS_DESC_FLEX
--  Description   : Function to find if an attribute of descriptive flexfield is setup for attribute code in parameter
--
--  PARAMETERS :
--     pv_qualifier      qualifier code
--     pv_code_attribute attribute code
--
--  RETURN VALUE :
--     vv_exists       :  OK/KO
-----------------------------------------------------------------
    FUNCTION attribute_exists_desc_flex (
        pv_desc_flex_name   IN   VARCHAR2,
        pv_code_attribute   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_exists               VARCHAR2 (2);
        nb_row                  NUMBER;
    BEGIN
        -- Initialisation
        vv_exists := NULL;

        -- Find if this attribute exists
       Select count(*)
       Into   nb_row
       from   fnd_descriptive_flexs f,
              fnd_descr_flex_column_usages fd
       where  1 = 1
       and    f.descriptive_flexfield_name = pv_desc_flex_name
       and    fd.descriptive_flexfield_name = f.descriptive_flexfield_name
       and    fd.end_user_column_name = pv_code_attribute ;

       IF nb_row = 0   THEN
          vv_exists := 'KO';
       ELSE
          vv_exists := 'OK';
       END IF;


        ----- return value -----
        RETURN (vv_exists);
    END attribute_exists_desc_flex;


-----------------------------------------------------------------
--  Name          : PROFILE_OPTION_EXISTS
--  Description   : Function to find if an profile option is setup and with a value
--
--  PARAMETERS :
--     pv_profile_option      profile option code
--
--  RETURN VALUE :
--     vv_exists       :  OK/KO
-----------------------------------------------------------------
    FUNCTION profile_option_exists (
        pv_profile_option        IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_exists               VARCHAR2 (2);
    BEGIN
        -- Initialisation
        vv_exists := NULL;

        -- Find if this profile option exists
        BEGIN
        SELECT 'OK'
        INTO   vv_exists
        FROM   fnd_profile_options
        WHERE     TRUNC(SYSDATE) BETWEEN nvl(start_date_active, TRUNC(SYSDATE)) AND nvl(end_date_active, TRUNC(SYSDATE))
              AND profile_option_name = pv_profile_option;
        EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
               vv_exists := 'KO';
        END;

        IF vv_exists = 'OK'
        THEN
            SELECT decode(Fnd_Profile.VALUE (pv_profile_option), NULL, 'KO','OK')
            INTO   vv_exists
            FROM   dual;
        END IF;

        ----- return value -----
        RETURN (vv_exists);
    END profile_option_exists;

-----------------------------------------------------------------
--  Name          : CONTROL_PERIOD_NAME
--  Description   : Control period name in parameter is an existing GL period
--
--
--  PARAMETERS :
--  pv_period_name                    Name of period
--  pv_errbuf   Input/Output          Error message
--
--  RETURN VALUE :
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
-----------------------------------------------------------------
    PROCEDURE control_period_name (
        pv_period_name    IN       VARCHAR2,
        pv_period_num     OUT      NUMBER,
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    )
    IS
    vv_period_name  gl_period_statuses.period_name%TYPE;

    BEGIN

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Begin of procedure control_period_name');

    SELECT period_name
          ,period_num
    INTO   vv_period_name
          ,pv_period_num
    FROM   gl_period_statuses gps,
           fnd_application fa
    WHERE     gps.application_id = fa.application_id
          AND gps.set_of_books_id       IN (SELECT LEDGER_ID FROM gl_access_set_assignments where access_set_id = FND_PROFILE.value('GL_ACCESS_SET_ID'))--GN_LEDGER_ID--Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID') R12 --RBE artf2177043
          AND fa.application_short_name = 'SQLGL'
          AND gps.period_name           = pv_period_name
          AND rownum = 1;

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||  'End of procedure control_period_name');

    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            pn_retcode    := 2;
            pv_errbuf     := SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG,pv_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure control_period_name : EXCEPTION NO_DATA_FOUND ');
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG,pv_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure control_period_name : EXCEPTION OTHERS ');
    END control_period_name;


-----------------------------------------------------------------
--  Name          : GET_GL_PERIOD_END_DATE
--  Description   : Function to return end_date of a gl period
--
--  PARAMETERS :
--     pv_period_name      period name
--
--  RETURN VALUE :
--     vv_end_date       :  date
-----------------------------------------------------------------
    FUNCTION get_gl_period_end_date (
        pv_period_name        IN   VARCHAR2
    )
        RETURN DATE
    IS
        vv_end_date              DATE;
    BEGIN
        -- Initialisation
        vv_end_date := NULL;

        -- Find if this profile option exists
        BEGIN
            SELECT end_date
            INTO   vv_end_date
            FROM   gl_period_statuses gps,
                   fnd_application fa
            WHERE     gps.application_id = fa.application_id
                  AND gps.set_of_books_id       = Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID')
                  AND fa.application_short_name = 'SQLGL'
                  AND gps.period_name           = pv_period_name;
        EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
               vv_end_date := NULL;
        END;

        ----- return value -----
        RETURN (vv_end_date);
    END get_gl_period_end_date;

-----------------------------------------------------------------
--  Name          : DELETE_DKA_IEOGLVEC01_INT
--  Description   : delete data in temporary table DKA_IEOGLVEC01_INT
--
--
--  PARAMETERS :
--  pn_request_id     Input           Request_Id
--  pv_errbuf   Input/Output          Error message
--
--  RETURN VALUE :
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
-----------------------------------------------------------------
    PROCEDURE delete_dka_ieoglvec01_int (
        pn_request_id     IN       NUMBER,
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    )
    IS


    BEGIN
    pn_retcode := 0;

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Begin of procedure delete_dka_ieoglvec01_int');

    DELETE dka_ieoglvec01_int
    WHERE  request_id = pn_request_id;

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Rows deleted : ' || TO_CHAR (SQL%ROWCOUNT));
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure delete_dka_ieoglvec01_int');

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || pv_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure delete_dka_ieoglvec01_int : EXCEPTION OTHERS ');
    END delete_dka_ieoglvec01_int;

-----------------------------------------------------------------
--  Name          : INSERT_DKA_IEOGLVEC01_INT
--  Description   : Insert data in temporary table DKA_IEOGLVEC01_INT
--
--
--  PARAMETERS :
--     pv_period_name         period name
--     pv_company_code        company code
--     pv_op_unit             operating unit
--     pv_conso_code         CONSO code
--     pv_errbuf      Input/Output          Error message
--
--  RETURN VALUE :
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
-----------------------------------------------------------------
    PROCEDURE insert_dka_ieoglvec01_int (
        pv_period_name    IN       VARCHAR2,
        pv_company_code   IN       VARCHAR2,
        pv_op_unit        IN       VARCHAR2,
        pv_conso_code    IN       VARCHAR2,
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    )
    IS
        sql_req                          VARCHAR2(4000);
        vv_seg_local_num                 VARCHAR2(12);
        vv_seg_argos_account_num         VARCHAR2(12);
        vv_seg_partner_num               VARCHAR2(12);
        vv_seg_op_unit_num               VARCHAR2(12);
        vv_seg_gl_balancing_num          VARCHAR2(12);
        vv_seg_flow_num                  VARCHAR2(12);  -- 04/01/2008
        vv_att_argos_excluded            VARCHAR2(12);
        vv_att_argos_interface           VARCHAR2(12);  -- 04/01/2008
        vn_set_of_books_id               NUMBER;
        vv_flex_val_set_name_argos       VARCHAR2(60); --16/11/2007
        vv_flex_val_set_name_flow        VARCHAR2(60);  -- 04/01/2008

    BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||  'Begin of procedure insert_dka_ieoglvec01_int');

        vv_seg_gl_balancing_num := get_segment_num('GL_BALANCING');
        vv_seg_local_num := get_segment_num('GL_ACCOUNT');
        vv_seg_argos_account_num := get_segment_num('XARGOS_ACCOUNT');
        vv_seg_partner_num := get_segment_num('XARGOS_INTERCO');
        vv_seg_op_unit_num := get_segment_num('XARGOS_OPERATING_UNIT');
        vv_seg_flow_num    := get_segment_num('XARGOS_FLOW');  -- 04/01/2008
        vv_att_argos_excluded := get_cuf_attribute_num('XARGOS_ACCOUNT','ARGOS_EXCLUDED');
        vv_att_argos_interface := get_cuf_attribute_num('XARGOS_FLOW', 'ARGOS_INTERFACE');  -- 04/01/2008


        vn_set_of_books_id := GN_LEDGER_ID;--Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID'); --R12 prise en compte du MOAC.


        vv_flex_val_set_name_argos := dka_ieoglvec01_pkg.get_qual_flex_value_set_name('XARGOS_ACCOUNT'); --16/11/2007
        vv_flex_val_set_name_flow  := dka_ieoglvec01_pkg.get_qual_flex_value_set_name('XARGOS_FLOW');  -- 04/01/2008

        -- Insert data only if qualifier are setuped
        IF (vv_seg_gl_balancing_num IS NOT NULL
            AND vv_seg_local_num IS NOT NULL
            AND vv_seg_argos_account_num IS NOT NULL
            AND vv_seg_partner_num IS NOT NULL
            AND vv_att_argos_excluded IS NOT NULL
            AND vv_flex_val_set_name_argos IS NOT NULL --16/11/2007
            )

        THEN

            IF pv_op_unit IS NULL
            THEN

            -- If no operating unit
            Fnd_File.put_line (Fnd_File.LOG, 'OPERATING UNIT IS NULL : ' || pv_op_unit);
            sql_req := 'INSERT INTO dka_ieoglvec01_int '||
                                   '(request_id,'||
                                   'date_extraction,'||
                                   'period_name,'||
                                   'company_code,'||
                                   'entity,'||
                                   'flow,'||
                                   'currency_code,'||
                                   'amount,'||
                                   'tmp_seg_local_account,'||
                                   'tmp_seg_argos_account,'||
                                   'tmp_seg_partner)'||
                        '(SELECT  '||gn_request_id||', '||
                                  'trunc(SYSDATE),'||
                                  'gb.period_name,'||
                                  ':pv_company_code,'||
                                  ':pv_conso_code,'||
                                  '''F99'','||
                                  'gsob.currency_code,'||
                                  'SUM (gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr) / 1000,'||
                                  'gcc.'||vv_seg_local_num||','||
                                  'gcc.'||vv_seg_argos_account_num||','||
                                  'gcc.'||vv_seg_partner_num||
                        ' FROM     gl_ledgers gsob,'||
                                  'gl_balances gb,'||
                                  'gl_code_combinations gcc '||
                         'WHERE        1 = 1 '||
                                 ' AND gcc.code_combination_id = gb.code_combination_id '||
                                 ' AND gb.ledger_id = gsob.ledger_id '|| --R12
                                 ' AND gsob.ledger_id = '||vn_set_of_books_id||
                                 ' AND gb.actual_flag = ''A'' '||
                                 ' AND gb.template_id IS NULL '||
                                 ' AND gb.currency_code = gsob.currency_code '||
                                 ' AND gcc.'||vv_seg_gl_balancing_num||' = :pv_company_code'||
                                 ' AND gcc.summary_flag = ''N'' '||
                                 ' AND gcc.template_id IS NULL '||
                                 ' AND gb.period_name = :pv_period_name'||
                                 ' AND gcc.'||vv_seg_argos_account_num||' NOT IN (SELECT ffv.flex_value '||
                                                                                 'FROM   fnd_flex_values ffv, '||
                                                                                        'fnd_flex_value_sets ffvs '||
                                                                                 'WHERE      ffv.flex_value_set_id = ffvs.flex_value_set_id '||
                                                                                        ' AND ffvs.flex_value_set_name = '''||vv_flex_val_set_name_argos|| --16/11/2007
                                                                                        '''AND ffv.'||vv_att_argos_excluded||' = ''Y'' )'||
                                 ' AND gcc.'||vv_seg_local_num||' NOT IN (SELECT ffv.flex_value '||
                                                                          'FROM   fnd_flex_values ffv, '||
                                                                                 'fnd_flex_value_sets ffvs '||
                                                                          'WHERE      ffv.flex_value_set_id = ffvs.flex_value_set_id '||
                                                                                 'AND ffvs.flex_value_set_name = ''XXDKA_VECTOR_EXCLUDED_LOCAL_ACCOUNT'' '||
                                                                                 'AND ffv.enabled_flag = ''Y'') '||
                        'GROUP BY trunc(SYSDATE),'||
                                  'gb.period_name,'||
                                  'gsob.currency_code,'||
                                  'gcc.'||vv_seg_local_num||','||
                                  'gcc.'||vv_seg_argos_account_num||','||
                                  'gcc.'||vv_seg_partner_num||' '||
                        'HAVING SUM (gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr) / 1000 != 0)';

            EXECUTE IMMEDIATE sql_req USING pv_company_code, pv_conso_code, pv_company_code, pv_period_name;	--R12 remplacer CONSO par conso

            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Rows inserted into dka_ieoglvec01_int : '|| TO_CHAR (SQL%ROWCOUNT));
            Fnd_File.put_line (Fnd_File.output,pv_company_code||' : '||get_message('SQLGL','GL_REC_INS','REC', TO_CHAR (SQL%ROWCOUNT),'TABLE','dka_ieoglvec01_int'));

              IF (vv_seg_flow_num IS NOT NULL
                  AND vv_att_argos_interface IS NOT NULL)
              THEN
                  Fnd_File.put_line (Fnd_File.LOG, 'vv_seg_flow_num  : ' || vv_seg_flow_num);
                  Fnd_File.put_line (Fnd_File.LOG, 'vv_att_argos_interface  : ' || vv_att_argos_interface);

                  sql_req := 'INSERT INTO dka_ieoglvec01_int '||
                                         '(request_id,'||
                                         'date_extraction,'||
                                         'period_name,'||
                                         'company_code,'||
                                         'entity,'||
                                         'flow,'||
                                         'currency_code,'||
                                         'amount,'||
                                         'tmp_seg_local_account,'||
                                         'tmp_seg_argos_account,'||
                                         'tmp_seg_partner)'||
                              '(SELECT  '||gn_request_id||', '||
                                        'trunc(SYSDATE),'||
                                        'gps4.period_name,'||
                                        ':pv_company_code,'||
                                        ':pv_conso_code,'||
                                        'gcc.'||vv_seg_flow_num||','||
                                        'gsob.currency_code,'||
  --                                      'SUM (gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr) / 1000,'||
                                        --'SUM ((nvl(gb.begin_balance_dr,0) - nvl(gb.begin_balance_cr,0) + nvl(gb.period_net_dr,0) - nvl(gb.period_net_cr,0)) - (nvl(gb2.begin_balance_dr,0) - nvl(gb2.begin_balance_cr,0)))  / 1000,'||
                                        'SUM (nvl(gb.period_net_dr,0) - nvl(gb.period_net_cr,0))  / 1000,'||
                                        'gcc.'||vv_seg_local_num||','||
                                        'gcc.'||vv_seg_argos_account_num||','||
                                        'gcc.'||vv_seg_partner_num||
                              ' FROM     gl_ledgers gsob,'||
                                        'gl_balances gb,'||
                                        'gl_code_combinations gcc, '||
                                        --'gl_balances gb2, '||
                                        'gl_period_statuses gps, '||
                                        'gl_period_statuses gps4, '||
                                        'fnd_application fa ' ||
                               'WHERE    1 = 1 '||
                                       ' AND gcc.code_combination_id = gb.code_combination_id '||
                                       ' AND gb.ledger_id = gsob.ledger_id '|| --R12
                                       ' AND gsob.ledger_id = '||vn_set_of_books_id||
                                       ' AND gb.actual_flag = ''A'' '||
                                       ' AND gb.template_id IS NULL '||
                                       ' AND gb.currency_code = gsob.currency_code '||
                                       ' AND gcc.'||vv_seg_gl_balancing_num||' = :pv_company_code'||
                                       ' AND gcc.summary_flag = ''N'' '||
                                       ' AND gcc.template_id IS NULL '||
                                       --' AND gb.period_name = :pv_period_name'||
                                       ' AND gb.period_name = gps.period_name'||
                                       ' AND gcc.'||vv_seg_argos_account_num||' NOT IN (SELECT ffv.flex_value '||
                                                                                       'FROM   fnd_flex_values ffv, '||
                                                                                              'fnd_flex_value_sets ffvs '||
                                                                                       'WHERE  ffv.flex_value_set_id = ffvs.flex_value_set_id '||
                                                                                        ' AND  ffvs.flex_value_set_name = '''||vv_flex_val_set_name_argos||
                                                                                       '''AND  ffv.'||vv_att_argos_excluded||' = ''Y'' )'||
                                       ' AND gcc.'||vv_seg_local_num||' NOT IN (SELECT ffv.flex_value '||
                                                                               'FROM   fnd_flex_values ffv, '||
                                                                                      'fnd_flex_value_sets ffvs '||
                                                                               'WHERE  ffv.flex_value_set_id = ffvs.flex_value_set_id '||
                                                                               'AND    ffvs.flex_value_set_name = ''XXDKA_VECTOR_EXCLUDED_LOCAL_ACCOUNT'' '||
                                                                               'AND    ffv.enabled_flag = ''Y'') '||
                                       ' AND gcc.'||vv_seg_flow_num||' IN (SELECT ffv.flex_value '||
                                                                          'FROM   fnd_flex_values ffv, '||
                                                                                 'fnd_flex_value_sets ffvs '||
                                                                          'WHERE  ffv.flex_value_set_id = ffvs.flex_value_set_id '||
                                                                          'AND    ffvs.flex_value_set_name = '''||vv_flex_val_set_name_flow||
                                                                       ''' AND    NVL(ffv.'||vv_att_argos_interface ||', ''Y'') = ''Y'' )'||
                                       --' AND    gb2.set_of_books_id = gb.set_of_books_id '||
                                       ' AND    gps.application_id = fa.application_id '||
                                       ' AND    fa.application_short_name = ''SQLGL'' '||
                                       ' AND    gps.period_year = gb.period_year '||
                                       ' AND    gps.set_of_books_id = gb.ledger_id '||
                                       ' AND    gps4.application_id = fa.application_id '||
                                       ' AND    gps4.period_year = gb.period_year '||
                                       ' AND    gps4.set_of_books_id = gb.ledger_id '||
                                       ' AND    gps4.period_name = :pv_period_name'||
                                       --' AND    gb2.actual_flag = ''A'' '||
                                       --' AND    gcc.code_combination_id = gb2.code_combination_id '||
                                       --' AND    gb2.period_name = gps.period_name '||
                                       ' AND    gps.period_num >= (SELECT min(gps2.period_num) '||
                                                                 'FROM   gl_period_statuses gps2 '||
                                                                 'WHERE  gps2.application_id = gps.application_id '||
                                                                 'AND    gps2.period_year = gb.period_year '||
                                                                 'AND    gps2.set_of_books_id = gb.ledger_id ) '||
                                       'AND    gps.period_num <= (SELECT gps3.period_num '||
                                                                 'FROM   gl_period_statuses gps3 '||
                                                                 'WHERE  gps3.application_id = gps.application_id '||
                                                                 'AND    gps3.period_year = gb.period_year '||
                                                                 'AND    gps3.period_name = gps4.period_name '||
                                                                 'AND    gps3.set_of_books_id = gb.ledger_id ) '||
                              'GROUP BY trunc(SYSDATE),'||
                                        'gps4.period_name,'||
                                        'gsob.currency_code,'||
                                        'gcc.'||vv_seg_flow_num||','||
                                        'gcc.'||vv_seg_local_num||','||
                                        'gcc.'||vv_seg_argos_account_num||','||
                                        'gcc.'||vv_seg_partner_num||' '||
                              --'HAVING SUM (gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr) / 1000 != 0)'
  --                            'HAVING SUM ((nvl(gb.begin_balance_dr,0) - nvl(gb.begin_balance_cr,0) + nvl(gb.period_net_dr,0) - nvl(gb.period_net_cr,0)) - (nvl(gb2.begin_balance_dr,0) - nvl(gb2.begin_balance_cr,0)))  / 1000 != 0';
                                'HAVING SUM ((nvl(gb.period_net_dr,0) - nvl(gb.period_net_cr,0)))  / 1000 != 0 )';

                  EXECUTE IMMEDIATE sql_req USING pv_company_code, pv_conso_code, pv_company_code, pv_period_name;

                  Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Rows inserted into dka_ieoglvec01_int : '|| TO_CHAR (SQL%ROWCOUNT));
                  Fnd_File.put_line (Fnd_File.output,pv_company_code||' : '||get_message('SQLGL','GL_REC_INS','REC', TO_CHAR (SQL%ROWCOUNT),'TABLE','dka_ieoglvec01_int'));

              END IF;

            ELSE

            -- If operating unit
            Fnd_File.put_line (Fnd_File.LOG, 'OPERATING UNIT IS NOT NULL  : ' || pv_op_unit);
            sql_req := 'INSERT INTO dka_ieoglvec01_int '||
                                   '(request_id,'||
                                   'date_extraction,'||
                                   'period_name,'||
                                   'company_code,'||
                                   'entity,'||
                                   'flow,'||
                                   'currency_code,'||
                                   'amount,'||
                                   'tmp_seg_local_account,'||
                                   'tmp_seg_argos_account,'||
                                   'tmp_seg_partner,'||
                                   'tmp_seg_op_unit)'||
                        '(SELECT   '||gn_request_id||', '||
                                  'trunc(SYSDATE),'||
                                  'gb.period_name,'||
                                  ':pv_company_code,'||
                                  ':pv_conso_code,'||
                                  '''F99'','||
                                  'gsob.currency_code,'||
                                  'SUM (gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr) / 1000,'||
                                  'gcc.'||vv_seg_local_num||','||
                                  'gcc.'||vv_seg_argos_account_num||','||
                                  'gcc.'||vv_seg_partner_num||','||
                                  'gcc.'||vv_seg_op_unit_num||
                        ' FROM     gl_ledgers gsob,'||
                                  'gl_balances gb,'||
                                  'gl_code_combinations gcc '||
                         'WHERE        1 = 1 '||
                                 ' AND gcc.code_combination_id = gb.code_combination_id '||
                                 ' AND gb.ledger_id = gsob.ledger_id '|| --R12
                                 ' AND gsob.ledger_id = '||vn_set_of_books_id||
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
                                 ' AND gcc.'||vv_seg_local_num||' NOT IN (SELECT ffv.flex_value '||
                                                                           'FROM   fnd_flex_values ffv, '||
                                                                                  'fnd_flex_value_sets ffvs '||
                                                                          'WHERE      ffv.flex_value_set_id = ffvs.flex_value_set_id '||
                                                                                 'AND ffvs.flex_value_set_name = ''XXDKA_VECTOR_EXCLUDED_LOCAL_ACCOUNT'' '||
                                                                                 'AND ffv.enabled_flag = ''Y'') '||
                          'GROUP BY trunc(SYSDATE),'||
                                   'gb.period_name,'||
                                   'gsob.currency_code,'||
                                   'gcc.'||vv_seg_local_num||','||
                                   'gcc.'||vv_seg_argos_account_num||','||
                                   'gcc.'||vv_seg_partner_num||','||
                                   'gcc.'||vv_seg_op_unit_num||' '||
                          'HAVING SUM (gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr) / 1000 != 0)';
                          
            EXECUTE IMMEDIATE sql_req USING pv_company_code, pv_conso_code, pv_company_code, pv_op_unit, pv_period_name;

            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'Rows inserted into dka_ieoglvec01_int : '||TO_CHAR (SQL%ROWCOUNT));
            Fnd_File.put_line (Fnd_File.output,pv_company_code||' '||pv_op_unit||' : '||get_message('SQLGL','GL_REC_INS','REC', TO_CHAR (SQL%ROWCOUNT),'TABLE','dka_ieoglvec01_int'));

            IF (vv_seg_flow_num IS NOT NULL
                AND vv_att_argos_interface IS NOT NULL)
            THEN
                Fnd_File.put_line (Fnd_File.LOG, 'vv_seg_flow_num  : ' || vv_seg_flow_num);
                Fnd_File.put_line (Fnd_File.LOG, 'vv_att_argos_interface  : ' || vv_att_argos_interface);

                sql_req := 'INSERT INTO dka_ieoglvec01_int '||
                                       '(request_id,'||
                                       'date_extraction,'||
                                       'period_name,'||
                                       'company_code,'||
                                       'entity,'||
                                       'flow,'||
                                       'currency_code,'||
                                       'amount,'||
                                       'tmp_seg_local_account,'||
                                       'tmp_seg_argos_account,'||
                                       'tmp_seg_partner,'||
                                       'tmp_seg_op_unit)'||
                            '(SELECT  '||gn_request_id||', '||
                                      'trunc(SYSDATE),'||
                                      'gps4.period_name,'||
                                      ':pv_company_code,'||
                                      ':pv_conso_code,'||
                                      'gcc.'||vv_seg_flow_num||','||
                                      'gsob.currency_code,'||
--                                      'SUM (gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr) / 1000,'||
                                      --'SUM ((nvl(gb.begin_balance_dr,0) - nvl(gb.begin_balance_cr,0) + nvl(gb.period_net_dr,0) - nvl(gb.period_net_cr,0)) - (nvl(gb2.begin_balance_dr,0) - nvl(gb2.begin_balance_cr,0)))  / 1000,'||
                                      'SUM (nvl(gb.period_net_dr,0) - nvl(gb.period_net_cr,0))  / 1000,'||
                                      'gcc.'||vv_seg_local_num||','||
                                      'gcc.'||vv_seg_argos_account_num||','||
                                      'gcc.'||vv_seg_partner_num||','||
                                      'gcc.'||vv_seg_op_unit_num||
                            ' FROM     gl_ledgers gsob,'||
                                      'gl_balances gb,'||
                                      'gl_code_combinations gcc, '||
                                      --'gl_balances gb2, '||
                                      'gl_period_statuses gps, '||
                                      'gl_period_statuses gps4, '||
                                      'fnd_application fa ' ||
                             'WHERE    1 = 1 '||
                                     ' AND gcc.code_combination_id = gb.code_combination_id '||
                                     ' AND gb.ledger_id = gsob.ledger_id '|| --R12
                                     ' AND gsob.ledger_id = '||vn_set_of_books_id||
                                     ' AND gb.actual_flag = ''A'' '||
                                     ' AND gb.template_id IS NULL '||
                                     ' AND gb.currency_code = gsob.currency_code '||
                                     ' AND gcc.'||vv_seg_gl_balancing_num||' = :pv_company_code'||
                                     ' AND gcc.'||vv_seg_op_unit_num||' = :pv_op_unit'||
                                     ' AND gcc.summary_flag = ''N'' '||
                                     ' AND gcc.template_id IS NULL '||
                                     --' AND gb.period_name = :pv_period_name'||
                                     ' AND gb.period_name = gps.period_name'||
                                     ' AND gcc.'||vv_seg_argos_account_num||' NOT IN (SELECT ffv.flex_value '||
                                                                                     'FROM   fnd_flex_values ffv, '||
                                                                                            'fnd_flex_value_sets ffvs '||
                                                                                     'WHERE      ffv.flex_value_set_id = ffvs.flex_value_set_id '||
                                                                                            ' AND ffvs.flex_value_set_name = '''||vv_flex_val_set_name_argos|| --16/11/2007
                                                                                            '''AND ffv.'||vv_att_argos_excluded||' = ''Y'' )'||
                                     ' AND gcc.'||vv_seg_local_num||' NOT IN (SELECT ffv.flex_value '||
                                                                             'FROM   fnd_flex_values ffv, '||
                                                                                    'fnd_flex_value_sets ffvs '||
                                                                             'WHERE  ffv.flex_value_set_id = ffvs.flex_value_set_id '||
                                                                             'AND    ffvs.flex_value_set_name = ''XXDKA_VECTOR_EXCLUDED_LOCAL_ACCOUNT'' '||
                                                                             'AND    ffv.enabled_flag = ''Y'') '||
                                     ' AND gcc.'||vv_seg_flow_num||' IN (SELECT ffv.flex_value '||
                                                                        'FROM   fnd_flex_values ffv, '||
                                                                               'fnd_flex_value_sets ffvs '||
                                                                        'WHERE  ffv.flex_value_set_id = ffvs.flex_value_set_id '||
                                                                        ' AND ffvs.flex_value_set_name = '''||vv_flex_val_set_name_flow||
                                                                        ''' AND NVL(ffv.'||vv_att_argos_interface ||', ''Y'') = ''Y'' )'||
                                     --' AND    gb2.set_of_books_id = gb.set_of_books_id '||
                                     ' AND    gps.application_id = fa.application_id '||
                                     ' AND    fa.application_short_name = ''SQLGL'' '||
                                     ' AND    gps.period_year = gb.period_year '||
                                     ' AND    gps.set_of_books_id = gb.ledger_id '||
                                     ' AND    gps4.application_id = fa.application_id '||
                                     ' AND    gps4.period_year = gb.period_year '||
                                     ' AND    gps4.set_of_books_id = gb.ledger_id '||
                                     ' AND    gps4.period_name = :pv_period_name '||
                                     --' AND    gb2.actual_flag = ''A'' '||
                                     --' AND    gcc.code_combination_id = gb2.code_combination_id '||
                                     --' AND    gb2.period_name = gps.period_name '||
                                     ' AND    gps.period_num >= (SELECT min(gps2.period_num) '||
                                                               'FROM   gl_period_statuses gps2 '||
                                                               'WHERE  gps2.application_id = gps.application_id '||
                                                               'AND    gps2.period_year = gb.period_year '||
                                                               'AND    gps2.set_of_books_id = gb.ledger_id ) '||
                                     ' AND    gps.period_num <= (SELECT gps3.period_num '||
                                                               'FROM   gl_period_statuses gps3 '||
                                                               'WHERE  gps3.application_id = gps.application_id '||
                                                               'AND    gps3.period_year = gb.period_year '||
                                                               'AND    gps3.period_name = gps4.period_name '||
                                                               'AND    gps3.set_of_books_id = gb.ledger_id ) '||
                              'GROUP BY trunc(SYSDATE),'||
                                       'gps4.period_name,'||
                                       'gsob.currency_code,'||
                                       'gcc.'||vv_seg_flow_num||','||
                                       'gcc.'||vv_seg_local_num||','||
                                       'gcc.'||vv_seg_argos_account_num||','||
                                       'gcc.'||vv_seg_partner_num||','||
                                       'gcc.'||vv_seg_op_unit_num||' '||
--                              'HAVING SUM (gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr) / 1000 != 0)'
--                                'HAVING SUM ((nvl(gb.begin_balance_dr,0) - nvl(gb.begin_balance_cr,0) + nvl(gb.period_net_dr,0) - nvl(gb.period_net_cr,0)) - (nvl(gb2.begin_balance_dr,0) - nvl(gb2.begin_balance_cr,0)))  / 1000 != 0 )';
                                'HAVING SUM ((nvl(gb.period_net_dr,0) - nvl(gb.period_net_cr,0)))  / 1000 != 0 )';

                EXECUTE IMMEDIATE sql_req USING pv_company_code, pv_conso_code, pv_company_code, pv_op_unit, pv_period_name;

                Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'Rows inserted into dka_ieoglvec01_int : '||TO_CHAR (SQL%ROWCOUNT));
                Fnd_File.put_line (Fnd_File.output,pv_company_code||' '||pv_op_unit||' : '||get_message('SQLGL','GL_REC_INS','REC', TO_CHAR (SQL%ROWCOUNT),'TABLE','dka_ieoglvec01_int'));

            END IF;

            END IF;

        ELSE

            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'No rows inserted into dka_ieoglvec01_int : All qualifier and descriptive flexfield are not correctly setuped');

        END IF;

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure insert_dka_ieoglvec01_int');

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || pv_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'End of procedure insert_dka_ieoglvec01_int : EXCEPTION OTHERS ');
    END insert_dka_ieoglvec01_int;


-----------------------------------------------------------------
--  Name          : UPDATE_DKA_IEOGLVEC01_INT
--  Description   : Update data in temporary table DKA_IEOGLVEC01_INT
--
--
--  PARAMETERS :
--    pv_conso_code         CONSO code
--    pv_errbuf   Input/Output          Error message
--
--  RETURN VALUE :
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
-----------------------------------------------------------------
    PROCEDURE update_dka_ieoglvec01_int (
        pv_conso_code    IN       VARCHAR2,
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    )
    IS


        CURSOR cur_account_vector_interco(pv_conso_code VARCHAR2)
            IS
            SELECT tmp_seg_argos_account,
                   tmp_seg_local_account,
                   tmp_seg_partner,
                   sum(amount) sum_amount,
                   get_cuf_attribute_value('XARGOS_ACCOUNT',
                                                               tmp_seg_argos_account,
                                                               decode (SIGN(sum(amount)), -1, 'ARGOS_ACCOUNT_C', 'ARGOS_ACCOUNT_D')
                                           ) vector_account,
                   get_cuf_attribute_value('XARGOS_ACCOUNT', tmp_seg_argos_account, 'ARGOS_NATURE') nature
            FROM   dka_ieoglvec01_int
            WHERE  request_id = gn_request_id
              AND  entity = pv_conso_code
              AND  interco_activated = 'Y'
            GROUP BY tmp_seg_argos_account
                   , tmp_seg_local_account
                   , tmp_seg_partner
            ;
        rec_account_vector_interco cur_account_vector_interco%ROWTYPE;



        CURSOR cur_account_vector(pv_conso_code VARCHAR2)
            IS
            SELECT tmp_seg_argos_account,
                   tmp_seg_local_account,
                   sum(amount) sum_amount,
                   get_cuf_attribute_value('XARGOS_ACCOUNT',
                                                               tmp_seg_argos_account,
                                                               decode (SIGN(sum(amount)), -1, 'ARGOS_ACCOUNT_C', 'ARGOS_ACCOUNT_D')
                                           ) vector_account,
                   get_cuf_attribute_value('XARGOS_ACCOUNT', tmp_seg_argos_account, 'ARGOS_NATURE') nature
            FROM   dka_ieoglvec01_int
            WHERE  request_id = gn_request_id
              AND  entity = pv_conso_code
              AND  (interco_activated = 'N'
                    OR interco_activated IS NULL)
            GROUP BY tmp_seg_argos_account
                   , tmp_seg_local_account
            ;
        rec_account_vector cur_account_vector%ROWTYPE;

        CURSOR cur_account_vector_interco_dep(pv_conso_code VARCHAR2)
            IS
            SELECT tmp_seg_argos_account,
                   tmp_seg_local_account,
                   tmp_seg_partner,
                   sum(amount) sum_amount,
                   get_cuf_attribute_value_dep('XARGOS_ACCOUNT',
                                                               tmp_seg_argos_account,
                                                               tmp_seg_local_account,
                                                               decode (SIGN(sum(amount)), -1, 'ARGOS_ACCOUNT_C', 'ARGOS_ACCOUNT_D')
                                           ) vector_account,
                   get_cuf_attribute_value_dep('XARGOS_ACCOUNT', tmp_seg_argos_account, tmp_seg_local_account, 'ARGOS_NATURE') nature
            FROM   dka_ieoglvec01_int
            WHERE  request_id = gn_request_id
              AND  entity = pv_conso_code
              AND  interco_activated = 'Y'
            GROUP BY tmp_seg_argos_account
                   , tmp_seg_local_account
                   , tmp_seg_partner
            ;
        rec_account_vector_interco_dep cur_account_vector_interco_dep%ROWTYPE;

        CURSOR cur_account_vector_dep(pv_conso_code VARCHAR2)
            IS
            SELECT tmp_seg_argos_account,
                   tmp_seg_local_account,
                   sum(amount) sum_amount,
                   get_cuf_attribute_value_dep('XARGOS_ACCOUNT',
                                                               tmp_seg_argos_account,
                                                               tmp_seg_local_account,
                                                               decode (SIGN(sum(amount)), -1, 'ARGOS_ACCOUNT_C', 'ARGOS_ACCOUNT_D')
                                           ) vector_account,
                   get_cuf_attribute_value_dep('XARGOS_ACCOUNT', tmp_seg_argos_account,tmp_seg_local_account, 'ARGOS_NATURE') nature
            FROM   dka_ieoglvec01_int
            WHERE  request_id = gn_request_id
              AND  entity = pv_conso_code
              AND  (interco_activated = 'N'
                    OR interco_activated IS NULL)
            GROUP BY tmp_seg_argos_account
                   , tmp_seg_local_account
            ;
        rec_account_vector_dep cur_account_vector_dep%ROWTYPE;

    BEGIN

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Begin of procedure update_dka_ieoglvec01_int');


    -- update interco_activated field
    UPDATE dka_ieoglvec01_int
       SET interco_activated = get_cuf_attribute_value('XARGOS_INTERCO', tmp_seg_partner, 'INTERCO_ACTIVATED')
     WHERE request_id = gn_request_id
       AND entity  = pv_conso_code;


    -- Update partner field
    UPDATE dka_ieoglvec01_int
       SET partner = get_partner_code(tmp_seg_partner, tmp_seg_op_unit)
     WHERE request_id = gn_request_id
       AND entity  = pv_conso_code
       AND interco_activated = 'Y';


    -- Test if XARGOS_ACCOUNT is link to an dependent or independent flex value set
    IF get_qual_value_set_val_type('XARGOS_ACCOUNT') = 'D'
    THEN
        -- Case of dependent account segment
           -- Update accnt and nature where INTERCO_ACTIVATED = 'Y'
           OPEN cur_account_vector_interco_dep (pv_conso_code);

           LOOP
           BEGIN
               FETCH cur_account_vector_interco_dep INTO rec_account_vector_interco_dep;
               EXIT WHEN cur_account_vector_interco_dep%NOTFOUND;

                  BEGIN

                      UPDATE dka_ieoglvec01_int
                         SET accnt   = rec_account_vector_interco_dep.vector_account
                            ,nature  = rec_account_vector_interco_dep.nature
                       WHERE request_id            = gn_request_id
                         AND entity                = pv_conso_code
                         AND tmp_seg_argos_account = rec_account_vector_interco_dep.tmp_seg_argos_account
                         AND tmp_seg_local_account = rec_account_vector_interco_dep.tmp_seg_local_account
                         AND tmp_seg_partner       = rec_account_vector_interco_dep.tmp_seg_partner;

                  EXCEPTION
                  WHEN OTHERS
                  THEN
                      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ERROR UPDATE TABLE dka_ieoglvec01_int');
                      pn_retcode := sqlcode;
                      pv_errbuf := substr(sqlerrm,1,400);
                      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> sqlcode = ' || pn_retcode );
                      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ' ||pv_errbuf);
                  END;

           EXCEPTION
           WHEN OTHERS
           THEN
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ERROR READ CURSOR rec_account_vector_interco');
              pn_retcode := sqlcode;
              pv_errbuf := substr(sqlerrm,1,400);
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> sqlcode = ' || pn_retcode );
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ' ||pv_errbuf);
           END;

           END LOOP;


           -- Update accnt and nature where INTERCO_ACTIVATED != 'Y'
           OPEN cur_account_vector_dep (pv_conso_code);

           LOOP
           BEGIN
               FETCH cur_account_vector_dep INTO rec_account_vector_dep;
               EXIT WHEN cur_account_vector_dep%NOTFOUND;

                  BEGIN

                      UPDATE dka_ieoglvec01_int
                         SET accnt   = rec_account_vector_dep.vector_account
                            ,nature  = rec_account_vector_dep.nature
                       WHERE request_id            = gn_request_id
                         AND entity                = pv_conso_code
                         AND tmp_seg_argos_account = rec_account_vector_dep.tmp_seg_argos_account
                         AND tmp_seg_local_account = rec_account_vector_dep.tmp_seg_local_account
                         AND  (interco_activated = 'N'
                               OR interco_activated IS NULL);

                  EXCEPTION
                  WHEN OTHERS
                  THEN
                      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ERROR UPDATE TABLE dka_ieoglvec01_int');
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

      ELSE
      -- Case of independent account segment
           -- Update accnt and nature where INTERCO_ACTIVATED = 'Y'
           OPEN cur_account_vector_interco (pv_conso_code);

           LOOP
           BEGIN
               FETCH cur_account_vector_interco INTO rec_account_vector_interco;
               EXIT WHEN cur_account_vector_interco%NOTFOUND;

                  BEGIN

                      UPDATE dka_ieoglvec01_int
                         SET accnt   = rec_account_vector_interco.vector_account
                            ,nature  = rec_account_vector_interco.nature
                       WHERE request_id            = gn_request_id
                         AND entity                = pv_conso_code
                         AND tmp_seg_argos_account = rec_account_vector_interco.tmp_seg_argos_account
                         AND tmp_seg_local_account = rec_account_vector_interco.tmp_seg_local_account
                         AND tmp_seg_partner       = rec_account_vector_interco.tmp_seg_partner;

                  EXCEPTION
                  WHEN OTHERS
                  THEN
                      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ERROR UPDATE TABLE dka_ieoglvec01_int');
                      pn_retcode := sqlcode;
                      pv_errbuf := substr(sqlerrm,1,400);
                      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> sqlcode = ' || pn_retcode );
                      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ' ||pv_errbuf);
                  END;

           EXCEPTION
           WHEN OTHERS
           THEN
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ERROR READ CURSOR rec_account_vector_interco');
              pn_retcode := sqlcode;
              pv_errbuf := substr(sqlerrm,1,400);
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> sqlcode = ' || pn_retcode );
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ' ||pv_errbuf);
           END;

           END LOOP;


           -- Update accnt and nature where INTERCO_ACTIVATED != 'Y'
           OPEN cur_account_vector (pv_conso_code);

           LOOP
           BEGIN
               FETCH cur_account_vector INTO rec_account_vector;
               EXIT WHEN cur_account_vector%NOTFOUND;

                  BEGIN

                      UPDATE dka_ieoglvec01_int
                         SET accnt   = rec_account_vector.vector_account
                            ,nature  = rec_account_vector.nature
                       WHERE  request_id           = gn_request_id
                         AND  entity               = pv_conso_code
                         AND tmp_seg_argos_account = rec_account_vector.tmp_seg_argos_account
                         AND tmp_seg_local_account = rec_account_vector.tmp_seg_local_account
                         AND  (interco_activated = 'N'
                               OR interco_activated IS NULL);

                  EXCEPTION
                  WHEN OTHERS
                  THEN
                      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ERROR UPDATE TABLE dka_ieoglvec01_int');
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

    END IF;


    -- Update Amount sign
    UPDATE dka_ieoglvec01_int
       SET amount = -1 * amount
     WHERE request_id = gn_request_id
       AND (SUBSTR (accnt,1, 4) = '40PL'
           OR SUBSTR (accnt,1, 2) in ('PL', 'LI'))
       AND entity = pv_conso_code;

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Rows updated (amount) : '|| TO_CHAR (SQL%ROWCOUNT));
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure update_dka_ieoglvec01_int');

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || pv_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure update_dka_ieoglvec01_int : EXCEPTION OTHERS ');
    END update_dka_ieoglvec01_int;


-----------------------------------------------------------------
--  Name          : LOAD_DKA_IEOGLVEC01_INT
--  Description   : Load data in temporary table DKA_IEOGLVEC01_INT
--
--
--  PARAMETERS :
--    pv_conso_code         CONSO code
--    pv_period_name         Name of period
--    pv_errbuf   Input/Output          Error message
--
--  RETURN VALUE :
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
-----------------------------------------------------------------
    PROCEDURE load_dka_ieoglvec01_int (
        pv_conso_code    IN       VARCHAR2,
        pv_period_name    IN       VARCHAR2,
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    )
    IS

        e_error           EXCEPTION;
        vv_errbuf         VARCHAR2 (500);
        vn_retcode        NUMBER;


        CURSOR cur_company(pv_conso_code VARCHAR2) --R12 modifier tout les CONSO par conso
            IS
            SELECT DISTINCT
                   balancing_seg_value,
                   operating_unit
            FROM   dka_ieoglvec01_conso_code_v
            WHERE  conso_code = pv_conso_code
            ;

        rec_company cur_company%ROWTYPE;

    BEGIN

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Begin of procedure load_dka_ieoglvec01_int');
    Fnd_File.put_line (Fnd_File.output, 'CONSO code : '||pv_conso_code);


           OPEN cur_company (pv_conso_code);

           LOOP
           BEGIN
               FETCH cur_company INTO rec_company;
               EXIT WHEN cur_company%NOTFOUND;

                  BEGIN

                  insert_dka_ieoglvec01_int
                                (pv_period_name,
                                 rec_company.balancing_seg_value,
                                 rec_company.operating_unit,
                                 pv_conso_code, -- R12 remplacer par pv_conso_code
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
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ERROR READ VIEW dka_ieoglvec01_CONSO_code');
              pn_retcode := sqlcode;
              pv_errbuf := substr(sqlerrm,1,400);
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> sqlcode = ' || pn_retcode );
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'>>>> ' ||pv_errbuf);
          END;

          END LOOP;


          update_dka_ieoglvec01_int (pv_conso_code, vv_errbuf, vn_retcode);

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


    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure load_dka_ieoglvec01_int');

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || pv_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure load_dka_ieoglvec01_int : EXCEPTION OTHERS ');
    END load_dka_ieoglvec01_int;



-----------------------------------------------------------------
--  Name          : LAUNCH_REQUEST
--  Description   :
--
--
--  PARAMETERS :
--    pv_conso_code         CONSO code
--    pv_period_name         Name of period
--    vn_requests_cnt Input/Output  Counter
--    va_request_ids  Input/Output  Table of request_id
--
--  RETURN VALUE :
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
--     pv_errbuf        :  Error message
-----------------------------------------------------------------

    PROCEDURE launch_request (
         pv_conso_code  IN VARCHAR2, --R12 changement conso_code
         pv_period_name  IN VARCHAR2,
         pv_period_num   IN NUMBER,
         pv_errbuf       OUT VARCHAR2,
         pn_retcode      OUT NUMBER,
         vn_requests_cnt IN OUT NUMBER,
         va_request_ids  IN OUT IdTabTyp
    )
    IS

        vv_amount_limit    fnd_profile_option_values.profile_option_value%TYPE;
        vn_request_id      Number;
        --vv_errbuf          VARCHAR2 (500);
        --vn_retcode         NUMBER;


    BEGIN

     Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Begin of procedure launch_request');

     vv_amount_limit := nvl(Fnd_Profile.VALUE ('VECTOR_INTERCO_THRESHOLD'),0);

     -- 07/03/07 CDE Recalculation of the interco threshold according to the month of extraction
     vv_amount_limit    := round((vv_amount_limit / 12) * pv_period_num);
     Fnd_File.put_line (Fnd_File.LOG,  TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'Interco threshold applied : '||vv_amount_limit);


     Fnd_File.put_line (Fnd_File.LOG,  TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'Generate VECTOR file for : '||pv_conso_code);
     vn_request_id   := fnd_request.submit_request (
                             gv_application_short_name,
                             'DKA_IEOGLVEC01_FILE',
                             NULL, --PROGRAM_NAME
                             NULL, --START
                             FALSE, --SUB_REQUEST
                             pv_conso_code, --ARGUMENT1  --R12 changer en conso_code
                             vv_amount_limit,
                             gn_request_id   --ARGUMENT3
                         );

      vn_requests_cnt := vn_requests_cnt + 1;
      va_request_ids(vn_requests_cnt) := vn_request_id;
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - Request submitted.  (Request ID = '||vn_request_id||')');

       -- Error in request launching
       IF vn_request_id = 0
       THEN
           pn_retcode    := 1;
           pv_errbuf     := get_message(gv_application_short_name,'DKA_IEOGLVEC01_DBERROR')||' : DKA_IEOGLVEC01_FILE (CONSO CODE '||pv_conso_code||')';
           Fnd_File.put_line (Fnd_File.output, pv_errbuf);
           Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || pv_errbuf);
       END IF;


       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'Launching request Balance VECTOR');
       vn_request_id   := fnd_request.submit_request (
                               gv_application_short_name, --APPL
                               'DKA_IEOGLVEC01_RDF',
                               NULL, --PROGRAM_NAME
                               NULL, --START
                               FALSE, --SUB_REQUEST
                               pv_conso_code, --ARGUMENT1 --R12 Change en conso_code.
                               pv_period_name,
                               gn_request_id   --ARGUMENT3
                           );

      vn_requests_cnt := vn_requests_cnt + 1;
      va_request_ids(vn_requests_cnt) := vn_request_id;
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - Request submitted.  (Request ID = '||vn_request_id||')');

       -- Error in request launching
       IF vn_request_id = 0
       THEN
           pn_retcode    := 1;
           pv_errbuf     := get_message(gv_application_short_name,'DKA_IEOGLVEC01_DBERROR')||' : DKA_IEOGLVEC01_REPORT (CONSO CODE '||pv_conso_code||')';
           Fnd_File.put_line (Fnd_File.output, pv_errbuf);
           Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || pv_errbuf);
       END IF;


   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'End of procedure launch_request');

   EXCEPTION
     WHEN OTHERS THEN
        pn_retcode    := 1;
        pv_errbuf     := 'End of procedure launch_request : EXCEPTION OTHERS';
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || pv_errbuf);
   END launch_request;


----------------------------------------------------------------------------
--  Name          : main
--  Description   : Request main procedure
--
--  PARAMETERS :
--    pv_conso_code         CONSO code
--    pv_period_name         Name of period
--    pv_errbuf   Input/Output          error message
--
--  RETURN VALUE :
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
----------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf        IN OUT   VARCHAR2,
        pn_retcode       IN OUT   NUMBER,
        pv_conso_code    IN       VARCHAR2,
        pv_period_name   IN       VARCHAR2
    )
    IS
        vv_errbuf                     VARCHAR2 (500);
        vn_retcode                    NUMBER;
        e_fatal_error                 EXCEPTION;
        t_request_ids                 IdTabTyp;
        vn_requests_cnt               NUMBER(22) := 0;
        vn_load_cnt                   NUMBER(22) := 0;
        vn_launch_cnt                 NUMBER(22) := 0;
        vv_dev_phase                  VARCHAR2(80);
        vv_dev_status                 VARCHAR2(80);
        vv_phase                      VARCHAR2(30);
        vv_status                     VARCHAR2(30);
        vb_loading_flag               BOOLEAN := FALSE;
        vb_req_flag                   BOOLEAN := FALSE;
        vv_period_num                 NUMBER;
        
        -- OBE artf2123666
        vn_trt_a_lancer                  NUMBER:=0;
        vn_trt_lances                    NUMBER:=0;
        vn_trt_normal                    NUMBER:=0;
        vn_trt_erreur                    NUMBER:=0;
        vn_trt_warning                   NUMBER:=0;             

        --R12
        CURSOR cur_conso(pv_conso_code VARCHAR2)
            IS
            SELECT DISTINCT conso_code,balancing_seg_value
            FROM   dka_ieoglvec01_conso_code_v
            WHERE  conso_code = pv_conso_code
              AND  'ALL' != pv_conso_code
              AND   EXISTS (SELECT 1 --RBE artf2177043
                            FROM GL_LEDGERS gl,gl_access_set_assignments gas
                            WHERE balancing_seg_value = gl.short_name
                            AND gl.ledger_id      = gas.LEDGER_ID
                            AND gas.access_set_id = FND_PROFILE.value('GL_ACCESS_SET_ID') 
                            )
            UNION ALL
            SELECT DISTINCT
                   conso_code,balancing_seg_value
            FROM   dka_ieoglvec01_conso_code_v
            WHERE  conso_code != pv_conso_code
              AND  conso_code IS NOT NULL
              AND  'ALL' = pv_conso_code
              AND   EXISTS (SELECT 1 --RBE artf2177043
                            FROM GL_LEDGERS gl,gl_access_set_assignments gas
                            WHERE balancing_seg_value = gl.short_name
                            AND gl.ledger_id      = gas.LEDGER_ID
                            AND gas.access_set_id = FND_PROFILE.value('GL_ACCESS_SET_ID')
                            )
              ;

        rec_conso cur_conso%ROWTYPE;

        --R12
        CURSOR cur_ledgers
        IS
          select ledger_id
          from gl_access_set_assignments
          where access_set_id = FND_PROFILE.value('GL_ACCESS_SET_ID');



    BEGIN

        -- Parameters initialisation
        vn_retcode := 0;
        gv_application_short_name := get_application_short_name(Fnd_Global.prog_appl_id);
        gn_request_id             := Fnd_Global.conc_request_id;

        -- Output header
        put_out_header;

        -- RBE artf2177043 :  Controle existence 
        OPEN cur_conso(pv_conso_code);
        FETCH cur_conso INTO rec_conso;

           IF (cur_conso%NOTFOUND)
           THEN
               IF pv_conso_code = 'ALL'
               THEN
                Fnd_File.put_line (Fnd_File.output,'Aucun code conso n''est trouvé pour cette responsabilité');
               ELSE
                Fnd_File.put_line (Fnd_File.output,'Le code conso '|| pv_conso_code ||' n''est pas accessible via cette responsabilité');
               END IF;
               CLOSE cur_conso;
                Fnd_File.put_line (Fnd_File.output,CHR(10));
                Fnd_File.put_line (Fnd_File.output,'******* '||get_message('FND','CONC-CP COMPLETED')||' *******');
                RETURN;
            END IF;
        CLOSE cur_conso;

        -------------------------------------
        -- Delete table dka_ieoglvec01_int --
        -------------------------------------
        --delete_dka_ieoglvec01_int (vv_errbuf, vn_retcode);

        --IF vn_retcode = 1
        --THEN
        --    pn_retcode   := 1;
        --    pv_errbuf    := vv_errbuf;
        --ELSIF vn_retcode != 0
        --THEN
        --    pn_retcode   := 2;
        --    pv_errbuf    := vv_errbuf;
        --    RAISE e_fatal_error;
        --END IF;

        --RBE artf2177043
        ---------------------------------
        -- Control period in parameter --
        ---------------------------------
        control_period_name (pv_period_name, vv_period_num, vv_errbuf, vn_retcode);
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
        ------------------------------------
        -- Load data and launch requests --
        ------------------------------------
        WHILE (vb_loading_flag = FALSE) OR (vb_req_flag = FALSE)
        LOOP

           IF vb_loading_flag = FALSE
           THEN
               Fnd_File.put_line (Fnd_File.output,CHR(10));
               Fnd_File.put_line (Fnd_File.output,'******* '||get_message('FND','FLOAD-UPLOADING','ARG1','dka_ieoglvec01_int','ARG2',NULL)||' *******');
               Fnd_File.put_line (Fnd_File.output,CHR(10));
           ELSE
               Fnd_File.put_line (Fnd_File.output,CHR(10));
               Fnd_File.put_line (Fnd_File.output,'******* '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_LAUNCH_HEADER')||' *******');
               Fnd_File.put_line (Fnd_File.output,CHR(10));
           END IF;

          FOR rec_conso IN cur_conso (pv_conso_code)
          LOOP
                  BEGIN
                      vn_trt_a_lancer := vn_trt_a_lancer + 1; -- OBE artf2123666

                      --RBE artf2177043 ne pas boucler sur les ledgers
                      --FOR rec_ledgers IN cur_ledgers
                      --LOOP
                        --RBE artf2177043
                        SELECT ledger_id
                        INTO GN_LEDGER_ID
                        FROM GL_LEDGERS gl
                        WHERE rec_conso.balancing_seg_value = gl.short_name
                        ;
                        --GN_LEDGER_ID := rec_ledgers.ledger_id;
                        ---------------------------------
                        -- Control period in parameter --
                        ---------------------------------
                        --control_period_name (pv_period_name, vv_period_num, vv_errbuf, vn_retcode);

                        -- IF vn_retcode = 1
                        -- THEN
                            -- pn_retcode   := 1;
                            -- pv_errbuf    := vv_errbuf;
                        -- ELSIF vn_retcode != 0
                        -- THEN
                            -- pn_retcode   := 2;
                            -- pv_errbuf    := vv_errbuf;
                            -- RAISE e_fatal_error;
                        -- END IF;

                        -----------------------------------------
                        -- Loading all data in temporary table --
                        -----------------------------------------
                        IF vb_loading_flag = FALSE
                        THEN
                        load_dka_ieoglvec01_int (rec_conso.conso_code
                                               , pv_period_name
                                               , vv_errbuf
                                               , vn_retcode);

                            IF vn_retcode != 0
                            THEN
                            RAISE e_fatal_error;
                            END IF;

                        vn_load_cnt := vn_load_cnt + 1;
                        END IF;
                      --END LOOP; --RBE artf2177043
                      --------------------------------
                      -- launching requests         --
                      --------------------------------

                      IF vb_loading_flag = TRUE
                      THEN

                         BEGIN
                         launch_request (rec_conso.conso_code --R12 remplacer par conso_code
                                       , pv_period_name
                                       , vv_period_num
                                       , vv_errbuf
                                       , vn_retcode
                                       , vn_requests_cnt
                                       , t_request_ids);

                         commit;

                           IF vn_retcode != 0
                           THEN
                           RAISE e_fatal_error;
                           END IF;

                           vn_launch_cnt := vn_launch_cnt + 1;
                           vn_trt_lances := vn_requests_cnt; -- OBE artf2123666

                             IF vn_launch_cnt = vn_load_cnt
                             THEN
                                 vb_req_flag := TRUE;
                                 Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'<<<< All requests have been launched');
                                 Fnd_File.put_line (Fnd_File.output,get_message('SQLGL','GL_REQUESTS_SUBMITTED')||' : '||vn_requests_cnt);
                             END IF;

                         EXCEPTION
                         WHEN OTHERS THEN
                               Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'Error occurred during launching of requests');
                               pv_errbuf  := SQLERRM;
                               pn_retcode := 2;
                         END;

                      END IF;


                 EXCEPTION
                 WHEN OTHERS THEN
                       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'Error cursor');
                       pv_errbuf  := SQLERRM;
                       pn_retcode := 2;
                END;

            END LOOP;

            IF vb_loading_flag = FALSE
            THEN
                vb_loading_flag := TRUE;
            ELSE
                vb_req_flag := TRUE;
            END IF;

         END LOOP;


         ---------------------------------------------------
         -- Loop to wait until all requests are completed --
         ---------------------------------------------------

         WHILE vn_requests_cnt > 0
         LOOP
             IF NOT (fnd_concurrent.wait_for_request (t_request_ids (vn_requests_cnt),
                                                      5,
                                                      0,
                                                      vv_phase,
                                                      vv_status,
                                                      vv_dev_phase,
                                                      vv_dev_status,
                                                      pv_errbuf
                                                    )
                  )
            THEN
                   Fnd_File.put_line (Fnd_File.output, 'Request number '|| TO_CHAR (t_request_ids (vn_requests_cnt)) || ' too long or failed in error');
                   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Request number '|| TO_CHAR (t_request_ids (vn_requests_cnt)) || ' too long or failed in error');
                   vn_trt_erreur := vn_trt_erreur + 1; -- OBE artf2123666

            ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL')
            THEN
                   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Request number '|| TO_CHAR (t_request_ids (vn_requests_cnt)) || ' completed successfully');
                   vn_trt_normal := vn_trt_normal + 1; -- OBE artf2123666
            ELSIF vv_dev_status = 'WARNING' THEN -- OBE artf2123666
              Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Request number '|| TO_CHAR (t_request_ids (vn_requests_cnt)) || ' completed with warning'); -- OBE artf2123666
              vn_trt_warning := vn_trt_warning + 1; -- OBE artf2123666
              
            ELSE
                   Fnd_File.put_line (Fnd_File.output,'Request number '|| TO_CHAR (t_request_ids (vn_requests_cnt)) || ' too long or failed in error');
                   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'Request number '|| TO_CHAR (t_request_ids (vn_requests_cnt)) || ' too long or failed in error');
                   vn_trt_erreur := vn_trt_erreur + 1; -- OBE artf2123666

            END IF;
            vn_requests_cnt := vn_requests_cnt - 1;
        END LOOP;
        
        -- OBE artf2123666
        Fnd_File.put_line (Fnd_File.LOG,CHR(10)||'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
        Fnd_File.put_line (Fnd_File.LOG,'==> Nombre de traitements lancés               : '||TO_CHAR(vn_trt_lances, '99990'));
        Fnd_File.put_line (Fnd_File.LOG,'==> Nombre de traitements terminés normalement : '||TO_CHAR(vn_trt_normal, '99990'));
        Fnd_File.put_line (Fnd_File.LOG,'==> Nombre de traitements terminés en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
        Fnd_File.put_line (Fnd_File.LOG,'==> Nombre de traitements terminés en erreur   : '||TO_CHAR(vn_trt_erreur, '99990')||CHR(10));
        
        -- OBE artf2123666
        IF vn_trt_erreur > 0 THEN
          pn_retcode := 2;
        ELSIF vn_trt_warning > 0 THEN
          pn_retcode := 1;
        END IF;        

        -------------------------------------
        -- Delete table dka_ieoglvec01_int --
        -------------------------------------
        delete_dka_ieoglvec01_int (gn_request_id, vv_errbuf, vn_retcode);

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


        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'******* '||get_message('FND','CONC-CP COMPLETED')||' *******');


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


----------------------------------------------------------------------------
--  Name          : control
--  Description   : Request control procedure
--
--  PARAMETERS :
--    pv_errbuf   Input/Output          error message
--
--  RETURN VALUE :
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
----------------------------------------------------------------------------
    PROCEDURE control (
        pv_errbuf        IN OUT   VARCHAR2,
        pn_retcode       IN OUT   NUMBER
    )
    IS
        --vv_errbuf                     VARCHAR2 (500);
        --vn_retcode                    NUMBER;
        e_fatal_error                 EXCEPTION;


        CURSOR cur_unit_op
            IS
            SELECT ffv1.flex_value
            FROM   fnd_flex_values ffv1
            WHERE     ffv1.flex_value_set_id = dka_ieoglvec01_pkg.get_qual_flex_value_set_id('XARGOS_OPERATING_UNIT')
                  AND ffv1.enabled_flag = 'Y'
                  AND ffv1.summary_flag = 'N'
            ;

        rec_unit_op cur_unit_op%ROWTYPE;

        CURSOR cur_code_conso_unknown
            IS
            SELECT balancing_seg_value,
                   operating_unit
            FROM   dka_ieoglvec01_conso_code_v
            WHERE     conso_code IS NULL
            ;

        rec_code_conso_unknown cur_code_conso_unknown%ROWTYPE;

    BEGIN

        -- Parameters initialisation
        --vn_retcode := 0;
        gv_application_short_name := get_application_short_name(Fnd_Global.prog_appl_id);

        -- Output header
        put_out_header;


        Fnd_File.put_line (Fnd_File.output,get_message(gv_application_short_name,'DKA_IEOGLVEC01_INSTANCE_NAME')||' : '||get_instance_name(Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID')));

        --------------------------------
        -- Control 1                  --
        --------------------------------
        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'1. '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_QUALIF_EXIST')||' : ');

        Fnd_File.put_line (Fnd_File.output, '    * GL_BALANCING...............'||qualifier_exists('GL_BALANCING'));
        Fnd_File.put_line (Fnd_File.output, '    * XARGOS_ACCOUNT.............'||qualifier_exists('XARGOS_ACCOUNT'));
        Fnd_File.put_line (Fnd_File.output, '    * XARGOS_INTERCO.............'||qualifier_exists('XARGOS_INTERCO'));
        Fnd_File.put_line (Fnd_File.output, '    * XARGOS_OPERATING_UNIT......'||qualifier_exists('XARGOS_OPERATING_UNIT')||' ('||get_message(gv_application_short_name,'DKA_IEOGLVEC01_QUAL_OPUN')||')');
        Fnd_File.put_line (Fnd_File.output, '    * XARGOS_FLOW................'||qualifier_exists('XARGOS_FLOW'));
        Fnd_File.put_line (Fnd_File.output, '    * GL_ACCOUNT.................'||qualifier_exists('GL_ACCOUNT'));

          --------------------------------
          -- Control 2                  --
          --------------------------------
          Fnd_File.put_line (Fnd_File.output,CHR(10));
          Fnd_File.put_line (Fnd_File.output,'2. '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_QUALIF_ASSIGN')||' : ');

          IF get_segment_num('GL_BALANCING') IS NOT NULL
          THEN
              Fnd_File.put_line (Fnd_File.output,'    * '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_LINK_QUALIF_ASS','QUALIFIER','GL_BALANCING','SEGMENT',get_segment_num('GL_BALANCING'))
                                                           ||' : '|| get_message(gv_application_short_name,'DKA_IEOGLVEC01_COMPL'));
          ELSE
              Fnd_File.put_line (Fnd_File.output,'    * '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_LINK_QUALIF_ASS','QUALIFIER','GL_BALANCING','SEGMENT',' ')
                                                           ||' : '|| get_message(gv_application_short_name,'DKA_IEOGLVEC01_UNCOMPL'));
          END IF;

          IF get_segment_num('XARGOS_ACCOUNT') IS NOT NULL
          THEN
              Fnd_File.put_line (Fnd_File.output,'    * '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_LINK_QUALIF_ASS','QUALIFIER','XARGOS_ACCOUNT','SEGMENT',get_segment_num('XARGOS_ACCOUNT'))
                                                           ||' : '|| get_message(gv_application_short_name,'DKA_IEOGLVEC01_COMPL'));
          ELSE
              Fnd_File.put_line (Fnd_File.output,'    * '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_LINK_QUALIF_ASS','QUALIFIER','XARGOS_ACCOUNT','SEGMENT',' ')
                                                           ||' : '|| get_message(gv_application_short_name,'DKA_IEOGLVEC01_UNCOMPL'));
          END IF;


          IF get_segment_num('XARGOS_INTERCO') IS NOT NULL
          THEN
              Fnd_File.put_line (Fnd_File.output,'    * '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_LINK_QUALIF_ASS','QUALIFIER','XARGOS_INTERCO','SEGMENT',get_segment_num('XARGOS_INTERCO'))
                                                           ||' : '|| get_message(gv_application_short_name,'DKA_IEOGLVEC01_COMPL'));
          ELSE
              Fnd_File.put_line (Fnd_File.output,'    * '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_LINK_QUALIF_ASS','QUALIFIER','XARGOS_INTERCO','SEGMENT',' ')
                                                           ||' : '|| get_message(gv_application_short_name,'DKA_IEOGLVEC01_UNCOMPL'));
          END IF;

          IF get_segment_num('XARGOS_OPERATING_UNIT') IS NOT NULL
          THEN
              Fnd_File.put_line (Fnd_File.output,'    * '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_LINK_QUALIF_ASS','QUALIFIER','XARGOS_OPERATING_UNIT','SEGMENT',get_segment_num('XARGOS_OPERATING_UNIT'))
                                                           ||' : '|| get_message(gv_application_short_name,'DKA_IEOGLVEC01_COMPL')
                                                           ||' ('||get_message(gv_application_short_name,'DKA_IEOGLVEC01_QUAL_OPUN')||')');
          ELSE
              Fnd_File.put_line (Fnd_File.output,'    * '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_LINK_QUALIF_ASS','QUALIFIER','XARGOS_OPERATING_UNIT','SEGMENT',' ')
                                                           ||' : '|| get_message(gv_application_short_name,'DKA_IEOGLVEC01_UNCOMPL')
                                                           ||' ('||get_message(gv_application_short_name,'DKA_IEOGLVEC01_QUAL_OPUN')||')');
          END IF;

          IF get_segment_num('XARGOS_FLOW') IS NOT NULL
          THEN
              Fnd_File.put_line (Fnd_File.output,'    * '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_LINK_QUALIF_ASS','QUALIFIER','XARGOS_FLOW','SEGMENT',get_segment_num('XARGOS_FLOW'))
                                                           ||' : '|| get_message(gv_application_short_name,'DKA_IEOGLVEC01_COMPL'));
          ELSE
              Fnd_File.put_line (Fnd_File.output,'    * '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_LINK_QUALIF_ASS','QUALIFIER','XARGOS_FLOW','SEGMENT',' ')
                                                           ||' : '|| get_message(gv_application_short_name,'DKA_IEOGLVEC01_UNCOMPL'));
          END IF;

          IF get_segment_num('GL_ACCOUNT') IS NOT NULL
          THEN
              Fnd_File.put_line (Fnd_File.output,'    * '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_LINK_QUALIF_ASS','QUALIFIER','GL_ACCOUNT','SEGMENT',get_segment_num('GL_ACCOUNT'))
                                                           ||' : '|| get_message(gv_application_short_name,'DKA_IEOGLVEC01_COMPL'));
          ELSE
              Fnd_File.put_line (Fnd_File.output,'    * '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_LINK_QUALIF_ASS','QUALIFIER','GL_ACCOUNT','SEGMENT',' ')
                                                           ||' : '|| get_message(gv_application_short_name,'DKA_IEOGLVEC01_UNCOMPL'));
          END IF;


        --------------------------------
        -- Control 3                  --
        --------------------------------
        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'3. '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_CUF_EXIST')||' : ');

        Fnd_File.put_line (Fnd_File.output,'    * Qualifier GL_BALANCING : ');
        Fnd_File.put_line (Fnd_File.output,'      '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_NAME_SEG')||' : '||get_qual_flex_value_set_name('GL_BALANCING'));
        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'         '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_CUF_SEG')||' : ');
        Fnd_File.put_line (Fnd_File.output,'            - MAGNITUDE_CODE......'||attribute_exists('GL_BALANCING', 'MAGNITUDE_CODE'));
        IF qualifier_exists('XARGOS_OPERATING_UNIT') = 'OK'
        THEN
             FOR rec_unit_op IN cur_unit_op
             LOOP
                    BEGIN
                      Fnd_File.put_line (Fnd_File.output,'            - '||rec_unit_op.flex_value||'..............'||attribute_exists('GL_BALANCING', rec_unit_op.flex_value));

                    EXCEPTION
                    WHEN OTHERS THEN
                         Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'Error cursor cur_unit_op');
                         pv_errbuf  := SQLERRM;
                         pn_retcode := 2;
                    END;
             END LOOP;

        END IF;

        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'    * Qualifier XARGOS_ACCOUNT : ');
        Fnd_File.put_line (Fnd_File.output,'      '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_NAME_SEG')||' : '||get_qual_flex_value_set_name('XARGOS_ACCOUNT'));
        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'         '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_CUF_SEG')||' : ');
        Fnd_File.put_line (Fnd_File.output,'            - ARGOS_ACCOUNT_D......'||attribute_exists('XARGOS_ACCOUNT', 'ARGOS_ACCOUNT_D'));
        Fnd_File.put_line (Fnd_File.output,'            - ARGOS_ACCOUNT_C......'||attribute_exists('XARGOS_ACCOUNT', 'ARGOS_ACCOUNT_C'));
        Fnd_File.put_line (Fnd_File.output,'            - ARGOS_EXCLUDED.......'||attribute_exists('XARGOS_ACCOUNT', 'ARGOS_EXCLUDED'));
        Fnd_File.put_line (Fnd_File.output,'            - ARGOS_NATURE.........'||attribute_exists('XARGOS_ACCOUNT', 'ARGOS_NATURE'));

        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'    * Qualifier XARGOS_INTERCO : ');
        Fnd_File.put_line (Fnd_File.output,'         '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_NAME_SEG')||' : '||get_qual_flex_value_set_name('XARGOS_INTERCO'));
        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'         '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_CUF_SEG')||' : ');
        Fnd_File.put_line (Fnd_File.output,'            - MAGNITUDE_INTERCO..............'||attribute_exists('XARGOS_INTERCO', 'MAGNITUDE_INTERCO'));
        Fnd_File.put_line (Fnd_File.output,'            - INTERCO_ACTIVATED...........'||attribute_exists('XARGOS_INTERCO', 'INTERCO_ACTIVATED'));
        Fnd_File.put_line (Fnd_File.output,'            - SEGMENTED_MAGNITUDE_INTERCO....'||attribute_exists('XARGOS_INTERCO', 'SEGMENTED_MAGNITUDE_INTERCO'));

        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'    * Qualifier XARGOS_FLOW : ');
        Fnd_File.put_line (Fnd_File.output,'         '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_NAME_SEG')||' : '||get_qual_flex_value_set_name('XARGOS_FLOW'));
        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'         '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_CUF_SEG')||' : ');
        Fnd_File.put_line (Fnd_File.output,'            - ARGOS_INTERFACE......'||attribute_exists('XARGOS_FLOW', 'ARGOS_INTERFACE'));

        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'    * Qualifier GL_ACCOUNT : ');
        Fnd_File.put_line (Fnd_File.output,'         '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_NAME_SEG')||' : '||get_qual_flex_value_set_name('GL_ACCOUNT'));
        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'         '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_CUF_SEG')||' : ');
        Fnd_File.put_line (Fnd_File.output,'            - ARGOS_ACCOUNT_TYPE..............'||attribute_exists('GL_ACCOUNT', 'ARGOS_ACCOUNT_TYPE'));


        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'    * Category : ');
        Fnd_File.put_line (Fnd_File.output,'         '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_CUF_SEG')||' : ');
        Fnd_File.put_line (Fnd_File.output,'            - ARGOS_ASSET_FLOW..............'||attribute_exists_desc_flex('GL_JE_CATEGORIES', 'ARGOS_ASSET_FLOW'));
        Fnd_File.put_line (Fnd_File.output,'            - ARGOS_DEPRN_FLOW..............'||attribute_exists_desc_flex('GL_JE_CATEGORIES', 'ARGOS_DEPRN_FLOW'));

        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'    * Budget : ');
        Fnd_File.put_line (Fnd_File.output,'         '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_CUF_SEG')||' : ');
        Fnd_File.put_line (Fnd_File.output,'            - BUDGET_TYPE..............'||attribute_exists_desc_flex('GL_BUDGETS', 'BUDGET_TYPE'));
        Fnd_File.put_line (Fnd_File.output,'            - NUM_VERSION..............'||attribute_exists_desc_flex('GL_BUDGETS', 'NUM_VERSION'));

        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'         '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_VALUE_SET_EXIST')||' : ');
        Fnd_File.put_line (Fnd_File.output,'            - XDKA_BUDGET_TYPE.........'||flex_value_set_name_exists('XDKA_BUDGET_TYPE'));
        Fnd_File.put_line (Fnd_File.output,'            - XDKA_NUM_VERSION.........'||flex_value_set_name_exists('XDKA_NUM_VERSION'));
        Fnd_File.put_line (Fnd_File.output,'            - XDKA_BUDGET_NAME.........'||flex_value_set_name_exists('XDKA_BUDGET_NAME'));

        --------------------------------
        -- Control 4                  --
        --------------------------------

        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'4. '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_CODE_CONSO_CTL')||' : ');

           OPEN cur_code_conso_unknown;
           FETCH cur_code_conso_unknown INTO rec_code_conso_unknown;

               IF (cur_code_conso_unknown%FOUND)
               THEN
                   Fnd_File.put_line (Fnd_File.output,'    '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_CONSO_UNCOMPL')||' : '||rec_code_conso_unknown.balancing_seg_value||'  '||rec_code_conso_unknown.operating_unit);

                   LOOP
                      FETCH cur_code_conso_unknown INTO rec_code_conso_unknown;
                      EXIT WHEN cur_code_conso_unknown%NOTFOUND;
                           Fnd_File.put_line (Fnd_File.output,'    '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_CONSO_UNCOMPL')||' : '||rec_code_conso_unknown.balancing_seg_value||'  '||rec_code_conso_unknown.operating_unit);
                   END LOOP;
                   Fnd_File.put_line (Fnd_File.output,CHR(10));

               ELSE
                   Fnd_File.put_line (Fnd_File.output,'     '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_CONSO_COMPLETE'));
               END IF;

            CLOSE cur_code_conso_unknown;


        --------------------------------
        -- Control 5                  --
        --------------------------------

        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'5. '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_PROFILE_OP_CTL')||' : ');
        Fnd_File.put_line (Fnd_File.output, '    * VECTOR_INTERCO_THRESHOLD.....'||profile_option_exists('VECTOR_INTERCO_THRESHOLD'));
        Fnd_File.put_line (Fnd_File.output, '    * GL_SET_OF_BKS_ID.............'||profile_option_exists('GL_SET_OF_BKS_ID'));
        Fnd_File.put_line (Fnd_File.output, '    * GL_ACCESS_SET_ID.............'||profile_option_exists('GL_ACCESS_SET_ID'));


        --------------------------------
        -- Control 6                  --
        --------------------------------

        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'6. '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_DEPENDENT_SEG')||' : ');
        IF get_qual_value_set_val_type('XARGOS_ACCOUNT') = 'D'
        THEN
             IF get_qual_flex_value_set_parent('XARGOS_ACCOUNT') = get_qual_flex_value_set_id('GL_ACCOUNT')
             THEN
             Fnd_File.put_line (Fnd_File.output,'    * '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_QUAL_PAR_CHILD','CHILD','XARGOS_ACCOUNT','PARENT','GL_ACCOUNT')||' : OK');
             ELSE
             Fnd_File.put_line (Fnd_File.output,'    * '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_QUAL_PAR_CHILD','CHILD','XARGOS_ACCOUNT','PARENT','GL_ACCOUNT')||' : KO');
             END IF;
        ELSE
             Fnd_File.put_line (Fnd_File.output,'     Qualifier XARGOS_ACCOUNT : '||get_message(gv_application_short_name,'DKA_IEOGLVEC01_NO_DEP_SEG'));
        END IF;



        Fnd_File.put_line (Fnd_File.output,CHR(10));
        Fnd_File.put_line (Fnd_File.output,'******* '||get_message('FND','CONC-CP COMPLETED')||' *******');


    EXCEPTION
        WHEN e_fatal_error
        THEN
            ROLLBACK;
            pn_retcode   := 2;
            pv_errbuf    := 'CONTROL - FATAL ERROR : '||pv_errbuf;
        WHEN OTHERS
        THEN
            ROLLBACK;
            pn_retcode   := 2;
            pv_errbuf    := 'CONTROL - EXCEPTION OTHERS : '||substr(SQLERRM,1,450);
    END control;

END DKA_IEOGLVEC01_PKG;
/
SHOW ERROR

EXIT
