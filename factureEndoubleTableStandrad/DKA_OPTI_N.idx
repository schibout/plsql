create or replace PACKAGE BODY Dka_Tools_Pkg
AS

----------------------------------------------------------------------------------------------
-- $Id$
--
-- NOM               : DKA_TOOLS_PKG.pkb
-- DESCRIPTION       : DKA_TOOLS_PKG package body : fonctions communes
---
--- AUTEUR           : J.JARDEZ
--- DATE DE CREATION : 16/03/2016
--- DOC. ASSOCIEE    :
---
----------------------------------------------------------------------------------------------
--- NOM DU PROGRAMME :
--- PARAMETRES       :
---
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  16/03/2016 JJA Portage Helios 2016
--  07/06/2016 MEG Ajout de la procedure Create_Table_Online_Patching

--------------------------------------------------------------------------------------------

     BOUNDARY       CONSTANT VARCHAR2(256) := '=_NextPart_DC7E1BB5_1105_4DB3_BAE3_2A6208EB099D';
     FIRST_BOUNDARY CONSTANT VARCHAR2(256) := '--' || BOUNDARY ||
                                              utl_tcp.CRLF;
     LAST_BOUNDARY  CONSTANT VARCHAR2(256) := '--' || BOUNDARY || '--' ||
                                              utl_tcp.CRLF;
     gv_new_line    VARCHAR2(5)            := CHR(10);
     gv_error_stack VARCHAR2(32000)        := NULL;

-----------------------------------------------------------------
--  Nom           : NUMERIC_CHECK
--  Description   : Fonction de contrôle de la présence exclusive
--                  de caracteres numériques dans un champ
--
--  PARAMETRES :
--     pv_field     Entrée      Champ a contrôler
--
--  VALEUR RETOURNEE :
--     Description       :  code retour de validité
--     Valeurs possibles :  '0'=OK, '1'=contient des caracteres non numériques
-----------------------------------------------------------------
    FUNCTION numeric_check (
        pv_field   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_return_code   NUMBER;
    BEGIN
        ----- on remplace tous les caracteres blancs par 'X'
        ----- puis tous les caracteres numériques acceptés par ' '
        ----- on supprime les caracteres blancs de droite
        ----- donc avec le decode la chaine vide signifiant qu'il n'y avait que du numérique devient '0'
        ----- toute autre valeur obtenue renvoie '1' -----
        SELECT DECODE (RTRIM (TRANSLATE (REPLACE (pv_field, ' ', 'X'), '1234567890', '          ')), '', '0', '1')
        INTO   vv_return_code
        FROM   sys.DUAL;

        ----- retour -----
        RETURN (vv_return_code);
    END numeric_check;


-----------------------------------------------------------------
--  Nom           : PUT_DEBUG_MESSAGE
--  Description   : Procédure insérant un message dans le log du
--                  traitement si on est en mode debug
--
--  PARAMETRES :
--     pv_message   Entrée      Message a insérer
--
--  VALEUR RETOURNEE :
--     N/A
-----------------------------------------------------------------
    PROCEDURE put_debug_message (
        Pv_Message   IN   VARCHAR2
    )
    IS
        vv_message   VARCHAR2 (1000);
    BEGIN
        IF gv_debug_mode = 'Y'
        THEN
            vv_message    := SUBSTR (Pv_Message, 1, 1000);

            IF (vv_message IS NOT NULL)
            THEN
                vv_message    := SUBSTR (TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || vv_message, 1, 1000);
            END IF;

            Fnd_File.put_line (Fnd_File.LOG, vv_message);
        END IF;
    END put_debug_message;


-----------------------------------------------------------------
--  Nom           : PUT_LOG_MESSAGE
--  Description   : Procédure insérant un message dans le log du
--                  traitement.
--
--  PARAMETRES :
--     pv_message   Entrée      Message a insérer
--
--  VALEUR RETOURNEE :
--     N/A
-----------------------------------------------------------------
    PROCEDURE put_log_message (
        Pv_Message   IN   VARCHAR2
    )
    IS
        vv_message   VARCHAR2 (1000);
    BEGIN
        vv_message    := SUBSTR (Pv_Message, 1, 1000);

        IF (vv_message IS NOT NULL)
        THEN
            vv_message    := TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || vv_message;
        END IF;

        Fnd_File.put_line (Fnd_File.LOG, vv_message);
    END put_log_message;

    -----------------------------------------------------------------
--  Nom           : PUT_OUTDEBUG_MESSAGE
--  Description   : Procédure insérant un message a la fois dans le log du
--                  traitement si on est en mode debug et dans le fichier
--                  de sortie
--
--  PARAMETRES :
--     pv_message   Entrée      Message a insérer
--
--  VALEUR RETOURNEE :
--     N/A
-----------------------------------------------------------------
    PROCEDURE put_outdebug_message (
        Pv_Message   IN   VARCHAR2
    )
    IS
    BEGIN
        ----- Ecriture dans le fichier de sortie -----
        Fnd_File.put_line (Fnd_File.output, Pv_Message);
        ----- Ecriture dans le journal de traitement -----
        Dka_Tools_Pkg.put_debug_message (Pv_Message);
    END put_outdebug_message;


-----------------------------------------------------------------
--  Nom           : PUT_OUT_HEADER
--  Description   : Procédure insérant une entete dans le fichier
--                  de sortie avec comme titre le nom du traitement
--                  la date et l'heure de lancement.
--
--  PARAMETRES :
--     N/A
--
--  VALEUR RETOURNEE :
--     N/A
-----------------------------------------------------------------
    PROCEDURE put_out_header
    IS
        cv_line                     VARCHAR2 (100);
        vv_conc_program_name        fnd_concurrent_programs.concurrent_program_name%TYPE;
        vv_user_conc_program_name   fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
    BEGIN
        cv_line    := '+-------------------------------------------------------------------------+';
        Fnd_File.put_line (Fnd_File.output, cv_line);
        Fnd_File.put_line (Fnd_File.output, '');
        Fnd_File.put_line (Fnd_File.output, Fnd_Global.application_name);
        Fnd_File.put_line (Fnd_File.output, '');

        ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
        BEGIN
            SELECT fcp.concurrent_program_name,
                   fcpt.user_concurrent_program_name
            INTO   vv_conc_program_name,
                   vv_user_conc_program_name
            FROM   fnd_concurrent_programs fcp,
                   fnd_concurrent_programs_tl fcpt
            WHERE      fcp.application_id = Fnd_Global.prog_appl_id
                   AND fcp.concurrent_program_id = Fnd_Global.conc_program_id
                   AND fcpt.application_id = Fnd_Global.prog_appl_id
                   AND fcpt.concurrent_program_id = Fnd_Global.conc_program_id
                   AND fcpt.LANGUAGE = Fnd_Global.current_language;
        EXCEPTION
            WHEN OTHERS
            THEN
                vv_user_conc_program_name    := '???????????????????????';
                vv_conc_program_name         := '???????';
        END;

        Fnd_File.put_line (Fnd_File.output, 'Nom du traitement : ' || vv_user_conc_program_name);
        Fnd_File.put_line (Fnd_File.output, 'Code du traitement : ' || vv_conc_program_name);
        Fnd_File.put_line (Fnd_File.output, 'Numéro du traitement : ' || Fnd_Global.conc_request_id);
        Fnd_File.put_line (Fnd_File.output, cv_line);
        Fnd_File.put_line (Fnd_File.output, '');
        Fnd_File.put_line (Fnd_File.output, 'Date et heure systeme : ' || TO_CHAR (SYSDATE));
        Fnd_File.put_line (Fnd_File.output, '');
        Fnd_File.put_line (Fnd_File.output, cv_line);
        Fnd_File.put_line (Fnd_File.output, '');
    END put_out_header;

-----------------------------------------------------------------
--  Nom           : GET_FILENAME
--  Description   : Fonction qui détermine le nom d'un fichier a partir
--                  de son masque
--
--  PARAMETRES :
--     pv_filename_format Entrée      Champ a contrôler
--
--  VALEUR RETOURNEE :
--     Description       :  Nom du fichier
--     Valeurs possibles :
-----------------------------------------------------------------
    FUNCTION get_filename (
        pv_filename_format   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_filename                  VARCHAR2 (50);
        vv_set_of_books_short_name   gl_sets_of_books.short_name%TYPE;
    BEGIN
        -- Initialisation
        vv_filename    := pv_filename_format;

        -- SOB est remplacé par le short_name de l'entité comptable
        SELECT  gl.short_name
        INTO     vv_set_of_books_short_name
        FROM
         gl_access_set_assignments gasa,
         gl_ledger_names_v gl
        WHERE
             access_set_id =  Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
         AND gl.ledger_id = gasa.ledger_id
         ;

        vv_filename    := TRANSLATE (vv_filename, 'SOB', vv_set_of_books_short_name);
        ----- retour -----
        RETURN (vv_filename);
    END get_filename;


-----------------------------------------------------------------
--  Nom           : GET_ENVIRONMENT_VARIABLE
--  Description   : Fonction qui détermine la valeur d'une variable
--                  d'environnement
--                  /!\ Ne fonctionne que dans un traitement simultané
--
--  PARAMETRES :
--     pv_variable_name   Entrée      Nom de la variable
--
--  VALEUR RETOURNEE :
--     Description       :  Valeur de la variable
--     Valeurs possibles :
-----------------------------------------------------------------
    FUNCTION get_environment_variable (
        pv_variable_name   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_value   fnd_env_context.VALUE%TYPE;
    BEGIN
        vv_value    := NULL;

        SELECT fec.VALUE
        INTO   vv_value
        FROM   fnd_env_context fec,
               fnd_concurrent_processes fcp
        WHERE      fcp.session_id = SYS_CONTEXT ('userenv', 'sessionid')
               AND fec.concurrent_process_id = fcp.concurrent_process_id
               AND fec.variable_name = pv_variable_name;

        RETURN vv_value;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN NULL;
    END get_environment_variable;


-----------------------------------------------------------------
--  Nom           : OPEN_UTL_FILE
--  Description   : Procédure qui ouvre un fichier pour UTL_FILE
--                  en écriture
--
--  PARAMETRES :
--      pv_path             Entrée      Répertoire du fichier
--      pv_filename         Entrée      Nom du fichier
--      pv_file             Sortie      Fichier
--      pv_err_msg          Sortie      Message d'erreur
--
--  VALEUR RETOURNEE :
--     Description       :  Fichier
--     Valeurs possibles :
-----------------------------------------------------------------
    PROCEDURE open_utl_file (
        pv_path       IN       VARCHAR2,
        pv_filename   IN       VARCHAR2,
        pv_file       OUT      UTL_FILE.file_type,
        pv_err_msg    OUT      VARCHAR2
    )
    IS
    BEGIN
        pv_err_msg    := NULL;
        pv_file       := UTL_FILE.fopen (pv_path, pv_filename, 'w');
    EXCEPTION
        WHEN UTL_FILE.invalid_path
        THEN
            pv_err_msg    := 'UTL ERROR: invalid path';
        WHEN UTL_FILE.invalid_mode
        THEN
            pv_err_msg    := 'UTL ERROR: invalid mode';
        WHEN UTL_FILE.invalid_filehandle
        THEN
            pv_err_msg    := 'UTL ERROR: invalid filehandle';
        WHEN UTL_FILE.invalid_operation
        THEN
            pv_err_msg    := 'UTL ERROR: invalid operation';
        WHEN UTL_FILE.read_error
        THEN
            pv_err_msg    := 'UTL ERROR: read error';
        WHEN UTL_FILE.write_error
        THEN
            pv_err_msg    := 'UTL ERROR: write error';
        WHEN UTL_FILE.internal_error
        THEN
            pv_err_msg    := 'UTL ERROR: internal error';
        WHEN OTHERS
        THEN
            pv_err_msg    := 'UTL ERROR: erreur inconnue';
    END open_utl_file;


-----------------------------------------------------------------
--  Nom           : OPEN_UTL_FILE
--  Description   : Procédure qui ouvre un fichier pour UTL_FILE
--                  en écriture
--
--  PARAMETRES :
--      pv_path             Entrée      Répertoire du fichier
--      pv_filename         Entrée      Nom du fichier
--      pv_file             Sortie      Fichier
--      pv_err_msg          Sortie      Message d'erreur
--
--  VALEUR RETOURNEE :
--     Description       :  Fichier
--     Valeurs possibles :
-----------------------------------------------------------------
    PROCEDURE open_utl_file_append (
        pv_path       IN       VARCHAR2,
        pv_filename   IN       VARCHAR2,
        pv_file       OUT      UTL_FILE.file_type,
        pv_err_msg    OUT      VARCHAR2
    )
    IS
    BEGIN
        pv_err_msg    := NULL;
        pv_file       := UTL_FILE.fopen (pv_path, pv_filename, 'a');
    EXCEPTION
        WHEN UTL_FILE.invalid_path
        THEN
            pv_err_msg    := 'UTL ERROR: invalid path';
        WHEN UTL_FILE.invalid_mode
        THEN
            pv_err_msg    := 'UTL ERROR: invalid mode';
        WHEN UTL_FILE.invalid_filehandle
        THEN
            pv_err_msg    := 'UTL ERROR: invalid filehandle';
        WHEN UTL_FILE.invalid_operation
        THEN
            pv_err_msg    := 'UTL ERROR: invalid operation';
        WHEN UTL_FILE.read_error
        THEN
            pv_err_msg    := 'UTL ERROR: read error';
        WHEN UTL_FILE.write_error
        THEN
            pv_err_msg    := 'UTL ERROR: write error';
        WHEN UTL_FILE.internal_error
        THEN
            pv_err_msg    := 'UTL ERROR: internal error';
        WHEN OTHERS
        THEN
            pv_err_msg    := 'UTL ERROR: erreur inconnue';
    END open_utl_file_append;


-----------------------------------------------------------------
--  Nom           : GET_MESSAGE
--  Description   : Procédure qui récupere des parametres
--
--  PARAMETRES :
--      pv_application           Entrée      Code de l'application
--      pv_name                  Entrée      Nom du message
--      pv_tokenx                Entrée      Nom des parametres dans le message
--      pv_valuex                Entrée      Valeur des parametres dans le message
--
--  VALEUR RETOURNEE :
--     Description       : Libellé du message
--     Valeurs possibles :
-----------------------------------------------------------------
    FUNCTION get_message (
        pv_application   IN   VARCHAR2,
        pv_name          IN   VARCHAR2,
        pv_token1        IN   VARCHAR2 DEFAULT NULL,
        pv_value1        IN   VARCHAR2 DEFAULT NULL,
        pv_token2        IN   VARCHAR2 DEFAULT NULL,
        pv_value2        IN   VARCHAR2 DEFAULT NULL,
        pv_token3        IN   VARCHAR2 DEFAULT NULL,
        pv_value3        IN   VARCHAR2 DEFAULT NULL,
        pv_token4        IN   VARCHAR2 DEFAULT NULL,
        pv_value4        IN   VARCHAR2 DEFAULT NULL,
        pv_token5        IN   VARCHAR2 DEFAULT NULL,
        pv_value5        IN   VARCHAR2 DEFAULT NULL,
        pv_token6        IN   VARCHAR2 DEFAULT NULL,
        pv_value6        IN   VARCHAR2 DEFAULT NULL,
        pv_token7        IN   VARCHAR2 DEFAULT NULL,
        pv_value7        IN   VARCHAR2 DEFAULT NULL,
        pv_token8        IN   VARCHAR2 DEFAULT NULL,
        pv_value8        IN   VARCHAR2 DEFAULT NULL,
        pv_token9        IN   VARCHAR2 DEFAULT NULL,
        pv_value9        IN   VARCHAR2 DEFAULT NULL,
        pv_token10       IN   VARCHAR2 DEFAULT NULL,
        pv_value10       IN   VARCHAR2 DEFAULT NULL
    )
        RETURN VARCHAR2
    IS
        manque_param   EXCEPTION;
    BEGIN
        IF    LENGTH (LTRIM (pv_application)) = 0
           OR LENGTH (LTRIM (pv_name)) = 0
        THEN
            RAISE manque_param;
        END IF;

        -- Recuperation du message
        Fnd_Message.set_name (pv_application, pv_name);

        -- Recuperation des Tokens
        IF pv_token1 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token1, pv_value1);
        END IF;

        IF pv_token2 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token2, pv_value2);
        END IF;

        IF pv_token3 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token3, pv_value3);
        END IF;

        IF pv_token4 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token4, pv_value4);
        END IF;

        IF pv_token5 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token5, pv_value5);
        END IF;

        IF pv_token6 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token6, pv_value6);
        END IF;

        IF pv_token7 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token7, pv_value7);
        END IF;

        IF pv_token8 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token8, pv_value8);
        END IF;

        IF pv_token9 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token9, pv_value9);
        END IF;

        IF pv_token10 IS NOT NULL
        THEN
            Fnd_Message.set_token (pv_token10, pv_value10);
        END IF;

        RETURN (Fnd_Message.get);
    EXCEPTION
        WHEN manque_param
        THEN
            RETURN ('ERREUR : Parametre manquant');
        WHEN OTHERS
        THEN
            RETURN ('ERREUR : '|| SQLCODE || ' : ' || SQLERRM (SQLCODE));
    END get_message;


