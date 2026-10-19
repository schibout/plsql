SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE BODY DKA_REPPOCMDIMP_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_REPPOCMDIMP_PKG.pkb  V2.8
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    Création du package de l'interface specifique des commandes fournisseurs
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
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    22/03/2016     OBN Creation
-- V1.1    21/07/2016     CDE Correction problème répertoire de chargement en dur
-- V1.2    29/07/2016     OBE Correction artf1980478 
-- V1.3    05/08/2016     OBE - Ajout de l'initialisation de l'environnement
--                            - Ajout du paramètre org_id au traitement standard
-- V1.4    01/09/2016     OBE - Correction de la récupération du site fournisseur - artf1999317 
--                            - Correction de l'initialisation de l'environnement - artf1999279 
-- V1.5    05/09/2016     OBE Correction artf2000961 
-- V1.6    22/09/2016     OBE Correction artf2010266  
-- V1.7    21/10/2016     MEG Demande de modification : artf2032033 
-- V1.8    26/10/2016     MEG Correction artf2034993 
-- V1.9    27/10/2016     MEG Correction artf2010266 
-- V2.0    02/11/2016     MEG Correction artf2036332, artf2036332 et artf2037795
-- V2.1    08/11/2016     MEG Correction artf2040524
-- V2.2    06/12/2016     RBE Correction artf2057398,artf2057402,artf2057707 et artf2057319
-- V2.3    12/12/2016     PBR Correction artf2063044: En cas d'erreur rencontré par le programme standard
--                                                    le traitement tombera en avertissement.
-- V2.4    20/12/2016     RBE Corrections artf2061678 
-- V2.5    26/01/2017	    NBO artf2090369 - RUN2 - DEFECT487 - Pb clé comptable sur commande reprise
-- V2.6    09/02/2017     NBO artf2098322: RUN3 - Suppression des contrôles qui calculent la clé comptable
-- V2.7    14/02/2017     YWA artf2101618 : URGENT - Prendre le premier demandeur de la ligne d'imputation
-- V2.8    17/02/2017     MEG artf2103342 : RUN3 - Flag erreur non alimenté lors du contrôle sur l'acheteur
-- V2.9    10/05/2017     YWA artf2149639 : REP005_EDB061_Extraire uniquement les commandes au statut "Approuvé" 
-- V2.10   01/08/2017     YWA artf2205542 : RDD Commandes - Ajout de contrôles 
-- V2.11   31/08/2017     YWA artf2205542 : RDD Commandes - Ajout de contrôles modif points 1 et 2
---------------------------------------------------------------------------------------------

 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    TYPE summary_typ IS RECORD 
    (
     loaded_rows                     NUMBER   -- Nb de Lignes chargées en table spécifique
    ,rejected_rows                   NUMBER   -- Nb de lignes rejetées en table spécifique
    ,loaded_header_rows              NUMBER   -- Nb de Lignes chargées en table spécifique des entetes
    ,loaded_lines_rows               NUMBER   -- Nb de Lignes chargées en table spécifique des lignes
    ,loaded_dist_rows                NUMBER   -- Nb de Lignes chargées en table spécifique des lignes de ventilations
    ,loaded_OI_header_rows           NUMBER   -- Nb de Lignes chargées dans la table OI des entetes
    ,loaded_OI_lines_rows            NUMBER   -- Nb de Lignes chargées dans la table OI des lignes
    ,loaded_OI_dist_rows             NUMBER   -- Nb de Lignes chargées dans la table OI des lignes de ventilations    
    ,rejected_headers_rows           NUMBER   -- Nb de Lignes rejetées en table spécifique des entetes
    ,rejected_lines_rows             NUMBER   -- Nb de Lignes rejetées en table spécifique des lignes
    ,rejected_dist_rows              NUMBER   -- Nb de Lignes rejetées en table spécifique des lignes de ventilations
    ,rejected_OI_headers_rows        NUMBER   -- Nb de Lignes rejetées en table d'OI des entetes
    ,rejected_OI_lines_rows          NUMBER   -- Nb de Lignes rejetées en table d'OI des lignes
    ,rejected_OI_dist_rows           NUMBER   -- Nb de Lignes rejetées en table d'OI des lignes de ventilations
    ,updated_rows_lines_sstr         NUMBER   -- Nb de Lignes mises à jour dans la table PO_LINE_LOCATIONS_ALL
    ,updated_rows_dist_sstr          NUMBER   -- Nb de Lignes mises à jour dans la table PO_DISTRIBUTIONS_ALL
    )
    ;

    TYPE  IdTabTyp      IS TABLE OF NUMBER(15)
    INDEX BY BINARY_INTEGER;
    
    g_summary                      summary_typ;

    g_user_id                      fnd_user.user_id%TYPE;
    g_login_id                     fnd_logins.login_id%TYPE;
    g_org_id                       hr_all_organization_units.organization_id%TYPE;
    g_request_id                   fnd_concurrent_requests.request_id%TYPE;
    g_int_request_id               fnd_concurrent_requests.request_id%TYPE;
    g_loader_request_id            fnd_concurrent_requests.request_id%TYPE;
    g_request_OI_vendor_id         fnd_concurrent_requests.request_id%TYPE;
    g_request_OI_site_id           fnd_concurrent_requests.request_id%TYPE;
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
        p_retcode   OUT      NUMBER
        )
  IS

    v_current_program_unit   VARCHAR2(30);
    v_step_program_error     VARCHAR2(1000);
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
        g_summary.loaded_rows                     := 0;
        g_summary.rejected_rows                   := 0;
        g_summary.loaded_header_rows              := 0;
        g_summary.loaded_lines_rows               := 0;
        g_summary.loaded_dist_rows                := 0;
        g_summary.loaded_OI_header_rows           := 0;
        g_summary.loaded_OI_lines_rows            := 0;
        g_summary.loaded_OI_dist_rows             := 0;        
        g_summary.rejected_headers_rows           := 0;
        g_summary.rejected_lines_rows             := 0;
        g_summary.rejected_dist_rows              := 0;
        g_summary.rejected_OI_headers_rows        := 0;
        g_summary.rejected_OI_lines_rows          := 0;
        g_summary.rejected_OI_dist_rows           := 0;
        g_summary.updated_rows_lines_sstr         := 0; 
        g_summary.updated_rows_dist_sstr          := 0;         


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
        v_conc_program_name        fnd_concurrent_programs.concurrent_program_name%TYPE;
        v_user_conc_program_name   fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
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
  
---------------------------------------------------------------------------------------
--  Nom           : ins_prog_message
--  Description   : Insere un message dans la table d'erreurs DKA_PROGRAM_MESSAGES et 
--                  Insere un message dans le journal
--     NB         :  cette proc s'exécute dans une transaction propre et fait un commit
-------------------------------------------------------------------------------------------------------------------
  PROCEDURE ins_prog_message(pn_request_id       IN NUMBER,
                             pv_prog_name        IN VARCHAR2,
                             pv_source           IN VARCHAR2 DEFAULT 'ETL',
                             pv_table_name       IN VARCHAR2,
                             pv_table_id         IN VARCHAR2,
                             pv_column_name      IN VARCHAR2,
                             pv_column_value     IN VARCHAR2,
                             pv_message_type     IN VARCHAR2 DEFAULT 'E',
                             pv_message_text     IN VARCHAR2) IS
    --PRAGMA AUTONOMOUS_TRANSACTION;
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
       message_text)
    VALUES
      (pn_request_id,   --request_id
       pv_prog_name,    --prog_name
       pv_source,       --source
       pv_table_name,   --table_name
       pv_table_id,     --table_id
       pv_column_name,  --column_name
       pv_column_value, --column_value
       pv_message_type, --message_type
       pv_message_text  --message_text
       );
  
    /* --RBE Optimisation
    IF pv_message_type = 'W' THEN
       Fnd_File.put_line(Fnd_File.LOG, 'AVERTISSEMENT: ' || pv_message_text);
    ELSE
       Fnd_File.put_line(Fnd_File.LOG, 'ERREUR: ' || pv_message_text);
    END IF;
    */
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20000,
                              'DKA_TOOLS_PKG.ins_prog_message:' || SQLERRM);
  END ins_prog_message;
  
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
      p_region  IN VARCHAR2,
      p_societe IN VARCHAR2
  )          
  RETURN NUMBER
  IS
    v_organization_id NUMBER;
   
  BEGIN  
 
     -- Recherche si le fournisseur est présent dans l'OI             
     BEGIN
        SELECT hr.ORGANIZATION_ID
        INTO   v_organization_id
        FROM   hr_operating_units hr
        WHERE  hr.NAME = p_region||p_societe
        ; 
     EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
         v_organization_id := NULL;
     END;

     ----- return value -----
     RETURN (v_organization_id);  
  
