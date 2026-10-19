---------------------------------------------------------------------------------------------------------------
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SFACLOTURE.sql
-- DESCRIPTION      : Lancement automatique du traitement SFACLOTURE par sociétés
---
--- AUTEUR           : Roshanak GHARAGOZLOU
--- DATE DE CREATION : 06/10/2016
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------------------------
--- Date       Qui Description
--  14/03/17   NBO artf2119392 - SPE034 : Automatisation : Période de cloture FA
--  16/05/17   MEG artf2150574 : SPE034 : DKA_SFAACCPB_JOB : Transfert FA vers GL ==> KO société 0800 
--  06/06/17   NBO artf2169713 - SPE034 : Cloture FA sur MAI-17 : Un seul livre traité (soc 0001)
--  27/11/20   NBO artf07423412 : INC0486420 - SPE034 - Correctif Automate de la clôture FA : Il s’agit de modifier la requête de récupération de la période en cours pour vérifier la date d’activité du livre FA.
--  15/08/23   ARA KDFI-1215 Problème de la taille du buffer DBMS_OUTPUT
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
--SET SERVEROUTPUT ON SIZE 100000
SET SERVEROUTPUT ON SIZE 1000000 --ARA

VAR ret_code VARCHAR2(10);

DECLARE
    
    vv_prog_name            CONSTANT VARCHAR2 (30)  := 'DKA_SFACLOTURE';
    vn_tempo                NUMBER                  := 20;
    vv_user                 VARCHAR2 (80)           :=  FND_PROFILE.VALUE('USERNAME');
    vv_errbuf                        VARCHAR2 (500) := NULL;
    vn_retcode_r                     NUMBER         := 0; -- PHENIX 2004
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
    vv_responsibility_key            fnd_responsibility.responsibility_key%TYPE  := 'DKA_EXPLOITATION';
    rec_param                        dka_parameters%ROWTYPE;
    pn_retcode                       NUMBER;
    vb_lancement_trt                 BOOLEAN;
    vn_trt_a_lancer                  NUMBER:=0;
    vn_trt_lances                    NUMBER:=0;
    vn_trt_normal                    NUMBER:=0;
    vn_trt_erreur                    NUMBER:=0;
    vn_trt_warning                   NUMBER:=0;
    vv_livre                         gl_ledgers.ledger_id%TYPE;
    
    TYPE myrecord IS RECORD (
         request_id    NUMBER);

    TYPE mytable IS TABLE OF myrecord
         INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;
    
     -- Curseur de sélection des sociétés 
    -----------------------------------------------------------------
    CURSOR cur_soc(p_type_livre VARCHAR2) IS
        /*SELECT DISTINCT val.FLEX_VALUE    company_name,
               val.ATTRIBUTE2   user_name
        FROM   fnd_flex_value_sets sets,
               fnd_flex_values_vl val              
        WHERE  sets.flex_value_set_id = val.flex_value_set_id
        AND    val.enabled_flag = 'Y'
        AND    val.compiled_value_attributes = 'Y'||chr(10)||'Y'
        AND    val.summary_flag = 'N'
        AND    val.VALUE_CATEGORY ='DAOPCCF_STE';*/
        SELECT DISTINCT val.flex_value company_name,
                        val.attribute2 user_name,
                        (SELECT DISTINCT first_value(period_name) over(ORDER BY period_open_date)
                           FROM fa_deprn_periods fdp, fa_book_controls fbc
                          WHERE fdp.period_close_date IS NULL
                            AND fdp.book_type_code = fbc.book_type_code
                            AND substr(fdp.book_type_code, 1, 4) NOT IN
                                (SELECT gl.short_name
                                   FROM gl_ledgers gl
                                  WHERE ledger_category_code = 'PRIMARY'
                                 MINUS
                                 SELECT gl.short_name
                                   FROM gl_access_sets gas
                                   JOIN gl_access_set_ledgers gasl ON gas.access_set_id =
                                                                      gasl.access_set_id
                                   JOIN gl_ledgers gl ON gasl.ledger_id =
                                                         gl.ledger_id
                                  WHERE gas.NAME = 'OPERATIONNEL')
                            AND fdp.book_type_code LIKE
                                val.flex_value || '%') period_name,
                         gl.ledger_id
          FROM fnd_flex_value_sets SETS, fnd_flex_values_vl val, gl_access_set_assignments gasa, gl_ledgers gl
         WHERE SETS.flex_value_set_id = val.flex_value_set_id
           AND val.enabled_flag = 'Y'
           AND val.compiled_value_attributes = 'Y' || chr(10) || 'Y'
           AND val.summary_flag = 'N'
           AND val.value_category = 'DAOPCCF_STE'
           AND gasa.access_set_id = Fnd_Profile.VALUE('GL_ACCESS_SET_ID')
           AND gl.ledger_id = gasa.ledger_id
           AND gl.ledger_category_code = 'PRIMARY'
           AND gl.SHORT_NAME = val.flex_value
           -- artf07423412 : INC0486420 - SPE034 - Correctif Automate de la clôture FA : Il s’agit de modifier la requête de récupération de la période en cours pour vérifier la date d’activité du livre FA.
           AND gl.ledger_id IN (select set_of_books_id from  fa_book_controls fbc where date_ineffective is null or date_ineffective > sysdate AND book_class = p_type_livre)
           /*AND val.flex_value NOT IN
               (SELECT gl.short_name
                  FROM gl_ledgers gl
                 WHERE ledger_category_code = 'PRIMARY'
                MINUS
                SELECT gl.short_name
                  FROM gl_access_sets gas
                  JOIN gl_access_set_ledgers gasl ON gas.access_set_id =
                                                     gasl.access_set_id
                  JOIN gl_ledgers gl ON gasl.ledger_id = gl.ledger_id
                 WHERE gas.NAME = 'OPERATIONNEL')*/
         ORDER BY 1, 2;
                 
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
        pn_retcode := 0;
        pv_errbuf  := NULL;

        DBMS_OUTPUT.put_line ('Récupération des informations liées à l''utilisateur');
        -- Recherche de l'utilisateur
        -----------------------------
        BEGIN
            SELECT user_id
            INTO   vn_user_id
            FROM   fnd_user
            WHERE  user_name = pv_user_name;
            EXCEPTION
            WHEN OTHERS THEN
                 pn_retcode := 2;
                 pv_errbuf  := '==> Impossible de trouver les informations liees a l''utilisateur';
                 RETURN;
        END; 
        
        DBMS_OUTPUT.put_line ('Récupération des informations liées a la responsabilite');
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
        
        DBMS_OUTPUT.put_line ('Recuperation des identifiants programme');
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
            WHERE  fcp.concurrent_program_name = vv_prog_name
            AND    fa.application_id           = fcp.application_id;

        EXCEPTION
            WHEN OTHERS THEN
                 pn_retcode := 2;
                 pv_errbuf  := '==> Impossible de trouver les informations liees au programme';
                 RETURN;
    END;
    
    -- Positionnement dans le contexte O.A.
    ---------------------------------------
    fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=French';
