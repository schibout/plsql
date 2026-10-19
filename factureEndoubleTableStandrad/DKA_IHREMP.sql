---------------------------------------------------------------------------------------------------------------
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_AUTO_APXINAGE.sql
-- DESCRIPTION      : Lancement automatique du traitement DKA_APXINAGE
--
-- AUTEUR           : E.Matuszewski
-- DATE DE CREATION : 28/01/2010
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------------------------
-- Date        Qui  Commentaires
---------------------------------------------------------------------------------------------------------------
-- 09/02/2010  EMA  Modification des paramètres de lancement de l'état "DKA : Balance âgée fournisseurs"
--                  - Détails facture         : Oui
--                  - Détails sites           : Oui
--                  - Factures comptabilisées : Tous
---------------------------------------------------------------------------------------------------------------
-- 10/03/2010  EMA  Modification des paramètres de lancement de l'état "DKA : Balance âgée fournisseurs"
--                  - Factures comptabilisées : Oui
--                  - Modification de l'ordre des paramètres
---------------------------------------------------------------------------------------------------------------
-- 01/03/2011  TB  Suppression de l'utilisation de la table Dka_Ibdsoc_I00ic_Tmp
---------------------------------------------------------------------------------------------------------------
-- 08/02/2012  EMA Correction de la requête dynamique
-- 01/12/2016  PBR correction dans le cadre de l'artifact artf2056876
-- 06/01/2016  YWA correction dans le cadre de l'artifact artf2075460  
-- 29/06/2017  OBE artf2182814 : ETA001 - Responsabilités utilisées
-- 29/01/2017  SFA artf3062543 : INC0276647 - ETA001 - Balance âgée fournisseurs - Correction Automate
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000

VAR ret_code      VARCHAR2(10);