END get_organization_id;  

 /*
 *************************************************************************
 * PROCEDURE NAME : print_errors
 * 
 * DESCRIPTION
 *  Procédure pour écrire les anomalies du programme
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * 
 ************************************************************************
 */
 
  PROCEDURE print_errors
  IS 
  
    CURSOR cur_prog_mess IS
    SELECT *
    FROM  DKA_PROGRAM_MESSAGES
    WHERE REQUEST_ID = g_request_id
    ;
  
  BEGIN
  
        /*fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT, 'LISTE DES ANOMALIES :');
        fnd_file.put_line(fnd_file.OUTPUT, '----------------------');

        FOR msg IN cur_prog_mess LOOP
            Fnd_File.put_line (Fnd_File.output, '. '||msg.message_text);
        END LOOP;*/
        
        fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT, 'LISTE DES ANOMALIES :');
        fnd_file.put_line(fnd_file.OUTPUT, '---------------------');
        fnd_file.put_line(fnd_file.OUTPUT, 'Commande           Fichier                      Ligne    Message');
        fnd_file.put_line(fnd_file.OUTPUT, '---------------    ------------------------     -----    -------');

        FOR msg IN cur_prog_mess LOOP
           --Fnd_File.put_line (Fnd_File.output, '. '||msg.message_text);
           Fnd_File.put_line (Fnd_File.output, RPAD(NVL(msg.column_value,' '),15,' ') ||'    '||RPAD(NVL(msg.table_name,' '),24,' ')||'     '||RPAD(NVL(msg.table_id,' '),5,' ') ||'    ' || msg.message_text);
        END LOOP;        
  
  END print_errors;   

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
  PROCEDURE Launch_Loader(--p_directory         IN  VARCHAR2,
                          p_errbuf            OUT VARCHAR2,
                          p_retcode           OUT NUMBER
                          ) 
  IS
        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
        v_message                VARCHAR2 (100);
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
        g_loader_request_id          := Fnd_Request.submit_request (
                                             'DKA'                            -- APPL
                                            ,'DKA_LOADER_REPPOCMDIMP'         -- PROG
                                            ,NULL                             -- PROGRAM_NAME
                                            ,NULL                             -- START
                                            ,FALSE                            -- SUB_REQUEST
                                            --,p_directory                      -- Répertoire de chargement
                                            );
 
        IF g_loader_request_id = 0
        THEN
            p_retcode    := 2;
            fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de chargement du fichier a échoué' || CHR(10) ||
                                            'PROGRAMME  : DKA_LOADER_REPPOCMDIMP' || CHR(10) --||
                                            --'REPERTOIRE : ' || p_directory || CHR(10) --||
                                            --'FICHIER : ' || p_file_name || CHR(10) 
                                            );
            Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de chargement du fichier a échoué');
        ELSE
            COMMIT;
            Fnd_File.put_line(Fnd_File.LOG, '=> LOAD REQUEST ID= ' || g_loader_request_id);            
            Fnd_File.put_line(Fnd_File.LOG, '. Numéro du traitement de chargement du fichier : ' || g_loader_request_id);  
 
            -- Attente de la fin du traitement
            IF NOT (Fnd_Concurrent.wait_for_request (g_loader_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
            THEN                        
                p_errbuf  := v_Message;
                Fnd_file.put_line(Fnd_file.log, 'ERREUR : Attente de la fin du programme de chargement du fichier dépassée : Fin du traitement' || CHR(10) ||
                                                'MESSAGE : ' || v_Message || CHR(10) );  
            END IF;
                         
            IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') 
            THEN          
                Fnd_File.put_line(Fnd_File.LOG, 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
                Fnd_File.put_line(Fnd_File.OUTPUT, '. Statut de fin : ' || v_phase || '/' || v_status);

                /* RBE
                UPDATE PO_HEADERS_TMP
                SET    load_request_id = g_loader_request_id 
                WHERE  load_request_id IS NULL;
                */
                SELECT COUNT(*)
                INTO   g_summary.loaded_header_rows
                FROM   PO_HEADERS_TMP
                WHERE  load_request_id = g_loader_request_id 
                ;
                
                /* --RBE
                UPDATE PO_LINES_TMP
                SET    load_request_id = g_loader_request_id 
                WHERE  load_request_id IS NULL;
                */

                SELECT COUNT(*)
                INTO   g_summary.loaded_lines_rows
                FROM   PO_LINES_TMP
                WHERE  load_request_id = g_loader_request_id 
                ;
                
                /* --RBE
                UPDATE PO_DISTRIBUTIONS_TMP
                SET    load_request_id = g_loader_request_id 
                WHERE  load_request_id IS NULL;
                */

                SELECT COUNT(*)
                INTO   g_summary.loaded_dist_rows
                FROM   PO_DISTRIBUTIONS_TMP
                WHERE  load_request_id = g_loader_request_id 
                ;                
                Fnd_File.put_line(Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' Nbre enregistrements entetes charges => '||g_summary.loaded_header_rows);
                Fnd_File.put_line(Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' Nbre enregistrements lignes charges => '||g_summary.loaded_lines_rows);
                Fnd_File.put_line(Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' Nbre enregistrements ventilations charges => '||g_summary.loaded_dist_rows);                

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
            THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement de chargement en warning '|| g_loader_request_id);
                Fnd_File.put_line (Fnd_File.OUTPUT, 'Fin du traitement de chargement en warning '|| g_loader_request_id);
                p_retcode    := 1;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')  
            THEN
                p_retcode := 2;
                p_errbuf  := 'ERREUR : Fin anormale du traitement de chargement : '||v_Message;
  
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
 *  Procédure de transcodification et de validation des données
 *
 * PARAMETERS
 * ==========
 * NAME                 DESCRIPTION
.* -------------------- ---------------------------------------------------
 * p_errbuf            Retour de message éventuel
 * p_retcode           Statut du traitement en sortie
 ************************************************************************
 */  
 
  PROCEDURE validate_data(p_errbuf        OUT VARCHAR2,
                          p_retcode       OUT NUMBER
                          ) 
  IS
  
  
    CURSOR cur_ent_cmd IS
      SELECT *
      FROM PO_HEADERS_TMP
      WHERE 1=1 --LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id) --RBE
      AND STATUT IS NULL
    ;
    
    CURSOR cur_lig_cmd (p_doc_num in VARCHAR2) IS
      SELECT *
      FROM  PO_LINES_TMP   
      WHERE DOCUMENT_NUM = p_doc_num
      --AND LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id) --RBE
      AND STATUT IS NULL
      FOR UPDATE OF STATUT, 
                    category_id,
                    QUANTITY,
                    UOM_CODE,
                    SHIP_TO_LOCATION,
                    LAST_UPDATE_DATE,
                    LAST_UPDATED_BY
    ;    
    
    CURSOR cur_vent_cmd (p_doc_num IN VARCHAR2, p_line_num IN NUMBER, p_shipment_num IN NUMBER) IS
      SELECT *
      FROM  PO_DISTRIBUTIONS_TMP    
      WHERE DOCUMENT_NUM = p_doc_num
      AND   LINE_NUM     = p_line_num
      AND   SHIPMENT_NUM = p_shipment_num
      --AND   LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id) --RBE
      AND STATUT IS NULL
      FOR UPDATE OF STATUT, 
                    QUANTITY_ORDERED,
                    SET_OF_BOOKS_ID,
                    CHARGE_ID,
                    VARIANCE_ID,
                    ACCRUAL_ID,
                    PROJECT,
                    TASK,
                    expenditure_organization,
                    DELIVER_TO_LOCATION,
                    DELIVER_TO_PERSON,
                    LAST_UPDATE_DATE,
                    LAST_UPDATED_BY,
                    EXPENDITURE_ITEM_DATE
    ;
    
    v_org_id                    NUMBER;
    --v_approval_statut           VARCHAR2(25); -- RBE artf2061678
    v_quantity                  NUMBER;
    v_quantity_ordered          NUMBER;
    v_STYLE_ID                  NUMBER;
    v_vendor_id                 NUMBER;
    v_agent_id                  NUMBER;        
    v_vendor_site_id            NUMBER;
    v_category_id               NUMBER;        
    
    v_cat_seg2                  VARCHAR2(10);
    v_cat_seg3                  VARCHAR2(10);        
    v_cat_seg4                  VARCHAR2(10);        
    v_cat_seg5                  VARCHAR2(10);        

    v_bill_to_location          VARCHAR2(60);
    v_header_ship_to_location   VARCHAR2(60);
    v_line_ship_to_location     VARCHAR2(60);
    v_deliver_to_location       VARCHAR2(60);        
    
    v_exp_org                   VARCHAR2(60);        
    v_project                   VARCHAR2(30);      
    v_project_name              VARCHAR2(30); 
    v_project_id                NUMBER;       --RBE  
    v_task_id                   NUMBER;       --RBE       
    v_task                      VARCHAR2(30);                        
    v_uom_code                  VARCHAR2(3);
    v_region                    VARCHAR2(10);
    
    v_charge_id                 VARCHAR2(300);
    v_accrual_id                VARCHAR2(300);
    v_variance_id               VARCHAR2(300);
    v_ccf                       VARCHAR2(300);        
    v_payment_terms             VARCHAR2(100);
    v_agent_name                VARCHAR2(200);
    v_demandeur                 VARCHAR2(240);
    
    v_bill_to_location_id       NUMBER;        
    v_set_of_books_id           NUMBER;    
    
    v_flag_erreur_entete        BOOLEAN;
    v_flag_erreur_lines         BOOLEAN;
    v_flag_erreur_dist          BOOLEAN;
    v_flag_exist_lines          BOOLEAN;
  
    vd_need_by_date             DATE;
    
    v_count                     NUMBER:= 0;
    vv_t_start_date             DATE;
    v_t_start_date              DATE;
    vv_cf_date_from             DATE;
    v_cf_date_from              DATE;
    v_t_completion_date         DATE;
    v_cf_date_to                DATE;
  
  BEGIN
  
      FOR ent_cmd IN cur_ent_cmd LOOP
          v_count:= v_count + 1;
          v_flag_erreur_entete := FALSE;    
          v_flag_exist_lines   := FALSE;
          
          --Fnd_File.put_line (Fnd_File.LOG, '>>>>>----------------------------------<<<<<'); --RBE Optimisation
          --Fnd_File.put_line (Fnd_File.LOG, '--------------------------------------------'); --RBE Optimisation
          --Fnd_File.put_line (Fnd_File.LOG, 'COMMANDE N° : '||ent_cmd.document_num);         --RBE Optimisation
          --Fnd_File.put_line (Fnd_File.LOG, '--------------------------------------------'); --RBE Optimisation
          --Fnd_File.put_line (Fnd_File.LOG, '>>>>>----------------------------------<<<<<'); --RBE Optimisation
          
          --Fnd_File.put_line (Fnd_File.LOG, 'Transcodification de la région');               --RBE Optimisation
          
          -- Transcodification de la région
          DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '008_REGIONS',
                                    pv_column_01    => ent_cmd.REGION,
                                    pv_out_01       => v_region);           
          
          --Fnd_File.put_line (Fnd_File.LOG, 'Récupération de l''organization_id');          --RBE Optimisation
          
          -- RG-IMP02 : Récupération de l'org id 
          v_org_id := get_organization_id(v_region,ent_cmd.SOCIETE);
          
          IF v_org_id IS NULL THEN
            -- Gestion d'anomalies
            v_flag_erreur_entete := TRUE;
            /*DKA_TOOLS_PKG.*/ins_prog_message(g_request_id
                                          ,'DKA_REPPOCMDIMP_PKG'
                                          ,'ETL'
                                          ,'PO_HEADERS_TMP'
                                          --,NULL
                                          ,ent_cmd.logical_line_num
                                          ,'ORG_ID'
                                          ,ent_cmd.document_num
                                          ,'E'
                                          ,'L''org id pour la commande '||ent_cmd.document_num||' est introuvable'
                                          );
             --g_summary.rejected_headers_rows :=  g_summary.rejected_headers_rows + 1;
          
          END IF; 
          
          --Fnd_File.put_line (Fnd_File.LOG, 'Détérmination du nouveau statut d''approbation'); --RBE Optimisation
          
         /* -- RBE artf2061678
         -- RG-IMP03 : Détérmination du nouveau statut d'approbation
        
          IF ent_cmd.approval_status IN ('REQUIRES REAPPROVAL','IN PROCESS','INCOMPLETE','REJECTED') THEN
              v_approval_statut := 'INCOMPLETE';
          ELSIF ent_cmd.approval_status IN ('APPROVED') THEN
              v_approval_statut := 'APPROVED';
          ELSE
              v_approval_statut := 'INCOMPLETE';
          END IF;   
          */ -- RBE artf2061678 
          
          --Fnd_File.put_line (Fnd_File.LOG, 'Récupération de l''id fournisseur et code site fournisseur '); --RBE Optimisation
          
          -- Récupération de l'id fournisseur et code site fournisseur           
          BEGIN
          
            SELECT VENDOR_ID
              INTO v_vendor_id
              FROM po_vendors
             WHERE vendor_name = ent_cmd.vendor_name
               AND ROWNUM = 1;
          
          EXCEPTION
            WHEN OTHERS THEN
              v_flag_erreur_entete := TRUE;
              --Fnd_File.put_line(Fnd_File.LOG, 'L''identifiant du fournisseur introuvable'); 
              /*DKA_TOOLS_PKG.*/ins_prog_message(g_request_id
                                            ,'DKA_REPPOCMDIMP_PKG'
                                            ,'ETL'
                                            ,'PO_HEADERS_TMP'
                                            --,NULL
                                            ,ent_cmd.logical_line_num
                                            ,'vendor_id'
                                            ,ent_cmd.document_num
                                            ,'E'
                                            ,'L''identifiant du fournisseur de la commande '||ent_cmd.document_num||' est introuvable'
                                            );
              --g_summary.rejected_headers_rows :=  g_summary.rejected_headers_rows + 1;
          END;
          
          BEGIN
          
            SELECT vendor_site_id
              INTO v_vendor_site_id
              FROM po_vendor_sites_all
             WHERE vendor_id in (v_vendor_id)
               AND vendor_site_code LIKE
                   SUBSTR(ent_cmd.VENDOR_SITE_CODE, 5) || '%' -- V1.4
                  --AND   vendor_site_code = ent_cmd.VENDOR_SITE_CODE
               AND purchasing_site_flag = 'Y' -- V1.4
               AND org_id = v_org_id
               AND ROWNUM = 1 -- V1.4
            ;

          EXCEPTION
            WHEN OTHERS THEN  
              v_flag_erreur_entete := TRUE;
              --Fnd_File.put_line(Fnd_File.LOG, 'L''identifiant du site fournisseur introuvable');  
              /*DKA_TOOLS_PKG.*/ins_prog_message(g_request_id
                                            ,'DKA_REPPOCMDIMP_PKG'
                                            ,'ETL'
                                            ,'PO_HEADERS_TMP'
                                            --,NULL
                                            ,ent_cmd.logical_line_num
                                            ,'vendor_site_id'
                                            ,ent_cmd.document_num
                                            ,'E'
                                            ,'L''identifiant du site fournisseur de la commande '||ent_cmd.document_num||' est introuvable'
                                            );
               --g_summary.rejected_headers_rows :=  g_summary.rejected_headers_rows + 1;                         
          END;
          
          --Fnd_File.put_line (Fnd_File.LOG, 'Transcodification de bill_to_location'); --RBE Optimisation
          -- Récupération de bill_to_location_id
          
          DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '016_LIEUX_LIV_FACT',
                                          pv_column_01    => ent_cmd.BILL_TO_LOCATION,
                                          pv_out_01       => v_bill_to_location);   
                                      

          --Fnd_File.put_line (Fnd_File.LOG, 'Transcodification du SHIP_TO_LOCATION de l''entete'); --RBE Optimisation
          
          DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '016_LIEUX_LIV_FACT',
                                          pv_column_01    => ent_cmd.SHIP_TO_LOCATION,
                                          pv_out_01       => v_header_ship_to_location);                              

                                            
          --Fnd_File.put_line (Fnd_File.LOG, 'Récupération de bill_to_location_id'); --RBE Optimisation
          
          BEGIN
          
            SELECT LOCATION_ID 
            INTO v_bill_to_location_id
            FROM HR_LOCATIONS_ALL 
            WHERE location_code = v_bill_to_location;
                   
          
          EXCEPTION
            WHEN OTHERS THEN  
                v_flag_erreur_entete := TRUE;
                --Fnd_File.put_line(Fnd_File.LOG, 'bill_to_location_id introuvable');     
                /*DKA_TOOLS_PKG.*/ins_prog_message(g_request_id
                                              ,'DKA_REPPOCMDIMP_PKG'
                                              ,'ETL'
                                              ,'PO_HEADERS_TMP'
                                              --,NULL
                                              ,ent_cmd.logical_line_num
                                              ,'bill_to_location_id'
                                              ,ent_cmd.document_num
                                              ,'E'
                                              ,'L''identifiant du lieu de facturation de la commande '||ent_cmd.document_num||' est introuvable'
                                              );
                 --g_summary.rejected_headers_rows :=  g_summary.rejected_headers_rows + 1;                   
          END;            
          
          
          -- Récupération de AGENT_ID
          --Fnd_File.put_line (Fnd_File.LOG, 'Récupération de agent_id'); 
          
          --V1.7: ajout de l'acheteur generique
          BEGIN
          
            SELECT ppf.person_id
              INTO v_agent_id
              FROM per_people_f ppf
             WHERE ppf.full_name = ent_cmd.agent_name
               AND sysdate BETWEEN NVL(ppf.effective_start_date,sysdate) AND NVL(ppf.effective_end_date,sysdate);
          
            v_agent_name := ent_cmd.agent_name;
          
          EXCEPTION
            WHEN OTHERS THEN  
            
               --V1.7 
                /*
                v_flag_erreur_entete := TRUE;
                Fnd_File.put_line(Fnd_File.LOG, 'agent_id introuvable');     
                DKA_TOOLS_PKG.ins_prog_message(g_request_id
                                              ,'DKA_REPPOCMDIMP_PKG'
                                              ,'ETL'
                                              ,'PO_HEADERS_TMP'
                                              --,NULL
                                              ,ent_cmd.logical_line_num
                                              ,'bill_to_location_id'
                                              ,ent_cmd.document_num
                                              ,'E'
                                              ,'L''identifiant de l''agent de la commande '||ent_cmd.document_num||' est introuvable'
                                              );
                 */
                v_agent_name := 'REPRISE, REPRISE';
                
                SELECT person_id
                  INTO v_agent_id
                  FROM per_people_f ppf
                 WHERE full_name = v_agent_name
                   AND sysdate BETWEEN NVL(ppf.effective_start_date,sysdate) AND NVL(ppf.effective_end_date,sysdate);
                
                --Fnd_File.put_line(Fnd_File.LOG, 'agent_id introuvable (agent_name: '||ent_cmd.agent_name||')');     
                
                 --g_summary.rejected_headers_rows :=  g_summary.rejected_headers_rows + 1;                   
          END; 
             
          BEGIN
          
            SELECT ppf.person_id
              INTO v_agent_id
              FROM per_people_f ppf, po_agents pa
             WHERE ppf.full_name = v_agent_name
               AND pa.agent_id = ppf.person_id
               AND sysdate BETWEEN NVL(pa.start_date_active,sysdate) AND NVL(pa.end_date_active,sysdate)
               AND sysdate BETWEEN NVL(ppf.effective_start_date,sysdate) AND NVL(ppf.effective_end_date,sysdate);
          
          EXCEPTION
          WHEN OTHERS THEN
          
            v_flag_erreur_entete := TRUE; --artf2103342
            ins_prog_message(g_request_id
                  ,'DKA_REPPOCMDIMP_PKG'
                  ,'ETL'
                  ,'PO_HEADERS_TMP'
                  --,NULL
                  ,ent_cmd.logical_line_num
                  ,'AGENT_NAME'
                  ,ent_cmd.document_num
                  ,'E'
                  ,'L''acheteur '||ent_cmd.agent_name||' n''existe pas en tant qu''acheteur'
                  );
          END;
                    
          -- Vérification du payment_terms
          --Fnd_File.put_line (Fnd_File.LOG, 'Récupération de payment_terms'); --RBE Optimisation
          
          BEGIN
          
            SELECT 'EXIST'
            INTO v_payment_terms
            FROM AP_TERMS
            WHERE name = ent_cmd.payment_terms;
                      
            
          EXCEPTION
            WHEN OTHERS THEN  
                v_flag_erreur_entete := TRUE;
                --Fnd_File.put_line(Fnd_File.LOG, 'payment_terms introuvable');     
                /*DKA_TOOLS_PKG.*/ins_prog_message(g_request_id
                                              ,'DKA_REPPOCMDIMP_PKG'
                                              ,'ETL'
                                              ,'PO_HEADERS_TMP'
                                              --,NULL
                                              ,ent_cmd.logical_line_num
                                              ,'PAYMENT_TERMS'
                                              ,ent_cmd.document_num
                                              ,'E'
                                              ,'La valeur spécifié pour PAYMENT_TERMS est non valide'
                                              );
                 --g_summary.rejected_headers_rows :=  g_summary.rejected_headers_rows + 1;                   
          END;           
        
        
        --YWA artf2205542 
         -- récupérer l'ID du lieu de livraison de l'entête de commande
        --Fnd_File.put_line (Fnd_File.LOG, 'récupérer l''ID du lieu de livraison de l'entête de commande'); -
        BEGIN
          SELECT location_code 
          INTO v_header_ship_to_location
          FROM hr_locations 
          WHERE location_code =  ent_cmd.ship_to_location;                
          
        EXCEPTION
          WHEN OTHERS THEN

            v_flag_erreur_entete := TRUE;
            /*DKA_TOOLS_PKG.*/ins_prog_message(g_request_id
                                          ,'DKA_REPPOCMDIMP_PKG'
                                          ,'ETL'
                                          ,'PO_HEADERS_TMP'
                                          --,NULL
                                          ,ent_cmd.logical_line_num
                                          ,'SHIP_TO_LOCATION'
                                          ,ent_cmd.document_num
                                          ,'E'
                                          ,'Le lieu '||ent_cmd.ship_to_location ||' n''existe pas, vous devez le paramétrer'
                                          );
             --g_summary.rejected_lines_rows :=  g_summary.rejected_lines_rows + 1;                         
        END;            
          ----------------------------------------------------------------
          -- Transcodification des données de la table PO_LINES_INTERFACE
          ----------------------------------------------------------------
    
          FOR lig_cmd IN cur_lig_cmd(ent_cmd.document_num) LOOP
              v_flag_erreur_lines := FALSE;
              v_flag_exist_lines  := TRUE;
              
            --Fnd_File.put_line (Fnd_File.LOG, '--------------------------------------------'); --RBE Optimisation
            --Fnd_File.put_line (Fnd_File.LOG, 'COMMANDE N° : '||ent_cmd.document_num||' LINE NUM : '||lig_cmd.line_num); --RBE Optimisation
            --Fnd_File.put_line (Fnd_File.LOG, '--------------------------------------------');              --RBE Optimisation
              
             --RG-IMP04 : Transcodification de la catégorie 
             --Fnd_File.put_line (Fnd_File.LOG, 'Transcodification de la catégorie'); --RBE Optimisation
             DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '013_CATEGORIES_ACHATS',
                                 pv_column_01    => lig_cmd.CATEGORY_SEGMENT2,
                                 pv_column_02    => lig_cmd.CATEGORY_SEGMENT3,
                                 pv_column_03    => lig_cmd.CATEGORY_SEGMENT4,
                                 pv_column_04    => lig_cmd.CATEGORY_SEGMENT5,
                                 pv_out_01       => v_cat_seg2,
                                 pv_out_02       => v_cat_seg3,
                                 pv_out_03       => v_cat_seg4,
                                 pv_out_04       => v_cat_seg5);
             

               --Fnd_File.put_line (Fnd_File.LOG, 'Récupération du category_id'); --RBE Optimisation
               BEGIN

                SELECT category_id
                INTO v_category_id
                FROM mtl_categories_b
                WHERE segment1 = v_cat_seg2
                AND segment2   = v_cat_seg3
                AND segment3   = v_cat_seg4
                AND segment4   = v_cat_seg5
                ;                           
               
               EXCEPTION
                  WHEN OTHERS THEN  
                      --Fnd_File.put_line(Fnd_File.LOG, 'category_id introuvable');     
                      v_flag_erreur_lines := TRUE;
                      /*DKA_TOOLS_PKG.*/ins_prog_message(g_request_id
                                                    ,'DKA_REPPOCMDIMP_PKG'
                                                    ,'ETL'
                                                    ,'PO_LINES_TMP'
                                                    --,NULL
                                                    ,lig_cmd.logical_line_num
                                                    ,'CATEGORY_ID'
                                                    ,ent_cmd.document_num
                                                    ,'E'
                                                    ,'L''identifiant de la catégorie de la commande '||ent_cmd.document_num||' est introuvable'
                                                    );
                       --g_summary.rejected_lines_rows :=  g_summary.rejected_lines_rows + 1;                   
                END; 

                --Fnd_File.put_line (Fnd_File.LOG, 'Transcodification du lieu de livraison');--RBE Optimisation
                -- Transcodification du lieu de livraison            
                 DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '016_LIEUX_LIV_FACT',
                                                 pv_column_01    => lig_cmd.SHIP_TO_LOCATION,
                                                 pv_out_01       => v_line_ship_to_location);             
                
                
                --Fnd_File.put_line (Fnd_File.LOG, 'Calcul de la quantité commandée'); --RBE Optimisation
                -- RG-IMP05 : Calcul de la quantité commandée          
                IF lig_cmd.document_num NOT LIKE '%ST%' THEN
                    v_quantity := lig_cmd.QUANTITY - lig_cmd.QUANTITY_BILLED;
                ELSE
                    v_quantity := lig_cmd.QUANTITY;
                END IF;        
       
                
                -- Récupération du code UOM_CODE
                --Fnd_File.put_line (Fnd_File.LOG, 'Récupération du code UOM_CODE'); --RBE Optimisation
                BEGIN
                  SELECT UOM_CODE
                  INTO v_uom_code
                  FROM po_units_of_measure_val_v
                  WHERE UNIT_OF_MEASURE = lig_cmd.UOM_CODE
                  ;                
                  
                EXCEPTION
                  WHEN OTHERS THEN
                    --v_uom_code := NULL;
                    v_flag_erreur_lines := TRUE;
                    /*DKA_TOOLS_PKG.*/ins_prog_message(g_request_id
                                                  ,'DKA_REPPOCMDIMP_PKG'
                                                  ,'ETL'
                                                  ,'PO_LINES_TMP'
                                                  --,NULL
                                                  ,lig_cmd.logical_line_num
                                                  ,'UOM_CODE'
                                                  ,ent_cmd.document_num
                                                  ,'E'
                                                  ,'UOM_CODE de la commande est introuvable'
                                                  );
                     --g_summary.rejected_lines_rows :=  g_summary.rejected_lines_rows + 1;                         
                END;              
                
                --artf2037795
                SELECT DECODE(SIGN(NVL(lig_cmd.need_by_date,
                                       to_date('01/01/1951',
                                               'DD/MM/YYYY HH24:MI:SS')) -
                                   trunc(sysdate)),
                              -1, trunc(sysdate),
                              lig_cmd.need_by_date) 
                  INTO vd_need_by_date 
                FROM dual;
                
                --YWA artf2205542  
                -- récupérer l'ID du lieu de livraison de la ligne de commande 
                --Fnd_File.put_line (Fnd_File.LOG, 'récupérer l''ID du lieu de livraison de la ligne de commande'); -
                BEGIN
                  SELECT location_code 
                  INTO v_line_ship_to_location
                  FROM hr_locations 
                  WHERE location_code =  lig_cmd.ship_to_location;                
                  
                EXCEPTION
                  WHEN OTHERS THEN

                    v_flag_erreur_lines := TRUE;
                    /*DKA_TOOLS_PKG.*/ins_prog_message(g_request_id
                                                  ,'DKA_REPPOCMDIMP_PKG'
                                                  ,'ETL'
                                                  ,'PO_LINES_TMP'
                                                  --,NULL
                                                  ,lig_cmd.logical_line_num
                                                  ,'SHIP_TO_LOCATION'
                                                  ,ent_cmd.document_num
                                                  ,'E'
                                                  ,'Le lieu '||lig_cmd.ship_to_location ||' n''existe pas, vous devez le paramétrer'
                                                  );
                     --g_summary.rejected_lines_rows :=  g_summary.rejected_lines_rows + 1;                         
                END;            
                
                
                ---------------------------------------------------------------------------------------
                -- Transcodification des données de la table PO_DISTRIBUTIONS_INTERFACE
                ---------------------------------------------------------------------------------------                  

                FOR vent_cmd IN cur_vent_cmd(lig_cmd.document_num, lig_cmd.line_num, lig_cmd.shipment_num) LOOP
                      v_flag_erreur_dist := FALSE;
                      
                      --Fnd_File.put_line (Fnd_File.LOG, '--------------------------------------------');  --RBE Optimisation
                      --Fnd_File.put_line (Fnd_File.LOG, 'COMMANDE N° : '||ent_cmd.document_num||' LINE NUM : '||lig_cmd.line_num||' DISTRIBUTION_NUM : '||vent_cmd.distribution_num); --RBE Optimisation
                      --Fnd_File.put_line (Fnd_File.LOG, '--------------------------------------------');                                    --RBE Optimisation
                      
                      
                      
                      --Fnd_File.put_line (Fnd_File.LOG, 'Calcul de la quantité commandée'); --RBE Optimisation
                      -- RG-IMP05 : Calcul de la quantité commandée            
                      IF vent_cmd.document_num NOT LIKE '%ST%' THEN
                          v_quantity_ordered := vent_cmd.QUANTITY_ORDERED - vent_cmd.QUANTITY_BILLED;
                      ELSE
                          v_quantity_ordered := vent_cmd.QUANTITY_ORDERED;
                      END IF;                               
                      
                      
                      --Fnd_File.put_line (Fnd_File.LOG, 'Récupération du set of book id'); --RBE Optimisation
                      -- Récupération du set of book id
                      BEGIN
         
                        SELECT set_of_books_id
                        INTO  v_set_of_books_id
                        FROM hr_operating_units
                        WHERE organization_id = v_org_id
                        ;
                        
                      
                      EXCEPTION
                        WHEN OTHERS THEN
                          v_flag_erreur_dist := TRUE;
                          /*DKA_TOOLS_PKG.*/ins_prog_message(g_request_id
                                    ,'DKA_REPPOCMDIMP_PKG'
                                    ,'ETL'
                                    ,'PO_DISTRIBUTIONS_TMP'
                                    --,NULL
                                    ,vent_cmd.logical_line_num
                                    ,'SET_OF_BOOKS_ID'
                                    ,ent_cmd.document_num
                                    ,'E'
                                    ,'L''identifiant du livre comptable de la commande '||ent_cmd.document_num||' est introuvable'
                                    );                    
                          --g_summary.rejected_dist_rows := g_summary.rejected_dist_rows + 1; 
                      END; 
                      
                      --Fnd_File.put_line (Fnd_File.LOG, 'Récupération de l''identifiant du compte d''imputation'); --RBE Optimisation
                      
                      -- 09/02/17 - NBO - artf2098322: RUN3 - Suppression des contrôles qui calculent la clé comptable
