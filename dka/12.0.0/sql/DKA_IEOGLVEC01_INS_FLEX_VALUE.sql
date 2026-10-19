----------------------------------------------------------------------------------------------            
-- $$                                                                                                     
-- CAPGEMINI                                                                            
-- PROJECT          : DALKIA Oracle Applications                                                          
-- NAME             : DKA_IEOGLVEC01_INS_FLEX_VALUE.sql                                                          
-- DESCRIPTION      : Script to insert flex values in Oracle tables                                       
-- AUTHOR           : CDEL (CG)                                                                   
-- CREATION DATE    : 24/10/2006                                                                           
-- COMMENTS         : Exec on SQLPLUS with user APPS                                           
--                    with parameters :                                                       
--                           1) Flex value set name                                  
--------------------------------------------------------------------------------------------              
-- MODIFICATION HISTORY                                                                         
-- Date       Who Description                                                                             
-- ---------- --- -------------------------------------------------------------------------               
--                                                             
--------------------------------------------------------------------------------------------  

SET SERVEROUTPUT ON


DECLARE
      
      vv_flex_value_set_name		fnd_flex_value_sets.flex_value_set_name%TYPE;
      vn_flex_value_set_id	        fnd_flex_value_sets.flex_value_set_id%TYPE;
      vv_application_short_name         fnd_application.application_short_name%TYPE;
      Nb_created                        NUMBER;   
      Nb_updated                        NUMBER;
      Nb_processed                      NUMBER;
      Nb_rejected                       NUMBER;
      err_msg	                        VARCHAR2(255);
      err_num	                        NUMBER;  
      vv_language_exists                VARCHAR2(2);                          

      
      CURSOR cur_flex_value IS 
          SELECT flex_value,
                 description, 
                 language
          FROM dka_ieoglvec01_load_flex_value
          WHERE statut not in ('I','U')
      FOR UPDATE;

      rec_flex_value cur_flex_value%ROWTYPE;


      CURSOR cur_rows_rejected IS 
          SELECT flex_value,
                 description, 
                 error_message
          FROM dka_ieoglvec01_load_flex_value
          WHERE statut = 'R'
      FOR UPDATE;

      rec_rows_rejected  cur_rows_rejected %ROWTYPE;

BEGIN

DBMS_OUTPUT.Enable(20000000);

-- Parameters initialisation
vv_application_short_name := dka_ieoglvec01_pkg.get_application_short_name(Fnd_Global.prog_appl_id);

-- Output Header
dka_ieoglvec01_pkg.put_out_header;


vv_flex_value_set_name := '&1';
vn_flex_value_set_id := NULL;
vv_language_exists := NULL;

Nb_created := 0;
Nb_updated := 0;
Nb_processed := 0;
Nb_rejected := 0;

