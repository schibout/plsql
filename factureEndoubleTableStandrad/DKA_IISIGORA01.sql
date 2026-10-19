---------------------------------------------------------------------------------------------------------------
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SGLCTRLFLUXIFRS.sql
-- DESCRIPTION      : Lancement automatique du traitement DKA_SGLCTRLFLUXIFRS.sql
--
-- AUTEUR           : CDE (CGEY)
-- DATE DE CREATION : 16/04/2008
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
---------------------------------------------------------------------------------------------------------------
--- 24/11/2016 PBR  Migration R12
---------------------------------------------------------------------------------------------------------------
--- 24/01/2017 OBE  Modification - artf2088777
--- 22/02/2017 MEG  
--- 21/06/2017 YWA artf2178310
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 100000

VAR ret_code VARCHAR2(10);

DECLARE
    cv_prog_name            CONSTANT VARCHAR2 (30)  := 'DKA_SGLCTRLFLUXIFRS';
    cn_tempo                CONSTANT NUMBER         := 20;
    vv_user                          VARCHAR2 (80)  := '&&1';
    vv_resp                          VARCHAR2 (80)  := '&&2';
    vv_errbuf                        VARCHAR2 (500) := NULL;
    vn_retcode                       NUMBER         := 0;
    vn_prog_application_id           NUMBER (15);
    vv_prog_application_short_name   VARCHAR2 (50);
    vn_program_id                    NUMBER (15);
    vn_responsibility_id             NUMBER (15);
    vn_application_id                NUMBER (15);
    vn_user_id                       NUMBER (15);
    vn_request_id                    NUMBER (15);
    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
    vn_traitement                    NUMBER         := 0;
    vn_indice                        NUMBER;
    vv_mainoffice_cost_center        VARCHAR2 (6);
    vd_active_date                   DATE;
    vv_sqlstmt                       VARCHAR2(32000); 
    
    --< OBE
    vn_trt_a_lancer     NUMBER:=0;
    vn_trt_lances       NUMBER:=0;
    vn_trt_normal       NUMBER:=0;
    vn_trt_erreur       NUMBER:=0;
    vn_trt_warning      NUMBER:=0;    
    --> OBE    
    

    TYPE myrecord IS RECORD (
         request_id    NUMBER);

    TYPE mytable IS TABLE OF myrecord
         INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;    
    
    CURSOR cur_code_conso
    IS
         SELECT DISTINCT 
                conso_code, operating_unit -- OBE
         FROM   dka_ieoglvec01_conso_code_v
         WHERE  conso_code != 'ALL'
         AND EXISTS (SELECT 1 
                            FROM GL_LEDGERS gl,gl_access_set_assignments gas
                            WHERE balancing_seg_value = gl.short_name
                            AND gl.ledger_id      = gas.ledger_id
                            AND gas.access_set_id = FND_PROFILE.value('GL_ACCESS_SET_ID')
                            ); --YWA artf2178310         

    rec_code_conso                          cur_code_conso%ROWTYPE;

    CURSOR cur_periode 
    IS
          SELECT distinct period_name
          FROM   gl_period_statuses gps
          WHERE  application_id  = 101
          AND    set_of_books_id IN (select ledger_id FROM GL_access_set_assignments where access_set_id = (fnd_profile.value('GL_ACCESS_SET_ID'))) --R12
          AND    closing_status = 'C'
          AND    start_date = (SELECT max(start_date)
                               FROM gl_period_statuses gps1
                               WHERE application_id  = 101
                               AND gps1.set_of_books_id = gps.set_of_books_id
                               AND closing_status = 'C');
      
         