/*                      BEGIN
                      -- RG-IMP06
                      -- Récupération de l'identifiant du compte d'imputation
                      v_ccf := dka_rep_transco_pkg.get_cle_transco_f (vent_cmd.charge_segment1,
                                                                              vent_cmd.charge_segment2,
                                                                              vent_cmd.charge_segment3,
                                                                              vent_cmd.charge_segment4,
                                                                              vent_cmd.charge_segment6,
                                                                              vent_cmd.charge_segment7,
                                                                              vent_cmd.charge_segment8,
                                                                              vent_cmd.charge_segment9,
                                                                              vent_cmd.charge_segment10);                                                                         
                                                                              
                      v_charge_id := TO_NUMBER(v_ccf);                                                                      
                                                                
                      EXCEPTION
                        WHEN OTHERS THEN
                          v_flag_erreur_dist := TRUE;
                          \*DKA_TOOLS_PKG.*\ins_prog_message(g_request_id
                                    ,'DKA_REPPOCMDIMP_PKG'
                                    ,'ETL'
                                    ,'PO_DISTRIBUTIONS_TMP'
                                    --,NULL
                                    ,vent_cmd.logical_line_num
                                    ,'CHARGE_ID'
                                    ,ent_cmd.document_num
                                    ,'E'
                                    ,'Erreur : Compte Imputation. Message : '||v_ccf
                                    );              
                                    --g_summary.rejected_dist_rows := g_summary.rejected_dist_rows + 1;                 
                      END;*/
                      

                      --Fnd_File.put_line (Fnd_File.LOG, 'Récupération de l''identifiant du compte de provision'); --RBE Optimisation
                      -- 09/02/17 - NBO - artf2098322: RUN3 - Suppression des contrôles qui calculent la clé comptable
/*                      BEGIN
                        -- Récupération de l'identifiant du compte de provision
                        v_ccf := dka_rep_transco_pkg.get_cle_transco_f (vent_cmd.accrual_segment1,
                                                                                vent_cmd.accrual_segment2,
                                                                                vent_cmd.accrual_segment3,
                                                                                vent_cmd.accrual_segment4,
                                                                                vent_cmd.accrual_segment6,
                                                                                vent_cmd.accrual_segment7,
                                                                                vent_cmd.accrual_segment8,
                                                                                vent_cmd.accrual_segment9,
                                                                                vent_cmd.accrual_segment10);     
                        v_accrual_id := TO_NUMBER(v_ccf);     
                              
                      EXCEPTION
                        WHEN OTHERS THEN
                          v_flag_erreur_dist := TRUE;
                          \*DKA_TOOLS_PKG.*\ins_prog_message(g_request_id
                                    ,'DKA_REPPOCMDIMP_PKG'
                                    ,'ETL'
                                    ,'PO_DISTRIBUTIONS_TMP'
                                    --,NULL
                                    ,vent_cmd.logical_line_num
                                    ,'CHARGE_ID'
                                    ,ent_cmd.document_num
                                    ,'E'
                                    ,'Erreur : Compte provision. Message : '||v_ccf
                                    );              
                                    --g_summary.rejected_dist_rows := g_summary.rejected_dist_rows + 1;                 
                      END;              
*/
                      
                      --Fnd_File.put_line (Fnd_File.LOG, 'Récupération de l''identifiant du compte d''ecart'); --RBE Optimisation
                      -- 09/02/17 - NBO - artf2098322: RUN3 - Suppression des contrôles qui calculent la clé comptable
