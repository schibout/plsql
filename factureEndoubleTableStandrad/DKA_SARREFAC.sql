/*<TOAD_FILE_CHUNK>*/
/* Formatted on 05/16/2002 16:08 (Formatter Plus v4.5.2) */
---------------------------------------------------------------------------------------------------------------
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_AUTO_AMOR_FISC.sql
-- DESCRIPTION      : Lancement automatique du traitement DKA_AMOR_FISC
---
--- AUTEUR           : Capgemini
--- DATE DE CREATION : 16/10/2003
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------------------------
--- Version          : 1.2.1
--- Date             : 26/03/2012
--- Auteur           : CDEF
--- Nature           : Correction de la requête de selection des sociétés
---------------------------------------------------------------------------------------------------------------
--- Version          : 1.2.0
--- Date             : 04/07/2005
--- Auteur           : EMA
--- Nature           : La copie des fichiers générés se fait à partir du répertoire $APPLCSF/$APPLOUT au lieu
---                    de $APPLCSF/out
---------------------------------------------------------------------------------------------------------------
--- Version          : 1.1.0
--- Date             : 16/05/2004
--- Auteur           : EMA
--- Nature           : Ajout de la gestion du bordereau d'envoi
---                    Ajout de la gestion de table dka_auto_etat qui contient les paramètres de lancement 
---                    de l'état dans le cas d'une relance avec des paramètres différents de ceux par défaut.
---------------------------------------------------------------------------------------------------------------
--- Version          : 1.2.0
--- Date             : 01/07/2004
--- Auteur           : EMA
--- Nature           : Dans le cas où les paramètres sont dans la table DKA_AUTO_ETAT, on garde dans les 
---                    variables vv_start_period_name_table et vv_end_period_name_table les valeurs des
---                    periodes de début et de fin.
---------------------------------------------------------------------------------------------------------------
--- 06/08/2004 STI Portage specifique PHENIX 2004
---                Modification de la fonction livre_comptable( suppression de HR_ALL_ORGANIZATION_units)
--- 02/09/2004 STI Modification de la gestion des responsabilités
--- 08/03/2011 QVA Suppression de l'utilisation de la table Dka_Ibdsoc_I00ic_Tmp
---------------------------------------------------------------------------------------------------------------
SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000

VAR ret_code      VARCHAR2(10);
VAR code_bande    VARCHAR2(6);
VAR utl_file_name VARCHAR2(512);