-----------------------------------------------------------------
--  Nom           : GET_PARAMETER
--  Description   : Procédure qui récupere des parametres
--
--  PARAMETRES :
--      pv_program_code          Entrée      Nom du programme
--      pv_parameter_name        Entrée      Nom des parametres
--      pv_data                  Sortie      listes des parametres
--      pn_retcode               Sortie      Code erreur
--      pv_err_msg               Sortie      Message d'erreur
--
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
-----------------------------------------------------------------
    PROCEDURE get_parameter (
        pv_program_code     IN       VARCHAR2,
        pv_parameter_name   IN       VARCHAR2,
        pr_data             OUT      dka_parameters%ROWTYPE,
        pn_retcode          OUT      NUMBER,
        pv_err_msg          OUT      VARCHAR2
    )
    IS
    BEGIN
        ----- Initialisation des variables -----
        pv_err_msg    := NULL;
        pn_retcode    := 0;

        SELECT *
        INTO   pr_data
        FROM   dka_parameters dp
        WHERE      dp.program_code = pv_program_code
               AND dp.parameter_name = pv_parameter_name;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            pv_err_msg    := 'NO_DATA_FOUND';
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            pv_err_msg    := SQLERRM;
            pn_retcode    := SQLCODE;
    END get_parameter;


-----------------------------------------------------------------
--  Nom           : CHECK_DKA_PARAMETERS
--  Description   : Procédure qui liste les parametres non valides
--                  dans la table dka_parameters
--
--  PARAMETRES :
--
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
-----------------------------------------------------------------
    PROCEDURE check_dka_parameters (
        pv_program_code   IN   VARCHAR2 DEFAULT NULL
    )
    IS
        vn_nb_errors                 NUMBER;
        vn_result                    NUMBER;

        -- Variables pour la déclaration du curseur
        TYPE refcur IS REF CURSOR;

        check_parameter_cur          refcur;
        check_parameter_rec          dka_parameters%ROWTYPE;
        vv_check_parameter_cur_sql   VARCHAR2 (500);
        vv_message                   VARCHAR2 (250);
        vv_value                     VARCHAR2 (100);
        vv_value_column              VARCHAR2 (100);
        vv_sub_select                VARCHAR2 (50);
        vv_sub_from                  VARCHAR2 (100);
        vv_sub_where                 VARCHAR2 (300);
        vv_sub_sql                   VARCHAR2 (500);
        vv_select                    VARCHAR2 (300);
        vv_from                      VARCHAR2 (50);
        vv_where                     VARCHAR2 (1000);
        vv_sql                       VARCHAR2 (1500);
    BEGIN
        DBMS_OUTPUT.ENABLE (1000000);
        vn_nb_errors                  := 0;