/*                      BEGIN
                          -- Récupération de l'identifiant du compte d'ecart              
                          v_ccf := dka_rep_transco_pkg.get_cle_transco_f (vent_cmd.variance_segment1,
                                                                                  vent_cmd.variance_segment2,
                                                                                  vent_cmd.variance_segment3,
                                                                                  vent_cmd.variance_segment4,
                                                                                  vent_cmd.variance_segment6,
                                                                                  vent_cmd.variance_segment7,
                                                                                  vent_cmd.variance_segment8,
                                                                                  vent_cmd.variance_segment9,
                                                                                  vent_cmd.variance_segment10);  
                          v_variance_id := TO_NUMBER(v_ccf);  
                                               
                      EXCEPTION
                        WHEN OTHERS THEN
                          v_flag_erreur_dist := TRUE;
                          \*DKA_TOOLS_PKG.*\ins_prog_message(g_request_id
                                    ,'DKA_REPPOCMDIMP_PKG'
                                    ,'ETL'
                                    ,'PO_DISTRIBUTIONS_TMP'
                                    --,NULL
                                    ,vent_cmd.logical_line_num
                                    ,NULL
                                    ,ent_cmd.document_num
                                    ,'E'
                                    ,'Erreur : Compte ecart. Message : '||v_ccf
                                    );              
                                    --g_summary.rejected_dist_rows := g_summary.rejected_dist_rows + 1;                 
                      END; */                   

                     --Fnd_File.put_line (Fnd_File.LOG, 'Transcodification du projet'); --RBE Optimisation
                      -- RG-IMP07
                     DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '014_PROJETS',
                                         pv_column_01    => vent_cmd.project_code,
                                         pv_out_01       => v_project,
                                         pv_out_02       => v_task);
                     
                     -- Récupéreation du nom du projet
                     BEGIN
                     
                       SELECT ppa.name,ppa.project_id
                         INTO v_project_name,v_project_id
                         FROM pa_projects_all ppa
                        WHERE ppa.segment1 = v_project;
                     
                     EXCEPTION
                       WHEN OTHERS THEN
                          v_project_name := NULL;
                          v_project_id   := NULL;
                           
                          v_flag_erreur_dist := TRUE;
                          ins_prog_message(g_request_id
                                        ,'DKA_REPPOCMDIMP_PKG'
                                        ,'ETL'
                                        ,'PO_DISTRIBUTIONS_TMP'
                                        --,NULL
                                        ,vent_cmd.logical_line_num
                                        ,NULL
                                        ,ent_cmd.document_num
                                        ,'E'
                                        ,'Impossible de récupérer le nom du projet ('||v_project||')'
                                        );              
                          --g_summary.rejected_dist_rows := g_summary.rejected_dist_rows + 1; 
                     
                     END;
                     
                     --Fnd_File.put_line (Fnd_File.LOG, 'Transcodification de expenditure_organization'); --RBE Optimisation
                      -- RG-IMP08  

                     --< V1.6
                     /*
                     DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '015_ORG_EXPENDITURES',
                                                     pv_column_01    => vent_cmd.expenditure_organization,
                                                     pv_out_01       => v_exp_org);   */
                      BEGIN
                        /*
                        SELECT b.NAME
                        INTO v_exp_org
                        FROM PA_PROJECTS_ALL a,
                          HR_OPERATING_UNITS b
                        WHERE a.segment1 = v_project
                        AND a.ORG_ID = b.ORGANIZATION_ID;
                        */
                        
                        SELECT org.name,org.date_from ,org.date_to -- YWA artf2205542 
                          INTO v_exp_org,v_cf_date_from,v_cf_date_to
                          FROM PA_PROJECTS_ALL a, 
                               HR_ORGANIZATION_UNITS org
                         WHERE a.segment1 = v_project
                           AND a.CARRYING_OUT_ORGANIZATION_ID = ORG.ORGANIZATION_ID
                           AND vent_cmd.EXPENDITURE_ITEM_DATE BETWEEN org.date_from  AND NVL(org.date_to,vent_cmd.EXPENDITURE_ITEM_DATE);-- YWA artf2205542 
                        
                      EXCEPTION
                        WHEN OTHERS THEN
                          v_exp_org := NULL;
                          --Fnd_File.put_line (Fnd_File.LOG, 'Impossible de récupérer l''organisation des dépenses');
                          
                          v_flag_erreur_dist := TRUE;
                          ins_prog_message(g_request_id
                                          ,'DKA_REPPOCMDIMP_PKG'
                                          ,'ETL'
                                          ,'PO_DISTRIBUTIONS_TMP'
                                          --,NULL
                                          ,vent_cmd.logical_line_num
                                          ,NULL
                                          ,ent_cmd.document_num
                                          ,'E'
                                          ,'Impossible de récupérer l''organisation des dépenses ou l''organisation n''est pas valide par rapport à la date de dépense '||vent_cmd.EXPENDITURE_ITEM_DATE --YWA artf2205542
                                          );              
                          --g_summary.rejected_dist_rows := g_summary.rejected_dist_rows + 1; 
                                    
                      END;

                      IF v_project_id IS NOT NULL THEN
                      --RBE : Ajout controle sur projet et tache
                        BEGIN
                          SELECT task_id, pt.start_date,pt.completion_date -- YWA artf2205542 
                          INTO v_task_id,  v_t_start_date,v_t_completion_date 
                          FROM pa_tasks pt
                          WHERE pt.project_id = v_project_id
                          AND   pt.task_number = v_task
                          AND vent_cmd.EXPENDITURE_ITEM_DATE BETWEEN pt.start_date AND NVL(pt.COMPLETION_DATE,vent_cmd.EXPENDITURE_ITEM_DATE); --YWA artf2205542 
                          --;
                        
                        EXCEPTION
                          WHEN OTHERS THEN
                            v_task_id := NULL;
                            v_flag_erreur_dist := TRUE;
                            ins_prog_message(g_request_id
                                            ,'DKA_REPPOCMDIMP_PKG'
                                            ,'ETL'
                                            ,'PO_DISTRIBUTIONS_TMP'
                                            --,NULL
                                            ,vent_cmd.logical_line_num
                                            ,NULL
                                            ,ent_cmd.document_num
                                            ,'E'
                                            --,'Impossible de récupérer  la tache '|| v_task  --YWA artf2205542  (08/30/2017 annulation modif)
                                            ,'La tache '|| v_task ||' n''est pas valide par rapport à la date de dépense '||vent_cmd.EXPENDITURE_ITEM_DATE
                                            );  --YWA artf2205542 
                           
                            

                             
                        END;
                      END IF;
                      --> V1.6
                      
                      
                      vv_t_start_date := NULL;
                      vv_cf_date_from := NULL;
                      
                      --YWA artf2205542
                      /*IF v_task_id IS NOT NULL AND v_exp_org IS NOT NULL  THEN
                          IF nvl(vent_cmd.expenditure_item_date,v_t_start_date-1) NOT BETWEEN v_t_start_date AND NVL(v_t_completion_date,vent_cmd.expenditure_item_date) THEN
                           Fnd_File.put_line (Fnd_File.LOG, 'AVERTISSEMENT: la date de dépense de la ligne de ventilation '||vent_cmd.logical_line_num|| ' n''est pas comprise dans les dates de validité de la tache pour la commande '||ent_cmd.document_num);
                           vv_t_start_date:= v_t_start_date+1;
                          END IF;
                          
                          IF nvl(vent_cmd.expenditure_item_date,v_cf_date_from-1) NOT BETWEEN v_cf_date_from AND NVL(v_cf_date_to,vent_cmd.expenditure_item_date) THEN
                            Fnd_File.put_line (Fnd_File.LOG, 'AVERTISSEMENT: la date de dépense de la ligne de ventilation '||vent_cmd.logical_line_num||' n''est pas comprise dans les dates de validité du centre finance pour la commande '||ent_cmd.document_num);
                             vv_cf_date_from := v_cf_date_from+1;
                          END IF;
                        
                           IF  vv_t_start_date IS NOT NULL AND vv_cf_date_from IS NOT NULL THEN
                               IF vv_t_start_date < vv_cf_date_from   THEN  
                                    vent_cmd.expenditure_item_date := vv_cf_date_from;
                               ELSE
                                    vent_cmd.expenditure_item_date := vv_t_start_date;
                               END IF;
                           ELSIF vv_t_start_date IS NOT NULL AND vv_cf_date_from IS  NULL THEN
                                vent_cmd.expenditure_item_date := vv_t_start_date;
                           ELSIF vv_t_start_date IS  NULL AND vv_cf_date_from IS NOT NULL THEN
                                vent_cmd.expenditure_item_date := vv_cf_date_from;
                           END IF;
                      END IF; */-- YWA artf2205542  (08/30/2017 annulation modif)
                       
                    --Fnd_File.put_line (Fnd_File.LOG, 'Transcodification de DELIVER_TO_LOCATION'); --RBE Optimisation
                    -- Transcodification du lieu de mise à disposition             
                     DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '016_LIEUX_LIV_FACT',
                                                     pv_column_01    => vent_cmd.DELIVER_TO_LOCATION,
                                                     pv_out_01       => v_deliver_to_location); 
                                                       
                    
                    --V2.1 : Controle que la personne a livrer n'existe pas en tant qu'employe
                    BEGIN
                      
                      IF vent_cmd.deliver_to_person IS NOT NULL THEN    
                              
                        SELECT papf.full_name
                          INTO v_demandeur
                          FROM per_all_people_f papf
                         WHERE papf.full_name = vent_cmd.deliver_to_person
                           AND sysdate BETWEEN NVL(papf.effective_start_date,sysdate) AND NVL(papf.effective_end_date,sysdate)
                           AND rownum = 1;--YWA artf2101618 
                      ELSE
                      
                        v_demandeur := NULL;
                          
                      END IF;
                                  
                    EXCEPTION
                      WHEN OTHERS THEN 
                        v_demandeur := 'REPRISE, REPRISE';

                        ins_prog_message(g_request_id
                                        ,'DKA_REPPOCMDIMP_PKG'
                                        ,'ETL'
                                        ,'PO_DISTRIBUTIONS_TMP'
                                        --,NULL
                                        ,vent_cmd.logical_line_num
                                        ,'DELIVER_TO_PERSON'
                                        ,ent_cmd.document_num
                                        ,'E'
                                        ,'La personne à livrer ' || vent_cmd.deliver_to_person || ' n''existe pas en tant qu''employé'
                                        );              
                                   
                    END;
                    
                    --YWA artf2205542 
                    IF vent_cmd.deliver_to_location IS NOT NULL THEN
                        -- récupérer l'ID du lieu de mise à dispo de l'imputation de commande 
                        --Fnd_File.put_line (Fnd_File.LOG, 'récupérer l''ID du lieu  de mise à dispo de l'imputation de commande'); -
                        BEGIN
                          SELECT location_code 
                          INTO v_deliver_to_location
                          FROM hr_locations 
                          WHERE location_code =  vent_cmd.deliver_to_location;                
                          
                        EXCEPTION
                          WHEN OTHERS THEN

                            v_flag_erreur_dist := TRUE;
                            /*DKA_TOOLS_PKG.*/ins_prog_message(g_request_id
                                                          ,'DKA_REPPOCMDIMP_PKG'
                                                          ,'ETL'
                                                          ,'PO_DISTRIBUTIONS_TMP'
                                                          --,NULL
                                                          ,vent_cmd.logical_line_num
                                                          ,'DELIVER_TO_LOCATION'
                                                          ,ent_cmd.document_num
                                                          ,'E'
                                                          ,'Le lieu '||vent_cmd.deliver_to_location||' n''existe pas, vous devez le paramétrer'
                                                          );
                             --g_summary.rejected_lines_rows :=  g_summary.rejected_lines_rows + 1;                         
                        END;  

                    END IF;
                     -- Mise à jour des champs de la tables des lignes de ventilations
                     IF NOT v_flag_erreur_dist THEN
                      
                        UPDATE PO_DISTRIBUTIONS_TMP
                        SET STATUT               = 'S'
                            --,QUANTITY_ORDERED = v_quantity_ordered
                            ,QUANTITY_ORDERED_NEW = v_quantity_ordered
                            ,SET_OF_BOOKS_ID = v_set_of_books_id
                            -- 09/02/17 - NBO - artf2098322: RUN3 - Suppression des contrôles qui calculent la clé comptable
                            --,CHARGE_ID = v_charge_id
                            --,VARIANCE_ID = v_variance_id
                            --,ACCRUAL_ID = v_accrual_id
                            ,PROJECT = v_project
                            ,TASK = v_task
                            --,expenditure_organization = v_exp_org
                            ,expenditure_org_new = v_exp_org
                            --,DELIVER_TO_LOCATION = v_deliver_to_location
                            ,DELIVER_TO_LOC_NEW = v_deliver_to_location
                            ,PROJECT_NAME = v_project_name
                            ,DELIVER_TO_PERSON = v_demandeur
                            ,LAST_UPDATE_DATE  = SYSDATE
                            ,LAST_UPDATED_BY   = g_user_id
                           -- ,EXPENDITURE_ITEM_DATE = vent_cmd.EXPENDITURE_ITEM_DATE --  YWA artf2205542  -- YWA artf2205542  (08/30/2017 annulation modif)
                        WHERE CURRENT OF cur_vent_cmd
                        ;
                        
                      ELSE -- en cas d'erreur
                        UPDATE PO_DISTRIBUTIONS_TMP
                        SET  STATUT            = 'E'
                            ,LAST_UPDATE_DATE  = SYSDATE
                            ,LAST_UPDATED_BY   = g_user_id
                        WHERE CURRENT OF cur_vent_cmd
                        ;
                        
                        v_flag_erreur_lines  := TRUE;
                        v_flag_erreur_entete := TRUE;

                      END IF;                         
                  
                
               END LOOP; -- Dist
  
               -- Mise à jour des champs de la tables des lignes
               IF NOT v_flag_erreur_lines THEN
                
                  UPDATE PO_LINES_TMP
                  SET STATUT               = 'S'
                      ,category_id = v_category_id
                      --,QUANTITY = v_quantity
                      ,QUANTITY_NEW = v_quantity
                      --,UOM_CODE = v_uom_code
                      ,UOM_CODE_NEW = v_uom_code
                      --,SHIP_TO_LOCATION = v_line_ship_to_location
                      ,SHIP_TO_LOCATION_NEW = v_line_ship_to_location
                      ,NEED_BY_DATE = vd_need_by_date
                      ,LAST_UPDATE_DATE  = SYSDATE
                      ,LAST_UPDATED_BY   = g_user_id
                  WHERE CURRENT OF cur_lig_cmd
                  ;
                  
                ELSE -- en cas d'erreur
                  UPDATE PO_LINES_TMP
                  SET  STATUT            = 'E'
                      ,LAST_UPDATE_DATE  = SYSDATE
                      ,LAST_UPDATED_BY   = g_user_id
                  WHERE CURRENT OF cur_lig_cmd
                  ;
                  
                  v_flag_erreur_entete := TRUE;

                END IF;            
          
         END LOOP;          -- Lines
         
         IF v_flag_exist_lines = FALSE THEN
         
           v_flag_erreur_entete := TRUE;
           ins_prog_message(g_request_id
                           ,'DKA_REPPOCMDIMP_PKG'
                           ,'ETL'
                           ,'PO_HEADERS_TMP'
                           --,NULL
                           ,ent_cmd.logical_line_num
                           ,'DOCUMENT_NUM'
                           ,ent_cmd.document_num
                           ,'E'
                           ,'L''entete de la commande ne possede aucune ligne'
                           );
           --g_summary.rejected_headers_rows :=  g_summary.rejected_headers_rows + 1;
         
         END IF;
         
         -- Mise à jour des champs de la tables des entetes
         IF NOT v_flag_erreur_entete THEN
            
            UPDATE PO_HEADERS_TMP
            SET STATUT               = 'S'
                ,ORG_ID = v_org_id
                --,REGION = v_region
                ,REGION_NEW = v_region
                --,APPROVAL_STATUS = v_approval_statut -- RBE artf2061678
                ,VENDOR_ID = v_vendor_id
                ,vendor_site_id = v_vendor_site_id
                --,BILL_TO_LOCATION = v_bill_to_location
                ,BILL_TO_LOCATION_NEW = v_bill_to_location
                --,SHIP_TO_LOCATION = v_header_ship_to_location
                ,SHIP_TO_LOCATION_NEW = v_header_ship_to_location
                ,bill_to_location_id  = v_bill_to_location_id
                ,AGENT_NAME        = v_agent_name --V1.7 : ajout
                ,AGENT_ID          = v_agent_id
                ,LAST_UPDATE_DATE  = SYSDATE
                ,LAST_UPDATED_BY   = g_user_id
            WHERE document_num = ent_cmd.document_num
            ;
            
          ELSE -- en cas d'erreur
                      
            UPDATE PO_HEADERS_TMP
            SET    STATUT            = 'E'
                  ,LAST_UPDATE_DATE  = SYSDATE
                  ,LAST_UPDATED_BY   = g_user_id
            WHERE document_num = ent_cmd.document_num
            ;
            UPDATE PO_LINES_TMP
            SET    STATUT            = 'E'
                  ,LAST_UPDATE_DATE  = SYSDATE
                  ,LAST_UPDATED_BY   = g_user_id
            WHERE document_num = ent_cmd.document_num
            ;            
            UPDATE PO_DISTRIBUTIONS_TMP
            SET    STATUT            = 'E'
                  ,LAST_UPDATE_DATE  = SYSDATE
                  ,LAST_UPDATED_BY   = g_user_id
            WHERE document_num = ent_cmd.document_num
            ;

          END IF; 
          
          -- Commit toutes les 1000 lignes
          IF v_count = 1000 THEN
            COMMIT;
            v_count := 0;
          END IF;
          
      END LOOP;      -- Header    

  
  COMMIT;
  
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
 *  Procédure d'import des données dans les tables d'interface
 *
 * PARAMETERS
 * ==========
 * NAME                 DESCRIPTION
.* -------------------- ---------------------------------------------------
 * p_errbuf            Retour de message éventuel
 * p_retcode           Statut du traitement en sortie
 ************************************************************************
 */  
 
  PROCEDURE import_data(p_errbuf        OUT VARCHAR2,
                          p_retcode       OUT NUMBER
                          ) 
  IS
  
    /*CURSOR cur_ent_cmd IS
      SELECT *
      FROM PO_HEADERS_TMP
      WHERE LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
      AND STATUT = 'S'
    ;
    CURSOR cur_lig_cmd (p_doc_num in VARCHAR2) IS
      SELECT *
      FROM  PO_LINES_TMP   
      WHERE DOCUMENT_NUM = p_doc_num
      AND   LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
      AND STATUT = 'S'
    ;    
    CURSOR cur_vent_cmd (p_doc_num IN VARCHAR2, p_line_num IN NUMBER, p_shipment_num IN NUMBER) IS
      SELECT *
      FROM  PO_DISTRIBUTIONS_TMP    
      WHERE DOCUMENT_NUM = p_doc_num
      AND   LINE_NUM     = p_line_num
      AND   SHIPMENT_NUM = p_shipment_num
      AND   LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)
      AND STATUT = 'S'
    ;*/
    
    --v_interface_header_id       NUMBER;
    --v_interface_line_id         NUMBER;
    --v_interface_distribution_id NUMBER;        
    v_STYLE_ID                  NUMBER;
   
  BEGIN
  
  
      -- Récupération du STYLE_ID
    
      BEGIN
          SELECT STYLE_ID 
          INTO v_STYLE_ID
          FROM PO_DOC_STYLE_HEADERS
          WHERE STYLE_TYPE = 'STANDARD'
          ;
      EXCEPTION
        WHEN OTHERS THEN
          v_STYLE_ID := NULL;
          p_retcode   := 2;
          RETURN;
      END;    
  
      ---------------------------------------------------
      -- Alimentation de la table PO_HEADERS_INTERFACE --
      ----------------------------------------------------
      --Fnd_File.put_line(Fnd_File.LOG, 'Parcours du curseur des entetes de commandes');            
      --FOR ent_cmd IN cur_ent_cmd LOOP
      
        Fnd_File.put_line(Fnd_File.LOG, 'Insertion des entetes de commandes'); 
        --BEGIN 
       
          -- Insertion au niveau de la table d'interface PO_HEADERS_INTERFACE
          
          --v_interface_header_id := PO_HEADERS_INTERFACE_S.NEXTVAL;
          
          INSERT INTO PO_HEADERS_INTERFACE
              (
              INTERFACE_HEADER_ID   
              ,PROCESS_CODE                            
              ,ACTION                                  
              ,ORG_ID                                  
              ,DOCUMENT_TYPE_CODE                      
              ,DOCUMENT_NUM                            
              ,CURRENCY_CODE                           
              --,AGENT_NAME --RBE  
              ,AGENT_ID
              ,VENDOR_ID
              --,VENDOR_NAME   --RBE                          
              ,VENDOR_SITE_ID
              --,VENDOR_SITE_CODE  --RBE                       
              ,VENDOR_CONTACT                          
              ,SHIP_TO_LOCATION                        
              --,BILL_TO_LOCATION   --RBE                      
              ,BILL_TO_LOCATION_ID
              ,PAYMENT_TERMS                           
              ,APPROVAL_STATUS                         
              ,APPROVED_DATE                                                 
              ,NOTE_TO_VENDOR                          
              ,NOTE_TO_RECEIVER                        
              ,COMMENTS                                
              ,CLOSED_CODE                                               
              ,ATTRIBUTE_CATEGORY                      
              ,ATTRIBUTE1                              
              ,ATTRIBUTE2                              
              ,ATTRIBUTE6                              
              ,ATTRIBUTE8                              
              ,ATTRIBUTE11                             
              ,ATTRIBUTE12                             
              ,ATTRIBUTE13                             
              ,ATTRIBUTE14   
              ,STYLE_ID                          
              ,CREATION_DATE                           
              ,CREATED_BY
              ,LAST_UPDATE_DATE
              ,LAST_UPDATED_BY
              )
            SELECT
              PO_HEADERS_INTERFACE_S.NEXTVAL--v_interface_header_id
              ,'PENDING'
              ,'ORIGINAL'
              ,PHT.org_id
              ,PHT.type_lookup_code
              ,PHT.document_num
              ,PHT.currency_code
              --,PHT.agent_name --RBE
              ,PHT.agent_id
              ,PHT.vendor_id
              --,PHT.vendor_name --RBE
              ,PHT.vendor_site_id
              --,SUBSTR(PHT.VENDOR_SITE_CODE,5) --RBE
              ,PHT.vendor_contact
              --,PHT.SHIP_TO_LOCATION
              --,PHT.BILL_TO_LOCATION
              ,PHT.SHIP_TO_LOCATION_NEW
              --,PHT.BILL_TO_LOCATION_NEW --RBE
              ,PHT.bill_to_location_id
              ,PHT.PAYMENT_TERMS
              --,DECODE(PHT.approval_status,'APPROVED','APPROVED','INCOMPLETE') -- RBE artf2061678 
              ,PHT.approval_status -- YWA artf2149639 --  'INCOMPLETE'  -- RBE artf2070166 
              ,PHT.APPROVAL_DATE -- YWA artf2149639
              --,NULL --RBE artf2070166 -- YWA artf2149639
              ,PHT.NOTE_TO_VENDOR
              ,PHT.NOTE_TO_RECEIVER
              ,PHT.COMMENTS
              ,'OPEN'
              ,PHT.ATTRIBUTE_CATEGORY
              ,PHT.ATTRIBUTE1
              ,PHT.ATTRIBUTE2
              ,PHT.ATTRIBUTE6
              ,PHT.ATTRIBUTE8
              ,PHT.AMOUNT_INIT
              ,PHT.ATTRIBUTE12
              ,PHT.ATTRIBUTE13
              ,PHT.ATTRIBUTE14 
              ,v_STYLE_ID         
              ,SYSDATE
              ,g_user_id
              ,SYSDATE
              ,g_user_id
            FROM PO_HEADERS_TMP PHT
            WHERE 1=1 --PHT.LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, PHT.load_request_id, g_loader_request_id) --RBE
            AND PHT.STATUT = 'S';
            
            --g_summary.loaded_OI_header_rows := g_summary.loaded_OI_header_rows + 1;
            
            g_summary.loaded_OI_header_rows := SQL%ROWCOUNT;
            
            UPDATE PO_HEADERS_TMP PHT
            SET PHT.STATUT               = 'T'
            WHERE 1=1 --PHT.LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, PHT.load_request_id, g_loader_request_id) --RBE
            AND PHT.STATUT = 'S'
            ;
          
          /*
          EXCEPTION
          WHEN OTHERS
          THEN
              p_retcode   := 2;
              p_errbuf    := 'import_data : Erreur lors de l''insertion dans PO_HEADERS_INTERFACE' ||SQLERRM;
              Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
          END;
          */


          Fnd_File.put_line(Fnd_File.LOG, 'Insertion des lignes de commandes');
          -------------------------------------------------------------------------------
          -- Transcodification des données et alimentation de la table PO_LINES_INTERFACE
          -------------------------------------------------------------------------------     
          --BEGIN           
          
          --FOR lig_cmd IN cur_lig_cmd(ent_cmd.document_num) LOOP
         
            -- Récupération de linterface line id
            --v_interface_line_id := PO_LINES_INTERFACE_S.NEXTVAL;
            
            -- Insertion au niveau de la table d'interface PO_LINES_INTERFACE
              INSERT INTO PO_LINES_INTERFACE
                (
                 INTERFACE_LINE_ID 
                ,INTERFACE_HEADER_ID
                ,ACTION                                   
                ,LINE_NUM                                 
                ,SHIPMENT_NUM                             
                ,SHIPMENT_TYPE                            
                ,LINE_TYPE                                
                ,CATEGORY_ID                              
                ,ITEM_DESCRIPTION                         
                ,VENDOR_PRODUCT_NUM                       
                ,UOM_CODE                                 
                ,QUANTITY                                 
                ,UNIT_PRICE                               
                ,LIST_PRICE_PER_UNIT                      
                ,NOTE_TO_VENDOR                           
                ,INSPECTION_REQUIRED_FLAG                 
                ,RECEIPT_REQUIRED_FLAG                    
                ,CLOSED_CODE                              
                ,INVOICE_CLOSE_TOLERANCE                  
                ,RECEIVE_CLOSE_TOLERANCE                  
                ,DAYS_EARLY_RECEIPT_ALLOWED               
                ,DAYS_LATE_RECEIPT_ALLOWED                
                ,ENFORCE_SHIP_TO_LOCATION_CODE            
                ,ALLOW_SUBSTITUTE_RECEIPTS_FLAG           
                ,RECEIVING_ROUTING                        
                ,QTY_RCV_TOLERANCE                        
                ,QTY_RCV_EXCEPTION_CODE                   
                ,RECEIPT_DAYS_EXCEPTION_CODE              
                ,SHIP_TO_ORGANIZATION_ID                  
                ,SHIP_TO_LOCATION 
                ,SHIP_TO_LOCATION_ID
                ,NEED_BY_DATE                             
                ,PROMISED_DATE                            
                ,LINE_ATTRIBUTE2                          
                ,CREATION_DATE                            
                ,CREATED_BY                               
                ,ORGANIZATION_ID                         
                ,PROCESS_CODE 
                ,LINE_LOC_POPULATED_FLAG 
                ,LAST_UPDATE_DATE
                ,LAST_UPDATED_BY
                )
              SELECT
                 PO_LINES_INTERFACE_S.NEXTVAL --v_interface_line_id
                ,PHI.interface_header_id--v_interface_header_id
                ,'ORIGINAL'
                ,PLT.LINE_NUM
                ,PLT.SHIPMENT_NUM
                ,PLT.SHIPMENT_TYPE
                ,PLT.LINE_TYPE
                ,PLT.category_id
                ,PLT.ITEM_DESCRIPTION
                ,PLT.VENDOR_PRODUCT_NUM
                --,PLT.uom_code
                --,PLT.quantity
                ,PLT.uom_code_new
                ,PLT.quantity_new
                ,PLT.UNIT_PRICE
                ,PLT.LIST_PRICE_PER_UNIT
                ,PLT.LINE_NOTE_TO_VENDOR
                ,PLT.INSPECTED_REQUIRED_FLAG          
                ,PLT.RECEIPT_REQUIRED_FLAG
                ,'OPEN'
                ,PLT.INVOICE_CLOSE_TOLERANCE
                ,PLT.RECEIVE_CLOSE_TOLERANCE
                ,PLT.DAYS_EARLY_RECEIPT_ALLOWED
                ,PLT.DAYS_LATE_RECEIPT_ALLOWED
                ,PLT.ENFORCE_SHIP_TO_LOCATION_CODE         
                ,PLT.ALLOW_SUBSTITUTE_RECEIPTS_FLAG
                ,DECODE(PLT.RECEIVING_ROUTING,'Mise à dispo. directe','Mise à disposition directe',PLT.RECEIVING_ROUTING)
                ,PLT.QTY_RECEIVED_TOLERANCE
                ,PLT.QTY_RCV_EXCEPTION_CODE
                ,PLT.RECEIPTS_DAYS_EXCEPTION_CODE
                ,PHI.org_id
                --,PLT.SHIP_TO_LOCATION        
                --,PHT.SHIP_TO_LOCATION_NEW  -- V1.5
                ,PLT.SHIP_TO_LOCATION_NEW    -- V1.5
                , (SELECT location_id FROM hr_locations  WHERE location_code = PLT.SHIP_TO_LOCATION_NEW )--YWA artf2205542 
                ,PLT.NEED_BY_DATE
                ,PLT.PROMISED_DATE
                ,PLT.LINE_ATTRIBUTE2
                ,SYSDATE
                ,g_user_id
                ,PHI.org_id
                ,'PENDING' 
                ,'N'      
                ,SYSDATE
                ,g_user_id
              FROM   PO_LINES_TMP PLT
                    ,PO_HEADERS_INTERFACE PHI
              WHERE PLT.DOCUMENT_NUM = PHI.DOCUMENT_NUM        
              --AND   PLT.LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, PLT.load_request_id, g_loader_request_id) --RBE
              AND   PLT.STATUT = 'S'
              ;
              
              --g_summary.loaded_OI_lines_rows := g_summary.loaded_OI_lines_rows + 1;
              g_summary.loaded_OI_lines_rows:= SQL%ROWCOUNT;
  
              UPDATE PO_LINES_TMP PLT
              SET  PLT.STATUT        = 'T'
                  ,LAST_UPDATE_DATE  = SYSDATE
                  ,LAST_UPDATED_BY   = g_user_id
              WHERE 1=1 --PLT.LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, PLT.load_request_id, g_loader_request_id) --RBE
              AND   PLT.STATUT = 'S'
              ;  
            
            /*EXCEPTION
            WHEN OTHERS
            THEN
                p_retcode   := 2;
                p_errbuf    := 'import_data : Erreur lors de l''insertion dans PO_LINES_INTERFACE' ||SQLERRM;
                Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            END;
            */
            
            
            Fnd_File.put_line(Fnd_File.LOG, 'Insertion des lignes de ventilation');
            ---------------------------------------------------------------------------------------
            -- Transcodification des données et alimentation de la table PO_DISTRIBUTIONS_INTERFACE
            ---------------------------------------------------------------------------------------                  
            --BEGIN
            --FOR vent_cmd IN cur_vent_cmd(lig_cmd.document_num, lig_cmd.line_num, lig_cmd.shipment_num) LOOP
              --Fnd_File.put_line(Fnd_File.LOG, 'Curseur des lignes de ventilation. Commande N° ' || ent_cmd.document_num);

              -- Récupération de linterface distribution id
              --v_interface_distribution_id := PO_DISTRIBUTIONS_INTERFACE_S.NEXTVAL;
              
              -- Insertion au niveau de la table d'interface PO_DISTRIBUTIONS_INTERFACE

                INSERT INTO PO_DISTRIBUTIONS_INTERFACE
                  (
                  INTERFACE_HEADER_ID
                  ,INTERFACE_LINE_ID
                  ,INTERFACE_DISTRIBUTION_ID
                  ,DISTRIBUTION_NUM
                  ,ORG_ID
                  ,QUANTITY_ORDERED
                  ,DELIVER_TO_LOCATION
                  ,DELIVER_TO_PERSON_FULL_NAME
                  ,DESTINATION_TYPE_CODE
                  ,DESTINATION_ORGANIZATION_ID
                  ,SET_OF_BOOKS_ID
-- V2.5    26/01/2017	  NBO artf2090369 - RUN2 - DEFECT487 - Pb clé comptable sur commande reprise
                  --,CHARGE_ACCOUNT_ID
                  --,ACCRUAL_ACCOUNT_ID
                  --,VARIANCE_ACCOUNT_ID
                  ,PROJECT
                  ,TASK
                  ,EXPENDITURE_TYPE
                  ,PROJECT_ACCOUNTING_CONTEXT
                  ,EXPENDITURE_ORGANIZATION
                  ,EXPENDITURE_ITEM_DATE
                  ,PROJECT_RELEATED_FLAG
                  ,ATTRIBUTE3
                  ,CREATION_DATE
                  ,CREATED_BY   
                  ,LAST_UPDATE_DATE
                  ,LAST_UPDATED_BY
                  )
                SELECT   
                    PHI.interface_header_id
                   ,PLI.interface_line_id
                   ,PO_DISTRIBUTIONS_INTERFACE_S.NEXTVAL --v_interface_distribution_id
                   ,PDT.DISTRIBUTION_NUM
                   ,PHI.org_id
                   --,PDT.quantity_ordered
                   --,PDT.DELIVER_TO_LOCATION
                   ,PDT.quantity_ordered_new
                   ,PDT.DELIVER_TO_LOC_NEW
                   ,PDT.DELIVER_TO_PERSON
                   ,PDT.DESTINATION_TYPE_CODE
                   ,PHI.org_id
                   ,PDT.SET_OF_BOOKS_ID
