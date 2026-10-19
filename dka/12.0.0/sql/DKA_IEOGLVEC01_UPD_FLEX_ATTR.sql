----------------------------------------------------------------------------------------------            
-- $$                                                                                                     
-- CAPGEMINI                                                                            
-- PROJECT          : DALKIA Oracle Applications                                                          
-- NAME		          : DKA_IEOGLVEC01_UPD_FLEX_ATTR.sql                                                                   
-- DESCRIPTION	    : Script to insert values into fnd_flex_values attributes                                                                                                                                                
-- AUTHOR	          : CDEL (CG)                                                                   
-- CREATION DATE    : 27/10/2006                                                                                                                                                               
-- COMMENTS         : Exec on SQLPLUS with user APPS                                           
--                    with parameters :                                                       
--                           1) Qualifier code                                  
--------------------------------------------------------------------------------------------              
-- MODIFICATION HISTORY                                                                         
-- Date       Who Description                                                                             
-- ---------- --- -------------------------------------------------------------------------               
-- 2006/12/22 CD  Function get_attribute_number : fdfcu.form_above_prompt => fdfcu.end_user_column_name   
-- 2007/05/07 CD  Upload attributes for dependent flex values
-- 2007/05/31 CD  Declare : change size variables vv_attribute_value...   
-- 2016/11/23 PBR MIGRATION R12.                                                       
--------------------------------------------------------------------------------------------  

SET SERVEROUTPUT ON


DECLARE
      
      pv_qualifier                      fnd_segment_attribute_values.segment_attribute_type%TYPE;
      vv_flex_value                     fnd_flex_values.flex_value%TYPE;
      vv_parent                         fnd_flex_values.parent_flex_value_low%TYPE;
      vn_flex_value_set_id              fnd_flex_value_sets.flex_value_set_id%TYPE;
      vv_flex_value_set_name            fnd_flex_value_sets.flex_value_set_name%TYPE;
      vv_validation_type                fnd_flex_value_sets.validation_type%TYPE;
      vv_application_short_name         fnd_application.application_short_name%TYPE; 
      Nb_updated                        NUMBER;
      Nb_rejected                       NUMBER;
      Nb_processed                      NUMBER;   
      vv_sql_set_req                    VARCHAR2(400);
      vv_sql_update_req                 VARCHAR2(500);
      vv_sql_sel_req                    VARCHAR2(400);
      vv_field                          VARCHAR2(20);
      vn_nbre                           NUMBER;
      vn_field_nbre                     NUMBER;
      vv_attribute_value_code           VARCHAR2(30);
      vv_flex_attribute_num             VARCHAR2(20);
      err_msg                           VARCHAR2(255);
      err_num                           NUMBER;                            
      vv_attribute_value1               dka_ieoglvec01_load_flex_attr.attribute_value1%TYPE;    
      vv_attribute_value2               dka_ieoglvec01_load_flex_attr.attribute_value2%TYPE;   
      vv_attribute_value3               dka_ieoglvec01_load_flex_attr.attribute_value3%TYPE;
      vv_attribute_value4               dka_ieoglvec01_load_flex_attr.attribute_value4%TYPE; 
      vv_attribute_value5               dka_ieoglvec01_load_flex_attr.attribute_value5%TYPE; 
      vv_attribute_value6               dka_ieoglvec01_load_flex_attr.attribute_value6%TYPE; 
      vv_attribute_value7               dka_ieoglvec01_load_flex_attr.attribute_value7%TYPE; 
      vv_attribute_value8               dka_ieoglvec01_load_flex_attr.attribute_value8%TYPE;
      vv_exists                         VARCHAR2(1);
      e_error                           EXCEPTION;
      
      CURSOR cur_flex_attributes IS 
          SELECT flex_value,
                 parent,
                 attribute_value1,
                 attribute_value2,
                 attribute_value3,
                 attribute_value4,
                 attribute_value5,
                 attribute_value6,
                 attribute_value7,
                 attribute_value8
           FROM   dka_ieoglvec01_load_flex_attr
          WHERE  statut not in ('A')
            AND  flex_value != 'FLEX_VALUES'
          FOR UPDATE;

      rec_flex_attributes cur_flex_attributes%ROWTYPE;


      CURSOR cur_rows_rejected IS 
          SELECT flex_value, 
                 error_message
          FROM dka_ieoglvec01_load_flex_attr
          WHERE statut = 'R'
      FOR UPDATE;

      rec_rows_rejected  cur_rows_rejected %ROWTYPE;


      FUNCTION get_attribute_number (
          pv_flex_value_set_name    IN   VARCHAR2,
          pv_code_attribute         IN   VARCHAR2
          )
      RETURN VARCHAR2
      IS
          vv_attribute_num             VARCHAR2(12);
      BEGIN
          -- Initialisation
          vv_attribute_num := NULL;

          -- attribute number link to attribute code and qualifier
          BEGIN
          SELECT fdfcu.application_column_name
          INTO   vv_attribute_num
          FROM   fnd_descr_flex_col_usage_vl fdfcu
          WHERE  1 = 1
            AND  fdfcu.descriptive_flexfield_name    = 'FND_FLEX_VALUES'
            AND  fdfcu.descriptive_flex_context_code = pv_flex_value_set_name
            AND  fdfcu.end_user_column_name     = pv_code_attribute;
          ExCEPTION
          WHEN NO_DATA_FOUND
          THEN
              vv_attribute_num := NULL;
          END;

        ----- return value -----
        RETURN (vv_attribute_num);
      END get_attribute_number;




