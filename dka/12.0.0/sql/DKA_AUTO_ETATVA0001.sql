/* Formatted on 05/16/2002 16:08 (Formatter Plus v4.5.2) */
---------------------------------------------------------------------------------------------------------------
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_AUTO_ETATVA0001.sql
-- DESCRIPTION      : Lancement automatique du traitement DKA_ETATVA0001
---
--- AUTEUR           : Capgemini
--- DATE DE CREATION : 16/10/2003
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------------------------
--- Version          : V1.1.0
--- Date             : 21/10/2005
--- Auteur           : E.Matuszewski
--- Nature           : Modification temporaire pour editer les états du mois d'août 2005
---------------------------------------------------------------------------------------------------------------
--- Version          : V1.1.1
--- Date             : 03/11/2005
--- Auteur           : E.Blondeel
--- Nature           : Annulation des modification temporaire d'Eric Matuszewski
---                    
---------------------------------------------------------------------------------------------------------------
--- Version          : V1.2.0
--- Date             : 22/09/2006
--- Auteur           : E.Matuszewski
--  Nature           : Ajout du paramètre supplémentaire 'Période comptable' qui permet de rééditer les états
---                    pour une période comptable particulière
---------------------------------------------------------------------------------------------------------------
--- Version          : V1.3.0
--- Date             : 01/03/2011
--- Auteur           : TB
--- Nature           : Suppression de l'utilisation de la table Dka_Ibdsoc_I00ic_Tmp
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--- Version          : V2
--- Date             : 10/11/2016
--- Auteur           : YWA
--- Nature           : Migration R12
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--- Version          : V3
--- Date             : 16/01/2017
--- Auteur           : NBO
--- Nature           : artf2083890 - SPE077 : TVA : Edition états TVA societe 001 : Automatisation
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--- Version          : V4
--- Date             : 14/02/2017
--- Auteur           : YWA
--- Nature           : artf2075460 : ETA001 : Lancement du script d'automatisation sur HELDEV2
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--- Version          : V5
--- Date             : 08/02/2018
--- Auteur           : Maxime EGOT
--- Nature           : artf2361551 : Automatisation Etats de TVA : ETA026 - SPE077 - ETA084 - ETA081 - ETA057
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--- Version          : V6
--- Date             : 16/04/2018
--- Auteur           : Julien JARDEZ
--- Nature           : artf2534999 : SPE077 - Problème lors du déplacement des fichiers de TVA de la 0001 (INC0209581) 
---------------------------------------------------------------------------------------------------------------
--- Version          : V7
--- Date             : 09/04/2019
--- Auteur           : Jerome WYCKAERT
--- Nature           : artf07235613 : Ajout de l'identification via UO/Société dans le lancement du traitement
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--- Version          : V8
--- Date             : 04/05/2023
--- Auteur           : ARAOUF-AHUILLE 
--- Nature           : Migration ExaCC
---------------------------------------------------------------------------------------------------------------


SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000

VAR ret_code      VARCHAR2(10);
VAR code_societe  VARCHAR2(6);
VAR utl_file_name VARCHAR2(512);