-- V2.5    26/01/2017	  NBO artf2090369 - RUN2 - DEFECT487 - Pb clé comptable sur commande reprise
                   --,PDT.CHARGE_ID
                   --,PDT.ACCRUAL_ID
                   --,PDT.VARIANCE_ID
                   ,PDT.PROJECT_NAME --,PDT.PROJECT
                   ,PDT.TASK
                   ,PDT.EXPENDITURE_TYPE
                   --,PDT.PROJECT_ACCOUNTING_CONTEXT
                   ,'Y'
                   --,PDT.expenditure_organization
                   ,PDT.expenditure_org_new
                   ,PDT.EXPENDITURE_ITEM_DATE
                   ,'Y'
                   ,PDT.DIST_ATTRIBUTE3
                   ,SYSDATE
                   ,g_user_id
                   ,SYSDATE
                   ,g_user_id
                  FROM PO_DISTRIBUTIONS_TMP PDT,PO_HEADERS_INTERFACE PHI,PO_LINES_INTERFACE PLI
                  WHERE PDT.DOCUMENT_NUM = PHI.DOCUMENT_NUM
                  AND   PHI.interface_header_id = PLI.interface_header_id
                  AND   PDT.LINE_NUM     = PLI.line_num
                  AND   PDT.SHIPMENT_NUM = PLI.shipment_num
                  --AND   PDT.LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, PDT.load_request_id, g_loader_request_id) --RBE
                  AND   PDT.STATUT = 'S'
                  ;
                  
                  --g_summary.loaded_OI_dist_rows := g_summary.loaded_OI_dist_rows + 1;
                  g_summary.loaded_OI_dist_rows:= SQL%ROWCOUNT;

            --END LOOP;

          --END LOOP;
         
         
        /*UPDATE PO_HEADERS_TMP
        SET STATUT               = 'T'
        WHERE document_num = ent_cmd.document_num
        ;
        UPDATE PO_LINES_TMP
        SET STATUT               = 'T'
        WHERE document_num = ent_cmd.document_num
        ;*/
                UPDATE PO_DISTRIBUTIONS_TMP PDT
                SET PDT.STATUT        = 'T'
                   ,LAST_UPDATE_DATE  = SYSDATE
                   ,LAST_UPDATED_BY   = g_user_id
                WHERE 1=1 -- PDT.LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, PDT.load_request_id, g_loader_request_id) --RBE
                AND   PDT.STATUT = 'S'
                ;
        
            /*EXCEPTION
            WHEN OTHERS
            THEN
                p_retcode   := 2;
                p_errbuf    := 'import_data : Erreur lors de l''insertion dans Open Interface ' ||SQLERRM;
                Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            END;
            */
        
      --END LOOP;

  COMMIT;
  
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
 * PROCEDURE NAME : Launch_OI
 * 
 * DESCRIPTION
 *  Procédure de lancement du programme standard de l'interface des commandes
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_ou              Unité opérationnelle
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 * 
 ************************************************************************
 */
 
  PROCEDURE Launch_OI(p_errbuf            OUT VARCHAR2,
                      p_retcode           OUT NUMBER
                          ) 
  IS
        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
        v_message                VARCHAR2 (100);
        b_result                 BOOLEAN;
        
        v_user_id                NUMBER;                       
        v_resp_id                NUMBER;
        v_resp_appl_id           NUMBER;

        TYPE num_traitement IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
        num_trait_list num_traitement;
      
        v_cpt INTEGER := 0;
        
  --< V1.3  
  CURSOR cur_uo IS
    SELECT DISTINCT org_id
    FROM PO_HEADERS_INTERFACE
   WHERE document_type_code = 'STANDARD'
     AND process_code <> 'ACCEPTED'; --RBE
  --> V1.3

  BEGIN
  
        v_user_id      := FND_PROFILE.VALUE('USER_ID');
        --v_resp_id      := FND_PROFILE.VALUE('RESP_ID');     -- V1.4
        --v_resp_appl_id := FND_PROFILE.VALUE('RESP_APPL_ID');-- V1.4  
        
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Launch_OI');    
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 
                                         'Lancement de l''interface des commandes : ');
        
        fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT, 'LANCEMENT DE L''INTERFACE DES COMMANDES : ');
        fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
        FOR rec IN cur_uo LOOP

            --fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
            --fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
            fnd_file.put_line(fnd_file.LOG, 'Lancement de l''interface des commandes pour l''org_id : '||rec.org_id);
            fnd_file.put_line(fnd_file.OUTPUT, 'Lancement de l''interface des commandes pour l''org_id : '||rec.org_id);
            --fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
            
            --< V1.4
            
            /*
            SELECT RESPONSIBILITY_ID
                  ,RESPONSIBILITY_APPLICATION_ID
            INTO   v_resp_id
                  ,v_resp_appl_id
            FROM
            (              
            SELECT  furg.RESPONSIBILITY_ID
            ,      furg.RESPONSIBILITY_APPLICATION_ID
            FROM   FND_PROFILE_OPTIONS       fpo
            ,      FND_PROFILE_OPTION_VALUES fpov
            ,      FND_USER_RESP_GROUPS      furg
            WHERE  1 = 1
            AND    fpov.APPLICATION_ID       = fpo.APPLICATION_ID
            AND    fpov.PROFILE_OPTION_ID    = fpo.PROFILE_OPTION_ID
            AND    fpov.PROFILE_OPTION_VALUE = TO_CHAR(rec.org_id)
            AND    fpo.PROFILE_OPTION_NAME   = 'ORG_ID'
            AND    fpov.LEVEL_ID             = 10003
            AND    furg.RESPONSIBILITY_APPLICATION_ID = fpov.LEVEL_VALUE_APPLICATION_ID
            AND    furg.RESPONSIBILITY_ID       = fpov.LEVEL_VALUE
            AND    furg.USER_ID                 = v_user_id
            AND    furg.START_DATE              <= SYSDATE
            AND    nvl(furg.END_DATE,SYSDATE+1) >= SYSDATE
            AND    furg.RESPONSIBILITY_APPLICATION_ID = 201
            ORDER BY furg.RESPONSIBILITY_ID ASC)
            WHERE ROWNUM = 1; 
            */ --V1.8
            
            --> V1.4
            
            --V1.8
            BEGIN 
              SELECT responsibility_id, application_id
                INTO v_resp_id, v_resp_appl_id
                FROM fnd_responsibility fr, hr_operating_units hou
               WHERE hou.organization_id = rec.org_id
                 AND fr.responsibility_key = hou.name || '_PO_ADMINISTRATEUR';
                
              --< V1.3
              APPS.FND_GLOBAL.APPS_INITIALIZE(USER_ID      => v_user_id,
                                              RESP_ID      => v_resp_id,
                                              RESP_APPL_ID => v_resp_appl_id
                                              );
                                              
              mo_global.set_policy_context('S',rec.org_id);
              
              Fnd_Request.set_org_id(org_id => rec.org_id); --V1.8

            EXCEPTION
            WHEN OTHERS THEN
                p_retcode   := 2;
                v_resp_id   := NULL; -- RBE artf2061712
                v_resp_appl_id := NULL; -- RBE artf2061712 
                --fnd_file.put_line(fnd_file.OUTPUT, 'Lancement de l''interface des commandes pour l''org_id : '||rec.org_id);
                fnd_file.put_line(fnd_file.OUTPUT, '. Problème de recupération de la responsabilité ');
                fnd_file.put_line(fnd_file.LOG, '. Problème de recupération de la responsabilité ');
            END;
            
            IF v_resp_id IS NOT NULL THEN
            --MO_GLOBAL.INIT('PO');    
            --> V1.3
            ---------------------------------------------------
            -- Lancement du traitement de l'interface des commandes --
            ---------------------------------------------------     
            -- Positionnement des options d'impression
            b_result := fnd_request.set_print_options(printer => gv_printer,
                                                      copies => g_number_of_copies); 
            -- Lancement du traitement 
            g_int_request_id          := Fnd_Request.submit_request (
                                                 'PO'                             -- APPL
                                                ,'POXPOPDOI'                      -- PROG
                                                ,NULL                             -- PROGRAM_NAME
                                                ,NULL                             -- START
                                                ,FALSE                            -- SUB_REQUEST
                                                ,NULL
                                                ,'STANDARD'
                                                ,NULL
                                                ,'N'
                                                ,NULL
                                                ,'APPROVED' -- YWA artf2149639  --'INITIATE APPROVAL'
                                                ,NULL
                                                ,NULL
                                                ,rec.org_id  -- V1.3
                                                ,NULL
                                                ,NULL
                                                ,NULL
                                                ,NULL
                                                ,NULL
                                                ,'Y' --,'N' --Groupes les lignes
                                                ,'N'
                                                ,5000
                                                ,'Y' -- RBE
                                                );
     
            IF g_int_request_id = 0
            THEN
                p_retcode    := 2;
                --fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de l''interface des commandes a échoué' || CHR(10) ||
                                                --'PROGRAMME  : POXPOPDOI' --|| CHR(10) ||
                                                --'UNITE OPERATIONNELLE : ' || p_ou || CHR(10)
                                                --);
                Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de l''interface des commandes a échoué');
            ELSE
                COMMIT;
                v_cpt := v_cpt + 1;
                num_trait_list(v_cpt) := g_int_request_id;
                --Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || g_int_request_id);            
                Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement de l''interface des commandes : ' || g_int_request_id);  
                Fnd_File.put_line(Fnd_File.LOG, '. Numéro du traitement de l''interface des commandes : ' || g_int_request_id);
     
                -- Attente de la fin du traitement
                --RBE Optimisation : a commenter
                /*
                IF NOT (Fnd_Concurrent.wait_for_request (g_int_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
                THEN                        
                    p_errbuf  := v_Message;
                    p_retcode := 2;
                    Fnd_file.put_line(Fnd_file.log, 'ERREUR : Attente de la fin du programme de l''interface des commandes : Fin du traitement' || CHR(10) ||
                                                    'MESSAGE : ' || v_Message || CHR(10) );  
                END IF;
                
                             
                IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') 
                THEN          
                    Fnd_File.put_line(Fnd_File.LOG, 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
                    --Fnd_File.put_line(Fnd_File.OUTPUT, '. Statut de fin : ' || v_phase || '/' || v_status);

                ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
                THEN
                    --Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement de l''interface des commandes en warning '|| g_int_request_id);
                    Fnd_File.put_line (Fnd_File.OUTPUT, 'Fin du traitement de l''interface des commandes en warning '|| g_int_request_id);
                    p_retcode    := 1;

                ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')  
                THEN
                    p_retcode := 2;
                    p_errbuf  := 'ERREUR : Fin anormale du traitement de l''interface des commandes : '||v_Message;
      
                    fnd_file.put_line(fnd_file.OUTPUT, 'ERREUR : Fin anormale du traitement de l''interface des commandes '|| g_int_request_id  || CHR(10) ||
                                                    'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                                    'MESSAGE : ' || v_message || CHR(10) );
                    --Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement de l''interface des commandes '||g_int_request_id);
                END IF;
                */
            END IF;
            
          END IF;
          
        END LOOP;

        fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT, 'ETAT DES INTERFACES STANDARS DES COMMANDES : ');
        fnd_file.put_line(fnd_file.OUTPUT, '-------------------------------------------- ');
        -- Attente de la fin des traitements
        FOR var IN 1 .. v_cpt LOOP
        
          --Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || num_trait_list(var));            
          Fnd_File.put_line(Fnd_File.OUTPUT,
                            '. Numéro du traitement de l''interface des commandes : ' ||
                            num_trait_list(var));
        
          IF NOT (Fnd_Concurrent.wait_for_request(num_trait_list(var),
                                                  g_tempo,
                                                  0,
                                                  v_phase,
                                                  v_status,
                                                  v_dev_phase,
                                                  v_dev_status,
                                                  v_message)) THEN
            p_errbuf := v_Message;
            Fnd_file.put_line(Fnd_file.log,
                              'ERREUR : Attente de la fin du programme de l''interface des commandes : Fin du traitement' ||
                              CHR(10) || 'MESSAGE : ' || v_Message || CHR(10));
          END IF;
        
          IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
            Fnd_File.put_line(Fnd_File.LOG,
                              'COMPLETION= ' || v_dev_phase || '/' ||
                              v_dev_status);
            Fnd_File.put_line(Fnd_File.OUTPUT,
                              '. Statut de fin : ' || v_phase || '/' ||
                              v_status);
          
          ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
            Fnd_File.put_line(Fnd_File.LOG,
                              'Fin du traitement de l''interface des commandes en warning ' ||
                              g_int_request_id);
            Fnd_File.put_line(Fnd_File.OUTPUT,
                              'Fin du traitement de l''interface des commandes en warning ' ||
                              g_int_request_id);
            p_retcode := 1;
          
          ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
            p_retcode := 1;  --artf2063044
            p_errbuf  := 'ERREUR : Fin anormale du traitement de l''interface des commandes : ' ||
                         v_Message;
          
            fnd_file.put_line(fnd_file.LOG,
                              'ERREUR : Fin anormale du traitement de l''interface des commandes ' ||
                              g_int_request_id || CHR(10) || 'Phase/Statut : ' ||
                              v_dev_phase || '/' || v_dev_status || CHR(10) ||
                              'MESSAGE : ' || v_message || CHR(10));
            Fnd_File.put_line(Fnd_File.OUTPUT,
                              '===> ERREUR : Fin anormale du traitement de l''interface des commandes ' ||
                              g_int_request_id);
          END IF;
        END LOOP;
        
        COMMIT;

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Launch_OI');    
  
  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'Launch_OI : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Launch_OI : EXCEPTION OTHERS ');
  END Launch_OI;  

  