BEGIN

DBMS_OUTPUT.Enable(20000000);

-- Parameters initialisation
vv_application_short_name := dka_ieoglvec01_pkg.get_application_short_name(Fnd_Global.prog_appl_id);

-- Output Header
dka_ieoglvec01_pkg.put_out_header;


pv_qualifier := '&1';
vn_flex_value_set_id := NULL;

Nb_updated := 0;
Nb_rejected := 0;
Nb_processed := 0;

   -- delete records already loaded
   DELETE dka_ieoglvec01_load_flex_attr
    WHERE statut in ('A');

   -- Find flex value set Id
   BEGIN
   SELECT fifs.flex_value_set_id
         ,ffvs.flex_value_set_name
         ,ffvs.validation_type
   INTO   vn_flex_value_set_id
         ,vv_flex_value_set_name
         ,vv_validation_type
   FROM   fnd_segment_attribute_values fsav,
          gl_ledgers gsob,
          fnd_id_flex_segments fifs,
          fnd_flex_value_sets ffvs
   WHERE  fsav.id_flex_num = gsob.chart_of_accounts_id
     AND  fifs.id_flex_num = gsob.chart_of_accounts_id
     AND  fifs.application_column_name = fsav.application_column_name
     AND  gsob.ledger_id IN (select ledger_id FROM GL_access_set_assignments where access_set_id = (fnd_profile.value('GL_ACCESS_SET_ID')))
     AND  ffvs.flex_value_set_id = fifs.flex_value_set_id
     AND  fsav.id_flex_code = 'GL#'
     AND  fsav.attribute_value = 'Y'
     AND  fifs.id_flex_code = 'GL#'
     AND  fsav.segment_attribute_type = pv_qualifier
     group by
     fifs.flex_value_set_id
     ,ffvs.flex_value_set_name
     ,ffvs.validation_type;
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
         Fnd_File.put_line (Fnd_File.LOG,CHR(10)||'ERROR ON SELECTING FLEX_VALUE_SET_ID : no data found for qualifier '||pv_qualifier);	   
   END;

   Fnd_File.put_line (Fnd_File.output,dka_ieoglvec01_pkg.get_message(vv_application_short_name ,'DKA_IEOGLVEC01_VALUE_SET')||' : '||vv_flex_value_set_name );

   -- Find if headline FLEX_VALUES exists
   BEGIN
   SELECT 'x'
   INTO   vv_exists
   FROM   dka_ieoglvec01_load_flex_attr dlfa
   WHERE  dlfa.flex_value = 'FLEX_VALUES';
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
         Fnd_File.put_line (Fnd_File.LOG,CHR(10)||'ERROR ON SELECTING HEADLINE : non data found for FLEX_VALUES line');
         raise_application_error(-20099,'RAISE APPLICATION ERROR : NO DATA FOUND FOR FLEX_VALUES HEADLINE.');
   END;


   IF vn_flex_value_set_id IS NOT NULL
   THEN

       BEGIN       

       Fnd_File.put_line (Fnd_File.LOG,CHR(10));

       FOR vn_nbre IN 1..8
       LOOP
 
         vv_field := 'ATTRIBUTE_VALUE'||vn_nbre;
         
         vv_sql_sel_req := 'SELECT dlfa.'||vv_field||
                           ' FROM dka_ieoglvec01_load_flex_attr dlfa '||
                           'WHERE dlfa.flex_value = ''FLEX_VALUES''';       

         execute immediate vv_sql_sel_req INTO vv_attribute_value_code;


         IF vv_attribute_value_code IS NOT NULL 
         THEN 

              vv_flex_attribute_num := get_attribute_number(vv_flex_value_set_name, vv_attribute_value_code);              

              IF vv_flex_attribute_num IS NULL
              THEN
              Fnd_File.put_line (Fnd_File.LOG,'ERROR ON SELECTING ATTRIBUTE NUMBER : NO DATA FOUND FOR CODE '||vv_attribute_value_code||CHR(10));
              raise_application_error(-20099,'RAISE APPLICATION ERROR : NO DATA FOUND FOR ATTRIBUTE CODE '||vv_attribute_value_code);

              ELSE 
              Fnd_File.put_line (Fnd_File.LOG,'SELECTING ATTRIBUTE NUMBER : '||vv_flex_attribute_num||' FOR CODE : '||vv_attribute_value_code);
                   IF vn_nbre = 1
                   THEN   
                       vv_sql_set_req := vv_flex_attribute_num||' = :vv_'||vv_field;
                       vn_field_nbre := vn_nbre;
                   ELSE
                       vv_sql_set_req := vv_sql_set_req||', '||vv_flex_attribute_num||' = :vv_'||vv_field;
                       vn_field_nbre := vn_nbre;
                   END IF;
              END IF;
         ELSE
             raise e_error;  
         END IF;               

       END LOOP;

       EXCEPTION
          WHEN e_error THEN
              NULL;
       END;

       Fnd_File.put_line (Fnd_File.LOG,CHR(10));

       OPEN cur_flex_attributes;

       LOOP 
       BEGIN
          FETCH cur_flex_attributes  INTO rec_flex_attributes ;

          EXIT WHEN cur_flex_attributes%NOTFOUND;

                BEGIN

                        -- Variables
                        vv_flex_value := rec_flex_attributes.flex_value;
                        vv_parent := rec_flex_attributes.parent;
                        vv_attribute_value1 := rec_flex_attributes.ATTRIBUTE_VALUE1;
                        vv_attribute_value2 := rec_flex_attributes.ATTRIBUTE_VALUE2;
                        vv_attribute_value3 := rec_flex_attributes.ATTRIBUTE_VALUE3;
                        vv_attribute_value4 := rec_flex_attributes.ATTRIBUTE_VALUE4;
                        vv_attribute_value5 := rec_flex_attributes.ATTRIBUTE_VALUE5;
                        vv_attribute_value6 := rec_flex_attributes.ATTRIBUTE_VALUE6;
                        vv_attribute_value7 := rec_flex_attributes.ATTRIBUTE_VALUE7;
                        vv_attribute_value8 := rec_flex_attributes.ATTRIBUTE_VALUE8;

                        Nb_processed := Nb_processed + 1;

                        
                        IF vv_validation_type = 'D'
                        THEN
                            -- Case of dependent flex value set
                            -- Sql request
                            vv_sql_update_req := 'UPDATE fnd_flex_values '||
                                                 'SET '||vv_sql_set_req||
                                                      ',last_update_date = SYSDATE '||
                                                      ',last_updated_by = -1'||
                                                      ',value_category = nvl(value_category,:vv_flex_value_set_name) '||
                                                 'WHERE flex_value_set_id = :vn_flex_value_set_id '||
                                                   'AND flex_value = :vv_flex_value '||
                                                   'AND parent_flex_value_low = :vv_parent ';


                            -- Execute with parameters
                            IF vn_field_nbre = 1 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value, vv_parent;
                            ELSIF vn_field_nbre = 2 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_attribute_value2, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value, vv_parent;
                            ELSIF vn_field_nbre = 3 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_attribute_value2, vv_attribute_value3, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value, vv_parent;
                            ELSIF vn_field_nbre = 4 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_attribute_value2, vv_attribute_value3, 
                                                                         vv_attribute_value4, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value, vv_parent;
                            ELSIF vn_field_nbre = 5 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_attribute_value2, vv_attribute_value3, vv_attribute_value4,
                                                                         vv_attribute_value5, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value, vv_parent;
                            ELSIF vn_field_nbre = 6 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_attribute_value2, vv_attribute_value3, vv_attribute_value4,
                                                                         vv_attribute_value5, vv_attribute_value6, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value, vv_parent;
                            ELSIF vn_field_nbre = 7 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_attribute_value2, vv_attribute_value3, vv_attribute_value4,
                                                                         vv_attribute_value5, vv_attribute_value6, vv_attribute_value7, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value, vv_parent;
                            ELSIF vn_field_nbre = 8 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_attribute_value2, vv_attribute_value3, vv_attribute_value4, vv_attribute_value5,
                                                                         vv_attribute_value6, vv_attribute_value7, vv_attribute_value8, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value, vv_parent;
                            END IF;

                        ELSE
                            -- Case of independent flex value set                        
                            -- Sql request
                            vv_sql_update_req := 'UPDATE fnd_flex_values '||
                                                 'SET '||vv_sql_set_req||
                                                      ',last_update_date = SYSDATE '||
                                                      ',last_updated_by = -1'||
                                                      ',value_category = nvl(value_category,:vv_flex_value_set_name) '||
                                                 'WHERE flex_value_set_id = :vn_flex_value_set_id '||
                                                   'AND flex_value = :vv_flex_value ';


                            -- Execute with parameters
                            IF vn_field_nbre = 1 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value;
                            ELSIF vn_field_nbre = 2 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_attribute_value2, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value;
                            ELSIF vn_field_nbre = 3 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_attribute_value2, vv_attribute_value3, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value;
                            ELSIF vn_field_nbre = 4 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_attribute_value2, vv_attribute_value3, 
                                                                         vv_attribute_value4, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value;
                            ELSIF vn_field_nbre = 5 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_attribute_value2, vv_attribute_value3, vv_attribute_value4,
                                                                         vv_attribute_value5, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value;
                            ELSIF vn_field_nbre = 6 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_attribute_value2, vv_attribute_value3, vv_attribute_value4,
                                                                         vv_attribute_value5, vv_attribute_value6, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value;
                            ELSIF vn_field_nbre = 7 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_attribute_value2, vv_attribute_value3, vv_attribute_value4,
                                                                         vv_attribute_value5, vv_attribute_value6, vv_attribute_value7, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value;
                            ELSIF vn_field_nbre = 8 THEN
                               execute immediate vv_sql_update_req USING vv_attribute_value1, vv_attribute_value2, vv_attribute_value3, vv_attribute_value4, vv_attribute_value5,
                                                                         vv_attribute_value6, vv_attribute_value7, vv_attribute_value8, vv_flex_value_set_name, vn_flex_value_set_id, vv_flex_value;
                            END IF;
                          END IF;


                          IF SQL%FOUND 
                          THEN
                        
                          UPDATE dka_ieoglvec01_load_flex_attr
                             SET statut = 'A'
                          WHERE current of cur_flex_attributes;
                        
                          Nb_updated := Nb_updated + 1;

                          Fnd_File.put_line (Fnd_File.LOG,vv_flex_value_set_name || '-> Update of flex_value : ' || vv_flex_value );

                          END IF;


                          IF SQL%NOTFOUND  
                          THEN

                          UPDATE dka_ieoglvec01_load_flex_attr
                             SET statut = 'R'
                                ,error_message = dka_ieoglvec01_pkg.get_message(vv_application_short_name ,'DKA_IEOGLVEC01_VALUE_UNKNOWN') 
                          WHERE  current of cur_flex_attributes;

                          Nb_rejected := Nb_rejected + 1;

                          Fnd_File.put_line (Fnd_File.LOG,vv_flex_value_set_name || '-> No update of flex_value : ' || vv_flex_value );    
                         
                          END IF;


                EXCEPTION
                WHEN OTHERS 
                THEN
                    Fnd_File.put_line (Fnd_File.LOG,'ERROR UPDATE VALUE :'||rec_flex_attributes.flex_value );
                    err_msg := SUBSTR(SQLERRM,1,400);

                    UPDATE dka_ieoglvec01_load_flex_attr
                       SET statut = 'R'
                           ,error_message = 'Error occurred on updating FND_FLEX_VALUES :' || err_msg
                    WHERE CURRENT OF cur_flex_attributes;
                    
                    Nb_rejected := Nb_rejected + 1;

                END;

          EXCEPTION
          WHEN OTHERS 
          THEN

              Fnd_File.put_line (Fnd_File.LOG,'>>>> ERROR READ TABLE dka_ieoglvec01_load_flex_attr');
              err_num := sqlcode;
              err_msg := substr(sqlerrm,1,400);
              Fnd_File.put_line (Fnd_File.LOG,'>>>> sqlcode = ' || err_num );
              Fnd_File.put_line (Fnd_File.LOG,'>>>> ' ||err_msg);

              UPDATE dka_ieoglvec01_load_flex_attr
                 SET statut = 'R'
                    ,error_message = 'Error occurred on reading dka_ieoglvec01_load_flex_attr :' || err_msg
              WHERE CURRENT OF cur_flex_attributes;

              Nb_rejected := Nb_rejected + 1;

              raise_application_error(-20099,sqlcode || '_' || substr(sqlerrm,1,400));
         END; 

       END LOOP;

   END IF;

    Fnd_File.put_line (Fnd_File.LOG,CHR(10)||'Number of flex values updated: ' || Nb_updated ||CHR(10));

 
    -- Execution report     
    Fnd_File.put_line (Fnd_File.output,CHR(10)||dka_ieoglvec01_pkg.get_message(vv_application_short_name ,'DKA_IEOGLVEC01_ROW_PROCESSED','ROWS',Nb_processed));
    Fnd_File.put_line (Fnd_File.output,dka_ieoglvec01_pkg.get_message(vv_application_short_name ,'DKA_IEOGLVEC01_ROW_UPDATED','ROWS',Nb_updated));
    Fnd_File.put_line (Fnd_File.output,dka_ieoglvec01_pkg.get_message(vv_application_short_name ,'DKA_IEOGLVEC01_ROW_REJECTED','ROWS',Nb_rejected));
    Fnd_File.put_line (Fnd_File.output,CHR(10));

 
     -- List of rejected rows
      IF Nb_rejected != 0
      THEN

           Fnd_File.put_line (Fnd_File.output,dka_ieoglvec01_pkg.get_message(vv_application_short_name ,'DKA_IEOGLVEC01_LIST_REJ_ROWS'));

           FOR rec_rows_rejected IN cur_rows_rejected
           LOOP
                  BEGIN
                  Fnd_File.put_line (Fnd_File.output,'    - '|| rec_rows_rejected.flex_value ||' - ERR : '||rec_rows_rejected.error_message);            

                  EXCEPTION
                  WHEN OTHERS THEN
                        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'Error cursor cur_rows_rejected');
                        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQLERRM);
                  END;
           END LOOP;
      END IF;



    Fnd_File.put_line (Fnd_File.output,CHR(10)||'>>>> '||dka_ieoglvec01_pkg.get_message('FND','CONC-CHECK LOG FOR DETAILS'));	


    Fnd_File.put_line (Fnd_File.output,CHR(10));
    Fnd_File.put_line (Fnd_File.output,'******* '||dka_ieoglvec01_pkg.get_message('FND','CONC-CP COMPLETED')||' *******');



END;

/
