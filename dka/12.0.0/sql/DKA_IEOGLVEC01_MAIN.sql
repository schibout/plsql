---------------------------------------------------------------------------------------------------------------
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_IEOGLVEC01_MAIN.sql
-- DESCRIPTION      : Lancement automatique du traitement DKA_IEOGLVEC01_MAIN.sql
--
-- AUTEUR           : CDE (CGEY)
-- DATE DE CREATION : 22/11/2006
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
---------------------------------------------------------------------------------------------------------------
--- 10/12/2007 EMA Modification du nom de l'index créé : le nom DKA_GL_CODE_COMBINATIONS_N1 est remplacé par
---                DKA_CODE_COMBINATIONS_INT039.
--- 07/12/2007 EMA Optimisation du traitement : création dynamique d'un nouvel index DKA_GL_CODE_COMBINATIONS_N1
---                sur la table GL_CODE_COMBINATIONS.
--- 24/09/2007 EMA EIS20070125_Automate VECTOR - Prise en compte Uoisation pour utilisateur de lancement
---                Modification du script de lancement pour prendre en compte la nouvelle regle pour la
---                détermination de l'utilisateur de lancement :
---                      Utilisateur de lancement = Centre de gestion conso
---                Dans le cas ou plusieurs centres de gestion correspondent a un meme code conso, on conservera
---                l'ancienne regle :
---                      Utilisateur de lancement = Centre principal de la société.
--- 10/01/2008 EMA La recherche de la période et des parametres par défaut du traitement se fait en dehors de 
---                la boucle de lecture des codes Véolia
--- 19/06/2017 RBE artf2177043 : GL Etat consolidation VECTOR en erreur defect BeB #760 et Oracle_R12 #630
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 100000

VAR ret_code VARCHAR2(10);

DECLARE
    cv_prog_name            CONSTANT VARCHAR2 (30)  := 'DKA_IEOGLVEC01_MAIN';
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

    --< RBE
    vn_trt_a_lancer     NUMBER:=0;
    vn_trt_lances       NUMBER:=0;
    vn_trt_normal       NUMBER:=0;
    vn_trt_erreur       NUMBER:=0;
    vn_trt_warning      NUMBER:=0;    
    --> RBE  

    TYPE myrecord IS RECORD (
         request_id    NUMBER);

    TYPE mytable IS TABLE OF myrecord
         INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;    
    
    CURSOR cur_code_conso
    IS
         SELECT DISTINCT 
                conso_code,operating_unit,balancing_seg_value
         FROM   dka_ieoglvec01_conso_code_v
         WHERE  conso_code != 'ALL'
         AND   EXISTS (SELECT 1 --RBE artf2177043
                    FROM GL_LEDGERS gl,gl_access_set_assignments gas
                    WHERE balancing_seg_value = gl.short_name
                    AND gl.ledger_id      = gas.LEDGER_ID
                    AND gas.access_set_id = FND_PROFILE.value('GL_ACCESS_SET_ID')
                    )
         ;

    rec_code_conso                          cur_code_conso%ROWTYPE;

    CURSOR cur_periode 
    IS
          SELECT distinct period_name
          FROM   gl_period_statuses gps
          WHERE  application_id  = 101
          AND    set_of_books_id IN (select ledger_id FROM GL_access_set_assignments where access_set_id = (fnd_profile.value('GL_ACCESS_SET_ID')))
          AND    closing_status = 'C'
          AND    start_date = (SELECT max(start_date)
                               FROM gl_period_statuses gps1
                               WHERE application_id  = 101
                               AND gps1.set_of_books_id = gps.set_of_books_id
                               AND closing_status = 'C');
      
         