DECLARE
    vv_prog_name                     VARCHAR2 (30)  := 'DKA_APXINAGE';
    vn_tempo                         NUMBER         := 20;
    vv_user                          VARCHAR2 (80);
    vv_errbuf                        VARCHAR2 (500) := NULL;
    vn_retcode                       NUMBER         := 0;
    vn_traitement                    NUMBER         := 0;
    vn_prog_application_id           fnd_concurrent_programs.application_id%TYPE;
    vv_prog_application_short_name   fnd_application.application_short_name%TYPE;
    vn_program_id                    fnd_concurrent_programs.concurrent_program_id%TYPE;
    vn_class_application_id          fnd_concurrent_programs.class_application_id%TYPE;
    vn_concurrent_class_id           fnd_concurrent_programs.concurrent_class_id%TYPE;
    vn_responsibility_id             NUMBER (15);
    vn_application_id                NUMBER (15);
    vn_user_id                       NUMBER (15);
    vn_conc_request_id               NUMBER (15);
    vn_request_id                    NUMBER (15);
    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
    vv_responsibility_ref            fnd_responsibility.responsibility_key%TYPE;
    vv_responsibility                fnd_responsibility.responsibility_key%TYPE;
    vv_responsibility_name           fnd_responsibility.responsibility_key%TYPE;
    vv_date_ref                      VARCHAR2(50);
    rec_param                        dka_parameters%ROWTYPE;
    pn_retcode                       NUMBER;
    vb_lancement_trt                 BOOLEAN;
    vn_trt_a_lancer                  NUMBER:=0;
    vn_trt_lances                    NUMBER:=0;
    vn_trt_normal                    NUMBER:=0;
    vn_trt_erreur                    NUMBER:=0;
    vn_trt_warning                   NUMBER:=0;
    vv_param_table                   VARCHAR2(1);
    vv_LIVRE_PRIMAIRE                dka_auto_etat.LIVRE_PRIMAIRE%TYPE;
    vv_LIVRE_SECONDAIRE              dka_auto_etat.LIVRE_SECONDAIRE%TYPE;
    vv_start_period_name             dka_auto_etat.start_period_name%TYPE;
    vv_end_period_name               dka_auto_etat.end_period_name%TYPE;
    vv_sql_stmt                      VARCHAR2(32000);
    vv_org_id                       number;

    TYPE myrecord IS RECORD (
         request_id    NUMBER,
         program_name  VARCHAR2(250),
         company_name  VARCHAR2(25),
         period_name   VARCHAR2(25));

    TYPE mytable IS TABLE OF myrecord
         INDEX BY BINARY_INTEGER;

    TYPE myrecsoc IS RECORD (
         company_name        VARCHAR2(4),--dka_ibdsoc_i00dgic.company_name%TYPE, --YWA artf2075460
         centre_de_gestion   VARCHAR2(3),--dka_ibdsoc_i00dgic.mainoffice_cost_center%TYPE, --YWA artf2075460
         org_id             NUMBER,
         set_of_books_id    NUMBER,
         entity              VARCHAR2(25),
         request_date        DATE,
         request_month       NUMBER(2));

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
        --------------------------------
        -- Recherche de l'utilisateur --
        --------------------------------
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

        -------------------------------------------------------------
        -- Récupération des informations liées a la responsabilite --
        -------------------------------------------------------------
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

        -------------------------------------------------
        -- Récupération des informations du traitement --
        -------------------------------------------------
        BEGIN
            SELECT fcp.application_id,
                   fa.application_short_name,
                   fcp.concurrent_program_id,
                   fcp.class_application_id,
                   fcp.concurrent_class_id
            INTO   vn_prog_application_id,
                   vv_prog_application_short_name,
                   vn_program_id,
                   vn_class_application_id,
                   vn_concurrent_class_id
            FROM   fnd_concurrent_programs fcp,
                   fnd_application fa
            WHERE  fcp.concurrent_program_name = vv_prog_name
            AND    fa.application_id           = fcp.application_id;
   
        EXCEPTION
            WHEN OTHERS THEN
                 pn_retcode := 2;
                 pv_errbuf  := '==> Impossible de trouver les informations liees au programme';
                 RETURN;
        END;

        ---------------------------------------------------------------
        -- Modification du GTS dans lequel s'exécutera le traitement --
        ---------------------------------------------------------------
        BEGIN
            UPDATE fnd_concurrent_programs fcp
            SET    fcp.class_application_id    = NULL,
                   fcp.concurrent_class_id     = NULL
            WHERE  fcp.concurrent_program_name = vv_prog_name;

            COMMIT;
   
        EXCEPTION
            WHEN OTHERS THEN
                 pn_retcode := 2;
                 pv_errbuf  := '==> Impossible de modifier le GTS du traitement';
            RETURN;
        END;


        ------------------------------------------
        -- Positionnement dans le contexte O.A. --
        ------------------------------------------
        Fnd_Global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
        --DBMS_OUTPUT.PUT_LINE ('Pramas INIT => user_id = ' || vn_user_id ||', responsibility_id = '||vn_responsibility_id ||', application_id = '|| vn_application_id ||', org_id = '||vv_org_id);
        --MO_GLOBAL.SET_POLICY_CONTEXT('S', vv_org_id);  
        mo_global.set_org_context(vv_org_id,NULL,'SQLAP');
        --EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || Fnd_Profile.value ('ICX_LANGUAGE') || ''''; artf2075460
        
        /*--TO DELTE
         fnd_global.apps_initialize (1292, 50838, 200);
         mo_global.set_org_context(85,NULL,'SQLAP');
         
        SELECT  org_id
        INTO   vv_org_id
        FROM   ap_system_parameters;
        DBMS_OUTPUT.PUT_LINE ('Pramas INIT => vv_org_id = ' || vv_org_id );
        DBMS_OUTPUT.PUT_LINE ('Pramas INIT => FND_GLOBAL.ORG_ID = ' || FND_GLOBAL.ORG_ID );*/--test YWA
  
  
        pn_retcode := 0;

    END;

    ------------------------------------------
    -- Fonction de soumission du traitement --
    ------------------------------------------
    PROCEDURE soumission_traitement IS
    BEGIN
        vn_request_id := Fnd_Request.submit_request ( vv_prog_application_short_name,       -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                      vv_prog_name,                         -- SHORT NAME DU TRAITEMENT
                                                      NULL,                                 -- PROGRAM NAME
                                                      NULL,                                 -- START
                                                      FALSE,                                -- SUB REQUEST
                                                      Dka_Tools_Pkg.tab_request_params(1),  -- ARGUMENT1
                                                      Dka_Tools_Pkg.tab_request_params(2),  -- ARGUMENT2
                                                      Dka_Tools_Pkg.tab_request_params(3),  -- ARGUMENT3
                                                      Dka_Tools_Pkg.tab_request_params(4),  -- ARGUMENT4
                                                      Dka_Tools_Pkg.tab_request_params(5),  -- ARGUMENT5
                                                      Dka_Tools_Pkg.tab_request_params(6),  -- ARGUMENT6
                                                      Dka_Tools_Pkg.tab_request_params(7),  -- ARGUMENT7
                                                      Dka_Tools_Pkg.tab_request_params(8),  -- ARGUMENT8
                                                      Dka_Tools_Pkg.tab_request_params(9),  -- ARGUMENT9
                                                      Dka_Tools_Pkg.tab_request_params(10), -- ARGUMENT10
                                                      Dka_Tools_Pkg.tab_request_params(11), -- ARGUMENT11
                                                      Dka_Tools_Pkg.tab_request_params(12), -- ARGUMENT12
                                                      Dka_Tools_Pkg.tab_request_params(13), -- ARGUMENT13
                                                      Dka_Tools_Pkg.tab_request_params(14), -- ARGUMENT14
                                                      Dka_Tools_Pkg.tab_request_params(15), -- ARGUMENT15
                                                      Dka_Tools_Pkg.tab_request_params(16), -- ARGUMENT16
                                                      Dka_Tools_Pkg.tab_request_params(17), -- ARGUMENT17
                                                      Dka_Tools_Pkg.tab_request_params(18), -- ARGUMENT18
                                                      Dka_Tools_Pkg.tab_request_params(19), -- ARGUMENT19
                                                      Dka_Tools_Pkg.tab_request_params(20), -- ARGUMENT20
                                                      Dka_Tools_Pkg.tab_request_params(21), -- ARGUMENT21
                                                      Dka_Tools_Pkg.tab_request_params(22), -- ARGUMENT22
                                                      Dka_Tools_Pkg.tab_request_params(23), -- ARGUMENT23
                                                      Dka_Tools_Pkg.tab_request_params(24), -- ARGUMENT24
                                                      Dka_Tools_Pkg.tab_request_params(25), -- ARGUMENT25
                                                      Dka_Tools_Pkg.tab_request_params(26), -- ARGUMENT26
                                                      Dka_Tools_Pkg.tab_request_params(27), -- ARGUMENT27
                                                      Dka_Tools_Pkg.tab_request_params(28), -- ARGUMENT28
                                                      Dka_Tools_Pkg.tab_request_params(29), -- ARGUMENT29
                                                      Dka_Tools_Pkg.tab_request_params(30), -- ARGUMENT30
                                                      Dka_Tools_Pkg.tab_request_params(31), -- ARGUMENT31
                                                      Dka_Tools_Pkg.tab_request_params(32), -- ARGUMENT32
                                                      Dka_Tools_Pkg.tab_request_params(33), -- ARGUMENT33
                                                      Dka_Tools_Pkg.tab_request_params(34), -- ARGUMENT34
                                                      Dka_Tools_Pkg.tab_request_params(35), -- ARGUMENT35
                                                      Dka_Tools_Pkg.tab_request_params(36), -- ARGUMENT36
                                                      Dka_Tools_Pkg.tab_request_params(37), -- ARGUMENT37
                                                      Dka_Tools_Pkg.tab_request_params(38), -- ARGUMENT38
                                                      Dka_Tools_Pkg.tab_request_params(39), -- ARGUMENT39
                                                      Dka_Tools_Pkg.tab_request_params(40), -- ARGUMENT40
                                                      Dka_Tools_Pkg.tab_request_params(41), -- ARGUMENT41
                                                      Dka_Tools_Pkg.tab_request_params(42), -- ARGUMENT42
                                                      Dka_Tools_Pkg.tab_request_params(43), -- ARGUMENT43
                                                      Dka_Tools_Pkg.tab_request_params(44), -- ARGUMENT44
                                                      Dka_Tools_Pkg.tab_request_params(45), -- ARGUMENT45
                                                      Dka_Tools_Pkg.tab_request_params(46), -- ARGUMENT46
                                                      Dka_Tools_Pkg.tab_request_params(47), -- ARGUMENT47
                                                      Dka_Tools_Pkg.tab_request_params(48), -- ARGUMENT48
                                                      Dka_Tools_Pkg.tab_request_params(49), -- ARGUMENT49
                                                      Dka_Tools_Pkg.tab_request_params(50), -- ARGUMENT50
                                                      Dka_Tools_Pkg.tab_request_params(51), -- ARGUMENT51
                                                      Dka_Tools_Pkg.tab_request_params(52), -- ARGUMENT52
                                                      Dka_Tools_Pkg.tab_request_params(53), -- ARGUMENT53
                                                      Dka_Tools_Pkg.tab_request_params(54), -- ARGUMENT54
                                                      Dka_Tools_Pkg.tab_request_params(55), -- ARGUMENT55
                                                      Dka_Tools_Pkg.tab_request_params(56), -- ARGUMENT56
                                                      Dka_Tools_Pkg.tab_request_params(57), -- ARGUMENT57
                                                      Dka_Tools_Pkg.tab_request_params(58), -- ARGUMENT58
                                                      Dka_Tools_Pkg.tab_request_params(59), -- ARGUMENT59
                                                      Dka_Tools_Pkg.tab_request_params(60), -- ARGUMENT60
                                                      Dka_Tools_Pkg.tab_request_params(61), -- ARGUMENT61
                                                      Dka_Tools_Pkg.tab_request_params(62), -- ARGUMENT62
                                                      Dka_Tools_Pkg.tab_request_params(63), -- ARGUMENT63
                                                      Dka_Tools_Pkg.tab_request_params(64), -- ARGUMENT64
                                                      Dka_Tools_Pkg.tab_request_params(65), -- ARGUMENT65
                                                      Dka_Tools_Pkg.tab_request_params(66), -- ARGUMENT66
                                                      Dka_Tools_Pkg.tab_request_params(67), -- ARGUMENT67
                                                      Dka_Tools_Pkg.tab_request_params(68), -- ARGUMENT68
                                                      Dka_Tools_Pkg.tab_request_params(69), -- ARGUMENT69
                                                      Dka_Tools_Pkg.tab_request_params(70), -- ARGUMENT70
                                                      Dka_Tools_Pkg.tab_request_params(71), -- ARGUMENT71
                                                      Dka_Tools_Pkg.tab_request_params(72), -- ARGUMENT72
                                                      Dka_Tools_Pkg.tab_request_params(73), -- ARGUMENT73
                                                      Dka_Tools_Pkg.tab_request_params(74), -- ARGUMENT74
                                                      Dka_Tools_Pkg.tab_request_params(75), -- ARGUMENT75
                                                      Dka_Tools_Pkg.tab_request_params(76), -- ARGUMENT76
                                                      Dka_Tools_Pkg.tab_request_params(77), -- ARGUMENT77
                                                      Dka_Tools_Pkg.tab_request_params(78), -- ARGUMENT78
                                                      Dka_Tools_Pkg.tab_request_params(79), -- ARGUMENT79
                                                      Dka_Tools_Pkg.tab_request_params(80), -- ARGUMENT80
                                                      Dka_Tools_Pkg.tab_request_params(81), -- ARGUMENT81
                                                      Dka_Tools_Pkg.tab_request_params(82), -- ARGUMENT82
                                                      Dka_Tools_Pkg.tab_request_params(83), -- ARGUMENT83
                                                      Dka_Tools_Pkg.tab_request_params(84), -- ARGUMENT84
                                                      Dka_Tools_Pkg.tab_request_params(85), -- ARGUMENT85
                                                      Dka_Tools_Pkg.tab_request_params(86), -- ARGUMENT86
                                                      Dka_Tools_Pkg.tab_request_params(87), -- ARGUMENT87
                                                      Dka_Tools_Pkg.tab_request_params(88), -- ARGUMENT88
                                                      Dka_Tools_Pkg.tab_request_params(89), -- ARGUMENT89
                                                      Dka_Tools_Pkg.tab_request_params(90), -- ARGUMENT90
                                                      Dka_Tools_Pkg.tab_request_params(91), -- ARGUMENT91
                                                      Dka_Tools_Pkg.tab_request_params(92), -- ARGUMENT92
                                                      Dka_Tools_Pkg.tab_request_params(93), -- ARGUMENT93
                                                      Dka_Tools_Pkg.tab_request_params(94), -- ARGUMENT94
                                                      Dka_Tools_Pkg.tab_request_params(95), -- ARGUMENT95
                                                      Dka_Tools_Pkg.tab_request_params(96), -- ARGUMENT96
                                                      Dka_Tools_Pkg.tab_request_params(97), -- ARGUMENT97
                                                      Dka_Tools_Pkg.tab_request_params(98), -- ARGUMENT98
                                                      Dka_Tools_Pkg.tab_request_params(99), -- ARGUMENT99
                                                      Dka_Tools_Pkg.tab_request_params(100) -- ARGUMENT100
                                                      );
        vn_traitement := vn_traitement + 1;
        vt_traitement(vn_traitement).request_id   := vn_request_id;
        vt_traitement(vn_traitement).program_name := vv_prog_name;
        vt_traitement(vn_traitement).company_name := rec_soc.company_name;
        vt_traitement(vn_traitement).period_name  := vv_date_ref;
        COMMIT;

        IF vn_request_id = 0 THEN
           DBMS_OUTPUT.PUT_LINE ('Impossible de lancer le Traitement ');
           DBMS_OUTPUT.PUT_LINE (vv_errbuf);
        END IF;

    END;

    ---------------------------------------------------
    -- Fonction de vérification du format de la date --
    ---------------------------------------------------
    FUNCTION verif_date ( pv_date_ref IN OUT VARCHAR2 ) RETURN BOOLEAN IS
    BEGIN
        BEGIN
            SELECT to_char(trunc(to_date(pv_date_ref, 'DD-MON-YYYY')), 'YYYY/MM/DD HH24:MI:SS')
            INTO   pv_date_ref
            FROM   dual;
            
        EXCEPTION
            WHEN OTHERS THEN
                 DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les paramètres :');
                 DBMS_OUTPUT.PUT_LINE ('==> La date  '||pv_date_ref||' ne respecte pas le format DD-MON-YY');
                 RETURN FALSE;
        END;

        RETURN TRUE;
    END;

BEGIN
    
    vv_user            := Fnd_Profile.VALUE('USERNAME');
    vn_conc_request_id := Fnd_Global.CONC_REQUEST_ID;

    ----------------------------------------------------------
    -- Recherche des paramètres dans la table dka_auto_etat --
    ----------------------------------------------------------
    BEGIN
        SELECT 'O',
               NVL(LIVRE_PRIMAIRE,  'N'),
               NVL(LIVRE_SECONDAIRE,'N'),
               start_period_name,
               end_period_name
        INTO   vv_param_table,
               vv_LIVRE_PRIMAIRE,
               vv_LIVRE_SECONDAIRE,
               vv_start_period_name,
               vv_end_period_name
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
        DBMS_OUTPUT.PUT_LINE('==>                     Période de début : '||vv_start_period_name);
        DBMS_OUTPUT.PUT_LINE('==>                       Période de fin : '||vv_end_period_name);
        DBMS_OUTPUT.PUT_LINE('**********************************************************************');
        DBMS_OUTPUT.PUT_LINE(CHR(10));

    EXCEPTION
        WHEN OTHERS THEN
             vv_param_table           := 'N';
             vv_LIVRE_PRIMAIRE := 'N';
             vv_LIVRE_SECONDAIRE         := 'N';
             vv_start_period_name     := NULL;
             vv_end_period_name       := NULL;
    END;

    --------------------------------------------------------------------
    -- Recherche de la responsabilité pour le lancement du traitement --
    --------------------------------------------------------------------
    Dka_Tools_Pkg.get_parameter ('DKA_APXINAGE', 'AP_RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf);
    IF pn_retcode != 0 THEN
       DBMS_OUTPUT.PUT_LINE (vv_errbuf);
       :ret_code := 'FAILURE';
       RETURN;
    END IF;
    vv_responsibility_ref := rec_param.varchar2_value;

    --------------------------------------------------------------------
    -- Automatisation du traitement 'DKA : Balance âgée fournisseurs' --
    --------------------------------------------------------------------

    --------------------------------------------------------------
    -- Construction de la requête sql de sélection des sociétés --
    --------------------------------------------------------------
	/*
    vv_sql_stmt := 'SELECT DISTINCT dii.company_code company_name, '||
                   '       dii.mainoffice_cost_center centre_de_gestion, '||
                   '       DECODE(dbc.close_month, ''06'', ''LEGALE'', ''OPERATIONNELLE'') entity, '||
                   '       SYSDATE request_date, '||
                   '       TO_NUMBER(TO_CHAR(SYSDATE, ''MM'')) request_month '||
                   'FROM   dka_ibdsoc_i00dgic       dii, '||
                   '       dka_bdste_comptable      dbc, '||
                   '       dka_ibdsoc_general_info  digi '||
                   'WHERE  dii.company_type    = ''0'' '||
                   'AND    dii.company_code    = digi.company_code '||
                   'AND    dii.company_code    = dbc.company_code '||
                   'AND    dbc.effective_date  = ( select max(db2.effective_date) from dka_bdste_comptable db2 '||
                   '                               where dbc.company_code = db2.company_code)';       
  */

      vv_sql_stmt := 'SELECT DISTINCT substr(hou.NAME,4)                company_name, '||--YWA artf2075460
                   '       substr(hou.NAME,0,3)                         centre_de_gestion, '||--YWA artf2075460
                   '       hou.organization_id org_id, '||--YWA artf2075460
                   '       hou.set_of_books_id  set_of_books_id,'||--YWA artf2075460
                   '       glr.target_ledger_category_code           entity, '||
                   '       SYSDATE                             request_date, '||
                   '       TO_NUMBER(TO_CHAR(SYSDATE, ''MM'')) request_month '||
                   'FROM   HR_OPERATING_UNITs       hou, '||
                   '       gl_ledger_relationships  glr  '||
                   'WHERE  hou.set_of_books_id = glr.target_ledger_id '||
							'AND  hou.set_of_books_id IN '||  --SFA --artf3062543
												'(SELECT set_of_books_id 
											      FROM FINANCIALS_SYSTEM_PARAMS_ALL)'; 
                   --TO DELETE YWA
                   --|| ' AND hou.organization_id = 85';  
				   
		/* --Modification R12 @PBA 		 artf2056870   
    IF vv_param_table = 'O' THEN
	
       vv_sql_stmt := vv_sql_stmt||
                      'AND    ((DECODE(dbc.close_month, ''06'', ''SECONDARY'', ''PRIMARY'') = ''PRIMARY'' '||
                      '         AND '''||vv_LIVRE_PRIMAIRE||''' = ''O'' ) OR '||
                      '        (DECODE(dbc.close_month, ''06'', ''SECONDARY'', ''PRIMARY'') = ''SECONDARY'' '||
                      '         AND '''||vv_LIVRE_SECONDAIRE||''' = ''O'' )) ';
	
	
    ELSE
       IF TO_NUMBER(TO_CHAR(SYSDATE, 'MM')) BETWEEN 1 AND 6 THEN
	   
          vv_sql_stmt := vv_sql_stmt||
                         'AND    DECODE(dbc.close_month, ''06'', ''SECONDARY'', ''PRIMARY'') = ''PRIMARY'' ';
      
       ELSE
	   
          vv_sql_stmt := vv_sql_stmt||
                         'AND    DECODE(dbc.close_month, ''06'', ''SECONDARY'', ''PRIMARY'') = ''SECONDARY'' ';
	   
       END IF;
    END IF;
	
    vv_sql_stmt := vv_sql_stmt||
                   'ORDER BY dii.company_code ASC';
    */
    
    ------------------------------------
    -- Boucle de lecture des sociétés --
    ------------------------------------
    OPEN cur_soc FOR vv_sql_stmt;
    LOOP
        FETCH cur_soc INTO rec_soc;
        EXIT WHEN cur_soc%NOTFOUND;
      
        vn_trt_a_lancer := vn_trt_a_lancer + 2;

        ----------------------------------------------------
        -- initialisation de la variable vb_lancement_trt --
        ----------------------------------------------------
        vb_lancement_trt := TRUE;

        ------------------------------------------
        -- Positionnement dans le contexte O.A. --
        ------------------------------------------
        vv_user                := rec_soc.centre_de_gestion;
        vv_org_id              := rec_soc.org_id;
        vv_responsibility_name := REPLACE (vv_responsibility_ref, 'XXX', rec_soc.centre_de_gestion||rec_soc.company_name);--YWA artf2075460
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

        ----------------------------------------------------------
        -- Récupération des paramètres par défaut du traitement --
        ----------------------------------------------------------
        IF vb_lancement_trt THEN
           Dka_Tools_Pkg.get_request_set_params (
               pv_errbuf                      => vv_errbuf,
               pn_retcode                     => vn_retcode,
               pn_application_id              => NULL,
               pn_request_set_id              => NULL,
               pn_request_set_program_id      => NULL,
               pn_prog_application_id         => vn_prog_application_id,
               pn_program_id                  => vn_program_id
               );

           IF vn_retcode != 0 THEN
              DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les paramètres :');
              DBMS_OUTPUT.PUT_LINE (vv_errbuf);
              vb_lancement_trt := FALSE;
           END IF;

           ---------------------------------------
           -- Recherche de la date de référence --
           ---------------------------------------
           IF vv_param_table = 'O' THEN
              --------------------------------------------------------------------------------------------
              -- La table de paramètre est renseignée, on prend la date dans le champ start_period_name --
              --------------------------------------------------------------------------------------------
              vv_date_ref := vv_start_period_name;
              IF NOT verif_date (vv_date_ref) THEN
                 vb_lancement_trt := FALSE;
              END IF;
           ELSE
              IF rec_soc.entity = 'PRIMARY' THEN--'OPERATIONNELLE' THEN --YWA artf2075460
                 -----------------------------------------------------------------------------------------------
                 -- Société de l'entité opérationnelle, on prend la date au 31 décembre de l'année précédente --
                 -----------------------------------------------------------------------------------------------
                 vv_date_ref := '31-DEC-'||TO_CHAR(TRUNC(rec_soc.request_date, 'YYYY') - 1, 'YYYY');
                 IF NOT verif_date (vv_date_ref) THEN
                    vb_lancement_trt := FALSE;
                 END IF;
              ELSE
                 ---------------------------------------------------------------------------------
                 -- Société de l'entité légale, on prend la date au 30 juin de l'année courante --
                 ---------------------------------------------------------------------------------
                 vv_date_ref := '30-JUN-'||TO_CHAR(rec_soc.request_date, 'YYYY');
                 IF NOT verif_date (vv_date_ref) THEN
                    vb_lancement_trt := FALSE;
                 END IF;
              END IF;
           END IF;

           -----------------------------------
           -- Initialisation des parametres --
           -----------------------------------
           --Dka_Tools_Pkg.tab_request_params(1)  := rec_soc.company_name;                        -- Société artf2075460
           --Dka_Tools_Pkg.tab_request_params(2)  := NULL;                                        -- Centre de gestion artf2075460
           Dka_Tools_Pkg.tab_request_params(1)  := vv_date_ref;                         -- Date de référence
           Dka_Tools_Pkg.tab_request_params(2)  := 'Vendor Name';                               -- Trier facture par
           Dka_Tools_Pkg.tab_request_params(3)  := 'Y';                                         -- Détails facture
           Dka_Tools_Pkg.tab_request_params(4)  := 'Y';                                         -- Détails sites
           Dka_Tools_Pkg.tab_request_params(5)  := NULL;                                        -- Solde minimum
           Dka_Tools_Pkg.tab_request_params(6)  := NULL;                                        -- Solde maximum
           Dka_Tools_Pkg.tab_request_params(7)  := NULL;                                        -- Type de facture
           Dka_Tools_Pkg.tab_request_params(8) := NULL;                                        -- Partenaire commercial
           Dka_Tools_Pkg.tab_request_params(9) := 'DKA : Justification des factures échues';   -- Nom de période de balance âgée
           Dka_Tools_Pkg.tab_request_params(10) := rec_soc.set_of_books_id;   -- SOB -- ID entité comptable YWA
           Dka_Tools_Pkg.tab_request_params(11) := 'Y';                                         -- Factures comptabilisées
           Dka_Tools_Pkg.tab_request_params(12) := 'N';    --SFA ---artf3062543                 -- Activer analyse  
           Dka_Tools_Pkg.tab_request_params(13) := 'N';    --SFA ---artf3062543                  -- Debug mode

        END IF;

        -----------------------------------------------------------------------------------------------
        -- Lancement du traitement pour le type de période "DKA : Justification des factures échues" --
        -----------------------------------------------------------------------------------------------
        IF vb_lancement_trt THEN
           soumission_traitement;
           DBMS_OUTPUT.PUT_LINE (CHR(10)||'org_id '||vv_org_id||' name '||rec_soc.centre_de_gestion||rec_soc.company_name);
           DBMS_OUTPUT.PUT_LINE (CHR(10)||'TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
            --DBMS_OUTPUT.PUT_LINE ('==>                         Societe : '||Dka_Tools_Pkg.tab_request_params(1)); artf2075460
            --DBMS_OUTPUT.PUT_LINE ('==>               Centre de gestion : '||Dka_Tools_Pkg.tab_request_params(2)); artf2075460
            DBMS_OUTPUT.PUT_LINE ('==>               Date de reference : '||Dka_Tools_Pkg.tab_request_params(1));
            DBMS_OUTPUT.PUT_LINE ('==>               Trier facture par : '||Dka_Tools_Pkg.tab_request_params(2));
            DBMS_OUTPUT.PUT_LINE ('==>                 Détails facture : '||Dka_Tools_Pkg.tab_request_params(3));
            DBMS_OUTPUT.PUT_LINE ('==>                   Détails sites : '||Dka_Tools_Pkg.tab_request_params(4));
            DBMS_OUTPUT.PUT_LINE ('==>                   Solde minimum : '||Dka_Tools_Pkg.tab_request_params(5));
            DBMS_OUTPUT.PUT_LINE ('==>                   Solde maximum : '||Dka_Tools_Pkg.tab_request_params(6));
            DBMS_OUTPUT.PUT_LINE ('==>                 Type de facture : '||Dka_Tools_Pkg.tab_request_params(7));
            DBMS_OUTPUT.PUT_LINE ('==>           Partenaire commercial : '||Dka_Tools_Pkg.tab_request_params(8));
            DBMS_OUTPUT.PUT_LINE ('==>  Nom de période de balance âgée : '||Dka_Tools_Pkg.tab_request_params(9));
            DBMS_OUTPUT.PUT_LINE ('==>             ID entité comptable : '||Dka_Tools_Pkg.tab_request_params(10));
            DBMS_OUTPUT.PUT_LINE ('==>         Factures comptabilisées : '||Dka_Tools_Pkg.tab_request_params(11));
            DBMS_OUTPUT.PUT_LINE ('==>                 Activer analyse : '||Dka_Tools_Pkg.tab_request_params(12));
            DBMS_OUTPUT.PUT_LINE ('==>                      Debug mode : '||Dka_Tools_Pkg.tab_request_params(13));
           DBMS_OUTPUT.PUT_LINE (CHR(10));
           vn_trt_lances := vn_trt_lances + 1;
        END IF;


        Dka_Tools_Pkg.tab_request_params(9) := 'DKA : Justification des factures non échues';   -- Type de période de balance âgée

        ---------------------------------------------------------------------------------------------------
        -- Lancement du traitement pour le type de période "DKA : Justification des factures non échues" --
        ---------------------------------------------------------------------------------------------------
        IF vb_lancement_trt THEN
           soumission_traitement;
           DBMS_OUTPUT.PUT_LINE (CHR(10)||'org_id '||vv_org_id||' name '||rec_soc.centre_de_gestion||rec_soc.company_name);
           DBMS_OUTPUT.PUT_LINE (CHR(10)||'TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
            --DBMS_OUTPUT.PUT_LINE ('==>                         Societe : '||Dka_Tools_Pkg.tab_request_params(1)); artf2075460
            --DBMS_OUTPUT.PUT_LINE ('==>               Centre de gestion : '||Dka_Tools_Pkg.tab_request_params(2)); artf2075460
            DBMS_OUTPUT.PUT_LINE ('==>               Date de reference : '||Dka_Tools_Pkg.tab_request_params(1));
            DBMS_OUTPUT.PUT_LINE ('==>               Trier facture par : '||Dka_Tools_Pkg.tab_request_params(2));
            DBMS_OUTPUT.PUT_LINE ('==>                 Détails facture : '||Dka_Tools_Pkg.tab_request_params(3));
            DBMS_OUTPUT.PUT_LINE ('==>                   Détails sites : '||Dka_Tools_Pkg.tab_request_params(4));
            DBMS_OUTPUT.PUT_LINE ('==>                   Solde minimum : '||Dka_Tools_Pkg.tab_request_params(5));
            DBMS_OUTPUT.PUT_LINE ('==>                   Solde maximum : '||Dka_Tools_Pkg.tab_request_params(6));
            DBMS_OUTPUT.PUT_LINE ('==>                 Type de facture : '||Dka_Tools_Pkg.tab_request_params(7));
            DBMS_OUTPUT.PUT_LINE ('==>           Partenaire commercial : '||Dka_Tools_Pkg.tab_request_params(8));
            DBMS_OUTPUT.PUT_LINE ('==>  Nom de période de balance âgée : '||Dka_Tools_Pkg.tab_request_params(9));
            DBMS_OUTPUT.PUT_LINE ('==>             ID entité comptable : '||Dka_Tools_Pkg.tab_request_params(10));
            DBMS_OUTPUT.PUT_LINE ('==>         Factures comptabilisées : '||Dka_Tools_Pkg.tab_request_params(11));
            DBMS_OUTPUT.PUT_LINE ('==>                 Activer analyse : '||Dka_Tools_Pkg.tab_request_params(12));
            DBMS_OUTPUT.PUT_LINE ('==>                      Debug mode : '||Dka_Tools_Pkg.tab_request_params(13));
           DBMS_OUTPUT.PUT_LINE (CHR(10));
           vn_trt_lances := vn_trt_lances + 1;
        END IF;

    END LOOP; -- fin boucle des sociétés

    CLOSE cur_soc;


    -------------------------------------------------
    -- On repositionne le GTS a sa valeur initiale --
    -------------------------------------------------
    BEGIN
        UPDATE fnd_concurrent_programs fcp
        SET    (fcp.class_application_id, fcp.concurrent_class_id) = (SELECT fcrc.application_id,
                                                                             fcrc.request_class_id
                                                                      FROM   fnd_concurrent_request_class fcrc
                                                                      WHERE  fcrc.request_class_name = 'DALKIA_NUIT')
        WHERE  fcp.concurrent_program_name = vv_prog_name;

        COMMIT;
   
    END;

    -----------------------------------------------
    -- Attente de la fin de tous les traitements --
    -----------------------------------------------
    FOR vn_indice IN 1..vn_traitement 
    LOOP
        IF NOT Fnd_Concurrent.wait_for_request (vt_traitement(vn_indice).request_id, vn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
           DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning');
        ELSE
           IF vv_dstatus = 'NORMAL' THEN
              DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
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

    DBMS_OUTPUT.PUT_LINE (CHR(10)||'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements lances               : '||TO_CHAR(vn_trt_lances, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines normalement : '||TO_CHAR(vn_trt_normal, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));

    ---------------------------------------------
    -- Remise à jour de la table dka_auto_etat --
    ---------------------------------------------
    BEGIN
        UPDATE dka_auto_etat
        SET    LIVRE_PRIMAIRE = NULL,
               LIVRE_SECONDAIRE         = NULL,
               start_period_name     = NULL,
               end_period_name       = NULL,
               last_updated_by       = Fnd_Profile.VALUE('USER_ID'),
               last_update_date      = SYSDATE
        WHERE  program_short_name    = vv_prog_name;

        COMMIT;
    END;
    
    --< OBE artf2182814
    IF vn_trt_a_lancer != vn_trt_lances THEN
      DBMS_OUTPUT.PUT_LINE (CHR(10)||'Avertissement : Tous les traitements n''ont pas pu être lancés.');
      :ret_code := 'WARNING';
      
      UPDATE fnd_concurrent_requests
             SET phase_code = 'C',
                 status_code = 'G',
                 completion_text = 'Fin Anormale',
                 actual_completion_date = SYSDATE
           WHERE request_id = vn_conc_request_id
           ;
       
      COMMIT;      
      
    END IF;
    --> OBE artf2182814

EXCEPTION
    WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE (vv_prog_name || ' ==> ERREUR : ' || SQLERRM);
         :ret_code := 'FAILURE';

         -------------------------------------------------
         -- On repositionne le GTS a sa valeur initiale --
         -------------------------------------------------
         BEGIN
             UPDATE fnd_concurrent_programs fcp
             SET    (fcp.class_application_id, fcp.concurrent_class_id) = (SELECT fcrc.application_id,
                                                                                  fcrc.request_class_id
                                                                           FROM   fnd_concurrent_request_class fcrc
                                                                           WHERE  fcrc.request_class_name = 'DALKIA_NUIT')
             WHERE  fcp.concurrent_program_name = vv_prog_name;

             COMMIT;
   
         END;

END;
/
COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code