DECLARE
    vv_prog_name                     VARCHAR2 (30)  := 'DKA_AMOR_FISC';
    vn_tempo                         NUMBER         := 20;
    vv_rattrapage                    VARCHAR2 (1)   := '&&1';
    vv_code_bande                    VARCHAR2 (6)   := '&&2';
    vv_user                          VARCHAR2 (80);
    vv_repertoire                    VARCHAR2 (250);
    vv_errbuf                        VARCHAR2 (500) := NULL;
    vn_retcode                       NUMBER         := 0;
    vn_retcode_r                     NUMBER         := 0;  -- PHENIX 2004
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
    vv_legal_responsibility_ref      fnd_responsibility.responsibility_key%TYPE;
    vv_responsibility                fnd_responsibility.responsibility_key%TYPE;
    vv_responsibility_name           fnd_responsibility.responsibility_key%TYPE;
    vn_effective_period_num          gl_period_statuses.effective_period_num%TYPE;
    vv_utl_file_dir                  v$parameter.value%TYPE;
    vv_utl_file_name                 VARCHAR2(250);
    vv_period_name                   VARCHAR2(50);
    vv_start_period_name             VARCHAR2(50);
    vv_end_period_name               VARCHAR2(50);
    vv_start_period_name_table       VARCHAR2(50);
    vv_end_period_name_table         VARCHAR2(50);
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
    vv_LIVRE_PRIMAIRE                dka_auto_etat.LIVRE_PRIMAIRE%TYPE;  --RBE MigR12
    vv_LIVRE_SECONDAIRE              dka_auto_etat.LIVRE_SECONDAIRE%TYPE;--RBE Migr12
    vv_sql_stmt                      VARCHAR2(32000);

    TYPE myrecord IS RECORD (
         request_id    NUMBER,
         program_name  VARCHAR2(250),
         company_name  VARCHAR2(25),
         period_name   VARCHAR2(15));

    TYPE mytable IS TABLE OF myrecord
         INDEX BY BINARY_INTEGER;

    TYPE myrecsoc IS RECORD (
         company_name  VARCHAR2(25),--dka_ibdsoc_i00dgic.company_name%TYPE,
         entity        VARCHAR2(25),
         request_date  DATE,
         request_month NUMBER(2));

    TYPE mycursoc IS REF CURSOR;

    vt_traitement                    mytable;
    rec_soc                          myrecsoc;
    cur_soc                          mycursoc;

    -- Curseur de sélection des sociétés pour les traitements annuels
    -----------------------------------------------------------------
    --                  ---------------------------------
    --                  |     Normal    |   Rattrapage  |
    -- --------------------------------------------------
    -- | Sociétés de    | FAXXXX SAISIE |               |
    -- | l'entité       |---------------|---------------|
    -- | Opérationnelle |    JAN/N-1    |               |
    -- |                |    DEC/N-1    |               |
    -- --------------------------------------------------
    -- | Sociétés de    | FAXXXX SAISIE | FAXXXX SAISIE |
    -- | l'entité       |---------------|---------------|
    -- | Légale         |    JUL/N-1    |    JUL/N-2    |
    -- |                |     JUN/N     |    JUN/N-1    |
    -- --------------------------------------------------
    --CURSOR cur_soc IS
    --    SELECT DISTINCT ffv.flex_value                                      company_name,
    --           digi.mainoffice_cost_center                                  user_name,
    --           DECODE(gcsm.single_value, NULL, 'OPERATIONNELLE', 'LEGALE')  entity,
    --           SYSDATE                                                      request_date,
    --           TO_NUMBER(TO_CHAR(SYSDATE, 'MM'))                            request_month
    --    FROM   fnd_flex_values            ffv,
    --           fnd_flex_value_sets        ffvs,
    --           dka_ibdsoc_general_info    digi,
    --           gl_cons_segment_map        gcsm
    --    WHERE  ffvs.flex_value_set_name = 'DKA_SOCIETES_LEGALES'
    --    AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
    --    AND    ffv.enabled_flag         = 'Y'
    --    AND    ffv.flex_value           = digi.company_code(+)
    --    AND    ffv.flex_value           = gcsm.single_value(+)
    --    AND    ffv.flex_value          IN ('0050', '0054')
    --    AND (( TO_NUMBER(TO_CHAR(SYSDATE, 'MM')) BETWEEN 7 AND 12 AND
    --           DECODE(gcsm.single_value, NULL, 'OPERATIONNELLE', 'LEGALE') = 'LEGALE' ) OR
    --         ( TO_NUMBER(TO_CHAR(SYSDATE, 'MM')) BETWEEN 1 AND 6 ))
    --    ORDER BY 1 ASC;

    --CURSOR cur_soc (pv_rattrapage VARCHAR2) IS
    --    SELECT DISTINCT dii.company_code                                    company_name,
    --           DECODE(diit.close_month, '06', 'LEGALE', 'OPERATIONNELLE')   entity,
    --           SYSDATE                                                      request_date,
    --           TO_NUMBER(TO_CHAR(SYSDATE, 'MM'))                            request_month
    --    FROM   dka_ibdsoc_i00dgic       dii,
    --           dka_ibdsoc_i00ic_tmp     diit,
    --           dka_ibdsoc_general_info  digi
    --    WHERE  dii.company_code    = diit.company_code
    --    AND    dii.company_type    = '0'
    --    AND    dii.company_code    = digi.company_code
    --    --AND    dii.company_code  BETWEEN '0040' AND '0057' 
    --    AND  (( pv_rattrapage     = 'N' AND
    --            (( TO_NUMBER(TO_CHAR(SYSDATE, 'MM')) BETWEEN 1 AND 6   AND
    --               DECODE(diit.close_month, '06', 'LEGALE', 'OPERATIONNELLE') = 'OPERATIONNELLE' ) OR
    --             ( TO_NUMBER(TO_CHAR(SYSDATE, 'MM')) BETWEEN 7 AND 12 AND
    --               DECODE(diit.close_month, '06', 'LEGALE', 'OPERATIONNELLE') = 'LEGALE' )))
    --    OR    ( pv_rattrapage     = 'Y' AND
    --            DECODE(diit.close_month, '06', 'LEGALE', 'OPERATIONNELLE') = 'LEGALE' ))
    --    ORDER BY dii.company_code ASC;

    --rec_soc                          cur_soc%ROWTYPE;


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
            WHERE  fcp.concurrent_program_name = vv_prog_name
            AND    fa.application_id           = fcp.application_id;
   
        EXCEPTION
            WHEN OTHERS THEN
                 pn_retcode := 2;
                 pv_errbuf  := '==> Impossible de trouver les informations liees au programme '||vv_prog_name;
                 RETURN;
        END;

        -- Positionnement dans le contexte O.A.
        ---------------------------------------
        Fnd_Global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);

        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || Fnd_Profile.value ('ICX_LANGUAGE') || '''';

        pn_retcode      := 0;
    END;


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
        vt_traitement(vn_traitement).program_name := vv_prog_name;
        vt_traitement(vn_traitement).company_name := rec_soc.company_name;
        vt_traitement(vn_traitement).period_name  := vv_period_name;
        COMMIT;

        IF vn_request_id = 0 THEN
           DBMS_OUTPUT.PUT_LINE ('Impossible de lancer le Traitement ');
           DBMS_OUTPUT.PUT_LINE (vv_errbuf);
        END IF;

    END;


    --------------------------------------------
    -- Fonction de vérification de période FA --
    --------------------------------------------
    FUNCTION verif_period_FA ( pv_book_type_code    IN     VARCHAR2,
                               pv_start_period_name IN OUT VARCHAR2,
                               pv_end_period_name   IN OUT VARCHAR2 ) RETURN BOOLEAN
    IS
        vv_dummy                         VARCHAR2(1);
    BEGIN
        BEGIN
            SELECT 'X', period_name
            INTO   vv_dummy, pv_start_period_name
            FROM   fa_deprn_periods fdp1
            WHERE  fdp1.book_type_code = pv_book_type_code
            AND    fdp1.period_counter = ( SELECT MIN(fdp2.period_counter)
                                           FROM   fa_deprn_periods fdp2
                                           WHERE  fdp2.book_type_code = fdp1.book_type_code
                                           AND    fdp2.calendar_period_open_date >= TO_DATE('01-'||pv_start_period_name, 'DD_MON-RR') );
        EXCEPTION
            WHEN OTHERS THEN
                 DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les paramètres :');
                 DBMS_OUTPUT.PUT_LINE ('==> Période '||pv_start_period_name||' inexistante pour la société '||rec_soc.company_name);
                 RETURN FALSE;
        END;

        BEGIN
            SELECT 'X', period_name
            INTO   vv_dummy, pv_end_period_name
            FROM   fa_deprn_periods fdp1
            WHERE  fdp1.book_type_code = pv_book_type_code
            AND    fdp1.period_counter = ( SELECT MAX(fdp2.period_counter)
                                           FROM   fa_deprn_periods fdp2
                                           WHERE  fdp2.book_type_code = fdp1.book_type_code
                                           AND    fdp2.calendar_period_close_date <= LAST_DAY(TO_DATE('01-'||pv_end_period_name, 'DD_MON-RR')) );
        EXCEPTION
            WHEN OTHERS THEN
                 DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les paramètres :');
                 DBMS_OUTPUT.PUT_LINE ('==> Période '||pv_end_period_name||' inexistante pour la société '||rec_soc.company_name);
                 RETURN FALSE;
        END;

        RETURN TRUE;
    END;


    ----------------------------------------------
    -- Fonction de recherche du livre comptable --
    ----------------------------------------------
    FUNCTION livre_comptable ( pv_company_name   IN  VARCHAR2,
                               pv_book_type_code OUT VARCHAR2 ) RETURN BOOLEAN
    IS
        Vn_Nombre            NUMBER;
    BEGIN
        -- Recherche du livre comptable
        -------------------------------
        BEGIN
            SELECT book_type_code
            INTO   pv_book_type_code
            FROM   fa_book_controls fbc
              --   hr_all_organization_units haou -- PHENIX 2004
            WHERE  1 = 1
            -- fbc.org_id     = haou.organization_id  -- PHENIX 2004
            AND    fbc.book_class = 'CORPORATE'
            -- AND    haou.name      = pv_company_name
            AND    fbc.book_type_code LIKE pv_company_name || '%' -- PHENIX 2004
            --AND	   fbc.SET_OF_BOOKS_ID = Fnd_Profile.Value('GL_SET_OF_BKS_ID') -- PHENIX 2004 --RBE MigR12
            AND    fbc.date_ineffective IS NULL;

        EXCEPTION
            WHEN OTHERS THEN
                 DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les paramètres :');
                 DBMS_OUTPUT.PUT_LINE ('==> Livre comptable pour la société '||pv_company_name||' inexistant');
                 RETURN FALSE;
        END;

        RETURN TRUE;
     END;

BEGIN
    
    vv_user := Fnd_Profile.VALUE('USERNAME');
    :code_bande := vv_code_bande;  -- V1.1.0

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
             DBMS_OUTPUT.PUT_LINE ('Impossible de récupérer le répertoire de création des fichiers');
             :ret_code := 'FAILURE';
             RETURN;
    END;

    vv_utl_file_name := 'DKA_AMOR_FISC.sh';
    :utl_file_name := vv_utl_file_dir||'/'||vv_utl_file_name;

    ----------------------------------------------------------
    -- Recherche des paramètres dans la table dka_auto_etat --
    ----------------------------------------------------------
    BEGIN
        SELECT 'O',
               NVL(LIVRE_PRIMAIRE, 'N'),
               NVL(LIVRE_secondaire, 'N'),
               start_period_name,
               end_period_name
        INTO   vv_param_table,
               vv_LIVRE_PRIMAIRE,
               vv_LIVRE_SECONDAIRE,
               vv_start_period_name_table,
               vv_end_period_name_table
        FROM   dka_auto_etat
        WHERE  program_short_name = vv_prog_name
        AND    ( LIVRE_PRIMAIRE IS NOT NULL  OR
                 LIVRE_PRIMAIRE         IS NOT NULL )
        AND    start_period_name IS NOT NULL
        AND    end_period_name   IS NOT NULL;

        DBMS_OUTPUT.PUT_LINE('**********************************************************************');
        DBMS_OUTPUT.PUT_LINE('ATTENTION : ');
        DBMS_OUTPUT.PUT_LINE('LES PARAMETRES PAR DEFAUT SONT REMPLACES PAR LES PARAMETRES SUIVANTS :');
        DBMS_OUTPUT.PUT_LINE('==> Edition pour l''entité opérationnelle : '||vv_LIVRE_PRIMAIRE);
        DBMS_OUTPUT.PUT_LINE('==>         Edition pour l''entité légale : '||vv_LIVRE_secondaire);
        DBMS_OUTPUT.PUT_LINE('==>                     Période de début : '||vv_start_period_name_table);
        DBMS_OUTPUT.PUT_LINE('==>                       Période de fin : '||vv_end_period_name_table);
        DBMS_OUTPUT.PUT_LINE('**********************************************************************');
        DBMS_OUTPUT.PUT_LINE(CHR(10));

    EXCEPTION
        WHEN OTHERS THEN
             vv_param_table           := 'N';
             vv_LIVRE_PRIMAIRE        := 'N'; --RBE MigR12
             vv_LIVRE_secondaire      := 'N'; --RBE MigR12
             vv_start_period_name     := NULL;
             vv_end_period_name       := NULL;
    END;

    ----------------------------
    -- LANCEMENT DES ETATS FA --
    ----------------------------
    -- Recherche de la responsabilité pour le lancement du traitement
    -----------------------------------------------------------------
    Dka_Tools_Pkg.get_parameter ('DKA_AMOR_FISC', 'FA_RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf);
    IF pn_retcode != 0 THEN
       DBMS_OUTPUT.PUT_LINE (vv_errbuf);
       :ret_code := 'FAILURE';
       RETURN;
    END IF;

    vv_responsibility_ref := rec_param.varchar2_value;

    ----------------------------------------------------------------------------------------------------
    -- Automatisation du traitement 'DKA : Amortissements fiscaux - mouvements de la période - 2055A' --
    ----------------------------------------------------------------------------------------------------
    vv_prog_name := 'DKA_AMOR_FISC';
    vv_repertoire := '$REP_DATA/editions_legales/'||vv_prog_name;

    -- Construction de la requête sql
    ---------------------------------
--RBE MigR12
/*    vv_sql_stmt := 'SELECT DISTINCT dii.company_code company_name, '||
                   '       DECODE (dbc.close_month, ''06'', ''LEGALE'', ''OPERATIONNELLE'') entity, '|| 
                   '       SYSDATE request_date, '||
                   '       TO_NUMBER(TO_CHAR(SYSDATE, ''MM'')) request_month '||
                   'FROM   dka_ibdsoc_i00dgic       dii, '|| 
                   '       dka_ibdsoc_general_info  digi, '||
                   '       dka_bdste_comptable      dbc '||
                   'WHERE  dii.company_type    = ''0'' '|| 
                   'AND    dii.company_code    = digi.company_code '|| 
                   'AND    dii.company_code    = dbc.company_code '||
                   'AND    dii.company_code   != ''0001'' '||
                   'and    dbc.effective_date = ( select max(db2.effective_date) from dka_bdste_comptable db2 where dbc.company_code = db2.company_code) ';
*/
--
--RBE MigR12
      vv_sql_stmt := 'SELECT DISTINCT substr(hou.NAME,4)                company_name, '||
                  -- '       substr(hou.NAME,0,3)                         centre_de_gestion, '||
                  -- '       hou.organization_id org_id, '||
                  -- '       hou.set_of_books_id  set_of_books_id,'||
                   '       glr.target_ledger_category_code           entity, '||
                   '       SYSDATE                             request_date, '||
                   '       TO_NUMBER(TO_CHAR(SYSDATE, ''MM'')) request_month '||
                   'FROM   HR_OPERATING_UNITs       hou, '||
                   '       gl_ledger_relationships  glr  '||
                   'WHERE  hou.set_of_books_id = glr.target_ledger_id';

/* --RBE migration R12                   
    IF vv_param_table = 'O' THEN
       vv_sql_stmt := vv_sql_stmt||
                      'AND    ((DECODE(dbc.close_month, ''06'', ''LEGALE'', ''OPERATIONNELLE'') = ''OPERATIONNELLE'' '||
                      '         AND '''||vv_entite_operationnelle||''' = ''O'' ) OR '||
                      '        (DECODE(dbc.close_month, ''06'', ''LEGALE'', ''OPERATIONNELLE'') = ''LEGALE'' '||
                      '         AND '''||vv_entite_legale||''' = ''O'' )) ';
    ELSE
       IF vv_rattrapage = 'N' THEN
          IF TO_NUMBER(TO_CHAR(SYSDATE, 'MM')) BETWEEN 1 AND 6 THEN
             vv_sql_stmt := vv_sql_stmt||
                            'AND    DECODE(dbc.close_month, ''06'', ''LEGALE'', ''OPERATIONNELLE'') = ''OPERATIONNELLE'' ';
          ELSE
             vv_sql_stmt := vv_sql_stmt||
                            'AND    DECODE(dbc.close_month, ''06'', ''LEGALE'', ''OPERATIONNELLE'') = ''LEGALE'' ';
          END IF;
       ELSE
          vv_sql_stmt := vv_sql_stmt||
                         'AND    DECODE(dbc.close_month, ''06'', ''LEGALE'', ''OPERATIONNELLE'') = ''LEGALE'' ';
       END IF;
    END IF;
    --vv_sql_stmt := vv_sql_stmt||
    --               'AND    dii.company_code  BETWEEN ''0046'' AND ''0058'' '; 
    vv_sql_stmt := vv_sql_stmt||
                   'ORDER BY dii.company_code ASC';
*/
       
       
    -- PHENIX 2004 on sort de la boucle l'initialisation de l'application   
    -- Positionnement dans le contexte O.A.
    ---------------------------------------
    -- PHENIX 2004 suppresison: positionnement_contexte ( vv_user, 
    -- PHENIX 2004 suppresison:                              'FA ADMINISTRATEUR', 
    -- PHENIX 2004 suppresison:                               vv_prog_name,
    -- PHENIX 2004 suppresison:                               vn_retcode_r,
    -- PHENIX 2004 suppresison:                               vv_errbuf );
    -- PHENIX 2004 suppresison:     IF vn_retcode_r != 0 THEN
    -- PHENIX 2004 suppresison:        DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de se positionner dans le contexte O.A. :');
    -- PHENIX 2004 suppresison:        DBMS_OUTPUT.PUT_LINE ('==> Utilisateur    : '||vv_user);
    -- PHENIX 2004 suppresison:        DBMS_OUTPUT.PUT_LINE ('==> Responsabilite : FA ADMINISTRATEUR');
    -- PHENIX 2004 suppresison:        DBMS_OUTPUT.PUT_LINE ('==> Programme      : '||vv_prog_name);
    -- PHENIX 2004 suppresison:        DBMS_OUTPUT.PUT_LINE (vv_errbuf);
    -- PHENIX 2004 suppresison:        vb_lancement_trt := FALSE;
    -- PHENIX 2004 suppresison:     END IF;

    vv_responsibility_name := vv_responsibility_ref;
    positionnement_contexte ( vv_user, 
                              vv_responsibility_name, 
                              vv_prog_name,
                              vn_retcode_r,
                              vv_errbuf );
                              
  
    
    IF vn_retcode_r != 0 THEN
       DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de se positionner dans le contexte O.A. :');
       DBMS_OUTPUT.PUT_LINE ('==> Utilisateur    : '||vv_user);
       DBMS_OUTPUT.PUT_LINE ('==> Responsabilite : '||vv_responsibility_name);
       DBMS_OUTPUT.PUT_LINE ('==> Programme      : '||vv_prog_name);
       DBMS_OUTPUT.PUT_LINE (vv_errbuf);
       vb_lancement_trt := FALSE;
    END IF;                



    OPEN cur_soc FOR vv_sql_stmt;
    LOOP
        FETCH cur_soc INTO rec_soc;
        EXIT WHEN cur_soc%NOTFOUND;

        vn_trt_a_lancer := vn_trt_a_lancer + 1;

        -- initialisation de la variable vb_lancement_trt
        -------------------------------------------------
         IF vn_retcode_r = 0 THEN -- PHENIX 2004
            vb_lancement_trt := TRUE;
         END IF;


	/* PHENIX 2004
        -- Positionnement dans le contexte O.A.
        ---------------------------------------
        positionnement_contexte ( vv_user, 
                                  'FA ADMINISTRATEUR', 
                                  vv_prog_name,
                                  vn_retcode,
                                  vv_errbuf );
        IF vn_retcode != 0 THEN
           DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de se positionner dans le contexte O.A. :');
           DBMS_OUTPUT.PUT_LINE ('==> Utilisateur    : '||vv_user);
           DBMS_OUTPUT.PUT_LINE ('==> Responsabilite : FA ADMINISTRATEUR');
           DBMS_OUTPUT.PUT_LINE ('==> Programme      : '||vv_prog_name);
           DBMS_OUTPUT.PUT_LINE (vv_errbuf);
           vb_lancement_trt := FALSE;
        END IF;

        vv_responsibility_name := REPLACE (vv_responsibility_ref, 'XXXX', rec_soc.company_name);
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
	
	*/
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
           Dka_Tools_Pkg.tab_request_params(1) := rec_soc.company_name;
           
           

           -- Recherche du livre comptable
           -------------------------------
           IF NOT livre_comptable (rec_soc.company_name, vv_book_type_code) THEN
              vb_lancement_trt := FALSE;
           END IF;

           -- Recherche des périodes du traitement
           ---------------------------------------
           --vv_book_type_code := dka_tools_pkg.tab_request_params(3);
           IF vv_param_table = 'O' THEN
              vv_start_period_name := vv_start_period_name_table;
              vv_end_period_name   := vv_end_period_name_table;
              IF NOT verif_period_FA (vv_book_type_code, vv_start_period_name, vv_end_period_name) THEN
                 vb_lancement_trt := FALSE;
              END IF;

              Dka_Tools_Pkg.tab_request_params(3) := vv_start_period_name;
              Dka_Tools_Pkg.tab_request_params(4) := vv_end_period_name;
              vv_period_name                      := vv_end_period_name;
           ELSE
              IF vv_rattrapage = 'N' THEN
                 IF rec_soc.entity = 'OPERATIONNELLE' THEN
                    vv_start_period_name := 'JAN-'||SUBSTR(TO_CHAR(rec_soc.request_date, 'YYYY')-1, 3);
                    vv_end_period_name   := 'DEC-'||SUBSTR(TO_CHAR(rec_soc.request_date, 'YYYY')-1, 3);

                    IF NOT verif_period_FA (vv_book_type_code, vv_start_period_name, vv_end_period_name) THEN
                       vb_lancement_trt := FALSE;
                    END IF;

                    Dka_Tools_Pkg.tab_request_params(3) := vv_start_period_name;
                    Dka_Tools_Pkg.tab_request_params(4) := vv_end_period_name;
                    vv_period_name                      := vv_end_period_name;
                 ELSE
                    vv_start_period_name := 'JUL-'||SUBSTR(TO_CHAR(rec_soc.request_date, 'YYYY')-1, 3);
                    vv_end_period_name   := 'JUN-'||SUBSTR(TO_CHAR(rec_soc.request_date, 'YYYY'), 3);

                    IF NOT verif_period_FA (vv_book_type_code, vv_start_period_name, vv_end_period_name) THEN
                       vb_lancement_trt := FALSE;
                    END IF;

                    Dka_Tools_Pkg.tab_request_params(3) := vv_start_period_name;
                    Dka_Tools_Pkg.tab_request_params(4) := vv_end_period_name;
                    vv_period_name                      := vv_end_period_name;
                 END IF;
              ELSE
                 vv_start_period_name := 'JUL-'||SUBSTR(TO_CHAR(rec_soc.request_date, 'YYYY')-2, 3);
                 vv_end_period_name   := 'JUN-'||SUBSTR(TO_CHAR(rec_soc.request_date, 'YYYY')-1, 3);

                 IF NOT verif_period_FA (vv_book_type_code, vv_start_period_name, vv_end_period_name) THEN
                    vb_lancement_trt := FALSE;
                 END IF;

                 Dka_Tools_Pkg.tab_request_params(3) := vv_start_period_name;
                 Dka_Tools_Pkg.tab_request_params(4) := vv_end_period_name;
                 vv_period_name                      := vv_end_period_name;
              END IF;
           END IF;           
        END IF;

        -- Lancement du traitement
        --------------------------
        IF vb_lancement_trt THEN
           soumission_traitement;
           DBMS_OUTPUT.PUT_LINE (CHR(10)||'TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
           DBMS_OUTPUT.PUT_LINE ('==>                     Code Société : '||Dka_Tools_Pkg.tab_request_params(1));
           DBMS_OUTPUT.PUT_LINE ('==>                Centre de Gestion : '||Dka_Tools_Pkg.tab_request_params(2));
           DBMS_OUTPUT.PUT_LINE ('==> Période d''amortissement de début : '||Dka_Tools_Pkg.tab_request_params(3));
           DBMS_OUTPUT.PUT_LINE ('==>   Période d''amortissement de fin : '||Dka_Tools_Pkg.tab_request_params(4));
           DBMS_OUTPUT.PUT_LINE ('==>                   Fichier genere : '||vt_traitement(vn_traitement).program_name||'_'||
                                 vt_traitement(vn_traitement).company_name||'_'||
                                 vt_traitement(vn_traitement).period_name||'.out');
           DBMS_OUTPUT.PUT_LINE (CHR(10));
           vn_trt_lances := vn_trt_lances + 1;
        END IF;

    END LOOP; -- fin boucle des sociétés

    CLOSE cur_soc;


    -----------------------------------------------
    -- Attente de la fin de tous les traitements --
    -----------------------------------------------
    -- Ouverture du fichier de commande 
    -----------------------------------
    vf_myfile := UTL_FILE.FOPEN (vv_utl_file_dir, vv_utl_file_name, 'w');
    UTL_FILE.PUT_LINE (vf_myfile, 'echo Vidage des fichiers');
    UTL_FILE.PUT_LINE (vf_myfile, 'rm '||vv_repertoire||'/'||vv_prog_name||'*.*');
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
              -- Début modification EMA du 04/07/2005
              -- vv_line := 'cp $APPLCSF/out/o'||vt_traitement(vn_indice).request_id||'.out '||vv_repertoire||'/'||
              --            vt_traitement(vn_indice).program_name||'_'||vt_traitement(vn_indice).company_name||'_'||
              --            vt_traitement(vn_indice).period_name||'.out';
              vv_line := 'cp $APPLCSF/$APPLOUT/o'||vt_traitement(vn_indice).request_id||'.out '||vv_repertoire||'/'||
                         vt_traitement(vn_indice).program_name||'_'||vt_traitement(vn_indice).company_name||'_'||
                         vt_traitement(vn_indice).period_name||'.out';
              -- Fin modification EMA du 04/07/2005
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

    DBMS_OUTPUT.PUT_LINE (CHR(10)||'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements lances               : '||TO_CHAR(vn_trt_lances, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines normalement : '||TO_CHAR(vn_trt_normal, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));

    -- Remise à jour de la table dka_auto_etat
    ------------------------------------------
    BEGIN
        /*UPDATE dka_auto_etat
        SET    entite_operationnelle = NULL,
               entite_legale         = NULL,
               start_period_name     = NULL,
               end_period_name       = NULL,
               last_updated_by       = FND_PROFILE.VALUE('USER_ID'),
               last_update_date      = SYSDATE
        WHERE  program_short_name    = vv_prog_name;
        */
--RBE MigR12
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

EXCEPTION
    WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE (vv_prog_name || ' ==> ERREUR : ' || SQLERRM);
         :ret_code := 'FAILURE';
END;
/
/*<TOAD_FILE_CHUNK>*/
COL :utl_file_name NEW_VALUE utl_file_name;
COL :code_bande    NEW_VALUE code_bande;
SELECT :utl_file_name
FROM   DUAL;
SELECT :code_bande
FROM   DUAL;
HOST ls &utl_file_name;
HOST sh &utl_file_name;
HOST ksh $DKA_TOP/bin/DKA_AMOR_FISC_BOR.sh &code_bande

COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code