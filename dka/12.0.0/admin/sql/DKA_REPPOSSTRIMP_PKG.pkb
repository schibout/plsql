SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE BODY DKA_REPPOSSTRIMP_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_REPPOSSTRIMP_PKG.pkb  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    Création du package de l'interface specifique d'import des contrats SSTR
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
-- 28/03/2016     RBE Creation
-- 18/08/2017     RBE Correctif artf2212570 : Ajout LATEST_EXTERNAL_FLAG
---------------------------------------------------------------------------------------------

 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    TYPE summary_typ IS RECORD 
    (
     loaded_header_rows               NUMBER      -- Nb des en-entêtes chargées en table specifique
    ,loaded_detail_rows               NUMBER      -- Nb des détails chargés en table specifique
    ,loaded_imput_rows                NUMBER      -- Nb des imputations chargées en table specifique
    ,rejected_header_rows             NUMBER      -- Nb de Lignes en-entêtes rejectées
    ,rejected_detail_rows             NUMBER      -- Nb de Lignes détail rejectés
    ,rejected_imput_rows              NUMBER      -- Nb de Lignes imputation rejectées
    ,inserted_header_rows             NUMBER      -- Nb de Lignes en-entêtes insérées
    ,inserted_detail_rows             NUMBER      -- Nb de Lignes detail insérés
    ,inserted_imput_rows              NUMBER      -- Nb de Lignes d'imputations insérées
    ,loaded_header_hist_rows          NUMBER      -- Nb des en-entêtes chargées en table specifique
    ,loaded_detail_hist_rows          NUMBER      -- Nb des détails chargés en table specifique
    ,loaded_imput_hist_rows           NUMBER      -- Nb des imputations chargées en table specifique
    ,rejected_header_hist_rows        NUMBER      -- Nb de Lignes en-entêtes rejectées
    ,rejected_detail_hist_rows        NUMBER      -- Nb de Lignes détail rejectés
    ,rejected_imput_hist_rows         NUMBER      -- Nb de Lignes imputation rejectées
    ,inserted_header_hist_rows        NUMBER      -- Nb de Lignes en-entêtes insérées
    ,inserted_detail_hist_rows        NUMBER      -- Nb de Lignes detail insérés
    ,inserted_imput_hist_rows         NUMBER      -- Nb de Lignes d'imputations insérées
    ,purged_header_rows               NUMBER      -- Nb de Lignes purgées en table spécifique   
    ,purged_detail_rows               NUMBER      -- Nb de Lignes purgées en table spécifique 
    ,purged_imput_rows                NUMBER      -- Nb de Lignes purgées en table spécifique 
    ,message_flag                     NUMBER      -- Flag d'entete etat des erreurs
    ,reprise_flag                     VARCHAR2(1) -- Flag reprise
    )
    ;

    g_summary                      summary_typ;

    g_user_id                      fnd_user.user_id%TYPE;
    g_login_id                     fnd_logins.login_id%TYPE;
    g_org_id                       hr_all_organization_units.organization_id%TYPE;
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
        p_errbuf    OUT      VARCHAR2,
        p_retcode   OUT      NUMBER,
        p_reprise   IN       VARCHAR2
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
        g_org_id                       := fnd_profile.value ('ORG_ID');
        g_tempo                        := 20;

        -- Variables globales de comptage

        g_summary.loaded_header_rows             := 0;
        g_summary.loaded_detail_rows             := 0;
        g_summary.loaded_imput_rows              := 0;
        g_summary.rejected_header_rows           := 0;
        g_summary.rejected_detail_rows           := 0;
        g_summary.rejected_imput_rows            := 0;
        g_summary.inserted_header_rows           := 0;
        g_summary.inserted_detail_rows           := 0;
        g_summary.inserted_imput_rows            := 0;
        g_summary.loaded_header_hist_rows        := 0;
        g_summary.loaded_detail_hist_rows        := 0;
        g_summary.loaded_imput_hist_rows         := 0;
        g_summary.rejected_header_hist_rows      := 0;
        g_summary.rejected_detail_hist_rows      := 0;
        g_summary.rejected_imput_hist_rows       := 0;
        g_summary.inserted_header_hist_rows      := 0;
        g_summary.inserted_detail_hist_rows      := 0;
        g_summary.inserted_imput_hist_rows       := 0;
        g_summary.purged_header_rows             := 0;
        g_summary.purged_detail_rows             := 0;
        g_summary.purged_imput_rows              := 0;
        g_summary.message_flag                   := 0;
        g_summary.reprise_flag                   := NVL(p_reprise,'N');

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

  PROCEDURE Add_Message  (p_document_num      IN  VARCHAR2,
                          p_type              IN  VARCHAR2,
                          p_line_num          IN  VARCHAR2,
                          p_message_text      IN  VARCHAR2
                          ) 
  IS
        cv_line                     VARCHAR2 (500);
  BEGIN

    IF  g_summary.message_flag = 0 THEN
      cv_line := 'Etat des erreurs :';
      Fnd_File.put_line (Fnd_File.output, CHR(10)||cv_line);
      cv_line := '-----------------';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := 'Numéro de document  Type   Id de la ligne de contrat  Message d''erreur';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := '------------------  ------ -------------------------  ---------------';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      g_summary.message_flag := 1;
    END IF;
    
    cv_line := RPAD(p_document_num,18,' ') ||'  '|| RPAD(NVL(p_type,' '),6,' ') || ' ' ||RPAD(NVL(p_line_num,' '),25,' ') ||'  ' || p_message_text ;

    Fnd_File.put_line (Fnd_File.output, cv_line);

  END Add_Message;
   
/*
*************************************************************************
 * FUNCTION NAME : get_organization_id
 *
 * DESCRIPTION
 *  Fonction pour récupérer le party_id du fournisseur
 *
 * PARAMETERS
 * ==========
 * NAME                    DESCRIPTION
 * ----------------------- -------------------------------------------------
 * p_vendor_name           Nom du fournisseur
 *
 * RETURN
 * ======
 * party_id   
 *
 ************************************************************************
 */

 FUNCTION get_organization_id (
                                 p_societe        IN VARCHAR2
                                ,p_region         IN VARCHAR2
                              )          
  RETURN NUMBER
  IS
    v_organization_id NUMBER;
   
  BEGIN  
 
     -- Recherche  de l'org_id          
     BEGIN
        SELECT hr.ORGANIZATION_ID
        INTO   v_organization_id
        FROM   hr_operating_units hr
        WHERE  hr.NAME = p_region||p_societe
        ;
     EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
         v_organization_id := -1;
     END;

     ----- return value -----
     RETURN (v_organization_id);  
  
END get_organization_id;  
   
/*
*************************************************************************
 * FUNCTION NAME : get_segment_categ
 *
 * DESCRIPTION
 *  Fonction pour récupérer les segments de catégorie achat
 *
 * PARAMETERS
 * ==========
 * NAME                    DESCRIPTION
 * ----------------------- -------------------------------------------------
 * p_chaine                la chaine
 * p_position              Position du segment
 *
 * RETURN
 * ======
 * v_segment   
 *
 ************************************************************************
 */

 FUNCTION get_segment_categ (
                                 p_chaine        IN VARCHAR2
                                ,p_position      IN VARCHAR2
                              )          
  RETURN VARCHAR2
  IS
    v_segment VARCHAR2(100);
   
  BEGIN  

  SELECT token 
  INTO v_segment
  FROM (
      SELECT trim( substr (txt,
              instr (txt, '.', 1, level  ) + 1,
              instr (txt, '.', 1, level+1)
                 - instr (txt, '.', 1, level) -1 ) )
          AS token, rownum num
        FROM (SELECT '.'||p_chaine||'.' txt
               FROM dual)
      connect BY level <=
         length(p_chaine)-length(REPLACE(p_chaine,'.',''))+1
         )
  WHERE num = p_position;

  RETURN v_segment;
  
  EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
  
