/* Formatted on 05/16/2002 16:08 (Formatter Plus v4.5.2) */
---------------------------------------------------------------------------------------------------------------
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_GLYRLBGE.sql
-- DESCRIPTION      : Lancement automatique du traitement DKA_GLYRLBGE
---
--- AUTEUR           : CGEY
--- DATE DE CREATION : 16/10/2003
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------------------------
--- Version          : 1.1.0
--- Date             : 10/03/2017
--- Auteur           : YWA
--- Nature           : artf2114837 
---------------------------------------------------------------------------------------------------------------
--- Version          : 1.4.2
--- Date             : 26/03/2012
--- Auteur           : Maxime EGOT
--- Nature           : Correction artf2102701 et artf2084115 
---------------------------------------------------------------------------------------------------------------
--- Version          : 1.4.1
--- Date             : 26/03/2012
--- Auteur           : CDEF
--- Nature           : Correction de la requete de selection des sociétés
---------------------------------------------------------------------------------------------------------------
--- Version          : 1.4.0
--- Date             : 01/03/2011
--- Auteur           : TB
--- Nature           : Suppression de l'utilisation de la table Dka_Ibdsoc_I00ic_Tmp
---------------------------------------------------------------------------------------------------------------
--- Version          : 1.3.1
--- Date             : 01/07/2005
--- Auteur           : EMA
--- Nature           : La copie des fichiers générés se fait a partir du répertoire $APPLCSF/$APPLOUT au lieu
---                    de $APPLCSF/out
---------------------------------------------------------------------------------------------------------------
--- Version          : 1.3
--- Date             : 08/10/2004
--- Auteur           : SLE
--- Nature           : Portage spécifique pour projet PHENIX 2004
---                    Le Positionnement dans le contexte O.A. ne se fait plus qu'une seule fois.
---                    Init variable retour + décalage parametres
---------------------------------------------------------------------------------------------------------------
--- Version          : 1.1.0
--- Date             : 16/05/2004
--- Auteur           : EMA
--- Nature           : Ajout de la gestion du bordereau d'envoi
---                    Ajout de la gestion de table dka_auto_etat qui contient les parametres de lancement 
---                    de l'état dans le cas d'une relance avec des parametres différents de ceux par défaut.
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000

VAR ret_code      VARCHAR2(10);
VAR code_bande    VARCHAR2(6);
VAR utl_file_name VARCHAR2(512);