DECLARE
    vv_prog_name                     VARCHAR2 (30)  := 'DKA_ETATVA0001';--YWA
    vn_tempo                         NUMBER         := 20;
    vv_code_societe                  VARCHAR2 (6)   := '&&1';
    -- Début modif EMA du 22/09/2006 : Ajout du paramètre vv_param_periode
    vv_param_periode                 gl_period_statuses.period_name%TYPE := '&&2';
    -- Fin modif EMA du 22/09/2006 
    vv_user                          VARCHAR2 (80);
    vv_repertoire                    VARCHAR2 (250);
    vv_errbuf                        VARCHAR2 (500) := NULL;
    vn_retcode                       NUMBER         := 0;
    vn_traitement                    NUMBER         := 0;
    vn_indice                        NUMBER;
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
    vv_responsibility_ref            fnd_responsibility.responsibility_key%TYPE;
    vv_responsibility                fnd_responsibility.responsibility_key%TYPE;
    vv_responsibility_name           fnd_responsibility.responsibility_key%TYPE;
    vv_utl_file_dir                  v$parameter.value%TYPE;
    vv_utl_file_name                 VARCHAR2(250);
    vv_period_name                   VARCHAR2(50);
    vv_line                          VARCHAR2(250);
    rec_param                        dka_parameters%ROWTYPE;
    vf_myfile                        UTL_FILE.FILE_TYPE;
    pn_retcode                       NUMBER;
    vb_lancement_trt                 BOOLEAN;
    vn_trt_a_lancer                  NUMBER:=0;
    vn_trt_lances                    NUMBER:=0;
    vn_trt_normal                    NUMBER:=0;
    vn_trt_erreur                    NUMBER:=0;
    vn_trt_warning                   NUMBER:=0;
    vv_date                          VARCHAR2(20);
    v_ledger_id                      NUMBER;
    v_currency_code                  VARCHAR2(10);
    v_chart_of_accounts_id           NUMBER;
	v_ledger_name 					 VARCHAR2(100);--JWY artf07235613
	v_region_main		 			 VARCHAR2(30);--JWY artf07235613
	v_region_trt		 			 VARCHAR2(30);--JWY artf07235613
	

    TYPE myrecord IS RECORD (
         request_id    NUMBER,
         program_name  VARCHAR2(250),
         company_name  VARCHAR2(25),
         period_name   VARCHAR2(15));

    TYPE mytable IS TABLE OF myrecord
         INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;


    -- Curseur de sélection des sociétés pour les traitements annuels
    -----------------------------------------------------------------
    CURSOR cur_soc IS
        /*SELECT DISTINCT dii.company_code    company_name,
               drv.cgsoc                    segment_name
        FROM   dka_ibdsoc_i00dgic       dii,
               dka_ibdsoc_general_info  digi,
               dka_rjefrtxdc_v          drv
        WHERE  dii.company_type    = '0'
        AND    dii.company_code    = digi.company_code
        AND    digi.company_code   = SUBSTR(drv.cgsoc, 4, 4)
        AND    dii.company_code    = '0001'
        ORDER BY dii.company_code ASC, SUBSTR(drv.cgsoc, 1, 3) ASC;--a modifier*/
        SELECT SUBSTR(name, 4) company_name, name segment_name
        FROM hr_operating_units 
        WHERE name like '%'||vv_code_societe
        ORDER BY substr(name, 1, 3) ASC;--YWA

    rec_soc                          cur_soc%ROWTYPE;

    -------------------------------------------------------
    -- Procédure de positionnement dans le contexte O.A. --
    -------------------------------------------------------
    PROCEDURE positionnement_contexte ( pv_user_name IN     VARCHAR2,
                                        pv_resp_name IN     VARCHAR2,
                                        pv_prog_name IN     VARCHAR2,
                                        pn_retcode      OUT NUMBER,
                                        pv_errbuf       OUT VARCHAR2 )
    IS
    BEGIN
        -- Recherche de l'utilisateur
        -----------------------------
        BEGIN
            SELECT user_id
            INTO   vn_user_id
            FROM   fnd_user
            WHERE  user_name = NVL(pv_user_name, 'EXPLOITATION');

        EXCEPTION
            WHEN OTHERS THEN
                 pn_retcode := 2;
                 pv_errbuf  := '==> Impossible de trouver les informations liees a l''utilisateur '||pv_user_name;
                 RETURN;
        END;

        -- Récupération des informations liées a la responsabilite
        ----------------------------------------------------------
        BEGIN
            SELECT fr.responsibility_id,
                   fr.application_id,
                   fr.responsibility_key
            INTO   vn_responsibility_id,
                   vn_application_id,
                   vv_responsibility      
            FROM   fnd_responsibility fr
            WHERE  fr.responsibility_key = pv_resp_name;

        EXCEPTION
           WHEN OTHERS THEN
                 pn_retcode := 2;
                 pv_errbuf  := '==> Impossible de trouver les informations liees a la responsabilite '||pv_resp_name;
                 RETURN;
        END;

        -- Récupération des informations du traitement
        ----------------------------------------------
        BEGIN
            SELECT fcp.application_id,
                   fa.application_short_name,
                   fcp.concurrent_program_id
            INTO   vn_prog_application_id,
                   vv_prog_application_short_name,
                   vn_program_id
            FROM   fnd_concurrent_programs fcp,
                   fnd_application fa
            WHERE  fcp.concurrent_program_name = pv_prog_name --vv_prog_name --YWA
            AND    fa.application_id           = fcp.application_id;
   
        EXCEPTION
            WHEN OTHERS THEN
                 pn_retcode := 2;
                 pv_errbuf  := '==> Impossible de trouver les informations liees au programme '||pv_prog_name;--vv_prog_name;--YWA
                 RETURN;
        END;

        -- Positionnement dans le contexte O.A.
        ---------------------------------------
        fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);

        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || fnd_profile.value ('ICX_LANGUAGE') || '''';

    END;


    ------------------------------------------
    -- Fonction de soumission du traitement --
    ------------------------------------------
    PROCEDURE soumission_traitement IS
    BEGIN
        vn_request_id := fnd_request.submit_request ( vv_prog_application_short_name, -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                      vv_prog_name,                   -- SHORT NAME DU TRAITEMENT
                                                      --NULL,                         -- PROGRAM NAME
													  v_region_trt||' - '||v_ledger_name,         -- PROGRAM NAME artf07235613
                                                      NULL,                           -- START
                                                      FALSE,                          -- SUB REQUEST
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
                                                      dka_tools_pkg.tab_request_params(19)--, --ARGUMENT19 YWA
                                                      /*dka_tools_pkg.tab_request_params(20), --ARGUMENT20
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
                                                      dka_tools_pkg.tab_request_params(100) --ARGUMENT100*/
                                                      );
        vn_traitement := vn_traitement + 1;
        vt_traitement(vn_traitement).request_id   := vn_request_id;
        vt_traitement(vn_traitement).program_name := vv_prog_name;
        vt_traitement(vn_traitement).company_name := vv_code_societe;
        vt_traitement(vn_traitement).period_name  := vv_period_name;
        COMMIT;

        IF vn_request_id = 0 THEN
           DBMS_OUTPUT.PUT_LINE ('Impossible de lancer le Traitement ');
           DBMS_OUTPUT.PUT_LINE (vv_errbuf);
        END IF;

    END;

BEGIN
    
    vv_user     := FND_PROFILE.VALUE('USERNAME');
    :code_societe := vv_code_societe;
    
 --JWY artf07235613
  SELECT ledger_id ,currency_code,chart_of_accounts_id, legal_entity_name, val.attribute2 || val.flex_value
    INTO v_ledger_id, v_currency_code,v_chart_of_accounts_id, v_ledger_name, v_region_main
    FROM   gl_ledger_le_v gll, fnd_flex_value_sets sets,
       fnd_flex_values_vl  val                     
    WHERE gll.ledger_category_code= 'PRIMARY' 
    AND gll.ledger_short_name= vv_code_societe
    AND sets.flex_value_set_id = val.flex_value_set_id
   AND val.enabled_flag = 'Y'
   AND val.compiled_value_attributes = 'Y' || chr(10) || 'Y'
   AND val.summary_flag = 'N'
   AND gll.ledger_short_name = val.flex_value
   AND val.VALUE_CATEGORY = 'DAOPCCF_STE';
    
    
    -- Début modif EMA du 22/09/2006 : Si la période n'est pas renseignée, on traite le mois précédent
    --                                 sinon le mois passé en paramètre
    IF vv_param_periode IS NULL THEN
       --vv_date        := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'YYYY/MM/DD HH24:MI:SS');
       --vv_period_name := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'MON-YY');
       
	   /* JWY artf07235613
       SELECT TO_CHAR(TRUNC(end_date), 'YYYY/MM/DD HH24:MI:SS'), TO_CHAR(TRUNC(end_date), 'MON-YY')
         INTO vv_date, vv_period_name
         FROM gl_period_statuses
        WHERE application_id = 101
          AND set_of_books_id = nvl(v_ledger_id, set_of_books_id)
          AND end_date IN (SELECT start_date - 1
                             FROM gl_period_statuses
                            WHERE sysdate between start_date and end_date
                              AND application_id = 101)
         AND ROWNUM = 1;
		 */
		 
		 
		-- JWY artf07235613 
		SELECT TO_CHAR(TRUNC(end_date), 'YYYY/MM/DD HH24:MI:SS'), TO_CHAR(TRUNC(end_date), 'MON-YY')
         INTO vv_date, vv_period_name
         FROM gl_period_statuses gps
        WHERE gps.application_id = 200
          AND gps.set_of_books_id = nvl(v_ledger_id, set_of_books_id)
          AND gps.end_date IN (SELECT min(start_date) - 1
                                   FROM   gl_period_statuses
                                   WHERE  application_id  = gps.application_id
                                   AND set_of_books_id =gps.set_of_books_id 
                                   AND closing_status = 'O')
         AND ROWNUM = 1; 
		 
		 
       
    ELSE
       --vv_date        := TO_CHAR(TRUNC(LAST_DAY(TO_DATE(vv_param_periode, 'MON-YY'))), 'YYYY/MM/DD HH24:MI:SS');
       --vv_period_name := vv_param_periode;
       
       SELECT TO_CHAR(TRUNC(end_date), 'YYYY/MM/DD HH24:MI:SS'), vv_param_periode
         INTO vv_date, vv_period_name
         FROM gl_period_statuses
        WHERE application_id = 101
          AND set_of_books_id = nvl(v_ledger_id, set_of_books_id)
          AND period_name = vv_param_periode
        AND ROWNUM = 1;

    END IF;
    -- Fin modif EMA du 22/09/2006


    -----------------------------------------------------------------------------
    -- Recherche du répertoire dans lequel sera généré le fichier de commandes --
    -----------------------------------------------------------------------------
    BEGIN
		
		--ARA Remediation Exacc
        /*SELECT
         nvl(DEBUT,nvl(FIN,MILIEU))
        '/data/flf/files2/PDBFINI2/data'
        INTO   vv_utl_file_dir       
        FROM       
        (SELECT 
        decode(INSTR (substr(value,instr(VALUE,',',-1)+2),'data/out'),0,NULL,substr(value,instr(VALUE,',',-1)+2)) FIN,
        decode(INSTR (substr(value,1,instr(VALUE,',')-1),'data/out'),0,NULL,substr(value,1,instr(VALUE,',')-1)) DEBUT,
        decode(INSTR (substr(value,
                             instr(VALUE,',',-(length(value)-instr(VALUE,',',INSTR(value, 'data/out') )+2) )+2, --La virgule avant la chaine de caractère data/out 
                             instr(VALUE,',',INSTR(value, 'data/out') )-instr(VALUE,',',-(length(value)-instr(VALUE,',',INSTR(value, 'data/out') )+2) )-2 
                             --le nombre de caractère entre la virgule avant et après data/out (+ ou - 2 car la virgule est suivie d'un espace)
                             ),'data/out'),0,NULL,
                       substr(value,
                             instr(VALUE,',',-(length(value)-instr(VALUE,',',INSTR(value, 'data/out') )+2) )+2, --La virgule avant la chaine de caractère data/out 
                             instr(VALUE,',',INSTR(value, 'data/out') )-instr(VALUE,',',-(length(value)-instr(VALUE,',',INSTR(value, 'data/out') )+2) )-2 
                             --le nombre de caractère entre la virgule avant et après data/out (+ ou - 2 car la virgule est suivie d'un espace)
                             )) MILIEU
        FROM   v$parameter
        WHERE  name = 'utl_file_dir') V;   */  

        --AHuille, Oracle Exacc
        SELECT directory_path INTO vv_utl_file_dir FROM all_directories WHERE directory_name = 'DKA_OUT_DIR';
        --



       /*
        IF INSTR(vv_utl_file_dir, ',') != 0 THEN
           vv_utl_file_dir := SUBSTR(vv_utl_file_dir, 1, INSTR(vv_utl_file_dir, ',')-1);
        END IF;
       */
    EXCEPTION
        WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE ('Impossible de récupérer le répertoire de création des fichiers');
             :ret_code := 'FAILURE';
             RETURN;
    END;

    vv_utl_file_name := 'DKA_ETATVA0001.sh';
    :utl_file_name   := vv_utl_file_dir||'/'||vv_utl_file_name;

    vv_prog_name  := 'DKA_ETATVA0001';
    vv_repertoire := '$REP_DATA/editions_legales/'||vv_prog_name;

/* --< JWYC
    -----------------------------------------------------------------------
    -- Lancement du traitement 'DKA : Etat déclaratif de la TVA dans GL' --
    -----------------------------------------------------------------------
    -- Recherche de la responsabilité pour le lancement du traitement
    -----------------------------------------------------------------
    dka_tools_pkg.get_parameter ('DKA_GL_DECLAR_TVA', 'GL_RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf);
    IF pn_retcode != 0 THEN
       :ret_code := 'FAILURE';
       RETURN;
    END IF;

    vv_responsibility_ref := rec_param.varchar2_value;

    -- initialisation des variables
    -------------------------------
    vv_prog_name     := 'DKA_GL_DECLAR_TVA';
    vb_lancement_trt := TRUE;
    vn_trt_a_lancer  := vn_trt_a_lancer + 1;

    -- Positionnement dans le contexte O.A.
    ---------------------------------------
    --vv_responsibility_name := REPLACE (vv_responsibility_ref, 'XXXX', '0001');--a modifier
    positionnement_contexte ( vv_user, 
                              vv_responsibility_ref, 
                              vv_prog_name,
                              vn_retcode,
                              vv_errbuf );
    IF vn_retcode != 0 THEN
       DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de se positionner dans le contexte O.A. :');
       DBMS_OUTPUT.PUT_LINE ('==> Utilisateur    : '||vv_user);
       DBMS_OUTPUT.PUT_LINE ('==> Responsabilite : '||vv_responsibility_ref);
       DBMS_OUTPUT.PUT_LINE ('==> Programme      : '||vv_prog_name);
       DBMS_OUTPUT.PUT_LINE (vv_errbuf);
       vb_lancement_trt := FALSE;
    END IF;

    -- Récupération des paramètres
    ------------------------------
    IF vb_lancement_trt THEN
       dka_tools_pkg.get_request_set_params ( pv_errbuf                 => vv_errbuf,
                                              pn_retcode                => vn_retcode,
                                              pn_application_id         => NULL,
                                              pn_request_set_id         => NULL,
                                              pn_request_set_program_id => NULL,
                                              pn_prog_application_id    => vn_prog_application_id,
                                              pn_program_id             => vn_program_id );

       IF vn_retcode != 0 THEN
          DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les paramètres :');
          DBMS_OUTPUT.PUT_LINE (vv_errbuf);
          vb_lancement_trt := FALSE;
       END IF;

       -- Initialisation des parametres
       --------------------------------
       -- Début modif EMA du 22/09/2006
       -- -- Début modif EMA du 21/10/2005
       -- dka_tools_pkg.tab_request_params(4) := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'YYYY/MM/DD HH24:MI:SS');
       -- vv_period_name                      := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'MON-YY');
       -- --dka_tools_pkg.tab_request_params(4) := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -2))), 'YYYY/MM/DD HH24:MI:SS');
       -- --vv_period_name                      := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -2))), 'MON-YY');
       -- -- Fin modif EMA du 21/10/2005
 
       dka_tools_pkg.tab_request_params(2) := v_ledger_id;--YWA-- a modif ledger_id
       dka_tools_pkg.tab_request_params(3) := vv_date;

       -- Fin modif EMA du 22/09/2006

    END IF;           

    -- Lancement du traitement
    --------------------------
    IF vb_lancement_trt THEN
       soumission_traitement;  
       DBMS_OUTPUT.PUT_LINE ('===============================================');
       DBMS_OUTPUT.PUT_LINE ('==  DKA : Etat déclaratif de la TVA dans GL  ==');
       DBMS_OUTPUT.PUT_LINE ('===============================================');
       DBMS_OUTPUT.PUT_LINE ('==> TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
       DBMS_OUTPUT.PUT_LINE ('==>            Code Société : '||vv_code_societe);--dka_tools_pkg.tab_request_params(2));
       DBMS_OUTPUT.PUT_LINE ('==> Date d''arrêté de l''état : '||dka_tools_pkg.tab_request_params(3));
       DBMS_OUTPUT.PUT_LINE ('==>          Fichier genere : '||vt_traitement(vn_traitement).program_name||'_'||
                             vt_traitement(vn_traitement).company_name||'_'||
                             vt_traitement(vn_traitement).period_name||'.out');
       DBMS_OUTPUT.PUT_LINE (chr(10));
       vn_trt_lances := vn_trt_lances + 1;
    END IF;

*/ --< JWYC


    ---------------------------------------------------------------------------------------------
    -- Lancement du traitement 'DKA : Etat justificatif de l'en-cours de TVA sur encaissement' --
    ---------------------------------------------------------------------------------------------
    -- Recherche de la responsabilité pour le lancement du traitement
    -----------------------------------------------------------------
	v_region_trt := v_region_main;
	
    dka_tools_pkg.get_parameter ('DKA_AR_JUST_TVA_ENC', 'AR_RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf);
    IF pn_retcode != 0 THEN
       :ret_code := 'FAILURE';
       RETURN;
    END IF;

    vv_responsibility_ref := rec_param.varchar2_value;


    -- initialisation des variables
    -------------------------------
    vv_prog_name     := 'DKA_AR_JUST_TVA_ENC';
    vb_lancement_trt := TRUE;
    vn_trt_a_lancer  := vn_trt_a_lancer + 1;

    -- Positionnement dans le contexte O.A.
    ---------------------------------------
    --vv_responsibility_name := REPLACE (vv_responsibility_ref, 'XXXX', '0001');
    positionnement_contexte ( vv_user, 
                              vv_responsibility_ref, 
                              vv_prog_name,
                              vn_retcode,
                              vv_errbuf );
    IF vn_retcode != 0 THEN
       DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de se positionner dans le contexte O.A. :');
       DBMS_OUTPUT.PUT_LINE ('==> Utilisateur    : '||vv_user);
       DBMS_OUTPUT.PUT_LINE ('==> Responsabilite : '||vv_responsibility_ref);
       DBMS_OUTPUT.PUT_LINE ('==> Programme      : '||vv_prog_name);
       DBMS_OUTPUT.PUT_LINE (vv_errbuf);
       vb_lancement_trt := FALSE;
    END IF;

    -- Récupération des paramètres
    ------------------------------
    IF vb_lancement_trt THEN
       dka_tools_pkg.get_request_set_params ( pv_errbuf                 => vv_errbuf,
                                              pn_retcode                => vn_retcode,
                                              pn_application_id         => NULL,
                                              pn_request_set_id         => NULL,
                                              pn_request_set_program_id => NULL,
                                              pn_prog_application_id    => vn_prog_application_id,
                                              pn_program_id             => vn_program_id );

       IF vn_retcode != 0 THEN
          DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les paramètres :');
          DBMS_OUTPUT.PUT_LINE (vv_errbuf);
          vb_lancement_trt := FALSE;
       END IF;

       -- Initialisation des parametres
       --------------------------------
       -- Début modif EMA du 22/09/2006
       -- -- Début modif EMA du 21/10/2005
       -- dka_tools_pkg.tab_request_params(4) := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'YYYY/MM/DD HH24:MI:SS');
       -- vv_period_name                      := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'MON-YY');
       -- --dka_tools_pkg.tab_request_params(4) := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -2))), 'YYYY/MM/DD HH24:MI:SS');
       -- --vv_period_name                      := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -2))), 'MON-YY');
       -- -- Fin modif EMA du 21/10/2005

       dka_tools_pkg.tab_request_params(2) := v_ledger_id;--YWA
       dka_tools_pkg.tab_request_params(3) := vv_date;

       -- Fin modif EMA du 22/09/2006

    END IF;           

    -- Lancement du traitement
    --------------------------
    IF vb_lancement_trt THEN
       soumission_traitement;
       DBMS_OUTPUT.PUT_LINE ('=====================================================================');
       DBMS_OUTPUT.PUT_LINE ('==  DKA : Etat justificatif de l''en-cours de TVA sur encaissement  ==');
       DBMS_OUTPUT.PUT_LINE ('=====================================================================');
       DBMS_OUTPUT.PUT_LINE ('==> TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
       DBMS_OUTPUT.PUT_LINE ('==>            Code société : '||vv_code_societe);--dka_tools_pkg.tab_request_params(2));
       DBMS_OUTPUT.PUT_LINE ('==> Date d''arrêté de l''état : '||dka_tools_pkg.tab_request_params(3));
       DBMS_OUTPUT.PUT_LINE ('==>          Fichier genere : '||vt_traitement(vn_traitement).program_name||'_'||
                             vt_traitement(vn_traitement).company_name||'_'||
                             vt_traitement(vn_traitement).period_name||'.out');
       DBMS_OUTPUT.PUT_LINE (chr(10));
       vn_trt_lances := vn_trt_lances + 1;
    END IF;



    --------------------------------------------------------------------------------------------
    -- Lancement du traitement 'DKA : Etat justificatif des comptes de TVA sur décaissement.' --
    --------------------------------------------------------------------------------------------
    -- Recherche de la responsabilité pour le lancement du traitement
    -----------------------------------------------------------------
    dka_tools_pkg.get_parameter ('DKA_RAPJUSTTVADEC', 'AP_RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf);
    IF pn_retcode != 0 THEN
       :ret_code := 'FAILURE';
       RETURN;
    END IF;

    vv_responsibility_ref := rec_param.varchar2_value;

    -- initialisation des variables
    -------------------------------
    vv_prog_name     := 'DKA_RAPJUSTTVADEC';
    vb_lancement_trt := TRUE;
    vn_trt_a_lancer  := vn_trt_a_lancer + 1;

    -- Positionnement dans le contexte O.A.
    ---------------------------------------
    --vv_responsibility_name := REPLACE (vv_responsibility_ref, 'XXXX', '0001');
    positionnement_contexte ( vv_user, 
                              vv_responsibility_ref, 
                              vv_prog_name,
                              vn_retcode,
                              vv_errbuf );
    IF vn_retcode != 0 THEN
       DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de se positionner dans le contexte O.A. :');
       DBMS_OUTPUT.PUT_LINE ('==> Utilisateur    : '||vv_user);
       DBMS_OUTPUT.PUT_LINE ('==> Responsabilite : '||vv_responsibility_ref);
       DBMS_OUTPUT.PUT_LINE ('==> Programme      : '||vv_prog_name);
       DBMS_OUTPUT.PUT_LINE (vv_errbuf);
       vb_lancement_trt := FALSE;
    END IF;

    -- Récupération des paramètres
    ------------------------------
    IF vb_lancement_trt THEN
       dka_tools_pkg.get_request_set_params ( pv_errbuf                 => vv_errbuf,
                                              pn_retcode                => vn_retcode,
                                              pn_application_id         => NULL,
                                              pn_request_set_id         => NULL,
                                              pn_request_set_program_id => NULL,
                                              pn_prog_application_id    => vn_prog_application_id,
                                              pn_program_id             => vn_program_id );

       IF vn_retcode != 0 THEN
          DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les paramètres :');
          DBMS_OUTPUT.PUT_LINE (vv_errbuf);
          vb_lancement_trt := FALSE;
       END IF;

       -- Initialisation des parametres
       --------------------------------
       -- Début modif EMA du 22/09/2006
       -- -- Début modif EMA du 21/10/2005
       -- dka_tools_pkg.tab_request_params(2) := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'YYYY/MM/DD HH24:MI:SS');
       -- vv_period_name                      := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'MON-YY');
       -- --dka_tools_pkg.tab_request_params(2) := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -2))), 'YYYY/MM/DD HH24:MI:SS');
       -- --vv_period_name                      := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -2))), 'MON-YY');
       -- -- Fin modif EMA du 21/10/2005

       dka_tools_pkg.tab_request_params(1) := v_ledger_id;--YWA
       dka_tools_pkg.tab_request_params(2) := vv_date;

       -- Fin modif EMA du 22/09/2006

    END IF;           

    -- Lancement du traitement
    --------------------------
    IF vb_lancement_trt THEN
       soumission_traitement;
       DBMS_OUTPUT.PUT_LINE ('===================================================================');
       DBMS_OUTPUT.PUT_LINE ('==  DKA : Etat justificatif des comptes de TVA sur décaissement  ==');
       DBMS_OUTPUT.PUT_LINE ('===================================================================');
       DBMS_OUTPUT.PUT_LINE ('==> TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
       DBMS_OUTPUT.PUT_LINE ('==>        Société : '||vv_code_societe);--dka_tools_pkg.tab_request_params(1));
       DBMS_OUTPUT.PUT_LINE ('==>           Date : '||dka_tools_pkg.tab_request_params(2));
       DBMS_OUTPUT.PUT_LINE ('==> Fichier genere : '||vt_traitement(vn_traitement).program_name||'_'||
                             vt_traitement(vn_traitement).company_name||'_'||
                             vt_traitement(vn_traitement).period_name||'.out');
       DBMS_OUTPUT.PUT_LINE (chr(10));
       vn_trt_lances := vn_trt_lances + 1;
    END IF;



    -------------------------------------------------------------------------------
    -- Lancement du traitement 'DKA : France - Déclaration de la TVA déductible' --
    -------------------------------------------------------------------------------
    -- Recherche de la responsabilité pour le lancement du traitement
    -----------------------------------------------------------------
    dka_tools_pkg.get_parameter ('DKA_RJETVADEDUC', 'AP_RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf);
    IF pn_retcode != 0 THEN
       :ret_code := 'FAILURE';
       RETURN;
    END IF;

    vv_responsibility_ref := rec_param.varchar2_value;

    -- initialisation des variables
    -------------------------------
    vv_prog_name     := 'DKA_RJETVADEDUC';
    vb_lancement_trt := TRUE;
    vn_trt_a_lancer  := vn_trt_a_lancer + 1;

    -- Positionnement dans le contexte O.A.
    ---------------------------------------
   -- vv_responsibility_name := REPLACE (vv_responsibility_ref, 'XXXX', '0001');
    positionnement_contexte ( vv_user, 
                              vv_responsibility_ref, 
                              vv_prog_name,
                              vn_retcode,
                              vv_errbuf );
    IF vn_retcode != 0 THEN
       DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de se positionner dans le contexte O.A. :');
       DBMS_OUTPUT.PUT_LINE ('==> Utilisateur    : '||vv_user);
       DBMS_OUTPUT.PUT_LINE ('==> Responsabilite : '||vv_responsibility_ref);
       DBMS_OUTPUT.PUT_LINE ('==> Programme      : '||vv_prog_name);
       DBMS_OUTPUT.PUT_LINE (vv_errbuf);
       vb_lancement_trt := FALSE;
    END IF;

    -- Récupération des paramètres
    ------------------------------
    IF vb_lancement_trt THEN
       dka_tools_pkg.get_request_set_params ( pv_errbuf                 => vv_errbuf,
                                              pn_retcode                => vn_retcode,
                                              pn_application_id         => NULL,
                                              pn_request_set_id         => NULL,
                                              pn_request_set_program_id => NULL,
                                              pn_prog_application_id    => vn_prog_application_id,
                                              pn_program_id             => vn_program_id );

       IF vn_retcode != 0 THEN
          DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les paramètres :');
          DBMS_OUTPUT.PUT_LINE (vv_errbuf);
          vb_lancement_trt := FALSE;
       END IF;

       -- Initialisation des parametres
       --------------------------------
       -- Début modif EMA du 22/09/2006
       -- -- Début modif EMA du 21/10/2005
       -- dka_tools_pkg.tab_request_params(2) := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'YYYY/MM/DD HH24:MI:SS');
       -- vv_period_name                      := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'MON-YY');
       -- --dka_tools_pkg.tab_request_params(2) := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -2))), 'YYYY/MM/DD HH24:MI:SS');
       -- --vv_period_name                      := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -2))), 'MON-YY');
       -- -- Fin modif EMA du 21/10/2005

       dka_tools_pkg.tab_request_params(1) := v_ledger_id;--YWA
       dka_tools_pkg.tab_request_params(2) := vv_date;

       -- Fin modif EMA du 22/09/2006

    END IF;           

    -- Lancement du traitement
    --------------------------
    IF vb_lancement_trt THEN
       soumission_traitement;
       DBMS_OUTPUT.PUT_LINE ('=======================================================');
       DBMS_OUTPUT.PUT_LINE ('==  DKA : France - Déclaration de la TVA déductible  ==');
       DBMS_OUTPUT.PUT_LINE ('=======================================================');
       DBMS_OUTPUT.PUT_LINE ('==> TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
       DBMS_OUTPUT.PUT_LINE ('==>             Société : '||vv_code_societe);--dka_tools_pkg.tab_request_params(1));
       DBMS_OUTPUT.PUT_LINE ('==> Date de déclaration : '||dka_tools_pkg.tab_request_params(2));
       DBMS_OUTPUT.PUT_LINE ('==>      Fichier genere : '||vt_traitement(vn_traitement).program_name||'_'||
                             vt_traitement(vn_traitement).company_name||'_'||
                             vt_traitement(vn_traitement).period_name||'.out');
       DBMS_OUTPUT.PUT_LINE (chr(10));
       vn_trt_lances := vn_trt_lances + 1;
    END IF;



    -----------------------------------------------------------------------------------------
    -- Lancement du traitement 'DKA : France - Déclaration détaillée de la TVA déductible' --
    -----------------------------------------------------------------------------------------
    -- Recherche de la responsabilité pour le lancement du traitement
    -----------------------------------------------------------------
    dka_tools_pkg.get_parameter ('DKA_JEFRTXDC', 'AP_RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf);
    IF pn_retcode != 0 THEN
       :ret_code := 'FAILURE';
       RETURN;
    END IF;

    vv_responsibility_ref := rec_param.varchar2_value;

    -- Initialisation des variables
    -------------------------------
    vv_prog_name := 'DKA_JEFRTXDC';

    -- Boucle de lecture sur les sociétés
    -------------------------------------
    OPEN cur_soc;
    LOOP
        FETCH cur_soc INTO rec_soc;
        EXIT WHEN cur_soc%NOTFOUND;

        vn_trt_a_lancer := vn_trt_a_lancer + 1;

        -- initialisation de la variable vb_lancement_trt
        -------------------------------------------------
        vb_lancement_trt := TRUE;
		
		v_region_trt :=  rec_soc.segment_name;--JWY artf07235613

        -- Positionnement dans le contexte O.A.
        ---------------------------------------
        --vv_responsibility_name := REPLACE (vv_responsibility_ref, 'XXXX', '0001');
        positionnement_contexte ( vv_user, 
                                  vv_responsibility_ref, 
                                  vv_prog_name,
                                  vn_retcode,
                                  vv_errbuf );
        IF vn_retcode != 0 THEN
           DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de se positionner dans le contexte O.A. :');
           DBMS_OUTPUT.PUT_LINE ('==> Utilisateur    : '||vv_user);
           DBMS_OUTPUT.PUT_LINE ('==> Responsabilite : '||vv_responsibility_ref);
           DBMS_OUTPUT.PUT_LINE ('==> Programme      : '||vv_prog_name);
           DBMS_OUTPUT.PUT_LINE (vv_errbuf);
           vb_lancement_trt := FALSE;
        END IF;

        -- Récupération des paramètres
        ------------------------------
        IF vb_lancement_trt THEN
           dka_tools_pkg.get_request_set_params ( pv_errbuf                 => vv_errbuf,
                                                  pn_retcode                => vn_retcode,
                                                  pn_application_id         => NULL,
                                                  pn_request_set_id         => NULL,
                                                  pn_request_set_program_id => NULL,
                                                  pn_prog_application_id    => vn_prog_application_id,
                                                  pn_program_id             => vn_program_id );

           IF vn_retcode != 0 THEN
              DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les paramètres :');
              DBMS_OUTPUT.PUT_LINE (vv_errbuf);
              vb_lancement_trt := FALSE;
           END IF;

           -- Initialisation des parametres
           --------------------------------
           -- Début modif EMA du 22/09/2006
           -- -- Début modif EMA du 21/10/2005
           -- dka_tools_pkg.tab_request_params(1) := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'YYYY/MM/DD HH24:MI:SS');
           -- --dka_tools_pkg.tab_request_params(1) := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -2))), 'YYYY/MM/DD HH24:MI:SS');
           -- vv_period_name                      := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'MON-YY');
           -- --vv_period_name                      := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -2))), 'MON-YY');
           -- -- Fin modif EMA du 21/10/2005

           dka_tools_pkg.tab_request_params(1) := vv_date;
           Dka_Tools_Pkg.tab_request_params(2) := v_chart_of_accounts_id;--YWA
           dka_tools_pkg.tab_request_params(3) := v_ledger_id;--YWA
           dka_tools_pkg.tab_request_params(4) := substr(rec_soc.segment_name, 1, 3);

           -- Fin modif EMA du 22/09/2006

        END IF;           

        -- Lancement du traitement
        --------------------------
        IF vb_lancement_trt THEN
           soumission_traitement;
           vt_traitement(vn_traitement).company_name := rec_soc.segment_name;
           DBMS_OUTPUT.PUT_LINE ('=================================================================');
           DBMS_OUTPUT.PUT_LINE ('==  DKA : France - Déclaration détaillée de la TVA déductible  ==');
           DBMS_OUTPUT.PUT_LINE ('=================================================================');
           DBMS_OUTPUT.PUT_LINE ('==> TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
           DBMS_OUTPUT.PUT_LINE ('==>   Date de déclaration : '||dka_tools_pkg.tab_request_params(1));
           DBMS_OUTPUT.PUT_LINE ('==>               Société : '||vv_code_societe);--dka_tools_pkg.tab_request_params(2));
           DBMS_OUTPUT.PUT_LINE ('==>                Région : '||dka_tools_pkg.tab_request_params(4));
           DBMS_OUTPUT.PUT_LINE ('==>        Fichier genere : '||vt_traitement(vn_traitement).program_name||'_'||
                                 vt_traitement(vn_traitement).company_name||'_'||
                                 vt_traitement(vn_traitement).period_name||'.out');
           DBMS_OUTPUT.PUT_LINE (chr(10));
           vn_trt_lances := vn_trt_lances + 1;
        END IF;

    END LOOP; -- fin boucle des sociétés

    CLOSE cur_soc;



    -------------------------------------------------------------------------
    -- Lancement du traitement 'DKA : Registre des règlements non lettrés' --
    -------------------------------------------------------------------------
    -- Recherche de la responsabilité pour le lancement du traitement
    -----------------------------------------------------------------
    dka_tools_pkg.get_parameter ('DKA_ARXCOA2', 'AR_RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf);
    IF pn_retcode != 0 THEN
       :ret_code := 'FAILURE';
       RETURN;
    END IF;

    vv_responsibility_ref := rec_param.varchar2_value;
	
	v_region_trt := v_region_main;--JWY artf07235613

    -- initialisation des variables
    -------------------------------
    vv_prog_name     := 'DKA_ARXCOA2';
    vb_lancement_trt := TRUE;
    vn_trt_a_lancer  := vn_trt_a_lancer + 1;

    -- Positionnement dans le contexte O.A.
    ---------------------------------------
    --vv_responsibility_name := REPLACE (vv_responsibility_ref, 'XXXX', '0001');
    positionnement_contexte ( vv_user, 
                              vv_responsibility_ref, 
                              vv_prog_name,
                              vn_retcode,
                              vv_errbuf );
    IF vn_retcode != 0 THEN
       DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de se positionner dans le contexte O.A. :');
       DBMS_OUTPUT.PUT_LINE ('==> Utilisateur    : '||vv_user);
       DBMS_OUTPUT.PUT_LINE ('==> Responsabilite : '||vv_responsibility_ref);
       DBMS_OUTPUT.PUT_LINE ('==> Programme      : '||vv_prog_name);
       DBMS_OUTPUT.PUT_LINE (vv_errbuf);
       vb_lancement_trt := FALSE;
    END IF;

    -- Récupération des paramètres
    ------------------------------
    IF vb_lancement_trt THEN
       /*dka_tools_pkg.get_request_set_params ( pv_errbuf                 => vv_errbuf,
                                              pn_retcode                => vn_retcode,
                                              pn_application_id         => NULL,
                                              pn_request_set_id         => NULL,
                                              pn_request_set_program_id => NULL,
                                              pn_prog_application_id    => vn_prog_application_id,
                                              pn_program_id             => vn_program_id );

       IF vn_retcode != 0 THEN
          DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les paramètres :');
          DBMS_OUTPUT.PUT_LINE (vv_errbuf);
          vb_lancement_trt := FALSE;
       END IF;*/--YWA

       -- Initialisation des parametres
       --------------------------------
       -- Début modif EMA du 22/09/2006
       -- -- Début modif EMA du 21/10/2005
       -- dka_tools_pkg.tab_request_params(6)  := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'YYYY/MM/DD HH24:MI:SS');
       -- --dka_tools_pkg.tab_request_params(6)  := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -2))), 'YYYY/MM/DD HH24:MI:SS');
       -- vv_period_name                       := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'MON-YY');
       -- --vv_period_name                       := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -2))), 'MON-YY');
       -- -- Fin modif EMA du 21/10/2005
        
       /*dka_tools_pkg.tab_request_params(1)  := v_chart_of_accounts_id;
       dka_tools_pkg.tab_request_params(3)  := v_ledger_id;
       dka_tools_pkg.tab_request_params(4)  := 'DETAIL';
       dka_tools_pkg.tab_request_params(6)  := vv_date;
       dka_tools_pkg.tab_request_params(7)  := v_currency_code;--'EUR'YWA
       dka_tools_pkg.tab_request_params(19) := vv_code_bande;--'0001'YWA*/

      Dka_Tools_Pkg.tab_request_params(2)  := 'DETAIL';
      Dka_Tools_Pkg.tab_request_params(4)  := vv_date; --TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'YYYY/MM/DD HH24:MI:SS');
      Dka_Tools_Pkg.tab_request_params(5)  := v_currency_code;--'EUR'YWA
      Dka_Tools_Pkg.tab_request_params(17) := vv_code_societe;--'0001'YWA
      Dka_Tools_Pkg.tab_request_params(18) := v_chart_of_accounts_id;
      Dka_Tools_Pkg.tab_request_params(19) := v_ledger_id;
      Dka_Tools_Pkg.tab_request_params(1)  := null;
      Dka_Tools_Pkg.tab_request_params(3)  := null;
      Dka_Tools_Pkg.tab_request_params(6)  := null;
      Dka_Tools_Pkg.tab_request_params(7)  := null;
      Dka_Tools_Pkg.tab_request_params(8)  := null;
      Dka_Tools_Pkg.tab_request_params(9)  := null;
      Dka_Tools_Pkg.tab_request_params(10) := null;
      Dka_Tools_Pkg.tab_request_params(11) := null;
      Dka_Tools_Pkg.tab_request_params(12) := null;
      Dka_Tools_Pkg.tab_request_params(13) := null;
      Dka_Tools_Pkg.tab_request_params(14) := null;
      Dka_Tools_Pkg.tab_request_params(15) := null;
      Dka_Tools_Pkg.tab_request_params(16) := 'O'; 
        
        
       -- Fin modif EMA du 22/09/2006


    END IF;           

    -- Lancement du traitement
    --------------------------
    IF vb_lancement_trt THEN
       soumission_traitement;
       DBMS_OUTPUT.PUT_LINE ('=================================================');
       DBMS_OUTPUT.PUT_LINE ('==  DKA : Registre des règlements non lettrés  ==');
       DBMS_OUTPUT.PUT_LINE ('=================================================');
       DBMS_OUTPUT.PUT_LINE ('==> TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
       DBMS_OUTPUT.PUT_LINE ('==>             Option format : '||Dka_Tools_Pkg.tab_request_params(4));
       DBMS_OUTPUT.PUT_LINE ('==> Date GL du règlement - Au : '||Dka_Tools_Pkg.tab_request_params(6));
       DBMS_OUTPUT.PUT_LINE ('==>               Code devise : '||Dka_Tools_Pkg.tab_request_params(5));
       DBMS_OUTPUT.PUT_LINE ('==>        Nom du client - De : '||Dka_Tools_Pkg.tab_request_params(8));
       DBMS_OUTPUT.PUT_LINE ('==>        Nom du client - A  : '||Dka_Tools_Pkg.tab_request_params(9));
       DBMS_OUTPUT.PUT_LINE ('==>     Numéro du client - De : '||Dka_Tools_Pkg.tab_request_params(10));
       DBMS_OUTPUT.PUT_LINE ('==>     Numéro de client - A  : '||Dka_Tools_Pkg.tab_request_params(11));
       DBMS_OUTPUT.PUT_LINE ('==>           Nom du lot - De : '||Dka_Tools_Pkg.tab_request_params(12));
       DBMS_OUTPUT.PUT_LINE ('==>           Nom du lot - A  : '||Dka_Tools_Pkg.tab_request_params(13));
       DBMS_OUTPUT.PUT_LINE ('==>   Nom origine du lot - De : '||Dka_Tools_Pkg.tab_request_params(14));
       DBMS_OUTPUT.PUT_LINE ('==>   Nom origine du lot - A  : '||Dka_Tools_Pkg.tab_request_params(15));
       DBMS_OUTPUT.PUT_LINE ('==>     Numéro règlement - De : '||Dka_Tools_Pkg.tab_request_params(16));
       DBMS_OUTPUT.PUT_LINE ('==>     Numéro règlement - A  : '||Dka_Tools_Pkg.tab_request_params(17));
       DBMS_OUTPUT.PUT_LINE ('==>            Fichier genere : '||vt_traitement(vn_traitement).program_name||'_'||
                             vt_traitement(vn_traitement).company_name||'_'||
                             vt_traitement(vn_traitement).period_name||'.out');
       DBMS_OUTPUT.PUT_LINE (chr(10));
       vn_trt_lances := vn_trt_lances + 1;
    END IF;--YWA


    -----------------------------------------------------------------------
    -- Lancement du traitement 'DKA : TVA Collectee : état préparatoire' --
    -----------------------------------------------------------------------
    -- Recherche de la responsabilité pour le lancement du traitement
    -----------------------------------------------------------------
    dka_tools_pkg.get_parameter ('DKA_TVACOLLECTEE', 'AR_RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf);
    IF pn_retcode != 0 THEN
       :ret_code := 'FAILURE';
       RETURN;
    END IF;

    vv_responsibility_ref := rec_param.varchar2_value;

    -- initialisation des variables
    -------------------------------
    vv_prog_name     := 'DKA_TVACOLLECTEE';
    vb_lancement_trt := TRUE;
    vn_trt_a_lancer  := vn_trt_a_lancer + 1;

    -- Positionnement dans le contexte O.A.
    ---------------------------------------
    --vv_responsibility_name := REPLACE (vv_responsibility_ref, 'XXXX', '0001');
    positionnement_contexte ( vv_user, 
                              vv_responsibility_ref, 
                              vv_prog_name,
                              vn_retcode,
                              vv_errbuf );
    IF vn_retcode != 0 THEN
       DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de se positionner dans le contexte O.A. :');
       DBMS_OUTPUT.PUT_LINE ('==> Utilisateur    : '||vv_user);
       DBMS_OUTPUT.PUT_LINE ('==> Responsabilite : '||vv_responsibility_ref);
       DBMS_OUTPUT.PUT_LINE ('==> Programme      : '||vv_prog_name);
       DBMS_OUTPUT.PUT_LINE (vv_errbuf);
       vb_lancement_trt := FALSE;
    END IF;

    -- Récupération des paramètres
    ------------------------------
    IF vb_lancement_trt THEN
       dka_tools_pkg.get_request_set_params ( pv_errbuf                 => vv_errbuf,
                                              pn_retcode                => vn_retcode,
                                              pn_application_id         => NULL,
                                              pn_request_set_id         => NULL,
                                              pn_request_set_program_id => NULL,
                                              pn_prog_application_id    => vn_prog_application_id,
                                              pn_program_id             => vn_program_id );

       IF vn_retcode != 0 THEN
          DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les paramètres :');
          DBMS_OUTPUT.PUT_LINE (vv_errbuf);
          vb_lancement_trt := FALSE;
       END IF;

       -- Initialisation des parametres
       --------------------------------
       dka_tools_pkg.tab_request_params(1) := v_ledger_id;--YWA
       dka_tools_pkg.tab_request_params(2) := vv_period_name;

       -- Début modif EMA du 22/09/2006 : La période est renseignée en début de procédure, la recherche de la période 
       --                                 devient obsolète
       -- -- Recherche de la dernière période
       -- -----------------------------------
       -- DECLARE
       --     CURSOR cur_periode IS
       --         SELECT period_name
       --         FROM   gl_period_statuses
       --         WHERE  application_id  = 101
       --         AND    set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID')
       --         -- Début modif EMA du 21/10/2005
       --         AND    end_date        < SYSDATE
       --         --AND    end_date        < SYSDATE - 30
       --         -- Fin modif EMA du 21/10/2005
       --         ORDER BY period_year DESC, period_num DESC;
       -- 
       -- BEGIN
       --     OPEN cur_periode;
       --     FETCH cur_periode INTO dka_tools_pkg.tab_request_params(2);
       --     CLOSE cur_periode;
       -- END;
       -- vv_period_name := dka_tools_pkg.tab_request_params(2);
       -- Fin modif EMA du 22/09/2006
    END IF;           

    -- Lancement du traitement
    --------------------------
    IF vb_lancement_trt THEN
       soumission_traitement;
       DBMS_OUTPUT.PUT_LINE ('===============================================');
       DBMS_OUTPUT.PUT_LINE ('==  DKA : TVA Collectee : état préparatoire  ==');
       DBMS_OUTPUT.PUT_LINE ('===============================================');
       DBMS_OUTPUT.PUT_LINE ('==> TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
       DBMS_OUTPUT.PUT_LINE ('==>      Code Société : '||vv_code_societe);--dka_tools_pkg.tab_request_params(1));
       DBMS_OUTPUT.PUT_LINE ('==> Période comptable : '||dka_tools_pkg.tab_request_params(2));
       DBMS_OUTPUT.PUT_LINE ('==>    Fichier genere : '||vt_traitement(vn_traitement).program_name||'_'||
                             vt_traitement(vn_traitement).company_name||'_'||
                             vt_traitement(vn_traitement).period_name||'.out');
       DBMS_OUTPUT.PUT_LINE (chr(10));
       vn_trt_lances := vn_trt_lances + 1;
    END IF;


    -----------------------------------------------
    -- Attente de la fin de tous les traitements --
    -----------------------------------------------
    -- Ouverture du fichier de commande 
    -----------------------------------
    DBMS_OUTPUT.PUT_LINE ('Ici1 AHU');
    vf_myfile := UTL_FILE.FOPEN (vv_utl_file_dir, vv_utl_file_name, 'w');
    UTL_FILE.PUT_LINE (vf_myfile, 'echo Vidage des fichiers');
    UTL_FILE.PUT_LINE (vf_myfile, 'rm '||vv_repertoire||'/DKA_*0001*.out');
    UTL_FILE.PUT_LINE (vf_myfile, 'echo Transfert des fichiers');
    UTL_FILE.FFLUSH (vf_myfile);
    DBMS_OUTPUT.PUT_LINE ('Ici2 AHU');

    FOR vn_indice IN 1..vn_traitement 
    LOOP
        IF NOT fnd_concurrent.wait_for_request (vt_traitement(vn_indice).request_id, vn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
           DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning');
        ELSE
           IF vv_dstatus = 'NORMAL' THEN
              DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
              DBMS_OUTPUT.PUT_LINE ('>>> Fichier genere '||vt_traitement(vn_indice).program_name||'_'||
                                    vt_traitement(vn_indice).company_name||'_'||
                                    vt_traitement(vn_indice).period_name||'.out');
              vv_line := 'cp $APPLCSF/$APPLOUT/o'||vt_traitement(vn_indice).request_id||'.out '||vv_repertoire||'/'||
                         vt_traitement(vn_indice).program_name||'_'||vt_traitement(vn_indice).company_name||'_'||
                         vt_traitement(vn_indice).period_name||'.out';
              UTL_FILE.PUT_LINE (vf_myfile, vv_line);
              UTL_FILE.FFLUSH (vf_myfile);
              vn_trt_normal := vn_trt_normal + 1;
           ELSIF vv_dstatus = 'WARNING' THEN
              DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning ');
              vn_trt_warning := vn_trt_warning + 1;
           ELSIF vv_dstatus != 'NORMAL' THEN
              DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Erreur ');
              vn_trt_erreur := vn_trt_erreur + 1;
           END IF;
        END IF;

       
    END LOOP;
    :ret_code := 'SUCCESS';
    -- Fermeture du fichier de commandes
    ------------------------------------
    UTL_FILE.FCLOSE_ALL;

    DBMS_OUTPUT.PUT_LINE (CHR(10)||'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements lances               : '||TO_CHAR(vn_trt_lances, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines normalement : '||TO_CHAR(vn_trt_normal, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));

    --- 02/06/2017 YWA artf2161965
    IF vn_trt_erreur > 0 THEN
      :ret_code := 'FAILURE';
    ELSIF vn_trt_warning > 0 THEN
      :ret_code := 'WARNING';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE (vv_prog_name || ' ==> ERREUR : ' || SQLERRM);
         :ret_code := 'FAILURE';
END;
/
COL :utl_file_name NEW_VALUE utl_file_name;
COL :code_societe    NEW_VALUE code_societe;
SELECT :utl_file_name
FROM   DUAL;
SELECT :code_societe
FROM   DUAL;
HOST sh &utl_file_name;
HOST ksh $DKA_TOP/bin/DKA_ETATVA0001_BOR.sh &code_societe

COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code
