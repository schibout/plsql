---------------------------------------------------------------------------------------------------------------
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_AUTO_SAPDAS2_GEN.sql
-- DESCRIPTION      : Lancement automatique du traitement DKA_APXINAGE
--
-- AUTEUR           : Q.VANHOUTE
-- DATE DE CREATION : 04/03/2010
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------------------------
-- Date        Qui  Commentaires
---------------------------------------------------------------------------------------------------------------
-- 08/03/2011 QVA  Suppression de l'utilisation de la table Dka_Ibdsoc_I00ic_Tmp
-- 27/03/2012 CDEF Correction de la requête de selection des sociétés
-- 31/07/2017 RBE  Artifact artf2099377 : SPE113 : Automatisation DKA_SAPDAS2_GEN_JOB.sh
-- 06/05/2020 ARA  Correction concernant l'UO de référence 
-- 09/12/2020 NBO INC0415872 - ETA018/ETA019 : Ajout contrôle sur responsabilité désactivées
---------------------------------------------------------------------------------------------------------------


SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000
-- 09/12/2020 NBO INC0415872 - ETA018/ETA019 : Ajout contrôle sur responsabilité désactivées
SET ECHO OFF
WHENEVER SQLERROR EXIT

VAR ret_code      VARCHAR2(10);


DECLARE
    g_errbuf                         VARCHAR2(1000);
    g_retcode                        VARCHAR2(1);
    vv_prog_name                     VARCHAR2 (30)  := 'DKA_JEFRDVER';
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
	-- 09/12/2020 NBO INC0415872 - ETA018/ETA019 : Ajout contrôle sur responsabilité désactivées
	vn_session_id					 NUMBER(15);
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
-- 09/12/2020 NBO INC0415872 - ETA018/ETA019 : Ajout contrôle sur responsabilité désactivées
    vn_trt_disable                   NUMBER:=0;
    vn_disable                       NUMBER;
    l_completion_status              BOOLEAN;
    vv_param_table                   VARCHAR2(1);
    vv_livre_primaire                dka_auto_etat.livre_primaire%TYPE;
    vv_livre_secondaire              dka_auto_etat.livre_secondaire%TYPE;
    vv_start_period_name             dka_auto_etat.start_period_name%TYPE;
    vv_end_period_name               dka_auto_etat.end_period_name%TYPE;
    --vv_sql_stmt                      VARCHAR2(32000);
    vn_annee                         NUMBER;
    vv_bool                          BOOLEAN; --SNK
    TYPE myrecord IS RECORD (
         request_id    NUMBER,
         program_name  VARCHAR2(250),
         company_name  VARCHAR2(25),
         period_name   VARCHAR2(25));

    TYPE mytable IS TABLE OF myrecord
         INDEX BY BINARY_INTEGER;

    TYPE myrecsoc IS RECORD (
         company_name        gl_ledgers.short_name%TYPE,
         centre_de_gestion   fnd_flex_values.attribute2%TYPE,
         entity              VARCHAR2(25),
         request_date        DATE,
         request_month       NUMBER(2));
         
    --< OBE R12
	--ARA
    CURSOR cur_entity IS
      SELECT xep.legal_entity_id         legal_entity_id,
            xep.legal_entity_identifier legal_entity_identifier, 
            xep.NAME                    legal_entity_name,
            hru.NAME                    ou_name,
            hru.organization_id         org_id,
            sysdate                     request_date,
            TO_NUMBER(TO_CHAR(SYSDATE, 'MM')) request_month
      FROM XLE_ENTITY_PROFILES XEP
      JOIN hr_operating_units hru ON (xep.legal_entity_id = hru.default_legal_context_id)
	  WHERE hru.name not like 'REF%'
      ORDER BY XEP.LEGAL_ENTITY_IDENTIFIER, organization_id;        
    --> OBE R12      

    TYPE mycursoc IS REF CURSOR;

    vt_traitement                    mytable;
    rec_soc                          myrecsoc;
    cur_soc                          mycursoc;