END;    

    ------------------------------------------
    -- Fonction de soumission du traitement --
    ------------------------------------------
    PROCEDURE soumission_traitement IS
    BEGIN
        vn_request_id := fnd_request.submit_request ( vv_prog_application_short_name, -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                      vv_prog_name,                   -- SHORT NAME DU TRAITEMENT
                                                      NULL,                           -- PROGRAM NAME
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
        COMMIT;

        IF vn_request_id = 0 THEN
           DBMS_OUTPUT.PUT_LINE ('Impossible de lancer le Traitement ');
           DBMS_OUTPUT.PUT_LINE (vv_errbuf);
        END IF;

    END;
BEGIN
    DBMS_OUTPUT.put_line ('Entree dans programme');---

    --  06/06/17   NBO artf2169713 - SPE034 : Cloture FA sur MAI-17 : Un seul livre traité (soc 0001)
    vv_user := 'EXPLOITATION';
    vv_responsibility_name := 'TOUT_FA_ADMINISTRATEUR';--vv_responsibility_key;
    DBMS_OUTPUT.put_line (vv_responsibility_name);---
    DBMS_OUTPUT.put_line (vv_prog_name);---
    DBMS_OUTPUT.put_line (rec_soc.company_name);---
    
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
    END IF;
    
    OPEN cur_soc('&&3'); 
    LOOP 
        FETCH cur_soc INTO rec_soc;
        
        EXIT WHEN cur_soc%NOTFOUND;

        vn_trt_a_lancer := vn_trt_a_lancer + 1;
        -- initialisation de la variable vb_lancement_trt
        -------------------------------------------------
        vb_lancement_trt       := TRUE;
        vv_user                := rec_soc.user_name;
        --vv_responsibility_name := vv_user||rec_soc.company_name||'_FA_ADMINISTRATEUR';--vv_responsibility_key;
        -- NBO 29/11/16 - Utilisation du MOAC
        vv_responsibility_name := 'TOUT_FA_ADMINISTRATEUR';--vv_responsibility_key;
        DBMS_OUTPUT.put_line (vv_user);---
        DBMS_OUTPUT.put_line (vv_responsibility_name);---
        DBMS_OUTPUT.put_line (vv_prog_name);---
        DBMS_OUTPUT.put_line (rec_soc.company_name);---
        
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

        -- Récupération des paramètres
        ------------------------------
        IF vb_lancement_trt THEN
           dka_tools_pkg.get_request_set_params (
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
          DBMS_OUTPUT.put_line ('OK');---
          
            -- Initialisation des parametres
            --------------------------------
            
            vv_livre := rec_soc.ledger_id;
            /*
            SELECT gl.ledger_id
            INTO vv_livre
            FROM gl_access_set_assignments gasa, 
                 gl_ledgers gl  
            WHERE gasa.access_set_id = Fnd_Profile.VALUE('GL_ACCESS_SET_ID')
            AND gl.ledger_id = gasa.ledger_id
            AND gl.ledger_category_code = 'PRIMARY'
            AND gl.SHORT_NAME = rec_soc.company_name;
            */
            
            ---DBMS_OUTPUT.put_line (Fnd_Profile.VALUE('GL_ACCESS_SET_ID'));
            ---DBMS_OUTPUT.put_line ('company_name: '||rec_soc.company_name);
            ---DBMS_OUTPUT.put_line ('livre: '||vv_livre);
            
            --type de livre
            dka_tools_pkg.tab_request_params(1) := '&&3';
            -- période FA
            DBMS_OUTPUT.put_line ('Recuperation de la période en cours');

            --  14/03/17   NBO artf2119392 - SPE034 : Automatisation : Période de cloture FA
            /*select distinct gp.period_name
              into dka_tools_pkg.tab_request_params(2)
              from gl_period_statuses gp
             where trunc(sysdate) between gp.start_date and gp.end_date
               and gp.set_of_books_id = vv_livre
               and gp.application_id = 101;*/
              SELECT distinct first_value(period_name) over (order by period_open_date) into dka_tools_pkg.tab_request_params(2)
			   FROM fnd_flex_value_sets SETS,
					fnd_flex_values_vl  val,
					fa_deprn_periods    fdp,
					fa_book_controls    fbc
			  WHERE SETS.flex_value_set_id = val.flex_value_set_id
				AND val.enabled_flag = 'Y'
				AND val.compiled_value_attributes = 'Y' || chr(10) || 'Y'
				AND val.summary_flag = 'N'
				AND val.value_category = 'DAOPCCF_STE'
			   AND fdp.period_close_date IS NULL
				AND val.flex_value = substr(fdp.book_type_code, 1, 4)
				AND fdp.book_type_code = fbc.book_type_code
        -- artf07423412 : INC0486420 - SPE034 - Correctif Automate de la clôture FA : Il s’agit de modifier la requête de récupération de la période en cours pour vérifier la date d’activité du livre FA.
        AND (fbc.date_ineffective is  null or fbc.date_ineffective > sysdate ) AND fbc.book_class = '&&3'
 
				AND val.flex_value NOT IN
					(SELECT gl.short_name
					   FROM gl_ledgers gl
					  WHERE ledger_category_code = 'PRIMARY'
					 MINUS
					 SELECT gl.short_name
					   FROM gl_access_sets gas
					   JOIN gl_access_set_ledgers gasl ON gas.access_set_id =
														  gasl.access_set_id
					   JOIN gl_ledgers gl ON gasl.ledger_id = gl.ledger_id
					  WHERE gas.NAME = 'OPERATIONNEL');
               
            -- NBO 29/11/16 - Force le SOB
            dka_tools_pkg.tab_request_params(3) := vv_livre;

			IF rec_soc.period_name != dka_tools_pkg.tab_request_params(2) THEN
			    DBMS_OUTPUT.PUT_LINE (CHR(10)||'TRAITEMENT NON LANCE');
				DBMS_OUTPUT.PUT_LINE ('==> Type de Livre : '||dka_tools_pkg.tab_request_params(1));
				DBMS_OUTPUT.PUT_LINE ('==>  Periode : '||dka_tools_pkg.tab_request_params(2));
				DBMS_OUTPUT.PUT_LINE ('==>  Sob : '||dka_tools_pkg.tab_request_params(3));
				DBMS_OUTPUT.PUT_LINE (chr(10));
				vb_lancement_trt := FALSE;
			END IF;

        END IF;            
        -- Lancement du traitement
        --------------------------
        IF vb_lancement_trt THEN
           soumission_traitement;
           DBMS_OUTPUT.PUT_LINE (CHR(10)||'TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
           DBMS_OUTPUT.PUT_LINE ('==> Type de Livre : '||dka_tools_pkg.tab_request_params(1));
           DBMS_OUTPUT.PUT_LINE ('==>  Periode : '||dka_tools_pkg.tab_request_params(2));
           DBMS_OUTPUT.PUT_LINE ('==>  Sob : '||dka_tools_pkg.tab_request_params(3));
           DBMS_OUTPUT.PUT_LINE (chr(10));
           vn_trt_lances := vn_trt_lances + 1;
        END IF;
    END LOOP; -- fin boucle des sociétés

    CLOSE cur_soc;
                                  
    

    -----------------------------------------------
    -- Attente de la fin de tous les traitements --
    -----------------------------------------------
    FOR vn_indice IN 1..vn_traitement 
    LOOP
        IF NOT fnd_concurrent.wait_for_request (vt_traitement(vn_indice).request_id, vn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
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
    
    IF vn_trt_erreur > 0 THEN
        :ret_code    := 'FAILURE';
    END IF;
    
    IF vn_trt_warning > 0 THEN
        :ret_code    := 'WARNING';
    END IF;    

    -- Fermeture du fichier de commandes
    ------------------------------------
    DBMS_OUTPUT.PUT_LINE (CHR(10)||'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements lances               : '||TO_CHAR(vn_trt_lances, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines normalement : '||TO_CHAR(vn_trt_normal, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));

   EXCEPTION
    WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE (vv_prog_name || ' ==> ERREUR : ' || SQLERRM);
         :ret_code := 'FAILURE 5';
END;




/
COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code