Fnd_File.put_line (Fnd_File.output,dka_ieoglvec01_pkg.get_message(vv_application_short_name ,'DKA_IEOGLVEC01_VALUE_SET')||' : '||vv_flex_value_set_name );

   -- delete records already loaded
   DELETE dka_ieoglvec01_load_flex_value
    WHERE statut in ('I','U');
  
   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || TO_CHAR (SQL%ROWCOUNT) || ' Rows deleted from dka_ieoglvec01_load_flex_value' ); 


   -- Find flex value set Id
   BEGIN
   SELECT flex_value_set_id
   INTO   vn_flex_value_set_id
   FROM   fnd_flex_value_sets ffvs
   WHERE  ffvs.flex_value_set_name = vv_flex_value_set_name;
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
         Fnd_File.put_line (Fnd_File.LOG,CHR(10)||TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'ERROR ON SELECTING FLEX_VALUE_SET_ID : no data found for flex_value_set_name '||vv_flex_value_set_name);	   
   END;

   Fnd_File.put_line (Fnd_File.LOG,CHR(10));

   IF vn_flex_value_set_id IS NOT NULL
   THEN

    OPEN cur_flex_value;

      LOOP 
      BEGIN
          FETCH cur_flex_value INTO rec_flex_value;
          EXIT WHEN cur_flex_value%NOTFOUND;

               BEGIN

               Nb_processed := Nb_processed + 1;

               
                -- Language control
               BEGIN
                    SELECT 'OK'
                    INTO    vv_language_exists
                    FROM    fnd_languages l
                    WHERE   l.installed_flag IN ('I', 'B')
                    AND     l.language_code = rec_flex_value.language
                    UNION ALL
                    SELECT 'OK'
                    FROM    dual
                    WHERE   rec_flex_value.language IS NULL;
               EXCEPTION
               WHEN NO_DATA_FOUND 
               THEN
 
                   vv_language_exists := 'KO';

                   UPDATE dka_ieoglvec01_load_flex_value
                      SET statut = 'R'
                         ,error_message = dka_ieoglvec01_pkg.get_message(vv_application_short_name ,'DKA_IEOGLVEC01_LANG_UNINSTALL','LANG',rec_flex_value.language)
                    WHERE current of cur_flex_value;

                   Nb_rejected := Nb_rejected + 1;

               END;

               
               IF vv_language_exists = 'OK'
               THEN         

                  -- Update FND_FLEX_VALUES_tl if value exists else insert into FND_FLEX_VALUES
                  UPDATE fnd_flex_values_tl ffvl
                     SET description      = rec_flex_value.description
                        ,last_update_date = SYSDATE
                        ,last_updated_by  = -1
                   WHERE ffvl.flex_value_id in ( SELECT ffv.flex_value_id
                                                 FROM fnd_flex_values ffv
                                                 WHERE ffv.flex_value_set_id = vn_flex_value_set_id
                                                   AND ffv.flex_value        = ltrim(rec_flex_value.flex_value, ' ')
                                                )
                     AND ((rec_flex_value.language IS NOT NULL
                          AND ffvl.language = rec_flex_value.language)
                      OR rec_flex_value.language IS NULL);


                        IF SQL%FOUND 
                        THEN
                        
                        UPDATE dka_ieoglvec01_load_flex_value
                           SET statut = 'U'
                         WHERE current of cur_flex_value;
                        
                        Nb_updated := Nb_updated + 1;

                        Fnd_File.put_line (Fnd_File.LOG,vv_flex_value_set_name || '-> Update of flex_value: ' || rec_flex_value.flex_value ||' - language : '|| rec_flex_value.language );

                        END IF;

                        IF SQL%NOTFOUND  
                        THEN

                             BEGIN                        

                             Fnd_File.put_line (Fnd_File.LOG,vv_flex_value_set_name || '-> Creation of flex_value: ' || rec_flex_value.flex_value );

                             --insert value into fnd_flex_values table
                               INSERT INTO fnd_flex_values 
                                        (flex_value_set_id,
                                         flex_value_id,
                                         flex_value,
                                         created_by,
                                         creation_date,
                                         last_update_date,
                                         last_updated_by,
                                         start_date_active,
                                         summary_flag,
                                         enabled_flag
                                         )
                                 VALUES (vn_flex_value_set_id,
                                         fnd_flex_values_s.nextval ,
                                         ltrim(rec_flex_value.flex_value, ' '),
                                          -1,
                                          sysdate,
                                          sysdate,
                                          -1,
                                          trunc(sysdate),
                                          'N',
                                          'Y');

                             --insert value into fnd_flex_values_tl table	
                               INSERT INTO fnd_flex_values_tl 
                                        (flex_value_id,
                                         language,
                                         last_update_date,
                                         last_updated_by,
                                         creation_date,
                                         created_by,
                                         last_update_login,
                                         description,
                                         source_lang,
                                         flex_value_meaning)
                                  SELECT fnd_flex_values_s.currval ,
                                         l.language_code,
                                         sysdate,
                                         -1,
                                         sysdate,
                                         -1,
                                         -1,
                                         rec_flex_value.description,
                                         l.language_code,
                                         rec_flex_value.flex_value 	
                                    FROM fnd_languages l
                                   WHERE l.installed_flag IN ('I', 'B');

                                  UPDATE dka_ieoglvec01_load_flex_value
                                     SET statut = 'I'
                                   WHERE current of cur_flex_value;
                                 
                                  Nb_created := Nb_created + 1;
                                  



                              EXCEPTION
                              WHEN OTHERS 
                              THEN
                                  Fnd_File.put_line (Fnd_File.LOG,'ERROR INSERT VALUE :'||rec_flex_value.flex_value );
                                  err_msg := SUBSTR(SQLERRM,1,400);
                                  Fnd_File.put_line (Fnd_File.LOG,err_msg);

                                  UPDATE dka_ieoglvec01_load_flex_value
                                     SET statut = 'R'
                                        ,error_message = dka_ieoglvec01_pkg.get_message(vv_application_short_name ,'DKA_IEOGLVEC01_ERR_FLEX_INS')||' : '|| err_msg
                                   WHERE current of cur_flex_value;

                                  Nb_rejected := Nb_rejected + 1;

                              END;

                        END IF;

               END IF;						

               EXCEPTION
               WHEN OTHERS 
               THEN
                       Fnd_File.put_line (Fnd_File.LOG,'ERROR UPDATE VALUE :'||rec_flex_value.flex_value );
                       err_msg := SUBSTR(SQLERRM,1,400);

                       UPDATE dka_ieoglvec01_load_flex_value
                          SET statut = 'R'
                             ,error_message = dka_ieoglvec01_pkg.get_message(vv_application_short_name ,'DKA_IEOGLVEC01_ERR_FLEX_UPD')||' : '|| err_msg
                       WHERE CURRENT OF cur_flex_value;

                       Nb_rejected := Nb_rejected + 1;
                       
               END;

        EXCEPTION
        WHEN OTHERS 
        THEN

            Fnd_File.put_line (Fnd_File.LOG,'>>>> ERROR READ TABLE dka_ieoglvec01_load_flex_value');
            err_num := sqlcode;
            err_msg := substr(sqlerrm,1,400);
            Fnd_File.put_line (Fnd_File.LOG,'>>>> sqlcode = ' || err_num );
            Fnd_File.put_line (Fnd_File.LOG,'>>>> ' ||err_msg);

            UPDATE dka_ieoglvec01_load_flex_value
               SET statut = 'R'
                  ,error_message = 'Error occurred on reading dka_ieoglvec01_load_flex_value : '|| err_msg
            WHERE CURRENT OF cur_flex_value;

            Nb_rejected := Nb_rejected + 1;
        
            raise_application_error(-20099,sqlcode || '_' || substr(sqlerrm,1,400));


        END ; 
      END LOOP;

    END IF;

      Fnd_File.put_line (Fnd_File.LOG,CHR(10)||TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'Number of flex values created : ' || Nb_created );	
      Fnd_File.put_line (Fnd_File.LOG,TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'Number of flex values updated : ' || Nb_updated );
 

      -- Execution report     
      Fnd_File.put_line (Fnd_File.output,CHR(10)||dka_ieoglvec01_pkg.get_message(vv_application_short_name ,'DKA_IEOGLVEC01_ROW_PROCESSED','ROWS',Nb_processed));
      Fnd_File.put_line (Fnd_File.output,dka_ieoglvec01_pkg.get_message(vv_application_short_name ,'DKA_IEOGLVEC01_ROW_INSERTED','ROWS',Nb_created));
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