BEGIN

    -- Début modif EMA du 07/12/2007 
    -- Supression de l'index DKA_CODE_COMBINATIONS_INT039
    -- DBMS_OUTPUT.put_line ('Suppression de l''index DKA_GL_CODE_COMBINATIONS_N1');     modif EMA du 10/12/2007
    DBMS_OUTPUT.put_line ('Suppression de l''index DKA_CODE_COMBINATIONS_INT039'); -- modif EMA du 10/12/2007
    BEGIN
        -- vv_sqlstmt := 'DROP INDEX GL.DKA_GL_CODE_COMBINATIONS_N1';     modif EMA du 10/12/2007
        vv_sqlstmt := 'DROP INDEX DKA.DKA_CODE_COMBINATIONS_INT039'; -- modif EMA du 10/12/2007

        EXECUTE IMMEDIATE vv_sqlstmt;

        -- DBMS_OUTPUT.put_line ('Index DKA_GL_CODE_COMBINATIONS_N1 supprime');     modif EMA du 10/12/2007
        DBMS_OUTPUT.put_line ('Index DKA_CODE_COMBINATIONS_INT039 supprime'); -- modif EMA du 10/12/2007

    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    -- Création de l'index DKA_CODE_COMBINATIONS_INT039
    -- DBMS_OUTPUT.put_line('Création de l''index DKA_GL_CODE_COMBINATIONS_N1');     modif EMA du 10/12/2007
    DBMS_OUTPUT.put_line('Création de l''index DKA_CODE_COMBINATIONS_INT039'); -- modif EMA du 10/12/2007
    BEGIN
        -- vv_sqlstmt := 'CREATE INDEX GL.DKA_GL_CODE_COMBINATIONS_N1 ON GL.GL_CODE_COMBINATIONS';     modif EMA du 10/12/2007
        vv_sqlstmt := 'CREATE INDEX DKA.DKA_CODE_COMBINATIONS_INT039 ON GL.GL_CODE_COMBINATIONS'; -- modif EMA du 10/12/2007
        vv_sqlstmt := vv_sqlstmt || '    ( SEGMENT1, SEGMENT2, SEGMENT3, SEGMENT4, SEGMENT5,';
        vv_sqlstmt := vv_sqlstmt || '      SEGMENT6, SEGMENT7, SEGMENT8, SEGMENT9, SEGMENT10 )';
        vv_sqlstmt := vv_sqlstmt || '    TABLESPACE APPS_DKASPE_IDX';
        vv_sqlstmt := vv_sqlstmt || '    PCTFREE 10';
        vv_sqlstmt := vv_sqlstmt || '    INITRANS 2';
        vv_sqlstmt := vv_sqlstmt || '    MAXTRANS 255';
        vv_sqlstmt := vv_sqlstmt || '    STORAGE';
        vv_sqlstmt := vv_sqlstmt || '    (';
        vv_sqlstmt := vv_sqlstmt || '     INITIAL     50M';
        vv_sqlstmt := vv_sqlstmt || '     NEXT        50M';
        vv_sqlstmt := vv_sqlstmt || '     MINEXTENTS  1';
        vv_sqlstmt := vv_sqlstmt || '     MAXEXTENTS  UNLIMITED';
        vv_sqlstmt := vv_sqlstmt || '     PCTINCREASE 0';
        vv_sqlstmt := vv_sqlstmt || '    )';
    
        EXECUTE IMMEDIATE vv_sqlstmt;

        -- DBMS_OUTPUT.put_line ('Index DKA_GL_CODE_COMBINATIONS_N1 cree');     modif EMA du 10/12/2007
        DBMS_OUTPUT.put_line ('Index DKA_CODE_COMBINATIONS_INT039 cree'); -- modif EMA du 10/12/2007

    EXCEPTION
        WHEN OTHERS THEN
            -- DBMS_OUTPUT.put_line('ERREUR LORS DE LA CREATION DE L''INDEX DKA_GL_CODE_COMBINATIONS_N1');     modif EMA du 10/12/2007
            DBMS_OUTPUT.put_line('ERREUR LORS DE LA CREATION DE L''INDEX DKA_CODE_COMBINATIONS_INT039'); -- modif EMA du 10/12/2007
            DBMS_OUTPUT.put_line(SUBSTR(SQLERRM, 1, 80));
    END;    
    -- Fin modif EMA du 07/12/2007 

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
    
    DBMS_OUTPUT.put_line ('Recuperation utilisateur');
    SELECT user_id
    INTO   vn_user_id
    FROM   fnd_user
    WHERE  user_name = vv_user;
    
    DBMS_OUTPUT.put_line ('Recuperation de la responsabilité');
    SELECT fr.responsibility_id,
           fr.application_id
    INTO   vn_responsibility_id,
           vn_application_id
    FROM   fnd_responsibility fr
    WHERE  responsibility_key = vv_resp;
    
    --RBE artf2177043
    DBMS_OUTPUT.put_line ('Initialisation dans le contexte OA');
    fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
    
    DBMS_OUTPUT.put_line ('Recuperation des parametres');                       -- 10/01/2008
    dka_tools_pkg.get_request_set_params (                                      -- 10/01/2008
          pv_errbuf                      => vv_errbuf,                          -- 10/01/2008
          pn_retcode                     => vn_retcode,                         -- 10/01/2008
          pn_application_id              => NULL,                               -- 10/01/2008
          pn_request_set_id              => NULL,                               -- 10/01/2008
          pn_request_set_program_id      => NULL,                               -- 10/01/2008
          pn_prog_application_id         => vn_prog_application_id,             -- 10/01/2008
          pn_program_id                  => vn_program_id                       -- 10/01/2008
       );                                                                       -- 10/01/2008

    IF vn_retcode != 0                                                          -- 10/01/2008
    THEN                                                                        -- 10/01/2008
        DBMS_OUTPUT.put_line ('Impossible de récupérer les parametres :');      -- 10/01/2008
        DBMS_OUTPUT.put_line (vv_errbuf);                                       -- 10/01/2008
        :ret_code    := 'FAILURE';                                              -- 10/01/2008
        RETURN;                                                                 -- 10/01/2008
    END IF;                                                                     -- 10/01/2008
 
    OPEN cur_periode;                                                           -- 10/01/2008
    FETCH cur_periode INTO dka_tools_pkg.tab_request_params(2);                 -- 10/01/2008
    CLOSE cur_periode;                                                          -- 10/01/2008


    FOR rec_code_conso IN cur_code_conso
    LOOP
        BEGIN
            vn_trt_a_lancer := vn_trt_a_lancer + 1; -- RBE
            -- Debut Modif EMA du 24/09/2007
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
                    AND    divcv.conso_code = rec_code_conso.conso_code; */
                    
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
                --WHEN TOO_MANY_ROWS
                WHEN OTHERS
                THEN
                    vv_mainoffice_cost_center := 'DOS';
                    vd_active_date := trunc(SYSDATE);
                END;

                /*vv_user := dka_stransco_pkg.get_value_f('DKA_BDSOC_CDG',
                                                         vd_active_date,
                                                         vv_errbuf,
                                                         vv_mainoffice_cost_center);*/
                vv_user := vv_mainoffice_cost_center;

            END;
            -- Fin Modif EMA du 24/09/2007

            DBMS_OUTPUT.put_line ('Recuperation utilisateur');
            SELECT user_id
            INTO   vn_user_id
            FROM   fnd_user
            WHERE  user_name = vv_user;
            
            DBMS_OUTPUT.put_line ('Recuperation de la responsabilité');
            SELECT fr.responsibility_id,
                   fr.application_id
            INTO   vn_responsibility_id,
                   vn_application_id
            FROM   fnd_responsibility fr
            WHERE  responsibility_key = rec_code_conso.balancing_seg_value||'_GL_SAISIE';
    
            DBMS_OUTPUT.put_line ('Initialisation dans le contexte OA');
            fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);

            EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || fnd_profile.value ('ICX_LANGUAGE') || '''';

            -- DBMS_OUTPUT.put_line ('Recuperation des parametres');                     -- 10/01/2008
            -- dka_tools_pkg.get_request_set_params (                                    -- 10/01/2008
            --       pv_errbuf                      => vv_errbuf,                        -- 10/01/2008
            --       pn_retcode                     => vn_retcode,                       -- 10/01/2008
            --       pn_application_id              => NULL,                             -- 10/01/200
            --       pn_request_set_id              => NULL,                             -- 10/01/2008
            --       pn_request_set_program_id      => NULL,                             -- 10/01/2008
            --       pn_prog_application_id         => vn_prog_application_id,           -- 10/01/2008
            --       pn_program_id                  => vn_program_id                     -- 10/01/2008
            --    );                                                                     -- 10/01/2008

            -- IF vn_retcode != 0                                                        -- 10/01/2008
            -- THEN                                                                      -- 10/01/2008
            --     DBMS_OUTPUT.put_line ('Impossible de récupérer les parametres :');    -- 10/01/2008
            --     DBMS_OUTPUT.put_line (vv_errbuf);                                     -- 10/01/2008
            --     :ret_code    := 'FAILURE';                                            -- 10/01/2008
            -- RETURN;                                                                   -- 10/01/2008
            -- END IF;                                                                   -- 10/01/2008

            dka_tools_pkg.tab_request_params(1)  := rec_code_conso.conso_code;

            -- OPEN cur_periode;                                                         -- 10/01/2008
            -- FETCH cur_periode INTO dka_tools_pkg.tab_request_params(2);               -- 10/01/2008
            -- CLOSE cur_periode;                                                        -- 10/01/2008
 
 
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
            
            vn_trt_lances := vn_trt_lances + 1; -- RBE
            
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
        --RBE
        IF vv_dstatus = 'NORMAL' THEN
            DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' terminé avec le statut Normal');
            vn_trt_normal := vn_trt_normal + 1;
        ELSIF vv_dstatus = 'WARNING'
        THEN
            DBMS_OUTPUT.put_line (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning ');
            :ret_code    := 'WARNING';
            vn_trt_warning := vn_trt_warning + 1; --RBE
        ELSIF vv_dstatus != 'NORMAL'
        THEN
            DBMS_OUTPUT.put_line (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Erreur ');
            :ret_code    := 'FAILURE';
            vn_trt_erreur := vn_trt_erreur + 1; --RBE
        END IF;
    END IF;
    END LOOP;

    -- Début modif EMA du 07/12/2007 
    -- Supression de l'index DKA_CODE_COMBINATIONS_INT039
    -- DBMS_OUTPUT.put_line ('Suppression de l''index DKA_GL_CODE_COMBINATIONS_N1');     modif EMA du 10/12/2007
    DBMS_OUTPUT.put_line ('Suppression de l''index DKA_CODE_COMBINATIONS_INT039'); -- modif EMA du 10/12/2007
    BEGIN
        -- vv_sqlstmt := 'DROP INDEX GL.DKA_GL_CODE_COMBINATIONS_N1';     modif EMA du 10/12/2007
        vv_sqlstmt := 'DROP INDEX DKA.DKA_CODE_COMBINATIONS_INT039'; -- modif EMA du 10/12/2007

        EXECUTE IMMEDIATE vv_sqlstmt;

        -- DBMS_OUTPUT.put_line ('Index DKA_GL_CODE_COMBINATIONS_N1 supprime');     modif EMA du 10/12/2007
        DBMS_OUTPUT.put_line ('Index DKA_CODE_COMBINATIONS_INT039 supprime'); -- modif EMA du 10/12/2007

    EXCEPTION
        WHEN OTHERS THEN
            -- DBMS_OUTPUT.put_line('ERREUR LORS DE LA SUPPRESSION DE L''INDEX DKA_GL_CODE_COMBINATIONS_N1');     modif EMA du 10/12/2007
            DBMS_OUTPUT.put_line('ERREUR LORS DE LA SUPPRESSION DE L''INDEX DKA_CODE_COMBINATIONS_INT039'); -- modif EMA du 10/12/2007
            DBMS_OUTPUT.put_line(SUBSTR(SQLERRM, 1, 80));
    END;    
    -- Fin modif EMA du 07/12/2007 


    DBMS_OUTPUT.put_line (CHR (10) || '>>> Fin normale');

    IF :ret_code IS NULL
    THEN
    :ret_code        := 'SUCCESS';
    END IF;

      --< RBE
    DBMS_OUTPUT.PUT_LINE (CHR(10)||'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements lances               : '||TO_CHAR(vn_trt_lances, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines normalement : '||TO_CHAR(vn_trt_normal, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));  
  --> RBE  
  
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