/*
 *************************************************************************
 * PROCEDURE NAME : update_post_import
 * 
 * DESCRIPTION
 *  Procédure de lancement des mises à jour post import
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
 
  PROCEDURE update_post_import(p_errbuf            OUT VARCHAR2,
                               p_retcode           OUT NUMBER
                              ) 
  IS
        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
        v_message                VARCHAR2 (100);
        b_result                 BOOLEAN;

  BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début update_post_import');    
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 
                                         'Lancement des mises à jour post import : ');

        fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT, 'LANCEMENT DES MISES A JOUR POST IMPORT');
        fnd_file.put_line(fnd_file.OUTPUT, '--------------------------------------');
        --------------------------------------------
        -- Lancement des mises à jour post import --
        --------------------------------------------     
        fnd_file.put_line(fnd_file.OUTPUT, 'Mise à jour de PO_LINE_LOCATIONS_ALL');
        UPDATE PO_LINE_LOCATIONS_ALL PLLA
        SET PLLA.QUANTITY_BILLED   = (SELECT PLT.QUANTITY_BILLED
                                      FROM  --PO_HEADERS_TMP PHT,
                                            PO_LINES_TMP PLT,
                                            PO_HEADERS_ALL PHA,
                                            PO_LINES_ALL POLA,
                                            PO_LINE_LOCATIONS_ALL PLL
                                      WHERE PLT.DOCUMENT_NUM = PHA.SEGMENT1
                                      --AND   PLT.DOCUMENT_NUM = PHT.DOCUMENT_NUM
                                      --AND   PHT.DOCUMENT_NUM = PHA.SEGMENT1
                                      --AND   PHT.ORG_ID       = PHA.ORG_ID
                                      AND   PLLA.PO_HEADER_ID = PHA.PO_HEADER_ID
                                      AND   PLL.PO_HEADER_ID  = PHA.PO_HEADER_ID
                                      AND   PLL.PO_LINE_ID    = PLLA.PO_LINE_ID
                                      AND   PLL.LINE_LOCATION_ID = PLLA.LINE_LOCATION_ID
                                      AND   PHA.PO_HEADER_ID  = pola.PO_HEADER_ID
                                      AND   PLL.PO_LINE_ID    = POLA.PO_LINE_ID
                                      AND   PHA.PO_HEADER_ID  = PLL.PO_HEADER_ID
                                      AND   PLLA.po_line_id   = POLA.PO_LINE_ID
                                      AND   POLA.LINE_NUM     = PLT.LINE_NUM
                                      AND   PLL.SHIPMENT_NUM  = PLT.SHIPMENT_NUM
                                      AND   PHA.SEGMENT1 LIKE '%ST%'
                                      --AND   PHT.DOCUMENT_NUM LIKE '%ST%'
                                      AND   PLT.DOCUMENT_NUM like '%ST%'
                                      )
                ,LAST_UPDATE_DATE  = SYSDATE
                ,LAST_UPDATED_BY   = g_user_id
        WHERE EXISTS 
                   (SELECT PLL.LINE_LOCATION_ID
                    FROM  --PO_HEADERS_TMP PHT,
                          PO_LINES_TMP PLT,
                          PO_HEADERS_ALL PHA,
                          PO_LINES_ALL POLA,
                          PO_LINE_LOCATIONS_ALL PLL
                    WHERE PLT.DOCUMENT_NUM = PHA.SEGMENT1
                    --AND   PLT.DOCUMENT_NUM = PHT.DOCUMENT_NUM
                    --AND   PHT.DOCUMENT_NUM = PHA.SEGMENT1
                    --AND   PHT.ORG_ID       = PHA.ORG_ID
                    AND   PLLA.PO_HEADER_ID = PHA.PO_HEADER_ID
                    AND   PLL.PO_HEADER_ID  = PHA.PO_HEADER_ID
                    AND   PLL.PO_LINE_ID    = PLLA.PO_LINE_ID
                    AND   PLL.LINE_LOCATION_ID = PLLA.LINE_LOCATION_ID
                    AND   PHA.PO_HEADER_ID  = pola.PO_HEADER_ID
                    AND   PLL.PO_LINE_ID    = POLA.PO_LINE_ID
                    AND   PHA.PO_HEADER_ID  = PLL.PO_HEADER_ID
                    AND   PLLA.po_line_id   = POLA.PO_LINE_ID
                    AND   POLA.LINE_NUM     = PLT.LINE_NUM
                    AND   PLL.SHIPMENT_NUM  = PLT.SHIPMENT_NUM
                    AND   PHA.SEGMENT1 LIKE '%ST%'
                    --AND   PHT.DOCUMENT_NUM LIKE '%ST%'
                    AND   PLT.DOCUMENT_NUM like '%ST%'
                    );

        g_summary.updated_rows_lines_sstr :=  SQL%ROWCOUNT;
       
        fnd_file.put_line(fnd_file.OUTPUT, 'Mise à jour DE PO_DISTRIBUTIONS_ALL');
        UPDATE PO_DISTRIBUTIONS_ALL PDAA
        SET PDAA.QUANTITY_BILLED   = (SELECT PLT.QUANTITY_BILLED
                                      FROM  --PO_HEADERS_TMP PHT,
                                            PO_DISTRIBUTIONS_TMP PLT,
                                            PO_HEADERS_ALL PHA,
                                            PO_LINES_ALL POLA,
                                            PO_LINE_LOCATIONS_ALL PLL,
                                            PO_DISTRIBUTIONS_ALL PDA
                                      WHERE PLT.DOCUMENT_NUM = PHA.SEGMENT1
                                      --AND   PLT.DOCUMENT_NUM = PHT.DOCUMENT_NUM
                                      --AND   PHT.DOCUMENT_NUM = PHA.SEGMENT1
                                      --AND   PHT.ORG_ID       = PHA.ORG_ID
                                      AND   PDAA.PO_HEADER_ID = PHA.PO_HEADER_ID
                                      AND   PLL.PO_HEADER_ID  = PHA.PO_HEADER_ID
                                      AND   PLL.PO_LINE_ID    = PDAA.PO_LINE_ID
                                      AND   PLL.LINE_LOCATION_ID = PDAA.LINE_LOCATION_ID
                                      AND   PHA.PO_HEADER_ID  = pola.PO_HEADER_ID
                                      AND   PLL.PO_LINE_ID    = POLA.PO_LINE_ID
                                      AND   PHA.PO_HEADER_ID  = PLL.PO_HEADER_ID
                                      AND   PDA.PO_HEADER_ID  = PHA.PO_HEADER_ID
                                      AND   PDA.PO_LINE_ID    = POLA.PO_LINE_ID
                                      AND   PDA.LINE_LOCATION_ID = PLL.LINE_LOCATION_ID
                                      AND   PDAA.po_line_id   = POLA.PO_LINE_ID
                                      AND   POLA.LINE_NUM     = PLT.LINE_NUM
                                      AND   PLL.SHIPMENT_NUM  = PLT.SHIPMENT_NUM
                                      AND   PDA.DISTRIBUTION_NUM = PLT.DISTRIBUTION_NUM
                                      AND   PDA.PO_DISTRIBUTION_ID = PDAA.PO_DISTRIBUTION_ID
                                      AND   PHA.SEGMENT1 LIKE '%ST%'
                                      --AND   PHT.DOCUMENT_NUM LIKE '%ST%'
                                      AND   PLT.DOCUMENT_NUM LIKE '%ST%'
                                      )
                ,LAST_UPDATE_DATE  = SYSDATE
                ,LAST_UPDATED_BY   = g_user_id
        WHERE EXISTS
                                     (SELECT 1
                                      FROM  --PO_HEADERS_TMP PHT,
                                            PO_DISTRIBUTIONS_TMP PLT,
                                            PO_HEADERS_ALL PHA,
                                            PO_LINES_ALL POLA,
                                            PO_LINE_LOCATIONS_ALL PLL,
                                            PO_DISTRIBUTIONS_ALL PDA
                                      WHERE PLT.DOCUMENT_NUM = PHA.SEGMENT1
                                      --AND   PLT.DOCUMENT_NUM = PHT.DOCUMENT_NUM
                                      --AND   PHT.DOCUMENT_NUM = PHA.SEGMENT1
                                      --AND   PHT.ORG_ID       = PHA.ORG_ID
                                      AND   PDAA.PO_HEADER_ID = PHA.PO_HEADER_ID
                                      AND   PLL.PO_HEADER_ID  = PHA.PO_HEADER_ID
                                      AND   PLL.PO_LINE_ID    = PDAA.PO_LINE_ID
                                      AND   PLL.LINE_LOCATION_ID = PDAA.LINE_LOCATION_ID
                                      AND   PHA.PO_HEADER_ID  = pola.PO_HEADER_ID
                                      AND   PLL.PO_LINE_ID    = POLA.PO_LINE_ID
                                      AND   PHA.PO_HEADER_ID  = PLL.PO_HEADER_ID
                                      AND   PDA.PO_HEADER_ID  = PHA.PO_HEADER_ID
                                      AND   PDA.PO_LINE_ID    = POLA.PO_LINE_ID
                                      AND   PDA.LINE_LOCATION_ID = PLL.LINE_LOCATION_ID
                                      AND   PDAA.po_line_id   = POLA.PO_LINE_ID
                                      AND   POLA.LINE_NUM     = PLT.LINE_NUM
                                      AND   PLL.SHIPMENT_NUM  = PLT.SHIPMENT_NUM
                                      AND   PDA.DISTRIBUTION_NUM = PLT.DISTRIBUTION_NUM
                                      AND   PDA.PO_DISTRIBUTION_ID = PDAA.PO_DISTRIBUTION_ID
                                      AND   PHA.SEGMENT1 LIKE '%ST%'
                                      --AND   PHT.DOCUMENT_NUM LIKE '%ST%'
                                      AND   PLT.DOCUMENT_NUM LIKE '%ST%'
                                      ); 
                                      
        g_summary.updated_rows_dist_sstr :=  SQL%ROWCOUNT;
        
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin update_post_import');    
  
  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'update_post_import : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure update_post_import : EXCEPTION OTHERS ');
  END update_post_import;    
  

 /*
 *************************************************************************
 * PROCEDURE NAME : Launch_report
 * 
 * DESCRIPTION
 *  Procédure de lancement du programme standard de l'interface des commandes
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
 
  PROCEDURE Launch_report(p_errbuf            OUT VARCHAR2,
                          p_retcode           OUT NUMBER
                          ) 
  IS
        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
        v_message                VARCHAR2 (100);
        b_result                 BOOLEAN;

  BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Launch_report');    
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 
                                         'Lancement de l''interface des commandes : ');

        fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT, 'LANCEMENT DU TRAITEMENT DE L''ETAT DES ERREURS:');
        fnd_file.put_line(fnd_file.OUTPUT, '----------------------------------------------');
        ---------------------------------------------------
        -- Lancement du traitement de l'interface des commandes --
        ---------------------------------------------------     
        -- Positionnement des options d'impression
        b_result := fnd_request.set_print_options(printer => gv_printer,
                                                  copies => g_number_of_copies); 
        -- Lancement du traitement 
         g_int_request_id          := Fnd_Request.submit_request (
                                             'PO'                             -- APPL
                                            ,'POXPIERR'                         -- PROG
                                            ,NULL                             -- PROGRAM_NAME
                                            ,NULL                             -- START
                                            ,FALSE                            -- SUB_REQUEST
                                            ,'PO_DOCS_OPEN_INTERFACE'
                                            ,'N'
                                            );
                                            
        IF g_int_request_id = 0
        THEN
            p_retcode    := 2;
            fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de l''interface des commandes a échoué' || CHR(10) ||
                                            'PROGRAMME  : POXPOPDOI' --|| CHR(10) ||
                                            --'UNITE OPERATIONNELLE : ' || p_ou || CHR(10)
                                            );
            Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de l''interface des commandes a échoué');
        ELSE
            COMMIT;
            Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || g_int_request_id);            
            Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement de l''interface des commandes : ' || g_int_request_id);  
 
            -- Attente de la fin du traitement
            IF NOT (Fnd_Concurrent.wait_for_request (g_int_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
            THEN                        
                p_errbuf  := v_Message;
                Fnd_file.put_line(Fnd_file.log, 'ERREUR : Attente de la fin du programme de l''interface des commandes : Fin du traitement' || CHR(10) ||
                                                'MESSAGE : ' || v_Message || CHR(10) );  
            END IF;
                         
            IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') 
            THEN          
                Fnd_File.put_line(Fnd_File.LOG, 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
                Fnd_File.put_line(Fnd_File.OUTPUT, '. Statut de fin : ' || v_phase || '/' || v_status);

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
            THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement de l''interface des commandes en warning '|| g_int_request_id);
                p_retcode    := 1;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')  
            THEN
                p_retcode := 2;
                p_errbuf  := 'ERREUR : Fin anormale du traitement de l''interface des commandes : '||v_Message;
  
                fnd_file.put_line(fnd_file.LOG, 'ERREUR : Fin anormale du traitement de l''interface des commandes '|| g_int_request_id  || CHR(10) ||
                                                'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                                'MESSAGE : ' || v_message || CHR(10) );
                Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement de l''interface des commandes '||g_int_request_id);
            END IF;
            
        END IF;                                            
  

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Launch_report');    
  
  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'Launch_report : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Launch_report : EXCEPTION OTHERS ');
  END Launch_report;    
  
  
  
  
  
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
  PROCEDURE Report_Bilan(p_errbuf            OUT VARCHAR2,
                         p_retcode           OUT NUMBER
                         ) 
  IS
 
  BEGIN
  
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Report_Bilan');

        --------------------    
        -- Initialisation --
        --------------------          
  
        p_errbuf  := NULL;
        p_retcode := 0;
        
        SELECT COUNT(1)
        INTO g_summary.rejected_headers_rows
        FROM PO_HEADERS_TMP
        WHERE statut ='E';
        
        SELECT COUNT(1)
        INTO g_summary.rejected_lines_rows
        FROM PO_LINES_TMP
        WHERE statut ='E';
        
        SELECT COUNT(1)
        INTO g_summary.rejected_dist_rows
        FROM PO_DISTRIBUTIONS_TMP
        WHERE statut ='E';
 
        
        fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT,'BILAN :');
        fnd_file.put_line(fnd_file.OUTPUT,'-------');
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table spécifique des entetes                : ' || TO_CHAR(g_summary.loaded_header_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table spécifique des lignes                 : ' || TO_CHAR(g_summary.loaded_lines_rows)); 
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements chargés dans la table spécifique des lignes de ventilation  : ' || TO_CHAR(g_summary.loaded_dist_rows)||CHR(10));        
        
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''anomalies dans la table spécifique des entetes                 : ' || TO_CHAR(g_summary.rejected_headers_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''anomalies dans la table spécifique des lignes                  : ' || TO_CHAR(g_summary.rejected_lines_rows)); 
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''anomalies dans la table spécifique des lignes de ventilations  : ' || TO_CHAR(g_summary.rejected_dist_rows)||CHR(10));
        
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements entetes chargés dans l''OI       : ' || TO_CHAR(g_summary.loaded_OI_header_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements lignes chargés dans l''OI        : ' || TO_CHAR(g_summary.loaded_OI_lines_rows)); 
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements ventilations chargés dans l''OI  : ' || TO_CHAR(g_summary.loaded_OI_dist_rows)||CHR(10));
        
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre de lignes rejetées dans la table OI des entetes                : ' || TO_CHAR(g_summary.rejected_OI_headers_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre de lignes rejetées dans la table OI des lignes de commandes    : ' || TO_CHAR(g_summary.rejected_OI_lines_rows)); 
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre de lignes rejetées dans la table OI des lignes de ventilations : ' || TO_CHAR(g_summary.rejected_OI_dist_rows)||CHR(10));     
        
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre de lignes mise à jour avec la quantité facturée dans la table PO_LINE_LOCATIONS_ALL : ' || TO_CHAR(g_summary.updated_rows_lines_sstr)); 
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre de lignes mise à jour avec la quantité facturée dans la table PO_DISTRIBUTIONS_ALL  : ' || TO_CHAR(g_summary.updated_rows_dist_sstr)||CHR(10));     


        fnd_file.put_line(fnd_file.OUTPUT,'Voir les sorties des traitements d''Open interface pour avoir plus de détails sur les enregistrements rejetés.');


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

  
/*
*************************************************************************
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
 ************************************************************************
 */
 
  PROCEDURE set_recovery_mode(p_Errbuf            OUT VARCHAR2,
                              p_retcode           OUT NUMBER
                              ) 
  IS

  BEGIN

    --g_loader_request_id := -1; --RBE
     
    UPDATE PO_HEADERS_TMP PHT
    SET  PHT.STATUT        = NULL
        ,LAST_UPDATE_DATE  = SYSDATE
        ,LAST_UPDATED_BY   = g_user_id
    WHERE PHT.STATUT = 'E'
    /*OR NOT EXISTS (
                    SELECT 1 
                    FROM PO_HEADERS_ALL PHA
                    WHERE PHA.SEGMENT1 = PHT.DOCUMENT_NUM
                    )*/ -- RBE artf2061678 
    ;
    
    UPDATE PO_LINES_TMP PLT
    SET  PLT.STATUT        = NULL
        ,LAST_UPDATE_DATE  = SYSDATE
        ,LAST_UPDATED_BY   = g_user_id
    WHERE PLT.STATUT = 'E'
    /*OR NOT EXISTS (
                    SELECT 1 
                    FROM PO_HEADERS_ALL PHA
                    WHERE PHA.SEGMENT1 = PLT.DOCUMENT_NUM
                    )*/-- RBE artf2061678 
    ;

    UPDATE PO_DISTRIBUTIONS_TMP PDT
    SET  PDT.STATUT        = NULL
        ,LAST_UPDATE_DATE  = SYSDATE
        ,LAST_UPDATED_BY   = g_user_id
    WHERE PDT.STATUT = 'E'
    /*OR NOT EXISTS (
                    SELECT 1 
                    FROM PO_HEADERS_ALL PHA
                    WHERE PHA.SEGMENT1 = PDT.DOCUMENT_NUM
                    )*/ -- RBE artf2061678 
    ;   
    

  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'SET_RECOVERY_MODE : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure SET_RECOVERY_MODE : EXCEPTION OTHERS ');
  END set_recovery_mode;    