END get_segment_categ;

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
                                                                  ,'DKA_LOADER_REPPOSSTRIMP'        -- PROG
                                                                  ,NULL                             -- PROGRAM_NAME
                                                                  ,NULL                             -- START
                                                                  ,FALSE                            -- SUB_REQUEST
                                                                  );
 
        IF g_loader_request_id = 0
        THEN
            p_retcode    := 2;
            fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de chargement du fichier a échoué' || CHR(10) ||
                                            'PROGRAMME  : DKA_LOADER_REPPOSSTRIMP'
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
                INTO g_summary.loaded_header_rows
                FROM DKA_CONTRAT_SSTR_HEADER_TMP
                WHERE DATA_TYPE = 'ACTUEL' 
                ;

                SELECT count(1)
                INTO g_summary.loaded_detail_rows
                FROM DKA_CONTRAT_SSTR_DETAIL_TMP 
                WHERE DATA_TYPE = 'ACTUEL' 
                ;
                
                SELECT count(1)
                INTO g_summary.loaded_imput_rows
                FROM DKA_CONTRAT_SSTR_IMPUT_TMP 
                WHERE DATA_TYPE = 'ACTUEL' 
                ;

                SELECT count(1)
                INTO g_summary.loaded_header_hist_rows
                FROM DKA_CONTRAT_SSTR_HEADER_TMP
                WHERE DATA_TYPE = 'HISTO' 
                ;
        
                SELECT count(1)
                INTO g_summary.loaded_detail_hist_rows
                FROM DKA_CONTRAT_SSTR_DETAIL_TMP  
                WHERE DATA_TYPE = 'HISTO' 
                ;
                
                SELECT count(1)
                INTO g_summary.loaded_imput_hist_rows
                FROM DKA_CONTRAT_SSTR_IMPUT_TMP 
                WHERE DATA_TYPE = 'HISTO' 
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
  PROCEDURE validate_data(  p_Errbuf            OUT VARCHAR2,
                            p_retcode           OUT NUMBER
                          ) 
  IS
    v_message                 VARCHAR2 (500);

    v_AGENT_ID                NUMBER;
    V_VENDOR_ID               NUMBER;
    V_VENDOR_SITE_ID          NUMBER;
    v_ship_TO_LOCATION_ID     NUMBER;
    v_BILL_TO_LOCATION_ID     NUMBER;
    v_TERM_ID                 NUMBER;
    v_STYLE_ID                NUMBER;
    v_CONTRAT_IMPUTATION_ID   NUMBER;
    v_CODE_COMBINATION_ID     NUMBER;

    v_org_id                  NUMBER;
    V_COUNT_PO_HEADERS        NUMBER := 0;
    v_commande_id             NUMBER;
    v_cadre_po_header_id      NUMBER;
    v_person_id               NUMBER;
    v_project_id              NUMBER;
    v_task_id                 NUMBER;
    v_location_id             NUMBER;
    
    v_project_code            VARCHAR2(150);
    v_task                    VARCHAR2(150);
    v_ccf                                 VARCHAR2(500);

    v_ATTRIBUTE5              VARCHAR2(240);
    v_attribute5_1            VARCHAR2(150);
    v_attribute5_2            VARCHAR2(150);
    v_attribute5_3            VARCHAR2(150);
    v_attribute5_4            VARCHAR2(150);
                                                    
    v_flag_erreur             BOOLEAN := FALSE;
    v_flag_erreur_detail      BOOLEAN := FALSE;
    v_flag_erreur_imput       BOOLEAN := FALSE;
    v_flag_erreur_histo       BOOLEAN := FALSE;
    
    v_flag_warning            BOOLEAN := FALSE;
    v_agent_name              VARCHAR2(150);
    
    CURSOR cur_header IS
      SELECT *
      FROM DKA_CONTRAT_SSTR_HEADER_TMP
      WHERE DATA_TYPE = 'ACTUEL'
      AND  load_request_id = DECODE( g_loader_request_id
                                       , -1, load_request_id
                                       , g_loader_request_id)
      AND  statut = '-1'              
    ; 
      
    CURSOR cur_header_histo(p_doc_num VARCHAR2) IS
      SELECT *
      FROM DKA_CONTRAT_SSTR_HEADER_TMP
      WHERE document_num = p_doc_num
      AND DATA_TYPE = 'HISTO'
      FOR UPDATE OF
           org_id              
          ,AGENT_ID            
          ,VENDOR_SITE_ID      
          ,VENDOR_ID           
          ,SHIP_TO_LOCATION_ID 
          ,BILL_TO_LOCATION_ID 
          ,TERM_ID             
          ,STYLE_ID            
          ,ATTRIBUTE5_TRANSCO  
          ,STATUT              
    ;

    CURSOR cur_detail (p_doc_num VARCHAR2)IS
      SELECT *
      FROM DKA_CONTRAT_SSTR_DETAIL_TMP
      WHERE document_num = p_doc_num
      FOR UPDATE OF
               CADRE_PO_HEADER_ID
              ,COMMANDE_ID       
              ,PERSON_ID         
              ,STATUT   
      
    ;
    CURSOR cur_imput (p_doc_num VARCHAR2) IS
      SELECT *
      FROM DKA_CONTRAT_SSTR_IMPUT_TMP
      WHERE document_num = p_doc_num
      FOR UPDATE OF
               project_id 
              ,task_id
              ,LOCATION_ID 
              ,STATUT      

    ;
    
  BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_data');    
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 
                                         'Validation des données dans les tables spécifiques : ');

        -- Récuperer style
        --->>
        --->>
            BEGIN
              SELECT STYLE_ID 
              INTO v_STYLE_ID
              FROM PO_DOC_STYLE_HEADERS
              WHERE STYLE_TYPE = 'STANDARD'
              ;
            EXCEPTION
            WHEN OTHERS THEN
              v_STYLE_ID := NULL;
              v_message := 'Erreur de récupération du STYLE ID';
              Add_Message('TOUT',NULL,NULL,v_message);
              p_retcode   := 2;
              RETURN;
            END;
        ---<<
        ---<<
        FOR rec_cur_header IN cur_header LOOP
            v_flag_erreur := FALSE;
            
            -- Récuperer l'agent
            --->>
            --->>
              BEGIN
                SELECT ppf.person_id
                INTO v_agent_id
                FROM per_people_f ppf
                WHERE ppf.full_name = rec_cur_header.AGENT_NAME
                AND sysdate BETWEEN NVL(ppf.effective_start_date,sysdate) AND NVL(ppf.effective_end_date,sysdate)
                AND CURRENT_EMPLOYEE_FLAG = 'Y';
                 
                v_agent_name := rec_cur_header.AGENT_NAME;
              
              EXCEPTION
                WHEN OTHERS THEN 
                  v_agent_id := NULL;
                  v_agent_name := 'REPRISE, REPRISE';
                  v_message := 'Avertissement : L''employé '||rec_cur_header.AGENT_NAME||' n''existe pas, remplacement par REPRISE';
                  Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_header.DATA_TYPE,NULL,v_message);
                  v_flag_warning := TRUE;
              END;
               
              BEGIN
                SELECT AGENT_ID 
                INTO v_AGENT_ID
                FROM PO_AGENTS_V
                WHERE AGENT_NAME = v_agent_name
                AND sysdate BETWEEN NVL(start_date_active,sysdate) AND NVL(end_date_active,sysdate)
                ;
              EXCEPTION
              WHEN OTHERS THEN
                v_agent_id := NULL;
                --v_message := 'Erreur de récupération du ID Agent pour AGENT_NAME = '||rec_cur_header.AGENT_NAME;
                v_message :=  'L''employé '||v_agent_name||' n''est pas défini comme acheteur';
                Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_header.DATA_TYPE,NULL,v_message);
                v_flag_erreur := TRUE;
              END;
            ---<<
            ---<<
          
            
            -- Récupération de l'org id
            --->>
            --->>
            
                dka_rep_transco_pkg.get_transco ( pv_transco_name => '008_REGIONS',
                                                     pv_column_01 => rec_cur_header.region,
                                                     pv_out_01    => rec_cur_header.region
                                                );
                                                
                v_org_id := get_organization_id(rec_cur_header.societe,rec_cur_header.region);
                
                IF v_org_id = -1 THEN
                  v_org_id := NULL;
                  v_message := 'Erreur de récuperation de ORG_ID pour le nom : '||rec_cur_header.region||','||rec_cur_header.societe;
                  Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_header.DATA_TYPE,NULL,v_message);
                  v_flag_erreur := TRUE;
                END IF;
            ---<<
            ---<<
            
            -- Récupération du fournisseur et site
            --->>
            --->>
                BEGIN
                  SELECT ASA.VENDOR_ID,ASSA.VENDOR_SITE_ID
                  INTO V_VENDOR_ID,V_VENDOR_SITE_ID
                  FROM Po_Vendors ASA,
                       Po_Vendor_SITES_ALL ASSA
                  WHERE ASSA.VENDOR_SITE_CODE like SUBSTR(rec_cur_header.VENDOR_SITE_CODE,5)||'%'
                  AND ASA.VENDOR_NAME  = rec_cur_header.VENDOR_NAME
                  AND ASA.vendor_id    = ASSA.vendor_id
                  AND ASSA.org_id = v_org_id
                  AND assa.purchasing_site_flag = 'Y'
                  AND ROWNUM = 1
                  ;
                EXCEPTION
                WHEN OTHERS THEN
                  V_VENDOR_ID := NULL;
                  V_VENDOR_SITE_ID := NULL;
                  v_message := 'Erreur de récuperation du fournisseur et site fournisseur ' ||rec_cur_header.VENDOR_NAME||'/'||SUBSTR(rec_cur_header.VENDOR_SITE_CODE,5)||', '||SQLERRM;
                  Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_header.DATA_TYPE,NULL,v_message);
                  v_flag_erreur := TRUE;
                END;
            ---<<
            ---<<
            
            -- Lieu de livraison
            --->>
            --->>
                BEGIN
                  SELECT LOCATION_ID 
                  INTO v_SHIP_TO_LOCATION_ID
                  FROM HR_LOCATIONS
                  WHERE location_code = rec_cur_header.SHIP_TO_LOCATION
                  ;
                EXCEPTION
                WHEN OTHERS THEN
                  v_SHIP_TO_LOCATION_ID := NULL;
                  v_message := 'Erreur de récuperation du lieu de livraison : '||rec_cur_header.SHIP_TO_LOCATION;
                  Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_header.DATA_TYPE,NULL,v_message);
                  v_flag_erreur := TRUE;
                END;
            ---<<
            ---<<
            
            -- Lieu de facturation
            --->>
            --->>
                BEGIN
                  SELECT LOCATION_ID 
                  INTO v_BILL_TO_LOCATION_ID
                  FROM HR_LOCATIONS
                  WHERE location_code = rec_cur_header.BILL_TO_LOCATION
                  ;
                EXCEPTION
                WHEN OTHERS THEN
                  v_BILL_TO_LOCATION_ID := NULL;
                  v_message := 'Erreur de récuperation du lieu de facturation '||rec_cur_header.BILL_TO_LOCATION;
                  Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_header.DATA_TYPE,NULL,v_message);
                  v_flag_erreur := TRUE;
                END;
            ---<<
            ---<<
            
            -- Terms
            --->>
            --->>
            IF rec_cur_header.PAYMENT_TERMS IS NOT NULL THEN
                BEGIN
                  SELECT TERM_ID 
                  INTO v_TERM_ID
                  FROM AP_TERMS
                  WHERE NAME = rec_cur_header.PAYMENT_TERMS
                  ;
                EXCEPTION
                WHEN OTHERS THEN
                  v_TERM_ID := NULL;
                  v_message := 'Erreur de récuperation du Terms Id pour NAME = '|| rec_cur_header.PAYMENT_TERMS;
                  Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_header.DATA_TYPE,NULL,v_message);
                  v_flag_erreur := TRUE;
                END;
            ELSE
              v_TERM_ID := NULL;
            END IF;
            
            ---<<
            ---<<
            
            -- Transco de ATTRIBUTE5
            --->>
            --->>              
              dka_rep_transco_pkg.get_transco (  pv_transco_name => '013_CATEGORIES_ACHATS',
                                                 pv_column_01 => get_segment_categ(rec_cur_header.ATTRIBUTE5,1),
                                                 pv_column_02 => get_segment_categ(rec_cur_header.ATTRIBUTE5,2),
                                                 pv_column_03 => get_segment_categ(rec_cur_header.ATTRIBUTE5,3),
                                                 pv_column_04 => get_segment_categ(rec_cur_header.ATTRIBUTE5,4),
                                                 pv_out_01    => v_attribute5_1,
                                                 pv_out_02    => v_attribute5_2,
                                                 pv_out_03    => v_attribute5_3,
                                                 pv_out_04    => v_attribute5_4
                                              );
                                              
              v_attribute5 := v_attribute5_1||'.'||v_attribute5_2||'.'||v_attribute5_3||'.'||v_attribute5_4;

              IF not v_flag_erreur THEN
                -- Table des enetetes
                UPDATE DKA_CONTRAT_SSTR_HEADER_TMP
                SET 
                       org_id               = v_org_id
                      ,AGENT_ID             = v_AGENT_ID
                      ,VENDOR_SITE_ID       = V_VENDOR_SITE_ID
                      ,VENDOR_ID            = V_VENDOR_ID
                      ,SHIP_TO_LOCATION_ID  = v_SHIP_TO_LOCATION_ID
                      ,BILL_TO_LOCATION_ID  = v_BILL_TO_LOCATION_ID
                      ,TERM_ID              = V_TERM_ID
                      ,STYLE_ID             = v_STYLE_ID
                      ,ATTRIBUTE5_TRANSCO   = v_attribute5
                      ,STATUT               = 'S'
                WHERE document_num = rec_cur_header.document_num
                AND   DATA_TYPE    = 'ACTUEL'
                ;
              ELSE
                -- Table des enetetes
                UPDATE DKA_CONTRAT_SSTR_HEADER_TMP
                SET 
                       org_id               = v_org_id
                      ,AGENT_ID             = v_AGENT_ID
                      ,VENDOR_SITE_ID       = V_VENDOR_SITE_ID
                      ,VENDOR_ID            = V_VENDOR_ID
                      ,SHIP_TO_LOCATION_ID  = v_SHIP_TO_LOCATION_ID
                      ,BILL_TO_LOCATION_ID  = v_BILL_TO_LOCATION_ID
                      ,TERM_ID              = V_TERM_ID
                      ,STYLE_ID             = v_STYLE_ID
                      ,ATTRIBUTE5_TRANSCO   = v_attribute5
                      ,STATUT               = 'E'
                WHERE document_num = rec_cur_header.document_num
                AND   DATA_TYPE    = 'ACTUEL'
                ;
              END IF;
            ---<<
            ---<<

            -----------------------
            -- Valider histo entete --
            -----------------------
            --->>
            --->>
            FOR rec_cur_header_histo IN cur_header_histo(rec_cur_header.DOCUMENT_NUM) LOOP
              v_flag_erreur_histo := FALSE;
              
              -- Récuperer l'agent
              --->>
              --->>
                BEGIN
                  SELECT ppf.person_id
                  INTO v_agent_id
                  FROM per_people_f ppf
                  WHERE ppf.full_name = rec_cur_header_histo.AGENT_NAME
                  AND sysdate BETWEEN NVL(ppf.effective_start_date,sysdate) AND NVL(ppf.effective_end_date,sysdate)
                  AND CURRENT_EMPLOYEE_FLAG = 'Y';
                   
                  v_agent_name := rec_cur_header_histo.AGENT_NAME;
                
                EXCEPTION
                  WHEN OTHERS THEN 
                    v_agent_id := NULL;
                    v_agent_name := 'REPRISE, REPRISE';
                    v_message := 'Avertissement : L''employé '||rec_cur_header_histo.AGENT_NAME||' n''existe pas, remplacement par REPRISE';
                    Add_Message(rec_cur_header_histo.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                    v_flag_warning := TRUE;
                END;
                 
                BEGIN
                  SELECT AGENT_ID 
                  INTO v_AGENT_ID
                  FROM PO_AGENTS_V
                  WHERE AGENT_NAME = v_agent_name
                  AND sysdate BETWEEN NVL(start_date_active,sysdate) AND NVL(end_date_active,sysdate)
                  ;
                EXCEPTION
                WHEN OTHERS THEN
                  v_agent_id := NULL;
                  v_message :=  'L''employé '||v_agent_name||' n''est pas défini comme acheteur';
                  Add_Message(rec_cur_header_histo.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                  v_flag_erreur_histo := TRUE;
                END;
              ---<<
              ---<<
            
              
              -- Récupération de l'org id
              --->>
              --->>
              
                  dka_rep_transco_pkg.get_transco ( pv_transco_name => '008_REGIONS',
                                                       pv_column_01 => rec_cur_header_histo.region,
                                                       pv_out_01    => rec_cur_header_histo.region
                                                  );
                                                  
                  v_org_id := get_organization_id(rec_cur_header_histo.societe,rec_cur_header_histo.region);
                  
                  IF v_org_id = -1 THEN
                    v_org_id := NULL;
                    v_message := 'Erreur de récuperation de ORG_ID pour le nom : '||rec_cur_header_histo.region||','||rec_cur_header_histo.societe;
                    Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                    v_flag_erreur_histo := TRUE;
                  END IF;
              ---<<
              ---<<
              
              -- Récupération du fournisseur et site
              --->>
              --->>
                  BEGIN
                    SELECT ASA.VENDOR_ID
                    INTO V_VENDOR_ID
                    FROM Po_Vendors ASA
                    WHERE ASA.VENDOR_NAME  = rec_cur_header_histo.VENDOR_NAME
                    ;
                    
                    IF V_VENDOR_ID IS NOT NULL THEN
                        BEGIN
                          SELECT ASA.VENDOR_ID,ASSA.VENDOR_SITE_ID
                          INTO V_VENDOR_ID,V_VENDOR_SITE_ID
                          FROM Po_Vendors ASA,
                               Po_Vendor_SITES_ALL ASSA
                          WHERE ASSA.VENDOR_SITE_CODE like SUBSTR(rec_cur_header_histo.VENDOR_SITE_CODE,5)||'%'
                          AND ASA.VENDOR_NAME  = rec_cur_header_histo.VENDOR_NAME
                          AND ASA.vendor_id    = ASSA.vendor_id
                          AND ASSA.org_id = v_org_id
                          AND assa.purchasing_site_flag = 'Y'
                          AND ROWNUM = 1
                          ;
                        EXCEPTION
                        WHEN OTHERS THEN
                          V_VENDOR_SITE_ID := NULL;
                          v_message := 'Avertissement : le site fournisseur ' ||SUBSTR(rec_cur_header_histo.VENDOR_SITE_CODE,5)||' n''existe pas';
                          Add_Message(rec_cur_header_histo.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                          v_flag_warning := TRUE;
                        END;
                    END IF;
                    
                  EXCEPTION
                  WHEN OTHERS THEN
                    V_VENDOR_ID := NULL;
                    V_VENDOR_SITE_ID := NULL;
                    v_message := 'Avertissement : le fournisseur ' ||rec_cur_header_histo.VENDOR_NAME|| ' n''existe pas ' ;
                    Add_Message(rec_cur_header_histo.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                    v_flag_warning := TRUE;
                  END;
                  
                  /*
                  BEGIN
                    SELECT ASA.VENDOR_ID,ASSA.VENDOR_SITE_ID
                    INTO V_VENDOR_ID,V_VENDOR_SITE_ID
                    FROM Po_Vendors ASA,
                         Po_Vendor_SITES_ALL ASSA
                    WHERE ASSA.VENDOR_SITE_CODE like SUBSTR(rec_cur_header_histo.VENDOR_SITE_CODE,5)||'%'
                    AND ASA.VENDOR_NAME  = rec_cur_header_histo.VENDOR_NAME
                    AND ASA.vendor_id    = ASSA.vendor_id
                    AND ASSA.org_id = v_org_id
                    AND assa.purchasing_site_flag = 'Y'
                    AND ROWNUM = 1
                    ;
                  EXCEPTION
                  WHEN OTHERS THEN
                    V_VENDOR_ID := NULL;
                    V_VENDOR_SITE_ID := NULL;
                    v_message := 'Erreur de récuperation du fournisseur et site fournisseur ' ||rec_cur_header_histo.VENDOR_NAME||'/'||SUBSTR(rec_cur_header_histo.VENDOR_SITE_CODE,5)||', '||SQLERRM;
                    Add_Message(rec_cur_header_histo.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                    v_flag_erreur_histo := TRUE;
                  END;*/
              ---<<
              ---<<
              
              -- Lieu de livraison
              --->>
              --->>
                  BEGIN
                    SELECT LOCATION_ID 
                    INTO v_SHIP_TO_LOCATION_ID
                    FROM HR_LOCATIONS
                    WHERE location_code = rec_cur_header_histo.SHIP_TO_LOCATION
                    ;
                  EXCEPTION
                  WHEN OTHERS THEN
                    v_SHIP_TO_LOCATION_ID := NULL;
                    v_message := 'Erreur de récuperation du lieu de livraison : '||rec_cur_header_histo.SHIP_TO_LOCATION;
                    Add_Message(rec_cur_header_histo.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                    v_flag_erreur_histo := TRUE;
                  END;
              ---<<
              ---<<
              
              -- Lieu de facturation
              --->>
              --->>
                  BEGIN
                    SELECT LOCATION_ID 
                    INTO v_BILL_TO_LOCATION_ID
                    FROM HR_LOCATIONS
                    WHERE location_code = rec_cur_header_histo.BILL_TO_LOCATION
                    ;
                  EXCEPTION
                  WHEN OTHERS THEN
                    v_BILL_TO_LOCATION_ID := NULL;
                    v_message := 'Erreur de récuperation du lieu de facturation '||rec_cur_header_histo.BILL_TO_LOCATION;
                    Add_Message(rec_cur_header_histo.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                    v_flag_erreur_histo := TRUE;
                  END;
              ---<<
              ---<<
              
              -- Terms
              --->>
              --->>
              IF rec_cur_header_histo.PAYMENT_TERMS IS NOT NULL THEN
                  BEGIN
                    SELECT TERM_ID 
                    INTO v_TERM_ID
                    FROM AP_TERMS
                    WHERE NAME = rec_cur_header_histo.PAYMENT_TERMS
                    ;
                  EXCEPTION
                  WHEN OTHERS THEN
                    v_TERM_ID := NULL;
                    v_message := 'Erreur de récuperation du Terms Id pour NAME = '|| rec_cur_header_histo.PAYMENT_TERMS;
                    Add_Message(rec_cur_header_histo.DOCUMENT_NUM,rec_cur_header_histo.DATA_TYPE,NULL,v_message);
                    v_flag_erreur_histo := TRUE;
                  END;
              ELSE
                v_TERM_ID := NULL;
              END IF;
              
              ---<<
              ---<<
              
              -- Transco de ATTRIBUTE5
              --->>
              --->>              
                dka_rep_transco_pkg.get_transco (  pv_transco_name => '013_CATEGORIES_ACHATS',
                                                   pv_column_01 => get_segment_categ(rec_cur_header_histo.ATTRIBUTE5,1),
                                                   pv_column_02 => get_segment_categ(rec_cur_header_histo.ATTRIBUTE5,2),
                                                   pv_column_03 => get_segment_categ(rec_cur_header_histo.ATTRIBUTE5,3),
                                                   pv_column_04 => get_segment_categ(rec_cur_header_histo.ATTRIBUTE5,4),
                                                   pv_out_01    => v_attribute5_1,
                                                   pv_out_02    => v_attribute5_2,
                                                   pv_out_03    => v_attribute5_3,
                                                   pv_out_04    => v_attribute5_4
                                                );
                                                
                v_attribute5 := v_attribute5_1||'.'||v_attribute5_2||'.'||v_attribute5_3||'.'||v_attribute5_4;
                
                
                IF v_flag_erreur_histo THEN
                  
                  v_flag_erreur := TRUE;
                  
                  -- Table des enetetes
                  UPDATE DKA_CONTRAT_SSTR_HEADER_TMP
                  SET 
                         org_id               = v_org_id
                        ,AGENT_ID             = v_AGENT_ID
                        ,VENDOR_SITE_ID       = V_VENDOR_SITE_ID
                        ,VENDOR_ID            = V_VENDOR_ID
                        ,SHIP_TO_LOCATION_ID  = v_SHIP_TO_LOCATION_ID
                        ,BILL_TO_LOCATION_ID  = v_BILL_TO_LOCATION_ID
                        ,TERM_ID              = V_TERM_ID
                        ,STYLE_ID             = v_STYLE_ID
                        ,ATTRIBUTE5_TRANSCO   = v_attribute5
                        ,STATUT               = 'E'
                  WHERE  CURRENT OF cur_header_histo;
                ELSE
                    -- Table des enetetes
                    UPDATE DKA_CONTRAT_SSTR_HEADER_TMP
                    SET 
                           org_id               = v_org_id
                          ,AGENT_ID             = v_AGENT_ID
                          ,VENDOR_SITE_ID       = V_VENDOR_SITE_ID
                          ,VENDOR_ID            = V_VENDOR_ID
                          ,SHIP_TO_LOCATION_ID  = v_SHIP_TO_LOCATION_ID
                          ,BILL_TO_LOCATION_ID  = v_BILL_TO_LOCATION_ID
                          ,TERM_ID              = V_TERM_ID
                          ,STYLE_ID             = v_STYLE_ID
                          ,ATTRIBUTE5_TRANSCO   = v_attribute5
                          ,STATUT               = 'S'
                    WHERE  CURRENT OF cur_header_histo
                    ;
                END IF;
                
            END LOOP;
            ---<<
            ---<<


            -----------------------
            -- Valider le detail --
            -----------------------
            --->>
            --->>
            FOR rec_cur_detail IN cur_detail(rec_cur_header.DOCUMENT_NUM) LOOP
              v_flag_erreur_detail := FALSE;
              -- Recuperer le signataire
              --->>
              --->>
              IF rec_cur_detail.DOCUMENT_NUM_CADRE IS NOT NULL THEN
                  BEGIN
                    SELECT PO_HEADER_ID
                    INTO v_cadre_po_header_id
                    FROM PO_HEADERS_ALL
                    WHERE segment1= rec_cur_detail.DOCUMENT_NUM_CADRE
                    ;
                  EXCEPTION
                  WHEN OTHERS THEN
                    IF rec_cur_detail.DATA_TYPE = 'ACTUEL' THEN
                      v_cadre_po_header_id := NULL;
                      v_message := 'Erreur de récupération du contrat cadre '|| rec_cur_detail.DOCUMENT_NUM_CADRE;
                      Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_detail.data_type,NULL,v_message);
                      v_flag_erreur_detail := TRUE;
                    ELSE
                      v_cadre_po_header_id := NULL;
                      v_message := 'Avertissement : problème de récupération du contrat cadre '|| rec_cur_detail.DOCUMENT_NUM_CADRE;
                      Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_detail.data_type,NULL,v_message);
                      v_flag_warning := TRUE;
                    END IF;
                  END;
              ELSE
                v_cadre_po_header_id := NULL;
              END IF;

              ---<<
              ---<<
              
              -- Recuperer la commande
              --->>
              --->>
              IF rec_cur_detail.COMMANDE_NUM IS NOT NULL THEN
                  BEGIN
                    SELECT PO_HEADER_ID
                    INTO v_commande_id
                    FROM PO_HEADERS_ALL
                    WHERE segment1 = rec_cur_detail.COMMANDE_NUM
                    AND type_lookup_code = 'STANDARD' --RBE artf2089569
                    ;
                  EXCEPTION
                  WHEN OTHERS THEN
                    IF rec_cur_detail.DATA_TYPE = 'ACTUEL' THEN
                      --RBE artf2089569 
                      BEGIN
                        SELECT 1
                        INTO v_commande_id
                        FROM PO_HEADERS_TMP
                        WHERE document_num = rec_cur_detail.COMMANDE_NUM
                        ;
                        
                        v_commande_id := NULL;
                        v_message := 'La commande PO ' ||rec_cur_detail.COMMANDE_NUM ||' n''est pas encore migrée';
                        Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_detail.data_type,NULL,v_message);
                        v_flag_erreur_detail := TRUE;
                      
                      EXCEPTION
                      WHEN OTHERS THEN
                        v_commande_id := NULL;
                        v_message := 'La commande PO n''a pas été extraite : ' ||rec_cur_detail.COMMANDE_NUM;
                        Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_detail.data_type,NULL,v_message);
                        v_flag_warning := TRUE;
                      END;

                    ELSE
                      v_commande_id := NULL;
                      v_message := 'Avertissement : la commande PO ' ||rec_cur_detail.COMMANDE_NUM ||' n''est pas trouvée';
                      Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_detail.data_type,NULL,v_message);
                      v_flag_warning := TRUE;
                    END IF;
                  END;
              ELSE
                v_commande_id := NULL;
              END IF;
              ---<<
              ---<<

              -- Recuperer le signataire
              --->>
              --->>
                  BEGIN
                    SELECT PERSON_ID
                    INTO v_person_id
                    FROM PER_ALL_PEOPLE_F ppf
                    WHERE ppf.FULL_NAME= rec_cur_detail.SIGNATAIRE_CONTRAT
                    AND sysdate BETWEEN NVL(ppf.effective_start_date,sysdate) AND NVL(ppf.effective_end_date,sysdate)
                    AND ppf.CURRENT_EMPLOYEE_FLAG = 'Y';
                                  EXCEPTION
                  WHEN OTHERS THEN
                      BEGIN
                        SELECT PPF.PERSON_ID
                        INTO v_person_id
                        FROM PER_PEOPLE_F PPF
                        WHERE ppf.full_name = 'REPRISE, REPRISE'
                        AND SYSDATE BETWEEN NVL(PPF.EFFECTIVE_START_DATE,SYSDATE) AND NVL(PPF.EFFECTIVE_END_DATE,SYSDATE)
                        AND CURRENT_EMPLOYEE_FLAG = 'Y'
                        ;
                        
                      v_message := 'Avertissement : L''employé '||rec_cur_detail.SIGNATAIRE_CONTRAT||' n''existe pas, remplacement par REPRISE';
                      Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_detail.data_type,NULL,v_message);
                      v_flag_warning := TRUE;
                      EXCEPTION
                      WHEN OTHERS THEN
                        v_person_id := NULL;
                        v_message :=  'L''employé '||'REPRISE, REPRISE'||' n''est pas trouvé';
                        Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_detail.data_type,NULL,v_message);
                        v_flag_erreur := TRUE;
                      END;
                  END;
              ---<<
              ---<<
            
              --Mise à jour de la table detail
              --->
              --->
                  -- Si erreur
                  IF v_flag_erreur_detail THEN
                  
                    UPDATE DKA_CONTRAT_SSTR_DETAIL_TMP
                    SET 
                           CADRE_PO_HEADER_ID = V_CADRE_PO_HEADER_ID
                          ,COMMANDE_ID        = V_COMMANDE_ID
                          ,PERSON_ID          = V_PERSON_ID
                          ,STATUT      = 'E'
                    WHERE  CURRENT OF cur_detail;
                  
                  ELSE -- en cas d'erreur
                    
                    UPDATE DKA_CONTRAT_SSTR_DETAIL_TMP
                    SET 
                           CADRE_PO_HEADER_ID = V_CADRE_PO_HEADER_ID
                          ,COMMANDE_ID        = V_COMMANDE_ID
                          ,PERSON_ID          = V_PERSON_ID        
                          ,STATUT      = 'S'
                    WHERE  CURRENT OF cur_detail
                    ;
                
                END IF;
              ---<<
              ---<<
              -- Si erreur
              IF v_flag_erreur_detail THEN
                v_flag_erreur := TRUE;
              END IF;
            END LOOP; --<<< Fin cur_detail
                   
            -- Valider les imputations
            --->>
            --->>
            FOR rec_cur_imput IN cur_imput(rec_cur_header.DOCUMENT_NUM) LOOP
                    
                    v_flag_erreur_imput := FALSE;
                    -- Récuperer le projet et tache
                    --->>
                    --->>
                        dka_rep_transco_pkg.get_transco ( pv_transco_name => '014_PROJETS',
                                         pv_column_01 => rec_cur_imput.PROJECT_CODE,
                                         pv_out_01    => v_project_code,
                                         pv_out_02    => v_task
                                    );

                        BEGIN
                          SELECT project_id
                          INTO v_project_id
                          FROM PA_PROJECTS_ALL 
                          WHERE segment1 = v_project_code
                          ;
                        EXCEPTION
                        WHEN OTHERS THEN
                          v_project_id := NULL;
                          v_message := 'Problème lors de récupération du projet '||v_project_code;
                          IF rec_cur_imput.DATA_TYPE = 'HISTO' THEN
                              v_message := 'Avertissement - '||v_message;
                              v_flag_warning := TRUE;
                          ELSE
                              v_flag_erreur_imput := TRUE;
                          END IF;
                          Add_Message(rec_cur_header.DOCUMENT_NUM, rec_cur_imput.data_type,rec_cur_imput.contrat_imputation_id,v_message);

                        END;

                        BEGIN
                          SELECT task_id
                          INTO v_task_id
                          FROM PA_TASKS 
                          WHERE task_number = v_task
                          AND   project_id  = v_project_id
                          ;
                        EXCEPTION
                        WHEN OTHERS THEN
                          v_task_id := NULL;
                          v_message := 'Problème lors de récupération de la tâche '||v_task;
                          IF rec_cur_imput.DATA_TYPE = 'HISTO' THEN
                              v_message := 'Avertissement - '||v_message;
                              v_flag_warning := TRUE;
                          ELSE
                              v_flag_erreur_imput := TRUE;
                          END IF;
                          Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_imput.data_type, rec_cur_imput.contrat_imputation_id,v_message);
                        END;
                    ---<<
                    ---<<
                    
                    -- Récuperer Location id
                    --->>
                    --->>
                        BEGIN
                          SELECT LOCATION_ID
                          INTO v_location_id
                          FROM HR_LOCATIONS 
                          WHERE LOCATION_CODE = rec_cur_imput.LOCATION_CODE
                          ;
                        EXCEPTION
                        WHEN OTHERS THEN
                          v_location_id := NULL;
                          v_message := 'Erreur de récupération location id pour LOCATION_CODE = '||rec_cur_imput.LOCATION_CODE;
                          Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_imput.data_type, rec_cur_imput.contrat_imputation_id,v_message);
                          v_flag_erreur_imput := TRUE;
                        END;
                    ---<<
                    ---<<
                    
                    -- CODE_COMBINATION_ID
                    --->>
                    --->>
                    BEGIN
                      
                        dka_rep_transco_pkg.get_transco ( pv_transco_name => '008_REGIONS',
                                                          pv_column_01 => rec_cur_imput.CCID_SEGMENT2,
                                                          pv_out_01    => rec_cur_imput.CCID_SEGMENT2
                                                        );

                        v_ccf := dka_rep_transco_pkg.get_cle_transco_f (  
                                                                        rec_cur_imput.CCID_SEGMENT1, 
                                                                                                          rec_cur_imput.CCID_SEGMENT2,                        
                                                                                                          rec_cur_imput.CCID_SEGMENT3, 
                                                                                                          rec_cur_imput.CCID_SEGMENT4, 
                                                                                                          rec_cur_imput.CCID_SEGMENT5, 
                                                                                                          --rec_cur_imput.CCID_SEGMENT6, 
                                                                                                          rec_cur_imput.CCID_SEGMENT7, 
                                                                                                          rec_cur_imput.CCID_SEGMENT8, 
                                                                                                          rec_cur_imput.CCID_SEGMENT9, 
                                                                                                          rec_cur_imput.CCID_SEGMENT10
                                                                                                          );
                                                                        
                         v_CODE_COMBINATION_ID := to_number(v_ccf);
                    
                    EXCEPTION
                        WHEN OTHERS THEN
                          v_code_combination_id := NULL;
                          v_message := v_ccf;
                          Add_Message(rec_cur_header.DOCUMENT_NUM,rec_cur_imput.data_type, rec_cur_imput.contrat_imputation_id,v_message);
                          v_flag_erreur_imput := TRUE;
                    END;

                    ---<<
                    ---<<

                    -- Mise à jour de la table
                    --->
                    --->
                        -- Si erreur
                        IF v_flag_erreur_imput THEN
                        
                          UPDATE DKA_CONTRAT_SSTR_IMPUT_TMP
                          SET 
                                 project_id  = v_project_id
                                ,task_id     = v_task_id
                                ,location_id = v_location_id
                                ,code_combination_id = v_code_combination_id
                                ,STATUT      = 'E'
                          WHERE  CURRENT OF cur_imput
                          ;
                        ELSE -- en cas d'erreur
                          
                          UPDATE DKA_CONTRAT_SSTR_IMPUT_TMP
                          SET 
                                 project_id  = v_project_id
                                ,task_id     = v_task_id
                                ,location_id = v_location_id
                                ,code_combination_id = v_code_combination_id
                                ,STATUT      = 'S'
                          WHERE  CURRENT OF cur_imput
                          ;
                      
                      END IF;
                    ---<<
                    ---<<
                    
                    -- Si erreur
                    IF v_flag_erreur_imput THEN
                      v_flag_erreur := TRUE;
                    END IF;

              END LOOP; 
              --<<<Fin cur_imput
              
            -- Mise à jour de la table
            --->
            --->
                -- Si erreur
                IF v_flag_erreur THEN

                  -- Table des entetes
                  UPDATE DKA_CONTRAT_SSTR_HEADER_TMP
                  SET STATUT = 'E'
                  WHERE document_num = rec_cur_header.document_num
                  ;
                  
                  -- Table des details
                  UPDATE DKA_CONTRAT_SSTR_DETAIL_TMP
                  SET STATUT = 'E'
                  WHERE document_num = rec_cur_header.document_num
                  ;
                  
                  -- Table des imputations
                  UPDATE DKA_CONTRAT_SSTR_IMPUT_TMP
                  SET STATUT = 'E'
                  WHERE document_num = rec_cur_header.document_num
                  ;
                END IF;
              ---<<
              ---<<
            
        END LOOP;          

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_data');    
  
        IF v_flag_warning AND p_retcode != 2 THEN
          p_retcode   := 1;
        END IF;
  
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
    
    v_po_header_id            NUMBER;
    
    CURSOR cur_header IS
      SELECT *
      FROM DKA_CONTRAT_SSTR_HEADER_TMP
      WHERE DATA_TYPE = 'ACTUEL'
      AND  STATUT = 'S'
      AND  load_request_id = DECODE( g_loader_request_id
                                       , -1, load_request_id
                                       , g_loader_request_id)
    ;

    CURSOR cur_header_histo(p_doc_num VARCHAR2) IS
      SELECT *
      FROM DKA_CONTRAT_SSTR_HEADER_TMP
      WHERE document_num = p_doc_num
      AND DATA_TYPE = 'HISTO'
    ;
    
    CURSOR cur_detail (p_doc_num VARCHAR2)IS
      SELECT *
      FROM DKA_CONTRAT_SSTR_DETAIL_TMP
      WHERE document_num = p_doc_num
      ORDER BY DATA_TYPE
    ;
    CURSOR cur_imput (p_doc_num VARCHAR2) IS
      SELECT *
      FROM DKA_CONTRAT_SSTR_IMPUT_TMP
      WHERE document_num = p_doc_num
      ORDER BY DATA_TYPE
    ;
    
  BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_data');    
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 
                                         'Insertion dans les tables finales : ');

        FOR rec_cur_header IN cur_header LOOP  
              -- Generer po_header_id
              SELECT po_headers_s.nextval
              INTO v_po_header_id
              FROM DUAL;
              -- PO_HEADERS_ALL
              INSERT INTO PO_HEADERS_ALL 
                                (  PO_HEADER_ID
                                  ,AGENT_ID
                                  ,TYPE_LOOKUP_CODE
                                  ,LAST_UPDATE_DATE
                                  ,LAST_UPDATED_BY
                                  ,SEGMENT1
                                  ,SUMMARY_FLAG
                                  ,ENABLED_FLAG
                                  ,CREATION_DATE
                                  ,CREATED_BY
                                  ,VENDOR_ID
                                  ,VENDOR_SITE_ID
                                  ,SHIP_TO_LOCATION_ID
                                  ,BILL_TO_LOCATION_ID
                                  ,TERMS_ID
                                  ,CURRENCY_CODE
                                  ,RATE_DATE
                                  ,START_DATE
                                  ,END_DATE
                                  ,BLANKET_TOTAL_AMOUNT
                                  ,AUTHORIZATION_STATUS
                                  ,REVISION_NUM
                                  ,REVISED_DATE
                                  ,APPROVED_FLAG
                                  ,APPROVED_DATE
                                  ,COMMENTS
                                  ,ATTRIBUTE4
                                  ,ATTRIBUTE5
                                  ,ATTRIBUTE13
                                  ,ATTRIBUTE14
                                  ,ATTRIBUTE15
                                  ,ORG_ID 
                                  ,STYLE_ID
                                  )
            VALUES
                                  (
                                   v_po_header_id                         --PO_HEADER_ID
                                  ,rec_cur_header.AGENT_ID                --AGENT_ID
                                  ,rec_cur_header.TYPE_LOOKUP_CODE        --TYPE_LOOKUP_CODE
                                  ,SYSDATE                                --LAST_UPDATE_DATE
                                  ,g_user_id                              --LAST_UPDATED_BY
                                  ,rec_cur_header.DOCUMENT_NUM||'ST'      --SEGMENT1
                                  ,'N'                                    --SUMMARY_FLAG
                                  ,'Y'                                    --ENABLED_FLAG
                                  ,SYSDATE                                --CREATION_DATE
                                  ,g_user_id                              --CREATED_BY
                                  ,rec_cur_header.VENDOR_ID               --VENDOR_ID
                                  ,rec_cur_header.VENDOR_SITE_ID          --VENDOR_SITE_ID
                                  ,rec_cur_header.SHIP_TO_LOCATION_ID     --SHIP_TO_LOCATION_ID 
                                  ,rec_cur_header.BILL_TO_LOCATION_ID     --BILL_TO_LOCATION_ID 
                                  ,rec_cur_header.TERM_ID                 --TERMS_ID  
                                  ,rec_cur_header.CURRENCY_CODE           --CURRENCY_CODE
                                  ,rec_cur_header.RATE_DATE               --RATE_DATE
                                  ,rec_cur_header.START_DATE              --START_DATE           
                                  ,rec_cur_header.END_DATE                --END_DATE             
                                  ,rec_cur_header.BLANKET_TOTAL_AMOUNT    --BLANKET_TOTAL_AMOUNT 
                                  ,rec_cur_header.APPROVAL_STATUS         --AUTHORIZATION_STATUS 
                                  ,rec_cur_header.REVISION_NUM            --REVISION_NUM         
                                  ,rec_cur_header.REVISION_DATE           --REVISED_DATE         
                                  ,rec_cur_header.APPROVED_FLAG           --APPROVED_FLAG        
                                  ,rec_cur_header.APPROVED_DATE           --APPROVED_DATE   
                                  ,rec_cur_header.COMMENTS                --COMMENTS
                                  ,rec_cur_header.ATTRIBUTE4              --ATTRIBUTE4 
                                  ,rec_cur_header.ATTRIBUTE5_transco      --ATTRIBUTE5 
                                  ,rec_cur_header.ATTRIBUTE13             --ATTRIBUTE13
                                  ,rec_cur_header.ATTRIBUTE14             --ATTRIBUTE14
                                  ,rec_cur_header.ATTRIBUTE15             --ATTRIBUTE15
                                  ,rec_cur_header.ORG_ID                  --ORG_ID     
                                  ,rec_cur_header.STYLE_ID                --STYLE_ID
                                  );
                                  
              g_summary.inserted_header_rows := g_summary.inserted_header_rows + 1;
  
            FOR rec_cur_header_histo IN cur_header_histo(rec_cur_header.DOCUMENT_NUM) LOOP
              -- PO_HEADERS_ARCHIVE_ALL
              INSERT INTO PO_HEADERS_ARCHIVE_ALL 
                                (  PO_HEADER_ID
                                  ,AGENT_ID
                                  ,TYPE_LOOKUP_CODE
                                  ,LAST_UPDATE_DATE
                                  ,LAST_UPDATED_BY
                                  ,SEGMENT1
                                  ,SUMMARY_FLAG
                                  ,ENABLED_FLAG
                                  ,CREATION_DATE
                                  ,CREATED_BY
                                  ,VENDOR_ID
                                  ,VENDOR_SITE_ID
                                  ,SHIP_TO_LOCATION_ID
                                  ,BILL_TO_LOCATION_ID
                                  ,TERMS_ID
                                  ,CURRENCY_CODE
                                  ,RATE_DATE
                                  ,START_DATE
                                  ,END_DATE
                                  ,BLANKET_TOTAL_AMOUNT
                                  ,AUTHORIZATION_STATUS
                                  ,REVISION_NUM
                                  ,REVISED_DATE
                                  ,APPROVED_FLAG
                                  ,APPROVED_DATE
                                  ,COMMENTS
                                  ,ATTRIBUTE4
                                  ,ATTRIBUTE5
                                  ,ATTRIBUTE13
                                  ,ATTRIBUTE14
                                  ,ATTRIBUTE15
                                  ,ORG_ID
                                  ,STYLE_ID
                                  ,LATEST_EXTERNAL_FLAG --RBE artf2212570
                                  )
            VALUES
                                  (
                                   v_po_header_id                               --PO_HEADER_ID
                                  ,rec_cur_header_histo.AGENT_ID                --AGENT_ID
                                  ,rec_cur_header_histo.TYPE_LOOKUP_CODE        --TYPE_LOOKUP_CODE
                                  ,SYSDATE                                      --LAST_UPDATE_DATE
                                  ,g_user_id                                    --LAST_UPDATED_BY
                                  ,rec_cur_header_histo.DOCUMENT_NUM||'ST'      --SEGMENT1
                                  ,'N'                                          --SUMMARY_FLAG
                                  ,'Y'                                          --ENABLED_FLAG
                                  ,SYSDATE                                      --CREATION_DATE
                                  ,g_user_id                                    --CREATED_BY
                                  ,rec_cur_header_histo.VENDOR_ID               --VENDOR_ID
                                  ,rec_cur_header_histo.VENDOR_SITE_ID          --VENDOR_SITE_ID
                                  ,rec_cur_header_histo.SHIP_TO_LOCATION_ID     --SHIP_TO_LOCATION_ID 
                                  ,rec_cur_header_histo.BILL_TO_LOCATION_ID     --BILL_TO_LOCATION_ID 
                                  ,rec_cur_header_histo.TERM_ID                 --TERMS_ID  
                                  ,rec_cur_header_histo.CURRENCY_CODE           --CURRENCY_CODE
                                  ,rec_cur_header_histo.RATE_DATE               --RATE_DATE
                                  ,rec_cur_header_histo.START_DATE              --START_DATE           
                                  ,rec_cur_header_histo.END_DATE                --END_DATE             
                                  ,rec_cur_header_histo.BLANKET_TOTAL_AMOUNT    --BLANKET_TOTAL_AMOUNT 
                                  ,rec_cur_header_histo.APPROVAL_STATUS         --AUTHORIZATION_STATUS 
                                  ,rec_cur_header_histo.REVISION_NUM            --REVISION_NUM         
                                  ,rec_cur_header_histo.REVISION_DATE           --REVISED_DATE         
                                  ,rec_cur_header_histo.APPROVED_FLAG           --APPROVED_FLAG        
                                  ,rec_cur_header_histo.APPROVED_DATE           --APPROVED_DATE   
                                  ,rec_cur_header_histo.COMMENTS                --COMMENTS
                                  ,rec_cur_header_histo.ATTRIBUTE4              --ATTRIBUTE4 
                                  ,rec_cur_header_histo.ATTRIBUTE5_TRANSCO      --ATTRIBUTE5 
                                  ,rec_cur_header_histo.ATTRIBUTE13             --ATTRIBUTE13
                                  ,rec_cur_header_histo.ATTRIBUTE14             --ATTRIBUTE14
                                  ,rec_cur_header_histo.ATTRIBUTE15             --ATTRIBUTE15
                                  ,rec_cur_header_histo.org_id                  --ORG_ID    
                                  ,rec_cur_header.STYLE_ID                      --STYLE_ID
                                  ,rec_cur_header_histo.LATEST_EXTERNAL_FLAG    --LATEST_EXTERNAL_FLAG --RBE artf2212570
                                  );
                g_summary.inserted_header_hist_rows := g_summary.inserted_header_hist_rows + 1;
                
            END LOOP;
  
            -- Inserer le detail
            FOR rec_cur_detail IN cur_detail(rec_cur_header.DOCUMENT_NUM) LOOP
              
              IF rec_cur_detail.DATA_TYPE = 'ACTUEL' THEN
              
                -- DKA_CONTRAT_SSTR
                INSERT INTO DKA_CONTRAT_SSTR
                (
                   PO_HEADER_ID                  
                  ,CADRE_PO_HEADER_ID               
                  ,FLAG_TACITE_RECONDUCTION         
                  ,NB_RECONDUCTION                 
                  ,PREAVIS_RESILIATION             
                  ,FLAG_REVISION                   
                  ,DATE_REVISION                   
                  ,NB_INTERVENTION                 
                  ,PERIODICITE_INTERVENTION         
                  ,NB_INTERVENTION_REALISE         
                  ,FLAG_FACTURATION                 
                  ,COMMENTAIRE_FACTURATION         
                  ,PERIODICITE_FACTURATION         
                  ,SIGNATAIRE_CONTRAT               
                  ,CREATED_BY                       
                  ,CREATION_DATE                   
                  ,LAST_UPDATED_BY                 
                  ,LAST_UPDATE_DATE                 
                  ,ORG_ID                           
                  ,REF_CONTRAT_FOURNISSEUR         
                  ,DESCRIPTION_SPECIFIQUE_CONTRAT
                  ,FLAG_MAIL_AVERTISSEMENT         
                  ,DATE_EFFET                    
                  ,RECONDUCTION_NUM                 
                  ,REVISION_NUM                  
                  ,COMMANDE_ID                     
                  ,COMMANDE_VERSION                 
                  ,DATE_RESILIATION                 
                  ,ANNULATION
                  )
                VALUES
                  (
                   v_po_header_id                                                         --PO_HEADER_ID                  
                  ,rec_cur_detail.CADRE_PO_HEADER_ID                                      --CADRE_PO_HEADER_ID               
                  ,rec_cur_detail.FLAG_TACITE_RECONDUCTION                                --FLAG_TACITE_RECONDUCTION         
                  ,rec_cur_detail.NB_RECONDUCTION                                         --NB_RECONDUCTION                  
                  ,rec_cur_detail.PREAVIS_RESILIATION                                     --PREAVIS_RESILIATION              
                  ,rec_cur_detail.FLAG_REVISION                                           --FLAG_REVISION                    
                  ,rec_cur_detail.DATE_REVISION                                              --DATE_REVISION                    
                  ,rec_cur_detail.NB_INTERVENTION                                         --NB_INTERVENTION                  
                  ,rec_cur_detail.PERIODICITE_INTERVENTION                                --PERIODICITE_INTERVENTION         
                  ,rec_cur_detail.NB_INTERVENTION_REALISE                                 --NB_INTERVENTION_REALISE          
                  ,rec_cur_detail.FLAG_FACTURATION                                        --FLAG_FACTURATION                 
                  ,rec_cur_detail.COMMENTAIRE_FACTURATION                                 --COMMENTAIRE_FACTURATION          
                  ,rec_cur_detail.PERIODICITE_FACTURATION                                 --PERIODICITE_FACTURATION          
                  ,rec_cur_detail.PERSON_ID                                               --SIGNATAIRE_CONTRAT               
                  ,g_user_id                                                              --CREATED_BY                       
                  ,SYSDATE                                                                --CREATION_DATE                    
                  ,g_user_id                                                              --LAST_UPDATED_BY                  
                  ,SYSDATE                                                                --LAST_UPDATE_DATE                 
                  ,rec_cur_header.org_id                                                               --ORG_ID                           
                  ,rec_cur_detail.REF_CONTRAT_FOURNISSEUR                                 --REF_CONTRAT_FOURNISSEUR          
                  ,rec_cur_detail.DESCRIPTION_SPECIFIQUE_CONTRAT                          --DESCRIPTION_SPECIFIQUE_CONTRAT
                  ,rec_cur_detail.FLAG_MAIL_AVERTISSEMENT                                 --FLAG_MAIL_AVERTISSEMENT          
                  ,rec_cur_detail.DATE_EFFET                                              --DATE_EFFET                    
                  ,rec_cur_detail.RECONDUCTION_NUM                                        --RECONDUCTION_NUM                 
                  ,rec_cur_detail.REVISION_NUM                                            --REVISION_NUM                  
                  ,rec_cur_detail.commande_id                                             --COMMANDE_ID
                  ,rec_cur_detail.COMMANDE_VERSION                                        --COMMANDE_VERSION                 
                  ,rec_cur_detail.DATE_RESILIATION                                        --DATE_RESILIATION                 
                  ,rec_cur_detail.ANNULATION                                              --ANNULATION                    
                  );
                  
                  g_summary.inserted_detail_rows := g_summary.inserted_detail_rows + 1;
                  
              ELSIF(rec_cur_detail.DATA_TYPE = 'HISTO') THEN
                -- DKA_CONTRAT_SSTR_ARCHI
                INSERT INTO DKA_CONTRAT_SSTR_ARCHI
                (
                   PO_HEADER_ID                  
                  ,CADRE_PO_HEADER_ID               
                  ,FLAG_TACITE_RECONDUCTION         
                  ,NB_RECONDUCTION                 
                  ,PREAVIS_RESILIATION             
                  ,FLAG_REVISION                   
                  ,DATE_REVISION                   
                  ,NB_INTERVENTION                 
                  ,PERIODICITE_INTERVENTION         
                  ,NB_INTERVENTION_REALISE         
                  ,FLAG_FACTURATION                 
                  ,COMMENTAIRE_FACTURATION         
                  ,PERIODICITE_FACTURATION         
                  ,SIGNATAIRE_CONTRAT               
                  ,CREATED_BY                       
                  ,CREATION_DATE                   
                  ,LAST_UPDATED_BY                 
                  ,LAST_UPDATE_DATE                 
                  ,ORG_ID                           
                  ,REF_CONTRAT_FOURNISSEUR         
                  ,DESCRIPTION_SPECIFIQUE_CONTRAT
                  ,FLAG_MAIL_AVERTISSEMENT         
                  ,DATE_EFFET                    
                  ,RECONDUCTION_NUM                 
                  ,REVISION_NUM                  
                  ,COMMANDE_ID                     
                  ,COMMANDE_VERSION                 
                  ,DATE_RESILIATION                 
                  ,ANNULATION                    
                  )
                VALUES
                  (
                   v_po_header_id                                                         --PO_HEADER_ID                  
                  ,rec_cur_detail.CADRE_PO_HEADER_ID                                      --CADRE_PO_HEADER_ID               
                  ,rec_cur_detail.FLAG_TACITE_RECONDUCTION                                --FLAG_TACITE_RECONDUCTION         
                  ,rec_cur_detail.NB_RECONDUCTION                                         --NB_RECONDUCTION                  
                  ,rec_cur_detail.PREAVIS_RESILIATION                                     --PREAVIS_RESILIATION              
                  ,rec_cur_detail.FLAG_REVISION                                           --FLAG_REVISION                    
                  ,rec_cur_detail.DATE_REVISION                                              --DATE_REVISION                    
                  ,rec_cur_detail.NB_INTERVENTION                                         --NB_INTERVENTION                  
                  ,rec_cur_detail.PERIODICITE_INTERVENTION                                --PERIODICITE_INTERVENTION         
                  ,rec_cur_detail.NB_INTERVENTION_REALISE                                 --NB_INTERVENTION_REALISE          
                  ,rec_cur_detail.FLAG_FACTURATION                                        --FLAG_FACTURATION                 
                  ,rec_cur_detail.COMMENTAIRE_FACTURATION                                 --COMMENTAIRE_FACTURATION          
                  ,rec_cur_detail.PERIODICITE_FACTURATION                                 --PERIODICITE_FACTURATION          
                  ,rec_cur_detail.PERSON_ID                                                            --SIGNATAIRE_CONTRAT               
                  ,g_user_id                                                              --CREATED_BY                       
                  ,SYSDATE                                                                --CREATION_DATE                    
                  ,g_user_id                                                              --LAST_UPDATED_BY                  
                  ,SYSDATE                                                                --LAST_UPDATE_DATE                 
                  ,rec_cur_header.org_id                                                  --ORG_ID                           
                  ,rec_cur_detail.REF_CONTRAT_FOURNISSEUR                                 --REF_CONTRAT_FOURNISSEUR          
                  ,rec_cur_detail.DESCRIPTION_SPECIFIQUE_CONTRAT                          --DESCRIPTION_SPECIFIQUE_CONTRAT
                  ,rec_cur_detail.FLAG_MAIL_AVERTISSEMENT                                 --FLAG_MAIL_AVERTISSEMENT          
                  ,rec_cur_detail.DATE_EFFET                                              --DATE_EFFET                    
                  ,rec_cur_detail.RECONDUCTION_NUM                                        --RECONDUCTION_NUM                 
                  ,rec_cur_detail.REVISION_NUM                                            --REVISION_NUM                  
                  ,rec_cur_detail.commande_id                                                          --COMMANDE_ID
                  ,rec_cur_detail.COMMANDE_VERSION                                        --COMMANDE_VERSION                 
                  ,rec_cur_detail.DATE_RESILIATION                                        --DATE_RESILIATION                 
                  ,rec_cur_detail.ANNULATION                                              --ANNULATION   
                  );
                  
                  g_summary.inserted_detail_hist_rows := g_summary.inserted_detail_hist_rows + 1;
              END IF;        
  
            END LOOP; -- Fin cur_detail
                   
            -- Inserer les imputations
            FOR rec_cur_imput IN cur_imput(rec_cur_header.DOCUMENT_NUM) LOOP

              IF rec_cur_imput.DATA_TYPE = 'ACTUEL' THEN
              
                -- DKA_CONTRAT_SSTR_IMPUTATION
                INSERT INTO DKA_CONTRAT_SSTR_IMPUTATION
                (
                   CONTRAT_IMPUTATION_ID
                  ,PO_HEADER_ID
                  ,PROJECT_ID
                  ,TASK_ID
                  ,UNITE_OEUVRE
                  ,CREATED_BY
                  ,CREATION_DATE
                  ,LAST_UPDATED_BY
                  ,LAST_UPDATE_DATE
                  ,ORG_ID
                  ,LOCATION_ID
                  ,REVISION_NUM
                  ,EXPENDITURE_TYPE
                  ,CODE_COMBINATION_ID                 
                  )
                VALUES
                  (
                    rec_cur_imput.contrat_imputation_id         --CONTRAT_IMPUTATION_ID   
                   ,v_po_header_id                              --PO_HEADER_ID            
                   ,rec_cur_imput.project_id                    --PROJECT_ID 
                   ,rec_cur_imput.task_id                       --TASK_ID             
                   ,rec_cur_imput.UNITE_OEUVRE                  --UNITE_OEUVRE            
                   ,g_user_id                                   --CREATED_BY              
                   ,SYSDATE                                     --CREATION_DATE           
                   ,g_user_id                                   --LAST_UPDATED_BY         
                   ,SYSDATE                                     --LAST_UPDATE_DATE        
                   ,rec_cur_header.org_id                       --ORG_ID                  
                   ,rec_cur_imput.location_id                   --LOCATION_ID             
                   ,rec_cur_imput.REVISION_NUM                  --REVISION_NUM            
                   ,rec_cur_imput.EXPENDITURE_TYPE              --EXPENDITURE_TYPE        
                   ,rec_cur_imput.CODE_COMBINATION_ID           --CODE_COMBINATION_ID                  
                  );
                  
                  g_summary.inserted_imput_rows := g_summary.inserted_imput_rows + 1;
                  
              ELSIF (rec_cur_imput.DATA_TYPE = 'HISTO') THEN
                -- DKA_CONTAT_SSTR_IMPUT_ARCHI
                INSERT INTO DKA_CONTRAT_SSTR_IMPUT_ARCHI
                (
                   CONTRAT_IMPUTATION_ID
                  ,PO_HEADER_ID
                  ,PROJECT_ID
                  ,TASK_ID
                  ,UNITE_OEUVRE
                  ,CREATED_BY
                  ,CREATION_DATE
                  ,LAST_UPDATED_BY
                  ,LAST_UPDATE_DATE
                  ,ORG_ID
                  ,LOCATION_ID
                  ,REVISION_NUM
                  ,EXPENDITURE_TYPE
                  ,CODE_COMBINATION_ID
                  )
                VALUES
                  (
                    rec_cur_imput.contrat_imputation_id         --CONTRAT_IMPUTATION_ID    
                   ,v_po_header_id                              --PO_HEADER_ID            
                   ,rec_cur_imput.project_id                    --PROJECT_ID  
                   ,rec_cur_imput.task_id                       --TASK_ID            
                   ,rec_cur_imput.UNITE_OEUVRE                  --UNITE_OEUVRE            
                   ,g_user_id                                   --CREATED_BY              
                   ,SYSDATE                                     --CREATION_DATE           
                   ,g_user_id                                   --LAST_UPDATED_BY         
                   ,SYSDATE                                     --LAST_UPDATE_DATE        
                   ,rec_cur_header.org_id                       --ORG_ID                  
                   ,rec_cur_imput.location_id                   --LOCATION_ID             
                   ,rec_cur_imput.REVISION_NUM                  --REVISION_NUM            
                   ,rec_cur_imput.EXPENDITURE_TYPE              --EXPENDITURE_TYPE        
                   ,rec_cur_imput.CODE_COMBINATION_ID           --CODE_COMBINATION_ID  
                  );
                  g_summary.inserted_imput_hist_rows := g_summary.inserted_imput_hist_rows + 1;
              END IF;        
                             
            END LOOP; --Fin cur_imput
            
            UPDATE DKA_CONTRAT_SSTR_HEADER_TMP
            SET  STATUT               = 'T'
            WHERE document_num = rec_cur_header.document_num
            ;

            UPDATE DKA_CONTRAT_SSTR_DETAIL_TMP
            SET  STATUT               = 'T'
            WHERE document_num = rec_cur_header.document_num
            ;
            
            UPDATE DKA_CONTRAT_SSTR_IMPUT_TMP
            SET  STATUT               = 'T'
            WHERE document_num = rec_cur_header.document_num
            ;
            
        END LOOP;          

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
        INTO g_summary.rejected_header_rows
        FROM DKA_CONTRAT_SSTR_HEADER_TMP
        WHERE statut = 'E' 
        AND DATA_TYPE = 'ACTUEL' 
        ;

        SELECT count(1)
        INTO g_summary.rejected_detail_rows
        FROM DKA_CONTRAT_SSTR_DETAIL_TMP 
        WHERE statut = 'E' 
        AND DATA_TYPE = 'ACTUEL' 
        ;
        
        SELECT count(1)
        INTO g_summary.rejected_imput_rows
        FROM DKA_CONTRAT_SSTR_IMPUT_TMP 
        WHERE statut = 'E' 
        AND DATA_TYPE = 'ACTUEL' 
        ;

        SELECT count(1)
        INTO g_summary.rejected_header_hist_rows
        FROM DKA_CONTRAT_SSTR_HEADER_TMP
        WHERE statut = 'E' 
        AND DATA_TYPE = 'HISTO' 
        ;

        SELECT count(1)
        INTO g_summary.rejected_detail_hist_rows
        FROM DKA_CONTRAT_SSTR_DETAIL_TMP 
        WHERE statut = 'E' 
        AND DATA_TYPE = 'HISTO' 
        ;
        
        SELECT count(1)
        INTO g_summary.rejected_imput_hist_rows
        FROM DKA_CONTRAT_SSTR_IMPUT_TMP 
        WHERE statut = 'E' 
        AND DATA_TYPE = 'HISTO' 
        ;
        
        fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT,'BILAN :');
        fnd_file.put_line(fnd_file.OUTPUT,'-------');
        
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des en-têtes chargées dans la table spécifique           : '||TO_CHAR(g_summary.loaded_header_rows+g_summary.loaded_header_hist_rows)||' (Actuel : '||TO_CHAR(g_summary.loaded_header_rows)||', Historique : '||TO_CHAR(g_summary.loaded_header_hist_rows)||')');
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des détails chargés dans la table spécifique             : ' ||TO_CHAR(g_summary.loaded_detail_rows+g_summary.loaded_detail_hist_rows)||' (Actuel : '||TO_CHAR(g_summary.loaded_detail_rows)||', Historique : '||TO_CHAR(g_summary.loaded_detail_hist_rows)||')'); 
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des imputations chargées dans la table spécifique        : ' || TO_CHAR(g_summary.loaded_imput_rows+g_summary.loaded_imput_hist_rows)||' (Actuel : '||TO_CHAR(g_summary.loaded_imput_rows)||', Historique : '||TO_CHAR(g_summary.loaded_imput_hist_rows)||')'||CHR(10));

        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des en-têtes en rejet dans la table spécifique           : ' || TO_CHAR(g_summary.rejected_header_rows+g_summary.rejected_header_hist_rows)||' (Actuel : '||TO_CHAR(g_summary.rejected_header_rows)||', Historique : '||TO_CHAR(g_summary.rejected_header_hist_rows)||')');
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des détails en rejet  dans la table spécifique           : ' || TO_CHAR(g_summary.rejected_detail_rows+g_summary.rejected_detail_hist_rows)||' (Actuel : '||TO_CHAR(g_summary.rejected_detail_rows)||', Historique : '||TO_CHAR(g_summary.rejected_detail_hist_rows)||')');
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des imputations en rejet dans la table spécifique        : ' || TO_CHAR(g_summary.rejected_imput_rows+g_summary.rejected_imput_hist_rows)||' (Actuel : '||TO_CHAR(g_summary.rejected_imput_rows)||', Historique : '||TO_CHAR(g_summary.rejected_imput_hist_rows)||')'||CHR(10));

        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table PO_HEADERS_ALL                : ' || TO_CHAR(g_summary.inserted_header_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table PO_HEADERS_ARCHIVE_ALL        : ' || TO_CHAR(g_summary.inserted_header_hist_rows)); 
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table DKA_CONTRAT_SSTR              : ' || TO_CHAR(g_summary.inserted_detail_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table DKA_CONTRAT_SSTR_ARCHI        : ' || TO_CHAR(g_summary.inserted_detail_hist_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table DKA_CONTRAT_SSTR_IMPUTATION   : ' || TO_CHAR(g_summary.inserted_imput_rows)); 
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table DKA_CONTRAT_SSTR_IMPUT_ARCHI  : ' || TO_CHAR(g_summary.inserted_imput_hist_rows)||CHR(10));

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
     
    UPDATE DKA_CONTRAT_SSTR_HEADER_TMP
    SET  STATUT               = '-1'
        ,AGENT_ID             = NULL
        ,ORG_ID               = NULL
        ,VENDOR_ID            = NULL
        ,VENDOR_SITE_ID       = NULL
        ,SHIP_TO_LOCATION_ID  = NULL
        ,BILL_TO_LOCATION_ID  = NULL
        ,TERM_ID              = NULL
        ,STYLE_ID             = NULL
        ,ATTRIBUTE5_TRANSCO   = NULL
    WHERE STATUT = 'E';
    
    UPDATE DKA_CONTRAT_SSTR_DETAIL_TMP
    SET STATUT = '-1'
        ,CADRE_PO_HEADER_ID = NULL
        ,COMMANDE_ID        = NULL
        ,PERSON_ID          = NULL
    WHERE STATUT = 'E';
    
    UPDATE DKA_CONTRAT_SSTR_IMPUT_TMP
    SET  STATUT       = '-1'
        ,project_id   = NULL
        ,task_id      = NULL
        ,LOCATION_ID  = NULL
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


     Fnd_File.Put_Line(Fnd_File.LOG, '-> DKA_CONTRAT_SSTR_HEADER_TMP' );

     -- On supprime les enregistrements

     DELETE FROM DKA_CONTRAT_SSTR_HEADER_TMP;

     g_summary.purged_header_rows := SQL%ROWCOUNT;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows '||TO_CHAR(g_summary.purged_header_rows));
     
     Fnd_File.Put_Line(Fnd_File.LOG, '-> DKA_CONTRAT_SSTR_DETAIL_TMP' );
     DELETE FROM DKA_CONTRAT_SSTR_DETAIL_TMP;

     g_summary.purged_detail_rows := SQL%ROWCOUNT;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows '||TO_CHAR(g_summary.purged_detail_rows));

     Fnd_File.Put_Line(Fnd_File.LOG, '-> DKA_CONTRAT_SSTR_IMPUT_TMP' );
     DELETE FROM DKA_CONTRAT_SSTR_IMPUT_TMP;   

     g_summary.purged_imput_rows := SQL%ROWCOUNT;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows '||TO_CHAR(g_summary.purged_imput_rows));


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

  PROCEDURE main(p_errbuf     IN    OUT VARCHAR2,
                 p_retcode          OUT NUMBER,
                 p_reprise    IN        VARCHAR2
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
      
      Init(v_errbuf, v_retcode, p_reprise);
      
      IF v_retcode = 2 
      THEN
          p_Errbuf  := v_errbuf;
          p_retcode := v_retcode;
          RAISE Erreur_Programme;
      END IF;       

      IF g_summary.reprise_flag = 'N' THEN
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
      
      -- Lancement de l'insertion des données
      import_data(v_errbuf,
                   v_retcode
                   );
      IF v_retcode = 2 
      THEN
          RAISE Erreur_Programme;
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
      ELSIF (g_summary.rejected_header_rows > 0 OR g_summary.rejected_detail_rows > 0 OR g_summary.rejected_imput_rows > 0 OR v_warning)
      THEN
         p_errbuf := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
         p_retcode := 1;
      ELSIF (g_summary.loaded_header_rows = 0 AND g_summary.loaded_detail_rows = 0 AND g_summary.loaded_imput_rows = 0 AND g_summary.reprise_flag = 'N')
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
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_REPPOSSTRIMP_PKG.' || v_current_program_unit||CHR(10)||'A retourné     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           p_errbuf := SQLERRM;
  END main; 
 

END DKA_REPPOSSTRIMP_PKG;
/
SHOW ERRORS
EXIT