-- 09/12/2020 NBO INC0415872 - ETA018/ETA019 : Ajout contrôle sur responsabilité désactivées
  PROCEDURE display_msg(i_text IN VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(i_text);
    FND_FILE.PUT_LINE(FND_FILE.LOG, i_text);
  END display_msg;

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
		-- 09122020 NBO INC0415872 - ETA018/ETA019 : Ajout contrôle sur responsabilité désactivées
        --Fnd_Global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
		
		 fnd_global.INITIALIZE( vn_session_id, 
							    vn_user_id, 
								vn_responsibility_id, 
								vn_application_id,
								null,
								-1,
								null,
								null,
								null,
								null,
								vn_conc_request_id,
								null,
								null,
								null,
								null,
								null,
								null,
								-1);		
		

        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || Fnd_Profile.value ('ICX_LANGUAGE') || '''';

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
                                                      Dka_Tools_Pkg.tab_request_params(6)/*,  -- ARGUMENT6
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
                                                      Dka_Tools_Pkg.tab_request_params(100) -- ARGUMENT100*/
                                                      );
        vn_traitement := vn_traitement + 1;
        vt_traitement(vn_traitement).request_id   := vn_request_id;
        vt_traitement(vn_traitement).program_name := vv_prog_name;
        vt_traitement(vn_traitement).company_name := rec_soc.company_name;
        vt_traitement(vn_traitement).period_name  := vv_date_ref;
        COMMIT;

        IF vn_request_id = 0 THEN
           display_msg('Impossible de lancer le Traitement ');
           display_msg(vv_errbuf);
        END IF;

    END;

    ---------------------------------------------------
    -- Fonction de vérification du format de la date --
    ---------------------------------------------------
    /*FUNCTION verif_date ( pv_date_ref IN OUT VARCHAR2 ) RETURN BOOLEAN IS
    BEGIN
        BEGIN
            SELECT to_char(trunc(to_date(pv_date_ref, 'DD-MON-YYYY')), 'YYYY/MM/DD HH24:MI:SS')
            INTO   pv_date_ref
            FROM   dual;
            
        EXCEPTION
            WHEN OTHERS THEN
                 display_msg(CHR(10)||'Impossible de récupérer les paramètres :');
                 display_msg('==> La date  '||pv_date_ref||' ne respecte pas le format DD-MON-YY');
                 RETURN FALSE;
        END;

        RETURN TRUE;
    END;*/

BEGIN
    
    vv_user            := Fnd_Profile.VALUE('USERNAME');
    vn_conc_request_id := Fnd_Global.CONC_REQUEST_ID;

-- 09122020 NBO INC0415872 - ETA018/ETA019 : Ajout contrôle sur responsabilité désactivées
	vn_session_id := Fnd_Global.session_id;
    
    display_msg('Recherche des paramètres dans la table dka_auto_etat');
    ----------------------------------------------------------
    -- Recherche des paramètres dans la table dka_auto_etat --
    ----------------------------------------------------------
    BEGIN
    
        
        SELECT 'O',
               NVL(livre_primaire, 'N'),
               NVL(livre_secondaire, 'N'),
               start_period_name,
               end_period_name
        INTO   vv_param_table,
               vv_livre_primaire,
               vv_livre_secondaire,
               vv_start_period_name,
               vv_end_period_name
        FROM   dka_auto_etat
        WHERE  program_short_name = vv_prog_name
        AND    ( livre_primaire IS NOT NULL  OR
                 livre_secondaire         IS NOT NULL )
        AND    start_period_name IS NOT NULL;

        DBMS_OUTPUT.PUT_LINE('**********************************************************************');
        DBMS_OUTPUT.PUT_LINE('ATTENTION : ');
        DBMS_OUTPUT.PUT_LINE('LES PARAMETRES PAR DEFAUT SONT REMPLACES PAR LES PARAMETRES SUIVANTS :');
        DBMS_OUTPUT.PUT_LINE('==> Edition pour l''entité opérationnelle : '||vv_livre_primaire);
        DBMS_OUTPUT.PUT_LINE('==>         Edition pour l''entité légale : '||vv_livre_secondaire);
        DBMS_OUTPUT.PUT_LINE('==>                     Période de début : '||vv_start_period_name);
        DBMS_OUTPUT.PUT_LINE('==>                       Période de fin : '||vv_end_period_name);
        DBMS_OUTPUT.PUT_LINE('**********************************************************************');
        DBMS_OUTPUT.PUT_LINE(CHR(10));

    EXCEPTION
        WHEN OTHERS THEN
             vv_param_table           := 'N';
             vv_livre_primaire        := 'N';
             vv_livre_secondaire      := 'N';
             vv_start_period_name     := NULL;
             vv_end_period_name       := NULL;
    END;
    
    --------------------------------------------------------------------
    -- Recherche de la responsabilité pour le lancement du traitement --
    --------------------------------------------------------------------
    Dka_Tools_Pkg.get_parameter ('DKA_SAPDAS2_GEN', 'AP_RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf);
    IF pn_retcode != 0 THEN
       display_msg(vv_errbuf);
       :ret_code := 'FAILURE';
	   -- 09122020 NBO INC0415872 - ETA018/ETA019 : Ajout contrôle sur responsabilité désactivées
	   l_completion_status:=FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR','');
       RETURN;
    END IF;
    vv_responsibility_ref := rec_param.varchar2_value;

    --------------------------------------------------------------------
    -- Automatisation du traitement 'DKA : Balance âgée fournisseurs' --
    --------------------------------------------------------------------

    --------------------------------------------------------------
    -- Construction de la requête sql de sélection des sociétés --
    --------------------------------------------------------------
    /*vv_sql_stmt := 'SELECT DISTINCT dii.company_code company_name, '||
                   '       Dii.Mainoffice_Cost_Center Centre_De_Gestion,'||
                   '       DECODE (dbc.close_month, ''06'', ''LEGALE'', ''OPERATIONNELLE'') entity, '|| 
                   '       SYSDATE request_date, '||
                   '       TO_NUMBER(TO_CHAR(SYSDATE, ''MM'')) request_month '||
                   'FROM   dka_ibdsoc_i00dgic       dii, '|| 
                   '       dka_ibdsoc_general_info  digi, '||
                   '       dka_bdste_comptable      dbc '||
                   'WHERE  dii.company_type    = ''0'' '|| 
                   'AND    dii.company_code    = digi.company_code '|| 
                   'AND    dii.company_code    = dbc.company_code '||
                   'and    dbc.effective_date = ( select max(db2.effective_date) from dka_bdste_comptable db2 where dbc.company_code = db2.company_code) ';

    IF vv_param_table = 'O' THEN
       vv_sql_stmt := vv_sql_stmt||
                      'AND    ((DECODE(dbc.close_month, ''06'', ''LEGALE'', ''OPERATIONNELLE'') = ''OPERATIONNELLE'' '||
                      '         AND '''||vv_entite_operationnelle||''' = ''O'' ) OR '||
                      '        (DECODE(dbc.close_month, ''06'', ''LEGALE'', ''OPERATIONNELLE'') = ''LEGALE'' '||
                      '         AND '''||vv_entite_legale||''' = ''O'' )) ';
    ELSE
       IF TO_NUMBER(TO_CHAR(SYSDATE, 'MM')) BETWEEN 1 AND 6 THEN
          vv_sql_stmt := vv_sql_stmt||
                         'AND    DECODE(dbc.close_month, ''06'', ''LEGALE'', ''OPERATIONNELLE'') = ''OPERATIONNELLE'' ';
       ELSE
          vv_sql_stmt := vv_sql_stmt||
                         'AND    DECODE(dbc.close_month, ''06'', ''LEGALE'', ''OPERATIONNELLE'') = ''LEGALE'' ';
       END IF;
    END IF;
    vv_sql_stmt := vv_sql_stmt||
                   'ORDER BY dii.company_code ASC';*/

    ------------------------------------
    -- Recupére l'année précédente    --
    ------------------------------------
    BEGIN
      SELECT to_char(sysdate,'YYYY')-1 
      INTO vn_annee
      FROM dual;
    
      EXCEPTION
        WHEN OTHERS THEN
        vv_errbuf := 'Erreur lors de la recherche de l''annee precedente.';
        display_msg(vv_errbuf);
        :ret_code := 'FAILURE';
		-- 09122020 NBO INC0415872 - ETA018/ETA019 : Ajout contrôle sur responsabilité désactivées
		l_completion_status:=FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR','');
        RETURN;
  
    END;
    
    ------------------------------------
    -- Boucle de lecture des sociétés --
    ------------------------------------
    --< OBE R12
    /*OPEN cur_soc FOR vv_sql_stmt;
    LOOP
        FETCH cur_soc INTO rec_soc;
        EXIT WHEN cur_soc%NOTFOUND;*/
    --> OBE R12
    FOR rec_soc IN cur_entity
        LOOP          
      
        vn_trt_a_lancer := vn_trt_a_lancer + 1;

        ----------------------------------------------------
        -- initialisation de la variable vb_lancement_trt --
        ----------------------------------------------------
        vb_lancement_trt := TRUE;

        ------------------------------------------
        -- Positionnement dans le contexte O.A. --
        ------------------------------------------
        vv_user                := SUBSTR(rec_soc.ou_name,1,3);--rec_soc.centre_de_gestion; -- OBE R12
        vv_responsibility_name := REPLACE (vv_responsibility_ref, 'XXX', rec_soc.ou_name/*rec_soc.centre_de_gestion*/);

-- 09/12/2020 NBO INC0415872 - ETA018/ETA019 : Ajout contrôle sur responsabilité désactivées
        select count(1) into vn_disable
        from fnd_responsibility where nvl(end_date,sysdate) >= sysdate and responsibility_key = vv_responsibility_name;
        
        IF vn_disable > 0 THEN
          positionnement_contexte ( vv_user, 
                                    vv_responsibility_name, 
                                    vv_prog_name,
                                    vn_retcode,
                                    vv_errbuf );
          IF vn_retcode != 0 THEN
             display_msg(CHR(10)||'Impossible de se positionner dans le contexte O.A. :');
             display_msg('==> Utilisateur    : '||vv_user);
             display_msg('==> Responsabilite : '||vv_responsibility_name);
             display_msg('==> Programme      : '||vv_prog_name);
             display_msg(vv_errbuf);
             vb_lancement_trt := FALSE;
          END IF;
        ELSE
          vb_lancement_trt := FALSE;
          vn_trt_disable := vn_trt_disable + 1;
          display_msg('Le traitement n''a pas pu être lancé car la responsabilité '|| vv_responsibility_name ||' n''est pas active.');
        END IF;

        vv_bool := FND_REQUEST.SET_OPTIONS(language => 'FRENCH', territory => 'FRANCE'); --SNK
        ----------------------------------------------------------
        -- Récupération des paramètres par défaut du traitement --
        ----------------------------------------------------------
        IF vb_lancement_trt THEN
         /*  Dka_Tools_Pkg.get_request_set_params (
               pv_errbuf                      => vv_errbuf,
               pn_retcode                     => vn_retcode,
               pn_application_id              => NULL,
               pn_request_set_id              => NULL,
               pn_request_set_program_id      => NULL,
               pn_prog_application_id         => vn_prog_application_id,
               pn_program_id                  => vn_program_id
               );

           IF vn_retcode != 0 THEN
              display_msg(CHR(10)||'Impossible de récupérer les paramètres :');
              display_msg(vv_errbuf);
              vb_lancement_trt := FALSE;
           END IF;*/

           ---------------------------------------
           -- Recherche de la date de référence --
           ---------------------------------------
          /* IF vv_param_table = 'O' THEN
              --------------------------------------------------------------------------------------------
              -- La table de paramètre est renseignée, on prend la date dans le champ start_period_name --
              --------------------------------------------------------------------------------------------
              vv_date_ref := vv_start_period_name;
              IF NOT verif_date (vv_date_ref) THEN
                 vb_lancement_trt := FALSE;
              END IF;
           ELSE
              IF rec_soc.entity = 'OPERATIONNELLE' THEN
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
*/
           -----------------------------------
           -- Initialisation des parametres --
           -----------------------------------
           --< OBE R12
           /*Dka_Tools_Pkg.tab_request_params(1)  := vn_annee;                                 -- Annee de versement
           Dka_Tools_Pkg.tab_request_params(2)  := rec_soc.company_name;                     -- Societe
           Dka_Tools_Pkg.tab_request_params(3)  := 'Y';                                      -- Contrôle uniquement
           Dka_Tools_Pkg.tab_request_params(4)  := 'N';                                      -- Debug Mode
           Dka_Tools_Pkg.tab_request_params(5)  := fnd_profile.VALUE('GL_SET_OF_BKS_ID');    -- SOB
           */
           Dka_Tools_Pkg.tab_request_params(1)  := vn_annee;                                 -- Annee de versement
           Dka_Tools_Pkg.tab_request_params(2)  := rec_soc.legal_entity_id;                  -- Id de l'entité juridique
           Dka_Tools_Pkg.tab_request_params(3)  := 'Y';                                      -- Extraire données
           Dka_Tools_Pkg.tab_request_params(4)  := 'Y';                                      -- Versement de salaires
           --Dka_Tools_Pkg.tab_request_params(5)  := NULL;                                     -- Entité comptable
           Dka_Tools_Pkg.tab_request_params(5)  := rec_soc.org_id;                           -- Id de l'OU en cours
           Dka_Tools_Pkg.tab_request_params(6)  := NULL;                                     -- Montant minimum
           --> OBE R12
        END IF;

        --------------------------------------------------------------------------------------------------
        -- Lancement du traitement pour le type de période "DKA : France - DAS2 Détail par fournisseur" --
        --------------------------------------------------------------------------------------------------
        IF vb_lancement_trt THEN
           soumission_traitement;
           display_msg(CHR(10)||'TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
           display_msg('==>               Annee de versement : '||Dka_Tools_Pkg.tab_request_params(1));
           /*display_msg('==>                          Societe : '||Dka_Tools_Pkg.tab_request_params(2));
           display_msg('==>              Contrôle uniquement : '||Dka_Tools_Pkg.tab_request_params(3));
           display_msg('==>                       Debug Mode : '||Dka_Tools_Pkg.tab_request_params(4));
           display_msg('==>                              SOB : '||Dka_Tools_Pkg.tab_request_params(5));*/
           display_msg('==>                 Entité juridique : '||rec_soc.legal_entity_identifier);
           display_msg('==>                 Extraire donnees : '||Dka_Tools_Pkg.tab_request_params(3));
           display_msg('==>           Versement des salaires : '||Dka_Tools_Pkg.tab_request_params(4));
           display_msg('==>                              SOB : '||Dka_Tools_Pkg.tab_request_params(5));
           display_msg('==>            Unité opérationnnelle : '||rec_soc.ou_name);           
           display_msg(CHR(10));
           vn_trt_lances := vn_trt_lances + 1;
        END IF;

    END LOOP; -- fin boucle des sociétés

    --CLOSE cur_soc;


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
           display_msg(CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning');
        ELSE
           IF vv_dstatus = 'NORMAL' THEN
              display_msg(CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
              vn_trt_normal := vn_trt_normal + 1;
           ELSIF vv_dstatus = 'WARNING' THEN
              display_msg(CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning ');
              vn_trt_warning := vn_trt_warning + 1;
           ELSIF vv_dstatus != 'NORMAL' THEN
              display_msg(CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Erreur ');
              vn_trt_erreur := vn_trt_erreur + 1;
           END IF;
        END IF;

           :ret_code := 'SUCCESS';
    END LOOP;

-- 09/12/2020 NBO INC0415872 - ETA018/ETA019 : Ajout contrôle sur responsabilité désactivées
    display_msg(CHR(10)||'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
    display_msg('==> Nombre de traitements lances               : '||TO_CHAR(vn_trt_lances, '99990'));
    display_msg('==> Nombre de traitements termines normalement : '||TO_CHAR(vn_trt_normal, '99990'));
    display_msg('==> Nombre de traitements termines en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
    display_msg('==> Nombre de traitements termines en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));
    display_msg('==> Nombre de traitements avec une responsabilite desactive   : '||TO_CHAR(vn_trt_disable, '99990'));

    --RBE artf2099377
-- 09/12/2020 NBO INC0415872 - ETA018/ETA019 : Ajout contrôle sur responsabilité désactivées
    IF vn_trt_erreur > 0 OR :ret_code = 'FAILURE' THEN
        --:ret_code    := 'FAILURE';
        l_completion_status:=FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR','');
    ELSIF vn_trt_warning > 0 OR vn_trt_disable > 0 THEN 
        display_msg('Sortie en WARNING');
        --:ret_code    := 'WARNING';
        g_retcode := 1;
        l_completion_status:=FND_CONCURRENT.SET_COMPLETION_STATUS('WARNING','');
    ELSE
        --:ret_code    := 'SUCCESS';
        l_completion_status:=FND_CONCURRENT.SET_COMPLETION_STATUS('NORMAL','');
    END IF;
    
    ---------------------------------------------
    -- Remise à jour de la table dka_auto_etat --
    ---------------------------------------------
    BEGIN
        UPDATE dka_auto_etat
        SET    livre_primaire        = NULL,
               livre_secondaire      = NULL,
               start_period_name     = NULL,
               end_period_name       = NULL,
               last_updated_by       = Fnd_Profile.VALUE('USER_ID'),
               last_update_date      = SYSDATE
        WHERE  program_short_name    = vv_prog_name;

        COMMIT;
    END;

EXCEPTION
    WHEN OTHERS THEN
-- 09/12/2020 NBO INC0415872 - ETA018/ETA019 : Ajout contrôle sur responsabilité désactivées
         display_msg(vv_prog_name || ' ==> ERREUR : ' || SQLERRM);
         :ret_code := 'FAILURE';
         --g_retcode := 2;
         l_completion_status:=FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR', SQLERRM);

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