/*
************************************************************************
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
 ************************************************************************
 */
 /* RBE artf2061678
  PROCEDURE Purge_Data(p_Errbuf            OUT VARCHAR2,
                       p_retcode           OUT NUMBER
                              ) 
  IS

  BEGIN


     Fnd_File.Put_Line(Fnd_File.LOG, '-> PO_HEADERS_TMP' );
     DELETE FROM PO_HEADERS_TMP
     ;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows '||TO_CHAR(SQL%ROWCOUNT));
     
     Fnd_File.Put_Line(Fnd_File.LOG, '-> PO_LINES_TMP' );
     DELETE FROM PO_LINES_TMP
     ;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows '||TO_CHAR(SQL%ROWCOUNT));

     Fnd_File.Put_Line(Fnd_File.LOG, '-> PO_DISTRIBUTIONS_TMP' );
     DELETE FROM PO_DISTRIBUTIONS_TMP
     ;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows '||TO_CHAR(SQL%ROWCOUNT));     
     



  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'PURGE_DATA : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure PURGE_DATA : EXCEPTION OTHERS ');
  END purge_data;  
  */ -- RBE artf2061678
  
/*
************************************************************************
 * PROCEDURE NAME : purge_data_OI
 *
 * DESCRIPTION
 *  Procédure de purge des données
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
 * -----------------  ------------------------------------------------------
 *
 ************************************************************************
 */
 /* -- RBE artf2061678
  PROCEDURE purge_data_OI(p_Errbuf            OUT VARCHAR2,
                          p_retcode           OUT NUMBER
                              ) 
  IS

  BEGIN


     Fnd_File.Put_Line(Fnd_File.LOG, '-> PO_HEADERS_INTERFACE' );
     DELETE FROM PO_HEADERS_INTERFACE
     ;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows '||TO_CHAR(SQL%ROWCOUNT));
     
     Fnd_File.Put_Line(Fnd_File.LOG, '-> PO_LINES_INTERFACE' );
     DELETE FROM PO_LINES_INTERFACE
     ;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows '||TO_CHAR(SQL%ROWCOUNT));

     Fnd_File.Put_Line(Fnd_File.LOG, '-> PO_DISTRIBUTIONS_INTERFACE' );
     DELETE FROM PO_DISTRIBUTIONS_INTERFACE
     ;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows '||TO_CHAR(SQL%ROWCOUNT));     
     



  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'PURGE_DATA_OI : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure purge_data_OI : EXCEPTION OTHERS ');
  END purge_data_OI;    

*/-- RBE artf2061678