DECLARE
    vv_prog_name                     VARCHAR2 (30)  := 'DKA_GLYRLBGE';
    vn_tempo                         NUMBER         := 20;
    vv_rattrapage                    VARCHAR2 (1)   := '&&1';
    vv_code_bande                    VARCHAR2 (6)   := '&&2';
    vv_file_name                     VARCHAR2 (30)  := 'DKA_GLYRLBGE';
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
    vv_responsibility_leg            fnd_responsibility.responsibility_key%TYPE;
    vv_responsibility_ope            fnd_responsibility.responsibility_key%TYPE;
    vv_responsibility                fnd_responsibility.responsibility_key%TYPE;
    vv_responsibility_name           fnd_responsibility.responsibility_key%TYPE;
    vn_effective_period_num          gl_period_statuses.effective_period_num%TYPE;
    --vv_utl_file_dir                  v$parameter.value%TYPE;
    vv_utl_file_name                 VARCHAR2(250);
    vv_period_name                   VARCHAR2(50);
    vv_line                          VARCHAR2(250);
    vn_set_of_books_id               NUMBER;
    vv_book_type_code                fa_book_controls.book_type_code%TYPE;
    rec_param                        dka_parameters%ROWTYPE;
    vf_myfile                        UTL_FILE.FILE_TYPE;
    pn_retcode                       NUMBER;
    vb_lancement_trt                 BOOLEAN;
    vn_trt_a_lancer                  NUMBER:=0;
    vn_trt_lances                    NUMBER:=0;
    vn_trt_normal                    NUMBER:=0;
    vn_trt_erreur                    NUMBER:=0;
    vn_trt_warning                   NUMBER:=0;
    vv_param_table                   VARCHAR2(1);
    vv_LIVRE_PRIMAIRE                dka_auto_etat.livre_primaire%TYPE;
    vv_LIVRE_SECONDAIRE              dka_auto_etat.livre_secondaire%TYPE;
    vv_start_period_name             dka_auto_etat.start_period_name%TYPE;
    vv_sql_stmt                      VARCHAR2(32000);

    TYPE myrecord IS RECORD (
         request_id    NUMBER,
         program_name  VARCHAR2(250),
         company_name  VARCHAR2(25),
         period_name   VARCHAR2(15));

    TYPE mytable IS TABLE OF myrecord
         INDEX BY BINARY_INTEGER;

    TYPE myrecsoc IS RECORD (
         company_name  HR_OPERATING_UNITS.NAME%TYPE,
         entity        VARCHAR2(25),
         ledger_id     gl_ledgers.ledger_id%TYPE,
         ledger_name   gl_ledgers.name%TYPE,
         request_date  DATE,
         request_month NUMBER(2));

    TYPE mycursoc IS REF CURSOR;

    vt_traitement                    mytable;
    rec_soc                          myrecsoc;
    cur_soc                          mycursoc;

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
        DBMS_OUTPUT.PUT_LINE ('positionnement_contexte : Début');
        
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
                 pv_errbuf  := '==> Impossible de trouver les informations liees a l''utilisateur';
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
                 pv_errbuf  := '==> Impossible de trouver les informations liees a la responsabilite';
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
            WHERE  fcp.concurrent_program_name = pv_prog_name
            AND    fa.application_id           = fcp.application_id;
   
        EXCEPTION
            WHEN OTHERS THEN
                 pn_retcode := 2;
                 pv_errbuf  := '==> Impossible de trouver les informations liees au programme';
                 RETURN;
        END;

        -- Positionnement dans le contexte O.A.
        ---------------------------------------
        DBMS_OUTPUT.PUT_LINE ('positionnement_contexte : contexte O.A.');
        Fnd_Global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
                
        DBMS_OUTPUT.PUT_LINE ('positionnement_contexte : NLS_LANGUAGE');
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || Fnd_Profile.value ('ICX_LANGUAGE') || '''';
        pn_retcode := 0;
        
    END positionnement_contexte;


    ------------------------------------------
    -- Fonction de soumission du traitement --
    ------------------------------------------
    PROCEDURE soumission_traitement IS
    BEGIN
        vn_request_id := Fnd_Request.submit_request ( vv_prog_application_short_name, -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                      vv_prog_name,                   -- SHORT NAME DU TRAITEMENT
                                                      NULL,                           -- PROGRAM NAME
                                                      NULL,                           -- START
                                                      FALSE,                          -- SUB REQUEST
                                                      Dka_Tools_Pkg.tab_request_params(1), --ARGUMENT1
                                                      Dka_Tools_Pkg.tab_request_params(2), --ARGUMENT2
                                                      Dka_Tools_Pkg.tab_request_params(3), --ARGUMENT3
                                                      Dka_Tools_Pkg.tab_request_params(4), --ARGUMENT4
                                                      Dka_Tools_Pkg.tab_request_params(5), --ARGUMENT5
                                                      Dka_Tools_Pkg.tab_request_params(6), --ARGUMENT6
                                                      Dka_Tools_Pkg.tab_request_params(7), --ARGUMENT7
                                                      Dka_Tools_Pkg.tab_request_params(8), --ARGUMENT8
                                                      Dka_Tools_Pkg.tab_request_params(9), --ARGUMENT9
                                                      Dka_Tools_Pkg.tab_request_params(10), --ARGUMENT10
                                                      Dka_Tools_Pkg.tab_request_params(11), --ARGUMENT11
                                                      Dka_Tools_Pkg.tab_request_params(12), --ARGUMENT12
                                                      Dka_Tools_Pkg.tab_request_params(13), --ARGUMENT13
                                                      Dka_Tools_Pkg.tab_request_params(14), --ARGUMENT14
                                                      Dka_Tools_Pkg.tab_request_params(15), --ARGUMENT15
                                                      Dka_Tools_Pkg.tab_request_params(16), --ARGUMENT16
                                                      Dka_Tools_Pkg.tab_request_params(17), --ARGUMENT17
                                                      Dka_Tools_Pkg.tab_request_params(18), --ARGUMENT18
                                                      Dka_Tools_Pkg.tab_request_params(19), --ARGUMENT19
                                                      Dka_Tools_Pkg.tab_request_params(20), --ARGUMENT20
                                                      Dka_Tools_Pkg.tab_request_params(21), --ARGUMENT21
                                                      Dka_Tools_Pkg.tab_request_params(22), --ARGUMENT22
                                                      Dka_Tools_Pkg.tab_request_params(23), --ARGUMENT23
                                                      Dka_Tools_Pkg.tab_request_params(24), --ARGUMENT24
                                                      Dka_Tools_Pkg.tab_request_params(25), --ARGUMENT25
                                                      Dka_Tools_Pkg.tab_request_params(26), --ARGUMENT26
                                                      Dka_Tools_Pkg.tab_request_params(27), --ARGUMENT27
                                                      Dka_Tools_Pkg.tab_request_params(28), --ARGUMENT28
                                                      Dka_Tools_Pkg.tab_request_params(29), --ARGUMENT29
                                                      Dka_Tools_Pkg.tab_request_params(30), --ARGUMENT30
                                                      Dka_Tools_Pkg.tab_request_params(31), --ARGUMENT31
                                                      Dka_Tools_Pkg.tab_request_params(32), --ARGUMENT32
                                                      Dka_Tools_Pkg.tab_request_params(33), --ARGUMENT33
                                                      Dka_Tools_Pkg.tab_request_params(34), --ARGUMENT34
                                                      Dka_Tools_Pkg.tab_request_params(35), --ARGUMENT35
                                                      Dka_Tools_Pkg.tab_request_params(36), --ARGUMENT36
                                                      Dka_Tools_Pkg.tab_request_params(37), --ARGUMENT37
                                                      Dka_Tools_Pkg.tab_request_params(38), --ARGUMENT38
                                                      Dka_Tools_Pkg.tab_request_params(39), --ARGUMENT39
                                                      Dka_Tools_Pkg.tab_request_params(40), --ARGUMENT40
                                                      Dka_Tools_Pkg.tab_request_params(41), --ARGUMENT41
                                                      Dka_Tools_Pkg.tab_request_params(42), --ARGUMENT42
                                                      Dka_Tools_Pkg.tab_request_params(43), --ARGUMENT43
                                                      Dka_Tools_Pkg.tab_request_params(44), --ARGUMENT44
                                                      Dka_Tools_Pkg.tab_request_params(45), --ARGUMENT45
                                                      Dka_Tools_Pkg.tab_request_params(46), --ARGUMENT46
                                                      Dka_Tools_Pkg.tab_request_params(47), --ARGUMENT47
                                                      Dka_Tools_Pkg.tab_request_params(48), --ARGUMENT48
                                                      Dka_Tools_Pkg.tab_request_params(49), --ARGUMENT49
                                                      Dka_Tools_Pkg.tab_request_params(50), --ARGUMENT50
                                                      Dka_Tools_Pkg.tab_request_params(51), --ARGUMENT51
                                                      Dka_Tools_Pkg.tab_request_params(52), --ARGUMENT52
                                                      Dka_Tools_Pkg.tab_request_params(53), --ARGUMENT53
                                                      Dka_Tools_Pkg.tab_request_params(54), --ARGUMENT54
                                                      Dka_Tools_Pkg.tab_request_params(55), --ARGUMENT55
                                                      Dka_Tools_Pkg.tab_request_params(56), --ARGUMENT56
                                                      Dka_Tools_Pkg.tab_request_params(57), --ARGUMENT57
                                                      Dka_Tools_Pkg.tab_request_params(58), --ARGUMENT58
                                                      Dka_Tools_Pkg.tab_request_params(59), --ARGUMENT59
                                                      Dka_Tools_Pkg.tab_request_params(60), --ARGUMENT60
                                                      Dka_Tools_Pkg.tab_request_params(61), --ARGUMENT61
                                                      Dka_Tools_Pkg.tab_request_params(62), --ARGUMENT62
                                                      Dka_Tools_Pkg.tab_request_params(63), --ARGUMENT63
                                                      Dka_Tools_Pkg.tab_request_params(64), --ARGUMENT64
                                                      Dka_Tools_Pkg.tab_request_params(65), --ARGUMENT65
                                                      Dka_Tools_Pkg.tab_request_params(66), --ARGUMENT66
                                                      Dka_Tools_Pkg.tab_request_params(67), --ARGUMENT67
                                                      Dka_Tools_Pkg.tab_request_params(68), --ARGUMENT68
                                                      Dka_Tools_Pkg.tab_request_params(69), --ARGUMENT69
                                                      Dka_Tools_Pkg.tab_request_params(70), --ARGUMENT70
                                                      Dka_Tools_Pkg.tab_request_params(71), --ARGUMENT71
                                                      Dka_Tools_Pkg.tab_request_params(72), --ARGUMENT72
                                                      Dka_Tools_Pkg.tab_request_params(73), --ARGUMENT73
                                                      Dka_Tools_Pkg.tab_request_params(74), --ARGUMENT74
                                                      Dka_Tools_Pkg.tab_request_params(75), --ARGUMENT75
                                                      Dka_Tools_Pkg.tab_request_params(76), --ARGUMENT76
                                                      Dka_Tools_Pkg.tab_request_params(77), --ARGUMENT77
                                                      Dka_Tools_Pkg.tab_request_params(78), --ARGUMENT78
                                                      Dka_Tools_Pkg.tab_request_params(79), --ARGUMENT79
                                                      Dka_Tools_Pkg.tab_request_params(80), --ARGUMENT80
                                                      Dka_Tools_Pkg.tab_request_params(81), --ARGUMENT81
                                                      Dka_Tools_Pkg.tab_request_params(82), --ARGUMENT82
                                                      Dka_Tools_Pkg.tab_request_params(83), --ARGUMENT83
                                                      Dka_Tools_Pkg.tab_request_params(84), --ARGUMENT84
                                                      Dka_Tools_Pkg.tab_request_params(85), --ARGUMENT85
                                                      Dka_Tools_Pkg.tab_request_params(86), --ARGUMENT86
                                                      Dka_Tools_Pkg.tab_request_params(87), --ARGUMENT87
                                                      Dka_Tools_Pkg.tab_request_params(88), --ARGUMENT88
                                                      Dka_Tools_Pkg.tab_request_params(89), --ARGUMENT89
                                                      Dka_Tools_Pkg.tab_request_params(90), --ARGUMENT90
                                                      Dka_Tools_Pkg.tab_request_params(91), --ARGUMENT91
                                                      Dka_Tools_Pkg.tab_request_params(92), --ARGUMENT92
                                                      Dka_Tools_Pkg.tab_request_params(93), --ARGUMENT93
                                                      Dka_Tools_Pkg.tab_request_params(94), --ARGUMENT94
                                                      Dka_Tools_Pkg.tab_request_params(95), --ARGUMENT95
                                                      Dka_Tools_Pkg.tab_request_params(96), --ARGUMENT96
                                                      Dka_Tools_Pkg.tab_request_params(97), --ARGUMENT97
                                                      Dka_Tools_Pkg.tab_request_params(98), --ARGUMENT98
                                                      Dka_Tools_Pkg.tab_request_params(99), --ARGUMENT99
                                                      Dka_Tools_Pkg.tab_request_params(100) --ARGUMENT100
                                                      );
        vn_traitement := vn_traitement + 1;
        vt_traitement(vn_traitement).request_id   := vn_request_id;
        vt_traitement(vn_traitement).program_name := vv_file_name;
        vt_traitement(vn_traitement).company_name := rec_soc.company_name;
        vt_traitement(vn_traitement).period_name  := vv_period_name;
        COMMIT;

        IF vn_request_id = 0 THEN
           DBMS_OUTPUT.PUT_LINE ('Impossible de lancer le Traitement ');
           DBMS_OUTPUT.PUT_LINE (vv_errbuf);
        END IF;

    END;

    --------------------------------------------
    -- Fonction de vérification de période GL --
    --------------------------------------------
    FUNCTION verif_period_GL ( pn_set_of_books_id NUMBER,
                               pv_period_name     VARCHAR2 ) RETURN BOOLEAN
    IS
        vv_dummy                         VARCHAR2(1);
    BEGIN
        BEGIN
            SELECT 'X'
            INTO   vv_dummy
            FROM   gl_period_statuses
            WHERE  application_id  = 101
            AND    set_of_books_id = pn_set_of_books_id
            AND    period_name     = pv_period_name
            AND    closing_status IN ('C', 'O', 'P', 'F');
            
        EXCEPTION
            WHEN OTHERS THEN
                 DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les parametres :');
                 DBMS_OUTPUT.PUT_LINE ('Période '||pv_period_name||' inexistante pour la société '||rec_soc.company_name);
                 RETURN FALSE;
        END;

        RETURN TRUE;
    END;

BEGIN
    
    vv_user := Fnd_Profile.VALUE('USERNAME');
    :code_bande := vv_code_bande;  -- V1.1.0
    
    /*
    -----------------------------------------------------------------------------
    -- Recherche du répertoire dans lequel sera généré le fichier de commandes --
    -----------------------------------------------------------------------------
    BEGIN
        SELECT value
        INTO   vv_utl_file_dir
        FROM   v$parameter
        WHERE  name = 'utl_file_dir';

        IF INSTR(vv_utl_file_dir, ',') != 0 THEN
           vv_utl_file_dir := SUBSTR(vv_utl_file_dir, 1, INSTR(vv_utl_file_dir, ',')-1);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE ('Impossible de récupérer le répertoire de réation des fichiers');
             :ret_code := 'FAILURE';
             RETURN;
    END;*/

    vv_utl_file_name := 'DKA_GLYRLBGE.sh';
    :utl_file_name := '$REP_DATA/editions_legales'||'/'||vv_utl_file_name;

    ----------------------------------------------------------
    -- Recherche des parametres dans la table dka_auto_etat --
    ----------------------------------------------------------
    BEGIN
        SELECT 'O',
               NVL(LIVRE_PRIMAIRE, 'N'),
               NVL(LIVRE_SECONDAIRE, 'N'),
               start_period_name
        INTO   vv_param_table,
               vv_LIVRE_PRIMAIRE,
               vv_LIVRE_SECONDAIRE,
               vv_start_period_name
        FROM   dka_auto_etat
        WHERE  program_short_name = vv_prog_name
        AND    ( LIVRE_PRIMAIRE IS NOT NULL  OR
                 LIVRE_SECONDAIRE         IS NOT NULL )
        AND    start_period_name IS NOT NULL;

        DBMS_OUTPUT.PUT_LINE('**********************************************************************');
        DBMS_OUTPUT.PUT_LINE('ATTENTION : ');
        DBMS_OUTPUT.PUT_LINE('LES PARAMETRES PAR DEFAUT SONT REMPLACES PAR LES PARAMETRES SUIVANTS :');
        DBMS_OUTPUT.PUT_LINE('==> Edition pour l''entité opérationnelle : '||vv_LIVRE_PRIMAIRE);
        DBMS_OUTPUT.PUT_LINE('==>         Edition pour l''entité légale : '||vv_LIVRE_SECONDAIRE);
        DBMS_OUTPUT.PUT_LINE('==>                              Période : '||vv_start_period_name);
        DBMS_OUTPUT.PUT_LINE('**********************************************************************');
        DBMS_OUTPUT.PUT_LINE(CHR(10));

    EXCEPTION
        WHEN OTHERS THEN
             vv_param_table           := 'N';
             vv_LIVRE_PRIMAIRE        := 'N';
             vv_LIVRE_SECONDAIRE      := 'N';
             vv_start_period_name     := NULL;
    END;

    ----------------------------
    -- LANCEMENT DES ETATS GL --
    ----------------------------
    -- Recherche de la responsabilité pour le lancement du traitement
    -----------------------------------------------------------------
    Dka_Tools_Pkg.get_parameter ('DKA_GLYRLBGE', 'GL_LEGAL_RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf);
    IF pn_retcode != 0 THEN
       :ret_code := 'FAILURE';
       RETURN;
    END IF;
    vv_responsibility_leg := rec_param.varchar2_value;

    Dka_Tools_Pkg.get_parameter ('DKA_GLYRLBGE', 'GL_RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf);
    IF pn_retcode != 0 THEN
       :ret_code := 'FAILURE';
       RETURN;
    END IF;
    vv_responsibility_ope := rec_param.varchar2_value;

    ---------------------------------------------------------------
    -- Automatisation du traitement 'DKA : Balance grand format' --
    ---------------------------------------------------------------
    vv_prog_name := 'DKA_GLYRLBGE';
    vv_repertoire := '$REP_DATA/editions_legales/'||vv_prog_name;

    -- Construction de la requete sql
    ---------------------------------
    DBMS_OUTPUT.PUT_LINE ('Construction de la requete sql');
    vv_sql_stmt :=  ' SELECT '||
                    ' substr(gl.short_name,1,4) COMPANY_NAME, '||
                    ' DECODE(gl.ledger_category_code, ''PRIMARY'', ''OPERATIONNELLE'', ''LEGALE'') ENTITY, '||
                    ' gl.ledger_id , '||
                    ' gl.name , '||
                    ' SYSDATE request_date, '||
                    ' TO_NUMBER(TO_CHAR(SYSDATE, ''MM'')) request_month '||
                    ' FROM fnd_profile_options_vl fpo, '||
                    ' fnd_profile_option_values fpov, '||
                    ' fnd_responsibility_vl fr, '||
                    ' gl_access_sets_v gas, '||
                    ' gl_access_set_assignments gasa, '||
                    ' gl_ledgers gl '||
                    ' WHERE profile_option_name = ''GL_ACCESS_SET_ID'' '||
                    ' AND fpo.PROFILE_OPTION_ID = fpov.profile_option_id '||
                    ' AND fpov.level_id = 10003 '||
                    ' AND fpov.level_value = fr.RESPONSIBILITY_ID '||
                    ' AND gas.access_set_id = fpov.PROFILE_OPTION_VALUE '||
                    ' AND gasa.access_set_id = gas.access_set_id '||
                    ' AND gasa.ledger_id = gl.ledger_id '||
                    ' AND ledger_category_code != ''NONE'' ';		   
				   
    IF vv_param_table = 'O' THEN
       vv_sql_stmt := vv_sql_stmt||
                      ' AND   ((DECODE(gl.ledger_category_code, ''PRIMARY'', ''OPERATIONNELLE'', ''LEGALE'') = ''OPERATIONNELLE'' '||
                      '         AND '''||vv_LIVRE_PRIMAIRE||''' = ''O'' '||
                      '         AND fr.responsibility_name = '''||vv_responsibility_ope||''') OR '||
                      '        (DECODE(gl.ledger_category_code, ''PRIMARY'', ''OPERATIONNELLE'', ''LEGALE'') = ''LEGALE'' '||
                      '         AND '''||vv_LIVRE_SECONDAIRE||''' = ''O'' '||
                      '         AND fr.responsibility_name = '''||vv_responsibility_leg||''' )) ';
    ELSE
       IF vv_rattrapage = 'N' THEN
          IF TO_NUMBER(TO_CHAR(SYSDATE, 'MM')) BETWEEN 1 AND 6 THEN
             vv_sql_stmt := vv_sql_stmt||
                            ' AND fr.responsibility_name = '''|| vv_responsibility_ope ||''' ';--YWA  artf2114837 
          ELSE
             vv_sql_stmt := vv_sql_stmt||
                            ' AND fr.responsibility_name = '''||vv_responsibility_leg||''' ';
          END IF;
       ELSE
          vv_sql_stmt := vv_sql_stmt||
                         ' AND fr.responsibility_name = '''||vv_responsibility_leg||''' ';
       END IF;
    END IF;
    vv_sql_stmt := vv_sql_stmt||
                   ' ORDER BY substr(gl.short_name,1,4) ';
     
     DBMS_OUTPUT.PUT_LINE (substr(vv_sql_stmt,1,255));
     DBMS_OUTPUT.PUT_LINE (substr(vv_sql_stmt,1+255,255));
     DBMS_OUTPUT.PUT_LINE (substr(vv_sql_stmt,1+2*255,255));
     DBMS_OUTPUT.PUT_LINE (substr(vv_sql_stmt,1+3*255,255));
     DBMS_OUTPUT.PUT_LINE (substr(vv_sql_stmt,1+4*255,255));
     
    DBMS_OUTPUT.PUT_LINE ('Debut curseur cur_soc');
    OPEN cur_soc FOR vv_sql_stmt;
    LOOP
        FETCH cur_soc INTO rec_soc;
        EXIT WHEN cur_soc%NOTFOUND;

        vn_trt_a_lancer := vn_trt_a_lancer + 1;

        -- initialisation de la variable vb_lancement_trt
        -------------------------------------------------
        vb_lancement_trt := TRUE;
	
   	  -- PHENIX 2004 
   	  -- Positionnement dans le contexte O.A.
        ---------------------------------------
        IF rec_soc.entity = 'OPERATIONNELLE' THEN
           vv_responsibility_name := vv_responsibility_ope;
           vv_prog_name           := 'DKA_GLYRLBGE';
        ELSE
           vv_responsibility_name := vv_responsibility_leg;
           vv_prog_name           := 'GLYRLBGE';
        END IF;
        
        positionnement_contexte ( vv_user, 
                                  vv_responsibility_name, 
                                  vv_prog_name,
                                  vn_retcode,
                                  vv_errbuf );
        IF vn_retcode != 0 THEN
           DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de se positionner dans le contexte O.A. :');
           DBMS_OUTPUT.PUT_LINE ('==> Utilisateur    : '||vv_user);
           DBMS_OUTPUT.PUT_LINE ('==> Responsabilite : '||vv_responsibility_name);
           DBMS_OUTPUT.PUT_LINE ('==> Programme      : '||vv_prog_name);
           DBMS_OUTPUT.PUT_LINE (vv_errbuf);
           vb_lancement_trt := FALSE;
        END IF;
	
        -- Récupération des parametres
        ------------------------------
        DBMS_OUTPUT.PUT_LINE('Récupération des parametres');
        IF vb_lancement_trt THEN    
           Dka_Tools_Pkg.get_request_set_params(pv_errbuf => vv_errbuf,
                                                 pn_retcode =>  vn_retcode,
                                                 pn_application_id =>  NULL,
                                                 pn_request_set_id =>  NULL,
                                                 pn_request_set_program_id =>  NULL,
                                                 pn_prog_application_id =>  vn_prog_application_id,
                                                 pn_program_id =>  vn_program_id);
       
           IF vn_retcode != 0 THEN
              DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les parametres :');
              DBMS_OUTPUT.PUT_LINE (vv_errbuf);
              vb_lancement_trt := FALSE;
           END IF;

           -- Initialisation des parametres
           --------------------------------
           DBMS_OUTPUT.PUT_LINE('Initialisation des parametres');
           IF rec_soc.entity = 'OPERATIONNELLE' THEN
              
              Dka_Tools_Pkg.tab_request_params(2) := rec_soc.ledger_name;
              Dka_Tools_Pkg.tab_request_params(3) := rec_soc.company_name;
              Dka_Tools_Pkg.tab_request_params(5) := rec_soc.ledger_id;
              Dka_Tools_Pkg.tab_request_params(6) := 'EUR';
              Dka_Tools_Pkg.tab_request_params(11) := '0';
              Dka_Tools_Pkg.tab_request_params(12) := '809200';
              Dka_Tools_Pkg.tab_request_params(13) := '3';
           ELSE
              Dka_Tools_Pkg.tab_request_params(2) := rec_soc.ledger_name;
              Dka_Tools_Pkg.tab_request_params(3) := rec_soc.ledger_id;
              Dka_Tools_Pkg.tab_request_params(4) := 'EUR';
              Dka_Tools_Pkg.tab_request_params(9) := '0';
              Dka_Tools_Pkg.tab_request_params(10) := '809200';
              Dka_Tools_Pkg.tab_request_params(11) := rec_soc.company_name;
              Dka_Tools_Pkg.tab_request_params(12) := '3';
           END IF;
           -- FIN PHENIX 2004

           -- Recherche de la période
           --------------------------
           DBMS_OUTPUT.PUT_LINE('Recherche de la période');
           IF vv_param_table = 'O' THEN
              IF rec_soc.entity = 'OPERATIONNELLE' THEN
                 vn_set_of_books_id := rec_soc.ledger_id; -- PHENIX 2004
                 DBMS_OUTPUT.PUT_LINE('ledger_id = ' || vn_set_of_books_id);
                 vv_period_name     := vv_start_period_name;
                 IF NOT verif_period_GL (vn_set_of_books_id, vv_period_name) THEN
                    vb_lancement_trt := FALSE;
                 END IF;
                 Dka_Tools_Pkg.tab_request_params(10) := vv_period_name; -- PHENIX 2004
              ELSE
                 vn_set_of_books_id := rec_soc.ledger_id;
                 vv_period_name     := vv_start_period_name;
                 DBMS_OUTPUT.PUT_LINE('ledger_id = ' || vn_set_of_books_id);
                 IF NOT verif_period_GL (vn_set_of_books_id, vv_period_name) THEN
                    vb_lancement_trt := FALSE;
                 END IF;
                 Dka_Tools_Pkg.tab_request_params(8) := vv_period_name;
              END IF;
           ELSE
              IF rec_soc.entity = 'OPERATIONNELLE' THEN
                 vn_set_of_books_id := rec_soc.ledger_id; -- PHENIX 2004
                 DBMS_OUTPUT.PUT_LINE('ledger_id = ' || vn_set_of_books_id);
                 vv_period_name := 'DEC-'||SUBSTR(TO_CHAR(rec_soc.request_date, 'YYYY')-1, 3);
                 IF NOT verif_period_GL (vn_set_of_books_id, vv_period_name) THEN
                    vb_lancement_trt := FALSE;
                 END IF;
                 Dka_Tools_Pkg.tab_request_params(10) := vv_period_name; -- PHENIX 2004
              ELSE
                 vn_set_of_books_id := rec_soc.ledger_id;
                 DBMS_OUTPUT.PUT_LINE('ledger_id = ' || vn_set_of_books_id);
                 IF vv_rattrapage = 'N' THEN
                    vv_period_name := 'JUN-'||SUBSTR(TO_CHAR(rec_soc.request_date, 'YYYY'), 3);
                    IF NOT verif_period_GL (vn_set_of_books_id, vv_period_name) THEN
                       vb_lancement_trt := FALSE;
                    END IF;
                    Dka_Tools_Pkg.tab_request_params(8) := vv_period_name;
                 ELSE
                    vv_period_name := 'JUN-'||SUBSTR(TO_CHAR(rec_soc.request_date, 'YYYY')-1, 3);
                    IF NOT verif_period_GL (vn_set_of_books_id, vv_period_name) THEN
                       vb_lancement_trt := FALSE;
                    END IF;
                    Dka_Tools_Pkg.tab_request_params(8) := vv_period_name;
                 END IF;
              END IF;
           END IF;
        END IF;

        -- Lancement du traitement
        --------------------------
        DBMS_OUTPUT.PUT_LINE('Lancement du traitement');
        IF vb_lancement_trt THEN
           soumission_traitement;
           DBMS_OUTPUT.PUT_LINE (CHR(10)||'TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
           IF rec_soc.entity = 'OPERATIONNELLE' THEN
              -- PHENIX 2004
              DBMS_OUTPUT.PUT_LINE ('==> DKA : Entite comptable  : '||Dka_Tools_Pkg.tab_request_params(2));
              DBMS_OUTPUT.PUT_LINE ('==>                 Société : '||Dka_Tools_Pkg.tab_request_params(3)); 
              DBMS_OUTPUT.PUT_LINE ('==>       Nom de la période : '||Dka_Tools_Pkg.tab_request_params(10));
              DBMS_OUTPUT.PUT_LINE ('==>             Compte - De : '||Dka_Tools_Pkg.tab_request_params(11));
              DBMS_OUTPUT.PUT_LINE ('==>              Compte - A : '||Dka_Tools_Pkg.tab_request_params(12));
              DBMS_OUTPUT.PUT_LINE ('==>                  Devise : '||Dka_Tools_Pkg.tab_request_params(6));
              DBMS_OUTPUT.PUT_LINE ('==>               Précision : '||Dka_Tools_Pkg.tab_request_params(13));
              -- FIN PHENIX 2004
           ELSE
              DBMS_OUTPUT.PUT_LINE ('==>                  Entite comptable : '||Dka_Tools_Pkg.tab_request_params(2));
              DBMS_OUTPUT.PUT_LINE ('==>                 Nom de la période : '||Dka_Tools_Pkg.tab_request_params(8));
              DBMS_OUTPUT.PUT_LINE ('==>                       Compte - De : '||Dka_Tools_Pkg.tab_request_params(9));
              DBMS_OUTPUT.PUT_LINE ('==>                        Compte - A : '||Dka_Tools_Pkg.tab_request_params(10));
              DBMS_OUTPUT.PUT_LINE ('==>            Segment d''équilibrage : '||Dka_Tools_Pkg.tab_request_params(11));
              DBMS_OUTPUT.PUT_LINE ('==>                            Devise : '||Dka_Tools_Pkg.tab_request_params(4));
              DBMS_OUTPUT.PUT_LINE ('==>                         Précision : '||Dka_Tools_Pkg.tab_request_params(12));
           END IF;
           DBMS_OUTPUT.PUT_LINE ('==>                    Fichier genere : '||vt_traitement(vn_traitement).program_name||'_'||
                                 vt_traitement(vn_traitement).company_name||'_'||
                                 vt_traitement(vn_traitement).period_name||'.out');
           DBMS_OUTPUT.PUT_LINE (CHR(10));
           vn_trt_lances := vn_trt_lances + 1;
        END IF;

    END LOOP; -- fin boucle des sociétés

    CLOSE cur_soc;

    -- Ouverture du fichier de commande 
    -----------------------------------
    DBMS_OUTPUT.PUT_LINE('Ouverture du fichier de commande ');
    vf_myfile := UTL_FILE.FOPEN ('DKA_EDITIONS_LEGALES', vv_utl_file_name, 'w');
    UTL_FILE.PUT_LINE (vf_myfile, 'echo Vidage des fichiers');
    UTL_FILE.PUT_LINE (vf_myfile, 'rm '||vv_repertoire||'/'||vv_file_name||'*.*');
    UTL_FILE.PUT_LINE (vf_myfile, 'echo Transfert des fichiers');
    UTL_FILE.FFLUSH (vf_myfile);

    FOR vn_indice IN 1..vn_traitement 
    LOOP
        IF NOT Fnd_Concurrent.wait_for_request (vt_traitement(vn_indice).request_id, vn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
           DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning');
        ELSE
           IF vv_dstatus = 'NORMAL' THEN
              DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
              DBMS_OUTPUT.PUT_LINE ('>>> Fichier genere '||vt_traitement(vn_indice).program_name||'_'||
                                    vt_traitement(vn_indice).company_name||'_'||
                                    vt_traitement(vn_indice).period_name||'.out');
              -- Début modification EMA du 01/07/2005
              -- vv_line := 'cp $APPLCSF/out/o'||vt_traitement(vn_indice).request_id||'.out '||vv_repertoire||'/'||
              --            vt_traitement(vn_indice).program_name||'_'||vt_traitement(vn_indice).company_name||'_'||
              --            vt_traitement(vn_indice).period_name||'.out';
              vv_line := 'cp $APPLCSF/$APPLOUT/o'||vt_traitement(vn_indice).request_id||'.out '||vv_repertoire||'/'||
                         vt_traitement(vn_indice).program_name||'_'||vt_traitement(vn_indice).company_name||'_'||
                         vt_traitement(vn_indice).period_name||'.out';
              -- Fin modification EMA du 01/07/2005
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

     	  :ret_code := 'SUCCESS';
    END LOOP;

    -- Fermeture du fichier de commandes
    ------------------------------------
    UTL_FILE.FCLOSE_ALL;

    DBMS_OUTPUT.PUT_LINE (CHR(10)||'==> Nombre de traitements a lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements lances               : '||TO_CHAR(vn_trt_lances, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines normalement : '||TO_CHAR(vn_trt_normal, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));

    -- Remise a jour de la table dka_auto_etat
    ------------------------------------------
    BEGIN
        UPDATE dka_auto_etat
        SET    LIVRE_PRIMAIRE = NULL,
               LIVRE_SECONDAIRE         = NULL,
               start_period_name     = NULL,
               end_period_name       = NULL,
               last_updated_by       = Fnd_Profile.VALUE('USER_ID'),
               last_update_date      = SYSDATE
        WHERE  program_short_name    = 'DKA_GLYRLBGE';

        COMMIT;
    END;

EXCEPTION
    WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE (vv_prog_name || ' ==> ERREUR : ' || SQLERRM);
         :ret_code := 'FAILURE';
END;
/
COL :utl_file_name NEW_VALUE utl_file_name;
COL :code_bande    NEW_VALUE code_bande;
SELECT :utl_file_name
FROM   DUAL;
SELECT :code_bande
FROM   DUAL;
HOST ls &utl_file_name;
HOST sh &utl_file_name;
HOST ksh $DKA_TOP/bin/DKA_GLYRLBGE_BOR.sh &code_bande

COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code