---------------------------------------------------------------------------------------------
-- Vérification que les valeurs présentes dans dka_parameters sont cohérentes avec le type --
---------------------------------------------------------------------------------------------
-- Construction du curseur dynamique
        vv_check_parameter_cur_sql    :=
                   'SELECT DISTINCT ''Valeur de type incohérent : '' || dp.program_code || '' -> '' || dp.parameter_name'
                || ' FROM dka_parameters dp'
                || ' WHERE ((    dp.data_type != ''VARCHAR2'''
                || '         AND dp.varchar2_value IS NOT NULL)'
                || '     OR (    dp.data_type != ''NUMBER'''
                || '         AND dp.number_value IS NOT NULL)'
                || '     OR (    dp.data_type != ''DATE'''
                || '         AND dp.date_value IS NOT NULL)'
                || '     OR (    dp.data_type != ''BOOLEAN'''
                || '         AND dp.boolean_value IS NOT NULL))';

        IF pv_program_code IS NOT NULL
        THEN
            vv_check_parameter_cur_sql    := vv_check_parameter_cur_sql || ' AND dp.program_code = ''' || pv_program_code || '''';
        END IF;

        vv_check_parameter_cur_sql    := vv_check_parameter_cur_sql || ' ORDER BY 1';
        -- Ouverture du curseur dynamique
        OPEN check_parameter_cur FOR vv_check_parameter_cur_sql;

        LOOP
            FETCH check_parameter_cur INTO vv_message;
            EXIT WHEN check_parameter_cur%NOTFOUND;
            vn_nb_errors    := vn_nb_errors + 1;
            DBMS_OUTPUT.put_line (vv_message);
        END LOOP;


----------------------------------------------------------------------------------------------
-- Vérification que les valeurs présentes dans dka_parameters sont cohérentes avec le Setup --
----------------------------------------------------------------------------------------------
-- Construction du curseur dynamique
        vv_check_parameter_cur_sql    := 'SELECT *' || ' FROM dka_parameters ' || ' WHERE table_name IS NOT NULL';

        IF pv_program_code IS NOT NULL
        THEN
            vv_check_parameter_cur_sql    := vv_check_parameter_cur_sql || ' AND program_code = ''' || pv_program_code || '''';
        END IF;

        vv_check_parameter_cur_sql    := vv_check_parameter_cur_sql || ' ORDER BY program_code, parameter_name';
        -- Ouverture du curseur dynamique
        OPEN check_parameter_cur FOR vv_check_parameter_cur_sql;

        LOOP
            FETCH check_parameter_cur INTO check_parameter_rec;
            EXIT WHEN check_parameter_cur%NOTFOUND;
            -- Construction de la sous-requete
            vv_value_column    := check_parameter_rec.data_type || '_VALUE';
            vv_sub_select      := 'SELECT 1';
            vv_sub_from        := ' FROM ' || check_parameter_rec.table_name || ' T, dka_parameters P';
            vv_sub_where       :=    ' WHERE '
                                  || check_parameter_rec.column_name
                                  || ' = P.'
                                  || vv_value_column
                                  || ' AND P.program_code = '''
                                  || check_parameter_rec.program_code
                                  || ''''
                                  || ' AND P.parameter_name = '''
                                  || check_parameter_rec.parameter_name
                                  || '''';
            vv_sub_sql         := vv_sub_select || vv_sub_from || vv_sub_where;
            -- Construction de la requete principale
            vv_select          := 'SELECT COUNT(1)';
            vv_from            := ' FROM dual';
            vv_where           := ' WHERE NOT EXISTS ( ' || vv_sub_sql || ' ) ';
            vv_sql             := vv_select || vv_from || vv_where;
            --DBMS_OUTPUT.PUT_LINE(chr(10) || 'Requete complete :');
            --DBMS_OUTPUT.PUT_LINE(vv_sql);

            EXECUTE IMMEDIATE vv_sql
                INTO vn_result;

            IF vn_result > 0
            THEN
                vn_nb_errors    := vn_nb_errors + 1;
                EXECUTE IMMEDIATE    'SELECT '
                                  || vv_value_column
                                  || ' FROM dka_parameters'
                                  || ' WHERE program_code = '''
                                  || check_parameter_rec.program_code
                                  || ''''
                                  || ' AND parameter_name = '''
                                  || check_parameter_rec.parameter_name
                                  || ''''
                    INTO vv_value;
                DBMS_OUTPUT.put_line (
                       'Valeur incorrecte : '
                    || check_parameter_rec.program_code
                    || ' -> '
                    || check_parameter_rec.parameter_name
                    || ' -> '
                    || vv_value
                    || ' <-> '
                    || check_parameter_rec.description
                );
            END IF;
        END LOOP;

        CLOSE check_parameter_cur;

---------------------
-- Affichage final --
---------------------
        DBMS_OUTPUT.put_line (
               CHR (10)
            || CHR (10)
            || '--> '
            || TO_CHAR (vn_nb_errors)
            || ' parametre(s) incorrect(s).'
            || CHR (10)
            || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS')
        );
    END check_dka_parameters;

----------------------------------------------------------------------------------------
--  Nom           : GET_CODE_COMBINATION_ID
--  Description   : Procédure permettant de déterminer le code_combination_id
--                  correspondant a la combinaison passée en parametre
--                  Si la combinaison n'existe pas, elle est créée
--                  Si la combinaison n'existe pas, elle est créée
--  PARAMETRES :
--    pv_segment1       Entrée
--    pv_segment2       Entrée
--    pv_segment3       Entrée
--    pv_segment4       Entrée
--    pv_segment5       Entrée
--    pv_segment6       Entrée
--    pv_segment7       Entrée
--    pv_segment8       Entrée
--    pv_segment9       Entrée
--    pv_segment10      Entrée
--    pv_segment11      Entrée
--    pv_segment12      Entrée
--
--    pn_ccid           Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
----------------------------------------------------------------------------------------
    PROCEDURE get_code_combination_id (
        pv_segment1              IN       VARCHAR2,
        pv_segment2              IN       VARCHAR2,
        pv_segment3              IN       VARCHAR2,
        pv_segment4              IN       VARCHAR2,
        pv_segment5              IN       VARCHAR2,
        pv_segment6              IN       VARCHAR2,
        pv_segment7              IN       VARCHAR2,
        pv_segment8              IN       VARCHAR2,
        pv_segment9              IN       VARCHAR2,
        pv_segment10             IN       VARCHAR2,
        pv_segment11             IN       VARCHAR2,
        pv_segment12             IN       VARCHAR2,
        pn_code_combination_id   OUT      NUMBER,
        pv_errbuf                OUT      VARCHAR2,
        pn_retcode               OUT      NUMBER,
        pv_validation_flag       IN       VARCHAR2 DEFAULT 'Y'
    )
    IS
        vb_dummy                    BOOLEAN;
        va_segments_array           Fnd_Flex_Ext.segmentarray;
        vn_nb_segments              NUMBER;
        vv_application_short_name   fnd_application.application_short_name%TYPE;
        vv_key_flex_code            fnd_id_flex_segments.id_flex_code%TYPE;
        vn_structure_number         fnd_id_flex_segments.id_flex_num%TYPE;
        vd_validation_date          DATE;
        vn_code_combination_id      gl_code_combinations.code_combination_id%TYPE;
    BEGIN
        -- Initialisation des variables de sortie
        pv_errbuf                    := NULL;
        pn_retcode                   := 0;
        -- Initialisation des variables
        vd_validation_date           := SYSDATE;
        vv_key_flex_code             := 'GL#';
        vv_application_short_name    := 'SQLGL';

        select  fifs.id_flex_num,count(1)
        INTO     vn_structure_number,
                 vn_nb_segments
        from
         (select *
          from gl_access_set_assignments
          where access_set_id =  Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
          and rownum = 1) gasa,
         gl_ledgers gl,
         FND_ID_FLEX_SEGMENTS fifs
        where
             gl.ledger_id = gasa.ledger_id
         and gl.ledger_category_code = 'PRIMARY'
         and gl.chart_of_accounts_id = fifs.id_flex_num
         AND fifs.application_id = 101
         AND fifs.id_flex_code =  'GL#'
         and fifs.enabled_flag = 'Y'
         GROUP BY fifs.id_flex_num;

        -- Si la vérification des regles n'est pas nécessaire, on regarde si la combinaison existe
        -- Dans ce cas, on retourne ce ccid directement
        IF pv_validation_flag = 'N'
        THEN
            BEGIN
                SELECT gcc.code_combination_id
                INTO   pn_code_combination_id
                FROM   gl_code_combinations gcc
                WHERE      gcc.chart_of_accounts_id = vn_structure_number
                       AND gcc.segment1 = pv_segment1
                       AND gcc.segment2 = pv_segment2
                       AND gcc.segment3 = pv_segment3
                       AND gcc.segment4 = pv_segment4
                       AND gcc.segment5 = pv_segment5
                       AND gcc.segment6 = pv_segment6
                       AND gcc.segment7 = pv_segment7
                       AND gcc.segment8 = pv_segment8
                       AND gcc.segment9 = pv_segment9
                       AND gcc.segment10 = pv_segment10
                       AND gcc.segment11 = pv_segment11
                       AND gcc.segment12 = pv_segment12;

                -- On a trouvé la combinaison, donc on sort
                RETURN;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    NULL;
            END;
        END IF;

        -- Remplissage de la variable Array
        va_segments_array (1)        := pv_segment1;
        va_segments_array (2)        := pv_segment2;
        va_segments_array (3)        := pv_segment3;
        va_segments_array (4)        := pv_segment4;
        va_segments_array (5)        := pv_segment5;
        va_segments_array (6)        := pv_segment6;
        va_segments_array (7)        := pv_segment7;
        va_segments_array (8)        := pv_segment8;
        va_segments_array (9)        := pv_segment9;
        va_segments_array (10)       := pv_segment10;
        va_segments_array (11)       := pv_segment11;
        va_segments_array (12)       := pv_segment12;

        -- Lancement de la fonction standard de détermination / génération du ccid
        vb_dummy                     := Fnd_Flex_Ext.get_combination_id (
                                            vv_application_short_name,
                                            vv_key_flex_code,
                                            vn_structure_number,
                                            vd_validation_date,
                                            vn_nb_segments,
                                            va_segments_array,
                                            vn_code_combination_id
                                        );

        -- En cas d'erreur, récupération du message
        IF NOT vb_dummy
        THEN
            pv_errbuf                 :=    pv_segment1
                                         || '.'
                                         || pv_segment2
                                         || '.'
                                         || pv_segment3
                                         || '.'
                                         || pv_segment4
                                         || '.'
                                         || pv_segment5
                                         || '.'
                                         || pv_segment6
                                         || '.'
                                         || pv_segment7
                                         || '.'
                                         || pv_segment8
                                         || '.'
                                         || pv_segment9
                                         || '.'
                                         || pv_segment10
                                         || '.'
                                         || pv_segment11
                                         || '.'
                                         || pv_segment12
                                         || ' : '
                                         || Fnd_Flex_Ext.get_message;
            pn_retcode                := 2;
            pn_code_combination_id    := NULL;
        ELSE
            pn_code_combination_id    := vn_code_combination_id;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := 'GET_CODE_COMBINATION_ID - ' || SQLERRM;
            pn_retcode    := SQLCODE;
    END get_code_combination_id;

----------------------------------------------------------------------------------------
--  Nom           : GET_CODE_COMBINATION_ID
--  Description   : Procédure permettant de déterminer le code_combination_id
--                  correspondant a la combinaison passée en parametre
--                  Si la combinaison n'existe pas, elle est créée
--                  Si la combinaison n'existe pas, elle est créée
--  PARAMETRES :
--    pv_clef       Entrée

--
--    pn_ccid           Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
----------------------------------------------------------------------------------------
    PROCEDURE get_code_combination_id (
		    pv_clef					         IN       VARCHAR2,
        pn_code_combination_id   OUT      NUMBER,
        pv_errbuf                OUT      VARCHAR2,
        pn_retcode               OUT      NUMBER,
        pv_validation_flag       IN       VARCHAR2 DEFAULT 'Y'
    )
    IS

      vv_errbuf                VARCHAR2(500);
      vn_retcode 						   NUMBER;
      vn_code_combination_id	 NUMBER;

      vv_segment1              VARCHAR2(150);
      vv_segment2              VARCHAR2(150);
      vv_segment3              VARCHAR2(150);
      vv_segment4              VARCHAR2(150);
      vv_segment5              VARCHAR2(150);
      vv_segment6              VARCHAR2(150);
      vv_segment7              VARCHAR2(150);
      vv_segment8              VARCHAR2(150);
      vv_segment9              VARCHAR2(150);
      vv_segment10             VARCHAR2(150);
      vv_segment11             VARCHAR2(150);
      vv_segment12             VARCHAR2(150);
      v_exception              EXCEPTION;

    BEGIN

      vv_segment1  := substr(pv_clef,instr(pv_clef,'.',0,1),instr(pv_clef,'.',1,1)-1);
      vv_segment2  := substr(pv_clef,instr(pv_clef,'.',1,1)+1,instr(pv_clef,'.',1,2) - instr(pv_clef,'.',1,1)-1);
      vv_segment3  := substr(pv_clef,instr(pv_clef,'.',1,2)+1,instr(pv_clef,'.',1,3) - instr(pv_clef,'.',1,2)-1);
      vv_segment4  := substr(pv_clef,instr(pv_clef,'.',1,3)+1,instr(pv_clef,'.',1,4) - instr(pv_clef,'.',1,3)-1);
      vv_segment5  := substr(pv_clef,instr(pv_clef,'.',1,4)+1,instr(pv_clef,'.',1,5) - instr(pv_clef,'.',1,4)-1);
      vv_segment6  := substr(pv_clef,instr(pv_clef,'.',1,5)+1,instr(pv_clef,'.',1,6) - instr(pv_clef,'.',1,5)-1);
      vv_segment7  := substr(pv_clef,instr(pv_clef,'.',1,6)+1,instr(pv_clef,'.',1,7) - instr(pv_clef,'.',1,6)-1);
      vv_segment8  := substr(pv_clef,instr(pv_clef,'.',1,7)+1,instr(pv_clef,'.',1,8) - instr(pv_clef,'.',1,7)-1);
      vv_segment9  := substr(pv_clef,instr(pv_clef,'.',1,8)+1,instr(pv_clef,'.',1,9) - instr(pv_clef,'.',1,8)-1);
      vv_segment10 := substr(pv_clef,instr(pv_clef,'.',1,9)+1,instr(pv_clef,'.',1,10) - instr(pv_clef,'.',1,9)-1);
      vv_segment11 := substr(pv_clef,instr(pv_clef,'.',1,10)+1,instr(pv_clef,'.',1,11) - instr(pv_clef,'.',1,10)-1);
  		vv_segment12 := substr(pv_clef,instr(pv_clef,'.',1,11)+1);

      get_code_combination_id(vv_segment1,
                              vv_segment2,
                              vv_segment3,
                              vv_segment4,
                              vv_segment5,
                              vv_segment6,
                              vv_segment7,
                              vv_segment8,
                              vv_segment9,
                              vv_segment10,
                              vv_segment11,
                              vv_segment12,
                              vn_code_combination_id,
                              vv_errbuf,
                              vn_retcode,
                              pv_validation_flag);

      pn_code_combination_id := vn_code_combination_id;
  		pv_errbuf              := vv_errbuf;
  		pn_retcode             := vn_retcode;

    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := 'GET_CODE_COMBINATION_ID - ' || SQLERRM;
            pn_retcode    := SQLCODE;
    END get_code_combination_id;


-------------------------------------------------------------------------------------------------------------------

--  Nom           : SEGMENT_SIZE
--  Description   : Retourne la longueur d'un segment de clé passé en
--  parametre
--
--  PARAMETRES    :
--    pn_segment_num  NUMBER
--  VALEUR RETOURNEE :
--     Valeurs possibles :     0 : ERREUR
--                         Autre : deroulement sans erreur
-------------------------------------------------------------------------------------------------------------------

    FUNCTION segment_size (pn_segment_num IN NUMBER) RETURN NUMBER IS
        CURSOR cur_size (p_seg_num IN NUMBER) IS
        SELECT fifs.display_size
        FROM   fnd_id_flex_segments fifs,
               --gl_sets_of_books gsob,
               gl_access_set_assignments gasa,
               gl_ledgers gl,
               fnd_application fa
        WHERE  1 = 1
        AND access_set_id =  Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
        AND gl.ledger_id = gasa.ledger_id
        AND gl.ledger_category_code = 'PRIMARY'
        AND gl.chart_of_accounts_id = fifs.id_flex_num
        AND    fifs.application_id       = fa.application_id
        AND    fa.application_short_name = 'SQLGL'
        AND    fifs.id_flex_code         = 'GL#'
        AND    fifs.segment_num          = p_seg_num;
        vn_size NUMBER;
    BEGIN
        OPEN cur_size (pn_segment_num);
        FETCH cur_size INTO vn_size;
        IF cur_size%NOTFOUND THEN
            CLOSE cur_size;
            RETURN 0;
        END IF;
        CLOSE cur_size;

        RETURN vn_size;
    END segment_size;

    ---------------------------------------------------------------------------------------
--  Nom           : get_flex_key_seg_value_set
--  Description   : Renvoie l'id et le nom du jeu de valeur d'un segment d'une des clés
---------------------------------------------------------------------------------------
    PROCEDURE get_flex_key_seg_value_set (
        pv_errbuf                OUT      VARCHAR2,
        pn_retcode               OUT      NUMBER,
        pv_legal_flex_key_flag   IN       VARCHAR2 DEFAULT 'N',-- = 'Y' si on considere la ccf des organisations légales
        pn_segment_num           IN       NUMBER,
        pn_flex_value_set_id     OUT      NUMBER,
        pv_flex_value_set_name   OUT      VARCHAR2
    )
    IS
        ln_flex_value_set_id     fnd_flex_value_sets.flex_value_set_id%TYPE;
        lv_flex_value_set_name   fnd_flex_value_sets.flex_value_set_name%TYPE;
    BEGIN
        SELECT ffs.flex_value_set_id,
               ffs.flex_value_set_name
        INTO   ln_flex_value_set_id,
               lv_flex_value_set_name
        FROM   fnd_id_flex_structures_vl fifst,
               fnd_id_flex_segments fifs,
               fnd_flex_value_sets ffs
        WHERE      fifst.id_flex_structure_code =
                                DECODE (pv_legal_flex_key_flag, 'Y', 'ACCOUNTING_FLEXFIELD_LEGAL',
                                           (SELECT DISTINCT fifst2.ID_FLEX_STRUCTURE_CODE
                                               FROM fnd_id_flex_structures_vl fifst2,
                                                   gl_access_sets gasa
                                             WHERE  fifst2.id_flex_code = 'GL#'
                                               AND access_set_id = Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
                                              AND gasa.chart_of_accounts_id = fifst2.id_flex_num
                                            )
                                        )
               AND fifst.application_id = 101
               AND fifst.id_flex_code = 'GL#'
               AND fifs.application_id = fifst.application_id
               AND fifs.id_flex_code = fifst.id_flex_code
               AND fifs.id_flex_num = fifst.id_flex_num
               AND fifs.segment_num = pn_segment_num
               AND ffs.flex_value_set_id = fifs.flex_value_set_id;

        pn_flex_value_set_id      := ln_flex_value_set_id;
        pv_flex_value_set_name    := lv_flex_value_set_name;
        pn_retcode                := 0;
        pv_errbuf                 := NULL;
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 1;
            pv_errbuf     := 'DKA_TOOLS.get_flex_key_seg_value_set:' || SQLERRM;
    END get_flex_key_seg_value_set;


---------------------------------------------------------------------------------------
--  Nom           : ins_prog_message
--  Description   : Insere un message dans la table d'erreurs DKA_PROGRAM_MESSAGES
--     NB         :  cette proc s'exécute dans une transaction propre et fait un commit
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE ins_prog_message (
        pn_request_id     IN   NUMBER,
        pv_prog_name      IN   VARCHAR2,
        pv_source         IN   VARCHAR2 DEFAULT 'ETL',
        pv_table_name     IN   VARCHAR2,
        pv_table_id       IN   VARCHAR2,
        pv_column_name    IN   VARCHAR2,
        pv_column_value   IN   VARCHAR2,
        pv_message_type   IN   VARCHAR2 DEFAULT 'E',
        pv_message_text   IN   VARCHAR2
    )
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO dka_program_messages
                    (request_id,
                     prog_name,
                     SOURCE,
                     table_name,
                     table_id,
                     column_name,
                     column_value,
                     message_type,
                     message_text
                    )
        VALUES      (pn_request_id, --request_id
                     pv_prog_name, --prog_name
                     pv_source, --source
                     pv_table_name, --table_name
                     pv_table_id, --table_id
                     pv_column_name, --column_name
                     pv_column_value, --column_value
                     pv_message_type, --message_type
                     pv_message_text --message_text
                    );

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR (-20000, 'DKA_TOOLS_PKG.ins_prog_message:' || SQLERRM);
    END ins_prog_message;


------------------------------------------------------------------------------------
--  Nom           : GET_CUF_FLEX_VALUE
--  Description   : Cette procédure permet de récupérer les valeurs des CUF associées a
--                  une valeur de jeu de valeurs
--
--  PARAMETRES    :
--  pv_flex_value
--  pv_flex_value_set_name
--  VALEUR RETOURNEE :
--     CUF (tab_cuf_flex_value) : Tableau regroupant toutes les valeurs d'attributes
--     Description       : 0 si tout se deroule correctement, 2 sinon.
--     Valeurs possibles : En cas d'erreur elle retourne le message d'erreur ORA SQLERRM.
------------------------------------------------------------------------------------

    PROCEDURE get_cuf_flex_value (
               pv_flex_value          IN   VARCHAR2
             , pv_flex_value_set_name IN   VARCHAR2
             , pv_errbuf              OUT  VARCHAR2
             , pn_retcode             OUT  NUMBER
    )
    IS
        vv_attribute_value             VARCHAR2(250);
        sql_req                        VARCHAR2(500);

    BEGIN
        pv_errbuf := NULL;
        pn_retcode := 0;


             FOR i IN 1 .. 50
             LOOP

                 BEGIN
                 sql_req := 'SELECT ffv.attribute'||i||
                            ' FROM fnd_flex_values ffv, fnd_flex_value_sets ffvs '||
                            'WHERE ffv.flex_value_set_id = ffvs.flex_value_set_id'||
                            '  AND ffvs.flex_value_set_name = :pv_flex_value_set_name'||
                            '  AND ffv.flex_value = :pv_flex_value';

                 EXECUTE IMMEDIATE sql_req INTO vv_attribute_value USING pv_flex_value_set_name, pv_flex_value;

                 tab_cuf_flex_value(i) := vv_attribute_value;

                 EXCEPTION
                 WHEN NO_DATA_FOUND
                 THEN
                      tab_cuf_flex_value(i) := NULL;
                 END;

             END LOOP;


    EXCEPTION
        WHEN OTHERS THEN
              pn_retcode := 2;
              pv_errbuf := 'DKA_TOOLS_PKG.get_cuf_flex_value:' || SQLERRM;
              dka_tools_pkg.put_debug_message(pv_errbuf);
    END get_cuf_flex_value;



----------------------------------------------------------------------------------------
--  Nom           : GET_SEGMENTS_FROM_CCID
--  Description   : Procédure permettant de déterminer les segments
--                  correspondant a la combinaison a partir du code_combination_id
--  PARAMETRES :
--    pn_ccid                       Entrée
--    pv_segment1                   Sortie
--    pv_segment2                   Sortie
--    pv_segment3                   Sortie
--    pv_segment4                   Sortie
--    pv_segment5                   Sortie
--    pv_segment6                   Sortie
--    pv_segment7                   Sortie
--    pv_segment8                   Sortie
--    pv_segment9                   Sortie
--    pv_segment10                  Sortie
--    pv_segment11                  Sortie
--    pv_segment12                  Sortie
--    pv_concateneted_segments      Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
----------------------------------------------------------------------------------------
    PROCEDURE get_segments_from_ccid (
        pn_code_combination_id     IN       NUMBER,
        pv_segment1                OUT      VARCHAR2,
        pv_segment2                OUT      VARCHAR2,
        pv_segment3                OUT      VARCHAR2,
        pv_segment4                OUT      VARCHAR2,
        pv_segment5                OUT      VARCHAR2,
        pv_segment6                OUT      VARCHAR2,
        pv_segment7                OUT      VARCHAR2,
        pv_segment8                OUT      VARCHAR2,
        pv_segment9                OUT      VARCHAR2,
        pv_segment10               OUT      VARCHAR2,
        pv_segment11               OUT      VARCHAR2,
        pv_segment12               OUT      VARCHAR2,
        pv_concateneted_segments   OUT      VARCHAR2,
        pv_errbuf                  OUT      VARCHAR2,
        pn_retcode                 OUT      NUMBER
    )
    IS
    BEGIN
        pn_retcode    := 0;
        pv_errbuf     := NULL;

        SELECT gcc.segment1,
               gcc.segment2,
               gcc.segment3,
               gcc.segment4,
               gcc.segment5,
               gcc.segment6,
               gcc.segment7,
               gcc.segment8,
               gcc.segment9,
               gcc.segment10,
               gcc.segment11,
               gcc.segment12,
               (   gcc.segment1
                || fifs.concatenated_segment_delimiter
                || gcc.segment2
                || fifs.concatenated_segment_delimiter
                || gcc.segment3
                || fifs.concatenated_segment_delimiter
                || gcc.segment4
                || fifs.concatenated_segment_delimiter
                || gcc.segment5
                || fifs.concatenated_segment_delimiter
                || gcc.segment6
                || fifs.concatenated_segment_delimiter
                || gcc.segment7
                || fifs.concatenated_segment_delimiter
                || gcc.segment8
                || fifs.concatenated_segment_delimiter
                || gcc.segment9
                || fifs.concatenated_segment_delimiter
                || gcc.segment10
                || fifs.concatenated_segment_delimiter
                || gcc.segment11
                || fifs.concatenated_segment_delimiter
                || gcc.segment12
               )
        INTO   pv_segment1,
               pv_segment2,
               pv_segment3,
               pv_segment4,
               pv_segment5,
               pv_segment6,
               pv_segment7,
               pv_segment8,
               pv_segment9,
               pv_segment10,
               pv_segment11,
               pv_segment12,
               pv_concateneted_segments
        FROM   gl_code_combinations gcc,
               gl_access_set_assignments gasa,
               gl_ledgers gl,
               fnd_id_flex_structures fifs
        WHERE      gcc.code_combination_id = pn_code_combination_id
               AND fifs.application_id = 101
               AND fifs.id_flex_code = 'GL#'
               AND access_set_id =  Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
               AND gl.ledger_id = gasa.ledger_id
               AND gl.ledger_category_code = 'PRIMARY'
               AND gl.chart_of_accounts_id = fifs.id_flex_num
               ;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            pv_errbuf     := 'CCID inexistant';
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            pv_errbuf     := SQLERRM;
            pn_retcode    := SQLCODE;
    END get_segments_from_ccid;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_REQUEST_SET_PARAMS
--  Description   : Recuperation des parametres d un traitement ou jeu de traitements
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER

--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
--
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_request_set_params (
        pv_errbuf                   OUT      VARCHAR2,
        pn_retcode                  OUT      NUMBER,
        pn_application_id           IN       NUMBER,
        pn_request_set_id           IN       NUMBER DEFAULT NULL,
        pn_request_set_program_id   IN       NUMBER DEFAULT NULL,
        pn_prog_application_id      IN       NUMBER DEFAULT NULL,
        pn_program_id               IN       NUMBER DEFAULT NULL
    )
    IS
        --Selectionne les parametres dans la declaration du jeu
        CURSOR cur_req_set_params
        IS
            SELECT   a.descriptive_flex_appl_id,
                     u.end_user_column_name,
                     a.display_flag,
                     a.insert_flag,
                     a.update_flag,
                     a.default_type default_type_set,
                     a.default_value default_value_set,
                     u.default_type default_type_trt,
                     u.default_value default_value_trt,
                     a.shared_parameter_name,
                     u.flex_value_set_id,
                     ffvs.validation_type
            FROM     fnd_request_set_program_args a,
                     fnd_descr_flex_column_usages u,
                     fnd_concurrent_programs p,
                     fnd_flex_value_sets ffvs
            WHERE        a.application_id(+) = pn_application_id
                     AND a.descriptive_flex_appl_id(+) = pn_prog_application_id
                     AND a.request_set_id(+) = pn_request_set_id
                     AND a.request_set_program_id(+) = pn_request_set_program_id
                     AND a.descriptive_flex_appl_id(+) = u.application_id
                     AND a.descriptive_flexfield_name(+) = u.descriptive_flexfield_name
                     AND a.application_column_name(+) = u.application_column_name
                     AND u.enabled_flag = 'Y'
                     AND p.concurrent_program_id = pn_program_id
                     AND u.descriptive_flexfield_name = ('$SRS$.'|| p.concurrent_program_name)
                     AND u.application_id = pn_prog_application_id
                     AND ffvs.flex_value_set_id = u.flex_value_set_id
            ORDER BY u.column_seq_num;

        --Selectionne les parametres dans la declaration du jeu
        CURSOR cur_prog_params
        IS
            SELECT   u.default_type,
                     u.default_value,
                     u.flex_value_set_id,
                     ffvs.validation_type
            FROM     fnd_descr_flex_column_usages u,
                     fnd_concurrent_programs p,
                     fnd_flex_value_sets ffvs
            WHERE        u.application_id = pn_prog_application_id
                     AND u.descriptive_flexfield_name = ('$SRS$.'|| p.concurrent_program_name)
                     AND u.enabled_flag = 'Y'
                     AND p.concurrent_program_id = pn_program_id
                     AND ffvs.flex_value_set_id = u.flex_value_set_id
            ORDER BY u.column_seq_num;

        vn_num_param       NUMBER;
        vv_param_value     fnd_request_set_program_args.default_value%TYPE;
        vv_default_value   fnd_request_set_program_args.default_value%TYPE;
        vv_default_type    fnd_request_set_program_args.default_type%TYPE;

        FUNCTION cas_particuliers ( pv_sql VARCHAR2 ) RETURN VARCHAR2
        IS
            vc_sql         fnd_request_set_program_args.default_value%TYPE;
        BEGIN
            vc_sql := REPLACE(pv_sql, ':$FLEX$.GL_SRS_SET_OF_BOOKS', 'fnd_profile.value(''GL_SET_OF_BKS_ID'')');
            vc_sql := REPLACE(vc_sql, ':$PROFILES$.GL_SET_OF_BKS_ID', 'fnd_profile.value(''GL_SET_OF_BKS_ID'')');
            vc_sql := REPLACE(vc_sql, ':$PROFILES$.gl_set_of_bks_id', 'fnd_profile.value(''GL_SET_OF_BKS_ID'')');
            vc_sql := REPLACE(vc_sql, ':$PROFILES$.ORG_ID', 'fnd_profile.value(''ORG_ID'')');
            vc_sql := REPLACE(vc_sql, ':$PROFILES$.org_id', 'fnd_profile.value(''ORG_ID'')');
            vc_sql := REPLACE(vc_sql, ':$PROFILES$.PER_BUSINESS_GROUP_ID', 'fnd_profile.value(''PER_BUSINESS_GROUP_ID'')');
            vc_sql := REPLACE(vc_sql, ':$PROFILES$.per_business_group_id', 'fnd_profile.value(''PER_BUSINESS_GROUP_ID'')');
            vc_sql := REPLACE(vc_sql, ':$PROFILES$.RESP_APPL_ID', 'fnd_profile.value(''RESP_APPL_ID'')');
            vc_sql := REPLACE(vc_sql, ':$PROFILES$.resp_appl_id', 'fnd_profile.value(''RESP_APPL_ID'')');
            vc_sql := REPLACE(vc_sql, ':$PROFILES$.RESP_ID', 'fnd_profile.value(''RESP_ID'')');
            vc_sql := REPLACE(vc_sql, ':$PROFILES$.resp_id', 'fnd_profile.value(''RESP_ID'')');
            vc_sql := REPLACE(vc_sql, ':$PROFILES$.USER_ID', 'fnd_profile.value(''USER_ID'')');
            vc_sql := REPLACE(vc_sql, ':$PROFILES$.user_id', 'fnd_profile.value(''USER_ID'')');
            vc_sql := REPLACE(vc_sql, ':$FLEX$.GL_SRS_COA_ID_BYSOB', '(SELECT chart_of_accounts_id FROM gl_sets_of_books WHERE set_of_books_id = fnd_profile.value(''GL_SET_OF_BKS_ID''))');
            vc_sql := REPLACE(vc_sql, ':$FLEX$.gl_srs_coa_id_bysob', '(SELECT chart_of_accounts_id FROM gl_sets_of_books WHERE set_of_books_id = fnd_profile.value(''GL_SET_OF_BKS_ID''))');
            vc_sql := REPLACE(vc_sql, ':$PROFILES$.AX_APPLICATION_ID', 'fnd_profile.value(''AX_APPLICATION_ID'')');
            vc_sql := REPLACE(vc_sql, ':$PROFILES$.GL_ACCESS_SET_ID', 'Fnd_Profile.VALUE(''GL_ACCESS_SET_ID'')');
            vc_sql := REPLACE(vc_sql, ':$FLEX$.GL_SRS_LEDGER_WITH_SETS_AND_ALCS_STORE_SHORT_NAME', '(select name from gl_ledgers where ledger_id = gl_access_set_security_pkg.get_default_ledger_id(Fnd_Profile.VALUE (''GL_ACCESS_SET_ID''), ''R''))');
            vc_sql := REPLACE(vc_sql, ':$FLEX$.GL_SRS_CURRENCY_TYPE','(select meaning from gl_lookups WHERE LOOKUP_TYPE = ''GL_CURRENCY_TYPE'' and lookup_code = ''T'')');

            RETURN vc_sql;
        END;

    BEGIN
        --init
        pn_retcode      := 0;
        pv_errbuf       := NULL;
        vn_num_param    := 1;

        FOR i IN 1 .. 100
        LOOP
            tab_request_params (i)    := CHR (0);
        END LOOP;

        --Cas d un jeu de traitement
        IF      pn_request_set_id IS NOT NULL
            AND pn_request_set_program_id IS NOT NULL
            AND pn_program_id IS NOT NULL
        THEN
            FOR rec_req_set_param IN cur_req_set_params
            LOOP
                vv_param_value                       := NULL;

                --Localisation de la valeur par defaut du parametre
                IF rec_req_set_param.default_value_set IS NOT NULL
                THEN
                    --Il y a une valeur par defaut sur le jeu
                    vv_default_type     := rec_req_set_param.default_type_set;
                    vv_default_value    := rec_req_set_param.default_value_set;
                ELSE
                    --Il faut rechercher la valeur par defaut du parametre dans la declaration du programme
                    vv_default_type     := rec_req_set_param.default_type_trt;
                    vv_default_value    := rec_req_set_param.default_value_trt;
                END IF;

                --Recuperation de la valeur du parametre
                IF vv_default_type = 'S' --Ordre SQL
                THEN
                    -- Prise en compte de certains cas spéciaux

                    vv_default_value := cas_particuliers (vv_default_value);

                    BEGIN

                      EXECUTE IMMEDIATE vv_default_value
                          INTO vv_param_value;

                    EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                      vv_param_value := NULL;
                     WHEN TOO_MANY_ROWS THEN
                      vv_param_value := NULL;
                    END;
                ELSIF vv_default_type = 'C' --Constante
                THEN
                    vv_param_value    := vv_default_value;
                ELSIF vv_default_type = 'P' --Profil
                THEN
                    vv_param_value    := Fnd_Profile.VALUE (vv_default_value);
                END IF;

                -- Calcul de l'id par le jeu de valeurs si besoin
                IF      rec_req_set_param.validation_type = 'F'
                    AND vv_param_value IS NOT NULL
                THEN
                    DECLARE
                        vv_id_column_name      fnd_flex_validation_tables.id_column_name%TYPE;
                        vv_value_column_name   fnd_flex_validation_tables.value_column_name%TYPE;
                        vv_sql                 VARCHAR2 (2000);
                        vv_param_value_id      VARCHAR2 (255);
                        vv_param_value_tmp     VARCHAR2 (255);
                        vv_mapping_code        VARCHAR2 (255);
                        vn_success             NUMBER;
                    BEGIN
                        SELECT ffvt.value_column_name
                        INTO   vv_value_column_name
                        FROM   fnd_flex_validation_tables ffvt
                        WHERE  ffvt.flex_value_set_id = rec_req_set_param.flex_value_set_id;

                        -- Utilisation de l'API standard pour déterminer la requete
                        Fnd_Flex_Val_Api.get_table_vset_select (
                            p_value_set_id                 => rec_req_set_param.flex_value_set_id,
                            p_inc_meaning_col              => 'N',
                            p_inc_user_where_clause        => 'Y',
                            p_user_where_clause            => vv_value_column_name || '=''' || vv_param_value || '''',
                            x_select                       => vv_sql,
                            x_mapping_code                 => vv_mapping_code,
                            x_success                      => vn_success
                        );

                        IF NVL (vn_success, 1) != 0
                        THEN
                            pn_retcode    := 2;
                            pv_errbuf     := 'Impossible de vérifier le jeu de valeurs';
                            RETURN;
                        END IF;

                        -- Prise en compte de certains cas spéciaux

                        vv_sql := cas_particuliers (vv_sql);

                        -- On vérifie si la requete générée contient encore des :$FLEX$ ou :$PROFILES$
                        -- dans ce cas on ne l'exécute pas
                        IF vv_sql LIKE '%:$FLEX$'
                        THEN
                            NULL;
                        ELSIF vv_sql LIKE '%:$PROFILES$'
                        THEN
                            NULL;
                        -- On vérifie si la requete générée retourne un ID (%ID1% => Oui, %ID0% => Non)
                        -- pour savoir combien de colonnes seront retournées
                        ELSIF vv_mapping_code LIKE '%ID1%'
                        THEN
                            EXECUTE IMMEDIATE vv_sql
                                INTO vv_param_value_tmp,
                                     vv_param_value_id;
                        ELSE
                            EXECUTE IMMEDIATE vv_sql
                                INTO vv_param_value_id;
                        END IF;

                        IF vv_param_value_id IS NOT NULL
                        THEN
                            vv_param_value    := vv_param_value_id;
                        END IF;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            NULL;
                    END;
                END IF;

                tab_request_params (vn_num_param)    := vv_param_value; --Affectation de la valeur du parametre
                vn_num_param                         := vn_num_param + 1; --parametre suivant
            END LOOP;

            RETURN;
        --Cas du traitement
        ELSIF pn_program_id IS NOT NULL
        THEN
            FOR rec_prog_param IN cur_prog_params
            LOOP
                vv_param_value                       := NULL;

                --Recuperation de la valeur du parametre
                IF rec_prog_param.default_type = 'S' --Ordre SQL
                THEN
                    -- Prise en compte de certains cas particuliers
                    rec_prog_param.default_value := cas_particuliers (rec_prog_param.default_value);
                    BEGIN
                      EXECUTE IMMEDIATE rec_prog_param.default_value
                          INTO vv_param_value;
                    EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                      vv_param_value := NULL;
                     WHEN TOO_MANY_ROWS THEN
                      vv_param_value := NULL;
                    END;
                ELSIF rec_prog_param.default_type = 'C' --Constante
                THEN
                    vv_param_value    := rec_prog_param.default_value;
                ELSIF rec_prog_param.default_type = 'P' --Profil
                THEN
                    vv_param_value    := Fnd_Profile.VALUE (rec_prog_param.default_value);
                END IF;

                -- Calcul de l'id par le jeu de valeurs si besoin
                IF      rec_prog_param.validation_type = 'F'
                    AND vv_param_value IS NOT NULL
                THEN
                    DECLARE
                        vv_id_column_name      fnd_flex_validation_tables.id_column_name%TYPE;
                        vv_value_column_name   fnd_flex_validation_tables.value_column_name%TYPE;
                        vv_sql                 VARCHAR2 (2000);
                        vv_param_value_id      VARCHAR2 (255);
                        vv_param_value_tmp     VARCHAR2 (255);
                        vv_mapping_code        VARCHAR2 (255);
                        vn_success             NUMBER;
                    BEGIN
                        SELECT ffvt.value_column_name
                        INTO   vv_value_column_name
                        FROM   fnd_flex_validation_tables ffvt
                        WHERE  ffvt.flex_value_set_id = rec_prog_param.flex_value_set_id;

                        -- Utilisation de l'API standard pour déterminer la requete
                        Fnd_Flex_Val_Api.get_table_vset_select (
                            p_value_set_id                 => rec_prog_param.flex_value_set_id,
                            p_inc_meaning_col              => 'N',
                            p_inc_user_where_clause        => 'Y',
                            p_user_where_clause            => vv_value_column_name || '=''' || vv_param_value || '''',
                            x_select                       => vv_sql,
                            x_mapping_code                 => vv_mapping_code,
                            x_success                      => vn_success
                        );

                        IF NVL (vn_success, 1) != 0
                        THEN
                            pn_retcode    := 2;
                            pv_errbuf     := 'Impossible de vérifier le jeu de valeurs';
                            RETURN;
                        END IF;

                        -- Prise en compte de certains cas particuliers
                        vv_sql := cas_particuliers (vv_sql);

                        -- On vérifie si la requete générée contient des :$FLEX$ ou $PROFILES$
                        -- dans ce cas on ne l'exécute pas
                        IF vv_sql LIKE '%:$FLEX$'
                        THEN
                            NULL;
                        ELSIF vv_sql LIKE '%:$PROFILES$'
                        THEN
                            NULL;
                        -- On vérifie si la requete générée retourne un ID (%ID1% => Oui, %ID0% => Non)
                        -- pour savoir combien de colonnes seront retournées
                        ELSIF vv_mapping_code LIKE '%ID1%'
                        THEN
                            EXECUTE IMMEDIATE vv_sql
                                INTO vv_param_value_tmp,
                                     vv_param_value_id;
                        ELSE
                            EXECUTE IMMEDIATE vv_sql
                                INTO vv_param_value_id;
                        END IF;

                        IF vv_param_value_id IS NOT NULL
                        THEN
                            vv_param_value    := vv_param_value_id;
                        END IF;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            NULL;
                    END;
                END IF;

                tab_request_params (vn_num_param)    := vv_param_value; --Affectation de la valeur du parametre
                vn_num_param                         := vn_num_param + 1; --parametre suivant
            END LOOP;

            RETURN;
        END IF;

        --Erreur
        pn_retcode      := 2;
        pv_errbuf       := 'Erreur de parametres';
    END get_request_set_params;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : LAUNCH_REQUEST_SET
--  Description   : Lancement d un jeu de traitement
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--      pv_program_code         IN      VARCHAR2    Code du Jeu de traitement a lancer
--  pv_user         IN  VARCHAR2    User qui lance le jeu
--  pv_resp         IN  VARCHAR2    Responsabilite
--      pn_request_id           OUT     NUMBER      ID du jeu lance
--  VALEUR RETOURNEE :
--     Description       : Id du traitement lancé
--     Valeurs possibles :
--
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE launch_request_set (
        pv_errbuf         OUT      VARCHAR2,
        pn_retcode        OUT      NUMBER,
        pv_application    IN       VARCHAR2,
        pv_program_code   IN       VARCHAR2,
        pv_user           IN       VARCHAR2,
        pv_resp           IN       VARCHAR2,
        pn_request_id     OUT      NUMBER
    )
    IS
        e_error                EXCEPTION;
        vn_responsibility_id   fnd_responsibility.responsibility_id%TYPE;
        vn_appl_resp_id        fnd_application.application_id%TYPE;
        vv_appl_resp_name      fnd_application.application_short_name%TYPE;
        vn_user_id             fnd_user.user_id%TYPE;
        vn_req_set_id          fnd_request_sets.request_set_id%TYPE;
        vb_save_output         BOOLEAN;

        CURSOR cur_programs (
            pn_req_set_id   NUMBER
        )
        IS
            SELECT v.*,
                   frss.stage_name
            FROM   fnd_req_set_run_form_v v,
                   fnd_request_set_stages frss
            WHERE      frss.request_set_id = v.request_set_id
                   AND frss.display_sequence = v.display_sequence
                   AND v.request_set_id = pn_req_set_id;
    BEGIN
        -- Positionnement de l'environnement

        SELECT fr.responsibility_id,
               fr.application_id  ,
               fa.application_short_name
        INTO   vn_responsibility_id,
               vn_appl_resp_id,
               vv_appl_resp_name
        FROM   fnd_responsibility fr ,
               fnd_application fa
        WHERE  fr.responsibility_key = pv_resp
        AND    fr.application_id = fa.application_id;

        SELECT user_id
        INTO   vn_user_id
        FROM   fnd_user
        WHERE  user_name = pv_user;

        SELECT frs.request_set_id
        INTO   vn_req_set_id
        FROM   fnd_request_sets frs
        WHERE  frs.request_set_name = pv_program_code;

        Fnd_Global.apps_initialize (vn_user_id, vn_responsibility_id, vn_appl_resp_id);
        --MO_GLOBAL.INIT (p_appl_short_name => vv_appl_resp_name) ;
        
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || fnd_profile.value ('ICX_LANGUAGE') || '''';
           
        -- Initialisation
        IF NOT Fnd_Submit.set_request_set (pv_application, pv_program_code)
        THEN
            Dka_Tools_Pkg.put_debug_message ('Impossible de "fnd_submit.set_request_set" le jeu de traitements '|| pv_program_code);
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de "fnd_submit.set_request_set" le jeu de traitements ' || pv_program_code;
            RAISE e_error;
        END IF;

        FOR rec_prog IN cur_programs (vn_req_set_id)
        LOOP
            --Recuperation des parametres
            get_request_set_params (
                pv_errbuf,
                pn_retcode,
                rec_prog.set_application_id,
                vn_req_set_id,
                rec_prog.request_set_program_id,
                rec_prog.program_application_id,
                rec_prog.concurrent_program_id
            );

            -- Parametres d'impression
            IF rec_prog.printer IS NOT NULL
            THEN
                IF rec_prog.save_output_flag = 'Y'
                THEN
                    vb_save_output    := TRUE;
                ELSE
                    vb_save_output    := FALSE;
                END IF;

                IF NOT Fnd_Submit.set_print_options (
                           printer                        => rec_prog.printer,
                           style                          => rec_prog.print_style,
                           copies                         => rec_prog.number_of_copies,
                           save_output                    => vb_save_output
                       )
                THEN
                    Dka_Tools_Pkg.put_debug_message (
                        'Impossible de "fnd_submit.set_print_options" le traitement '|| rec_prog.concurrent_program_name
                    );
                    Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
                    pn_retcode    := 2;
                    pv_errbuf     :=
                                   'Impossible de "fnd_submit.set_print_options" le traitement ' || rec_prog.concurrent_program_name;
                    RAISE e_error;
                END IF;
            END IF;

            -- Lancement programmes
            IF NOT Fnd_Submit.submit_program (
                       rec_prog.application_short_name, -- Application
                       rec_prog.concurrent_program_name, -- Program
                       rec_prog.stage_name, -- Stage
                       Dka_Tools_Pkg.tab_request_params (1), --ARGUMENT1
                       Dka_Tools_Pkg.tab_request_params (2), --ARGUMENT2
                       Dka_Tools_Pkg.tab_request_params (3), --ARGUMENT3
                       Dka_Tools_Pkg.tab_request_params (4), --ARGUMENT4
                       Dka_Tools_Pkg.tab_request_params (5), --ARGUMENT5
                       Dka_Tools_Pkg.tab_request_params (6), --ARGUMENT6
                       Dka_Tools_Pkg.tab_request_params (7), --ARGUMENT7
                       Dka_Tools_Pkg.tab_request_params (8), --ARGUMENT8
                       Dka_Tools_Pkg.tab_request_params (9), --ARGUMENT9
                       Dka_Tools_Pkg.tab_request_params (10), --ARGUMENT10
                       Dka_Tools_Pkg.tab_request_params (11), --ARGUMENT11
                       Dka_Tools_Pkg.tab_request_params (12), --ARGUMENT12
                       Dka_Tools_Pkg.tab_request_params (13), --ARGUMENT13
                       Dka_Tools_Pkg.tab_request_params (14), --ARGUMENT14
                       Dka_Tools_Pkg.tab_request_params (15), --ARGUMENT15
                       Dka_Tools_Pkg.tab_request_params (16), --ARGUMENT16
                       Dka_Tools_Pkg.tab_request_params (17), --ARGUMENT17
                       Dka_Tools_Pkg.tab_request_params (18), --ARGUMENT18
                       Dka_Tools_Pkg.tab_request_params (19), --ARGUMENT19
                       Dka_Tools_Pkg.tab_request_params (20), --ARGUMENT20
                       Dka_Tools_Pkg.tab_request_params (21), --ARGUMENT21
                       Dka_Tools_Pkg.tab_request_params (22), --ARGUMENT22
                       Dka_Tools_Pkg.tab_request_params (23), --ARGUMENT23
                       Dka_Tools_Pkg.tab_request_params (24), --ARGUMENT24
                       Dka_Tools_Pkg.tab_request_params (25), --ARGUMENT25
                       Dka_Tools_Pkg.tab_request_params (26), --ARGUMENT26
                       Dka_Tools_Pkg.tab_request_params (27), --ARGUMENT27
                       Dka_Tools_Pkg.tab_request_params (28), --ARGUMENT28
                       Dka_Tools_Pkg.tab_request_params (29), --ARGUMENT29
                       Dka_Tools_Pkg.tab_request_params (30), --ARGUMENT30
                       Dka_Tools_Pkg.tab_request_params (31), --ARGUMENT31
                       Dka_Tools_Pkg.tab_request_params (32), --ARGUMENT32
                       Dka_Tools_Pkg.tab_request_params (33), --ARGUMENT33
                       Dka_Tools_Pkg.tab_request_params (34), --ARGUMENT34
                       Dka_Tools_Pkg.tab_request_params (35), --ARGUMENT35
                       Dka_Tools_Pkg.tab_request_params (36), --ARGUMENT36
                       Dka_Tools_Pkg.tab_request_params (37), --ARGUMENT37
                       Dka_Tools_Pkg.tab_request_params (38), --ARGUMENT38
                       Dka_Tools_Pkg.tab_request_params (39), --ARGUMENT39
                       Dka_Tools_Pkg.tab_request_params (40), --ARGUMENT40
                       Dka_Tools_Pkg.tab_request_params (41), --ARGUMENT41
                       Dka_Tools_Pkg.tab_request_params (42), --ARGUMENT42
                       Dka_Tools_Pkg.tab_request_params (43), --ARGUMENT43
                       Dka_Tools_Pkg.tab_request_params (44), --ARGUMENT44
                       Dka_Tools_Pkg.tab_request_params (45), --ARGUMENT45
                       Dka_Tools_Pkg.tab_request_params (46), --ARGUMENT46
                       Dka_Tools_Pkg.tab_request_params (47), --ARGUMENT47
                       Dka_Tools_Pkg.tab_request_params (48), --ARGUMENT48
                       Dka_Tools_Pkg.tab_request_params (49), --ARGUMENT49
                       Dka_Tools_Pkg.tab_request_params (50), --ARGUMENT50
                       Dka_Tools_Pkg.tab_request_params (51), --ARGUMENT51
                       Dka_Tools_Pkg.tab_request_params (52), --ARGUMENT52
                       Dka_Tools_Pkg.tab_request_params (53), --ARGUMENT53
                       Dka_Tools_Pkg.tab_request_params (54), --ARGUMENT54
                       Dka_Tools_Pkg.tab_request_params (55), --ARGUMENT55
                       Dka_Tools_Pkg.tab_request_params (56), --ARGUMENT56
                       Dka_Tools_Pkg.tab_request_params (57), --ARGUMENT57
                       Dka_Tools_Pkg.tab_request_params (58), --ARGUMENT58
                       Dka_Tools_Pkg.tab_request_params (59), --ARGUMENT59
                       Dka_Tools_Pkg.tab_request_params (60), --ARGUMENT60
                       Dka_Tools_Pkg.tab_request_params (61), --ARGUMENT61
                       Dka_Tools_Pkg.tab_request_params (62), --ARGUMENT62
                       Dka_Tools_Pkg.tab_request_params (63), --ARGUMENT63
                       Dka_Tools_Pkg.tab_request_params (64), --ARGUMENT64
                       Dka_Tools_Pkg.tab_request_params (65), --ARGUMENT65
                       Dka_Tools_Pkg.tab_request_params (66), --ARGUMENT66
                       Dka_Tools_Pkg.tab_request_params (67), --ARGUMENT67
                       Dka_Tools_Pkg.tab_request_params (68), --ARGUMENT68
                       Dka_Tools_Pkg.tab_request_params (69), --ARGUMENT69
                       Dka_Tools_Pkg.tab_request_params (70), --ARGUMENT70
                       Dka_Tools_Pkg.tab_request_params (71), --ARGUMENT71
                       Dka_Tools_Pkg.tab_request_params (72), --ARGUMENT72
                       Dka_Tools_Pkg.tab_request_params (73), --ARGUMENT73
                       Dka_Tools_Pkg.tab_request_params (74), --ARGUMENT74
                       Dka_Tools_Pkg.tab_request_params (75), --ARGUMENT75
                       Dka_Tools_Pkg.tab_request_params (76), --ARGUMENT76
                       Dka_Tools_Pkg.tab_request_params (77), --ARGUMENT77
                       Dka_Tools_Pkg.tab_request_params (78), --ARGUMENT78
                       Dka_Tools_Pkg.tab_request_params (79), --ARGUMENT79
                       Dka_Tools_Pkg.tab_request_params (80), --ARGUMENT80
                       Dka_Tools_Pkg.tab_request_params (81), --ARGUMENT81
                       Dka_Tools_Pkg.tab_request_params (82), --ARGUMENT82
                       Dka_Tools_Pkg.tab_request_params (83), --ARGUMENT83
                       Dka_Tools_Pkg.tab_request_params (84), --ARGUMENT84
                       Dka_Tools_Pkg.tab_request_params (85), --ARGUMENT85
                       Dka_Tools_Pkg.tab_request_params (86), --ARGUMENT86
                       Dka_Tools_Pkg.tab_request_params (87), --ARGUMENT87
                       Dka_Tools_Pkg.tab_request_params (88), --ARGUMENT88
                       Dka_Tools_Pkg.tab_request_params (89), --ARGUMENT89
                       Dka_Tools_Pkg.tab_request_params (90), --ARGUMENT90
                       Dka_Tools_Pkg.tab_request_params (91), --ARGUMENT91
                       Dka_Tools_Pkg.tab_request_params (92), --ARGUMENT92
                       Dka_Tools_Pkg.tab_request_params (93), --ARGUMENT93
                       Dka_Tools_Pkg.tab_request_params (94), --ARGUMENT94
                       Dka_Tools_Pkg.tab_request_params (95), --ARGUMENT95
                       Dka_Tools_Pkg.tab_request_params (96), --ARGUMENT96
                       Dka_Tools_Pkg.tab_request_params (97), --ARGUMENT97
                       Dka_Tools_Pkg.tab_request_params (98), --ARGUMENT98
                       Dka_Tools_Pkg.tab_request_params (99), --ARGUMENT99
                       Dka_Tools_Pkg.tab_request_params (100) --ARGUMENT100
                   )
            THEN
                Dka_Tools_Pkg.put_debug_message (
                    'Impossible de "fnd_submit.submit_program" le traitement '|| rec_prog.concurrent_program_name
                );
                Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
                pn_retcode    := 2;
                pv_errbuf     := 'Impossible de "fnd_submit.submit_program" le traitement ' || rec_prog.concurrent_program_name;
                RAISE e_error;
            END IF;
        END LOOP;

        -- Lancement du jeu
        pn_request_id    := Fnd_Submit.submit_set ();
        -- Validation pour que les GTS puissent prendre la demande
        COMMIT;

        IF pn_request_id = 0
        THEN
            Dka_Tools_Pkg.put_debug_message ('Impossible de lancer "submit_set" pour le jeu de traitement '|| pv_program_code);
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de lancer "submit_set" pour le jeu de traitement ' || pv_program_code;
            RAISE e_error;
        END IF;
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf    := 'launch_request_set :' || pv_errbuf;
        WHEN OTHERS
        THEN
            pv_errbuf     := 'launch_request_set :' || SQLERRM;
            pn_retcode    := 2;
    END launch_request_set;