/*
*************************************************************************
 * PROCEDURE NAME : post_OI
 *
 * DESCRIPTION
 *  Procédure post_OI
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
 * -----------------  ------------------------------------------------------
 *
 ************************************************************************
 */
 
  PROCEDURE post_OI(p_Errbuf            OUT VARCHAR2,
                    p_retcode           OUT NUMBER
                    ) 
  IS
  
   CURSOR cur_errors_header IS
    /*SELECT *
    FROM po_interface_errors
    WHERE INTERFACE_HEADER_ID IN (SELECT DISTINCT INTERFACE_HEADER_ID
                                  FROM PO_HEADERS_INTERFACE
                                  )*/
    SELECT poi.document_num, poe.TABLE_NAME, poe.COLUMN_NAME, pot.logical_line_num, poe.ERROR_MESSAGE
    FROM  po_interface_errors  poe
         ,PO_HEADERS_INTERFACE poi
         ,PO_HEADERS_TMP       pot
    WHERE poe.TABLE_NAME          = 'PO_HEADERS_INTERFACE'
    AND   poe.INTERFACE_HEADER_ID = poi.INTERFACE_HEADER_ID
    AND   poi.document_num        = pot.document_num
    AND   pot.statut              = 'E'   
    --AND   pot.LOAD_REQUEST_ID     = DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)--RBE                              
   ;
   
   CURSOR cur_errors_lines IS
    SELECT pohi.document_num, poe.TABLE_NAME, poe.COLUMN_NAME, pot.logical_line_num, poe.ERROR_MESSAGE
    FROM po_interface_errors  poe
        ,PO_HEADERS_INTERFACE pohi
        ,PO_LINES_INTERFACE   poi
        ,PO_LINES_TMP         pot
    WHERE poe.TABLE_NAME          in ('PO_LINES_INTERFACE','PO_LINE_LOCATIONS_INTERFACE')
    AND   poe.INTERFACE_HEADER_ID = poi.INTERFACE_HEADER_ID
    AND   poe.INTERFACE_LINE_ID   = poi.INTERFACE_LINE_ID
    AND   poi.INTERFACE_HEADER_ID = pohi.INTERFACE_HEADER_ID
    AND   pohi.document_num       = pot.document_num
    AND   poi.line_num            = pot.line_num
    AND   pot.statut              = 'E'
    --AND   pot.LOAD_REQUEST_ID     = DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id) --RBE                            
    ;
    
   CURSOR cur_errors_distribution IS
    SELECT pohi.document_num, poe.TABLE_NAME, poe.COLUMN_NAME, pot.logical_line_num, poe.ERROR_MESSAGE
    FROM po_interface_errors        poe
        ,PO_HEADERS_INTERFACE       pohi
        ,PO_DISTRIBUTIONS_INTERFACE poi
        ,PO_DISTRIBUTIONS_TMP       pot
    WHERE poe.TABLE_NAME                = 'PO_DISTRIBUTIONS_INTERFACE'
    AND   poe.INTERFACE_HEADER_ID       = poi.INTERFACE_HEADER_ID
    AND   poe.INTERFACE_LINE_ID         = poi.INTERFACE_LINE_ID
    AND   poe.INTERFACE_DISTRIBUTION_ID = poi.INTERFACE_DISTRIBUTION_ID
    AND   poi.INTERFACE_HEADER_ID       = pohi.INTERFACE_HEADER_ID
    AND   pohi.document_num             = pot.document_num
    AND   poi.distribution_num          = pot.distribution_num
    AND   pot.statut                    = 'E'
    --AND   pot.LOAD_REQUEST_ID     = DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id)  --RBE                            
    ;   

  BEGIN

     
    UPDATE PO_HEADERS_TMP
    SET  STATUT     = 'R' --RBE
        ,LAST_UPDATE_DATE  = SYSDATE
        ,LAST_UPDATED_BY   = g_user_id
    WHERE DOCUMENT_NUM IN (SELECT DOCUMENT_NUM
                           FROM PO_HEADERS_INTERFACE
                           WHERE PROCESS_CODE != 'ACCEPTED' 
                          )
    AND STATUT = 'T'                      
    --AND LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id) --RBE
    ;
    
    g_summary.rejected_OI_headers_rows :=  SQL%ROWCOUNT;
    
    UPDATE PO_LINES_TMP
    SET  STATUT     = 'R' --RBE
        ,LAST_UPDATE_DATE  = SYSDATE
        ,LAST_UPDATED_BY   = g_user_id
    WHERE DOCUMENT_NUM IN (SELECT DOCUMENT_NUM
                           FROM PO_HEADERS_INTERFACE
                           WHERE PROCESS_CODE != 'ACCEPTED' 
                          )
    AND STATUT = 'T'                      
    --AND LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id) --RBE
    ;
    
    g_summary.rejected_OI_lines_rows :=  SQL%ROWCOUNT;

    UPDATE PO_DISTRIBUTIONS_TMP
    SET  STATUT     = 'R' --RBE
        ,LAST_UPDATE_DATE  = SYSDATE
        ,LAST_UPDATED_BY   = g_user_id
    WHERE DOCUMENT_NUM IN (SELECT DOCUMENT_NUM
                           FROM PO_HEADERS_INTERFACE
                           WHERE PROCESS_CODE != 'ACCEPTED' 
                          )
    AND STATUT = 'T'                      
    --AND LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id) --RBE                  
    ;    
    
    g_summary.rejected_OI_dist_rows :=  SQL%ROWCOUNT;
    
    -- Récupération des erreurs de la table d'interface header
    FOR err IN cur_errors_header LOOP
                /*DKA_TOOLS_PKG.*/ins_prog_message(g_request_id
                                              ,'DKA_REPPOCMDIMP_PKG'
                                              ,'ETL'
                                              ,err.TABLE_NAME
                                              ,err.logical_line_num
                                              ,err.COLUMN_NAME
                                              ,err.document_num
                                              ,'E'
                                              ,err.ERROR_MESSAGE
                                              );    
                g_summary.rejected_rows := g_summary.rejected_rows + 1;                               
    END LOOP;
    
    -- Récupération des erreurs de la table d'interface lines
    FOR err IN cur_errors_lines LOOP
                /*DKA_TOOLS_PKG.*/ins_prog_message(g_request_id
                                              ,'DKA_REPPOCMDIMP_PKG'
                                              ,'ETL'
                                              ,err.TABLE_NAME
                                              ,err.logical_line_num
                                              ,err.COLUMN_NAME
                                              ,err.document_num
                                              ,'E'
                                              ,err.ERROR_MESSAGE
                                              );    
                g_summary.rejected_rows := g_summary.rejected_rows + 1;                               
    END LOOP;

    -- Récupération des erreurs de la table d'interface distribution
    FOR err IN cur_errors_distribution LOOP
                /*DKA_TOOLS_PKG.*/ins_prog_message(g_request_id
                                              ,'DKA_REPPOCMDIMP_PKG'
                                              ,'ETL'
                                              ,err.TABLE_NAME
                                              ,err.logical_line_num
                                              ,err.COLUMN_NAME
                                              ,err.document_num
                                              ,'E'
                                              ,err.ERROR_MESSAGE
                                              );    
                g_summary.rejected_rows := g_summary.rejected_rows + 1;                               
    END LOOP;    
    
    
    
    
    COMMIT;

  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'POST_OI : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure post_OI : EXCEPTION OTHERS ');
  END post_OI;    
    
  
 /*
 *************************************************************************
 * PROCEDURE NAME : main
 * 
 * DESCRIPTION
 *  Procédure principale de l'interface de création des fournisseurs
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
.* ----------------- ------------------------------------------------------
 * p_errbuf         Retour de message éventuel
 * p_retcode        Statut du traitement en sortie
 * p_directory      Repertoire 
 * p_file_name      Nom du fichier à charger
 ************************************************************************
 */

  PROCEDURE main(p_errbuf       IN OUT  VARCHAR2,
                 p_retcode      OUT     NUMBER,
                 p_reprise      IN      VARCHAR2,
                 p_insert       IN      VARCHAR2,
                 p_import       IN      VARCHAR2
                 )
  IS
  
     v_current_program_unit   VARCHAR2(30);
     v_errbuf                 VARCHAR2(2500);
     v_retcode                NUMBER;
     v_count                  NUMBER;
     --v_directory              VARCHAR2(100):='/oradata/HELDEV/app/data/in'; 
     Erreur_Programme         EXCEPTION;
 
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
       
       Init(v_errbuf, v_retcode);
        
       IF v_retcode = 2 
       THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RAISE Erreur_Programme;
       END IF;              
        
      IF p_reprise = 'Y' THEN -- RBE artf2061678 
      
          /* --RBE artf2061678 
          -------------------------------------------
          -- PHASE DE PURGE DES ANCIENNES DONNEES  --
          -------------------------------------------
          Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PURGE DES DONNEES TABLES SPECIFIQUES'); 
          purge_data(v_errbuf,
                     v_retcode
                     );
          IF v_retcode = 2 
          THEN
              p_Errbuf  := v_errbuf;
              p_retcode := v_retcode;
              RAISE Erreur_Programme;
          END IF; 
          */

              
           ------------------------------------
           -- PHASE DE CHARGEMENT DU FICHIER --
           ------------------------------------ 
           Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE DE CHARGEMENT DU FICHIER'); 

           -- Lancement du programme de chargement
           Launch_Loader(--v_directory,
                         v_errbuf,
                         v_retcode
                         );
           IF v_retcode = 2 
           THEN
                RAISE Erreur_Programme;
           END IF;
      END IF;
        
      ------------------------------------
      -- ALIMENTER OPEN INTERFACE       --
      ------------------------------------
      
      IF p_insert = 'Y' THEN -- RBE artf2061678   
          -- RBE artf2061678 
          --ELSE
          Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE DE INITIALISATION DU MODE REPRISE'); 
          set_recovery_mode(v_errbuf,
                            v_retcode
                            );           
          
          --END IF;
        /*-- RBE artf2061678 
        ------------------------------------
        -- PHASE DE PURGE DES DONNEES OI  --
        ------------------------------------
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PURGE DES DONNEES OI'); 
        purge_data_OI(v_errbuf,
                      v_retcode
                      );
        IF v_retcode = 2 
        THEN
            p_Errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RAISE Erreur_Programme;
        END IF; 
        */ 
              
         -------------------------------------
         -- PHASE DE VALIDATION DES DONNEES --
         ------------------------------------- 
         Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE DE VALIDATION DES DONNEES'); 
  
         -- Lancement du programme de chargement
         validate_data(v_errbuf,
                       v_retcode
                       );
         IF v_retcode = 2 
         THEN
              p_errbuf  := v_errbuf;
              p_retcode := v_retcode;       
              RAISE Erreur_Programme;
         END IF;
         
         ---------------------------------------
         -- PHASE D'IMPORTATION DES COMMANDES --
         --------------------------------------- 
         Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE D''IMPORTATION DES COMMANDES'); 
      
         -- Lancement du programme standard 
         import_data(v_errbuf,
                     v_retcode
                    );
         IF v_retcode = 2 
         THEN
              RAISE Erreur_Programme;
         END IF;   
           
      END IF;
      
      ------------------------------------
      -- SOUMETTRE OPEN INTERFACE       --
      ------------------------------------
      IF p_import = 'Y' THEN -- RBE artf2061678  
         -----------------------------------------------
         -- PHASE DE LANCEMENT DU TRAITEMENT STANDARD --
         ----------------------------------------------- 
         Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE DE LANCEMENT DU TRAITEMENT STANDARD'); 

          --RBE
          UPDATE PO_HEADERS_TMP
          SET  STATUT     = 'T'
              ,LAST_UPDATE_DATE  = SYSDATE
              ,LAST_UPDATED_BY   = g_user_id
          WHERE STATUT = 'R';
          
          UPDATE PO_LINES_TMP
          SET  STATUT     = 'T'
              ,LAST_UPDATE_DATE  = SYSDATE
              ,LAST_UPDATED_BY   = g_user_id
          WHERE STATUT = 'R';
          
          UPDATE PO_DISTRIBUTIONS_TMP
          SET  STATUT     = 'T'
              ,LAST_UPDATE_DATE  = SYSDATE
              ,LAST_UPDATED_BY   = g_user_id
          WHERE STATUT = 'R';

         BEGIN
          SELECT count(1)
          INTO v_count
          FROM PO_HEADERS_TMP
          WHERE STATUT = 'T'
          --AND LOAD_REQUEST_ID = DECODE( g_loader_request_id, -1, load_request_id, g_loader_request_id) --RBE
          ;
         EXCEPTION
          WHEN OTHERS THEN
            v_count := 0;
         END;
         
         IF v_count != 0 THEN
      
           -- Lancement du programme standard 
           Launch_OI(v_errbuf,
                     v_retcode
                     );
                    
         IF v_retcode = 2 
         THEN
              p_errbuf  := v_errbuf;
              p_retcode := v_retcode;
              Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
              Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf);
         END IF;                   
  
  
         ----------------------------------------
         -- PHASE DES MISES A JOUR POST IMPORT --
         ----------------------------------------
         Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE DES MISES A JOUR POST IMPORT'); 
      
         -- lancer les mises à jour
         update_post_import(v_errbuf,
                            v_retcode
                            );
         IF v_retcode = 2 
         THEN
              RAISE Erreur_Programme;
         END IF; 
  
         
         -- Lancement du traitement d'Etat des erreurs de l’interface des achats 
         Launch_report(v_errbuf,
                       v_retcode
                      );
  
          -- Vérification des erreurs retournées par l'interface standard                           
          post_OI(v_errbuf,
                  v_retcode
                  );
  
  
         END IF;
         
       END IF;-- RBE artf2061678  
       
       ----------------------------------
       -- PHASE DE BILAN DU TRAITEMENT --
       ----------------------------------

       Report_Bilan(v_errbuf, v_retcode); 

       IF v_retcode = 2 
       THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;
            --RAISE Erreur_Programme;
       END IF;

       
       ------------------------------------
       -- PHASE DE CHARGEMENT DU FICHIER --
       ------------------------------------ 
       Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE DES ANOMALIES'); 
       
       print_errors;          



       ---------------------------------------
       -- PHASE DE FIN DU TRAITEMENT MAITRE --
       ---------------------------------------
       IF p_retcode = 2
       THEN
           p_errbuf := 'ATTENTION : Erreur bloquante : '||p_errbuf;
       ELSIF (g_summary.rejected_headers_rows > 0 OR g_summary.rejected_lines_rows > 0 OR g_summary.rejected_dist_rows > 0 OR g_summary.rejected_rows > 0)
       THEN
           p_errbuf := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
           p_retcode := 1;
       ELSIF (g_summary.loaded_header_rows = 0 AND g_summary.loaded_lines_rows = 0 AND g_summary.loaded_dist_rows = 0)
       THEN
           p_errbuf := 'ATTENTION : Aucun enregistrement chargé.';
           p_retcode := 1;
       ELSE 
           p_errbuf := 'Fin normale du traitement - Aucun rejet.';
           p_retcode := 0;
       END IF;


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
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_REPPOCMDIMP_PKG.' || v_current_program_unit||CHR(10)||'A retourné     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           p_errbuf := SQLERRM;
  END main; 
 

END DKA_REPPOCMDIMP_PKG;
/
SHOW ERRORS
EXIT
