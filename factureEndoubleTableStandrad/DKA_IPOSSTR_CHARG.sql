/*<TOAD_FILE_CHUNK>*/
/* Formatted on 05/16/2002 16:08 (Formatter Plus v4.5.2) */
---------------------------------------------------------------------------------------------------------------
--  CAP GEMINI
--  PROJET           : DALKIA Oracle Applications
--  NOM              : DKA_AUTO_SARSELECAVOIR.sql
--  DESCRIPTION      : Lancement automatique du traitement DKA_SARSELECAVOIR
---
--- AUTEUR           : IBA
--- DATE DE CREATION : 20/02/2023
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000
VAR ret_code      VARCHAR2(10);

VAR utl_file_name VARCHAR2(512);
DECLARE
    vv_prog_name                     VARCHAR2 (30)  := 'DKA_SARSELECAVOIR';
   
    vn_tempo                         NUMBER         := 20;
    vv_user                          VARCHAR2 (80);
    vv_errbuf                        VARCHAR2 (500) := NULL;
    vn_retcode                       NUMBER         := 0;
    vn_retcode_r                     NUMBER         := 0; -- PHENIX 2004
    vn_traitement                    NUMBER         := 0;
    vn_session_id                    NUMBER(15);
    vn_conc_request_id               NUMBER (15);
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
    vv_responsibility_ref            fnd_responsibility.responsibility_key%TYPE := 'DKA_ETATS';
    vv_responsibility                fnd_responsibility.responsibility_key%TYPE;
    vv_responsibility_name           fnd_responsibility.responsibility_key%TYPE;
    rec_param                        dka_parameters%ROWTYPE;
    pn_retcode                       NUMBER;
    vb_lancement_trt                 BOOLEAN;
    vn_trt_a_lancer                  NUMBER:=0;
    vn_trt_lances                    NUMBER:=0;
    vn_trt_normal                    NUMBER:=0;
    vn_trt_erreur                    NUMBER:=0;
    vn_trt_warning                   NUMBER:=0;
    l_req_data                       VARCHAR2(30);


    TYPE myrecord IS RECORD (
         request_id    NUMBER);

    TYPE mytable IS TABLE OF myrecord
         INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;

   

  CURSOR cur_soc IS
     
 SELECT distinct substr(name,1,3) user_name
        FROM   hr_operating_units 
        where substr(name,1,3) <> 'REF';
   
    rec_soc                   cur_soc%ROWTYPE;

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
	
        fnd_global.INITIALIZE( 
          vn_session_id, 
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

       
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''FRENCH''';                                        
        pn_retcode := 0;

    END;


    ------------------------------------------
    -- Fonction de soumission du traitement --
    ------------------------------------------
    PROCEDURE soumission_traitement (soc_name IN VARCHAR2)/*--SFA artf07235613*/ IS
    BEGIN
    
        vn_request_id := Fnd_Request.submit_request ( vv_prog_application_short_name, -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                      vv_prog_name,                   -- SHORT NAME DU TRAITEMENT
                                                      --NULL,                           -- PROGRAM NAME  
                                                      soc_name,                       -- PROGRAM NAME  
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
        COMMIT;

        IF vn_request_id = 0 THEN
           DBMS_OUTPUT.PUT_LINE ('Impossible de lancer le Traitement ');
           DBMS_OUTPUT.PUT_LINE (vv_errbuf);
		
		ELSE
		  update fnd_concurrent_requests
			set priority_request_id = vn_conc_request_id , is_sub_request = 'Y' , parent_request_id = vn_conc_request_id
			where request_id = vn_request_id;
		  commit;
        END IF;
        
    END;

BEGIN
    vn_conc_request_id := Fnd_Global.CONC_REQUEST_ID;
    vn_session_id := Fnd_Global.session_id;


    vv_user := Fnd_Profile.VALUE('USERNAME');
    DBMS_OUTPUT.PUT_LINE ('==> vv_user      : '||vv_user);
    ----------------------------
    -- LANCEMENT DES ETATS AR --
    ----------------------------
    -- Recherche de la responsabilité pour le lancement du traitement
    -----------------------------------------------------------------

    --------------------------------------------------------------------------------------------------
    -- Automatisation du traitement 'DKA : Etat justificatif de l'en-cours de TVA sur encaissement' --
    --------------------------------------------------------------------------------------------------
    vv_prog_name := 'DKA_SARSELECAVOIR';
    
 
    
    OPEN cur_soc;
      LOOP
        FETCH cur_soc INTO rec_soc;
        EXIT WHEN cur_soc%NOTFOUND;

        vn_trt_a_lancer := vn_trt_a_lancer + 1;

        -- initialisation de la variable vb_lancement_trt
        -------------------------------------------------
  
  vb_lancement_trt := TRUE;  

        -- Positionnement dans le contexte O.A.
        ---------------------------------------
        --PHENIX 2004
        vv_user                := rec_soc.user_name;
        

  vv_responsibility_name := vv_responsibility_ref; -- Modif EB
  
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

           -- Initialisation des parametres
           --------------------------------
         Dka_Tools_Pkg.tab_request_params(2) := rec_soc.user_name;
    
        END IF;           

        -- Lancement du traitement
        --------------------------
        IF vb_lancement_trt THEN
           soumission_traitement(rec_soc.user_name); 
           DBMS_OUTPUT.PUT_LINE (CHR(10)||'TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
           DBMS_OUTPUT.PUT_LINE ('==>            Region : '||Dka_Tools_Pkg.tab_request_params(2));
           DBMS_OUTPUT.PUT_LINE (CHR(10));
           vn_trt_lances := vn_trt_lances + 1;
        END IF;

    END LOOP; -- fin boucle des sociétés
    

    CLOSE cur_soc;

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
    

    IF vn_trt_erreur > 0 THEN
      :ret_code := 'FAILURE';
    END IF;


    -- Fermeture du fichier de commandes
    ------------------------------------
    DBMS_OUTPUT.PUT_LINE (CHR(10)||'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements lances               : '||TO_CHAR(vn_trt_lances, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines normalement : '||TO_CHAR(vn_trt_normal, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));
    
   
    Fnd_File.put_line(Fnd_File.LOG,CHR(10)||'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
    Fnd_File.put_line(Fnd_File.LOG,'==> Nombre de traitements lances               : '||TO_CHAR(vn_trt_lances, '99990'));
    Fnd_File.put_line(Fnd_File.LOG,'==> Nombre de traitements termines normalement : '||TO_CHAR(vn_trt_normal, '99990'));
    Fnd_File.put_line(Fnd_File.LOG,'==> Nombre de traitements termines en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
    Fnd_File.put_line(Fnd_File.LOG,'==> Nombre de traitements termines en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));    
    
    

EXCEPTION
    WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE (vv_prog_name || ' ==> ERREUR : ' || SQLERRM);
         :ret_code := 'FAILURE';
END;
/

COL :utl_file_name NEW_VALUE utl_file_name;
SELECT :utl_file_name
FROM   DUAL;
HOST sh &utl_file_name;

COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code
