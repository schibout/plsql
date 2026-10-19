SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE BODY DKA_REPGLPIECEREPIMP_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME
--    DKA_REPGLPIECEREPIMP_PKG.pkb  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION
--    Création du package de l'interface specifique d'import des pièces répétitives
--
-- USAGE
--    A exécuter sous SqlPlus avec user APPS sans paramètre
--
-- NOTES
--
-- PARAMETERS
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Date           Qui Description
-- -------------- --- ---------------------------------------------------------------
-- 27/10/2017     RBE Creation
-- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
---------------------------------------------------------------------------------------------

 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    TYPE summary_typ IS RECORD 
    (
     loaded_rows                      NUMBER      -- Nb des lignes chargées en table specifique
    ,loaded_imput_rows                NUMBER      -- Nb des imputations chargées en table specifique
    ,rejected_rows                    NUMBER      -- Nb de Lignes rejectées
    ,no_imported_rows                 NUMBER      -- Nb de Lignes non importées
    ,inserted_batches_rows            NUMBER      -- Nb de Lignes batches insérées
    ,inserted_headers_rows            NUMBER      -- Nb de Lignes headers insérés
    ,inserted_lines_rows              NUMBER      -- Nb de Lignes lines insérées
    ,inserted_rules_rows              NUMBER      -- Nb de Lignes rules insérées
    ,purged_rows                      NUMBER      -- Nb de Lignes purgées en table spécifique   
    ,message_flag                     NUMBER      -- Flag d'entete etat des erreurs
    ,load_file                        VARCHAR2(1) -- parametre charger fichier
    ,insert_oa                        VARCHAR2(1) -- parametre insérer dans OA
    )
    ;

    g_summary                      summary_typ;

    g_user_id                      fnd_user.user_id%TYPE;
    g_login_id                     fnd_logins.login_id%TYPE;
    g_request_id                   fnd_concurrent_requests.request_id%TYPE;
    g_loader_request_id            fnd_concurrent_requests.request_id%TYPE;
    gv_printer                     fnd_concurrent_requests.printer%TYPE;
    g_number_of_copies             fnd_concurrent_requests.number_of_copies%TYPE;
    g_tempo                        NUMBER;


 /*
 *************************************************************************
 * PROCEDURE NAME : init
 * 
 * DESCRIPTION
 *  Procédure d'initialisation des variables globales
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
.* ----------------- ------------------------------------------------------
 * p_errbuf         Retour de message éventuel
 * p_retcode        Statut du traitement en sortie
 ************************************************************************
 */

  PROCEDURE init (
        p_errbuf        OUT      VARCHAR2,
        p_retcode       OUT      NUMBER,
        p_load_file     IN       VARCHAR2,
        p_insert_oa     IN       VARCHAR2
        )
  IS

    v_current_program_unit    VARCHAR2(30);
    v_step_program_error      VARCHAR2(1000);
    program_error             EXCEPTION;

  BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début init');

        ----------------------------------
        -- Initialisation des variables --
        ----------------------------------
        p_errbuf  := NULL;
        p_retcode := 0;
        v_current_program_unit := 'INIT';

        ------------------------
        -- Variables globales --
        ------------------------ 

        g_user_id                      := fnd_global.user_id;
        g_login_id                     := fnd_global.login_id;
        g_request_id                   := fnd_global.conc_request_id;
        g_tempo                        := 20;

        -- Variables globales de comptage

        g_summary.loaded_rows                      := 0;
        g_summary.loaded_imput_rows                := 0;
        g_summary.rejected_rows                    := 0;
        g_summary.no_imported_rows                 := 0;
        g_summary.inserted_batches_rows            := 0;
        g_summary.inserted_headers_rows            := 0;
        g_summary.inserted_lines_rows              := 0;
        g_summary.inserted_rules_rows              := 0;
        g_summary.purged_rows                      := 0;
        g_summary.message_flag                     := 0;
        g_summary.load_file                        := p_load_file;
        g_summary.insert_oa                        := p_insert_oa;

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin init');
        
        BEGIN
           SELECT printer
                 ,number_of_copies
           INTO   gv_printer
                 ,g_number_of_copies
           FROM   fnd_concurrent_requests fcr
           WHERE  fcr.request_id = g_request_id;
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
           Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Erreur de récupération de l''imprimante');
           gv_printer := NULL;
           g_number_of_copies := 0;
        END;
        
        
 
  EXCEPTION
        WHEN program_error THEN
             fnd_file.put_line(fnd_file.log, 'ERREUR : ' || v_step_program_error);
             RAISE; 
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'INIT : ' ||SQLERRM;
  END init;


 /*
 *************************************************************************
 * PROCEDURE NAME : Output_Header
 *
 * DESCRIPTION
 *  Procédure pour insérer une en-tête dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE output_header
  IS
        cv_line                     VARCHAR2 (100);
        v_conc_program_name         fnd_concurrent_programs.concurrent_program_name%TYPE;
        v_user_conc_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN

        cv_line    := '+-------------------------------------------------------------------------+';

        ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
        BEGIN
            SELECT fcp.concurrent_program_name,
                   fcpt.user_concurrent_program_name
            INTO   v_conc_program_name,
                   v_user_conc_program_name
            FROM   fnd_concurrent_programs fcp,
                   fnd_concurrent_programs_tl fcpt
            WHERE  fcp.application_id = Fnd_Global.prog_appl_id
            AND    fcp.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.application_id = Fnd_Global.prog_appl_id
            AND    fcpt.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.LANGUAGE = Fnd_Global.current_language;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_user_conc_program_name    := '???????????????????????';
                v_conc_program_name         := '???????';
        END;


        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Nom du traitement  : ' || v_user_conc_program_name);
        Fnd_File.put_line (Fnd_File.output, 'Code du traitement : ' || v_conc_program_name);
        Fnd_File.put_line (Fnd_File.output, 'Programme lancé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10) || CHR(10));
  END output_header;
  
  
 /*
 *************************************************************************
 * PROCEDURE NAME : Request_parameters
 *
 * DESCRIPTION
 *  Procédure pour afficher les valeurs de paramètres du traitement
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 ************************************************************************
 */

  PROCEDURE Request_parameters
  IS

      CURSOR cur_parameters
            IS
            SELECT form_left_prompt
            FROM   fnd_concurrent_requests fcr,
                   fnd_concurrent_programs fcp,
                   fnd_descr_flex_col_usage_vl fdfcu
            WHERE  fdfcu.descriptive_flexfield_name = '$SRS$.'||fcp.concurrent_program_name
            AND    fcp.concurrent_program_id = fcr.concurrent_program_id
            AND    fcr.request_id = Fnd_Global.conc_request_id
            ORDER BY fdfcu.column_seq_num
            ;
        rec_parameters        cur_parameters%ROWTYPE;

        sql_req               VARCHAR2(500);
        v_argument_number    VARCHAR2(12);
        v_argument_num       NUMBER;
        v_argument_value     VARCHAR2(240);
  BEGIN

        Fnd_File.put_line (Fnd_File.output, 'PARAMETRES : ');
        Fnd_File.put_line (Fnd_File.output, '--------------');
        Fnd_File.put_line (Fnd_File.log, 'PARAMETRES : ');
        Fnd_File.put_line (Fnd_File.log, '--------------');

        v_argument_num := 1;

        OPEN cur_parameters;
        FETCH cur_parameters INTO rec_parameters;

             IF (cur_parameters%FOUND)
             THEN
                   v_argument_number := 'ARGUMENT'||v_argument_num;

                   sql_req := 'SELECT '||v_argument_number||
                              ' FROM fnd_concurrent_requests '||
                              'WHERE request_id = Fnd_Global.conc_request_id';

                   EXECUTE IMMEDIATE sql_req INTO v_argument_value;

                   Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
                   Fnd_File.put_line (Fnd_File.log, rec_parameters.form_left_prompt||' : '||v_argument_value);


                   LOOP
                      FETCH cur_parameters INTO rec_parameters;
                      EXIT WHEN cur_parameters%NOTFOUND;

                          v_argument_num := v_argument_num + 1;
                          v_argument_number := 'ARGUMENT'||v_argument_num;

                          sql_req := 'SELECT '||v_argument_number||
                                     ' FROM fnd_concurrent_requests '||
                                     'WHERE request_id = Fnd_Global.conc_request_id';

                          EXECUTE IMMEDIATE sql_req INTO v_argument_value;

                          Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
                          Fnd_File.put_line (Fnd_File.log, rec_parameters.form_left_prompt||' : '||v_argument_value);
                   END LOOP;

                   Fnd_File.put_line (Fnd_File.output,CHR(10));

            ELSE
                   Fnd_File.put_line (Fnd_File.output,'Aucun argument');
                   Fnd_File.put_line (Fnd_File.log,'Aucun argument');
            END IF;

        CLOSE cur_parameters;

  END Request_parameters;

 /*
 *************************************************************************
 * PROCEDURE NAME : Output_End
 *
 * DESCRIPTION
 *  Procédure pour insérer une fin dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE output_end
  IS
        cv_line                     VARCHAR2 (100);
  BEGIN

        cv_line    := '+-------------------------------------------------------------------------+';



        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
        Fnd_File.put_line (Fnd_File.output, cv_line);
  END output_end;

 /*
 *************************************************************************
 * PROCEDURE NAME : Add_Message
 *
 * DESCRIPTION
 *  Procédure pour insérer un message dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE Add_Message  (p_nom_lot             IN  VARCHAR2,
                          p_nom_piece           IN  VARCHAR2,
                          p_line_num            IN  VARCHAR2,
                          p_message_text        IN  VARCHAR2
                          ) 
  IS
        cv_line                     VARCHAR2 (500);
  BEGIN

    IF  g_summary.message_flag = 0 THEN
      cv_line := 'Etat des erreurs :';
      Fnd_File.put_line (Fnd_File.output, CHR(10)||cv_line);
      cv_line := '-----------------';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := 'Nom du lot  Nom Pièce                     Num ligne  Message d''erreur';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := '----------  ----------------------------- ---------  -----------------';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      g_summary.message_flag := 1;
    END IF;
    
    cv_line := RPAD(p_nom_lot,10,' ') ||'  '|| RPAD(NVL(p_nom_piece,' '),28,' ') || '  ' ||RPAD(NVL(p_line_num,' '),9,' ') ||'  ' || p_message_text ;

    Fnd_File.put_line (Fnd_File.output, cv_line);
    
    -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
    -- Ajout des messages d'erreur en table
    dka_tools_pkg.ins_prog_message(g_request_id,
                                   'DKA_REPGLPIECEREPIMP',
                                    'ETL',
                                    'DKA_REP_PIECES_TMP',
                                    p_nom_lot||'|'||p_nom_piece||'|'||p_line_num,
                                    'ERROR_CODE',
                                    NULL,
                                    'E',
                                    substr(p_message_text,1,500));

  END Add_Message;

 /*
 *************************************************************************
 * PROCEDURE NAME : Launch_Loader
 * 
 * DESCRIPTION
 *  Procédure de lancement du programme de chargement dans la table spécifique
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_directory       Répertoire du fichier
 * p_file_name       Nom du fichier à charger
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 * 
 ************************************************************************
 */
  PROCEDURE Launch_Loader(p_Errbuf            OUT VARCHAR2,
                          p_retcode           OUT NUMBER
                          ) 
  IS
        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
        v_message                VARCHAR2 (500);
        b_result                  BOOLEAN;

  BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Launch_Loader');    
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 
                                         'Lancement de chargement du fichier dans la table d''interface spécifique : ');

        fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT, 'CHARGEMENT DU FICHIER :');
        fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
        ------------------------------------------------------
        -- Lancement du traitement de chargement du fichier --
        ------------------------------------------------------     
        -- Positionnement des options d'impression
        b_result := fnd_request.set_print_options(printer => gv_printer,
                                                  copies => g_number_of_copies); 
        -- Lancement du traitement 
        g_loader_request_id         := Fnd_Request.submit_request (
                                                                   'DKA'                            -- APPL
                                                                  ,'DKA_LOADER_REPGLPIECEREP'       -- PROG
                                                                  ,NULL                             -- PROGRAM_NAME
                                                                  ,NULL                             -- START
                                                                  ,FALSE                            -- SUB_REQUEST
                                                                  );
 
        IF g_loader_request_id = 0
        THEN
            p_retcode    := 2;
            fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de chargement du fichier a échoué' || CHR(10) ||
                                            'PROGRAMME  : DKA_LOADER_REPGLPIECEREP'
                                            );
            Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de chargement du fichier a échoué');
        ELSE
            COMMIT;
            Fnd_File.put_line(Fnd_File.LOG, '=> LOAD REQUEST ID= ' || g_loader_request_id);            
            Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement de chargement du fichier : ' || g_loader_request_id);  
 
            -- Attente de la fin du traitement
            IF NOT (Fnd_Concurrent.wait_for_request (g_loader_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
            THEN                        
                p_Errbuf  := v_Message;
                Fnd_file.put_line(Fnd_file.log, 'ERREUR : Attente de la fin du programme de chargement du fichier dépassée : Fin du traitement' || CHR(10) ||
                                                'MESSAGE : ' || v_Message || CHR(10) );  
            END IF;
                         
            IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') 
            THEN          
                Fnd_File.put_line(Fnd_File.LOG, 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
                Fnd_File.put_line(Fnd_File.OUTPUT, '. Statut de fin : ' || v_phase || '/' || v_status);

                SELECT count(1)
                INTO g_summary.loaded_rows
                FROM DKA_REP_PIECES_TMP
                ;
                
            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
            THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement de chargement en warning '|| g_loader_request_id);
                p_retcode    := 1;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')  
            THEN
                p_retcode := 2;
                p_Errbuf  := 'ERREUR : Fin anormale du traitement de chargement : '||v_Message;
  
                fnd_file.put_line(fnd_file.LOG, 'ERREUR : Fin anormale du traitement de chargement '|| g_loader_request_id  || CHR(10) ||
                                                'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                                'MESSAGE : ' || v_message || CHR(10) );
                Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement de chargement '||g_loader_request_id);
            END IF;
            
        END IF;
  

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Launch_Loader');    
  
  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'LAUNCH_LOADER : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Launch_Loader : EXCEPTION OTHERS ');
  END Launch_Loader;  


 /*
 *************************************************************************
 * PROCEDURE NAME : validate_data
 * 
 * DESCRIPTION
 *  Procédure de validation des données
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 * 
 ************************************************************************
 */
  PROCEDURE validate_data(  p_Errbuf            OUT VARCHAR2,
                            p_retcode           OUT NUMBER
                          ) 
  IS
    v_message                   VARCHAR2 (500);                                                    
    v_flag_erreur               BOOLEAN := FALSE;
    v_ledger_lot                NUMBER;
    v_ledger_piece              NUMBER;
    v_exist                     VARCHAR2(10);
    v_code_projet_new           VARCHAR2(100);
    v_tache_new                 VARCHAR2(100);
    V_CLE_NEW                   VARCHAR2(240);
    v_cle_new_id                NUMBER;
    v_JE_CATEGORY_NAME          NUMBER;
    V_PROJECT_ID                NUMBER;
    V_TASK_ID                   NUMBER;
    V_CONTEXTE                  VARCHAR2(100);
    V_EXPENDITURE_TYPE          VARCHAR2(100);
    v_segment1                  VARCHAR2(150);
    v_segment2                  VARCHAR2(150);
    v_segment3                  VARCHAR2(150);
    v_segment4                  VARCHAR2(150);
    v_segment5                  VARCHAR2(150);
    v_segment6                  VARCHAR2(150);
    v_segment7                  VARCHAR2(150);
    v_segment8                  VARCHAR2(150);
    v_segment9                  VARCHAR2(150);
    v_segment10                 VARCHAR2(150);
    v_segment11                 VARCHAR2(150);
    v_segment12                 VARCHAR2(150);
    v_chaine                    VARCHAR2(500);
    v_statut_lot                VARCHAR2(10);
    
    v_Errbuf                    VARCHAR2(240);
    v_retcode                   NUMBER;
    
     vv_SEGMENT1   GL_CODE_COMBINATIONS.SEGMENT1%TYPE;
     vv_SEGMENT2   GL_CODE_COMBINATIONS.SEGMENT2%TYPE;
     vv_SEGMENT3   GL_CODE_COMBINATIONS.SEGMENT3%TYPE;
     vv_SEGMENT4   GL_CODE_COMBINATIONS.SEGMENT4%TYPE;
     vv_SEGMENT5   GL_CODE_COMBINATIONS.SEGMENT5%TYPE;
     vv_SEGMENT6   GL_CODE_COMBINATIONS.SEGMENT6%TYPE;
     vv_SEGMENT7   GL_CODE_COMBINATIONS.SEGMENT7%TYPE;
     vv_SEGMENT8   GL_CODE_COMBINATIONS.SEGMENT8%TYPE;
     vv_SEGMENT9   GL_CODE_COMBINATIONS.SEGMENT9%TYPE;
     vv_SEGMENT10  GL_CODE_COMBINATIONS.SEGMENT10%TYPE;
     vv_SEGMENT11  GL_CODE_COMBINATIONS.SEGMENT11%TYPE;
     vv_SEGMENT12  GL_CODE_COMBINATIONS.SEGMENT12%TYPE;
     vv_errbuf              VARCHAR2(500);
     vn_retcode             NUMBER;
     vn_code_combination_id GL_CODE_COMBINATIONS.CODE_COMBINATION_ID%TYPE;
    
    CURSOR cur_pieces IS
      SELECT tmp.*, COUNT(1) OVER (PARTITION BY nom_lot, nom_piece, num_ligne) cpt
      FROM DKA_REP_PIECES_TMP tmp
      WHERE load_request_id = DECODE( g_loader_request_id
                                     , -1, load_request_id
                                     , g_loader_request_id)
      AND  statut = '-1'
    ORDER BY nom_lot,nom_piece,num_ligne
    ;
    

    
  BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_data');    
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 
                                         'Validation des données dans les tables spécifiques : ');

        FOR rec_cur_pieces IN cur_pieces LOOP
            v_flag_erreur := FALSE;
            v_statut_lot  := 'S';            
            
            IF rec_cur_pieces.NOM_LOT IS NULL THEN 
                  v_message := 'Nom du lot manquant';
                  Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
                  v_flag_erreur := TRUE;
                  v_statut_lot := 'E';
            END IF;
            
            IF rec_cur_pieces.NOM_LOT IS NOT NULL THEN 
                BEGIN 
                    --Fnd_File.put_line (Fnd_File.LOG, 'Recherche LEDGER_ID 1');
                    SELECT ledger_id
                    INTO v_ledger_lot
                    FROM GL_LEDGERS 
                    WHERE short_name = SUBSTR(rec_cur_pieces.NOM_LOT,1,4);
                    
                EXCEPTION
                    WHEN OTHERS THEN
                      v_ledger_lot := NULL;
                      v_message := 'Impossible de déterminer le livre du Lot '||rec_cur_pieces.NOM_LOT;
                      Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
                      v_flag_erreur := TRUE;
                      v_statut_lot := 'E';
                END;
            END IF;

            IF rec_cur_pieces.NOM_PIECE IS NULL THEN 
                  v_message := 'Nom de la pièce manquant';
                  Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
                  v_flag_erreur := TRUE;
            END IF;

            IF rec_cur_pieces.NOM_LOT IS NOT NULL THEN 
                BEGIN 
                    --Fnd_File.put_line (Fnd_File.LOG, 'Recherche LEDGER_ID 2');
                    SELECT ledger_id
                    INTO v_ledger_piece
                    FROM GL_LEDGERS 
                    WHERE short_name = SUBSTR(rec_cur_pieces.NOM_LOT,1,4);
                EXCEPTION
                    WHEN OTHERS THEN
                      v_ledger_piece := NULL;
                      v_message := 'Impossible de déterminer le livre de la pièce '||rec_cur_pieces.NOM_PIECE;
                      Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
                      v_flag_erreur := TRUE;
                END;
            END IF;
            
            BEGIN
                --Fnd_File.put_line (Fnd_File.LOG, 'Recherche DKA_ABON_TYPE_PIECE');
                SELECT 'X'
                INTO   v_exist
                FROM   Fnd_Flex_Value_Sets        Ffvs,
                       Fnd_Flex_Values            Ffv
                WHERE  Ffvs.Flex_Value_Set_Name = 'DKA_ABON_TYPE_PIECE'
                AND    Ffvs.Flex_Value_Set_Id   = Ffv.Flex_Value_Set_Id
                AND    Ffv.Flex_Value           = rec_cur_pieces.TYPE_PIECE
                AND    Ffv.Enabled_Flag         = 'Y'
                AND    Trunc(SYSDATE) BETWEEN Nvl(Ffv.Start_Date_Active, Trunc(SYSDATE))
                                      AND     Nvl(Ffv.End_Date_Active, Trunc(SYSDATE))
                ;
                
                --Fnd_File.put_line (Fnd_File.LOG, 'Recherche JE_CATEGORY_NAME');
                SELECT JE_CATEGORY_NAME
                INTO v_JE_CATEGORY_NAME
                FROM GL_JE_CATEGORIES
                WHERE USER_JE_CATEGORY_NAME = rec_cur_pieces.TYPE_PIECE;
                
            EXCEPTION
                    WHEN OTHERS THEN
                      v_JE_CATEGORY_NAME := NULL;
                      v_message := 'Type de pièce manquant ou invalide '||rec_cur_pieces.TYPE_PIECE;
                      Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
                      v_flag_erreur := TRUE;
            END;

            IF rec_cur_pieces.CUF_PIECE IS NULL THEN
                rec_cur_pieces.CUF_PIECE := 0;
            END IF;

            IF rec_cur_pieces.NUM_LIGNE IS NULL THEN 
                  v_message := 'Numéro de ligne manquant';
                  Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
                  v_flag_erreur := TRUE;
            END IF;

            IF rec_cur_pieces.PROJET_OLD IS NOT NULL THEN
                --Fnd_File.put_line (Fnd_File.LOG, 'Recherche 014_PROJETS');
                dka_rep_transco_pkg.get_transco(pv_transco_name => '014_PROJETS',
                              pv_column_01    => rec_cur_pieces.PROJET_OLD,
                              pv_out_01       => v_code_projet_new,
                              pv_out_02       => v_tache_new);

                --Fnd_File.put_line (Fnd_File.LOG, 'Recherche project_id');
                BEGIN 
                    SELECT project_id
                    INTO   v_project_id
                    FROM   PA_PROJECTS_ALL
                    WHERE  segment1 = v_code_projet_new
                    ;
                EXCEPTION
                    WHEN OTHERS THEN 
                        v_project_id := NULL;
                        v_message := 'Impossible de déterminer le projet R12 pour le projet '||rec_cur_pieces.PROJET_OLD;
                        Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
                        v_flag_erreur := TRUE;
                END;
                
                BEGIN 
                    --Fnd_File.put_line (Fnd_File.LOG, 'Recherche task_id');
                    SELECT task_id
                    INTO   v_task_id
                    FROM   PA_tasks
                    WHERE  task_number = v_tache_new
                    AND project_id = v_project_id
                    ;
                EXCEPTION
                    WHEN OTHERS THEN 
                        v_task_id := NULL;
                        v_message := 'Impossible de déterminer la tâche projet R12 pour le projet '||rec_cur_pieces.PROJET_OLD;
                        Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
                        v_flag_erreur := TRUE;
                END;
                
                IF rec_cur_pieces.type_dpse_old IS NOT NULL THEN
                    v_contexte        := 'Y.E.X';
                ELSIF rec_cur_pieces.type_evt_old IS NOT NULL THEN
                    v_contexte        := 'Y.R.X';
                ELSE
                    v_contexte        := NULL;
                END IF;
            ELSE
                v_project_id      := NULL;
                v_task_id         := NULL;
                v_code_projet_new := NULL;
                v_tache_new       := NULL;
                v_contexte        := NULL;
            END IF;
            
            IF rec_cur_pieces.type_dpse_old IS NOT NULL THEN
                --Fnd_File.put_line (Fnd_File.LOG, 'Recherche 018_EXPENDITURE_TYPE');
                DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '018_EXPENDITURE_TYPE',
                                          pv_column_01    => rec_cur_pieces.type_dpse_old,
                                          pv_out_01       => v_expenditure_type);
            ELSE
                v_expenditure_type := NULL;
            END IF;
            
            IF rec_cur_pieces.PROJET_OLD IS NULL THEN
                IF rec_cur_pieces.cle_old IS NOT NULL THEN
                    v_segment1 := SUBSTR(rec_cur_pieces.cle_old,1,INSTR(rec_cur_pieces.cle_old,'.')-1);
                    v_chaine   := SUBSTR(rec_cur_pieces.cle_old,INSTR(rec_cur_pieces.cle_old,'.')+1);
                    v_segment2 := SUBSTR(v_chaine,1,INSTR(v_chaine,'.')-1);
                    v_chaine   := SUBSTR(v_chaine,INSTR(v_chaine,'.')+1);
                    v_segment3 := SUBSTR(v_chaine,1,INSTR(v_chaine,'.')-1);
                    v_chaine   := SUBSTR(v_chaine,INSTR(v_chaine,'.')+1);
                    v_segment4 := SUBSTR(v_chaine,1,INSTR(v_chaine,'.')-1);
                    v_chaine   := SUBSTR(v_chaine,INSTR(v_chaine,'.')+1);
                    v_segment5 := SUBSTR(v_chaine,1,INSTR(v_chaine,'.')-1);
                    v_chaine   := SUBSTR(v_chaine,INSTR(v_chaine,'.')+1);
                    v_segment6 := SUBSTR(v_chaine,1,INSTR(v_chaine,'.')-1);
                    v_chaine   := SUBSTR(v_chaine,INSTR(v_chaine,'.')+1);
                    v_segment7 := SUBSTR(v_chaine,1,INSTR(v_chaine,'.')-1);
                    v_chaine   := SUBSTR(v_chaine,INSTR(v_chaine,'.')+1);
                    v_segment8 := SUBSTR(v_chaine,1,INSTR(v_chaine,'.')-1);
                    v_chaine   := SUBSTR(v_chaine,INSTR(v_chaine,'.')+1);
                    v_segment9 := SUBSTR(v_chaine,1,INSTR(v_chaine,'.')-1);
                    v_chaine   := SUBSTR(v_chaine,INSTR(v_chaine,'.')+1);
                    v_segment10:= SUBSTR(v_chaine,1,INSTR(v_chaine,'.')-1);
                    
                    BEGIN
                        --Fnd_File.put_line (Fnd_File.LOG, 'Recherche cle_new');
                        
                       DKA_REP_TRANSCO_PKG.get_cle_transco( v_segment1,
                                        v_segment2,
                                        v_segment3,
                                        v_segment4,
                                        v_segment5,
                                        v_segment6,
                                        v_segment8,
                                        v_segment9,
                                        v_segment10,
                                        vv_SEGMENT1, 
                                        vv_SEGMENT2, 
                                        vv_SEGMENT3, 
                                        vv_SEGMENT4, 
                                        vv_SEGMENT5, 
                                        vv_SEGMENT6, 
                                        vv_SEGMENT7, 
                                        vv_SEGMENT8, 
                                        vv_SEGMENT9, 
                                        vv_SEGMENT10,
                                        vv_SEGMENT11,
                                        vv_SEGMENT12);    

                       v_cle_new := vv_segment1 ||'.'||vv_segment2 ||'.'||vv_segment3 ||'.'||vv_segment4 ||'.'||vv_segment5 ||'.'||vv_segment6 ||'.'||vv_segment7 ||'.'||vv_segment8 ||'.'||vv_segment9 ||'.'||vv_segment10 ||'.'||vv_segment11 ||'.'||vv_segment12;
                                        
                       --Recherche de la clé
                       Dka_Tools_Pkg.get_code_combination_id (
                        pv_segment1              => vv_SEGMENT1,
                        pv_segment2              => vv_SEGMENT2,
                        pv_segment3              => vv_SEGMENT3,
                        pv_segment4              => vv_SEGMENT4,
                        pv_segment5              => vv_SEGMENT5,
                        pv_segment6              => vv_SEGMENT6,
                        pv_segment7              => vv_SEGMENT7,
                        pv_segment8              => vv_SEGMENT8,
                        pv_segment9              => vv_SEGMENT9,
                        pv_segment10             => vv_SEGMENT10,
                        pv_segment11             => vv_SEGMENT12,
                        pv_segment12             => vv_SEGMENT12,
                        pn_code_combination_id   => vn_code_combination_id,
                        pv_errbuf                => vv_errbuf,
                        pn_retcode               => vn_retcode);

                        SELECT CODE_COMBINATION_ID
                        INTO v_cle_new_id
                        FROM GL_CODE_COMBINATIONS
                        WHERE CODE_COMBINATION_ID = vn_code_combination_id
                        ;
                        
                    EXCEPTION
                        WHEN OTHERS THEN
                        v_cle_new_id := NULL;
                        -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
                        v_message := 'Impossible de déterminer la nouvelle clé comptable R12 => ' || vv_errbuf;
                        Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
                        v_flag_erreur := TRUE;
                    END;
                ELSE
                    v_cle_new_id := NULL;
                    -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
                    v_message := 'Impossible de déterminer la nouvelle clé comptable R12 => ' || v_cle_new;
                    Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
                    v_flag_erreur := TRUE;
                END IF;
            ELSE
                --Autocounting
                --Fnd_File.put_line (Fnd_File.LOG, 'Recherche segments Autocounting');
                --Fnd_File.put_line (Fnd_File.LOG, 'Recherche segment1');
                v_segment1 := DKA_SPAAUTOACCOUNTING_PKG.societe_projet(v_project_id);
                --Fnd_File.put_line (Fnd_File.LOG, 'Recherche segment2');
                v_segment2 := DKA_SPAAUTOACCOUNTING_PKG.uo_projet(v_project_id);
                
                IF rec_cur_pieces.type_dpse_old IS NOT NULL THEN
                    --Fnd_File.put_line (Fnd_File.LOG, 'Recherche segment3');
                    v_segment3 := DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts( v_project_id,
                                                                             v_expenditure_type,
                                                                             v_task_id);
                    --Fnd_File.put_line (Fnd_File.LOG, 'Recherche segment4');
                    v_segment4 := DKA_SPAAUTOACCOUNTING_PKG.run_cpt_groupe_couts_f( v_project_id,
                                                                                    v_expenditure_type,
                                                                                    NULL,
                                                                                    v_task_id,
                                                                                    NULL);
                ELSE 
                    --Fnd_File.put_line (Fnd_File.LOG, 'Recherche segment3');
                    Dka_Pa_Tools_Pkg.pa_run_accounting_rule (
                                    pv_rule_name           => 'CPT_LOCAL_PRODUIT',
                                    pv_event_type          => rec_cur_pieces.type_evt_old,
                                    pv_segment_value       => v_segment3,
                                    pv_errbuf              => v_Errbuf,
                                    pn_retcode             => v_retcode
                                );
                    
                    --Fnd_File.put_line (Fnd_File.LOG, 'Recherche segment4');
                    v_segment4    := Dka_Spaautoaccounting_Pkg.run_cpt_groupe_produit_f (
                                     pn_project_id   => v_project_id,
                                     pv_event_type   => rec_cur_pieces.type_evt_old,
                                     pn_task_id      => v_task_id
                                     );
                END IF;
                
                IF rec_cur_pieces.cle_old IS NOT NULL THEN
                    v_chaine   := SUBSTR(rec_cur_pieces.cle_old,INSTR(rec_cur_pieces.cle_old,'.')+1);
                    v_chaine   := SUBSTR(v_chaine,INSTR(v_chaine,'.')+1);
                    v_chaine   := SUBSTR(v_chaine,INSTR(v_chaine,'.')+1);
                    v_chaine   := SUBSTR(v_chaine,INSTR(v_chaine,'.')+1);
                    v_segment5 := SUBSTR(v_chaine,1,INSTR(v_chaine,'.')-1);
                ELSE
                    v_segment5 := NULL;
                END IF;
                
                v_segment5 := DKA_REP_TRANSCO_PKG.get_complement_compte(v_segment5);
                /*v_segment5 := DKA_SPAAUTOACCOUNTING_PKG.code_interco(v_project_id,
                                                                     v_vendor_site_id);*/
                --Fnd_File.put_line (Fnd_File.LOG, 'Recherche segment6');
                v_segment6 := DKA_SPAAUTOACCOUNTING_PKG.centrefi(v_project_id);
                --Fnd_File.put_line (Fnd_File.LOG, 'Recherche segment7');
                v_segment7 := DKA_SPAAUTOACCOUNTING_PKG.affaire(v_project_id);
                --Fnd_File.put_line (Fnd_File.LOG, 'Recherche segment8');
                v_segment8 := dka_spaautoaccounting_pkg.projetfi(v_project_id);
                v_segment9 := '0';
                v_segment10:= '0';
                v_segment11:= '0';
                v_segment12:= '0';
                
                v_cle_new := v_segment1 ||'.'||v_segment2 ||'.'||v_segment3 ||'.'||v_segment4 ||'.'||v_segment5 ||'.'||v_segment6 ||'.'||v_segment7 ||'.'||v_segment8 ||'.'||v_segment9 ||'.'||v_segment10 ||'.'||v_segment11 ||'.'||v_segment12;
                
                --Fnd_File.put_line (Fnd_File.LOG, 'Recherche ccid');
                
                DKA_TOOLS_PKG.get_code_combination_id(
                                                      v_segment1
                                                     ,v_segment2
                                                     ,v_segment3
                                                     ,v_segment4
                                                     ,v_segment5
                                                     ,v_segment6
                                                     ,v_segment7
                                                     ,v_segment8
                                                     ,v_segment9
                                                     ,v_segment10
                                                     ,v_segment11
                                                     ,v_segment12
                                                     ,v_cle_new_id
                                                     ,v_Errbuf
                                                     ,v_retcode
                                                     ,'Y'
                                                     );
                BEGIN
                    SELECT CODE_COMBINATION_ID
                    INTO v_cle_new_id
                    FROM GL_CODE_COMBINATIONS
                    WHERE CODE_COMBINATION_ID = v_cle_new_id
                    ;
                EXCEPTION
                    WHEN OTHERS THEN
                    --Fnd_File.put_line (Fnd_File.LOG,TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||  'Recherche ccid pour lot/piece/ligne '||rec_cur_pieces.NOM_LOT||'/'||rec_cur_pieces.nom_piece||'/'||rec_cur_pieces.num_ligne ||' ==> ' ||v_Errbuf);
                    v_cle_new_id := NULL;
                    -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
                    v_message := 'Impossible de déterminer la nouvelle clé comptable R12 ==> ' ||v_Errbuf;
                    Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
                    v_flag_erreur := TRUE;
                END;
            END IF;
            /*
            v_message := 'Impossible de déterminer la nouvelle clé comptable R12';
            Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
            v_flag_erreur := TRUE;
            */
            
            IF rec_cur_pieces.NUM_LIG_FORM IS NULL THEN 
                v_message := 'Numéro de la ligne de formule manquant';
                Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
                v_flag_erreur := TRUE;
            END IF;
            
            IF rec_cur_pieces.OPER_FORM IS NULL THEN 
                v_message := 'Code Opérateur  de la ligne de formule est manquant';
                Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
                v_flag_erreur := TRUE;
            END IF;
            
            IF rec_cur_pieces.MONTANT_FORM IS NULL THEN 
                v_message := 'Montant de la ligne de formule manquant';
                Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
                v_flag_erreur := TRUE;
            END IF;
            
            -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
            IF rec_cur_pieces.cpt > 1 THEN
                v_message := 'Ligne en doublon (lot/pièce/numéro)';
                Add_Message(rec_cur_pieces.NOM_LOT,rec_cur_pieces.nom_piece,rec_cur_pieces.num_ligne,v_message);
                v_flag_erreur := TRUE;
            END IF;            

              IF not v_flag_erreur THEN
                -- Table DKA_REP_PIECES_TMP
                UPDATE DKA_REP_PIECES_TMP
                SET 
                       TYPE_LOT             = 'Livre unique'
                      ,DEVISE               = 'EUR'
                      ,LIVRE_LOT            = v_ledger_lot
                      ,LIVRE_PIECE          = v_ledger_piece
                      ,CUF_PIECE            = rec_cur_pieces.CUF_PIECE
                      ,DEBUT_PIECE          = TO_DATE ('01/01/2018','DD/MM/YYYY')
                      ,projet_new           = v_project_id
                      ,tache_new            = v_task_id
                      ,cle_new              = v_cle_new
                      ,cle_new_id           = v_cle_new_id
                      ,JE_CATEGORY_NAME     = v_JE_CATEGORY_NAME
                      ,type_dpse_new        = v_expenditure_type
                      ,type_evt_new         = rec_cur_pieces.type_evt_old
                      ,contexte             = v_contexte
                      ,statut_lot           = v_statut_lot
                      ,STATUT               = 'S'
                      -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
                      ,statut_piece         = 'S'
                      ,last_update_date     = sysdate
                WHERE nom_lot       = rec_cur_pieces.nom_lot
                AND   nom_piece     = rec_cur_pieces.nom_piece
                AND   num_ligne     = rec_cur_pieces.num_ligne
                ;
                --g_summary.validated_rows := g_summary.validated_rows + 1;
              ELSE
                -- Table DKA_REP_PIECES_TMP
                UPDATE DKA_REP_PIECES_TMP
                SET 
                       TYPE_LOT             = 'Livre unique'
                      ,DEVISE               = 'EUR'
                      ,LIVRE_LOT            = v_ledger_lot
                      ,LIVRE_PIECE          = v_ledger_piece
                      ,CUF_PIECE            = rec_cur_pieces.CUF_PIECE
                      ,DEBUT_PIECE          = TO_DATE ('01/01/2018','DD/MM/YYYY')
                      ,projet_new           = v_project_id
                      ,tache_new            = v_task_id
                      ,cle_new              = v_cle_new
                      ,cle_new_id           = v_cle_new_id
                      ,JE_CATEGORY_NAME     = v_JE_CATEGORY_NAME
                      ,type_dpse_new        = v_expenditure_type
                      ,type_evt_new         = rec_cur_pieces.type_evt_old
                      ,contexte             = v_contexte
                      ,statut_lot           = v_statut_lot
                      ,STATUT               = 'E'
                      ,last_update_date     = sysdate
                WHERE nom_lot       = rec_cur_pieces.nom_lot
                AND   nom_piece     = rec_cur_pieces.nom_piece
                AND   num_ligne     = rec_cur_pieces.num_ligne
                ;

                -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
                UPDATE DKA_REP_PIECES_TMP
                SET statut_lot           = v_statut_lot
                   ,last_update_date     = sysdate
                WHERE nom_lot       = rec_cur_pieces.nom_lot
                AND statut_lot != 'T';
                
                                
                UPDATE DKA_REP_PIECES_TMP
                SET statut_piece     = 'E'
                   ,last_update_date = sysdate
                WHERE nom_lot       = rec_cur_pieces.nom_lot
                AND nom_piece     = rec_cur_pieces.nom_piece;
                
                UPDATE DKA_REP_PIECES_TMP
                   SET STATUT           = 'E'
                WHERE  STATUT           = 'T'
                AND   statut_piece     = 'E';
                                
                --g_summary.rejected_rows := g_summary.rejected_rows + 1;
              END IF;
            ---<<
            ---<<

        END LOOP;          
        
        COMMIT;
        
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_data');    
  
  
  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'validate_data : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure validate_data : EXCEPTION OTHERS ');
  END validate_data;  
 
 
 /*
 *************************************************************************
 * PROCEDURE NAME : import_data
 * 
 * DESCRIPTION
 *  Procédure d'insertion dans les tables finales
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 * 
 ************************************************************************
 */
  PROCEDURE import_data(  p_Errbuf            OUT VARCHAR2,
                          p_retcode           OUT NUMBER
                          ) 
  IS
    
    v_RECURRING_BATCH_ID            NUMBER;
    V_RECURRING_HEADER_ID           NUMBER;
    v_message                       VARCHAR2 (500);
    cv_line                         VARCHAR2 (100);
    
    CURSOR cur_batches IS
      SELECT NOM_LOT,LIVRE_LOT,DESC_LOT
      FROM DKA_REP_PIECES_TMP
      WHERE STATUT_LOT = 'S'
      AND  load_request_id = DECODE( g_loader_request_id
                                    , -1, load_request_id
                                    , g_loader_request_id)
      GROUP BY NOM_LOT,LIVRE_LOT,DESC_LOT
    ;
    
    CURSOR cur_headers(p_nom_lot VARCHAR2)IS
      -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
      SELECT NOM_LOT,LIVRE_LOT,DESC_LOT,NOM_PIECE,TYPE_PIECE,CUF_PIECE,FIN_PIECE,DEBUT_PIECE,devise,LIVRE_PIECE,JE_CATEGORY_NAME
      FROM DKA_REP_PIECES_TMP tmp
      WHERE nom_lot = p_nom_lot
      AND STATUT_PIECE = 'S'
      AND STATUT = 'S'
      AND NOT EXISTS (select 'x' from  DKA_REP_PIECES_TMP tmp2 WHERE tmp.nom_lot = tmp2.nom_lot AND tmp.nom_piece = tmp2.nom_piece AND tmp2.statut = 'E')
      AND  load_request_id = DECODE( g_loader_request_id
                            , -1, load_request_id
                            , g_loader_request_id)
      GROUP BY NOM_LOT,LIVRE_LOT,DESC_LOT,NOM_PIECE,TYPE_PIECE,CUF_PIECE,FIN_PIECE,DEBUT_PIECE,devise,LIVRE_PIECE,JE_CATEGORY_NAME
    ;
    
    CURSOR cur_LINES (p_nom_lot VARCHAR2,p_nom_piece VARCHAR2) IS
      SELECT 
             Nom_lot
            ,nom_piece
            ,NUM_LIGNE
            ,CLE_NEW_ID
            ,DESC_LIGNE
            ,PROJET_NEW
            ,TACHE_NEW
            ,TYPE_EVT_NEW
            ,TYPE_DPSE_NEW
            ,CONTEXTE
      FROM DKA_REP_PIECES_TMP
      WHERE nom_lot = p_nom_lot
      AND STATUT = 'S'
      -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
      AND STATUT_PIECE = 'S'
      AND STATUT_LOT = 'S' 
      AND nom_piece = p_nom_piece
      AND load_request_id = DECODE( g_loader_request_id
                                    , -1, load_request_id
                                    , g_loader_request_id)
      GROUP BY
             Nom_lot
            ,nom_piece
            ,NUM_LIGNE
            ,CLE_NEW_ID
            ,DESC_LIGNE
            ,PROJET_NEW
            ,TACHE_NEW
            ,TYPE_EVT_NEW
            ,TYPE_DPSE_NEW
            ,CONTEXTE
    ;
    
    CURSOR cur_rules (p_nom_lot VARCHAR2,p_nom_piece VARCHAR2,p_num_ligne NUMBER) IS
      SELECT *
      FROM DKA_REP_PIECES_TMP
      WHERE nom_lot = p_nom_lot
      AND STATUT = 'S'
      -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
      AND STATUT_PIECE = 'S'
      AND STATUT_LOT = 'S' 
      AND nom_piece = p_nom_piece
      AND num_ligne = p_num_ligne
      AND load_request_id = DECODE( g_loader_request_id
                                    , -1, load_request_id
                                    , g_loader_request_id)
      ;
      
      l_batchfound BOOLEAN;
    
  BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_data');    
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 
                                         'Insertion dans les tables finales : ');
        
        Fnd_File.put_line (Fnd_File.output, CHR(10)||'Etat des erreurs de l''import');
        Fnd_File.put_line (Fnd_File.output, '----------------------------');
        cv_line := 'Nom du lot  Nom Pièce                Num ligne  Message d''erreur';
        Fnd_File.put_line (Fnd_File.output, cv_line);
        cv_line := '----------  -----------------------  ---------  -----------------';
        Fnd_File.put_line (Fnd_File.output, cv_line);
         
        FOR rec_cur_batches IN cur_batches LOOP  
            
            -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
            BEGIN
              SELECT RECURRING_BATCH_ID INTO v_RECURRING_BATCH_ID
              FROM GL_RECURRING_BATCHES 
              WHERE NAME = rec_cur_batches.NOM_LOT 
                AND CHART_OF_ACCOUNTS_ID = 101 
                AND PERIOD_SET_NAME = 'GROUPE'
                AND ACCOUNTED_PERIOD_TYPE = 'Month';
                
              Fnd_File.put_line (Fnd_File.LOG, ' v_RECURRING_BATCH_ID : ' ||  v_RECURRING_BATCH_ID || ':'||rec_cur_batches.NOM_LOT);
              
              l_batchfound := TRUE;
              
              EXCEPTION WHEN NO_DATA_FOUND THEN
                l_batchfound := FALSE;
            END;

            IF NOT l_batchfound THEN
              
              --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'GENERATE RECURRING_BATCH_ID');
              -- Generer RECURRING_BATCH_ID
              SELECT GL_RECURRING_BATCHES_S.nextval
              INTO v_RECURRING_BATCH_ID
              FROM DUAL;
                
              --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Table GL_RECURRING_BATCHES '||rec_cur_batches.NOM_LOT||V_RECURRING_BATCH_ID);
              BEGIN
               -- GL_RECURRING_BATCHES
               INSERT INTO GL_RECURRING_BATCHES 
                          (  
                           RECURRING_BATCH_ID
                          ,NAME
                          ,LAST_UPDATE_DATE
                          ,LAST_UPDATED_BY
                          ,LEDGER_ID
                          ,BUDGET_FLAG
                          ,ALLOCATION_FLAG
                          ,CREATION_DATE
                          ,CREATED_BY
                          ,LAST_UPDATE_LOGIN
                          ,DESCRIPTION
                          ,SECURITY_FLAG
                          ,RECURRING_BATCH_TYPE
                          ,CHART_OF_ACCOUNTS_ID
                          ,PERIOD_SET_NAME
                          ,ACCOUNTED_PERIOD_TYPE
                          )
              VALUES
                          (
                           V_RECURRING_BATCH_ID                   --RECURRING_BATCH_ID
                          ,rec_cur_batches.NOM_LOT                --NAME
                          ,SYSDATE                                --LAST_UPDATE_DATE
                          ,g_user_id                              --LAST_UPDATED_BY
                          ,rec_cur_batches.livre_lot              --LEDGER_ID
                          ,'N'                                    --BUDGET_FLAG
                          ,'N'                                    --ALLOCATION_FLAG
                          ,SYSDATE                                --CREATION_DATE
                          ,g_user_id                              --CREATED_BY
                          ,g_login_id                             --LAST_UPDATE_LOGIN
                          ,rec_cur_batches.DESC_LOT               --DESCRIPTION
                          ,'N'                                    --SECURITY_FLAG
                          ,'S'                                    --RECURRING_BATCH_TYPE
                          ,101                                    --CHART_OF_ACCOUNTS_ID
                          ,'GROUPE'                               --PERIOD_SET_NAME
                          ,'Month'                                --ACCOUNTED_PERIOD_TYPE
                         );
                                    
              g_summary.inserted_batches_rows := g_summary.inserted_batches_rows + 1;
              
              EXCEPTION
                  WHEN DUP_VAL_ON_INDEX THEN 
                      v_message := 'Création impossible, le lot existe déja en base';
                      Add_Message(rec_cur_batches.NOM_LOT,'','',v_message);
                      p_retcode   := 1;

                      -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
                      UPDATE DKA_REP_PIECES_TMP
                        SET   STATUT        = 'E'
                             ,STATUT_LOT    = 'E'
                             ,STATUT_PIECE  = 'E'
                        WHERE nom_lot       = rec_cur_batches.NOM_LOT
                        ;
                      
                      continue;
                  WHEN OTHERS THEN
                      v_message := sqlerrm;
                      Add_Message(rec_cur_batches.NOM_LOT,'','',v_message);
                      p_retcode   := 1;
                      
                      UPDATE DKA_REP_PIECES_TMP
                        SET   STATUT        = 'E'
                             ,STATUT_LOT    = 'E'
                             ,STATUT_PIECE  = 'E'
                        WHERE nom_lot       = rec_cur_batches.NOM_LOT
                        ;
                      
                      continue;
              END;
            
            END IF;
            
            --GL_RECURRING_HEADERS
            FOR rec_cur_headers IN cur_headers(rec_cur_batches.NOM_LOT) LOOP
              -- Generer RECURRING_HEADER_ID
              SELECT GL_RECURRING_HEADERS_S.nextval
              INTO V_RECURRING_HEADER_ID
              FROM DUAL;
              
              --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Table GL_RECURRING_HEADERS '||'/'||rec_cur_batches.NOM_LOT||'/'||V_RECURRING_HEADER_ID||'/'||rec_cur_headers.NOM_PIECE);
              --GL_RECURRING_HEADERS              
              BEGIN
              INSERT INTO GL_RECURRING_HEADERS 
                    (RECURRING_HEADER_ID
                    ,LAST_UPDATE_DATE
                    ,LAST_UPDATED_BY
                    ,LEDGER_ID
                    ,NAME
                    ,JE_CATEGORY_NAME
                    ,ENABLED_FLAG
                    ,ALLOCATION_FLAG
                    ,CURRENCY_CODE
                    ,CREATION_DATE
                    ,CREATED_BY
                    ,LAST_UPDATE_LOGIN
                    ,RECURRING_BATCH_ID
                    ,START_DATE_ACTIVE
                    ,END_DATE_ACTIVE
                    ,ATTRIBUTE1
                    ,CONTEXT
                      )
                VALUES
                      (
                         V_RECURRING_HEADER_ID          --RECURRING_HEADER_ID
                        ,SYSDATE                        --LAST_UPDATE_DATE
                        ,g_user_id                      --LAST_UPDATED_BY
                        ,rec_cur_headers.LIVRE_PIECE    --LEDGER_ID
                        ,rec_cur_headers.NOM_PIECE      --NAME
                        ,rec_cur_headers.JE_CATEGORY_NAME --JE_CATEGORY_NAME
                        ,'Y'                            --ENABLED_FLAG
                        ,'N'                            --ALLOCATION_FLAG
                        ,rec_cur_headers.devise         --CURRENCY_CODE
                        ,SYSDATE                        --CREATION_DATE
                        ,g_user_id                      --CREATED_BY
                        ,g_login_id                     --LAST_UPDATE_LOGIN
                        ,v_RECURRING_BATCH_ID           --RECURRING_BATCH_ID
                        ,rec_cur_headers.DEBUT_PIECE    --START_DATE_ACTIVE
                        ,rec_cur_headers.FIN_PIECE      --END_DATE_ACTIVE
                        ,rec_cur_headers.CUF_PIECE      --ATTRIBUTE1
                        ,rec_cur_headers.JE_CATEGORY_NAME   --CONTEXT
                      );
            g_summary.inserted_headers_rows := g_summary.inserted_headers_rows + 1;
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN 
                    v_message := 'Création impossible, la pièce existe déja en base';
                    Add_Message(rec_cur_batches.NOM_LOT,rec_cur_headers.NOM_PIECE,'',v_message);
                    p_retcode   := 1;
                    
                    -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
                    UPDATE DKA_REP_PIECES_TMP
                        SET   STATUT        = 'E'
                             ,STATUT_PIECE  = 'E'
                        WHERE nom_lot       = rec_cur_batches.NOM_LOT
                        AND   nom_piece     = rec_cur_headers.NOM_PIECE
                        ;
                    
                    continue;
                WHEN OTHERS THEN
                    v_message := sqlerrm;
                    Add_Message(rec_cur_batches.NOM_LOT,rec_cur_headers.NOM_PIECE,'',v_message);
                    p_retcode   := 1;
                    
                    -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
                    UPDATE DKA_REP_PIECES_TMP
                        SET   STATUT        = 'E'
                             ,STATUT_PIECE  = 'E'
                        WHERE nom_lot       = rec_cur_batches.NOM_LOT
                        AND   nom_piece     = rec_cur_headers.NOM_PIECE
                        ;
                    
                    continue;
            END;
  
            -- GL_RECURRING_LINES
            FOR rec_cur_lines IN cur_lines(rec_cur_headers.nom_lot,rec_cur_headers.nom_piece) LOOP
                -- GL_RECURRING_LINES
                --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Table GL_RECURRING_LINES');
              BEGIN
                INSERT INTO GL_RECURRING_LINES
                (
                     RECURRING_HEADER_ID
                    ,RECURRING_LINE_NUM
                    ,LAST_UPDATE_DATE
                    ,LAST_UPDATED_BY
                    ,CODE_COMBINATION_ID
                    ,CREATION_DATE
                    ,CREATED_BY
                    ,LAST_UPDATE_LOGIN
                    ,DESCRIPTION
                    ,ATTRIBUTE1
                    ,ATTRIBUTE2
                    ,ATTRIBUTE3
                    ,ATTRIBUTE4
                    ,CONTEXT
                  )
                VALUES
                  (
                     V_RECURRING_HEADER_ID              --RECURRING_HEADER_ID
                    ,rec_cur_lines.NUM_LIGNE            --RECURRING_LINE_NUM
                    ,SYSDATE                            --LAST_UPDATE_DATE
                    ,g_user_id                          --LAST_UPDATED_BY
                    ,rec_cur_lines.CLE_NEW_ID           --CODE_COMBINATION_ID
                    ,SYSDATE                            --CREATION_DATE
                    ,g_user_id                          --CREATED_BY
                    ,g_login_id                         --LAST_UPDATE_LOGIN
                    ,rec_cur_lines.DESC_LIGNE           --DESCRIPTION
                    ,rec_cur_lines.PROJET_NEW           --ATTRIBUTE1
                    ,rec_cur_lines.TACHE_NEW            --ATTRIBUTE2
                    ,rec_cur_lines.TYPE_EVT_NEW         --ATTRIBUTE3
                    ,rec_cur_lines.TYPE_DPSE_NEW        --ATTRIBUTE4
                    ,rec_cur_lines.CONTEXTE             --CONTEXT
                  );
                  
                  g_summary.inserted_lines_rows := g_summary.inserted_lines_rows + 1;
                EXCEPTION
                    WHEN DUP_VAL_ON_INDEX THEN 
                        v_message := 'Création impossible, la ligne existe déja en base';
                        Add_Message(rec_cur_batches.NOM_LOT,rec_cur_headers.NOM_PIECE,rec_cur_lines.NUM_LIGNE,v_message);
                        p_retcode   := 1;
                        
                        -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
                        UPDATE DKA_REP_PIECES_TMP
                        SET   STATUT        = 'E'
                             ,STATUT_LOT    = 'E'
                             ,STATUT_PIECE  = 'E'
                        WHERE nom_lot       = rec_cur_lines.nom_lot
                        AND   nom_piece     = rec_cur_lines.nom_piece
                        AND   num_ligne     = rec_cur_lines.num_ligne
                        ;
                    
                        continue;
                    WHEN OTHERS THEN
                        v_message := sqlerrm;
                        Add_Message(rec_cur_batches.NOM_LOT,rec_cur_headers.NOM_PIECE,rec_cur_lines.NUM_LIGNE,v_message);
                        p_retcode   := 1;
                        
                        -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
                        UPDATE DKA_REP_PIECES_TMP
                        SET   STATUT        = 'E'
                             ,STATUT_LOT    = 'E'
                             ,STATUT_PIECE  = 'E'
                        WHERE nom_lot       = rec_cur_lines.nom_lot
                        AND   nom_piece     = rec_cur_lines.nom_piece
                        AND   num_ligne     = rec_cur_lines.num_ligne
                        ;
                        continue;
                END;
              FOR rec_cur_rules IN cur_rules(rec_cur_headers.nom_lot,rec_cur_headers.nom_piece,rec_cur_lines.num_ligne) LOOP
                -- GL_RECURRING_LINE_CALC_RULES
                --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Table GL_RECURRING_LINE_CALC_RULES');
               BEGIN
                INSERT INTO GL_RECURRING_LINE_CALC_RULES
                (
                     RECURRING_HEADER_ID
                    ,RECURRING_LINE_NUM
                    ,RULE_NUM
                    ,LAST_UPDATE_DATE
                    ,LAST_UPDATED_BY
                    ,OPERATOR
                    ,CREATION_DATE
                    ,CREATED_BY
                    ,LAST_UPDATE_LOGIN
                    ,AMOUNT
                  )
                VALUES
                  (
                     V_RECURRING_HEADER_ID          --RECURRING_HEADER_ID
                    ,rec_cur_lines.NUM_LIGNE        --RECURRING_LINE_NUM
                    ,rec_cur_rules.NUM_LIG_FORM     --RULE_NUM
                    ,SYSDATE                        --LAST_UPDATE_DATE
                    ,g_user_id                      --LAST_UPDATED_BY
                    ,rec_cur_rules.OPER_FORM        --OPERATOR
                    ,SYSDATE                        --CREATION_DATE
                    ,g_user_id                      --CREATED_BY
                    ,g_login_id                     --LAST_UPDATE_LOGIN
                    ,rec_cur_rules.MONTANT_FORM     --AMOUNT
                    );
                  
                  g_summary.inserted_rules_rows := g_summary.inserted_rules_rows + 1;        

                    UPDATE DKA_REP_PIECES_TMP
                    SET   STATUT        = 'T'
                         ,STATUT_LOT    = 'T'
                    -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
                         ,STATUT_PIECE  = 'T'
                    WHERE nom_lot       = rec_cur_lines.nom_lot
                    AND   nom_piece     = rec_cur_lines.nom_piece
                    AND   num_ligne     = rec_cur_lines.num_ligne
                    AND   NUM_LIG_FORM  = rec_cur_rules.NUM_LIG_FORM
                    ;
                  EXCEPTION
                    WHEN DUP_VAL_ON_INDEX THEN 
                        v_message := 'Création impossible, la règle existe déja en base';
                        Add_Message(rec_cur_batches.NOM_LOT,rec_cur_headers.NOM_PIECE,rec_cur_lines.NUM_LIGNE,v_message);
                        p_retcode   := 1;
                        continue;
                    WHEN OTHERS THEN
                        v_message := sqlerrm;
                        Add_Message(rec_cur_batches.NOM_LOT,rec_cur_headers.NOM_PIECE,rec_cur_lines.NUM_LIGNE,v_message);
                        p_retcode   := 1;
                        continue;
                  END;
                END LOOP;  -- Fin cur_rules
              
              END LOOP; -- Fin cur_lines
            
            END LOOP; --Fin cur_headers
           
        END LOOP; --Fin cur_batches

        COMMIT;
        
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin import_data');    
  
  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'import_data : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure import_data : EXCEPTION OTHERS ');
  END import_data;  
 
 /*
 *************************************************************************
 * PROCEDURE NAME : Bilan
 * 
 * DESCRIPTION
 *  Procédure de génération du bilan du traitement d'interface
 *
 * PARAMETERS
 * ==========
 * NAME                 DESCRIPTION
.* -------------------- ---------------------------------------------------
 * p_errbuf            Retour de message éventuel
 * p_retcode           Statut du traitement en sortie
 ************************************************************************
 */
  PROCEDURE Report_Bilan(p_Errbuf            OUT VARCHAR2,
                         p_retcode           OUT NUMBER
                         ) 
  IS
 
  BEGIN
  
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Report_Bilan');

        --------------------    
        -- Initialisation --
        --------------------          
        p_Errbuf  := NULL;
        p_retcode := 0;

        SELECT count(1)
        INTO g_summary.rejected_rows
        FROM DKA_REP_PIECES_TMP
        WHERE statut = 'E' 
        ;

        SELECT count(1)
        INTO g_summary.no_imported_rows
        FROM DKA_REP_PIECES_TMP
        WHERE statut = 'S' 
        ;
        
        fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT,'BILAN :');
        fnd_file.put_line(fnd_file.OUTPUT,'-------');
        
        fnd_file.put_line(fnd_file.OUTPUT,'  . Nombre de lignes chargées dans la table spécifique                           : ' || TO_CHAR(g_summary.loaded_rows)||CHR(10));

        fnd_file.put_line(fnd_file.OUTPUT,'  . Nombre de lignes en rejet dans la table spécifique                           : ' || TO_CHAR(g_summary.rejected_rows)||CHR(10));
        
        fnd_file.put_line(fnd_file.OUTPUT,'  . Nombre de lignes validées mais non importées                                 : ' || TO_CHAR(g_summary.no_imported_rows)||CHR(10));

        fnd_file.put_line(fnd_file.OUTPUT,'  . Nombre d''enregistrements chargés dans la table GL_RECURRING_BATCHES          : ' || TO_CHAR(g_summary.inserted_batches_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'  . Nombre d''enregistrements chargés dans la table GL_RECURRING_HEADERS          : ' || TO_CHAR(g_summary.inserted_headers_rows)); 
        fnd_file.put_line(fnd_file.OUTPUT,'  . Nombre d''enregistrements chargés dans la table GL_RECURRING_LINES            : ' || TO_CHAR(g_summary.inserted_lines_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'  . Nombre d''enregistrements chargés dans la table GL_RECURRING_LINE_CALC_RULES  : ' || TO_CHAR(g_summary.inserted_rules_rows));

        fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Report_Bilan');  

  
  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'REPORT_BILAN : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
  END Report_Bilan; 

/**************************************************************************
 * PROCEDURE NAME : set_recovery_mode
 *
 * DESCRIPTION
 *  Procédure d'initialisation du mode reprise (Pas de fichier en entrée)
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
 * -----------------  ------------------------------------------------------
 *
 *************************************************************************/
  PROCEDURE set_recovery_mode(p_Errbuf            OUT VARCHAR2,
                              p_retcode           OUT NUMBER
                              ) 
  IS

  BEGIN

    --RESET g_loader_request_id
    g_loader_request_id := -1;
    
    UPDATE DKA_REP_PIECES_TMP
    -- 06/12/2017     NBO artf2280442 - REP017 - Reprise des pièces répétitives - Erreur sur les lignes de produit
    SET  STATUT       = '-1',
         STATUT_PIECE = '-1',
         STATUT_LOT   = '-1'
    WHERE STATUT = 'E';

  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'SET_RECOVERY_MODE : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure SET_RECOVERY_MODE : EXCEPTION OTHERS ');
  END set_recovery_mode;


/**************************************************************************
 * PROCEDURE NAME : purge_data
 *
 * DESCRIPTION
 *  Procédure de purge des données
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
 * -----------------  ------------------------------------------------------
 *
 *************************************************************************/
  PROCEDURE purge_data(p_Errbuf            OUT VARCHAR2,
                       p_retcode           OUT NUMBER
                              ) 
  IS

  BEGIN


     Fnd_File.Put_Line(Fnd_File.LOG, '-> DKA_REP_PIECES_TMP' );

     -- On supprime les enregistrements

     DELETE FROM DKA_REP_PIECES_TMP;

     g_summary.purged_rows := SQL%ROWCOUNT;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows '||TO_CHAR(g_summary.purged_rows));

  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'PURGE_DATA : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure PURGE_DATA : EXCEPTION OTHERS ');
  END purge_data;
 /*
 *************************************************************************
 * PROCEDURE NAME : main
 * 
 * DESCRIPTION
 *  Procédure principale
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 ************************************************************************
 */

  PROCEDURE main(p_errbuf       IN   OUT VARCHAR2,
                 p_retcode           OUT NUMBER,
                 p_load_file    IN       VARCHAR2,
                 p_insert_oa    IN       VARCHAR2
                 )
  IS
  
    v_current_program_unit     VARCHAR2(30);
    v_errbuf                   VARCHAR2(2500);
    v_retcode                  NUMBER;
    Erreur_Programme           EXCEPTION;
    v_warning                  BOOLEAN := FALSE;
 
  BEGIN
      
      ----------------------------
      -- PHASE D'INITIALISATION --
      ----------------------------
      
      v_current_program_unit := 'main';
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'DEBUT DE L''INTERFACE'); 
      
      
      Output_Header;
      Request_parameters;
      
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE D''INITIALISATION'); 
      
      v_errbuf  := NULL;
      v_retcode := 0;
      
      Init(v_errbuf, v_retcode, p_load_file, p_insert_oa);
      
      IF v_retcode = 2 
      THEN
          p_Errbuf  := v_errbuf;
          p_retcode := v_retcode;
          RAISE Erreur_Programme;
      END IF;       

      IF g_summary.load_file = 'Y' THEN
        -------------------------------------------
        -- PHASE DE PURGE DES ANCIENNES DONNEES  --
        -------------------------------------------
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PURGE DES DONNEES'); 
        purge_data(v_errbuf,
                      v_retcode
                     );
        IF v_retcode = 2 
        THEN
            p_Errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RAISE Erreur_Programme;
        END IF; 
  
        ------------------------------------
        -- PHASE DE CHARGEMENT DU FICHIER --
        ------------------------------------ 
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE DE CHARGEMENT DU FICHIER'); 
      
      
        -- Lancement du programme de chargement
        Launch_Loader(v_errbuf,
                      v_retcode
                     );
        IF v_retcode = 2 
          THEN
          RAISE Erreur_Programme;
        END IF;
      
      ELSE
        set_recovery_mode(v_errbuf,
                          v_retcode
                          );
      END IF;

      -- Lancement de validation des données
      validate_data(v_errbuf,
                   v_retcode
                   );
      IF v_retcode = 2 
      THEN
          RAISE Erreur_Programme;
      ELSIF v_retcode = 1 THEN
        v_warning := TRUE;
      END IF;
      
      IF g_summary.insert_oa = 'Y' THEN
          -- Lancement de l'insertion des données
          import_data(v_errbuf,
                       v_retcode
                       );
          IF v_retcode = 2 
          THEN
              RAISE Erreur_Programme;
          END IF;
      END IF;

      -- bilan
      Report_Bilan(p_Errbuf,
                   p_retcode
                 ); 
                 
      ---------------------------------------
      -- PHASE DE FIN DU TRAITEMENT MAITRE --
      ---------------------------------------
      IF p_retcode = 2
      THEN
         p_errbuf := 'ATTENTION : Erreur bloquante : '||p_errbuf;
      ELSIF (g_summary.rejected_rows > 0 OR g_summary.no_imported_rows > 0 )
      THEN
         p_errbuf := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
         p_retcode := 1;
      ELSIF (g_summary.loaded_rows = 0 AND g_summary.load_file = 'Y')
      THEN
         p_errbuf := 'ATTENTION : Aucun enregistrement chargé.';
         p_retcode := 1;
      ELSE 
         p_errbuf := 'Fin normale du traitement - Aucun rejet.';
         p_retcode := 0;
      END IF;
      
      COMMIT;
      
      
      Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf||CHR(10));
      output_end;
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'FIN DE L''INTERFACE');       


  EXCEPTION
        WHEN Erreur_Programme
        THEN
            p_retcode   := 2;
            p_errbuf    := v_errbuf;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');        
            Fnd_File.put_line (Fnd_File.OUTPUT, '==> Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');        
       WHEN OTHERS 
       THEN
           fnd_concurrent.af_rollback;
           p_retcode := 2;
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_REPGLPIECEREPIMP_PKG.' || v_current_program_unit||CHR(10)||'A retourné     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           p_errbuf := SQLERRM;
  END main; 
 

END DKA_REPGLPIECEREPIMP_PKG;
/
SHOW ERRORS
EXIT