BEGIN


    DBMS_OUTPUT.put_line ('Recuperation de la responsabilité');
    SELECT fr.responsibility_id,
           fr.application_id
    INTO   vn_responsibility_id,
           vn_application_id
    FROM   fnd_responsibility fr
    WHERE  responsibility_key = vv_resp;


    DBMS_OUTPUT.put_line ('Recuperation des identifiants programme');
    SELECT fcp.application_id,
           fa.application_short_name,
           fcp.concurrent_program_id
    INTO   vn_prog_application_id,
           vv_prog_application_short_name,
           vn_program_id
    FROM   fnd_concurrent_programs fcp,
           fnd_application fa
    WHERE  fcp.concurrent_program_name = cv_prog_name
    AND    fa.application_id = fcp.application_id;


    DBMS_OUTPUT.put_line ('Recuperation des parametres');                       
    dka_tools_pkg.get_request_set_params (                                      
          pv_errbuf                      => vv_errbuf,                          
          pn_retcode                     => vn_retcode,                         
          pn_application_id              => NULL,                               
          pn_request_set_id              => NULL,                              
          pn_request_set_program_id      => NULL,                              
          pn_prog_application_id         => vn_prog_application_id,            
          pn_program_id                  => vn_program_id                      
       );                                                                     

    IF vn_retcode != 0                                                         
    THEN                                                                       
        DBMS_OUTPUT.put_line ('Impossible de récupérer les paramètres :');     
        DBMS_OUTPUT.put_line (vv_errbuf);                                      
        :ret_code    := 'FAILURE';                                             
        RETURN;                                                                 
    END IF;                                                                     
    
    
    --YWA artf2178310
    DBMS_OUTPUT.put_line ('Recuperation utilisateur');
    SELECT user_id
    INTO   vn_user_id
    FROM   fnd_user
    WHERE  user_name = vv_user;

    DBMS_OUTPUT.put_line ('Initialisation dans le contexte OA');
    fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
    --YWA artf2178310
    
    
    OPEN cur_periode;                                                          
    FETCH cur_periode INTO dka_tools_pkg.tab_request_params(2);               
    CLOSE cur_periode;                                                        
    


    FOR rec_code_conso IN cur_code_conso
    LOOP
        BEGIN
            vn_trt_a_lancer := vn_trt_a_lancer + 1; -- OBE
            BEGIN
                SELECT DISTINCT operating_unit
                INTO   vv_user
                FROM   dka_ieoglvec01_conso_code_v divcv
                WHERE  divcv.conso_code = rec_code_conso.conso_code;

            EXCEPTION
            WHEN OTHERS 
            THEN
                BEGIN
                    /*SELECT DISTINCT 
                           diig.mainoffice_cost_center
                         , diig.active_date
                    INTO   vv_mainoffice_cost_center
                         , vd_active_date
                    FROM   dka_ieoglvec01_conso_code_v divcv,
                           dka_ibdsoc_i00dgic diig
                    WHERE  divcv.balancing_seg_value = diig.company_code
                    AND    divcv.conso_code = rec_code_conso.conso_code;*/ 
                    
                    --R12
                    SELECT DISTINCT 
                            val.ATTRIBUTE2   user_name   
                    INTO   vv_mainoffice_cost_center
                    FROM   fnd_flex_value_sets sets,
                           fnd_flex_values_vl val  ,
                           GL_LEDGERS         gl            
                    WHERE  sets.flex_value_set_id = val.flex_value_set_id
                    and    gl.short_name = val.flex_value
                    and    val.attribute2 = rec_code_conso.operating_unit
                    and    ledger_category_code = 'PRIMARY'
                    and    val.enabled_flag = 'Y'
                    and    SYSDATE BETWEEN nvl(val.start_date_active,SYSDATE) AND nvl(val.end_date_active,SYSDATE)
                    and    val.summary_flag = 'N'
                    and    val.VALUE_CATEGORY ='DAOPCCF_STE';
                    
                EXCEPTION 
                WHEN OTHERS
                THEN
                    vv_mainoffice_cost_center := 'DOS';--'GFK'; -- OBE
                    vd_active_date := trunc(SYSDATE);
                END;

                /*vv_user := dka_stransco_pkg.get_value_f('DKA_BDSOC_CDG',
                                                         vd_active_date,
                                                         vv_errbuf,
                                                         vv_mainoffice_cost_center);*/
                vv_user := vv_mainoffice_cost_center; --R12

            END;

            DBMS_OUTPUT.put_line ('Recuperation utilisateur');
            SELECT user_id
            INTO   vn_user_id
            FROM   fnd_user
            WHERE  user_name = vv_user;
    
    
            DBMS_OUTPUT.put_line ('Initialisation dans le contexte OA');
            fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);

            EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''FRENCH''';

            dka_tools_pkg.tab_request_params(1)  := rec_code_conso.conso_code;
 
            DBMS_OUTPUT.put_line ('Soumission du traitement');
            vn_request_id    := fnd_request.submit_request (
                               vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                               cv_prog_name, --SHORT_NAME du TRAITEMENT
                               NULL, --PROGRAM_NAME
                               NULL, --START
                               FALSE, --SUB_REQUEST
                               dka_tools_pkg.tab_request_params(1), --ARGUMENT1
                               dka_tools_pkg.tab_request_params(2), --ARGUMENT2
                               dka_tools_pkg.tab_request_params(3), --ARGUMENT3
                               dka_tools_pkg.tab_request_params(4), --ARGUMENT4
                               dka_tools_pkg.tab_request_params(5), --ARGUMENT5
                               dka_tools_pkg.tab_request_params(6), --ARGUMENT6
                               dka_tools_pkg.tab_request_params(7), --ARGUMENT7
                               dka_tools_pkg.tab_request_params(8), --ARGUMENT8
                               dka_tools_pkg.tab_request_params(9), --ARGUMENT9
                               dka_tools_pkg.tab_request_params(10), --ARGUMENT10
                               dka_tools_pkg.tab_request_params(11), --ARGUMENT11
                               dka_tools_pkg.tab_request_params(12), --ARGUMENT12
                               dka_tools_pkg.tab_request_params(13), --ARGUMENT13
                               dka_tools_pkg.tab_request_params(14), --ARGUMENT14
                               dka_tools_pkg.tab_request_params(15), --ARGUMENT15
                               dka_tools_pkg.tab_request_params(16), --ARGUMENT16
                               dka_tools_pkg.tab_request_params(17), --ARGUMENT17
                               dka_tools_pkg.tab_request_params(18), --ARGUMENT18
                               dka_tools_pkg.tab_request_params(19), --ARGUMENT19
                               dka_tools_pkg.tab_request_params(20), --ARGUMENT20
                               dka_tools_pkg.tab_request_params(21), --ARGUMENT21
                               dka_tools_pkg.tab_request_params(22), --ARGUMENT22
                               dka_tools_pkg.tab_request_params(23), --ARGUMENT23
                               dka_tools_pkg.tab_request_params(24), --ARGUMENT24
                               dka_tools_pkg.tab_request_params(25), --ARGUMENT25
                               dka_tools_pkg.tab_request_params(26), --ARGUMENT26
                               dka_tools_pkg.tab_request_params(27), --ARGUMENT27
                               dka_tools_pkg.tab_request_params(28), --ARGUMENT28
                               dka_tools_pkg.tab_request_params(29), --ARGUMENT29
                               dka_tools_pkg.tab_request_params(30), --ARGUMENT30
                               dka_tools_pkg.tab_request_params(31), --ARGUMENT31
                               dka_tools_pkg.tab_request_params(32), --ARGUMENT32
                               dka_tools_pkg.tab_request_params(33), --ARGUMENT33
                               dka_tools_pkg.tab_request_params(34), --ARGUMENT34
                               dka_tools_pkg.tab_request_params(35), --ARGUMENT35
                               dka_tools_pkg.tab_request_params(36), --ARGUMENT36
                               dka_tools_pkg.tab_request_params(37), --ARGUMENT37
                               dka_tools_pkg.tab_request_params(38), --ARGUMENT38
                               dka_tools_pkg.tab_request_params(39), --ARGUMENT39
                               dka_tools_pkg.tab_request_params(40), --ARGUMENT40
                               dka_tools_pkg.tab_request_params(41), --ARGUMENT41
                               dka_tools_pkg.tab_request_params(42), --ARGUMENT42
                               dka_tools_pkg.tab_request_params(43), --ARGUMENT43
                               dka_tools_pkg.tab_request_params(44), --ARGUMENT44
                               dka_tools_pkg.tab_request_params(45), --ARGUMENT45
                               dka_tools_pkg.tab_request_params(46), --ARGUMENT46
                               dka_tools_pkg.tab_request_params(47), --ARGUMENT47
                               dka_tools_pkg.tab_request_params(48), --ARGUMENT48
                               dka_tools_pkg.tab_request_params(49), --ARGUMENT49
                               dka_tools_pkg.tab_request_params(50), --ARGUMENT50
                               dka_tools_pkg.tab_request_params(51), --ARGUMENT51
                               dka_tools_pkg.tab_request_params(52), --ARGUMENT52
                               dka_tools_pkg.tab_request_params(53), --ARGUMENT53
                               dka_tools_pkg.tab_request_params(54), --ARGUMENT54
                               dka_tools_pkg.tab_request_params(55), --ARGUMENT55
                               dka_tools_pkg.tab_request_params(56), --ARGUMENT56
                               dka_tools_pkg.tab_request_params(57), --ARGUMENT57
                               dka_tools_pkg.tab_request_params(58), --ARGUMENT58
                               dka_tools_pkg.tab_request_params(59), --ARGUMENT59
                               dka_tools_pkg.tab_request_params(60), --ARGUMENT60
                               dka_tools_pkg.tab_request_params(61), --ARGUMENT61
                               dka_tools_pkg.tab_request_params(62), --ARGUMENT62
                               dka_tools_pkg.tab_request_params(63), --ARGUMENT63
                               dka_tools_pkg.tab_request_params(64), --ARGUMENT64
                               dka_tools_pkg.tab_request_params(65), --ARGUMENT65
                               dka_tools_pkg.tab_request_params(66), --ARGUMENT66
                               dka_tools_pkg.tab_request_params(67), --ARGUMENT67
                               dka_tools_pkg.tab_request_params(68), --ARGUMENT68
                               dka_tools_pkg.tab_request_params(69), --ARGUMENT69
                               dka_tools_pkg.tab_request_params(70), --ARGUMENT70
                               dka_tools_pkg.tab_request_params(71), --ARGUMENT71
                               dka_tools_pkg.tab_request_params(72), --ARGUMENT72
                               dka_tools_pkg.tab_request_params(73), --ARGUMENT73
                               dka_tools_pkg.tab_request_params(74), --ARGUMENT74
                               dka_tools_pkg.tab_request_params(75), --ARGUMENT75
                               dka_tools_pkg.tab_request_params(76), --ARGUMENT76
                               dka_tools_pkg.tab_request_params(77), --ARGUMENT77
                               dka_tools_pkg.tab_request_params(78), --ARGUMENT78
                               dka_tools_pkg.tab_request_params(79), --ARGUMENT79
                               dka_tools_pkg.tab_request_params(80), --ARGUMENT80
                               dka_tools_pkg.tab_request_params(81), --ARGUMENT81
                               dka_tools_pkg.tab_request_params(82), --ARGUMENT82
                               dka_tools_pkg.tab_request_params(83), --ARGUMENT83
                               dka_tools_pkg.tab_request_params(84), --ARGUMENT84
                               dka_tools_pkg.tab_request_params(85), --ARGUMENT85
                               dka_tools_pkg.tab_request_params(86), --ARGUMENT86
                               dka_tools_pkg.tab_request_params(87), --ARGUMENT87
                               dka_tools_pkg.tab_request_params(88), --ARGUMENT88
                               dka_tools_pkg.tab_request_params(89), --ARGUMENT89
                               dka_tools_pkg.tab_request_params(90), --ARGUMENT90
                               dka_tools_pkg.tab_request_params(91), --ARGUMENT91
                               dka_tools_pkg.tab_request_params(92), --ARGUMENT92
                               dka_tools_pkg.tab_request_params(93), --ARGUMENT93
                               dka_tools_pkg.tab_request_params(94), --ARGUMENT94
                               dka_tools_pkg.tab_request_params(95), --ARGUMENT95
                               dka_tools_pkg.tab_request_params(96), --ARGUMENT96
                               dka_tools_pkg.tab_request_params(97), --ARGUMENT97
                               dka_tools_pkg.tab_request_params(98), --ARGUMENT98
                               dka_tools_pkg.tab_request_params(99), --ARGUMENT99
                               dka_tools_pkg.tab_request_params(100) --ARGUMENT100
                           );

            vn_traitement := vn_traitement + 1;
            vt_traitement(vn_traitement).request_id   := vn_request_id;
  
            DBMS_OUTPUT.put_line ('Validation pour que les GTS puissent prendre la demande');
            COMMIT;

            IF vn_request_id = 0
            THEN
                DBMS_OUTPUT.put_line ('Impossible de lancer le Traitement ');
                :ret_code    := 'FAILURE';
                RETURN;
            END IF;

            DBMS_OUTPUT.put_line ('Traitement numero : ' || TO_CHAR (vn_request_id));
            vn_trt_lances := vn_trt_lances + 1; -- OBE

        END;
    END LOOP;



    -----------------------------------------------
    -- Attente de la fin de tous les traitements --
    -----------------------------------------------
    FOR vn_indice IN 1..vn_traitement 
    LOOP
    IF NOT fnd_concurrent.wait_for_request (vt_traitement(vn_indice).request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message)
    THEN
        :ret_code    := 'FAILURE';
        RETURN;
    ELSE
        --< OBE
         IF vv_dstatus = 'NORMAL' THEN
            DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' terminé avec le statut Normal');
            vn_trt_normal := vn_trt_normal + 1;
         ELSIF vv_dstatus = 'WARNING' THEN
            DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' terminé avec le statut en Warning');
            vn_trt_warning := vn_trt_warning + 1;
            :ret_code    := 'WARNING';
         ELSIF vv_dstatus != 'NORMAL' THEN
            DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' terminé avec le statut en Erreur');
            vn_trt_erreur := vn_trt_erreur + 1;
            dbms_output.put_line('>>>    message = "' || vv_message || '"');
            :ret_code := 'FAILURE';
         END IF;       
        /*IF vv_dstatus = 'WARNING'
        THEN
            DBMS_OUTPUT.put_line (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning ');
            :ret_code    := 'WARNING';
        ELSIF vv_dstatus != 'NORMAL'
        THEN
            DBMS_OUTPUT.put_line (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Erreur ');
            :ret_code    := 'FAILURE';
        END IF;*/
        --> OBE
    END IF;
    END LOOP;


    --DBMS_OUTPUT.put_line (CHR (10) || '>>> Fin normale'); -- OBE

    IF :ret_code IS NULL
    THEN
    :ret_code        := 'SUCCESS';
    END IF;
    
  --< OBE
    DBMS_OUTPUT.PUT_LINE (CHR(10)||'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements lances               : '||TO_CHAR(vn_trt_lances, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines normalement : '||TO_CHAR(vn_trt_normal, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));  
  --> OBE    
    
EXCEPTION
    WHEN OTHERS
    THEN
        DBMS_OUTPUT.put_line (cv_prog_name || ' ==> ERREUR : ' || SQLERRM);
        :ret_code    := 'FAILURE';
END;
/
COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code