----------------------------------------------------------------------------------------
  --  Nom           : get_code_societe
  --  Description   : Procédure qui donne le code societe a partir de l'org_id
  --
  --
  --  PARAMETRES :
  --            pn_org_id           Entrée
  --            pv_soc                  Sortie
  --            pv_errbuf           Entrée  Sortie
  --                pn_retcode              Sortie
  --
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_code_societe (
        pn_org_id    IN       NUMBER,
        pv_soc       OUT      VARCHAR2,
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
    BEGIN
        ---initialisation des variables------

        pv_errbuf     := NULL;
        pn_retcode    := 0;

        SELECT LTRIM (RTRIM (haou.NAME))
        INTO   pv_soc
        FROM   hr_all_organization_units haou
        WHERE      haou.organization_id = pn_org_id
        ;
        -- PHENIX 2004: Suppression de       AND haou.TYPE = 'SOCIETE';
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            pv_errbuf     := 'get_code_societe: ' || TO_CHAR (pn_org_id) || 'Non trouvé';
            pn_retcode    := 2;
            pv_soc        := NULL;
        WHEN OTHERS
        THEN
            pv_errbuf     := 'Erreur get_code_societe: WHEN_OTHERS :  ' || SQLERRM;
            pn_retcode    := 2;
    END get_code_societe;


  ---------------------------------------------------------------------------------------
  --  Nom           : get_org_id
  --  Description   : Procédure permettant d'obtenir l'id l'organisation a partir du code societe
  --
  --  PARAMETRES :
  --            pv_soc          Entrée
  --            pn_org_id                  Sortie
  --            pv_errbuf           Entrée  Sortie
  --                pn_retcode              Sortie
  --
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_org_id (
        pv_soc       IN       VARCHAR2,
        pn_org_id    OUT      NUMBER,
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
    BEGIN
        ---initialisation des variables------

        pv_errbuf     := NULL;
        pn_retcode    := 0;

        SELECT haou.organization_id
        INTO   pn_org_id
        FROM   hr_all_organization_units haou
        WHERE  haou.NAME = pv_soc;
    --AND haou.type='SOCIETE';

    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            pv_errbuf     := 'get_org_id : Société ' || pv_soc || 'Non trouvé';
            pn_retcode    := 2;
            pn_org_id     := 0;
        WHEN OTHERS
        THEN
            pv_errbuf     := 'Erreur get_org_id: WHEN_OTHERS  ' || SQLERRM;
            pn_retcode    := 2;
    END get_org_id;

    ---------------------------------------------------------------------------------------------------------------
      --  Nom           : trt_car_spec
      --  Description   :  fonction qui permet de traiter les caracteres spéciaux      --
      --
      --  PARAMETRES    :
      --                     pv_chaine
      --
      --  VALEUR RETOURNEE :
      --                     chaine convertie
      ---------------------------------------------------------------------------------------------------------------
      FUNCTION trt_car_spec (pv_chaine IN VARCHAR2)
      RETURN VARCHAR2
      IS
        -- Chaine des caracteres corrects : lettres de l'alphabet en majuscules + chiffres
        vv_chaine_car_corrects VARCHAR2(200) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';

        -- Chaine des caracteres autorisés a remplacer: un caractere se trouvant dans la chaine vv_chaine_car_src
        -- est remplacé par son caractere équivalent se trouvant a la meme position dans la chaine vv_chaine_car_dst
        vv_chaine_car_src VARCHAR2(200) := 'abcdefghijklmnopqrstuvwxyzaâäáaaçéeeëîiiíôö?óouuüúýyAÁÂAÄAAÇEÉEËIÍÎIDOÓÔOÖOUÚUÜÝ';
        vv_chaine_car_dst VARCHAR2(200) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZAAAAAACEEEEIIIIOOOOOUUUUYYAAAAAAECEEEEIIIIDOOOOOOUUUUY';

        -- variables locales
        vv_chaine_conv           VARCHAR2(2000);
        vv_chaine_car_incorrects VARCHAR2(500);
        i                        NUMBER;

      BEGIN
           -- On commence par remplacer les caracteres autorisés
           SELECT TRANSLATE(pv_chaine,
                            vv_chaine_car_corrects || vv_chaine_car_src,
                            vv_chaine_car_corrects || vv_chaine_car_dst
                )
           INTO vv_chaine_conv
           FROM dual;

           -- On constitue la liste des caracteres non autorisés (tout caractere ne se trouvant pas dans
           -- vv_chaine_car_corrects ou dans vv_chaine_car_src) par un tiret
           SELECT TRANSLATE(pv_chaine,
                            'x' || vv_chaine_car_corrects || vv_chaine_car_src,
                            'x'
                           )
           INTO vv_chaine_car_incorrects
           FROM dual;

           -- On substitue le cas échéant les caracteres se trouvant dans vv_chaine_car_incorrects par un tiret
           -- dans la chaine convertie
           IF vv_chaine_car_incorrects IS NOT NULL
           THEN
               FOR i IN 1 .. length(vv_chaine_car_incorrects)
               LOOP
                   SELECT REPLACE(vv_chaine_conv,
                                  substr(vv_chaine_car_incorrects, i, 1),
                                  ' '
                                 )
                   INTO vv_chaine_conv
                   FROM dual;
               END LOOP;
           END IF;

           RETURN vv_chaine_conv;

      EXCEPTION
            WHEN OTHERS THEN RETURN pv_chaine;

      END trt_car_spec;

      ---------------------------------------------------------------------------------------------------------------
      --  Nom           : is_bank_holiday
      --  Description   :  fonction qui vérifie si la date passée en parametre est fériée
      --
      --  PARAMETRES    :
      --                     pd_date
      --
      --  VALEUR RETOURNEE :
      --     Valeurs possibles :      0 non, 1 oui
      ---------------------------------------------------------------------------------------------------------------
      FUNCTION is_bank_holiday(pd_date IN DATE)
      RETURN NUMBER
      IS
        -- Déclaration des jours fériés fixes
        cv_new_year       CONSTANT VARCHAR2(4) := '0101';
        cv_labour_day     CONSTANT VARCHAR2(4) := '0105';
        cv_1945_truce     CONSTANT VARCHAR2(4) := '0805';
        cv_national_day   CONSTANT VARCHAR2(4) := '1407';
        cv_assumption     CONSTANT VARCHAR2(4) := '1508';
        cv_all_saints_day CONSTANT VARCHAR2(4) := '0111';
        cv_1918_truce     CONSTANT VARCHAR2(4) := '1111';
        cv_christmas_day  CONSTANT VARCHAR2(4) := '2512';

        -- Variable qui contient le résultat
        vn_result         NUMBER := 0;

        -- Variable pour calcul de la date de Pâques
        four_digit_year    NUMBER;
        easter_month       NUMBER;
        easter_date        NUMBER;
        century            NUMBER;
        golden_year        NUMBER;
        epact              NUMBER;
        days_to_full_moon  NUMBER;
        wkday_full_moon    NUMBER;
        days_full_moon     NUMBER;
        easter_sunday      DATE;

      BEGIN

      IF to_char(pd_date, 'DDMM') IN (cv_new_year, cv_labour_day, cv_1945_truce, cv_national_day, cv_assumption, cv_all_saints_day, cv_1918_truce, cv_christmas_day)
      THEN
          vn_result := 1;
      ELSE -- On recherche si Pâques ou Ascension
          -- Calcul de la date de Pâques
          four_digit_year := to_number(to_char(pd_date, 'YYYY'));
          century := trunc(four_digit_year/100);
          golden_year := MOD(four_digit_year,19);
          epact := MOD(TRUNC((century-TRUNC(century/4)-TRUNC((8*century+13)/25)+(19*golden_year)+15)),30);
          days_full_moon := epact-TRUNC(epact/28)*(1-TRUNC(epact/28)*TRUNC(29/(epact+1))*TRUNC((21-golden_year)/11));
          wkday_full_moon := MOD((four_digit_year+TRUNC(four_digit_year/4)+days_full_moon+2-TRUNC(four_digit_year/100)+TRUNC(TRUNC(four_digit_year/100)/4)),7);
          days_to_full_moon := days_full_moon - wkday_full_moon;
          easter_month := 3+TRUNC((days_to_full_moon+40)/44);
          easter_date := days_to_full_moon+28-31*TRUNC(easter_month/4);
          easter_sunday := to_date(to_char(easter_date,'00')||to_char(easter_month,'00')||to_char(four_digit_year,'0000'),'DD-MM-YYYY');

          -- Lundi de Pâques, Jeudi de l'Ascension et Lundi de Pentecôte
          IF trunc(pd_date) = (easter_sunday + 1)
             OR trunc(pd_date) = (easter_sunday + 39)
             OR trunc(pd_date) = (easter_sunday + 50)
          THEN
              vn_result := 1;
          END IF;
      END IF;

      RETURN vn_result;

      EXCEPTION
               WHEN OTHERS THEN RETURN NULL;

      END is_bank_holiday;

      ---------------------------------------------------------------------------------------------------------------
      --  Nom           : get_next_working_day
      --  Description   :  fonction qui retourne le jour ouvré le plus proche de la date passée en parametre
      --
      --  PARAMETRES    :
      --                     pd_date
      --
      --  VALEUR RETOURNEE :
      --     Valeurs possibles :      date elle-meme ou le prochain jour ouvré
      ---------------------------------------------------------------------------------------------------------------
      PROCEDURE get_next_working_day(pd_date IN OUT DATE)
      IS
        vd_date  DATE;
      BEGIN
           vd_date := pd_date;
           -- On recherche si la date est un jour férié ou un jour de week-end
           IF IS_BANK_HOLIDAY(vd_date)= 1 OR TRIM(TO_CHAR(vd_date, 'DAY')) IN ('SAMEDI', 'DIMANCHE')
           THEN
               -- Si oui, on appelle la fonction de maniere récursive en augmentant d'un jour,
               -- ce qui permet automatiquement de trouver le prochaine jour ouvert
               --
               vd_date:=vd_date+1;
               GET_NEXT_WORKING_DAY(vd_date);
           END IF;

           pd_date := vd_date;
      EXCEPTION
          WHEN OTHERS THEN NULL;
      END get_next_working_day;


     ----------------------------------------------------------------------------
     --  Nom           : add_error_stack
     --  Description   : Procédure
     --
     --  PARAMETRES :
     ----------------------------------------------------------------------------
     PROCEDURE add_error_stack(pv_error_message IN VARCHAR2)
     IS
     BEGIN
       IF gv_error_stack IS NULL THEN
         gv_error_stack := pv_error_message;
       ELSE
         gv_error_stack := pv_error_message || gv_new_line || gv_error_stack;
       END IF;

       EXCEPTION
         WHEN OTHERS
             THEN gv_error_stack := NULL;
     END;

     ----------------------------------------------------------------------------
     --  Nom           : print_error_stack
     --  Description   : Procédure
     --
     --  PARAMETRES :
     ----------------------------------------------------------------------------
     PROCEDURE print_error_stack
     IS
     BEGIN
       IF gv_error_stack IS NOT NULL THEN
         add_error_stack(gv_new_line || 'Trace :');
         put_outdebug_message(gv_error_stack);
       END IF;
     END;
     
     ----------------------------------------------------------------------------
     --  Nom           : clear_error_stack
     --  Description   : Procédure
     --
     --  PARAMETRES :
     ----------------------------------------------------------------------------
     PROCEDURE clear_error_stack
     IS
     BEGIN
       gv_error_stack := null;
     END;

     -- -----------------------------------------------------------------------------
     -- Nom              : Create_Table_Online_Patching
     -- Description      : fonction permettant la création de la editioning view (EV)
     --                    + Ajout d'un enregistrement NULL
     --
     -- PARAMETRES       : pv_owner           Proprietaire de la table
     --                    pv_table_name      Nom de la table
     --                    Pv_Errbuf          Sortie Message d'erreur
     --                    Pn_Retcode         Sortie Code Retour de la procédure
     --                                              '0' : Normal
     --                                              '1' : Avertissement
     --                                              '2' : Erreur
     --
     --
     -- VALEUR RETOURNEE :
     --     Description       :
     --     Valeurs possibles :
     -- -----------------------------------------------------------------------------
      PROCEDURE Create_Table_Online_Patching(pv_owner      IN VARCHAR2,
                                             pv_table_name IN VARCHAR2,
                                             pn_retcode    OUT NUMBER,
                                             pv_Errbuf     OUT VARCHAR2) IS

        CURSOR myCur_columns IS
          SELECT owner, table_name, column_name, data_type, data_length, nullable
            FROM all_tab_columns
           WHERE table_name = pv_table_name
             AND OWNER = pv_owner;

        Vv_chaine      VARCHAR2(2000);
        Vv_cmpt        NUMBER := 1;
        Vv_check_param NUMBER;
        e_err_create_ev EXCEPTION;
        e_err_insert_null EXCEPTION;
        e_err_check_param EXCEPTION;

      BEGIN

        -- Verifie les parametres
        SELECT COUNT(1)
          INTO Vv_check_param
          FROM all_tables
         WHERE table_name = pv_table_name
           AND owner = pv_owner;

        IF Vv_check_param = 0 THEN

          RAISE e_err_check_param;

        END IF;

        -- Creation de la vue "editioning view" (EV)
        BEGIN
          ad_zd_table.upgrade(pv_owner, pv_table_name);
          NULL;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE e_err_create_ev;
        END;

        -- Permet d'inserer une ligne quelconque dans la table si la table est vide
        DECLARE
        Vv_cpt NUMBER;

        BEGIN

          EXECUTE IMMEDIATE 'SELECT COUNT(1) FROM ' || pv_owner || '.' || pv_table_name INTO Vv_cpt;

          IF Vv_cpt = 0 THEN

            FOR myRrec_columns IN myCur_columns LOOP

              IF Vv_cmpt > 1 THEN
                Vv_chaine := Vv_chaine || ',';
              END IF;

              IF NVL(myRrec_columns.nullable, 'N') = 'Y' THEN

                Vv_chaine := Vv_chaine || 'NULL';

              ELSE

                IF    myRrec_columns.data_type = 'NUMBER' THEN
                  Vv_chaine := Vv_chaine || '''0''';
                ELSIF myRrec_columns.data_type = 'DATE' THEN
                  Vv_chaine := Vv_chaine || 'SYSDATE';
                ELSE
                  Vv_chaine := Vv_chaine || '''A''';
                END IF;

              END IF;

              Vv_cmpt := Vv_cmpt + 1;

            END LOOP;

            EXECUTE IMMEDIATE 'INSERT INTO '||pv_owner||'.'||pv_table_name||' VALUES ('||Vv_chaine||')';

            COMMIT;

          END IF;

        EXCEPTION
          WHEN OTHERS THEN
            pv_Errbuf := SQLERRM;
            RAISE e_err_insert_null;
        END;

        pn_retcode := 0;
        pv_Errbuf  := 'OK';

      EXCEPTION
        WHEN e_err_check_param THEN
          pn_retcode := 2;
          pv_Errbuf  := 'Erreur lors de la verification de la table en base (Create_Table_Online_Patching)';
          Dka_Tools_Pkg.Put_Debug_Message(pv_Errbuf);
        WHEN e_err_create_ev THEN
          pn_retcode := 2;
          pv_Errbuf  := 'Erreur lors de la creation de l''EV (Create_Table_Online_Patching)';
          Dka_Tools_Pkg.Put_Debug_Message(pv_Errbuf);
        WHEN e_err_insert_null THEN
          pn_retcode := 2;
          pv_Errbuf  := 'Erreur lors de l''insertion d''une ligne vide (Create_Table_Online_Patching) - '||pv_Errbuf;
          Dka_Tools_Pkg.Put_Debug_Message(pv_Errbuf);
        WHEN OTHERS THEN
          pn_retcode := 2;
          pv_Errbuf  := 'Erreur dans la procedure Create_Table_Online_Patching : ' ||
                        chr(10) || Substr(SQLERRM, 1, 80);
          Dka_Tools_Pkg.Put_Debug_Message(pv_Errbuf);
      END Create_Table_Online_Patching;


     -- -----------------------------------------------------------------------------
     -- Nom              : check_directory
     -- Description      : Vérifie de l'existence d'un directory et provoque une exception s'il n'existe pas
     -- -----------------------------------------------------------------------------
      procedure check_directory(p_directory_name in ALL_DIRECTORIES.directory_name%type)
      is
        CURSOR cur_directory (p_directory_name IN ALL_DIRECTORIES.directory_name%type) IS
        SELECT owner, directory_name, directory_path
          FROM all_directories
         WHERE directory_name = p_directory_name;
         l_dir cur_directory%ROWTYPE;
      begin
        open cur_directory(p_directory_name);
        fetch cur_directory into l_dir;
        if cur_directory%notfound then
          close cur_directory;
          put_log_message('Le directory ' || p_directory_name || ' n''existe pas.');
          raise program_error;
        end if;
        close cur_directory;
        put_log_message('Directory OK :  ' || p_directory_name || ' -> ' || l_dir.directory_path);
      end check_directory;

     -- -----------------------------------------------------------------------------
     -- Nom              : check_transco
     -- Description      : Vérifie de l'existence d'un jeu de transco et provoque une exception s'il n'existe pas
     -- -----------------------------------------------------------------------------
      procedure check_transco(p_set_name in dka_stransco_headers.set_name%type) is
        CURSOR cur_transco(p_set_name in varchar2) is
        SELECT dsh.set_id, dsh.set_name, dsh.inactive_date,
               sum(case when sysdate between trunc(nvl(dsl.start_date, sysdate)) and trunc(nvl(dsl.end_date, SYSDATE+1)) then 1 else 0 end) as active_lines,
               count(dsl.set_id) as lines
        FROM dka_stransco_headers dsh
        LEFT OUTER JOIN dka_stransco_lines   dsl on (dsh.set_id = dsl.set_id)
        WHERE dsh.set_name = p_set_name
        GROUP BY dsh.set_id, dsh.set_name, dsh.inactive_date;
        l_transco cur_transco%rowtype;
        l_ok boolean := false;
      begin
        open cur_transco(p_set_name);
        fetch cur_transco into l_transco;
        if cur_transco%notfound then
          put_log_message('Le jeu de transco ' || p_set_name || ' n''existe pas.');
        elsif l_transco.inactive_date >= trunc(sysdate) then
          put_log_message('Le jeu de transco ' || p_set_name || ' est désactivé.');
        elsif l_transco.lines = 0 then
          put_log_message('Aucune ligne n''est configurée dans le jeu de transco ' || p_set_name || '.');
        elsif l_transco.active_lines = 0 then
          put_log_message('Aucune ligne n''est active dans le jeu de transco ' || p_set_name || '.');
        else
          put_log_message('Jeu de transco OK : ' || p_set_name);
          l_ok := true;
        end if;
        close cur_transco;
        if not l_ok then
          raise program_error;
        end if;
      end check_transco;

     -- -----------------------------------------------------------------------------
     -- Nom              : check_value_set
     -- Description      : Vérifie de l'existence d'un jeu de valeurs et provoque une exception s'il n'existe pas
     -- -----------------------------------------------------------------------------
     procedure check_value_set(p_value_set_name in fnd_flex_value_sets.flex_value_set_name%type) is
        cursor cur_value_set(p_value_set_name in varchar2) is
        select ffvs.FLEX_VALUE_SET_ID,
               sum(case when ffv.ENABLED_FLAG='Y' and sysdate between trunc(nvl(ffv.START_DATE_ACTIVE, sysdate)) and trunc(nvl(ffv.END_DATE_ACTIVE, SYSDATE+1)) then 1 else 0 end) as active_lines,
               count(ffv.flex_value_id) as lines
        from fnd_flex_value_sets        ffvs
        left outer join fnd_flex_values ffv  on (ffvs.flex_value_set_id =  ffv.flex_value_set_id)
        where ffvs.flex_value_set_name = p_value_set_name
        group by ffvs.FLEX_VALUE_SET_ID;
        l_value_set cur_value_set%rowtype;
        l_ok boolean := false;
      begin
        open cur_value_set(p_value_set_name);
        fetch cur_value_set into l_value_set;
        if cur_value_set%notfound then
          put_log_message('Le jeu de valeurs ' || p_value_set_name || ' n''existe pas.');
        elsif l_value_set.lines = 0 then
          put_log_message('Aucune ligne n''est configurée dans le jeu de valeurs ' || p_value_set_name || '.');
        elsif l_value_set.active_lines = 0 then
          put_log_message('Aucune valeur n''est active dans le jeu de valeurs ' || p_value_set_name || '.');
        else
          put_log_message('Jeu de valeurs OK : ' || p_value_set_name);
          l_ok := true;
        end if;
        close cur_value_set;
        if not l_ok then
          raise program_error;
        end if;
      end check_value_set;

     -- -----------------------------------------------------------------------------
     -- Nom              : check_parameter
     -- Description      : Vérifie de l'existence d'un parametre DKA et provoque une exception s'il n'existe pas
     -- -----------------------------------------------------------------------------
      procedure check_parameter(p_program_code in DKA_PARAMETERS.PROGRAM_CODE%type, p_parameter_name in DKA_PARAMETERS.PARAMETER_NAME%type) is
        l_exists number;
      begin
        select 1 into l_exists from DKA_PARAMETERS where PROGRAM_CODE=p_program_code and PARAMETER_NAME=p_parameter_name;
        put_log_message('Parametre OK : ' || p_program_code || '/' || p_parameter_name);
      exception
        when no_data_found then
          put_log_message('Parametre inexistant : ' || p_program_code || '/' || p_parameter_name);
          raise program_error;
      end check_parameter;

     -- -----------------------------------------------------------------------------
     -- Nom              : check_message
     -- Description      : Vérifie de l'existence d'un message et provoque une exception s'il n'existe pas
     -- -----------------------------------------------------------------------------
      procedure check_message(p_application_short_name in FND_APPLICATION.APPLICATION_SHORT_NAME%type, p_message_name in FND_NEW_MESSAGES.MESSAGE_NAME%type) is
        l_exists number;
      begin
        select 1 into l_exists
        from FND_NEW_MESSAGES
        join FND_APPLICATION using (application_id)
        where APPLICATION_SHORT_NAME=p_application_short_name
          and MESSAGE_NAME=p_message_name
          and rownum=1;
        put_log_message('Message OK : ' || p_application_short_name || '/' || p_message_name);
      exception
        when no_data_found then
          put_log_message('Message inexistant : ' || p_application_short_name || '/' || p_message_name);
          raise program_error;
      end check_message;

     -- -----------------------------------------------------------------------------
     -- Nom              : check_parameter
     -- Description      : Vérifie de l'existence d'un segment de CUF et provoque une exception s'il n'existe pas
     --                  : Le segment peut etre désigné par son nom utilisateur, par la colonne (ATTRIBUTEn) qu'il occupe, ou les 2
     -- -----------------------------------------------------------------------------
      procedure check_flex_segment(
        p_appl_short_name in FND_APPLICATION.APPLICATION_SHORT_NAME%type,
        p_flexfield_name  in fnd_descriptive_flexs.descriptive_flexfield_name%type,
        p_context_code    in fnd_descr_flex_column_usages.descriptive_flex_context_code%type,
        p_segment_name    in fnd_descr_flex_column_usages.end_user_column_name%type,
        p_column_name     in fnd_descr_flex_column_usages.application_column_name%type)
      is
        cursor cur_flex_segment is
        SELECT fdf.descriptive_flexfield_name,
               col.descriptive_flex_context_code,
               col.application_column_name,
               col.end_user_column_name,   /* segment_name */
               col.enabled_flag
        FROM   fnd_application                       fa
        join   fnd_descriptive_flexs                 fdf on (fdf.application_id = fa.application_id)
        join fnd_descr_flex_column_usages            col on (col.descriptive_flexfield_name = fdf.descriptive_flexfield_name and col.application_id = fdf.application_id)
        where fa.application_short_name         = p_appl_short_name
          AND fdf.descriptive_flexfield_name    = p_flexfield_name
          AND col.descriptive_flex_context_code = p_context_code
          AND (col.end_user_column_name         = p_segment_name or p_segment_name is null)
          and (col.application_column_name      = p_column_name or p_column_name is null)
          and (p_column_name is not null or p_segment_name is not null);
        l_flex_segment cur_flex_segment%rowtype;
        l_ok boolean := false;
      begin
        open cur_flex_segment;
        fetch cur_flex_segment into l_flex_segment;
        if cur_flex_segment%notfound then
          put_log_message('Segment de CUF inexistant : ' || p_appl_short_name || '/' || p_flexfield_name || '/' || p_context_code || '/' || nvl(p_segment_name,p_column_name));
        elsif l_flex_segment.enabled_flag != 'Y' then
          put_log_message('Segment de CUF désactivé : ' || p_appl_short_name || '/' || p_flexfield_name || '/' || p_context_code || '/' || nvl(p_segment_name,p_column_name));
        else
          put_log_message('Segment de CUF OK : ' || p_appl_short_name || '/' || p_flexfield_name || '/' || p_context_code || '/' || nvl(p_segment_name,p_column_name));
          l_ok := true;
        end if;
        close cur_flex_segment;
        if not l_ok then
          raise program_error;
        end if;
      end check_flex_segment;

-----------------------------------------------------------------
-- Debut du corps de package                                   --
-----------------------------------------------------------------
BEGIN
    gv_debug_mode    := Fnd_Profile.VALUE ('DKA_DEBUG_MODE');
END Dka_Tools_Pkg; -- package body
/
SHOW ERRORS
EXIT;
